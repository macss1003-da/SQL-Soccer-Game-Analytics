"""Optional: inspect XML structure using Python's standard library.
Run from repository root: python scripts/profile_xml.py data/database.sqlite
Output is JSON on stdout. Non-empty XML is not a completeness guarantee.
"""
import argparse
import json
from pathlib import Path
import sqlite3
import xml.etree.ElementTree as ET

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('database', type=Path)
    args = parser.parse_args()
    db = args.database.expanduser().resolve(strict=True)
    con = sqlite3.connect(db.as_uri() + '?mode=ro', uri=True)
    results = {}
    for column in ['goal','shoton','shotoff','foulcommit','card','cross','corner','possession']:
        stats = dict(nonnull_rows=0,empty_text_rows=0,xml_parse_errors=0,
                     empty_xml_roots=0,xml_rows_with_children=0)
        for (value,) in con.execute('SELECT "' + column + '" FROM "Match" WHERE "' + column + '" IS NOT NULL'):
            stats['nonnull_rows'] += 1
            if not str(value).strip():
                stats['empty_text_rows'] += 1
                continue
            try:
                elem = ET.fromstring(value)
                stats['xml_rows_with_children' if len(elem) else 'empty_xml_roots'] += 1
            except ET.ParseError:
                stats['xml_parse_errors'] += 1
        results[column] = stats
    con.close()
    print(json.dumps(results, ensure_ascii=False, indent=2))

if __name__ == '__main__':
    main()
