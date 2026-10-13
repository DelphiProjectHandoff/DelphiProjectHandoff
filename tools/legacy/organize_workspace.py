from pathlib import Path
import csv
import hashlib
import os
import re

root = Path(__file__).resolve().parents[2]
def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()
def inside(path):
    resolved = path.resolve()
    if not resolved.is_relative_to(root.resolve()):
        raise RuntimeError(f'Outside project: {path}')
def destination(path):
    rel = path.relative_to(root).as_posix()
    if path.parent == root and path.name in {
        'DPH_CODEX_HANDOFF.txt', 'DPH_Master_Development_Specification_v1.md',
        'DPH_PHASE1_MASTER_REQUIREMENTS.md'}:
        return root / 'docs/planning' / path.name
    if path.parent == root / 'docs':
        if path.suffix == '.log':
            return root / 'logs/validation' / path.name
        if path.suffix == '.png':
            return root / 'docs/validation/images' / path.name
        if path.name.startswith('Learning_Requirements_Reconciliation') or path.name == 'Phase1_Implementation_Backlog.csv':
            return root / 'docs/requirements' / path.name
        if path.suffix == '.json':
            return root / 'docs/validation/reports' / path.name
        if path.name in {'Learning_Refocus_Status.txt', 'STOPPING_POINT.txt', 'Implementation_Completion_Tracker.txt'}:
            return root / 'docs/status' / path.name
        if path.suffix == '.txt':
            return root / 'docs/history' / path.name
    if path.parent == root / 'docs/guides' and path.suffix == '.txt' and path.name not in {
        'Run_And_Test.txt', 'Developer_Test_Directions.txt', 'Workspace_Operations.txt'}:
        return root / 'docs/guides/reference' / path.name
    if path.parent == root / 'bin':
        if path.suffix == '.log':
            return root / 'logs/development' / path.name
        if path.suffix in {'.json', '.tsv'}:
            return root / 'bin/reports' / path.name
        if path.suffix == '.dphdb':
            return root / 'Databases/validation-archives' / path.name
        if path.suffix == '.exe':
            return root / 'bin/probes' / path.name
        if path.suffix == '.txt':
            return root / 'bin/notes' / path.name
    return None

sources = [*root.iterdir(), *(root / 'docs').iterdir(),
           *(root / 'docs/guides').iterdir(), *(root / 'bin').iterdir()]
moves = [(p, destination(p)) for p in sources if p.is_file()]
moves = [(a, b) for a, b in moves if b is not None]
for old, new in moves:
    inside(old)
    inside(new)
    if new.exists():
        raise RuntimeError(f'Destination exists: {new}')

mapping = {a.relative_to(root).as_posix(): b.relative_to(root).as_posix() for a, b in moves}
if not moves:
    reverse_folders = {
        'docs/planning': '', 'docs/requirements': 'docs',
        'docs/validation/reports': 'docs', 'docs/validation/images': 'docs',
        'docs/status': 'docs', 'docs/history': 'docs',
        'docs/guides/reference': 'docs/guides',
        'logs/validation': 'docs', 'logs/development': 'bin',
        'bin/reports': 'bin', 'bin/notes': 'bin', 'bin/probes': 'bin',
        'Databases/validation-archives': 'bin'}
    for folder, previous in reverse_folders.items():
        for item in (root/folder).iterdir():
            if item.is_file():
                old = (Path(previous)/item.name).as_posix()
                mapping[old] = item.relative_to(root).as_posix()
rows = []
for old, new in moves:
    before = sha(old)
    new.parent.mkdir(parents=True, exist_ok=True)
    os.replace(old, new)
    if sha(new) != before:
        raise RuntimeError(f'Hash mismatch: {old}')
    rows.append((old.relative_to(root).as_posix(), new.relative_to(root).as_posix(), before))

# Update exact path literals in maintained tools and tests. Historical reports stay byte-identical.
maintained = [*list((root/'tools').rglob('*')), *list((root/'tests').rglob('*')),
              root/'README.md', root/'.gitattributes',
              *list((root/'docs/guides/source').glob('*.txt'))]
changed = []
for path in maintained:
    if not path.is_file() or path.suffix not in {'.ps1','.cmd','.py','.dpr','.txt','.md','.gitattributes'}:
        continue
    try:
        raw = path.read_bytes()
        value = raw.decode('utf-8-sig')
    except UnicodeDecodeError:
        continue
    updated = value
    for old, new in mapping.items():
        updated = updated.replace(old, new).replace(old.replace('/', '\\'), new.replace('/', '\\'))
    # Input source documents were formerly looked up by bare name from the project root.
    for name in ('DPH_CODEX_HANDOFF.txt','DPH_Master_Development_Specification_v1.md','DPH_PHASE1_MASTER_REQUIREMENTS.md'):
        updated = re.sub(r'(?<![A-Za-z0-9_/\\])' + re.escape(name),
                         'docs/planning/' + name, updated)
    if updated != value:
        encoding = 'utf-8-sig' if raw.startswith(b'\xef\xbb\xbf') else 'utf-8'
        newline = '\r\n' if b'\r\n' in raw else '\n'
        temporary = path.with_name(path.name + '.dph-tmp')
        temporary.write_bytes(updated.replace('\n', newline).replace('\r\r\n','\r\n').encode(encoding))
        os.replace(temporary, path)
        changed.append(path.relative_to(root).as_posix())

manifest = root / 'docs/PROJECT_MOVE_MANIFEST.csv'
with manifest.open('w', encoding='utf-8', newline='') as file:
    writer = csv.writer(file)
    writer.writerow(('previous_path','current_path','sha256'))
    if rows:
        writer.writerows(rows)
    else:
        writer.writerows((old, new, sha(root/new)) for old, new in sorted(mapping.items()))
print(f'MOVED {len(rows)} files; UPDATED {len(changed)} maintained source files')
print('UPDATED FILES:', *changed, sep='\n')
