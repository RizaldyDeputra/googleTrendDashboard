WITH rising_trends AS (
    SELECT
        term,
        country_name,
        COALESCE(region_name, 'National') AS region_name,
        refresh_date,
        week,
        percent_gain,
        RANK() OVER (
            PARTITION BY country_name, refresh_date 
            ORDER BY percent_gain DESC
        ) AS rank_growth
    FROM `bigquery-public-data.google_trends.international_top_rising_terms`
),

top_trends AS (
    SELECT
        term,
        country_name,
        COALESCE(region_name, 'National') AS region_name,
        week,
        MAX(score) AS score  -- deduplicate if multiple rows per term/country/week
    FROM `bigquery-public-data.google_trends.international_top_terms`
    GROUP BY term, country_name, region_name, week
)

SELECT
    r.term,
    r.country_name,
    r.region_name,
    r.week,
    r.percent_gain,
    t.score,
    CASE 
        WHEN r.percent_gain > 500 THEN 'Explosive'
        WHEN r.percent_gain BETWEEN 200 AND 500 THEN 'High Growth'
        ELSE 'Moderate'
    END AS growth_category
FROM rising_trends r
LEFT JOIN top_trends t
    ON r.term = t.term
    AND r.country_name = t.country_name
    AND r.region_name = t.region_name
    AND r.week = t.week        -- join on week instead of refresh_date
WHERE r.rank_growth <= 5
ORDER BY r.percent_gain DESC;