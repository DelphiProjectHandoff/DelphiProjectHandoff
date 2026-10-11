unit DPH.Analysis.Async;
interface
uses DPH.Project.Analysis, DPH.Analysis.Model;
type
  TDPHAsyncAnalysis = class
  public
    class procedure Enrich(AScan: TDPHScan; AGraph: TDPHSemanticGraph); static;
  end;
implementation
uses System.SysUtils, System.StrUtils, System.Generics.Collections, DPH.Parse.Model;

class procedure TDPHAsyncAnalysis.Enrich(AScan: TDPHScan; AGraph: TDPHSemanticGraph);
var Sites: TDictionary<string,Integer>; Ordinals: TDictionary<Integer,Integer>;
    Handles: TObjectDictionary<Integer,TList<Integer>>; Operations: TList<Integer>;
    OriginalCount,I,J,Owner,Operation,Ordinal,VariableIndex,Scope,Found: Integer;
    Relation,Capture: TDPHRelation; Symbol,Parent: TDPHSymbol; Site,API,Context,Receiver,Action: string;
    IR: TDPHParseResult; Tokens: TDPHTokens; TokenIndex,Before,After,Depth,CallEnd: Integer; Started: Boolean;
  function NextCode(Index: Integer): Integer;
  begin
    Result:=Index;
    while (Result<Length(Tokens)) and ((Tokens[Result].Kind in [tkSpace,tkComment,tkDirective]) or (Tokens[Result].Active<>daActive)) do Inc(Result);
  end;
  function PreviousCode(Index: Integer): Integer;
  begin
    Result:=Index;
    while (Result>=0) and ((Tokens[Result].Kind in [tkSpace,tkComment,tkDirective]) or (Tokens[Result].Active<>daActive)) do Dec(Result);
  end;
  function VariableFor(ARoutine: Integer; const AName: string): Integer;
  var Candidate,Lexical,Match: Integer; Name: string;
  begin
    Name:=AName; if StartsText('Self.',Name) then Delete(Name,1,5);
    Lexical:=ARoutine;
    while Lexical>=0 do begin
      Match:=-1;
      for Candidate:=0 to AGraph.Symbols.Count-1 do
        if (AGraph.Symbols[Candidate].Owner=Lexical) and SameText(AGraph.Symbols[Candidate].Name,Name) and
          MatchText(AGraph.Symbols[Candidate].Kind,['local','parameter','variable','field','property']) then begin
          if Match>=0 then Exit(-1); Match:=Candidate;
        end;
      if Match>=0 then Exit(Match); Lexical:=AGraph.Symbols[Lexical].Owner;
    end;
    Match:=-1;
    for Candidate:=0 to AGraph.Symbols.Count-1 do
      if MatchText(AGraph.Symbols[Candidate].Kind,['field','property']) and
        SameText(AGraph.Symbols[Candidate].QualifiedName,AGraph.Symbols[ARoutine].UnitName+'.'+AGraph.Symbols[ARoutine].OwnerName+'.'+Name) then begin
        if Match>=0 then Exit(-1); Match:=Candidate;
      end;
    Result:=Match;
  end;
  procedure CallTokens;
  var SearchIndex: Integer;
  begin
    Tokens:=nil; TokenIndex:=-1; CallEnd:=-1;
    if not AScan.Results.TryGetValue(Relation.Location.Source,IR) then Exit;
    Tokens:=IR.Tokens;
    for SearchIndex:=0 to High(Tokens) do if (Tokens[SearchIndex].Location.Source=Relation.Location.Source) and
      (Tokens[SearchIndex].Location.StartByte=Relation.Location.StartByte) and (Tokens[SearchIndex].Active=daActive) then begin TokenIndex:=SearchIndex; Break; end;
    if TokenIndex<0 then Exit;
    After:=TokenIndex;
    while (After<Length(Tokens)) and (Tokens[After].Text<>'(') do Inc(After);
    if After>=Length(Tokens) then Exit; Depth:=0;
    repeat
      if Tokens[After].Text='(' then Inc(Depth) else if Tokens[After].Text=')' then Dec(Depth);
      Inc(After);
    until (After>=Length(Tokens)) or (Depth=0);
    if Depth=0 then CallEnd:=After-1;
  end;
begin
  Sites:=TDictionary<string,Integer>.Create; Ordinals:=TDictionary<Integer,Integer>.Create;
  Handles:=TObjectDictionary<Integer,TList<Integer>>.Create([doOwnsValues]);
  try
    OriginalCount:=AGraph.Relations.Count;
    for I:=0 to OriginalCount-1 do begin
      Relation:=AGraph.Relations[I]; API:=Relation.LabelText;
      if (Relation.Kind<>'schedules') or (Relation.ToSymbol<0) or
        not MatchText(API,['TThread.CreateAnonymousThread','TThread.Queue','TThread.ForceQueue','TThread.Synchronize','TTask.Run']) then Continue;
      Owner:=Relation.FromSymbol; Parent:=AGraph.Symbols[Owner];
      Site:=IntToStr(Owner)+'|'+API+'|'+Relation.Location.Source+'|'+IntToStr(Relation.Location.StartByte);
      if not Sites.TryGetValue(Site,Operation) then begin
        if AGraph.Symbols.Count>=50000 then raise ERangeError.Create('Asynchronous symbol limit');
        if not Ordinals.TryGetValue(Owner,Ordinal) then Ordinal:=0; Inc(Ordinal); Ordinals.AddOrSetValue(Owner,Ordinal);
        Symbol:=TDPHSymbol.Create; Symbol.Index:=AGraph.Symbols.Count; Symbol.Owner:=Owner; Symbol.Name:='$async'+IntToStr(Ordinal);
        Symbol.QualifiedName:=Parent.QualifiedName+'.'+Symbol.Name; Symbol.Kind:='async_operation'; Symbol.Variant:=Parent.Variant;
        Symbol.Location:=Relation.Location; Symbol.Occurrences.Add(Relation.Location); Symbol.SourceHash:=AGraph.SourceHashes[Relation.Location.Source]; Symbol.UnitName:=Parent.UnitName;
        Symbol.Signature:=LowerCase(API); Symbol.Key:=LowerCase(Symbol.QualifiedName+'|async_operation|'+Symbol.Signature+'|'+Symbol.Variant);
        Symbol.Dispatch:='possible_dynamic'; Context:='worker thread';
        if MatchText(API,['TThread.Queue','TThread.ForceQueue','TThread.Synchronize']) then Context:='main thread dispatch';
        if SameText(API,'TTask.Run') then Context:='task scheduler'; Symbol.TypeName:=Context;
        Operation:=AGraph.Symbols.Add(Symbol); Sites.Add(Site,Operation);
        AGraph.AddRelation(Owner,Operation,'owns','confirmed_static','lexical_async_site_not_runtime_object_owner',API,Relation.Location,Relation.Condition);
        AGraph.AddRelation(Owner,Operation,'creates','inferred','recognized_async_api_spelling',API,Relation.Location,Relation.Condition);
        CallTokens; Started:=not SameText(API,'TThread.CreateAnonymousThread');
        if (CallEnd>=0) and SameText(API,'TThread.CreateAnonymousThread') then begin
          After:=NextCode(CallEnd+1);
          if (After<Length(Tokens)) and (Tokens[After].Text='.') then begin After:=NextCode(After+1); Started:=(After<Length(Tokens)) and SameText(Tokens[After].Text,'Start'); end;
        end;
        if Started then AGraph.AddRelation(Owner,Operation,'starts','possible_dynamic','recognized_async_dispatch_not_runtime_order',Context,Relation.Location,Relation.Condition);
        if (TokenIndex>=0) and SameText(API,'TThread.CreateAnonymousThread') then begin
          Before:=PreviousCode(TokenIndex-1);
          if (Before>=0) and (Tokens[Before].Text=':=') then begin
            Before:=PreviousCode(Before-1); if Before>=0 then begin
              VariableIndex:=VariableFor(Owner,Tokens[Before].Text);
              if VariableIndex>=0 then begin
                if not Handles.TryGetValue(VariableIndex,Operations) then begin Operations:=TList<Integer>.Create; Handles.Add(VariableIndex,Operations); end;
                Operations.Add(Operation); AGraph.AddRelation(Operation,VariableIndex,'assigned_to','inferred','lexical_assignment_not_runtime_alias_proof',Tokens[Before].Text,Relation.Location,Relation.Condition);
              end;
            end;
          end;
        end;
        if SameText(API,'TThread.Synchronize') then AGraph.AddRelation(Owner,Operation,'waits_for','inferred','synchronize_api_spelling_normal_return_only','Callback completion before normal return; runtime context unverified',Relation.Location,Relation.Condition);
        AGraph.Complete:=False;
        AGraph.Diagnostics.Report('ASYNC_LIFETIME_REVIEW',API+': review captured object lifetimes, thread affinity, errors and completion; lexical ownership does not prove runtime ownership',Relation.Location);
      end;
      AGraph.AddRelation(Operation,Relation.ToSymbol,'dispatches','possible_dynamic','callback_attached_to_recognized_async_site',API,Relation.Location,Relation.Condition);
      if SameText(API,'TThread.CreateAnonymousThread') then begin
        Started:=False; for J:=OriginalCount to AGraph.Relations.Count-1 do if (AGraph.Relations[J].FromSymbol=Owner) and
          (AGraph.Relations[J].ToSymbol=Operation) and (AGraph.Relations[J].Kind='starts') then Started:=True;
        if not Started then begin Relation.Kind:='prepares_callback'; Relation.Rule:='thread_created_start_not_proven'; AGraph.Relations[I]:=Relation; end;
      end;
      for J:=0 to OriginalCount-1 do begin Capture:=AGraph.Relations[J];
        if (Capture.FromSymbol<>Relation.ToSymbol) or (Capture.ToSymbol<0) or not MatchText(Capture.Kind,['reads','writes']) then Continue;
        Symbol:=AGraph.Symbols[Capture.ToSymbol]; Scope:=AGraph.Symbols[Relation.ToSymbol].Owner; Found:=-1;
        while Scope>=0 do begin if Scope=Symbol.Owner then begin Found:=Scope; Break; end; Scope:=AGraph.Symbols[Scope].Owner; end;
        if (Found>=0) and MatchText(Symbol.Kind,['local','parameter','field','property']) then
          AGraph.AddRelation(Relation.ToSymbol,Capture.ToSymbol,'captures','inferred','lexical_reference_not_object_lifetime_proof',Symbol.QualifiedName,Capture.Location,Capture.Condition);
      end;
    end;
    for I:=0 to OriginalCount-1 do begin
      Relation:=AGraph.Relations[I]; if Relation.Kind<>'calls' then Continue; API:=Relation.LabelText;
      J:=LastDelimiter('.',API); if J=0 then Continue; Receiver:=Copy(API,1,J-1); Action:=Copy(API,J+1,MaxInt);
      if not MatchText(Action,['Start','WaitFor','Terminate','SetEvent']) then Continue;
      VariableIndex:=VariableFor(Relation.FromSymbol,Receiver); if VariableIndex<0 then Continue;
      if MatchText(Action,['Start','WaitFor','Terminate']) and Handles.TryGetValue(VariableIndex,Operations) then for Operation in Operations do begin
        if (AGraph.Symbols[Operation].Owner<>Relation.FromSymbol) or
          (AGraph.Symbols[Operation].Location.Source<>Relation.Location.Source) or
          (AGraph.Symbols[Operation].Location.StartByte>=Relation.Location.StartByte) then Continue;
        Context:='starts'; if SameText(Action,'WaitFor') then Context:='waits_for'; if SameText(Action,'Terminate') then Context:='requests_cancellation';
        AGraph.AddRelation(Relation.FromSymbol,Operation,Context,'possible_dynamic','recognized_thread_handle_action_aliases_unverified',API,Relation.Location,Relation.Condition);
        if SameText(Action,'WaitFor') then AGraph.Diagnostics.Report('ASYNC_WAIT_REVIEW','Check blocking context, callback queues and error paths for '+API,Relation.Location);
      end;
      Symbol:=AGraph.Symbols[VariableIndex];
      if SameText(Symbol.TypeName,'TEvent') or EndsText('.TEvent',Symbol.TypeName) then begin
        Context:='signals'; if SameText(Action,'WaitFor') then Context:='waits_for_signal';
        if MatchText(Action,['SetEvent','WaitFor']) then AGraph.AddRelation(Relation.FromSymbol,VariableIndex,Context,'inferred','event_api_spelling_reset_and_alias_state_unverified',API,Relation.Location,Relation.Condition);
      end;
    end;
  finally Handles.Free; Ordinals.Free; Sites.Free; end;
end;
end.
