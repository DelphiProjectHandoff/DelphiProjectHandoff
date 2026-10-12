unit DPH.Parse.Forms;

interface
uses System.SysUtils, DPH.Project.Source, DPH.Parse.Model;
type
  TDPHFormParser = class
  private
    FSource: TDPHSource;
    FResult: TDPHParseResult;
    FDiagnostics: TDPHDiagnostics;
    FPosition: Integer;
    function ReadUnsigned(ACount: Integer): UInt64;
    function ReadShort: string;
    function BinaryValue(ADepth: Integer): string;
    procedure BinaryObject(AParent, ADepth: Integer);
    procedure TextForm;
    function Add(const AKind,AName,AValue: string; AParent,AStart,AEnd: Integer; ABinary: Boolean): Integer;
  public
    function Parse(ASource: TDPHSource; ADiagnostics: TDPHDiagnostics): TDPHParseResult;
  end;
implementation
uses System.Classes, System.Generics.Collections, System.StrUtils;

function TDPHFormParser.Add(const AKind,AName,AValue: string; AParent,AStart,AEnd: Integer; ABinary: Boolean): Integer;
var Node: TDPHIRNode;
begin
  if FResult.Nodes.Count>=DPHMaxNodes then raise EReadError.Create('Form node limit');
  Node:=Default(TDPHIRNode); Node.Kind:=AKind; Node.Name:=AName; Node.Value:=AValue; Node.Parent:=AParent;
  if ABinary then
  begin Node.Location.Source:=FSource.RelativePath; Node.Location.StartByte:=AStart; Node.Location.EndByte:=AEnd; end
  else Node.Location:=FSource.Range(AStart,AEnd);
  Result:=FResult.Nodes.Add(Node);
end;

function TDPHFormParser.ReadUnsigned(ACount: Integer): UInt64;
var I: Integer;
begin
  if (ACount<0) or (FPosition>Length(FSource.Bytes)-ACount) then raise EReadError.Create('Truncated binary form');
  Result:=0;
  for I:=0 to ACount-1 do Result:=Result or (UInt64(FSource.Bytes[FPosition+I]) shl (8*I));
  Inc(FPosition,ACount);
end;
function TDPHFormParser.ReadShort: string;
var Count: Integer; Decoder: TEncoding;
begin
  Count:=ReadUnsigned(1);
  if FPosition>Length(FSource.Bytes)-Count then raise EReadError.Create('Truncated binary identifier');
  Decoder:=TMBCSEncoding.Create(65001,8,0,False);
  try Result:=Decoder.GetString(FSource.Bytes,FPosition,Count); finally Decoder.Free; end;
  Inc(FPosition,Count);
end;

function TDPHFormParser.BinaryValue(ADepth: Integer): string;
var Tag,Count,I,Start: Integer; Number: UInt64; Part: string; Decoder: TEncoding;
begin
  if ADepth>DPHMaxNesting then raise EReadError.Create('Binary value nesting limit');
  Tag:=ReadUnsigned(1); Result:='';
  case TValueType(Tag) of
    vaNull: Result:='null';
    vaFalse: Result:='False'; vaTrue: Result:='True'; vaNil: Result:='nil';
    vaInt8: Result:=IntToStr(ShortInt(ReadUnsigned(1)));
    vaInt16: Result:=IntToStr(SmallInt(ReadUnsigned(2)));
    vaInt32: Result:=IntToStr(Integer(ReadUnsigned(4)));
    vaInt64: Result:=IntToStr(Int64(ReadUnsigned(8)));
    vaIdent: Result:=ReadShort;
    vaString: Result:=QuotedStr(ReadShort);
    vaSet:
      begin Result:='['; repeat Part:=ReadShort; if Part='' then Break; Result:=Result+Part+','; until False; Result:=Result+']'; end;
    vaList:
      begin
        Result:='('; while (FPosition<Length(FSource.Bytes)) and (FSource.Bytes[FPosition]<>0) do
          Result:=Result+BinaryValue(ADepth+1)+' '; ReadUnsigned(1); Result:=Result+')';
      end;
    vaCollection:
      begin
        Result:='<';
        while (FPosition<Length(FSource.Bytes)) and (FSource.Bytes[FPosition]<>0) do
        begin
          if Integer(FSource.Bytes[FPosition])<>Ord(vaList) then Result:=Result+BinaryValue(ADepth+1);
          if ReadUnsigned(1)<>Ord(vaList) then raise EReadError.Create('Invalid collection item');
          Result:=Result+'item ';
          repeat Part:=ReadShort; if Part='' then Break;
            Result:=Result+Part+'='+BinaryValue(ADepth+1)+';'; until False;
          Result:=Result+'end ';
        end;
        ReadUnsigned(1); Result:=Result+'>';
      end;
    vaBinary,vaLString,vaUTF8String,vaWString:
      begin
        Number:=ReadUnsigned(4);
        if TValueType(Tag)=vaWString then Number:=Number*2;
        if Number>UInt64(NativeUInt(Length(FSource.Bytes)-FPosition)) then raise EReadError.Create('Binary property length exceeds captured input');
        Count:=Integer(Number); Start:=FPosition;
        if TValueType(Tag)=vaBinary then Result:='binary bytes='+IntToStr(Count)
        else
        begin
          if TValueType(Tag)=vaWString then Decoder:=TUnicodeEncoding.Create(False)
          else Decoder:=TMBCSEncoding.Create(65001,8,0,False);
          try Result:=QuotedStr(Decoder.GetString(FSource.Bytes,FPosition,Count)); finally Decoder.Free; end;
        end;
        FPosition:=Start+Count;
      end;
    vaExtended,vaSingle,vaDouble,vaCurrency,vaDate:
      begin
        case TValueType(Tag) of vaExtended: Count:=10; vaSingle: Count:=4; else Count:=8; end;
        Result:='encoded-float:';
        for I:=1 to Count do Result:=Result+IntToHex(ReadUnsigned(1),2);
      end;
  else raise EReadError.CreateFmt('Unsupported binary value tag %d',[Tag]);
  end;
  if Length(Result)>1024*1024 then raise EReadError.Create('Serialized property size limit');
end;

procedure TDPHFormParser.BinaryObject(AParent,ADepth: Integer);
var Start,Flags,Node,PropStart,PropertyNode: Integer; ClassName,Name,PropertyName,Value,Kind: string; ObjectNode: TDPHIRNode;
begin
  if ADepth>DPHMaxNesting then raise EReadError.Create('Binary object nesting limit');
  Start:=FPosition; Flags:=0;
  if (FPosition<Length(FSource.Bytes)) and ((FSource.Bytes[FPosition] and $F0)=$F0) then
  begin Flags:=ReadUnsigned(1) and $0F; if (Flags and 2)<>0 then BinaryValue(0); end;
  ClassName:=ReadShort; Name:=ReadShort;
  if ClassName='' then raise EReadError.Create('Binary class name missing');
  Kind:='object'; if (Flags and 1)<>0 then Kind:='inherited' else if (Flags and 4)<>0 then Kind:='inline';
  Node:=Add(Kind,Name,ClassName,AParent,Start,FPosition,True);
  repeat
    PropStart:=FPosition; PropertyName:=ReadShort; if PropertyName='' then Break;
    Value:=BinaryValue(0); PropertyNode:=Add('property',PropertyName,Value,Node,PropStart,FPosition,True);
    if (StartsText('On',PropertyName) or MatchText(PropertyName,['BeforePost','BeforeInsert','BeforeEdit','BeforeDelete','BeforeCancel','BeforeOpen'])) and not MatchText(Value,['nil','null']) then
      Add('event_binding',PropertyName,Value,PropertyNode,PropStart,FPosition,True);
  until False;
  while (FPosition<Length(FSource.Bytes)) and (FSource.Bytes[FPosition]<>0) do BinaryObject(Node,ADepth+1);
  if ReadUnsigned(1)<>0 then raise EReadError.Create('Missing binary child terminator');
  ObjectNode:=FResult.Nodes[Node]; ObjectNode.Location.EndByte:=FPosition; FResult.Nodes[Node]:=ObjectNode;
end;

procedure TDPHFormParser.TextForm;
var Stack: TList<Integer>; S,Line,Trimmed,Header,Name,ClassName,PropertyName,Value: string;
    Position,LineStart,LineEnd,Colon,Equals,Node,PropertyNode,ValueStart,Scan,Depth,LastNonSpace,RootCount: Integer;
    Quote: Boolean; C: Char; ObjectNode: TDPHIRNode;
begin
  Stack:=TList<Integer>.Create;
  try
    S:=FSource.Text; Position:=0; RootCount:=0;
    while Position<Length(S) do
    begin
      LineStart:=Position; LineEnd:=Position;
      FPosition:=FSource.ByteOffsets[LineStart];
      while (LineEnd<Length(S)) and not CharInSet(S[LineEnd+1],[#10,#13]) do Inc(LineEnd);
      Line:=Copy(S,LineStart+1,LineEnd-LineStart); Trimmed:=Trim(Line); Position:=LineEnd;
      while (Position<Length(S)) and CharInSet(S[Position+1],[#10,#13]) do Inc(Position);
      if Trimmed='' then Continue;
      if StartsText('object ',Trimmed) or StartsText('inherited ',Trimmed) or StartsText('inline ',Trimmed) then
      begin
        if Stack.Count>=DPHMaxNesting then raise EReadError.Create('Text form nesting limit');
        Header:=Copy(Trimmed,Pos(' ',Trimmed)+1,MaxInt); Colon:=Pos(':',Header);
        if Colon=0 then raise EReadError.Create('Object header lacks class');
        Name:=Trim(Copy(Header,1,Colon-1)); ClassName:=Trim(Copy(Header,Colon+1,MaxInt));
        if Pos(' [',ClassName)>0 then ClassName:=Copy(ClassName,1,Pos(' [',ClassName)-1);
        if Stack.Count=0 then
        begin Inc(RootCount); if RootCount>1 then raise EReadError.Create('Multiple form roots'); Node:=-1; end
        else Node:=Stack.Last;
        Node:=Add(Copy(Trimmed,1,Pos(' ',Trimmed)-1),Name,ClassName,Node,LineStart,LineEnd,False); Stack.Add(Node);
      end
      else if SameText(Trimmed,'end') then
      begin
        if Stack.Count=0 then raise EReadError.Create('Unexpected form end');
        ObjectNode:=FResult.Nodes[Stack.Last]; ObjectNode.Location.EndByte:=FSource.ByteOffsets[LineEnd];
        FResult.Nodes[Stack.Last]:=ObjectNode; Stack.Delete(Stack.Count-1);
      end
      else
      begin
        Equals:=Pos('=',Line);
        if (Equals=0) or (Stack.Count=0) then
        begin FDiagnostics.Report('FORM_LINE_UNSUPPORTED',Trimmed,FSource.Range(LineStart,LineEnd)); FResult.Complete:=False; Continue; end;
        PropertyName:=Trim(Copy(Line,1,Equals-1)); ValueStart:=LineStart+Equals; Scan:=ValueStart; Depth:=0; Quote:=False;
        while (Scan<Length(S)) and (S[Scan+1]<=' ') do Inc(Scan);
        LastNonSpace:=Scan;
        repeat
          if Scan>=Length(S) then Break;
          C:=S[Scan+1];
          if C='''' then
          begin if Quote and (Scan+1<Length(S)) and (S[Scan+2]='''') then Inc(Scan) else Quote:=not Quote; end
          else if not Quote then
          begin
            if CharInSet(C,['(','[','{','<']) then Inc(Depth)
            else if CharInSet(C,[')',']','}','>']) then Dec(Depth);
            if (Depth<0) or (Depth>DPHMaxNesting) then raise EReadError.Create('Serialized property delimiter limit');
            if (Depth=0) and CharInSet(C,[#10,#13]) and ((LastNonSpace=0) or (S[LastNonSpace]<>'+')) then Break;
          end;
          Inc(Scan);
          if C>' ' then LastNonSpace:=Scan;
          if Scan-ValueStart>1024*1024 then raise EReadError.Create('Text property size limit');
        until False;
        if Quote or (Depth<>0) then raise EReadError.Create('Unterminated serialized property');
        Value:=Trim(Copy(S,ValueStart+1,Scan-ValueStart)); Position:=Scan;
        PropertyNode:=Add('property',PropertyName,Value,Stack.Last,LineStart,Scan,False);
        if (StartsText('On',PropertyName) or MatchText(PropertyName,['BeforePost','BeforeInsert','BeforeEdit','BeforeDelete','BeforeCancel','BeforeOpen'])) and (Value<>'') and not SameText(Value,'nil') then
          Add('event_binding',PropertyName,Value,PropertyNode,LineStart,Scan,False);
      end;
    end;
    if Stack.Count<>0 then raise EReadError.Create('Form object was not closed');
    if FResult.Nodes.Count=0 then raise EReadError.Create('Form object missing');
  finally Stack.Free; end;
end;

function TDPHFormParser.Parse(ASource: TDPHSource; ADiagnostics: TDPHDiagnostics): TDPHParseResult;
var Location: TDPHRange;
begin
  FSource:=ASource; FDiagnostics:=ADiagnostics; FResult:=TDPHParseResult.Create;
  try
    try
      if ASource.EncodingName='binary-form' then
      begin FPosition:=4; BinaryObject(-1,0); if FPosition<>Length(ASource.Bytes) then raise EReadError.Create('Trailing binary form bytes'); end
      else if ASource.Decoded then TextForm else raise EReadError.Create('Form encoding is unavailable');
    except on E: Exception do
      begin
        FResult.Complete:=False; Location:=Default(TDPHRange); Location.Source:=ASource.RelativePath;
        Location.StartByte:=FPosition; Location.EndByte:=FPosition;
        FDiagnostics.Report('FORM_PARSE_ERROR',E.Message,Location,'error');
      end;
    end;
    Result:=FResult;
  except FResult.Free; raise; end;
end;
end.
