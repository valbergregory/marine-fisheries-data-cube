# 95_measure_cost.R -------------------------------------------------------
# Mede o CUSTO COMPUTACIONAL do pipeline para sustentar a afirmacao de custo
# do artigo e da versao de SI com numeros medidos, nao estimados.
#
# Uso (sempre pelo wrapper de PowerShell, que le o pico de memoria do SO):
#   Rscript scripts/95_measure_cost.R ingest
#   Rscript scripts/95_measure_cost.R analysis
#   Rscript scripts/95_measure_cost.R netio
#
# O que cada etapa mede
#   ingest   : montagem do cubo, recorte de UM ano (arquivo global local) e
#              deteccao de MHW de UM bloco de 250 pixels; extrapola para o
#              total pelo numero de anos e de blocos (extrapolacao declarada).
#   analysis : invalida e recomputa a cadeia de estimacao -> tabelas -> export
#              e le o tempo por alvo do proprio metadado do targets.
#   netio    : vazao de download medida com UMA requisicao de intervalo
#              (64 MB) ao servidor da PSL; o tempo total de download e
#              extrapolado do volume em disco (extrapolacao declarada).
#
# Saida: outputs/logs/cost_<etapa>_<timestamp>.json e linhas no stdout.
# Nao escreve em data/raw/ e nao altera nenhum alvo fora da cadeia analitica.

stage <- commandArgs(trailingOnly = TRUE)[1]
if (is.na(stage) || !stage %in% c("ingest", "analysis", "netio")) {
  stop("uso: Rscript scripts/95_measure_cost.R [ingest|analysis|netio]")
}

suppressMessages({
  library(targets)
  library(data.table)
})
invisible(lapply(list.files("R", pattern = "[.]R$", full.names = TRUE), source))

out <- list(stage = stage,
            started_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
            r_version = R.version.string,
            machine = list(os = Sys.info()[["sysname"]],
                           release = Sys.info()[["release"]],
                           cores = parallel::detectCores()))

timeit <- function(label, expr) {
  gc(reset = TRUE, full = TRUE)
  t0 <- proc.time()
  val <- force(expr)
  el <- proc.time() - t0
  # gc() devolve, por tipo de celula, "max used" em CELULAS e a coluna 6 ja em
  # Mb; usar a coluna 6 (converter cellulas a mao erra o fator por tipo).
  mx <- sum(gc()[, 6])                                # pico do heap do R, MB
  cat(sprintf("[%s] %.1f s (elapsed) | %.1f s (user) | R max used ~%.0f MB\n",
              label, el[["elapsed"]], el[["user.self"]], mx))
  list(value = val,
       seconds = as.numeric(el[["elapsed"]]),
       user_seconds = as.numeric(el[["user.self"]]),
       r_max_used_mb = as.numeric(mx))
}

# ---- ingest --------------------------------------------------------------
if (stage == "ingest") {
  cfg <- tar_read(cfg)
  crop_files <- tar_read(oisst_crop_files)
  pixels_needed <- tar_read(pixels_needed)

  cat(sprintf("pixels no universo: %d | anos de recorte: %d\n",
              length(pixels_needed), length(crop_files)))

  # 1. montagem do cubo (le todos os recortes anuais e empilha)
  a <- timeit("cubo", mfdc_oisst_cube(crop_files, pixels_needed, NULL))
  cube <- a$value
  out$cube <- a[c("seconds", "user_seconds", "r_max_used_mb")]
  out$cube$n_pixels <- length(pixels_needed)
  out$cube$n_days <- length(cube$dates)
  out$cube$object_mb <- as.numeric(object.size(cube)) / 1024^2

  # 2. recorte de um ano, a partir do arquivo global JA EM DISCO
  #    (destino temporario para forcar o caminho sem cache)
  tmp_crop <- file.path(tempdir(), "cost_crop")
  dir.create(tmp_crop, showWarnings = FALSE, recursive = TRUE)
  y_test <- cfg$full_study$sst_years$end
  b <- timeit(sprintf("recorte %d", y_test),
              mfdc_oisst_crop_year(y_test, cfg$full_study$bbox,
                                   cfg$full_study$paths$oisst_global,
                                   tmp_crop, NULL))
  out$crop_one_year <- b[c("seconds", "user_seconds", "r_max_used_mb")]
  out$crop_one_year$year <- y_test
  out$crop_one_year$global_file_mb <-
    file.size(file.path(cfg$full_study$paths$oisst_global,
                        sprintf("sst.day.mean.%d.nc", y_test))) / 1024^2
  out$crop_one_year$n_years_total <- length(crop_files)
  out$crop_one_year$implied_total_seconds <-
    b$seconds * length(crop_files)
  unlink(tmp_crop, recursive = TRUE)

  # 3. deteccao de MHW de um bloco de 250 pixels (sem cache_dir)
  chunk <- 250L
  idx <- seq_len(min(chunk, length(pixels_needed)))
  d <- timeit(sprintf("MHW %d pixels", length(idx)),
              mfdc_mhw_monthly(
                list(dates = cube$dates, m = cube$m[idx, , drop = FALSE]),
                pixels_needed[idx], cfg,
                cfg$full_study$period$start, cfg$full_study$period$end,
                log_file = NULL))
  n_blocks <- ceiling(length(pixels_needed) / chunk)
  out$mhw_one_block <- d[c("seconds", "user_seconds", "r_max_used_mb")]
  out$mhw_one_block$pixels_per_block <- length(idx)
  out$mhw_one_block$n_blocks_total <- n_blocks
  out$mhw_one_block$implied_total_seconds <- d$seconds * n_blocks
  out$mhw_one_block$note <-
    "4 definicoes de MHW sao estimadas (principal + 3 robustez)"
  out$mhw_all_definitions_implied_seconds <- d$seconds * n_blocks * 4
}

# ---- analysis ------------------------------------------------------------
if (stage == "analysis") {
  chain <- c("models_r4", "dyn_r4", "het_r4", "spill_r4", "nonlin_r4",
             "thresholds", "celltrend", "placebos", "placebo_lead12",
             "rob_main", "rob_altdef", "moran", "relocation", "cum_effect",
             "descriptives", "quality", "tex_tables", "extra_tables",
             "overleaf")
  cat("invalidando:", paste(chain, collapse = ", "), "\n")
  for (nm in chain) try(tar_invalidate(all_of(nm)), silent = TRUE)

  t0 <- proc.time()
  tar_make(reporter = "summary")
  el <- as.numeric((proc.time() - t0)[["elapsed"]])
  cat(sprintf("[cadeia analitica] %.1f s = %.1f min\n", el, el / 60))

  m <- as.data.table(tar_meta(fields = c("seconds", "bytes", "time")))
  m <- m[name %in% chain & !is.na(seconds)][order(-seconds)]
  print(m[, .(name, seconds, mb = round(bytes / 1024^2, 1))])

  out$analysis <- list(
    wall_seconds = el,
    targets_sum_seconds = sum(m$seconds, na.rm = TRUE),
    per_target = lapply(seq_len(nrow(m)), function(i)
      list(name = m$name[i], seconds = m$seconds[i],
           mb = round(m$bytes[i] / 1024^2, 1))))
}

# ---- netio ---------------------------------------------------------------
if (stage == "netio") {
  cfg <- tar_read(cfg)
  y <- cfg$full_study$sst_years$end
  url <- mfdc_oisst_global_url(y)
  n_bytes <- 64 * 1024^2
  tmpf <- tempfile(fileext = ".bin")
  h <- curl::new_handle()
  curl::handle_setheaders(h, Range = sprintf("bytes=0-%d", n_bytes - 1L))
  t0 <- proc.time()
  ok <- tryCatch({ curl::curl_download(url, tmpf, handle = h, quiet = TRUE)
                   TRUE }, error = function(e) { message(conditionMessage(e))
                   FALSE })
  el <- as.numeric((proc.time() - t0)[["elapsed"]])
  got <- if (file.exists(tmpf)) file.size(tmpf) else 0
  unlink(tmpf)
  mbps <- (got / 1024^2) / el
  disk_gb <- sum(file.size(list.files(cfg$full_study$paths$oisst_global,
                                      full.names = TRUE))) / 1024^3
  cat(sprintf("[download] %.0f MB em %.1f s = %.2f MB/s | volume total %.1f GB\n",
              got / 1024^2, el, mbps, disk_gb))
  out$netio <- list(ok = ok, measured_mb = got / 1024^2, seconds = el,
                    mb_per_s = mbps, total_gb_on_disk = disk_gb,
                    implied_download_seconds = (disk_gb * 1024) / mbps,
                    note = "vazao medida em uma requisicao de intervalo; total extrapolado")
}

out$finished_at <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
dir.create("outputs/logs", recursive = TRUE, showWarnings = FALSE)
f <- file.path("outputs/logs",
               sprintf("cost_%s_%s.json", stage, format(Sys.time(), "%Y%m%d_%H%M%S")))
writeLines(jsonlite::toJSON(out, auto_unbox = TRUE, pretty = TRUE, digits = 4), f)
cat("gravado:", f, "\n")
