# 09_build_panel.R — painel celula x mes por resolucao (universo = fishing
# footprint, conforme decisao de viabilidade: PPML + footprint; universo
# integral fica reconstituivel a partir de cells_res*.parquet).

#' Esforco agregado a celulas H3 de uma resolucao.
mfdc_effort_by_cell <- function(gfw, res) {
  key <- unique(gfw[, .(lon, lat)])
  pts <- sf::st_as_sf(key, coords = c("lon", "lat"), crs = 4326)
  key[, cell := h3jsr::point_to_cell(pts, res = res, simple = TRUE)]
  g <- merge(gfw, key, by = c("lon", "lat"))
  g[, .(hours = sum(hours, na.rm = TRUE),
        n_vessels = sum(n_vessels, na.rm = TRUE)),
    by = .(cell, month)]
}

#' Painel completo de uma resolucao.
#' eff: mfdc_effort_by_cell; cells: mfdc_grid_cells + dist + region;
#' mhw_px: mfdc_mhw_monthly.
mfdc_build_panel <- function(eff, cells, mhw_px, res, months_all, log_file = NULL) {
  foot <- cells[cell %in% unique(eff$cell)]          # fishing footprint
  mfdc_log(sprintf("res %d: %d celulas oceanicas, %d no footprint (%.1f%%)",
    res, nrow(cells), nrow(foot), 100 * nrow(foot) / nrow(cells)), file = log_file)
  panel <- data.table::CJ(cell = foot$cell, month = months_all)
  panel <- merge(panel, foot, by = "cell")
  panel <- merge(panel, eff, by = c("cell", "month"), all.x = TRUE)
  panel[is.na(hours), hours := 0]
  panel[is.na(n_vessels), n_vessels := 0]
  panel[, effort_present := as.integer(hours > 0)]
  panel <- merge(panel, mhw_px, by = c("pixel_id", "month"), all.x = TRUE)
  stopifnot(nrow(panel) == nrow(foot) * length(months_all))
  if (anyNA(panel$sst_mean))
    mfdc_log(sprintf("res %d: %d linhas sem SST (pixel de terra?) — verificar",
      res, sum(is.na(panel$sst_mean))), file = log_file)
  panel[]
}
