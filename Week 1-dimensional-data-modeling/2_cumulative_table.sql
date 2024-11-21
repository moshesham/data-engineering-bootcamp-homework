INSERT INTO actors (actorid, actor, films, current_year, quality_class, is_active)
WITH last_year AS (
	SELECT *
	FROM actors
	WHERE current_year = 1973
),
this_year AS (
	SELECT
	    actorid
	    , actor
		, year
		, AVG(rating) as avg_rating -- or SUM(rating * votes) / sum(votes)
		, ARRAY_AGG(
			ROW(film, year, votes, rating, filmid)::film_stats
		) AS films
	FROM actor_films
	WHERE year = 1974
	GROUP BY actorid, actor, year
)
SELECT
    COALESCE(l.actorid, t.actorid) AS actorid
    , COALESCE(l.actor, t.actor) AS actor
	, COALESCE(l.films, ARRAY[]::film_stats[]) || CASE WHEN t.year IS NOT NULL THEN t.films
                ELSE ARRAY[]::film_stats[] END
		AS films
    , COALESCE(t.year, l.current_year+1) AS current_year
    , CASE WHEN t.avg_rating IS NOT NULL THEN
	 		(CASE
				WHEN t.avg_rating > 8 THEN 'star'
				WHEN t.avg_rating > 7 THEN 'good'
				WHEN t.avg_rating > 6 THEN 'average'
			    ELSE 'bad'
	 		    END
	 		)::quality_class
		ELSE l.quality_class END
		AS quality_class
	, t.year IS NOT NULL as is_active
FROM last_year l FULL OUTER JOIN this_year t
ON l.actorid = t.actorid

