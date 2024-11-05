import 'process.justfile'
import 'process_full.justfile'
import 'isochrones.justfile'
set dotenv-load
set export

default:
    just --list

[group('utils')]
pre-commit-install:
    pip install pre-commit==3.8.0 && pre-commit install

[group('utils')]
build-postgis-h3:
    docker build -f utils/Dockerfile.pgh3 -t isinus/postgis-h3:$POSTGIS_H3_VERSION .
    docker push isinus/postgis-h3:$POSTGIS_H3_VERSION

[group('utils')]
pg-hero location="LOCAL":
    echo $DATABASE_URL_{{ location }}_ADMIN && docker run --rm -ti -e DATABASE_URL=$DATABASE_URL_{{ location }}_ADMIN -p 8080:8080 --network=host ankane/pghero

prepare-all: download-osm extract-cities load-pbf fill-cities prepare-indexes prepare-indexes-full prepare-indexes-isochrones

[group('deploy')]
export-city-indexes:
    psql $DATABASE_URL --command "\\copy public.city_indexes (city, building, zoom, h3, living_index, kindergarten_index, school_index, transport_index, dining_index, parking_index, medical_index,sport_index,park_index,education_index, geom, centroid) TO 'db/city_indexes.bin' ;"
    psql $DATABASE_URL --command "\\copy public.city_indexes_full (city, zoom, h3, living_index, kindergarten_index, school_index, transport_index, dining_index, parking_index, medical_index,sport_index,park_index,education_index, geom, centroid) TO 'db/city_indexes_full.bin' ;"
    psql $DATABASE_URL --command "\\copy public.city_indexes_isochrones (city, building, zoom, h3, living_index, kindergarten_index, school_index, transport_index, dining_index, parking_index, medical_index,sport_index,park_index,education_index, geom, centroid) TO 'db/city_indexes_isochrones.bin' ;"


[group('deploy')]
deploy-city-indexes location="LOCALSERVER": export-city-indexes
    psql $DATABASE_URL_{{ location }} -a -q -f sql_deploy/city_indexes_migrate.sql
    psql $DATABASE_URL_{{ location }} --command "\\copy public.city_indexes (city, building, zoom, h3, living_index, kindergarten_index, school_index, transport_index, dining_index, parking_index, medical_index,sport_index,park_index,education_index, geom, centroid) FROM 'db/city_indexes.bin' ;"
    psql $DATABASE_URL_{{ location }} --command "\\copy public.city_indexes_full (city, zoom, h3, living_index, kindergarten_index, school_index, transport_index, dining_index, parking_index, medical_index,sport_index,park_index,education_index, geom, centroid) FROM 'db/city_indexes_full.bin' ;"
    psql $DATABASE_URL_{{ location }} --command "\\copy public.city_indexes_isochrones (city, building, zoom, h3, living_index, kindergarten_index, school_index, transport_index, dining_index, parking_index, medical_index,sport_index,park_index,education_index, geom, centroid) FROM 'db/city_indexes_isochrones.bin' ;"
    psql $DATABASE_URL_{{ location }} --command "VACUUM ANALYZE public.city_indexes;"
    psql $DATABASE_URL_{{ location }} --command "VACUUM ANALYZE public.city_indexes_full;"
    psql $DATABASE_URL_{{ location }} --command "VACUUM ANALYZE public.city_indexes_isochrones;"
    psql $DATABASE_URL_{{ location }} --command "VACUUM ANALYZE public.spatial_ref_sys;"

[group('deploy')]
deploy-site:
    cp -r local/static/* local-server/static/
    # Replace protocols and server
    sed -e 's/http:\/\/localhost/https:\/\/city-indexes.online/g' local/static/index.html > local-server/static/index.html
    sed -i -e 's/http:\/\//https:\/\//g' local-server/static/index.html
    sed -e 's/http:\/\/localhost/https:\/\/city-indexes.online/g' local/static/script/city-indexes.js > local-server/static/script/city-indexes.js
    sed -i -e 's/http:\/\//https:\/\//g' local-server/static/script/city-indexes.js

[group('deploy')]
cache-warmup:
    python utils/cache_warmup.py
