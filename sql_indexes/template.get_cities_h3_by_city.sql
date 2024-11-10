DROP TABLE IF EXISTS city_h3;
CREATE TABLE city_h3 AS (
SELECT city,h3_10,h3_cell_to_parent(h3_10,9)AS h3_9,h3_grid_disk(h3_10,${SQL_INDEX_RADIUS}) AS h3_10_ FROM (
	SELECT city,h3_polygon_to_cells(geom, 10) AS h3_10 FROM cities WHERE city='${SQL_INDEX_CITY}'));
