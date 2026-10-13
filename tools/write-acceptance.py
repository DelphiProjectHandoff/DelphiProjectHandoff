"""Write explicit WP7 acceptance accounting from measured test evidence."""
from pathlib import Path
import json
import hashlib
import re
from datetime import datetime, timezone

root = Path(__file__).resolve().parent.parent
measurement = json.loads((root/'docs/validation/reports/completion-hardening-validation.json').read_text(encoding='utf-8-sig'))
inputs = json.loads((root/'docs/validation/reports/completion-input-validation.json').read_text(encoding='utf-8-sig'))
regression = json.loads((root/'docs/validation/reports/completion-regression-validation.json').read_text(encoding='utf-8-sig'))
if (inputs['test_exit'] != 0 or inputs['changed_files'] or measurement['checks_passed'] != 32
        or regression['changed_files'] or not regression['suites']
        or any(s['exit_code'] != 0 for s in regression['suites'])):
    raise RuntimeError('Final WP7 evidence is not passing')
analyzer = re.search(r"DPH-WP3-\d+", (root/'DPH.Analysis.Model.pas').read_text(encoding='utf-8-sig')).group()
publisher = re.search(r"DPH-LEARNING-\d+", (root/'DPH.Publish.Model.pas').read_text(encoding='utf-8-sig')).group()
cases = [
('AT-01','pass','Cached facts displayed before source verification',f"Reference cache retained its exact generation; measured {measurement['reference_cached_ms']} ms",'wp7-build.log'),
('AT-02','pass','Parsed form hierarchy and inspection','Serialized hierarchy/properties and approximate screens exercised; no untrusted component construction','wp7-regression.log'),
('AT-03','pass','btnConvert event resolves to handler','Pinned form binding and source-backed handler identity demonstrated','wp3-reference-validation.json'),
('AT-04','pass','Procedure signature and evidence inspector','Semantic signatures/ranges/references and reference FMX inspector exercised','wp7-build.log'),
('AT-05','pass','Qualified asynchronous conversion chain','Event, anonymous worker, ConversionThreadProc and engine chain retained with explicit certainty','wp3-reference-validation.json'),
('AT-06','partial','Accurate complex procedure flowchart with independent source review','Supported structured CFG tests pass; independent complex-reference flow review remains outstanding','WP7_Maintenance_Exercise.txt'),
('AT-07','pass','Evidence-qualified report lineage','Typed report-model rendering is inferred; actual call facts carry source ranges and certainty','wp3-reference-validation.json'),
('AT-08','pass','Gallery fit native zoom and full-screen reconstruction','All five screen modes rendered on controlled fixture; approximation explicitly labelled','wp7-regression.log'),
('AT-09','pass','Search canonical objects and guarded source navigation','Reference handler search/inspector passes; detached source does not follow cached paths; live source requires hash match','wp7-build.log'),
('AT-10','pass','Reverse calls retain provenance','Reverse-reference and bounded impact contract checks pass','wp3-validation.json'),
('AT-11','pass','Modification flag separate from stale state','Controlled copied-source edits set independent persistent flags','wp7-regression.log'),
('AT-12','pass','Automatic reassessment and equivalent facts','Worker detects edits/configuration; bounded routine reuse and exact full/incremental reference semantic equivalence pass','wp7-build.log'),
('AT-13','pass','Human knowledge survives reparse and portability','Immutable authored/review history survives capture/restore and verified relocation','wp7-build.log'),
('AT-14','pass','Unsupported and unavailable analysis stays explicit','Reference is partial with diagnostic cap; partial generations retain prior complete head','wp7-build.log'),
('AT-15','partial','Consistent engineering/user views and complete eligible manuals','Canonical HTML/DOCX/PDF generation and integrity pass; missing business/end-user procedures require attributed human content and review','WP6_Acceptance.txt'),
('AT-16','pass','Selected sources remain byte-for-byte unchanged',f"{inputs['checked_files']} pinned, fixture and instruction inputs unchanged before/after hardening; full regression input proof also passes",'wp7-input-validation.json'),
('AC-17','pass','Same-input full/incremental equivalence','Exact semantic graph hash equality through repeated normalized reference captures','wp7-build.log'),
('AC-18','pass','Generation-consistent source evidence','SQLite constraints and rehashed cross-generation export rejection; correct source hash/ranges enforced','wp7-build.log'),
('AC-19','pass','Compiler configuration variants stay distinct','Conditional/unknown branch and configuration-context tests pass; reference defines explicitly pinned','wp3-validation.json'),
('AC-20','pass','Scoped missing dependency reported','Unavailable dependencies stay bounded and visible, without arbitrary neighboring discovery','wp7-regression.log'),
('AC-21','pass','Interrupted analysis/migrations recover safely','Forced termination, atomic publish rollback, failed migration repair and retained manual notes tested','wp7-regression.log'),
('AC-22','pass','Controlled secret and injection negatives cannot escape','Current publishing suite exercises credential redaction, exclusions, encoded text, source browsing, localized fallbacks and navigation restrictions; not a universal secret detector','wp7-regression.log'),
('AC-23','pass','Verified relocation preserves logical identity','Exact manifest move preserves symbols/ranges/notes; changed copy rejected; moved adjacent cache validates','wp7-build.log'),
('AC-24','pass','Successful reparse cannot approve human knowledge','Review stays pending after source/configuration change and source relocation','wp7-regression.log'),
('AC-25','not_run','First-time programmer investigates without author help','Human participant/reviewer unavailable; prepared worksheet is not a completed exercise','WP7_Maintenance_Exercise.txt'),
]
records = []
for test_id, result, expected, observed, evidence in cases:
    evidence = {
        'wp7-build.log': 'completion-hardening.log',
        'wp7-regression.log': 'completion-regression-validation.json',
        'wp7-input-validation.json': 'completion-input-validation.json',
        'wp3-reference-validation.json': 'rework-wp3-reference-validation.json',
        'wp3-validation.json': 'rework-wp3-validation.json',
        'WP6_Acceptance.txt': 'Implementation_Completion_Tracker.txt',
    }.get(evidence, evidence)
    path = root/'docs'/evidence
    records.append(dict(test_id=test_id, result=result, expected=expected, observed=observed,
        fixture='Pinned VCL2FMXConverter v6.0.0 plus controlled synthetic fixtures',
        reference_commit=inputs['reference_commit'], source_fingerprint='85af5e4f63dbf775e6b1dc70b03c53cf33d91f1cb8c5d203118d0b6c7b3490d3',
        configuration='Debug/Win32; MSWINDOWS;WIN32 for pinned reference', compiler=inputs['compiler'], schema_version=inputs['schema_version'],
        analyzer=analyzer, publication_template=publisher, expected_behavior=expected,
        evidence='docs/'+evidence, evidence_sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
        reviewer='Codex automated/source review; independent human gates explicitly outstanding',
        timestamp=inputs['validated_utc'], defect_or_followup='See maintenance exercise' if result!='pass' else None))
report = dict(schema_version=1, generated_utc=datetime.now(timezone.utc).isoformat(), tests=records,
    counts={state:sum(r['result']==state for r in records) for state in ['pass','partial','not_run','fail']},
    formal_product_acceptance='NOT COMPLETE; partial and not-run are not pass',
    performance_budget_acceptance='not_run; hardware recorded and measurements supplied; release budgets not agreed',
    measurements=measurement)
(root/'docs/validation/reports/completion-acceptance-matrix.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print(report['counts'])
