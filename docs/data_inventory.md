# Inventário de dados

Versão narrativa do inventário. A versão máquina-legível (campo a campo,
com status de teste) está em [`config/data_sources.yml`](../config/data_sources.yml).
Todos os testes abaixo foram executados em **2026-09-03** com requisições
mínimas (HEAD/GET de poucos KB) — nenhum download em massa foi feito.

## Prioridade fase 1 (núcleo)

### 1. Esforço pesqueiro — Global Fishing Watch (API v3)
- **Status: ACESSÍVEL COM TOKEN.** O endpoint respondeu HTTP 401 sem
  autenticação (serviço ativo; token gratuito exigido).
- **Ação do pesquisador:** criar conta em <https://globalfishingwatch.org/our-apis/>,
  gerar token e salvá-lo em `.Renviron` como `GFW_TOKEN=...` (nunca em script).
- Cliente R oficial: `gfwr` — **não está no CRAN** (verificado: CRAN 404 em
  2026-09-03); instalar do GitHub `GlobalFishingWatch/gfwr` com versão
  pinada no `renv.lock`.
- Conceito: *apparent fishing effort* (horas de pesca inferidas de AIS por
  modelo da GFW). Não é esforço declarado. Cobertura enviesada para
  embarcações ≥ ~15 m com AIS — a frota artesanal fica sub-representada.
- Licença: CC BY-SA 4.0 para dados agregados; confirmar termos da API antes
  de redistribuir agregados derivados.

### 2. SST — NOAA OISST v2.1
- **Status: ACESSÍVEL, SEM AUTENTICAÇÃO.**
  - NCEI HTTPS (arquivo diário global NetCDF): HTTP 200, ~1,5 MB/dia
    (testado `oisst-avhrr-v02r01.20240115.nc`, Content-Length 1.545.085).
  - PSL THREDDS/OPeNDAP (recorte espacial no servidor): HTTP 200.
  - ERDDAP (CoastWatch e Upwell): **indisponível no dia do teste** (HTTP 000)
    — não usar como caminho primário; manter como alternativa.
- 0,25°, diário, 1981-09–presente, domínio público.
- Volume estimado para recorte Brasil + 30 anos de climatologia: ordem de
  poucos GB via OPeNDAP; viável em disco local.

### 3. Ondas de calor marinhas — derivadas (não é fonte externa)
- Calculadas a partir do OISST com `heatwaveR` (CRAN, verificado 2026-09-03),
  definição de Hobday et al. (2016) — ver protocolo, seção 5.

### 4. Grade espacial — H3
- `h3jsr` (R) a validar na instalação; alternativa: grade regular 0,25°
  alinhada ao OISST (sem dependência externa). Decisão D2 pendente do piloto.

### 5. Costa, municípios e território — IBGE
- **Status: ACESSÍVEL.** API de localidades respondeu JSON válido
  (`estados/26` → Pernambuco); API de malhas v3 HTTP 200; pacote `geobr`
  no CRAN (municípios, faixa litorânea, UF). Dado público.

## Extensões condicionadas à viabilidade (fase 2+)

| Fonte | Status 2026-09-03 | Observação |
|---|---|---|
| Clorofila — Copernicus Marine | portal OK (200); download exige conta gratuita | toolbox `copernicusmarine` é Python → se usado, ambiente isolado em `python/` |
| UCs marinhas — ICMBio/CNUC (alt.: WDPA) | portais OK (200); download direto **não testado** | localizar geoserviço CNUC; WDPA não permite redistribuir shapefile |
| Portos — ANTAQ | portal OK (200); dataset georreferenciado **não testado** | verificar cobertura de portos pesqueiros pequenos |
| Emprego — RAIS/Novo CAGED (CNAE 03) | **não testado** | só emprego formal; outcome municipal secundário |
| Seguro-Defeso — Portal da Transparência | **não testado** | pagamentos por município/mês, se compatível |
| Preços de pescado | **nenhuma série nacional verificada** | não usar até localizar fonte real |
| Diesel — ANP | **não testado** | possível controle de custo |
| Legislação de defeso | **não testado** | alto custo de codificação manual; só com camada confiável |

## Bloqueios ativos

1. **GFW exige token** — bloqueio administrativo (não técnico); ação do
   pesquisador. Nenhum dado de esforço pode ser testado antes disso.
2. **ERDDAP NOAA fora do ar** no dia do teste — contornado (NCEI/PSL OK).
3. Nenhuma outra fonte apresentou bloqueio; as marcadas "não testado"
   simplesmente ainda não foram verificadas (não presumir disponibilidade).
