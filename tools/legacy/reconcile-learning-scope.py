from pathlib import Path
import json,csv,hashlib,collections
root=Path(__file__).resolve().parents[2]
baseline=root/'docs/Phase1_Requirements_Traceability.json'
original=baseline.read_bytes();ledger=json.loads(original)
# Explicit dispositions for original feature IDs. Each omitted feature is kept
# in the historical ledger, but is outside the owner's revised learning contract.
kept={
1:{4,5,6,8,10,14},2:{1,2,3,4,5,6,7,8,9,10,11,12,14,15,19},
3:{1,2,3,4,5,6,7,8,9,10,11,14,15,17,18},
4:set(range(1,20)),5:{9,10,11,12,13,14,15,17,19},6:set(range(1,17)),
7:set(range(1,16)),8:{7,10,11,12,14,17},9:{1,2,3,4,5,6,8,9,10,12,14,18},
10:{1,2,3,4,8,9,13,15},11:{1,2,3,5,6,7,11,13,15,16},
12:set(range(1,16)),13:{1,2,4,6,7,8,9,11,12,14,16,17,18},
14:{1,2,3,4,5,6,7,8,9,14,15},15:set(range(1,21))-{10},
16:{1,2,3,4,5,6,7,8,9,10,11,14,15,17},17:{1,2,3,4,5,6,7,15,17,18},
18:set(),19:{1,2,3,4,5,10,11,13,14},20:{1,2,5,9,10,11,12,13,15,16,17,18},
21:{5,6,12},22:{5},23:set(range(1,13))}
source_domains={2,3,4,13,14}
foundation_domains={15,16,20}
cards_domains={5,6,7,8,9,10,11,21,23}
ex_retained={1,2,3,4,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,27,30,33,34,35,36,37,38,40,41,42,43,45,47,48,50,58,62,64,65,67,68,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,89,90,91,92,93}
db_superseded={28,29,33,38}
capabilities={
'orientation':{'purpose':'Explain the selected application, who uses it, a first-session route and plain Delphi terms.','evidence':['DPH.Analysis.Explanations.pas','DPH.Knowledge.ProjectProfile.pas','tests/DPH.Tests.LearningRefocus.dpr']},
'source_lessons':{'purpose':'Teach supported screen, action, decision, input/result and connection examples with source links; keep deep code optional and unknowns explicit.','evidence':['DPH.Analysis.Explanations.pas','DPH.Workspace.Screen.pas','tests/DPH.Tests.LearningRefocus.dpr']},
'teaching_cards':{'purpose':'Teach screen/field meanings, examples and units, limits, permissions, settings, related systems, rules, errors and output interpretation using attributed, editable cards. This is instruction, not a business or administration engine.','evidence':['DPH.Workspace.Model.pas','DPH.Storage.Database.pas','DPH.UI.Main.fmx','tests/DPH.Tests.GuidedTasks.dpr']},
'tasks_paths':{'purpose':'Provide ordered tasks, prerequisites, role filters, named learning paths, exercises, expected results and revision-specific personal progress.','evidence':['DPH.UI.Main.pas','DPH.Workspace.Catalog.pas','tests/DPH.Tests.GuidedTasks.dpr','tests/DPH.Tests.Catalog.dpr']},
'pictures':{'purpose':'Use real contributed pictures, linked explanations and anchored callouts; keep source reconstructions clearly labeled.','evidence':['DPH.Workspace.Screen.pas','DPH.Storage.Database.pas','DPH.UI.Main.fmx','tests/DPH.Tests.GuidedTasks.dpr','tests/DPH.Tests.Practice.dpr'],'state':'implemented and exercised in the native viewer and offline publication; original PNG bytes preserved'},
'knowledge':{'purpose':'Preserve named author explanations, glossary, questions, links, revisions and human review; never invent missing application knowledge.','evidence':['DPH.Storage.Database.pas','DPH.Knowledge.Glossary.pas','tests/DPH.Tests.Knowledge.dpr']},
'publishing':{'purpose':'Publish the same selected-application lessons, tasks, examples, terms and pictures in an offline searchable/printable edition and editable user guide.','evidence':['DPH.Publish.Model.pas','DPH.Publish.Export.pas','tests/DPH.Tests.Publishing.dpr']},
'foundation':{'purpose':'Keep selected sources read-only, results project-scoped, cached lessons durable, current-source checks honest and failed scans recoverable. These support teaching and stay out of the main lesson route.','evidence':['DPH.Project.Analysis.pas','DPH.Storage.Database.pas','DPH.Workspace.Worker.pas','tests/DPH.Tests.Storage.dpr']},
'delivery':{'purpose':'Deliver a native beginner-friendly application, a supplied worked learning example, current explicit instructions and validated packages.','evidence':['DPH.UI.Main.fmx','samples/OrderPractice/lessons.json','tests/DPH.Tests.Practice.dpr','tools/package-dph.ps1','docs/guides/Run_And_Test.txt'],'state':'worked example implemented with four tasks, fourteen teaching cards and two native images; remaining: current guides and final package'}
}
rows=[]
for item in ledger['requirements']:
 ident=item['id'];domain=item['domain'];number=None
 if ident.startswith('EX-'):
  number=int(ident[3:]);retained=number in ex_retained
  cap='source_lessons' if number<=30 or number>=61 else 'teaching_cards'
  if number in {10,20,30,40,50,58,70,81,82,89,90,91,92,93}:cap='foundation'
  if number in {41,42,43,45,47}:cap='knowledge'
  if number in {48,80}:cap='publishing'
 elif ident.startswith('SC-'):
  retained=True;cap='foundation'
 elif ident.startswith('DB-'):
  retained=int(ident[3:]) not in db_superseded;cap='foundation'
 else:
  d,n=map(int,ident.split('.'));retained=n in kept[d]
  cap='orientation'
  if d in source_domains:cap='source_lessons'
  if d in foundation_domains:cap='foundation'
  if d in cards_domains:cap='teaching_cards'
  if d in {12,19}:cap='tasks_paths'
  if d==17:cap='publishing'
  if d==22:cap='foundation'
  if ident in {'04.03','04.04','04.05','12.08','13.06','13.07','13.08','23.11'}:cap='pictures'
  if ident in {'12.02','12.03','12.06','12.10','12.12','12.14','23.01','23.02','23.03','23.04','23.05','23.06','23.07','23.08','23.09','23.10','23.12'}:cap='teaching_cards'
  if ident in {'01.08','06.12','06.16','11.16','19.02','19.03','19.04','19.05'}:cap='knowledge'
  if ident in {'12.13','12.15','19.13'}:cap='publishing'
  if ident in {'19.14','20.05','20.13','21.12'}:cap='delivery'
 disposition='superseded_by_learning_direction'
 if retained:
  if cap=='foundation':disposition='retain_supporting_safeguard_with_existing_limits'
  elif cap in {'teaching_cards','knowledge'}:disposition='adapt_to_attributed_application_instruction'
  else:disposition='retain_learning_capability_with_explicit_limits'
 reason=(capabilities[cap]['purpose'] if retained else
  'The original '+item['requirement'].lower()+' obligation is outside the revised beginner-learning product. Do not add its dedicated enterprise, engineering-administration, automation or specialist analysis system. Existing useful internal code may support lessons; this is a scope decision, not a claim the original feature was implemented.')
 rows.append({'id':ident,'original_requirement':item['requirement'],'original_status':item['implementation'],
  'original_remaining_work':item.get('reconciliation',{}).get('remaining_work',''),'disposition':disposition,
  'learning_capability':cap if retained else None,'revised_contract_and_reason':reason,
  'original_limitation_preserved':item.get('limitation',''),'evidence_to_validate':capabilities[cap]['evidence'] if retained else []})
assert len(rows)==533 and len({r['id'] for r in rows})==533
assert original==baseline.read_bytes()
summary=dict(collections.Counter(r['disposition'] for r in rows))
result={'schema_version':1,'controlling_direction':'Owner instruction: reconcile and finish DPH as a learning tool for a beginner studying one unfamiliar Delphi application.',
 'historical_ledger_sha256':hashlib.sha256(original).hexdigest(),'historical_ledger_unchanged':True,
 'not_a_claim_of_original_technical_completion':True,'records_reconciled':len(rows),'unreconciled':0,
 'original_incomplete_records_reviewed':sum(r['original_status'] in ['partial','missing'] for r in rows),
 'dispositions':summary,'capabilities':capabilities,'requirements':rows}
(root/'docs/Learning_Requirements_Reconciliation.json').write_text(json.dumps(result,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
with (root/'docs/Learning_Requirements_Reconciliation.csv').open('w',newline='',encoding='utf-8-sig') as f:
 writer=csv.DictWriter(f,fieldnames=['id','original_requirement','original_status','disposition','learning_capability','revised_contract_and_reason','original_remaining_work','original_limitation_preserved']);writer.writeheader()
 writer.writerows({k:v for k,v in r.items() if k!='evidence_to_validate'} for r in rows)
text=['DPH LEARNING REQUIREMENTS RECONCILIATION','13 October 2026','',
 'All 533 numbered records reviewed, including all 312 historically partial/missing records. Zero unreconciled.',
 'The historical ledger and its implementation counts are unchanged. Revised scope is not original technical completion.',
 'Each CSV/JSON row preserves the original requirement, status, limitation and remaining work alongside the revised teaching contract.',
 'Dedicated technical administration, enterprise workflow engines, specialist whole-program proof, AI agent infrastructure and translation expansion are not the revised product.',
 'Teaching cards explain application-specific rules, permissions, reports and problems; they do not implement those systems or claim to infer unwritten author knowledge.','',
 'REVISED CAPABILITIES']
for key,value in capabilities.items():text.extend([key+': '+value['purpose'],'Evidence: '+', '.join(value['evidence']),'State: '+value.get('state','implemented foundation; current completion validation still required'),''])
text.extend(['NEXT REMAINING WORK','Current directions and guides, final visual checks and a fresh validated distribution.','Independent human beginner acceptance is a separate reported observation, not a reason to stop implementation.'])
(root/'docs/Learning_Requirements_Reconciliation.txt').write_text('\n'.join(text)+'\n',encoding='utf-8')
print(json.dumps({'reconciled':len(rows),'old_incomplete_reviewed':result['original_incomplete_records_reviewed'],'dispositions':summary},indent=2))
