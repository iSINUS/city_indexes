DROP TABLE IF EXISTS city_indexes_isochrones;
CREATE TABLE city_indexes_isochrones AS (
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
		CAST(COALESCE(industrial_index,0) AS smallint) AS industrial_index,
		CAST(COALESCE(shop_food_index,0) AS smallint) AS shop_food_index,
		CAST(COALESCE(shop_nonfood_index,0) AS smallint) AS shop_nonfood_index,
		h3_cell_to_boundary_geometry(h3) AS geom,
		h3_cell_to_geometry(h3) AS centroid
	FROM living_index
	FULL JOIN transport_index_isochrones USING (city,h3)
	FULL JOIN kindergarten_index_isochrones USING (city,h3)
	FULL JOIN school_index_isochrones USING (city,h3)
	FULL JOIN dining_index_isochrones USING (city,h3)
	FULL JOIN parking_index_isochrones USING (city,h3)
	FULL JOIN medical_index_isochrones USING (city,h3)
	FULL JOIN sport_index_isochrones USING (city,h3)
	FULL JOIN park_index_isochrones USING (city,h3)
	FULL JOIN education_index_isochrones USING (city,h3)
	FULL JOIN industrial_index_isochrones USING (city,h3)
	FULL JOIN shop_food_index_isochrones USING (city,h3)
	FULL JOIN shop_nonfood_index_isochrones USING (city,h3))
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
		CAST(COALESCE(industrial_index,0) AS smallint) AS industrial_index,
		CAST(COALESCE(shop_food_index,0) AS smallint) AS shop_food_index,
		CAST(COALESCE(shop_nonfood_index,0) AS smallint) AS shop_nonfood_index,
		h3_cell_to_boundary_geometry(h3) AS geom,
		h3_cell_to_geometry(h3) AS centroid
	FROM living_index_building
	FULL JOIN transport_index_isochrones USING (city,h3)
	FULL JOIN kindergarten_index_isochrones USING (city,h3)
	FULL JOIN school_index_isochrones USING (city,h3)
	FULL JOIN dining_index_isochrones USING (city,h3)
	FULL JOIN parking_index_isochrones USING (city,h3)
	FULL JOIN medical_index_isochrones USING (city,h3)
	FULL JOIN sport_index_isochrones USING (city,h3)
	FULL JOIN park_index_isochrones USING (city,h3)
	FULL JOIN education_index_isochrones USING (city,h3)
	FULL JOIN industrial_index_isochrones USING (city,h3)
	FULL JOIN shop_food_index_isochrones USING (city,h3)
	FULL JOIN shop_nonfood_index_isochrones USING (city,h3)));

CREATE INDEX city_indexes_isochrones_geom_idx
  ON city_indexes_isochrones
  USING GIST (geom);

CREATE INDEX city_indexes_isochrones_centroid_idx
  ON city_indexes_isochrones
  USING GIST (centroid);

CREATE INDEX city_indexes_isochrones_city_idx
  ON city_indexes_isochrones
  USING BTREE (city,building,zoom);
