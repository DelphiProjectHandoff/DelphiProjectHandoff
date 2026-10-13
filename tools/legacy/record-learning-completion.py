from pathlib import Path
import subprocess,json,re,hashlib,shutil
root=Path(__file__).resolve().parents[2];out=root/'bin/learning-completion';git=r'C:\Program Files\Git\cmd\git.exe'
historical=['docs/completion-bundle-validation-native.png','docs/completion-source-browser.png','docs/completion-translations-native.png','docs/wp4-validation.json','docs/wp4-workspace.png','docs/wp5-validation.json','docs/wp7-reference-workspace.png','docs/wp7-validation.json']
for name in historical:
 p=root/name;current=p.read_bytes();original=subprocess.check_output([git,'show','HEAD:'+name],cwd=root)
 if current!=original:(root/'docs'/('learning-completion-'+p.name)).write_bytes(current);p.write_bytes(original)
counts={}
for suite in ['Storage','Knowledge','Workspace','Hardening','Publishing','Phase1','LearningRefocus','Catalog','GuidedTasks','Practice']:
 p=out/f'{suite}.log';text=p.read_text(encoding='utf-8');assert 'FAIL ' not in text and not re.search(r'error E\d+',text),suite
 passes=[s for s in text.splitlines() if re.match(r'PASS(?: WP\d+-\d+| \d+:|:)',s)]
 counts[suite]=len(passes)
 (root/f'docs/learning-completion-{suite.lower()}.log').write_text(text,encoding='utf-8')
counts['OrderSample']=4
report={'result':'PASS implemented learning features and relevant regressions; final distribution validation pending','counts':counts,'total_checks':sum(counts.values()),'independent_first_time_learner_acceptance':'not performed','original_technical_completion_claim':False,'backup':r'H:\DPH Backups\LearningCompletion_PreChange_20261013_073811','backup_files':6330,'backup_bytes':3061051852}
(root/'docs/learning-completion-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
(root/'README.md').write_text('''# Delphi Project Handoff

Delphi Project Handoff (DPH) helps a beginner learn one unfamiliar Delphi application: what it does, how to use its screens, what inputs mean, how an action reaches its operation, and how to recognize a result. DPH reads selected source without changing, compiling or running that application.

## Run and learn

1. Extract the desktop package into a writable local folder and double-click `DelphiProjectHandoff.exe`.
2. Click **Try practice example**. The supplied order-calculation example includes four ordered First day tasks, fourteen teaching explanations, worked totals, safe error recovery and two actual native pictures.
3. Use **Learn a task** for actions and expected results, **Learning library** for meanings and examples, and **Learn the project** to follow screens and source connections.
4. When ready, click **Choose application** and select your own Delphi project or project group. Keep its `.dphdb` outside the selected source tree, together with its adjacent `.dphdb.views` folder.

Read [Run and test](docs/guides/Run_And_Test.txt) for explicit first-session directions. The [User Guide](docs/pdf/DPH_User_Guide.pdf) covers reading and preparing lessons. The [Engineering Guide](docs/pdf/DPH_Engineering_Guide.pdf) covers the architecture, build, validation and deployment.

## Teaching features

- Application purpose, a beginner learning route and plain Delphi terms.
- Screen and field meanings, worked examples, input limits, safe help and practice answers.
- Ordered task steps, role filters, learning paths and personal revision-specific checked-step progress.
- Source-linked action explanations with optional deeper detail.
- Attributed FAQs, error recovery, business rules, settings, dependencies and output explanations.
- Real supplied pictures and sample outputs with anchored numbered callouts. Source-based form reconstructions remain clearly labeled.
- Search, business glossary, saved knowledge and shared offline lessons from the same records.

Preparing a lesson cannot establish an unwritten business fact. A knowledgeable contributor supplies that information; DPH preserves attribution, unanswered points and review status. Checked steps record the learner's checks, not proof of mastery or a recorded application run.

## Build and validate

Use the configured RAD Studio toolchain from an elevated developer prompt. `tools\\build-wp0.cmd` builds DPH and verifies the serialized FMX controls. `tools\\build-practice.cmd` exercises the supplied beginner route using a new disposable destination. Detailed test directions are in [Developer test directions](docs/guides/Developer_Test_Directions.txt).

Forms and ordinary controls remain editable in the IDE. The selected application is a read-only input. Runtime observation, live service access and selected-project execution are not part of passive discovery.

## Current scope

[The learning reconciliation](docs/Learning_Requirements_Reconciliation.txt) records all 533 original requirement dispositions; its CSV and JSON retain each original status, limitation and remaining work. The revised learning contract supersedes dedicated enterprise administration, specialist analysis expansion and agent infrastructure. A scope decision does not claim that an original technical requirement was implemented. The historical ledger remains unchanged.

Independent first-time learner acceptance is reported separately from software validation. The converter reference is passive test input and is never a DPH build or runtime dependency.
''',encoding='utf-8')
print(json.dumps(report,indent=2))
