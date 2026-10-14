unit DPH.Publish.Model;
interface
uses System.SysUtils, System.JSON, DPH.Workspace.Model;
const DPHPublishVersion = 'DPH-LEARNING-13';
type
  TDPHDocumentModel = class
  private
    FDocument: TJSONObject;
    FLocalDisplay: Boolean;
  public
    constructor Create(AView: TDPHWorkspaceView; AKnowledge: TJSONArray;
      const ASeeds,AExclusions: TArray<string>; ADetached,AStale: Boolean; AImages: TJSONArray = nil; ALocalDisplay: Boolean = False; const AAudience: string = 'all');
    constructor CreateLocalizedSections(ABase: TDPHDocumentModel; const ALocale: string; ARows: TJSONArray);
    destructor Destroy; override;
    class function Redact(const AText: string): string; static;
    class function Scrub(AValue: TJSONValue): TJSONValue; static;
    class function HTML(const AText: string): string; static;
    property Document: TJSONObject read FDocument;
    property LocalDisplay: Boolean read FLocalDisplay;
  end;
implementation
uses System.Classes, System.StrUtils, System.Hash, System.RegularExpressions, System.Generics.Collections, DPH.Analysis.Explanations, DPH.Workspace.Graphs, DPH.Learning.Discovery;
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
var Pair: TJSONPair; V,Structured: TJSONValue; J: TJSONObject; A: TJSONArray;
begin
  if AValue is TJSONObject then begin J:=TJSONObject.Create; Result:=J; for Pair in TJSONObject(AValue) do
    if MatchText(Pair.JsonString.Value,['password','passwd','secret','api_key','apikey','access_token','authorization','private_key']) then J.AddPair(Pair.JsonString.Value,'[REDACTED]')
    else if Pair.JsonString.Value='structured_json' then begin
      Structured:=TJSONObject.ParseJSONValue(Pair.JsonValue.Value);
      try
        if not (Structured is TJSONObject) then raise EReadError.Create('Authored structured metadata must be a JSON object');
        J.AddPair('structured_record',Scrub(Structured));
      finally Structured.Free; end;
    end else J.AddPair(Pair.JsonString.Value,Scrub(Pair.JsonValue)); end
  else if AValue is TJSONArray then begin A:=TJSONArray.Create; Result:=A; for V in TJSONArray(AValue) do A.AddElement(Scrub(V)); end
  else if AValue is TJSONString then Result:=TJSONString.Create(Redact(AValue.Value)) else Result:=AValue.Clone as TJSONValue;
end;
constructor TDPHDocumentModel.Create(AView: TDPHWorkspaceView; AKnowledge: TJSONArray;
  const ASeeds,AExclusions: TArray<string>; ADetached,AStale: Boolean; AImages: TJSONArray; ALocalDisplay: Boolean; const AAudience: string);
var AllowedFiles,Selected,AllKeys,FlowIDs: TDictionary<string,Boolean>; Queue: TQueue<string>;
    V,W,LinkFileValue: TJSONValue; S,R,J,Range,Section: TJSONObject; Symbols,Relations,Files,Excluded,Evidence,Knowledge,FlowNodes,FlowEdges,Sections,Paragraphs,Links: TJSONArray;
    Path,Prefix,Key,FromKey,ToKey,Kind,EvidenceID,SectionAudience: string; Exclude,IncludeRow: Boolean; Generation: Int64; I,Confirmed,Unresolved,Parent,Depth: Integer;
    Startup,Nodes,Comments,AuthoredSections,Questions: TJSONArray; Node,FileRow,LinkedRow,LinkRange,QuestionMetadata: TJSONObject; Explanations: TDPHExplanationModel; CommentCount,LinkIndex,Omitted: Integer;
    LinkRecords: TList<TJSONObject>; LinkValue,TargetRecord,TargetRevision: TJSONValue; TargetFound: Boolean;
  function CaptureValue(AValue: TJSONValue): TJSONValue;
  begin
    if ALocalDisplay then Result:=AValue.Clone as TJSONValue else Result:=Scrub(AValue);
  end;
begin
  inherited Create; FDocument:=TJSONObject.Create; FLocalDisplay:=ALocalDisplay;
  if not MatchText(AAudience,['all','engineer','user','maintainer','builder','agent']) then raise EArgumentException.Create('Unknown publication audience');
  FDocument.AddPair('audience',AAudience);
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
    J:=TJSONObject.Create; FDocument.AddPair('analyzers',J);
    J.AddPair('syntax',AView.Document.GetValue<string>('syntax.analyzer'));
    J.AddPair('semantics',AView.Document.GetValue<string>('semantics.analyzer'));
    J:=TJSONObject.Create; FDocument.AddPair('analysis_configuration',J);
    J.AddPair('configuration',AView.Document.GetValue<string>('configuration')); J.AddPair('platform',AView.Document.GetValue<string>('platform'));
    J.AddPair('identity',AView.Document.GetValue<string>('configuration_identity','unknown'));
    J.AddPair('code_page',TJSONNumber.Create(AView.Document.GetValue<Integer>('code_page',0)));
    J.AddPair('additional_defines',CaptureValue(AView.Document.GetValue<TJSONArray>('defines')));
    J.AddPair('excluded_external_root_count',TJSONNumber.Create(AView.Document.GetValue<TJSONArray>('external_roots').Count));
    J:=TJSONObject.Create; FDocument.AddPair('required_toolchain',J);
    J.AddPair('language','Delphi'); J.AddPair('exact_release','unknown; consult attributed build_deploy sections');
    J.AddPair('selected_project_build','not_run'); J.AddPair('environment_prerequisites','unknown unless supplied as reviewed knowledge');
    J.AddPair('reviewed_procedures',TJSONArray.Create);
    J:=TJSONObject.Create; FDocument.AddPair('source_revision',J);
    J.AddPair('captured_input_fingerprint',AView.Document.GetValue<string>('semantics.input_fingerprint'));
    J.AddPair('vcs_commit','unrecorded'); J.AddPair('identity_basis','captured file hashes and configuration; no VCS revision inferred');
    Links:=TJSONArray.Create; FDocument.AddPair('task_seeds',Links); for Key in ASeeds do Links.Add(Key);
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
      if Links.Count>0 then begin IncludeRow:=True; for W in Links do begin
        Key:=W.GetValue<string>('canonical_key','');
        if Key<>'' then begin if not Selected.ContainsKey(Key) then IncludeRow:=False; end
        else begin
          Path:=W.GetValue<string>('source_path',''); Exclude:=True;
          for LinkFileValue in Files do if LinkFileValue.GetValue<string>('path')=Path then begin Exclude:=False; Break; end;
          if Exclude then IncludeRow:=False;
        end;
        Path:=W.GetValue<string>('source_path','');
        if Path<>'' then begin Exclude:=True; for LinkFileValue in Files do if LinkFileValue.GetValue<string>('path')=Path then begin Exclude:=False; Break; end;
          if Exclude then IncludeRow:=False; end;
      end; end;
      if IncludeRow then begin
        QuestionMetadata:=TJSONObject.ParseJSONValue(R.GetValue<string>('structured_json','{}')) as TJSONObject;
        try if (QuestionMetadata<>nil) and (QuestionMetadata.GetValue<string>('record_type','')='data_dictionary') then begin
          IncludeRow:=False;Path:=QuestionMetadata.GetValue<string>('fields.source','');
          for LinkFileValue in Files do if (LinkFileValue.GetValue<string>('path')=Path) and
            (LinkFileValue.GetValue<string>('sha256','')=QuestionMetadata.GetValue<string>('fields.source_hash','')) then begin IncludeRow:=True;Break;end;
        end;finally QuestionMetadata.Free;end;
      end;
      if (AAudience<>'all') and not MatchText(R.GetValue<string>('audience','engineer'),['all',AAudience]) then IncludeRow:=False;
      if IncludeRow and (R.GetValue<string>('question_json','')<>'') then begin
        QuestionMetadata:=TJSONObject.ParseJSONValue(R.GetValue<string>('question_json')) as TJSONObject;
        try if QuestionMetadata<>nil then begin Path:=QuestionMetadata.GetValue<string>('range.source','');
          if Path<>'' then begin Exclude:=True; for LinkFileValue in Files do if LinkFileValue.GetValue<string>('path')=Path then begin Exclude:=False; Break; end;
            if Exclude then IncludeRow:=False;
          end;
        end; finally QuestionMetadata.Free; end;
      end;
      if IncludeRow then begin J:=CaptureValue(R) as TJSONObject;
        if R.GetValue<string>('question_json','')<>'' then begin
          QuestionMetadata:=TJSONObject.ParseJSONValue(R.GetValue<string>('question_json')) as TJSONObject;
          try J.RemovePair('question_json').Free; J.AddPair('question_metadata',CaptureValue(QuestionMetadata)); finally QuestionMetadata.Free; end;
        end;
        J.AddPair('publication_generation',TJSONNumber.Create(Generation)); Knowledge.AddElement(J);
      end;
    end;
    Questions:=AView.Questions(AKnowledge);
    try
      Links:=TJSONArray.Create; FDocument.AddPair('author_questions',Links);
      for V in Questions do begin R:=V as TJSONObject; Path:=R.GetValue<string>('range.source'); Key:=R.GetValue<string>('entity_key');
        IncludeRow:=Path=''; if Path<>'' then for W in Files do if W.GetValue<string>('path')=Path then begin IncludeRow:=True; Break; end;
        if (Key<>'') and not Selected.ContainsKey(Key) then IncludeRow:=False;
        Kind:=R.GetValue<string>('answer_kind','unknown'); SectionAudience:='engineer'; if Kind='user_help' then SectionAudience:='user' else if Kind='build_deploy' then SectionAudience:='builder';
        if (AAudience<>'all') and (AAudience<>SectionAudience) then IncludeRow:=False;
        if IncludeRow then Links.AddElement(CaptureValue(R));
      end;
    finally Questions.Free; end;
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
    LinkRecords:=TList<TJSONObject>.Create;
    try
      for V in Knowledge do begin LinkRecords.Add(V as TJSONObject); for W in V.GetValue<TJSONArray>('history') do LinkRecords.Add(W as TJSONObject); end;
      for LinkedRow in LinkRecords do begin
        if LinkedRow.TryGetValue<TJSONArray>('backlinks',AuthoredSections) then
          for LinkIndex:=AuthoredSections.Count-1 downto 0 do begin TargetFound:=False;
            for TargetRecord in Knowledge do if TargetRecord.GetValue<Int64>('id')=AuthoredSections.Items[LinkIndex].GetValue<Int64>('knowledge_id') then begin TargetFound:=True; Break; end;
            if not TargetFound then AuthoredSections.Remove(LinkIndex).Free;
          end;
        if not LinkedRow.TryGetValue<TJSONArray>('rich_links',AuthoredSections) then Continue; Omitted:=0;
        for LinkIndex:=AuthoredSections.Count-1 downto 0 do begin
          LinkValue:=AuthoredSections.Items[LinkIndex]; Kind:=LinkValue.GetValue<string>('target_kind'); TargetFound:=False;
          if MatchText(Kind,['entity','relationship']) then TargetFound:=Selected.ContainsKey(LinkValue.GetValue<string>('canonical_key',''));
          if (Kind='relationship') and (LinkValue.GetValue<string>('to_key','')<>'') and not Selected.ContainsKey(LinkValue.GetValue<string>('to_key')) then TargetFound:=False;
          if Kind='evidence' then begin
            LinkRange:=TJSONObject.ParseJSONValue(LinkValue.GetValue<string>('source_range','{}')) as TJSONObject;
            try if LinkRange<>nil then for W in Files do if W.GetValue<string>('path')=LinkRange.GetValue<string>('source','') then begin TargetFound:=True; Break; end; finally LinkRange.Free; end;
          end;
          if Kind='screenshot' then for W in FDocument.GetValue<TJSONArray>('screenshots') do
            if W.GetValue<string>('artifact_hash','')=LinkValue.GetValue<string>('screenshot_hash','unavailable') then begin TargetFound:=True; Break; end;
          if Kind='section' then for TargetRecord in Knowledge do begin
            for TargetRevision in TargetRecord.GetValue<TJSONArray>('history') do if TargetRevision.GetValue<Int64>('revision')=LinkValue.GetValue<Int64>('target_id') then begin TargetFound:=True; Break; end;
            if TargetFound then Break;
          end;
          if not TargetFound then begin AuthoredSections.Remove(LinkIndex).Free; Inc(Omitted); end;
        end;
        LinkedRow.AddPair('omitted_rich_links',TJSONNumber.Create(Omitted));
      end;
    finally LinkRecords.Free; end;
    for V in Knowledge do begin J:=V as TJSONObject;
     QuestionMetadata:=J.GetValue<TJSONObject>('structured_record',nil);
     if (QuestionMetadata<>nil) and (QuestionMetadata.GetValue<string>('record_type','')='departmental_workflow') then
      J.AddPair('process_diagram',TDPHGraphProjection.Workflow(J,Knowledge,Generation));
    end;

    Links:=TJSONArray.Create; FDocument.AddPair('diagnostics',Links);
    for V in S.GetValue<TJSONArray>('diagnostics') do begin R:=V as TJSONObject;
      Path:=R.GetValue<string>('range.source',''); IncludeRow:=Path='';
      for W in Files do if (W as TJSONObject).GetValue<string>('path')=Path then IncludeRow:=True;
      if IncludeRow then Links.AddElement(CaptureValue(R));
    end;
    Links:=FDocument.GetValue<TJSONObject>('required_toolchain').GetValue<TJSONArray>('reviewed_procedures');
    for V in Knowledge do if (V.GetValue<string>('document_kind')='build_deploy') and (V.GetValue<string>('state')='verified') and (V.GetValue<string>('pending')='0') then begin
      J:=TJSONObject.Create; Links.AddElement(J); J.AddPair('section_id',V.GetValue<string>('section_id')); J.AddPair('revision',V.GetValue<string>('revision'));
      J.AddPair('source_generation',V.GetValue<string>('source_generation')); J.AddPair('reviewer',V.GetValue<string>('reviewer')); J.AddPair('last_reviewed',V.GetValue<string>('reviewed_at'));
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
          if R.GetValue<string>('kind')='expression' then begin IncludeRow:=False;Break;end;
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
      SectionAudience:=IfThen(MatchText(Kind,['user','help']),'user',
        IfThen(Kind='maintenance','maintainer',IfThen(Kind='build_deploy','builder',IfThen(Kind='handoff','agent','engineer'))));
      if (AAudience<>'all') and (Kind<>'overview') and (SectionAudience<>AAudience) then Continue;
      Section:=TJSONObject.Create; Sections.AddElement(Section); Section.AddPair('id',Kind); Section.AddPair('title',Kind.Replace('_',' '));
      Section.AddPair('source_generation',TJSONNumber.Create(Generation)); Section.AddPair('verification_state','source_derived_static_unreviewed');
      Section.AddPair('document_id','document-'+Kind); Section.AddPair('section_id','generated-'+Kind);
      Section.AddPair('last_reviewed','unknown'); Section.AddPair('reviewer',''); Section.AddPair('audience',SectionAudience);
      AuthoredSections:=TJSONArray.Create; Section.AddPair('authored_sections',AuthoredSections);
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
      for V in Knowledge do begin R:=V as TJSONObject;
        if R.GetValue<string>('document_kind',IfThen(R.GetValue<string>('kind')='user_help','user','engineering'))<>Kind then Continue;
        Links.Add(R.GetValue<string>('id')); AuthoredSections.AddElement(R.Clone as TJSONObject);
        Paragraphs.Add(R.GetValue<string>('title')+' [section '+R.GetValue<string>('section_id','knowledge-'+R.GetValue<string>('id'))+
          '; revision '+R.GetValue<string>('revision')+'; audience '+R.GetValue<string>('audience','engineer')+'; state '+R.GetValue<string>('state')+
          '; source generation '+R.GetValue<string>('source_generation')+'; author '+R.GetValue<string>('owner')+
          '; reviewer '+IfThen(R.GetValue<string>('reviewer')='','unassigned',R.GetValue<string>('reviewer'))+
          '; reviewed '+IfThen(R.GetValue<string>('reviewed_at')='','never',R.GetValue<string>('reviewed_at'))+']');
        Paragraphs.Add(R.GetValue<string>('body'));
      end;
    end;
    if AView.Document.GetValue<TJSONArray>('project_guides',nil)<>nil then begin
      FDocument.AddPair('project_guides',CaptureValue(AView.Document.GetValue('project_guides')));
      if AView.Document.GetValue('project_screens')<>nil then
        FDocument.AddPair('project_screens',CaptureValue(AView.Document.GetValue('project_screens')))
      else FDocument.AddPair('project_screens',TJSONArray.Create);
      if AView.Document.GetValue('project_startup_forms')<>nil then
        FDocument.AddPair('project_startup_forms',CaptureValue(AView.Document.GetValue('project_startup_forms')))
      else FDocument.AddPair('project_startup_forms',TJSONArray.Create);
      if AView.Document.GetValue('project_assets')<>nil then
        FDocument.AddPair('project_assets',CaptureValue(AView.Document.GetValue('project_assets')))
      else FDocument.AddPair('project_assets',TJSONArray.Create);
      if AView.Document.GetValue('project_sites')<>nil then
        FDocument.AddPair('project_sites',CaptureValue(AView.Document.GetValue('project_sites')))
      else FDocument.AddPair('project_sites',TJSONArray.Create);
    end else TDPHLearningDiscovery.AddEvidence(FDocument,AView.Document);
    if not ALocalDisplay then
      for V in FDocument.GetValue<TJSONArray>('project_guides') do begin
        R:=V as TJSONObject;
        for W in R.GetValue<TJSONArray>('sections') do begin
          J:=W as TJSONObject;
          Path:=Redact(J.GetValue<string>('text',''));
          J.RemovePair('text').Free;
          J.AddPair('text',Path);
        end;
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
        Section.AddPair('section_version',THashSHA2.GetHashString(Paragraphs.ToJSON+Section.GetValue<TJSONArray>('authored_sections').ToJSON));
      end;
    finally Explanations.Free; end;
  finally Queue.Free; FlowIDs.Free; AllKeys.Free; Selected.Free; AllowedFiles.Free; end;
end;
constructor TDPHDocumentModel.CreateLocalizedSections(ABase: TDPHDocumentModel; const ALocale: string; ARows: TJSONArray);
var Sections,Paragraphs: TJSONArray; V: TJSONValue; Section: TJSONObject;
begin
  inherited Create; FLocalDisplay:=True; FDocument:=ABase.Document.Clone as TJSONObject;
  FDocument.AddPair('localized_locale',ALocale);
  FDocument.RemovePair('sections').Free; Sections:=TJSONArray.Create; FDocument.AddPair('sections',Sections);
  FDocument.RemovePair('knowledge').Free; FDocument.AddPair('knowledge',TJSONArray.Create);
  FDocument.RemovePair('symbols').Free; FDocument.AddPair('symbols',TJSONArray.Create);
  FDocument.RemovePair('known_unknowns').Free;
  FDocument.AddPair('known_unknowns','Localized authored bodies only. Titles, generated guidance and technical indexes remain in their source language. Missing or unreviewed translations retain source prose and explicit fallback states. Translation review approves wording, not the underlying business facts.');
  for V in ARows do begin
    Section:=TJSONObject.Create; Sections.AddElement(Section); Section.AddPair('id',V.GetValue<string>('section_id'));
    Section.AddPair('title','Localized section '+V.GetValue<string>('section_id')); Section.AddPair('section_id',V.GetValue<string>('section_id'));
    Section.AddPair('section_version',V.GetValue<string>('revision')); Section.AddPair('source_generation',V.GetValue<string>('source_generation'));
    Section.AddPair('verification_state',V.GetValue<string>('state')); Section.AddPair('last_reviewed',V.GetValue<string>('reviewed_at','never'));
    Section.AddPair('knowledge_ids',TJSONArray.Create);
    Paragraphs:=TJSONArray.Create; Section.AddPair('paragraphs',Paragraphs);
    Paragraphs.Add('Original title: '+V.GetValue<string>('title')+' | requested locale '+ALocale+' | actual locale '+V.GetValue<string>('actual_locale')+
      ' | source author '+V.GetValue<string>('author')+' | translation reviewer '+V.GetValue<string>('reviewer','unassigned'));
    Paragraphs.Add(V.GetValue<string>('body'));
  end;
end;
destructor TDPHDocumentModel.Destroy;
begin FDocument.Free; inherited; end;
end.
