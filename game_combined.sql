CREATE OR REPLACE TABLE games.games_combined AS
WITH aggregated_tags AS (
  SELECT
    app_id,
    STRING_AGG(LOWER(tag), " ") AS tags_combined,
    LOWER(description) AS description_lower
  FROM
    `famous-modem-466914-j8.games.metadata`,
    UNNEST(tags) AS tag
  GROUP BY
    app_id, description
)
SELECT
  g.app_id,
  g.title AS name,
  agg.tags_combined,
  agg.description_lower AS description,
  CONCAT(agg.tags_combined, " ", agg.description_lower) AS combined_features
FROM
  `famous-modem-466914-j8.games.game` g
LEFT JOIN
  aggregated_tags agg
ON
  g.app_id = agg.app_id
WHERE
  g.title IS NOT NULL;

