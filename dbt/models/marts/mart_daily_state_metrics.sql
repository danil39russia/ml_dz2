select
    t.transaction_date,
    t.state,
    s.state_name,
    s.region,
    count() as transactions_cnt,
    round(sum(t.amount), 2) as total_amount,
    round(avg(t.amount), 2) as avg_check,
    round(quantile(0.95)(t.amount), 2) as p95_amount,
    round(100.0 * avg(t.is_large_amount), 2) as large_tx_share_pct,
    sum(t.is_fraud) as fraud_cnt
from {{ ref('stg_transactions') }} as t
left join {{ ref('states') }} as s on t.state = s.state_code
group by t.transaction_date, t.state, s.state_name, s.region
