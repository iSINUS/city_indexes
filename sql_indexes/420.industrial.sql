DROP TABLE IF EXISTS industrial_index_isochrones;
CREATE TABLE industrial_index_isochrones AS (
	WITH
		industrial_prepared AS (
			SELECT b.city, a.h3 AS h3,b.area_id,b.area,MIN(aa.distance) AS distance
			FROM living_index a
			JOIN living_index_isochrones aa USING (h3)
			JOIN industrial b ON ST_WITHIN(b.centroid,aa.geom) AND a.city=b.city
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL AND a.zoom=10 AND aa.distance<=30
			GROUP BY 1,2,3,4),
		industrial_index_10 AS (
			SELECT city,h3,10::SMALLINT AS zoom, SUM(area*POWER((31-distance),2)) AS industrial_index
			FROM industrial_prepared
			GROUP BY 1,2),
		industrial_index_9 AS (
			SELECT city,h3_cell_to_parent(h3,9) AS h3, 9::SMALLINT AS zoom, SUM(area*POWER((31-distance),2)) AS industrial_index
			FROM industrial_prepared
			GROUP BY 1,2),
		industrial_index_isochrones AS (
			SELECT * FROM industrial_index_10
			UNION ALL
			SELECT * FROM industrial_index_9
		),
		measure_stats as (
			SELECT city,zoom,percentile_cont(0.25) WITHIN GROUP (ORDER BY industrial_index) as q1, percentile_cont(0.75) WITHIN GROUP (ORDER BY industrial_index) as q3
			FROM industrial_index_isochrones
			GROUP BY 1,2),
		data_table AS (
			SELECT city,h3,zoom,GREATEST(LEAST(industrial_index,q3+1.5*(q3-q1)),q1-1.5*(q3-q1)) AS industrial_index
			FROM industrial_index_isochrones
			JOIN measure_stats USING(city,zoom)),
		industrial_max_min AS (
			SELECT city,zoom,MAX(industrial_index) AS max_industrial_index, MIN(industrial_index) AS min_industrial_index FROM data_table GROUP BY 1,2
		)
	SELECT
		city,zoom,h3,
		CASE WHEN max_industrial_index>min_industrial_index THEN CAST(100*(industrial_index-min_industrial_index)/(max_industrial_index-min_industrial_index) AS smallint) ELSE 100::smallint END AS industrial_index
	FROM data_table
	JOIN industrial_max_min USING(city,zoom));

CREATE INDEX IF NOT EXISTS industrial_index_isochrones_city_h3_idx
    ON industrial_index_isochrones (city,h3);
