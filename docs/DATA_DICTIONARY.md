# Data dictionary — verified uploaded SQLite database

Generated from the actual PRAGMA table_info metadata and observed NULL counts. Declared SQLite types describe schema declarations; they are not a full validation of every stored value. Blank-string counts and additional checks are in outputs/database_audit.json. Units or external semantics not established by this file must be verified before use.

## Core relationships

| Cột nguồn | Cột đích | Cách sử dụng |
| --- | --- | --- |
| League.country_id | Country.id | Quốc gia của giải. |
| Match.league_id | League.id | Tên giải; không dùng country_id thay thế league_id. |
| Match.country_id | Country.id | Tên quốc gia của trận. |
| Match.home_team_api_id | Team.team_api_id | JOIN Team với alias home. |
| Match.away_team_api_id | Team.team_api_id | JOIN Team với alias away. |
| Match.home_player_1…11 / away_player_1…11 | Player.player_api_id | 22 vị trí cầu thủ, có thể thiếu. |
| Player_Attributes.player_api_id | Player.player_api_id | Nhiều lần ghi nhận theo cầu thủ. |
| Team_Attributes.team_api_id | Team.team_api_id | Nhiều lần ghi nhận theo đội. |

## Match column groups

| Group | Columns | Use |
| --- | --- | --- |
| Identity, competition, date and score | 11 | Version 1 core. |
| Player API slots | 22 | Home and away slots 1–11; not a normalized roster table. |
| Player coordinates | 44 | X/Y for 22 slots; coordinate conventions need confirmation before tactical interpretation. |
| Event XML | 8 | Parse event structure before numeric aggregation. |
| Odds | 30 | Ten H/D/A groups; timing and market definitions need source verification. |

The API join keys are distinct from each table's internal id. Team.team_fifa_api_id is nullable and not unique in this upload. Entity-date combinations in both attribute tables require tie handling.

## Country

Một quốc gia theo phân loại trong nguồn dữ liệu. Rows: 11. Columns: 2.

| Position | Column | Declared type | NULL count | NULL % | Declared PK order | Declared FK target |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | id | INTEGER | 0 | 0.0 | 1 | — |
| 1 | name | TEXT | 0 | 0.0 | 0 | — |

## League

Một giải đấu; country_id liên kết với Country. Rows: 11. Columns: 3.

| Position | Column | Declared type | NULL count | NULL % | Declared PK order | Declared FK target |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | id | INTEGER | 0 | 0.0 | 1 | — |
| 1 | country_id | INTEGER | 0 | 0.0 | 0 | country.id |
| 2 | name | TEXT | 0 | 0.0 | 0 | — |

## Match

Một trận đấu; match_api_id duy nhất trong file đã kiểm tra. Rows: 25,979. Columns: 115.

| Position | Column | Declared type | NULL count | NULL % | Declared PK order | Declared FK target |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | id | INTEGER | 0 | 0.0 | 1 | — |
| 1 | country_id | INTEGER | 0 | 0.0 | 0 | country.id |
| 2 | league_id | INTEGER | 0 | 0.0 | 0 | League.id |
| 3 | season | TEXT | 0 | 0.0 | 0 | — |
| 4 | stage | INTEGER | 0 | 0.0 | 0 | — |
| 5 | date | TEXT | 0 | 0.0 | 0 | — |
| 6 | match_api_id | INTEGER | 0 | 0.0 | 0 | — |
| 7 | home_team_api_id | INTEGER | 0 | 0.0 | 0 | Team.team_api_id |
| 8 | away_team_api_id | INTEGER | 0 | 0.0 | 0 | Team.team_api_id |
| 9 | home_team_goal | INTEGER | 0 | 0.0 | 0 | — |
| 10 | away_team_goal | INTEGER | 0 | 0.0 | 0 | — |
| 11 | home_player_X1 | INTEGER | 1821 | 7.01 | 0 | — |
| 12 | home_player_X2 | INTEGER | 1821 | 7.01 | 0 | — |
| 13 | home_player_X3 | INTEGER | 1832 | 7.05 | 0 | — |
| 14 | home_player_X4 | INTEGER | 1832 | 7.05 | 0 | — |
| 15 | home_player_X5 | INTEGER | 1832 | 7.05 | 0 | — |
| 16 | home_player_X6 | INTEGER | 1832 | 7.05 | 0 | — |
| 17 | home_player_X7 | INTEGER | 1832 | 7.05 | 0 | — |
| 18 | home_player_X8 | INTEGER | 1832 | 7.05 | 0 | — |
| 19 | home_player_X9 | INTEGER | 1832 | 7.05 | 0 | — |
| 20 | home_player_X10 | INTEGER | 1832 | 7.05 | 0 | — |
| 21 | home_player_X11 | INTEGER | 1832 | 7.05 | 0 | — |
| 22 | away_player_X1 | INTEGER | 1832 | 7.05 | 0 | — |
| 23 | away_player_X2 | INTEGER | 1832 | 7.05 | 0 | — |
| 24 | away_player_X3 | INTEGER | 1832 | 7.05 | 0 | — |
| 25 | away_player_X4 | INTEGER | 1832 | 7.05 | 0 | — |
| 26 | away_player_X5 | INTEGER | 1832 | 7.05 | 0 | — |
| 27 | away_player_X6 | INTEGER | 1832 | 7.05 | 0 | — |
| 28 | away_player_X7 | INTEGER | 1832 | 7.05 | 0 | — |
| 29 | away_player_X8 | INTEGER | 1832 | 7.05 | 0 | — |
| 30 | away_player_X9 | INTEGER | 1833 | 7.06 | 0 | — |
| 31 | away_player_X10 | INTEGER | 1833 | 7.06 | 0 | — |
| 32 | away_player_X11 | INTEGER | 1839 | 7.08 | 0 | — |
| 33 | home_player_Y1 | INTEGER | 1821 | 7.01 | 0 | — |
| 34 | home_player_Y2 | INTEGER | 1821 | 7.01 | 0 | — |
| 35 | home_player_Y3 | INTEGER | 1832 | 7.05 | 0 | — |
| 36 | home_player_Y4 | INTEGER | 1832 | 7.05 | 0 | — |
| 37 | home_player_Y5 | INTEGER | 1832 | 7.05 | 0 | — |
| 38 | home_player_Y6 | INTEGER | 1832 | 7.05 | 0 | — |
| 39 | home_player_Y7 | INTEGER | 1832 | 7.05 | 0 | — |
| 40 | home_player_Y8 | INTEGER | 1832 | 7.05 | 0 | — |
| 41 | home_player_Y9 | INTEGER | 1832 | 7.05 | 0 | — |
| 42 | home_player_Y10 | INTEGER | 1832 | 7.05 | 0 | — |
| 43 | home_player_Y11 | INTEGER | 1832 | 7.05 | 0 | — |
| 44 | away_player_Y1 | INTEGER | 1832 | 7.05 | 0 | — |
| 45 | away_player_Y2 | INTEGER | 1832 | 7.05 | 0 | — |
| 46 | away_player_Y3 | INTEGER | 1832 | 7.05 | 0 | — |
| 47 | away_player_Y4 | INTEGER | 1832 | 7.05 | 0 | — |
| 48 | away_player_Y5 | INTEGER | 1832 | 7.05 | 0 | — |
| 49 | away_player_Y6 | INTEGER | 1832 | 7.05 | 0 | — |
| 50 | away_player_Y7 | INTEGER | 1832 | 7.05 | 0 | — |
| 51 | away_player_Y8 | INTEGER | 1832 | 7.05 | 0 | — |
| 52 | away_player_Y9 | INTEGER | 1833 | 7.06 | 0 | — |
| 53 | away_player_Y10 | INTEGER | 1833 | 7.06 | 0 | — |
| 54 | away_player_Y11 | INTEGER | 1839 | 7.08 | 0 | — |
| 55 | home_player_1 | INTEGER | 1224 | 4.71 | 0 | Player.player_api_id |
| 56 | home_player_2 | INTEGER | 1315 | 5.06 | 0 | Player.player_api_id |
| 57 | home_player_3 | INTEGER | 1281 | 4.93 | 0 | Player.player_api_id |
| 58 | home_player_4 | INTEGER | 1323 | 5.09 | 0 | Player.player_api_id |
| 59 | home_player_5 | INTEGER | 1316 | 5.07 | 0 | Player.player_api_id |
| 60 | home_player_6 | INTEGER | 1325 | 5.1 | 0 | Player.player_api_id |
| 61 | home_player_7 | INTEGER | 1227 | 4.72 | 0 | Player.player_api_id |
| 62 | home_player_8 | INTEGER | 1309 | 5.04 | 0 | Player.player_api_id |
| 63 | home_player_9 | INTEGER | 1273 | 4.9 | 0 | Player.player_api_id |
| 64 | home_player_10 | INTEGER | 1436 | 5.53 | 0 | Player.player_api_id |
| 65 | home_player_11 | INTEGER | 1555 | 5.99 | 0 | Player.player_api_id |
| 66 | away_player_1 | INTEGER | 1234 | 4.75 | 0 | Player.player_api_id |
| 67 | away_player_2 | INTEGER | 1278 | 4.92 | 0 | Player.player_api_id |
| 68 | away_player_3 | INTEGER | 1293 | 4.98 | 0 | Player.player_api_id |
| 69 | away_player_4 | INTEGER | 1321 | 5.08 | 0 | Player.player_api_id |
| 70 | away_player_5 | INTEGER | 1335 | 5.14 | 0 | Player.player_api_id |
| 71 | away_player_6 | INTEGER | 1313 | 5.05 | 0 | Player.player_api_id |
| 72 | away_player_7 | INTEGER | 1235 | 4.75 | 0 | Player.player_api_id |
| 73 | away_player_8 | INTEGER | 1341 | 5.16 | 0 | Player.player_api_id |
| 74 | away_player_9 | INTEGER | 1328 | 5.11 | 0 | Player.player_api_id |
| 75 | away_player_10 | INTEGER | 1441 | 5.55 | 0 | Player.player_api_id |
| 76 | away_player_11 | INTEGER | 1554 | 5.98 | 0 | Player.player_api_id |
| 77 | goal | TEXT | 11762 | 45.28 | 0 | — |
| 78 | shoton | TEXT | 11762 | 45.28 | 0 | — |
| 79 | shotoff | TEXT | 11762 | 45.28 | 0 | — |
| 80 | foulcommit | TEXT | 11762 | 45.28 | 0 | — |
| 81 | card | TEXT | 11762 | 45.28 | 0 | — |
| 82 | cross | TEXT | 11762 | 45.28 | 0 | — |
| 83 | corner | TEXT | 11762 | 45.28 | 0 | — |
| 84 | possession | TEXT | 11762 | 45.28 | 0 | — |
| 85 | B365H | NUMERIC | 3387 | 13.04 | 0 | — |
| 86 | B365D | NUMERIC | 3387 | 13.04 | 0 | — |
| 87 | B365A | NUMERIC | 3387 | 13.04 | 0 | — |
| 88 | BWH | NUMERIC | 3404 | 13.1 | 0 | — |
| 89 | BWD | NUMERIC | 3404 | 13.1 | 0 | — |
| 90 | BWA | NUMERIC | 3404 | 13.1 | 0 | — |
| 91 | IWH | NUMERIC | 3459 | 13.31 | 0 | — |
| 92 | IWD | NUMERIC | 3459 | 13.31 | 0 | — |
| 93 | IWA | NUMERIC | 3459 | 13.31 | 0 | — |
| 94 | LBH | NUMERIC | 3423 | 13.18 | 0 | — |
| 95 | LBD | NUMERIC | 3423 | 13.18 | 0 | — |
| 96 | LBA | NUMERIC | 3423 | 13.18 | 0 | — |
| 97 | PSH | NUMERIC | 14811 | 57.01 | 0 | — |
| 98 | PSD | NUMERIC | 14811 | 57.01 | 0 | — |
| 99 | PSA | NUMERIC | 14811 | 57.01 | 0 | — |
| 100 | WHH | NUMERIC | 3408 | 13.12 | 0 | — |
| 101 | WHD | NUMERIC | 3408 | 13.12 | 0 | — |
| 102 | WHA | NUMERIC | 3408 | 13.12 | 0 | — |
| 103 | SJH | NUMERIC | 8882 | 34.19 | 0 | — |
| 104 | SJD | NUMERIC | 8882 | 34.19 | 0 | — |
| 105 | SJA | NUMERIC | 8882 | 34.19 | 0 | — |
| 106 | VCH | NUMERIC | 3411 | 13.13 | 0 | — |
| 107 | VCD | NUMERIC | 3411 | 13.13 | 0 | — |
| 108 | VCA | NUMERIC | 3411 | 13.13 | 0 | — |
| 109 | GBH | NUMERIC | 11817 | 45.49 | 0 | — |
| 110 | GBD | NUMERIC | 11817 | 45.49 | 0 | — |
| 111 | GBA | NUMERIC | 11817 | 45.49 | 0 | — |
| 112 | BSH | NUMERIC | 11818 | 45.49 | 0 | — |
| 113 | BSD | NUMERIC | 11818 | 45.49 | 0 | — |
| 114 | BSA | NUMERIC | 11818 | 45.49 | 0 | — |

## Player

Một cầu thủ theo player_api_id. Rows: 11,060. Columns: 7.

| Position | Column | Declared type | NULL count | NULL % | Declared PK order | Declared FK target |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | id | INTEGER | 0 | 0.0 | 1 | — |
| 1 | player_api_id | INTEGER | 0 | 0.0 | 0 | — |
| 2 | player_name | TEXT | 0 | 0.0 | 0 | — |
| 3 | player_fifa_api_id | INTEGER | 0 | 0.0 | 0 | — |
| 4 | birthday | TEXT | 0 | 0.0 | 0 | — |
| 5 | height | INTEGER | 0 | 0.0 | 0 | — |
| 6 | weight | INTEGER | 0 | 0.0 | 0 | — |

## Player_Attributes

Một lần ghi nhận thuộc tính cầu thủ; cầu thủ và ngày chưa tạo thành khóa duy nhất. Rows: 183,978. Columns: 42.

| Position | Column | Declared type | NULL count | NULL % | Declared PK order | Declared FK target |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | id | INTEGER | 0 | 0.0 | 1 | — |
| 1 | player_fifa_api_id | INTEGER | 0 | 0.0 | 0 | Player.player_fifa_api_id |
| 2 | player_api_id | INTEGER | 0 | 0.0 | 0 | Player.player_api_id |
| 3 | date | TEXT | 0 | 0.0 | 0 | — |
| 4 | overall_rating | INTEGER | 836 | 0.45 | 0 | — |
| 5 | potential | INTEGER | 836 | 0.45 | 0 | — |
| 6 | preferred_foot | TEXT | 836 | 0.45 | 0 | — |
| 7 | attacking_work_rate | TEXT | 3230 | 1.76 | 0 | — |
| 8 | defensive_work_rate | TEXT | 836 | 0.45 | 0 | — |
| 9 | crossing | INTEGER | 836 | 0.45 | 0 | — |
| 10 | finishing | INTEGER | 836 | 0.45 | 0 | — |
| 11 | heading_accuracy | INTEGER | 836 | 0.45 | 0 | — |
| 12 | short_passing | INTEGER | 836 | 0.45 | 0 | — |
| 13 | volleys | INTEGER | 2713 | 1.47 | 0 | — |
| 14 | dribbling | INTEGER | 836 | 0.45 | 0 | — |
| 15 | curve | INTEGER | 2713 | 1.47 | 0 | — |
| 16 | free_kick_accuracy | INTEGER | 836 | 0.45 | 0 | — |
| 17 | long_passing | INTEGER | 836 | 0.45 | 0 | — |
| 18 | ball_control | INTEGER | 836 | 0.45 | 0 | — |
| 19 | acceleration | INTEGER | 836 | 0.45 | 0 | — |
| 20 | sprint_speed | INTEGER | 836 | 0.45 | 0 | — |
| 21 | agility | INTEGER | 2713 | 1.47 | 0 | — |
| 22 | reactions | INTEGER | 836 | 0.45 | 0 | — |
| 23 | balance | INTEGER | 2713 | 1.47 | 0 | — |
| 24 | shot_power | INTEGER | 836 | 0.45 | 0 | — |
| 25 | jumping | INTEGER | 2713 | 1.47 | 0 | — |
| 26 | stamina | INTEGER | 836 | 0.45 | 0 | — |
| 27 | strength | INTEGER | 836 | 0.45 | 0 | — |
| 28 | long_shots | INTEGER | 836 | 0.45 | 0 | — |
| 29 | aggression | INTEGER | 836 | 0.45 | 0 | — |
| 30 | interceptions | INTEGER | 836 | 0.45 | 0 | — |
| 31 | positioning | INTEGER | 836 | 0.45 | 0 | — |
| 32 | vision | INTEGER | 2713 | 1.47 | 0 | — |
| 33 | penalties | INTEGER | 836 | 0.45 | 0 | — |
| 34 | marking | INTEGER | 836 | 0.45 | 0 | — |
| 35 | standing_tackle | INTEGER | 836 | 0.45 | 0 | — |
| 36 | sliding_tackle | INTEGER | 2713 | 1.47 | 0 | — |
| 37 | gk_diving | INTEGER | 836 | 0.45 | 0 | — |
| 38 | gk_handling | INTEGER | 836 | 0.45 | 0 | — |
| 39 | gk_kicking | INTEGER | 836 | 0.45 | 0 | — |
| 40 | gk_positioning | INTEGER | 836 | 0.45 | 0 | — |
| 41 | gk_reflexes | INTEGER | 836 | 0.45 | 0 | — |

## Team

Một bản ghi đội theo team_api_id; không tự gộp theo tên hoặc mã FIFA. Rows: 299. Columns: 5.

| Position | Column | Declared type | NULL count | NULL % | Declared PK order | Declared FK target |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | id | INTEGER | 0 | 0.0 | 1 | — |
| 1 | team_api_id | INTEGER | 0 | 0.0 | 0 | — |
| 2 | team_fifa_api_id | INTEGER | 11 | 3.68 | 0 | — |
| 3 | team_long_name | TEXT | 0 | 0.0 | 0 | — |
| 4 | team_short_name | TEXT | 0 | 0.0 | 0 | — |

## Team_Attributes

Một lần ghi nhận thuộc tính đội; đội và ngày chưa tạo thành khóa duy nhất. Rows: 1,458. Columns: 25.

| Position | Column | Declared type | NULL count | NULL % | Declared PK order | Declared FK target |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | id | INTEGER | 0 | 0.0 | 1 | — |
| 1 | team_fifa_api_id | INTEGER | 0 | 0.0 | 0 | Team.team_fifa_api_id |
| 2 | team_api_id | INTEGER | 0 | 0.0 | 0 | Team.team_api_id |
| 3 | date | TEXT | 0 | 0.0 | 0 | — |
| 4 | buildUpPlaySpeed | INTEGER | 0 | 0.0 | 0 | — |
| 5 | buildUpPlaySpeedClass | TEXT | 0 | 0.0 | 0 | — |
| 6 | buildUpPlayDribbling | INTEGER | 969 | 66.46 | 0 | — |
| 7 | buildUpPlayDribblingClass | TEXT | 0 | 0.0 | 0 | — |
| 8 | buildUpPlayPassing | INTEGER | 0 | 0.0 | 0 | — |
| 9 | buildUpPlayPassingClass | TEXT | 0 | 0.0 | 0 | — |
| 10 | buildUpPlayPositioningClass | TEXT | 0 | 0.0 | 0 | — |
| 11 | chanceCreationPassing | INTEGER | 0 | 0.0 | 0 | — |
| 12 | chanceCreationPassingClass | TEXT | 0 | 0.0 | 0 | — |
| 13 | chanceCreationCrossing | INTEGER | 0 | 0.0 | 0 | — |
| 14 | chanceCreationCrossingClass | TEXT | 0 | 0.0 | 0 | — |
| 15 | chanceCreationShooting | INTEGER | 0 | 0.0 | 0 | — |
| 16 | chanceCreationShootingClass | TEXT | 0 | 0.0 | 0 | — |
| 17 | chanceCreationPositioningClass | TEXT | 0 | 0.0 | 0 | — |
| 18 | defencePressure | INTEGER | 0 | 0.0 | 0 | — |
| 19 | defencePressureClass | TEXT | 0 | 0.0 | 0 | — |
| 20 | defenceAggression | INTEGER | 0 | 0.0 | 0 | — |
| 21 | defenceAggressionClass | TEXT | 0 | 0.0 | 0 | — |
| 22 | defenceTeamWidth | INTEGER | 0 | 0.0 | 0 | — |
| 23 | defenceTeamWidthClass | TEXT | 0 | 0.0 | 0 | — |
| 24 | defenceDefenderLineClass | TEXT | 0 | 0.0 | 0 | — |

