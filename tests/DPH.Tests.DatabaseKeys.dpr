program DPH.Tests.DatabaseKeys;
{$APPTYPE CONSOLE}
uses System.Types,System.SysUtils,System.Classes,System.IOUtils,System.JSON,System.Hash,System.StrUtils,System.UITypes,
 FMX.Forms,FMX.Graphics,DPH.Project.Analysis,DPH.Analysis.Model,DPH.Analysis.Symbols,
 DPH.Workspace.Model,DPH.Workspace.DatabaseSchema,DPH.Workspace.Keyboard,DPH.UI.Main,
 DPH.Storage.Database,DPH.Storage.Types,DPH.Analysis.Persistence,DPH.Workspace.Catalog;
var Root,Work,Fixture,SQL,ColumnCase,SourceHash,Catalog,CatalogHash,Before:string;I,Checks:Integer;
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
 Root:=TPath.GetFullPath(ParamStr(1));Work:=TPath.Combine(Root,'bin\database-keys-validation');Fixture:=TPath.Combine(Work,'source');TDirectory.CreateDirectory(Fixture);
 TFile.WriteAllText(TPath.Combine(Fixture,'Schema.dpr'),'program Schema; uses Main; begin end.',TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(Fixture,'Main.pas'),String.Join(sLineBreak,[
 'unit Main; interface implementation procedure Load; begin',
 'TFile.ReadAllText(''schema.sql''); TFile.ReadAllText(''duplicate.sql'');',
 'TFile.ReadAllText(''broken.sql''); TFile.ReadAllText(''quote.sql'');',
 'TFile.ReadAllText(''limits.sql''); TFile.ReadAllText(''empty.sql''); TFile.ReadAllText(''read.sql'');',
 'TFile.ReadAllText(''columns.sql''); TFile.ReadAllText(''columns-duplicate.sql''); TFile.ReadAllText(''keys.sql'');',
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
 TFile.WriteAllText(TPath.Combine(Fixture,'columns.sql'),String.Join(sLineBreak,[
 'CREATE TABLE Sales.Details (',
 ' id BIGINT NOT NULL PRIMARY KEY,',
 ' amount DECIMAL(12,2) DEFAULT -42.5 NOT NULL,',
 ' title CHARACTER VARYING(80) NULL DEFAULT ''SECRET_COLUMN_CANARY'',',
 ' due TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,',
 ' maybe INTEGER,',
 ' flag INTEGER DEFAULT NULL,',
 ' constrained INTEGER CONSTRAINT Positive CHECK (constrained IN (1,2)),',
 ' ref INTEGER REFERENCES Sales.Customers(id),',
 ' named INTEGER CONSTRAINT NN NOT NULL,',
 ' fn TEXT DEFAULT coalesce(''SECRET_FUNC_CANARY'', ''fallback''),',
 ' calc INTEGER DEFAULT (1 + 2) CHECK (calc > 0),',
 ' noInfer INTEGER PRIMARY KEY,',
 ' "quoted.column" custom."Money",',
 ' arraycol INTEGER[],',
 ' CONSTRAINT Details_PK PRIMARY KEY(id),',
 ' CHECK(amount IN(1,2)),',
 ' bad INTEGER GENERATED ALWAYS AS (id + 1) STORED,',
 ' conflict INTEGER NULL NOT NULL,',
 ' missing INTEGER DEFAULT,',
 ' repeated INTEGER DEFAULT 1 DEFAULT 2,',
 ' expression INTEGER DEFAULT CASE WHEN id IS NULL THEN 1 ELSE 2 END,',
 ' absenttype,',
 ' badname. integer,',
 ' namedbad INTEGER CONSTRAINT c,',
 ' malformeddefault INTEGER DEFAULT -,',
 ' missingtype NOT NULL,',
 ' typeless DEFAULT 42,',
 ' afterbad INTEGER NOT NULL',
 ');',
 'CREATE TABLE TrailingColumns (id integer,);']),TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(Fixture,'columns-duplicate.sql'),'CREATE TABLE Sales.Details (id VARCHAR(10));',TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(Fixture,'keys.sql'),String.Join(sLineBreak,[
 'CREATE TABLE Parent (a INTEGER, b INTEGER, CONSTRAINT Parent_PK PRIMARY KEY(a,b), CONSTRAINT Parent_UQ UNIQUE(b,a));',
 'CREATE TABLE Child (x INTEGER, y INTEGER, CONSTRAINT Child_FK FOREIGN KEY(x,y) REFERENCES Parent(a,b) ON DELETE CASCADE ON UPDATE NO ACTION);',
 'CREATE TABLE InlineKeys (id INTEGER CONSTRAINT Inline_PK PRIMARY KEY, code TEXT CONSTRAINT Inline_UQ UNIQUE, parent INTEGER CONSTRAINT Inline_FK REFERENCES Parent(a));',
 'CREATE TABLE SelfRef (id INTEGER PRIMARY KEY, parent INTEGER REFERENCES SelfRef(id));',
 'CREATE TABLE Absent (id INTEGER, CONSTRAINT Missing_FK FOREIGN KEY(id) REFERENCES NotCaptured(id));',
 'CREATE TABLE Ambiguous (id INTEGER); CREATE TABLE Ambiguous (id TEXT);',
 'CREATE TABLE RefAmbiguous (id INTEGER, CONSTRAINT Ambiguous_FK FOREIGN KEY(id) REFERENCES Ambiguous(id));',
 'CREATE TABLE NoColumns (id INTEGER, CONSTRAINT Omitted_FK FOREIGN KEY(id) REFERENCES Parent);',
 'CREATE TABLE Mismatch (id INTEGER, CONSTRAINT Mismatch_FK FOREIGN KEY(id) REFERENCES Parent(a,b));',
 'CREATE TABLE MissingMember (id INTEGER, CONSTRAINT Missing_PK PRIMARY KEY(absent));',
 'CREATE TABLE DuplicateColumns (id INTEGER, id TEXT, CONSTRAINT Duplicate_UQ UNIQUE(id));',
 'CREATE TABLE DuplicatePrimary (a INTEGER PRIMARY KEY, b INTEGER PRIMARY KEY);',
 'CREATE TABLE InvalidKeys (id INTEGER, CONSTRAINT Repeated_UQ UNIQUE(id,id), CONSTRAINT Expression_UQ UNIQUE(lower(id)), CONSTRAINT Tail_UQ UNIQUE(id) DEFERRABLE, CONSTRAINT Empty_PK PRIMARY KEY(), CONSTRAINT BadAction_FK FOREIGN KEY(id) REFERENCES Parent(a) ON DELETE UNKNOWN);',
 'CREATE TABLE InvalidInline (id INTEGER PRIMARY KEY COLLATE unknown);',
 'CREATE TABLE "Quoted Parent" ("odd.column" INTEGER PRIMARY KEY);',
 'CREATE TABLE "Quoted Child" ("local.column" INTEGER REFERENCES "Quoted Parent"("odd.column"));',
 'CREATE TABLE CaseMismatch (id INTEGER REFERENCES parent(a));',
 'CREATE TABLE MissingTargetColumn (id INTEGER, CONSTRAINT AbsentColumn_FK FOREIGN KEY(id) REFERENCES Parent(absent));',
 'CREATE TABLE DuplicateKeyName (a INTEGER CONSTRAINT Same UNIQUE, b INTEGER CONSTRAINT Same UNIQUE);',
 'CREATE TABLE LiteralSafety (id INTEGER DEFAULT ''PRIMARY KEY SECRET_KEY_CANARY'', CHECK(id IN(1,2)));',
 'CREATE TABLE LateForeign (id INTEGER REFERENCES Page270(id));'
 ]),TEncoding.UTF8);
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
 Check(Find('Sales.Details.id','declared column')<>nil,'Actual CREATE column declaration captured');
 Check(Find('Sales.Details.id','declared column').GetValue<string>('declared_type')='VARCHAR(10)','First duplicate retains its own declared type');
 Row:=Find('Sales.Details.amount','declared column');
 Check(Row.GetValue<string>('declared_type')='DECIMAL(12, 2)','Type precision and comma retained without splitting a column');
 Check(Row.GetValue<string>('default')='-42.5','Signed numeric default retained');
 Check(Row.GetValue<string>('nullability')='explicit NOT NULL','Nullability after DEFAULT parsed separately');
 Check(Row.GetValue<string>('table')='Sales.Details','Column retains qualified table');
 Check(Row.GetValue<string>('source')='columns.sql','Column retains original source file');
 Check(Row.GetValue<Integer>('range.line')=3,'Column declaration start line retained');
 Check(Row.GetValue<string>('source_hash')=THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'columns.sql')),'Column retains actual source hash');
 Check(Row.GetValue<Int64>('generation_id')=Generation,'Column retains captured generation');
 Check(Row.GetValue<string>('declaration_id')<>'','Column retains unique parent declaration identity');
 Check(Find('Sales.Details.title','declared column').GetValue<string>('declared_type')='CHARACTER VARYING(80)','Multiword type retained');
 Check(Find('Sales.Details.title','declared column').GetValue<string>('nullability')='explicit NULL','Explicit NULL distinguished from unspecified');
 Check(Find('Sales.Details.title','declared column').GetValue<string>('default')='[literal omitted]','Literal default masked with explicit marker');
 Check(Find('Sales.Details.due','declared column').GetValue<string>('declared_type')='TIMESTAMP WITHOUT TIME ZONE','Timestamp qualifier retained');
 Check(Find('Sales.Details.due','declared column').GetValue<string>('default')='CURRENT_TIMESTAMP','Symbolic default retained without evaluating');
 Check(Find('Sales.Details.maybe','declared column').GetValue<string>('nullability')='not declared','Absent nullability not invented');
 Check(Find('Sales.Details.maybe','declared column').GetValue<string>('default')='not declared','Absent default not invented');
 Check(Find('Sales.Details.flag','declared column').GetValue<string>('default')='NULL','DEFAULT NULL remains a default expression');
 Check(Find('Sales.Details.flag','declared column').GetValue<string>('nullability')='not declared','DEFAULT NULL does not become an explicit nullability clause');
 Check(Find('Sales.Details.constrained','declared column').GetValue<string>('constraints').Contains('CONSTRAINT Positive CHECK'),'Named CHECK text retained');
 Check(Find('Sales.Details.ref','declared column').GetValue<string>('constraints').Contains('REFERENCES Sales.Customers'),'Inline reference clause retained as text only');
 Check(Find('Sales.Details.named','declared column').GetValue<string>('nullability')='explicit NOT NULL','Named NOT NULL clause captured');
 Check(Find('Sales.Details.fn','declared column').GetValue<string>('default').Contains('coalesce([literal omitted], [literal omitted])'),'Function default commas and literals handled');
 Check(Find('Sales.Details.calc','declared column').GetValue<string>('default')='(1 + 2)','Parenthesized default expression retained');
 Check(Find('Sales.Details.calc','declared column').GetValue<string>('constraints').Contains('CHECK'),'Default and CHECK stay separate');
 Check(Find('Sales.Details.noInfer','declared column').GetValue<string>('nullability')='not declared','Primary key does not invent explicit NOT NULL declaration');
 Check(Find('Sales.Details."quoted.column"','declared column').GetValue<string>('declared_type')='custom."Money"','Quoted name and qualified custom type preserved');
 Check(Find('Sales.Details.arraycol','declared column').GetValue<string>('declared_type')='INTEGER[]','Array type suffix retained');
 Check(Find('Sales.Details | CONSTRAINT','captured constraint').GetValue<string>('scope')='table','Table constraint not misclassified as column');
 Check(Find('Sales.Details | CHECK','captured constraint').GetValue<string>('definition').Contains('1, 2'),'Table CHECK commas remain in one entry');
 for ColumnCase in ['bad','conflict','missing','repeated','expression','absenttype','badname','namedbad','malformeddefault','missingtype','typeless'] do begin
  Check(Find('Sales.Details.'+ColumnCase,'declared column')=nil,'Unsupported column not promoted: '+ColumnCase);
  Check(Find('Sales.Details.'+ColumnCase,'unsupported')<>nil,'Unsupported column entry explained: '+ColumnCase);
 end;
 Check(Find('Sales.Details.afterbad','declared column')<>nil,'Supported following column survives earlier entry gaps');
 Check(Find('TrailingColumns | empty entry','unsupported')<>nil,'Trailing empty column entry explicitly reported');
 Check(not Report.ToJSON.Contains('SECRET_'),'All column literal canaries absent from projection');
 Check(TDPHDatabaseSchema.Describe(Row).Contains('Declared type: DECIMAL'),'Column explanation displays type before long qualifications');
 Check(TDPHDatabaseSchema.Describe(Row).Contains('not an effective database default'),'Column explanation teaches absent-declaration meaning');
 Other:=nil;for V in Report.GetValue<TJSONArray>('rows') do if (V.GetValue<string>('name')='Sales.Details.id') and (V.GetValue<string>('source')='columns.sql') then Other:=V as TJSONObject;
 Check((Other<>nil) and (Other.GetValue<string>('declared_type')='BIGINT'),'Other duplicate column retains distinct type');
 Check(Other.GetValue<string>('declaration_id')<>Find('Sales.Details.id','declared column').GetValue<string>('declaration_id'),'Duplicate table declarations never merge column ownership');

 Row:=Find('Parent | Parent_PK','declared key');Check(Row<>nil,'Composite named primary key captured');
 Check(Row.GetValue<string>('key_kind')='primary','Primary type retained');
 Check(Row.GetValue<TJSONArray>('members').ToJSON='["a","b"]','Composite primary membership order retained');
 Check(Row.GetValue<string>('relationship_status')='captured links complete','Primary members resolve inside exact table declaration');
 Check(Row.GetValue<TJSONArray>('links').Count=3,'Owner and ordered primary member links present');
 Check(Find('Parent | Parent_UQ','declared key').GetValue<TJSONArray>('members').ToJSON='["b","a"]','Unique member order distinct from primary order');
 Row:=Find('Child | Child_FK','declared key');
 Check(Row.GetValue<string>('key_kind')='foreign','Composite foreign key captured');
 Check(Row.GetValue<TJSONArray>('members').ToJSON='["x","y"]','Foreign local order retained');
 Check(Row.GetValue<TJSONArray>('reference_columns').ToJSON='["a","b"]','Foreign referenced order retained');
 Check(Row.GetValue<string>('reference_table')='Parent','Foreign target exact name retained');
 Check(Row.GetValue<string>('referential_actions').Contains('ON DELETE CASCADE'),'Declared delete action captured');
 Check(Row.GetValue<string>('referential_actions').Contains('ON UPDATE NO ACTION'),'Declared update action captured');
 Check(Row.GetValue<string>('relationship_status')='captured links complete','Unique foreign targets resolved');
 Check(Row.GetValue<TJSONArray>('links').Count=6,'Owner local target table and referenced column links present');
 Check(Row.GetValue<TJSONArray>('links').Items[4].GetValue<string>('target_id')=Find('Parent.a','declared column').GetValue<string>('id'),'Referenced first member points to exact captured column');
 Check(Find('InlineKeys | Inline_PK','declared key').GetValue<TJSONArray>('members').ToJSON='["id"]','Named inline primary key becomes single member');
 Check(Find('InlineKeys | Inline_UQ','declared key').GetValue<string>('key_kind')='unique','Named inline unique key captured');
 Check(Find('InlineKeys | Inline_FK','declared key').GetValue<string>('reference_table')='Parent','Named inline reference captured');
 for V in Report.GetValue<TJSONArray>('rows') do if (V.GetValue<string>('kind')='key') and (V.GetValue<string>('table')='SelfRef') and (V.GetValue<string>('key_kind')='foreign') then Check(V.GetValue<string>('relationship_status')='captured links complete','Self reference resolves after full capture');
 Check(Find('Absent | Missing_FK','declared key').GetValue<string>('relationship_status')='relationship gaps','Absent target remains explicit relationship gap');
 Check(Find('RefAmbiguous | Ambiguous_FK','declared key').ToJSON.Contains('ambiguous captured declarations'),'Duplicate table targets do not choose a winner');
 Check(not Find('RefAmbiguous | Ambiguous_FK','declared key').GetValue<TJSONArray>('links').Items[2].ToJSON.Contains('target_id'),'Ambiguous referenced table has no invented link');
 Check(Find('NoColumns | Omitted_FK','declared key').GetValue<string>('reference_note').Contains('no default primary-key target guessed'),'Omitted reference columns remain unknown');
 Check(Find('Mismatch | Mismatch_FK','declared key').GetValue<string>('reference_note').Contains('counts differ'),'Arity mismatch explicitly qualified');
 Check(Find('MissingMember | Missing_PK','declared key').ToJSON.Contains('missing captured declaration'),'Missing local key column reported');
 Check(Find('DuplicateColumns | Duplicate_UQ','declared key').ToJSON.Contains('ambiguous captured declarations'),'Duplicate local column remains ambiguous');
 for V in Report.GetValue<TJSONArray>('rows') do if (V.GetValue<string>('kind')='key') and (V.GetValue<string>('table')='DuplicatePrimary') then Check(V.GetValue<string>('conflict').Contains('Multiple primary-key'),'Conflicting primary declarations retained without winner');
 for ColumnCase in ['Repeated_UQ','Expression_UQ','Tail_UQ','Empty_PK','BadAction_FK'] do Check(Find('InvalidKeys | '+ColumnCase,'declared key')=nil,'Malformed or unsupported key not promoted: '+ColumnCase);
 Check(Report.ToJSON.Contains('Key extraction gap'),'Unsupported key grammar has explicit explanation');
 Check(not Report.ToJSON.Contains('InvalidInline | anonymous primary'),'Unsupported column tail cannot leak partial key');
 for V in Report.GetValue<TJSONArray>('rows') do if (V.GetValue<string>('kind')='key') and (V.GetValue<string>('table')='"Quoted Child"') then Check(V.GetValue<string>('relationship_status')='captured links complete','Quoted dotted identifier remains exact single member');
 for V in Report.GetValue<TJSONArray>('rows') do if (V.GetValue<string>('kind')='key') and (V.GetValue<string>('table')='CaseMismatch') then Check(V.GetValue<string>('relationship_status')='relationship gaps','Dialect case folding is not guessed');
 Check(Find('MissingTargetColumn | AbsentColumn_FK','declared key').ToJSON.Contains('missing captured declaration'),'Missing referenced column reported');
 Check(Find('DuplicateKeyName | Same','declared key').GetValue<string>('name_conflict').Contains('Duplicate constraint name'),'Duplicate constraint names remain distinct and flagged');
 Check(not Report.ToJSON.Contains('SECRET_KEY_CANARY'),'Key-like string content omitted');
 Check(not Report.ToJSON.Contains('LiteralSafety | anonymous primary'),'Default and CHECK do not invent keys');
 Check(Row.GetValue<Int64>('generation_id')=Generation,'Key retains capture generation');
 Check(Row.GetValue<string>('source_hash')=THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'keys.sql')),'Key retains original SQL hash');
 Check(TDPHDatabaseSchema.Describe(Row).Contains('Ordered local columns'),'Key explanation leads with structured facts');
 Check(TDPHKeyboardInspector.ReadSource(View,TPath.Combine(Fixture,'Schema.dpr'),Row,Row.GetValue<TJSONObject>('range')).Contains('Child_FK'),'Guarded key source navigation works');
 Refuses('',Row,'Detached key source refused');

 Other:=nil;
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
 Form.DatabaseSchemaKind.ItemIndex:=5;Form.DatabaseSchemaState.ItemIndex:=5;Form.DatabaseSchemaFilter.Text:='DECIMAL';Form.DatabaseSchemaFilterChange(nil);
 Check(Form.DatabaseSchemaList.Count=1,'Native declared-type filter finds captured column');
 Check(Form.DatabaseSchemaMemo.Text.Contains('Nullability declaration: explicit NOT NULL'),'Native column nullability explained');
 Check(Form.DatabaseSchemaMemo.Text.Contains('Default declaration: -42.5'),'Native default evidence displayed');
 Form.DatabaseSchemaFilter.Text:='missing-column';Form.DatabaseSchemaFilterChange(nil);Check(Form.DatabaseSchemaList.Count=0,'Native column empty filter handled');
 Form.DatabaseSchemaFilter.Text:='DECIMAL';Form.DatabaseSchemaFilterChange(nil);

 Form.DatabaseSchemaKind.ItemIndex:=7;Form.DatabaseSchemaState.ItemIndex:=7;Form.DatabaseSchemaFilter.Text:='Child_FK';Form.DatabaseSchemaFilterChange(nil);
 Check(Form.DatabaseSchemaList.Count=1,'Native key kind state and constraint name filters combine');
 Check(Form.DatabaseSchemaMemo.Text.Contains('Ordered local columns'),'Native key details explain composite membership');
 Check(Form.DatabaseSchemaLinks.Items.Count=6,'Native relationship selector exposes exact targets');
 Form.DatabaseSchemaLinks.ItemIndex:=4;Form.DatabaseSchemaFollowClick(nil);
 Check(Form.DatabaseSchemaMemo.Text.Contains('COLUMN Parent.a'),'Follow relationship selects exact captured target across pages');
 Form.DatabaseSchemaKind.ItemIndex:=7;Form.DatabaseSchemaState.ItemIndex:=7;Form.DatabaseSchemaFilter.Text:='Child_FK';Form.DatabaseSchemaFilterChange(nil);
 Form.DatabaseSchemaKind.ItemIndex:=7;Form.DatabaseSchemaState.ItemIndex:=7;Form.DatabaseSchemaFilter.Text:='LateForeign';Form.DatabaseSchemaFilterChange(nil);
 Form.DatabaseSchemaLinks.ItemIndex:=2;Form.DatabaseSchemaFollowClick(nil);
 Check(Form.DatabaseSchemaMemo.Text.Contains('TABLE Page270'),'Foreign target on later inventory page selected by exact ID');
 Form.DatabaseSchemaKind.ItemIndex:=7;Form.DatabaseSchemaState.ItemIndex:=7;Form.DatabaseSchemaFilter.Text:='Child_FK';Form.DatabaseSchemaFilterChange(nil);
 Form.WorkspaceTabs.ActiveTab:=Form.DatabaseSchemaTab;Form.Show;Render('phase1-database-keys-workspace.png');
 Form.WindowState:=TWindowState.wsNormal;Form.Width:=960;Form.Height:=600;Render('phase1-database-keys-compact.png');
 Form.DatabaseSchemaToolbar.ViewportPosition:=PointF(10000,0);Application.ProcessMessages;
 Check(Form.DatabaseSchemaFollow.AbsoluteRect.Right<=Form.DatabaseSchemaToolbar.AbsoluteRect.Right+2,'Relationship command reachable at minimum width');
 Render('phase1-database-keys-relationships.png');
 Check(Form.DatabaseSchemaMemo.Height>=50,'Compact memo has readable area');
 Check(Form.DatabaseSchemaMemo.ShowScrollBars,'Long schema details scroll');
 Check(Form.DatabaseSchemaToolbar.ShowScrollBars,'Compact commands can scroll horizontally');
 Form.LoadView(Reopened.Document.Clone as TJSONObject);Check(Form.DatabaseSchemaList.Count=1,'Capture replacement rebuilds projection under current filters');Form.Hide;
 finally Form.Free;end;
 Check((not TFile.Exists(Catalog) and (CatalogHash='')) or (TFile.Exists(Catalog) and (THashSHA2.GetHashStringFromFile(Catalog)=CatalogHash)),'Owner catalog unchanged');
 Check(THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'schema.sql'))=SourceHash,'Target source restored unchanged after navigation refusal test');
 Log:=TJSONObject.Create.AddPair('result','PASS').AddPair('checks',TJSONNumber.Create(Checks)).AddPair('qualification','Controlled captured primary/foreign/unique keys, ordered relationships, unresolved evidence, grammar gaps, persistence and native FMX navigation. Expressions and deployed enforcement unverified; no SQL executed.');
 try TFile.WriteAllText(TPath.Combine(Root,'docs\validation\reports\phase1-database-keys-validation.json'),Log.Format,TEncoding.UTF8);finally Log.Free;end;
 finally Report.Free;end;finally Reopened.Free;View.Free;end;
 Writeln('Database keys validation passed: ',Checks,' checks.');
 except on E:Exception do begin Writeln(E.ClassName,': ',E.Message);ExitCode:=1;end;end;
end.
