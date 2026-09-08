# 16_figures.R — figuras do artigo (ggplot2), geradas pelo pipeline.

mfdc_fig_event_study <- function(dyn, out_png) {
  es <- data.table::copy(dyn$event_study)
  data.table::setnames(es, c("Estimate", "Std. Error"), c("b", "se"),
                       skip_absent = TRUE)
  g <- ggplot2::ggplot(es, ggplot2::aes(x = horizon, y = b)) +
    ggplot2::geom_hline(yintercept = 0, linetype = 2, colour = "grey50") +
    ggplot2::geom_vline(xintercept = -0.5, linetype = 3, colour = "grey70") +
    ggplot2::geom_pointrange(ggplot2::aes(ymin = b - 1.96 * se,
                                          ymax = b + 1.96 * se)) +
    ggplot2::scale_x_continuous(breaks = seq(-3, 6)) +
    ggplot2::labs(
      x = "Months relative to MHW exposure (leads < 0 = placebo)",
      y = "PPML coefficient on MHW days (95% CI, Conley SE)",
      title = "Fishing hours and marine heatwave exposure: dynamics") +
    ggplot2::theme_minimal(base_size = 11)
  ggplot2::ggsave(out_png, g, width = 7.5, height = 4.5, dpi = 300)
  out_png
}

mfdc_fig_maps <- function(panel, out_png) {
  cellavg <- panel[, .(hours = mean(hours), mhw = mean(mhw_days),
                       lon = lon_c[1], lat = lat_c[1]), by = cell]
  base <- tryCatch(sf::st_geometry(sf::st_transform(
    geobr::read_state(year = 2020, showProgress = FALSE), 4326)),
    error = function(e) NULL)
  mk <- function(fill_var, lab, trans) {
    g <- ggplot2::ggplot()
    if (!is.null(base)) g <- g + ggplot2::geom_sf(data = base, fill = "grey92",
                                                  colour = "grey70", linewidth = .2)
    g + ggplot2::geom_point(data = cellavg,
          ggplot2::aes(lon, lat, colour = .data[[fill_var]]), size = .8) +
      ggplot2::scale_colour_viridis_c(trans = trans, name = lab) +
      ggplot2::coord_sf(xlim = c(-54, -25), ylim = c(-35, 6)) +
      ggplot2::theme_minimal(base_size = 10) +
      ggplot2::labs(x = NULL, y = NULL)
  }
  g <- patchwork::wrap_plots(
    mk("hours", "Mean monthly\nfishing hours", "log1p") +
      ggplot2::ggtitle("Apparent fishing effort (2013-2024)"),
    mk("mhw", "Mean MHW\ndays/month", "identity") +
      ggplot2::ggtitle("Marine heatwave exposure"),
    ncol = 2)
  ggplot2::ggsave(out_png, g, width = 11, height = 6, dpi = 300)
  out_png
}

mfdc_fig_timeseries <- function(panel, out_png) {
  ts <- panel[, .(hours = sum(hours), mhw_share = mean(mhw_days > 0)),
              by = month][order(month)]
  ts[, date := as.Date(paste0(month, "-01"))]
  sc <- max(ts$hours) # eixo secundario
  g <- ggplot2::ggplot(ts, ggplot2::aes(date)) +
    ggplot2::geom_col(ggplot2::aes(y = hours), fill = "steelblue", alpha = .7) +
    ggplot2::geom_line(ggplot2::aes(y = mhw_share * sc), colour = "firebrick") +
    ggplot2::scale_y_continuous(
      name = "Total apparent fishing hours",
      sec.axis = ggplot2::sec_axis(~ . / sc,
        name = "Share of cells under MHW (red)")) +
    ggplot2::labs(x = NULL,
      title = "Fishing effort and MHW incidence, Brazilian coast") +
    ggplot2::theme_minimal(base_size = 11)
  ggplot2::ggsave(out_png, g, width = 9, height = 4.5, dpi = 300)
  out_png
}
