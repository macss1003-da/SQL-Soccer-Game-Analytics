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
