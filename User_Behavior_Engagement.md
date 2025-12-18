# C. User Behavior & Engagement Queries

Click [here](README.md) to view the project overview.

### Table of Contents
- [C. User Behavior \& Engagement Queries](#c-user-behavior--engagement-queries)
  - [1C. Engagement Analysis](#1c-engagement-analysis)
  - [2C. Engagement by Traffic Source](#2c-engagement-by-traffic-source)
  - [3C. Conversion Funnel Analysis](#3c-conversion-funnel-analysis)
- [Further Analysis](#further-analysis)


## 1C. Engagement Analysis
**Objective:** Compare engagement between users who convert and those who don't.

```sql
WITH sessions AS (
    SELECT
	    user_pseudo_id,
		(SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS ga_session_id,
        SUM((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'engagement_time_msec')) AS engagement_time,
		COUNT(*) AS events_per_session,
		COUNTIF(event_name = 'page_view') AS pages_per_session,
		MAX(CASE WHEN event_name = 'purchase' THEN 1 ELSE 0 END) AS purchase_flag
	FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
	GROUP BY user_pseudo_id, ga_session_id
)

SELECT
    'Total' AS user_type,
	ROUND(AVG(engagement_time) / 1000, 2) AS avg_engagement_time_sec,
	ROUND(AVG(events_per_session), 2) AS avg_events_per_session,
	ROUND(AVG(pages_per_session), 2) AS avg_pages_per_session
FROM sessions

UNION ALL

SELECT
	CASE WHEN purchase_flag = 1 THEN 'Purchaser' ELSE 'Non-Purchaser' END AS user_type,
	ROUND(AVG(engagement_time) / 1000, 2) AS avg_engagement_time_sec,
	ROUND(AVG(events_per_session), 2) AS avg_events_per_session,
	ROUND(AVG(pages_per_session), 2) AS avg_pages_per_session
FROM sessions
GROUP BY purchase_flag;
```
[Query Results](<Query Outputs/C. User Behavior & Engagement/1C_Engagement_Analysis.csv>)

**Findings:** Purchasers show substantially higher engagement, with far greater average session time, events per session, and pages per session. This is expected, as purchasers naturally generate more events and view more pages during the buying process, whereas non-purchasers interact less with the site.

## 2C. Engagement by Traffic Source
**Objective:** Compare session engagement depth across acquisition channels.

```sql
WITH sessions AS (
    SELECT
        user_pseudo_id,
        (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS ga_session_id,
        traffic_source.source,
        traffic_source.medium,
        SUM((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'engagement_time_msec')) AS engagement_time,
        COUNT(*) AS events_per_session,
        COUNTIF(event_name = 'page_view') AS pages_per_session
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
    WHERE
        traffic_source.source NOT IN (
            '(data deleted)',
            'shop.googlemerchandisestore.com'
        )
        AND traffic_source.medium != '(data deleted)'
    GROUP BY user_pseudo_id, ga_session_id, traffic_source.source, traffic_source.medium
)

SELECT
    source,
    medium,
    COUNT(DISTINCT ga_session_id) AS total_sessions,
    ROUND(AVG(engagement_time) / 1000, 2) AS avg_engagement_time_sec,
    ROUND(AVG(events_per_session), 2) AS avg_events_per_session,
    ROUND(AVG(pages_per_session), 2) AS avg_pages_per_session
FROM sessions
GROUP BY source, medium
HAVING COUNT(DISTINCT ga_session_id) >= 50
ORDER BY total_sessions DESC;
```
[Query Results](<Query Outputs/C. User Behavior & Engagement/2C_Engagement_by_Traffic_Source.csv>)

**Findings:** Referral traffic drives the highest user engagement, suggesting these users are highly interested and more interactive. Google search and direct channels maintain strong, consistent engagement, indicating they effectively attract attentive visitors. Paid search (Google CPC) shows lower engagement, highlighting an opportunity to improve interaction and conversion.

## 3C. Conversion Funnel Analysis
**Objective:** Analyze user progression through the purchase funnel and identify primary drop-off points.

```sql
WITH user_funnel AS (
    SELECT
        user_pseudo_id,
        MIN(CASE WHEN event_name = 'session_start' THEN event_timestamp END) AS first_session,
        MIN(CASE WHEN event_name = 'view_item' THEN event_timestamp END) AS first_view,
        MIN(CASE WHEN event_name = 'add_to_cart' THEN event_timestamp END) AS first_add_to_cart,
        MIN(CASE WHEN event_name = 'begin_checkout' THEN event_timestamp END) AS first_checkout,
        MIN(CASE WHEN event_name = 'add_payment_info' THEN event_timestamp END) AS first_payment_info,
        MIN(CASE WHEN event_name = 'purchase' THEN event_timestamp END) AS first_purchase,
        MAX(CASE WHEN event_name = 'session_start' THEN 1 ELSE 0 END) AS reached_session,
        MAX(CASE WHEN event_name = 'view_item' THEN 1 ELSE 0 END) AS reached_view,
        MAX(CASE WHEN event_name = 'add_to_cart' THEN 1 ELSE 0 END) AS reached_cart,
        MAX(CASE WHEN event_name = 'begin_checkout' THEN 1 ELSE 0 END) AS reached_checkout,
        MAX(CASE WHEN event_name = 'add_payment_info' THEN 1 ELSE 0 END) AS reached_payment_info,
        MAX(CASE WHEN event_name = 'purchase' THEN 1 ELSE 0 END) AS completed_purchase,
        TIMESTAMP_DIFF(
            TIMESTAMP_MICROS(MIN(CASE WHEN event_name = 'purchase' THEN event_timestamp END)),
            TIMESTAMP_MICROS(MIN(CASE WHEN event_name = 'session_start' THEN event_timestamp END)),
            SECOND
        ) / 86400.0 AS time_to_purchase_days
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  GROUP BY user_pseudo_id
)

SELECT
    COUNT(DISTINCT user_pseudo_id) AS total_users,
    COUNTIF(reached_session = 1) AS users_started_session,
    COUNTIF(reached_view = 1) AS users_viewed_items,
    COUNTIF(reached_cart = 1) AS users_added_to_cart,
    COUNTIF(reached_checkout = 1) AS users_reached_checkout,
    COUNTIF(reached_payment_info = 1) AS users_added_payment,
    COUNTIF(completed_purchase = 1) AS users_completed_purchase,
    ROUND(AVG(time_to_purchase_days), 1) AS avg_time_to_purchase_days,
    ROUND(COUNTIF(reached_checkout = 1) / NULLIF(COUNTIF(reached_cart = 1), 0) * 100.0, 1) AS cart_to_checkout_pct,
    ROUND(COUNTIF(reached_payment_info = 1) / NULLIF(COUNTIF(reached_checkout = 1), 0) * 100.0, 1) AS checkout_to_payment_pct,
    ROUND(COUNTIF(completed_purchase = 1) / NULLIF(COUNTIF(reached_payment_info = 1), 0) * 100.0, 1) AS payment_to_purchase_pct
FROM user_funnel;
```
[Query Results](<Query Outputs/C. User Behavior & Engagement/3C_Conversion_Funnel_Analysis.csv>)

**Findings:** The largest initial drop-off occurs at the item view stage, where only 23% of users who start a session view a product. The most critical leak happens at the payment stage, with 40.8% of users abandoning after reaching checkout, highlighting the need to streamline the payment process. Of those who enter payment details, 77% successfully complete their purchase.

# Further Analysis
View other sections in the analysis:

[Exploratory Analysis](Exploratory_Analysis.md)

[User Acquisition](User_Acquisition.md)

[Sales & Revenue Performance](Sales_Revenue_Performance.md)

Click [here](README.md) to return to the project overview.