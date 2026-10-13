from pathlib import Path
r=Path.cwd();s=(r/'tests/DPH.Tests.DatabaseIndexes.dpr').read_text()
s=s.replace('DatabaseIndexes','DatabaseStoredObjects').replace('database-indexes','database-stored-objects')
s=s.replace("'end; end.']),TEncoding.UTF8);", "'TFile.ReadAllText(''stored.sql''); TFile.ReadAllText(''stored-broken.sql''); TFile.ReadAllText(''stored-dollar.sql'');',\n 'end; end.']),TEncoding.UTF8);",1)
fixture=r''' TFile.WriteAllText(TPath.Combine(Fixture,'stored.sql'),String.Join(sLineBreak,[
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
'''
s=s.replace(' SourceHash:=THashSHA2',fixture+' SourceHash:=THashSHA2',1)
checks=r''' Row:=Find('Data.Save','declared stored object');Check(Row<>nil,'Multi-statement procedure captured as one definition');
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
 for ColumnCase in ['EmptyDefault','DuplicateParam','TrailingParam','TypelessParam','NoReturns','BadLanguage','EmptyBody','BadEvent','BadCall','BadTail','Broken','BrokenDollar'] do begin
  Check(Find(ColumnCase,'declared stored object')=nil,'Unsupported stored object not promoted: '+ColumnCase);
 end;
 Check(Find('HiddenStored','declared stored object')=nil,'Comment routine is not promoted');
 Check(not Report.ToJSON.Contains('SECRET_STORED_'),'Body defaults/comments/dynamic literals never leak');
 Check(Report.ToJSON.Contains('Stored-object extraction gap'),'Unsupported stored grammar explicitly explained');
 Check(Report.ToJSON.Contains('Unterminated dollar-quoted body'),'Malformed dollar resource has lexical gap');
 Other:=nil;
'''
s=s.replace(" Check(not Report.ToJSON.Contains('SECRET_SQL_CANARY')",checks+" Check(not Report.ToJSON.Contains('SECRET_SQL_CANARY')",1)
ui=r''' Form.DatabaseSchemaKind.ItemIndex:=9;Form.DatabaseSchemaState.ItemIndex:=9;Form.DatabaseSchemaFilter.Text:='Data.Save';Form.DatabaseSchemaFilterChange(nil);
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
'''
s=s.replace(' Form.WorkspaceTabs.ActiveTab:=Form.DatabaseSchemaTab;',ui+' Form.WorkspaceTabs.ActiveTab:=Form.DatabaseSchemaTab;',1)
s=s.replace('Controlled captured index structures, ordered membership, includes, predicates/options, exact evidence relationships, explicit gaps, persistence and native FMX navigation; SQL references do not prove actual index use. Expressions and deployed enforcement unverified; no SQL executed.','Captured procedures/functions/triggers, ordered parameters/defaults/returns, sanitized bodies, supported table and explicit call evidence, ambiguity/gaps, persistence and native navigation. Body grammar and runtime binding unverified; no SQL executed.')
(r/'tests/DPH.Tests.DatabaseStoredObjects.dpr').write_bytes(s.replace('\n','\r\n').encode())
s=(r/'tools/build-database-indexes.cmd').read_text().replace('DatabaseIndexes','DatabaseStoredObjects')
(r/'tools/build-database-stored-objects.cmd').write_bytes(s.replace('\n','\r\n').encode())
print('Stored object integration suite created')
