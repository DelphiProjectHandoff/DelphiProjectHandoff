program DPH.Tests.Hardening;
{$APPTYPE CONSOLE}
{$SETPEFLAGS $20}
uses System.SysUtils, System.Classes, System.IOUtils, System.JSON, System.Hash, System.Diagnostics,
  System.StrUtils, System.Generics.Collections, Winapi.Windows, Winapi.ActiveX, Winapi.PsAPI, FMX.Forms, FMX.WebBrowser, FMX.Graphics,
  DPH.UI.Main in '..\DPH.UI.Main.pas', DPH.Workspace.Worker in '..\DPH.Workspace.Worker.pas',
  DPH.Workspace.Model in '..\DPH.Workspace.Model.pas', DPH.Storage.Database in '..\DPH.Storage.Database.pas',
  DPH.Publish.Model in '..\DPH.Publish.Model.pas', DPH.Publish.Export in '..\DPH.Publish.Export.pas';
var Root,Work,Fixture,Relocated,ReferenceRoot,Bundle,Key,FirstGraph,FirstKeys,Path,OldRoot,SourceArtifact: string;
    Worker: TDPHWorkspaceWorker; Request: TDPHWorkspaceRequest; Response: TDPHWorkspaceResponse;
    View: TDPHWorkspaceView; Store: TDPHKnowledgeStore; Model: TDPHDocumentModel;
    Rows: TJSONArray; J,Report,Hashes,Manifest,Canonical: TJSONObject; V: TJSONValue;
    Form: TDPHMainForm; Watch,Attempt: TStopwatch; Gap,LastTick,MaxGap,FullMS,CacheMS,IncrementalMS: Int64;
    Generation: Int64; Count,Checks: Integer; Failed,Done: Boolean; JSResult,Original,Hash: string;
    Memory: PROCESS_MEMORY_COUNTERS; ID: TGUID; Bitmap: TBitmap;
procedure Check(OK: Boolean; const Text: string);
begin if not OK then raise Exception.Create('FAIL '+Text); Inc(Checks); Writeln('PASS ',Checks,': ',Text); Flush(Output); end;
function WaitResponse: TDPHWorkspaceResponse;
var Timer: TStopwatch;
begin
  Timer:=TStopwatch.StartNew; LastTick:=Timer.ElapsedMilliseconds;
  repeat
    Application.ProcessMessages; Gap:=Timer.ElapsedMilliseconds-LastTick; if Gap>MaxGap then MaxGap:=Gap; LastTick:=Timer.ElapsedMilliseconds;
    if Worker.Poll(Result) then begin if not Result.Busy then Exit; Result.Free; end;
    if Timer.ElapsedMilliseconds>600000 then raise Exception.Create('Worker exceeded ten-minute test bound');
    TThread.Sleep(10);
  until False;
end;
procedure Submit;
begin Worker.Submit(Request); Response:=WaitResponse;
  try Check(not Response.Failed,Response.MessageText);
    if Response.Document<>nil then begin View.Free; View:=TDPHWorkspaceView.Create(Response.Document); Response.Document:=nil; end;
  finally Response.Free; end;
end;
procedure RefreshHashes(const Directory: string);
var FileName,Relative: string;
begin
  Hashes:=TJSONObject.Create;
  try for FileName in TDirectory.GetFiles(Directory,'*',TSearchOption.soAllDirectories) do begin
    Relative:=ExtractRelativePath(IncludeTrailingPathDelimiter(Directory),FileName).Replace('\','/');
    if Relative<>'validation/manifest-sha256.json' then Hashes.AddPair(Relative,THashSHA2.GetHashStringFromFile(FileName));
  end; TFile.WriteAllText(TPath.Combine(Directory,'validation\manifest-sha256.json'),Hashes.ToJSON,TEncoding.UTF8);
  finally Hashes.Free; end;
end;
procedure PublishBundle(const Directory: string; const Seeds: TArray<string>; IncludeSource: Boolean = False);
begin
  Store:=TDPHKnowledgeStore.Create(Request.Database,TDPHKnowledgeStore.ProjectRoot(Request.Database),TPath.Combine(Root,'migrations'));
  try Rows:=Store.KnowledgeJSON;
    try Model:=TDPHDocumentModel.Create(View,Rows,Seeds,[],Request.Entry='',Store.Status.AnalysisStale);
      try TDPHPublisher.Export(Model,Store,Directory,False,IncludeSource);
        Store.RecordExport(View.Document.GetValue<Int64>('generation_id'),Directory,THashSHA2.GetHashString(Model.Document.ToJSON),'{"test_scope":"handoff"}',Store.Status.AnalysisStale);
      finally Model.Free; end;
    finally Rows.Free; end;
  finally Store.Free; end;
end;
begin
  CoInitialize(nil); Application.Initialize; View:=nil; Report:=TJSONObject.Create;
  try
    try
      Root:=TPath.GetFullPath(ParamStr(1)); CreateGUID(ID); Work:=TPath.Combine(Root,'bin\wp7-tests-'+GUIDToString(ID));
      Fixture:=TPath.Combine(Work,'fixture'); Relocated:=TPath.Combine(Work,'relocated'); TDirectory.CreateDirectory(Fixture); TDirectory.CreateDirectory(Relocated);
      for Path in TDirectory.GetFiles(TPath.Combine(Root,'tests\fixtures\semantics')) do begin
        TFile.Copy(Path,TPath.Combine(Fixture,ExtractFileName(Path))); TFile.Copy(Path,TPath.Combine(Relocated,ExtractFileName(Path)));
      end;
      Worker:=TDPHWorkspaceWorker.Create(Root);
      try
        Request.Command:='full'; Request.Database:=TPath.Combine(Work,'fixture.dphdb'); Request.Entry:=TPath.Combine(Fixture,'Semantic.dproj'); Request.Configuration:='Debug'; Request.Platform:='Win32';
        Submit; Generation:=View.Document.GetValue<Int64>('generation_id'); FirstKeys:=View.Document.GetValue<TJSONArray>('semantics.symbols').ToJSON;
        Rows:=View.Search('Click','routine',''); try Key:=(Rows.Items[0] as TJSONObject).GetValue<string>('key'); finally Rows.Free; end;
        Store:=TDPHKnowledgeStore.Create(Request.Database,Fixture,TPath.Combine(Root,'migrations'));
        try Store.SaveKnowledge(0,0,Generation,'Portability note','Authored rationale stays linked','WP7 test author','engineering_rule',Key);
          Store.BackupTo(TPath.Combine(Work,'portable.dphdb'));
        finally Store.Free; end;
        TDirectory.CreateDirectory(TPath.Combine(Work,'portable.dphdb.views'));
        for Path in TDirectory.GetFiles(Request.Database+'.views') do TFile.Copy(Path,TPath.Combine(Work,'portable.dphdb.views\'+ExtractFileName(Path)));
        Path:=Request.Database; Request.Database:=TPath.Combine(Work,'portable.dphdb'); Request.Command:='open'; Submit;
        Check(View.Document.GetValue<Int64>('generation_id')=Generation,'Moved database resolves its adjacent verified cache without old absolute paths');
        Request.Database:=Path; Request.Command:='relocate'; Request.GenerationID:=Generation; Request.Entry:=TPath.Combine(Relocated,'Semantic.dproj'); Submit;
        Check(SameFileName(ExcludeTrailingPathDelimiter(View.Document.GetValue<string>('root')),Relocated),'Explicit relocation adopts only the verified copied source root');
        Check(View.Document.GetValue<TJSONArray>('semantics.symbols').ToJSON=FirstKeys,'Verified source relocation preserves logical symbols and exact source ranges');
        Store:=TDPHKnowledgeStore.Create(Request.Database,Relocated,TPath.Combine(Root,'migrations'));
        try Rows:=Store.KnowledgeJSON; try Check((Rows.Count=1) and ((Rows.Items[0] as TJSONObject).GetValue<string>('body')='Authored rationale stays linked'),'Relocation preserves authored knowledge');
          Check((Rows.Items[0] as TJSONObject).GetValue<string>('state')='needs_review','Relocation cannot manufacture human verification'); finally Rows.Free; end;
          Check(Store.IntegrityCheck='ok','Relocation retains SQLite and foreign-key integrity');
        finally Store.Free; end;
        Generation:=View.Document.GetValue<Int64>('generation_id'); Request.GenerationID:=Generation;
        Original:=TFile.ReadAllText(TPath.Combine(Fixture,'Main.pas'),TEncoding.UTF8); TFile.AppendAllText(TPath.Combine(Fixture,'Main.pas'),#10+'// different copy',TEncoding.UTF8);
        Request.Entry:=TPath.Combine(Fixture,'Semantic.dproj'); Worker.Submit(Request); Response:=WaitResponse;
        try Check(Response.Failed,'Different source contents cannot be accepted as relocation'); finally Response.Free; end;
        Check(SameFileName(ExcludeTrailingPathDelimiter(TDPHKnowledgeStore.ProjectRoot(Request.Database)),Relocated),'Rejected relocation retains prior source identity');
        Request.Entry:=TPath.Combine(Relocated,'Semantic.dproj'); Bundle:=TPath.Combine(Work,'fixture-bundle'); PublishBundle(Bundle,[]);
        Hash:=View.Document.GetValue<string>('semantics.input_fingerprint');
        TDPHPublisher.Validate(Bundle,Hash,False); Check(True,'Full fixture passes independent semantic and JSONL validation');
        Path:=TPath.Combine(Bundle,'indexes\symbols.jsonl'); Original:=TFile.ReadAllText(Path,TEncoding.UTF8); TFile.WriteAllText(Path,'{}'+#10,TEncoding.UTF8); RefreshHashes(Bundle);
        Failed:=False; try TDPHPublisher.Validate(Bundle,Hash,False); except Failed:=True; end; Check(Failed,'Rehashed but inconsistent JSONL is rejected against canonical facts');
        TFile.WriteAllText(Path,Original,TEncoding.UTF8); RefreshHashes(Bundle);
        Canonical:=TJSONObject.ParseJSONValue(TFile.ReadAllText(TPath.Combine(Bundle,'canonical.json'),TEncoding.UTF8)) as TJSONObject;
        Manifest:=TJSONObject.ParseJSONValue(TFile.ReadAllText(TPath.Combine(Bundle,'manifest.json'),TEncoding.UTF8)) as TJSONObject;
        try J:=Canonical.GetValue<TJSONArray>('symbols').Items[0] as TJSONObject; J.RemovePair('generation_id').Free; J.AddPair('generation_id',TJSONNumber.Create(999999));
          TFile.WriteAllText(TPath.Combine(Bundle,'canonical.json'),Canonical.ToJSON,TEncoding.UTF8); Manifest.RemovePair('canonical_hash').Free; Manifest.AddPair('canonical_hash',THashSHA2.GetHashString(Canonical.ToJSON));
          TFile.WriteAllText(TPath.Combine(Bundle,'manifest.json'),Manifest.ToJSON,TEncoding.UTF8); RefreshHashes(Bundle);
        finally Canonical.Free; Manifest.Free; end;
        Failed:=False; try TDPHPublisher.Validate(Bundle,Hash,False); except Failed:=True; end; Check(Failed,'Rehashed cross-generation source fact is rejected');
        ReferenceRoot:=TPath.Combine(Root,'samples\reference-vcl2fmx-v6.0.0');
        Request.Command:='full'; Request.Entry:=TPath.Combine(ReferenceRoot,'VCL2FMXConverter.dproj'); Request.Database:=TPath.Combine(Work,'reference.dphdb'); Request.GenerationID:=0; Request.Defines:=['MSWINDOWS','WIN32'];
        Watch:=TStopwatch.StartNew; Submit; FullMS:=Watch.ElapsedMilliseconds;
        FirstGraph:=THashSHA2.GetHashString(View.Document.GetValue<TJSONObject>('semantics').ToJSON);
        Check(View.Document.GetValue<string>('semantics.input_fingerprint')='85af5e4f63dbf775e6b1dc70b03c53cf33d91f1cb8c5d203118d0b6c7b3490d3','Pinned reference inventory matches approved v6.0 fingerprint');
        Check(not View.Document.GetValue<Boolean>('analysis_complete'),'Pinned reference retains honest partial coverage');
        // The extended analyzer adds 32 startup/phase routines, four async sites
        // and 17 output artifacts to the original 4909-symbol pinned baseline.
        Count:=View.Document.GetValue<TJSONArray>('semantics.symbols').Count; Check(Count=4962,'Pinned reference expanded symbol baseline survives normalized database publication');
        Request.Command:='open'; Watch:=TStopwatch.StartNew; Submit; CacheMS:=Watch.ElapsedMilliseconds;
        Check(THashSHA2.GetHashString(View.Document.GetValue<TJSONObject>('semantics').ToJSON)=FirstGraph,'Cached reference preserves the exact semantic generation');
        Request.Command:='incremental'; Watch:=TStopwatch.StartNew; Submit; IncrementalMS:=Watch.ElapsedMilliseconds;
        Check(THashSHA2.GetHashString(View.Document.GetValue<TJSONObject>('semantics').ToJSON)=FirstGraph,'Full and incremental reference pipelines produce identical semantic graphs');
        Rows:=View.Search('btnConvertClick','routine',''); try Check(Rows.Count=1,'Reference Explorer locates convert event handler'); Key:=(Rows.Items[0] as TJSONObject).GetValue<string>('key'); finally Rows.Free; end;
        Form:=TDPHMainForm.Create(nil);
        try Form.PollTimer.Enabled:=False; Form.ChangeTimer.Enabled:=False; Form.LoadView(View.Document.Clone as TJSONObject);
          Form.SearchEdit.Text:='btnConvertClick'; Form.ExplorerList.ItemIndex:=0; Form.ExplorerClick(nil);
          Check(ContainsText(Form.InspectorMemo.Text,'btnConvertClick'),'Reference FMX inspector presents the selected captured handler');
          Form.WorkspaceTabs.ActiveTab:=Form.GraphTab; Form.Show; Application.ProcessMessages;
          Bitmap:=TBitmap.Create(Form.ClientWidth,Form.ClientHeight); try
            if Bitmap.Canvas.BeginScene then try Form.PaintTo(Bitmap.Canvas); finally Bitmap.Canvas.EndScene; end;
            Bitmap.SaveToFile(TPath.Combine(Root,'docs\wp7-reference-workspace.png')); finally Bitmap.Free; end;
          Bundle:=TPath.Combine(Work,'reference-task'); PublishBundle(Bundle,[Key],True);
          TDPHPublisher.Validate(Bundle,View.Document.GetValue<string>('semantics.input_fingerprint'),False);
          Check(True,'Pinned reference task handoff validates with explicit partial/stale evidence');
          Failed:=False; try TDPHPublisher.Validate(Bundle,View.Document.GetValue<string>('semantics.input_fingerprint')); except Failed:=True; end;
          Check(Failed,'Default validation rejects a reference bundle explicitly marked stale');
          Form.WorkspaceTabs.ActiveTab:=Form.PublishTab; Form.PublishBrowser.OnShouldLoadURL:=nil;
          Form.PublishBrowser.WindowsEngine:=TWindowsEngine.EdgeOnly; Form.PublishBrowser.Visible:=True;
          Form.PublishBrowser.Navigate('file://'+TPath.Combine(Bundle,'index.html'));
          Watch:=TStopwatch.StartNew; JSResult:='';
          repeat
            Done:=False;
            Form.PublishBrowser.EvaluateJavaScript('document.getElementById("search") ? "DPH_READY" : "WAIT"',TJavaScriptResultCallback(procedure(const Value: string) begin JSResult:=Value; Done:=True; end));
            Attempt:=TStopwatch.StartNew;
            while not Done and (Attempt.ElapsedMilliseconds<250) do begin Application.ProcessMessages; TThread.Sleep(10); end;
            if ContainsText(JSResult,'DPH_READY') then Break;
            Application.ProcessMessages; TThread.Sleep(50);
          until Watch.ElapsedMilliseconds>20000;
          Check(ContainsText(JSResult,'DPH_READY'),'Real FMX WebView2 loads the offline generated page and runs local search JavaScript');
          Done:=False; Form.PublishBrowser.EvaluateJavaScript('(()=>{const s=document.getElementById("search");s.value="no_such_symbol_34789";s.dispatchEvent(new Event("input"));return Array.from(document.querySelectorAll("article")).every(x=>x.hidden) ? "SEARCH_OK":"FAIL";})()',TJavaScriptResultCallback(procedure(const Value: string) begin JSResult:=Value; Done:=True; end));
          Watch:=TStopwatch.StartNew; while not Done and (Watch.ElapsedMilliseconds<5000) do begin Application.ProcessMessages; TThread.Sleep(10); end;
          Check(Done and ContainsText(JSResult,'SEARCH_OK'),'Offline search filters actual rendered symbol articles');
          J:=TJSONObject.ParseJSONValue(TFile.ReadAllText(TPath.Combine(Bundle,'source-navigation.json'),TEncoding.UTF8)) as TJSONObject;
          try SourceArtifact:='';
            for V in J.GetValue<TJSONArray>('files') do
              if V.GetValue<string>('state')='redacted_captured_text' then begin SourceArtifact:=V.GetValue<string>('artifact'); Break; end;
          finally J.Free; end;
          Check(SourceArtifact<>'','Reference task includes an eligible redacted source browsing page');
          Form.PublishBrowser.Navigate('file://'+TPath.Combine(Bundle,SourceArtifact.Replace('/',PathDelim)));
          Watch:=TStopwatch.StartNew; JSResult:='';
          repeat
            Done:=False;
            Form.PublishBrowser.EvaluateJavaScript('document.title==="Captured source browsing view" && document.querySelector("pre span[id^=L]") ? "SOURCE_READY":"WAIT"',TJavaScriptResultCallback(procedure(const Value: string) begin JSResult:=Value; Done:=True; end));
            Attempt:=TStopwatch.StartNew;
            while not Done and (Attempt.ElapsedMilliseconds<250) do begin Application.ProcessMessages; TThread.Sleep(10); end;
            if ContainsText(JSResult,'SOURCE_READY') then Break;
            Application.ProcessMessages; TThread.Sleep(50);
          until Watch.ElapsedMilliseconds>20000;
          Check(ContainsText(JSResult,'SOURCE_READY'),'Real FMX WebView2 renders source excerpts with original line anchors');
          Bitmap:=Form.PublishBrowser.CaptureBitmap;
          Check(Bitmap<>nil,'Source excerpt browser bitmap captured for visual review');
          try Bitmap.SaveToFile(TPath.Combine(Root,'docs\completion-source-browser.png')); finally Bitmap.Free; end;
          Form.Hide;
        finally Form.Free; end;
        Store:=TDPHKnowledgeStore.Create(Request.Database,ReferenceRoot,TPath.Combine(Root,'migrations'));
        try Check(Store.IntegrityCheck='ok','Large reference database retains integrity after multiple captures and export'); finally Store.Free; end;
      finally Worker.Free; View.Free; end;
      ZeroMemory(@Memory,SizeOf(Memory)); Memory.cb:=SizeOf(Memory); GetProcessMemoryInfo(GetCurrentProcess,@Memory,SizeOf(Memory));
      Report.AddPair('checks_passed',TJSONNumber.Create(Checks)); Report.AddPair('work',Work); Report.AddPair('reference_bundle',Bundle);
      Report.AddPair('reference_full_ms',TJSONNumber.Create(FullMS)); Report.AddPair('reference_cached_ms',TJSONNumber.Create(CacheMS)); Report.AddPair('reference_incremental_ms',TJSONNumber.Create(IncrementalMS));
      Report.AddPair('ui_message_pump_max_gap_ms',TJSONNumber.Create(MaxGap)); Report.AddPair('peak_working_set_bytes',TJSONNumber.Create(Int64(Memory.PeakWorkingSetSize)));
      Report.AddPair('independent_first_time_programmer','not_run; requires a human participant');
      TFile.WriteAllText(TPath.Combine(Root,'docs\wp7-validation.json'),Report.Format(2),TEncoding.UTF8);
      Writeln('PASS WP7: ',Checks,' checks');
    except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode:=1; end; end;
  finally Report.Free; CoUninitialize; end;
end.
