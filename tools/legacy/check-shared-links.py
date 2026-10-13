from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit,unquote
import json
root=Path(__file__).resolve().parents[2]
work=Path(json.loads((root/'bin/learner-sharing/wp6-validation.json').read_text(encoding='utf-8-sig'))['work'])/'full'
class Links(HTMLParser):
 def __init__(self):super().__init__();self.links=[];self.ids=set()
 def handle_starttag(self,tag,attrs):
  attrs=dict(attrs)
  if 'id' in attrs:self.ids.add(attrs['id'])
  if tag=='a' and 'href' in attrs:self.links.append(attrs['href'])
pages={}
for p in work.rglob('*.html'):
 parser=Links();parser.feed(p.read_text(encoding='utf-8-sig'));pages[p.resolve()]=parser
checks=0
for p,parser in pages.items():
 for href in parser.links:
  uri=urlsplit(href);assert not uri.scheme and not uri.netloc,(p,href)
  target=(p.parent/unquote(uri.path)).resolve() if uri.path else p
  assert target.is_relative_to(work.resolve()) and target.exists(),(p,href)
  if uri.fragment:assert unquote(uri.fragment) in pages[target].ids,(p,href,'missing anchor')
  checks+=1
print('PASS',checks,'local HTML links across',len(pages),'pages; no external navigation')
(root/'docs/learner-sharing-links.json').write_text(json.dumps({'result':'PASS','links':checks,'html_pages':len(pages),'scope':'Synthetic selected-project publication with excluded worker unit'},indent=2)+'\n',encoding='utf-8')
