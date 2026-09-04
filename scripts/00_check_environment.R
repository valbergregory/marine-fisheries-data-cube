# 00_check_environment.R — auditoria do ambiente (Console ou Background Job)
# Independente do Global Environment; localiza a raiz sozinho; loga em outputs/logs.

local({
  # localizar raiz mesmo se rodado como Background Job a partir de scripts/
  find_root <- function(start) {
    p <- normalizePath(start, winslash = "/")
    while (!file.exists(file.path(p, "marine-fisheries-data-cube.Rproj"))) {
      parent <- dirname(p); if (parent == p) stop("Raiz nao encontrada."); p <- parent
    }
    p
  }
  root <- find_root(if (nzchar(Sys.getenv("R_SCRIPT_PATH"))) dirname(Sys.getenv("R_SCRIPT_PATH")) else ".")
  setwd(root)
  source(file.path(root, "R", "00_setup.R"))

  log_file <- mfdc_open_log("00_check_environment")
  mfdc_log("== INICIO auditoria de ambiente ==", file = log_file)
  on.exit(mfdc_log("== FIM ==", file = log_file), add = TRUE)

  mfdc_log("R: ", R.version.string, file = log_file)
  mfdc_log("Plataforma: ", R.version$platform, file = log_file)
  mfdc_log("Raiz do projeto: ", root, file = log_file)
  mfdc_log("renv ativo: ", !is.na(Sys.getenv("RENV_PROJECT", NA)), file = log_file)

  quarto <- tryCatch(system2("quarto", "--version", stdout = TRUE), error = function(e) "NAO ENCONTRADO no PATH")
  mfdc_log("Quarto: ", paste(quarto, collapse = " "), file = log_file)
  git <- tryCatch(system2("git", "--version", stdout = TRUE), error = function(e) "NAO ENCONTRADO")
  mfdc_log("Git: ", git, file = log_file)

  # Pacotes da fase 1
  fase1 <- c("targets", "tarchetypes", "yaml", "jsonlite", "httr2", "curl",
             "data.table", "checkmate", "testthat")
  inst <- vapply(fase1, requireNamespace, logical(1), quietly = TRUE)
  mfdc_log("Pacotes fase 1 OK: ", paste(fase1[inst], collapse = ", "), file = log_file)
  if (any(!inst)) mfdc_log("FALTANDO: ", paste(fase1[!inst], collapse = ", "),
                           " -> rode renv::restore()", file = log_file)

  # Credenciais (presenca, nunca o valor)
  mfdc_log("GFW_TOKEN definido: ", nzchar(Sys.getenv("GFW_TOKEN")), file = log_file)
  if (!nzchar(Sys.getenv("GFW_TOKEN")))
    mfdc_log("AVISO: crie o token em https://globalfishingwatch.org/our-apis/ e salve em .Renviron",
             file = log_file)

  # Espaco em disco no drive do projeto
  mfdc_log("Log salvo em: ", log_file, file = log_file)
  invisible(TRUE)
})
