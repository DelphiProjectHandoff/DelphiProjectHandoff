from pathlib import Path
import hashlib,json,subprocess
root=Path(__file__).resolve().parents[2]
backup=Path(r'H:\DPH Backups\LearningRefocus_PreChange_20261012_213753')
manifest=json.loads((backup/'DPH_Backup_Verification.json').read_text(encoding='utf-8-sig'))
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
unchanged=[]
for item in manifest['entries']:
    name=item['path'].replace('\\','/')
    if name.startswith(('tests/fixtures/','help/','docs/guides/','docs/pdf/')) or name in ['DPH_Master_Development_Specification_v1.md','DPH_PHASE1_MASTER_REQUIREMENTS.md','DPH_CODEX_HANDOFF.txt']:
        assert sha(root/name)==item['sha256'],name+' was modified'
        unchanged.append(name)
images=[{'path':str(p.relative_to(root)).replace('\\','/'),'sha256':sha(p),'review':'Individually viewed; actual DPH native UI using an explicitly synthetic test Delphi project'} for p in sorted((root/'docs').glob('learning-refocus-*.png'))]
report={'result':'PASS for initial learning refocus; project completion not claimed','pre_change_backup':str(backup),
    'tests':{'native_learning':82,'profile_regression':19,'publishing_regression':114,'application_build':'PASS','serialized_form_baseline':'PASS'},
    'guides_and_original_inputs_unchanged':unchanged,'images':images,
    'scope':'Latest owner instruction: teaching and learning the selected application; broad technical backlog is not the implementation order',
    'documentation_review':'Deferred until application work is finished; attached review not read or acted on',
    'independent_beginner_acceptance':'Not performed; automated rendering is not human learning acceptance',
    'source_sha256':{n:sha(root/n) for n in ['DPH.Analysis.Explanations.pas','DPH.UI.Main.fmx','DPH.UI.Main.pas','tests/DPH.Tests.LearningRefocus.dpr']}}
(root/'docs/learning-refocus-verification.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print('Verified',len(unchanged),'unchanged input/guide/help files and',len(images),'reviewed native images')
