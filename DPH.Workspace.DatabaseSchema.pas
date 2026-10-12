unit DPH.Workspace.DatabaseSchema;
interface
uses System.JSON,DPH.Workspace.Model;
type TDPHDatabaseSchema=class
 class function Inspect(AView:TDPHWorkspaceView):TJSONObject;static;
 class function Describe(ARow:TJSONObject):string;static;
end;
implementation
uses System.SysUtils,System.StrUtils,System.Classes,System.Generics.Collections;
type TSchemaToken=record Text:string;Line:Integer;Identifier:Boolean;end;
class function TDPHDatabaseSchema.Inspect(AView:TDPHWorkspaceView):TJSONObject;
var Rows,Nodes:TJSONArray;FileValue,NodeValue,Value:TJSONValue;FileRow,Node,Row:TJSONObject;
 Tokens:TList<TSchemaToken>;Counts:TDictionary<string,Integer>;ReferenceNames:TDictionary<string,string>;Token:TSchemaToken;
 SQL,Path,Text,Name,SchemaName,Kind,Status,Issue,Definition,Key:string;
 Position,Start,Line,Depth,I,J,First,Last,NameAt,BodyAt,Count,Ordinal:Integer;
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
begin
 Result:=TJSONObject.Create;Rows:=TJSONArray.Create;Result.AddPair('rows',Rows);
 Result.AddPair('qualification','Captured schema evidence only. CREATE headers declare intended objects; body grammar, column/constraint semantics, deployment order, dialect, existence and current production schema are unverified. SQL references do not prove object definitions. No SQL or target application is executed. Comments and string literals are omitted from displayed definitions; original source/cache remains unchanged. Unsupported statements are explicit gaps. Quoted identifier spelling is preserved; cross-dialect identity is not guessed.');
 Tokens:=TList<TSchemaToken>.Create;Counts:=TDictionary<string,Integer>.Create;ReferenceNames:=TDictionary<string,string>.Create;Ordinal:=0;
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
     SQL:=Node.GetValue<string>('value');Tokens.Clear;Position:=1;Line:=Node.GetValue<Integer>('line',1);Issue:='';
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
      if CharInSet(C,['''','"','[','`']) then begin
       Quoted:=C<>'''';Closing:=C;if C='[' then Closing:=']';Inc(Position);Closed:=False;
       while Position<=Length(SQL) do begin
        if SQL[Position]=#10 then Inc(Line);
        if SQL[Position]=Closing then begin Inc(Position);if (Position<=Length(SQL)) and (SQL[Position]=Closing) then Inc(Position) else begin Closed:=True;Break;end;end else Inc(Position);
       end;
       if not Closed then begin Issue:='Unterminated string or quoted identifier';Break;end;
       Token.Identifier:=Quoted and (Position-Start>2);if Quoted then Token.Text:=Copy(SQL,Start,Position-Start) else Token.Text:='[literal omitted]';
      end else if CharInSet(C,['A'..'Z','a'..'z','_']) then begin
       Inc(Position);while (Position<=Length(SQL)) and CharInSet(SQL[Position],['A'..'Z','a'..'z','0'..'9','_','$']) do Inc(Position);
       Token.Text:=Copy(SQL,Start,Position-Start);Token.Identifier:=True;
      end else begin Token.Text:=C;Inc(Position);end;
      Tokens.Add(Token);if Tokens.Count>100000 then Issue:='SQL resource exceeds 100000-token limit';
     end;
     if Issue<>'' then begin AddRow('gap',Path,'unknown','unsupported',Issue,'',Line,Node);Continue;end;
     First:=0;
     while First<Tokens.Count do begin
      Last:=First;while (Last<Tokens.Count) and (Tokens[Last].Text<>';') do Inc(Last);
      if Last=First then begin Inc(First);Continue;end;
      Kind:='gap';Name:='statement at line '+IntToStr(Tokens[First].Line);SchemaName:='unknown';Status:='unsupported';Issue:='Unsupported SQL statement; no object definition inferred.';Definition:='';Valid:=True;
      if SameText(Tokens[First].Text,'CREATE') then begin
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
  except Result.Free;raise;end;
 finally ReferenceNames.Free;Counts.Free;Tokens.Free;end;
end;
class function TDPHDatabaseSchema.Describe(ARow:TJSONObject):string;
begin
 Result:=UpperCase(ARow.GetValue<string>('kind'))+' '+ARow.GetValue<string>('name')+sLineBreak+
  'Evidence: '+ARow.GetValue<string>('status')+' | Schema: '+ARow.GetValue<string>('schema')+sLineBreak+
  ARow.GetValue<string>('reason')+sLineBreak+'Captured declarations with exact kind/spelling: '+ARow.GetValue('definition_count').Value+sLineBreak+
  'Generation '+ARow.GetValue('generation_id').Value+' | '+ARow.GetValue<string>('source')+':'+ARow.GetValue<TJSONObject>('range').GetValue('line').Value+sLineBreak+
  'SHA256 '+ARow.GetValue<string>('source_hash')+sLineBreak+ARow.GetValue<string>('range_precision')+sLineBreak+sLineBreak+
  'CAPTURED DEFINITION WITH COMMENTS AND LITERALS OMITTED'+sLineBreak+ARow.GetValue<string>('definition')+sLineBreak+sLineBreak+
  'NEXT INVESTIGATION'+sLineBreak+'Ask the maintainer which approved schema script and migration order define the intended deployment. Attach approved missing files and reassess. A name used in SQL can denote a table or view; a qualifier does not prove a schema declaration. No current production object, privileges, dialect validity or business purpose is established. Open source requires attached unchanged source; original SQL may contain sensitive data.';
end;
end.
