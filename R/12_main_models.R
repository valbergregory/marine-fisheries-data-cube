# 12_main_models.R — modelos principais (associacionais; ver
# docs/identification_strategy.md e docs/estimand_table.md).
# Especificacao principal: PPML (fepois) com EF de celula e periodo +
# sazonalidade regional; erros Conley (fallback: cluster celula+tempo).

mfdc_prep_panel <- function(panel) {
  p <- data.table::copy(panel)
  p[, time_id := as.integer(factor(month, levels = sort(unique(month))))]
  p[, month_of_year := substr(month, 6, 7)]
  # fixest::conley detecta colunas 'lat'/'lon'
  p[, `:=`(lat = lat_c, lon = lon_c)]
  if (all(is.na(p$region))) p[, region := "BR"]   # fallback se geobr falhou
  p[]
}

#' Sumario com Conley (cutoff km); fallback cluster bidirecional.
mfdc_vcov_summary <- function(m, cutoff_km, log_file = NULL) {
  s <- tryCatch(summary(m, vcov = fixest::conley(cutoff = cutoff_km)),
                error = function(e) e)
  if (!inherits(s, "error")) return(list(sum = s, vcov = sprintf("conley_%dkm", cutoff_km)))
  mfdc_log("Conley falhou (", conditionMessage(s),
           ") — fallback cluster celula+tempo", file = log_file)
  list(sum = summary(m, cluster = c("cell", "time_id")), vcov = "cluster_cell_time")
}

#' Estima o bloco principal numa resolucao. Devolve lista com sumarios,
#' tabela coeficientes e metadados (nunca copiar numeros a mao).
mfdc_main_models <- function(panel, conley_cutoff_km = 200, log_file = NULL) {
  p <- mfdc_prep_panel(panel)
  data.table::setkey(p, cell, time_id)
  fe <- "cell + month + region^month_of_year"
  panel_id <- c("cell", "time_id")

  mfdc_log(sprintf("Modelos res %d: %d obs, %d celulas, %d meses",
    p$grid_res[1], nrow(p), data.table::uniqueN(p$cell),
    data.table::uniqueN(p$month)), file = log_file)

  models <- list(
    ppml_mhw       = fixest::fepois(
      stats::as.formula(paste("hours ~ mhw_days |", fe)), data = p),
    ppml_mhw_anom  = fixest::fepois(
      stats::as.formula(paste("hours ~ mhw_days + sst_anom |", fe)), data = p),
    ext_lpm        = fixest::feols(
      stats::as.formula(paste("effort_present ~ mhw_days |", fe)), data = p),
    log1p_rob      = fixest::feols(
      stats::as.formula(paste("log1p(hours) ~ mhw_days |", fe)), data = p),
    ppml_dyn       = fixest::fepois(
      stats::as.formula(paste("hours ~ l(mhw_days, 0:3) |", fe)),
      data = p, panel.id = panel_id),
    ppml_intensity = fixest::fepois(
      stats::as.formula(paste("hours ~ mhw_days + mhw_max_int |", fe)), data = p)
  )

  sums <- lapply(models, mfdc_vcov_summary, cutoff_km = conley_cutoff_km,
                 log_file = log_file)
  coefs <- data.table::rbindlist(lapply(names(sums), function(nm) {
    ct <- as.data.frame(sums[[nm]]$sum$coeftable)
    data.table::data.table(model = nm, term = rownames(ct), ct,
                           vcov = sums[[nm]]$vcov)
  }), fill = TRUE)

  list(
    grid_res = p$grid_res[1],
    n_obs = nrow(p), n_cells = data.table::uniqueN(p$cell),
    summaries = lapply(sums, `[[`, "sum"),
    coefs = coefs,
    meta = list(fe = fe, conley_cutoff_km = conley_cutoff_km,
                estimated_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S"))
  )
}

#' Heterogeneidade: efeito por regiao e por arte de pesca.
#' panel_gear vem de mfdc_build_panel_gear (celula x mes x arte).
mfdc_heterogeneity_models <- function(panel, panel_gear, conley_cutoff_km = 200,
                                      log_file = NULL) {
  p <- mfdc_prep_panel(panel)
  pg <- mfdc_prep_panel(panel_gear)
  pg[, cell_gear := paste(cell, gear, sep = "_")]

  models <- list(
    by_region = fixest::fepois(
      hours ~ i(region, mhw_days) + sst_anom |
        cell + month + region^month_of_year, data = p),
    by_gear = fixest::fepois(
      hours ~ i(gear, mhw_days) + sst_anom |
        cell_gear + month + region^month_of_year, data = pg),
    # distancia da costa: acima/abaixo da mediana
    by_distance = fixest::fepois(
      hours ~ i(far_coast, mhw_days) + sst_anom |
        cell + month + region^month_of_year,
      data = p[, far_coast := data.table::fifelse(
        dist_coast_km > stats::median(dist_coast_km, na.rm = TRUE),
        "offshore", "nearshore")])
  )
  sums <- lapply(models, mfdc_vcov_summary, cutoff_km = conley_cutoff_km,
                 log_file = log_file)
  coefs <- data.table::rbindlist(lapply(names(sums), function(nm) {
    ct <- as.data.frame(sums[[nm]]$sum$coeftable)
    data.table::data.table(model = nm, term = rownames(ct), ct,
                           vcov = sums[[nm]]$vcov)
  }), fill = TRUE)
  list(summaries = lapply(sums, `[[`, "sum"), coefs = coefs,
       n_gear_obs = nrow(pg))
}

mfdc_save_heterogeneity <- function(het, dir_models, dir_tables) {
  f1 <- file.path(dir_models, "heterogeneity_res4.rds")
  saveRDS(het, f1)
  f2 <- file.path(dir_tables, "heterogeneity_etable.txt")
  writeLines(capture.output(fixest::etable(het$summaries)), f2)
  f3 <- file.path(dir_tables, "heterogeneity_coefs.csv")
  data.table::fwrite(het$coefs, f3)
  c(f1, f2, f3)
}

#' Salva artefatos dos modelos (RDS + coeficientes CSV + etable txt).
mfdc_save_models <- function(res_obj, dir_models, dir_tables) {
  dir.create(dir_models, recursive = TRUE, showWarnings = FALSE)
  dir.create(dir_tables, recursive = TRUE, showWarnings = FALSE)
  tag <- sprintf("res%d", res_obj$grid_res)
  f_rds <- file.path(dir_models, sprintf("main_models_%s.rds", tag))
  saveRDS(res_obj, f_rds)
  f_csv <- file.path(dir_tables, sprintf("main_coefs_%s.csv", tag))
  data.table::fwrite(res_obj$coefs, f_csv)
  f_txt <- file.path(dir_tables, sprintf("main_etable_%s.txt", tag))
  writeLines(capture.output(fixest::etable(res_obj$summaries)), f_txt)
  c(f_rds, f_csv, f_txt)
}
