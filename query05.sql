/*
  Rate neighborhoods by their bus stop accessibility for wheelchairs.
  Use OpenDataPhilly's neighborhood dataset along with SEPTA GTFS bus feed.

  Accessibility metric: ratio of wheelchair-accessible bus stops to total bus
  stops in a neighborhood, weighted by total stop count to penalize
  neighborhoods with very few stops. The metric is:
    (num_accessible / total_stops) * ln(1 + total_stops)
  This rewards both a high accessibility ratio AND a higher density of stops.

  GTFS wheelchair_boarding values:
    0 = no accessibility information
    1 = some vehicles at this stop can be boarded by a rider in a wheelchair
    2 = wheelchair boarding is not possible at this stop

  We treat wheelchair_boarding = 1 as accessible, and 0 or 2 as inaccessible.
*/

with

neighborhood_stops as (
    select
        n.name as neighborhood_name,
        count(*) filter (where s.wheelchair_boarding = 1) as num_bus_stops_accessible,
        count(*) filter (where s.wheelchair_boarding = 0 or s.wheelchair_boarding = 2) as num_bus_stops_inaccessible
    from phl.neighbourhoods as n
    inner join septa.bus_stops as s
        on st_intersects(s.geog, n.geog)
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
order by accessibility_metric desc;
