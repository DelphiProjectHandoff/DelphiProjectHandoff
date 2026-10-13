from pathlib import Path
import re
root=Path(__file__).resolve().parents[2];p=root/'DPH.UI.Main.fmx';raw=p.read_bytes();text=raw.decode('utf-8-sig').replace('\r\n','\n')
sizes={'SetupPurpose':16,'TaskPurposeLabel':15,'TaskReaderTitle':20,'TaskContextMemo':15,'TaskStepLabel':17,'TaskActionMemo':18,'TaskResultMemo':15,'TaskPickerLabel':15,'TaskEditorPurpose':16,'TutorAction':16,'TutorExpected':16}
for key in ['name','purpose','prerequisites','expected_result','troubleshooting','practice']:sizes['Tutor_'+key]=16;sizes['Tutor_'+key+'_label']=15
for name,size in sizes.items():
 start=text.index('object '+name+':');end=text.index('\nend',start);block=text[start:end]
 block=re.sub(r'\nTextSettings.Font.Size = [^\n]+','',block)
 block=block+'\nStyledSettings = []\nTextSettings.Font.Size = '+str(size)
 if name in ['SetupPurpose','TaskReaderTitle','TaskStepLabel']:block+='\nTextSettings.FontColor = xFF146CB4'
 text=text[:start]+block+text[end:]
start=text.index('object WorkspacePageCombo:');end=text.index('\nend',start);block=text[start:end].replace('Margins.Right = 12','Margins.Left = 12\nMargins.Right = 12');text=text[:start]+block+text[end:]
p.write_bytes((b'\xef\xbb\xbf' if raw.startswith(b'\xef\xbb\xbf') else b'')+text.replace('\n','\r\n').encode('utf-8'))
