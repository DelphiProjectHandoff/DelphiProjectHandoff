from pathlib import Path
p=Path('DPH.Workspace.Model.pas');s=p.read_text(encoding='utf-8-sig');s=s.replace('class function TDPHWorkspaceView.DescribeBusinessProcess(ARow:TJSONObject):string;\nbegin','class function TDPHWorkspaceView.DescribeBusinessProcess(ARow:TJSONObject):string;\nvar History:TJSONArray;Value:TJSONValue;\nbegin');p.write_text(s,encoding='utf-8')
