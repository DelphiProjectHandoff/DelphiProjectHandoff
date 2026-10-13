from pathlib import Path
import re
root=Path(__file__).resolve().parents[2]
def read(name): return (root/name).read_text(encoding='utf-8-sig')
def write(name,text):
    p=root/name
    bom=p.exists() and p.read_bytes().startswith(b'\xef\xbb\xbf')
    p.write_text(text,encoding='utf-8-sig' if bom else 'utf-8')
f=read('DPH.UI.Main.fmx')
def take(name):
    global f
    m=re.search(r'(?m)^\s*object '+re.escape(name)+r':[^\n]*\n',f)
    assert m,name
    depth=1
    for line in re.finditer(r'(?m)^\s*(object [^\n]+|end)\s*$',f[m.end():]):
        if line.group(1).startswith('object '): depth+=1
        else: depth-=1
        if depth==0:
            end=m.end()+line.end()
            block=f[m.start():end].strip()+'\n'
            f=f[:m.start()]+f[end:]
            return block
    raise ValueError(name)
chooser=take('WorkspacePageCombo')
settings=[]
for name in ['ConfigurationCombo','PlatformCombo','DefinesEdit','ExternalRootsEdit','CodePageEdit','CodePageLabel','RelocateButton']:
    settings.append(take(name))
chooser=re.sub(r'Align = Right\nWidth = 210', 'Align = Top\nHeight = 34',chooser)
chooser=chooser.replace('Margins.Top = 12','Margins.Top = 8').replace('Margins.Bottom = 12','Margins.Bottom = 8')
chooser=chooser.replace("'Getting started'", "'Getting started'\n'Project setup'",1)
for i,block in enumerate(settings):
    block=re.sub(r'Position.X = [^\n]+','Position.X = 12',block)
    block=re.sub(r'Position.Y = [^\n]+',f'Position.Y = {40+i*40}',block)
    if 'object CodePageLabel:' in block:
        block=block.replace('Width = 1180','Width = 650').replace('Height = 28','Height = 65')
        block=block.replace("Text = 'Source code page: 0 = Unicode; 1252 = Western; 1251 = Cyrillic; 932 = Japanese. BOM takes precedence. Apply with reassessment.'", "WordWrap = True\nText = 'Text encoding is only needed if an older source file displays incorrect characters. Leave 0 unless the application author supplies a Windows encoding number. Refresh lessons after changing these settings.'")
    if 'object CodePageEdit:' in block: block=block.replace("TextPrompt = 'Code page'", "TextPrompt = 'Text encoding'")
    if 'object RelocateButton:' in block: block=block.replace('Position.Y = 280','Position.Y = 330')
    settings[i]=block
setup='''object SetupTab: TTabItem
Text = 'Project setup'
object SetupScroll: TVertScrollBox
Align = Client
object SetupPurpose: TLabel
Align = Top
Height = 86
Margins.Left = 12
Margins.Right = 12
WordWrap = True
Text = 'For the person preparing lessons: choose the source configuration, then refresh lessons. Learners can leave these settings alone. Additional project information below supports preparing and checking explanations; it is not the learning route.'
end
'''+chooser+'''object AnalysisSettingsLayout: TLayout
Align = Top
Height = 390
object AnalysisSettingsTitle: TLabel
Position.X = 12
Position.Y = 0
Width = 650
Height = 36
Text = 'Source-reading settings (Debug, platform, extra defines, allowed dependency folders, text encoding)'
WordWrap = True
end
'''+''.join(settings)+'''end
end
end
'''
f=f.replace('object CoverageTab: TTabItem',setup+'object CoverageTab: TTabItem',1)
header='''object LessonPageCombo: TComboBox
Align = Right
Width = 210
Margins.Top = 12
Margins.Bottom = 12
Margins.Right = 12
Items.Strings = (
'Getting started'
'Learn the project'
'Form designs'
'Screenshots'
'Explain'
'Graphs'
'Business glossary'
'Search project'
'Knowledge')
OnChange = WorkspacePageChange
end
object SetupButton: TButton
Align = Right
Width = 118
Margins.Top = 12
Margins.Bottom = 12
Margins.Right = 8
Text = 'Prepare lessons'
OnClick = SetupClick
end
'''
f=f.replace('object HelpButton: TButton',header+'object HelpButton: TButton',1)
f=f.replace('Height = 140\nShowScrollBars','Height = 84\nShowScrollBars',1)
f=f.replace("Text = 'Attach project'","Text = 'Choose application'",1).replace('Width = 120\nHeight = 28\nOnClick = OpenProjectClick','Width = 150\nHeight = 28\nOnClick = OpenProjectClick',1)
f=f.replace('Position.X = 136\nPosition.Y = 4','Position.X = 166\nPosition.Y = 4',1)
f=f.replace("Text = 'Open cache'","Text = 'Open saved lessons'",1).replace('Width = 120\nHeight = 28\nOnClick = OpenCacheClick','Width = 150\nHeight = 28\nOnClick = OpenCacheClick',1)
f=f.replace('Position.X = 264\nPosition.Y = 4','Position.X = 326\nPosition.Y = 4',1).replace("Text = 'Full reassessment'","Text = 'Refresh lessons'",1)
f=f.replace('Position.X = 690\nPosition.Y = 42','Position.X = 516\nPosition.Y = 42',1)
f=f.replace("Text = 'Select a Delphi project or cached database'","Text = 'Choose the application you want to learn, or open its saved lessons.'",1)
f=f.replace("Text = 'Selection details'","Text = 'About your selection'",1)
f=f.replace("Text = 'Click an object in Explorer to inspect it. Double-click a [+] or [-] branch to expand or collapse it. Open Explain for its code or Details for statements and evidence.'", "Text = 'Select something on the left to learn what it is. Explain describes its role and connections. Begin with Learn the project if you are new to this application.'")
f=f.replace("Text = 'Ready | source projects are read only'","Text = 'Choose an application to begin learning. DPH reads its files without changing them.'",1)
f=f.replace('Width = 220\nOnChange = LearningClick','Width = 188\nOnChange = LearningClick',1)
write('DPH.UI.Main.fmx',f)
p=read('DPH.UI.Main.pas')
p=p.replace('    WorkspacePageCombo: TComboBox;','    WorkspacePageCombo,LessonPageCombo: TComboBox;\n    SetupTab: TTabItem;\n    SetupScroll: TVertScrollBox;\n    SetupPurpose,AnalysisSettingsTitle: TLabel;\n    AnalysisSettingsLayout: TLayout;\n    SetupButton: TButton;\n    procedure SetupClick(Sender: TObject);',1)
a=p.index('procedure TDPHMainForm.WorkspacePageChange(')
b=p.index('procedure TDPHMainForm.ProjectSearchClick(',a)
p=p[:a]+'''procedure TDPHMainForm.SetupClick(Sender: TObject);
begin WorkspaceTabs.ActiveTab:=SetupTab; end;
procedure TDPHMainForm.WorkspacePageChange(Sender: TObject);
var Index: Integer; Choice: TComboBox;
begin
  if FBinding then Exit;
  if (Sender=WorkspacePageCombo) or (Sender=LessonPageCombo) then begin
    Choice:=Sender as TComboBox;
    if Choice.ItemIndex<0 then Exit;
    for Index:=0 to WorkspaceTabs.TabCount-1 do
      if WorkspaceTabs.Tabs[Index].Text=Choice.Items[Choice.ItemIndex] then begin
        WorkspaceTabs.ActiveTab:=WorkspaceTabs.Tabs[Index]; Break;
      end;
  end;
  if WorkspaceTabs.ActiveTab<>nil then begin
    FBinding:=True;
    try
      WorkspacePageCombo.ItemIndex:=WorkspacePageCombo.Items.IndexOf(WorkspaceTabs.ActiveTab.Text);
      LessonPageCombo.ItemIndex:=LessonPageCombo.Items.IndexOf(WorkspaceTabs.ActiveTab.Text);
    finally FBinding:=False; end;
  end;
end;
'''+p[b:]
p=p.replace('  LearningClick(nil); ShowExplanation; RefreshGraphics;','  LearningClick(nil); ShowExplanation; RefreshGraphics;',1)
p=p.replace('HTML:=FExplanations.TopicHTML(Max(0,LearningTopics.ItemIndex));','HTML:=FExplanations.LessonHTML(Max(0,LearningTopics.ItemIndex));',1)
p=p.replace("  if SameProject then WorkspaceTabs.ActiveTab:=SavedTab;", "  if SameProject then WorkspaceTabs.ActiveTab:=SavedTab else WorkspaceTabs.ActiveTab:=OverviewTab;",1)
p=p.replace("  P:=Pos('#g_',AURL);", "  P:=Pos('#lesson_',AURL);\n  if P>0 then begin\n    ACancel:=True;\n    if TryStrToInt(Copy(AURL,P+8,MaxInt),I) and (I>=0) and (I<LearningTopics.Count) then begin\n      LearningTopics.ItemIndex:=I; LearningClick(nil); WorkspaceTabs.ActiveTab:=OverviewTab;\n    end;\n    Exit;\n  end;\n  P:=Pos('#g_',AURL);",1)
a=p.index("  InspectorMemo.Text:=S.GetValue<string>('name')",p.index('procedure TDPHMainForm.SelectSymbol'))
b=p.index('  RelationsList.Items.Clear;',a)
p=p[:a]+'''  InspectorMemo.Text:=S.GetValue<string>('name')+sLineBreak+sLineBreak+
    'This is a '+S.GetValue<string>('kind')+' in the selected application.'+sLineBreak+sLineBreak+
    'Read Explain to understand its connections and the steps behind it. A routine is a named operation; an event connects an action to that operation.'+sLineBreak+sLineBreak+
    'Source location: '+S.GetValue<string>('range.source')+':'+S.GetValue<Integer>('range.line').ToString+sLineBreak+sLineBreak+
    'Use Learn the project for the guided route. Source details remain available through Prepare lessons.';
'''+p[b:]
p=p.replace("    StatusLabel.Text:=R.MessageText; if FView<>nil then StatusLabel.Text:=StatusLabel.Text+' | '+FView.FlagsText;", "    StatusLabel.Text:=R.MessageText;\n    if (FView<>nil) and not R.Busy and not R.Failed then begin\n      StatusLabel.Text:='Lessons for '+FView.Document.GetValue<string>('entry')+'. Choose Learn the project to continue.';\n      if not FView.Document.GetValue<Boolean>('analysis_complete') then\n        StatusLabel.Text:=StatusLabel.Text+' Some code could not be explained; check unanswered questions.';\n    end;",1)
write('DPH.UI.Main.pas',p)
print('Serialized learning navigation and setup separation written')
