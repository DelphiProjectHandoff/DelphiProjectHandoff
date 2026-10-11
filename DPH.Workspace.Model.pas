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
    function SourceFile(const APath: string): TJSONObject;
    function Properties(const AKey: string): TJSONArray;
    function Graph(const AKind,AKey: string; ALimit: Integer = 120): TJSONObject;
    function FlagsText: string;
    class function SelectionHash(const AConfig,APlatform: string; const ADefines,AExternalRoots: TArray<string>): string; static;
    property Document: TJSONObject read FDocument;
  end;
implementation
uses System.StrUtils, System.IOUtils, System.Hash, System.DateUtils;

class function TDPHWorkspaceView.SelectionHash(const AConfig,APlatform: string; const ADefines,AExternalRoots: TArray<string>): string;
begin Result:=THashSHA2.GetHashString(AConfig+#0+APlatform+#0+String.Join(#0,ADefines)+#1+String.Join(#0,AExternalRoots)); end;

class function TDPHWorkspaceView.Capture(AScan: TDPHScan; AGraph: TDPHSemanticGraph; AGeneration: Int64;
  const AEntry,AConfig,APlatform: string; const ADefines,AExternalRoots: TArray<string>): TJSONObject;
var A: TJSONArray; Value: string;
begin
  Result:=TJSONObject.Create; Result.AddPair('workspace_schema',TJSONNumber.Create(1));
  Result.AddPair('captured_utc',DateToISO8601(TTimeZone.Local.ToUniversalTime(Now),True));
  Result.AddPair('generation_id',TJSONNumber.Create(AGeneration)); Result.AddPair('entry',ExtractFileName(AEntry));
  Result.AddPair('root',AScan.Inventory.Root); Result.AddPair('configuration',AConfig); Result.AddPair('platform',APlatform);
  Result.AddPair('configuration_identity',AScan.Inventory.ConfigurationIdentity);
  Result.AddPair('selection_hash',SelectionHash(AConfig,APlatform,ADefines,AExternalRoots));
  A:=TJSONArray.Create; Result.AddPair('defines',A); for Value in ADefines do A.Add(Value);
  A:=TJSONArray.Create; Result.AddPair('external_roots',A); for Value in AExternalRoots do A.Add(Value);
  Result.AddPair('syntax',AScan.AsJSON); Result.AddPair('semantics',AGraph.AsJSON);
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
function TDPHWorkspaceView.Graph(const AKind,AKey: string; ALimit: Integer): TJSONObject;
var Nodes,Edges,AllNodes,AllEdges: TJSONArray; V: TJSONValue; R,S,N: TJSONObject;
    Seen: TDictionary<string,Boolean>; Queue: TQueue<string>; Key,FromKey,ToKey,Kind: string;
    I: Integer; Truncated: Boolean;
  procedure AddSymbolNode(const K: string);
  var Row,Sym: TJSONObject;
  begin
    if (K='') or Seen.ContainsKey(K) then Exit;
    if Seen.Count>=ALimit then begin Truncated:=True; Exit; end;
    Seen.Add(K,True); Sym:=Symbol(K); Row:=TJSONObject.Create; Row.AddPair('id',K);
    if Sym<>nil then begin Row.AddPair('label',Sym.GetValue<string>('name')); Row.AddPair('range',Sym.GetValue<TJSONObject>('range').Clone as TJSONObject); end
    else Row.AddPair('label',K); Nodes.AddElement(Row); Queue.Enqueue(K);
  end;
begin
  if (ALimit<1) or (ALimit>1000) then raise EArgumentException.Create('Invalid graph limit');
  Result:=TJSONObject.Create; Nodes:=TJSONArray.Create; Edges:=TJSONArray.Create;
  Result.AddPair('kind',AKind); Result.AddPair('nodes',Nodes); Result.AddPair('edges',Edges);
  Result.AddPair('generation_id',TJSONNumber.Create(FDocument.GetValue<Int64>('generation_id')));
  Result.AddPair('runtime_trace',TJSONBool.Create(False)); Truncated:=False;
  Seen:=TDictionary<string,Boolean>.Create; Queue:=TQueue<string>.Create;
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
      if AKey='' then for V in S.GetValue<TJSONArray>('symbols') do
      begin N:=V as TJSONObject; if N.GetValue<Boolean>('has_body') then begin AddSymbolNode(N.GetValue<string>('key')); Break; end; end;
      while Queue.Count>0 do
      begin
        Key:=Queue.Dequeue;
        for V in S.GetValue<TJSONArray>('relationships') do
        begin
          R:=V as TJSONObject; Kind:=R.GetValue<string>('kind'); FromKey:=R.GetValue<string>('from'); ToKey:=R.GetValue<string>('to','');
          if (AKind='Change impact') then begin if ToKey<>Key then Continue; end
          else if (AKind='Caller / callee') then begin if (FromKey<>Key) and (ToKey<>Key) then Continue; end
          else if FromKey<>Key then Continue;
          if (AKind='Execution') and not MatchText(Kind,['calls','schedules','passes_callback','binds']) then Continue;
          if (AKind='Form navigation') and not MatchText(Kind,['owns','binds','calls','schedules']) then Continue;
          if (AKind='Data flow') and not MatchText(Kind,['reads','writes','uses_type','renders','assigns_callback']) then Continue;
          AddSymbolNode(FromKey); AddSymbolNode(ToKey);
          if Seen.ContainsKey(FromKey) and Seen.ContainsKey(ToKey) then Edges.AddElement(R.Clone as TJSONObject);
          if Edges.Count>=ALimit*8 then begin Truncated:=True; Queue.Clear; Break; end;
        end;
      end;
    end;
    Result.AddPair('truncated',TJSONBool.Create(Truncated));
  finally Queue.Free; Seen.Free; end;
end;
function TDPHWorkspaceView.FlagsText: string;
begin
  Result:='Generation '+FDocument.GetValue<Int64>('generation_id').ToString+' | ';
  if FDocument.GetValue<Boolean>('analysis_complete') then Result:=Result+'complete captured analysis' else Result:=Result+'PARTIAL analysis — inspect diagnostics';
  Result:=Result+' | static evidence; runtime behavior unobserved';
end;
end.
