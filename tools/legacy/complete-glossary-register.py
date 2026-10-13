from pathlib import Path
import collections,csv,hashlib,json,subprocess
root=Path(__file__).resolve().parent.parent.parent
git=r'C:\Program Files\Git\cmd\git.exe'
path=root/'docs/Phase1_Requirements_Traceability.json'
ledger=json.loads(path.read_text(encoding='utf-8-sig'))
baseline=json.loads(subprocess.check_output([git,'show','5ec1d6e:docs/Phase1_Requirements_Traceability.json'],cwd=root))
assert [(r['id'],r['requirement']) for r in ledger['requirements']]==[(r['id'],r['requirement']) for r in baseline['requirements']]
completed=['06.12','12.09']
evidence=['DPH.Knowledge.Glossary.pas','DPH.UI.Glossary.pas','DPH.UI.Glossary.fmx','DPH.UI.Main.pas','DPH.UI.Main.fmx','DPH.Storage.Database.pas','DPH.Publish.Model.pas','DPH.Publish.Export.pas','tests/DPH.Tests.Glossary.dpr','docs/phase1-glossary-validation.json','docs/phase1-glossary-validation.log']
finding='Dedicated project-scoped business glossary with typed term/aliases/definition/examples/context, contributor attribution, immutable save/review history, rename with stable identity, normalized duplicate prevention, source links, stale-source review, native list/filter/editor, project search and shared canonical HTML/DOCX/JSONL publication.'
for row in ledger['requirements']:
    if row['id'] not in completed: continue
    if 'audit_at_reconciliation' not in row: row['audit_at_reconciliation']=dict(row['reconciliation'])
    row['implementation']='implemented'
    row['evidence']=evidence
    row['limitation']='Business definitions are contributor-supplied and require named review. Current names of retired terms remain reserved. Source-linked terms are invalidated by affected evidence; unlinked terms have only their contributor context. Native validation uses actual FMX form instances and PaintTo renders, not target-runtime screenshots.'
    row['reconciliation'].update(finding=finding,remaining_work='',verification='Final glossary suite: 57 checks passed, including native modal editing, persistence, review, source changes, search and publication. Compatibility: knowledge 59, publishing 114, profile 19, quality 15, comparison 17, catalog 14; application baseline passed.')
    row['implementation_update']={'date':'2026-10-11','batch':'Business glossary','validation':'docs/phase1-glossary-validation.json','prior_audit_status':'missing'}
counts=dict(collections.Counter(r['implementation'] for r in ledger['requirements']))
assert counts=={'implemented_manual_capture':17,'partial':242,'implemented':172,'missing':102},counts
assert len(ledger['requirements'])==533 and 'unassessed' not in counts
ledger['completion']='RECONCILIATION COMPLETE; PRODUCT IMPLEMENTATION INCOMPLETE. Zero unassessed requirements. Business glossary requirements 06.12 and 12.09 implemented; 344 partial or missing requirement records remain.'
ledger['audit']['counts_describe']='Historical counts at the completed reconciliation baseline. Current implementation counts are recorded in current_implementation; the audit report and batch register remain historical evidence.'
ledger['audit']['recommended_next_step']['status']='completed'
ledger['audit']['recommended_next_step']['completion_evidence']='docs/Phase1_Glossary_Completion.txt'
ledger['current_implementation']={'date':'2026-10-11','completed_batch':'Business glossary','completed_requirement_ids':completed,'counts':counts,'unassessed':0,'incomplete_requirement_records':344,'completion_record':'docs/Phase1_Glossary_Completion.txt','next_bounded_batch':{'requirement':'04.13','title':'Keyboard shortcuts and focus-order inspector','scope':'Inspect captured shortcuts, action references and TabOrder in an IDE-designed view with duplicate/unknown diagnostics, source navigation, tests and directions. Preserve explicit inherited/runtime unknowns rather than claiming runtime focus order.'}}
path.write_text(json.dumps(ledger,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
with (root/'docs/Phase1_Implementation_Backlog.csv').open('w',encoding='utf-8-sig',newline='') as stream:
    writer=csv.writer(stream);writer.writerow(['ID','Domain','Requirement / purpose','Status','Existing behavior','Remaining work','Batch','Evidence'])
    for row in ledger['requirements']:
        if row['implementation'] not in ('partial','missing'):continue
        a=row['reconciliation'];writer.writerow([row['id'],row['domain'],row['requirement'],row['implementation'],a['finding'],a['remaining_work'],a['batch'],'; '.join(row['evidence'])])
with (root/'docs/Phase1_Implementation_Backlog.csv').open(encoding='utf-8-sig',newline='') as stream:
    rows=list(csv.DictReader(stream))
assert len(rows)==344 and not set(completed)&{r['ID'] for r in rows}
assert sum(r['implementation']!=b['implementation'] for r,b in zip(ledger['requirements'],baseline['requirements']))==2
print(json.dumps({'counts':counts,'backlog':len(rows),'unassessed':0,'completed':completed},indent=2))
