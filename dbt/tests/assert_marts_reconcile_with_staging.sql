-- Витрины не теряют и не дублируют транзакции: суммарное число транзакций и фродов
-- в каждой витрине совпадает со staging
with stg as (
    select
        count() as tx,
        sum(is_fraud) as fraud
    from {{ ref('stg_transactions') }}
),

marts as (
    select
        'daily_state' as mart,
        sum(transactions_cnt) as tx,
        sum(fraud_cnt) as fraud
    from {{ ref('mart_daily_state_metrics') }}
    union all
    select
        'category',
        sum(transactions_cnt),
        sum(fraud_cnt)
    from {{ ref('mart_fraud_by_category') }}
    union all
    select
        'state',
        sum(transactions_cnt),
        sum(fraud_cnt)
    from {{ ref('mart_fraud_by_state') }}
    union all
    select
        'customer',
        sum(transactions_cnt),
        sum(fraud_cnt)
    from {{ ref('mart_customer_risk_profile') }}
    union all
    select
        'hourly',
        sum(transactions_cnt),
        sum(fraud_cnt)
    from {{ ref('mart_hourly_fraud_pattern') }}
    union all
    select
        'merchant',
        sum(transactions_cnt),
        sum(fraud_cnt)
    from {{ ref('mart_merchant_analytics') }}
)

select marts.*
from marts
cross join stg
where marts.tx != stg.tx or marts.fraud != stg.fraud
