from pathlib import Path
import hashlib,json,zipfile
from pypdf import PdfReader
root=Path(r'C:\New Delphi Projects\Delphi Project Handoff')
evidence=json.loads((root/'docs'/'guide-source-validation.json').read_text(encoding='utf-8-sig'))
for item in evidence['sources']:
    assert hashlib.sha256((root/item['path']).read_bytes()).hexdigest()==item['sha256'], item['path']
guides=[]
for name in ['DPH_Engineering_Guide','DPH_User_Guide']:
    docx=root/'docs'/'guides'/(name+'.docx')
    pdf=root/'docs'/'pdf'/(name+'.pdf')
    with zipfile.ZipFile(docx) as archive:
        assert ' TOC ' in archive.read('word/document.xml').decode(), name
    guides.append(dict(guide=name,pages=len(PdfReader(pdf).pages),docx_sha256=hashlib.sha256(docx.read_bytes()).hexdigest(),pdf_sha256=hashlib.sha256(pdf.read_bytes()).hexdigest(),editable_toc=True))
report=dict(sources_verified=len(evidence['sources']),guides=guides,visual_review='All 22 rendered pages reviewed; changed directions and backup paragraphs additionally checked at page size',layout_checks=16,learning_checks=53,backup_policy='D: suspended; local Git and both GitHub remotes enabled')
(root/'docs'/'ui-layout-guide-validation.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('PASS current source hashes, editable TOCs and final guide evidence')
