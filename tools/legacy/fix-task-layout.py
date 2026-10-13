from pathlib import Path
root=Path(__file__).resolve().parents[2]
p=root/'DPH.UI.Main.fmx';raw=p.read_bytes();text=raw.decode('utf-8-sig')
start=text.index('object TaskReaderPanel:');end=text.index('object TaskEditorTab:',start)
block=text[start:end]
nstart=block.index('object TaskNavigation:');nend=block.index('object TaskResultMemo:',nstart)
nav=block[nstart:nend];block=block[:nstart]+block[nend:]
opening=block.index('object TaskReaderTitle:')
block=block[:opening]+nav+'object TaskReaderScroll: TVertScrollBox\nAlign = Client\n'+block[opening:]
for name,y in [('TaskReaderTitle',0),('TaskContextMemo',38),('TaskStepLabel',148),('TaskActionMemo',178),('TaskResultMemo',358)]:
    pos=block.index('object '+name+':');align=block.index('Align = ',pos)
    if name=='TaskActionMemo': block=block[:align]+block[align:].replace('Align = Client','Align = Top\nHeight = 180',1)
    align=block.index('Align = ',pos);block=block[:align]+'Position.Y = '+str(y)+'\n'+block[align:]
block=block.rstrip()+'\nend\n'
text=text[:start]+block+text[end:]
for tab in ['TaskTab','TaskEditorTab']:
    text=text.replace('object '+tab+': TTabItem\n','object '+tab+': TTabItem\nPadding.Left = 12\nPadding.Right = 12\n',1)
p.write_bytes((b'\xef\xbb\xbf' if raw.startswith(b'\xef\xbb\xbf') else b'')+text.replace('\r\n','\n').replace('\n','\r\n').encode('utf-8'))
p=root/'DPH.UI.Main.pas';raw=p.read_bytes();text=raw.decode('utf-8-sig').replace('    TaskReaderPanel: TLayout;','    TaskReaderPanel: TLayout;\n    TaskReaderScroll: TVertScrollBox;',1)
p.write_bytes((b'\xef\xbb\xbf' if raw.startswith(b'\xef\xbb\xbf') else b'')+text.replace('\r\n','\n').replace('\n','\r\n').encode('utf-8'))
