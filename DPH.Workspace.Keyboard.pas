unit DPH.Workspace.Keyboard;
interface
uses System.JSON, DPH.Workspace.Model;
type
  TDPHKeyboardInspector = class
    class function Inspect(AView: TDPHWorkspaceView): TJSONObject; static;
    class function Describe(ARow: TJSONObject): string; static;
    class function ReadSource(AView: TDPHWorkspaceView; const AEntry: string; ARow,ARange: TJSONObject): string; static;
  end;
implementation
uses System.SysUtils, System.StrUtils, System.Classes, System.IOUtils, System.Generics.Collections, System.Generics.Defaults,
  DPH.Project.Source, DPH.Parse.Model;

class function TDPHKeyboardInspector.Inspect(AView: TDPHWorkspaceView): TJSONObject;
var Files,Nodes,Rows,Properties,Diagnostics: TJSONArray; FileValue,Value: TJSONValue;
    FileRow,Node,PropertyNode,Row,Target,Parent,RootNode: TJSONObject;
    Objects: TDictionary<Integer,TJSONObject>; Ordered: TList<TJSONObject>;
    Names: TObjectDictionary<string,TList<TJSONObject>>;
    ShortcutGroups,TabGroups: TObjectDictionary<string,TList<TJSONObject>>;
    PropertyGroups: TObjectDictionary<Integer,TList<TJSONObject>>;
    Group: TList<TJSONObject>; Path,Name,Text,Key,ActionName: string;
    I,ParentID,RootID,Number,ActionCount: Integer;
  function PropertyValue(AObject: TJSONObject; const AName: string): string;
  var P: TJSONValue;
  begin
    Result:='';
    for P in AObject.GetValue<TJSONArray>('properties') do
      if SameText(P.GetValue<string>('name'),AName) then Exit(P.GetValue<string>('value'));
  end;
  procedure Warn(AObject: TJSONObject; const AText: string);
  begin AObject.GetValue<TJSONArray>('diagnostics').Add(AText); end;
  procedure GroupRow(AGroups: TObjectDictionary<string,TList<TJSONObject>>; const AKey: string; AObject: TJSONObject);
  var Members: TList<TJSONObject>;
  begin
    if not AGroups.TryGetValue(AKey,Members) then begin Members:=TList<TJSONObject>.Create; AGroups.Add(AKey,Members); end;
    Members.Add(AObject);
  end;
begin
  Result:=TJSONObject.Create; Rows:=TJSONArray.Create; Result.AddPair('rows',Rows);
  Result.AddPair('qualification','Captured design-time declarations, not observed keyboard behavior. TabOrder is local to each serialized parent. Missing properties mean unknown/default/inherited, not False or zero. Runtime code, class defaults, inheritance, visibility, enabled state, nested containers and framework rules can change navigation. Duplicate shortcuts are possible conflicts within one form, not proof of simultaneous activation.');
  Objects:=TDictionary<Integer,TJSONObject>.Create; Ordered:=TList<TJSONObject>.Create;
  Names:=TObjectDictionary<string,TList<TJSONObject>>.Create([doOwnsValues]);
  ShortcutGroups:=TObjectDictionary<string,TList<TJSONObject>>.Create([doOwnsValues]);
  TabGroups:=TObjectDictionary<string,TList<TJSONObject>>.Create([doOwnsValues]);
  PropertyGroups:=TObjectDictionary<Integer,TList<TJSONObject>>.Create([doOwnsValues]);
  try
    try
      Files:=AView.Document.GetValue<TJSONArray>('syntax.files');
      for FileValue in Files do begin
        FileRow:=FileValue as TJSONObject; Path:=FileRow.GetValue<string>('path');
        if not MatchText(ExtractFileExt(Path),['.dfm','.fmx']) or not FileRow.TryGetValue<TJSONArray>('ir.nodes',Nodes) then Continue;
        Objects.Clear; Names.Clear; ShortcutGroups.Clear; TabGroups.Clear;
        PropertyGroups.Clear;
        for Value in Nodes do begin
          PropertyNode:=Value as TJSONObject;
          if (PropertyNode.GetValue<string>('kind')<>'property') or
            not MatchText(PropertyNode.GetValue<string>('name'),['ShortCut','SecondaryShortCuts.Strings','TabOrder','TabStop','CanFocus','Action','OnKeyDown','OnKeyUp','OnKeyPress','Enabled','Visible','FocusControl',
              'Caption','Text','Hint','Menu','PopupMenu','OnClick','OnExecute','OnUpdate','OnPopup','Checked','AutoCheck','GroupIndex','RadioItem','Category','ImageIndex','Style','AutoPopup',
              'Align','Anchors','Left','Top','Width','Height','ClientWidth','ClientHeight','Position.X','Position.Y','Size.Width','Size.Height','AutoSize','AlignWithMargins','WordWrap','Scaled','PixelsPerInch','Scale.X','Scale.Y',
              'Margins.Left','Margins.Top','Margins.Right','Margins.Bottom','Padding.Left','Padding.Top','Padding.Right','Padding.Bottom','Constraints.MinWidth','Constraints.MaxWidth','Constraints.MinHeight','Constraints.MaxHeight','OnResize','OnCanResize','OnConstrainedResize','OnAlignPosition','OnAlignInsertBefore','WrapMode']) then Continue;
          ParentID:=PropertyNode.GetValue<Integer>('parent');
          if not PropertyGroups.TryGetValue(ParentID,Group) then begin Group:=TList<TJSONObject>.Create; PropertyGroups.Add(ParentID,Group); end;
          Group.Add(PropertyNode);
        end;
        for I:=0 to Nodes.Count-1 do begin
          Node:=Nodes.Items[I] as TJSONObject;
          if not MatchText(Node.GetValue<string>('kind'),['object','inherited','inline']) then Continue;
          Row:=TJSONObject.Create; Rows.AddElement(Row); Ordered.Add(Row); Objects.Add(I,Row);
          Row.AddPair('source',Path); Row.AddPair('source_hash',FileRow.GetValue<string>('sha256',''));
          Row.AddPair('availability',FileRow.GetValue<string>('availability','unknown'));
          Row.AddPair('generation_id',TJSONNumber.Create(AView.Document.GetValue<Int64>('generation_id')));
          Row.AddPair('name',Node.GetValue<string>('name')); Row.AddPair('class',Node.GetValue<string>('value'));
          Row.AddPair('declaration',Node.GetValue<string>('kind')); Row.AddPair('node',TJSONNumber.Create(I));
          ParentID:=Node.GetValue<Integer>('parent'); Row.AddPair('parent_node',TJSONNumber.Create(ParentID));
          Parent:=nil; Objects.TryGetValue(ParentID,Parent);
          if Parent=nil then begin RootID:=I; Text:='(form root)'; end
          else begin RootID:=Parent.GetValue<Integer>('root_node'); Text:=Parent.GetValue<string>('name'); end;
          Row.AddPair('root_node',TJSONNumber.Create(RootID)); Row.AddPair('parent',Text);
          RootNode:=Nodes.Items[RootID] as TJSONObject; Row.AddPair('form',RootNode.GetValue<string>('name'));
          Row.AddPair('range',TJSONObject.Create.AddPair('source',Path).AddPair('start',TJSONNumber.Create(Node.GetValue<Integer>('start')))
            .AddPair('end',TJSONNumber.Create(Node.GetValue<Integer>('end'))).AddPair('line',TJSONNumber.Create(Node.GetValue<Integer>('line')))
            .AddPair('column',TJSONNumber.Create(Node.GetValue<Integer>('column'))));
          Properties:=TJSONArray.Create; Row.AddPair('properties',Properties);
          Diagnostics:=TJSONArray.Create; Row.AddPair('diagnostics',Diagnostics);
          if PropertyGroups.TryGetValue(I,Group) then for PropertyNode in Group do Properties.AddElement(PropertyNode.Clone as TJSONObject);
          Key:=IntToStr(RootID)+'|'+LowerCase(Row.GetValue<string>('name'));
          GroupRow(Names,Key,Row);
          Text:=PropertyValue(Row,'TabOrder'); Number:=MaxInt;
          if Text='' then Warn(Row,'TabOrder not serialized: focus position unknown (or not applicable to this component).')
          else if not TryStrToInt(Text,Number) or (Number<0) then begin Number:=MaxInt; Warn(Row,'Invalid or unsupported TabOrder: '+Text); end
          else GroupRow(TabGroups,IntToStr(ParentID)+'|'+IntToStr(Number),Row);
          Row.AddPair('tab_order',TJSONNumber.Create(Number));
          for Name in ['TabStop','CanFocus','Enabled','Visible'] do begin
            Text:=PropertyValue(Row,Name);
            if Text='' then Text:='unknown (not serialized)'
            else if not MatchText(Text,['True','False']) then Warn(Row,'Unsupported '+Name+' value: '+Text);
            Row.AddPair(LowerCase(Name),Text);
          end;
          if Node.GetValue<string>('kind')<>'object' then Warn(Row,'Inherited/inline declaration: uncaptured base values and parent relationships remain unknown.');
          Text:=PropertyValue(Row,'ShortCut'); Row.AddPair('shortcut',Text);
          if Text='' then Warn(Row,'ShortCut not serialized: no key binding can be inferred from this property.')
          else if not TryStrToInt(Text,Number) or (Number<0) or (Number>65535) then Warn(Row,'Unsupported shortcut encoding: '+Text)
          else if Number<>0 then GroupRow(ShortcutGroups,IntToStr(RootID)+'|'+IntToStr(Number),Row);
          Row.AddPair('action',PropertyValue(Row,'Action'));
          if PropertyValue(Row,'SecondaryShortCuts.Strings')<>'' then Warn(Row,'Secondary shortcut collection is captured below but not decoded for conflict detection.');
        end;
        for Row in Objects.Values do begin
          ActionName:=Row.GetValue<string>('action'); Target:=nil; ActionCount:=0;
          if not MatchText(ActionName,['','nil','null']) then begin
            Key:=IntToStr(Row.GetValue<Integer>('root_node'))+'|'+LowerCase(ActionName);
            if Names.TryGetValue(Key,Group) then
              for Parent in Group do
                if EndsText('Action',Parent.GetValue<string>('class')) then begin Target:=Parent; Inc(ActionCount); end;
            if ActionCount=1 then begin
              Row.AddPair('action_target',Target.GetValue<string>('name'));
              Row.AddPair('action_shortcut',Target.GetValue<string>('shortcut'));
              Row.AddPair('action_range',Target.GetValue<TJSONObject>('range').Clone as TJSONObject);
              if Target.GetValue<string>('shortcut')='' then Warn(Row,'Referenced action has no serialized ShortCut; its effective shortcut is unknown.');
              if Row.GetValue<string>('shortcut')<>'' then Warn(Row,'Both component and action declare shortcuts; effective ActionLink behavior is not observed.');
            end else Warn(Row,'Action reference unresolved or ambiguous in this form: '+ActionName+'. External and inherited actions are not guessed.');
          end;
        end;
        for Group in ShortcutGroups.Values do if Group.Count>1 then
          for Row in Group do Warn(Row,'Possible duplicate shortcut in this form ('+IntToStr(Group.Count)+' declarations). Action-linked consumers are not counted again.');
        for Group in TabGroups.Values do if Group.Count>1 then
          for Row in Group do Warn(Row,'Duplicate TabOrder among serialized siblings ('+IntToStr(Group.Count)+' declarations); actual traversal is unknown.');
      end;
      Ordered.Sort(TComparer<TJSONObject>.Construct(
        function(const L,R: TJSONObject): Integer
        begin
          Result:=CompareText(L.GetValue<string>('source'),R.GetValue<string>('source'));
          if Result=0 then Result:=L.GetValue<Integer>('root_node')-R.GetValue<Integer>('root_node');
          if Result=0 then Result:=L.GetValue<Integer>('parent_node')-R.GetValue<Integer>('parent_node');
          if Result=0 then begin
            if L.GetValue<Integer>('tab_order')<R.GetValue<Integer>('tab_order') then Result:=-1
            else if L.GetValue<Integer>('tab_order')>R.GetValue<Integer>('tab_order') then Result:=1;
          end;
          if Result=0 then Result:=L.GetValue<Integer>('node')-R.GetValue<Integer>('node');
        end));
      // Rows own the objects; reorder by cloning before releasing the original array.
      Properties:=TJSONArray.Create;
      for Row in Ordered do Properties.AddElement(Row.Clone as TJSONObject);
      Result.RemovePair('rows').Free; Result.AddPair('rows',Properties);
      Result.AddPair('total',TJSONNumber.Create(Properties.Count));
    except Result.Free; raise; end;
  finally PropertyGroups.Free; TabGroups.Free; ShortcutGroups.Free; Names.Free; Ordered.Free; Objects.Free; end;
end;

class function TDPHKeyboardInspector.Describe(ARow: TJSONObject): string;
var Value: TJSONValue; Number: Integer; Text: string;
  function KeyText(const Raw: string): string;
  var Code,KeyCode: Integer; KeyName: string;
  begin
    Result:='unknown';
    if not TryStrToInt(Raw,Code) or (Code<0) or (Code>65535) then Exit;
    if Code=0 then Exit('none declared');
    KeyCode:=Code and not (scCommand or scShift or scCtrl or scAlt);
    if ((KeyCode>=Ord('A')) and (KeyCode<=Ord('Z'))) or ((KeyCode>=Ord('0')) and (KeyCode<=Ord('9'))) then KeyName:=Chr(KeyCode)
    else if (KeyCode>=112) and (KeyCode<=135) then KeyName:='F'+IntToStr(KeyCode-111)
    else case KeyCode of
      8: KeyName:='Backspace'; 9: KeyName:='Tab'; 13: KeyName:='Enter'; 27: KeyName:='Escape';
      32: KeyName:='Space'; 33: KeyName:='PageUp'; 34: KeyName:='PageDown'; 35: KeyName:='End'; 36: KeyName:='Home';
      37: KeyName:='Left'; 38: KeyName:='Up'; 39: KeyName:='Right'; 40: KeyName:='Down'; 45: KeyName:='Insert'; 46: KeyName:='Delete';
    else KeyName:='key code $'+IntToHex(KeyCode,2); end;
    Result:='';
    if Code and scCommand<>0 then Result:=Result+'Command+';
    if Code and scCtrl<>0 then Result:=Result+'Ctrl+';
    if Code and scAlt<>0 then Result:=Result+'Alt+';
    if Code and scShift<>0 then Result:=Result+'Shift+';
    Result:=Result+KeyName;
  end;
begin
  Result:=ARow.GetValue<string>('form')+' / '+ARow.GetValue<string>('parent')+' / '+ARow.GetValue<string>('name')+
    ' : '+ARow.GetValue<string>('class')+sLineBreak+
    'Captured generation: '+ARow.GetValue('generation_id').Value+sLineBreak+
    'Evidence: '+ARow.GetValue<string>('source')+' | SHA-256 '+ARow.GetValue<string>('source_hash')+sLineBreak+
    'Location: line '+IntToStr(ARow.GetValue<Integer>('range.line'))+', byte '+IntToStr(ARow.GetValue<Integer>('range.start'))+sLineBreak+
    'Declaration: '+ARow.GetValue<string>('declaration')+'; availability: '+ARow.GetValue<string>('availability')+sLineBreak;
  Number:=ARow.GetValue<Integer>('tab_order'); Text:='unknown / not applicable';
  if Number<>MaxInt then Text:=IntToStr(Number);
  Result:=Result+'Sibling TabOrder: '+Text+sLineBreak;
  for Text in ['tabstop','canfocus','enabled','visible'] do Result:=Result+Text+': '+ARow.GetValue<string>(Text)+sLineBreak;
  Text:=ARow.GetValue<string>('shortcut'); if Text='' then Text:='unknown (not serialized)';
  Result:=Result+'Own ShortCut (serialized code): '+Text+' ['+KeyText(ARow.GetValue<string>('shortcut'))+']'+sLineBreak+
    'Action reference: '+ARow.GetValue<string>('action','')+sLineBreak+
    'Resolved local action: '+ARow.GetValue<string>('action_target','unknown / none')+sLineBreak+
    'Action ShortCut (serialized code): '+ARow.GetValue<string>('action_shortcut','unknown / none')+' ['+KeyText(ARow.GetValue<string>('action_shortcut',''))+']'+sLineBreak+sLineBreak+
    'CAPTURED PROPERTIES (with source locations)'+sLineBreak;
  for Value in ARow.GetValue<TJSONArray>('properties') do
    Result:=Result+Value.GetValue<string>('name')+' = '+Value.GetValue<string>('value')+' | line '+IntToStr(Value.GetValue<Integer>('line'))+', byte '+IntToStr(Value.GetValue<Integer>('start'))+sLineBreak;
  Result:=Result+sLineBreak+'DIAGNOSTICS'+sLineBreak;
  for Value in ARow.GetValue<TJSONArray>('diagnostics') do Result:=Result+'- '+Value.Value+sLineBreak;
  Result:=Result+sLineBreak+'HOW TO READ THIS'+sLineBreak+
    'Lower TabOrder values precede higher values only within the same serialized parent. TabStop=False and CanFocus=False are explicit declarations, not proof of current runtime state. Missing defaults are unknown. ShortCut=0 explicitly declares no shortcut on that object; action behavior can still apply. Common Windows key codes use readable names; original numeric/hex codes remain authoritative. Other keyboard layouts are not established. OnKey handlers may implement additional keys. Runtime changes, inheritance and framework rules require a real execution test.';
end;

class function TDPHKeyboardInspector.ReadSource(AView: TDPHWorkspaceView; const AEntry: string; ARow,ARange: TJSONObject): string;
var Path: string; Source: TDPHSource; Diagnostics: TDPHDiagnostics;
begin
  if AEntry='' then raise EInvalidOpException.Create('Source is detached. Attach the unchanged project to navigate.');
  if ARow.GetValue<Int64>('generation_id')<>AView.Document.GetValue<Int64>('generation_id') then raise EInvalidOpException.Create('Historical generation: navigation refused.');
  if ARange.GetValue<Integer>('line')<=0 then raise EInvalidOpException.Create('Binary form: byte locations remain available; text navigation is not available.');
  if not SameText(ARange.GetValue<string>('source'),ARow.GetValue<string>('source')) then raise EInvalidOpException.Create('Source location does not belong to this evidence row.');
  Path:=TPath.GetFullPath(TPath.Combine(ExtractFilePath(AEntry),ARange.GetValue<string>('source')));
  if not StartsText(IncludeTrailingPathDelimiter(ExtractFilePath(AEntry)),Path) then raise EInvalidOpException.Create('Source is outside the attached project.');
  Diagnostics:=TDPHDiagnostics.Create;
  try
    Source:=TDPHSource.Create(Path,ARange.GetValue<string>('source'),Diagnostics,AView.Document.GetValue<Integer>('code_page',0));
    try
      if not Source.Decoded or not SameText(Source.SHA256,ARow.GetValue<string>('source_hash')) then
        raise EInvalidOpException.Create('Source changed or cannot be decoded. Rescan before navigating; the captured range was not applied.');
      Result:=Source.Text;
    finally Source.Free; end;
  finally Diagnostics.Free; end;
end;
end.
