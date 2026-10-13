from pathlib import Path
root=Path(__file__).resolve().parents[2]
types={}
def node(name,kind,props='',children=''):
    types[name]=kind
    return f'object {name}: {kind}\n{props}\n{children}end\n'
def label(name,text,height=30):
    return node(name,'TLabel',f"Align = Top\nHeight = {height}\nWordWrap = True\nText = '{text}'")
def memo(name,height,readonly=False,event=''):
    return node(name,'TMemo',f'Align = Top\nHeight = {height}\nWordWrap = True\nReadOnly = {str(readonly)}\nShowScrollBars = True'+(f'\nOnChange = {event}' if event else ''))
def button(name,text,handler,x,width=130):
    return node(name,'TButton',f"Position.X = {x}\nPosition.Y = 6\nWidth = {width}\nHeight = 30\nText = '{text}'\nOnClick = {handler}")
reader=node('TaskReaderPanel','TLayout','Align = Client\nMargins.Left = 12\nMargins.Right = 12',
    label('TaskReaderTitle','Choose a task to learn',38)+memo('TaskContextMemo',110,True)+
    label('TaskStepLabel','Step instructions',30)+
    node('TaskNavigation','THorzScrollBox','Align = Bottom\nHeight = 44',button('TaskPrevious','Previous step','TaskNavigate',8)+button('TaskNext','Next step','TaskNavigate',146)+button('TaskRestart','Start again','TaskNavigate',284))+
    memo('TaskResultMemo',120,True)+node('TaskActionMemo','TMemo','Align = Client\nReadOnly = True\nWordWrap = True\nShowScrollBars = True\nTextSettings.Font.Size = 17'))
left=node('TaskPicker','TLayout','Align = Left\nWidth = 240',
    label('TaskPickerLabel','Choose a saved task',32)+node('TaskFilter','TEdit',"Align = Top\nHeight = 34\nTextPrompt = 'Find task instructions'\nOnChange = TaskFilterChange")+
    node('TaskNextPage','TButton',"Align = Bottom\nHeight = 32\nText = 'More tasks'\nOnClick = TaskFilterChange")+
    node('TaskList','TListBox','Align = Client\nOnChange = TaskSelectionChange'))
toolbar=node('TaskToolbar','THorzScrollBox','Align = Top\nHeight = 44',
    button('TaskNew','Prepare a new task','TaskEditClick',8,170)+button('TaskEdit','Edit instructions','TaskEditClick',186,150)+button('TaskNotes','Notes and review','TaskOpenNotes',344,150))
reader=node('TaskTab','TTabItem',"Text = 'Learn a task'",label('TaskPurposeLabel','Learn one task step by step. Read what must be ready, follow each action, and check the expected result. DPH presents instructions without running the selected application.',64)+toolbar+left+reader)
fields=''
for key,caption in [('name','Task name'),('purpose','What the learner will accomplish'),('prerequisites','Before the learner begins'),('expected_result','Expected result of the whole task'),('troubleshooting','If something goes wrong'),('practice','Practice and check your understanding')]:
    fields+=label('Tutor_'+key+'_label',caption)+memo('Tutor_'+key,90,event='TaskEditorChanged')
fields+=label('TutorStepsLabel','Steps in the order the learner follows',32)+node('TutorSteps','TListBox','Align = Top\nHeight = 150\nOnChange = TutorStepSelection')
actions=''
for i,(name,text) in enumerate([('TutorNewStep','New step'),('TutorKeepStep','Keep step'),('TutorDiscardStep','Undo step edit'),('TutorRemoveStep','Remove step'),('TutorStepUp','Move up'),('TutorStepDown','Move down')]):
    actions+=button(name,text,'TutorStepAction',8+i*138)
fields+=node('TutorStepToolbar','THorzScrollBox','Align = Top\nHeight = 44',actions)
fields+=label('TutorActionLabel','What the learner does in this step')+memo('TutorAction',100,event='TutorStepChanged')
fields+=label('TutorExpectedLabel','What the learner should see after this step')+memo('TutorExpected',90,event='TutorStepChanged')
top=node('TaskEditorToolbar','THorzScrollBox','Align = Top\nHeight = 80',
    node('TutorAuthorLabel','TLabel',"Position.X = 12\nPosition.Y = 0\nWidth = 220\nHeight = 24\nText = 'Person supplying these instructions'")+
    node('TutorAuthor','TEdit','Position.X = 12\nPosition.Y = 30\nWidth = 220\nHeight = 30\nOnChange = TaskEditorChanged')+
    button('TutorSave','Save task','TaskSaveClick',244,130).replace('Position.Y = 6','Position.Y = 30')+
    button('TutorCancel','Cancel changes','TaskCancelClick',382,150).replace('Position.Y = 6','Position.Y = 30'))
editor=node('TaskEditorTab','TTabItem',"Text = 'Prepare a task'",
    label('TaskEditorPurpose','Prepare instructions for this selected application. Supply a purpose, prerequisites, ordered actions and expected results. Keep each step, then Save task. Do not invent outcomes; enter Unknown where a result needs confirmation.',70)+top+
    node('TaskEditorScroll','TVertScrollBox','Align = Client\nMargins.Left = 12\nMargins.Right = 12',fields))
f=root/'DPH.UI.Main.fmx';text=f.read_text(encoding='utf-8-sig')
text=text.replace("'Learn the project'", "'Learn the project'\n'Learn a task'",2)
text=text.replace("'Saved explanations'", "'Saved explanations'\n'Prepare a task'",1)
text=text.replace('object CoverageTab: TTabItem',reader+editor+'object CoverageTab: TTabItem',1)
f.write_text(text,encoding='utf-8')
p=root/'DPH.UI.Main.pas';bom=p.read_bytes().startswith(b'\xef\xbb\xbf');text=p.read_text(encoding='utf-8-sig')
decl=''.join(f'    {n}: {t};\n' for n,t in types.items())
text=text.replace('    WorkspacePageCombo,LessonPageCombo: TComboBox;',decl+'    WorkspacePageCombo,LessonPageCombo: TComboBox;',1)
methods=['TaskFilterChange','TaskSelectionChange','TaskNavigate','TaskEditClick','TaskOpenNotes','TaskEditorChanged','TutorStepSelection','TutorStepChanged','TutorStepAction','TaskSaveClick','TaskCancelClick']
text=text.replace('    procedure SetupClick(Sender: TObject);',''.join(f'    procedure {m}(Sender: TObject);\n' for m in methods)+'    procedure SetupClick(Sender: TObject);',1)
text=text.replace('    FCalculationEvidence:TJSONObject;', '    FTaskRows:TList<TJSONObject>;\n    FTaskDraft:TJSONObject;\n    FTaskOffset,FTaskStep,FTutorStep:Integer;\n    FTutorStepDirty:Boolean;\n    FTaskSavingID:string;\n    FCalculationEvidence:TJSONObject;',1)
text=text.replace('  FQualityRows:=TList<TJSONObject>.Create;', '  FTaskRows:=TList<TJSONObject>.Create;\n  FQualityRows:=TList<TJSONObject>.Create;',1)
text=text.replace('  DataRetentionFilterChange(nil);','  TaskFilterChange(nil);\n  DataRetentionFilterChange(nil);',1)
text=text.replace('  FQualityRows.Free; FProjectMembers.Free;', '  FTaskRows.Free;FTaskDraft.Free;\n  FQualityRows.Free; FProjectMembers.Free;',1)
text=text.replace('procedure TDPHMainForm.ClearWorkspace;\nbegin','procedure TDPHMainForm.ClearWorkspace;\nbegin\n  FTaskRows.Clear;TaskList.Items.Clear;FreeAndNil(FTaskDraft);TaskSelectionChange(nil);',1)
text=text.replace('begin FKnowledge.Free; FKnowledge:=ARows;','begin FTaskRows.Clear;FKnowledge.Free; FKnowledge:=ARows;',1)
text=text.replace('CalculationFilterChange(nil);BusinessRuleFilterChange(nil);DepartmentalWorkflowFilterChange(nil);DataQualityFilterChange(nil); if FView', 'CalculationFilterChange(nil);BusinessRuleFilterChange(nil);DepartmentalWorkflowFilterChange(nil);DataQualityFilterChange(nil);TaskFilterChange(nil); if FView',1)
text=text.replace('  FreeAndNil(FWorkflowDraft);FWorkflowStepDirty:=False;', '  FreeAndNil(FTaskDraft);FTutorStepDirty:=False;\n  FreeAndNil(FWorkflowDraft);FWorkflowStepDirty:=False;',1)
p.write_text(text,encoding='utf-8-sig' if bom else 'utf-8')
print('Native task reader and preparation resources written; method implementations still required')
