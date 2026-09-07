# Relatório de viabilidade

**Versão 1.0 — 2026-09-07 (piloto executado).**
Piloto: litoral NE (bbox −38,−10.5 → −32,−4.5), 2022-01–2023-12, mensal,
400 células H3 res. 5 amostradas de 874 oceânicas (seed 20260903).
Execução: `scripts/02_run_feasibility.R` (log `02_run_feasibility_20260907_*.log`);
métricas em `outputs/diagnostics/feasibility_metrics.csv` e composição em
`gfw_composition_pilot.csv`. Nenhum número abaixo foi digitado à mão fora
desses artefatos.

## A. Verificações de acesso (histórico 03–07/09)

| Teste | Resultado |
|---|---|
| GFW API v3 autenticada (4wings MONTHLY 0,1°) | **OK** — 1.654 linhas, 24/24 meses |
| OISST v2.1 — NCEI HTTPS / PSL OPeNDAP | **OK** (OPeNDAP em fatias ≤183 dias — D13) |
| OISST — NCSS e ERDDAP | **quebrados** no período 05–07/09 (500/502/000) — contornados |
| IBGE, CRAN (heatwaveR, geobr), Crossref | OK |

## B. As 10 perguntas do piloto — respondidas

| # | Pergunta | Critério | Resposta | Veredito |
|---|---|---|---|---|
| 1 | Acesso reproduzível? | script de ponta a ponta sem intervenção | Sim: GFW + OISST + MHW + painel em execução única, com retries e cache (runtime 44,7 min). Instabilidade da NOAA exigiu D10→D13, já codificada | ✅ |
| 2 | Licença permite pesquisa e redistribuição? | agregados publicáveis | OISST: domínio público. GFW: CC BY-SA 4.0 para dados; **pendência não-bloqueante:** ler os termos da API v3 antes de publicar agregados derivados no repositório/dashboard | ✅ c/ ação |
| 3 | Períodos compatíveis? | interseção ≥ 8 anos | Sim: GFW cobre 24/24 meses do piloto; OISST 1991–2023 contínuo (12.053 dias, **0 lacunas**). Estudo completo: GFW 2012+ ∩ OISST → ≥ 12 anos | ✅ |
| 4 | Resoluções cruzáveis? | mapeamento sem ambiguidade dominante | Sim: mediana de 1 célula GFW 0,1° por H3 (máx 4); 1 H3 por pixel SST (máx 3); distância centróide→pixel mediana 11,2 km (máx 18). Ressalva: H3 res 5 (~252 km²) é mais fina que o pixel SST (~770 km²) — células vizinhas compartilham pixel (tratável com Conley; res 4 inverteria a razão) | ✅ c/ ressalva |
| 5 | % células-mês com esforço > 0? | ≥ ~25% | **5,2% — REPROVADO no critério.** 64,3% das células têm esforço em algum mês; 23/24 meses têm esforço. Mesmo condicional às células com esforço, ~8% dos meses são positivos. Esforço total: só 4.752 h em 2 anos no bbox | ❌ |
| 6 | Variação suficiente? | não degenerada; MHWs ocorrem | SST: sd dentro-célula 0,74 °C. Esforço: sd log1p dentro 0,23 / entre 0,27 (baixa, reflexo dos zeros). MHW: **2.530 eventos iniciados em 2022–23, 100% dos pixels com evento; 60,5% das células-mês com ≥1 dia de MHW** (57% com ≥5). Tratamento abundante — tão comum que o binário é pouco informativo: usar margens de intensidade (dias, intensidade, categorias) | ✅ c/ ressalva |
| 7 | Custo computacional? | < 30 min, < 8 GB | 44,7 min (41 = download OISST, único e cacheado; reexecução ~4 min), RAM pico 370 MB. Escala para a costa inteira: horas de download únicos, memória trivial | ✅ |
| 8 | Identificador de embarcação? | documentar nível legítimo | API agrega por célula×mês×bandeira×arte (14 pares flag×gear; contagem de embarcações disponível). IDs individuais existem em outros endpoints, mas o desenho usa agregados — suficiente e mais simples eticamente | ✅ |
| 9 | Cobertura representativa? | viés quantificado | **Não para o NE artesanal:** frota observada é 76% espinhel de superfície (BRA + sem bandeira), com trawlers CHN/ARG/FLK em águas distantes; zero artes artesanais. A população observável = frota industrial/semi-industrial rastreada, dominada por espinhel | ⚠️ |
| 10 | Conceito = esforço pesqueiro? | erro de medida discutível | "Apparent fishing effort" = horas de comportamento de pesca inferidas por modelo da GFW a partir de AIS — padrão na literatura; erro de medida e gaps de AIS serão discutidos no artigo | ✅ |

## C. Decisão recomendada: **RESTRINGIR (continuar com ajustes)**

A viabilidade **técnica** está integralmente demonstrada (1, 3, 4, 7, 8).
A reprovação em 5 e o alerta em 9 não derrubam o projeto — redirecionam o
desenho, conforme a regra de decisão pré-registrada ("restringir se 5, 6 ou
9 falharem parcialmente"):

1. **Escopo espacial completo, não só NE:** o estudo principal cobre toda a
   costa/ZEE — S/SE concentra a frota industrial densa em AIS; a esparsidade
   do NE não é representativa do universo do estudo.
2. **Zeros tratados por desenho, não por transformação:** especificação
   principal em **PPML (`fixest::fepois`)** + margem extensiva
   (presença/contagem); `log1p` vira robustez. Universo = *fishing
   footprint* (células com esforço em ao menos um mês da amostra completa),
   com o universo integral como robustez.
3. **Resolução:** testar H3 res. 4 como grade principal (célula ~1.770 km² >
   pixel SST) contra res. 5; decidir por zeros/variância na amostra completa
   (atualiza D2).
4. **Exposição contínua, não binária:** dias-MHW e intensidade como
   tratamento (60% das células-mês têm algum dia de MHW — o indicador
   binário quase não discrimina).
5. **População declarada:** todas as inferências valem para a **frota
   rastreada por AIS, dominada por espinhel** — título, abstract e
   conclusões dirão isso explicitamente.
6. **Ação administrativa:** ler os termos da API GFW antes de publicar
   agregados derivados (item 2).

**Portão:** esta recomendação aguarda a decisão do pesquisador
(continuar-com-ajustes / continuar-como-estava / reformular) antes de
qualquer download do universo completo (`_targets.R`, `feasibility_approved`).
