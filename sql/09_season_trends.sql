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
