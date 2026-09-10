# 06_clean_fishing.R — harmonizacao do esforco GFW e painel por arte de pesca.

#' Classifica geartype em categorias analiticas (top-N por horas + "other").
mfdc_gear_classes <- function(gfw, top_n = 4L, min_share = 0.02) {
  g <- gfw[!is.na(geartype) & nzchar(geartype),
           .(h = sum(hours, na.rm = TRUE)), by = geartype][order(-h)]
  g[, share := h / sum(h)]
  keep <- g[seq_len(min(top_n, .N))][share >= min_share, geartype]
  keep <- setdiff(keep, "inconclusive")
  list(keep = keep, table = g[])
}

#' Esforco agregado a celula x mes x arte de pesca (classes de mfdc_gear_classes).
mfdc_effort_by_cell_gear <- function(gfw, res, gear_keep, log_file = NULL) {
  key <- unique(gfw[, .(lon, lat)])
  pts <- sf::st_as_sf(key, coords = c("lon", "lat"), crs = 4326)
  key[, cell := h3jsr::point_to_cell(pts, res = res, simple = TRUE)]
  g <- merge(gfw, key, by = c("lon", "lat"))
  g[, gear := data.table::fifelse(geartype %in% gear_keep, geartype, "other")]
  out <- g[, .(hours = sum(hours, na.rm = TRUE),
               n_vessels = sum(n_vessels, na.rm = TRUE)),
           by = .(cell, month, gear)]
  mfdc_log(sprintf("Esforco por arte (res %d): %d linhas, artes: %s", res,
    nrow(out), paste(sort(unique(out$gear)), collapse = ", ")), file = log_file)
  out[]
}

#' Painel celula x mes x arte (universo: celula-arte com esforco em >=1 mes).
mfdc_build_panel_gear <- function(eff_gear, cells, mhw_px, months_all,
                                  log_file = NULL) {
  units <- unique(eff_gear[, .(cell, gear)])
  units <- merge(units, cells, by = "cell")
  panel <- data.table::CJ(idx = seq_len(nrow(units)), month = months_all)
  panel <- cbind(units[panel$idx], month = panel$month)
  panel <- merge(panel, eff_gear, by = c("cell", "month", "gear"), all.x = TRUE)
  panel[is.na(hours), hours := 0]
  panel[is.na(n_vessels), n_vessels := 0]
  panel[, effort_present := as.integer(hours > 0)]
  panel <- merge(panel, mhw_px, by = c("pixel_id", "month"), all.x = TRUE)
  mfdc_log(sprintf("Painel por arte: %d linhas (%d unidades celula-arte x %d meses)",
    nrow(panel), nrow(units), length(months_all)), file = log_file)
  panel[]
}
