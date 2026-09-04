# Plano das próximas etapas (2026-09-03)

## Bloqueio único para o piloto

- [ ] **Valber:** criar conta e token na Global Fishing Watch
  (<https://globalfishingwatch.org/our-apis/>) e salvar em `.Renviron`
  na raiz do projeto: `GFW_TOKEN=...` (arquivo já ignorado pelo Git).

## Fase 1 — Viabilidade (1–2 sessões)

1. Instalar dependências espaciais (Background Job:
   `scripts/00b_install_dependencies.R`) — sf, terra, exactextractr,
   h3jsr*, heatwaveR, arrow, duckdb, gfwr (GitHub, pinado).
   *Se `h3jsr` falhar no Windows, fallback documentado: grade 0,25°.
2. Rodar `scripts/01_test_data_access.R` (Background Job) — valida token
   GFW com consulta mínima + baixa 1 dia de OISST + malha IBGE.
3. Rodar `scripts/02_run_feasibility.R` (Background Job) — piloto NE
   2022–2023, mensal, ≤400 células; preenche as 10 perguntas do
   `docs/feasibility_report.md`.
4. **Revisão do pesquisador:** aprovar/restringir/reformular (regra de
   decisão no relatório). ⛔ Nada de download completo antes disso.

## Fase 2 — Cubo de dados (após aprovação)

5. Decidir unidade de análise (D2) com números do piloto.
6. Downloads completos com checksums + linhagem (targets).
7. Climatologia 1991–2020 + eventos MHW (heatwaveR) para toda a costa.
8. Painel célula×mês em Parquet + consultas DuckDB + validação
   (testthat + validate) + relatório de auditoria.

## Fase 3 — Análise

9. Descritivas e mapas; revisão de literatura sistematizada (Related
   Literature) com citações verificadas via Crossref.
10. Modelos principais (fixest, Conley), dinâmica (lags/DLNM),
    deslocamento espacial, robustez (lista da seção 11 do protocolo).

## Fase 4 — Produtos

11. Protótipo Shiny (após dados/modelos validados).
12. Manuscrito EN (Marine Policy / Fisheries Research / Ecological
    Economics / ICES JMS) + delimitação da versão SBSI (contribuição de SI
    distinta — sem submissão duplicada; diferenças registradas em
    `article/`).
