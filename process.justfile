[group('process')]
download-osm:
    #!/usr/bin/env bash
    set -euo pipefail

    curl -o osm-data/russia-latest.osm.pbf https://download.geofabrik.de/russia-latest.osm.pbf

    cat osm-data/countries | while read line || [[ -n $line ]];
    do
        country=($line)
        echo ${country[0]} ${country[1]}
        curl -o osm-data/${country[1]}-latest.osm.pbf https://download.geofabrik.de/${country[0]}/${country[1]}-latest.osm.pbf
    done

[group('process')]
extract-cities filename="cities":
    #!/usr/bin/env bash
    set -euo pipefail

    cat utils/{{ filename }} | while read line || [[ -n $line ]];
    do
        city=($line)
        echo $city
        curl -s -o osm-data/${city[0]}.poly "https://polygons.openstreetmap.fr/get_poly.py?id=${city[0]}&params=0"
        osmium extract --polygon osm-data/${city[0]}.poly --output=osm-data/${city[0]}.pbf --strategy=smart --overwrite osm-data/${city[2]}-latest.osm.pbf
    done
    rm osm-data/*.poly

[group('process')]
load-pbf:
    #!/usr/bin/env bash
    set -euo pipefail

    first_line=1
    cat utils/cities | while read line || [[ -n $line ]];
    do
        city=($line)
        echo $city
        if [[ $first_line -eq 1 ]]; then
            osm2pgsql -c -s osm-data/$city.pbf -O flex -S osm-data/city_districts.lua -d $DATABASE_URL
            first_line=0
        fi
        osm2pgsql -a -s osm-data/$city.pbf -O flex -S osm-data/city_districts.lua -d $DATABASE_URL
    done

[group('process')]
fill-cities:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "DROP TABLE IF EXISTS cities_tmp;CREATE TABLE cities_tmp (id INTEGER NOT NULL PRIMARY KEY, city VARCHAR(250) NOT NULL);INSERT INTO cities_tmp (id,city) VALUES" > utils/_get_cities_insert.sql

    cat utils/cities | while read line || [[ -n $line ]];
    do
        city=($line)
        echo ${city[0]} ${city[1]}
        echo "(${city[0]},'${city[1]}')," >> utils/_get_cities_insert.sql
    done
    sed '$! { P; D; }; s/.$//' utils/_get_cities_insert.sql > utils/get_cities_insert.sql
    rm utils/_get_cities_insert.sql
    psql $DATABASE_URL -a -q -f utils/get_cities_insert.sql
    psql $DATABASE_URL -a -q -f utils/get_cities.sql
    psql $DATABASE_URL -a -q -f utils/get_cities_centers.sql
    # Required for JavaScript
    psql $DATABASE_URL --command "\\copy public.cities_tmp (cities) TO 'local/static/script/cities.json' DELIMITER ';' ;"
    # List of cities to warmup cache
    # psql $DATABASE_URL --command "\\copy (SELECT city,id FROM cities ORDER BY 1) TO 'utils/cities_list_cache' DELIMITER ',' HEADER ;"

[group('process')]
prepare-indexes-functions:
    psql $DATABASE_URL -a -q -f sql_indexes/010.functions.sql

[group('process')]
prepare-indexes-apartments:
    psql $DATABASE_URL -a -q -f sql_indexes/020.apartments.sql
    psql $DATABASE_URL --command "\\copy public.apartments_tmp (area_id, building, building_levels, area, geometry) TO 'data/apartments_tmp.csv' DELIMITER ',' CSV HEADER QUOTE '\"' ESCAPE '\"';"
    python utils/apartments_to_h3.py
    psql $DATABASE_URL --command "\\copy public.apartments_tmp_h3 (area_id, building, building_levels, area, h3_10) FROM 'data/apartments_tmp_h3.csv' DELIMITER ',' CSV QUOTE '\"' ESCAPE '\"';"
    psql $DATABASE_URL -a -q -f sql_indexes/021.apartments.sql

[group('process')]
prepare-indexes-objects:
    psql $DATABASE_URL -a -q -f sql_indexes/030.public_transport.sql
    psql $DATABASE_URL -a -q -f sql_indexes/040.kindergarten.sql
    psql $DATABASE_URL -a -q -f sql_indexes/050.school.sql
    psql $DATABASE_URL -a -q -f sql_indexes/060.dining.sql
    psql $DATABASE_URL -a -q -f sql_indexes/070.parking.sql
    psql $DATABASE_URL -a -q -f sql_indexes/080.medical.sql
    psql $DATABASE_URL -a -q -f sql_indexes/090.sport.sql

[group('process')]
prepare-indexes-parks:
    psql $DATABASE_URL -a -q -f sql_indexes/100.park.sql
    psql $DATABASE_URL --command "\\copy public.park_tmp (area_id, area, geometry) TO 'data/objects_tmp.csv' DELIMITER ',' CSV HEADER QUOTE '\"' ESCAPE '\"';"
    python utils/objects_to_h3.py
    psql $DATABASE_URL --command "\\copy public.park_tmp_h3 (area_id, area, h3_10) FROM 'data/objects_tmp_h3.csv' DELIMITER ',' CSV QUOTE '\"' ESCAPE '\"';"
    psql $DATABASE_URL -a -q -f sql_indexes/101.park.sql

[group('process')]
prepare-indexes-education:
    psql $DATABASE_URL -a -q -f sql_indexes/110.education.sql
    psql $DATABASE_URL --command "\\copy public.education_tmp (area_id, area, geometry) TO 'data/objects_tmp.csv' DELIMITER ',' CSV HEADER QUOTE '\"' ESCAPE '\"';"
    python utils/objects_to_h3.py
    psql $DATABASE_URL --command "\\copy public.education_tmp_h3 (area_id, area, h3_10) FROM 'data/objects_tmp_h3.csv' DELIMITER ',' CSV QUOTE '\"' ESCAPE '\"';"
    psql $DATABASE_URL -a -q -f sql_indexes/111.education.sql

[group('process')]
prepare-indexes-final:
    psql $DATABASE_URL -a -q -f sql_indexes/999.city_indexes.sql

[group('process')]
prepare-indexes: prepare-indexes-functions prepare-indexes-apartments prepare-indexes-objects prepare-indexes-parks prepare-indexes-education prepare-indexes-final
