from pathlib import Path
r=Path.cwd();s=(r/'tests/DPH.Tests.DatasetBindings.dpr').read_text(encoding='utf-8-sig')
s=s.replace('DPH.Tests.DatasetBindings','DPH.Tests.DataRules').replace('dataset-bindings-validation','data-rules-validation').replace('phase1-dataset-bindings','phase1-data-rules').replace('Dataset bindings validation','Data rules validation')
start=s.index(" TFile.WriteAllText(TPath.Combine(Fixture,'Main.pas')")
end=s.index(" for Text in ['Remote'",start)
s=s[:start]+''' TFile.WriteAllText(TPath.Combine(Fixture,'Main.pas'),String.Join(sLineBreak,[
 'unit Main; interface uses System.SysUtils, Data.DB; type TMainModule = class',
 ' MainConnection: TFDConnection; Query: TFDQuery; Unserialized: TADOConnection;',
 ' Amount: TCurrencyField; InputAmount, OutputAmount: Currency; Normalized: string;',
 ' procedure ValidateAmount(Sender: TField);',
 ' procedure NormalizeText(Sender: TField; const Text: string);',
 ' procedure BeforeSave(DataSet: TDataSet);',
 'end; implementation {$R *.dfm}',
 'procedure TMainModule.ValidateAmount(Sender: TField); begin',
 ' if InputAmount < 0 then raise ERangeError.Create(''SENSITIVE_VALIDATION_CANARY'');',
 ' OutputAmount := InputAmount * 1.2;',
 ' if OutputAmount > 100 then Exit;',
 'end;',
 'procedure TMainModule.NormalizeText(Sender: TField; const Text: string); begin',
 ' Normalized := Trim(Text);',
 ' Normalized := ''SENSITIVE_TRANSFORM_CANARY'' + #65;',
 'end;',
 'procedure TMainModule.BeforeSave(DataSet: TDataSet); begin',
 ' if InputAmount = 0 then raise Exception.Create(''SENSITIVE_POST_CANARY'');',
 'end;',
 'end.']),TEncoding.UTF8);
'''+s[end:]
s=s.replace("' object Query: TFDQuery','  Connection = MainConnection',", "' object Query: TFDQuery','  Connection = MainConnection','  BeforePost = BeforeSave',")
s=s.replace("'   ReadOnly = False','  end',", "'   ReadOnly = False','   MinValue = 0','   MaxValue = 10000','   CustomConstraint = ''VALUE >= 0''','   DefaultExpression = ''1 + 2''','   ConstraintErrorMessage = ''SENSITIVE_CONSTRAINT_CANARY''','   OnValidate = ValidateAmount','   OnSetText = NormalizeText','   OnGetText = MissingHandler','  end',",1)
needle='procedure Render(const Name:string);'
helper='''function RuleRow(const Kind,ContainsTextValue:string):TJSONObject;
var V:TJSONValue;
begin Result:=nil;for V in Report.GetValue<TJSONArray>('rows') do
 if (V.GetValue<string>('role')='data rule') and V.GetValue<string>('rule_kind').Contains(Kind) and
 (V.GetValue<string>('expression')+' '+V.GetValue<string>('constraint')).Contains(ContainsTextValue) then Exit(V as TJSONObject);end;
'''
s=s.replace(needle,helper+needle,1)
needle=" Catalog:=TDPHWorkspaceCatalog.DefaultPath;"
checks=''' Check(Report.GetValue<Integer>('data_rule_count')>=16,'Field constraints and hook body rules captured');
 Check(not Report.GetValue<Boolean>('data_rules_truncated'),'Normal fixture rules not truncated');
 Row:=RuleRow('declared field constraint','MinValue = 0');Check(Row<>nil,'Declared numeric minimum retained');
 Check(Row.GetValue<string>('output')='MainModule.Query.Amount','Constraint context is exact field');
 Check(Row.GetValue<Integer>('range.start')>Find('Amount').GetValue<Integer>('range.start'),'Constraint source points at property, not field container');
 Check(RuleRow('declared field constraint','VALUE >= 0')<>nil,'Custom constraint structure retained');
 Check(RuleRow('declared field constraint','1 + 2')<>nil,'Default expression retained without evaluation');
 Check(RuleRow('validation condition','InputAmount < 0')<>nil,'Validation predicate captured');
 Check(RuleRow('validation exit','ERangeError')<>nil,'Validation exception candidate retained');
 Check(RuleRow('validation exit','Exit')=nil,'Bare Exit is represented as empty captured expression');
 Row:=RuleRow('transformation','InputAmount * 1.2');Check(Row<>nil,'Numeric transformation captured');
 Check(Row.GetValue<string>('input').Contains('InputAmount'),'Assignment input expression shown');
 Check(Row.GetValue<string>('output')='OutputAmount','Assignment output expression shown');
 Check(Row.GetValue<TJSONArray>('links').ToJSON.Contains('lexical input'),'Input declaration navigable');
 Check(Row.GetValue<TJSONArray>('links').ToJSON.Contains('lexical output'),'Output declaration navigable');
 Check(Row.GetValue<TJSONArray>('links').ToJSON.Contains('handler'),'Handler navigable');
 Check(Row.GetValue<string>('source_hash')=THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'Main.pas')),'Transformation source SHA256 retained');
 Check(RuleRow('transformation','Trim')<>nil,'Text transformation retained');
 Row:=RuleRow('validation or conversion hook','MissingHandler');Check(Row<>nil,'Missing hook remains visible');
 Check(Row.GetValue<string>('constraint').Contains('unresolved'),'Missing hook explicitly unresolved');
 Check(not Row.GetValue<TJSONArray>('links').ToJSON.Contains('handler'),'Missing handler has no invented target');
 Check(not Report.ToJSON.Contains('SENSITIVE_'),'Constraint and handler literals omitted from rule projection');
 Check(Report.ToJSON.Contains('[character code omitted]'),'Encoded character literal omitted');
 Check(TDPHDatabaseConnections.Describe(RuleRow('transformation','InputAmount * 1.2')).StartsWith('DATA VALIDATION AND TRANSFORMATION'),'Rule explanation appears first');
 Row:=TDPHDatabaseConnections.Inspect(Reopened);try Check(Row.ToJSON=Report.ToJSON,'Reopened capture retains identical rule evidence');finally Row.Free;end;
'''
s=s.replace(needle,checks+needle,1)
needle=" Form.WorkspaceTabs.ActiveTab:=Form.DatabaseInventoryTab;"
native=''' Form.DatabaseInventoryKind.ItemIndex:=Form.DatabaseInventoryKind.Items.IndexOf('data rule');Form.DatabaseInventoryFilter.Text:='InputAmount * 1.2';Form.DatabaseInventoryFilterChange(nil);
 Check(Form.DatabaseInventoryList.Count=1,'Native data rule filter searches transformation expression');
 Check(Form.DatabaseInventoryMemo.Text.StartsWith('DATA VALIDATION AND TRANSFORMATION'),'Native memo labels rule purpose');
 Check(Form.DatabaseInventoryMemo.Text.Contains('Input expression: InputAmount'),'Native input expression visible');
 Check(Form.DatabaseInventoryMemo.Text.Contains('Output expression: OutputAmount'),'Native output expression visible');
 Check(Form.DatabaseInventorySource.Enabled,'Rule source command available');
 Form.DatabaseInventorySourceClick(nil);Check(Form.DatabaseInventoryMemo.Text.Contains('Source is detached'),'Detached rule source is refused');
 for I:=0 to Form.DatabaseInventoryLinks.Items.Count-1 do if Form.DatabaseInventoryLinks.Items[I].StartsWith('Target via handler:') then Form.DatabaseInventoryLinks.ItemIndex:=I;
 Form.DatabaseInventoryFollowClick(nil);Check(Form.DatabaseInventoryMemo.Text.Contains('RULE DECLARATION Main.TMainModule.ValidateAmount'),'Native follow opens exact validation handler');
 Form.DatabaseInventoryKind.ItemIndex:=Form.DatabaseInventoryKind.Items.IndexOf('data rule');Form.DatabaseInventoryFilter.Text:='InputAmount * 1.2';Form.DatabaseInventoryFilterChange(nil);
'''
assert needle in s;s=s.replace(needle,native+needle,1)
(r/'tests/DPH.Tests.DataRules.dpr').write_text(s,encoding='utf-8')
tool=(r/'tools/build-dataset-bindings.cmd').read_text(encoding='utf-8-sig').replace('DatasetBindings','DataRules')
(r/'tools/build-data-rules.cmd').write_text(tool,encoding='utf-8')
print('Focused data-rule test created')
