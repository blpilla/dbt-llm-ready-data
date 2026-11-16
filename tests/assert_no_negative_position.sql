{{ config(severity='warn') }}

select
    client_id,
    client_name,
    asset_ticker,
    net_quantity,
    net_financial_value
from {{ ref('mart_client_portfolio') }}
where net_quantity < 0
