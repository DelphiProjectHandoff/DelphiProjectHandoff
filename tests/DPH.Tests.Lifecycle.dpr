program DPHLifecycleTests;
{$APPTYPE CONSOLE}
uses System.SysUtils, System.IOUtils, System.JSON, System.Hash,
  DPH.Storage.Database in '..\DPH.Storage.Database.pas', DPH.Storage.Types;
var Root,Work,Source,Database,Text,Path: string; Store: TDPHKnowledgeStore;
    Manifest: TDPHManifest; Config,Generation,Note: Int64; Index,Checks: Integer;
    Rows: TJSONArray; Failed: Boolean;
procedure Check(Condition: Boolean; const MessageText: string);
begin
  if not Condition then raise Exception.Create('FAIL '+MessageText);
  Inc(Checks); Writeln('PASS ',Checks,': ',MessageText);
end;
begin
  Root:=TPath.GetFullPath(ParamStr(1)); Work:=TPath.Combine(Root,'bin\lifecycle-validation');
  Source:=TPath.Combine(Work,'source'); Database:=TPath.Combine(Work,'fixture.dphdb');
  if TDirectory.Exists(Work) then raise Exception.Create('Lifecycle test work directory already exists; inspect it before reuse');
  TDirectory.CreateDirectory(Source);
  TFile.WriteAllText(TPath.Combine(Source,'one.pas'),'unit One; interface implementation end.',TEncoding.UTF8);
  SetLength(Manifest,1); Manifest[0].RelativePath:='one.pas'; Manifest[0].Kind:='.pas';
  Manifest[0].Availability:='available'; Manifest[0].Encoding:='UTF-8';
  Manifest[0].SHA256:=THashSHA2.GetHashStringFromFile(TPath.Combine(Source,'one.pas'));
  Manifest[0].SizeBytes:=TFile.GetSize(TPath.Combine(Source,'one.pas'));
  Store:=TDPHKnowledgeStore.Create(Database,Source,TPath.Combine(Root,'migrations'));
  try
    Store.InitializeProject('Lifecycle fixture','dpr'); Config:=Store.AddConfiguration('Win32','37.0','[]','[]','Debug');
    Store.SelectConfiguration(Config); Store.ObserveManifest(Manifest);
    for Index:=1 to 6 do begin
      Generation:=Store.BeginGeneration(Config,'lifecycle-fixture',Manifest);
      Text:='{"generation_id":'+IntToStr(Generation)+'}'; Store.SaveWorkspaceView(Generation,Text);
      Check(Store.PublishGeneration(Generation,Manifest,'{}',True),'Captured coherent generation '+IntToStr(Index));
      if Index=2 then Store.RetainGeneration(Generation,'Reviewed fixture release','Test reviewer');
    end;
    Note:=Store.SaveKnowledge(0,0,Generation,'Keep my note','Authored knowledge survives retention','Test author','note','');
    Rows:=Store.RetentionReport(1);
    try Check(Rows.Count=6,'Preview accounts for all immutable generations'); finally Rows.Free; end;
    Store.ApplyRetention(1);
    Check(Length(TDirectory.GetFiles(Database+'.views','*.json'))=3,'Baseline, retained release and current head survive; three old views removed');
    Rows:=Store.RetentionReport(1);
    try Check(Rows.Count=6,'Retention never destroys generation provenance'); finally Rows.Free; end;
    Rows:=Store.KnowledgeJSON;
    try Check((Rows.Count=1) and ((Rows.Items[0] as TJSONObject).GetValue<string>('body')='Authored knowledge survives retention'),'Authored knowledge remains intact'); finally Rows.Free; end;
    Check(Store.IntegrityCheck='ok','Retention preserves SQLite and foreign-key integrity');
    Failed:=False; try Store.ApplyRetention(0); except Failed:=True; end;
    Check(Failed,'Invalid retention policy is rejected');
    Store.ApplyRetention(1);
    Check(Length(TDirectory.GetFiles(Database+'.views','*.json'))=3,'Repeated retention is idempotent');
  finally Store.Free; end;
  Writeln('PASS Lifecycle: ',Checks,' checks');
  // Work is removed by the validation driver after evidence is recorded.
end.
