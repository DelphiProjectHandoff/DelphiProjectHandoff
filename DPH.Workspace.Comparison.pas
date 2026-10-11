unit DPH.Workspace.Comparison;
interface
uses System.SysUtils, System.JSON;
type
  TDPHRevisionComparison = class
  public
    class function Compare(ABefore,AAfter: TJSONObject; const AFilter: string = ''; AOffset: Integer = 0): TJSONObject; static;
    class function EvidenceText(ARow: TJSONObject): string; static;
  end;
implementation
uses System.Classes, System.StrUtils, System.Hash, System.Generics.Collections,
  System.Generics.Defaults;
class function TDPHRevisionComparison.Compare(ABefore,AAfter: TJSONObject; const AFilter: string; AOffset: Integer): TJSONObject;
var OldRows,NewRows: TDictionary<string,TJSONObject>; Fingerprints,Details: TDictionary<string,string>; SeenKeys: TDictionary<string,Boolean>;
    Keys: TList<string>; Row,OldRow,NewRow,Change: TJSONObject;
    Changes: TJSONArray; Key,Kind,BeforeHash,AfterHash: string; Total: Integer;
  procedure AddChange(const AKind,AKey: string; AOld,ANew: TJSONObject);
  var SearchText: string;
  begin
    SearchText:=AKind+' '+AKey;
    if AOld<>nil then SearchText:=SearchText+' '+AOld.ToJSON;
    if ANew<>nil then SearchText:=SearchText+' '+ANew.ToJSON;
    if (AFilter<>'') and not ContainsText(SearchText,AFilter) then Exit;
    Inc(Total); if (Total<=AOffset) or (Changes.Count>=200) then Exit;
    Change:=TJSONObject.Create; Changes.AddElement(Change); Change.AddPair('kind',AKind); Change.AddPair('key',AKey);
    if AOld<>nil then begin
      Row:=AOld.Clone as TJSONObject; Change.AddPair('before',Row);
      if Details.ContainsKey('before:'+AKey) then begin Row.AddPair('captured_structure',Details['before:'+AKey]); Row.AddPair('structure_hash',Fingerprints['before:'+AKey]); end;
    end else Change.AddPair('before',TJSONNull.Create);
    if ANew<>nil then begin
      Row:=ANew.Clone as TJSONObject; Change.AddPair('after',Row);
      if Details.ContainsKey('after:'+AKey) then begin Row.AddPair('captured_structure',Details['after:'+AKey]); Row.AddPair('structure_hash',Fingerprints['after:'+AKey]); end;
    end else Change.AddPair('after',TJSONNull.Create);
  end;
  procedure IndexRows(ADocument: TJSONObject; const APath,AKey: string; AMap: TDictionary<string,TJSONObject>);
  var V: TJSONValue; R: TJSONObject; K: string;
  begin
    AMap.Clear;
    for V in ADocument.GetValue<TJSONArray>(APath) do begin
      R:=V as TJSONObject; K:=R.GetValue<string>(AKey);
      if AMap.ContainsKey(K) then raise EArgumentException.Create('Ambiguous duplicate identity in captured revision: '+K);
      AMap.Add(K,R); if not SeenKeys.ContainsKey(K) then begin SeenKeys.Add(K,True); Keys.Add(K); end;
    end;
  end;
  procedure IndexStructure(ADocument: TJSONObject; const APrefix: string);
  var Builders: TObjectDictionary<string,TStringBuilder>; V: TJSONValue; R: TJSONObject;
      Builder: TStringBuilder; SymbolKey,Owner,TargetOwner: string; NodeID,Ordinal,FromID,ToID: Integer;
      FlowOwners: TDictionary<Integer,string>; FlowOrdinals: TDictionary<Integer,Integer>;
      FlowCounts: TDictionary<string,Integer>;
  begin
    Builders:=TObjectDictionary<string,TStringBuilder>.Create([doOwnsValues]);
    FlowOwners:=TDictionary<Integer,string>.Create; FlowOrdinals:=TDictionary<Integer,Integer>.Create;
    FlowCounts:=TDictionary<string,Integer>.Create;
    try
      for V in ADocument.GetValue<TJSONArray>('semantics.symbols') do begin
        R:=V as TJSONObject; Builder:=TStringBuilder.Create; Builders.Add(R.GetValue<string>('key'),Builder);
        for SymbolKey in ['kind','signature','type','variant','condition','dispatch','has_body'] do
          Builder.Append(SymbolKey).Append('=').Append(R.GetValue(SymbolKey).ToJSON).AppendLine;
      end;
      for V in ADocument.GetValue<TJSONArray>('semantics.flow_nodes') do begin
        R:=V as TJSONObject; Owner:=R.GetValue<string>('routine'); NodeID:=R.GetValue<Integer>('id');
        FlowOwners.Add(NodeID,Owner); if not FlowCounts.TryGetValue(Owner,Ordinal) then Ordinal:=0;
        FlowOrdinals.Add(NodeID,Ordinal); FlowCounts.AddOrSetValue(Owner,Ordinal+1);
        if Builders.TryGetValue(Owner,Builder) then
          Builder.Append(R.GetValue<string>('kind')).Append('|').Append(R.GetValue<string>('expression','')).AppendLine;
      end;
      for V in ADocument.GetValue<TJSONArray>('semantics.flow_edges') do begin
        R:=V as TJSONObject; FromID:=R.GetValue<Integer>('from'); ToID:=R.GetValue<Integer>('to');
        if not FlowOwners.TryGetValue(FromID,Owner) or not FlowOwners.TryGetValue(ToID,TargetOwner) then
          raise EArgumentException.Create('Captured flow edge has a missing node');
        if Builders.TryGetValue(Owner,Builder) then
          Builder.Append('flow ').Append(FlowOrdinals[FromID]).Append(' > ').Append(TargetOwner).Append(':').Append(FlowOrdinals[ToID])
            .Append(' | ').Append(R.GetValue<string>('kind')).Append(' | ').Append(R.GetValue<string>('resolution')).AppendLine;
      end;
      for V in ADocument.GetValue<TJSONArray>('semantics.relationships') do begin
        R:=V as TJSONObject;
        if Builders.TryGetValue(R.GetValue<string>('from'),Builder) then begin
          for SymbolKey in ['to','kind','resolution','rule','label','condition'] do
            Builder.Append(SymbolKey).Append('=').Append(R.GetValue(SymbolKey).ToJSON).AppendLine;
        end;
      end;
      for SymbolKey in Builders.Keys do begin
        Fingerprints.Add(APrefix+SymbolKey,THashSHA2.GetHashString(Builders[SymbolKey].ToString));
        Details.Add(APrefix+SymbolKey,Copy(Builders[SymbolKey].ToString,1,4000));
        if Builders[SymbolKey].Length>4000 then Details[APrefix+SymbolKey]:=Details[APrefix+SymbolKey]+sLineBreak+'[Display truncated after 4000 characters; hash covers full captured structure.]';
      end;
    finally FlowCounts.Free; FlowOrdinals.Free; FlowOwners.Free; Builders.Free; end;
  end;
begin
  if (ABefore=nil) or (AAfter=nil) then raise EArgumentException.Create('Both captured revisions are required');
  if (AOffset<0) or (AOffset>10000000) then raise EArgumentException.Create('Invalid comparison page');
  if not SameText(ABefore.GetValue<string>('entry'),AAfter.GetValue<string>('entry')) then
    raise EArgumentException.Create('Compare captures of the same selected project entry');
  if ABefore.GetValue<string>('selection_hash')<>AAfter.GetValue<string>('selection_hash') then
    raise EArgumentException.Create('Analysis selections differ. Compare the same configuration, platform, defines and dependency roots');
  if (ABefore.GetValue<string>('syntax.analyzer')<>AAfter.GetValue<string>('syntax.analyzer')) or
     (ABefore.GetValue<string>('semantics.analyzer')<>AAfter.GetValue<string>('semantics.analyzer')) then
    raise EArgumentException.Create('Analyzer versions differ; comparisons require equivalent analysis contracts');
  Result:=TJSONObject.Create; Changes:=TJSONArray.Create; Result.AddPair('changes',Changes);
  Result.AddPair('before_generation',TJSONNumber.Create(ABefore.GetValue<Int64>('generation_id')));
  Result.AddPair('after_generation',TJSONNumber.Create(AAfter.GetValue<Int64>('generation_id')));
  Result.AddPair('before_fingerprint',ABefore.GetValue<string>('semantics.input_fingerprint'));
  Result.AddPair('after_fingerprint',AAfter.GetValue<string>('semantics.input_fingerprint'));
  Result.AddPair('definition','Comparison of captured file fingerprints, symbol declarations, routine flow expressions and outgoing relationships. A file change alone does not prove that each routine changed. Historical source bytes are not reconstructed. Added/removed identities can be renames or moves; continuity requires named review. Partial parsing can hide changes. No source or knowledge is modified.');
  OldRows:=TDictionary<string,TJSONObject>.Create; NewRows:=TDictionary<string,TJSONObject>.Create;
  Fingerprints:=TDictionary<string,string>.Create; Details:=TDictionary<string,string>.Create; SeenKeys:=TDictionary<string,Boolean>.Create; Keys:=TList<string>.Create; Total:=0;
  try
    try
      IndexRows(ABefore,'syntax.files','path',OldRows); IndexRows(AAfter,'syntax.files','path',NewRows); Keys.Sort;
      for Key in Keys do begin
        OldRows.TryGetValue(Key,OldRow); NewRows.TryGetValue(Key,NewRow);
        if OldRow=nil then Kind:='file_added' else if NewRow=nil then Kind:='file_removed'
        else if (OldRow.GetValue<string>('sha256')<>NewRow.GetValue<string>('sha256')) or
          (OldRow.GetValue<string>('availability')<>NewRow.GetValue<string>('availability')) then Kind:='file_changed' else Continue;
        AddChange(Kind,Key,OldRow,NewRow);
      end;
      Keys.Clear; SeenKeys.Clear; IndexStructure(ABefore,'before:'); IndexStructure(AAfter,'after:');
      IndexRows(ABefore,'semantics.symbols','key',OldRows); IndexRows(AAfter,'semantics.symbols','key',NewRows); Keys.Sort;
      for Key in Keys do begin
        OldRows.TryGetValue(Key,OldRow); NewRows.TryGetValue(Key,NewRow);
        if OldRow=nil then Kind:='symbol_added' else if NewRow=nil then Kind:='symbol_removed' else begin
          BeforeHash:=Fingerprints['before:'+Key]; AfterHash:=Fingerprints['after:'+Key];
          if BeforeHash<>AfterHash then Kind:='captured_structure_changed'
          else if OldRow.GetValue<string>('source_hash')<>NewRow.GetValue<string>('source_hash') then Kind:='source_file_changed_only'
          else Continue;
        end;
        AddChange(Kind,Key,OldRow,NewRow);
      end;
      Result.AddPair('total_matching',TJSONNumber.Create(Total)); Result.AddPair('offset',TJSONNumber.Create(AOffset));
      Result.AddPair('more',TJSONBool.Create(Total>AOffset+Changes.Count));
    except Result.Free; raise; end;
  finally Keys.Free; SeenKeys.Free; Details.Free; Fingerprints.Free; NewRows.Free; OldRows.Free; end;
end;
class function TDPHRevisionComparison.EvidenceText(ARow: TJSONObject): string;
var Text: TStringBuilder; Field: string; Range: TJSONObject;
begin
  if ARow=nil then Exit('Absent from this captured revision.');
  Text:=TStringBuilder.Create;
  try
    for Field in ['path','name','kind','signature','type','dispatch','condition','sha256','source_hash','availability'] do
      if ARow.GetValue(Field)<>nil then Text.AppendLine(Field+': '+ARow.GetValue(Field).Value);
    if ARow.TryGetValue<TJSONObject>('range',Range) then Text.AppendLine('Source: '+Range.GetValue<string>('source')+':'+IntToStr(Range.GetValue<Integer>('line')));
    if ARow.GetValue('structure_hash')<>nil then begin
      Text.AppendLine('Captured structure SHA256: '+ARow.GetValue<string>('structure_hash'));
      Text.AppendLine('Captured declarations, flow and outgoing relationships:'); Text.AppendLine(ARow.GetValue<string>('captured_structure'));
    end;
    Result:=Text.ToString;
  finally Text.Free; end;
end;
end.
