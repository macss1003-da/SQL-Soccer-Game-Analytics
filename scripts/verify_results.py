"""Independently reconcile exported SQL aggregates to raw Match records.

Uses Python accumulation and exact Fraction ranks rather than SQL views.
Run after run_analysis.py. This is a data reconciliation, not an official
fixture/standings validation.
"""
import argparse
from collections import defaultdict
from fractions import Fraction
import json
from pathlib import Path
import sqlite3


def main():
    root = Path(__file__).resolve().parents[1]
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--db', type=Path, default=root/'data/database.sqlite')
    p.add_argument('--results', type=Path, default=root/'outputs/results/all_results.json')
    args = p.parse_args()
    results = json.loads(args.results.read_text(encoding='utf-8'))
    con = sqlite3.connect(args.db.resolve().as_uri()+'?mode=ro', uri=True)
    teams = defaultdict(lambda: defaultdict(int))
    leagues = defaultdict(lambda: defaultdict(int))
    for league, season, home, away, hg, ag in con.execute(
        'SELECT league_id,season,home_team_api_id,away_team_api_id,home_team_goal,away_team_goal FROM "Match"'
    ):
        ls = leagues[league,season]
        ls['matches'] += 1; ls['total_goals'] += hg+ag
        ls['home_wins'] += hg>ag; ls['draws'] += hg==ag; ls['away_wins'] += hg<ag
        for team,gf,ga,venue in [(home,hg,ag,'home'),(away,ag,hg,'away')]:
            row=teams[league,season,team]
            points=3 if gf>ga else 1 if gf==ga else 0
            row['played']+=1;row['wins']+=gf>ga;row['draws']+=gf==ga;row['losses']+=gf<ga
            row['goals_for']+=gf;row['goals_against']+=ga;row['goal_difference']+=gf-ga
            row['points']+=points;row[venue+'_points']+=points;row[venue+'_played']+=1
    con.close()
    sqlteams=results['team_season_rankings']['rows']
    assert len(teams)==len(sqlteams)
    for row in sqlteams:
        raw=teams[row['league_id'],row['season'],row['team_api_id']]
        for field in ['played','wins','draws','losses','goals_for','goals_against','goal_difference','points']:
            assert row[field]==raw[field],(row['team'],row['season'],field)
        ratios={Fraction(v['points'],v['played']) for k,v in teams.items() if k[:2]==(row['league_id'],row['season'])}
        expected_rank=sorted(ratios,reverse=True).index(Fraction(raw['points'],raw['played']))+1
        assert row['ppg_rank']==expected_rank
    for row in results['team_home_away']['rows']:
        raw=teams[row['league_id'],row['season'],row['team_api_id']]
        for field in ['home_played','away_played','home_points','away_points']:
            assert row[field]==raw[field]
        gap=Fraction(raw['home_points'],raw['home_played'])-Fraction(raw['away_points'],raw['away_played'])
        assert abs(row['home_away_ppg_gap']-float(gap))<1e-12
    for row in results['league_season']['rows']:
        raw=leagues[row['league_id'],row['season']]
        for field,value in raw.items(): assert row[field]==value
    sqlchange={(r['league_id'],r['season'],r['team_api_id']):r for r in results['consecutive_season_changes']['rows']}
    expected_changes=0
    for (league,season,team),row in teams.items():
        year=int(season[:4]);previous=f'{year-1}/{year}'
        prev=teams.get((league,previous,team))
        if prev is None: continue
        expected_changes+=1
        delta=Fraction(row['points'],row['played'])-Fraction(prev['points'],prev['played'])
        actual=sqlchange[league,season,team]
        assert actual['previous_season']==previous
        assert abs(actual['ppg_change']-float(delta))<1e-12
    assert expected_changes==len(sqlchange)
    evidence={'method':'Raw Match accumulation in Python; exact Fraction ranks and changes',
              'team_seasons_reconciled':len(teams),'league_seasons_reconciled':len(leagues),
              'consecutive_changes_reconciled':expected_changes,'result':'PASS'}
    (args.results.parent/'independent_verification.json').write_text(json.dumps(evidence,indent=2),encoding='utf-8')
    print(json.dumps(evidence,indent=2))


if __name__=='__main__':main()
