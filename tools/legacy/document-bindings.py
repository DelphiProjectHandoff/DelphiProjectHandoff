from pathlib import Path
r=Path.cwd();p=r/'tools/build-guides.py';s=p.read_text(encoding='utf-8-sig')
user=[
'Open the project or cached database, then choose Database connections in the upper-right page selector. Choose bound control in the kind filter to find data-aware controls, persistent field for captured field components, or data source for the intermediary between a control and dataset. Clear the text filter before changing the kind if no rows appear. Field names and component paths are searchable.',
'Select a bound control. The labeled details memo begins with DATASET AND SCREEN BINDINGS and lists its captured DataSource and DataField references. Select Target via DataSource in the reference selector and click Follow reference to inspect the data source, then follow DataSet to its dataset and Connection to the captured connection. To go straight to a captured persistent field, select Target via DataField and click Follow reference. A field name can refer to a calculated or lookup field; it does not prove a live database column.',
'Select a persistent field to see its captured FieldName, FieldKind, Required, ReadOnly, Size and Precision when serialized. Its DataSet reference identifies the serialized owning dataset, and Used by references return to bound controls. Choose a reference in the selector before clicking Follow reference; use the horizontal toolbar scrollbar when the command is outside the visible area. The details memo scrolls independently.',
'For FMX TLinkControlToField, DPH recognizes the serialized DataSource, FieldName and Control properties. Follow DataSource to TBindSourceDB and DataSet, FieldName to a unique persistent field, or Control to the captured visual target. This explains stored component references without creating any target component or executing LiveBindings. General expression-based bindings, dynamically created fields, runtime assignments, uncaptured inherited values and missing external targets remain unknown.',
'Duplicate field declarations or ambiguous data-source targets are reported without choosing one. A missing persistent field remains unresolved even if a runtime dataset might create it. Native controls are editable in the IDE. Run and test directions are in docs/guides/Dataset_Bindings_Run_and_Test.txt. The screen-data inventory is evidence for the selected captured revision, not a live database connection or an assertion about production data.'
]
engineering=[
'TDPHDatabaseConnections.Inspect extends the existing captured form inventory with known persistent TField classes, data-aware control property signals, TBindSourceDB and visual controls explicitly referenced by serialized binding Control properties. Only required reference/configuration metadata enters the projection; captions, credentials and connection values retain existing redaction. The source and persisted workspace remain unchanged.',
'Persistent field DataSet ownership is derived from its exact serialized parent path and resolved only to a unique dataset. Explicit LookupDataSet references remain distinct from ownership. ResolveFields indexes captured IDs and dataset-scoped case-insensitive FieldName values, then joins resolved control DataSource or BindSource, intermediary DataSet and persistent field identity. Multiple fields, incomplete or competing chains receive no target ID. Fields absent from captured declarations are not invented. Every property link retains its original property line and byte range; binary form evidence has byte positions rather than invented text lines.',
'The existing Follow reference workflow navigates outgoing and reverse references, resets filters and finds exact IDs across 250-row pages. Serialized kind choices add bound control, persistent field and binding control target. Binding explanations and field metadata appear before lengthy engine qualifications. No runtime controls, helper unit, target component loading or storage migration was introduced. Existing engine derivation remains unchanged.',
'The installed RAD Studio Data.Bind.Components source and official TLinkControlToField documentation establish the published DataSource, FieldName and Control contract. Data.Bind.DBScope supplies TBindSourceDB. Support describes serialized lexical candidates; it does not evaluate LiveBindings expressions or instantiate the target. General expression/factory/runtime/inherited behavior remains qualified rather than promoted to confirmed static binding.',
'Run tools/build-dataset-bindings.cmd elevated for 92 checks. Real text/binary DFM and FMX fixtures cover VCL and FMX field chains, parent ownership, reverse links, duplicate fields, missing/nil sources, lookup datasets, exact property evidence, native kind/text filters, follow navigation, compact layout, SQLite reopening and unchanged source/catalog. Connection and engine regressions each pass 66 checks. tools/build-wp0.cmd builds the actual application and verifies FMX resource bindings. Fixtures use fixed ignored bin/dataset-bindings-validation.'
]
at=s.index('user_order = [');s=s[:at]+'USER.append(('+repr('Follow dataset and screen field bindings')+', '+repr(user)+'))\nENGINEERING.append(('+repr('Resolve captured dataset and field bindings')+', '+repr(engineering)+'))\nfor chapters in (USER, ENGINEERING):\n for index, (heading, paragraphs) in enumerate(chapters):\n  chapters[index]=(heading,[p.replace("327 requirement records remain incomplete","326 requirement records remain incomplete") for p in paragraphs])\n\n'+s[at:]
at=s.index('user_order = [');s=s[:at]+s[at:].replace("'Define table and column business meanings',", "'Define table and column business meanings', 'Follow dataset and screen field bindings',",1)
s=s.replace("'guide_version': 24","'guide_version': 25");p.write_text(s,encoding='utf-8')
p=r/'README.md';s=p.read_text();s+='\nRequirement 05.11: Database connections follows captured dataset/data-source/control/persistent-field chains, including serialized FMX DataSource/FieldName/Control references. Duplicate, missing and runtime-only fields remain unresolved. See docs/guides/Dataset_Bindings_Run_and_Test.txt.\n';p.write_text(s)
p=r/'help/index.html';s=p.read_text(encoding='utf-8-sig').replace('</main>','<section id="dataset-bindings"><h2>Follow dataset and screen field bindings</h2><p>'+('</p><p>'.join(user))+'</p></section>\n</main>',1);p.write_text(s,encoding='utf-8')
directions=r'''DPH DATASET AND SCREEN FIELD BINDINGS RUN AND TEST
Last changed 12 October 2026

START THE UPDATED APPLICATION
1. Save or discard any authored draft before closing DPH.
2. Start C:\New Delphi Projects\Delphi Project Handoff\bin\Win32\Debug\DelphiProjectHandoff.exe.
3. Click Attach project and choose the intended Delphi project, or Open cache and
   choose its existing .dphdb. DPH refuses its own project/database.
4. Wait for the capture to open. In the upper-right page selector choose
   Database connections. Click the kind selector and choose bound control.
5. Clear the text filter. Select a control in the list. Read DATASET AND SCREEN
   BINDINGS in the labeled details memo below the list.
6. In the reference selector choose Target via DataSource; click Follow reference.
   If commands are outside the visible area, scroll the toolbar horizontally.
7. On the data-source row choose Target via DataSet and click Follow reference.
   On the dataset choose Target via Connection to inspect the captured connection.
8. To inspect a field directly, return to the bound control and select Target via
   DataField, then Follow reference. The persistent field shows its serialized
   FieldName and optional kind, required/read-only, size and precision metadata.
9. Use Used by references to return from a field to its control. The kind selector
   has persistent field and binding control target choices. Text search matches
   captured names, field metadata and references. Clear it to restore all rows.
10. FMX TLinkControlToField uses Target via DataSource, FieldName and Control.
    Follow DataSource to TBindSourceDB, then DataSet. FieldName opens a uniquely
    captured persistent field; Control opens the serialized visual target.
11. Duplicate fields, missing targets and runtime-created fields remain unresolved
    and have no navigable field target. Read the qualification rather than treating
    an empty result as proof that the application has no database fields.

CONTROLLED PRACTICE AND DEVELOPER TESTS
1. Open Windows Start, type cmd, right-click Command Prompt and select
   Run as administrator. RAD Studio needs access to its environment settings.
2. Enter exactly:
   cd /d "C:\New Delphi Projects\Delphi Project Handoff"
3. Enter:
   tools\build-dataset-bindings.cmd
4. Expected: Dataset bindings validation passed: 92 checks. Exit code must be 0.
   The suite uses the fixed ignored bin\dataset-bindings-validation folder and
   controlled text/binary DFM and FMX files. No SQL or target application runs.
5. Run shared regressions:
   tools\build-database-connections.cmd
   tools\build-database-engines.cmd
   Expected: 66 checks pass in each suite.
6. Build the actual app and verify its serialized controls:
   tools\build-wp0.cmd
   Expected: PASS WP0-TEST: FMX resource instantiation and component binding.
7. Logs and evidence for this batch are under docs\phase1-dataset-bindings-*.

LIMITS
Captured references are lexical candidates, not runtime binding proof. A persistent
field can be calculated or a lookup; it is not automatically a physical SQL column.
General FMX binding expressions, runtime assignments, factories, inherited defaults
not present in the captured resource and dynamic fields remain unknown. No target
class, driver, SQL or server is opened. Original source files remain read only.
'''
(r/'docs/guides/Dataset_Bindings_Run_and_Test.txt').write_text(directions,encoding='utf-8')
s=(r/'bin/verify-database-dictionary-guides.py').read_text().replace('==24','==25').replace('Define table and column business meanings','Follow dataset and screen field bindings').replace('Maintain attributed schema dictionaries','Resolve captured dataset and field bindings').replace('database-dictionary-guide-check','dataset-bindings-guide-check');(r/'bin/verify-dataset-bindings-guides.py').write_text(s)
for name in ['DPH.Workspace.DatabaseConnections.pas','DPH.UI.Main.fmx','tests/DPH.Tests.DatasetBindings.dpr','tools/build-dataset-bindings.cmd']:
 p=r/name;p.write_bytes(p.read_bytes().replace(b'\r\n',b'\n').replace(b'\n',b'\r\n'))
print('Dataset binding instructions and guide chapters authored')
