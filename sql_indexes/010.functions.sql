CREATE OR REPLACE FUNCTION get_city(shape geometry) RETURNS TEXT
    LANGUAGE 'plpgsql'
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
DECLARE
	answer TEXT;
BEGIN
	SELECT city
	FROM (
		SELECT city
		FROM cities
		WHERE public.ST_WITHIN(shape,geom)
		ORDER BY city LIMIT 1
	) INTO answer;

	RETURN answer;
END;
$BODY$;

CREATE OR REPLACE FUNCTION get_h3_index(shape geometry, index integer, is_process boolean)
 	RETURNS h3index AS $$
DECLARE
	h3_index h3index;
BEGIN
	SELECT h3
	FROM (
		SELECT h3, public.ST_AREA(public.ST_INTERSECTION(shape,public.ST_TRANSFORM(h3_cells_to_multi_polygon_geometry(ARRAY[h3]),3857)))/public.ST_AREA(shape) AS intersection_area
		FROM (SELECT DISTINCT h3_cell_to_parent(h3_polygon_to_cells(public.ST_Transform(shape,4326), 15), index) AS h3)
		ORDER BY intersection_area DESC LIMIT 1
	) WHERE is_process INTO h3_index;

	RETURN h3_index;
END;
$$ LANGUAGE plpgsql IMMUTABLE;



CREATE INDEX IF NOT EXISTS polygons_amenity_idx
    ON polygons (amenity);
CREATE INDEX IF NOT EXISTS polygons_leisure_idx
    ON polygons (leisure);
CREATE INDEX IF NOT EXISTS polygons_leisure_natural_area_idx
    ON polygons (leisure,"natural",area);
CREATE INDEX IF NOT EXISTS polygons_building_idx
    ON polygons (building);
CREATE INDEX IF NOT EXISTS polygons_building_part_idx
    ON polygons (building_part);
CREATE INDEX IF NOT EXISTS polygons_building_amenity_idx
    ON polygons (building_part,building,(building_levels IS NOT NULL),(amenity IS NULL));

CREATE INDEX IF NOT EXISTS points_public_transport_idx
    ON points (public_transport);
