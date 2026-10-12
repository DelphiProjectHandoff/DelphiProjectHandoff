unit DPH.Workspace.Commands;
interface
uses System.JSON, DPH.Workspace.Model;
type
  TDPHCommandInventory = class
    class function Inspect(AView: TDPHWorkspaceView; AKeyboard: TJSONObject): TJSONObject; static;
    class function Describe(ARow: TJSONObject): string; static;
  end;
implementation
uses System.SysUtils, System.StrUtils, System.Generics.Collections, System.Generics.Defaults;

class function TDPHCommandInventory.Inspect(AView: TDPHWorkspaceView; AKeyboard: TJSONObject): TJSONObject;
var Rows,Handlers,References,Properties: TJSONArray; Value,PropertyValue,RelationValue: TJSONValue;
    Component,Row,Parent,Target,Reference,Relation: TJSONObject;
    Nodes,Names: TDictionary<string,TJSONObject>; Ambiguous: TDictionary<string,Boolean>;
    Bindings: TObjectDictionary<string,TList<TJSONObject>>; Relations: TList<TJSONObject>;
    Ordered: TList<TJSONObject>; Key,Kind,Caption,CommandPath,ClassName,Name,Text,RefName: string;
    Depth: Integer; IsToolbar: Boolean;
  function Prop(AObject: TJSONObject; const AName: string): string;
  var V: TJSONValue;
  begin Result:=''; for V in AObject.GetValue<TJSONArray>('properties') do
    if SameText(V.GetValue<string>('name'),AName) then Exit(V.GetValue<string>('value')); end;
  function NodeKey(AObject: TJSONObject; AID: Integer): string;
  begin Result:=LowerCase(AObject.GetValue<string>('source'))+'|'+IntToStr(AID); end;
  function NameKey(AObject: TJSONObject; const AName: string): string;
  begin Result:=NodeKey(AObject,AObject.GetValue<Integer>('root_node'))+'|'+LowerCase(AName); end;
  procedure AddHandlers(AObject: TJSONObject; const AOrigin: string);
  var V: TJSONValue; P,H,R,S: TJSONObject; List: TList<TJSONObject>; BindingKey: string;
  begin
    for V in AObject.GetValue<TJSONArray>('properties') do begin
      P:=V as TJSONObject;
      if not MatchText(P.GetValue<string>('name'),['OnClick','OnExecute','OnUpdate','OnPopup']) or
        MatchText(P.GetValue<string>('value'),['nil','null','']) then Continue;
      H:=TJSONObject.Create; Handlers.AddElement(H);
      H.AddPair('origin',AOrigin); H.AddPair('event',P.GetValue<string>('name')); H.AddPair('declared_handler',P.GetValue<string>('value'));
      H.AddPair('resolution','unresolved'); H.AddPair('target_key','');
      H.AddPair('binding_source',AObject.GetValue<string>('source')); H.AddPair('binding_start',TJSONNumber.Create(P.GetValue<Integer>('start')));
      BindingKey:=LowerCase(AObject.GetValue<string>('source'))+'|'+IntToStr(P.GetValue<Integer>('start'));
      if Bindings.TryGetValue(BindingKey,List) and (List.Count=1) then begin
        R:=List[0]; S:=AView.Symbol(R.GetValue<string>('to',''));
        H.AddPair('relationship',R.Clone as TJSONObject);
        if (S<>nil) and (S.GetValue<string>('kind')='routine') and (R.GetValue<string>('resolution')='confirmed_static') then begin
          H.RemovePair('resolution').Free; H.AddPair('resolution','confirmed_static');
          H.RemovePair('target_key').Free; H.AddPair('target_key',S.GetValue<string>('key'));
          H.AddPair('target',S.Clone as TJSONObject);
        end;
      end;
    end;
  end;
begin
  Result:=TJSONObject.Create; Rows:=TJSONArray.Create; Result.AddPair('rows',Rows);
  Result.AddPair('qualification','Captured command declarations, not observed execution. Menu paths follow serialized ownership; visual ordering, ActionLink precedence, enabled/checked state and runtime-created commands may differ. Only unique local compatible references and confirmed static handler bindings are followed. Custom classes and uncaptured inheritance remain unknown.');
  Nodes:=TDictionary<string,TJSONObject>.Create; Names:=TDictionary<string,TJSONObject>.Create;
  Ambiguous:=TDictionary<string,Boolean>.Create; Bindings:=TObjectDictionary<string,TList<TJSONObject>>.Create([doOwnsValues]);
  Ordered:=TList<TJSONObject>.Create;
  try
    try
      for Value in AKeyboard.GetValue<TJSONArray>('rows') do begin
        Component:=Value as TJSONObject; Nodes.AddOrSetValue(NodeKey(Component,Component.GetValue<Integer>('node')),Component);
        Key:=NameKey(Component,Component.GetValue<string>('name'));
        if Names.ContainsKey(Key) then Ambiguous.AddOrSetValue(Key,True) else Names.Add(Key,Component);
      end;
      for RelationValue in AView.Document.GetValue<TJSONArray>('semantics.relationships') do begin
        Relation:=RelationValue as TJSONObject; if Relation.GetValue<string>('kind')<>'binds' then Continue;
        Key:=LowerCase(Relation.GetValue<string>('range.source'))+'|'+IntToStr(Relation.GetValue<Integer>('range.start'));
        if not Bindings.TryGetValue(Key,Relations) then begin Relations:=TList<TJSONObject>.Create; Bindings.Add(Key,Relations); end;
        Relations.Add(Relation);
      end;
      for Value in AKeyboard.GetValue<TJSONArray>('rows') do begin
        Component:=Value as TJSONObject; ClassName:=Component.GetValue<string>('class'); Kind:='';
        if MatchText(ClassName,['TMainMenu','TMenuBar']) then Kind:='main menu'
        else if SameText(ClassName,'TPopupMenu') then Kind:='context menu'
        else if SameText(ClassName,'TMenuItem') then Kind:='menu item'
        else if SameText(ClassName,'TToolBar') then Kind:='toolbar'
        else if MatchText(ClassName,['TToolButton','TMenuButton']) then Kind:='toolbar command'
        else if EndsText('Action',ClassName) then Kind:='action'
        else if MatchText(ClassName,['TActionList','TActionManager']) then Kind:='action container';
        IsToolbar:=False; Parent:=Component; CommandPath:=Component.GetValue<string>('name');
        for Depth:=0 to 127 do begin
          if not Nodes.TryGetValue(NodeKey(Parent,Parent.GetValue<Integer>('parent_node')),Parent) then Break;
          if SameText(Parent.GetValue<string>('class'),'TToolBar') then IsToolbar:=True;
          CommandPath:=Parent.GetValue<string>('name')+' / '+CommandPath;
        end;
        if (Kind='') and IsToolbar then Kind:='toolbar child';
        if (Kind='') and not MatchText(Prop(Component,'Action'),['','nil','null']) then Kind:='action consumer';
        if (Kind='') and ((Prop(Component,'PopupMenu')<>'') or (Prop(Component,'Menu')<>'')) then Kind:='menu attachment';
        if Kind='' then Continue;
        Caption:=Prop(Component,'Caption'); if Caption='' then Caption:=Prop(Component,'Text');
        if (Kind='menu item') and (AnsiDequotedStr(Caption,'''')='-') then Kind:='menu separator';
        Row:=TJSONObject.Create; Rows.AddElement(Row); Ordered.Add(Row);
        for Name in ['source','source_hash','availability','generation_id','name','class','declaration','node','parent_node','root_node','parent','form','range','shortcut','action','properties'] do
          Row.AddPair(Name,Component.GetValue(Name).Clone as TJSONValue);
        Row.AddPair('kind',Kind); Row.AddPair('command_path',CommandPath); Row.AddPair('caption',Caption);
        Row.AddPair('diagnostics',TJSONArray.Create);
        for Name in ['Enabled','Visible','Checked','AutoCheck','RadioItem','GroupIndex','Category','Hint','ImageIndex','Style','AutoPopup'] do begin
          Text:=Prop(Component,Name); if Text='' then Text:='unknown (not serialized)'; Row.AddPair(LowerCase(Name),Text);
        end;
        if Component.GetValue<string>('declaration')<>'object' then Row.GetValue<TJSONArray>('diagnostics').Add('Inherited/inline command: uncaptured base commands and properties remain unknown.');
        Handlers:=TJSONArray.Create; Row.AddPair('handlers',Handlers); AddHandlers(Component,'component');
        References:=TJSONArray.Create; Row.AddPair('references',References);
        for Name in ['Action','Menu','PopupMenu'] do begin
          RefName:=Prop(Component,Name); if MatchText(RefName,['','nil','null']) then Continue;
          Reference:=TJSONObject.Create; References.AddElement(Reference); Reference.AddPair('property',Name); Reference.AddPair('name',RefName);
          Reference.AddPair('resolution','unresolved'); Key:=NameKey(Component,RefName);
          if not Ambiguous.ContainsKey(Key) and Names.TryGetValue(Key,Target) and
            (((Name='Action') and EndsText('Action',Target.GetValue<string>('class'))) or
             ((Name='Menu') and MatchText(Target.GetValue<string>('class'),['TMainMenu','TMenuBar'])) or
             ((Name='PopupMenu') and SameText(Target.GetValue<string>('class'),'TPopupMenu'))) then begin
            Reference.RemovePair('resolution').Free; Reference.AddPair('resolution','confirmed_static');
            Reference.AddPair('range',Target.GetValue<TJSONObject>('range').Clone as TJSONObject);
            Reference.AddPair('class',Target.GetValue<string>('class')); Reference.AddPair('command',Target.GetValue<string>('name'));
            if Name='Action' then begin
              Row.AddPair('action_shortcut',Target.GetValue<string>('shortcut')); Row.AddPair('action_range',Target.GetValue<TJSONObject>('range').Clone as TJSONObject);
              Row.AddPair('action_caption',Prop(Target,'Caption')); AddHandlers(Target,'action '+RefName);
            end;
          end else Row.GetValue<TJSONArray>('diagnostics').Add(Name+' reference unresolved or ambiguous: '+RefName+'. External, custom and inherited targets are not guessed.');
        end;
        if (Kind<>'menu separator') and (Handlers.Count=0) then Row.GetValue<TJSONArray>('diagnostics').Add('No captured OnClick, OnExecute, OnUpdate or OnPopup binding. This may be a container or framework command; no executable handler is inferred.');
        for PropertyValue in Handlers do if PropertyValue.GetValue<string>('resolution')='unresolved' then
          Row.GetValue<TJSONArray>('diagnostics').Add('Handler unresolved: '+PropertyValue.GetValue<string>('origin')+'.'+PropertyValue.GetValue<string>('event')+' = '+PropertyValue.GetValue<string>('declared_handler'));
      end;
      Ordered.Sort(TComparer<TJSONObject>.Construct(function(const L,R: TJSONObject): Integer
        begin Result:=CompareText(L.GetValue<string>('source'),R.GetValue<string>('source'));
          if Result=0 then Result:=L.GetValue<Integer>('node')-R.GetValue<Integer>('node'); end));
      Properties:=TJSONArray.Create; for Row in Ordered do Properties.AddElement(Row.Clone as TJSONObject);
      Result.RemovePair('rows').Free; Result.AddPair('rows',Properties); Result.AddPair('total',TJSONNumber.Create(Properties.Count));
    except Result.Free; raise; end;
  finally Ordered.Free; Bindings.Free; Ambiguous.Free; Names.Free; Nodes.Free; end;
end;

class function TDPHCommandInventory.Describe(ARow: TJSONObject): string;
var Value: TJSONValue; Binding: TJSONObject; Text: string;
begin
  Result:=ARow.GetValue<string>('kind')+' | '+ARow.GetValue<string>('command_path')+sLineBreak+
    'Component: '+ARow.GetValue<string>('name')+' : '+ARow.GetValue<string>('class')+sLineBreak+
    'Caption/Text (serialized): '+ARow.GetValue<string>('caption')+sLineBreak+
    'Generation: '+ARow.GetValue('generation_id').Value+' | '+ARow.GetValue<string>('availability')+sLineBreak+
    'Evidence: '+ARow.GetValue<string>('source')+' | SHA-256 '+ARow.GetValue<string>('source_hash')+sLineBreak+
    'Line '+IntToStr(ARow.GetValue<Integer>('range.line'))+' | byte '+IntToStr(ARow.GetValue<Integer>('range.start'))+sLineBreak+
    'Own ShortCut code: '+ARow.GetValue<string>('shortcut')+sLineBreak+
    'Action reference: '+ARow.GetValue<string>('action')+sLineBreak+
    'Action ShortCut code: '+ARow.GetValue<string>('action_shortcut','unknown / none')+sLineBreak+
    'Action caption (serialized): '+ARow.GetValue<string>('action_caption','unknown / none')+sLineBreak;
  for Text in ['enabled','visible','checked','autocheck','radioitem','groupindex','category','hint','imageindex','style','autopopup'] do
    Result:=Result+Text+': '+ARow.GetValue<string>(Text)+sLineBreak;
  Result:=Result+sLineBreak+'MENU AND ACTION REFERENCES'+sLineBreak;
  for Value in ARow.GetValue<TJSONArray>('references') do begin
    Result:=Result+Value.GetValue<string>('property')+' = '+Value.GetValue<string>('name')+' ['+Value.GetValue<string>('resolution')+']';
    if Value.GetValue<string>('resolution')='confirmed_static' then Result:=Result+' | '+Value.GetValue<string>('range.source')+':'+IntToStr(Value.GetValue<Integer>('range.line'));
    Result:=Result+sLineBreak;
  end;
  Result:=Result+sLineBreak+'HANDLER BINDINGS'+sLineBreak;
  for Value in ARow.GetValue<TJSONArray>('handlers') do begin
    Result:=Result+Value.GetValue<string>('origin')+'.'+Value.GetValue<string>('event')+' = '+Value.GetValue<string>('declared_handler')+' ['+Value.GetValue<string>('resolution')+']'+sLineBreak;
    if (Value as TJSONObject).TryGetValue<TJSONObject>('target',Binding) then
      Result:=Result+'  '+Binding.GetValue<string>('name')+' | '+Binding.GetValue<string>('range.source')+':'+IntToStr(Binding.GetValue<Integer>('range.line'))+' | SHA-256 '+Binding.GetValue<string>('source_hash')+sLineBreak;
  end;
  Result:=Result+sLineBreak+'CAPTURED COMMAND PROPERTIES'+sLineBreak;
  for Value in ARow.GetValue<TJSONArray>('properties') do Result:=Result+Value.GetValue<string>('name')+' = '+Value.GetValue<string>('value')+' | line '+IntToStr(Value.GetValue<Integer>('line'))+', byte '+IntToStr(Value.GetValue<Integer>('start'))+sLineBreak;
  Result:=Result+sLineBreak+'DIAGNOSTICS'+sLineBreak;
  for Value in ARow.GetValue<TJSONArray>('diagnostics') do Result:=Result+'- '+Value.Value+sLineBreak;
  Result:=Result+sLineBreak+'HOW TO READ THIS'+sLineBreak+
    'Menu paths follow serialized parents, not observed screen positions. A Caption containing & declares an accelerator marker; it is not an independently confirmed shortcut. A separator is not an executable command. OnUpdate can change enabled/checked state; OnPopup can change menu contents. An action consumer may use its action OnExecute, while a separate OnClick may also be declared. These are separate captured bindings; dispatch precedence is not inferred. Use Keyboard and focus for readable key names and possible shortcut conflicts. Missing properties and uncaptured defaults remain unknown.';
end;
end.
