from pathlib import Path
r=Path.cwd()
p=r/'DPH.Workspace.DatabaseConnections.pas';s=p.read_text(encoding='utf-8-sig')
s=s.replace('    class procedure AttachTransactionPaths','    class procedure AppendDataRules(AView:TDPHWorkspaceView;AInventory:TJSONObject); static;\n    class procedure AttachTransactionPaths',1)
s=s.replace('      AttachTransactionPaths(AView,Result);','      AttachTransactionPaths(AView,Result);\n      AppendDataRules(AView,Result);',1)
method=r"""class procedure TDPHDatabaseConnections.AppendDataRules(AView:TDPHWorkspaceView;AInventory:TJSONObject);
var Rows,Symbols,Relations,Flows,Nodes:TJSONArray;V,F,P,C,E,B,N,X:TJSONValue;
    Owner,FileRow,PropertyNode,Rule,Handler,Flow,Symbol,ReferenceRow:TJSONObject;
    BySymbol:TDictionary<string,TJSONObject>;Hooks:TObjectDictionary<string,TList<TJSONObject>>;
    RoutineFlows:TObjectDictionary<string,TList<TJSONObject>>;List:TList<TJSONObject>;
    Original,I,Parent,Count,SplitAt:Integer;Key,Name,Text,Kind,ID,HandlerKey,ExpressionText:string;
    Seen:TDictionary<string,Boolean>;Truncated:Boolean;
  function Safe(const S:string):string;
  var J:Integer;Quoted,Comment:Boolean;Closer:string;
  begin
   Result:='';J:=1;Quoted:=False;Comment:=False;Closer:='';
   while J<=Length(S) do begin
    if Comment then begin
     if Copy(S,J,Length(Closer))=Closer then begin Inc(J,Length(Closer));Comment:=False;end else Inc(J);Continue;
    end;
    if S[J]='''' then begin
     Result:=Result+'[literal omitted]';Inc(J);Quoted:=True;
     while J<=Length(S) do begin
      if S[J]='''' then begin Inc(J);if (J<=Length(S)) and (S[J]='''') then Inc(J) else begin Quoted:=False;Break;end;end else Inc(J);
     end;
     Continue;
    end;
    if S[J]='{' then begin Comment:=True;Closer:='}';Inc(J);Continue;end;
    if Copy(S,J,2)='(*' then begin Comment:=True;Closer:='*)';Inc(J,2);Continue;end;
    if Copy(S,J,2)='//' then begin while (J<=Length(S)) and not CharInSet(S[J],[#10,#13]) do Inc(J);Continue;end;
    if S[J]='#' then begin
     Result:=Result+'[character code omitted]';Inc(J);while (J<=Length(S)) and CharInSet(S[J],['0'..'9','A'..'F','a'..'f','$']) do Inc(J);Continue;
    end;
    Result:=Result+S[J];Inc(J);
   end;
   Result:=Trim(Result);if Length(Result)>2048 then Result:=Copy(Result,1,2048)+' [expression truncated]';
  end;
  function NewRule(const AKind,AName,ASource,AHash:string;ARange:TJSONObject;AOwner:TJSONObject):TJSONObject;
  begin
   Result:=nil;if Rows.Count>=10000 then begin Truncated:=True;Exit;end;
   ID:='rule:'+IntToStr(Rows.Count);Result:=TJSONObject.Create;Rows.AddElement(Result);Inc(Count);
   Result.AddPair('id',ID).AddPair('name',AName).AddPair('path',AOwner.GetValue<string>('path')+' / '+AName).AddPair('class',AKind).AddPair('role','data rule');
   Result.AddPair('rule_kind',AKind).AddPair('source',ASource).AddPair('source_hash',AHash).AddPair('range',ARange.Clone as TJSONValue).AddPair('generation_id',AView.Document.GetValue('generation_id').Clone as TJSONValue);
   Result.AddPair('declaration','captured rule evidence').AddPair('availability','source candidate, not enforced behavior').AddPair('configuration',TJSONArray.Create).AddPair('links',TJSONArray.Create).AddPair('used_by',TJSONArray.Create);
   Result.AddPair('input','unknown').AddPair('output','unknown').AddPair('constraint','unknown').AddPair('expression','').AddPair('condition','');
   Result.AddPair('unknowns','This is captured configuration or source evidence. Actual values, event dispatch, inherited defaults, validation outcome, database constraints, aliases and external effects remain unobserved. Handler context is not proof that every statement validates its associated field.');
   Result.GetValue<TJSONArray>('links').AddElement(TJSONObject.Create.AddPair('property','rule context').AddPair('reference',AOwner.GetValue<string>('path')).AddPair('target_id',AOwner.GetValue<string>('id')).AddPair('resolution','exact captured context, not proven field effect'));
   AOwner.GetValue<TJSONArray>('used_by').AddElement(TJSONObject.Create.AddPair('id',ID).AddPair('name',Result.GetValue<string>('path')).AddPair('property','rule evidence'));
  end;
  procedure SetText(ARow:TJSONObject;const AName,AValue:string);
  begin ARow.RemovePair(AName).Free;ARow.AddPair(AName,AValue);end;
  function SymbolRow(const AKey:string):TJSONObject;
  var S:TJSONObject;
  begin
   Result:=nil;if not BySymbol.TryGetValue(AKey,S) then Exit;
   for X in Rows do if X.GetValue<string>('id')=AKey then Exit(X as TJSONObject);
   if Rows.Count>=10000 then begin Truncated:=True;Exit;end;
   Result:=TJSONObject.Create;Rows.AddElement(Result);
   Result.AddPair('id',AKey).AddPair('name',S.GetValue<string>('name')).AddPair('path',S.GetValue<string>('name')).AddPair('class',S.GetValue<string>('type')).AddPair('role','rule declaration');
   Result.AddPair('source',S.GetValue<string>('range.source')).AddPair('source_hash',S.GetValue<string>('source_hash')).AddPair('range',S.GetValue('range').Clone as TJSONValue).AddPair('generation_id',AView.Document.GetValue('generation_id').Clone as TJSONValue);
   Result.AddPair('declaration',S.GetValue<string>('kind')).AddPair('availability','captured declaration').AddPair('configuration',TJSONArray.Create).AddPair('links',TJSONArray.Create).AddPair('used_by',TJSONArray.Create).AddPair('unknowns','Lexical declaration only; reaching definitions, runtime values and dispatch are unobserved.');
  end;
  procedure LinkSymbol(ARow:TJSONObject;const AKey,AProperty:string);
  var Target:TJSONObject;
  begin
   Target:=SymbolRow(AKey);if Target=nil then Exit;
   ARow.GetValue<TJSONArray>('links').AddElement(TJSONObject.Create.AddPair('property',AProperty).AddPair('reference',Target.GetValue<string>('path')).AddPair('target_id',Target.GetValue<string>('id')).AddPair('resolution','captured lexical relation; not reaching-value proof'));
   Target.GetValue<TJSONArray>('used_by').AddElement(TJSONObject.Create.AddPair('id',ARow.GetValue<string>('id')).AddPair('name',ARow.GetValue<string>('path')).AddPair('property',AProperty));
  end;
begin
 Rows:=AInventory.GetValue<TJSONArray>('rows');Original:=Rows.Count;Count:=0;Truncated:=False;
 Symbols:=AView.Document.GetValue<TJSONArray>('semantics.symbols');Relations:=AView.Document.GetValue<TJSONArray>('semantics.relationships');Flows:=AView.Document.GetValue<TJSONArray>('semantics.flow_nodes');
 BySymbol:=TDictionary<string,TJSONObject>.Create;Hooks:=TObjectDictionary<string,TList<TJSONObject>>.Create([doOwnsValues]);RoutineFlows:=TObjectDictionary<string,TList<TJSONObject>>.Create([doOwnsValues]);Seen:=TDictionary<string,Boolean>.Create;
 try
  for V in Symbols do BySymbol.Add(V.GetValue<string>('key'),V as TJSONObject);
  for V in Relations do if V.GetValue<string>('kind')='binds' then begin
   Key:=V.GetValue<string>('from');if not Hooks.TryGetValue(Key,List) then begin List:=TList<TJSONObject>.Create;Hooks.Add(Key,List);end;List.Add(V as TJSONObject);
  end;
  for V in Flows do begin Key:=V.GetValue<string>('routine');if not RoutineFlows.TryGetValue(Key,List) then begin List:=TList<TJSONObject>.Create;RoutineFlows.Add(Key,List);end;List.Add(V as TJSONObject);end;
  for I:=0 to Original-1 do begin
   Owner:=Rows.Items[I] as TJSONObject;if not MatchText(Owner.GetValue<string>('role'),['persistent field','dataset','bound control']) then Continue;
   for F in AView.Document.GetValue<TJSONArray>('syntax.files') do begin
    FileRow:=F as TJSONObject;if FileRow.GetValue<string>('path')<>Owner.GetValue<string>('source') then Continue;
    if not FileRow.TryGetValue<TJSONArray>('ir.nodes',Nodes) then Continue;Parent:=-1;
    for P in Nodes do if MatchText(P.GetValue<string>('kind'),['object','inherited','inline']) and (P.GetValue<Integer>('start')=Owner.GetValue<Integer>('range.start')) then begin Parent:=Nodes.IndexOf(P);Break;end;
    if Parent<0 then Continue;
    for P in Nodes do begin
     PropertyNode:=P as TJSONObject;if PropertyNode.GetValue<Integer>('parent')<>Parent then Continue;
     Name:=PropertyNode.GetValue<string>('name');
     if (PropertyNode.GetValue<string>('kind')='property') and (Owner.GetValue<string>('role')='persistent field') and MatchText(Name,['Required','ReadOnly','Size','Precision','MinValue','MaxValue','DefaultExpression','CustomConstraint','ConstraintErrorMessage','EditMask']) then begin
      Rule:=NewRule('declared field constraint',Name,Owner.GetValue<string>('source'),Owner.GetValue<string>('source_hash'),TJSONObject.Create.AddPair('source',Owner.GetValue<string>('source')).AddPair('start',PropertyNode.GetValue('start').Clone as TJSONValue).AddPair('end',PropertyNode.GetValue('end').Clone as TJSONValue).AddPair('line',PropertyNode.GetValue('line').Clone as TJSONValue).AddPair('column',PropertyNode.GetValue('column').Clone as TJSONValue),Owner);
      if Rule=nil then Continue;Text:=Safe(PropertyNode.GetValue<string>('value'));SetText(Rule,'constraint',Name+' = '+Text);SetText(Rule,'output',Owner.GetValue<string>('path'));SetText(Rule,'condition',PropertyNode.GetValue<string>('condition',''));Continue;
     end;
     if (PropertyNode.GetValue<string>('kind')<>'event_binding') or not MatchText(Name,['OnValidate','OnSetText','OnGetText','BeforePost','BeforeInsert','BeforeEdit','OnCalcFields','OnNewRecord','OnChange','OnExit','OnValidating']) then Continue;
     Key:='';for E in Symbols do if (E.GetValue<string>('kind')='event') and (E.GetValue<string>('range.source')=Owner.GetValue<string>('source')) and (E.GetValue<Integer>('range.start')=PropertyNode.GetValue<Integer>('start')) then begin Key:=E.GetValue<string>('key');Break;end;
     Rule:=NewRule('validation or conversion hook',Name,Owner.GetValue<string>('source'),Owner.GetValue<string>('source_hash'),Owner.GetValue<TJSONObject>('range'),Owner);if Rule=nil then Continue;
     Rule.RemovePair('range').Free;Rule.AddPair('range',TJSONObject.Create.AddPair('source',Owner.GetValue<string>('source')).AddPair('start',PropertyNode.GetValue('start').Clone as TJSONValue).AddPair('end',PropertyNode.GetValue('end').Clone as TJSONValue).AddPair('line',PropertyNode.GetValue('line').Clone as TJSONValue).AddPair('column',PropertyNode.GetValue('column').Clone as TJSONValue));
     SetText(Rule,'expression',Name+' = '+Safe(PropertyNode.GetValue<string>('value')));SetText(Rule,'condition',PropertyNode.GetValue<string>('condition',''));HandlerKey:='';
     if Hooks.TryGetValue(Key,List) and (List.Count=1) then HandlerKey:=List[0].GetValue<string>('to','');
     if (HandlerKey='') or not BySymbol.TryGetValue(HandlerKey,Handler) then begin SetText(Rule,'constraint','Handler unresolved or ambiguous; no body invented.');Continue;end;
     LinkSymbol(Rule,HandlerKey,'handler');SetText(Rule,'constraint','Serialized event binding; runtime dispatch and successful validation remain unverified.');
     if not RoutineFlows.TryGetValue(HandlerKey,List) then Continue;
     for Flow in List do begin
      Kind:=Flow.GetValue<string>('kind');ExpressionText:=Flow.GetValue<string>('expression');SplitAt:=Pos('; ',ExpressionText);
      if MatchText(Kind,['entry','normal_exit','exception_exit','exception_dispatch','try','for','with','case_arm','case_default']) then Continue;
      if MatchText(Kind,['if','while','repeat','case']) then Text:='validation condition candidate'
      else if MatchText(Kind,['raise','exit']) then Text:='validation exit or error candidate'
      else if SplitAt>0 then Text:='transformation assignment candidate' else Continue;
      Key:=Owner.GetValue<string>('id')+'|'+HandlerKey+'|'+Flow.GetValue('range.start').Value+'|'+Text;
      if Seen.ContainsKey(Key) then Continue;Seen.Add(Key,True);
      Rule:=NewRule(Text,Name+' / line '+Flow.GetValue('range.line').Value,Flow.GetValue<string>('range.source'),Flow.GetValue<string>('source_hash'),Flow.GetValue<TJSONObject>('range'),Owner);if Rule=nil then Continue;
      LinkSymbol(Rule,HandlerKey,'handler');SetText(Rule,'expression',Safe(ExpressionText));
      if Text='transformation assignment candidate' then begin SetText(Rule,'output',Safe(Copy(ExpressionText,1,SplitAt-1)));SetText(Rule,'input',Safe(Copy(ExpressionText,SplitAt+2,MaxInt)));end
      else SetText(Rule,'constraint',Safe(ExpressionText));
      for B in Relations do if (B.GetValue<string>('from')=HandlerKey) and MatchText(B.GetValue<string>('kind'),['reads','writes']) and
       (B.GetValue<string>('range.source')=Flow.GetValue<string>('range.source')) and (B.GetValue<Integer>('range.start')>=Flow.GetValue<Integer>('range.start')) and (B.GetValue<Integer>('range.end')<=Flow.GetValue<Integer>('range.end')) then begin
       Key:=B.GetValue<string>('to','');if Key<>'' then LinkSymbol(Rule,Key,IfThen(B.GetValue<string>('kind')='writes','lexical output','lexical input'));
      end;
     end;
    end;
   end;
  end;
  AInventory.AddPair('data_rule_count',TJSONNumber.Create(Count)).AddPair('data_rules_truncated',TJSONBool.Create(Truncated));
 finally Seen.Free;RoutineFlows.Free;Hooks.Free;BySymbol.Free;end;
end;

"""
assert 'class procedure TDPHDatabaseConnections.AppendDataRules' not in s
s=s.replace('class procedure TDPHDatabaseConnections.ResolveFields',method+'class procedure TDPHDatabaseConnections.ResolveFields',1)
needle="  Result:=Result+sLineBreak+'UNKNOWNS AND NEXT INVESTIGATION'"
s=s.replace(needle,"  if ARow.GetValue<string>('role')='data rule' then Result:='DATA VALIDATION AND TRANSFORMATION EVIDENCE'+sLineBreak+ARow.GetValue<string>('rule_kind')+sLineBreak+'Input expression: '+ARow.GetValue<string>('input')+sLineBreak+'Output expression: '+ARow.GetValue<string>('output')+sLineBreak+'Constraint: '+ARow.GetValue<string>('constraint')+sLineBreak+'Captured expression: '+ARow.GetValue<string>('expression')+sLineBreak+'Conditional compilation: '+ARow.GetValue<string>('condition')+sLineBreak+'Candidate evidence only. Follow reference opens context, handler or lexical declaration; Source opens the hash-checked location.'+sLineBreak+sLineBreak+Result;\n"+needle,1)
p.write_text(s,encoding='utf-8')
p=r/'DPH.UI.Main.fmx';s=p.read_text();s=s.replace(" 'transaction operation')"," 'transaction operation'\n 'data rule'\n 'rule declaration')",1);p.write_text(s,encoding='utf-8')
p=r/'DPH.UI.Main.pas';s=p.read_text(encoding='utf-8-sig');needle="Row.GetValue<string>('engine.server_version'),DatabaseInventoryFilter.Text.Trim)";assert needle in s;s=s.replace(needle,"Row.GetValue<string>('engine.server_version')+' '+Row.GetValue<string>('expression','')+' '+Row.GetValue<string>('constraint','')+' '+Row.GetValue<string>('input','')+' '+Row.GetValue<string>('output',''),DatabaseInventoryFilter.Text.Trim)",1);p.write_text(s,encoding='utf-8-sig')
print('Data-rule inventory implementation applied')
