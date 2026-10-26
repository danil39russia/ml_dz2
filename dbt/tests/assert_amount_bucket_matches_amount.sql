-- Сегмент суммы, посчитанный макросом amount_bucket, согласован с самой суммой
select
    transaction_id,
    amount,
    amount_bucket
from {{ ref('stg_transactions') }}
where
    (amount_bucket = 'micro' and amount >= 10)
    or (amount_bucket = 'huge' and amount < {{ var('large_amount_threshold') }})
    or (amount_bucket != 'huge' and amount >= {{ var('large_amount_threshold') }})
