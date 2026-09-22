# Prototipo Shiny — Marine Fisheries Data Cube
# Le os agregados de R/18 (alvo `dashboard_data` do targets). Rodar da raiz:
#   shiny::runApp("app")
# Licenca dos dados exibidos: CC BY-NC 4.0 (Global Fishing Watch API) —
# atribuicao no rodape e no arquivo baixado (docs/gfw_api_terms.md).

library(shiny)
library(bslib)
library(leaflet)
library(data.table)

root <- local({
  p <- normalizePath(".", winslash = "/")
  while (!file.exists(file.path(p, "marine-fisheries-data-cube.Rproj"))) {
    parent <- dirname(p); if (parent == p) stop("Raiz nao encontrada."); p <- parent
  }
  p
})
source(file.path(root, "R", "18_dashboard_data.R"))
dd <- file.path(root, "data", "processed", "dashboard")
if (!file.exists(file.path(dd, "cells.rds")))
  stop("Rode targets::tar_make(names = 'dashboard_data') antes do app.")

cells <- readRDS(file.path(dd, "cells.rds"))
cell_year <- as.data.table(arrow::read_parquet(file.path(dd, "cell_year.parquet")))
region_month <- as.data.table(arrow::read_parquet(file.path(dd, "region_month.parquet")))
years <- range(cell_year$year)
regions <- sort(unique(cell_year$region))
vars <- c("Fishing hours (sum)" = "hours", "MHW days per month (mean)" = "mean_mhw_days",
          "SST anomaly, °C (mean)" = "mean_sst_anom")

ui <- page_sidebar(
  title = "Marine Fisheries Data Cube — Brazil",
  sidebar = sidebar(
    sliderInput("yrs", "Years", min = years[1], max = years[2], value = years,
                step = 1, sep = ""),
    checkboxGroupInput("reg", "Regions", regions, selected = regions),
    radioButtons("var", "Map variable", vars),
    downloadButton("dl", "Download cell × year CSV"),
    helpText("Prototype. Apparent fishing effort from AIS; artisanal fleet under-represented.")
  ),
  layout_columns(col_widths = c(7, 5),
    card(card_header("Map (H3 resolution 4)"), leafletOutput("map", height = 520)),
    card(card_header("Monthly series by region"), plotOutput("ts", height = 520))),
  tags$footer(style = "font-size: 0.8em; padding: 6px;",
    tags$a(href = "https://globalfishingwatch.org", target = "_blank",
           "Powered by Global Fishing Watch"), " · ", mfdc_dashboard_attribution())
)

server <- function(input, output, session) {
  sel <- reactive({
    cell_year[year >= input$yrs[1] & year <= input$yrs[2] & region %in% input$reg]
  })
  agg <- reactive({
    v <- input$var
    s <- sel()
    if (v == "hours") s[, .(value = sum(hours)), by = cell]
    else s[, .(value = mean(get(v), na.rm = TRUE)), by = cell]
  })

  output$map <- renderLeaflet({
    leaflet() |> addTiles() |>
      setView(lng = -42, lat = -14, zoom = 4)
  })
  observe({
    a <- agg(); v <- input$var
    shp <- cells
    shp$value <- a$value[match(shp$cell, a$cell)]
    shp <- shp[!is.na(shp$value), ]
    x <- if (v == "hours") log10(1 + shp$value) else shp$value
    pal <- if (v == "mean_sst_anom")
      colorNumeric("RdBu", domain = c(-1, 1) * max(abs(x), na.rm = TRUE), reverse = TRUE)
      else colorNumeric("viridis", domain = x, na.color = "transparent")
    lab <- sprintf("%s<br>%s: %s", shp$cell, names(vars)[vars == v],
                   format(round(shp$value, 2), big.mark = ","))
    leafletProxy("map", data = shp) |> clearShapes() |> clearControls() |>
      addPolygons(fillColor = pal(x), fillOpacity = 0.75, weight = 0.2,
                  color = "#555555", label = lapply(lab, HTML)) |>
      addLegend(pal = pal, values = x, position = "bottomright",
                title = if (v == "hours") "log10(1 + hours)" else names(vars)[vars == v])
  })

  output$ts <- renderPlot({
    r <- region_month[region %in% input$reg &
      as.integer(substr(month, 1, 4)) >= input$yrs[1] &
      as.integer(substr(month, 1, 4)) <= input$yrs[2]]
    r[, date := as.Date(paste0(month, "-01"))]
    long <- melt(r, id.vars = c("region", "date"),
                 measure.vars = c("hours", "mean_mhw_days"))
    long[, variable := factor(variable, c("hours", "mean_mhw_days"),
                              c("Fishing hours", "MHW days per cell-month"))]
    ggplot2::ggplot(long, ggplot2::aes(date, value, colour = region)) +
      ggplot2::geom_line(linewidth = 0.4) +
      ggplot2::facet_wrap(~variable, ncol = 1, scales = "free_y") +
      ggplot2::labs(x = NULL, y = NULL, colour = NULL) +
      ggplot2::theme_minimal(base_size = 12) +
      ggplot2::theme(legend.position = "bottom")
  })

  output$dl <- downloadHandler(
    filename = function() sprintf("mfdc_cell_year_%d_%d.csv", input$yrs[1], input$yrs[2]),
    content = function(file) {
      writeLines(paste("#", mfdc_dashboard_attribution()), file)
      fwrite(sel(), file, append = TRUE, col.names = TRUE)
    })
}

shinyApp(ui, server)
