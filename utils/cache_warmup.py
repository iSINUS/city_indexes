import argparse

import mercantile
import pandas as pd
import requests
from pandarallel import pandarallel
from shapely import from_geojson

# requests.packages.urllib3.disable_warnings()
pandarallel.initialize(progress_bar=False, nb_workers=4)

# Combinations of all parameters
# PARAMETERS = set()
# for i in range(1024):
#     PARAMETERS.add("{0:0>10b}".format(i))

# Only simple combinations
PARAMETERS = {
    "1111111111",
    "1000000000",
    "1100000000",
    "1010000000",
    "1001000000",
    "1000100000",
    "1000010000",
    "1000001000",
    "1000000100",
    "1000000010",
    "1000000001",
    "0100000000",
    "0010000000",
    "0001000000",
    "0000100000",
    "0000010000",
    "0000001000",
    "0000000100",
    "0000000010",
    "0000000001",
}

TILES = {"city_indexes", "city_indexes_full", "city_indexes_isochrones"}


def _cache_warmup(row, host, tilename):
    for z in range(9, 13):
        i = 0
        # Get all tiles for city bbox
        for tile in mercantile.tiles(*row["bbox"], z):
            i += 1
            for parameter in PARAMETERS:
                try:
                    requests.get(
                        f"{host}tiles/{tilename}/{tile.z}/{tile.x}/{tile.y}?city={row['city']}&"
                        f"living_index_importance={parameter[0]}&kindergarten_index_importance={parameter[1]}&school_index_importance={parameter[2]}&transport_index_importance={parameter[3]}&"
                        f"parking_index_importance={parameter[4]}&dining_index_importance={parameter[5]}&medical_index_importance={parameter[6]}&sport_index_importance={parameter[7]}&"
                        f"park_index_importance={parameter[8]}&education_index_importance={parameter[9]}&building=*",
                        headers={"referer": host},
                        timeout=120,
                        # verify=False,
                    )
                except Exception:
                    pass
        print(tilename, row["city"], z, i)


def cache_warmup(host: str):
    """Preload nginx cache for main cities and parameters."""

    df = pd.read_csv("utils/cities_list_cache")
    # Get city bounding box
    df["bbox"] = df["relation_id"].parallel_map(
        lambda x: from_geojson(requests.get(f"https://polygons.openstreetmap.fr/get_geojson.py?id={x}&params=0").text).bounds
    )
    for tile in TILES:
        df.parallel_apply(lambda row: _cache_warmup(row, host, tile), axis=1)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", type=str, default="https://city-indexes.online/")
    args = parser.parse_args()
    cache_warmup(args.host)
