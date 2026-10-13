from pathlib import Path
r=Path.cwd();s=(r/'tests/DPH.Tests.DatabaseSchema.dpr').read_text(encoding='utf-8-sig')
s=s.replace('DPH.Tests.DatabaseSchema','DPH.Tests.SchemaHistory').replace('database-schema-validation','schema-history-validation').replace('phase1-database-schema-','phase1-schema-history-')
s=s.replace("'end; end.']),TEncoding.UTF8);", "'TFile.ReadAllText(''001_initial.sql''); TFile.ReadAllText(''002_upgrade.sql'');',\n 'TFile.ReadAllText(''003_counter.sql''); TFile.ReadAllText(''004_dynamic.sql'');',\n 'end; end.']),TEncoding.UTF8);")
anchor=" SourceHash:=THashSHA2.GetHashStringFromFile"
fixtures=""" TFile.WriteAllText(TPath.Combine(Fixture,'001_initial.sql'),'CREATE TABLE Seed (id integer); PRAGMA user_version=1; PRAGMA integrity_check;',TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(Fixture,'002_upgrade.sql'),'-- PRAGMA user_version=999;'+sLineBreak+'PRAGMA main.user_version(2); PRAGMA user_version=3; PRAGMA foreign_key_check; SELECT ''SECRET_HISTORY_CANARY'';',TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(Fixture,'003_counter.sql'),'PRAGMA schema_version=42; PRAGMA user_version;',TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(Fixture,'004_dynamic.sql'),'PRAGMA user_version=runtime_value;',TEncoding.UTF8);
"""
assert anchor in s;s=s.replace(anchor,fixtures+anchor,1)
anchor=" Check(Find('Sales','declared header')<>nil"
extra=""" Row:=Find('001_initial.sql','migration candidate');Check(Row<>nil,'Referenced migration file candidate discovered');
 Check(Row.GetValue<string>('filename_order')='001','Filename order retained as qualified candidate');
 Check(Row.GetValue<string>('target_version').Contains('user_version=1'),'Explicit application version assignment retained');
 Check(Row.GetValue<string>('verification').Contains('integrity_check'),'Verification request retained without executing it');
 Check(Row.GetValue<string>('applied_status').StartsWith('unknown'),'Applied deployment status remains unknown');
 Check(Row.GetValue<TJSONArray>('loader_evidence').Count=1,'Exact captured loader context linked');
 Check(Row.GetValue<TJSONArray>('links').Count>0,'Script links captured schema evidence');
 Check(Row.GetValue<string>('source_hash')=THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'001_initial.sql')),'Migration SHA256 matches exact source');
 Check(Row.GetValue<Int64>('generation_id')=Generation,'Migration belongs to exact capture generation');
 Check(TDPHDatabaseSchema.Describe(Row).Contains('A migration changes'),'Newcomer explanation describes migration purpose');
 Row:=Find('002_upgrade.sql','migration candidate');
 Check(Row.GetValue<string>('target_version').Contains('user_version=2'),'Parenthesized schema-qualified version retained');
 Check(Row.GetValue<string>('target_version').Contains('user_version=3'),'Multiple assignments retained without selecting winner');
 Check(not Row.GetValue<string>('target_version').Contains('999'),'Comment version not promoted');
 Check(Row.GetValue<string>('verification').Contains('foreign_key_check'),'Foreign-key verification request retained');
 Check(not Report.ToJSON.Contains('SECRET_HISTORY_CANARY'),'Migration literal contents remain omitted');
 Check(Find('003_counter.sql','migration candidate').GetValue<string>('target_version')='unknown','Engine schema counter and version query are not application assignments');
 Check(Find('004_dynamic.sql','migration candidate').GetValue<string>('target_version')='unknown','Dynamic application version remains unknown');
 Check(Find('004_dynamic.sql','migration candidate').GetValue<string>('version_basis').Contains('unresolved'),'Unsupported assignment explains unresolved evidence');
 Check(Find('broken.sql','migration candidate').GetValue<string>('version_basis').Contains('Unterminated'),'Malformed scripts preserve explicit history gaps');
"""
assert anchor in s;s=s.replace(anchor,extra+anchor,1)
anchor=" Form.WorkspaceTabs.ActiveTab:=Form.DatabaseSchemaTab;Form.Show;"
extra=""" Form.DatabaseSchemaKind.ItemIndex:=Form.DatabaseSchemaKind.Items.IndexOf('migration');Form.DatabaseSchemaState.ItemIndex:=0;Form.DatabaseSchemaFilter.Text:='001_initial.sql';Form.DatabaseSchemaFilterChange(nil);
 Check(Form.DatabaseSchemaList.Count=1,'Native migration filter selects exact script');
 Check(Form.DatabaseSchemaMemo.Text.Contains('Target version:'),'Native migration details lead with version evidence');
 Check(Form.DatabaseSchemaFollow.Enabled,'Native migration can follow schema evidence');
 Form.DatabaseSchemaLinks.ItemIndex:=0;Form.DatabaseSchemaFollowClick(nil);Check(Form.DatabaseSchemaMemo.Text.Contains('Seed'),'Native relationship opens captured schema');
 Form.DatabaseSchemaKind.ItemIndex:=Form.DatabaseSchemaKind.Items.IndexOf('migration');Form.DatabaseSchemaFilter.Text:='001_initial.sql';Form.DatabaseSchemaFilterChange(nil);
"""
assert anchor in s;s=s.replace(anchor,extra+anchor,1)
(r/'tests/DPH.Tests.SchemaHistory.dpr').write_text(s,encoding='utf-8')
s=(r/'tools/build-database-schema.cmd').read_text().replace('DatabaseSchema','SchemaHistory');(r/'tools/build-schema-history.cmd').write_text(s,encoding='utf-8')
