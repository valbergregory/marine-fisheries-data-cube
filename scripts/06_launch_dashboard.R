# 06_launch_dashboard.R — inicia o prototipo Shiny (apos fase 4)
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
  log_file <- mfdc_open_log("06_launch_dashboard")
  mfdc_log("== INICIO 06_launch_dashboard.R ==", file = log_file)
  # Comando principal (descomentar quando a fase correspondente for liberada):
  # shiny::runApp("app")
  stop("Etapa ainda nao liberada — ver docs/next_steps.md.")
})
