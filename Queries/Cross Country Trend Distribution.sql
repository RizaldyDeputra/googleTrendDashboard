-- Which countries dominate a trend

WITH country_trend AS (
    SELECT
        term,
        country_name,
        AVG(score) AS avg_score
    FROM `bigquery-public-data.google_trends.international_top_terms`
    GROUP BY term, country_name
),

ranked_country AS (
    SELECT
        term,
        country_name,
        avg_score,
        RANK() OVER (
            PARTITION BY term ORDER BY avg_score DESC
        ) AS rank_country
    FROM country_trend
)

SELECT *
FROM ranked_country
WHERE rank_country <= 5;