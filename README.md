# Marine Fisheries Data Cube

Research compendium for the working paper:

> **Marine Heatwaves, Ocean Productivity and Fishing Effort: High-Frequency
> Evidence from the Brazilian Coast**
> (IS-oriented alternative: *A Geospatial Information System for
> Climate-Resilient Fisheries: Monitoring Marine Heatwaves and Fishing-Effort
> Displacement in Brazil*)

Reproducible, R-first geospatial infrastructure integrating fishing effort
(Global Fishing Watch), sea-surface temperature and marine heatwaves
(NOAA OISST v2.1 + Hobday et al. 2016 definition via `heatwaveR`), ocean
productivity, marine protected areas, ports and territorial characteristics
along the Brazilian coast.

**Status (2026-09-03):** first delivery — environment audit, project
skeleton, scientific protocol, data inventory, access tests and feasibility
plan. **No full-universe download and no definitive estimation yet.**
See [docs/next_steps.md](docs/next_steps.md).

## Estrutura

| Pasta | Conteúdo |
|---|---|
| `config/` | Configuração do projeto e inventário máquina-legível das fontes |
| `R/` | Funções do pipeline (chamadas por `_targets.R`) |
| `scripts/` | Scripts executáveis (Console / Background Jobs / Terminal) |
| `data/raw` | **Imutável.** Nunca editar manualmente. Fora do Git |
| `data/interim`, `data/processed` | Derivados reproduzíveis (fora do Git) |
| `data/metadata` | Checksums, linhagem, inventários (versionados) |
| `outputs/` | Figuras, tabelas, modelos, logs, diagnósticos |
| `article/` | Manuscrito Quarto (EN) + versões editorial-específicas |
| `docs/` | Protocolo, inventário, viabilidade, identificação, decisões |
| `app/` | Protótipo Shiny (após aprovação da viabilidade) |
| `tests/` | testthat |
| `python/` | Somente se houver vantagem concreta (ambiente isolado) |

## Como reproduzir (estado atual)

```r
# No RStudio, com o projeto aberto (marine-fisheries-data-cube.Rproj):
renv::restore()                              # restaura dependências travadas
source("scripts/00_check_environment.R")     # Console: auditoria do ambiente
# Tools > Jobs > Run Script as Background Job:
#   scripts/01_test_data_access.R            # testes de acesso às fontes
#   scripts/02_run_feasibility.R             # piloto NE (após token GFW)
```

O pipeline completo (`targets::tar_make()`, via `scripts/03_run_pipeline.R`)
só deve ser executado após a aprovação do relatório de viabilidade
([docs/feasibility_report.md](docs/feasibility_report.md)).

## Credenciais

Tokens ficam **fora do Git**, em `.Renviron` na raiz do projeto (já no
`.gitignore`):

```
GFW_TOKEN=<token da API do Global Fishing Watch>
COPERNICUSMARINE_SERVICE_USERNAME=<se/quando Copernicus for usado>
COPERNICUSMARINE_SERVICE_PASSWORD=<idem>
```

Token GFW: criar conta gratuita em <https://globalfishingwatch.org/our-apis/>
e gerar o token no portal de APIs.

## Licenças e redistribuição

Cada fonte tem licença própria — ver `config/data_sources.yml` e
`docs/data_inventory.md`. Dados brutos não são redistribuídos neste
repositório; apenas código, metadados e agregados permitidos.
