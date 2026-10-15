program DPHTestsOfflinePreview;

{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.Classes, System.IOUtils,
  IdHTTP, DPH.Publish.OfflinePreview in '..\DPH.Publish.OfflinePreview.pas';

var
  Directory, AssetDirectory, Page, URL: string;
  Preview: TDPHOfflinePreview;
  HTTP: TIdHTTP;
  Stream: TMemoryStream;
begin
  Directory := TPath.Combine(TPath.GetTempPath, 'DPH-OfflinePreview-Test');
  AssetDirectory := TPath.Combine(TPath.GetFullPath('Localization'), 'OfflineTranslation');
  TDirectory.CreateDirectory(Directory);
  Page := TPath.Combine(Directory, 'test.html');
  TFile.WriteAllText(Page, '<html><body>offline preview</body></html>', TEncoding.UTF8);
  Preview := TDPHOfflinePreview.Create(Directory, AssetDirectory);
  HTTP := TIdHTTP.Create(nil);
  Stream := TMemoryStream.Create;
  try
    URL := Preview.URLForPage(Page);
    if not Preview.Allows(URL, Directory) then raise Exception.Create('Local page rejected');
    if Preview.Allows(URL, TPath.GetTempPath + 'elsewhere') then
      raise Exception.Create('Page escaped its directory');
    if not HTTP.Get(URL).Contains('offline preview') then
      raise Exception.Create('Local page response missing');
    if not HTTP.Get(Preview.ScriptURL).Contains('BundledGermanModel') then
      raise Exception.Create('Local translation script missing');
    HTTP.Get(Preview.ScriptURL.Replace('offline-translate.js',
      'model/model.ende.intgemm.alphas.bin'), Stream);
    if Stream.Size <> 17140835 then raise Exception.Create('Local model response incomplete');
    Writeln('Offline preview serves page, script, and model on loopback.');
  finally
    Stream.Free;
    HTTP.Free;
    Preview.Free;
    TFile.Delete(Page);
    TDirectory.Delete(Directory, False);
  end;
end.
