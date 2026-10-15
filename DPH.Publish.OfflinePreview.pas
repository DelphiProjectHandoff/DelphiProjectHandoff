unit DPH.Publish.OfflinePreview;

interface

uses
  System.Classes, System.SysUtils, IdContext, IdCustomHTTPServer, IdHTTPServer;

type
  TDPHOfflinePreview = class
  private
    FServer: TIdHTTPServer;
    FPagesDirectory: string;
    FAssetsDirectory: string;
    FToken: string;
    FPort: Integer;
    procedure Serve(AContext: TIdContext; ARequest: TIdHTTPRequestInfo;
      AResponse: TIdHTTPResponseInfo);
    function BaseURL: string;
  public
    constructor Create(const APagesDirectory, AAssetsDirectory: string);
    destructor Destroy; override;
    function URLForPage(const APagePath: string): string;
    function ScriptURL: string;
    function Allows(const AURL, APageDirectory: string): Boolean;
  end;

implementation

uses
  System.IOUtils, System.StrUtils, IdGlobal, IdSocketHandle;

constructor TDPHOfflinePreview.Create(const APagesDirectory,
  AAssetsDirectory: string);
var
  ID: TGUID;
  Binding: TIdSocketHandle;
begin
  inherited Create;
  FPagesDirectory := IncludeTrailingPathDelimiter(TPath.GetFullPath(APagesDirectory));
  FAssetsDirectory := IncludeTrailingPathDelimiter(TPath.GetFullPath(AAssetsDirectory));
  if not TDirectory.Exists(FPagesDirectory) or
     not TFile.Exists(TPath.Combine(FAssetsDirectory, 'offline-translate.js')) then
    raise EFileNotFoundException.Create('Offline translation files are unavailable');
  CreateGUID(ID);
  FToken := GUIDToString(ID).Replace('{', '').Replace('}', '').Replace('-', '');
  FServer := TIdHTTPServer.Create(nil);
  try
    FServer.Bindings.Clear;
    Binding := FServer.Bindings.Add;
    Binding.IP := '127.0.0.1';
    Binding.Port := 0;
    FServer.OnCommandGet := Serve;
    FServer.Active := True;
    FPort := FServer.Bindings[0].Port;
    if FPort = 0 then raise EInvalidOperation.Create('Offline preview did not bind a local port');
  except
    FServer.Free;
    FServer := nil;
    raise;
  end;
end;

destructor TDPHOfflinePreview.Destroy;
begin
  FServer.Free;
  inherited;
end;

function TDPHOfflinePreview.BaseURL: string;
begin
  Result := Format('http://127.0.0.1:%d/%s/', [FPort, FToken]);
end;

function TDPHOfflinePreview.URLForPage(const APagePath: string): string;
var
  FullPath: string;
begin
  FullPath := TPath.GetFullPath(APagePath);
  if not StartsText(FPagesDirectory, FullPath) then
    raise EArgumentException.Create('Page is outside the offline preview directory');
  Result := BaseURL + 'page/' +
    FullPath.Substring(Length(FPagesDirectory)).Replace('\', '/');
end;

function TDPHOfflinePreview.ScriptURL: string;
begin
  Result := BaseURL + 'asset/offline-translate.js';
end;

function TDPHOfflinePreview.Allows(const AURL, APageDirectory: string): Boolean;
var
  URL, RelativePath, FullPath, Root: string;
begin
  URL := AURL.Split(['#', '?'])[0];
  Result := StartsText(BaseURL + 'page/', URL);
  if not Result then Exit;
  RelativePath := URL.Substring(Length(BaseURL + 'page/')).Replace('/', '\');
  Root := IncludeTrailingPathDelimiter(TPath.GetFullPath(APageDirectory));
  FullPath := TPath.GetFullPath(TPath.Combine(FPagesDirectory, RelativePath));
  Result := StartsText(Root, FullPath) and
    SameText(TPath.GetExtension(FullPath), '.html') and TFile.Exists(FullPath);
end;

procedure TDPHOfflinePreview.Serve(AContext: TIdContext;
  ARequest: TIdHTTPRequestInfo; AResponse: TIdHTTPResponseInfo);
var
  RelativePath, FullPath, Root, Extension: string;
begin
  AResponse.ResponseNo := 404;
  AResponse.ContentText := 'Not found';
  AResponse.CustomHeaders.Values['X-Content-Type-Options'] := 'nosniff';
  if not StartsText('/' + FToken + '/', ARequest.Document) then Exit;
  RelativePath := ARequest.Document.Substring(Length(FToken) + 2);
  if StartsText('page/', RelativePath) then begin
    Root := FPagesDirectory;
    Delete(RelativePath, 1, Length('page/'));
  end else if StartsText('asset/', RelativePath) then begin
    Root := FAssetsDirectory;
    Delete(RelativePath, 1, Length('asset/'));
  end else Exit;
  FullPath := TPath.GetFullPath(TPath.Combine(Root,
    RelativePath.Replace('/', '\')));
  if not StartsText(Root, FullPath) or not TFile.Exists(FullPath) then Exit;
  Extension := LowerCase(TPath.GetExtension(FullPath));
  if Root = FPagesDirectory then begin
    if Extension <> '.html' then Exit;
  end else if not MatchText(Extension, ['.js', '.wasm', '.bin', '.spm']) then Exit;
  AResponse.ResponseNo := 200;
  AResponse.ContentText := '';
  if Extension = '.html' then AResponse.ContentType := 'text/html; charset=utf-8'
  else if Extension = '.js' then AResponse.ContentType := 'text/javascript; charset=utf-8'
  else if Extension = '.wasm' then AResponse.ContentType := 'application/wasm'
  else AResponse.ContentType := 'application/octet-stream';
  AResponse.ContentStream := TFileStream.Create(FullPath, fmOpenRead or fmShareDenyNone);
  AResponse.FreeContentStream := True;
end;

end.
