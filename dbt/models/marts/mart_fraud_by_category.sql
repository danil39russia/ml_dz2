select
    category,
    count() as transactions_cnt,
    sum(is_fraud) as fraud_cnt,
    {{ fraud_rate() }} as fraud_rate,
    round(sum(amount), 2) as total_amount,
    round(sumIf(amount, is_fraud = 1), 2) as fraud_amount,
    round(avgIf(amount, is_fraud = 1), 2) as avg_fraud_amount,
    rank() over (order by {{ fraud_rate() }} desc) as fraud_rate_rank
from {{ ref('stg_transactions') }}
group by category
