from pathlib import Path
r=Path.cwd();p=r/'tools/build-guides.py';s=p.read_text(encoding='utf-8-sig');pos=s.rfind('for chapters in (USER, ENGINEERING):');assert pos>=0
chapters="""USER.append(('Inspect import and export file formats', [
'Start bin/Win32/Debug/DelphiProjectHandoff.exe. Attach the application you intend to document or open its captured database. Choose Import/export formats in the upper-right page selector. A file-format contract explains how another program can produce or consume a file: its encoding, structure, required fields, compatibility and error handling.',
'Use the kind selector to choose import, export or captured resource. Enter a format, routine or encoding in the search field. Select a row and read Format evidence and saved contract below the list. First page and Next page navigate inventories over 250 rows. Scroll the command bar horizontally when the window is narrow. Open source opens unchanged attached evidence; Explain routine selects the captured enclosing routine.',
'Captured JSON, XML and INI resources expose bounded member structure with scalar values omitted. This is observed structure, not a formal validation schema. Transfer API spellings identify candidates and literal filename extensions; explicit TEncoding arguments remain source candidates. Captured source decoding is separate from a transfer encoding contract. Dynamic paths, defaults, missing structure and unsupported formats remain unknown.',
'Click Record/open contract. An existing contract opens in Knowledge; otherwise DPH prepares a draft with fields for format/version, purpose, encoding and BOM, schema, delimiters and escaping, producer, consumer, validation, compatibility and verification. Complete each field or explicitly record Unknown and its responsible maintainer. Enter the named author, click Save and review separately against evidence. Preparing the draft does not save or verify it. Clear an unsaved Knowledge draft before opening a different contract.',
'Contracts retain an exact captured source identity. Reassessment with changed source creates a different contract identity; previous records remain available in Knowledge. DPH does not execute a transfer or infer successful compatibility. Detailed commands and controlled practice instructions are in docs/guides/File_Formats_Run_and_Test.txt.'
]))
ENGINEERING.append(('Project captured file formats and contracts', [
'TDPHWorkspaceView.FileFormats projects existing IR and semantic captures without a schema or analyzer change. Supported captured JSON, XML and INI resources show member shapes while omitting scalar values. Member names are bounded and unsafe names are omitted. Each resource shows at most 250 members and an explicit total/limit. The combined inventory is capped at 10000 rows with visible truncation.',
'Outer expression tokens identify dotted ReadAllText/Bytes/Lines, WriteAllText/Bytes/Lines, LoadFromFile and SaveToFile spellings. Quoted strings remain single tokens and comments do not become APIs. A supported literal first argument contributes only a safe filename extension. Explicit TEncoding argument spellings remain candidates; byte APIs remain binary candidates. Enclosing captured routine identity provides a producer or consumer link. Evidence retains source hash, generation and enclosing expression range; custom receivers and runtime dispatch are unverified.',
'DPH.UI.Main and its serialized FMX resource provide kind/text filters, 250-row paging, labeled evidence, guarded source opening, routine explanation and contract drafts. No runtime controls, helper unit or target execution is introduced. Deterministic contract titles include the exact row and source hash. Existing attributed Knowledge storage supplies immutable revision history and separate review. A contract draft includes encoding/BOM, schema and required fields, producer/consumer mappings, validation, compatibility, verification and remaining unknowns.',
'Run tools/build-file-formats.cmd elevated for the focused actual-parser, persistence and native FMX checks. It uses fixed ignored bin/file-formats-validation fixtures and verifies redaction, routine identity, explicit encoding candidates, resource/transfer distinctions, large shapes, paging, saved contracts, source-change and detached-source refusal, compact layout and unchanged captured source/catalog. Shared schema-history, lineage, Knowledge and publishing regressions and tools/build-wp0.cmd validate integration. Candidate evidence and authored contracts do not establish a formal schema, runtime transfer success or deployed compatibility.'
]))

"""
s=s[:pos]+chapters+s[pos:];s=s.replace(".replace('322 requirement records remain incomplete','321 requirement records remain incomplete')",".replace('322 requirement records remain incomplete','321 requirement records remain incomplete').replace('321 requirement records remain incomplete','320 requirement records remain incomplete')")
s=s.replace("'Inspect migration and schema-version history', 'Compare screen history", "'Inspect migration and schema-version history', 'Inspect import and export file formats', 'Compare screen history");s=s.replace("'guide_version': 30","'guide_version': 31");p.write_text(s,encoding='utf-8')
p=r/'README.md';p.write_text(p.read_text()+'\nRequirement 05.17 adds Import/export formats with captured API/encoding candidates, JSON/XML/INI member structure, source/routine navigation and attributed format contracts. Read docs/guides/File_Formats_Run_and_Test.txt. Transfer success and formal schema compliance remain unverified.\n',encoding='utf-8')
p=r/'help/index.html';s=p.read_text();s=s.replace('</body>','<section><h2>Import and export formats</h2><p>Choose Import/export formats in the page selector. Filter and select a row to inspect captured format, encoding and producer/consumer evidence. Open source requires unchanged attached bytes. Explain routine opens its captured routine. Record/open contract prepares or opens an attributed Knowledge record covering schema, encoding, mappings, validation and compatibility. Enter the named author and click Save; review separately. Captured resource structure omits scalar values. No file transfer executes. Detailed directions: docs/guides/File_Formats_Run_and_Test.txt.</p></section></body>');p.write_text(s,encoding='utf-8')
(r/'docs/guides/File_Formats_Run_and_Test.txt').write_text(r'''DPH IMPORT AND EXPORT FILE FORMATS RUN AND TEST
Last changed: 12 October 2026

RUN AND INSPECT
1. Open File Explorer and go to:
   C:\New Delphi Projects\Delphi Project Handoff\bin\Win32\Debug
2. Double-click DelphiProjectHandoff.exe.
3. Click Attach project and select the target .dproj, .dpr or .groupproj.
   Save its proposed database when prompted. To inspect a saved capture,
   click Open cache and choose its .dphdb.
4. In the upper-right page selector choose Import/export formats.
5. In the page's kind selector choose All, import, export or captured resource.
   Enter a format, routine or encoding in the adjacent search box.
6. Select a row. Read Format evidence and saved contract below the list.
   First page and Next page navigate results over 250 rows. Scroll the command
   bar horizontally to reveal all buttons in a narrow window.
7. Click Explain routine to select its enclosing routine. Click Open source
   to read unchanged attached evidence. Changed or detached source refuses
   navigation with an explanation. Resource rows may have no routine.

RECORD A CONTRACT
1. Select the format row and click Record/open contract.
2. If a saved contract exists, Knowledge opens it. Otherwise a new draft opens.
   Clear any unsaved Knowledge draft before opening a different contract.
3. Fill in format/version, direction/purpose, encoding/BOM, schema and required
   fields, delimiters/escaping, producer and consumer mappings, validation,
   compatibility, verification evidence and remaining unknowns/maintainer.
   Explicit Unknown is acceptable when evidence is unavailable.
4. Enter the named author in Knowledge and click Save. Opening or preparing
   the draft alone does not save anything. Review separately against evidence.
5. Return to Import/export formats and select the row to see its saved contract.
   Changed source has a new identity; previous records stay in Knowledge.

INTERPRETATION
API spelling is a candidate, including on custom receivers. Explicit encoding
arguments are source evidence. Binary APIs do not establish text encoding.
Captured source decoding is not a transfer encoding contract. JSON/XML/INI
member structure is bounded observed shape, not a required/optional schema.
Scalar values and literal paths are omitted. Dynamic paths, defaults, opaque
resources, missing parser evidence and unsupported formats remain unknown.
DPH does not execute the selected app, a file transfer, SQL, driver or server.

BUILD AND TEST
1. Open Start, type Command Prompt and choose Run as administrator.
2. Enter:
   cd /d "C:\New Delphi Projects\Delphi Project Handoff"
3. Enter:
   tools\build-file-formats.cmd
   The checks must report PASS with no FAIL and return exit code zero.
4. Build the actual application and verify serialized FMX bindings:
   tools\build-wp0.cmd
5. Shared checks:
   tools\build-schema-history.cmd
   tools\build-data-lineage.cmd
   tools\build-wp5.cmd
   tools\build-wp6.cmd
6. For controlled practice after the focused check, attach:
   C:\New Delphi Projects\Delphi Project Handoff\bin\file-formats-validation\source\Formats.dpr
   Save a separate practice database. Inspect Main.Transfer, settings.json,
   settings.xml and settings.ini. Filter export and WriteAllText for the CSV
   filename candidate. Record a contract and leave unverified fields Unknown.

EVIDENCE
Focused results: docs/phase1-file-formats-validation.json and companion log.
Native renders show actual DPH controls with controlled fixtures, not target
application screenshots. Guides: docs/guides; companion PDFs: docs/pdf.
''',encoding='utf-8')
verify=(r/'bin/verify-schema-history-guides.py').read_text().replace('==30','==31').replace('Inspect migration and schema-version history','Inspect import and export file formats').replace('Project captured migration and version evidence','Project captured file formats and contracts').replace('schema-history-guide-check.json','file-formats-guide-check.json');(r/'bin/verify-file-formats-guides.py').write_text(verify,encoding='utf-8')
