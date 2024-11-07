DROP TABLE IF EXISTS cities_tmp;
CREATE TABLE cities_tmp AS (
  SELECT
    JSON_AGG(ROW_TO_JSON(t)) AS cities
  FROM
    (
      SELECT
        city_ru AS name_ru,
        city AS name_en,
        ARRAY[public.ST_x (public.ST_transform (geom_center, 4326)), public.ST_y (public.ST_transform (geom_center, 4326))] AS coordinates
      FROM cities
      ORDER BY name_ru
    ) AS t (name_ru, name_en, coordinates));
