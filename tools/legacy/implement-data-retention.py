from pathlib import Path
r=Path.cwd()
p=r/'DPH.Workspace.Model.pas';s=p.read_text(encoding='utf-8-sig');s=s.replace('    function FileFormats: TJSONObject;', '''    class function NewDataRetentionPolicy:string;static;
    class function IsDataRetentionPolicy(ARow:TJSONObject):Boolean;static;
    class function DescribeDataRetentionPolicy(ARow:TJSONObject):string;static;
    function FileFormats: TJSONObject;''')
code='''class function TDPHWorkspaceView.NewDataRetentionPolicy:string;
begin
 Result:='TARGET DATA RETENTION AND ARCHIVAL POLICY'+sLineBreak+
  'Human-authored requirements for the selected application. Replace Unknown with evidence or explain who must resolve it. Do not enter credentials or customer data.'+sLineBreak+sLineBreak+
  'Policy name and version: Unknown'+sLineBreak+
  'Data categories, tables/files and business scope: Unknown'+sLineBreak+
  'Business or regulatory basis and evidence: Unknown'+sLineBreak+
  'Retention period, units and clock-start event: Unknown'+sLineBreak+
  'Eligibility and expiry calculation, time zone: Unknown'+sLineBreak+
  'Archive trigger, frequency and implementing job/procedure: Unknown'+sLineBreak+
  'Archive destination, format and access permissions: Unknown'+sLineBreak+
  'Deletion/disposal method and implementing job/procedure: Unknown'+sLineBreak+
  'Legal holds, exceptions and override authority: Unknown'+sLineBreak+
  'Policy owner, operator and approval responsibility: Unknown'+sLineBreak+
  'Archive retrieval, restoration and disposal evidence: Unknown'+sLineBreak+
  'Failure handling, monitoring and audit trail: Unknown'+sLineBreak+
  'Verification procedure, test evidence and last review: Unknown'+sLineBreak+
  'Remaining unknowns and responsible maintainer: Unknown'+sLineBreak+sLineBreak+
  'Implementing links: use Knowledge links to attach captured routines, evidence or exact procedure-section revisions; Save the link edits. A written job name alone is not a resolved source link.'+sLineBreak+
  'Qualification: this records target-application policy. DPH snapshot retention is separate. DPH never runs an archive, deletion, SQL statement or target job. Saving or reviewing this record does not establish legal compliance or observed job success.';
end;
class function TDPHWorkspaceView.IsDataRetentionPolicy(ARow:TJSONObject):Boolean;
begin
 Result:=(ARow<>nil) and (ARow.GetValue<string>('kind','')='business_rule') and
  ARow.GetValue<string>('body','').StartsWith('TARGET DATA RETENTION AND ARCHIVAL POLICY'+sLineBreak);
end;
class function TDPHWorkspaceView.DescribeDataRetentionPolicy(ARow:TJSONObject):string;
var Links:TJSONArray;
begin
 Result:='No saved target-data policy selected. New policy prepares an unsaved Knowledge draft. Empty results do not prove that the application has no retention obligations.';
 if not IsDataRetentionPolicy(ARow) then Exit;
 Result:=ARow.GetValue<string>('title')+sLineBreak+'Named contributor: '+ARow.GetValue<string>('owner','unknown')+
  sLineBreak+'Review state: '+ARow.GetValue<string>('state','unknown')+' | revision '+ARow.GetValue<string>('revision','unknown')+
  sLineBreak+'Reviewer: '+ARow.GetValue<string>('reviewer','not supplied')+sLineBreak;
 if ARow.TryGetValue<TJSONArray>('rich_links',Links) then Result:=Result+'Explicit implementation/evidence links: '+IntToStr(Links.Count)+sLineBreak;
 Result:=Result+sLineBreak+ARow.GetValue<string>('body')+sLineBreak+sLineBreak+
  'Open policy to edit, save and review it. Implementation links opens the exact saved links and link editor. Unknown text remains unresolved even when a contributor has reviewed the record. Source links identify captured objects, not successful runtime jobs.';
end;

'''
s=s.replace('class function TDPHWorkspaceView.IsHandoffProject',code+'class function TDPHWorkspaceView.IsHandoffProject',1);p.write_text(s,encoding='utf-8')
p=r/'DPH.UI.Main.pas';s=p.read_text(encoding='utf-8-sig');s=s.replace('    procedure FileFormatsContractClick(Sender:TObject);','''    procedure DataRetentionFilterChange(Sender:TObject);
    procedure DataRetentionSelectionChange(Sender:TObject);
    procedure DataRetentionNewClick(Sender:TObject);
    procedure DataRetentionOpenClick(Sender:TObject);
    procedure FileFormatsContractClick(Sender:TObject);''');s=s.replace('    FileFormatsTab:', '''    DataRetentionTab:TTabItem;
    DataRetentionPurpose,DataRetentionStatus,DataRetentionEvidenceLabel:TLabel;
    DataRetentionToolbar:THorzScrollBox;
    DataRetentionFilter:TEdit;
    DataRetentionState:TComboBox;
    DataRetentionFirst,DataRetentionNext,DataRetentionNew,DataRetentionOpen,DataRetentionLinks:TButton;
    DataRetentionList:TListBox;
    DataRetentionMemo:TMemo;
    FileFormatsTab:''',1)
s=s.replace('    FFileFormatRows:', '''    FDataRetentionRows:TList<TJSONObject>;
    FDataRetentionOffset:Integer;
    FFileFormatRows:''',1)
s=s.replace('  FFileFormatRows:=TList<TJSONObject>.Create;', '  FFileFormatRows:=TList<TJSONObject>.Create;FDataRetentionRows:=TList<TJSONObject>.Create;')
s=s.replace('  FFileFormatRows.Free;','  FDataRetentionRows.Free;FFileFormatRows.Free;',1)
s=s.replace('  NewKnowledgeClick(nil); FExportDirectory:', '  DataRetentionFilterChange(nil);NewKnowledgeClick(nil); FExportDirectory:',1)
s=s.replace('FileFormatsSelectionChange(nil); if FView<>nil', 'FileFormatsSelectionChange(nil);DataRetentionFilterChange(nil); if FView<>nil',1)
code='''procedure TDPHMainForm.DataRetentionFilterChange(Sender:TObject);
var V:TJSONValue;Row:TJSONObject;Count:Integer;Query,StateFilter:string;
begin
 if FDataRetentionRows=nil then Exit;
 if Sender=DataRetentionNext then Inc(FDataRetentionOffset,250) else FDataRetentionOffset:=0;
 FDataRetentionRows.Clear;DataRetentionList.Items.Clear;DataRetentionNext.Enabled:=False;DataRetentionNew.Enabled:=FView<>nil;
 DataRetentionSelectionChange(nil);
 if (FView=nil) or (FKnowledge=nil) then begin DataRetentionStatus.Text:='Open a captured project, then New policy to record its target-data requirements.';Exit;end;
 Query:=DataRetentionFilter.Text.Trim;StateFilter:='';if DataRetentionState.ItemIndex>0 then StateFilter:=DataRetentionState.Selected.Text;Count:=0;
 for V in FKnowledge do begin Row:=V as TJSONObject;
  if not TDPHWorkspaceView.IsDataRetentionPolicy(Row) then Continue;
  if (StateFilter<>'') and (Row.GetValue<string>('state')<>StateFilter) then Continue;
  if (Query<>'') and not ContainsText(TDPHWorkspaceView.DescribeDataRetentionPolicy(Row),Query) then Continue;
  if (Count>=FDataRetentionOffset) and (FDataRetentionRows.Count<250) then begin
   FDataRetentionRows.Add(Row);DataRetentionList.Items.Add('['+Row.GetValue<string>('state')+'] '+Row.GetValue<string>('title')+' | '+Row.GetValue<string>('owner'));
  end;Inc(Count);
 end;
 DataRetentionNext.Enabled:=Count>FDataRetentionOffset+FDataRetentionRows.Count;
 DataRetentionStatus.Text:=IntToStr(Count)+' saved policies match; '+IntToStr(FDataRetentionRows.Count)+' shown from '+IntToStr(FDataRetentionOffset)+'. Review state is a human assessment; unknown fields remain unresolved.';
 if DataRetentionList.Count>0 then DataRetentionList.ItemIndex:=0;
 DataRetentionSelectionChange(nil);
end;
procedure TDPHMainForm.DataRetentionSelectionChange(Sender:TObject);
var Row:TJSONObject;
begin
 Row:=nil;if (FDataRetentionRows<>nil) and (DataRetentionList.ItemIndex>=0) and (DataRetentionList.ItemIndex<FDataRetentionRows.Count) then Row:=FDataRetentionRows[DataRetentionList.ItemIndex];
 DataRetentionOpen.Enabled:=Row<>nil;DataRetentionLinks.Enabled:=Row<>nil;
 DataRetentionMemo.Text:=TDPHWorkspaceView.DescribeDataRetentionPolicy(Row);
end;
procedure TDPHMainForm.DataRetentionNewClick(Sender:TObject);
begin
 if FBusy or (FView=nil) then Exit;
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft before starting a retention policy.';Exit;end;
 NewKnowledgeClick(nil);FBinding:=True;
 try
  FKnowledgeLink:='';KnowledgeTitleEdit.Text:='Retention policy: enter descriptive data scope';
  KnowledgeBodyMemo.Text:=TDPHWorkspaceView.NewDataRetentionPolicy;
  KnowledgeKindCombo.ItemIndex:=KnowledgeKindCombo.Items.IndexOf('business_rule');
  KnowledgeDocumentCombo.ItemIndex:=KnowledgeDocumentCombo.Items.IndexOf('maintenance');
  KnowledgeAudienceCombo.ItemIndex:=KnowledgeAudienceCombo.Items.IndexOf('maintainer');
 finally FBinding:=False;end;
 FKnowledgeEdited:=True;WorkspaceTabs.ActiveTab:=KnowledgeTab;
 StatusLabel.Text:='Enter a descriptive title and named author. Complete the policy fields, preserve the first heading, add implementation links, then Save. Review separately.';
end;
procedure TDPHMainForm.DataRetentionOpenClick(Sender:TObject);
var Row:TJSONObject;ID:string;I:Integer;
begin
 if FBusy or (FView=nil) then Exit;
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft before opening another policy.';Exit;end;
 if (DataRetentionList.ItemIndex<0) or (DataRetentionList.ItemIndex>=FDataRetentionRows.Count) then Exit;
 Row:=FDataRetentionRows[DataRetentionList.ItemIndex];ID:=Row.GetValue<string>('id');
 PendingKnowledgeCheck.IsChecked:=False;KnowledgeFilterChange(nil);
 for I:=0 to FKnowledgeRows.Count-1 do if FKnowledgeRows[I].GetValue<string>('id')=ID then begin
  KnowledgeList.ItemIndex:=I;KnowledgeClick(nil);WorkspaceTabs.ActiveTab:=KnowledgeTab;
  if Sender=DataRetentionLinks then begin WorkspaceTabs.ActiveTab:=KnowledgeLinksTab;StatusLabel.Text:='Select a saved link and Open target, or search a captured routine/procedure and Add link. Return to Knowledge and Save edits.';end;
  Exit;
 end;
end;

'''
s=s.replace('procedure TDPHMainForm.FileFormatsContractClick',code+'procedure TDPHMainForm.FileFormatsContractClick',1);p.write_text(s,encoding='utf-8')
p=r/'DPH.UI.Main.fmx';s=p.read_text(encoding='utf-8-sig').replace("'Import/export formats'\n", "'Import/export formats'\n'Target data retention'\n",1)
fmx="""object DataRetentionTab: TTabItem
Text = 'Target data retention'
object DataRetentionPurpose: TLabel
Align = Top
Height = 64
Margins.Left = 12
Margins.Right = 12
WordWrap = True
Text = 'Record the selected application''s data-retention and archival rules. New policy prepares a named-author Knowledge draft covering periods, archives, disposal, holds, ownership and verification. Link implementing routines or procedures. No target job runs.'
end
object DataRetentionToolbar: THorzScrollBox
Align = Top
Height = 44
ShowScrollBars = True
"""
fmx+="""object DataRetentionState: TComboBox
Position.X = 12
Width = 150
Height = 28
Items.Strings = ('All' 'needs_review' 'verified' 'inferred' 'rejected' 'retired')
ItemIndex = 0
OnChange = DataRetentionFilterChange
end
object DataRetentionFilter: TEdit
Position.X = 170
Width = 230
Height = 28
TextPrompt = 'Find policy, scope, owner or job'
OnChange = DataRetentionFilterChange
end
"""
for name,x,w,label,event in [('First',408,85,'First page','DataRetentionFilterChange'),('Next',501,85,'Next page','DataRetentionFilterChange'),('New',594,105,'New policy','DataRetentionNewClick'),('Open',707,110,'Open policy','DataRetentionOpenClick'),('Links',825,150,'Implementation links','DataRetentionOpenClick')]:
 fmx+=f"object DataRetention{name}: TButton\nPosition.X = {x}\nWidth = {w}\nHeight = 28\nText = '{label}'\nOnClick = {event}\nend\n"
fmx+='''end
object DataRetentionStatus: TLabel
Align = Top
Height = 48
Margins.Left = 12
Margins.Right = 12
WordWrap = True
Text = 'Open a captured project to begin.'
end
object DataRetentionList: TListBox
Align = Top
Height = 56
Margins.Left = 12
Margins.Right = 12
OnChange = DataRetentionSelectionChange
end
object DataRetentionEvidenceLabel: TLabel
Align = Top
Height = 26
Margins.Left = 12
Margins.Right = 12
Text = 'Saved policy, attribution and review state (scroll for details)'
end
object DataRetentionMemo: TMemo
Align = Client
Margins.Left = 12
Margins.Right = 12
Margins.Bottom = 12
ReadOnly = True
WordWrap = True
ShowScrollBars = True
end
end
'''
s=s.replace('object FileFormatsTab: TTabItem',fmx+'object FileFormatsTab: TTabItem',1);p.write_text(s,encoding='utf-8')
print('Implemented native authored target retention policy register without new helper units.')
