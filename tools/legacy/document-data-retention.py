from pathlib import Path
r=Path.cwd();p=r/'tools/build-guides.py';s=p.read_text(encoding='utf-8-sig');pos=s.rfind('for chapters in (USER, ENGINEERING):');assert pos>=0
chapters="""USER.append(('Record target data retention and archival policies', [
'Start bin/Win32/Debug/DelphiProjectHandoff.exe and attach the application you want to document, or open its saved database. Choose Target data retention in the upper-right page selector. This page records the selected application\'s data obligations and archival procedures. DPH database snapshot retention remains on Database tools and is a separate feature.',
'Click New policy. DPH opens an unsaved Knowledge draft. Replace the default title with a descriptive data scope before saving; saved titles remain stable. Enter the named contributor and complete the body below its first heading. The prompts cover data categories and tables/files, policy basis, retention period and clock-start event, expiry calculation, archive trigger and schedule, archive destination and permissions, disposal, legal holds, ownership, retrieval, failure monitoring, verification evidence and remaining unknowns. Record Unknown and its responsible maintainer when a fact is unavailable.',
'To link an implementing routine, choose Knowledge links in the page selector. Select entity in the target-kind selector, enter the routine name, and click Find targets. Select the semantic_routine result, choose depends_on, then Add link. To cite an operating procedure saved in Knowledge, choose section, search its title and Add link with cites. Return to Knowledge and click Save. Links are explicit captured identities or exact section revisions; a written job name alone does not resolve an implementation link. Link search returns up to 200 candidates, so narrow the filter when necessary.',
'Return to Target data retention. Filter by review state or search policy text, contributor, scope or job. Select a saved policy to read its original contributor, current revision author, reviewer and explicit link count. First page and Next page cover registers larger than 250 policies. Scroll the toolbar sideways in a narrow window. Open policy loads the saved Knowledge record for editing and named review. Implementation links opens its saved links; select a link and Open saved target to inspect its captured routine or exact procedure revision.',
'Save creates a pending review revision. Review separately against policy evidence; editing a reviewed policy reopens review and retains earlier revisions. Save or discard an existing Knowledge draft before opening another policy. DPH does not execute archival, deletion, SQL or target jobs. Human review does not establish legal compliance or observed success; Unknown fields remain unresolved. Detailed run, practice and test commands are in docs/guides/Data_Retention_Run_and_Test.txt.'
]))
ENGINEERING.append(('Maintain attributed target retention requirements', [
'Requirement 05.18 is an attributed manual-capture workflow. TDPHWorkspaceView provides the target-policy template, typed-record recognition, metadata validation and readable evidence. Native DataRetention controls in DPH.UI.Main.fmx provide state/text filtering, bounded 250-row pages, labeled scrollable details, draft preparation and existing Knowledge/link navigation. Controls remain editable in the IDE. No helper unit, analyzer pass or storage migration is introduced.',
'Structured metadata contains record_type data_retention and a stable GUID policy_id. The existing attributed body remains editable; identity and kind stay protected. TDPHKnowledgeStore.SaveKnowledge validates metadata, rejects the default title, anonymous authors, removed heading, wrong business-rule/maintenance/maintainer scope, duplicate identities, identity changes and discarded structured metadata. Existing optimistic revisions, named review, immutable history and exact rich links remain authoritative. Unknown fields are deliberately permitted and visibly unresolved; policy prose is human evidence, not an inferred legal rule.',
'The register distinguishes original contributor from current revision editor and shows the named reviewer and explicit link count. Existing Knowledge links support captured semantic routines, evidence and exact procedure-section revisions. Publication includes these requirements and typed identities in maintenance/all-reader handoffs through existing audience and redaction rules. No source application, SQL, deletion or archive job executes. DPH snapshot controls are distinct from the selected application\'s retention requirements.',
'Run tools/build-data-retention.cmd elevated. The focused suite uses a real parsed controlled Retention.dpr capture, persisted attributed policies, metadata rejection cases, immutable review/edit history, routine and procedure links, canonical/HTML export and complete bundle validation, native paging/filtering, draft guards and compact rendering. Knowledge, publishing and file-format regressions and tools/build-wp0.cmd cover shared paths. Controlled outputs remain under ignored bin/data-retention-validation; no owner project source or catalog is modified.'
]))

"""
# Escape apostrophes inside generated single-quoted chapter paragraphs.
chapters=chapters.replace("application's", "application\\'s")
s=s[:pos]+chapters+s[pos:];s=s.replace(".replace('321 requirement records remain incomplete','320 requirement records remain incomplete')",".replace('321 requirement records remain incomplete','320 requirement records remain incomplete').replace('320 requirement records remain incomplete','319 requirement records remain incomplete')")
s=s.replace("'Inspect import and export file formats', 'Compare screen history", "'Inspect import and export file formats', 'Record target data retention and archival policies', 'Compare screen history");s=s.replace("'guide_version': 31","'guide_version': 32");p.write_text(s,encoding='utf-8')
p=r/'DPH.Workspace.Model.pas';p.write_text(p.read_text(encoding='utf-8-sig').rstrip()+'\n',encoding='utf-8')
p=r/'README.md';p.write_text(p.read_text()+'\nRequirement 05.18 adds Target data retention: attributed manual policies covering retention, archival, disposal and holds, with exact implementation/procedure links, revision history and named review. See docs/guides/Data_Retention_Run_and_Test.txt. No target archival or deletion job executes.\n',encoding='utf-8')
p=r/'help/index.html';s=p.read_text();s=s.replace('</body>','<section><h2>Target data retention</h2><p>Choose Target data retention in the page selector. New policy prepares an unsaved Knowledge draft with retention, archival, disposal, holds, ownership and verification prompts. Enter a descriptive title and named author. Use Knowledge links to attach captured semantic routines or exact operating-procedure sections, return to Knowledge and Save. Review separately. Open policy edits a saved policy; Implementation links opens its exact links. Filter by state or policy text and use Next page beyond 250 rows. Unknown facts remain unresolved. DPH snapshot retention is separate; target jobs never run. Detailed directions: docs/guides/Data_Retention_Run_and_Test.txt.</p></section></body>');p.write_text(s,encoding='utf-8')
(r/'docs/guides/Data_Retention_Run_and_Test.txt').write_text(r'''DPH TARGET DATA RETENTION AND ARCHIVAL REQUIREMENTS
Last changed: 12 October 2026

RUN AND RECORD A POLICY
1. Open File Explorer and go to:
   C:\New Delphi Projects\Delphi Project Handoff\bin\Win32\Debug
2. Double-click DelphiProjectHandoff.exe.
3. Click Attach project and select the application .dproj, .dpr or .groupproj.
   Save its proposed database when prompted. Alternatively click Open cache
   and choose its existing .dphdb.
4. In the upper-right page selector choose Target data retention.
5. Click New policy. The Knowledge page opens with an UNSAVED policy draft.
6. Replace the default title with a descriptive scope, such as
   Orders: retention and archival policy. Enter your name in the author field.
   A saved title remains stable; change the policy name/version within its body
   when revising it later. Preserve the first policy heading.
7. Complete each prompt: data categories/tables/files, policy basis, period and
   clock-start event, expiry/time zone, archive job/schedule, destination and
   permissions, disposal job/method, holds/exceptions, ownership, retrieval,
   monitoring/failures, verification evidence and remaining unknowns.
   If a fact is unavailable, explicitly record Unknown and its responsible
   maintainer. Do not copy real customer data or credentials into the policy.

LINK AN IMPLEMENTING JOB OR OPERATING PROCEDURE
8. Choose Knowledge links in the page selector. In the target-kind selector,
   choose entity. Enter the implementing routine's name and click Find targets.
9. Select its result labeled [semantic_routine], choose depends_on, and click
   Add link. Syntax records can also appear; the semantic routine provides
   the captured explanation. Search returns up to 200 candidates: narrow
   the name filter when needed. DPH does not execute the selected routine.
10. For a saved operating procedure, choose section as the target kind,
    search the procedure title, select it, choose cites and click Add link.
    This cites that exact procedure revision.
11. Return to Knowledge in the page selector and click Save. Both body and
    link edits are unsaved until Save. A named author is required.
12. Review the saved policy against evidence using the named review controls.
    Save alone leaves needs_review. A later edit creates another revision and
    reopens review. Earlier bodies, attribution and links remain in history.

INSPECT AND EDIT SAVED POLICIES
13. Return to Target data retention. Select the policy. Read the labeled memo
    for original contributor, current revision author, reviewer, exact link
    count and policy body. Scroll to see the complete body.
14. Use the review-state selector or search policy text, owner, scope or job.
    First page and Next page navigate lists over 250 policies. In a narrow
    window scroll the command bar horizontally to reach all buttons.
15. Open policy loads its saved Knowledge record for editing. Its body is
    editable; stable identity/title and document scope remain protected.
16. Implementation links opens its saved links. Select a link and click
    Open saved target to inspect the semantic routine or exact section.
17. Save or discard a current Knowledge draft before opening a different
    policy. Unknown fields remain unknown even after human review.

CONTROLLED PRACTICE AND AUTOMATED TESTS
18. Open an elevated PowerShell window and run these commands separately:
    Set-Location -LiteralPath 'C:\New Delphi Projects\Delphi Project Handoff'
    cmd /c tools\build-data-retention.cmd
    cmd /c tools\build-wp0.cmd
19. PASS lines confirm the focused actual-parser/persistence/native workflow
    and application/FM X binding checks. Any FAIL or compiler error means
    validation did not pass. The tests do not attach your real source project.
20. For practice, attach the controlled file created by the focused test:
    C:\New Delphi Projects\Delphi Project Handoff\bin\data-retention-validation\source\Retention.dpr
    Create a practice policy and link Main.ArchiveOrders [semantic_routine].
    This controlled empty routine is not a real archival implementation.
21. For a handoff, choose Publish and include the maintenance or all audience.
    Its output includes the policy and exact links subject to exclusions and
    redaction. Publish and bundle validation never execute target jobs.

LIMITS
These are attributed requirements, not discovered legal obligations. Unknown
facts and named job strings do not prove implementation, legal compliance or
successful archival/deletion. DPH never executes target jobs, SQL or disposal.
DPH's own snapshot retention is managed separately on Database tools.
'''.replace('application/FM X','application/FMX'),encoding='utf-8')
print('Updated guide sources, help and explicit run/test directions.')
