DROP TABLE IF EXISTS education_index_full;
CREATE TABLE education_index_full AS (
	WITH
		education_index_10 AS (
			SELECT a.city, a.h3_10 AS h3, 10::SMALLINT AS zoom, SUM((16-h3_grid_distance(a.h3_10,b.h3_10))*b.area) AS education_index
			FROM city_h3 a
			JOIN education b ON a.city=b.city AND b.h3_10=a.h3_10_
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL
			GROUP BY 1,2),
		education_index_9 AS (
			SELECT a.city, a.h3_9 AS h3, 9::SMALLINT AS zoom, SUM((16-h3_grid_distance(a.h3_10,b.h3_10))*b.area) AS education_index
			FROM city_h3 a
			JOIN education b ON a.city=b.city AND b.h3_10=a.h3_10_
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL
			GROUP BY 1,2),
		education_index AS (
			SELECT * FROM education_index_10
			UNION ALL
			SELECT * FROM education_index_9),
		measure_stats as (
			SELECT city,zoom,percentile_cont(0.25) WITHIN GROUP (ORDER BY education_index) as q1, percentile_cont(0.75) WITHIN GROUP (ORDER BY education_index) as q3
			FROM education_index
			GROUP BY 1,2),
		data_table AS (
			SELECT city,h3,zoom,GREATEST(LEAST(education_index,q3+1.5*(q3-q1)),q1-1.5*(q3-q1)) AS education_index
			FROM education_index
			JOIN measure_stats USING(city,zoom)),
		education_max_min AS (
			SELECT city,zoom,MAX(education_index) AS max_education_index, MIN(education_index) AS min_education_index FROM data_table GROUP BY 1,2
		)
	SELECT
		city,zoom,h3,
		CASE WHEN max_education_index>min_education_index THEN CAST(100*(education_index-min_education_index)/(max_education_index-min_education_index) AS smallint) ELSE 100::smallint END AS education_index
	FROM data_table
	JOIN education_max_min USING(city,zoom));

CREATE INDEX IF NOT EXISTS education_index_full_city_h3_idx
    ON education_index_full (city,h3,zoom);
