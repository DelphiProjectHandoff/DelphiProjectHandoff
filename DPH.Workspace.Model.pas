unit DPH.Workspace.Model;

interface
uses System.SysUtils, System.JSON, System.Generics.Collections,
  DPH.Project.Analysis, DPH.Analysis.Model;
type
  TDPHWorkspaceView = class
  private
    FDocument: TJSONObject;
    FSymbols: TDictionary<string,TJSONObject>;
  public
    constructor Create(ADocument: TJSONObject);
    destructor Destroy; override;
    class function Capture(AScan: TDPHScan; AGraph: TDPHSemanticGraph; AGeneration: Int64;
      const AEntry,AConfig,APlatform: string; const ADefines,AExternalRoots: TArray<string>): TJSONObject; static;
    function Symbol(const AKey: string): TJSONObject;
    function Neighbors(const AKey,ADirection: string): TJSONArray;
    function Search(const AQuery,AKind,AScope: string; AOffset: Integer = 0; ALimit: Integer = 250): TJSONArray;
    function Hierarchy(const AExpanded: TArray<string>; AOffset: Integer = 0; ALimit: Integer = 250): TJSONArray;
    function SourceFile(const APath: string): TJSONObject;
    function Properties(const AKey: string): TJSONArray;
    function Details(const AKey: string): TJSONArray;
    function Graph(const AKind,AKey: string; ALimit: Integer = 120): TJSONObject;
    function FlagsText: string;
    function Coverage: TJSONObject;
    class function SelectionHash(const AConfig,APlatform: string; const ADefines,AExternalRoots: TArray<string>; ACodePage: Integer = 0): string; static;
    class function IsHandoffProject(ADocument: TJSONObject): Boolean; static;
    property Document: TJSONObject read FDocument;
  end;
implementation
uses System.StrUtils, System.IOUtils, System.Hash, System.DateUtils, System.Generics.Defaults, DPH.Project.Inventory;

class function TDPHWorkspaceView.IsHandoffProject(ADocument: TJSONObject): Boolean;
var Files,Nodes: TJSONArray; FileValue,NodeValue: TJSONValue; Row,IR,Node: TJSONObject;
begin
  Result:=False;
  if (ADocument=nil) or not ADocument.TryGetValue<TJSONArray>('syntax.files',Files) then Exit;
  for FileValue in Files do
  begin
    Row:=FileValue as TJSONObject;
    if not Row.TryGetValue<TJSONObject>('ir',IR) or not IR.TryGetValue<TJSONArray>('nodes',Nodes) then Continue;
    for NodeValue in Nodes do
    begin
      Node:=NodeValue as TJSONObject;
      if (SameText(Node.GetValue<string>('kind',''),'project_property') and
        SameText(Node.GetValue<string>('name',''),'ProjectGuid') and
        SameText(Trim(Node.GetValue<string>('value','')),DPHHandoffProjectGUID)) or
        (SameText(Node.GetValue<string>('kind',''),'program') and
        SameText(Node.GetValue<string>('name',''),DPHHandoffProgramName)) then Exit(True);
    end;
  end;
end;

class function TDPHWorkspaceView.SelectionHash(const AConfig,APlatform: string; const ADefines,AExternalRoots: TArray<string>; ACodePage: Integer): string;
var Selection: string;
begin
  Selection:=AConfig+#0+APlatform+#0+String.Join(#0,ADefines)+#1+String.Join(#0,AExternalRoots);
  if ACodePage<>0 then Selection:=Selection+#0+'CP'+IntToStr(ACodePage);
  Result:=THashSHA2.GetHashString(Selection);
end;

class function TDPHWorkspaceView.Capture(AScan: TDPHScan; AGraph: TDPHSemanticGraph; AGeneration: Int64;
  const AEntry,AConfig,APlatform: string; const ADefines,AExternalRoots: TArray<string>): TJSONObject;
var A: TJSONArray; Value: string;
begin
  Result:=TJSONObject.Create; Result.AddPair('workspace_schema',TJSONNumber.Create(1));
  Result.AddPair('captured_utc',DateToISO8601(TTimeZone.Local.ToUniversalTime(Now),True));
  Result.AddPair('generation_id',TJSONNumber.Create(AGeneration)); Result.AddPair('entry',ExtractFileName(AEntry));
  Result.AddPair('root',AScan.Inventory.Root); Result.AddPair('configuration',AConfig); Result.AddPair('platform',APlatform);
  Result.AddPair('configuration_identity',AScan.Inventory.ConfigurationIdentity);
  Result.AddPair('selection_hash',SelectionHash(AConfig,APlatform,ADefines,AExternalRoots,AScan.Inventory.CodePage));
  Result.AddPair('code_page',TJSONNumber.Create(AScan.Inventory.CodePage));
  A:=TJSONArray.Create; Result.AddPair('defines',A); for Value in ADefines do A.Add(Value);
  A:=TJSONArray.Create; Result.AddPair('external_roots',A); for Value in AExternalRoots do A.Add(Value);
  A:=TJSONArray.Create; Result.AddPair('configurations',A); for Value in AScan.Inventory.Configurations do A.Add(Value);
  A:=TJSONArray.Create; Result.AddPair('platforms',A); for Value in AScan.Inventory.Platforms do A.Add(Value);
  Result.AddPair('syntax',AScan.AsJSON(True)); Result.AddPair('semantics',AGraph.AsJSON);
  Result.AddPair('analysis_complete',TJSONBool.Create(AScan.Complete and AGraph.Complete));
  Result.AddPair('runtime_observed',TJSONBool.Create(False));
end;
constructor TDPHWorkspaceView.Create(ADocument: TJSONObject);
var V: TJSONValue; S: TJSONObject; Semantic: TJSONObject;
begin
  inherited Create; FDocument:=ADocument;
  if (ADocument=nil) or (ADocument.GetValue<Integer>('workspace_schema',0)<>1) then raise EArgumentException.Create('Unsupported workspace document');
  FSymbols:=TDictionary<string,TJSONObject>.Create;
  Semantic:=ADocument.GetValue<TJSONObject>('semantics');
  for V in Semantic.GetValue<TJSONArray>('symbols') do
  begin S:=V as TJSONObject; FSymbols.Add(S.GetValue<string>('key'),S); end;
end;
destructor TDPHWorkspaceView.Destroy;
begin FSymbols.Free; FDocument.Free; inherited; end;
function TDPHWorkspaceView.Symbol(const AKey: string): TJSONObject;
begin if not FSymbols.TryGetValue(AKey,Result) then Result:=nil; end;
function TDPHWorkspaceView.Search(const AQuery,AKind,AScope: string; AOffset,ALimit: Integer): TJSONArray;
var V: TJSONValue; S: TJSONObject; Count: Integer; Name,Kind: string;
begin
  if (AOffset<0) or (ALimit<1) or (ALimit>1000) then raise EArgumentException.Create('Invalid Explorer page');
  Result:=TJSONArray.Create; Count:=0;
  for V in FDocument.GetValue<TJSONObject>('semantics').GetValue<TJSONArray>('symbols') do
  begin
    S:=V as TJSONObject; Name:=S.GetValue<string>('name'); Kind:=S.GetValue<string>('kind');
    if (AKind<>'') and (Kind<>AKind) then Continue;
    if (AScope<>'') and not StartsText(AScope+'.',Name) then Continue;
    if (AQuery<>'') and not ContainsText(Name+' '+S.GetValue<string>('signature')+' '+Kind,AQuery) then Continue;
    if Count>=AOffset then Result.AddElement(S.Clone as TJSONObject);
    Inc(Count); if Result.Count>=ALimit then Break;
  end;
end;
function TDPHWorkspaceView.Hierarchy(const AExpanded: TArray<string>; AOffset,ALimit: Integer): TJSONArray;
var Children: TObjectDictionary<string,TList<string>>; Parents: TDictionary<string,string>;
    Expanded,Seen: TDictionary<string,Boolean>; Roots: TList<string>; Items: TList<string>;
    V: TJSONValue; R: TJSONObject; Key,Owner,Child: string; VisibleCount: Integer;
  procedure Visit(const AKey: string; Depth: Integer);
  var Row,CopyRow: TJSONObject; Branch: TList<string>; ChildKey: string; HasChildren,IsExpanded: Boolean;
  begin
    if (Depth>128) or (Result.Count>=ALimit) or Seen.ContainsKey(AKey) then Exit;
    Row:=Symbol(AKey); if Row=nil then Exit; Seen.Add(AKey,True);
    HasChildren:=Children.TryGetValue(AKey,Branch); IsExpanded:=Expanded.ContainsKey(AKey);
    if VisibleCount>=AOffset then begin
      CopyRow:=Row.Clone as TJSONObject; Result.AddElement(CopyRow);
      CopyRow.AddPair('depth',TJSONNumber.Create(Depth)); CopyRow.AddPair('has_children',TJSONBool.Create(HasChildren));
      CopyRow.AddPair('expanded',TJSONBool.Create(IsExpanded));
    end;
    Inc(VisibleCount);
    if HasChildren and IsExpanded then for ChildKey in Branch do Visit(ChildKey,Depth+1);
  end;
begin
  if (AOffset<0) or (ALimit<1) or (ALimit>1000) then raise EArgumentException.Create('Invalid hierarchy page');
  Result:=TJSONArray.Create;
  Children:=TObjectDictionary<string,TList<string>>.Create([doOwnsValues]); Parents:=TDictionary<string,string>.Create;
  Expanded:=TDictionary<string,Boolean>.Create; Seen:=TDictionary<string,Boolean>.Create; Roots:=TList<string>.Create;
  try
    try
    for Key in AExpanded do Expanded.AddOrSetValue(Key,True);
    for V in FDocument.GetValue<TJSONArray>('semantics.relationships') do begin
      R:=V as TJSONObject; if R.GetValue<string>('kind')<>'owns' then Continue;
      Owner:=R.GetValue<string>('from'); Child:=R.GetValue<string>('to','');
      if (Owner=Child) or (Symbol(Owner)=nil) or (Symbol(Child)=nil) or Parents.ContainsKey(Child) then Continue;
      Parents.Add(Child,Owner);
      if not Children.TryGetValue(Owner,Items) then begin Items:=TList<string>.Create; Children.Add(Owner,Items); end;
      Items.Add(Child);
    end;
    for V in FDocument.GetValue<TJSONArray>('semantics.symbols') do begin
      Key:=(V as TJSONObject).GetValue<string>('key'); if not Parents.ContainsKey(Key) then Roots.Add(Key);
    end;
    VisibleCount:=0; for Key in Roots do Visit(Key,0);
    except Result.Free; raise; end;
  finally Roots.Free; Seen.Free; Expanded.Free; Parents.Free; Children.Free; end;
end;

function TDPHWorkspaceView.Neighbors(const AKey,ADirection: string): TJSONArray;
var V: TJSONValue; R: TJSONObject; Field: string;
begin
  Result:=TJSONArray.Create; Field:='from'; if ADirection='reverse' then Field:='to';
  for V in FDocument.GetValue<TJSONObject>('semantics').GetValue<TJSONArray>('relationships') do
  begin R:=V as TJSONObject; if R.GetValue<string>(Field,'')=AKey then Result.AddElement(R.Clone as TJSONObject); end;
end;
function TDPHWorkspaceView.SourceFile(const APath: string): TJSONObject;
var V: TJSONValue;
begin
  Result:=nil; for V in FDocument.GetValue<TJSONObject>('syntax').GetValue<TJSONArray>('files') do
    if SameText((V as TJSONObject).GetValue<string>('path'),APath) then Exit(V as TJSONObject);
end;
function TDPHWorkspaceView.Properties(const AKey: string): TJSONArray;
var S,FileRow,N,Range: TJSONObject; V: TJSONValue; Nodes: TJSONArray; NodeID,I: Integer;
begin
  Result:=TJSONArray.Create; S:=Symbol(AKey); if S=nil then Exit;
  Range:=S.GetValue<TJSONObject>('range'); FileRow:=SourceFile(Range.GetValue<string>('source')); if FileRow=nil then Exit;
  Nodes:=FileRow.GetValue<TJSONObject>('ir').GetValue<TJSONArray>('nodes'); NodeID:=-1;
  for I:=0 to Nodes.Count-1 do
  begin N:=Nodes.Items[I] as TJSONObject;
    if (N.GetValue<Int64>('start')=Range.GetValue<Int64>('start')) and MatchText(N.GetValue<string>('kind'),['object','inherited','inline']) then begin NodeID:=I; Break; end;
  end;
  if NodeID<0 then Exit;
  for V in Nodes do begin N:=V as TJSONObject; if (N.GetValue<Integer>('parent')=NodeID) and (N.GetValue<string>('kind')='property') then Result.AddElement(N.Clone as TJSONObject); end;
end;
function TDPHWorkspaceView.Details(const AKey: string): TJSONArray;
var V: TJSONValue; Row,CopyRow,FileRow: TJSONObject; PropertiesRows: TJSONArray; FlowRows: TList<TJSONObject>;
begin
  Result:=TJSONArray.Create; FlowRows:=TList<TJSONObject>.Create;
  try
    try
    for V in FDocument.GetValue<TJSONArray>('semantics.flow_nodes') do begin
      Row:=V as TJSONObject; if Row.GetValue<string>('routine')<>AKey then Continue;
      FlowRows.Add(Row);
    end;
    FlowRows.Sort(TComparer<TJSONObject>.Construct(
      function(const L,R: TJSONObject): Integer
      var LeftBoundary,RightBoundary: Boolean;
      begin
        LeftBoundary:=MatchText(L.GetValue<string>('kind'),['entry','normal_exit','exception_exit']);
        RightBoundary:=MatchText(R.GetValue<string>('kind'),['entry','normal_exit','exception_exit']);
        if LeftBoundary<>RightBoundary then begin if LeftBoundary then Exit(1) else Exit(-1); end;
        Result:=CompareStr(L.GetValue<string>('range.source'),R.GetValue<string>('range.source'));
        if Result=0 then begin
          if L.GetValue<Int64>('range.start')<R.GetValue<Int64>('range.start') then Result:=-1
          else if L.GetValue<Int64>('range.start')>R.GetValue<Int64>('range.start') then Result:=1;
        end;
      end));
    for Row in FlowRows do begin
      CopyRow:=Row.Clone as TJSONObject; Result.AddElement(CopyRow);
      if MatchText(Row.GetValue<string>('kind'),['entry','normal_exit','exception_exit']) then CopyRow.AddPair('detail_kind','flow boundary')
      else CopyRow.AddPair('detail_kind','statement'); CopyRow.AddPair('title',Row.GetValue<string>('kind'));
      CopyRow.AddPair('object_key',AKey);
      CopyRow.AddPair('text',Row.GetValue<string>('expression')); CopyRow.AddPair('resolution','inferred');
      CopyRow.AddPair('rule','captured_control_flow_not_runtime_trace'); if Result.Count>=1000 then Exit;
    end;
    PropertiesRows:=Properties(AKey);
    try for V in PropertiesRows do begin
      Row:=V as TJSONObject; CopyRow:=TJSONObject.Create; Result.AddElement(CopyRow);
      CopyRow.AddPair('detail_kind','property'); CopyRow.AddPair('title',Row.GetValue<string>('name'));
      CopyRow.AddPair('object_key',AKey);
      CopyRow.AddPair('text',Row.GetValue<string>('value')); CopyRow.AddPair('range',Row.Clone as TJSONObject);
      CopyRow.AddPair('resolution','confirmed_static'); CopyRow.AddPair('rule','serialized_override_not_framework_default');
      FileRow:=SourceFile(Row.GetValue<string>('source')); if FileRow<>nil then CopyRow.AddPair('source_hash',FileRow.GetValue<string>('sha256'));
      if Result.Count>=1000 then Exit;
    end; finally PropertiesRows.Free; end;
    for V in FDocument.GetValue<TJSONArray>('semantics.relationships') do begin
      Row:=V as TJSONObject; if Row.GetValue<string>('from')<>AKey then Continue;
      CopyRow:=Row.Clone as TJSONObject; Result.AddElement(CopyRow);
      CopyRow.AddPair('detail_kind','relationship'); CopyRow.AddPair('title',Row.GetValue<string>('kind'));
      CopyRow.AddPair('object_key',Row.GetValue<string>('to',AKey));
      CopyRow.AddPair('text',Row.GetValue<string>('label')); if Result.Count>=1000 then Exit;
    end;
    except Result.Free; raise; end;
  finally FlowRows.Free; end;
end;

function TDPHWorkspaceView.Graph(const AKind,AKey: string; ALimit: Integer): TJSONObject;
var Nodes,Edges,AllNodes,AllEdges: TJSONArray; V: TJSONValue; R,S,N: TJSONObject;
    Seen,EdgeKeys: TDictionary<string,Boolean>; Queue: TQueue<string>; Key,FromKey,ToKey,Kind,EdgeKey: string;
    I: Integer; Truncated: Boolean;
  procedure AddSymbolNode(const K: string);
  var Row,Sym: TJSONObject;
  begin
    if (K='') or Seen.ContainsKey(K) then Exit;
    if Seen.Count>=ALimit then begin Truncated:=True; Exit; end;
    Seen.Add(K,True); Sym:=Symbol(K); Row:=TJSONObject.Create; Row.AddPair('id',K);
    if Sym<>nil then begin Row.AddPair('label',Sym.GetValue<string>('name')); Row.AddPair('kind',Sym.GetValue<string>('kind')); Row.AddPair('type',Sym.GetValue<string>('type')); Row.AddPair('range',Sym.GetValue<TJSONObject>('range').Clone as TJSONObject); end
    else Row.AddPair('label',K); Nodes.AddElement(Row); Queue.Enqueue(K);
  end;
begin
  if (ALimit<1) or (ALimit>1000) then raise EArgumentException.Create('Invalid graph limit');
  Result:=TJSONObject.Create; Nodes:=TJSONArray.Create; Edges:=TJSONArray.Create;
  Result.AddPair('kind',AKind); Result.AddPair('nodes',Nodes); Result.AddPair('edges',Edges);
  Result.AddPair('generation_id',TJSONNumber.Create(FDocument.GetValue<Int64>('generation_id')));
  Result.AddPair('runtime_trace',TJSONBool.Create(False)); Truncated:=False;
  Seen:=TDictionary<string,Boolean>.Create; EdgeKeys:=TDictionary<string,Boolean>.Create; Queue:=TQueue<string>.Create;
  try
    S:=FDocument.GetValue<TJSONObject>('semantics');
    if AKind='Procedure CFG' then
    begin
      AllNodes:=S.GetValue<TJSONArray>('flow_nodes'); AllEdges:=S.GetValue<TJSONArray>('flow_edges');
      for V in AllNodes do
      begin N:=V as TJSONObject; if N.GetValue<string>('routine')<>AKey then Continue;
        if Nodes.Count>=ALimit then begin Truncated:=True; Break; end;
        R:=N.Clone as TJSONObject; Key:=N.GetValue<Integer>('id').ToString; R.AddPair('label',N.GetValue<string>('kind')+' '+N.GetValue<string>('expression'));
        Nodes.AddElement(R); Seen.Add(Key,True);
      end;
      for V in AllEdges do begin R:=V as TJSONObject;
        if Seen.ContainsKey(R.GetValue<Integer>('from').ToString) and Seen.ContainsKey(R.GetValue<Integer>('to').ToString) then Edges.AddElement(R.Clone as TJSONObject);
      end;
    end
    else
    begin
      AddSymbolNode(AKey);
      if (AKey='') and (AKind='Execution') then
        for V in S.GetValue<TJSONArray>('symbols') do begin N:=V as TJSONObject;
          if (N.GetValue<string>('kind')='unit') and MatchText(N.GetValue<string>('type'),['program','library','package']) then AddSymbolNode(N.GetValue<string>('key'));
        end;
      if (AKey='') and (AKind='Form navigation') then
        for V in S.GetValue<TJSONArray>('symbols') do begin N:=V as TJSONObject;
          if (N.GetValue<string>('kind')='component') and MatchText(ExtractFileExt(N.GetValue<string>('range.source')),['.fmx','.dfm']) then begin
            R:=SourceFile(N.GetValue<string>('range.source'));
            if (R<>nil) and (R.GetValue<TJSONArray>('ir.nodes').Count>0) and
              (R.GetValue<TJSONArray>('ir.nodes').Items[0].GetValue<Int64>('start')=N.GetValue<Int64>('range.start')) then AddSymbolNode(N.GetValue<string>('key'));
          end;
        end;
      if (AKey='') and (AKind='Data flow') then
        for V in S.GetValue<TJSONArray>('symbols') do begin N:=V as TJSONObject;
          if MatchText(N.GetValue<string>('kind'),['parameter','local','field','property','variable','resource','definition','sql_statement','sql_table','sql_column','output_artifact']) then AddSymbolNode(N.GetValue<string>('key'));
        end;
      if (AKey='') and (Nodes.Count=0) then for V in S.GetValue<TJSONArray>('symbols') do
      begin N:=V as TJSONObject; if N.GetValue<Boolean>('has_body') then begin AddSymbolNode(N.GetValue<string>('key')); Break; end; end;
      while Queue.Count>0 do
      begin
        Key:=Queue.Dequeue;
        for V in S.GetValue<TJSONArray>('relationships') do
        begin
          R:=V as TJSONObject; Kind:=R.GetValue<string>('kind'); FromKey:=R.GetValue<string>('from'); ToKey:=R.GetValue<string>('to','');
          if (AKind='Change impact') then begin if ToKey<>Key then Continue; end
          else if (AKind='Caller / callee') then begin if (FromKey<>Key) and (ToKey<>Key) then Continue; end
          else if (AKind='Data flow') then begin if (FromKey<>Key) and (ToKey<>Key) then Continue; end
          else if (AKind='Form navigation') and MatchText(Kind,['represents','form_instance','component_field','binds']) then begin if (FromKey<>Key) and (ToKey<>Key) then Continue; end
          else if FromKey<>Key then Continue;
          if (AKind='Execution') and not MatchText(Kind,['calls','schedules','passes_callback','prepares_callback','starts','dispatches','waits_for','requests_cancellation','signals','waits_for_signal','binds','enters','initializes','finalizes','creates']) then Continue;
          if (AKind='Form navigation') and not MatchText(Kind,['owns','binds','calls','schedules','creates','assigned_to','mutates_property','assigns_callback','uses_type','represents','form_instance','component_field','shows_form','shows_modal_form','hides_form','closes_form']) then Continue;
          if (AKind='Data flow') and not MatchText(Kind,['reads','writes','renders','captures','assigned_to','derives_from','configures','static_sql','dynamic_sql','mutates_property']) then Continue;
          AddSymbolNode(FromKey); AddSymbolNode(ToKey);
          if Seen.ContainsKey(FromKey) and Seen.ContainsKey(ToKey) then begin
            EdgeKey:=FromKey+#0+ToKey+#0+Kind+#0+R.GetValue<string>('range.source')+#0+R.GetValue<Int64>('range.start').ToString+#0+R.GetValue<string>('rule')+#0+R.GetValue<string>('condition');
            if not EdgeKeys.ContainsKey(EdgeKey) then begin EdgeKeys.Add(EdgeKey,True); Edges.AddElement(R.Clone as TJSONObject); end;
          end;
          if Edges.Count>=ALimit*8 then begin Truncated:=True; Queue.Clear; Break; end;
        end;
      end;
    end;
    Result.AddPair('truncated',TJSONBool.Create(Truncated));
  finally Queue.Free; EdgeKeys.Free; Seen.Free; end;
end;
function TDPHWorkspaceView.Coverage: TJSONObject;
var Files,Relations,Diagnostics,Metrics,Nodes: TJSONArray; V,W,E: TJSONValue; R,IR,N,Edge: TJSONObject;
  Parsed,Available,Complete,Confirmed,Unresolved,Events,BoundEvents,Evidence: Integer; Recognized,Tokens: Int64; Matched: Boolean;
  procedure Metric(const Name,Definition: string; Numerator,Denominator: Int64);
  var Row: TJSONObject;
  begin Row:=TJSONObject.Create; Metrics.AddElement(Row); Row.AddPair('name',Name);
    Row.AddPair('definition',Definition); Row.AddPair('numerator',TJSONNumber.Create(Numerator));
    Row.AddPair('denominator',TJSONNumber.Create(Denominator)); end;
begin
  Result:=TJSONObject.Create; Metrics:=TJSONArray.Create; Result.AddPair('metrics',Metrics);
  Diagnostics:=TJSONArray.Create; Result.AddPair('diagnostics',Diagnostics);
  Files:=FDocument.GetValue<TJSONArray>('syntax.files'); Relations:=FDocument.GetValue<TJSONArray>('semantics.relationships');
  Parsed:=0; Available:=0; Complete:=0; Recognized:=0; Tokens:=0; Confirmed:=0; Unresolved:=0;
  Events:=0; BoundEvents:=0; Evidence:=0;
  for V in Files do begin R:=V as TJSONObject;
    if R.GetValue<string>('sha256','')<>'' then Inc(Available);
    if R.TryGetValue<TJSONObject>('ir',IR) then begin Inc(Parsed);
      if IR.GetValue<Boolean>('complete',False) then Inc(Complete);
      Inc(Recognized,IR.GetValue<Int64>('recognized_tokens',0)); Inc(Tokens,IR.GetValue<Int64>('significant_tokens',0));
      if MatchText(ExtractFileExt(R.GetValue<string>('path')),['.fmx','.dfm']) and IR.TryGetValue<TJSONArray>('nodes',Nodes) then
        for W in Nodes do begin N:=W as TJSONObject;
          if (N.GetValue<string>('kind')<>'property') or not StartsText('On',N.GetValue<string>('name')) or (Trim(N.GetValue<string>('value'))='') then Continue;
          Inc(Events); Matched:=False;
          for E in Relations do begin Edge:=E as TJSONObject;
            if (Edge.GetValue<string>('kind')='binds') and (Edge.GetValue<string>('resolution')='confirmed_static') and
              SameText(Edge.GetValue<string>('range.source'),R.GetValue<string>('path')) and
              (Edge.GetValue<Int64>('range.start')=N.GetValue<Int64>('start')) then begin Matched:=True; Break; end;
          end;
          if Matched then Inc(BoundEvents);
        end;
    end;
  end;
  for V in Relations do begin R:=V as TJSONObject;
    if R.GetValue<string>('resolution')='confirmed_static' then Inc(Confirmed);
    if R.GetValue<string>('resolution')='unresolved' then Inc(Unresolved);
    if (R.GetValue<string>('range.source','')<>'') and (R.GetValue<string>('rule','')<>'') then Inc(Evidence);
  end;
  Metric('Fingerprinted inventory files','Files with captured SHA256 / files in selected inventory. Not all files on disk.',Available,Files.Count);
  Metric('Files with parsed IR','Files with an intermediate representation / selected inventory files. Opaque resources may have no IR.',Parsed,Files.Count);
  Metric('Complete parsed files','IR complete flag / files with IR. This does not measure semantic correctness.',Complete,Parsed);
  Metric('Recognized syntax tokens','Sum of recognized tokens / significant tokens in parsed files. Not runtime coverage.',Recognized,Tokens);
  Metric('Confirmed static relationships','confirmed_static relationship records / all captured relationship records. Inferred edges remain separate.',Confirmed,Relations.Count);
  Metric('Unresolved relationships','unresolved relationship records / all captured relationship records. A zero count does not prove completeness.',Unresolved,Relations.Count);
  Metric('Serialized event bindings','Nonempty On-prefixed serialized properties with a confirmed static binds edge / nonempty On-prefixed properties in captured forms. Dynamic assignments excluded.',BoundEvents,Events);
  Metric('Source-located relationship evidence','Relationship records with a source location and derivation rule / all captured relationship records. Location is not human verification.',Evidence,Relations.Count);
  for V in FDocument.GetValue<TJSONArray>('syntax.diagnostics') do Diagnostics.AddElement(V.Clone as TJSONObject);
  for V in FDocument.GetValue<TJSONArray>('semantics.diagnostics') do Diagnostics.AddElement(V.Clone as TJSONObject);
end;
function TDPHWorkspaceView.FlagsText: string;
begin
  Result:='Generation '+FDocument.GetValue<Int64>('generation_id').ToString+' | ';
  if FDocument.GetValue<Boolean>('analysis_complete') then Result:=Result+'complete captured analysis' else Result:=Result+'PARTIAL analysis - inspect diagnostics';
  Result:=Result+' | static evidence; runtime behavior unobserved';
end;
end.
