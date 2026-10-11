program DPH.Tests.Knowledge;
{$APPTYPE CONSOLE}
uses System.SysUtils, System.IOUtils, System.JSON, System.Hash, FMX.Forms,
  DPH.UI.Main in '..\DPH.UI.Main.pas',
  DPH.Storage.Database in '..\DPH.Storage.Database.pas',
  DPH.Storage.Backup in '..\DPH.Storage.Backup.pas',
  DPH.Storage.Types in '..\DPH.Storage.Types.pas';
var Root,Work,SourceRoot: string; ID: TGUID; Store: TDPHKnowledgeStore;
    ObservationBytes: TBytes; ObservationPath: string;
    Manifest: TDPHManifest; Config,Generation,Next,Entity,Note,Revision,OldRevision,EvidenceID: Int64;
    Rows,RichLinks: TJSONArray; Row: TJSONObject; Failed,CanClose: Boolean; Checks: Integer; Form: TDPHMainForm; TargetKind: string;
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
      EvidenceID:=Store.AddEvidence(Generation,'unit1.pas','{"source":"unit1.pas","start":0,"end":3,"line":1,"column":1}','source','fixture','inferred');
      Store.AddRelationship(Generation,Entity,Entity,EvidenceID,'calls','inferred','fixture-only');
      Check(Store.PublishGeneration(Generation,Manifest,'{}',True),'Fixture generation publishes');
      TFile.WriteAllText(TPath.Combine(Work,'observed.log'),'2026-10-11T12:00:00Z Work started'+sLineBreak+'<script>not executable</script>',TEncoding.UTF8);
      Failed:=False; try Store.ImportObservation(Generation,TPath.Combine(Work,'observed.log'),'','Fixture environment','unit1.work'); except Failed:=True; end;
      Check(Failed,'Runtime claim import requires named attribution');
      Failed:=False; try Store.ImportObservation(Generation,TPath.Combine(Work,'observed.log'),'Test Author','Fixture environment','missing-key'); except Failed:=True; end;
      Check(Failed,'Runtime claim cannot link an absent captured object');
      Store.ImportObservation(Generation,TPath.Combine(Work,'observed.log'),'Test Author','Synthetic fixture log; not a real program run','unit1.work');
      Rows:=Store.ObservationsJSON;
      try Row:=Rows.Items[0] as TJSONObject;
        Check((Rows.Count=1) and (Row.GetValue<string>('verification_state')='contributor_claim_unverified') and
          (Row.GetValue<Int64>('generation_id')=Generation),'Observation retains its generation and cannot silently verify runtime claims');
        Check((Row.GetValue<string>('linked_source_hash')=Manifest[0].SHA256) and
          (Row.GetValue<string>('original_sha256')=THashSHA2.GetHashStringFromFile(TPath.Combine(Work,'observed.log'))),
          'Observation pins both contributed bytes and the actual linked source revision');
        Check(Pos('<script>not executable</script>',Row.GetValue<string>('text'))>0,'Log content stays literal text rather than executed script');
        Check(Length(Store.ManagedArtifactPaths)=1,'Explicit portable backup inventory includes observation content');
        ObservationPath:=TPath.Combine(Work,'knowledge.dphdb.views\'+Row.GetValue<string>('artifact_hash')+'.json');
        ObservationBytes:=TFile.ReadAllBytes(ObservationPath); TFile.WriteAllText(ObservationPath,'damaged',TEncoding.UTF8);
        Failed:=False; try RichLinks:=Store.ObservationsJSON; RichLinks.Free; except Failed:=True; end;
        Check(Failed,'Damaged observation is rejected before display'); TFile.WriteAllBytes(ObservationPath,ObservationBytes);
      finally Rows.Free; end;
      TFile.WriteAllBytes(TPath.Combine(Work,'invalid.log'),TBytes.Create($FF,$FE,$00));
      Failed:=False; try Store.ImportObservation(Generation,TPath.Combine(Work,'invalid.log'),'Test Author','Invalid encoding',''); except Failed:=True; end;
      Check(Failed,'Non-UTF-8 observation input is rejected rather than silently replaced');
      TFile.WriteAllText(TPath.Combine(Work,'empty.log'),'   ',TEncoding.UTF8);
      Failed:=False; try Store.ImportObservation(Generation,TPath.Combine(Work,'empty.log'),'Test Author','Empty extract',''); except Failed:=True; end;
      Check(Failed,'Whitespace-only observation cannot become evidence');
      TDPHProjectBackup.Save(Store,TPath.Combine(Work,'observation-backup.dphdb'));
      TDPHProjectBackup.Restore(TPath.Combine(Work,'observation-backup.dphdb'),TPath.Combine(Work,'observation-restored.dphdb'),TPath.Combine(Root,'migrations'));
      var ObservationStore:=TDPHKnowledgeStore.Create(TPath.Combine(Work,'observation-restored.dphdb'),SourceRoot,TPath.Combine(Root,'migrations'));
      try Rows:=ObservationStore.ObservationsJSON;
        try Check((Rows.Count=1) and (Rows.Items[0].GetValue<string>('contributor')='Test Author'),
          'Verified portable backup/restore retains observation content and contributor'); finally Rows.Free; end;
      finally ObservationStore.Free; end;
      Failed:=False; try Store.SaveKnowledge(0,0,Generation,'Rule','Body','','business_rule','unit1.work'); except Failed:=True; end; Check(Failed,'Anonymous authorship is rejected');
      RichLinks:=TJSONArray.Create;
      try
        for TargetKind in ['entity','relationship','evidence'] do begin
          Rows:=Store.LinkCandidates(Generation,TargetKind);
          try Check(Rows.Count=1,'Captured '+TargetKind+' target is offered by bounded link search');
            Row:=Rows.Items[0].Clone as TJSONObject; Row.AddPair('link_role','cites'); RichLinks.AddElement(Row);
          finally Rows.Free; end;
        end;
        Note:=Store.SaveKnowledge(0,0,Generation,'Dry-run intent','Author states dry run must preserve outputs.','Test Author','business_rule','unit1.work','maintenance','maintainer',RichLinks.ToJSON);
      finally RichLinks.Free; end;
      Revision:=CurrentRevision; Row:=LoadNote;
      try Check(Row.GetValue<string>('state')='needs_review','New rule remains pending explicit review'); Check(Row.GetValue<TJSONArray>('links').Count=4,'Rule links to stable identity and multiple evidence targets'); Check(Row.GetValue<TJSONArray>('history').Count=1,'First authored revision retained');
        Check(Row.GetValue<TJSONArray>('rich_links').Count=3,'Multiple typed links persist on exact authored revision'); finally Row.Free; end;
      Failed:=False; try Store.SaveKnowledge(Note,Revision,Generation,'Dry-run intent','Invalid linked edit','Author','business_rule','','maintenance','maintainer',
        '[{"target_kind":"entity","target_id":999999,"link_role":"cites"}]'); except Failed:=True; end;
      Check(Failed and (CurrentRevision=Revision),'Unavailable rich target rolls back entire authored revision');
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
      Row:=LoadNote; try Check(Row.GetValue<TJSONArray>('rich_links').Count=3,'Named review preserves immutable rich links'); finally Row.Free; end;
      Failed:=False; try Store.SaveKnowledge(Note,OldRevision,Generation,'Dry-run intent','Old edit','Author','business_rule',''); except Failed:=True; end; Check(Failed,'Stale editor revision cannot overwrite reviewed content');
      Store.SaveKnowledge(Note,Revision,Generation,'Dry-run intent','Revised author explanation','Second Author','business_rule',''); Revision:=CurrentRevision;
      Check(Store.Status.KnowledgeReviewNeeded,'Authored edit reopens human review');
      Row:=LoadNote; try Check((Row.GetValue<TJSONArray>('history').Items[0].GetValue<string>('document_kind')='maintenance') and
        (Row.GetValue<string>('document_kind')='engineering'),'Document reassignment retains prior revision metadata'); finally Row.Free; end;
      Manifest[0].SHA256:=THashSHA2.GetHashString('def'); Store.ObserveManifest(Manifest);
      Failed:=False; try Store.ReviewKnowledge(Note,Revision,Generation,'Reviewer','verified'); except Failed:=True; end; Check(Failed,'Old source generation cannot approve changed inputs');
      Next:=Store.BeginGeneration(Config,'knowledge-fixture',Manifest); Store.AddSourceEntity(Next,'unit1.pas','unit1.work','semantic_routine','Unit1.Work','()',0,3,'{}');
      Check(Store.PublishGeneration(Next,Manifest,'{}',True),'Changed source generation publishes');
      Rows:=Store.ReviewTasks(Next);
      try Check((Rows.Count=1) and (Rows.Items[0].GetValue<Int64>('baseline_generation')=Generation) and
        (Rows.Items[0].GetValue<Int64>('current_generation')=Next),'Review task compares last verified source generation with current capture');
        Check((Rows.Items[0].GetValue<TJSONArray>('affected').Count=1) and
          (Rows.Items[0].GetValue<TJSONArray>('affected').Items[0].GetValue<string>('after_present')='1'),
          'Review task identifies affected canonical entity and before/after presence');
        Check(Rows.Items[0].GetValue<string>('before_body').Contains('preserve outputs') and
          Rows.Items[0].GetValue<string>('body').Contains('Revised author explanation'),
          'Review task exposes prior and current authored content for comparison');
      finally Rows.Free; end;
      Form:=TDPHMainForm.Create(nil);
      try Form.LoadReviewTasks(Store.ReviewTasks(Next));
        Check(Form.ReviewBeforeMemo.Text.Contains('BEFORE: baseline generation') and Form.ReviewAfterMemo.Text.Contains('AFTER: captured generation'),
          'IDE-editable task comparison labels before and after generations');
        Check(Form.ReviewAffectedCombo.Items.Count=1,'Review queue offers affected source object selection');
      finally Form.Free; end;
      Row:=LoadNote; try Check(Row.GetValue<string>('state')='needs_review','Parser publication never approves human explanation'); Check(Row.GetValue<string>('body')='Revised author explanation','Rescan retains authored text'); Check(Row.GetValue<TJSONArray>('history').Count=3,'Rescan preserves all human revisions'); finally Row.Free; end;
      Failed:=False; try Store.ReviewKnowledge(Note,Revision,Next,'Reviewer','verified'); except Failed:=True; end;
      Check(Failed,'Historical rich links block approval in a newer generation');
      Store.SaveKnowledge(Note,Revision,Next,'Dry-run intent','Revised author explanation','Second Author','business_rule','','engineering','engineer','[]'); Revision:=CurrentRevision;
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
    try Row:=LoadNote; try Check(Row.GetValue<TJSONArray>('history').Count=6,'Backup/restore retains full immutable review and rich-link history'); finally Row.Free; end; finally Store.Free; end;
    Row:=TJSONObject.Create; try Row.AddPair('checks_passed',TJSONNumber.Create(Checks)); Row.AddPair('work',Work); TFile.WriteAllText(TPath.Combine(Root,'docs\wp5-validation.json'),Row.Format,TEncoding.UTF8); finally Row.Free; end;
    Writeln('PASS WP5: ',Checks,' checks');
  except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode:=1; end; end;
end.
