DROP TABLE IF EXISTS objects_tmp;

CREATE TABLE
    objects_tmp AS (
        (SELECT
            area_id,
            area,
            public.ST_AsGeoJSON (public.ST_Transform (geom, 4326)) AS geometry
        FROM
            polygons
        WHERE
            shop in (
                'alcohol',
                'bakery',
                'beverages',
                'brewing_supplies',
                'butcher',
                'cheese',
                'chocolate',
                'coffee',
                'confectionery',
                'convenience',
                'dairy',
                'deli',
                'farm',
                'food',
                'frozen_food',
                'greengrocer',
                'health_food',
                'ice_cream',
                'nuts',
                'pasta',
                'pastry',
                'seafood',
                'spices',
                'tea',
                'tortilla',
                'water',
                'wine',
                'general',
                'mall',
                'supermarket',
                'wholesale'
            ))
        UNION ALL
        (SELECT
            node_id,
            50::smallint as area,
            public.ST_AsGeoJSON (public.ST_Transform (public.ST_ForceRHR(public.ST_Buffer(geom,4,'quad_segs=2')), 4326)) AS geometry
        FROM
            points
        WHERE
            shop in (
                'alcohol',
                'bakery',
                'beverages',
                'brewing_supplies',
                'butcher',
                'cheese',
                'chocolate',
                'coffee',
                'confectionery',
                'convenience',
                'dairy',
                'deli',
                'farm',
                'food',
                'frozen_food',
                'greengrocer',
                'health_food',
                'ice_cream',
                'nuts',
                'pasta',
                'pastry',
                'seafood',
                'spices',
                'tea',
                'tortilla',
                'water',
                'wine',
                'general',
                'mall',
                'supermarket',
                'wholesale'
            ))
    );

DROP TABLE IF EXISTS objects_tmp_h3;

CREATE TABLE IF NOT EXISTS
    objects_tmp_h3 (area_id bigint, area integer, h3_10 h3index);
