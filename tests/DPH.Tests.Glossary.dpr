program DPH.Tests.Glossary;
{$APPTYPE CONSOLE}
uses System.SysUtils, System.Classes, System.StrUtils, System.IOUtils, System.JSON, System.Hash, System.Zip, System.UITypes,
  FMX.Forms, FMX.Graphics,
  DPH.Knowledge.Glossary in '..\DPH.Knowledge.Glossary.pas',
  DPH.UI.Glossary in '..\DPH.UI.Glossary.pas', DPH.UI.Main in '..\DPH.UI.Main.pas',
  DPH.Storage.Database in '..\DPH.Storage.Database.pas', DPH.Storage.Types in '..\DPH.Storage.Types.pas',
  DPH.Project.Analysis in '..\DPH.Project.Analysis.pas', DPH.Analysis.Symbols in '..\DPH.Analysis.Symbols.pas',
  DPH.Analysis.Model in '..\DPH.Analysis.Model.pas',
  DPH.Analysis.Persistence in '..\DPH.Analysis.Persistence.pas', DPH.Workspace.Model in '..\DPH.Workspace.Model.pas',
  DPH.Publish.Model in '..\DPH.Publish.Model.pas', DPH.Publish.Export in '..\DPH.Publish.Export.pas';
var Root,Work,SourceRoot,DatabasePath,Key,OldHash,Definition,PublishedRevision,PreferencesHash,PreferencesPath: string;
    Checks,Index: Integer; Store,OtherStore: TDPHKnowledgeStore; Analyzer: TDPHAnalyzer; Semantic: TDPHSemanticAnalyzer;
    Scan: TDPHScan; Graph: TDPHSemanticGraph; View: TDPHWorkspaceView; Config,Generation,TermID,Revision,OldRevision,OtherConfig,OtherGeneration: Int64;
    Term,OtherTerm,Row,Report,Link: TJSONObject; Rows,Links: TJSONArray; Failed,ModalDriven: Boolean;
    Model: TDPHDocumentModel; Editor: TDPHGlossaryForm; NativeForm: TDPHMainForm; Bitmap: TBitmap; Archive: TZipFile; Bytes: TBytes;
    FixtureManifest: TDPHManifest;
procedure Check(OK: Boolean; const MessageText: string);
begin if not OK then raise Exception.Create('FAIL '+MessageText); Inc(Checks); Writeln('PASS ',Checks,': ',MessageText); Flush(Output); end;
function NewTerm(const Name,Alias,Meaning: string): TJSONObject;
var Names: TJSONArray;
begin
  Result:=TJSONObject.Create; Result.AddPair('record_type','business_glossary'); Result.AddPair('term',Name);
  Names:=TJSONArray.Create; Result.AddPair('aliases',Names); if Alias<>'' then Names.Add(Alias);
  Result.AddPair('definition',Meaning); Result.AddPair('examples','Synthetic example for a controlled regression, not production knowledge.');
  Result.AddPair('context','Selected fixture business language; attributed to the synthetic test contributor.');
end;
function CurrentRow: TJSONObject;
var Items: TJSONArray; Value: TJSONValue;
begin
  Result:=nil; Items:=Store.KnowledgeJSON;
  try for Value in Items do if Value.GetValue<Int64>('id')=TermID then begin Result:=Value.Clone as TJSONObject; Break; end;
  finally Items.Free; end;
  if Result=nil then raise Exception.Create('Expected glossary record is absent');
end;
function SaveTerm(ARecord: TJSONObject; ID,Expected: Int64; const Author: string; const LinkJSON: string=''): Int64;
begin Result:=Store.SaveKnowledge(ID,Expected,Generation,ARecord.GetValue<string>('term').Trim,TDPHGlossary.Body(ARecord),Author,'glossary','','user','all',LinkJSON,'',ARecord.ToJSON); end;
procedure CaptureForm(AForm: TForm; const Name: string);
begin
  AForm.Show; Application.ProcessMessages; Bitmap:=TBitmap.Create(AForm.ClientWidth,AForm.ClientHeight);
  try if Bitmap.Canvas.BeginScene then try AForm.PaintTo(Bitmap.Canvas); finally Bitmap.Canvas.EndScene; end;
    Bitmap.SaveToFile(TPath.Combine(Root,'docs\'+Name));
  finally Bitmap.Free; end;
end;
procedure QueueNativeTerm(const Name: string; Cancel: Boolean);
var Action: TThreadProcedure;
begin
  ModalDriven:=False;
  Action:=procedure
    var I: Integer; ActiveEditor: TDPHGlossaryForm;
    begin
      for I:=0 to Screen.FormCount-1 do if Screen.Forms[I] is TDPHGlossaryForm then begin
        ActiveEditor:=Screen.Forms[I] as TDPHGlossaryForm; ModalDriven:=True;
        if Cancel then ActiveEditor.ModalResult:=mrCancel
        else begin ActiveEditor.TermEdit.Text:=Name; ActiveEditor.DefinitionMemo.Text:='Native draft definition';
          ActiveEditor.ContextMemo.Text:='Native controlled fixture'; ActiveEditor.AuthorEdit.Text:='Native contributor'; ActiveEditor.ApplyTermClick(nil); end;
        Break;
      end;
    end;
  TThread.ForceQueue(nil,Action);
end;
begin
  Application.Initialize;
  try
    Root:=TPath.GetFullPath(ParamStr(1)); if not TFile.Exists(TPath.Combine(Root,'DelphiProjectHandoff.dproj')) then raise Exception.Create('Pass the DPH source root');
    Work:=TPath.Combine(Root,'bin\glossary-validation'); SourceRoot:=TPath.Combine(Work,'source'); TDirectory.CreateDirectory(SourceRoot);
    DatabasePath:=TPath.Combine(Work,'glossary.dphdb');
    for Key in ['glossary.dphdb','glossary.dphdb-wal','glossary.dphdb-shm','glossary.dphdb-journal','other.dphdb','other.dphdb-wal','other.dphdb-shm','other.dphdb-journal'] do
      if TFile.Exists(TPath.Combine(Work,Key)) then TFile.Delete(TPath.Combine(Work,Key));
    for Key in TDirectory.GetFiles(TPath.Combine(Root,'tests\fixtures\semantics')) do TFile.Copy(Key,TPath.Combine(SourceRoot,ExtractFileName(Key)),True);
    OldHash:=THashSHA2.GetHashStringFromFile(TPath.Combine(SourceRoot,'Main.pas'));
    Term:=NewTerm('Settlement batch','SB','A synthetic group of payable entries; <script>literal text</script>.');
    try
      Check(TDPHGlossary.NameKey('  SETTLEMENT   batch  ')='settlement batch','Term names normalize case and repeated spaces');
      OtherTerm:=NewTerm('','',''); try Failed:=False; try TDPHGlossary.Validate(OtherTerm); except Failed:=True; end; Check(Failed,'Empty term/definition cannot be saved'); finally OtherTerm.Free; end;
      Term.GetValue<TJSONArray>('aliases').Add(' sb '); Failed:=False; try TDPHGlossary.Validate(Term); except Failed:=True; end;
      Check(Failed,'Duplicate aliases are rejected ignoring case and surrounding spaces'); Term.GetValue<TJSONArray>('aliases').Remove(1).Free;
      Term.GetValue<TJSONArray>('aliases').Add('Settlement batch'); Failed:=False; try TDPHGlossary.Validate(Term); except Failed:=True; end;
      Check(Failed,'An alias cannot duplicate its own term'); Term.GetValue<TJSONArray>('aliases').Remove(1).Free;
      Term.AddPair('unexpected','value'); Failed:=False; try TDPHGlossary.Validate(Term); except Failed:=True; end;
      Check(Failed,'Unknown structured fields are rejected'); Term.RemovePair('unexpected').Free;
      Term.GetValue<TJSONArray>('aliases').AddElement(TJSONNumber.Create(12)); Failed:=False; try TDPHGlossary.Validate(Term); except Failed:=True; end;
      Check(Failed,'Non-text aliases are rejected'); Term.GetValue<TJSONArray>('aliases').Remove(1).Free;
      Term.RemovePair('context').Free; Term.AddPair('context',''); Failed:=False; try TDPHGlossary.Validate(Term); except Failed:=True; end;
      Check(Failed,'Every term needs relevance/evidence context'); Term.RemovePair('context').Free; Term.AddPair('context','Controlled selected-project definition and source evidence.');
      Analyzer:=TDPHAnalyzer.Create; Semantic:=TDPHSemanticAnalyzer.Create;
      Store:=TDPHKnowledgeStore.Create(DatabasePath,SourceRoot,TPath.Combine(Root,'migrations'));
      try
        Store.InitializeProject('Glossary fixture','Delphi'); Config:=Store.AddConfiguration('Win32','37.0','[]','[]','Debug'); Store.SelectConfiguration(Config);
        Scan:=Analyzer.Scan(TPath.Combine(SourceRoot,'Semantic.dproj'),'Debug','Win32',[],[],False);
        try FixtureManifest:=Scan.Inventory.Manifest; Graph:=Semantic.Analyze(Scan);
          try Generation:=TDPHSemanticPersistence.Stage(Scan,Graph,Store,Config); TDPHSemanticPersistence.Publish(Scan,Graph,Store,Generation);
            View:=TDPHWorkspaceView.Create(TDPHWorkspaceView.Capture(Scan,Graph,Generation,'Semantic.dproj','Debug','Win32',[],[]));
          finally Graph.Free; end;
        finally Scan.Free; end;
        try
          Rows:=Store.LinkCandidates(Generation,'entity','Main.TMain.Click'); Links:=TJSONArray.Create;
          try Check(Rows.Count>0,'Controlled source provides exact evidence for a business term'); Link:=Rows.Items[0].Clone as TJSONObject;
            Link.AddPair('link_role','explains'); Links.AddElement(Link); Key:=Link.GetValue<string>('canonical_key');
            Failed:=False; try SaveTerm(Term,0,0,'',Links.ToJSON); except Failed:=True; end; Check(Failed,'Saving requires a named contributor');
            TermID:=SaveTerm(Term,0,0,'Glossary test contributor',Links.ToJSON);
          finally Rows.Free; Links.Free; end;
          Row:=CurrentRow;
          try Revision:=Row.GetValue<Int64>('revision');
            Check((Row.GetValue<string>('state')='needs_review') and (Row.GetValue<string>('structured_json')=Term.ToJSON),'Save preserves exact structured fields and requires explicit review');
            Check(Row.GetValue<TJSONArray>('rich_links').Count=1,'Term retains its exact source link');
            Check(Row.GetValue<string>('body')=TDPHGlossary.Body(Term),'Readable definition and structured fields agree');
          finally Row.Free; end;
          OtherTerm:=NewTerm('sb','','Conflicting alias'); try Failed:=False; try SaveTerm(OtherTerm,0,0,'Author'); except Failed:=True; end;
            Check(Failed,'A new term cannot reuse an existing alias'); finally OtherTerm.Free; end;
          OtherTerm:=NewTerm('Other term',' settlement   BATCH ','Conflicting term'); try Failed:=False; try SaveTerm(OtherTerm,0,0,'Author'); except Failed:=True; end;
            Check(Failed,'A new alias cannot reuse another normalized term'); finally OtherTerm.Free; end;
          Failed:=False; try Store.SaveKnowledge(TermID,Revision,Generation,'Settlement batch','Contradictory definition','Author','glossary','','user','all','','',Term.ToJSON); except Failed:=True; end;
          Check(Failed,'Typed fields cannot diverge from their generated readable body');
          Failed:=False; try Store.SaveKnowledge(TermID,Revision,Generation,'Settlement batch',TDPHGlossary.Body(Term),'Author','glossary','','user','all'); except Failed:=True; end;
          Check(Failed,'Plain text editing cannot discard glossary fields');
          Failed:=False; try Store.ReviewKnowledge(TermID,Revision,Generation,'','verified'); except Failed:=True; end;
          Check(Failed,'Verification requires a named reviewer');
          Store.ReviewKnowledge(TermID,Revision,Generation,'Glossary named reviewer','verified'); OldRevision:=Revision; Row:=CurrentRow;
          try Revision:=Row.GetValue<Int64>('revision');
            Check((Revision<>OldRevision) and (Row.GetValue<string>('state')='verified') and (Row.GetValue<TJSONArray>('history').Count=2),'Review appends an immutable verified revision');
          finally Row.Free; end;
          Failed:=False; try SaveTerm(Term,TermID,OldRevision,'Stale author'); except Failed:=True; end; Check(Failed,'Stale editor cannot overwrite a later review');
          Failed:=False; try Store.ReviewKnowledge(TermID,OldRevision,Generation,'Stale reviewer','verified'); except Failed:=True; end; Check(Failed,'Stale reviewer cannot approve an obsolete revision');
          Term.RemovePair('term').Free; Term.AddPair('term','Settlement group'); Definition:='Updated synthetic definition with a recorded revision.';
          Term.RemovePair('definition').Free; Term.AddPair('definition',Definition); Check(SaveTerm(Term,TermID,Revision,'Revising contributor')=TermID,'Renaming a term preserves its stable knowledge identity');
          Row:=CurrentRow; try Revision:=Row.GetValue<Int64>('revision');
            Check((Row.GetValue<TJSONArray>('history').Count=3) and (Row.GetValue<string>('state')='needs_review'),'Definition edit preserves history and reopens review');
          finally Row.Free; end;
          Store.ReviewKnowledge(TermID,Revision,Generation,'Final named reviewer','verified'); Row:=CurrentRow;
          try Revision:=Row.GetValue<Int64>('revision'); PublishedRevision:=Row.GetValue<string>('revision'); finally Row.Free; end;
          Rows:=Store.SearchProject(Generation,'SB','knowledge',0); try Check(Rows.Count=1,'Project search retrieves a glossary term through its alias'); finally Rows.Free; end;
          Rows:=Store.SearchProject(Generation,'Updated synthetic','knowledge',0); try Check(Rows.Count=1,'Project search indexes the latest definition'); finally Rows.Free; end;
          Rows:=Store.SearchProject(Generation,'Settlement group','knowledge',0); try Check(Rows.Count=1,'Project search indexes the renamed term'); finally Rows.Free; end;
          OtherStore:=TDPHKnowledgeStore.Create(TPath.Combine(Work,'other.dphdb'),SourceRoot,TPath.Combine(Root,'migrations'));
          try OtherStore.InitializeProject('Other scoped project','Delphi'); OtherConfig:=OtherStore.AddConfiguration('Win32','37.0','[]','[]','Debug'); OtherStore.SelectConfiguration(OtherConfig);
            OtherStore.ObserveManifest(FixtureManifest); OtherGeneration:=OtherStore.BeginGeneration(OtherConfig,'isolation-fixture',FixtureManifest);
            OtherStore.PublishGeneration(OtherGeneration,FixtureManifest,'{}',True);
            Rows:=OtherStore.KnowledgeJSON; try Check(Rows.Count=0,'Another project database cannot see these terms'); finally Rows.Free; end;
            Check(OtherStore.SaveKnowledge(0,0,OtherGeneration,'Settlement group',TDPHGlossary.Body(Term),'Other contributor','glossary','','user','all','','',Term.ToJSON)>0,'The same business name can exist independently in another selected project');
          finally OtherStore.Free; end;
          Rows:=Store.KnowledgeJSON;
          try
            Model:=TDPHDocumentModel.Create(View,Rows,[],[],False,False);
            try
              Row:=Model.Document.GetValue<TJSONArray>('knowledge').Items[0] as TJSONObject;
              Check((Row.GetValue<string>('revision')=PublishedRevision) and (Row.GetValue<string>('body')=TDPHGlossary.Body(Term)),'Canonical handoff retains the exact reviewed term revision and definition');
              Check(Row.GetValue<TJSONObject>('structured_record').GetValue<string>('term')='Settlement group','Canonical handoff preserves typed term fields');
              Index:=1; while TDirectory.Exists(TPath.Combine(Work,'handoff-'+IntToStr(Index))) do Inc(Index);
              TDPHPublisher.Export(Model,Store,TPath.Combine(Work,'handoff-'+IntToStr(Index)));
              TDPHPublisher.Validate(TPath.Combine(Work,'handoff-'+IntToStr(Index)),Model.Document.GetValue<string>('input_fingerprint'),False);
              Check(True,'Complete glossary handoff passes package validation');
              Check(TFile.ReadAllText(TPath.Combine(Work,'handoff-'+IntToStr(Index)+'\indexes\glossary.jsonl'),TEncoding.UTF8)=Row.ToJSON+#10,'Dedicated glossary JSONL exactly matches canonical knowledge');
              Check(TFile.ReadAllText(TPath.Combine(Work,'handoff-'+IntToStr(Index)+'\index.html'),TEncoding.UTF8).Contains('id="business-glossary"'),'Offline HTML exposes a dedicated business glossary index');
              for Key in ['User_Guide.docx','Engineering_Guide.docx'] do begin
                Archive:=TZipFile.Create; try Archive.Open(TPath.Combine(Work,'handoff-'+IntToStr(Index)+'\'+Key),zmRead); Archive.Read('word/document.xml',Bytes);
                  Check(TEncoding.UTF8.GetString(Bytes).Contains(Definition),'Reviewed definition appears in '+Key);
                finally Archive.Free; end;
              end;
              TFile.WriteAllText(TPath.Combine(Work,'handoff-'+IntToStr(Index)+'\indexes\glossary.jsonl'),'tampered',TEncoding.UTF8);
              Failed:=False; try TDPHPublisher.Validate(TPath.Combine(Work,'handoff-'+IntToStr(Index)),Model.Document.GetValue<string>('input_fingerprint'),False); except Failed:=True; end;
              Check(Failed,'Tampered glossary export is rejected');
              Report:=TJSONObject.ParseJSONValue(TFile.ReadAllText(TPath.Combine(Work,'handoff-'+IntToStr(Index)+'\validation\manifest-sha256.json'),TEncoding.UTF8)) as TJSONObject;
              try Report.RemovePair('indexes/glossary.jsonl').Free;
                Report.AddPair('indexes/glossary.jsonl',THashSHA2.GetHashStringFromFile(TPath.Combine(Work,'handoff-'+IntToStr(Index)+'\indexes\glossary.jsonl')));
                TFile.WriteAllText(TPath.Combine(Work,'handoff-'+IntToStr(Index)+'\validation\manifest-sha256.json'),Report.Format(2),TEncoding.UTF8);
              finally Report.Free; end;
              Failed:=False; try TDPHPublisher.Validate(TPath.Combine(Work,'handoff-'+IntToStr(Index)),Model.Document.GetValue<string>('input_fingerprint'),False); except Failed:=True; end;
              Check(Failed,'Rehashing altered glossary JSONL cannot bypass canonical agreement');
              TFile.WriteAllBytes(TPath.Combine(Work,'handoff-'+IntToStr(Index)+'\indexes\glossary.jsonl'),TEncoding.UTF8.GetBytes(Row.ToJSON+#10));
              Report:=TJSONObject.ParseJSONValue(TFile.ReadAllText(TPath.Combine(Work,'handoff-'+IntToStr(Index)+'\validation\manifest-sha256.json'),TEncoding.UTF8)) as TJSONObject;
              try Report.RemovePair('indexes/glossary.jsonl').Free;
                Report.AddPair('indexes/glossary.jsonl',THashSHA2.GetHashStringFromFile(TPath.Combine(Work,'handoff-'+IntToStr(Index)+'\indexes\glossary.jsonl')));
                TFile.WriteAllText(TPath.Combine(Work,'handoff-'+IntToStr(Index)+'\validation\manifest-sha256.json'),Report.Format(2),TEncoding.UTF8);
              finally Report.Free; end;
              TDPHPublisher.Validate(TPath.Combine(Work,'handoff-'+IntToStr(Index)),Model.Document.GetValue<string>('input_fingerprint'),False);
            finally Model.Free; end;
            Model:=TDPHDocumentModel.Create(View,Rows,[],[],False,False,nil,False,'engineer');
            try Check(Model.Document.GetValue<TJSONArray>('knowledge').Count=1,'All-reader glossary remains present in engineering-scoped handoffs'); finally Model.Free; end;
            Model:=TDPHDocumentModel.Create(View,Rows,[],['main.pas'],False,False);
            try Check(Model.Document.GetValue<TJSONArray>('knowledge').Count=0,'Confidential source exclusion removes dependent glossary evidence/content'); finally Model.Free; end;
          finally Rows.Free; end;
          PreferencesPath:=TPath.Combine(TPath.GetHomePath,'AppData\Local\DPH\workspace.json'); PreferencesHash:='';
          if TFile.Exists(PreferencesPath) then PreferencesHash:=THashSHA2.GetHashStringFromFile(PreferencesPath);
          NativeForm:=TDPHMainForm.Create(nil);
          try NativeForm.PollTimer.Enabled:=False; NativeForm.ChangeTimer.Enabled:=False; NativeForm.LoadView(View.Document.Clone as TJSONObject); NativeForm.LoadKnowledge(Store.KnowledgeJSON);
            Check(NativeForm.WorkspacePageCombo.Items.IndexOf('Business glossary')>=0,'Workspace selector exposes Business glossary');
            Check(NativeForm.GlossaryList.Count=1,'Native glossary displays saved scoped terms');
            NativeForm.GlossaryFilterEdit.Text:='SB'; NativeForm.GlossaryFilterChange(nil);
            Check((NativeForm.GlossaryList.Count=1) and NativeForm.GlossaryMemo.Text.Contains(Definition),'Native alias filter finds and explains the current term');
            NativeForm.OpenGlossaryKnowledgeClick(nil);
            Check(NativeForm.KnowledgeBodyMemo.ReadOnly and NativeForm.KnowledgeHistoryMemo.Text.Contains('Immutable revision history'),'Open in Knowledge exposes history without allowing conflicting plain-text edits');
            NativeForm.WorkspaceTabs.ActiveTab:=NativeForm.GlossaryTab; CaptureForm(NativeForm,'phase1-glossary-workspace.png');
            NativeForm.WindowState:=TWindowState.wsNormal; NativeForm.Width:=960; NativeForm.Height:=600; Application.ProcessMessages;
            CaptureForm(NativeForm,'phase1-glossary-compact.png'); Check(NativeForm.GlossaryMemo.Height>=80,'Glossary definition remains usable at the minimum workspace size ('+FloatToStr(NativeForm.GlossaryMemo.Height)+')');
            QueueNativeTerm('',True); NativeForm.EditGlossaryClick(NativeForm.EditGlossaryButton);
            Check(ModalDriven and (NativeForm.KnowledgeTitleEdit.Text='Settlement group'),'Cancelling native term editing preserves the loaded record');
            QueueNativeTerm('Native renamed term',False); NativeForm.EditGlossaryClick(NativeForm.EditGlossaryButton);
            Check(ModalDriven and NativeForm.KnowledgeBodyMemo.Text.Contains('Native renamed term'),'Native Edit term prepares updated structured fields');
            NativeForm.DiscardKnowledgeClick(nil);
            QueueNativeTerm('Native term',False); NativeForm.EditGlossaryClick(NativeForm.NewGlossaryButton);
            Check(ModalDriven and NativeForm.KnowledgeBodyMemo.Text.Contains('Native draft definition') and (NativeForm.WorkspaceTabs.ActiveTab=NativeForm.KnowledgeTab),'Native New term creates the correct attributed Knowledge draft');
            NativeForm.EditGlossaryClick(NativeForm.NewGlossaryButton);
            Check(NativeForm.StatusLabel.Text.Contains('Save or discard'),'Unsaved glossary drafts block replacement');
            NativeForm.DiscardKnowledgeClick(nil); Check(not NativeForm.KnowledgeBodyMemo.ReadOnly,'Discard restores ordinary Knowledge editing');
          finally NativeForm.Free; end;
          Check((not TFile.Exists(PreferencesPath) and (PreferencesHash='')) or (TFile.Exists(PreferencesPath) and (THashSHA2.GetHashStringFromFile(PreferencesPath)=PreferencesHash)),'Native validation does not add test databases to the user project catalog');
          Editor:=TDPHGlossaryForm.Create(nil);
          try Editor.LoadRecord(Term,'Native field contributor'); Row:=Editor.RecordJSON;
            try Check((TDPHGlossary.Body(Row)=TDPHGlossary.Body(Term)) and (Row.GetValue<TJSONArray>('aliases').ToJSON=Term.GetValue<TJSONArray>('aliases').ToJSON),'IDE-designed editor round-trips all glossary fields'); finally Row.Free; end;
            Editor.AuthorEdit.Text:=''; Editor.ApplyTermClick(nil); Check(Editor.ModalResult<>mrOk,'Native editor rejects missing attribution');
            Editor.AuthorEdit.Text:='Native field contributor'; Editor.ApplyTermClick(nil); Check(Editor.ModalResult=mrOk,'Native field validation accepts a complete term');
            Editor.ModalResult:=mrNone; CaptureForm(Editor,'phase1-glossary-editor.png'); Editor.Width:=620; Editor.Height:=480; CaptureForm(Editor,'phase1-glossary-editor-compact.png'); Editor.Hide;
          finally Editor.Free; end;
          Check(THashSHA2.GetHashStringFromFile(TPath.Combine(SourceRoot,'Main.pas'))=OldHash,'Glossary capture, review and native inspection do not modify selected source');
          TFile.AppendAllText(TPath.Combine(SourceRoot,'Main.pas'),sLineBreak+'// controlled glossary evidence change',TEncoding.UTF8);
          Scan:=Analyzer.Scan(TPath.Combine(SourceRoot,'Semantic.dproj'),'Debug','Win32',[],[],False);
          try Graph:=Semantic.Analyze(Scan); try TDPHSemanticPersistence.Stage(Scan,Graph,Store,Config); finally Graph.Free; end; finally Scan.Free; end;
          Row:=CurrentRow; try Check(Row.GetValue<string>('pending')='1','A source-evidence change reopens term review independently of the last verified text'); finally Row.Free; end;
          Failed:=False; try Store.ReviewKnowledge(TermID,Revision,Generation,'Obsolete source reviewer','verified'); except Failed:=True; end;
          Check(Failed,'Review cannot approve a glossary term against obsolete source fingerprints');
          Check(Store.IntegrityCheck='ok','All glossary revisions and source links preserve SQLite integrity');
        finally View.Free; end;
      finally Store.Free; Semantic.Free; Analyzer.Free; end;
      Store:=TDPHKnowledgeStore.Create(DatabasePath,SourceRoot,TPath.Combine(Root,'migrations'));
      try Row:=CurrentRow; try Check((Row.GetValue<string>('structured_json')=Term.ToJSON) and (Row.GetValue<TJSONArray>('history').Count=4),'Reopened project retains exact term fields and all save/review revisions'); finally Row.Free; end; finally Store.Free; end;
      Report:=TJSONObject.Create;
      try Report.AddPair('checks_passed',TJSONNumber.Create(Checks)); Report.AddPair('requirements','06.12, 12.09'); Report.AddPair('work',Work);
        Report.AddPair('native_evidence','FMX controls instantiated from .fmx and rendered with PaintTo; modal editing and draft flow exercised in the native form. Not a target application screenshot.');
        Report.AddPair('scope','Structured glossary fields, duplicates, rename, immutable revisions, attribution/review, project isolation, search, canonical/HTML/DOCX/JSONL, exclusions, tamper, native controls and changed source review');
        TFile.WriteAllText(TPath.Combine(Root,'docs\phase1-glossary-validation.json'),Report.Format(2),TEncoding.UTF8);
      finally Report.Free; end;
    finally Term.Free; end;
    Writeln('PASS business glossary: ',Checks,' checks');
  except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode:=1; end; end;
end.
