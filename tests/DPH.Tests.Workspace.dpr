program DPH.Tests.Workspace;
{$APPTYPE CONSOLE}
uses System.SysUtils, System.Classes, System.IOUtils, System.JSON, System.Diagnostics,
  System.Hash, System.Types, FMX.Forms, FMX.Graphics, Winapi.ActiveX,
  DPH.UI.Main in '..\DPH.UI.Main.pas',
  DPH.Workspace.Model in '..\DPH.Workspace.Model.pas',
  DPH.Workspace.Worker in '..\DPH.Workspace.Worker.pas',
  DPH.Workspace.Screen in '..\DPH.Workspace.Screen.pas',
  DPH.Storage.Database in '..\DPH.Storage.Database.pas',
  DPH.Project.Analysis in '..\DPH.Project.Analysis.pas',
  DPH.Analysis.Model in '..\DPH.Analysis.Model.pas',
  DPH.Analysis.Symbols in '..\DPH.Analysis.Symbols.pas';
var Root,Work,Fixture,Path,Key,ComponentKey,Kind: string; ID: TGUID; Checks: Integer;
    Worker: TDPHWorkspaceWorker; Request: TDPHWorkspaceRequest; Response: TDPHWorkspaceResponse;
    View: TDPHWorkspaceView; Rows: TJSONArray; J,Screen: TJSONObject; V: TJSONValue;
    Form: TDPHMainForm; Bitmap: TBitmap; Watch: TStopwatch; Generation: Int64;
    Before,After: string; Failed: Boolean;
procedure Check(OK: Boolean; const MessageText: string);
begin if not OK then raise Exception.Create('FAIL '+MessageText); Inc(Checks); Writeln('PASS ',Checks,': ',MessageText); end;
function WaitResponse: TDPHWorkspaceResponse;
var Start: TStopwatch;
begin
  Start:=TStopwatch.StartNew;
  repeat
    Application.ProcessMessages;
    if Worker.Poll(Result) then begin if not Result.Busy then Exit; Result.Free; end;
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
          Rows:=View.Neighbors(Key,'reverse'); try Check(Rows.Count>0,'Reverse references retain event evidence'); finally Rows.Free; end;
          for Kind in ['Execution','Procedure CFG','Caller / callee','Form navigation','Data flow','Change impact'] do begin
            J:=View.Graph(Kind,Key,5); try Check(J.GetValue<TJSONArray>('nodes').Count<=5,Kind+' graph is bounded'); Check(not J.GetValue<Boolean>('runtime_trace'),Kind+' graph has static provenance'); finally J.Free; end;
          end;
          Screen:=TDPHScreenLayout.Reconstruct(View,'Main.fmx');
          try Check(Screen.GetValue<TJSONArray>('components').Count=2,'Design-time screen contains form and button');
            Check(Pos('not a runtime',Screen.GetValue<string>('provenance'))>0,'Screen reconstruction never claims runtime capture'); finally Screen.Free; end;
          Form:=TDPHMainForm.Create(nil);
          try
            Form.LoadView(View.Document.Clone as TJSONObject); Check(Form.ExplorerList.Items.Count>0,'FMX Explorer displays canonical cached objects');
            Form.SearchEdit.Text:='Click'; Form.ExplorerList.ItemIndex:=0; Form.ExplorerClick(nil);
            Check(Pos('Main.TMain.Click',Form.InspectorMemo.Text)>0,'Explorer selection populates source-backed inspector');
            Check(Pos('detached',Form.SourceMemo.Text)>0,'Detached source view does not follow cached filesystem paths');
            Form.BookmarkClick(nil); Form.BookmarksClick(nil); Check(Form.ExplorerList.Items.Count=1,'Canonical selection can be bookmarked');
            for Kind in ['Execution','Procedure CFG','Caller / callee','Form navigation','Data flow','Change impact'] do begin Form.GraphCombo.ItemIndex:=Form.GraphCombo.Items.IndexOf(Kind); Form.ViewChange(nil); end;
            Form.WorkspaceTabs.ActiveTab:=Form.OverviewTab; Form.Show; Application.ProcessMessages;
            Bitmap:=TBitmap.Create(Form.ClientWidth,Form.ClientHeight); try
              if Bitmap.Canvas.BeginScene then try Form.PaintTo(Bitmap.Canvas); finally Bitmap.Canvas.EndScene; end;
              if ParamStr(2)<>'no-report' then Bitmap.SaveToFile(TPath.Combine(Root,'docs\wp4-workspace.png')); finally Bitmap.Free; end;
            Form.WorkspaceTabs.ActiveTab:=Form.ScreenTab;
            for Kind in ['Thumbnail','Fit','Native','Zoom 200%','Full screen'] do begin
              Form.ScreenModeCombo.ItemIndex:=Form.ScreenModeCombo.Items.IndexOf(Kind); Form.ViewChange(nil); Application.ProcessMessages;
              Bitmap:=Form.ScreenPaint.MakeScreenshot; try Check((Bitmap.Width>0) and (Bitmap.Height>0),'Render screen mode '+Kind); finally Bitmap.Free; end;
            end;
            Form.Hide;
          finally Form.Free; end;
          Request.Command:='open'; Worker.Submit(Request); Watch:=TStopwatch.StartNew; Response:=WaitResponse;
          try Check(not Response.Failed and (Response.Document<>nil),'Cached database opens without analysis'); Check(Response.Detached,'Cached open requires explicit source attachment');
            Check(Response.Document.GetValue<Int64>('generation_id')=Generation,'Cached open preserves generation'); Check(Watch.ElapsedMilliseconds<5000,'Fixture cached open completes within 5 seconds'); finally Response.Free; end;
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
