DROP TABLE IF EXISTS kindergarten_index_full;
CREATE TABLE kindergarten_index_full AS (
	WITH
		kindergarten_index_10 AS (
			SELECT a.city, a.h3_10 AS h3, 10::SMALLINT AS zoom, SUM(POWER((8-h3_grid_distance(a.h3_10,b.h3_10)),2)) AS kindergarten_index
			FROM city_h3 a
			JOIN kindergarten b ON a.city=b.city AND b.h3_10=a.h3_10_
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL
			GROUP BY 1,2),
		kindergarten_index_9 AS (
			SELECT a.city, a.h3_9 AS h3, 9::SMALLINT AS zoom, SUM(POWER((8-h3_grid_distance(a.h3_10,b.h3_10)),2)) AS kindergarten_index
			FROM city_h3 a
			JOIN kindergarten b ON a.city=b.city AND b.h3_10=a.h3_10_
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL
			GROUP BY 1,2),
		kindergarten_index AS (
			SELECT * FROM kindergarten_index_10
			UNION ALL
			SELECT * FROM kindergarten_index_9),
		measure_stats as (
			SELECT city,zoom,percentile_cont(0.25) WITHIN GROUP (ORDER BY kindergarten_index) as q1, percentile_cont(0.75) WITHIN GROUP (ORDER BY kindergarten_index) as q3
			FROM kindergarten_index
			GROUP BY 1,2),
		data_table AS (
			SELECT city,h3,zoom,GREATEST(LEAST(kindergarten_index,q3+1.5*(q3-q1)),q1-1.5*(q3-q1)) AS kindergarten_index
			FROM kindergarten_index
			JOIN measure_stats USING(city,zoom)),
		kindergarten_max_min AS (
			SELECT city,zoom,MAX(kindergarten_index) AS max_kindergarten_index, MIN(kindergarten_index) AS min_kindergarten_index FROM data_table GROUP BY 1,2
		)
	SELECT
		city,zoom,h3,
		CASE WHEN max_kindergarten_index>min_kindergarten_index THEN CAST(100*(kindergarten_index-min_kindergarten_index)/(max_kindergarten_index-min_kindergarten_index) AS smallint) ELSE 100::smallint END AS kindergarten_index
	FROM data_table
	JOIN kindergarten_max_min USING(city,zoom));

CREATE INDEX IF NOT EXISTS kindergarten_index_full_city_h3_idx
    ON kindergarten_index_full (city,h3,zoom);
