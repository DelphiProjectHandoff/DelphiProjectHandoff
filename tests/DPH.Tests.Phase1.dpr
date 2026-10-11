program DPH.Tests.Phase1;
{$APPTYPE CONSOLE}
uses System.SysUtils, System.IOUtils, System.JSON, System.Hash, System.UITypes, FMX.Forms, FMX.Graphics,
  DPH.Storage.Database in '..\DPH.Storage.Database.pas', DPH.Storage.Types in '..\DPH.Storage.Types.pas',
  DPH.Knowledge.ProjectProfile in '..\DPH.Knowledge.ProjectProfile.pas', DPH.UI.ProjectProfile in '..\DPH.UI.ProjectProfile.pas';
var Root,Work,SourceRoot,DatabasePath,BodyText: string; ID: TGUID; Store: TDPHKnowledgeStore;
    Manifest: TDPHManifest; Configuration,Generation,Knowledge,Revision,ReviewedRevision: Int64;
    Profile,Fields,Row,Report: TJSONObject; Rows: TJSONArray; Failed: Boolean; Checks: Integer;
    Form: TDPHProjectProfileForm; Bitmap: TBitmap;
procedure Check(OK: Boolean; const MessageText: string);
begin if not OK then raise Exception.Create('FAIL '+MessageText); Inc(Checks); Writeln('PASS ',Checks,': ',MessageText); Flush(Output); end;
function CurrentRow: TJSONObject;
var Items: TJSONArray;
begin Items:=Store.KnowledgeJSON; try Result:=Items.Items[0].Clone as TJSONObject; finally Items.Free; end; end;
function SaveProfile(Expected: Int64): Int64;
begin Result:=Store.SaveKnowledge(Knowledge,Expected,Generation,'Project profile',TDPHProjectProfile.Body(Profile),'Phase1 Test Author','orientation','','overview','all','','',Profile.ToJSON); end;
begin
  Application.Initialize;
  try
    Root:=TPath.GetFullPath(ParamStr(1)); CreateGUID(ID); Work:=TPath.Combine(Root,'bin\phase1-tests-'+GUIDToString(ID));
    SourceRoot:=TPath.Combine(Work,'source'); TDirectory.CreateDirectory(SourceRoot); DatabasePath:=TPath.Combine(Work,'profile.dphdb');
    Profile:=TJSONObject.Create; Profile.AddPair('record_type','project_profile'); Fields:=TJSONObject.Create; Profile.AddPair('fields',Fields);
    try
      Failed:=False; try BodyText:=TDPHProjectProfile.Body(Profile); except Failed:=True; end;
      Check(Failed,'Empty profile cannot claim a documented purpose');
      Fields.AddPair('purpose','Synthetic selected application; not a real business claim');
      Failed:=False; try BodyText:=TDPHProjectProfile.Body(Profile); except Failed:=True; end;
      Check(Failed,'Profile requires attribution and evidence context');
      Fields.AddPair('evidence','Synthetic controlled test; unknown production settings'); Fields.AddPair('owner','Fixture owner');
      BodyText:=TDPHProjectProfile.Body(Profile);
      Check(Pos('Not supplied; requires attributed information.',BodyText)>0,'Unwritten project metadata is explicitly unknown');
      Fields.AddPair('unexpected','bad'); Failed:=False; try TDPHProjectProfile.Validate(Profile); except Failed:=True; end;
      Check(Failed,'Unknown typed field is rejected'); Fields.RemovePair('unexpected').Free;
      Store:=TDPHKnowledgeStore.Create(DatabasePath,SourceRoot,TPath.Combine(Root,'migrations'));
      try
        Store.InitializeProject('Profile fixture','Delphi'); Configuration:=Store.AddConfiguration('Win32','37.0','[]','[]','Debug'); Store.SelectConfiguration(Configuration);
        SetLength(Manifest,1); Manifest[0].RelativePath:='unit1.pas'; Manifest[0].SHA256:=THashSHA2.GetHashString('abc'); Manifest[0].SizeBytes:=3;
        Manifest[0].Availability:='available'; Manifest[0].Encoding:='UTF-8'; Manifest[0].Kind:='pascal'; Store.ObserveManifest(Manifest);
        Generation:=Store.BeginGeneration(Configuration,'phase1-profile-fixture',Manifest);
        Store.AddSourceEntity(Generation,'unit1.pas','unit1.run','semantic_routine','Unit1.Run','()',0,3,'{}');
        Check(Store.PublishGeneration(Generation,Manifest,'{}',True),'Profile fixture generation publishes');
        Knowledge:=SaveProfile(0); Row:=CurrentRow;
        try Revision:=StrToInt64(Row.GetValue<string>('revision'));
          Check((Row.GetValue<string>('state')='needs_review') and (Row.GetValue<string>('source_generation')=IntToStr(Generation)), 'Profile is attributed, revision-pinned and awaiting human review');
          Check(Row.GetValue<string>('structured_json')=Profile.ToJSON,'Exact structured fields survive SQLite publication');
          Check(Row.GetValue<string>('body')=BodyText,'Readable body and typed fields agree (stored '+IntToStr(Length(Row.GetValue<string>('body')))+', expected '+IntToStr(Length(BodyText))+')');
        finally Row.Free; end;
        Failed:=False; try Store.SaveKnowledge(0,0,Generation,'Project profile',BodyText,'Other author','orientation','','overview','all','','',Profile.ToJSON); except Failed:=True; end;
        Check(Failed,'Only one profile can belong to the selected project');
        Failed:=False; try Store.SaveKnowledge(Knowledge,Revision,Generation,'Project profile','Contradictory body','Author','orientation','','overview','all','','',Profile.ToJSON); except Failed:=True; end;
        Check(Failed,'Text cannot diverge silently from structured profile fields');
        Failed:=False; try Store.SaveKnowledge(Knowledge,Revision,Generation,'Project profile',BodyText,'Author','orientation','','overview','all'); except Failed:=True; end;
        Check(Failed,'Ordinary text editing cannot discard typed profile data');
        Store.ReviewKnowledge(Knowledge,Revision,Generation,'Named Reviewer','verified'); Row:=CurrentRow;
        try ReviewedRevision:=StrToInt64(Row.GetValue<string>('revision'));
          Check((Row.GetValue<string>('structured_json')=Profile.ToJSON) and (Row.GetValue<string>('state')='verified'), 'Named review preserves structured fields in a new immutable revision');
        finally Row.Free; end;
        Failed:=False; try SaveProfile(Revision); except Failed:=True; end; Check(Failed,'A stale profile editor cannot overwrite newer review');
        Fields.RemovePair('owner').Free; Fields.AddPair('owner','Revised fixture owner'); Knowledge:=SaveProfile(ReviewedRevision); Row:=CurrentRow;
        try Check((Row.GetValue<TJSONArray>('history').Count=3) and (Row.GetValue<string>('state')='needs_review'),'Editing reviewed ownership preserves history and reopens review'); finally Row.Free; end;
        Store.BuildSearchIndex(Generation); Rows:=Store.SearchProject(Generation,'Revised fixture owner','',0);
        try Check(Rows.Count>0,'Authored project profile participates in project search'); finally Rows.Free; end;
        Check(Store.IntegrityCheck='ok','Typed profile updates preserve database integrity');
      finally Store.Free; end;
      Store:=TDPHKnowledgeStore.Create(DatabasePath,SourceRoot,TPath.Combine(Root,'migrations'));
      try Row:=CurrentRow; try Check(Row.GetValue<string>('structured_json')=Profile.ToJSON,'Reopened database retains exact profile fields'); finally Row.Free; end; finally Store.Free; end;
      Form:=TDPHProjectProfileForm.Create(nil);
      try Form.LoadRecord(Profile,'Native Test Author'); Form.ApplyProfileClick(nil);
        Check(Form.ModalResult=mrOk,'IDE-designed profile fields validate and produce an attributed draft');
        Row:=Form.RecordJSON; try Check(Row.GetValue<TJSONObject>('fields').GetValue<string>('owner')='Revised fixture owner','Native editor round-trips the saved owner field'); finally Row.Free; end;
        Form.Show; Application.ProcessMessages; Bitmap:=TBitmap.Create(Form.ClientWidth,Form.ClientHeight);
        try if Bitmap.Canvas.BeginScene then try Form.PaintTo(Bitmap.Canvas); finally Bitmap.Canvas.EndScene; end;
          Bitmap.SaveToFile(TPath.Combine(Root,'docs\phase1-project-profile.png'));
        finally Bitmap.Free; end; Form.Hide;
      finally Form.Free; end;
      Report:=TJSONObject.Create; try Report.AddPair('checks_passed',TJSONNumber.Create(Checks)); Report.AddPair('scope','Project profile, attribution, immutable review, stale edits, search and native form'); Report.AddPair('work',Work);
        TFile.WriteAllText(TPath.Combine(Root,'docs\phase1-profile-validation.json'),Report.Format(2),TEncoding.UTF8); finally Report.Free; end;
    finally Profile.Free; end;
    Writeln('PASS Phase1 profile: ',Checks,' checks');
  except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode:=1; end; end;
end.

