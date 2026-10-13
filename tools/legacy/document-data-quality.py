from pathlib import Path
r=Path.cwd();p=r/'tools/build-guides.py';s=p.read_text(encoding='utf-8-sig');pos=s.rfind('for chapters in (USER, ENGINEERING):')
chapters="""USER.append(('Record target data quality rules and check reports', [
'Choose Target data quality in the upper-right page selector after attaching a source project or opening its database. New check prepares an unsaved Knowledge draft. Enter a descriptive title and named author. Preserve the first heading and record the check purpose and version, tables/fields/files and environment, quality dimension, measurable threshold and units, prerequisites and sampling, implementing procedure and schedule, responsible owner, failure severity and remediation, observed results, evidence and remaining unknowns. Unknown is an unresolved answer and should name its responsible maintainer.',
'Use Knowledge links to attach captured semantic routines, constraints or exact procedure-section revisions. Choose entity, evidence or section, narrow the search, Find targets, select a result, choose depends_on or cites, and Add link. Return to Knowledge and Save. A typed routine name in prose is not a resolved link. Saving leaves needs_review; named review is separate. Open check returns to the saved record for editing, history and review. Implementation links opens its exact links. Search and review-state filters narrow the register; Next page covers lists exceeding 250 rows.',
'To preserve an existing check report, enter the report contributor name and the check/environment/measurement context on Target data quality, then click Import check report. Select an explicitly saved UTF-8 .txt, .log or .json extract no larger than 32 KiB. Import immediately saves a new pending-review quality record containing the literal text, contributor, context, import UTC, captured generation and original byte SHA256. No file commands or markup execute. The imported text may contain sensitive data, so prepare an appropriate focused extract first. Report measurements, timestamps and runtime origin remain contributor claims.',
'To connect a report with its rule, Open check on the rule, choose Implementation links or Knowledge links, select section and search Imported check report plus its descriptive context. Choose the exact report revision, cites and Add link, then return to Knowledge and Save. Earlier linked revisions remain exact when a report is edited. Read every report and procedure against its source; human review does not establish live data quality. Save or discard a current draft before opening another record or importing a report. DPH database integrity checks are a separate feature.',
'In a narrow window scroll each command bar horizontally to reach all commands and report fields; the labeled evidence memo scrolls independently. Detailed run, practice, import and test directions are in docs/guides/Data_Quality_Run_and_Test.txt. DPH does not run target SQL, checks or applications. Captured schema constraints and validation routines are declarations and candidates rather than observed enforcement.'
]))
ENGINEERING.append(('Maintain target data quality evidence and report imports', [
'TDPHWorkspaceView provides NewDataQualityRule, typed record recognition, metadata validation and attributed details in the existing model unit. Stable record_type data_quality and GUID rule_id identify each rule or imported report. Native controls are serialized in DPH.UI.Main.fmx for IDE editing: state/text filters, 250-row pages, command bars, contributor/context inputs, labeled evidence, New/Open, implementation links and import. Main guards unsaved Knowledge drafts and reuses existing revision, review and rich-link workflows. No helper unit, storage migration or target execution is introduced.',
'TDPHKnowledgeStore.SaveKnowledge validates quality identity, heading, business-rule kind and project maintenance/maintainer scope, rejects placeholder titles, duplicate identities, changed identities and discarded structured metadata. The body remains editable and exact prior revisions remain in history. ImportDataQualityReport reads only explicitly selected .txt/.log/.json files, checks both before/after read sizes at 32 KiB, requires round-trip UTF-8 and rejects empty/NUL text. It hashes the original bytes and saves literal text with contributor, context, UTC, generation and an explicit unverified-claim qualification through SaveKnowledge.',
'The import_data_quality worker command opens the selected store using its actual source root, imports on the existing background writer and returns saved Knowledge. Report imports do not execute a parser for report commands, SQL, scripts or target code. Publication uses the normal maintenance scope and escapes report markup in HTML; imported measurements remain unverified even when hash-consistent. Exact section links associate rule, operator procedure and imported report revisions; entity/evidence links preserve captured implementation references. DPH storage integrity and selected-data quality remain distinct.',
'Run tools/build-data-quality.cmd elevated for real parsing/persistence, identity and invalid-save cases, immutable review/edit history, implementation/procedure/result links, native filtering/paging/draft guards, compact rendering, UTF-8/size/NUL rejection, report hashes, literal HTML, full handoff validation, unchanged source/catalog and actual background import. The worker test releases the test writer before opening the background writer. Knowledge, publishing, retention and actual application/FMX regressions cover shared paths. Fixed ignored bin/data-quality-validation holds controlled fixtures.'
]))

"""
s=s[:pos]+chapters+s[pos:];s=s.replace("'guide_version': 32","'guide_version': 33").replace(".replace('320 requirement records remain incomplete','319 requirement records remain incomplete')",".replace('320 requirement records remain incomplete','319 requirement records remain incomplete').replace('319 requirement records remain incomplete','318 requirement records remain incomplete')").replace("'Record target data retention and archival policies', 'Compare screen history","'Record target data retention and archival policies', 'Record target data quality rules and check reports', 'Compare screen history");p.write_text(s,encoding='utf-8')
p=r/'README.md';s=p.read_text();s+='\nRequirement 05.19 adds Target data quality: attributed rules, thresholds, owners and implementing links, plus safe import of saved UTF-8 check reports with original byte hashes, review/history and exact report-revision citations. See docs/guides/Data_Quality_Run_and_Test.txt. No target check or SQL executes.\n';p.write_text(s,encoding='utf-8')
p=r/'help/index.html';s=p.read_text().replace('</body>','<section><h2>Target data quality</h2><p>Choose Target data quality. New check prepares an unsaved attributed rule with scope, quality dimension, threshold, sampling, owner, procedure, remediation and result evidence prompts. Add captured routines, constraints or exact procedure links in Knowledge links; return to Knowledge and Save. Import check report saves a selected UTF-8 .txt, .log or .json extract up to 32 KiB with contributor, context, UTC, generation and original SHA256. Enter contributor and context first. Link the report to a rule using section and cites, then Save. Outcomes remain contributor claims; named review is separate. Use filters and Next page beyond 250 records. Scroll command bars horizontally and the evidence memo vertically. No target checks execute. Detailed directions: docs/guides/Data_Quality_Run_and_Test.txt.</p></section></body>');p.write_text(s,encoding='utf-8')
(r/'docs/guides/Data_Quality_Run_and_Test.txt').write_text(r'''DPH TARGET DATA QUALITY RULES AND CHECK REPORTS
Last changed: 12 October 2026

START AND RECORD A RULE
1. Open File Explorer to:
   C:\New Delphi Projects\Delphi Project Handoff\bin\Win32\Debug
   Double-click DelphiProjectHandoff.exe.
2. Click Attach project and select the application's .dproj, .dpr or .groupproj,
   then save its proposed database. Or click Open cache and select its .dphdb.
3. Choose Target data quality in the upper-right page selector.
4. Click New check. In Knowledge, replace the default title with a descriptive
   check name and enter your name as author. Preserve the first body heading.
5. Fill in purpose/version, data scope/environment, quality dimension, rule,
   threshold/units, expected outcome, prerequisites/sampling/exclusions,
   procedure/schedule, owner/operator, failure/remediation, observed results,
   result evidence and remaining unknowns. Explicitly record Unknown and the
   responsible maintainer when evidence is unavailable.
6. Choose Knowledge links in the page selector. Choose entity to search an
   implementing routine; choose evidence for captured constraints/evidence;
   choose section for an existing saved operating procedure.
7. Enter a specific name, click Find targets, select the exact result, choose
   depends_on or cites and Add link. A routine labeled [semantic_routine]
   opens its captured explanation. Search returns at most 200 candidates;
   narrow the name when needed. No selected routine executes.
8. Return to Knowledge and click Save. Review separately using a named reviewer.
   Saving leaves needs_review. Edits append history and reopen review.

IMPORT AN EXISTING CHECK REPORT
9. Prepare a focused, explicitly saved UTF-8 .txt, .log or .json file of at most
   32 KiB. Remove inappropriate customer data or credentials before importing.
   DPH does not run a check for you and does not interpret report commands.
10. Save or discard any existing Knowledge draft. Return to Target data quality.
11. Enter the report contributor name and a descriptive check/environment/
    measurement context in the second command bar. Scroll it horizontally
    if the fields or Import check report button are outside the window.
12. Click Import check report and select your saved extract.
    Import saves a new attributed pending-review record immediately.
13. Find Imported check report in the register. Select it and scroll the memo
    to read the literal result, contributor, context, import UTC, generation
    and original byte SHA256. Report timestamps, environment and outcomes
    are contributor claims. A matching hash does not prove their truth.
14. Open check loads the report's saved Knowledge record for review/history.
    Its original revision remains preserved if its body is edited later.

LINK THE REPORT TO ITS RULE
15. Return to Target data quality and select the rule, then Open check.
16. Choose Knowledge links. Choose section, enter Imported check report plus
    its context, Find targets, select the exact report revision, choose cites
    and Add link. Return to Knowledge and Save.
17. Implementation links opens a selected rule's saved links. Select its report
    link and Open saved target to read that exact revision. Do the same for
    operating procedures or captured implementation evidence.
18. Filter by review state or search text. First page/Next page cover registers
    above 250 records. Scroll both command bars horizontally when necessary;
    scroll the labeled evidence memo for full details. Save or discard a draft
    before opening another record or importing another report.

CONTROLLED VALIDATION
19. Open an elevated PowerShell window and run separately:
    Set-Location -LiteralPath 'C:\New Delphi Projects\Delphi Project Handoff'
    cmd /c tools\build-data-quality.cmd
    cmd /c tools\build-wp0.cmd
20. PASS lines confirm focused actual-parser, saved-rule/report, native UI and
    background import checks, then the application/FMX baseline. FAIL or a
    compiler error means validation has not passed. Controlled practice source
    remains in bin\data-quality-validation; no real target program runs.

DPH's database integrity check concerns its own store. Target-data quality
requires target-specific rules and separately obtained observed evidence.
Captured constraints do not establish deployed enforcement or clean live data.
''',encoding='utf-8')
print('Updated quality directions, help and source-based guides')
