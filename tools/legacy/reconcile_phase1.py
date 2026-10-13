import csv, hashlib, json, pathlib, subprocess, collections

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
LEDGER = ROOT / 'docs/Phase1_Requirements_Traceability.json'
ledger = json.loads(LEDGER.read_text(encoding='utf-8-sig'))
initial = json.loads(subprocess.check_output([r'C:\Program Files\Git\cmd\git.exe','show','6736d00:docs/Phase1_Requirements_Traceability.json'],cwd=ROOT))
initial_by_id = {r['id']:r for r in initial['requirements']}
groups = {
 'inventory': [('DPH.Project.Inventory.pas','constructor TDPHInventory.Create'),('DPH.Project.Analysis.pas','function TDPHScan.AsJSON'),('tests/DPH.Tests.Discovery.dpr','INV01')],
 'syntax': [('DPH.Parse.Pascal.pas','implementation'),('DPH.Analysis.Symbols.pas','procedure TDPHSemanticAnalyzer.Collect'),('tests/DPH.Tests.Discovery.dpr','PAS02')],
 'semantics': [('DPH.Analysis.Symbols.pas','procedure TDPHSemanticAnalyzer.RoutineFacts'),('DPH.Analysis.Model.pas','function TDPHSemanticGraph.AsJSON'),('tests/DPH.Tests.Semantics.dpr','RESOLVE01')],
 'flow': [('DPH.Analysis.Flow.pas','procedure TDPHFlowBuilder.Build'),('DPH.Workspace.Model.pas','function TDPHWorkspaceView.Graph'),('DPH.Analysis.Explanations.pas','function TDPHExplanationModel.RoutineLesson'),('tests/DPH.Tests.Semantics.dpr','FLOW01')],
 'startup': [('DPH.Analysis.Symbols.pas','procedure TDPHSemanticAnalyzer.ModulePhases'),('tests/DPH.Tests.Semantics.dpr','START01')],
 'async': [('DPH.Analysis.Async.pas','class procedure TDPHAsyncAnalysis.Enrich'),('tests/DPH.Tests.Semantics.dpr','ASYNC04')],
 'forms': [('DPH.Parse.Forms.pas','implementation'),('DPH.Analysis.Symbols.pas','procedure TDPHSemanticAnalyzer.BindForms'),('DPH.Workspace.Screen.pas','class function TDPHScreenLayout.Reconstruct'),('DPH.UI.Main.fmx','object ScreenTab:'),('tests/DPH.Tests.Semantics.dpr','NAV01')],
 'sql': [('DPH.Analysis.SQL.pas','class procedure TDPHSQLAnalysis.Enrich'),('tests/DPH.Tests.Semantics.dpr','SQL01')],
 'resources': [('DPH.Parse.Resources.pas','implementation'),('DPH.Project.Inventory.pas','procedure DefinitionFiles'),('tests/DPH.Tests.Semantics.dpr','DEF01')],
 'knowledge': [('DPH.Storage.Database.pas','function TDPHKnowledgeStore.SaveKnowledge'),('DPH.Storage.Database.pas','procedure TDPHKnowledgeStore.ReviewKnowledge'),('DPH.UI.Main.fmx','object KnowledgeKindCombo:'),('tests/DPH.Tests.Knowledge.dpr','Explicit named review verifies human content')],
 'links': [('DPH.Storage.Database.pas','function TDPHKnowledgeStore.LinkCandidates'),('DPH.Storage.Database.pas','function TDPHKnowledgeStore.ReviewTasks'),('DPH.UI.Main.fmx','object KnowledgeLinksTab:'),('tests/DPH.Tests.Knowledge.dpr','Named review preserves immutable rich links')],
 'onboarding': [('DPH.Analysis.Explanations.pas','function TDPHExplanationModel.TopicText'),('DPH.Workspace.Model.pas','function TDPHWorkspaceView.Questions'),('help/index.html','<!doctype'),('tests/DPH.Tests.Learning.dpr','program ')],
 'ui': [('DPH.UI.Main.pas','procedure TDPHMainForm.LoadView'),('DPH.UI.Main.fmx','object WorkspaceTabs:'),('DPH.Workspace.Model.pas','function TDPHWorkspaceView.Hierarchy'),('tests/DPH.Tests.Workspace.dpr','program ')],
 'search': [('DPH.Storage.Database.pas','function TDPHKnowledgeStore.SearchProject'),('DPH.Storage.Database.pas','procedure TDPHKnowledgeStore.BuildSearchIndex'),('DPH.UI.Main.fmx','object ProjectSearchTab:'),('tests/DPH.Tests.Lifecycle.dpr','program ')],
 'publish': [('DPH.Publish.Model.pas','constructor TDPHDocumentModel.Create('),('DPH.Publish.Export.pas','class procedure TDPHPublisher.Export'),('DPH.Publish.Export.pas','class procedure TDPHPublisher.Validate'),('tests/DPH.Tests.Publishing.dpr','Canonical output is deterministic')],
 'translation': [('DPH.Publish.Translation.pas','constructor TDPHAtlasAdapter.Create'),('DPH.Publish.Translation.pas','function TDPHTranslationCache.Translate'),('DPH.Storage.Database.pas','procedure TDPHKnowledgeStore.ReviewTranslation'),('tests/DPH.Tests.Publishing.dpr','Selected Atlas DAT pack translates offline')],
 'storage': [('DPH.Storage.Database.pas','constructor TDPHKnowledgeStore.Create'),('DPH.Storage.Database.pas','function TDPHKnowledgeStore.PublishGeneration'),('migrations/001_foundation.sql','CREATE TABLE projects'),('tests/DPH.Tests.Storage.dpr','program ')],
 'revision': [('DPH.Storage.Database.pas','procedure TDPHKnowledgeStore.ObserveManifest'),('DPH.Storage.Database.pas','function TDPHKnowledgeStore.LoadWorkspaceView'),('DPH.Workspace.Worker.pas','procedure TDPHWorkspaceWorker.Execute'),('tests/DPH.Tests.Workspace.dpr','Unchanged connected check skips analysis')],
 'snapshot': [('migrations/001_foundation.sql','snapshot_blob_id'),('DPH.Storage.Database.pas','procedure TDPHKnowledgeStore.SaveWorkspaceView'),('DPH.Storage.Database.pas','procedure TDPHKnowledgeStore.ApplyRetention'),('DPH.Publish.Export.pas','raw_source_snapshots')],
 'backup': [('DPH.Storage.Backup.pas','class procedure TDPHProjectBackup.Save'),('DPH.Storage.Backup.pas','class procedure TDPHProjectBackup.Restore'),('DPH.UI.Main.fmx','object LifecycleTab:'),('tests/DPH.Tests.Lifecycle.dpr','program ')],
 'scope': [('DPH.Project.Inventory.pas','function TDPHInventory.Allowed'),('DPH.Storage.Database.pas','procedure TDPHKnowledgeStore.CheckOutsideSource'),('DPH.Publish.Model.pas','AllowedFiles:='),('tests/DPH.Tests.Selection.dpr','program ')],
 'output': [('DPH.Analysis.Symbols.pas','procedure TDPHSemanticAnalyzer.OutputSites'),('tests/DPH.Tests.Semantics.dpr','OUT01')],
 'tests': [('DPH.Analysis.Symbols.pas','procedure TDPHSemanticAnalyzer.TestCoverage'),('tests/DPH.Tests.Semantics.dpr','REL05')],
 'profile': [('DPH.Knowledge.ProjectProfile.pas','implementation'),('DPH.UI.ProjectProfile.fmx','object '),('tests/DPH.Tests.Phase1.dpr','program ')],
 'catalog': [('DPH.Workspace.Model.pas','function TDPHWorkspaceView.ProjectMembers'),('DPH.UI.Main.fmx','object ProjectMembersTab:'),('tests/DPH.Tests.ProjectCatalog.dpr','Missing group member remains visible')],
 'comparison': [('DPH.Workspace.Comparison.pas','class function TDPHRevisionComparison.Compare'),('tests/DPH.Tests.Comparison.dpr','Control-flow edge changes are detected')],
 'quality': [('DPH.Analysis.Quality.pas','implementation'),('tests/DPH.Tests.SourceQuality.dpr','program ')],
 'observations': [('DPH.Storage.Database.pas','procedure TDPHKnowledgeStore.ImportObservation'),('DPH.UI.Main.fmx','object ObservationsTab:'),('tests/DPH.Tests.Knowledge.dpr','program ')],
}

evidence_groups = {}
for group, locations in groups.items():
 refs=[]
 for path, marker in locations:
  text=(ROOT/path).read_text(encoding='utf-8-sig'); lines=text.splitlines()
  hits=[i+1 for i,line in enumerate(lines) if marker.lower() in line.lower()]
  if not hits: raise ValueError(f'Missing evidence anchor {path}: {marker}')
  refs.append({'path':path,'line':hits[0],'anchor':marker,'sha256':hashlib.sha256((ROOT/path).read_bytes()).hexdigest(),'role':'existing test definition; not rerun in this audit' if path.startswith('tests/') else 'reviewed implementation or nearest existing foundation; see individual finding'})
 evidence_groups[group]=refs

decisions={}
for number,line in enumerate((ROOT/'bin/phase1_audit_decisions.tsv').read_text(encoding='utf-8').splitlines(),1):
 if not line or line.startswith('#'): continue
 fields=line.split('|')
 if len(fields)!=5: raise ValueError(f'Decision line {number} has {len(fields)} fields')
 key,status,group,finding,gap=fields
 if key in decisions or key not in initial_by_id: raise ValueError('Duplicate/unknown decision '+key)
 if status not in ['implemented','partial','missing','implemented_manual_capture']: raise ValueError(status)
 if group not in groups: raise ValueError(group)
 if status in ['partial','missing'] and gap=='-': raise ValueError('Missing concrete backlog '+key)
 decisions[key]=(status,group,finding,gap)

unassessed_ids=[r['id'] for r in initial['requirements'] if r['implementation']=='unassessed']
assert len(unassessed_ids)==510
assert set(decisions)==set(unassessed_ids),f'Unreconciled: {sorted(set(unassessed_ids)-set(decisions))}; extra: {sorted(set(decisions)-set(unassessed_ids))}'
batch_for={key:position//25+1 for position,key in enumerate(unassessed_ids)}
prior_gaps={
 '01.02':'Add curated profiles for each selected project-group member and complete supported MSBuild evaluation with explicit unresolved imports/conditions.',
 '01.03':'Represent multiple applications only inside an explicitly selected group, with per-member curated profiles and member-specific configuration; preserve the one-selected-project/group boundary.',
 '01.04':'Complete referenced/imported MSBuild property and condition evaluation, including member-specific configuration and visible unresolved discovery.',
 '01.05':'Add evidence-backed service/output-kind identification and verified artifact references without automatically executing or installing the target.',
 '02.16':'Extend bounded reachability/reference analysis to indirect/event entry points and present unreferenced candidates with limitations; do not claim proof of dead code.',
 '02.17':'Add configurable near-duplicate/structural similarity detection beyond exact significant-token equality and reviewed redundancy findings.',
 '02.18':'Define and implement documented complexity/maintainability measures with reproducible tests and explicit supported-syntax limits.',
 '02.20':'Add retained historical source-byte comparison and reviewed rename/move continuity with explicit unsupported semantic equivalence.',
 '03.13':'Extend static call-cycle findings with qualified indirect/virtual callback cycles and source-linked cycle explanations.',
 '22.08':'Add revision-associated pre/post source-text and affected-document comparisons, preserving historical bytes and reviewed continuity.',
 'EX-028':'Add reentry candidates from events/callbacks/thread contexts and qualify indirect recursion beyond static strongly connected call components.',
 'EX-046':'Add important-procedure selection and historical source-body comparison with reviewed rename/move continuity.',
 'EX-090':'Complete moved/renamed symbol and event-binding continuity with before/after historical source evidence and explicit ambiguity.'
}
for r in ledger['requirements']:
 key=r['id']; assert r['requirement']==initial_by_id[key]['requirement']
 if key in decisions:
  status,group,finding,gap=decisions[key]
  r['implementation']=status; r['evidence']=[ref['path'] for ref in evidence_groups[group]]
  r['limitation']=gap if gap!='-' else finding
  r['reconciliation']={'state':'reconciled','batch':batch_for[key],'finding':finding,'remaining_work':'' if gap=='-' else gap,'purpose':r['requirement'],'evidence_group':group,'verification':'Source/form/schema and existing test-definition review; no application build, test execution or independent acceptance performed in this audit.'}
 else:
  r['reconciliation']={'state':'previously_assessed','batch':0,'finding':r['limitation'],'remaining_work':prior_gaps[key] if r['implementation']=='partial' else '', 'purpose':r['requirement'],'verification':'Existing source and limitations retained; no new acceptance claim.'}

counts=dict(collections.Counter(r['implementation'] for r in ledger['requirements']))
ledger['schema_version']=2
ledger['completion']='RECONCILIATION COMPLETE; PRODUCT IMPLEMENTATION INCOMPLETE. No unassessed numbered requirements remain. Implemented means the stated feature exists within recorded bounds, not independent acceptance of the complete product.'
ledger['audit']={'baseline_commit':'6736d00','date':'2026-10-11','newly_reconciled':510,'previously_assessed':23,'batches':21,'counts':counts,'method':'Manual requirement-by-requirement mapping to actual Pascal, FMX, schema, test definitions and existing evidence. Missing means no dedicated fulfillment found in the reviewed application; generic prose storage alone is not counted as a specialized feature. Partial states present behavior and explicit remaining work. Runtime execution and independent human acceptance remain separate.','evidence_groups':evidence_groups}
next_step={
 'title':'Implement the selected-project business glossary end to end',
 'requirement_ids':['06.12','12.09'],
 'scope':'One complete module: scoped terms, aliases, plain-language definitions, attribution, source links, immutable revisions, named review, project search and canonical HTML/DOCX/JSON publication. Use an IDE-editable form and the existing repository/review/publishing contracts.',
 'completion_criteria':[
  'A user can add, edit, find and review a term, close DPH, reopen the same project and retain the exact current record and history.',
  'Terms remain isolated to the selected project; duplicate names/aliases, empty definitions, stale edits and stale reviews are handled explicitly.',
  'The same reviewed term revision appears consistently in search, user/engineering documentation and machine-readable handoff exports.',
  'Source-linked terms retain evidence and become review-needed when affected source changes.',
  'Meaningful persistence, revision, review, scope, search and export regressions pass; the application builds and the native workflow is checked.',
  'Run/test directions and guides describe the actual shipped controls; update the two requirement records with evidence, commit and push both remotes.'
 ],
 'dependencies':'Uses existing knowledge versioning, source links, named review, search and publication foundations. No external AI service, production database connection or additional planning file is needed. Real business definitions are entered by contributors; regression fixtures verify the software without requiring those definitions.',
 'boundary':'Do not fold interviews, general business-process modeling, natural-language AI answering or report/schema analysis into this implementation batch.'
}
ledger['audit']['recommended_next_step']=next_step
LEDGER.write_text(json.dumps(ledger,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

batch_rows=[]
for batch in range(1,22):
 ids=[k for k in unassessed_ids if batch_for[k]==batch]
 batch_rows.append({'batch':batch,'count':len(ids),'first':ids[0],'last':ids[-1],'ids':ids,'reconciled':len(ids),'unassessed':0,'statuses':dict(collections.Counter(decisions[k][0] for k in ids))})
(ROOT/'docs/Phase1_Reconciliation_Batches.json').write_text(json.dumps({'baseline_commit':'6736d00','total':510,'batches':batch_rows},indent=2)+'\n',encoding='utf-8')
with (ROOT/'docs/Phase1_Implementation_Backlog.csv').open('w',encoding='utf-8-sig',newline='') as f:
 writer=csv.writer(f); writer.writerow(['ID','Domain','Requirement / purpose','Status','Existing behavior','Remaining work','Batch','Evidence'])
 for r in ledger['requirements']:
  if r['implementation'] not in ['partial','missing']: continue
  audit=r['reconciliation']; writer.writerow([r['id'],r['domain'],r['requirement'],r['implementation'],audit['finding'],audit['remaining_work'],audit['batch'],'; '.join(r['evidence'])])
report=['DPH complete Phase 1 reconciliation','Audit date: 11 October 2026','Implementation baseline: 6736d00','', 'All 510 formerly unassessed numbered requirements reconciled in 21 batches.', 'The first 20 batches contain 25 items; batch 21 contains 10.', 'The 23 previously assessed items retain their previous implementation status.', '', 'STATUS COUNTS']
report.extend(f'{status}: {count}' for status,count in sorted(counts.items()))
report.extend(['','Read implemented as feature existence within documented bounds, not complete product acceptance.', 'Partial and missing items require implementation. Authored content and independent human acceptance are separate.', 'No DPH or selected-project code, forms, migrations, databases or binaries changed in this audit.', 'Tests were inspected, not executed. Historical PASS counts are not new audit runs.','', 'BATCH COMPLETION'])
report[report.index('STATUS COUNTS'):report.index('STATUS COUNTS')]=[
 'ASSESSMENT',
 f"{counts.get('partial',0)+counts.get('missing',0)} numbered requirements remain incomplete: {counts.get('partial',0)} partial and {counts.get('missing',0)} missing.",
 'These are requirement records, not that many independent coding tasks: original and expansion requirements intentionally overlap.',
 'Most missing items require dedicated models, workflows or analyzers that do not exist. Partial items have a foundation but lack the behavior specified in Remaining below.',
 'Generic notes, source graphs, package integrity checks and DPH own test reports do not substitute for target business workflows, target database schemas, target tests or operational readiness.',
 'Approval and the formerly missing planning document are not the reason these implementation gaps remain.',
 'Manual-capture status means attributed author-supplied knowledge can be stored/reviewed/published; it does not claim automatic inference or that real project answers have been supplied.',
 'This is a source audit, not a fresh runtime acceptance test. The next implementation batch must build and validate its changed behavior.',
 '', 'NEXT COMPLETE IMPLEMENTATION BATCH', next_step['title'],
 'Requirements: '+', '.join(next_step['requirement_ids']), 'Scope: '+next_step['scope'],
 'Dependencies: '+next_step['dependencies'], 'Boundary: '+next_step['boundary'], 'Definition of done:',
 *['- '+criterion for criterion in next_step['completion_criteria']],
 '', 'STATUS LEGEND',
 'implemented: supported feature exists in the recorded bounded scope; not a claim of independent acceptance or compiler-grade inference.',
 'implemented_manual_capture: the stated knowledge can be captured with attribution; humans must supply and verify its actual content.',
 'partial: implemented behavior exists, but the specific Remaining work is necessary to fulfill the requirement.',
 'missing: no dedicated fulfillment was found; cited evidence identifies the reviewed nearest foundation, not proof that the missing behavior exists.',
 ''
]
report.extend(f"Batch {b['batch']:02}: {b['count']}/{b['count']} reconciled; {b['first']} through {b['last']}; zero unassessed" for b in batch_rows)
for r in ledger['requirements']:
 a=r['reconciliation']; report.extend(['',r['id']+' '+r['requirement'],'Status: '+r['implementation'],'Purpose: '+a['purpose'],'Existing: '+a['finding'],'Remaining: '+(a['remaining_work'] or 'No additional implementation identified for this requirement within the recorded scope.'),'Evidence: '+', '.join(r['evidence'])])
(ROOT/'docs/Phase1_Reconciliation_Report.txt').write_text('\n'.join(report)+'\n',encoding='utf-8')
print(json.dumps({'reconciled':len(decisions),'batches':len(batch_rows),'counts':counts},indent=2))
