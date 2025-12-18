# B. User Acquisition Queries

Click [here](README.md) to view the project overview.

### Table of Contents
- [B. User Acquisition Queries](#b-user-acquisition-queries)
  - [1B. Traffic Source Value](#1b-traffic-source-value)
  - [2B. New User Acquisition Growth](#2b-new-user-acquisition-growth)
  - [3B. Traffic Source Performance by Device](#3b-traffic-source-performance-by-device)
- [Further Analysis](#further-analysis)


## 1B. Traffic Source Value
**Objective:** Evaluate acquisition channels by purchase conversion and engagement metrics.

```sql
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
```

[Query Results](<Query Outputs/B. User Acquisition/1B_Traffic_Source_Value.csv>)

**Findings:** Google search drives the highest traffic (88k users) with steady conversion (1.3%) and strong engagement. Direct traffic follows (64k users, 1.5% conversion) and delivers the highest revenue efficiency. Obfuscated sources contribute meaningful volume but lower purchase rates (1.0–1.6%). Paid ad campaigns perform below average in conversion (1.0%) and engagement.


## 2B. New User Acquisition Growth
**Objective:** Track week-over-week new user growth and revenue by acquisition channel.

```sql
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
```

[Query Results](<Query Outputs/B. User Acquisition/2B_New_User_Growth_Rate.csv>)

**Findings:** New user acquisition peaked in late November to early December, led by organic search and direct traffic. Both channels saw strong double-digit week-over-week growth before declining sharply after December 20, likely due to seasonality or campaign slowdowns. Paid (CPC) traffic remained modest throughout, contributing incremental but less consistent user growth.

## 3B. Traffic Source Performance by Device
**Objective:** Analyze traffic performance by device across different acquisition channels, measuring user engagement, conversion rates, and revenue metrics.

```sql
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
```
[Query Results](<Query Outputs/B. User Acquisition/3B_Traffic_Performance_by_Device.csv>)

**Findings:** Desktop users consistently generate the highest revenue and purchase volume across nearly all traffic sources, with strong average order values, particularly from referral and organic channels. Mobile traffic, while slightly lower in revenue, shows comparable purchase rates, indicating strong conversion potential. Tablet users contribute minimally to both revenue and purchases.

# Further Analysis
View other sections in the analysis:

[Exploratory Analysis](Exploratory_Analysis.md)

[User Behavior & Engagement](User_Behavior_Engagement.md)

[Sales & Revenue Performance](Sales_Revenue_Performance.md)

Click [here](README.md) to return to the project overview.