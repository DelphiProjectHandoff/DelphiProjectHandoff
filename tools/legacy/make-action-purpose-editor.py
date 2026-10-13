from pathlib import Path
r=Path.cwd()
keys=['action_id','target','target_key','action_name','screen','trigger','purpose','preconditions','steps','outcome','evidence','exceptions']
labels=['Stable action identity','Captured target or project task','Captured object key','Action or task name','Screen and user role','User trigger','Business purpose','Prerequisites and permissions','Numbered user steps','Expected business outcome','Evidence and remaining unknowns','Failures and recovery']
pas=(r/'DPH.UI.ComponentDependency.pas').read_text(encoding='utf-8-sig').replace('ComponentDependency','ActionPurpose')
start=pas.index('    Profile_class_name_Row:');end=pas.index('    procedure ApplyProfileClick',start)
pas=pas[:start]+''.join(f'    Profile_{k}_Row: TLayout;\n    Profile_{k}_Label: TLabel;\n    Profile_{k}: TMemo;\n' for k in keys)+pas[end:]
(r/'DPH.UI.ActionPurpose.pas').write_text(pas,encoding='utf-8')
fmx=(r/'DPH.UI.ComponentDependency.fmx').read_text(encoding='utf-8-sig').replace('ComponentDependency','ActionPurpose')
fmx=fmx.replace("Caption = 'Component dependency'","Caption = 'Action and business purpose'")
start=fmx.index('    object Profile_class_name_Row:')
fmx=fmx[:start]
fmx=fmx.replace("Text = 'Record package, vendor, version and support claims with a named contributor. Evidence is required; blank optional fields stay unknown. Apply prepares a draft; Save on Knowledge persists it.'", "Text = 'Record the purpose, steps and expected outcome with a named contributor and evidence. Apply prepares a draft; Save on Knowledge persists it. Business claims require explicit review.'")
for i,(k,label) in enumerate(zip(keys,labels)):
 readonly='        ReadOnly = True\n' if i<3 else ''
 fmx+=f'''    object Profile_{k}_Row: TLayout
      Position.Y = {i*122}
      Width = 780
      Height = 122
      Anchors = [akLeft, akTop, akRight]
      object Profile_{k}_Label: TLabel
        Align = Top
        Height = 28
        Margins.Left = 12
        Text = '{label}'
      end
      object Profile_{k}: TMemo
        Align = Client
        Margins.Left = 12
        Margins.Right = 12
        Margins.Bottom = 10
        WordWrap = True
{readonly}        ShowScrollBars = True
        StyledSettings = []
        TextSettings.Font.Size = 16
      end
    end
'''
fmx+='  end\nend\n';(r/'DPH.UI.ActionPurpose.fmx').write_text(fmx,encoding='utf-8')
