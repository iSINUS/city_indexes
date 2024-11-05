import argparse
import json
import os

import psycopg2
import requests
from dotenv import load_dotenv

load_dotenv()


def insert_cities(var_name: str):
    """Insert multiple cities polygons into the table."""

    sql = "UPDATE cities SET geom=public.ST_GeomFromGeoJSON(%s) WHERE relation_id=%s;"
    try:
        with psycopg2.connect(os.getenv(var_name)) as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT relation_id FROM cities;")
                relation_ids = {row[0] for row in cur.fetchall()}
                print(relation_ids)

            with conn.cursor() as cur:
                for relation in relation_ids:
                    polygone = requests.get(f"https://polygons.openstreetmap.fr/get_geojson.py?id={relation}&params=0").json()
                    cur.execute(sql, (json.dumps(polygone), relation))

            # commit the changes to the database
            conn.commit()
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--db_url", type=str, default="DATABASE_URL")
    args = parser.parse_args()
    insert_cities(args.db_url)
