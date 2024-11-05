DROP TABLE IF EXISTS parking_index_isochrones;
CREATE TABLE parking_index_isochrones AS (
	WITH
		parking_prepared AS (
			SELECT b.city, a.h3 AS h3,b.area_id,MIN(aa.distance) AS distance
			FROM living_index a
			JOIN living_index_isochrones aa USING (h3)
			JOIN parking b ON ST_WITHIN(b.centroid,aa.geom) AND a.city=b.city
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL AND a.zoom=10 AND aa.distance<=10
			GROUP BY 1,2,3),
		parking_index_10 AS (
			SELECT city,h3,10::SMALLINT AS zoom, SUM(POWER((11-distance),2)) AS parking_index
			FROM parking_prepared
			GROUP BY 1,2),
		parking_index_9 AS (
			SELECT city,h3_cell_to_parent(h3,9) AS h3, 9::SMALLINT AS zoom, SUM(POWER((11-distance),2)) AS parking_index
			FROM parking_prepared
			GROUP BY 1,2),
		parking_index_isochrones AS (
			SELECT * FROM parking_index_10
			UNION ALL
			SELECT * FROM parking_index_9
		),
		measure_stats as (
			SELECT city,zoom,percentile_cont(0.25) WITHIN GROUP (ORDER BY parking_index) as q1, percentile_cont(0.75) WITHIN GROUP (ORDER BY parking_index) as q3
			FROM parking_index_isochrones
			GROUP BY 1,2),
		data_table AS (
			SELECT city,h3,zoom,GREATEST(LEAST(parking_index,q3+1.5*(q3-q1)),q1-1.5*(q3-q1)) AS parking_index
			FROM parking_index_isochrones
			JOIN measure_stats USING(city,zoom)),
		parking_max_min AS (
			SELECT city,zoom,MAX(parking_index) AS max_parking_index, MIN(parking_index) AS min_parking_index FROM data_table GROUP BY 1,2
		)
	SELECT city,zoom,h3, CAST(100*(parking_index-min_parking_index)/(max_parking_index-min_parking_index) AS smallint) AS parking_index
	FROM data_table
	JOIN parking_max_min USING(city,zoom));

CREATE INDEX IF NOT EXISTS parking_index_isochrones_city_h3_idx
    ON parking_index_isochrones (city,h3);
