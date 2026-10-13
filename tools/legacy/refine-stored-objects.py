from pathlib import Path
r=Path.cwd();p=r/'DPH.Workspace.DatabaseSchema.pas';s=p.read_text()
a=s.index('  function TypeSupported(');b=s.index('  procedure ParameterEntry',a)
s=s[:a]+'''  function TypeSupported(AStart,AStop:Integer):Boolean;
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
'''+s[b:]
s=s.replace('QuotedBody,Parenthesized:Boolean;', 'QuotedBody,Parenthesized,ComplexScope:Boolean;')
s=s.replace("   if Problem='' then ObjectName:=ReadName(P,AEnd,Tokens);\n   if ObjectName.Contains('.') then Qualifier:=Copy(ObjectName,1,LastDelimiter('.',ObjectName)-1);", "   if Problem='' then begin Q:=P;ObjectName:=ReadName(P,AEnd,Tokens);if P-Q>2 then begin Qualifier:='';for ScanAt:=Q to P-3 do Qualifier:=Qualifier+Tokens[ScanAt].Text;end;end;")
s=s.replace("    Inc(Q);\n   end;\n   if BodyLast<0", "    if (BlockDepth>128) then begin Problem:='Stored-object nesting exceeds 128';Break;end;\n    if SameText(Tokens[Q].Text,'END') and (Q+1<Tokens.Count) and SameText(Tokens[Q+1].Text,'CASE') then Inc(Q);\n    Inc(Q);\n   end;\n   if BodyLast<0")
s=s.replace('   Q:=0;\n   while Q<BodyTokens.Count', "   ComplexScope:=False;for TokenValue in BodyTokens do if SameText(TokenValue.Text,'WITH') then ComplexScope:=True;\n   Q:=0;\n   while Q<BodyTokens.Count")
s=s.replace("      if (Problem='') and not ((Role='table reference')", "      if (Problem='') and not ((Role='table reference') and ComplexScope) and not ((Role='table reference')")
p.write_bytes(s.replace('\n','\r\n').encode())
p=r/'tests/DPH.Tests.DatabaseStoredObjects.dpr';s=p.read_text()
s=s.replace("'TFile.ReadAllText(''stored.sql'');", "'TFile.ReadAllText(''stored-limits.sql''); TFile.ReadAllText(''stored.sql'');")
s=s.replace(" 'CREATE PROCEDURE EmptyDefault", " 'CREATE PROCEDURE CTERef () AS BEGIN WITH Data AS (SELECT a FROM Data.Target) SELECT a FROM Data; END;',\n 'CREATE PROCEDURE TypeTail (item INTEGER MYSTERY) AS BEGIN SELECT 1; END;',\n 'CREATE PROCEDURE EmptyDefault")
at=s.index(' SourceHash:=THashSHA2')
s=s[:at]+''' ColumnCase:='CREATE PROCEDURE LimitRefs () AS BEGIN ';
 for I:=1 to 1100 do ColumnCase:=ColumnCase+'SELECT a FROM Data.Target; ';
 ColumnCase:=ColumnCase+'END;';TFile.WriteAllText(TPath.Combine(Fixture,'stored-limits.sql'),ColumnCase,TEncoding.UTF8);
'''+s[at:]
s=s.replace("['EmptyDefault','DuplicateParam'", "['TypeTail','EmptyDefault','DuplicateParam'")
at=s.index(" Check(Find('HiddenStored'")
s=s[:at]+''' Check(Find('"Quoted.Procedure"','declared stored object').GetValue<string>('schema')='unknown','Dot inside quoted routine name is not a schema separator');
 Check(not Find('CTERef','declared stored object').GetValue<TJSONArray>('links').ToJSON.Contains('target_id'),'CTE scope prevents guessed table binding');
 Check(Find('LimitRefs','declared stored object').GetValue<TJSONArray>('dependencies').Count=1000,'Stored dependency extraction bounded to 1000 entries');
 Check(Find('LimitRefs','declared stored object').GetValue<string>('dependency_note').Contains('limited to 1000'),'Stored dependency limit explicitly explained');
'''+s[at:]
s=s.replace('Database indexes validation passed:', 'Database stored objects validation passed:')
p.write_bytes(s.replace('\n','\r\n').encode())
print('Stored type, scope, name and bound cases refined')
