# Termos de uso da API da Global Fishing Watch — leitura de 2026-09-22

Pendência aberta em D14 ("ler ToS da API GFW antes de publicar agregados").
Fontes lidas em 2026-09-22:

- <https://globalfishingwatch.org/our-apis/documentation/docs/license-rate-limits>
- <https://globalfishingwatch.org/our-apis/terms-of-use>

## O que vale para este projeto

| Ponto | Termo | Consequência aqui |
|---|---|---|
| Licença dos dados via API | **CC BY-NC 4.0** (não CC BY-SA 4.0, como constava antes nos docs — a BY-SA vale para downloads avulsos do site, não para a API 4Wings v3 que usamos) | Todo agregado derivado (painel Parquet, dashboard, tabelas por célula) herda BY-NC |
| Uso | Somente não comercial; uso comercial exige contato com a GFW | Artigo, repositório público e Shiny acadêmico: ok. Qualquer uso comercial futuro do cubo: pedir autorização |
| Obras derivadas | Remix permitido com atribuição e **redistribuição nos mesmos termos BY-NC** | Cubo liberado com o artigo deve sair sob CC BY-NC 4.0 (não MIT, não CC BY) |
| Atribuição (bibliografia) | "Copyright [ano], Global Fishing Watch, Inc., https://globalfishingwatch.org/our-apis/" (+ data de acesso) | Entrar no `references.bib` e na declaração de disponibilidade |
| Atribuição (site/gráfico/app) | "Powered by Global Fishing Watch" com link para globalfishingwatch.org, ou citação completa (ano, dataset, versão, período, URL) | Rodapé obrigatório no Shiny (R/18) e nas figuras publicadas fora do artigo |
| Natureza do dado | Atividade de pesca é "aparente", sem garantia de exatidão | Manter "apparent fishing effort" no texto (já é o caso) |
| Token | Pessoal, não pode ser compartilhado nem publicado | Já em `.Renviron` fora do Git; nunca em logs |
| Limites | 50 mil requisições/dia; 1,5 mi/mês; 429 ao exceder (bloqueio de 24 h / 30 dias) | Download anual em lote está muito abaixo |

## Correções feitas no repositório

`config/data_sources.yml`, `docs/data_inventory.md`, `docs/feasibility_report.md`
(nota), `docs/reproducibility_guide.md`, `docs/research_protocol.md`,
`LICENSING.md` e `article/data_code_availability.tex` passaram de
"CC BY-SA 4.0" para "CC BY-NC 4.0 (API)".

## Decisão pendente do autor

Licença dos agregados liberados com o artigo: a opção compatível é
**CC BY-NC 4.0**. O colchete em `article/data_code_availability.tex` foi
mantido para ele confirmar.
