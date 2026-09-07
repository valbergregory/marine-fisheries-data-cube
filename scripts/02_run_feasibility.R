# 02_run_feasibility.R — piloto de viabilidade (Background Job)
# Pré-requisitos: token GFW no .Renviron + scripts/00b_install_dependencies.R OK.
# Escopo: NE (bbox em config), 2022-2023, mensal, <=400 células.
# Produz: data/interim/pilot/*.parquet + outputs/diagnostics/feasibility_metrics.csv
#         + outputs/diagnostics/gfw_composition_pilot.csv (p/ perguntas 9-10).
# OISST via OPeNDAP (dodsC) da PSL com recorte por indices no servidor:
# o NCSS passou a devolver 500/502 em 2026-09-05/07, mas o servico OPeNDAP do
# mesmo THREDDS segue funcional e o ncdf4 do Windows le dodsC (validado
# 2026-09-07). Cache local por ano em RDS (data/raw imutavel + checksums).
# ERDDAP segue indisponivel.

local({
  find_root <- function(start) {
    p <- normalizePath(start, winslash = "/")
    while (!file.exists(file.path(p, "marine-fisheries-data-cube.Rproj"))) {
      parent <- dirname(p); if (parent == p) stop("Raiz nao encontrada."); p <- parent
    }
    p
  }
  root <- find_root("."); setwd(root)
  source(file.path(root, "R", "00_setup.R"))
  source(file.path(root, "R", "01_config.R"))
  source(file.path(root, "R", "02_utils.R"))
  log_file <- mfdc_open_log("02_run_feasibility")
  mfdc_log("== INICIO piloto de viabilidade ==", file = log_file)

  cfg <- mfdc_config()
  fz <- cfg$feasibility
  mfdc_assert_bbox(fz$bbox)
  mfdc_require_env("GFW_TOKEN",
    "Token da Global Fishing Watch (https://globalfishingwatch.org/our-apis/).")

  for (p in c("gfwr", "sf", "heatwaveR", "arrow", "h3jsr", "ncdf4", "curl", "data.table"))
    if (!requireNamespace(p, quietly = TRUE))
      stop("Pacote '", p, "' ausente. Rode scripts/00b_install_dependencies.R primeiro.")
  suppressMessages({ library(data.table); library(sf) })

  gc(reset = TRUE)
  t0 <- Sys.time()
  mins_since <- function(a, b = Sys.time()) as.numeric(difftime(b, a, units = "mins"))

  dir_oisst <- file.path("data", "raw", "pilot", "oisst")
  dir_gfw   <- file.path("data", "raw", "pilot", "gfw")
  dir_int   <- file.path("data", "interim", "pilot")
  dir_diag  <- file.path("outputs", "diagnostics")
  for (d in c(dir_oisst, dir_gfw, dir_int, dir_diag))
    dir.create(d, recursive = TRUE, showWarnings = FALSE)

  bbox <- fz$bbox
  months_pilot <- mfdc_month_seq(fz$period$start, fz$period$end)
  yr_clim0 <- as.integer(format(as.Date(cfg$mhw$climatology_period$start), "%Y"))
  yr_pil0  <- as.integer(format(as.Date(fz$period$start), "%Y"))
  yr_pil1  <- as.integer(format(as.Date(fz$period$end), "%Y"))
  years_sst <- yr_clim0:yr_pil1   # inclui 2021 p/ serie diaria continua

  ## ---- 1/6 GFW: esforco mensal 0.1 grau -------------------------------
  mfdc_log("1/6 GFW 4wings: esforco mensal 0.1 grau...", file = log_file)
  poly <- st_as_sf(st_as_sfc(st_bbox(
    c(xmin = bbox$xmin, ymin = bbox$ymin, xmax = bbox$xmax, ymax = bbox$ymax),
    crs = st_crs(4326))))
  # get_raster esta deprecado na gfwr 3.0 (sucessor: gfw_ais_fishing_hours),
  # mas e a interface da versao pinada no renv.lock (GitHub b8e7dcd).
  # A API gratuita aplica rate limit (HTTP 429): retry com espera progressiva.
  gfw_year <- function(y, attempts = 5L) {
    for (a in seq_len(attempts)) {
      r <- tryCatch(gfwr::get_raster(
        spatial_resolution = "LOW", temporal_resolution = "MONTHLY",
        start_date = sprintf("%d-01-01", y), end_date = sprintf("%d-01-01", y + 1),
        region_source = "USER_SHAPEFILE", region = poly, group_by = "FLAGANDGEARTYPE"),
        error = function(e) e)
      if (!inherits(r, "error")) return(r)
      if (!grepl("429", conditionMessage(r)) || a == attempts) stop(r)
      wait_s <- 70 * a
      mfdc_log(sprintf("GFW 429 (rate limit) no ano %d — aguardando %d s (tentativa %d/%d)",
                       y, wait_s, a, attempts), file = log_file)
      Sys.sleep(wait_s)
    }
  }
  gfw_raw <- rbindlist(lapply(yr_pil0:yr_pil1, function(y) {
    # end = 1o de janeiro seguinte + filtro ao proprio ano: garante dezembro
    # completo qualquer que seja a convencao (inclusiva/exclusiva) da API
    r <- gfw_year(y)
    Sys.sleep(15)   # espaca as chamadas p/ nao reincidir no rate limit
    setDT(r)
    r[startsWith(`Time Range`, as.character(y))]
  }), fill = TRUE)
  setnames(gfw_raw,
    old = c("Lat", "Lon", "Time Range", "Flag", "Geartype",
            "Vessel IDs", "Apparent Fishing Hours"),
    new = c("lat", "lon", "month", "flag", "geartype", "n_vessels", "hours"),
    skip_absent = TRUE)
  stopifnot(all(c("lat", "lon", "month", "hours") %in% names(gfw_raw)),
            nrow(gfw_raw) > 0)
  f_gfw <- file.path(dir_gfw, "gfw_effort_monthly_raw.parquet")
  arrow::write_parquet(gfw_raw, f_gfw)
  mfdc_register_download(f_gfw,
    "https://gateway.api.globalfishingwatch.org/v3/4wings/report (MONTHLY, LOW, FLAGANDGEARTYPE)",
    "gfw_4wings")
  mfdc_log(sprintf("GFW: %d linhas, %.1f horas, %d meses com esforco, %d pares flag x gear",
    nrow(gfw_raw), sum(gfw_raw$hours, na.rm = TRUE), uniqueN(gfw_raw$month),
    nrow(unique(gfw_raw[, .(flag, geartype)]))), file = log_file)
  t_gfw <- Sys.time()

  ## ---- 2/6 OISST via OPeNDAP (PSL dodsC), recorte no servidor ---------
  mfdc_log(sprintf("2/6 OISST OPeNDAP: %d-%d, %d anos...",
                   yr_clim0, yr_pil1, length(years_sst)), file = log_file)
  lon360 <- function(x) x %% 360
  url_year <- function(y) sprintf(
    "https://psl.noaa.gov/thredds/dodsC/Datasets/noaa.oisst.v2.highres/sst.day.mean.%d.nc", y)

  # indices do bbox lidos da grade real do primeiro ano (lon 0-360 no OISST)
  nc0 <- NULL
  for (a in 1:5) {
    nc0 <- tryCatch(ncdf4::nc_open(url_year(years_sst[1])), error = function(e) e)
    if (!inherits(nc0, "error")) break
    mfdc_log(sprintf("OPeNDAP indisponivel (tentativa %d/5): %s",
                     a, conditionMessage(nc0)), file = log_file)
    Sys.sleep(30 * a)
  }
  if (inherits(nc0, "error")) stop("OPeNDAP PSL indisponivel apos 5 tentativas.")
  lon_all <- as.numeric(ncdf4::ncvar_get(nc0, "lon"))
  lat_all <- as.numeric(ncdf4::ncvar_get(nc0, "lat"))
  ncdf4::nc_close(nc0)
  lon_idx <- which(lon_all >= lon360(bbox$xmin) - 0.125 & lon_all <= lon360(bbox$xmax) + 0.125)
  lat_idx <- which(lat_all >= bbox$ymin - 0.125 & lat_all <= bbox$ymax + 0.125)
  stopifnot(length(lon_idx) > 0, length(lat_idx) > 0,
            all(diff(lon_idx) == 1L), all(diff(lat_idx) == 1L))
  lon_v <- ifelse(lon_all[lon_idx] > 180, lon_all[lon_idx] - 360, lon_all[lon_idx])
  lat_v <- lat_all[lat_idx]

  # O DAP da PSL recusa fatias de 365 dias mas aceita ate ~183 (medido em
  # 2026-09-07: 365 falha; 183 OK ~55s; 92 OK ~28s; 31 OK ~9s). Leitura em
  # fatias semestrais, com conexao propria e retry POR FATIA.
  dap_retry <- function(what, y, fun, attempts = 4L) {
    for (a in seq_len(attempts)) {
      out <- tryCatch(fun(), error = function(e) e)
      if (!inherits(out, "error")) return(out)
      mfdc_log(sprintf("  OISST %d %s falhou (%d/%d): %s",
                       y, what, a, attempts, conditionMessage(out)), file = log_file)
      Sys.sleep(15 * a)
    }
    stop("OISST ", y, " (", what, "): OPeNDAP falhou apos ", attempts, " tentativas.")
  }
  fetch_year <- function(y, chunk_days = 183L) {
    dest <- file.path(dir_oisst, sprintf("oisst_ne_%d.rds", y))
    if (file.exists(dest)) {
      x <- tryCatch(readRDS(dest), error = function(e) NULL)
      if (!is.null(x) && is.matrix(x$m) &&
          nrow(x$m) == length(lon_idx) * length(lat_idx))
        return(list(x = x, new = FALSE))
    }
    tm <- dap_retry("time", y, function() {
      nc <- ncdf4::nc_open(url_year(y))
      on.exit(ncdf4::nc_close(nc), add = TRUE)
      as.Date(floor(as.numeric(ncdf4::ncvar_get(nc, "time"))), origin = "1800-01-01")
    })
    starts <- seq(1L, length(tm), by = chunk_days)
    cols <- lapply(starts, function(s) {
      cnt <- min(chunk_days, length(tm) - s + 1L)
      sst <- dap_retry(sprintf("t=%d+%d", s, cnt), y, function() {
        nc <- ncdf4::nc_open(url_year(y))
        on.exit(ncdf4::nc_close(nc), add = TRUE)
        ncdf4::ncvar_get(nc, "sst",
          start = c(min(lon_idx), min(lat_idx), s),
          count = c(length(lon_idx), length(lat_idx), cnt))
      })
      matrix(sst, nrow = length(lon_idx) * length(lat_idx))
    })
    x <- list(year = y, url = url_year(y), lon = lon_v, lat = lat_v,
              dates = tm, m = do.call(cbind, cols))
    saveRDS(x, dest)
    mfdc_register_download(dest, sprintf("%s (OPeNDAP, lon_idx %d:%d, lat_idx %d:%d)",
      url_year(y), min(lon_idx), max(lon_idx), min(lat_idx), max(lat_idx)),
      "oisst_psl_opendap")
    list(x = x, new = TRUE)
  }

  n_new <- 0L
  mats <- vector("list", length(years_sst)); dts <- vector("list", length(years_sst))
  for (k in seq_along(years_sst)) {
    r <- fetch_year(years_sst[k])
    if (r$new) n_new <- n_new + 1L
    stopifnot(isTRUE(all.equal(r$x$lon, lon_v)), isTRUE(all.equal(r$x$lat, lat_v)),
              ncol(r$x$m) == length(r$x$dates))
    mats[[k]] <- r$x$m
    dts[[k]] <- r$x$dates
    mfdc_log(sprintf("  OISST: %d/%d anos (%d %s)", k, length(years_sst),
      years_sst[k], if (r$new) "baixado" else "cache"), file = log_file)
  }
  t_dl <- Sys.time()

  ## ---- 3/6 Montagem do cubo SST ---------------------------------------
  mfdc_log("3/6 Montando cubo SST...", file = log_file)
  first <- list(lon = lon_v, lat = lat_v)
  n_lon <- length(lon_v); n_lat <- length(lat_v)
  pix <- data.table(expand.grid(lon_i = seq_len(n_lon), lat_i = seq_len(n_lat)))
  pix[, `:=`(pixel_id = .I, lon = lon_v[lon_i], lat = lat_v[lat_i])]
  M <- do.call(cbind, mats)
  rm(mats)
  dates <- as.Date(unlist(dts), origin = "1970-01-01")
  stopifnot(!anyDuplicated(dates), !is.unsorted(dates))
  n_gaps <- as.integer(max(dates) - min(dates)) + 1L - length(dates)
  ocean <- rowSums(!is.na(M[, seq_len(min(30L, ncol(M))), drop = FALSE])) > 0
  mfdc_log(sprintf("SST: %d pixels (%d oceanicos), %d dias (%s a %s), %d lacunas",
    nrow(M), sum(ocean), ncol(M), format(min(dates)), format(max(dates)), n_gaps),
    file = log_file)
  t_read <- Sys.time()

  ## ---- 4/6 Grade H3 e amostra -----------------------------------------
  mfdc_log("4/6 Grade H3 e amostra de celulas...", file = log_file)
  res_h3 <- fz$grid$h3_resolution
  cells_all <- unique(unlist(h3jsr::polygon_to_cells(poly, res = res_h3, simple = TRUE)))
  cent <- st_coordinates(h3jsr::cell_to_point(cells_all, simple = TRUE))
  step <- 0.25
  li <- pmin(pmax(round((cent[, 1] - first$lon[1]) / step) + 1L, 1L), n_lon)
  la <- pmin(pmax(round((cent[, 2] - first$lat[1]) / step) + 1L, 1L), n_lat)
  cells <- data.table(cell = cells_all, lon_c = cent[, 1], lat_c = cent[, 2],
                      pixel_id = li + (la - 1L) * n_lon)
  cells[, ocean := ocean[pixel_id]]
  n_univ <- cells[, sum(ocean)]
  cells_s <- cells[ocean == TRUE]
  set.seed(cfg$seed)
  if (nrow(cells_s) > fz$max_cells_sample)
    cells_s <- cells_s[sample(.N, fz$max_cells_sample)]
  cells_s[, dist_km := {
    dx <- (lon_c - pix$lon[pixel_id]) * 111.32 * cospi(lat_c / 180)
    dy <- (lat_c - pix$lat[pixel_id]) * 110.57
    sqrt(dx^2 + dy^2)
  }]
  mfdc_log(sprintf("H3 res %d: %d celulas no bbox, %d oceanicas, %d amostradas (seed %d)",
    res_h3, length(cells_all), n_univ, nrow(cells_s), cfg$seed), file = log_file)

  ## ---- 5/6 MHW (Hobday et al. 2016) + SST mensal ----------------------
  pixels_needed <- sort(unique(cells_s$pixel_id))
  mfdc_log(sprintf("5/6 MHW (heatwaveR) em %d pixels...", length(pixels_needed)),
           file = log_file)
  in_pilot <- dates >= as.Date(fz$period$start) & dates <= as.Date(fz$period$end)
  mm_pilot <- format(dates[in_pilot], "%Y-%m")
  d0 <- as.Date(fz$period$start); d1 <- as.Date(fz$period$end)
  mhw_list <- vector("list", length(pixels_needed))
  ev_total <- 0L; ev_pilot <- 0L; px_with_ev_pilot <- 0L
  for (j in seq_along(pixels_needed)) {
    p <- pixels_needed[j]
    dfp <- data.frame(t = dates, temp = M[p, ])
    clim <- heatwaveR::ts2clm(dfp,
      climatologyPeriod = c(cfg$mhw$climatology_period$start,
                            cfg$mhw$climatology_period$end),
      pctile = cfg$mhw$percentile,
      smoothPercentileWidth = cfg$mhw$smooth_percentile_window)
    ev <- heatwaveR::detect_event(clim,
      minDuration = cfg$mhw$min_duration_days, maxGap = cfg$mhw$max_gap_days)
    cl <- ev$climatology[in_pilot, c("temp", "event")]
    mhw_list[[j]] <- data.table(pixel_id = p, month = mm_pilot,
                                sst = cl$temp, mhw = cl$event)[
      , .(sst_mean = mean(sst, na.rm = TRUE), mhw_days = sum(mhw, na.rm = TRUE)),
      by = .(pixel_id, month)]
    n_ev_p <- sum(ev$event$date_start >= d0 & ev$event$date_start <= d1)
    ev_total <- ev_total + nrow(ev$event)
    ev_pilot <- ev_pilot + n_ev_p
    px_with_ev_pilot <- px_with_ev_pilot + (n_ev_p > 0L)
    if (j %% 50L == 0L)
      mfdc_log(sprintf("  MHW: %d/%d pixels", j, length(pixels_needed)), file = log_file)
  }
  mhw_px <- rbindlist(mhw_list)
  mfdc_log(sprintf("MHW: %d eventos 1991-2023; %d iniciados no piloto; %d/%d pixels com evento no piloto",
    ev_total, ev_pilot, px_with_ev_pilot, length(pixels_needed)), file = log_file)
  t_mhw <- Sys.time()

  ## ---- 6/6 Painel, metricas e artefatos -------------------------------
  mfdc_log("6/6 Painel celula x mes e metricas...", file = log_file)
  gfw_cells <- unique(gfw_raw[, .(lon, lat)])
  gfw_pts <- st_as_sf(gfw_cells, coords = c("lon", "lat"), crs = 4326)
  gfw_cells[, cell := h3jsr::point_to_cell(gfw_pts, res = res_h3, simple = TRUE)]
  gfw2 <- merge(gfw_raw, gfw_cells, by = c("lon", "lat"))
  eff_cm <- gfw2[, .(hours = sum(hours, na.rm = TRUE),
                     n_vessels = sum(n_vessels, na.rm = TRUE),
                     n_gfw_cells = uniqueN(paste(lon, lat))),
                 by = .(cell, month)]

  panel <- CJ(cell = cells_s$cell, month = months_pilot)
  panel <- merge(panel, cells_s[, .(cell, pixel_id, lon_c, lat_c)], by = "cell")
  panel <- merge(panel, eff_cm[, .(cell, month, hours, n_vessels)],
                 by = c("cell", "month"), all.x = TRUE)
  panel[is.na(hours), hours := 0]
  panel[is.na(n_vessels), n_vessels := 0]
  panel <- merge(panel, mhw_px, by = c("pixel_id", "month"), all.x = TRUE)
  stopifnot(nrow(panel) == nrow(cells_s) * length(months_pilot),
            !anyNA(panel$sst_mean))
  arrow::write_parquet(panel, file.path(dir_int, "panel_pilot.parquet"))
  arrow::write_parquet(cells_s, file.path(dir_int, "cells_pilot.parquet"))

  comp <- gfw_raw[, .(hours = sum(hours, na.rm = TRUE),
                      vessels = sum(n_vessels, na.rm = TRUE)),
                  by = .(flag, geartype)][order(-hours)]
  fwrite(comp, file.path(dir_diag, "gfw_composition_pilot.csv"))

  share_pos      <- panel[, mean(hours > 0)]
  cells_any_eff  <- panel[, any(hours > 0), by = cell][, mean(V1)]
  months_any_eff <- panel[, any(hours > 0), by = month][, sum(V1)]
  sd_within      <- panel[, .(s = sd(log1p(hours))), by = cell][, mean(s, na.rm = TRUE)]
  sd_between     <- panel[, .(s = sd(log1p(hours))), by = month][, mean(s, na.rm = TRUE)]
  sst_sd_within  <- panel[, .(s = sd(sst_mean)), by = cell][, mean(s, na.rm = TRUE)]
  mhw_any_share  <- panel[, mean(mhw_days > 0)]
  mhw_cm_share   <- panel[, mean(mhw_days >= cfg$mhw$min_duration_days)]
  map_gfw <- eff_cm[cell %in% cells_s$cell,
                    .(med = median(n_gfw_cells), max = max(n_gfw_cells))]
  cells_per_px <- cells_s[, .N, by = pixel_id][, .(med = median(N), max = max(N))]
  g <- gc()
  runtime_total <- mins_since(t0)
  metrics <- data.table(metric = c(
    "n_cells_bbox", "n_cells_ocean", "n_cells_sampled", "n_months",
    "gfw_rows", "gfw_hours_total", "gfw_vessel_obs_total",
    "gfw_months_with_effort", "gfw_flag_gear_pairs",
    "q4_gfw_cells_per_h3_median", "q4_gfw_cells_per_h3_max",
    "q4_h3_cells_per_sst_pixel_median", "q4_h3_cells_per_sst_pixel_max",
    "q4_dist_centroid_pixel_km_median", "q4_dist_centroid_pixel_km_max",
    "q5_share_cellmonths_effort_pos", "q5_share_cells_any_effort",
    "q5_months_with_any_effort",
    "q6_sd_within_cell_log1p_hours", "q6_sd_between_cells_log1p_hours",
    "q6_sd_within_cell_sst", "q6_mhw_events_1991_2023",
    "q6_mhw_events_pilot", "q6_share_pixels_with_mhw_pilot",
    "q6_share_cellmonths_mhw_any", "q6_share_cellmonths_mhw_5d",
    "q7_runtime_total_min", "q7_min_gfw", "q7_min_oisst_download",
    "q7_min_sst_read", "q7_min_mhw", "q7_ram_peak_mb",
    "sst_days", "sst_gaps", "oisst_years_downloaded_now"
  ), value = c(
    length(cells_all), n_univ, nrow(cells_s), length(months_pilot),
    nrow(gfw_raw), round(sum(gfw_raw$hours, na.rm = TRUE), 1),
    sum(gfw_raw$n_vessels, na.rm = TRUE),
    uniqueN(gfw_raw$month), nrow(unique(gfw_raw[, .(flag, geartype)])),
    map_gfw$med, map_gfw$max,
    cells_per_px$med, cells_per_px$max,
    round(median(cells_s$dist_km), 2), round(max(cells_s$dist_km), 2),
    round(share_pos, 4), round(cells_any_eff, 4),
    months_any_eff,
    round(sd_within, 4), round(sd_between, 4),
    round(sst_sd_within, 3), ev_total,
    ev_pilot, round(px_with_ev_pilot / length(pixels_needed), 4),
    round(mhw_any_share, 4), round(mhw_cm_share, 4),
    round(runtime_total, 1), round(mins_since(t0, t_gfw), 1),
    round(mins_since(t_gfw, t_dl), 1),
    round(mins_since(t_dl, t_read), 1), round(mins_since(t_read, t_mhw), 1),
    round(sum(g[, 6]), 0),
    length(dates), n_gaps, n_new
  ))
  fwrite(metrics, file.path(dir_diag, "feasibility_metrics.csv"))
  mfdc_log(sprintf(
    "Metricas-chave: %%cel-mes esforco>0 = %.1f%%; MHW no piloto = %d eventos (%.0f%% pixels); runtime %.1f min",
    100 * share_pos, ev_pilot, 100 * px_with_ev_pilot / length(pixels_needed),
    runtime_total), file = log_file)
  mfdc_log("== FIM piloto de viabilidade — preencher docs/feasibility_report.md ==",
           file = log_file)
})
