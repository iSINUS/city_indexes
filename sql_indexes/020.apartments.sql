DROP TABLE IF EXISTS apartments_tmp;
CREATE TABLE apartments_tmp AS (
	WITH
		bulding_parts AS (
			SELECT a.area_id, b.area_id AS part_id
			FROM polygons a
			JOIN polygons b ON public.ST_WITHIN(b.geom,a.geom)
			WHERE b.building_part='yes'
			AND a.building IN ('apartments','dormitory','residential','barracks'))
	SELECT area_id, building, building_levels, area, public.ST_AsGeoJSON(public.ST_Transform(geom,4326)) AS geometry
		FROM polygons
		WHERE
			(building IN ('apartments','dormitory','residential','barracks') AND area_id NOT IN (SELECT area_id FROM bulding_parts)
			OR (building_levels IS NOT NULL
				AND ((building IN ('apartments','dormitory','residential','barracks') AND area_id NOT IN (SELECT area_id FROM bulding_parts))
					OR (building_part='yes' AND area_id in (SELECT part_id FROM bulding_parts)))))
			AND amenity IS NULL);

DROP TABLE IF EXISTS apartments_tmp_h3;
CREATE TABLE IF NOT EXISTS apartments_tmp_h3
(
    area_id bigint,
	building text,
    building_levels integer,
    area integer,
    h3_10 h3index
);
