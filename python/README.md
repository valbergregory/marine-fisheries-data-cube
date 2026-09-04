# python/

Vazio por decisão (D9, `docs/decisions_log.md`): arquitetura R-first.

Único caso de uso previsto até agora: toolbox `copernicusmarine` para
clorofila (extensão condicionada à viabilidade). Se ativado:

```bash
# Terminal, na raiz do projeto (Python 3.13 detectado no sistema)
python -m venv python/.venv
python/.venv/Scripts/pip install copernicusmarine
```

Comunicação com o pipeline R: scripts Python gravam NetCDF/Parquet em
`data/interim/`, e um target de `_targets.R` os consome via
`tarchetypes::tar_file()` — nunca objetos em memória compartilhados.
Credenciais via variáveis de ambiente (nunca em código).
