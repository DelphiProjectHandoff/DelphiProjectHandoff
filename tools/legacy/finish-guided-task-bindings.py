from pathlib import Path
root=Path(__file__).resolve().parents[2]
f=root/'DPH.UI.Main.fmx';t=f.read_text(encoding='utf-8-sig')
t=t.replace("'Saved explanations'\n'Prepare a task'","'Saved explanations'",1)
pos=t.index('object WorkspacePageCombo:')
t=t[:pos]+t[pos:].replace("'Saved explanations'","'Saved explanations'\n'Prepare a task'",1)
f.write_text(t,encoding='utf-8')
p=root/'DPH.UI.Main.pas';bom=p.read_bytes().startswith(b'\xef\xbb\xbf');t=p.read_text(encoding='utf-8-sig')
t=t.replace('FProjectMembers.Free; FComparison.Free; FQualityRows.Free;', 'FProjectMembers.Free; FComparison.Free; FQualityRows.Free;FTaskRows.Free;FTaskDraft.Free;',1)
t=t.replace('  FreeAndNil(FView); FreeAndNil(FGraph); FreeAndNil(FScreen); FreeAndNil(FKnowledge);', '  FTaskRows.Clear;TaskList.Items.Clear;FreeAndNil(FTaskDraft);TaskSelectionChange(nil);\n  FreeAndNil(FView); FreeAndNil(FGraph); FreeAndNil(FScreen); FreeAndNil(FKnowledge);',1)
old="      LoadKnowledge(R.Knowledge); R.Knowledge:=nil; end;"
new="""      LoadKnowledge(R.Knowledge); R.Knowledge:=nil;
      if FTaskSavingID<>'' then begin
        TaskFilter.Text:='';TaskFilterChange(nil);
        for var TaskIndex:=0 to FTaskRows.Count-1 do
          if TDPHWorkspaceView.IsLearningLesson(FTaskRows[TaskIndex]) then begin
            var SavedLesson:=TJSONObject.ParseJSONValue(FTaskRows[TaskIndex].GetValue<string>('structured_json')) as TJSONObject;
            try if SavedLesson.GetValue<string>('lesson_id')=FTaskSavingID then begin TaskList.ItemIndex:=TaskIndex;TaskSelectionChange(nil);Break;end;finally SavedLesson.Free;end;
          end;
        FTaskSavingID:='';WorkspaceTabs.ActiveTab:=TaskTab;
      end;
    end;"""
assert old in t;t=t.replace(old,new,1)
anchor='    if R.Knowledge<>nil then begin'
t=t.replace(anchor,"    if not R.Busy and (FTaskSavingID<>'') then begin\n      TaskEditorScroll.Enabled:=True;TaskEditorToolbar.Enabled:=True;\n      if R.Failed then FTaskSavingID:='';\n    end;\n"+anchor,1)
t=t.replace("begin if not FBinding and (FTaskDraft<>nil) then FKnowledgeEdited:=True;end;", "begin if not FBinding and (FTaskDraft<>nil) then begin FKnowledgeEdited:=True;FStructuredEditorPending:=True;end;end;",1)
t=t.replace('FTutorStepDirty:=True;FKnowledgeEdited:=True;end;end;', 'FTutorStepDirty:=True;FKnowledgeEdited:=True;FStructuredEditorPending:=True;end;end;',1)
t=t.replace("   KnowledgeBodyMemo.Text:=TDPHWorkspaceView.LearningLessonBody(FTaskDraft);", "   KnowledgeBodyMemo.ReadOnly:=True;KnowledgeTitleEdit.ReadOnly:=True;KnowledgeKindCombo.Enabled:=False;KnowledgeDocumentCombo.Enabled:=False;KnowledgeAudienceCombo.Enabled:=False;\n   KnowledgeBodyMemo.Text:=TDPHWorkspaceView.LearningLessonBody(FTaskDraft);",1)
p.write_text(t,encoding='utf-8-sig' if bom else 'utf-8')
print('Guided task response, ownership and navigation bindings completed')
