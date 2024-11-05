DROP TABLE IF EXISTS park_index_full;
CREATE TABLE park_index_full AS (
	WITH
		park_index_10 AS (
			SELECT a.city, a.h3_10 AS h3, 10::SMALLINT AS zoom, SUM((16-h3_grid_distance(a.h3_10,b.h3_10))*b.area) AS park_index
			FROM city_h3 a
			JOIN park b ON a.city=b.city AND b.h3_10=a.h3_10_
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL
			GROUP BY 1,2),
		park_index_9 AS (
			SELECT a.city, a.h3_9 AS h3, 9::SMALLINT AS zoom, SUM((16-h3_grid_distance(a.h3_10,b.h3_10))*b.area) AS park_index
			FROM city_h3 a
			JOIN park b ON a.city=b.city AND b.h3_10=a.h3_10_
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL
			GROUP BY 1,2),
		park_index AS (
			SELECT * FROM park_index_10
			UNION ALL
			SELECT * FROM park_index_9),
		measure_stats as (
			SELECT city,zoom,percentile_cont(0.25) WITHIN GROUP (ORDER BY park_index) as q1, percentile_cont(0.75) WITHIN GROUP (ORDER BY park_index) as q3
			FROM park_index
			GROUP BY 1,2),
		data_table AS (
			SELECT city,h3,zoom,GREATEST(LEAST(park_index,q3+1.5*(q3-q1)),q1-1.5*(q3-q1)) AS park_index
			FROM park_index
			JOIN measure_stats USING(city,zoom)),
		park_max_min AS (
			SELECT city,zoom,MAX(park_index) AS max_park_index, MIN(park_index) AS min_park_index FROM data_table GROUP BY 1,2
		)
	SELECT
		city,zoom,h3,
		CASE WHEN max_park_index>min_park_index THEN CAST(100*(park_index-min_park_index)/(max_park_index-min_park_index) AS smallint) ELSE 100::smallint END AS park_index
	FROM data_table
	JOIN park_max_min USING(city,zoom));

CREATE INDEX IF NOT EXISTS park_index_full_city_h3_idx
    ON park_index_full (city,h3,zoom);
