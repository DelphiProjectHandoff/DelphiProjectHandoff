unit DPH.Analysis.Explanations;

interface
uses System.SysUtils, System.JSON, System.Generics.Collections;
type
  // A deterministic explanation of captured evidence, never an external AI call.
  TDPHExplanationModel = class
  private
    FFacts: TJSONObject;
    FSymbols: TDictionary<string,TJSONObject>;
    FOutgoing,FIncoming,FFlow,FNext: TObjectDictionary<string,TList<TJSONObject>>;
    function Link(const AKey: string): string;
    function Citation(ARow: TJSONObject): string;
    function RelationText(ARow: TJSONObject; AReverse: Boolean): string;
    function Page(const ATitle,ABody: string): string;
    function Prose(const AText: string): string;
  public
    constructor Create(AFacts: TJSONObject);
    destructor Destroy; override;
    class function Encode(const AText: string): string; static;
    function ObjectText(const AKey: string): string;
    function ObjectHTML(const AKey: string): string;
    function ObjectLessonHTML(const AKey: string): string;
    function RoutineLesson(const AKey: string): string;
    function TopicText(AIndex: Integer): string;
    function TopicHTML(AIndex: Integer): string;
    function LessonHTML(AIndex: Integer): string;
    function ApplicationRouteHTML(AIndex: Integer): string;
    function ProjectMapHTML: string;
    function FlowSVG(const AKey: string): string;
    function FlowHTML(const AKey: string): string;
    function GraphHTML(AGraph: TJSONObject): string;
    function TraceHTML(const AKey: string): string;
    class function TopicTitle(AIndex: Integer): string; static;
    class function ApplicationRouteTitle(AIndex: Integer): string; static;
  end;
implementation
uses System.StrUtils, System.Hash, System.Math, System.Classes, System.Generics.Defaults,
  System.IOUtils, System.NetEncoding, DPH.Workspace.Graphs;

class function TDPHExplanationModel.Encode(const AText: string): string;
begin Result:=AText.Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;').Replace('"','&quot;').Replace('''','&#39;'); end;
constructor TDPHExplanationModel.Create(AFacts: TJSONObject);
var V: TJSONValue; R: TJSONObject; Key: string; Rows: TList<TJSONObject>;
begin
  inherited Create; FFacts:=AFacts;
  FSymbols:=TDictionary<string,TJSONObject>.Create;
  FOutgoing:=TObjectDictionary<string,TList<TJSONObject>>.Create([doOwnsValues]);
  FIncoming:=TObjectDictionary<string,TList<TJSONObject>>.Create([doOwnsValues]);
  FFlow:=TObjectDictionary<string,TList<TJSONObject>>.Create([doOwnsValues]);
  FNext:=TObjectDictionary<string,TList<TJSONObject>>.Create([doOwnsValues]);
  for V in FFacts.GetValue<TJSONArray>('symbols') do begin R:=V as TJSONObject; FSymbols.Add(R.GetValue<string>('key'),R); end;
  for V in FFacts.GetValue<TJSONArray>('relationships') do begin
    R:=V as TJSONObject; Key:=R.GetValue<string>('from');
    if not FOutgoing.TryGetValue(Key,Rows) then begin Rows:=TList<TJSONObject>.Create; FOutgoing.Add(Key,Rows); end; Rows.Add(R);
    Key:=R.GetValue<string>('to',''); if Key='' then Continue;
    if not FIncoming.TryGetValue(Key,Rows) then begin Rows:=TList<TJSONObject>.Create; FIncoming.Add(Key,Rows); end; Rows.Add(R);
  end;
  for V in FFacts.GetValue<TJSONArray>('flow_nodes') do begin R:=V as TJSONObject; Key:=R.GetValue<string>('routine');
    if not FFlow.TryGetValue(Key,Rows) then begin Rows:=TList<TJSONObject>.Create; FFlow.Add(Key,Rows); end; Rows.Add(R);
  end;
  for V in FFacts.GetValue<TJSONArray>('flow_edges') do begin R:=V as TJSONObject; Key:=R.GetValue('from').Value;
    if not FNext.TryGetValue(Key,Rows) then begin Rows:=TList<TJSONObject>.Create; FNext.Add(Key,Rows); end; Rows.Add(R);
  end;
  for Rows in FOutgoing.Values do Rows.Sort(TComparer<TJSONObject>.Construct(
    function(const L,R: TJSONObject): Integer
    var LP,RP: Integer;
    begin
      LP:=10; RP:=10;
      if MatchText(L.GetValue<string>('kind'),['calls','renders','static_sql']) then LP:=4;
      if MatchText(R.GetValue<string>('kind'),['calls','renders','static_sql']) then RP:=4;
      if L.GetValue<string>('resolution')='unresolved' then LP:=8;
      if R.GetValue<string>('resolution')='unresolved' then RP:=8;
      if L.GetValue<string>('kind')='schedules' then LP:=2;
      if R.GetValue<string>('kind')='schedules' then RP:=2;
      if L.GetValue<string>('kind')='passes_callback' then LP:=1;
      if R.GetValue<string>('kind')='passes_callback' then RP:=1;
      if L.GetValue<string>('kind')='binds' then LP:=0;
      if R.GetValue<string>('kind')='binds' then RP:=0;
      Result:=CompareValue(LP,RP);
      if Result=0 then Result:=CompareValue(L.GetValue<Int64>('range.start'),R.GetValue<Int64>('range.start'));
      if Result=0 then Result:=CompareStr(L.ToJSON,R.ToJSON);
    end));
end;
destructor TDPHExplanationModel.Destroy;
begin FNext.Free; FFlow.Free; FIncoming.Free; FOutgoing.Free; FSymbols.Free; inherited; end;
function TDPHExplanationModel.Link(const AKey: string): string;
var S: TJSONObject;
begin
  if FSymbols.TryGetValue(AKey,S) then Result:='<a href="#s_'+THashSHA2.GetHashString(AKey)+'"><code>'+Encode(S.GetValue<string>('name'))+'</code></a>'
  else Result:='<small class="unresolved">Unresolved target</small>';
end;
function TDPHExplanationModel.Citation(ARow: TJSONObject): string;
var R: TJSONObject;
begin
  R:=ARow.GetValue<TJSONObject>('range');
  Result:=R.GetValue<string>('source')+':'+R.GetValue('line').Value+' | SHA256 '+ARow.GetValue<string>('source_hash');
end;
function TDPHExplanationModel.RelationText(ARow: TJSONObject; AReverse: Boolean): string;
var Kind,Verb,Target: string; S: TJSONObject;
begin
  Kind:=ARow.GetValue<string>('kind'); Target:=ARow.GetValue<string>('to','');
  if AReverse then Target:=ARow.GetValue<string>('from');
  if FSymbols.TryGetValue(Target,S) then Target:=S.GetValue<string>('name') else Target:=ARow.GetValue<string>('label','unresolved target');
  Verb:=Kind.Replace('_',' ');
  if Kind='calls' then Verb:='contains a call site to';
  if Kind='binds' then Verb:='connects the serialized event to';
  if Kind='shows_form' then Verb:='contains a possible Show action on';
  if Kind='shows_modal_form' then Verb:='contains a possible modal Show action on';
  if Kind='hides_form' then Verb:='contains a possible Hide action on';
  if Kind='closes_form' then Verb:='contains a possible Close request for';
  if Kind='represents' then Verb:='serializes an instance of this declared form class:';
  if Kind='form_instance' then Verb:='has a matching declaration for this serialized form; runtime identity is unverified:';
  if Kind='component_field' then Verb:='matches this declared form field:';
  if Kind='schedules' then Verb:='may schedule asynchronous work in';
  if Kind='prepares_callback' then Verb:='attaches a callback while creating a suspended thread; this site does not prove it starts:';
  if Kind='starts' then Verb:='contains a possible start or dispatch action for';
  if Kind='dispatches' then Verb:='has this possible callback target:';
  if Kind='waits_for' then Verb:='contains a wait for completion of';
  if Kind='requests_cancellation' then Verb:='requests cancellation of; termination is not guaranteed for';
  if Kind='captures' then Verb:='references an outer-scope value whose lifetime requires review:';
  if Kind='assigned_to' then Verb:='is assigned to this handle; later alias state is unverified:';
  if Kind='signals' then Verb:='contains an inferred event signal for';
  if Kind='waits_for_signal' then Verb:='contains an inferred event wait for';
  if Kind='passes_callback' then Verb:='passes this callback as an argument:';
  if Kind='assigns_callback' then Verb:='assigns a procedure reference to';
  if Kind='reads' then Verb:='reads the value of';
  if Kind='writes' then Verb:='may update';
  if Kind='derives_from' then Verb:='has a source expression that uses; the reaching value remains unverified for';
  if Kind='configures' then Verb:='has an inferred configuration connection with';
  if Kind='static_sql' then Verb:='contains static SQL text associated with';
  if Kind='dynamic_sql' then Verb:='builds SQL from inputs that require review for';
  if Kind='renders' then Verb:='has an inferred model-to-renderer connection with';
  if Kind='output_candidate' then Verb:='contains a candidate file-writing site associated with';
  if Kind='imports' then Verb:='declares a unit dependency on';
  if Kind='owns' then Verb:='declares or contains';
  if Kind='creates' then Verb:='has an inferred creation site for';
  if Kind='creates_control_candidate' then Verb:='contains a candidate visual-control creation associated with';
  if Kind='mutates_property' then Verb:='contains a source property change on';
  if Kind='destroys' then Verb:='contains a possible cleanup action for';
  if Kind='raises' then Verb:='contains an explicit raise with this declared exception type:';
  if Kind='catches' then Verb:='declares a handler for; actual exception matching is unobserved for';
  if Kind='test_covers' then Verb:='is explicitly marked as a test and contains a call to; assertions and results are unverified for';
  if Kind='uses_type' then Verb:='declares a value with type';
  if AReverse then Result:=Target+' '+Verb+' this object' else Result:='This object '+Verb+' '+Target;
  Result:=Result+' ['+ARow.GetValue<string>('resolution')+']. Evidence: '+Citation(ARow)+'. Rule: '+ARow.GetValue<string>('rule');
  if ARow.GetValue<string>('condition','')<>'' then Result:=Result+'. Compile condition: '+ARow.GetValue<string>('condition');
end;
class function TDPHExplanationModel.TopicTitle(AIndex: Integer): string;
begin
  case AIndex of
    0: Result:='Start here'; 1: Result:='How it starts'; 2: Result:='Screens and actions';
    3: Result:='Follow an action'; 4: Result:='Decisions and loops';
    5: Result:='Inputs and results'; 6: Result:='How the parts fit';
    7: Result:='Before a change'; 8: Result:='Unanswered points';
    9: Result:='Questions and answers'; 10: Result:='Delphi terms'; 11: Result:='Task walkthroughs';
  else Result:='Project learning guide'; end;
end;
class function TDPHExplanationModel.ApplicationRouteTitle(AIndex: Integer): string;
begin
  case AIndex of
    0: Result:='Meet this app';
    1: Result:='Learn a real task';
    2: Result:='Explore related tasks';
    3: Result:='Resolve unknowns';
  else Result:='Learn this app'; end;
end;
function TDPHExplanationModel.RoutineLesson(const AKey: string): string;
var Rows,Edges,Ordered: TList<TJSONObject>; Targets: TDictionary<string,TJSONObject>;
    N,E,Target: TJSONObject; Text: TStringBuilder; Kind,Meaning,Path,Destination: string; I,J: Integer;
begin
  Result:=''; if not FFlow.TryGetValue(AKey,Rows) then Exit;
  Ordered:=TList<TJSONObject>.Create; Targets:=TDictionary<string,TJSONObject>.Create; Text:=TStringBuilder.Create;
  try
    for N in Rows do begin Ordered.Add(N); Targets.Add(N.GetValue('id').Value,N); end;
    Ordered.Sort(TComparer<TJSONObject>.Construct(function(const L,R: TJSONObject): Integer
    var LP,RP: Integer;
    begin
      LP:=1; RP:=1;
      if L.GetValue<string>('kind')='entry' then LP:=0;
      if R.GetValue<string>('kind')='entry' then RP:=0;
      if MatchText(L.GetValue<string>('kind'),['normal_exit','exception_exit']) then LP:=2;
      if MatchText(R.GetValue<string>('kind'),['normal_exit','exception_exit']) then RP:=2;
      Result:=CompareValue(LP,RP);
      if Result=0 then Result:=CompareValue(L.GetValue<Int64>('range.start'),R.GetValue<Int64>('range.start'));
      if Result=0 then Result:=CompareStr(L.GetValue('id').Value,R.GetValue('id').Value);
    end));
    Text.AppendLine('SOURCE WALKTHROUGH').AppendLine('Read the captured expressions with the possible next paths below. Entries are arranged by source location, not execution order. Cleanup statements can appear more than once because the graph preserves different pending returns, loop transfers and exceptions. A confirmed static edge describes code structure, not an observed run.');
    for I:=0 to Min(Ordered.Count,60)-1 do begin N:=Ordered[I]; Kind:=N.GetValue<string>('kind');
      Meaning:='This is a captured statement expression. Read its calls, inputs and possible writes in the relationships section; the expression alone does not establish the value produced or the business purpose.';
      if Kind='entry' then Meaning:='Start reading this routine here. Follow the enter edge to its first captured statement. This boundary does not prove a caller reaches it.'
      else if Kind='if' then Meaning:='Evaluate the condition. A true result selects the true path; a false result selects the false path. Check both outcomes when changing this condition.'
      else if Kind='while' then Meaning:='Test the condition before another iteration. The body may run zero times. Follow loop_exit to see where work continues after the loop.'
      else if Kind='for' then Meaning:='This counted or enumerated loop has an iteration path and a loop-exit path. Bounds, collection contents and the number of iterations require actual values.'
      else if Kind='repeat' then Meaning:='This is the test after a repeat body. False repeats the body; true leaves it. The body is entered before this test, so source order here is not a starting path.'
      else if Kind='case' then Meaning:='Compare the selector with the captured case arms. Follow a matching arm, the else arm, or the no-match path if present. A listed alternative is not a prediction of its value.'
      else if Kind='case_arm' then Meaning:='These labels select this case arm. Follow case_body to inspect its statements.'
      else if Kind='case_default' then Meaning:='This else arm handles selector values without a matching case label.'
      else if Kind='try' then Meaning:='Enter a protected region. Follow the actual edges through cleanup or possible handlers. Finally cleanup is distinct from handling an exception; the presence of either does not guarantee successful recovery.'
      else if Kind='exception_dispatch' then Meaning:='An exception may reach a handler here. Handler type matching remains conservative; inspect the possibly-unhandled path as well as every possible handler.'
      else if Kind='exit' then Meaning:='Request an early return from this routine. Follow return to inspect any intervening finally cleanup before the normal exit. Evaluating a return expression may itself raise.'
      else if Kind='raise' then Meaning:='Transfer to the exception path. A bare raise can propagate an active exception. Inspect cleanup and handlers rather than treating this as a successful return.'
      else if Kind='break' then Meaning:='Leave the nearest loop, following any intervening cleanup. Later statements in that iteration can be skipped.'
      else if Kind='continue' then Meaning:='Move toward the next iteration of the nearest loop, following any intervening cleanup. Later statements in this iteration can be skipped.'
      else if Kind='goto' then Meaning:='Transfer toward the named label. An unresolved jump target is a coverage gap, not a known continuation.'
      else if Kind='with' then Meaning:='Read the receiver and then its body. Unqualified member binding remains partial; confirm which object each name refers to before editing.'
      else if MatchText(Kind,['asm','opaque','unresolved_jump_target']) then Meaning:='The analyzer cannot fully explain this construct. The alternatives shown are conservative; inspect the source and resolve the gap before relying on a path.'
      else if Kind='normal_exit' then Meaning:='This boundary represents a possible normal return. It does not prove that output values satisfy the intended contract.'
      else if Kind='exception_exit' then Meaning:='This boundary represents a possible exception escaping the routine. It does not prove that any particular run raises an exception.';
      Text.AppendLine.AppendLine('SOURCE POINT '+IntToStr(I+1)+' | '+UpperCase(Kind)+' | LINE '+N.GetValue<Integer>('range.line').ToString);
      if N.GetValue<string>('expression')<>'' then Text.AppendLine('Captured expression: '+N.GetValue<string>('expression'));
      Text.AppendLine(Meaning).AppendLine('Evidence: '+Citation(N));
      if FNext.TryGetValue(N.GetValue('id').Value,Edges) then begin
        for J:=0 to Min(Edges.Count,8)-1 do begin E:=Edges[J]; Path:=E.GetValue<string>('kind'); Destination:='a target outside this captured routine';
          if Targets.TryGetValue(E.GetValue('to').Value,Target) then Destination:=Target.GetValue<string>('kind')+' at line '+Target.GetValue<Integer>('range.line').ToString+' ('+Target.GetValue<string>('expression')+')';
          Text.AppendLine('Possible next path: '+Path+' -> '+Destination+' ['+E.GetValue<string>('resolution')+'].');
        end;
        if Edges.Count>8 then Text.AppendLine(IntToStr(Edges.Count-8)+' further paths omitted here; inspect the full CFG.');
      end else Text.AppendLine('No outgoing CFG edge was captured at this boundary.');
    end;
    if Ordered.Count>60 then Text.AppendLine(IntToStr(Ordered.Count-60)+' source points omitted by the 60-point lesson limit. Use the source and focused CFG for the remainder.');
    Text.AppendLine.AppendLine('CHECK YOUR UNDERSTANDING').AppendLine('Choose one condition above. Identify its possible next lines, then follow each path to a return, loop or exception boundary. Explain which captured reads and writes can be reached. Record the intended outcome with its author; DPH cannot derive business intent or test results from source alone. Before changing cleanup or an early exit, inspect every incoming path to its copied cleanup nodes.');
    Result:=Text.ToString;
  finally Text.Free; Targets.Free; Ordered.Free; end;
end;
function TDPHExplanationModel.ObjectText(const AKey: string): string;
var S,R: TJSONObject; Rows: TList<TJSONObject>; Text: TStringBuilder; V: TJSONValue; Count: Integer;
begin
  if not FSymbols.TryGetValue(AKey,S) then Exit('Select an object to see its explanation.');
  Text:=TStringBuilder.Create;
  try
    Text.AppendLine(S.GetValue<string>('name')).AppendLine;
    Text.AppendLine('WHAT YOU ARE LOOKING AT');
    if S.GetValue<string>('kind')='routine' then Text.AppendLine('A Delphi routine: a named operation. Read its inputs, callers, effects and branches below to understand its role.')
    else if S.GetValue<string>('kind')='component' then Text.AppendLine('A component declared in a form resource. Its serialized properties describe the design, and its event links show where user interaction enters code.')
    else if S.GetValue<string>('kind')='event' then Text.AppendLine('An event binding in a form resource: the connection between an interaction and its declared handler.')
    else if S.GetValue<string>('kind')='anonymous' then Text.AppendLine('An anonymous routine (callback). It is passed or scheduled by other code. Its execution time and thread must not be assumed from a static relationship.')
    else Text.AppendLine('A '+S.GetValue<string>('kind')+' in the captured Delphi project. Use its declarations and relationships below to establish its role.');
    Text.AppendLine('Declared signature: '+S.GetValue<string>('signature'));
    Text.AppendLine('Declared type: '+S.GetValue<string>('type'));
    Text.AppendLine('Source: '+Citation(S));
    Text.AppendLine('Generation: '+FFacts.GetValue('generation_id').Value+' | '+FFacts.GetValue<string>('configuration')+' / '+FFacts.GetValue<string>('platform'));
    if S.GetValue<string>('condition','')<>'' then Text.AppendLine('Compile condition: '+S.GetValue<string>('condition'));
    Text.AppendLine.AppendLine('HOW IT IS REACHED / WHO DEPENDS ON IT'); Count:=0;
    if FIncoming.TryGetValue(AKey,Rows) then for R in Rows do begin
      if R.GetValue<string>('kind')='owns' then Continue;
      Text.AppendLine(RelationText(R,True)); Inc(Count); if Count>=30 then Break;
    end;
    if Count=0 then Text.AppendLine('No incoming relationship was resolved in this capture. This is not proof the object is unused.');
    Text.AppendLine.AppendLine('WHAT IT DOES IN THE CAPTURED CODE'); Count:=0;
    if FOutgoing.TryGetValue(AKey,Rows) then for R in Rows do begin
      if R.GetValue<string>('kind')='owns' then Continue;
      Text.AppendLine(RelationText(R,False)); Inc(Count); if Count>=40 then Break;
    end;
    if Count=0 then Text.AppendLine('No behavioral relationships were extracted. Inspect the source and diagnostics before drawing a conclusion.');
    if FFlow.TryGetValue(AKey,Rows) then begin
      Text.AppendLine.AppendLine('DECISIONS AND EXIT PATHS'); Count:=0;
      for R in Rows do if MatchText(R.GetValue<string>('kind'),['if','while','for','repeat','case','try','try_finally','try_except','raise','exit','exception_exit']) then begin
        Text.AppendLine(R.GetValue<string>('kind')+': '+R.GetValue<string>('expression')+' | '+Citation(R)); Inc(Count); if Count>=30 then Break;
      end;
      if Count=0 then Text.AppendLine('No supported decision node was extracted for this routine.');
    end;
    if S.GetValue('serialized_properties')<>nil then begin Text.AppendLine.AppendLine('FORM PROPERTIES');
      for V in S.GetValue<TJSONArray>('serialized_properties') do begin R:=V as TJSONObject; Text.AppendLine(R.GetValue<string>('name')+' = '+R.GetValue<string>('value')); end;
    end;
    Text.AppendLine.AppendLine(RoutineLesson(AKey));
    Text.AppendLine.AppendLine('BEFORE CHANGING THIS OBJECT');
    Text.AppendLine('Review incoming callers, event bindings, reads/writes and compile conditions. Use Change impact for possible dependents; use the Source and Graphs tabs to inspect the actual code. Reassess after a controlled edit, then review affected notes.');
    Text.AppendLine('Business purpose, expected user results and operational rationale are not established by these static facts. Record the missing explanation as attributed knowledge. Lists above are bounded; use References for further relationships.');
    Result:=Text.ToString;
  finally Text.Free; end;
end;
function TDPHExplanationModel.TraceHTML(const AKey: string): string;
var Queue: TQueue<string>; Depths: TDictionary<string,Integer>; Rows: TList<TJSONObject>; R: TJSONObject;
    Key,Target,TargetLink: string; Depth,Count: Integer; Text: TStringBuilder;
begin
  Queue:=TQueue<string>.Create; Depths:=TDictionary<string,Integer>.Create; Text:=TStringBuilder.Create;
  try
    Queue.Enqueue(AKey); Depths.Add(AKey,0); Count:=0;
    Text.Append('<h2>Follow the work</h2><p>Read each connection from left to right. Callbacks and resolved connections appear first to make the route easier to follow. This is bounded reachability, not proof that branches or callbacks execute in this order.</p><table><tr><th>From</th><th>Connection</th><th>Next object</th><th>Evidence</th></tr>');
    while (Queue.Count>0) and (Count<60) do begin Key:=Queue.Dequeue; Depth:=Depths[Key];
      if not FOutgoing.TryGetValue(Key,Rows) then Continue;
      for R in Rows do begin
        if not MatchText(R.GetValue<string>('kind'),['calls','binds','passes_callback','schedules','assigns_callback','owns',
          'enters','initializes','finalizes','prepares_callback','starts','dispatches','waits_for','requests_cancellation','signals','waits_for_signal']) then Continue;
        Target:=R.GetValue<string>('to','');
        if (R.GetValue<string>('kind')='owns') and ((not FSymbols.ContainsKey(Target)) or (FSymbols[Target].GetValue<string>('kind')<>'event')) then Continue;
        TargetLink:=Link(Target);
        if Target='' then TargetLink:='<code>'+Encode(R.GetValue<string>('label','unknown'))+'</code><br>'+TargetLink;
        Text.Append('<tr><td>'+Link(Key)+'</td><td>'+Encode(R.GetValue<string>('kind').Replace('_',' '))+'<br><span class="badge" data-resolution="'+Encode(R.GetValue<string>('resolution'))+'">'+Encode(R.GetValue<string>('resolution').Replace('_',' '))+'</span></td><td>'+TargetLink+'</td><td>'+Encode(R.GetValue<string>('range.source'))+':'+R.GetValue<Integer>('range.line').ToString+'<details><summary>Exact evidence</summary>'+Encode(Citation(R))+'<br>'+Encode(R.GetValue<string>('rule'))+'</details></td></tr>');
        Inc(Count);
        if (Target<>'') and (Depth<6) and not Depths.ContainsKey(Target) then begin Depths.Add(Target,Depth+1); Queue.Enqueue(Target); end;
        if Count>=60 then Break;
      end;
    end;
    Text.Append('</table>');
    if Count=0 then Text.Append('<p>No supported execution connection was resolved for this selection. Choose a routine or event.</p>');
    if (Count>=60) or (Queue.Count>0) then Text.Append('<p class="warning">Trace limit reached: 60 connections / six levels. Select a downstream object to continue.</p>');
    Result:=Text.ToString;
  finally Text.Free; Depths.Free; Queue.Free; end;
end;
function TDPHExplanationModel.FlowSVG(const AKey: string): string;
var Rows: TList<TJSONObject>; Nodes: TList<TJSONObject>; Positions: TDictionary<string,Integer>; R,N: TJSONObject;
    V: TJSONValue; I,A,B,Y1,Y2: Integer; Text: TStringBuilder; LabelText,Colour: string;
    Outgoing: TObjectDictionary<string,TList<TJSONObject>>; Edges: TList<TJSONObject>; RenderEdges,Collapsed: TJSONArray;
    Keep: TDictionary<string,Boolean>; Seen: TDictionary<string,Integer>; Queue: TQueue<string>;
    E,J: TJSONObject; FromID,Target,Current,InitialKind: string; Distance: Integer; Uncertain: TDictionary<string,Boolean>;
begin
  Result:=''; if not FFlow.TryGetValue(AKey,Rows) then Exit;
  Nodes:=TList<TJSONObject>.Create; Positions:=TDictionary<string,Integer>.Create; Text:=TStringBuilder.Create;
  Collapsed:=nil; Outgoing:=TObjectDictionary<string,TList<TJSONObject>>.Create([doOwnsValues]);
  Keep:=TDictionary<string,Boolean>.Create; Seen:=TDictionary<string,Integer>.Create; Uncertain:=TDictionary<string,Boolean>.Create; Queue:=TQueue<string>.Create;
  try
    // Order source statements by their source byte range, with synthetic exits last.
    for R in Rows do if R.GetValue<string>('kind')='entry' then Nodes.Add(R);
    for R in Rows do if not MatchText(R.GetValue<string>('kind'),['entry','normal_exit','exception_exit']) then Nodes.Add(R);
    Nodes.Sort(TComparer<TJSONObject>.Construct(function(const L,R: TJSONObject): Integer begin Result:=CompareValue(L.GetValue<Int64>('range.start'),R.GetValue<Int64>('range.start')); end));
    for R in Rows do if MatchText(R.GetValue<string>('kind'),['normal_exit','exception_exit']) then Nodes.Add(R);
    RenderEdges:=FFacts.GetValue<TJSONArray>('flow_edges');
    if Nodes.Count>70 then begin
      for R in Rows do begin FromID:=R.GetValue('id').Value;
        if MatchText(R.GetValue<string>('kind'),['entry','normal_exit','exception_exit','if','while','for','repeat','case','try',
          'exception_dispatch','exit','raise','break','continue','goto','asm','opaque','with']) then Keep.AddOrSetValue(FromID,True);
      end;
      for I:=Nodes.Count-1 downto 0 do if not Keep.ContainsKey(Nodes[I].GetValue('id').Value) then Nodes.Delete(I);
      if Nodes.Count>70 then begin Result:='<p class="warning">This routine has more than 70 control nodes even after collapsing straight-line statements. Read the logic summary and source; no incomplete diagram is presented as complete.</p>'; Exit; end;
      for V in RenderEdges do begin E:=V as TJSONObject; FromID:=E.GetValue('from').Value;
        if not Outgoing.TryGetValue(FromID,Edges) then begin Edges:=TList<TJSONObject>.Create; Outgoing.Add(FromID,Edges); end; Edges.Add(E);
      end;
      Collapsed:=TJSONArray.Create;
      for R in Nodes do begin FromID:=R.GetValue('id').Value;
        if not Outgoing.TryGetValue(FromID,Edges) then Continue;
        for E in Edges do begin
          Seen.Clear; Uncertain.Clear; Queue.Clear; Target:=E.GetValue('to').Value; InitialKind:=E.GetValue<string>('kind');
          Seen.Add(Target,0); Uncertain.Add(Target,E.GetValue<string>('resolution')<>'confirmed_static'); Queue.Enqueue(Target);
          while Queue.Count>0 do begin
            Current:=Queue.Dequeue; Distance:=Seen[Current];
            if Keep.ContainsKey(Current) then begin
              J:=TJSONObject.Create; J.AddPair('from',FromID); J.AddPair('to',Current);
              J.AddPair('kind',InitialKind+IfThen(Distance>0,' via '+IntToStr(Distance)+' statements',''));
              J.AddPair('resolution',IfThen(Uncertain[Current] or (Distance>0),'possible_dynamic','confirmed_static')); Collapsed.AddElement(J); Continue;
            end;
            if Distance>=2000 then raise ERangeError.Create('Collapsed CFG traversal limit');
            if Outgoing.ContainsKey(Current) then for N in Outgoing[Current] do begin Target:=N.GetValue('to').Value;
              if not Seen.ContainsKey(Target) then begin Seen.Add(Target,Distance+1);
                Uncertain.Add(Target,Uncertain[Current] or (N.GetValue<string>('resolution')<>'confirmed_static')); Queue.Enqueue(Target);
              end;
            end;
          end;
        end;
      end;
      RenderEdges:=Collapsed;
      Text.Append('<p class="warning">Straight-line statements are collapsed. Each arrow follows captured CFG edges through the stated number of omitted statements. Source retains the full body; this diagram emphasizes decisions and exits.</p>');
    end;
    for I:=0 to Nodes.Count-1 do Positions.Add(Nodes[I].GetValue('id').Value,I);
    Text.Append('<h2>Control-flow diagram</h2><p>Arrows show actual captured CFG edges. Read true/false and loop labels. Orange paths are uncertain; exceptional paths do not prove an exception occurs.</p><div class="diagram"><svg xmlns="http://www.w3.org/2000/svg" width="100%" viewBox="0 0 900 '+IntToStr(Nodes.Count*115+35)+'" role="img" aria-label="Source-derived control flow"><defs><marker id="arrow" markerWidth="8" markerHeight="8" refX="7" refY="3" orient="auto"><path d="M0,0 L0,6 L7,3 z" fill="#146cb4"/></marker></defs>');
    I:=0;
    for V in RenderEdges do begin R:=V as TJSONObject;
      if not Positions.TryGetValue(R.GetValue('from').Value,A) or not Positions.TryGetValue(R.GetValue('to').Value,B) then Continue;
      Y1:=A*115+65; Y2:=B*115+65; Colour:='#146cb4'; if R.GetValue<string>('resolution')<>'confirmed_static' then Colour:='#b95c00';
      Text.Append('<path d="M620 '+IntToStr(Y1)+' H'+IntToStr(655+(I mod 9)*22)+' V'+IntToStr(Y2)+' H620" fill="none" stroke="'+Colour+'" marker-end="url(#arrow)"><title>'+Encode(R.GetValue<string>('kind'))+'</title></path><text x="'+IntToStr(658+(I mod 9)*22)+'" y="'+IntToStr(Y1+16+(I mod 3)*14)+'" font-size="12" fill="'+Colour+'">'+Encode(R.GetValue<string>('kind'))+'</text>'); Inc(I);
    end;
    for I:=0 to Nodes.Count-1 do begin N:=Nodes[I]; LabelText:=N.GetValue<string>('expression');
      Text.Append('<g><title>'+Encode(LabelText)+'</title><rect x="15" y="'+IntToStr(I*115+20)+'" width="600" height="90" rx="8" fill="#eaf3fc" stroke="#146cb4"/><text x="30" y="'+IntToStr(I*115+43)+'" font-size="16" font-weight="bold">'+Encode(N.GetValue<string>('kind'))+' | line '+N.GetValue<Integer>('range.line').ToString+'</text>');
      Text.Append('<text x="30" y="'+IntToStr(I*115+65)+'" font-size="13">'+Encode(Copy(LabelText,1,76))+'</text><text x="30" y="'+IntToStr(I*115+84)+'" font-size="13">'+Encode(Copy(LabelText,77,76))+'</text></g>');
    end;
    Text.Append('</svg></div>'); Result:=Text.ToString;
  finally Queue.Free; Uncertain.Free; Seen.Free; Keep.Free; Outgoing.Free; Collapsed.Free; Text.Free; Positions.Free; Nodes.Free; end;
end;
function TDPHExplanationModel.FlowHTML(const AKey: string): string;
var Body: string;
begin
  Body:=FlowSVG(AKey);
  if Body='' then Body:='<section class="card"><h2>Select a routine</h2><p>A procedure control-flow graph requires a routine with a captured body. Select an operation in Explorer, then return here.</p></section>';
  Result:=Page('Procedure control flow',Body);
end;
function TDPHExplanationModel.GraphHTML(AGraph: TJSONObject): string;
var Nodes,Edges: TJSONArray; Indices: TDictionary<string,Integer>;
    Links: TObjectDictionary<Integer,TList<Integer>>; Targets: TList<Integer>; Queue: TQueue<Integer>;
    Depths,Incoming,Slots,X,Y: TArray<Integer>; I,A,B,Width,Height: Integer;
    V: TJSONValue; Row: TJSONObject; Text: TStringBuilder; LabelText,Kind,Colour,Dash,Href,Tooltip: string;
  procedure Walk;
  var Source,Target: Integer; Destinations: TList<Integer>;
  begin
    while Queue.Count>0 do begin
      Source:=Queue.Dequeue; if not Links.TryGetValue(Source,Destinations) then Continue;
      for Target in Destinations do if Depths[Target]<0 then begin Depths[Target]:=Min(8,Depths[Source]+1); Queue.Enqueue(Target); end;
    end;
  end;
begin
  if AGraph.GetValue<string>('kind')='Business process' then Exit(Page('Business process diagram',TDPHGraphProjection.WorkflowSVG(AGraph)));
  Nodes:=AGraph.GetValue<TJSONArray>('nodes'); Edges:=AGraph.GetValue<TJSONArray>('edges');
  if Nodes.Count=0 then Exit(Page(AGraph.GetValue<string>('kind'),'<section class="card"><h2>No supported graph objects</h2><p>Select an Explorer object or use Whole program, All forms or Project data. Review coverage gaps before inferring that behavior is absent.</p></section>'));
  Indices:=TDictionary<string,Integer>.Create; Links:=TObjectDictionary<Integer,TList<Integer>>.Create([doOwnsValues]); Queue:=TQueue<Integer>.Create; Text:=TStringBuilder.Create;
  try
    SetLength(Depths,Nodes.Count); SetLength(Incoming,Nodes.Count); SetLength(X,Nodes.Count); SetLength(Y,Nodes.Count); SetLength(Slots,9);
    for I:=0 to Nodes.Count-1 do begin Indices.Add(Nodes.Items[I].GetValue<string>('id'),I); Depths[I]:=-1; end;
    for V in Edges do begin Row:=V as TJSONObject;
      if not Indices.TryGetValue(Row.GetValue('from').Value,A) or not Indices.TryGetValue(Row.GetValue('to').Value,B) then Continue;
      if A=B then Continue; Inc(Incoming[B]);
      if not Links.TryGetValue(A,Targets) then begin Targets:=TList<Integer>.Create; Links.Add(A,Targets); end; Targets.Add(B);
    end;
    for I:=0 to Nodes.Count-1 do if Incoming[I]=0 then begin Depths[I]:=0; Queue.Enqueue(I); end; Walk;
    for I:=0 to Nodes.Count-1 do if Depths[I]<0 then begin Depths[I]:=0; Queue.Enqueue(I); Walk; end;
    Width:=700; Height:=160;
    for I:=0 to Nodes.Count-1 do begin X[I]:=25+Depths[I]*380; Y[I]:=25+Slots[Depths[I]]*150; Inc(Slots[Depths[I]]); Width:=Max(Width,X[I]+330); Height:=Max(Height,Y[I]+130); end;
    Text.Append('<section class="card"><p><strong>Static relationship graph.</strong> Blue solid arrows show confirmed source facts; orange dashed arrows show qualified facts. Arrow labels describe the relationship, not runtime order. Scroll the diagram to inspect it. Select a node for details.</p>');
    if AGraph.GetValue<string>('grouping','')<>'' then Text.Append('<p>Grouped by '+Encode(AGraph.GetValue<string>('grouping'))+'. Select a group to inspect its members. Counts cover the bounded captured projection; up to 16 evidence examples accompany each grouped connection.</p>');
    if AGraph.GetValue<Boolean>('truncated') then Text.Append('<p class="warning">This projection is truncated. Missing nodes or arrows do not prove absence of behavior. Focus an object or change the grouping.</p>');
    Text.Append('<div style="overflow:auto;max-height:75vh;border:1px solid #dce5ef"><svg xmlns="http://www.w3.org/2000/svg" width="'+IntToStr(Width)+'" height="'+IntToStr(Height)+'" role="img" aria-label="Captured static relationships"><defs><marker id="blueArrow" markerWidth="10" markerHeight="8" refX="9" refY="4" orient="auto"><path d="M0,0 L10,4 L0,8 Z" fill="#146cb4"/></marker><marker id="orangeArrow" markerWidth="10" markerHeight="8" refX="9" refY="4" orient="auto"><path d="M0,0 L10,4 L0,8 Z" fill="#bc5a00"/></marker></defs>');
    for V in Edges do begin Row:=V as TJSONObject;
      if not Indices.TryGetValue(Row.GetValue('from').Value,A) or not Indices.TryGetValue(Row.GetValue('to').Value,B) then Continue;
      Kind:=Row.GetValue<string>('kind').Replace('_',' '); Colour:='#146cb4'; Dash:=''; Href:='blueArrow';
      if Row.GetValue<string>('resolution','')<>'confirmed_static' then begin Colour:='#bc5a00'; Dash:=' stroke-dasharray="6 4"'; Href:='orangeArrow'; end;
      Tooltip:=Kind+' | '+Row.GetValue<string>('resolution','unverified')+' | '+Row.GetValue<string>('rule','');
      if Row.GetValue<Integer>('relationship_count',1)>1 then Kind:=Kind+' ('+Row.GetValue<Integer>('relationship_count').ToString+')';
      Text.Append('<g><title>'+Encode(Tooltip)+'</title><path d="M'+IntToStr(X[A]+280)+' '+IntToStr(Y[A]+50)+' C'+IntToStr(X[A]+330)+' '+IntToStr(Y[A]+50)+' '+IntToStr(X[B]-50)+' '+IntToStr(Y[B]+50)+' '+IntToStr(X[B])+' '+IntToStr(Y[B]+50)+'" fill="none" stroke="'+Colour+'" stroke-width="1.5"'+Dash+' marker-end="url(#'+Href+')"/><text x="'+IntToStr((X[A]+280+X[B]) div 2)+'" y="'+IntToStr((Y[A]+Y[B]) div 2+38)+'" font-size="11" fill="'+Colour+'">'+Encode(Kind)+'</text></g>');
    end;
    for I:=0 to Nodes.Count-1 do begin Row:=Nodes.Items[I] as TJSONObject; LabelText:=Row.GetValue<string>('label'); Kind:=Row.GetValue<string>('kind','object');
      Href:='#s_'+THashSHA2.GetHashString(Row.GetValue('id').Value);
      if Kind='group' then begin Href:='#g_'+THashSHA2.GetHashString(Row.GetValue('id').Value); Kind:=Row.GetValue<string>('grouping')+' group | '+Row.GetValue<Integer>('member_count').ToString+' members'; end;
      Text.Append('<a href="'+Href+'"><g><title>'+Encode(LabelText)+'</title><rect x="'+IntToStr(X[I])+'" y="'+IntToStr(Y[I])+'" width="280" height="100" rx="8" fill="#eaf3fc" stroke="#146cb4"/><text x="'+IntToStr(X[I]+12)+'" y="'+IntToStr(Y[I]+20)+'" font-size="11" fill="#146cb4">'+Encode(Kind)+'</text><text x="'+IntToStr(X[I]+12)+'" y="'+IntToStr(Y[I]+44)+'" font-size="14" font-weight="bold" fill="#20364a">'+Encode(Copy(LabelText,1,32))+'</text><text x="'+IntToStr(X[I]+12)+'" y="'+IntToStr(Y[I]+65)+'" font-size="13" fill="#20364a">'+Encode(Copy(LabelText,33,32))+'</text>');
      if Row.GetValue<Integer>('member_count',0)>0 then LabelText:=Row.GetValue<Integer>('internal_relationships',0).ToString+' internal source relationships'
      else LabelText:=Row.GetValue<string>('range.source','')+':'+Row.GetValue<Integer>('range.line',0).ToString;
      Text.Append('<text x="'+IntToStr(X[I]+12)+'" y="'+IntToStr(Y[I]+87)+'" font-size="11" fill="#52697c">'+Encode(Copy(LabelText,1,42))+'</text></g></a>');
    end;
    Text.Append('</svg></div></section>'); Result:=Page(AGraph.GetValue<string>('kind'),Text.ToString);
    if AGraph.GetValue<string>('kind')='Data lineage' then begin
     Text.Append('<section class="card"><h2>Unresolved breaks and boundaries</h2><ul>');
     for V in AGraph.GetValue<TJSONArray>('breaks') do Text.Append('<li>'+Encode(V.GetValue<string>('reason'))+'</li>');
     Text.Append('</ul><p>'+Encode(AGraph.GetValue<string>('qualification'))+'</p></section>');
     Result:=Page('Data lineage source candidates',Text.ToString);
    end;
  finally Text.Free; Queue.Free; Links.Free; Indices.Free; end;
end;

function TDPHExplanationModel.Page(const ATitle,ABody: string): string;
var Logo,Directory,ImagePath: string; I: Integer;
begin
  Logo:=''; Directory:=ExtractFilePath(ParamStr(0));
  for I:=0 to 5 do begin
    ImagePath:=TPath.Combine(Directory,'images and icons\DPH-Emblem-128.png');
    if TFile.Exists(ImagePath) then begin
      Logo:='<img class="brand" src="data:image/png;base64,'+
        TNetEncoding.Base64.EncodeBytesToString(TFile.ReadAllBytes(ImagePath))+'" alt="Delphi Project Handoff logo">';
      Break;
    end;
    Directory:=ExtractFileDir(ExcludeTrailingPathDelimiter(Directory));
  end;
  Result:='<!doctype html><html lang="en"><head><meta charset="utf-8"><meta http-equiv="Content-Security-Policy" content="default-src ''none''; style-src ''unsafe-inline''; img-src ''self'' data:; script-src ''none''; connect-src ''none''; base-uri ''none''"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+
    Encode(ATitle)+'</title><style>body{font:16px/1.6 Segoe UI,Arial,sans-serif;color:#20364a;margin:0;background:#f1f5fa}main{max-width:1100px;margin:auto;padding:26px}header{background:#146cb4;color:white;padding:26px;border-bottom:5px solid #f28c28;display:flex;align-items:center;gap:20px}.brand{width:76px;height:76px;object-fit:contain;flex:none}'+
    'h1{font-size:28px;margin:0}body{overflow-wrap:anywhere}*{box-sizing:border-box}'+
    'h2{font-size:21px;color:#146cb4}h3{font-size:18px}'+
    '.card{background:white;border:1px solid #dce5ef;border-radius:9px;padding:20px;margin:16px 0}.badge{display:inline-block;background:#eaf3fc;padding:3px 8px;border-radius:4px;font-size:12px}'+
    '.warning{border-left:5px solid #f28c28;padding:12px;background:#fff3e4}a{color:#146cb4}code{overflow-wrap:anywhere;font-size:13px}'+
    'pre{white-space:pre-wrap;font:15px/1.6 Segoe UI,Arial,sans-serif}table{border-collapse:collapse;table-layout:fixed;width:100%;font-size:13px}td,th{border:1px solid #dce5ef;padding:9px;text-align:left;vertical-align:top;overflow-wrap:anywhere}'+
    'small{color:#53697f}.diagram{overflow:auto}svg text{font-family:Segoe UI,Arial,sans-serif}@media print{body{background:white}main{padding:0}'+
    '.card{break-inside:avoid}}</style></head><body><header>'+Logo+'<div><h1>'+Encode(ATitle)+'</h1><p>'+
    Encode(FFacts.GetValue<string>('project'))+'</p></div></header><main>'+
    IfThen(FFacts.GetValue<Boolean>('stale') or not FFacts.GetValue<Boolean>('analysis_complete'),'<p><small>Some explanations need checking. Ask about unexplained behavior before relying on it.</small></p>','')+ABody+'</main></body></html>';
end;
function TDPHExplanationModel.ObjectHTML(const AKey: string): string;
var S,R: TJSONObject; Body,Kind,Key: string; Text: TStringBuilder; Rows: TList<TJSONObject>; Count,Pass: Integer; V,W: TJSONValue; Linked: Boolean;
begin
  if not FSymbols.TryGetValue(AKey,S) then Exit(Page('Explain this object','<p>Select an Explorer object.</p>'));
  Text:=TStringBuilder.Create;
  try
    Kind:=S.GetValue<string>('kind');
    Text.Append('<section class="card"><span class="badge">'+Encode(Kind)+'</span><h2>Understand this selection</h2>');
    if MatchText(Kind,['routine','anonymous']) then Text.Append('<p>This is a callable piece of Delphi code. Its signature describes declared inputs and result type. The sections below explain how it is reached, what it interacts with, and which branches need your attention.</p>')
    else if MatchText(Kind,['component','event']) then Text.Append('<p>This object comes from a form resource. Its declared properties and event bindings connect the interface to application code. Follow an event into its handler to understand the action behind the control.</p>')
    else Text.Append('<p>This '+Encode(Kind)+' is part of the project structure. Its outgoing relationships describe declarations or dependencies; incoming relationships show where other captured code depends on it.</p>');
    Text.Append('<p><strong>Declared contract:</strong> <code>'+Encode(S.GetValue<string>('signature'))+'</code></p>');
    if S.GetValue<string>('type')<>'' then Text.Append('<p><strong>Type:</strong> <code>'+Encode(S.GetValue<string>('type'))+'</code></p>');
    if S.GetValue<string>('condition','')<>'' then Text.Append('<p class="warning">Compile condition: '+Encode(S.GetValue<string>('condition'))+'</p>');
    Text.Append('<details><summary>Exact source evidence</summary><p>'+Encode(Citation(S))+'</p><p>Variant: '+Encode(S.GetValue<string>('variant'))+'</p></details></section>');
    if (S.GetValue('source_comments')<>nil) and (S.GetValue<TJSONArray>('source_comments').Count>0) then begin
      Text.Append('<section class="card"><h2>What the source author wrote</h2><p>Comments inside or immediately before this declaration. They are source documentation, not independently verified behavior.</p>');
      for V in S.GetValue<TJSONArray>('source_comments') do begin R:=V as TJSONObject;
        Text.Append('<blockquote>'+Encode(R.GetValue<string>('text'))+'</blockquote><details><summary>Comment location</summary><p>'+Encode(Citation(R))+'</p></details>');
      end; Text.Append('</section>');
    end;
    for Pass:=0 to 1 do begin
      Rows:=nil;
      if Pass=0 then begin FIncoming.TryGetValue(AKey,Rows); Text.Append('<section class="card"><h2>How it is reached and used</h2><p>These objects refer to the selection. Inspect callers and event bindings before changing its contract.</p>'); end
      else begin FOutgoing.TryGetValue(AKey,Rows); Text.Append('<section class="card"><h2>What it interacts with</h2><p>Read calls as code locations, reads as inputs and writes as possible effects. Inferred relationships and asynchronous scheduling retain their uncertainty.</p>'); end;
      Count:=0;
      if Rows<>nil then for R in Rows do begin
        Kind:=R.GetValue<string>('kind'); if Kind='owns' then Continue;
        Key:=R.GetValue<string>('to',''); if Pass=0 then Key:=R.GetValue<string>('from');
        Text.Append('<p><span class="badge">'+Encode(Kind.Replace('_',' '))+'</span> '+Link(Key)+' <small>'+Encode(R.GetValue<string>('resolution'))+'</small></p>');
        Text.Append('<details><summary>Why this connection is shown</summary><p>'+Encode(RelationText(R,Pass=0))+'</p></details>');
        Inc(Count); if Count>=30 then Break;
      end;
      if Count=0 then Text.Append('<p>No supported relationship was captured here. This does not prove absence of behavior; inspect source and coverage gaps.</p>');
      if Count>=30 then Text.Append('<p>First 30 relationships shown. The References tab contains the remaining direct relationships.</p>'); Text.Append('</section>');
    end;
    if S.GetValue('serialized_properties')<>nil then begin Text.Append('<section class="card"><h2>Declared interface properties</h2><table><tr><th>Property</th><th>Serialized value</th></tr>');
      for V in S.GetValue<TJSONArray>('serialized_properties') do begin R:=V as TJSONObject; Text.Append('<tr><td>'+Encode(R.GetValue<string>('name'))+'</td><td>'+Encode(R.GetValue<string>('value'))+'</td></tr>'); end; Text.Append('</table></section>');
    end;
    if FFlow.TryGetValue(AKey,Rows) then begin
      Text.Append('<section class="card"><h2>Read the logic</h2><p>These decisions come from the routine body. Inspect each condition against the intended behavior; the analyzer does not know the business reason for it.</p>'); Count:=0;
      for R in Rows do begin Kind:=R.GetValue<string>('kind');
        if not MatchText(Kind,['if','while','repeat','for','case','try','try_finally','try_except','raise','exit']) then Continue;
        Text.Append('<h3>'+Encode(Kind)+' at line '+R.GetValue<Integer>('range.line').ToString+'</h3>');
        if Kind='if' then Text.Append('<p>Evaluates this condition and takes its captured true or false path:</p>')
        else if MatchText(Kind,['while','repeat','for']) then Text.Append('<p>A loop can revisit code. Inspect its condition and loop-exit edges, plus break and continue paths:</p>')
        else if Kind='exit' then Text.Append('<p>An early return can skip later normal statements. Check the captured cleanup path before removing it.</p>')
        else if Kind='raise' then Text.Append('<p>A raise transfers control toward an exception path. A handler or finally block may affect the outcome.</p>')
        else Text.Append('<p>This control construct has alternative or cleanup paths. Read the captured edges and their uncertainty before assuming an order.</p>');
        if R.GetValue<string>('expression')<>'' then Text.Append('<p><code>'+Encode(R.GetValue<string>('expression'))+'</code></p>');
        Text.Append('<details><summary>Source evidence</summary><p>'+Encode(Citation(R))+'</p></details>');
        Inc(Count); if Count>=30 then Break;
      end;
      if Count=0 then Text.Append('<p>No supported decision node was captured. Read the source before interpreting that as simple behavior.</p>');
      if Count>=30 then Text.Append('<p>First 30 decisions shown. Inspect the full routine source and CFG for the remainder.</p>'); Text.Append('</section>');
    end;
    for V in FFacts.GetValue<TJSONArray>('knowledge') do begin R:=V as TJSONObject;
      Linked:=R.GetValue<string>('entity_key','')=AKey;
      for W in R.GetValue<TJSONArray>('links') do if (W as TJSONObject).GetValue<string>('canonical_key','')=AKey then Linked:=True;
      if not Linked then Continue;
      Text.Append('<section class="card"><h2>Attributed knowledge: '+Encode(R.GetValue<string>('title'))+'</h2><p>'+Encode(R.GetValue<string>('state'))+' | '+Encode(R.GetValue<string>('owner'))+'</p><p>'+Encode(R.GetValue<string>('body'))+'</p></section>');
    end;
    Text.Append('<section class="card"><h2>What still needs explanation</h2><p>The business reason, expected user outcome, operational prerequisites and recovery procedure need an attributed answer if they are not recorded above. A symbol name cannot establish them.</p><h3>Before you change it</h3><p>Inspect callers, event bindings, writes and conditional variants. Open Change impact, review linked rules, run authorized project-specific tests, then reassess and review affected notes.</p></section>');
    Body:=Text.ToString;
  finally Text.Free; end;
  Body:=Body+Prose(RoutineLesson(AKey));
  try Body:=Body+TraceHTML(AKey); except on E: Exception do raise EReadError.Create('Trace: '+E.Message); end;
  try Body:=Body+FlowSVG(AKey); except on E: Exception do raise EReadError.Create('Flow: '+E.Message); end;
  Result:=Page(S.GetValue<string>('name'),Body);
end;
function TDPHExplanationModel.ObjectLessonHTML(const AKey: string): string;
const PurposeFields:array[0..7] of string=('action_name','screen','trigger','purpose','preconditions','steps','outcome','exceptions');
      PurposeLabels:array[0..7] of string=('Action name','Screen and user role','What starts it','Why the user needs it','Before you begin','How to use it','Expected result','If something goes wrong');
var Body: TStringBuilder; S,R,Metadata,Fields,Section: TJSONObject; V,W: TJSONValue; Rows,LessonRows: TList<TJSONObject>;
    Kind,DetailHTML,Target,Verb,PropertyName,PropertyValue,Meaning,ControlName,FormName,CaptionText,Excerpt,SourceText: string;
    Count,P,Limit,I,Pass,MatchAt: Integer; Linked,Found: Boolean;
begin
  if not FSymbols.TryGetValue(AKey,S) then Exit(Page('Explain this selection','<p>Choose a screen control, action or operation to begin.</p>'));
  Body:=TStringBuilder.Create;
  try
    Kind:=S.GetValue<string>('kind');
    Body.Append('<section class="card"><h2>Understand this selection</h2><p><strong>'+Encode(S.GetValue<string>('name'))+'</strong></p>');
    if Kind='component' then begin
      ControlName:=S.GetValue<string>('name'); P:=LastDelimiter('.',ControlName);
      if P>0 then ControlName:=Copy(ControlName,P+1,MaxInt);
      FormName:=S.GetValue<string>('name'); P:=LastDelimiter('.',FormName);
      if P>0 then FormName:=Copy(FormName,1,P-1);
      P:=LastDelimiter('.',FormName); if P>0 then FormName:=Copy(FormName,P+1,MaxInt);
      CaptionText:='';
      if S.GetValue<TJSONArray>('serialized_properties',nil)<>nil then
        for V in S.GetValue<TJSONArray>('serialized_properties') do begin
          R:=V as TJSONObject;
          if MatchText(R.GetValue<string>('name',''),['Text','Caption','Hint','TextPrompt']) and
            (R.GetValue<string>('value','').Trim<>'''') and (CaptionText='') then
            CaptionText:=R.GetValue<string>('value','').Trim(['''',' ']).Replace('''''','''');
        end;
      Body.Append('<p>On the saved '+Encode(FormName)+' screen, <strong>'+Encode(ControlName)+'</strong> is a '+
        Encode(S.GetValue<string>('type','control')));
      if CaptionText<>'' then Body.Append(' labelled &ldquo;'+Encode(CaptionText)+'&rdquo;');
      Body.Append('.');
      if ContainsText(S.GetValue<string>('type',''),'Label') then
        Body.Append(' A label identifies nearby information or an input; it does not itself accept a value.');
      Body.Append('</p>');
    end
    else if Kind='event' then Body.Append('<p>This is an event: the connection between an action and the operation that responds to it.</p>')
    else if MatchText(Kind,['routine','anonymous']) then Body.Append('<p>This is an operation in the application. A procedure performs work; a function also returns a result. Read its connections below to see the part it plays.</p>')
    else if Kind='unit' then Body.Append('<p>This is a unit: a source file grouping related definitions and operations.</p>')
    else if MatchText(Kind,['field','variable','local','parameter','property']) then
      Body.Append('<p>This is a '+Encode(Kind)+' that holds or exposes information used by the application.</p>')
    else Body.Append('<p>This '+Encode(Kind)+' is part of the selected application. Its connections help explain where it fits.</p>');
    if S.GetValue<string>('type','')<>'' then
      Body.Append('<p><strong>Declared type:</strong> <code>'+Encode(S.GetValue<string>('type'))+'</code></p>');
    if S.GetValue<string>('signature','')<>'' then
      Body.Append('<p><strong>Declaration:</strong> <code>'+Encode(S.GetValue<string>('signature'))+'</code></p>');
    Body.Append('<p><small>Source: '+Encode(S.GetValue<string>('range.source',''))+':'+
      IntToStr(S.GetValue<Integer>('range.line',0))+'</small></p>');
    Body.Append('</section>');
    if (Kind='component') and (S.GetValue('serialized_properties')<>nil) then begin
      Body.Append('<section class="card"><h2>What the learner sees and can enter</h2>');Found:=False;
      for V in S.GetValue<TJSONArray>('serialized_properties') do begin
        R:=V as TJSONObject;PropertyName:=R.GetValue<string>('name');PropertyValue:=R.GetValue<string>('value').Trim;Meaning:='';
        if (Length(PropertyValue)>=2) and PropertyValue.StartsWith('''') and PropertyValue.EndsWith('''') then
          PropertyValue:=Copy(PropertyValue,2,Length(PropertyValue)-2).Replace('''''','''');
        if MatchText(PropertyName,['Text','Caption']) then Meaning:='Text saved for this control: '+PropertyValue
        else if MatchText(PropertyName,['Hint','TextHint','TextPrompt']) then Meaning:='Guidance supplied with this control: '+PropertyValue
        else if SameText(PropertyName,'ReadOnly') and SameText(PropertyValue,'True') then Meaning:='This control is designed to display information without allowing direct typing.'
        else if SameText(PropertyName,'ReadOnly') and SameText(PropertyValue,'False') then Meaning:='The saved design permits editing; other application rules may still restrict it.'
        else if SameText(PropertyName,'Enabled') and SameText(PropertyValue,'False') then Meaning:='The saved design starts this control unavailable. Ask what enables it.'
        else if SameText(PropertyName,'Visible') and SameText(PropertyValue,'False') then Meaning:='The saved design starts this control hidden. Ask when it is shown.'
        else if SameText(PropertyName,'MaxLength') and TryStrToInt(PropertyValue,Limit) and (Limit>0) then Meaning:='The saved input limit is '+IntToStr(Limit)+' characters.';
        if Meaning<>'' then begin Body.Append('<p>'+Encode(Meaning)+'</p>');Found:=True;end;
      end;
      if not Found then Body.Append('<p>No supported display text, typing guidance or input limit was saved directly on this control. Ask the author for an example of its use.</p>');
      Body.Append('<p><small>These are saved design settings. The running application may change them. A field name alone does not establish what a user should enter.</small></p></section>');
    end;
    if (Kind='component') and (FFacts.GetValue<TJSONArray>('project_guides',nil)<>nil) then begin
      Count:=0; DetailHTML:='';
      for V in FFacts.GetValue<TJSONArray>('project_guides') do begin
        R:=V as TJSONObject;
        if R.GetValue<TJSONArray>('sections',nil)=nil then Continue;
        for W in R.GetValue<TJSONArray>('sections') do begin
          Section:=W as TJSONObject; SourceText:=Section.GetValue<string>('text','');
          MatchAt:=0;
          if Length(ControlName)>=5 then MatchAt:=Pos(LowerCase(ControlName),LowerCase(SourceText));
          if (MatchAt=0) and (Length(CaptionText)>=6) then MatchAt:=Pos(LowerCase(CaptionText),LowerCase(SourceText));
          if (MatchAt=0) and (Length(FormName)>=6) then MatchAt:=Pos(LowerCase(FormName),LowerCase(SourceText));
          if (MatchAt=0) and FormName.StartsWith('frm') and (Length(FormName)>6) then
            MatchAt:=Pos(LowerCase(Copy(FormName,4,MaxInt)),LowerCase(SourceText));
          if MatchAt=0 then Continue;
          Excerpt:=Copy(SourceText,Max(1,MatchAt-110),420).Trim;
          if SameText(R.GetValue<string>('format',''),'.log') then
            DetailHTML:=DetailHTML+'<p><strong>Recorded log excerpt:</strong> '+Encode(Excerpt)+'</p>'
          else DetailHTML:=DetailHTML+'<p>'+Encode(Excerpt)+'</p>';
          DetailHTML:=DetailHTML+'<p><small>'+Encode(R.GetValue<string>('source'))+
            ' · '+Encode(Section.GetValue<string>('heading',''))+'</small></p>';
          Inc(Count); if Count>=3 then Break;
        end;
        if Count>=3 then Break;
      end;
      if Count>0 then Body.Append('<section class="card"><h2>What the application documents and logs say</h2>'+DetailHTML+'</section>');
    end;
    if (Kind='component') and (FFacts.GetValue<TJSONArray>('project_sites',nil)<>nil) then
      for V in FFacts.GetValue<TJSONArray>('project_sites') do begin
        R:=V as TJSONObject; SourceText:=R.GetValue<string>('text','');
        if (SourceText='') or not (ContainsText(SourceText,ControlName) or ContainsText(SourceText,FormName)) then Continue;
        Body.Append('<section class="card"><h2>What the project website says</h2><p>'+Encode(Copy(SourceText,1,900))+
          '</p><p><small>'+Encode(R.GetValue<string>('url',''))+'; named in '+Encode(R.GetValue<string>('source',''))+'.</small></p></section>');
        Break;
      end;
    Body.Append('<section class="card"><h2>Why it matters to the user</h2>'); Found:=False;
    for V in FFacts.GetValue<TJSONArray>('knowledge') do begin
      R:=V as TJSONObject; Linked:=R.GetValue<string>('entity_key','')=AKey;
      if MatchText(R.GetValue<string>('state',''),['retired','rejected']) then Continue;
      for W in R.GetValue<TJSONArray>('links') do if W.GetValue<string>('canonical_key','')=AKey then Linked:=True;
      if not Linked then Continue;
      Metadata:=R.GetValue<TJSONObject>('structured_record',nil);
      if Metadata=nil then Metadata:=TJSONObject.ParseJSONValue(R.GetValue<string>('structured_json','{}')) as TJSONObject else Metadata:=Metadata.Clone as TJSONObject;
      try
        if (Metadata<>nil) and (Metadata.GetValue<string>('record_type','')='action_purpose') then begin
          Fields:=Metadata.GetValue<TJSONObject>('fields');
          for I:=0 to High(PurposeFields) do begin
            Meaning:=Fields.GetValue<string>(PurposeFields[I],'Not supplied; ask the author.');
            Body.Append('<h3>'+PurposeLabels[I]+'</h3><p>'+Encode(Meaning)+'</p>');
          end;
        end else Body.Append('<h3>'+Encode(R.GetValue<string>('title'))+'</h3><p>'+Encode(R.GetValue<string>('body')).Replace(sLineBreak,'<br>')+'</p>');
        Body.Append('<p><small>Supplied by '+Encode(R.GetValue<string>('owner'))+'; review status: '+Encode(R.GetValue<string>('state'))+'.</small></p>');Found:=True;
      finally Metadata.Free;end;
    end;
    if not Found then begin
      if (Kind='component') and (CaptionText<>'') then
        Body.Append('<p>The saved screen identifies this as &ldquo;'+Encode(CaptionText)+'&rdquo;. Follow the connected action below to see how this part of the screen participates in a task.</p>')
      else Body.Append('<p>Follow the connected actions below to see how this selection participates in the application.</p>');
    end;
    Body.Append('</section>');DetailHTML:='';Count:=0;
    LessonRows:=TList<TJSONObject>.Create;
    try
    if FFlow.TryGetValue(AKey,Rows) then for R in Rows do LessonRows.Add(R);
    LessonRows.Sort(TComparer<TJSONObject>.Construct(function(const L,R: TJSONObject): Integer
    begin Result:=CompareValue(L.GetValue<Int64>('range.start'),R.GetValue<Int64>('range.start'));end));
    for Pass:=0 to 1 do begin
      if Count>=4 then Break;
      for R in LessonRows do begin
      Kind:=R.GetValue<string>('kind');Meaning:='';PropertyValue:=R.GetValue<string>('expression','');
      if (Pass=0) and not MatchText(Kind,['if','case','while','repeat','for']) then Continue;
      if (Pass=1) and MatchText(Kind,['if','case','while','repeat','for']) then Continue;
      if Length(PropertyValue)>180 then PropertyValue:=Copy(PropertyValue,1,180)+'...';
      if Kind='if' then Meaning:='It makes a choice by testing '+PropertyValue+'. A true result follows one branch; a false result follows the other.'
      else if Kind='case' then Meaning:='It chooses among several alternatives using '+PropertyValue+'.'
      else if Kind='while' then Meaning:='It can repeat work while '+PropertyValue+' is true. The work may run zero times.'
      else if Kind='repeat' then Meaning:='It tests '+PropertyValue+' after doing the repeated work. A false result repeats it; a true result stops repeating.'
      else if Kind='for' then Meaning:='It repeats work for the range or items described by '+PropertyValue+'.'
      else if Kind='try_finally' then Meaning:='It arranges cleanup after the protected work, including paths that leave early.'
      else if Kind='try_except' then Meaning:='It has a place to handle an error raised during the protected work.'
      else if Kind='raise' then Meaning:='This path can report an error: '+PropertyValue+'. It does not mean every run fails.'
      else if Kind='exit' then Meaning:='This path can leave the operation early: '+PropertyValue+'.';
      if Meaning='' then Continue;DetailHTML:=DetailHTML+'<p>'+Encode(Meaning)+'</p>';Inc(Count);if Count>=4 then Break;
      end;
    end;
    finally LessonRows.Free;end;
    if Count>0 then Body.Append('<section class="card"><h2>Choices and stopping points</h2>'+DetailHTML+
      '<p>These are examples from this operation, not a record of a run. Read the optional walkthrough for all supported paths and their order.</p></section>');
    Body.Append('<section class="card"><h2>Follow what happens next</h2>'); Count:=0;
    if FOutgoing.TryGetValue(AKey,Rows) then for R in Rows do begin
      Kind:=R.GetValue<string>('kind'); Target:=R.GetValue<string>('to','');
      if not MatchText(Kind,['calls','binds','reads','writes','shows_form','shows_modal_form','closes_form','schedules','passes_callback']) then Continue;
      Verb:='Connects to';
      if Kind='calls' then Verb:='Can call the operation';
      if Kind='binds' then Verb:='Names this responding operation';
      if Kind='reads' then Verb:='Uses information from';
      if Kind='writes' then Verb:='Can change';
      if MatchText(Kind,['shows_form','shows_modal_form']) then Verb:='Can open the screen';
      if Kind='closes_form' then Verb:='Can close the screen';
      if MatchText(Kind,['schedules','passes_callback']) then Verb:='Supplies work that may run later in';
      Body.Append('<p>'+Verb+' '+Link(Target)+'.</p>');
      if R.GetValue<string>('resolution')<>'confirmed_static' then Body.Append('<p><small>This connection needs confirmation; the source alone does not establish its exact target or timing.</small></p>');
      Inc(Count); if Count>=8 then Break;
    end;
    if Count=0 then Body.Append('<p>No supported next operation was found directly here. For a screen control, open its event in the left-hand list. For code, inspect the walkthrough below or ask the author about missing connections.</p>');
    if Count>=8 then Body.Append('<p>Eight connections are shown to keep this lesson focused. Further connections are in the optional details.</p>');
    Body.Append('<p>These are possible source paths. Conditions and user input determine which paths a real run takes.</p></section>'+
      '<section class="card"><h2>Check your understanding</h2><p>Explain what starts this operation, what information it uses, and what it can change. Which user result is documented, and which part still needs an answer?</p></section>');
    DetailHTML:=ObjectHTML(AKey); P:=Pos('<main>',DetailHTML);
    if P>0 then begin
      DetailHTML:=Copy(DetailHTML,P+6,MaxInt); P:=Pos('</main>',DetailHTML);
      if P>0 then DetailHTML:=Copy(DetailHTML,1,P-1);
      Body.Append('<details class="card"><summary>Optional: read the code walkthrough and source details</summary>'+DetailHTML+'</details>');
    end;
    Body.Append('<section class="card"><p><a href="#all_objects">Return to the full Project map</a></p></section>');
    Result:=Page(S.GetValue<string>('name'),Body.ToString);
  finally Body.Free; end;
end;
function TDPHExplanationModel.Prose(const AText: string): string;
var Line: string; Text: TStringBuilder;
begin
  Text:=TStringBuilder.Create;
  try
    Text.Append('<section class="card">');
    for Line in AText.Split([sLineBreak]) do begin
      if Trim(Line)='' then Continue;
      if (Length(Line)<70) and (Line=UpperCase(Line)) then Text.Append('</section><section class="card"><h2>'+Encode(Line)+'</h2>')
      else Text.Append('<p>'+Encode(Line)+'</p>');
    end;
    Text.Append('</section>'); Result:=Text.ToString;
  finally Text.Free; end;
end;
function TDPHExplanationModel.TopicText(AIndex: Integer): string;
var Text: TStringBuilder; V,W: TJSONValue; R,S: TJSONObject; Count: Integer; Kind: string;
begin
  Text:=TStringBuilder.Create;
  try
    Text.AppendLine(TopicTitle(AIndex)).AppendLine;
    case AIndex of
      0: begin
        Text.AppendLine('Your first route through '+FFacts.GetValue<string>('project')+':');
        Text.AppendLine('1. Open How the program starts and read the captured initialization statements.');
        Text.AppendLine('2. Open Screens and user actions. Select a control you recognize.');
        Text.AppendLine('3. Follow its event binding to the handler, then read Explain and the execution trace.');
        Text.AppendLine('4. Inspect each important branch and its data/output relationships.');
        Text.AppendLine('5. Check coverage gaps. Record author answers as attributed knowledge.');
        Text.AppendLine('6. Before editing, review incoming dependencies and Change impact.');
        Text.AppendLine(IntToStr(FFacts.GetValue<TJSONArray>('files').Count)+' included files; '+IntToStr(FSymbols.Count)+' symbols; '+IntToStr(FFacts.GetValue<TJSONArray>('relationships').Count)+' relationships. These counts measure captured objects, not understanding or human approval.');
      end;
      1: begin
        Text.AppendLine('The startup block in the Delphi program is where initialization and form creation are normally declared. These are the startup expressions actually captured from the program resource:');
        if FFacts.GetValue('startup')<>nil then for V in FFacts.GetValue<TJSONArray>('startup') do begin R:=V as TJSONObject; Text.AppendLine(R.GetValue<string>('text')+' | '+Citation(R)); end;
        if (FFacts.GetValue('startup')=nil) or (FFacts.GetValue<TJSONArray>('startup').Count=0) then Text.AppendLine('No program startup expressions were captured in this scope. Open the DPR source; startup must not be inferred from an arbitrary first routine.');
        Text.AppendLine('Application.Initialize prepares the application framework; Application.CreateForm declares a form instance; Application.Run enters the event loop when those calls are present. Their presence alone does not establish successful runtime startup.');
      end;
      2: Text.AppendLine('A form resource declares controls and their design-time properties. Captions describe labels; OnClick and other event properties link user actions to code. Select a component below, then follow its event. Reconstructed rectangles are not screenshots. Imported images are separate, attributed evidence.');
      3: Text.AppendLine('Start at a serialized event and follow binds to its routine. calls identifies a call site; passes_callback identifies a supplied anonymous routine; schedules is a possible asynchronous connection. Click any object in a trace to continue. None of these facts proves callback timing or runtime order.');
      4: Text.AppendLine('Select a routine to read its decisions and its control-flow diagram. An if has true/false exits; a loop can repeat; a finally block describes cleanup paths. The diagram uses captured edges and source locations. Orange paths are uncertain. Look for conditional configuration and background scheduling before assuming a straight sequence.');
      5: Text.AppendLine('Read relationships distinguish inputs from writes and possible side effects. renders is a conservative model-to-renderer inference, not a guaranteed output. Static SQL is only a captured literal; dynamic SQL and live database behavior require separate evidence. Select a result below to examine its consumer and producer.');
      6: Text.AppendLine('Units partition the application. imports records a declared dependency; it is not a call. owns links declarations to their containers. uses_type, inherits and implements describe supported type relationships. Missing dependencies remain gaps rather than guessed framework behavior.');
      7: Text.AppendLine('Choose the object you intend to change. Read its incoming relationships to identify callers and consumers, inspect compile variants, then open Change impact. Check linked rules and review history. Make a separately authorized change, run the project-specific tests, reassess, and review invalidated explanations. DPH has not tested the selected program merely by parsing it.');
      8: begin
        Text.AppendLine('Analysis gaps affect what you can conclude. Fix missing input roots or supply correct compiler defines before treating an unresolved name as a defect in the selected program. PARTIAL remains partial after explanation generation.');
        if FFacts.GetValue('diagnostics')<>nil then begin Count:=0; for V in FFacts.GetValue<TJSONArray>('diagnostics') do begin R:=V as TJSONObject; Text.AppendLine(R.GetValue<string>('code')+': '+R.GetValue<string>('message')); Inc(Count); if Count>=30 then Break; end; end;
        Text.AppendLine('Troubleshooting needs an observed symptom, expected behavior, environment, source revision and a reviewed remedy. Static analysis alone cannot establish a production failure cause.');
      end;
      9: begin
        Text.AppendLine('These unanswered questions are derived from captured gaps and missing reviewed procedures in this scope:');
        if FFacts.GetValue('author_questions')<>nil then for V in FFacts.GetValue<TJSONArray>('author_questions') do begin R:=V as TJSONObject;
          Text.AppendLine(R.GetValue<string>('title')+': '+R.GetValue<string>('prompt'));
          Text.AppendLine('Evidence rule: '+R.GetValue<string>('rule')+' | '+Citation(R));
        end;
        Text.AppendLine('Open Author questions in the app to inspect evidence and record a named response. Saving leaves it pending review. A reviewed answer only suppresses its exact question while no review is pending. No business rationale or runtime result is invented.');
      end;
      10: begin
        Text.AppendLine('Unit: a Pascal module grouping declarations and implementations.');
        Text.AppendLine('Class/type: a definition of data and available operations. Component: an object declared in a form resource.');
        Text.AppendLine('Routine: a procedure or function. Signature: the declared parameter and result types. Event handler: a routine connected to an event.');
        Text.AppendLine('Callback: code supplied for later invocation. Asynchronous: work whose ordering or thread differs from the immediate caller.');
        Text.AppendLine('Control-flow graph: possible paths through a routine, including branches, loops and exits. Def-use: relationships between writing and reading values.');
        Text.AppendLine('Static confirmed: supported by a captured declaration or code location. Inferred: a derivation with limits. Unresolved: no supported target was established.');
        Text.AppendLine('Generation: one captured source/configuration revision. Fingerprint: its hash identity. Detached: historical data open without source attachment.');
      end;
    end;
    if AIndex in [2,3,4,5,6] then begin
      Count:=0; Text.AppendLine.AppendLine('PROJECT-SPECIFIC STARTING POINTS');
      if AIndex in [3,5] then begin
        for V in FFacts.GetValue<TJSONArray>('relationships') do begin R:=V as TJSONObject; Kind:=R.GetValue<string>('kind');
          if ((AIndex=3) and (Kind='binds')) or ((AIndex=5) and MatchText(Kind,['renders','static_sql','writes'])) then begin
            Text.AppendLine(RelationText(R,False)); Inc(Count); if Count>=20 then Break;
          end;
        end;
      end else for V in FFacts.GetValue<TJSONArray>('symbols') do begin S:=V as TJSONObject; Kind:=S.GetValue<string>('kind');
        if ((AIndex=2) and (Kind='component')) or ((AIndex=4) and ((Kind='anonymous') or (FFlow.ContainsKey(S.GetValue<string>('key'))))) or ((AIndex=6) and (Kind='unit')) then begin
          Text.AppendLine(S.GetValue<string>('name')+' | '+Citation(S)); Inc(Count); if Count>=20 then Break;
        end;
      end;
      if Count=0 then Text.AppendLine('No supported starting point was captured for this topic in the selected scope.');
    end;
    if AIndex in [0,9] then for V in FFacts.GetValue<TJSONArray>('knowledge') do begin R:=V as TJSONObject;
      Text.AppendLine.AppendLine('ATTRIBUTED KNOWLEDGE: '+R.GetValue<string>('title')+' ['+R.GetValue<string>('state')+'] by '+R.GetValue<string>('owner'));
      Text.AppendLine(R.GetValue<string>('body'));
    end;
    Result:=Text.ToString;
  finally Text.Free; end;
end;
function TDPHExplanationModel.LessonHTML(AIndex: Integer): string;
var Body: TStringBuilder; V,W: TJSONValue; S,R,Fields,Metadata,Target: TJSONObject;
    Rows,TaskRecords: TList<TJSONObject>; Caption,ControlType,Key,Handler,Kind: string;
    Count,StepIndex: Integer; Found,HasPurpose,IncludeCard: Boolean;
begin
  if not (AIndex in [0..11]) then Exit(Page('Learn the application','<p>Choose a topic from the lesson list.</p>'));
  Body:=TStringBuilder.Create;
  try
    if AIndex=0 then begin
      Body.Append('<section class="card"><h2>What does this application do?</h2>'); HasPurpose:=False;
      for V in FFacts.GetValue<TJSONArray>('knowledge') do begin
        R:=V as TJSONObject; Metadata:=R.GetValue<TJSONObject>('structured_record',nil);
        if MatchText(R.GetValue<string>('state',''),['retired','rejected']) then Continue;
        if Metadata=nil then Metadata:=TJSONObject.ParseJSONValue(R.GetValue<string>('structured_json','{}')) as TJSONObject
        else Metadata:=Metadata.Clone as TJSONObject;
        try
          if (Metadata=nil) or (Metadata.GetValue<string>('record_type','')<>'project_profile') then Continue;
          Fields:=Metadata.GetValue<TJSONObject>('fields',nil); if Fields=nil then Continue;
          Body.Append('<p>'+Encode(Fields.GetValue<string>('purpose','Not supplied'))+'</p><p><small>Explanation supplied by '+
            Encode(R.GetValue<string>('owner','not supplied'))+'; review status: '+Encode(R.GetValue<string>('state','not supplied'))+'.</small></p>');
          HasPurpose:=True;
        finally Metadata.Free; end;
      end;
      if not HasPurpose then Body.Append('<p>The author has not yet supplied an application-purpose explanation. Begin with a screen you recognize, and ask what task it helps its users accomplish. A filename cannot answer that question.</p>');
      Body.Append('</section><section class="card"><h2>Your first route through the application</h2><ol>'+
        '<li><a href="#lesson_2">Meet its screens and controls</a>. Find a button or field and read what connects it to the program. <a href="#lesson_11">Read its supplied task walkthroughs</a> for user instructions.</li>'+
        '<li><a href="#lesson_3">Follow one action</a>. Open its handler: the operation called when the action occurs.</li>'+
        '<li><a href="#lesson_4">Read the decisions</a>. Follow what happens when a condition is true and when it is false.</li>'+
        '<li><a href="#lesson_5">Follow the information</a>. Find what the operation reads, changes, or produces.</li>'+
        '<li><a href="#lesson_9">Ask what is still unclear</a>. Separate what the code shows from what its author needs to explain.</li></ol></section>'+
        '<section class="card"><h2>A small first exercise</h2><p>Choose one action. Explain, in your own words: what starts it, which operation responds, one decision it makes, and the result its user expects. Follow the links above to find the first three. If the expected result is not documented, record it as a question rather than guessing.</p>'+
        '<p><a href="#lesson_10">New to Delphi? Read the terms first.</a></p></section>');
    end else if AIndex=2 then begin
      Body.Append('<section class="card"><h2>Meet the interface</h2><p>A form is a screen. A control is something on that screen, such as a button, label or input box. A caption is the text a user sees. An event connects an action to a named operation in the code.</p>'+
        '<p>Open Screenshots to inspect blank screen views that DPH generates from the application''s saved .fmx or .dfm files. They show design-time controls and captions; runtime content and custom styling may differ.</p></section>');
      Count:=0;
      for V in FFacts.GetValue<TJSONArray>('symbols') do begin
        S:=V as TJSONObject; if S.GetValue<string>('kind')<>'component' then Continue;
        Key:=S.GetValue<string>('key'); Caption:=''; ControlType:=S.GetValue<string>('type','');
        if S.GetValue('serialized_properties')<>nil then for W in S.GetValue<TJSONArray>('serialized_properties') do begin
          R:=W as TJSONObject;
          if MatchText(R.GetValue<string>('name'),['Text','Caption']) then Caption:=R.GetValue<string>('value');
        end;
        Body.Append('<section class="card"><h2>'+Link(Key)+'</h2>');
        if Caption<>'' then Body.Append('<p><strong>Text shown to the user:</strong> '+Encode(Caption)+'</p>')
        else Body.Append('<p>No display text was saved for this control. Its code name is not an explanation of its purpose.</p>');
        Body.Append('<p><strong>Control type:</strong> '+Encode(ControlType)+'. Open the name above to inspect its connections.</p>');
        Found:=False;
        if S.GetValue('serialized_properties')<>nil then for W in S.GetValue<TJSONArray>('serialized_properties') do begin
          R:=W as TJSONObject;
          if StartsText('On',R.GetValue<string>('name')) then begin
            Body.Append('<p><strong>Action connection:</strong> '+Encode(R.GetValue<string>('name'))+' calls the named handler '+Encode(R.GetValue<string>('value'))+'.</p>'); Found:=True;
          end;
        end;
        if not Found then Body.Append('<p>No event was saved directly on this control. It may display information, use an action object, or be connected by code.</p>');
        Body.Append('<p><small>Found in '+Encode(S.GetValue<string>('range.source'))+'.</small></p></section>');
        Inc(Count); if Count>=30 then Break;
      end;
      if Count=0 then Body.Append('<section class="card"><p>No supported screen controls were found in this selection. It may be a nonvisual application, or its form files may be unavailable.</p></section>');
      if Count>=30 then Body.Append('<p>First 30 controls shown. Use the left-hand search to find another by name.</p>');
      Body.Append('<section class="card"><h2>Try it</h2><p>Find a button. Identify its display text and its event handler. What task does the button help the user accomplish? Check the explanation; the caption alone cannot establish the whole task.</p><a href="#lesson_3">Next: follow an action into its operation</a></section>');
    end else if AIndex=3 then begin
      Body.Append('<section class="card"><h2>From an action to its operation</h2><p>When a user clicks a button, Delphi calls its connected event handler. That handler may call other operations. Follow one connection below and read the explanation before opening the source code.</p></section>');
      Count:=0;
      for V in FFacts.GetValue<TJSONArray>('relationships') do begin
        R:=V as TJSONObject; if R.GetValue<string>('kind')<>'binds' then Continue;
        Key:=R.GetValue<string>('from'); Handler:=R.GetValue<string>('to','');
        Body.Append('<section class="card"><h2>'+Link(Key)+'</h2><ol><li>This saved event names a responding operation.</li>');
        if FSymbols.TryGetValue(Handler,Target) then begin
          Body.Append('<li>Open '+Link(Handler)+' to read that operation.</li><li>Inside its explanation, look at what it calls and what it changes.</li></ol>');
          if FOutgoing.TryGetValue(Handler,Rows) then begin
            Found:=False;
            for S in Rows do if S.GetValue<string>('kind')='calls' then begin
              Body.Append('<p>One next operation to explore: '+Link(S.GetValue<string>('to',''))+'. This is a source connection; conditions may prevent it from running.</p>'); Found:=True; Break;
            end;
            if not Found then Body.Append('<p>No direct next call was resolved. Read its decisions and assignments in Explain.</p>');
          end;
        end else Body.Append('<li>The named handler could not be found in the available source. Ask the author for the missing connection.</li></ol>');
        Body.Append('</section>'); Inc(Count); if Count>=30 then Break;
      end;
      if Count=0 then Body.Append('<section class="card"><p>No saved event-to-handler connections were found. Select a routine in the left-hand list to learn its operations directly. Runtime connections need an explanation from the author.</p></section>');
      if Count>=30 then Body.Append('<p>First 30 connections shown. Use search for additional events.</p>');
      Body.Append('<section class="card"><h2>Check your understanding</h2><p>Describe the route as: user action, responding operation, next operation, expected result. Say which parts the code shows and which parts still need the author to explain.</p><a href="#lesson_4">Next: understand decisions and alternatives</a></section>');
    end else begin
      Body.Append('<section class="card">'); Count:=0;
      case AIndex of
        1: begin
          Body.Append('<h2>How the application gets ready</h2><p>The Delphi program file describes the work done before the application waits for user actions. The following expressions were found in that startup section.</p>');
          for V in FFacts.GetValue<TJSONArray>('startup') do begin
            R:=V as TJSONObject; Caption:=R.GetValue<string>('text');
            if StartsText('Application . ',Caption) then Caption:='Application.'+Copy(Caption,15,MaxInt);
            Body.Append('<h3>'+Encode(Caption)+'</h3>');
            if ContainsText(Caption,'Application.Initialize') then Body.Append('<p>Prepares the application framework.</p>')
            else if ContainsText(Caption,'Application.CreateForm') then Body.Append('<p>Requests creation of a form or data module. Read the names in the call to identify which one.</p>')
            else if ContainsText(Caption,'Application.Run') then Body.Append('<p>Starts the event loop: the application can respond to user actions.</p>')
            else Body.Append('<p>This is a startup instruction. Its intended purpose needs the called operation or an author explanation.</p>');
            Inc(Count); if Count>=20 then Break;
          end;
          if Count=0 then Body.Append('<p>No supported startup instructions were found. Ask the author which program file and initialization steps apply.</p>');
          if Count>=20 then Body.Append('<p>First 20 startup instructions shown.</p>');
          Body.Append('<h3>Try it</h3><p>Identify the first screen created. Does it match the screen the user sees first? The source shows the request; the author or an actual screenshot can confirm the displayed result.</p>');
        end;
        4: begin
          Body.Append('<h2>Understand a decision</h2><p>An if statement chooses between alternatives. A loop repeats work. A try/finally block arranges cleanup even when work leaves early. These are actual decisions found in the selected application.</p>');
          var Decisions:=TList<TJSONObject>.Create;
          try
          for V in FFacts.GetValue<TJSONArray>('flow_nodes') do Decisions.Add(V as TJSONObject);
          Decisions.Sort(TComparer<TJSONObject>.Construct(function(const L,R:TJSONObject):Integer
          begin Result:=CompareText(L.GetValue<string>('range.source'),R.GetValue<string>('range.source'));
            if Result=0 then Result:=CompareValue(L.GetValue<Int64>('range.start'),R.GetValue<Int64>('range.start'));end));
          for R in Decisions do begin
            Kind:=R.GetValue<string>('kind');
            if not MatchText(Kind,['if','while','for','repeat','case']) then Continue;
            Caption:='It makes a choice by testing '+R.GetValue<string>('expression')+'. A true result takes one branch; a false result takes the other.';
            if Kind='while' then Caption:='It can repeat work while '+R.GetValue<string>('expression')+' is true. The work may run zero times.';
            if Kind='repeat' then Caption:='It does the repeated work before testing '+R.GetValue<string>('expression')+'. False repeats the work; true stops repeating.';
            if Kind='for' then Caption:='It repeats work for the range or items described by '+R.GetValue<string>('expression')+'.';
            if Kind='case' then Caption:='It chooses among alternatives using '+R.GetValue<string>('expression')+'.';
            Body.Append('<p>'+Encode(Caption)+'<br>Read it in '+Link(R.GetValue<string>('routine'))+'.</p>');
            Inc(Count); if Count>=6 then Break;
          end;
          finally Decisions.Free;end;
          if Count=0 then Body.Append('<p>No supported decision was found. This does not establish that the application has no decisions.</p>');
          if Count>=6 then Body.Append('<p>Six examples shown. Search for a particular operation to read its own decisions.</p>');
          Body.Append('<h3>Try it</h3><p>Open one operation. Expand its optional walkthrough and explain what happens when one condition is true and when it is false. Work that runs in the background may finish later; its timing needs confirmation.</p>');
        end;
        5: begin
          Body.Append('<h2>Follow the information</h2><p>An operation can read a value, change a value, or prepare an output. These connections provide starting points for learning where information comes from and where it goes.</p>');
          var SeenConnections:=TDictionary<string,Boolean>.Create;
          try
          for V in FFacts.GetValue<TJSONArray>('relationships') do begin
            R:=V as TJSONObject; Kind:=R.GetValue<string>('kind');
            if not MatchText(Kind,['reads','writes','renders','output_candidate']) then Continue;
            Caption:=Kind+#0+R.GetValue<string>('from')+#0+R.GetValue<string>('to','');
            if SeenConnections.ContainsKey(Caption) then Continue;SeenConnections.Add(Caption,True);
            Caption:='uses'; if Kind='writes' then Caption:='can change';
            if MatchText(Kind,['renders','output_candidate']) then Caption:='may prepare an output associated with';
            Body.Append('<p>'+Link(R.GetValue<string>('from'))+' '+Caption+' '+Link(R.GetValue<string>('to',''))+'.</p>');
            Inc(Count); if Count>=12 then Break;
          end;
          finally SeenConnections.Free;end;
          if Count=0 then Body.Append('<p>No supported information connections were found. Ask the author for an example of an input and its resulting output.</p>');
          if Count>=12 then Body.Append('<p>Twelve examples shown. Open an operation for its own connections.</p>');
          Body.Append('<h3>Try it</h3><p>Choose one result and ask where its original information came from, what changes it, and where the user sees it. These source connections do not establish actual values or successful delivery.</p>');
        end;
        6: begin
          Body.Append('<h2>How the parts fit together</h2><p>Delphi groups code into units. A unit can use another unit, but that dependency does not mean every operation in it runs. Start with a few units related to a screen or action you recognize.</p>');
          for V in FFacts.GetValue<TJSONArray>('symbols') do begin
            S:=V as TJSONObject; if S.GetValue<string>('kind')<>'unit' then Continue;
            Body.Append('<p>'+Link(S.GetValue<string>('key'))+'</p>'); Inc(Count); if Count>=20 then Break;
          end;
          if Count=0 then Body.Append('<p>No supported units were found in this selection.</p>');
          if Count>=20 then Body.Append('<p>First 20 units shown. Use search to find another.</p>');
          Body.Append('<h3>Try it</h3><p>Pick a screen and identify the unit containing its event handler. Ask what responsibility that unit has, and which other unit does the next piece of work.</p>');
        end;
        7: Body.Append('<h2>Before making a change</h2><ol><li>Describe the user behavior you intend to change.</li><li>Follow its action to the responsible operation.</li><li>Read the callers and the information it changes.</li><li>Ask the author about rules or consequences that are not explained.</li><li>Use the selected application''s approved build and test instructions.</li><li>Refresh the lessons after the source changes and check affected explanations.</li></ol><p>DPH reads the application; it does not prove a change is correct by reading it.</p>');
        8: Body.Append('<h2>What still needs explaining</h2><p>A lesson can be incomplete because a source file is missing, a connection could not be understood, or a human explanation has not been supplied. These are different problems.</p><ol><li>Ask whether all required source and form files were supplied.</li><li>Open the particular action or operation and identify the missing connection.</li><li>Ask for its intended result and an example of correct behavior.</li></ol><p>Prepare lessons contains the detailed source-reading checks for the person maintaining the lessons.</p><p><a href="#lesson_9">Read the questions for the author</a>.</p>');
        9: begin
          Body.Append('<h2>Answers supplied for this application</h2><p>Read what the application author or another named contributor has explained. Review status tells you whether someone has checked the answer.</p>');
          for V in FFacts.GetValue<TJSONArray>('knowledge') do begin
            R:=V as TJSONObject;if MatchText(R.GetValue<string>('state',''),['retired','rejected']) then Continue;
            Metadata:=R.GetValue<TJSONObject>('question_metadata',nil);if Metadata=nil then Continue;
            Body.Append('<h3>'+Encode(Metadata.GetValue<string>('prompt',R.GetValue<string>('title')) )+'</h3><p>'+
              Encode(R.GetValue<string>('body')).Replace(sLineBreak,'</p><p>')+'</p><p><small>Answer supplied by '+Encode(R.GetValue<string>('owner'))+'. ');
            if R.GetValue<string>('state')='verified' then Body.Append('Reviewed answer.') else Body.Append('This answer still needs review.');
            Body.Append('</small></p>');Inc(Count);if Count>=30 then Break;
          end;
          if Count=0 then Body.Append('<p>No saved answers have been supplied yet. The questions below identify useful things to ask.</p>');
          if Count>=30 then Body.Append('<p>First 30 answers shown. Open Saved explanations to review another answer.</p>');
          Body.Append('<h2>Questions still to ask</h2><p>Use these questions to fill gaps in your understanding. <a href="#ask_author">Open Author questions</a> to record a named reply.</p>');Count:=0;
          for V in FFacts.GetValue<TJSONArray>('author_questions') do begin
            R:=V as TJSONObject;if R.GetValue<string>('answer_kind','')<>'user_help' then Continue;
            Body.Append('<h3>Prepare a first task</h3><p>Which task should a new user learn first? What inputs and permissions must be ready, how do they recognize success, and what should they do when the result differs?</p>');
            Inc(Count);Break;
          end;
          if Count=0 then Body.Append('<p>Ask which task matters most and whether its supplied instructions cover the expected result and common mistakes.</p>');
          Body.Append('<h3>Understand an unfamiliar result</h3><p>Which examples show correct and incorrect outcomes? What information would help someone explain a result that differs?</p><h3>Learn the important rules</h3><p>Which mistakes should a newcomer avoid, and what business rule explains why?</p>');
        end;
        10: Body.Append('<h2>Delphi terms in plain language</h2><p><strong>Form:</strong> a screen or window.</p>'+
          '<p><strong>Control:</strong> something on a screen, such as a button or input box.</p>'+
          '<p><strong>Property:</strong> a setting belonging to an object, such as its caption or visibility.</p>'+
          '<p><strong>Event:</strong> something that happens, such as a click.</p>'+
          '<p><strong>Event handler:</strong> the operation that responds to an event.</p>'+
          '<p><strong>Procedure:</strong> a named operation. <strong>Function:</strong> an operation that returns a result.</p>'+
          '<p><strong>Parameter:</strong> information passed to an operation.</p>'+
          '<p><strong>Variable:</strong> a named place holding a value that can change.</p>'+
          '<p><strong>Unit:</strong> a source file grouping definitions and operations.</p>'+
          '<p><strong>Class:</strong> a definition used to create objects with data and operations.</p>'+
          '<p><strong>Background work:</strong> work that can continue while the interface responds; completion order needs care.</p>'+
          '<p>Business glossary contains terms specific to the selected application.</p>');
        11: begin
          Body.Append('<h2>Task walkthroughs for this application</h2><p>These are instructions supplied for the selected application. Read the prerequisites, follow the named actions, and compare the result with the expected outcome. The contributor and review status identify whose explanation you are using.</p>');
          Body.Append('<p><a href="#task_reader">Open Learn a task</a> to follow the prepared steps one at a time, with Previous, Next and Start again.</p>');
          TaskRecords:=TList<TJSONObject>.Create;
          try
          for V in FFacts.GetValue<TJSONArray>('knowledge') do TaskRecords.Add(V as TJSONObject);
          TaskRecords.Sort(TComparer<TJSONObject>.Construct(function(const L,R:TJSONObject):Integer
          var LeftRecord,RightRecord:TJSONObject;
          begin
            LeftRecord:=L.GetValue<TJSONObject>('structured_record',nil);RightRecord:=R.GetValue<TJSONObject>('structured_record',nil);
            if LeftRecord=nil then LeftRecord:=TJSONObject.ParseJSONValue(L.GetValue<string>('structured_json','{}')) as TJSONObject else LeftRecord:=LeftRecord.Clone as TJSONObject;
            if RightRecord=nil then RightRecord:=TJSONObject.ParseJSONValue(R.GetValue<string>('structured_json','{}')) as TJSONObject else RightRecord:=RightRecord.Clone as TJSONObject;
            try
              Result:=CompareText(LeftRecord.GetValue<string>('learning.path',''),RightRecord.GetValue<string>('learning.path',''));
              if Result=0 then Result:=CompareValue(LeftRecord.GetValue<Integer>('learning.order',10000),RightRecord.GetValue<Integer>('learning.order',10000));
              if Result=0 then Result:=CompareText(L.GetValue<string>('title'),R.GetValue<string>('title'));
            finally LeftRecord.Free;RightRecord.Free;end;
          end));
          for R in TaskRecords do begin
            if MatchText(R.GetValue<string>('state',''),['rejected','retired']) then Continue;
            if not MatchText(R.GetValue<string>('kind',''),['user_help','troubleshooting']) and
              not MatchText(R.GetValue<string>('document_kind',''),['user','help']) then Continue;
            Metadata:=R.GetValue<TJSONObject>('structured_record',nil);
            if Metadata=nil then Metadata:=TJSONObject.ParseJSONValue(R.GetValue<string>('structured_json','{}')) as TJSONObject else Metadata:=Metadata.Clone as TJSONObject;
            try
              if (Metadata<>nil) and (Metadata.GetValue<string>('record_type','')<>'') and (Metadata.GetValue<string>('record_type','')<>'learning_lesson') then Continue;
              Body.Append('<h3>'+Encode(R.GetValue<string>('title'))+'</h3>');
              if (Metadata<>nil) and (Metadata.GetValue<string>('record_type','')='learning_lesson') then begin
                Fields:=Metadata.GetValue<TJSONObject>('fields');
                if Metadata.GetValue('learning')<>nil then Body.Append('<p><strong>User role:</strong> '+Encode(Metadata.GetValue<string>('learning.role'))+
                  '<br><strong>Learning path:</strong> '+Encode(Metadata.GetValue<string>('learning.path'))+'; lesson '+IntToStr(Metadata.GetValue<Integer>('learning.order'))+'</p>');
                Body.Append('<p><strong>Purpose:</strong> '+Encode(Fields.GetValue<string>('purpose'))+'</p><p><strong>Before you begin:</strong> '+Encode(Fields.GetValue<string>('prerequisites'))+'</p><ol>');
                StepIndex:=0;
                for W in Metadata.GetValue<TJSONArray>('steps') do begin Inc(StepIndex);
                  Body.Append('<li><p>'+Encode(W.GetValue<string>('action')).Replace(sLineBreak,'<br>')+'</p><p><strong>Expected after step '+IntToStr(StepIndex)+':</strong> '+Encode(W.GetValue<string>('expected_result')).Replace(sLineBreak,'<br>')+'</p></li>');
                end;
                Body.Append('</ol><p><strong>Expected final result:</strong> '+Encode(Fields.GetValue<string>('expected_result'))+'</p><p><strong>If something goes wrong:</strong> '+Encode(Fields.GetValue<string>('troubleshooting'))+'</p><p><strong>Practice:</strong> '+Encode(Fields.GetValue<string>('practice'))+'</p>');
              end else Body.Append('<p>'+Encode(R.GetValue<string>('body')).Replace(sLineBreak,'</p><p>')+'</p>');
            finally Metadata.Free;end;
            Body.Append('<p><small>Supplied by '+Encode(R.GetValue<string>('owner'))+'; review status: '+Encode(R.GetValue<string>('state'))+'.</small></p>');
            for W in R.GetValue<TJSONArray>('links') do begin
              Key:=W.GetValue<string>('canonical_key','');
              if (Key<>'') and FSymbols.ContainsKey(Key) then Body.Append('<p>Explore the related part of the application: '+Link(Key)+'.</p>');
            end;
            Inc(Count);
          end;
          finally TaskRecords.Free;end;
          if Count=0 then Body.Append('<p>No user walkthrough has been supplied for this application yet. Ask its author for one common task: who performs it, what must be ready, the screen actions in order, the expected result, and what to do if it fails. The code alone cannot supply unwritten operating instructions.</p>');
          Body.Append('<h3>Practice</h3><p>Choose a supplied task, explain its steps in your own words, and identify the result you would check. Do not run the selected application or alter live information without its owner''s approval.</p>');
        end;
      end;
      Body.Append('</section><section class="card"><p><a href="#lesson_0">Return to your learning route</a></p></section>');
    end;
    for V in FFacts.GetValue<TJSONArray>('knowledge') do begin
      R:=V as TJSONObject;if MatchText(R.GetValue<string>('state',''),['retired','rejected']) then Continue;
      Metadata:=R.GetValue<TJSONObject>('structured_record',nil);
      if Metadata=nil then Metadata:=TJSONObject.ParseJSONValue(R.GetValue<string>('structured_json','{}')) as TJSONObject else Metadata:=Metadata.Clone as TJSONObject;
      try
        if (Metadata=nil) or (Metadata.GetValue<string>('record_type','')<>'learning_card') then Continue;
        Kind:=Metadata.GetValue<string>('category');IncludeCard:=False;
        case AIndex of
          0: IncludeCard:=Kind='Role or permission';
          2: IncludeCard:=MatchText(Kind,['Screen','Field']);
          3: IncludeCard:=Kind='Background work';
          4: IncludeCard:=Kind='Business rule';
          5: IncludeCard:=MatchText(Kind,['Output or report','Setting or option']);
          6: IncludeCard:=Kind='Related system';
          7: IncludeCard:=Kind='History or design choice';
          8: IncludeCard:=Kind='Learning check';
          9: IncludeCard:=MatchText(Kind,['Error or problem','Question and answer']);
        end;
        if not IncludeCard then Continue;
        Body.Append('<section class="card"><h2>'+Encode(Kind)+': '+Encode(R.GetValue<string>('title'))+'</h2><p>'+Encode(R.GetValue<string>('body')).Replace(sLineBreak,'<br>')+'</p><p><small>Supplied by '+Encode(R.GetValue<string>('owner'))+'; review status: '+Encode(R.GetValue<string>('state'))+'.</small></p>');
        Key:=R.GetValue<string>('entity_key','');
        if R.GetValue('links')<>nil then for W in R.GetValue<TJSONArray>('links') do
          if FSymbols.ContainsKey(W.GetValue<string>('canonical_key','')) then begin Key:=W.GetValue<string>('canonical_key');Break;end;
        if (Key<>'') and FSymbols.ContainsKey(Key) then Body.Append('<p>Explore the related selection: '+Link(Key)+'.</p>');
        Body.Append('</section>');
      finally Metadata.Free;end;
    end;
    if AIndex=0 then Body.Append('<section class="card"><h2>Find a plain-language explanation</h2><p>Choose Learning library in DPH to search screen and field guides, worked examples, questions, errors, rules and reports. In this shared guide, those explanations appear with their relevant learning topic.</p></section>');
    Result:=Page(TopicTitle(AIndex),Body.ToString);
  finally Body.Free; end;
end;
function TDPHExplanationModel.ProjectMapHTML: string;
const Kinds: array[0..11] of string =
  ('unit','type','routine','component','event','field','property','variable',
   'local','parameter','resource','definition');
var Body: TStringBuilder; V: TJSONValue; Row: TJSONObject;
    Kind,Path,GroupName,LabelText,UnitKey: string;
    I,Count,Total,OtherCount: Integer; FileGroups: array[0..3] of TStringBuilder;
    OtherGroups: array[0..2] of TStringBuilder;
    Counts: TDictionary<string,Integer>; UnitKeys: TDictionary<string,string>;
    KnownPaths: TDictionary<string,Boolean>;
begin
  Body:=TStringBuilder.Create; Counts:=TDictionary<string,Integer>.Create;
  UnitKeys:=TDictionary<string,string>.Create;
  KnownPaths:=TDictionary<string,Boolean>.Create;
  for I:=0 to 3 do FileGroups[I]:=TStringBuilder.Create;
  for I:=0 to 2 do OtherGroups[I]:=TStringBuilder.Create;
  try
    for V in FFacts.GetValue<TJSONArray>('symbols') do begin
      Row:=V as TJSONObject; Kind:=Row.GetValue<string>('kind','');
      if Counts.TryGetValue(Kind,Count) then Counts[Kind]:=Count+1 else Counts.Add(Kind,1);
      if Kind='unit' then UnitKeys.AddOrSetValue(LowerCase(Row.GetValue<string>('range.source','')),Row.GetValue<string>('key'));
    end;
    Body.Append('<section class="card"><h2>Find your way around this application</h2>'+
      '<p>The left-hand list contains the captured units, types, operations, screen controls and data values. '
      +'Choose a group below, search by name, or expand a unit. Select an item to see its type, source and connections.</p>'+
      '<p><a href="#all_objects">Show all objects</a> &nbsp; <a href="#open_forms">Open form designs</a> &nbsp; '
      +'<a href="#open_screenshots">Open generated screens</a></p></section>');
    if FFacts.GetValue<TJSONArray>('project_screens',nil)<>nil then begin
      Body.Append('<section class="card"><h2>Screens</h2><p>'+IntToStr(FFacts.GetValue<TJSONArray>('project_screens').Count)+
        ' form definitions were found. <a href="#open_screenshots">Screenshots</a> shows the corresponding empty screen views generated by DPH from those definitions. '
        +'These views reproduce saved controls and captions; they are not photographs of a running application.</p><ul>');
      for V in FFacts.GetValue<TJSONArray>('project_screens') do begin
        Row:=V as TJSONObject; Path:=Row.GetValue<string>('source','');
        LabelText:=Row.GetValue<string>('title',''); if LabelText='' then LabelText:=Row.GetValue<string>('name',Path);
        Body.Append('<li><a href="#form_'+THashSHA2.GetHashString(Path)+'">'+Encode(LabelText)+
          '</a> <small>('+Encode(Path)+')</small></li>');
      end;
      Body.Append('</ul></section>');
    end;
    Body.Append('<section class="card"><h2>Objects in the project</h2><p>Choose a category to filter the list on the left.</p>');
    for Kind in Kinds do begin
      if not Counts.TryGetValue(Kind,Count) or (Count=0) then Continue;
      LabelText:=Kind;
      if Kind='routine' then LabelText:='Procedures and functions';
      if Kind='unit' then LabelText:='Pascal units';
      if Kind='component' then LabelText:='Screen controls';
      if Kind='variable' then LabelText:='Unit variables';
      if Kind='local' then LabelText:='Local variables';
      if Kind='field' then LabelText:='Fields';
      if Kind='parameter' then LabelText:='Parameters';
      Body.Append('<p><a href="#kind_'+Kind+'">'+Encode(LabelText)+'</a> ('+IntToStr(Count)+')</p>');
    end;
    Body.Append('</section>');
    Total:=0;
    for V in FFacts.GetValue<TJSONArray>('files') do begin
      Row:=V as TJSONObject; Path:=Row.GetValue<string>('path','');
      KnownPaths.AddOrSetValue(LowerCase(Path),True);
      Kind:=LowerCase(ExtractFileExt(Path)); I:=3;
      if MatchText(Kind,['.dpr','.dproj','.groupproj']) then I:=0
      else if Kind='.pas' then I:=1
      else if MatchText(Kind,['.fmx','.dfm']) then I:=2;
      UnitKey:='';
      if I=1 then UnitKeys.TryGetValue(LowerCase(Path),UnitKey);
      FileGroups[I].Append('<li>');
      if UnitKey<>'' then FileGroups[I].Append(Link(UnitKey)+' &mdash; ');
      FileGroups[I].Append('<code>'+Encode(Path)+'</code></li>');
      Inc(Total);
    end;
    Body.Append('<section class="card"><h2>Files captured from this project</h2><p>'+IntToStr(Total)+
      ' files are indexed. Open a group to see the complete captured list; select a linked unit to explore its members.</p>');
    for I:=0 to 3 do begin
      case I of
        0: GroupName:='Project and startup files';
        1: GroupName:='Pascal units (.pas)';
        2: GroupName:='Saved form designs (.fmx and .dfm)';
      else GroupName:='Other captured files'; end;
      Body.Append('<details class="card"><summary>'+GroupName+'</summary><ul>'+FileGroups[I].ToString+'</ul></details>');
    end;
    Body.Append('</section>');
    OtherCount:=0;
    if FFacts.GetValue<TJSONArray>('project_assets',nil)<>nil then
      for V in FFacts.GetValue<TJSONArray>('project_assets') do begin
        Row:=V as TJSONObject; Path:=Row.GetValue<string>('source','');
        if KnownPaths.ContainsKey(LowerCase(Path)) then Continue;
        Kind:=Row.GetValue<string>('format',''); I:=2;
        if MatchText(Kind,['.md','.markdown','.rst','.adoc','.asciidoc','.txt','.text',
          '.nfo','.log','.html','.htm','.docx','.docm','.doc','.dot','.dotx',
          '.odt','.ott','.sxw','.fodt','.pdf','.rtf','.wpd','.wpt','.wps',
          '.wri','.tex','.csv',
          '.contract','.schema','.json','.xml','.ini','.config','.yml','.yaml']) or
          ContainsText(Path,'contract') or ContainsText(Path,'spec') then I:=0
        else if MatchText(Kind,['.png','.jpg','.jpeg','.svg','.bmp','.rc','.res']) then I:=1;
        OtherGroups[I].Append('<li><code>'+Encode(Path)+'</code></li>'); Inc(OtherCount);
      end;
    if OtherCount>0 then begin
      Body.Append('<section class="card"><h2>Other files found in the application folder</h2>'+
        '<p>These files were found beside the project. A filename alone does not establish their role.</p>');
      for I:=0 to 2 do begin
        case I of
          0: GroupName:='Documents, contracts and configuration';
          1: GroupName:='Images and resources';
        else GroupName:='Other source and data files'; end;
        if OtherGroups[I].Length>0 then Body.Append('<details class="card"><summary>'+GroupName+
          '</summary><ul>'+OtherGroups[I].ToString+'</ul></details>');
      end;
      Body.Append('</section>');
    end;
    if FFacts.GetValue<TJSONArray>('project_guides',nil)<>nil then begin
      Body.Append('<section class="card"><h2>Documents found beside the project</h2>');
      Count:=0;
      for V in FFacts.GetValue<TJSONArray>('project_guides') do begin
        Row:=V as TJSONObject;
        Body.Append('<p><code>'+Encode(Row.GetValue<string>('source',''))+'</code></p>'); Inc(Count);
      end;
      if Count=0 then Body.Append('<p>No matching document or log was found in the scanned project folders.</p>');
      Body.Append('<p><a href="#lesson_2">Read extracted passages in Explore related tasks</a>.</p></section>');
    end;
    Result:=Page('Project map: '+FFacts.GetValue<string>('project','selected application'),Body.ToString);
  finally
    for I:=0 to 3 do FileGroups[I].Free;
    for I:=0 to 2 do OtherGroups[I].Free;
    KnownPaths.Free; UnitKeys.Free; Counts.Free;
    Body.Free;
  end;
end;
function TDPHExplanationModel.ApplicationRouteHTML(AIndex: Integer): string;
var
  Body: TStringBuilder;
  V,W: TJSONValue;
  R,S,Control,Metadata,Fields,Screen,Effect,StartupRow: TJSONObject;
  TaskRecords: TList<TJSONObject>;
  HandlerRelations: TList<TJSONObject>;
  ProjectName,ActionName,ControlName,EventName,Caption,Handler,Source,GuideTitle,GuideBody,EffectVerb: string;
  Guides,GuideSections,Screens,Sites,StartupForms: TJSONArray; Guide,GuideSection: TJSONObject;
  Count,TaskIndex,TaskTotal,ActionIndex,P,EffectCount: Integer;
  HasPurpose: Boolean;
begin
  if not (AIndex in [0..3]) then
    Exit(Page('Learn this app','<p>Choose a learning step for the selected application.</p>'));
  ProjectName:=FFacts.GetValue<string>('project','the selected application');
  Guides:=FFacts.GetValue<TJSONArray>('project_guides',nil);
  Screens:=FFacts.GetValue<TJSONArray>('project_screens',nil);
  StartupForms:=FFacts.GetValue<TJSONArray>('project_startup_forms',nil);
  Sites:=FFacts.GetValue<TJSONArray>('project_sites',nil);
  Body:=TStringBuilder.Create;
  TaskRecords:=TList<TJSONObject>.Create;
  try
    for V in FFacts.GetValue<TJSONArray>('knowledge') do begin
      R:=V as TJSONObject;
      if MatchText(R.GetValue<string>('state',''),['retired','rejected']) then Continue;
      Metadata:=R.GetValue<TJSONObject>('structured_record',nil);
      if Metadata=nil then Metadata:=TJSONObject.ParseJSONValue(R.GetValue<string>('structured_json','{}')) as TJSONObject
      else Metadata:=Metadata.Clone as TJSONObject;
      try
        if (Metadata<>nil) and (Metadata.GetValue<string>('record_type','')='learning_lesson') then TaskRecords.Add(R);
      finally Metadata.Free; end;
    end;
    TaskRecords.Sort(TComparer<TJSONObject>.Construct(function(const L,R:TJSONObject):Integer
    var LeftRecord,RightRecord:TJSONObject;
    begin
      LeftRecord:=L.GetValue<TJSONObject>('structured_record',nil);
      RightRecord:=R.GetValue<TJSONObject>('structured_record',nil);
      if LeftRecord=nil then LeftRecord:=TJSONObject.ParseJSONValue(L.GetValue<string>('structured_json','{}')) as TJSONObject
      else LeftRecord:=LeftRecord.Clone as TJSONObject;
      if RightRecord=nil then RightRecord:=TJSONObject.ParseJSONValue(R.GetValue<string>('structured_json','{}')) as TJSONObject
      else RightRecord:=RightRecord.Clone as TJSONObject;
      try
        Result:=CompareValue(LeftRecord.GetValue<Integer>('learning.order',10000),RightRecord.GetValue<Integer>('learning.order',10000));
        if Result=0 then Result:=CompareText(LeftRecord.GetValue<string>('learning.path',''),RightRecord.GetValue<string>('learning.path',''));
        if Result=0 then Result:=CompareText(L.GetValue<string>('title'),R.GetValue<string>('title'));
      finally LeftRecord.Free;RightRecord.Free;end;
    end));
    TaskTotal:=TaskRecords.Count;
    Body.Append('<section class="card"><p><strong>'+Encode(ProjectName)+
      '</strong> is explored through its starting screen, visible controls, connected actions and available help topics.</p></section>');
    case AIndex of
      0: begin
        Body.Append('<section class="card"><h2>What is this application for?</h2>');
        HasPurpose:=False;
        for V in FFacts.GetValue<TJSONArray>('knowledge') do begin
          R:=V as TJSONObject;
          if MatchText(R.GetValue<string>('state',''),['retired','rejected']) then Continue;
          Metadata:=R.GetValue<TJSONObject>('structured_record',nil);
          if Metadata=nil then Metadata:=TJSONObject.ParseJSONValue(R.GetValue<string>('structured_json','{}')) as TJSONObject
          else Metadata:=Metadata.Clone as TJSONObject;
          try
            if (Metadata=nil) or (Metadata.GetValue<string>('record_type','')<>'project_profile') then Continue;
            Fields:=Metadata.GetValue<TJSONObject>('fields',nil);
            if Fields=nil then Continue;
            Body.Append('<p>'+Encode(Fields.GetValue<string>('purpose',''))+'</p>');
            if Fields.GetValue<string>('department','')<>'' then
              Body.Append('<p><strong>Department:</strong> '+Encode(Fields.GetValue<string>('department'))+'</p>');
            Body.Append('<p><small>Supplied by '+Encode(R.GetValue<string>('owner','unknown contributor'))+
              '; review status: '+Encode(R.GetValue<string>('state','not recorded'))+'.</small></p>');
            HasPurpose:=True; Break;
          finally Metadata.Free; end;
        end;
        if not HasPurpose and (Guides<>nil) then for V in Guides do begin
          Guide:=V as TJSONObject; GuideSections:=Guide.GetValue<TJSONArray>('sections');
          for W in GuideSections do begin
            GuideSection:=W as TJSONObject; GuideTitle:=GuideSection.GetValue<string>('heading','');
            if not (ContainsText(GuideTitle,'purpose') or ContainsText(GuideTitle,'overview') or
              ContainsText(GuideTitle,'about') or ContainsText(GuideTitle,'introduction')) then Continue;
            GuideBody:=Trim(GuideSection.GetValue<string>('text',''));
            if GuideBody='' then Continue;
            Body.Append('<p>'+Encode(Copy(GuideBody,1,1800)).Replace(sLineBreak,'<br>')+'</p>');
            HasPurpose:=True; Break;
          end;
          if HasPurpose then Break;
        end;
        if not HasPurpose then for V in FFacts.GetValue<TJSONArray>('knowledge') do begin
          R:=V as TJSONObject;
          if MatchText(R.GetValue<string>('state',''),['retired','rejected']) or
            (R.GetValue<string>('kind','')<>'orientation') then Continue;
          Body.Append('<p><strong>Supplied orientation note:</strong> '+Encode(R.GetValue<string>('body',''))+
            '<br><small>Supplied by '+Encode(R.GetValue<string>('owner','unknown contributor'))+
            '; review status: '+Encode(R.GetValue<string>('state','not recorded'))+'.</small></p>');
          Break;
        end;
        if not HasPurpose then begin
          Caption:=''; Source:='';
          for V in FFacts.GetValue<TJSONArray>('symbols') do begin
            S:=V as TJSONObject;
            if (S.GetValue<string>('kind','')<>'component') or
              not MatchText(ExtractFileExt(S.GetValue<string>('range.source','')),['.fmx','.dfm']) or
              not ContainsText(S.GetValue<string>('name',''),'hero') or
              (S.GetValue<TJSONArray>('serialized_properties',nil)=nil) then Continue;
            for W in S.GetValue<TJSONArray>('serialized_properties') do
              if MatchText(W.GetValue<string>('name',''),['Text','Caption']) and
                (Length(Trim(W.GetValue<string>('value','')))>8) then begin
                Caption:=W.GetValue<string>('value'); Source:=S.GetValue<string>('range.source'); Break; end;
            if Caption<>'' then Break;
          end;
          if Caption<>'' then Body.Append('<p>'+Encode(Caption)+'</p>')
          else Body.Append('<p>Begin with the project title and the window titles below; they show how the application presents itself.</p>');
        end;
        Body.Append('</section>');
        Count:=0;
        if Sites<>nil then for V in Sites do
          if Trim(V.GetValue<string>('text',''))<>'' then Inc(Count);
        if Count>0 then begin
          Body.Append('<section class="card"><h2>Web information named by this project</h2>');
          for V in Sites do begin
            R:=V as TJSONObject;
            if Trim(R.GetValue<string>('text',''))<>'' then
              Body.Append('<p>'+Encode(Copy(R.GetValue<string>('text',''),1,900))+'</p>');
          end;
          Body.Append('</section>');
        end;
        Body.Append('<section class="card"><h2>Project files</h2>');
        Count:=0;
        for V in FFacts.GetValue<TJSONArray>('files') do begin
          R:=V as TJSONObject; Source:=R.GetValue<string>('path','');
          if not MatchText(ExtractFileExt(Source),['.dpr','.dproj','.groupproj']) then Continue;
          Body.Append('<p><code>'+Encode(Source)+'</code></p>');
          Inc(Count);
        end;
        if Count=0 then Body.Append('<p>No Delphi project file was available in this capture.</p>');
        Body.Append('</section><section class="card"><h2>Where the application starts</h2>');
        Count:=0;
        if StartupForms<>nil then for V in StartupForms do begin
          StartupRow:=V as TJSONObject;
          if Count=0 then Caption:='The first form registered for automatic creation is '
          else Caption:='The program also registers ';
          Source:=StartupRow.GetValue<string>('screen','');
          if Screens<>nil then for W in Screens do begin
            Screen:=W as TJSONObject;
            if SameText(Screen.GetValue<string>('source',''),Source) and (Source<>'') then begin
              GuideTitle:=Screen.GetValue<string>('title','');
              if GuideTitle='' then GuideTitle:=StartupRow.GetValue<string>('instance','form');
              Caption:=Caption+'<a href="#form_'+THashSHA2.GetHashString(Source)+'">'+
                Encode(GuideTitle)+'</a> '; Break;
            end;
          end;
          if not ContainsText(Caption,'</a>') then Caption:=Caption+
            Encode(StartupRow.GetValue<string>('instance','form'))+' ';
          Body.Append('<p>'+Caption+'(<code>'+Encode(StartupRow.GetValue<string>('class',''))+
            '</code>).');
          if StartupRow.GetValue<string>('unit','')<>'' then
            Body.Append(' Its form class is declared in <code>'+Encode(StartupRow.GetValue<string>('unit',''))+'</code>.');
          Body.Append(' <small>'+Encode(StartupRow.GetValue<string>('program',''))+':'+
            IntToStr(StartupRow.GetValue<Integer>('line',0))+'</small></p>');
          Inc(Count);
        end;
        if Count=0 then Body.Append('<p>The available project files do not identify which form opens first. Explore the screens below to find the application entry point.</p>');
        Body.Append('</section><section class="card"><h2>Application screens</h2>');
        Count:=0;
        if Screens<>nil then for V in Screens do begin
          Screen:=V as TJSONObject;
          Body.Append('<p><strong>'+Encode(Screen.GetValue<string>('title',Screen.GetValue<string>('name','Screen')))+
            '</strong> &mdash; <a href="#form_'+THashSHA2.GetHashString(Screen.GetValue<string>('source',''))+
            '">explore this screen</a>');
          for W in FFacts.GetValue<TJSONArray>('symbols') do begin
            S:=W as TJSONObject;
            if (S.GetValue<string>('kind','')='component') and
              SameText(S.GetValue<string>('range.source',''),Screen.GetValue<string>('source','')) and
              SameText(S.GetValue<string>('name',''),Screen.GetValue<string>('source','')+'.'+Screen.GetValue<string>('name','')) then begin
              Body.Append(' &mdash; open '+Link(S.GetValue<string>('key'))); Break;
            end;
          end;
          Body.Append('</p>');
          Inc(Count);
        end;
        if Count=0 then Body.Append('<p>No saved form design was captured in the selected project files.</p>')
        else Body.Append('<p>'+IntToStr(Count)+' application forms were found. '
          +'<a href="#open_screenshots">Open available screen images</a>.</p>');
        Body.Append('</section><section class="card"><p><a href="#lesson_1">Next: learn a task in '+Encode(ProjectName)+
          '</a></p></section>');
      end;
      1,2: begin
        if AIndex=1 then
          Body.Append('<section class="card"><h2>Start with a task in '+Encode(ProjectName)+'</h2>')
        else
          Body.Append('<section class="card"><h2>Other tasks and actions in '+Encode(ProjectName)+'</h2>');
        Count:=0; TaskIndex:=0;
        for R in TaskRecords do begin
          Metadata:=R.GetValue<TJSONObject>('structured_record',nil);
          if Metadata=nil then Metadata:=TJSONObject.ParseJSONValue(R.GetValue<string>('structured_json','{}')) as TJSONObject
          else Metadata:=Metadata.Clone as TJSONObject;
          try
            if (Metadata=nil) or (Metadata.GetValue<string>('record_type','')<>'learning_lesson') then Continue;
            Inc(TaskIndex);
            if ((AIndex=1) and (TaskIndex<>1)) or ((AIndex=2) and (TaskIndex=1)) then Continue;
            Fields:=Metadata.GetValue<TJSONObject>('fields');
            Body.Append('<h3>'+Encode(R.GetValue<string>('title'))+'</h3><p><strong>Purpose:</strong> '+
              Encode(Fields.GetValue<string>('purpose'))+'</p><p><strong>Before you begin:</strong> '+
              Encode(Fields.GetValue<string>('prerequisites'))+'</p><ol>');
            for W in Metadata.GetValue<TJSONArray>('steps') do
              Body.Append('<li>'+Encode(W.GetValue<string>('action'))+
                '<br><strong>Expected:</strong> '+Encode(W.GetValue<string>('expected_result'))+'</li>');
            Body.Append('</ol><p><strong>Final result:</strong> '+Encode(Fields.GetValue<string>('expected_result'))+
              '</p><p><strong>If it differs:</strong> '+Encode(Fields.GetValue<string>('troubleshooting'))+
              '</p><p><strong>Practice:</strong> '+Encode(Fields.GetValue<string>('practice'))+
              '</p><p><small>Supplied by '+Encode(R.GetValue<string>('owner'))+
              '; review status: '+Encode(R.GetValue<string>('state'))+'.</small></p>');
            if R.GetValue<string>('state','')<>'verified' then
              Body.Append('<p>This task has not been verified by a reviewer. Confirm its instructions and expected result before relying on it.</p>');
            Inc(Count); if (AIndex=1) or (Count>=5) then Break;
          finally Metadata.Free; end;
        end;
        if (AIndex=1) and (Count=0) then
          Body.Append('<p>Start with the first labeled action traced from a saved screen into source below. The application’s own documents may also describe how to use it.</p>');
        if (AIndex=2) and (Count=0) then
          Body.Append('<p>Explore the other actions captured in this application’s saved screens and source below.</p>');
        Body.Append('</section>');
        if (Guides<>nil) and (Guides.Count>0) then begin
          Body.Append('<section class="card"><h2>Read this application’s own documents</h2><p>These passages come from files in the selected project folder and are identified by file and fingerprint.</p>');
          Count:=0;
          for V in Guides do begin
            Guide:=V as TJSONObject;
            for W in Guide.GetValue<TJSONArray>('sections') do begin
              GuideSection:=W as TJSONObject; GuideTitle:=GuideSection.GetValue<string>('heading','');
              GuideBody:=Trim(GuideSection.GetValue<string>('text',''));
              if (GuideBody='') or not
                (ContainsText(GuideTitle,'start') or ContainsText(GuideTitle,'using') or
                 ContainsText(GuideTitle,'main form') or ContainsText(GuideTitle,'playlist') or
                 ContainsText(GuideTitle,'responsibilit') or
                 ContainsText(GuideTitle,'editing') or ContainsText(GuideTitle,'schedule') or
                 ContainsText(GuideTitle,'operation') or ContainsText(GuideTitle,'quick reference')) then Continue;
              if AIndex=1 then begin
                if Count>=8 then Break;
              end else if Count>=8 then Break;
              Body.Append('<details class="card"><summary>'+Encode(GuideTitle)+'</summary><pre>'+Encode(GuideBody)+
                '</pre><small>From '+Encode(Guide.GetValue<string>('source'))+'</small></details>');
              Inc(Count);
            end;
          end;
          if Count=0 then Body.Append('<p>The local guides do not have a clearly labeled getting-started or task section. Explore their headings below and use the forms and actions in this route.</p>');
          Body.Append('</section>');
        end;
        begin
          Body.Append('<section class="card"><h2>Actions found in this application</h2>');
          Count:=0; ActionIndex:=0;
          for V in FFacts.GetValue<TJSONArray>('relationships') do begin
            R:=V as TJSONObject;
            if R.GetValue<string>('kind','')<>'binds' then Continue;
            if not FSymbols.TryGetValue(R.GetValue<string>('from',''),S) then Continue;
            ActionName:=S.GetValue<string>('name',''); P:=LastDelimiter('.',ActionName);
            if P=0 then Continue;
            EventName:=Copy(ActionName,P+1,MaxInt);
            if not MatchText(EventName,['OnClick','OnExecute','OnDblClick','OnTap']) then Continue;
            ControlName:=Copy(ActionName,1,P-1); Caption:='';
            for W in FFacts.GetValue<TJSONArray>('symbols') do begin
              Control:=W as TJSONObject;
              if not SameText(Control.GetValue<string>('name',''),ControlName) then Continue;
              if Control.GetValue<TJSONArray>('serialized_properties',nil)<>nil then
                for var PropertyValue in Control.GetValue<TJSONArray>('serialized_properties') do
                  if MatchText(PropertyValue.GetValue<string>('name',''),['Text','Caption']) then begin
                    Caption:=PropertyValue.GetValue<string>('value',''); Break;
                  end;
              Break;
            end;
            Handler:=R.GetValue<string>('to','');
            if Caption='' then Continue;
            Inc(ActionIndex);
            if (AIndex=2) and (ActionIndex=1) then Continue;
            if (AIndex=1) and (ActionIndex>1) then Break;
            Body.Append('<h3>'+Encode(Caption)+'</h3><p>On the saved screen in '+
              Encode(R.GetValue<string>('range.source','a form'))+', this control connects '+
              Encode(EventName)+' to ');
            if (Handler<>'') and FSymbols.ContainsKey(Handler) then
              Body.Append(Link(Handler)+'. ')
            else Body.Append('a handler that was not resolved in this capture. ');
            Body.Append('<small>'+Encode(R.GetValue<string>('range.source',''))+':'+
              IntToStr(R.GetValue<Integer>('range.line',0))+'</small></p>');
            if FOutgoing.TryGetValue(Handler,HandlerRelations) then begin
              EffectCount:=0;
              for Effect in HandlerRelations do begin
                if not MatchText(Effect.GetValue<string>('kind',''),
                  ['calls','reads','writes','shows_form','shows_modal_form','output_candidate','static_sql']) then Continue;
                if EffectCount=0 then Body.Append('<p>The connected code shows:</p><ul>');
                EffectVerb:=Effect.GetValue<string>('kind','').Replace('_',' ');
                if EffectVerb='calls' then EffectVerb:='Calls';
                if EffectVerb='reads' then EffectVerb:='Reads';
                if EffectVerb='writes' then EffectVerb:='May update';
                if EffectVerb='shows form' then EffectVerb:='May open';
                if EffectVerb='shows modal form' then EffectVerb:='May open a dialog';
                if EffectVerb='output candidate' then EffectVerb:='May write an output';
                if EffectVerb='static sql' then EffectVerb:='Uses a saved database command';
                Body.Append('<li>'+Encode(EffectVerb)+' ');
                if FSymbols.ContainsKey(Effect.GetValue<string>('to','')) then
                  Body.Append(Link(Effect.GetValue<string>('to')))
                else Body.Append(Encode(Effect.GetValue<string>('label','an unresolved target')));
                Body.Append(' <small>('+Encode(Effect.GetValue<string>('range.source',''))+':'+
                  IntToStr(Effect.GetValue<Integer>('range.line',0))+')</small></li>');
                Inc(EffectCount); if EffectCount>=6 then Break;
              end;
              if EffectCount>0 then Body.Append('</ul>');
            end;
            if AIndex=1 then Body.Append('<p>Use the linked handler and its source evidence to follow the action further. The saved files describe the intended path; observe the running application to check the final result.</p>');
            Inc(Count); if (AIndex=1) or (Count>=8) then Break;
          end;
          if Count=0 then begin
            Body.Append('<p>No labeled click action could be connected to readable code. These saved interface labels still help you choose a screen to explore:</p><ul>');
            Count:=0;
            for V in FFacts.GetValue<TJSONArray>('symbols') do begin
              S:=V as TJSONObject;
              if (S.GetValue<string>('kind','')<>'component') or
                not MatchText(ExtractFileExt(S.GetValue<string>('range.source','')),['.fmx','.dfm']) or
                (S.GetValue<TJSONArray>('serialized_properties',nil)=nil) then Continue;
              Caption:='';
              for W in S.GetValue<TJSONArray>('serialized_properties') do
                if MatchText(W.GetValue<string>('name',''),['Text','Caption']) and
                  (Length(Trim(W.GetValue<string>('value','')))>3) then begin
                  Caption:=W.GetValue<string>('value'); Break; end;
              if (Caption='') or SameText(Caption,S.GetValue<string>('name','')) then Continue;
              Body.Append('<li>'+Encode(Caption)+' <small>('+Encode(S.GetValue<string>('range.source',''))+')</small></li>');
              Inc(Count); if Count>=8 then Break;
            end;
            if Count=0 then Body.Append('<li>No descriptive labels were saved in the captured forms.</li>');
            Body.Append('</ul>');
          end;
          Body.Append('</section>');
        end;
        if AIndex=2 then begin
          if (Guides<>nil) and (Guides.Count>0) then begin
            Body.Append('<section class="card"><h2>More from the project’s documentation</h2><p>Open a topic to read the corresponding passage from the selected application’s own guide.</p>');
            for V in Guides do begin
              Guide:=V as TJSONObject;
              Body.Append('<h3>'+Encode(Guide.GetValue<string>('source'))+'</h3>');
              if Guide.GetValue<TJSONArray>('sections').Count=0 then
                Body.Append('<p><small>No selectable text could be extracted from this file. It may contain only images, require a password, or need a document converter.</small></p>');
              for W in Guide.GetValue<TJSONArray>('sections') do begin
                GuideSection:=W as TJSONObject;
                GuideBody:=Trim(GuideSection.GetValue<string>('text',''));
                if GuideBody='' then Continue;
                Body.Append('<details class="card"><summary>'+Encode(GuideSection.GetValue<string>('heading','Topic'))+
                  '</summary><pre>'+Encode(GuideBody)+'</pre><small>Source: '+Encode(Guide.GetValue<string>('source'))+'</small></details>');
              end;
            end;
            Body.Append('</section>');
          end;
          Body.Append('<section class="card"><h2>Supplied explanations and worked examples</h2>');
          Count:=0;
          for V in FFacts.GetValue<TJSONArray>('knowledge') do begin
            R:=V as TJSONObject;
            if MatchText(R.GetValue<string>('state',''),['retired','rejected']) then Continue;
            Metadata:=R.GetValue<TJSONObject>('structured_record',nil);
            if Metadata=nil then Metadata:=TJSONObject.ParseJSONValue(R.GetValue<string>('structured_json','{}')) as TJSONObject
            else Metadata:=Metadata.Clone as TJSONObject;
            try
              if (Metadata=nil) or (Metadata.GetValue<string>('record_type','')<>'learning_card') then Continue;
              Fields:=Metadata.GetValue<TJSONObject>('fields');
              Body.Append('<h3>'+Encode(Metadata.GetValue<string>('category'))+': '+
                Encode(Fields.GetValue<string>('name'))+'</h3><p>'+Encode(Fields.GetValue<string>('meaning'))+
                '</p><p><strong>Example:</strong> '+Encode(Fields.GetValue<string>('example'))+
                '</p><p><strong>Limits and mistakes:</strong> '+Encode(Fields.GetValue<string>('limits'))+
                '</p><p><strong>If the result differs:</strong> '+Encode(Fields.GetValue<string>('help'))+
                '</p><p><strong>Practice and expected answer:</strong> '+Encode(Fields.GetValue<string>('practice'))+
                '</p><p><small>Supplied by '+Encode(R.GetValue<string>('owner'))+
                '; review status: '+Encode(R.GetValue<string>('state'))+'.</small></p>');
              Inc(Count); if Count>=8 then Break;
            finally Metadata.Free; end;
          end;
          if Count=0 then Body.Append('<p>No field, rule, error or output explanation has been supplied for this application yet.</p>');
          Body.Append('</section>');
          Count:=0;
          for V in FFacts.GetValue<TJSONArray>('knowledge') do begin
            R:=V as TJSONObject;
            if MatchText(R.GetValue<string>('state',''),['retired','rejected']) or
              not MatchText(R.GetValue<string>('kind',''),['user_help','troubleshooting']) then Continue;
            Metadata:=R.GetValue<TJSONObject>('structured_record',nil);
            if Metadata=nil then Metadata:=TJSONObject.ParseJSONValue(R.GetValue<string>('structured_json','{}')) as TJSONObject
            else Metadata:=Metadata.Clone as TJSONObject;
            try
              if (Metadata<>nil) and (Metadata.GetValue<string>('record_type','')<>'') then Continue;
              if Count=0 then Body.Append('<section class="card"><h2>Other supplied guidance</h2>');
              Body.Append('<h3>'+Encode(R.GetValue<string>('title','Guidance'))+'</h3><p>'+
                Encode(R.GetValue<string>('body','')).Replace(sLineBreak,'<br>')+
                '</p><p><small>Supplied by '+Encode(R.GetValue<string>('owner','unknown contributor'))+
                '; review status: '+Encode(R.GetValue<string>('state','not recorded'))+'.</small></p>');
              Inc(Count); if Count>=5 then Break;
            finally Metadata.Free; end;
          end;
          if Count>0 then Body.Append('</section>');
        end;
        if AIndex=1 then Body.Append('<section class="card"><p><a href="#task_reader">Open the step-by-step task reader</a> when a task has been supplied. <a href="#lesson_2">Explore related tasks</a>.</p></section>')
        else Body.Append('<section class="card"><p><a href="#lesson_3">Check what is still unknown</a>.</p></section>');
      end;
      3: begin
        Body.Append('<section class="card"><h2>What the captured files cannot confirm</h2><p>Use the preceding screens, documents and traced actions first. The points below identify outcomes that source reading alone cannot prove.</p><ul>');
        HasPurpose:=False;
        for V in FFacts.GetValue<TJSONArray>('knowledge') do begin
          R:=V as TJSONObject;
          if MatchText(R.GetValue<string>('state',''),['retired','rejected']) then Continue;
          Metadata:=R.GetValue<TJSONObject>('structured_record',nil);
          if Metadata=nil then Metadata:=TJSONObject.ParseJSONValue(R.GetValue<string>('structured_json','{}')) as TJSONObject
          else Metadata:=Metadata.Clone as TJSONObject;
          try
            if (Metadata<>nil) and (Metadata.GetValue<string>('record_type','')='project_profile') then HasPurpose:=True;
          finally Metadata.Free; end;
        end;
        if not HasPurpose and (Guides<>nil) then
          for V in Guides do begin
            Guide:=V as TJSONObject;
            for W in Guide.GetValue<TJSONArray>('sections') do
              if ContainsText(W.GetValue<string>('heading',''),'purpose') and
                (Trim(W.GetValue<string>('text',''))<>'') then begin HasPurpose:=True; Break; end;
            if HasPurpose then Break;
          end;
        if not HasPurpose then
          Body.Append('<li>The saved titles suggest a purpose, but the captured documents do not explain every user role or business goal.</li>');
        if TaskTotal=0 then Body.Append('<li>Source traces show possible action paths; they cannot demonstrate the running result or a safe operating procedure.</li>');
        if FFacts.GetValue<TJSONArray>('screenshots').Count=0 then Body.Append('<li>The saved form layout shows controls and positions, but no photograph of the running screen is available.</li>');
        Body.Append('<li>Permissions, external services and recovery behavior require observation in the running application.</li></ul>');
        Count:=0;
        for V in FFacts.GetValue<TJSONArray>('author_questions') do begin
          R:=V as TJSONObject;
          if R.GetValue<string>('answer_kind','')<>'user_help' then Continue;
          if Count=0 then Body.Append('<h3>Questions prepared for this application</h3>');
          Body.Append('<p>'+Encode(R.GetValue<string>('prompt'))+'</p>');
          Inc(Count); if Count>=3 then Break;
        end;
        if Count>0 then Body.Append('<p><a href="#ask_author">Open the recorded questions</a> for further investigation of '+Encode(ProjectName)+'.</p>');
        Body.Append('</section>');
      end;
    end;
    Result:=Page(ApplicationRouteTitle(AIndex)+': '+ProjectName,Body.ToString);
  finally TaskRecords.Free; Body.Free; end;
end;
function TDPHExplanationModel.TopicHTML(AIndex: Integer): string;
var Body: TStringBuilder; V: TJSONValue; S: TJSONObject; Kind,Key: string; Count: Integer;
begin
  Body:=TStringBuilder.Create;
  try
    Body.Append(Prose(TopicText(AIndex))); Count:=0;
    if AIndex in [1,2,3,4,5,6,7] then begin Body.Append('<h2>Open the evidence</h2><div class="card">');
      for V in FFacts.GetValue<TJSONArray>('symbols') do begin S:=V as TJSONObject; Kind:=S.GetValue<string>('kind'); Key:=S.GetValue<string>('key');
        if ((AIndex=1) and (Kind='unit')) or ((AIndex=2) and (Kind='component')) or ((AIndex=3) and (Kind='event')) or
          ((AIndex=4) and MatchText(Kind,['routine','anonymous']) and FFlow.ContainsKey(Key)) or
          ((AIndex=5) and MatchText(Kind,['field','property','variable'])) or ((AIndex=6) and (Kind='unit')) or ((AIndex=7) and (Kind='routine')) then begin
          Body.Append('<p>'+Link(Key)+'<br><small>'+Encode(Citation(S))+'</small></p>'); Inc(Count); if Count>=50 then Break;
        end;
      end;
      if Count=0 then Body.Append('<p>No matching object is available in this captured scope.</p>');
      if Count>=50 then Body.Append('<p>First 50 objects shown. Use Explorer search to locate another object.</p>'); Body.Append('</div>');
    end;
    Result:=Page(TopicTitle(AIndex),Body.ToString);
  finally Body.Free; end;
end;
end.
