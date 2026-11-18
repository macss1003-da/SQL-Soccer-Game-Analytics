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
