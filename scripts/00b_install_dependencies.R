# 00b_install_dependencies.R — instala dependências da FASE 2 (Background Job)
# Rodar SOMENTE quando for iniciar o piloto (após criar o token GFW).
# Instala via renv (biblioteca isolada do projeto; nada global).

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
  log_file <- mfdc_open_log("00b_install_dependencies")
  mfdc_log("== INICIO instalacao fase 2 ==", file = log_file)

  pkgs_cran <- c("sf", "terra", "exactextractr", "heatwaveR", "rerddap",
                 "geobr", "arrow", "duckdb", "DBI", "fixest",
                 "marginaleffects", "modelsummary", "ggplot2", "patchwork",
                 "scales", "validate", "h3jsr")
  for (p in pkgs_cran) {
    ok <- tryCatch({ renv::install(p, prompt = FALSE); TRUE },
                   error = function(e) { mfdc_log("FALHA ", p, ": ", conditionMessage(e), file = log_file); FALSE })
    mfdc_log(p, if (ok) " OK" else " FALHOU (ver acima)", file = log_file)
  }

  # gfwr nao esta no CRAN (verificado 2026-09-03) — instalar do GitHub, pinado.
  # Atualize o ref para a tag estavel mais recente antes de rodar.
  ok_gfwr <- tryCatch({ renv::install("GlobalFishingWatch/gfwr", prompt = FALSE); TRUE },
                      error = function(e) { mfdc_log("FALHA gfwr: ", conditionMessage(e), file = log_file); FALSE })
  mfdc_log("gfwr (GitHub) ", if (ok_gfwr) "OK" else "FALHOU", file = log_file)

  renv::snapshot(prompt = FALSE)
  mfdc_log("renv.lock atualizado. == FIM ==", file = log_file)
})
