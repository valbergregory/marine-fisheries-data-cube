# Estratégia de identificação (v0.1 — 2026-09-03)

**Postura:** linguagem associacional até que a identificação seja
defensável. O que segue é o argumento a ser construído e testado, não uma
afirmação de causalidade.

## Modelo principal (associacional, painel)

Para célula *i*, mês *t*:

```
log1p(effort_it) = Σ_k β_k · MHW_{i,t-k} + X_it'γ + α_i + δ_t + (região×mês do ano) + ε_it
```

- `MHW_{i,t-k}`: exposição (dias-MHW ou indicador; k = 0..K defasagens);
- `X_it`: controles ambientais variantes (SST média, anomalia não-MHW; CHL se viável);
- `α_i`: efeito fixo de célula (absorve profundidade, distância à costa,
  produtividade média, portos, regulação constante);
- `δ_t`: efeito fixo de período (absorve preços nacionais de combustível,
  demanda agregada, feriados, choques macro);
- sazonalidade regional: região×mês-do-ano ou tendências regionais;
- **Erros:** Conley (dependência espacial, cutoff a escolher por variograma)
  + cluster temporal; comparar com cluster duplo célula/tempo. Implementação
  em `fixest` (vcov = conley) — validar opções na versão instalada.

## Fonte de variação e ameaças

**Argumento de exogeneidade condicional:** o momento e a localização exata
de uma MHW, condicionais a efeitos fixos de célula e sazonalidade regional,
são determinados por dinâmica oceânico-atmosférica plausivelmente não
correlacionada com choques idiossincráticos de demanda/custo da célula.

Ameaças a levar a sério (e testes correspondentes):

| Ameaça | Teste/mitigação |
|---|---|
| MHW correlacionada a padrões climáticos amplos (ENSO) que afetam pesca por outros canais (chuva, portos, demanda) | controles δ_t + região×tempo; robustez controlando índices ENSO interagidos com região |
| Antecipação (previsões de MHW alteram esforço antes do evento) | leads como teste de placebo/predição |
| Erro de medida no esforço (AIS desligado durante eventos?) | outcome de presença/contagem de embarcações; discussão de gaps de AIS |
| Deslocamento contamina o "controle" (SUTVA espacial violada) | estimar spillovers explicitamente (anéis de vizinhança); interpretar β como efeito líquido local |
| Zeros excessivos | modelo em duas partes (extensiva/intensiva); PPML (`fixest::fepois`) como robustez a log1p |

## Margem espacial (deslocamento)

- Exposição da vizinhança: dias-MHW médios nos anéis H3 k=1, k=2 (excluindo
  a própria célula), entrando junto com a exposição própria;
- Outcomes de realocação: distância média do esforço à costa/porto,
  centro de massa do esforço, concentração (Gini/HHI espacial por região),
  entrada/saída de células (extensiva).

## Dinâmica

Defasagens distribuídas (K ≥ 6 meses) e, se o suporte amostral permitir,
DLNM (`dlnm`) para não-linearidade intensidade×defasagem. Reportar:
antecipação (leads), impacto, persistência, recuperação.

## O que NÃO faremos sem justificativa científica

IV, causal forests, DML, modelos espaciais dinâmicos — só se resolverem um
problema identificado (e com suporte amostral). Modelos SAR/SEM (`spatialreg`)
entram apenas como caracterização da dependência espacial residual, não como
estratégia de identificação.
