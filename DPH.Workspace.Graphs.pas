unit DPH.Workspace.Graphs;
interface
uses System.JSON, DPH.Workspace.Model;
type
  TDPHGraphProjection = class
  public
    class function Workflow(ARow:TJSONObject; AKnowledge:TJSONArray; AGeneration:Int64):TJSONObject;static;
    class function WorkflowSVG(AGraph:TJSONObject):string;static;
    class function Group(AView: TDPHWorkspaceView; AGraph: TJSONObject; const ALevel: string; ALimit: Integer = 120): TJSONObject; static;
  end;
implementation
uses System.SysUtils, System.StrUtils, System.Generics.Collections, System.Classes, System.Hash, System.NetEncoding;


class function TDPHGraphProjection.Workflow(ARow:TJSONObject; AKnowledge:TJSONArray; AGeneration:Int64):TJSONObject;
var RecordValue,Step,Node,Edge,Link,Process,Revision,Metadata:TJSONObject;
 Nodes,Edges,Steps,Processes,Links,History:TJSONArray;V,W,L:TJSONValue;I:Integer;Target,Key,Detail:string;
 function Structured(R:TJSONObject):TJSONObject;
 begin
  if R.GetValue('structured_record')<>nil then Result:=R.GetValue<TJSONObject>('structured_record').Clone as TJSONObject
  else Result:=TJSONObject.ParseJSONValue(R.GetValue<string>('structured_json','{}')) as TJSONObject;
 end;
 procedure AddNode(const ID,LabelText,Kind,Text:string);
 begin Node:=TJSONObject.Create.AddPair('id',ID).AddPair('label',LabelText).AddPair('kind',Kind).AddPair('detail',Text);Nodes.AddElement(Node);end;
 procedure AddEdge(const AFrom,ATo,Kind,LabelText:string);
 begin Edge:=TJSONObject.Create.AddPair('from',AFrom).AddPair('to',ATo).AddPair('kind',Kind).AddPair('label',LabelText)
  .AddPair('resolution','attributed_manual').AddPair('rule','saved_workflow_sequence_not_runtime_trace');Edges.AddElement(Edge);end;
 begin
 if ARow=nil then raise EArgumentException.Create('Select a saved departmental workflow');
 RecordValue:=Structured(ARow);
 try
 TDPHWorkspaceView.ValidateDepartmentalWorkflow(RecordValue);
 Result:=TJSONObject.Create;
 try
 Result.AddPair('kind','Business process').AddPair('generation_id',TJSONNumber.Create(AGeneration))
  .AddPair('workflow_id',RecordValue.GetValue<string>('workflow_id')).AddPair('knowledge_id',ARow.GetValue<string>('id'))
  .AddPair('revision',ARow.GetValue<string>('revision')).AddPair('title',ARow.GetValue<string>('title'))
  .AddPair('state',ARow.GetValue<string>('state')).AddPair('author',ARow.GetValue<string>('owner'))
  .AddPair('reviewer',ARow.GetValue<string>('reviewer','')).AddPair('source_generation',ARow.GetValue<string>('source_generation','0'))
  .AddPair('runtime_trace',TJSONBool.Create(False)).AddPair('truncated',TJSONBool.Create(False));
 Result.AddPair('qualification','Attributed end-to-end workflow. Blue arrows: authored normal sequence; orange routes: authored exceptions. Review approves content, not execution or authorization. Unknown remains unresolved. Process links identify exact historical revisions, not current business approval.');
 Nodes:=TJSONArray.Create;Edges:=TJSONArray.Create;Processes:=TJSONArray.Create;
 Result.AddPair('nodes',Nodes).AddPair('edges',Edges).AddPair('process_links',Processes);
 Steps:=RecordValue.GetValue<TJSONArray>('steps');
 for I:=0 to Steps.Count-1 do begin Step:=Steps.Items[I] as TJSONObject;Detail:='';
  for Key in DPHWorkflowStepKeys do Detail:=Detail+Key+': '+Step.GetValue<string>(Key)+sLineBreak;
  AddNode(Step.GetValue<string>('step_id'),'Step '+IntToStr(I+1)+': '+Step.GetValue<string>('action'),'workflow_step',Detail);
  Node.AddPair('department',Step.GetValue<string>('department')).AddPair('role',Step.GetValue<string>('role'));
 end;
 AddNode('End','End','workflow_end','End of this authored workflow; successful runtime completion is unobserved.');
 for I:=0 to Steps.Count-1 do begin Step:=Steps.Items[I] as TJSONObject;Key:=Step.GetValue<string>('step_id');Target:='End';
  if I+1<Steps.Count then Target:=Steps.Items[I+1].GetValue<string>('step_id');
  AddEdge(Key,Target,'normal',Step.GetValue<string>('handoff'));
  Target:=Step.GetValue<string>('exception_target');
  if Target='Unknown' then begin Target:='unknown|'+Key;AddNode(Target,'Unknown exception destination for step '+IntToStr(I+1),'unresolved','Resolve the exception route with the responsible maintainer.');end;
  AddEdge(Key,Target,'exception',Step.GetValue<string>('exception_handling'));
 end;
 if (AKnowledge<>nil) and ARow.TryGetValue<TJSONArray>('rich_links',Links) then for L in Links do begin
  Link:=L as TJSONObject;if Link.GetValue<string>('target_kind','')<>'section' then Continue;
  for V in AKnowledge do begin Process:=V as TJSONObject;if not Process.TryGetValue<TJSONArray>('history',History) then Continue;
   for W in History do begin Revision:=W as TJSONObject;if Revision.GetValue<string>('revision')<>Link.GetValue<string>('target_id') then Continue;
    Metadata:=Structured(Revision);
    try
     if (Metadata=nil) or (Metadata.GetValue<string>('record_type','')<>'business_process') then Continue;
     TDPHWorkspaceView.ValidateBusinessProcess(Metadata);
     Node:=TJSONObject.Create.AddPair('knowledge_id',Process.GetValue<string>('id')).AddPair('title',Process.GetValue<string>('title'))
      .AddPair('revision',Revision.GetValue<string>('revision')).AddPair('process_id',Metadata.GetValue<string>('process_id'))
      .AddPair('state',Revision.GetValue<string>('verification_state')).AddPair('reviewer',Revision.GetValue<string>('reviewer',''))
      .AddPair('reviewed',TJSONBool.Create((Revision.GetValue<string>('verification_state')='verified') and (Revision.GetValue<string>('reviewer','')<>'')))
      .AddPair('link_role',Link.GetValue<string>('link_role'));Processes.AddElement(Node);
    finally Metadata.Free;end;
   end;
  end;
 end;
 except Result.Free;raise;end;
 finally RecordValue.Free;end;
end;
class function TDPHGraphProjection.WorkflowSVG(AGraph:TJSONObject):string;
var Text:TStringBuilder;Nodes,Edges:TJSONArray;V:TJSONValue;N,E:TJSONObject;I,A,B,Y1,Y2,H:Integer;
 Indices:TDictionary<string,Integer>;Colour,Dash,Route,Caption:string;
 function Enc(const S:string):string;
 begin Result:=TNetEncoding.HTML.Encode(S);end;
 function Y(Index:Integer):Integer;
 begin Result:=40+Index*190;end;
begin
 if AGraph.GetValue<string>('kind')<>'Business process' then raise EArgumentException.Create('Expected a business-process diagram');
 Text:=TStringBuilder.Create;Indices:=TDictionary<string,Integer>.Create;
 try
 Nodes:=AGraph.GetValue<TJSONArray>('nodes');Edges:=AGraph.GetValue<TJSONArray>('edges');H:=Nodes.Count*190+40;
 for I:=0 to Nodes.Count-1 do Indices.Add(Nodes.Items[I].GetValue<string>('id'),I);
 Text.Append('<section class="card"><h2>'+Enc(AGraph.GetValue<string>('title'))+'</h2><p>'+Enc(AGraph.GetValue<string>('qualification'))+'</p><p>Workflow revision '+Enc(AGraph.GetValue<string>('revision'))+
  ' | '+Enc(AGraph.GetValue<string>('state'))+' | contributor '+Enc(AGraph.GetValue<string>('author'))+' | reviewer '+Enc(AGraph.GetValue<string>('reviewer'))+
  ' | source generation '+Enc(AGraph.GetValue<string>('source_generation'))+'</p>');
 Text.Append('<h3>Linked business processes</h3><ul>');
 for V in AGraph.GetValue<TJSONArray>('process_links') do begin N:=V as TJSONObject;
  Caption:='Unreviewed linked revision';if N.GetValue<Boolean>('reviewed') then Caption:='Reviewed linked revision';
  Text.Append('<li><a href="#knowledge_revision_'+Enc(N.GetValue<string>('revision'))+'">'+Enc(N.GetValue<string>('title'))+'</a> | '+Caption+' '+Enc(N.GetValue<string>('revision'))+' | '+Enc(N.GetValue<string>('state'))+' | reviewer '+Enc(N.GetValue<string>('reviewer'))+'</li>');
 end;
 if AGraph.GetValue<TJSONArray>('process_links').Count=0 then Text.Append('<li>No business-process revision linked in this scope. Use Implementation links to cite a reviewed process.</li>');
 Text.Append('</ul><div style="overflow:auto;max-height:70vh"><svg xmlns="http://www.w3.org/2000/svg" width="1050" height="'+IntToStr(H)+'" role="img" aria-label="Authored end-to-end process diagram"><defs><marker id="processBlue" markerWidth="10" markerHeight="8" refX="9" refY="4" orient="auto"><path d="M0,0 L10,4 L0,8 Z" fill="#146cb4"/></marker><marker id="processOrange" markerWidth="10" markerHeight="8" refX="9" refY="4" orient="auto"><path d="M0,0 L10,4 L0,8 Z" fill="#bc5a00"/></marker></defs>');
 for V in Edges do begin E:=V as TJSONObject;
  if not Indices.TryGetValue(E.GetValue<string>('from'),A) or not Indices.TryGetValue(E.GetValue<string>('to'),B) then Continue;
  Y1:=Y(A);Y2:=Y(B);Colour:='#146cb4';Dash:='';Caption:='processBlue';
  if E.GetValue<string>('kind')='normal' then Route:='M470 '+IntToStr(Y1+120)+' L470 '+IntToStr(Y2)
  else begin Colour:='#bc5a00';Dash:=' stroke-dasharray="7 4"';Caption:='processOrange';
   Route:='M770 '+IntToStr(Y1+70)+' L'+IntToStr(820+(A mod 8)*22)+' '+IntToStr(Y1+70)+' L'+IntToStr(820+(A mod 8)*22)+' '+IntToStr(Y2+30)+' L770 '+IntToStr(Y2+30);
  end;
  Text.Append('<path d="'+Route+'" fill="none" stroke="'+Colour+'" stroke-width="2"'+Dash+' marker-end="url(#'+Caption+')"><title>'+Enc(E.GetValue<string>('kind')+': '+E.GetValue<string>('label'))+'</title></path>');
  if E.GetValue<string>('kind')='normal' then Text.Append('<text x="480" y="'+IntToStr(Y1+145)+'" fill="#146cb4" font-size="12">Normal sequence / handoff</text>');
 end;
 for I:=0 to Nodes.Count-1 do begin N:=Nodes.Items[I] as TJSONObject;Y1:=Y(I);Caption:='';if N.GetValue<string>('kind')='workflow_step' then Caption:=N.GetValue<string>('department')+' | '+N.GetValue<string>('role');Colour:='#146cb4';if N.GetValue<string>('kind')='unresolved' then Colour:='#bc5a00';
  Text.Append('<a href="#s_'+THashSHA2.GetHashString(AGraph.GetValue<string>('workflow_id')+'|'+N.GetValue<string>('id'))+'"><g><title>'+Enc(N.GetValue<string>('detail'))+'</title><rect x="170" y="'+IntToStr(Y1)+'" width="600" height="120" rx="8" fill="#eaf3fc" stroke="'+Colour+'"/><text x="185" y="'+IntToStr(Y1+26)+'" font-size="16" fill="#20364a">'+Enc(Copy(N.GetValue<string>('label'),1,65))+'</text><text x="185" y="'+IntToStr(Y1+49)+'" font-size="14" fill="#20364a">'+Enc(Copy(N.GetValue<string>('label'),66,65))+'</text><text x="185" y="'+IntToStr(Y1+75)+'" font-size="13" fill="#146cb4">'+Enc(Copy(Caption,1,85))+'</text><text x="185" y="'+IntToStr(Y1+100)+'" font-size="12" fill="#52697c">Select for full step details; orange routes are exceptions</text></g></a>');
 end;
 Text.Append('</svg></div><h3>Full steps and routes</h3>');
 for V in Nodes do begin N:=V as TJSONObject;Text.Append('<details id="s_'+THashSHA2.GetHashString(AGraph.GetValue<string>('workflow_id')+'|'+N.GetValue<string>('id'))+'"><summary>'+Enc(N.GetValue<string>('label'))+'</summary><pre>'+Enc(N.GetValue<string>('detail'))+'</pre><ul>');
  for I:=0 to Edges.Count-1 do begin E:=Edges.Items[I] as TJSONObject;if E.GetValue<string>('from')<>N.GetValue<string>('id') then Continue;
   B:=Indices[E.GetValue<string>('to')];Text.Append('<li>'+Enc(E.GetValue<string>('kind')+' to '+Nodes.Items[B].GetValue<string>('label')+': '+E.GetValue<string>('label'))+'</li>');end;
  Text.Append('</ul></details>');
 end;
 Text.Append('</section>');Result:=Text.ToString;
 finally Indices.Free;Text.Free;end;
end;

class function TDPHGraphProjection.Group(AView: TDPHWorkspaceView; AGraph: TJSONObject; const ALevel: string; ALimit: Integer): TJSONObject;
var Parents,Mapping: TDictionary<string,string>; Groups,Aggregates: TDictionary<string,TJSONObject>;
    Omitted: TDictionary<string,Boolean>; Nodes,Edges,Members,Evidence: TJSONArray;
    V: TJSONValue; Row,Symbol,GroupRow,EdgeRow: TJSONObject;
    Key,Parent,GroupKey,Caption,Current,FromKey,ToKey,EdgeKey,Kind: string; Depth,Count: Integer;
begin
  if not MatchText(ALevel,['Units','Types']) or (ALimit<1) or (ALimit>1000) then raise EArgumentException.Create('Invalid graph grouping');
  Result:=TJSONObject.Create; Parents:=TDictionary<string,string>.Create; Mapping:=TDictionary<string,string>.Create;
  Groups:=TDictionary<string,TJSONObject>.Create; Aggregates:=TDictionary<string,TJSONObject>.Create; Omitted:=TDictionary<string,Boolean>.Create;
  try
    try
      Nodes:=TJSONArray.Create; Edges:=TJSONArray.Create; Result.AddPair('nodes',Nodes); Result.AddPair('edges',Edges);
      Result.AddPair('kind',AGraph.GetValue<string>('kind')); Result.AddPair('grouping',ALevel);
      Result.AddPair('generation_id',TJSONNumber.Create(AGraph.GetValue<Int64>('generation_id'))); Result.AddPair('runtime_trace',TJSONBool.Create(False));
      for V in AView.Document.GetValue<TJSONArray>('semantics.relationships') do begin
        Row:=V as TJSONObject; Kind:=Row.GetValue<string>('kind'); Key:=Row.GetValue<string>('to',''); Parent:=Row.GetValue<string>('from');
        if (Kind='owns') and (Key<>'') and not Parents.ContainsKey(Key) then Parents.Add(Key,Parent);
        if (Kind='represents') and (Key<>'') then Parents.AddOrSetValue(Parent,Key);
      end;
      for V in AGraph.GetValue<TJSONArray>('nodes') do begin
        Row:=V as TJSONObject; Key:=Row.GetValue('id').Value;
        Caption:=ChangeFileExt(Row.GetValue<string>('range.source','unmapped'),''); GroupKey:='unit|'+LowerCase(Caption);
        if ALevel='Types' then begin
          Current:=Key;
          for Depth:=0 to 127 do begin
            Symbol:=AView.Symbol(Current); if Symbol=nil then Break;
            if Symbol.GetValue<string>('kind')='type' then begin GroupKey:='type|'+Current; Caption:=Symbol.GetValue<string>('name'); Break; end;
            if not Parents.TryGetValue(Current,Parent) or (Parent=Current) then Break; Current:=Parent;
          end;
        end;
        Mapping.AddOrSetValue(Key,GroupKey);
        if not Groups.TryGetValue(GroupKey,GroupRow) then begin
          if Nodes.Count>=ALimit then begin Omitted.AddOrSetValue(GroupKey,True); Continue; end;
          GroupRow:=TJSONObject.Create; Nodes.AddElement(GroupRow); Groups.Add(GroupKey,GroupRow);
          GroupRow.AddPair('id',GroupKey); GroupRow.AddPair('label',Caption); GroupRow.AddPair('kind','group'); GroupRow.AddPair('grouping',ALevel);
          GroupRow.AddPair('members',TJSONArray.Create); GroupRow.AddPair('internal_relationships',TJSONNumber.Create(0));
          GroupRow.AddPair('internal_evidence',TJSONArray.Create);
          if Row.GetValue('range')<>nil then GroupRow.AddPair('range',Row.GetValue<TJSONObject>('range').Clone as TJSONObject);
        end;
        Members:=GroupRow.GetValue<TJSONArray>('members'); Members.Add(Key);
      end;
      for V in AGraph.GetValue<TJSONArray>('edges') do begin
        Row:=V as TJSONObject;
        if not Mapping.TryGetValue(Row.GetValue('from').Value,FromKey) or not Mapping.TryGetValue(Row.GetValue('to').Value,ToKey) then Continue;
        if not Groups.ContainsKey(FromKey) or not Groups.ContainsKey(ToKey) then Continue;
        if FromKey=ToKey then begin
          GroupRow:=Groups[FromKey]; Count:=GroupRow.GetValue<Integer>('internal_relationships')+1;
          GroupRow.RemovePair('internal_relationships').Free; GroupRow.AddPair('internal_relationships',TJSONNumber.Create(Count));
          Evidence:=GroupRow.GetValue<TJSONArray>('internal_evidence'); if Evidence.Count<16 then Evidence.AddElement(Row.Clone as TJSONObject); Continue;
        end;
        Kind:=Row.GetValue<string>('kind'); EdgeKey:=FromKey+#0+ToKey+#0+Kind;
        if not Aggregates.TryGetValue(EdgeKey,EdgeRow) then begin
          EdgeRow:=TJSONObject.Create; Edges.AddElement(EdgeRow); Aggregates.Add(EdgeKey,EdgeRow);
          EdgeRow.AddPair('from',FromKey); EdgeRow.AddPair('to',ToKey); EdgeRow.AddPair('kind',Kind);
          EdgeRow.AddPair('resolution',Row.GetValue<string>('resolution')); EdgeRow.AddPair('rule','grouped_source_relationships_not_runtime_order');
          EdgeRow.AddPair('relationship_count',TJSONNumber.Create(0)); EdgeRow.AddPair('evidence',TJSONArray.Create);
        end;
        Count:=EdgeRow.GetValue<Integer>('relationship_count')+1; EdgeRow.RemovePair('relationship_count').Free;
        EdgeRow.AddPair('relationship_count',TJSONNumber.Create(Count)); Evidence:=EdgeRow.GetValue<TJSONArray>('evidence');
        if Evidence.Count<16 then Evidence.AddElement(Row.Clone as TJSONObject);
        if (Row.GetValue<string>('resolution')<>'confirmed_static') and (EdgeRow.GetValue<string>('resolution')='confirmed_static') then begin
          EdgeRow.RemovePair('resolution').Free; EdgeRow.AddPair('resolution','possible_dynamic');
        end;
      end;
      for GroupRow in Groups.Values do GroupRow.AddPair('member_count',TJSONNumber.Create(GroupRow.GetValue<TJSONArray>('members').Count));
      Result.AddPair('source_node_count',TJSONNumber.Create(AGraph.GetValue<TJSONArray>('nodes').Count));
      Result.AddPair('omitted_groups',TJSONNumber.Create(Omitted.Count));
      Result.AddPair('source_truncated',TJSONBool.Create(AGraph.GetValue<Boolean>('truncated')));
      Result.AddPair('truncated',TJSONBool.Create(AGraph.GetValue<Boolean>('truncated') or (Omitted.Count>0)));
    except Result.Free; raise; end;
  finally Omitted.Free; Aggregates.Free; Groups.Free; Mapping.Free; Parents.Free; end;
end;
end.
