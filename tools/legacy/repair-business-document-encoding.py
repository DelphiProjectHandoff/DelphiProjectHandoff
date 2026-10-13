from pathlib import Path
import re,json
report=[]
for name in ['tools/build-guides.py','README.md','help/index.html']:
 p=Path(name);s=p.read_text(encoding='utf-8-sig');changes=[]
 def repair(m):
  original=m.group();value=original
  for _ in range(12):
   next_value=value
   for encoding in ['cp1252','latin1']:
    try:
     candidate=value.encode(encoding).decode('utf-8')
     if candidate!=value:next_value=candidate;break
    except UnicodeError:pass
   if next_value==value:break
   value=next_value
  if value!=original:changes.append({'before':original,'after':value})
  return value
 s=re.sub(r'[^\x00-\x7f]+',repair,s);p.write_text(s,encoding='utf-8');report.append({'path':name,'repairs':changes})
 print(name,len(changes),'remaining markers',len(re.findall('[ÃÂ]',s)))
# Prevent authoring scripts from adding new encoding corruption if reused.
for name in ['bin/document-business-process.py','bin/verify-business-process-guides.py']:
 p=Path(name);s=p.read_text(encoding='utf-8-sig').replace('.read_text()',".read_text(encoding='utf-8')");p.write_text(s,encoding='utf-8')
Path('bin/business-document-encoding-repair.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
