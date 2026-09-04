# Dicionário de dados (inicial — v0.1, 2026-09-03)

Convenções: snake_case; unidades SI; datas ISO-8601; CRS geodésico
EPSG:4674, métrico EPSG:5880; valores ausentes = NA explícito (nunca 0).
Este dicionário será expandido pelo pipeline (target `data_dictionary`).

## Painel analítico principal — `data/processed/panel_cell_month.parquet`

| Variável | Tipo | Unidade | Origem | Definição |
|---|---|---|---|---|
| cell_id | chr | — | derivada (H3) | índice H3 da célula (resolução em `grid_resolution`) |
| grid_resolution | int | — | derivada | resolução H3 da grade |
| year_month | chr | AAAA-MM | derivada | mês de referência |
| lon_c, lat_c | dbl | graus | derivada | centróide da célula (EPSG:4674) |
| fishing_hours | dbl | horas | GFW 4wings | apparent fishing effort agregado na célula-mês |
| vessel_count | int | embarcações | GFW | embarcações distintas ativas na célula-mês (se disponível) |
| effort_present | int | 0/1 | derivada | 1 se fishing_hours > 0 |
| sst_mean | dbl | °C | OISST v2.1 | média mensal da SST diária na célula |
| sst_anom | dbl | °C | OISST | anomalia média vs. climatologia 1991–2020 |
| mhw_days | int | dias | derivada (heatwaveR) | dias do mês sob evento MHW (Hobday et al. 2016) |
| mhw_any | int | 0/1 | derivada | 1 se mhw_days ≥ 1 |
| mhw_max_intensity | dbl | °C | derivada | intensidade máxima acima do limiar no mês |
| mhw_days_ring1 | dbl | dias | derivada | média de mhw_days nas células vizinhas (anel k=1, exclui a própria) |
| dist_coast_km | dbl | km | derivada (IBGE) | distância do centróide à linha de costa |
| dist_port_km | dbl | km | derivada (ANTAQ*) | distância ao porto mais próximo (*pendente teste da fonte) |
| in_mpa | int | 0/1 | CNUC/ICMBio* | célula intersecta UC marinha (*pendente teste da fonte) |
| region | chr | — | IBGE | macrorregião costeira associada (N/NE/SE/S) |
| muni_code_near | chr | — | IBGE | município costeiro mais próximo (código IBGE 7 dígitos) |

## Metadados e linhagem — `data/metadata/`

| Arquivo | Conteúdo |
|---|---|
| checksums.csv | arquivo bruto, sha256, bytes, data de download, URL exata |
| lineage.csv | derivado → insumos → função/target → versão do código (git hash) |
| download_log.csv | cada download: fonte, parâmetros, status, duração |

## Variáveis proibidas de criar sem verificação prévia

`fish_price_*` (nenhuma série verificada), `employment_fishing_*` (RAIS não
testada), `defeso_active` (camada regulatória não construída). Ver
`config/data_sources.yml`.
