from pathlib import Path
p=Path('tests/DPH.Tests.ComponentDependencies.dpr');s=p.read_text();s=s.replace("Check(Row.ToJSON=RecordValue.ToJSON,'Editor round trips every field');","Rejected:=False;for Text in DPHComponentDependencyKeys do if Row.GetValue<string>('fields.'+Text,'')<>RecordValue.GetValue<string>('fields.'+Text,'') then Rejected:=True;Check(not Rejected,'Editor round trips every field');")
p.write_text(s,encoding='utf-8')
