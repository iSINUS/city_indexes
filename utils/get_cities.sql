drop table if exists cities;
create table cities as (
	with
		city_boundaries as (
			(select
				id,city,
				coalesce(tags ->> 'name:ru',tags ->> 'name') as city_ru,
				public.ST_BuildArea(geom) as geom
			from
				boundaries
			join cities_tmp on id = abs(relation_id))
			union all
			(select
				id,city,
				name as city_ru,
				public.ST_BuildArea(geom) as geom
			from
				polygons
			join cities_tmp on id = abs(area_id))),
		cities_center as (
			select
				REPLACE(REPLACE(COALESCE(tags ->> 'name:en',tags ->> 'name'),' ','-'),'''','') AS name_en,
				geom as geom_center
			from points
			where (tags ->> 'place') in ('city','town'))
	select
		city_boundaries.id, city_boundaries.city,city_boundaries.city_ru,
		public.ST_Transform(city_boundaries.geom,4326) as geom,
		public.ST_Transform(coalesce(geom_center,public.ST_Centroid(city_boundaries.geom)),4326) as geom_center
	from city_boundaries
	left join cities_center on name_en=city and (public.st_within(geom_center,geom) or public.st_distance(geom_center,geom)<12000));

create index cities_geom_idx
	on cities
	using GIST (geom);
