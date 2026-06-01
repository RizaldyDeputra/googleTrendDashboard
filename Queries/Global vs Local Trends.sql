-- Identify global vs local trends

WITH country_count AS (
    SELECT
        term,
        COUNT(DISTINCT country_name) AS country_coverage
    FROM `bigquery-public-data.google_trends.international_top_terms`
    GROUP BY term
)

SELECT
    term,
    country_coverage,
    CASE
        WHEN country_coverage >= 10 THEN 'Global'
        WHEN country_coverage BETWEEN 3 AND 9 THEN 'Regional'
        ELSE 'Local'
    END AS trend_scope
FROM country_count
ORDER BY country_coverage DESC;