/*selects PAs that overlap with input polygon */
select ST_AsEWKT(the_geom) as arse from data_import
where the_geom && ST_GeomFromEWKT('SRID=4326;POLYGON((142 -14,150 -14,150 -23,142 -23,142 -14))')

/*selects PAs and the distance to an input polygon*/
select name_eng, ST_Distance(the_geom, ST_GeomFromEWKT('SRID=4326;POLYGON((142 -14,150 -14,150 -23,142 -23,142 -14))')) from data_import

/* selects PAs, outputs as geojson with distance that are within 50 degrees of the input polygon*/
select ST_AsGeoJson(the_geom) as PAgeom, name_eng, ST_Distance(the_geom, ST_GeomFromEWKT('SRID=4326;POLYGON((142 -14,150 -14,150 -23,142 -23,142 -14))'))   from data_import
where the_geom && ST_Buffer(ST_GeomFromEWKT('SRID=4326;POLYGON((142 -14,150 -14,150 -23,142 -23,142 -14))'),50)


