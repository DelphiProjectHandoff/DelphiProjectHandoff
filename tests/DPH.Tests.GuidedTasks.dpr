program DPH.Tests.GuidedTasks;
{$APPTYPE CONSOLE}
uses System.SysUtils,System.Classes,System.IOUtils,System.JSON,System.Hash,System.StrUtils,System.Diagnostics,System.UITypes,
  Winapi.ActiveX,FMX.Forms,FMX.Graphics,
  DPH.UI.Main in '..\DPH.UI.Main.pas',
  DPH.Analysis.Explanations in '..\DPH.Analysis.Explanations.pas',
  DPH.Workspace.Model in '..\DPH.Workspace.Model.pas',DPH.Storage.Database in '..\DPH.Storage.Database.pas',
  DPH.Project.Analysis in '..\DPH.Project.Analysis.pas',DPH.Analysis.Symbols in '..\DPH.Analysis.Symbols.pas',
  DPH.Analysis.Model in '..\DPH.Analysis.Model.pas',DPH.Analysis.Persistence in '..\DPH.Analysis.Persistence.pas',
  DPH.Publish.Model in '..\DPH.Publish.Model.pas',DPH.Publish.Export in '..\DPH.Publish.Export.pas';
var Root,Fixture,Database,HashBefore,Body,Key:string;Store:TDPHKnowledgeStore;Analyzer:TDPHAnalyzer;Semantic:TDPHSemanticAnalyzer;
 Scan:TDPHScan;Graph:TDPHSemanticGraph;View:TDPHWorkspaceView;Config,Generation,LessonID,Revision:Int64;
 Lesson,Fields,R,Report:TJSONObject;Rows,Pictures:TJSONArray;V:TJSONValue;Checks:Integer;Failed:Boolean;Form:TDPHMainForm;Watch:TStopwatch;Bitmap:TBitmap;Publication:TDPHDocumentModel;PicturePath,PictureHash:string;
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
    Lesson:=TDPHWorkspaceView.NewLearningCard;
    try
     Failed:=False;try TDPHWorkspaceView.ValidateLearningCard(Lesson);except Failed:=True;end;Check(Failed,'An empty teaching template cannot masquerade as an explanation');
     Fields:=Lesson.GetValue<TJSONObject>('fields');Fields.RemovePair('name').Free;Fields.AddPair('name','Storage negative control');Fields.RemovePair('meaning').Free;Fields.AddPair('meaning','A real explanation is required.');
     Body:=TDPHWorkspaceView.LearningCardBody(Lesson);
     Failed:=False;try Store.SaveKnowledge(0,0,Generation,'Storage negative control','Contradictory body','Named contributor','user_help','','user','all','','',Lesson.ToJSON);except Failed:=True;end;Check(Failed,'Saved teaching prose cannot contradict its structured fields');
     Failed:=False;try Store.SaveKnowledge(0,0,Generation,'Storage negative control',Body,'Unknown','user_help','','user','all','','',Lesson.ToJSON);except Failed:=True;end;Check(Failed,'Teaching explanations require a named contributor');
     Lesson.AddPair('picture',TJSONObject.Create.AddPair('image_sha256',StringOfChar('f',64)).AddPair('x',TJSONNumber.Create(5000)).AddPair('y',TJSONNumber.Create(5000)));
     Body:=TDPHWorkspaceView.LearningCardBody(Lesson);
     Failed:=False;try Store.SaveKnowledge(0,0,Generation,'Storage negative control',Body,'Named contributor','user_help','','user','all','','',Lesson.ToJSON);except Failed:=True;end;Check(Failed,'A callout cannot refer to a picture outside the selected application');
     Lesson.GetValue<TJSONObject>('picture').RemovePair('x').Free;Lesson.GetValue<TJSONObject>('picture').AddPair('x',TJSONNumber.Create(10001));
     Failed:=False;try TDPHWorkspaceView.ValidateLearningCard(Lesson);except Failed:=True;end;Check(Failed,'A callout outside the picture bounds is rejected');
    finally Lesson.Free;end;
    PicturePath:=TPath.Combine(ExtractFileDir(Database),'sample-output.png');Bitmap:=TBitmap.Create(320,200);
    try Bitmap.Clear(TAlphaColors.Lightblue);Bitmap.SaveToFile(PicturePath);finally Bitmap.Free;end;
    PictureHash:=THashSHA2.GetHashStringFromFile(PicturePath);
    Store.ImportScreenshot(Generation,PicturePath,'Fixture image contributor','Synthetic teaching image for callout testing; not an application screenshot.','','Sample output');
   finally Store.Free;Semantic.Free;Analyzer.Free;end;
   Form:=TDPHMainForm.Create(nil);
   try
    Check(not Form.WorkspaceTabs.Enabled,'Project opening protects lesson drafts until the candidate is accepted');
    Form.ChangeTimer.Enabled:=False;Form.Show;Form.WorkspaceTabs.ActiveTab:=Form.TaskTab;WaitForTask('Initial task');
    Check(Form.WorkspaceTabs.Enabled,'Accepted project restores normal lesson interaction');
    Form.TaskList.ItemIndex:=Form.TaskList.Items.IndexOf('Initial task');Form.TaskSelectionChange(nil);
    Check(ContainsText(Form.TaskActionMemo.Text,'Open the responding operation'),'Learner reads the actual supplied first action');
    Check(ContainsText(Form.TaskResultMemo.Text,'Its explanation appears'),'Learner sees the expected result beside the action');
    Form.TaskList.ItemIndex:=Form.TaskList.Items.IndexOf('Legacy instructions');Form.TaskSelectionChange(nil);
    Check(ContainsText(Form.TaskActionMemo.Text,'Original free-text') and not Form.TaskNext.Enabled,'Legacy text remains readable without fabricated step boundaries');
    Check((Form.FindComponent('Tutor_name')<>nil) and (Form.TutorSteps<>nil) and (Form.TutorAuthor<>nil),'Task editor controls are serialized in the native form');
    Form.SetupClick(nil);Form.TaskEditClick(Form.SetupTaskButton);
    Check(Form.WorkspaceTabs.ActiveTab=Form.TaskEditorTab,'Prepare lessons opens a real new task draft');
    Form.Tutor_name.Text:='Choose an option';Form.Tutor_purpose.Text:='Learn the two alternatives in an event handler';
    Form.Tutor_prerequisites.Text:='Use the supplied example source';Form.Tutor_expected_result.Text:='Explain the true and false alternatives';
    Form.Tutor_troubleshooting.Text:='Ask the author if the handler cannot be found';Form.Tutor_practice.Text:='Explain which path is taken when Sender is zero';Form.TutorAuthor.Text:='Learning instructor';
    Form.TutorRole.Text:='New operator';Form.TutorPath.Text:='First day';Form.TutorOrder.Text:='2';
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
     Bitmap.SaveToFile(TPath.Combine(Root,'docs\validation\images\guided-tasks-reader-compact.png'));finally Bitmap.Free;end;
    Form.ClientWidth:=1400;Form.ClientHeight:=850;Application.ProcessMessages;
    Bitmap:=TBitmap.Create(Form.ClientWidth,Form.ClientHeight);try
     if Bitmap.Canvas.BeginScene then try Form.PaintTo(Bitmap.Canvas);finally Bitmap.Canvas.EndScene;end;
     Bitmap.SaveToFile(TPath.Combine(Root,'docs\validation\images\guided-tasks-reader.png'));finally Bitmap.Free;end;
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
     Bitmap.SaveToFile(TPath.Combine(Root,'docs\validation\images\guided-tasks-preparation.png'));finally Bitmap.Free;end;
    Form.TaskSaveClick(nil);WaitForTask('Choose an option',True);
    Check(ContainsText(Form.TaskContextMemo.Text,'Learn to follow a real event handler') and (Form.TaskActionMemo.Text='Open the Click operation explanation'),'Edited purpose and reordered steps persist together');
    Check(ContainsText(Form.TaskContextMemo.Text,'New operator') and ContainsText(Form.TaskContextMemo.Text,'First day'),'Saved role and learning path accompany the actual instructions');
    Form.TaskLearner.Text:='Fixture learner';Form.TaskSelectionChange(nil);
    Check(Form.TaskCheckStep.Enabled,'A named learner can check the first result');
    Form.TaskProgressClick(Form.TaskCheckStep);
    Check(ContainsText(Form.TaskProgressLabel.Text,'1 of 2') and (Form.TaskStepLabel.Text='Step 2 of 2'),'Checking a result saves progress and moves to the next real step');
    Form.TaskSelectionChange(nil);Check(Form.TaskStepLabel.Text='Step 2 of 2','Returning to a task resumes the unchecked step');
    Form.TaskProgressClick(Form.TaskCheckStep);Check(ContainsText(Form.TaskProgressLabel.Text,'2 of 2') and not Form.TaskCheckStep.Enabled,'Every result must be checked before task completion');
    Form.TaskProgressClick(Form.TaskResetProgress);Check(ContainsText(Form.TaskProgressLabel.Text,'0 of 2'),'Clear my progress resets this learner without changing instructions');
    Form.TaskRoleFilter.Text:='Other role';Form.TaskFilterChange(nil);Check(Form.TaskList.Items.IndexOf('Choose an option')<0,'Role filter excludes instructions for another named role');
    Form.TaskRoleFilter.Text:='New operator';Form.TaskFilterChange(nil);Check(Form.TaskList.Items.IndexOf('Choose an option')>=0,'Role filter retains this role instructions');
    Form.TaskRoleFilter.Text:='';Form.TaskPathFilter.Text:='First day';Form.TaskFilterChange(nil);Check(Form.TaskList.Count=1,'Learning path selects only its assigned task');
    Form.TaskPathFilter.Text:='';Form.TaskFilterChange(nil);Form.TaskList.ItemIndex:=Form.TaskList.Items.IndexOf('Choose an option');Form.TaskSelectionChange(nil);
    Form.TaskEditClick(Form.TaskEdit);Form.TutorSteps.ItemIndex:=0;Form.TutorStepSelection(nil);
    Check(Form.TutorAction.Text='Open the Click operation explanation','Reopening the saved revision restores the replacement step');
    Form.TaskCancelClick(nil);
    Form.CardEditClick(Form.CardNew);
    Check(Form.WorkspaceTabs.ActiveTab=Form.CardEditorTab,'Teaching library opens an IDE-editable explanation form');
    Form.CardCategory.ItemIndex:=Form.CardCategory.Items.IndexOf('Field');
    Form.Card_name.Text:='Choosing a mode';Form.Card_role.Text:='New operator';Form.Card_meaning.Text:='The mode changes which processing path is selected.';
    Form.Card_example.Text:='Ask the author for a safe example mode; the fixture uses Sender.';Form.Card_limits.Text:='Do not assume a button caption establishes its whole purpose.';
    Form.Card_help.Text:='If no handler is found, ask the author to identify it.';Form.Card_practice.Text:='Which operation responds? Expected: the saved Click handler.';Form.CardAuthor.Text:='Learning instructor';
    Form.CardSaveClick(nil);Watch:=TStopwatch.StartNew;
    repeat Form.PollTimerTimer(nil);Application.ProcessMessages;TThread.Sleep(15);
    until ((Form.WorkspaceTabs.ActiveTab=Form.CardLibraryTab) and (Form.CardList.Count>0)) or (Watch.ElapsedMilliseconds>20000);
    Check((Form.WorkspaceTabs.ActiveTab=Form.CardLibraryTab) and ContainsText(Form.CardReader.Text,'mode changes'),'One Save explanation persists the real fields and returns to the learner');
    Check(ContainsText(Form.CardReader.Text,'Learning instructor') and ContainsText(Form.CardReader.Text,'needs review'),'A teaching card retains contributor and pending review in plain language');
    Form.CardRole.Text:='Different role';Form.CardFilterChange(nil);Check(Form.CardList.Count=0,'Teaching library filters role-specific explanations');
    Form.CardRole.Text:='';Form.CardFilter.Text:='saved Click handler';Form.CardFilterChange(nil);Check(Form.CardList.Count=1,'Teaching library searches examples and expected answers as well as titles');
    Form.CardEditClick(Form.CardEdit);Check(Form.Card_example.Text='Ask the author for a safe example mode; the fixture uses Sender.','Reopening a card restores its actual saved example');Form.CardCancelClick(nil);
    Check(Form.ScreenshotList.Count=1,'Saved sample output opens with the selected application');
    Form.WorkspaceTabs.ActiveTab:=Form.ScreenshotTab;Form.ScreenshotList.ItemIndex:=0;Form.ScreenshotClick(nil);
    Check(ContainsText(Form.ScreenshotEvidence.Text,'Sample output') and not ContainsText(Form.ScreenshotEvidence.Text,'SHA256'),'Learner sees the sample purpose rather than a fingerprint dump');
    Form.ScreenshotPoint(Form.ScreenshotImage,TMouseButton.mbLeft,[],Form.ScreenshotImage.Width/2,Form.ScreenshotImage.Height/2);
    Form.ScreenshotCalloutClick(nil);Check((Form.WorkspaceTabs.ActiveTab=Form.CardEditorTab) and (Form.CardCategory.Selected.Text='Output or report'),'A selected picture point opens its real output explanation draft');
    Form.Card_name.Text:='Reading the sample total';Form.Card_role.Text:='All learners';Form.Card_meaning.Text:='This marked point represents the result the learner should check.';
    Form.Card_example.Text:='This synthetic blue image tests the teaching overlay; it is not a customer report.';Form.Card_limits.Text:='No financial meaning is inferred from this fixture.';
    Form.Card_help.Text:='Ask the application author for a real sample and its interpretation.';Form.Card_practice.Text:='What must be checked? Expected: the documented result at the marked point.';Form.CardAuthor.Text:='Callout contributor';
    Form.CardSaveClick(nil);Watch:=TStopwatch.StartNew;
    repeat Form.PollTimerTimer(nil);Application.ProcessMessages;TThread.Sleep(15);
    until ((Form.WorkspaceTabs.ActiveTab=Form.CardLibraryTab) and ContainsText(Form.CardReader.Text,'marked point represents')) or (Watch.ElapsedMilliseconds>20000);
    Check(ContainsText(Form.CardReader.Text,'marked point represents'),'The anchored explanation is saved through the actual background pipeline');
    Form.WorkspaceTabs.ActiveTab:=Form.ScreenshotTab;Form.ScreenshotClick(nil);Application.ProcessMessages;
    Check(ContainsText(Form.ScreenshotEvidence.Text,'1. Reading the sample total') and ContainsText(Form.ScreenshotEvidence.Text,'Callout contributor'),'Picture legend presents the numbered meaning and actual contributor');
    Check(THashSHA2.GetHashStringFromFile(PicturePath)=PictureHash,'Anchored callouts leave original picture bytes unchanged');
    Bitmap:=TBitmap.Create(Form.ClientWidth,Form.ClientHeight);try if Bitmap.Canvas.BeginScene then try Form.PaintTo(Bitmap.Canvas);finally Bitmap.Canvas.EndScene;end;Bitmap.SaveToFile(TPath.Combine(Root,'docs\validation\images\guided-tasks-callouts.png'));finally Bitmap.Free;end;
    Form.Hide;
   finally Form.Free;end;
   Store:=TDPHKnowledgeStore.Create(Database,Fixture,TPath.Combine(Root,'migrations'));
   try
    View:=TDPHWorkspaceView.Create(TJSONObject.ParseJSONValue(Store.LoadWorkspaceView) as TJSONObject);
    try Rows:=Store.KnowledgeJSON;
     try Pictures:=Store.ScreenshotsJSON;
      try Publication:=TDPHDocumentModel.Create(View,Rows,[],[],False,False,Pictures);finally Pictures.Free;end;
      try TDPHPublisher.Export(Publication,Store,TPath.Combine(ExtractFileDir(Database),'learning-edition'));
       TDPHPublisher.Validate(TPath.Combine(ExtractFileDir(Database),'learning-edition'),Publication.Document.GetValue<string>('input_fingerprint'));
       Body:=TFile.ReadAllText(TPath.Combine(ExtractFileDir(Database),'learning-edition\learning.html'),TEncoding.UTF8);
       Check(ContainsText(Body,'Open the Click operation explanation') and ContainsText(Body,'Learn to follow a real event handler'),'Sharing preserves the saved task revision and its purpose');
       Check(ContainsText(Body,'<ol><li><p>Open the Click operation explanation') and ContainsText(Body,'Expected after step 2:'),'Offline tasks contain real ordered steps and per-step expected results');
       Check(ContainsText(Body,'Practice:') and ContainsText(Body,'Expected final result:') and ContainsText(Body,'Learning instructor'),'Offline task retains practice, final result and named contributor');
       Check(not ContainsText(Body,'href="#task_reader"') and ContainsText(Body,'In DPH, Learn a task also'),'Offline instructions distinguish the read-only edition from the native step reader');
       Check(ContainsText(Body,'Field: Choosing a mode') and ContainsText(Body,'Expected: the saved Click handler.'),'Shared lessons contain the same teaching card and expected practice answer');
       Check(ContainsText(Body,'class="callout" style="left:50%;top:50%">1') and ContainsText(Body,'Sample output:'),'Shared edition preserves the anchored point and the supplied image kind');
       Check(ContainsText(Body,'Callout contributor') and ContainsText(Body,'This synthetic blue image'),'Picture callout legend keeps attribution and the actual worked example');
       var OrderedFacts:=Publication.Document.Clone as TJSONObject;
       try
        for var OrderedRow in OrderedFacts.GetValue<TJSONArray>('knowledge') do begin
         var OrderedRecord:=OrderedRow.GetValue<TJSONObject>('structured_record',nil);
         if (OrderedRecord=nil) or (OrderedRecord.GetValue<string>('record_type','')<>'learning_lesson') then Continue;
         OrderedRecord.RemovePair('learning').Free;
         var LessonPosition:=9;if OrderedRow.GetValue<string>('title')='Choose an option' then LessonPosition:=1;
         OrderedRecord.AddPair('learning',TJSONObject.Create.AddPair('role','All learners').AddPair('path','Ordering check').AddPair('order',TJSONNumber.Create(LessonPosition)));
        end;
        var OrderedExplain:=TDPHExplanationModel.Create(OrderedFacts);
        try Body:=OrderedExplain.LessonHTML(11);
         Check((Pos('<h3>Choose an option</h3>',Body)>0) and (Pos('<h3>Choose an option</h3>',Body)<Pos('<h3>Initial task</h3>',Body)),'Shared tasks honor prepared learning-path order rather than creation order');
        finally OrderedExplain.Free;end;
       finally OrderedFacts.Free;end;
      finally Publication.Free;end;
     finally Rows.Free;end;
    finally View.Free;end;
   finally Store.Free;end;
   Check(THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'Main.pas'))=HashBefore,'Selected application source remains unchanged');
   Report:=TJSONObject.Create;try Report.AddPair('checks',TJSONNumber.Create(Checks));Report.AddPair('result','PASS');Report.AddPair('independent_learner_acceptance','not performed');TFile.WriteAllText(TPath.Combine(Root,'docs\validation\reports\guided-tasks-validation.json'),Report.Format(2),TEncoding.UTF8);finally Report.Free;end;
   Writeln('PASS guided task learning: ',Checks,' checks');
  except on E:Exception do begin Writeln(E.ClassName,': ',E.Message);ExitCode:=1;end;end;
 finally CoUninitialize;end;
end.
