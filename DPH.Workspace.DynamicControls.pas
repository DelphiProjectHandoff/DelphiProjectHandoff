unit DPH.Workspace.DynamicControls;
interface
uses System.JSON, DPH.Workspace.Model;
type
 TDPHDynamicControls = class
   class function Inspect(AView:TDPHWorkspaceView):TJSONObject; static;
   class function Describe(ARow:TJSONObject):string; static;
 end;
implementation
uses System.SysUtils, System.StrUtils, System.Generics.Collections;
class function TDPHDynamicControls.Inspect(AView:TDPHWorkspaceView):TJSONObject;
var V:TJSONValue; S,R,T,Row,Link:TJSONObject; Rows,Links:TJSONArray;
    Indexed:TObjectDictionary<string,TList<TJSONObject>>; Items:TList<TJSONObject>; Key:string;
begin
 Result:=TJSONObject.Create; Rows:=TJSONArray.Create; Result.AddPair('rows',Rows);
 Result.AddPair('qualification','Source creation sites, not observed runtime controls. One site may run zero, one or many times. Owner means lifetime ownership; Parent means visual containment. Lexical references do not establish executed order, reaching definitions, aliases, final layout or actual event dispatch. Unsupported factories, with scopes, casts, indirect handles and cross-routine mutations require review. Reassess older captures to obtain new relationships.');
 Indexed:=TObjectDictionary<string,TList<TJSONObject>>.Create([doOwnsValues]);
 try
  try
  for V in AView.Document.GetValue<TJSONArray>('semantics.relationships') do begin
   R:=V as TJSONObject; Key:=R.GetValue<string>('from');
   if not MatchText(R.GetValue<string>('kind'),['assigned_to','constructor_owner','dynamic_parent','dynamic_event','dynamic_property','dynamic_assignment_ambiguous']) then Continue;
   if not Indexed.TryGetValue(Key,Items) then begin Items:=TList<TJSONObject>.Create; Indexed.Add(Key,Items); end; Items.Add(R);
  end;
  for V in AView.Document.GetValue<TJSONArray>('semantics.symbols') do begin
   S:=V as TJSONObject; if S.GetValue<string>('kind')<>'dynamic_control' then Continue;
   Row:=S.Clone as TJSONObject; Rows.AddElement(Row); Row.AddPair('generation_id',AView.Document.GetValue('generation_id').Clone as TJSONValue);
   Row.AddPair('runtime_instances','unknown / unobserved'); Links:=TJSONArray.Create; Row.AddPair('links',Links);
   if Indexed.TryGetValue(S.GetValue<string>('key'),Items) then for R in Items do begin
    Link:=R.Clone as TJSONObject; Links.AddElement(Link);
    T:=AView.Symbol(R.GetValue<string>('to','')); if T<>nil then Link.AddPair('target',T.Clone as TJSONObject);
   end;
  end;
  Result.AddPair('total',TJSONNumber.Create(Rows.Count));
 except Result.Free; raise;
 end;
 finally Indexed.Free; end;
end;
class function TDPHDynamicControls.Describe(ARow:TJSONObject):string;
var V:TJSONValue; Link,Target:TJSONObject;
begin
 Result:='CREATION SITE '+ARow.GetValue<string>('name')+sLineBreak+
 'Constructed class: '+ARow.GetValue<string>('type')+sLineBreak+
 'Runtime instances: '+ARow.GetValue<string>('runtime_instances')+sLineBreak+
 'Generation: '+ARow.GetValue('generation_id').Value+sLineBreak+
 'Source: '+ARow.GetValue<string>('range.source')+':'+IntToStr(ARow.GetValue<Integer>('range.line'))+' | byte '+IntToStr(ARow.GetValue<Integer>('range.start'))+sLineBreak+
 'SHA-256: '+ARow.GetValue<string>('source_hash')+sLineBreak+
 'Condition: '+ARow.GetValue<string>('condition')+sLineBreak+sLineBreak+'CAPTURED RELATIONSHIPS'+sLineBreak;
 for V in ARow.GetValue<TJSONArray>('links') do begin
  Link:=V as TJSONObject; Result:=Result+Link.GetValue<string>('kind')+' | '+Link.GetValue<string>('label')+' ['+Link.GetValue<string>('resolution')+']'+sLineBreak+
   '  '+Link.GetValue<string>('range.source')+':'+IntToStr(Link.GetValue<Integer>('range.line'))+' | '+Link.GetValue<string>('rule')+sLineBreak;
  if Link.TryGetValue<TJSONObject>('target',Target) then Result:=Result+'  Reference target: '+Target.GetValue<string>('name')+' ('+Target.GetValue<string>('kind')+') | '+Target.GetValue<string>('range.source')+':'+IntToStr(Target.GetValue<Integer>('range.line'))+' | SHA-256 '+Target.GetValue<string>('source_hash')+sLineBreak;
 end;
 if ARow.GetValue<TJSONArray>('links').Count=0 then Result:=Result+'No supported relationships captured. Reassess older captures; inspect the constructor source.'+sLineBreak;
 Result:=Result+sLineBreak+'HOW TO READ THIS'+sLineBreak+
 'A constructor argument can name an owner without making that owner the visual parent. Parent assignments are separate. nil is an explicit empty-reference expression, not an observed runtime result. Event links identify candidate routine declarations, not proof that an event fired. A reused handle or assignment before construction is marked ambiguous rather than assigned to one instance. Properties are captured expressions, not evaluated values. Missing links do not prove absence. Explain creation site opens its captured object; Explain reference opens the selected declaration. Use Source from Explain for verified attached code.';
end;
end.
