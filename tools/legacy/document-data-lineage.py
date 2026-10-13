from pathlib import Path
r=Path.cwd();p=r/'tools/build-guides.py';s=p.read_text(encoding='utf-8-sig')
i=s.index('for chapters in (USER, ENGINEERING):',s.index("ENGINEERING.append(('Capture field validation and transformation evidence'"))
chapters='''USER.append(('Trace inputs and destination candidates', [
'Start DPH from bin/Win32/Debug/DelphiProjectHandoff.exe. Attach the application you intend to document or open its captured database. Choose Database connections in the upper-right page selector. Choose bound control, persistent field, data rule or database operation in the kind selector and select a relevant row. Drag the horizontal toolbar scrollbar fully right to reveal Both directions, Trace lineage and Lineage diagram.',
'Click Trace lineage. The labeled memo shows the starting point, direction, capture generation and truncation state, followed by scoped route nodes, captured edges and unresolved breaks. Each node identifies its captured source location and SHA256. Select a Lineage hop in the reference selector, then click Follow reference. A component or rule opens its inventory evidence; a semantic declaration or file output opens Explain. To open the originally selected inventory row in unchanged attached source, return to Database connections and click Source. For another traced node, follow that node first and use its own Source command.',
'Both directions includes serialized controls and fields, data-source and dataset references, rule context, procedure reads and writes, operations and file-output candidates. This is a source relationship neighborhood. A procedure that reads one variable and writes another does not establish a value transfer between them. Dependencies are explicitly labeled separately from context. Choose Inputs for upstream dependencies or Destinations for downstream dependencies, then click Trace lineage again. These directions omit broad procedure read/write/handler context while retaining captured binding and rule context.',
'Click Lineage diagram to open Graphs with Data lineage selected. Orange dashed arrows show qualified source relationships. The HTML diagram labels arrows and lists unresolved breaks below it. Select a component node to open Database connections or a declaration/output node to open Explain. A native graph remains available when the embedded browser is unavailable. Exact node identity is retained and grouping is disabled. To return to the textual route, choose Database connections in the page selector, select the intended starting row and click Trace lineage.',
'A file destination node identifies a captured writer and whether the destination expression was literal or dynamic. Follow it to Explain and inspect captured source for the expression. Projected lineage omits literal contents and configuration values. No file is produced and no SQL is executed by the trace. Unknown handlers, absent dataset references, unavailable semantic targets, connection boundaries and omitted routes remain explicit. A final captured endpoint does not establish successful delivery, current values or runtime execution. Limits are 200 returned nodes, 800 edges and 12 hops; index limits are also reported. Full directions and a controlled practice project are in docs/guides/Data_Lineage_Run_and_Test.txt.']))
ENGINEERING.append(('Connect source evidence into scoped lineage', [
'TDPHDatabaseConnections.Lineage projects the captured workspace and database inventory without modifying either. Exact component_field source locations map semantic receivers to serialized inventory identity only when unique. Existing rule declarations retain their identity. Directed derives_from relations connect input candidates to dependent declarations and file output artifacts. Lexical rule inputs and outputs connect through the captured rule. Serialized bindings, handler context, reads/writes, rendering requests and database operation routines remain labeled context rather than reaching-definition evidence.',
'The projection indexes at most 50000 symbols and 100000 deduplicated edges, then performs bounded adjacency traversal. Each returned node retains its parent hop, kind, source, SHA256 and capture generation. Edges retain original range, source hash, condition, category and qualification. Both direction traversal includes context; Inputs and Destinations exclude broad procedure context and respect dependency direction. Cycles are deduplicated. Returned limits are 200 nodes, 800 edges and 12 hops. Missing targets, missing dataset declarations, unresolved handlers, scoped connection boundaries and limits remain explicit. Runtime values, aliases, server effects and final success remain unverified.',
'ResolveFields now treats any captured data-source chain without a dataset target as incomplete, including the case where another source chain resolves. It no longer invents a persistent-field target from the remaining valid branch. Existing exact-role and ambiguity checks remain in force. No analyzer version or schema migration is needed because lineage projects existing captures; older captures without a recognized event or relation still require Full reassessment.',
'The direction selector, Trace lineage and Lineage diagram buttons and Data lineage graph choice are serialized in DPH.UI.Main.fmx. Main form navigation reuses the inventory and explanation pages; graph grouping is disabled for lineage. GraphHTML renders the same evidence JSON with selectable nodes and unresolved breaks. Existing browser allowlisting and source hash guards remain in force. Tests use actual parsing, persisted and reopened SQLite captures, directional assignment chains, cyclic assignments, controlled file-writer evidence, redaction, incomplete bindings, trace limits and native FMX navigation/layout. No selected target, SQL, driver or production server is executed. Build with tools/build-data-lineage.cmd.']))

'''
s=s[:i]+chapters+s[i:]
s=s.replace("'Inspect field validation and transformations', 'Compare screen history'", "'Inspect field validation and transformations', 'Trace inputs and destination candidates', 'Compare screen history'")
s=s.replace("'guide_version': 28","'guide_version': 29")
s=s.replace(".replace('324 requirement records remain incomplete','323 requirement records remain incomplete')", ".replace('324 requirement records remain incomplete','323 requirement records remain incomplete').replace('323 requirement records remain incomplete','322 requirement records remain incomplete')")
p.write_text(s,encoding='utf-8')
(r/'docs/guides/Data_Lineage_Run_and_Test.txt').write_text(r'''DPH DATA LINEAGE RUN AND TEST
Last changed: 12 October 2026

START DPH
1. Open File Explorer and navigate to:
   C:\New Delphi Projects\Delphi Project Handoff\bin\Win32\Debug
2. Double-click DelphiProjectHandoff.exe. It opens maximized.
3. Click Attach project. Select the OTHER application's .dproj, .dpr or
   .groupproj. Save the proposed .dphdb under DPH's Databases folder.
   Wait until analysis finishes. For a saved capture, click Open cache
   and choose its .dphdb. Attach matching source before using Source.
   Click Full reassessment to refresh unsupported or older captures.

TRACE A CONTROL OR FIELD
4. In the upper-right page selector choose Database connections.
5. In its kind selector choose bound control, persistent field, data rule
   or database operation. Clear the text filter, then select a row.
6. Drag the toolbar's horizontal scrollbar fully right. Locate the
   Both directions selector, Trace lineage and Lineage diagram buttons.
7. Click Trace lineage. Read the memo headed DATA LINEAGE SOURCE CANDIDATES.
   Scroll down through SCOPED ROUTE NODES, CAPTURED EDGES, UNRESOLVED BREAKS
   AND BOUNDARIES and SCOPE AND LIMITS. Drag the divider below the list
   upward to give the evidence memo more space in a small window.
8. Both directions includes binding and procedure context. Context edges
   do not prove value transfer. To narrow the dependency direction,
   choose Inputs or Destinations, then click Trace lineage again.
9. Scroll the toolbar left to its reference selector. Choose a Lineage
   hop, then click Follow reference. Inventory nodes open the exact
   component/rule; semantic declarations and outputs open Explain.
10. Source in Database connections opens the originally selected row.
    To inspect another route node's source, follow that node first,
    then use its Source command. Detached or changed source is refused.
    A file-output node's Explain page identifies the captured writer
    and destination expression. Lineage itself omits literal contents.

VIEW THE DIAGRAM
11. Select the starting inventory row, scroll right and click Lineage
    diagram. DPH opens Graphs with Data lineage selected.
12. Scroll the diagram to inspect nodes and labeled qualified arrows.
    The HTML view lists unresolved breaks below the diagram. Select a
    component node to open its inventory evidence; select a declaration
    or output node to open Explain. A native diagram remains usable if
    the embedded browser is unavailable. Grouping stays disabled so that
    each node retains its exact identity.
13. Return via the upper-right Database connections choice. Select a new
    starting row before another trace. A saved capture can be traced
    while detached; original source navigation still requires attachment.

UNDERSTAND LIMITS
A dependency is a captured lexical candidate, not an observed runtime value.
Both directions is a relationship neighborhood, not a proven execution path.
Inputs and Destinations omit broad procedure read/write/handler context.
Bindings identify serialized candidate links; dynamic/inherited bindings stay
unknown. Missing handlers, absent dataset links, external targets, connection
boundaries and omitted routes remain explicit. Trace limits: 200 nodes,
800 returned edges, 12 hops, 50000 indexed symbols and 100000 indexed edges.
A final captured endpoint never proves successful file delivery or database
persistence. DPH does not run the selected application's code, SQL or drivers.

CONTROLLED PRACTICE
Run the developer test below first. It creates one fixed ignored fixture at:
C:\New Delphi Projects\Delphi Project Handoff\bin\data-lineage-validation\source
Attach that folder's Connections.dpr. Choose bound control and search for
AmountEdit. Trace lineage. Follow the captured Amount field, ValidateAmount,
InputAmount/OutputAmount and file-output candidate. MixedEdit deliberately
contains both a valid source and an empty source; its DataField must remain
unresolved. Do not execute the fixture source. It is analysis evidence only.

DEVELOPER TEST
1. Open Windows Start, type cmd, and choose Run as administrator.
2. Enter:
   cd /d "C:\New Delphi Projects\Delphi Project Handoff"
3. Enter:
   tools\build-data-lineage.cmd
   Expect Data lineage validation passed and exit code 0.
   The test writes docs\phase1-data-lineage-validation.json and native
   workspace/compact/diagram PNGs. To save console output, run:
   tools\build-data-lineage.cmd > docs\phase1-data-lineage-validation.log 2>&1
4. Run tools\build-data-rules.cmd, tools\build-database-transactions.cmd,
   tools\build-database-operations.cmd, tools\build-dataset-bindings.cmd
   and tools\build-database-engines.cmd.
5. Run tools\build-wp3.cmd, then:
   bin\Win32\Debug\DPH.Tests.Semantics.exe "%CD%"
6. Run tools\build-wp2.cmd for parser/discovery checks.
7. Run tools\build-wp0.cmd. Expect PASS WP0-TEST for actual app and FMX.
The tests preserve selected source and the owner catalog. No target app or
production database is opened. Test fixtures remain under the fixed bin path.
''',encoding='utf-8')
p=r/'README.md';p.write_text(p.read_text(encoding='utf-8-sig')+'\nData lineage: select a Database connections row, scroll its toolbar right and use Trace lineage or Lineage diagram. Inputs/Destinations filter lexical dependencies; context is separately qualified. Unresolved breaks and trace limits remain visible. Explicit directions: docs/guides/Data_Lineage_Run_and_Test.txt.\n',encoding='utf-8')
p=r/'help/index.html';s=p.read_text(encoding='utf-8-sig');s=s.replace('</body>','<h2>Trace inputs and destination candidates</h2><p>Choose Database connections in the upper-right selector and select a control, field, rule or operation. Scroll its toolbar fully right and click Trace lineage. The memo lists route nodes, captured edges and unresolved breaks. Choose Inputs or Destinations to filter dependency direction. Both directions also includes procedure context, which does not prove value transfer. Choose a Lineage hop and Follow reference for exact evidence. Lineage diagram opens Graphs with selectable nodes; unresolved breaks appear below the HTML diagram. Source still requires unchanged attached source. Final delivery and runtime values remain unknown. Full directions: docs/guides/Data_Lineage_Run_and_Test.txt.</p>\n</body>');p.write_text(s,encoding='utf-8')
print('Prepared data lineage guide chapters, help and explicit directions')
