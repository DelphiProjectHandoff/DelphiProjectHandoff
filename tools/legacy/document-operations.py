exec((__import__('pathlib').Path(__file__).parent/'implement-operations.py').read_text(encoding='utf-8').split("s=read('DPH.Analysis.Symbols.pas')")[0])
import json,html
user=['Choose Database connections in the upper-right page selector, then choose database operation in its kind filter. Clear the text filter to see all captured requests; enter Post, Delete, read, insert or a calling routine name to narrow the list. Select a row. The evidence memo begins with its operation kind, requested effect and evidence basis. Operation requests are source candidates; DPH does not run the selected application or connect to its database.',
'Open, Refresh, navigation and search methods are read candidates. Append and Insert prepare a new record buffer; Edit prepares an update. AppendRecord and InsertRecord request insertion. Post submits a pending insert or edit, depending on the dataset state; cached updates can defer persistence. Delete requests deletion of the current record. ApplyUpdates can submit mixed pending writes. Cancel and CancelUpdates concern pending edits or cached changes. None of these calls proves transaction commit or rollback.',
'Literal SELECT, INSERT, UPDATE and DELETE text is classified separately from calls. Configuring SQL does not execute it. Joined statements retain their lexical family even when table and column binding is unsupported. Dynamic SQL, mixed batches and unsupported prefixes remain unknown. SQL values are omitted from this inventory. Inspect approved source locally to understand parameters and context.',
'Select Target via DataSet in the reference selector and click Follow reference to inspect the exact captured receiver. A dataset lists reverse operation references in the same selector. Click Source to open the original location only after attaching unchanged source; detached, changed and historical evidence refuses navigation. Use the horizontal toolbar scrollbar to reach Follow reference and Source when they are outside the visible area. Scroll within the evidence memo for engine evidence and unknowns. Full reassessment upgrades an older capture to the new analyzer. Explicit run and test directions are in docs/guides/Database_Operations_Run_and_Test.txt.']
eng=['TDPHSemanticAnalyzer.RoutineFacts emits database_operation relations for recognized methods on declared framework datasets or captured descendants. Receiver resolution and imported framework identity are checked; a local class shadowing TFDQuery and ordinary Delete methods are excluded. Captured inheritance is bounded to 32 steps. Within-with calls, factories, aliases, indexed receivers, unsupported providers and runtime dispatch remain unproved. DPHSemanticVersion DPH-WP3-13 invalidates older semantic caches.',
'TDPHDatabaseConnections.AppendOperations projects API calls, static_sql and dynamic_sql relations into existing database inventory rows. It preserves generation, condition, source SHA256 and line/byte range. Semantic component_field relationships connect operation receivers to serialized components by exact source location; ambiguous locations never choose an arbitrary target. Recognized custom dataset declarations receive their own navigable receiver row. SQL literal values are omitted. Single lexical CRUD families can be retained for complex SQL without inventing table or column bindings; dynamic or mixed batches remain unknown.',
'Effects distinguish record-buffer preparation, posting, cached-update application, deletion requests, SQL configuration and execution requests. Engine evidence follows captured receiver references. The database operation kind filter and Source button are serialized in DPH.UI.Main.fmx. Existing pagination, reverse references and source hash guards are reused. No helper unit, runtime control, storage migration, target execution or driver loading is introduced.',
'Run tools/build-database-operations.cmd elevated for 232 checks using the actual analyzer, persisted/reopened SQLite workspace and native FMX form. Fixtures cover CRUD requests, local/custom datasets, framework-name shadowing, SQL joins and mixed/dynamic SQL, operation effects, exact receiver/source identity, redaction, reverse navigation, detached-source refusal, compact layout and unchanged source/catalog. Binding regression passes 92, engine regression 66 and semantic regression 134 checks. tools/build-wp0.cmd builds the real application and verifies its FMX resource. Fixtures stay in fixed ignored bin/database-operations-validation.']
s=read('tools/build-guides.py');at=s.index('user_order = [');s=s[:at]+f"USER.append(('Inspect database read and write operations', {user!r}))\nENGINEERING.append(('Recognize captured database operation requests', {eng!r}))\nfor chapters in (USER, ENGINEERING):\n for index, (heading, paragraphs) in enumerate(chapters):\n  chapters[index]=(heading,[p.replace('326 requirement records remain incomplete','325 requirement records remain incomplete') for p in paragraphs])\n\n"+s[at:]
s=s.replace("'Follow dataset and screen field bindings',", "'Follow dataset and screen field bindings', 'Inspect database read and write operations',",1).replace("'guide_version': 25","'guide_version': 26")
write('tools/build-guides.py',s)
p=root/'README.md';p.write_text(read('README.md')+'\nRequirement 05.12: Database connections now inventories source dataset CRUD requests and captured SQL families, with effects, exact receiver references and hash-checked Source navigation. Preparation, posting, cached writes and configured SQL are distinguished from execution and commit. See docs/guides/Database_Operations_Run_and_Test.txt.\n',encoding='utf-8')
p=root/'help/index.html';s=read('help/index.html');section='<section id="database-operations"><h2>Inspect database read and write operations</h2>'+''.join('<p>'+html.escape(x)+'</p>' for x in user)+'</section>\n';at=s.index('<section id="dataset-bindings">');p.write_text(s[:at]+section+s[at:],encoding='utf-8')
directions=r'''DATABASE OPERATIONS RUN AND TEST
Last changed: 12 October 2026

1. In File Explorer open:
   C:\New Delphi Projects\Delphi Project Handoff\bin\Win32\Debug
   Double-click DelphiProjectHandoff.exe. The app opens maximized.
2. Click Attach project. Select the application's .dproj, .dpr or .groupproj.
   Save its proposed .dphdb in DPH's Databases folder. DPH rejects itself.
   Alternatively click Open cache and select an existing .dphdb. For old
   captures, attach unchanged source and click Full reassessment to refresh
   operation evidence. Source code and SQL are not executed by DPH.
3. Choose Database connections from the upper-right page selector.
   In the page's first dropdown choose database operation. Clear the adjacent
   text filter. Select a row in the list below the filter toolbar.
4. Read the DATABASE OPERATION section at the start of the evidence memo.
   Enter Delete, Post, read, insert, update or a routine name in the filter
   to find related requests. Next page shows more than 250 matching rows;
   First page returns to the beginning. An empty filter result is not proof
   that no database behavior exists.
5. In the reference dropdown choose Target via DataSet, then click Follow
   reference. The receiver's reverse references return to operation rows.
   Use the horizontal scrollbar beneath the page toolbar to reach commands
   outside the visible area. The evidence memo scrolls separately.
6. Select an operation and click Source at the right end of that toolbar.
   Attach unchanged source first. Detached, changed, out-of-root, historical
   and binary evidence does not permit text navigation. Read the refusal
   message in the evidence memo. Never apply old ranges to changed source.

READ THE EFFECT CORRECTLY
Append/Insert prepare insertion; Edit prepares an update. Post requests
submission of the buffer, which may still be cached. Delete requests deletion
of the current record. ApplyUpdates may submit mixed changes. Cancel and
CancelUpdates do not prove database rollback. No call proves commit, success
or affected row count. Configured SQL is not execution evidence. Dynamic and
mixed SQL remain unknown. SQL families do not prove server validity or all
nested effects. Custom dispatch, runtime receivers and unsupported APIs need
approved source review. This page never displays SQL values or credentials.

REPEATABLE CONTROLLED CHECK
Open Windows Terminal as administrator. Choose a Command Prompt tab and run:
cd /d "C:\New Delphi Projects\Delphi Project Handoff"
tools\build-database-operations.cmd
Expected final result: Database operations validation passed: 232 checks.
This compiles only DPH's test harness and runs controlled local fixtures,
not the analyzed application or SQL. Evidence is saved to:
docs\phase1-database-operations-validation.json
The controlled fixture folder is bin\database-operations-validation.
Do not select its synthetic source as a real project.

REGRESSIONS
tools\build-dataset-bindings.cmd             expected 92 checks
tools\build-database-engines.cmd             expected 66 checks
tools\build-wp3.cmd
bin\Win32\Debug\DPH.Tests.Semantics.exe "%CD%"  expected 134 checks
tools\build-wp0.cmd                          expected PASS WP0-TEST

Guides: docs\guides\DPH_User_Guide.docx and DPH_Engineering_Guide.docx.
Companion PDFs: docs\pdf\DPH_User_Guide.pdf and DPH_Engineering_Guide.pdf.
'''
write('docs/guides/Database_Operations_Run_and_Test.txt',directions)
