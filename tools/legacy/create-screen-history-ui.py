from pathlib import Path
r=Path.cwd();p=r/'DPH.UI.Main.fmx';s=p.read_text(encoding='utf-8-sig');s=s.replace("'Action purposes'\n", "'Action purposes'\n'Screen history'\n",1)
tab='''object HistoryTab: TTabItem
Text = 'Screen history'
object HistoryPurpose: TLabel
Align = Top
Height = 64
Margins.Left = 12
Margins.Right = 12
WordWrap = True
Text = 'Compare imported screen evidence. Scroll commands sideways and this page down for images and details.'
StyledSettings = []
TextSettings.FontColor = xFF146CB4
end
object HistoryToolbar: THorzScrollBox
Align = Top
Height = 100
ShowScrollBars = True
'''
for name,kind,x,y,w,text,event in [
 ('HistoryBeforeCombo','TComboBox',8,22,350,'','HistorySelectionChange'),('HistoryAfterCombo','TComboBox',366,22,350,'','HistorySelectionChange'),
 ('HistoryModeCombo','TComboBox',8,58,160,'','HistoryModeChange'),
 ('HistoryBeforePath','TEdit',176,58,220,'Before relative form path (optional)','HistorySelectionChange'),('HistoryAfterPath','TEdit',404,58,220,'After relative form path (optional)','HistorySelectionChange'),
 ('HistoryCompareButton','TButton',632,58,100,'Compare','HistoryCompareClick'),('HistorySwapButton','TButton',740,58,100,'Swap sides','HistoryCompareClick'),
 ('HistoryFilter','TEdit',848,58,220,'Filter captured layout changes','HistoryFilterChange'),('HistoryFirstButton','TButton',1076,58,90,'First page','HistoryFilterChange'),('HistoryNextButton','TButton',1174,58,90,'Next page','HistoryFilterChange')]:
 tab+=f'object {name}: {kind}\nPosition.X = {x}\nPosition.Y = {y}\nWidth = {w}\nHeight = 28\n'
 if text:tab+=f"{'TextPrompt' if kind=='TEdit' else 'Text'} = '{text}'\n"
 tab+=f"{'OnClick' if kind=='TButton' else 'OnChange'} = {event}\n"
 if name=='HistoryModeCombo':tab+="Items.Strings = (\n'Imported images'\n'Captured layouts')\nItemIndex = 0\n"
 if name=='HistoryNextButton':tab+='Enabled = False\n'
 tab+='end\n'
for name,x,text in [('HistoryBeforeSelectorLabel',8,'BEFORE screenshot record'),('HistoryAfterSelectorLabel',366,'AFTER screenshot record')]:
 # Labels have no event fields and need no Pascal member for streaming.
 tab+=f"object {name}: TLabel\nPosition.X = {x}\nPosition.Y = 0\nWidth = 350\nHeight = 20\nText = '{text}'\nend\n"
tab+='''end
object HistoryStatus: TLabel
Align = Top
Height = 48
Margins.Left = 12
Margins.Right = 12
WordWrap = True
Text = 'Import screenshots first. This page lists the newest 200 records.'
end
object HistoryBody: TVertScrollBox
Align = Client
Margins.Left = 12
Margins.Right = 12
Margins.Bottom = 12
ShowScrollBars = True
object HistoryContent: TLayout
Align = Top
Height = 620
object HistoryGrid: TGridPanelLayout
Align = Top
Height = 220
ColumnCollection = <
item Value = 33.3333333333333 end
item Value = 33.3333333333333 end
item Value = 33.3333333333334 end>
RowCollection = <item Value = 100 end>
ControlCollection = <
item Column = 0 Row = 0 Control = HistoryBeforePanel end
item Column = 1 Row = 0 Control = HistoryAfterPanel end
item Column = 2 Row = 0 Control = HistoryDifferencePanel end>
'''
for stem,label in [('Before','BEFORE'),('After','AFTER'),('Difference','PIXEL DIFFERENCE')]:
 tab+=f'''object History{stem}Panel: TLayout
Margins.Left = 3
Margins.Right = 3
object History{stem}Title: TLabel
Align = Top
Height = 28
Text = '{label}'
end
object History{stem}Background: TRectangle
Align = Client
Fill.Color = xFFFFFFFF
Stroke.Kind = None
object History{stem}Image: TImage
Align = Client
WrapMode = Fit
end
object History{stem}Paint: TPaintBox
Align = Client
Visible = False
OnPaint = HistoryPaint
end
end
end
'''
tab+='''end
object HistoryLegend: TLayout
Align = Top
Height = 28
object HistoryBeforeLegend: TRectangle
Position.X = 4
Position.Y = 8
Width = 12
Height = 12
Fill.Color = xFF146CB4
Stroke.Kind = None
end
object HistoryAfterLegend: TRectangle
Position.X = 140
Position.Y = 8
Width = 12
Height = 12
Fill.Color = xFFF28C28
Stroke.Kind = None
end
object HistoryLegendText: TLabel
Align = Client
Text = '     Blue: Before        Orange: After layout; red/magenta: pixel changes'
end
end
object HistoryList: TListBox
Align = Top
Height = 96
OnChange = HistoryRowClick
end
object HistoryMemo: TMemo
Align = Client
ReadOnly = True
WordWrap = True
ShowScrollBars = True
end
end
end
end
'''
assert 'object HistoryTab:' not in s;s=s.replace('object ActionPurposeTab: TTabItem',tab+'object ActionPurposeTab: TTabItem',1);p.write_text(s,encoding='utf-8')
