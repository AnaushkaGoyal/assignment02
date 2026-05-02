/*
  With a query, find out how many census block groups Penn's main campus
  fully contains.

  We define Penn's campus using the PWD parcels dataset by selecting parcels
  whose owner1 field contains 'UNIV OF PENN' or 'TRUSTEES OF THE UNIVERSITY
  OF PENNSYLVANIA', then taking the union of those parcels (ST_Union) and
  checking how many census block groups are fully contained (ST_Covers) within
  that boundary.
*/

with

penn_campus as (
    select st_union(geog::geometry) as geog
    from phl.pwd_parcels
    where
        owner1 like '%UNIV OF PENN%'
        or owner1 like '%TRUSTEES OF THE UNIVERSITY OF PENNSYLVANIA%'
)

select count(*) as count_block_groups
from census.blockgroups_2020 as bg
cross join penn_campus
where st_intersects(bg.geog::geometry, penn_campus.geog);

