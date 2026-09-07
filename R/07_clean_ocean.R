# 07_clean_ocean.R — climatologia + eventos MHW (Hobday et al. 2016 via
# heatwaveR) por pixel, agregados a mes. Mesmo algoritmo validado no piloto.

#' MHW mensal por pixel. cube = mfdc_oisst_cube(); pixels na MESMA ordem.
#' Devolve data.table pixel_id x month: sst_mean, mhw_days, mhw_max_int.
mfdc_mhw_monthly <- function(cube, pixel_ids, cfg, period_start, period_end,
                             log_file = NULL) {
  stopifnot(nrow(cube$m) == length(pixel_ids))
  keep <- cube$dates >= as.Date(period_start) & cube$dates <= as.Date(period_end)
  mm <- format(cube$dates[keep], "%Y-%m")
  out <- vector("list", length(pixel_ids))
  for (j in seq_along(pixel_ids)) {
    dfp <- data.frame(t = cube$dates, temp = cube$m[j, ])
    if (all(is.na(dfp$temp))) next   # pixel de terra que escapou da mascara
    clim <- heatwaveR::ts2clm(dfp,
      climatologyPeriod = c(cfg$mhw$climatology_period$start,
                            cfg$mhw$climatology_period$end),
      pctile = cfg$mhw$percentile,
      smoothPercentileWidth = cfg$mhw$smooth_percentile_window)
    ev <- heatwaveR::detect_event(clim,
      minDuration = cfg$mhw$min_duration_days, maxGap = cfg$mhw$max_gap_days)
    cl <- ev$climatology[keep, c("temp", "seas", "thresh", "event")]
    out[[j]] <- data.table::data.table(
      pixel_id = pixel_ids[j], month = mm,
      sst = cl$temp, seas = cl$seas, thresh = cl$thresh, mhw = cl$event
    )[, .(
      sst_mean    = mean(sst, na.rm = TRUE),
      sst_anom    = mean(sst - seas, na.rm = TRUE),
      mhw_days    = sum(mhw, na.rm = TRUE),
      mhw_max_int = { v <- (sst - thresh)[mhw %in% TRUE]
                      if (length(v) && any(is.finite(v))) max(v, na.rm = TRUE) else 0 }
    ), by = .(pixel_id, month)]
    if (!is.null(log_file) && j %% 250L == 0L)
      mfdc_log(sprintf("  MHW: %d/%d pixels", j, length(pixel_ids)), file = log_file)
  }
  data.table::rbindlist(out)
}
