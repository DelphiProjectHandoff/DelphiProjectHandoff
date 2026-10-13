from pathlib import Path
import re
root=Path(__file__).resolve().parents[2];p=root/'DPH.UI.ActionPurpose.fmx';raw=p.read_bytes();text=raw.decode('utf-8-sig').replace('\r\n','\n')
text=text.replace("Caption = 'Action and business purpose record'","Caption = 'Explain a button, field or task'",1)
text=text.replace("Text = 'Document the action or task name, business purpose, steps, expected outcome and evidence with a named contributor. Apply prepares a Knowledge draft; click Save there, then review explicitly. Unknown permissions and outcomes must remain explicit. Do not enter credentials.'", "Text = 'Explain what this action helps a user accomplish, how to use it, and how to recognize a correct result. Name the person supplying the explanation. Apply opens a saved-explanation draft: click Save there to keep it, then ask someone who knows the application to review it.'",1)
text=text.replace("Text = 'Apply to Knowledge draft'","Text = 'Apply explanation draft'",1)
text=re.sub(r'(object Profile_(?:action_id|target|target_key)_Row: TLayout\n)',r'\1      Visible = False\n',text)
text=re.sub(r'(object Profile_(\w+)_Row: TLayout\n.*?Position.Y = )(\d+)',lambda m:m[1]+str(max(0,int(m[3])-366)),text,flags=re.S)
p.write_bytes((b'\xef\xbb\xbf' if raw.startswith(b'\xef\xbb\xbf') else b'')+text.replace('\n','\r\n').encode('utf-8'))
