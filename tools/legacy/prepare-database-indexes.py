from pathlib import Path
r=Path.cwd();s=(r/'tests/DPH.Tests.DatabaseKeys.dpr').read_text(encoding='utf-8-sig').replace('DatabaseKeys','DatabaseIndexes').replace('database-keys','database-indexes').replace('Database keys validation passed:','Database indexes validation passed:')
s=s.replace("TFile.ReadAllText(''keys.sql'');',", "TFile.ReadAllText(''keys.sql''); TFile.ReadAllText(''indexes.sql''); TFile.ReadAllText(''index-use.sql'');',")
fixture=""" TFile.WriteAllText(TPath.Combine(Fixture,'indexes.sql'),String.Join(sLineBreak,[
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
"""
s=s.replace(' SourceHash:=THashSHA2',fixture+' SourceHash:=THashSHA2',1)
checks="""
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
 for ColumnCase in ['IX_Empty','IX_Trailing','IX_BadSort','IX_Collation','IX_BadInclude','IX_EmptyPredicate','IX_BadPredicate','IX_NoOn','IX_BadTail','IX_NoName','IX_Dot.','IX_EmptyExpression','IX_EmptyStorage','IX_ComplexPredicate','IX_NullOrder','IX_NoMethod','IX_MissingIncluded'] do begin
  Check(Find(ColumnCase,'declared index')=nil,'Unsupported/malformed index not promoted: '+ColumnCase);
  Check(Find('index '+ColumnCase,'unsupported')<>nil,'Unsupported/malformed index explained: '+ColumnCase);
 end;
 Check(Find('HiddenIndex','declared index')=nil,'Comment index is not promoted');
 Check(not Report.ToJSON.Contains('SECRET_INDEX_'),'Index literal canaries omitted');
 Check(Report.ToJSON.Contains('Index extraction gap'),'Unsupported index grammar explicitly reported');
 Other:=nil;
"""
s=s.replace(" Other:=nil;\n Check(not Report.ToJSON.Contains('SECRET_SQL_CANARY')",checks+"\n Other:=nil;\n Check(not Report.ToJSON.Contains('SECRET_SQL_CANARY')",1)
ui="""
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
"""
s=s.replace(' Form.WorkspaceTabs.ActiveTab:=Form.DatabaseSchemaTab;',ui+' Form.WorkspaceTabs.ActiveTab:=Form.DatabaseSchemaTab;',1)
s=s.replace('Controlled captured primary/foreign/unique keys, ordered relationships, unresolved evidence, grammar gaps, persistence and native FMX navigation.', 'Controlled captured index structures, ordered membership, includes, predicates/options, exact evidence relationships, explicit gaps, persistence and native FMX navigation; SQL references do not prove actual index use.')
(r/'tests/DPH.Tests.DatabaseIndexes.dpr').write_text(s,encoding='utf-8')
(r/'tools/build-database-indexes.cmd').write_text((r/'tools/build-database-keys.cmd').read_text().replace('DatabaseKeys','DatabaseIndexes'))
