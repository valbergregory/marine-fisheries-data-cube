# 03_download_fishing.R — esforco pesqueiro GFW (4wings, MONTHLY, 0.1 grau)
# Cache anual em Parquet (data/raw/gfw). Requer GFW_TOKEN no .Renviron.
# get_raster esta deprecado na gfwr 3.0 (sucessor: gfw_ais_fishing_hours),
# mas e a interface da versao pinada no renv.lock (GitHub b8e7dcd).

mfdc_gfw_poly <- function(bbox) {
  sf::st_as_sf(sf::st_as_sfc(sf::st_bbox(
    c(xmin = bbox$xmin, ymin = bbox$ymin, xmax = bbox$xmax, ymax = bbox$ymax),
    crs = sf::st_crs(4326))))
}

# Uma chamada 4wings com retry p/ rate limit (429); em erro de regiao
# grande, o chamador divide o bbox.
mfdc_gfw_call <- function(poly, y, attempts = 5L, log_file = NULL) {
  for (a in seq_len(attempts)) {
    r <- tryCatch(gfwr::get_raster(
      spatial_resolution = "LOW", temporal_resolution = "MONTHLY",
      start_date = sprintf("%d-01-01", y), end_date = sprintf("%d-01-01", y + 1),
      region_source = "USER_SHAPEFILE", region = poly,
      group_by = "FLAGANDGEARTYPE"), error = function(e) e)
    if (!inherits(r, "error")) return(r)
    if (!grepl("429", conditionMessage(r)) || a == attempts) return(r)
    wait_s <- 70 * a
    mfdc_log(sprintf("GFW 429 no ano %d — aguardando %ds (%d/%d)", y, wait_s, a, attempts),
             file = log_file)
    Sys.sleep(wait_s)
  }
}

#' Esforco de um ano para um bbox, com divisao recursiva se a API recusar
#' a regiao inteira (fallback em 2 metades latitudinais, profundidade <= 2).
mfdc_gfw_effort_year <- function(y, bbox, dir_out, log_file = NULL, depth = 0L) {
  dest <- file.path(dir_out, sprintf("gfw_effort_%d.parquet", y))
  if (file.exists(dest) && depth == 0L) {
    x <- tryCatch(arrow::read_parquet(dest), error = function(e) NULL)
    if (!is.null(x) && nrow(x) > 0) {
      mfdc_log(sprintf("GFW %d: cache (%d linhas)", y, nrow(x)), file = log_file)
      return(dest)
    }
  }
  r <- mfdc_gfw_call(mfdc_gfw_poly(bbox), y, log_file = log_file)
  if (inherits(r, "error")) {
    if (depth >= 2L) stop("GFW ", y, ": falhou mesmo com bbox dividido: ",
                          conditionMessage(r))
    mfdc_log(sprintf("GFW %d: regiao recusada (%s) — dividindo bbox (depth %d)",
                     y, conditionMessage(r), depth + 1L), file = log_file)
    mid <- (bbox$ymin + bbox$ymax) / 2
    b1 <- modifyList(bbox, list(ymax = mid)); b2 <- modifyList(bbox, list(ymin = mid))
    p1 <- mfdc_gfw_effort_year(y, b1, dir_out, log_file, depth + 1L)
    p2 <- mfdc_gfw_effort_year(y, b2, dir_out, log_file, depth + 1L)
    dt <- data.table::rbindlist(lapply(list(p1, p2), function(p)
      if (is.character(p)) arrow::read_parquet(p) else p), fill = TRUE)
    dt <- unique(dt)   # celulas na linha de corte podem duplicar
    if (depth > 0L) return(dt)
    arrow::write_parquet(dt, dest)
  } else {
    data.table::setDT(r)
    data.table::setnames(r,
      old = c("Lat", "Lon", "Time Range", "Flag", "Geartype",
              "Vessel IDs", "Apparent Fishing Hours"),
      new = c("lat", "lon", "month", "flag", "geartype", "n_vessels", "hours"),
      skip_absent = TRUE)
    r <- r[startsWith(month, as.character(y))]   # dezembro garantido, sem vazar ano+1
    if (depth > 0L) return(r)
    stopifnot(all(c("lat", "lon", "month", "hours") %in% names(r)))
    arrow::write_parquet(r, dest)
  }
  mfdc_register_download(dest,
    sprintf("https://gateway.api.globalfishingwatch.org/v3/4wings/report (MONTHLY, LOW, FLAGANDGEARTYPE, %d)", y),
    "gfw_4wings")
  x <- arrow::read_parquet(dest)
  mfdc_log(sprintf("GFW %d: %d linhas, %.0f horas", y, nrow(x),
                   sum(x$hours, na.rm = TRUE)), file = log_file)
  Sys.sleep(15)   # espaca chamadas p/ rate limit
  dest
}

#' Baixa todos os anos e devolve os paths (cacheado por ano)
mfdc_download_gfw <- function(years, bbox, dir_out, log_file = NULL) {
  dir.create(dir_out, recursive = TRUE, showWarnings = FALSE)
  vapply(years, mfdc_gfw_effort_year, character(1),
         bbox = bbox, dir_out = dir_out, log_file = log_file)
}

#' Le e empilha os parquets anuais
mfdc_read_gfw <- function(paths) {
  dt <- data.table::rbindlist(lapply(paths, arrow::read_parquet), fill = TRUE)
  stopifnot(nrow(dt) > 0, !anyNA(dt$lon), !anyNA(dt$lat))
  dt
}
