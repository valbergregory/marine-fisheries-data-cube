# A parte quantitativa, passo a passo (para o autor)

Documento de apoio ao pesquisador: o que cada etapa faz, por que foi escolhida
e como reproduzi-la. Números citados são os do `outputs/tables/RESULTS_DIGEST.md`
corrente; o texto do artigo é escrito pelo autor (docs/AI_POLICY_AND_REPRODUCIBILITY.md).

## 1. Unidade de análise e painel

- Célula hexagonal **H3 resolução 4** (~1.770 km²) × **mês**, 2013-01 a 2024-12
  (144 meses), toda a costa/ZEE brasileira (bbox em `config/config.yml`).
- Universo = *fishing footprint*: as 4.765 células com esforço em ao menos um
  mês → 686.160 células-mês (decisão D14/D17). Res 5 (31.481 células) é robustez.
- Outcome: `hours` = *apparent fishing hours* (GFW, agregado por célula-mês).
- Exposição: `mhw_days` = dias do mês sob evento MHW no pixel OISST (0,25°)
  que contém o centróide da célula; `sst_anom` = anomalia média do mês.
- Construção: `R/03` (GFW), `R/04` (OISST), `R/07` (MHW), `R/08` (grade),
  `R/09` (painel), `R/10` (auditoria). Tudo orquestrado por `_targets.R`.

## 2. Definição de onda de calor marinha (Hobday et al. 2016)

Para cada pixel: climatologia diária 1991–2020; limiar = percentil 90 da SST
para cada dia do calendário (janela de 31 dias, suavizada); evento = ≥5 dias
consecutivos acima do limiar (intervalos ≤2 dias unem eventos). Métricas
mensais: dias de MHW, intensidade máxima acima do limiar, SST média, anomalia
(SST − climatologia sazonal). Implementação: `heatwaveR::ts2clm` +
`detect_event` (`R/07_clean_ocean.R`). Uma anomalia positiva simples **não**
é MHW: por isso `sst_anom` entra como controle separado.

## 3. Modelo principal (PPML com efeitos fixos)

    E[hours_it] = exp( β·mhw_days_it + γ·sst_anom_it + α_i + δ_t + θ_{r(i),m(t)} )

- **Por que PPML** (`fixest::fepois`): 84% das células-mês têm zero horas;
  log(1+y) distorce a escala e é sensível à unidade (Santos Silva & Tenreyro);
  PPML é consistente sob a média condicional exponencial, aceita zeros e
  heteroscedasticidade, e β lê-se como semi-elasticidade (100·β % por dia).
- **Efeitos fixos**: α_i (célula: profundidade, distância à costa, produtividade
  média, portos, regulação estável), δ_t (mês-calendário: combustível, demanda,
  ENSO médio, choques nacionais), θ (região × mês-do-ano: sazonalidade
  regional, defesos anuais).
- **Leitura do resultado**: β = −0,0113 (p=0,001) ⇒ cada dia adicional de MHW
  no mês associa-se a −1,1% de horas, *condicional* à anomalia; γ = +0,13/°C ⇒
  água mais quente que o normal, sem extremo, atrai esforço. Sem o controle
  de anomalia, β mistura os dois (−0,004, ns).
- Margem extensiva (`effort_present` por MQO): ≈0 ⇒ resposta é intensiva.

## 4. Erros-padrão

Células vizinhas compartilham pixel de SST e frota → dependência espacial;
meses consecutivos → dependência serial. Usamos **Conley** (kernel espacial,
cutoff 200 km; robustez 100/400) via `vcov = conley()` do fixest; se falhar,
cluster bidirecional célula+tempo (`mfdc_vcov_summary`, `R/12`).

## 5. Dinâmica e placebo de antecipação (`R/13`)

    hours ~ f(mhw,3)+f(mhw,2)+f(mhw,1) + l(mhw,0..6) + sst_anom | EF

Leads (f) são o placebo: se o esforço "reagisse" antes da MHW existir, a
especificação estaria contaminada. Resultado: leads ≈0 (p 0,59/0,60/0,998);
lag 0 −0,66%, lag 2 −0,65%, lag 4 −0,61%, dissipa pelo 6º mês. Efeito
acumulado = soma dos lags, com SE = √(w'Vw) sob a matriz de Conley
(`mfdc_cumulative_effect`).

## 6. Deslocamento espacial (`R/14`)

Exposição média dos vizinhos em anéis por distância entre centróides:
0–60 km (≈ anel k=1 na res 4), 60–150, 150–300. Implementação com matriz
esparsa normalizada por linha (W·M, pacote Matrix), o que escala para anéis
grandes. Coeficiente positivo no vizinho = esforço migra para a célula quando o
entorno queima. Resultado: 0–60 ns; **60–150 km +1,5% (p=0,051)**; 150–300 ns.

## 7. Heterogeneidade (`R/12`, `mfdc_heterogeneity_models`)

`i(region, mhw_days)`; distância (offshore vs. nearshore na mediana); arte de
pesca com painel célula×mês×arte e EF célula×arte (`R/06`). Resultados: Norte
−4,1%***, Sudeste −1,1%**, Nordeste −1,2%*, Sul ≈0; offshore −2,4%*** vs.
nearshore ns; espinhel de deriva −1,3%***, arrasto e espinhel de fundo ns.

## 8. Não-linearidade (`mfdc_nonlinear_models`)

Faixas de anomalia (ref −0,5..0 °C) e de dias de MHW (ref 0) como dummies →
curva de resposta (fig. dose-resposta). Mostra o "branda atrai, extremo
repele" sem impor linearidade.

## 9. Realocação agregada — estimando E4 (`mfdc_build_region_month`)

Região × mês: distância média do esforço à costa (ponderada por horas), HHI
espacial, células ativas. Exposição = média de dias-MHW com **pesos históricos
fixos** por célula (evita contaminar o regressor com a composição
contemporânea). Só 4 regiões ⇒ SE robusto e leitura cautelosa.

## 10. Robustez e placebos (`R/15`)

Res 5; tendências região×ano; células estáveis (≥12 meses ativos); Conley
100/400; definições alternativas de MHW (p95; duração ≥10 dias; climatologia
1982–2011, que exigiu OISST desde 1982); exclusões (células <25 km da costa,
proxy de porto; <6 meses ativos); placebo temporal (lead de 12 meses);
placebo espacial (50 permutações das séries de MHW entre células da mesma
região → p-valor de randomização); Moran's I dos resíduos médios por célula
(permutação, matriz 0–60 km). Lido até aqui: p95 −1,65%*** (dose-resposta
coerente), demais especificações entre −0,7% e −1,2%.

## 11. Como replicar

```r
renv::restore()                              # pacotes travados (renv.lock)
source("scripts/00_check_environment.R")     # R 4.4.3, token GFW no .Renviron
source("scripts/03_run_pipeline.R")          # targets::tar_make() — tudo
source("scripts/90_export_overleaf.R")       # tabelas + figuras + numbers.tex + zip
targets::tar_visnetwork()                    # grafo: o que depende de quê
```
Cada alvo tem cache; reexecutar é retomar. Processos longos: destacados
(`Start-Process`, ver RUNBOOK). Para inspecionar um modelo:

```r
m <- readRDS("outputs/models/main_models_res4.rds")
fixest::etable(m$summaries)                  # tabela
m$coefs                                      # b/se/stat/p padronizados
d <- readRDS("outputs/models/dynamic_res4.rds"); d$event_study
```
Para mudar uma escolha (percentil, duração, cutoff, anéis): edite
`config/config.yml` ou o argumento da função no `_targets.R` e rode
`tar_make()` — só o que depende da mudança é recomputado. Nunca digite um
número no `.tex`: acrescente a macro em `mfdc_numbers_tex()` (`R/19`).
