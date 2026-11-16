{{ config(severity='warn') }}

select
    transaction_id,
    client_id,
    quantity,
    transaction_date
from {{ ref('transactions') }}
where quantity is null
   or quantity <= 0
