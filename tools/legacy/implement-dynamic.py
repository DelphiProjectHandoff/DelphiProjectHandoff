from pathlib import Path
r=Path.cwd();p=r/'DPH.Analysis.Symbols.pas';s=p.read_text(encoding='utf-8-sig')
a=s.index('procedure TDPHSemanticAnalyzer.VisualSites;');b=s.index('procedure TDPHSemanticAnalyzer.OutputSites;',a)
s=s[:a]+'''procedure TDPHSemanticAnalyzer.VisualSites;
var I,J,Count,Ordinal,Index,Target,EqualAt,Hits: Integer; R,P: TDPHRelation; S,Owner: TDPHSymbol;
    Ordinals: TDictionary<Integer,Integer>; CandidatesByRoutine: TObjectDictionary<Integer,TList<TDPHRelation>>;
    Items: TList<TDPHRelation>; Handles: TDictionary<string,Integer>; HandleKey,ExpressionText,PropertyName,Kind,Resolution: string;
    Matches: TArray<Integer>;
begin
  Ordinals:=TDictionary<Integer,Integer>.Create;
  CandidatesByRoutine:=TObjectDictionary<Integer,TList<TDPHRelation>>.Create([doOwnsValues]);
  Handles:=TDictionary<string,Integer>.Create;
  try
    Count:=FGraph.Relations.Count;
    for I:=0 to Count-1 do begin
      R:=FGraph.Relations[I];
      if MatchText(R.Kind,['control_owner_candidate','control_property_candidate']) then begin
        if not CandidatesByRoutine.TryGetValue(R.FromSymbol,Items) then begin Items:=TList<TDPHRelation>.Create; CandidatesByRoutine.Add(R.FromSymbol,Items); end;
        Items.Add(R);
      end;
      if (R.Kind='creates_control_candidate') and (R.ToSymbol>=0) then begin
        HandleKey:=IntToStr(R.FromSymbol)+'|'+IntToStr(R.ToSymbol); Hits:=0; Handles.TryGetValue(HandleKey,Hits); Handles.AddOrSetValue(HandleKey,Hits+1);
      end;
    end;
    for I:=0 to Count-1 do begin
      R:=FGraph.Relations[I]; if R.Kind<>'creates_control_candidate' then Continue;
      if not Ordinals.TryGetValue(R.FromSymbol,Ordinal) then Ordinal:=0; Inc(Ordinal); Ordinals.AddOrSetValue(R.FromSymbol,Ordinal);
      Owner:=FGraph.Symbols[R.FromSymbol]; S:=TDPHSymbol.Create; S.Kind:='dynamic_control'; S.Owner:=R.FromSymbol;
      S.Name:='$control'+IntToStr(Ordinal); S.QualifiedName:=Owner.QualifiedName+'.'+S.Name; S.UnitName:=Owner.UnitName;
      S.TypeName:=R.LabelText; S.Signature:=LowerCase(R.LabelText); S.Variant:=Owner.Variant; S.Location:=R.Location;
      S.SourceHash:=FGraph.SourceHashes[R.Location.Source]; S.Dispatch:='possible_dynamic'; Index:=AddSymbol(S);
      FGraph.AddRelation(R.FromSymbol,Index,'creates','inferred','recognized_visual_constructor_site_not_runtime_instance',R.LabelText,R.Location,R.Condition);
      if R.ToSymbol>=0 then FGraph.AddRelation(Index,R.ToSymbol,'assigned_to','inferred','lexical_control_handle_assignment_alias_state_unverified',FGraph.Symbols[R.ToSymbol].QualifiedName,R.Location,R.Condition);
      if CandidatesByRoutine.TryGetValue(R.FromSymbol,Items) then for P in Items do begin
        if (P.Kind='control_owner_candidate') and (P.Location.StartByte=R.Location.StartByte) then begin
          FGraph.AddRelation(Index,P.ToSymbol,'constructor_owner',P.Resolution,'constructor_argument_declaration_not_runtime_owner_instance',P.LabelText,P.Location,P.Condition); Continue;
        end;
        if (P.Kind<>'control_property_candidate') or (R.ToSymbol<0) or (P.ToSymbol<>R.ToSymbol) then Continue;
        HandleKey:=IntToStr(R.FromSymbol)+'|'+IntToStr(R.ToSymbol);
        if (Handles[HandleKey]<>1) or (P.Location.StartByte<R.Location.StartByte) then begin
          FGraph.AddRelation(Index,-1,'dynamic_assignment_ambiguous','unresolved','reused_handle_or_assignment_before_creation_not_attributed',P.LabelText,P.Location,P.Condition); Continue;
        end;
        EqualAt:=Pos(' := ',P.LabelText); PropertyName:=Copy(P.LabelText,1,EqualAt-1); ExpressionText:=Copy(P.LabelText,EqualAt+4,MaxInt);
        PropertyName:=Copy(PropertyName,LastDelimiter('.',PropertyName)+1,MaxInt);
        Kind:='dynamic_property'; Target:=-1; Resolution:='inferred';
        if SameText(PropertyName,'Parent') then begin Kind:='dynamic_parent'; Target:=ResolveValue(ExpressionText,R.FromSymbol); if Target<0 then Resolution:='unresolved'; end
        else if StartsText('On',PropertyName) then begin
          Kind:='dynamic_event'; Matches:=Candidates(ExpressionText.TrimLeft(['@']),R.FromSymbol); Target:=-1;
          if Length(Matches)=1 then Target:=Matches[0];
          Resolution:='unresolved'; if Target>=0 then Resolution:='inferred';
        end;
        if SameText(ExpressionText,'nil') then begin Target:=-1; Resolution:='inferred'; end;
        FGraph.AddRelation(Index,Target,Kind,Resolution,'same_routine_unique_handle_lexical_reference_not_reaching_definition_or_runtime_binding',P.LabelText,P.Location,P.Condition);
      end;
      FGraph.Complete:=False; FGraph.Diagnostics.Report('DYNAMIC_CONTROL_REVIEW','Creation site and lexical references retained; runtime instances, aliases, execution order and actual bindings remain unobserved',R.Location);
    end;
  finally Handles.Free; CandidatesByRoutine.Free; Ordinals.Free; end;
end;

'''+s[b:]
s=s.replace("FGraph.AddRelation(ARoutine,InputSymbol,'creates_control_candidate','inferred','visual_type_constructor_source_candidate',Copy(Path,1,Length(Path)-7),L,Tokens[I].Condition);", """FGraph.AddRelation(ARoutine,InputSymbol,'creates_control_candidate','inferred','visual_type_constructor_source_candidate',Copy(Path,1,Length(Path)-7),L,Tokens[I].Condition);
          Argument:='<omitted or unsupported>'; if Args.Count=1 then Argument:=Args[0];
          InputIndex:=ResolveValue(Argument,ARoutine); Resolution:='inferred';
          if (InputIndex<0) and not SameText(Argument,'nil') then Resolution:='unresolved';
          FGraph.AddRelation(ARoutine,InputIndex,'control_owner_candidate',Resolution,'constructor_argument_reference_not_runtime_value',Argument,L,Tokens[I].Condition);""")
s=s.replace("if (InputSymbol>=0) and IsVisualType(FGraph.Symbols[InputSymbol].TypeName,Routine.UnitName) then\n          FGraph.AddRelation(ARoutine,InputSymbol,'mutates_property','inferred','visual_receiver_property_assignment_runtime_layout_unverified',Path,L,Tokens[I].Condition);", """if (InputSymbol>=0) and IsVisualType(FGraph.Symbols[InputSymbol].TypeName,Routine.UnitName) then begin
          FGraph.AddRelation(ARoutine,InputSymbol,'mutates_property','inferred','visual_receiver_property_assignment_runtime_layout_unverified',Path,L,Tokens[I].Condition);
          Argument:=''; ExpressionEnd:=Stop+2; Depth:=0;
          while ExpressionEnd<=Body.LastToken do begin
            if (Depth=0) and MatchText(Tokens[ExpressionEnd].Text,[';','end','else','until']) then Break;
            if MatchText(Tokens[ExpressionEnd].Text,['(','[']) then Inc(Depth)
            else if MatchText(Tokens[ExpressionEnd].Text,[')',']']) then begin if Depth=0 then Break; Dec(Depth); end;
            Argument:=Argument+Tokens[ExpressionEnd].Text; Inc(ExpressionEnd);
          end;
          FGraph.AddRelation(ARoutine,InputSymbol,'control_property_candidate','inferred','captured_visual_assignment_expression_not_evaluated',Path+' := '+Argument,L,Tokens[I].Condition);
        end;""")
s=s.replace('I,J,Count,Ordinal,Index,Target,EqualAt,Hits: Integer','I,Count,Ordinal,Index,Target,EqualAt,Hits: Integer')
p.write_text(s,encoding='utf-8')
p=r/'DPH.Analysis.Model.pas';p.write_text(p.read_text(encoding='utf-8-sig').replace("DPH-WP3-11","DPH-WP3-12"),encoding='utf-8')
