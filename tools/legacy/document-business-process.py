from pathlib import Path
p=Path('tools/build-guides.py');s=p.read_text(encoding='utf-8');a=s.index('for collection in (USER, ENGINEERING):') if 'for collection in (USER, ENGINEERING):' in s else s.index('def field(')
chapters='''USER.append(('Inventory business processes', [
'Open the selected application or its database, then choose Business processes in the upper-right page selector. Click New process. The Process fields page provides separately labeled fields for process name, accountable owner, department and roles, trigger and prerequisites, inputs and their origins, outputs and recipients, ordered steps and handoffs, and unknowns with the person responsible for resolving them. Enter a named contributor above the fields. The contributor records the description; the accountable owner is a separate business role.',
'Give the process a descriptive name. Complete each field or explicitly enter Unknown. Do not enter customer records or credentials. Name is stable after saving; other fields remain editable. Each field accepts up to 4096 characters and the name up to 200. Scroll vertically to reach the last fields. In a narrow window scroll the command bar horizontally to reach Apply to Knowledge draft. Apply prepares the canonical body and does not save it. Click Save on Knowledge to persist the process as needs_review.',
'Choose Knowledge links to connect captured routines using entity and depends_on, or exact procedure/evidence revisions using section and cites. Search, Find targets, select a result, choose the link role and Add link. Return to Knowledge and Save. A routine name written in prose alone is not a source link. Review separately using a named reviewer after checking the business account and source evidence.',
'Return to Business processes. Open record opens saved Knowledge and its immutable history; Edit fields restores the structured editor, preserves the process identity and exact links, and prepares a new revision after Apply and Save. Implementation links opens its evidence links. The review-state and text filters search the register, including owners, inputs and outputs. First page and Next page expose inventories larger than 250 records. Save or discard a current draft before editing another process. Cancel discards the current draft.',
'Publishing with maintenance or all audience includes the attributed canonical process and typed fields, subject to exclusions and redaction. These descriptions do not establish that the target performed the steps or produced the stated outcomes. A repeatable exercise and elevated test command are in docs/guides/Business_Process_Run_and_Test.txt.'
]))
ENGINEERING.append(('Maintain structured business process records', [
'TDPHWorkspaceView provides the typed business_process object with stable process_id GUID and eight string fields. Validation rejects missing, unexpected, non-text, empty and oversized fields, and an unspecified process name. SaveKnowledge enforces project business-rule maintenance scope, a name matching the stable title, a canonical generated body, unique identity and optimistic revisions. Existing metadata conversion/discard guards, immutable review/edit history and exact evidence links remain authoritative.',
'BusinessProcess controls and the Process fields editor are serialized in DPH.UI.Main.fmx for IDE and Object Inspector editing. A scrolling native field editor prepares the existing Knowledge draft rather than silently saving. Named contributor, draft guards, editable business fields, protected saved name, separate review, filters, 250-row paging, source explanation navigation and exact section revisions share the existing workflow. No helper unit, schema migration, runtime control construction or target execution is introduced.',
'Run tools/build-business-process.cmd elevated. The controlled fixture parses Operations.dpr and FulfilOrders, persists and reopens typed fields, tests malformed metadata, duplicate/changed identities, canonical-body divergence, stale saves, named review and immutable history, exact source/procedure links, canonical publication and full bundle validation. Actual native FMX editor/register renders cover normal and compact windows and the last field. Shared knowledge, publishing and data-quality suites and tools/build-wp0.cmd cover regressions. Fixtures use the fixed ignored bin/business-process-validation directory.',
'Business owner and contributor are distinct. Unknown is an explicit unresolved value rather than inferred business knowledge. Source links establish captured implementation evidence, not that a business step ran. Generic ordered step text in this inventory does not complete the separate departmental workflow or end-to-end process-diagram requirements.'
]))

'''
s=s[:a]+chapters+s[a:];s=s.replace("'guide_version': 34","'guide_version': 35").replace(".replace('318 requirement records remain incomplete','317 requirement records remain incomplete')",".replace('318 requirement records remain incomplete','317 requirement records remain incomplete').replace('317 requirement records remain incomplete','316 requirement records remain incomplete')");p.write_text(s,encoding='utf-8')
Path('docs/guides/Business_Process_Run_and_Test.txt').write_text(r'''DPH BUSINESS PROCESS INVENTORY
Last changed 12 October 2026

RUN AND RECORD
1. Open C:\New Delphi Projects\Delphi Project Handoff\bin\Win32\Debug in File
   Explorer. Double-click DelphiProjectHandoff.exe.
2. Click Attach project; choose the application's .dproj/.dpr/.groupproj.
   Save its proposed database under DPH's Databases folder. Wait for analysis.
   Alternatively click Open cache and select its existing .dphdb database.
3. Choose Business processes in the page selector at the upper right.
4. Click New process. Enter a named contributor in Process fields.
5. Enter a descriptive Process name. Complete accountable owner, department
   and roles, trigger, inputs, outputs, ordered steps/handoffs and unknowns.
   Explicitly enter Unknown where facts are unavailable. Scroll down to reach
   every field. Name allows 200 characters; other fields allow 4096 each.
6. Click Apply to Knowledge draft. In a narrow window scroll the command bar
   sideways to find this button. Apply alone does not save. Click Save on
   Knowledge and wait for completion. The saved process needs human review.
7. Choose Knowledge links in the page selector. Choose entity, enter a captured
   routine name, click Find targets, select its exact result, choose depends_on
   and click Add link. To cite a saved procedure choose section, search its
   title, select the exact revision, choose cites and click Add link.
8. Return to Knowledge and click Save. Enter the named reviewer; verify only
   after checking the stated business facts against evidence. Saving and
   reviewing do not prove the selected application actually ran the process.
9. Return to Business processes. Open record shows the saved Knowledge and
   history. Edit fields restores the editor. Apply and Save append a revision,
   preserve identity and links, and require fresh review. Saved name is stable.
10. Filter by owner, input, output or review state. First page and Next page
    navigate more than 250 processes. Implementation links opens exact links.
    Save or discard a draft before opening another process. Cancel discards it.

REPEATABLE PRACTICE
Use a disposable documentation database for a project you may inspect. Create
Fulfil orders, owner Operations manager, input Approved order, output Dispatch
confirmation and steps Check / Reserve / Dispatch / Confirm. Leave unsupported
fields Unknown. Save, link a relevant actual captured routine and saved
procedure, Save again, and review. Close/reopen the database and confirm fields,
contributor, review and links. Edit outputs to include tracking number, Apply,
Save and confirm the prior reviewed revision remains in immutable history while
the new revision needs review. Publish to a new folder with maintenance/all
audience and verify the process and exact links in index.html. Never insert
practice descriptions into production documentation without checking them.

DEVELOPER CHECKS
Open an elevated Command Prompt. Run:
  cd /d "C:\New Delphi Projects\Delphi Project Handoff"
  tools\build-business-process.cmd
A nonzero exit or FAIL is a failure. Inspect
docs\phase1-business-process-validation.log and validation.json. The fixture
creates a controlled parser input and SQLite store under the fixed ignored
bin\business-process-validation folder, exercises real native controls and
validates an exported bundle. Run tools\build-wp0.cmd for the actual app/FM X
resource check. No selected target executable, SQL, service or job is run.
'''.replace('FM X','FMX'),encoding='utf-8')
p=Path('README.md');p.write_text(p.read_text(encoding='utf-8')+'\nRequirement 06.01 adds Business processes with a native structured editor for owner, inputs, outputs, trigger, roles, steps and unknowns, plus stable identity, exact source/procedure links and named review/history. See docs/guides/Business_Process_Run_and_Test.txt.\n',encoding='utf-8')
p=Path('help/index.html');p.write_text(p.read_text(encoding='utf-8').replace('</body>','<section><h2>Business processes</h2><p>Choose Business processes, then New process. In Process fields enter a named contributor and complete the separately labeled owner, inputs, outputs, trigger, roles, steps and unknowns. Apply to Knowledge draft, then Save. Use Knowledge links for exact captured routines or saved procedure revisions; return to Knowledge and Save the links. Review separately. Edit fields prepares a revised structured record; Open record shows Knowledge and immutable history. Filters and Next page expose large inventories. Scroll commands sideways and fields vertically in narrow windows. Unknown remains unresolved; source links do not prove target execution. Detailed directions: docs/guides/Business_Process_Run_and_Test.txt.</p></section></body>'),encoding='utf-8')
print('Business process guides and explicit run/test instructions updated.')
