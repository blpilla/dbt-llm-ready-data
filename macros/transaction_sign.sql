{% macro transaction_sign(operation_column) -%}
case
    when upper(trim(cast({{ operation_column }} as varchar))) = 'BUY' then 1
    when upper(trim(cast({{ operation_column }} as varchar))) = 'SELL' then -1
    else 0
end
{%- endmacro %}
