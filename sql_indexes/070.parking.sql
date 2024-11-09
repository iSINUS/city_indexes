DROP TABLE IF EXISTS parking;
CREATE TABLE parking AS (
	WITH
		parking AS (
			SELECT *,h3_lat_lng_to_cell(public.ST_Transform(public.ST_Centroid(geom),4326), 10) AS h3_10
			FROM polygons
			WHERE amenity='parking' AND (tags->>'access' IS NULL OR tags->>'access' != 'private')),
		additional_h3 AS (
			SELECT *,
				h3_cell_to_geometry(h3_10) AS centroid,
				h3_cell_to_parent(h3_10,9) AS h3_9
			FROM parking
			WHERE h3_10 IS NOT NULL)
	SELECT *,
		get_city(centroid) AS city
	FROM additional_h3);

CREATE INDEX IF NOT EXISTS parking_h3_10_idx
    ON parking  ((city IS NOT NULL),(h3_10 IS NOT NULL));

DROP TABLE IF EXISTS parking_index;
CREATE TABLE parking_index AS (
	WITH
		parking_index_10 AS (
			SELECT b.city, a.h3, 10::SMALLINT AS zoom,SUM(POWER((8-h3_grid_distance(a.h3,b.h3_10)),2)) AS parking_index
			FROM living_index a
			JOIN parking b ON h3_grid_distance(a.h3,b.h3_10)<8 AND a.city=b.city
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL AND a.zoom=10
			GROUP BY 1,2),
		parking_index_9 AS (
			SELECT b.city, h3_cell_to_parent(a.h3,9) AS h3, 9::SMALLINT AS zoom,SUM(POWER((8-h3_grid_distance(a.h3,b.h3_10)),2)) AS parking_index
			FROM living_index a
			JOIN parking b ON h3_grid_distance(a.h3,b.h3_10)<8 AND a.city=b.city
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL AND a.zoom=10
			GROUP BY 1,2),
		parking_index AS (
			SELECT * FROM parking_index_10
			UNION ALL
			SELECT * FROM parking_index_9
		),
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

CREATE INDEX IF NOT EXISTS parking_index_city_h3_idx
    ON parking_index (city,h3);
