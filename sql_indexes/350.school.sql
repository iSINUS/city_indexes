DROP TABLE IF EXISTS school_index_isochrones;
CREATE TABLE school_index_isochrones AS (
	WITH
		school_prepared AS (
			SELECT b.city, a.h3 AS h3,b.area_id,MIN(aa.distance) AS distance
			FROM living_index a
			JOIN living_index_isochrones aa USING (h3)
			JOIN school b ON ST_WITHIN(b.centroid,aa.geom) AND a.city=b.city
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL AND a.zoom=10 AND aa.distance<=10
			GROUP BY 1,2,3),
		school_index_10 AS (
			SELECT city,h3,10::SMALLINT AS zoom, SUM(POWER((11-distance),2)) AS school_index
			FROM school_prepared
			GROUP BY 1,2),
		school_index_9 AS (
			SELECT city,h3_cell_to_parent(h3,9) AS h3, 9::SMALLINT AS zoom, SUM(POWER((11-distance),2)) AS school_index
			FROM school_prepared
			GROUP BY 1,2),
		school_index_isochrones AS (
			SELECT * FROM school_index_10
			UNION ALL
			SELECT * FROM school_index_9
		),
		measure_stats as (
			SELECT city,zoom,percentile_cont(0.25) WITHIN GROUP (ORDER BY school_index) as q1, percentile_cont(0.75) WITHIN GROUP (ORDER BY school_index) as q3
			FROM school_index_isochrones
			GROUP BY 1,2),
		data_table AS (
			SELECT city,h3,zoom,GREATEST(LEAST(school_index,q3+1.5*(q3-q1)),q1-1.5*(q3-q1)) AS school_index
			FROM school_index_isochrones
			JOIN measure_stats USING(city,zoom)),
		school_max_min AS (
			SELECT city,zoom,MAX(school_index) AS max_school_index, MIN(school_index) AS min_school_index FROM data_table GROUP BY 1,2
		)
	SELECT city,zoom,h3, CAST(100*(school_index-min_school_index)/(max_school_index-min_school_index) AS smallint) AS school_index
	FROM data_table
	JOIN school_max_min USING(city,zoom));

CREATE INDEX IF NOT EXISTS school_index_isochrones_city_h3_idx
    ON school_index_isochrones (city,h3);
