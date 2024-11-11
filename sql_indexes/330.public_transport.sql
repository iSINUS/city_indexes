DROP TABLE IF EXISTS transport_index_isochrones;
CREATE TABLE transport_index_isochrones AS (
	WITH
		transport_prepared AS (
			SELECT b.city, a.h3 AS h3,b.node_id,b.routes_count,b.mult,b.routes_length,MIN(aa.distance) AS distance
			FROM living_index a
			JOIN living_index_isochrones aa USING (h3)
			JOIN public_transport b ON ST_WITHIN(b.centroid,aa.geom) AND a.city=b.city
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL AND a.zoom=10 AND aa.distance<=10
			GROUP BY 1,2,3,4,5,6),
		transport_index_10 AS (
			SELECT city,h3,10::SMALLINT AS zoom, SUM(POWER((11-distance),2)*routes_count*mult*routes_length) AS transport_index
			FROM transport_prepared
			GROUP BY 1,2),
		transport_index_9 AS (
			SELECT city,h3_cell_to_parent(h3,9) AS h3, 9::SMALLINT AS zoom, SUM(POWER((11-distance),2)*routes_count*mult*routes_length) AS transport_index
			FROM transport_prepared
			GROUP BY 1,2),
		transport_index_isochrones AS (
			SELECT * FROM transport_index_10
			UNION ALL
			SELECT * FROM transport_index_9
		),
		measure_stats as (
			SELECT city,zoom,percentile_cont(0.25) WITHIN GROUP (ORDER BY transport_index) as q1, percentile_cont(0.75) WITHIN GROUP (ORDER BY transport_index) as q3
			FROM transport_index_isochrones
			GROUP BY 1,2),
		data_table AS (
			SELECT city,h3,zoom,GREATEST(LEAST(transport_index,q3+1.5*(q3-q1)),q1-1.5*(q3-q1)) AS transport_index
			FROM transport_index_isochrones
			JOIN measure_stats USING(city,zoom)),
		transport_max_min AS (
			SELECT city,zoom,MAX(transport_index) AS max_transport_index, MIN(transport_index) AS min_transport_index FROM data_table GROUP BY 1,2
		)
	SELECT
		city,zoom,h3,
		CASE WHEN max_transport_index>min_transport_index THEN CAST(100*(transport_index-min_transport_index)/(max_transport_index-min_transport_index) AS smallint) ELSE 100::smallint END AS transport_index
	FROM data_table
	JOIN transport_max_min USING(city,zoom));

CREATE INDEX IF NOT EXISTS transport_index_isochrones_city_h3_idx
    ON transport_index_isochrones (city,h3);
