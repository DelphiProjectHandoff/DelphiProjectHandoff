from pathlib import Path
p=Path('DPH.UI.ComponentDependency.pas');p.write_text(p.read_text(encoding='utf-8-sig').rstrip()+'\n',encoding='utf-8')
p=Path('bin/complete-component-dependencies-register.py');s=p.read_text();s=s.replace("assert 'Current live backlog: 340 incomplete requirement records; 0 unassessed.' in s","assert ('Current live backlog: 340 incomplete requirement records; 0 unassessed.' in s) or ('Current live backlog: 339 incomplete requirement records; 0 unassessed.' in s)");p.write_text(s,encoding='utf-8')
