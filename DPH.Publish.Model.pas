unit DPH.Publish.Model;
interface
uses System.SysUtils, System.JSON, DPH.Workspace.Model;
const DPHPublishVersion = 'DPH-LEARNING-1';
type
  TDPHDocumentModel = class
  private
    FDocument: TJSONObject;
    FLocalDisplay: Boolean;
  public
    constructor Create(AView: TDPHWorkspaceView; AKnowledge: TJSONArray;
      const ASeeds,AExclusions: TArray<string>; ADetached,AStale: Boolean; AImages: TJSONArray = nil; ALocalDisplay: Boolean = False);
    destructor Destroy; override;
    class function Redact(const AText: string): string; static;
    class function Scrub(AValue: TJSONValue): TJSONValue; static;
    class function HTML(const AText: string): string; static;
    property Document: TJSONObject read FDocument;
    property LocalDisplay: Boolean read FLocalDisplay;
  end;
implementation
uses System.StrUtils, System.Hash, System.RegularExpressions, System.Generics.Collections, DPH.Analysis.Explanations;
class function TDPHDocumentModel.HTML(const AText: string): string;
begin Result:=AText.Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;').Replace('"','&quot;').Replace('''','&#39;'); end;
class function TDPHDocumentModel.Redact(const AText: string): string;
begin
  Result:=AText;
  if ContainsText(Result,'-----BEGIN ') and ContainsText(Result,'PRIVATE KEY-----') then Exit('[REDACTED private key]');
  Result:=TRegEx.Replace(Result,'(?i)(authorization\s*[:=]\s*bearer\s+|bearer\s+)[A-Za-z0-9._~+/-]+=*','$1[REDACTED]');
  Result:=TRegEx.Replace(Result,'(?i)(password|passwd|secret|api[_-]?key|access[_-]?token|authorization)["'']?\s*(?::=|[:=])\s*("[^"]*"|''[^'']*''|[^\s;,]+)','$1=[REDACTED]');
  Result:=TRegEx.Replace(Result,'\bAKIA[0-9A-Z]{16}\b','[REDACTED access key]');
  Result:=TRegEx.Replace(Result,'\beyJ[A-Za-z0-9_-]{12,}\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b','[REDACTED token]');
end;
class function TDPHDocumentModel.Scrub(AValue: TJSONValue): TJSONValue;
var Pair: TJSONPair; V: TJSONValue; J: TJSONObject; A: TJSONArray;
begin
  if AValue is TJSONObject then begin J:=TJSONObject.Create; Result:=J; for Pair in TJSONObject(AValue) do
    if MatchText(Pair.JsonString.Value,['password','passwd','secret','api_key','apikey','access_token','authorization','private_key']) then J.AddPair(Pair.JsonString.Value,'[REDACTED]')
    else J.AddPair(Pair.JsonString.Value,Scrub(Pair.JsonValue)); end
  else if AValue is TJSONArray then begin A:=TJSONArray.Create; Result:=A; for V in TJSONArray(AValue) do A.AddElement(Scrub(V)); end
  else if AValue is TJSONString then Result:=TJSONString.Create(Redact(AValue.Value)) else Result:=AValue.Clone as TJSONValue;
end;
constructor TDPHDocumentModel.Create(AView: TDPHWorkspaceView; AKnowledge: TJSONArray;
  const ASeeds,AExclusions: TArray<string>; ADetached,AStale: Boolean; AImages: TJSONArray; ALocalDisplay: Boolean);
var AllowedFiles,Selected,AllKeys,FlowIDs: TDictionary<string,Boolean>; Queue: TQueue<string>;
    V,W: TJSONValue; S,R,J,Range,Section: TJSONObject; Symbols,Relations,Files,Excluded,Evidence,Knowledge,FlowNodes,FlowEdges,Sections,Paragraphs,Links: TJSONArray;
    Path,Prefix,Key,FromKey,ToKey,Kind,EvidenceID: string; Exclude,IncludeRow: Boolean; Generation: Int64; I,Confirmed,Unresolved,Parent,Depth: Integer;
    Startup,Nodes,Comments: TJSONArray; Node,FileRow: TJSONObject; Explanations: TDPHExplanationModel; CommentCount: Integer;
  function CaptureValue(AValue: TJSONValue): TJSONValue;
  begin
    if ALocalDisplay then Result:=AValue.Clone as TJSONValue else Result:=Scrub(AValue);
  end;
begin
  inherited Create; FDocument:=TJSONObject.Create; FLocalDisplay:=ALocalDisplay;
  AllowedFiles:=TDictionary<string,Boolean>.Create; Selected:=TDictionary<string,Boolean>.Create;
  AllKeys:=TDictionary<string,Boolean>.Create; FlowIDs:=TDictionary<string,Boolean>.Create; Queue:=TQueue<string>.Create;
  try
    Generation:=AView.Document.GetValue<Int64>('generation_id');
    FDocument.AddPair('schema_version',TJSONNumber.Create(1)); FDocument.AddPair('template_version',DPHPublishVersion);
    FDocument.AddPair('captured_utc',AView.Document.GetValue<string>('captured_utc','not recorded'));
    FDocument.AddPair('project',AView.Document.GetValue<string>('entry')); FDocument.AddPair('generation_id',TJSONNumber.Create(Generation));
    FDocument.AddPair('configuration',AView.Document.GetValue<string>('configuration')); FDocument.AddPair('platform',AView.Document.GetValue<string>('platform'));
    FDocument.AddPair('input_fingerprint',AView.Document.GetValue<string>('semantics.input_fingerprint'));
    FDocument.AddPair('context_fingerprint',AView.Document.GetValue<string>('semantics.context_fingerprint'));
    FDocument.AddPair('analysis_complete',TJSONBool.Create(AView.Document.GetValue<Boolean>('analysis_complete')));
    FDocument.AddPair('detached',TJSONBool.Create(ADetached)); FDocument.AddPair('stale',TJSONBool.Create(AStale));
    FDocument.AddPair('verification_state','source_derived_static_unreviewed'); FDocument.AddPair('runtime_observed',TJSONBool.Create(False));
    FDocument.AddPair('source_snapshots_included',TJSONBool.Create(False));
    FDocument.AddPair('scope',IfThen(Length(ASeeds)=0,'full','task'));
    Files:=TJSONArray.Create; Excluded:=TJSONArray.Create; Symbols:=TJSONArray.Create; Relations:=TJSONArray.Create;
    Evidence:=TJSONArray.Create; Knowledge:=TJSONArray.Create; FlowNodes:=TJSONArray.Create; FlowEdges:=TJSONArray.Create;
    Sections:=TJSONArray.Create;
    FDocument.AddPair('files',Files); FDocument.AddPair('exclusions',Excluded); FDocument.AddPair('symbols',Symbols); FDocument.AddPair('relationships',Relations);
    FDocument.AddPair('evidence',Evidence); FDocument.AddPair('knowledge',Knowledge); FDocument.AddPair('flow_nodes',FlowNodes); FDocument.AddPair('flow_edges',FlowEdges); FDocument.AddPair('sections',Sections);
    for V in AView.Document.GetValue<TJSONArray>('syntax.files') do begin R:=V as TJSONObject; Path:=R.GetValue<string>('path');
      Exclude:=StartsText('external/',Path) or ContainsText(Path,'.env') or ContainsText(Path,'credential') or ContainsText(Path,'secret') or
        EndsText('.pem',Path) or EndsText('.pfx',Path) or EndsText('.key',Path);
      for Prefix in AExclusions do begin
        if (Prefix='') or ContainsText(Prefix,'..') or ContainsText(Prefix,':') or StartsText('/',Prefix) then raise EArgumentException.Create('Exclusions must be explicit relative file or folder prefixes');
        if SameText(Path,Prefix.Replace('\','/')) or StartsText(ExcludeTrailingPathDelimiter(Prefix.Replace('\','/'))+'/',Path) then Exclude:=True;
      end;
      if Exclude then Excluded.Add(Path) else AllowedFiles.Add(Path,True);
    end;
    S:=AView.Document.GetValue<TJSONObject>('semantics');
    for V in S.GetValue<TJSONArray>('symbols') do begin R:=V as TJSONObject;
      if AllowedFiles.ContainsKey(R.GetValue<string>('range.source')) then AllKeys.Add(R.GetValue<string>('key'),True);
    end;
    for Key in ASeeds do begin if not AllKeys.ContainsKey(Key) then raise EArgumentException.Create('Task seed is missing or excluded'); if not Selected.ContainsKey(Key) then begin Selected.Add(Key,True); Queue.Enqueue(Key); end; end;
    // A task contains the complete incident evidence for its explicitly selected
    // symbols and their direct neighbors, rather than truncating a full export.
    I:=Queue.Count;
    while I>0 do begin Dec(I); Key:=Queue.Dequeue;
      for V in S.GetValue<TJSONArray>('relationships') do begin R:=V as TJSONObject; FromKey:=R.GetValue<string>('from'); ToKey:=R.GetValue<string>('to','');
        if (FromKey<>Key) and (ToKey<>Key) then Continue;
        if AllKeys.ContainsKey(FromKey) then Selected.AddOrSetValue(FromKey,True);
        if AllKeys.ContainsKey(ToKey) then Selected.AddOrSetValue(ToKey,True);
      end;
    end;
    if Selected.Count>5000 then raise EArgumentException.Create('Task scope exceeds 5000 symbols; choose a narrower seed');
    if Length(ASeeds)=0 then for Key in AllKeys.Keys do Selected.AddOrSetValue(Key,True);
    for V in S.GetValue<TJSONArray>('symbols') do begin R:=V as TJSONObject; if not Selected.ContainsKey(R.GetValue<string>('key')) then Continue;
      J:=CaptureValue(R) as TJSONObject; J.AddPair('generation_id',TJSONNumber.Create(Generation));
      FileRow:=AView.SourceFile(R.GetValue<string>('range.source')); Comments:=TJSONArray.Create; J.AddPair('source_comments',Comments); CommentCount:=0;
      if (FileRow<>nil) and (FileRow.GetValue('comments')<>nil) then for W in FileRow.GetValue<TJSONArray>('comments') do begin Node:=W as TJSONObject;
        if ((Node.GetValue<Int64>('range.start')>=R.GetValue<Int64>('range.start')) and (Node.GetValue<Int64>('range.end')<=R.GetValue<Int64>('range.end'))) or
          ((Node.GetValue<Integer>('range.line')<R.GetValue<Integer>('range.line')) and (R.GetValue<Integer>('range.line')-Node.GetValue<Integer>('range.line')<=3)) then begin
          Range:=CaptureValue(Node) as TJSONObject; Range.AddPair('generation_id',TJSONNumber.Create(Generation));
          Comments.AddElement(Range); Inc(CommentCount); if CommentCount>=12 then Break;
        end;
      end;
      if R.GetValue<string>('kind')='component' then begin Links:=AView.Properties(R.GetValue<string>('key')); try J.AddPair('serialized_properties',CaptureValue(Links)); finally Links.Free; end; end;
      Symbols.AddElement(J);
    end;
    Confirmed:=0; Unresolved:=0;
    for V in S.GetValue<TJSONArray>('relationships') do begin R:=V as TJSONObject; FromKey:=R.GetValue<string>('from'); ToKey:=R.GetValue<string>('to','');
      if not Selected.ContainsKey(FromKey) or ((ToKey<>'') and not Selected.ContainsKey(ToKey)) or not AllowedFiles.ContainsKey(R.GetValue<string>('range.source')) then Continue;
      J:=CaptureValue(R) as TJSONObject; EvidenceID:='e_'+THashSHA2.GetHashString(IntToStr(Generation)+R.ToJSON);
      J.AddPair('evidence_id',EvidenceID); J.AddPair('generation_id',TJSONNumber.Create(Generation)); Relations.AddElement(J);
      Range:=TJSONObject.Create; Range.AddPair('id',EvidenceID); Range.AddPair('generation_id',TJSONNumber.Create(Generation));
      Range.AddPair('range',R.GetValue<TJSONObject>('range').Clone as TJSONObject); Range.AddPair('source_hash',R.GetValue<string>('source_hash'));
      Range.AddPair('rule',R.GetValue<string>('rule')); Range.AddPair('resolution',R.GetValue<string>('resolution')); Evidence.AddElement(Range);
      if R.GetValue<string>('resolution')='confirmed_static' then Inc(Confirmed);
      if R.GetValue<string>('resolution')='unresolved' then Inc(Unresolved);
    end;
    for V in S.GetValue<TJSONArray>('flow_nodes') do begin R:=V as TJSONObject;
      if not Selected.ContainsKey(R.GetValue<string>('routine')) or not AllowedFiles.ContainsKey(R.GetValue<string>('range.source')) then Continue;
      J:=CaptureValue(R) as TJSONObject; J.AddPair('generation_id',TJSONNumber.Create(Generation)); FlowNodes.AddElement(J); FlowIDs.Add(R.GetValue('id').Value,True);
    end;
    for V in S.GetValue<TJSONArray>('flow_edges') do begin R:=V as TJSONObject;
      if FlowIDs.ContainsKey(R.GetValue('from').Value) and FlowIDs.ContainsKey(R.GetValue('to').Value) then begin
        J:=CaptureValue(R) as TJSONObject; J.AddPair('generation_id',TJSONNumber.Create(Generation)); FlowEdges.AddElement(J);
      end;
    end;
    for V in AView.Document.GetValue<TJSONArray>('syntax.files') do begin R:=V as TJSONObject; Path:=R.GetValue<string>('path'); if not AllowedFiles.ContainsKey(Path) then Continue;
      IncludeRow:=Length(ASeeds)=0; if not IncludeRow then for W in Symbols do if (W as TJSONObject).GetValue<string>('range.source')=Path then begin IncludeRow:=True; Break; end;
      if IncludeRow then begin J:=TJSONObject.Create; J.AddPair('path',Path); J.AddPair('sha256',R.GetValue<string>('sha256')); J.AddPair('bytes',TJSONNumber.Create(R.GetValue<Int64>('bytes'))); J.AddPair('availability',R.GetValue<string>('availability')); Files.AddElement(J); end;
    end;
    if AKnowledge<>nil then for V in AKnowledge do begin R:=V as TJSONObject; Links:=R.GetValue<TJSONArray>('links'); IncludeRow:=Links.Count=0;
      if Links.Count>0 then begin IncludeRow:=True; for W in Links do if not Selected.ContainsKey((W as TJSONObject).GetValue<string>('canonical_key','')) then IncludeRow:=False; end;
      if IncludeRow then begin J:=CaptureValue(R) as TJSONObject; J.AddPair('source_generation',TJSONNumber.Create(Generation)); Knowledge.AddElement(J); end;
    end;
    J:=TJSONObject.Create; FDocument.AddPair('coverage',J); J.AddPair('included_files',TJSONNumber.Create(Files.Count)); J.AddPair('excluded_files',TJSONNumber.Create(Excluded.Count));
    J.AddPair('included_symbols',TJSONNumber.Create(Symbols.Count)); J.AddPair('relationships_denominator',TJSONNumber.Create(Relations.Count));
    J.AddPair('confirmed_static_numerator',TJSONNumber.Create(Confirmed)); J.AddPair('unresolved_relationships',TJSONNumber.Create(Unresolved));
    J.AddPair('human_records',TJSONNumber.Create(Knowledge.Count)); J.AddPair('human_review','Separate record state and reviewer; not combined with parser coverage');
    FDocument.AddPair('known_unknowns','Runtime behavior unobserved. Missing dependencies and unsupported syntax remain partial. Business intent, operational procedures and historical rationale require attributed review. No analyzed-project build or execution was performed.');
    Links:=TJSONArray.Create; FDocument.AddPair('screenshots',Links);
    if AImages<>nil then for V in AImages do begin R:=V as TJSONObject;
      if R.GetValue<Int64>('generation_id')<>Generation then Continue;
      Key:=R.GetValue<string>('entity_key',''); if (Key<>'') and not Selected.ContainsKey(Key) then Continue;
      J:=CaptureValue(R) as TJSONObject; J.RemovePair('managed_path').Free; Links.AddElement(J);
    end;
    Links:=TJSONArray.Create; FDocument.AddPair('diagnostics',Links);
    for V in S.GetValue<TJSONArray>('diagnostics') do begin R:=V as TJSONObject;
      Path:=R.GetValue<string>('range.source',''); IncludeRow:=Path='';
      for W in Files do if (W as TJSONObject).GetValue<string>('path')=Path then IncludeRow:=True;
      if IncludeRow then Links.AddElement(CaptureValue(R));
    end;
    Startup:=TJSONArray.Create; FDocument.AddPair('startup',Startup);
    for V in AView.Document.GetValue<TJSONArray>('syntax.files') do begin FileRow:=V as TJSONObject;
      if not AllowedFiles.ContainsKey(FileRow.GetValue<string>('path')) or not FileRow.TryGetValue<TJSONArray>('ir.nodes',Nodes) or (Nodes.Count=0) then Continue;
      if not MatchText((Nodes.Items[0] as TJSONObject).GetValue<string>('kind'),['program','library']) then Continue;
      IncludeRow:=False; for W in Files do if (W as TJSONObject).GetValue<string>('path')=FileRow.GetValue<string>('path') then IncludeRow:=True;
      if not IncludeRow then Continue;
      for W in Nodes do begin Node:=W as TJSONObject;
        if Node.GetValue<string>('kind')<>'expression' then Continue;
        Parent:=Node.GetValue<Integer>('parent'); Depth:=0; IncludeRow:=False;
        while (Parent>0) and (Parent<Nodes.Count) and (Depth<128) do begin
          R:=Nodes.Items[Parent] as TJSONObject;
          if StartsText('routine_',R.GetValue<string>('kind')) or StartsText('anonymous_',R.GetValue<string>('kind')) then begin IncludeRow:=False; Break; end;
          if (R.GetValue<string>('kind')='block') and (R.GetValue<Integer>('parent')=0) then IncludeRow:=True;
          Parent:=R.GetValue<Integer>('parent'); Inc(Depth);
        end;
        if not IncludeRow or (Depth>=128) then Continue;
        J:=TJSONObject.Create; Startup.AddElement(J); J.AddPair('text',Redact(Node.GetValue<string>('value')));
        Range:=TJSONObject.Create; Range.AddPair('source',Node.GetValue<string>('source')); Range.AddPair('start',Node.GetValue('start').Clone as TJSONValue);
        Range.AddPair('end',Node.GetValue('end').Clone as TJSONValue); Range.AddPair('line',Node.GetValue('line').Clone as TJSONValue); Range.AddPair('column',Node.GetValue('column').Clone as TJSONValue);
        J.AddPair('range',Range); J.AddPair('source_hash',FileRow.GetValue<string>('sha256')); J.AddPair('generation_id',TJSONNumber.Create(Generation));
        J.AddPair('resolution','confirmed_static'); J.AddPair('rule','parsed_program_body_expression');
      end;
    end;
    for Kind in ['overview','engineering','user','maintenance','build_deploy','troubleshooting','orientation','handoff','help'] do begin
      Section:=TJSONObject.Create; Sections.AddElement(Section); Section.AddPair('id',Kind); Section.AddPair('title',Kind.Replace('_',' '));
      Section.AddPair('source_generation',TJSONNumber.Create(Generation)); Section.AddPair('verification_state','source_derived_static_unreviewed');
      Paragraphs:=TJSONArray.Create; Section.AddPair('paragraphs',Paragraphs);
      Paragraphs.Add('Project '+AView.Document.GetValue<string>('entry')+'; generation '+IntToStr(Generation)+'; '+AView.Document.GetValue<string>('configuration')+' / '+AView.Document.GetValue<string>('platform')+'.');
      if Kind='overview' then Paragraphs.Add(IntToStr(Symbols.Count)+' scoped symbols and '+IntToStr(Relations.Count)+' typed relationships. Consult each source range, hash, derivation rule and certainty before relying on an explanation.');
      if Kind='engineering' then Paragraphs.Add('The symbol, relationship and control-flow indexes are the engineering reference. Static event bindings identify declared handlers; dynamic dispatch and callback ordering remain uncertain where marked.');
      if MatchText(Kind,['user','help']) then Paragraphs.Add('Serialized form controls, captions and event bindings identify the available interface. End-user workflows and permissions are absent unless recorded in attributed user help. Do not invent operating procedures from control names.');
      if Kind='maintenance' then Paragraphs.Add('Use caller/callee and change-impact evidence to locate possible dependents. Impact reachability does not prove runtime impact. Reassess changed source and retain pending human reviews.');
      if Kind='build_deploy' then Paragraphs.Add('Captured configuration and platform identify this analysis variant. Build, deployment, environment prerequisites and production access are unverified unless supplied as reviewed knowledge. Passive analysis did not execute the selected project or its scripts.');
      if Kind='troubleshooting' then Paragraphs.Add('Inspect unresolved references, source availability and analysis diagnostics. A partial result cannot establish runtime failure causes; record observed symptoms and reviewed remedies as attributed knowledge.');
      if Kind='orientation' then Paragraphs.Add('Start with project inventory and startup routines, then follow form events into methods and callbacks. Inspect report origins and dry-run branches where present. Ask the original author about business rationale and missing procedures.');
      if Kind='handoff' then Paragraphs.Add('Validate artifact hashes, generation and input fingerprints before use. Request authorization before modifying or executing the analyzed project. Treat AI explanations as hypotheses requiring evidence and human review.');
      Links:=TJSONArray.Create; Section.AddPair('knowledge_ids',Links);
      for V in Knowledge do begin R:=V as TJSONObject; if (R.GetValue<string>('kind')=Kind) or ((Kind='user') and (R.GetValue<string>('kind')='user_help')) or
        ((Kind='engineering') and MatchText(R.GetValue<string>('kind'),['engineering_rule','business_rule','decision','note'])) then Links.Add(R.GetValue<string>('id')); end;
    end;
    Explanations:=TDPHExplanationModel.Create(FDocument);
    try
      for V in Sections do begin Section:=V as TJSONObject; Kind:=Section.GetValue<string>('id'); Paragraphs:=Section.GetValue<TJSONArray>('paragraphs');
        if Kind='overview' then Paragraphs.Add(Explanations.TopicText(0));
        if Kind='orientation' then begin Paragraphs.Add(Explanations.TopicText(1)); Paragraphs.Add(Explanations.TopicText(3)); Paragraphs.Add(Explanations.TopicText(10)); end;
        if MatchText(Kind,['user','help']) then Paragraphs.Add(Explanations.TopicText(2));
        if Kind='engineering' then begin Paragraphs.Add(Explanations.TopicText(4)); Paragraphs.Add(Explanations.TopicText(5)); Paragraphs.Add(Explanations.TopicText(6)); end;
        if Kind='maintenance' then Paragraphs.Add(Explanations.TopicText(7));
        if Kind='troubleshooting' then Paragraphs.Add(Explanations.TopicText(8));
        if Kind='handoff' then Paragraphs.Add(Explanations.TopicText(9));
      end;
    finally Explanations.Free; end;
  finally Queue.Free; FlowIDs.Free; AllKeys.Free; Selected.Free; AllowedFiles.Free; end;
end;
destructor TDPHDocumentModel.Destroy;
begin FDocument.Free; inherited; end;
end.
