# Registro de decisões

| ID | Data | Decisão | Justificativa | Status |
|---|---|---|---|---|
| D1 | 2026-09-03 | Projeto criado em subdiretório próprio `marine-fisheries-data-cube` (nome sem espaços/acentos) dentro de `D:\Claude code - projetos` | O diretório raiz contém vários projetos independentes; nomes sem espaço evitam fricção com CLI/renv/Quarto/Python | ativa |
| D2 | 2026-09-03 | Unidade de análise preferida: célula espacial × **mês**; comparação formal H3 res. 4/5/6 vs. grade regular 0,25°, e mês vs. semana, adiada para o piloto | Compatibilidade com OISST 0,25°, controle de zeros excessivos e custo; critérios: % células com esforço>0, variância, custo de processamento | pendente de dados do piloto |
| D3 | 2026-09-03 | Dependências em dois estágios: `Imports` (viabilidade: targets, yaml, jsonlite, httr2, curl, data.table, checkmate, tarchetypes) instaladas agora; stack espacial/pesada (`Suggests`) instalada só após aprovação da viabilidade | Regra do protocolo: não instalar tudo automaticamente; evita horas de instalação antes de saber se o projeto é viável | ativa |
| D4 | 2026-09-03 | SST via NCEI HTTPS (arquivos diários) com OPeNDAP/PSL para recortes; ERDDAP rebaixado a alternativa | ERDDAP indisponível no teste (HTTP 000); NCEI e PSL responderam 200 | ativa |
| D5 | 2026-09-03 | Definição de MHW: Hobday et al. (2016) via heatwaveR; parâmetros em `config/config.yml`; anomalia simples nunca rotulada como MHW | Referência canônica confirmada via Crossref; implementação auditada em pacote publicado (JOSS) | ativa |
| D6 | 2026-09-03 | Linguagem associacional em todo o texto até identificação defensável; plausibilidade causal argumentada, não afirmada | Regra 12 do protocolo do pesquisador | ativa |
| D7 | 2026-09-03 | `gfwr` instalado do GitHub com versão pinada no renv.lock (não está no CRAN — verificado 404) | Cliente oficial da GFW; pinagem preserva reprodutibilidade | ativa |
| D8 | 2026-09-03 | CRS: análise métrica em EPSG:5880 (Brazil Polyconic/SIRGAS 2000); armazenamento geodésico em EPSG:4674 | Distâncias/áreas em metros ao longo de toda a costa; padrão SIRGAS do IBGE | ativa |
| D9 | 2026-09-03 | Python somente se necessário (candidato único até agora: toolbox `copernicusmarine` para clorofila — extensão); econometria permanece em R | Regra da arquitetura R-first | ativa |
