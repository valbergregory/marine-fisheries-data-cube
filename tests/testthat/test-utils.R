root <- {
  p <- normalizePath(".", winslash = "/")
  while (!file.exists(file.path(p, "marine-fisheries-data-cube.Rproj"))) {
    parent <- dirname(p); if (parent == p) stop("Raiz nao encontrada."); p <- parent
  }
  p
}
source(file.path(root, "R", "02_utils.R"))

test_that("mfdc_month_seq gera meses corretos", {
  m <- mfdc_month_seq("2022-01-01", "2022-03-31")
  expect_equal(m, c("2022-01", "2022-02", "2022-03"))
})

test_that("mfdc_oisst_url monta a URL canonica do NCEI", {
  u <- mfdc_oisst_url("2024-01-15")
  expect_match(u, "avhrr/202401/oisst-avhrr-v02r01\\.20240115\\.nc$")
})

test_that("mfdc_assert_bbox rejeita bbox invalido", {
  expect_error(mfdc_assert_bbox(list(xmin = -30, xmax = -38, ymin = -10, ymax = -4)))
  expect_silent(mfdc_assert_bbox(list(xmin = -38, xmax = -32, ymin = -10.5, ymax = -4.5)))
})
