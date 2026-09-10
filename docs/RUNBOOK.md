# RUNBOOK — Marine Fisheries Data Cube

Comandos operacionais do compêndio. Detalhes conceituais em
[research_protocol.md](research_protocol.md); regras de reprodutibilidade em
[reproducibility_guide.md](reproducibility_guide.md); política de IA em
[AI_POLICY_AND_REPRODUCIBILITY.md](AI_POLICY_AND_REPRODUCIBILITY.md).

## 0. Pré-requisitos (uma vez)

```r
renv::restore()                            # dependências travadas
source("scripts/00_check_environment.R")   # audita R, Quarto, Git, token
```
`.Renviron` na raiz (fora do Git) com `GFW_TOKEN=...`.

**R fica fora do PATH nesta máquina:** use
`C:\Program Files\R\R-4.4.3\bin\Rscript.exe` quando chamar pelo terminal.

## 1. Pipeline completo (Background Job)

```r
source("scripts/03_run_pipeline.R")   # targets::tar_make()
```
Downloads (GFW 2013–2024; OISST 1991–2024 global recortado), climatologia e
eventos MHW (Hobday et al. 2016), grades H3 res 4 e 5, painéis Parquet,
auditoria, modelos, figuras e tabelas. Todos os passos têm cache em disco: se
o processo cair, reexecutar retoma de onde parou.

**Processos longos devem rodar destacados do editor:**
```powershell
Start-Process "C:\Program Files\R\R-4.4.3\bin\Rscript.exe" `
  -ArgumentList '"scripts\03_run_pipeline.R"' -WindowStyle Hidden `
  -RedirectStandardOutput "outputs\logs\run_stdout.log" `
  -RedirectStandardError  "outputs\logs\run_stderr.log"
```

## 2. Pacote para o Overleaf

```r
source("scripts/90_export_overleaf.R")
```
Gera `outputs/overleaf/` (tabelas `.tex` em booktabs, figuras, `numbers.tex`,
`main.tex`, `references.bib`, declarações) e o zip `outputs/overleaf_AAAAMMDD.zip`
para upload direto no Overleaf.

### Regra dos números

Nenhum número é digitado no texto. Cada valor citado é uma macro de
`numbers.tex` — por exemplo `\bMhwMain{}`, `\panelObs{}`, `\shareEffortPos{}`.
Se a estimativa mudar, o texto acompanha sozinho na próxima exportação.
Para acrescentar um número novo, edite `mfdc_numbers_tex()` em
`R/19_export_overleaf.R` e reexporte — nunca escreva o valor no `.tex`.

### Divisão de papéis (política de IA)

| Camada | Quem faz |
|---|---|
| Pergunta, desenho, identificação, interpretação, conclusões | autor |
| Código, pipeline, testes, infraestrutura e docs do repositório | autor com Claude Code (declarado) |
| **Prosa do artigo** | **exclusivamente o autor, no Overleaf** |

## 3. Inspeção rápida (Console)

```r
targets::tar_visnetwork()                       # grafo do pipeline
p <- arrow::read_parquet("data/processed/panel_cell_month_res4.parquet")
readLines("outputs/tables/RESULTS_DIGEST.md")   # números correntes
```

## 4. Testes

```r
testthat::test_dir("tests/testthat")
```

## 5. Estado do projeto

Decisões numeradas em [decisions_log.md](decisions_log.md) (D1–D17);
viabilidade em [feasibility_report.md](feasibility_report.md);
próximos passos em [next_steps.md](next_steps.md).
