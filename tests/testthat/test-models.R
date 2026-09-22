# Helpers econometricos com dados simulados (nao dependem do cubo real)
root <- {
  p <- normalizePath(".", winslash = "/")
  while (!file.exists(file.path(p, "marine-fisheries-data-cube.Rproj"))) {
    parent <- dirname(p); if (parent == p) stop("Raiz nao encontrada."); p <- parent
  }
  p
}
source(file.path(root, "R", "00_setup.R"))
source(file.path(root, "R", "12_main_models.R"))
source(file.path(root, "R", "15_robustness.R"))
source(file.path(root, "R", "19_export_overleaf.R"))

# painel sintetico celula x mes com efeito conhecido de mhw_days
sim_panel <- function(n_cells = 60L, n_months = 48L, beta = -0.02, seed = 1L) {
  set.seed(seed)
  months <- format(seq(as.Date("2013-01-01"), by = "month", length.out = n_months), "%Y-%m")
  cells <- data.table::data.table(cell = sprintf("c%03d", seq_len(n_cells)),
    lon_c = stats::runif(n_cells, -48, -34), lat_c = stats::runif(n_cells, -30, -2),
    alpha = stats::rnorm(n_cells, 3, 0.5),
    region = sample(c("Norte", "Nordeste", "Sudeste", "Sul"), n_cells, TRUE))
  p <- data.table::CJ(cell = cells$cell, month = months)
  p <- merge(p, cells, by = "cell")
  p[, mhw_days := as.integer(pmin(31, stats::rpois(.N, 4)))]
  p[, sst_anom := stats::rnorm(.N, 0.3, 0.6)]
  p[, hours := stats::rpois(.N, exp(alpha + beta * mhw_days + 0.1 * sst_anom))]
  p[, grid_res := 4L]
  p[]
}

test_that("mfdc_prep_panel cria time_id, month_of_year, lat/lon e fallback de regiao", {
  p <- sim_panel(n_cells = 5L, n_months = 14L)
  q <- mfdc_prep_panel(p)
  expect_equal(max(q$time_id), 14L)
  expect_setequal(unique(q$month_of_year), sprintf("%02d", 1:12))
  expect_equal(q$lat, q$lat_c)
  p[, region := NA_character_]
  expect_true(all(mfdc_prep_panel(p)$region == "BR"))
  expect_false("time_id" %in% names(p))   # nao altera o original (copy)
})

test_that("PPML recupera o coeficiente simulado e coef_table padroniza colunas", {
  p <- mfdc_prep_panel(sim_panel(beta = -0.02))
  m <- fixest::fepois(hours ~ mhw_days + sst_anom | cell + month, data = p)
  ct <- mfdc_coef_table(list(m1 = list(sum = summary(m, cluster = "cell"),
                                       vcov = "cluster_cell")))
  expect_true(all(c("model", "term", "b", "se", "stat", "p", "vcov") %in% names(ct)))
  expect_equal(ct[term == "mhw_days", b], -0.02, tolerance = 0.005)
})

test_that("mfdc_cumulative_effect soma coeficientes e usa a covariancia", {
  p <- mfdc_prep_panel(sim_panel())
  data.table::setkey(p, cell, time_id)
  m <- fixest::fepois(hours ~ l(mhw_days, 0:2) | cell + month,
                      data = p, panel.id = c("cell", "time_id"))
  s <- summary(m, cluster = "cell")
  cum <- mfdc_cumulative_effect(s, "mhw_days")
  b <- stats::coef(s); V <- stats::vcov(s)
  expect_equal(cum$k, 3L)
  expect_equal(cum$b, sum(b))
  expect_equal(cum$se, sqrt(sum(V)))
  expect_equal(cum$lo, cum$b - 1.96 * cum$se)
})

test_that("mfdc_threshold_models estima limiares e bins nas duas especificacoes", {
  p <- sim_panel(n_cells = 40L, n_months = 36L)
  p[sample(.N, 200), mhw_days := sample(20:31, 200, TRUE)]   # garante massa em 20+/30+
  # painel pequeno: VCOV Conley pode sair nao positivo-definido (aviso esperado)
  res <- suppressWarnings(mfdc_threshold_models(p, thresholds = c(10L, 20L, 30L),
                                                conley_cutoff_km = 500))
  expect_setequal(unique(res$coefs$model),
    c(sprintf("ge%d_base", c(10, 20, 30)), "bins_base",
      sprintf("ge%d_celltrend", c(10, 20, 30)), "bins_celltrend"))
  expect_equal(res$counts$n_cell_months[res$counts$threshold == 30],
               sum(p$mhw_days >= 30))
  expect_true(all(is.finite(res$coefs[grepl("^mhw_ge", term), b])))
})

test_that("mfdc_tex_escape escapa os caracteres especiais do LaTeX", {
  expect_equal(mfdc_tex_escape("a_b 5% R&D #1"), "a\\_b 5\\% R\\&D \\#1")
})
