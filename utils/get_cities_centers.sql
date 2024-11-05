DROP TABLE IF EXISTS cities_tmp;
CREATE TABLE cities_tmp AS (
  SELECT
    JSON_AGG(ROW_TO_JSON(t)) AS cities
  FROM
    (
      SELECT
        tags ->> 'name:ru' AS name_ru,
        REPLACE(REPLACE(COALESCE(tags ->> 'name:en',tags ->> 'name'),' ','-'),'''','') AS name_en,
        ARRAY[public.ST_x (public.ST_transform (geom, 4326)), public.ST_y (public.ST_transform (geom, 4326))] AS coordinates
      FROM points
      WHERE tags ->> 'place' = 'city'
      ORDER BY tags ->> 'name:ru'
    ) AS t (name_ru, name_en, coordinates));
