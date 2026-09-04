# Guia de reprodutibilidade (v0.1 — 2026-09-03)

## Ambiente de referência

| Componente | Versão detectada (2026-09-03) |
|---|---|
| SO | Windows 11 Home 10.0.26200 |
| R | 4.4.3 (`C:\Program Files\R\R-4.4.3`) — 4.4.2 também instalada |
| Quarto | 1.9.38 |
| Git | 2.49.0.windows.1 |
| Python | 3.13.2 (usado só se necessário; ambiente isolado em `python/.venv`) |

## Princípios

1. **Dados brutos imutáveis** — `data/raw/` nunca é editado; cada arquivo
   tem sha256 em `data/metadata/checksums.csv` no momento do download.
2. **Tudo via pipeline** — nenhum resultado científico (número, tabela,
   figura) é copiado manualmente; tudo é target de `_targets.R`.
3. **Dependências travadas** — `renv.lock` versionado; restaurar com
   `renv::restore()`. Pacotes fora do CRAN (ex.: `gfwr`) pinados por
   commit/tag do GitHub.
4. **Seeds** — seed global 20260903 (`config/config.yml`); operações
   estocásticas declaram seed local.
5. **Segredos fora do Git** — `.Renviron` (ignorado) guarda tokens;
   scripts leem via `Sys.getenv()` e falham com mensagem clara se ausente.
6. **Logs** — todo script em `scripts/` grava início/fim/sessionInfo em
   `outputs/logs/`.
7. **Licenças e redistribuição** — agregados derivados da GFW respeitam
   CC BY-SA (atribuição + share-alike); OISST é domínio público; WDPA (se
   usada) não permite redistribuir os polígonos originais.

## Reconstrução do zero

```r
# 1. clonar/copiar o projeto e abrir o .Rproj no RStudio
renv::restore()
source("scripts/00_check_environment.R")   # audita ambiente e credenciais
# 2. (uma vez) criar .Renviron com GFW_TOKEN=...
# 3. Background Job: scripts/01_test_data_access.R
# 4. Background Job: scripts/02_run_feasibility.R  → docs/feasibility_report.md
# 5. após aprovação: Background Job scripts/03_run_pipeline.R (targets::tar_make())
# 6. Terminal: quarto render article/manuscript.qmd  (ou scripts/05_render_article.R)
```

## Proveniência

`data/metadata/lineage.csv` liga cada derivado a insumos + função + git
hash. O grafo do pipeline (`targets::tar_visnetwork()`) é a documentação
executável da linhagem.
