# 13_dynamic_effects.R — dinamica: leads (teste de antecipacao/placebo) +
# defasagens ate 6 meses. Especificacao preferida inclui sst_anom (R/12).

mfdc_dynamic_models <- function(panel, conley_cutoff_km = 200, log_file = NULL) {
  p <- mfdc_prep_panel(panel)
  data.table::setkey(p, cell, time_id)
  fe <- "cell + month + region^month_of_year"
  pid <- c("cell", "time_id")

  models <- list(
    # leads como placebo: sob nao-antecipacao, f(mhw_days, 1:3) ~ 0
    ppml_leads_lags = fixest::fepois(stats::as.formula(paste(
      "hours ~ f(mhw_days, 3) + f(mhw_days, 2) + f(mhw_days, 1) +",
      "l(mhw_days, 0:6) + sst_anom |", fe)), data = p, panel.id = pid),
    # so defasagens (perfil de persistencia/recuperacao)
    ppml_lags6 = fixest::fepois(stats::as.formula(paste(
      "hours ~ l(mhw_days, 0:6) + sst_anom |", fe)), data = p, panel.id = pid)
  )
  sums <- lapply(models, mfdc_vcov_summary, cutoff_km = conley_cutoff_km,
                 log_file = log_file)
  coefs <- data.table::rbindlist(lapply(names(sums), function(nm) {
    ct <- as.data.frame(sums[[nm]]$sum$coeftable)
    data.table::data.table(model = nm, term = rownames(ct), ct,
                           vcov = sums[[nm]]$vcov)
  }), fill = TRUE)

  # horizonte p/ event-study plot: -3..-1 leads, 0..6 lags
  es <- coefs[model == "ppml_leads_lags" & grepl("mhw_days", term)]
  es[, horizon := data.table::fcase(
    grepl("^f\\(", term), -as.integer(gsub("\\D", "", term)),
    grepl("^l\\(", term),  as.integer(gsub("\\D", "", term)),
    term == "mhw_days", 0L, default = NA_integer_)]

  list(grid_res = p$grid_res[1], summaries = lapply(sums, `[[`, "sum"),
       coefs = coefs, event_study = es[!is.na(horizon)][order(horizon)],
       meta = list(fe = fe, conley_cutoff_km = conley_cutoff_km))
}

mfdc_save_dynamic <- function(dyn, dir_models, dir_tables) {
  tag <- sprintf("res%d", dyn$grid_res)
  f1 <- file.path(dir_models, sprintf("dynamic_%s.rds", tag))
  saveRDS(dyn, f1)
  f2 <- file.path(dir_tables, sprintf("dynamic_etable_%s.txt", tag))
  writeLines(capture.output(fixest::etable(dyn$summaries)), f2)
  f3 <- file.path(dir_tables, sprintf("event_study_%s.csv", tag))
  data.table::fwrite(dyn$event_study, f3)
  c(f1, f2, f3)
}
