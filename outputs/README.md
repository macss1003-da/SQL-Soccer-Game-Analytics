# Analysis outputs

The completed analysis is in `results/`: 38 complete CSV query outputs, JSON snapshots, run metadata, independent reconciliation, and RESULT_INDEX.md. The largest tables are 1,481 team-seasons and 1,110 consecutive-season changes. Empty audit CSVs retain their headers and indicate no rows matched the issue query.

`SOCCER_RESULTS.xlsx` is a five-sheet review snapshot. Formula-based metrics can be inspected; SQL ranks and selected rows refresh through the SQL pipeline, not automatically inside Excel.

`FIRST_ANALYSIS.md`, `LEAGUE_SEASON_COVERAGE.md`, `VALIDATION.md`, `database_audit.json` and `verified_query_results.json` retain the earlier profiling evidence for the same source fingerprint. The final report is `docs/BAO_CAO_KET_QUA.md`. Six charts are in `assets/`.

Rates in full CSV/JSON use fractions (0.4587 means 45.87%), except columns explicitly suffixed `_pp`, which contain percentage points. Report tables and chart labels are rounded for display only.
