unit DPH.Analysis.SQL;
interface
uses DPH.Analysis.Model, DPH.Project.Analysis;
type
  TDPHSQLAnalysis = class
  public
    class procedure Enrich(AScan: TDPHScan; AGraph: TDPHSemanticGraph); static;
  end;
implementation
uses System.SysUtils, System.StrUtils, System.Generics.Collections, DPH.Parse.Model;

class procedure TDPHSQLAnalysis.Enrich(AScan: TDPHScan; AGraph: TDPHSemanticGraph);
var Words,Columns: TList<string>; R: TDPHRelation; S: TDPHSymbol;
    OriginalCount,I,J,Position,Start,Statement,TableIndex,ColumnIndex,Ordinal,TableAt: Integer;
    SQL,WordText,TableName,AccessKind: string; Valid,Quoted: Boolean;
    Ordinals: TDictionary<Integer,Integer>;
  function Identifier(const Text: string): Boolean;
  var C: Char;
  begin
    Result:=Text<>''; if not Result then Exit;
    if not CharInSet(Text[1],['A'..'Z','a'..'z','_']) then Exit(False);
    for C in Text do if not CharInSet(C,['A'..'Z','a'..'z','0'..'9','_','$','.']) then Exit(False);
  end;
  function AddSymbol(const Name,Kind: string; Owner: Integer): Integer;
  var Symbol: TDPHSymbol; Key: string;
  begin
    Key:=LowerCase(AGraph.Symbols[Owner].QualifiedName+'.'+Name+'|'+Kind+'|'+AGraph.Configuration);
    Result:=AGraph.SymbolIndex(Key); if Result>=0 then Exit;
    if AGraph.Symbols.Count>=50000 then raise ERangeError.Create('SQL symbol limit');
    Symbol:=TDPHSymbol.Create; Symbol.Index:=AGraph.Symbols.Count; Symbol.Owner:=Owner;
    Symbol.Name:=Name; Symbol.Kind:=Kind; Symbol.QualifiedName:=AGraph.Symbols[Owner].QualifiedName+'.'+Name;
    Symbol.Key:=Key;
    Symbol.Variant:=AGraph.Configuration; Symbol.UnitName:=AGraph.Symbols[R.FromSymbol].UnitName;
    Symbol.Location:=R.Location; Symbol.Occurrences.Add(R.Location); AGraph.SourceHashes.TryGetValue(R.Location.Source,Symbol.SourceHash);
    Symbol.Dispatch:='inferred'; Result:=AGraph.Symbols.Add(Symbol);
    AGraph.AddRelation(Owner,Result,'owns','confirmed_static','lexical_sql_reference_not_live_schema',Name,R.Location,R.Condition);
  end;
begin
  Words:=TList<string>.Create; Columns:=TList<string>.Create; Ordinals:=TDictionary<Integer,Integer>.Create;
  try
    for S in AGraph.Symbols do if (S.Kind='resource') and SameText(ExtractFileExt(S.Location.Source),'.sql') and
      AScan.Inventory.Sources.ContainsKey(S.Location.Source) then
      AGraph.AddRelation(S.Index,-1,'static_sql','inferred','captured_sql_file_not_execution_proof',AScan.Inventory.Sources[S.Location.Source].Text,S.Location,'');
    OriginalCount:=AGraph.Relations.Count;
    for I:=0 to OriginalCount-1 do begin
      R:=AGraph.Relations[I]; if R.Kind<>'static_sql' then Continue;
      SQL:=R.LabelText;
      if R.Rule='literal_argument_to_execsql_spelling_api_unverified' then
        SQL:=Copy(SQL,2,Length(SQL)-2).Replace('''''','''');
      if not Ordinals.TryGetValue(R.FromSymbol,Ordinal) then Ordinal:=0; Inc(Ordinal); Ordinals.AddOrSetValue(R.FromSymbol,Ordinal);
      Statement:=AddSymbol('$sql'+IntToStr(Ordinal),'sql_statement',R.FromSymbol);
      S:=AGraph.Symbols[Statement]; S.Signature:=SQL; S.TypeName:='Static SQL text; dialect and schema unverified';
      AGraph.AddRelation(R.FromSymbol,Statement,'configures','inferred','static_sql_text_not_execution_proof',SQL,R.Location,R.Condition);
      if R.ToSymbol>=0 then AGraph.AddRelation(Statement,R.ToSymbol,'configures','inferred','sql_receiver_declaration_api_and_connection_unverified',AGraph.Symbols[R.ToSymbol].QualifiedName,R.Location,R.Condition);
      Words.Clear; Columns.Clear; Position:=1; Valid:=True;
      while Position<=Length(SQL) do begin
        if SQL[Position]<=' ' then begin Inc(Position); Continue; end;
        if SQL[Position]='''' then begin
          Inc(Position); Quoted:=False;
          while Position<=Length(SQL) do begin
            if SQL[Position]='''' then begin Inc(Position); if (Position<=Length(SQL)) and (SQL[Position]='''') then Inc(Position) else begin Quoted:=True; Break; end; end
            else Inc(Position);
          end;
          if not Quoted then Valid:=False; Words.Add('#literal'); Continue;
        end;
        Start:=Position;
        if CharInSet(SQL[Position],['A'..'Z','a'..'z','_','0'..'9']) then begin
          repeat Inc(Position) until (Position>Length(SQL)) or not CharInSet(SQL[Position],['A'..'Z','a'..'z','_','0'..'9','$','.']);
          Words.Add(Copy(SQL,Start,Position-Start));
        end else begin Words.Add(SQL[Position]); Inc(Position); end;
        if Words.Count>4096 then begin Valid:=False; Break; end;
      end;
      TableAt:=-1; AccessKind:='reads';
      if Words.Count>=4 then begin
        if SameText(Words[0],'SELECT') then begin
          J:=1;
          while (J<Words.Count) and not SameText(Words[J],'FROM') do begin
            if (J mod 2=1) and Identifier(Words[J]) then Columns.Add(Words[J])
            else if (J mod 2=0) and (Words[J]=',') then begin end else Valid:=False;
            Inc(J);
          end;
          if (Columns.Count=0) or (J>=Words.Count) or (J mod 2<>0) then Valid:=False else TableAt:=J+1;
        end else if SameText(Words[0],'UPDATE') and SameText(Words[2],'SET') then begin
          TableAt:=1; AccessKind:='writes'; J:=3;
          while J<Words.Count do begin
            if SameText(Words[J],'WHERE') or (Words[J]=';') then Break;
            if (J+2>=Words.Count) or not Identifier(Words[J]) or (Words[J+1]<>'=') then begin Valid:=False; Break; end;
            Columns.Add(Words[J]); Inc(J,3);
            if (J<Words.Count) and (Words[J]=',') then Inc(J) else Break;
          end;
        end else if SameText(Words[0],'INSERT') and SameText(Words[1],'INTO') then begin
          TableAt:=2; AccessKind:='writes'; J:=3;
          if (J>=Words.Count) or (Words[J]<>'(') then Valid:=False else begin
            Inc(J);
            while (J<Words.Count) and (Words[J]<>')') do begin
              if not Identifier(Words[J]) then begin Valid:=False; Break; end;
              Columns.Add(Words[J]); Inc(J);
              if (J<Words.Count) and (Words[J]=',') then Inc(J) else Break;
            end;
            if (J>=Words.Count) or (Words[J]<>')') or (J+1>=Words.Count) or not SameText(Words[J+1],'VALUES') then Valid:=False;
          end;
        end else if SameText(Words[0],'DELETE') and SameText(Words[1],'FROM') then begin TableAt:=2; AccessKind:='writes'; end
        else Valid:=False;
      end else Valid:=False;
      // Reject joins, aliases, nested queries, quoted identifiers and batches.
      if (TableAt<0) or (TableAt>=Words.Count) then Valid:=False
      else if not Identifier(Words[TableAt]) then Valid:=False;
      for J:=0 to Words.Count-1 do begin
        if MatchText(Words[J],['JOIN','UNION','WITH','RETURNING','MERGE','AS','"','[',']','`','-','/']) then Valid:=False;
        if (J>0) and MatchText(Words[J],['SELECT','INSERT','UPDATE','DELETE','FROM','INTO']) and (J<>TableAt-1) then Valid:=False;
        if (Words[J]=';') and (J<>Words.Count-1) then Valid:=False;
      end;
      if Valid and SameText(Words[0],'SELECT') and (TableAt+1<Words.Count) and
        not MatchText(Words[TableAt+1],['WHERE','ORDER','GROUP','HAVING','LIMIT',';']) then Valid:=False;
      if Valid and SameText(Words[0],'DELETE') and (TableAt+1<Words.Count) and
        not MatchText(Words[TableAt+1],['WHERE',';']) then Valid:=False;
      if not Valid then begin
        AGraph.Complete:=False; AGraph.Diagnostics.Report('SQL_SCHEMA_PARTIAL','SQL text retained; table/column inference requires a supported unambiguous single-table statement',R.Location); Continue;
      end;
      TableName:=Words[TableAt]; TableIndex:=AddSymbol(TableName,'sql_table',Statement);
      for J:=0 to Words.Count-1 do if MatchText(Words[J],['WHERE','ORDER','GROUP','HAVING']) then begin
        AGraph.Complete:=False; AGraph.Diagnostics.Report('SQL_EXPRESSION_PARTIAL','Explicit projection/assignment columns retained; predicate, grouping and ordering expressions require review',R.Location); Break;
      end;
      AGraph.AddRelation(Statement,TableIndex,AccessKind,'inferred','single_table_sql_text_schema_unverified',TableName,R.Location,R.Condition);
      for WordText in Columns do begin
        if WordText.Contains('.') then begin
          if not SameText(Copy(WordText,1,LastDelimiter('.',WordText)-1),TableName) then begin AGraph.Complete:=False; AGraph.Diagnostics.Report('SQL_COLUMN_PARTIAL','Qualified column does not match the sole table',R.Location); Continue; end;
        end;
        ColumnIndex:=AddSymbol(WordText,'sql_column',TableIndex);
        AGraph.AddRelation(Statement,ColumnIndex,AccessKind,'inferred','explicit_single_table_column_schema_unverified',WordText,R.Location,R.Condition);
      end;
    end;
  finally Ordinals.Free; Columns.Free; Words.Free; end;
end;
end.
