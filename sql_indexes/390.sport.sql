DROP TABLE IF EXISTS sport_index_isochrones;
CREATE TABLE sport_index_isochrones AS (
	WITH
		sport_prepared AS (
			SELECT b.city, a.h3 AS h3,b.id,MIN(aa.distance) AS distance
			FROM living_index a
			JOIN living_index_isochrones aa USING (h3)
			JOIN sport b ON ST_WITHIN(b.centroid,aa.geom) AND a.city=b.city
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL AND a.zoom=10 AND aa.distance<=10
			GROUP BY 1,2,3),
		sport_index_10 AS (
			SELECT city,h3,10::SMALLINT AS zoom, SUM(POWER((11-distance),2)) AS sport_index
			FROM sport_prepared
			GROUP BY 1,2),
		sport_index_9 AS (
			SELECT city,h3_cell_to_parent(h3,9) AS h3, 9::SMALLINT AS zoom, SUM(POWER((11-distance),2)) AS sport_index
			FROM sport_prepared
			GROUP BY 1,2),
		sport_index_isochrones AS (
			SELECT * FROM sport_index_10
			UNION ALL
			SELECT * FROM sport_index_9
		),
		measure_stats as (
			SELECT city,zoom,percentile_cont(0.25) WITHIN GROUP (ORDER BY sport_index) as q1, percentile_cont(0.75) WITHIN GROUP (ORDER BY sport_index) as q3
			FROM sport_index_isochrones
			GROUP BY 1,2),
		data_table AS (
			SELECT city,h3,zoom,GREATEST(LEAST(sport_index,q3+1.5*(q3-q1)),q1-1.5*(q3-q1)) AS sport_index
			FROM sport_index_isochrones
			JOIN measure_stats USING(city,zoom)),
		sport_max_min AS (
			SELECT city,zoom,MAX(sport_index) AS max_sport_index, MIN(sport_index) AS min_sport_index FROM data_table GROUP BY 1,2
		)
	SELECT city,zoom,h3, CAST(100*(sport_index-min_sport_index)/(max_sport_index-min_sport_index) AS smallint) AS sport_index
	FROM data_table
	JOIN sport_max_min USING(city,zoom));

CREATE INDEX IF NOT EXISTS sport_index_isochrones_city_h3_idx
    ON sport_index_isochrones (city,h3);
