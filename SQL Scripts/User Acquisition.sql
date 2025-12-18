/*

Google Analytics E-Commerce Analysis
  Section B: User Acquisition

---------------------------------------------------------------------------

1B. Traffic Source Value

Utilization: 1.04 GB

---------------------------------------------------------------------------
*/


WITH user_data AS (
  SELECT
    user_pseudo_id,
    traffic_source.source AS source,
    traffic_source.medium AS medium,
    SUM(ecommerce.purchase_revenue_in_usd) AS user_revenue,
    MAX(
			CASE WHEN event_name = 'purchase' THEN 1 ELSE 0 END
		) AS purchase_flag,
		SUM(ep.value.int_value) / 1000 AS total_engagement_time_sec,
		TIMESTAMP_DIFF(
			TIMESTAMP_MICROS(MIN(CASE WHEN event_name = 'purchase' THEN event_timestamp END)),
    	TIMESTAMP_MICROS(MIN(event_timestamp)),
    	DAY
		) AS session_to_purchase_days
  FROM
	  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
	  UNNEST(event_params) AS ep
  WHERE 
    traffic_source.source NOT IN (
			'(data deleted)', -- omitting obfuscated data
			'shop.googlemerchandisestore.com' -- omitting self-referral traffic
		)
    AND traffic_source.medium != '(data deleted)'
		AND ep.key = 'engagement_time_msec'
  GROUP BY user_pseudo_id, source, medium
)

SELECT
  source,
  medium,
  COUNT(DISTINCT user_pseudo_id) AS users,
  ROUND((SUM(purchase_flag) / COUNT(DISTINCT user_pseudo_id)) * 100.0, 1) AS purchase_rate_pct,
  SUM(user_revenue) AS total_revenue,
  ROUND(AVG(NULLIF(user_revenue, 0)), 2) AS avg_ltv_per_purchaser,
  ROUND(AVG(total_engagement_time_sec), 2) AS avg_engagement_time_sec,
  ROUND(AVG(session_to_purchase_days), 1) AS avg_days_to_first_purchase
FROM user_data
GROUP BY source, medium
HAVING COUNT(DISTINCT user_pseudo_id) >= 50
ORDER BY users DESC, purchase_rate_pct DESC;

/*
---------------------------------------------------------------------------

2B. New User Growth Rate (Week over Week)

Utilization: 179.27 MB

---------------------------------------------------------------------------
*/

WITH weekly_data AS (
    SELECT
        traffic_source.source AS source,
        traffic_source.medium AS medium,
        DATE_TRUNC(PARSE_DATE('%Y%m%d', event_date), WEEK(SUNDAY)) AS week,
        COUNTIF(event_name = 'first_visit') AS new_users,
        COUNTIF(event_name = 'purchase') AS purchases,
        IFNULL(SUM(ecommerce.purchase_revenue_in_usd), 0) AS total_revenue
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
    WHERE 
        traffic_source.source NOT IN (
            '(data deleted)',
            'shop.googlemerchandisestore.com'
        )
        AND traffic_source.medium != '(data deleted)'
    GROUP BY week, source, medium	
)

SELECT
    week,
    source,
    medium,
    new_users,
    ROUND(SAFE_DIVIDE(
        new_users - LAG(new_users) OVER (PARTITION BY source, medium ORDER BY week),
        LAG(new_users) OVER (PARTITION BY source, medium ORDER BY week)
    ) * 100.0, 1) AS new_users_wow_growth_pct,
    purchases,
    ROUND(SAFE_DIVIDE(purchases, new_users) * 100.0, 1) AS purchase_rate_pct,
    ROUND(SAFE_DIVIDE(total_revenue, purchases), 2) AS avg_order_value,
		total_revenue
FROM weekly_data
ORDER BY week, source, medium;

/*
---------------------------------------------------------------------------

3B. Traffic Source Performance by Device

Utilization: 258.16 MB

---------------------------------------------------------------------------
*/

SELECT
	traffic_source.source AS source,
  traffic_source.medium AS medium,
  device.category AS device,
  COUNT(DISTINCT user_pseudo_id) AS users,
  COUNTIF(event_name = 'purchase') AS purchases,
  ROUND(
    COUNTIF(event_name = 'purchase') / COUNT(DISTINCT user_pseudo_id) * 100.0, 
    1
  ) AS purchase_rate_pct,
  IFNULL(SUM(ecommerce.purchase_revenue_in_usd), 0) AS total_revenue,
  ROUND(
    IFNULL(SUM(ecommerce.purchase_revenue_in_usd), 0) / NULLIF(COUNTIF(event_name = 'purchase'), 0), 
    2
  ) AS avg_order_value
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE 
    traffic_source.source NOT IN (
      '(data deleted)',
      'shop.googlemerchandisestore.com'
    )
    AND traffic_source.medium != '(data deleted)'
GROUP BY source, medium, device
HAVING users >= 50
ORDER BY source, medium, users DESC;
---------------------------------------------------------------------------