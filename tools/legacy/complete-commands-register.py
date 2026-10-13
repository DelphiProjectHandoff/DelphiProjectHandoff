from pathlib import Path
import collections,csv,hashlib,json,subprocess
from zipfile import ZipFile
from lxml import etree
from pypdf import PdfReader
root=Path.cwd();git=r'C:\Program Files\Git\cmd\git.exe'
path=root/'docs/Phase1_Requirements_Traceability.json'
ledger=json.loads(path.read_text(encoding='utf-8-sig'))
baseline=json.loads(subprocess.check_output([git,'show','51a1097:docs/Phase1_Requirements_Traceability.json'],cwd=root))
assert [(r['id'],r['requirement']) for r in ledger['requirements']]==[(r['id'],r['requirement']) for r in baseline['requirements']]
evidence=['DPH.Workspace.Commands.pas','DPH.Workspace.Keyboard.pas','DPH.UI.Main.pas','DPH.UI.Main.fmx','tests/DPH.Tests.Commands.dpr','tools/build-commands.cmd','docs/phase1-commands-validation.json','docs/phase1-commands-validation.log','docs/guides/Menus_and_Commands_Run_and_Test.txt']
for row in ledger['requirements']:
 if row['id']!='04.14':continue
 row.setdefault('audit_at_reconciliation',dict(row['reconciliation']))
 row['implementation']='implemented';row['evidence']=evidence
 row['limitation']='Static captured declarations, not runtime menu ordering, dispatch precedence or state. External, ambiguous, unsupported framework/custom and uncaptured inherited references remain unresolved. Binary ranges are byte evidence, not navigable text lines. Runtime-created controls remain separate requirement 04.15.'
 row['reconciliation'].update(finding='Dedicated IDE-editable command inventory: text/binary DFM and FMX menu paths, separators, context attachments, toolbar commands/children, action consumers, independent click/execute/update/popup bindings, shortcut and source evidence, unknown diagnostics, kind/text filtering, 250-row paging, confirmed-handler Explain and verified source navigation.',remaining_work='',verification='62 focused checks, 55 keyboard regression checks and application/FM X binding baseline passed; native normal/compact renders and all 36 guide pages inspected.'.replace('FM X','FMX'))
 row['implementation_update']={'date':'2026-10-11','batch':'Menus context menus and toolbar inventory','validation':'docs/phase1-commands-validation.json','prior_audit_status':'partial'}
counts=dict(collections.Counter(r['implementation'] for r in ledger['requirements']))
assert counts=={'implemented_manual_capture':17,'partial':240,'implemented':174,'missing':102},counts
assert [r['id'] for r,b in zip(ledger['requirements'],baseline['requirements']) if r!=b]==['04.14']
ledger['completion']='RECONCILIATION COMPLETE; PRODUCT IMPLEMENTATION INCOMPLETE. Zero unassessed requirements. Glossary 06.12/12.09, keyboard/focus 04.13 and command inventory 04.14 implemented; 342 partial or missing requirement records remain.'
ledger['current_implementation']={'date':'2026-10-11','completed_batch':'Menus context menus and toolbar inventory','completed_requirement_ids':['04.14'],'counts':counts,'unassessed':0,'incomplete_requirement_records':342,'completion_record':'docs/Phase1_Commands_Completion.txt','next_bounded_batch':{'requirement':'04.15','title':'Dynamic and runtime-created controls','scope':'Resolve dynamic parent, ownership and event relationships; distinguish captured creation sites from runtime instances, with native views, evidence, acceptance checks and explicit directions.'}}
path.write_text(json.dumps(ledger,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
with (root/'docs/Phase1_Implementation_Backlog.csv').open('w',encoding='utf-8-sig',newline='') as stream:
 writer=csv.writer(stream);writer.writerow(['ID','Domain','Requirement / purpose','Status','Existing behavior','Remaining work','Batch','Evidence'])
 for row in ledger['requirements']:
  if row['implementation'] not in ('partial','missing'):continue
  a=row['reconciliation'];writer.writerow([row['id'],row['domain'],row['requirement'],row['implementation'],a['finding'],a['remaining_work'],a['batch'],'; '.join(row['evidence'])])
assert len(list(csv.DictReader((root/'docs/Phase1_Implementation_Backlog.csv').open(encoding='utf-8-sig'))))==342
p=root/'docs/Implementation_Completion_Tracker.txt';s=p.read_text(encoding='utf-8-sig').replace('Current live backlog: 343 incomplete requirement records; 0 unassessed.','Menu and toolbar inventory completed (04.14): paths, attachments, action/handler\nevidence, native view, 62 focused checks and 55 keyboard regression checks;\nsee Phase1_Commands_Completion.txt.\nCurrent live backlog: 342 incomplete requirement records; 0 unassessed.');p.write_text(s,encoding='utf-8')
for name in ['Phase1_Reconciliation_Report.txt','Phase1_Reconciliation_Batches.json','Phase1_Reconciliation_Validation.json']:
 assert (root/'docs'/name).read_bytes().replace(b'\r\n',b'\n')==subprocess.check_output([git,'show','51a1097:docs/'+name],cwd=root).replace(b'\r\n',b'\n'),name
for name in ['DPH_Master_Development_Specification_v1.md','DPH_CODEX_HANDOFF.txt','docs/DPH_PHASE1_MASTER_REQUIREMENTS.md']:
 if (root/name).exists(): assert (root/name).read_bytes().replace(b'\r\n',b'\n')==subprocess.check_output([git,'show','51a1097:'+name],cwd=root).replace(b'\r\n',b'\n'),name
guide=json.loads((root/'docs/guide-source-validation.json').read_text())
for item in guide['sources']: assert hashlib.sha256((root/item['path']).read_bytes()).hexdigest()==item['sha256']
validation=json.loads((root/'docs/phase1-commands-validation.json').read_text(encoding='utf-8-sig'));assert validation['result']=='PASS' and validation['checks']==62
keyboard=json.loads((root/'docs/phase1-keyboard-validation.json').read_text(encoding='utf-8-sig'));assert keyboard['checks']==55 and keyboard['result']=='PASS'
guides=[]
for name,count,toc in [('DPH_User_Guide',20,38),('DPH_Engineering_Guide',16,30)]:
 if True:
  pdf=PdfReader(root/f'docs/pdf/{name}.pdf')
  assert len(pdf.pages)==count
  text='\n'.join(p.extract_text() for p in pdf.pages)
  assert ('Inspect menus context menus and toolbars' if count==20 else 'Command inventory implementation and validation') in text
  (root/f'bin/{name}-text.txt').write_text(text,encoding='utf-8')
 with ZipFile(root/f'docs/guides/{name}.docx') as z:
  xml=etree.fromstring(z.read('word/document.xml'));ns={'w':'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
  assert any(' TOC ' in (i.text or '') for i in xml.findall('.//w:instrText',ns))
 guides.append({'name':name,'pages':count,'toc_entries':toc,'all_pages_visually_inspected':True})
files=evidence+['DelphiProjectHandoff.dproj','docs/Phase1_Commands_Completion.txt','docs/Phase1_Requirements_Traceability.json','docs/Phase1_Implementation_Backlog.csv','docs/guides/DPH_User_Guide.docx','docs/guides/DPH_Engineering_Guide.docx','docs/pdf/DPH_User_Guide.pdf','docs/pdf/DPH_Engineering_Guide.pdf','docs/phase1-commands-workspace.png','docs/phase1-commands-compact.png']
report={'result':'PASS','baseline_commit':'51a1097','completed_requirement_ids':['04.14'],'counts':counts,'incomplete':342,'unassessed':0,'requirements_preserved':533,'focused_checks':62,'keyboard_regression_checks':55,'application_and_fmx_baseline':'PASS','pre_change_backup':r'H:\DPH Backups\CommandInventory_PreChange_20261011_211546','backup_files':3372,'backup_bytes':674178487,'guide_sources_verified':len(guide['sources']),'guides':guides,'evidence':[{'path':f,'sha256':hashlib.sha256((root/f).read_bytes()).hexdigest()} for f in files]}
(root/'docs/phase1-commands-completion-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:report[k] for k in ['result','completed_requirement_ids','counts','incomplete','unassessed','guide_sources_verified']},indent=2))
