# 19_export_overleaf.R — empacota o material do artigo para Overleaf:
# outputs/overleaf/{tables,figures,numbers.tex}. Nunca escreve prosa; apenas
# tabelas (booktabs) e \newcommand com os numeros citados no texto.

mfdc_tex_escape <- function(x) gsub("([%_&#])", "\\\\\\1", x)

mfdc_booktabs <- function(dt, file, caption, label, digits = 2) {
  fmt <- function(v) {
    if (is.numeric(v) && all(v == round(v), na.rm = TRUE))
      format(v, big.mark = ",", scientific = FALSE, trim = TRUE)
    else if (is.numeric(v)) formatC(v, digits = digits, format = "f")
    else mfdc_tex_escape(as.character(v))
  }
  cells <- as.data.frame(lapply(dt, fmt), stringsAsFactors = FALSE)
  body <- apply(cells, 1, paste, collapse = " & ")
  writeLines(c(
    "\\begin{table}[htbp]\\centering",
    sprintf("\\caption{%s}\\label{%s}", caption, label),
    sprintf("\\begin{tabular}{l%s}", strrep("r", ncol(dt) - 1L)),
    "\\toprule", paste(mfdc_tex_escape(names(dt)), collapse = " & "),
    "\\\\ \\midrule", paste0(body, " \\\\"),
    "\\bottomrule", "\\end{tabular}\\end{table}"), file)
  file
}

#' Macros de numeros citados no texto (uma por valor).
mfdc_numbers_tex <- function(models, dyn, spill, rob, alt, het, quality,
                             descriptives, cfg, file, extra = NULL) {
  cf <- function(dt, m, t, what = "b", d = 4) {
    r <- dt[model == m & term == t]
    if (!nrow(r)) return("[missing]")
    formatC(r[[what]][1], format = "f", digits = d)
  }
  q4 <- quality[grid_res == 4]
  num <- list(
    panelObs        = format(models$n_obs, big.mark = ","),
    panelCells      = format(models$n_cells, big.mark = ","),
    panelStart      = substr(cfg$full_study$period$start, 1, 4),
    panelEnd        = substr(cfg$full_study$period$end, 1, 4),
    gridRes         = "4",
    shareEffortPos  = formatC(100 * q4$share_effort_pos, format = "f", digits = 1),
    shareMhwAny     = formatC(100 * q4$share_mhw_any, format = "f", digits = 1),
    meanMhwDays     = formatC(q4$mean_mhw_days, format = "f", digits = 2),
    totalHours      = format(round(q4$total_hours), big.mark = ","),
    mhwPctile       = as.character(cfg$mhw$percentile),
    mhwMinDuration  = as.character(cfg$mhw$min_duration_days),
    climStart       = substr(cfg$mhw$climatology_period$start, 1, 4),
    climEnd         = substr(cfg$mhw$climatology_period$end, 1, 4),
    conleyCutoff    = "200",
    # coeficientes principais (PPML com anomalia)
    bMhwMain        = cf(models$coefs, "ppml_mhw_anom", "mhw_days"),
    seMhwMain       = cf(models$coefs, "ppml_mhw_anom", "mhw_days", "se"),
    pMhwMain        = cf(models$coefs, "ppml_mhw_anom", "mhw_days", "p", 3),
    bSstAnom        = cf(models$coefs, "ppml_mhw_anom", "sst_anom"),
    seSstAnom       = cf(models$coefs, "ppml_mhw_anom", "sst_anom", "se"),
    bExtensive      = cf(models$coefs, "ext_lpm", "mhw_days"),
    pExtensive      = cf(models$coefs, "ext_lpm", "mhw_days", "p", 3),
    # efeito acumulado 0-6 meses (soma dos lags do modelo so-lags)
    bCumSixMonths   = formatC(dyn$coefs[model == "ppml_lags6" &
                        grepl("mhw_days", term), sum(b)], format = "f", digits = 4),
    # placebo: maior |t| entre os leads
    maxAbsTLead     = formatC(max(abs(dyn$event_study[horizon < 0, b /
                        pmax(se, 1e-12)])), format = "f", digits = 2),
    # spillovers por anel
    bRingNear       = cf(spill$coefs, "ppml_rings", "mhw_nb_k1"),
    pRingNear       = cf(spill$coefs, "ppml_rings", "mhw_nb_k1", "p", 3),
    bRingMid        = cf(spill$coefs, "ppml_rings", "mhw_nb_mid"),
    pRingMid        = cf(spill$coefs, "ppml_rings", "mhw_nb_mid", "p", 3),
    bRingFar        = cf(spill$coefs, "ppml_rings", "mhw_nb_far"),
    pRingFar        = cf(spill$coefs, "ppml_rings", "mhw_nb_far", "p", 3),
    # robustez
    bResFive        = cf(rob$coefs, "res5_main", "mhw_days"),
    bTrendRegYear   = cf(rob$coefs, "trend_regyr", "mhw_days"),
    bStableCells    = cf(rob$coefs, "stable_cells", "mhw_days"),
    bMhwPninetyfive = cf(alt[[1]]$coefs, "mhw_p95", "mhw_days"),
    nRegions        = as.character(nrow(descriptives) - 1L)
  )
  # alternativas 2 e 3 (duracao 10 dias; climatologia 1982-2011)
  if (length(alt) >= 2) num$bMhwDurTen <- cf(alt[[2]]$coefs, "mhw_dur10", "mhw_days")
  if (length(alt) >= 3) num$bMhwClimEarly <-
    cf(alt[[3]]$coefs, "mhw_clim1982_2011", "mhw_days")
  if (!is.null(extra)) {
    if (!is.null(extra$cum)) num <- c(num, list(
      bCumSixIC   = formatC(extra$cum$b[1], format = "f", digits = 4),
      seCumSix    = formatC(extra$cum$se[1], format = "f", digits = 4),
      pCumSix     = formatC(extra$cum$p[1], format = "f", digits = 3),
      loCumSix    = formatC(extra$cum$lo[1], format = "f", digits = 4),
      hiCumSix    = formatC(extra$cum$hi[1], format = "f", digits = 4)))
    if (!is.null(extra$placebo)) num <- c(num, list(
      nPermutations = as.character(extra$placebo$n_perm[1]),
      pPermutation  = formatC(extra$placebo$p_rand[1], format = "f", digits = 3)))
    if (!is.null(extra$moran)) num <- c(num, list(
      moranI      = formatC(extra$moran$moran_I[1], format = "f", digits = 4),
      pMoran      = formatC(extra$moran$p_perm[1], format = "f", digits = 3)))
    if (!is.null(extra$reloc)) {
      g <- function(m) { r <- extra$reloc[model == m & term == "mhw_exp"]
        if (nrow(r)) formatC(r$b[1], format = "f", digits = 4) else "[missing]" }
      num <- c(num, list(bRelocDistCoast = g("dist_coast"),
                         bRelocHHI = g("concentration"),
                         bRelocActive = g("active_cells")))
    }
  }
  writeLines(c("% generated by the targets pipeline (R/19_export_overleaf.R)",
               "% do not edit by hand — every number cited in the text is a macro",
               sprintf("\\newcommand{\\%s}{%s}", names(num), unlist(num))), file)
  file
}

#' Copia tabelas/figuras e escreve numbers.tex; devolve os arquivos criados.
mfdc_export_overleaf <- function(models, dyn, spill, rob, alt, het, quality,
                                 descriptives, cfg, tex_tables, figures,
                                 extra_numbers = NULL,
                                 out_dir = "outputs/overleaf", log_file = NULL) {
  dir.create(file.path(out_dir, "tables"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(out_dir, "figures"), recursive = TRUE, showWarnings = FALSE)
  file.copy(tex_tables, file.path(out_dir, "tables"), overwrite = TRUE)
  file.copy(figures, file.path(out_dir, "figures"), overwrite = TRUE)
  nums <- mfdc_numbers_tex(models, dyn, spill, rob, alt, het, quality,
                           descriptives, cfg, file.path(out_dir, "numbers.tex"),
                           extra = extra_numbers)
  # esqueleto e declaracoes acompanham o pacote (prosa e do autor)
  file.copy(c("article/main.tex", "article/references.bib",
              "article/ai_disclosure.tex", "article/data_code_availability.tex"),
            out_dir, overwrite = TRUE)
  files <- c(list.files(out_dir, recursive = TRUE, full.names = TRUE))
  mfdc_log(sprintf("Overleaf: %d arquivos em %s", length(files), out_dir),
           file = log_file)
  files
}
