unit DPH.Project.Source;

interface

uses System.SysUtils, DPH.Parse.Model;

type
  TDPHSource = class
  public
    Path, RelativePath, SHA256, EncodingName, LineEndings, Text: string;
    Bytes: TBytes;
    ByteOffsets: TArray<Integer>;
    Decoded: Boolean;
    constructor Create(const APath, ARelativePath: string; ADiagnostics: TDPHDiagnostics;
      ACodePage: Integer = 0; ARaw: Boolean = False);
    function Range(AStartChar, AEndChar: Integer): TDPHRange;
  end;

implementation

uses System.Classes, System.IOUtils, System.Hash, System.Math, Winapi.Windows;

constructor TDPHSource.Create(const APath, ARelativePath: string;
  ADiagnostics: TDPHDiagnostics; ACodePage: Integer; ARaw: Boolean);
var Stream: TFileStream; Decoder: TEncoding; Hash: THashSHA2;
    Skip, I, Width, Position, CRLF, LF, CR: Integer; Encoded: TBytes;
    ResolvedPath: string; PathLength: Cardinal;
begin
  inherited Create;
  Path:=APath; RelativePath:=ARelativePath;
  Stream:=TFileStream.Create(APath,fmOpenRead or fmShareDenyNone);
  try
    SetLength(ResolvedPath,32768);
    PathLength:=GetFinalPathNameByHandle(Stream.Handle,PChar(ResolvedPath),Length(ResolvedPath),0);
    if (PathLength=0) or (PathLength>=Cardinal(Length(ResolvedPath))) then raise EReadError.Create('Cannot verify opened source path');
    SetLength(ResolvedPath,PathLength);
    if ResolvedPath.StartsWith('\\?\UNC\') then ResolvedPath:='\\'+Copy(ResolvedPath,9,MaxInt)
    else if ResolvedPath.StartsWith('\\?\') then Delete(ResolvedPath,1,4);
    if not SameFileName(TPath.GetFullPath(APath),ResolvedPath) then raise EReadError.Create('Opened source resolves through an alias or reparse path');
    if Stream.Size>DPHMaxSourceBytes then raise EReadError.Create('Source exceeds 16 MiB acquisition limit');
    SetLength(Bytes,Stream.Size);
    if Length(Bytes)>0 then Stream.ReadBuffer(Bytes,Length(Bytes));
    if Stream.Size<>Length(Bytes) then raise EReadError.Create('Source size changed during acquisition');
  finally Stream.Free; end;
  Hash:=THashSHA2.Create; Hash.Update(Bytes); SHA256:=Hash.HashAsString;
  if ARaw then begin EncodingName:='opaque-binary'; Exit; end;
  Skip:=0;
  if (Length(Bytes)>=4) and (Bytes[0]=$54) and (Bytes[1]=$50) and (Bytes[2]=$46) and (Bytes[3]=$30) then
  begin EncodingName:='binary-form'; Exit; end;
  if (Length(Bytes)>=3) and (Bytes[0]=$EF) and (Bytes[1]=$BB) and (Bytes[2]=$BF) then
  begin Decoder:=TMBCSEncoding.Create(65001,8,0,False); Skip:=3; EncodingName:='UTF-8 BOM'; end
  else if (Length(Bytes)>=2) and (Bytes[0]=$FF) and (Bytes[1]=$FE) then
  begin Decoder:=TUnicodeEncoding.Create(False); Skip:=2; EncodingName:='UTF-16 LE'; end
  else if (Length(Bytes)>=2) and (Bytes[0]=$FE) and (Bytes[1]=$FF) then
  begin Decoder:=TBigEndianUnicodeEncoding.Create(False); Skip:=2; EncodingName:='UTF-16 BE'; end
  else if ACodePage<>0 then begin Decoder:=TEncoding.GetEncoding(ACodePage); EncodingName:='CP'+IntToStr(ACodePage); end
  else begin Decoder:=TMBCSEncoding.Create(65001,8,0,False); EncodingName:='UTF-8'; end;
  try
    try Text:=Decoder.GetString(Bytes,Skip,Length(Bytes)-Skip);
    except
      on E: EEncodingError do
      begin
        if (Skip<>0) or (ACodePage=0) then
        begin
          EncodingName:='undecodable';
          ADiagnostics.Report('ENCODING_REQUIRED','Invalid Unicode; explicit legacy code page required',Range(0,0),'error');
          Exit;
        end;
        Decoder.Free; Decoder:=TEncoding.GetEncoding(ACodePage);
        Text:=Decoder.GetString(Bytes); EncodingName:='CP'+IntToStr(ACodePage);
      end;
    end;
    Encoded:=Decoder.GetBytes(Text);
    if (Length(Encoded)<>Length(Bytes)-Skip) or
      ((Length(Encoded)>0) and not CompareMem(@Encoded[0],@Bytes[Skip],Length(Encoded))) then
    begin
      ADiagnostics.Report('ENCODING_LOSS','Decoding did not round-trip exact bytes',Range(0,0),'error'); Exit;
    end;
    if Pos(#0,Text)>0 then
    begin EncodingName:='binary'; ADiagnostics.Report('BINARY_INPUT','NUL bytes in text input',Range(0,0)); Exit; end;
    SetLength(ByteOffsets,Length(Text)+1); I:=1; Position:=Skip;
    while I<=Length(Text) do
    begin
      ByteOffsets[I-1]:=Position; Width:=1;
      if (Ord(Text[I])>=$D800) and (Ord(Text[I])<=$DBFF) and (I<Length(Text)) then
      begin Width:=2; ByteOffsets[I]:=Position; end;
      Inc(Position,Decoder.GetByteCount(Copy(Text,I,Width))); Inc(I,Width);
    end;
    ByteOffsets[Length(Text)]:=Position;
    CRLF:=0; LF:=0; CR:=0;
    for I:=1 to Length(Text) do
      if Text[I]=#10 then begin if (I>1) and (Text[I-1]=#13) then Inc(CRLF) else Inc(LF); end
      else if (Text[I]=#13) and ((I=Length(Text)) or (Text[I+1]<>#10)) then Inc(CR);
    LineEndings:=Format('CRLF=%d;LF=%d;CR=%d',[CRLF,LF,CR]); Decoded:=True;
  finally Decoder.Free; end;
end;

function TDPHSource.Range(AStartChar, AEndChar: Integer): TDPHRange;
var I: Integer;
begin
  Result:=Default(TDPHRange); Result.Source:=RelativePath; Result.Line:=1; Result.Column:=1;
  if Length(ByteOffsets)=0 then Exit;
  AStartChar:=EnsureRange(AStartChar,0,Length(Text)); AEndChar:=EnsureRange(AEndChar,AStartChar,Length(Text));
  Result.StartByte:=ByteOffsets[AStartChar]; Result.EndByte:=ByteOffsets[AEndChar];
  for I:=1 to AStartChar do
    if Text[I]=#10 then begin Inc(Result.Line); Result.Column:=1; end
    else if (Text[I]=#13) and ((I=Length(Text)) or (Text[I+1]<>#10)) then
      begin Inc(Result.Line); Result.Column:=1; end
    else if Text[I]<>#13 then Inc(Result.Column);
end;
end.
