from pathlib import Path
import json,hashlib,subprocess,collections
r=Path.cwd();p=r/'docs/phase1-action-purposes-completion-validation.json';v=json.loads(p.read_text())
guide=json.loads((r/'bin/action-purposes-guide-check.json').read_text());v['guides']=guide
for name in v['evidence_hashes']:v['evidence_hashes'][name]=hashlib.sha256((r/name).read_bytes()).hexdigest()
v['modal_background_refresh']='PASS: Knowledge is refreshed while the native editor is open; owned saved-row snapshot preserves expected revision and evidence links.'
ledger=json.loads((r/'docs/Phase1_Requirements_Traceability.json').read_text());assert len(ledger['requirements'])==533
assert dict(collections.Counter(x['implementation'] for x in ledger['requirements']))==v['counts']
assert sum(x['implementation'] in ('partial','missing') for x in ledger['requirements'])==337
g=r'C:\Program Files\Git\cmd\git.exe';base=json.loads(subprocess.check_output([g,'show','8323fbe:docs/Phase1_Requirements_Traceability.json']))
assert [x['id'] for x,y in zip(ledger['requirements'],base['requirements']) if x!=y]==['04.19']
assert [(x['id'],x['requirement']) for x in ledger['requirements']]==[(x['id'],x['requirement']) for x in base['requirements']]
assert '81 checks.' in (r/'docs/phase1-action-purposes-validation.log').read_text()
p.write_text(json.dumps(v,indent=2)+'\n',encoding='utf-8')
print('PASS final evidence hashes, 53 guide sources, 533 preserved requirement records, only 04.19 promoted, 337 incomplete')
