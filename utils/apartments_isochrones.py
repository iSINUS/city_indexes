import h3
import pandas as pd
import requests
import ujson
from pandarallel import pandarallel

pandarallel.initialize(progress_bar=False, nb_workers=16)

CONTOURS_DICT = {"pedestrian": [{"time": 5}, {"time": 10}, {"time": 15}, {"time": 30}], "auto": [{"time": 10}]}


def main():
    def _isochrones(row) -> dict:
        lat, lng = h3.h3_to_geo(row["h3"])
        for costing, contours in CONTOURS_DICT.items():
            json_data = {
                "polygons": True,
                "denoise": 1,
                "generalize": 100,
                "show_locations": True,
                "costing": costing,
                "costing_options": {
                    "pedestrian": {"costing": {"walking_speed": 4}, "directions": {"alternates": 0, "exclude_polygons": []}}
                },
                "contours": contours,
                "locations": [{"lon": lng, "lat": lat, "type": "break"}],
                "units": "kilometers",
            }
            result = requests.get("http://localhost:8002/isochrone", params={"json": ujson.dumps(json_data)}).json()
            for feature in result.get("features", []):
                if feature.get("properties", {}).get("contour", 0) > 0:
                    row[f"{costing}_{feature.get('properties',{}).get('contour',0)}"] = feature.get("geometry", {})
        return row

    df = pd.read_csv("data/h3_isochrones_tmp.csv")
    df = df.parallel_apply(_isochrones, axis=1)
    pd.concat(
        [
            df[["h3", f"{costing}_{contour['time']}"]]
            .rename({f"{costing}_{contour['time']}": "geom"}, axis=1)
            .assign(distance=contour["time"] if costing != "auto" else contour["time"] * 10)
            for costing, contours in CONTOURS_DICT.items()
            for contour in contours
        ]
    ).to_csv("data/h3_isochrones_tmp_result.csv", header=False, index=False)


if __name__ == "__main__":
    main()
