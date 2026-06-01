-- Identify strongest regions per country

WITH region_score AS (
    SELECT
        country_name,
        region_name,
        term,
        AVG(score) AS avg_score
    FROM `bigquery-public-data.google_trends.international_top_terms`
    GROUP BY country_name, region_name, term
),

ranked_region AS (
    SELECT
        *,
        RANK() OVER (
            PARTITION BY country_name, term
            ORDER BY avg_score DESC
        ) AS rank_region
    FROM region_score
)

SELECT *
FROM ranked_region
WHERE rank_region <= 3;