# 02_run_feasibility.R — piloto de viabilidade (Background Job)
# Pré-requisitos: token GFW no .Renviron + scripts/00b_install_dependencies.R OK.
# Escopo: NE (bbox em config), 2022-2023, mensal, <=400 células.
# Produz: data/interim/pilot/*.parquet + numeros para docs/feasibility_report.md.

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
  source(file.path(root, "R", "01_config.R"))
  source(file.path(root, "R", "02_utils.R"))
  log_file <- mfdc_open_log("02_run_feasibility")
  mfdc_log("== INICIO piloto de viabilidade ==", file = log_file)

  cfg <- mfdc_config()
  fz <- cfg$feasibility
  mfdc_assert_bbox(fz$bbox)
  mfdc_require_env("GFW_TOKEN",
    "Token da Global Fishing Watch (https://globalfishingwatch.org/our-apis/).")

  for (p in c("gfwr", "terra", "sf", "heatwaveR", "arrow"))
    if (!requireNamespace(p, quietly = TRUE))
      stop("Pacote '", p, "' ausente. Rode scripts/00b_install_dependencies.R primeiro.")

  t0 <- Sys.time()
  # ------------------------------------------------------------------
  # TODO(fase 1, proximo passo apos token):
  #  1. gfwr::get_raster(): esforco mensal 0.1 grau no bbox, 2022-2023;
  #  2. OISST: baixar recorte via OPeNDAP/PSL (terra) para o mesmo bbox
  #     + climatologia minima p/ MHW piloto (ou usar 'anom' do proprio OISST
  #     no piloto, marcando que a climatologia completa vem na fase 2);
  #  3. agregar ambos na grade do piloto (H3 res 5 e alternativa 0.25);
  #  4. calcular metricas das 10 perguntas (zeros, variancia, tempo, RAM);
  #  5. salvar data/interim/pilot/panel_pilot.parquet + resumo em
  #     outputs/diagnostics/feasibility_metrics.csv.
  # Este script FALHA aqui de proposito enquanto o TODO nao for implementado:
  stop("Piloto ainda nao implementado — implementar apos GFW_TOKEN disponivel. ",
       "Ver docs/next_steps.md, Fase 1.")
  # ------------------------------------------------------------------
})
