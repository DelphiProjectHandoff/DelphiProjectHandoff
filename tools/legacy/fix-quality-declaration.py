from pathlib import Path
p=Path('DPH.UI.Main.pas');s=p.read_text();s=s.replace('    procedure DataQualityImportClick(Sender:TObject);\n','',1).replace('    procedure DataQualityFilterChange(Sender:TObject);','    procedure DataQualityImportClick(Sender:TObject);\n    procedure DataQualityFilterChange(Sender:TObject);',1);p.write_text(s,encoding='utf-8')
