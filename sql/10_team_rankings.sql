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
