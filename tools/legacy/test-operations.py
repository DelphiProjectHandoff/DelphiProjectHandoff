exec((__import__('pathlib').Path(__file__).parent/'implement-operations.py').read_text(encoding='utf-8').split("s=read('DPH.Analysis.Symbols.pas')")[0])
s=read('tests/DPH.Tests.DatasetBindings.dpr').replace('DatasetBindings','DatabaseOperations').replace('dataset-bindings','database-operations').replace('Dataset bindings','Database operations')
s=s.replace('DPH.Workspace.Model,','DPH.Workspace.Keyboard,DPH.Workspace.Model,',1)
s=s.replace("'unit Main; interface type TMainModule = class'", "'unit Main; interface uses Data.DB, FireDAC.Comp.Client; type TCustomRecords = class(TDataSet); TOrdinary = class procedure Delete; end; TMainModule = class'")
s=s.replace("' Unserialized: TADOConnection;',", "' Unserialized: TADOConnection;',' Records: TCustomRecords;',' OrdinaryObject: TOrdinary;',' procedure Work;',")
s=s.replace("'end; implementation {$R *.dfm} end.'", "'end; implementation {$R *.dfm}', 'procedure TOrdinary.Delete; begin end;', 'procedure TMainModule.Work; var Local: TDataSet; begin', 'Query.Open; Query.Refresh; Query.First; Query.Next; Query.Locate(''CODE'', 1, []);', 'Query.Append; Query.Insert; Query.AppendRecord([1]); Query.InsertRecord([2]); Query.Edit; Query.Post; Query.Delete; Query.Cancel; Query.ApplyUpdates(0); Query.CancelUpdates;', 'Query.SQL.Text := ''SELECT a.CODE FROM A a JOIN B b ON a.CODE=b.CODE'';', 'Query.SQL.Text := ''INSERT INTO A(CODE) VALUES (1)'';', 'Query.SQL.Text := ''UPDATE A SET CODE=2'';', 'Query.SQL.Text := ''DELETE FROM A WHERE CODE=1'';', 'Query.SQL.Text := ''SELECT CODE FROM A; DELETE FROM A'';', 'Query.SQL.Text := BuildSQL;', 'Query.ExecSQL; Query.ExecSQL(''DELETE FROM A'');', 'Records.Delete; Local.Post; OrdinaryObject.Delete;', 'end; end.'")
needle=" Check(Reference('TouchLink','Control')"
at=s.index(needle)
extra=""" Check(Report.GetValue<Integer>('operation_count')>=25,'Operation inventory includes dataset API, literal SQL and dynamic SQL');
 for Text in ['Open','Refresh','First','Next','Locate','Append','Insert','AppendRecord','InsertRecord','Edit','Post','Delete','Cancel','ApplyUpdates','CancelUpdates','ExecSQL'] do begin
  Row:=Find(Text);Check((Row<>nil) and (Row.GetValue<string>('role')='database operation'),'Captured dataset request '+Text);
  Check(Row.GetValue<string>('source_hash')=THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'Main.pas')),'Operation source SHA256 '+Text);
  Check(Row.GetValue<Integer>('range.line')>0,'Operation source line '+Text);
  Check(Reference(Text,'DataSet').GetValue<string>('target_id')=Find('Query').GetValue<string>('id'),'Operation follows exact serialized dataset '+Text);
 end;
 Check(Find('Post').GetValue<string>('effect').Contains('does not prove transaction commit'),'Post never claims commit');
 Check(Find('Append').GetValue<string>('operation_kind')='insert preparation','Append distinguishes preparation from inserted row');
 Check(Find('Edit').GetValue<string>('operation_kind')='update preparation','Edit distinguishes preparation from updated row');
 Check(Find('Cancel').GetValue<string>('effect').Contains('does not establish rollback'),'Cancel never claims transaction rollback');
 Check(Find('ApplyUpdates').GetValue<string>('operation_kind')='mixed pending writes','Cached writes remain mixed');
 I:=0;for Value in Report.GetValue<TJSONArray>('rows') do if Value.GetValue<string>('role')='database operation' then begin
  Text:=Value.GetValue<string>('path');Check(not Text.Contains('OrdinaryObject'),'Ordinary Delete is not a database operation');
  if Value.GetValue<string>('name')='configured SQL' then begin
   Inc(I);Check(Value.GetValue<string>('effect').Contains('does not execute'),'SQL configuration never claims execution');
  end;
 end;
 Check(I=5,'All five literal SQL configurations retained including joins and mixed batch');
 Check(Find('dynamic SQL').GetValue<string>('operation_kind')='unknown','Dynamic SQL does not invent CRUD kind');
 Check(TDPHKeyboardInspector.ReadSource(View,TPath.Combine(Fixture,'Connections.dpr'),Find('Post'),Find('Post').GetValue<TJSONObject>('range')).Contains('Query.Post'),'Hash checked source navigation reads operation source');
"""
s=s[:at]+extra+s[at:]
needle=" Form.WorkspaceTabs.ActiveTab:=Form.DatabaseInventoryTab;Form.Show;Render("
at=s.index(needle)
s=s[:at]+""" Form.DatabaseInventoryKind.ItemIndex:=Form.DatabaseInventoryKind.Items.IndexOf('database operation');Form.DatabaseInventoryFilter.Text:='Post';Form.DatabaseInventoryFilterChange(nil);
 Check(Form.DatabaseInventoryList.Count=2,'Native filter finds both dataset Post sites');
 Check(Form.DatabaseInventoryMemo.Text.Contains('DATABASE OPERATION'),'Native operation effect appears first');
 Check(Form.DatabaseInventorySource.Enabled,'Native source command is available');
 Form.DatabaseInventorySourceClick(nil);Check(Form.DatabaseInventoryMemo.Text.Contains('Source is detached'),'Detached capture refuses source access');
 Form.DatabaseInventoryFilter.Text:='Query / Delete';Form.DatabaseInventoryFilterChange(nil);
"""+s[at:]
# Receiver path uses caller name rather than receiver; choose Delete text instead.
s=s.replace("Form.DatabaseInventoryFilter.Text:='Query / Delete'", "Form.DatabaseInventoryFilter.Text:='Delete'")
write('tests/DPH.Tests.DatabaseOperations.dpr',s)
s=read('tools/build-dataset-bindings.cmd').replace('DatasetBindings','DatabaseOperations');write('tools/build-database-operations.cmd',s)
s=read('DPH.Analysis.Symbols.pas').replace('Name,UnitName,ImportName:string;Imports:TList<string>;','Name,UnitName:string;Imports:TList<string>;',1);write('DPH.Analysis.Symbols.pas',s)
