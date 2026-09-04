# 04_run_models.R — executa somente os targets de modelos (Background Job)
# STATUS: bloqueado ate aprovacao da viabilidade (docs/feasibility_report.md).
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
  log_file <- mfdc_open_log("04_run_models")
  mfdc_log("== INICIO 04_run_models.R ==", file = log_file)
  # Comando principal (descomentar quando a fase correspondente for liberada):
  # targets::tar_make(names = tidyselect::starts_with("model_"))
  stop("Etapa ainda nao liberada — ver docs/next_steps.md.")
})
