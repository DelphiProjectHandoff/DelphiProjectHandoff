unit DPH.Workspace.ActionPurposes;
interface
uses System.JSON,DPH.Workspace.Model;
type TDPHActionPurposes=class
 class function Inspect(AView:TDPHWorkspaceView;AComponents:TJSONObject;AKnowledge:TJSONArray):TJSONObject;static;
 class function Describe(ARow:TJSONObject;AKnowledge:TJSONArray):string;static;
 class function FindRecord(AKnowledge:TJSONArray;const AIdentity:string):TJSONObject;static;
 class function State(ARow:TJSONObject;AKnowledge:TJSONArray):string;static;
end;
implementation
uses System.SysUtils,System.StrUtils,System.Generics.Collections,DPH.Knowledge.ActionPurpose;
class function TDPHActionPurposes.FindRecord(AKnowledge:TJSONArray;const AIdentity:string):TJSONObject;
var V:TJSONValue;R:TJSONObject;
begin
 Result:=nil;if AKnowledge=nil then Exit;
 for V in AKnowledge do begin R:=TJSONObject.ParseJSONValue(V.GetValue<string>('structured_json','{}')) as TJSONObject;
  try if (R<>nil) and (R.GetValue<string>('record_type','')='action_purpose') and SameText(R.GetValue<string>('fields.action_id',''),AIdentity) then Exit(V as TJSONObject);finally R.Free;end;
 end;
end;
class function TDPHActionPurposes.State(ARow:TJSONObject;AKnowledge:TJSONArray):string;
var Saved:TJSONObject;
begin Saved:=FindRecord(AKnowledge,ARow.GetValue<string>('action_id'));if Saved=nil then Result:='not recorded' else Result:=Saved.GetValue<string>('state');end;
class function TDPHActionPurposes.Inspect(AView:TDPHWorkspaceView;AComponents:TJSONObject;AKnowledge:TJSONArray):TJSONObject;
var Rows:TJSONArray;V,W:TJSONValue;Row,Component,Parent,Saved,R,S:TJSONObject;
 Nodes:TDictionary<string,TJSONObject>;Seen:TDictionary<string,Integer>;Path,Target,Key,Identity:string;Depth,Matches,Occurrences:Integer;
 function NodeID(C:TJSONObject;Index:Integer):string;
 begin Result:=LowerCase(C.GetValue<string>('source'))+'|'+IntToStr(Index);end;
begin
 Result:=TJSONObject.Create;Rows:=TJSONArray.Create;Result.AddPair('rows',Rows);
 Result.AddPair('qualification','Captured UI objects are candidates, not proof of a user action or business purpose. Captions/events do not establish intent. Purpose records and project tasks are attributed user documentation with independent review state. Unmatched saved targets remain historical/unresolved. No selected application is executed.');
 Nodes:=TDictionary<string,TJSONObject>.Create;Seen:=TDictionary<string,Integer>.Create;
 try
  try
   if AComponents<>nil then begin
    for V in AComponents.GetValue<TJSONArray>('rows') do begin Component:=V as TJSONObject;Nodes.AddOrSetValue(NodeID(Component,Component.GetValue<Integer>('node')),Component);end;
    for V in AComponents.GetValue<TJSONArray>('rows') do begin
     Component:=V as TJSONObject;Path:=Component.GetValue<string>('name');Parent:=Component;
     for Depth:=0 to 127 do begin if not Nodes.TryGetValue(NodeID(Parent,Parent.GetValue<Integer>('parent_node')),Parent) then Break;Path:=Parent.GetValue<string>('name')+'/'+Path;end;
     Target:=Component.GetValue<string>('source')+'|'+Path;Identity:=TDPHActionPurpose.Identity(Target);
     Row:=Component.Clone as TJSONObject;Rows.AddElement(Row);Row.AddPair('action_id',Identity).AddPair('target',Target).AddPair('record_only',TJSONBool.Create(False));
     Key:='';Matches:=0;
     for W in AView.Document.GetValue<TJSONArray>('semantics.symbols') do begin S:=W as TJSONObject;
      if (S.GetValue<string>('kind')='component') and SameText(S.GetValue<string>('range.source'),Component.GetValue<string>('source')) and (S.GetValue<Integer>('range.start')=Component.GetValue<Integer>('range.start')) then begin Key:=S.GetValue<string>('key');Inc(Matches);end;
     end;
     if Matches<>1 then Key:='';Row.AddPair('target_key',Key);
     if not Seen.TryGetValue(Identity,Occurrences) then Occurrences:=0;Seen.AddOrSetValue(Identity,Occurrences+1);
    end;
   end;
   for V in Rows do begin Row:=V as TJSONObject;Row.AddPair('ambiguous_target',TJSONBool.Create(Seen[Row.GetValue<string>('action_id')]>1));end;
   if AKnowledge<>nil then for V in AKnowledge do begin Saved:=V as TJSONObject;R:=TJSONObject.ParseJSONValue(Saved.GetValue<string>('structured_json','{}')) as TJSONObject;
    try
     if (R=nil) or (R.GetValue<string>('record_type','')<>'action_purpose') then Continue;
     Identity:=R.GetValue<string>('fields.action_id');if Seen.ContainsKey(Identity) then Continue;
     Row:=TJSONObject.Create;Rows.AddElement(Row);Row.AddPair('action_id',Identity).AddPair('target',R.GetValue<string>('fields.target')).AddPair('target_key',R.GetValue<string>('fields.target_key','')).AddPair('name',R.GetValue<string>('fields.action_name')).AddPair('form',R.GetValue<string>('fields.screen','')).AddPair('record_only',TJSONBool.Create(True));
    finally R.Free;end;
   end;
  except Result.Free;raise;end;
 finally Seen.Free;Nodes.Free;end;
end;
class function TDPHActionPurposes.Describe(ARow:TJSONObject;AKnowledge:TJSONArray):string;
var V:TJSONValue;Saved:TJSONObject;
begin
 Result:='ACTION PURPOSE '+ARow.GetValue<string>('target')+sLineBreak+'Identity: '+ARow.GetValue<string>('action_id')+sLineBreak;
 if ARow.GetValue<Boolean>('record_only') then begin
  if ARow.GetValue<string>('action_id').StartsWith('task:') then Result:=Result+'Project task: no automatic UI mapping.'+sLineBreak else Result:=Result+'Historical/unresolved target: no matching UI object in this capture. Review its source links; business text is preserved.'+sLineBreak;
 end else begin
  Result:=Result+'Captured '+ARow.GetValue<string>('name')+' : '+ARow.GetValue<string>('class')+' | source '+ARow.GetValue<string>('source')+':'+IntToStr(ARow.GetValue<Integer>('range.line'))+sLineBreak+'SHA-256 '+ARow.GetValue<string>('source_hash')+' | generation '+ARow.GetValue('generation_id').Value+sLineBreak+'CAPTURED PRESENTATION AND TRIGGERS'+sLineBreak;
  for V in ARow.GetValue<TJSONArray>('properties') do if MatchText(V.GetValue<string>('name'),['Caption','Text','Hint','Action','OnClick','OnExecute','OnPopup','OnKeyDown','OnKeyPress']) then Result:=Result+V.GetValue<string>('name')+' = '+V.GetValue<string>('value')+sLineBreak;
 end;
 if ARow.GetValue<Boolean>('ambiguous_target',False) then Result:=Result+'Ambiguous captured path: duplicate object names prevent a unique purpose mapping. Edit purpose and Explain are disabled; inspect the source or use a project task.'+sLineBreak;
 Result:=Result+sLineBreak+'ATTRIBUTED BUSINESS GUIDANCE'+sLineBreak;Saved:=FindRecord(AKnowledge,ARow.GetValue<string>('action_id'));
 if Saved=nil then Result:=Result+'Purpose not recorded. Click Edit purpose to ask a knowledgeable contributor for the action name, purpose, prerequisites, steps, expected outcome and evidence. Do not infer business intent from a caption or handler name.'
 else Result:=Result+Saved.GetValue<string>('body')+sLineBreak+'State: '+Saved.GetValue<string>('state')+' | revision: '+Saved.GetValue<string>('revision')+' | generation: '+Saved.GetValue<string>('source_generation')+sLineBreak+'Original contributor: '+Saved.GetValue<string>('owner','')+' | revision editor: '+Saved.GetValue<string>('editor','')+' | reviewer: '+Saved.GetValue<string>('reviewer','')+sLineBreak+'Open in Knowledge for immutable history, exact source links and named review. Editing reopens review.';
end;
end.
