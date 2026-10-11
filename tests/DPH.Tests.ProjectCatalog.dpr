program DPH.Tests.ProjectCatalog;
{$APPTYPE CONSOLE}
uses System.SysUtils, System.Classes, System.IOUtils, System.JSON, System.StrUtils, System.UITypes,
  FMX.Forms, FMX.Graphics, DPH.Project.Analysis, DPH.Analysis.Model,
  DPH.Analysis.Symbols, DPH.Workspace.Model, DPH.UI.Main;
var Root,Work,Fixture,Entry: string; ID: TGUID; Checks: Integer;
    Analyzer: TDPHAnalyzer; Semantic: TDPHSemanticAnalyzer; Scan: TDPHScan;
    Graph: TDPHSemanticGraph; View: TDPHWorkspaceView; Members: TJSONArray;
    Row,Node,Report: TJSONObject; Value: TJSONValue; Form: TDPHMainForm;
    Bitmap: TBitmap; Found: Boolean; Index: Integer;
procedure Check(OK: Boolean; const Text: string);
begin if not OK then raise Exception.Create('FAIL '+Text); Inc(Checks); Writeln('PASS ',Checks,': ',Text); end;
function FindMember(const Path: string): TJSONObject;
var Item: TJSONValue;
begin Result:=nil; for Item in Members do
  if SameText(Item.GetValue<string>('path'),Path) then Exit(Item as TJSONObject); end;
begin
  Application.Initialize;
  try
    Root:=TPath.GetFullPath(ParamStr(1)); CreateGUID(ID);
    Work:=TPath.Combine(Root,'bin\phase1-tests-'+GUIDToString(ID));
    Fixture:=TPath.Combine(Work,'catalog'); TDirectory.CreateDirectory(Fixture);
    Entry:=TPath.Combine(Fixture,'Suite.groupproj');
    TFile.WriteAllText(Entry,'<Project><ItemGroup><Projects Include="App.dproj"/><Projects Include="Shared.dpr"/><Projects Include="Widgets.dpk"/><Projects Include="Missing.dproj"/></ItemGroup></Project>',TEncoding.UTF8);
    TFile.WriteAllText(TPath.Combine(Fixture,'App.dproj'),'<Project><PropertyGroup><MainSource>App.dpr</MainSource><FrameworkType>FMX</FrameworkType></PropertyGroup><PropertyGroup Condition="''$(Config)''==''Debug''"><DCC_Define>CATALOG_DEBUG</DCC_Define></PropertyGroup><ItemGroup><DelphiCompile Include="App.dpr"/></ItemGroup></Project>',TEncoding.UTF8);
    TFile.WriteAllText(TPath.Combine(Fixture,'App.dpr'),'program CatalogApp; begin end.',TEncoding.UTF8);
    TFile.WriteAllText(TPath.Combine(Fixture,'Shared.dpr'),'library CatalogShared; begin end.',TEncoding.UTF8);
    TFile.WriteAllText(TPath.Combine(Fixture,'Widgets.dpk'),'package CatalogWidgets; end.',TEncoding.UTF8);
    Analyzer:=TDPHAnalyzer.Create; Semantic:=TDPHSemanticAnalyzer.Create;
    try
      Scan:=Analyzer.Scan(Entry,'Debug','Win32',[],[],False);
      try
        Graph:=Semantic.Analyze(Scan);
        try View:=TDPHWorkspaceView.Create(TDPHWorkspaceView.Capture(Scan,Graph,42,Entry,'Debug','Win32',[],[]));
          try Members:=View.ProjectMembers;
            try
              Check(Members.Count=6,'Selected group catalog contains group, settings, three output declarations and missing member');
              Check(FindMember('suite.groupproj').GetValue<string>('kind')='project group','Group identity is preserved');
              Check(FindMember('app.dpr').GetValue<string>('kind')='executable declaration','Program declaration is classified as executable evidence');
              Check(FindMember('shared.dpr').GetValue<string>('kind')='library declaration','Library declaration is classified from captured syntax');
              Check(FindMember('widgets.dpk').GetValue<string>('kind')='package declaration','Package declaration is classified from captured syntax');
              Check((FindMember('missing.dproj').GetValue<string>('availability')='missing') and
                (FindMember('missing.dproj').GetValue<TJSONArray>('settings_and_references').Count=0),'Missing group member remains visible without fabricated settings');
              Row:=FindMember('app.dproj'); Found:=False;
              for Value in Row.GetValue<TJSONArray>('settings_and_references') do begin
                Node:=Value as TJSONObject;
                if (Node.GetValue<string>('name')='FrameworkType') and (Node.GetValue<string>('value')='FMX') then
                  Found:=Node.GetValue<Integer>('line')>0;
              end;
              Check(Found,'Settings retain captured values and source lines');
              Found:=True;
              for Value in Members do Found:=Found and (Value.GetValue<Int64>('generation_id')=42) and
                ((Length(Value.GetValue<string>('source_hash'))=64) or (Value.GetValue<string>('availability')='missing'));
              Check(Found,'Catalog rows identify their capture and available source hashes');
              Check(FindMember('app.dpr').GetValue<TJSONObject>('declaration').GetValue<Integer>('line')=1,'Output declaration retains its exact source reference');
              Check(FindMember('app.dpr').GetValue<string>('qualification').Contains('not a built binary'),'Declaration classification does not claim a verified build or service installation');
              Form:=TDPHMainForm.Create(nil);
              try
                Form.PollTimer.Enabled:=False; Form.ChangeTimer.Enabled:=False;
                Form.LoadView(View.Document.Clone as TJSONObject);
                Check(Form.ProjectMembersList.Count=6,'Native Projects page displays the captured catalog including missing inputs');
                for Index:=0 to Members.Count-1 do if Form.ProjectMembersList.Items[Index].Contains('app.dproj') then Form.ProjectMembersList.ItemIndex:=Index;
                Check(Form.ProjectMemberMemo.Text.Contains('FrameworkType = FMX') and
                  Form.ProjectMemberMemo.Text.Contains('Evidence: app.dproj:1'),'Native catalog selection explains settings and their evidence');
                Form.WorkspaceTabs.ActiveTab:=Form.ProjectsTab; Form.ProjectCatalogTabs.ActiveTab:=Form.ProjectMembersTab;
                Form.Show; Application.ProcessMessages;
                Bitmap:=TBitmap.Create(Form.ClientWidth,Form.ClientHeight);
                try if Bitmap.Canvas.BeginScene then try Form.PaintTo(Bitmap.Canvas); finally Bitmap.Canvas.EndScene; end;
                  Bitmap.SaveToFile(TPath.Combine(Root,'docs\phase1-project-catalog.png'));
                finally Bitmap.Free; end;
                Form.WindowState:=TWindowState.wsNormal; Form.Width:=960; Form.Height:=600;
                Application.ProcessMessages;
                Check(Form.ProjectMemberMemo.Height>=80,'Evidence remains readable at the minimum supported restored window size');
                Bitmap:=TBitmap.Create(Form.ClientWidth,Form.ClientHeight);
                try if Bitmap.Canvas.BeginScene then try Form.PaintTo(Bitmap.Canvas); finally Bitmap.Canvas.EndScene; end;
                  Bitmap.SaveToFile(TPath.Combine(Root,'docs\phase1-project-catalog-compact.png'));
                finally Bitmap.Free; end;
                Form.Hide;
              finally Form.Free; end;
              Check(Scan.Inventory.Revalidate,'Catalog projection and native inspection leave selected source inputs unchanged');
            finally Members.Free; end;
          finally View.Free; end;
        finally Graph.Free; end;
      finally Scan.Free; end;
    finally Semantic.Free; Analyzer.Free; end;
    Report:=TJSONObject.Create;
    try Report.AddPair('checks_passed',TJSONNumber.Create(Checks)); Report.AddPair('work',Work);
      Report.AddPair('qualification','Controlled selected-group fixture; declaration kinds only. Service installation and actual build outputs are not verified. Native image is an FMX PaintTo render.');
      TFile.WriteAllText(TPath.Combine(Root,'docs\phase1-project-catalog-validation.json'),Report.Format(2),TEncoding.UTF8);
    finally Report.Free; end;
    Writeln('PASS project catalog: ',Checks,' checks');
  except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode:=1; end; end;
end.
