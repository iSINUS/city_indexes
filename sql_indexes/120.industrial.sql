DROP TABLE IF EXISTS objects_tmp;

CREATE TABLE
    objects_tmp AS (
        SELECT
            area_id,
            area,
            public.ST_AsGeoJSON (public.ST_Transform (geom, 4326)) AS geometry
        FROM
            polygons
        WHERE
            landuse = 'industrial'
    );

DROP TABLE IF EXISTS objects_tmp_h3;

CREATE TABLE IF NOT EXISTS
    objects_tmp_h3 (area_id bigint, area integer, h3_10 h3index);
