# Results digest (machine-generated; prose is written by the author)
Generated: 2026-09-10 02:10

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

## Cube quality
-    grid_res n_cells n_months  n_rows key_unique sst_na_rows share_effort_pos
-       <int>   <int>    <int>   <int>     <lgcl>       <int>            <num>
- 1:        4    4765      144  686160       TRUE           0           0.1635
- 2:        5   31481      144 4533264       TRUE           0           0.0895
-    share_mhw_any mean_mhw_days total_hours sd_within_log1p p50_hours_pos
-            <num>         <num>       <num>           <num>         <num>
- 1:        0.3369          4.84     8154935          0.9049          13.1
- 2:        0.3353          4.82     8365472          0.4553           4.3
