from pathlib import Path
from PIL import Image
import hashlib,json
r=Path.cwd();b=Path(r'H:\DPH Backups\Calculations_PreChange_20261012_205718\bin\guide-qa');report=[]
for name in ['DPH_Engineering_Guide','DPH_User_Guide']:
 def digest(path):
  with Image.open(path) as im:return hashlib.sha256(im.convert('RGB').tobytes()).hexdigest()
 prior={digest(p):p.name for p in (b/name).glob('page-*.png')}
 now=r/'bin/guide-qa'/name
 for p in sorted(now.glob('page-*.png'),key=lambda x:int(x.stem.split('-')[-1])):
  h=digest(p);report.append({'guide':name,'page':int(p.stem.split('-')[-1]),'previous_reviewed_identical_page':prior.get(h),'sha256_pixels':h})
(r/'bin/calculation-guide-page-comparison.json').write_text(json.dumps(report,indent=2));print(json.dumps({'unchanged_reviewed_pages':sum(bool(x['previous_reviewed_identical_page']) for x in report),'changed_pages':[(x['guide'],x['page']) for x in report if not x['previous_reviewed_identical_page']]},indent=2))
