# Projeto dbt de transações

Projeto local em dbt que transforma arquivos brutos de clientes e transações em modelos analíticos documentados.

## Pré-requisitos

- Python 3.10 ou superior;
- `dbt-core` e `dbt-duckdb` instalados;
- execução a partir da raiz do projeto.

Instale o adaptador com:

```bash
python -m pip install -r requirements.txt
```

O arquivo `profiles.yml` usa DuckDB e cria `teste_valor.duckdb` localmente. Como o dbt procura perfis em `~/.dbt` por padrão, os comandos abaixo usam `--profiles-dir .`.

## Execução

```bash
dbt seed --profiles-dir . --full-refresh
dbt run --profiles-dir .
dbt test --profiles-dir .
```

Também é possível definir `DBT_PROFILES_DIR=.` e executar os comandos sem repetir a opção.

O teste `assert_no_negative_position` está configurado com severidade `warn`: ele retorna as posições negativas encontradas como aviso e permite que `dbt test` termine com código de sucesso. Para tratar o aviso como falha, use `dbt test --profiles-dir . --warn-error`.

## Camadas

```text
seeds/clients.csv              fonte bruta de clientes
seeds/transactions.csv         fonte bruta de transações
        |
models/staging/                tipagem, normalização e filtros
        |
models/intermediate/           join com clientes e métricas assinadas
        |
models/marts/                  dimensão, fato incremental e carteira
```

- `stg_clients` normaliza os campos do cadastro e mantém a cidade ausente para que a qualidade da origem continue observável.
- `stg_transactions` converte tipos e elimina linhas sem chaves, com operação desconhecida, quantidade não positiva, preço não positivo ou data inválida.
- `dim_clients` resolve cadastros duplicados de forma determinística, priorizando o registro com mais atributos preenchidos.
- `int_transactions` associa transações aos clientes e calcula quantidade e valor com sinal: `BUY = 1` e `SELL = -1`.
- `fact_transactions` é incremental, usa `transaction_id` como chave única e usa a maior `transaction_date` carregada como controle. A data máxima é incluída novamente para capturar novas operações do mesmo dia.
- `mart_client_portfolio` agrupa por cliente e ativo e calcula quantidade líquida e valor financeiro líquido.

O valor financeiro da carteira é o fluxo assinado das operações; ele não representa uma marcação a mercado.

## Qualidade dos dados

Os CSVs em `seeds/` contêm problemas intencionais. O conjunto inclui clientes duplicados, cidade ausente, transação sem cliente, quantidade negativa e uma venda que gera posição líquida negativa. Os testes das seeds e os testes singulares usam `warn` para evidenciar problemas da origem sem impedir a construção dos modelos; os modelos tratados têm testes de `not_null`, `unique`, `accepted_values`, relacionamentos e granularidade cliente/ativo.

O registro com quantidade negativa e a transação sem cliente são excluídos no staging. A quantidade negativa é reportada por `assert_positive_transaction_quantity`; a posição negativa permanece nos marts para ser identificada por `assert_no_negative_position`.

## Incremental e reprocessamento

Para alterações retroativas anteriores à maior data já carregada, execute:

```bash
dbt run --profiles-dir . --full-refresh --select fact_transactions mart_client_portfolio
```

O reprocessamento também é recomendado quando a regra de negócio ou a estrutura das colunas mudar.

## Arquivos principais

- `dbt_project.yml`: configuração do projeto, materializações e tipos das seeds;
- `profiles.yml`: conexão local DuckDB;
- `requirements.txt`: dependência do adaptador DuckDB;
- `models/schema.yml`: documentação e testes;
- `macros/transaction_sign.sql`: macro reutilizável para o sinal da operação;
- `tests/assert_positive_transaction_quantity.sql`: alerta para quantidade de origem não positiva;
- `tests/assert_no_negative_position.sql`: teste singular obrigatório.

