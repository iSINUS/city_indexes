DROP TABLE IF EXISTS city_indexes_full;
CREATE TABLE city_indexes_full AS (
	SELECT
		city,zoom,h3,
		CAST(COALESCE(living_index,0) AS smallint) AS living_index,
		CAST(COALESCE(kindergarten_index,0) AS smallint) AS kindergarten_index,
		CAST(COALESCE(school_index,0) AS smallint) AS school_index,
		CAST(COALESCE(transport_index,0) AS smallint) AS transport_index,
		CAST(COALESCE(dining_index,0) AS smallint) AS dining_index,
		CAST(COALESCE(parking_index,0) AS smallint) AS parking_index,
		CAST(COALESCE(medical_index,0) AS smallint) AS medical_index,
		CAST(COALESCE(sport_index,0) AS smallint) AS sport_index,
		CAST(COALESCE(park_index,0) AS smallint) AS park_index,
		CAST(COALESCE(education_index,0) AS smallint) AS education_index,
		h3_cell_to_boundary_geometry(h3) AS geom,
		h3_cell_to_geometry(h3) AS centroid
	FROM living_index
	FULL JOIN transport_index_full USING (city,h3,zoom)
	FULL JOIN kindergarten_index_full USING (city,h3,zoom)
	FULL JOIN school_index_full USING (city,h3,zoom)
	FULL JOIN dining_index_full USING (city,h3,zoom)
	FULL JOIN parking_index_full USING (city,h3,zoom)
	FULL JOIN medical_index_full USING (city,h3,zoom)
	FULL JOIN sport_index_full USING (city,h3,zoom)
	FULL JOIN park_index_full USING (city,h3,zoom)
	FULL JOIN education_index_full USING (city,h3,zoom));

CREATE INDEX city_indexes_full_geom_idx
  ON city_indexes_full
  USING GIST (geom);

CREATE INDEX city_indexes_full_centroid_idx
  ON city_indexes_full
  USING GIST (centroid);

CREATE INDEX city_indexes_full_city_idx
  ON city_indexes_full
  USING BTREE (city,zoom);
