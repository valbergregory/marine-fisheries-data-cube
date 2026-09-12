# DRAFT — initial text for the author to rewrite (EN)

> **Status and disclosure.** This file is an AI-assisted first draft produced
> with Claude Code at the author's explicit request (2026-09-11). It exists so
> the author has a scaffold to rewrite, correct and expand; it is **not** the
> article. Two consequences follow from the project's AI policy
> (`docs/AI_POLICY_AND_REPRODUCIBILITY.md`) and from Portaria CNPq 2.664/2026:
> (1) whatever survives into `main.tex` must be substantially rewritten in the
> author's own words, and (2) the sentence "No generative AI tool was used to
> write, draft or paraphrase the text of this article" in
> `article/ai_disclosure.tex` must be replaced by a truthful statement that an
> AI tool assisted in drafting early versions of some sections, which the
> author rewrote and takes full responsibility for.
>
> **Numbers.** Every figure below is written as `\macro{}` (current value in
> brackets) so it can be pasted into LaTeX without ever typing a value. All
> values come from `outputs/tables/RESULTS_DIGEST.md` (pipeline run of
> 2026-09-11). Language is associational throughout (decision D6).

---

## Abstract (draft, ~230 words)

Marine heatwaves (MHWs) are becoming longer and more frequent, yet evidence
on how fishing fleets respond to them at high spatial and temporal
resolution remains scarce, especially for tropical and subtropical
fisheries. We assemble a reproducible geospatial data cube that links
satellite-based apparent fishing effort (Global Fishing Watch) to daily
sea-surface temperature (NOAA OISST) for the entire Brazilian coast and
exclusive economic zone, at the level of `\panelCells{}` [4,765] hexagonal
cells (H3 resolution 4) observed monthly from `\panelStart{}` [2013] to
`\panelEnd{}` [2024] (`\panelObs{}` [686,160] cell-months). MHWs follow the
Hobday et al. (2016) definition. Poisson pseudo-maximum-likelihood models
with cell, month and region-by-season fixed effects and Conley standard
errors indicate that each additional MHW day in a month is associated with
`\bMhwMain{}` [−0.0113] log points of fishing hours (about −1.1%),
conditional on the sea-surface temperature anomaly; the response is on the
intensive margin, concentrated in months with 20 or more MHW days, absent
before exposure (leads), and robust to grid resolution, alternative MHW
definitions and Conley cut-offs. A specification with cell-specific linear
trends, which also neutralises a 12-month-lead placebo, yields a more
conservative `\bMhwCellTrend{}` [−0.0046]. We find no short-distance
displacement, but a positive association with neighbours' exposure at
60–150 km, and the largest responses for drifting longliners, offshore
cells and the North region. The data cube is released as an
information-systems artefact for climate-resilient fisheries monitoring.

## 1. Introduction (draft)

Paragraph 1 — the shock. Marine heatwaves, discrete periods of anomalously
warm sea-surface temperature lasting at least five days
(Hobday et al., 2016), have increased in frequency and duration over the
past century (Oliver et al., 2018) and now threaten biodiversity and the
provision of ecosystem services on which fisheries depend
(Smale et al., 2019). Historical warming has already reduced the
productivity of many exploited stocks (Free et al., 2019), and single
extreme events can reorganise fishing seasons and markets, as the 2012
Northwest Atlantic heatwave showed (Mills et al., 2013). Projections indicate
that heatwaves compound the effects of gradual warming on fisheries
(Cheung and Frölicher, 2020).

Paragraph 2 — the gap. Most evidence concerns temperate stocks and relies on
landings or stock assessments at annual or seasonal resolution. Much less is
known about how fleets themselves react — where and how much they fish —
while a heatwave unfolds, and almost nothing for tropical and subtropical
fisheries of the South Atlantic. Brazil is a demanding case: it has no
continuous national fisheries statistics since the discontinuation of the
official series in the 2010s, so behavioural responses cannot be studied
from landings at all. [AUTHOR: one or two sentences on the Brazilian
institutional context you know best.]

Paragraph 3 — what we do. Satellite tracking of vessels (AIS) now makes it
possible to observe fishing activity at fine spatial and temporal scales
(Kroodsma et al., 2018). We combine twelve years of Global Fishing Watch
apparent fishing effort with daily NOAA OISST temperatures for the whole
Brazilian coast in a cell-by-month panel and ask how MHW exposure is
associated with the intensity and the spatial distribution of effort. Our
empirical strategy exploits within-cell variation in exposure, net of
calendar-month shocks and regional seasonality, with PPML estimation
(Santos Silva and Tenreyro, 2006; Correia et al., 2020) and spatially
robust inference (Conley, 1999).

Paragraph 4 — findings (three sentences, associational). [Use the abstract
numbers; add the threshold result: months with 20+ MHW days,
`\bMhwBinTwentyPlus{}` if you add the macro — currently −0.328 in
`tab07_nonlinear`.]

Paragraph 5 — contributions. (i) First coast-wide, high-frequency evidence
on fleet responses to MHWs for Brazil; (ii) a transparent treatment of the
identification threats (anticipation, differential trends, spatial
dependence) with placebos that the reader can inspect; (iii) the Marine
Fisheries Data Cube, a reproducible pipeline and storage design that
integrates effort, temperature, heatwave events and territorial layers, as
an information-systems contribution for monitoring and adaptation.

## 2. Data (draft)

**Fishing effort.** Global Fishing Watch's 4Wings API provides "apparent
fishing hours" — hours in which a neural-network classifier infers fishing
behaviour from AIS tracks (Kroodsma et al., 2018) — aggregated monthly on a
0.1° grid, by flag and gear type. We query the box −54°E to −25°E, −35°N to
6°N for `\panelStart{}`–`\panelEnd{}` and map each 0.1° centre to an H3
cell. AIS coverage is skewed toward larger vessels; the artisanal fleet is
essentially absent. All inferences therefore concern the AIS-tracked fleet,
which in Brazil is dominated by drifting longliners (Table 1, gear
composition). [AUTHOR: state clearly in one sentence that this is a
population statement, not a sampling caveat.]

**Sea-surface temperature and marine heatwaves.** NOAA OISST v2.1 gives
daily SST on a 0.25° grid from 1981. For each ocean pixel we compute a
1991–2020 daily climatology and the seasonally varying 90th-percentile
threshold (31-day window), and detect MHWs as runs of at least five days
above the threshold, merging gaps of at most two days (Hobday et al., 2016;
implementation: heatwaveR, Schlegel and Smit, 2018). The monthly exposure
variables are the number of MHW days (`mhw_days`), the maximum intensity
above threshold, the mean SST and the mean anomaly relative to the seasonal
climatology (`sst_anom`). The anomaly is kept separate because a warm
anomaly is not a heatwave; the two enter jointly in all models.

**Grid and panel.** Cells are H3 hexagons of resolution 4 (~1,770 km²),
chosen after comparing resolutions 4 and 5 on zeros and within-cell variance
(resolution 5 is used as robustness). The analysis universe is the fishing
footprint: cells with positive effort in at least one month, giving
`\panelCells{}` cells × 144 months = `\panelObs{}` cell-months, of which
`\shareEffortPos{}`% [16.4] have positive hours and `\shareMhwAny{}`% [33.7]
have at least one MHW day. Each cell carries its distance to the coast and
the nearest coastal region (North, Northeast, Southeast, South).
Descriptive statistics by region are in Table 1; Figure 2 maps mean effort
and mean MHW exposure; Figure 3 shows the national time series.

## 3. Empirical strategy — the econometric model (draft)

**Outcome and estimator.** Let $y_{it}$ be apparent fishing hours in cell
$i$ and month $t$. Because `\shareEffortPos{}`% of cell-months are positive
and the rest are exact zeros, a log-linear model is unsuitable: $\log(1+y)$
is scale-dependent and inconsistent under heteroskedasticity (Santos Silva
and Tenreyro, 2006). We therefore estimate the conditional mean by Poisson
pseudo-maximum likelihood,

$$
E[y_{it} \mid X_{it}] = \exp\!\big(\beta\,\mathrm{MHW}_{it} + \gamma\,\mathrm{ANOM}_{it} + \alpha_i + \delta_t + \theta_{r(i),m(t)}\big),
$$

where $\mathrm{MHW}_{it}$ is the number of MHW days, $\mathrm{ANOM}_{it}$ the
mean SST anomaly, $\alpha_i$ a cell fixed effect, $\delta_t$ a calendar-month
fixed effect (144 levels) and $\theta_{r(i),m(t)}$ a region × month-of-year
effect. PPML is consistent whenever the conditional mean is correctly
specified, regardless of the distribution of $y$, and $100\beta$ is read as
the percentage change in expected hours per additional MHW day. Estimation
uses the iteratively reweighted algorithm with high-dimensional fixed
effects (Correia et al., 2020; R package fixest).

**What the fixed effects absorb.** $\alpha_i$ removes every time-invariant
determinant of effort in a cell — depth, distance to ports, average
productivity, permanent closures; $\delta_t$ removes national shocks common
to all cells in a month — fuel prices, demand, the average state of ENSO,
changes in AIS coverage; $\theta$ removes region-specific seasonality such
as annual closed seasons. Identification of $\beta$ therefore rests on
within-cell deviations of MHW exposure from the cell's mean, net of the
month's national shock and the region's seasonal norm.

**Inference.** Neighbouring cells share the same SST pixel and the same
vessels, and months are serially dependent. We use Conley (1999) standard
errors with a 200 km spatial cut-off (100 and 400 km as robustness), which
also accommodate serial correlation within cell; a two-way cluster by cell
and month is the fallback. Moran's I of cell-mean residuals
(`\moranI{}` [0.024], permutation p = `\pMoran{}` [0.015]) confirms small
but non-zero residual spatial dependence, justifying this choice.

**Margins.** The extensive margin uses $\mathbf{1}[y_{it}>0]$ as outcome in
a linear probability model with the same fixed effects. Dynamics use
distributed leads and lags,
$\sum_{k=-3}^{-1}\phi_k\,\mathrm{MHW}_{i,t-k} + \sum_{k=0}^{6}\beta_k\,\mathrm{MHW}_{i,t-k}$;
under no anticipation the lead coefficients $\phi_k$ should be zero, and the
cumulative effect $\sum_k\beta_k$ is reported with its Conley variance.
Non-linearity replaces the linear index by indicators for bins of MHW days
(0 ref., 1–4, 5–9, 10–19, 20+) and of the anomaly.

**Spatial displacement.** For each cell we compute the mean MHW exposure of
its neighbours in three concentric rings by centroid distance — 0–60 km
(the first hexagonal ring), 60–150 km and 150–300 km — using a row-normalised
sparse contiguity matrix, and add them to the baseline model. A positive
ring coefficient, conditional on own exposure, indicates that effort moves
into the cell when its surroundings are under a heatwave. At the region ×
month level we also examine the effort-weighted mean distance to coast, a
Herfindahl index of the spatial concentration of hours, and the number of
active cells, using historically fixed cell weights for the exposure
measure.

**Heterogeneity.** Interactions of MHW days with region, with distance to
coast (above/below the median) and, in a cell × month × gear panel with
cell × gear fixed effects, with gear type.

**Threats and placebos.** (i) Anticipation: leads at 1–3 months. (ii)
Differential trends: MHW exposure rises steeply over the period (from 0.9 to
13.3 days per cell-month between 2013 and 2024), so cells with growing
exposure may also have declining effort for unrelated reasons; we add region
× year effects and, more demandingly, cell-specific linear trends
(`cell[time]`), and we use a 12-month lead conditional on lags 0–6 as the
diagnostic. (iii) Spatial confounding: we permute the MHW series across cells
within region 50 times and compare the observed coefficient with the
permutation distribution. (iv) Measurement of MHWs: 95th percentile, 10-day
minimum duration and a 1982–2011 climatology. (v) Sample: resolution-5 grid,
cells active in ≥12 months, exclusion of cells within 25 km of the coast
(port proxy) and of low-coverage cells.

## 4. Results (draft description of tables and figures)

**Table 1 (descriptives).** [Describe: cells and hours by region; the
Southeast/South concentrate hours; share of positive cell-months; mean MHW
days; median distance to coast. Gear composition from
`descriptives_by_region_gear.csv`: drifting longlines dominate.]

**Table 2 (main).** Without the anomaly control, the MHW coefficient is
small and imprecise (`ppml_mhw`: −0.0041, p = 0.22). Conditioning on the
anomaly separates two opposite associations: a warm-but-not-extreme month
attracts effort (`\bSstAnom{}` [+0.131] per °C), while each MHW day is
associated with `\bMhwMain{}` [−0.0113] (SE `\seMhwMain{}` [0.0035],
p = `\pMhwMain{}`). The extensive margin does not respond
(`\bExtensive{}` [−0.0006], p = `\pExtensive{}` [0.14]): vessels do not
abandon cells, they fish fewer hours in them. The log(1+y) specification
gives the same sign with smaller magnitude; the maximum-intensity term is
positive and marginal once days are controlled.

**Table 3 and Figure 1 (dynamics).** Leads at −3, −2 and −1 months are all
close to zero and insignificant (largest |t| = `\maxAbsTLead{}` [0.6]); the
contemporaneous coefficient is −0.0066 (p = 0.004), the second lag −0.0065
(p < 0.001), the fourth −0.0061 (p = 0.01); the response dissipates by the
sixth month. The cumulative 0–6 month effect is `\bCumSixIC{}` [−0.0222]
(95% CI `\loCumSix{}` to `\hiCumSix{}` [−0.035; −0.009]).

**Table 7 and Figure 4 (non-linearity).** The response is a threshold, not a
gradient: months with 20+ MHW days show −0.33 log points (≈ −28%,
p < 0.001), 10–19 days −0.06 (n.s.), fewer days nothing. Anomaly bins are
individually imprecise but positive for +0.5 to +1 °C.

**Table 4 and Table 8 (displacement).** Own exposure remains negative;
the 0–60 km ring is negative and insignificant (`\bRingNear{}` [−0.015],
p = `\pRingNear{}`) — a heatwave that hits the cell typically also hits its
first ring, so there is no nearby refuge; the 60–150 km ring is positive
(`\bRingMid{}` [+0.0147], p = `\pRingMid{}` [0.051]), consistent with
medium-distance relocation; the 150–300 km ring is null. At the region ×
month level, regional MHW exposure is not associated with the mean distance
to coast or with concentration, but the number of active cells rises
(`\bRelocActive{}` [+0.019], p < 0.001): effort spreads out. [AUTHOR: read
these with the 4-region caveat.]

**Table 5 (heterogeneity).** By region: North −0.041 (p < 0.001),
Southeast −0.011, Northeast −0.012, South +0.004 (n.s.) — a tropical-to-
subtropical gradient. By distance: offshore −0.024 (p < 0.001) versus
nearshore −0.007 (n.s.). By gear: drifting longlines −0.013 (p < 0.001),
generic "fishing" −0.011, set longlines and trawlers not distinguishable
from zero. The response is thus concentrated in the offshore pelagic
longline fleet in tropical waters.

**Tables 6, 9, 10, 11 and Figure 5 (robustness and placebos).** The
coefficient is stable across the resolution-5 grid (`\bResFive{}`),
region × year trends (`\bTrendRegYear{}`), stable cells
(`\bStableCells{}`), Conley 100/400 km, coastal and low-coverage exclusions,
and the three alternative MHW definitions (`\bMhwPninetyfive{}`,
`\bMhwDurTen{}`, `\bMhwClimEarly{}`) — the 95th-percentile definition gives
the largest effect, a dose-response pattern. The within-region permutation
places the observed coefficient outside the 95% range of
`\nPermutations{}` draws (p = `\pPermutation{}` [0.02]). The 12-month lead
is significant in the baseline even conditional on lags — not anticipation
(the 12-month autocorrelation of exposure is 0.05) but differential trends;
with cell-specific linear trends the lead vanishes (`\bLeadTwelveCT{}`,
p = `\pLeadTwelveCT{}` [0.27]) and the main coefficient is
`\bMhwCellTrend{}` [−0.0046] (p = `\pMhwCellTrend{}` [0.037]), while the
cumulative six-month effect is no longer significant (`\bCumSixCT{}`). We
report the baseline as the estimate comparable to the literature and the
cell-trend specification as the conservative, placebo-consistent bound.

## 5. Figures — captions to adapt

- Figure 1 `fig_event_study_res4.png`: PPML coefficients on MHW days by
  horizon, −3 to +6 months, 95% Conley intervals; dashed line at zero;
  dotted line separates leads (placebo) from lags.
- Figure 2 `fig_maps_effort_mhw.png`: left, mean monthly apparent fishing
  hours by cell (log scale); right, mean MHW days per month, 2013–2024.
- Figure 3 `fig_timeseries.png`: total monthly hours (bars) and share of
  cells under MHW (line), national aggregate.
- Figure 4 `fig_dose_response.png`: coefficients for bins of SST anomaly
  and of MHW days relative to the reference bins.
- Figure 5 `fig_placebo_permutation.png`: distribution of the MHW
  coefficient across 50 within-region permutations; red line = observed.

## 6. Limitations (bullet reminders for the author)

AIS coverage bias (population = tracked fleet, longline-dominated);
apparent effort is model-inferred; 0.25° SST resolution near the coast;
association not causation — trends and unobserved time-varying cell
shocks remain possible despite placebos; monthly frequency only; H4/H5
(productivity, protected areas) deferred to future work.
