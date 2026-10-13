from pathlib import Path
p=Path('bin/DPH.Tests.Publishing.Formats.dpr');s=p.read_text(encoding='utf-8');p.write_text(s,encoding='utf-8-sig')
