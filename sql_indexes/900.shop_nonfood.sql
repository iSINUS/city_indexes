DROP TABLE IF EXISTS shop_nonfood_index_full;
CREATE TABLE shop_nonfood_index_full AS (
	WITH
		shop_nonfood_index_10 AS (
			SELECT a.city, a.h3_10 AS h3, 10::SMALLINT AS zoom, SUM((8-h3_grid_distance(a.h3_10,b.h3_10))*b.area) AS shop_nonfood_index
			FROM city_h3 a
			JOIN shop_nonfood b ON a.city=b.city AND b.h3_10=a.h3_10_
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL
			GROUP BY 1,2),
		shop_nonfood_index_9 AS (
			SELECT a.city, a.h3_9 AS h3, 9::SMALLINT AS zoom, SUM((8-h3_grid_distance(a.h3_10,b.h3_10))*b.area) AS shop_nonfood_index
			FROM city_h3 a
			JOIN shop_nonfood b ON a.city=b.city AND b.h3_10=a.h3_10_
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL
			GROUP BY 1,2),
		shop_nonfood_index AS (
			SELECT * FROM shop_nonfood_index_10
			UNION ALL
			SELECT * FROM shop_nonfood_index_9),
		measure_stats as (
			SELECT city,zoom,percentile_cont(0.25) WITHIN GROUP (ORDER BY shop_nonfood_index) as q1, percentile_cont(0.75) WITHIN GROUP (ORDER BY shop_nonfood_index) as q3
			FROM shop_nonfood_index
			GROUP BY 1,2),
		data_table AS (
			SELECT city,h3,zoom,GREATEST(LEAST(shop_nonfood_index,q3+1.5*(q3-q1)),q1-1.5*(q3-q1)) AS shop_nonfood_index
			FROM shop_nonfood_index
			JOIN measure_stats USING(city,zoom)),
		shop_nonfood_max_min AS (
			SELECT city,zoom,MAX(shop_nonfood_index) AS max_shop_nonfood_index, MIN(shop_nonfood_index) AS min_shop_nonfood_index FROM data_table GROUP BY 1,2
		)
	SELECT
		city,zoom,h3,
		CASE WHEN max_shop_nonfood_index>min_shop_nonfood_index THEN CAST(100*(shop_nonfood_index-min_shop_nonfood_index)/(max_shop_nonfood_index-min_shop_nonfood_index) AS smallint) ELSE 100::smallint END AS shop_nonfood_index
	FROM data_table
	JOIN shop_nonfood_max_min USING(city,zoom));

CREATE INDEX IF NOT EXISTS shop_nonfood_index_full_city_h3_idx
    ON shop_nonfood_index_full (city,h3,zoom);
