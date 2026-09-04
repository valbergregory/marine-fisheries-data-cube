# 02_utils.R — utilidades analíticas puras (testáveis)

#' Sequência de meses AAAA-MM entre duas datas
mfdc_month_seq <- function(start, end) {
  format(seq(as.Date(start), as.Date(end), by = "month"), "%Y-%m")
}

#' URL de um arquivo diário OISST v2.1 no NCEI
mfdc_oisst_url <- function(date) {
  d <- as.Date(date)
  sprintf(
    "https://www.ncei.noaa.gov/data/sea-surface-temperature-optimum-interpolation/v2.1/access/avhrr/%s/oisst-avhrr-v02r01.%s.nc",
    format(d, "%Y%m"), format(d, "%Y%m%d")
  )
}

#' Valida um bbox lon/lat
mfdc_assert_bbox <- function(b) {
  checkmate::assert_numeric(unlist(b), len = 4, any.missing = FALSE)
  stopifnot(b$xmin >= -180, b$xmax <= 180, b$ymin >= -90, b$ymax <= 90,
            b$xmin < b$xmax, b$ymin < b$ymax)
  invisible(b)
}
