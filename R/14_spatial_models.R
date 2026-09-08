# 14_spatial_models.R — deslocamento espacial: exposicao MHW da vizinhanca
# (celulas com centroide a ate dist_km; h3jsr nao expoe API de anel testada,
# entao a vizinhanca e definida por distancia de centroides — res 4 tem
# aresta ~22 km, logo 60 km captura o anel k=1).

mfdc_neighbor_exposure <- function(panel, dist_km = 60) {
  cs <- unique(panel[, .(cell, lon_c, lat_c)])
  sfp <- sf::st_as_sf(cs, coords = c("lon_c", "lat_c"), crs = 4326)
  nb <- sf::st_is_within_distance(sfp, dist = dist_km * 1000)
  edges <- data.table::data.table(
    from = rep(seq_len(nrow(cs)), lengths(nb)), to = unlist(nb))[from != to]
  edges[, `:=`(cell = cs$cell[from], nb_cell = cs$cell[to])]
  mh <- panel[, .(cell, month, mhw_days)]
  e2 <- merge(edges[, .(cell, nb_cell)], mh,
              by.x = "nb_cell", by.y = "cell", allow.cartesian = TRUE)
  e2[, .(mhw_days_nb = mean(mhw_days, na.rm = TRUE),
         n_nb = data.table::uniqueN(nb_cell)), by = .(cell, month)]
}

mfdc_spatial_models <- function(panel, dist_km = 60, conley_cutoff_km = 200,
                                log_file = NULL) {
  ring <- mfdc_neighbor_exposure(panel, dist_km)
  p <- mfdc_prep_panel(panel)
  p <- merge(p, ring, by = c("cell", "month"), all.x = TRUE)
  mfdc_log(sprintf("Spillover res %d: %d/%d linhas com vizinhanca (mediana %s vizinhos)",
    p$grid_res[1], sum(!is.na(p$mhw_days_nb)), nrow(p),
    stats::median(p$n_nb, na.rm = TRUE)), file = log_file)
  p <- p[!is.na(mhw_days_nb)]
  fe <- "cell + month + region^month_of_year"

  models <- list(
    # se vizinhos sao atingidos e o esforco migra p/ ca: coef positivo
    ppml_spill = fixest::fepois(stats::as.formula(paste(
      "hours ~ mhw_days + mhw_days_nb + sst_anom |", fe)), data = p),
    ext_spill  = fixest::feols(stats::as.formula(paste(
      "effort_present ~ mhw_days + mhw_days_nb + sst_anom |", fe)), data = p)
  )
  sums <- lapply(models, mfdc_vcov_summary, cutoff_km = conley_cutoff_km,
                 log_file = log_file)
  coefs <- data.table::rbindlist(lapply(names(sums), function(nm) {
    ct <- as.data.frame(sums[[nm]]$sum$coeftable)
    data.table::data.table(model = nm, term = rownames(ct), ct,
                           vcov = sums[[nm]]$vcov)
  }), fill = TRUE)
  list(grid_res = p$grid_res[1], dist_km = dist_km,
       summaries = lapply(sums, `[[`, "sum"), coefs = coefs)
}

mfdc_save_spatial <- function(sp, dir_models, dir_tables) {
  tag <- sprintf("res%d", sp$grid_res)
  f1 <- file.path(dir_models, sprintf("spatial_%s.rds", tag))
  saveRDS(sp, f1)
  f2 <- file.path(dir_tables, sprintf("spatial_etable_%s.txt", tag))
  writeLines(capture.output(fixest::etable(sp$summaries)), f2)
  c(f1, f2)
}
