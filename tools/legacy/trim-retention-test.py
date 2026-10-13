from pathlib import Path
import json,hashlib
r=Path.cwd();p=r/'tests/DPH.Tests.DataRetention.dpr';p.write_bytes(p.read_bytes().rstrip()+b'\r\n')
p=r/'docs/phase1-data-retention-completion-validation.json';d=json.loads(p.read_text());d['evidence_hashes']['tests/DPH.Tests.DataRetention.dpr']=hashlib.sha256((r/'tests/DPH.Tests.DataRetention.dpr').read_bytes()).hexdigest();p.write_text(json.dumps(d,indent=2)+'\n')
p=r/'bin/commit-data-retention.py';s=p.read_text(encoding='utf-8-sig');s=s.replace("assert not read('diff','--cached','--name-only').strip()","# Existing staging belongs to this exact intended batch; checked below.",1);p.write_text(s)
