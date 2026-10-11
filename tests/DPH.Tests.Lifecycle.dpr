program DPHLifecycleTests;
{$APPTYPE CONSOLE}
uses System.SysUtils, System.IOUtils, System.JSON, System.Hash, System.NetEncoding,
  DPH.Storage.Database in '..\DPH.Storage.Database.pas', DPH.Storage.Types,
  DPH.Storage.Backup in '..\DPH.Storage.Backup.pas';
var Root,Work,Source,Database,Text: string; Store: TDPHKnowledgeStore;
    Manifest: TDPHManifest; Config,Generation,OldNote,OldRevision: Int64; Index,Checks: Integer;
    Rows: TJSONArray; Failed: Boolean;
procedure Check(Condition: Boolean; const MessageText: string);
begin
  if not Condition then raise Exception.Create('FAIL '+MessageText);
  Inc(Checks); Writeln('PASS ',Checks,': ',MessageText);
end;
begin
  OldNote:=0;
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
      if Index<=2 then Store.AddSourceEntity(Generation,'one.pas','old.work','semantic_routine','Old.Work','()',0,10)
      else Store.AddSourceEntity(Generation,'one.pas','new.work','semantic_routine','New.Work','()',0,10);
      Text:='{"generation_id":'+IntToStr(Generation)+'}'; Store.SaveWorkspaceView(Generation,Text);
      Check(Store.PublishGeneration(Generation,Manifest,'{}',True),'Captured coherent generation '+IntToStr(Index));
      if Index=2 then Store.RetainGeneration(Generation,'Reviewed fixture release','Test reviewer');
      if Index=1 then OldNote:=Store.SaveKnowledge(0,0,Generation,'Rename rationale','Original authored rationale','Original author','note','old.work');
    end;
    Store.SaveKnowledge(0,0,Generation,'Keep my note','Authored knowledge survives retention','Test author','note','');
    Rows:=Store.RetentionReport(1);
    try Check(Rows.Count=6,'Preview accounts for all immutable generations'); finally Rows.Free; end;
    Store.ApplyRetention(1);
    Check(Length(TDirectory.GetFiles(Database+'.views','*.json'))=3,'Baseline, retained release and current head survive; three old views removed');
    Rows:=Store.RetentionReport(1);
    try Check(Rows.Count=6,'Retention never destroys generation provenance'); finally Rows.Free; end;
    Rows:=Store.KnowledgeJSON;
    try Check((Rows.Count=2) and ((Rows.Items[1] as TJSONObject).GetValue<string>('body')='Authored knowledge survives retention'),'Authored knowledge remains intact'); finally Rows.Free; end;
    Check(Store.IntegrityCheck='ok','Retention preserves SQLite and foreign-key integrity');
    Failed:=False; try Store.ApplyRetention(0); except Failed:=True; end;
    Check(Failed,'Invalid retention policy is rejected');
    Store.ApplyRetention(1);
    Check(Length(TDirectory.GetFiles(Database+'.views','*.json'))=3,'Repeated retention is idempotent');
    Check(Store.RecentRetentionCount=1,'Retention policy persists independently of its preview');
    Rows:=Store.ContinuityCandidates(Generation,'New');
    try
      Check(Rows.Count=1,'Missing identity produces a filtered same-kind proposal');
      OldRevision:=StrToInt64((Rows.Items[0] as TJSONObject).GetValue<string>('current_revision_id'));
    finally Rows.Free; end;
    Failed:=False; try Store.ApproveContinuity(OldNote,OldRevision,Generation,'old.work','new.work',''); except Failed:=True; end;
    Check(Failed,'Identity continuity cannot approve itself without reviewer');
    Failed:=False; try Store.ApproveContinuity(OldNote,OldRevision+100,Generation,'old.work','new.work','Reviewer'); except Failed:=True; end;
    Check(Failed,'Stale knowledge revision cannot approve continuity');
    Store.ApproveContinuity(OldNote,OldRevision,Generation,'old.work','new.work','Continuity reviewer');
    Rows:=Store.KnowledgeJSON;
    try
      Check((Rows.Items[0] as TJSONObject).GetValue<string>('body')='Original authored rationale','Reviewed rename preserves authored content');
      Check((Rows.Items[0] as TJSONObject).GetValue<string>('state')='needs_review','Identity approval does not approve knowledge content');
      Check(((Rows.Items[0] as TJSONObject).GetValue<TJSONArray>('links').Items[0] as TJSONObject).GetValue<string>('canonical_key')='new.work','Reviewed replacement becomes active annotation link');
      Check((Rows.Items[0] as TJSONObject).GetValue<TJSONArray>('history').Count=2,'Continuity appends a revision instead of overwriting history');
      OldRevision:=StrToInt64((Rows.Items[0] as TJSONObject).GetValue<string>('revision'));
    finally Rows.Free; end;
    Store.ReviewKnowledge(OldNote,OldRevision,Generation,'Content reviewer','verified');
    Rows:=Store.ContinuityCandidates(Generation,'');
    try Check(Rows.Count=0,'Historical link does not reopen completed continuity work'); finally Rows.Free; end;
    Check(Store.IntegrityCheck='ok','Reviewed continuity preserves relational integrity');
    Rows:=Store.SearchProject(Generation,'New','object',0);
    try Check((Rows.Count=1) and ((Rows.Items[0] as TJSONObject).GetValue<string>('entity_key')='new.work'),'Indexed object search returns current canonical identity'); finally Rows.Free; end;
    Rows:=Store.SearchProject(Generation,'authored knowledge','knowledge',0);
    try Check(Rows.Count=1,'Full-text search matches authored note content'); finally Rows.Free; end;
    Rows:=Store.KnowledgeJSON;
    try OldRevision:=StrToInt64((Rows.Items[1] as TJSONObject).GetValue<string>('revision'));
      OldNote:=StrToInt64((Rows.Items[1] as TJSONObject).GetValue<string>('id'));
    finally Rows.Free; end;
    Store.SaveKnowledge(OldNote,OldRevision,Generation,'Keep my note','Authored knowledge survives retention. RevisedOnly evidence.','Test author','note','');
    Rows:=Store.SearchProject(Generation,'RevisedOnly','knowledge',0);
    try Check(Rows.Count=1,'Knowledge edits invalidate and refresh the search index'); finally Rows.Free; end;
    Rows:=Store.SearchProject(Generation,'Old','object',0);
    try Check(Rows.Count=0,'Search never mixes retired identities into the current generation'); finally Rows.Free; end;
    Failed:=False; try Rows:=Store.SearchProject(Generation,'" OR *', '',0); Rows.Free; except Failed:=True; end;
    Check(not Failed,'Search syntax is tokenized rather than executed as query operators');
    Text:=TPath.Combine(Work,'capture.png');
    TFile.WriteAllBytes(Text,TNetEncoding.Base64.DecodeStringToBytes('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aDv8AAAAASUVORK5CYII='));
    Store.ImportScreenshot(Generation,Text,'Fixture contributor','One-pixel imported fixture','');
    TDPHProjectBackup.Save(Store,TPath.Combine(Work,'backup.dphdb'));
    Check(TFile.Exists(TPath.Combine(Work,'backup.dphdb.views\backup-manifest.json')),'Project backup includes a checksum manifest');
    Failed:=False; try TDPHProjectBackup.Save(Store,TPath.Combine(Work,'backup.dphdb')); except Failed:=True; end;
    Check(Failed,'Backup refuses to overwrite an existing file');
    TDPHProjectBackup.Restore(TPath.Combine(Work,'backup.dphdb'),TPath.Combine(Work,'restored.dphdb'),TPath.Combine(Root,'migrations'));
    Failed:=False; try TDPHProjectBackup.Restore(TPath.Combine(Work,'backup.dphdb'),Database,TPath.Combine(Root,'migrations')); except Failed:=True; end;
    Check(Failed,'Restore refuses to overwrite the active database');
  finally Store.Free; end;
  Store:=TDPHKnowledgeStore.Create(TPath.Combine(Work,'restored.dphdb'),Source,TPath.Combine(Root,'migrations'));
  try
    Check(Store.IntegrityCheck='ok','Restored database passes SQLite integrity validation');
    Rows:=Store.KnowledgeJSON;
    try Check((Rows.Count=2) and ((Rows.Items[0] as TJSONObject).GetValue<TJSONArray>('history').Count=3),'Restore preserves notes, continuity and complete review history'); finally Rows.Free; end;
    Rows:=Store.ScreenshotsJSON;
    try Check(Rows.Count=1,'Restore includes screenshot metadata and image data'); finally Rows.Free; end;
  finally Store.Free; end;
  TFile.AppendAllText(TPath.Combine(Work,'backup.dphdb'),'tamper');
  Failed:=False; try TDPHProjectBackup.Restore(TPath.Combine(Work,'backup.dphdb'),TPath.Combine(Work,'rejected.dphdb'),TPath.Combine(Root,'migrations')); except Failed:=True; end;
  Check(Failed and not TFile.Exists(TPath.Combine(Work,'rejected.dphdb')),'Damaged backup is rejected before creating destination');
  Writeln('PASS Lifecycle: ',Checks,' checks');
  // Work is removed by the validation driver after evidence is recorded.
end.
