unit DPH.Parse.Lexer;

interface
uses DPH.Project.Source, DPH.Parse.Model;
type
  TDPHLexer = class
    class function Tokenize(ASource: TDPHSource; ADiagnostics: TDPHDiagnostics): TDPHTokens; static;
  end;
implementation
uses System.SysUtils, System.Classes, System.Generics.Collections;

class function TDPHLexer.Tokenize(ASource: TDPHSource; ADiagnostics: TDPHDiagnostics): TDPHTokens;
var Items: TList<TDPHToken>; T: TDPHToken; S: string; I, Start, Line, Column,
    StartLine, StartColumn, K,ExponentStart: Integer; Closed,ValidNumber: Boolean;
begin
  Items:=TList<TDPHToken>.Create;
  try
    S:=ASource.Text; I:=1; Line:=1; Column:=1;
    while I<=Length(S) do
    begin
      if Items.Count>=DPHMaxTokens then raise EReadError.Create('Token acquisition limit');
      Start:=I; StartLine:=Line; StartColumn:=Column; T:=Default(TDPHToken); Closed:=True; ValidNumber:=True;
      if CharInSet(S[I],[#9,#10,#13,' ']) then
      begin T.Kind:=tkSpace; repeat Inc(I); until (I>Length(S)) or not CharInSet(S[I],[#9,#10,#13,' ']); end
      else if (S[I]='/') and (I<Length(S)) and (S[I+1]='/') then
      begin T.Kind:=tkComment; while (I<=Length(S)) and not CharInSet(S[I],[#10,#13]) do Inc(I); end
      else if (S[I]='{') or ((S[I]='(') and (I<Length(S)) and (S[I+1]='*')) then
      begin
        T.Kind:=tkComment;
        if S[I]='{' then
        begin
          Inc(I); if (I<=Length(S)) and (S[I]='$') then T.Kind:=tkDirective;
          while (I<=Length(S)) and (S[I]<>'}') do Inc(I);
          Closed:=I<=Length(S); if Closed then Inc(I);
        end
        else
        begin
          Inc(I,2); if (I<=Length(S)) and (S[I]='$') then T.Kind:=tkDirective;
          while (I<Length(S)) and not ((S[I]='*') and (S[I+1]=')')) do Inc(I);
          Closed:=I<Length(S); if Closed then Inc(I,2) else I:=Length(S)+1;
        end;
      end
      else if S[I]='''' then
      begin
        T.Kind:=tkString; Inc(I); Closed:=False;
        while I<=Length(S) do
        begin
          if CharInSet(S[I],[#10,#13]) then Break;
          if S[I]='''' then
          begin
            Inc(I); if (I<=Length(S)) and (S[I]='''') then Inc(I)
            else begin Closed:=True; Break; end;
          end else Inc(I);
        end;
      end
      else if CharInSet(S[I],['A'..'Z','a'..'z','_','&']) or (Ord(S[I])>=128) then
      begin
        T.Kind:=tkIdentifier; Inc(I);
        while (I<=Length(S)) and (CharInSet(S[I],['A'..'Z','a'..'z','0'..'9','_']) or (Ord(S[I])>=128)) do Inc(I);
      end
      else if CharInSet(S[I],['0'..'9','$','%']) then
      begin
        T.Kind:=tkNumber; Inc(I); ValidNumber:=True;
        if CharInSet(S[Start],['$','%']) then
          while (I<=Length(S)) and CharInSet(S[I],['0'..'9','A'..'F','a'..'f','_']) do Inc(I)
        else while (I<=Length(S)) and CharInSet(S[I],['0'..'9','_']) do Inc(I);
        if CharInSet(S[Start],['$','%']) and (I=Start+1) then ValidNumber:=False;
        if S[Start]='%' then for K:=Start+1 to I-1 do if not CharInSet(S[K],['0','1','_']) then ValidNumber:=False;
        if (I<Length(S)) and (S[I]='.') and (S[I+1]<>'.') and CharInSet(S[I+1],['0'..'9']) then
        begin Inc(I); while (I<=Length(S)) and CharInSet(S[I],['0'..'9']) do Inc(I); end;
        if not CharInSet(S[Start],['$','%']) and (I<=Length(S)) and CharInSet(S[I],['e','E']) then
        begin Inc(I); if (I<=Length(S)) and CharInSet(S[I],['+','-']) then Inc(I);
          ExponentStart:=I;
          while (I<=Length(S)) and CharInSet(S[I],['0'..'9']) do Inc(I);
          if I=ExponentStart then ValidNumber:=False;
        end;
      end
      else
      begin
        T.Kind:=tkSymbol; Inc(I);
        if (I<=Length(S)) and ((Copy(S,Start,2)=':=') or (Copy(S,Start,2)='..') or
          (Copy(S,Start,2)='<=') or (Copy(S,Start,2)='>=') or (Copy(S,Start,2)='<>') or
          (Copy(S,Start,2)='(.') or (Copy(S,Start,2)='.)')) then Inc(I);
      end;
      T.Text:=Copy(S,Start,I-Start); T.Active:=daActive;
      T.Location.Source:=ASource.RelativePath; T.Location.StartByte:=ASource.ByteOffsets[Start-1];
      T.Location.EndByte:=ASource.ByteOffsets[I-1]; T.Location.Line:=StartLine; T.Location.Column:=StartColumn;
      if not Closed then ADiagnostics.Report('UNTERMINATED_TOKEN','Unterminated comment or string literal',T.Location,'error');
      if (T.Kind=tkNumber) and not ValidNumber then ADiagnostics.Report('INVALID_NUMBER','Malformed numeric literal',T.Location,'error');
      Items.Add(T);
      for K:=Start to I-1 do
        if S[K]=#10 then begin Inc(Line); Column:=1; end
        else if (S[K]=#13) and ((K=Length(S)) or (S[K+1]<>#10)) then begin Inc(Line); Column:=1; end
        else if S[K]<>#13 then Inc(Column);
    end;
    T:=Default(TDPHToken); T.Kind:=tkEOF; T.Active:=daActive;
    T.Location.Source:=ASource.RelativePath; T.Location.StartByte:=Length(ASource.Bytes);
    T.Location.EndByte:=Length(ASource.Bytes); T.Location.Line:=Line; T.Location.Column:=Column; Items.Add(T);
    Result:=Items.ToArray;
  finally Items.Free; end;
end;
end.
