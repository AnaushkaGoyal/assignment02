/*
  What are the bottom five neighborhoods according to your accessibility metric?
*/


with

neighborhood_stops as (
    select
        n.name as neighborhood_name,
        count(*) filter (where s.wheelchair_boarding = 1) as num_bus_stops_accessible,
        count(*) filter (where s.wheelchair_boarding = 0 or s.wheelchair_boarding = 2) as num_bus_stops_inaccessible
    from phl.neighbourhoods as n
    inner join septa.bus_stops as s
        on st_within(s.geog::geometry, n.geog::geometry)
    group by n.name
)

select
    neighborhood_name,
    num_bus_stops_accessible::integer,
    num_bus_stops_inaccessible::integer,
    round(
        (
            num_bus_stops_accessible::numeric
            / (num_bus_stops_accessible + num_bus_stops_inaccessible)
        )
        * ln(1 + num_bus_stops_accessible + num_bus_stops_inaccessible)::numeric,
        2
    ) as accessibility_metric
from neighborhood_stops
order by accessibility_metric asc
limit 5;
