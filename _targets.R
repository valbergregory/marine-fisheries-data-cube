# _targets.R — esqueleto do pipeline (Marine Fisheries Data Cube)
#
# ESTADO: esqueleto da fase 1. Os targets de download/painel/modelos estão
# declarados mas protegidos por `feasibility_approved` — o pipeline PARA
# de forma explícita enquanto docs/feasibility_report.md não for aprovado
# (flag em config: full_study habilitado).
#
# Executar SEMPRE via scripts/03_run_pipeline.R (Background Job), nunca
# resultados manuais fora do pipeline.

library(targets)
library(tarchetypes)

# Funções do projeto
for (f in list.files("R", pattern = "^0[0-2].*\\.R$", full.names = TRUE)) source(f)

tar_option_set(
  packages = c("yaml", "jsonlite", "data.table", "checkmate"),
  format = "rds",          # objetos grandes migrarão para format = "file" (Parquet/NetCDF em disco)
  seed = 20260903
)

list(
  # ---- 1. Configuração e inventário -------------------------------------
  tar_target(config_file, "config/config.yml", format = "file"),
  tar_target(sources_file, "config/data_sources.yml", format = "file"),
  tar_target(cfg, { config_file; mfdc_config() }),
  tar_target(sources, { sources_file; mfdc_sources() }),

  # ---- 2. Portão de viabilidade ------------------------------------------
  tar_target(feasibility_approved, {
    # Aprovação é uma decisão humana registrada em decisions_log.md e
    # materializada aqui: mude para TRUE somente com autorização do pesquisador.
    FALSE
  }),

  # ---- 3. Fases seguintes (declaradas, bloqueadas) -----------------------
  tar_target(gate_msg, {
    if (!feasibility_approved) {
      message("Pipeline parado no portao de viabilidade. ",
              "Rode scripts/02_run_feasibility.R e obtenha aprovacao ",
              "(docs/feasibility_report.md) antes de habilitar downloads completos.")
    }
    feasibility_approved
  })

  # TODO(fase 2, apos aprovacao): downloads com checksums (R/03-05),
  # limpeza (R/06-07), grade (R/08), painel Parquet/DuckDB (R/09),
  # auditoria (R/10), descritivas (R/11), modelos (R/12-15),
  # figuras/tabelas (R/16-17), dashboard (R/18),
  # tar_quarto(article, "article/manuscript.qmd").
)
