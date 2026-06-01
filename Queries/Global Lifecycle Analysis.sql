-- Trend lifecycle across countries

WITH timeseries AS (
    SELECT
        term,
        country_name,
        week,
        AVG(score) AS avg_score
    FROM `bigquery-public-data.google_trends.international_top_terms`
    GROUP BY term, country_name, week
),

lifecycle AS (
    SELECT
        term,
        country_name,
        week,
        avg_score,
        LAG(avg_score) OVER (
            PARTITION BY term, country_name 
            ORDER BY week
        ) AS prev_score
    FROM timeseries
)

SELECT
    term,
    country_name,
    week,
    avg_score,
    avg_score - prev_score AS growth
FROM lifecycle;