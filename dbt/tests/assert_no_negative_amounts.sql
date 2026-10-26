-- В staging не должно быть транзакций с неположительной суммой
select *
from {{ ref('stg_transactions') }}
where amount <= 0
