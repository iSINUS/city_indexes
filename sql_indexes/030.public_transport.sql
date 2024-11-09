DROP TABLE IF EXISTS public_transport;
CREATE TABLE public_transport AS (
	WITH
		routes_unnest AS (
			SELECT relation_id, unnest(members) as members FROM routes
		),
		routes_line AS (
			SELECT relation_id, ST_MakeLine(n.geom) AS geom
			FROM routes_unnest r
			JOIN points n ON r.members=n.node_id
			GROUP BY relation_id),
		transport AS (
			SELECT
				DISTINCT
				a.node_id,
				b.relation_id,
				CAST(ROUND(ST_Length(l.geom)) AS bigint) AS route_length
			FROM points a
 			LEFT JOIN routes_unnest b ON a.node_id = b.members
			LEFT JOIN routes_line l ON b.relation_id = l.relation_id
			WHERE a.public_transport='platform'),
		final_transport AS (
			SELECT
				a.node_id,
				a.geom,
				(CASE WHEN a.subway IS NULL THEN 1 ELSE 10 END) AS mult,
				COUNT(b.relation_id)+1 AS routes_count,
				COALESCE(SUM(b.route_length),1) AS routes_length,
				h3_lat_lng_to_cell(public.ST_Transform(a.geom,4326), 10) AS h3_10
			FROM points a
 			JOIN transport b ON a.node_id = b.node_id
			GROUP BY 1,2,3),
		additional_h3 AS (
			SELECT *,
				h3_cell_to_geometry(h3_10) AS centroid,
				h3_cell_to_parent(h3_10,9) AS h3_9
			FROM final_transport
			WHERE h3_10 IS NOT NULL)
	SELECT *,
		get_city(centroid) AS city
	FROM additional_h3);

CREATE INDEX IF NOT EXISTS public_transport_city_h3_10_idx
    ON public_transport ((city IS NOT NULL),(h3_10 IS NOT NULL));

DROP TABLE IF EXISTS transport_index;
CREATE TABLE transport_index AS (
	WITH
		transport_index_10 AS (
			SELECT b.city, a.h3, 10::SMALLINT AS zoom,SUM(POWER((8-h3_grid_distance(a.h3,b.h3_10)),2)*b.routes_count*b.mult*b.routes_length) AS transport_index
			FROM living_index a
			JOIN public_transport b ON h3_grid_distance(a.h3,b.h3_10)<8 AND a.city=b.city
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL AND a.zoom=10
			GROUP BY 1,2),
		transport_index_9 AS (
			SELECT b.city, h3_cell_to_parent(a.h3,9)AS h3, 9::SMALLINT AS zoom,SUM(POWER((8-h3_grid_distance(a.h3,b.h3_10)),2)*b.routes_count*b.mult*b.routes_length) AS transport_index
			FROM living_index a
			JOIN public_transport b ON h3_grid_distance(a.h3,b.h3_10)<8 AND a.city=b.city
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL AND a.zoom=10
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

CREATE INDEX IF NOT EXISTS transport_index_city_h3_idx
    ON transport_index (city,h3);
