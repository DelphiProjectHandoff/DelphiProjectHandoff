from pathlib import Path
p=Path('DPH.UI.Main.fmx');s=p.read_text();s=s.replace("Text = 'Saved recovery plan, attribution and review state (scroll for details)'","Text = 'Saved recovery plan and review evidence'");p.write_text(s,encoding='utf-8')
p=Path('tests/DPH.Tests.TargetRecovery.dpr');s=p.read_text(encoding='utf-8-sig').replace('Template explains retention period and clock trigger','Template captures recovery point objective').replace('Template captures archive destination and permissions','Template captures backup destination and retention').replace('Template separates archival from disposal','Template captures restoration steps').replace('Controlled target retention requirements','Controlled target recovery requirements').replace('Attributed manual target-data retention policies with captured implementation links; legal compliance and runtime jobs remain unverified.','Attributed target backup/restore requirements and recovery-test claims with source links; target jobs and reported success remain unverified.');p.write_text(s,encoding='utf-8-sig')
p=Path('tools/build-guides.py');s=p.read_text();a=s.rfind('for chapters in (USER, ENGINEERING):');chapters="""USER.append(('Record backup and restoration requirements', [
'After attaching the selected application or opening its saved database, choose Target backup and restore in the upper-right page selector. This register documents the selected application. DPH portable database backups remain on Database tools and serve a separate purpose. New plan opens an unsaved Knowledge draft. Enter a descriptive title and named author and preserve the first heading.',
'Complete the data scope, recovery point objective and maximum acceptable data loss, recovery time objective and priority, backup type and consistency, schedule, destination, retention and offsite copies, encryption and key responsibility, prerequisites and dependency order, restoration steps, rollback criteria and responsible operators. Unknown remains unresolved and should name the responsible maintainer. Avoid credentials and actual customer data.',
'Record each recovery test with its date, isolated environment, operator, backup identity or hash, measured recovery time and recovered point, acceptance checks, failures, corrective action, reviewer and evidence. These are attributed claims. Use Knowledge links to attach captured backup or restore routines with entity and depends_on, or exact operating procedure and recovery-test evidence revisions with section and cites. Return to Knowledge and Save. A name in prose alone does not create an implementation link.',
'Save creates a needs_review revision. Review separately against evidence using a named reviewer. Open plan returns to its saved Knowledge record for editing and history; Implementation links opens the exact links. Filters search plan text and review state. First page and Next page navigate more than 250 plans. Scroll the command bar horizontally in narrow windows and the labeled evidence memo vertically. Save or discard an existing draft before starting or opening another plan.',
'DPH never runs a target backup or restoration or proves that a recovery test succeeded. Publishing with the maintenance or all audience includes the attributed plan subject to exclusions and redaction. Explicit run, practice and test instructions are in docs/guides/Target_Recovery_Run_and_Test.txt.'
]))
ENGINEERING.append(('Maintain target backup and restoration evidence', [
'TDPHWorkspaceView provides the recovery template, typed metadata validation, recognition and readable attribution. record_type target_recovery and a stable GUID plan_id identify each plan independently of its editable body. TDPHKnowledgeStore.SaveKnowledge enforces the first heading, descriptive stable title, project business-rule and maintenance scope, unique identity and existing optimistic revisions. Named reviews and edits preserve exact prior bodies and evidence links; unknowns remain explicit.',
'TargetRecovery controls in DPH.UI.Main.fmx are serialized for IDE and Object Inspector editing. The register provides state and text filters, 250-row pages, labeled scrolling evidence, New/Open and the existing exact-link editor. It borrows saved Knowledge rows and clears them before replacement; it guards unsaved drafts. No helper unit, migration, runtime control construction or target backup/restore execution is introduced.',
'The controlled tests parse a real Recovery.dpr and RestoreOrders routine, persist requirements and attributed test measurements, exercise invalid/duplicate/stale saves, immutable review/edit history, source and exact procedure links, canonical and escaped HTML publication, full bundle validation, native editing/navigation/filtering/paging and compact layout. Knowledge, publishing and data-quality regression suites and the actual app/FMX baseline cover shared paths. Run tools/build-target-recovery.cmd elevated. Fixtures remain under fixed ignored bin/target-recovery-validation.',
'DPH portable database backup and selected-application recovery requirements are separate. Written measurements are contributor claims, and a stored hash does not authenticate their origin or prove recovery. Existing section links can pin a saved evidence revision. The embedded-NUL report rejection fixture uses an ordinary filename, embedded-nul.txt, to avoid Windows device-name behavior while testing the actual NUL bytes.'
]))

""";s=s[:a]+chapters+s[a:];s=s.replace("'guide_version': 33","'guide_version': 34").replace(".replace('319 requirement records remain incomplete','318 requirement records remain incomplete')",".replace('319 requirement records remain incomplete','318 requirement records remain incomplete').replace('318 requirement records remain incomplete','317 requirement records remain incomplete')");p.write_text(s,encoding='utf-8')
Path('docs/guides/Target_Recovery_Run_and_Test.txt').write_text(r'''DPH TARGET BACKUP AND RESTORATION REQUIREMENTS
Last changed 12 October 2026

1. In File Explorer open C:\New Delphi Projects\Delphi Project Handoff\bin\Win32\Debug
   and double-click DelphiProjectHandoff.exe.
2. Click Attach project, select the application's .dproj/.dpr/.groupproj and
   save the proposed .dphdb. Or click Open cache and select its existing database.
3. Choose Target backup and restore in the upper-right page selector.
4. Click New plan. In Knowledge enter a descriptive title and your author name.
   Preserve the first heading. Complete each requirement prompt or explicitly
   state Unknown and the maintainer responsible for resolving it.
5. Record data scope; RPO (maximum acceptable data loss) and RTO (maximum recovery
   duration) with units; backup type, consistency and schedule; destinations,
   retention/offsite copies; permissions/encryption/key responsibility; restore
   prerequisites/dependency order; restoration/rollback steps; operators/owner.
6. Record recovery-test date/environment/operator/backup identity or hash,
   measured time/recovered point, acceptance checks, failures and corrective
   action, reviewer and evidence. Describe observations as attributed claims.
7. Choose Knowledge links. Choose entity, type the implementing routine name,
   click Find targets, select its [semantic_routine] result, choose depends_on
   and click Add link. For a saved procedure or test-evidence record, choose
   section, search its title, select the exact revision, choose cites and Add link.
   Narrow the search when needed; at most 200 candidates are returned.
8. Return to Knowledge and click Save. Body and links are unsaved until Save.
   Named review is a separate action. Edits reopen review and retain history.
9. Return to Target backup and restore. Select the plan to read the labeled memo.
   Open plan loads the saved record; Implementation links opens its exact links.
   Filter by state or plan text. Use First page/Next page beyond 250 plans.
   Scroll the command bar horizontally in a narrow window; scroll the memo
   vertically for complete evidence. Save or discard drafts before switching.
10. Publish with maintenance or all audience to include the attributed plan
    subject to export exclusions and redaction. Review published content.

CONTROLLED TESTS AND PRACTICE
11. Open an elevated PowerShell window and run these commands separately:
    Set-Location -LiteralPath 'C:\New Delphi Projects\Delphi Project Handoff'
    cmd /c tools\build-target-recovery.cmd
    cmd /c tools\build-wp0.cmd
    A FAIL or compiler error means the corresponding validation failed.
12. For practice attach the controlled fixture created by the focused suite:
    C:\New Delphi Projects\Delphi Project Handoff\bin\target-recovery-validation\source\Recovery.dpr
    Create a practice plan and link Main.RestoreOrders [semantic_routine].
    This empty fixture routine does not actually restore data.

DPH never executes selected target backups, restores, SQL or jobs. Requirements
and test results are attributed human evidence. Review does not prove successful
recovery. DPH's own portable database backup remains separate on Database tools.
''',encoding='utf-8')
p=Path('README.md');p.write_text(p.read_text()+'\nRequirement 05.20 adds Target backup and restore: attributed requirements, recovery objectives, operational responsibility, exact source/procedure links and recovery-test evidence. See docs/guides/Target_Recovery_Run_and_Test.txt. Target jobs never execute.\n',encoding='utf-8')
p=Path('help/index.html');p.write_text(p.read_text().replace('</body>','<section><h2>Target backup and restore</h2><p>Choose Target backup and restore. New plan opens a Knowledge draft. Enter a descriptive title and named author; complete scope, RPO/RTO, backup schedule/destination/security, restoration steps, operators and attributed recovery-test evidence. Use Knowledge links for implementing routines or exact saved procedure/evidence revisions, return to Knowledge and Save. Review separately. Open plan edits a saved record; Implementation links opens exact links. Filters and Next page cover large registers; the command bar scrolls horizontally and the evidence memo vertically. DPH never executes target backup or restore jobs. Its own database backup is separate. Detailed directions: docs/guides/Target_Recovery_Run_and_Test.txt.</p></section></body>'),encoding='utf-8')
