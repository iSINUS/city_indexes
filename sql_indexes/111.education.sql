DROP TABLE IF EXISTS education;
CREATE TABLE education AS (
	WITH
		additional_h3 AS (
			SELECT *,
				h3_cell_to_geometry(h3_10) AS centroid,
				h3_cell_to_parent(h3_10,9) AS h3_9
			FROM education_tmp_h3
			WHERE h3_10 IS NOT NULL)
	SELECT *,
		get_city(centroid) AS city
	FROM additional_h3);

CREATE INDEX IF NOT EXISTS education_h3_10_idx
    ON education  ((city IS NOT NULL),(h3_10 IS NOT NULL));

DROP TABLE IF EXISTS education_index;
CREATE TABLE education_index AS (
	WITH
		education_index_10 AS (
			SELECT b.city, a.h3, 10::SMALLINT AS zoom,SUM(b.area*POWER((16-h3_grid_distance(a.h3,b.h3_10)),2)) AS education_index
			FROM living_index a
			JOIN education b ON h3_grid_distance(a.h3,b.h3_10)<16 AND a.city=b.city
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL AND a.zoom=10
			GROUP BY 1,2),
		education_index_9 AS (
			SELECT b.city, h3_cell_to_parent(a.h3,9) AS h3, 9::SMALLINT AS zoom,SUM(b.area*POWER((16-h3_grid_distance(a.h3,b.h3_10)),2)) AS education_index
			FROM living_index a
			JOIN education b ON h3_grid_distance(a.h3,b.h3_10)<16 AND a.city=b.city
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL AND a.zoom=10
			GROUP BY 1,2),
		education_index AS (
			SELECT * FROM education_index_10
			UNION ALL
			SELECT * FROM education_index_9
		),
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

CREATE INDEX IF NOT EXISTS education_index_city_h3_idx
    ON education_index (city,h3);
