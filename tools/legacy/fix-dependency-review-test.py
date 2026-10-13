from pathlib import Path
p=Path('tests/DPH.Tests.ComponentDependencies.dpr');s=p.read_text();s=s.replace("(Row.GetValue<string>('state')='verified') and (Row.GetValue<string>('structured_json')=RecordValue.ToJSON)","(Row.GetValue<string>('state')='verified') and (Row.GetValue<string>('body')=TDPHComponentDependency.Body(RecordValue))");p.write_text(s,encoding='utf-8')
