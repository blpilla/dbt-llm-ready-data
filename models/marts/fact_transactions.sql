{{ config(
    materialized='incremental',
    unique_key='transaction_id',
    incremental_strategy='delete+insert',
    on_schema_change='sync_all_columns'
) }}

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
    gross_value,
    signed_quantity,
    signed_value,
    transaction_date
from {{ ref('int_transactions') }}
{% if is_incremental() %}
where transaction_date >= (
    select coalesce(max(transaction_date), cast('1900-01-01' as date))
    from {{ this }}
)
{% endif %}
