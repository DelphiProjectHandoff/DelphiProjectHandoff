from pathlib import Path
r=Path.cwd()
keys=['name','owner','department','trigger','inputs','outputs','steps','unknowns']
labels=['Process name','Accountable business owner','Department and participating roles','Trigger and prerequisites','Inputs and their origin','Outputs and their recipients','Ordered steps and handoffs','Unknowns and responsible maintainer']
p=r/'DPH.Workspace.Model.pas';s=p.read_text(encoding='utf-8-sig');s=s.replace('type\n  TDPHWorkspaceView','const DPHBusinessProcessKeys:array[0..7] of string = ('+','.join("'"+x+"'" for x in keys)+');\ntype\n  TDPHWorkspaceView',1)
s=s.replace('    class function NewTargetRecoveryPlan', '''    class function NewBusinessProcess:TJSONObject;static;
    class procedure ValidateBusinessProcess(ARecord:TJSONObject);static;
    class function BusinessProcessBody(ARecord:TJSONObject):string;static;
    class function IsBusinessProcess(ARow:TJSONObject):Boolean;static;
    class function DescribeBusinessProcess(ARow:TJSONObject):string;static;
    class function NewTargetRecoveryPlan''',1)
a=s.index('class function TDPHWorkspaceView.NewTargetRecoveryPlan')
code='''class function TDPHWorkspaceView.NewBusinessProcess:TJSONObject;
var Fields:TJSONObject;Key:string;
begin
 Result:=TJSONObject.Create.AddPair('record_type','business_process').AddPair('process_id',TGUID.NewGuid.ToString);
 Fields:=TJSONObject.Create;Result.AddPair('fields',Fields);
 for Key in DPHBusinessProcessKeys do Fields.AddPair(Key,'Unknown');
end;
class procedure TDPHWorkspaceView.ValidateBusinessProcess(ARecord:TJSONObject);
var Fields:TJSONObject;Pair:TJSONPair;Key:string;ID:TGUID;
begin
 if (ARecord=nil) or (ARecord.Count<>3) or (ARecord.GetValue<string>('record_type','')<>'business_process') then raise EArgumentException.Create('Expected a structured business process');
 if not (ARecord.GetValue('process_id') is TJSONString) or (Length(ARecord.GetValue<string>('process_id',''))<>38) then raise EArgumentException.Create('Invalid process identity');
 try ID:=StringToGUID(ARecord.GetValue<string>('process_id'));except raise EArgumentException.Create('Invalid process identity');end;
 if not ARecord.TryGetValue<TJSONObject>('fields',Fields) or (Fields.Count<>Length(DPHBusinessProcessKeys)) then raise EArgumentException.Create('Process requires its eight structured fields');
 for Pair in Fields do if not (Pair.JsonValue is TJSONString) then raise EArgumentException.Create('Process fields must be text');
 for Key in DPHBusinessProcessKeys do begin
  if Fields.GetValue<string>(Key,'').Trim='' then raise EArgumentException.Create('Complete '+Key+' or explicitly enter Unknown');
  if Length(Fields.GetValue<string>(Key))>4096 then raise EArgumentException.Create('Process field exceeds 4096 characters: '+Key);
 end;
 if SameText(Fields.GetValue<string>('name').Trim,'Unknown') or (Length(Fields.GetValue<string>('name'))>200) then raise EArgumentException.Create('Enter a descriptive process name of at most 200 characters');
end;
class function TDPHWorkspaceView.BusinessProcessBody(ARecord:TJSONObject):string;
const Labels:array[0..7] of string = (LABELS);
var I:Integer;Fields:TJSONObject;
begin
 ValidateBusinessProcess(ARecord);Fields:=ARecord.GetValue<TJSONObject>('fields');
 Result:='BUSINESS PROCESS'+sLineBreak;
 for I:=0 to High(DPHBusinessProcessKeys) do Result:=Result+sLineBreak+Labels[I]+': '+Fields.GetValue<string>(DPHBusinessProcessKeys[I])+sLineBreak;
 Result:=Result+sLineBreak+'Attributed business description; Unknown remains unresolved. Source links identify captured code, not observed execution. Saving and named review do not prove operational outcomes.';
end;
class function TDPHWorkspaceView.IsBusinessProcess(ARow:TJSONObject):Boolean;
var V:TJSONValue;
begin
 Result:=False;if ARow=nil then Exit;
 V:=TJSONObject.ParseJSONValue(ARow.GetValue<string>('structured_json','{}'));
 try if V is TJSONObject then Result:=(ARow.GetValue<string>('kind','')='business_rule') and (V.GetValue<string>('record_type','')='business_process');finally V.Free;end;
end;
class function TDPHWorkspaceView.DescribeBusinessProcess(ARow:TJSONObject):string;
begin
 Result:='No saved process selected. New process opens structured fields. Empty results do not prove the application has no business processes.';
 if not IsBusinessProcess(ARow) then Exit;
 Result:=ARow.GetValue<string>('title')+sLineBreak+'Original contributor: '+ARow.GetValue<string>('owner','unknown')+sLineBreak+
 'Review state: '+ARow.GetValue<string>('state')+' | revision '+ARow.GetValue<string>('revision')+sLineBreak+
 'Reviewer: '+IfThen(ARow.GetValue<string>('reviewer','')='','not supplied',ARow.GetValue<string>('reviewer',''))+sLineBreak+
 'Explicit implementation/evidence links: '+IntToStr(ARow.GetValue<TJSONArray>('rich_links').Count)+sLineBreak+ARow.GetValue<string>('body');
end;

'''.replace('LABELS',','.join("'"+x+"'" for x in labels))
s=s[:a]+code+s[a:];p.write_text(s,encoding='utf-8')
p=r/'DPH.Storage.Database.pas';s=p.read_text(encoding='utf-8-sig');a=s.index("      end else if StructuredValue.GetValue<string>('record_type','')='target_recovery'");b=s.index("      end else if StructuredValue.GetValue<string>('record_type','')='data_quality'",a);block=s[a:b].replace('target_recovery','business_process').replace('ValidateTargetRecoveryRecord','ValidateBusinessProcess').replace('plan_id','process_id').replace('Recovery plan','Business process').replace('recovery plan','business process')
x=block.index('        if SameText');y=block.index("        if (AKind",x);block=block[:x]+"        if ATitle<>StructuredValue.GetValue<string>('fields.name').Trim then raise EDPHStorage.Create('Process title must match its structured name');\n"+block[y:]
x=block.index('        if not ABody.StartsWith');y=block.index("        if (PriorStructured",x);block=block[:x]+"        if ABody<>TDPHWorkspaceView.BusinessProcessBody(StructuredValue as TJSONObject) then raise EDPHStorage.Create('Edit the structured fields on Business processes');\n"+block[y:];s=s[:b]+block+s[b:];p.write_text(s,encoding='utf-8')
p=r/'DPH.UI.Main.pas';s=p.read_text(encoding='utf-8-sig')
def tr(x):
 return x.replace('TargetRecoveryPlan','BusinessProcess').replace('TargetRecovery','BusinessProcess').replace('saved plans','saved processes').replace('New plan','New process').replace('another plan','another process').replace('target-data requirements','business process').replace('recovery plan','business process')
a=s.index('    TargetRecoveryTab:');b=s.index('    DataQualityTab:',a);decl=tr(s[a:b])+'''    BusinessProcessEdit:TButton;
    BusinessProcessEditorTab:TTabItem;
    BusinessProcessEditorPurpose,BusinessProcessAuthorLabel:TLabel;
    BusinessProcessEditorToolbar:TLayout;
    BusinessProcessAuthor:TEdit;
    BusinessProcessApply,BusinessProcessCancel:TButton;
    BusinessProcessEditorScroll:TVertScrollBox;
'''
for key in keys:decl+=f'    Process_{key}_Row:TLayout;\n    Process_{key}_Label:TLabel;\n    Process_{key}:TMemo;\n'
s=s[:b]+decl+s[b:];a=s.index('    procedure TargetRecoveryFilterChange');b=s.index('    procedure DataQualityFilterChange',a);decl=tr(s[a:b])+'''    procedure BusinessProcessEditClick(Sender:TObject);
    procedure BusinessProcessApplyClick(Sender:TObject);
''';s=s[:b]+decl+s[b:];s=s.replace('    FTargetRecoveryRows:', '    FBusinessProcessRows:TList<TJSONObject>;\n    FBusinessProcessOffset:Integer;\n    FTargetRecoveryRows:',1);s=s.replace('FTargetRecoveryRows:=TList<TJSONObject>.Create;', 'FTargetRecoveryRows:=TList<TJSONObject>.Create;FBusinessProcessRows:=TList<TJSONObject>.Create;',1).replace('FTargetRecoveryRows.Free;', 'FBusinessProcessRows.Free;FTargetRecoveryRows.Free;',1);s=s.replace('TargetRecoveryFilterChange(nil);','TargetRecoveryFilterChange(nil);BusinessProcessFilterChange(nil);')
a=s.index('procedure TDPHMainForm.TargetRecoveryFilterChange');b=s.index('procedure TDPHMainForm.DataQualityFilterChange',a);block=tr(s[a:b]);x=block.index('procedure TDPHMainForm.BusinessProcessNewClick');y=block.index('procedure TDPHMainForm.BusinessProcessOpenClick',x);block=block[:x]+'''procedure TDPHMainForm.BusinessProcessNewClick(Sender:TObject);
begin BusinessProcessEditClick(BusinessProcessNew);end;
'''+block[y:];block=block.replace('BusinessProcessOpen.Enabled:=Row<>nil;', 'BusinessProcessEdit.Enabled:=Row<>nil;BusinessProcessOpen.Enabled:=Row<>nil;')
s=s[:b]+block+'''procedure TDPHMainForm.BusinessProcessEditClick(Sender:TObject);
var RecordValue,Fields:TJSONObject;Key:string;
begin
 if FBusy or (FView=nil) then Exit;
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft before editing a process.';Exit;end;
 if Sender=BusinessProcessNew then begin NewKnowledgeClick(nil);RecordValue:=TDPHWorkspaceView.NewBusinessProcess;end
 else begin
  if BusinessProcessList.ItemIndex<0 then Exit;
  BusinessProcessOpenClick(nil);
  RecordValue:=TJSONObject.ParseJSONValue(FKnowledgeStructuredJSON) as TJSONObject;
  if (RecordValue=nil) or (RecordValue.GetValue<string>('record_type','')<>'business_process') then begin RecordValue.Free;Exit;end;
 end;
 try
  FKnowledgeStructuredJSON:=RecordValue.ToJSON;Fields:=RecordValue.GetValue<TJSONObject>('fields');
  for Key in DPHBusinessProcessKeys do (FindComponent('Process_'+Key) as TMemo).Text:=Fields.GetValue<string>(Key,'Unknown');
  Process_name.ReadOnly:=FKnowledgeID<>0;BusinessProcessAuthor.Text:=KnowledgeAuthorEdit.Text;
 finally RecordValue.Free;end;
 FKnowledgeEdited:=True;WorkspaceTabs.ActiveTab:=BusinessProcessEditorTab;
 StatusLabel.Text:='Complete the process fields, enter a named contributor and Apply to Knowledge draft. Then Save, add source links and review.';
end;
procedure TDPHMainForm.BusinessProcessApplyClick(Sender:TObject);
var RecordValue,Fields:TJSONObject;Key:string;
begin
 if FBusy or (FView=nil) or not FKnowledgeEdited then Exit;
 RecordValue:=TJSONObject.ParseJSONValue(FKnowledgeStructuredJSON) as TJSONObject;
 try
  try
   if (RecordValue=nil) or (RecordValue.GetValue<string>('record_type','')<>'business_process') then raise EArgumentException.Create('Start or edit a process first');
   Fields:=RecordValue.GetValue<TJSONObject>('fields');
   for Key in DPHBusinessProcessKeys do begin Fields.RemovePair(Key).Free;Fields.AddPair(Key,(FindComponent('Process_'+Key) as TMemo).Text.Trim);end;
   TDPHWorkspaceView.ValidateBusinessProcess(RecordValue);
   if BusinessProcessAuthor.Text.Trim='' then raise EArgumentException.Create('Enter a named contributor');
   FBinding:=True;
   try
    KnowledgeTitleEdit.Text:=Fields.GetValue<string>('name').Trim;KnowledgeAuthorEdit.Text:=BusinessProcessAuthor.Text.Trim;
    KnowledgeBodyMemo.Text:=TDPHWorkspaceView.BusinessProcessBody(RecordValue);KnowledgeBodyMemo.ReadOnly:=True;KnowledgeTitleEdit.ReadOnly:=True;
    KnowledgeKindCombo.ItemIndex:=KnowledgeKindCombo.Items.IndexOf('business_rule');KnowledgeDocumentCombo.ItemIndex:=KnowledgeDocumentCombo.Items.IndexOf('maintenance');KnowledgeAudienceCombo.ItemIndex:=KnowledgeAudienceCombo.Items.IndexOf('maintainer');
    KnowledgeKindCombo.Enabled:=False;KnowledgeDocumentCombo.Enabled:=False;KnowledgeAudienceCombo.Enabled:=False;
    FKnowledgeStructuredJSON:=RecordValue.ToJSON;FKnowledgeLink:='';FKnowledgeQuestionJSON:='';
   finally FBinding:=False;end;
   WorkspaceTabs.ActiveTab:=KnowledgeTab;StatusLabel.Text:='Process draft prepared. Click Save to persist. Add exact source links on Knowledge links, Save again and review separately.';
  except on E:Exception do StatusLabel.Text:=E.Message;end;
 finally RecordValue.Free;end;
end;

'''+s[b:];p.write_text(s,encoding='utf-8')
p=r/'DPH.UI.Main.fmx';s=p.read_text(encoding='utf-8-sig');a=s.index('object TargetRecoveryTab:');b=s.index('object DataQualityTab:',a);block=tr(s[a:b]).replace("Text = 'Target backup and restore'","Text = 'Business processes'")
x=block.index("Text = 'Record backup");y=block.index('\nend',x);block=block[:x]+"Text = 'Inventory business processes with owners, inputs, outputs and ordered steps. New process and Edit fields open structured editors. Apply, Save, link source evidence and review separately.'"+block[y:]
block=block.replace('Find plan, scope, owner or test','Find process, owner, input or output').replace("Text = 'Open plan'","Text = 'Open record'").replace('Saved recovery plan and review evidence','Saved process and review evidence')
x=block.index('object BusinessProcessLinks:');y=block.index('\nend\nend',x)+4;block=block[:y]+'''\nobject BusinessProcessEdit:TButton
Position.X = 983
Width = 110
Height = 28
Text = 'Edit fields'
OnClick = BusinessProcessEditClick
end'''+block[y:]
editor='''object BusinessProcessEditorTab:TTabItem
Text = 'Process fields'
object BusinessProcessEditorPurpose:TLabel
Align = Top
Height = 64
Margins.Left = 12
Margins.Right = 12
WordWrap = True
Text = 'Describe one selected-application business process. Name is stable after saving. Enter Unknown where evidence is unavailable. Apply prepares a Knowledge draft; Save persists it. Cancel discards the current draft.'
end
object BusinessProcessEditorToolbar:TLayout
Align = Top
Height = 72
object BusinessProcessAuthorLabel:TLabel
Position.X = 12
Width = 200
Height = 24
Text = 'Named contributor'
end
object BusinessProcessAuthor:TEdit
Position.X = 12
Position.Y = 28
Width = 200
Height = 28
end
object BusinessProcessApply:TButton
Position.X = 220
Position.Y = 28
Width = 180
Height = 28
Text = 'Apply to Knowledge draft'
OnClick = BusinessProcessApplyClick
end
object BusinessProcessCancel:TButton
Position.X = 220
Width = 150
Height = 24
Text = 'Cancel / discard draft'
OnClick = DiscardKnowledgeClick
end
end
object BusinessProcessEditorScroll:TVertScrollBox
Align = Client
Margins.Left = 12
Margins.Right = 12
Margins.Bottom = 12
'''
for key,label in zip(keys,labels):
 editor+=f'''object Process_{key}_Row:TLayout
Align = Top
Height = 112
object Process_{key}_Label:TLabel
Align = Top
Height = 26
Text = '{label}'
end
object Process_{key}:TMemo
Align = Client
Margins.Bottom = 8
WordWrap = True
ShowScrollBars = True
end
end
'''
editor+='end\nend\n';s=s[:b]+block+editor+s[b:];s=s.replace("'Target backup and restore'\n","'Target backup and restore'\n'Business processes'\n'Process fields'\n",1);p.write_text(s,encoding='utf-8')
print('Structured business process model, storage validation and native register/editor added.')
