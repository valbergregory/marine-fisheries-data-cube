# 08_build_grid.R — grades H3 (res 4 e 5) sobre o oceano do bbox,
# mapeadas ao pixel OISST mais proximo; regiao via UF mais proxima (geobr).

#' Celulas H3 de uma resolucao com centroide sobre pixel oceanico.
mfdc_grid_cells <- function(bbox, res, pix, log_file = NULL) {
  poly <- mfdc_gfw_poly(bbox)
  cells_all <- unique(unlist(h3jsr::polygon_to_cells(poly, res = res, simple = TRUE)))
  cent <- sf::st_coordinates(h3jsr::cell_to_point(cells_all, simple = TRUE))
  step <- 0.25
  lon0 <- pix[lon_i == 1L & lat_i == 1L, lon]
  lat0 <- pix[lon_i == 1L & lat_i == 1L, lat]
  n_lon <- max(pix$lon_i); n_lat <- max(pix$lat_i)
  li <- pmin(pmax(round((cent[, 1] - lon0) / step) + 1L, 1L), n_lon)
  la <- pmin(pmax(round((cent[, 2] - lat0) / step) + 1L, 1L), n_lat)
  cells <- data.table::data.table(
    cell = cells_all, grid_res = res,
    lon_c = cent[, 1], lat_c = cent[, 2],
    pixel_id = li + (la - 1L) * n_lon)
  cells[, ocean := pix$ocean[pixel_id]]
  out <- cells[ocean == TRUE][, ocean := NULL]
  mfdc_log(sprintf("H3 res %d: %d celulas no bbox, %d oceanicas",
                   res, length(cells_all), nrow(out)), file = log_file)
  out[]
}

#' Distancia (km) do centroide ao pixel de TERRA mais proximo (proxy de
#' distancia a costa com precisao ~0.25 grau; documentado no dicionario).
mfdc_dist_coast <- function(cells, pix) {
  land <- pix[ocean == FALSE]
  if (nrow(land) == 0L) { cells[, dist_coast_km := NA_real_]; return(cells[]) }
  land_sf <- sf::st_as_sf(land, coords = c("lon", "lat"), crs = 4326)
  cell_sf <- sf::st_as_sf(cells, coords = c("lon_c", "lat_c"), crs = 4326)
  idx <- sf::st_nearest_feature(cell_sf, land_sf)
  d <- sf::st_distance(cell_sf, land_sf[idx, ], by_element = TRUE)
  cells[, dist_coast_km := round(as.numeric(d) / 1000, 1)]
  cells[]
}

#' Regiao/UF costeira mais proxima via geobr (cache local do proprio geobr).
mfdc_assign_region <- function(cells, log_file = NULL) {
  uf <- tryCatch(geobr::read_state(year = 2020, showProgress = FALSE),
                 error = function(e) e)
  if (inherits(uf, "error")) {
    mfdc_log("geobr indisponivel — region/uf ficam NA: ",
             conditionMessage(uf), file = log_file)
    cells[, `:=`(uf_near = NA_character_, region = NA_character_)]
    return(cells[])
  }
  cell_sf <- sf::st_as_sf(cells, coords = c("lon_c", "lat_c"), crs = 4326)
  uf <- sf::st_transform(uf, 4326)
  idx <- sf::st_nearest_feature(cell_sf, uf)
  cells[, `:=`(uf_near = uf$abbrev_state[idx], region = uf$name_region[idx])]
  cells[]
}
