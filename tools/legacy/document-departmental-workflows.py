from pathlib import Path
p=Path('tools/build-guides.py');s=p.read_text(encoding='utf-8');a=s.index('def field(')
chapters='''USER.append(('Record departmental workflows', [
'Open the intended project or its database and choose Departmental workflows in the upper-right page selector. Click New workflow. In Workflow fields enter a named contributor, descriptive name, accountable owner, department scope, trigger and prerequisites, and unresolved questions with their responsible maintainer. Scroll down to Ordered steps. The contributor records the account; the accountable owner is a separate role.',
'Click New step. Enter its department, responsible role, descriptive action, inputs and origins, outputs and recipients, handoff to the next department or role, and exception handling or recovery. Unknown remains an unresolved value. Choose the Exception destination from Unknown, End or an existing named step. Click Apply step. This updates the local workflow draft and does not save the database. Repeat to add the next step. Normal order follows the list; the last step ends the authored sequence.',
'Select a step to edit it, then Apply step. Move up and Move down reorder the normal sequence while retaining stable exception destinations. Remove step refuses removal while another step refers to it as an exception destination; edit that referring step first. Apply or Discard step edits before selecting, adding, removing or moving another step. Discard step edits abandons the current step changes. Cancel discards the entire workflow draft.',
'Click Apply workflow to draft, then click Save on Knowledge. Save refuses an unapplied editor to avoid losing field changes. Use Knowledge links with section and cites to link an exact saved business-process or procedure revision; use entity and depends_on for captured implementing routines. Return to Knowledge and Save the links. Review separately using a named reviewer. Open record shows saved Knowledge and immutable history; Edit fields restores the structured workflow for a new revision.',
'Filter by workflow, department, role, action or review state. First page and Next page navigate inventories larger than 250 records. Scroll command bars horizontally and the editor vertically in narrow windows. Each workflow contains 1 through 64 steps, with a 64 KiB structured-record limit. Workflow fields accept 4096 characters, the name 200 and step fields 2048. Split a larger account into explicitly linked workflows. Unknown destinations remain visible rather than invented.',
'Publish with maintenance or all audience to include the canonical ordered steps and attributed exception paths, subject to exclusions and redaction. DPH never executes a business workflow; content review does not grant business authorization or prove success. Detailed run, practice and test directions are in docs/guides/Departmental_Workflow_Run_and_Test.txt.'
]))
ENGINEERING.append(('Maintain ordered departmental workflow evidence', [
'TDPHWorkspaceView provides departmental_workflow metadata, canonical workflow GUID, five workflow fields and an ordered steps array. Each step has a canonical GUID, department, role, action, inputs, outputs, handoff, exception handling and exception destination. Validation rejects duplicate identities, dangling destinations, unknown shapes, invalid types, empty or oversized fields, unspecified actions, missing steps and exceeded limits. Normal authored order follows the array; exception identity remains stable across reordering.',
'SaveKnowledge requires project-scoped maintenance business-rule records, stable title matching the structured name, canonical generated body, unique workflow identity and optimistic revisions. Existing immutable save/review history, source invalidation, exact section/source links, named contributors and reviewers, publication and reopening apply. No new schema or helper unit is added. Human workflow content and named review do not establish target execution, business authorization or successful outcomes.',
'The register and workflow/step fields are native serialized controls in DPH.UI.Main.fmx. New/Edit create a local structured draft; Apply step modifies that draft; Apply workflow prepares Knowledge; Save persists it. Shared nonmodal editor guards prevent saving unapplied fields and bind edits to the original record. New/discarded Knowledge frees its workflow draft. Compact commands scroll horizontally and fields vertically. Array replacement/reordering uses the RTL TJSONArray.SetElements ownership contract while retaining or freeing element values appropriately.',
'Run tools/build-departmental-workflow.cmd elevated. The real parser, SQLite reopening, revision/review and canonical publication fixture covers ordered Sales/Warehouse steps, roles, handoff, recovery destination, malformed records, invalid identities, dangling/duplicate destinations, bounds, source/procedure links and unchanged source/catalog. Native FMX exercises add/apply/remove protection, reordering, dirty-step and unapplied-workflow guards, editor/register navigation and compact renders. Compatibility covers Knowledge, publishing, data quality and the business-process editor plus the actual application/FMX build. Fixtures remain in the fixed ignored bin/departmental-workflow-validation directory.',
'This implements departmental workflow capture. The separate end-to-end process-diagram requirement remains pending; technical code graphs are not substituted for business workflow diagrams.'
]))

'''
s=s[:a]+chapters+s[a:];s=s.replace("'guide_version': 35","'guide_version': 36").replace(".replace('317 requirement records remain incomplete','316 requirement records remain incomplete')",".replace('317 requirement records remain incomplete','316 requirement records remain incomplete').replace('316 requirement records remain incomplete','315 requirement records remain incomplete')");p.write_text(s,encoding='utf-8')
Path('docs/guides/Departmental_Workflow_Run_and_Test.txt').write_text(r'''DPH DEPARTMENTAL WORKFLOWS
Last changed 12 October 2026

RUN AND RECORD
1. In File Explorer open C:\New Delphi Projects\Delphi Project Handoff\bin\Win32\Debug.
   Double-click DelphiProjectHandoff.exe. Attach the application's project and
   save its proposed database under Databases, or Open cache for its .dphdb.
2. Wait for analysis. Choose Departmental workflows in the upper-right page
   selector. Click New workflow. Enter a named contributor, descriptive name,
   accountable owner, department scope, trigger and unknowns in Workflow fields.
3. Scroll down to Ordered steps. Click New step. Complete department, role,
   action, inputs, outputs, handoff and exception handling. Enter Unknown where
   facts are unavailable. Choose Exception destination: Unknown, End or a named
   existing step. Click Apply step. Repeat for each ordered step.
4. Select a saved-in-draft step to edit it; click Apply step. Move up / Move
   down changes normal order and preserves exact exception targets. Remove step
   refuses removal of another step's exception target: change that reference
   first. Apply or Discard step edits before selecting/replacing another step.
5. Scroll command bars sideways in narrow windows and fields vertically.
   Click Apply workflow to draft. Choose Knowledge and click Save. Apply alone
   does not save. Save refuses an unapplied editor; Cancel discards its draft.
6. Choose Knowledge links. For an existing business-process or procedure record
   choose section, enter its title, Find targets, select its exact revision,
   choose cites and Add link. For an implementing routine choose entity, search
   its name, select the captured result, choose depends_on and Add link.
   Return to Knowledge and Save. A name in prose alone is not an exact link.
7. Enter a named reviewer and verify only after checking the business account
   and evidence. Review does not grant business authorization or prove success.
8. Return to Departmental workflows. Open record shows Knowledge and history;
   Edit fields restores a workflow for revision. Apply steps, Apply workflow,
   Save and review again. Filter by department, role, action or state. First
   page / Next page exposes more than 250 records. Implementation links opens
   the saved exact links. Save or discard a draft before opening another record.

REPEATABLE PRACTICE
Use a disposable documentation database. Create Order fulfilment workflow, owner
Operations manager. Add Check approved order in Sales with role Order clerk,
input Approved order and handoff Validated order to Warehouse. Apply step.
Add Dispatch order in Warehouse with role Dispatch operator and exception
handling Return missing approval to Sales. Choose Check approved order as its
exception destination. Apply step, Apply workflow and Save. Link the relevant
actual source routine and saved business-process/procedure revisions; Save and
review. Close/reopen the database and confirm ordered fields, links and history.
Edit fields: moving the first step down must keep the exception destination
attached to its named step. Removing the referenced step must be refused until
you change its referring exception destination. Cancel this practice edit or
Apply workflow and Save it as another pending-review revision. Publish to a new
folder with maintenance/all audience and inspect ordered steps in index.html.
Do not insert unchecked practice claims into production documentation.

LIMITS AND CHECKS
One workflow has 1 to 64 steps and at most 64 KiB structured JSON. Name allows
200 characters, workflow fields 4096 each, and step fields 2048 each. Split larger
accounts into explicitly linked workflows. No JSON editing is required.

Open an elevated Command Prompt and run:
  cd /d "C:\New Delphi Projects\Delphi Project Handoff"
  tools\build-departmental-workflow.cmd
A nonzero exit or FAIL is a failure. Inspect docs\phase1-departmental-workflow-
validation.log and validation.json. Fixed ignored fixtures reside under
bin\departmental-workflow-validation. Run tools\build-wp0.cmd for actual app and
FMX checks. No selected target executable, SQL, service or job is executed.
''',encoding='utf-8')
p=Path('README.md');p.write_text(p.read_text(encoding='utf-8')+'\nRequirement 06.02 adds Departmental workflows with native ordered step editing, roles, handoffs, explicit exception destinations, named review/history and exact source/procedure links. See docs/guides/Departmental_Workflow_Run_and_Test.txt. Save now refuses unapplied structured editor fields.\n',encoding='utf-8')
p=Path('help/index.html');p.write_text(p.read_text(encoding='utf-8').replace('</body>','<section><h2>Departmental workflows</h2><p>Choose Departmental workflows and New workflow. Complete its named contributor and workflow fields, scroll to Ordered steps and New step. Enter department, responsible role, action, inputs, outputs, handoff and exception handling; choose a named exception destination, End or Unknown. Apply step, then add or reorder other steps. Apply workflow prepares Knowledge; Save persists it. Save refuses an unapplied editor. Link exact business-process, source and procedure evidence on Knowledge links and Save again; review separately. Removing a referenced exception target is refused. Commands scroll sideways and fields vertically. Detailed instructions: docs/guides/Departmental_Workflow_Run_and_Test.txt.</p></section></body>'),encoding='utf-8')
s=Path('bin/verify-business-process-guides.py').read_text(encoding='utf-8').replace("guide_version']==35","guide_version']==36").replace('Inventory business processes','Record departmental workflows').replace('Maintain structured business process records','Maintain ordered departmental workflow evidence').replace('business-process-guide-check','departmental-workflow-guide-check');Path('bin/verify-departmental-workflow-guides.py').write_text(s,encoding='utf-8')
s=Path('bin/compare-business-guide-pages.py').read_text(encoding='utf-8').replace('BusinessProcesses_PreChange_20261012_192606','DepartmentalWorkflows_PreChange_20261012_194558').replace('business-guide-page-comparison','departmental-workflow-guide-page-comparison');Path('bin/compare-departmental-workflow-guide-pages.py').write_text(s,encoding='utf-8')
print('Departmental workflow guides, HTML help and explicit run/test directions updated.')
