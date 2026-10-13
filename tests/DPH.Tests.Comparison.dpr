program DPH.Tests.Comparison;
{$APPTYPE CONSOLE}
uses System.SysUtils, System.Classes, System.IOUtils, System.JSON, System.StrUtils, System.Diagnostics,
  FMX.Forms, FMX.Graphics, DPH.Project.Analysis, DPH.Analysis.Model, DPH.Analysis.Symbols,
  DPH.Analysis.Persistence, DPH.Storage.Database, DPH.Storage.Types, DPH.Workspace.Model,
  DPH.Workspace.Comparison, DPH.Workspace.Worker, DPH.UI.Main;
var Root,Work,Fixture,Database: string; ID: TGUID; Store: TDPHKnowledgeStore; Config: Int64;
    Before,After,Report,Invalid,Row,Extra,ResultLog: TJSONObject; Value: TJSONValue;
    Form: TDPHMainForm; Bitmap: TBitmap; Worker: TDPHWorkspaceWorker;
    Request: TDPHWorkspaceRequest; Response: TDPHWorkspaceResponse; Watch: TStopwatch;
    Checks,I: Integer; Found,Rejected: Boolean;
procedure Check(OK: Boolean; const Text: string);
begin if not OK then raise Exception.Create('FAIL '+Text); Inc(Checks); Writeln('PASS ',Checks,': ',Text); Flush(Output); end;
function WaitResponse: TDPHWorkspaceResponse;
begin
  Watch:=TStopwatch.StartNew; Result:=nil;
  repeat
    if Worker.Poll(Result) then begin if not Result.Busy then Exit; Result.Free; Result:=nil; end;
    if Watch.ElapsedMilliseconds>30000 then raise Exception.Create('Comparison worker timed out');
    TThread.Sleep(20);
  until False;
end;
function Capture: TJSONObject;
var Analyzer: TDPHAnalyzer; Semantic: TDPHSemanticAnalyzer; Scan: TDPHScan; Graph: TDPHSemanticGraph; Generation: Int64;
begin
  Analyzer:=TDPHAnalyzer.Create; Semantic:=TDPHSemanticAnalyzer.Create;
  try Scan:=Analyzer.Scan(TPath.Combine(Fixture,'Compare.dpr'),'Debug','Win32',[],[],False);
    try Graph:=Semantic.Analyze(Scan);
      try Generation:=TDPHSemanticPersistence.Stage(Scan,Graph,Store,Config);
        Result:=TDPHWorkspaceView.Capture(Scan,Graph,Generation,'Compare.dpr','Debug','Win32',[],[]);
        try Store.SaveWorkspaceView(Generation,Result.ToJSON); TDPHSemanticPersistence.Publish(Scan,Graph,Store,Generation);
        except Result.Free; raise; end;
      finally Graph.Free; end;
    finally Scan.Free; end;
  finally Semantic.Free; Analyzer.Free; end;
end;
function FindChange(const Kind,Name: string): TJSONObject;
var V: TJSONValue;
begin Result:=nil; for V in Report.GetValue<TJSONArray>('changes') do
  if (V.GetValue<string>('kind')=Kind) and ContainsText(V.GetValue<string>('key'),Name) then Exit(V as TJSONObject); end;
begin
  Application.Initialize;
  try
    Root:=TPath.GetFullPath(ParamStr(1)); CreateGUID(ID); Work:=TPath.Combine(Root,'bin\phase1-tests-'+GUIDToString(ID));
    Fixture:=TPath.Combine(Work,'source'); TDirectory.CreateDirectory(Fixture); Database:=TPath.Combine(Work,'comparison.dphdb');
    TFile.WriteAllText(TPath.Combine(Fixture,'Compare.dpr'),'program Compare; uses Model; begin Run; end.',TEncoding.UTF8);
    TFile.WriteAllText(TPath.Combine(Fixture,'Model.pas'),String.Join(sLineBreak,[
      'unit Model; interface procedure Run; implementation',
      'procedure Stable; begin Writeln(''unchanged''); end;',
      'procedure Removed; begin Writeln(''removed''); end;',
      'procedure Run; begin Stable; Writeln(''before''); end; end.']),TEncoding.UTF8);
    Store:=TDPHKnowledgeStore.Create(Database,Fixture,TPath.Combine(Root,'migrations')); Before:=nil; After:=nil;
    try Store.InitializeProject('Comparison fixture','Delphi'); Config:=Store.AddConfiguration('Win32','37.0','[]','[]','Debug'); Store.SelectConfiguration(Config);
      Before:=Capture;
      TFile.WriteAllText(TPath.Combine(Fixture,'Model.pas'),String.Join(sLineBreak,[
        'unit Model; interface procedure Run; implementation',
        'procedure Stable; begin Writeln(''unchanged''); end;',
        'procedure Added; begin Writeln(''added''); end;',
        'procedure Run; begin Stable; Writeln(''after''); end; end.']),TEncoding.UTF8);
      After:=Capture;
      Report:=TDPHRevisionComparison.Compare(Before,After);
      try
        Check(FindChange('file_changed','model.pas')<>nil,'Changed file is identified by captured fingerprints');
        Check(FindChange('symbol_removed','Removed')<>nil,'Removed symbol is retained as Before evidence');
        Check(FindChange('symbol_added','Added')<>nil,'Added symbol is retained as After evidence');
        Row:=FindChange('captured_structure_changed','Run');
        Check(Row<>nil,'Changed routine flow is distinguished from a file-level change');
        Check(TDPHRevisionComparison.EvidenceText(Row.GetValue<TJSONObject>('before')).Contains('before') and
          TDPHRevisionComparison.EvidenceText(Row.GetValue<TJSONObject>('after')).Contains('after'),'Side-by-side evidence includes changed captured expressions');
        Check(FindChange('source_file_changed_only','Stable')<>nil,'Unchanged captured routine is qualified when another routine changes its file');
        Check(Report.GetValue<string>('definition').Contains('Historical source bytes are not reconstructed'),'Comparison explains historical-source and inference limitations');
        Form:=TDPHMainForm.Create(nil);
        try Form.PollTimer.Enabled:=False; Form.ChangeTimer.Enabled:=False; Form.LoadView(After.Clone as TJSONObject);
          Form.LoadComparison(Report.Clone as TJSONObject);
          Check(Form.ComparisonList.Count=Report.GetValue<TJSONArray>('changes').Count,'Native page displays the bounded revision results');
          for I:=0 to Report.GetValue<TJSONArray>('changes').Count-1 do
            if Report.GetValue<TJSONArray>('changes').Items[I]=Row then Form.ComparisonList.ItemIndex:=I;
          Form.ComparisonSelectionClick(nil);
          Check(Form.ComparisonBeforeMemo.Text.Contains('before') and Form.ComparisonAfterMemo.Text.Contains('after'),'Native labeled panes show original and changed evidence');
          Form.WorkspaceTabs.ActiveTab:=Form.ComparisonTab; Form.Show; Application.ProcessMessages;
          Bitmap:=TBitmap.Create(Form.ClientWidth,Form.ClientHeight);
          try if Bitmap.Canvas.BeginScene then try Form.PaintTo(Bitmap.Canvas); finally Bitmap.Canvas.EndScene; end;
            Bitmap.SaveToFile(TPath.Combine(Root,'docs\validation\images\phase1-revision-comparison.png'));
          finally Bitmap.Free; end; Form.Hide;
        finally Form.Free; end;
      finally Report.Free; end;
      Report:=TDPHRevisionComparison.Compare(After,After);
      try Check(Report.GetValue<Integer>('total_matching')=0,'Identical capture has no changes'); finally Report.Free; end;
      Invalid:=After.Clone as TJSONObject;
      try
        Row:=Invalid.GetValue<TJSONArray>('semantics.flow_edges').Items[0] as TJSONObject;
        Row.RemovePair('kind').Free; Row.AddPair('kind','synthetic_changed_edge');
        Report:=TDPHRevisionComparison.Compare(After,Invalid);
        try Found:=False; for Value in Report.GetValue<TJSONArray>('changes') do
          if Value.GetValue<string>('kind')='captured_structure_changed' then Found:=True;
          Check(Found,'Control-flow edge changes are detected even when recorded expressions stay unchanged');
        finally Report.Free; end;
      finally Invalid.Free; end;
      Invalid:=After.Clone as TJSONObject;
      try Invalid.RemovePair('selection_hash').Free; Invalid.AddPair('selection_hash','different'); Rejected:=False;
        try Report:=TDPHRevisionComparison.Compare(Before,Invalid); Report.Free; except on E: EArgumentException do Rejected:=True; end;
        Check(Rejected,'Configuration mismatch is rejected instead of reported as source changes');
      finally Invalid.Free; end;
      Invalid:=After.Clone as TJSONObject;
      try
        for I:=1 to 215 do begin Extra:=Invalid.GetValue<TJSONArray>('semantics.symbols').Items[0].Clone as TJSONObject;
          Extra.RemovePair('key').Free; Extra.AddPair('key','synthetic-extra-'+IntToStr(I)); Invalid.GetValue<TJSONArray>('semantics.symbols').AddElement(Extra); end;
        Report:=TDPHRevisionComparison.Compare(After,Invalid,'synthetic-extra');
        try Check((Report.GetValue<TJSONArray>('changes').Count=200) and Report.GetValue<Boolean>('more'),'Comparison result page is bounded and preserves the matching total'); finally Report.Free; end;
        Report:=TDPHRevisionComparison.Compare(After,Invalid,'synthetic-extra',200);
        try Check((Report.GetValue<TJSONArray>('changes').Count=15) and not Report.GetValue<Boolean>('more'),'Next comparison page reaches remaining changes'); finally Report.Free; end;
      finally Invalid.Free; end;
      Check(Store.IntegrityCheck='ok','Comparison leaves the project database consistent');
    finally Store.Free; end;
    Worker:=TDPHWorkspaceWorker.Create(Root);
    try Request:=Default(TDPHWorkspaceRequest); Request.Command:='compare'; Request.Database:=Database;
      Request.BaselineGeneration:=Before.GetValue<Int64>('generation_id'); Request.GenerationID:=After.GetValue<Int64>('generation_id');
      Worker.Submit(Request); Response:=WaitResponse;
      try if Response.Failed then Writeln('Worker comparison error: '+Response.MessageText);
        Check(not Response.Failed and (Response.Comparison<>nil),'Background worker compares both verified retained database captures'); finally Response.Free; end;
      Request.BaselineGeneration:=999999; Worker.Submit(Request); Response:=WaitResponse;
      try Check(Response.Failed,'Missing historical cache is explained without inventing source history'); finally Response.Free; end;
    finally Worker.Free; end;
    Before.Free; After.Free;
    ResultLog:=TJSONObject.Create;
    try ResultLog.AddPair('checks_passed',TJSONNumber.Create(Checks)); ResultLog.AddPair('work',Work);
      TFile.WriteAllText(TPath.Combine(Root,'docs\validation\reports\phase1-comparison-validation.json'),ResultLog.Format(2),TEncoding.UTF8);
    finally ResultLog.Free; end;
    Writeln('PASS revision comparison: ',Checks,' checks');
  except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode:=1; end; end;
end.
