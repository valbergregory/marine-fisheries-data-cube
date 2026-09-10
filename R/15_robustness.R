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
