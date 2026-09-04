# Valida a configuração central e o inventário de fontes
root <- {
  p <- normalizePath(".", winslash = "/")
  while (!file.exists(file.path(p, "marine-fisheries-data-cube.Rproj"))) {
    parent <- dirname(p); if (parent == p) stop("Raiz nao encontrada."); p <- parent
  }
  p
}
source(file.path(root, "R", "00_setup.R"))
source(file.path(root, "R", "01_config.R"))

test_that("config.yml e valido e coerente", {
  cfg <- mfdc_config()
  expect_equal(cfg$mhw$method, "hobday2016")
  expect_gte(cfg$mhw$min_duration_days, 5)
  expect_true(cfg$feasibility$bbox$xmin < cfg$feasibility$bbox$xmax)
  d0 <- as.Date(cfg$feasibility$period$start)
  d1 <- as.Date(cfg$feasibility$period$end)
  expect_lte(as.numeric(d1 - d0), 731)  # piloto: no maximo 2 anos
})

test_that("data_sources.yml tem os campos minimos e statuses validos", {
  src <- mfdc_sources()
  expect_gte(length(src), 5)
  valid <- c("ok", "ok_requer_token", "pendente", "bloqueado", "descartado")
  for (nm in names(src)) {
    s <- src[[nm]]
    expect_true(!is.null(s$instituicao), info = nm)
    if (!is.null(s$status_teste)) expect_true(s$status_teste %in% valid, info = nm)
  }
})
