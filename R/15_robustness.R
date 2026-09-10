# 15_robustness.R — bateria de robustez pre-registrada (protocolo, secao 11):
# res 5, cutoffs Conley, tendencias regiao-ano, amostra estavel, e definicao
# alternativa de MHW (p95) via alvo separado no _targets.R.

mfdc_robustness_models <- function(panel_r4, panel_r5, log_file = NULL) {
  fe  <- "cell + month + region^month_of_year"
  fe_t <- "cell + month + region^month_of_year + region^year"
  p4 <- mfdc_prep_panel(panel_r4); p5 <- mfdc_prep_panel(panel_r5)
  p4[, year := substr(month, 1, 4)]; p5[, year := substr(month, 1, 4)]
  # amostra estavel: celulas com esforco em >= 12 meses distintos
  stable <- p4[hours > 0, data.table::uniqueN(month), by = cell][V1 >= 12, cell]

  base4 <- fixest::fepois(stats::as.formula(paste(
    "hours ~ mhw_days + sst_anom |", fe)), data = p4)

  models <- list(
    res5_main    = fixest::fepois(stats::as.formula(paste(
      "hours ~ mhw_days + sst_anom |", fe)), data = p5),
    trend_regyr  = fixest::fepois(stats::as.formula(paste(
      "hours ~ mhw_days + sst_anom |", fe_t)), data = p4),
    stable_cells = fixest::fepois(stats::as.formula(paste(
      "hours ~ mhw_days + sst_anom |", fe)), data = p4[cell %in% stable])
  )
  sums <- c(
    lapply(models, mfdc_vcov_summary, cutoff_km = 200, log_file = log_file),
    list(conley100 = mfdc_vcov_summary(base4, 100, log_file),
         conley400 = mfdc_vcov_summary(base4, 400, log_file))
  )
  coefs <- mfdc_coef_table(sums)
  list(summaries = lapply(sums, `[[`, "sum"), coefs = coefs,
       n_stable_cells = length(stable))
}

#' Placebos: (a) temporal — lead de 12 meses (a exposicao futura nao pode
#' explicar o esforco de hoje); (b) espacial — permutacao das series de MHW
#' entre celulas DA MESMA REGIAO, gerando p-valor de randomizacao.
mfdc_placebo_models <- function(panel, n_perm = 50L, seed = 20260903,
                                log_file = NULL) {
  p <- mfdc_prep_panel(panel)
  data.table::setkey(p, cell, time_id)
  fe <- "cell + month + region^month_of_year"

  temporal <- fixest::fepois(stats::as.formula(paste(
    "hours ~ f(mhw_days, 12) + sst_anom |", fe)), data = p,
    panel.id = c("cell", "time_id"))
  s_temp <- mfdc_vcov_summary(temporal, 200, log_file)

  b_obs <- stats::coef(fixest::fepois(stats::as.formula(paste(
    "hours ~ mhw_days + sst_anom |", fe)), data = p))[["mhw_days"]]

  mhw_by_cell <- p[, .(cell, month, mhw_days, region)]
  cells_reg <- unique(p[, .(cell, region)])
  set.seed(seed)
  b_perm <- vapply(seq_len(n_perm), function(i) {
    map <- cells_reg[, .(cell, cell_src = sample(cell)), by = region]
    px <- merge(p[, .(cell, month, hours, sst_anom, region, month_of_year)],
                map[, .(cell, cell_src)], by = "cell")
    px <- merge(px, mhw_by_cell[, .(cell_src = cell, month, mhw_perm = mhw_days)],
                by = c("cell_src", "month"))
    m <- tryCatch(fixest::fepois(stats::as.formula(paste(
      "hours ~ mhw_perm + sst_anom |", fe)), data = px, notes = FALSE),
      error = function(e) NULL)
    if (is.null(m)) NA_real_ else stats::coef(m)[["mhw_perm"]]
  }, numeric(1))

  b_perm <- b_perm[is.finite(b_perm)]
  p_rand <- (1 + sum(abs(b_perm) >= abs(b_obs))) / (1 + length(b_perm))
  mfdc_log(sprintf("Placebo espacial: b_obs = %.4f; %d permutacoes, p_rand = %.3f",
                   b_obs, length(b_perm), p_rand), file = log_file)
  list(temporal_summary = s_temp$sum,
       temporal_coefs = mfdc_coef_table(list(placebo_lead12 = s_temp)),
       permutation = data.table::data.table(
         b_obs = b_obs, n_perm = length(b_perm), perm_mean = mean(b_perm),
         perm_sd = stats::sd(b_perm), p_rand = p_rand,
         perm_q025 = stats::quantile(b_perm, .025),
         perm_q975 = stats::quantile(b_perm, .975)),
       perm_draws = b_perm)
}

#' Exclusoes de amostra: celulas costeiras (proxy de area portuaria) e
#' celulas de baixa cobertura.
mfdc_exclusion_models <- function(panel, min_dist_km = 25, min_active = 6L,
                                  log_file = NULL) {
  p <- mfdc_prep_panel(panel)
  fe <- "cell + month + region^month_of_year"
  active <- p[hours > 0, .N, by = cell][N >= min_active, cell]
  models <- list(
    excl_coastal = fixest::fepois(stats::as.formula(paste(
      "hours ~ mhw_days + sst_anom |", fe)), data = p[dist_coast_km >= min_dist_km]),
    excl_low_cov = fixest::fepois(stats::as.formula(paste(
      "hours ~ mhw_days + sst_anom |", fe)), data = p[cell %in% active])
  )
  sums <- lapply(models, mfdc_vcov_summary, cutoff_km = 200, log_file = log_file)
  mfdc_log(sprintf("Exclusoes: %d celulas >= %g km da costa; %d com >= %d meses ativos",
    data.table::uniqueN(p[dist_coast_km >= min_dist_km, cell]), min_dist_km,
    length(active), min_active), file = log_file)
  list(summaries = lapply(sums, `[[`, "sum"), coefs = mfdc_coef_table(sums))
}

#' Modelo principal sob definicao alternativa de MHW (painel ja re-derivado)
mfdc_altdef_model <- function(panel_alt, label, log_file = NULL) {
  p <- mfdc_prep_panel(panel_alt)
  fe <- "cell + month + region^month_of_year"
  m <- fixest::fepois(stats::as.formula(paste(
    "hours ~ mhw_days + sst_anom |", fe)), data = p)
  s <- mfdc_vcov_summary(m, 200, log_file)
  sl <- stats::setNames(list(s), label)
  list(label = label, summary = s$sum, coefs = mfdc_coef_table(sl))
}

mfdc_save_robustness <- function(rob, alt_list, dir_models, dir_tables) {
  f1 <- file.path(dir_models, "robustness_res4.rds")
  saveRDS(list(rob = rob, alt = alt_list), f1)
  all_sums <- c(rob$summaries, lapply(alt_list, `[[`, "summary"))
  f2 <- file.path(dir_tables, "robustness_etable.txt")
  writeLines(capture.output(fixest::etable(all_sums)), f2)
  f3 <- file.path(dir_tables, "robustness_coefs.csv")
  data.table::fwrite(data.table::rbindlist(
    c(list(rob$coefs), lapply(alt_list, `[[`, "coefs")), fill = TRUE), f3)
  c(f1, f2, f3)
}
