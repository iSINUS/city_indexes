import h3
import pandas as pd
import pyproj
import ujson
from pandarallel import pandarallel
from shapely import MultiPolygon, area, from_geojson, intersection, to_geojson
from shapely.geometry import Polygon
from shapely.ops import transform

pandarallel.initialize(progress_bar=False)
wgs84 = pyproj.CRS("EPSG:4326")
utm = pyproj.CRS("EPSG:3857")
project = pyproj.Transformer.from_crs(wgs84, utm, always_xy=True).transform


def main():
    """Map apartments to H3."""

    def _to_h3_10(row):
        result = set()
        if isinstance(row["original_geometry"], MultiPolygon):
            geoms = [ujson.loads(to_geojson(geom)) for geom in row["original_geometry"].geoms]
            areas = [transform(project, geom).area for geom in row["original_geometry"].geoms]
        else:
            geoms = [row["geometry"]]
            areas = [row["area"]]
        for i, geom in enumerate(geoms):
            if areas[i] < 100000:
                result = result | {h3.h3_to_parent(h3_15, 10) for h3_15 in h3.polyfill_geojson(geom, 15)}
            else:
                result = result | h3.polyfill_geojson(geom, 10)
        return result

    df = pd.read_csv("data/apartments_tmp.csv")
    df["original_geometry"] = df["geometry"].parallel_map(from_geojson)
    df["geometry"] = df["geometry"].parallel_map(lambda x: ujson.loads(x))
    df["h3_10s"] = df["h3_10s"] = df.parallel_apply(_to_h3_10, axis=1)
    df = df.explode("h3_10s")
    df = df[~df["h3_10s"].isnull()]
    df["h3_geometry"] = df["h3_10s"].parallel_map(lambda x: Polygon(tuple(coord[::-1] for coord in h3.h3_to_geo_boundary(x))))
    df["coverage"] = df.parallel_apply(lambda row: area(intersection(row["original_geometry"], row["h3_geometry"])) / row["area"], axis=1)
    df = df.reset_index()
    df = df.loc[df.groupby(["area_id"])["coverage"].idxmax()]
    df["building_levels"] = df["building_levels"].fillna(1).astype(int)
    df[["area_id", "building", "building_levels", "area", "h3_10s"]].to_csv("data/apartments_tmp_h3.csv", header=False, index=False)


if __name__ == "__main__":
    main()
