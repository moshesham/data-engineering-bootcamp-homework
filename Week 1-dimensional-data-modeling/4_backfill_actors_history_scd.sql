WITH change_view AS (
    SELECT actorid
        , actor
        , current_year
        , quality_class
        , is_active
        , LAG(quality_class, 1, quality_class) OVER (PARTITION BY actorid ORDER BY current_year) <> quality_class AS did_change_quality_class
        , LAG(is_active, 1, is_active) OVER (PARTITION BY actorid ORDER BY current_year) <> is_active AS did_change_is_active
    FROM actors
),
cumulative_change_view AS (
SELECT *
    , SUM(CAST(did_change_quality_class AS INT)) OVER (PARTITION BY actorid ORDER BY current_year) as cumulative_change_quality_class
    , SUM(CAST(did_change_is_active AS INT)) OVER (PARTITION BY actorid ORDER BY current_year) as cumulative_change_is_active
FROM change_view
),
aggregate AS (
    SELECT actorid
        , actor
        , cumulative_change_quality_class
        , cumulative_change_is_active
        , quality_class
        , is_active
        , MIN(current_year) as start_year
        , MAX(current_year) as end_year
    FROM cumulative_change_view
    GROUP BY actorid
        , actor
        , cumulative_change_quality_class
        , cumulative_change_is_active
        , quality_class
        , is_active
)
INSERT INTO actors_history_scd (actorid, actor, quality_class, is_active, start_year, end_year)
SELECT actorid
    , actor
    , quality_class
    , is_active
    , start_year
    , end_year
FROM aggregate
