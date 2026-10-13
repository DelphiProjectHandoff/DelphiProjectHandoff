from pathlib import Path
from pypdf import PdfReader
from PIL import Image,ImageDraw
from zipfile import ZipFile
from lxml import etree
import json,hashlib,re
r=Path.cwd();summary=[];W='{http://schemas.openxmlformats.org/wordprocessingml/2006/main}'
g=json.loads((r/'docs/guide-source-validation.json').read_text(encoding='utf-8'));assert g['guide_version']==35
for s in g['sources']: assert hashlib.sha256((r/s['path']).read_bytes()).hexdigest()==s['sha256'],s['path']
for name,heading in [('DPH_User_Guide','Inventory business processes'),('DPH_Engineering_Guide','Maintain structured business process records')]:
 pdf=PdfReader(r/f'docs/pdf/{name}.pdf');pages=[x.extract_text() or '' for x in pdf.pages]
 assert all(len(x)>100 for x in pages),'Blank page'
 newpages=[i+1 for i,t in enumerate(pages) if heading in t]
 assert len(newpages)>=2,(name,newpages)
 with ZipFile(r/f'docs/guides/{name}.docx') as z:
  xml=etree.fromstring(z.read('word/document.xml'));assert any(' TOC ' in (x.text or '') for x in xml.iter(W+'instrText'))
  inside=False;separated=False;entries=0
  for para in xml.iter(W+'p'):
   if any(' TOC ' in (x.text or '') for x in para.iter(W+'instrText')):inside=True
   if not inside:continue
   chars=list(para.iter(W+'fldChar'))
   if any(x.get(W+'fldCharType')=='separate' for x in chars):separated=True;continue
   if any(x.get(W+'fldCharType')=='end' for x in chars):break
   if not separated:continue
   label=''.join(x.text or '' for x in para.iter(W+'t'));match=re.fullmatch(r'(.+?)(\d+)',label)
   if not match:continue
   title,number=match.groups();lines=[re.sub(r'\s+',' ',line).strip() for line in pages[int(number)-1].splitlines()];assert title in lines,(name,title,number);entries+=1
 qa=r/f'bin/guide-qa/{name}';images=[qa/f'page-{i+1}.png' for i in range(len(pages))]
 for start in range(0,len(images),6):
  sheet=Image.new('RGB',(1536,1450),'#d0d0d0');draw=ImageDraw.Draw(sheet)
  for j,path in enumerate(images[start:start+6]):
   im=Image.open(path).convert('RGB');im.thumbnail((492,680));x=(j%3)*512+10;y=(j//3)*725+28;sheet.paste(im,(x,y));draw.text((x,y-20),f'{name} page {start+j+1}',fill='black')
  sheet.save(qa/f'review-{start//6+1}.png')
 summary.append({'name':name,'pages':len(pages),'toc_entries':entries,'new_chapter_pages':newpages,'blank_pages':0,'toc_numbers_verified':True})
(r/'bin/business-process-guide-check.json').write_text(json.dumps({'guide_sources_verified':len(g['sources']),'guides':summary},indent=2));print(json.dumps(summary))
