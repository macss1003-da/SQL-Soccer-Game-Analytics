-- result: coverage_audit
-- One output row per league-season; no views required.
-- The ordered-pair diagnostic tests an OBSERVED two-round structure only.
-- It does not verify official competition formats or full-season coverage.
-- Example: Belgium 2013/2014 passes with only four observed teams.
WITH team_matches AS (
    SELECT league_id, season, home_team_api_id AS team_id FROM "Match"
    UNION ALL
    SELECT league_id, season, away_team_api_id FROM "Match"
), team_counts AS (
    SELECT league_id, season, team_id, COUNT(*) AS games
    FROM team_matches GROUP BY league_id, season, team_id
), team_summary AS (
    SELECT league_id, season, COUNT(*) AS observed_teams,
           MIN(games) AS min_team_games, MAX(games) AS max_team_games
    FROM team_counts GROUP BY league_id, season
), pairs AS (
    SELECT league_id, season, home_team_api_id, away_team_api_id, COUNT(*) AS n
    FROM "Match"
    GROUP BY league_id, season, home_team_api_id, away_team_api_id
), pair_summary AS (
    SELECT league_id, season, COUNT(*) AS ordered_pairs,
           MIN(n) AS min_pair_rows, MAX(n) AS max_pair_rows, SUM(n) AS matches
    FROM pairs GROUP BY league_id, season
), dates AS (
    SELECT league_id, season, MIN(date(date)) AS first_date,
           MAX(date(date)) AS last_date, MIN(stage) AS first_stage,
           MAX(stage) AS last_stage
    FROM "Match" GROUP BY league_id, season
)
SELECT l.name AS league, t.league_id, t.season, p.matches, t.observed_teams,
       t.min_team_games, t.max_team_games, p.ordered_pairs,
       p.min_pair_rows, p.max_pair_rows, d.first_date, d.last_date,
       d.first_stage, d.last_stage,
       CASE WHEN p.matches=t.observed_teams*(t.observed_teams-1)
                 AND p.ordered_pairs=t.observed_teams*(t.observed_teams-1)
                 AND p.min_pair_rows=1 AND p.max_pair_rows=1
            THEN 1 ELSE 0 END AS observed_double_round_robin
FROM team_summary AS t
JOIN pair_summary AS p USING (league_id, season)
JOIN dates AS d USING (league_id, season)
JOIN League AS l ON l.id=t.league_id
ORDER BY l.name, t.season;
