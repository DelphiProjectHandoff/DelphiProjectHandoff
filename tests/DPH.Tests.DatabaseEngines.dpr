program DPH.Tests.DatabaseEngines;
{$APPTYPE CONSOLE}
uses System.SysUtils,System.Classes,System.IOUtils,System.JSON,System.Hash,System.UITypes,
 FMX.Forms,FMX.Graphics,DPH.Project.Analysis,DPH.Analysis.Model,DPH.Analysis.Symbols,
 DPH.Workspace.Model,DPH.Workspace.DatabaseConnections,DPH.UI.Main,DPH.Workspace.Catalog,
 DPH.Storage.Database,DPH.Analysis.Persistence;
const Drivers:array[0..13] of string=('ADS','ASA','DB2','FB','IB','IBLite','Infx','MSAcc','MSSQL','MySQL','Ora','PG','SQLite','Mongo');
 Families:array[0..13] of string=('Advantage Database Server','SQL Anywhere','IBM DB2','Firebird','InterBase','InterBase','Informix','Microsoft Access','Microsoft SQL Server','MySQL-compatible','Oracle','PostgreSQL','SQLite','MongoDB');
var Root,Work,Fixture,Text,SourceHash,CatalogHash,Catalog:string;I,Checks:Integer;
 Analyzer:TDPHAnalyzer;Semantic:TDPHSemanticAnalyzer;Scan:TDPHScan;Graph:TDPHSemanticGraph;
 View,Reopened:TDPHWorkspaceView;Document,Report,Other,Log:TJSONObject;Store:TDPHKnowledgeStore;
 Config,Generation:Int64;Form:TDPHMainForm;Bitmap:TBitmap;Input:TStringStream;Binary:TMemoryStream;
procedure Check(OK:Boolean;const MessageText:string);
begin if not OK then raise Exception.Create('FAIL '+MessageText);Inc(Checks);Writeln('PASS ',Checks,': ',MessageText);Flush(Output);end;
function Find(const Name:string):TJSONObject;
var V:TJSONValue;
begin Result:=nil;for V in Report.GetValue<TJSONArray>('rows') do if V.GetValue<string>('name')=Name then Exit(V as TJSONObject);end;
procedure Render(const Name:string);
begin Application.ProcessMessages;Bitmap:=TBitmap.Create(Form.ClientWidth,Form.ClientHeight);
try if Bitmap.Canvas.BeginScene then try Form.PaintTo(Bitmap.Canvas);finally Bitmap.Canvas.EndScene;end;
Bitmap.SaveToFile(TPath.Combine(Root,'docs\'+Name));finally Bitmap.Free;end;end;
begin Application.Initialize;
 try
 Root:=TPath.GetFullPath(ParamStr(1));Work:=TPath.Combine(Root,'bin\database-engines-validation');
 if TDirectory.Exists(Work) then TDirectory.Delete(Work,True);
 Fixture:=TPath.Combine(Work,'source');TDirectory.CreateDirectory(Fixture);
 TFile.WriteAllText(TPath.Combine(Fixture,'Engines.dpr'),'program Engines; uses Main, Touch, BinaryDB; begin end.',TEncoding.UTF8);
 for Text in ['Main','Touch','BinaryDB'] do
  if Text='Touch' then TFile.WriteAllText(TPath.Combine(Fixture,Text+'.pas'),'unit '+Text+'; interface implementation {$R *.fmx} end.',TEncoding.UTF8)
  else TFile.WriteAllText(TPath.Combine(Fixture,Text+'.pas'),'unit '+Text+'; interface implementation {$R *.dfm} end.',TEncoding.UTF8);
 Text:='object MainModule: TDataModule';
 for I:=0 to High(Drivers) do Text:=Text+sLineBreak+' object Driver'+IntToStr(I)+': TFDConnection'+sLineBreak+'  Params.Strings = ('+sLineBreak+'   ''DriverID='+Drivers[I]+''')'+sLineBreak+' end';
 Text:=Text+sLineBreak+String.Join(sLineBreak,[
 ' object Versioned: TFDConnection','  ServerVersion = ''5.0.2''','  DatabaseVersion = ''5.0.2''',
 '  ClientVersion = ''4.0.1''','  DriverVersion = ''37.0''','  Params.Strings = (''DriverID=FB'')','  Password = ''SECRET_ENGINE_CANARY''',' end',
 ' object Dataset: TFDQuery','  Connection = Versioned',' end',' object Source: TDataSource','  DataSet = Dataset',' end',
 ' object Chain1: TFDQuery','  DataSet = Dataset',' end',' object Chain2: TFDQuery','  DataSet = Chain1',' end',' object Chain3: TFDQuery','  DataSet = Chain2',' end',
 ' object Conflict: TFDConnection','  Params.Strings = (''DriverID=FB'' ''DriverID=PG'')',' end',
 ' object Unknown: TFDConnection','  Params.Strings = (''DriverID=ODBC'')','  ClientVersion = ''18.5''','  SQLDialect = 3','  Port = 3050',' end',
 ' object Virtual: TFDConnection','  Params.Strings = (''DriverID=CustomFB'')',' end',
 ' object Mixed: TFDConnection','  Params.Strings = (''DriverID=FB'' ''DriverID=CustomFB'')',' end',
 ' object VersionConflict: TFDConnection','  ServerVersion = ''5.0''','  DatabaseVersion = ''4.0''',' end',
 ' object InvalidVersion: TFDConnection','  ServerVersion = ''5.0;PWD=SECRET_VERSION_CANARY''','  ClientVersion = ''SECRET_CLIENT_CANARY''',' end',
 ' object OpaqueADO: TADOConnection','  ConnectionString = ''Provider=MSOLEDBSQL;PWD=SECRET_ADO_CANARY''','  DriverID = ''FB''',' end',
 ' object TwoConnections: TFDQuery','  Connection = Driver3','  SQLConnection = Driver11',' end',
 ' object Missing: TFDQuery','  Connection = Absent',' end',
 ' object PartialLink: TFDQuery','  Connection = Versioned','  SQLConnection = Absent',' end',
 ' object Duplicate: TFDConnection','  DriverID = ''FB''',' end',' object Duplicate: TFDConnection','  DriverID = ''PG''',' end',
 ' object Ambiguous: TFDQuery','  Connection = Duplicate',' end',
 ' object DefinedOnly: TFDConnection','  ConnectionDefName = ''ExternalDB''',' end','end']);
 TFile.WriteAllText(TPath.Combine(Fixture,'Main.dfm'),Text,TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(Fixture,'Touch.fmx'),String.Join(sLineBreak,['object TouchForm: TForm',' object Pg: TFDConnection','  DriverID = ''PG''','  ServerVersion = ''16.3''',' end','end']),TEncoding.UTF8);
 Input:=TStringStream.Create(String.Join(sLineBreak,['object BinaryModule: TDataModule',' object Embedded: TFDConnection','  DriverID = ''SQLite''','  ServerVersion = ''3.45.1''',' end','end']));Binary:=TMemoryStream.Create;
 try ObjectTextToBinary(Input,Binary);Binary.SaveToFile(TPath.Combine(Fixture,'BinaryDB.dfm'));finally Binary.Free;Input.Free;end;
 SourceHash:=THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'Main.dfm'));
 Analyzer:=TDPHAnalyzer.Create;Semantic:=TDPHSemanticAnalyzer.Create;
 try Scan:=Analyzer.Scan(TPath.Combine(Fixture,'Engines.dpr'),'Debug','Win32',[],[],False);
 try Graph:=Semantic.Analyze(Scan);
 try Store:=TDPHKnowledgeStore.Create(TPath.Combine(Work,'engines.dphdb'),Fixture,TPath.Combine(Root,'migrations'));
 try Store.InitializeProject('Controlled engine/version declarations','Delphi');Config:=Store.AddConfiguration('Win32','37.0','[]','[]','Debug');Store.SelectConfiguration(Config);
 Generation:=TDPHSemanticPersistence.Stage(Scan,Graph,Store,Config);
 Document:=TDPHWorkspaceView.Capture(Scan,Graph,Generation,'Engines.dpr','Debug','Win32',[],[]);
 Store.SaveWorkspaceView(Generation,Document.ToJSON);TDPHSemanticPersistence.Publish(Scan,Graph,Store,Generation);
 View:=TDPHWorkspaceView.Create(Document);Reopened:=TDPHWorkspaceView.Create(TJSONObject.ParseJSONValue(Store.LoadWorkspaceView) as TJSONObject);
 Check(Store.IntegrityCheck='ok','Persisted fixture integrity valid');
 finally Store.Free;end;finally Graph.Free;end;finally Scan.Free;end;finally Semantic.Free;Analyzer.Free;end;
 try Report:=TDPHDatabaseConnections.Inspect(View);
 try
 TFile.WriteAllText(TPath.Combine(Work,'inventory.json'),Report.Format,TEncoding.UTF8);
 for I:=0 to High(Drivers) do begin
  Check(Find('Driver'+IntToStr(I)).GetValue<string>('engine.family')=Families[I],'Recognized DriverID '+Drivers[I]);
  Check(Find('Driver'+IntToStr(I)).GetValue<string>('engine.server_version')='unknown','DriverID does not imply server version '+Drivers[I]);
 end;
 Check(Find('Versioned').GetValue<string>('engine.server_version')='5.0.2','Matching explicit version declarations retained');
 Check(Find('Versioned').GetValue<string>('engine.version_state')='declared','Version is declared not observed');
 Check(Find('Versioned').GetValue<TJSONArray>('engine.evidence').Count=5,'Driver and all version evidence retained');
 Check(Find('Dataset').GetValue<string>('engine.family')='Firebird','Dataset follows unique captured connection');
 Check(Find('Source').GetValue<string>('engine.server_version')='5.0.2','Data source follows dataset to connection');
 Check(Find('Chain2').GetValue<Integer>('engine.hops')=3,'Three-hop evidence path retained');
 Check(Find('Chain3').GetValue<string>('engine.family')='unknown','Fourth hop remains unknown');
 Check(Find('Dataset').GetValue<string>('engine.via').Contains('Versioned'),'Derived engine retains reference path');
 Check(Find('Dataset').GetValue<TJSONArray>('engine.evidence').Items[0].GetValue<string>('source_hash')=SourceHash,'Derived evidence retains origin hash');
 Check(Find('Conflict').GetValue<string>('engine.state')='conflicting','Different driver families conflict');
 Check(Find('Mixed').GetValue<string>('engine.state')='conflicting','Known plus virtual driver remains conflicting');
 Check(Find('Unknown').GetValue<string>('engine.family')='unknown','ODBC port and dialect do not identify engine');
 Check(Find('Unknown').GetValue<string>('engine.server_version')='unknown','Client version not confused with server');
 Check(Find('Virtual').GetValue<string>('engine.state')='unknown','Virtual driver not guessed from name');
 Check(Find('VersionConflict').GetValue<string>('engine.version_state')='conflicting','Different version declarations conflict');
 Check(Find('InvalidVersion').GetValue<string>('engine.server_version')='unknown','Invalid version not displayed or inferred');
 Check(Find('OpaqueADO').GetValue<string>('engine.family')='unknown','ADO string and unrelated DriverID do not identify engine');
 Check(Find('TwoConnections').GetValue<string>('engine.state')='conflicting','Different captured connections not collapsed');
 Check(Find('Missing').GetValue<string>('engine.family')='unknown','Missing reference engine unknown');
 Check(Find('PartialLink').GetValue<string>('engine.family')='unknown','Partially unresolved connection paths do not imply one engine');
 Check(Find('Ambiguous').GetValue<string>('engine.family')='unknown','Ambiguous reference engine unknown');
 Check(Find('ExternalDB').GetValue<string>('engine.family')='unknown','External definition engine unavailable');
 Check(Find('Pg').GetValue<string>('engine.family')='PostgreSQL','FMX DriverID captured');
 Check(Find('Embedded').GetValue<string>('engine.server_version')='3.45.1','Binary DFM version captured');
 Check(not Report.ToJSON.Contains('SECRET_'),'Secrets absent from engine and configuration projection');
 Check(TDPHDatabaseConnections.Describe(Find('Versioned')).Contains('not measured server versions'),'Details qualify declared version');
 Other:=TDPHDatabaseConnections.Inspect(Reopened);try Check(Other.ToJSON=Report.ToJSON,'Reopened capture produces identical engine evidence');finally Other.Free;end;
 Catalog:=TDPHWorkspaceCatalog.DefaultPath;CatalogHash:='';if TFile.Exists(Catalog) then CatalogHash:=THashSHA2.GetHashStringFromFile(Catalog);
 Form:=TDPHMainForm.Create(nil);
 try Form.PollTimer.Enabled:=False;Form.ChangeTimer.Enabled:=False;Form.LoadView(View.Document.Clone as TJSONObject);
 Form.DatabaseInventoryFilter.Text:='SQLite';Form.DatabaseInventoryFilterChange(nil);
 Check(Form.DatabaseInventoryList.Count=2,'Engine-name filter ignores explanatory boilerplate');
 Check(Form.DatabaseInventoryList.Items[0].Contains('Engine: SQLite'),'List exposes engine summary');
 Form.DatabaseInventoryFilter.Text:='Versioned';Form.DatabaseInventoryKind.ItemIndex:=1;Form.DatabaseInventoryFilterChange(nil);
 Check(Form.DatabaseInventoryMemo.Text.Contains('Server version declaration: 5.0.2'),'Native details display version');
 Check(Form.DatabaseInventoryMemo.Text.Contains('ClientVersion = 4.0.1'),'Client evidence distinctly labeled');
 Check(not Form.DatabaseInventoryMemo.Text.Contains('SECRET_'),'Native engine evidence remains masked');
 Form.WorkspaceTabs.ActiveTab:=Form.DatabaseInventoryTab;Form.Show;Render('phase1-database-engines-workspace.png');
 Form.WindowState:=TWindowState.wsNormal;Form.Width:=960;Form.Height:=600;Render('phase1-database-engines-compact.png');
 Check(Form.DatabaseInventoryMemo.Height>=50,'Compact engine evidence has visible area');
 Check(Form.DatabaseInventoryMemo.ShowScrollBars,'Long engine explanations scroll');
 Form.LoadView(Reopened.Document.Clone as TJSONObject);Check(Form.DatabaseInventoryMemo.Text.Contains('DATABASE ENGINE AND VERSION'),'Reopened native capture rebuilds evidence');Form.Hide;
 finally Form.Free;end;
 Check((not TFile.Exists(Catalog) and (CatalogHash='')) or (TFile.Exists(Catalog) and (THashSHA2.GetHashStringFromFile(Catalog)=CatalogHash)),'Owner catalog unchanged');
 Check(THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'Main.dfm'))=SourceHash,'Target source unchanged');
 Log:=TJSONObject.Create.AddPair('result','PASS').AddPair('checks',TJSONNumber.Create(Checks)).AddPair('qualification','Controlled captured driver/version declarations using actual text/binary DFM, FMX, SQLite capture persistence and native FMX controls; no target server or driver is opened.');
 try TFile.WriteAllText(TPath.Combine(Root,'docs\validation\reports\phase1-database-engines-validation.json'),Log.Format,TEncoding.UTF8);finally Log.Free;end;
 finally Report.Free;end;finally Reopened.Free;View.Free;end;
 Writeln('Database engine validation passed: ',Checks,' checks.');
 except on E:Exception do begin Writeln(E.ClassName,': ',E.Message);ExitCode:=1;end;end;
end.
