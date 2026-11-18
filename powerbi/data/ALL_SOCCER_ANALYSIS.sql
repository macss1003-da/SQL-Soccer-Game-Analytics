-- SQL SOCCER GAME ANALYTICS | Complete reproducible analysis
-- Source: European Soccer Database, seasons 2008/2009 through 2015/2016.
-- SQLite 3.25+ (window functions). Compatible with the user's SQLite 3.46.1.
-- Open database.sqlite. Execute in one connection; views are TEMP.
-- In DB Browser, run each result query separately to inspect/export its table.
-- A single Execute All may display only the last result set.
-- Source tables are never modified. No CLI dot-commands are required.
-- Reproduce CSV/JSON exports with scripts/run_analysis.py.


-- ============================================================
-- FILE: 00_inspect_database.sql
-- ============================================================
-- result: sqlite_version
-- Run statements separately in Execute SQL.
-- Generic inspection; no soccer table names are assumed.
-- Queries 00.3 and 00.4 require SQLite >= 3.16.0.

-- 00.1
SELECT sqlite_version() AS sqlite_version;

-- result: schema_objects

-- 00.2 User tables and views.
SELECT name AS object_name, type AS object_type
FROM sqlite_master
WHERE type IN ('table', 'view')
  AND substr(name, 1, 7) <> 'sqlite_'
ORDER BY type, name;

-- result: schema_columns

-- 00.3 Columns and declared keys, not validated uniqueness.
SELECT m.name AS table_name, p.cid AS column_position,
       p.name AS column_name, p.type AS declared_type,
       p."notnull" AS declared_not_null,
       p.dflt_value AS default_value, p.pk AS primary_key_ordinal
FROM sqlite_master AS m
JOIN pragma_table_info(m.name) AS p ON 1 = 1
WHERE m.type = 'table' AND substr(m.name, 1, 7) <> 'sqlite_'
ORDER BY m.name, p.cid;

-- result: schema_foreign_keys

-- 00.4 Declared foreign keys.
-- An empty result does not rule out logical relationships.
SELECT m.name AS source_table, fk.id AS foreign_key_id,
       fk.seq AS key_column_sequence, fk."from" AS source_column,
       fk."table" AS referenced_table, fk."to" AS referenced_column
FROM sqlite_master AS m
JOIN pragma_foreign_key_list(m.name) AS fk ON 1 = 1
WHERE m.type = 'table' AND substr(m.name, 1, 7) <> 'sqlite_'
ORDER BY m.name, fk.id, fk.seq;

-- result: schema_ddl

-- 00.5 Actual CREATE TABLE definitions.
SELECT name AS table_name, sql AS create_table_sql
FROM sqlite_master
WHERE type = 'table' AND substr(name, 1, 7) <> 'sqlite_'
ORDER BY name;

-- result: table_counts

-- 00.6 Counts of all seven verified source tables.
SELECT 'Country' AS table_name, COUNT(*) AS row_count FROM Country
UNION ALL SELECT 'League', COUNT(*) FROM League
UNION ALL SELECT 'Match', COUNT(*) FROM "Match"
UNION ALL SELECT 'Team', COUNT(*) FROM Team
UNION ALL SELECT 'Player', COUNT(*) FROM Player
UNION ALL SELECT 'Player_Attributes', COUNT(*) FROM Player_Attributes
UNION ALL SELECT 'Team_Attributes', COUNT(*) FROM Team_Attributes;


-- ============================================================
-- FILE: 01_profile_core.sql
-- ============================================================
-- result: core_table_counts
-- Run after 00_inspect_database.sql and confirm the expected schema:
-- Country: id, name
-- League: id, country_id, name
-- Team: id, team_api_id, team_long_name, team_short_name
-- Match: id, match_api_id, country_id, league_id, season, date,
--        home_team_api_id, away_team_api_id, home_team_goal, away_team_goal
-- Schema verified against the uploaded database; rerun checks on new versions.
-- Run each read query separately. Do not automatically fix anomalies.

-- 01.1 Core row counts; profile other tables after confirming their names.
SELECT 'Country' AS table_name, COUNT(*) AS row_count FROM "Country"
UNION ALL SELECT 'League', COUNT(*) FROM "League"
UNION ALL SELECT 'Team', COUNT(*) FROM "Team"
UNION ALL SELECT 'Match', COUNT(*) FROM "Match";

-- result: raw_coverage

-- 01.2 Coverage without dimension joins.
-- Raw rows are not yet confirmed unique or eligible matches.
-- DISTINCT excludes NULL; date MIN/MAX ignore unparseable dates.
SELECT league_id, season, COUNT(*) AS raw_match_rows,
       COUNT(DISTINCT match_api_id) AS distinct_nonnull_match_ids,
       MIN(date("date")) AS first_parseable_match_date,
       MAX(date("date")) AS last_parseable_match_date,
       COUNT(DISTINCT home_team_api_id) AS distinct_home_teams,
       COUNT(DISTINCT away_team_api_id) AS distinct_away_teams
FROM "Match"
GROUP BY league_id, season
ORDER BY league_id, season;

-- result: core_missing_values

-- 01.3 NULL counts and blank date/season labels. Checks can overlap.
SELECT COUNT(*) AS raw_match_rows,
       COUNT(*) - COUNT(match_api_id) AS null_match_ids,
       COUNT(*) - COUNT(country_id) AS null_country_ids,
       COUNT(*) - COUNT(league_id) AS null_league_ids,
       COUNT(*) - COUNT(season) AS null_seasons,
       COUNT(CASE WHEN trim(season) = '' THEN 1 END) AS blank_seasons,
       COUNT(*) - COUNT("date") AS null_dates,
       COUNT(CASE WHEN trim("date") = '' THEN 1 END) AS blank_dates,
       COUNT(*) - COUNT(home_team_api_id) AS null_home_team_ids,
       COUNT(*) - COUNT(away_team_api_id) AS null_away_team_ids,
       COUNT(*) - COUNT(home_team_goal) AS null_home_goals,
       COUNT(*) - COUNT(away_team_goal) AS null_away_goals
FROM "Match";

-- result: score_date_validity

-- 01.4 Score validity and date parseability.
-- Valid scores: numeric storage, nonnegative, whole-number values.
-- Investigate other encodings before conversion.
-- Score-valid rows are not necessarily final accepted matches.
SELECT COUNT(*) AS raw_match_rows,
    COUNT(CASE WHEN home_team_goal IS NULL OR away_team_goal IS NULL
        THEN 1 END) AS rows_with_missing_score,
    COUNT(CASE
        WHEN (home_team_goal IS NOT NULL
              AND typeof(home_team_goal) NOT IN ('integer', 'real'))
          OR (away_team_goal IS NOT NULL
              AND typeof(away_team_goal) NOT IN ('integer', 'real'))
        THEN 1 END) AS rows_with_nonnumeric_score,
    COUNT(CASE
        WHEN (typeof(home_team_goal) IN ('integer', 'real') AND home_team_goal < 0)
          OR (typeof(away_team_goal) IN ('integer', 'real') AND away_team_goal < 0)
        THEN 1 END) AS rows_with_negative_score,
    COUNT(CASE
        WHEN (typeof(home_team_goal) IN ('integer', 'real')
              AND home_team_goal <> CAST(home_team_goal AS INTEGER))
          OR (typeof(away_team_goal) IN ('integer', 'real')
              AND away_team_goal <> CAST(away_team_goal AS INTEGER))
        THEN 1 END) AS rows_with_noninteger_score,
    COUNT(CASE
        WHEN typeof(home_team_goal) IN ('integer', 'real')
         AND typeof(away_team_goal) IN ('integer', 'real')
         AND home_team_goal >= 0 AND away_team_goal >= 0
         AND home_team_goal = CAST(home_team_goal AS INTEGER)
         AND away_team_goal = CAST(away_team_goal AS INTEGER)
        THEN 1 END) AS rows_with_valid_score_pair,
    COUNT(CASE WHEN "date" IS NOT NULL AND date("date") IS NULL
        THEN 1 END) AS rows_with_unparseable_nonnull_date
FROM "Match";

-- result: duplicate_match_ids

-- 01.5 Duplicate non-NULL match identifiers; investigate before deduplication.
SELECT match_api_id, COUNT(*) AS rows_per_match_id
FROM "Match"
WHERE match_api_id IS NOT NULL
GROUP BY match_api_id
HAVING COUNT(*) > 1
ORDER BY rows_per_match_id DESC, match_api_id;

-- result: duplicate_dimension_keys

-- 01.6 Dimension keys that would multiply match rows.
SELECT 'Team.team_api_id' AS key_name, team_api_id AS key_value,
       COUNT(*) AS rows_per_key
FROM "Team" WHERE team_api_id IS NOT NULL
GROUP BY team_api_id HAVING COUNT(*) > 1
UNION ALL
SELECT 'League.id', id, COUNT(*)
FROM "League" WHERE id IS NOT NULL
GROUP BY id HAVING COUNT(*) > 1
UNION ALL
SELECT 'Country.id', id, COUNT(*)
FROM "Country" WHERE id IS NOT NULL
GROUP BY id HAVING COUNT(*) > 1;

-- result: relationship_checks

-- 01.7 EXISTS avoids multiplying rows when dimension keys are duplicated.
-- NULL keys are checked separately in 01.3. Issue counts can overlap.
SELECT COUNT(*) AS raw_match_rows,
    COUNT(CASE WHEN m.home_team_api_id = m.away_team_api_id
        THEN 1 END) AS same_home_and_away_team,
    COUNT(CASE WHEN m.home_team_api_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM "Team" AS t WHERE t.team_api_id = m.home_team_api_id
    ) THEN 1 END) AS unmatched_home_team_ids,
    COUNT(CASE WHEN m.away_team_api_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM "Team" AS t WHERE t.team_api_id = m.away_team_api_id
    ) THEN 1 END) AS unmatched_away_team_ids,
    COUNT(CASE WHEN m.league_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM "League" AS l WHERE l.id = m.league_id
    ) THEN 1 END) AS unmatched_league_ids,
    COUNT(CASE WHEN m.country_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM "Country" AS c WHERE c.id = m.country_id
    ) THEN 1 END) AS unmatched_country_ids,
    COUNT(CASE WHEN m.country_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM "League" AS l
        WHERE l.id = m.league_id AND l.country_id IS NOT NULL
          AND l.country_id <> m.country_id
    ) THEN 1 END) AS country_league_mismatches
FROM "Match" AS m;

-- result: duplicate_fixtures

-- 01.8 Duplicate fixture tuples, independent of match_api_id.
SELECT league_id, season, date, home_team_api_id, away_team_api_id,
       COUNT(*) AS fixture_rows
FROM "Match"
GROUP BY league_id, season, date, home_team_api_id, away_team_api_id
HAVING COUNT(*) > 1;


-- ============================================================
-- FILE: 02_coverage_audit.sql
-- ============================================================
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


-- ============================================================
-- FILE: 03_build_analysis_views.sql
-- ============================================================
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


-- ============================================================
-- FILE: 04_validate_views.sql
-- ============================================================
-- result: view_validation
-- Run after 03 in the same connection. Every passed flag should equal 1.
-- Raw/accepted row counts are reported separately: investigate any exclusions.
WITH raw AS (SELECT COUNT(*) AS n FROM "Match"),
m AS (
    SELECT COUNT(*) AS n, COUNT(DISTINCT match_api_id) AS unique_ids,
           COALESCE(SUM(total_goals),0) AS goals,
           COUNT(CASE WHEN result='home_win' THEN 1 END) AS hw,
           COUNT(CASE WHEN result='away_win' THEN 1 END) AS aw,
           COUNT(CASE WHEN result='draw' THEN 1 END) AS draws
    FROM v_matches
), t AS (
    SELECT COUNT(*) AS n, COALESCE(SUM(goals_for),0) AS gf,
           COALESCE(SUM(goals_against),0) AS ga,
           COUNT(CASE WHEN outcome='W' THEN 1 END) AS wins,
           COUNT(CASE WHEN outcome='D' THEN 1 END) AS draws,
           COUNT(CASE WHEN outcome='L' THEN 1 END) AS losses,
           COALESCE(SUM(points),0) AS points
    FROM v_team_matches
), checks AS (
    SELECT 'unique accepted match ids' AS check_name, m.unique_ids AS actual,
           m.n AS expected FROM m
    UNION ALL SELECT 'two team rows per accepted match',t.n,2*m.n FROM t,m
    UNION ALL SELECT 'team goals for equal match goals',t.gf,m.goals FROM t,m
    UNION ALL SELECT 'team goals against equal match goals',t.ga,m.goals FROM t,m
    UNION ALL SELECT 'match result categories exhaust matches',m.hw+m.aw+m.draws,m.n FROM m
    UNION ALL SELECT 'wins equal losses',t.wins,t.losses FROM t
    UNION ALL SELECT 'team results exhaust team rows',t.wins+t.draws+t.losses,t.n FROM t
    UNION ALL SELECT 'team draws equal twice match draws',t.draws,2*m.draws FROM t,m
    UNION ALL SELECT 'points reconcile with match outcomes',t.points,3*(m.hw+m.aw)+2*m.draws FROM t,m
    UNION ALL SELECT 'each match has two distinct teams',
        (SELECT COUNT(*) FROM (
            SELECT match_api_id FROM v_team_matches GROUP BY match_api_id
            HAVING COUNT(*)=2 AND COUNT(DISTINCT team_api_id)=2
        )),m.n FROM m
)
SELECT check_name,actual,expected,CASE WHEN actual=expected THEN 1 ELSE 0 END AS passed
FROM checks;

-- result: accepted_rows

SELECT (SELECT COUNT(*) FROM "Match") AS raw_matches,
       (SELECT COUNT(*) FROM v_matches) AS accepted_matches,
       (SELECT COUNT(*) FROM "Match")-(SELECT COUNT(*) FROM v_matches) AS excluded_matches,
       (SELECT COUNT(*) FROM v_team_matches) AS team_match_rows;


-- ============================================================
-- FILE: 05_first_analysis.sql
-- ============================================================
-- result: first_analysis
-- First guided exercise: Premier League season overview.
-- Run after 03, in the same connection. One row per observed season.
-- Home/away win rates share the all-match denominator, including draws.
-- The gap is in percentage points. This is descriptive, not a causal estimate.
SELECT league,season,COUNT(*) AS matches,
       SUM(total_goals) AS goals,ROUND(AVG(total_goals),3) AS goals_per_match,
       COUNT(CASE WHEN result='home_win' THEN 1 END) AS home_wins,
       COUNT(CASE WHEN result='draw' THEN 1 END) AS draws,
       COUNT(CASE WHEN result='away_win' THEN 1 END) AS away_wins,
       ROUND(100.0*COUNT(CASE WHEN result='home_win' THEN 1 END)/COUNT(*),2) AS home_win_pct,
       ROUND(100.0*COUNT(CASE WHEN result='draw' THEN 1 END)/COUNT(*),2) AS draw_pct,
       ROUND(100.0*COUNT(CASE WHEN result='away_win' THEN 1 END)/COUNT(*),2) AS away_win_pct,
       ROUND(100.0*(COUNT(CASE WHEN result='home_win' THEN 1 END)
                         -COUNT(CASE WHEN result='away_win' THEN 1 END))/COUNT(*),2) AS home_away_gap_pp
FROM v_matches WHERE league_id=1729
GROUP BY league_id,league,season
ORDER BY season;


-- ============================================================
-- FILE: 06_extension_audit.sql
-- ============================================================
-- Optional extension audit. No views required.
-- Multiple rows per entity are expected, but duplicated entity-date keys need review.
SELECT 'Player_Attributes' AS table_name,COUNT(*) AS rows,
       COUNT(DISTINCT player_api_id) AS entities,MIN(date) AS first_date,MAX(date) AS last_date
FROM Player_Attributes
UNION ALL
SELECT 'Team_Attributes',COUNT(*),COUNT(DISTINCT team_api_id),MIN(date),MAX(date)
FROM Team_Attributes;

SELECT 'Player_Attributes' AS table_name,COUNT(*) AS duplicate_entity_date_groups,
       COALESCE(SUM(n-1),0) AS excess_rows
FROM (SELECT player_api_id,date,COUNT(*) AS n FROM Player_Attributes
      GROUP BY player_api_id,date HAVING COUNT(*)>1)
UNION ALL
SELECT 'Team_Attributes',COUNT(*),COALESCE(SUM(n-1),0)
FROM (SELECT team_api_id,date,COUNT(*) AS n FROM Team_Attributes
      GROUP BY team_api_id,date HAVING COUNT(*)>1);

SELECT team_fifa_api_id,COUNT(*) AS team_rows
FROM Team WHERE team_fifa_api_id IS NOT NULL
GROUP BY team_fifa_api_id HAVING COUNT(*)>1;

-- Non-NULL XML is not proof of populated events or complete measurements.
SELECT l.name AS league,COUNT(*) AS matches,
       COUNT(m.goal) AS nonnull_goal_xml,
       COUNT(m.possession) AS nonnull_possession_xml
FROM "Match" AS m JOIN League AS l ON l.id=m.league_id
GROUP BY m.league_id,l.name ORDER BY l.name;


-- ============================================================
-- FILE: 07_build_summary_views.sql
-- ============================================================
-- Run 03 first, in this same connection. TEMP views do not change the source.
-- Re-running this file refreshes definitions, not source rows.
DROP VIEW IF EXISTS temp.v_team_season_change;
DROP VIEW IF EXISTS temp.v_team_season_ranked;
DROP VIEW IF EXISTS temp.v_league_season;
DROP VIEW IF EXISTS temp.v_team_season;
DROP VIEW IF EXISTS temp.v_coverage_policy;

-- A reporting policy based on the observed coverage audit in SQL 02.
-- It is not a claim that official schedules or all competition phases are complete.
CREATE TEMP VIEW v_coverage_policy AS
SELECT DISTINCT league_id, season,
    CASE
        WHEN league_id=1 AND season='2013/2014'
            THEN 'Narrow subset: 12 matches, 4 observed teams'
        WHEN league_id=10257 AND season='2011/2012'
            THEN 'Uneven schedule: 358 matches, 34-38 games per team'
        WHEN league_id=10257 AND season='2014/2015'
            THEN 'Uneven schedule: 379 matches, 37-38 games per team'
        WHEN league_id=24558 AND season='2011/2012'
            THEN 'Uneven schedule: 162 matches, 18-34 games per team'
        WHEN league_id IN (1,15722,19694,24558)
            THEN 'Interpret within observed stages and competition format'
        ELSE 'Observed schedule reviewed; official completeness not verified'
    END AS coverage_note,
    CASE WHEN league_id IN (1729,4769,7809,13274,21518)
         THEN 1 ELSE 0 END AS stable_comparison_sample
FROM v_matches;

-- Grain: one team in one league in one season.
CREATE TEMP VIEW v_team_season AS
WITH totals AS (
    SELECT league_id, league, country, season, season_start_year,
           team_api_id, team,
           COUNT(*) AS played,
           SUM(CASE WHEN outcome='W' THEN 1 ELSE 0 END) AS wins,
           SUM(CASE WHEN outcome='D' THEN 1 ELSE 0 END) AS draws,
           SUM(CASE WHEN outcome='L' THEN 1 ELSE 0 END) AS losses,
           SUM(goals_for) AS goals_for, SUM(goals_against) AS goals_against,
           SUM(goal_difference) AS goal_difference, SUM(points) AS points,
           SUM(CASE WHEN venue='home' THEN 1 ELSE 0 END) AS home_played,
           SUM(CASE WHEN venue='away' THEN 1 ELSE 0 END) AS away_played,
           SUM(CASE WHEN venue='home' THEN points ELSE 0 END) AS home_points,
           SUM(CASE WHEN venue='away' THEN points ELSE 0 END) AS away_points
    FROM v_team_matches
    GROUP BY league_id, league, country, season, season_start_year, team_api_id, team
)
SELECT t.*, 1.0*t.points/t.played AS ppg,
       1.0*t.wins/t.played AS win_rate,
       1.0*t.goals_for/t.played AS goals_for_per_game,
       1.0*t.goals_against/t.played AS goals_against_per_game,
       1.0*t.home_points/NULLIF(t.home_played,0) AS home_ppg,
       1.0*t.away_points/NULLIF(t.away_played,0) AS away_ppg,
       1.0*t.home_points/NULLIF(t.home_played,0)
         -1.0*t.away_points/NULLIF(t.away_played,0) AS home_away_ppg_gap,
       c.coverage_note, c.stable_comparison_sample
FROM totals AS t JOIN v_coverage_policy AS c USING (league_id,season);

-- DENSE_RANK uses the full-precision PPG. Equal ratios share a rank.
-- These are reconstructed PPG ranks, not official final league positions.
CREATE TEMP VIEW v_team_season_ranked AS
SELECT *, DENSE_RANK() OVER (
    PARTITION BY league_id, season ORDER BY ppg DESC
) AS ppg_rank
FROM v_team_season;

-- Grain: one league in one season. Ratios are weighted by matches.
CREATE TEMP VIEW v_league_season AS
WITH team_coverage AS (
    SELECT league_id,season,COUNT(*) AS observed_teams,
           MIN(played) AS min_team_games,MAX(played) AS max_team_games
    FROM v_team_season GROUP BY league_id,season
), totals AS (
    SELECT league_id,league,country,season,season_start_year,
           COUNT(*) AS matches,SUM(total_goals) AS total_goals,
           SUM(home_goals) AS home_goals,SUM(away_goals) AS away_goals,
           SUM(CASE WHEN result='home_win' THEN 1 ELSE 0 END) AS home_wins,
           SUM(CASE WHEN result='draw' THEN 1 ELSE 0 END) AS draws,
           SUM(CASE WHEN result='away_win' THEN 1 ELSE 0 END) AS away_wins
    FROM v_matches GROUP BY league_id,league,country,season,season_start_year
)
SELECT t.*,s.observed_teams,s.min_team_games,s.max_team_games,
       1.0*t.total_goals/t.matches AS goals_per_match,
       1.0*t.home_wins/t.matches AS home_win_rate,
       1.0*t.draws/t.matches AS draw_rate,
       1.0*t.away_wins/t.matches AS away_win_rate,
       100.0*(t.home_wins-t.away_wins)/t.matches AS home_away_win_gap_pp,
       c.coverage_note,c.stable_comparison_sample
FROM totals AS t
JOIN team_coverage AS s USING (league_id,season)
JOIN v_coverage_policy AS c USING (league_id,season);

-- LAG alone can bridge a relegation/coverage gap. Keep only adjacent years.
CREATE TEMP VIEW v_team_season_change AS
WITH history AS (
    SELECT *,
        LAG(season) OVER w AS previous_season,
        LAG(season_start_year) OVER w AS previous_start_year,
        LAG(played) OVER w AS previous_played,
        LAG(points) OVER w AS previous_points,
        LAG(ppg) OVER w AS previous_ppg,
        LAG(ppg_rank) OVER w AS previous_ppg_rank,
        LAG(coverage_note) OVER w AS previous_coverage_note
    FROM v_team_season_ranked
    WINDOW w AS (PARTITION BY league_id,team_api_id ORDER BY season_start_year)
)
SELECT *,points-previous_points AS points_change,
       ppg-previous_ppg AS ppg_change,
       previous_ppg_rank-ppg_rank AS ppg_rank_improvement
FROM history WHERE season_start_year=previous_start_year+1;


-- ============================================================
-- FILE: 08_overview_and_leagues.sql
-- ============================================================
-- Requires 03 and 07 in the same connection.
-- result: overview
SELECT COUNT(*) AS matches,COUNT(DISTINCT league_id) AS leagues,
       COUNT(DISTINCT country_id) AS countries,COUNT(DISTINCT season) AS seasons,
       (SELECT COUNT(DISTINCT team_api_id) FROM v_team_matches) AS participating_teams,
       MIN(match_date) AS first_match_date,MAX(match_date) AS last_match_date,
       SUM(total_goals) AS total_goals,SUM(home_goals) AS home_goals,
       SUM(away_goals) AS away_goals,AVG(total_goals) AS goals_per_match,
       SUM(CASE WHEN result='home_win' THEN 1 ELSE 0 END) AS home_wins,
       SUM(CASE WHEN result='draw' THEN 1 ELSE 0 END) AS draws,
       SUM(CASE WHEN result='away_win' THEN 1 ELSE 0 END) AS away_wins,
       AVG(CASE WHEN result='home_win' THEN 1.0 ELSE 0.0 END) AS home_win_rate,
       AVG(CASE WHEN result='draw' THEN 1.0 ELSE 0.0 END) AS draw_rate,
       AVG(CASE WHEN result='away_win' THEN 1.0 ELSE 0.0 END) AS away_win_rate,
       100.0*SUM(CASE result WHEN 'home_win' THEN 1 WHEN 'away_win' THEN -1 ELSE 0 END)
            /COUNT(*) AS home_away_win_gap_pp
FROM v_matches;

-- Q1/Q5: Descriptive comparison, all observed matches. Different opponents,
-- stages and coverage mean this is not a ranking of league quality.
-- result: league_summary
SELECT league_id,league,country,COUNT(*) AS matches,
       COUNT(DISTINCT season) AS seasons,SUM(total_goals) AS total_goals,
       AVG(total_goals) AS goals_per_match,
       SUM(CASE WHEN result='home_win' THEN 1 ELSE 0 END) AS home_wins,
       SUM(CASE WHEN result='draw' THEN 1 ELSE 0 END) AS draws,
       SUM(CASE WHEN result='away_win' THEN 1 ELSE 0 END) AS away_wins,
       AVG(CASE WHEN result='home_win' THEN 1.0 ELSE 0.0 END) AS home_win_rate,
       AVG(CASE WHEN result='draw' THEN 1.0 ELSE 0.0 END) AS draw_rate,
       AVG(CASE WHEN result='away_win' THEN 1.0 ELSE 0.0 END) AS away_win_rate,
       100.0*SUM(CASE result WHEN 'home_win' THEN 1 WHEN 'away_win' THEN -1 ELSE 0 END)
            /COUNT(*) AS home_away_win_gap_pp
FROM v_matches GROUP BY league_id,league,country
ORDER BY goals_per_match DESC,league_id;

-- Same five leagues in every season; see SQL 02 and comparison policy in 07.
-- Coverage balance does not adjust for opponent strength or differing formats.
-- result: stable_league_comparison
SELECT league_id,league,country,COUNT(*) AS observed_seasons,
       SUM(matches) AS matches,SUM(total_goals) AS total_goals,
       1.0*SUM(total_goals)/SUM(matches) AS goals_per_match,
       1.0*SUM(home_wins)/SUM(matches) AS home_win_rate,
       1.0*SUM(away_wins)/SUM(matches) AS away_win_rate,
       100.0*SUM(home_wins-away_wins)/SUM(matches) AS home_away_win_gap_pp
FROM v_league_season WHERE stable_comparison_sample=1
GROUP BY league_id,league,country ORDER BY goals_per_match DESC;


-- ============================================================
-- FILE: 09_season_trends.sql
-- ============================================================
-- Q1: All 88 league-seasons, with observed coverage and full-precision ratios.
-- result: league_season
SELECT * FROM v_league_season ORDER BY league,season;

-- Focus sample for storytelling: England has 380 observed fixtures each year.
-- result: premier_league_seasons
SELECT season,matches,total_goals,goals_per_match,home_wins,draws,away_wins,
       home_win_rate,draw_rate,away_win_rate,home_away_win_gap_pp
FROM v_league_season WHERE league_id=1729 ORDER BY season;

-- Stable league membership avoids changing the league mix across years.
-- This remains a match-weighted series, not a causal time-trend estimate.
-- result: stable_sample_season_trend
SELECT season,COUNT(*) AS leagues,SUM(matches) AS matches,
       SUM(total_goals) AS total_goals,
       1.0*SUM(total_goals)/SUM(matches) AS goals_per_match,
       1.0*SUM(home_wins)/SUM(matches) AS home_win_rate,
       1.0*SUM(away_wins)/SUM(matches) AS away_win_rate
FROM v_league_season WHERE stable_comparison_sample=1
GROUP BY season ORDER BY season;


-- ============================================================
-- FILE: 10_team_rankings.sql
-- ============================================================
-- Q2: Every observed team-season. PPG rank is within league and season.
-- Points = 3*wins + draws. No disciplinary deductions or official tie-breaks.
-- result: team_season_rankings
SELECT league_id,league,season,team_api_id,team,played,wins,draws,losses,
       goals_for,goals_against,goal_difference,points,ppg,ppg_rank,
       coverage_note,stable_comparison_sample
FROM v_team_season_ranked ORDER BY league,season,ppg_rank,team;

-- Includes every tied leader, without silently selecting an arbitrary team.
-- result: league_season_ppg_leaders
SELECT league,season,team_api_id,team,played,points,ppg,ppg_rank,coverage_note
FROM v_team_season_ranked WHERE ppg_rank=1 ORDER BY league,season,team;

-- A concrete complete internal schedule, not an official final table.
-- result: premier_league_2015_16
SELECT ppg_rank,team_api_id,team,played,wins,draws,losses,
       goals_for,goals_against,goal_difference,points,ppg
FROM v_team_season_ranked WHERE league_id=1729 AND season='2015/2016'
ORDER BY ppg_rank,team;


-- ============================================================
-- FILE: 11_home_away.sql
-- ============================================================
-- Q3: Descriptive difference, not a causal estimate of home advantage.
-- Always show both denominators. Keep all team-seasons in the full export.
-- result: team_home_away
SELECT league_id,league,season,team_api_id,team,
       home_played,away_played,home_points,away_points,
       home_ppg,away_ppg,home_away_ppg_gap,coverage_note
FROM v_team_season ORDER BY league,season,home_away_ppg_gap DESC,team;

-- Compare season-level gaps within the same league; equal 19/19 schedules.
-- result: premier_league_largest_home_gaps
SELECT season,team_api_id,team,home_played,away_played,home_points,away_points,
       home_ppg,away_ppg,home_away_ppg_gap
FROM v_team_season WHERE league_id=1729 AND home_played=19 AND away_played=19
ORDER BY home_away_ppg_gap DESC,season,team LIMIT 10;

-- All 20 teams in the latest observed season, including negative gaps.
-- result: premier_league_2015_16_home_away
SELECT team_api_id,team,home_played,away_played,home_points,away_points,
       home_ppg,away_ppg,home_away_ppg_gap
FROM v_team_season WHERE league_id=1729 AND season='2015/2016'
ORDER BY home_away_ppg_gap DESC,team;


-- ============================================================
-- FILE: 12_consecutive_season_changes.sql
-- ============================================================
-- Q4: Only adjacent start-years for the same team API id and same league.
-- Full results retain coverage notes for both sides of the comparison.
-- result: consecutive_season_changes
SELECT league_id,league,team_api_id,team,previous_season,season,
       previous_played,played,previous_points,points,points_change,
       previous_ppg,ppg,ppg_change,previous_ppg_rank,ppg_rank,
       ppg_rank_improvement,previous_coverage_note,coverage_note,
       stable_comparison_sample
FROM v_team_season_change ORDER BY league,team,season;

-- Primary improvement comparison: same league, 38 games in both seasons.
-- result: premier_league_improvements
SELECT team_api_id,team,previous_season,season,previous_played,played,
       previous_points,points,points_change,previous_ppg,ppg,ppg_change,
       previous_ppg_rank,ppg_rank
FROM v_team_season_change WHERE league_id=1729
  AND previous_played=38 AND played=38
ORDER BY ppg_change DESC,season,team LIMIT 10;

-- Stable-sample improvements are a descriptive search, not a strength ranking.
-- result: stable_sample_improvements
SELECT league,team_api_id,team,previous_season,season,previous_played,played,
       previous_points,points,previous_ppg,ppg,ppg_change
FROM v_team_season_change WHERE stable_comparison_sample=1
ORDER BY ppg_change DESC,league,season,team LIMIT 10;


-- ============================================================
-- FILE: 13_validate_aggregates.sql
-- ============================================================
-- All passed values must be 1. Stop and investigate any failure.
-- result: aggregate_validation
WITH checks AS (
    SELECT 'all raw matches retained' AS check_name,
       (SELECT COUNT(*) FROM v_matches) AS actual,
       (SELECT COUNT(*) FROM "Match") AS expected
    UNION ALL SELECT 'team-season played reconciles',SUM(played),
       (SELECT COUNT(*) FROM v_team_matches) FROM v_team_season
    UNION ALL SELECT 'team-season goals for reconciles',SUM(goals_for),
       (SELECT SUM(total_goals) FROM v_matches) FROM v_team_season
    UNION ALL SELECT 'league-season matches reconciles',SUM(matches),
       (SELECT COUNT(*) FROM v_matches) FROM v_league_season
    UNION ALL SELECT 'league-season goals reconciles',SUM(total_goals),
       (SELECT SUM(total_goals) FROM v_matches) FROM v_league_season
    UNION ALL SELECT 'invalid team-season totals',COUNT(*),0 FROM v_team_season
       WHERE played<>wins+draws+losses OR points<>3*wins+draws
       OR goal_difference<>goals_for-goals_against
       OR home_played+away_played<>played OR home_points+away_points<>points
    UNION ALL SELECT 'invalid PPG or venue denominator',COUNT(*),0 FROM v_team_season
       WHERE ppg<0 OR ppg>3 OR home_played=0 OR away_played=0
    UNION ALL SELECT 'duplicate team-season keys',COUNT(*),0 FROM (
       SELECT league_id,season,team_api_id FROM v_team_season
       GROUP BY league_id,season,team_api_id HAVING COUNT(*)<>1)
    UNION ALL SELECT 'nonconsecutive changes',COUNT(*),0 FROM v_team_season_change
       WHERE season_start_year<>previous_start_year+1
    UNION ALL SELECT 'duplicate season labels per start year',COUNT(*),0 FROM (
       SELECT league_id,team_api_id,season_start_year FROM v_team_season
       GROUP BY league_id,team_api_id,season_start_year HAVING COUNT(*)<>1)
    UNION ALL SELECT 'each league-season has a PPG leader',
       (SELECT COUNT(*) FROM (SELECT league_id,season FROM v_team_season_ranked
           WHERE ppg_rank=1 GROUP BY league_id,season)),
       (SELECT COUNT(*) FROM v_league_season)
    UNION ALL SELECT 'stable sample ordered-pair structure failures',COUNT(*),0 FROM (
       SELECT league_id,season FROM v_matches
       WHERE league_id IN (1729,4769,7809,13274,21518)
       GROUP BY league_id,season HAVING COUNT(*) <>
           (SELECT COUNT(*)*(COUNT(*)-1) FROM v_team_season AS t
            WHERE t.league_id=v_matches.league_id AND t.season=v_matches.season)
       UNION ALL
       SELECT league_id,season FROM v_matches
       WHERE league_id IN (1729,4769,7809,13274,21518)
       GROUP BY league_id,season,home_team_api_id,away_team_api_id HAVING COUNT(*)<>1
    )
)
SELECT check_name,actual,expected,CASE WHEN actual=expected THEN 1 ELSE 0 END AS passed
FROM checks;

