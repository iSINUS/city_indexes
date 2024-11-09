DROP TABLE IF EXISTS dining;
CREATE TABLE dining AS (
	WITH
		dining AS (
			SELECT *,h3_lat_lng_to_cell(public.ST_Transform(public.ST_Centroid(geom),4326), 10) AS h3_10
			FROM (
				(SELECT area_id,geom
				FROM polygons
				WHERE amenity IN ('bar','biergarten','cafe','fapublic.ST_food','food_court','ice_cream','pub','restaurant'))
				UNION ALL
				(SELECT node_id,geom
				FROM points
				WHERE amenity IN ('bar','biergarten','cafe','fapublic.ST_food','food_court','ice_cream','pub','restaurant')))),
		additional_h3 AS (
			SELECT *,
				h3_cell_to_geometry(h3_10) AS centroid,
				h3_cell_to_parent(h3_10,9) AS h3_9
			FROM dining
			WHERE h3_10 IS NOT NULL)
	SELECT *,
		get_city(centroid) AS city
	FROM additional_h3);

CREATE INDEX IF NOT EXISTS dining_h3_10_idx
    ON dining  ((city IS NOT NULL),(h3_10 IS NOT NULL));

DROP TABLE IF EXISTS dining_index;
CREATE TABLE dining_index AS (
	WITH
		dining_index_10 AS (
			SELECT b.city, a.h3, 10::SMALLINT AS zoom,SUM(POWER((8-h3_grid_distance(a.h3,b.h3_10)),2)) AS dining_index
			FROM living_index a
			JOIN dining b ON h3_grid_distance(a.h3,b.h3_10)<8 AND a.city=b.city
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL AND a.zoom=10
			GROUP BY 1,2),
		dining_index_9 AS (
			SELECT b.city, h3_cell_to_parent(a.h3,9) AS h3, 9::SMALLINT AS zoom,SUM(POWER((8-h3_grid_distance(a.h3,b.h3_10)),2)) AS dining_index
			FROM living_index a
			JOIN dining b ON h3_grid_distance(a.h3,b.h3_10)<8 AND a.city=b.city
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL AND a.zoom=10
			GROUP BY 1,2),
		dining_index AS (
			SELECT * FROM dining_index_10
			UNION ALL
			SELECT * FROM dining_index_9
		),
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

CREATE INDEX IF NOT EXISTS dining_index_city_h3_idx
    ON dining_index (city,h3);
