# 14_spatial_models.R — deslocamento espacial: exposicao MHW da vizinhanca em
# ANEIS concentricos (h3jsr nao expoe API de anel testada, entao a vizinhanca
# e definida por distancia entre centroides; res 4 tem aresta ~22 km).
# Implementacao com matriz esparsa (Matrix): escala para aneis grandes sem
# explodir a memoria (o merge cartesiano anterior era O(edges x meses)).

#' Matriz de vizinhanca normalizada por linha para o anel (d_min, d_max] em km.
mfdc_ring_matrix <- function(cs, d_min_km, d_max_km) {
  sfp <- sf::st_as_sf(cs, coords = c("lon_c", "lat_c"), crs = 4326)
  inner <- if (d_min_km > 0) sf::st_is_within_distance(sfp, dist = d_min_km * 1000)
           else vector("list", nrow(cs))
  outer <- sf::st_is_within_distance(sfp, dist = d_max_km * 1000)
  from <- rep(seq_len(nrow(cs)), lengths(outer))
  to   <- unlist(outer)
  keep <- from != to
  if (d_min_km > 0) {
    inner_key <- paste(rep(seq_len(nrow(cs)), lengths(inner)), unlist(inner))
    keep <- keep & !(paste(from, to) %in% inner_key)
  }
  from <- from[keep]; to <- to[keep]
  W <- Matrix::sparseMatrix(i = from, j = to, x = 1,
                            dims = c(nrow(cs), nrow(cs)))
  rs <- Matrix::rowSums(W)
  list(W = Matrix::Diagonal(x = ifelse(rs > 0, 1 / rs, 0)) %*% W, n_nb = rs)
}

#' Exposicao media dos vizinhos por anel; devolve colunas mhw_nb_<tag>.
mfdc_ring_exposure <- function(panel, rings = list(k1 = c(0, 60),
                                                   mid = c(60, 150),
                                                   far = c(150, 300)),
                               log_file = NULL) {
  cs <- unique(panel[, .(cell, lon_c, lat_c)])[order(cell)]
  months <- sort(unique(panel$month))
  M <- data.table::dcast(panel[, .(cell, month, mhw_days)], cell ~ month,
                         value.var = "mhw_days")[order(cell)]
  stopifnot(identical(M$cell, cs$cell))
  Mx <- as.matrix(M[, -1])
  Mx[is.na(Mx)] <- 0
  out <- data.table::data.table(cell = rep(cs$cell, times = length(months)),
                                month = rep(months, each = nrow(cs)))
  for (tag in names(rings)) {
    r <- rings[[tag]]
    rm_ <- mfdc_ring_matrix(cs, r[1], r[2])
    E <- as.matrix(rm_$W %*% Mx)
    out[, (paste0("mhw_nb_", tag)) := as.vector(E)]
    mfdc_log(sprintf("Anel %s (%g-%g km): mediana %g vizinhos", tag, r[1], r[2],
                     stats::median(rm_$n_nb)), file = log_file)
  }
  out[]
}

mfdc_spatial_models <- function(panel, conley_cutoff_km = 200, log_file = NULL) {
  rings <- mfdc_ring_exposure(panel, log_file = log_file)
  p <- merge(mfdc_prep_panel(panel), rings, by = c("cell", "month"), all.x = TRUE)
  fe <- "cell + month + region^month_of_year"
  models <- list(
    # esforco migra p/ ca quando o entorno queima? coef positivo = deslocamento
    ppml_rings = fixest::fepois(stats::as.formula(paste(
      "hours ~ mhw_days + mhw_nb_k1 + mhw_nb_mid + mhw_nb_far + sst_anom |", fe)),
      data = p),
    ext_rings = fixest::feols(stats::as.formula(paste(
      "effort_present ~ mhw_days + mhw_nb_k1 + mhw_nb_mid + mhw_nb_far + sst_anom |", fe)),
      data = p)
  )
  sums <- lapply(models, mfdc_vcov_summary, cutoff_km = conley_cutoff_km,
                 log_file = log_file)
  coefs <- mfdc_coef_table(sums)
  list(grid_res = panel$grid_res[1], summaries = lapply(sums, `[[`, "sum"),
       coefs = coefs)
}

#' Realocacao agregada (E4): distancia media do esforco a costa, concentracao
#' espacial e n de celulas ativas, por regiao x mes.
#' ATENCAO: 4 regioes = poucos clusters; reportamos SE robusto (hetero) e
#' cluster por regiao, com leitura cautelosa (registrado nos metadados).
mfdc_relocation_models <- function(rm_panel, log_file = NULL) {
  p <- data.table::copy(rm_panel)[!is.na(dist_w_km)]
  p[, month_of_year := substr(month, 6, 7)]
  models <- list(
    dist_coast = fixest::feols(dist_w_km ~ mhw_exp + sst_anom |
                                 region + month, data = p),
    concentration = fixest::feols(hhi ~ mhw_exp + sst_anom |
                                    region + month, data = p),
    active_cells = fixest::fepois(n_active ~ mhw_exp + sst_anom |
                                    region + month, data = p)
  )
  sums <- lapply(models, function(m)
    list(sum = summary(m, vcov = "hetero"), vcov = "hetero"))
  mfdc_log(sprintf("Realocacao: %d obs regiao-mes (%d regioes) — poucos clusters",
    nrow(p), data.table::uniqueN(p$region)), file = log_file)
  list(summaries = lapply(sums, `[[`, "sum"), coefs = mfdc_coef_table(sums),
       n_regions = data.table::uniqueN(p$region), n_obs = nrow(p))
}

#' Moran's I dos residuos medios por celula (dependencia espacial residual).
#' Implementado com a matriz do anel 0-60 km — evita dependencia de spdep.
mfdc_moran_residuals <- function(panel, model, d_max_km = 60, n_perm = 199L,
                                 seed = 20260903, log_file = NULL) {
  p <- mfdc_prep_panel(panel)[!is.na(sst_anom)]
  # predict alinha por construcao (fixest pode remover singletons na estimacao)
  p[, fit := as.numeric(stats::predict(model, newdata = p))]
  p <- p[is.finite(fit)]
  agg <- p[, .(e = mean(hours - fit)), by = cell]
  cs <- unique(p[, .(cell, lon_c, lat_c)])[agg, on = "cell"][order(cell)]
  W <- mfdc_ring_matrix(cs, 0, d_max_km)$W   # normalizada por linha
  z <- cs$e - mean(cs$e)
  I_obs <- as.numeric((t(z) %*% (W %*% z)) / sum(z^2)) * nrow(cs) / sum(W)
  set.seed(seed)
  I_perm <- vapply(seq_len(n_perm), function(i) {
    zp <- sample(z)
    as.numeric((t(zp) %*% (W %*% zp)) / sum(zp^2)) * nrow(cs) / sum(W)
  }, numeric(1))
  out <- data.table::data.table(
    moran_I = I_obs, perm_mean = mean(I_perm), perm_sd = stats::sd(I_perm),
    p_perm = (1 + sum(abs(I_perm) >= abs(I_obs))) / (1 + n_perm),
    n_cells = nrow(cs), d_max_km = d_max_km)
  mfdc_log(sprintf("Moran I dos residuos = %.4f (p_perm = %.3f, %d celulas)",
                   I_obs, out$p_perm, nrow(cs)), file = log_file)
  out[]
}

mfdc_save_spatial <- function(sp, dir_models, dir_tables) {
  tag <- sprintf("res%d", sp$grid_res)
  f1 <- file.path(dir_models, sprintf("spatial_%s.rds", tag))
  saveRDS(sp, f1)
  f2 <- file.path(dir_tables, sprintf("spatial_etable_%s.txt", tag))
  writeLines(capture.output(fixest::etable(sp$summaries)), f2)
  f3 <- file.path(dir_tables, sprintf("spatial_coefs_%s.csv", tag))
  data.table::fwrite(sp$coefs, f3)
  c(f1, f2, f3)
}
