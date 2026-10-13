from pathlib import Path
r=Path.cwd();s=(r/'tests/DPH.Tests.DatabaseOperations.dpr').read_text(encoding='utf-8-sig')
s=s.replace('DatabaseOperations','DatabaseTransactions').replace('database-operations','database-transactions').replace('Database operations','Database transactions')
s=s.replace('BinaryDB, Shadow; begin','BinaryDB, Shadow, TxTrace, TxShadow; begin')
needle=" for Text in ['Remote','Touch','BinaryDB'] do"
fixture=""" TFile.WriteAllText(TPath.Combine(Fixture,'TxTrace.pas'),String.Join(sLineBreak,[
 'unit TxTrace; interface uses Data.DB, FireDAC.Comp.Client, Data.Win.ADODB, Data.SqlExpr, IBX.IBDatabase;',
 'type TCustomConnection = class(TFDConnection); TTx = class',
 ' C, Other: TFDConnection; Tx: TFDTransaction; ADO: TADOConnection; SQLConn: TSQLConnection; IB: TIBTransaction; Q: TFDQuery; Flag: Boolean;',
 ' procedure Work; procedure Cleanup; procedure Branches; procedure Missing; procedure Cross; procedure Retain; procedure ADOWork; procedure SQLWork; procedure Derived;',
 'end; implementation',
 'procedure TTx.Work; begin C.StartTransaction; try Q.ExecSQL; C.Commit; except C.Rollback; raise; end; end;',
 'procedure TTx.Cleanup; begin Tx.StartTransaction; try Q.Edit; if Flag then Exit; finally Tx.Rollback; end; end;',
 'procedure TTx.Branches; begin C.StartTransaction; if Flag then C.Commit else C.Rollback; end;',
 'procedure TTx.Missing; begin C.StartTransaction; Q.Refresh; end;',
 'procedure TTx.Cross; begin C.StartTransaction; Other.Commit; C.Rollback; end;',
 'procedure TTx.Retain; begin Tx.StartTransaction; Tx.CommitRetaining; Tx.RollbackRetaining; IB.StartTransaction; IB.CommitRetaining; IB.RollbackRetaining; IB.RollbackSavepoint(''SENSITIVE_SAVEPOINT_CANARY''); IB.Rollback; end;',
 'procedure TTx.ADOWork; var Level: Integer; begin Level := ADO.BeginTrans; ADO.CommitTrans; ADO.RollbackTrans; end;',
 'procedure TTx.SQLWork; begin SQLConn.BeginTransaction; SQLConn.CommitFreeAndNil(nil); SQLConn.RollbackIncompleteFreeAndNil(nil); end;',
 'procedure TTx.Derived; var Local: TCustomConnection; begin Local.StartTransaction; Local.Commit; end;',
 'end.']),TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(Fixture,'TxShadow.pas'),String.Join(sLineBreak,[
 'unit TxShadow; interface uses FireDAC.Comp.Client; type TFDConnection = class procedure Commit; end; TOrdinary = class procedure Rollback; end;',
 'procedure Work; implementation procedure TFDConnection.Commit; begin end; procedure TOrdinary.Rollback; begin end;',
 'procedure Work; var Fake: TFDConnection; Ordinary: TOrdinary; begin Fake.Commit; Ordinary.Rollback; end; end.']),TEncoding.UTF8);
"""
assert needle in s;s=s.replace(needle,fixture+needle)
needle='procedure Render(const Name:string);'
helpers="""function TxRow(const Routine,Method:string):TJSONObject;
var V:TJSONValue;
begin Result:=nil;for V in Report.GetValue<TJSONArray>('rows') do
 if (V.GetValue<string>('role')='transaction operation') and (V.GetValue<string>('name')=Method) and V.GetValue<string>('path').Contains('.'+Routine+' /') then Exit(V as TJSONObject);
end;
function HasPath(ARow:TJSONObject;const Target,Kind:string):Boolean;
var V:TJSONValue;
begin Result:=False;for V in ARow.GetValue<TJSONArray>('transaction_paths') do
 if V.GetValue<string>('target').Contains(Target) and V.GetValue<string>('path_kind').Contains(Kind) then Exit(True);
end;
"""
s=s.replace(needle,helpers+needle)
needle=" Check(Report.GetValue<Integer>('operation_count')>=25"
tests=""" TFile.WriteAllText(TPath.Combine(Work,'transaction-inventory.json'),Report.Format,TEncoding.UTF8);
 Check(Report.GetValue<Integer>('transaction_operation_count')>=25,'Transaction requests captured from actual source');
 for Text in ['Work','Cleanup','Branches','Missing','Cross','Retain','Derived'] do begin
  Row:=TxRow(Text,'StartTransaction');Check(Row<>nil,'Begin boundary retained for '+Text);
  Check(Row.GetValue<string>('source_hash')=THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'TxTrace.pas')),'Transaction source SHA256 '+Text);
  Check(Row.GetValue<Integer>('flow_node_count')>0,'Transaction mapped to captured CFG '+Text);
  Check(not Row.GetValue<Boolean>('flow_truncated'),'Transaction paths not truncated '+Text);
 end;
 Check(HasPath(TxRow('Work','StartTransaction'),' / Commit /','normal'),'Begin reaches commit through protected normal path');
 Check(HasPath(TxRow('Work','StartTransaction'),' / Rollback /','exception'),'Begin reaches rollback through protected exception path');
 Check(HasPath(TxRow('Work','Commit'),' / Rollback /','exception'),'Commit may raise into rollback handler');
 Check(HasPath(TxRow('Work','Rollback'),'exception_exit','exception'),'Rollback and rethrow preserve exception exit');
 Check(HasPath(TxRow('Cleanup','StartTransaction'),' / Rollback /','normal'),'Normal path enters cleanup rollback');
 Check(HasPath(TxRow('Cleanup','StartTransaction'),' / Rollback /','exception'),'Error path enters cleanup rollback');
 Check(TxRow('Cleanup','Rollback').GetValue<Integer>('flow_node_count')>1,'Finalizer pending transfers remain separate CFG copies');
 Check(HasPath(TxRow('Branches','StartTransaction'),' / Commit /','conditional'),'Conditional commit path retained');
 Check(HasPath(TxRow('Branches','StartTransaction'),' / Rollback /','conditional'),'Conditional rollback alternative retained');
 Check(HasPath(TxRow('Missing','StartTransaction'),'normal_exit without another explicit boundary','normal'),'Missing local completion remains visible');
 Check(HasPath(TxRow('Cross','StartTransaction'),' / Rollback /','normal'),'Different receiver commit is not an ending for this transaction');
 Check(not HasPath(TxRow('Cross','StartTransaction'),' / Commit /','normal'),'Receiver boundaries never paired across connections');
 Check(TxRow('Retain','CommitRetaining').GetValue<string>('operation_kind')='commit retaining request','Commit retaining distinguished');
 Check(TxRow('Retain','RollbackRetaining').GetValue<string>('operation_kind')='rollback retaining request','Rollback retaining distinguished');
 Check(TxRow('Retain','RollbackSavepoint').GetValue<string>('operation_kind')='rollback savepoint request','Savepoint rollback distinguished');
 Check(TxRow('ADOWork','BeginTrans')<>nil,'ADO return-valued BeginTrans without parentheses captured');
 Check(TxRow('ADOWork','CommitTrans')<>nil,'ADO CommitTrans recognized');Check(TxRow('ADOWork','RollbackTrans')<>nil,'ADO RollbackTrans recognized');
 Check(TxRow('SQLWork','BeginTransaction')<>nil,'dbExpress BeginTransaction recognized');
 Check(TxRow('SQLWork','CommitFreeAndNil')<>nil,'dbExpress handle commit recognized');
 Check(TxRow('SQLWork','RollbackIncompleteFreeAndNil')<>nil,'dbExpress incomplete rollback recognized');
 Check(TxRow('Derived','StartTransaction').GetValue<TJSONArray>('links').Items[0].GetValue<string>('target_id')<>'','Captured connection descendant retains exact receiver');
 for Value in Report.GetValue<TJSONArray>('rows') do if Value.GetValue<string>('role')='transaction operation' then begin
  Check(Value.GetValue<string>('source')<>'TxShadow.pas','Ordinary and locally shadowed transaction-like methods excluded');
  Check(Value.GetValue<string>('effect').Contains('unobserved') or Value.GetValue<string>('effect').Contains('raise') or Value.GetValue<string>('effect').Contains('review'),'Transaction outcome remains qualified');
 end;
 Check(TDPHDatabaseConnections.Describe(TxRow('Work','StartTransaction')).StartsWith('TRANSACTION PATHS'),'Path explanation appears before generic configuration');
 Check(not Report.ToJSON.Contains('SENSITIVE_SAVEPOINT_CANARY'),'Savepoint argument never copied to inventory');
"""
s=s.replace(needle,tests+needle)
needle=" Form.WorkspaceTabs.ActiveTab:=Form.DatabaseInventoryTab;Form.Show;"
ui=""" Form.DatabaseInventoryKind.ItemIndex:=Form.DatabaseInventoryKind.Items.IndexOf('transaction operation');Form.DatabaseInventoryFilter.Text:='.Work / StartTransaction';Form.DatabaseInventoryFilterChange(nil);
 Check(Form.DatabaseInventoryList.Count=1,'Native transaction filter finds exact begin boundary');
 Check(Form.DatabaseInventoryMemo.Text.StartsWith('TRANSACTION PATHS'),'Native transaction details explain paths first');
 Check(Form.DatabaseInventoryMemo.Text.Contains('possible exception path'),'Native details show possible rollback exception path');
 Check(Form.DatabaseInventorySource.Enabled,'Transaction source navigation available');
 for I:=0 to Form.DatabaseInventoryLinks.Items.Count-1 do if Form.DatabaseInventoryLinks.Items[I].Contains('possible normal path') and Form.DatabaseInventoryLinks.Items[I].Contains(' / Commit /') then Form.DatabaseInventoryLinks.ItemIndex:=I;
 Form.DatabaseInventoryFollowClick(nil);Check(Form.DatabaseInventoryMemo.Text.Contains('COMMIT REQUEST'),'Native follow opens the next transaction boundary');
 Form.DatabaseInventoryFilter.Text:='.Work / StartTransaction';Form.DatabaseInventoryFilterChange(nil);
"""
s=s.replace(needle,ui+needle)
(r/'tests/DPH.Tests.DatabaseTransactions.dpr').write_text(s,encoding='utf-8')
cmd=(r/'tools/build-database-operations.cmd').read_text().replace('DatabaseOperations','DatabaseTransactions')
(r/'tools/build-database-transactions.cmd').write_text(cmd,encoding='utf-8')
