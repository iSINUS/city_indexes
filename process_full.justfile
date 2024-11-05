

[group('process-full')]
prepare-indexes-full-radius radius="7":
    #!/usr/bin/env bash
    set -euo pipefail

    SQL_INDEX_RADIUS={{ radius }} envsubst < sql_indexes/template.get_cities_h3.sql > sql_indexes/get_cities_h3_{{ radius }}.tmp.sql
    psql $DATABASE_URL -a -q --command "DROP TABLE IF EXISTS city_h3;"
    psql $DATABASE_URL -a -q -f sql_indexes/get_cities_h3_{{ radius }}.tmp.sql

    cat sql_indexes/indexes_{{ radius }} | while read line || [[ -n $line ]];
    do
        index_var=($line)
        echo ${index_var[0]} ${index_var[1]}
        # SQL_INDEX_SOURCE=${index_var[0]} SQL_INDEX_NAME=${index_var[1]} envsubst < sql_indexes/template.index_full.sql >> sql_indexes/900.${index_var[1]}.sql
        psql $DATABASE_URL -a -q -f sql_indexes/900.${index_var[1]}.sql
    done
    rm sql_indexes/*.tmp.sql

[group('process-full')]
prepare-indexes-full-city-16:
    #!/usr/bin/env bash
    set -euo pipefail

    cat sql_indexes/indexes_16 | while read line || [[ -n $line ]];
    do
        index_var=($line)
        SQL_INDEX_SOURCE=${index_var[0]} SQL_INDEX_NAME=${index_var[1]} envsubst < sql_indexes/template.index_full_area_01.sql > sql_indexes/${index_var[1]}_01.tmp.sql
        SQL_INDEX_SOURCE=${index_var[0]} SQL_INDEX_NAME=${index_var[1]} envsubst < sql_indexes/template.index_full_area_03.sql > sql_indexes/${index_var[1]}_03.tmp.sql
        psql $DATABASE_URL -a -q -f sql_indexes/${index_var[1]}_01.tmp.sql
    done

    cat utils/cities | while read line_city || [[ -n $line_city ]];
    do
        city=($line_city)
        echo ${city[1]}

        # Prepare city h3 in radius
        SQL_INDEX_RADIUS=16 SQL_INDEX_CITY=${city[1]} envsubst < sql_indexes/template.get_cities_h3_by_city.sql > sql_indexes/get_cities_h3.tmp.sql
        psql $DATABASE_URL -a -q -f sql_indexes/get_cities_h3.tmp.sql

        # Per index process
        cat sql_indexes/indexes_16 | while read line_index || [[ -n $line_index ]];
        do
            index_var=($line_index)
            echo ${city[1]} ${index_var[0]} ${index_var[1]}
            SQL_INDEX_RADIUS=16 SQL_INDEX_SOURCE=${index_var[0]} SQL_INDEX_NAME=${index_var[1]} SQL_INDEX_CITY=${city[1]} envsubst < sql_indexes/template.index_full_area_02.sql > sql_indexes/${index_var[1]}_02.tmp.sql
            psql $DATABASE_URL -a -q -f sql_indexes/${index_var[1]}_02.tmp.sql
        done
    done

    cat sql_indexes/indexes_16 | while read line || [[ -n $line ]];
    do
        index_var=($line)
        psql $DATABASE_URL -a -q -f sql_indexes/${index_var[1]}_03.tmp.sql
    done
    rm sql_indexes/*.tmp.sql

[group('process-full')]
prepare-indexes-full-city-40:
    #!/usr/bin/env bash
    set -euo pipefail

    cat sql_indexes/indexes_40 | while read line || [[ -n $line ]];
    do
        index_var=($line)
        SQL_INDEX_SOURCE=${index_var[0]} SQL_INDEX_NAME=${index_var[1]} envsubst < sql_indexes/template.index_full_mult_01.sql > sql_indexes/${index_var[1]}_01.tmp.sql
        SQL_INDEX_SOURCE=${index_var[0]} SQL_INDEX_NAME=${index_var[1]} envsubst < sql_indexes/template.index_full_mult_03.sql > sql_indexes/${index_var[1]}_03.tmp.sql
        psql $DATABASE_URL -a -q -f sql_indexes/${index_var[1]}_01.tmp.sql
    done

    cat utils/cities | while read line_city || [[ -n $line_city ]];
    do
        city=($line_city)
        echo ${city[1]}

        # Prepare city h3 in radius
        SQL_INDEX_RADIUS=0 SQL_INDEX_CITY=${city[1]} envsubst < sql_indexes/template.get_cities_h3_by_city.sql > sql_indexes/get_cities_h3.tmp.sql
        psql $DATABASE_URL -a -q -f sql_indexes/get_cities_h3.tmp.sql

        # Per index process
        cat sql_indexes/indexes_40 | while read line_index || [[ -n $line_index ]];
        do
            index_var=($line_index)
            echo ${city[1]} ${index_var[0]} ${index_var[1]}
            SQL_INDEX_RADIUS=8 SQL_INDEX_SOURCE=${index_var[0]} SQL_INDEX_NAME=${index_var[1]} SQL_INDEX_CITY=${city[1]} envsubst < sql_indexes/template.index_full_mult_02.sql > sql_indexes/${index_var[1]}_02.tmp.sql
            psql $DATABASE_URL -a -q -f sql_indexes/${index_var[1]}_02.tmp.sql
        done
    done

    cat sql_indexes/indexes_40 | while read line || [[ -n $line ]];
    do
        index_var=($line)
        psql $DATABASE_URL -a -q -f sql_indexes/${index_var[1]}_03.tmp.sql
    done
    rm sql_indexes/*.tmp.sql

[group('process-full')]
prepare-indexes-full-final:
    psql $DATABASE_URL -a -q -f sql_indexes/999.city_indexes_full.sql

[group('process-full')]
prepare-indexes-full: prepare-indexes-full-radius prepare-indexes-full-city-16 prepare-indexes-full-city-40 prepare-indexes-full-final
