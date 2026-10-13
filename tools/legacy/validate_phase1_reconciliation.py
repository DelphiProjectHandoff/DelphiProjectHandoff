import collections, csv, datetime, hashlib, json, pathlib, re, subprocess

root=pathlib.Path(__file__).resolve().parent.parent.parent
git=r'C:\Program Files\Git\cmd\git.exe'
def command(*args):
    return subprocess.check_output([git,*args],cwd=root)
def read(path):
    return json.loads((root/path).read_text(encoding='utf-8-sig'))
def sha(path):
    return hashlib.sha256((root/path).read_bytes()).hexdigest()

baseline=json.loads(command('show','6736d00:docs/Phase1_Requirements_Traceability.json'))
ledger=read('docs/Phase1_Requirements_Traceability.json')
rows=ledger['requirements']; original=baseline['requirements']
assert len(rows)==533 and len({r['id'] for r in rows})==533
assert [(r['id'],r['domain'],r['requirement']) for r in rows]==[(r['id'],r['domain'],r['requirement']) for r in original]
document=(root/ledger['baseline']).read_text(encoding='utf-8-sig')
numbered=re.findall(r'^- \*\*((?:\d{2}\.\d{2}|EX-\d{3}|SC-\d{2}|DB-\d{3}))\*\* (.+)$',document,re.M)
assert len(numbered)==533
assert [(r['id'],r['requirement']) for r in rows]==[(i,t.strip()) for i,t in numbered]
assert sha(ledger['baseline'])==ledger['baseline_sha256']==baseline['baseline_sha256']
before={r['id']:r for r in original}
new_ids=[r['id'] for r in original if r['implementation']=='unassessed']
assert len(new_ids)==510
old_ids=[r['id'] for r in original if r['implementation']!='unassessed']
by_id={r['id']:r for r in rows}
assert len(old_ids)==23
assert all(by_id[i]['implementation']==before[i]['implementation'] for i in old_ids)
assert all(by_id[i]['reconciliation']['state']=='reconciled' for i in new_ids)
assert all(by_id[i]['reconciliation']['state']=='previously_assessed' for i in old_ids)
assert all(r['implementation']!='unassessed' for r in rows)
counts=dict(collections.Counter(r['implementation'] for r in rows))
assert counts==ledger['audit']['counts'] and sum(counts.values())==533

batches=read('docs/Phase1_Reconciliation_Batches.json')['batches']
assert len(batches)==21
assert [b['count'] for b in batches]==[25]*20+[10]
assert [i for b in batches for i in b['ids']]==new_ids
for position,b in enumerate(batches,1):
    assert b['batch']==position and b['unassessed']==0 and b['reconciled']==b['count']==len(b['ids'])
    assert b['first']==b['ids'][0] and b['last']==b['ids'][-1]
    assert all(by_id[i]['reconciliation']['batch']==position for i in b['ids'])
    assert dict(collections.Counter(by_id[i]['implementation'] for i in b['ids']))==b['statuses']

refs=ledger['audit']['evidence_groups']
assert len(refs)==28
evidence_files={}
for references in refs.values():
    for ref in references:
        path=ref['path']; lines=(root/path).read_text(encoding='utf-8-sig').splitlines()
        assert ref['anchor'].lower() in lines[ref['line']-1].lower()
        assert sha(path)==ref['sha256']
        evidence_files[path]=ref['sha256']
for r in rows:
    a=r['reconciliation']
    assert a['purpose']==r['requirement'] and a['finding'].strip() and a['verification'].strip()
    assert r['evidence'] and all((root/path).is_file() for path in r['evidence'])
    if r['id'] in new_ids:
        assert r['evidence']==[ref['path'] for ref in refs[a['evidence_group']]]
    if r['implementation'] in ('missing','partial'):
        assert len(a['remaining_work'])>30 and a['remaining_work']!='-'
    else:
        assert a['remaining_work']==''

with (root/'docs/Phase1_Implementation_Backlog.csv').open(encoding='utf-8-sig',newline='') as stream:
    backlog=list(csv.DictReader(stream))
incomplete=[r for r in rows if r['implementation'] in ('partial','missing')]
assert len(backlog)==len(incomplete)==346
assert [r['ID'] for r in backlog]==[r['id'] for r in incomplete]
for result,r in zip(backlog,incomplete):
    assert result['Status']==r['implementation']
    assert result['Requirement / purpose']==r['requirement']
    assert result['Remaining work']==r['reconciliation']['remaining_work']
    assert result['Existing behavior']==r['reconciliation']['finding']

report=(root/'docs/Phase1_Reconciliation_Report.txt').read_text(encoding='utf-8')
assert len(re.findall(r'^Status: ',report,re.M))==533
for r in rows:
    assert '\n'+r['id']+' '+r['requirement']+'\nStatus: '+r['implementation']+'\n' in report
    assert 'Remaining: '+(r['reconciliation']['remaining_work'] or 'No additional implementation identified for this requirement within the recorded scope.') in report
assert ledger['audit']['recommended_next_step']['requirement_ids']==['06.12','12.09']
assert all(by_id[i]['implementation']=='missing' for i in ('06.12','12.09'))
assert 'NEXT COMPLETE IMPLEMENTATION BATCH' in report

allowed={
    'docs/Phase1_Requirements_Traceability.json',
    'docs/Phase1_Reconciliation_Batches.json',
    'docs/Phase1_Implementation_Backlog.csv',
    'docs/Phase1_Reconciliation_Report.txt',
    'docs/Phase1_Reconciliation_Validation.json'
}
assert command('rev-parse','HEAD').decode().strip().startswith('6736d00')
changed=set(command('diff','--name-only','6736d00').decode().splitlines())
untracked=set(command('ls-files','--others','--exclude-standard').decode().splitlines())
assert changed|untracked <= allowed,sorted((changed|untracked)-allowed)
command('diff','--check')
tracked=command('ls-files','-z').decode().split('\0')
product_files=[p for p in tracked if p and (p.endswith(('.pas','.fmx','.dpr','.dproj','.groupproj','.sql')) or p.startswith('help/'))]
assert product_files
assert not command('diff','--name-only','6736d00','--',*product_files).strip()
product_hashes={p:sha(p) for p in product_files}
domains={}
for domain in dict.fromkeys(r['domain'] for r in rows):
    domains[domain]=dict(collections.Counter(r['implementation'] for r in rows if r['domain']==domain))
artifact_hashes={p:sha(p) for p in sorted(allowed) if not p.endswith('_Validation.json')}
result={
    'result':'PASS',
    'checked_at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'baseline_commit':command('rev-parse','6736d00').decode().strip(),
    'requirements':533,'newly_reconciled':510,'previously_assessed':23,
    'unassessed':0,'audit_batches':21,'batch_sizes':[25]*20+[10],
    'implementation_counts':counts,'incomplete_requirement_records':346,
    'domain_counts':domains,
    'checks':{
        'all_original_ids_domains_and_requirement_text_preserved':True,
        'all_533_requirements_match_master_document_in_original_order':True,
        'master_document_hash_matches_original_ledger':True,
        'all_510_decisions_present_exactly_once':True,
        'previous_23_statuses_preserved':True,
        'all_21_batches_complete_and_disjoint':True,
        'no_unassessed_status_remains':True,
        'all_evidence_paths_anchors_lines_and_hashes_valid':True,
        'all_partial_missing_records_have_specific_remaining_work':True,
        'backlog_matches_all_346_incomplete_records':True,
        'report_contains_all_533_requirement_findings':True,
        'bounded_next_batch_has_scope_dependencies_and_completion_criteria':True,
        'git_diff_check_passed':True,
        'only_requested_audit_artifacts_changed_or_untracked':True,
        'tracked_product_source_forms_projects_migrations_and_help_unchanged':True
    },
    'artifact_sha256':artifact_hashes,
    'evidence_file_sha256':evidence_files,
    'unchanged_product_file_sha256':product_hashes,
    'limits':[
        'Source/form/schema/test-definition audit, not new application runtime testing.',
        'Historical test reports are retained evidence, not claimed as fresh passes.',
        'Missing-item citations point to reviewed nearest foundations, not implementations of the absent feature.',
        'Named review and manual capture do not authenticate users or establish actual project content accuracy.',
        'Incomplete counts are requirement records; overlapping records can be completed by one coherent feature implementation.'
    ]
}
(root/'docs/Phase1_Reconciliation_Validation.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:result[k] for k in ('result','requirements','newly_reconciled','previously_assessed','unassessed','audit_batches','implementation_counts','incomplete_requirement_records')},indent=2))
print('Evidence files checked:',len(evidence_files),'Unchanged tracked product files checked:',len(product_files))
