from pathlib import Path
import subprocess
root=Path(__file__).resolve().parents[2]
git=r'C:\Program Files\Git\cmd\git.exe'
for name in ['wp6-canonical-fixture.json','wp6-validation.json']:
    path=root/'docs'/name
    (root/'docs'/('learning-refocus-'+name)).write_bytes(path.read_bytes())
    path.write_bytes(subprocess.check_output([git,'show','HEAD:docs/'+name],cwd=root))
p=root/'docs/STOPPING_POINT.txt'
p.write_text(p.read_text(encoding='utf-8-sig').rstrip()+'\n',encoding='utf-8-sig')
print('Kept refocus regression evidence; restored the two historical WP6 artifacts overwritten by its test')
