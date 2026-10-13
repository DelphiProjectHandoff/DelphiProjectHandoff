from pathlib import Path
from zipfile import ZipFile
from xml.etree import ElementTree as ET
from pypdf import PdfReader
from PIL import Image,ImageDraw,ImageFont
import json,re,hashlib,subprocess
root=Path(__file__).resolve().parents[2];out=root/'bin/detailed-guide-qa';out.mkdir(exist_ok=True)
W='{http://schemas.openxmlformats.org/wordprocessingml/2006/main}'
def clean(s):return re.sub(r'\s+',' ',s).strip()
report={}
for kind in ['User','Engineering']:
 docx=root/f'docs/guides/DPH_{kind}_Guide.docx';pdf=root/f'docs/pdf/DPH_{kind}_Guide.pdf'
 with ZipFile(docx) as archive:
  tree=ET.fromstring(archive.read('word/document.xml'));core=ET.fromstring(archive.read('docProps/core.xml'))
  paragraphs=list(tree.iter(W+'p'));text='\n'.join(''.join(n.text or '' for n in p.iter(W+'t')) for p in paragraphs)
  headings=[]
  for p in paragraphs:
   style=p.find('./'+W+'pPr/'+W+'pStyle')
   if style is not None and style.get(W+'val') in ['Heading1','Heading2','Heading3']:headings.append((style.get(W+'val'),clean(''.join(n.text or '' for n in p.iter(W+'t')))))
  assert sum(s=='Heading1' for s,t in headings)==6
  assert sum(s=='Heading2' for s,t in headings)==27
  assert ' TOC ' in ''.join(n.text or '' for n in tree.iter(W+'instrText'))
  assert not re.search(r'(?i)C:[\\/]Users|C:[\\/]New Delphi Projects|\bmarti\b|owner rejected|cock.up',text)
  if kind=='User':assert 'dcc32' not in text and 'build-wp0' not in text
  for node in core:
   if node.tag.endswith(('creator','lastModifiedBy')):assert not node.text
  # Cached contents must point to the exact final body heading, including wrapped headings.
  pages=PdfReader(pdf).pages;lines=[[clean(x) for x in (p.extract_text() or '').splitlines()] for p in pages]
  def hasheading(page,title):return any(clean(' '.join(page[i:i+n]))==title for i in range(len(page)) for n in range(1,4))
  inside=False;cached=[]
  for p in paragraphs:
   instruction=''.join(n.text or '' for n in p.iter(W+'instrText'))
   if 'TOC ' in instruction:inside=True;continue
   if inside and any(n.get(W+'fldCharType')=='end' for n in p.iter(W+'fldChar')):break
   if not inside:continue
   values=[n.text or '' for n in p.iter(W+'t')]
   if len(values)>=2 and values[-1].isdigit():cached.append((clean(''.join(values[:-1])),int(values[-1])))
  assert len(cached)==33,(kind,len(cached))
  for title,page in cached:assert hasheading(lines[page-1],title),(kind,title,page)
  # Verify every chapter and subsection has its expected numbered hierarchy.
  chapter=0;section=0
  for style,title in headings:
   if style=='Heading2':chapter+=1;section=0;assert title.startswith(str(chapter)+' '),title
   if style=='Heading3':section+=1;assert title.startswith(f'{chapter}.{section} '),title
  figurecount=len([n for n in archive.namelist() if n.startswith('word/media/')])
  assert figurecount==(6 if kind=='User' else 0)
 # Check PDF text origins and rendered edge margins; visual review checks full extents.
 for page in pages:
  def visitor(text,cm,tm,font,size):
   if not text.strip():return
   x=tm[4]*cm[0]+tm[5]*cm[2]+cm[4];y=tm[4]*cm[1]+tm[5]*cm[3]+cm[5]
   assert 0<=x<=612.5 and 0<=y<=792.5,(kind,text[:60],x,y)
  page.extract_text(visitor_text=visitor)
 # Produce six-page sheets for complete visual pagination inspection.
 qa=root/f'bin/guide-qa/DPH_{kind}_Guide';sheets=[]
 font=ImageFont.truetype(r'C:\Windows\Fonts\segoeui.ttf',22)
 for start in range(1,len(pages)+1,6):
  sheet=Image.new('RGB',(1800,3480),'#dde3e8');draw=ImageDraw.Draw(sheet)
  for j,n in enumerate(range(start,min(start+6,len(pages)+1))):
   image=Image.open(qa/f'page-{n}.png').convert('RGB');image.thumbnail((870,1125))
   x=(j%2)*900+15;y=(j//2)*1160+30;sheet.paste(image,(x,y));draw.text((x,y-27),f'{kind} page {n}',font=font,fill='black')
  target=out/f'{kind}-{start:03d}.jpg';sheet.save(target,quality=90);sheets.append(str(target))
 report[kind]={'pages':len(pages),'parts':6,'chapters':27,'subsections':sum(s=='Heading3' for s,t in headings),'native_figures':figurecount,'contents_entries_verified':len(cached),'privacy':'PASS','text_origins_within_page':'PASS','docx_sha256':hashlib.sha256(docx.read_bytes()).hexdigest(),'pdf_sha256':hashlib.sha256(pdf.read_bytes()).hexdigest(),'sheets':sheets}
source=json.loads((root/'docs/validation/reports/guide-source-validation.json').read_text())
for name,digest in source['sources'].items():assert hashlib.sha256((root/name).read_bytes()).hexdigest()==digest,name
report['source_hashes_verified']=len(source['sources'])
(out/'structural-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:{a:b for a,b in v.items() if a!='sheets'} if isinstance(v,dict) else v for k,v in report.items()},indent=2))
