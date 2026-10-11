unit DPH.Analysis.Quality;
interface
uses System.SysUtils, System.JSON, DPH.Project.Analysis, DPH.Analysis.Model;
const DPHQualityVersion = 'DPH-QUALITY-1';
type
  TDPHSourceQuality = class
  public
    class function Analyze(AScan: TDPHScan; AGraph: TDPHSemanticGraph): TJSONObject; static;
  end;
implementation
uses System.Classes, System.Hash, System.StrUtils, System.Generics.Collections,
  System.Generics.Defaults, DPH.Parse.Model;
class function TDPHSourceQuality.Analyze(AScan: TDPHScan; AGraph: TDPHSemanticGraph): TJSONObject;
var Metrics,Duplicates,Unreferenced,Unreachable,Cycles,Members,Evidence: TJSONArray;
    Symbol: TDPHSymbol; Relation: TDPHRelation; Flow: TDPHFlowNode; Edge: TDPHFlowEdge;
    Parsed: TDPHParseResult; BodyNode,IRNode: TDPHIRNode; Token: TDPHToken;
    Row,Group,Item: TJSONObject; I,J,K,Node,Seed,Score,TokenCount,LineCount,EndLine,Parent,Depth,MaxDepth,Stamp: Integer;
    Inbound,Visited,Reached: TArray<Integer>; Eligible: TArray<Boolean>;
    FlowByRoutine,NextFlow,Calls,ReverseCalls: TObjectDictionary<Integer,TList<Integer>>;
    Indices,Neighbors,Component,Order: TList<Integer>; Stack: TStack<Integer>; Queue: TQueue<Integer>;
    Signatures: TDictionary<string,TJSONObject>; Decisions: TDictionary<string,Boolean>;
    MemberSet: TDictionary<Integer,Boolean>; Builder: TStringBuilder; Fingerprint,DecisionKey: string;
    CompleteBody,SelfCall: Boolean;
    Hashes: TArray<string>;
    TokenCache: TDictionary<TDPHParseResult,TDPHTokens>;
    SignificantTokens: TDPHTokens;
    FilteredTokens: TList<TDPHToken>;
  procedure AddIndex(Map: TObjectDictionary<Integer,TList<Integer>>; Source,Target: Integer);
  var List: TList<Integer>;
  begin
    if not Map.TryGetValue(Source,List) then begin List:=TList<Integer>.Create; Map.Add(Source,List); end;
    List.Add(Target);
  end;
  function EvidenceRow(ASymbol: TDPHSymbol): TJSONObject;
  begin
    Result:=TJSONObject.Create; Result.AddPair('object_key',ASymbol.Key); Result.AddPair('name',ASymbol.QualifiedName);
    Result.AddPair('range',DPHRangeJSON(ASymbol.Location)); Result.AddPair('source_hash',ASymbol.SourceHash);
    Result.AddPair('verification_state','source_derived_candidate_unreviewed');
  end;
begin
  Result:=TJSONObject.Create; Result.AddPair('version',DPHQualityVersion); Result.AddPair('input_fingerprint',AGraph.Fingerprint);
  Result.AddPair('definition','Structural decision score is 1 plus unique captured if/for/while/repeat decisions and explicit case arms. It is not compiler-exact cyclomatic complexity or a maintainability index. Body equality uses significant active tokens with exact literals, normalized identifier case and conditional identity. At least 12 tokens and a complete parsed file are required; unknown conditional bodies are excluded. Missing inbound references, disconnected CFG statements and call cycles are investigation candidates, never proof that code is unused or removable. Dynamic dispatch, external callers, parser gaps and runtime conditions remain unknown.');
  Metrics:=TJSONArray.Create; Result.AddPair('routines',Metrics);
  Duplicates:=TJSONArray.Create; Result.AddPair('duplicate_bodies',Duplicates);
  Unreferenced:=TJSONArray.Create; Result.AddPair('unreferenced_candidates',Unreferenced);
  Unreachable:=TJSONArray.Create; Result.AddPair('unreachable_candidates',Unreachable);
  Cycles:=TJSONArray.Create; Result.AddPair('call_cycles',Cycles);
  SetLength(Inbound,AGraph.Symbols.Count); SetLength(Eligible,AGraph.Symbols.Count);
  SetLength(Visited,AGraph.Symbols.Count); SetLength(Reached,AGraph.FlowNodes.Count);
  FlowByRoutine:=TObjectDictionary<Integer,TList<Integer>>.Create([doOwnsValues]);
  NextFlow:=TObjectDictionary<Integer,TList<Integer>>.Create([doOwnsValues]);
  Calls:=TObjectDictionary<Integer,TList<Integer>>.Create([doOwnsValues]);
  ReverseCalls:=TObjectDictionary<Integer,TList<Integer>>.Create([doOwnsValues]);
  Signatures:=TDictionary<string,TJSONObject>.Create; Decisions:=TDictionary<string,Boolean>.Create;
  MemberSet:=TDictionary<Integer,Boolean>.Create; Order:=TList<Integer>.Create; Component:=TList<Integer>.Create;
  Stack:=TStack<Integer>.Create; Queue:=TQueue<Integer>.Create; Builder:=TStringBuilder.Create;
  TokenCache:=TDictionary<TDPHParseResult,TDPHTokens>.Create; FilteredTokens:=TList<TDPHToken>.Create;
  try
    for I:=0 to AGraph.Symbols.Count-1 do Eligible[I]:=AGraph.Symbols[I].HasBody and (AGraph.Symbols[I].Kind='routine');
    for Relation in AGraph.Relations do begin
      if (Relation.ToSymbol>=0) and not MatchText(Relation.Kind,['owns','imports','documented_by','test_covers']) then Inc(Inbound[Relation.ToSymbol]);
      if (Relation.ToSymbol>=0) and Eligible[Relation.FromSymbol] and Eligible[Relation.ToSymbol] and
        MatchText(Relation.Kind,['calls','dispatches_callback','schedules','passes_callback']) then begin
        AddIndex(Calls,Relation.FromSymbol,Relation.ToSymbol); AddIndex(ReverseCalls,Relation.ToSymbol,Relation.FromSymbol);
      end;
    end;
    for I:=0 to AGraph.FlowNodes.Count-1 do AddIndex(FlowByRoutine,AGraph.FlowNodes[I].Routine,I);
    for Edge in AGraph.FlowEdges do
      if AGraph.FlowNodes[Edge.FromNode].Routine=AGraph.FlowNodes[Edge.ToNode].Routine then AddIndex(NextFlow,Edge.FromNode,Edge.ToNode);
    Stamp:=0;
    for Symbol in AGraph.Symbols do begin
      if not Eligible[Symbol.Index] then Continue;
      Row:=EvidenceRow(Symbol); Metrics.AddElement(Row); Score:=1; Decisions.Clear;
      if FlowByRoutine.TryGetValue(Symbol.Index,Indices) then begin
        Inc(Stamp); Queue.Clear;
        for I in Indices do if AGraph.FlowNodes[I].Kind='entry' then begin Reached[I]:=Stamp; Queue.Enqueue(I); end;
        while Queue.Count>0 do begin Node:=Queue.Dequeue;
          if NextFlow.TryGetValue(Node,Neighbors) then for J in Neighbors do if Reached[J]<>Stamp then begin Reached[J]:=Stamp; Queue.Enqueue(J); end;
        end;
        for I in Indices do begin Flow:=AGraph.FlowNodes[I];
          if MatchText(Flow.Kind,['if','for','while','repeat','case_arm']) then begin
            DecisionKey:=Flow.Location.Source+':'+IntToStr(Flow.Location.StartByte)+':'+Flow.Kind;
            if not Decisions.ContainsKey(DecisionKey) then begin Decisions.Add(DecisionKey,True); Inc(Score); end;
          end;
          if (Reached[I]<>Stamp) and not MatchText(Flow.Kind,['entry','normal_exit','exception_exit','exception_dispatch','unresolved_jump_target']) then begin
            Item:=EvidenceRow(Symbol); Item.RemovePair('range').Free; Item.AddPair('range',DPHRangeJSON(Flow.Location));
            Item.AddPair('finding','No path from the captured CFG entry, including modeled uncertain edges; unsupported jumps, exception semantics or runtime entry may invalidate this candidate.');
            Item.AddPair('flow_node',TJSONNumber.Create(I)); Unreachable.AddElement(Item);
          end;
        end;
        Row.AddPair('captured_cfg_nodes',TJSONNumber.Create(Indices.Count));
      end else Row.AddPair('captured_cfg_nodes',TJSONNumber.Create(0));
      Row.AddPair('structural_decision_score',TJSONNumber.Create(Score));
      Row.AddPair('incoming_relationships',TJSONNumber.Create(Inbound[Symbol.Index]));
      if (Inbound[Symbol.Index]=0) and not Symbol.Exported then begin
        Item:=EvidenceRow(Symbol); Item.AddPair('finding','No captured non-ownership incoming reference. Lexical ownership, imports and documentation/test-coverage annotations are excluded. External callers, RTTI, callbacks and unresolved calls may still use it; investigate rather than delete.'); Unreferenced.AddElement(Item);
      end;
      Fingerprint:=''; TokenCount:=0; LineCount:=0; MaxDepth:=0; CompleteBody:=False;
      if AScan.Results.TryGetValue(Symbol.Location.Source,Parsed) and (Symbol.BodyNode>=0) and (Symbol.BodyNode<Parsed.Nodes.Count) then begin
        BodyNode:=Parsed.Nodes[Symbol.BodyNode]; Builder.Clear; EndLine:=BodyNode.Location.Line; CompleteBody:=Parsed.Complete;
        if not TokenCache.TryGetValue(Parsed,SignificantTokens) then begin
          FilteredTokens.Clear;
          for Token in Parsed.Tokens do if not (Token.Kind in [tkSpace,tkComment,tkDirective]) and (Token.Active=daActive) then FilteredTokens.Add(Token);
          SignificantTokens:=FilteredTokens.ToArray; TokenCache.Add(Parsed,SignificantTokens);
        end;
        for I:=BodyNode.FirstToken to BodyNode.LastToken do begin
          if (I<0) or (I>=Length(SignificantTokens)) then begin CompleteBody:=False; Break; end;
          Token:=SignificantTokens[I]; if Token.Location.Source<>BodyNode.Location.Source then CompleteBody:=False;
          if (Token.Active=daInactive) or (Token.Kind in [tkSpace,tkComment,tkDirective,tkEOF]) then Continue;
          Inc(TokenCount); if Token.Location.Line>EndLine then EndLine:=Token.Location.Line;
          Builder.Append(IntToStr(Ord(Token.Kind))).Append(':').Append(IntToStr(Ord(Token.Active))).Append(':');
          if Token.Kind=tkIdentifier then Builder.Append(LowerCase(Token.Text)) else Builder.Append(Token.Text);
          Builder.Append(#0).Append(Token.Condition).Append(#0);
        end;
        LineCount:=EndLine-BodyNode.Location.Line+1;
        for IRNode in Parsed.Nodes do
          if (IRNode.Location.Source=BodyNode.Location.Source) and (IRNode.Location.StartByte>=BodyNode.Location.StartByte) and
            (IRNode.Location.EndByte<=BodyNode.Location.EndByte) and (IRNode.Kind.StartsWith('statement_')) then begin
            Parent:=IRNode.Parent; Depth:=0;
            while (Parent>=0) and (Parent<Parsed.Nodes.Count) and (Depth<128) do begin
              if Parent=Symbol.BodyNode then Break; Inc(Depth); Parent:=Parsed.Nodes[Parent].Parent;
            end;
            if Depth>MaxDepth then MaxDepth:=Depth;
          end;
        if CompleteBody and (TokenCount>=12) then Fingerprint:=THashSHA2.GetHashString(Builder.ToString);
      end;
      Row.AddPair('body_line_span',TJSONNumber.Create(LineCount)); Row.AddPair('significant_body_tokens',TJSONNumber.Create(TokenCount));
      Row.AddPair('maximum_parse_nesting',TJSONNumber.Create(MaxDepth)); Row.AddPair('body_comparison_eligible',TJSONBool.Create(Fingerprint<>''));
      if Fingerprint<>'' then begin
        if not Signatures.TryGetValue(Fingerprint,Group) then begin
          Group:=TJSONObject.Create; Signatures.Add(Fingerprint,Group); Group.AddPair('body_fingerprint',Fingerprint);
          Group.AddPair('finding','Equal significant-token bodies are potential duplicates, not proven equivalent routines. Signatures, types, captures and surrounding state can differ.');
          Members:=TJSONArray.Create; Group.AddPair('members',Members); Members.AddElement(EvidenceRow(Symbol));
        end else Group.GetValue<TJSONArray>('members').AddElement(EvidenceRow(Symbol));
      end;
    end;
    Hashes:=Signatures.Keys.ToArray; TArray.Sort<string>(Hashes);
    for Fingerprint in Hashes do begin Group:=Signatures[Fingerprint];
      if Group.GetValue<TJSONArray>('members').Count>1 then Duplicates.AddElement(Group.Clone as TJSONObject);
    end;
    // Iterative strongly-connected components avoid recursive traversal of large call graphs.
    for Seed:=0 to AGraph.Symbols.Count-1 do if Eligible[Seed] and (Visited[Seed]=0) then begin
      Stack.Push(Seed);
      while Stack.Count>0 do begin Node:=Stack.Pop;
        if Node<0 then begin Order.Add(-Node-1); Continue; end;
        if Visited[Node]<>0 then Continue; Visited[Node]:=1; Stack.Push(-Node-1);
        if Calls.TryGetValue(Node,Neighbors) then for J in Neighbors do if Visited[J]=0 then Stack.Push(J);
      end;
    end;
    for I:=Order.Count-1 downto 0 do begin Seed:=Order[I]; if Visited[Seed]<>1 then Continue;
      Component.Clear; MemberSet.Clear; Stack.Push(Seed);
      while Stack.Count>0 do begin Node:=Stack.Pop; if Visited[Node]<>1 then Continue;
        Visited[Node]:=2; Component.Add(Node); MemberSet.Add(Node,True);
        if ReverseCalls.TryGetValue(Node,Neighbors) then for J in Neighbors do if Visited[J]=1 then Stack.Push(J);
      end;
      SelfCall:=False; if Calls.TryGetValue(Seed,Neighbors) then SelfCall:=Neighbors.Contains(Seed);
      if (Component.Count<2) and not SelfCall then Continue;
      Component.Sort; Group:=TJSONObject.Create; Cycles.AddElement(Group);
      Group.AddPair('finding','Captured call-graph cycle; recursion is possible, but runtime feasibility and termination are unverified.');
      Members:=TJSONArray.Create; Group.AddPair('members',Members); for J in Component do Members.AddElement(EvidenceRow(AGraph.Symbols[J]));
      Evidence:=TJSONArray.Create; Group.AddPair('evidence',Evidence); K:=0;
      for Relation in AGraph.Relations do if MemberSet.ContainsKey(Relation.FromSymbol) and MemberSet.ContainsKey(Relation.ToSymbol) and
        MatchText(Relation.Kind,['calls','dispatches_callback','schedules','passes_callback']) then begin
        Inc(K); if Evidence.Count>=16 then Continue; Item:=DPHRangeJSON(Relation.Location); Evidence.AddElement(Item);
        Item.AddPair('from',AGraph.Symbols[Relation.FromSymbol].Key); Item.AddPair('to',AGraph.Symbols[Relation.ToSymbol].Key);
        Item.AddPair('resolution',Relation.Resolution); Item.AddPair('rule',Relation.Rule);
      end;
      Group.AddPair('relationship_count',TJSONNumber.Create(K)); Group.AddPair('omitted_evidence',TJSONNumber.Create(K-Evidence.Count));
    end;
  finally
    for Group in Signatures.Values do Group.Free;
    Builder.Free; Queue.Free; Stack.Free; Component.Free; Order.Free; MemberSet.Free; Decisions.Free;
    FilteredTokens.Free; TokenCache.Free;
    Signatures.Free; ReverseCalls.Free; Calls.Free; NextFlow.Free; FlowByRoutine.Free;
  end;
end;
end.

