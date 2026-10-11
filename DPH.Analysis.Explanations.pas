unit DPH.Analysis.Explanations;

interface
uses System.SysUtils, System.JSON, System.Generics.Collections;
type
  // A deterministic explanation of captured evidence, never an external AI call.
  TDPHExplanationModel = class
  private
    FFacts: TJSONObject;
    FSymbols: TDictionary<string,TJSONObject>;
    FOutgoing,FIncoming,FFlow: TObjectDictionary<string,TList<TJSONObject>>;
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
    function TopicText(AIndex: Integer): string;
    function TopicHTML(AIndex: Integer): string;
    function FlowSVG(const AKey: string): string;
    function FlowHTML(const AKey: string): string;
    function TraceHTML(const AKey: string): string;
    class function TopicTitle(AIndex: Integer): string; static;
  end;
implementation
uses System.StrUtils, System.Hash, System.Math, System.Classes, System.Generics.Defaults;

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
begin FFlow.Free; FIncoming.Free; FOutgoing.Free; FSymbols.Free; inherited; end;
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
    0: Result:='Start here'; 1: Result:='How the program starts'; 2: Result:='Screens and user actions';
    3: Result:='Follow an event into the code'; 4: Result:='Logic, branches and background work';
    5: Result:='Data, configuration and outputs'; 6: Result:='Architecture and dependencies';
    7: Result:='Plan a maintenance change'; 8: Result:='Coverage and troubleshooting';
    9: Result:='Questions for the original author'; 10: Result:='Delphi terms explained';
  else Result:='Project learning guide'; end;
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
        if not MatchText(R.GetValue<string>('kind'),['calls','binds','passes_callback','schedules','assigns_callback','owns']) then Continue;
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
function TDPHExplanationModel.Page(const ATitle,ABody: string): string;
begin
  Result:='<!doctype html><html lang="en"><head><meta charset="utf-8"><meta http-equiv="Content-Security-Policy" content="default-src ''none''; style-src ''unsafe-inline''; img-src ''self'' data:; script-src ''none''; connect-src ''none''; base-uri ''none''"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+
    Encode(ATitle)+'</title><style>body{font:16px/1.6 Segoe UI,Arial,sans-serif;color:#20364a;margin:0;background:#f1f5fa}main{max-width:1100px;margin:auto;padding:26px}header{background:#146cb4;color:white;padding:26px;border-bottom:5px solid #f28c28}'+
    'h1{font-size:28px;margin:0}body{overflow-wrap:anywhere}*{box-sizing:border-box}'+
    'h2{font-size:21px;color:#146cb4}h3{font-size:18px}'+
    '.card{background:white;border:1px solid #dce5ef;border-radius:9px;padding:20px;margin:16px 0}.badge{display:inline-block;background:#eaf3fc;padding:3px 8px;border-radius:4px;font-size:12px}'+
    '.warning{border-left:5px solid #f28c28;padding:12px;background:#fff3e4}a{color:#146cb4}code{overflow-wrap:anywhere;font-size:13px}'+
    'pre{white-space:pre-wrap;font:15px/1.6 Segoe UI,Arial,sans-serif}table{border-collapse:collapse;table-layout:fixed;width:100%;font-size:13px}td,th{border:1px solid #dce5ef;padding:9px;text-align:left;vertical-align:top;overflow-wrap:anywhere}'+
    'small{color:#53697f}.diagram{overflow:auto}svg text{font-family:Segoe UI,Arial,sans-serif}@media print{body{background:white}main{padding:0}'+
    '.card{break-inside:avoid}}</style></head><body><header><h1>'+Encode(ATitle)+'</h1><p>'+
    Encode(FFacts.GetValue<string>('project'))+' | generation '+FFacts.GetValue('generation_id').Value+' | '+Encode(FFacts.GetValue<string>('configuration'))+' / '+Encode(FFacts.GetValue<string>('platform'))+'</p></header><main>'+
    IfThen(FFacts.GetValue<Boolean>('stale') or not FFacts.GetValue<Boolean>('analysis_complete'),'<p class="warning">Historical or partial evidence. Read the coverage gaps before relying on this explanation.</p>','')+ABody+
    '<p><small>Deterministic explanation of captured static evidence. No external AI, no runtime execution, no invented business rationale.</small></p></main></body></html>';
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
      Linked:=R.GetValue<TJSONArray>('links').Count=0;
      for W in R.GetValue<TJSONArray>('links') do if (W as TJSONObject).GetValue<string>('canonical_key','')=AKey then Linked:=True;
      if not Linked then Continue;
      Text.Append('<section class="card"><h2>Attributed knowledge: '+Encode(R.GetValue<string>('title'))+'</h2><p>'+Encode(R.GetValue<string>('state'))+' | '+Encode(R.GetValue<string>('owner'))+'</p><p>'+Encode(R.GetValue<string>('body'))+'</p></section>');
    end;
    Text.Append('<section class="card"><h2>What still needs explanation</h2><p>The business reason, expected user outcome, operational prerequisites and recovery procedure need an attributed answer if they are not recorded above. A symbol name cannot establish them.</p><h3>Before you change it</h3><p>Inspect callers, event bindings, writes and conditional variants. Open Change impact, review linked rules, run authorized project-specific tests, then reassess and review affected notes.</p></section>');
    Body:=Text.ToString;
  finally Text.Free; end;
  try Body:=Body+TraceHTML(AKey); except on E: Exception do raise EReadError.Create('Trace: '+E.Message); end;
  try Body:=Body+FlowSVG(AKey); except on E: Exception do raise EReadError.Create('Flow: '+E.Message); end;
  Result:=Page(S.GetValue<string>('name'),Body);
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
        Text.AppendLine('Ask and record answers against the selected object:');
        Text.AppendLine('What business result should this operation produce? What inputs are mandatory and what makes them valid?');
        Text.AppendLine('Which outputs should the user inspect, and what proves success? What can fail and how should a user recover?');
        Text.AppendLine('Which rule is historical or contractual? What must never change? Which tests cover the behavior?');
        Text.AppendLine('What must an operator install or configure? Which deployment steps and permissions are required?');
        Text.AppendLine('For asynchronous paths: which thread owns the operation, how is completion reported, and what cancels it?');
        Text.AppendLine('Use Knowledge to preserve the named author, evidence and review state. No author answer is generated by a symbol name.');
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
