program DPH.Tests.Workspace;
{$APPTYPE CONSOLE}
uses System.SysUtils, System.Classes, System.IOUtils, System.JSON, System.Diagnostics, System.UITypes,
  System.Hash, System.Types, FMX.Forms, FMX.Graphics, Winapi.ActiveX,
  DPH.UI.Main in '..\DPH.UI.Main.pas',
  DPH.Workspace.Model in '..\DPH.Workspace.Model.pas',
  DPH.Workspace.Worker in '..\DPH.Workspace.Worker.pas',
  DPH.Workspace.Screen in '..\DPH.Workspace.Screen.pas',
  DPH.Workspace.Graphs in '..\DPH.Workspace.Graphs.pas',
  DPH.Publish.Model in '..\DPH.Publish.Model.pas',
  DPH.Analysis.Explanations in '..\DPH.Analysis.Explanations.pas',
  DPH.Storage.Database in '..\DPH.Storage.Database.pas',
  DPH.Project.Analysis in '..\DPH.Project.Analysis.pas',
  DPH.Analysis.Model in '..\DPH.Analysis.Model.pas',
  DPH.Analysis.Symbols in '..\DPH.Analysis.Symbols.pas';
var Root,Work,Fixture,Path,Key,ComponentKey,Kind: string; ID: TGUID; Checks: Integer;
    Worker: TDPHWorkspaceWorker; Request: TDPHWorkspaceRequest; Response: TDPHWorkspaceResponse;
    View: TDPHWorkspaceView; Rows: TJSONArray; J,Screen,BaseGraph,GroupedGraph,Row: TJSONObject; V: TJSONValue;
    Form: TDPHMainForm; Bitmap: TBitmap; Watch: TStopwatch; Generation: Int64; EscapeKey: Word; EscapeChar: Char; SavedScreenWidth: Single;
    Facts: TDPHDocumentModel; Explanation: TDPHExplanationModel; HTML: string;
    Before,After,RootKey: string; Failed,CachedShownBeforeVerification,FoundChild: Boolean; RootCount,ExpandedCount,Members,Relationships: Integer;
procedure Check(OK: Boolean; const MessageText: string);
begin if not OK then raise Exception.Create('FAIL '+MessageText); Inc(Checks); Writeln('PASS ',Checks,': ',MessageText); end;
function WaitResponse: TDPHWorkspaceResponse;
var Start: TStopwatch;
begin
  Start:=TStopwatch.StartNew;
  repeat
    Application.ProcessMessages;
    if Worker.Poll(Result) then begin
      if Result.Busy and (Result.Document<>nil) then CachedShownBeforeVerification:=True;
      if not Result.Busy then Exit; Result.Free;
    end;
    if Start.ElapsedMilliseconds>60000 then raise Exception.Create('Worker timed out');
    TThread.Sleep(10);
  until False;
end;
begin
  CoInitialize(nil); Application.Initialize;
  try
    try
      Root:=TPath.GetFullPath(ParamStr(1)); CreateGUID(ID); Work:=TPath.Combine(Root,'bin\wp4-tests-'+GUIDToString(ID));
      Fixture:=TPath.Combine(Work,'fixture'); TDirectory.CreateDirectory(Fixture);
      for Path in TDirectory.GetFiles(TPath.Combine(Root,'tests\fixtures\semantics')) do TFile.Copy(Path,TPath.Combine(Fixture,ExtractFileName(Path)));
      Before:=THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'Main.pas'));
      Worker:=TDPHWorkspaceWorker.Create(Root);
      try
        Request.Command:='incremental'; Request.Entry:=TPath.Combine(Fixture,'Semantic.dproj'); Request.Database:=TPath.Combine(Work,'workspace.dphdb');
        Request.Configuration:='Debug'; Request.Platform:='Win32'; Request.Defines:=[]; Request.ExternalRoots:=[];
        Worker.Submit(Request); Response:=WaitResponse;
        try
          Check(not Response.Failed,Response.MessageText); Check(Response.Document<>nil,'Background scan returns a captured workspace');
          View:=TDPHWorkspaceView.Create(Response.Document); Response.Document:=nil;
        finally Response.Free; end;
        try
          Generation:=View.Document.GetValue<Int64>('generation_id');
          Check(Generation>0,'Workspace includes its immutable generation');
          Rows:=View.Search('Click','routine',''); try Check(Rows.Count=1,'Project-wide search selects method identity'); Key:=(Rows.Items[0] as TJSONObject).GetValue<string>('key'); finally Rows.Free; end;
          Rows:=View.Search('btnConvert','component',''); try Check(Rows.Count=1,'Form component is searchable'); ComponentKey:=(Rows.Items[0] as TJSONObject).GetValue<string>('key'); finally Rows.Free; end;
          Rows:=View.Properties(ComponentKey); try Check(Rows.Count>0,'Inspector retains serialized properties'); finally Rows.Free; end;
          Rows:=View.Details(ComponentKey); try Check((Rows.Count>0) and (Rows.Items[0].GetValue<string>('detail_kind')='property') and
            (Rows.Items[0].GetValue<string>('rule')='serialized_override_not_framework_default'),'Component details distinguish serialized values from unknown defaults'); finally Rows.Free; end;
          Rows:=View.Details(Key); try Check((Rows.Count>0) and (Rows.Items[0].GetValue<string>('detail_kind')='statement') and
            (Rows.Items[0].GetValue<string>('source_hash')<>''),'Routine details retain statement text and immutable source evidence'); finally Rows.Free; end;
          Rows:=View.Neighbors(Key,'reverse'); try Check(Rows.Count>0,'Reverse references retain event evidence'); finally Rows.Free; end;
          Rows:=View.Search('Main','unit',''); try RootKey:=(Rows.Items[0] as TJSONObject).GetValue<string>('key'); finally Rows.Free; end;
          Rows:=View.Hierarchy([]); try
            RootCount:=Rows.Count; FoundChild:=False;
            for V in Rows do if (V as TJSONObject).GetValue<Integer>('depth')<>0 then FoundChild:=True;
            Check((RootCount>0) and not FoundChild,'Collapsed hierarchy shows only ownership roots');
          finally Rows.Free; end;
          Rows:=View.Hierarchy([RootKey]); try
            ExpandedCount:=Rows.Count; FoundChild:=False;
            for V in Rows do if (V as TJSONObject).GetValue<Integer>('depth')=1 then FoundChild:=True;
            Check((ExpandedCount>RootCount) and FoundChild,'Expanding a module reveals its immediate owned objects');
          finally Rows.Free; end;
          Rows:=View.Hierarchy([]); try Check(Rows.Count=RootCount,'Collapsing a branch restores root rows without changing the source model'); finally Rows.Free; end;
          Rows:=View.Hierarchy([RootKey],1,2); try Check(Rows.Count=2,'Hierarchy pagination is applied after branch visibility'); finally Rows.Free; end;
          BaseGraph:=View.Graph('Execution',Key,1000);
          try for Kind in ['Types','Units'] do begin
            GroupedGraph:=TDPHGraphProjection.Group(View,BaseGraph,Kind);
            try
              Members:=0; Relationships:=0;
              for V in GroupedGraph.GetValue<TJSONArray>('nodes') do begin Inc(Members,V.GetValue<Integer>('member_count')); Inc(Relationships,V.GetValue<Integer>('internal_relationships')); end;
              for V in GroupedGraph.GetValue<TJSONArray>('edges') do Inc(Relationships,V.GetValue<Integer>('relationship_count'));
              Check((Members=BaseGraph.GetValue<TJSONArray>('nodes').Count) and (GroupedGraph.GetValue<TJSONArray>('nodes').Count<Members),Kind+' grouping retains every captured member while collapsing nodes');
              Check(Relationships=BaseGraph.GetValue<TJSONArray>('edges').Count,Kind+' grouping retains internal and external relationship counts');
              Facts:=TDPHDocumentModel.Create(View,nil,[],[],True,not View.Document.GetValue<Boolean>('analysis_complete'),nil,True);
              try Explanation:=TDPHExplanationModel.Create(Facts.Document);
                try
                  HTML:=Explanation.GraphHTML(GroupedGraph);
                  Check(HTML.Contains('<svg') and HTML.Contains('#g_') and HTML.Contains('marker-end'),'Grouped graph HTML renders directed labeled nodes with member navigation');
                  TFile.WriteAllText(TPath.Combine(Work,'grouped-graph.html'),HTML,TEncoding.UTF8);
                  Row:=(GroupedGraph.GetValue<TJSONArray>('nodes').Items[0] as TJSONObject);
                  Row.RemovePair('label').Free; Row.AddPair('label','<script>alert(1)</script>');
                  HTML:=Explanation.GraphHTML(GroupedGraph);
                  Check(HTML.Contains('&lt;script&gt;') and not HTML.Contains('<script>'),'Graph labels escape analyzed source text as inert content');
                finally Explanation.Free; end;
              finally Facts.Free; end;
            finally GroupedGraph.Free; end;
          end; finally BaseGraph.Free; end;
          BaseGraph:=View.Graph('Execution',Key,1);
          try GroupedGraph:=TDPHGraphProjection.Group(View,BaseGraph,'Units');
            try Check(GroupedGraph.GetValue<Boolean>('truncated'),'Grouped graph preserves source-projection truncation'); finally GroupedGraph.Free; end;
          finally BaseGraph.Free; end;
          for Kind in ['Execution','Procedure CFG','Caller / callee','Form navigation','Data flow','Change impact'] do begin
            J:=View.Graph(Kind,Key,5); try Check(J.GetValue<TJSONArray>('nodes').Count<=5,Kind+' graph is bounded'); Check(not J.GetValue<Boolean>('runtime_trace'),Kind+' graph has static provenance'); finally J.Free; end;
          end;
          Screen:=TDPHScreenLayout.Reconstruct(View,'Main.fmx');
          try Check(Screen.GetValue<TJSONArray>('components').Count=2,'Design-time screen contains form and button');
            Check(Pos('not a runtime',Screen.GetValue<string>('provenance'))>0,'Screen reconstruction never claims runtime capture'); finally Screen.Free; end;
          Form:=TDPHMainForm.Create(nil);
          try
            Form.LoadView(View.Document.Clone as TJSONObject); Check(Form.ExplorerList.Items.Count>0,'FMX Explorer displays canonical cached objects');
            RootCount:=Form.ExplorerList.Items.Count; Form.ExplorerList.ItemIndex:=0; Form.ExplorerExpandClick(nil);
            Check(Form.ExplorerList.Items.Count>RootCount,'IDE-editable expand button opens the selected Explorer branch');
            Form.ExplorerExpandClick(nil); Check(Form.ExplorerList.Items.Count=RootCount,'Explorer branch collapse preserves other roots');
            Check((Form.ConfigurationCombo.Items.Count=View.Document.GetValue<TJSONArray>('configurations').Count) and
              (Form.PlatformCombo.Items.Count=View.Document.GetValue<TJSONArray>('platforms').Count),'FMX choices come from captured project options');
            Check(Form.CodePageEdit.Text='0','Captured code page is visible in the source settings');
            J:=View.Coverage;
            try
              Check((J.GetValue<TJSONArray>('metrics').Count=8) and
                (J.GetValue<TJSONArray>('metrics').Items[0].GetValue<Integer>('denominator')=View.Document.GetValue<TJSONArray>('syntax.files').Count),
                'Coverage metrics define inventory denominator explicitly');
              Check(J.GetValue<TJSONArray>('diagnostics').Count=View.Document.GetValue<TJSONArray>('syntax.diagnostics').Count+
                View.Document.GetValue<TJSONArray>('semantics.diagnostics').Count,'Coverage retains syntax and semantic diagnostic evidence');
            finally J.Free; end;
            Check(Form.CoverageMemo.Text.Contains('not proof') and Form.CoverageMemo.Text.Contains('denominator'),
              'Coverage page explains human-review limits separately from static measures');
            if Form.CoverageList.Count>0 then begin
              Form.CoverageList.ItemIndex:=0; Form.CoverageInspectClick(nil);
              Check((Form.WorkspaceTabs.ActiveTab=Form.DetailsTab) and Form.DetailsMemo.Text.StartsWith('diagnostic:'),
                'Coverage gap opens labeled source evidence in Details');
            end;
            Form.SearchEdit.Text:='Click'; Form.ExplorerList.ItemIndex:=0; Form.ExplorerClick(nil);
            Check(Pos('Main.TMain.Click',Form.InspectorMemo.Text)>0,'Explorer selection populates source-backed inspector');
            Check(Pos('detached',Form.SourceMemo.Text)>0,'Detached source view does not follow cached filesystem paths');
            Check(Form.DetailsList.Items.Count>0,'Selected routine populates IDE-editable statement/evidence rows');
            Form.DetailsList.ItemIndex:=0; Form.DetailsClick(nil);
            Check(Pos('SHA256:',Form.DetailsMemo.Text)>0,'Evidence pane labels certainty, rule and source hash');
            Form.WorkspaceTabs.ActiveTab:=Form.DetailsTab; Form.DetailsSourceClick(nil);
            Check((Form.WorkspaceTabs.ActiveTab=Form.DetailsTab) and (Pos('detached',Form.DetailsMemo.Text)>0),'Detached evidence command retains cached details without following filesystem paths');
            Form.GraphGroupingCombo.ItemIndex:=Form.GraphGroupingCombo.Items.IndexOf('Units'); Form.ViewChange(Form.GraphGroupingCombo);
            Form.GraphMouseDown(Form.GraphPaint,TMouseButton.mbLeft,[],20,20);
            Check((Form.WorkspaceTabs.ActiveTab=Form.DetailsTab) and (Form.DetailsList.Items.Count>0) and (Pos('Group:',Form.DetailsMemo.Text)>0),'Selecting a collapsed graph group opens its member/evidence list');
            Form.DetailsList.ItemIndex:=0; Form.DetailsObjectClick(nil);
            Check(Form.WorkspaceTabs.ActiveTab=Form.ExplainTab,'Group member opens its canonical object explanation');
            Form.GraphGroupingCombo.ItemIndex:=0; Form.SearchEdit.Text:='Click'; Form.ExplorerList.ItemIndex:=0; Form.ExplorerClick(nil);
            Form.WholeProgramGraphClick(nil);
            Check((Form.GraphCombo.ItemIndex=0) and (Form.WorkspaceTabs.ActiveTab=Form.GraphTab),'Whole program command opens startup execution projection');
            Check(Pos('Main.TMain.Click',Form.InspectorMemo.Text)>0,'Whole program projection preserves the inspected object context');
            Form.AllFormsGraphClick(nil);
            Check((Form.GraphCombo.ItemIndex=Form.GraphCombo.Items.IndexOf('Form navigation')) and (Form.WorkspaceTabs.ActiveTab=Form.GraphTab),'All forms command selects the whole form navigation projection');
            Check(Pos('Main.TMain.Click',Form.InspectorMemo.Text)>0,'All forms graph preserves the inspected object context');
            Form.AllDataGraphClick(nil);
            Check((Form.GraphCombo.ItemIndex=Form.GraphCombo.Items.IndexOf('Data flow')) and (Form.WorkspaceTabs.ActiveTab=Form.GraphTab),'Project data command opens the whole captured data projection');
            Check(Pos('Main.TMain.Click',Form.InspectorMemo.Text)>0,'Project data projection preserves the inspected object context');
            Form.BookmarkClick(nil); Form.BookmarksClick(nil); Check(Form.ExplorerList.Items.Count=1,'Canonical selection can be bookmarked');
            for Kind in ['Execution','Procedure CFG','Caller / callee','Form navigation','Data flow','Change impact'] do begin Form.GraphCombo.ItemIndex:=Form.GraphCombo.Items.IndexOf(Kind); Form.ViewChange(nil); end;
            Form.WorkspaceTabs.ActiveTab:=Form.OverviewTab; Form.Show; Application.ProcessMessages;
            Bitmap:=TBitmap.Create(Form.ClientWidth,Form.ClientHeight); try
              if Bitmap.Canvas.BeginScene then try Form.PaintTo(Bitmap.Canvas); finally Bitmap.Canvas.EndScene; end;
              if ParamStr(2)<>'no-report' then Bitmap.SaveToFile(TPath.Combine(Root,'docs\wp4-workspace.png')); finally Bitmap.Free; end;
            Form.WorkspaceTabs.ActiveTab:=Form.DetailsTab; Application.ProcessMessages;
            Bitmap:=TBitmap.Create(Form.ClientWidth,Form.ClientHeight);
            try
              if Bitmap.Canvas.BeginScene then try Form.PaintTo(Bitmap.Canvas); finally Bitmap.Canvas.EndScene; end;
              Bitmap.SaveToFile(TPath.Combine(Work,'details-native.png'));
            finally Bitmap.Free; end;
            Form.WorkspaceTabs.ActiveTab:=Form.ScreenTab;
            for Kind in ['Thumbnail','Fit','Native','Custom zoom','Full screen'] do begin
              Form.ScreenModeCombo.ItemIndex:=Form.ScreenModeCombo.Items.IndexOf(Kind); Form.ViewChange(nil); Application.ProcessMessages;
              Bitmap:=Form.ScreenPaint.MakeScreenshot; try Check((Bitmap.Width>0) and (Bitmap.Height>0),'Render screen mode '+Kind); finally Bitmap.Free; end;
            end;
            Check(not Form.HeaderLayout.Visible and not Form.ExplorerLayout.Visible and
              not Form.InspectorLayout.Visible and (Form.BorderStyle=TFmxFormBorderStyle.None),
              'Dedicated full screen hides surrounding workspace while retaining screen toolbar');
            EscapeKey:=vkEscape; EscapeChar:=#0; Form.FormKeyDown(nil,EscapeKey,EscapeChar,[]);
            Check(Form.HeaderLayout.Visible and Form.ExplorerLayout.Visible and Form.InspectorLayout.Visible and
              (EscapeKey=0),'Escape restores workspace from focused full screen');
            Form.ScreenModeCombo.ItemIndex:=2; Form.ViewChange(nil); SavedScreenWidth:=Form.ScreenPaint.Width;
            Form.ScreenZoom.Value:=300; Form.ViewChange(Form.ScreenZoom);
            Check((Form.ScreenModeCombo.ItemIndex=3) and (Abs(Form.ScreenPaint.Width-SavedScreenWidth*3)<1),
              'Custom zoom updates scrollable extent to three times native width');
            Form.ScreenModeCombo.ItemIndex:=1; Form.ViewChange(nil);
            Check((Form.ScreenPaint.Width<=Form.ScreenScroll.Width) and (Form.ScreenPaint.Height<=Form.ScreenScroll.Height),
              'Fit computes bounds from all captured components within screen viewport');
            Bitmap:=TBitmap.Create(320,160);
            try Bitmap.Clear(TAlphaColors.Blue); Bitmap.SaveToFile(TPath.Combine(Work,'runtime-evidence.png')); finally Bitmap.Free; end;
            with TDPHKnowledgeStore.Create(Request.Database,Fixture,TPath.Combine(Root,'migrations')) do
            try ImportScreenshot(Generation,TPath.Combine(Work,'runtime-evidence.png'),'Fixture contributor','Synthetic test image, not target runtime',ComponentKey);
              Form.LoadScreenshots(ScreenshotsJSON);
            finally Free; end;
            Check((Form.ScreenshotList.Count=1) and not Form.ScreenshotList.ListItems[0].ItemData.Bitmap.IsEmpty,
              'Imported screenshot gallery provides bounded image thumbnail');
            Form.ScreenshotList.ItemIndex:=0; Form.ScreenshotClick(nil);
            Form.ScreenshotModeCombo.ItemIndex:=1; Form.ScreenshotViewChange(nil);
            Check((Form.ScreenshotImage.Width=320) and (Form.ScreenshotImage.Height=160),
              'Native screenshot mode uses actual pixel dimensions');
            Form.ScreenshotZoom.Value:=200; Form.ScreenshotViewChange(Form.ScreenshotZoom);
            Check((Form.ScreenshotImage.Width=640) and (Form.ScreenshotImage.Height=320),
              'Screenshot zoom updates scrollable image bounds');
            Form.ScreenshotInspectClick(nil);
            Check((Form.WorkspaceTabs.ActiveTab=Form.ExplainTab) and Form.InspectorMemo.Text.StartsWith(View.Symbol(ComponentKey).GetValue<string>('name')),
              'Screenshot linked object opens canonical explanation');
            Form.BookmarkClick(nil); Form.WorkspaceTabs.ActiveTab:=Form.GraphTab;
            Form.LoadView(View.Document.Clone as TJSONObject);
            Check((Form.WorkspaceTabs.ActiveTab=Form.GraphTab) and
              Form.InspectorMemo.Text.StartsWith(View.Symbol(ComponentKey).GetValue<string>('name')),
              'Same-project reassessment preserves selected object and active page');
            Form.BookmarksClick(nil);
            Check(Form.ExplorerList.Items.Contains(View.Symbol(ComponentKey).GetValue<string>('name')),
              'Same-project reassessment retains surviving bookmarks');
            J:=View.Document.Clone as TJSONObject;
            Rows:=J.GetValue<TJSONArray>('semantics.symbols');
            for Members:=Rows.Count-1 downto 0 do if Rows.Items[Members].GetValue<string>('key')=ComponentKey then Rows.Remove(Members).Free;
            Form.LoadView(J);
            Check((Form.InspectorMemo.Text='') and Form.StatusLabel.Text.Contains('absent'),
              'Removed object clears stale inspector and reports selection loss without guessing a replacement');
            Form.BookmarksClick(nil);
            Check(not Form.ExplorerList.Items.Contains(View.Symbol(ComponentKey).GetValue<string>('name')),
              'Removed object is pruned from reassessment bookmarks');
            Form.Hide;
          finally Form.Free; end;
          CachedShownBeforeVerification:=False;
          Request.Command:='open'; Worker.Submit(Request); Watch:=TStopwatch.StartNew; Response:=WaitResponse;
          try Check(not Response.Failed and (Response.Document<>nil),'Cached database opens without analysis'); Check(not Response.Detached and (Response.SourceEntry<>''),'Cached open verifies available source automatically');
            Check(Response.Document.GetValue<Int64>('generation_id')=Generation,'Cached open preserves generation'); Check(Watch.ElapsedMilliseconds<5000,'Fixture cached open completes within 5 seconds'); finally Response.Free; end;
          Check(CachedShownBeforeVerification,'Cached document is delivered before background verification completes');
          TFile.Move(Request.Entry,Request.Entry+'.offline');
          try
            Worker.Submit(Request); Response:=WaitResponse;
            try Check(not Response.Failed and Response.Detached and (Response.Document<>nil),'Unavailable source opens safely detached'); finally Response.Free; end;
          finally TFile.Move(Request.Entry+'.offline',Request.Entry); end;
          Request.Command:='check'; Worker.Submit(Request); Response:=WaitResponse;
          try Check(not Response.Failed and not Response.Changed and (Response.Document=nil),'Unchanged connected check skips analysis'); finally Response.Free; end;
          Request.Defines:=['EXTRA']; Worker.Submit(Request); Response:=WaitResponse;
          try Check(not Response.Failed and (Response.Document<>nil),'Configuration change reassesses unchanged source bytes'); finally Response.Free; end;
          TFile.AppendAllText(TPath.Combine(Fixture,'Main.pas'),sLineBreak+'// controlled workspace test'+sLineBreak,TEncoding.UTF8);
          Worker.Submit(Request); Response:=WaitResponse;
          try Check(not Response.Failed and Response.Changed and (Response.Document<>nil),'Source modification triggers background reassessment'); finally Response.Free; end;
          After:=THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'Main.pas'));
          Check(Before<>After,'Controlled edit changes its input fingerprint');
          Request.Command:='open'; Worker.Submit(Request); Response:=WaitResponse; try Check(not Response.Failed,'Updated cached workspace can reopen'); finally Response.Free; end;
          Path:=TPath.Combine(Request.Database+'.views',THashSHA2.GetHashString(View.Document.ToJSON)+'.json'); TFile.AppendAllText(Path,'tamper',TEncoding.UTF8);
          // Explicitly select the damaged generation rather than whichever head is current.
          with TDPHKnowledgeStore.Create(Request.Database,Fixture,TPath.Combine(Root,'migrations')) do
          try Failed:=False; try LoadWorkspaceView(Generation); except Failed:=True; end; Check(Failed,'Artifact tampering is rejected'); finally Free; end;
        finally View.Free; end;
      finally Worker.Free; end;
      Check(True,'Idle worker shutdown returns without a queue loop');
      J:=TJSONObject.Create; try J.AddPair('checks_passed',TJSONNumber.Create(Checks)); J.AddPair('corpus','copied semantic fixture'); J.AddPair('work',Work);
        if ParamStr(2)<>'no-report' then TFile.WriteAllText(TPath.Combine(Root,'docs\wp4-validation.json'),J.Format,TEncoding.UTF8); finally J.Free; end;
      Writeln('PASS WP4: ',Checks,' checks');
    except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode:=1; end; end;
  finally CoUninitialize; end;
end.
