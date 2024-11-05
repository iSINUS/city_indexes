DROP TABLE IF EXISTS cities;
CREATE TABLE cities AS (
  WITH clear_empty AS (
    SELECT relation_id,city,geom
    FROM
    (SELECT *, ROW_NUMBER() OVER( PARTITION BY relation_id ORDER BY city ) AS row_num
    FROM cities_tmp )
    WHERE row_num = 1)
  SELECT relation_id,city,geom
  FROM
  (SELECT *, ROW_NUMBER() OVER( PARTITION BY city ORDER BY relation_id DESC) AS row_num
  FROM clear_empty )
  WHERE row_num = 1);

DROP TABLE IF EXISTS cities_tmp;
CREATE INDEX cities_geom_idx
  ON cities
  USING GIST (geom);
