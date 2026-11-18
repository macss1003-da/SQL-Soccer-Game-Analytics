from pathlib import Path
import json, base64, hashlib, re, shutil, argparse
from collections import Counter

ap=argparse.ArgumentParser(description='Build a portable Power BI project from the verified Soccer dashboard snapshot. No third-party Python dependencies.')
ap.add_argument('--input',required=True,help='dashboard_snapshot.json')
ap.add_argument('--output',required=True,help='Output project folder')
ap.add_argument('--source-html',help='Optional original HTML file for provenance fingerprint')
args=ap.parse_args()
OUT = Path(args.output).resolve()
SRC = json.loads(Path(args.input).read_text(encoding='utf-8'))
if args.source_html:
    SRC['dashboard_html_sha256']=hashlib.sha256(Path(args.source_html).read_bytes()).hexdigest()
R = SRC['results']
REPORT = OUT/'SoccerAnalytics.Report'
MODEL = OUT/'SoccerAnalytics.SemanticModel'
SC = 'https://developer.microsoft.com/json-schemas/fabric/'
DEF = SC+'item/report/definition/'
TEAL='#137C75'; DARK='#102E35'; MUTED='#587077'; BG='#F3F6F5'; MINT='#B8EF79'; RED='#B85247'

def dump(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

def rows(k): return R[k]['rows']
def uid(s): return hashlib.sha256(s.encode()).hexdigest()[:20]
def key(r): return (r['league_id'],r['season'],r.get('team_api_id'))

leagues={r['league_id']:{k:r[k] for k in ['league_id','league','country','stable_comparison_sample']} for r in rows('league_season')}
for r in leagues.values():
    r['sample_group']='5 giải có cấu trúc ổn định' if r['stable_comparison_sample'] else 'Các giải còn lại'
seasons=[{'season':s,'start_year':int(s[:4])} for s in sorted({r['season'] for r in rows('league_season')})]
teams={r['team_api_id']:{'team_api_id':r['team_api_id'],'team':r['team']} for r in rows('team_season_rankings')}
team_name_counts=Counter(t['team'].casefold() for t in teams.values())
for t in teams.values():
    t['team_label']=t['team']+(f" [{t['team_api_id']}]" if team_name_counts[t['team'].casefold()]>1 else '')
venue={key(r):r for r in rows('team_home_away')}
team_facts=[]
for r in rows('team_season_rankings'):
    t=dict(r); t.update({k:v for k,v in venue[key(r)].items() if k.startswith(('home_','away_'))})
    t['team_label']=teams[r['team_api_id']]['team_label']
    t['TeamSeasonKey']=f"{r['league_id']}_{r['season']}_{r['team_api_id']}"
    team_facts.append(t)
changes=[]
for r in rows('consecutive_season_changes'):
    t=dict(r)
    t['PairKey']=f"{r['league_id']}_{r['season']}_{r['team_api_id']}"
    t['team_label']=teams[r['team_api_id']]['team_label']
    t['PairLabel']=f"{t['team_label']} · {r['season']} · {leagues[r['league_id']]['country']}"
    changes.append(t)
checks=[dict(r,group=g,status='Đạt' if r['passed'] else 'Không đạt') for k,g in [('view_validation','Kiểm tra view'),('aggregate_validation','Kiểm tra tổng hợp')] for r in rows(k)]
warnings=[]
translations={
    'Narrow subset: 12 matches, 4 observed teams':'Phạm vi hẹp: 12 trận, 4 đội; không đại diện toàn mùa.',
    'Uneven schedule: 358 matches, 34-38 games per team':'Số trận không đều: 34–38 trận/đội.',
    'Uneven schedule: 379 matches, 37-38 games per team':'Số trận không đều: 37–38 trận/đội.',
    'Uneven schedule: 162 matches, 18-34 games per team':'Số trận không đều: 18–34 trận/đội.'}
for r in rows('league_season'):
    if r['coverage_note'] in translations:
        warnings.append({'league':r['league'],'season':r['season'],'matches':r['matches'],'note':translations[r['coverage_note']]})
catalog=[{'result_table':k,'model_table':'SQL_'+k,'row_count':len(v['rows']),'column_count':len(v['columns'])} for k,v in R.items()]
OUT.mkdir(parents=True,exist_ok=True)
dump(OUT/'data/all_results.json',R)
dump(OUT/'data/dashboard_snapshot.json',SRC)
dump(OUT/'data/source_metadata.json',{'metadata':SRC['metadata'],'verification':SRC['verification'],'dashboard_html_sha256':SRC.get('dashboard_html_sha256')})
(OUT/'data/ALL_SOCCER_ANALYSIS.sql').write_text(SRC['sql'],encoding='utf-8')

tables=[]; table_payloads={}; measures=[]
def add_table(name,data,columns=None,description='',hidden=False):
    columns=columns or list(data[0])
    schema=[]; types=[]
    for c in columns:
        vals=[r[c] for r in data if r.get(c) is not None]
        if vals and all(isinstance(x,bool) for x in vals): dtype,mt='boolean','type logical'
        elif vals and all(isinstance(x,int) and not isinstance(x,bool) for x in vals):dtype,mt='int64','Int64.Type'
        elif vals and all(isinstance(x,(int,float)) and not isinstance(x,bool) for x in vals):dtype,mt='double','type number'
        else:dtype,mt='string','type text'
        col={'name':c,'dataType':dtype,'sourceColumn':c,'summarizeBy':'none'}
        if dtype=='int64':col['formatString']='#,0'
        elif dtype=='double':col['formatString']='0.00'
        if name=='DimSeason' and c=='season':col['sortByColumn']='start_year'
        if name=='DimOutcome' and c=='label':col['sortByColumn']='sort_order'
        if c in ['league_id','team_api_id','start_year','stable_comparison_sample','TeamSeasonKey','PairKey','_dummy','code','sort_order']:col['isHidden']=True
        schema.append(col);types.append('{'+json.dumps(c,ensure_ascii=False)+', '+mt+'}')
    vals=[[r.get(c) for c in columns] for r in data]
    # Inline UTF-8 JSON avoids machine-specific file paths, SQLite drivers and credentials.
    enc=base64.b64encode(json.dumps(vals,ensure_ascii=False,separators=(',',':'),allow_nan=False).encode()).decode()
    chunks=[enc[i:i+12000] for i in range(0,len(enc),12000)] or ['']
    expression=['let','    Encoded = Text.Combine({'+', '.join('"'+s+'"' for s in chunks)+'}, ""),','    Source = Json.Document(Binary.FromText(Encoded, BinaryEncoding.Base64)),','    Data = Table.FromRows(Source, {'+', '.join(json.dumps(c,ensure_ascii=False) for c in columns)+'}),','    Typed = Table.TransformColumnTypes(Data, {'+', '.join(types)+'}, "en-US")','in','    Typed']
    t={'name':name,'description':description,'columns':schema,'partitions':[{'name':name,'mode':'import','source':{'type':'m','expression':expression}}],'annotations':[{'name':'PBI_ResultType','value':'Table'}]}
    if hidden:t['isHidden']=True
    tables.append(t);table_payloads[name]={'columns':columns,'rows':data}
    return t

add_table('DimLeague',list(leagues.values()),description='One row per league. Stable group means observed schedule structure reviewed, not proof of official completeness.')
add_table('DimSeason',seasons,description='Season filter. For FactSeasonChange this is the later season.')
add_table('DimTeam',list(teams.values()),description='299 teams that participated in the observed matches.')
add_table('DimOutcome',[{'code':'H','label':'Chủ nhà thắng','sort_order':1},{'code':'D','label':'Hòa','sort_order':2},{'code':'A','label':'Khách thắng','sort_order':3}],description='Disconnected outcome legend, used by the Outcome Matches measure.')
add_table('FactLeagueSeason',rows('league_season'),description='88 league-season aggregates. Ratios must be recomputed from sums, not averaged.')
add_table('FactTeamSeason',team_facts,description='1481 team-season rows, joined 1:1 with home/away results. ppg_rank preserves SQL DENSE_RANK within league-season, no official tie breaks or point deductions.')
add_table('FactSeasonChange',changes,description='1110 consecutive same-team, same-league season pairs. Missing previous seasons are absent, not zeros.')
add_table('DataChecks',checks,description='22 original SQL checks, disconnected from report slicers.')
add_table('CoverageWarnings',warnings,description='Four notable source coverage warnings. Other competition-format limitations remain applicable.')
add_table('ResultCatalog',catalog,description='All 38 original SQL result sets; open the associated SQL_ table in Table view.')
add_table('RunInfo',[{'sql_statements':SRC['metadata']['sql_statements_executed'],'source_sha256':SRC['metadata']['source_sha256'],'integrity_check':SRC['metadata']['integrity_check'],'source_unchanged':str(SRC['metadata']['source_unchanged'])}],description='Source run provenance; metadata records the original SQLite execution environment.')
mt=add_table('Measures',[{'_dummy':1}],description='Explicit measures. Ratios recompute under filter context; main report uses these measures.')

def measure(name,expr,fmt='#,0',folder='01 Tổng quan',description=None):
    d={'name':name,'expression':expr,'formatString':fmt,'displayFolder':folder}
    if description:d['description']=description
    measures.append(d)
F='FactLeagueSeason';T='FactTeamSeason';C='FactSeasonChange'
for n,c in [('Matches','matches'),('Goals','total_goals'),('Home Goals','home_goals'),('Away Goals','away_goals'),('Home Wins','home_wins'),('Draws','draws'),('Away Wins','away_wins')]:measure(n,f"SUM ( '{F}'[{c}] )")
measure('Goals per Match','DIVIDE ( [Goals], [Matches] )','0.00')
measure('Home Win Rate','DIVIDE ( [Home Wins], [Matches] )','0.0%')
measure('Draw Rate','DIVIDE ( [Draws], [Matches] )','0.0%')
measure('Away Win Rate','DIVIDE ( [Away Wins], [Matches] )','0.0%')
measure('Outcome Matches','SWITCH ( SELECTEDVALUE ( DimOutcome[code] ), "H", [Home Wins], "D", [Draws], "A", [Away Wins] )')
measure('Participating Teams',f"DISTINCTCOUNT ( '{T}'[team_api_id] )")
measure('League Seasons',f"COUNTROWS ( '{F}' )")
for n,c in [('Team Games','played'),('Team Points','points'),('Team Wins','wins'),('Team Goals For','goals_for'),('Team Goals Against','goals_against')]:measure(n,f"SUM ( '{T}'[{c}] )",folder='02 Đội bóng')
measure('Team Seasons',f"COUNTROWS ( '{T}' )",folder='02 Đội bóng')
measure('Team PPG','DIVIDE ( [Team Points], [Team Games] )','0.00','02 Đội bóng','Weighted points per game for selected teams/seasons. Not an average of rounded PPG.')
measure('Team Win Rate','DIVIDE ( [Team Wins], [Team Games] )','0.0%','02 Đội bóng')
for n,c in [('Home Team Games','home_played'),('Away Team Games','away_played'),('Home Team Points','home_points'),('Away Team Points','away_points')]:measure(n,f"SUM ( '{T}'[{c}] )",folder='03 Sân nhà và sân khách')
measure('Home PPG','DIVIDE ( [Home Team Points], [Home Team Games] )','0.00','03 Sân nhà và sân khách')
measure('Away PPG','DIVIDE ( [Away Team Points], [Away Team Games] )','0.00','03 Sân nhà và sân khách')
measure('Venue PPG Gap','[Home PPG] - [Away PPG]','+0.00;-0.00;0.00','03 Sân nhà và sân khách')
measure('Change Pairs',f"COUNTROWS ( '{C}' )",folder='04 Thay đổi qua mùa')
measure('Improved Pairs',f"COUNTROWS ( FILTER ( '{C}', '{C}'[ppg_change] > 0 ) )",folder='04 Thay đổi qua mùa')
measure('Declined Pairs',f"COUNTROWS ( FILTER ( '{C}', '{C}'[ppg_change] < 0 ) )",folder='04 Thay đổi qua mùa')
measure('Mean PPG Change',f"AVERAGE ( '{C}'[ppg_change] )",'+0.00;-0.00;0.00','04 Thay đổi qua mùa','Arithmetic mean of valid paired PPG changes, not a weighted cohort performance measure.')
measure('Pair PPG Change',f"IF ( HASONEVALUE ( '{C}'[PairKey] ), MAX ( '{C}'[ppg_change] ) )",'+0.00;-0.00;0.00','04 Thay đổi qua mùa')

def top_measure(name,base,entity,col,keycol,desc=True,sign=None):
    order='DESC' if desc else 'ASC'
    target=f"'{entity}'[{col}]"
    predicate='NOT ISBLANK ( [__score] )'+(' && [__score] '+sign+' 0' if sign else '')
    # ALLSELECTED removes the chart category while preserving page/slicer selections.
    expr=f'''VAR Candidates = FILTER ( ADDCOLUMNS ( ALLSELECTED ( {target} ), "__score", [{base}] ), {predicate} )
VAR Chosen = TOPN ( 10, Candidates, [__score], {order}, {target}, ASC )
RETURN IF ( CONTAINS ( Chosen, {target}, SELECTEDVALUE ( {target} ) ), [{base}] )'''
    measure(name,expr,'0.00','90 Biểu đồ Top 10')

top_measure('Top Team PPG','Team PPG','DimTeam','team_label','team_api_id')
top_measure('Top Home Gap','Venue PPG Gap','DimTeam','team_label','team_api_id',True,'>')
top_measure('Top Away Gap','Venue PPG Gap','DimTeam','team_label','team_api_id',False,'<')
top_measure('Top Improvements','Pair PPG Change',C,'PairLabel','PairKey',True,'>')
top_measure('Top Declines','Pair PPG Change',C,'PairLabel','PairKey',False,'<')
measure('Checks Passed','COUNTROWS ( FILTER ( DataChecks, DataChecks[passed] = 1 ) )',folder='05 Kiểm tra')
measure('Checks Failed','COALESCE ( COUNTROWS ( FILTER ( DataChecks, DataChecks[passed] <> 1 ) ), 0 )',folder='05 Kiểm tra')
measure('Source Result Tables','COUNTROWS ( ResultCatalog )',folder='05 Kiểm tra')
measure('SQL Statements','MAX ( RunInfo[sql_statements] )',folder='05 Kiểm tra')
measure('Notable Warnings','COUNTROWS ( CoverageWarnings )',folder='05 Kiểm tra')
mt['measures']=measures
for name,data in R.items():add_table('SQL_'+name,data['rows'],data['columns'],'Original SQL result set. Disconnected archival table; not affected by report slicers.')

relationships=[]
for fact in [F,T,C]:
    dims=[('league_id','DimLeague','league_id'),('season','DimSeason','season')]
    if fact in [T,C]:dims.append(('team_api_id','DimTeam','team_api_id'))
    for col,dim,dc in dims:
        relationships.append({'name':uid(fact+dim),'fromTable':fact,'fromColumn':col,'fromCardinality':'many','toTable':dim,'toColumn':dc,'toCardinality':'one','isActive':True,'crossFilteringBehavior':'oneDirection'})
dump(MODEL/'definition.pbism',{'$schema':SC+'item/semanticModel/definitionProperties/1.0.0/schema.json','version':'1.0','settings':{'qnaEnabled':False}})
dump(MODEL/'model.bim',{'name':'SoccerAnalytics','compatibilityLevel':1567,'model':{'culture':'en-US','sourceQueryCulture':'en-US','defaultPowerBIDataSourceVersion':'powerBI_V3','tables':tables,'relationships':relationships,'annotations':[{'name':'__PBI_TimeIntelligenceEnabled','value':'0'},{'name':'PBI_QueryOrder','value':json.dumps([t['name'] for t in tables])}]}})
dump(OUT/'SoccerAnalytics.pbip',{'$schema':SC+'pbip/pbipProperties/1.0.0/schema.json','version':'1.0','artifacts':[{'report':{'path':'SoccerAnalytics.Report'}}],'settings':{'enableAutoRecovery':True}})
dump(REPORT/'definition.pbir',{'$schema':SC+'item/report/definitionProperties/2.0.0/schema.json','version':'4.0','datasetReference':{'byPath':{'path':'../SoccerAnalytics.SemanticModel'}}})

theme={'name':'Soccer Portfolio','dataColors':[TEAL,'#91A4A7',MINT,'#E0AE62',RED,'#497FB1'],'background':'#FFFFFF','foreground':DARK,'tableAccent':TEAL,'good':TEAL,'neutral':'#DDA653','bad':RED,'textClasses':{'callout':{'fontFace':'Segoe UI','fontSize':30,'color':DARK},'title':{'fontFace':'Segoe UI Semibold','fontSize':14,'color':DARK},'header':{'fontFace':'Segoe UI Semibold','fontSize':12,'color':DARK},'label':{'fontFace':'Segoe UI','fontSize':11,'color':MUTED}}}
dump(REPORT/'StaticResources/RegisteredResources/SoccerPortfolio.json',theme)
dump(REPORT/'definition/report.json',{'$schema':DEF+'report/3.0.0/schema.json','themeCollection':{'customTheme':{'name':'SoccerPortfolio','reportVersionAtImport':{'visual':'2.1.0','page':'2.0.0','report':'3.0.0'},'type':'RegisteredResources'}},'resourcePackages':[{'name':'RegisteredResources','type':'RegisteredResources','items':[{'name':'SoccerPortfolio','path':'SoccerPortfolio.json','type':'CustomTheme'}]}],'settings':{'useStylableVisualContainerHeader':True,'defaultFilterActionIsDataFilter':True,'defaultDrillFilterOtherVisuals':True,'allowChangeFilterTypes':True,'useEnhancedTooltips':True}})
dump(REPORT/'definition/version.json',{'$schema':DEF+'versionMetadata/1.0.0/schema.json','version':'4.0.0'})

def lit(v):
    if isinstance(v,bool):s=str(v).lower()
    elif isinstance(v,(float,int)):s=str(v)+'D'
    else:s="'"+str(v).replace("'","''")+"'"
    return {'expr':{'Literal':{'Value':s}}}
def color(v): return {'solid':{'color':lit(v)}}
def props(**kwargs):return [{'properties':kwargs}]
def field(table,column,kind='Column'):return {kind:{'Expression':{'SourceRef':{'Entity':table}},'Property':column}}
def projection(table,col,label=None,kind='Column',active=None):
    x={'field':field(table,col,kind),'queryRef':table+'.'+col,'nativeQueryRef':label or col,'displayName':label or col}
    if active is not None:x['active']=active
    return x
def mp(name,label=None):return projection('Measures',name,label,'Measure')

PAGES=[];VISUALS=[];seq=0
def page(name,title,subtitle):
    p={'$schema':DEF+'page/2.0.0/schema.json','name':name,'displayName':title,'displayOption':'FitToPage','height':960,'width':1440,'objects':{'background':props(color=color(BG),transparency=lit(0))}}
    PAGES.append(p)
    textbox(p,'SOCCER / SQL ANALYTICS',32,14,800,23,10,TEAL,bold=True)
    textbox(p,title,32,40,1360,48,26,DARK,bold=True)
    textbox(p,subtitle,32,90,1376,36,11,MUTED)
    textbox(p,'Kaggle European Soccer Database · 2008/09–2015/16 · Điểm 3/1/0 · Kết quả mô tả trong phạm vi dữ liệu quan sát',32,929,1360,25,9,MUTED)
    return p
def visual(p,typ,title,x,y,w,h,query=None,objects=None,bg='#FFFFFF',sort=None):
    global seq
    seq+=1; name=uid(p['name']+'_'+str(seq))
    v={'$schema':DEF+'visualContainer/2.1.0/schema.json','name':name,'position':{'x':x,'y':y,'z':seq*1000,'width':w,'height':h,'tabOrder':seq*1000},'visual':{'visualType':typ,'visualContainerObjects':{'background':props(show=lit(True),color=color(bg),transparency=lit(0)),'border':props(show=lit(True),color=color('#E0E8E5'),radius=lit(8)),'title':props(show=lit(bool(title)),text=lit(title or ''),fontColor=color(DARK),fontSize=lit(13),fontFamily=lit('Segoe UI Semibold'),titleWrap=lit(True))}}}
    if query:
        v['visual']['query']={'queryState':{k:{'projections':vals} for k,vals in query.items()}}
        if sort:v['visual']['query']['sortDefinition']={'sort':[{'field':sort[0],'direction':sort[1]}]}
    if objects:v['visual']['objects']=objects
    VISUALS.append((p,v));return v
def textbox(p,text,x,y,w,h,size=12,fg=DARK,bg=BG,bold=False):
    style={'fontFamily':'Segoe UI','fontSize':f'{size}pt','color':fg}
    if bold:style['fontWeight']='bold'
    v=visual(p,'textbox',None,x,y,w,h,objects={'general':props(paragraphs=[{'textRuns':[{'value':text,'textStyle':style}]}])},bg=bg)
    v['visual']['visualContainerObjects']['border']=props(show=lit(False))
    return v
def slicer(p,table,col,title,x,w,group):
    v=visual(p,'slicer',title,x,138,w,67,{'Values':[projection(table,col,title,active=True)]},{'data':props(mode=lit('Dropdown')),'selection':props(singleSelect=lit(False),selectAllCheckboxEnabled=lit(True)),'header':props(show=lit(False)),'items':props(textSize=lit(11),fontColor=color(DARK))})
    v['visual']['syncGroup']={'groupName':group,'fieldChanges':True,'filterChanges':True};return v
def filters(p,team=False):
    width=330 if team else 445
    fields=[('DimLeague','league','Giải đấu','league'),('DimSeason','season','Mùa giải','season')]
    if team:fields.append(('DimTeam','team_label','Đội bóng','team'))
    fields.append(('DimLeague','sample_group','Nhóm so sánh','sample'))
    for i,(t,c,l,g) in enumerate(fields):slicer(p,t,c,l,32+i*(width+16),width,g)
def cards(p,items):
    n=len(items);w=(1376-(n-1)*16)/n
    for i,(m,l) in enumerate(items):
        v=visual(p,'card',l,32+i*(w+16),225,w,104,{'Values':[mp(m,l)]},{'labels':props(fontSize=lit(30),color=color(TEAL),labelDisplayUnits=lit(1),labelPrecision=lit(2 if ('PPG' in m or 'per Match' in m or 'Gap' in m or 'Change' in m and m!='Change Pairs') else (1 if 'Rate' in m else 0))),'categoryLabels':props(show=lit(False))})
def chart(p,typ,title,cat,ms,x,y,w,h,sortby=None,ascending=False,fg=None):
    obj={'categoryAxis':props(show=lit(True),fontSize=lit(10),labelColor=color(MUTED),showAxisTitle=lit(False)),'valueAxis':props(show=lit(True),fontSize=lit(10),labelColor=color(MUTED),showAxisTitle=lit(False)),'labels':props(show=lit(typ!='lineChart'),fontSize=lit(10),labelDisplayUnits=lit(1),labelPrecision=lit(2)),'legend':props(show=lit(len(ms)>1),fontSize=lit(11))}
    if fg:obj['dataPoint']=props(defaultColor=color(fg))
    if typ=='lineChart':obj['lineStyles']=props(strokeWidth=lit(3),showMarker=lit(True))
    return visual(p,typ,title,x,y,w,h,{'Category':[cat],'Y':[mp(*m) if isinstance(m,tuple) else mp(m) for m in ms]},obj,sort=(field('Measures',sortby,'Measure') if sortby else cat['field'],'Ascending' if ascending or not sortby else 'Descending'))
def table(p,title,cols,x,y,w,h,sort=None):
    return visual(p,'tableEx',title,x,y,w,h,{'Values':cols},{'columnHeaders':props(fontSize=lit(10),fontColor=color(DARK),backColor=color('#EBF1EF'),wordWrap=lit(True)),'values':props(fontSize=lit(10),fontColorPrimary=color(DARK),wordWrap=lit(False)),'grid':props(gridVertical=lit(False),gridHorizontal=lit(True),rowPadding=lit(5)),'total':props(totals=lit(False))},sort=sort)

p=page('01_Overview','01 · Tổng quan giải đấu','Theo dõi quy mô, mức ghi bàn và kết quả trận đấu. Mọi tỷ lệ được tính lại từ tổng tử số và mẫu số theo bộ lọc.')
filters(p)
cards(p,[('Matches','SỐ TRẬN'),('Goals','TỔNG BÀN THẮNG'),('Goals per Match','BÀN THẮNG / TRẬN'),('Home Win Rate','TỶ LỆ CHỦ NHÀ THẮNG'),('Participating Teams','ĐỘI THAM DỰ')])
chart(p,'barChart','Mức ghi bàn theo giải',projection('DimLeague','league','Giải'),[('Goals per Match','Bàn/trận')],32,350,790,300,'Goals per Match',fg=TEAL)
visual(p,'donutChart','Kết quả trận đấu',846,350,562,300,{'Category':[projection('DimOutcome','label','Kết quả')],'Y':[mp('Outcome Matches','Số trận')]},{'legend':props(show=lit(True),position=lit('Bottom'),fontSize=lit(11)),'labels':props(show=lit(True),labelStyle=lit('Percent of total'),fontSize=lit(11))})
chart(p,'lineChart','Xu hướng bàn thắng / trận',projection('DimSeason','season','Mùa'),[('Goals per Match','Bàn/trận')],32,672,670,240,fg=TEAL)
table(p,'Bảng tổng hợp theo giải',[projection('DimLeague','league','Giải'),mp('Matches','Trận'),mp('Goals','Bàn'),mp('Goals per Match','Bàn/trận'),mp('Home Win Rate','Chủ nhà thắng')],726,672,682,240)

p=page('02_Teams','02 · Thành tích đội bóng','Điểm/trận (PPG) được tính có trọng số theo số trận. Thứ hạng ở bảng chi tiết giữ nguyên trong từng giải–mùa; chưa áp dụng luật phụ hoặc trừ điểm.')
filters(p,True)
cards(p,[('Participating Teams','ĐỘI ĐANG CHỌN'),('Team Seasons','DÒNG ĐỘI–MÙA'),('Team Games','LƯỢT ĐỘI THI ĐẤU'),('Team Points','TỔNG ĐIỂM'),('Team PPG','ĐIỂM / TRẬN')])
chart(p,'barChart','10 đội có PPG cao nhất trong phạm vi chọn',projection('DimTeam','team_label','Đội'),[('Top Team PPG','PPG')],32,350,790,290,'Top Team PPG',fg=TEAL)
chart(p,'lineChart','PPG của nhóm đội đang chọn theo mùa',projection('DimSeason','season','Mùa'),[('Team PPG','PPG')],846,350,562,290,fg=TEAL)
teamcols=[('league','Giải'),('season','Mùa'),('team_label','Đội'),('ppg_rank','Hạng PPG'),('played','Trận'),('wins','Thắng'),('draws','Hòa'),('losses','Thua'),('points','Điểm'),('ppg','PPG'),('goals_for','Bàn thắng'),('goals_against','Bàn thua')]
table(p,'Thành tích từng đội–mùa • thứ hạng mô tả từ SQL',[projection(T,c,l) for c,l in teamcols],32,662,1376,250)

p=page('03_Venue','03 · Sân nhà và sân khách','Chênh lệch PPG = điểm/trận sân nhà − điểm/trận sân khách. Giá trị âm nghĩa là đội có PPG sân khách cao hơn trong phạm vi chọn.')
filters(p,True)
cards(p,[('Home Team Games','LƯỢT SÂN NHÀ'),('Away Team Games','LƯỢT SÂN KHÁCH'),('Home PPG','PPG SÂN NHÀ'),('Away PPG','PPG SÂN KHÁCH'),('Venue PPG Gap','CHÊNH LỆCH PPG')])
chart(p,'barChart','10 đội có lợi thế sân nhà lớn nhất',projection('DimTeam','team_label','Đội'),[('Top Home Gap','Chênh lệch PPG')],32,350,676,290,'Top Home Gap',fg=TEAL)
chart(p,'barChart','Tối đa 10 đội có PPG sân khách cao hơn',projection('DimTeam','team_label','Đội'),[('Top Away Gap','Chênh lệch PPG')],732,350,676,290,'Top Away Gap',True,RED)
vcols=[('league','Giải'),('season','Mùa'),('team_label','Đội'),('home_played','Trận nhà'),('away_played','Trận khách'),('home_points','Điểm nhà'),('away_points','Điểm khách'),('home_ppg','PPG nhà'),('away_ppg','PPG khách'),('home_away_ppg_gap','Chênh lệch')]
table(p,'So sánh sân nhà / sân khách từng đội–mùa',[projection(T,c,l) for c,l in vcols],32,662,1376,250)

p=page('04_Changes','04 · Thay đổi qua mùa','Bộ lọc mùa chỉ mùa SAU của cặp so sánh. Chỉ giữ mùa liên tiếp, cùng đội và cùng giải. Đội thiếu mùa trước sẽ không xuất hiện; không gán bằng 0.')
filters(p,True)
cards(p,[('Change Pairs','CẶP MÙA HỢP LỆ'),('Improved Pairs','CẶP CẢI THIỆN PPG'),('Declined Pairs','CẶP GIẢM PPG'),('Mean PPG Change','Δ PPG TRUNG BÌNH')])
chart(p,'barChart','10 lần cải thiện PPG lớn nhất',projection(C,'PairLabel','Đội · mùa sau'),[('Top Improvements','Δ PPG')],32,350,676,290,'Top Improvements',fg=TEAL)
chart(p,'barChart','10 lần suy giảm PPG lớn nhất',projection(C,'PairLabel','Đội · mùa sau'),[('Top Declines','Δ PPG')],732,350,676,290,'Top Declines',True,RED)
ccols=[('league','Giải'),('team_label','Đội'),('previous_season','Mùa trước'),('season','Mùa sau'),('previous_played','Trận trước'),('played','Trận sau'),('previous_points','Điểm trước'),('points','Điểm sau'),('points_change','Δ Điểm'),('previous_ppg','PPG trước'),('ppg','PPG sau'),('ppg_change','Δ PPG')]
table(p,'Chi tiết các cặp mùa liên tiếp',[projection(C,c,l) for c,l in ccols],32,662,1376,250)

p=page('05_Quality','05 · Dữ liệu và kiểm tra','Trang này luôn trình bày toàn bộ phạm vi nguồn. Mở Table view để xem đầy đủ 38 bảng SQL_; không dùng bộ lọc của các trang phân tích.')
textbox(p,'Nguồn: European Soccer Database (Kaggle)  |  Bản chụp kết quả SQL đã đối chiếu  |  Refresh nạp dữ liệu nhúng, không chạy lại SQLite.',32,140,1376,56,12,DARK,bg='#E4EFEB')
cards(p,[('Source Result Tables','BẢNG KẾT QUẢ SQL'),('SQL Statements','CÂU LỆNH ĐÃ CHẠY'),('Checks Passed','KIỂM TRA ĐẠT'),('Checks Failed','KIỂM TRA KHÔNG ĐẠT'),('Notable Warnings','LƯU Ý PHẠM VI')])
table(p,'4 trường hợp cần lưu ý khi diễn giải',[projection('CoverageWarnings',c,l) for c,l in [('league','Giải'),('season','Mùa'),('matches','Trận'),('note','Lưu ý')]],32,350,1376,165)
table(p,'22 phép kiểm tra SQL',[projection('DataChecks',c,l) for c,l in [('group','Nhóm'),('check_name','Phép kiểm tra'),('actual','Thực tế'),('expected','Kỳ vọng'),('status','Kết quả')]],32,538,824,374)
table(p,'38 bảng nguồn • xem chi tiết trong Table view',[projection('ResultCatalog',c,l) for c,l in [('model_table','Tên bảng trong mô hình'),('row_count','Dòng'),('column_count','Cột')]],880,538,528,374)

for p in PAGES:dump(REPORT/'definition/pages'/p['name']/'page.json',p)
for p,v in VISUALS:dump(REPORT/'definition/pages'/p['name']/'visuals'/v['name']/'visual.json',v)
dump(REPORT/'definition/pages/pages.json',{'$schema':DEF+'pagesMetadata/1.0.0/schema.json','pageOrder':[p['name'] for p in PAGES],'activePageName':PAGES[0]['name']})
(OUT/'.gitignore').write_text('**/.pbi/localSettings.json\n**/.pbi/cache.abf\n**/.pbi/unappliedChanges.json\n',encoding='utf-8')
dump(OUT/'docs/build_inventory.json',{'pages':len(PAGES),'visuals':len(VISUALS),'tables':len(tables),'raw_result_tables':len(R),'measures':len(measures),'relationships':len(relationships),'portable_embedded_data':True,'native_power_bi_desktop_tested':False})
dump(OUT/'docs/measures.json',measures)
if Path(__file__).resolve() != (OUT/'docs/build_powerbi.py').resolve():
    shutil.copy2(__file__,OUT/'docs/build_powerbi.py')
print(json.dumps({'output':str(OUT),'pages':len(PAGES),'visuals':len(VISUALS),'tables':len(tables),'measures':len(measures)},ensure_ascii=False))
