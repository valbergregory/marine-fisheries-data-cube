#!/usr/bin/env Rscript
# 90_export_overleaf.R — gera outputs/overleaf/ (tabelas booktabs, figuras,
# numbers.tex e o esqueleto main.tex) a partir do pipeline. Nunca escreve prosa.
# Uso: Rscript scripts/90_export_overleaf.R  (ou Background Job no RStudio)
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
  log_file <- mfdc_open_log("90_export_overleaf")
  mfdc_log("== INICIO export Overleaf ==", file = log_file)
  on.exit(mfdc_log("== FIM ==", file = log_file), add = TRUE)
  targets::tar_make(names = c("results_digest", "overleaf"), reporter = "timestamp")
  zipf <- file.path("outputs", sprintf("overleaf_%s.zip", format(Sys.Date(), "%Y%m%d")))
  old <- setwd("outputs/overleaf")
  utils::zip(file.path("..", "..", zipf), list.files(".", recursive = TRUE))
  setwd(old)
  mfdc_log("Pacote para upload no Overleaf: ", zipf, file = log_file)
  message("Pronto: ", zipf)
})
