from pathlib import Path
r=Path.cwd();s=(r/'tests/DPH.Tests.DatabaseSchema.dpr').read_text(encoding='utf-8-sig')
s=s.replace('DPH.Tests.DatabaseSchema','DPH.Tests.DatabaseColumns').replace('database-schema-validation','database-columns-validation').replace('phase1-database-schema','phase1-database-columns').replace('Database schema validation passed','Database columns validation passed')
s=s.replace("'end; end.']),TEncoding.UTF8);", "'TFile.ReadAllText(''columns.sql''); TFile.ReadAllText(''columns-duplicate.sql'');',\n 'end; end.']),TEncoding.UTF8);",1)
fixture=''' TFile.WriteAllText(TPath.Combine(Fixture,'columns.sql'),String.Join(sLineBreak,[
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
 ' afterbad INTEGER NOT NULL',
 ');']),TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(Fixture,'columns-duplicate.sql'),'CREATE TABLE Sales.Details (id VARCHAR(10));',TEncoding.UTF8);
'''
s=s.replace(" SourceHash:=THashSHA2.GetHashStringFromFile",fixture+" SourceHash:=THashSHA2.GetHashStringFromFile",1)
checks=''' Check(Find('Sales.Details.id','declared column')<>nil,'Actual CREATE column declaration captured');
 Check(Find('Sales.Details.id','declared column').GetValue<string>('declared_type')='VARCHAR ( 10 )','First duplicate retains its own declared type');
 Row:=Find('Sales.Details.amount','declared column');
 Check(Row.GetValue<string>('declared_type')='DECIMAL ( 12 , 2 )','Type precision and comma retained without splitting a column');
 Check(Row.GetValue<string>('default')='- 42 . 5','Signed numeric default retained');
 Check(Row.GetValue<string>('nullability')='explicit NOT NULL','Nullability after DEFAULT parsed separately');
 Check(Row.GetValue<string>('table')='Sales.Details','Column retains qualified table');
 Check(Row.GetValue<string>('source')='columns.sql','Column retains original source file');
 Check(Row.GetValue<Integer>('range.line')=3,'Column declaration start line retained');
 Check(Row.GetValue<string>('source_hash')=THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'columns.sql')),'Column retains actual source hash');
 Check(Row.GetValue<Int64>('generation_id')=Generation,'Column retains captured generation');
 Check(Row.GetValue<string>('declaration_id')<>'','Column retains unique parent declaration identity');
 Check(Find('Sales.Details.title','declared column').GetValue<string>('declared_type')='CHARACTER VARYING ( 80 )','Multiword type retained');
 Check(Find('Sales.Details.title','declared column').GetValue<string>('nullability')='explicit NULL','Explicit NULL distinguished from unspecified');
 Check(Find('Sales.Details.title','declared column').GetValue<string>('default')='[literal omitted]','Literal default masked with explicit marker');
 Check(Find('Sales.Details.due','declared column').GetValue<string>('declared_type')='TIMESTAMP WITHOUT TIME ZONE','Timestamp qualifier retained');
 Check(Find('Sales.Details.due','declared column').GetValue<string>('default')='CURRENT_TIMESTAMP','Symbolic default retained without evaluating');
 Check(Find('Sales.Details.maybe','declared column').GetValue<string>('nullability')='not declared','Absent nullability not invented');
 Check(Find('Sales.Details.maybe','declared column').GetValue<string>('default')='not declared','Absent default not invented');
 Check(Find('Sales.Details.flag','declared column').GetValue<string>('default')='NULL','DEFAULT NULL remains a default expression');
 Check(Find('Sales.Details.flag','declared column').GetValue<string>('nullability')='not declared','DEFAULT NULL does not become an explicit nullability clause');
 Check(Find('Sales.Details.constrained','declared column').GetValue<string>('constraints').Contains('CONSTRAINT Positive CHECK'),'Named CHECK text retained');
 Check(Find('Sales.Details.ref','declared column').GetValue<string>('constraints').Contains('REFERENCES Sales . Customers'),'Inline reference clause retained as text only');
 Check(Find('Sales.Details.named','declared column').GetValue<string>('nullability')='explicit NOT NULL','Named NOT NULL clause captured');
 Check(Find('Sales.Details.fn','declared column').GetValue<string>('default').Contains('coalesce ( [literal omitted] , [literal omitted] )'),'Function default commas and literals handled');
 Check(Find('Sales.Details.calc','declared column').GetValue<string>('default')='( 1 + 2 )','Parenthesized default expression retained');
 Check(Find('Sales.Details.calc','declared column').GetValue<string>('constraints').Contains('CHECK'),'Default and CHECK stay separate');
 Check(Find('Sales.Details.noInfer','declared column').GetValue<string>('nullability')='not declared','Primary key does not invent explicit NOT NULL declaration');
 Check(Find('Sales.Details."quoted.column"','declared column').GetValue<string>('declared_type')='custom . "Money"','Quoted name and qualified custom type preserved');
 Check(Find('Sales.Details.arraycol','declared column').GetValue<string>('declared_type')='INTEGER []','Array type suffix retained');
 Check(Find('Sales.Details | CONSTRAINT','captured constraint').GetValue<string>('scope')='table','Table constraint not misclassified as column');
 Check(Find('Sales.Details | CHECK','captured constraint').GetValue<string>('definition').Contains('1 , 2'),'Table CHECK commas remain in one entry');
 for SQL in ['bad','conflict','missing','repeated','expression','absenttype','badname','namedbad','malformeddefault'] do begin
  Check(Find('Sales.Details.'+SQL,'declared column')=nil,'Unsupported column not promoted: '+SQL);
  Check(Find('Sales.Details.'+SQL,'unsupported')<>nil,'Unsupported column entry explained: '+SQL);
 end;
 Check(Find('Sales.Details.afterbad','declared column')<>nil,'Supported following column survives earlier entry gaps');
 Check(not Report.ToJSON.Contains('SECRET_'),'All column literal canaries absent from projection');
 Check(TDPHDatabaseSchema.Describe(Row).Contains('Declared type: DECIMAL'),'Column explanation displays type before long qualifications');
 Check(TDPHDatabaseSchema.Describe(Row).Contains('not an effective database default'),'Column explanation teaches absent-declaration meaning');
 Other:=nil;for V in Report.GetValue<TJSONArray>('rows') do if (V.GetValue<string>('name')='Sales.Details.id') and (V.GetValue<string>('source')='columns.sql') then Other:=V as TJSONObject;
 Check((Other<>nil) and (Other.GetValue<string>('declared_type')='BIGINT'),'Other duplicate column retains distinct type');
 Check(Other.GetValue<string>('declaration_id')<>Find('Sales.Details.id','declared column').GetValue<string>('declaration_id'),'Duplicate table declarations never merge column ownership');
 Other:=nil;
'''
s=s.replace(" Check(not Report.ToJSON.Contains('SECRET_SQL_CANARY')",checks+" Check(not Report.ToJSON.Contains('SECRET_SQL_CANARY')",1)
ui=''' Form.DatabaseSchemaKind.ItemIndex:=5;Form.DatabaseSchemaState.ItemIndex:=5;Form.DatabaseSchemaFilter.Text:='DECIMAL';Form.DatabaseSchemaFilterChange(nil);
 Check(Form.DatabaseSchemaList.Count=1,'Native declared-type filter finds captured column');
 Check(Form.DatabaseSchemaMemo.Text.Contains('Nullability declaration: explicit NOT NULL'),'Native column nullability explained');
 Check(Form.DatabaseSchemaMemo.Text.Contains('Default declaration: - 42 . 5'),'Native default evidence displayed');
 Form.DatabaseSchemaFilter.Text:='missing-column';Form.DatabaseSchemaFilterChange(nil);Check(Form.DatabaseSchemaList.Count=0,'Native column empty filter handled');
 Form.DatabaseSchemaFilter.Text:='DECIMAL';Form.DatabaseSchemaFilterChange(nil);
'''
s=s.replace(" Form.WorkspaceTabs.ActiveTab:=Form.DatabaseSchemaTab;Form.Show;",ui+" Form.WorkspaceTabs.ActiveTab:=Form.DatabaseSchemaTab;Form.Show;",1)
s=s.replace("'Controlled source SQL capture, supported declaration headers, explicit gaps, SQLite persistence and actual native FMX controls. Body grammar and deployed object existence unverified; no SQL executed.'","'Controlled SQL column/type/nullability/default/constraint capture, unsupported-entry gaps, duplicate ownership, literal omission, persistence and native FMX controls. Expressions and deployed enforcement unverified; no SQL executed.'")
(r/'tests/DPH.Tests.DatabaseColumns.dpr').write_text(s,encoding='utf-8')
s=(r/'tools/build-database-schema.cmd').read_text().replace('DPH.Tests.DatabaseSchema','DPH.Tests.DatabaseColumns');(r/'tools/build-database-columns.cmd').write_text(s,encoding='utf-8')
