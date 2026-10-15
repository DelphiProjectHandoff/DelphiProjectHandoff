unit DPH.Workspace.Screen;
interface
uses System.JSON, DPH.Workspace.Model;
type
  TDPHScreenLayout = class
    class function Reconstruct(AView: TDPHWorkspaceView; const AFile: string; AIncludeKeys: Boolean = True): TJSONObject; static;
    class function Gallery(AView: TDPHWorkspaceView): TJSONObject; static;
  end;
implementation
uses System.SysUtils, System.StrUtils, System.Generics.Collections, System.Math, System.RegularExpressions;
class function TDPHScreenLayout.Gallery(AView: TDPHWorkspaceView): TJSONObject;
var FileValue,Value: TJSONValue; FileRow,Screen,Row,CopyRow: TJSONObject; Rows: TJSONArray;
    Index: Integer; Path: string;
begin
  Result:=TJSONObject.Create; Rows:=TJSONArray.Create; Result.AddPair('components',Rows);
  Result.AddPair('provenance','Approximate design-time thumbnail gallery; not runtime screenshots. Maximum 60 forms.'); Index:=0;
  for FileValue in AView.Document.GetValue<TJSONArray>('syntax.files') do
  begin
    FileRow:=FileValue as TJSONObject; Path:=FileRow.GetValue<string>('path');
    if not MatchText(ExtractFileExt(Path),['.fmx','.dfm']) or (FileRow.GetValue('ir')=nil) then Continue;
    Screen:=Reconstruct(AView,Path);
    try
      for Value in Screen.GetValue<TJSONArray>('components') do
      begin
        Row:=Value as TJSONObject; CopyRow:=Row.Clone as TJSONObject;
        CopyRow.RemovePair('x').Free; CopyRow.RemovePair('y').Free;
        CopyRow.AddPair('x',TJSONNumber.Create(Row.GetValue<Double>('x')+(Index mod 3)*1000));
        CopyRow.AddPair('y',TJSONNumber.Create(Row.GetValue<Double>('y')+(Index div 3)*800)); Rows.AddElement(CopyRow);
      end;
    finally Screen.Free; end;
    Inc(Index); if Index>=60 then Break;
  end;
end;
class function TDPHScreenLayout.Reconstruct(AView: TDPHWorkspaceView; const AFile: string; AIncludeKeys: Boolean): TJSONObject;
var FileRow,N,P,R,Parent,S,Range: TJSONObject; Nodes,Rows: TJSONArray; V: TJSONValue;
    Positions: TDictionary<Integer,TJSONObject>; I,J: Integer; X,Y,W,H,FontSize: Double;
    Name,Value,Caption,FontColor,FillColor,HorzAlign,NavigatorButtons: string; Visible: Boolean;
    TextPart: TMatch; CharacterCode: Integer;
begin
  Result:=TJSONObject.Create; Rows:=TJSONArray.Create; Result.AddPair('components',Rows);
  Result.AddPair('provenance','Approximate design-time reconstruction; not a runtime screenshot. Custom painting, styles and runtime layout are unobserved.');
  Result.AddPair('source',AFile); FileRow:=AView.SourceFile(AFile); if FileRow=nil then Exit;
  Result.AddPair('source_hash',FileRow.GetValue<string>('sha256'));
  if not FileRow.TryGetValue<TJSONArray>('ir.nodes',Nodes) then Exit;
  Positions:=TDictionary<Integer,TJSONObject>.Create;
  try
    for I:=0 to Nodes.Count-1 do
    begin
      N:=Nodes.Items[I] as TJSONObject; if not MatchText(N.GetValue<string>('kind'),['object','inherited','inline']) then Continue;
      Parent:=nil; Positions.TryGetValue(N.GetValue<Integer>('parent'),Parent);
      X:=0; Y:=0; W:=120; H:=32; if Parent=nil then begin W:=800; H:=600; end;
      Caption:=''; FontSize:=14; FontColor:=''; FillColor:=''; HorzAlign:='Leading';
      NavigatorButtons:=''; Visible:=(Parent=nil) or Parent.GetValue<Boolean>('visible',True);
      for J:=I+1 to Nodes.Count-1 do
      begin
        P:=Nodes.Items[J] as TJSONObject;
        if (P.GetValue<Integer>('parent')<>I) or (P.GetValue<string>('kind')<>'property') then Continue;
        Name:=P.GetValue<string>('name'); Value:=P.GetValue<string>('value');
        if (Parent<>nil) and MatchText(Name,['Left','Position.X']) then X:=StrToFloatDef(Value,X,TFormatSettings.Invariant);
        if (Parent<>nil) and MatchText(Name,['Top','Position.Y']) then Y:=StrToFloatDef(Value,Y,TFormatSettings.Invariant);
        if MatchText(Name,['Width','ClientWidth','Size.Width']) then W:=StrToFloatDef(Value,W,TFormatSettings.Invariant);
        if MatchText(Name,['Height','ClientHeight','Size.Height']) then H:=StrToFloatDef(Value,H,TFormatSettings.Invariant);
        if Name='TextSettings.Font.Size' then FontSize:=StrToFloatDef(Value,FontSize,TFormatSettings.Invariant);
        if Name='TextSettings.FontColor' then FontColor:=Value;
        if Name='Fill.Color' then FillColor:=Value;
        if Name='TextSettings.HorzAlign' then HorzAlign:=Value;
        if Name='VisibleButtons' then NavigatorButtons:=Value;
        if Name='Visible' then Visible:=Visible and not SameText(Value,'False');
        if (Name='IsSelected') and SameText(N.GetValue<string>('value',''),'TTabItem') then
          Visible:=Visible and not SameText(Value,'False');
        if MatchText(Name,['Caption','Text']) and not MatchText(LowerCase(N.GetValue<string>('value','')),['tedit','tmemo','tlistbox','tcombobox','timage']) then begin
          Caption:='';
          for TextPart in TRegEx.Matches(Value,'''((?:''''|[^''])*)''|#(\d+)') do begin
            if TextPart.Groups[1].Success then
              Caption:=Caption+TextPart.Groups[1].Value.Replace('''''','''')
            else if TryStrToInt(TextPart.Groups[2].Value,CharacterCode) then begin
              if CharacterCode=10 then Caption:=Caption+#10
              else if (CharacterCode>=32) and (CharacterCode<=65535) then
                Caption:=Caption+Char(CharacterCode);
            end;
          end;
          if Caption='' then Caption:=Value;
        end;
      end;
      if Parent<>nil then begin X:=X+Parent.GetValue<Double>('x'); Y:=Y+Parent.GetValue<Double>('y'); end;
      R:=TJSONObject.Create; Rows.AddElement(R); Positions.Add(I,R);
      R.AddPair('name',N.GetValue<string>('name')); R.AddPair('class',N.GetValue<string>('value')); R.AddPair('caption',Caption);
      if Parent<>nil then R.AddPair('parent_class',Parent.GetValue<string>('class',''))
      else R.AddPair('parent_class','');
      R.AddPair('font_size',TJSONNumber.Create(EnsureRange(FontSize,7.0,72.0)));
      R.AddPair('font_color',FontColor); R.AddPair('fill_color',FillColor);
      R.AddPair('navigator_buttons',NavigatorButtons);
      R.AddPair('horizontal_alignment',HorzAlign); R.AddPair('visible',TJSONBool.Create(Visible));
      R.AddPair('x',TJSONNumber.Create(EnsureRange(X,-100000.0,100000.0))); R.AddPair('y',TJSONNumber.Create(EnsureRange(Y,-100000.0,100000.0)));
      R.AddPair('width',TJSONNumber.Create(EnsureRange(W,1.0,100000.0))); R.AddPair('height',TJSONNumber.Create(EnsureRange(H,1.0,100000.0)));
      if AIncludeKeys then
        for V in AView.Document.GetValue<TJSONArray>('semantics.symbols') do
        begin S:=V as TJSONObject; Range:=S.GetValue<TJSONObject>('range');
          if (Range.GetValue<string>('source')=AFile) and (Range.GetValue<Int64>('start')=N.GetValue<Int64>('start')) then begin R.AddPair('key',S.GetValue<string>('key')); Break; end;
        end;
    end;
  finally Positions.Free; end;
end;
end.
