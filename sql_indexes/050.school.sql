DROP TABLE IF EXISTS school;
CREATE TABLE school AS (
	WITH
		school AS (
			SELECT *,h3_lat_lng_to_cell(public.ST_Transform(public.ST_Centroid(geom),4326), 10) AS h3_10
			FROM polygons
			WHERE amenity='school'),
		additional_h3 AS (
			SELECT *,
				h3_cell_to_geometry(h3_10) AS centroid,
				h3_cell_to_parent(h3_10,9) AS h3_9
			FROM school
			WHERE h3_10 IS NOT NULL)
	SELECT *,
		get_city(centroid) AS city
	FROM additional_h3);


CREATE INDEX IF NOT EXISTS school_h3_10_idx
    ON school  ((city IS NOT NULL),(h3_10 IS NOT NULL));

DROP TABLE IF EXISTS school_index;
CREATE TABLE school_index AS (
	WITH
		school_index_10 AS (
			SELECT b.city, a.h3, 10::SMALLINT AS zoom,SUM(POWER((8-h3_grid_distance(a.h3,b.h3_10)),2)) AS school_index
			FROM living_index a
			JOIN school b ON h3_grid_distance(a.h3,b.h3_10)<8 AND a.city=b.city
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL AND a.zoom=10
			GROUP BY 1,2),
		school_index_9 AS (
			SELECT b.city, h3_cell_to_parent(a.h3,9) AS h3, 9::SMALLINT AS zoom,SUM(POWER((8-h3_grid_distance(a.h3,b.h3_10)),2)) AS school_index
			FROM living_index a
			JOIN school b ON h3_grid_distance(a.h3,b.h3_10)<8 AND a.city=b.city
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL AND a.zoom=10
			GROUP BY 1,2),
		school_index AS (
			SELECT * FROM school_index_10
			UNION ALL
			SELECT * FROM school_index_9
		),
		measure_stats as (
			SELECT city,zoom,percentile_cont(0.25) WITHIN GROUP (ORDER BY school_index) as q1, percentile_cont(0.75) WITHIN GROUP (ORDER BY school_index) as q3
			FROM school_index
			GROUP BY 1,2),
		data_table AS (
			SELECT city,h3,zoom,GREATEST(LEAST(school_index,q3+1.5*(q3-q1)),q1-1.5*(q3-q1)) AS school_index
			FROM school_index
			JOIN measure_stats USING(city,zoom)),
		school_max_min AS (
			SELECT city,zoom,MAX(school_index) AS max_school_index, MIN(school_index) AS min_school_index FROM data_table GROUP BY 1,2
		)
	SELECT city,zoom,h3, CAST(100*(school_index-min_school_index)/(max_school_index-min_school_index) AS smallint) AS school_index
	FROM data_table
	JOIN school_max_min USING(city,zoom));

CREATE INDEX IF NOT EXISTS school_index_city_h3_idx
    ON school_index (city,h3);
