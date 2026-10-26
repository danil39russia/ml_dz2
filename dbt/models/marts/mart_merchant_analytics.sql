with merchants as (

    select
        merchant,
        any(category) as category,
        count() as transactions_cnt,
        round(sum(amount), 2) as turnover,
        round(avg(amount), 2) as avg_check,
        sum(is_fraud) as fraud_cnt,
        {{ fraud_rate() }} as fraud_rate,
        uniqExact(customer_id) as unique_customers
    from {{ ref('stg_transactions') }}
    group by merchant

)

select
    *,
    -- подозрительный мерчант: достаточно транзакций и fraud_rate в 3+ раза выше среднего по мерчантам
    toUInt8(
        transactions_cnt >= {{ var('min_transactions_for_rate') }}
        and fraud_rate >= 3 * avg(fraud_rate) over ()
    ) as is_suspicious
from merchants
