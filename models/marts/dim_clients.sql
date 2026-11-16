with ranked_clients as (
    select
        client_id,
        name,
        city,
        state,
        created_at,
        row_number() over (
            partition by client_id
            order by
                case when city is not null then 1 else 0 end desc,
                created_at desc,
                name
        ) as record_rank
    from {{ ref('stg_clients') }}
)

select
    client_id,
    name,
    city,
    state,
    created_at
from ranked_clients
where record_rank = 1
