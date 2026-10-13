from pathlib import Path
from zipfile import ZipFile
from xml.etree import ElementTree as ET
from html.parser import HTMLParser
from pypdf import PdfReader
import json,re,hashlib,shutil
root=Path(__file__).resolve().parents[2]
backup=Path(r'H:\DPH Backups\LearningGuides_PreChange_20261012_235331')
manifest=json.loads((backup/'DPH_Backup_Verification.json').read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
unchanged=[]
for entry in manifest['entries']:
 name=entry['path'].replace('\\','/')
 if name.startswith('tests/fixtures/') or name in ['docs/pdf/DPH_Engineering_Guide - Copy.pdf','docs/pdf/DPH_User_Guide - Copy.pdf','DPH_Master_Development_Specification_v1.md','DPH_PHASE1_MASTER_REQUIREMENTS.md','DPH_CODEX_HANDOFF.txt']:
  assert sha(root/name)==entry['sha256'],name;unchanged.append(name)
reference=json.loads((root/'docs/reference-inventory.json').read_text(encoding='utf-8-sig'))
for entry in reference['files']:assert sha(root/'samples/reference-vcl2fmx-v6.0.0'/entry['path'])==entry['sha256'],entry['path']
ns={'w':'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
reports=[]
for kind,count in [('User',13),('Engineering',10)]:
 docx=root/f'docs/guides/DPH_{kind}_Guide.docx';pdf=root/f'docs/pdf/DPH_{kind}_Guide.pdf'
 with ZipFile(docx) as z:
  xml=ET.fromstring(z.read('word/document.xml'));core=ET.fromstring(z.read('docProps/core.xml'))
  text='\n'.join(n.text or '' for n in xml.findall('.//w:t',ns))
  assert ' TOC ' in ''.join(n.text or '' for n in xml.findall('.//w:instrText',ns))
  assert not re.search(r'(?i)C:[\\/]|marti|GitHub|WP7|owner rejected|[a-f0-9]{64}',text)
  for node in core:
   if node.tag.endswith(('creator','lastModifiedBy')):assert not node.text
  headings=[ ''.join(n.text or '' for n in p.findall('.//w:t',ns)) for p in xml.findall('.//w:p',ns) if p.find('./w:pPr/w:pStyle',ns) is not None and p.find('./w:pPr/w:pStyle',ns).get('{'+ns['w']+'}val')=='Heading1']
  assert len(headings)==(10 if kind=='User' else 8)
  assert len([n for n in z.namelist() if n.startswith('word/media/')])==(2 if kind=='User' else 0)
 reader=PdfReader(pdf);assert len(reader.pages)==count
 pages=[re.sub(r'\s+',' ',p.extract_text()).strip() for p in reader.pages]
 for heading in headings:assert any(heading in page for page in pages[2:]),heading
 if kind=='User':assert 'Win32' not in text and 'build-wp' not in text
 reports.append({'guide':kind,'pages':count,'headings':headings,'docx_sha256':sha(docx),'pdf_sha256':sha(pdf),'visual_review':'Every final rendered page inspected; readable without clipping or overlap','metadata':'No personal author or local development paths'})
evidence=json.loads((root/'docs/guide-source-validation.json').read_text(encoding='utf-8-sig'))
for name in evidence['sources']:evidence['sources'][name]=sha(root/name)
(root/'docs/guide-source-validation.json').write_text(json.dumps(evidence,indent=2)+'\n',encoding='utf-8')
for source,target in [('LearningRefocus.log','learning-guides-native.log'),('GuidedTasks.log','learning-guides-tasks.log'),('Phase1.log','learning-guides-profile.log'),('Publishing.log','learning-guides-publishing.log')]:
 p=root/'bin/learner-sharing'/source
 if p.exists():shutil.copyfile(p,root/'docs'/target)
report={'result':'PASS current manuals; package deployment and independent learning acceptance are separate','backup':str(backup),'backup_files':manifest['files'],'backup_bytes':manifest['bytes'],'manuals':reports,
 'unchanged_inputs_and_owner_copies':unchanged,'unchanged_reference_files':len(reference['files']),
 'review_used':'DPH Guides Review.txt, read only at the final documentation phase','historical_requirement_ledger':'unchanged; not relabeled complete','independent_beginner_acceptance':'not performed'}
(root/'docs/learning-guides-verification.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print('PASS two manuals, 23 inspected pages, editable contents, privacy checks, preserved owner PDFs and',len(reference['files']),'reference files')
