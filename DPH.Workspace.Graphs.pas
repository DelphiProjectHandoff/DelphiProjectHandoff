unit DPH.Workspace.Graphs;
interface
uses System.JSON, DPH.Workspace.Model;
type
  TDPHGraphProjection = class
  public
    class function Group(AView: TDPHWorkspaceView; AGraph: TJSONObject; const ALevel: string; ALimit: Integer = 120): TJSONObject; static;
  end;
implementation
uses System.SysUtils, System.StrUtils, System.Generics.Collections;

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
