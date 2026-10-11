"""Populate the cached result of an editable TOC from a matching rendered PDF."""
from pathlib import Path
import argparse
import re
from zipfile import ZipFile, ZIP_DEFLATED
from xml.etree import ElementTree as ET
from pypdf import PdfReader

parser = argparse.ArgumentParser()
parser.add_argument('docx', type=Path)
parser.add_argument('pdf', type=Path)
args = parser.parse_args()
W = '{http://schemas.openxmlformats.org/wordprocessingml/2006/main}'
ET.register_namespace('w', W[1:-1])
with ZipFile(args.docx) as archive:
    parts = {info.filename: archive.read(info.filename) for info in archive.infolist()}
root = ET.fromstring(parts['word/document.xml'])
pages = [[re.sub(r'\s+', ' ', line).strip().casefold()
          for line in (p.extract_text() or '').splitlines()]
         for p in PdfReader(args.pdf).pages]
inside = False
separated = False
entries = []
body_start = None
for paragraph in root.iter(W+'p'):
    instructions = ''.join(n.text or '' for n in paragraph.iter(W+'instrText'))
    if 'TOC ' in instructions:
        inside = True
    if not inside:
        continue
    chars = list(paragraph.iter(W+'fldChar'))
    if any(n.get(W+'fldCharType') == 'separate' for n in chars):
        separated = True
        continue
    if any(n.get(W+'fldCharType') == 'end' for n in chars):
        break
    if not separated:
        continue
    heading = ''.join(n.text or '' for n in paragraph.iter(W+'t')).strip()
    if not heading:
        continue
    # Support updating the same cache again after a second render.
    heading = re.sub(r'\s+\d+$', '', heading).strip()
    lookup = re.sub(r'\s+', ' ', heading).casefold()
    # TOC rows contain a leader and page number. Match a whole body-heading line
    # so a continued contents page cannot masquerade as the chapter itself.
    # The first entry appears on contents page two, even when later entries
    # continue onto more pages. Locate its body heading first, then constrain
    # all other lookups to the body so a continued initial TOC cannot match.
    if body_start is None:
        body_start = next((i for i, lines in enumerate(pages) if i >= 2 and lookup in lines), None)
    page = next((i+1 for i, lines in enumerate(pages)
                 if body_start is not None and i >= body_start and lookup in lines), None)
    if page is None:
        raise RuntimeError(f'TOC heading absent from body PDF: {heading}')
    # Keep the authored spacing when replacing the field result. Dropping pPr
    # can move the TOC onto another page and invalidate every cached page number.
    props = paragraph.find(W+'pPr')
    for child in list(paragraph):
        if child is not props:
            paragraph.remove(child)
    if props is None:
        props = ET.SubElement(paragraph, W+'pPr')
    for existing in list(props.findall(W+'tabs')):
        props.remove(existing)
    tabs = ET.SubElement(props, W+'tabs')
    ET.SubElement(tabs, W+'tab', {W+'val': 'right', W+'leader': 'dot', W+'pos': '9360'})
    run = ET.SubElement(paragraph, W+'r')
    ET.SubElement(run, W+'t').text = heading
    run = ET.SubElement(paragraph, W+'r')
    ET.SubElement(run, W+'tab')
    ET.SubElement(run, W+'t').text = str(page)
    entries.append({'heading': heading, 'page': page})
if not entries:
    raise RuntimeError('No editable TOC field with cached entries was found')
parts['word/document.xml'] = ET.tostring(root, encoding='utf-8', xml_declaration=True)
temporary = args.docx.with_suffix('.updated.docx')
with ZipFile(temporary, 'w', ZIP_DEFLATED) as archive:
    for name, content in parts.items():
        archive.writestr(name, content)
temporary.replace(args.docx)
print(f'Populated {len(entries)} TOC entries against {len(pages)} PDF pages for {args.docx.name}')
