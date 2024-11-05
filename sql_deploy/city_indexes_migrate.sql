DROP TABLE IF EXISTS city_indexes;

CREATE TABLE IF NOT EXISTS city_indexes
(
    city text,
    building text,
    zoom smallint,
    h3 h3index,
    living_index smallint,
    kindergarten_index smallint,
    school_index smallint,
    transport_index smallint,
    dining_index smallint,
    parking_index smallint,
    medical_index smallint,
    sport_index smallint,
    park_index smallint,
    education_index smallint,
    geom geometry,
    centroid geometry
);

CREATE INDEX IF NOT EXISTS city_indexes_centroid_idx
    ON city_indexes USING gist (centroid);

CREATE INDEX IF NOT EXISTS city_indexes_city_idx
  ON city_indexes USING BTREE (city,building,zoom);

CREATE INDEX IF NOT EXISTS city_indexes_geom_idx
    ON public.city_indexes USING gist (geom);

CREATE OR REPLACE FUNCTION convert_to_int(text)
  RETURNS int
  LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE AS
$func$
BEGIN
   IF $1 = '' THEN
      RETURN 0;
   ELSIF $1 !~ '^[+-]*\d+$' THEN
      RETURN 0;
   ELSE
      RETURN LEFT($1,1)||RIGHT($1,1)::smallint;
   END IF;
END
$func$;

CREATE OR REPLACE
    FUNCTION city_indexes(z integer, x integer, y integer, query_params json)
    RETURNS bytea AS $$
DECLARE
  mvt bytea;
BEGIN
  SELECT INTO mvt public.ST_AsMVT(tile, 'city_indexes', 4096, 'geom') FROM (
    SELECT
      public.ST_AsMVTGeom(
          public.ST_Transform(public.ST_CurveToLine(geom), 3857),
          public.ST_TileEnvelope(z, x, y),
          4096, 64, true) AS geom, city_index, living_index, kindergarten_index, school_index, transport_index, parking_index, dining_index, medical_index,sport_index,park_index,education_index
    FROM (
		WITH
			city_index AS (
				SELECT
					*,
					(100-living_index)*LEAST(GREATEST(convert_to_int(query_params->>'living_index_importance'),-5),5) +
					kindergarten_index*LEAST(GREATEST(convert_to_int(query_params->>'kindergarten_index_importance'),-5),5) +
					school_index*LEAST(GREATEST(convert_to_int(query_params->>'school_index_importance'),-5),5) +
					transport_index*LEAST(GREATEST(convert_to_int(query_params->>'transport_index_importance'),-5),5) +
					parking_index*LEAST(GREATEST(convert_to_int(query_params->>'parking_index_importance'),-5),5) +
					dining_index*LEAST(GREATEST(convert_to_int(query_params->>'dining_index_importance'),-5),5) +
					medical_index*LEAST(GREATEST(convert_to_int(query_params->>'medical_index_importance'),-5),5) +
					sport_index*LEAST(GREATEST(convert_to_int(query_params->>'sport_index_importance'),-5),5) +
					park_index*LEAST(GREATEST(convert_to_int(query_params->>'park_index_importance'),-5),5) +
					education_index*LEAST(GREATEST(convert_to_int(query_params->>'education_index_importance'),-5),5) AS city_index
				FROM city_indexes
				WHERE
					((query_params->>'bbox' IS NULL) OR public.ST_Within(centroid,public.ST_Transform(public.ST_GeomFromGeoJSON(query_params->>'bbox'),4326))) AND
					city = COALESCE(query_params->>'city','Minsk') AND zoom = (CASE WHEN z<12 THEN 9 ELSE 10 END) AND building = COALESCE(query_params->>'building','*')),
			index_max_min AS (
			  SELECT *, MAX(city_index) OVER() AS max_city_index, MIN(city_index) OVER() AS min_city_index FROM city_index)
		SELECT
			h3,(100-living_index) AS living_index, kindergarten_index, school_index, transport_index, parking_index, dining_index, medical_index,sport_index,park_index,education_index,
			CASE WHEN max_city_index>min_city_index THEN CAST(ROUND(100*(city_index-min_city_index)/(max_city_index-min_city_index)) AS smallint) ELSE 100::smallint END AS city_index,
			geom
		FROM index_max_min
	)
    WHERE geom && public.ST_Transform(public.ST_TileEnvelope(z, x, y), 4326)
  ) as tile WHERE geom IS NOT NULL;

  RETURN mvt;
END
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

DROP TABLE IF EXISTS city_indexes_full;

CREATE TABLE IF NOT EXISTS city_indexes_full
(
    city text,
    zoom smallint,
    h3 h3index,
    living_index smallint,
    kindergarten_index smallint,
    school_index smallint,
    transport_index smallint,
    dining_index smallint,
    parking_index smallint,
    medical_index smallint,
    sport_index smallint,
    park_index smallint,
    education_index smallint,
    geom geometry,
    centroid geometry
);

CREATE INDEX IF NOT EXISTS city_indexes_full_centroid_idx
    ON city_indexes_full USING gist (centroid);

CREATE INDEX IF NOT EXISTS city_indexes_full_city_idx
  ON city_indexes_full USING BTREE (city,zoom);

CREATE INDEX IF NOT EXISTS city_indexes_full_geom_idx
    ON public.city_indexes_full USING gist (geom);

CREATE OR REPLACE
    FUNCTION city_indexes_full(z integer, x integer, y integer, query_params json)
    RETURNS bytea AS $$
DECLARE
  mvt bytea;
BEGIN
  SELECT INTO mvt public.ST_AsMVT(tile, 'city_indexes_full', 4096, 'geom') FROM (
    SELECT
      public.ST_AsMVTGeom(
          public.ST_Transform(public.ST_CurveToLine(geom), 3857),
          public.ST_TileEnvelope(z, x, y),
          4096, 64, true) AS geom, city_index, living_index, kindergarten_index, school_index, transport_index, parking_index, dining_index, medical_index,sport_index,park_index,education_index
    FROM (
		WITH
			city_index AS (
				SELECT
					*,
          (100-living_index)*LEAST(GREATEST(convert_to_int(query_params->>'living_index_importance'),-5),5) +
					kindergarten_index*LEAST(GREATEST(convert_to_int(query_params->>'kindergarten_index_importance'),-5),5) +
					school_index*LEAST(GREATEST(convert_to_int(query_params->>'school_index_importance'),-5),5) +
					transport_index*LEAST(GREATEST(convert_to_int(query_params->>'transport_index_importance'),-5),5) +
					parking_index*LEAST(GREATEST(convert_to_int(query_params->>'parking_index_importance'),-5),5) +
					dining_index*LEAST(GREATEST(convert_to_int(query_params->>'dining_index_importance'),-5),5) +
					medical_index*LEAST(GREATEST(convert_to_int(query_params->>'medical_index_importance'),-5),5) +
					sport_index*LEAST(GREATEST(convert_to_int(query_params->>'sport_index_importance'),-5),5) +
					park_index*LEAST(GREATEST(convert_to_int(query_params->>'park_index_importance'),-5),5) +
					education_index*LEAST(GREATEST(convert_to_int(query_params->>'education_index_importance'),-5),5) AS city_index
				FROM city_indexes_full
				WHERE
					((query_params->>'bbox' IS NULL) OR public.ST_Within(centroid,public.ST_Transform(public.ST_GeomFromGeoJSON(query_params->>'bbox'),4326))) AND
					city = COALESCE(query_params->>'city','Minsk') AND zoom = (CASE WHEN z<12 THEN 9 ELSE 10 END)),
			index_max_min AS (
			  SELECT *, MAX(city_index) OVER() AS max_city_index, MIN(city_index) OVER() AS min_city_index FROM city_index)
		SELECT
			h3,(100-living_index) AS living_index, kindergarten_index, school_index, transport_index, parking_index, dining_index, medical_index,sport_index,park_index,education_index,
			CASE WHEN max_city_index>min_city_index THEN CAST(ROUND(100*(city_index-min_city_index)/(max_city_index-min_city_index)) AS smallint) ELSE 100::smallint END AS city_index,
			geom
		FROM index_max_min
	)
    WHERE geom && public.ST_Transform(public.ST_TileEnvelope(z, x, y), 4326)
  ) as tile WHERE geom IS NOT NULL;

  RETURN mvt;
END
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

DROP TABLE IF EXISTS city_indexes_isochrones;

CREATE TABLE IF NOT EXISTS city_indexes_isochrones
(
    city text,
    building text,
    zoom smallint,
    h3 h3index,
    living_index smallint,
    kindergarten_index smallint,
    school_index smallint,
    transport_index smallint,
    dining_index smallint,
    parking_index smallint,
    medical_index smallint,
    sport_index smallint,
    park_index smallint,
    education_index smallint,
    geom geometry,
    centroid geometry
);

CREATE INDEX IF NOT EXISTS city_indexes_isochrones_centroid_idx
    ON city_indexes_isochrones USING gist (centroid);

CREATE INDEX IF NOT EXISTS city_indexes_isochrones_city_idx
  ON city_indexes_isochrones USING BTREE (city,building,zoom);

CREATE INDEX IF NOT EXISTS city_indexes_isochrones_geom_idx
    ON public.city_indexes_isochrones USING gist (geom);

CREATE OR REPLACE
    FUNCTION city_indexes_isochrones(z integer, x integer, y integer, query_params json)
    RETURNS bytea AS $$
DECLARE
  mvt bytea;
BEGIN
  SELECT INTO mvt public.ST_AsMVT(tile, 'city_indexes_isochrones', 4096, 'geom') FROM (
    SELECT
      public.ST_AsMVTGeom(
          public.ST_Transform(public.ST_CurveToLine(geom), 3857),
          public.ST_TileEnvelope(z, x, y),
          4096, 64, true) AS geom, city_index, living_index, kindergarten_index, school_index, transport_index, parking_index, dining_index, medical_index,sport_index,park_index,education_index
    FROM (
		WITH
			city_index AS (
				SELECT
					*,
					(100-living_index)*LEAST(GREATEST(convert_to_int(query_params->>'living_index_importance'),-5),5) +
					kindergarten_index*LEAST(GREATEST(convert_to_int(query_params->>'kindergarten_index_importance'),-5),5) +
					school_index*LEAST(GREATEST(convert_to_int(query_params->>'school_index_importance'),-5),5) +
					transport_index*LEAST(GREATEST(convert_to_int(query_params->>'transport_index_importance'),-5),5) +
					parking_index*LEAST(GREATEST(convert_to_int(query_params->>'parking_index_importance'),-5),5) +
					dining_index*LEAST(GREATEST(convert_to_int(query_params->>'dining_index_importance'),-5),5) +
					medical_index*LEAST(GREATEST(convert_to_int(query_params->>'medical_index_importance'),-5),5) +
					sport_index*LEAST(GREATEST(convert_to_int(query_params->>'sport_index_importance'),-5),5) +
					park_index*LEAST(GREATEST(convert_to_int(query_params->>'park_index_importance'),-5),5) +
					education_index*LEAST(GREATEST(convert_to_int(query_params->>'education_index_importance'),-5),5) AS city_index
				FROM city_indexes_isochrones
				WHERE
					((query_params->>'bbox' IS NULL) OR public.ST_Within(centroid,public.ST_Transform(public.ST_GeomFromGeoJSON(query_params->>'bbox'),4326))) AND
					city = COALESCE(query_params->>'city','Minsk') AND zoom = (CASE WHEN z<12 THEN 9 ELSE 10 END) AND building = COALESCE(query_params->>'building','*')),
			index_max_min AS (
			  SELECT *, MAX(city_index) OVER() AS max_city_index, MIN(city_index) OVER() AS min_city_index FROM city_index)
		SELECT
			h3,(100-living_index) AS living_index, kindergarten_index, school_index, transport_index, parking_index, dining_index, medical_index,sport_index,park_index,education_index,
			CASE WHEN max_city_index>min_city_index THEN CAST(ROUND(100*(city_index-min_city_index)/(max_city_index-min_city_index)) AS smallint) ELSE 100::smallint END AS city_index,
			geom
		FROM index_max_min
	)
    WHERE geom && public.ST_Transform(public.ST_TileEnvelope(z, x, y), 4326)
  ) as tile WHERE geom IS NOT NULL;

  RETURN mvt;
END
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;
