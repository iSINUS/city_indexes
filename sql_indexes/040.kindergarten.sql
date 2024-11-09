DROP TABLE IF EXISTS kindergarten;
CREATE TABLE kindergarten AS (
	WITH
		kindergarten AS (
			SELECT *,h3_lat_lng_to_cell(public.ST_Transform(public.ST_Centroid(geom),4326), 10) AS h3_10
			FROM polygons
			WHERE amenity='kindergarten'),
		additional_h3 AS (
			SELECT *,
				h3_cell_to_geometry(h3_10) AS centroid,
				h3_cell_to_parent(h3_10,9) AS h3_9
			FROM kindergarten
			WHERE h3_10 IS NOT NULL)
	SELECT *,
		get_city(centroid) AS city
	FROM additional_h3);

CREATE INDEX IF NOT EXISTS kindergarten_h3_10_idx
    ON kindergarten ((city IS NOT NULL),(h3_10 IS NOT NULL));

DROP TABLE IF EXISTS kindergarten_index;
CREATE TABLE kindergarten_index AS (
	WITH
		kindergarten_index_10 AS (
			SELECT b.city, a.h3 AS h3, 10::SMALLINT AS zoom,SUM(POWER((8-h3_grid_distance(a.h3,b.h3_10)),2)) AS kindergarten_index
			FROM living_index a
			JOIN kindergarten b ON h3_grid_distance(a.h3,b.h3_10)<8 AND a.city=b.city
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL AND a.zoom=10
			GROUP BY 1,2),
		kindergarten_index_9 AS (
			SELECT b.city, h3_cell_to_parent(a.h3,9) AS h3, 9::SMALLINT AS zoom,SUM(POWER((8-h3_grid_distance(a.h3,b.h3_10)),2)) AS kindergarten_index
			FROM living_index a
			JOIN kindergarten b ON h3_grid_distance(a.h3,b.h3_10)<8 AND a.city=b.city
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL AND a.zoom=10
			GROUP BY 1,2),
		kindergarten_index AS (
			SELECT * FROM kindergarten_index_10
			UNION ALL
			SELECT * FROM kindergarten_index_9
		),
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

CREATE INDEX IF NOT EXISTS kindergarten_index_city_h3_idx
    ON kindergarten_index (city,h3);
