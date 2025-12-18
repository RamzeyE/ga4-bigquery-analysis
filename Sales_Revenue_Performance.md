# D. Sales & Revenue Performance

Click [here](README.md) to view the project overview.

### Table of Contents
- [D. Sales \& Revenue Performance](#d-sales--revenue-performance)
	- [1D. Top Products by Revenue](#1d-top-products-by-revenue)
	- [2D. Weekly Revenue \& Growth Trends](#2d-weekly-revenue--growth-trends)
	- [3D. Average Order Value](#3d-average-order-value)
- [Further Analysis](#further-analysis)


## 1D. Top Products by Revenue
**Objective:** Identify highest-grossing products and categories.

```sql
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
```
[Query Results](<Query Outputs/D. Sales & Revenue Performance/1D_Top_Products.csv>)

**Findings:** Apparel drives the highest volume, with Google-branded items dominating the top sellers. Several high-priced products show strong performance, suggesting untapped potential with higher-margin items. Accessories and drinkware provide supplementary revenue but lack individual high-performers.


## 2D. Weekly Revenue & Growth Trends
**Objective:** Analyze revenue trends and week-over-week growth patterns.

```sql
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
```
[Query Results](<Query Outputs/D. Sales & Revenue Performance/2D_Revenue_over_Time.csv>)

**Findings:** Revenue demonstrates significant weekly volatility indicating either heavy promotional dependency, seasonal factors, or inconsistent customer demand.


## 3D. Average Order Value
**Objective:**  Identify which acquisition channels drive the highest-value customers.

```sql
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
```
[Query Results](<Query Outputs/D. Sales & Revenue Performance/2D_Revenue_over_Time.csv>)

**Findings:** Google search traffic drives the most value with 1,345 orders and a healthy $71 average order value, while direct traffic delivers comparable AOV ($70) with strong volume (1,138 orders). However, CPC traffic significantly underperforms with only 156 orders at a $58 AOV.

# Further Analysis
View other sections in the analysis:

[Exploratory Analysis](Exploratory_Analysis.md)

[User Acquisition](User_Acquisition.md)

[User Behavior & Engagement](User_Behavior_Engagement.md)

Click [here](README.md) to return to the project overview.