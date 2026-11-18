-- Run all statements in the SAME database connection as later queries.
-- TEMP views leave source tables unchanged and vanish when the connection closes.
-- Rerun this file after reopening the database. No Write Changes is needed.
-- First run 01: dimension keys must be unique and relations must resolve.
-- The verified upload has 25,979 eligible rows; a new version may differ.
DROP VIEW IF EXISTS temp.v_team_matches;
DROP VIEW IF EXISTS temp.v_matches;

CREATE TEMP VIEW v_matches AS
SELECT m.match_api_id, m.country_id, c.name AS country,
       m.league_id, l.name AS league, m.season,
       CAST(substr(m.season,1,4) AS INTEGER) AS season_start_year,
       m.stage, date(m.date) AS match_date,
       m.home_team_api_id, h.team_long_name AS home_team,
       m.away_team_api_id, a.team_long_name AS away_team,
       m.home_team_goal AS home_goals, m.away_team_goal AS away_goals,
       m.home_team_goal + m.away_team_goal AS total_goals,
       CASE WHEN m.home_team_goal>m.away_team_goal THEN 'home_win'
            WHEN m.home_team_goal<m.away_team_goal THEN 'away_win'
            ELSE 'draw' END AS result
FROM "Match" AS m
JOIN Country AS c ON c.id=m.country_id
JOIN League AS l ON l.id=m.league_id AND l.country_id=m.country_id
JOIN Team AS h ON h.team_api_id=m.home_team_api_id
JOIN Team AS a ON a.team_api_id=m.away_team_api_id
WHERE m.match_api_id IS NOT NULL
  AND m.home_team_api_id<>m.away_team_api_id
  AND m.season IS NOT NULL AND trim(m.season)<>''
  AND date(m.date) IS NOT NULL
  AND typeof(m.home_team_goal) IN ('integer','real')
  AND typeof(m.away_team_goal) IN ('integer','real')
  AND m.home_team_goal>=0 AND m.away_team_goal>=0
  AND m.home_team_goal=CAST(m.home_team_goal AS INTEGER)
  AND m.away_team_goal=CAST(m.away_team_goal AS INTEGER);

CREATE TEMP VIEW v_team_matches AS
SELECT match_api_id, country_id, country, league_id, league,
       season, season_start_year, stage, match_date,
       home_team_api_id AS team_api_id, home_team AS team,
       away_team_api_id AS opponent_api_id, away_team AS opponent,
       'home' AS venue, home_goals AS goals_for, away_goals AS goals_against,
       home_goals-away_goals AS goal_difference,
       CASE result WHEN 'home_win' THEN 3 WHEN 'draw' THEN 1 ELSE 0 END AS points,
       CASE result WHEN 'home_win' THEN 'W' WHEN 'draw' THEN 'D' ELSE 'L' END AS outcome
FROM v_matches
UNION ALL
SELECT match_api_id, country_id, country, league_id, league,
       season, season_start_year, stage, match_date,
       away_team_api_id, away_team, home_team_api_id, home_team,
       'away', away_goals, home_goals, away_goals-home_goals,
       CASE result WHEN 'away_win' THEN 3 WHEN 'draw' THEN 1 ELSE 0 END,
       CASE result WHEN 'away_win' THEN 'W' WHEN 'draw' THEN 'D' ELSE 'L' END
FROM v_matches;
