DROP TABLE IF EXISTS medical;
CREATE TABLE medical AS (
	WITH
		medical AS (
			SELECT *,(CASE amenity WHEN 'clinic' THEN 2 ELSE 5 END) AS mult,h3_lat_lng_to_cell(public.ST_Transform(public.ST_Centroid(geom),4326), 10) AS h3_10
			FROM polygons
			WHERE amenity in ('clinic', 'hospital')),
		additional_h3 AS (
			SELECT *,
				h3_cell_to_geometry(h3_10) AS centroid,
				h3_cell_to_parent(h3_10,9) AS h3_9
			FROM medical
			WHERE h3_10 IS NOT NULL)
	SELECT *,
		get_city(centroid) AS city
	FROM additional_h3);

CREATE INDEX IF NOT EXISTS medical_h3_10_idx
    ON medical  ((city IS NOT NULL),(h3_10 IS NOT NULL));

DROP TABLE IF EXISTS medical_index;
CREATE TABLE medical_index AS (
	WITH
		medical_index_10 AS (
			SELECT b.city, a.h3, 10::SMALLINT AS zoom,SUM(b.mult*POWER((8*b.mult-h3_grid_distance(a.h3,b.h3_10)),2)) AS medical_index
			FROM living_index a
			JOIN medical b ON h3_grid_distance(a.h3,b.h3_10)<8*b.mult AND a.city=b.city
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL AND a.zoom=10
			GROUP BY 1,2),
		medical_index_9 AS (
			SELECT b.city, h3_cell_to_parent(a.h3,9) AS h3, 9::SMALLINT AS zoom,SUM(b.mult*POWER((8*b.mult-h3_grid_distance(a.h3,b.h3_10)),2)) AS medical_index
			FROM living_index a
			JOIN medical b ON h3_grid_distance(a.h3,b.h3_10)<8*b.mult AND a.city=b.city
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL AND a.zoom=10
			GROUP BY 1,2),
		medical_index AS (
			SELECT * FROM medical_index_10
			UNION ALL
			SELECT * FROM medical_index_9
		),
		measure_stats as (
			SELECT city,zoom,percentile_cont(0.25) WITHIN GROUP (ORDER BY medical_index) as q1, percentile_cont(0.75) WITHIN GROUP (ORDER BY medical_index) as q3
			FROM medical_index
			GROUP BY 1,2),
		data_table AS (
			SELECT city,h3,zoom,GREATEST(LEAST(medical_index,q3+1.5*(q3-q1)),q1-1.5*(q3-q1)) AS medical_index
			FROM medical_index
			JOIN measure_stats USING(city,zoom)),
		medical_max_min AS (
			SELECT city,zoom,MAX(medical_index) AS max_medical_index, MIN(medical_index) AS min_medical_index FROM data_table GROUP BY 1,2
		)
	SELECT
		city,zoom,h3,
		CASE WHEN max_medical_index>min_medical_index THEN CAST(100*(medical_index-min_medical_index)/(max_medical_index-min_medical_index) AS smallint) ELSE 100::smallint END AS medical_index
	FROM data_table
	JOIN medical_max_min USING(city,zoom));

CREATE INDEX IF NOT EXISTS medical_index_city_h3_idx
    ON medical_index (city,h3);
