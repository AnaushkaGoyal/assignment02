/*
  Build a description (stop_desc) for each rail stop using nearby PWD parcels,
  PostGIS functions (ST_Distance, ST_Azimuth), and PostgreSQL string functions.

  The description format is:
    "X meters [direction] of [nearest parcel address]"
  where direction is derived from the azimuth between the rail stop and the
  nearest parcel.
*/

with

nearest_parcel as (
    select
        rs.stop_id,
        rs.stop_name,
        rs.stop_lon,
        rs.stop_lat,
        p.address,
        round(st_distance(
            rs.geog,
            p.geog
        )::numeric) as dist_meters,
        degrees(st_azimuth(
            rs.geog::geometry,
            st_centroid(p.geog::geometry)
        )) as azimuth_deg
    from septa.rail_stops as rs
    cross join lateral (
        select
            parcels.address,
            parcels.geog
        from phl.pwd_parcels as parcels
        where parcels.address is not null
        order by rs.geog <-> parcels.geog
        limit 1
    ) as p
)

select
    np.stop_id::integer as stop_id,
    np.stop_name,
    np.stop_lon,
    np.stop_lat,
    np.dist_meters || ' meters '
    || case
        when np.azimuth_deg <= 22.5 or np.azimuth_deg > 337.5 then 'N'
        when np.azimuth_deg > 22.5 and np.azimuth_deg <= 67.5 then 'NE'
        when np.azimuth_deg > 67.5 and np.azimuth_deg <= 112.5 then 'E'
        when np.azimuth_deg > 112.5 and np.azimuth_deg <= 157.5 then 'SE'
        when np.azimuth_deg > 157.5 and np.azimuth_deg <= 202.5 then 'S'
        when np.azimuth_deg > 202.5 and np.azimuth_deg <= 247.5 then 'SW'
        when np.azimuth_deg > 247.5 and np.azimuth_deg <= 292.5 then 'W'
        when np.azimuth_deg > 292.5 and np.azimuth_deg <= 337.5 then 'NW'
    end
    || ' of ' || np.address as stop_desc
from nearest_parcel as np
order by np.stop_id::integer;
