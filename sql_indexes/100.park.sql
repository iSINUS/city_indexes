DROP TABLE IF EXISTS park_tmp;
CREATE TABLE park_tmp AS (
	SELECT area_id,area,public.ST_AsGeoJSON(public.ST_Transform(geom,4326)) AS geometry
	FROM polygons
	WHERE (leisure in ('park','garden') OR "natural" in ('wood','beach')) AND area>0);

DROP TABLE IF EXISTS park_tmp_h3;
CREATE TABLE IF NOT EXISTS park_tmp_h3
(
    area_id bigint,
    area integer,
    h3_10 h3index
);
