# RETOMAR AQUI — estado e próximos passos

Atualizado em 2026-10-09. Histórico completo das decisões em
[decisions_log.md](decisions_log.md) (D1–D27); números correntes em
`outputs/tables/RESULTS_DIGEST.md`; comandos em [RUNBOOK.md](RUNBOOK.md).

Desde 2026-09-23 nada mudou no projeto: nenhum arquivo foi tocado e o
`main` local está idêntico ao `origin/main` (`2ac098b`).

## Estado: a parte técnica está fechada

| Bloco | Situação |
|---|---|
| Cubo de dados (2013–2024, 4.765 células, 686.160 células-mês) | pronto, auditado, Parquet + DuckDB |
| Modelos, dinâmica, deslocamento, heterogeneidade, robustez, placebos | estimados; 12 tabelas, 5 figuras |
| Limiares sob tendências por célula (D21) | ≥20 dias sobrevive; ≥30 dias também |
| Termos da API GFW (D20) | lidos: **CC BY-NC 4.0** (não BY-SA); docs e LICENSING corrigidos |
| Testes automatizados | suíte `testthat` cobrindo esquema, chaves, MHW, joins |
| Dashboard Shiny | `app/app.R` funcional (período, região, esforço, MHW, anomalias, exportação) |
| Título (D22) | "Marine Heatwaves and Fishing Effort: High-Frequency Evidence from the Brazilian Coast" |
| Periódico-alvo (D23) | **Marine Policy**; estudo em `elsarticle`, com highlights e declarações |
| Determinismo (D24) | verificado por MD5: recomputar a cadeia de estimação reproduz as tabelas byte a byte |
| Custo computacional (D25) | medido por etapa, tempo e memória de pico — ver [cost_profile.md](cost_profile.md) |
| Regras do periódico (D26) | Guide for Authors lido: refs numeradas, duplo-cego (chave `\ifanon` + `title_page.tex`), highlights de ≤85 caracteres |
| Execução incremental (D27) | `LOGF` com timestamp invalidava a cadeia toda a cada `tar_make`; com caminho fixo, a exportação leva segundos |
| Texto-modelo do autor | `_texto-apoio-autor/` (EN, PT, bullets, versão SI) — **fora do Git**, por ser texto gerado por IA |

## O que depende do pesquisador (bloqueia a submissão)

   o que sobreviver dele precisa constar da declaração de IA
   brasileiros (último boletim do MPA; história institucional do MPA; regime
   de gestão compartilhada e Decreto 6.981/2009; Lei 10.779/2003 e
   elegibilidade do Seguro-Defeso; filiação à ICCAT e portos da frota de
   espinhel; base legal e limiar do PREPS) e duas afirmações que pedem
   evidência específica da pescaria.
3. **Aprovar ou remover as 11 referências candidatas**
   (`article/references_candidates.bib`). Os DOIs foram verificados na
   Crossref, mas o autor ainda não leu os textos; a política do portfólio
4. **Preencher o frontmatter**: afiliação, e-mail de correspondência,
   financiamento e 3–5 highlights (`article/highlights.tex`).
5. **Preencher os colchetes** de `article/data_code_availability.tex`
   (tag/commit do release, datas de acesso), a versão do aplicativo em
   e-mail, ORCID, financiamento).
6. **Cortar o resumo de 299 para ~250 palavras** (exigência do periódico). Não
   fiz o corte porque ele mexe nos cinco achados, e a escolha de qual perde
   espaço é sua.
7. **Decidir o enquadramento técnico.** O Marine Policy declara que "não é um
   periódico técnico" e pede fórmulas e detalhes de modelo em apêndice. O corpo
   tem 5.103 palavras (faixa do periódico: 4.000–6.000) e só uma equação
   numerada, então nada é desqualificante — mas a estratégia empírica é densa
   para o público dele. As opções são enxugar a §5 mandando a especificação
   para apêndice, ou manter e assumir o risco de transferência.

## O que posso fazer quando o pesquisador quiser

- **Apurar os 3 alvos que reaparecem desatualizados** (`models_r4_files`,
  `spill_r4_files`, `dashboard_data`) logo após serem construídos. Não afetam
  os números do estudo (as tabelas e o `numbers.tex` são byte a byte
  idênticos, D24), mas são alvos `format = "file"` cujos arquivos não voltam a
  gerar o mesmo hash. Causa ainda não estabelecida.
- Versão de Sistemas de Informação (SBSI) com pergunta e contribuição
  distintas, sem submissão duplicada (seção 16 do protocolo).
- Publicar o dashboard (shinyapps.io ou container) respeitando o BY-NC.
- Release no GitHub com DOI (Zenodo) no dia da submissão.
