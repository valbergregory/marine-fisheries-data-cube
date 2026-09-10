# 16_figures.R — figuras do artigo (ggplot2), geradas pelo pipeline.

mfdc_fig_event_study <- function(dyn, out_png) {
  es <- data.table::copy(dyn$event_study)   # colunas ja padronizadas: b/se/p
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

#' Curva de resposta: coeficientes por faixa de anomalia de SST e de dias MHW.
mfdc_fig_dose_response <- function(nonlin, out_png) {
  lab <- c(lt_m1 = "< -1", m1_m05 = "-1..-0.5", m05_0 = "-0.5..0 (ref)",
           `0_05` = "0..0.5", `05_1` = "0.5..1", `1_15` = "1..1.5",
           gt_15 = "> 1.5", d0 = "0 (ref)", d1_4 = "1-4", d5_9 = "5-9",
           d10_19 = "10-19", d20p = "20+")
  d <- data.table::copy(nonlin$coefs)[grepl("_bin::", term)]
  d[, key := sub(".*_bin::", "", term)]
  d[, panel := data.table::fifelse(grepl("^anom", term),
      "SST anomaly bin (degC)", "MHW days in month")]
  d[, key := factor(lab[key], levels = unname(lab))]
  ref <- data.table::data.table(
    key = factor(c("-0.5..0 (ref)", "0 (ref)"), levels = unname(lab)),
    b = 0, se = 0, panel = c("SST anomaly bin (degC)", "MHW days in month"))
  d <- rbind(d[, .(key, b, se, panel)], ref)
  g <- ggplot2::ggplot(d, ggplot2::aes(key, b)) +
    ggplot2::geom_hline(yintercept = 0, linetype = 2, colour = "grey50") +
    ggplot2::geom_pointrange(ggplot2::aes(ymin = b - 1.96 * se,
                                          ymax = b + 1.96 * se)) +
    ggplot2::facet_wrap(~panel, scales = "free_x") +
    ggplot2::labs(x = NULL, y = "PPML coefficient (95% CI, Conley SE)",
      title = "Non-linear response of fishing effort") +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 30, hjust = 1))
  ggplot2::ggsave(out_png, g, width = 9, height = 4.5, dpi = 300)
  out_png
}

#' Placebo espacial: distribuicao das permutacoes vs. coeficiente observado.
mfdc_fig_permutation <- function(placebos, out_png) {
  d <- data.table::data.table(b = placebos$perm_draws)
  obs <- placebos$permutation$b_obs
  g <- ggplot2::ggplot(d, ggplot2::aes(b)) +
    ggplot2::geom_histogram(bins = 20, fill = "grey75", colour = "white") +
    ggplot2::geom_vline(xintercept = obs, colour = "firebrick", linewidth = 1) +
    ggplot2::annotate("text", x = obs, y = Inf, label = " observed",
      colour = "firebrick", hjust = 0, vjust = 1.5, size = 3.5) +
    ggplot2::labs(x = "PPML coefficient under permuted MHW series",
      y = "Permutations", title = sprintf(
        "Spatial placebo: %d within-region permutations (p = %.3f)",
        placebos$permutation$n_perm, placebos$permutation$p_rand)) +
    ggplot2::theme_minimal(base_size = 11)
  ggplot2::ggsave(out_png, g, width = 7.5, height = 4.2, dpi = 300)
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
