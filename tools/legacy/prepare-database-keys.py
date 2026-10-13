from pathlib import Path
r=Path.cwd()
p=r/'tests/DPH.Tests.DatabaseColumns.dpr'
s=p.read_text(encoding='utf-8-sig').replace('DatabaseColumns','DatabaseKeys').replace('database-columns','database-keys')
s=s.replace("'TFile.ReadAllText(''columns.sql''); TFile.ReadAllText(''columns-duplicate.sql'');',", "'TFile.ReadAllText(''columns.sql''); TFile.ReadAllText(''columns-duplicate.sql''); TFile.ReadAllText(''keys.sql'');',")
fixture=""" TFile.WriteAllText(TPath.Combine(Fixture,'keys.sql'),String.Join(sLineBreak,[
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
 'CREATE TABLE LiteralSafety (id INTEGER DEFAULT ''PRIMARY KEY SECRET_KEY_CANARY'', CHECK(id IN(1,2)));'
 ]),TEncoding.UTF8);
"""
s=s.replace(' SourceHash:=THashSHA2',fixture+' SourceHash:=THashSHA2',1)
checks="""
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
 for V in Report.GetValue<TJSONArray>('rows') do Check(not ((V.GetValue<string>('kind')='key') and (V.GetValue<string>('table','')='InvalidInline')),'Unsupported column tail cannot leak partial key');
 for V in Report.GetValue<TJSONArray>('rows') do if (V.GetValue<string>('kind')='key') and (V.GetValue<string>('table')='"Quoted Child"') then Check(V.GetValue<string>('relationship_status')='captured links complete','Quoted dotted identifier remains exact single member');
 for V in Report.GetValue<TJSONArray>('rows') do if (V.GetValue<string>('kind')='key') and (V.GetValue<string>('table')='CaseMismatch') then Check(V.GetValue<string>('relationship_status')='relationship gaps','Dialect case folding is not guessed');
 Check(Find('MissingTargetColumn | AbsentColumn_FK','declared key').ToJSON.Contains('missing captured declaration'),'Missing referenced column reported');
 Check(not Report.ToJSON.Contains('SECRET_KEY_CANARY'),'Key-like string content omitted');
 Check(not Report.ToJSON.Contains('LiteralSafety | anonymous primary'),'Default and CHECK do not invent keys');
 Check(Row.GetValue<Int64>('generation_id')=Generation,'Key retains capture generation');
 Check(Row.GetValue<string>('source_hash')=THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'keys.sql')),'Key retains original SQL hash');
 Check(TDPHDatabaseSchema.Describe(Row).Contains('Ordered local columns'),'Key explanation leads with structured facts');
 Check(TDPHKeyboardInspector.ReadSource(View,TPath.Combine(Fixture,'Schema.dpr'),Row,Row.GetValue<TJSONObject>('range')).Contains('Child_FK'),'Guarded key source navigation works');
 Refuses('',Row,'Detached key source refused');
"""
# One aggregate check, not one per unrelated inventory row.
checks=checks.replace(" for V in Report.GetValue<TJSONArray>('rows') do Check(not ((V.GetValue<string>('kind')='key') and (V.GetValue<string>('table','')='InvalidInline')),'Unsupported column tail cannot leak partial key');", " Check(not Report.ToJSON.Contains('InvalidInline | anonymous primary'),'Unsupported column tail cannot leak partial key');")
s=s.replace(" Other:=nil;\n Check(not Report.ToJSON.Contains('SECRET_SQL_CANARY')",checks+"\n Other:=nil;\n Check(not Report.ToJSON.Contains('SECRET_SQL_CANARY')",1)
ui="""
 Form.DatabaseSchemaKind.ItemIndex:=7;Form.DatabaseSchemaState.ItemIndex:=7;Form.DatabaseSchemaFilter.Text:='Child_FK';Form.DatabaseSchemaFilterChange(nil);
 Check(Form.DatabaseSchemaList.Count=1,'Native key kind state and constraint name filters combine');
 Check(Form.DatabaseSchemaMemo.Text.Contains('Ordered local columns'),'Native key details explain composite membership');
 Check(Form.DatabaseSchemaLinks.Items.Count=6,'Native relationship selector exposes exact targets');
 Form.DatabaseSchemaLinks.ItemIndex:=4;Form.DatabaseSchemaFollowClick(nil);
 Check(Form.DatabaseSchemaMemo.Text.Contains('COLUMN Parent.a'),'Follow relationship selects exact captured target across pages');
 Form.DatabaseSchemaKind.ItemIndex:=7;Form.DatabaseSchemaState.ItemIndex:=7;Form.DatabaseSchemaFilter.Text:='Child_FK';Form.DatabaseSchemaFilterChange(nil);
"""
s=s.replace(" Form.WorkspaceTabs.ActiveTab:=Form.DatabaseSchemaTab;",ui+" Form.WorkspaceTabs.ActiveTab:=Form.DatabaseSchemaTab;",1)
s=s.replace("Controlled SQL column/type/nullability/default/constraint capture, unsupported-entry gaps, duplicate ownership, literal omission, persistence and native FMX controls.","Controlled captured primary/foreign/unique keys, ordered relationships, unresolved evidence, grammar gaps, persistence and native FMX navigation.")
(r/'tests/DPH.Tests.DatabaseKeys.dpr').write_text(s,encoding='utf-8')
s=(r/'tools/build-database-columns.cmd').read_text().replace('DatabaseColumns','DatabaseKeys')
(r/'tools/build-database-keys.cmd').write_text(s,encoding='utf-8')
