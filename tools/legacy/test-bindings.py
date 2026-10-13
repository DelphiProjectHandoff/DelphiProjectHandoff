from pathlib import Path
r=Path.cwd();s=(r/'tests/DPH.Tests.DatabaseConnections.dpr').read_text()
s=s.replace('DPH.Tests.DatabaseConnections','DPH.Tests.DatasetBindings').replace('database-connections-validation','dataset-bindings-validation').replace('phase1-database-connections','phase1-dataset-bindings')
s=s.replace("' object Query: TFDQuery','  Connection = MainConnection',' end',", """' object Query: TFDQuery','  Connection = MainConnection',
 '  object Amount: TCurrencyField','   FieldName = ''AMOUNT''','   Required = True','   ReadOnly = False','  end',
 '  object CodeA: TStringField','   FieldName = ''CODE''','  end',
 '  object CodeB: TStringField','   FieldName = ''CODE''','  end',' end',
 ' object AmountEdit: TDBEdit','  DataSource = Source','  DataField = ''amount''',' end',
 ' object CodeEdit: TDBEdit','  DataSource = Source','  DataField = ''CODE''',' end',
 ' object DynamicEdit: TDBEdit','  DataSource = Source','  DataField = ''RUNTIME_FIELD''',' end',
 ' object BrokenEdit: TDBEdit','  DataSource = NoSource','  DataField = ''AMOUNT''',' end',
 ' object NilEdit: TDBEdit','  DataSource = nil','  DataField = ''AMOUNT''',' end',
 ' object Lookup: TStringField','  LookupDataSet = Query','  FieldName = ''LOOKUP''',' end',""")
s=s.replace("'  SQLConnection = TouchConnection',' end','end'", "'  SQLConnection = TouchConnection','  object TouchID: TIntegerField','   FieldName = ''ID''','  end',' end',' object TouchSource: TBindSourceDB','  DataSet = TouchQuery',' end',' object TouchLink: TLinkControlToField','  BindSource = TouchSource','  DataField = ''ID''',' end','end'")
s=s.replace("'  Connection = BinaryConnection',' end','end'", "'  Connection = BinaryConnection','  object BinaryID: TIntegerField','   FieldName = ''ID''','  end',' end',' object BinarySource: TDataSource','  DataSet = BinaryQuery',' end',' object BinaryEdit: TDBEdit','  DataSource = BinarySource','  DataField = ''ID''',' end','end'")
needle=" Check(Find('MainConnection')<>nil,'Text DFM connection captured');"
s=s.replace(needle,""" Check(Find('Amount').GetValue<string>('role')='persistent field','Persistent field is explicitly classified');
 Check(Find('AmountEdit').GetValue<string>('role')='bound control','Data-aware control is classified');
 Check(Reference('Amount','DataSet').GetValue<string>('target_id')=Find('Query').GetValue<string>('id'),'Field parent resolves exact owning dataset');
 Check(Reference('AmountEdit','DataSource').GetValue<string>('target_id')=Find('Source').GetValue<string>('id'),'Control resolves data source');
 Check(Reference('AmountEdit','DataField').GetValue<string>('target_id')=Find('Amount').GetValue<string>('id'),'Control field resolves through dataset chain');
 Check(Reference('AmountEdit','DataField').GetValue<Integer>('line')>0,'Field binding retains property line');
 Check(Reference('AmountEdit','DataField').GetValue<Integer>('end')>Reference('AmountEdit','DataField').GetValue<Integer>('start'),'Field binding retains byte range');
 Check(Find('Amount').GetValue<TJSONArray>('used_by').Count=1,'Persistent field lists exact bound control');
 Check(Reference('CodeEdit','DataField').GetValue<string>('resolution').Contains('ambiguous'),'Duplicate field names remain ambiguous');
 Check(not Reference('CodeEdit','DataField').ToJSON.Contains('target_id'),'Duplicate fields never select arbitrary target');
 Check(not Reference('DynamicEdit','DataField').ToJSON.Contains('target_id'),'Runtime field is not invented');
 Check(not Reference('BrokenEdit','DataField').ToJSON.Contains('target_id'),'Missing source prevents field link');
 Check(not Reference('NilEdit','DataField').ToJSON.Contains('target_id'),'Nil source prevents field link');
 Check(Reference('Lookup','LookupDataSet').GetValue<string>('target_id')=Find('Query').GetValue<string>('id'),'Lookup dataset reference navigable');
 Check(not Reference('Lookup','DataSet').ToJSON.Contains('target_id'),'Field with non-dataset parent remains unowned');
 Check(Reference('TouchLink','DataField').GetValue<string>('target_id')=Find('TouchID').GetValue<string>('id'),'FMX BindSource chain resolves captured field');
 Check(Reference('BinaryEdit','DataField').GetValue<string>('target_id')=Find('BinaryID').GetValue<string>('id'),'Binary DFM field chain resolves');
 Check(TDPHDatabaseConnections.Describe(Find('Amount')).Contains('Required = True'),'Field metadata shown');
 Check(TDPHDatabaseConnections.Describe(Find('AmountEdit')).StartsWith('DATASET AND SCREEN BINDINGS'),'Binding explanation precedes engine guidance');
"""+needle)
needle=" Form.WorkspaceTabs.ActiveTab:=Form.DatabaseInventoryTab;Form.Show;"
s=s.replace(needle,""" Form.DatabaseInventoryKind.ItemIndex:=Form.DatabaseInventoryKind.Items.IndexOf('bound control');Form.DatabaseInventoryFilter.Text:='AmountEdit';Form.DatabaseInventoryFilterChange(nil);
 Check(Form.DatabaseInventoryList.Count=1,'Native bound control filter finds control');
 Check(Form.DatabaseInventoryMemo.Text.Contains('DataField -> amount'),'Native details show captured field binding');
 for I:=0 to Form.DatabaseInventoryLinks.Items.Count-1 do if Form.DatabaseInventoryLinks.Items[I].StartsWith('Target via DataField:') then Form.DatabaseInventoryLinks.ItemIndex:=I;
 Form.DatabaseInventoryFollowClick(nil);Check(Form.DatabaseInventoryMemo.Text.Contains('PERSISTENT FIELD MainModule.Query.Amount'),'Native follow opens exact persistent field');
 Check(Form.DatabaseInventoryLinks.Items.Count>=2,'Field has dataset and reverse control links');
 Form.DatabaseInventoryKind.ItemIndex:=Form.DatabaseInventoryKind.Items.IndexOf('persistent field');Form.DatabaseInventoryFilter.Text:='AMOUNT';Form.DatabaseInventoryFilterChange(nil);
 Check(Form.DatabaseInventoryList.Count=1,'Field name search finds persistent field');
"""+needle)
s=s.replace('Database connections validation passed:', 'Dataset bindings validation passed:')
(r/'tests/DPH.Tests.DatasetBindings.dpr').write_bytes(s.replace('\r\n','\n').replace('\n','\r\n').encode())
s=(r/'tools/build-database-connections.cmd').read_text().replace('DatabaseConnections','DatasetBindings')
(r/'tools/build-dataset-bindings.cmd').write_bytes(s.replace('\r\n','\n').replace('\n','\r\n').encode())
print('Dataset bindings fixture and build command ready')
