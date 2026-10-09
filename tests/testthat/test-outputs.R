# Integridade dos produtos do pipeline (pula se ainda nao foram gerados)
root <- {
  p <- normalizePath(".", winslash = "/")
  while (!file.exists(file.path(p, "marine-fisheries-data-cube.Rproj"))) {
    parent <- dirname(p); if (parent == p) stop("Raiz nao encontrada."); p <- parent
  }
  p
}

test_that("painel res4: chave unica, faixas validas e 144 meses (D16/D17)", {
  f <- file.path(root, "data", "processed", "panel_cell_month_res4.parquet")
  skip_if_not(file.exists(f), "painel ainda nao gerado")
  p <- data.table::as.data.table(arrow::read_parquet(f))
  expect_equal(anyDuplicated(p[, .(cell, month)]), 0L)
  expect_equal(data.table::uniqueN(p$month), 144L)
  expect_equal(range(p$month), c("2013-01", "2024-12"))
  expect_true(all(p$grid_res == 4L))
  expect_true(all(p$hours >= 0))
  expect_true(all(p$mhw_days >= 0 & p$mhw_days <= 31, na.rm = TRUE))
  expect_true(all(p$mhw_max_int[p$mhw_days == 0] == 0, na.rm = TRUE))
  expect_equal(p$effort_present, as.integer(p$hours > 0))
  expect_true(all(p$region %in% c("Norte", "Nordeste", "Sudeste", "Sul")))
  # painel balanceado: toda celula tem os 144 meses
  expect_true(all(p[, .N, by = cell]$N == 144L))
  # universo = fishing footprint (celula com esforco em ao menos um mes)
  expect_true(all(p[, any(hours > 0), by = cell]$V1))
})

test_that("numbers.tex: sem valores faltantes e cobre toda macro usada no main.tex", {
  nf <- file.path(root, "outputs", "overleaf", "numbers.tex")
  mf <- file.path(root, "article", "main.tex")
  skip_if_not(file.exists(nf) && file.exists(mf), "numbers.tex/main.tex ausentes")
  nums <- readLines(nf, encoding = "UTF-8")
  defs <- regmatches(nums, regexpr("(?<=newcommand\\{\\\\)[A-Za-z]+", nums, perl = TRUE))
  vals <- sub("^.*\\}\\{(.*)\\}$", "\\1", grep("newcommand", nums, value = TRUE))
  expect_gt(length(defs), 100)
  expect_equal(anyDuplicated(defs), 0L)
  expect_false(any(grepl("missing|^NA$|^NaN$|^$", vals)), info = paste(defs[grepl("missing|^NA$|^NaN$|^$", vals)], collapse = ", "))
  tex <- paste(readLines(mf, encoding = "UTF-8"), collapse = "\n")
  used <- unique(regmatches(tex, gregexpr("(?<=\\\\)[A-Za-z]+(?=\\{\\})", tex, perl = TRUE))[[1]])
  # Comandos do LaTeX/elsarticle que tambem aparecem como \nome{}: nao sao
  # macros de numero. "author" entra em 2026-10-09 porque o ramo anonimo do
  # manuscrito (revisao duplo-cega do Marine Policy, D26) usa \author{} vazio.
  latex_builtin <- c("today", "maketitle", "tableofcontents", "centering", "par",
                     "newpage", "clearpage", "appendix", "noindent", "LaTeX", "TeX",
                     "author")
  undefined <- setdiff(used, c(defs, latex_builtin))
  expect_equal(undefined, character(0))
})
