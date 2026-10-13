from pathlib import Path
import subprocess,json,hashlib
r=Path.cwd();g=r'C:\Program Files\Git\cmd\git.exe'
def read(*a):return subprocess.check_output([g,*a]).decode()
def run(*a):subprocess.run([g,*a],check=True)
lock=r/'.git/index.lock'
if lock.exists():
 processes=subprocess.check_output(['powershell','-NoProfile','-Command',"@(Get-Process git -ErrorAction SilentlyContinue).Count"]).decode().strip();assert lock.stat().st_size==0 and processes=='0';lock.unlink()
assert read('rev-parse','HEAD').strip().startswith('1505786')
for remote in ['origin','private']:
 run('fetch',remote);assert read('rev-list','--left-right','--count','HEAD...'+remote+'/main').split()==['0','0']
assert not read('diff','--cached','--name-only').strip()
e=json.loads((r/'docs/phase1-schema-history-completion-validation.json').read_text());files=list(e['evidence_hashes'])+['docs/phase1-schema-history-completion-validation.json']
for f,h in e['evidence_hashes'].items():assert hashlib.sha256((r/f).read_bytes()).hexdigest()==h,f
run('add','--',*files)
assert set(read('diff','--cached','--name-only').splitlines())==set(files)
run('diff','--cached','--check');run('diff','--cached','--stat')
run('commit','-m','Implement captured migration and schema-version history for requirement 05.16')
for remote in ['origin','private']:run('push',remote,'HEAD:main')
head=read('rev-parse','HEAD').strip()
for remote in ['origin','private']:assert read('ls-remote',remote,'refs/heads/main').split()[0]==head
assert not read('status','--porcelain').strip()
print('Verified clean worktree and both remotes:',head)
