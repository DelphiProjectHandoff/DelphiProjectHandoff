from pathlib import Path
r=Path.cwd();p=r/'DPH.UI.Main.pas';s=p.read_text(encoding='utf-8-sig')
s=s.replace('    CommandsTab: TTabItem;', '''    DynamicTab:TTabItem;
    DynamicPurpose,DynamicStatus:TLabel;
    DynamicToolbar:THorzScrollBox;
    DynamicFilterEdit:TEdit;
    DynamicFirstButton,DynamicNextButton,DynamicExplainButton,DynamicReferenceButton:TButton;
    DynamicReferenceCombo:TComboBox;
    DynamicList:TListBox;
    DynamicSplitter:TSplitter;
    DynamicMemo:TMemo;
    CommandsTab: TTabItem;''')
s=s.replace('    procedure CommandsFilterChange(Sender: TObject);','''    procedure DynamicFilterChange(Sender:TObject);
    procedure DynamicSelectionClick(Sender:TObject);
    procedure DynamicReferenceChange(Sender:TObject);
    procedure DynamicExplainClick(Sender:TObject);
    procedure CommandsFilterChange(Sender: TObject);''')
s=s.replace('    FCommands: TJSONObject;','''    FDynamic:TJSONObject;
    FDynamicRows:TList<TJSONObject>;
    FDynamicOffset:Integer;
    FCommands: TJSONObject;''')
s=s.replace('DPH.Workspace.Commands;','DPH.Workspace.Commands, DPH.Workspace.DynamicControls;')
s=s.replace('  FCommandRows:=TList<TJSONObject>.Create;','  FCommandRows:=TList<TJSONObject>.Create;\n  FDynamicRows:=TList<TJSONObject>.Create;')
s=s.replace('  FCommandRows.Free; FCommands.Free;','  FCommandRows.Free; FCommands.Free;\n  FDynamicRows.Free; FDynamic.Free;')
s=s.replace('procedure TDPHMainForm.ClearWorkspace;\nbegin','''procedure TDPHMainForm.ClearWorkspace;
begin
  FDynamicRows.Clear; FreeAndNil(FDynamic); DynamicList.Items.Clear; DynamicReferenceCombo.Items.Clear;
  DynamicMemo.Text:='Open a project to inspect creation sites.'; DynamicStatus.Text:='No capture loaded.';
  DynamicNextButton.Enabled:=False; DynamicExplainButton.Enabled:=False; DynamicReferenceButton.Enabled:=False;''')
s=s.replace('  FreeAndNil(FProjectMembers); FProjectMembers:=FView.ProjectMembers;', '''  FDynamicRows.Clear; FreeAndNil(FDynamic); FDynamic:=TDPHDynamicControls.Inspect(FView); DynamicFilterChange(nil);
  FreeAndNil(FProjectMembers); FProjectMembers:=FView.ProjectMembers;''')
a=s.index('procedure TDPHMainForm.CommandsFilterChange')
s=s[:a]+'''procedure TDPHMainForm.DynamicFilterChange(Sender:TObject);
var V:TJSONValue; Row:TJSONObject; Count:Integer; Query:string;
begin
 if Sender=DynamicNextButton then Inc(FDynamicOffset,250) else FDynamicOffset:=0;
 DynamicList.Items.Clear; FDynamicRows.Clear; DynamicReferenceCombo.Items.Clear;
 DynamicNextButton.Enabled:=False; DynamicExplainButton.Enabled:=False; DynamicReferenceButton.Enabled:=False;
 DynamicMemo.Text:='Select a creation site to read its evidence and limits.';
 if FDynamic=nil then Exit;
 Query:=DynamicFilterEdit.Text.Trim; Count:=0;
 for V in FDynamic.GetValue<TJSONArray>('rows') do begin Row:=V as TJSONObject;
  if (Query<>'') and not ContainsText(TDPHDynamicControls.Describe(Row),Query) then Continue;
  if (Count>=FDynamicOffset) and (FDynamicRows.Count<250) then begin FDynamicRows.Add(Row); DynamicList.Items.Add(Row.GetValue<string>('name')+' | '+Row.GetValue<string>('type')+' | instances unobserved'); end;
  Inc(Count);
 end;
 DynamicNextButton.Enabled:=Count>FDynamicOffset+FDynamicRows.Count;
 DynamicStatus.Text:=IntToStr(Count)+' matching creation sites; showing '+IntToStr(FDynamicRows.Count)+' from offset '+IntToStr(FDynamicOffset)+'. Reassess older captures for new links.';
 if DynamicList.Count>0 then begin DynamicList.ItemIndex:=0; DynamicSelectionClick(nil); end
 else DynamicMemo.Text:='No matching captured creation sites. Clear the filter or reassess. Unsupported factories and indirect creation remain gaps; this is not proof of no runtime controls.';
end;
procedure TDPHMainForm.DynamicSelectionClick(Sender:TObject);
var Row:TJSONObject; V:TJSONValue;
begin
 DynamicExplainButton.Enabled:=False; DynamicReferenceButton.Enabled:=False; DynamicReferenceCombo.Items.Clear;
 if (DynamicList.ItemIndex<0) or (DynamicList.ItemIndex>=FDynamicRows.Count) then Exit;
 Row:=FDynamicRows[DynamicList.ItemIndex]; DynamicMemo.Text:=TDPHDynamicControls.Describe(Row)+sLineBreak+sLineBreak+FDynamic.GetValue<string>('qualification');
 DynamicExplainButton.Enabled:=True;
 for V in Row.GetValue<TJSONArray>('links') do DynamicReferenceCombo.Items.Add(V.GetValue<string>('kind')+' | '+V.GetValue<string>('label')+' ['+V.GetValue<string>('resolution')+']');
 if DynamicReferenceCombo.Items.Count>0 then DynamicReferenceCombo.ItemIndex:=0;
 DynamicReferenceChange(nil);
end;
procedure TDPHMainForm.DynamicReferenceChange(Sender:TObject);
var Links:TJSONArray; Key:string;
begin
 DynamicReferenceButton.Enabled:=False;
 if (FView=nil) or (DynamicList.ItemIndex<0) or (DynamicList.ItemIndex>=FDynamicRows.Count) then Exit;
 Links:=FDynamicRows[DynamicList.ItemIndex].GetValue<TJSONArray>('links');
 if (DynamicReferenceCombo.ItemIndex<0) or (DynamicReferenceCombo.ItemIndex>=Links.Count) then Exit;
 Key:=Links.Items[DynamicReferenceCombo.ItemIndex].GetValue<string>('to','');
 DynamicReferenceButton.Enabled:=(Key<>'') and (FView.Symbol(Key)<>nil);
end;
procedure TDPHMainForm.DynamicExplainClick(Sender:TObject);
var Key:string;
begin
 if (FView=nil) or (DynamicList.ItemIndex<0) or (DynamicList.ItemIndex>=FDynamicRows.Count) then Exit;
 Key:=FDynamicRows[DynamicList.ItemIndex].GetValue<string>('key');
 if Sender=DynamicReferenceButton then begin
  DynamicReferenceChange(nil); if not DynamicReferenceButton.Enabled then Exit;
  Key:=FDynamicRows[DynamicList.ItemIndex].GetValue<TJSONArray>('links').Items[DynamicReferenceCombo.ItemIndex].GetValue<string>('to','');
 end;
 SelectSymbol(Key); WorkspaceTabs.ActiveTab:=ExplainTab;
end;

'''+s[a:];p.write_text(s,encoding='utf-8')
p=r/'DPH.UI.Main.fmx';s=p.read_text(encoding='utf-8-sig');s=s.replace("'Menus and commands'","'Menus and commands'\n'Dynamic controls'",1)
page=s[s.index('object CommandsTab:'):s.index('object KeyboardTab:')].replace('Commands','Dynamic').replace("Text = 'Menus and commands'","Text = 'Dynamic controls'")
a=page.index('object DynamicKindCombo:');b=page.index('object DynamicFilterEdit:',a);page=page[:a]+page[b:]
page=page.replace('Position.X = 176','Position.X = 8').replace("Find command, caption, action or handler","Find creation site, owner, parent or event").replace('Position.X = 434','Position.X = 266').replace('Position.X = 532','Position.X = 364')
a=page.index('object DynamicSourceButton:');b=page.index('object DynamicStatus:',a)
page=page[:a]+'''object DynamicExplainButton: TButton
Position.X = 462
Position.Y = 4
Width = 160
Height = 30
Enabled = False
Text = 'Explain creation site'
OnClick = DynamicExplainClick
end
object DynamicReferenceCombo: TComboBox
Position.X = 630
Position.Y = 4
Width = 360
Height = 30
OnChange = DynamicReferenceChange
end
object DynamicReferenceButton: TButton
Position.X = 998
Position.Y = 4
Width = 150
Height = 30
Enabled = False
Text = 'Explain reference'
OnClick = DynamicExplainClick
end
end
'''+page[b:]
page=page.replace('Captured menu paths, context attachments, toolbar commands and actions. Select a command, then a handler to explain. Runtime dispatch is unobserved.','Source creation sites with owner, parent and event references. Select a site to read evidence. Runtime instances and final state are unobserved.')
s=s.replace('object CommandsTab:',page+'object CommandsTab:',1);p.write_text(s,encoding='utf-8')
p=r/'DelphiProjectHandoff.dproj';s=p.read_text(encoding='utf-8-sig').replace('<DCCReference Include="DPH.Workspace.Commands.pas" />','<DCCReference Include="DPH.Workspace.Commands.pas" />\n      <DCCReference Include="DPH.Workspace.DynamicControls.pas" />');p.write_text(s,encoding='utf-8')
