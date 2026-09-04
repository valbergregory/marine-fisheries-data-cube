# Protocolo científico

**Projeto:** Marine Fisheries Data Cube
**Versão:** 0.1 (2026-09-03) — provisório; revisar após inspeção da literatura e do piloto de viabilidade.
**Pesquisador:** Valber Gregory (Doutor em Economia; professor de Sistemas de Informação e de Economia Pesqueira).

---

## 1. Problema prático

Os dados necessários para monitorar e gerir a pesca brasileira sob mudança
climática estão fragmentados em silos incompatíveis:

- **Esforço pesqueiro:** o Brasil não possui estatística pesqueira nacional
  contínua desde a descontinuação das séries do IBAMA/MPA (última série
  nacional consistente encerrada na década de 2010). Rastreamento por
  satélite (AIS, via Global Fishing Watch) existe, mas em plataforma
  separada, com conceito próprio ("apparent fishing effort") e cobertura
  enviesada para embarcações maiores.
- **Oceanografia:** SST, anomalias e clorofila estão em NetCDF/serviços
  internacionais (NOAA, Copernicus), em grades e convenções distintas.
- **Regulação:** unidades de conservação (CNUC/ICMBio), portarias de defeso
  e restrições espaciais estão em cadastros e diários oficiais, raramente
  georreferenciados de forma analítica.
- **Território:** municípios, população, emprego e transferências (IBGE,
  RAIS/CAGED, Seguro-Defeso) usam a malha municipal, sem ponte natural com
  o espaço marinho.

Consequência: gestores e pesquisadores não conseguem responder, com
frequência alta e cobertura nacional, a perguntas básicas como "para onde o
esforço se desloca quando o mar aquece?" — o que limita alerta precoce,
adaptação climática e avaliação de políticas (defeso, UCs marinhas). A
contribuição de Sistemas de Informação é exatamente a infraestrutura que
elimina essa fragmentação de forma reproduzível e auditável.

## 2. Pergunta principal (provisória)

> **How do marine heatwaves affect the intensity and spatial distribution of
> fishing effort along the Brazilian coast?**

## 3. Perguntas secundárias

1. O esforço diminui nas células diretamente afetadas por MHW?
2. Há deslocamento (spillover positivo) para células vizinhas não afetadas?
3. As embarcações se movem para águas mais frias (gradiente térmico) e/ou
   mais distantes da costa/porto?
4. Os efeitos persistem após o término do evento (histerese) ou há
   recuperação rápida?
5. Os efeitos são heterogêneos por tipo de embarcação/arte de pesca, região
   (N/NE/SE/S), distância da costa e produtividade oceânica?
6. Áreas protegidas e restrições regulatórias (defeso) alteram a resposta
   espacial (deslocamento para dentro/fora de áreas restritas)?

## 4. Hipóteses iniciais (provisórias — revisar após literatura e piloto)

| # | Hipótese | Sinal esperado | Observável |
|---|---|---|---|
| H1 | MHW reduz o esforço na célula afetada | β_MHW < 0 em log1p(horas) | painel célula×mês |
| H2 | Parte do esforço desloca-se para células adjacentes/menos afetadas | efeito positivo em vizinhas não tratadas | anéis de vizinhança H3 |
| H3 | Efeitos maiores onde a dependência pesqueira é alta e a diversificação baixa | interação com índice municipal | ligação célula→município costeiro |
| H4 | Produtividade (clorofila) modera o efeito térmico | interação MHW×CHL | extensão condicionada |
| H5 | UCs e defeso modificam a resposta espacial | heterogeneidade por camada regulatória | extensão condicionada |

Riscos conhecidos para as hipóteses: (i) MHW pode *aumentar* capturabilidade
de algumas espécies no curto prazo (agregação em refúgios térmicos), tornando
o sinal de H1 ambíguo por arte de pesca; (ii) AIS sub-representa a frota
artesanal, então H3 é testável apenas para a frota rastreada.

## 5. Definição de onda de calor marinha

Adotamos a definição hierárquica de **Hobday et al. (2016)** — referência
metodológica original, metadados confirmados via Crossref em 2026-09-03:

> Hobday, A.J., et al. (2016). "A hierarchical approach to defining marine
> heatwaves". *Progress in Oceanography*, 141, 227–238.
> DOI: 10.1016/j.pocean.2015.12.014 (resolvido em 2026-09-03).

Parâmetros (registrados em `config/config.yml`):

- **Climatologia:** 1991–2020 (30 anos, dentro do período OISST 1981–presente);
- **Limiar:** percentil 90 da distribuição diária de SST, suavizado em
  janela de 31 dias (default do algoritmo);
- **Duração mínima:** ≥ 5 dias consecutivos acima do limiar;
- **Junção de eventos:** intervalos ≤ 2 dias entre excedências unem eventos;
- **Métricas distintas:** intensidade (média/máxima, °C acima do limiar),
  duração (dias), frequência (eventos), dias-MHW por célula-mês, e categorias
  (Moderate/Strong/Severe/Extreme, conforme extensão de Hobday et al. 2018 —
  citar somente após verificação Crossref).

Implementação: pacote **heatwaveR** (Schlegel & Smit, 2018, *JOSS*, 3(28),
821, DOI 10.21105/joss.00821 — confirmado via Crossref em 2026-09-03), que
implementa exatamente o algoritmo de Hobday et al.

**Regra:** uma anomalia positiva simples de SST **não** é MHW e não será
rotulada como tal. Sensibilidade: percentil 95, duração ≥ 10 dias e
climatologia alternativa 1982–2011 (seção Robustez).

## 6. Unidade de análise

Comparação formal pendente do piloto (ver `docs/decisions_log.md`, D2):
célula H3 (res. 4/5/6) × mês vs. semana; grade regular 0.25° × mês (nativa
do OISST) como alternativa; embarcação×mês somente se identificadores forem
legitimamente acessíveis via API GFW.

**Preferência inicial: célula espacial × mês** — compatível com a resolução
ambiental, reduz zeros excessivos e custo computacional. O piloto medirá:
% de células com esforço > 0, variância espacial/temporal, custo de
processamento por resolução.

## 7. Desenho empírico (resumo; detalhes em identification_strategy.md)

Painel espaço-temporal com efeitos fixos de célula e de período
(e tendências/sazonalidade regional), exposição contemporânea e defasada a
MHW, erros robustos à dependência espacial (Conley) e serial. Linguagem
**associacional** até que a estratégia de identificação seja defensável;
a plausibilidade causal apoia-se na exogeneidade física do choque térmico
condicional aos efeitos fixos, a ser argumentada e testada (leads/placebos).

## 8. Contribuições pretendidas

1. **Econômica:** primeira evidência de alta frequência para o Brasil sobre
   resposta do esforço pesqueiro a MHWs (intensidade + margem espacial).
2. **Sistemas de Informação:** o *Marine Fisheries Data Cube* — arquitetura
   reproduzível (Parquet + DuckDB + H3 + targets) com linhagem, checksums e
   validação, avaliada pelo tripé pessoas–processos–tecnologia.
3. **Política:** subsídios para defeso dinâmico, UCs marinhas e adaptação
   climática de comunidades costeiras.

## 9. Ética, licenças e limitações declaradas

- Dados GFW: agregados, sem identificação individual em outputs públicos;
  respeitar CC BY-SA e termos da API.
- Sub-representação da frota artesanal no AIS: limitação central, declarada
  na introdução e nas conclusões — os resultados valem para a frota rastreada.
- "Apparent fishing effort" é inferência de modelo (não esforço declarado);
  erro de medida discutido explicitamente.
- Nenhum dado restrito será versionado no Git.
