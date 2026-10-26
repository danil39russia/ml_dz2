with by_slot as (

    select
        day_of_week,
        transaction_hour,
        count() as transactions_cnt,
        sum(is_fraud) as fraud_cnt,
        {{ fraud_rate() }} as fraud_rate,
        round(sumIf(amount, is_fraud = 1), 2) as fraud_amount
    from {{ ref('stg_transactions') }}
    group by day_of_week, transaction_hour

)

select
    *,
    round(fraud_rate / nullIf(avg(fraud_rate) over (), 0), 2) as fraud_rate_vs_avg,
    -- окно повышенного риска: fraud_rate минимум вдвое выше среднего по всем слотам
    toUInt8(fraud_rate >= 2 * avg(fraud_rate) over ()) as is_high_risk_window
from by_slot
