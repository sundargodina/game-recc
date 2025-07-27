

CREATE OR REPLACE TABLE `games.cleaned_games` AS
SELECT g.*
FROM `famous-modem-466914-j8.games.game` g
JOIN `famous-modem-466914-j8.games.metadata` gm
  ON g.app_id = gm.app_id
WHERE
  (g.price_original = 0.0 OR (g.price_original BETWEEN 2.99 AND 70.00))
  AND g.win = TRUE
  AND g.rating NOT IN ('Overwhelmingly Negative', 'Very Negative');

-- Step 1: Compute product quartiles and filter outliers
CREATE OR REPLACE TABLE `games.user_filtered_products` AS
WITH product_stats AS (
  SELECT APPROX_QUANTILES(products, 4) AS q FROM `games.users`
)
SELECT u.*
FROM `games.users` u, product_stats
WHERE u.products > 0
  AND u.products <= (q[3] + 1.5 * (q[3] - q[1]));

-- Step 2: Compute review quartiles and filter outliers
CREATE OR REPLACE TABLE `games.user_filtered_reviews` AS
WITH review_stats AS (
  SELECT APPROX_QUANTILES(reviews, 4) AS q FROM `games.user_filtered_products`
)
SELECT u.*
FROM `games.user_filtered_products` u, review_stats
WHERE u.reviews > 0
  AND u.reviews <= (q[3] + 3.0 * (q[3] - q[1]));

CREATE OR REPLACE TABLE `games.filtered_recommendations` AS
WITH hour_stats AS (
  SELECT APPROX_QUANTILES(hours, 4) AS q
  FROM `games.reccommendations`
)
SELECT r.*
FROM `games.reccommendations` r
JOIN `games.user_filtered_reviews` u ON r.user_id = u.user_id
JOIN `games.cleaned_games` g ON r.app_id = g.app_id,
hour_stats
WHERE r.hours >= 3
  AND r.hours <= (q[3] + 1.5 * (q[3] - q[1]));
