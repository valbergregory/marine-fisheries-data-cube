# Tabela de estimandos (v0.1 — 2026-09-03)

Linguagem associacional (ver identification_strategy.md). "ATT-like" indica
o parâmetro que a associação aproximaria sob as hipóteses de identificação
ainda não validadas.

| Campo | E1 — intensidade local | E2 — margem extensiva | E3 — deslocamento espacial | E4 — realocação costa/porto | E5 — dinâmica |
|---|---|---|---|---|---|
| Unidade | célula×mês | célula×mês | célula×mês | região×mês (agregado do esforço) | célula×mês |
| Exposição | dias-MHW na célula (contínua) e indicador MHW≥5d | idem | dias-MHW nos anéis k=1,2 (vizinhança), condicional à própria | dias-MHW ponderados pelo esforço histórico da região | trajetória {MHW_{t-k}} k=0..K |
| Outcome | log1p(apparent fishing hours) | 1{horas>0}; nº embarcações | log1p(horas) | distância média do esforço à costa e ao porto mais próximo; HHI/Gini espacial | log1p(horas) |
| Comparação | mesma célula em meses sem MHW, líquida de δ_t e sazonalidade regional | idem | células com vizinhança exposta vs. não, própria exposição fixa | mesma região, meses sem MHW | perfil de defasagens vs. t-1 |
| Horizonte | contemporâneo | contemporâneo | contemporâneo + 1–3 meses | contemporâneo + 1–3 meses | 0–6+ meses, leads −3..−1 |
| População | células da ZEE/costa brasileira com esforço AIS observável (frota rastreada) | idem | idem | regiões N/NE/SE/S | idem E1 |
| Parâmetro | semi-elasticidade do esforço a dias-MHW (ATT-like) | variação de prob. de atividade | semi-elasticidade cruzada (spillover) | variação em km / pontos de concentração | β_k por defasagem |
| Interpretação | resposta líquida local da frota rastreada | margem de entrada/saída | evidência de realocação (H2) | mudança do padrão espacial (H2/H3) | persistência/recuperação (perguntas 4) |

Notas:
1. Todos os estimandos são **condicionais à cobertura AIS** — não se
   estendem à frota artesanal não rastreada.
2. E2 protege contra sensibilidade do log1p; PPML como especificação
   alternativa de E1.
3. E4 usa agregação regional para evitar pós-tratamento na composição de
   células.
4. Heterogeneidades (arte de pesca, região, distância, CHL, UC/defeso)
   são versões interagidas de E1/E3 — registrar antes de estimar.
