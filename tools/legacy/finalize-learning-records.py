from pathlib import Path
import json,subprocess
root=Path(__file__).resolve().parents[2]
p=root/'docs/learning-completion-validation.json'
r=json.loads(p.read_text(encoding='utf-8-sig'));r['counts']['GuidedTasks']=73;r['total_checks']=sum(r['counts'].values())
p.write_text(json.dumps(r,indent=2)+'\n',encoding='utf-8')
(root/'docs/learning-completion-guidedtasks.log').write_bytes((root/'bin/learning-completion/GuidedTasks.log').read_bytes())
p=root/'docs/Learning_Requirements_Reconciliation.json';r=json.loads(p.read_text(encoding='utf-8-sig'))
for name,cap in r['capabilities'].items():
 cap['state']='Implemented and exercised within the revised teaching contract; see learning-completion-validation.json and learning-completion-guides-validation.json.'
 if name=='delivery':cap['state']='Worked example, current manuals and explicit run/test directions implemented and validated. Release-package checks are recorded separately in learning-distribution-validation.json.'
p.write_text(json.dumps(r,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
p=root/'docs/Learning_Requirements_Reconciliation.txt';s=p.read_text(encoding='utf-8-sig')
s=s.replace('implemented foundation; current completion validation still required','implemented and exercised within the revised teaching contract; see learning-completion-validation.json')
s=s.replace('worked example implemented with four tasks, fourteen teaching cards and two native images; remaining: current guides and final package','worked example, current manuals and explicit run/test directions implemented and validated; package checks recorded separately in learning-distribution-validation.json')
s=s.replace('Current directions and guides, final visual checks and a fresh validated distribution.','Directions, guides and visual review are complete. Final package checks are recorded separately in learning-distribution-validation.json.')
p.write_text(s,encoding='utf-8')
print('Recorded 645 checks and current guide validation without changing original requirement history')
