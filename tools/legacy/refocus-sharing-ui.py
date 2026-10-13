from pathlib import Path
root=Path(__file__).resolve().parents[2]
p=root/'DPH.UI.Main.fmx';raw=p.read_bytes();text=raw.decode('utf-8-sig').replace('\r\n','\n')
def take(name):
 global text
 start=text.index('object '+name+':');lines=text[start:].splitlines(keepends=True);depth=0;length=0
 for line in lines:
  if line.startswith('object '):depth+=1
  if line.strip()=='end':depth-=1
  length+=len(line)
  if depth==0:break
 block=text[start:start+length];text=text[:start]+text[start+length:];return block
button=take('PublishButton').replace("Text = 'Export HTML guides and AI bundle'","Text = 'Share lessons'").replace('Position.Y = 42','Position.Y = 4')
preview=take('PreviewButton').replace("Text = 'Preview offline HTML'","Text = 'Preview lessons'").replace('Position.Y = 42','Position.Y = 4')
start=text.index('object PublishToolbar:');text=text[:start]+text[start:].replace('object PublishToolbar: THorzScrollBox\nAlign = Top\nHeight = 190', 'object PublishOptionsLayout: TLayout\nAlign = Client\nHeight = 190',1)
start=text.index('object PublishOptionsLayout:')
intro='''object PublishPurpose: TLabel
Align = Top
Height = 64
Margins.Left = 12
Margins.Right = 12
WordWrap = True
StyledSettings = []
TextSettings.Font.Size = 16
Text = 'Share a saved learning edition of this application. Choose Share lessons, give the new folder a name, then Preview lessons. The edition includes learning topics, supplied task instructions, explanations and images. Review the material before sharing it.'
end
object PublishToolbar: THorzScrollBox
Align = Top
Height = 46
'''+button+preview+'''end
object PublishSettingsExpander: TExpander
Align = Top
Height = 34
HeaderHeight = 34
ContentSize = '190'
IsExpanded = False
Text = 'Optional publication settings'
'''
text=text[:start]+intro+text[start:]
start=text.index('object PublishMemo:');text=text[:start]+'end\n'+text[start:]
text=text.replace('object PublishMemo: TMemo\nAlign = Top\nHeight = 140','object PublishMemo: TMemo\nAlign = Top\nHeight = 92',1)
p.write_bytes((b'\xef\xbb\xbf' if raw.startswith(b'\xef\xbb\xbf') else b'')+text.replace('\n','\r\n').encode('utf-8'))
p=root/'DPH.UI.Main.pas';raw=p.read_bytes();text=raw.decode('utf-8-sig').replace('\r\n','\n')
text=text.replace('    PublishAudienceCombo: TComboBox;','    PublishAudienceCombo: TComboBox;\n    PublishPurpose: TLabel;\n    PublishSettingsExpander: TExpander;\n    PublishOptionsLayout: TLayout;',1)
p.write_bytes((b'\xef\xbb\xbf' if raw.startswith(b'\xef\xbb\xbf') else b'')+text.replace('\n','\r\n').encode('utf-8'))
print('Native serialized sharing controls updated')
