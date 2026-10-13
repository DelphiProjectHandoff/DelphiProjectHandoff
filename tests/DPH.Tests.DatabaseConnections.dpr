program DPH.Tests.DatabaseConnections;
{$APPTYPE CONSOLE}
uses System.SysUtils,System.Classes,System.IOUtils,System.JSON,System.Hash,System.StrUtils,System.UITypes,
  FMX.Forms,FMX.Graphics,DPH.Project.Analysis,DPH.Analysis.Model,DPH.Analysis.Symbols,
  DPH.Workspace.Model,DPH.Workspace.DatabaseConnections,DPH.UI.Main,DPH.Workspace.Catalog,
  DPH.Storage.Database,DPH.Storage.Types,DPH.Analysis.Persistence;
var Root,Work,Fixture,Text,Catalog,CatalogHash,SourceHash,Database:string;I,Checks:Integer;
    Analyzer:TDPHAnalyzer;Semantic:TDPHSemanticAnalyzer;Scan:TDPHScan;Graph:TDPHSemanticGraph;
    View,Reopened:TDPHWorkspaceView;Document,Report,Row,Link,Log:TJSONObject;Value:TJSONValue;
    Form:TDPHMainForm;Bitmap:TBitmap;Input:TStringStream;Binary:TMemoryStream;
    Store:TDPHKnowledgeStore;Config,Generation:Int64;
procedure Check(OK:Boolean;const MessageText:string);
begin if not OK then raise Exception.Create('FAIL '+MessageText);Inc(Checks);Writeln('PASS ',Checks,': ',MessageText);Flush(Output);end;
function Find(const Name:string):TJSONObject;
var V:TJSONValue;
begin Result:=nil;for V in Report.GetValue<TJSONArray>('rows') do if V.GetValue<string>('name')=Name then Exit(V as TJSONObject);end;
function Reference(const Name,PropertyName:string):TJSONObject;
var V:TJSONValue;
begin Result:=nil;for V in Find(Name).GetValue<TJSONArray>('links') do if SameText(V.GetValue<string>('property'),PropertyName) then Exit(V as TJSONObject);end;
procedure Render(const Name:string);
begin Application.ProcessMessages;Bitmap:=TBitmap.Create(Form.ClientWidth,Form.ClientHeight);
try if Bitmap.Canvas.BeginScene then try Form.PaintTo(Bitmap.Canvas);finally Bitmap.Canvas.EndScene;end;
Bitmap.SaveToFile(TPath.Combine(Root,'docs\'+Name));finally Bitmap.Free;end;end;
begin
 Application.Initialize;
 try
 Root:=TPath.GetFullPath(ParamStr(1));Work:=TPath.Combine(Root,'bin\database-connections-validation');
 if TDirectory.Exists(Work) then TDirectory.Delete(Work,True);
 Fixture:=TPath.Combine(Work,'source');TDirectory.CreateDirectory(Fixture);
 TFile.WriteAllText(TPath.Combine(Fixture,'Connections.dpr'),'program Connections; uses Main, Remote, Touch, BinaryDB; begin end.',TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(Fixture,'Main.pas'),String.Join(sLineBreak,[
 'unit Main; interface type TMainModule = class',' MainConnection: TFDConnection;',' Query: TFDQuery;',' Unserialized: TADOConnection;',
 'end; implementation {$R *.dfm} end.']),TEncoding.UTF8);
 for Text in ['Remote','Touch','BinaryDB'] do TFile.WriteAllText(TPath.Combine(Fixture,Text+'.pas'),'unit '+Text+'; interface implementation {$R *.'+IfThen(Text='Touch','fmx','dfm')+'} end.',TEncoding.UTF8);
 Text:=String.Join(sLineBreak,[
 'object MainModule: TMainModule',
 ' object MainConnection: TFDConnection','  ConnectionDefName = ''PrimaryDef''','  Connected = True','  LoginPrompt = False',
 '  Database = ''SENSITIVE_ENDPOINT_CANARY''','  Password = ''SENSITIVE_PASSWORD_CANARY''',
 '  DatabaseName = ''SENSITIVE_DATABASE_NAME_CANARY''',
 '  Params.Strings = (','    ''DriverID=FB''','    ''Port=3050''','    ''Database=SENSITIVE_DB_CANARY''',
 '    ''User_Name=SENSITIVE_USER_CANARY''','    ''PWD=SENSITIVE_PWD_CANARY''','    ''UnknownKey=SENSITIVE_UNKNOWN_CANARY'')',' end',
 ' object Query: TFDQuery','  Connection = MainConnection',' end',
 ' object Source: TDataSource','  DataSet = Query',' end',
 ' object RemoteQuery: TADOQuery','  Connection = RemoteDM.RemoteConnection',' end',
 ' object Broken: TFDQuery','  Connection = MissingConnection',' end',
 ' object QuotedDatabase: TFDQuery','  Database = ''SENSITIVE_DATASET_DB_CANARY''',' end',
 ' object UnqualifiedRemote: TFDQuery','  Connection = RemoteConnection',' end',
 ' object Ordinary: TButton','  Caption = ''SENSITIVE_NON_DB_CANARY''',' end',
 ' object NilQuery: TFDQuery','  Connection = nil',' end',
 ' object WrongRole: TFDQuery','  Connection = Query',' end',
 ' object Expression: TFDQuery','  Connection = SENSITIVE_EXPRESSION_CANARY()',' end',
 ' object ADO: TADOConnection','  ConnectionString = ''Provider=MSDASQL;PWD=SENSITIVE_ADO_CANARY''',' end',
 ' object IB: TIBDatabase',' end',' object Tx: TIBTransaction','  DefaultDatabase = IB',' end',
 ' object IBQuery: TIBQuery','  Database = IB','  Transaction = Tx',' end',
 ' object Legacy: TDatabase','  DatabaseName = ''LogicalDB''','  SessionName = ''SharedSession''',' end',
 ' object LegacyQuery: TQuery','  DatabaseName = ''LogicalDB''',' end',
 ' object Session: TSession','  SessionName = ''SharedSession''',' end',
 ' object Nested: TPanel','  object NestedConnection: TFDConnection','  end',' end',
 ' object NestedQuery: TFDQuery','  Connection = Nested.NestedConnection',' end',
 ' object SelfQuery: TFDQuery','  Connection = Self.MainConnection',' end',
 ' object Duplicate: TFDConnection',' end',' object Duplicate: TFDConnection',' end',
 ' object Ambiguous: TFDQuery','  Connection = Duplicate',' end',
 ' object Custom: TCustomBusinessQuery','  Connection = MainConnection',' end',
 ' inherited InheritedQuery: TFDQuery',' end',
 ' object BadConfig: TFDConnection','  DriverID = ''SENSITIVE_DRIVER_CANARY()''','  Port = 70000',' end']);
 for I:=1 to 270 do Text:=Text+sLineBreak+' object Extra'+IntToStr(I)+': TFDQuery'+sLineBreak+'  Connection = MainConnection'+sLineBreak+' end';
 Text:=Text+sLineBreak+'end';TFile.WriteAllText(TPath.Combine(Fixture,'Main.dfm'),Text,TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(Fixture,'Remote.dfm'),String.Join(sLineBreak,[
 'object RemoteDM: TDataModule',' object RemoteConnection: TADOConnection','  ConnectionDefName = ''PrimaryDef''',' end','end']),TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(Fixture,'Touch.fmx'),String.Join(sLineBreak,[
 'object TouchForm: TForm',' object TouchConnection: TSQLConnection',' end',' object TouchQuery: TSQLQuery','  SQLConnection = TouchConnection',' end','end']),TEncoding.UTF8);
 Input:=TStringStream.Create(String.Join(sLineBreak,[
 'object BinaryModule: TDataModule',' object BinaryConnection: TFDConnection','  Password = ''SENSITIVE_BINARY_CANARY''',' end',
 ' object BinaryQuery: TFDQuery','  Connection = BinaryConnection',' end','end']));Binary:=TMemoryStream.Create;
 try ObjectTextToBinary(Input,Binary);Binary.SaveToFile(TPath.Combine(Fixture,'BinaryDB.dfm'));finally Binary.Free;Input.Free;end;
 SourceHash:=THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'Main.dfm'));
 Analyzer:=TDPHAnalyzer.Create;Semantic:=TDPHSemanticAnalyzer.Create;
 try Scan:=Analyzer.Scan(TPath.Combine(Fixture,'Connections.dpr'),'Debug','Win32',[],[],False);
 try Graph:=Semantic.Analyze(Scan);
 try
 Database:=TPath.Combine(Work,'connections.dphdb');Store:=TDPHKnowledgeStore.Create(Database,Fixture,TPath.Combine(Root,'migrations'));
 try Store.InitializeProject('Controlled database connection inventory','Delphi');Config:=Store.AddConfiguration('Win32','37.0','[]','[]','Debug');Store.SelectConfiguration(Config);
 Generation:=TDPHSemanticPersistence.Stage(Scan,Graph,Store,Config);
 Document:=TDPHWorkspaceView.Capture(Scan,Graph,Generation,'Connections.dpr','Debug','Win32',[],[]);
 Store.SaveWorkspaceView(Generation,Document.ToJSON);TDPHSemanticPersistence.Publish(Scan,Graph,Store,Generation);
 View:=TDPHWorkspaceView.Create(Document);Reopened:=TDPHWorkspaceView.Create(TJSONObject.ParseJSONValue(Store.LoadWorkspaceView) as TJSONObject);
 Check(Store.IntegrityCheck='ok','Fixture SQLite integrity valid');
 finally Store.Free;end;
 finally Graph.Free;end;finally Scan.Free;end;finally Semantic.Free;Analyzer.Free;end;
 try
 Report:=TDPHDatabaseConnections.Inspect(View);
 try
 Check(Find('MainConnection')<>nil,'Text DFM connection captured');
 Check(Find('MainConnection').GetValue<string>('role')='connection','Known connection class classified');
 Check(Find('Query').GetValue<string>('role')='dataset','Dataset classified');
 Check(Find('Source').GetValue<string>('role')='data source','Data source classified');
 Check(Find('Tx').GetValue<string>('role')='transaction','Transaction classified');
 Check(Find('Session').GetValue<string>('role')='session','Session classified');
 Check(Find('Custom').GetValue<string>('role')='database candidate','Custom class property signal remains candidate');
 Check(Find('Main.TMainModule.Unserialized')<>nil,'Pascal-only declaration retained');
 I:=0;for Value in Report.GetValue<TJSONArray>('rows') do if Value.GetValue<string>('name')='Main.TMainModule.MainConnection' then Inc(I);
 Check(I=0,'Confirmed component-field binding avoids duplicate declaration row');
 Check(Reference('Query','Connection').GetValue<string>('target_id')=Find('MainConnection').GetValue<string>('id'),'Dataset connection links uniquely');
 Check(Reference('Source','DataSet').GetValue<string>('target_id')=Find('Query').GetValue<string>('id'),'Data source links to dataset');
 Check(Reference('RemoteQuery','Connection').GetValue<string>('target_id')=Find('RemoteConnection').GetValue<string>('id'),'Qualified cross-module reference links');
 Check(Reference('Broken','Connection').GetValue<string>('resolution').Contains('unresolved'),'Missing target explicitly unresolved');
 Check(not Reference('Broken','Connection').ToJSON.Contains('target_id'),'Missing target not fabricated');
 Check(not Reference('UnqualifiedRemote','Connection').ToJSON.Contains('target_id'),'Unqualified external target is not guessed');
 Check(Find('Ordinary')=nil,'Unrelated visual component excluded');
 Check(Reference('NilQuery','Connection').GetValue<string>('resolution')='explicit nil reference','Nil stays explicit');
 Check(not Reference('WrongRole','Connection').ToJSON.Contains('target_id'),'Wrong-role target not linked');
 Check(Reference('Expression','Connection').GetValue<string>('reference')='[unsupported reference expression]','Unsupported expression masked');
 Check(Reference('IBQuery','Database').GetValue<string>('target_id')=Find('IB').GetValue<string>('id'),'IB database reference links');
 Check(Reference('IBQuery','Transaction').GetValue<string>('target_id')=Find('Tx').GetValue<string>('id'),'Transaction reference links');
 Check(Reference('Tx','DefaultDatabase').GetValue<string>('target_id')=Find('IB').GetValue<string>('id'),'Transaction default database links');
 Check(Reference('LegacyQuery','DatabaseName').GetValue<string>('target_id')=Find('Legacy').GetValue<string>('id'),'BDE logical database alias links');
 Check(Reference('Legacy','SessionName').GetValue<string>('target_id')=Find('Session').GetValue<string>('id'),'Session alias links');
 Check(Reference('NestedQuery','Connection').GetValue<string>('target_id')=Find('NestedConnection').GetValue<string>('id'),'Parent-local nested path links');
 Check(Reference('SelfQuery','Connection').GetValue<string>('target_id')=Find('MainConnection').GetValue<string>('id'),'Self-qualified reference links');
 Check(Reference('Ambiguous','Connection').GetValue<string>('resolution').Contains('ambiguous'),'Duplicate paths remain ambiguous');
 Check(not Reference('Ambiguous','Connection').ToJSON.Contains('target_id'),'Ambiguous target not followed');
 Check(Find('PrimaryDef').GetValue<string>('role')='connection definition','Named definition inventoried');
 Check(Find('PrimaryDef').GetValue<TJSONArray>('used_by').Count=2,'Shared definition has both referencing connections');
 Check(Find('PrimaryDef').GetValue<string>('availability').Contains('unavailable'),'External definition contents not invented');
 Check(Find('MainConnection').GetValue<TJSONArray>('used_by').Count>270,'Reverse dataset dependencies retained');
 Check(Find('BinaryConnection')<>nil,'Binary DFM connection captured');
 Check(Reference('BinaryQuery','Connection').TryGetValue<string>('target_id',Text),'Binary reference resolved');
 Check(Reference('TouchQuery','SQLConnection').GetValue<string>('target_id')=Find('TouchConnection').GetValue<string>('id'),'FMX connection reference resolved');
 Check(Find('InheritedQuery').GetValue<string>('declaration')='inherited','Inherited declaration preserved');
 Check(Find('InheritedQuery').GetValue<TJSONArray>('configuration').Count=0,'Missing configuration not invented');
 Check(not Report.ToJSON.Contains('SENSITIVE_'),'All sensitive configuration canaries absent from projection');
 Check(TDPHDatabaseConnections.Describe(Find('MainConnection')).Contains('DriverID = FB'),'Validated driver metadata shown');
 Check(TDPHDatabaseConnections.Describe(Find('MainConnection')).Contains('Port = 3050'),'Valid port shown');
 Check(TDPHDatabaseConnections.Describe(Find('BadConfig')).Contains('[REDACTED configuration value]'),'Invalid driver and port masked');
 Check(TDPHDatabaseConnections.Describe(Find('MainConnection')).Contains('not evidence of a successful connection'),'Connected flag qualified');
 Check(Find('MainConnection').GetValue<string>('source_hash')=SourceHash,'Exact source hash retained');
 Row:=TDPHDatabaseConnections.Inspect(Reopened);try Check(Row.ToJSON=Report.ToJSON,'Reopened captured database gives identical inventory');finally Row.Free;end;
 Catalog:=TDPHWorkspaceCatalog.DefaultPath;CatalogHash:='';if TFile.Exists(Catalog) then CatalogHash:=THashSHA2.GetHashStringFromFile(Catalog);
 Form:=TDPHMainForm.Create(nil);
 try Form.PollTimer.Enabled:=False;Form.ChangeTimer.Enabled:=False;Form.LoadView(View.Document.Clone as TJSONObject);
 Check(Form.WorkspacePageCombo.Items.IndexOf('Database connections')>=0,'Inventory page discoverable');
 Check(Form.DatabaseInventoryList.Count=250,'Native page paginates at 250');Check(Form.DatabaseInventoryNext.Enabled,'Next enabled for remaining rows');
 Form.DatabaseInventoryFilterChange(Form.DatabaseInventoryNext);Check(Form.DatabaseInventoryList.Count<250,'Next shows bounded remaining rows');
 Form.DatabaseInventoryKind.ItemIndex:=2;Form.DatabaseInventoryFilter.Text:='RemoteQuery';Form.DatabaseInventoryFilterChange(nil);Check(Form.DatabaseInventoryList.Count=1,'Native text and kind filters find dataset');
 Form.DatabaseInventoryList.ItemIndex:=0;Form.DatabaseInventorySelectionChange(nil);Check(Form.DatabaseInventoryFollow.Enabled,'Unique reference enables follow');
 Form.DatabaseInventoryFollowClick(nil);Check(Form.DatabaseInventoryMemo.Text.Contains('CONNECTION RemoteDM.RemoteConnection'),'Follow navigates exact target');
 Check(Form.DatabaseInventoryLinks.Items.Count>0,'Reverse references navigable');
 Form.DatabaseInventoryKind.ItemIndex:=6;Form.DatabaseInventoryFilterChange(nil);Check(Form.DatabaseInventoryList.Count=1,'Named definition kind filter');
 Check(Form.DatabaseInventoryMemo.Text.Contains('External definition contents'),'Native details explain unknown definition contents');
 Form.DatabaseInventoryKind.ItemIndex:=1;Form.DatabaseInventoryFilter.Text:='MainConnection';Form.DatabaseInventoryFilterChange(nil);
 Check(not Form.DatabaseInventoryMemo.Text.Contains('SENSITIVE_'),'Native details omit sensitive values');
 Form.DatabaseInventoryFilter.Text:='NO_MATCH_FIXTURE';Form.DatabaseInventoryFilterChange(nil);
 Check(Form.DatabaseInventoryList.Count=0,'Empty filter has no invented rows');
 Check(not Form.DatabaseInventoryFollow.Enabled,'Empty filter disables reference navigation');
 Check(Form.DatabaseInventoryMemo.Text.Contains('Runtime-only factories'),'Empty inventory explains coverage limits');
 Form.DatabaseInventoryFilter.Text:='MainConnection';Form.DatabaseInventoryFilterChange(nil);
 Form.WorkspaceTabs.ActiveTab:=Form.DatabaseInventoryTab;Form.Show;Render('phase1-database-connections-workspace.png');
 Form.WindowState:=TWindowState.wsNormal;Form.Width:=960;Form.Height:=600;Render('phase1-database-connections-compact.png');
 Check(Form.DatabaseInventoryToolbar.ShowScrollBars,'Compact commands scroll horizontally');Check(Form.DatabaseInventoryMemo.ShowScrollBars,'Evidence memo scrolls');
 Check(Form.DatabaseInventoryMemo.Width<400,'Compact evidence stays in workspace pane');
 Check(Form.DatabaseInventoryMemo.Height>=50,'Compact evidence retains usable visible height');
 Form.LoadView(View.Document.Clone as TJSONObject);Check(not Form.DatabaseInventoryMemo.Text.Contains('SENSITIVE_'),'Capture replacement retains redaction');Form.Hide;
 finally Form.Free;end;
 Check((not TFile.Exists(Catalog) and (CatalogHash='')) or (TFile.Exists(Catalog) and (THashSHA2.GetHashStringFromFile(Catalog)=CatalogHash)),'Owner catalog unchanged');
 Check(THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'Main.dfm'))=SourceHash,'Analyzed source unchanged');
 Log:=TJSONObject.Create.AddPair('result','PASS').AddPair('checks',TJSONNumber.Create(Checks)).AddPair('qualification','Actual parser, persisted and reopened captures, redacted configuration and native FMX controls. No target database is opened; fixtures contain only controlled canaries.');
 try TFile.WriteAllText(TPath.Combine(Root,'docs\validation\reports\phase1-database-connections-validation.json'),Log.Format,TEncoding.UTF8);finally Log.Free;end;
 finally Report.Free;end;
 finally Reopened.Free;View.Free;end;
 Writeln('Database connections validation passed: ',Checks,' checks.');
 except on E:Exception do begin Writeln(E.ClassName,': ',E.Message);ExitCode:=1;end;end;
end.
