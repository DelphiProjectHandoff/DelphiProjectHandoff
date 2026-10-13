from pathlib import Path
r=Path.cwd()
p=r/'DPH.Workspace.Model.pas';s=p.read_text(encoding='utf-8-sig');s=s.replace('    function ProjectMembers: TJSONArray;','    function ProjectMembers: TJSONArray;\n    function FileFormats: TJSONObject;\n    class function DescribeFileFormat(ARow:TJSONObject):string; static;\n    class function FileFormatContractTitle(ARow:TJSONObject):string; static;')
s=s.replace('implementation\nuses System.StrUtils','implementation\nuses System.RegularExpressions, System.StrUtils')
code=r"""
function TDPHWorkspaceView.FileFormats:TJSONObject;
var Rows,Files,Nodes,Shape:TJSONArray; F,N,V,W:TJSONValue; FileRow,Node,Row,Range,Owner:TJSONObject;
    Path,Kind,Text,API,Direction,Extension,Encoding,Key,Member,ValueType:string;
    Tokens:TMatchCollection; Seen:TDictionary<string,Boolean>; I,J,K,Depth,Parent,ShapeCount,BestSize:Integer;
  procedure Add(const AName,ADirection,AFormat,AEncoding:string; ANode:TJSONObject);
  begin
   if Rows.Count>=10000 then begin if Result.GetValue('limit')=nil then Result.AddPair('limit','File-format inventory truncated at 10000 candidates.');Exit;end;
   Range:=TJSONObject.Create.AddPair('source',Path).AddPair('line',TJSONNumber.Create(ANode.GetValue<Integer>('line',1))).AddPair('column',TJSONNumber.Create(ANode.GetValue<Integer>('column',1))).AddPair('start',TJSONNumber.Create(ANode.GetValue<Integer>('start',0))).AddPair('end',TJSONNumber.Create(ANode.GetValue<Integer>('end',0)));
   Row:=TJSONObject.Create;Rows.AddElement(Row);
   Key:=Path+'|'+Range.GetValue('start').Value+'|'+AName+'|'+ADirection;
   Row.AddPair('id',Key).AddPair('name',AName).AddPair('direction',ADirection).AddPair('format',AFormat).AddPair('encoding',AEncoding).AddPair('source',Path).AddPair('source_hash',FileRow.GetValue<string>('sha256','')).AddPair('generation_id',FDocument.GetValue('generation_id').Clone as TJSONValue).AddPair('range',Range).AddPair('schema',TJSONArray.Create).AddPair('producer','unknown').AddPair('consumer','unknown').AddPair('target_key','');
   Owner:=nil;BestSize:=MaxInt;
   for W in FDocument.GetValue<TJSONArray>('semantics.symbols') do
    if MatchText(W.GetValue<string>('kind'),['procedure','function','constructor','destructor']) and (W.GetValue<string>('range.source')=Path) and (W.GetValue<Integer>('range.start')<=ANode.GetValue<Integer>('start',0)) and (W.GetValue<Integer>('range.end')>=ANode.GetValue<Integer>('end',0)) and (W.GetValue<Integer>('range.end')-W.GetValue<Integer>('range.start')<BestSize) then begin Owner:=W as TJSONObject;BestSize:=W.GetValue<Integer>('range.end')-W.GetValue<Integer>('range.start');end;
   if Owner<>nil then begin
    Row.RemovePair('target_key').Free;Row.AddPair('target_key',Owner.GetValue<string>('key'));
    if ADirection='export' then Member:='producer' else Member:='consumer';
    Row.RemovePair(Member).Free;Row.AddPair(Member,Owner.GetValue<string>('name')+' (enclosing captured routine; API binding/execution unverified)');
   end;
  end;
begin
 Result:=TJSONObject.Create;Rows:=TJSONArray.Create;Result.AddPair('rows',Rows);
 Result.AddPair('qualification','Source format candidates and captured resource shape only. API spellings, extensions and enclosing routines do not prove runtime dispatch, an accepted schema, actual encoding or successful import/export. Scalar values and literal paths are omitted. Captured resource decoding is distinct from a file-transfer encoding contract. Dynamic paths, defaults, opaque resources, parser gaps and missing structure remain unknown. Record a named contract and review it against evidence. No target code or file-transfer API executes.');
 Seen:=TDictionary<string,Boolean>.Create;
 try
  Files:=FDocument.GetValue<TJSONArray>('syntax.files');
  for F in Files do begin
   FileRow:=F as TJSONObject;Path:=FileRow.GetValue<string>('path');Extension:=LowerCase(ExtractFileExt(Path));
   if not FileRow.TryGetValue<TJSONArray>('ir.nodes',Nodes) then Continue;
   if MatchText(Extension,['.json','.xml','.ini']) then begin
    Node:=TJSONObject.Create;try Add(Path,'captured resource',Extension,'Captured source decoding: '+FileRow.GetValue<string>('encoding','unknown')+'; transfer encoding unknown',Node);finally Node.Free;end;
    Shape:=Row.GetValue<TJSONArray>('schema');ShapeCount:=0;
    for N in Nodes do if MatchText(N.GetValue<string>('kind'),['json_object','json_array','json_value','xml_element','xml_attribute','ini_section','ini_value']) then begin
     Inc(ShapeCount);if ShapeCount>250 then Continue;Member:=N.GetValue<string>('name');
     if (Length(Member)>128) or not TRegEx.IsMatch(Member,'^[A-Za-z0-9_./~:-]*$') then Member:='<nonidentifier member omitted>';
     ValueType:=N.GetValue<string>('kind');Text:=N.GetValue<string>('value','');
     if ValueType='json_value' then begin
      if Text.StartsWith('"') then ValueType:='JSON string' else if Text='null' then ValueType:='JSON null' else if MatchText(Text,['true','false']) then ValueType:='JSON boolean' else ValueType:='JSON numeric candidate';
     end;
     Shape.AddElement(TJSONObject.Create.AddPair('member',Member).AddPair('shape',ValueType));
    end;
    Row.AddPair('shape_count',TJSONNumber.Create(ShapeCount));if ShapeCount>250 then Row.AddPair('shape_limit','Captured structure display truncated to first 250 members.');
    Row.AddPair('structure_basis','Observed resource shape, not a required/optional schema contract. Scalar values omitted; missing/opaque structure remains unknown.');
   end;
   for N in Nodes do begin
    Node:=N as TJSONObject;if Node.GetValue<string>('kind')<>'expression' then Continue;
    Parent:=Node.GetValue<Integer>('parent',-1);if (Parent>=0) and (Parent<Nodes.Count) and (Nodes[Parent].GetValue<string>('kind')='expression') then Continue;
    Text:=Node.GetValue<string>('value','');if (Text='') or (Length(Text)>16000) then Continue;
    // IR expression text is bounded by the parser. Quoted literals are single tokens.
    Tokens:=TRegEx.Matches(Text,'''(?:[^'']|'''')*''|[A-Za-z_][A-Za-z0-9_]*|[^\s]');
    for I:=0 to Tokens.Count-2 do begin
     API:=Tokens[I].Value;if not MatchText(API,['ReadAllText','ReadAllBytes','ReadAllLines','WriteAllText','WriteAllBytes','WriteAllLines','LoadFromFile','SaveToFile']) or (Tokens[I+1].Value<>'(') then Continue;
     if (I=0) or (Tokens[I-1].Value<>'.') then Continue;
     Direction:='import';if MatchText(API,['WriteAllText','WriteAllBytes','WriteAllLines','SaveToFile']) then Direction:='export';
     Key:=Path+'|'+Node.GetValue('start').Value+'|'+IntToStr(I)+'|'+API;if Seen.ContainsKey(Key) then Continue;Seen.Add(Key,True);
     Extension:='unknown; dynamic or unsupported path';J:=I+2;
     if (J+1<Tokens.Count) and Tokens[J].Value.StartsWith('''') and MatchText(Tokens[J+1].Value,[',',')']) then begin
      Extension:=LowerCase(ExtractFileExt(Tokens[J].Value.Trim([''''])));
      if (Length(Extension)>16) or not TRegEx.IsMatch(Extension,'^\.[a-z0-9]+$') then Extension:='unknown; no supported filename extension';
      Extension:=Extension+' (filename candidate; contents unverified)';
     end;
     Encoding:='unknown; default, custom receiver or unsupported encoding';Depth:=1;K:=J;
     while (K<Tokens.Count) and (Depth>0) do begin
      if Tokens[K].Value='(' then Inc(Depth) else if Tokens[K].Value=')' then Dec(Depth);
      if (K+2<Tokens.Count) and SameText(Tokens[K].Value,'TEncoding') and (Tokens[K+1].Value='.') and MatchText(Tokens[K+2].Value,['UTF8','Unicode','BigEndianUnicode','ASCII','Default']) then Encoding:=Tokens[K+2].Value+' (explicit source argument candidate; runtime binding unverified)';
      Inc(K);
     end;
     if MatchText(API,['ReadAllBytes','WriteAllBytes']) then Encoding:='binary byte API candidate; text encoding not established';
     Add(API,Direction,Extension,Encoding,Node);Row.AddPair('structure_basis','Transfer schema unknown; inspect the captured routine and record an explicit contract. Location is the enclosing IR expression.');
    end;
   end;
  end;
 except Result.Free;raise;end;
 Seen.Free;
end;

class function TDPHWorkspaceView.FileFormatContractTitle(ARow:TJSONObject):string;
begin Result:='File format contract '+THashSHA2.GetHashString(ARow.GetValue<string>('id')+#0+ARow.GetValue<string>('source_hash'));end;
class function TDPHWorkspaceView.DescribeFileFormat(ARow:TJSONObject):string;
var V:TJSONValue;
begin
 Result:='FILE FORMAT EVIDENCE'+sLineBreak+ARow.GetValue<string>('name')+' | '+ARow.GetValue<string>('direction')+sLineBreak+
  'Format: '+ARow.GetValue<string>('format')+sLineBreak+'Encoding: '+ARow.GetValue<string>('encoding')+sLineBreak+'Producer: '+ARow.GetValue<string>('producer')+sLineBreak+'Consumer: '+ARow.GetValue<string>('consumer')+sLineBreak+ARow.GetValue<string>('structure_basis','')+sLineBreak;
 for V in ARow.GetValue<TJSONArray>('schema') do Result:=Result+V.GetValue<string>('member')+' : '+V.GetValue<string>('shape')+sLineBreak;
 Result:=Result+ARow.GetValue<string>('shape_limit','')+sLineBreak+'Source: '+ARow.GetValue<string>('source')+' | line '+ARow.GetValue<TJSONObject>('range').GetValue('line').Value+sLineBreak+'SHA256 '+ARow.GetValue<string>('source_hash')+' | generation '+ARow.GetValue('generation_id').Value+sLineBreak;
end;
"""
s=s.replace('function TDPHWorkspaceView.ProjectMembers: TJSONArray;',code+'\nfunction TDPHWorkspaceView.ProjectMembers: TJSONArray;');p.write_text(s,encoding='utf-8')
p=r/'DPH.UI.Main.pas';s=p.read_text(encoding='utf-8-sig');anchor='    DatabaseSchemaTab:TTabItem;';s=s.replace(anchor,'''    FileFormatsTab:TTabItem;
    FileFormatsPurpose,FileFormatsStatus,FileFormatsEvidenceLabel:TLabel;
    FileFormatsToolbar:THorzScrollBox;
    FileFormatsKind:TComboBox;
    FileFormatsFilter:TEdit;
    FileFormatsFirst,FileFormatsNext,FileFormatsSource,FileFormatsExplain,FileFormatsContract:TButton;
    FileFormatsList:TListBox;
    FileFormatsMemo:TMemo;
'''+anchor)
s=s.replace('    procedure DatabaseSchemaFilterChange(Sender:TObject);','''    procedure FileFormatsFilterChange(Sender:TObject);
    procedure FileFormatsSelectionChange(Sender:TObject);
    procedure FileFormatsSourceClick(Sender:TObject);
    procedure FileFormatsExplainClick(Sender:TObject);
    procedure FileFormatsContractClick(Sender:TObject);
    procedure DatabaseSchemaFilterChange(Sender:TObject);''')
s=s.replace('    FDatabaseSchema:TJSONObject;','    FFileFormats:TJSONObject;\n    FFileFormatRows:TList<TJSONObject>;\n    FFileFormatOffset:Integer;\n    FDatabaseSchema:TJSONObject;')
s=s.replace('  FDatabaseSchemaRows:=TList<TJSONObject>.Create;','  FFileFormatRows:=TList<TJSONObject>.Create;\n  FDatabaseSchemaRows:=TList<TJSONObject>.Create;')
s=s.replace('  FDatabaseSchemaRows.Free;FDatabaseSchema.Free;','  FFileFormatRows.Free;FFileFormats.Free;\n  FDatabaseSchemaRows.Free;FDatabaseSchema.Free;')
s=s.replace('  FDatabaseSchemaRows.Clear;FreeAndNil(FDatabaseSchema);DatabaseSchemaFilterChange(nil);','  FFileFormatRows.Clear;FreeAndNil(FFileFormats);FileFormatsFilterChange(nil);\n  FDatabaseSchemaRows.Clear;FreeAndNil(FDatabaseSchema);DatabaseSchemaFilterChange(nil);',1)
s=s.replace('FDatabaseSchema:=TDPHDatabaseSchema.Inspect(FView);','FDatabaseSchema:=TDPHDatabaseSchema.Inspect(FView);\n  FFileFormatRows.Clear;FreeAndNil(FFileFormats);FFileFormats:=FView.FileFormats;FileFormatsFilterChange(nil);')
s=s.replace('RefreshQuestions; DependencyFilterChange(nil); DatabaseSchemaSelectionChange(nil);','RefreshQuestions; DependencyFilterChange(nil); DatabaseSchemaSelectionChange(nil);FileFormatsSelectionChange(nil);')
code=r"""
procedure TDPHMainForm.FileFormatsFilterChange(Sender:TObject);
var V:TJSONValue;Row:TJSONObject;Count:Integer;
begin
 if FFileFormatRows=nil then Exit;
 if Sender=FileFormatsNext then Inc(FFileFormatOffset,250) else FFileFormatOffset:=0;
 FFileFormatRows.Clear;FileFormatsList.Items.Clear;FileFormatsNext.Enabled:=False;FileFormatsSelectionChange(nil);
 if FFileFormats=nil then begin FileFormatsStatus.Text:='Open a captured project to inspect format evidence.';Exit;end;
 Count:=0;
 for V in FFileFormats.GetValue<TJSONArray>('rows') do begin Row:=V as TJSONObject;
  if (FileFormatsKind.ItemIndex>0) and (Row.GetValue<string>('direction')<>FileFormatsKind.Selected.Text) then Continue;
  if (FileFormatsFilter.Text.Trim<>'') and not ContainsText(TDPHWorkspaceView.DescribeFileFormat(Row),FileFormatsFilter.Text.Trim) then Continue;
  if (Count>=FFileFormatOffset) and (FFileFormatRows.Count<250) then begin FFileFormatRows.Add(Row);FileFormatsList.Items.Add(Row.GetValue<string>('direction')+' | '+Row.GetValue<string>('name')+' | '+Row.GetValue<string>('format'));end;Inc(Count);
 end;
 FileFormatsNext.Enabled:=Count>FFileFormatOffset+FFileFormatRows.Count;
 FileFormatsStatus.Text:=Format('%d matches; %d shown from %d. Captured candidates; runtime transfer unobserved. %s',[Count,FFileFormatRows.Count,FFileFormatOffset,FFileFormats.GetValue<string>('limit','')]);
 if FileFormatsList.Count>0 then FileFormatsList.ItemIndex:=0;FileFormatsSelectionChange(nil);
end;
procedure TDPHMainForm.FileFormatsSelectionChange(Sender:TObject);
var Row:TJSONObject;V:TJSONValue;Title:string;
begin
 FileFormatsSource.Enabled:=False;FileFormatsExplain.Enabled:=False;FileFormatsContract.Enabled:=False;
 FileFormatsMemo.Text:='Select a captured file or API candidate. Empty results do not prove there are no import/export formats; unsupported, dynamic and uncaptured transfers remain unknown.';
 if (FFileFormatRows=nil) or (FileFormatsList.ItemIndex<0) or (FileFormatsList.ItemIndex>=FFileFormatRows.Count) then Exit;
 Row:=FFileFormatRows[FileFormatsList.ItemIndex];FileFormatsMemo.Text:=TDPHWorkspaceView.DescribeFileFormat(Row)+sLineBreak+FFileFormats.GetValue<string>('qualification');
 FileFormatsSource.Enabled:=True;FileFormatsExplain.Enabled:=Row.GetValue<string>('target_key')<>'';FileFormatsContract.Enabled:=True;
 Title:=TDPHWorkspaceView.FileFormatContractTitle(Row);
 if FKnowledge<>nil then for V in FKnowledge do if V.GetValue<string>('title')=Title then FileFormatsMemo.Lines.Add(sLineBreak+'SAVED CONTRACT ['+V.GetValue<string>('state')+'] | '+V.GetValue<string>('owner')+sLineBreak+V.GetValue<string>('body'));
end;
procedure TDPHMainForm.FileFormatsSourceClick(Sender:TObject);
var Row,Range:TJSONObject;
begin
 if (FView=nil) or (FileFormatsList.ItemIndex<0) or (FileFormatsList.ItemIndex>=FFileFormatRows.Count) then Exit;
 Row:=FFileFormatRows[FileFormatsList.ItemIndex];Range:=Row.GetValue<TJSONObject>('range');
 if FDetached then begin FileFormatsMemo.Lines.Add('Source is detached. Attach unchanged source to navigate.');Exit;end;
 try SourceMemo.Text:=TDPHKeyboardInspector.ReadSource(FView,FEntry,Row,Range);SourceMemo.CaretPosition:=TCaretPosition.Create(Max(0,Range.GetValue<Integer>('line')-1),0);WorkspaceTabs.ActiveTab:=SourceTab;
 except on E:Exception do FileFormatsMemo.Lines.Add('Source unavailable: '+E.Message);end;
end;
procedure TDPHMainForm.FileFormatsExplainClick(Sender:TObject);
var Key:string;
begin
 if (FView=nil) or (FileFormatsList.ItemIndex<0) or (FileFormatsList.ItemIndex>=FFileFormatRows.Count) then Exit;
 Key:=FFileFormatRows[FileFormatsList.ItemIndex].GetValue<string>('target_key');if Key='' then Exit;
 SelectSymbol(Key);WorkspaceTabs.ActiveTab:=ExplainTab;
end;
procedure TDPHMainForm.FileFormatsContractClick(Sender:TObject);
var Row:TJSONObject;Title:string;I:Integer;
begin
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft before recording a format contract.';Exit;end;
 if (FView=nil) or (FileFormatsList.ItemIndex<0) or (FileFormatsList.ItemIndex>=FFileFormatRows.Count) then Exit;
 Row:=FFileFormatRows[FileFormatsList.ItemIndex];Title:=TDPHWorkspaceView.FileFormatContractTitle(Row);
 for I:=0 to FKnowledgeRows.Count-1 do if FKnowledgeRows[I].GetValue<string>('title')=Title then begin KnowledgeList.ItemIndex:=I;KnowledgeClick(nil);WorkspaceTabs.ActiveTab:=KnowledgeTab;Exit;end;
 NewKnowledgeClick(nil);FBinding:=True;
 try FKnowledgeLink:=Row.GetValue<string>('target_key');KnowledgeTitleEdit.Text:=Title;KnowledgeKindCombo.ItemIndex:=KnowledgeKindCombo.Items.IndexOf('engineering_rule');
  KnowledgeBodyMemo.Text:='FILE FORMAT CONTRACT - replace Unknown with reviewed facts; do not enter credentials or real customer data.'+sLineBreak+
   'Format name and version: Unknown'+sLineBreak+'Direction and business purpose: '+Row.GetValue<string>('direction')+sLineBreak+
   'Encoding and BOM policy: Unknown'+sLineBreak+'Schema / required and optional fields / types: Unknown'+sLineBreak+
   'Delimiter, quoting, escaping and line endings: Unknown'+sLineBreak+'Producer routine and input mapping: '+Row.GetValue<string>('producer')+sLineBreak+
   'Consumer routine and destination mapping: '+Row.GetValue<string>('consumer')+sLineBreak+'Validation, malformed input and partial failure: Unknown'+sLineBreak+
   'Compatibility and version migration: Unknown'+sLineBreak+'Verification procedure and evidence: Unknown'+sLineBreak+'Remaining unknowns and responsible maintainer: Unknown'+sLineBreak+sLineBreak+TDPHWorkspaceView.DescribeFileFormat(Row);
 finally FBinding:=False;end;
 FKnowledgeEdited:=True;WorkspaceTabs.ActiveTab:=KnowledgeTab;StatusLabel.Text:='Complete the format contract, enter the named author, and click Save. Review separately against evidence.';
end;
"""
s=s.replace('procedure TDPHMainForm.DatabaseSchemaFilterChange(Sender:TObject);',code+'\nprocedure TDPHMainForm.DatabaseSchemaFilterChange(Sender:TObject);');p.write_text(s,encoding='utf-8')
p=r/'DPH.UI.Main.fmx';s=p.read_text(encoding='utf-8-sig');s=s.replace("'Database ER diagram'","'Database ER diagram'\n'Import/export formats'",1)
ui='''object FileFormatsTab: TTabItem
Text = 'Import/export formats'
object FileFormatsPurpose: TLabel
Align = Top
Height = 64
Margins.Left = 12
Margins.Right = 12
WordWrap = True
Text = 'Inspect captured import/export API candidates and resource structure. Select a row, then Record/open contract to document its encoding, schema, producer, consumer and verification steps. Scalar values are omitted; no transfer runs.'
end
object FileFormatsToolbar: THorzScrollBox
Align = Top
Height = 44
ShowScrollBars = True
object FileFormatsKind: TComboBox
Position.X = 8
Width = 160
Height = 28
Items.Strings = (
'All'
'import'
'export'
'captured resource')
ItemIndex = 0
OnChange = FileFormatsFilterChange
end
object FileFormatsFilter: TEdit
Position.X = 176
Width = 230
Height = 28
TextPrompt = 'Find format, encoding or routine'
OnChange = FileFormatsFilterChange
end
'''
for name,x,w,label,handler in [('First',414,90,'First page','FileFormatsFilterChange'),('Next',512,90,'Next page','FileFormatsFilterChange'),('Source',610,110,'Open source','FileFormatsSourceClick'),('Explain',728,140,'Explain routine','FileFormatsExplainClick'),('Contract',876,170,'Record/open contract','FileFormatsContractClick')]:
 ui+=f"object FileFormats{name}: TButton\nPosition.X = {x}\nWidth = {w}\nHeight = 28\nText = '{label}'\nOnClick = {handler}\nend\n"
ui+='''end
object FileFormatsStatus: TLabel
Align = Top
Height = 48
Margins.Left = 12
Margins.Right = 12
WordWrap = True
Text = 'Open a captured project to begin.'
end
object FileFormatsList: TListBox
Align = Top
Height = 90
Margins.Left = 12
Margins.Right = 12
OnChange = FileFormatsSelectionChange
end
object FileFormatsSplitter: TSplitter
Align = Top
Height = 6
end
object FileFormatsEvidenceLabel: TLabel
Align = Top
Height = 26
Margins.Left = 12
Margins.Right = 12
Text = 'Format evidence and saved contract (scroll for details)'
end
object FileFormatsMemo: TMemo
Align = Client
ReadOnly = True
WordWrap = True
ShowScrollBars = True
Margins.Left = 12
Margins.Right = 12
Margins.Bottom = 12
end
end
'''
s=s.replace('object DatabaseSchemaTab: TTabItem',ui+'object DatabaseSchemaTab: TTabItem');p.write_text(s,encoding='utf-8')
print('Implemented file-format projection and serialized inspector/contract workflow')
