program DPH.Tests.DatabaseER;
{$APPTYPE CONSOLE}
uses System.Types,System.SysUtils,System.Classes,System.IOUtils,System.JSON,System.Hash,System.StrUtils,System.UITypes,
 FMX.Forms,FMX.Graphics,DPH.Project.Analysis,DPH.Analysis.Model,DPH.Analysis.Symbols,
 DPH.Workspace.Model,DPH.Workspace.DatabaseSchema,DPH.Workspace.Keyboard,DPH.UI.Main,
 DPH.Storage.Database,DPH.Storage.Types,DPH.Analysis.Persistence,DPH.Workspace.Catalog;
var Root,Work,Fixture,SQL,ColumnCase,SourceHash,Catalog,CatalogHash,Before:string;I,Checks:Integer;
 Analyzer:TDPHAnalyzer;Semantic:TDPHSemanticAnalyzer;Scan:TDPHScan;Graph:TDPHSemanticGraph;
 View,Reopened,Stress:TDPHWorkspaceView;Document,Report,Other,Row,Log,StressDocument,StressSymbol,StressRelation,StressReport:TJSONObject;V:TJSONValue;
 Store:TDPHKnowledgeStore;Config,Generation:Int64;Form:TDPHMainForm;Bitmap:TBitmap;Diagram,ERNode,EREdge:TJSONObject;Rejected:Boolean;
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
 Root:=TPath.GetFullPath(ParamStr(1));Work:=TPath.Combine(Root,'bin\database-er-validation');Fixture:=TPath.Combine(Work,'source');TDirectory.CreateDirectory(Fixture);
 TFile.WriteAllText(TPath.Combine(Fixture,'Schema.dpr'),'program Schema; uses Main; begin end.',TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(Fixture,'Main.pas'),String.Join(sLineBreak,[
 'unit Main; interface implementation procedure Load; begin',
 'TFile.ReadAllText(''schema.sql''); TFile.ReadAllText(''duplicate.sql'');',
 'TFile.ReadAllText(''broken.sql''); TFile.ReadAllText(''quote.sql'');',
 'TFile.ReadAllText(''limits.sql''); TFile.ReadAllText(''empty.sql''); TFile.ReadAllText(''read.sql'');',
 'TFile.ReadAllText(''columns.sql''); TFile.ReadAllText(''columns-duplicate.sql''); TFile.ReadAllText(''keys.sql''); TFile.ReadAllText(''indexes.sql''); TFile.ReadAllText(''index-use.sql'');',
 'TFile.ReadAllText(''er.sql''); TFile.ReadAllText(''stored-limits.sql''); TFile.ReadAllText(''stored.sql''); TFile.ReadAllText(''stored-broken.sql''); TFile.ReadAllText(''stored-dollar.sql'');',
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
 TFile.WriteAllText(TPath.Combine(Fixture,'indexes.sql'),String.Join(sLineBreak,[
 'CREATE TABLE Data.Target (a INTEGER, b INTEGER, code TEXT, note TEXT, status INTEGER);',
 'CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS IX_Composite ON ONLY Data.Target USING btree(a DESC NULLS LAST,b ASC) INCLUDE(note) NULLS NOT DISTINCT WITH(fillfactor=80) TABLESPACE fastdisk WHERE status=1 AND note<>''SECRET_INDEX_CANARY'';',
 'CREATE INDEX IX_Expression ON Data.Target(lower(code), (a+b) DESC);',
 'CREATE CLUSTERED INDEX IX_Clustered ON Data.Target(a);',
 'CREATE UNIQUE NONCLUSTERED INDEX IX_Nonclustered ON Data.Target(b) INCLUDE(code);',
 'CREATE INDEX IX_Missing ON NotCaptured(id);',
 'CREATE INDEX IX_Ambiguous ON Ambiguous(id);',
 'CREATE INDEX IX_MissingColumn ON Data.Target(absent);',
 'CREATE INDEX IX_DuplicateColumn ON DuplicateColumns(id);',
 'CREATE INDEX IX_Duplicate ON Data.Target(a); CREATE INDEX IX_Duplicate ON Data.Target(b);',
 'CREATE INDEX "IX.quoted" ON "Quoted Parent"("odd.column" DESC);',
 'CREATE INDEX IX_Late ON Page270(id);',
 'CREATE INDEX IX_NoUsage ON Parent(a);',
 'CREATE INDEX IX_CaseMismatch ON data.target(a);',
 'CREATE INDEX IX_IncludeMissing ON Data.Target(a) INCLUDE(absent);',
 'CREATE INDEX IX_Method ON Data.Target USING hash(a);',
 'CREATE INDEX IX_Empty ON Data.Target();',
 'CREATE INDEX IX_Trailing ON Data.Target(a,);',
 'CREATE INDEX IX_BadSort ON Data.Target(a SIDEWAYS);',
 'CREATE INDEX IX_Collation ON Data.Target(code COLLATE custom);',
 'CREATE INDEX IX_BadInclude ON Data.Target(a) INCLUDE(note,note);',
 'CREATE INDEX IX_EmptyPredicate ON Data.Target(a) WHERE;',
 'CREATE INDEX IX_BadPredicate ON Data.Target(a) WHERE (a=1;',
 'CREATE INDEX IX_NoOn Data.Target(a);',
 'CREATE INDEX IX_BadTail ON Data.Target(a) MYSTERY;',
 'CREATE INDEX IX_NoName ON Data.Target;',
 'CREATE INDEX IX_Dot. ON Data.Target(a);',
 'CREATE INDEX IX_EmptyExpression ON Data.Target(());',
 'CREATE INDEX IX_EmptyStorage ON Data.Target(a) WITH();',
 'CREATE INDEX IX_ComplexPredicate ON Data.Target(a) WHERE a IN(SELECT a FROM Other);',
 'CREATE INDEX IX_NullOrder ON Data.Target(a NULLS SIDEWAYS);',
 'CREATE INDEX IX_NoMethod ON Data.Target USING (a);',
 'CREATE INDEX IX_MissingIncluded ON Data.Target(a) INCLUDE();',
 'CREATE INDEX IX_QualifiedName ON Data.Target(a);',
 'CREATE INDEX "Data"."IX.WithDot" ON Data.Target(a);',
 'CREATE TABLE IndexLiteral (id TEXT DEFAULT ''CREATE INDEX SECRET_INDEX_FAKE ON Data.Target(a)'');',
 '-- CREATE INDEX HiddenIndex ON Data.Target(a);',
 'ALTER INDEX IX_Composite RENAME TO Unsupported;'
 ]),TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(Fixture,'index-use.sql'),'SELECT a, b FROM Data.Target;',TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(Fixture,'stored.sql'),String.Join(sLineBreak,[
 'CREATE PROCEDURE Data.Save (IN item INTEGER, OUT result NUMERIC(12,2), INOUT note TEXT DEFAULT ''SECRET_STORED_DEFAULT'') AS BEGIN',
 ' INSERT INTO Data.Target(a,note) VALUES(item,''SECRET_STORED_BODY; CREATE TABLE FakeStored(id int)'');',
 ' UPDATE Data.Target SET b=item; CALL Data.Log(item);',
 ' BEGIN SELECT a FROM Page270; END;',
 ' SELECT CASE WHEN a>1 THEN a ELSE 0 END FROM Data.Target;',
 ' END;',
 'CREATE PROCEDURE Data.Log (item INTEGER) AS BEGIN SELECT a FROM Data.Target; END;',
 'CREATE OR REPLACE FUNCTION Data.Total (item INTEGER DEFAULT 1) RETURNS DECIMAL(12,2) LANGUAGE sql AS $body$ SELECT a FROM Data.Target WHERE a=item; $body$;',
 'CREATE FUNCTION Data.Hook () RETURNS trigger AS $$ BEGIN RETURN NEW; END; $$ LANGUAGE plpgsql;',
 'CREATE TRIGGER Data.Audit AFTER INSERT OR UPDATE ON Data.Target FOR EACH ROW WHEN (NEW.a>0) EXECUTE FUNCTION Data.Hook();',
 'CREATE TRIGGER AuditInline BEFORE DELETE ON Data.Target FOR EACH ROW BEGIN INSERT INTO Parent(a) VALUES(OLD.a); END;',
 'CREATE OR ALTER PROC Legacy.Save @item INT, @result DECIMAL(10,2) = 0 OUTPUT AS BEGIN EXEC Data.Log @item; END;',
 'GO',
 'CREATE PROCEDURE AfterBatch () AS BEGIN CALL Data.Log(1); END;',
 'CREATE FUNCTION SingleQuoted (item INTEGER) RETURNS INTEGER LANGUAGE sql AS ''SELECT a FROM Data.Target WHERE note=''''SECRET_STORED_QUOTED'''';'';',
 'CREATE PROCEDURE MissingRef () AS BEGIN SELECT id FROM NotCaptured; CALL MissingRoutine(); END;',
 'CREATE PROCEDURE AmbiguousRef () AS BEGIN SELECT id FROM Ambiguous; END;',
 'CREATE PROCEDURE DynamicRef () AS BEGIN EXECUTE ''SELECT id FROM SECRET_STORED_DYNAMIC''; EXEC @selected; END;',
 'CREATE PROCEDURE "Quoted.Procedure" ("odd.parameter" custom."Type") AS BEGIN SELECT "odd.column" FROM "Quoted Parent"; END;',
 'CREATE FUNCTION Overload (item INTEGER) RETURNS INTEGER AS BEGIN RETURN item; END;',
 'CREATE FUNCTION Overload (item TEXT) RETURNS TEXT AS BEGIN RETURN item; END;',
 'CREATE TRIGGER AmbiguousHook AFTER INSERT ON Parent EXECUTE FUNCTION Overload();',
 'CREATE TRIGGER AbsentTable AFTER INSERT ON NotCaptured EXECUTE FUNCTION Data.Hook();',
 'CREATE PROCEDURE DDLInside () AS BEGIN CREATE TABLE InternalOnly (id INT); SELECT id FROM InternalOnly; END;',
 'CREATE TABLE AfterStored (id INTEGER);',
 'CREATE PROCEDURE CTERef () AS BEGIN WITH Data AS (SELECT a FROM Data.Target) SELECT a FROM Data; END;',
 'CREATE PROCEDURE TypeTail (item INTEGER MYSTERY) AS BEGIN SELECT 1; END;',
 'CREATE PROCEDURE AS BEGIN SELECT 1; END;',
 'CREATE PROCEDURE EmptyDefault (item INTEGER DEFAULT) AS BEGIN SELECT 1; END;',
 'CREATE PROCEDURE DuplicateParam (item INTEGER,item TEXT) AS BEGIN SELECT 1; END;',
 'CREATE PROCEDURE TrailingParam (item INTEGER,) AS BEGIN SELECT 1; END;',
 'CREATE PROCEDURE TypelessParam (item) AS BEGIN SELECT 1; END;',
 'CREATE FUNCTION NoReturns (item INTEGER) AS BEGIN RETURN item; END;',
 'CREATE FUNCTION BadLanguage () RETURNS INTEGER LANGUAGE python AS $$ SECRET_STORED_EXTERNAL $$;',
 'CREATE FUNCTION EmptyBody () RETURNS INTEGER LANGUAGE sql AS $$$$;',
 'CREATE TRIGGER BadEvent AFTER UNKNOWN ON Parent BEGIN SELECT 1; END;',
 'CREATE TRIGGER BadCall AFTER INSERT ON Parent EXECUTE FUNCTION Data.Hook(1);',
 'CREATE PROCEDURE BadTail () AS BEGIN SELECT 1; END MYSTERY;',
 '-- CREATE PROCEDURE HiddenStored () AS BEGIN SELECT 1; END;',
 'CREATE TABLE StoredCanary (note TEXT DEFAULT ''CREATE PROCEDURE SECRET_STORED_FAKE'');'
 ]),TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(Fixture,'stored-broken.sql'),'CREATE PROCEDURE Broken () AS BEGIN SELECT 1; CREATE TABLE HiddenInsideBroken (id INT);',TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(Fixture,'stored-dollar.sql'),'CREATE FUNCTION BrokenDollar () RETURNS INT LANGUAGE sql AS $bad$ SELECT 1;',TEncoding.UTF8);
 ColumnCase:='CREATE PROCEDURE LimitRefs () AS BEGIN ';
 for I:=1 to 1100 do ColumnCase:=ColumnCase+'SELECT a FROM Data.Target; ';
 ColumnCase:=ColumnCase+'END;';TFile.WriteAllText(TPath.Combine(Fixture,'stored-limits.sql'),ColumnCase,TEncoding.UTF8);
 ColumnCase:=String.Join(sLineBreak,[
 'CREATE TABLE ER_Customers (id INTEGER PRIMARY KEY, name VARCHAR(80), active INTEGER DEFAULT 1);',
 'CREATE TABLE ER_Orders (id INTEGER PRIMARY KEY, customer_id INTEGER, total NUMERIC(12,2), CONSTRAINT ER_OrderCustomer FOREIGN KEY(customer_id) REFERENCES ER_Customers(id));',
 'CREATE TABLE ER_Lines (id INTEGER PRIMARY KEY, order_id INTEGER, description TEXT, quantity INTEGER, CONSTRAINT ER_LineOrder FOREIGN KEY(order_id) REFERENCES ER_Orders(id));',
 'CREATE TABLE ER_ManyLinks (id INTEGER,']);
 for I:=1 to 130 do begin ColumnCase:=ColumnCase+'CONSTRAINT Many'+IntToStr(I)+' FOREIGN KEY(id) REFERENCES Parent(a)';if I<130 then ColumnCase:=ColumnCase+',';end;
 ColumnCase:=ColumnCase+');';TFile.WriteAllText(TPath.Combine(Fixture,'er.sql'),ColumnCase,TEncoding.UTF8);
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


 Row:=Find('IX_Composite','declared index');Check(Row<>nil,'Structured composite index captured');
 Check(Row.GetValue<Boolean>('unique'),'Unique declaration captured');
 Check(Row.GetValue<Boolean>('concurrently'),'CONCURRENTLY declaration captured');
 Check(Row.GetValue<Boolean>('conditional'),'Conditional creation declaration captured');
 Check(Row.GetValue<Boolean>('only_table'),'ONLY declaration captured');
 Check(Row.GetValue<string>('table')='Data.Target','Index target exact qualified spelling retained');
 Check(Row.GetValue<string>('schema')='Data','Target schema qualifier captured');
 Check(Row.GetValue<string>('method')='btree','Explicit index method retained');
 Check(Row.GetValue<TJSONArray>('members').Count=2,'Composite index member count captured');
 Check(Row.GetValue<TJSONArray>('members').Items[0].GetValue<string>('column')='a','First composite member retained');
 Check(Row.GetValue<TJSONArray>('members').Items[1].GetValue<string>('column')='b','Second composite member retained');
 Check(Row.GetValue<TJSONArray>('members').Items[0].GetValue<string>('sort')='DESC','Descending member order retained');
 Check(Row.GetValue<TJSONArray>('members').Items[1].GetValue<string>('sort')='ASC','Ascending member order retained');
 Check(Row.GetValue<TJSONArray>('members').Items[0].GetValue<string>('nulls')='LAST','Declared NULLS LAST retained');
 Check(Row.GetValue<TJSONArray>('included_columns').ToJSON='["note"]','Included columns distinct from ordered members');
 Check(Row.GetValue<string>('null_treatment')='NULLS NOT DISTINCT','Unique null treatment retained');
 Check(Row.GetValue<string>('storage_options').Contains('fillfactor = 80'),'Captured storage options retained without evaluation');
 Check(Row.GetValue<string>('tablespace')='fastdisk','Declared tablespace retained');
 Check(Row.GetValue<string>('predicate').Contains('status = 1'),'Partial index predicate retained');
 Check(Row.GetValue<string>('predicate').Contains('[literal omitted]'),'Predicate literals omitted');
 Check(Row.GetValue<string>('relationship_status')='captured links complete','Unique table column and include evidence resolved');
 Check(Row.GetValue<Integer>('usage_reference_count')=1,'Exact captured SQL table usage linked');
 Check(Row.GetValue<TJSONArray>('links').Count=5,'Table member include and SQL evidence links present');
 Check(Row.GetValue<TJSONArray>('links').Items[1].GetValue<string>('target_id')=Find('Data.Target.a','declared column').GetValue<string>('id'),'Indexed column link targets exact captured row');
 Check(Row.GetValue<TJSONArray>('links').Items[4].GetValue<string>('role').Contains('index use unobserved'),'SQL evidence never claims actual index selection');
 Check(Row.GetValue<string>('usage_note').Contains('Zero references'),'No-reference interpretation explained');
 Check(Row.GetValue<string>('source_hash')=THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'indexes.sql')),'Index retains original SQL SHA256');
 Check(Row.GetValue<Int64>('generation_id')=Generation,'Index retains capture generation');
 Check(Row.GetValue<Integer>('range.line')=2,'Index statement line retained');
 Check(TDPHDatabaseSchema.Describe(Row).Contains('No query plan'),'Index explanation qualifies performance conclusions');
 Check(TDPHKeyboardInspector.ReadSource(View,TPath.Combine(Fixture,'Schema.dpr'),Row,Row.GetValue<TJSONObject>('range')).Contains('IX_Composite'),'Unchanged index source can open');
 Refuses('',Row,'Detached index source refused');
 Other:=Find('IX_Expression','declared index');
 Check(Other.GetValue<TJSONArray>('members').Items[0].GetValue<string>('column')='','Function expression does not invent a column');
 Check(Other.GetValue<TJSONArray>('members').Items[1].GetValue<string>('expression').Contains('a + b'),'Parenthesized expression captured');
 Check(Other.GetValue<string>('relationship_status')='relationship gaps','Expression dependencies remain explicit gaps');
 Check(Other.ToJSON.Contains('expression dependencies unverified'),'Expression uncertainty explained');
 Check(Find('IX_Clustered','declared index').GetValue<string>('storage_kind')='CLUSTERED','Clustered structure declaration retained');
 Check(Find('IX_Nonclustered','declared index').GetValue<string>('storage_kind')='NONCLUSTERED','Nonclustered structure declaration retained');
 Check(Find('IX_Method','declared index').GetValue<string>('method')='hash','Alternate explicit method retained');
 Check(Find('IX_NoUsage','declared index').GetValue<Integer>('usage_reference_count')=0,'Absent supported SQL references do not fabricate usage');
 Check(Find('IX_NoUsage','declared index').GetValue<string>('method')='not declared','Missing method is not assigned a guessed dialect default');
 Check(Find('IX_Missing','declared index').ToJSON.Contains('missing captured declaration'),'Missing target table explained');
 Check(Find('IX_Ambiguous','declared index').ToJSON.Contains('ambiguous captured declarations'),'Ambiguous target table not guessed');
 Check(Find('IX_MissingColumn','declared index').GetValue<string>('relationship_status')='relationship gaps','Missing indexed column explained');
 Check(Find('IX_IncludeMissing','declared index').GetValue<string>('relationship_status')='relationship gaps','Missing included column explained');
 Check(Find('IX_DuplicateColumn','declared index').ToJSON.Contains('ambiguous captured declarations'),'Duplicate captured column stays ambiguous');
 Check(Find('IX_Duplicate','declared index').GetValue<Integer>('definition_count')=2,'Duplicate index declarations counted');
 Check(Find('IX_Duplicate','declared index').GetValue<string>('conflict').Contains('unresolved'),'Duplicate index migration remains unresolved');
 Check(Find('"IX.quoted"','declared index').GetValue<string>('relationship_status')='captured links complete','Quoted dotted index and column names retained exactly');
 Check(Find('"Data"."IX.WithDot"','declared index').GetValue<string>('index_qualifier')='"Data"','Explicit index qualifier retained separately');
 Check(Find('IX_CaseMismatch','declared index').GetValue<string>('relationship_status')='relationship gaps','Index target case folding is not guessed');
 for ColumnCase in ['IX_Empty','IX_Trailing','IX_BadSort','IX_Collation','IX_BadInclude','IX_EmptyPredicate','IX_BadPredicate','IX_NoOn','IX_BadTail','IX_NoName','IX_EmptyExpression','IX_EmptyStorage','IX_ComplexPredicate','IX_NullOrder','IX_NoMethod','IX_MissingIncluded'] do begin
  Check(Find(ColumnCase,'declared index')=nil,'Unsupported/malformed index not promoted: '+ColumnCase);
  Check(Find('index '+ColumnCase,'unsupported')<>nil,'Unsupported/malformed index explained: '+ColumnCase);
 end;
 Check(Find('IX_Dot.','declared index')=nil,'Incomplete qualified index name not promoted');
 Other:=nil;for V in Report.GetValue<TJSONArray>('rows') do if (V.GetValue<string>('kind')='gap') and V.GetValue<string>('definition').Contains('IX_Dot') then Other:=V as TJSONObject;Check(Other<>nil,'Incomplete qualified index name retains a source gap');
 Check(Find('HiddenIndex','declared index')=nil,'Comment index is not promoted');
 Check(not Report.ToJSON.Contains('SECRET_INDEX_'),'Index literal canaries omitted');
 Check(Report.ToJSON.Contains('Index extraction gap'),'Unsupported index grammar explicitly reported');
 Other:=nil;

 Other:=nil;
 Row:=Find('Data.Save','declared stored object');Check(Row<>nil,'Multi-statement procedure captured as one definition');
 Check(Row.GetValue<string>('kind')='procedure','Procedure kind retained');
 Check(Row.GetValue<TJSONArray>('parameters').Count=3,'Ordered IN OUT and INOUT parameters captured');
 Check(Row.GetValue<TJSONArray>('parameters').Items[0].GetValue<string>('name')='item','First parameter name retained');
 Check(Row.GetValue<TJSONArray>('parameters').Items[1].GetValue<string>('declared_type')='NUMERIC ( 12 , 2 )','Parameter precision comma does not split parameter');
 Check(Row.GetValue<TJSONArray>('parameters').Items[1].GetValue<string>('mode')='OUT','Output parameter mode retained');
 Check(Row.GetValue<TJSONArray>('parameters').Items[2].GetValue<string>('mode')='INOUT','Inout parameter mode retained');
 Check(Row.GetValue<TJSONArray>('parameters').Items[2].GetValue<string>('default')='[literal omitted]','Parameter default literal omitted');
 Check(Row.GetValue<string>('body').Contains('BEGIN SELECT a FROM Page270 ; END'),'Nested block stays in stored body');
 Check(Row.GetValue<string>('body').Contains('CASE WHEN'),'CASE expression does not terminate routine');
 Check(Row.GetValue<TJSONArray>('dependencies').Count=5,'Body insert/update/call/nested/table references captured in order');
 Check(Row.GetValue<TJSONArray>('links').Items[0].GetValue<string>('target_id')=Find('Data.Target','declared header').GetValue<string>('id'),'Insert table dependency links exact declaration');
 Check(Row.GetValue<TJSONArray>('links').Items[2].GetValue<string>('target_id')=Find('Data.Log','declared stored object').GetValue<string>('id'),'Forward procedure call resolves after all source capture');
 Check(Row.GetValue<TJSONArray>('links').Items[3].GetValue<string>('target_id')=Find('Page270','declared header').GetValue<string>('id'),'Stored body dependency resolves target beyond first page');
 Check(Row.GetValue<string>('source_hash')=THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'stored.sql')),'Stored source hash retained');
 Check(Row.GetValue<Int64>('generation_id')=Generation,'Stored generation retained');
 Check(Row.GetValue<Integer>('range.line')=1,'Stored statement start line retained');
 Check(Row.GetValue<TJSONArray>('parameters').Items[0].GetValue<Integer>('line')=1,'Parameter source line retained');
 Check(Row.GetValue<string>('dependency_note').Contains('unverified'),'Incomplete dependency coverage explained');
 Check(TDPHDatabaseSchema.Describe(Row).Contains('Ordered parameters'),'Stored explanation leads with parameter facts');
 Check(TDPHDatabaseSchema.Describe(Row).Contains('not observed executions'),'Stored explanation teaches declaration/execution distinction');
 Row:=Find('Data.Total','declared stored object');Check(Row<>nil,'Tagged dollar SQL function captured');
 Check(Row.GetValue<string>('returns')='DECIMAL ( 12 , 2 )','Scalar return precision retained');
 Check(Row.GetValue<string>('language')='sql','Declared function language retained');
 Check(Row.GetValue<string>('header_operation')='CREATE OR REPLACE','Replace operation retained without migration winner');
 Check(Row.GetValue<TJSONArray>('parameters').Items[0].GetValue<string>('default')='1','Numeric parameter default retained');
 Check(Row.GetValue<TJSONArray>('dependencies').Count=1,'Dollar body table reference inspected without executing');
 Check(Row.GetValue<TJSONArray>('dependencies').Items[0].GetValue<Integer>('line')=8,'Dollar body reference keeps resource line');
 Check(Find('Data.Hook','declared stored object').GetValue<string>('language')='plpgsql','Post-body language declaration captured');
 Row:=Find('Data.Audit','declared stored object');Check(Row.GetValue<string>('kind')='trigger','Trigger kind retained');
 Check(Row.GetValue<string>('timing')='AFTER','Trigger timing retained');
 Check(Row.GetValue<string>('events')='INSERT OR UPDATE','Ordered trigger events retained');
 Check(Row.GetValue<string>('scope')='ROW','Trigger row scope retained');
 Check(Row.GetValue<string>('when').Contains('NEW'),'Trigger WHEN preserved unevaluated');
 Check(Row.GetValue<TJSONArray>('links').Count=2,'Trigger table and called function links present');
 Check(Row.GetValue<TJSONArray>('links').Items[1].GetValue<string>('target_id')=Find('Data.Hook','declared stored object').GetValue<string>('id'),'Trigger links exact captured function');
 Row:=Find('AuditInline','declared stored object');Check(Row.GetValue<string>('timing')='BEFORE','Inline trigger block captured');
 Check(Row.GetValue<TJSONArray>('dependencies').Count=2,'Inline trigger owns event table and body dependency');
 Row:=Find('Legacy.Save','declared stored object');Check(Row<>nil,'TSQL PROC and OR ALTER header captured');
 Check(Row.GetValue<TJSONArray>('parameters').Items[0].GetValue<string>('name')='@item','TSQL parameter marker retained');
 Check(Row.GetValue<TJSONArray>('parameters').Items[1].GetValue<string>('mode')='OUTPUT','TSQL output mode retained');
 Check(Row.GetValue<TJSONArray>('parameters').Items[1].GetValue<string>('default')='0','Output suffix separated from default');
 Check(Row.GetValue<TJSONArray>('links').Count=1,'Explicit EXEC procedure evidence captured');
 Check(Find('AfterBatch','declared stored object')<>nil,'Standalone client GO separator preserves following routine');
 Check(Find('SingleQuoted','declared stored object').GetValue<string>('body').Contains('[literal omitted]'),'Single-quoted body unescapes only for masked inspection');
 Check(Find('SingleQuoted','declared stored object').GetValue<TJSONArray>('links').Count=1,'Single-quoted SQL body dependency captured');
 Check(Find('MissingRef','declared stored object').ToJSON.Contains('missing captured declaration'),'Missing stored dependencies explained');
 Check(Find('AmbiguousRef','declared stored object').ToJSON.Contains('ambiguous captured declarations'),'Ambiguous table dependency has no winner');
 Check(not Find('AmbiguousRef','declared stored object').GetValue<TJSONArray>('links').Items[0].ToJSON.Contains('target_id'),'Ambiguous table dependency has no invented navigation');
 Check(Find('DynamicRef','declared stored object').ToJSON.Contains('dynamic SQL'),'Dynamic SQL is explicit unresolved execution');
 Check(not Find('DynamicRef','declared stored object').GetValue<TJSONArray>('links').ToJSON.Contains('target_id'),'Dynamic execution cannot invent targets');
 Check(Find('"Quoted.Procedure"','declared stored object').GetValue<TJSONArray>('parameters').Items[0].GetValue<string>('name')='"odd.parameter"','Quoted parameter spelling preserved');
 Check(Find('Overload','declared stored object').GetValue<Integer>('definition_count')=2,'Overloaded function definitions remain independent');
 Check(Find('AmbiguousHook','declared stored object').ToJSON.Contains('ambiguous captured declarations or overloads'),'Trigger overload target not guessed');
 Check(Find('AbsentTable','declared stored object').GetValue<string>('relationship_status')='relationship gaps','Absent trigger table reported');
 Check(Find('DDLInside','declared stored object')<>nil,'Inline body DDL retained within routine');
 Check(Find('InternalOnly','declared header')=nil,'Internal DDL not promoted to top-level schema');
 Check(Find('HiddenInsideBroken','declared header')=nil,'Unterminated block does not leak internal declarations');
 Check(Find('AfterStored','declared header')<>nil,'Top-level declaration after routine survives');
 for ColumnCase in ['TypeTail','EmptyDefault','DuplicateParam','TrailingParam','TypelessParam','NoReturns','BadLanguage','EmptyBody','BadEvent','BadCall','BadTail','Broken','BrokenDollar'] do begin
  Check(Find(ColumnCase,'declared stored object')=nil,'Unsupported stored object not promoted: '+ColumnCase);
 end;
 Check(Find('"Quoted.Procedure"','declared stored object').GetValue<string>('schema')='unknown','Dot inside quoted routine name is not a schema separator');
 Check(not Find('CTERef','declared stored object').GetValue<TJSONArray>('links').ToJSON.Contains('target_id'),'CTE scope prevents guessed table binding');
 Check(Find('LimitRefs','declared stored object').GetValue<TJSONArray>('dependencies').Count=1000,'Stored dependency extraction bounded to 1000 entries');
 Check(Find('LimitRefs','declared stored object').GetValue<string>('dependency_note').Contains('limited to 1000'),'Stored dependency limit explicitly explained');
 Check(Find('AS','declared stored object')=nil,'Missing stored-object name cannot consume AS keyword');
 Check(Find('HiddenStored','declared stored object')=nil,'Comment routine is not promoted');
 Check(not Report.ToJSON.Contains('SECRET_STORED_'),'Body defaults/comments/dynamic literals never leak');
 Check(Report.ToJSON.Contains('Stored-object extraction gap'),'Unsupported stored grammar explicitly explained');
 Check(Report.ToJSON.Contains('Unterminated dollar-quoted body'),'Malformed dollar resource has lexical gap');
 Other:=nil;
 Diagram:=TDPHDatabaseSchema.Diagram(Report,'ER_','',0,60,8);
 try
 Check(Diagram.GetValue<TJSONArray>('nodes').Count=4,'ER entities come from actual captured table declarations');
 Check(Diagram.GetValue<Integer>('total_tables')>270,'ER global count retains all captured tables');
 Check(Diagram.GetValue<Integer>('source_gaps')>0,'ER labels incomplete schemas with source gap count');
 Check(Diagram.GetValue<Integer>('unresolved_foreign_keys')>0,'ER counts unresolved foreign keys separately');
 Check(Diagram.GetValue<string>('qualification').Contains('PARTIAL CAPTURED SCHEMA'),'ER never claims a complete deployed schema');
 Check(Diagram.GetValue<string>('qualification').Contains('business cardinality'),'ER does not invent business cardinality');
 Check(Diagram.GetValue<Integer>('related_foreign_keys')=132,'ER counts all related keys before evidence cap');
 Check(Diagram.GetValue<TJSONArray>('edges').Count=120,'ER relation evidence bounded to 120 entries');
 Check(Diagram.GetValue<Integer>('omitted_foreign_keys')=12,'ER omitted relationships explicitly counted');
 ERNode:=Diagram.GetValue<TJSONArray>('nodes').Items[0] as TJSONObject;
 Check(ERNode.GetValue<string>('name')='ER_Customers','ER stable ordering follows captured declarations');
 Check(ERNode.GetValue<string>('source_hash')=THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'er.sql')),'ER node retains source hash');
 Check(ERNode.GetValue<Int64>('generation_id')=Generation,'ER node retains capture generation');
 Check(ERNode.GetValue<Integer>('range.line')=1,'ER node retains exact declaration start line');
 Check(ERNode.GetValue<TJSONArray>('columns').Items[0].GetValue<string>('badges').Contains('PK'),'ER column badges use captured primary-key membership');
 Check(ERNode.GetValue<TJSONArray>('columns').Items[0].GetValue<string>('id')=Find('ER_Customers.id','declared column').GetValue<string>('id'),'ER column evidence identity retained');
 Check(ERNode.GetValue<TJSONArray>('columns').Items[1].GetValue<string>('declared_type')='VARCHAR(80)','ER displays declared column type');
 EREdge:=Diagram.GetValue<TJSONArray>('edges').Items[0] as TJSONObject;
 Check(EREdge.GetValue<string>('key_id')=Find('ER_Orders | ER_OrderCustomer','declared key').GetValue<string>('id'),'ER edge retains exact key evidence identity');
 Check(EREdge.GetValue<string>('from')=Find('ER_Orders','declared header').GetValue<string>('id'),'ER FK starts from exact owning table declaration');
 Check(EREdge.GetValue<string>('to')=Find('ER_Customers','declared header').GetValue<string>('id'),'ER FK ends at exact resolved captured table');
 Check(EREdge.GetValue<Boolean>('resolved') and EREdge.GetValue<Boolean>('draw'),'ER draws structurally resolved visible foreign key');
 Check(EREdge.GetValue<TJSONArray>('members').ToJSON='["customer_id"]','ER local ordered membership retained');
 Check(EREdge.GetValue<TJSONArray>('reference_columns').ToJSON='["id"]','ER referenced ordered membership retained');
 Check(EREdge.GetValue<Integer>('range.line')=2,'ER edge retains source declaration line');
 Check(not Diagram.ToJSON.Contains('SECRET_'),'ER does not expose masked literal canaries');
 finally Diagram.Free;end;
 Diagram:=TDPHDatabaseSchema.Diagram(Report,'',Find('ER_Orders','declared header').GetValue<string>('id'),0,30,8);
 try Check(Diagram.GetValue<TJSONArray>('nodes').Count=3,'ER focus includes selected table and one-hop incoming/outgoing neighbors');
 Check(Diagram.GetValue<TJSONArray>('edges').Count=2,'ER focused evidence excludes unrelated foreign-key sources');
 finally Diagram.Free;end;
 Diagram:=TDPHDatabaseSchema.Diagram(Report,'ER_Orders','',0,30,8);
 try Check(Diagram.GetValue<TJSONArray>('nodes').Count=1,'ER text filter bounds visible entity scope');
 Check(not Diagram.GetValue<TJSONArray>('edges').Items[0].GetValue<Boolean>('draw'),'Off-page/filter endpoint is not drawn as a fabricated table');
 Check(Diagram.GetValue<TJSONArray>('edges').Items[0].GetValue<string>('state').Contains('outside'),'Off-page/filter relationship remains explicitly selectable evidence');
 Check(Diagram.GetValue<TJSONArray>('nodes').Items[0].GetValue<TJSONArray>('columns').Items[1].GetValue<string>('badges').Contains('FK'),'ER foreign column badge retained');
 finally Diagram.Free;end;
 Diagram:=TDPHDatabaseSchema.Diagram(Report,'ER_','',1,1,1);
 try Check(Diagram.GetValue<Integer>('matching_tables')=4,'ER pagination preserves total matching count');
 Check(Diagram.GetValue<TJSONArray>('nodes').Items[0].GetValue<string>('name')='ER_Orders','ER offset selects exact later table');
 Check(Diagram.GetValue<Boolean>('has_next'),'ER next page indicated');
 Check(Diagram.GetValue<TJSONArray>('nodes').Items[0].GetValue<Integer>('column_count')=3,'ER full column count survives truncation');
 Check(Diagram.GetValue<TJSONArray>('nodes').Items[0].GetValue<Integer>('shown_columns')=1,'ER column summaries respect display bound');
 Check(Diagram.GetValue<TJSONArray>('nodes').Items[0].GetValue<Boolean>('partial'),'ER truncated table marked incomplete');
 finally Diagram.Free;end;
 Diagram:=TDPHDatabaseSchema.Diagram(Report,'SelfRef','',0,30,8);
 try Check(Diagram.GetValue<TJSONArray>('edges').Items[0].GetValue<string>('from')=Diagram.GetValue<TJSONArray>('edges').Items[0].GetValue<string>('to'),'ER self-reference retained without inventing another entity');finally Diagram.Free;end;
 Diagram:=TDPHDatabaseSchema.Diagram(Report,'Absent','',0,30,8);
 try Check(not Diagram.GetValue<TJSONArray>('edges').Items[0].GetValue<Boolean>('resolved'),'ER absent target is unresolved');
 Check(Diagram.GetValue<TJSONArray>('edges').Items[0].GetValue<string>('to')='','ER absent target has no invented ID');
 Check(Diagram.GetValue<TJSONArray>('nodes').Items[0].GetValue<Boolean>('partial'),'ER unresolved owning table marked orange');finally Diagram.Free;end;
 Diagram:=TDPHDatabaseSchema.Diagram(Report,'Sales.Customers','',0,30,8);
 try Check(Diagram.GetValue<TJSONArray>('nodes').Count=2,'ER duplicate table declarations remain independent');
 Check(Diagram.GetValue<TJSONArray>('nodes').Items[0].GetValue<Boolean>('partial'),'ER duplicate-name table marked incomplete');
 Check(Diagram.GetValue<TJSONArray>('nodes').Items[0].GetValue<string>('id')<>Diagram.GetValue<TJSONArray>('nodes').Items[1].GetValue<string>('id'),'ER duplicate declaration identities do not merge');finally Diagram.Free;end;
 Diagram:=TDPHDatabaseSchema.Diagram(Report,'UnverifiedObject','',0,30,8);
 try Check(Diagram.GetValue<Integer>('shown_tables')=0,'Inferred SQL references do not invent ER entities');finally Diagram.Free;end;
 Diagram:=TDPHDatabaseSchema.Diagram(Report,'','missing-id',0,30,8);
 try Check(Diagram.GetValue<Integer>('shown_tables')=0,'ER missing focused identity cannot select an unrelated table');finally Diagram.Free;end;
 Diagram:=TDPHDatabaseSchema.Diagram(nil,'','',0,30,8);
 try Check(Diagram.GetValue<Integer>('total_tables')=0,'ER empty capture handled');finally Diagram.Free;end;
 Rejected:=False;try Diagram:=TDPHDatabaseSchema.Diagram(Report,'','',0,61,8);Diagram.Free;except on E:EArgumentOutOfRangeException do Rejected:=True;end;Check(Rejected,'ER page bounds enforced');
 Rejected:=False;try Diagram:=TDPHDatabaseSchema.Diagram(Report,'','',-1,30,8);Diagram.Free;except on E:EArgumentOutOfRangeException do Rejected:=True;end;Check(Rejected,'ER negative offset refused');
 Rejected:=False;try Diagram:=TDPHDatabaseSchema.Diagram(Report,'','',0,30,33);Diagram.Free;except on E:EArgumentOutOfRangeException do Rejected:=True;end;Check(Rejected,'ER column bounds enforced');
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
 StressDocument:=View.Document.Clone as TJSONObject;StressSymbol:=nil;
 for V in StressDocument.GetValue<TJSONArray>('semantics.symbols') do if (V.GetValue<string>('kind')='sql_table') and (V.GetValue<string>('range.source')='index-use.sql') then begin StressSymbol:=V.Clone as TJSONObject;Break;end;
 Check(StressSymbol<>nil,'Controlled reference-bound test starts from actual captured SQL evidence');
 StressRelation:=nil;for V in StressDocument.GetValue<TJSONArray>('semantics.relationships') do if (V.GetValue<string>('rule')='single_table_sql_text_schema_unverified') and (V.GetValue<string>('to')=StressSymbol.GetValue<string>('key')) then begin StressRelation:=V.Clone as TJSONObject;Break;end;
 Check(StressRelation<>nil,'Controlled bound case preserves the captured relation contract');
 try for I:=1 to 260 do begin Other:=StressSymbol.Clone as TJSONObject;Other.RemovePair('key').Free;Other.AddPair('key','controlled-stress-'+IntToStr(I));StressDocument.GetValue<TJSONArray>('semantics.symbols').AddElement(Other);Other:=StressRelation.Clone as TJSONObject;Other.RemovePair('to').Free;Other.AddPair('to','controlled-stress-'+IntToStr(I));StressDocument.GetValue<TJSONArray>('semantics.relationships').AddElement(Other);end;finally StressRelation.Free;StressSymbol.Free;end;
 Stress:=TDPHWorkspaceView.Create(StressDocument);
 try StressReport:=TDPHDatabaseSchema.Inspect(Stress);
 try
  Other:=nil;for V in StressReport.GetValue<TJSONArray>('rows') do if (V.GetValue<string>('kind')='index') and (V.GetValue<string>('name')='IX_Composite') then Other:=V as TJSONObject;
  Check(Other.GetValue<Integer>('usage_reference_count')=261,'Total reference count retained beyond navigation bound');
  Check(Other.GetValue<Integer>('usage_shown_count')=250,'SQL reference navigation bounded to 250 per index');
  Check(Other.GetValue<TJSONArray>('links').Count=254,'Structural links preserved alongside capped usage links');
 finally StressReport.Free;end;finally Stress.Free;end;
 Other:=nil;
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

 Form.DatabaseSchemaKind.ItemIndex:=8;Form.DatabaseSchemaState.ItemIndex:=8;Form.DatabaseSchemaFilter.Text:='IX_Composite';Form.DatabaseSchemaFilterChange(nil);
 Check(Form.DatabaseSchemaList.Count=1,'Native index kind/state/name filters combine');
 Check(Form.DatabaseSchemaMemo.Text.Contains('Ordered index members'),'Native index details teach declared structure');
 Check(Form.DatabaseSchemaLinks.Items.Count=5,'Native index relationship selector includes SQL evidence');
 Form.DatabaseSchemaLinks.ItemIndex:=4;Form.DatabaseSchemaFollowClick(nil);
 Check(Form.DatabaseSchemaMemo.Text.Contains('index-use.sql'),'Follow opens exact captured SQL table-reference evidence');
 Form.DatabaseSchemaKind.ItemIndex:=8;Form.DatabaseSchemaState.ItemIndex:=8;Form.DatabaseSchemaFilter.Text:='IX_Late';Form.DatabaseSchemaFilterChange(nil);
 Form.DatabaseSchemaLinks.ItemIndex:=1;Form.DatabaseSchemaFollowClick(nil);
 Check(Form.DatabaseSchemaMemo.Text.Contains('COLUMN Page270.id'),'Index column beyond first page opens by exact identity');
 Form.DatabaseSchemaKind.ItemIndex:=8;Form.DatabaseSchemaState.ItemIndex:=8;Form.DatabaseSchemaFilter.Text:='fillfactor';Form.DatabaseSchemaFilterChange(nil);
 Check(Form.DatabaseSchemaList.Count=1,'Storage option text filter searches captured index');
 Form.DatabaseSchemaFilter.Text:='hash';Form.DatabaseSchemaFilterChange(nil);Check(Form.DatabaseSchemaList.Count=1,'Method filter searches index declarations');
 Form.DatabaseSchemaFilter.Text:='IX_Composite';Form.DatabaseSchemaFilterChange(nil);
 Form.DatabaseSchemaKind.ItemIndex:=9;Form.DatabaseSchemaState.ItemIndex:=9;Form.DatabaseSchemaFilter.Text:='Data.Save';Form.DatabaseSchemaFilterChange(nil);
 Check(Form.DatabaseSchemaList.Count=1,'Native procedure kind/state/name filters combine');
 Check(Form.DatabaseSchemaMemo.Text.Contains('Ordered parameters'),'Native stored-object details expose ordered parameters');
 Check(Form.DatabaseSchemaLinks.Items.Count=5,'Native stored dependency selector contains exact evidence targets');
 Form.DatabaseSchemaLinks.ItemIndex:=3;Form.DatabaseSchemaFollowClick(nil);
 Check(Form.DatabaseSchemaMemo.Text.Contains('TABLE Page270'),'Stored dependency target beyond first page opens exactly');
 Form.DatabaseSchemaKind.ItemIndex:=10;Form.DatabaseSchemaState.ItemIndex:=9;Form.DatabaseSchemaFilter.Text:='DECIMAL';Form.DatabaseSchemaFilterChange(nil);
 Check(Form.DatabaseSchemaList.Count=1,'Native return-type search finds function');
 Form.DatabaseSchemaKind.ItemIndex:=11;Form.DatabaseSchemaFilter.Text:='Data.Audit';Form.DatabaseSchemaFilterChange(nil);
 Check(Form.DatabaseSchemaList.Count=1,'Native trigger kind/state filters combine');
 Check(Form.DatabaseSchemaMemo.Text.Contains('Timing: AFTER'),'Native trigger facts displayed before body');
 Form.DatabaseSchemaLinks.ItemIndex:=1;Form.DatabaseSchemaFollowClick(nil);
 Check(Form.DatabaseSchemaMemo.Text.Contains('FUNCTION Data.Hook'),'Native trigger function navigation opens exact definition');
 Form.DatabaseSchemaKind.ItemIndex:=9;Form.DatabaseSchemaState.ItemIndex:=9;Form.DatabaseSchemaFilter.Text:='Data.Save';Form.DatabaseSchemaFilterChange(nil);
 Form.DatabaseSchemaFilter.Text:='@result';Form.DatabaseSchemaFilterChange(nil);Check(Form.DatabaseSchemaList.Count=1,'Native parameter-name search finds procedure header');
 Form.DatabaseSchemaFilter.Text:='Data.Save';Form.DatabaseSchemaFilterChange(nil);
 Form.DatabaseERFilter.Text:='ER_Orders';Form.DatabaseERFilterChange(nil);Form.WorkspaceTabs.ActiveTab:=Form.DatabaseERTab;
 Check(Form.DatabaseERStatus.Text.Contains('1 of 1 matching'),'Native ER filter shows captured table scope');
 Check(Form.DatabaseERRelations.Items.Count=2,'Native ER selector retains off-page FK evidence');
 Form.DatabaseERRelations.ItemIndex:=0;Form.DatabaseERSelectionChange(nil);
 Check(Form.DatabaseERMemo.Text.Contains('Ordered local columns'),'Native ER relationship selection explains full ordered key metadata');
 Form.DatabaseEROpenClick(nil);
 Check(Form.WorkspaceTabs.ActiveTab=Form.DatabaseSchemaTab,'ER Open evidence selects schema page');
 Check(Form.DatabaseSchemaMemo.Text.Contains('ER_OrderCustomer'),'ER Open evidence selects exact foreign key');
 Form.DatabaseERFocusClick(nil);
 Check(Form.DatabaseERStatus.Text.Contains('3 of 3 matching'),'Native focus includes incoming and outgoing neighbors');
 Check(Form.DatabaseERRelations.Items.Count=2,'Native focus removes unrelated FKs');
 Form.DatabaseERMouseDown(nil,TMouseButton.mbLeft,[],Form.DatabaseERTableStyle.Margins.Left+20,Form.DatabaseERTableStyle.Margins.Top+60);
 Check(Form.DatabaseERMemo.Text.Contains('TABLE ER_Customers'),'Native table hit selects exact captured table evidence');
 Check(Form.DatabaseERMemo.Text.Contains('CAPTURED COLUMNS AND KEYS'),'Native table evidence includes full inventory beyond card summary');
 Form.DatabaseEROpenClick(nil);Check(Form.DatabaseSchemaMemo.Text.Contains('TABLE ER_Customers'),'Native table evidence opens exact schema target');
 Form.DatabaseERFilterChange(Form.DatabaseERAll);Form.DatabaseERPageSize.ItemIndex:=0;Form.DatabaseERFilterChange(nil);
 Check(Form.DatabaseERStatus.Text.Contains('15 of'),'Native ER page size bounds diagrams');
 Check(Form.DatabaseERNext.Enabled,'Native ER next page enabled');
 Form.DatabaseERFilterChange(Form.DatabaseERNext);Check(Form.DatabaseERStatus.Text.Contains('from 15'),'Native ER next page advances exact offset');
 Form.DatabaseERFilter.Text:='missing-er-table';Form.DatabaseERFilterChange(nil);Check(Form.DatabaseERMemo.Text.Contains('No matching captured tables'),'Native ER empty results explain recovery');
 Form.DatabaseERFilter.Text:='Page270';Form.DatabaseERFilterChange(nil);Form.DatabaseERMouseDown(nil,TMouseButton.mbLeft,[],Form.DatabaseERTableStyle.Margins.Left+20,Form.DatabaseERTableStyle.Margins.Top+60);Form.DatabaseEROpenClick(nil);
 Check(Form.DatabaseSchemaMemo.Text.Contains('TABLE Page270'),'ER evidence navigation reaches later schema inventory page');
 Form.DatabaseERFilter.Text:='ER_';Form.DatabaseERFilterChange(nil);Form.WorkspaceTabs.ActiveTab:=Form.DatabaseERTab;Form.Show;
 Check(Form.WorkspacePageCombo.Items.IndexOf('Database ER diagram')>=0,'ER page available through serialized upper-right selector');
 Form.WorkspacePageCombo.ItemIndex:=Form.WorkspacePageCombo.Items.IndexOf('Database ER diagram');Form.WorkspacePageChange(Form.WorkspacePageCombo);
 Check(Form.WorkspaceTabs.ActiveTab=Form.DatabaseERTab,'Upper-right selector opens ER page');
 Bitmap:=Form.DatabaseERPaint.MakeScreenshot;try Bitmap.SaveToFile(TPath.Combine(Root,'docs\validation\images\phase1-database-er-diagram.png'));finally Bitmap.Free;end;
 Render('phase1-database-er-workspace.png');
 Form.WindowState:=TWindowState.wsNormal;Form.Width:=960;Form.Height:=600;Application.ProcessMessages;
 Form.DatabaseERZoom.ItemIndex:=4;Form.DatabaseERFilterChange(nil);Check(Form.DatabaseERPaint.Width>Form.DatabaseERScroll.Width,'ER zoom enables horizontal scrolling');
 Form.DatabaseERZoom.ItemIndex:=1;Form.DatabaseERFilterChange(nil);
 Form.WindowState:=TWindowState.wsNormal;Form.Width:=960;Form.Height:=600;Application.ProcessMessages;Form.DatabaseERResize(nil);Render('phase1-database-er-compact.png');
 Check(Form.DatabaseERScroll.Height>=30,'Compact ER canvas retains reachable scroll area');
 Check(Form.DatabaseERMemo.ShowScrollBars,'ER evidence memo scrolls');
 Check(Form.DatabaseERScroll.ShowScrollBars,'ER diagram scrolls independently');
 Check(Form.DatabaseERPaint.Height>Form.DatabaseERScroll.Height,'ER canvas retains lower table rows outside viewport');
 Form.DatabaseERToolbar.ViewportPosition:=PointF(10000,0);Application.ProcessMessages;
 Check(Form.DatabaseEROpen.AbsoluteRect.Right<=Form.DatabaseERToolbar.AbsoluteRect.Right+2,'ER evidence command reachable at compact width');
 Render('phase1-database-er-commands.png');
 Form.LoadView(Reopened.Document.Clone as TJSONObject);Check(Form.DatabaseERStatus.Text.Contains('4 of 4 matching'),'Capture replacement rebuilds ER projection under current filter');
 Form.DatabaseSchemaKind.ItemIndex:=9;Form.DatabaseSchemaState.ItemIndex:=9;Form.DatabaseSchemaFilter.Text:='Data.Save';Form.DatabaseSchemaFilterChange(nil);
 Form.WorkspaceTabs.ActiveTab:=Form.DatabaseSchemaTab;Form.Show;Render('phase1-database-er-schema-workspace.png');
 Form.WindowState:=TWindowState.wsNormal;Form.Width:=960;Form.Height:=600;Render('phase1-database-er-schema-compact.png');
 Form.DatabaseSchemaToolbar.ViewportPosition:=PointF(10000,0);Application.ProcessMessages;
 Check(Form.DatabaseSchemaFollow.AbsoluteRect.Right<=Form.DatabaseSchemaToolbar.AbsoluteRect.Right+2,'Relationship command reachable at minimum width');
 Render('phase1-database-er-relationships.png');
 Check(Form.DatabaseSchemaMemo.Height>=50,'Compact memo has readable area');
 Check(Form.DatabaseSchemaMemo.ShowScrollBars,'Long schema details scroll');
 Check(Form.DatabaseSchemaToolbar.ShowScrollBars,'Compact commands can scroll horizontally');
 Form.LoadView(Reopened.Document.Clone as TJSONObject);Check(Form.DatabaseSchemaList.Count=1,'Capture replacement rebuilds projection under current filters');Form.Hide;
 finally Form.Free;end;
 Check((not TFile.Exists(Catalog) and (CatalogHash='')) or (TFile.Exists(Catalog) and (THashSHA2.GetHashStringFromFile(Catalog)=CatalogHash)),'Owner catalog unchanged');
 Check(THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'schema.sql'))=SourceHash,'Target source restored unchanged after navigation refusal test');
 Log:=TJSONObject.Create.AddPair('result','PASS').AddPair('checks',TJSONNumber.Create(Checks)).AddPair('qualification','ER diagrams from captured declarations and exact key links, qualified gaps, bounded table/column/relationship projections, focus/filter/paging/zoom and native evidence navigation. Cardinality, semantic validity and deployed schema unverified; no SQL executed.');
 try TFile.WriteAllText(TPath.Combine(Root,'docs\validation\reports\phase1-database-er-validation.json'),Log.Format,TEncoding.UTF8);finally Log.Free;end;
 finally Report.Free;end;finally Reopened.Free;View.Free;end;
 Writeln('Database ER validation passed: ',Checks,' checks.');
 except on E:Exception do begin Writeln(E.ClassName,': ',E.Message);ExitCode:=1;end;end;
end.
