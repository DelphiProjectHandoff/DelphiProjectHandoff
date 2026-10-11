program DPH.Tests.Knowledge;
{$APPTYPE CONSOLE}
uses System.SysUtils, System.IOUtils, System.JSON, System.Hash, FMX.Forms,
  DPH.UI.Main in '..\DPH.UI.Main.pas',
  DPH.Storage.Database in '..\DPH.Storage.Database.pas',
  DPH.Storage.Types in '..\DPH.Storage.Types.pas';
var Root,Work,SourceRoot: string; ID: TGUID; Store: TDPHKnowledgeStore;
    Manifest: TDPHManifest; Config,Generation,Next,Entity,Note,Revision,OldRevision: Int64;
    Rows: TJSONArray; Row: TJSONObject; Failed,CanClose: Boolean; Checks: Integer; Form: TDPHMainForm;
procedure Check(OK: Boolean; const MessageText: string);
begin if not OK then raise Exception.Create('FAIL '+MessageText); Inc(Checks); Writeln('PASS ',Checks,': ',MessageText); end;
function LoadNote: TJSONObject;
var A: TJSONArray;
begin A:=Store.KnowledgeJSON; try Result:=A.Items[0].Clone as TJSONObject; finally A.Free; end; end;
function CurrentRevision: Int64;
var R: TJSONObject;
begin R:=LoadNote; try Result:=StrToInt64(R.GetValue<string>('revision')); finally R.Free; end; end;
begin
  Application.Initialize;
  try
    Root:=TPath.GetFullPath(ParamStr(1)); CreateGUID(ID); Work:=TPath.Combine(Root,'bin\wp5-tests-'+GUIDToString(ID));
    SourceRoot:=TPath.Combine(Work,'source'); TDirectory.CreateDirectory(SourceRoot);
    Store:=TDPHKnowledgeStore.Create(TPath.Combine(Work,'knowledge.dphdb'),SourceRoot,TPath.Combine(Root,'migrations'));
    try
      Store.InitializeProject('Knowledge fixture','Delphi'); Config:=Store.AddConfiguration('Win32','37.0','[]','[]','Debug'); Store.SelectConfiguration(Config);
      SetLength(Manifest,1); Manifest[0].RelativePath:='unit1.pas'; Manifest[0].SHA256:=THashSHA2.GetHashString('abc'); Manifest[0].SizeBytes:=3;
      Manifest[0].Availability:='available'; Manifest[0].Encoding:='UTF-8'; Manifest[0].Kind:='pascal'; Store.ObserveManifest(Manifest);
      Generation:=Store.BeginGeneration(Config,'knowledge-fixture',Manifest);
      Entity:=Store.AddSourceEntity(Generation,'unit1.pas','unit1.work','semantic_routine','Unit1.Work','()',0,3,'{}');
      Check(Store.PublishGeneration(Generation,Manifest,'{}',True),'Fixture generation publishes');
      Failed:=False; try Store.SaveKnowledge(0,0,Generation,'Rule','Body','','business_rule','unit1.work'); except Failed:=True; end; Check(Failed,'Anonymous authorship is rejected');
      Note:=Store.SaveKnowledge(0,0,Generation,'Dry-run intent','Author states dry run must preserve outputs.','Test Author','business_rule','unit1.work','maintenance','maintainer');
      Revision:=CurrentRevision; Row:=LoadNote;
      try Check(Row.GetValue<string>('state')='needs_review','New rule remains pending explicit review'); Check(Row.GetValue<TJSONArray>('links').Count=1,'Rule links to stable semantic identity'); Check(Row.GetValue<TJSONArray>('history').Count=1,'First authored revision retained'); finally Row.Free; end;
      Check(Store.Status.KnowledgeReviewNeeded,'Separate project review flag is set');
      Row:=LoadNote;
      try Check((Row.GetValue<string>('section_id')='knowledge-'+IntToStr(Note)) and (Row.GetValue<string>('document_kind')='maintenance') and
        (Row.GetValue<string>('audience')='maintainer') and (Row.GetValue<string>('source_generation')=IntToStr(Generation)),
        'Authored section persists stable ID, document, audience and source generation'); finally Row.Free; end;
      Failed:=False; try Store.ReviewKnowledge(Note,Revision,Generation,'','verified'); except Failed:=True; end; Check(Failed,'Anonymous reviewer is rejected');
      Store.ReviewKnowledge(Note,Revision,Generation,'Named Reviewer','verified'); OldRevision:=Revision; Revision:=CurrentRevision; Row:=LoadNote;
      try Check(Row.GetValue<string>('state')='verified','Explicit named review verifies human content'); Check(Row.GetValue<string>('reviewer')='Named Reviewer','Reviewer attribution persists'); Check(Row.GetValue<TJSONArray>('history').Count=2,'Verification appends rather than overwrites history'); finally Row.Free; end;
      Check(not Store.Status.KnowledgeReviewNeeded,'Resolved review queue clears its own flag');
      Row:=LoadNote; try Check((Row.GetValue<string>('document_kind')='maintenance') and (Row.GetValue<string>('audience')='maintainer'),
        'Review revision preserves document section metadata'); finally Row.Free; end;
      Failed:=False; try Store.SaveKnowledge(Note,OldRevision,Generation,'Dry-run intent','Old edit','Author','business_rule',''); except Failed:=True; end; Check(Failed,'Stale editor revision cannot overwrite reviewed content');
      Store.SaveKnowledge(Note,Revision,Generation,'Dry-run intent','Revised author explanation','Second Author','business_rule',''); Revision:=CurrentRevision;
      Check(Store.Status.KnowledgeReviewNeeded,'Authored edit reopens human review');
      Row:=LoadNote; try Check((Row.GetValue<TJSONArray>('history').Items[0].GetValue<string>('document_kind')='maintenance') and
        (Row.GetValue<string>('document_kind')='engineering'),'Document reassignment retains prior revision metadata'); finally Row.Free; end;
      Manifest[0].SHA256:=THashSHA2.GetHashString('def'); Store.ObserveManifest(Manifest);
      Failed:=False; try Store.ReviewKnowledge(Note,Revision,Generation,'Reviewer','verified'); except Failed:=True; end; Check(Failed,'Old source generation cannot approve changed inputs');
      Next:=Store.BeginGeneration(Config,'knowledge-fixture',Manifest); Store.AddSourceEntity(Next,'unit1.pas','unit1.work','semantic_routine','Unit1.Work','()',0,3,'{}');
      Check(Store.PublishGeneration(Next,Manifest,'{}',True),'Changed source generation publishes');
      Row:=LoadNote; try Check(Row.GetValue<string>('state')='needs_review','Parser publication never approves human explanation'); Check(Row.GetValue<string>('body')='Revised author explanation','Rescan retains authored text'); Check(Row.GetValue<TJSONArray>('history').Count=3,'Rescan preserves all human revisions'); finally Row.Free; end;
      Store.ReviewKnowledge(Note,Revision,Next,'Reviewer','verified'); Revision:=CurrentRevision;
      Config:=Store.AddConfiguration('Win32','37.0','["OTHER"]','[]','Debug'); Store.SelectConfiguration(Config);
      Check(Store.Status.KnowledgeReviewNeeded,'Configuration change invalidates review without source-byte change');
      Generation:=Store.BeginGeneration(Config,'knowledge-fixture',Manifest); Store.AddSourceEntity(Generation,'unit1.pas','unit1.renamed','semantic_routine','Unit1.Renamed','()',0,3,'{}');
      Check(Store.PublishGeneration(Generation,Manifest,'{}',True),'Controlled rename publishes a distinct identity');
      Failed:=False; try Store.ReviewKnowledge(Note,Revision,Generation,'Reviewer','verified'); except Failed:=True; end; Check(Failed,'Missing or renamed entity cannot inherit verified knowledge');
      Row:=LoadNote; try Check((Row.GetValue<TJSONArray>('links').Items[0] as TJSONObject).GetValue<string>('canonical_key')='unit1.work','Historical link is not reassigned to a renamed method'); finally Row.Free; end;
      Store.ReviewKnowledge(Note,Revision,Generation,'Reviewer','retired'); Revision:=CurrentRevision;
      Row:=LoadNote; try Check(Row.GetValue<string>('state')='retired','Obsolete knowledge can be retired with history'); finally Row.Free; end;
      Check(not Store.Status.KnowledgeReviewNeeded,'Retirement resolves the pending task');
      Rows:=Store.KnowledgeJSON;
      Form:=TDPHMainForm.Create(nil);
      try Form.LoadKnowledge(Rows); Rows:=nil; Check(Form.KnowledgeList.Items.Count=1,'FMX knowledge list shows curated records'); Form.KnowledgeList.ItemIndex:=0; Form.KnowledgeClick(nil);
        Check(Form.KnowledgeBodyMemo.Text='Revised author explanation','Editor loads selected authored revision'); Check(Pos('Named Reviewer',Form.KnowledgeHistoryMemo.Text)>0,'Inspector exposes prior reviewer attribution');
        Form.PendingKnowledgeCheck.IsChecked:=True; Form.KnowledgeFilterChange(nil); Check(Form.KnowledgeList.Items.Count=0,'Pending filter excludes resolved retired knowledge');
        Form.KnowledgeBodyMemo.Text:='Unsaved author text'; Form.LoadKnowledge(Store.KnowledgeJSON);
        Check(Form.KnowledgeBodyMemo.Text='Unsaved author text','Background knowledge refresh preserves unsaved edits');
        CanClose:=True; Form.FormCloseQuery(nil,CanClose); Check(not CanClose,'Close cannot silently discard authored text');
        Form.ReviewKnowledgeClick(Form.VerifyKnowledgeButton); Check(Pos('Save the authored edit',Form.StatusLabel.Text)>0,'Displayed unsaved edit cannot approve a different persisted revision');
        Form.DiscardKnowledgeClick(nil); Check(Form.KnowledgeBodyMemo.Text='','Explicit discard clears the edit');
      finally Form.Free; Rows.Free; end;
      Store.BackupTo(TPath.Combine(Work,'portable.dphdb')); Check(Store.IntegrityCheck='ok','Knowledge edits preserve SQLite integrity');
    finally Store.Free; end;
    Store:=TDPHKnowledgeStore.Create(TPath.Combine(Work,'portable.dphdb'),SourceRoot,TPath.Combine(Root,'migrations'));
    try Row:=LoadNote; try Check(Row.GetValue<TJSONArray>('history').Count=5,'Backup/restore retains full immutable review history'); finally Row.Free; end; finally Store.Free; end;
    Row:=TJSONObject.Create; try Row.AddPair('checks_passed',TJSONNumber.Create(Checks)); Row.AddPair('work',Work); TFile.WriteAllText(TPath.Combine(Root,'docs\wp5-validation.json'),Row.Format,TEncoding.UTF8); finally Row.Free; end;
    Writeln('PASS WP5: ',Checks,' checks');
  except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode:=1; end; end;
end.
