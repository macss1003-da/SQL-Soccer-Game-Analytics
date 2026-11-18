"""Execute the SQL project read-only and export every result table (stdlib).

python scripts/run_analysis.py --db data/database.sqlite
All TEMP views and their dependent queries run in one SQLite connection.
"""
import argparse
import csv
import hashlib
import json
from pathlib import Path
import re
import sqlite3
import sys


def statements(text):
    buffer = ''
    for line in text.splitlines(keepends=True):
        buffer += line
        if sqlite3.complete_statement(buffer):
            yield buffer
            buffer = ''
    if re.sub(r'--[^\n]*', '', buffer).strip():
        raise ValueError('Unterminated SQL statement')


def file_sha256(path):
    digest = hashlib.sha256()
    with path.open('rb') as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()


def main():
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--db', type=Path, default=root/'data/database.sqlite')
    parser.add_argument('--out', type=Path, default=root/'outputs/results')
    args = parser.parse_args()
    if not args.db.is_file():
        parser.error(f'Database not found: {args.db}. Place the original file in data/.')
    if sqlite3.sqlite_version_info < (3,25,0):
        parser.error('SQLite 3.25 or later is required for window functions.')
    args.out.mkdir(parents=True, exist_ok=True)
    before = file_sha256(args.db)
    connection = sqlite3.connect(args.db.resolve().as_uri()+'?mode=ro', uri=True)
    connection.row_factory = sqlite3.Row
    if [row[0] for row in connection.execute('PRAGMA quick_check')] != ['ok']:
        raise ValueError('SQLite quick_check failed')
    results = {}; catalog = []; failures = []
    count = 0
    for path in sorted((root/'sql').glob('[0-9][0-9]_*.sql')):
        for number, sql in enumerate(statements(path.read_text(encoding='utf-8')), 1):
            cursor = connection.execute(sql)
            count += 1
            if cursor.description is None:
                continue
            marker = re.search(r'^-- result:\s*(\w+)\s*$', sql, flags=re.M)
            name = marker.group(1) if marker else f'{path.stem}_{number:02d}'
            if name in results:
                raise ValueError(f'Duplicate output name: {name}')
            columns = [c[0] for c in cursor.description]
            rows = [dict(row) for row in cursor.fetchall()]
            results[name] = {'columns': columns, 'rows': rows}
            with (args.out/f'{name}.csv').open('w', newline='', encoding='utf-8-sig') as f:
                writer = csv.DictWriter(f, fieldnames=columns)
                writer.writeheader(); writer.writerows(rows)
            catalog.append({'result': name, 'sql_file': str(path.relative_to(root)),
                            'statement': number, 'rows': len(rows)})
            if 'passed' in columns:
                failures += [f'{name}: {row["check_name"]}' for row in rows if row['passed'] != 1]
    connection.close()
    after = file_sha256(args.db)
    if before != after:
        raise RuntimeError('Source database fingerprint changed')
    metadata = {'source_sha256': before, 'source_bytes': args.db.stat().st_size,
                'sqlite_version': sqlite3.sqlite_version, 'integrity_check': 'ok',
                'sql_statements_executed': count, 'source_unchanged': before == after,
                'validation_failures': failures, 'outputs': catalog}
    (args.out/'all_results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
    (args.out/'run_metadata.json').write_text(json.dumps(metadata,ensure_ascii=False,indent=2),encoding='utf-8')
    (args.out/'RESULT_INDEX.md').write_text(
        '# SQL result index\n\nEach CSV is a complete query result, with headers even when zero rows.\n\n'
        '| Result | SQL | Statement | Rows |\n| --- | --- | --- | --- |\n'+''.join(
            f'| [{r["result"]}.csv]({r["result"]}.csv) | {r["sql_file"]} | {r["statement"]} | {r["rows"]} |\n'
            for r in catalog),encoding='utf-8')
    print(json.dumps({'statements':count,'result_tables':len(results),
                      'overview':results['overview']['rows'][0],
                      'validation_failures':failures,'source_unchanged':before==after},
                     ensure_ascii=False,indent=2))
    if failures:
        sys.exit('Validation failed. Review the checks above before reporting findings.')


if __name__ == '__main__':
    main()
