DROP TABLE IF EXISTS education_tmp;
CREATE TABLE education_tmp AS (
	SELECT area_id,area,public.ST_AsGeoJSON(public.ST_Transform(geom,4326)) AS geometry
	FROM polygons
	WHERE amenity in ('university','college'));

DROP TABLE IF EXISTS education_tmp_h3;
CREATE TABLE IF NOT EXISTS education_tmp_h3
(
    area_id bigint,
    area integer,
    h3_10 h3index
);
