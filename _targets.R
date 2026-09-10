# _targets.R — pipeline do Marine Fisheries Data Cube (fase 2)
#
# Portao de viabilidade LIBERADO em 2026-09-07: decisao do pesquisador =
# "RESTRINGIR (continuar com ajustes)" sobre docs/feasibility_report.md v1.0
# (registrada em docs/decisions_log.md, D14). Ajustes: costa inteira,
# universo fishing footprint, PPML como especificacao principal, H3 res 4
# vs 5, exposicao continua (dias-MHW).
#
# Executar via scripts/03_run_pipeline.R (Background Job). Nenhum resultado
# cientifico fora do pipeline.

library(targets)
library(tarchetypes)

for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) source(f)

tar_option_set(
  packages = c("data.table", "yaml", "checkmate", "arrow", "sf", "h3jsr",
               "ncdf4", "heatwaveR", "curl", "Matrix", "fixest", "ggplot2",
               "patchwork"),
  format = "rds",
  seed = 20260903
)

LOGF <- {
  dir.create("outputs/logs", showWarnings = FALSE, recursive = TRUE)
  file.path("outputs", "logs",
            sprintf("pipeline_%s.log", format(Sys.time(), "%Y%m%d_%H%M%S")))
}

list(
  # ---- 1. Configuracao ---------------------------------------------------
  tar_target(config_file, "config/config.yml", format = "file"),
  tar_target(cfg, { config_file; mfdc_config() }),
  tar_target(feasibility_approved, TRUE),   # D14, 2026-09-07

  # ---- 2. Downloads (cache interno por ano; format=file p/ rastreio) -----
  tar_target(years_effort, {
    p <- cfg$full_study$period
    as.integer(format(as.Date(p$start), "%Y")):as.integer(format(as.Date(p$end), "%Y"))
  }),
  tar_target(years_sst,
    cfg$full_study$sst_years$start:cfg$full_study$sst_years$end),
  tar_target(gfw_files, {
    stopifnot(feasibility_approved)
    mfdc_require_env("GFW_TOKEN", "Token da Global Fishing Watch.")
    mfdc_download_gfw(years_effort, cfg$full_study$bbox,
                      cfg$full_study$paths$gfw, LOGF)
  }, format = "file"),
  tar_target(oisst_crop_files, {
    stopifnot(feasibility_approved)
    mfdc_download_oisst(years_sst, cfg$full_study$bbox,
                        cfg$full_study$paths$oisst_global,
                        cfg$full_study$paths$oisst_crop, LOGF)
  }, format = "file"),

  # ---- 3. Grades e esforco -----------------------------------------------
  tar_target(gfw, mfdc_read_gfw(gfw_files)),
  tar_target(pix, mfdc_oisst_grid(oisst_crop_files)),
  tar_target(cells_r4, mfdc_assign_region(
    mfdc_dist_coast(mfdc_grid_cells(cfg$full_study$bbox, 4L, pix, LOGF), pix), LOGF)),
  tar_target(cells_r5, mfdc_assign_region(
    mfdc_dist_coast(mfdc_grid_cells(cfg$full_study$bbox, 5L, pix, LOGF), pix), LOGF)),
  tar_target(eff_r4, mfdc_effort_by_cell(gfw, 4L)),
  tar_target(eff_r5, mfdc_effort_by_cell(gfw, 5L)),

  # ---- 4. MHW apenas nos pixels do footprint (economia) ------------------
  tar_target(pixels_needed, sort(unique(c(
    cells_r4[cell %in% unique(eff_r4$cell), pixel_id],
    cells_r5[cell %in% unique(eff_r5$cell), pixel_id])))),
  tar_target(mhw_px, {
    cube <- mfdc_oisst_cube(oisst_crop_files, pixels_needed, LOGF)
    mfdc_mhw_monthly(cube, pixels_needed, cfg,
                     cfg$full_study$period$start, cfg$full_study$period$end,
                     LOGF, cache_dir = "data/interim/mhw_chunks")
  }),

  # ---- 5. Paineis (footprint) e artefatos Parquet ------------------------
  tar_target(months_all, mfdc_month_seq(cfg$full_study$period$start,
                                        cfg$full_study$period$end)),
  tar_target(panel_r4, mfdc_build_panel(eff_r4, cells_r4, mhw_px, 4L, months_all, LOGF)),
  tar_target(panel_r5, mfdc_build_panel(eff_r5, cells_r5, mhw_px, 5L, months_all, LOGF)),
  tar_target(parquet_r4, {
    dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)
    f <- "data/processed/panel_cell_month_res4.parquet"
    arrow::write_parquet(panel_r4, f); f
  }, format = "file"),
  tar_target(parquet_r5, {
    f <- "data/processed/panel_cell_month_res5.parquet"
    arrow::write_parquet(panel_r5, f); f
  }, format = "file"),
  tar_target(parquet_cells, {
    f <- "data/processed/cells_res4_res5.parquet"
    arrow::write_parquet(data.table::rbindlist(list(cells_r4, cells_r5)), f); f
  }, format = "file"),

  # ---- 6. Auditoria ------------------------------------------------------
  tar_target(quality, mfdc_quality_report(
    list(panel_r4, panel_r5), "outputs/diagnostics/cube_quality.csv", LOGF)),

  # ---- 7. Modelos principais (fase 3; grade principal = res 4, D17) ------
  tar_target(models_r4, mfdc_main_models(panel_r4, conley_cutoff_km = 200, LOGF)),
  tar_target(models_r4_files, mfdc_save_models(models_r4,
    "outputs/models", "outputs/tables"), format = "file"),

  # ---- 8. Dinamica (leads = placebo) e spillover -------------------------
  tar_target(dyn_r4, mfdc_dynamic_models(panel_r4, 200, LOGF)),
  tar_target(dyn_r4_files, mfdc_save_dynamic(dyn_r4,
    "outputs/models", "outputs/tables"), format = "file"),
  tar_target(spill_r4, mfdc_spatial_models(panel_r4,
    conley_cutoff_km = 200, log_file = LOGF)),
  tar_target(spill_r4_files, mfdc_save_spatial(spill_r4,
    "outputs/models", "outputs/tables"), format = "file"),

  # ---- 9. Robustez (res5, cutoffs, tendencias, amostra estavel, p95) -----
  tar_target(mhw_px_p95, {
    cfg95 <- cfg; cfg95$mhw$percentile <- 95
    cube <- mfdc_oisst_cube(oisst_crop_files, pixels_needed, LOGF)
    mfdc_mhw_monthly(cube, pixels_needed, cfg95,
                     cfg$full_study$period$start, cfg$full_study$period$end,
                     LOGF, cache_dir = "data/interim/mhw_chunks_p95")
  }),
  tar_target(panel_r4_p95, mfdc_build_panel(eff_r4, cells_r4, mhw_px_p95,
    4L, months_all, LOGF)),
  tar_target(rob_altdef, mfdc_altdef_model(panel_r4_p95, "mhw_p95", LOGF)),
  tar_target(rob_main, mfdc_robustness_models(panel_r4, panel_r5, LOGF)),
  tar_target(rob_files, mfdc_save_robustness(rob_main, list(rob_altdef),
    "outputs/models", "outputs/tables"), format = "file"),

  # ---- 10. Figuras -------------------------------------------------------
  tar_target(fig_event, mfdc_fig_event_study(dyn_r4,
    "outputs/figures/fig_event_study_res4.png"), format = "file"),
  tar_target(fig_maps, mfdc_fig_maps(panel_r4,
    "outputs/figures/fig_maps_effort_mhw.png"), format = "file"),
  tar_target(fig_ts, mfdc_fig_timeseries(panel_r4,
    "outputs/figures/fig_timeseries.png"), format = "file"),

  # ---- 11. Heterogeneidade (regiao, arte de pesca, distancia) ------------
  tar_target(gear_classes, mfdc_gear_classes(gfw)),
  tar_target(eff_gear_r4, mfdc_effort_by_cell_gear(gfw, 4L,
    gear_classes$keep, LOGF)),
  tar_target(panel_gear_r4, mfdc_build_panel_gear(eff_gear_r4, cells_r4,
    mhw_px, months_all, LOGF)),
  tar_target(het_r4, mfdc_heterogeneity_models(panel_r4, panel_gear_r4,
    200, LOGF)),
  tar_target(het_files, mfdc_save_heterogeneity(het_r4,
    "outputs/models", "outputs/tables"), format = "file"),

  # ---- 12. Descritivas, tabelas LaTeX e digest de resultados -------------
  tar_target(descriptives, mfdc_descriptives(panel_r4, gear_classes$table,
    "outputs/tables/descriptives_by_region.csv", LOGF)),
  tar_target(tex_tables, mfdc_build_tables(models_r4, dyn_r4, spill_r4,
    rob_main, list(rob_altdef), het_r4, descriptives, "outputs/tables"),
    format = "file"),
  tar_target(results_digest, mfdc_results_digest(models_r4, dyn_r4, spill_r4,
    rob_main, list(rob_altdef), het_r4, quality,
    "outputs/tables/RESULTS_DIGEST.md"), format = "file"),

  # ---- 13. Pacote Overleaf (tabelas + figuras + numbers.tex) -------------
  tar_target(overleaf, mfdc_export_overleaf(models_r4, dyn_r4, spill_r4,
    rob_main, list(rob_altdef), het_r4, quality, descriptives, cfg,
    tex_tables, c(fig_event, fig_maps, fig_ts),
    out_dir = "outputs/overleaf", log_file = LOGF), format = "file")

  # TODO(fase 5): dashboard (R/18); prosa do artigo escrita pelo autor em
  # Overleaf (politica em docs/AI_POLICY_AND_REPRODUCIBILITY.md).
)
