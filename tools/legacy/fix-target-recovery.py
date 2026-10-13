from pathlib import Path
p=Path('DPH.UI.Main.pas');s=p.read_text();line='    procedure DataQualityImportClick(Sender:TObject);\n';a=s.index(line);b=s.index(line,a+len(line));s=s[:b]+s[b+len(line):]
marker='procedure TDPHMainForm.DataQualityImportClick';a=s.index(marker);b=s.index(marker,a+len(marker));end=s.index('procedure TDPHMainForm.DataQualityFilterChange',b);s=s[:b]+s[end:];p.write_text(s,encoding='utf-8')
