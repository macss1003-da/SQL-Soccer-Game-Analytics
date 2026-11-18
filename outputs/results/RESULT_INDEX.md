# SQL result index

Each CSV is a complete query result, with headers even when zero rows.

| Result | SQL | Statement | Rows |
| --- | --- | --- | --- |
| [sqlite_version.csv](sqlite_version.csv) | sql/00_inspect_database.sql | 1 | 1 |
| [schema_objects.csv](schema_objects.csv) | sql/00_inspect_database.sql | 2 | 7 |
| [schema_columns.csv](schema_columns.csv) | sql/00_inspect_database.sql | 3 | 199 |
| [schema_foreign_keys.csv](schema_foreign_keys.csv) | sql/00_inspect_database.sql | 4 | 31 |
| [schema_ddl.csv](schema_ddl.csv) | sql/00_inspect_database.sql | 5 | 7 |
| [table_counts.csv](table_counts.csv) | sql/00_inspect_database.sql | 6 | 7 |
| [core_table_counts.csv](core_table_counts.csv) | sql/01_profile_core.sql | 1 | 4 |
| [raw_coverage.csv](raw_coverage.csv) | sql/01_profile_core.sql | 2 | 88 |
| [core_missing_values.csv](core_missing_values.csv) | sql/01_profile_core.sql | 3 | 1 |
| [score_date_validity.csv](score_date_validity.csv) | sql/01_profile_core.sql | 4 | 1 |
| [duplicate_match_ids.csv](duplicate_match_ids.csv) | sql/01_profile_core.sql | 5 | 0 |
| [duplicate_dimension_keys.csv](duplicate_dimension_keys.csv) | sql/01_profile_core.sql | 6 | 0 |
| [relationship_checks.csv](relationship_checks.csv) | sql/01_profile_core.sql | 7 | 1 |
| [duplicate_fixtures.csv](duplicate_fixtures.csv) | sql/01_profile_core.sql | 8 | 0 |
| [coverage_audit.csv](coverage_audit.csv) | sql/02_coverage_audit.sql | 1 | 88 |
| [view_validation.csv](view_validation.csv) | sql/04_validate_views.sql | 1 | 10 |
| [accepted_rows.csv](accepted_rows.csv) | sql/04_validate_views.sql | 2 | 1 |
| [first_analysis.csv](first_analysis.csv) | sql/05_first_analysis.sql | 1 | 8 |
| [06_extension_audit_01.csv](06_extension_audit_01.csv) | sql/06_extension_audit.sql | 1 | 2 |
| [06_extension_audit_02.csv](06_extension_audit_02.csv) | sql/06_extension_audit.sql | 2 | 2 |
| [06_extension_audit_03.csv](06_extension_audit_03.csv) | sql/06_extension_audit.sql | 3 | 3 |
| [06_extension_audit_04.csv](06_extension_audit_04.csv) | sql/06_extension_audit.sql | 4 | 11 |
| [overview.csv](overview.csv) | sql/08_overview_and_leagues.sql | 1 | 1 |
| [league_summary.csv](league_summary.csv) | sql/08_overview_and_leagues.sql | 2 | 11 |
| [stable_league_comparison.csv](stable_league_comparison.csv) | sql/08_overview_and_leagues.sql | 3 | 5 |
| [league_season.csv](league_season.csv) | sql/09_season_trends.sql | 1 | 88 |
| [premier_league_seasons.csv](premier_league_seasons.csv) | sql/09_season_trends.sql | 2 | 8 |
| [stable_sample_season_trend.csv](stable_sample_season_trend.csv) | sql/09_season_trends.sql | 3 | 8 |
| [team_season_rankings.csv](team_season_rankings.csv) | sql/10_team_rankings.sql | 1 | 1481 |
| [league_season_ppg_leaders.csv](league_season_ppg_leaders.csv) | sql/10_team_rankings.sql | 2 | 90 |
| [premier_league_2015_16.csv](premier_league_2015_16.csv) | sql/10_team_rankings.sql | 3 | 20 |
| [team_home_away.csv](team_home_away.csv) | sql/11_home_away.sql | 1 | 1481 |
| [premier_league_largest_home_gaps.csv](premier_league_largest_home_gaps.csv) | sql/11_home_away.sql | 2 | 10 |
| [premier_league_2015_16_home_away.csv](premier_league_2015_16_home_away.csv) | sql/11_home_away.sql | 3 | 20 |
| [consecutive_season_changes.csv](consecutive_season_changes.csv) | sql/12_consecutive_season_changes.sql | 1 | 1110 |
| [premier_league_improvements.csv](premier_league_improvements.csv) | sql/12_consecutive_season_changes.sql | 2 | 10 |
| [stable_sample_improvements.csv](stable_sample_improvements.csv) | sql/12_consecutive_season_changes.sql | 3 | 10 |
| [aggregate_validation.csv](aggregate_validation.csv) | sql/13_validate_aggregates.sql | 1 | 12 |
