from pathlib import Path
import subprocess,json
r=Path.cwd();g=r'C:\Program Files\Git\cmd\git.exe'
def read(*a):return subprocess.check_output([g,*a]).decode()
def run(*a):subprocess.run([g,*a],check=True)
historical=[]
for line in read('status','--porcelain').splitlines():
 name=line[3:]
 if name.startswith(('docs/phase1-data-rules-','docs/phase1-database-engines-','docs/phase1-database-operations-','docs/phase1-database-transactions-','docs/phase1-dataset-bindings-')) or name in ['docs/wp0-validation.json','docs/wp2-input-validation.json','docs/wp3-input-validation.json']:
  head=subprocess.check_output([g,'show','HEAD:'+name]);assert (r/name).read_bytes().replace(b'\r\n',b'\n')==head.replace(b'\r\n',b'\n');historical.append(name)
if historical:run('add','--renormalize','--',*historical)
assert not read('diff','--cached','--name-only').strip()
e=json.loads((r/'docs/phase1-data-lineage-completion-validation.json').read_text());files=list(e['evidence_hashes'])+['docs/phase1-data-lineage-completion-validation.json']
run('add','--',*files)
staged=read('diff','--cached','--name-only').splitlines();assert set(staged)==set(files),(set(staged)-set(files),set(files)-set(staged))
run('diff','--cached','--check')
run('commit','-m','Implement scoped data lineage and evidence navigation for requirement 05.15')
run('push','origin','HEAD:main');run('push','private','HEAD:main')
head=read('rev-parse','HEAD').strip()
for remote in ['origin','private']:assert read('ls-remote',remote,'refs/heads/main').split()[0]==head
print('Verified both remotes:',head);print(read('status','--short'))
