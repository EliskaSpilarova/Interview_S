-- ověření správného načtení
SELECT COUNT(*) FROM impress;
SELECT COUNT(*) FROM click;

-- Otázka č. 1: U jakého produktu je nejlepší poměr prokliků ku zobrazení?
SELECT 
    i.product_id,
    SUM(i.count::int) AS total_impressions,
    COALESCE(SUM(c.count::int), 0) AS total_clicks,
    ROUND(COALESCE(SUM(c.count::int), 0)::numeric / NULLIF(SUM(i.count::int), 0), 4) AS ctr
FROM impress i
LEFT JOIN click c
  ON i.user_id::bigint = c.user_id::bigint 
  AND i.product_id = c.product_id
GROUP BY i.product_id
HAVING SUM(i.count::int) >= 10
ORDER BY ctr DESC
LIMIT 1;

-- Otázka 2: Která produktová kategorie je nejproklikávanější a která nejzobrazovanější?
-- Nejzobrazovanější kategorie
SELECT 
    category_name,
    SUM(count) AS total_impressions
FROM impress
WHERE category_name IS NOT NULL
GROUP BY category_name
ORDER BY total_impressions DESC
LIMIT 1;

-- Nejproklikávanější kategorie
SELECT 
    i.category_name,
    SUM(c.count) AS total_clicks
FROM impress i
JOIN click c ON i.user_id = c.user_id AND i.product_id = c.product_id
WHERE i.category_name IS NOT NULL
GROUP BY i.category_name
ORDER BY total_clicks DESC
LIMIT 1;

-- Otázka 3: Má počet nabídek produktu nějaký vliv na jeho proklikovost?
WITH product_stats AS (
    SELECT 
        i.product_id,
        AVG(i.offers) AS avg_offers,
        SUM(i.count) AS total_impressions,
        COALESCE(SUM(c.count), 0) AS total_clicks
    FROM impress i
    LEFT JOIN click c ON i.product_id = c.product_id AND i.user_id = c.user_id
    GROUP BY i.product_id
    HAVING SUM(i.count) > 10  -- Filtrování statisticky významných dat
)
SELECT 
    CASE
        WHEN avg_offers BETWEEN 1 AND 5 THEN '01-05'
        WHEN avg_offers BETWEEN 6 AND 10 THEN '06-10'
        WHEN avg_offers BETWEEN 11 AND 20 THEN '11-20'
        WHEN avg_offers BETWEEN 21 AND 50 THEN '21-50'
        ELSE '50+'
    END AS offers_range,
    COUNT(*) AS product_count,
    SUM(total_impressions) AS total_impressions,
    SUM(total_clicks) AS total_clicks,
    CASE 
        WHEN SUM(total_impressions) > 0 THEN 
            ROUND((SUM(total_clicks)::NUMERIC / SUM(total_impressions)) * 100, 2)
        ELSE 0
    END AS click_through_rate
FROM product_stats
GROUP BY offers_range
ORDER BY offers_range;
