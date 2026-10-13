from pathlib import Path
r=Path.cwd()
s=(r/'tests/DPH.Tests.DataRules.dpr').read_text(encoding='utf-8-sig').replace('DataRules','DataLineage').replace('data-rules','data-lineage').replace('Data rules','Data lineage')
s=s.replace('ChangedFile,AddedNode:TJSONObject','ChangedFile,AddedNode,Trace,TraceAgain:TJSONObject')
s=s.replace("'unit Main; interface uses System.SysUtils, Data.DB;", "'unit Main; interface uses System.SysUtils, System.IOUtils, Data.DB;")
s=s.replace("' OutputAmount := InputAmount * 1.2;',", "' OutputAmount := InputAmount * 1.2;', ' InputAmount := OutputAmount;', ' TFile.WriteAllText(''SENSITIVE_DESTINATION_CANARY.txt'', Normalized);',")
s=s.replace("' object CodeEdit: TDBEdit'", "' object MixedEdit: TDBEdit','  DataSource = Source','  BindSource = EmptySource','  DataField = ''amount''',' end', ' object EmptySource: TDataSource',' end', ' object CodeEdit: TDBEdit'")
anchor=" Check(Report.GetValue<Integer>('data_rule_count')>=16"
i=s.index(anchor)
checks=r'''
 Check(not Reference('MixedEdit','DataField').ToJSON.Contains('target_id'),'Mixed complete/incomplete source chains never invent a field target');
 Trace:=TDPHDatabaseConnections.Lineage(View,Report,Find('AmountEdit').GetValue<string>('id'),'both');
 try
  Check(Trace.GetValue<TJSONArray>('nodes').ToJSON.Contains('MainModule.Query.Amount'),'Control lineage reaches exact persistent field');
  Check(Trace.GetValue<TJSONArray>('nodes').ToJSON.Contains('ValidateAmount'),'Field lineage reaches validation procedure');
  Check(Trace.GetValue<TJSONArray>('nodes').ToJSON.Contains('InputAmount'),'Field lineage reaches captured input declaration');
  Check(Trace.GetValue<TJSONArray>('nodes').ToJSON.Contains('OutputAmount'),'Field lineage reaches captured output declaration');
  Check(Trace.GetValue<TJSONArray>('nodes').ToJSON.Contains('output_artifact'),'Lineage reaches file destination candidate');
  Check(Trace.GetValue<TJSONArray>('nodes').ToJSON.Contains('literal_output_path'),'Literal destination classification retained without projected literal');
  Check(Trace.GetValue<TJSONArray>('edges').ToJSON.Contains('derives_from'),'Captured lexical dependency direction retained');
  Check(Trace.GetValue<TJSONArray>('edges').ToJSON.Contains('context'),'Binding/procedure context distinguished from dependencies');
  Check(Trace.GetValue<TJSONArray>('edges').ToJSON.Contains('source_hash'),'Each lineage edge retains original evidence hash');
  Check(Trace.GetValue<TJSONArray>('breaks').Count>0,'Unknown handlers or scoped boundaries remain visible');
  Check(not Trace.GetValue<Boolean>('runtime_trace'),'Trace explicitly source evidence only');
  Check(not Trace.ToJSON.Contains('SENSITIVE_'),'Lineage omits literal, SQL and configuration canaries');
  Check(Trace.GetValue<TJSONArray>('nodes').Count<=200,'Cycles do not create unbounded node expansion');
  Check(TDPHDatabaseConnections.DescribeLineage(Trace).Contains('UNRESOLVED BREAKS'),'Lineage memo explains unresolved breaks');
  TraceAgain:=TDPHDatabaseConnections.Lineage(Reopened,Report,Find('AmountEdit').GetValue<string>('id'),'both');
  try Check(TraceAgain.ToJSON=Trace.ToJSON,'Reopened generation reproduces identical lineage');finally TraceAgain.Free;end;
  TFile.WriteAllText(TPath.Combine(Work,'lineage.json'),Trace.Format,TEncoding.UTF8);
 finally Trace.Free;end;
 Trace:=TDPHDatabaseConnections.Lineage(View,Report,Find('MixedEdit').GetValue<string>('id'),'both');
 try Check(Trace.GetValue<TJSONArray>('breaks').ToJSON.Contains('unresolved field or dataset chain'),'Broken field chain explicitly reported');
  Check(Trace.GetValue<TJSONArray>('breaks').ToJSON.Contains('no captured dataset'),'Empty source is an explicit chain break');
 finally Trace.Free;end;
 Trace:=TDPHDatabaseConnections.Lineage(View,Report,Find('AmountEdit').GetValue<string>('id'),'both',3);
 try Check(Trace.GetValue<TJSONArray>('nodes').Count=3,'Requested trace limit honored');Check(Trace.GetValue<Boolean>('truncated'),'Node limit reports truncation');
  Check(Trace.GetValue<TJSONArray>('breaks').ToJSON.Contains('limit reached'),'Omitted routes explicitly unresolved');
 finally Trace.Free;end;
 Trace:=TDPHDatabaseConnections.Lineage(View,Report,'not-captured','both');
 try Check(Trace.GetValue<TJSONArray>('nodes').Count=0,'Unavailable seed has no invented route');Check(Trace.GetValue<TJSONArray>('breaks').Count=1,'Unavailable seed gives a break');finally Trace.Free;end;
'''
s=s[:i]+checks+s[i:]
anchor=" Form.WorkspaceTabs.ActiveTab:=Form.DatabaseInventoryTab;Form.Show;Render("
i=s.index(anchor)
s=s[:i]+r'''
 Check(Form.DatabaseInventoryTrace.Enabled,'Selected inventory row enables Trace lineage');
 Form.DatabaseInventoryDirection.ItemIndex:=0;Form.DatabaseInventoryTraceClick(nil);
 Check(Form.DatabaseInventoryMemo.Text.StartsWith('DATA LINEAGE SOURCE CANDIDATES'),'Native lineage purpose appears first');
 Check(Form.DatabaseInventoryMemo.Text.Contains('SCOPED ROUTE NODES'),'Native memo shows scoped route nodes');
 Check(Form.DatabaseInventoryMemo.Text.Contains('CAPTURED EDGES'),'Native memo shows dependencies and context');
 Check(Form.DatabaseInventoryMemo.Text.Contains('output_artifact'),'Native memo includes destination candidate');
 Check(Form.DatabaseInventoryLinks.Items.Count>1,'Every captured route node navigable');
 for I:=0 to Form.DatabaseInventoryLinks.Items.Count-1 do if Form.DatabaseInventoryLinks.Items[I].Contains('OutputAmount') then Form.DatabaseInventoryLinks.ItemIndex:=I;
 Form.DatabaseInventoryFollowClick(nil);Check(Form.WorkspaceTabs.ActiveTab=Form.ExplainTab,'Semantic lineage hop opens real declaration explanation');
 Form.WorkspaceTabs.ActiveTab:=Form.DatabaseInventoryTab;
 Form.DatabaseInventoryTraceClick(nil);
''' +s[i:]
(r/'tests/DPH.Tests.DataLineage.dpr').write_text(s,encoding='utf-8')
s=(r/'tools/build-data-rules.cmd').read_text().replace('DataRules','DataLineage')
(r/'tools/build-data-lineage.cmd').write_text(s)
