from pathlib import Path
r=Path.cwd();p=r/'tools/build-guides.py';s=p.read_text(encoding='utf-8-sig')
needle='USER_ORDER = ['
print('order marker',needle in s)
insert=s.index('for chapters in (USER, ENGINEERING):',s.index("ENGINEERING.append(('Trace captured transaction boundaries'"))
chapters='''USER.append(('Inspect field validation and transformations', [
'Open the intended project or cache and choose Database connections in the upper-right page selector. Choose data rule in its kind filter. Clear the text filter, then search for a field, handler, predicate, constraint or transformation expression. Select a row. The labeled evidence memo begins DATA VALIDATION AND TRANSFORMATION EVIDENCE and shows Input expression, Output expression, Constraint, Captured expression and conditional compilation context. Drag the divider below the list or scroll the memo for the full explanation.',
'Declared field constraints include captured Required, ReadOnly, Size, Precision, MinValue, MaxValue, CustomConstraint, DefaultExpression, error-message and edit-mask declarations. Numeric and constraint structure remains visible; literal contents are omitted. A declaration does not establish an inherited default or a successfully enforced rule. Default expressions are not evaluated. An omitted message or mask can be inspected through approved hash-checked Source.',
'Validation and conversion hooks include OnValidate, OnSetText, OnGetText, BeforePost and other recognized dataset or input events. Captured handler conditions, raises, early returns and assignment expressions provide technical rule candidates. Assignment rows identify the written expression and its input expression, with links to available lexical declarations. Handler context identifies its associated field, dataset or bound control; it does not prove that every statement acts on that field or that an event actually ran.',
'Scroll the command bar sideways to reach the reference selector, Follow reference and Source. Follow rule context to the field or dataset, handler to its captured routine, or lexical input/output to a declaration. Follow clears filters to show the exact target; reselect data rule afterward. Source requires unchanged attached source in the displayed generation. Missing or ambiguous handlers and unavailable syntax remain explicit. The shared 10000-row inventory limit reports omitted rules. Full launch, practice and test directions are in docs/guides/Data_Rules_Run_and_Test.txt. DPH does not run target code, SQL or validation.']))
ENGINEERING.append(('Capture field validation and transformation evidence', [
'DPH-WP2-6 recognizes serialized BeforePost, BeforeInsert, BeforeEdit, BeforeDelete, BeforeCancel and BeforeOpen as event bindings in both text and binary forms. Existing own-form method resolution supplies handler relations; DPH-WP3-15 invalidates older semantic captures. Existing On-prefixed events retain their previous behavior. Missing or ambiguous method targets remain unresolved.',
'AppendDataRules in DPH.Workspace.DatabaseConnections indexes captured symbols, event bindings and routine CFG nodes. It projects persistent-field constraints, recognized field/dataset/input hooks and bounded handler statements. A transformation requires two direct expressions in the matching Pascal statement IR, rather than a semicolon heuristic. Conditions, raises and early exits remain distinct. Repeated finally copies are deduplicated by source location and context. Statement input/output links use captured lexical reads/writes within expression ranges, not reaching-definition or runtime-value claims. Literal strings, comments and character codes are omitted; supported custom/default expressions retain their structure without evaluation.',
'The combined inventory is bounded to 10000 rows; truncation is explicit in the model and native status. Source, SHA256, generation, context, handler, input/output and reverse references retain exact captured identity. Native data rule and rule declaration filters are serialized in the FMX resource. No new UI controls, helper unit, migration, target instance, driver or server execution is introduced. tools/build-data-rules.cmd checks real parser output, persisted/reopened captures, constraints, predicates, transformation inputs/outputs, missing handlers/syntax, semicolons in call literals, redaction, inventory limits, native navigation and normal/compact layouts. Explicit directions are in docs/guides/Data_Rules_Run_and_Test.txt.']))

'''
s=s[:insert]+chapters+s[insert:]
s=s.replace("'Inspect transaction and rollback paths', 'Compare screen history", "'Inspect transaction and rollback paths', 'Inspect field validation and transformations', 'Compare screen history")
s=s.replace("'guide_version': 27","'guide_version': 28")
# Normalize current prose to the final validated analyzer versions and live count.
s=s.replace(".replace('DPH-WP3-13','DPH-WP3-14')", ".replace('DPH-WP3-13','DPH-WP3-14').replace('DPH-WP3-14','DPH-WP3-15').replace('DPH-WP2-5','DPH-WP2-6').replace('324 requirement records remain incomplete','323 requirement records remain incomplete')")
p.write_text(s,encoding='utf-8')
p=r/'docs/guides/Data_Rules_Run_and_Test.txt';p.write_text(r'''DPH FIELD VALIDATION AND TRANSFORMATIONS RUN AND TEST
Last changed: 12 October 2026

START AND INSPECT
1. Open File Explorer and navigate to:
   C:\New Delphi Projects\Delphi Project Handoff\bin\Win32\Debug
2. Double-click DelphiProjectHandoff.exe. It opens maximized.
3. Click Attach project at the upper left. Choose the OTHER application's
   .dproj, .dpr or .groupproj. Save its proposed .dphdb in DPH's Databases
   folder. Wait for the bottom activity line to finish. For an existing cache,
   click Open cache, select its .dphdb, then attach its matching source.
   Click Full reassessment to upgrade older captures to DPH-WP2-6/WP3-15.
4. In the upper-right page selector choose Database connections.
5. In the kind selector choose data rule. Clear the text filter.
6. Select a rule. The central memo begins DATA VALIDATION AND TRANSFORMATION
   EVIDENCE. Read Input expression, Output expression, Constraint, Captured
   expression and conditional compilation. Scroll within the memo; drag the
   divider below the list to give details more height.
7. Search for a field, handler, predicate or transformation expression.
   First page resets pagination; Next page shows the next 250 matches.
8. Drag the toolbar's horizontal scrollbar right to reach the reference
   selector, Follow reference and Source. Choose Target via rule context
   and click Follow reference to inspect the field/dataset. Choose handler
   for its routine, or lexical input/output for a captured declaration.
   Follow clears filters to reveal its exact target. Choose data rule again
   when returning. Used by entries provide reverse navigation.
9. Click Source for unchanged attached source in the displayed generation.
   Detached, changed, historical, binary or outside-root source is refused
   with an explanation. Do not interpret refusal as an empty rule.

READ THE EVIDENCE
Required/ReadOnly/Size/Precision/MinValue/MaxValue and supported custom/default
expressions are captured declarations. Missing values and inherited defaults
stay unknown. Defaults are not evaluated. String and character-code literals,
comments, message contents and masks are omitted from projected expressions.
OnValidate/OnSetText/OnGetText and supported dataset/input hooks identify source
contexts. Handler predicates, raises, exits and assignments are candidates.
The context field is not proof that every statement changes that field.
Lexical inputs/outputs are declarations, not observed values or reaching
definitions. Actual event dispatch, successful validation and database effects
remain unknown. Missing handlers/syntax stay explicit. A full combined inventory
reports truncation at 10000 rows; narrow the captured project when needed.

CONTROLLED PRACTICE
Run the developer test below first. It creates a fixed ignored fixture under:
C:\New Delphi Projects\Delphi Project Handoff\bin\data-rules-validation\source
Attach that folder's Connections.dpr to DPH. Choose data rule and search for
InputAmount * 1.2. Its input is InputAmount and output is OutputAmount.
Follow handler to ValidateAmount. Search InputAmount < 0 to inspect its
validation condition and associated exception source. Search MinValue for the
Amount field's declared minimum. OnGetText = MissingHandler deliberately has
no resolved handler. This fixture is analyzed only; never run its source.

DEVELOPER VALIDATION
1. Open Windows Start, type cmd, then select Run as administrator for
   Command Prompt. Elevation lets RAD Studio read its environment file.
2. Enter:
   cd /d "C:\New Delphi Projects\Delphi Project Handoff"
3. Enter:
   tools\build-data-rules.cmd
   Expect Data rules validation passed and a zero exit code.
   Results: docs\phase1-data-rules-validation.json and .log.
   Normal/compact images are direct renders of running DPH controls.
4. Run tools\build-database-transactions.cmd, tools\build-database-operations.cmd,
   tools\build-dataset-bindings.cmd and tools\build-database-engines.cmd.
5. Run tools\build-wp3.cmd, then:
   bin\Win32\Debug\DPH.Tests.Semantics.exe "%CD%"
6. Run tools\build-wp2.cmd for parser/discovery checks.
7. Run tools\build-wp0.cmd. Expect PASS WP0-TEST for the actual app and FMX.
The tools run DPH validation, not the selected application's code or SQL.
Owner source and catalog remain unchanged.
''',encoding='utf-8')
p=r/'README.md';s=p.read_text(encoding='utf-8-sig');s+='\nField validation and transformation evidence is under Database connections → data rule. Inspect declared constraints, handler conditions and assignment inputs/outputs, then follow exact context, handler or lexical declaration references. Explicit launch and test directions: docs/guides/Data_Rules_Run_and_Test.txt.\n';p.write_text(s,encoding='utf-8')
p=r/'help/index.html';s=p.read_text(encoding='utf-8-sig');needle='</body>';assert needle in s;s=s.replace(needle,'<h2>Inspect field validation and transformations</h2><p>Choose Database connections in the upper-right selector, then data rule in its kind filter. Select a row to read declared constraints, validation conditions and transformation inputs and outputs. Follow reference opens its context field, handler or lexical declaration. Source requires unchanged attached code. Scroll commands sideways and the evidence memo vertically. Missing handlers and syntax remain explicit; source candidates do not establish actual validation. Full directions are in docs/guides/Data_Rules_Run_and_Test.txt.</p>\n'+needle);p.write_text(s,encoding='utf-8')
print('Data-rule guide chapters, help and explicit directions prepared')
