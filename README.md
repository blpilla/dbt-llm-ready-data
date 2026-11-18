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

## Execução Rápida (3 comandos)

Na raiz do projeto, execute:

```bash
dbt seed
dbt run
dbt test
```

*(Caso você possua um `~/.dbt/profiles.yml` global e queira forçar o perfil local do projeto, adicione `--profiles-dir .` ou `export DBT_PROFILES_DIR=.`).*

O teste singular obrigatório `assert_no_negative_position` está configurado com severidade `warn`: ele sinaliza no terminal as 6 posições líquidas negativas encontradas nos dados e permite que `dbt run && dbt test` finalize com código de saída `0` (sucesso). Para transformar avisos em falha bloqueante de CI/CD, utilize `dbt test --warn-error`.

## Arquitetura em 3 Camadas (DAG)

```text
seeds/clients.csv              fonte bruta de clientes (27 linhas)
seeds/transactions.csv         fonte bruta de transações (100 linhas)
        |
models/staging/                limpeza, tipagem, deduplicação e filtro de inválidos
  ├── stg_clients.sql          (25 clientes únicos válidos)
  └── stg_transactions.sql     (98 transações válidas)
        |
models/intermediate/           joins entre stagings e regras de negócio (macro de sinal)
  └── int_transactions.sql     (98 transações enriquecidas com métricas assinadas)
        |
models/marts/                  camada analítica final (Star Schema + Mart de Carteira)
  ├── dim_clients.sql          (dimensão de clientes: 25 clientes)
  ├── fact_transactions.sql    (tabela fato incremental por transaction_date: 98 transações)
  └── mart_client_portfolio.sql(posição líquida atual por cliente/ativo: 55 posições)
```

- `stg_clients` padroniza tipos/strings e deduplica cadastros repetidos (`C1` e `C6`) de forma determinística via Window Function (`ROW_NUMBER`), priorizando o cadastro completo (com `city` preenchida) e mais recente.
- `stg_transactions` converte tipos e filtra registros estruturalmente inválidos da fonte: transação órfã sem `client_id` (`T021`) e transação com `quantity <= 0` (`T037`).
- `int_transactions` realiza o join exclusivamente na camada de staging (`stg_transactions` + `stg_clients`) e aplica a macro `transaction_sign` (`BUY = +1`, `SELL = -1`) para quantidade e valor financeiro.
- `dim_clients` materializa a dimensão final de clientes na camada `marts`.
- `fact_transactions` é materializada como `incremental` (`unique_key='transaction_id'`, estratégia `delete+insert`), usando `transaction_date` como chave de controle (`>= max(transaction_date)`) para garantir idempotência em reprocessamentos do mesmo dia.
- `mart_client_portfolio` consolida a posição líquida (`net_quantity` e `net_financial_value`) de cada cliente por ativo (`BUY - SELL`).

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

