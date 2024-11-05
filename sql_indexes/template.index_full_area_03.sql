CREATE INDEX IF NOT EXISTS ${SQL_INDEX_NAME}_index_full_city_h3_idx
    ON ${SQL_INDEX_NAME}_index_full (city,h3,zoom);
