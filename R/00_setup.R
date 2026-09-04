# 00_setup.R — utilidades de infraestrutura (logging, paths, credenciais)
# Carregado por todos os scripts e pelo _targets.R. Sem efeitos colaterais.

mfdc_root <- function() {
  # localiza a raiz do projeto sem depender do working directory
  p <- normalizePath(".", winslash = "/")
  while (!file.exists(file.path(p, "marine-fisheries-data-cube.Rproj"))) {
    parent <- dirname(p)
    if (parent == p) stop("Raiz do projeto nao encontrada (procure o .Rproj).")
    p <- parent
  }
  p
}

mfdc_log <- function(..., file = NULL) {
  msg <- sprintf("[%s] %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), paste0(...))
  message(msg)
  if (!is.null(file)) cat(msg, "\n", file = file, append = TRUE)
}

mfdc_open_log <- function(script_name) {
  dir_logs <- file.path(mfdc_root(), "outputs", "logs")
  dir.create(dir_logs, showWarnings = FALSE, recursive = TRUE)
  file.path(dir_logs, sprintf("%s_%s.log", script_name, format(Sys.time(), "%Y%m%d_%H%M%S")))
}

mfdc_require_env <- function(var, hint) {
  val <- Sys.getenv(var, unset = "")
  if (!nzchar(val)) {
    stop(sprintf(
      "Variavel de ambiente '%s' ausente. %s\nDefina-a em .Renviron na raiz do projeto e reinicie o R.",
      var, hint
    ), call. = FALSE)
  }
  invisible(val)  # nunca imprimir o valor
}

mfdc_sha256 <- function(path) {
  # checksum de arquivo bruto para data/metadata/checksums.csv
  as.character(tools::md5sum(path)) # placeholder ate 'digest'/'openssl' entrar nas deps
}

mfdc_register_download <- function(file, url, source_id) {
  meta_dir <- file.path(mfdc_root(), "data", "metadata")
  dir.create(meta_dir, showWarnings = FALSE, recursive = TRUE)
  row <- data.frame(
    source_id = source_id, file = basename(file), url = url,
    bytes = file.size(file), checksum = mfdc_sha256(file),
    downloaded_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
    stringsAsFactors = FALSE
  )
  csv <- file.path(meta_dir, "checksums.csv")
  utils::write.table(row, csv, sep = ",", row.names = FALSE,
                     col.names = !file.exists(csv), append = file.exists(csv))
  invisible(row)
}
