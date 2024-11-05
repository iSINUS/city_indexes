UPDATE living_index_isochrones SET geom=ST_SetSRID(geom,4326);

CREATE INDEX IF NOT EXISTS living_index_isochrones_distance_idx
    ON living_index_isochrones (distance);
