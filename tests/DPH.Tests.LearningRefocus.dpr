program DPH.Tests.LearningRefocus;
{$APPTYPE CONSOLE}
{$SETPEFLAGS $20}
uses System.SysUtils, System.Classes, System.IOUtils, System.JSON, System.Hash, System.StrUtils, System.Diagnostics, System.Types, System.Generics.Collections, System.Math.Vectors, System.Zip,
  Winapi.ActiveX, FMX.Forms, FMX.Graphics, FMX.WebBrowser, System.UITypes,
  DPH.UI.Main in '..\DPH.UI.Main.pas', DPH.Storage.Database in '..\DPH.Storage.Database.pas',
  DPH.Workspace.Model in '..\DPH.Workspace.Model.pas', DPH.Analysis.Explanations in '..\DPH.Analysis.Explanations.pas',
  DPH.Publish.Model in '..\DPH.Publish.Model.pas', DPH.Publish.Export in '..\DPH.Publish.Export.pas',
  DPH.Publish.BrowserPolicy in '..\DPH.Publish.BrowserPolicy.pas',
  DPH.Project.Analysis in '..\DPH.Project.Analysis.pas', DPH.Analysis.Symbols in '..\DPH.Analysis.Symbols.pas',
  DPH.Workspace.Worker in '..\DPH.Workspace.Worker.pas',
  DPH.Learning.Discovery in '..\DPH.Learning.Discovery.pas',
  DPH.UI.ActionPurpose in '..\DPH.UI.ActionPurpose.pas', DPH.Knowledge.ActionPurpose in '..\DPH.Knowledge.ActionPurpose.pas',
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
      Root:=TPath.GetFullPath(ParamStr(1)); CreateGUID(ID); Work:=TPath.Combine(Root,'bin\learning-refocus-tests-'+GUIDToString(ID)); TDirectory.CreateDirectory(Work);
      TFile.WriteAllText(TPath.Combine(Work,'README.md'),'The learning fixture has a documented first task.',TEncoding.UTF8);
      TFile.WriteAllText(TPath.Combine(Work,'Setup_Notes.txt'),
        'The Unicode setup note explains the first screen.',TEncoding.Unicode);
      TFile.WriteAllText(TPath.Combine(Work,'Miscellaneous.txt'),
        'The unfamiliar application keeps another useful instruction here.',TEncoding.UTF8);
      TFile.WriteAllText(TPath.Combine(Work,'activity.log'),StringOfChar('x',1100000)+sLineBreak+
        'The Convert action completed at 10:30.',TEncoding.UTF8);
      TFile.Copy(TPath.Combine(Root,'docs\pdf\DPH_User_Guide.pdf'),
        TPath.Combine(Work,'User_Guide.pdf'));
      TFile.Copy(TPath.Combine(Root,'docs\guides\DPH_Engineering_Guide.docx'),
        TPath.Combine(Work,'Engineering_Guide.docx'));
      TFile.WriteAllText(TPath.Combine(Work,'Training_Notes.rtf'),
        '{\rtf1\ansi The test application has a saved training note.}',TEncoding.ASCII);
      var ODTContent:=TPath.Combine(Work,'content.xml');
      TFile.WriteAllText(ODTContent,
        '<office:document-content xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"><office:body><office:text><text:p>ODT learning guide explains the saved screen.</text:p></office:text></office:body></office:document-content>',TEncoding.UTF8);
      var ODTZip:=TZipFile.Create;
      try
        ODTZip.Open(TPath.Combine(Work,'Learning_Guide.odt'),zmWrite);
        ODTZip.Add(ODTContent,'content.xml');
      finally ODTZip.Free;end;
      TFile.Delete(ODTContent);
      var DiscoveryFacts:=TJSONObject.Create.AddPair('root',Work);
      try
        TDPHLearningDiscovery.AddEvidence(DiscoveryFacts,DiscoveryFacts);
        var FoundLog:=False;
        var FoundPDF:=False;
        var FoundDOCX:=False;
        var FoundRTF:=False;
        var FoundODT:=False;
        var FoundTXT:=False;
        var FoundUnlabelledTXT:=False;
        for var Discovered in DiscoveryFacts.GetValue<TJSONArray>('project_guides') do
          begin
            if SameText(Discovered.GetValue<string>('source',''),'activity.log') and
              ContainsText(Discovered.ToJSON,'Convert action completed') then FoundLog:=True;
            if SameText(Discovered.GetValue<string>('source',''),'User_Guide.pdf') and
              ContainsText(Discovered.ToJSON,'Delphi Project Handoff User Guide') then FoundPDF:=True;
            if SameText(Discovered.GetValue<string>('source',''),'Engineering_Guide.docx') and
              ContainsText(Discovered.ToJSON,'Delphi Project Handoff Engineering Guide') then FoundDOCX:=True;
            if SameText(Discovered.GetValue<string>('source',''),'Training_Notes.rtf') and
              ContainsText(Discovered.ToJSON,'saved training note') then FoundRTF:=True;
            if SameText(Discovered.GetValue<string>('source',''),'Learning_Guide.odt') and
              ContainsText(Discovered.ToJSON,'ODT learning guide') then FoundODT:=True;
            if SameText(Discovered.GetValue<string>('source',''),'Setup_Notes.txt') and
              ContainsText(Discovered.ToJSON,'Unicode setup note') then FoundTXT:=True;
            if SameText(Discovered.GetValue<string>('source',''),'Miscellaneous.txt') and
              ContainsText(Discovered.ToJSON,'another useful instruction') then FoundUnlabelledTXT:=True;
          end;
        Check(FoundLog,'Initial discovery reads existing application logs as cited evidence');
        Check(FoundPDF and FoundDOCX and FoundRTF and FoundODT and FoundTXT and FoundUnlabelledTXT,
          'PDF, DOCX, RTF, ODT and text files contribute extracted text, including unnamed notes');
      finally DiscoveryFacts.Free;end;
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
          Store.SaveKnowledge(0,0,Generation,'Unrelated project note','UNRELATED_NOTE_MUST_NOT_APPEAR','Other Author','note','');
          Store.SaveKnowledge(0,0,Generation,'Practice choosing a mode','Prerequisite: use the learning fixture.'+sLineBreak+'1. Select the example option.'+sLineBreak+'2. Read the responding operation.'+sLineBreak+'Expected result: identify both branch alternatives.','Named task author','user_help',Key);
          Rows:=Store.KnowledgeJSON;
          try Model:=TDPHDocumentModel.Create(View,Rows,[],[],False,True); finally Rows.Free; end;
          Explain:=TDPHExplanationModel.Create(Model.Document);
          try
            Check((Model.Document.GetValue<TJSONArray>('project_guides').Count>0) and
              ContainsText(Explain.ApplicationRouteHTML(0),'This example application teaches'),
              'The selected project README supplies cited app-specific orientation');
            Check(ContainsText(Explain.ProjectMapHTML,'Pascal units (.pas)') and
              ContainsText(Explain.ProjectMapHTML,'Procedures and functions') and
              ContainsText(Explain.ProjectMapHTML,'Main.pas') and
              ContainsText(Explain.ProjectMapHTML,'Example.contract.json') and
              ContainsText(Explain.ProjectMapHTML,'#open_forms'),
              'Project map groups source, a related contract and searchable objects');
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
            Check(Explain.RoutineLesson('absent-object')='', 'An absent routine cannot acquire a fabricated walkthrough');
            for I:=0 to 10 do Check(Length(Explain.TopicHTML(I))>1500,'Learning topic '+IntToStr(I)+' renders a complete offline page');
            Check(not ContainsText(Explain.ObjectHTML(Key),'UNRELATED_NOTE_MUST_NOT_APPEAR'),'Unlinked global notes do not masquerade as an object purpose');
            Check(ContainsText(Explain.ObjectLessonHTML(Key),'Fixture explanation supplied') and not ContainsText(Explain.ObjectLessonHTML(Key),'UNRELATED_NOTE_MUST_NOT_APPEAR'),'Learner explanation includes linked knowledge and excludes unrelated notes');
            Check(ContainsText(Explain.ObjectLessonHTML(Key),'<details class="card"><summary>Optional: read the code walkthrough'),'Detailed source walkthrough is optional in the learner explanation');
            FlowText:=Explain.ObjectLessonHTML(Key);FlowText:=Copy(FlowText,1,Pos('<details class="card"><summary>Optional',FlowText)-1);
            Check(ContainsText(FlowText,'Choices and stopping points') and ContainsText(FlowText,'Sender &gt; 0') and ContainsText(FlowText,'true result follows one branch'),'Beginner explanation teaches the actual branch before the optional technical walkthrough');
            for I:=0 to 11 do begin
              FlowText:=Explain.LessonHTML(I);
              Check((Length(FlowText)>1500) and not ContainsText(FlowText,'SHA256') and not ContainsText(FlowText,'confirmed_static'),'Learner topic '+IntToStr(I)+' avoids technical hash and resolution dumps');
            end;
            Check(ContainsText(Explain.LessonHTML(0),'author has not yet supplied') and not ContainsText(Explain.LessonHTML(0),'UNRELATED_NOTE_MUST_NOT_APPEAR'),'Application purpose gap is explicit without dumping unrelated records');
            Check(ContainsText(Explain.LessonHTML(2),'btnConvert') and ContainsText(Explain.LessonHTML(2),'OnClick') and ContainsText(Explain.LessonHTML(2),'Click'),'Screen lesson uses actual captured control and action binding');
            Check(ContainsText(Explain.LessonHTML(3),'responding operation') and ContainsText(Explain.LessonHTML(3),'#s_'),'Action lesson links actual event and handler');
            for I:=0 to 3 do begin
              FlowText:=Explain.ApplicationRouteHTML(I);
              Check(ContainsText(FlowText,Model.Document.GetValue<string>('project')) and
                not ContainsText(FlowText,'OrderPractice'),'Each main learning step belongs to the selected application');
            end;
            Check(ContainsText(Explain.ApplicationRouteHTML(0),'MainForm') and
              ContainsText(Explain.ApplicationRouteHTML(0),'Screens found in the saved design') and
              (Model.Document.GetValue<TJSONArray>('project_screens').Count>0),
              'App introduction lists captured form roots and their evidence');
            Check(ContainsText(Explain.ApplicationRouteHTML(1),'Start with the first labeled action') and
              ContainsText(Explain.ApplicationRouteHTML(1),'The connected code shows'),
              'The task route connects a visible control to its source relationships');
            Check(ContainsText(Explain.ApplicationRouteHTML(3),'Source traces show possible action paths'),
              'Unknowns page states the runtime limit without inventing a result');
            Check(ContainsText(Explain.ApplicationRouteHTML(2),'<title>Explore related tasks: Semantic.dproj</title>') and
              ContainsText(Explain.ApplicationRouteHTML(2),'<h1>Explore related tasks: Semantic.dproj</h1>'),
              'App-specific page title uses a plain ASCII separator');
            var GuideFacts:=Model.Document.Clone as TJSONObject;
            try
              GuideFacts.GetValue<TJSONArray>('project_screens').AddElement(
                TJSONObject.Create.AddPair('source','Extra.fmx').AddPair('source_hash','fixture-hash')
                  .AddPair('name','ExtraForm').AddPair('class','TExtraForm')
                  .AddPair('title','Extra learning screen').AddPair('line',TJSONNumber.Create(1)));
              var GuideSections:=TJSONArray.Create;
              GuideSections.AddElement(TJSONObject.Create.AddPair('heading','1. Purpose').AddPair('text','A source-supplied purpose for this application.'));
              GuideSections.AddElement(TJSONObject.Create.AddPair('heading','2. Getting started').AddPair('text','Begin with its own saved controls.'));
              GuideSections.AddElement(TJSONObject.Create.AddPair('heading','3. Convert a file').AddPair('text','Choose btnConvert on MainForm to begin the example conversion.'));
              GuideFacts.RemovePair('project_guides').Free;
              GuideFacts.AddPair('project_guides',TJSONArray.Create(
                TJSONObject.Create.AddPair('source','docs/Application_Guide.md').AddPair('sections',GuideSections)));
              var GuideModel:=TDPHExplanationModel.Create(GuideFacts);
              try
                Check(ContainsText(GuideModel.ApplicationRouteHTML(0),'A source-supplied purpose for this application.') and
                  ContainsText(GuideModel.ApplicationRouteHTML(0),'docs/Application_Guide.md'),
                  'Selected project guide supplies an attributed purpose');
                Check(ContainsText(GuideModel.ApplicationRouteHTML(0),'Extra learning screen') and
                  ContainsText(GuideModel.ApplicationRouteHTML(0),'2 saved screen design(s)'),
                  'A form design appears even when no class-link relationship was resolved');
                Check(ContainsText(GuideModel.ApplicationRouteHTML(1),'Begin with its own saved controls.') and
                  ContainsText(GuideModel.ApplicationRouteHTML(2),'Getting started'),
                  'Application guide enriches the first task and related topics');
                var ControlKey: string:='';
                for var SymbolValue in GuideFacts.GetValue<TJSONArray>('symbols') do
                  if (SymbolValue.GetValue<string>('kind','')='component') and
                    ContainsText(SymbolValue.GetValue<string>('name',''),'btnConvert') then begin
                    ControlKey:=SymbolValue.GetValue<string>('key'); Break;
                  end;
                Check(ControlKey<>'','Fixture exposes its saved Convert control');
                FlowText:=GuideModel.ObjectLessonHTML(ControlKey);
                Check(ContainsText(FlowText,'What the application documents and logs say') and
                  ContainsText(FlowText,'Choose btnConvert on MainForm') and
                  ContainsText(FlowText,'docs/Application_Guide.md'),
                  'A selected control shows its matching project-guide passage and source');
                Check(not ContainsText(FlowText,'How this lesson was prepared') and
                  not ContainsText(FlowText,'This is a saved part of a screen'),
                  'Learner page omits preparation metadata and stock control wording');
              finally GuideModel.Free;end;
            finally GuideFacts.Free;end;
            var FAQFacts:=Model.Document.Clone as TJSONObject;
            try
              var FAQRecord:=TJSONObject.Create.AddPair('title','Answer: Which task first?').AddPair('body','Begin with the supplied example option.').AddPair('owner','Named application teacher').AddPair('state','needs_review').AddPair('question_metadata',TJSONObject.Create.AddPair('prompt','Which task should a newcomer learn first?'));
              FAQFacts.GetValue<TJSONArray>('knowledge').AddElement(FAQRecord);
              var FAQModel:=TDPHExplanationModel.Create(FAQFacts);
              try
                FlowText:=FAQModel.LessonHTML(9);
                Check(ContainsText(FlowText,'Which task should a newcomer') and ContainsText(FlowText,'Begin with the supplied example option.'),'Question lesson presents the saved author reply with its actual question');
                Check(ContainsText(FlowText,'Named application teacher') and ContainsText(FlowText,'still needs review'),'Saved answer remains attributed and does not become automatically verified');
                FAQRecord.RemovePair('state').Free;FAQRecord.AddPair('state','retired');
                Check(not ContainsText(FAQModel.LessonHTML(9),'Begin with the supplied example option.'),'Retired answer is excluded from the learner questions page');
              finally FAQModel.Free;end;
            finally FAQFacts.Free;end;
            var ActionFacts:=Model.Document.Clone as TJSONObject;
            try
              var ActionFields:=TJSONObject.Create;
              for var ActionFieldName in DPHActionPurposeKeys do ActionFields.AddPair(ActionFieldName,'Unknown');
              ActionFields.RemovePair('action_id').Free;ActionFields.AddPair('action_id',TDPHActionPurpose.Identity('captured button'));
              ActionFields.RemovePair('target').Free;ActionFields.AddPair('target','captured button');
              ActionFields.RemovePair('action_name').Free;ActionFields.AddPair('action_name','Choose an option');
              ActionFields.RemovePair('purpose').Free;ActionFields.AddPair('purpose','Learn the available alternatives');
              var ActionMetadata:=TJSONObject.Create.AddPair('record_type','action_purpose').AddPair('fields',ActionFields);
              var ActionRecord:=TJSONObject.Create.AddPair('title','INTERNAL_IDENTITY_TITLE').AddPair('body','INTERNAL_IDENTITY_BODY').AddPair('entity_key',Key).AddPair('owner','Application teacher').AddPair('state','needs_review').AddPair('links',TJSONArray.Create).AddPair('structured_record',ActionMetadata);
              ActionFacts.GetValue<TJSONArray>('knowledge').AddElement(ActionRecord);
              var ActionLesson:=TDPHExplanationModel.Create(ActionFacts);
              try
                FlowText:=ActionLesson.ObjectLessonHTML(Key);FlowText:=Copy(FlowText,1,Pos('<details class="card"><summary>Optional',FlowText)-1);
                Check(ContainsText(FlowText,'Choose an option') and ContainsText(FlowText,'Learn the available alternatives'),'Linked purpose explains the action name and user goal');
                Check(not ContainsText(FlowText,'INTERNAL_IDENTITY') and not ContainsText(FlowText,'Stable action identity'),'Learner purpose omits internal record title, identity and storage body');
              finally ActionLesson.Free;end;
              var PurposeEditor:=TDPHActionPurposeForm.Create(nil);
              try
                PurposeEditor.LoadRecord(ActionMetadata,'Application teacher');PurposeEditor.Show;Application.ProcessMessages;
                Check(not PurposeEditor.Profile_action_id_Row.Visible and not PurposeEditor.Profile_target_Row.Visible and not PurposeEditor.Profile_target_key_Row.Visible,'Purpose editor hides the three internal identity rows');
                Check(PurposeEditor.Profile_action_name_Row.Position.Y=0,'Purpose editor begins with the visible action name');
                var RoundTripPurpose:=PurposeEditor.RecordJSON;
                try Check(RoundTripPurpose.GetValue<string>('fields.action_id')=ActionFields.GetValue<string>('action_id'),'Simpler editor preserves the saved identity');finally RoundTripPurpose.Free;end;
                Bitmap:=TBitmap.Create(PurposeEditor.ClientWidth,PurposeEditor.ClientHeight);try
                  if Bitmap.Canvas.BeginScene then try PurposeEditor.PaintTo(Bitmap.Canvas);finally Bitmap.Canvas.EndScene;end;
                  Bitmap.SaveToFile(TPath.Combine(Work,'learning-refocus-purpose-editor.png'));
                finally Bitmap.Free;end;
                PurposeEditor.Hide;
              finally PurposeEditor.Free;end;
            finally ActionFacts.Free;end;
            var ControlFacts:=Model.Document.Clone as TJSONObject;
            try
              var ControlKey:='';
              for var ControlRow in ControlFacts.GetValue<TJSONArray>('symbols') do
                if ControlRow.GetValue<string>('kind')='component' then begin
                  ControlKey:=ControlRow.GetValue<string>('key');
                  (ControlRow as TJSONObject).RemovePair('serialized_properties').Free;
                  var ControlProperties:=TJSONArray.Create;
                  ControlProperties.AddElement(TJSONObject.Create.AddPair('name','Caption').AddPair('value','Choose <safely>'));
                  ControlProperties.AddElement(TJSONObject.Create.AddPair('name','Hint').AddPair('value','Enter the supplied example'));
                  ControlProperties.AddElement(TJSONObject.Create.AddPair('name','ReadOnly').AddPair('value','True'));
                  ControlProperties.AddElement(TJSONObject.Create.AddPair('name','MaxLength').AddPair('value','30'));
                  ControlProperties.AddElement(TJSONObject.Create.AddPair('name','Enabled').AddPair('value','False'));
                  ControlProperties.AddElement(TJSONObject.Create.AddPair('name','Visible').AddPair('value','False'));
                  (ControlRow as TJSONObject).AddPair('serialized_properties',ControlProperties);Break;
                end;
              Check(ControlKey<>'','Control explanation test uses a captured selected-project component');
              var ControlLesson:=TDPHExplanationModel.Create(ControlFacts);
              try
                FlowText:=ControlLesson.ObjectLessonHTML(ControlKey);
                Check(ContainsText(FlowText,'Text saved for this control: Choose &lt;safely&gt;'),'Control explanation uses escaped visible text');
                Check(ContainsText(FlowText,'Guidance supplied with this control: Enter the supplied example'),'Control explanation includes supplied typing guidance');
                Check(ContainsText(FlowText,'without allowing direct typing') and ContainsText(FlowText,'30 characters'),'Field explanation describes actual saved editability and input limit');
                Check(ContainsText(FlowText,'starts this control unavailable') and ContainsText(FlowText,'starts this control hidden'),'Control explanation distinguishes saved availability and visibility');
                Check(ContainsText(FlowText,'running application may change them'),'Design settings are not presented as guaranteed runtime behavior');
              finally ControlLesson.Free;end;
            finally ControlFacts.Free;end;
            Check(ContainsText(Explain.LessonHTML(4),'Sender &gt; 0'),'Decisions lesson teaches an actual application condition');
            Check(ContainsText(Explain.LessonHTML(4),'A true result takes one branch') and not ContainsText(Explain.LessonHTML(9),'possible_dynamic'),'Learner decisions explain their alternatives and author questions omit analyzer jargon');
            Check(ContainsText(Explain.LessonHTML(11),'Practice choosing a mode') and ContainsText(Explain.LessonHTML(11),'Expected result: identify both branch alternatives.') and ContainsText(Explain.LessonHTML(11),'Named task author'),'Task lesson displays selected-application instructions, expected outcome and named author');
            Check(not ContainsText(Explain.LessonHTML(11),'UNRELATED_NOTE_MUST_NOT_APPEAR'),'Task lesson excludes unrelated engineering notes');
            var PurposeFacts:=Model.Document.Clone as TJSONObject;
            try
              var PurposeRecord:=TJSONObject.Create;
              PurposeRecord.AddPair('owner','Named application author');PurposeRecord.AddPair('state','pending');
              var PurposeMetadata:=TJSONObject.Create;PurposeMetadata.AddPair('record_type','project_profile');
              var PurposeFields:=TJSONObject.Create;PurposeFields.AddPair('purpose','Teach a branch and a worker <safely>.');
              PurposeMetadata.AddPair('fields',PurposeFields);PurposeRecord.AddPair('structured_record',PurposeMetadata);
              PurposeFacts.GetValue<TJSONArray>('knowledge').AddElement(PurposeRecord);
              var PurposeLesson:=TDPHExplanationModel.Create(PurposeFacts);
              try
                FlowText:=PurposeLesson.LessonHTML(0);
                Check(ContainsText(FlowText,'Teach a branch and a worker &lt;safely&gt;') and ContainsText(FlowText,'Named application author'),'Opening lesson uses the authored application purpose with escaped content and attribution');
                Check(ContainsText(FlowText,'review status: pending') and not ContainsText(FlowText,'author has not yet supplied'),'Unreviewed purpose is presented with its actual review status');
              finally PurposeLesson.Free;end;
            finally PurposeFacts.Free;end;

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
              try BrowserBitmap.SaveToFile(TPath.Combine(Work,'learning-refocus-getting-started.png')); finally BrowserBitmap.Free; end;

              Check((Form.LessonPageCombo.Items.Count=11) and (Form.LessonPageCombo.Items.IndexOf('Learning library')>=0) and (Form.LessonPageCombo.Items.IndexOf('Database tools')<0) and (Form.LessonPageCombo.Items.IndexOf('Translations')<0),'Default learning navigation includes the teaching library and excludes database administration and translation tools');
              Check((Form.CodePageEdit.Parent=Form.AnalysisSettingsLayout) and (Form.ConfigurationCombo.Parent=Form.AnalysisSettingsLayout),'Encoding and compiler settings are serialized outside the learner toolbar');
              Form.SetupClick(nil); Check(Form.WorkspaceTabs.ActiveTab=Form.SetupTab,'Prepare lessons opens its separate setup page');
              Check((Form.WorkspacePageCombo.Items.Count=13) and (Form.WorkspacePageCombo.Items.IndexOf('Project map')>=0) and (Form.WorkspacePageCombo.Items.IndexOf('Database tools')<0) and (Form.WorkspacePageCombo.Items.IndexOf('Target data retention')<0),'Preparation menu includes the project map without database administration');
              Check(not Form.AnalysisSettingsExpander.IsExpanded and (Form.AnalysisSettingsExpander.Height<50),'Source reading settings start collapsed');
              Form.AnalysisSettingsExpander.IsExpanded:=True;Application.ProcessMessages;
              Check(Form.AnalysisSettingsExpander.Height>390,'Native expander exposes the IDE-editable source settings when requested');
              Form.AnalysisSettingsExpander.IsExpanded:=False;
              Bitmap:=TBitmap.Create(Form.ClientWidth,Form.ClientHeight);try
                if Bitmap.Canvas.BeginScene then try Form.PaintTo(Bitmap.Canvas);finally Bitmap.Canvas.EndScene;end;
                Bitmap.SaveToFile(TPath.Combine(Work,'learning-refocus-preparation.png'));
              finally Bitmap.Free;end;
              Form.LessonPageCombo.ItemIndex:=Form.LessonPageCombo.Items.IndexOf('Learn the project'); Form.WorkspacePageChange(Form.LessonPageCombo);
              Check(Form.WorkspaceTabs.ActiveTab=Form.OverviewTab,'Learner page selector returns from preparation to learning');
              Form.LoadView(View.Document.Clone as TJSONObject);
              Check(Form.WorkspaceTabs.ActiveTab=Form.OverviewTab,'A newly opened application starts its learning route');
              Check((Form.DatabaseInventoryList.Count=0) and (Form.QualityList.Count=0) and (Form.ActionPurposeList.Count=0),'Opening a lesson leaves unrequested preparation reports unloaded');
              Check(not Form.ExplorerLayout.Visible and not Form.InspectorLayout.Visible,'Guided lessons reserve width for learning instead of technical side panels');
              Form.LessonPageCombo.ItemIndex:=Form.LessonPageCombo.Items.IndexOf('Project map');
              Form.WorkspacePageChange(Form.LessonPageCombo);
              WaitHTML(Form.ExplainBrowser,'document.body.innerText','Files captured from this project');
              WaitHTML(Form.ExplainBrowser,'String(document.documentElement.scrollWidth <= window.innerWidth)','true');
              Check((Form.WorkspaceTabs.ActiveTab=Form.ExplainTab) and Form.ExplorerLayout.Visible and
                (Form.ExplorerList.Count>0) and (Form.KindCombo.Items.IndexOf('variable')>=0),
                'Project map exposes the indexed object tree and variable filter');
              Form.BookmarkClick(nil);
              Check(ContainsText(Form.StatusLabel.Text,'Select an object'),
                'Save place explains why it cannot act before an object is selected');
              Form.ExplorerList.ItemIndex:=0; Form.ExplorerClick(nil); Form.BookmarkClick(nil);
              Form.BookmarksClick(nil);
              Check((Form.WorkspaceTabs.ActiveTab=Form.ExplainTab) and (Form.ExplorerList.Count=1) and
                ContainsText(Form.BreadcrumbLabel.Text,'Saved places'),
                'Saved places opens its visible list in Project map');
              Form.ParentClick(nil);
              Check(Form.WorkspaceTabs.ActiveTab=Form.ExplainTab,'Up one level remains visible in Project map');
              Form.LearningShouldLoad(Form.ExplainBrowser,Form.ExplainBrowser.URL+'#open_forms',Failed);
              Check(Failed and (Form.WorkspaceTabs.ActiveTab=Form.ScreenTab),
                'Project map opens the saved form designs directly');
              Form.LearningShouldLoad(Form.ExplainBrowser,Form.ExplainBrowser.URL+
                '#form_'+THashSHA2.GetHashString(Form.FormCombo.Items[0]),Failed);
              Check(Failed and (Form.WorkspaceTabs.ActiveTab=Form.ScreenTab) and
                (Form.FormCombo.ItemIndex=0),
                'A linked screen opens its specific saved form design');
              Form.LearningShouldLoad(Form.ExplainBrowser,Form.ExplainBrowser.URL+'#open_screenshots',Failed);
              Check(Failed and (Form.WorkspaceTabs.ActiveTab=Form.ScreenshotTab),
                'Project map opens the actual-screenshot page directly');
              Form.WorkspaceTabs.ActiveTab:=Form.OverviewTab;
              Form.LoadKnowledge(Store.KnowledgeJSON);
              Form.WorkspaceTabs.ActiveTab:=Form.ActionPurposeTab;Form.WorkspacePageChange(nil);
              Check(Form.ActionPurposeList.Count>0,'Requesting action purposes builds their real preparation report');
              Form.WorkspaceTabs.ActiveTab:=Form.OverviewTab;

              WaitHTML(Form.LearningBrowser,'document.body.innerText','Selected application'); Check(True,'Real WebView2 renders the selected application route');

              Failed:=False; Form.LearningShouldLoad(Form.LearningBrowser,Form.LearningBrowser.URL+'#lesson_3',Failed);
              Check(Failed and (Form.LearningTopics.ItemIndex=3) and (Form.LearningTopics.Count=4),'Route link opens Resolve unknowns without external navigation');
              Form.LearningShouldLoad(Form.LearningBrowser,Form.LearningBrowser.URL+'#task_reader',Failed);
              Check(Failed and (Form.WorkspaceTabs.ActiveTab=Form.TaskTab),'Task walkthrough link opens the native step reader');
              Form.LearningShouldLoad(Form.LearningBrowser,Form.LearningBrowser.URL+'#ask_author',Failed);
              Check(Failed and (Form.WorkspaceTabs.ActiveTab=Form.QuestionsTab),'Question lesson link opens the existing named-answer workflow');
              Form.WorkspaceTabs.ActiveTab:=Form.OverviewTab;
              WaitHTML(Form.LearningBrowser,'document.body.innerText','What the captured files cannot confirm');
              BrowserBitmap:=Form.LearningBrowser.CaptureBitmap;
              try BrowserBitmap.SaveToFile(TPath.Combine(Work,'learning-refocus-action-lesson.png')); finally BrowserBitmap.Free; end;
              Form.LearningTopics.ItemIndex:=2; Form.LearningClick(nil);
              WaitHTML(Form.LearningBrowser,'document.body.innerText','Other tasks and actions');
              WaitHTML(Form.LearningBrowser,'document.title','Explore related tasks: Semantic.dproj');
              Check(True,'Native browser shows the app-specific title without damaged punctuation');
              Check(ContainsText(Form.OverviewMemo.Text,'Other tasks and actions') and not ContainsText(Form.OverviewMemo.Text,'Source capture'),'Text fallback presents the same app-specific route without technical capture metadata');
              BrowserBitmap:=Form.LearningBrowser.CaptureBitmap;
              try BrowserBitmap.SaveToFile(TPath.Combine(Work,'learning-refocus-screen-lesson.png')); finally BrowserBitmap.Free; end;
              Form.WindowState:=TWindowState.wsNormal; Form.ClientWidth:=960;Form.ClientHeight:=600;Application.ProcessMessages;
              WaitHTML(Form.LearningBrowser,'String(document.documentElement.scrollWidth <= window.innerWidth)','true');
              BrowserBitmap:=Form.LearningBrowser.CaptureBitmap;
              try BrowserBitmap.SaveToFile(TPath.Combine(Work,'learning-refocus-screen-compact.png')); finally BrowserBitmap.Free; end;
              Form.ClientWidth:=1600;Form.ClientHeight:=900;Application.ProcessMessages;
              Check(Form.LearningBrowser.Width>1000,'Wide lesson page uses the available main window');
              Form.SearchEdit.Text:='TMain.Click'; Form.ExplorerList.ItemIndex:=0; Form.ExplorerClick(nil);
              WaitHTML(Form.ExplainBrowser,'document.body.innerText','Understand this selection'); Check(True,'Real WebView2 renders the readable selected-object explanation');
              Check(Form.WorkspaceTabs.ActiveTab=Form.ExplainTab,'Explorer selection opens Explain');
              Check(ContainsText(Form.ExplainFallback.Text,'Understand this selection') and not ContainsText(Form.ExplainFallback.Text,'FORM PROPERTIES') and not ContainsText(Form.ExplainFallback.Text,'Source SHA256'),'Text fallback keeps the learning explanation and excludes optional technical dumps');
              BrowserBitmap:=Form.ExplainBrowser.CaptureBitmap;
              Check(BrowserBitmap<>nil,'Native WebView2 image capture is available for visual QA');
              try BrowserBitmap.SaveToFile(TPath.Combine(Work,'learning-refocus-explain-browser.png'));
              Bitmap:=TBitmap.Create(Form.ClientWidth,Form.ClientHeight); try
                if Bitmap.Canvas.BeginScene then try Form.PaintTo(Bitmap.Canvas);
                  Bitmap.Canvas.SetMatrix(TMatrix.Identity);
                  var BrowserBounds:=Form.ExplainBrowser.AbsoluteRect;
                  Bitmap.Canvas.DrawBitmap(BrowserBitmap,TRectF.Create(0,0,BrowserBitmap.Width,BrowserBitmap.Height),BrowserBounds,1);
                finally Bitmap.Canvas.EndScene; end;
                Bitmap.SaveToFile(TPath.Combine(Work,'learning-refocus-learning-workspace.png'));
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
              try BrowserBitmap.SaveToFile(TPath.Combine(Work,'learning-refocus-grouped-graph-browser.png')); finally BrowserBitmap.Free; end;
              Form.WorkspaceTabs.ActiveTab:=Form.PublishTab;
              Check(not Form.PublishSettingsExpander.IsExpanded and (Form.PublishSettingsExpander.Height<50),'Sharing starts with plain instructions and collapsed optional settings');
              Form.PublishBrowser.OnShouldLoadURL:=nil;
              Form.PublishBrowser.WindowsEngine:=TWindowsEngine.EdgeOnly;Form.PublishBrowser.Visible:=True;
              Form.PublishBrowser.Navigate('file://'+TPath.Combine(Work,'image-handoff\learning.html'));
              WaitHTML(Form.PublishBrowser,'document.body.innerText','Meet this app');
              WaitHTML(Form.PublishBrowser,'String(document.documentElement.scrollWidth <= window.innerWidth)','true');
              Check(True,'Actual native browser renders the saved learning edition without horizontal overflow');
              BrowserBitmap:=Form.PublishBrowser.CaptureBitmap;
              try BrowserBitmap.SaveToFile(TPath.Combine(Work,'learning-refocus-shared-lessons.png'));finally BrowserBitmap.Free;end;
              Form.PublishBrowser.OnShouldLoadURL:=Form.BrowserShouldLoad;
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
      Analyzer:=TDPHAnalyzer.Create; Semantic:=TDPHSemanticAnalyzer.Create;
      try Scan:=Analyzer.Scan(TPath.Combine(Root,'samples\OrderPractice\OrderPractice.dproj'),'Debug','Win32',[],[],False);
        try Graph:=Semantic.Analyze(Scan);
          try View:=TDPHWorkspaceView.Create(TDPHWorkspaceView.Capture(Scan,Graph,1,'OrderPractice.dproj','Debug','Win32',[],[]));
          finally Graph.Free; end;
        finally Scan.Free; end;
        try Model:=TDPHDocumentModel.Create(View,nil,[],[],False,True); Explain:=TDPHExplanationModel.Create(Model.Document);
          try
            FlowText:=Explain.ApplicationRouteHTML(1);
            Check(ContainsText(FlowText,'OrderPractice.dproj') and ContainsText(FlowText,'Calculate total') and
              not ContainsText(FlowText,'Semantic.dproj') and ContainsText(FlowText,'The connected code shows'),
              'A second selected project yields its own action and no imported practice lesson');
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
            Check(Model.Document.GetValue<TJSONArray>('startup').Count=3,'Pinned startup lesson includes the three startup operations without treating form-call arguments as separate actions');
            Check(ContainsText(Explain.LessonHTML(1),'Prepares the application framework') and ContainsText(Explain.LessonHTML(1),'Requests creation of a form'),'Token spacing does not prevent plain-language startup explanations');
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
              try BrowserBitmap.SaveToFile(TPath.Combine(Work,'learning-refocus-reference-explain.png')); finally BrowserBitmap.Free; end;
              WaitHTML(Form.ExplainBrowser,'(()=>{for(const d of document.querySelectorAll("details")){if(d.querySelector("summary")?.textContent.includes("Optional:"))d.open=true;}const h=Array.from(document.querySelectorAll("h2")).find(x=>x.textContent==="Follow the work"); if(!h||!h.offsetHeight)return "WAIT"; h.scrollIntoView();return "TRACE_READY";})()','TRACE_READY');
              Check(True,'Reference execution trace is present in the actual rendered explanation');
              Application.ProcessMessages; TThread.Sleep(100);
              BrowserBitmap:=Form.ExplainBrowser.CaptureBitmap;
              try BrowserBitmap.SaveToFile(TPath.Combine(Work,'learning-refocus-reference-trace.png')); finally BrowserBitmap.Free; end;
              Form.GraphCombo.ItemIndex:=1; Form.WorkspaceTabs.ActiveTab:=Form.GraphTab; Form.ViewChange(nil);
              WaitHTML(Form.FlowBrowser,'document.body.innerText','Control-flow diagram');
              Check(True,'Reference procedure CFG renders labeled captured edges');
              BrowserBitmap:=Form.FlowBrowser.CaptureBitmap;
              try BrowserBitmap.SaveToFile(TPath.Combine(Work,'learning-refocus-reference-flow.png')); finally BrowserBitmap.Free; end;
              Form.LearningTopics.ItemIndex:=1; Form.LearningClick(nil); Form.WorkspaceTabs.ActiveTab:=Form.OverviewTab;
              WaitHTML(Form.LearningBrowser,'document.body.innerText','Start with a task');
              Check(True,'Reference application renders its own task starting point');
              WaitHTML(Form.LearningBrowser,'String(document.documentElement.scrollWidth <= window.innerWidth)','true');
              Check(True,'Narrow learning view wraps long source citations without horizontal overflow');
              BrowserBitmap:=Form.LearningBrowser.CaptureBitmap;
              try BrowserBitmap.SaveToFile(TPath.Combine(Work,'learning-refocus-reference-startup.png')); finally BrowserBitmap.Free; end;
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
                try BrowserBitmap.SaveToFile(TPath.Combine(Work,'learning-refocus-source-lines-browser.png')); finally BrowserBitmap.Free; end;
              end;
              Form.Hide;
            finally Form.Free; end;
            Check(not Model.Document.GetValue<Boolean>('analysis_complete'),'Learning does not clear partial reference coverage');
          finally Explain.Free; Model.Free; end;
        finally View.Free; end;
      end;
      var LegacyRoot:=TPath.Combine(Work,'legacy-form');
      TDirectory.CreateDirectory(LegacyRoot);
      TFile.WriteAllText(TPath.Combine(LegacyRoot,'Legacy.dproj'),
        '<Project><ItemGroup><DCCReference Include="Legacy.pas"><Form>LegacyForm</Form></DCCReference></ItemGroup></Project>',TEncoding.UTF8);
      TFile.WriteAllBytes(TPath.Combine(LegacyRoot,'Legacy.pas'),TBytes.Create($FF,$41,$42));
      TFile.WriteAllText(TPath.Combine(LegacyRoot,'Legacy.fmx'),'object LegacyForm: TLegacyForm'+sLineBreak+
        '  Caption = ''Legacy learning screen'''+sLineBreak+'end',TEncoding.UTF8);
      Analyzer:=TDPHAnalyzer.Create;
      try
        Scan:=Analyzer.Scan(TPath.Combine(LegacyRoot,'Legacy.dproj'),'Debug','Win32',[],[]);
        try Check(Scan.Inventory.Sources.ContainsKey('legacy.fmx'),
          'A project-listed form resource is captured even when its Pascal unit is undecodable');
        finally Scan.Free;end;
      finally Analyzer.Free;end;
      if (ParamCount>=4) and TFile.Exists(ParamStr(3)) then begin
        Analyzer:=TDPHAnalyzer.Create;
        try
          Scan:=Analyzer.Scan(ParamStr(3),'Debug','Win64',[],[]);
          try
            var FormCount:=0;
            for var CapturedPath in Scan.Inventory.Sources.Keys do
              if MatchText(TPath.GetExtension(CapturedPath),['.fmx','.dfm']) then Inc(FormCount);
            Check(FormCount>=StrToInt(ParamStr(4)),
              'Selected project captures '+IntToStr(FormCount)+' form designs, including resources of undecodable units');
            Semantic:=TDPHSemanticAnalyzer.Create;
            try
              Graph:=Semantic.Analyze(Scan);
              try
                View:=TDPHWorkspaceView.Create(TDPHWorkspaceView.Capture(Scan,Graph,1,
                  TPath.GetFileName(ParamStr(3)),'Debug','Win64',[],[]));
                try
                  Form:=TDPHMainForm.Create(nil);
                  try
                    Form.PollTimer.Enabled:=False; Form.ChangeTimer.Enabled:=False;
                    Form.LoadView(View.Document.Clone as TJSONObject);
                    Check((Form.FormCombo.Items.Count>=StrToInt(ParamStr(4))) and
                      ContainsText(Form.OverviewMemo.Text,IntToStr(FormCount)+' saved screen design(s)'),
                      'The learner sees the captured form count in the actual DPH form');
                    Check(ContainsText(Form.OverviewMemo.Text,'portable FireMonkey desktop application') and
                      ContainsText(Form.OverviewMemo.Text,'Westminster_Chimes_and_Carillon_Bells_8_1_Application_Guide.md'),
                      'The actual Carillon guide supplies purpose and attribution in the learner view');
                    Form.LearningTopics.ItemIndex:=1; Form.LearningClick(nil);
                    Check(ContainsText(Form.OverviewMemo.Text,'Read this application') and
                      ContainsText(Form.OverviewMemo.Text,'playlist form is responsible for'),
                      'The task route retains selected-project guide substance in its text fallback');
                    Form.LearningTopics.ItemIndex:=3; Form.LearningClick(nil);
                    Check(not ContainsText(Form.OverviewMemo.Text,'purpose and first screen need confirmation') and
                      ContainsText(Form.OverviewMemo.Text,'Permissions, external services and recovery behavior'),
                      'Unknowns acknowledge purpose evidence and identify unobserved operating behavior');
                  finally Form.Free;end;
                finally View.Free;end;
              finally Graph.Free;end;
            finally Semantic.Free;end;
          finally Scan.Free;end;
        finally Analyzer.Free;end;
      end;
      Report:=TJSONObject.Create; try Report.AddPair('checks_passed',TJSONNumber.Create(Checks)); Report.AddPair('work',Work); Report.AddPair('reference_cache',ReferenceDB); Report.AddPair('human_acceptance','not_run'); Report.AddPair('guides_review','Manual review and rendered-guide verification are recorded separately from this native learning suite');
        Report.AddPair('reference_learning_projection_ms',TJSONNumber.Create(ReferenceViewMS));
        TFile.WriteAllText(TPath.Combine(Root,'docs\validation\reports\learning-refocus-learning-validation.json'),Report.Format(2),TEncoding.UTF8);
      finally Report.Free; end;
      if not StartsText(TPath.Combine(TPath.GetFullPath(Root),'bin\learning-refocus-tests-'),TPath.GetFullPath(Work)) then
        raise Exception.Create('Refusing cleanup outside the generated refocus test workspace');
      TDirectory.Delete(Work,True);
      Writeln('PASS Learning: ',Checks,' checks; disposable test workspace removed');
    except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode:=1; end; end;
  finally CoUninitialize; end;
end.
