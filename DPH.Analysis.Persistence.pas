unit DPH.Analysis.Persistence;

interface
uses DPH.Analysis.Model, DPH.Project.Analysis, DPH.Storage.Database;
type
  TDPHSemanticPersistence = class
  public
    class function Stage(AScan: TDPHScan; AGraph: TDPHSemanticGraph; AStore: TDPHKnowledgeStore; AConfiguration: Int64): Int64; static;
    class function Publish(AScan: TDPHScan; AGraph: TDPHSemanticGraph; AStore: TDPHKnowledgeStore; AGeneration: Int64): Boolean; static;
  end;
implementation
uses System.SysUtils, System.JSON, DPH.Parse.Model;

class function TDPHSemanticPersistence.Stage(AScan: TDPHScan; AGraph: TDPHSemanticGraph; AStore: TDPHKnowledgeStore; AConfiguration: Int64): Int64;
var Entities,Nodes: TArray<Int64>; I: Integer; S: TDPHSymbol; R: TDPHRelation;
    N: TDPHFlowNode; E: TDPHFlowEdge; D: TDPHDiagnostic; J,Range: TJSONObject;
    Evidence,Target: Int64; Verification: string;
begin
  if AGraph.Fingerprint<>TDPHKnowledgeStore.ManifestHash(AScan.Inventory.Manifest) then raise EArgumentException.Create('Semantic graph does not match capture');
  if AGraph.ContextHash<>AScan.ContextHash then raise EArgumentException.Create('Semantic graph does not match configuration context');
  Result:=AScan.Stage(AStore,AConfiguration,DPHSemanticVersion);
  AStore.BeginFacts(Result);
  try
    SetLength(Entities,AGraph.Symbols.Count); SetLength(Nodes,AGraph.FlowNodes.Count);
    for I:=0 to AGraph.Symbols.Count-1 do
    begin
      S:=AGraph.Symbols[I]; J:=TJSONObject.Create;
      try
        J.AddPair('variant',S.Variant); J.AddPair('condition',S.Condition); J.AddPair('source_hash',S.SourceHash);
        J.AddPair('type',S.TypeName); J.AddPair('dispatch',S.Dispatch); J.AddPair('range',DPHRangeJSON(S.Location));
        Entities[I]:=AStore.AddSourceEntity(Result,S.Location.Source,S.Key,'semantic_'+S.Kind,S.QualifiedName,S.Signature,
          S.Location.StartByte,S.Location.EndByte,J.ToJSON);
      finally J.Free; end;
    end;
    for R in AGraph.Relations do
    begin
      J:=TJSONObject.Create; Range:=DPHRangeJSON(R.Location);
      try
        J.AddPair('rule',R.Rule); J.AddPair('label',R.LabelText); J.AddPair('source_hash',AGraph.SourceHashes[R.Location.Source]);
        J.AddPair('resolution',R.Resolution); J.AddPair('runtime_observed',TJSONBool.Create(False));
        Verification:='inferred'; if R.Resolution='confirmed_static' then Verification:='verified';
        Evidence:=AStore.AddEvidence(Result,R.Location.Source,Range.ToJSON,'semantic_derivation',J.ToJSON,Verification);
        Target:=0; if R.ToSymbol>=0 then Target:=Entities[R.ToSymbol];
        AStore.AddRelationship(Result,Entities[R.FromSymbol],Target,Evidence,R.Kind,R.Resolution,R.Condition);
      finally Range.Free; J.Free; end;
    end;
    for I:=0 to AGraph.FlowNodes.Count-1 do
    begin
      N:=AGraph.FlowNodes[I]; Range:=DPHRangeJSON(N.Location);
      try
        // Evidence validates the captured byte range, including nodes from include files.
        AStore.AddEvidence(Result,N.Location.Source,Range.ToJSON,'control_flow_derivation',N.ExpressionText,'inferred');
        Nodes[I]:=AStore.AddFlowNode(Result,Entities[N.Routine],N.Kind,Range.ToJSON,N.ExpressionText);
      finally Range.Free; end;
    end;
    for E in AGraph.FlowEdges do AStore.AddFlowEdge(Result,Nodes[E.FromNode],Nodes[E.ToNode],E.Kind,E.Resolution);
    for D in AGraph.Diagnostics do
    begin Range:=DPHRangeJSON(D.Location); try AStore.AddDiagnostic(Result,D.Severity,D.Code,D.MessageText,Range.ToJSON); finally Range.Free; end; end;
    AStore.CommitFacts;
  except on E: Exception do begin AStore.RollbackFacts; AStore.FailGeneration(Result,E.Message); raise; end; end;
end;
class function TDPHSemanticPersistence.Publish(AScan: TDPHScan; AGraph: TDPHSemanticGraph; AStore: TDPHKnowledgeStore; AGeneration: Int64): Boolean;
begin
  if AGraph.Fingerprint<>TDPHKnowledgeStore.ManifestHash(AScan.Inventory.Manifest) then raise EArgumentException.Create('Semantic graph does not match capture');
  if AGraph.ContextHash<>AScan.ContextHash then raise EArgumentException.Create('Semantic graph does not match configuration context');
  Result:=AScan.Publish(AStore,AGeneration,AGraph.Complete);
end;
end.
