from pathlib import Path
r=Path.cwd();p=r/'DPH.UI.Main.pas';s=p.read_text()
s=s.replace('    DatabaseSchemaTab:TTabItem;', '''    DatabaseERTab:TTabItem;
    DatabaseERPurpose,DatabaseERStatus,DatabaseEREvidenceLabel:TLabel;
    DatabaseERToolbar:THorzScrollBox;
    DatabaseERFilter:TEdit;
    DatabaseERPageSize,DatabaseERZoom,DatabaseERRelations:TComboBox;
    DatabaseERFirst,DatabaseERNext,DatabaseERAll,DatabaseERFocus,DatabaseEROpen,DatabaseSchemaER:TButton;
    DatabaseERScroll:TScrollBox;
    DatabaseERPaint:TPaintBox;
    DatabaseERMemo:TMemo;
    DatabaseERTableStyle,DatabaseERGapStyle,DatabaseERHeaderStyle:TRectangle;
    DatabaseERTextStyle,DatabaseERTitleStyle:TLabel;
    DatabaseSchemaTab:TTabItem;''')
s=s.replace('    procedure DatabaseSchemaFilterChange', '''    procedure DatabaseERFilterChange(Sender:TObject);
    procedure DatabaseERFocusClick(Sender:TObject);
    procedure DatabaseERSelectionChange(Sender:TObject);
    procedure DatabaseEROpenClick(Sender:TObject);
    procedure DatabaseERResize(Sender:TObject);
    procedure DatabaseERPaintPaint(Sender:TObject;Canvas:TCanvas);
    procedure DatabaseERMouseDown(Sender:TObject;Button:TMouseButton;Shift:TShiftState;X,Y:Single);
    procedure DatabaseSchemaFilterChange''',1)
s=s.replace('    FDatabaseSchema:TJSONObject;', '''    FDatabaseER:TJSONObject;
    FDatabaseEROffset:Integer;
    FDatabaseERFocusID,FDatabaseEREvidenceID:string;
    FDatabaseERScale:Single;
    function DatabaseERRect(AIndex:Integer):TRectF;
    procedure DatabaseEREvidence(const AID:string);
    FDatabaseSchema:TJSONObject;''')
# Delphi fields must precede private methods.
s=s.replace('    function DatabaseERRect(AIndex:Integer):TRectF;\n    procedure DatabaseEREvidence(const AID:string);\n','')
s=s.replace('    procedure RefreshGraphics;', '    function DatabaseERRect(AIndex:Integer):TRectF;\n    procedure DatabaseEREvidence(const AID:string);\n    procedure RefreshGraphics;')
s=s.replace('  FDatabaseSchemaRows.Free;FDatabaseSchema.Free;', '  FDatabaseER.Free;\n  FDatabaseSchemaRows.Free;FDatabaseSchema.Free;')
s=s.replace('FDatabaseSchemaRows.Clear;FreeAndNil(FDatabaseSchema);DatabaseSchemaFilterChange(nil);','FDatabaseSchemaRows.Clear;FreeAndNil(FDatabaseSchema);DatabaseSchemaFilterChange(nil);FDatabaseERFocusID:=\'\';FDatabaseEREvidenceID:=\'\';DatabaseERFilterChange(nil);')
s=s.replace('FDatabaseSchema:=TDPHDatabaseSchema.Inspect(FView);DatabaseSchemaFilterChange(nil);',"FDatabaseSchema:=TDPHDatabaseSchema.Inspect(FView);DatabaseSchemaFilterChange(nil);FDatabaseERFocusID:='';FDatabaseEREvidenceID:='';DatabaseERFilterChange(nil);")
methods=r'''procedure TDPHMainForm.DatabaseERFilterChange(Sender:TObject);
var V:TJSONValue;Edge:TJSONObject;Limit,MaxColumns:Integer;
begin
 if FDatabaseSchemaRows=nil then Exit;
 Limit:=StrToIntDef(DatabaseERPageSize.Selected.Text,30);
 if Sender=DatabaseERNext then Inc(FDatabaseEROffset,Limit) else FDatabaseEROffset:=0;
 if Sender=DatabaseERAll then begin FDatabaseERFocusID:='';DatabaseERFilter.Text:='';end;
 FDatabaseEREvidenceID:='';DatabaseEROpen.Enabled:=False;DatabaseERRelations.Items.Clear;FreeAndNil(FDatabaseER);
 MaxColumns:=Max(1,Min(32,Trunc((DatabaseERTableStyle.Height-DatabaseERHeaderStyle.Height-DatabaseERTextStyle.Height*2)/Max(1,DatabaseERTextStyle.Height))));
 FDatabaseER:=TDPHDatabaseSchema.Diagram(FDatabaseSchema,DatabaseERFilter.Text,FDatabaseERFocusID,FDatabaseEROffset,Limit,MaxColumns);
 FDatabaseERScale:=StrToIntDef(StringReplace(DatabaseERZoom.Selected.Text,'%','',[]),100)/100;
 for V in FDatabaseER.GetValue<TJSONArray>('edges') do begin Edge:=V as TJSONObject;
  DatabaseERRelations.Items.Add('FK '+IntToStr(DatabaseERRelations.Items.Count+1)+': '+Edge.GetValue<string>('from_name')+' -> '+Edge.GetValue<string>('to_name')+' | '+Edge.GetValue<string>('state'));
 end;
 DatabaseERNext.Enabled:=FDatabaseER.GetValue<Boolean>('has_next');
 DatabaseERStatus.Text:=Format('PARTIAL schema | %d of %d matching tables from %d | %d related FKs (%d omitted) | %d source gaps; %d unresolved FKs. Blue = captured links; orange = gaps. Cardinality/deployment unverified.',[FDatabaseER.GetValue<Integer>('shown_tables'),FDatabaseER.GetValue<Integer>('matching_tables'),FDatabaseEROffset,FDatabaseER.GetValue<Integer>('related_foreign_keys'),FDatabaseER.GetValue<Integer>('omitted_foreign_keys'),FDatabaseER.GetValue<Integer>('source_gaps'),FDatabaseER.GetValue<Integer>('unresolved_foreign_keys')]);
 DatabaseERMemo.Text:=FDatabaseER.GetValue<string>('qualification')+sLineBreak+sLineBreak+'PK = declared primary key; FK = declared foreign key; UQ = declared unique key. A badge describes captured membership, not deployed enforcement. Click a table for its full column/key evidence, or choose FK evidence in the command strip.';
 if FDatabaseER.GetValue<Integer>('shown_tables')=0 then DatabaseERMemo.Lines.Add('No matching captured tables. Clear the text filter, click All tables, or attach approved SQL resources and reassess.');
 if FDatabaseERFocusID<>'' then DatabaseERMemo.Lines.Add('Focus includes the selected captured table and its directly linked neighbors; the text filter still applies.');
 DatabaseERResize(nil);
end;
procedure TDPHMainForm.DatabaseERFocusClick(Sender:TObject);
var Row:TJSONObject;
begin
 FDatabaseERFocusID:='';
 if (DatabaseSchemaList.ItemIndex>=0) and (DatabaseSchemaList.ItemIndex<FDatabaseSchemaRows.Count) then begin
  Row:=FDatabaseSchemaRows[DatabaseSchemaList.ItemIndex];
  if (Row.GetValue<string>('kind')='table') and (Row.GetValue<string>('status')='declared header') then FDatabaseERFocusID:=Row.GetValue<string>('id')
  else Row.TryGetValue<string>('declaration_id',FDatabaseERFocusID);
 end;
 DatabaseERFilter.Text:='';DatabaseERFilterChange(nil);WorkspaceTabs.ActiveTab:=DatabaseERTab;
 if FDatabaseERFocusID='' then DatabaseERMemo.Lines.Add('No captured table/column/key selected in Database schema; showing all captured tables.');
end;
function TDPHMainForm.DatabaseERRect(AIndex:Integer):TRectF;
var W,H,Left,Top:Single;Columns:Integer;
begin
 W:=(DatabaseERTableStyle.Width+DatabaseERTableStyle.Margins.Right)*FDatabaseERScale;H:=(DatabaseERTableStyle.Height+DatabaseERTableStyle.Margins.Bottom)*FDatabaseERScale;
 Columns:=Max(1,Trunc((DatabaseERPaint.Width-DatabaseERTableStyle.Margins.Left*2*FDatabaseERScale)/Max(1,W)));
 Left:=DatabaseERTableStyle.Margins.Left*FDatabaseERScale+(AIndex mod Columns)*W;Top:=DatabaseERTableStyle.Margins.Top*FDatabaseERScale+(AIndex div Columns)*H;
 Result:=RectF(Left,Top,Left+DatabaseERTableStyle.Width*FDatabaseERScale,Top+DatabaseERTableStyle.Height*FDatabaseERScale);
end;
procedure TDPHMainForm.DatabaseERResize(Sender:TObject);
var Count:Integer;
begin
 if FDatabaseER=nil then Exit;
 DatabaseERPaint.Width:=Max(DatabaseERScroll.Width-24,(DatabaseERTableStyle.Width+DatabaseERTableStyle.Margins.Left*2+DatabaseERTableStyle.Margins.Right)*FDatabaseERScale);
 Count:=FDatabaseER.GetValue<TJSONArray>('nodes').Count;
 if Count=0 then DatabaseERPaint.Height:=Max(100,DatabaseERScroll.Height-24)
 else DatabaseERPaint.Height:=DatabaseERRect(Count-1).Bottom+DatabaseERTableStyle.Margins.Bottom*FDatabaseERScale;
 DatabaseERPaint.Repaint;
end;
procedure TDPHMainForm.DatabaseERPaintPaint(Sender:TObject;Canvas:TCanvas);
var Nodes,Edges:TJSONArray;V,Column:TJSONValue;Node,Edge:TJSONObject;I,J,A,B:Integer;R,Header,TextRect:TRectF;P1,P2,P3,P4,P5,P6:TPointF;Scale,Pad,RowHeight,Lane:Single;Style:TRectangle;Text:string;
begin
 Canvas.Fill.Color:=TAlphaColors.White;Canvas.FillRect(DatabaseERPaint.LocalRect,0,0,[],1);
 if FDatabaseER=nil then Exit;Nodes:=FDatabaseER.GetValue<TJSONArray>('nodes');Edges:=FDatabaseER.GetValue<TJSONArray>('edges');Scale:=FDatabaseERScale;Pad:=DatabaseERTextStyle.Margins.Left*Scale;RowHeight:=DatabaseERTextStyle.Height*Scale;
 Canvas.Font.Assign(DatabaseERTextStyle.TextSettings.Font);Canvas.Font.Size:=Canvas.Font.Size*Scale;
 if Nodes.Count=0 then begin Canvas.Fill.Color:=DatabaseERTextStyle.TextSettings.FontColor;Canvas.FillText(DatabaseERPaint.LocalRect,'No matching captured tables. Clear filters or attach SQL and reassess.',True,1,[],TTextAlign.Center,TTextAlign.Center);Exit;end;
 for I:=0 to Edges.Count-1 do begin Edge:=Edges.Items[I] as TJSONObject;if not Edge.GetValue<Boolean>('draw') then Continue;A:=-1;B:=-1;
  for J:=0 to Nodes.Count-1 do begin Node:=Nodes.Items[J] as TJSONObject;if Node.GetValue<string>('id')=Edge.GetValue<string>('from') then A:=J;if Node.GetValue<string>('id')=Edge.GetValue<string>('to') then B:=J;end;
  if (A<0) or (B<0) then Continue;
  Canvas.Stroke.Assign(DatabaseERTableStyle.Stroke);if not Edge.GetValue<Boolean>('resolved') then begin Canvas.Stroke.Assign(DatabaseERGapStyle.Stroke);Canvas.Stroke.Dash:=TStrokeDash.Dash;end;
  Lane:=(8+(I mod 3)*8)*Scale;R:=DatabaseERRect(A);Header:=DatabaseERRect(B);
  P1:=PointF(R.Right,R.CenterPoint.Y);P2:=PointF(R.Right+Lane,P1.Y);P3:=PointF(P2.X,Max(R.Bottom,Header.Bottom)+Lane);P4:=PointF(Header.Left-Lane,P3.Y);P5:=PointF(P4.X,Header.CenterPoint.Y);P6:=PointF(Header.Left,P5.Y);
  Canvas.DrawLine(P1,P2,1);Canvas.DrawLine(P2,P3,1);Canvas.DrawLine(P3,P4,1);Canvas.DrawLine(P4,P5,1);Canvas.DrawLine(P5,P6,1);
  Canvas.DrawLine(P6,PointF(P6.X-5*Scale,P6.Y-4*Scale),1);Canvas.DrawLine(P6,PointF(P6.X-5*Scale,P6.Y+4*Scale),1);
  Canvas.Fill.Color:=Canvas.Stroke.Color;Canvas.FillText(RectF(P2.X+2*Scale,P2.Y-RowHeight,P2.X+55*Scale,P2.Y),'FK '+IntToStr(I+1),False,1,[],TTextAlign.Leading,TTextAlign.Center);
 end;
 for I:=0 to Nodes.Count-1 do begin Node:=Nodes.Items[I] as TJSONObject;R:=DatabaseERRect(I);Style:=DatabaseERTableStyle;if Node.GetValue<Boolean>('partial') then Style:=DatabaseERGapStyle;
  Canvas.Fill.Assign(Style.Fill);Canvas.FillRect(R,4,4,AllCorners,1);Canvas.Stroke.Assign(Style.Stroke);Canvas.DrawRect(R,4,4,AllCorners,1);
  Header:=RectF(R.Left,R.Top,R.Right,R.Top+DatabaseERHeaderStyle.Height*Scale);Canvas.Fill.Assign(DatabaseERHeaderStyle.Fill);Canvas.FillRect(Header,0,0,[],1);
  Canvas.Font.Assign(DatabaseERTitleStyle.TextSettings.Font);Canvas.Font.Size:=Canvas.Font.Size*Scale;Canvas.Fill.Color:=DatabaseERTitleStyle.TextSettings.FontColor;
  TextRect:=Header;TextRect.Inflate(-Pad,-2*Scale);Canvas.FillText(TextRect,Node.GetValue<string>('name'),True,1,[],TTextAlign.Leading,TTextAlign.Center);
  Canvas.Font.Assign(DatabaseERTextStyle.TextSettings.Font);Canvas.Font.Size:=Canvas.Font.Size*Scale;Canvas.Fill.Color:=DatabaseERTextStyle.TextSettings.FontColor;J:=0;
  for Column in Node.GetValue<TJSONArray>('columns') do begin
   TextRect:=RectF(R.Left+Pad,Header.Bottom+J*RowHeight,R.Right-Pad,Header.Bottom+(J+1)*RowHeight);Text:=Column.GetValue<string>('badges');if Text<>'' then Text:='['+Text+'] ';Text:=Text+Column.GetValue<string>('name')+' : '+Column.GetValue<string>('declared_type');Canvas.FillText(TextRect,Text,False,1,[],TTextAlign.Leading,TTextAlign.Center);Inc(J);
  end;
  TextRect:=RectF(R.Left+Pad,R.Bottom-RowHeight*2,R.Right-Pad,R.Bottom-RowHeight);Canvas.FillText(TextRect,IntToStr(J)+'/'+Node.GetValue<Integer>('column_count').ToString+' columns | click table for evidence',False,1,[],TTextAlign.Leading,TTextAlign.Center);
  if Node.GetValue<Boolean>('partial') then Text:='GAPS / TRUNCATION - inspect evidence' else Text:='Captured declaration; live schema unverified';TextRect.Offset(0,RowHeight);Canvas.Fill.Color:=Style.Stroke.Color;Canvas.FillText(TextRect,Text,False,1,[],TTextAlign.Leading,TTextAlign.Center);
 end;
end;
procedure TDPHMainForm.DatabaseEREvidence(const AID:string);
var V,W:TJSONValue;Row:TJSONObject;Text:string;
begin
 if FDatabaseSchema=nil then Exit;
 FDatabaseEREvidenceID:='';DatabaseEROpen.Enabled:=False;
 for V in FDatabaseSchema.GetValue<TJSONArray>('rows') do begin Row:=V as TJSONObject;if Row.GetValue<string>('id')<>AID then Continue;
  FDatabaseEREvidenceID:=AID;Text:=TDPHDatabaseSchema.Describe(Row);
  if Row.GetValue<string>('kind')='table' then begin
   Text:=Text+sLineBreak+sLineBreak+'CAPTURED COLUMNS AND KEYS (full inventory, up to 10000 rows)'+sLineBreak;
   for W in FDatabaseSchema.GetValue<TJSONArray>('rows') do if W.GetValue<string>('declaration_id','')=AID then Text:=Text+W.GetValue<string>('kind')+' | '+W.GetValue<string>('name')+' | '+W.GetValue<string>('declared_type','')+' | '+W.GetValue<string>('key_kind','')+' | '+W.GetValue<string>('relationship_status','')+' | '+W.GetValue<string>('reason')+sLineBreak;
  end;
  DatabaseERMemo.Text:=Text+sLineBreak+sLineBreak+FDatabaseER.GetValue<string>('qualification');DatabaseEROpen.Enabled:=True;Exit;
 end;
end;
procedure TDPHMainForm.DatabaseERSelectionChange(Sender:TObject);
begin
 if (FDatabaseER=nil) or (DatabaseERRelations.ItemIndex<0) or (DatabaseERRelations.ItemIndex>=FDatabaseER.GetValue<TJSONArray>('edges').Count) then Exit;
 DatabaseEREvidence(FDatabaseER.GetValue<TJSONArray>('edges').Items[DatabaseERRelations.ItemIndex].GetValue<string>('key_id'));
end;
procedure TDPHMainForm.DatabaseERMouseDown(Sender:TObject;Button:TMouseButton;Shift:TShiftState;X,Y:Single);
var I:Integer;
begin
 if (FDatabaseER=nil) or (Button<>TMouseButton.mbLeft) then Exit;
 for I:=0 to FDatabaseER.GetValue<TJSONArray>('nodes').Count-1 do if DatabaseERRect(I).Contains(PointF(X,Y)) then begin DatabaseEREvidence(FDatabaseER.GetValue<TJSONArray>('nodes').Items[I].GetValue<string>('id'));Exit;end;
end;
procedure TDPHMainForm.DatabaseEROpenClick(Sender:TObject);
var I:Integer;V:TJSONValue;
begin
 if (FDatabaseSchema=nil) or (FDatabaseEREvidenceID='') then Exit;I:=0;
 for V in FDatabaseSchema.GetValue<TJSONArray>('rows') do begin
  if V.GetValue<string>('id')=FDatabaseEREvidenceID then begin
   DatabaseSchemaKind.ItemIndex:=0;DatabaseSchemaState.ItemIndex:=0;DatabaseSchemaFilter.Text:='';DatabaseSchemaFilterChange(nil);
   if I>=250 then begin FDatabaseSchemaOffset:=(I div 250)*250-250;DatabaseSchemaFilterChange(DatabaseSchemaNext);end;
   DatabaseSchemaList.ItemIndex:=I mod 250;DatabaseSchemaSelectionChange(nil);WorkspaceTabs.ActiveTab:=DatabaseSchemaTab;Exit;
  end;Inc(I);
 end;
 DatabaseERMemo.Lines.Add('Evidence target is no longer in this captured schema. Rebuild the diagram.');
end;
'''
at=s.index('procedure TDPHMainForm.DatabaseSchemaFilterChange');s=s[:at]+methods+s[at:];p.write_bytes(s.replace('\n','\r\n').encode())
p=r/'DPH.UI.Main.fmx';s=p.read_text();s=s.replace("'Database schema'\n'Knowledge links'", "'Database schema'\n'Database ER diagram'\n'Knowledge links'",1)
at=s.index('object DatabaseSchemaStatus:')
# Insert the ER entry inside the existing schema command strip, before its closing end.
target="Enabled = False\nend\nend\nobject DatabaseSchemaStatus:"
replacement="Enabled = False\nend\nobject DatabaseSchemaER: TButton\nPosition.X = 1397\nPosition.Y = 0\nWidth = 150\nHeight = 28\nText = 'View ER diagram'\nOnClick = DatabaseERFocusClick\nend\nend\nobject DatabaseSchemaStatus:"
assert target in s;s=s.replace(target,replacement,1)
tab='''object DatabaseERTab: TTabItem
Text = 'Database ER diagram'
object DatabaseERPurpose: TLabel
Align = Top
Height = 64
Margins.Left = 12
Margins.Right = 12
WordWrap = True
Text = 'Tables and declared foreign keys from captured SQL. Click a table or choose FK evidence; read details below. Orange marks gaps. Scroll commands sideways. No SQL runs.'
StyledSettings = []
TextSettings.FontColor = xFF146CB4
end
object DatabaseERToolbar: THorzScrollBox
Align = Top
Height = 44
ShowScrollBars = True
object DatabaseERFilter: TEdit
Position.X = 8
Width = 240
Height = 28
TextPrompt = 'Find table, schema or source'
OnChange = DatabaseERFilterChange
end
object DatabaseERFirst: TButton
Position.X = 256
Width = 90
Height = 28
Text = 'First page'
OnClick = DatabaseERFilterChange
end
object DatabaseERNext: TButton
Position.X = 354
Width = 90
Height = 28
Text = 'Next page'
OnClick = DatabaseERFilterChange
Enabled = False
end
object DatabaseERPageSize: TComboBox
Position.X = 452
Width = 110
Height = 28
Hint = 'Maximum tables per diagram page'
ShowHint = True
Items.Strings = (
'15'
'30'
'60')
ItemIndex = 1
OnChange = DatabaseERFilterChange
end
object DatabaseERZoom: TComboBox
Position.X = 570
Width = 100
Height = 28
Hint = 'Diagram zoom'
ShowHint = True
Items.Strings = (
'75%'
'100%'
'125%'
'150%'
'200%')
ItemIndex = 1
OnChange = DatabaseERFilterChange
end
object DatabaseERAll: TButton
Position.X = 678
Width = 100
Height = 28
Text = 'All tables'
OnClick = DatabaseERFilterChange
end
object DatabaseERFocus: TButton
Position.X = 786
Width = 170
Height = 28
Text = 'Focus schema selection'
OnClick = DatabaseERFocusClick
end
object DatabaseERRelations: TComboBox
Position.X = 964
Width = 350
Height = 28
Hint = 'FK numbers match the diagram arrows; unresolved and off-page evidence remains selectable'
ShowHint = True
OnChange = DatabaseERSelectionChange
end
object DatabaseEROpen: TButton
Position.X = 1322
Width = 140
Height = 28
Text = 'Open evidence'
OnClick = DatabaseEROpenClick
Enabled = False
end
end
object DatabaseERStatus: TLabel
Align = Top
Height = 48
Margins.Left = 12
Margins.Right = 12
WordWrap = True
Text = 'Open a captured project. Schema completeness and deployed behavior remain unverified.'
end
object DatabaseERScroll: TScrollBox
Align = Client
Margins.Left = 12
Margins.Right = 12
ShowScrollBars = True
OnResize = DatabaseERResize
object DatabaseERPaint: TPaintBox
Width = 1000
Height = 360
OnPaint = DatabaseERPaintPaint
OnMouseDown = DatabaseERMouseDown
end
end
object DatabaseERSplitter: TSplitter
Align = Bottom
Height = 6
end
object DatabaseEREvidenceLabel: TLabel
Align = Bottom
Height = 22
Margins.Left = 12
Margins.Right = 12
Text = 'Selected table or foreign-key evidence (scroll for details)'
end
object DatabaseERMemo: TMemo
Align = Bottom
Height = 90
Margins.Left = 12
Margins.Right = 12
Margins.Bottom = 12
ReadOnly = True
WordWrap = True
ShowScrollBars = True
end
end
'''
at=s.index('object HistoryTab:');s=s[:at]+tab+s[at:]
styles='''object DatabaseERTableStyle: TRectangle
Visible = False
Width = 300
Height = 240
Margins.Left = 32
Margins.Top = 24
Margins.Right = 88
Margins.Bottom = 56
Fill.Color = xFFF3F8FD
Stroke.Color = xFF146CB4
Stroke.Thickness = 1.5
end
object DatabaseERGapStyle: TRectangle
Visible = False
Width = 300
Height = 240
Fill.Color = xFFFFF6EC
Stroke.Color = xFFF28C28
Stroke.Thickness = 2
end
object DatabaseERHeaderStyle: TRectangle
Visible = False
Width = 300
Height = 42
Fill.Color = xFF146CB4
Stroke.Color = xFF146CB4
end
object DatabaseERTextStyle: TLabel
Visible = False
Width = 280
Height = 20
Margins.Left = 10
StyledSettings = []
TextSettings.Font.Family = 'Segoe UI'
TextSettings.Font.Size = 11
TextSettings.FontColor = xFF222222
end
object DatabaseERTitleStyle: TLabel
Visible = False
Width = 280
Height = 38
StyledSettings = []
TextSettings.Font.Family = 'Segoe UI'
TextSettings.Font.Size = 14
TextSettings.Font.Style = [fsBold]
TextSettings.FontColor = xFFFFFFFF
end
'''
at=s.index('object GraphNodeStyle:');s=s[:at]+styles+s[at:];p.write_bytes(s.replace('\n','\r\n').encode())
print('IDE-editable ER page and native painting/navigation added')
