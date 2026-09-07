# 10_data_quality.R — auditoria do cubo: chaves, cobertura, zeros, metricas
# para a decisao de resolucao (atualiza D2).

mfdc_quality_report <- function(panels, out_csv, log_file = NULL) {
  rows <- lapply(panels, function(p) {
    res <- p$grid_res[1]
    data.table::data.table(
      grid_res            = res,
      n_cells             = data.table::uniqueN(p$cell),
      n_months            = data.table::uniqueN(p$month),
      n_rows              = nrow(p),
      key_unique          = anyDuplicated(p[, .(cell, month)]) == 0L,
      sst_na_rows         = sum(is.na(p$sst_mean)),
      share_effort_pos    = round(mean(p$hours > 0), 4),
      share_mhw_any       = round(mean(p$mhw_days > 0, na.rm = TRUE), 4),
      mean_mhw_days       = round(mean(p$mhw_days, na.rm = TRUE), 2),
      total_hours         = round(sum(p$hours), 0),
      sd_within_log1p     = round(p[, .(s = stats::sd(log1p(hours))), by = cell][
                                    , mean(s, na.rm = TRUE)], 4),
      p50_hours_pos       = round(stats::median(p$hours[p$hours > 0]), 1)
    )
  })
  out <- data.table::rbindlist(rows)
  data.table::fwrite(out, out_csv)
  mfdc_log("Qualidade do cubo escrita em ", out_csv, file = log_file)
  # travas duras: chaves unicas e sem SST ausente em escala
  stopifnot(all(out$key_unique), all(out$sst_na_rows / out$n_rows < 0.01))
  out[]
}
