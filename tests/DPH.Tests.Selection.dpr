program DPHSelectionTests;
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.IOUtils, System.JSON, System.Diagnostics, System.Classes,
  FMX.Forms, Winapi.ActiveX,
  DPH.UI.Main in '..\DPH.UI.Main.pas',
  DPH.Project.Inventory, DPH.Project.Analysis, DPH.Workspace.Model,
  DPH.Analysis.Symbols, DPH.Analysis.Model, DPH.Analysis.Persistence,
  DPH.Storage.Database;
var
  Root,Work,Ordinary,SelfProject,SelfCache,Path,SelectedText,OriginalHash: string;
  ID: TGUID; Checks: Integer;
  WorkerForm: TDPHMainForm; PreviousView: TDPHWorkspaceView;
  Inventory: TDPHInventory; Analyzer: TDPHAnalyzer; Semantic: TDPHSemanticAnalyzer;
  Scan: TDPHScan; Graph: TDPHSemanticGraph; Store: TDPHKnowledgeStore;
  Document,Report: TJSONObject; Configuration,Generation: Int64;
  PreferencePath: string; SavedPreference: TBytes; HadPreference: Boolean; Preference: TJSONObject;
procedure Check(Condition: Boolean; const MessageText: string);
begin
  if not Condition then raise Exception.Create('FAIL: '+MessageText);
  Inc(Checks); Writeln('PASS ',Checks,': ',MessageText);
end;
procedure WaitFor(const Text: string);
var Watch: TStopwatch;
begin
  Watch:=TStopwatch.StartNew;
  repeat
    Application.ProcessMessages; WorkerForm.PollTimerTimer(nil);
    if Pos(Text,WorkerForm.StatusLabel.Text)>0 then Exit;
    Sleep(10);
  until Watch.ElapsedMilliseconds>60000;
  raise Exception.Create('Timed out waiting for '+Text+': '+WorkerForm.StatusLabel.Text);
end;
begin
  HadPreference:=False;
  CoInitialize(nil); Application.Initialize;
  try
    try
      if SameText(ExtractFileExt(ParamStr(1)),'.dphdb') then
      begin
        // FormCreate follows the actual command-line startup path.
        WorkerForm:=TDPHMainForm.Create(nil);
        try
          WaitFor(DPHSelfSelectionMessage);
          Check(WorkerForm.WorkspaceView=nil,'Startup does not load a self-analysis cache');
          Check(WorkerForm.WorkspaceTabs.ActiveTab=WorkerForm.HelpTab,'Rejected startup selection shows Getting started');
        finally WorkerForm.Free; end;
        Exit;
      end;
      Root:=TPath.GetFullPath(ParamStr(1)); CreateGUID(ID);
      PreferencePath:=TPath.Combine(TPath.GetHomePath,'AppData\Local\DPH\workspace.json');
      HadPreference:=TFile.Exists(PreferencePath);
      if HadPreference then SavedPreference:=TFile.ReadAllBytes(PreferencePath);
      Work:=TPath.Combine(Root,'bin\selection-tests-'+GUIDToString(ID));
      Ordinary:=TPath.Combine(Work,'ordinary'); SelfProject:=TPath.Combine(Work,'renamed-copy');
      TDirectory.CreateDirectory(Ordinary); TDirectory.CreateDirectory(SelfProject);
      TFile.WriteAllText(TPath.Combine(Ordinary,'DelphiProjectHandoff.dproj'),
        '<Project><PropertyGroup><ProjectGuid>{12345678-1234-1234-1234-123456789ABC}</ProjectGuid></PropertyGroup><ItemGroup><DelphiCompile Include="Other.dpr" /></ItemGroup></Project>',TEncoding.UTF8);
      TFile.WriteAllText(TPath.Combine(Ordinary,'Other.dpr'),'program Other; begin end.',TEncoding.UTF8);
      TFile.WriteAllText(TPath.Combine(SelfProject,'Renamed.dproj'),
        '<Project><PropertyGroup><ProjectGuid>'+LowerCase(DPHHandoffProjectGUID)+'</ProjectGuid></PropertyGroup><ItemGroup><DelphiCompile Include="Other.dpr" /></ItemGroup></Project>',TEncoding.UTF8);
      TFile.Copy(TPath.Combine(Ordinary,'Other.dpr'),TPath.Combine(SelfProject,'Other.dpr'));
      TFile.WriteAllText(TPath.Combine(SelfProject,'RenamedProgram.dpr'),
        '// explicitly synthetic identity fixture'+sLineBreak+'program DelphiProjectHandoff; begin end.',TEncoding.UTF8);
      TFile.WriteAllText(TPath.Combine(SelfProject,'Group.groupproj'),
        '<Project><ItemGroup><Projects Include="Renamed.dproj" /></ItemGroup></Project>',TEncoding.UTF8);
      OriginalHash:=TFile.ReadAllText(TPath.Combine(SelfProject,'Renamed.dproj'),TEncoding.UTF8);
      Inventory:=TDPHInventory.Create(TPath.Combine(SelfProject,'Renamed.dproj'),'Debug','Win32',[],[]);
      try Check(Inventory.IsHandoffProject,'Renamed and relocated project is recognized by GUID'); finally Inventory.Free; end;
      Inventory:=TDPHInventory.Create(TPath.Combine(SelfProject,'RenamedProgram.dpr'),'Debug','Win32',[],[]);
      try Check(Inventory.IsHandoffProject,'Renamed DPR is recognized by its program declaration'); finally Inventory.Free; end;
      Inventory:=TDPHInventory.Create(TPath.Combine(Ordinary,'DelphiProjectHandoff.dproj'),'Debug','Win32',[],[]);
      try Check(not Inventory.IsHandoffProject,'Unrelated project with the same filename is allowed'); finally Inventory.Free; end;
      Inventory:=TDPHInventory.Create(TPath.Combine(SelfProject,'Group.groupproj'),'Debug','Win32',[],[]);
      try Check(Inventory.IsHandoffProject,'A project group containing DPH is recognized'); finally Inventory.Free; end;
      Inventory:=TDPHInventory.Create(TPath.Combine(Root,'DelphiProjectHandoff.dproj'),'Debug','Win32',[],[]);
      try Check(Inventory.IsHandoffProject,'Actual DPH project is recognized'); finally Inventory.Free; end;

      // Manufacture historical evidence through the same capture/storage pipeline.
      // Core analyzer tests remain able to produce old-version fixture caches.
      SelfCache:=TPath.Combine(Work,'renamed-historical-cache.dphdb');
      Store:=TDPHKnowledgeStore.Create(SelfCache,SelfProject,TPath.Combine(Root,'migrations'));
      Analyzer:=TDPHAnalyzer.Create; Semantic:=TDPHSemanticAnalyzer.Create;
      try
        Store.InitializeProject('Synthetic historical DPH identity','Delphi');
        Configuration:=Store.AddConfiguration('Win32','37.0','[]','[]','Debug');
        Store.SelectConfiguration(Configuration);
        Scan:=Analyzer.Scan(TPath.Combine(SelfProject,'Renamed.dproj'),'Debug','Win32',[],[],False);
        try
          Graph:=Semantic.Analyze(Scan);
          try
            Generation:=TDPHSemanticPersistence.Stage(Scan,Graph,Store,Configuration);
            Document:=TDPHWorkspaceView.Capture(Scan,Graph,Generation,'Renamed.dproj','Debug','Win32',[],[]);
            try
              Check(TDPHWorkspaceView.IsHandoffProject(Document),'Historical cache identifies self from captured GUID');
              Store.SaveWorkspaceView(Generation,Document.ToJSON);
            finally Document.Free; end;
            TDPHSemanticPersistence.Publish(Scan,Graph,Store,Generation);
          finally Graph.Free; end;
        finally Scan.Free; end;
      finally Semantic.Free; Analyzer.Free; Store.Free; end;
      WorkerForm:=TDPHMainForm.Create(nil);
      try
        Check(SameFileName(WorkerForm.DatabaseDialog.InitialDir,TPath.Combine(Root,'Databases')),'Save database dialog defaults to the app Databases folder');
        Check(SameFileName(WorkerForm.OpenCacheDialog.InitialDir,WorkerForm.DatabaseDialog.InitialDir),'Open cache dialog defaults to the same folder');
        Check(TDirectory.Exists(WorkerForm.DatabaseDialog.InitialDir),'Default Databases folder exists');
        WorkerForm.OpenSelection(TPath.Combine(Ordinary,'DelphiProjectHandoff.dproj'),TPath.Combine(Work,'ordinary.dphdb'));
        WaitFor('captured analysis');
        Check(WorkerForm.WorkspaceView<>nil,'Unrelated project attaches successfully despite matching filename');
        PreviousView:=WorkerForm.WorkspaceView;
        WorkerForm.ExplorerList.ItemIndex:=0; WorkerForm.ExplorerClick(nil); SelectedText:=WorkerForm.InspectorMemo.Text;
        WorkerForm.OpenSelection(TPath.Combine(SelfProject,'Renamed.dproj'),TPath.Combine(Work,'must-not-exist.dphdb'));
        WaitFor(DPHSelfSelectionMessage);
        Check(WorkerForm.WorkspaceView=PreviousView,'Rejected self-project keeps the current workspace');
        Check(WorkerForm.InspectorMemo.Text=SelectedText,'Rejected self-project keeps the selected object details');
        Check(not TFile.Exists(TPath.Combine(Work,'must-not-exist.dphdb')),'Rejected self-project does not create a database');
        WorkerForm.OpenSelection(TPath.Combine(SelfProject,'RenamedProgram.dpr'),TPath.Combine(Work,'must-not-exist-dpr.dphdb'));
        WaitFor(DPHSelfSelectionMessage);
        Check(WorkerForm.WorkspaceView=PreviousView,'DPR rejection also preserves the workspace');
        WorkerForm.OpenSelection('',SelfCache); WaitFor(DPHSelfSelectionMessage);
        Check(WorkerForm.WorkspaceView=PreviousView,'Rejected self-cache keeps the current workspace');
        Check(WorkerForm.InspectorMemo.Text=SelectedText,'Rejected self-cache keeps the selected object details');
        WorkerForm.OpenSelection('',TPath.Combine(Work,'ordinary.dphdb')); WaitFor('Cached project');
        Check(WorkerForm.WorkspaceView<>nil,'An ordinary cache remains usable after rejected selections');
        WorkerForm.HelpClick(nil);
      finally WorkerForm.Free; end;
      Check(TFile.ReadAllText(TPath.Combine(SelfProject,'Renamed.dproj'),TEncoding.UTF8)=OriginalHash,'Identity checks leave selected source unchanged');
      Report:=TJSONObject.Create;
      try
        Report.AddPair('checks_passed',TJSONNumber.Create(Checks)); Report.AddPair('self_cache',SelfCache);
        Report.AddPair('work',Work);
        Report.AddPair('preference_path',PreferencePath);
        TFile.WriteAllText(TPath.Combine(Root,'docs\validation\reports\selection-validation.json'),Report.Format(2),TEncoding.UTF8);
      finally Report.Free; end;
      Writeln('PASS Selection: ',Checks,' checks');
    except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode:=1; end; end;
  finally
    // Do not leave a fixture as the owner's remembered startup project.
    if (Work<>'') and TFile.Exists(PreferencePath) then
    begin
      Preference:=TJSONObject.ParseJSONValue(TFile.ReadAllText(PreferencePath,TEncoding.UTF8)) as TJSONObject;
      try
        if (Preference<>nil) and SameFileName(Preference.GetValue<string>('database',''),TPath.Combine(Work,'ordinary.dphdb')) then
          if HadPreference then TFile.WriteAllBytes(PreferencePath,SavedPreference) else TFile.Delete(PreferencePath);
      finally Preference.Free; end;
    end;
    CoUninitialize;
  end;
end.
