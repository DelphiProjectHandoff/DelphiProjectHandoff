from pathlib import Path
from PIL import Image, ImageOps, ImageDraw
from pypdf import PdfReader
root = Path(r'C:\New Delphi Projects\Delphi Project Handoff')
for guide in ['DPH_Engineering_Guide', 'DPH_User_Guide']:
    pages = sorted((root/'bin'/'guide-qa'/guide).glob('page-*.png'), key=lambda p: int(p.stem.split('-')[-1]))
    pages=pages[:len(PdfReader(root/'docs'/'pdf'/(guide+'.pdf')).pages)]
    for start in range(0,len(pages),4):
        sheet=Image.new('RGB',(1440,1940),'#cbd5e1')
        draw=ImageDraw.Draw(sheet)
        for i,path in enumerate(pages[start:start+4]):
            image=Image.open(path).convert('RGB')
            image.thumbnail((700,930))
            x=(i%2)*720+(720-image.width)//2
            y=(i//2)*970+30
            sheet.paste(image,(x,y))
            draw.text(((i%2)*720+12,(i//2)*970+8),path.name,fill='black')
        sheet.save(root/'bin'/'guide-qa'/f'{guide}-layout-review-{start//4+1}.png')
    print(guide,len(pages),'pages')
