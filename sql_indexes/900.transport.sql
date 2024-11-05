DROP TABLE IF EXISTS transport_index_full;
CREATE TABLE transport_index_full AS (
	WITH
		transport_index_10 AS (
			SELECT a.city, a.h3_10 AS h3, 10::SMALLINT AS zoom, SUM(POWER((8-h3_grid_distance(a.h3_10,b.h3_10)),2)*b.routes_count*b.mult*b.routes_length) AS transport_index
			FROM city_h3 a
			JOIN public_transport b ON a.city=b.city AND b.h3_10=a.h3_10_
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL
			GROUP BY 1,2),
		transport_index_9 AS (
			SELECT a.city, a.h3_9 AS h3, 9::SMALLINT AS zoom, SUM(POWER((8-h3_grid_distance(a.h3_10,b.h3_10)),2)*b.routes_count*b.mult*b.routes_length) AS transport_index
			FROM city_h3 a
			JOIN public_transport b ON a.city=b.city AND b.h3_10=a.h3_10_
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL
			GROUP BY 1,2),
		transport_index AS (
			SELECT * FROM transport_index_10
			UNION ALL
			SELECT * FROM transport_index_9),
		measure_stats as (
			SELECT city,zoom,percentile_cont(0.25) WITHIN GROUP (ORDER BY transport_index) as q1, percentile_cont(0.75) WITHIN GROUP (ORDER BY transport_index) as q3
			FROM transport_index
			GROUP BY 1,2),
		data_table AS (
			SELECT city,h3,zoom,GREATEST(LEAST(transport_index,q3+1.5*(q3-q1)),q1-1.5*(q3-q1)) AS transport_index
			FROM transport_index
			JOIN measure_stats USING(city,zoom)),
		transport_max_min AS (
			SELECT city,zoom,MAX(transport_index) AS max_transport_index, MIN(transport_index) AS min_transport_index FROM data_table GROUP BY 1,2
		)
	SELECT
		city,zoom,h3,
		CASE WHEN max_transport_index>min_transport_index THEN CAST(100*(transport_index-min_transport_index)/(max_transport_index-min_transport_index) AS smallint) ELSE 100::smallint END AS transport_index
	FROM data_table
	JOIN transport_max_min USING(city,zoom));

CREATE INDEX IF NOT EXISTS transport_index_full_city_h3_idx
    ON transport_index_full (city,h3,zoom);
