from pathlib import Path
import re
root = Path(__file__).resolve().parents[2]
for path in [*(root/'tools').rglob('*'), *(root/'tests').rglob('*')]:
    if not path.is_file() or path.suffix not in {'.ps1','.cmd','.py','.dpr'}:
        continue
    raw = path.read_bytes()
    try: text = raw.decode('utf-8-sig')
    except UnicodeDecodeError: continue
    new = text.replace('docs/planning/docs\\planning\\','docs\\planning\\')
    new = new.replace("'docs/requirements/Learning_Requirements_Reconciliation.txt','docs/requirements/Learning_Requirements_Reconciliation.csv','docs/requirements/Learning_Requirements_Reconciliation.json','docs/requirements/Learning_Requirements_Reconciliation.txt'", "'docs/requirements/Learning_Requirements_Reconciliation.txt','docs/requirements/Learning_Requirements_Reconciliation.csv','docs/requirements/Learning_Requirements_Reconciliation.json'")
    for extension, folder in (('png','docs/validation/images'),('json','docs/validation/reports'),('log','logs/validation')):
        new = re.sub(r'docs[/\\]([A-Za-z0-9_-]+\.'+extension+r')',
                     lambda m: folder.replace('/', '\\' if '\\' in m[0] else '/') + ('\\' if '\\' in m[0] else '/') + m[1], new)
    if new != text:
        path.write_bytes(new.encode('utf-8-sig' if raw.startswith(b'\xef\xbb\xbf') else 'utf-8'))
        print(path.relative_to(root))
