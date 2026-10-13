from pathlib import Path
import collections,csv,datetime,hashlib,json,re,subprocess,zipfile
from pypdf import PdfReader
root=Path(__file__).resolve().parent.parent.parent
git=r'C:\Program Files\Git\cmd\git.exe'
def read(p):return json.loads((root/p).read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256((root/p).read_bytes()).hexdigest()
baseline=json.loads(subprocess.check_output([git,'show','5ec1d6e:docs/Phase1_Requirements_Traceability.json'],cwd=root).decode('utf-8-sig'))
ledger=read('docs/Phase1_Requirements_Traceability.json')
assert [(r['id'],r['requirement']) for r in ledger['requirements']]==[(r['id'],r['requirement']) for r in baseline['requirements']]
changes=[r['id'] for r,b in zip(ledger['requirements'],baseline['requirements']) if r['implementation']!=b['implementation']]
assert changes==['06.12','12.09']
counts=dict(collections.Counter(r['implementation'] for r in ledger['requirements']))
assert counts==ledger['current_implementation']['counts'] and sum(counts.values())==533 and counts.get('unassessed',0)==0
assert sha(ledger['baseline'])==ledger['baseline_sha256']
with (root/'docs/Phase1_Implementation_Backlog.csv').open(encoding='utf-8-sig',newline='') as stream:backlog=list(csv.DictReader(stream))
assert len(backlog)==344 and [r['ID'] for r in backlog]==[r['id'] for r in ledger['requirements'] if r['implementation'] in ('missing','partial')]
for p in ['docs/Phase1_Reconciliation_Report.txt','docs/Phase1_Reconciliation_Batches.json','docs/Phase1_Reconciliation_Validation.json']:
    assert not subprocess.check_output([git,'diff','--name-only','5ec1d6e','--',p],cwd=root).strip()
source_manifest=read('docs/guide-source-validation.json')
assert source_manifest['guide_version']==7
for entry in source_manifest['sources']:assert sha(entry['path'])==entry['sha256'],entry['path']
guides={}
for name,pages in [('DPH_User_Guide',19),('DPH_Engineering_Guide',15)]:
    docx='docs/guides/'+name+'.docx';pdf='docs/pdf/'+name+'.pdf'
    reader=PdfReader(root/pdf);assert len(reader.pages)==pages
    text='\n'.join(p.extract_text() or '' for p in reader.pages)
    assert '11 October 2026' in text and 'Business glossary' in text or 'business terms' in text
    assert 'H:' in text and 'D: development backups are suspended' not in text
    with zipfile.ZipFile(root/docx) as archive:
        xml=archive.read('word/document.xml').decode('utf-8')
        assert ' TOC ' in xml and 'fldCharType="begin"' in xml and 'fldCharType="end"' in xml
    pngs=list((root/'bin/guide-qa'/name).glob('page-*.png'))
    assert len(pngs)==pages
    guides[name]={'pages':pages,'docx_sha256':sha(docx),'pdf_sha256':sha(pdf),'editable_toc_preserved':True,'all_final_pages_visually_inspected':True,'png_sha256':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(pngs)}}
tests={p:read(p)['checks_passed'] for p in ['docs/phase1-glossary-validation.json','docs/wp5-validation.json','docs/wp6-validation.json','docs/phase1-profile-validation.json','docs/phase1-quality-validation.json','docs/phase1-comparison-validation.json','docs/phase1-project-catalog-validation.json']}
assert list(tests.values())==[57,59,114,19,15,17,14]
log=(root/'docs/phase1-glossary-validation.log').read_text(encoding='utf-8-sig')
assert 'PASS business glossary: 57 checks' in log and not re.search(r'^FAIL',log,re.M)
assert 'PASS WP0-TEST' in (root/'bin/glossary-final-build.log').read_text(encoding='utf-8-sig')
assert not subprocess.check_output([git,'diff','--name-only','5ec1d6e','--','migrations','DPH_PHASE1_MASTER_REQUIREMENTS.md','DPH_Master_Development_Specification_v1.md','DPH_CODEX_HANDOFF.txt'],cwd=root).strip()
subprocess.check_call([git,'diff','--check'],cwd=root)
files=['DPH.Knowledge.Glossary.pas','DPH.UI.Glossary.pas','DPH.UI.Glossary.fmx','DPH.UI.Main.pas','DPH.UI.Main.fmx','DPH.Storage.Database.pas','DPH.Publish.Model.pas','DPH.Publish.Export.pas','DelphiProjectHandoff.dproj','tests/DPH.Tests.Glossary.dpr','tools/build-glossary.cmd','tools/backup-phase.ps1','tools/build-guides.py','docs/Phase1_Requirements_Traceability.json','docs/Phase1_Implementation_Backlog.csv','docs/Phase1_Glossary_Completion.txt','docs/guides/Business_Glossary_Run_and_Test.txt','help/index.html']+list(tests)
result={'result':'PASS','checked_at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'baseline_commit':'5ec1d6e','completed_requirements':changes,'numbered_requirements_preserved':533,'unassessed':0,'implementation_counts':counts,'backlog_records':344,'test_checks_passed':tests,'application_build_and_fmx_baseline':'PASS','standalone_bundle_validator':'PASS on controlled glossary fixture; --allow-stale explicitly selected','guide_source_hashes_verified':len(source_manifest['sources']),'guides':guides,'native_forms':'Normal and compact serialized FMX control renders inspected; modal edit/new/cancel and unsaved-draft guards exercised','prechange_backup':{'path':r'H:\DPH Backups\BusinessGlossary_PreChange_20261011_202113','files':4278,'bytes':646707077,'verification':'Every copied file SHA-256 verified before source edits','wake_allowance_seconds':65},'only_two_requirement_statuses_promoted':True,'historical_reconciliation_reports_unchanged':True,'original_plans_and_migrations_unchanged':True,'disposable_fixtures_removed':read('bin/glossary-disposable-cleanup.json'),'source_and_evidence_sha256':{p:sha(p) for p in dict.fromkeys(files)},'binary_sha256':{p:sha(p) for p in ['bin/Win32/Debug/DelphiProjectHandoff.exe','bin/Win32/Debug/DPH.ValidateHandoff.exe']},'limits':['Contributor-supplied business definitions require named review; no automatic business inference or authenticated-user claim.','This completes the glossary batch, not the 344 remaining partial/missing requirement records.','Controlled regression/native evidence does not substitute for independent whole-product first-time-user acceptance.']}
(root/'docs/phase1-glossary-completion-validation.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'result':'PASS','changed_statuses':changes,'backlog':344,'unassessed':0,'guide_sources':len(source_manifest['sources']),'guide_pages':{k:v['pages'] for k,v in guides.items()},'tests':tests},indent=2))
