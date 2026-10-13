from pathlib import Path
import subprocess
r=Path.cwd();p=r/'docs/wp3-reference-validation.json'
p.write_bytes(subprocess.check_output([r'C:\Program Files\Git\cmd\git.exe','show','9da0486:docs/wp3-reference-validation.json'],cwd=r))
