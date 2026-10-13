from pathlib import Path
r=Path.cwd();s=(r/'tests/DPH.Tests.TargetRecovery.dpr').read_text(encoding='utf-8-sig')
for a,b in [('TargetRecoveryPlan','BusinessProcess'),('TargetRecovery','BusinessProcess'),('target_recovery','business_process'),('plan_id','process_id'),('target-recovery','business-process'),('Recovery.dpr','Operations.dpr'),('program Recovery;','program Operations;'),('RestoreOrders','FulfilOrders'),('Orders backup and restoration','Fulfil orders'),('Recovery author','Process author'),('Recovery reviewer','Process reviewer'),('recovery-','process-')]:s=s.replace(a,b)
a=s.index(' Body:=TDPHWorkspaceView.NewBusinessProcess;');b=s.index(' Check(SavePolicy(0,0,PolicyTitle,Body',a)
s=s[:a]+''' RecordValue:=TDPHWorkspaceView.NewBusinessProcess;
 try
  Row:=RecordValue.GetValue<TJSONObject>('fields');
  Row.RemovePair('name').Free;Row.AddPair('name','Fulfil orders');
  Row.RemovePair('owner').Free;Row.AddPair('owner','Operations manager');
  Row.RemovePair('inputs').Free;Row.AddPair('inputs','Approved order from sales');
  Row.RemovePair('outputs').Free;Row.AddPair('outputs','Dispatch confirmation to customer');
  Row.RemovePair('steps').Free;Row.AddPair('steps','1. Check order; 2. Reserve stock; 3. Dispatch; 4. Confirm');
  TDPHWorkspaceView.ValidateBusinessProcess(RecordValue);Metadata:=RecordValue.ToJSON;
  Body:=TDPHWorkspaceView.BusinessProcessBody(RecordValue);PolicyTitle:='Fulfil orders';
  Check(Body.Contains('Approved order from sales'),'Structured process inputs rendered');
  Check(Body.Contains('Dispatch confirmation to customer'),'Structured process outputs rendered');
  Check(Body.Contains('Operations manager'),'Accountable owner rendered separately from contributor');
  Check(Body.Contains('Ordered steps and handoffs'),'Structured ordered steps rendered');
  Check(Body.Contains('Department and participating roles: Unknown'),'Missing department remains explicitly unknown');
  Check(Body.Contains('not observed execution'),'Business process qualification retained');
 finally RecordValue.Free;end;
'''+s[b:]
s=s.replace('ValidateBusinessProcessRecord','ValidateBusinessProcess').replace("'Recovery plan: enter descriptive data scope'","'Incorrect title'")
s=s.replace('Check(Row.GetValue<string>(\'body\').Contains(\'15 minutes\'),\'Authored target period persists\')',"Check(Row.GetValue<string>('body').Contains('Approved order from sales'),'Structured process inputs persist')")
a=s.index(" Store.SaveKnowledge(PolicyID,Revision,Generation,PolicyTitle,Body+sLineBreak");b=s.index(" Check(Store.IntegrityCheck='ok'",a)
s=s[:a]+''' RecordValue:=TJSONObject.ParseJSONValue(Metadata) as TJSONObject;
 try
  Row:=RecordValue.GetValue<TJSONObject>('fields');Row.RemovePair('outputs').Free;Row.AddPair('outputs','Dispatch confirmation and tracking number');
  Metadata:=RecordValue.ToJSON;Body:=TDPHWorkspaceView.BusinessProcessBody(RecordValue);
 finally RecordValue.Free;end;
 Store.SaveKnowledge(PolicyID,Revision,Generation,PolicyTitle,Body,'Second author','business_rule','','maintenance','maintainer','','',Metadata);
 Row:=LoadPolicy;try Check(Row.GetValue<string>('state')='needs_review','Process edits reopen review');Check(Row.GetValue<TJSONArray>('history').Count=3,'Prior reviewed process retained');Check(Row.GetValue<TJSONArray>('rich_links').Count=2,'Process revision preserves implementation links');Check(Row.GetValue<string>('body').Contains('tracking number'),'Changed structured output persists');finally Row.Free;end;
 Check(SavePolicy(PolicyID,0,PolicyTitle,Body+sLineBreak+'invented prose','Editor','business_rule','maintenance','maintainer','',Metadata),'Structured process body cannot diverge from fields');
'''+s[b:]
s=s.replace(".Contains('15 minutes'),'Published HTML includes authored retention period'",".Contains('Approved order from sales'),'Published HTML includes structured inputs'")
s=s.replace("Check(not Form.KnowledgeBodyMemo.ReadOnly,'Saved plan body remains editable')","Check(Form.KnowledgeBodyMemo.ReadOnly,'Saved structured body protected from free text edits')")
a=s.index(' Form.BusinessProcessNewClick(nil);');b=s.index(' Form.BusinessProcessState.ItemIndex:=2;',a)
s=s[:a]+''' Form.BusinessProcessEditClick(nil);Check(Form.WorkspaceTabs.ActiveTab=Form.BusinessProcessEditorTab,'Edit opens native structured fields');Check(Form.Process_inputs.Text='Approved order from sales','Native editor restores persisted input');Check(Form.Process_name.ReadOnly,'Saved process name remains stable');
 Form.Process_outputs.Text:='Revised native output';Form.BusinessProcessAuthor.Text:='Native contributor';Form.BusinessProcessApplyClick(nil);Check(Form.WorkspaceTabs.ActiveTab=Form.KnowledgeTab,'Apply prepares Knowledge draft');Check(Form.KnowledgeBodyMemo.Text.Contains('Revised native output'),'Native structured edit generates canonical body');
 Body:=Form.KnowledgeBodyMemo.Text;Form.BusinessProcessOpenClick(nil);Check(Form.KnowledgeBodyMemo.Text=Body,'Unsaved structured draft protected from selection');Form.BusinessProcessNewClick(nil);Check(Form.StatusLabel.Text.Contains('Save or discard'),'Unsaved structured draft protected from replacement');Form.DiscardKnowledgeClick(nil);
 Form.BusinessProcessNewClick(nil);Check(Form.WorkspaceTabs.ActiveTab=Form.BusinessProcessEditorTab,'New process opens structured editor');Check(not Form.Process_name.ReadOnly,'New process name editable');
 Form.BusinessProcessAuthor.Text:='';Form.BusinessProcessApplyClick(nil);Check(Form.WorkspaceTabs.ActiveTab=Form.BusinessProcessEditorTab,'Invalid unnamed process stays in editor');
 Form.Process_name.Text:='Native process';Form.BusinessProcessAuthor.Text:='Native contributor';Form.BusinessProcessApplyClick(nil);Check(Form.KnowledgeBodyMemo.Text.Contains('BUSINESS PROCESS'),'New native process canonical body prepared');Check(Form.KnowledgeBodyMemo.ReadOnly,'Canonical draft body protected');Form.DiscardKnowledgeClick(nil);
'''+s[b:]
s=s.replace("BusinessProcessFilter.Text:='15 minutes'","BusinessProcessFilter.Text:='Approved order'").replace(".Contains('Empty results do not prove')",".Contains('Empty results do not prove')")
s=s.replace("Form.BusinessProcessToolbar.ShowScrollBars and Form.BusinessProcessMemo.ShowScrollBars","Form.BusinessProcessToolbar.ShowScrollBars and Form.BusinessProcessMemo.ShowScrollBars")
s=s.replace("'qualification','Attributed target backup/restore requirements and recovery-test claims with source links; target jobs and reported success remain unverified.'","'qualification','Structured attributed business-process inventory with inputs, outputs, owners, ordered steps and exact source/procedure links. Target execution and business outcomes remain unverified.'")
s=s.replace("'Restoration operator procedure'","'Order fulfilment procedure'").replace('Controlled procedure: check restoration prerequisites before requesting recovery. No execution.','Controlled order fulfilment procedure; source evidence only. No execution.')
# Additional strict shape and field validation, using a valid baseline each time.
a=s.index(' Links:=TJSONArray.Create;')
extra=''' RecordValue:=TJSONObject.ParseJSONValue(Metadata) as TJSONObject;try Row:=RecordValue.GetValue<TJSONObject>('fields');Row.RemovePair('inputs').Free;Row.AddPair('inputs','');Check(SavePolicy(0,0,PolicyTitle,Body,'Author','business_rule','maintenance','maintainer','',RecordValue.ToJSON),'Empty structured inputs rejected; Unknown must be explicit');finally RecordValue.Free;end;
 RecordValue:=TJSONObject.ParseJSONValue(Metadata) as TJSONObject;try Row:=RecordValue.GetValue<TJSONObject>('fields');Row.RemovePair('owner').Free;Row.AddPair('owner',TJSONNumber.Create(1));Check(SavePolicy(0,0,PolicyTitle,Body,'Author','business_rule','maintenance','maintainer','',RecordValue.ToJSON),'Numeric owner rejected');finally RecordValue.Free;end;
 RecordValue:=TJSONObject.ParseJSONValue(Metadata) as TJSONObject;try Row:=RecordValue.GetValue<TJSONObject>('fields');Row.RemovePair('steps').Free;Row.AddPair('steps',StringOfChar('x',4097));Check(SavePolicy(0,0,PolicyTitle,Body,'Author','business_rule','maintenance','maintainer','',RecordValue.ToJSON),'Oversized structured field rejected');finally RecordValue.Free;end;
'''
s=s[:a]+extra+s[a:]
(r/'tests/DPH.Tests.BusinessProcess.dpr').write_text(s,encoding='utf-8-sig')
(r/'tools/build-business-process.cmd').write_text((r/'tools/build-target-recovery.cmd').read_text().replace('TargetRecovery','BusinessProcess'),encoding='utf-8')
print('Business process focused acceptance fixture prepared.')
