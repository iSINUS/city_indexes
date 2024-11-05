DROP TABLE IF EXISTS parking_index_full;
CREATE TABLE parking_index_full AS (
	WITH
		parking_index_10 AS (
			SELECT a.city, a.h3_10 AS h3, 10::SMALLINT AS zoom, SUM(POWER((8-h3_grid_distance(a.h3_10,b.h3_10)),2)) AS parking_index
			FROM city_h3 a
			JOIN parking b ON a.city=b.city AND b.h3_10=a.h3_10_
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL
			GROUP BY 1,2),
		parking_index_9 AS (
			SELECT a.city, a.h3_9 AS h3, 9::SMALLINT AS zoom, SUM(POWER((8-h3_grid_distance(a.h3_10,b.h3_10)),2)) AS parking_index
			FROM city_h3 a
			JOIN parking b ON a.city=b.city AND b.h3_10=a.h3_10_
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL
			GROUP BY 1,2),
		parking_index AS (
			SELECT * FROM parking_index_10
			UNION ALL
			SELECT * FROM parking_index_9),
		measure_stats as (
			SELECT city,zoom,percentile_cont(0.25) WITHIN GROUP (ORDER BY parking_index) as q1, percentile_cont(0.75) WITHIN GROUP (ORDER BY parking_index) as q3
			FROM parking_index
			GROUP BY 1,2),
		data_table AS (
			SELECT city,h3,zoom,GREATEST(LEAST(parking_index,q3+1.5*(q3-q1)),q1-1.5*(q3-q1)) AS parking_index
			FROM parking_index
			JOIN measure_stats USING(city,zoom)),
		parking_max_min AS (
			SELECT city,zoom,MAX(parking_index) AS max_parking_index, MIN(parking_index) AS min_parking_index FROM data_table GROUP BY 1,2
		)
	SELECT
		city,zoom,h3,
		CASE WHEN max_parking_index>min_parking_index THEN CAST(100*(parking_index-min_parking_index)/(max_parking_index-min_parking_index) AS smallint) ELSE 100::smallint END AS parking_index
	FROM data_table
	JOIN parking_max_min USING(city,zoom));

CREATE INDEX IF NOT EXISTS parking_index_full_city_h3_idx
    ON parking_index_full (city,h3,zoom);
