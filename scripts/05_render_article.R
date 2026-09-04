# 05_render_article.R — renderiza o manuscrito Quarto (Background Job ou Terminal: quarto render article/manuscript.qmd)
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
  log_file <- mfdc_open_log("05_render_article")
  mfdc_log("== INICIO 05_render_article.R ==", file = log_file)
  # Comando principal (descomentar quando a fase correspondente for liberada):
  # quarto::quarto_render("article/manuscript.qmd")
  stop("Etapa ainda nao liberada — ver docs/next_steps.md.")
})
