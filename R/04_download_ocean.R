# 04_download_ocean.R — OISST v2.1 completo: arquivos anuais GLOBAIS da PSL
# (~476 MB/ano), recortados localmente ao bbox do estudo (D15).
# Racional: OPeNDAP limita respostas a ~1-2 MB (D13) — inviavel p/ 19k pixels;
# NCSS/ERDDAP quebrados. Download unico + recorte local e o caminho robusto.
# Globais ficam em data/raw/oisst_global (imutaveis, com checksum);
# recortes anuais em data/raw/oisst_crop (RDS: lon, lat, dates, m).

mfdc_oisst_global_url <- function(y) sprintf(
  "https://downloads.psl.noaa.gov/Datasets/noaa.oisst.v2.highres/sst.day.mean.%d.nc", y)

mfdc_oisst_download_global <- function(y, dir_global, log_file = NULL, attempts = 3L) {
  dest <- file.path(dir_global, sprintf("sst.day.mean.%d.nc", y))
  # tamanho esperado via HEAD; cache valido se bate
  h <- curl::curl_fetch_memory(mfdc_oisst_global_url(y),
        handle = curl::new_handle(nobody = TRUE))
  exp_len <- suppressWarnings(as.numeric(
    curl::parse_headers_list(h$headers)[["content-length"]]))
  if (file.exists(dest) && !is.na(exp_len) && file.size(dest) == exp_len)
    return(dest)
  for (a in seq_len(attempts)) {
    ok <- tryCatch({
      curl::curl_download(mfdc_oisst_global_url(y), dest, quiet = TRUE)
      is.na(exp_len) || file.size(dest) == exp_len
    }, error = function(e) {
      mfdc_log(sprintf("OISST global %d falhou (%d/%d): %s", y, a, attempts,
                       conditionMessage(e)), file = log_file)
      FALSE
    })
    if (ok) {
      mfdc_register_download(dest, mfdc_oisst_global_url(y), "oisst_psl_global")
      return(dest)
    }
    Sys.sleep(20 * a)
  }
  stop("OISST global ", y, ": download falhou apos ", attempts, " tentativas.")
}

#' Baixa (se preciso) e recorta um ano ao bbox; devolve path do RDS de recorte.
mfdc_oisst_crop_year <- function(y, bbox, dir_global, dir_crop, log_file = NULL) {
  dir.create(dir_global, recursive = TRUE, showWarnings = FALSE)
  dir.create(dir_crop, recursive = TRUE, showWarnings = FALSE)
  dest <- file.path(dir_crop, sprintf("oisst_crop_%d.rds", y))
  if (file.exists(dest)) {
    x <- tryCatch(readRDS(dest), error = function(e) NULL)
    if (!is.null(x) && is.matrix(x$m) && ncol(x$m) == length(x$dates)) {
      mfdc_log(sprintf("OISST %d: recorte em cache", y), file = log_file)
      return(dest)
    }
  }
  g <- mfdc_oisst_download_global(y, dir_global, log_file)
  nc <- ncdf4::nc_open(g); on.exit(ncdf4::nc_close(nc), add = TRUE)
  lon_all <- as.numeric(ncdf4::ncvar_get(nc, "lon"))   # 0..360
  lat_all <- as.numeric(ncdf4::ncvar_get(nc, "lat"))
  lon360 <- function(x) x %% 360
  lon_idx <- which(lon_all >= lon360(bbox$xmin) - 0.125 & lon_all <= lon360(bbox$xmax) + 0.125)
  lat_idx <- which(lat_all >= bbox$ymin - 0.125 & lat_all <= bbox$ymax + 0.125)
  stopifnot(all(diff(lon_idx) == 1L), all(diff(lat_idx) == 1L))
  tm <- as.Date(floor(as.numeric(ncdf4::ncvar_get(nc, "time"))), origin = "1800-01-01")
  sst <- ncdf4::ncvar_get(nc, "sst",
    start = c(min(lon_idx), min(lat_idx), 1),
    count = c(length(lon_idx), length(lat_idx), length(tm)))
  if (length(dim(sst)) == 2L) dim(sst) <- c(dim(sst), 1L)
  x <- list(year = y, url = mfdc_oisst_global_url(y),
            lon = ifelse(lon_all[lon_idx] > 180, lon_all[lon_idx] - 360, lon_all[lon_idx]),
            lat = lat_all[lat_idx], dates = tm,
            m = matrix(sst, nrow = length(lon_idx) * length(lat_idx)))
  saveRDS(x, dest)
  mfdc_log(sprintf("OISST %d: recortado (%d pixels x %d dias)", y,
                   nrow(x$m), ncol(x$m)), file = log_file)
  dest
}

mfdc_download_oisst <- function(years, bbox, dir_global, dir_crop, log_file = NULL) {
  vapply(years, mfdc_oisst_crop_year, character(1), bbox = bbox,
         dir_global = dir_global, dir_crop = dir_crop, log_file = log_file)
}

#' Metadados da grade recortada (lon/lat/pixel_id/mascara oceanica)
mfdc_oisst_grid <- function(crop_paths) {
  x <- readRDS(crop_paths[[1]])
  n_lon <- length(x$lon); n_lat <- length(x$lat)
  pix <- data.table::data.table(expand.grid(lon_i = seq_len(n_lon), lat_i = seq_len(n_lat)))
  pix[, `:=`(pixel_id = .I, lon = x$lon[lon_i], lat = x$lat[lat_i])]
  pix[, ocean := rowSums(!is.na(x$m[, seq_len(min(30L, ncol(x$m))), drop = FALSE])) > 0]
  pix[]
}

#' Cubo diario apenas dos pixels pedidos (economia de RAM):
#' devolve list(dates, m[pixels_needed x dias]) na ordem de pixels_needed.
mfdc_oisst_cube <- function(crop_paths, pixels_needed, log_file = NULL) {
  mats <- vector("list", length(crop_paths)); dts <- vector("list", length(crop_paths))
  ref <- NULL
  for (k in seq_along(crop_paths)) {
    x <- readRDS(crop_paths[[k]])
    if (is.null(ref)) ref <- list(lon = x$lon, lat = x$lat)
    stopifnot(isTRUE(all.equal(x$lon, ref$lon)), isTRUE(all.equal(x$lat, ref$lat)))
    mats[[k]] <- x$m[pixels_needed, , drop = FALSE]
    dts[[k]] <- x$dates
  }
  dates <- as.Date(unlist(dts), origin = "1970-01-01")
  stopifnot(!anyDuplicated(dates), !is.unsorted(dates))
  list(dates = dates, m = do.call(cbind, mats))
}
