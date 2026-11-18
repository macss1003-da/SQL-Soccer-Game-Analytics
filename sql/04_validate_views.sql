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
