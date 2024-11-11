DROP TABLE IF EXISTS medical_index_isochrones;
CREATE TABLE medical_index_isochrones AS (
	WITH
		medical_prepared AS (
			SELECT b.city, a.h3 AS h3,b.area_id,b.mult,MIN(aa.distance) AS distance
			FROM living_index a
			JOIN living_index_isochrones aa USING (h3)
			JOIN medical b ON ST_WITHIN(b.centroid,aa.geom) AND a.city=b.city
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL AND a.zoom=10 AND aa.distance<=(CASE b.mult WHEN 2 THEN 30 ELSE 100 END)
			GROUP BY 1,2,3,4),
		medical_index_10 AS (
			SELECT city,h3,10::SMALLINT AS zoom, SUM(POWER(((CASE mult WHEN 2 THEN 31 ELSE 101 END)-distance),2)*mult) AS medical_index
			FROM medical_prepared
			GROUP BY 1,2),
		medical_index_9 AS (
			SELECT city,h3_cell_to_parent(h3,9) AS h3, 9::SMALLINT AS zoom, SUM(POWER(((CASE mult WHEN 2 THEN 31 ELSE 101 END)-distance),2)*mult) AS medical_index
			FROM medical_prepared
			GROUP BY 1,2),
		medical_index_isochrones AS (
			SELECT * FROM medical_index_10
			UNION ALL
			SELECT * FROM medical_index_9
		),
		measure_stats as (
			SELECT city,zoom,percentile_cont(0.25) WITHIN GROUP (ORDER BY medical_index) as q1, percentile_cont(0.75) WITHIN GROUP (ORDER BY medical_index) as q3
			FROM medical_index_isochrones
			GROUP BY 1,2),
		data_table AS (
			SELECT city,h3,zoom,GREATEST(LEAST(medical_index,q3+1.5*(q3-q1)),q1-1.5*(q3-q1)) AS medical_index
			FROM medical_index_isochrones
			JOIN measure_stats USING(city,zoom)),
		medical_max_min AS (
			SELECT city,zoom,MAX(medical_index) AS max_medical_index, MIN(medical_index) AS min_medical_index FROM data_table GROUP BY 1,2
		)
	SELECT
		city,zoom,h3,
		CASE WHEN max_medical_index>min_medical_index THEN CAST(100*(medical_index-min_medical_index)/(max_medical_index-min_medical_index) AS smallint) ELSE 100::smallint END AS medical_index
	FROM data_table
	JOIN medical_max_min USING(city,zoom));

CREATE INDEX IF NOT EXISTS medical_index_isochrones_city_h3_idx
    ON medical_index_isochrones (city,h3);
