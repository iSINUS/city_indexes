DROP TABLE IF EXISTS dining_index_full;
CREATE TABLE dining_index_full AS (
	WITH
		dining_index_10 AS (
			SELECT a.city, a.h3_10 AS h3, 10::SMALLINT AS zoom, SUM(POWER((8-h3_grid_distance(a.h3_10,b.h3_10)),2)) AS dining_index
			FROM city_h3 a
			JOIN dining b ON a.city=b.city AND b.h3_10=a.h3_10_
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL
			GROUP BY 1,2),
		dining_index_9 AS (
			SELECT a.city, a.h3_9 AS h3, 9::SMALLINT AS zoom, SUM(POWER((8-h3_grid_distance(a.h3_10,b.h3_10)),2)) AS dining_index
			FROM city_h3 a
			JOIN dining b ON a.city=b.city AND b.h3_10=a.h3_10_
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL
			GROUP BY 1,2),
		dining_index AS (
			SELECT * FROM dining_index_10
			UNION ALL
			SELECT * FROM dining_index_9),
		measure_stats as (
			SELECT city,zoom,percentile_cont(0.25) WITHIN GROUP (ORDER BY dining_index) as q1, percentile_cont(0.75) WITHIN GROUP (ORDER BY dining_index) as q3
			FROM dining_index
			GROUP BY 1,2),
		data_table AS (
			SELECT city,h3,zoom,GREATEST(LEAST(dining_index,q3+1.5*(q3-q1)),q1-1.5*(q3-q1)) AS dining_index
			FROM dining_index
			JOIN measure_stats USING(city,zoom)),
		dining_max_min AS (
			SELECT city,zoom,MAX(dining_index) AS max_dining_index, MIN(dining_index) AS min_dining_index FROM data_table GROUP BY 1,2
		)
	SELECT
		city,zoom,h3,
		CASE WHEN max_dining_index>min_dining_index THEN CAST(100*(dining_index-min_dining_index)/(max_dining_index-min_dining_index) AS smallint) ELSE 100::smallint END AS dining_index
	FROM data_table
	JOIN dining_max_min USING(city,zoom));

CREATE INDEX IF NOT EXISTS dining_index_full_city_h3_idx
    ON dining_index_full (city,h3,zoom);
