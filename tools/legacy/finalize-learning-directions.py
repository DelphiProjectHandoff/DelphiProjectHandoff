from pathlib import Path
import shutil,hashlib,json
root=Path(__file__).resolve().parents[2];guides=root/'docs/guides'
# Preserve older feature-specific instructions. The package explicitly selects current guides.
older=[p.name for p in guides.glob('*.txt') if p.name not in ['Run_And_Test.txt','Developer_Test_Directions.txt','Workspace_Operations.txt']]
directions='''RUN AND TEST DELPHI PROJECT HANDOFF

START THE SUPPLIED DESKTOP PACKAGE
1. Extract the ZIP file into a local folder where you can save files.
2. Open that extracted folder in File Explorer.
3. Double-click DelphiProjectHandoff.exe. Getting started should appear.
4. Keep the executable, loader, migrations, help and docs together.

OPEN AN APPLICATION
5. Click Choose application at the top left.
6. Select the intended Delphi .dproj or .dpr, or its .groupproj group.
7. Save its proposed .dphdb in Databases, outside the selected source folder.
8. Wait for Learn the project to open. Read Start here, then Screens and actions.
   If lessons already exist, use Open saved lessons and select their .dphdb.
   Keep the adjacent .dphdb.views folder with the database.

CHECK AN ACTUAL EXPLANATION
9. Follow a screen control or event link into Explain. Read the selection role.
10. Follow its responding operation and read its purpose and next connections.
11. Read Choices and stopping points if present. Identify an actual condition.
12. Use Back to return. Keep optional source details closed until you need them.

PREPARE AND CHECK A TASK
13. Click Prepare lessons, then Prepare task instructions.
14. Enter your contributor name, task name, purpose and prerequisites.
15. Enter its overall result, recovery guidance and practice exercise.
16. Scroll to the steps. Click New step, enter an action and expected result,
    then Keep step. Add a second step in the same way.
17. Click Save task. Learn a task should open at Step 1 of 2.
18. Click Next step, Previous step and Start again. Check each displayed action
    and expected result against what you entered. Scroll the instruction area.
19. Close and reopen DPH, use Open saved lessons, and check the saved task.

CHECK A SAVED ANSWER AND SHARE
20. In Prepare lessons choose Author questions. Select a question, then Record
    author answer. Enter the contributor and reply after Answer:, then Save.
21. In Learn the project choose Questions and answers and find that reply.
22. In Prepare lessons choose Publish, then Share lessons. Give a NEW folder
    name outside the selected application's source. Wait, then Preview lessons.
23. Open learning.html in the edition folder. Check the task, answer and object
    link. Keep the whole edition folder together when sharing it.

EXPECTED RESULT
You can explain one task, its prerequisites and expected result, follow one
actual screen action into its operation, and read the same saved instruction
in the exported learning edition. DPH does not perform the task in the selected
application. Use owner-approved example data if separately practicing there.

IF SOMETHING IS UNAVAILABLE
No task or purpose supplied means a contributor must add it. Some code could
not be explained means the preparer must check missing files or source settings.
If embedded pages fail, check Microsoft WebView2 Runtime and use available
native text or the exported learning.html. Never delete the last readable
lesson database as a first troubleshooting step.

The complete procedures and illustrations are in DPH_User_Guide.docx and its
PDF companion. Source-build and automated-check directions are in the
Engineering Guide and Developer_Test_Directions.txt.
'''
(guides/'Run_And_Test.txt').write_text(directions,encoding='utf-8')
(guides/'Developer_Test_Directions.txt').write_text('''DEVELOPER BUILD AND CHECK DIRECTIONS

Open an elevated Windows Command Prompt and change to the source root that
contains DelphiProjectHandoff.dproj. Run the following commands in order:

tools\\build-wp0.cmd
tools\\build-learning-refocus.cmd
tools\\build-guided-tasks.cmd "%CD%\\bin\\fresh-task-check\\fixture.dphdb"
tools\\build-phase1.cmd
tools\\build-wp6.cmd

Use a new disposable folder name if fresh-task-check already exists. Do not
reuse an owner database for the task test. Each suite must end with PASS and a
zero process exit code. Run the relevant analyzer/storage suites when changing
those contracts. These checks do not replace a first-time learner exercise.

To run this source build:
bin\\Win32\\Debug\\DelphiProjectHandoff.exe

Keep WebView2Loader.dll beside the executable and migrations in the source root.
Use Debug and Win32 in RAD Studio. The User Guide describes deployed operation.
''',encoding='utf-8')
(guides/'Workspace_Operations.txt').write_text('''FIND YOUR WAY AROUND DELPHI PROJECT HANDOFF

Use the top-right page selector for Learn the project, Learn a task, Explain,
Form designs, Screenshots, Graphs, Business glossary, Search project and Saved
explanations. Getting started returns to introductory directions.

Prepare lessons contains the application description, task instructions and
other lesson material. Source reading settings start collapsed.

Explain shows the selected object. Double-click an object in the left list to
open it. Selection details labels the right pane. Drag dividers to resize panes.
Scroll command strips horizontally and instruction areas vertically when needed.

Save task stores prepared instructions and opens their reader. Profile, purpose
and glossary dialogs first Apply to a draft; click Save in Saved explanations
to keep those records. Named review is a separate decision.

Read Run_And_Test.txt for a complete first session and repeatable checks.
''',encoding='utf-8')
for kind in ['User','Engineering']:
 shutil.copyfile(root/f'bin/learning-guides/{kind.lower()}-render/DPH_{kind}_Guide.pdf',root/f'docs/pdf/DPH_{kind}_Guide.pdf')
bad=root/'docs/learning-guides-getting-started.png'
bad.unlink(missing_ok=True)
report={'older_instructions_preserved_in_repository_and_excluded_from_package':older,'current_directions':['Run_And_Test.txt','Developer_Test_Directions.txt','Workspace_Operations.txt'],
 'translation_helper_source':'Pinned independent reference assets/translation-selector.js; copied per global directive 22',
 'translation_helper_sha256':hashlib.sha256((root/'help/assets/translation-selector.js').read_bytes()).hexdigest()}
(root/'docs/learning-guides-cleanup.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print('Wrote three current learning/build direction files; preserved older files; copied final PDFs.')
