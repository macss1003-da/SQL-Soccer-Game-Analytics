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
