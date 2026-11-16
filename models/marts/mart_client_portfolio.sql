select
    client_id,
    client_name,
    asset_ticker,
    sum(quantity * {{ transaction_sign('operation') }}) as net_quantity,
    cast(sum(quantity * unit_price * {{ transaction_sign('operation') }}) as decimal(18, 4)) as net_financial_value,
    min(transaction_date) as first_transaction_date,
    max(transaction_date) as last_transaction_date,
    count(*) as transaction_count
from {{ ref('fact_transactions') }}
group by
    client_id,
    client_name,
    asset_ticker
