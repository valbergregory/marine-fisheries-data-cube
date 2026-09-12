# 11_descriptive_analysis.R — estatisticas descritivas do painel analitico.

mfdc_descriptives <- function(panel, gear_tbl, out_csv, log_file = NULL) {
  by_region <- panel[, .(
    cells        = data.table::uniqueN(cell),
    cell_months  = .N,
    share_pos    = round(mean(hours > 0), 3),
    hours_total  = round(sum(hours)),
    hours_mean_pos = round(mean(hours[hours > 0]), 1),
    sst_mean     = round(mean(sst_mean, na.rm = TRUE), 2),
    mhw_days_mean = round(mean(mhw_days, na.rm = TRUE), 2),
    share_mhw_any = round(mean(mhw_days > 0, na.rm = TRUE), 3),
    dist_coast_km = round(stats::median(dist_coast_km, na.rm = TRUE), 0)
  ), by = .(region = data.table::fifelse(is.na(region), "NA", region))][order(-hours_total)]

  overall <- panel[, .(region = "All", cells = data.table::uniqueN(cell),
    cell_months = .N, share_pos = round(mean(hours > 0), 3),
    hours_total = round(sum(hours)),
    hours_mean_pos = round(mean(hours[hours > 0]), 1),
    sst_mean = round(mean(sst_mean, na.rm = TRUE), 2),
    mhw_days_mean = round(mean(mhw_days, na.rm = TRUE), 2),
    share_mhw_any = round(mean(mhw_days > 0, na.rm = TRUE), 3),
    dist_coast_km = round(stats::median(dist_coast_km, na.rm = TRUE), 0))]

  out <- rbind(by_region, overall)
  data.table::fwrite(out, out_csv)
  data.table::fwrite(gear_tbl, sub("\\.csv$", "_gear.csv", out_csv))
  mfdc_log("Descritivas escritas em ", out_csv, file = log_file)
  out[]
}

#' Escritor .tex minimalista (sem dependencias extras): tabular booktabs-like.
mfdc_write_tex_table <- function(dt, file, caption, label, digits = 3) {
  esc <- function(x) gsub("([%_&#])", "\\\\\\1", x)
  fmt <- function(x) if (is.numeric(x)) formatC(x, format = "fg", digits = digits,
                                                big.mark = ",") else esc(as.character(x))
  body <- apply(dt, 1, function(r) paste(vapply(r, fmt, character(1)), collapse = " & "))
  tex <- c(
    "\\begin{table}[htbp]", "\\centering",
    sprintf("\\caption{%s}", caption), sprintf("\\label{%s}", label),
    sprintf("\\begin{tabular}{l%s}", strrep("r", ncol(dt) - 1L)),
    "\\hline",
    paste(gsub("_", "\\\\_", names(dt)), collapse = " & "), "\\\\ \\hline",
    paste0(body, " \\\\"),
    "\\hline", "\\end{tabular}", "\\end{table}")
  writeLines(tex, file)
  file
}
