with customers as (

    select
        customer_id,
        any(first_name) as first_name,
        any(last_name) as last_name,
        any(gender) as gender,
        any(state) as state,
        any(city) as city,
        min(transaction_time) as first_transaction_at,
        max(transaction_time) as last_transaction_at,
        count() as transactions_cnt,
        sum(is_fraud) as fraud_cnt,
        {{ fraud_rate() }} as fraud_rate,
        round(avg(amount), 2) as avg_check,
        round(sum(amount), 2) as total_amount,
        round(avg(distance_km), 2) as avg_distance_km
    from {{ ref('stg_transactions') }}
    group by customer_id

)

select
    *,
    multiIf(
        fraud_cnt >= 3 or fraud_rate >= 10, 'HIGH',
        fraud_cnt >= 1, 'MEDIUM',
        'LOW'
    ) as risk_segment
from customers
