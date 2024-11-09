DROP TABLE IF EXISTS park;
CREATE TABLE park AS (
	WITH
		additional_h3 AS (
			SELECT *,
				h3_cell_to_geometry(h3_10) AS centroid,
				h3_cell_to_parent(h3_10,9) AS h3_9
			FROM park_tmp_h3
			WHERE h3_10 IS NOT NULL)
	SELECT *,
		get_city(centroid) AS city
	FROM additional_h3);

CREATE INDEX IF NOT EXISTS park_h3_10_idx
    ON park  ((city IS NOT NULL),(h3_10 IS NOT NULL));

DROP TABLE IF EXISTS park_index;
CREATE TABLE park_index AS (
	WITH
		park_index_10 AS (
			SELECT b.city, a.h3, 10::SMALLINT AS zoom,SUM(b.area*POWER((16-h3_grid_distance(a.h3,b.h3_10)),2)) AS park_index
			FROM living_index a
			JOIN park b ON h3_grid_distance(a.h3,b.h3_10)<16 AND a.city=b.city
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL AND a.zoom=10
			GROUP BY 1,2),
		park_index_9 AS (
			SELECT b.city, h3_cell_to_parent(a.h3,9) AS h3, 9::SMALLINT AS zoom,SUM(b.area*POWER((16-h3_grid_distance(a.h3,b.h3_10)),2)) AS park_index
			FROM living_index a
			JOIN park b ON h3_grid_distance(a.h3,b.h3_10)<16 AND a.city=b.city
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL AND a.zoom=10
			GROUP BY 1,2),
		park_index AS (
			SELECT * FROM park_index_10
			UNION ALL
			SELECT * FROM park_index_9
		),
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

CREATE INDEX IF NOT EXISTS park_index_city_h3_idx
    ON park_index (city,h3);
