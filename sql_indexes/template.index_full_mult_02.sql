INSERT INTO ${SQL_INDEX_NAME}_index_full (
	WITH
		${SQL_INDEX_NAME}_index_10 AS (
			SELECT a.city, a.h3_10 AS h3, 10::SMALLINT AS zoom, SUM(POWER((${SQL_INDEX_RADIUS}*b.mult-h3_grid_distance(a.h3_10,b.h3_10)),2)*b.mult) AS ${SQL_INDEX_NAME}_index
			FROM city_h3 a
			JOIN ${SQL_INDEX_SOURCE} b ON a.city=b.city AND h3_grid_distance(a.h3_10,b.h3_10)<${SQL_INDEX_RADIUS}*b.mult
			WHERE b.h3_10 IS NOT NULL AND b.city='${SQL_INDEX_CITY}'
			GROUP BY 1,2),
		${SQL_INDEX_NAME}_index_9 AS (
			SELECT a.city, a.h3_9 AS h3, 9::SMALLINT AS zoom, SUM(POWER((${SQL_INDEX_RADIUS}*b.mult-h3_grid_distance(a.h3_10,b.h3_10)),2)*b.mult) AS ${SQL_INDEX_NAME}_index
			FROM city_h3 a
			JOIN ${SQL_INDEX_SOURCE} b ON a.city=b.city AND h3_grid_distance(a.h3_10,b.h3_10)<${SQL_INDEX_RADIUS}*b.mult
			WHERE b.h3_10 IS NOT NULL AND b.city='${SQL_INDEX_CITY}'
			GROUP BY 1,2),
		${SQL_INDEX_NAME}_index AS (
			SELECT * FROM ${SQL_INDEX_NAME}_index_10
			UNION ALL
			SELECT * FROM ${SQL_INDEX_NAME}_index_9),
		measure_stats as (
			SELECT city,zoom,percentile_cont(0.25) WITHIN GROUP (ORDER BY ${SQL_INDEX_NAME}_index) as q1, percentile_cont(0.75) WITHIN GROUP (ORDER BY ${SQL_INDEX_NAME}_index) as q3
			FROM ${SQL_INDEX_NAME}_index
			GROUP BY 1,2),
		data_table AS (
			SELECT city,h3,zoom,GREATEST(LEAST(${SQL_INDEX_NAME}_index,q3+1.5*(q3-q1)),q1-1.5*(q3-q1)) AS ${SQL_INDEX_NAME}_index
			FROM ${SQL_INDEX_NAME}_index
			JOIN measure_stats USING(city,zoom)),
		${SQL_INDEX_NAME}_max_min AS (
			SELECT city,zoom,MAX(${SQL_INDEX_NAME}_index) AS max_${SQL_INDEX_NAME}_index, MIN(${SQL_INDEX_NAME}_index) AS min_${SQL_INDEX_NAME}_index FROM data_table GROUP BY 1,2
		)
	SELECT
		city,zoom,h3,
		CASE WHEN max_${SQL_INDEX_NAME}_index>min_${SQL_INDEX_NAME}_index THEN CAST(100*(${SQL_INDEX_NAME}_index-min_${SQL_INDEX_NAME}_index)/(max_${SQL_INDEX_NAME}_index-min_${SQL_INDEX_NAME}_index) AS smallint) ELSE 100::smallint END AS ${SQL_INDEX_NAME}_index
	FROM data_table
	JOIN ${SQL_INDEX_NAME}_max_min USING(city,zoom));
