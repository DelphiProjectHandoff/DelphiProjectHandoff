from pathlib import Path
from PIL import Image,ImageOps,ImageDraw
from pypdf import PdfReader
r=Path('bin/guide-qa')
for name in ['DPH_User_Guide','DPH_Engineering_Guide']:
 pages=sorted((r/name).glob('page-*.png'),key=lambda p:int(p.stem.split('-')[1]))
 pages=pages[:len(PdfReader(Path('docs/pdf')/(name+'.pdf')).pages)]
 for start in range(0,len(pages),6):
  sheet=Image.new('RGB',(1500,1360),'#aaaaaa');d=ImageDraw.Draw(sheet)
  for j,p in enumerate(pages[start:start+6]):
   im=Image.open(p);im.thumbnail((490,640));x=(j%3)*500;y=(j//3)*680
   sheet.paste(im,(x,y+25));d.text((x+5,y+5),f'{name} {p.stem}',fill='black')
  sheet.save(r/f'{name}-review-{start//6+1}.png')
