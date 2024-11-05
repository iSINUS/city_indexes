DROP TABLE IF EXISTS city_indexes;
CREATE TABLE city_indexes AS (
	(SELECT
		city,'*' AS building, living_index.zoom,h3,
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
	FULL JOIN transport_index USING (city,h3)
	FULL JOIN kindergarten_index USING (city,h3)
	FULL JOIN school_index USING (city,h3)
	FULL JOIN dining_index USING (city,h3)
	FULL JOIN parking_index USING (city,h3)
	FULL JOIN medical_index USING (city,h3)
	FULL JOIN sport_index USING (city,h3)
	FULL JOIN park_index USING (city,h3)
	FULL JOIN education_index USING (city,h3))
	UNION ALL
	(SELECT
		city,building, living_index_building.zoom,h3,
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
	FROM living_index_building
	FULL JOIN transport_index USING (city,h3)
	FULL JOIN kindergarten_index USING (city,h3)
	FULL JOIN school_index USING (city,h3)
	FULL JOIN dining_index USING (city,h3)
	FULL JOIN parking_index USING (city,h3)
	FULL JOIN medical_index USING (city,h3)
	FULL JOIN sport_index USING (city,h3)
	FULL JOIN park_index USING (city,h3)
	FULL JOIN education_index USING (city,h3)));

CREATE INDEX city_indexes_geom_idx
  ON city_indexes
  USING GIST (geom);

CREATE INDEX city_indexes_centroid_idx
  ON city_indexes
  USING GIST (centroid);

CREATE INDEX city_indexes_city_idx
  ON city_indexes
  USING BTREE (city,building,zoom);
