"""Create six exportable portfolio charts from the SQL result snapshot.

Requires matplotlib. No database writes or statistical-model assumptions.
python scripts/make_charts.py
"""
import json
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.ticker import PercentFormatter, MultipleLocator

ROOT=Path(__file__).resolve().parents[1]
DATA=json.loads((ROOT/'outputs/results/all_results.json').read_text(encoding='utf-8'))
OUT=ROOT/'assets';OUT.mkdir(exist_ok=True)
plt.rcParams.update({'font.family':'DejaVu Sans','font.size':11,'axes.titlesize':18,
                     'axes.labelsize':11,'axes.spines.top':False,'axes.spines.right':False,
                     'axes.edgecolor':'#CBD5E1','xtick.color':'#334155','ytick.color':'#334155',
                     'text.color':'#172033','axes.labelcolor':'#334155','figure.facecolor':'white',
                     'savefig.facecolor':'white','svg.fonttype':'none'})
BLUE='#315DA8';TEAL='#07867F';ORANGE='#C56C27';GREY='#64748B'


def finish(fig,ax,name,title,subtitle,footer,left=.12,bottom=.16):
    fig.subplots_adjust(left=left,right=.96,top=.77,bottom=bottom)
    fig.text(.06,.94,title,fontsize=18,fontweight='bold',ha='left',va='top')
    fig.text(.06,.86,subtitle,fontsize=11,color=GREY,ha='left',va='top')
    fig.text(.06,.035,footer,fontsize=9,color=GREY,ha='left',va='bottom')
    ax.set_axisbelow(True)
    for suffix in ['png','svg']:fig.savefig(OUT/f'{name}.{suffix}',dpi=170)
    plt.close(fig)


# 1. All eleven leagues, complete observed sample and explicit denominators.
r=DATA['league_summary']['rows'];fig,ax=plt.subplots(figsize=(12,7.3))
labels=[f'{x["country"]}  (n={x["matches"]:,})' for x in r]
bars=ax.barh(labels,[x['goals_per_match'] for x in r],color=BLUE,height=.63)
ax.invert_yaxis();ax.set_xlim(0,3.6);ax.set_xlabel('Goals per observed match');ax.grid(axis='x',alpha=.18)
ax.bar_label(bars,labels=[f'{x["goals_per_match"]:.3f}' for x in r],padding=7,fontsize=11)
finish(fig,ax,'01_goals_by_league','Scoring differs across the 11 observed leagues',
       '2008/09–2015/16  |  Match-weighted averages; league names are retained in the CSV.',
       'Source: SQL 08, league_summary. Coverage and competition stages vary; this is not a league-quality ranking.',left=.28)

# 2. Comparable eight-year observation window, all seasons shown.
r=DATA['premier_league_seasons']['rows'];seasons=[x['season'][:4]+'/'+x['season'][-2:] for x in r]
fig,ax=plt.subplots(figsize=(11,6.2))
ax.plot(seasons,[100*x['home_win_rate'] for x in r],'-o',color=BLUE,lw=2.3,label='Home wins')
ax.plot(seasons,[100*x['away_win_rate'] for x in r],'-o',color=TEAL,lw=2.3,label='Away wins')
for i in [0,1,7]:
    ax.annotate(f'{r[i]["home_win_rate"]:.2%}',(i,100*r[i]['home_win_rate']),xytext=(0,10),textcoords='offset points',ha='center',fontsize=10,color=BLUE)
ax.annotate(f'{r[-1]["away_win_rate"]:.2%}',(7,100*r[-1]['away_win_rate']),xytext=(0,-18),textcoords='offset points',ha='center',fontsize=10,color=TEAL)
ax.set_ylim(15,58);ax.yaxis.set_major_formatter(PercentFormatter(100));ax.grid(axis='y',alpha=.18)
ax.set_ylabel('Share of matches');ax.legend(loc='lower left',frameon=False,ncol=2)
finish(fig,ax,'02_epl_home_away_trend','Home wins remained more frequent in every EPL season',
       '380 observed matches each season. Draws account for the remaining share.',
       'Source: SQL 09, premier_league_seasons. Changes are descriptive; no causal effect is estimated.')

# 3. Twenty teams, no truncation at a tie. Points reconstructed from scores.
r=DATA['premier_league_2015_16']['rows'];fig,ax=plt.subplots(figsize=(12,9.2))
bars=ax.barh([x['team'] for x in r],[x['points'] for x in r],color=[TEAL]+[BLUE]*(len(r)-1),height=.65)
ax.invert_yaxis();ax.set_xlim(0,94);ax.grid(axis='x',alpha=.18);ax.set_xlabel('Reconstructed points (3 for a win, 1 for a draw)')
ax.bar_label(bars,labels=[str(x['points']) for x in r],padding=6)
finish(fig,ax,'03_epl_2015_16_points','Leicester led the observed 2015/16 EPL results',
       'All 20 teams played 38 matches. Leicester: 23 wins, 12 draws, 3 losses.',
       'Source: SQL 10, premier_league_2015_16. Deductions and official tie-break rules are not applied.',left=.25,bottom=.12)

# 4. All twenty venue differences, including cases where away PPG was higher.
r=DATA['premier_league_2015_16_home_away']['rows'];fig,ax=plt.subplots(figsize=(12,9.2))
bars=ax.barh([x['team'] for x in r],[x['home_away_ppg_gap'] for x in r],
             color=[BLUE if x['home_away_ppg_gap']>=0 else ORANGE for x in r],height=.65)
ax.invert_yaxis();ax.axvline(0,color=GREY,lw=.8);ax.set_xlim(-.28,1.2)
ax.set_xlabel('Home PPG minus away PPG');ax.grid(axis='x',alpha=.18)
ax.bar_label(bars,labels=[f'{x["home_away_ppg_gap"]:+.3f}' for x in r],padding=6,fontsize=10)
finish(fig,ax,'04_epl_2015_16_venue_gap','The home–away difference varies by team',
       'Premier League 2015/16. Each team: 19 home matches and 19 away matches.',
       'Source: SQL 11, premier_league_2015_16_home_away. PPG = points per game; negative values favor away results.',left=.25,bottom=.12)

# 5. Top improvements within the same league and equal season lengths.
r=DATA['premier_league_improvements']['rows'];fig,ax=plt.subplots(figsize=(12,7.3))
labels=[f'{x["team"]}  {x["previous_season"][:4]}/{x["previous_season"][-2:]} → {x["season"][:4]}/{x["season"][-2:]}' for x in r]
bars=ax.barh(labels,[x['points_change'] for x in r],color=[TEAL]+[BLUE]*9,height=.64)
ax.invert_yaxis();ax.set_xlim(0,47);ax.grid(axis='x',alpha=.18);ax.set_xlabel('Increase in reconstructed points')
ax.bar_label(bars,labels=[f'+{x["points_change"]}' for x in r],padding=7)
finish(fig,ax,'05_epl_improvements','Leicester had the largest adjacent-season EPL improvement',
       'Top 10 of 119 comparisons. Same team and league, consecutive seasons, 38 games in each.',
       'Source: SQL 12, premier_league_improvements. Leicester rose from 41 to 81 points (+1.053 PPG).',left=.43)

# 6. Consistent league membership through time, all eight seasons in each.
r=DATA['league_season']['rows'];fig,ax=plt.subplots(figsize=(11.5,6.5))
palette={'England':BLUE,'France':GREY,'Germany':ORANGE,'Netherlands':TEAL,'Spain':'#8751A6'}
for country,color in palette.items():
    points=sorted([x for x in r if x['country']==country and x['stable_comparison_sample']],key=lambda x:x['season'])
    ax.plot(seasons,[x['goals_per_match'] for x in points],'-o',lw=1.9,ms=4,label=country,color=color)
ax.set_ylim(2.1,3.5);ax.set_ylabel('Goals per observed match');ax.grid(axis='y',alpha=.18)
ax.legend(loc='upper center',bbox_to_anchor=(.5,-.13),ncol=5,frameon=False)
finish(fig,ax,'06_stable_leagues_scoring_trend','A fixed set of leagues makes the time comparison clearer',
       'Five leagues, eight seasons, 14,016 matches. Each observed schedule has two meetings per pair.',
       'Source: SQL 09, league_season. Internal schedule balance does not adjust for opponent strength.',bottom=.23)
print('Created 6 PNG charts and 6 SVG charts')
