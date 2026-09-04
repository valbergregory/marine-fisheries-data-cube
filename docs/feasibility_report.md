# Relatório de viabilidade

**Versão 0.1 — 2026-09-03 (pré-piloto).**
Este relatório tem duas partes: (A) o que já foi verificado hoje, com
requisições mínimas; (B) o desenho do piloto e as dez perguntas que ele deve
responder antes de qualquer download do universo completo.

## A. Verificações executadas em 2026-09-03

| Teste | Resultado |
|---|---|
| GFW API v3 (sem token) | HTTP **401** — serviço ativo, exige token gratuito (bloqueio administrativo, ação do pesquisador) |
| OISST v2.1 — NCEI HTTPS (arquivo diário) | HTTP **200**, ~1,5 MB/dia global, sem autenticação |
| OISST — PSL THREDDS/OPeNDAP | HTTP **200** (permite recorte espacial no servidor) |
| OISST — ERDDAP (CoastWatch/Upwell) | HTTP **000** — indisponível no dia; rebaixado a alternativa |
| IBGE (localidades + malhas v3) | **OK** (JSON válido; 200) |
| CRAN: `heatwaveR`, `rerddap`, `geobr` | disponíveis |
| CRAN: `gfwr` | **404** — instalar do GitHub oficial (GlobalFishingWatch/gfwr), pinado |
| Crossref: Hobday et al. 2016; Schlegel & Smit 2018 | metadados confirmados |
| Copernicus, ICMBio, ANTAQ, dados.gov.br, Protected Planet | portais reachable (200); downloads específicos **não testados** |

**Conclusão parcial:** o eixo ambiental (SST → MHW) é 100% viável sem
autenticação. O eixo de esforço pesqueiro depende apenas do token GFW.
Nenhum bloqueio técnico identificado até aqui.

## B. Desenho do piloto (`config/config.yml → feasibility`)

- **Região:** litoral nordestino — bbox (-38, -10.5) a (-32, -4.5)
  (RN, PB, PE, AL + ZEE próxima);
- **Período:** 2022-01 a 2023-12 (2 anos);
- **Frequência:** mensal;
- **Amostra:** ≤ 400 células (H3 res. 5; comparar 4 e 6);
- **Variáveis:** apparent fishing hours (GFW 4wings report) + SST (OISST).
- **Execução:** `scripts/02_run_feasibility.R` como Background Job, após
  token GFW configurado e dependências espaciais instaladas.

### As 10 perguntas do piloto (respostas a preencher)

| # | Pergunta | Critério de aprovação | Resposta |
|---|---|---|---|
| 1 | O dado pode ser acessado de forma reproduzível? | script roda de ponta a ponta sem intervenção manual | _pendente_ |
| 2 | A licença permite pesquisa e redistribuição dos resultados? | agregados publicáveis (CC BY-SA GFW; domínio público OISST) | _pendente (leitura dos termos da API)_ |
| 3 | Período compatível entre fontes? | interseção ≥ 8 anos utilizáveis (GFW 2012+ ∩ OISST 1981+) | _pendente_ |
| 4 | Resolução espacial permite cruzamento? | mapeamento célula↔pixel 0,25° sem ambiguidade dominante | _pendente_ |
| 5 | % de células-mês com esforço > 0? | ≥ ~25% na faixa de pesca ativa (senão, engrossar célula/período ou modelo de zeros) | _pendente_ |
| 6 | Variação espacial e temporal suficientes? | desvios dentro-célula e dentro-mês não degenerados; eventos MHW ocorrem no período | _pendente_ |
| 7 | Tempo e memória do processamento? | piloto < 30 min e < 8 GB RAM em máquina local | _pendente_ |
| 8 | Identificador de embarcação disponível? | documentar nível de agregação legítimo da API | _pendente_ |
| 9 | Cobertura representativa? | comparação qualitativa com frota conhecida da região; viés artesanal quantificado ao menos por classe de tamanho | _pendente_ |
| 10 | O conceito corresponde a esforço pesqueiro? | leitura da documentação do modelo GFW; discussão de erro de medida | _pendente_ |

### Regra de decisão

- **Continuar** (escopo pleno) se 1–7 aprovados e 8–10 documentáveis;
- **Restringir** (ex.: só frota industrial, só S/SE, só mensal) se 5, 6 ou 9
  falharem parcialmente;
- **Reformular** (outra fonte de esforço ou outro desenho) se 1, 2 ou 10
  falharem.

**Não avançar para o download completo até este relatório ser aprovado pelo
pesquisador.**
