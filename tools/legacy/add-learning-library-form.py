from pathlib import Path
root=Path(__file__).resolve().parents[2]
path=root/'DPH.UI.Main.fmx'
text=path.read_text(encoding='utf-8-sig')
text=text.replace("'Learn a task'\n'Form designs'","'Learn a task'\n'Learning library'\n'Form designs'")
text=text.replace("'Learn a task'\n'Action purposes'","'Learn a task'\n'Learning library'\n'Action purposes'")
categories=['Screen','Field','Error or problem','Question and answer','Business rule','Output or report','Role or permission','Related system','Setting or option','Background work','History or design choice','Learning check']
library='''object CardLibraryTab: TTabItem
Text = 'Learning library'
object CardPurpose: TLabel
Align = Top
Height = 72
Margins.Left = 12
Margins.Right = 12
WordWrap = True
Text = 'Learn what the selected application does and how to use it. Read worked examples, field guidance, rules, answers and safe troubleshooting. Explanations are supplied by named contributors; Unknown means an answer is still needed.'
end
object CardToolbar: THorzScrollBox
Align = Top
Height = 48
object CardNew: TButton
Position.X = 12
Position.Y = 6
Width = 180
Height = 32
Text = 'Prepare an explanation'
OnClick = CardEditClick
end
object CardEdit: TButton
Position.X = 200
Position.Y = 6
Width = 160
Height = 32
Text = 'Edit explanation'
OnClick = CardEditClick
end
object CardRelated: TButton
Position.X = 368
Position.Y = 6
Width = 190
Height = 32
Text = 'Explore related selection'
OnClick = CardRelatedClick
end
end
object CardFilter: TEdit
Align = Top
Height = 34
Margins.Left = 12
Margins.Right = 12
TextPrompt = 'Find a topic, question, error message or example'
OnChange = CardFilterChange
end
object CardRole: TEdit
Align = Top
Height = 34
Margins.Left = 12
Margins.Right = 12
TextPrompt = 'User role (blank means all; shared explanations always appear)'
OnChange = CardFilterChange
end
object CardList: TListBox
Align = Left
Width = 260
Margins.Left = 12
Margins.Right = 12
OnChange = CardSelectionChange
end
object CardReader: TMemo
Align = Client
Margins.Right = 12
Margins.Bottom = 12
ReadOnly = True
WordWrap = True
ShowScrollBars = True
StyledSettings = []
TextSettings.Font.Size = 17
end
end
object CardEditorTab: TTabItem
Text = 'Prepare an explanation'
object CardEditorPurpose: TLabel
Align = Top
Height = 78
Margins.Left = 12
Margins.Right = 12
WordWrap = True
Text = 'Teach one part of the selected application. Name the screen, field, error, question or report. Explain its purpose in plain language, give a worked example, mistakes to avoid, safe help and a practice question with its answer. Unknown is allowed when the author must answer. A new card links to the currently selected object, if any.'
end
object CardEditToolbar: THorzScrollBox
Align = Top
Height = 78
object CardCategory: TComboBox
Position.X = 12
Position.Y = 12
Width = 210
Height = 34
Items.Strings = (
'''+''.join("'"+c+"'\n" for c in categories)+''')
ItemIndex = 0
OnChange = CardChanged
end
object CardAuthor: TEdit
Position.X = 234
Position.Y = 12
Width = 230
Height = 34
TextPrompt = 'Person supplying this explanation'
OnChange = CardChanged
end
object CardSave: TButton
Position.X = 476
Position.Y = 12
Width = 150
Height = 34
Text = 'Save explanation'
OnClick = CardSaveClick
end
object CardCancel: TButton
Position.X = 638
Position.Y = 12
Width = 150
Height = 34
Text = 'Cancel changes'
OnClick = CardCancelClick
end
end
object CardEditorScroll: TVertScrollBox
Align = Client
Margins.Left = 12
Margins.Right = 12
'''
fields=[('name','Topic name: screen, field, exact error, question or report',64),('role','Who this helps: enter a user role, or All learners',64),('meaning','What it means and why the user needs it',110),('example','Worked example, valid input and units, or sample output explained',110),('limits','Rules, limits, permission requirements and common mistakes',110),('help','If the result differs: symptom, safe next step and who can help',110),('practice','Practice question or exercise and expected answer',110)]
y=0
for key,label,height in fields:
 library+=f'''object Card_{key}_label: TLabel
Align = Top
Position.Y = {y}
Height = 38
WordWrap = True
Text = '{label}'
end
object Card_{key}: TMemo
Align = Top
Position.Y = {y+38}
Height = {height}
WordWrap = True
ShowScrollBars = True
OnChange = CardChanged
end
'''
 y+=height+38
library+='end\nend\n'
assert 'object CardLibraryTab:' not in text
text=text.replace('object SetupTab: TTabItem',library+'object SetupTab: TTabItem',1)
path.write_bytes(text.replace('\r\n','\n').replace('\n','\r\n').encode('utf-8'))
path=root/'DPH.UI.Main.pas';text=path.read_text(encoding='utf-8-sig')
text=text.replace('begin FTaskRows.Clear;FKnowledge.Free;','begin FCardRows.Clear;CardList.Items.Clear;FTaskRows.Clear;FKnowledge.Free;')
text=text.replace('DataQualityFilterChange(nil);TaskFilterChange(nil); FActionPurposeRows.Clear;','DataQualityFilterChange(nil);TaskFilterChange(nil);CardFilterChange(nil); FActionPurposeRows.Clear;')
text=text.replace('  FTaskRows.Clear;TaskList.Items.Clear;FreeAndNil(FTaskDraft);TaskSelectionChange(nil);','  FCardRows.Clear;CardList.Items.Clear;CardSelectionChange(nil);FreeAndNil(FCardDraft);FCardSavingID:=\'\';\n  FTaskRows.Clear;TaskList.Items.Clear;FreeAndNil(FTaskDraft);TaskSelectionChange(nil);')
path.write_bytes(text.replace('\r\n','\n').replace('\n','\r\n').encode('utf-8'))
