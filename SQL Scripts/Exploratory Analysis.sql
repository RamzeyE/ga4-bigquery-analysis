/*

Google Analytics E-Commerce Analysis
  Section A: Exploratory Analysis

---------------------------------------------------------------------------

1A. Dataset Overview

Utilization: 1.09 GB

---------------------------------------------------------------------------
*/

SELECT
  COUNT(*) AS events,
  CONCAT(
    FORMAT_DATE('%b %d, %Y', MIN(PARSE_DATE('%Y%m%d', event_date))),
    ' - ',
    FORMAT_DATE('%b %d, %Y', MAX(PARSE_DATE('%Y%m%d', event_date)))
  ) AS date_range,
  COUNT(DISTINCT user_pseudo_id) AS users,
  COUNT(DISTINCT CONCAT(
    user_pseudo_id,
    CAST((
      SELECT value.int_value 
      FROM UNNEST(event_params) 
      WHERE key = 'ga_session_id'
    ) AS STRING)
  )) AS sessions,
  COUNTIF(user_pseudo_id IS NULL) AS missing_user_id,
  COUNTIF(event_name IS NULL) AS missing_event_name,
  COUNTIF(device.category IS NULL) AS missing_device_cat,
  COUNTIF(geo.country IS NULL) AS missing_country,
  COUNTIF(traffic_source.source IS NULL) AS missing_traffic_source
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`;

/*
---------------------------------------------------------------------------

2A. Event Type Distribution

Utilization: 949.09 MB

---------------------------------------------------------------------------
*/

SELECT
  event_name,
  COUNT(*) AS events,
  COUNT(DISTINCT user_pseudo_id) AS users,
  COUNT(DISTINCT CONCAT(
    user_pseudo_id,
    CAST((
      SELECT value.int_value 
      FROM UNNEST(event_params) 
      WHERE key = 'ga_session_id'
    ) AS STRING)
  )) AS sessions,
  ROUND(
    COUNT(DISTINCT user_pseudo_id) / (
      SELECT COUNT(DISTINCT user_pseudo_id)
      FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
    ) * 100.0,
    1
  ) AS pct_of_users
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
GROUP BY event_name
ORDER BY events DESC;

/*
---------------------------------------------------------------------------

3A. Device Category Distribution

Utilization: 88.52 MB

---------------------------------------------------------------------------
*/

SELECT
  device.category,
  COUNT(*) AS events,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER() * 100.0, 1) AS pct_of_events,
  COUNTIF(event_name = 'purchase') AS purchases,
  ROUND(
    COUNTIF(event_name = 'purchase') / 
      SUM(COUNTIF(event_name = 'purchase')) OVER() * 100.0,
    1
  ) AS pct_of_purchases
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
GROUP BY device.category
ORDER BY events DESC;

/*
---------------------------------------------------------------------------

4A. Geographic Distribution

Utilization: 101.40 MB

---------------------------------------------------------------------------
*/

SELECT
  geo.country,
  COUNT(*) AS events,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER() * 100.0, 1) AS pct_of_events,
  COUNTIF(event_name = 'purchase') AS purchases,
  ROUND(
    COUNTIF(event_name = 'purchase') / 
      SUM(COUNTIF(event_name = 'purchase')) OVER() * 100.0,
    1
  ) AS pct_of_purchases
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
GROUP BY geo.country
ORDER BY events DESC;

/*
---------------------------------------------------------------------------

5A. Daily Activity Trends

Utilization: 990.06 MB

---------------------------------------------------------------------------
*/

SELECT
  FORMAT_DATE('%b %d, %Y', PARSE_DATE('%Y%m%d', event_date)) AS date,
  FORMAT_DATE('%A', PARSE_DATE('%Y%m%d', event_date)) AS weekday,
  COUNT(DISTINCT user_pseudo_id) AS users,
  COUNT(DISTINCT CONCAT(
    user_pseudo_id,
    CAST((
      SELECT value.int_value 
      FROM UNNEST(event_params) 
      WHERE key = 'ga_session_id'
    ) AS STRING)
  )) AS sessions,
  COUNTIF(event_name = 'purchase') AS purchases
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
GROUP BY event_date
ORDER BY event_date;

/*
---------------------------------------------------------------------------

6A. Revenue Overview

Utilization: 53.40 MB

---------------------------------------------------------------------------
*/

SELECT
  COUNT(*) AS purchase_events,
  COUNTIF(ecommerce.purchase_revenue IS NULL) AS missing_revenue,
  MIN(ecommerce.purchase_revenue) AS min_revenue,
  MAX(ecommerce.purchase_revenue) AS max_revenue,
  ROUND(AVG(ecommerce.purchase_revenue), 2) AS avg_revenue,
  SUM(ecommerce.purchase_revenue) AS total_revenue,
  APPROX_QUANTILES(ecommerce.purchase_revenue, 100)[OFFSET(50)] AS median_revenue
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE event_name = 'purchase';

/*
---------------------------------------------------------------------------

7A. Traffic Source Overview

Utilization: 131.51 MB

---------------------------------------------------------------------------
*/

SELECT
  traffic_source.source AS source,
  COUNT(*) AS events,
  COUNT(DISTINCT user_pseudo_id) AS users,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER() * 100.0, 1) AS pct_of_events
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
GROUP BY source
ORDER BY events DESC;
---------------------------------------------------------------------------