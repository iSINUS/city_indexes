[group('process-isochrones')]
valhalla filename="cities":
    #!/usr/bin/env bash
    set -euo pipefail

    psql $DATABASE_URL -a -q -f sql_indexes/300.isochrones.sql
    cat utils/{{ filename }} | while read line_city || [[ -n $line_city ]];
    do
        city=($line_city)
        echo ${city[0]} ${city[1]}

        cp osm-data/${city[0]}.pbf osm-data/valhalla/${city[0]}.pbf

        psql $DATABASE_URL --command "\\copy (SELECT DISTINCT h3 FROM living_index WHERE city='${city[1]}' AND zoom=10) TO 'data/h3_isochrones_tmp.csv' DELIMITER ',' CSV HEADER QUOTE '\"' ESCAPE '\"';"

        docker restart valhalla || docker run -dt --name valhalla -p 8002:8002 -e server_threads=8 -v $PWD/osm-data/valhalla:/custom_files ghcr.io/gis-ops/docker-valhalla/valhalla:3.5.0
        until (curl -sS --fail -o /dev/null "http://localhost:8002/status"); do sleep 10; done;
        docker restart valhalla
        until (curl -sS --fail -o /dev/null "http://localhost:8002/status"); do sleep 10; done;

        python utils/apartments_isochrones.py
        psql $DATABASE_URL --command "\\copy living_index_isochrones FROM 'data/h3_isochrones_tmp_result.csv' DELIMITER ',' CSV QUOTE '\"' ESCAPE '\"';"

        docker exec valhalla bash -c "sudo rm -f *.txt"
        docker exec valhalla bash -c "sudo rm -f *.pbf"
        docker exec valhalla bash -c "sudo rm -f valhalla_tiles.tar"
        docker exec valhalla bash -c "sudo rm -f -R valhalla_tiles"
    done
    docker stop valhalla
    psql $DATABASE_URL -a -q -f sql_indexes/998.isochrones.sql
    psql $DATABASE_URL --command "VACUUM ANALYZE  living_index_isochrones;"

[group('process-isochrones')]
prepare-indexes-isochrones-objects:
    psql $DATABASE_URL -a -q -f sql_indexes/330.public_transport.sql
    psql $DATABASE_URL -a -q -f sql_indexes/340.kindergarten.sql
    psql $DATABASE_URL -a -q -f sql_indexes/350.school.sql
    psql $DATABASE_URL -a -q -f sql_indexes/360.dining.sql
    psql $DATABASE_URL -a -q -f sql_indexes/370.parking.sql
    psql $DATABASE_URL -a -q -f sql_indexes/380.medical.sql
    psql $DATABASE_URL -a -q -f sql_indexes/390.sport.sql
    psql $DATABASE_URL -a -q -f sql_indexes/400.park.sql
    psql $DATABASE_URL -a -q -f sql_indexes/410.education.sql

[group('process-isochrones')]
prepare-indexes-isochrones-final:
    psql $DATABASE_URL -a -q -f sql_indexes/999.city_indexes_isochrones.sql

[group('process-isochrones')]
prepare-indexes-isochrones: valhalla prepare-indexes-isochrones-objects prepare-indexes-isochrones-final
