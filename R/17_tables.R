# 17_tables.R — tabelas do artigo em LaTeX, geradas pelo pipeline.
# Regra do projeto: numeros do artigo NUNCA sao digitados a mao; o .tex e
# incluido no manuscrito (\input{}) e a prosa e escrita pelo autor.

mfdc_tex_models <- function(sums, file, title, label, notes = NULL,
                            dict = NULL) {
  if (file.exists(file)) unlink(file)
  fixest::etable(sums, tex = TRUE, file = file, replace = TRUE,
                 title = title, label = label, notes = notes,
                 dict = c(hours = "Fishing hours",
                          effort_present = "Any effort (0/1)",
                          mhw_days = "MHW days",
                          mhw_max_int = "MHW max. intensity",
                          sst_anom = "SST anomaly",
                          mhw_nb_k1 = "Neighbour MHW (0-60 km)",
                          mhw_nb_mid = "Neighbour MHW (60-150 km)",
                          mhw_nb_far = "Neighbour MHW (150-300 km)",
                          cell = "Cell", month = "Month",
                          cell_gear = "Cell x gear",
                          region = "Region", year = "Year",
                          month_of_year = "Month of year", dict))
  file
}

mfdc_build_tables <- function(models, dyn, spill, rob, alt, het, desc,
                              dir_tables) {
  dir.create(dir_tables, recursive = TRUE, showWarnings = FALSE)
  f <- character(0)
  f <- c(f, mfdc_write_tex_table(desc, file.path(dir_tables, "tab01_descriptives.tex"),
    "Descriptive statistics by coastal region, 2013-2024 (H3 res.\\ 4 fishing footprint)",
    "tab:desc"))
  f <- c(f, mfdc_tex_models(models$summaries,
    file.path(dir_tables, "tab02_main.tex"),
    "Marine heatwave exposure and apparent fishing effort", "tab:main",
    notes = "Conley standard errors (200 km). Associational estimates; see identification strategy."))
  f <- c(f, mfdc_tex_models(dyn$summaries,
    file.path(dir_tables, "tab03_dynamics.tex"),
    "Dynamic specification: leads (placebo) and lags", "tab:dyn"))
  f <- c(f, mfdc_tex_models(spill$summaries,
    file.path(dir_tables, "tab04_spillovers.tex"),
    "Spatial displacement: neighbourhood exposure by distance ring", "tab:spill"))
  f <- c(f, mfdc_tex_models(het$summaries,
    file.path(dir_tables, "tab05_heterogeneity.tex"),
    "Heterogeneity by region, gear type and distance to coast", "tab:het"))
  f <- c(f, mfdc_tex_models(c(rob$summaries, lapply(alt, `[[`, "summary")),
    file.path(dir_tables, "tab06_robustness.tex"),
    "Robustness: grid resolution, trends, sample, Conley cutoffs and MHW definition",
    "tab:rob"))
  f
}

#' Digest factual dos resultados (numeros + metadados) para o autor escrever a
#' prosa. NAO contem interpretacao redigida para o artigo.
mfdc_results_digest <- function(models, dyn, spill, rob, alt, het, quality,
                                out_md, extras = NULL) {
  num <- function(dt, m, t) {
    r <- dt[model == m & term == t]
    if (!nrow(r)) return("n/a")
    sprintf("%.4f (SE %.4f, p=%.3g)", r$b[1], r$se[1], r$p[1])
  }
  all_coefs <- data.table::rbindlist(list(models$coefs, dyn$coefs, spill$coefs,
    rob$coefs, het$coefs, data.table::rbindlist(lapply(alt, `[[`, "coefs"))),
    fill = TRUE)
  lines <- c(
    "# Results digest (machine-generated; prose is written by the author)",
    sprintf("Generated: %s", format(Sys.time(), "%Y-%m-%d %H:%M")),
    "", "## Panel", sprintf("- Grid: H3 res 4; obs = %s; cells = %s",
      format(models$n_obs, big.mark = ","), format(models$n_cells, big.mark = ",")),
    "", "## Main (PPML, Conley 200 km)",
    sprintf("- MHW days (no controls): %s", num(models$coefs, "ppml_mhw", "mhw_days")),
    sprintf("- MHW days | SST anomaly: %s", num(models$coefs, "ppml_mhw_anom", "mhw_days")),
    sprintf("- SST anomaly: %s", num(models$coefs, "ppml_mhw_anom", "sst_anom")),
    sprintf("- Extensive margin: %s", num(models$coefs, "ext_lpm", "mhw_days")),
    "", "## Dynamics (leads = placebo)",
    dyn$event_study[, sprintf("- h=%d: %.4f (SE %.4f, p=%.3g)", horizon, b, se, p)],
    "", "## Spillovers by ring",
    sprintf("- own: %s", num(spill$coefs, "ppml_rings", "mhw_days")),
    sprintf("- 0-60 km: %s", num(spill$coefs, "ppml_rings", "mhw_nb_k1")),
    sprintf("- 60-150 km: %s", num(spill$coefs, "ppml_rings", "mhw_nb_mid")),
    sprintf("- 150-300 km: %s", num(spill$coefs, "ppml_rings", "mhw_nb_far")),
    "", "## Heterogeneity (full coefficients in heterogeneity_coefs.csv)",
    het$coefs[grepl("mhw_days", term),
      sprintf("- %s | %s: %.4f (SE %.4f, p=%.3g)", model, term, b, se, p)],
    "", "## Robustness",
    rob$coefs[term == "mhw_days",
      sprintf("- %s: %.4f (SE %.4f, p=%.3g)", model, b, se, p)],
    data.table::rbindlist(lapply(alt, `[[`, "coefs"))[term == "mhw_days",
      sprintf("- %s: %.4f (SE %.4f, p=%.3g)", model, b, se, p)],
    "", "## Cube quality", paste0("- ", capture.output(print(quality))))

  if (!is.null(extras)) {
    add <- c("", "## Cumulative effect (lags 0-6, Conley SE)")
    if (!is.null(extras$cum)) add <- c(add, extras$cum[, sprintf(
      "- sum of %d lags: %.4f (SE %.4f, p=%.3g; 95%% CI %.4f to %.4f)",
      k, b, se, p, lo, hi)])
    if (!is.null(extras$nonlin)) add <- c(add, "", "## Non-linear bins",
      extras$nonlin$coefs[grepl("_bin::", term),
        sprintf("- %s: %.4f (SE %.4f, p=%.3g)", term, b, se, p)])
    if (!is.null(extras$placebos)) add <- c(add, "", "## Placebos",
      extras$placebos$temporal_coefs[grepl("^f[(]", term),
        sprintf("- 12-month lead UNCONDITIONAL (proxies persistent MHW regimes; not a valid test): %.4f (SE %.4f, p=%.3g)", b, se, p)],
      if (!is.null(extras$lead12)) extras$lead12$coefs[grepl("^f[(]", term),
        sprintf("- 12-month lead CONDITIONAL on lags 0-6 (valid placebo): %.4f (SE %.4f, p=%.3g)", b, se, p)],
      extras$placebos$permutation[, sprintf(
        "- spatial permutation: observed %.4f vs perm mean %.4f (sd %.4f), p_rand=%.3f, 95%% perm range [%.4f, %.4f]",
        b_obs, perm_mean, perm_sd, p_rand, perm_q025, perm_q975)])
    if (!is.null(extras$celltrend)) add <- c(add, "",
      "## Cell-specific linear trends (D19) — placebo-consistent specification",
      extras$celltrend$coefs[model == "main_celltrend" & term == "mhw_days",
        sprintf("- main effect with cell trends: %.4f (SE %.4f, p=%.3g)", b, se, p)],
      extras$celltrend$coefs[model == "lead12_celltrend" & grepl("^f[(]", term),
        sprintf("- 12-month lead with cell trends: %.4f (SE %.4f, p=%.3g)", b, se, p)],
      extras$celltrend$cumulative[, sprintf(
        "- cumulative lags 0-6 with cell trends: %.4f (SE %.4f, p=%.3g; 95%% CI %.4f to %.4f)",
        b, se, p, lo, hi)])
    if (!is.null(extras$exclusions)) add <- c(add, "", "## Sample exclusions",
      extras$exclusions$coefs[term == "mhw_days",
        sprintf("- %s: %.4f (SE %.4f, p=%.3g)", model, b, se, p)])
    if (!is.null(extras$relocation)) add <- c(add, "",
      "## Reallocation (region-month; only 4 regions, read with caution)",
      extras$relocation$coefs[term == "mhw_exp",
        sprintf("- %s: %.4f (SE %.4f, p=%.3g)", model, b, se, p)])
    if (!is.null(extras$moran)) add <- c(add, "", "## Residual spatial dependence",
      extras$moran[, sprintf("- Moran's I = %.4f (permutation p = %.3f, %d cells, %g km)",
        moran_I, p_perm, n_cells, d_max_km)])
    lines <- c(lines, add)
  }
  writeLines(lines, out_md)
  out_md
}
