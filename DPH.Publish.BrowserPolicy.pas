unit DPH.Publish.BrowserPolicy;
interface
type TDPHBrowserPolicy = class
  class function Allowed(const AURL,ADirectory: string): Boolean; static;
end;
implementation
uses System.SysUtils, System.StrUtils, System.IOUtils, System.NetEncoding;
class function TDPHBrowserPolicy.Allowed(const AURL,ADirectory: string): Boolean;
var Path: string; P: Integer;
begin
  Result:=SameText(AURL,'about:blank'); if Result then Exit;
  if (ADirectory='') or not StartsText('file://',AURL) then Exit(False);
  Path:=Copy(AURL,8,MaxInt);
  if StartsText('/',Path) then Delete(Path,1,1);
  Path:=TNetEncoding.URL.Decode(Path); P:=Pos('#',Path); if P>0 then SetLength(Path,P-1);
  if Path.Contains('?') or Path.Contains('..') or Path.Contains(#0) then Exit(False);
  Path:=Path.Replace('/',PathDelim);
  try Result:=SameFileName(TPath.GetFullPath(Path),TPath.Combine(TPath.GetFullPath(ADirectory),'index.html')); except Result:=False; end;
end;
end.
