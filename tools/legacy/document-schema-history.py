from pathlib import Path
r=Path.cwd();p=r/'tools/build-guides.py';s=p.read_text(encoding='utf-8-sig')
anchor='for chapters in (USER, ENGINEERING):'
# Insert immediately before final shared version/count normalization.
pos=s.rfind(anchor);assert pos>=0
chapters="""USER.append(('Inspect migration and schema-version history', [
'Start bin/Win32/Debug/DelphiProjectHandoff.exe and attach the application you intend to document, or open its captured database. In the upper-right page selector choose Database schema. In the leftmost kind selector choose migration. Keep the state selector at All to include readable script candidates and migration gaps. Enter part of a script filename or an explicit user_version assignment in the search box. Select a row.',
'A migration changes database structure or data between application versions. DPH shows each referenced captured SQL script as a candidate. The evidence memo begins with a filename order candidate, explicit target-version assignments, verification requests, applied status and source fingerprint. Leading numeric filename prefixes provide intended-order candidates within each directory. Equivalent numbers such as 001 and 1 produce an explicit conflict. File numbers and captured loader enumeration do not establish the order used by a migration runner.',
'SQLite user_version assignments with a supported nonnegative integer preserve their schema qualifier and statement line. Multiple assignments remain visible; DPH does not select a deployed winner. A query of user_version and SQLite schema_version are not promoted to an application target version. Other migration-framework version metadata and dynamic expressions remain unknown. Captured integrity_check, quick_check and foreign_key_check requests identify potential verification work; DPH does not run them and does not report a successful result.',
'Drag the command bar scrollbar right to reveal the relationship selector and Follow relationship. Choose a captured schema evidence link and click Follow relationship to inspect the script declaration or gap. To read a script, select its migration row and click Open source. Source opens only when the attached bytes still match the capture. A migration gap cites the Pascal loader of an unavailable script; no missing SQL is reconstructed. Clear filters and use First page or Next page for larger inventories.',
'Applied state remains unknown because source text is not a deployment ledger. Ask the maintainer to supply the intended migration framework, ordering rules, expected schema versions and recorded verification results. Save attributed explanations through Knowledge and review them against evidence. Full commands and a controlled practice project are in docs/guides/Schema_History_Run_and_Test.txt.'
]))
ENGINEERING.append(('Project captured migration and version evidence', [
'TDPHDatabaseSchema.Inspect appends migration evidence after ordinary schema identities and links are resolved. Existing schema IDs remain stable. Each captured readable SQL resource becomes a migration candidate; unavailable literal SQL loader targets become migration gaps citing the Pascal loader range and fingerprint. The existing bounded project inventory discovers referenced files only. No unrelated directory scan, migration runner, target database or target application executes.',
'Leading numeric filenames are order candidates scoped to the captured source directory. Leading zeros normalize only for conflict detection; original filename digits remain visible. Captured loader configures relationships retain their source, line, fingerprint and enumeration label. Neither filename nor lexical-loader order becomes deployment precedence. Schema evidence links retain exact row IDs and are limited to 250 per script, with total and omission counts.',
'The existing SQL lexer separates comments and literal contents. Supported top-level PRAGMA user_version assignments capture nonnegative 32-bit integer values through equals or parentheses and preserve explicit schema qualifiers. Queries, engine schema_version counters, unsupported expressions, nested procedure blocks and comments cannot become application-version assignments. Multiple assignments remain ordered evidence rather than a selected final version. SQLite reference: https://www.sqlite.org/pragma.html#pragma_user_version. Supported verification request spelling captures integrity_check, quick_check and foreign_key_check without execution or invented results.',
'Existing SQL bounds are 2 MiB characters, 100000 tokens and 10000 combined schema rows. Migration detail bounds are 250 displayed version assignments, 8000 characters of verification requests and 1000 loader entries, with explicit truncation. IDE-editable kind/state selectors, paging, evidence memo, source guards and relationship navigation are reused. The focused tools/build-schema-history.cmd suite exercises actual parsing, persisted reopening, numeric-prefix conflicts, missing sources, version/counter distinctions, nested blocks, redaction, limits, native filters and navigation. Shared schema, ER, stored-object and lineage regressions verify the same projection remains compatible.'
]))

"""
s=s[:pos]+chapters+s[pos:]
s=s.replace(".replace('323 requirement records remain incomplete','322 requirement records remain incomplete')", ".replace('323 requirement records remain incomplete','322 requirement records remain incomplete').replace('322 requirement records remain incomplete','321 requirement records remain incomplete')")
s=s.replace("'Trace inputs and destination candidates', 'Compare screen history", "'Trace inputs and destination candidates', 'Inspect migration and schema-version history', 'Compare screen history")
s=s.replace("'guide_version': 29", "'guide_version': 30");p.write_text(s,encoding='utf-8')
p=r/'README.md';s=p.read_text();s+='\nRequirement 05.16 adds referenced migration-script candidates, filename/loader order evidence, explicit SQLite application-version assignments, verification request evidence and missing-script gaps in Database schema. See docs/guides/Schema_History_Run_and_Test.txt. Deployed versions and verification outcomes remain unknown.\n';p.write_text(s,encoding='utf-8')
p=r/'help/index.html';s=p.read_text();text='<section><h2>Migration and schema-version history</h2><p>Choose Database schema, then migration in the kind selector. Select a referenced SQL script to inspect filename-order candidates, explicit application versions, verification requests and source fingerprints. Missing scripts remain migration gaps. Follow relationship opens captured schema evidence; Open source requires unchanged attached source. DPH does not run migrations or verification SQL, and applied state remains unknown. Read docs/guides/Schema_History_Run_and_Test.txt for explicit commands.</p></section>'
assert '</body>' in s;s=s.replace('</body>',text+'</body>');p.write_text(s,encoding='utf-8')
text='''DPH MIGRATION AND SCHEMA-VERSION HISTORY: RUN AND TEST
Last changed: 12 October 2026

RUN
1. Open File Explorer and go to:
   C:\\New Delphi Projects\\Delphi Project Handoff\\bin\\Win32\\Debug
2. Double-click DelphiProjectHandoff.exe.
3. Click Attach project. Select the application you intend to document using
   its .dproj, .dpr or .groupproj. Choose its database when prompted.
   To inspect an existing capture, click Open cache and select its .dphdb.
4. Choose Database schema in the upper-right page selector.
5. In the leftmost kind selector choose migration. Leave the state selector
   at All. Enter part of a script filename or user_version=number to search.
6. Select a script row. Read the labeled evidence memo below the list.
   Filename numbers and loader enumeration are ordering candidates only.
   Conflicting numbers remain explicit. No deployed winner is selected.
7. Drag the command bar horizontal scrollbar right to reveal the relationship
   selector. Select a captured schema evidence link and click Follow relationship.
8. To open unchanged script source, select its migration row and click Open source.
   A migration gap opens evidence for the Pascal loader of missing SQL.
   Detached or changed source refuses navigation with an explanation.
9. Use First page/Next page for inventories over 250 rows. Clear the search
   field and select All kinds to return to the complete schema evidence list.

INTERPRETATION
Only supported explicit SQLite user_version integer assignments are captured
as application-version candidates. Queries and engine schema_version counters
do not establish a target version. Multiple assignments retain their lines.
Other frameworks and dynamic expressions remain unknown.
Verification requests are captured spelling, not results. DPH never executes
the selected target, migration SQL, verification SQL, driver or server.
Applied state remains unknown; captured source is not a deployment ledger.
Record maintainer-supplied ordering/framework/verification explanations in
Knowledge with attribution and evidence. Do not infer results from filenames.

AUTOMATED CHECKS AND CONTROLLED PRACTICE
1. Open Windows Start, type Command Prompt, and choose Run as administrator.
2. Enter:
   cd /d "C:\\New Delphi Projects\\Delphi Project Handoff"
3. Enter:
   tools\\build-schema-history.cmd
   A PASS line per check and zero exit indicate success. Any FAIL or nonzero
   exit requires investigation. The suite uses fixed ignored controlled data
   under bin\\schema-history-validation; it does not execute SQL.
4. Build the actual application and check IDE resource bindings:
   tools\\build-wp0.cmd
5. For shared schema/ER/stored-object/lineage regressions, run:
   tools\\build-database-schema.cmd
   tools\\build-database-er.cmd
   tools\\build-database-stored-objects.cmd
   tools\\build-data-lineage.cmd
6. For practice after the focused test, attach:
   C:\\New Delphi Projects\\Delphi Project Handoff\\bin\\schema-history-validation\\source\\Schema.dpr
   Save a new practice database when prompted; avoid replacing a real project.
   Inspect 001_initial.sql and 1_conflict.sql to see order conflicts.
   Inspect 002_upgrade.sql for multiple explicit version assignments.
   Inspect missing.sql for an unavailable source gap.

EVIDENCE
docs/phase1-schema-history-validation.json and its companion .log record the
focused run. Native PaintTo images show real instantiated DPH controls using
controlled fixtures; they are not screenshots of an analyzed target app.
User and Engineering guides are in docs/guides with PDFs in docs/pdf.
'''
(r/'docs/guides/Schema_History_Run_and_Test.txt').write_text(text,encoding='utf-8')
verify=(r/'bin/verify-data-lineage-guides.py').read_text().replace("==29","==30").replace('Trace inputs and destination candidates','Inspect migration and schema-version history').replace('Connect source evidence into scoped lineage','Project captured migration and version evidence').replace('data-lineage-guide-check.json','schema-history-guide-check.json')
(r/'bin/verify-schema-history-guides.py').write_text(verify,encoding='utf-8')
