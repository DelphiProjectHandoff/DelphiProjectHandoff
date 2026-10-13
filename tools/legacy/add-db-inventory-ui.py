from pathlib import Path
r=Path.cwd();p=r/'DPH.UI.Main.pas';s=p.read_text(encoding='utf-8-sig')
s=s.replace('    HistoryTab:TTabItem;','''    DatabaseInventoryTab:TTabItem;
    DatabaseInventoryPurpose,DatabaseInventoryStatus:TLabel;
    DatabaseInventoryToolbar:THorzScrollBox;
    DatabaseInventoryFilter:TEdit;
    DatabaseInventoryKind,DatabaseInventoryLinks:TComboBox;
    DatabaseInventoryFirst,DatabaseInventoryNext,DatabaseInventoryFollow:TButton;
    DatabaseInventoryList:TListBox;
    DatabaseInventoryMemo:TMemo;
    HistoryTab:TTabItem;''',1)
s=s.replace('    procedure HistorySelectionChange(Sender:TObject);','''    procedure DatabaseInventoryFilterChange(Sender:TObject);
    procedure DatabaseInventorySelectionChange(Sender:TObject);
    procedure DatabaseInventoryFollowClick(Sender:TObject);
    procedure HistorySelectionChange(Sender:TObject);''',1)
s=s.replace('    FScreenHistory:TJSONObject;','''    FDatabaseInventory:TJSONObject;
    FDatabaseInventoryRows:TList<TJSONObject>;
    FDatabaseInventoryTargets:TList<string>;
    FDatabaseInventoryOffset:Integer;
    FScreenHistory:TJSONObject;''',1)
s=s.replace('DPH.Workspace.ScreenHistory;','DPH.Workspace.ScreenHistory,DPH.Workspace.DatabaseConnections;',1)
s=s.replace('  FHistoryRows:=TList<TJSONObject>.Create;','''  FHistoryRows:=TList<TJSONObject>.Create;
  FDatabaseInventoryRows:=TList<TJSONObject>.Create;
  FDatabaseInventoryTargets:=TList<string>.Create;''',1)
s=s.replace('  FHistoryRows.Free;FScreenHistory.Free;','''  FHistoryRows.Free;FScreenHistory.Free;
  FDatabaseInventoryRows.Free;FDatabaseInventoryTargets.Free;FDatabaseInventory.Free;''',1)
s=s.replace('procedure TDPHMainForm.ClearWorkspace;\nbegin','''procedure TDPHMainForm.ClearWorkspace;
begin
  FDatabaseInventoryRows.Clear;FreeAndNil(FDatabaseInventory);DatabaseInventoryFilterChange(nil);''',1)
s=s.replace('  FKeyboardRows.Clear; FreeAndNil(FKeyboard);','''  FDatabaseInventoryRows.Clear;FreeAndNil(FDatabaseInventory);FDatabaseInventory:=TDPHDatabaseConnections.Inspect(FView);DatabaseInventoryFilterChange(nil);
  FKeyboardRows.Clear; FreeAndNil(FKeyboard);''',1)
methods='''procedure TDPHMainForm.DatabaseInventoryFilterChange(Sender:TObject);
var V:TJSONValue;Row:TJSONObject;Count:Integer;Kind:string;
begin
 if FDatabaseInventoryRows=nil then Exit;
 if Sender=DatabaseInventoryNext then Inc(FDatabaseInventoryOffset,250) else FDatabaseInventoryOffset:=0;
 FDatabaseInventoryRows.Clear;DatabaseInventoryList.Items.Clear;DatabaseInventoryNext.Enabled:=False;DatabaseInventorySelectionChange(nil);
 if FDatabaseInventory=nil then begin DatabaseInventoryStatus.Text:='Open a captured project to inspect its database declarations.';Exit;end;
 Kind:='';if DatabaseInventoryKind.ItemIndex>0 then Kind:=DatabaseInventoryKind.Selected.Text;Count:=0;
 for V in FDatabaseInventory.GetValue<TJSONArray>('rows') do begin Row:=V as TJSONObject;
  if (Kind<>'') and (Row.GetValue<string>('role')<>Kind) then Continue;
  if (DatabaseInventoryFilter.Text.Trim<>'') and not ContainsText(Row.ToJSON,DatabaseInventoryFilter.Text.Trim) then Continue;
  if (Count>=FDatabaseInventoryOffset) and (FDatabaseInventoryRows.Count<250) then begin FDatabaseInventoryRows.Add(Row);DatabaseInventoryList.Items.Add(Row.GetValue<string>('role')+' | '+Row.GetValue<string>('path')+' : '+Row.GetValue<string>('class'));end;Inc(Count);
 end;
 DatabaseInventoryNext.Enabled:=Count>FDatabaseInventoryOffset+FDatabaseInventoryRows.Count;
 DatabaseInventoryStatus.Text:=Format('%d matches; %d shown from %d. Configuration is masked; no target database is opened.',[Count,FDatabaseInventoryRows.Count,FDatabaseInventoryOffset]);
 if DatabaseInventoryList.Count>0 then begin DatabaseInventoryList.ItemIndex:=0;DatabaseInventorySelectionChange(nil);end;
end;
procedure TDPHMainForm.DatabaseInventorySelectionChange(Sender:TObject);
var Row:TJSONObject;Value:TJSONValue;ID:string;
begin
 if FDatabaseInventoryTargets=nil then Exit;FDatabaseInventoryTargets.Clear;DatabaseInventoryLinks.Items.Clear;DatabaseInventoryFollow.Enabled:=False;
 DatabaseInventoryMemo.Text:='Select a connection, dataset, data source, transaction, session or definition. Missing configuration and runtime bindings remain unknown.';
 if (DatabaseInventoryList.ItemIndex<0) or (DatabaseInventoryList.ItemIndex>=FDatabaseInventoryRows.Count) then Exit;
 Row:=FDatabaseInventoryRows[DatabaseInventoryList.ItemIndex];DatabaseInventoryMemo.Text:=FDatabaseInventory.GetValue<string>('qualification')+sLineBreak+sLineBreak+TDPHDatabaseConnections.Describe(Row);
 for Value in Row.GetValue<TJSONArray>('links') do if Value.TryGetValue<string>('target_id',ID) then begin FDatabaseInventoryTargets.Add(ID);DatabaseInventoryLinks.Items.Add('Target via '+Value.GetValue<string>('property')+': '+Value.GetValue<string>('reference'));end;
 for Value in Row.GetValue<TJSONArray>('used_by') do begin FDatabaseInventoryTargets.Add(Value.GetValue<string>('id'));DatabaseInventoryLinks.Items.Add('Used by '+Value.GetValue<string>('name')+' via '+Value.GetValue<string>('property'));end;
 DatabaseInventoryFollow.Enabled:=FDatabaseInventoryTargets.Count>0;if DatabaseInventoryFollow.Enabled then DatabaseInventoryLinks.ItemIndex:=0;
end;
procedure TDPHMainForm.DatabaseInventoryFollowClick(Sender:TObject);
var ID:string;Value:TJSONValue;Index:Integer;
begin
 if (FDatabaseInventory=nil) or (DatabaseInventoryLinks.ItemIndex<0) or (DatabaseInventoryLinks.ItemIndex>=FDatabaseInventoryTargets.Count) then Exit;
 ID:=FDatabaseInventoryTargets[DatabaseInventoryLinks.ItemIndex];DatabaseInventoryFilter.Text:='';DatabaseInventoryKind.ItemIndex:=0;
 Index:=0;for Value in FDatabaseInventory.GetValue<TJSONArray>('rows') do begin if Value.GetValue<string>('id')=ID then Break;Inc(Index);end;
 FDatabaseInventoryOffset:=(Index div 250)*250;
 // Reuse pagination while keeping the exact target page.
 Dec(FDatabaseInventoryOffset,250);DatabaseInventoryFilterChange(DatabaseInventoryNext);
 DatabaseInventoryList.ItemIndex:=Index mod 250;DatabaseInventorySelectionChange(nil);
end;
'''
s=s.replace('procedure TDPHMainForm.HistorySelectionChange(Sender:TObject);',methods+'procedure TDPHMainForm.HistorySelectionChange(Sender:TObject);',1);p.write_text(s,encoding='utf-8')
p=r/'DPH.UI.Main.fmx';s=p.read_text(encoding='utf-8-sig').replace("'Screen history'\n","'Screen history'\n'Database connections'\n",1)
tab='''object DatabaseInventoryTab: TTabItem
Text = 'Database connections'
object DatabaseInventoryPurpose: TLabel
Align = Top
Height = 80
Margins.Left = 12
Margins.Right = 12
WordWrap = True
Text = 'Inspect captured database connections and their datasets. Select a row for masked configuration, source evidence and unresolved links. Follow a target or Used by reference using the toolbar. No target database is opened.'
StyledSettings = []
TextSettings.FontColor = xFF146CB4
end
object DatabaseInventoryToolbar: THorzScrollBox
Align = Top
Height = 44
ShowScrollBars = True
'''
for name,kind,x,w,text,event in [('Kind','TComboBox',8,160,'','DatabaseInventoryFilterChange'),('Filter','TEdit',176,260,'Find component, reference or safe setting','DatabaseInventoryFilterChange'),('First','TButton',444,90,'First page','DatabaseInventoryFilterChange'),('Next','TButton',542,90,'Next page','DatabaseInventoryFilterChange'),('Links','TComboBox',640,330,'',''),('Follow','TButton',978,125,'Follow reference','DatabaseInventoryFollowClick')]:
 tab+=f'object DatabaseInventory{name}: {kind}\nPosition.X = {x}\nPosition.Y = 0\nWidth = {w}\nHeight = 28\n'
 if text:tab+=f"{'TextPrompt' if kind=='TEdit' else 'Text'} = '{text}'\n"
 if event:tab+=f"{'OnClick' if kind=='TButton' else 'OnChange'} = {event}\n"
 if name=='Kind':tab+="Items.Strings = (\n'All'\n'connection'\n'dataset'\n'data source'\n'transaction'\n'session'\n'connection definition'\n'database candidate')\nItemIndex = 0\n"
 if name in ['Next','Follow']:tab+='Enabled = False\n'
 tab+='end\n'
tab+='''end
object DatabaseInventoryStatus: TLabel
Align = Top
Height = 48
Margins.Left = 12
Margins.Right = 12
WordWrap = True
Text = 'Open a captured project to begin.'
end
object DatabaseInventoryList: TListBox
Align = Top
Height = 120
Margins.Left = 12
Margins.Right = 12
OnChange = DatabaseInventorySelectionChange
end
object DatabaseInventorySplitter: TSplitter
Align = Top
Height = 6
end
object DatabaseInventoryEvidenceLabel: TLabel
Align = Top
Height = 26
Margins.Left = 12
Margins.Right = 12
Text = 'Database evidence and masked configuration'
end
object DatabaseInventoryMemo: TMemo
Align = Client
ReadOnly = True
WordWrap = True
ShowScrollBars = True
Margins.Left = 12
Margins.Right = 12
Margins.Bottom = 12
end
end
'''
assert 'object DatabaseInventoryTab:' not in s;s=s.replace('object HistoryTab: TTabItem',tab+'object HistoryTab: TTabItem',1);p.write_text(s,encoding='utf-8')
p=r/'DelphiProjectHandoff.dproj';s=p.read_text(encoding='utf-8-sig');key='<DCCReference Include="DPH.Workspace.ScreenHistory.pas"/>';assert key in s;s=s.replace(key,key+'\n        <DCCReference Include="DPH.Workspace.DatabaseConnections.pas"/>');p.write_text(s,encoding='utf-8')
