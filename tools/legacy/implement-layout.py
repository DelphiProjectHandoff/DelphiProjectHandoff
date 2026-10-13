from pathlib import Path
r=Path.cwd();p=r/'DPH.Workspace.Keyboard.pas';s=p.read_text(encoding='utf-8-sig').replace("'Style','AutoPopup']","'Style','AutoPopup',\n              'Align','Anchors','Left','Top','Width','Height','ClientWidth','ClientHeight','Position.X','Position.Y','Size.Width','Size.Height','AutoSize','AlignWithMargins','WordWrap','Scaled','PixelsPerInch','Scale.X','Scale.Y',\n              'Margins.Left','Margins.Top','Margins.Right','Margins.Bottom','Padding.Left','Padding.Top','Padding.Right','Padding.Bottom','Constraints.MinWidth','Constraints.MaxWidth','Constraints.MinHeight','Constraints.MaxHeight','OnResize','OnCanResize','OnConstrainedResize','OnAlignPosition','OnAlignInsertBefore','WrapMode']");p.write_text(s,encoding='utf-8')
p=r/'DPH.UI.Main.pas';s=p.read_text(encoding='utf-8-sig').replace('    DynamicTab:TTabItem;', '''    LayoutTab:TTabItem;
    LayoutPurpose,LayoutStatus,LayoutWidthLabel,LayoutHeightLabel:TLabel;
    LayoutToolbar:THorzScrollBox;
    LayoutFilterEdit,LayoutWidthEdit,LayoutHeightEdit:TEdit;
    LayoutFirstButton,LayoutNextButton,LayoutSourceButton,LayoutApplyButton:TButton;
    LayoutList:TListBox;
    LayoutSplitter:TSplitter;
    LayoutMemo:TMemo;
    DynamicTab:TTabItem;''').replace('    procedure DynamicFilterChange(Sender:TObject);','''    procedure LayoutFilterChange(Sender:TObject);
    procedure LayoutSelectionClick(Sender:TObject);
    procedure LayoutApplyClick(Sender:TObject);
    procedure LayoutSourceClick(Sender:TObject);
    procedure DynamicFilterChange(Sender:TObject);''').replace('    FDynamic:TJSONObject;','''    FLayout:TJSONObject;
    FLayoutRows:TList<TJSONObject>;
    FLayoutOffset,FLayoutWidthDelta,FLayoutHeightDelta:Integer;
    FDynamic:TJSONObject;''').replace('DPH.Workspace.DynamicControls;','DPH.Workspace.DynamicControls, DPH.Workspace.LayoutRules;').replace('  FDynamicRows:=TList<TJSONObject>.Create;','''  FDynamicRows:=TList<TJSONObject>.Create;
  FLayoutRows:=TList<TJSONObject>.Create;
  TryStrToInt(LayoutWidthEdit.Text,FLayoutWidthDelta);TryStrToInt(LayoutHeightEdit.Text,FLayoutHeightDelta);''').replace('  FDynamicRows.Free; FDynamic.Free;','  FDynamicRows.Free; FDynamic.Free;\n  FLayoutRows.Free; FLayout.Free;').replace('procedure TDPHMainForm.ClearWorkspace;\nbegin','''procedure TDPHMainForm.ClearWorkspace;
begin
 FLayoutRows.Clear;FreeAndNil(FLayout);LayoutList.Items.Clear;LayoutMemo.Text:='Open a project to inspect layout declarations.';LayoutStatus.Text:='No capture loaded.';
 LayoutNextButton.Enabled:=False;LayoutSourceButton.Enabled:=False;''').replace('  FDynamicRows.Clear; FreeAndNil(FDynamic); FDynamic:=','  FLayoutRows.Clear;FreeAndNil(FLayout);FLayout:=TDPHLayoutRules.Inspect(FKeyboard);LayoutFilterChange(nil);\n  FDynamicRows.Clear; FreeAndNil(FDynamic); FDynamic:=')
a=s.index('procedure TDPHMainForm.DynamicFilterChange');s=s[:a]+'''procedure TDPHMainForm.LayoutFilterChange(Sender:TObject);
var V:TJSONValue;Row:TJSONObject;Count:Integer;Query:string;
begin
 if Sender=LayoutNextButton then Inc(FLayoutOffset,250) else FLayoutOffset:=0;
 LayoutList.Items.Clear;FLayoutRows.Clear;LayoutNextButton.Enabled:=False;LayoutSourceButton.Enabled:=False;
 LayoutMemo.Text:='Select a component to read its layout declarations.';if FLayout=nil then Exit;
 Query:=LayoutFilterEdit.Text.Trim;Count:=0;
 for V in FLayout.GetValue<TJSONArray>('rows') do begin Row:=V as TJSONObject;
  if (Query<>'') and not ContainsText(TDPHLayoutRules.Describe(Row,FLayoutWidthDelta,FLayoutHeightDelta),Query) then Continue;
  if (Count>=FLayoutOffset) and (FLayoutRows.Count<250) then begin FLayoutRows.Add(Row);LayoutList.Items.Add(Row.GetValue<string>('form')+' / '+Row.GetValue<string>('parent')+' / '+Row.GetValue<string>('name')+' : '+Row.GetValue<string>('class'));end;Inc(Count);
 end;
 LayoutNextButton.Enabled:=Count>FLayoutOffset+FLayoutRows.Count;
 LayoutStatus.Text:=IntToStr(Count)+' matching components; showing '+IntToStr(FLayoutRows.Count)+' from offset '+IntToStr(FLayoutOffset)+'. Examples do not evaluate the target layout engine.';
 if LayoutList.Count>0 then begin LayoutList.ItemIndex:=0;LayoutSelectionClick(nil);end else LayoutMemo.Text:='No matching component. Clear the filter or inspect Coverage for uncaptured forms.';
end;
procedure TDPHMainForm.LayoutSelectionClick(Sender:TObject);
begin
 LayoutSourceButton.Enabled:=False;
 if (LayoutList.ItemIndex<0) or (LayoutList.ItemIndex>=FLayoutRows.Count) then Exit;
 LayoutMemo.Text:=TDPHLayoutRules.Describe(FLayoutRows[LayoutList.ItemIndex],FLayoutWidthDelta,FLayoutHeightDelta)+sLineBreak+sLineBreak+FLayout.GetValue<string>('qualification');LayoutSourceButton.Enabled:=True;
end;
procedure TDPHMainForm.LayoutApplyClick(Sender:TObject);
var W,H:Integer;
begin
 if not TryStrToInt(LayoutWidthEdit.Text.Trim,W) or not TryStrToInt(LayoutHeightEdit.Text.Trim,H) or (Abs(Int64(W))>10000) or (Abs(Int64(H))>10000) then begin LayoutStatus.Text:='Enter whole width and height changes from -10000 to 10000. The previous example remains active.';Exit;end;
 FLayoutWidthDelta:=W;FLayoutHeightDelta:=H;LayoutSelectionClick(nil);
 LayoutStatus.Text:='Educational parent change applied: width '+IntToStr(W)+', height '+IntToStr(H)+' units. Target source and form geometry are unchanged.';
end;
procedure TDPHMainForm.LayoutSourceClick(Sender:TObject);
var Row,Range:TJSONObject;
begin
 if (FView=nil) or (LayoutList.ItemIndex<0) or (LayoutList.ItemIndex>=FLayoutRows.Count) then Exit;
 Row:=FLayoutRows[LayoutList.ItemIndex];Range:=Row.GetValue<TJSONObject>('range');
 if FDetached then begin LayoutMemo.Lines.Add('Source is detached. Attach unchanged source to navigate.');Exit;end;
 try SourceMemo.Text:=TDPHKeyboardInspector.ReadSource(FView,FEntry,Row,Range);SourceMemo.CaretPosition:=TCaretPosition.Create(Max(0,Range.GetValue<Integer>('line')-1),Max(0,Range.GetValue<Integer>('column')-1));WorkspaceTabs.ActiveTab:=SourceTab;
 except on E:Exception do LayoutMemo.Lines.Add('Source unavailable: '+E.Message);end;
end;

'''+s[a:];p.write_text(s,encoding='utf-8')
p=r/'DPH.UI.Main.fmx';s=p.read_text(encoding='utf-8-sig').replace("'Dynamic controls'","'Dynamic controls'\n'Layout rules'",1)
page=s[s.index('object DynamicTab:'):s.index('object CommandsTab:')].replace('Dynamic','Layout').replace("Text = 'Layout controls'","Text = 'Layout rules'")
a=page.index('object LayoutExplainButton:');b=page.index('object LayoutStatus:',a)
page=page[:a]+'''object LayoutSourceButton: TButton
Position.X = 462
Position.Y = 4
Width = 150
Height = 30
Enabled = False
Text = 'Component source'
OnClick = LayoutSourceClick
end
object LayoutWidthLabel: TLabel
Position.X = 620
Position.Y = 4
Width = 135
Height = 30
Text = 'Parent width change'
end
object LayoutWidthEdit: TEdit
Position.X = 760
Position.Y = 4
Width = 80
Height = 30
Text = '120'
end
object LayoutHeightLabel: TLabel
Position.X = 848
Position.Y = 4
Width = 135
Height = 30
Text = 'Parent height change'
end
object LayoutHeightEdit: TEdit
Position.X = 988
Position.Y = 4
Width = 80
Height = 30
Text = '80'
end
object LayoutApplyButton: TButton
Position.X = 1076
Position.Y = 4
Width = 145
Height = 30
Text = 'Apply example'
OnClick = LayoutApplyClick
end
end
'''+page[b:];page=page.replace('Source creation sites with owner, parent and event references. Select a site to read evidence. Runtime instances and final state are unobserved.','Captured layout rules with alignment, anchors and spacing explanations. Resize examples are educational; target runtime geometry is unobserved.').replace('Find creation site, owner, parent or event','Find component, alignment, anchors or rule').replace('OnClick = LayoutSelectionClick','OnChange = LayoutSelectionClick')
s=s.replace('object DynamicTab:',page+'object DynamicTab:',1);p.write_text(s,encoding='utf-8')
p=r/'DelphiProjectHandoff.dproj';s=p.read_text(encoding='utf-8-sig').replace('<DCCReference Include="DPH.Workspace.DynamicControls.pas" />','<DCCReference Include="DPH.Workspace.DynamicControls.pas" />\n      <DCCReference Include="DPH.Workspace.LayoutRules.pas" />');p.write_text(s,encoding='utf-8')
