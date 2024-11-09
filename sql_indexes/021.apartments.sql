CREATE INDEX IF NOT EXISTS apartments_tmp_h3_building_h3_10_idx
    ON apartments (building,(building IS NOT NULL),(h3_10 IS NOT NULL));

DROP TABLE IF EXISTS apartments;
CREATE TABLE apartments AS (
	WITH
		additional_h3 AS (
			SELECT *,
			h3_cell_to_geometry(h3_10) AS centroid,
			h3_cell_to_parent(h3_10,9) AS h3_9
			FROM apartments_tmp_h3
			WHERE h3_10 IS NOT NULL AND (building in ('apartments','dormitory','residential','barracks') OR building IS NULL))
	SELECT *,
		get_city(centroid) AS city
	FROM additional_h3);

CREATE INDEX IF NOT EXISTS apartments_city_h3_10_idx
    ON apartments ((city IS NOT NULL),(h3_10 IS NOT NULL));
CREATE INDEX IF NOT EXISTS apartments_city_h3_9_idx
    ON apartments ((city IS NOT NULL),(h3_9 IS NOT NULL));


DROP TABLE IF EXISTS living_index;
CREATE TABLE living_index AS (
	WITH
		living_index_10 AS (
			SELECT city, h3_10 AS h3, 10::SMALLINT AS zoom,SUM(COALESCE(building_levels,1)*area) AS living_index
			FROM apartments
			WHERE h3_10 IS NOT NULL AND city IS NOT NULL
			GROUP BY 1,2),
		living_index_9 AS (
			SELECT city, h3_9 AS h3, 9::SMALLINT AS zoom,SUM(COALESCE(building_levels,1)*area) AS living_index
			FROM apartments
			WHERE h3_10 IS NOT NULL AND city IS NOT NULL
			GROUP BY 1,2),
		living_index AS (
			SELECT * FROM living_index_10
			UNION ALL
			SELECT * FROM living_index_9
		),
		measure_stats as (
			SELECT city,zoom,percentile_cont(0.25) WITHIN GROUP (ORDER BY living_index) as q1, percentile_cont(0.75) WITHIN GROUP (ORDER BY living_index) as q3
			FROM living_index
			GROUP BY 1,2),
		data_table AS (
			SELECT city,h3,zoom,GREATEST(LEAST(living_index,q3+1.5*(q3-q1)),q1-1.5*(q3-q1)) AS living_index
			FROM living_index
			JOIN measure_stats USING(city,zoom)),
		living_max_min AS (
			SELECT city,zoom,MAX(living_index) AS max_living_index, MIN(living_index) AS min_living_index FROM data_table GROUP BY 1,2
		)
	SELECT city,zoom,h3, CAST(100*(living_index-min_living_index)/(max_living_index-min_living_index) AS smallint) AS living_index
	FROM data_table
	JOIN living_max_min USING(city,zoom));

CREATE INDEX IF NOT EXISTS living_index_city_h3_idx
    ON living_index (city,h3);
CREATE INDEX IF NOT EXISTS living_index_zoom_idx
    ON living_index (zoom);

DROP TABLE IF EXISTS living_index_building;
CREATE TABLE living_index_building AS (
	WITH
		living_index_10 AS (
			SELECT city,COALESCE(CASE building WHEN 'residential' THEN 'apartments' ELSE building END,'unknown') AS building, h3_10 AS h3, 10::SMALLINT AS zoom,SUM(COALESCE(building_levels,1)*area) AS living_index
			FROM apartments
			WHERE h3_10 IS NOT NULL AND city IS NOT NULL
			GROUP BY 1,2,3),
		living_index_9 AS (
			SELECT city, COALESCE(CASE building WHEN 'residential' THEN 'apartments' ELSE building END,'unknown') AS building, h3_9 AS h3, 9::SMALLINT AS zoom,SUM(COALESCE(building_levels,1)*area) AS living_index
			FROM apartments
			WHERE h3_10 IS NOT NULL AND city IS NOT NULL
			GROUP BY 1,2,3),
		living_index_building AS (
			SELECT * FROM living_index_10
			UNION ALL
			SELECT * FROM living_index_9
		),
		measure_stats as (
			SELECT city,building,zoom,percentile_cont(0.25) WITHIN GROUP (ORDER BY living_index) as q1, percentile_cont(0.75) WITHIN GROUP (ORDER BY living_index) as q3
			FROM living_index_building
			GROUP BY 1,2,3),
		data_table AS (
			SELECT city,building,h3,zoom,GREATEST(LEAST(living_index,q3+1.5*(q3-q1)),q1-1.5*(q3-q1)) AS living_index
			FROM living_index_building
			JOIN measure_stats USING(city,building,zoom)),
		living_max_min AS (
			SELECT city,building,zoom,MAX(living_index) AS max_living_index, MIN(living_index) AS min_living_index FROM data_table GROUP BY 1,2,3
		)
	SELECT
		city,building,zoom,h3,
		CASE WHEN max_living_index>min_living_index THEN CAST(100*(living_index-min_living_index)/(max_living_index-min_living_index) AS smallint) ELSE 100::smallint END AS living_index
	FROM data_table
	JOIN living_max_min USING(city,building,zoom));

CREATE INDEX IF NOT EXISTS living_index_city_building_h3_idx
    ON living_index_building (city,building,h3);
