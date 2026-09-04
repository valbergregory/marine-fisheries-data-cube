# 01_config.R — leitura e validação da configuração central

mfdc_config <- function(profile = "default") {
  cfg_path <- file.path(mfdc_root(), "config", "config.yml")
  stopifnot(file.exists(cfg_path))
  cfg <- yaml::read_yaml(cfg_path)[[profile]]

  checkmate::assert_list(cfg)
  checkmate::assert_number(cfg$seed)
  checkmate::assert_string(cfg$crs_analysis)
  fb <- cfg$feasibility$bbox
  checkmate::assert_true(fb$xmin < fb$xmax && fb$ymin < fb$ymax)
  checkmate::assert_true(as.Date(cfg$feasibility$period$start) <
                         as.Date(cfg$feasibility$period$end))
  checkmate::assert_choice(cfg$mhw$method, "hobday2016")
  checkmate::assert_number(cfg$mhw$percentile, lower = 80, upper = 99)
  checkmate::assert_number(cfg$mhw$min_duration_days, lower = 3)
  cfg
}

mfdc_sources <- function() {
  yaml::read_yaml(file.path(mfdc_root(), "config", "data_sources.yml"))
}
