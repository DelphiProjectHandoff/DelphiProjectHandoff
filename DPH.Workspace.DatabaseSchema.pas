unit DPH.Workspace.DatabaseSchema;
interface
uses System.JSON,DPH.Workspace.Model;
type TDPHDatabaseSchema=class
 class function Inspect(AView:TDPHWorkspaceView):TJSONObject;static;
 class function Describe(ARow:TJSONObject):string;static;
end;
implementation
uses System.SysUtils,System.StrUtils,System.Classes,System.Generics.Collections;
type TSchemaToken=record Text,Body:string;Line:Integer;Identifier:Boolean;end;
class function TDPHDatabaseSchema.Inspect(AView:TDPHWorkspaceView):TJSONObject;
var Rows,Nodes:TJSONArray;FileValue,NodeValue,Value:TJSONValue;FileRow,Node,Row:TJSONObject;
 Tokens:TList<TSchemaToken>;Counts:TDictionary<string,Integer>;ReferenceNames:TDictionary<string,string>;Token:TSchemaToken;
 SQL,Path,Text,Name,SchemaName,Kind,Status,Issue,Definition,Key:string;
 Position,Start,Line,Depth,I,J,First,Last,NameAt,BodyAt,Count,Ordinal,StoredDependencies:Integer;
 C,Closing:Char;Closed,Valid,Quoted,ReplaceHeader,TemporaryHeader,IfHeader:Boolean;
 procedure AddRow(const AKind,AName,ASchema,AStatus,AReason,ADefinition:string;ALine:Integer;ARange:TJSONObject);
 var Range:TJSONObject;
 begin
  if Rows.Count>=10000 then raise ERangeError.Create('Schema inventory exceeds 10000 rows; narrow the captured project');
  Row:=TJSONObject.Create;Rows.AddElement(Row);Inc(Ordinal);
  Row.AddPair('id',Path+'|'+IntToStr(Ordinal)).AddPair('kind',AKind).AddPair('name',AName).AddPair('schema',ASchema).AddPair('status',AStatus).AddPair('reason',AReason).AddPair('definition',ADefinition);
  Row.AddPair('source',Path).AddPair('source_hash',FileRow.GetValue<string>('sha256','')).AddPair('generation_id',AView.Document.GetValue('generation_id').Clone as TJSONValue);
  Range:=TJSONObject.Create.AddPair('source',Path).AddPair('start',ARange.GetValue('start').Clone as TJSONValue).AddPair('end',ARange.GetValue('end').Clone as TJSONValue).AddPair('line',TJSONNumber.Create(ALine)).AddPair('column',TJSONNumber.Create(1));
  Row.AddPair('range',Range).AddPair('range_precision','Byte extent covers the captured SQL resource; line identifies the statement start. Inferred references retain their captured semantic range.');
  Row.AddPair('definition_count',TJSONNumber.Create(0));
 end;
 procedure Tokenize(const SQL:string;BaseLine:Integer;ATokens:TList<TSchemaToken>;out Issue:string);
 var Position,Start,Line,Depth,J,ClosingAt:Integer;C,Closing:Char;Closed,Quoted:Boolean;Token:TSchemaToken;Delimiter:string;
 begin
  ATokens.Clear;Position:=1;Line:=BaseLine;Issue:='';
  if Length(SQL)>2*1024*1024 then Issue:='SQL resource exceeds 2 MiB character inspection limit';
     while (Position<=Length(SQL)) and (Issue='') do begin
      C:=SQL[Position];if C<=#32 then begin if C=#10 then Inc(Line);Inc(Position);Continue;end;
      if (C='-') and (Position<Length(SQL)) and (SQL[Position+1]='-') then begin
       while (Position<=Length(SQL)) and (SQL[Position]<>#10) do Inc(Position);Continue;
      end;
      if (C='/') and (Position<Length(SQL)) and (SQL[Position+1]='*') then begin
       Inc(Position,2);Depth:=1;
       while (Position<=Length(SQL)) and (Depth>0) do begin
        if SQL[Position]=#10 then Inc(Line);
        if (Position<Length(SQL)) and (Copy(SQL,Position,2)='/*') then begin Inc(Depth);Inc(Position,2);if Depth>16 then begin Issue:='Comment nesting exceeds 16';Break;end;end
        else if (Position<Length(SQL)) and (Copy(SQL,Position,2)='*/') then begin Dec(Depth);Inc(Position,2);end else Inc(Position);
       end;
       if Depth>0 then Issue:='Unterminated or unsupported block comment';Continue;
      end;
      Token:=Default(TSchemaToken);Token.Line:=Line;Start:=Position;
      if C='$' then begin
       J:=Position+1;while (J<=Length(SQL)) and CharInSet(SQL[J],['A'..'Z','a'..'z','0'..'9','_']) do Inc(J);
       if (J<=Length(SQL)) and (SQL[J]='$') and ((J=Position+1) or not CharInSet(SQL[Position+1],['0'..'9'])) then begin
        Delimiter:=Copy(SQL,Position,J-Position+1);Position:=J+1;Start:=Position;ClosingAt:=PosEx(Delimiter,SQL,Position);
        if ClosingAt=0 then begin Issue:='Unterminated dollar-quoted body';Break;end;
        Token.Text:='[literal omitted]';Token.Body:=Copy(SQL,Start,ClosingAt-Start);
        while Position<ClosingAt do begin if SQL[Position]=#10 then Inc(Line);Inc(Position);end;Inc(Position,Length(Delimiter));
        ATokens.Add(Token);if ATokens.Count>100000 then Issue:='SQL resource exceeds 100000-token limit';Continue;
       end;
      end;
      if CharInSet(C,['''','"','[','`']) then begin
       Quoted:=C<>'''';Closing:=C;if C='[' then Closing:=']';Inc(Position);Closed:=False;
       while Position<=Length(SQL) do begin
        if SQL[Position]=#10 then Inc(Line);
        if SQL[Position]=Closing then begin Inc(Position);if (Position<=Length(SQL)) and (SQL[Position]=Closing) then Inc(Position) else begin Closed:=True;Break;end;end else Inc(Position);
       end;
       if not Closed then begin Issue:='Unterminated string or quoted identifier';Break;end;
       Token.Identifier:=Quoted and (Position-Start>2);if Quoted then Token.Text:=Copy(SQL,Start,Position-Start) else begin Token.Text:='[literal omitted]';Token.Body:=StringReplace(Copy(SQL,Start+1,Position-Start-2),'''''','''',[rfReplaceAll]);end;
      end else if CharInSet(C,['0'..'9']) then begin
       Inc(Position);while (Position<=Length(SQL)) and CharInSet(SQL[Position],['0'..'9']) do Inc(Position);Token.Text:=Copy(SQL,Start,Position-Start);
      end else if CharInSet(C,['A'..'Z','a'..'z','_']) then begin
       Inc(Position);while (Position<=Length(SQL)) and CharInSet(SQL[Position],['A'..'Z','a'..'z','0'..'9','_','$']) do Inc(Position);
       Token.Text:=Copy(SQL,Start,Position-Start);Token.Identifier:=True;
      end else begin Token.Text:=C;Inc(Position);end;
      ATokens.Add(Token);if ATokens.Count>100000 then Issue:='SQL resource exceeds 100000-token limit';
     end;
 end;
 procedure InspectColumns(ABody,ALast:Integer;const ATable,ASchema,ADeclaration:string;ARange:TJSONObject);
 var EntryFirst,EntryLast,Cursor,TypeFirst,TypeLast,ClauseFirst,ExpressionFirst,ExpressionLast,Nesting,Part,Number:Integer;
     ColumnName,DeclaredType,Nullability,DefaultText,ConstraintText,Problem,ColumnDefinition:string;SawNull,SawNotNull,SawDefault:Boolean;
     ColumnRow:TJSONObject;KeySpans:TArray<TPair<Integer,Integer>>;KeySpan:TPair<Integer,Integer>;KeyAt:Integer;
  function Span(AFirst,AEnd:Integer):string;
  var Index:Integer;
  begin
   Result:='';for Index:=AFirst to AEnd-1 do begin
    if Length(Result)>8000 then Exit(Result+' [display truncated]');
    if (Result<>'') and not MatchText(Tokens[Index].Text,['.','(',')',',','[]']) and not MatchText(Tokens[Index-1].Text,['.','(']) and not ((Index=AFirst+1) and MatchText(Tokens[AFirst].Text,['+','-'])) then Result:=Result+' ';
    Result:=Result+Tokens[Index].Text;
   end;
  end;
  procedure Parentheses;
  var Balance:Integer;
  begin
   Balance:=0;
   if (Cursor>=EntryLast) or (Tokens[Cursor].Text<>'(') then begin Problem:='Expected parenthesized expression';Exit;end;
   repeat
    if Tokens[Cursor].Text='(' then Inc(Balance) else if Tokens[Cursor].Text=')' then Dec(Balance);
    Inc(Cursor);
   until (Cursor>=EntryLast) or (Balance=0);
   if Balance<>0 then Problem:='Incomplete parenthesized expression';
  end;
  procedure InspectKey(AFirst,AEnd:Integer;const AColumn:string);
  var P,N:Integer;KeyKind,ConstraintName,Target,ErrorText,Action,ActionKind:string;
      Members,References:TJSONArray;Seen:TDictionary<string,Boolean>;
   procedure Names(AList:TJSONArray);
   begin
    Seen.Clear;
    if (P>=AEnd) or (Tokens[P].Text<>'(') then begin ErrorText:='Expected key column list';Exit;end;Inc(P);
    repeat
     if (P>=AEnd) or not Tokens[P].Identifier then begin ErrorText:='Missing key column identifier';Exit;end;
     if Seen.ContainsKey(Tokens[P].Text) then begin ErrorText:='Repeated key column identifier';Exit;end;
     Seen.Add(Tokens[P].Text,True);AList.Add(Tokens[P].Text);Inc(P);
     if (P<AEnd) and (Tokens[P].Text=',') then Inc(P) else Break;
    until False;
    if (P>=AEnd) or (Tokens[P].Text<>')') then ErrorText:='Incomplete or unsupported key column list' else Inc(P);
   end;
  begin
   P:=AFirst;ConstraintName:='';KeyKind:='';Target:='';ErrorText:='';Action:='';
   Members:=TJSONArray.Create;References:=TJSONArray.Create;Seen:=TDictionary<string,Boolean>.Create;
   try
    if (P<AEnd) and SameText(Tokens[P].Text,'CONSTRAINT') then begin Inc(P);if (P<AEnd) and Tokens[P].Identifier then begin ConstraintName:=Tokens[P].Text;Inc(P);end else ErrorText:='Missing constraint name';end;
    if P>=AEnd then Exit;
    if SameText(Tokens[P].Text,'PRIMARY') then begin KeyKind:='primary';Inc(P);if (P<AEnd) and SameText(Tokens[P].Text,'KEY') then Inc(P) else ErrorText:='Expected PRIMARY KEY';end
    else if SameText(Tokens[P].Text,'UNIQUE') then begin KeyKind:='unique';Inc(P);end
    else if SameText(Tokens[P].Text,'FOREIGN') then begin KeyKind:='foreign';Inc(P);if (P<AEnd) and SameText(Tokens[P].Text,'KEY') then Inc(P) else ErrorText:='Expected FOREIGN KEY';end
    else if SameText(Tokens[P].Text,'REFERENCES') and (AColumn<>'') then KeyKind:='foreign'
    else Exit;
    if ErrorText='' then begin if AColumn<>'' then Members.Add(AColumn) else Names(Members);end;
    if (KeyKind='foreign') and (ErrorText='') then begin
     if (P>=AEnd) or not SameText(Tokens[P].Text,'REFERENCES') then ErrorText:='Expected REFERENCES' else begin
      Inc(P);N:=0;
      repeat
       if (P>=AEnd) or not Tokens[P].Identifier then begin ErrorText:='Missing referenced table identifier';Break;end;
       if Target<>'' then Target:=Target+'.';Target:=Target+Tokens[P].Text;Inc(P);Inc(N);
       if (P<AEnd) and (Tokens[P].Text='.') then Inc(P) else Break;
      until False;
      if N>3 then ErrorText:='Referenced table has more than three name parts';
      if (ErrorText='') and (P<AEnd) and (Tokens[P].Text='(') then Names(References);
     end;
     while (ErrorText='') and (P<AEnd) and SameText(Tokens[P].Text,'ON') do begin
      Inc(P);if (P>=AEnd) or not MatchText(Tokens[P].Text,['DELETE','UPDATE']) then begin ErrorText:='Unsupported referential action';Break;end;
      ActionKind:=UpperCase(Tokens[P].Text);if ContainsText(Action,'ON '+ActionKind+' ') then begin ErrorText:='Repeated referential action';Break;end;
      Action:=Action+'ON '+ActionKind+' ';Inc(P);
      if (P<AEnd) and MatchText(Tokens[P].Text,['CASCADE','RESTRICT']) then begin Action:=Action+UpperCase(Tokens[P].Text)+'; ';Inc(P);end
      else if (P+1<AEnd) and ((SameText(Tokens[P].Text,'NO') and SameText(Tokens[P+1].Text,'ACTION')) or (SameText(Tokens[P].Text,'SET') and MatchText(Tokens[P+1].Text,['NULL','DEFAULT']))) then begin Action:=Action+UpperCase(Tokens[P].Text+' '+Tokens[P+1].Text)+'; ';Inc(P,2);end
      else ErrorText:='Unsupported referential action';
     end;
    end;
    if (ErrorText='') and (P<>AEnd) then ErrorText:='Unsupported key clause tail: '+Tokens[P].Text;
    if ErrorText<>'' then begin AddRow('gap',ATable+' | key at line '+IntToStr(Tokens[AFirst].Line),ASchema,'unsupported','Key extraction gap: '+ErrorText+'. No structured key promoted.',Span(AFirst,AEnd),Tokens[AFirst].Line,ARange);Row.AddPair('table',ATable).AddPair('declaration_id',ADeclaration);Exit;end;
    if ConstraintName='' then ConstraintName:='anonymous '+KeyKind+' at line '+IntToStr(Tokens[AFirst].Line)+' token '+IntToStr(AFirst);
    AddRow('key',ATable+' | '+ConstraintName,ASchema,'declared key','Captured key declaration; relationships use exact spelling and unique captured ownership. Dialect validity, target eligibility, migration order and enforcement remain unverified.',Span(AFirst,AEnd),Tokens[AFirst].Line,ARange);
    Row.AddPair('table',ATable).AddPair('declaration_id',ADeclaration).AddPair('constraint_name',ConstraintName).AddPair('key_kind',KeyKind).AddPair('members',Members).AddPair('reference_table',Target).AddPair('reference_columns',References).AddPair('referential_actions',Action);
    Members:=nil;References:=nil;
   finally Seen.Free;Members.Free;References.Free;end;
  end;
 begin
  EntryFirst:=ABody+1;
  while EntryFirst<ALast-1 do begin
   EntryLast:=EntryFirst;Nesting:=0;
   while EntryLast<ALast-1 do begin
    if Tokens[EntryLast].Text='(' then Inc(Nesting) else if Tokens[EntryLast].Text=')' then Dec(Nesting);
    if (Nesting=0) and (Tokens[EntryLast].Text=',') then Break;Inc(EntryLast);
   end;
   ColumnDefinition:=Span(EntryFirst,EntryLast);Problem:='';ColumnName:=Tokens[EntryFirst].Text;
   if MatchText(ColumnName,['CONSTRAINT','PRIMARY','FOREIGN','UNIQUE','CHECK']) then begin
    AddRow('constraint',ATable+' | '+ColumnName,ASchema,'captured constraint','Table-level constraint text only; membership, key relationships and enforcement are unverified.',ColumnDefinition,Tokens[EntryFirst].Line,ARange);
    Row.AddPair('table',ATable).AddPair('declaration_id',ADeclaration).AddPair('scope','table');
    InspectKey(EntryFirst,EntryLast,'');
    EntryFirst:=EntryLast+1;Continue;
   end;
   SetLength(KeySpans,0);Cursor:=EntryFirst+1;TypeFirst:=Cursor;SawNull:=False;SawNotNull:=False;SawDefault:=False;DefaultText:='not declared';ConstraintText:='';
   if not Tokens[EntryFirst].Identifier or (Cursor>=EntryLast) or not Tokens[Cursor].Identifier then Problem:='Missing column name or declared data type';
   if (Cursor<EntryLast) and MatchText(Tokens[Cursor].Text,['DEFAULT','NOT','NULL','CONSTRAINT','PRIMARY','UNIQUE','CHECK','REFERENCES','GENERATED','COLLATE']) then Problem:='Missing data type before column clause';
   if Problem='' then begin
    Inc(Cursor);
    if (Cursor<EntryLast) and (Tokens[Cursor].Text='.') then begin Inc(Cursor);if (Cursor>=EntryLast) or not Tokens[Cursor].Identifier then Problem:='Incomplete qualified data type' else Inc(Cursor);end;
    if (Cursor<EntryLast) and MatchText(Tokens[Cursor].Text,['PRECISION','VARYING']) then Inc(Cursor);
    if (Cursor<EntryLast) and (Tokens[Cursor].Text='(') then Parentheses;
    if (Cursor+2<EntryLast) and MatchText(Tokens[Cursor].Text,['WITH','WITHOUT']) and SameText(Tokens[Cursor+1].Text,'TIME') and SameText(Tokens[Cursor+2].Text,'ZONE') then Inc(Cursor,3);
    while (Cursor<EntryLast) and ((Tokens[Cursor].Text='[]') or MatchText(Tokens[Cursor].Text,['UNSIGNED','ZEROFILL'])) do Inc(Cursor);
   end;
   TypeLast:=Cursor;DeclaredType:=Span(TypeFirst,TypeLast);
   while (Cursor<EntryLast) and (Problem='') do begin
    ClauseFirst:=Cursor;
    if SameText(Tokens[Cursor].Text,'DEFAULT') then begin
     if SawDefault then begin Problem:='Repeated DEFAULT clauses';Break;end;SawDefault:=True;Inc(Cursor);ExpressionFirst:=Cursor;
     if Cursor>=EntryLast then begin Problem:='DEFAULT has no expression';Break;end;
     if Tokens[Cursor].Text='(' then Parentheses
     else begin
      if MatchText(Tokens[Cursor].Text,['+','-']) then Inc(Cursor);
      if Cursor>=EntryLast then begin Problem:='Incomplete DEFAULT expression';Break;end;
      if TryStrToInt(Tokens[Cursor].Text,Number) then begin
       repeat Inc(Cursor) until (Cursor>=EntryLast) or not TryStrToInt(Tokens[Cursor].Text,Number);
       if (Cursor<EntryLast) and (Tokens[Cursor].Text='.') then begin Inc(Cursor);Part:=Cursor;while (Cursor<EntryLast) and TryStrToInt(Tokens[Cursor].Text,Number) do Inc(Cursor);if Cursor=Part then Problem:='Incomplete numeric default';end;
      end else if Tokens[Cursor].Identifier or (Tokens[Cursor].Text='[literal omitted]') then begin
       if MatchText(Tokens[Cursor].Text,['CASE','SELECT','NOT','CONSTRAINT','CHECK','REFERENCES','PRIMARY','UNIQUE']) then Problem:='Unsupported DEFAULT expression';
       Inc(Cursor);
       if (Cursor<EntryLast) and (Tokens[Cursor].Text='(') then Parentheses;
      end else Problem:='Unsupported DEFAULT expression';
     end;
     ExpressionLast:=Cursor;DefaultText:=Span(ExpressionFirst,ExpressionLast);Continue;
    end;
    if SameText(Tokens[Cursor].Text,'CONSTRAINT') then begin Inc(Cursor);if (Cursor>=EntryLast) or not Tokens[Cursor].Identifier then begin Problem:='Missing constraint name';Break;end;Inc(Cursor);if Cursor>=EntryLast then begin Problem:='Missing named constraint clause';Break;end;end;
    KeyAt:=Cursor;
    if (Cursor+1<EntryLast) and SameText(Tokens[Cursor].Text,'NOT') and SameText(Tokens[Cursor+1].Text,'NULL') then begin SawNotNull:=True;Inc(Cursor,2);end
    else if SameText(Tokens[Cursor].Text,'NULL') then begin SawNull:=True;Inc(Cursor);end
    else if (Cursor+1<EntryLast) and SameText(Tokens[Cursor].Text,'PRIMARY') and SameText(Tokens[Cursor+1].Text,'KEY') then Inc(Cursor,2)
    else if SameText(Tokens[Cursor].Text,'UNIQUE') then Inc(Cursor)
    else if SameText(Tokens[Cursor].Text,'CHECK') then begin Inc(Cursor);Parentheses;end
    else if SameText(Tokens[Cursor].Text,'REFERENCES') then begin
     Inc(Cursor);if (Cursor>=EntryLast) or not Tokens[Cursor].Identifier then Problem:='Missing referenced object' else begin Inc(Cursor);while (Cursor+1<EntryLast) and (Tokens[Cursor].Text='.') and Tokens[Cursor+1].Identifier do Inc(Cursor,2);if (Cursor<EntryLast) and (Tokens[Cursor].Text='(') then Parentheses;end;
    end else Problem:='Unsupported column clause: '+Tokens[Cursor].Text;
    if ConstraintText<>'' then ConstraintText:=ConstraintText+sLineBreak;ConstraintText:=ConstraintText+Span(ClauseFirst,Cursor);
    if (Problem='') and MatchText(Tokens[KeyAt].Text,['PRIMARY','UNIQUE','REFERENCES']) then begin SetLength(KeySpans,Length(KeySpans)+1);KeySpans[High(KeySpans)]:=TPair<Integer,Integer>.Create(ClauseFirst,Cursor);end;
   end;
   if SawNull and SawNotNull then Problem:='Conflicting NULL and NOT NULL declarations';
   Nullability:='not declared';if SawNull then Nullability:='explicit NULL';if SawNotNull then Nullability:='explicit NOT NULL';
   if Problem<>'' then begin
    AddRow('gap',ATable+'.'+ColumnName,ASchema,'unsupported','Column extraction gap: '+Problem+'. Full captured entry retained; no structured column facts promoted.',ColumnDefinition,Tokens[EntryFirst].Line,ARange);
    Row.AddPair('table',ATable).AddPair('declaration_id',ADeclaration);
   end else begin
    AddRow('column',ATable+'.'+ColumnName,ASchema,'declared column','Captured column declaration only. Type validity, expression semantics, effective nullability, inherited/domain defaults and deployed enforcement are unverified.',ColumnDefinition,Tokens[EntryFirst].Line,ARange);
    ColumnRow:=Row;ColumnRow.AddPair('table',ATable).AddPair('declaration_id',ADeclaration).AddPair('column',ColumnName).AddPair('declared_type',DeclaredType).AddPair('nullability',Nullability).AddPair('default',DefaultText).AddPair('constraints',ConstraintText);
    for KeySpan in KeySpans do InspectKey(KeySpan.Key,KeySpan.Value,ColumnName);
   end;
   EntryFirst:=EntryLast+1;
  end;
  if Tokens[ALast-2].Text=',' then begin AddRow('gap',ATable+' | empty entry',ASchema,'unsupported','Trailing comma leaves an empty column/constraint entry; no facts inferred.','',Tokens[ALast-2].Line,ARange);Row.AddPair('table',ATable).AddPair('declaration_id',ADeclaration);end;
 end;
 function InspectIndex(AFirst,AEnd:Integer;ARange:TJSONObject):Boolean;
 var P,BeginTerm,EndTerm,Balance,Part,Order:Integer;
     IndexName,TableName,TableQualifier,IndexQualifier,UnusedQualifier,Method,StorageKind,Predicate,Options,Tablespace,NullTreatment,Problem,Column,SortOrder,NullOrder:string;
     IsUnique,Concurrent,Conditional,OnlyTable:Boolean;Members,Included:TJSONArray;MemberRow:TJSONObject;Seen:TDictionary<string,Boolean>;
  function Span(AStart,AStop:Integer):string;
  var T:Integer;
  begin Result:='';for T:=AStart to AStop-1 do begin if Length(Result)>8000 then Exit(Result+' [display truncated]');if Result<>'' then Result:=Result+' ';Result:=Result+Tokens[T].Text;end;end;
  function QualifiedName(out Qualifier:string):string;
  var Parts:Integer;
  begin
   Result:='';Qualifier:='unknown';Parts:=0;
   repeat
    if (P>=AEnd) or not Tokens[P].Identifier then begin Problem:='Missing identifier in qualified name';Exit;end;
    if Result<>'' then begin Qualifier:=Result;Result:=Result+'.';end;Result:=Result+Tokens[P].Text;Inc(P);Inc(Parts);
    if (P<AEnd) and (Tokens[P].Text='.') then Inc(P) else Break;
   until False;
   if Parts>3 then Problem:='Name has more than three parts';
  end;
  procedure Parentheses;
  begin
   Balance:=0;if (P>=AEnd) or (Tokens[P].Text<>'(') then begin Problem:='Expected parenthesized structure';Exit;end;
   repeat
    if Tokens[P].Text='(' then Inc(Balance) else if Tokens[P].Text=')' then Dec(Balance);
    if Balance>128 then begin Problem:='Index expression nesting exceeds 128';Exit;end;
    Inc(P);
   until (P>=AEnd) or (Balance=0);
   if Balance<>0 then Problem:='Incomplete parenthesized index structure';
  end;
 begin
  Result:=False;P:=AFirst+1;IsUnique:=False;Concurrent:=False;Conditional:=False;OnlyTable:=False;StorageKind:='not declared';
  if (P<AEnd) and SameText(Tokens[P].Text,'UNIQUE') then begin IsUnique:=True;Inc(P);end;
  if (P<AEnd) and MatchText(Tokens[P].Text,['CLUSTERED','NONCLUSTERED']) then begin StorageKind:=UpperCase(Tokens[P].Text);Inc(P);end;
  if (P>=AEnd) or not SameText(Tokens[P].Text,'INDEX') then Exit;
  Result:=True;Inc(P);Problem:='';IndexName:='';TableName:='';TableQualifier:='unknown';Method:='not declared';Predicate:='not declared';Options:='not declared';Tablespace:='not declared';NullTreatment:='not declared';
  Members:=TJSONArray.Create;Included:=TJSONArray.Create;Seen:=TDictionary<string,Boolean>.Create;
  try
   if (P<AEnd) and SameText(Tokens[P].Text,'CONCURRENTLY') then begin Concurrent:=True;Inc(P);end;
   if (P+2<AEnd) and SameText(Tokens[P].Text,'IF') and SameText(Tokens[P+1].Text,'NOT') and SameText(Tokens[P+2].Text,'EXISTS') then begin Conditional:=True;Inc(P,3);end;
   IndexName:=QualifiedName(IndexQualifier);
   if (Problem='') and ((P>=AEnd) or not SameText(Tokens[P].Text,'ON')) then Problem:='Expected ON after an explicit index name';
   if Problem='' then begin Inc(P);if (P<AEnd) and SameText(Tokens[P].Text,'ONLY') then begin OnlyTable:=True;Inc(P);end;TableName:=QualifiedName(TableQualifier);end;
   if (Problem='') and (P<AEnd) and SameText(Tokens[P].Text,'USING') then begin Inc(P);if (P<AEnd) and Tokens[P].Identifier then begin Method:=Tokens[P].Text;Inc(P);end else Problem:='Missing declared index method';end;
   if (Problem='') and ((P>=AEnd) or (Tokens[P].Text<>'(')) then Problem:='Expected nonempty index member list';
   if Problem='' then begin
    Inc(P);Order:=0;
    repeat
     BeginTerm:=P;Column:='';SortOrder:='not declared';NullOrder:='not declared';
     if (P<AEnd) and (Tokens[P].Text='(') then begin Parentheses;if (Problem='') and (P=BeginTerm+2) then Problem:='Empty index expression';end
     else if (P<AEnd) and Tokens[P].Identifier then begin
      Column:=Tokens[P].Text;Inc(P);
      if (P<AEnd) and (Tokens[P].Text='(') then begin Column:='';Parentheses;end;
     end else Problem:='Missing index column or supported expression';
     EndTerm:=P;
     if (Problem='') and (P<AEnd) and MatchText(Tokens[P].Text,['ASC','DESC']) then begin SortOrder:=UpperCase(Tokens[P].Text);Inc(P);end;
     if (Problem='') and (P<AEnd) and SameText(Tokens[P].Text,'NULLS') then begin Inc(P);if (P<AEnd) and MatchText(Tokens[P].Text,['FIRST','LAST']) then begin NullOrder:=UpperCase(Tokens[P].Text);Inc(P);end else Problem:='Expected NULLS FIRST or LAST';end;
     if Problem<>'' then Break;
     Inc(Order);MemberRow:=TJSONObject.Create.AddPair('position',TJSONNumber.Create(Order)).AddPair('column',Column).AddPair('expression',Span(BeginTerm,EndTerm)).AddPair('sort',SortOrder).AddPair('nulls',NullOrder);Members.AddElement(MemberRow);
     if (P<AEnd) and (Tokens[P].Text=',') then Inc(P) else Break;
    until False;
    if (Problem='') and ((P>=AEnd) or (Tokens[P].Text<>')')) then Problem:='Incomplete member list or unsupported member option';if Problem='' then Inc(P);
   end;
   if (Problem='') and (P<AEnd) and SameText(Tokens[P].Text,'INCLUDE') then begin
    Inc(P);if (P>=AEnd) or (Tokens[P].Text<>'(') then Problem:='Expected included column list' else begin
     Inc(P);repeat
      if (P>=AEnd) or not Tokens[P].Identifier then begin Problem:='Missing included column identifier';Break;end;
      if Seen.ContainsKey(Tokens[P].Text) then begin Problem:='Repeated included column';Break;end;Seen.Add(Tokens[P].Text,True);Included.Add(Tokens[P].Text);Inc(P);
      if (P<AEnd) and (Tokens[P].Text=',') then Inc(P) else Break;
     until False;
     if (Problem='') and ((P>=AEnd) or (Tokens[P].Text<>')')) then Problem:='Incomplete or unsupported included column list';if Problem='' then Inc(P);
    end;
   end;
   if (Problem='') and (P<AEnd) and SameText(Tokens[P].Text,'NULLS') then begin
    BeginTerm:=P;Inc(P);if (P<AEnd) and SameText(Tokens[P].Text,'NOT') then Inc(P);
    if (P<AEnd) and SameText(Tokens[P].Text,'DISTINCT') then begin Inc(P);NullTreatment:=Span(BeginTerm,P);end else Problem:='Expected NULLS DISTINCT or NOT DISTINCT';
   end;
   if (Problem='') and (P<AEnd) and SameText(Tokens[P].Text,'WITH') then begin Inc(P);BeginTerm:=P;Parentheses;if (Problem='') and (P=BeginTerm+2) then Problem:='Empty storage options';if Problem='' then Options:=Span(BeginTerm,P);end;
   if (Problem='') and (P<AEnd) and SameText(Tokens[P].Text,'TABLESPACE') then begin Inc(P);Tablespace:=QualifiedName(UnusedQualifier);end;
   if (Problem='') and (P<AEnd) and SameText(Tokens[P].Text,'WHERE') then begin
    Inc(P);BeginTerm:=P;Balance:=0;
    for Part:=P to AEnd-1 do begin
     if Tokens[Part].Text='(' then Inc(Balance) else if Tokens[Part].Text=')' then Dec(Balance);
     if (Balance<0) or (Balance>128) or MatchText(Tokens[Part].Text,['CREATE','ALTER','DROP','SELECT','INSERT','UPDATE','DELETE','WITH','TABLESPACE','$']) then Problem:='Unsupported or unbalanced index predicate';
    end;
    if (Balance<>0) or (BeginTerm=AEnd) then Problem:='Empty or incomplete index predicate';Predicate:=Span(BeginTerm,AEnd);P:=AEnd;
   end;
   if (Problem='') and (P<>AEnd) then Problem:='Unsupported index clause tail: '+Tokens[P].Text;
   if Problem<>'' then begin AddRow('gap','index '+IndexName,TableQualifier,'unsupported','Index extraction gap: '+Problem+'. No structured index promoted.',Span(AFirst,AEnd),Tokens[AFirst].Line,ARange);Exit;end;
   AddRow('index',IndexName,TableQualifier,'declared index','Captured index declaration only. Dialect validity, effective migration, physical existence, optimizer use and performance benefit are unverified.',Span(AFirst,AEnd),Tokens[AFirst].Line,ARange);
   Row.AddPair('table',TableName).AddPair('index_qualifier',IndexQualifier).AddPair('unique',TJSONBool.Create(IsUnique)).AddPair('concurrently',TJSONBool.Create(Concurrent)).AddPair('conditional',TJSONBool.Create(Conditional)).AddPair('only_table',TJSONBool.Create(OnlyTable)).AddPair('storage_kind',StorageKind).AddPair('method',Method).AddPair('members',Members).AddPair('included_columns',Included).AddPair('null_treatment',NullTreatment).AddPair('predicate',Predicate).AddPair('storage_options',Options).AddPair('tablespace',Tablespace);
   Members:=nil;Included:=nil;
  finally Seen.Free;Members.Free;Included.Free;end;
 end;
 function InspectStored(AFirst:Integer;var AEnd:Integer;ARange:TJSONObject):Boolean;
 var P,Q,N,BodyFirst,BodyLast,BlockDepth,BracketDepth,ParamFirst,ParamLast,TypeFirst,DefaultAt,Order,ScanAt:Integer;
     ObjectKind,ObjectName,Qualifier,Problem,LanguageName,ReturnType,BodyText,BodyIssue,TriggerTable,Timing,Scope,Events,WhenText,Mode,ParamName,ParamType,DefaultText,TargetName,Role,DependencyNote,HeaderOperation:string;
     Params,Dependencies:TJSONArray;ParamRow,Dependency:TJSONObject;BodyTokens:TList<TSchemaToken>;Seen:TDictionary<string,Boolean>;TokenValue:TSchemaToken;QuotedBody,Parenthesized,ComplexScope:Boolean;
  function Span(AStart,AStop:Integer):string;
  var T:Integer;
  begin Result:='';for T:=AStart to AStop-1 do begin if Length(Result)>8000 then Exit(Result+' [display truncated]');if Result<>'' then Result:=Result+' ';Result:=Result+Tokens[T].Text;end;end;
  function ReadName(var Cursor:Integer;Limit:Integer;Source:TList<TSchemaToken>):string;
  var Parts:Integer;
  begin
   Result:='';Parts:=0;
   repeat
    if (Cursor>=Limit) or not Source[Cursor].Identifier or MatchText(Source[Cursor].Text,['AS','BEGIN','END','CREATE','RETURNS','LANGUAGE','SELECT','FROM','WHERE','ON']) then begin Problem:='Missing qualified identifier';Exit;end;
    if Result<>'' then Result:=Result+'.';Result:=Result+Source[Cursor].Text;Inc(Cursor);Inc(Parts);
    if (Cursor<Limit) and (Source[Cursor].Text='.') then Inc(Cursor) else Break;
   until False;
   if Parts>3 then Problem:='Identifier has more than three parts';
  end;
  function TypeSupported(AStart,AStop:Integer):Boolean;
  var T,Value:Integer;
  begin
   Result:=False;if (AStart>=AStop) or not Tokens[AStart].Identifier or MatchText(Tokens[AStart].Text,['AS','RETURNS','LANGUAGE','DEFAULT','BEGIN','TABLE']) then Exit;
   T:=AStart+1;
   while (T+1<AStop) and (Tokens[T].Text='.') and Tokens[T+1].Identifier do Inc(T,2);
   if (T<AStop) and MatchText(Tokens[T].Text,['PRECISION','VARYING']) then Inc(T);
   if (T<AStop) and (Tokens[T].Text='(') then begin
    Inc(T);if (T>=AStop) or not TryStrToInt(Tokens[T].Text,Value) then Exit;Inc(T);
    if (T<AStop) and (Tokens[T].Text=',') then begin Inc(T);if (T>=AStop) or not TryStrToInt(Tokens[T].Text,Value) then Exit;Inc(T);end;
    if (T>=AStop) or (Tokens[T].Text<>')') then Exit;Inc(T);
   end;
   if (T+2<AStop) and MatchText(Tokens[T].Text,['WITH','WITHOUT']) and SameText(Tokens[T+1].Text,'TIME') and SameText(Tokens[T+2].Text,'ZONE') then Inc(T,3);
   while (T<AStop) and (Tokens[T].Text='[]') do Inc(T);
   Result:=T=AStop;
  end;
  procedure ParameterEntry(AStart,AStop:Integer);
  var T,B:Integer;
  begin
   Q:=AStart;Mode:='IN';DefaultText:='not declared';ParamName:='';
   if (Q<AStop) and MatchText(Tokens[Q].Text,['IN','OUT','INOUT','VARIADIC']) then begin Mode:=UpperCase(Tokens[Q].Text);Inc(Q);end;
   if (Q<AStop) and (Tokens[Q].Text='@') then begin ParamName:='@';Inc(Q);end;
   if (Q>=AStop) or not Tokens[Q].Identifier then begin Problem:='Parameter requires an explicit name and type';Exit;end;
   ParamName:=ParamName+Tokens[Q].Text;Inc(Q);TypeFirst:=Q;DefaultAt:=AStop;B:=0;
   for T:=Q to AStop-1 do begin
    if Tokens[T].Text='(' then Inc(B) else if Tokens[T].Text=')' then Dec(B);
    if (B=0) and MatchText(Tokens[T].Text,['DEFAULT','=']) then begin DefaultAt:=T;Break;end;
   end;
   Q:=DefaultAt;if (Q>TypeFirst) and MatchText(Tokens[Q-1].Text,['OUT','OUTPUT','READONLY']) then begin Mode:=UpperCase(Tokens[Q-1].Text);Dec(Q);end;
   if not TypeSupported(TypeFirst,Q) then begin Problem:='Unsupported parameter type structure';Exit;end;
   ParamType:=Span(TypeFirst,Q);
   if DefaultAt<AStop then begin
    Q:=AStop;if (Q>DefaultAt+1) and MatchText(Tokens[Q-1].Text,['OUT','OUTPUT']) then begin Mode:=UpperCase(Tokens[Q-1].Text);Dec(Q);end;
    if Q<=DefaultAt+1 then begin Problem:='Parameter default has no expression';Exit;end;DefaultText:=Span(DefaultAt+1,Q);
   end;
   if Seen.ContainsKey(ParamName) then begin Problem:='Duplicate parameter name';Exit;end;Seen.Add(ParamName,True);Inc(Order);
   ParamRow:=TJSONObject.Create.AddPair('position',TJSONNumber.Create(Order)).AddPair('name',ParamName).AddPair('mode',Mode).AddPair('declared_type',ParamType).AddPair('default',DefaultText).AddPair('line',TJSONNumber.Create(Tokens[AStart].Line));Params.AddElement(ParamRow);
  end;
  procedure AddDependency(const ARole,AName,AState:string;ALine:Integer);
  begin
   if StoredDependencies>=10000 then begin DependencyNote:='Dependency display limited to 10000 entries across the projection; coverage incomplete.';Exit;end;
   if Dependencies.Count>=1000 then begin DependencyNote:='Dependency display limited to 1000 entries; coverage incomplete.';Exit;end;
   Dependency:=TJSONObject.Create.AddPair('role',ARole).AddPair('reference',AName).AddPair('line',TJSONNumber.Create(ALine)).AddPair('state',AState);Dependencies.AddElement(Dependency);Inc(StoredDependencies);
  end;
 begin
  Result:=False;P:=AFirst+1;HeaderOperation:='CREATE';
  if (P+1<Tokens.Count) and SameText(Tokens[P].Text,'OR') and MatchText(Tokens[P+1].Text,['REPLACE','ALTER']) then begin HeaderOperation:='CREATE OR '+UpperCase(Tokens[P+1].Text);Inc(P,2);end;
  if (P>=Tokens.Count) or not MatchText(Tokens[P].Text,['PROCEDURE','PROC','FUNCTION','TRIGGER']) then Exit;
  Result:=True;ObjectKind:=LowerCase(Tokens[P].Text);if ObjectKind='proc' then ObjectKind:='procedure';Inc(P);
  Problem:='';ObjectName:='';Qualifier:='unknown';LanguageName:='not declared';ReturnType:='not declared';TriggerTable:='';Timing:='not declared';Events:='';Scope:='not declared';WhenText:='not declared';DependencyNote:='Supported literal table references and explicit calls only; aliases, column binding, expression calls, CTEs and dynamic SQL are unverified. Empty dependencies do not establish independence.';
  BodyFirst:=-1;BodyLast:=-1;QuotedBody:=False;
  // Keep an inline block together; never reinterpret its internal DDL as top-level declarations.
  for ScanAt:=P to AEnd-1 do if SameText(Tokens[ScanAt].Text,'BEGIN') then begin
   BodyFirst:=ScanAt;BlockDepth:=0;Q:=ScanAt;
   while Q<Tokens.Count do begin
    if MatchText(Tokens[Q].Text,['BEGIN','CASE']) then Inc(BlockDepth)
    else if SameText(Tokens[Q].Text,'END') and not ((Q+1<Tokens.Count) and MatchText(Tokens[Q+1].Text,['IF','LOOP','WHILE'])) then begin Dec(BlockDepth);if BlockDepth=0 then begin BodyLast:=Q+1;Break;end;end;
    if (BlockDepth>128) then begin Problem:='Stored-object nesting exceeds 128';Break;end;
    if SameText(Tokens[Q].Text,'END') and (Q+1<Tokens.Count) and SameText(Tokens[Q+1].Text,'CASE') then Inc(Q);
    Inc(Q);
   end;
   if BodyLast<0 then begin Problem:='Unterminated stored-object block; remaining resource held as a gap';AEnd:=Tokens.Count;end
   else begin AEnd:=BodyLast;if (AEnd<Tokens.Count) and (Tokens[AEnd].Text<>';') and not SameText(Tokens[AEnd].Text,'GO') then begin Problem:='Unsupported tail after stored-object block';while (AEnd<Tokens.Count) and (Tokens[AEnd].Text<>';') do Inc(AEnd);end;end;
   Break;
  end;
  Params:=TJSONArray.Create;Dependencies:=TJSONArray.Create;BodyTokens:=TList<TSchemaToken>.Create;Seen:=TDictionary<string,Boolean>.Create;
  try
   if Problem='' then begin Q:=P;ObjectName:=ReadName(P,AEnd,Tokens);if P-Q>2 then begin Qualifier:='';for ScanAt:=Q to P-3 do Qualifier:=Qualifier+Tokens[ScanAt].Text;end;end;
   if (Problem='') and (ObjectKind<>'trigger') then begin
    Parenthesized:=(P<AEnd) and (Tokens[P].Text='(');ParamFirst:=P;
    if Parenthesized then begin
     Inc(P);ParamFirst:=P;BracketDepth:=1;
     while (P<AEnd) and (BracketDepth>0) do begin if Tokens[P].Text='(' then Inc(BracketDepth) else if Tokens[P].Text=')' then Dec(BracketDepth);if BracketDepth>0 then Inc(P);end;
     if BracketDepth<>0 then Problem:='Incomplete parameter list';ParamLast:=P;Inc(P);
    end else begin
     if ObjectKind='function' then Problem:='Function requires a parenthesized parameter list';
     while (P<AEnd) and not MatchText(Tokens[P].Text,['AS','BEGIN','LANGUAGE']) do Inc(P);ParamLast:=P;
    end;
    Q:=ParamFirst;Order:=0;
    while (Q<ParamLast) and (Problem='') do begin
     N:=Q;BracketDepth:=0;while N<ParamLast do begin if Tokens[N].Text='(' then Inc(BracketDepth) else if Tokens[N].Text=')' then Dec(BracketDepth);if (BracketDepth=0) and (Tokens[N].Text=',') then Break;Inc(N);end;
     ScanAt:=N;ParameterEntry(Q,N);Q:=ScanAt+1;
     if (Q=ParamLast) and (Tokens[ParamLast-1].Text=',') then Problem:='Trailing empty parameter';
    end;
    if (Problem='') and (ObjectKind='function') then begin
     if (P>=AEnd) or not SameText(Tokens[P].Text,'RETURNS') then Problem:='Function requires RETURNS type'
     else begin Inc(P);TypeFirst:=P;while (P<AEnd) and not MatchText(Tokens[P].Text,['AS','BEGIN','LANGUAGE']) do Inc(P);if not TypeSupported(TypeFirst,P) then Problem:='Unsupported return type structure' else ReturnType:=Span(TypeFirst,P);end;
    end;
   end;
   if (Problem='') and (ObjectKind='trigger') then begin
    if (P<AEnd) and MatchText(Tokens[P].Text,['BEFORE','AFTER']) then begin Timing:=UpperCase(Tokens[P].Text);Inc(P);end
    else if (P+1<AEnd) and SameText(Tokens[P].Text,'INSTEAD') and SameText(Tokens[P+1].Text,'OF') then begin Timing:='INSTEAD OF';Inc(P,2);end
    else Problem:='Expected trigger timing BEFORE, AFTER or INSTEAD OF';
    while (Problem='') and (P<AEnd) do begin
     if not MatchText(Tokens[P].Text,['INSERT','UPDATE','DELETE','TRUNCATE']) then begin Problem:='Unsupported trigger event';Break;end;
     if Events<>'' then Events:=Events+' OR ';Events:=Events+UpperCase(Tokens[P].Text);Inc(P);
     if (P<AEnd) and SameText(Tokens[P].Text,'OR') then Inc(P) else Break;
    end;
    if (Problem='') and ((P>=AEnd) or not SameText(Tokens[P].Text,'ON')) then Problem:='Expected trigger ON table';
    if Problem='' then begin Inc(P);TriggerTable:=ReadName(P,AEnd,Tokens);AddDependency('trigger table',TriggerTable,'captured reference',Tokens[AFirst].Line);end;
    if (P+2<AEnd) and SameText(Tokens[P].Text,'FOR') and SameText(Tokens[P+1].Text,'EACH') and MatchText(Tokens[P+2].Text,['ROW','STATEMENT']) then begin Scope:=UpperCase(Tokens[P+2].Text);Inc(P,3);end;
    if (P<AEnd) and SameText(Tokens[P].Text,'WHEN') then begin
     Inc(P);Q:=P;BracketDepth:=0;
     if (P>=AEnd) or (Tokens[P].Text<>'(') then Problem:='Trigger WHEN requires parentheses'
     else repeat if Tokens[P].Text='(' then Inc(BracketDepth) else if Tokens[P].Text=')' then Dec(BracketDepth);Inc(P);until (P>=AEnd) or (BracketDepth=0);
     if BracketDepth<>0 then Problem:='Incomplete trigger WHEN';WhenText:=Span(Q,P);
    end;
    if (Problem='') and (P+1<AEnd) and SameText(Tokens[P].Text,'EXECUTE') and MatchText(Tokens[P+1].Text,['FUNCTION','PROCEDURE']) then begin
     Inc(P,2);TargetName:=ReadName(P,AEnd,Tokens);AddDependency('function call',TargetName,'captured reference',Tokens[AFirst].Line);
     if (P+1<>AEnd-1) or (Tokens[P].Text<>'(') or (Tokens[P+1].Text<>')') then Problem:='Only zero-argument trigger calls are supported' else begin Inc(P,2);BodyText:='EXECUTE FUNCTION '+TargetName+' ( )';BodyFirst:=-2;end;
    end;
   end;
   if (Problem='') and (BodyFirst<>-2) then begin
    if (P+1<AEnd) and SameText(Tokens[P].Text,'LANGUAGE') and Tokens[P+1].Identifier then begin LanguageName:=Tokens[P+1].Text;Inc(P,2);end;
    if (P<AEnd) and SameText(Tokens[P].Text,'AS') then Inc(P);
    if (P<AEnd) and (Tokens[P].Text='[literal omitted]') then begin
     QuotedBody:=True;Tokenize(Tokens[P].Body,Tokens[P].Line,BodyTokens,BodyIssue);Inc(P);
     if BodyIssue<>'' then Problem:='Body lexical gap: '+BodyIssue;
     if (P+1<AEnd) and SameText(Tokens[P].Text,'LANGUAGE') and Tokens[P+1].Identifier then begin LanguageName:=Tokens[P+1].Text;Inc(P,2);end;
     if not MatchText(LanguageName,['sql','plpgsql']) then Problem:='Quoted body language must be SQL or PLPGSQL';
     if P<>AEnd then Problem:='Unsupported stored-object option tail';
     if BodyTokens.Count=0 then Problem:='Empty stored-object body';
    end else if (P=BodyFirst) and (BodyLast>BodyFirst) then begin for Q:=BodyFirst to BodyLast-1 do BodyTokens.Add(Tokens[Q]);P:=BodyLast;end
    else Problem:='Expected supported AS quoted SQL body or BEGIN/END block';
    BodyText:='';for TokenValue in BodyTokens do begin if Length(BodyText)>16000 then begin BodyText:=BodyText+' [display truncated]';Break;end;if BodyText<>'' then BodyText:=BodyText+' ';BodyText:=BodyText+TokenValue.Text;end;
   end;
   if Problem<>'' then begin AddRow('gap','stored object '+ObjectName,Qualifier,'unsupported','Stored-object extraction gap: '+Problem+'. No structured stored object promoted.',Span(AFirst,AEnd),Tokens[AFirst].Line,ARange);Exit;end;
   // These are textual evidence, never a complete or executable dependency graph.
   ComplexScope:=False;for TokenValue in BodyTokens do if SameText(TokenValue.Text,'WITH') then ComplexScope:=True;
   Q:=0;
   while Q<BodyTokens.Count do begin
    Role:='';ScanAt:=Q;
    if MatchText(BodyTokens[Q].Text,['FROM','JOIN','UPDATE']) then begin Role:='table reference';Inc(Q);end
    else if (Q>0) and (Q+1<BodyTokens.Count) and SameText(BodyTokens[Q].Text,'INTO') and SameText(BodyTokens[Q-1].Text,'INSERT') then begin Role:='table reference';Inc(Q);end
    else if MatchText(BodyTokens[Q].Text,['CALL','EXEC']) then begin Role:='procedure call';Inc(Q);end
    else if (Q+1<BodyTokens.Count) and SameText(BodyTokens[Q].Text,'EXECUTE') and SameText(BodyTokens[Q+1].Text,'PROCEDURE') then begin Role:='procedure call';Inc(Q,2);end
    else if SameText(BodyTokens[Q].Text,'EXECUTE') then AddDependency('unresolved dynamic execution','','dynamic SQL or dialect-specific execution; no target guessed',BodyTokens[Q].Line);
    if Role<>'' then begin
     if (Q<BodyTokens.Count) and BodyTokens[Q].Identifier and not MatchText(BodyTokens[Q].Text,['SELECT','SET','ONLY']) then begin
      TargetName:=ReadName(Q,BodyTokens.Count,BodyTokens);
      if (Problem='') and not ((Role='table reference') and ComplexScope) and not ((Role='table reference') and not SameText(BodyTokens[ScanAt].Text,'INTO') and (Q<BodyTokens.Count) and (BodyTokens[Q].Text='(')) then AddDependency(Role,TargetName,'captured reference',BodyTokens[ScanAt].Line)
      else AddDependency('unresolved dependency',TargetName,'complex reference; no target guessed',BodyTokens[ScanAt].Line);
      Problem:='';
     end else AddDependency('unresolved dependency','','complex reference; no target guessed',BodyTokens[ScanAt].Line);
    end;
    if StoredDependencies>=10000 then begin DependencyNote:='Dependency display limited to 10000 entries across the projection; coverage incomplete.';Break;end;
    if Dependencies.Count>=1000 then begin DependencyNote:='Dependency display limited to 1000 entries; coverage incomplete.';Break;end;
    Q:=ScanAt+1;
   end;
   AddRow(ObjectKind,ObjectName,Qualifier,'declared stored object','Captured definition and supported header structure only. Body grammar, permissions, overload selection, migration order and deployed behavior remain unverified.',Span(AFirst,AEnd),Tokens[AFirst].Line,ARange);
   Row.AddPair('parameters',Params).AddPair('returns',ReturnType).AddPair('language',LanguageName).AddPair('body',BodyText).AddPair('dependencies',Dependencies).AddPair('dependency_note',DependencyNote).AddPair('header_operation',HeaderOperation).AddPair('trigger_table',TriggerTable).AddPair('timing',Timing).AddPair('events',Events).AddPair('scope',Scope).AddPair('when',WhenText).AddPair('quoted_body',TJSONBool.Create(QuotedBody));Params:=nil;Dependencies:=nil;
  finally Seen.Free;BodyTokens.Free;Params.Free;Dependencies.Free;end;
 end;
 procedure ResolveStored;
 var Index:TDictionary<string,TJSONObject>;Multiplicity:TDictionary<string,Integer>;Item,Target,Link:TJSONObject;Value,Dependency:TJSONValue;Identity,TargetKey,StateText:string;N:Integer;Links:TJSONArray;Complete:Boolean;
  procedure RegisterName(const Key:string;ObjectRow:TJSONObject);
  var Count:Integer;
  begin Count:=0;Multiplicity.TryGetValue(Key,Count);Multiplicity.AddOrSetValue(Key,Count+1);Index.AddOrSetValue(Key,ObjectRow);end;
 begin
  Index:=TDictionary<string,TJSONObject>.Create;Multiplicity:=TDictionary<string,Integer>.Create;
  try
   for Value in Rows do begin Item:=Value as TJSONObject;
    if MatchText(Item.GetValue<string>('kind'),['table','view']) and (Item.GetValue<string>('status')='declared header') then RegisterName('relation|'+Item.GetValue<string>('name'),Item);
    if Item.GetValue<string>('status')='declared stored object' then begin RegisterName(Item.GetValue<string>('kind')+'|'+Item.GetValue<string>('name'),Item);end;
   end;
   for Value in Rows do begin Item:=Value as TJSONObject;if Item.GetValue<string>('status')<>'declared stored object' then Continue;
    Links:=TJSONArray.Create;Item.AddPair('links',Links);Complete:=True;
    Identity:=Item.GetValue<string>('kind')+'|'+Item.GetValue<string>('name');N:=Multiplicity[Identity];Item.RemovePair('definition_count').Free;Item.AddPair('definition_count',TJSONNumber.Create(N));
    if N>1 then begin Complete:=False;Item.AddPair('conflict','Multiple captured definitions or overloads with this exact kind/name; no effective definition or overload selected.');end;
    for Dependency in Item.GetValue<TJSONArray>('dependencies') do begin
     TargetKey:='';if MatchText(Dependency.GetValue<string>('role'),['table reference','trigger table']) then TargetKey:='relation|'+Dependency.GetValue<string>('reference')
     else if Dependency.GetValue<string>('role')='procedure call' then TargetKey:='procedure|'+Dependency.GetValue<string>('reference')
     else if Dependency.GetValue<string>('role')='function call' then TargetKey:='function|'+Dependency.GetValue<string>('reference');
     Link:=TJSONObject.Create.AddPair('role',Dependency.GetValue<string>('role')).AddPair('reference',Dependency.GetValue<string>('reference')).AddPair('position',TJSONNumber.Create(Links.Count+1)).AddPair('line',TJSONNumber.Create(Dependency.GetValue<Integer>('line')));Links.AddElement(Link);
     N:=0;if TargetKey<>'' then Multiplicity.TryGetValue(TargetKey,N);
     if N=1 then begin Target:=Index[TargetKey];Link.AddPair('state','unique captured name match; binding unverified').AddPair('target_id',Target.GetValue<string>('id'));end
     else begin Complete:=False;if TargetKey='' then StateText:=Dependency.GetValue<string>('state') else if N=0 then StateText:='missing captured declaration' else StateText:='ambiguous captured declarations or overloads';Link.AddPair('state',StateText);end;
    end;
    if Complete then StateText:='captured links complete; coverage unverified' else StateText:='relationship gaps';Item.AddPair('relationship_status',StateText);
   end;
  finally Multiplicity.Free;Index.Free;end;
 end;
 procedure ResolveKeys;
 var Index:TDictionary<string,TJSONObject>;Multiplicity:TDictionary<string,Integer>;
     UsageIndex:TObjectDictionary<string,TList<TJSONObject>>;UsageRows:TList<TJSONObject>;UsageRow:TJSONObject;UsageShown,UsageLinks:Integer;
     Item,Link,TargetRow:TJSONObject;ItemValue,Member:TJSONValue;Links:TJSONArray;
     Identity,Owner,TargetOwner,TargetName,StateText:string;N,Order:Integer;Complete:Boolean;
  procedure LinkTo(const ARole,AName,AIdentity:string;APosition:Integer);
  begin
   Link:=TJSONObject.Create.AddPair('role',ARole).AddPair('reference',AName).AddPair('position',TJSONNumber.Create(APosition));Links.AddElement(Link);
   N:=0;Multiplicity.TryGetValue(AIdentity,N);
   if N=1 then begin TargetRow:=Index[AIdentity];Link.AddPair('state','unique captured match').AddPair('target_id',TargetRow.GetValue<string>('id'));end
   else begin Complete:=False;if N=0 then StateText:='missing captured declaration' else StateText:='ambiguous captured declarations';Link.AddPair('state',StateText);end;
  end;
 begin
  Index:=TDictionary<string,TJSONObject>.Create;Multiplicity:=TDictionary<string,Integer>.Create;UsageIndex:=TObjectDictionary<string,TList<TJSONObject>>.Create([doOwnsValues]);UsageLinks:=0;
  try
   for ItemValue in Rows do begin
    Item:=ItemValue as TJSONObject;Identity:='';
    if (Item.GetValue<string>('kind')='table') and (Item.GetValue<string>('status')='declared header') then Identity:='table|'+Item.GetValue<string>('name');
    if Item.GetValue<string>('kind')='column' then Identity:='column|'+Item.GetValue<string>('declaration_id')+'|'+Item.GetValue<string>('column');
    if Item.GetValue<string>('kind')='index' then Identity:='index|'+Item.GetValue<string>('table')+'|'+Item.GetValue<string>('name');
    if Item.GetValue<string>('status')='inferred reference' then begin
     TargetName:=Item.GetValue<string>('name');if not UsageIndex.TryGetValue(TargetName,UsageRows) then begin UsageRows:=TList<TJSONObject>.Create;UsageIndex.Add(TargetName,UsageRows);end;UsageRows.Add(Item);
    end;
    if Item.GetValue<string>('kind')='key' then begin Identity:='constraint|'+Item.GetValue<string>('declaration_id')+'|'+Item.GetValue<string>('constraint_name');N:=0;Multiplicity.TryGetValue(Identity,N);Multiplicity.AddOrSetValue(Identity,N+1);Identity:='';end;
    if (Item.GetValue<string>('kind')='key') and (Item.GetValue<string>('key_kind')='primary') then Identity:='primary|'+Item.GetValue<string>('declaration_id');
    if Identity='' then Continue;N:=0;Multiplicity.TryGetValue(Identity,N);Multiplicity.AddOrSetValue(Identity,N+1);Index.AddOrSetValue(Identity,Item);
   end;
   for ItemValue in Rows do begin
    Item:=ItemValue as TJSONObject;
    if Item.GetValue<string>('kind')='index' then begin
     Links:=TJSONArray.Create;Item.AddPair('links',Links);Complete:=True;Owner:='';TargetName:=Item.GetValue<string>('table');LinkTo('indexed table',TargetName,'table|'+TargetName,0);Link.TryGetValue<string>('target_id',Owner);
     for Member in Item.GetValue<TJSONArray>('members') do begin
      Order:=Member.GetValue<Integer>('position');Identity:=Member.GetValue<string>('column');
      if Identity='' then begin Complete:=False;Link:=TJSONObject.Create.AddPair('role','index expression').AddPair('reference',Member.GetValue<string>('expression')).AddPair('position',TJSONNumber.Create(Order)).AddPair('state','expression dependencies unverified');Links.AddElement(Link);end
      else if Owner<>'' then LinkTo('indexed column',Identity,'column|'+Owner+'|'+Identity,Order)
      else begin Complete:=False;Link:=TJSONObject.Create.AddPair('role','indexed column').AddPair('reference',Identity).AddPair('position',TJSONNumber.Create(Order)).AddPair('state','indexed table unresolved');Links.AddElement(Link);end;
     end;
     Order:=0;for Member in Item.GetValue<TJSONArray>('included_columns') do begin Inc(Order);
      if Owner<>'' then LinkTo('included column',Member.Value,'column|'+Owner+'|'+Member.Value,Order)
      else begin Complete:=False;Link:=TJSONObject.Create.AddPair('role','included column').AddPair('reference',Member.Value).AddPair('position',TJSONNumber.Create(Order)).AddPair('state','indexed table unresolved');Links.AddElement(Link);end;
     end;
     N:=Multiplicity['index|'+TargetName+'|'+Item.GetValue<string>('name')];Item.RemovePair('definition_count').Free;Item.AddPair('definition_count',TJSONNumber.Create(N));if N>1 then begin Complete:=False;Item.AddPair('conflict','Multiple captured index declarations with this exact table/name; effective migration unresolved.');end;
     UsageShown:=0;N:=0;
     if UsageIndex.TryGetValue(TargetName,UsageRows) then begin N:=UsageRows.Count;for UsageRow in UsageRows do begin
      if (UsageShown>=250) or (UsageLinks>=10000) then Break;Inc(UsageShown);Inc(UsageLinks);
      Link:=TJSONObject.Create.AddPair('role','SQL table reference (index use unobserved)').AddPair('reference',UsageRow.GetValue<string>('source')+':'+UsageRow.GetValue<Integer>('range.line').ToString).AddPair('position',TJSONNumber.Create(UsageShown)).AddPair('state','captured table reference only').AddPair('target_id',UsageRow.GetValue<string>('id'));Links.AddElement(Link);
     end;end;
     Item.AddPair('usage_reference_count',TJSONNumber.Create(N)).AddPair('usage_shown_count',TJSONNumber.Create(UsageShown)).AddPair('usage_note','Exact-spelling supported SQL table references only; no column coverage, optimizer selection or measured benefit is established. Zero references means no supported captured match, not an unused index. Navigation shows up to 250 references per index and 10000 across the projection.');
     if Complete then StateText:='captured links complete' else StateText:='relationship gaps';Item.AddPair('relationship_status',StateText);Continue;
    end;
    if Item.GetValue<string>('kind')<>'key' then Continue;
    Links:=TJSONArray.Create;Item.AddPair('links',Links);Complete:=True;Owner:=Item.GetValue<string>('declaration_id');Order:=0;
    Link:=TJSONObject.Create.AddPair('role','owning table').AddPair('reference',Item.GetValue<string>('table')).AddPair('position',TJSONNumber.Create(0)).AddPair('state','exact captured owner').AddPair('target_id',Owner);Links.AddElement(Link);
    for Member in Item.GetValue<TJSONArray>('members') do begin Inc(Order);LinkTo('local column',Member.Value,'column|'+Owner+'|'+Member.Value,Order);end;
    if Item.GetValue<string>('key_kind')='foreign' then begin
     TargetName:=Item.GetValue<string>('reference_table');TargetOwner:='';LinkTo('referenced table',TargetName,'table|'+TargetName,0);
     if Link.TryGetValue<string>('target_id',TargetOwner) then begin
      Order:=0;for Member in Item.GetValue<TJSONArray>('reference_columns') do begin Inc(Order);LinkTo('referenced column',Member.Value,'column|'+TargetOwner+'|'+Member.Value,Order);end;
     end else begin
      Order:=0;for Member in Item.GetValue<TJSONArray>('reference_columns') do begin Inc(Order);Link:=TJSONObject.Create.AddPair('role','referenced column').AddPair('reference',Member.Value).AddPair('position',TJSONNumber.Create(Order)).AddPair('state','referenced table unresolved');Links.AddElement(Link);end;
     end;
     if Item.GetValue<TJSONArray>('reference_columns').Count=0 then begin Complete:=False;Item.AddPair('reference_note','Referenced columns omitted; no default primary-key target guessed.');end
     else if Item.GetValue<TJSONArray>('reference_columns').Count<>Item.GetValue<TJSONArray>('members').Count then begin Complete:=False;Item.AddPair('reference_note','Local and referenced column counts differ; no valid pairing asserted.');end;
    end;
    N:=0;Multiplicity.TryGetValue('primary|'+Owner,N);if N>1 then begin Complete:=False;Item.AddPair('conflict','Multiple primary-key declarations in the same captured table; no effective key selected.');end;
    N:=0;Multiplicity.TryGetValue('constraint|'+Owner+'|'+Item.GetValue<string>('constraint_name'),N);if N>1 then begin Complete:=False;Item.AddPair('name_conflict','Duplicate constraint name in the same captured table; both records retained.');end;
    if Complete then StateText:='captured links complete' else StateText:='relationship gaps';Item.AddPair('relationship_status',StateText);
   end;
  finally UsageIndex.Free;Multiplicity.Free;Index.Free;end;
 end;
begin
 Result:=TJSONObject.Create;Rows:=TJSONArray.Create;Result.AddPair('rows',Rows);
 Result.AddPair('qualification','Captured schema evidence only. CREATE headers declare intended objects; body grammar, column/constraint semantics, deployment order, dialect, existence and current production schema are unverified. SQL references do not prove object definitions. No SQL or target application is executed. Comments and string literals are omitted from displayed definitions; original source/cache remains unchanged. Unsupported statements are explicit gaps. Quoted identifier spelling is preserved; cross-dialect identity is not guessed.');
 Tokens:=TList<TSchemaToken>.Create;Counts:=TDictionary<string,Integer>.Create;ReferenceNames:=TDictionary<string,string>.Create;Ordinal:=0;StoredDependencies:=0;
 try
  try
   for FileValue in AView.Document.GetValue<TJSONArray>('syntax.files') do begin
    FileRow:=FileValue as TJSONObject;Path:=FileRow.GetValue<string>('path');
    if not SameText(ExtractFileExt(Path),'.sql') then Continue;
    if not FileRow.TryGetValue<TJSONArray>('ir.nodes',Nodes) then begin
     Node:=TJSONObject.Create.AddPair('start',TJSONNumber.Create(0)).AddPair('end',TJSONNumber.Create(0));
     try AddRow('gap',Path,'unknown','unsupported','Captured SQL has no readable IR; obtain approved missing source.','',1,Node);finally Node.Free;end;Continue;
    end;
    for NodeValue in Nodes do begin
     Node:=NodeValue as TJSONObject;if Node.GetValue<string>('kind')<>'sql_text' then Continue;
     SQL:=Node.GetValue<string>('value');Tokenize(SQL,Node.GetValue<Integer>('line',1),Tokens,Issue);
     if Issue<>'' then begin AddRow('gap',Path,'unknown','unsupported',Issue,'',Line,Node);Continue;end;
     First:=0;
     while First<Tokens.Count do begin
      if SameText(Tokens[First].Text,'GO') and ((First=0) or (Tokens[First-1].Line<Tokens[First].Line)) and ((First+1=Tokens.Count) or (Tokens[First+1].Line>Tokens[First].Line)) then begin Inc(First);Continue;end;
      Last:=First;while (Last<Tokens.Count) and (Tokens[Last].Text<>';') do Inc(Last);
      if Last=First then begin Inc(First);Continue;end;
      Kind:='gap';Name:='statement at line '+IntToStr(Tokens[First].Line);SchemaName:='unknown';Status:='unsupported';Issue:='Unsupported SQL statement; no object definition inferred.';Definition:='';Valid:=True;
      if SameText(Tokens[First].Text,'CREATE') then begin
       if InspectStored(First,Last,Node) then begin First:=Last+1;Continue;end;
       if InspectIndex(First,Last,Node) then begin First:=Last+1;Continue;end;
       J:=First+1;ReplaceHeader:=False;TemporaryHeader:=False;IfHeader:=False;
       if (J+1<Last) and SameText(Tokens[J].Text,'OR') and SameText(Tokens[J+1].Text,'REPLACE') then begin ReplaceHeader:=True;Inc(J,2);end;
       if (J<Last) and MatchText(Tokens[J].Text,['TEMP','TEMPORARY']) then begin TemporaryHeader:=True;Inc(J);end;
       if (J<Last) and MatchText(Tokens[J].Text,['TABLE','VIEW','SCHEMA']) then begin
        Kind:=LowerCase(Tokens[J].Text);Inc(J);
        if (J+2<Last) and SameText(Tokens[J].Text,'IF') and SameText(Tokens[J+1].Text,'NOT') and SameText(Tokens[J+2].Text,'EXISTS') then begin IfHeader:=True;Inc(J,3);end;
        if (ReplaceHeader and (Kind<>'view')) or (TemporaryHeader and (Kind='schema')) or (IfHeader and (Kind='view')) then Valid:=False;
        NameAt:=J;Name:='';Count:=0;
        while (J<Last) and Tokens[J].Identifier do begin
         if Name<>'' then Name:=Name+'.';Name:=Name+Tokens[J].Text;Inc(J);Inc(Count);
         if (J<Last) and (Tokens[J].Text='.') then Inc(J) else Break;
        end;
        if (Count=0) or (Count>3) or ((J>0) and (Tokens[J-1].Text='.')) then Valid:=False;
        if Count>1 then begin SchemaName:='';for I:=NameAt to J-3 do SchemaName:=SchemaName+Tokens[I].Text;end;
        BodyAt:=J;Depth:=0;
        for I:=J to Last-1 do begin
         if Tokens[I].Text='(' then Inc(Depth) else if Tokens[I].Text=')' then Dec(Depth);
         if (Depth<0) or ((Depth=0) and SameText(Tokens[I].Text,'CREATE')) or (Tokens[I].Text='$') then Valid:=False;
        end;
        if Depth<>0 then Valid:=False;
        if Kind='schema' then begin if (Count<>1) or (BodyAt<>Last) then Valid:=False;end
        else if Kind='table' then begin if (BodyAt>=Last-2) or (Tokens[BodyAt].Text<>'(') or (Tokens[Last-1].Text<>')') then Valid:=False;end
        else if (BodyAt+2>=Last) or not SameText(Tokens[BodyAt].Text,'AS') or not SameText(Tokens[BodyAt+1].Text,'SELECT') then Valid:=False;
        if Valid then begin
         Status:='declared header';Issue:='Object name/header captured. Body grammar, columns, constraints and deployed existence are unverified.';
         for I:=First to Last-1 do begin if Length(Definition)>8000 then begin Definition:=Definition+' [display truncated]';Break;end;Definition:=Definition+Tokens[I].Text+' ';end;
        end else begin Kind:='gap';Name:='statement at line '+IntToStr(Tokens[First].Line);Issue:='CREATE statement outside supported header/balanced-body subset; no object definition inferred.';end;
       end;
      end;
      AddRow(Kind,Name,SchemaName,Status,Issue,Trim(Definition),Tokens[First].Line,Node);
      if (Status='declared header') and (Kind='table') then InspectColumns(BodyAt,Last,Name,SchemaName,Row.GetValue<string>('id'),Node);
      if (Status='declared header') and (Kind<>'schema') and (SchemaName<>'unknown') then AddRow('schema',SchemaName,SchemaName,'qualifier reference','Schema qualifier in an object name; not a CREATE SCHEMA declaration.','',Tokens[First].Line,Node);
      First:=Last+1;
     end;
    end;
   end;
   for Value in AView.Document.GetValue<TJSONArray>('semantics.relationships') do begin
    Node:=Value as TJSONObject;
    if Node.GetValue<string>('rule')='single_table_sql_text_schema_unverified' then ReferenceNames.AddOrSetValue(Node.GetValue<string>('to'),Node.GetValue<string>('label'));
   end;
   for Value in AView.Document.GetValue<TJSONArray>('semantics.symbols') do begin
    Node:=Value as TJSONObject;if Node.GetValue<string>('kind')<>'sql_table' then Continue;
    Path:=Node.GetValue<string>('range.source');FileRow:=TJSONObject.Create.AddPair('sha256',Node.GetValue<string>('source_hash',''));
    if not ReferenceNames.TryGetValue(Node.GetValue<string>('key'),Name) then Name:=Node.GetValue<string>('name');
    try AddRow('table',Name,'unknown','inferred reference','Existing supported SQL text names this object; table/view identity, schema and definition are unverified.','',Node.GetValue<Integer>('range.line'),Node.GetValue<TJSONObject>('range'));finally FileRow.Free;end;
   end;
   for Value in Rows do begin Row:=Value as TJSONObject;if Row.GetValue<string>('status')<>'declared header' then Continue;Key:=Row.GetValue<string>('kind')+'|'+Row.GetValue<string>('name');Count:=0;Counts.TryGetValue(Key,Count);Counts.AddOrSetValue(Key,Count+1);end;
   for Value in Rows do begin Row:=Value as TJSONObject;if Row.GetValue<string>('status')<>'declared header' then Continue;Key:=Row.GetValue<string>('kind')+'|'+Row.GetValue<string>('name');Count:=Counts[Key];Row.RemovePair('definition_count').Free;Row.AddPair('definition_count',TJSONNumber.Create(Count));if Count>1 then begin Row.RemovePair('reason').Free;Row.AddPair('reason','Multiple captured declarations have this exact kind/spelling. Migration order and effective definition are unresolved; no last-definition winner is selected.');end;end;
   ResolveKeys;ResolveStored;
  except Result.Free;raise;end;
 finally ReferenceNames.Free;Counts.Free;Tokens.Free;end;
end;
class function TDPHDatabaseSchema.Describe(ARow:TJSONObject):string;
var ColumnFacts,CountText:string;Link,Member:TJSONValue;
begin
 ColumnFacts:='';CountText:='';
 if MatchText(ARow.GetValue<string>('kind'),['procedure','function','trigger']) then begin
  ColumnFacts:='Stored object: '+ARow.GetValue<string>('name')+' | Header: '+ARow.GetValue<string>('header_operation')+sLineBreak+'Language: '+ARow.GetValue<string>('language')+' | Returns: '+ARow.GetValue<string>('returns')+sLineBreak+'Ordered parameters:'+sLineBreak;
  for Member in ARow.GetValue<TJSONArray>('parameters') do ColumnFacts:=ColumnFacts+Member.GetValue<Integer>('position').ToString+': '+Member.GetValue<string>('name')+' | '+Member.GetValue<string>('mode')+' | '+Member.GetValue<string>('declared_type')+' | default '+Member.GetValue<string>('default')+' | line '+Member.GetValue<Integer>('line').ToString+sLineBreak;
  if ARow.GetValue<string>('kind')='trigger' then ColumnFacts:=ColumnFacts+'Trigger table: '+ARow.GetValue<string>('trigger_table')+sLineBreak+'Timing: '+ARow.GetValue<string>('timing')+' | Events: '+ARow.GetValue<string>('events')+' | Scope: '+ARow.GetValue<string>('scope')+sLineBreak+'WHEN (unevaluated text): '+ARow.GetValue<string>('when')+sLineBreak;
  ColumnFacts:=ColumnFacts+'Relationships: '+ARow.GetValue<string>('relationship_status')+' | Captured definitions/overloads: '+ARow.GetValue<Integer>('definition_count').ToString+sLineBreak+ARow.GetValue<string>('conflict','')+sLineBreak+ARow.GetValue<string>('dependency_note')+sLineBreak;
  for Link in ARow.GetValue<TJSONArray>('links') do ColumnFacts:=ColumnFacts+Link.GetValue<string>('role')+': '+Link.GetValue<string>('reference')+' | '+Link.GetValue<string>('state')+' | line '+Link.GetValue<Integer>('line').ToString+sLineBreak;
  ColumnFacts:=ColumnFacts+sLineBreak+'CAPTURED BODY (comments and literals omitted)'+sLineBreak+ARow.GetValue<string>('body')+sLineBreak+sLineBreak+'A procedure groups database work; a function declares a returned value; a trigger declares work associated with an event. These are source declarations, not observed executions. Follow relationship opens captured evidence; name matches do not prove runtime binding. Body grammar, dynamic SQL, expression calls, permissions and deployed effects remain unverified.'+sLineBreak+sLineBreak;
 end;
 if ARow.GetValue<string>('kind')='index' then begin
  ColumnFacts:='Indexed table: '+ARow.GetValue<string>('table')+sLineBreak+'Unique declared: '+ARow.GetValue('unique').Value+' | Method: '+ARow.GetValue<string>('method')+' | Storage kind: '+ARow.GetValue<string>('storage_kind')+sLineBreak+'Ordered index members:'+sLineBreak;
  for Member in ARow.GetValue<TJSONArray>('members') do ColumnFacts:=ColumnFacts+Member.GetValue<Integer>('position').ToString+': '+Member.GetValue<string>('expression')+' | order '+Member.GetValue<string>('sort')+' | nulls '+Member.GetValue<string>('nulls')+sLineBreak;
  ColumnFacts:=ColumnFacts+'Included columns: '+ARow.GetValue<TJSONArray>('included_columns').ToJSON+sLineBreak+'Predicate (captured text): '+ARow.GetValue<string>('predicate')+sLineBreak+
   'Storage options (captured text): '+ARow.GetValue<string>('storage_options')+' | Tablespace: '+ARow.GetValue<string>('tablespace')+sLineBreak+'Unique null treatment: '+ARow.GetValue<string>('null_treatment')+sLineBreak+
   'CONCURRENTLY: '+ARow.GetValue('concurrently').Value+' | IF NOT EXISTS: '+ARow.GetValue('conditional').Value+' | ONLY: '+ARow.GetValue('only_table').Value+sLineBreak+
   'Relationships: '+ARow.GetValue<string>('relationship_status')+' | Captured declarations: '+ARow.GetValue<Integer>('definition_count').ToString+sLineBreak+ARow.GetValue<string>('conflict','')+sLineBreak+
   'Captured SQL table references: '+ARow.GetValue<Integer>('usage_reference_count').ToString+' | shown: '+ARow.GetValue<Integer>('usage_shown_count').ToString+sLineBreak+ARow.GetValue<string>('usage_note')+sLineBreak;
  for Link in ARow.GetValue<TJSONArray>('links') do ColumnFacts:=ColumnFacts+Link.GetValue<string>('role')+' '+Link.GetValue<Integer>('position').ToString+': '+Link.GetValue<string>('reference')+' | '+Link.GetValue<string>('state')+sLineBreak;
  ColumnFacts:=ColumnFacts+'An index is a declared access structure that may affect reads, writes and storage. Included columns and a predicate describe additional structure; expressions and storage options are retained without evaluation. No query plan, timing, index use, physical size or performance recommendation is inferred.'+sLineBreak+sLineBreak;
 end;
 if ARow.GetValue<string>('kind')='key' then begin
  ColumnFacts:='Key type: '+ARow.GetValue<string>('key_kind')+sLineBreak+'Ordered local columns: '+ARow.GetValue<TJSONArray>('members').ToJSON+sLineBreak+
   'Referenced table: '+ARow.GetValue<string>('reference_table')+sLineBreak+'Ordered referenced columns: '+ARow.GetValue<TJSONArray>('reference_columns').ToJSON+sLineBreak+
   'Relationships: '+ARow.GetValue<string>('relationship_status')+sLineBreak+ARow.GetValue<string>('reference_note','')+sLineBreak+ARow.GetValue<string>('conflict','')+sLineBreak+ARow.GetValue<string>('name_conflict','')+sLineBreak+
   'Referential actions: '+ARow.GetValue<string>('referential_actions')+sLineBreak;
  for Link in ARow.GetValue<TJSONArray>('links') do ColumnFacts:=ColumnFacts+Link.GetValue<string>('role')+' '+Link.GetValue<Integer>('position').ToString+': '+Link.GetValue<string>('reference')+' | '+Link.GetValue<string>('state')+' | '+Link.GetValue<string>('target_id','no link')+sLineBreak;
  ColumnFacts:=ColumnFacts+'Primary identifies a row; unique declares a distinct column combination; foreign declares a reference to another table. Links identify captured evidence only; target uniqueness, compatibility and deployed enforcement are unverified.'+sLineBreak+sLineBreak;
 end;
 if ARow.GetValue<string>('status')='declared header' then CountText:='Captured declarations with exact kind/spelling: '+ARow.GetValue('definition_count').Value+sLineBreak;
 if ARow.GetValue<string>('kind')='column' then ColumnFacts:='Declared type: '+ARow.GetValue<string>('declared_type')+sLineBreak+'Nullability declaration: '+ARow.GetValue<string>('nullability')+sLineBreak+
  'Default declaration: '+ARow.GetValue<string>('default')+sLineBreak+'Inline constraints (captured text):'+sLineBreak+ARow.GetValue<string>('constraints')+sLineBreak+
  'Table: '+ARow.GetValue<string>('table')+' | Captured table declaration: '+ARow.GetValue<string>('declaration_id')+sLineBreak+
  'Not declared means absent from this entry, not an effective database default. Key implications, referenced membership and enforcement require separate verification.'+sLineBreak+sLineBreak;
 Result:=UpperCase(ARow.GetValue<string>('kind'))+' '+ARow.GetValue<string>('name')+sLineBreak+
  ColumnFacts+
  'Evidence: '+ARow.GetValue<string>('status')+' | Schema: '+ARow.GetValue<string>('schema')+sLineBreak+
  ARow.GetValue<string>('reason')+sLineBreak+CountText+
  'Generation '+ARow.GetValue('generation_id').Value+' | '+ARow.GetValue<string>('source')+':'+ARow.GetValue<TJSONObject>('range').GetValue('line').Value+sLineBreak+
  'SHA256 '+ARow.GetValue<string>('source_hash')+sLineBreak+ARow.GetValue<string>('range_precision')+sLineBreak+sLineBreak+
  'CAPTURED DEFINITION WITH COMMENTS AND LITERALS OMITTED'+sLineBreak+ARow.GetValue<string>('definition')+sLineBreak+sLineBreak+
  'NEXT INVESTIGATION'+sLineBreak+'Ask the maintainer which approved schema script and migration order define the intended deployment. Attach approved missing files and reassess. A name used in SQL can denote a table or view; a qualifier does not prove a schema declaration. No current production object, privileges, dialect validity or business purpose is established. Open source requires attached unchanged source; original SQL may contain sensitive data.';
end;
end.
