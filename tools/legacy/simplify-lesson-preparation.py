from pathlib import Path
root=Path(__file__).resolve().parents[2]
p=root/'DPH.UI.Main.fmx';raw=p.read_bytes();text=raw.decode('utf-8-sig').replace('\r\n','\n')
start=text.index('object WorkspacePageCombo:');a=text.index('Items.Strings = (',start);b=text.index(')\nOnChange',a)
choices=['Learn the project','Learn a task','Action purposes','Screenshots','Business glossary','Author questions','Saved explanations','Knowledge links','Runtime observations','Publish','Projects']
text=text[:a]+'Items.Strings = (\n'+'\n'.join("'"+c+"'" for c in choices)+text[b:]
text=text.replace("Text = 'For the person preparing lessons: choose the source configuration, then refresh lessons. Learners can leave these settings alone. Additional project information below supports preparing and checking explanations; it is not the learning route.'", "Text = 'Prepare lessons for the selected application. First describe what it does and whom it helps. Then prepare one common task with clear steps and expected results. Add explanations, screenshots and business terms as needed. Learners return to Learn the project or Learn a task in the top-right selector.'",1)
start=text.index('object WorkspacePageCombo:')
toolbar='''object SetupLessonToolbar: THorzScrollBox
Align = Top
Height = 50
object SetupProfileButton: TButton
Position.X = 12
Position.Y = 8
Width = 210
Height = 32
Text = 'Describe this application'
OnClick = ProjectProfileClick
end
object SetupTaskButton: TButton
Position.X = 234
Position.Y = 8
Width = 210
Height = 32
Text = 'Prepare task instructions'
OnClick = TaskEditClick
end
end
object SetupMaterialLabel: TLabel
Align = Top
Height = 30
Margins.Left = 12
Text = 'Other lesson material: choose a page below.'
end
'''
text=text[:start]+toolbar+text[start:]
text=text.replace('object AnalysisSettingsLayout: TLayout\n',"object AnalysisSettingsExpander: TExpander\nAlign = Top\nMargins.Left = 12\nMargins.Right = 12\nHeight = 424\nHeaderHeight = 34\nText = 'Source reading settings (only if the application author needs them)'\nContentSize = '390'\nIsExpanded = False\nobject AnalysisSettingsLayout: TLayout\n",1)
stop=text.index('object TaskTab:')
text=text[:stop].rstrip()+'\nend\n'+text[stop:]
text=text.replace("Text = 'Focused questions from captured gaps, uncertain relationships, asynchronous work, SQL/output contracts and absent reviewed procedures. Up to 100 questions, at most 20 per category. Inspect evidence, then record the named author response. Saving does not verify an answer. Only an explicitly verified response with no pending review hides its exact question.'", "Text = 'Ask the application author about unclear behavior or missing instructions. Select a question, read it, then choose Record author answer. Save the reply with the contributor name. An answer still needs review by someone who knows the application.'",1)
p.write_bytes((b'\xef\xbb\xbf' if raw.startswith(b'\xef\xbb\xbf') else b'')+text.replace('\n','\r\n').encode('utf-8'))
p=root/'DPH.UI.Main.pas';raw=p.read_bytes();text=raw.decode('utf-8-sig').replace('\r\n','\n')
text=text.replace('    SetupPurpose,AnalysisSettingsTitle: TLabel;', '    SetupPurpose,AnalysisSettingsTitle,SetupMaterialLabel: TLabel;\n    SetupLessonToolbar: THorzScrollBox;\n    SetupProfileButton,SetupTaskButton: TButton;\n    AnalysisSettingsExpander: TExpander;',1)
text=text.replace('if Sender=TaskNew then begin NewKnowledgeClick(nil);','if (Sender=TaskNew) or (Sender=SetupTaskButton) then begin NewKnowledgeClick(nil);',1)
p.write_bytes((b'\xef\xbb\xbf' if raw.startswith(b'\xef\xbb\xbf') else b'')+text.replace('\n','\r\n').encode('utf-8'))
