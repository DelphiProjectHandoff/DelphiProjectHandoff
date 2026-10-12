program DPH.Tests.DatabaseSchema;
{$APPTYPE CONSOLE}
uses System.SysUtils,System.Classes,System.IOUtils,System.JSON,System.Hash,System.StrUtils,System.UITypes,
 FMX.Forms,FMX.Graphics,DPH.Project.Analysis,DPH.Analysis.Model,DPH.Analysis.Symbols,
 DPH.Workspace.Model,DPH.Workspace.DatabaseSchema,DPH.Workspace.Keyboard,DPH.UI.Main,
 DPH.Storage.Database,DPH.Storage.Types,DPH.Analysis.Persistence,DPH.Workspace.Catalog;
var Root,Work,Fixture,SQL,SourceHash,Catalog,CatalogHash,Before:string;I,Checks:Integer;
 Analyzer:TDPHAnalyzer;Semantic:TDPHSemanticAnalyzer;Scan:TDPHScan;Graph:TDPHSemanticGraph;
 View,Reopened:TDPHWorkspaceView;Document,Report,Other,Row,Log:TJSONObject;V:TJSONValue;
 Store:TDPHKnowledgeStore;Config,Generation:Int64;Form:TDPHMainForm;Bitmap:TBitmap;
procedure Check(OK:Boolean;const MessageText:string);
begin if not OK then raise Exception.Create('FAIL '+MessageText);Inc(Checks);Writeln('PASS ',Checks,': ',MessageText);Flush(Output);end;
function Find(const Name,Status:string):TJSONObject;
var Value:TJSONValue;
begin Result:=nil;for Value in Report.GetValue<TJSONArray>('rows') do if (Value.GetValue<string>('name')=Name) and (Value.GetValue<string>('status')=Status) then Exit(Value as TJSONObject);end;
procedure Render(const Name:string);
begin Application.ProcessMessages;Bitmap:=TBitmap.Create(Form.ClientWidth,Form.ClientHeight);
try if Bitmap.Canvas.BeginScene then try Form.PaintTo(Bitmap.Canvas);finally Bitmap.Canvas.EndScene;end;
 Bitmap.SaveToFile(TPath.Combine(Root,'docs\'+Name));finally Bitmap.Free;end;end;
procedure Refuses(const Entry:string;Evidence:TJSONObject;const MessageText:string);
var Denied:Boolean;
begin Denied:=False;try TDPHKeyboardInspector.ReadSource(View,Entry,Evidence,Evidence.GetValue<TJSONObject>('range'));except on E:EInvalidOpException do Denied:=True;end;Check(Denied,MessageText);end;
begin
 Application.Initialize;
 try
 Root:=TPath.GetFullPath(ParamStr(1));Work:=TPath.Combine(Root,'bin\database-schema-validation');Fixture:=TPath.Combine(Work,'source');TDirectory.CreateDirectory(Fixture);
 TFile.WriteAllText(TPath.Combine(Fixture,'Schema.dpr'),'program Schema; uses Main; begin end.',TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(Fixture,'Main.pas'),String.Join(sLineBreak,[
 'unit Main; interface implementation procedure Load; begin',
 'TFile.ReadAllText(''schema.sql''); TFile.ReadAllText(''duplicate.sql'');',
 'TFile.ReadAllText(''broken.sql''); TFile.ReadAllText(''quote.sql'');',
 'TFile.ReadAllText(''limits.sql''); TFile.ReadAllText(''empty.sql''); TFile.ReadAllText(''read.sql'');',
 'end; end.']),TEncoding.UTF8);
 SQL:=String.Join(sLineBreak,[
 '-- CREATE TABLE Fake (id int);',
 'CREATE SCHEMA Sales;',
 'CREATE TABLE Sales.Customers (id integer, note varchar(80) DEFAULT ''SECRET_SQL_CANARY; CREATE VIEW Fake AS SELECT 1'');',
 'CREATE OR REPLACE VIEW Sales.Active AS SELECT id FROM Sales.Customers;',
 'CREATE TABLE "odd.schema"."odd.table" (id integer);',
 'CREATE TABLE [Legacy].[Orders] (id integer);',
 'CREATE TABLE `Web`.`Items` (id integer);',
 'CREATE TEMP TABLE Scratch (id integer);',
 'CREATE TABLE IF NOT EXISTS Existing (id integer);',
 'CREATE SCHEMA IF NOT EXISTS Safe;',
 '/* outer /* inner CREATE SCHEMA Hidden; */ comment */ CREATE VIEW Visible AS SELECT ''literal;content'';',
 'ALTER TABLE Sales.Customers ADD name varchar(30);',
 'CREATE TABLE Unbalanced (id integer;',
 'CREATE TABLE Trailing. (id integer);',
 'CREATE OR REPLACE TABLE InvalidReplace (id integer);',
 'CREATE TEMP SCHEMA InvalidTemp;',
 'CREATE VIEW IF NOT EXISTS InvalidIf AS SELECT 1;',
 'CREATE TABLE "" (id integer);',
 'CREATE FUNCTION F AS $$ BEGIN SELECT 1; END $$;',
 'CREATE VIEW WithColumns (id) AS SELECT 1;',
 'SELECT id FROM Sales.Customers;']);
 for I:=1 to 270 do SQL:=SQL+sLineBreak+'CREATE TABLE Page'+IntToStr(I)+' (id integer);';
 TFile.WriteAllText(TPath.Combine(Fixture,'schema.sql'),SQL,TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(Fixture,'duplicate.sql'),'CREATE TABLE Sales.Customers (replacement integer);',TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(Fixture,'broken.sql'),'CREATE TABLE Earlier (id integer); /* unterminated',TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(Fixture,'quote.sql'),'CREATE TABLE Quoted (id integer DEFAULT ''unterminated);',TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(Fixture,'limits.sql'),StringOfChar(' ',2*1024*1024+1),TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(Fixture,'empty.sql'),'-- no declarations',TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(Fixture,'read.sql'),'SELECT id FROM UnverifiedObject;',TEncoding.UTF8);
 SourceHash:=THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'schema.sql'));
 Analyzer:=TDPHAnalyzer.Create;Semantic:=TDPHSemanticAnalyzer.Create;
 try Scan:=Analyzer.Scan(TPath.Combine(Fixture,'Schema.dpr'),'Debug','Win32',[],[],False);
 try Graph:=Semantic.Analyze(Scan);
 try Store:=TDPHKnowledgeStore.Create(TPath.Combine(Work,'schema.dphdb'),Fixture,TPath.Combine(Root,'migrations'));
 try Store.InitializeProject('Controlled captured schema evidence','Delphi');Config:=Store.AddConfiguration('Win32','37.0','[]','[]','Debug');Store.SelectConfiguration(Config);
 Generation:=TDPHSemanticPersistence.Stage(Scan,Graph,Store,Config);
 Document:=TDPHWorkspaceView.Capture(Scan,Graph,Generation,'Schema.dpr','Debug','Win32',[],[]);
 Store.SaveWorkspaceView(Generation,Document.ToJSON);TDPHSemanticPersistence.Publish(Scan,Graph,Store,Generation);
 View:=TDPHWorkspaceView.Create(Document);Reopened:=TDPHWorkspaceView.Create(TJSONObject.ParseJSONValue(Store.LoadWorkspaceView) as TJSONObject);
 Check(Store.IntegrityCheck='ok','Persisted fixture integrity valid');
 finally Store.Free;end;finally Graph.Free;end;finally Scan.Free;end;finally Semantic.Free;Analyzer.Free;end;
 try Before:=View.Document.ToJSON;Report:=TDPHDatabaseSchema.Inspect(View);
 try
 TFile.WriteAllText(TPath.Combine(Work,'inventory.json'),Report.Format,TEncoding.UTF8);
 Check(Find('Sales','declared header')<>nil,'CREATE SCHEMA declaration captured');
 Check(Find('Sales.Customers','declared header')<>nil,'Qualified table captured');
 Check(Find('Sales.Active','declared header').GetValue<string>('kind')='view','CREATE OR REPLACE VIEW distinguished from table');
 Check(Find('Sales.Active','declared header').GetValue<string>('schema')='Sales','Schema qualifier retained');
 Check(Find('Sales','qualifier reference')<>nil,'Qualifier references distinct from explicit schemas');
 Check(Find('Sales.Customers','declared header').GetValue<Integer>('definition_count')=2,'Duplicate declarations counted without selecting winner');
 Check(Find('Sales.Customers','declared header').GetValue<string>('reason').Contains('unresolved'),'Duplicate deployment uncertainty explained');
 Check(Find('"odd.schema"."odd.table"','declared header').GetValue<string>('schema')='"odd.schema"','Dots inside quoted identifiers preserved');
 Check(Find('[Legacy].[Orders]','declared header')<>nil,'Bracket identifiers captured');
 Check(Find('`Web`.`Items`','declared header')<>nil,'Backtick identifiers captured');
 Check(Find('Scratch','declared header')<>nil,'Temporary table header captured');
 Check(Find('Existing','declared header')<>nil,'Conditional table header captured');
 Check(Find('Safe','declared header')<>nil,'Conditional schema header captured');
 Check(Find('Visible','declared header')<>nil,'Nested comments and quoted semicolons do not split declaration');
 Check(Find('Fake','declared header')=nil,'Comment and string SQL do not invent objects');
 Check(Find('Hidden','declared header')=nil,'Nested comment SQL ignored');
 Check(Find('Earlier','declared header')=nil,'Malformed lexical source not partially promoted');
 Check(Find('Unbalanced','declared header')=nil,'Unbalanced body remains unsupported');
 Check(Find('Trailing.','declared header')=nil,'Incomplete qualified name not promoted');
 Check(Find('InvalidReplace','declared header')=nil,'Unsupported replace-table header refused');
 Check(Find('InvalidTemp','declared header')=nil,'Unsupported temporary schema refused');
 Check(Find('InvalidIf','declared header')=nil,'Unsupported conditional view refused');
 Check(Find('WithColumns','declared header')=nil,'Unsupported view column-list header not guessed');
 Check(Find('UnverifiedObject','inferred reference')<>nil,'Existing SQL reference retained without inventing a definition');
 Check(Find('UnverifiedObject','inferred reference').GetValue<string>('definition')='','Inferred reference has no invented definition');
 Check(Find('UnverifiedObject','declared header')=nil,'Inferred reference never promoted to declaration');
 Check(not Report.ToJSON.Contains('SECRET_SQL_CANARY'),'String literal omitted from projected definitions');
 Check(not Report.ToJSON.Contains('literal;content'),'Quoted semicolon content omitted');
 Check(Report.ToJSON.Contains('Unterminated'),'Malformed lexical resources explain gaps');
 Check(Report.ToJSON.Contains('2 MiB'),'Oversize resource explicitly reported');
 Check(Report.ToJSON.Contains('Unsupported SQL statement'),'Migration and unsupported statements retained as gaps');
 Row:=Find('Sales.Active','declared header');
 Check(Row.GetValue<string>('source_hash')=SourceHash,'Definition retains captured SHA256');
 Check(Row.GetValue<Int64>('generation_id')=Generation,'Definition retains generation');
 Check(Row.GetValue<Integer>('range.line')=4,'Statement start line retained');
 Check(TDPHDatabaseSchema.Describe(Row).Contains('unverified'),'Details qualify definition validation');
 Check(TDPHKeyboardInspector.ReadSource(View,TPath.Combine(Fixture,'Schema.dpr'),Row,Row.GetValue<TJSONObject>('range')).Contains('CREATE SCHEMA Sales'),'Unchanged attached source opens');
 Refuses('',Row,'Detached source navigation refused');
 Other:=Row.Clone as TJSONObject;try Other.RemovePair('source').Free;Other.AddPair('source','..\outside.sql');Other.GetValue<TJSONObject>('range').RemovePair('source').Free;Other.GetValue<TJSONObject>('range').AddPair('source','..\outside.sql');Refuses(TPath.Combine(Fixture,'Schema.dpr'),Other,'Outside-project navigation refused');finally Other.Free;end;
 Other:=Row.Clone as TJSONObject;try Other.RemovePair('generation_id').Free;Other.AddPair('generation_id',TJSONNumber.Create(Generation+1));Refuses(TPath.Combine(Fixture,'Schema.dpr'),Other,'Historical generation navigation refused');finally Other.Free;end;
 TFile.AppendAllText(TPath.Combine(Fixture,'schema.sql'),sLineBreak+'-- changed',TEncoding.UTF8);Refuses(TPath.Combine(Fixture,'Schema.dpr'),Row,'Changed source navigation refused');TFile.WriteAllText(TPath.Combine(Fixture,'schema.sql'),SQL,TEncoding.UTF8);
 Check(View.Document.ToJSON=Before,'Inspector leaves captured workspace unchanged');
 Other:=TDPHDatabaseSchema.Inspect(Reopened);try Check(Other.ToJSON=Report.ToJSON,'Persisted reopening yields identical schema evidence');finally Other.Free;end;
 Catalog:=TDPHWorkspaceCatalog.DefaultPath;CatalogHash:='';if TFile.Exists(Catalog) then CatalogHash:=THashSHA2.GetHashStringFromFile(Catalog);
 Form:=TDPHMainForm.Create(nil);
 try Form.PollTimer.Enabled:=False;Form.ChangeTimer.Enabled:=False;Form.LoadView(View.Document.Clone as TJSONObject);
 Form.DatabaseSchemaKind.ItemIndex:=1;Form.DatabaseSchemaState.ItemIndex:=1;Form.DatabaseSchemaFilterChange(nil);
 Check(Form.DatabaseSchemaList.Count=250,'Native list bounds first page to 250 rows');
 Check(Form.DatabaseSchemaNext.Enabled,'Next page enabled for remaining declarations');
 Form.DatabaseSchemaFilterChange(Form.DatabaseSchemaNext);Check((Form.DatabaseSchemaList.Count>0) and (Form.DatabaseSchemaList.Count<250),'Native next page exposes remainder');
 Form.DatabaseSchemaFilter.Text:='Sales.Active';Form.DatabaseSchemaKind.ItemIndex:=2;Form.DatabaseSchemaFilterChange(nil);
 Check(Form.DatabaseSchemaList.Count=1,'Kind, state and name filters combine');
 Check(Form.DatabaseSchemaMemo.Text.Contains('CAPTURED DEFINITION'),'Native memo explains selected definition');
 Check(Form.DatabaseSchemaMemo.Text.Contains(SourceHash),'Native details expose source hash');
 Form.DatabaseSchemaSourceClick(nil);Check(Form.DatabaseSchemaMemo.Text.Contains('detached'),'Native navigation explains detached attachment');
 Form.DatabaseSchemaFilter.Text:='missing-object';Form.DatabaseSchemaFilterChange(nil);Check(Form.DatabaseSchemaMemo.Text.Contains('Empty results do not prove'),'Empty result teaches missing-evidence interpretation');
 Form.DatabaseSchemaFilter.Text:='Sales.Active';Form.DatabaseSchemaFilterChange(nil);
 Form.WorkspaceTabs.ActiveTab:=Form.DatabaseSchemaTab;Form.Show;Render('phase1-database-schema-workspace.png');
 Form.WindowState:=TWindowState.wsNormal;Form.Width:=960;Form.Height:=600;Render('phase1-database-schema-compact.png');
 Check(Form.DatabaseSchemaMemo.Height>=50,'Compact memo has readable area');
 Check(Form.DatabaseSchemaMemo.ShowScrollBars,'Long schema details scroll');
 Check(Form.DatabaseSchemaToolbar.ShowScrollBars,'Compact commands can scroll horizontally');
 Form.LoadView(Reopened.Document.Clone as TJSONObject);Check(Form.DatabaseSchemaList.Count=1,'Capture replacement rebuilds projection under current filters');Form.Hide;
 finally Form.Free;end;
 Check((not TFile.Exists(Catalog) and (CatalogHash='')) or (TFile.Exists(Catalog) and (THashSHA2.GetHashStringFromFile(Catalog)=CatalogHash)),'Owner catalog unchanged');
 Check(THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'schema.sql'))=SourceHash,'Target source restored unchanged after navigation refusal test');
 Log:=TJSONObject.Create.AddPair('result','PASS').AddPair('checks',TJSONNumber.Create(Checks)).AddPair('qualification','Controlled source SQL capture, supported declaration headers, explicit gaps, SQLite persistence and actual native FMX controls. Body grammar and deployed object existence unverified; no SQL executed.');
 try TFile.WriteAllText(TPath.Combine(Root,'docs\phase1-database-schema-validation.json'),Log.Format,TEncoding.UTF8);finally Log.Free;end;
 finally Report.Free;end;finally Reopened.Free;View.Free;end;
 Writeln('Database schema validation passed: ',Checks,' checks.');
 except on E:Exception do begin Writeln(E.ClassName,': ',E.Message);ExitCode:=1;end;end;
end.
