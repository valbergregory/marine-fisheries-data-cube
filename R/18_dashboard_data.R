# 18_dashboard_data.R — agregados para o dashboard Shiny (app/app.R).
# Licenca: derivados da API da GFW sao CC BY-NC 4.0 (docs/gfw_api_terms.md);
# os arquivos gravados aqui carregam essa nota e a atribuicao obrigatoria.
# Contrato: funcao pura; recebe o painel e grava em data/processed/dashboard.
# Nivel de agregacao: celula x ano e regiao x mes (nada por embarcacao).

mfdc_dashboard_attribution <- function(year = format(Sys.Date(), "%Y")) {
  sprintf(paste0(
    "Fishing effort: Copyright %s, Global Fishing Watch, Inc., ",
    "https://globalfishingwatch.org/our-apis/ (4Wings API v3), CC BY-NC 4.0 — ",
    "apparent fishing effort, non-commercial use only. ",
    "SST: NOAA OISST v2.1 (public domain). MHW: Hobday et al. (2016)."), year)
}

mfdc_dashboard_data <- function(panel, out_dir = "data/processed/dashboard",
                                log_file = NULL) {
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  p <- data.table::as.data.table(panel)
  p[, year := as.integer(substr(month, 1, 4))]

  cell_year <- p[, .(hours = sum(hours), mean_mhw_days = mean(mhw_days, na.rm = TRUE),
                     mean_sst_anom = mean(sst_anom, na.rm = TRUE),
                     months_active = sum(hours > 0)),
                 by = .(cell, region, year)]
  region_month <- p[, .(hours = sum(hours), mean_mhw_days = mean(mhw_days, na.rm = TRUE),
                        share_mhw = mean(mhw_days > 0, na.rm = TRUE),
                        mean_sst_anom = mean(sst_anom, na.rm = TRUE)),
                    by = .(region, month)]

  cells <- unique(p[, .(cell, region, lon_c, lat_c, dist_coast_km)])
  geom <- h3jsr::cell_to_polygon(cells$cell, simple = FALSE)
  cells_sf <- sf::st_sf(as.data.frame(cells), geometry = sf::st_geometry(geom))
  # hexagonos que cruzam o antimeridiano nao existem aqui; so validar
  cells_sf <- sf::st_make_valid(cells_sf)

  files <- c(
    cells  = file.path(out_dir, "cells.rds"),
    cell_year = file.path(out_dir, "cell_year.parquet"),
    region_month = file.path(out_dir, "region_month.parquet"),
    notice = file.path(out_dir, "LICENSE_NOTICE.txt"))
  saveRDS(cells_sf, files[["cells"]])
  arrow::write_parquet(cell_year, files[["cell_year"]])
  arrow::write_parquet(region_month, files[["region_month"]])
  writeLines(c(mfdc_dashboard_attribution(),
               "Derived aggregates (cell x year, region x month) are shared under CC BY-NC 4.0.",
               "See docs/gfw_api_terms.md."), files[["notice"]])
  mfdc_log(sprintf("Dashboard: %d celulas, %d celula-anos, %d regiao-meses",
                   nrow(cells_sf), nrow(cell_year), nrow(region_month)), file = log_file)
  unname(files)
}
