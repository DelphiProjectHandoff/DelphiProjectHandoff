program DPH.Tests.Practice;
{$APPTYPE CONSOLE}
uses System.SysUtils,System.Classes,System.IOUtils,System.JSON,System.Hash,System.StrUtils,System.Diagnostics,System.UITypes,
 Winapi.ActiveX,FMX.Forms,FMX.Graphics,
 DPH.UI.Main in '..\DPH.UI.Main.pas',DPH.Workspace.Model in '..\DPH.Workspace.Model.pas',DPH.Storage.Database in '..\DPH.Storage.Database.pas',
 DPH.Publish.Model in '..\DPH.Publish.Model.pas',DPH.Publish.Export in '..\DPH.Publish.Export.pas',DPH.Analysis.Explanations in '..\DPH.Analysis.Explanations.pas';
var Root,Work,Database,HTML,Key:string;Form:TDPHMainForm;Watch:TStopwatch;Checks:Integer;
 Store:TDPHKnowledgeStore;View:TDPHWorkspaceView;Rows,Images,Found:TJSONArray;Model:TDPHDocumentModel;Explain:TDPHExplanationModel;
 Pack,Report:TJSONObject;Pair:TJSONPair;Bitmap:TBitmap;
procedure Check(OK:Boolean;const Text:string);
begin if not OK then raise Exception.Create('FAIL '+Text);Inc(Checks);Writeln('PASS ',Checks,': ',Text);Flush(Output);end;
procedure Capture(const Name:string);
begin
 Application.ProcessMessages;Bitmap:=TBitmap.Create(Form.ClientWidth,Form.ClientHeight);
 try if Bitmap.Canvas.BeginScene then try Form.PaintTo(Bitmap.Canvas);finally Bitmap.Canvas.EndScene;end;Bitmap.SaveToFile(TPath.Combine(Root,'docs\validation\images\learning-completion-'+Name+'.png'));finally Bitmap.Free;end;
end;
begin
 CoInitialize(nil);Application.Initialize;
 try
  try
   Root:=TPath.GetFullPath(ParamStr(1));Work:=TPath.GetFullPath(ParamStr(2));TDirectory.CreateDirectory(Work);Database:=TPath.Combine(Work,'OrderPractice.dphdb');
   Pack:=TJSONObject.ParseJSONValue(TFile.ReadAllText(TPath.Combine(Root,'samples\OrderPractice\lessons.json'),TEncoding.UTF8)) as TJSONObject;
   try
    Form:=TDPHMainForm.Create(nil);
    try
     Form.Show;Form.ChangeTimer.Enabled:=False;Form.DatabaseDialog.InitialDir:=Work;Form.PracticeClick(nil);Watch:=TStopwatch.StartNew;
     repeat Form.PollTimerTimer(nil);Application.ProcessMessages;TThread.Sleep(15);
     until ((Form.WorkspaceView<>nil) and Form.WorkspaceTabs.Enabled and (Form.TaskList.Count=4) and (Form.CardList.Count=14)) or (Watch.ElapsedMilliseconds>30000);
     Check((Form.WorkspaceView<>nil) and (Form.TaskList.Count=4) and (Form.CardList.Count=14),'One practice button opens four ordered tasks and fourteen actual application explanations: '+Form.StatusLabel.Text);
     Check(Form.ScreenshotList.Count=2,'The practice application includes its native screen and sample output');
     Form.TaskPathFilter.Text:='First day';Form.TaskRoleFilter.Text:='New learner';Form.TaskFilterChange(nil);
     Check((Form.TaskList.Count=4) and (Form.TaskList.Items[0]='Meet the practice application') and (Form.TaskList.Items[3]='Understand an input error safely'),'First day learning path follows the prepared prerequisite order');
     Form.WorkspaceTabs.ActiveTab:=Form.TaskTab;Form.TaskList.ItemIndex:=1;Form.TaskSelectionChange(nil);
     Check(ContainsText(Form.TaskContextMemo.Text,'Predict a total') or ContainsText(Form.TaskContextMemo.Text,'inputs become'),'The learner starts with a task purpose rather than source metadata');
     Check(ContainsText(Form.TaskActionMemo.Text,'quantity 2') and ContainsText(Form.TaskResultMemo.Text,'20.00'),'A real worked task teaches the input and expected subtotal');
     Form.TaskLearner.Text:='Practice learner';Form.TaskSelectionChange(nil);Form.TaskProgressClick(Form.TaskCheckStep);
     Check(ContainsText(Form.TaskProgressLabel.Text,'1 of 3') and (Form.TaskStepLabel.Text='Step 2 of 3'),'Practice learner can save a checked result and resume the next action');Capture('practice-task');
     Form.CardFilter.Text:='Quantity:';Form.CardFilterChange(nil);Form.WorkspaceTabs.ActiveTab:=Form.CardLibraryTab;
     Check((Form.CardList.Count=1) and ContainsText(Form.CardReader.Text,'whole numbers from 1 to 1000') and ContainsText(Form.CardReader.Text,'minimum is 1'),'Field guide teaches meaning, valid input and the expected practice answer');Capture('practice-library');
     Check(Form.CardRelated.Enabled,'Field guidance links to its actual captured control');Form.CardRelatedClick(nil);Check(Form.WorkspaceTabs.ActiveTab=Form.ExplainTab,'Contextual help opens the linked control explanation');Form.WorkspaceTabs.ActiveTab:=Form.CardLibraryTab;
     Form.CardFilter.Text:='Why did changing a field';Form.CardFilterChange(nil);
     Check(ContainsText(Form.CardReader.Text,'does not automatically run') and ContainsText(Form.CardReader.Text,'Calculate total button click'),'FAQ explains an actual application behavior with a concrete answer');
     Form.WorkspaceTabs.ActiveTab:=Form.ScreenshotTab;Form.ScreenshotList.ItemIndex:=0;Form.ScreenshotClick(nil);
     Check(ContainsText(Form.ScreenshotEvidence.Text,'Sample output') and ContainsText(Form.ScreenshotEvidence.Text,'Reading the displayed total'),'Native sample output has its anchored teaching explanation');Capture('practice-output');
     Form.WindowState:=TWindowState.wsNormal;Form.ClientWidth:=960;Form.ClientHeight:=600;Form.WorkspaceTabs.ActiveTab:=Form.CardLibraryTab;
     Form.CardFilter.Text:='Quantity:';Form.CardFilterChange(nil);Capture('practice-library-compact');
     Check(not Form.ExplorerLayout.Visible and not Form.InspectorLayout.Visible,'Compact learning library uses the available width without technical side panes');
     Form.WorkspaceTabs.ActiveTab:=Form.TaskTab;Capture('practice-task-compact');
     Form.Hide;
    finally Form.Free;end;
    Store:=TDPHKnowledgeStore.Create(Database,TPath.Combine(Root,'samples\OrderPractice'),TPath.Combine(Root,'migrations'));
    try
     View:=TDPHWorkspaceView.Create(TJSONObject.ParseJSONValue(Store.LoadWorkspaceView) as TJSONObject);
     try
      Rows:=Store.KnowledgeJSON;Images:=Store.ScreenshotsJSON;
      try
       Check(Rows.Count=19,'Practice knowledge persists as nineteen attributed records');
       Model:=TDPHDocumentModel.Create(View,Rows,[],[],False,False,Images);
       try
        Explain:=TDPHExplanationModel.Create(Model.Document);
        try
         Check(ContainsText(Explain.LessonHTML(0),'does not save orders'),'Application purpose explains the boundary in ordinary language');
         Check(ContainsText(Explain.LessonHTML(2),'whole numbers from 1 to 1000'),'Screen lesson includes its supplied field meanings');
         Check(ContainsText(Explain.LessonHTML(4),'optional tax 1.50'),'Decision lesson includes the worked business rule');
         Check(ContainsText(Explain.LessonHTML(5),'unchecked gives 20.00; checked gives 22.00'),'Input/result lesson explains both option-dependent outcomes');
         Check(ContainsText(Explain.LessonHTML(9),'replace the value') or ContainsText(Explain.LessonHTML(9),'Replace the quantity'),'Question lesson includes the actual error recovery');
         Found:=View.Search('CalculateClick','routine','');try Check(Found.Count=1,'The sample responding operation resolves to one captured identity');Key:=Found.Items[0].GetValue<string>('key');finally Found.Free;end;
         HTML:=Explain.ObjectLessonHTML(Key);Check(ContainsText(HTML,'TaxCheck') and ContainsText(HTML,'How the total is calculated'),'The actual operation combines source-derived decisions with its attributed meaning');
        finally Explain.Free;end;
        TDPHPublisher.Export(Model,Store,TPath.Combine(Work,'shared-practice'));TDPHPublisher.Validate(TPath.Combine(Work,'shared-practice'),Model.Document.GetValue<string>('input_fingerprint'));
        HTML:=TFile.ReadAllText(TPath.Combine(Work,'shared-practice\learning.html'),TEncoding.UTF8);
        Check(ContainsText(HTML,'First day') and ContainsText(HTML,'Meet the practice application') and ContainsText(HTML,'class="callout"'),'Shared practice includes the learning path, tasks and anchored pictures');
       finally Model.Free;end;
      finally Rows.Free;Images.Free;end;
     finally View.Free;end;
    finally Store.Free;end;
    for Pair in Pack.GetValue<TJSONObject>('source_hashes') do Check(THashSHA2.GetHashStringFromFile(TPath.Combine(Root,'samples\OrderPractice\'+Pair.JsonString.Value))=Pair.JsonValue.Value,'Practice source/picture unchanged: '+Pair.JsonString.Value);
   finally Pack.Free;end;
   Report:=TJSONObject.Create;try Report.AddPair('checks',TJSONNumber.Create(Checks)).AddPair('result','PASS').AddPair('independent_beginner_acceptance','not performed');TFile.WriteAllText(TPath.Combine(Root,'docs\validation\reports\learning-completion-practice-validation.json'),Report.Format(2),TEncoding.UTF8);finally Report.Free;end;
  except on E:Exception do begin Writeln(E.ClassName,': ',E.Message);ExitCode:=1;end;end;
 finally CoUninitialize;end;
end.
