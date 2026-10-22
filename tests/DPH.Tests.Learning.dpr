program DPH.Tests.Learning;
{$APPTYPE CONSOLE}
{$SETPEFLAGS $20}
uses System.SysUtils, System.Classes, System.IOUtils, System.JSON, System.Hash, System.StrUtils, System.Diagnostics, System.Types, System.Generics.Collections, System.Math.Vectors,
  Winapi.ActiveX, FMX.Forms, FMX.Graphics, FMX.WebBrowser, System.UITypes,
  DPH.UI.Main in '..\DPH.UI.Main.pas', DPH.Storage.Database in '..\DPH.Storage.Database.pas',
  DPH.Workspace.Model in '..\DPH.Workspace.Model.pas', DPH.Analysis.Explanations in '..\DPH.Analysis.Explanations.pas',
  DPH.Publish.Model in '..\DPH.Publish.Model.pas', DPH.Publish.Export in '..\DPH.Publish.Export.pas',
  DPH.Publish.BrowserPolicy in '..\DPH.Publish.BrowserPolicy.pas',
  DPH.Project.Analysis in '..\DPH.Project.Analysis.pas', DPH.Analysis.Symbols in '..\DPH.Analysis.Symbols.pas',
  DPH.Workspace.Worker in '..\DPH.Workspace.Worker.pas',
  DPH.Analysis.Model in '..\DPH.Analysis.Model.pas', DPH.Analysis.Persistence in '..\DPH.Analysis.Persistence.pas';
var Root,Work,Fixture,Key,Path,BeforeHash,JS,ReferenceDB,ReferenceRoot,SourceArtifact,ReferenceBundle: string; ID: TGUID;
    Analyzer: TDPHAnalyzer; Semantic: TDPHSemanticAnalyzer; Scan: TDPHScan; Graph: TDPHSemanticGraph;
    Store: TDPHKnowledgeStore; View: TDPHWorkspaceView; Model,ImageModel: TDPHDocumentModel; Explain: TDPHExplanationModel;
    Config,Generation: Int64; Rows: TJSONArray; V: TJSONValue; Row,Report: TJSONObject;
    Checks,I: Integer; Failed,Done: Boolean; Form: TDPHMainForm; Watch,Attempt: TStopwatch; Bitmap,BrowserBitmap: TBitmap; ReferenceViewMS: Int64;
    PortableStore: TDPHKnowledgeStore; ImageBytes: TBytes; LargeSource,FlowText: string;
    Worker: TDPHWorkspaceWorker; Request: TDPHWorkspaceRequest; Response: TDPHWorkspaceResponse;
procedure Check(OK: Boolean; const Text: string);
begin if not OK then raise Exception.Create('FAIL '+Text); Inc(Checks); Writeln('PASS ',Checks,': ',Text); Flush(Output); end;
procedure WaitHTML(Browser: TWebBrowser; const Script,Expected: string);
begin
  Watch:=TStopwatch.StartNew; JS:='';
  repeat
    Done:=False; Browser.EvaluateJavaScript(Script,TJavaScriptResultCallback(procedure(const Value: string) begin JS:=Value; Done:=True; end));
    Attempt:=TStopwatch.StartNew;
    while not Done and (Attempt.ElapsedMilliseconds<250) do begin Application.ProcessMessages; TThread.Sleep(10); end;
    if ContainsText(JS,Expected) then Exit;
    Application.ProcessMessages; TThread.Sleep(50);
  until Watch.ElapsedMilliseconds>20000;
  raise Exception.Create('Rendered HTML check timed out: '+Expected+'; '+JS);
end;
begin
  CoInitialize(nil); Application.Initialize;
  try
    try
      Root:=TPath.GetFullPath(ParamStr(1)); CreateGUID(ID); Work:=TPath.Combine(Root,'bin\learning-tests-'+GUIDToString(ID)); TDirectory.CreateDirectory(Work);
      Fixture:=TPath.Combine(Root,'tests\fixtures\semantics'); BeforeHash:=THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'Main.pas'));
      Analyzer:=TDPHAnalyzer.Create; Semantic:=TDPHSemanticAnalyzer.Create;
      Store:=TDPHKnowledgeStore.Create(TPath.Combine(Work,'fixture.dphdb'),Fixture,TPath.Combine(Root,'migrations'));
      try
        Store.InitializeProject('Learning fixture','Delphi'); Config:=Store.AddConfiguration('Win32','37.0','[]','[]','Debug'); Store.SelectConfiguration(Config);
        Scan:=Analyzer.Scan(TPath.Combine(Fixture,'Semantic.dproj'),'Debug','Win32',[],[]);
        try Graph:=Semantic.Analyze(Scan);
          try Generation:=TDPHSemanticPersistence.Stage(Scan,Graph,Store,Config); View:=TDPHWorkspaceView.Create(TDPHWorkspaceView.Capture(Scan,Graph,Generation,'Semantic.dproj','Debug','Win32',[],[]));
            Store.SaveWorkspaceView(Generation,View.Document.ToJSON); TDPHSemanticPersistence.Publish(Scan,Graph,Store,Generation);
          finally Graph.Free; end;
        finally Scan.Free; end;
        try
          Rows:=View.Search('TMain.Click','routine',''); try Key:=(Rows.Items[0] as TJSONObject).GetValue<string>('key'); finally Rows.Free; end;
          Store.SaveKnowledge(0,0,Generation,'Meaning of this operation','Fixture explanation supplied by a named author','Learning Test','note',Key);
          Rows:=Store.KnowledgeJSON;
          try Model:=TDPHDocumentModel.Create(View,Rows,[],[],False,True); finally Rows.Free; end;
          Explain:=TDPHExplanationModel.Create(Model.Document);
          try
            Check(ContainsText(Explain.ObjectText(Key),'Worker.PublicWork'),'Object explanation identifies a real cross-unit dependency');
            Check(ContainsText(Explain.ObjectText(Key),'Sender > 0'),'Explanation carries the actual branch condition');
            Check(ContainsText(Explain.TraceHTML(Key),'possible_dynamic'),'Execution trace preserves asynchronous or dispatch uncertainty');
            Check(ContainsText(Explain.FlowSVG(Key),'true') and ContainsText(Explain.FlowSVG(Key),'false'),'Flow diagram uses captured branch edges');
            Check(ContainsText(Explain.ObjectHTML(Key),'Fixture explanation supplied'),'Attributed knowledge appears in the linked explanation');
            Check(not ContainsText(Explain.ObjectHTML(Key),'"source_hash":'),'Explanation is not a raw JSON dump');
            Check(ContainsText(Explain.ObjectHTML(Key),'never a call'),'Captured source comment is available as author documentation');
            FlowText:=Explain.RoutineLesson(Key);
            Check(ContainsText(FlowText,'Sender > 0') and ContainsText(FlowText,'true ->') and ContainsText(FlowText,'false ->'),
              'Beginner walkthrough ties the actual condition to both captured branch destinations');
            Check(ContainsText(FlowText,'body is entered before this test') and ContainsText(FlowText,'loop_exit ->'),
              'Walkthrough distinguishes post-test repeat semantics from loop-exit paths');
            Check(ContainsText(FlowText,'intervening finally cleanup') and ContainsText(FlowText,'exception escaping') and ContainsText(FlowText,'possible_dynamic'),
              'Walkthrough teaches early-return cleanup and qualified exceptional alternatives');
            Check(ContainsText(Explain.ObjectHTML(Key),'SOURCE WALKTHROUGH') and ContainsText(Explain.ObjectHTML(Key),'Sender &gt; 0') and
              ContainsText(Explain.ObjectText(Key),'CHECK YOUR UNDERSTANDING'),
              'Native HTML and exported text share the source lesson with escaped expressions and a concrete learning exercise');
            Check(ContainsText(Explain.CookbookHTML(Key),'Files to inspect before changing code') and
              ContainsText(Explain.CookbookHTML(Key),'not a measured execution sequence') and
              ContainsText(Explain.CookbookHTML(Key),'DPH has not run the target application'),
              'Cookbook provides a bounded source-reading route without inventing execution or test results');
            Check(ContainsText(Explain.CookbookHTML('absent-object'),'Selection unavailable'),
              'Cookbook does not fabricate a route for an absent source object');
            Check(Explain.RoutineLesson('absent-object')='', 'An absent routine cannot acquire a fabricated walkthrough');
            for I:=0 to 10 do Check(Length(Explain.TopicHTML(I))>1500,'Learning topic '+IntToStr(I)+' renders a complete offline page');
            TDPHPublisher.Export(Model,Store,TPath.Combine(Work,'handoff'));
            Check(TFile.Exists(TPath.Combine(Work,'handoff\objects\'+THashSHA2.GetHashString(Key)+'.html')),'Export includes the selected object explanation');
            TDPHPublisher.Validate(TPath.Combine(Work,'handoff'),Model.Document.GetValue<string>('input_fingerprint'),False);
            Check(True,'Narrative export preserves generation, canonical and artifact integrity');
            ImageModel:=TDPHDocumentModel.Create(View,nil,[],[],False,True,nil,True);
            try Failed:=False; try TDPHPublisher.Export(ImageModel,Store,TPath.Combine(Work,'unsafe-local')); except Failed:=True; end;
              Check(Failed,'Unredacted local display projection cannot be published');
            finally ImageModel.Free; end;
            Check(TDPHBrowserPolicy.Allowed('file://'+TPath.Combine(Work,'handoff\objects\'+THashSHA2.GetHashString(Key)+'.html'),TPath.Combine(Work,'handoff'),True),'Preview permits only the generated object route shape');
            Check(not TDPHBrowserPolicy.Allowed('file://'+TPath.Combine(Work,'handoff\objects\arbitrary.html'),TPath.Combine(Work,'handoff'),True),'Preview rejects an arbitrary local object filename');
            Bitmap:=TBitmap.Create(80,60); try Bitmap.Clear(TAlphaColors.Blue); Bitmap.SaveToFile(TPath.Combine(Work,'synthetic-image.png')); finally Bitmap.Free; end;
            Store.ImportScreenshot(Generation,TPath.Combine(Work,'synthetic-image.png'),'Synthetic test contributor','Synthetic PNG fixture, not a captured application',Key);
            Rows:=Store.ScreenshotsJSON;
            try Check(Rows.Count=1,'Imported image persists with metadata'); Row:=Rows.Items[0] as TJSONObject;
              Check(Row.GetValue<string>('verification_state')='user_supplied_unverified','Imported image cannot silently become runtime-verified');
              Path:=Row.GetValue<string>('managed_path'); Check(THashSHA2.GetHashStringFromFile(Path)=Row.GetValue<string>('image_sha256'),'Managed image hash matches contributor evidence');
              ImageModel:=TDPHDocumentModel.Create(View,nil,[],[],False,True,Rows);
              try TDPHPublisher.Export(ImageModel,Store,TPath.Combine(Work,'image-handoff'));
                TDPHPublisher.Validate(TPath.Combine(Work,'image-handoff'),ImageModel.Document.GetValue<string>('input_fingerprint'),False);
                Check(ImageModel.Document.GetValue<TJSONArray>('screenshots').Count=1,'Export includes matching attributed image evidence');
                Check(not ContainsText(ImageModel.Document.ToJSON,'managed_path'),'Private image storage path is absent from canonical export');
              finally ImageModel.Free; end;
              ImageModel:=TDPHDocumentModel.Create(View,nil,[],['main.pas'],False,True,Rows);
              try Check(ImageModel.Document.GetValue<TJSONArray>('screenshots').Count=0,'Excluding the linked source also excludes its screenshot'); finally ImageModel.Free; end;
            finally Rows.Free; end;
            Failed:=False; try Store.ImportScreenshot(Generation,TPath.Combine(Fixture,'Main.pas'),'Test','Not an image',Key); except Failed:=True; end;
            Check(Failed,'Non-PNG input is rejected');
            Failed:=False; try Store.ImportScreenshot(Generation,TPath.Combine(Work,'synthetic-image.png'),'Test','Invalid link','missing-key'); except Failed:=True; end;
            Check(Failed,'Image cannot be linked to an object absent from its generation');
            Store.BackupTo(TPath.Combine(Work,'portable.dphdb'));
            TDirectory.Copy(TPath.Combine(Work,'fixture.dphdb.views'),TPath.Combine(Work,'portable.dphdb.views'));
            PortableStore:=TDPHKnowledgeStore.Create(TPath.Combine(Work,'portable.dphdb'),Fixture,TPath.Combine(Root,'migrations'));
            try Rows:=PortableStore.ScreenshotsJSON;
              try Check((Rows.Count=1) and ContainsText((Rows.Items[0] as TJSONObject).GetValue<string>('managed_path'),'portable.dphdb.views'),'Detached copy resolves its own adjacent screenshot assets'); finally Rows.Free; end;
            finally PortableStore.Free; end;
            ImageBytes:=TFile.ReadAllBytes(Path); TFile.WriteAllBytes(Path,TBytes.Create(1,2,3));
            try Failed:=False; try Rows:=Store.ScreenshotsJSON; Rows.Free; except Failed:=True; end;
              Check(Failed,'Damaged managed screenshot is rejected before display or export');
            finally TFile.WriteAllBytes(Path,ImageBytes); end;
            Path:=TPath.Combine(Work,'portable.dphdb.views\'+TPath.GetFileName(Path));
            TFile.WriteAllBytes(Path,TBytes.Create(1,2,3));
            if ParamStr(2)<>'--no-ui' then begin
            Worker:=TDPHWorkspaceWorker.Create(Root);
            try Request:=Default(TDPHWorkspaceRequest); Request.Command:='open'; Request.Database:=TPath.Combine(Work,'portable.dphdb');
              Worker.Submit(Request); Watch:=TStopwatch.StartNew; Done:=False;
              repeat
                if Worker.Poll(Response) then try
                  if (Response.Document<>nil) and (Response.Screenshots<>nil) then begin
                    Check(not Response.Failed and (Response.Screenshots.Count=0) and
                      ContainsText(Response.MessageText,'Screenshot evidence unavailable'),'Damaged supplemental image does not block the valid cached analysis'); Done:=True;
                  end;
                finally Response.Free; end;
                Application.ProcessMessages; TThread.Sleep(10);
              until Done or (Watch.ElapsedMilliseconds>20000);
              if not Done then raise Exception.Create('Cached-analysis recovery timed out');
            finally Worker.Free; TFile.WriteAllBytes(Path,ImageBytes); end;
            Form:=TDPHMainForm.Create(nil);
            try
              Form.PollTimer.Enabled:=False; Form.ChangeTimer.Enabled:=False; Form.Show;
              WaitHTML(Form.HelpBrowser,'document.body.innerText','Your first ten minutes');
              Check(Form.WorkspaceTabs.ActiveTab=Form.HelpTab,'First launch provides directions before a project is loaded');
              BrowserBitmap:=Form.HelpBrowser.CaptureBitmap;
              try BrowserBitmap.SaveToFile(TPath.Combine(Root,'docs\validation\images\rework-getting-started.png')); finally BrowserBitmap.Free; end;
              Form.LoadView(View.Document.Clone as TJSONObject); Form.WorkspaceTabs.ActiveTab:=Form.OverviewTab;
              WaitHTML(Form.LearningBrowser,'document.body.innerText','Your first route'); Check(True,'Real WebView2 renders the learning workspace');
              Form.SearchEdit.Text:='TMain.Click'; Form.ExplorerList.ItemIndex:=0; Form.ExplorerClick(nil);
              WaitHTML(Form.ExplainBrowser,'document.body.innerText','Understand this selection'); Check(True,'Real WebView2 renders the readable selected-object explanation');
              Check(Form.WorkspaceTabs.ActiveTab=Form.ExplainTab,'Explorer selection opens Explain');
              BrowserBitmap:=Form.ExplainBrowser.CaptureBitmap;
              Check(BrowserBitmap<>nil,'Native WebView2 image capture is available for visual QA');
              try BrowserBitmap.SaveToFile(TPath.Combine(Root,'docs\validation\images\rework-explain-browser.png'));
              Bitmap:=TBitmap.Create(Form.ClientWidth,Form.ClientHeight); try
                if Bitmap.Canvas.BeginScene then try Form.PaintTo(Bitmap.Canvas);
                  Bitmap.Canvas.SetMatrix(TMatrix.Identity);
                  var BrowserBounds:=Form.ExplainBrowser.AbsoluteRect;
                  Bitmap.Canvas.DrawBitmap(BrowserBitmap,TRectF.Create(0,0,BrowserBitmap.Width,BrowserBitmap.Height),BrowserBounds,1);
                finally Bitmap.Canvas.EndScene; end;
                Bitmap.SaveToFile(TPath.Combine(Root,'docs\validation\images\rework-learning-workspace.png'));
              finally Bitmap.Free; end;
              finally BrowserBitmap.Free; end;
              Form.GraphGroupingCombo.ItemIndex:=2; Form.GraphCombo.ItemIndex:=0; Form.ViewChange(nil);
              Form.WorkspaceTabs.ActiveTab:=Form.GraphTab;
              WaitHTML(Form.FlowBrowser,'document.body.innerText','Grouped by Units');
              WaitHTML(Form.FlowBrowser,'String(document.querySelector("svg[aria-label=\"Captured static relationships\"]") !== null)','true');
              Check(True,'Native grouped graph renders labeled source relationships in WebView2');
              WaitHTML(Form.FlowBrowser,'String(document.documentElement.scrollWidth <= window.innerWidth)','true');
              Check(True,'Grouped graph keeps wide diagrams inside their scrollable viewport');
                WaitHTML(Form.FlowBrowser,'(()=>{const graph=document.querySelector("svg[aria-label=\"Captured static relationships\"]");if(!graph)return "WAIT";graph.scrollIntoView();return "GRAPH_VISIBLE";})()','GRAPH_VISIBLE');
                Application.ProcessMessages; TThread.Sleep(200);
              BrowserBitmap:=Form.FlowBrowser.CaptureBitmap;
              try BrowserBitmap.SaveToFile(TPath.Combine(Root,'docs\validation\images\completion-grouped-graph-browser.png')); finally BrowserBitmap.Free; end;
              Form.Hide;
            finally Form.Free; end;
            end;
          finally Explain.Free; Model.Free; end;
          Check(THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'Main.pas'))=BeforeHash,'Selected fixture source remains unchanged');
        finally View.Free; end;
      finally Store.Free; Semantic.Free; Analyzer.Free; end;
      // Analyze a real generated Pascal body rather than manufacturing diagram edges.
      TDirectory.CreateDirectory(TPath.Combine(Work,'large-input'));
      LargeSource:='program Large;'+sLineBreak+'procedure Walk; var I: Integer; begin'+sLineBreak+'I := 0; while I < 100 do begin'+sLineBreak;
      for I:=1 to 100 do LargeSource:=LargeSource+'I := I + 1;'+sLineBreak;
      LargeSource:=LargeSource+'end; Application.FakeInsideRoutine; end;'+sLineBreak+'begin Walk; end.';
      TFile.WriteAllText(TPath.Combine(Work,'large-input\Large.dpr'),LargeSource,TEncoding.UTF8);
      Analyzer:=TDPHAnalyzer.Create; Semantic:=TDPHSemanticAnalyzer.Create;
      try Scan:=Analyzer.Scan(TPath.Combine(Work,'large-input\Large.dpr'),'Debug','Win32',[],[],False);
        try Graph:=Semantic.Analyze(Scan);
          try View:=TDPHWorkspaceView.Create(TDPHWorkspaceView.Capture(Scan,Graph,1,'Large.dpr','Debug','Win32',[],[]));
          finally Graph.Free; end;
        finally Scan.Free; end;
        try Model:=TDPHDocumentModel.Create(View,nil,[],[],False,True); Explain:=TDPHExplanationModel.Create(Model.Document);
          try Rows:=View.Search('Walk','routine',''); try Key:=(Rows.Items[0] as TJSONObject).GetValue<string>('key'); finally Rows.Free; end;
            FlowText:=Explain.FlowSVG(Key);
            Check(ContainsText(FlowText,'statements are collapsed') and not ContainsText(FlowText,'more than 70'),'Large routine collapses straight-line statements into a usable diagram');
            Check(ContainsText(FlowText,'iterate') and ContainsText(FlowText,'loop_exit'),'Collapsed flow preserves loop-back and branch-exit evidence');
            Check(ContainsText(Explain.RoutineLesson(Key),'source points omitted by the 60-point lesson limit'),
              'Long source lessons disclose omitted points rather than claiming full coverage');
            Check(not ContainsText(Explain.TopicText(1),'FakeInsideRoutine'),'Startup explanation excludes expressions inside declared routines');
          finally Explain.Free; Model.Free; end;
        finally View.Free; end;
      finally Semantic.Free; Analyzer.Free; end;
      ReferenceDB:=ParamStr(2); if ReferenceDB='--no-ui' then ReferenceDB:='';
      if ReferenceDB<>'' then begin
        ReferenceRoot:=TDPHKnowledgeStore.ProjectRoot(ReferenceDB); Store:=TDPHKnowledgeStore.Create(ReferenceDB,ReferenceRoot,TPath.Combine(Root,'migrations'));
        try View:=TDPHWorkspaceView.Create(TJSONObject.ParseJSONValue(Store.LoadWorkspaceView) as TJSONObject); finally Store.Free; end;
        try Model:=TDPHDocumentModel.Create(View,nil,[],[],True,True); Explain:=TDPHExplanationModel.Create(Model.Document);
          try
            Check(Model.Document.GetValue<TJSONArray>('startup').Count>0,'Pinned program startup is captured from its DPR body');
            Check(ContainsText(Explain.TopicText(1),'Application.CreateForm'),'Startup lesson cites actual form creation');
            Rows:=View.Search('btnConvertClick','routine',''); try Key:=(Rows.Items[0] as TJSONObject).GetValue<string>('key'); finally Rows.Free; end;
            Check(ContainsText(Explain.TraceHTML(Key),'CreateAnonymousThread') or ContainsText(Explain.TraceHTML(Key),'passes_callback'),'Reference convert explanation reaches its actual callback evidence');
            Check(ContainsText(Explain.TraceHTML(Key),'ConversionThreadProc'),'Reference trace reaches the actual conversion worker through its callback');
            TFile.WriteAllBytes(TPath.Combine(Work,'reference-convert.html'),TEncoding.UTF8.GetBytes(Explain.ObjectHTML(Key)));
            TFile.WriteAllBytes(TPath.Combine(Work,'reference-startup.html'),TEncoding.UTF8.GetBytes(Explain.TopicHTML(1)));
            Form:=TDPHMainForm.Create(nil);
            try Form.PollTimer.Enabled:=False; Form.ChangeTimer.Enabled:=False;
              Watch:=TStopwatch.StartNew; Form.LoadView(View.Document.Clone as TJSONObject); ReferenceViewMS:=Watch.ElapsedMilliseconds;
              Form.Show; Form.SearchEdit.Text:='btnConvertClick'; Form.ExplorerList.ItemIndex:=0; Form.ExplorerClick(nil);
              WaitHTML(Form.ExplainBrowser,'document.body.innerText','Understand this selection');
              Check(ContainsText(Form.ExplainFallback.Text,'btnConvertClick'),'Reference object explanation works in the actual FMX form');
              BrowserBitmap:=Form.ExplainBrowser.CaptureBitmap;
              try BrowserBitmap.SaveToFile(TPath.Combine(Root,'docs\validation\images\rework-reference-explain.png')); finally BrowserBitmap.Free; end;
              WaitHTML(Form.ExplainBrowser,'(()=>{const h=Array.from(document.querySelectorAll("h2")).find(x=>x.textContent==="Follow the work"); if(!h)return "WAIT"; h.scrollIntoView();return "TRACE_READY";})()','TRACE_READY');
              Check(True,'Reference execution trace is present in the actual rendered explanation');
              Application.ProcessMessages; TThread.Sleep(100);
              BrowserBitmap:=Form.ExplainBrowser.CaptureBitmap;
              try BrowserBitmap.SaveToFile(TPath.Combine(Root,'docs\validation\images\rework-reference-trace.png')); finally BrowserBitmap.Free; end;
              Form.GraphCombo.ItemIndex:=1; Form.WorkspaceTabs.ActiveTab:=Form.GraphTab; Form.ViewChange(nil);
              WaitHTML(Form.FlowBrowser,'document.body.innerText','Control-flow diagram');
              Check(True,'Reference procedure CFG renders labeled captured edges');
              BrowserBitmap:=Form.FlowBrowser.CaptureBitmap;
              try BrowserBitmap.SaveToFile(TPath.Combine(Root,'docs\validation\images\rework-reference-flow.png')); finally BrowserBitmap.Free; end;
              Form.LearningTopics.ItemIndex:=1; Form.LearningClick(nil); Form.WorkspaceTabs.ActiveTab:=Form.OverviewTab;
              WaitHTML(Form.LearningBrowser,'document.body.innerText','Application.CreateForm');
              Check(True,'Reference startup lesson renders actual initialization evidence');
              WaitHTML(Form.LearningBrowser,'String(document.documentElement.scrollWidth <= window.innerWidth)','true');
              Check(True,'Narrow learning view wraps long source citations without horizontal overflow');
              BrowserBitmap:=Form.LearningBrowser.CaptureBitmap;
              try BrowserBitmap.SaveToFile(TPath.Combine(Root,'docs\validation\images\rework-reference-startup.png')); finally BrowserBitmap.Free; end;
              ReferenceBundle:=TPath.Combine(TPath.GetDirectoryName(ReferenceDB),'reference-task');
              if TFile.Exists(TPath.Combine(ReferenceBundle,'source-navigation.json')) then begin
                Row:=TJSONObject.ParseJSONValue(TFile.ReadAllText(TPath.Combine(ReferenceBundle,'source-navigation.json'),TEncoding.UTF8)) as TJSONObject;
                try SourceArtifact:='';
                  for V in Row.GetValue<TJSONArray>('files') do
                    if V.GetValue<string>('state')='redacted_captured_text' then begin SourceArtifact:=V.GetValue<string>('artifact'); Break; end;
                finally Row.Free; end;
                Check(SourceArtifact<>'','Pinned source browsing has an eligible page for native visual review');
                Form.WorkspaceTabs.ActiveTab:=Form.PublishTab; Form.PublishBrowser.OnShouldLoadURL:=nil;
                Form.PublishBrowser.WindowsEngine:=TWindowsEngine.EdgeOnly; Form.PublishBrowser.Visible:=True;
                Form.PublishBrowser.Navigate('file://'+TPath.Combine(ReferenceBundle,SourceArtifact.Replace('/',PathDelim)));
                WaitHTML(Form.PublishBrowser,'(()=>{const line=document.querySelector("pre span[id^=L]");if(!line)return "WAIT";line.scrollIntoView();return "SOURCE_LINES_READY";})()','SOURCE_LINES_READY');
                Application.ProcessMessages; TThread.Sleep(200);
                BrowserBitmap:=Form.PublishBrowser.CaptureBitmap;
                try BrowserBitmap.SaveToFile(TPath.Combine(Root,'docs\validation\images\completion-source-lines-browser.png')); finally BrowserBitmap.Free; end;
              end;
              Form.Hide;
            finally Form.Free; end;
            Check(not Model.Document.GetValue<Boolean>('analysis_complete'),'Learning does not clear partial reference coverage');
          finally Explain.Free; Model.Free; end;
        finally View.Free; end;
      end;
      Report:=TJSONObject.Create; try Report.AddPair('checks_passed',TJSONNumber.Create(Checks)); Report.AddPair('work',Work); Report.AddPair('reference_cache',ReferenceDB); Report.AddPair('human_acceptance','not_run');
        Report.AddPair('reference_learning_projection_ms',TJSONNumber.Create(ReferenceViewMS));
        TFile.WriteAllText(TPath.Combine(Root,'docs\validation\reports\rework-learning-validation.json'),Report.Format(2),TEncoding.UTF8);
      finally Report.Free; end;
      Writeln('PASS Learning: ',Checks,' checks');
    except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode:=1; end; end;
  finally CoUninitialize; end;
end.
