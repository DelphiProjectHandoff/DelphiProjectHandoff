from pathlib import Path
root=Path(__file__).resolve().parents[2]
p=(root/'tests/DPH.Tests.Learning.dpr').read_text(encoding='utf-8-sig')
p=p.replace('program DPH.Tests.Learning;','program DPH.Tests.LearningRefocus;',1)
p=p.replace('docs\\rework-', 'docs\\learning-refocus-').replace('docs\\completion-', 'docs\\learning-refocus-')
p=p.replace('bin\\learning-tests-', 'bin\\learning-refocus-tests-')
p=p.replace("          Rows:=Store.KnowledgeJSON;", "          Store.SaveKnowledge(0,0,Generation,'Unrelated project note','UNRELATED_NOTE_MUST_NOT_APPEAR','Other Author','note','');\n          Rows:=Store.KnowledgeJSON;",1)
anchor="            for I:=0 to 10 do Check(Length(Explain.TopicHTML(I))>1500,'Learning topic '+IntToStr(I)+' renders a complete offline page');"
assert anchor in p
p=p.replace(anchor,anchor+'''
            Check(not ContainsText(Explain.ObjectHTML(Key),'UNRELATED_NOTE_MUST_NOT_APPEAR'),'Unlinked global notes do not masquerade as an object purpose');
            Check(ContainsText(Explain.ObjectLessonHTML(Key),'Fixture explanation supplied') and not ContainsText(Explain.ObjectLessonHTML(Key),'UNRELATED_NOTE_MUST_NOT_APPEAR'),'Learner explanation includes linked knowledge and excludes unrelated notes');
            Check(ContainsText(Explain.ObjectLessonHTML(Key),'<details class="card"><summary>Optional: read the code walkthrough'),'Detailed source walkthrough is optional in the learner explanation');
            for I:=0 to 10 do begin
              FlowText:=Explain.LessonHTML(I);
              Check((Length(FlowText)>1500) and not ContainsText(FlowText,'SHA256') and not ContainsText(FlowText,'confirmed_static'),'Learner topic '+IntToStr(I)+' avoids technical hash and resolution dumps');
            end;
            Check(ContainsText(Explain.LessonHTML(0),'author has not yet supplied') and not ContainsText(Explain.LessonHTML(0),'UNRELATED_NOTE_MUST_NOT_APPEAR'),'Application purpose gap is explicit without dumping unrelated records');
            Check(ContainsText(Explain.LessonHTML(2),'btnConvert') and ContainsText(Explain.LessonHTML(2),'OnClick') and ContainsText(Explain.LessonHTML(2),'Click'),'Screen lesson uses actual captured control and action binding');
            Check(ContainsText(Explain.LessonHTML(3),'responding operation') and ContainsText(Explain.LessonHTML(3),'#s_'),'Action lesson links actual event and handler');
            Check(ContainsText(Explain.LessonHTML(4),'Sender &gt; 0'),'Decisions lesson teaches an actual application condition');
''',1)
anchor="              Form.LoadView(View.Document.Clone as TJSONObject); Form.WorkspaceTabs.ActiveTab:=Form.OverviewTab;"
assert anchor in p
p=p.replace(anchor,'''
              Check((Form.LessonPageCombo.Items.Count=9) and (Form.LessonPageCombo.Items.IndexOf('Database tools')<0) and (Form.LessonPageCombo.Items.IndexOf('Translations')<0),'Default learning navigation excludes database administration and translation tools');
              Check((Form.CodePageEdit.Parent=Form.AnalysisSettingsLayout) and (Form.ConfigurationCombo.Parent=Form.AnalysisSettingsLayout),'Encoding and compiler settings are serialized outside the learner toolbar');
              Form.SetupClick(nil); Check(Form.WorkspaceTabs.ActiveTab=Form.SetupTab,'Prepare lessons opens its separate setup page');
              Form.LessonPageCombo.ItemIndex:=Form.LessonPageCombo.Items.IndexOf('Learn the project'); Form.WorkspacePageChange(Form.LessonPageCombo);
              Check(Form.WorkspaceTabs.ActiveTab=Form.OverviewTab,'Learner page selector returns from preparation to learning');
              Form.LoadView(View.Document.Clone as TJSONObject);
              Check(Form.WorkspaceTabs.ActiveTab=Form.OverviewTab,'A newly opened application starts its learning route');
              Form.WorkspaceTabs.ActiveTab:=Form.OverviewTab;
''',1)
anchor="              Form.SearchEdit.Text:='TMain.Click';"
assert anchor in p
p=p.replace(anchor,'''
              Failed:=False; Form.LearningShouldLoad(Form.LearningBrowser,Form.LearningBrowser.URL+'#lesson_3',Failed);
              Check(Failed and (Form.LearningTopics.ItemIndex=3),'Lesson link opens its actual next topic without external navigation');
              WaitHTML(Form.LearningBrowser,'document.body.innerText','From an action to its operation');
              BrowserBitmap:=Form.LearningBrowser.CaptureBitmap;
              try BrowserBitmap.SaveToFile(TPath.Combine(Root,'docs\\learning-refocus-action-lesson.png')); finally BrowserBitmap.Free; end;
              Form.LearningTopics.ItemIndex:=2; Form.LearningClick(nil);
              WaitHTML(Form.LearningBrowser,'document.body.innerText','Meet the interface');
              BrowserBitmap:=Form.LearningBrowser.CaptureBitmap;
              try BrowserBitmap.SaveToFile(TPath.Combine(Root,'docs\\learning-refocus-screen-lesson.png')); finally BrowserBitmap.Free; end;
              Form.WindowState:=TWindowState.wsNormal; Form.ClientWidth:=960;Form.ClientHeight:=600;Application.ProcessMessages;
              WaitHTML(Form.LearningBrowser,'String(document.documentElement.scrollWidth <= window.innerWidth)','true');
              BrowserBitmap:=Form.LearningBrowser.CaptureBitmap;
              try BrowserBitmap.SaveToFile(TPath.Combine(Root,'docs\\learning-refocus-screen-compact.png')); finally BrowserBitmap.Free; end;
              Form.ClientWidth:=1600;Form.ClientHeight:=900;Application.ProcessMessages;
'''+anchor,1)
p=p.replace("Report.AddPair('human_acceptance','not_run');","Report.AddPair('human_acceptance','not_run'); Report.AddPair('guides_review','deferred by owner; guides and help assets unchanged');")
(root/'tests/DPH.Tests.LearningRefocus.dpr').write_text(p,encoding='utf-8-sig')
cmd=(root/'tools/build-learning.cmd').read_text().replace('DPH.Tests.Learning','DPH.Tests.LearningRefocus')
(root/'tools/build-learning-refocus.cmd').write_text(cmd,encoding='ascii')
print('Focused learner tests prepared with distinct evidence outputs')
