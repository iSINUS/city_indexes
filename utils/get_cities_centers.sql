DROP TABLE IF EXISTS cities_tmp;
CREATE TABLE cities_tmp AS (
  SELECT
    JSON_AGG(ROW_TO_JSON(t)) AS cities
  FROM
    (
      SELECT
        city_ru AS name_ru,
        city AS name_en,
        ARRAY[public.ST_x(geom_center), public.ST_y(geom_center)] AS coordinates
      FROM cities
      ORDER BY name_ru
    ) AS t (name_ru, name_en, coordinates));
