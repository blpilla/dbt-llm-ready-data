with joined as (
    select
        t.transaction_id,
        t.client_id,
        c.name as client_name,
        c.city,
        c.state,
        t.asset_ticker,
        t.operation,
        t.quantity,
        t.unit_price,
        t.transaction_date,
        {{ transaction_sign('t.operation') }} as operation_sign
    from {{ ref('stg_transactions') }} as t
    inner join {{ ref('dim_clients') }} as c
        on t.client_id = c.client_id
)

select
    transaction_id,
    client_id,
    client_name,
    city,
    state,
    asset_ticker,
    operation,
    operation_sign,
    quantity,
    unit_price,
    cast(quantity * unit_price as decimal(18, 4)) as gross_value,
    quantity * operation_sign as signed_quantity,
    cast(quantity * unit_price * operation_sign as decimal(18, 4)) as signed_value,
    transaction_date
from joined
