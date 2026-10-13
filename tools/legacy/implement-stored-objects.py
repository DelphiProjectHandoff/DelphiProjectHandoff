from pathlib import Path
r=Path.cwd();p=r/'DPH.Workspace.DatabaseSchema.pas';s=p.read_text(encoding='utf-8-sig')
s=s.replace('Text:string;Line:Integer;Identifier:Boolean;', 'Text,Body:string;Line:Integer;Identifier:Boolean;')
start=s.index('     SQL:=Node.GetValue<string>(\'value\');Tokens.Clear;')
end=s.index("     if Issue<>'' then begin AddRow('gap'",start)
lex=s[start:end]
lex=lex[lex.index('     while (Position<=Length(SQL))'):]
lex=lex.replace('Tokens.Add(Token);if Tokens.Count>100000','ATokens.Add(Token);if ATokens.Count>100000')
lex=lex.replace("      if CharInSet(C,[''''", "      if CharInSet(C,[''''") # keep original quote syntax
needle="      if CharInSet(C,['''','\"','[','`']) then begin"
assert needle in lex
lex=lex.replace(needle,"""      if C='$' then begin
       J:=Position+1;while (J<=Length(SQL)) and CharInSet(SQL[J],['A'..'Z','a'..'z','0'..'9','_']) do Inc(J);
       if (J<=Length(SQL)) and (SQL[J]='$') and ((J=Position+1) or not CharInSet(SQL[Position+1],['0'..'9'])) then begin
        Delimiter:=Copy(SQL,Position,J-Position+1);Position:=J+1;Start:=Position;ClosingAt:=PosEx(Delimiter,SQL,Position);
        if ClosingAt=0 then begin Issue:='Unterminated dollar-quoted body';Break;end;
        Token.Text:='[literal omitted]';Token.Body:=Copy(SQL,Start,ClosingAt-Start);
        while Position<ClosingAt do begin if SQL[Position]=#10 then Inc(Line);Inc(Position);end;Inc(Position,Length(Delimiter));
        ATokens.Add(Token);if ATokens.Count>100000 then Issue:='SQL resource exceeds 100000-token limit';Continue;
       end;
      end;
"""+needle)
lex=lex.replace("else Token.Text:='[literal omitted]';", "else begin Token.Text:='[literal omitted]';Token.Body:=StringReplace(Copy(SQL,Start+1,Position-Start-2),'''''''','''',[rfReplaceAll]);end;")
tokenizer=""" procedure Tokenize(const SQL:string;BaseLine:Integer;ATokens:TList<TSchemaToken>;out Issue:string);
 var Position,Start,Line,Depth,J,ClosingAt:Integer;C,Closing:Char;Closed,Quoted:Boolean;Token:TSchemaToken;Delimiter:string;
 begin
  ATokens.Clear;Position:=1;Line:=BaseLine;Issue:='';
  if Length(SQL)>2*1024*1024 then Issue:='SQL resource exceeds 2 MiB character inspection limit';
"""+lex+" end;\n"
s=s[:start]+"     SQL:=Node.GetValue<string>('value');Tokenize(SQL,Node.GetValue<Integer>('line',1),Tokens,Issue);\n"+s[end:]
at=s.index(' procedure InspectColumns(');s=s[:at]+tokenizer+s[at:]
stored=r''' function InspectStored(AFirst:Integer;var AEnd:Integer;ARange:TJSONObject):Boolean;
 var P,Q,N,BodyFirst,BodyLast,BlockDepth,BracketDepth,ParamFirst,ParamLast,TypeFirst,DefaultAt,Order,ScanAt:Integer;
     ObjectKind,ObjectName,Qualifier,Problem,LanguageName,ReturnType,BodyText,BodyIssue,TriggerTable,Timing,Scope,Events,WhenText,Mode,ParamName,ParamType,DefaultText,TargetName,Role,DependencyNote,HeaderOperation:string;
     Params,Dependencies:TJSONArray;ParamRow,Dependency:TJSONObject;BodyTokens:TList<TSchemaToken>;Seen:TDictionary<string,Boolean>;TokenValue:TSchemaToken;QuotedBody,Parenthesized:Boolean;
  function Span(AStart,AStop:Integer):string;
  var T:Integer;
  begin Result:='';for T:=AStart to AStop-1 do begin if Length(Result)>8000 then Exit(Result+' [display truncated]');if Result<>'' then Result:=Result+' ';Result:=Result+Tokens[T].Text;end;end;
  function ReadName(var Cursor:Integer;Limit:Integer;Source:TList<TSchemaToken>):string;
  var Parts:Integer;
  begin
   Result:='';Parts:=0;
   repeat
    if (Cursor>=Limit) or not Source[Cursor].Identifier then begin Problem:='Missing qualified identifier';Exit;end;
    if Result<>'' then Result:=Result+'.';Result:=Result+Source[Cursor].Text;Inc(Cursor);Inc(Parts);
    if (Cursor<Limit) and (Source[Cursor].Text='.') then Inc(Cursor) else Break;
   until False;
   if Parts>3 then Problem:='Identifier has more than three parts';
  end;
  function TypeSupported(AStart,AStop:Integer):Boolean;
  var T,B:Integer;
  begin
   Result:=False;if (AStart>=AStop) or not Tokens[AStart].Identifier or MatchText(Tokens[AStart].Text,['AS','RETURNS','LANGUAGE','DEFAULT','BEGIN','TABLE']) then Exit;
   B:=0;
   for T:=AStart to AStop-1 do begin
    if Tokens[T].Text='(' then Inc(B) else if Tokens[T].Text=')' then Dec(B);
    if (B<0) or (B>16) or MatchText(Tokens[T].Text,['[literal omitted]',';','=','@','DEFAULT','AS','RETURNS','BEGIN','LANGUAGE']) then Exit;
    if not Tokens[T].Identifier and not MatchText(Tokens[T].Text,['.',',','(',')','[]']) and not TryStrToInt(Tokens[T].Text,N) then Exit;
   end;Result:=B=0;
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
   if Dependencies.Count>=1000 then begin DependencyNote:='Dependency display limited to 1000 entries; coverage incomplete.';Exit;end;
   Dependency:=TJSONObject.Create.AddPair('role',ARole).AddPair('reference',AName).AddPair('line',TJSONNumber.Create(ALine)).AddPair('state',AState);Dependencies.AddElement(Dependency);
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
    Inc(Q);
   end;
   if BodyLast<0 then begin Problem:='Unterminated stored-object block; remaining resource held as a gap';AEnd:=Tokens.Count;end
   else begin AEnd:=BodyLast;if (AEnd<Tokens.Count) and (Tokens[AEnd].Text<>';') and not SameText(Tokens[AEnd].Text,'GO') then begin Problem:='Unsupported tail after stored-object block';while (AEnd<Tokens.Count) and (Tokens[AEnd].Text<>';') do Inc(AEnd);end;end;
   Break;
  end;
  Params:=TJSONArray.Create;Dependencies:=TJSONArray.Create;BodyTokens:=TList<TSchemaToken>.Create;Seen:=TDictionary<string,Boolean>.Create;
  try
   if Problem='' then ObjectName:=ReadName(P,AEnd,Tokens);
   if ObjectName.Contains('.') then Qualifier:=Copy(ObjectName,1,LastDelimiter('.',ObjectName)-1);
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
   Q:=0;
   while Q<BodyTokens.Count do begin
    Role:='';ScanAt:=Q;
    if MatchText(BodyTokens[Q].Text,['FROM','JOIN','UPDATE']) then begin Role:='table reference';Inc(Q);end
    else if (Q+1<BodyTokens.Count) and SameText(BodyTokens[Q].Text,'INTO') and SameText(BodyTokens[Q-1].Text,'INSERT') then begin Role:='table reference';Inc(Q);end
    else if MatchText(BodyTokens[Q].Text,['CALL','EXEC']) then begin Role:='procedure call';Inc(Q);end
    else if (Q+1<BodyTokens.Count) and SameText(BodyTokens[Q].Text,'EXECUTE') and SameText(BodyTokens[Q+1].Text,'PROCEDURE') then begin Role:='procedure call';Inc(Q,2);end
    else if SameText(BodyTokens[Q].Text,'EXECUTE') then AddDependency('unresolved dynamic execution','','dynamic SQL or dialect-specific execution; no target guessed',BodyTokens[Q].Line);
    if Role<>'' then begin
     if (Q<BodyTokens.Count) and BodyTokens[Q].Identifier and not MatchText(BodyTokens[Q].Text,['SELECT','SET','ONLY']) then begin
      TargetName:=ReadName(Q,BodyTokens.Count,BodyTokens);
      if (Problem='') and not ((Role='table reference') and (Q<BodyTokens.Count) and (BodyTokens[Q].Text='(')) then AddDependency(Role,TargetName,'captured reference',BodyTokens[ScanAt].Line)
      else AddDependency('unresolved dependency',TargetName,'complex reference; no target guessed',BodyTokens[ScanAt].Line);
      Problem:='';
     end else AddDependency('unresolved dependency','','complex reference; no target guessed',BodyTokens[ScanAt].Line);
    end;
    if Dependencies.Count>=1000 then begin DependencyNote:='Dependency display limited to 1000 entries; coverage incomplete.';Break;end;
    Inc(Q);
   end;
   AddRow(ObjectKind,ObjectName,Qualifier,'declared stored object','Captured definition and supported header structure only. Body grammar, permissions, overload selection, migration order and deployed behavior remain unverified.',Span(AFirst,AEnd),Tokens[AFirst].Line,ARange);
   Row.AddPair('parameters',Params).AddPair('returns',ReturnType).AddPair('language',LanguageName).AddPair('body',BodyText).AddPair('dependencies',Dependencies).AddPair('dependency_note',DependencyNote).AddPair('header_operation',HeaderOperation).AddPair('trigger_table',TriggerTable).AddPair('timing',Timing).AddPair('events',Events).AddPair('scope',Scope).AddPair('when',WhenText).AddPair('quoted_body',TJSONBool.Create(QuotedBody));Params:=nil;Dependencies:=nil;
  finally Seen.Free;BodyTokens.Free;Params.Free;Dependencies.Free;end;
 end;
'''
at=s.index(' procedure ResolveKeys;');s=s[:at]+stored+s[at:]
s=s.replace("       if InspectIndex(First,Last,Node)","       if InspectStored(First,Last,Node) then begin First:=Last+1;Continue;end;\n       if InspectIndex(First,Last,Node)")
# Stored relationships have their own exact multiplicity lookup, so tables/views and overloaded routines remain ambiguous.
resolve=r''' procedure ResolveStored;
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
     Link:=TJSONObject.Create.AddPair('role',Dependency.GetValue<string>('role')).AddPair('reference',Dependency.GetValue<string>('reference')).AddPair('position',TJSONNumber.Create(Links.Count+1)).AddPair('line',Dependency.GetValue('line').Clone as TJSONValue);Links.AddElement(Link);
     N:=0;if TargetKey<>'' then Multiplicity.TryGetValue(TargetKey,N);
     if N=1 then begin Target:=Index[TargetKey];Link.AddPair('state','unique captured name match; binding unverified').AddPair('target_id',Target.GetValue<string>('id'));end
     else begin Complete:=False;if TargetKey='' then StateText:=Dependency.GetValue<string>('state') else if N=0 then StateText:='missing captured declaration' else StateText:='ambiguous captured declarations or overloads';Link.AddPair('state',StateText);end;
    end;
    if Complete then StateText:='captured links complete; coverage unverified' else StateText:='relationship gaps';Item.AddPair('relationship_status',StateText);
   end;
  finally Multiplicity.Free;Index.Free;end;
 end;
'''
at=s.index(' procedure ResolveKeys;');s=s[:at]+resolve+s[at:]
s=s.replace('   ResolveKeys;','   ResolveKeys;ResolveStored;')
describe=r''' if MatchText(ARow.GetValue<string>('kind'),['procedure','function','trigger']) then begin
  ColumnFacts:='Stored object: '+ARow.GetValue<string>('name')+' | Header: '+ARow.GetValue<string>('header_operation')+sLineBreak+'Language: '+ARow.GetValue<string>('language')+' | Returns: '+ARow.GetValue<string>('returns')+sLineBreak+'Ordered parameters:'+sLineBreak;
  for Member in ARow.GetValue<TJSONArray>('parameters') do ColumnFacts:=ColumnFacts+Member.GetValue<Integer>('position').ToString+': '+Member.GetValue<string>('name')+' | '+Member.GetValue<string>('mode')+' | '+Member.GetValue<string>('declared_type')+' | default '+Member.GetValue<string>('default')+' | line '+Member.GetValue<Integer>('line').ToString+sLineBreak;
  if ARow.GetValue<string>('kind')='trigger' then ColumnFacts:=ColumnFacts+'Trigger table: '+ARow.GetValue<string>('trigger_table')+sLineBreak+'Timing: '+ARow.GetValue<string>('timing')+' | Events: '+ARow.GetValue<string>('events')+' | Scope: '+ARow.GetValue<string>('scope')+sLineBreak+'WHEN (unevaluated text): '+ARow.GetValue<string>('when')+sLineBreak;
  ColumnFacts:=ColumnFacts+'Relationships: '+ARow.GetValue<string>('relationship_status')+' | Captured definitions/overloads: '+ARow.GetValue<Integer>('definition_count').ToString+sLineBreak+ARow.GetValue<string>('conflict','')+sLineBreak+ARow.GetValue<string>('dependency_note')+sLineBreak;
  for Link in ARow.GetValue<TJSONArray>('links') do ColumnFacts:=ColumnFacts+Link.GetValue<string>('role')+': '+Link.GetValue<string>('reference')+' | '+Link.GetValue<string>('state')+' | line '+Link.GetValue<Integer>('line').ToString+sLineBreak;
  ColumnFacts:=ColumnFacts+sLineBreak+'CAPTURED BODY (comments and literals omitted)'+sLineBreak+ARow.GetValue<string>('body')+sLineBreak+sLineBreak+'A procedure groups database work; a function declares a returned value; a trigger declares work associated with an event. These are source declarations, not observed executions. Follow relationship opens captured evidence; name matches do not prove runtime binding. Body grammar, dynamic SQL, expression calls, permissions and deployed effects remain unverified.'+sLineBreak+sLineBreak;
 end;
'''
at=s.index(" if ARow.GetValue<string>('kind')='index' then begin",s.index('class function TDPHDatabaseSchema.Describe'));s=s[:at]+describe+s[at:]
p.write_bytes(s.replace('\n','\r\n').encode('utf-8'))
p=r/'DPH.UI.Main.fmx';s=p.read_text();s=s.replace("'index')","'index'\n'procedure'\n'function'\n'trigger')").replace("'declared index')","'declared index'\n'declared stored object')")
s=s.replace('Select a key or index for structure and evidence. Scroll commands sideways to Follow relationship. Missing targets remain gaps. SQL references do not prove index use. No SQL is executed.','Select a key, index or stored object for structure and evidence. Scroll commands sideways to Follow relationship. Missing targets remain gaps; source references do not prove execution. No SQL is executed.')
p.write_bytes(s.replace('\n','\r\n').encode())
p=r/'DPH.UI.Main.pas';s=p.read_text();s=s.replace("['key','index']","['key','index','procedure','function','trigger']")
s=s.replace("Row.GetValue<string>('storage_options',''),DatabaseSchemaFilter.Text.Trim)","Row.GetValue<string>('storage_options','')+' '+Row.GetValue<string>('language','')+' '+Row.GetValue<string>('returns','')+' '+Row.GetValue<string>('trigger_table','')+' '+Row.GetValue<string>('events','')+' '+Row.GetValue<string>('body','')+' '+Row.GetValue<string>('parameters',''),DatabaseSchemaFilter.Text.Trim)")
# Array-valued parameters are searched via their JSON representation, not a string cast.
s=s.replace("+' '+Row.GetValue<string>('parameters','')", "")
p.write_bytes(s.replace('\n','\r\n').encode())
print('Stored object source and IDE selectors updated')
