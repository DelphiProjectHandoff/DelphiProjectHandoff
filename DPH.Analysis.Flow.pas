unit DPH.Analysis.Flow;

interface
uses System.SysUtils, System.Generics.Collections, DPH.Parse.Model, DPH.Analysis.Model;
type
  TDPHFlowBuilder = class
  private
    FGraph: TDPHSemanticGraph;
    FIR: TDPHParseResult;
    FTokens: TDPHTokens;
    FRoutine,FDepth: Integer;
    FChildren: TObjectDictionary<Integer,TList<Integer>>;
    function Node(const Kind,ExpressionText: string; const Location: TDPHRange): Integer;
    procedure Edge(AFrom,ATo: Integer; const Kind: string; const Resolution: string = 'confirmed_static');
    function Sequence(const Items: TArray<Integer>; ANext,AReturn,AException,ABreak,AContinue: Integer): Integer;
    function Statement(AIndex,ANext,AReturn,AException,ABreak,AContinue: Integer): Integer;
  public
    procedure Build(AGraph: TDPHSemanticGraph; ARoutine: Integer; AIR: TDPHParseResult;
      const ATokens: TDPHTokens; ABody: Integer);
  end;
implementation
uses System.StrUtils;

function TDPHFlowBuilder.Node(const Kind,ExpressionText: string; const Location: TDPHRange): Integer;
var N: TDPHFlowNode;
begin
  if FGraph.FlowNodes.Count>=100000 then raise ERangeError.Create('Control flow node limit');
  N.Routine:=FRoutine; N.Kind:=Kind; N.ExpressionText:=ExpressionText; N.Location:=Location;
  Result:=FGraph.FlowNodes.Add(N);
end;
procedure TDPHFlowBuilder.Edge(AFrom,ATo: Integer; const Kind,Resolution: string);
var E: TDPHFlowEdge;
begin
  if ATo<0 then Exit;
  if FGraph.FlowEdges.Count>=300000 then raise ERangeError.Create('Control flow edge limit');
  E.FromNode:=AFrom; E.ToNode:=ATo; E.Kind:=Kind; E.Resolution:=Resolution; FGraph.FlowEdges.Add(E);
end;
function TDPHFlowBuilder.Sequence(const Items: TArray<Integer>; ANext,AReturn,AException,ABreak,AContinue: Integer): Integer;
var I: Integer;
begin
  Result:=ANext;
  for I:=High(Items) downto 0 do Result:=Statement(Items[I],Result,AReturn,AException,ABreak,AContinue);
end;
function TDPHFlowBuilder.Statement(AIndex,ANext,AReturn,AException,ABreak,AContinue: Integer): Integer;
var N,C: TDPHIRNode; All: TList<Integer>; Items,ProtectedItems,HandlerItems: TList<Integer>;
    I,J,Boundary,Start,Finish,ReturnVia,ExceptionVia,BreakVia,ContinueVia,Handler,Condition: Integer;
    ExpressionText,Kind: string;
begin
  N:=FIR.Nodes[AIndex]; Inc(FDepth);
  try
    if FDepth>128 then raise ERangeError.Create('Control flow nesting limit');
    Items:=TList<Integer>.Create;
    try
      ExpressionText:='';
      if FChildren.TryGetValue(AIndex,All) then for I in All do
      begin
        C:=FIR.Nodes[I];
        if C.Kind='expression' then begin if ExpressionText<>'' then ExpressionText:=ExpressionText+'; '; ExpressionText:=ExpressionText+C.Value; end
        else if (C.Kind='block') or C.Kind.StartsWith('statement_') or (C.Kind='opaque') then Items.Add(I);
      end;
      if N.Kind='block' then Exit(Sequence(Items.ToArray,ANext,AReturn,AException,ABreak,AContinue));
      Kind:=N.Kind; if Kind.StartsWith('statement_') then Delete(Kind,1,10);
      Result:=Node(Kind,ExpressionText,N.Location);
      if Kind='if' then
      begin
        Start:=ANext; Finish:=ANext;
        if Items.Count>0 then Start:=Statement(Items[0],ANext,AReturn,AException,ABreak,AContinue);
        if Items.Count>1 then Finish:=Statement(Items[1],ANext,AReturn,AException,ABreak,AContinue);
        Edge(Result,Start,'true'); Edge(Result,Finish,'false'); Edge(Result,AException,'may_raise','possible_dynamic');
      end
      else if MatchText(Kind,['while','for']) then
      begin
        Start:=Sequence(Items.ToArray,Result,AReturn,AException,ANext,Result);
        Edge(Result,Start,'iterate'); Edge(Result,ANext,'loop_exit'); Edge(Result,AException,'may_raise','possible_dynamic');
      end
      else if Kind='repeat' then
      begin
        Condition:=Result; Start:=Sequence(Items.ToArray,Condition,AReturn,AException,ANext,Condition);
        Edge(Condition,Start,'false'); Edge(Condition,ANext,'true'); Edge(Condition,AException,'may_raise','possible_dynamic'); Result:=Start;
      end
      else if Kind='try' then
      begin
        // The parser retains exact tokens: partition only at this try's own delimiter.
        Boundary:=-1; J:=N.FirstToken+1;
        while J<=N.LastToken do
        begin
          if MatchText(FTokens[J].Text,['finally','except']) then begin Boundary:=J; Break; end;
          Finish:=J;
          for I in Items do if FIR.Nodes[I].FirstToken=J then begin Finish:=FIR.Nodes[I].LastToken; Break; end;
          J:=Finish+1;
        end;
        ProtectedItems:=TList<Integer>.Create; HandlerItems:=TList<Integer>.Create;
        try
          for I in Items do if (Boundary>=0) and (FIR.Nodes[I].FirstToken>Boundary) then HandlerItems.Add(I) else ProtectedItems.Add(I);
          if (Boundary>=0) and SameText(FTokens[Boundary].Text,'finally') then
          begin
            // Separate copies preserve the pending transfer through the finalizer.
            Finish:=Sequence(HandlerItems.ToArray,ANext,AReturn,AException,ABreak,AContinue);
            ReturnVia:=Sequence(HandlerItems.ToArray,AReturn,AReturn,AException,ABreak,AContinue);
            ExceptionVia:=Sequence(HandlerItems.ToArray,AException,AReturn,AException,ABreak,AContinue);
            BreakVia:=Sequence(HandlerItems.ToArray,ABreak,AReturn,AException,ABreak,AContinue);
            ContinueVia:=Sequence(HandlerItems.ToArray,AContinue,AReturn,AException,ABreak,AContinue);
            Start:=Sequence(ProtectedItems.ToArray,Finish,ReturnVia,ExceptionVia,BreakVia,ContinueVia);
          end
          else
          begin
            Handler:=Node('exception_dispatch','handler type matching is conservative',N.Location);
            // Typed handlers are alternatives, never a proved sequential execution.
            for I in HandlerItems do Edge(Handler,Statement(I,ANext,AReturn,AException,ABreak,AContinue),'possible_handler','possible_dynamic');
            Edge(Handler,AException,'possibly_unhandled','possible_dynamic');
            Start:=Sequence(ProtectedItems.ToArray,ANext,AReturn,Handler,ABreak,AContinue);
          end;
          Edge(Result,Start,'enter_try');
        finally HandlerItems.Free; ProtectedItems.Free; end;
      end
      else if Kind='exit' then begin Edge(Result,AReturn,'return'); Edge(Result,AException,'return_expression_may_raise','possible_dynamic'); end
      else if Kind='raise' then Edge(Result,AException,'raise')
      else if (Kind='break') and (ABreak>=0) then Edge(Result,ABreak,'break')
      else if (Kind='continue') and (AContinue>=0) then Edge(Result,AContinue,'continue')
      else if MatchText(Kind,['case','goto','asm','opaque','with']) then
      begin
        FGraph.Complete:=False;
        FGraph.Diagnostics.Report('CFG_CONSERVATIVE_CONSTRUCT','Control flow alternatives require conservative interpretation: '+Kind,N.Location);
        for I in Items do Edge(Result,Statement(I,ANext,AReturn,AException,ABreak,AContinue),'possible_branch','possible_dynamic');
        Edge(Result,ANext,'possible_fallthrough','possible_dynamic'); Edge(Result,AException,'may_raise','possible_dynamic');
      end
      else begin Edge(Result,ANext,'next'); Edge(Result,AException,'may_raise','possible_dynamic'); end;
    finally Items.Free; end;
  finally Dec(FDepth); end;
end;
procedure TDPHFlowBuilder.Build(AGraph: TDPHSemanticGraph; ARoutine: Integer; AIR: TDPHParseResult;
  const ATokens: TDPHTokens; ABody: Integer);
var I,Entry,NormalExit,ExceptionExit,Start: Integer; Children: TList<Integer>;
begin
  FGraph:=AGraph; FRoutine:=ARoutine; FIR:=AIR; FTokens:=ATokens; FDepth:=0;
  FChildren:=TObjectDictionary<Integer,TList<Integer>>.Create([doOwnsValues]);
  try
    for I:=0 to AIR.Nodes.Count-1 do
    begin
      if not FChildren.TryGetValue(AIR.Nodes[I].Parent,Children) then
      begin Children:=TList<Integer>.Create; FChildren.Add(AIR.Nodes[I].Parent,Children); end;
      Children.Add(I);
    end;
    Entry:=Node('entry','',AIR.Nodes[ABody].Location);
    NormalExit:=Node('normal_exit','',AIR.Nodes[ABody].Location);
    ExceptionExit:=Node('exception_exit','',AIR.Nodes[ABody].Location);
    Start:=Statement(ABody,NormalExit,NormalExit,ExceptionExit,-1,-1); Edge(Entry,Start,'enter');
  finally FChildren.Free; end;
end;
end.
