from pathlib import Path
import ast
r=Path.cwd();tree=ast.parse((r/'bin/implement-data-quality.py').read_text(encoding='utf-8-sig'));ns={};exec(compile(ast.Module(body=[tree.body[2]],type_ignores=[]),'transform','exec'),ns)
f=ns['transform'];s=f((r/'tests/DPH.Tests.DataRetention.dpr').read_text(encoding='utf-8-sig')).replace('data-retention','data-quality').replace('DataRetention','DataQuality').replace('Retention.dpr','Quality.dpr').replace('program Retention','program Quality').replace('ArchiveOrders','CheckOrders').replace('retention-','quality-').replace('Orders retention and legal holds','Order completeness check').replace('Archival operator procedure','Data quality operator procedure').replace('inspect holds before requesting archival','inspect missing order identifiers').replace('Retention author','Quality author').replace('Retention reviewer','Quality reviewer').replace('7 years','zero missing IDs').replace("Form.DataQualityNewClick(nil);Check", "Form.DataQualityNewClick(nil);Check")
a=s.index(" Check(Body.Contains('Retention period");b=s.index(' RecordValue:=TJSONObject.Create',a)
s=s[:a]+''' Check(Body.Contains('Rule, threshold, units'),'Template captures measurable acceptance criteria');
 Check(Body.Contains('completeness, uniqueness'),'Template explains quality dimensions');
 Check(Body.Contains('Prerequisites, sampling'),'Template records sampling and limitations');
 Check(Body.Contains('Owner, operator'),'Template records responsibilities');
 Check(Body.Contains('Failure severity'),'Template records escalation and remediation');
 Check(Body.Contains('measurement time and environment'),'Template captures observation context');
 Check(Body.Contains('Unknown means unresolved'),'Template preserves unknowns');
 Check(Body.Contains('DPH database integrity is separate'),'Target quality separated from DPH storage integrity');
'''+s[b:]
s=s.replace("Body:=Body.Replace('Policy name and version: Unknown','Policy name and version: Orders v1').Replace('Retention period, units and clock-start event: Unknown','Retention period, units and clock-start event: zero missing IDs from order closure; controlled fixture only');","Body:=Body.Replace('Check name, version and purpose: Unknown','Check name, version and purpose: Orders v1').Replace('Rule, threshold, units and expected outcome: Unknown','Rule, threshold, units and expected outcome: zero missing IDs; controlled fixture only');")
s=s.replace("Form.KnowledgeBodyMemo.Text.Contains('Legal holds')","Form.KnowledgeBodyMemo.Text.Contains('Rule, threshold')")
# Import after native checks so the single-rule register checks retain their exact fixture.
a=s.index("Check(View.Document.ToJSON=Before,")
imports=''' TFile.WriteAllText(TPath.Combine(Work,'result.txt'),'missing_ids=0'+sLineBreak+'<script>do not execute</script>',TEncoding.UTF8);
 Before:=THashSHA2.GetHashStringFromFile(TPath.Combine(Work,'result.txt'));
 Denied:=False;try Store.ImportDataQualityReport(Generation,TPath.Combine(Work,'result.txt'),'','Test environment');except Denied:=True;end;Check(Denied,'Anonymous imported result rejected');
 Denied:=False;try Store.ImportDataQualityReport(Generation,TPath.Combine(Work,'result.txt'),'Reporter','');except Denied:=True;end;Check(Denied,'Missing report context rejected');
 TFile.WriteAllBytes(TPath.Combine(Work,'bad.txt'),TBytes.Create($C3,$28));
 Denied:=False;try Store.ImportDataQualityReport(Generation,TPath.Combine(Work,'bad.txt'),'Reporter','Test environment');except Denied:=True;end;Check(Denied,'Invalid UTF8 check report rejected');
 TFile.WriteAllText(TPath.Combine(Work,'nul.txt'),'a'+#0+'b',TEncoding.UTF8);
 Denied:=False;try Store.ImportDataQualityReport(Generation,TPath.Combine(Work,'nul.txt'),'Reporter','Test environment');except Denied:=True;end;Check(Denied,'NUL check report rejected');
 TFile.WriteAllText(TPath.Combine(Work,'large.txt'),StringOfChar('x',32769),TEncoding.UTF8);
 Denied:=False;try Store.ImportDataQualityReport(Generation,TPath.Combine(Work,'large.txt'),'Reporter','Test environment');except Denied:=True;end;Check(Denied,'Oversized report rejected');
 ProcedureID:=Store.ImportDataQualityReport(Generation,TPath.Combine(Work,'result.txt'),'Named reporter','Order identifiers, fixture environment, measured time unknown');
 Rows:=Store.KnowledgeJSON;try
 Row:=nil;for Value in Rows do if Value.GetValue<string>('id')=IntToStr(ProcedureID) then begin Row:=Value as TJSONObject;Break;end;
 Check(Row<>nil,'Imported check report persists as Knowledge');Check(TDPHWorkspaceView.IsDataQualityRule(Row),'Imported report has stable quality-record identity');
 Check(Row.GetValue<string>('body').Contains(Before),'Original report byte hash persists');Check(Row.GetValue<string>('body').Contains('Named reporter'),'Report contributor persists');
 Check(Row.GetValue<string>('body').Contains('missing_ids=0'),'Literal imported check result persists');Check(Row.GetValue<string>('state')='needs_review','Imported outcome remains unreviewed');
 Model:=TDPHDocumentModel.Create(View,Rows,[],[],False,False,nil,False,'maintainer');try Check(Model.Document.ToJSON.Contains('missing_ids=0'),'Publication includes imported check evidence');finally Model.Free;end;
 Form:=TDPHMainForm.Create(nil);try Form.PollTimer.Enabled:=False;Form.ChangeTimer.Enabled:=False;Form.LoadView(View.Document.Clone as TJSONObject);Form.LoadKnowledge(Rows.Clone as TJSONArray);
 Check(Form.DataQualityList.Count=2,'Native register includes rule and imported result');Form.DataQualityFilter.Text:='missing_ids=0';Form.DataQualityFilterChange(nil);Check(Form.DataQualityList.Count=1,'Native search finds saved imported result');Form.DataQualityImportClick(nil);Check(Form.StatusLabel.Text.Contains('contributor'),'Import command explains missing contributor before opening dialog');finally Form.Free;end;
 finally Rows.Free;end;
 Rows:=Store.LinkCandidates(Generation,'section','Imported check report');try Check(Rows.Count=1,'Imported result available as exact revision section link');finally Rows.Free;end;
 Check(THashSHA2.GetHashStringFromFile(TPath.Combine(Work,'result.txt'))=Before,'Imported report file unchanged');Before:=View.Document.ToJSON;
'''
s=s[:a]+imports+s[a:];s=s.replace('retention obligations','data quality checks');s=s.rstrip()+'\n';(r/'tests/DPH.Tests.DataQuality.dpr').write_text(s,encoding='utf-8-sig')
s=(r/'tools/build-data-retention.cmd').read_text().replace('DataRetention','DataQuality');(r/'tools/build-data-quality.cmd').write_text(s,encoding='utf-8')
