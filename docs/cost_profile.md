# Perfil de custo computacional

Medido em 2026-10-09 com `scripts/95_measure_cost.R` (lógica) e
`scripts/95_measure_cost.ps1` (invólucro que lê o pico de memória do SO).
Fecha a afirmação de custo que estava marcada `[CONFERIR]` no resumo da versão
de Sistemas de Informação. Decisão correspondente: **D25**.

## Máquina

Windows 11, 20 núcleos lógicos, R 4.4.3 (x86_64-w64-mingw32). Execução
sequencial: o pipeline não usa paralelismo (`crew`/`future`), de modo que os
tempos abaixo são de um núcleo.

## Como o pico de memória foi obtido

Pela árvore de processos, com `Win32_Process.PeakWorkingSetSize` amostrado a
cada 500 ms. Dois detalhes que, ignorados, invalidariam a medida — e que
invalidaram a minha primeira tentativa:

1. `Rscript.exe` é só um lançador: ele executa o processo de trabalho como
   **filho**. Medir apenas o processo devolvido por `Start-Process` dá ~10 MB,
   não o pico real.
2. O objeto `Process` do .NET mantém valores em cache, e `Refresh()` não
   atualiza `PeakWorkingSet64` de forma confiável.

O valor reportado é o do processo dominante; a soma da árvore acrescenta ~24 MB
do lançador e do `cmd.exe`.

## Ingestão (medida por unidade e extrapolada)

O universo tem **12.005 pixels** OISST e **34 anos** de recortes anuais.

| Etapa | Medido | Base | Total implicado |
|---|---|---|---|
| Download dos globais (PSL) | 10,8 MB/s (requisição de intervalo de 64 MB) | 19,1 GB em disco | **~30 min** |
| Recorte de um ano (arquivo global já local) | 6,4 s | 34 anos | **~3,6 min** |
| Montagem do cubo (lê os 34 recortes e empilha) | 5,4 s | — | **5,4 s** |
| Detecção de MHW (Hobday) de um bloco de 250 pixels | 80,2 s | 49 blocos | **~65 min por definição** |
| Idem, quatro definições (principal + 3 de robustez) | — | 4 × 49 blocos | **~4,4 h** |

**Pico de memória da ingestão: 2.479 MB** (heap do R no mesmo instante:
2.404 MB — as duas medidas independentes concordam).

Os totais de download, recorte e MHW são **extrapolações declaradas**: uma
unidade foi cronometrada e multiplicada pelo número de unidades. Não são o
relógio de parede de uma execução do zero, que nunca foi registrado porque a
série foi construída em etapas ao longo de vários dias, com checkpoints por
bloco. A extrapolação do MHW é consistente com o custo observado em setembro,
quando uma interrupção custou cerca de 4,5 h de reprocessamento das quatro
definições.

## Cadeia analítica (medida de ponta a ponta)

Invalidados e recomputados os alvos de estimação, tabelas e exportação; o
`targets` arrastou junto a cadeia desde as grades e os painéis, de modo que a

| Medida | Valor |
|---|---|
| Relógio de parede | **1.074 s = 17,8 min** |
| Soma do tempo de comando dos alvos | 461 s = 7,7 min |
| **Pico de memória** | **14.580 MB (14,2 GB)** |
| Objetos de alvo gravados | 11,6 GB |
| Maior objeto isolado (`rob_files`) | 1.830 MB |

Dois fatos que o número agregado esconde:

1. **A diferença entre 17,8 min e 7,7 min é entrada e saída**, não cálculo. O
   `targets` grava 11,6 GB de objetos intermediários; os alvos mais caros em
   relógio são os de *escrita* (`rob_files` 94 s, `het_files` 34 s,
   `models_r4_files` 31 s), não os de estimação.
2. **O pico de 14,2 GB é o requisito real de hardware.** Vem dos objetos
   `fixest` com matriz de covariância de Conley sobre 686.160 observações,
   mantidos simultaneamente em memória: um único alvo de robustez ocupa
   1,8 GB em disco. Uma máquina de 8 GB não executa esta cadeia.

Alvos mais caros em tempo de comando:

| Alvo | s | MB |
|---|---|---|
| `rob_files` | 94,3 | 1.830 |
| `placebos` (50 permutações) | 84,4 | 127 |
| `het_files` | 34,1 | 728 |
| `models_r4_files` | 31,1 | 617 |
| `thresholds` | 22,5 | 1.043 |
| `dyn_r4_files` | 19,6 | 468 |
| `rob_main` | 16,5 | 1.272 |

## O que esta medição revelou de quebra (D27)

Medir o custo expôs a causa de um incômodo registrado em 22/09 como "o
pipeline reestima tudo a cada `tar_make`". Não eram os downloads: `LOGF`, o
objeto global com o caminho do log, trazia um **timestamp até o segundo no
nome do arquivo** e era recalculado a cada definição do pipeline. Dezenas de
alvos recebem `LOGF` no comando, o `targets` trata o objeto global como
dependência, e o hash mudava a cada execução — de modo que toda chamada
reconstruía a cadeia inteira, anulando justamente a execução incremental que
é a razão de ser do `targets`. Com o caminho fixo (D27), os 17,8 min passam a
ser o custo de uma **reconstrução completa**, não o pedágio de qualquer
`tar_make`.

## Resumo para citar no texto

Ingestão: ~30 min de download, ~4 min de recorte, ~4,4 h de detecção de MHW
nas quatro definições, pico de 2,5 GB. Análise: 17,8 min, pico de 14,2 GB.
Ou seja, **cerca de 5 h de máquina para reconstruir tudo do zero**, das quais
quase 90% são a detecção de ondas de calor pixel a pixel — a etapa que os
checkpoints por bloco protegem de interrupções.

## Por que o metadado do `targets` não responde sozinho

Somar a coluna `seconds` de `_targets/meta/meta` dá ~356 s, e seria errado
chamar isso de "custo do pipeline": os alvos de ingestão aparecem baratos
(`oisst_crop_files` 4,3 s, `mhw_px` 7,4 s) porque leem o cache de recortes e os
checkpoints de bloco. O metadado mede o **último** caminho percorrido, não o
caminho do zero. É exatamente por isso que as etapas pesadas foram medidas
por unidade, acima.

## Reprodutibilidade das medidas

```powershell
powershell -File scripts/95_measure_cost.ps1 -Stage netio
powershell -File scripts/95_measure_cost.ps1 -Stage ingest
powershell -File scripts/95_measure_cost.ps1 -Stage analysis
```

Cada execução grava dois arquivos em `outputs/logs/`: `cost_<etapa>_*.json`
(tempos por etapa, medidos pelo R) e `cost_<etapa>_*.peak.json` (pico de
memória por processo, medido pelo SO).
