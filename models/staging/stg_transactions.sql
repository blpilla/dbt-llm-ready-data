with typed as (
    select
        nullif(trim(cast(transaction_id as varchar)), '') as transaction_id,
        nullif(trim(cast(client_id as varchar)), '') as client_id,
        upper(nullif(trim(cast(asset_ticker as varchar)), '')) as asset_ticker,
        upper(nullif(trim(cast(operation as varchar)), '')) as operation,
        try_cast(nullif(trim(cast(quantity as varchar)), '') as integer) as quantity,
        try_cast(nullif(trim(cast(unit_price as varchar)), '') as decimal(18, 4)) as unit_price,
        try_cast(nullif(trim(cast(transaction_date as varchar)), '') as date) as transaction_date
    from {{ ref('transactions') }}
)

select
    transaction_id,
    client_id,
    asset_ticker,
    operation,
    quantity,
    unit_price,
    transaction_date
from typed
where transaction_id is not null
  and client_id is not null
  and asset_ticker is not null
  and operation in ('BUY', 'SELL')
  and quantity > 0
  and unit_price > 0
  and transaction_date is not null
