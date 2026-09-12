# Prompt para o SciSpace — revisão bibliográfica (5 artigos-chave)

Cole o bloco em inglês abaixo no SciSpace (Literature Review / Deep Review).
Depois, **verifique cada referência sugerida na Crossref** antes de usar
(regra 13 do protocolo: título, autores, periódico, ano e DOI confirmados) e
confira o estrato Qualis na Plataforma Sucupira — o SciSpace não conhece o
Qualis; a lista de periódicos abaixo é uma tradução prática do critério
"A1–A3" para as áreas de Economia / Ciências Ambientais / Biodiversidade.

Já verificadas e no `references.bib` (não precisam ser redescobertas):
Hobday et al. 2016 (Prog. Oceanogr.); Hobday et al. 2018 (Oceanography);
Oliver et al. 2018 (Nat. Commun.); Smale et al. 2019 (Nat. Clim. Change);
Kroodsma et al. 2018 (Science); Free et al. 2019 (Science); Cheung & Frölicher
2020 (Sci. Rep.); Mills et al. 2013 (Oceanography); Santos Silva & Tenreyro
2006 (REStat); Conley 1999 (J. Econometrics); Correia, Guimarães & Zylkin 2020
(Stata J.); Schlegel & Smit 2018 (JOSS).

---

```
ROLE: You are assisting an economist preparing a peer-reviewed article on
fisheries economics and climate impacts.

WORKING TITLE: "Marine Heatwaves, Ocean Productivity and Fishing Effort:
High-Frequency Evidence from the Brazilian Coast"

STUDY IN ONE PARAGRAPH: We build a cell-by-month panel (H3 hexagonal cells,
~1,770 km2; 4,765 cells; Jan 2013 - Dec 2024) of apparent fishing effort from
Global Fishing Watch (AIS-based, hours) along the entire Brazilian coast and
EEZ, matched to daily NOAA OISST v2.1 sea-surface temperature. Marine
heatwaves (MHWs) follow Hobday et al. (2016): 1991-2020 daily climatology,
90th percentile threshold, >=5 consecutive days. We estimate Poisson
pseudo-maximum-likelihood (PPML) models with cell, calendar-month and
region x month-of-year fixed effects, Conley spatial standard errors,
distributed leads/lags, neighbourhood exposure rings (spatial displacement),
heterogeneity by region, gear type and distance to coast, and a battery of
placebos (leads, within-region permutation) and robustness checks (grid
resolution, alternative MHW definitions, cell-specific trends). Main
finding: MHW days are associated with lower fishing hours on the intensive
margin (about -0.5% to -1.1% per MHW day, concentrated in months with 20+
MHW days), no anticipation, no short-distance displacement but a positive
association with neighbours' exposure at 60-150 km, strongest for drifting
longliners offshore and in the North region. We also present a reproducible
"Marine Fisheries Data Cube" (targets + Parquet + DuckDB + H3) as an
information-systems contribution.

TASK: Identify the FIVE most important and necessary references to anchor
the Related Literature section, one per theme below, and for each provide:
(a) full citation with DOI; (b) 3-4 sentence summary of method and finding;
(c) one sentence on exactly how it connects to our design or result;
(d) the journal's field and why it qualifies as a top-tier venue.

THEMES (one reference each):
1. Behavioural response of fishing fleets to marine heatwaves or ocean
   temperature shocks measured with high-frequency vessel data (AIS/VMS):
   effort, location choice, or displacement.
2. Economic consequences of marine heatwaves for fisheries (landings,
   revenue, closures, management responses), preferably with a
   quasi-experimental or panel design.
3. Fishing location choice / spatial bioeconomics: discrete-choice or
   panel models of where fishers fish and how they respond to environmental
   gradients (the theoretical background for the displacement analysis).
4. Ocean warming and marine heatwaves in the South Atlantic / Brazilian
   coast: trends, drivers, or documented impacts on tropical and subtropical
   fisheries or ecosystems.
5. Data-quality limits of AIS-based apparent fishing effort (coverage bias
   toward larger vessels, artisanal fleets, inference error) and how
   empirical studies should handle them.

CONSTRAINTS:
- Only peer-reviewed journals of the highest tier or scholarly books from
  established academic presses. Acceptable journals include (non-exhaustive):
  Science; Nature; Nature Climate Change; Nature Communications; PNAS;
  Global Change Biology; Fish and Fisheries; ICES Journal of Marine Science;
  Fisheries Research; Marine Policy; Ecological Economics; Journal of
  Environmental Economics and Management; American Journal of Agricultural
  Economics; Marine Resource Economics; Progress in Oceanography; Frontiers
  in Marine Science; Global Environmental Change; Annual Review of Marine
  Science; Journal of the Association of Environmental and Resource
  Economists; Environmental and Resource Economics. Books: Oxford UP,
  Cambridge UP, Springer, Elsevier academic monographs, FAO technical
  series only if peer-reviewed.
- Exclude preprints, conference abstracts, grey literature, predatory or
  unindexed journals, and anything without a resolvable DOI.
- Do not invent references. If unsure about any bibliographic field, say so.
- Prefer 2013-2025, but a foundational earlier work is acceptable for theme 3.
- Do NOT return the references already in our list: Hobday 2016/2018,
  Oliver 2018, Smale 2019, Kroodsma 2018, Free 2019, Cheung & Frolicher
  2020, Mills 2013, Santos Silva & Tenreyro 2006, Conley 1999.

OUTPUT FORMAT: a numbered list of five entries following (a)-(d), then a
short paragraph (<=150 words) suggesting how the five works order a
literature narrative that leads to our research gap: high-frequency,
coast-wide evidence for a tropical/subtropical fleet in Brazil, where
national fisheries statistics have been discontinued.
```
