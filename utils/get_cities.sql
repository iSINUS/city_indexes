DROP TABLE IF EXISTS cities_tmp;
CREATE TABLE cities_tmp AS (
	SELECT relation_id, COALESCE(tags ->> 'name:en',tags ->> 'name') AS city, public.ST_TRANSFORM(geom,4326) AS geom FROM boundaries WHERE tags->>'place' = 'city'
);
