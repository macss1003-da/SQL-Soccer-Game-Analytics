-- Optional extension audit. No views required.
-- Multiple rows per entity are expected, but duplicated entity-date keys need review.
SELECT 'Player_Attributes' AS table_name,COUNT(*) AS rows,
       COUNT(DISTINCT player_api_id) AS entities,MIN(date) AS first_date,MAX(date) AS last_date
FROM Player_Attributes
UNION ALL
SELECT 'Team_Attributes',COUNT(*),COUNT(DISTINCT team_api_id),MIN(date),MAX(date)
FROM Team_Attributes;

SELECT 'Player_Attributes' AS table_name,COUNT(*) AS duplicate_entity_date_groups,
       COALESCE(SUM(n-1),0) AS excess_rows
FROM (SELECT player_api_id,date,COUNT(*) AS n FROM Player_Attributes
      GROUP BY player_api_id,date HAVING COUNT(*)>1)
UNION ALL
SELECT 'Team_Attributes',COUNT(*),COALESCE(SUM(n-1),0)
FROM (SELECT team_api_id,date,COUNT(*) AS n FROM Team_Attributes
      GROUP BY team_api_id,date HAVING COUNT(*)>1);

SELECT team_fifa_api_id,COUNT(*) AS team_rows
FROM Team WHERE team_fifa_api_id IS NOT NULL
GROUP BY team_fifa_api_id HAVING COUNT(*)>1;

-- Non-NULL XML is not proof of populated events or complete measurements.
SELECT l.name AS league,COUNT(*) AS matches,
       COUNT(m.goal) AS nonnull_goal_xml,
       COUNT(m.possession) AS nonnull_possession_xml
FROM "Match" AS m JOIN League AS l ON l.id=m.league_id
GROUP BY m.league_id,l.name ORDER BY l.name;
