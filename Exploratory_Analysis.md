# A. Exploratory Analysis Queries

Click [here](README.md) to view the project overview.

### Table of Contents
- [A. Exploratory Analysis Queries](#a-exploratory-analysis-queries)
  - [1A. Dataset Overview](#1a-dataset-overview)
  - [2A. Event Type Distribution](#2a-event-type-distribution)
  - [3A. Device Category Distribution](#3a-device-category-distribution)
  - [4A. Geographic Distribution](#4a-geographic-distribution)
  - [5A. Daily Activity Trends](#5a-daily-activity-trends)
  - [6A. Revenue Overview](#6a-revenue-overview)
  - [7A. Traffic Source Overview](#7a-traffic-source-overview)
- [Further Analysis](#further-analysis)

## 1A. Dataset Overview
**Objective:** Establish understanding of data volume and completeness.

```sql
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
```
[Query Results](<Query Outputs/A. Exploratory Analysis/1A_Dataset_Overview.csv>)

**Findings:** Dataset comprises 4.3M events across 270K users and 360K sessions, with no missing values in key columns.

## 2A. Event Type Distribution
**Objective:** Identify primary user actions and engagement patterns.

```sql
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
```
[Query Results](<Query Outputs/A. Exploratory Analysis/2A_Event_Type_Distribution.csv>)

**Findings:** Browsing events (page views, engagement, scrolling) dominate, while 4.64% of users add an item to cart and only 1.64% of users complete purchases, indicating a possible need to improve the conversion process.

## 3A. Device Category Distribution
**Objective:** Assess traffic and conversion by device type.

```sql
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
```
[Query Results](<Query Outputs/A. Exploratory Analysis/3A_Device_Distribution.csv>)

**Findings:** Desktop drives 58% of traffic and 57% of purchases. Mobile contributes 40% of sessions with proportional conversion. Tablet traffic is negligible.

## 4A. Geographic Distribution
**Objective:** Identify top markets by engagement and revenue contribution.

```sql
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
```
[Query Results](<Query Outputs/A. Exploratory Analysis/4A_Geographic_Distribution.csv>)

**Findings:** United States accounts for 44% of traffic and 44% of purchases. India and Canada represent the next largest markets with proportional conversion rates.

## 5A. Daily Activity Trends
**Objective:** Track daily user activity and purchase patterns over time.

```sql
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
```
[Query Results](<Query Outputs/A. Exploratory Analysis/5A_Daily_Activity_Trends.csv>)

**Findings:** Daily users averaged 3,470 with approximately 62 purchases per day. Activity peaked during late November through mid-December, reflecting holiday shopping behavior, then declined sharply through January.

## 6A. Revenue Overview
**Objective:** Identify revenue distribution and transaction value.

```sql
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
```
[Query Results](<Query Outputs/A. Exploratory Analysis/6A_Revenue_Overview.csv>)

**Findings:** Total revenue reached $362K over three months. Average order value of $69 with median of $48 indicates numerous high-value outliers. 450 transactions lack revenue data, likely due to promotional credits or gift card redemptions.

## 7A. Traffic Source Overview
**Objective:** Determine primary acquisition channels driving site traffic.

```sql
SELECT
  traffic_source.source AS source,
  COUNT(*) AS events,
  COUNT(DISTINCT user_pseudo_id) AS users,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER() * 100.0, 1) AS pct_of_events
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
GROUP BY source
ORDER BY events DESC;
```

[Query Results](<Query Outputs/A. Exploratory Analysis/7A_Traffic_Source_Overview.csv>)

**Findings:** Google search is the leading acquisition channel, driving 35% of total events. Obfuscated sources contribute 26%, and direct traffic accounts for 23%. Internal referrals make up 9%, while deleted data represents the remaining 7%; the latter two will be excluded from further analysis.

# Further Analysis
View other sections in the analysis:

[User Acquisition](User_Acquisition.md)

[User Behavior & Engagement](User_Behavior_Engagement.md)

[Sales & Revenue Performance](Sales_Revenue_Performance.md)

Click [here](README.md) to return to the project overview.