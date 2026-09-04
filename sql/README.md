# sql/

Consultas analíticas DuckDB sobre o cubo Parquet (fase 2+).
Convenção: um arquivo `.sql` por consulta nomeada, chamado a partir de R via
`DBI::dbGetQuery(con, readr::read_file("sql/<nome>.sql"))` dentro de targets.
Nenhuma consulta deve modificar dados (somente leitura sobre Parquet).
