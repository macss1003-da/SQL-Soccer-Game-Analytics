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
