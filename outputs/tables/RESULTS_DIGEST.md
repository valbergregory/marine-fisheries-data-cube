# Results digest (machine-generated; prose is written by the author)
Generated: 2026-09-11 15:08

## Panel
- Grid: H3 res 4; obs = 686,160; cells = 4,765

## Main (PPML, Conley 200 km)
- MHW days (no controls): -0.0041 (SE 0.0034, p=0.223)
- MHW days | SST anomaly: -0.0113 (SE 0.0035, p=0.00107)
- SST anomaly: 0.1308 (SE 0.0398, p=0.00101)
- Extensive margin: -0.0006 (SE 0.0004, p=0.144)

## Dynamics (leads = placebo)
- h=-3: -0.0013 (SE 0.0023, p=0.591)
- h=-2: -0.0014 (SE 0.0026, p=0.596)
- h=-1: 0.0000 (SE 0.0021, p=0.998)
- h=0: -0.0066 (SE 0.0023, p=0.00372)
- h=1: -0.0021 (SE 0.0025, p=0.419)
- h=2: -0.0065 (SE 0.0018, p=0.000349)
- h=3: 0.0018 (SE 0.0025, p=0.466)
- h=4: -0.0061 (SE 0.0024, p=0.0116)
- h=5: -0.0035 (SE 0.0020, p=0.0725)
- h=6: -0.0019 (SE 0.0018, p=0.306)

## Spillovers by ring
- own: -0.0026 (SE 0.0031, p=0.413)
- 0-60 km: -0.0148 (SE 0.0096, p=0.126)
- 60-150 km: 0.0147 (SE 0.0075, p=0.0508)
- 150-300 km: -0.0122 (SE 0.0098, p=0.213)

## Heterogeneity (full coefficients in heterogeneity_coefs.csv)
- by_region | region::Nordeste:mhw_days: -0.0120 (SE 0.0056, p=0.0308)
- by_region | region::Norte:mhw_days: -0.0409 (SE 0.0054, p=3.71e-14)
- by_region | region::Sudeste:mhw_days: -0.0108 (SE 0.0038, p=0.00469)
- by_region | region::Sul:mhw_days: 0.0041 (SE 0.0047, p=0.377)
- by_gear | gear::drifting_longlines:mhw_days: -0.0126 (SE 0.0037, p=0.000676)
- by_gear | gear::fishing:mhw_days: -0.0114 (SE 0.0042, p=0.00634)
- by_gear | gear::other:mhw_days: -0.0107 (SE 0.0042, p=0.0102)
- by_gear | gear::set_longlines:mhw_days: -0.0072 (SE 0.0076, p=0.343)
- by_gear | gear::trawlers:mhw_days: -0.0102 (SE 0.0105, p=0.333)
- by_distance | far_coast::nearshore:mhw_days: -0.0074 (SE 0.0047, p=0.114)
- by_distance | far_coast::offshore:mhw_days: -0.0239 (SE 0.0042, p=1.65e-08)

## Robustness
- res5_main: -0.0107 (SE 0.0036, p=0.00276)
- trend_regyr: -0.0066 (SE 0.0024, p=0.00681)
- stable_cells: -0.0120 (SE 0.0036, p=0.000973)
- conley100: -0.0113 (SE 0.0030, p=0.000144)
- conley400: -0.0113 (SE 0.0036, p=0.00142)
- mhw_p95: -0.0165 (SE 0.0042, p=9.5e-05)
- mhw_dur10: -0.0123 (SE 0.0033, p=0.000173)
- mhw_clim1982_2011: -0.0102 (SE 0.0029, p=0.000373)

## Cube quality
-    grid_res n_cells n_months  n_rows key_unique sst_na_rows share_effort_pos
-       <int>   <int>    <int>   <int>     <lgcl>       <int>            <num>
- 1:        4    4765      144  686160       TRUE           0           0.1635
- 2:        5   31481      144 4533264       TRUE           0           0.0895
-    share_mhw_any mean_mhw_days total_hours sd_within_log1p p50_hours_pos
-            <num>         <num>       <num>           <num>         <num>
- 1:        0.3369          4.84     8154935          0.9049          13.1
- 2:        0.3353          4.82     8365472          0.4553           4.3

## Cumulative effect (lags 0-6, Conley SE)
- sum of 7 lags: -0.0222 (SE 0.0067, p=0.000967; 95% CI -0.0354 to -0.0090)

## Non-linear bins
- anom_bin::lt_m1: -0.1641 (SE 0.1528, p=0.283)
- anom_bin::m1_m05: 0.0257 (SE 0.1002, p=0.798)
- anom_bin::0_05: 0.0525 (SE 0.0525, p=0.317)
- anom_bin::05_1: 0.1356 (SE 0.0999, p=0.175)
- anom_bin::1_15: 0.0695 (SE 0.0953, p=0.466)
- anom_bin::gt_15: -0.0336 (SE 0.1455, p=0.817)
- mhw_bin::d1_4: -0.0011 (SE 0.0713, p=0.988)
- mhw_bin::d5_9: -0.0131 (SE 0.0286, p=0.646)
- mhw_bin::d10_19: -0.0594 (SE 0.0455, p=0.192)
- mhw_bin::d20p: -0.3281 (SE 0.0911, p=0.000317)

## Placebos
- 12-month lead UNCONDITIONAL (proxies persistent MHW regimes; not a valid test): -0.0102 (SE 0.0036, p=0.00466)
- 12-month lead CONDITIONAL on lags 0-6 (valid placebo): -0.0099 (SE 0.0032, p=0.00196)
- spatial permutation: observed -0.0113 vs perm mean -0.0031 (sd 0.0014), p_rand=0.020, 95% perm range [-0.0061, -0.0009]

## Cell-specific linear trends (D19) — placebo-consistent specification
- main effect with cell trends: -0.0046 (SE 0.0022, p=0.0366)
- 12-month lead with cell trends: -0.0020 (SE 0.0018, p=0.267)
- cumulative lags 0-6 with cell trends: -0.0057 (SE 0.0057, p=0.312; 95% CI -0.0168 to 0.0054)

## Sample exclusions
- excl_coastal: -0.0115 (SE 0.0035, p=0.00109)
- excl_low_cov: -0.0115 (SE 0.0035, p=0.00106)

## Reallocation (region-month; only 4 regions, read with caution)
- dist_coast: 0.4428 (SE 2.4997, p=0.859)
- concentration: -0.0012 (SE 0.0008, p=0.126)
- active_cells: 0.0192 (SE 0.0045, p=2.4e-05)

## Residual spatial dependence
- Moran's I = 0.0239 (permutation p = 0.015, 4765 cells, 60 km)
