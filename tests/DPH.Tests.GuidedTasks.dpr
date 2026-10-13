program DPH.Tests.GuidedTasks;
{$APPTYPE CONSOLE}
uses System.SysUtils,System.Classes,System.IOUtils,System.JSON,System.Hash,System.StrUtils,System.Diagnostics,System.UITypes,
  Winapi.ActiveX,FMX.Forms,FMX.Graphics,
  DPH.UI.Main in '..\DPH.UI.Main.pas',
  DPH.Workspace.Model in '..\DPH.Workspace.Model.pas',DPH.Storage.Database in '..\DPH.Storage.Database.pas',
  DPH.Project.Analysis in '..\DPH.Project.Analysis.pas',DPH.Analysis.Symbols in '..\DPH.Analysis.Symbols.pas',
  DPH.Analysis.Model in '..\DPH.Analysis.Model.pas',DPH.Analysis.Persistence in '..\DPH.Analysis.Persistence.pas';
var Root,Fixture,Database,HashBefore,Body,Key:string;Store:TDPHKnowledgeStore;Analyzer:TDPHAnalyzer;Semantic:TDPHSemanticAnalyzer;
 Scan:TDPHScan;Graph:TDPHSemanticGraph;View:TDPHWorkspaceView;Config,Generation,LessonID,Revision:Int64;
 Lesson,Fields,R,Report:TJSONObject;Rows:TJSONArray;V:TJSONValue;Checks:Integer;Failed:Boolean;Form:TDPHMainForm;Watch:TStopwatch;Bitmap:TBitmap;
procedure Check(OK:Boolean;const MessageText:string);
begin if not OK then raise Exception.Create('FAIL '+MessageText);Inc(Checks);Writeln('PASS ',Checks,': ',MessageText);Flush(Output);end;
procedure WaitForTask(const Name:string;Saving:Boolean=False);
begin
 Watch:=TStopwatch.StartNew;
 repeat Form.PollTimerTimer(nil);Application.ProcessMessages;TThread.Sleep(15);
 until ((Form.TaskList.Items.IndexOf(Name)>=0) and (not Saving or (Form.TaskEditorScroll.Enabled and (Form.WorkspaceTabs.ActiveTab=Form.TaskTab)))) or (Watch.ElapsedMilliseconds>20000);
 Check((Form.TaskList.Items.IndexOf(Name)>=0) and (not Saving or (Form.TaskEditorScroll.Enabled and (Form.WorkspaceTabs.ActiveTab=Form.TaskTab))),'Saved task is returned through the actual background save/open pipeline: '+Name+' / '+Form.StatusLabel.Text);
end;
begin
 CoInitialize(nil);Application.Initialize;
 try
  try
   Database:=ParamStr(1);Root:=TPath.GetFullPath(ParamStr(2));Fixture:=TPath.Combine(Root,'tests\fixtures\semantics');
   HashBefore:=THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'Main.pas'));
   Analyzer:=TDPHAnalyzer.Create;Semantic:=TDPHSemanticAnalyzer.Create;Store:=TDPHKnowledgeStore.Create(Database,Fixture,TPath.Combine(Root,'migrations'));
   try
    Store.InitializeProject('Guided task test fixture','Delphi');Config:=Store.AddConfiguration('Win32','37.0','[]','[]','Debug');Store.SelectConfiguration(Config);
    Scan:=Analyzer.Scan(TPath.Combine(Fixture,'Semantic.dproj'),'Debug','Win32',[],[]);
    try Graph:=Semantic.Analyze(Scan);
     try Generation:=TDPHSemanticPersistence.Stage(Scan,Graph,Store,Config);
      View:=TDPHWorkspaceView.Create(TDPHWorkspaceView.Capture(Scan,Graph,Generation,'Semantic.dproj','Debug','Win32',[],[]));
      try Store.SaveWorkspaceView(Generation,View.Document.ToJSON);finally View.Free;end;
      TDPHSemanticPersistence.Publish(Scan,Graph,Store,Generation);
     finally Graph.Free;end;
    finally Scan.Free;end;
    Lesson:=TDPHWorkspaceView.NewLearningLesson;
    try
     Failed:=False;try TDPHWorkspaceView.ValidateLearningLesson(Lesson);except Failed:=True;end;
     Check(Failed,'A blank template cannot masquerade as task instructions');
     Fields:=Lesson.GetValue<TJSONObject>('fields');Fields.RemovePair('name').Free;Fields.AddPair('name','Initial task');Fields.RemovePair('purpose').Free;Fields.AddPair('purpose','Learn to read a source branch');
     Lesson.GetValue<TJSONArray>('steps').AddElement(TJSONObject.Create.AddPair('action','Open the responding operation').AddPair('expected_result','Its explanation appears'));
     TDPHWorkspaceView.ValidateLearningLesson(Lesson);Check(True,'A task needs an explicit purpose and a real action');
     Body:=TDPHWorkspaceView.LearningLessonBody(Lesson);Check(ContainsText(Body,'Expected after this step: Its explanation appears'),'Canonical instructions preserve the action and expected outcome');
     LessonID:=Store.SaveKnowledge(0,0,Generation,'Initial task',Body,'Task author','user_help','','user','all','','',Lesson.ToJSON);
     Rows:=Store.KnowledgeJSON;try R:=Rows.Items[0] as TJSONObject;Revision:=R.GetValue<Int64>('revision');Check(TDPHWorkspaceView.IsLearningLesson(R),'SQLite returns the saved typed lesson');finally Rows.Free;end;
     Failed:=False;try Store.SaveKnowledge(LessonID,Revision,Generation,'Initial task','Different text','Task author','user_help','','user','all','','',Lesson.ToJSON);except Failed:=True;end;
     Check(Failed,'Free-text edits cannot silently contradict the structured instructions');
     Failed:=False;try Store.SaveKnowledge(0,0,Generation,'Initial task',Body,'Other author','user_help','','user','all','','',Lesson.ToJSON);except Failed:=True;end;
     Check(Failed,'A task cannot be duplicated under the same identity');
     Failed:=False;try Store.SaveKnowledge(LessonID,Revision,Generation,'Initial task',Body,'Unknown','user_help','','user','all','','',Lesson.ToJSON);except Failed:=True;end;
     Check(Failed,'Task contribution requires a named person');
     (Lesson.GetValue<TJSONArray>('steps').Items[0] as TJSONObject).RemovePair('action').Free;
     Failed:=False;try TDPHWorkspaceView.ValidateLearningLesson(Lesson);except Failed:=True;end;
     Check(Failed,'Incomplete step structure is rejected');
    finally Lesson.Free;end;
    Store.SaveKnowledge(0,0,Generation,'Legacy instructions','Original free-text operating instructions.','Original author','user_help','');
   finally Store.Free;Semantic.Free;Analyzer.Free;end;
   Form:=TDPHMainForm.Create(nil);
   try
    Form.ChangeTimer.Enabled:=False;Form.Show;Form.WorkspaceTabs.ActiveTab:=Form.TaskTab;WaitForTask('Initial task');
    Form.TaskList.ItemIndex:=Form.TaskList.Items.IndexOf('Initial task');Form.TaskSelectionChange(nil);
    Check(ContainsText(Form.TaskActionMemo.Text,'Open the responding operation'),'Learner reads the actual supplied first action');
    Check(ContainsText(Form.TaskResultMemo.Text,'Its explanation appears'),'Learner sees the expected result beside the action');
    Form.TaskList.ItemIndex:=Form.TaskList.Items.IndexOf('Legacy instructions');Form.TaskSelectionChange(nil);
    Check(ContainsText(Form.TaskActionMemo.Text,'Original free-text') and not Form.TaskNext.Enabled,'Legacy text remains readable without fabricated step boundaries');
    Check((Form.FindComponent('Tutor_name')<>nil) and (Form.TutorSteps<>nil) and (Form.TutorAuthor<>nil),'Task editor controls are serialized in the native form');
    Form.TaskEditClick(Form.TaskNew);
    Form.Tutor_name.Text:='Choose an option';Form.Tutor_purpose.Text:='Learn the two alternatives in an event handler';
    Form.Tutor_prerequisites.Text:='Use the supplied example source';Form.Tutor_expected_result.Text:='Explain the true and false alternatives';
    Form.Tutor_troubleshooting.Text:='Ask the author if the handler cannot be found';Form.Tutor_practice.Text:='Explain which path is taken when Sender is zero';Form.TutorAuthor.Text:='Learning instructor';
    Form.TutorAction.Text:='Find the Click operation';Form.TutorExpected.Text:='The operation explanation opens';Form.TutorStepAction(Form.TutorKeepStep);
    Form.TutorStepAction(Form.TutorNewStep);Form.TutorAction.Text:='Read the Sender > 0 condition';Form.TutorExpected.Text:='Identify both alternatives';Form.TutorStepAction(Form.TutorKeepStep);
    Check(Form.TutorSteps.Count=2,'Native preparation retains two explicitly authored steps');
    Form.TaskSaveClick(nil);Check(not Form.TaskEditorScroll.Enabled,'An in-flight save protects the supplied instructions from lost edits');
    WaitForTask('Choose an option',True);Check(Form.WorkspaceTabs.ActiveTab=Form.TaskTab,'One Save task returns directly to the learner');
    Check((Form.TaskStepLabel.Text='Step 1 of 2') and ContainsText(Form.TaskActionMemo.Text,'Find the Click'),'Saved task starts with its first step');
    Form.TaskNavigate(Form.TaskNext);Check((Form.TaskStepLabel.Text='Step 2 of 2') and ContainsText(Form.TaskResultMemo.Text,'Explain the true and false alternatives'),'Last step shows the overall expected result');
    Check(not Form.TaskNext.Enabled and Form.TaskPrevious.Enabled,'Reader prevents moving beyond the last step');
    Form.TaskNavigate(Form.TaskPrevious);Check(Form.TaskStepLabel.Text='Step 1 of 2','Learner can return to the earlier action');
    Form.TaskNavigate(Form.TaskNext);Form.TaskNavigate(Form.TaskRestart);Check(Form.TaskStepLabel.Text='Step 1 of 2','Start again resets the learning sequence');
    Form.WindowState:=TWindowState.wsNormal;Form.ClientWidth:=960;Form.ClientHeight:=600;Application.ProcessMessages;
    Check(not Form.ExplorerLayout.Visible and not Form.InspectorLayout.Visible,'Task reader has no unrelated technical side panels');
    Bitmap:=TBitmap.Create(Form.ClientWidth,Form.ClientHeight);try
     if Bitmap.Canvas.BeginScene then try Form.PaintTo(Bitmap.Canvas);finally Bitmap.Canvas.EndScene;end;
     Bitmap.SaveToFile(TPath.Combine(Root,'docs\guided-tasks-reader-compact.png'));finally Bitmap.Free;end;
    Form.ClientWidth:=1400;Form.ClientHeight:=850;Application.ProcessMessages;
    Bitmap:=TBitmap.Create(Form.ClientWidth,Form.ClientHeight);try
     if Bitmap.Canvas.BeginScene then try Form.PaintTo(Bitmap.Canvas);finally Bitmap.Canvas.EndScene;end;
     Bitmap.SaveToFile(TPath.Combine(Root,'docs\guided-tasks-reader.png'));finally Bitmap.Free;end;
    Form.TaskEditClick(Form.TaskEdit);Check(Form.TutorSteps.Count=2,'Reopening instructions restores their ordered steps');
    Form.Tutor_purpose.Text:='Revised learning purpose';Form.TaskCancelClick(nil);Check(Form.WorkspaceTabs.ActiveTab=Form.TaskTab,'Cancel returns to learning without saving a replacement');
    Form.TaskSelectionChange(nil);Check(ContainsText(Form.TaskContextMemo.Text,'Learn the two alternatives'),'Canceled edits preserve the stored purpose');
    Form.TaskEditClick(Form.TaskEdit);
    Check(Form.Tutor_name.ReadOnly,'Editing preserves the saved task identity');
    Form.TutorSteps.ItemIndex:=0;Form.TutorStepSelection(nil);Form.TutorAction.Text:='Open the Click operation explanation';Form.TutorStepAction(Form.TutorKeepStep);
    Check(ContainsText(Form.TutorSteps.Items[0],'Open the Click'),'Replacing a step keeps the replacement in its original position');
    Form.TutorStepAction(Form.TutorStepDown);Check(ContainsText(Form.TutorSteps.Items[1],'Open the Click'),'Moving a step down preserves both instructions');
    Form.TutorStepAction(Form.TutorStepUp);Check(ContainsText(Form.TutorSteps.Items[0],'Open the Click'),'Moving a step up restores the order');
    Form.TutorStepAction(Form.TutorNewStep);Form.TutorAction.Text:='Temporary practice step';Form.TutorExpected.Text:='Temporary result';Form.TutorStepAction(Form.TutorKeepStep);
    Form.TutorStepAction(Form.TutorRemoveStep);Check(Form.TutorSteps.Count=2,'Removing a step preserves the other steps');
    Form.TutorSteps.ItemIndex:=0;Form.TutorStepSelection(nil);Form.TutorAction.Text:='Unkept edit';Form.TutorStepAction(Form.TutorDiscardStep);
    Check(Form.TutorAction.Text='Open the Click operation explanation','Undo step restores the kept action');
    Form.Tutor_purpose.Text:='Learn to follow a real event handler';
    Bitmap:=TBitmap.Create(Form.ClientWidth,Form.ClientHeight);try
     if Bitmap.Canvas.BeginScene then try Form.PaintTo(Bitmap.Canvas);finally Bitmap.Canvas.EndScene;end;
     Bitmap.SaveToFile(TPath.Combine(Root,'docs\guided-tasks-preparation.png'));finally Bitmap.Free;end;
    Form.TaskSaveClick(nil);WaitForTask('Choose an option',True);
    Check(ContainsText(Form.TaskContextMemo.Text,'Learn to follow a real event handler') and (Form.TaskActionMemo.Text='Open the Click operation explanation'),'Edited purpose and reordered steps persist together');
    Form.TaskEditClick(Form.TaskEdit);Form.TutorSteps.ItemIndex:=0;Form.TutorStepSelection(nil);
    Check(Form.TutorAction.Text='Open the Click operation explanation','Reopening the saved revision restores the replacement step');
    Form.TaskCancelClick(nil);
    Form.Hide;
   finally Form.Free;end;
   Check(THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'Main.pas'))=HashBefore,'Selected application source remains unchanged');
   Report:=TJSONObject.Create;try Report.AddPair('checks',TJSONNumber.Create(Checks));Report.AddPair('result','PASS');Report.AddPair('independent_learner_acceptance','not performed');TFile.WriteAllText(TPath.Combine(Root,'docs\guided-tasks-validation.json'),Report.Format(2),TEncoding.UTF8);finally Report.Free;end;
   Writeln('PASS guided task learning: ',Checks,' checks');
  except on E:Exception do begin Writeln(E.ClassName,': ',E.Message);ExitCode:=1;end;end;
 finally CoUninitialize;end;
end.
