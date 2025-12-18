/*

Google Analytics E-Commerce Analysis
  Section D: Sales & Revenue Performance

---------------------------------------------------------------------------

1D. Top Products by Revenue

Utilization: 237.65 MB

---------------------------------------------------------------------------
*/

SELECT
	items.item_name,
	items.item_category,
	COUNT(*) AS quantity_sold,
	SUM(item_revenue_in_usd) AS total_revenue,
	ROUND(AVG(items.item_revenue_in_usd), 2) AS avg_price
FROM
	`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
	UNNEST(items) AS items
WHERE
	event_name = 'purchase'
GROUP BY items.item_name, items.item_category
ORDER BY total_revenue DESC
LIMIT 50;

/*
---------------------------------------------------------------------------

2D. Revenue over Time & Week over Week Growth

Utilization: 94.45 MB

---------------------------------------------------------------------------
*/

WITH weekly_data AS (
	SELECT
		DATE_TRUNC(PARSE_DATE('%Y%m%d', event_date), WEEK(MONDAY)) AS week_start,
		SUM(items.item_revenue_in_usd) AS revenue
	FROM
		`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
		UNNEST(items) AS items
	WHERE event_name = 'purchase'
	GROUP BY week_start
)

SELECT
	week_start,
	revenue,
	LAG(revenue) OVER (ORDER BY week_start) AS prev_week_revenue,
	ROUND(SAFE_DIVIDE(
		revenue - LAG(revenue) OVER (ORDER BY week_start),
		LAG(revenue) OVER (ORDER BY week_start)
	) * 100.0, 1) AS wow_change_pct
FROM weekly_data
ORDER BY week_start;

/*
---------------------------------------------------------------------------

3D. Average Order Value

Utilization: 138.31 MB

---------------------------------------------------------------------------
*/

SELECT
  traffic_source.source AS source,
  traffic_source.medium AS medium,
  COUNT(*) AS total_orders,
  ROUND(AVG(ecommerce.purchase_revenue_in_usd), 2) AS avg_order_value,
  ROUND(MIN(ecommerce.purchase_revenue_in_usd), 2) AS min_order_value,
  ROUND(MAX(ecommerce.purchase_revenue_in_usd), 2) AS max_order_value
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE
  event_name = 'purchase'
	AND ecommerce.purchase_revenue_in_usd > 0
  AND traffic_source.source NOT IN (
    '(data deleted)',
    'shop.googlemerchandisestore.com'
  ) 
  AND traffic_source.medium != '(data deleted)'
GROUP BY source, medium
HAVING COUNT(*) >= 10
ORDER BY total_orders DESC;
---------------------------------------------------------------------------