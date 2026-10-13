unit DPH.Publish.BrowserPolicy;
interface
type TDPHBrowserPolicy = class
  class function Allowed(const AURL,ADirectory: string; AObjectPages: Boolean = False; AHashedPages: Boolean = False): Boolean; static;
end;
implementation
uses System.SysUtils, System.StrUtils, System.IOUtils, System.NetEncoding;
class function TDPHBrowserPolicy.Allowed(const AURL,ADirectory: string; AObjectPages,AHashedPages: Boolean): Boolean;
var Path,Name: string; P: Integer; C: Char;
begin
  Result:=SameText(AURL,'about:blank'); if Result then Exit;
  if (ADirectory='') or not StartsText('file://',AURL) then Exit(False);
  Path:=Copy(AURL,8,MaxInt);
  if StartsText('/',Path) then Delete(Path,1,1);
  Path:=TNetEncoding.URL.Decode(Path); P:=Pos('#',Path); if P>0 then SetLength(Path,P-1);
  if Path.Contains('?') or Path.Contains('..') or Path.Contains(#0) then Exit(False);
  Path:=Path.Replace('/',PathDelim);
  try
    Path:=TPath.GetFullPath(Path);
    Result:=SameFileName(Path,TPath.Combine(TPath.GetFullPath(ADirectory),'index.html'));
    if not Result and AObjectPages then Result:=SameFileName(Path,TPath.Combine(TPath.GetFullPath(ADirectory),'learning.html'));
    if not Result and ((AObjectPages and SameFileName(ExtractFileDir(Path),TPath.Combine(TPath.GetFullPath(ADirectory),'objects'))) or
      (AHashedPages and SameFileName(ExtractFileDir(Path),TPath.GetFullPath(ADirectory)))) then begin
      Name:=TPath.GetFileNameWithoutExtension(Path); Result:=(Length(Name)=64) and SameText(ExtractFileExt(Path),'.html');
      for C in Name do if not CharInSet(C,['0'..'9','a'..'f','A'..'F']) then Result:=False;
    end;
  except Result:=False; end;
end;
end.
