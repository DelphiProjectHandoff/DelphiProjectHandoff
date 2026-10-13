from pathlib import Path
r=Path.cwd();keys=['name','owner','scope','trigger','unknowns'];labels=['Workflow name','Accountable workflow owner','Departments and business scope','Trigger and prerequisites','Unknowns and responsible maintainer']
stepkeys=['step_id','department','role','action','inputs','outputs','handoff','exception_handling','exception_target'];steplabels=['Stable step identity','Department','Responsible role','Step action','Inputs and origin','Outputs and recipient','Handoff to next department or role','Exception handling and recovery','Exception destination']
p=r/'DPH.Workspace.Model.pas';s=p.read_text(encoding='utf-8-sig');a=s.index('\ntype\n');s=s[:a]+"\nconst DPHWorkflowKeys:array[0..4] of string = ("+','.join("'"+x+"'" for x in keys)+");\n DPHWorkflowStepKeys:array[0..8] of string = ("+','.join("'"+x+"'" for x in stepkeys)+');\n'+s[a:]
s=s.replace('    class function NewBusinessProcess:', '''    class function NewDepartmentalWorkflow:TJSONObject;static;
    class function NewWorkflowStep:TJSONObject;static;
    class procedure ValidateWorkflowStep(AStep:TJSONObject);static;
    class procedure ValidateDepartmentalWorkflow(ARecord:TJSONObject);static;
    class function DepartmentalWorkflowBody(ARecord:TJSONObject):string;static;
    class function IsDepartmentalWorkflow(ARow:TJSONObject):Boolean;static;
    class function DescribeDepartmentalWorkflow(ARow:TJSONObject):string;static;
    class function NewBusinessProcess:''',1)
a=s.index('class function TDPHWorkspaceView.NewBusinessProcess:')
model='''class function TDPHWorkspaceView.NewDepartmentalWorkflow:TJSONObject;
var Fields:TJSONObject;Key:string;
begin
 Result:=TJSONObject.Create.AddPair('record_type','departmental_workflow').AddPair('workflow_id',TGUID.NewGuid.ToString);
 Fields:=TJSONObject.Create;Result.AddPair('fields',Fields);Result.AddPair('steps',TJSONArray.Create);
 for Key in DPHWorkflowKeys do Fields.AddPair(Key,'Unknown');
end;
class function TDPHWorkspaceView.NewWorkflowStep:TJSONObject;
var Key:string;
begin
 Result:=TJSONObject.Create;
 for Key in DPHWorkflowStepKeys do if Key='step_id' then Result.AddPair(Key,TGUID.NewGuid.ToString) else Result.AddPair(Key,'Unknown');
end;
class procedure TDPHWorkspaceView.ValidateWorkflowStep(AStep:TJSONObject);
var Key:string;Pair:TJSONPair;ID:TGUID;
begin
 if (AStep=nil) or (AStep.Count<>Length(DPHWorkflowStepKeys)) then raise EArgumentException.Create('Step requires its nine structured fields');
 for Pair in AStep do if not (Pair.JsonValue is TJSONString) then raise EArgumentException.Create('Step fields must be text');
 for Key in DPHWorkflowStepKeys do if (AStep.GetValue<string>(Key,'').Trim='') or (Length(AStep.GetValue<string>(Key))>2048) then raise EArgumentException.Create('Complete '+Key+' or enter Unknown; maximum 2048 characters');
 try ID:=StringToGUID(AStep.GetValue<string>('step_id'));except raise EArgumentException.Create('Invalid step identity');end;
 if ID.ToString<>AStep.GetValue<string>('step_id') then raise EArgumentException.Create('Use canonical step identity');
 if SameText(AStep.GetValue<string>('action').Trim,'Unknown') then raise EArgumentException.Create('Enter a descriptive step action');
end;
class procedure TDPHWorkspaceView.ValidateDepartmentalWorkflow(ARecord:TJSONObject);
var Fields:TJSONObject;Steps:TJSONArray;V:TJSONValue;Pair:TJSONPair;Key,Target:string;ID:TGUID;IDs:TList<string>;
begin
 if (ARecord=nil) or (ARecord.Count<>4) or (ARecord.GetValue<string>('record_type','')<>'departmental_workflow') then raise EArgumentException.Create('Expected a structured departmental workflow');
 if Length(ARecord.ToJSON)>65536 then raise EArgumentException.Create('Workflow exceeds 64 KiB; split it into explicitly linked workflows');
 try ID:=StringToGUID(ARecord.GetValue<string>('workflow_id',''));except raise EArgumentException.Create('Invalid workflow identity');end;
 if ID.ToString<>ARecord.GetValue<string>('workflow_id') then raise EArgumentException.Create('Use canonical workflow identity');
 if not ARecord.TryGetValue<TJSONObject>('fields',Fields) or (Fields.Count<>Length(DPHWorkflowKeys)) then raise EArgumentException.Create('Workflow requires its five fields');
 for Pair in Fields do if not (Pair.JsonValue is TJSONString) then raise EArgumentException.Create('Workflow fields must be text');
 for Key in DPHWorkflowKeys do if (Fields.GetValue<string>(Key,'').Trim='') or (Length(Fields.GetValue<string>(Key))>4096) then raise EArgumentException.Create('Complete '+Key+' or enter Unknown; maximum 4096 characters');
 if SameText(Fields.GetValue<string>('name').Trim,'Unknown') or (Length(Fields.GetValue<string>('name'))>200) then raise EArgumentException.Create('Enter a descriptive workflow name of at most 200 characters');
 if not ARecord.TryGetValue<TJSONArray>('steps',Steps) or (Steps.Count<1) or (Steps.Count>64) then raise EArgumentException.Create('Workflow requires 1 through 64 ordered steps');
 IDs:=TList<string>.Create;
 try
  for V in Steps do begin
   if not (V is TJSONObject) then raise EArgumentException.Create('Step must be an object');
   ValidateWorkflowStep(V as TJSONObject);Key:=V.GetValue<string>('step_id');
   if IDs.Contains(Key) then raise EArgumentException.Create('Duplicate workflow step identity');IDs.Add(Key);
  end;
  for V in Steps do begin Target:=V.GetValue<string>('exception_target');
   if (Target<>'Unknown') and (Target<>'End') and not IDs.Contains(Target) then raise EArgumentException.Create('Exception destination is absent from this workflow');
  end;
 finally IDs.Free;end;
end;
class function TDPHWorkspaceView.DepartmentalWorkflowBody(ARecord:TJSONObject):string;
const Labels:array[0..4] of string=(LABELS);
 StepLabels:array[0..8] of string=(STEPLABELS);
var I,J:Integer;Fields,Step:TJSONObject;Steps:TJSONArray;Target,V:string;
begin
 ValidateDepartmentalWorkflow(ARecord);Fields:=ARecord.GetValue<TJSONObject>('fields');Steps:=ARecord.GetValue<TJSONArray>('steps');
 Result:='DEPARTMENTAL WORKFLOW'+sLineBreak;
 for I:=0 to High(DPHWorkflowKeys) do Result:=Result+sLineBreak+Labels[I]+': '+Fields.GetValue<string>(DPHWorkflowKeys[I])+sLineBreak;
 Result:=Result+sLineBreak+'ORDERED STEPS AND DEPARTMENT HANDOFFS'+sLineBreak;
 for I:=0 to Steps.Count-1 do begin Step:=Steps.Items[I] as TJSONObject;
  Result:=Result+sLineBreak+'Step '+IntToStr(I+1)+': '+Step.GetValue<string>('action')+sLineBreak;
  for J:=1 to High(DPHWorkflowStepKeys)-1 do Result:=Result+StepLabels[J]+': '+Step.GetValue<string>(DPHWorkflowStepKeys[J])+sLineBreak;
  if I+1<Steps.Count then V:='Step '+IntToStr(I+2) else V:='End';Result:=Result+'Normal authored sequence: '+V+sLineBreak;
  Target:=Step.GetValue<string>('exception_target');V:=Target;
  for J:=0 to Steps.Count-1 do if Steps.Items[J].GetValue<string>('step_id')=Target then V:='Step '+IntToStr(J+1)+': '+Steps.Items[J].GetValue<string>('action');
  Result:=Result+'Exception destination: '+V+sLineBreak;
 end;
 Result:=Result+sLineBreak+'Attributed workflow; Unknown remains unresolved. Ordered steps and exception destinations are supplied by a contributor. DPH never executes this workflow. Content review is separate from business authorization or observed success. Use exact Knowledge links for business-process, source and procedure evidence.';
end;
class function TDPHWorkspaceView.IsDepartmentalWorkflow(ARow:TJSONObject):Boolean;
var V:TJSONValue;
begin
 Result:=False;if ARow=nil then Exit;V:=TJSONObject.ParseJSONValue(ARow.GetValue<string>('structured_json','{}'));
 try if V is TJSONObject then Result:=(ARow.GetValue<string>('kind','')='business_rule') and (V.GetValue<string>('record_type','')='departmental_workflow');finally V.Free;end;
end;
class function TDPHWorkspaceView.DescribeDepartmentalWorkflow(ARow:TJSONObject):string;
var History:TJSONArray;V:TJSONValue;
begin
 Result:='No saved workflow selected. New workflow opens structured fields and ordered steps. Empty results do not establish absent workflows.';
 if not IsDepartmentalWorkflow(ARow) then Exit;
 Result:=ARow.GetValue<string>('title')+sLineBreak+'Original contributor: '+ARow.GetValue<string>('owner')+sLineBreak+'Review state: '+ARow.GetValue<string>('state')+' | revision '+ARow.GetValue<string>('revision')+sLineBreak+'Reviewer: '+IfThen(ARow.GetValue<string>('reviewer','')='','not supplied',ARow.GetValue<string>('reviewer',''))+sLineBreak+'Explicit implementation/evidence links: '+IntToStr(ARow.GetValue<TJSONArray>('rich_links').Count)+sLineBreak;
 if ARow.TryGetValue<TJSONArray>('history',History) then for V in History do if V.GetValue<string>('revision')=ARow.GetValue<string>('revision') then Result:=Result+'Current revision author: '+V.GetValue<string>('editor')+sLineBreak;
 Result:=Result+sLineBreak+ARow.GetValue<string>('body');
end;

'''.replace('STEPLABELS',','.join("'"+x+"'" for x in steplabels)).replace('LABELS',','.join("'"+x+"'" for x in labels));s=s[:a]+model+s[a:];p.write_text(s,encoding='utf-8')
p=r/'DPH.Storage.Database.pas';s=p.read_text(encoding='utf-8-sig');a=s.index("      end else if StructuredValue.GetValue<string>('record_type','')='business_process'");b=s.index("      end else if StructuredValue.GetValue<string>('record_type','')='data_quality'",a);block=s[a:b].replace('business_process','departmental_workflow').replace('BusinessProcess','DepartmentalWorkflow').replace('process_id','workflow_id').replace('Business processes','Departmental workflows').replace('Business process','Departmental workflow').replace('business process','departmental workflow').replace('Process title','Workflow title');s=s[:b]+block+s[b:];p.write_text(s,encoding='utf-8')
p=r/'DPH.UI.Main.pas';s=p.read_text(encoding='utf-8-sig')
def tr(x):return x.replace('BusinessProcess','DepartmentalWorkflow').replace('business processes','departmental workflows').replace('business process','departmental workflow').replace('processes','workflows').replace('process','workflow')
a=s.index('    BusinessProcessTab:');b=s.index('    BusinessProcessEdit:',a);decl=tr(s[a:b])+'''    DepartmentalWorkflowEdit:TButton;
    WorkflowEditorTab:TTabItem;
    WorkflowEditorPurpose,WorkflowAuthorLabel,WorkflowStepsLabel,WorkflowExceptionLabel:TLabel;
    WorkflowEditorToolbar,WorkflowStepToolbar:THorzScrollBox;
    WorkflowAuthor:TEdit;
    WorkflowApply,WorkflowCancel,WorkflowNewStep,WorkflowSaveStep,WorkflowDiscardStep,WorkflowRemoveStep,WorkflowStepUp,WorkflowStepDown:TButton;
    WorkflowEditorScroll:TVertScrollBox;
    WorkflowSteps:TListBox;
    WorkflowExceptionTarget:TComboBox;
'''
for key in keys:decl+=f'    Workflow_{key}_Row:TLayout;Workflow_{key}_Label:TLabel;Workflow_{key}:TMemo;\n'
for key in stepkeys[:-1]:decl+=f'    Step_{key}_Row:TLayout;Step_{key}_Label:TLabel;Step_{key}:TMemo;\n'
s=s[:b]+decl+s[b:];a=s.index('    procedure BusinessProcessFilterChange');b=s.index('    procedure BusinessProcessEditClick',a);s=s[:b]+tr(s[a:b])+'''    procedure DepartmentalWorkflowEditClick(Sender:TObject);
    procedure WorkflowApplyClick(Sender:TObject);
    procedure WorkflowStepClick(Sender:TObject);
    procedure WorkflowStepChange(Sender:TObject);
    procedure WorkflowStepAction(Sender:TObject);
    procedure RefreshWorkflowSteps;
'''+s[b:]
s=s.replace('    FBusinessProcessRows:', '''    FDepartmentalWorkflowRows:TList<TJSONObject>;
    FDepartmentalWorkflowOffset:Integer;
    FWorkflowDraft:TJSONObject;
    FWorkflowStepIndex:Integer;
    FWorkflowStepDirty:Boolean;
    FBusinessProcessRows:''',1).replace('FBusinessProcessRows:=TList<TJSONObject>.Create;','FBusinessProcessRows:=TList<TJSONObject>.Create;FDepartmentalWorkflowRows:=TList<TJSONObject>.Create;',1).replace('FBusinessProcessRows.Free;','FWorkflowDraft.Free;FDepartmentalWorkflowRows.Free;FBusinessProcessRows.Free;',1).replace('BusinessProcessFilterChange(nil);','BusinessProcessFilterChange(nil);DepartmentalWorkflowFilterChange(nil);')
# New/discarded Knowledge cannot leave an older workflow draft active.
s=s.replace("  FreeAndNil(FTranslations); TranslationList.Items.Clear; TranslationMemo.Text:='';", "  FreeAndNil(FWorkflowDraft);FWorkflowStepDirty:=False;\n  FreeAndNil(FTranslations); TranslationList.Items.Clear; TranslationMemo.Text:='';",1)
a=s.index('procedure TDPHMainForm.BusinessProcessFilterChange');b=s.index('procedure TDPHMainForm.BusinessProcessEditClick',a);block=tr(s[a:b]);block=block.replace("'No saved workflow", "'No saved workflow");s=s[:b]+block+s[b:]
a=s.index('procedure TDPHMainForm.BusinessProcessEditClick');b=s.index('procedure TDPHMainForm.DataQualityFilterChange',a)
code='''procedure TDPHMainForm.DepartmentalWorkflowEditClick(Sender:TObject);
var Fields:TJSONObject;Key:string;
begin
 if FBusy or (FView=nil) then Exit;
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft before editing a workflow.';Exit;end;
 if Sender=DepartmentalWorkflowNew then begin NewKnowledgeClick(nil);FWorkflowDraft:=TDPHWorkspaceView.NewDepartmentalWorkflow;end
 else begin
  if DepartmentalWorkflowList.ItemIndex<0 then Exit;
  DepartmentalWorkflowOpenClick(nil);FreeAndNil(FWorkflowDraft);
  FWorkflowDraft:=TJSONObject.ParseJSONValue(FKnowledgeStructuredJSON) as TJSONObject;
  if (FWorkflowDraft=nil) or (FWorkflowDraft.GetValue<string>('record_type','')<>'departmental_workflow') then begin FreeAndNil(FWorkflowDraft);Exit;end;
 end;
 FBinding:=True;
 try
  Fields:=FWorkflowDraft.GetValue<TJSONObject>('fields');
  for Key in DPHWorkflowKeys do (FindComponent('Workflow_'+Key) as TMemo).Text:=Fields.GetValue<string>(Key,'Unknown');
  Workflow_name.ReadOnly:=FKnowledgeID<>0;WorkflowAuthor.Text:=KnowledgeAuthorEdit.Text;
  FWorkflowStepIndex:=-1;FWorkflowStepDirty:=False;
 finally FBinding:=False;end;
 FKnowledgeStructuredJSON:=FWorkflowDraft.ToJSON;FKnowledgeEdited:=True;RefreshWorkflowSteps;WorkspaceTabs.ActiveTab:=WorkflowEditorTab;
 StatusLabel.Text:='Complete workflow fields and add ordered steps. Apply step keeps it in this draft; Apply workflow prepares Knowledge. Save and review separately.';
end;
procedure TDPHMainForm.RefreshWorkflowSteps;
var Steps:TJSONArray;V:TJSONValue;I:Integer;
begin
 if FWorkflowDraft=nil then Exit;
 Steps:=FWorkflowDraft.GetValue<TJSONArray>('steps');FBinding:=True;
 try
  WorkflowSteps.Items.Clear;WorkflowExceptionTarget.Items.Clear;WorkflowExceptionTarget.Items.Add('Unknown');WorkflowExceptionTarget.Items.Add('End');
  I:=0;for V in Steps do begin Inc(I);WorkflowSteps.Items.Add(IntToStr(I)+'. '+V.GetValue<string>('department')+' | '+V.GetValue<string>('role')+' | '+V.GetValue<string>('action'));WorkflowExceptionTarget.Items.Add('Step '+IntToStr(I)+': '+V.GetValue<string>('action'));end;
  WorkflowSteps.ItemIndex:=FWorkflowStepIndex;
 finally FBinding:=False;end;
 WorkflowStepClick(nil);
end;
procedure TDPHMainForm.WorkflowStepClick(Sender:TObject);
var Steps:TJSONArray;Step:TJSONObject;Key,Target:string;I:Integer;
begin
 if FBinding or (FWorkflowDraft=nil) then Exit;
 if FWorkflowStepDirty then begin FBinding:=True;try WorkflowSteps.ItemIndex:=FWorkflowStepIndex;finally FBinding:=False;end;StatusLabel.Text:='Apply step or discard step changes before selecting another step.';Exit;end;
 Steps:=FWorkflowDraft.GetValue<TJSONArray>('steps');FWorkflowStepIndex:=WorkflowSteps.ItemIndex;Step:=nil;
 if (FWorkflowStepIndex>=0) and (FWorkflowStepIndex<Steps.Count) then Step:=Steps.Items[FWorkflowStepIndex] as TJSONObject;
 FBinding:=True;
 try
  for Key in DPHWorkflowStepKeys do if Key<>'exception_target' then begin
   (FindComponent('Step_'+Key) as TMemo).Text:='';if Step<>nil then (FindComponent('Step_'+Key) as TMemo).Text:=Step.GetValue<string>(Key);
  end;
  WorkflowExceptionTarget.ItemIndex:=0;
  if Step<>nil then begin Target:=Step.GetValue<string>('exception_target');if Target='End' then WorkflowExceptionTarget.ItemIndex:=1;
   for I:=0 to Steps.Count-1 do if Steps.Items[I].GetValue<string>('step_id')=Target then WorkflowExceptionTarget.ItemIndex:=I+2;
  end;
 finally FBinding:=False;end;
end;
procedure TDPHMainForm.WorkflowStepChange(Sender:TObject);
begin if not FBinding and (FWorkflowDraft<>nil) and FKnowledgeEdited then FWorkflowStepDirty:=True;end;
procedure TDPHMainForm.WorkflowStepAction(Sender:TObject);
var Steps:TJSONArray;Step:TJSONObject;Key,Target:string;V:TJSONValue;Index:Integer;
begin
 if FBusy or (FView=nil) or (FWorkflowDraft=nil) or not FKnowledgeEdited then Exit;
 Steps:=FWorkflowDraft.GetValue<TJSONArray>('steps');
 try
  if Sender=WorkflowDiscardStep then begin FWorkflowStepDirty:=False;WorkflowStepClick(nil);Exit;end;
  if (Sender<>WorkflowSaveStep) and FWorkflowStepDirty then raise EArgumentException.Create('Apply step or discard step changes first');
  if Sender=WorkflowNewStep then begin
   if Steps.Count>=64 then raise EArgumentException.Create('Workflow is limited to 64 steps');
   Step:=TDPHWorkspaceView.NewWorkflowStep;
   try FBinding:=True;try for Key in DPHWorkflowStepKeys do if Key<>'exception_target' then (FindComponent('Step_'+Key) as TMemo).Text:=Step.GetValue<string>(Key);WorkflowExceptionTarget.ItemIndex:=0;WorkflowSteps.ItemIndex:=-1;FWorkflowStepIndex:=-1;finally FBinding:=False;end;finally Step.Free;end;
   FWorkflowStepDirty:=True;StatusLabel.Text:='Complete the new step action, department, role, inputs, outputs, handoff and exception path; then Apply step.';Exit;
  end;
  if Sender=WorkflowSaveStep then begin
   if not FWorkflowStepDirty then Exit;
   Step:=TJSONObject.Create;
   try
    for Key in DPHWorkflowStepKeys do if Key<>'exception_target' then Step.AddPair(Key,(FindComponent('Step_'+Key) as TMemo).Text.Trim);
    Target:='Unknown';Index:=WorkflowExceptionTarget.ItemIndex;
    if Index=1 then Target:='End' else if (Index>=2) and (Index-2<Steps.Count) then Target:=Steps.Items[Index-2].GetValue<string>('step_id');
    Step.AddPair('exception_target',Target);TDPHWorkspaceView.ValidateWorkflowStep(Step);
    if FWorkflowStepIndex<0 then begin Steps.AddElement(Step.Clone as TJSONObject);FWorkflowStepIndex:=Steps.Count-1;end
    else begin Steps.Remove(FWorkflowStepIndex).Free;Steps.Insert(FWorkflowStepIndex,Step.Clone as TJSONObject);end;
   finally Step.Free;end;
   FWorkflowStepDirty:=False;RefreshWorkflowSteps;StatusLabel.Text:='Step applied to workflow draft. Apply workflow and Save to persist.';Exit;
  end;
  if (FWorkflowStepIndex<0) or (FWorkflowStepIndex>=Steps.Count) then Exit;
  if Sender=WorkflowRemoveStep then begin
   Target:=Steps.Items[FWorkflowStepIndex].GetValue<string>('step_id');
   for V in Steps do if (V.GetValue<string>('step_id')<>Target) and (V.GetValue<string>('exception_target')=Target) then raise EArgumentException.Create('Change the referring exception destination before removing this step');
   Steps.Remove(FWorkflowStepIndex).Free;FWorkflowStepIndex:=-1;
  end else begin Index:=FWorkflowStepIndex;
   if Sender=WorkflowStepUp then Dec(Index) else if Sender=WorkflowStepDown then Inc(Index) else Exit;
   if (Index<0) or (Index>=Steps.Count) then Exit;
   V:=Steps.Remove(FWorkflowStepIndex);Steps.Insert(Index,V);FWorkflowStepIndex:=Index;
  end;
  RefreshWorkflowSteps;
 except on E:Exception do StatusLabel.Text:=E.Message;end;
end;
procedure TDPHMainForm.WorkflowApplyClick(Sender:TObject);
var Fields:TJSONObject;Key:string;
begin
 if FBusy or (FView=nil) or (FWorkflowDraft=nil) or not FKnowledgeEdited then Exit;
 try
  if FWorkflowStepDirty then raise EArgumentException.Create('Apply step or discard step changes before applying the workflow');
  Fields:=FWorkflowDraft.GetValue<TJSONObject>('fields');
  for Key in DPHWorkflowKeys do begin Fields.RemovePair(Key).Free;Fields.AddPair(Key,(FindComponent('Workflow_'+Key) as TMemo).Text.Trim);end;
  TDPHWorkspaceView.ValidateDepartmentalWorkflow(FWorkflowDraft);
  if WorkflowAuthor.Text.Trim='' then raise EArgumentException.Create('Enter a named contributor');
  FBinding:=True;
  try
   KnowledgeTitleEdit.Text:=Fields.GetValue<string>('name').Trim;KnowledgeAuthorEdit.Text:=WorkflowAuthor.Text.Trim;KnowledgeBodyMemo.Text:=TDPHWorkspaceView.DepartmentalWorkflowBody(FWorkflowDraft);
   KnowledgeTitleEdit.ReadOnly:=True;KnowledgeBodyMemo.ReadOnly:=True;
   KnowledgeKindCombo.ItemIndex:=KnowledgeKindCombo.Items.IndexOf('business_rule');KnowledgeDocumentCombo.ItemIndex:=KnowledgeDocumentCombo.Items.IndexOf('maintenance');KnowledgeAudienceCombo.ItemIndex:=KnowledgeAudienceCombo.Items.IndexOf('maintainer');
   KnowledgeKindCombo.Enabled:=False;KnowledgeDocumentCombo.Enabled:=False;KnowledgeAudienceCombo.Enabled:=False;FKnowledgeStructuredJSON:=FWorkflowDraft.ToJSON;FKnowledgeLink:='';FKnowledgeQuestionJSON:='';
  finally FBinding:=False;end;
  WorkspaceTabs.ActiveTab:=KnowledgeTab;StatusLabel.Text:='Workflow draft prepared. Save, add exact business-process/source/procedure links, Save again and review separately.';
 except on E:Exception do StatusLabel.Text:=E.Message;end;
end;

'''
s=s[:b]+code+s[b:];p.write_text(s,encoding='utf-8')
p=r/'DPH.UI.Main.fmx';s=p.read_text(encoding='utf-8-sig');a=s.index('object BusinessProcessTab:');b=s.index('object BusinessProcessEditorTab:',a);block=tr(s[a:b]);block=block.replace("Text = 'Business processes'","Text = 'Departmental workflows'");x=block.index("Text = 'Inventory");y=block.index('\nend',x);block=block[:x]+"Text = 'Document ordered departmental steps, responsible roles, handoffs and exception destinations. New workflow and Edit fields open the native editor. Apply steps, Apply workflow, Save and review separately.'"+block[y:];block=block.replace('Find workflow, owner, input or output','Find workflow, department, role or action')
editor='''object WorkflowEditorTab:TTabItem
Text = 'Workflow fields'
object WorkflowEditorPurpose:TLabel
Align = Top
Height = 64
Margins.Left = 12
Margins.Right = 12
WordWrap = True
Text = 'Complete workflow fields and ordered steps. Apply step updates this draft; Apply workflow prepares Knowledge. Save persists it. Unknown remains unresolved. Cancel discards the entire draft.'
end
object WorkflowEditorToolbar:THorzScrollBox
Align = Top
Height = 80
ShowScrollBars = True
object WorkflowAuthorLabel:TLabel
Position.X = 12
Width = 200
Height = 24
Text = 'Named contributor'
end
object WorkflowAuthor:TEdit
Position.X = 12
Position.Y = 28
Width = 200
Height = 28
end
object WorkflowApply:TButton
Position.X = 220
Position.Y = 28
Width = 180
Height = 28
Text = 'Apply workflow to draft'
OnClick = WorkflowApplyClick
end
object WorkflowCancel:TButton
Position.X = 220
Width = 150
Height = 24
Text = 'Cancel / discard draft'
OnClick = DiscardKnowledgeClick
end
end
object WorkflowEditorScroll:TVertScrollBox
Align = Client
Margins.Left = 12
Margins.Right = 12
Margins.Bottom = 12
'''
def field(prefix,key,label,hidden=False):
 return f'''object {prefix}_{key}_Row:TLayout
Align = Top
Height = 100
'''+('Visible = False\n' if hidden else '')+f'''object {prefix}_{key}_Label:TLabel
Align = Top
Height = 26
Text = '{label}'
end
object {prefix}_{key}:TMemo
Align = Client
Margins.Bottom = 8
WordWrap = True
ShowScrollBars = True
'''+('ReadOnly = True\n' if hidden else '')+('OnChange = WorkflowStepChange\n' if prefix=='Step' else '')+'end\nend\n'
for key,label in zip(keys,labels):editor+=field('Workflow',key,label)
editor+='''object WorkflowStepsLabel:TLabel
Align = Top
Height = 32
WordWrap = True
Text = 'Ordered steps - select a step to edit'
end
object WorkflowSteps:TListBox
Align = Top
Height = 132
OnChange = WorkflowStepClick
end
object WorkflowStepToolbar:THorzScrollBox
Align = Top
Height = 44
ShowScrollBars = True
'''
for i,(name,label) in enumerate([('NewStep','New step'),('SaveStep','Apply step'),('DiscardStep','Discard step edits'),('RemoveStep','Remove step'),('StepUp','Move up'),('StepDown','Move down')]):editor+=f'''object Workflow{name}:TButton
Position.X = {i*140}
Width = 132
Height = 28
Text = '{label}'
OnClick = WorkflowStepAction
end
'''
editor+='end\n'
for key,label in zip(stepkeys[:-1],steplabels[:-1]):editor+=field('Step',key,label,key=='step_id')
editor+='''object WorkflowExceptionLabel:TLabel
Align = Top
Height = 30
Text = 'Exception destination: Unknown, End or a named step'
WordWrap = True
end
object WorkflowExceptionTarget:TComboBox
Align = Top
Height = 32
Items.Strings = ('Unknown' 'End')
ItemIndex = 0
OnChange = WorkflowStepChange
end
end
end
''';s=s[:b]+block+editor+s[b:];s=s.replace("'Business processes'\n","'Business processes'\n'Departmental workflows'\n'Workflow fields'\n",1);p.write_text(s,encoding='utf-8')
print('Typed departmental workflow, ordered steps, native editor and storage guards added.')
