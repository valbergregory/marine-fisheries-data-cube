# 03_run_pipeline.R — executa o pipeline targets (Background Job)
# Fase 2 liberada em 2026-09-07 (decisao D14: RESTRINGIR/continuar com ajustes).
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
  log_file <- mfdc_open_log("03_run_pipeline")
  mfdc_log("== INICIO tar_make ==", file = log_file)
  on.exit(mfdc_log("== FIM tar_make ==", file = log_file), add = TRUE)
  targets::tar_make(reporter = "timestamp")
  print(targets::tar_progress_summary())
})
