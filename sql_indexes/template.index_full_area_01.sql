DROP TABLE IF EXISTS ${SQL_INDEX_NAME}_index_full;
CREATE TABLE IF NOT EXISTS ${SQL_INDEX_NAME}_index_full
(
    city text,
    zoom smallint,
    h3 h3index,
    ${SQL_INDEX_NAME}_index smallint
);
