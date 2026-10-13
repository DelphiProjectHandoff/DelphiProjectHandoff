from pathlib import Path
p=Path('DPH.UI.Main.pas');s=p.read_text(encoding='utf-8-sig')
s=s.replace('    FWorkflowStepDirty:Boolean;','    FWorkflowStepDirty:Boolean;\n    FStructuredEditorPending:Boolean;\n    FStructuredEditorID:string;')
s=s.replace('    procedure WorkflowApplyClick(Sender:TObject);','    procedure WorkflowApplyClick(Sender:TObject);\n    procedure StructuredEditorChange(Sender:TObject);')
s=s.replace('procedure TDPHMainForm.NewKnowledgeClick(Sender: TObject);\nbegin','procedure TDPHMainForm.NewKnowledgeClick(Sender: TObject);\nbegin',1)
start=s.index('procedure TDPHMainForm.NewKnowledgeClick(Sender: TObject);');pos=s.index('  FreeAndNil(FTranslations);',start);s=s[:pos]+"  FreeAndNil(FWorkflowDraft);FWorkflowStepDirty:=False;FStructuredEditorPending:=False;FStructuredEditorID:='';\n"+s[pos:]
s=s.replace("begin Submit('save_knowledge'); end;", "begin\n if FStructuredEditorPending then begin StatusLabel.Text:='Apply the structured editor to Knowledge or discard its draft before Save.';Exit;end;\n Submit('save_knowledge');\nend;",1)
# Both nonmodal structured editors remain bound to their original record.
s=s.replace("FKnowledgeStructuredJSON:=RecordValue.ToJSON;Fields:=RecordValue.GetValue<TJSONObject>('fields');", "FKnowledgeStructuredJSON:=RecordValue.ToJSON;FStructuredEditorID:=RecordValue.GetValue<string>('process_id');FStructuredEditorPending:=True;Fields:=RecordValue.GetValue<TJSONObject>('fields');",1)
s=s.replace("if (RecordValue=nil) or (RecordValue.GetValue<string>('record_type','')<>'business_process') then raise EArgumentException.Create('Start or edit a process first');", "if (RecordValue=nil) or (RecordValue.GetValue<string>('record_type','')<>'business_process') or (RecordValue.GetValue<string>('process_id','')<>FStructuredEditorID) then raise EArgumentException.Create('Reopen this process with Edit fields before applying');")
s=s.replace("WorkspaceTabs.ActiveTab:=KnowledgeTab;StatusLabel.Text:='Process draft prepared.", "FStructuredEditorPending:=False;WorkspaceTabs.ActiveTab:=KnowledgeTab;StatusLabel.Text:='Process draft prepared.",1)
s=s.replace("FKnowledgeStructuredJSON:=FWorkflowDraft.ToJSON;FKnowledgeEdited:=True;RefreshWorkflowSteps;", "FKnowledgeStructuredJSON:=FWorkflowDraft.ToJSON;FStructuredEditorID:=FWorkflowDraft.GetValue<string>('workflow_id');FStructuredEditorPending:=True;FKnowledgeEdited:=True;RefreshWorkflowSteps;",1)
s=s.replace("begin if not FBinding and (FWorkflowDraft<>nil) and FKnowledgeEdited then FWorkflowStepDirty:=True;end;", "begin if not FBinding and (FWorkflowDraft<>nil) then begin StructuredEditorChange(Sender);if FStructuredEditorPending then FWorkflowStepDirty:=True;end;end;")
start=s.index('procedure TDPHMainForm.WorkflowStepAction');pos=s.index(" Steps:=FWorkflowDraft.GetValue<TJSONArray>('steps');",start);s=s[:pos]+" FStructuredEditorPending:=True;\n"+s[pos:]
start=s.index('procedure TDPHMainForm.WorkflowApplyClick');pos=s.index(' try\n',start);s=s[:pos]+''' try
  if FWorkflowDraft.GetValue<string>('workflow_id')<>FStructuredEditorID then raise EArgumentException.Create('Reopen this workflow with Edit fields before applying');
'''+s[pos+5:]
s=s.replace("WorkspaceTabs.ActiveTab:=KnowledgeTab;StatusLabel.Text:='Workflow draft prepared.", "FStructuredEditorPending:=False;WorkspaceTabs.ActiveTab:=KnowledgeTab;StatusLabel.Text:='Workflow draft prepared.",1)
a=s.index('procedure TDPHMainForm.WorkflowStepChange')
s=s[:a]+'''procedure TDPHMainForm.StructuredEditorChange(Sender:TObject);
var RecordValue:TJSONValue;ID:string;
begin
 if FBinding or (FView=nil) or (FStructuredEditorID='') then Exit;
 RecordValue:=TJSONObject.ParseJSONValue(FKnowledgeStructuredJSON);
 try
  if not (RecordValue is TJSONObject) then Exit;
  ID:=RecordValue.GetValue<string>('process_id',RecordValue.GetValue<string>('workflow_id',''));
  if ID<>FStructuredEditorID then begin StatusLabel.Text:='Reopen the record with Edit fields before changing these fields.';Exit;end;
  FStructuredEditorPending:=True;FKnowledgeEdited:=True;
 finally RecordValue.Free;end;
end;
'''+s[a:];p.write_text(s,encoding='utf-8')
p=Path('DPH.UI.Main.fmx');s=p.read_text(encoding='utf-8-sig')
for prefix,keys in [('Process',['name','owner','department','trigger','inputs','outputs','steps','unknowns']),('Workflow',['name','owner','scope','trigger','unknowns'])]:
 for key in keys:
  a=s.index('object '+prefix+'_'+key+':TMemo');b=s.index('\nend',a);s=s[:b]+'\nOnChange = StructuredEditorChange'+s[b:]
for name in ['BusinessProcessAuthor','WorkflowAuthor']:
 a=s.index('object '+name+':TEdit');b=s.index('\nend',a);s=s[:b]+'\nOnChange = StructuredEditorChange'+s[b:]
p.write_text(s,encoding='utf-8')
p=Path('tests/DPH.Tests.DepartmentalWorkflow.dpr');s=p.read_text(encoding='utf-8-sig');s=s.replace("Check(Form.Workflow_name.ReadOnly,'Saved workflow name protected');", "Check(Form.Workflow_name.ReadOnly,'Saved workflow name protected');Form.SaveKnowledgeClick(nil);Check(Form.StatusLabel.Text.Contains('Apply the structured editor'),'Save refuses unapplied workflow editor');")
s=s.replace("Form.DepartmentalWorkflowEditClick(nil);Form.Show;Render", "Form.DepartmentalWorkflowEditClick(nil);Form.WorkflowSteps.ItemIndex:=1;Form.WorkflowStepClick(nil);Form.Show;Render")
s=s.replace('Structured attributed departmental-workflow inventory with inputs, outputs, owners, ordered steps and exact source/procedure links. Target execution and business outcomes remain unverified.','Structured attributed departmental workflows with ordered steps, departments, roles, handoffs and explicit exception destinations. Target execution and business outcomes remain unverified.')
s=s.replace("'Process", "'Workflow").replace("'No capture disables new process'","'No capture disables new workflow'").replace('Remaining process rows','Remaining workflow rows').replace('prior process rows','prior workflow rows').replace('saved process','saved workflow').replace('process detail','workflow detail')
a=s.index(' Links:=TJSONArray.Create;');s=s[:a]+''' RecordValue:=TJSONObject.ParseJSONValue(Metadata) as TJSONObject;try Row:=RecordValue.GetValue<TJSONArray>('steps').Items[0] as TJSONObject;Row.RemovePair('inputs').Free;Row.AddPair('inputs',StringOfChar('x',2049));Check(SaveWorkflow(0,0,WorkflowTitle,Body,'Author','business_rule','maintenance','maintainer','',RecordValue.ToJSON),'Oversized step field rejected');finally RecordValue.Free;end;
 RecordValue:=TJSONObject.ParseJSONValue(Metadata) as TJSONObject;try for I:=3 to 65 do begin Step:=TDPHWorkspaceView.NewWorkflowStep;Step.RemovePair('action').Free;Step.AddPair('action','Bounded extra step');RecordValue.GetValue<TJSONArray>('steps').AddElement(Step);end;Check(SaveWorkflow(0,0,WorkflowTitle,Body,'Author','business_rule','maintenance','maintainer','',RecordValue.ToJSON),'More than 64 workflow steps rejected');finally RecordValue.Free;end;
'''+s[a:];p.write_text(s.rstrip()+'\n',encoding='utf-8-sig')
# Include the previous process editor in compatibility coverage for the shared draft guard.
s=Path('bin/regress-business-process.py').read_text(encoding='utf-8').replace('business-process','departmental-workflow').replace('.Business.dpr','.Workflow.dpr').replace('.Business.exe','.Workflow.exe');s=s.replace("('quality','DataQuality','data-quality','phase1-data-quality-')", "('quality','DataQuality','data-quality','phase1-data-quality-'),('process','BusinessProcess','business-process','phase1-business-process-')");Path('bin/regress-departmental-workflow.py').write_text(s,encoding='utf-8')
