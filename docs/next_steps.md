# RETOMAR AQUI — estado e próximos passos

Atualizado em 2026-09-22. Histórico completo das decisões em
[decisions_log.md](decisions_log.md) (D1–D20); números correntes em
`outputs/tables/RESULTS_DIGEST.md`; comandos em [RUNBOOK.md](RUNBOOK.md).

## Estado: a parte técnica está fechada

| Bloco | Situação |
|---|---|
| Cubo de dados (2013–2024, 4.765 células, 686.160 células-mês) | pronto, auditado, Parquet + DuckDB |
| Modelos, dinâmica, deslocamento, heterogeneidade, robustez, placebos | estimados; 12 tabelas, 5 figuras |
| Limiares sob tendências por célula (D20) | ≥20 dias sobrevive; ≥30 dias também |
| Testes automatizados | suíte `testthat` cobrindo esquema, chaves, MHW, joins |
| Termos da API GFW | lidos: **CC BY-NC 4.0** (não BY-SA); docs e LICENSING corrigidos |
| Dashboard Shiny | `app/app.R` funcional (período, região, esforço, MHW, anomalias, exportação) |

## O que depende do pesquisador (bloqueia a submissão)

   o que sobreviver dele precisa constar da declaração de IA
   brasileiros (último boletim do MPA; história institucional do MPA; regime
   de gestão compartilhada e Decreto 6.981/2009; Lei 10.779/2003 e
   elegibilidade do Seguro-Defeso; filiação à ICCAT e portos da frota de
   espinhel; base legal e limiar do PREPS) e duas afirmações que pedem
   evidência do autor.
3. **Aprovar ou remover as 11 referências candidatas**
   (`article/references_candidates.bib`). Os DOIs foram verificados na
   Crossref, mas o autor ainda não leu os textos; a política do portfólio
4. **Escolher o título.** A clorofila saiu do escopo (D18), então
   "Ocean Productivity" no título atual não se sustenta. Alternativas no
5. **Escolher o periódico-alvo** (Marine Policy, Fisheries Research,
   Ecological Economics, ICES JMS) — eu adapto classe e bibliografia.
6. **Preencher os colchetes** de `article/data_code_availability.tex`
   (tag/commit do release, datas de acesso) e a versão do aplicativo em

## O que posso fazer quando o pesquisador quiser

- Versão de Sistemas de Informação (SBSI) com pergunta e contribuição
  distintas, sem submissão duplicada (seção 16 do protocolo).
- Publicar o dashboard (shinyapps.io ou container) respeitando o BY-NC.
- Release no GitHub com DOI (Zenodo) no dia da submissão.
