with source as (

    select * from {{ source('transactions_db', 'transactions') }}

),

renamed as (

    select
        toDateTime(transaction_time) as transaction_time,
        toDate(transaction_time) as transaction_date,
        toHour(transaction_time) as transaction_hour,
        {{ dbt_date.day_of_week('transaction_time', isoweek=true) }} as day_of_week,
        replaceRegexpOne(trim(merch), '^fraud_', '') as merchant,
        lower(trim(cat_id)) as category,
        round(toFloat64(amount), 2) as amount,
        trim(name_1) as first_name,
        trim(name_2) as last_name,
        upper(trim(gender)) as gender,
        trim(street) as street,
        trim(one_city) as city,
        upper(trim(us_state)) as state,
        toString(post_code) as post_code,
        toFloat64(lat) as customer_lat,
        toFloat64(lon) as customer_lon,
        toUInt32(population_city) as city_population,
        trim(jobs) as job,
        toFloat64(merchant_lat) as merchant_lat,
        toFloat64(merchant_lon) as merchant_lon,
        toUInt8(target) as is_fraud
    from source
    where amount > 0

),

enriched as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'transaction_time', 'merchant', 'category', 'amount',
            'first_name', 'last_name', 'street', 'post_code'
        ]) }} as transaction_id,
        {{ dbt_utils.generate_surrogate_key(['first_name', 'last_name', 'street', 'post_code']) }} as customer_id,
        *,
        {{ amount_bucket('amount') }} as amount_bucket,
        toUInt8(amount >= {{ var('large_amount_threshold') }}) as is_large_amount,
        round(geoDistance(customer_lon, customer_lat, merchant_lon, merchant_lat) / 1000, 2) as distance_km
    from renamed

)

-- в сырых данных встречаются полные дубли строк: оставляем по одной транзакции
select * from enriched
limit 1 by transaction_id
