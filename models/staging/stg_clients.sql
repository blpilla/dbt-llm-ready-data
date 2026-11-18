with typed as (
    select
        nullif(trim(cast(client_id as varchar)), '') as client_id,
        nullif(trim(cast(name as varchar)), '') as name,
        nullif(trim(cast(city as varchar)), '') as city,
        upper(nullif(trim(cast(state as varchar)), '')) as state,
        try_cast(nullif(trim(cast(created_at as varchar)), '') as date) as created_at
    from {{ ref('clients') }}
),

filtered as (
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
    from typed
    where client_id is not null
      and name is not null
      and state is not null
      and created_at is not null
)

select
    client_id,
    name,
    city,
    state,
    created_at
from filtered
where record_rank = 1
