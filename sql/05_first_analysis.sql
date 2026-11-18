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
