program DPH.Tests.SourceQuality;
{$APPTYPE CONSOLE}
uses System.SysUtils, System.IOUtils, System.JSON, System.Hash, System.StrUtils, FMX.Forms, FMX.Graphics,
  DPH.Project.Analysis in '..\DPH.Project.Analysis.pas', DPH.Analysis.Model in '..\DPH.Analysis.Model.pas',
  DPH.Analysis.Symbols in '..\DPH.Analysis.Symbols.pas', DPH.Analysis.Quality in '..\DPH.Analysis.Quality.pas',
  DPH.Workspace.Model in '..\DPH.Workspace.Model.pas', DPH.UI.Main in '..\DPH.UI.Main.pas';
var Root,Work,Fixture,SourceHash,Key: string; ID: TGUID; Analyzer: TDPHAnalyzer; Semantic: TDPHSemanticAnalyzer;
    Scan: TDPHScan; Graph: TDPHSemanticGraph; Quality,Again,Row,Report: TJSONObject; Value,Member: TJSONValue;
    View: TDPHWorkspaceView; Form: TDPHMainForm; Bitmap: TBitmap; Checks: Integer; Found,Unexpected: Boolean;
procedure Check(OK: Boolean; const Text: string);
begin if not OK then raise Exception.Create('FAIL '+Text); Inc(Checks); Writeln('PASS ',Checks,': ',Text); Flush(Output); end;
begin
  Application.Initialize;
  try
    Root:=TPath.GetFullPath(ParamStr(1)); CreateGUID(ID); Work:=TPath.Combine(Root,'bin\phase1-tests-'+GUIDToString(ID));
    Fixture:=TPath.Combine(Work,'source'); TDirectory.CreateDirectory(Fixture);
    TFile.WriteAllText(TPath.Combine(Fixture,'QualityFixture.pas'),String.Join(sLineBreak,[
      'unit QualityFixture;',
      'interface',
      'procedure Entry;',
      'procedure Alpha;',
      'procedure Beta;',
      'procedure Gamma;',
      'implementation',
      'procedure DuplicateA; var X: Integer; begin X:=1; X:=X+2; X:=X*3; end;',
      'procedure DuplicateB; var X: Integer; begin X:=1; X:=X+2; X:=X*3; end;',
      'procedure LiteralA; begin Writeln(''CaseSensitive''); Writeln(''same suffix''); end;',
      'procedure LiteralB; begin Writeln(''casesensitive''); Writeln(''same suffix''); end;',
      'procedure NeverReferenced; begin Writeln(''private candidate''); end;',
      'procedure Disconnected; begin Exit; Writeln(''after return''); end;',
      'procedure Branch(Value: Integer); begin if Value>0 then Writeln(Value); while Value>0 do Dec(Value); end;',
      'procedure Alpha; begin Beta; end;',
      'procedure Beta; begin Gamma; end;',
      'procedure Gamma; begin Alpha; end;',
      'procedure Entry; begin DuplicateA; Alpha; Branch(2); LiteralA; LiteralB; Disconnected; end;',
      'end.']),TEncoding.UTF8);
    TFile.WriteAllText(TPath.Combine(Fixture,'Quality.dpr'),'program Quality; uses QualityFixture; begin Entry; end.',TEncoding.UTF8);
    SourceHash:=THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'QualityFixture.pas'));
    Analyzer:=TDPHAnalyzer.Create; Semantic:=TDPHSemanticAnalyzer.Create;
    try Scan:=Analyzer.Scan(TPath.Combine(Fixture,'Quality.dpr'),'Debug','Win32',[],[],False);
      try Graph:=Semantic.Analyze(Scan);
        try Quality:=TDPHSourceQuality.Analyze(Scan,Graph);
          try
            TFile.WriteAllText(TPath.Combine(Work,'quality-debug.json'),Quality.Format(2),TEncoding.UTF8);
            Check(Quality.GetValue<TJSONArray>('routines').Count>=12,'Source quality reports captured routine metrics');
            Found:=False; for Value in Quality.GetValue<TJSONArray>('routines') do if Value.GetValue<string>('name')='QualityFixture.Branch' then begin
              Found:=Value.GetValue<Integer>('structural_decision_score')=3;
              Check(Value.GetValue<string>('source_hash')=SourceHash,'Routine metric retains the actual source fingerprint');
            end;
            Check(Found,'Structural decision score counts the captured if and while without claiming exact cyclomatic complexity');
            Found:=False; Unexpected:=False;
            for Value in Quality.GetValue<TJSONArray>('duplicate_bodies') do begin
              Key:=''; for Member in Value.GetValue<TJSONArray>('members') do Key:=Key+' '+Member.GetValue<string>('name');
              if ContainsText(Key,'DuplicateA') and ContainsText(Key,'DuplicateB') then Found:=True;
              if ContainsText(Key,'LiteralA') and ContainsText(Key,'LiteralB') then Unexpected:=True;
            end;
            Check(Found,'Equal nontrivial significant-token bodies become qualified duplicate candidates');
            Check(not Unexpected,'Different literal case is preserved and does not become equal-body evidence');
            Found:=False;
            for Value in Quality.GetValue<TJSONArray>('unreferenced_candidates') do
              if Value.GetValue<string>('name')='QualityFixture.NeverReferenced' then Found:=True;
            Check(Found,'Private routine without a captured incoming reference is an investigation candidate');
            Found:=False;
            for Value in Quality.GetValue<TJSONArray>('unreachable_candidates') do
              if Value.GetValue<string>('name')='QualityFixture.Disconnected' then Found:=True;
            Check(Found,'Statement disconnected after Exit is surfaced with bounded CFG evidence');
            Found:=False;
            for Value in Quality.GetValue<TJSONArray>('call_cycles') do begin
              Key:=''; for Member in Value.GetValue<TJSONArray>('members') do Key:=Key+' '+Member.GetValue<string>('name');
              if ContainsText(Key,'Alpha') and ContainsText(Key,'Beta') and ContainsText(Key,'Gamma') then Found:=True;
            end;
            Check(Found,'Iterative call-cycle analysis finds a three-routine strongly connected component');
            Again:=TDPHSourceQuality.Analyze(Scan,Graph);
            try Check(Again.ToJSON=Quality.ToJSON,'Same captured inputs produce deterministic source-quality evidence'); finally Again.Free; end;
            Check(Quality.GetValue<string>('definition').Contains('never proof'),'Candidate report explicitly rejects unsupported unused-code conclusions');
            View:=TDPHWorkspaceView.Create(TDPHWorkspaceView.Capture(Scan,Graph,1,'Quality.dpr','Debug','Win32',[],[]));
            try
              Check(View.Document.GetValue<string>('source_quality.version')=DPHQualityVersion,'Quality evidence is retained in the captured workspace');
              Form:=TDPHMainForm.Create(nil);
              try
                Writeln('Native form created'); Flush(Output);
                Form.PollTimer.Enabled:=False; Form.ChangeTimer.Enabled:=False; Form.LoadView(View.Document.Clone as TJSONObject);
                Check(Form.QualityList.Count>=12,'Native Source quality page lists captured routine metrics');
                Form.QualityKindCombo.ItemIndex:=1; Form.QualityClick(nil);
                Check((Form.QualityList.Count>0) and Form.QualityMemo.Text.Contains('potential duplicates'),'Native duplicate inspection supplies qualified explanation and member evidence');
                Form.WorkspaceTabs.ActiveTab:=Form.QualityTab; Form.Show; Application.ProcessMessages;
                Bitmap:=TBitmap.Create(Form.ClientWidth,Form.ClientHeight);
                try if Bitmap.Canvas.BeginScene then try Form.PaintTo(Bitmap.Canvas); finally Bitmap.Canvas.EndScene; end;
                  Bitmap.SaveToFile(TPath.Combine(Root,'docs\validation\images\phase1-source-quality.png'));
                finally Bitmap.Free; end;
                Form.QualityClick(Form.QualityOpenButton);
                Check(Form.WorkspaceTabs.ActiveTab=Form.ExplainTab,'Quality finding navigates to its canonical source-backed explanation');
                Form.Hide;
              finally Form.Free; end;
            finally View.Free; end;
            Check(THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'QualityFixture.pas'))=SourceHash,'Source quality analysis leaves selected input bytes unchanged');
            Report:=TJSONObject.Create;
            try Report.AddPair('checks_passed',TJSONNumber.Create(Checks)); Report.AddPair('quality_version',DPHQualityVersion); Report.AddPair('work',Work);
              Report.AddPair('report',Quality.Clone as TJSONObject);
              TFile.WriteAllText(TPath.Combine(Root,'docs\validation\reports\phase1-quality-validation.json'),Report.Format(2),TEncoding.UTF8);
            finally Report.Free; end;
          finally Quality.Free; end;
        finally Graph.Free; end;
      finally Scan.Free; end;
    finally Semantic.Free; Analyzer.Free; end;
    Writeln('PASS Phase1 source quality: ',Checks,' checks');
  except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode:=1; end; end;
end.

