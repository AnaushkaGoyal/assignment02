/*
  Using the bus_shapes, bus_routes, and bus_trips tables from GTFS bus feed,
  find the two routes with the longest trips.
*/

with

shape_lengths as (
    select
        shape_id,
        st_length(
            st_makeline(
                st_makepoint(shape_pt_lon, shape_pt_lat)
                order by shape_pt_sequence
            )::geography
        ) as shape_length
    from septa.bus_shapes
    group by shape_id
),

distinct_trip_shapes as (
    select distinct
        trips.route_id,
        trips.trip_headsign,
        trips.shape_id
    from septa.bus_trips as trips
),

ranked_trips as (
    select
        dts.route_id,
        dts.trip_headsign,
        sl.shape_length,
        row_number() over (
            order by sl.shape_length desc
        ) as rn
    from distinct_trip_shapes as dts
    inner join shape_lengths as sl
        on dts.shape_id = sl.shape_id
)

select
    routes.route_short_name,
    rt.trip_headsign,
    round(rt.shape_length)::integer as shape_length
from ranked_trips as rt
inner join septa.bus_routes as routes
    on rt.route_id = routes.route_id
where rt.rn <= 2
order by rt.shape_length desc;
