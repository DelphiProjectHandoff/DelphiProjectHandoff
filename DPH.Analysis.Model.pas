unit DPH.Analysis.Model;

interface
uses System.SysUtils, System.JSON, System.Generics.Collections, DPH.Parse.Model;
const DPHSemanticVersion = 'DPH-WP3-5';
      DPHSemanticSchema = 1;
type
  TDPHSymbol = class
  public
    Key,Name,QualifiedName,Kind,Signature,UnitName,OwnerName,TypeName,Condition,Variant,Dispatch,SourceHash: string;
    Location: TDPHRange;
    Owner,NodeIndex,BodyNode,Index,MinArguments: Integer;
    ParameterNames,ParameterTypes: TArray<string>;
    HasBody,Exported,ClassMethod: Boolean;
    Occurrences: TList<TDPHRange>;
    constructor Create;
    destructor Destroy; override;
  end;
  TDPHRelation = record
    FromSymbol,ToSymbol: Integer;
    Kind,Resolution,Rule,LabelText,Condition: string;
    Location: TDPHRange;
  end;
  TDPHFlowNode = record
    Routine: Integer;
    Kind,ExpressionText: string;
    Location: TDPHRange;
  end;
  TDPHFlowEdge = record
    FromNode,ToNode: Integer;
    Kind,Resolution: string;
  end;
  TDPHSemanticGraph = class
  public
    Symbols: TObjectList<TDPHSymbol>;
    Relations: TList<TDPHRelation>;
    FlowNodes: TList<TDPHFlowNode>;
    FlowEdges: TList<TDPHFlowEdge>;
    Diagnostics: TDPHDiagnostics;
    SourceHashes: TDictionary<string,string>;
    Fingerprint,Configuration,ContextHash: string;
    Complete: Boolean;
    constructor Create;
    destructor Destroy; override;
    function AddRelation(AFrom,ATo: Integer; const AKind,AResolution,ARule,ALabel: string;
      const ALocation: TDPHRange; const ACondition: string = ''): Integer;
    function AsJSON: TJSONObject;
    function ReverseReferences(const AKey: string): TJSONArray;
    function Impact(const ASeeds: TArray<string>; AMaxDepth: Integer=32; AMaxNodes: Integer=10000): TJSONObject;
    function SymbolIndex(const AKey: string): Integer;
  end;
function DPHRangeJSON(const ARange: TDPHRange): TJSONObject;
implementation

function DPHRangeJSON(const ARange: TDPHRange): TJSONObject;
begin
  Result:=TJSONObject.Create; Result.AddPair('source',ARange.Source);
  Result.AddPair('start',TJSONNumber.Create(ARange.StartByte)); Result.AddPair('end',TJSONNumber.Create(ARange.EndByte));
  Result.AddPair('line',TJSONNumber.Create(ARange.Line)); Result.AddPair('column',TJSONNumber.Create(ARange.Column));
end;
constructor TDPHSymbol.Create;
begin inherited; Owner:=-1; BodyNode:=-1; Occurrences:=TList<TDPHRange>.Create; end;
destructor TDPHSymbol.Destroy;
begin Occurrences.Free; inherited; end;
constructor TDPHSemanticGraph.Create;
begin
  inherited; Symbols:=TObjectList<TDPHSymbol>.Create(True); Relations:=TList<TDPHRelation>.Create;
  FlowNodes:=TList<TDPHFlowNode>.Create; FlowEdges:=TList<TDPHFlowEdge>.Create;
  Diagnostics:=TDPHDiagnostics.Create; SourceHashes:=TDictionary<string,string>.Create; Complete:=True;
end;
destructor TDPHSemanticGraph.Destroy;
begin SourceHashes.Free; Diagnostics.Free; FlowEdges.Free; FlowNodes.Free; Relations.Free; Symbols.Free; inherited; end;
function TDPHSemanticGraph.AddRelation(AFrom,ATo: Integer; const AKind,AResolution,ARule,ALabel: string;
  const ALocation: TDPHRange; const ACondition: string): Integer;
var R: TDPHRelation;
begin
  if Relations.Count>=200000 then raise ERangeError.Create('Semantic relationship limit');
  R.FromSymbol:=AFrom; R.ToSymbol:=ATo; R.Kind:=AKind; R.Resolution:=AResolution;
  R.Rule:=ARule; R.LabelText:=ALabel; R.Location:=ALocation; R.Condition:=ACondition;
  if AResolution='unresolved' then Complete:=False;
  Result:=Relations.Add(R);
end;
function TDPHSemanticGraph.SymbolIndex(const AKey: string): Integer;
var S: TDPHSymbol;
begin Result:=-1; for S in Symbols do if S.Key=AKey then Exit(S.Index); end;
function TDPHSemanticGraph.AsJSON: TJSONObject;
var Rows,Occurrences: TJSONArray; J: TJSONObject; S: TDPHSymbol; R: TDPHRelation;
    N: TDPHFlowNode; E: TDPHFlowEdge; D: TDPHDiagnostic; L: TDPHRange; I: Integer; Hash: string;
begin
  Result:=TJSONObject.Create; Result.AddPair('schema_version',TJSONNumber.Create(DPHSemanticSchema));
  Result.AddPair('analyzer',DPHSemanticVersion); Result.AddPair('input_fingerprint',Fingerprint);
  Result.AddPair('context_fingerprint',ContextHash);
  Result.AddPair('configuration',Configuration); Result.AddPair('complete',TJSONBool.Create(Complete));
  Result.AddPair('diagnostic_limit_reached',TJSONBool.Create(Diagnostics.Count>=10000));
  Rows:=TJSONArray.Create; Result.AddPair('symbols',Rows);
  for S in Symbols do
  begin
    J:=TJSONObject.Create; Rows.AddElement(J); J.AddPair('key',S.Key); J.AddPair('name',S.QualifiedName);
    J.AddPair('kind',S.Kind); J.AddPair('signature',S.Signature); J.AddPair('type',S.TypeName);
    J.AddPair('variant',S.Variant); J.AddPair('condition',S.Condition); J.AddPair('dispatch',S.Dispatch);
    J.AddPair('has_body',TJSONBool.Create(S.HasBody)); J.AddPair('source_hash',S.SourceHash); J.AddPair('range',DPHRangeJSON(S.Location));
    Occurrences:=TJSONArray.Create; J.AddPair('occurrences',Occurrences); for L in S.Occurrences do Occurrences.AddElement(DPHRangeJSON(L));
  end;
  Rows:=TJSONArray.Create; Result.AddPair('relationships',Rows);
  for R in Relations do
  begin
    J:=TJSONObject.Create; Rows.AddElement(J); J.AddPair('from',Symbols[R.FromSymbol].Key);
    if R.ToSymbol>=0 then J.AddPair('to',Symbols[R.ToSymbol].Key) else J.AddPair('to',TJSONNull.Create);
    J.AddPair('kind',R.Kind); J.AddPair('resolution',R.Resolution); J.AddPair('rule',R.Rule);
    J.AddPair('label',R.LabelText); J.AddPair('condition',R.Condition); J.AddPair('range',DPHRangeJSON(R.Location));
    Hash:=''; SourceHashes.TryGetValue(R.Location.Source,Hash); J.AddPair('source_hash',Hash);
  end;
  Rows:=TJSONArray.Create; Result.AddPair('flow_nodes',Rows);
  for I:=0 to FlowNodes.Count-1 do
  begin
    N:=FlowNodes[I]; J:=TJSONObject.Create; Rows.AddElement(J); J.AddPair('id',TJSONNumber.Create(I));
    J.AddPair('routine',Symbols[N.Routine].Key); J.AddPair('kind',N.Kind); J.AddPair('expression',N.ExpressionText);
    J.AddPair('range',DPHRangeJSON(N.Location));
    Hash:=''; SourceHashes.TryGetValue(N.Location.Source,Hash); J.AddPair('source_hash',Hash);
  end;
  Rows:=TJSONArray.Create; Result.AddPair('flow_edges',Rows);
  for E in FlowEdges do
  begin
    J:=TJSONObject.Create; Rows.AddElement(J); J.AddPair('from',TJSONNumber.Create(E.FromNode));
    J.AddPair('to',TJSONNumber.Create(E.ToNode)); J.AddPair('kind',E.Kind); J.AddPair('resolution',E.Resolution);
  end;
  Rows:=TJSONArray.Create; Result.AddPair('diagnostics',Rows);
  for D in Diagnostics do
  begin
    J:=TJSONObject.Create; Rows.AddElement(J); J.AddPair('code',D.Code); J.AddPair('message',D.MessageText);
    J.AddPair('severity',D.Severity); J.AddPair('range',DPHRangeJSON(D.Location));
  end;
end;
function TDPHSemanticGraph.ReverseReferences(const AKey: string): TJSONArray;
var Target,I: Integer; R: TDPHRelation; J: TJSONObject;
begin
  Result:=TJSONArray.Create; Target:=SymbolIndex(AKey); if Target<0 then Exit;
  for I:=0 to Relations.Count-1 do
  begin R:=Relations[I]; if R.ToSymbol<>Target then Continue;
    J:=TJSONObject.Create; Result.AddElement(J); J.AddPair('from',Symbols[R.FromSymbol].Key);
    J.AddPair('kind',R.Kind); J.AddPair('resolution',R.Resolution); J.AddPair('edge',TJSONNumber.Create(I));
    J.AddPair('rule',R.Rule); J.AddPair('range',DPHRangeJSON(R.Location));
    J.AddPair('source_hash',SourceHashes[R.Location.Source]); end;
end;
function TDPHSemanticGraph.Impact(const ASeeds: TArray<string>; AMaxDepth,AMaxNodes: Integer): TJSONObject;
var Seen: TDictionary<Integer,Integer>; Queue: TQueue<Integer>; Edges: TObjectDictionary<Integer,TList<Integer>>;
    Rows: TJSONArray; J: TJSONObject; Seed: string; Index,Depth,I,Target: Integer; R: TDPHRelation;
    Neighbors: TList<Integer>; Truncated: Boolean; Via: TDictionary<Integer,Integer>;
begin
  if (AMaxDepth<0) or (AMaxDepth>128) or (AMaxNodes<1) or (AMaxNodes>100000) then raise EArgumentException.Create('Invalid impact bounds');
  Result:=TJSONObject.Create; Rows:=TJSONArray.Create; Result.AddPair('possible_impact',Rows);
  Result.AddPair('input_fingerprint',Fingerprint); Result.AddPair('runtime_impact_proved',TJSONBool.Create(False));
  Result.AddPair('context_fingerprint',ContextHash);
  Seen:=TDictionary<Integer,Integer>.Create; Queue:=TQueue<Integer>.Create;
  Edges:=TObjectDictionary<Integer,TList<Integer>>.Create([doOwnsValues]); Truncated:=False;
  Via:=TDictionary<Integer,Integer>.Create;
  try
    for I:=0 to Relations.Count-1 do
    begin R:=Relations[I]; if R.ToSymbol<0 then Continue;
      if not Edges.TryGetValue(R.ToSymbol,Neighbors) then begin Neighbors:=TList<Integer>.Create; Edges.Add(R.ToSymbol,Neighbors); end; Neighbors.Add(I); end;
    for Seed in ASeeds do
    begin Index:=SymbolIndex(Seed); if (Index>=0) and not Seen.ContainsKey(Index) then
      begin if Seen.Count>=AMaxNodes then begin Truncated:=True; Continue; end; Seen.Add(Index,0); Queue.Enqueue(Index); end; end;
    while Queue.Count>0 do
    begin
      Target:=Queue.Dequeue; Depth:=Seen[Target]; J:=TJSONObject.Create; Rows.AddElement(J);
      J.AddPair('key',Symbols[Target].Key); J.AddPair('distance',TJSONNumber.Create(Depth));
      if Via.TryGetValue(Target,I) then
      begin
        R:=Relations[I]; J.AddPair('via_edge',TJSONNumber.Create(I)); J.AddPair('depends_on',Symbols[R.ToSymbol].Key);
        J.AddPair('relation',R.Kind); J.AddPair('resolution',R.Resolution); J.AddPair('rule',R.Rule);
        J.AddPair('range',DPHRangeJSON(R.Location)); J.AddPair('source_hash',SourceHashes[R.Location.Source]);
      end;
      if not Edges.TryGetValue(Target,Neighbors) then Continue;
      for I in Neighbors do
      begin
        R:=Relations[I]; Index:=R.FromSymbol; if Seen.ContainsKey(Index) then Continue;
        if (Depth>=AMaxDepth) or (Seen.Count>=AMaxNodes) then begin Truncated:=True; Continue; end;
        Seen.Add(Index,Depth+1); Via.Add(Index,I); Queue.Enqueue(Index);
      end;
    end;
    Result.AddPair('truncated',TJSONBool.Create(Truncated)); Result.AddPair('unresolved_edges_omitted',TJSONBool.Create(True));
  finally Via.Free; Edges.Free; Queue.Free; Seen.Free; end;
end;
end.
