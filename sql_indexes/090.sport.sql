DROP TABLE IF EXISTS sport;
CREATE TABLE sport AS (
	WITH
		sport AS (
			(SELECT area_id AS id,geom,h3_lat_lng_to_cell(public.ST_Transform(public.ST_Centroid(geom),4326), 10) AS h3_10
			FROM polygons
			WHERE leisure in ('sports_centre','fitness_centre','fitness_station'))
			UNION ALL
			(SELECT node_id AS id,geom,h3_lat_lng_to_cell(public.ST_Transform(geom,4326), 10) AS h3_10
			FROM points
			WHERE leisure in ('sports_centre','fitness_centre','fitness_station'))),
		additional_h3 AS (
			SELECT *,
				h3_cell_to_geometry(h3_10) AS centroid,
				h3_cell_to_parent(h3_10,9) AS h3_9
			FROM sport
			WHERE h3_10 IS NOT NULL)
	SELECT *,
		get_city(centroid) AS city
	FROM additional_h3);

CREATE INDEX IF NOT EXISTS sport_h3_10_idx
    ON sport  ((city IS NOT NULL),(h3_10 IS NOT NULL));

DROP TABLE IF EXISTS sport_index;
CREATE TABLE sport_index AS (
	WITH
		sport_index_10 AS (
			SELECT b.city, a.h3, 10::SMALLINT AS zoom,SUM(POWER((8-h3_grid_distance(a.h3,b.h3_10)),2)) AS sport_index
			FROM living_index a
			JOIN sport b ON h3_grid_distance(a.h3,b.h3_10)<8 AND a.city=b.city
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL AND a.zoom=10
			GROUP BY 1,2),
		sport_index_9 AS (
			SELECT b.city, h3_cell_to_parent(a.h3,9) AS h3, 9::SMALLINT AS zoom,SUM(POWER((8-h3_grid_distance(a.h3,b.h3_10)),2)) AS sport_index
			FROM living_index a
			JOIN sport b ON h3_grid_distance(a.h3,b.h3_10)<8 AND a.city=b.city
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL AND a.zoom=10
			GROUP BY 1,2),
		sport_index AS (
			SELECT * FROM sport_index_10
			UNION ALL
			SELECT * FROM sport_index_9
		),
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

CREATE INDEX IF NOT EXISTS sport_index_city_h3_idx
    ON sport_index (city,h3);
