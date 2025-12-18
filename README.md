# Google Analytics E-Commerce Analysis with BigQuery

*A data analysis project demonstrating SQL expertise and business intelligence insights for e-commerce platform optimization*

#### Table of Contents
- [Project Background](#project-background)
- [Summary](#summary)
- [Key Insights](#key-insights)
- [Recommendations](#recommendations)
  - [Improve Conversion Funnel Leak](#improve-conversion-funnel-leak)
  - [Optimize Paid Ads (CPC) Performance](#optimize-paid-ads-cpc-performance)
  - [Address Product View Dropoff](#address-product-view-dropoff)
  - [Leverage High-Margin Products](#leverage-high-margin-products)
  - [Develop Mobile Revenue Strategy](#develop-mobile-revenue-strategy)
  - [Capitalize on Referral Traffic Quality](#capitalize-on-referral-traffic-quality)
  - [Optimize for Peak Seasons](#optimize-for-peak-seasons)
- [SQL Queries \& Results](#sql-queries--results)


## Project Background
This project analyzes Google Analytics 4 (GA4) e-commerce data from the public BigQuery dataset to derive actionable insights on user behavior, acquisition effectiveness, engagement patterns, and revenue performance.

### Tools Used
```Google BigQuery```, ```SQL```, ```Google Analytics 4```

### Data Source
Dataset: ```bigquery-public-data.ga4_obfuscated_sample_ecommerce```

This dataset represents a sample of obfsucated Google Analytics event data from the Google Merchandise Store. The data has been anonymized with certain fields containing placeholder values.

The dataset contains ~4.3M events from ~270K users, and spans from November 2020 to January 2021. Each row in the table represents a single event occurence. However, due to repeated nested structures (like multiple parameters per event), a single event can span multiple rows.

For more information on how the dataset is structured, visit the documentation here: https://support.google.com/analytics/answer/7029846

### Data Schema Characteristics

* Complex data structures are stored as RECORD types, enabling hierarchical data organization (e.g., device info or geographical location).

* Arrays of data like `event_params`, `user_properties`, and `items` are stored as repeated records, requiring UNNEST operations.

* Custom event and user parameters are stored in key-value pairs with typed values (string, int, double, float).

## Summary

- From November 2020 to January 2021, The business generated $362K in revenue from 270K users. A significant **40.8% checkout abandonment rate** represents a critical source of revenue leakage. 

- **Paid traffic (CPC) underperforms**, exhibiting weak conversion and low revenue contribution, indicating the need for campaign optimization.

- Mobile traffic accounts for 40% of sessions with conversion rates comparable to desktop traffic, but generates lower revenue per transaction, suggesting a revenue uplift opportunity on mobile.

- U.S. customers account for the largest share of purchases (~44%), followed by India and Canada. **Google-branded merchandise and apparel** drive the highest revenue and unit volume. Revenue is **heavily concentrated in winter apparel** (hoodies, sweatpants, sweaters), resulting in a **winter-driven seasonality**. Expanding spring and summer product offerings would help mitigate low-revenue quarters and reduce seasonal volatility.

This analysis identifies key opportunities to improve conversion and optimize acquisition channels. Immediate priorities include checkout process enhancement, paid campaign restructuring, and mobile revenue optimization.


## Key Insights

- #### Acquisition

    * Google search is the primary source (~35% of events, ~88k users) with ~1.3% purchase conversion. Direct traffic delivers higher purchase conversion (~1.5%) and more revenue per user.
    * Paid campaigns (CPC) show considerable lower engagement and conversion (~1.0%) vs other sources.
    * New user acquisition peaked in late Nov–Dec with seasonal drops after Dec 20.

- #### Engagement

    * Referral and Google Search channels show highest engagement; paid ad campaigns have lower engagement metrics.
    * Desktop users typically generate the most revenue and orders across channels; mobile shows comparable purchase rates but lower revenue per purchaser, indicating a revenue uplift opportunity on mobile.


- #### Funnel Conversion

    * Only ~23% of session-starters view a product. The largest funnel drop-off occurs during the checkout process where ~40.8% of users drop after reaching checkout and before entering payment details.

- #### Revenue & Products

    * Revenue reached $362K across the period, with weekly volatility (likely seasonality or promo-driven)
    * Google Search and direct traffic drive the highest average order value (~$70) while CPC underperforms (~$58).
    * United States is the largest market (~44% of purchases), followed by India and Canada.
    * Apparel and Google-branded items account for the majority of revenue and units sold.
    * Premium items ($80-100+) show strong revenue potential but move 2-5x fewer units than mid-range products.
    * High-margin items are concentrated in cold-weather apparel, resulting in significant seasonal dependence.
    

## Recommendations

#### Improve Conversion Funnel Leak
> 40.8% of users abandon at the payment stage after reaching checkout.

* Implement exit pop-ups offering incentives or customer assistance

* Enable guest checkout 

* Conduct usability testing on the checkout page to identify barriers and improve trust.


#### Optimize Paid Ads (CPC) Performance
> Paid ads underperform, with a 1.0% conversion rate, the lowest engagement metrics, and $58 AOV.

* Review landing page and ensure relevance in ad messaging to reduce drop-offs.

* A/B test different elements (ad copy, images, CTAs, landing pages) to identify high-performing combinations.

* Consider reallocating budget toward retargeting campaigns for users who viewed products but did not convert.

####  Address Product View Dropoff
> Only 23% of session starters view a product.

* Improve homepage product visibility and featured collections.

* Add promotional banners highlighting popular items or deals.

* Implement personalized product recommendations.


#### Leverage High-Margin Products
> High-margin items show strong performance potential.

* Feature high-margin apparel prominently on the homepage and in promotional campaigns.

* Expand offerings beyond cold-weather apparel to diversify seasonal revenue streams.

* Bundle high-margin items with popular products.


#### Develop Mobile Revenue Strategy
> Mobile accounts for 40% of traffic with conversion rates comparable to desktop, indicating untapped revenue potential.

* Launch mobile-specific promotions or discounts to incentivize higher spend.

* Optimize mobile UX for browsing, product discovery, and checkout flow.

* Implement streamlined checkout options, including one-click payments (Apple Pay, Google Pay).

#### Capitalize on Referral Traffic Quality
> Referral traffic delivers the highest engagement metrics and most interested users.

* Identify top-performing referral sources and strengthen partnerships.

* Offer targeted promotions to convert referred visitors into purchases.

#### Optimize for Peak Seasons
> Revenue peaks in late November–December, followed by sharp declines.

* Plan holiday campaigns and seasonal promotions to maximize peak revenue.

* Introduce post-holiday and New Year/spring promotions to sustain momentum and smooth seasonality.


## SQL Queries & Results

Click below to view detailed findings, SQL queries, and query results:

[Exploratory Analysis](Exploratory_Analysis.md)

[User Acquisition](User_Acquisition.md)

[User Behavior & Engagement](User_Behavior_Engagement.md)

[Sales & Revenue Performance](Sales_Revenue_Performance.md)