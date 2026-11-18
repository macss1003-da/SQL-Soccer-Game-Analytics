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
