from pathlib import Path
root=Path(__file__).resolve().parents[2];p=root/'DPH.UI.Main.pas';raw=p.read_bytes();text=raw.decode('utf-8-sig').replace('\r\n','\n')
start=text.index('  FDatabaseSchemaRows.Clear;FreeAndNil(FDatabaseSchema);FDatabaseSchema:=',text.index('procedure TDPHMainForm.LoadView'))
end=text.index("  InspectorMemo.Text:='';",start)
reset='''  FDatabaseSchemaRows.Clear;FreeAndNil(FDatabaseSchema);DatabaseSchemaFilterChange(nil);FreeAndNil(FDatabaseER);
  FCalculationEvidenceRows.Clear;FreeAndNil(FCalculationEvidence);CalculationEvidenceFilterChange(nil);
  FFileFormatRows.Clear;FreeAndNil(FFileFormats);FileFormatsFilterChange(nil);
  FDatabaseInventoryRows.Clear;FreeAndNil(FDatabaseInventory);DatabaseInventoryFilterChange(nil);
  FKeyboardRows.Clear;FreeAndNil(FKeyboard);KeyboardFilterChange(nil);
  FCommandRows.Clear;FreeAndNil(FCommands);CommandsFilterChange(nil);
  FActionPurposeRows.Clear;FreeAndNil(FActionPurposes);ActionPurposeFilterChange(nil);
  FInheritanceRows.Clear;FInheritanceOrigins.Clear;FreeAndNil(FInheritance);InheritanceFilterChange(nil);
  FDependencyRows.Clear;FreeAndNil(FDependencies);DependencyFilterChange(nil);
  FLayoutRows.Clear;FreeAndNil(FLayout);LayoutFilterChange(nil);
  FDynamicRows.Clear;FreeAndNil(FDynamic);DynamicFilterChange(nil);
  FreeAndNil(FProjectMembers);ProjectMembersList.Items.Clear;ProjectMemberMemo.Text:='';
'''
text=text[:start]+reset+text[end:]
start=text.index('procedure TDPHMainForm.WorkspacePageChange');end=text.index('procedure TDPHMainForm.ProjectSearchClick',start);block=text[start:end]
block=block.replace('Choice: TComboBox;','Choice: TComboBox; V:TJSONValue;',1)
point=block.rfind('end;')
initialize='''  if FView<>nil then begin
    if ((WorkspaceTabs.ActiveTab=ActionPurposeTab) or (WorkspaceTabs.ActiveTab=KeyboardTab) or
      (WorkspaceTabs.ActiveTab=CommandsTab) or (WorkspaceTabs.ActiveTab=DependencyTab) or
      (WorkspaceTabs.ActiveTab=LayoutTab)) and (FKeyboard=nil) then FKeyboard:=TDPHKeyboardInspector.Inspect(FView);
    if (WorkspaceTabs.ActiveTab=ActionPurposeTab) and (FActionPurposes=nil) then begin FActionPurposes:=TDPHActionPurposes.Inspect(FView,FKeyboard,FKnowledge);ActionPurposeFilterChange(nil);end;
    if WorkspaceTabs.ActiveTab=KeyboardTab then KeyboardFilterChange(nil);
    if (WorkspaceTabs.ActiveTab=CommandsTab) and (FCommands=nil) then begin FCommands:=TDPHCommandInventory.Inspect(FView,FKeyboard);CommandsFilterChange(nil);end;
    if (WorkspaceTabs.ActiveTab=DependencyTab) and (FDependencies=nil) then begin FDependencies:=TDPHComponentDependencies.Inspect(FView,FKeyboard);DependencyFilterChange(nil);end;
    if (WorkspaceTabs.ActiveTab=LayoutTab) and (FLayout=nil) then begin FLayout:=TDPHLayoutRules.Inspect(FKeyboard);LayoutFilterChange(nil);end;
    if (WorkspaceTabs.ActiveTab=InheritanceTab) and (FInheritance=nil) then begin FInheritance:=TDPHFormInheritance.Inspect(FView);InheritanceFilterChange(nil);end;
    if (WorkspaceTabs.ActiveTab=DynamicTab) and (FDynamic=nil) then begin FDynamic:=TDPHDynamicControls.Inspect(FView);DynamicFilterChange(nil);end;
    if ((WorkspaceTabs.ActiveTab=DatabaseSchemaTab) or (WorkspaceTabs.ActiveTab=DatabaseERTab)) and (FDatabaseSchema=nil) then begin FDatabaseSchema:=TDPHDatabaseSchema.Inspect(FView);DatabaseSchemaFilterChange(nil);end;
    if WorkspaceTabs.ActiveTab=DatabaseERTab then DatabaseERFilterChange(nil);
    if (WorkspaceTabs.ActiveTab=DatabaseInventoryTab) and (FDatabaseInventory=nil) then begin FDatabaseInventory:=TDPHDatabaseConnections.Inspect(FView);DatabaseInventoryFilterChange(nil);end;
    if (WorkspaceTabs.ActiveTab=CalculationEvidenceTab) and (FCalculationEvidence=nil) then begin FCalculationEvidence:=FView.Calculations;CalculationEvidenceFilterChange(nil);end;
    if (WorkspaceTabs.ActiveTab=FileFormatsTab) and (FFileFormats=nil) then begin FFileFormats:=FView.FileFormats;FileFormatsFilterChange(nil);end;
    if (WorkspaceTabs.ActiveTab=ProjectsTab) and (FProjectMembers=nil) then begin
      FProjectMembers:=FView.ProjectMembers;for V in FProjectMembers do ProjectMembersList.Items.Add(V.GetValue<string>('name'));end;
    if WorkspaceTabs.ActiveTab=QuestionsTab then RefreshQuestions;
    if WorkspaceTabs.ActiveTab=CoverageTab then RefreshCoverage;
    if WorkspaceTabs.ActiveTab=QualityTab then QualityClick(nil);
    if (WorkspaceTabs.ActiveTab=GraphTab) or (WorkspaceTabs.ActiveTab=ScreenTab) then RefreshGraphics;
  end;
'''
block=block[:point]+initialize+block[point:];text=text[:start]+block+text[end:]
old='if FView<>nil then begin FActionPurposeRows.Clear;FreeAndNil(FActionPurposes);FActionPurposes:=TDPHActionPurposes.Inspect(FView,FKeyboard,FKnowledge);ActionPurposeFilterChange(nil);end; end;'
new='FActionPurposeRows.Clear;FreeAndNil(FActionPurposes);ActionPurposeFilterChange(nil);if (FView<>nil) and (WorkspaceTabs.ActiveTab=ActionPurposeTab) then WorkspacePageChange(nil);end;'
assert old in text;text=text.replace(old,new,1)
text=text.replace('  FlowBrowser.Visible:=False;GraphPaint.Height:=4500;', '  FlowBrowser.Visible:=False;\n  if (WorkspaceTabs.ActiveTab<>GraphTab) and (WorkspaceTabs.ActiveTab<>ScreenTab) then Exit;\n  GraphPaint.Height:=4500;',1)
text=text.replace("  else if IsLineage then begin\n", "  else if IsLineage then begin\n   if FDatabaseInventory=nil then FDatabaseInventory:=TDPHDatabaseConnections.Inspect(FView);\n",1)
text=text.replace("  FPendingCommand:=Request.Command; FBusy:=True; StatusLabel.Text:='Checking selected project;", "  FPendingCommand:=Request.Command; FBusy:=True;WorkspaceTabs.Enabled:=False; StatusLabel.Text:='Checking selected project;",1)
text=text.replace('    FBusy:=R.Busy;','    FBusy:=R.Busy;if not R.Busy then WorkspaceTabs.Enabled:=True;',1)
p.write_bytes((b'\xef\xbb\xbf' if raw.startswith(b'\xef\xbb\xbf') else b'')+text.replace('\n','\r\n').encode('utf-8'))
