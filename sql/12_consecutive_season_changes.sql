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
