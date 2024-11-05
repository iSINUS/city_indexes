DROP TABLE IF EXISTS living_index_isochrones;
CREATE TABLE living_index_isochrones
(
    h3 h3index NOT NULL,
    geom geometry,
	distance smallint
);
