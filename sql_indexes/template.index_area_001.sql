DROP TABLE IF EXISTS ${SQL_INDEX_NAME};
CREATE TABLE ${SQL_INDEX_NAME} AS (
	WITH
		additional_h3 AS (
			SELECT *,
				h3_cell_to_geometry(h3_10) AS centroid,
				h3_cell_to_parent(h3_10,9) AS h3_9
			FROM objects_tmp_h3
			WHERE h3_10 IS NOT NULL)
	SELECT *,
		get_city(centroid) AS city
	FROM additional_h3);

CREATE INDEX IF NOT EXISTS ${SQL_INDEX_NAME}_h3_10_idx
    ON ${SQL_INDEX_NAME}  ((city IS NOT NULL),(h3_10 IS NOT NULL));

DROP TABLE IF EXISTS ${SQL_INDEX_NAME}_index;
CREATE TABLE ${SQL_INDEX_NAME}_index AS (
	WITH
		${SQL_INDEX_NAME}_index_10 AS (
			SELECT b.city, a.h3, 10::SMALLINT AS zoom,SUM(b.area*POWER((${SQL_INDEX_RADIUS}-h3_grid_distance(a.h3,b.h3_10)),2)) AS ${SQL_INDEX_NAME}_index
			FROM living_index a
			JOIN ${SQL_INDEX_NAME} b ON h3_grid_distance(a.h3,b.h3_10)<${SQL_INDEX_RADIUS} AND a.city=b.city
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL AND a.zoom=10
			GROUP BY 1,2),
		${SQL_INDEX_NAME}_index_9 AS (
			SELECT b.city, h3_cell_to_parent(a.h3,9) AS h3, 9::SMALLINT AS zoom,SUM(b.area*POWER((${SQL_INDEX_RADIUS}-h3_grid_distance(a.h3,b.h3_10)),2)) AS ${SQL_INDEX_NAME}_index
			FROM living_index a
			JOIN ${SQL_INDEX_NAME} b ON h3_grid_distance(a.h3,b.h3_10)<${SQL_INDEX_RADIUS} AND a.city=b.city
			WHERE b.h3_10 IS NOT NULL AND b.city IS NOT NULL AND a.zoom=10
			GROUP BY 1,2),
		${SQL_INDEX_NAME}_index AS (
			SELECT * FROM ${SQL_INDEX_NAME}_index_10
			UNION ALL
			SELECT * FROM ${SQL_INDEX_NAME}_index_9
		),
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

CREATE INDEX IF NOT EXISTS ${SQL_INDEX_NAME}_index_city_h3_idx
    ON ${SQL_INDEX_NAME}_index (city,h3);
