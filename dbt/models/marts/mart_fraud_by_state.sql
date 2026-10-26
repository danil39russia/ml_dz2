select
    t.state,
    any(s.state_name) as state_name,
    any(s.region) as region,
    count() as transactions_cnt,
    sum(t.is_fraud) as fraud_cnt,
    {{ fraud_rate('t.is_fraud') }} as fraud_rate,
    uniqExact(t.customer_id) as unique_customers,
    uniqExact(t.merchant) as unique_merchants,
    round(sum(t.amount), 2) as total_amount,
    round(sumIf(t.amount, t.is_fraud = 1), 2) as fraud_amount
from {{ ref('stg_transactions') }} as t
left join {{ ref('states') }} as s on t.state = s.state_code
group by t.state
