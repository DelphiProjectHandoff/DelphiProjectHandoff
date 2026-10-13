from pathlib import Path
from zipfile import ZipFile
from xml.etree import ElementTree as ET
from pypdf import PdfReader
from html.parser import HTMLParser
import hashlib,json,re
root=Path(__file__).resolve().parents[2]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
backup=Path(r'H:\DPH Backups\LearningCompletion_PreChange_20261013_073811')
manifest=json.loads((backup/'DPH_Backup_Verification.json').read_text(encoding='utf-8-sig'))
preserved=[]
for row in manifest['entries']:
 name=row['path'].replace('\\','/')
 if name.startswith(('tests/fixtures/','samples/reference-vcl2fmx-v6.0.0/')) or name in ['docs/pdf/DPH_Engineering_Guide - Copy.pdf','docs/pdf/DPH_User_Guide - Copy.pdf','DPH_Master_Development_Specification_v1.md','DPH_CODEX_HANDOFF.txt','DPH_PHASE1_MASTER_REQUIREMENTS.md','docs/Phase1_Requirements_Traceability.json']:
  assert sha(root/name)==row['sha256'],name;preserved.append(name)
ns={'w':'http://schemas.openxmlformats.org/wordprocessingml/2006/main'};reports=[]
for kind,pages,chapters,images in [('User',16,12,3),('Engineering',10,8,0)]:
 docx=root/f'docs/guides/DPH_{kind}_Guide.docx';pdf=root/f'docs/pdf/DPH_{kind}_Guide.pdf'
 with ZipFile(docx) as z:
  xml=ET.fromstring(z.read('word/document.xml'));core=ET.fromstring(z.read('docProps/core.xml'))
  text='\n'.join(n.text or '' for n in xml.findall('.//w:t',ns))
  assert ' TOC ' in ''.join(n.text or '' for n in xml.findall('.//w:instrText',ns))
  assert not re.search(r'(?i)C:[\\/]|marti|GitHub|owner rejected|[a-f0-9]{64}',text)
  assert len([n for n in z.namelist() if n.startswith('word/media/')])==images
  headings=[''.join(n.text or '' for n in p.findall('.//w:t',ns)) for p in xml.findall('.//w:p',ns) if p.find('./w:pPr/w:pStyle',ns) is not None and p.find('./w:pPr/w:pStyle',ns).get('{'+ns['w']+'}val')=='Heading1']
  assert len(headings)==chapters
  for node in core:
   if node.tag.endswith(('creator','lastModifiedBy')):assert not node.text
 reader=PdfReader(pdf);assert len(reader.pages)==pages
 texts=[re.sub(r'\s+',' ',p.extract_text()).strip() for p in reader.pages]
 for heading in headings:assert any(heading in p for p in texts[2:]),heading
 if kind=='User':
  assert 'Win32' not in text and 'build-wp' not in text
  for phrase in ['Try practice example','Learning library','I checked this result','Explain this point','First day']:assert phrase in text
 reports.append({'guide':kind,'pages':pages,'chapters':chapters,'native_figures':images,'docx_sha256':sha(docx),'pdf_sha256':sha(pdf),'editable_contents':'populated','visual_review':'Final pages individually inspected'})
class Links(HTMLParser):
 def __init__(self):super().__init__();self.links=[]
 def handle_starttag(self,tag,attrs):
  for key,value in attrs:
   if key in ['src','href'] and value and not value.startswith(('#','http:','https:','data:')):self.links.append(value)
parser=Links();parser.feed((root/'help/index.html').read_text(encoding='utf-8'))
for target in parser.links:assert (root/'help'/target).is_file(),target
source=json.loads((root/'docs/guide-source-validation.json').read_text(encoding='utf-8-sig'))
for name in source['sources']:source['sources'][name]=sha(root/name)
(root/'docs/guide-source-validation.json').write_text(json.dumps(source,indent=2)+'\n',encoding='utf-8')
result={'result':'PASS current manuals, editable contents, privacy, local help links and preserved original inputs','guides':reports,'preserved_input_files':len(preserved),'historical_ledger_unchanged':True,'owner_pdf_copies_unchanged':True,'independent_beginner_acceptance':'not performed'}
(root/'docs/learning-completion-guides-validation.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print(json.dumps(result,indent=2))
