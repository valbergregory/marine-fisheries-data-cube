if (file.exists("renv/activate.R")) source("renv/activate.R")

options(
  scipen = 999,
  stringsAsFactors = FALSE,
  timeout = 600,                # downloads NetCDF podem ser lentos
  renv.config.auto.snapshot = FALSE
)

# Seed global do projeto (reprodutibilidade; cada script re-declara a sua)
Sys.setenv(MFDC_SEED = "20260903")

if (interactive()) {
  message("Marine Fisheries Data Cube — projeto carregado (R ", getRversion(), ")")
  message("Comece por: scripts/00_check_environment.R")
}
