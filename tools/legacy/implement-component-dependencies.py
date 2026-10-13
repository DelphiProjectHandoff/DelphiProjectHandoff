from pathlib import Path
r=Path.cwd()
keys=['class_name','unit_name','package_name','vendor','version','support','evidence']
labels=['Component class identity','Declaring unit','Package or product','Vendor or maintainer','Version and configuration','Support and replacement considerations','Evidence references and remaining unknowns']
source=(r/'DPH.UI.ProjectProfile.pas').read_text(encoding='utf-8-sig')
start=source.index('    Profile_purpose_Row:');end=source.index('    procedure ApplyProfileClick',start)
source=source[:start]+''.join(f'    Profile_{k}_Row: TLayout;\n    Profile_{k}_Label: TLabel;\n    Profile_{k}: TMemo;\n' for k in keys)+source[end:]
source=source.replace('DPH.UI.ProjectProfile','DPH.UI.ComponentDependency').replace('DPH.Knowledge.ProjectProfile','DPH.Knowledge.ComponentDependency').replace('TDPHProjectProfile','TDPHComponentDependency').replace('DPHProjectProfileFieldCount-1','High(DPHComponentDependencyKeys)').replace('DPHProjectProfileKeys','DPHComponentDependencyKeys').replace("'project_profile'","'component_dependency'")
source=source.replace('  ProfileAuthorEdit.Text:=AAuthor; Fields:=nil;', '  ProfileAuthorEdit.Text:=AAuthor; Profile_class_name.ReadOnly:=True; Fields:=nil;')
(r/'DPH.UI.ComponentDependency.pas').write_text(source,encoding='utf-8')
fmx=(r/'DPH.UI.ProjectProfile.fmx').read_text(encoding='utf-8-sig');fmx=fmx[:fmx.index('    object Profile_purpose_Row:')]
fmx=fmx.replace('TDPHProjectProfileForm','TDPHComponentDependencyForm').replace("Caption = 'Selected application profile'","Caption = 'Component dependency record'")
fmx=fmx.replace('Describe only the selected application. Purpose and attribution are required. Blank optional fields stay explicitly unknown. Apply creates a Knowledge draft; use Save there, then review with a named reviewer. Do not enter credentials.','Document this component class for the selected application. Evidence and a named contributor are required. Blank package, vendor, version and support fields remain unknown. Apply creates a Knowledge draft; click Save there, then review explicitly. Do not enter credentials.')
for i,(key,label) in enumerate(zip(keys,labels)):
 fmx+=f'''    object Profile_{key}_Row: TLayout
      Position.Y = {i*122}
      Width = 780
      Height = 122
      Anchors = [akLeft, akTop, akRight]
      object Profile_{key}_Label: TLabel
        Align = Top
        Height = 28
        Margins.Left = 12
        Text = '{label}'
      end
      object Profile_{key}: TMemo
        Align = Client
        Margins.Left = 12
        Margins.Right = 12
        Margins.Bottom = 10
        WordWrap = True
        ShowScrollBars = True
        StyledSettings = []
        TextSettings.Font.Size = 16
      end
    end
'''
fmx+='  end\nend\n';(r/'DPH.UI.ComponentDependency.fmx').write_text(fmx,encoding='utf-8')
p=r/'DPH.UI.Main.fmx';s=p.read_text(encoding='utf-8-sig').replace("'Layout rules'","'Layout rules'\n'Component dependencies'",1)
start=s.index('object LayoutTab:');end=s.index('object DynamicTab:',start);page=s[start:end]
page=page.replace('Layout','Dependency').replace("Text = 'Dependency rules'","Text = 'Component dependencies'")
page=page.replace('Captured layout rules with alignment, anchors and spacing explanations. Resize examples are educational; target runtime geometry is unobserved.','Captured component classes and unresolved dependencies, with attributed package, vendor, version and support records. No vendor classes are loaded.')
start=page.index('object DependencyWidthLabel:');end=page.index('object DependencyStatus:',start)
page=page[:start]+'''object DependencyEditButton: TButton
Position.X = 620
Position.Y = 4
Width = 150
Height = 30
Text = 'Edit dependency'
Enabled = False
OnClick = DependencyEditClick
end
object DependencyKnowledgeButton: TButton
Position.X = 778
Position.Y = 4
Width = 160
Height = 30
Text = 'Open in Knowledge'
Enabled = False
OnClick = DependencyKnowledgeClick
end
end
'''+page[end:]
page=page.replace('Find component, alignment, anchors or rule','Find class, resolution, vendor or support')
s=s[:s.index('object DynamicTab:')]+page+s[s.index('object DynamicTab:'):];p.write_text(s,encoding='utf-8')
p=r/'DPH.UI.Main.pas';s=p.read_text(encoding='utf-8-sig')
s=s.replace('    LayoutTab:TTabItem;','''    DependencyTab:TTabItem;
    DependencyPurpose,DependencyStatus:TLabel;
    DependencyToolbar:THorzScrollBox;
    DependencyFilterEdit:TEdit;
    DependencyFirstButton,DependencyNextButton,DependencySourceButton,DependencyEditButton,DependencyKnowledgeButton:TButton;
    DependencyList:TListBox;
    DependencySplitter:TSplitter;
    DependencyMemo:TMemo;
    LayoutTab:TTabItem;''',1)
s=s.replace('    procedure LayoutFilterChange(Sender:TObject);','''    procedure DependencyFilterChange(Sender:TObject);
    procedure DependencySelectionClick(Sender:TObject);
    procedure DependencySourceClick(Sender:TObject);
    procedure DependencyEditClick(Sender:TObject);
    procedure DependencyKnowledgeClick(Sender:TObject);
    procedure LayoutFilterChange(Sender:TObject);''',1)
s=s.replace('    FLayout:TJSONObject;','''    FDependencies:TJSONObject;
    FDependencyRows:TList<TJSONObject>;
    FDependencyOffset:Integer;
    FLayout:TJSONObject;''',1)
s=s.replace('DPH.Workspace.LayoutRules;', 'DPH.Workspace.LayoutRules, DPH.Workspace.ComponentDependencies, DPH.Knowledge.ComponentDependency, DPH.UI.ComponentDependency;',1)
s=s.replace('  FLayoutRows:=TList<TJSONObject>.Create;', '  FDependencyRows:=TList<TJSONObject>.Create;\n  FLayoutRows:=TList<TJSONObject>.Create;',1)
s=s.replace('  FLayoutRows.Free; FLayout.Free;', '  FDependencyRows.Free; FDependencies.Free;\n  FLayoutRows.Free; FLayout.Free;',1)
s=s.replace('procedure TDPHMainForm.ClearWorkspace;\nbegin','''procedure TDPHMainForm.ClearWorkspace;
begin
 FDependencyRows.Clear;FreeAndNil(FDependencies);DependencyList.Items.Clear;DependencyMemo.Text:='Open a project to inspect component dependencies.';DependencyStatus.Text:='No capture loaded.';
 DependencyNextButton.Enabled:=False;DependencySourceButton.Enabled:=False;DependencyEditButton.Enabled:=False;DependencyKnowledgeButton.Enabled:=False;''',1)
s=s.replace('  FLayoutRows.Clear;FreeAndNil(FLayout);FLayout:=', '  FDependencyRows.Clear;FreeAndNil(FDependencies);FDependencies:=TDPHComponentDependencies.Inspect(FView,FKeyboard);DependencyFilterChange(nil);\n  FLayoutRows.Clear;FreeAndNil(FLayout);FLayout:=',1)
s=s.replace('RefreshQuestions; end;','RefreshQuestions; DependencyFilterChange(nil); end;',1)
code='''procedure TDPHMainForm.DependencyFilterChange(Sender:TObject);
var V:TJSONValue;Row:TJSONObject;Count:Integer;Query:string;
begin
 if FDependencyRows=nil then Exit;
 if Sender=DependencyNextButton then Inc(FDependencyOffset,250) else FDependencyOffset:=0;
 DependencyList.Items.Clear;FDependencyRows.Clear;DependencyNextButton.Enabled:=False;DependencySourceButton.Enabled:=False;DependencyEditButton.Enabled:=False;DependencyKnowledgeButton.Enabled:=False;
 DependencyMemo.Text:='Select a component to inspect captured class evidence and authored dependency information.';if FDependencies=nil then Exit;
 Query:=DependencyFilterEdit.Text.Trim;Count:=0;
 for V in FDependencies.GetValue<TJSONArray>('rows') do begin Row:=V as TJSONObject;
  if (Query<>'') and not ContainsText(TDPHComponentDependencies.Describe(Row,FKnowledge),Query) then Continue;
  if (Count>=FDependencyOffset) and (FDependencyRows.Count<250) then begin FDependencyRows.Add(Row);DependencyList.Items.Add(Row.GetValue<string>('form')+' / '+Row.GetValue<string>('name')+' : '+Row.GetValue<string>('class')+' | '+Row.GetValue<string>('resolution'));end;Inc(Count);
 end;
 DependencyNextButton.Enabled:=Count>FDependencyOffset+FDependencyRows.Count;
 DependencyStatus.Text:=IntToStr(Count)+' matching components; showing '+IntToStr(FDependencyRows.Count)+' from offset '+IntToStr(FDependencyOffset)+'. Vendor and runtime support require attributed evidence.';
 if DependencyList.Count>0 then begin DependencyList.ItemIndex:=0;DependencySelectionClick(nil);end else DependencyMemo.Text:='No matching components. Clear the filter or inspect Coverage for uncaptured forms.';
end;
procedure TDPHMainForm.DependencySelectionClick(Sender:TObject);
var V:TJSONValue;Row:TJSONObject;
begin
 DependencySourceButton.Enabled:=False;DependencyEditButton.Enabled:=False;DependencyKnowledgeButton.Enabled:=False;
 if (DependencyList.ItemIndex<0) or (DependencyList.ItemIndex>=FDependencyRows.Count) then Exit;
 Row:=FDependencyRows[DependencyList.ItemIndex];DependencyMemo.Text:=TDPHComponentDependencies.Describe(Row,FKnowledge)+sLineBreak+sLineBreak+FDependencies.GetValue<string>('qualification');
 DependencyMemo.Lines.Add('CAPTURED PACKAGE DECLARATIONS (not component membership)');
 for V in FDependencies.GetValue<TJSONArray>('packages') do DependencyMemo.Lines.Add(V.GetValue<string>('name')+' | '+V.GetValue<string>('source')+' | SHA-256 '+V.GetValue<string>('source_hash'));
 DependencyMemo.Lines.Add('UNAVAILABLE INPUTS (project-wide; not automatically attributed to this class)');
 for V in FDependencies.GetValue<TJSONArray>('unavailable_inputs') do DependencyMemo.Lines.Add(V.GetValue<string>('source')+' | '+V.GetValue<string>('availability'));
 DependencySourceButton.Enabled:=True;DependencyEditButton.Enabled:=True;DependencyKnowledgeButton.Enabled:=TDPHComponentDependencies.FindRecord(FKnowledge,Row.GetValue<string>('class'))<>nil;
end;
procedure TDPHMainForm.DependencySourceClick(Sender:TObject);
var Row,Range:TJSONObject;
begin
 if (FView=nil) or (DependencyList.ItemIndex<0) or (DependencyList.ItemIndex>=FDependencyRows.Count) then Exit;
 Row:=FDependencyRows[DependencyList.ItemIndex];Range:=Row.GetValue<TJSONObject>('range');
 if FDetached then begin DependencyMemo.Lines.Add('Source is detached. Attach unchanged source to navigate.');Exit;end;
 try SourceMemo.Text:=TDPHKeyboardInspector.ReadSource(FView,FEntry,Row,Range);SourceMemo.CaretPosition:=TCaretPosition.Create(Max(0,Range.GetValue<Integer>('line')-1),Max(0,Range.GetValue<Integer>('column')-1));WorkspaceTabs.ActiveTab:=SourceTab;
 except on E:Exception do DependencyMemo.Lines.Add('Source unavailable: '+E.Message);end;
end;
procedure TDPHMainForm.DependencyKnowledgeClick(Sender:TObject);
var Row:TJSONObject;I:Integer;
begin
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft first';Exit;end;
 if (DependencyList.ItemIndex<0) or (DependencyList.ItemIndex>=FDependencyRows.Count) then Exit;
 Row:=TDPHComponentDependencies.FindRecord(FKnowledge,FDependencyRows[DependencyList.ItemIndex].GetValue<string>('class'));if Row=nil then Exit;
 PendingKnowledgeCheck.IsChecked:=False;KnowledgeFilterChange(nil);
 for I:=0 to FKnowledgeRows.Count-1 do if FKnowledgeRows[I].GetValue<string>('id')=Row.GetValue<string>('id') then begin KnowledgeList.ItemIndex:=I;KnowledgeClick(nil);WorkspaceTabs.ActiveTab:=KnowledgeTab;Exit;end;
end;
procedure TDPHMainForm.DependencyEditClick(Sender:TObject);
var Editor:TDPHComponentDependencyForm;Row,ComponentRow,RecordValue,Initial:TJSONObject;Links:TJSONArray;
begin
 if FBusy or (FView=nil) then Exit;
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft first';Exit;end;
 if (DependencyList.ItemIndex<0) or (DependencyList.ItemIndex>=FDependencyRows.Count) then Exit;
 ComponentRow:=FDependencyRows[DependencyList.ItemIndex];Row:=TDPHComponentDependencies.FindRecord(FKnowledge,ComponentRow.GetValue<string>('class'));
 if Row<>nil then Initial:=TJSONObject.ParseJSONValue(Row.GetValue<string>('structured_json')) as TJSONObject
 else Initial:=TJSONObject.Create.AddPair('record_type','component_dependency').AddPair('fields',TJSONObject.Create.AddPair('class_name',ComponentRow.GetValue<string>('class')));
 Editor:=TDPHComponentDependencyForm.Create(nil);
 try
  Editor.LoadRecord(Initial,KnowledgeAuthorEdit.Text);if Editor.ShowModal<>mrOk then Exit;
  RecordValue:=Editor.RecordJSON;
  try
   FBinding:=True;
   try
    FKnowledgeID:=0;FKnowledgeRevision:=0;if Row<>nil then begin FKnowledgeID:=StrToInt64(Row.GetValue<string>('id'));FKnowledgeRevision:=StrToInt64(Row.GetValue<string>('revision'));end;
    KnowledgeTitleEdit.Text:=TDPHComponentDependency.Title(RecordValue);KnowledgeAuthorEdit.Text:=Editor.ProfileAuthorEdit.Text;
    KnowledgeKindCombo.ItemIndex:=KnowledgeKindCombo.Items.IndexOf('engineering_rule');KnowledgeDocumentCombo.ItemIndex:=KnowledgeDocumentCombo.Items.IndexOf('engineering');KnowledgeAudienceCombo.ItemIndex:=KnowledgeAudienceCombo.Items.IndexOf('engineer');
    KnowledgeBodyMemo.Text:=TDPHComponentDependency.Body(RecordValue);KnowledgeBodyMemo.ReadOnly:=True;KnowledgeTitleEdit.ReadOnly:=True;KnowledgeKindCombo.Enabled:=False;KnowledgeDocumentCombo.Enabled:=False;KnowledgeAudienceCombo.Enabled:=False;
    FKnowledgeStructuredJSON:=RecordValue.ToJSON;FKnowledgeQuestionJSON:='';FKnowledgeLink:='';FreeAndNil(FEditableLinks);
    if (Row<>nil) and Row.TryGetValue<TJSONArray>('rich_links',Links) then FEditableLinks:=Links.Clone as TJSONArray else FEditableLinks:=TJSONArray.Create;
    RefreshKnowledgeLinks;FKnowledgeEdited:=True;KnowledgeSectionLabel.Text:='Component dependency draft: click Save, then review explicitly';KnowledgeHistoryMemo.Text:='Edit structured fields on Component dependencies. Use Knowledge links for exact evidence. Saving does not resolve class source or verify vendor claims.';
   finally FBinding:=False;end;
   WorkspaceTabs.ActiveTab:=KnowledgeTab;StatusLabel.Text:='Dependency draft prepared. Click Save to persist; review requires a named reviewer.';
  finally RecordValue.Free;end;
 finally Editor.Free;Initial.Free;end;
end;

'''
s=s.replace('procedure TDPHMainForm.LayoutFilterChange(Sender:TObject);',code+'procedure TDPHMainForm.LayoutFilterChange(Sender:TObject);',1);p.write_text(s,encoding='utf-8')
p=r/'DelphiProjectHandoff.dproj';s=p.read_text(encoding='utf-8-sig').replace('      <DCCReference Include="DPH.Workspace.LayoutRules.pas" />','''      <DCCReference Include="DPH.Workspace.LayoutRules.pas" />
      <DCCReference Include="DPH.Workspace.ComponentDependencies.pas" />
      <DCCReference Include="DPH.Knowledge.ComponentDependency.pas" />
      <DCCReference Include="DPH.UI.ComponentDependency.pas"><Form>DPHComponentDependencyForm</Form><FormType>fmx</FormType></DCCReference>''');p.write_text(s,encoding='utf-8')
p=r/'DPH.Storage.Database.pas';s=p.read_text(encoding='utf-8-sig').replace('DPH.Knowledge.ProjectProfile, DPH.Knowledge.Glossary;','DPH.Knowledge.ProjectProfile, DPH.Knowledge.Glossary, DPH.Knowledge.ComponentDependency;',1)
needle='      end else begin\n      TDPHProjectProfile.Validate(StructuredValue as TJSONObject);'
assert needle in s
s=s.replace(needle,'''      end else if StructuredValue.GetValue<string>('record_type','')='component_dependency' then begin
        TDPHComponentDependency.Validate(StructuredValue as TJSONObject);
        if (ATitle<>TDPHComponentDependency.Title(StructuredValue as TJSONObject)) or (AKind<>'engineering_rule') or (DocumentKind<>'engineering') or (Audience<>'engineer') or (AEntityKey<>'') then raise EDPHStorage.Create('Component dependency identity and engineering scope must be preserved');
        if ABody<>TDPHComponentDependency.Body(StructuredValue as TJSONObject) then raise EDPHStorage.Create('Edit dependency fields on Component dependencies');
        if (PriorStructured<>'') and (PriorStructured<>'{}') then begin
          PriorRecord:=TJSONObject.ParseJSONValue(PriorStructured);
          try if PriorRecord.GetValue<string>('fields.class_name','')<>StructuredValue.GetValue<string>('fields.class_name','') then raise EDPHStorage.Create('Component class identity cannot change');finally PriorRecord.Free;end;
        end;
        if Scalar('SELECT count(*) FROM knowledge_records k JOIN knowledge_revisions r ON r.knowledge_revision_id=k.current_revision_id WHERE k.project_id=1 AND k.knowledge_id<>:id AND json_extract(r.structured_json,''$.record_type'')=''component_dependency'' AND lower(json_extract(r.structured_json,''$.fields.class_name''))=lower(:class)',[AKnowledgeID,StructuredValue.GetValue<string>('fields.class_name')])<>0 then raise EDPHStorage.Create('A dependency record already exists for this class; refresh and edit it. Retired identities remain reserved.');
      end else begin
      TDPHProjectProfile.Validate(StructuredValue as TJSONObject);''',1);p.write_text(s,encoding='utf-8')
