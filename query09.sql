/*
  With a query involving PWD parcels and census block groups, find the geo_id
  of the block group that contains Meyerson Hall.
  ST_MakePoint() and functions like that are not allowed.

  Meyerson Hall is at 210 S 34TH ST, Philadelphia. We use the PWD parcels
  dataset to find the parcel for Meyerson Hall by matching the address, then
  find the block group that contains the parcel centroid.
*/

select bg.geoid as geo_id
from phl.pwd_parcels as parcels
inner join census.blockgroups_2020 as bg
    on st_within(
        st_centroid(parcels.geog::geometry),
        bg.geog::geometry
    )
where parcels.address = '220-30 S 34TH ST'
order by bg.geoid
limit 1;
