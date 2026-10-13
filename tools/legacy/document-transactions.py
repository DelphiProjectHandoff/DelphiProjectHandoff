from pathlib import Path
r=Path.cwd()
p=r/'tools/build-guides.py';s=p.read_text(encoding='utf-8-sig')
pos=s.index('\nfor chapters in (USER, ENGINEERING):',s.index("ENGINEERING.append(('Recognize captured database operation requests'"))
addition="""
USER.append(('Inspect transaction and rollback paths', [
'Choose Database connections in the upper-right page selector. In its kind filter choose transaction operation, then clear the text filter. Select StartTransaction or BeginTrans to inspect a begin request. Select Commit, Rollback or a retaining variant to inspect that boundary. Use the calling routine name to narrow the list. Searches include linked references, so a search for a begin call may also show its connected commit and rollback rows.',
'The evidence memo begins with TRANSACTION PATHS (SOURCE POSSIBILITIES). Each route leads to the next explicit transaction request on the same declared receiver, or to a normal/exception routine exit without another boundary. Possible normal and exception paths remain distinct. Conditional/loop routes and duplicated finally cleanup copies are labeled. A route is a conservative source possibility, not proof that the transaction started or that a commit or rollback succeeded.',
'In the reference selector choose a Target via possible normal path or possible exception path, then click Follow reference to inspect the next boundary. Target via Transaction opens the captured receiver; Used by returns to an earlier boundary. Follow reference clears filters to reveal its exact target, so reselect transaction operation when returning to the inventory. Scroll the command bar sideways to reach Follow reference and Source. Source requires unchanged attached source; a detached cache refuses navigation.',
'CommitRetaining and RollbackRetaining preserve or restart transaction context according to the provider. RollbackSavepoint concerns a savepoint rather than necessarily the full transaction. Post and Cancel are dataset operations and do not establish transaction completion. A visible exit without another boundary requires source and caller review; implicit transactions, aliases, external effects and provider behavior remain unknown. Missing, ambiguous or truncated flow must never be read as safe completion. Explicit launch and test steps are in docs/guides/Database_Transactions_Run_and_Test.txt.'
]))
ENGINEERING.append(('Trace captured transaction boundaries', [
'DPHSemanticVersion DPH-WP3-14 invalidates older captures. RoutineFacts emits database_transaction relations for recognized FireDAC, ADO, dbExpress, BDE and IBX transaction APIs on declared imported framework types or captured descendants. IsDatabaseType shares the existing bounded ancestry and framework-name shadow checks with dataset operation recognition. The API list is provider-specific; ordinary methods and local classes sharing framework names are excluded. Parameter values and savepoint names do not enter the inventory. No target class, SQL or server is loaded or executed.',
'AttachTransactionPaths projects existing captured flow_nodes and flow_edges without evaluating expressions. Each boundary maps to the smallest containing statement range in the same routine and source. Separate finalizer copies retain their different pending transfers. Bounded traversal stops at the next boundary on the same declared semantic receiver or a normal/exception exit. Exception and conditional/loop flags stay separate. Multiple transaction calls in one expression receive no invented ordering. Receiver aliases and interprocedural transactions remain unproved.',
'Indexes group nodes by routine, outgoing edges by node and transaction boundaries by their statement. Limits are 10000 candidate CFG nodes per routine, 5000 states and 64 routes per boundary, and 1000000 states per inventory. Missing or bounded flow remains explicit. Routes expose node IDs and traversed edge-kind sets for comparison with the underlying CFG; they are not execution traces or path-feasibility proofs. Existing reference navigation links receivers, next boundaries and their reverse references. Controls remain serialized and IDE editable in DPH.UI.Main.fmx.',
'Calls immediately after try, except and finally now retain their no-parentheses statement-call recognition. Run tools/build-database-transactions.cmd elevated for 400 checks using actual analysis, persisted/reopened SQLite and native FMX controls. Fixtures cover normal/error commit and rollback paths, finalizers, conditional alternatives, missing boundaries, distinct receivers, retaining/savepoint variants, five framework families, captured descendants, local name shadows, unordered expressions, absent CFG, redaction, native navigation, compact layout and unchanged source/catalog. Regression suites cover 232 operation, 92 binding, 66 engine and 134 semantic checks. tools/build-wp0.cmd builds the actual application and checks the FMX resource. Tests reuse fixed ignored bin/database-transactions-validation.'
]))
"""
s=s[:pos]+ '\n'+addition+s[pos:]
s=s.replace("'Inspect database read and write operations', 'Compare screen", "'Inspect database read and write operations', 'Inspect transaction and rollback paths', 'Compare screen")
s=s.replace("p.replace('326 requirement records remain incomplete','325 requirement records remain incomplete').replace('DPH-WP3-12','DPH-WP3-13')", "p.replace('326 requirement records remain incomplete','324 requirement records remain incomplete').replace('325 requirement records remain incomplete','324 requirement records remain incomplete').replace('DPH-WP3-12','DPH-WP3-14').replace('DPH-WP3-13','DPH-WP3-14')")
s=s.replace("'guide_version': 26", "'guide_version': 27")
p.write_text(s.rstrip()+'\n',encoding='utf-8')
p=r/'README.md';s=p.read_text(encoding='utf-8-sig');s+='\nRequirement 05.13 adds captured transaction API boundaries and conservative normal/error/cleanup routes in Database connections. Select transaction operation, inspect source-qualified routes, and follow a receiver or next boundary. Five framework families and captured descendants are recognized without executing a target or proving outcomes. Explicit directions: [Database transaction run and test guide](docs/guides/Database_Transactions_Run_and_Test.txt). Focused validation: 400 checks.\n';p.write_text(s,encoding='utf-8')
p=r/'help/index.html';s=p.read_text(encoding='utf-8-sig');mark='<h2>Inspect transaction and rollback paths</h2><p>Choose Database connections, choose transaction operation in the kind filter, and clear the text filter. Select a begin, commit or rollback request. The evidence memo starts with possible normal, exception and cleanup paths to the next explicit boundary on the same declared receiver, or an exit without another local boundary. These source possibilities do not prove runtime success. In the reference selector choose a possible path and click Follow reference, or choose Transaction to inspect its receiver. Follow clears filters to reveal the target. Scroll the commands sideways for Source, which needs unchanged attached source. Retaining variants and savepoint rollback remain distinct. Missing, ambiguous or truncated CFG, aliases, caller behavior and implicit commits require review. See docs/guides/Database_Transactions_Run_and_Test.txt for explicit launch and test directions.</p>'
assert '</body>' in s;s=s.replace('</body>',mark+'\n</body>');p.write_text(s,encoding='utf-8')
(r/'docs/guides/Database_Transactions_Run_and_Test.txt').write_text('''DPH DATABASE TRANSACTIONS - RUN AND TEST
Last changed: 12 October 2026

START AND INSPECT
1. In File Explorer open:
   C:\\New Delphi Projects\\Delphi Project Handoff\\bin\\Win32\\Debug
2. Double-click DelphiProjectHandoff.exe. DPH opens maximized.
3. Click Attach project at the upper left. Select the OTHER Delphi application
   to inspect by its .dproj, .dpr or .groupproj file. Save its proposed .dphdb
   under DPH's Databases folder. Wait for the bottom activity line to finish.
   For an existing cache, click Open cache and select its .dphdb, then attach
   its unchanged source. Click Full reassessment to upgrade old captures.
4. In the upper-right page selector choose Database connections.
5. In the kind selector choose transaction operation. Clear the text filter.
6. Select StartTransaction, BeginTrans, Commit, Rollback or a retaining call.
   The central evidence memo begins TRANSACTION PATHS (SOURCE POSSIBILITIES).
7. Read each possible normal, exception or cleanup route. A normal/exception
   exit without another boundary is a reason to inspect source and callers,
   not proof that a transaction was left active or safely completed.
8. In the reference selector choose Target via possible normal path or
   possible exception path. Click Follow reference to inspect that boundary.
   Choose Target via Transaction instead to inspect the receiver. Used by
   references return to earlier boundaries. Follow clears the kind/text
   filters to reveal the exact target; reselect transaction operation as needed.
9. Drag the command bar's horizontal scrollbar right to reach Follow reference
   and Source. Source opens the hash-checked captured location only with
   unchanged attached source. Detached/changed/historical evidence is refused.
10. Scroll inside the evidence memo for effects, CFG limits and unknowns.
    Search includes reference labels, so a routine/begin search can also show
    connected commit/rollback rows. No matches is not proof of no transactions.

WHAT THE EVIDENCE MEANS
Recognized FireDAC, ADO, dbExpress, BDE and IBX API requests are linked to their
declared receiver and possible intraprocedural CFG routes. Commit can raise.
Rollback can raise and cannot prove that earlier commits or external effects
were undone. Retaining variants and savepoint rollback are separate effects.
Post/Cancel are not transaction completion. The target app, SQL and database
server are never executed. Aliases, factories, runtime dispatch, automatic
transactions, caller behavior, nesting depth and server outcomes remain unknown.
Missing/ambiguous/bounded CFG is explicitly qualified, never safe-completion proof.

REPEAT THE AUTOMATED CHECKS
1. Open the Windows Start menu. Type cmd. Right-click Command Prompt and
   choose Run as administrator; accept Windows' elevation prompt.
2. Enter exactly:
   cd /d "C:\\New Delphi Projects\\Delphi Project Handoff"
3. Enter:
   tools\\build-database-transactions.cmd
4. Wait for Database transactions validation passed: 400 checks.
   The fixed ignored fixture folder is bin\\database-transactions-validation.
   No live database or selected application is opened. Review the saved report:
   docs\\phase1-database-transactions-validation.json
5. Regression commands, one at a time:
   tools\\build-database-operations.cmd
   tools\\build-dataset-bindings.cmd
   tools\\build-database-engines.cmd
   tools\\build-wp3.cmd
   bin\\Win32\\Debug\\DPH.Tests.Semantics.exe "%CD%"
   Expected checks: operations 232, bindings 92, engines 66, semantics 134.
6. Rebuild the actual application and its FMX resource check:
   tools\\build-wp0.cmd
   Expect PASS WP0-TEST. Start the application again using steps 1-2 above.

400 focused checks and 524 regression checks apply to these tested contracts.
They do not establish completion of every DPH project requirement.
''',encoding='utf-8')
print('Updated transaction directions, help and guide source version 27')
