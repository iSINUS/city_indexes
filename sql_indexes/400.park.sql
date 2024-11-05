DROP TABLE IF EXISTS park_index_isochrones;
CREATE TABLE park_index_isochrones AS (
	WITH
		park_prepared AS (
			SELECT b.city, a.h3 AS h3,b.area_id,b.area,MIN(aa.distance) AS distance
			FROM living_index a
			JOIN living_index_isochrones aa USING (h3)
			JOIN park b ON ST_WITHIN(b.centroid,aa.geom) AND a.city=b.city
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL AND a.zoom=10 AND aa.distance<=30
			GROUP BY 1,2,3,4),
		park_index_10 AS (
			SELECT city,h3,10::SMALLINT AS zoom, SUM(area*POWEr((31-distance),2)) AS park_index
			FROM park_prepared
			GROUP BY 1,2),
		park_index_9 AS (
			SELECT city,h3_cell_to_parent(h3,9) AS h3, 9::SMALLINT AS zoom, SUM(area*POWER((31-distance),2)) AS park_index
			FROM park_prepared
			GROUP BY 1,2),
		park_index_isochrones AS (
			SELECT * FROM park_index_10
			UNION ALL
			SELECT * FROM park_index_9
		),
		measure_stats as (
			SELECT city,zoom,percentile_cont(0.25) WITHIN GROUP (ORDER BY park_index) as q1, percentile_cont(0.75) WITHIN GROUP (ORDER BY park_index) as q3
			FROM park_index_isochrones
			GROUP BY 1,2),
		data_table AS (
			SELECT city,h3,zoom,GREATEST(LEAST(park_index,q3+1.5*(q3-q1)),q1-1.5*(q3-q1)) AS park_index
			FROM park_index_isochrones
			JOIN measure_stats USING(city,zoom)),
		park_max_min AS (
			SELECT city,zoom,MAX(park_index) AS max_park_index, MIN(park_index) AS min_park_index FROM data_table GROUP BY 1,2
		)
	SELECT city,zoom,h3, CAST(100*(park_index-min_park_index)/(max_park_index-min_park_index) AS smallint) AS park_index
	FROM data_table
	JOIN park_max_min USING(city,zoom));

CREATE INDEX IF NOT EXISTS park_index_isochrones_city_h3_idx
    ON park_index_isochrones (city,h3);
