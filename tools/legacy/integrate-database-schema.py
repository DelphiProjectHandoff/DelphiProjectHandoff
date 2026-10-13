from pathlib import Path
r=Path.cwd();p=r/'DPH.UI.Main.pas';s=p.read_text(encoding='utf-8-sig')
s=s.replace('    DatabaseInventoryTab:TTabItem;', '''    DatabaseSchemaTab:TTabItem;
    DatabaseSchemaPurpose,DatabaseSchemaStatus:TLabel;
    DatabaseSchemaToolbar:THorzScrollBox;
    DatabaseSchemaFilter:TEdit;
    DatabaseSchemaKind,DatabaseSchemaState:TComboBox;
    DatabaseSchemaFirst,DatabaseSchemaNext,DatabaseSchemaSource:TButton;
    DatabaseSchemaList:TListBox;
    DatabaseSchemaMemo:TMemo;
    DatabaseInventoryTab:TTabItem;''',1)
s=s.replace('    procedure DatabaseInventoryFilterChange(Sender:TObject);','''    procedure DatabaseSchemaFilterChange(Sender:TObject);
    procedure DatabaseSchemaSelectionChange(Sender:TObject);
    procedure DatabaseSchemaSourceClick(Sender:TObject);
    procedure DatabaseInventoryFilterChange(Sender:TObject);''',1)
s=s.replace('    FDatabaseInventory:TJSONObject;','''    FDatabaseSchema:TJSONObject;
    FDatabaseSchemaRows:TList<TJSONObject>;
    FDatabaseSchemaOffset:Integer;
    FDatabaseInventory:TJSONObject;''',1)
s=s.replace('DPH.Workspace.ScreenHistory,DPH.Workspace.DatabaseConnections;', 'DPH.Workspace.ScreenHistory,DPH.Workspace.DatabaseConnections,DPH.Workspace.DatabaseSchema;')
s=s.replace('  FDatabaseInventoryRows:=TList<TJSONObject>.Create;','  FDatabaseSchemaRows:=TList<TJSONObject>.Create;\n  FDatabaseInventoryRows:=TList<TJSONObject>.Create;',1)
s=s.replace('  FDatabaseInventoryRows.Free;', '  FDatabaseSchemaRows.Free;FDatabaseSchema.Free;\n  FDatabaseInventoryRows.Free;',1)
s=s.replace('  FDatabaseInventoryRows.Clear;FreeAndNil(FDatabaseInventory);DatabaseInventoryFilterChange(nil);','  FDatabaseSchemaRows.Clear;FreeAndNil(FDatabaseSchema);DatabaseSchemaFilterChange(nil);\n  FDatabaseInventoryRows.Clear;FreeAndNil(FDatabaseInventory);DatabaseInventoryFilterChange(nil);',1)
s=s.replace('  FDatabaseInventoryRows.Clear;FreeAndNil(FDatabaseInventory);FDatabaseInventory:=', '  FDatabaseSchemaRows.Clear;FreeAndNil(FDatabaseSchema);FDatabaseSchema:=TDPHDatabaseSchema.Inspect(FView);DatabaseSchemaFilterChange(nil);\n  FDatabaseInventoryRows.Clear;FreeAndNil(FDatabaseInventory);FDatabaseInventory:=',1)
methods='''procedure TDPHMainForm.DatabaseSchemaFilterChange(Sender:TObject);
var V:TJSONValue;Row:TJSONObject;Count:Integer;
begin
 if FDatabaseSchemaRows=nil then Exit;
 if Sender=DatabaseSchemaNext then Inc(FDatabaseSchemaOffset,250) else FDatabaseSchemaOffset:=0;
 FDatabaseSchemaRows.Clear;DatabaseSchemaList.Items.Clear;DatabaseSchemaNext.Enabled:=False;DatabaseSchemaSelectionChange(nil);
 if FDatabaseSchema=nil then begin DatabaseSchemaStatus.Text:='Open a captured project to inspect tables, views and schemas.';Exit;end;
 Count:=0;
 for V in FDatabaseSchema.GetValue<TJSONArray>('rows') do begin Row:=V as TJSONObject;
  if (DatabaseSchemaKind.ItemIndex>0) and (Row.GetValue<string>('kind')<>DatabaseSchemaKind.Selected.Text) then Continue;
  if (DatabaseSchemaState.ItemIndex>0) and (Row.GetValue<string>('status')<>DatabaseSchemaState.Selected.Text) then Continue;
  if (DatabaseSchemaFilter.Text.Trim<>'') and not ContainsText(Row.GetValue<string>('name')+' '+Row.GetValue<string>('schema')+' '+Row.GetValue<string>('source'),DatabaseSchemaFilter.Text.Trim) then Continue;
  if (Count>=FDatabaseSchemaOffset) and (FDatabaseSchemaRows.Count<250) then begin FDatabaseSchemaRows.Add(Row);DatabaseSchemaList.Items.Add(Row.GetValue<string>('kind')+' | '+Row.GetValue<string>('name')+' | '+Row.GetValue<string>('status')+' | '+Row.GetValue<string>('source')+':'+Row.GetValue<TJSONObject>('range').GetValue('line').Value);end;Inc(Count);
 end;
 DatabaseSchemaNext.Enabled:=Count>FDatabaseSchemaOffset+FDatabaseSchemaRows.Count;
 DatabaseSchemaStatus.Text:=Format('%d matches; %d shown from %d. Captured declarations and references; deployed schema unverified.',[Count,FDatabaseSchemaRows.Count,FDatabaseSchemaOffset]);
 if DatabaseSchemaList.Count>0 then begin DatabaseSchemaList.ItemIndex:=0;DatabaseSchemaSelectionChange(nil);end
 else DatabaseSchemaMemo.Text:=FDatabaseSchema.GetValue<string>('qualification')+sLineBreak+sLineBreak+'No matching captured evidence. Clear filters or attach approved SQL scripts referenced by the project and reassess. Empty results do not prove the application has no schema.';
end;
procedure TDPHMainForm.DatabaseSchemaSelectionChange(Sender:TObject);
begin
 DatabaseSchemaSource.Enabled:=False;DatabaseSchemaMemo.Text:='Select a table, view, schema or unsupported statement to read its captured evidence and next investigation.';
 if (FDatabaseSchemaRows=nil) or (DatabaseSchemaList.ItemIndex<0) or (DatabaseSchemaList.ItemIndex>=FDatabaseSchemaRows.Count) then Exit;
 DatabaseSchemaMemo.Text:=TDPHDatabaseSchema.Describe(FDatabaseSchemaRows[DatabaseSchemaList.ItemIndex])+sLineBreak+sLineBreak+FDatabaseSchema.GetValue<string>('qualification');
 DatabaseSchemaSource.Enabled:=True;
end;
procedure TDPHMainForm.DatabaseSchemaSourceClick(Sender:TObject);
var Row,Range:TJSONObject;
begin
 if (FView=nil) or (DatabaseSchemaList.ItemIndex<0) or (DatabaseSchemaList.ItemIndex>=FDatabaseSchemaRows.Count) then Exit;
 Row:=FDatabaseSchemaRows[DatabaseSchemaList.ItemIndex];Range:=Row.GetValue<TJSONObject>('range');
 try SourceMemo.Text:=TDPHKeyboardInspector.ReadSource(FView,FEntry,Row,Range);SourceMemo.CaretPosition:=TCaretPosition.Create(Max(0,Range.GetValue<Integer>('line')-1),0);WorkspaceTabs.ActiveTab:=SourceTab;
 except on E:Exception do DatabaseSchemaMemo.Lines.Add('Source unavailable: '+E.Message);end;
end;
'''
s=s.replace('procedure TDPHMainForm.DatabaseInventoryFilterChange(Sender:TObject);',methods+'\nprocedure TDPHMainForm.DatabaseInventoryFilterChange(Sender:TObject);',1)
p.write_text(s,encoding='utf-8')
p=r/'DPH.UI.Main.fmx';s=p.read_text(encoding='utf-8-sig');start=s.index('object DatabaseInventoryTab: TTabItem');end=s.index('object HistoryTab:',start);tab=s[start:end].replace('DatabaseInventory','DatabaseSchema').replace("Text = 'Database connections'","Text = 'Database schema'")
tab=tab.replace("Text = 'Select a row for database engine, version declarations and masked evidence. Filter by engine name or component. Scroll commands sideways to follow references. No target database is opened.'","Text = 'Inspect captured tables, views and schemas. Declared headers, inferred SQL references and unsupported statements remain distinct. Select evidence below; scroll commands sideways. No SQL is executed.'")
tab=tab.replace("'connection'\n'dataset'\n'data source'\n'transaction'\n'session'\n'connection definition'\n'database candidate'","'table'\n'view'\n'schema'\n'gap'")
tab=tab.replace("TextPrompt = 'Find component, reference or safe setting'","TextPrompt = 'Find object, schema or source file'")
a=tab.index('object DatabaseSchemaLinks:');b=tab.index('\nend\nend\nobject DatabaseSchemaStatus:',a)
tab=tab[:a]+'''object DatabaseSchemaState: TComboBox
Position.X = 640
Position.Y = 0
Width = 200
Height = 28
OnChange = DatabaseSchemaFilterChange
Items.Strings = (
'All'
'declared header'
'inferred reference'
'qualifier reference'
'unsupported')
ItemIndex = 0
end
object DatabaseSchemaSource: TButton
Position.X = 848
Position.Y = 0
Width = 125
Height = 28
Text = 'Open source'
OnClick = DatabaseSchemaSourceClick
Enabled = False'''+tab[b:]
tab=tab.replace("Text = 'Database evidence (scroll for details)'","Text = 'Schema evidence and next investigation (scroll for details)'")
s=s[:end]+tab+s[end:];s=s.replace("'Database connections'","'Database connections'\n'Database schema'",1);p.write_text(s,encoding='utf-8')
p=r/'DelphiProjectHandoff.dproj';s=p.read_text(encoding='utf-8-sig');needle='<DCCReference Include="DPH.Workspace.DatabaseConnections.pas"';pos=s.index(needle);line=s.rfind('\n',0,pos);s=s[:line]+ '\n        <DCCReference Include="DPH.Workspace.DatabaseSchema.pas"/>'+s[line:];p.write_text(s,encoding='utf-8')
