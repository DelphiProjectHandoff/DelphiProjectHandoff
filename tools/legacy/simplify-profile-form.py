from pathlib import Path
import re,subprocess
root=Path(__file__).resolve().parents[2];path=root/'DPH.UI.ProjectProfile.fmx';text=path.read_text(encoding='utf-8-sig')
labels={'purpose':'What the application does and who uses it','owner':'Who is responsible for this application','support':'Who can answer questions or help with a problem','environments':'Where safe learning and practice should happen','relationships':'Other systems the learner needs to know about','architecture':'How its main parts fit together in plain language','evidence':'Who supplied these facts and what still needs checking'}
order={key:i for i,key in enumerate(labels)}
def row(match):
 key=match.group(1);block=match.group(0)
 block=re.sub(r'Position.Y = \d+',f'Position.Y = {order.get(key,0)*122}',block,count=1)
 if key not in order:
  block=block.replace('Height = 122','Height = 0\n      Visible = False',1)
 else:
  block=re.sub(r"Text = '[^']*'","Text = '"+labels[key]+"'",block,count=1)
 return block
text=re.sub(r'    object Profile_([a-z_]+)_Row: TLayout\n.*?(?=    object Profile_|  end\nend\s*$)',row,text,flags=re.S)
for key,label in labels.items():text=re.sub(r'(object Profile_'+key+r"_Label: TLabel\n.*?Text = )'[^']*'",lambda m:m[1]+"'"+label+"'",text,count=1,flags=re.S)
text=text.replace("Caption = 'Selected application profile'","Caption = 'Describe the application'")
text=text.replace('Describe only the selected application. Purpose and attribution are required. Blank optional fields stay explicitly unknown. Apply creates a Knowledge draft; use Save there, then review with a named reviewer. Do not enter credentials.','Explain the selected application for a new learner: its purpose, who can help, where practice is safe and how its main parts fit together. Purpose and attribution are required. Apply prepares a draft; click Save in Saved explanations to keep it. Leave unanswered fields Unknown.')
before=subprocess.check_output([r'C:\Program Files\Git\cmd\git.exe','show','HEAD:DPH.UI.ProjectProfile.fmx'],cwd=root)
path.write_bytes((b'\xef\xbb\xbf' if before.startswith(b'\xef\xbb\xbf') else b'')+text.replace('\r\n','\n').replace('\n','\r\n').encode('utf-8'))
assert text.count('Visible = False')==8
print('Seven learning fields visible; eight legacy administration fields preserved but hidden')
