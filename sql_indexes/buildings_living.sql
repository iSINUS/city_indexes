-- All buidigns for living
CREATE TABLE buildings AS (
WITH
	bulding_types AS (SELECT UNNEST(ARRAY['apartments','detached','dormitory','house','residential','barracks','bungalow','cabin','annexe','semidetached_house'])),
	bulding_parts AS (
		SELECT a.area_id, b.area_id AS part_id
		FROM polygons a
		JOIN polygons b ON public.ST_WITHIN(b.geom,a.geom)
		WHERE b.building_part='yes'
		AND a.building IN (SELECT * FROM bulding_types)),
	residential AS (
		SELECT b.area_id
		FROM polygons a
		JOIN polygons b ON public.ST_WITHIN(b.geom,a.geom)
		WHERE b.building='yes'
		AND a.landuse = 'residential')
SELECT *
FROM polygons
WHERE
	(building IN (SELECT * FROM bulding_types) AND area_id NOT IN (SELECT area_id FROM bulding_parts)
	OR (building_levels IS NOT NULL
		AND ((building IN (SELECT * FROM bulding_types) AND area_id NOT IN (SELECT area_id FROM bulding_parts))
			OR (building_part='yes' AND area_id in (SELECT part_id FROM bulding_parts))))
	OR (building='yes' AND area_id IN (SELECT * FROM residential) AND area<1000.0 AND (building_levels IS NULL OR building_levels<4) AND tags<>'{}'::jsonb AND "name" IS NULL))
	AND amenity IS NULL
);
