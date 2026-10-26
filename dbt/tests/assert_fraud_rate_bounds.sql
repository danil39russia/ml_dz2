-- fraud_rate во всех витринах — процент, должен лежать в [0, 100]
select
    'category' as mart,
    category as entity,
    fraud_rate
from {{ ref('mart_fraud_by_category') }}
where fraud_rate < 0 or fraud_rate > 100

union all

select
    'state',
    state,
    fraud_rate
from {{ ref('mart_fraud_by_state') }}
where fraud_rate < 0 or fraud_rate > 100

union all

select
    'merchant',
    merchant,
    fraud_rate
from {{ ref('mart_merchant_analytics') }}
where fraud_rate < 0 or fraud_rate > 100
