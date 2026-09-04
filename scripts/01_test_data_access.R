# 01_test_data_access.R — testes mínimos de acesso às fontes (Background Job)
# Requisições pequenas (KB, não GB). Falha com mensagem clara em bloqueio.
# Resultados: outputs/diagnostics/data_access_report.csv + log.

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
  source(file.path(root, "R", "02_utils.R"))
  log_file <- mfdc_open_log("01_test_data_access")
  mfdc_log("== INICIO testes de acesso ==", file = log_file)

  results <- list()
  add <- function(source, status, detail) {
    results[[length(results) + 1]] <<- data.frame(
      source = source, status = status, detail = detail,
      tested_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S"), stringsAsFactors = FALSE)
    mfdc_log(source, ": ", status, " — ", detail, file = log_file)
  }

  # --- 1. OISST: HEAD de um arquivo diario (sem baixar) --------------------
  tryCatch({
    url <- mfdc_oisst_url("2024-01-15")
    resp <- httr2::req_perform(httr2::req_method(httr2::request(url), "HEAD"))
    add("oisst_ncei", "ok", paste0("HTTP ", httr2::resp_status(resp),
        ", bytes=", httr2::resp_header(resp, "content-length")))
  }, error = function(e) add("oisst_ncei", "erro", conditionMessage(e)))

  # --- 2. IBGE ---------------------------------------------------------------
  tryCatch({
    r <- httr2::req_perform(httr2::request(
      "https://servicodados.ibge.gov.br/api/v1/localidades/estados/26"))
    j <- httr2::resp_body_json(r)
    add("ibge", "ok", paste0("UF=", j$sigla))
  }, error = function(e) add("ibge", "erro", conditionMessage(e)))

  # --- 3. GFW: exige token -----------------------------------------------
  token <- Sys.getenv("GFW_TOKEN")
  if (!nzchar(token)) {
    add("gfw", "bloqueado",
        "GFW_TOKEN ausente no .Renviron. Criar em https://globalfishingwatch.org/our-apis/")
  } else {
    tryCatch({
      # consulta minima: busca de datasets (payload pequeno) na API v3
      r <- httr2::req_perform(
        httr2::req_auth_bearer_token(
          httr2::request("https://gateway.api.globalfishingwatch.org/v3/datasets?limit=1"),
          token))
      add("gfw", "ok", paste0("HTTP ", httr2::resp_status(r), " autenticado"))
    }, error = function(e) add("gfw", "erro",
        paste0("Token presente mas requisicao falhou: ", conditionMessage(e))))
  }

  out <- do.call(rbind, results)
  dir.create("outputs/diagnostics", showWarnings = FALSE, recursive = TRUE)
  utils::write.csv(out, "outputs/diagnostics/data_access_report.csv", row.names = FALSE)
  mfdc_log("Relatorio: outputs/diagnostics/data_access_report.csv == FIM ==", file = log_file)
  print(out)
})
