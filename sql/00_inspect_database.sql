-- result: sqlite_version
-- Run statements separately in Execute SQL.
-- Generic inspection; no soccer table names are assumed.
-- Queries 00.3 and 00.4 require SQLite >= 3.16.0.

-- 00.1
SELECT sqlite_version() AS sqlite_version;

-- result: schema_objects

-- 00.2 User tables and views.
SELECT name AS object_name, type AS object_type
FROM sqlite_master
WHERE type IN ('table', 'view')
  AND substr(name, 1, 7) <> 'sqlite_'
ORDER BY type, name;

-- result: schema_columns

-- 00.3 Columns and declared keys, not validated uniqueness.
SELECT m.name AS table_name, p.cid AS column_position,
       p.name AS column_name, p.type AS declared_type,
       p."notnull" AS declared_not_null,
       p.dflt_value AS default_value, p.pk AS primary_key_ordinal
FROM sqlite_master AS m
JOIN pragma_table_info(m.name) AS p ON 1 = 1
WHERE m.type = 'table' AND substr(m.name, 1, 7) <> 'sqlite_'
ORDER BY m.name, p.cid;

-- result: schema_foreign_keys

-- 00.4 Declared foreign keys.
-- An empty result does not rule out logical relationships.
SELECT m.name AS source_table, fk.id AS foreign_key_id,
       fk.seq AS key_column_sequence, fk."from" AS source_column,
       fk."table" AS referenced_table, fk."to" AS referenced_column
FROM sqlite_master AS m
JOIN pragma_foreign_key_list(m.name) AS fk ON 1 = 1
WHERE m.type = 'table' AND substr(m.name, 1, 7) <> 'sqlite_'
ORDER BY m.name, fk.id, fk.seq;

-- result: schema_ddl

-- 00.5 Actual CREATE TABLE definitions.
SELECT name AS table_name, sql AS create_table_sql
FROM sqlite_master
WHERE type = 'table' AND substr(name, 1, 7) <> 'sqlite_'
ORDER BY name;

-- result: table_counts

-- 00.6 Counts of all seven verified source tables.
SELECT 'Country' AS table_name, COUNT(*) AS row_count FROM Country
UNION ALL SELECT 'League', COUNT(*) FROM League
UNION ALL SELECT 'Match', COUNT(*) FROM "Match"
UNION ALL SELECT 'Team', COUNT(*) FROM Team
UNION ALL SELECT 'Player', COUNT(*) FROM Player
UNION ALL SELECT 'Player_Attributes', COUNT(*) FROM Player_Attributes
UNION ALL SELECT 'Team_Attributes', COUNT(*) FROM Team_Attributes;
