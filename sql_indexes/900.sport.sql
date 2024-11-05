DROP TABLE IF EXISTS sport_index_full;
CREATE TABLE sport_index_full AS (
	WITH
		sport_index_10 AS (
			SELECT a.city, a.h3_10 AS h3, 10::SMALLINT AS zoom, SUM(POWER((8-h3_grid_distance(a.h3_10,b.h3_10)),2)) AS sport_index
			FROM city_h3 a
			JOIN sport b ON a.city=b.city AND b.h3_10=a.h3_10_
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL
			GROUP BY 1,2),
		sport_index_9 AS (
			SELECT a.city, a.h3_9 AS h3, 9::SMALLINT AS zoom, SUM(POWER((8-h3_grid_distance(a.h3_10,b.h3_10)),2)) AS sport_index
			FROM city_h3 a
			JOIN sport b ON a.city=b.city AND b.h3_10=a.h3_10_
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL
			GROUP BY 1,2),
		sport_index AS (
			SELECT * FROM sport_index_10
			UNION ALL
			SELECT * FROM sport_index_9),
		measure_stats as (
			SELECT city,zoom,percentile_cont(0.25) WITHIN GROUP (ORDER BY sport_index) as q1, percentile_cont(0.75) WITHIN GROUP (ORDER BY sport_index) as q3
			FROM sport_index
			GROUP BY 1,2),
		data_table AS (
			SELECT city,h3,zoom,GREATEST(LEAST(sport_index,q3+1.5*(q3-q1)),q1-1.5*(q3-q1)) AS sport_index
			FROM sport_index
			JOIN measure_stats USING(city,zoom)),
		sport_max_min AS (
			SELECT city,zoom,MAX(sport_index) AS max_sport_index, MIN(sport_index) AS min_sport_index FROM data_table GROUP BY 1,2
		)
	SELECT
		city,zoom,h3,
		CASE WHEN max_sport_index>min_sport_index THEN CAST(100*(sport_index-min_sport_index)/(max_sport_index-min_sport_index) AS smallint) ELSE 100::smallint END AS sport_index
	FROM data_table
	JOIN sport_max_min USING(city,zoom));

CREATE INDEX IF NOT EXISTS sport_index_full_city_h3_idx
    ON sport_index_full (city,h3,zoom);
