unit DPH.Workspace.LayoutRules;
interface
uses System.JSON;
type
 TDPHLayoutRules = class
  class function Inspect(AComponents:TJSONObject):TJSONObject; static;
  class function Describe(ARow:TJSONObject; AWidthDelta,AHeightDelta:Integer):string; static;
 end;
implementation
uses System.SysUtils,System.StrUtils,System.Generics.Collections;
class function TDPHLayoutRules.Inspect(AComponents:TJSONObject):TJSONObject;
var V:TJSONValue; Row,Parent:TJSONObject; Rows:TJSONArray; Index:TDictionary<string,TJSONObject>; Key:string;
begin
 Result:=TJSONObject.Create;Rows:=TJSONArray.Create;Result.AddPair('rows',Rows);
 Result.AddPair('qualification','Captured layout declarations and educational resize examples, not evaluated VCL/FMX layout or observed runtime geometry. Parent means serialized containment. Class defaults, inherited values, sibling allocation order, custom layout code, DPI, fonts, styles, margins, padding and constraints can change actual results. Form designs remains an approximate reconstruction; run the target to observe resizing.');
 Index:=TDictionary<string,TJSONObject>.Create;
 try
  try
   for V in AComponents.GetValue<TJSONArray>('rows') do begin Row:=V as TJSONObject;Index.AddOrSetValue(LowerCase(Row.GetValue<string>('source'))+'|'+IntToStr(Row.GetValue<Integer>('node')),Row);end;
   for V in AComponents.GetValue<TJSONArray>('rows') do begin
    Row:=V.Clone as TJSONObject;Rows.AddElement(Row);Key:=LowerCase(Row.GetValue<string>('source'))+'|'+IntToStr(Row.GetValue<Integer>('parent_node'));
    if Index.TryGetValue(Key,Parent) then begin Row.AddPair('parent_properties',Parent.GetValue<TJSONArray>('properties').Clone as TJSONArray);Row.AddPair('parent_range',Parent.GetValue<TJSONObject>('range').Clone as TJSONObject);end;
   end;
   Result.AddPair('total',TJSONNumber.Create(Rows.Count));
  except Result.Free;raise;end;
 finally Index.Free;end;
end;
class function TDPHLayoutRules.Describe(ARow:TJSONObject; AWidthDelta,AHeightDelta:Integer):string;
var V:TJSONValue; Props:TJSONArray; Align,Anchors,Mode,Token,Text:string; Parts:TArray<string>;
 Left,Right,Top,Bottom,Valid:Boolean; MinValue,MaxValue:Double;
 function Prop(const Name:string):string;
 var P:TJSONValue;
 begin Result:='';for P in ARow.GetValue<TJSONArray>('properties') do if SameText(P.GetValue<string>('name'),Name) then Exit(P.GetValue<string>('value'));end;
 function LayoutProperty(const Name:string):Boolean;
 begin Result:=MatchText(Name,['Align','Anchors','Left','Top','Width','Height','ClientWidth','ClientHeight','Position.X','Position.Y','AutoSize','AlignWithMargins','WordWrap','Scaled','PixelsPerInch','OnResize','OnCanResize','OnConstrainedResize','OnAlignPosition','OnAlignInsertBefore','WrapMode']) or StartsText('Margins.',Name) or StartsText('Padding.',Name) or StartsText('Constraints.',Name) or StartsText('Size.',Name) or StartsText('Scale.',Name);end;
 function Axis(First,Last:Boolean;Delta:Integer;const AxisName,SizeName,PositionName:string):string;
 begin
  if First and Last then Result:=AxisName+': opposing edges anchored; basic example '+SizeName+' change = '+IntToStr(Delta)+' units, '+PositionName+' change = 0.'
  else if Last then Result:=AxisName+': trailing edge anchored; basic example '+PositionName+' change = '+IntToStr(Delta)+' units, '+SizeName+' change = 0.'
  else if First then Result:=AxisName+': leading edge anchored; basic example '+PositionName+' and '+SizeName+' changes = 0.'
  else Result:=AxisName+': neither edge anchored; centering/proportional behavior depends on framework and stored anchor origin; no numeric example inferred.';
 end;
begin
 Result:='LAYOUT RULES '+ARow.GetValue<string>('name')+' : '+ARow.GetValue<string>('class')+sLineBreak+
 'Form: '+ARow.GetValue<string>('form')+' | serialized parent: '+ARow.GetValue<string>('parent')+sLineBreak+
 'Generation: '+ARow.GetValue('generation_id').Value+' | '+ARow.GetValue<string>('availability')+sLineBreak+
 'Source: '+ARow.GetValue<string>('source')+':'+IntToStr(ARow.GetValue<Integer>('range.line'))+' | byte '+IntToStr(ARow.GetValue<Integer>('range.start'))+sLineBreak+
 'SHA-256: '+ARow.GetValue<string>('source_hash')+sLineBreak+sLineBreak+'CAPTURED LAYOUT PROPERTIES'+sLineBreak;
 for V in ARow.GetValue<TJSONArray>('properties') do if LayoutProperty(V.GetValue<string>('name')) then Result:=Result+V.GetValue<string>('name')+' = '+V.GetValue<string>('value')+' | line '+IntToStr(V.GetValue<Integer>('line'))+', byte '+IntToStr(V.GetValue<Integer>('start'))+sLineBreak;
 Align:=Prop('Align');Anchors:=Prop('Anchors');Mode:=LowerCase(Align);if StartsText('al',Mode) then Delete(Mode,1,2);
 Result:=Result+sLineBreak+'ALIGNMENT EXPLANATION'+sLineBreak;
 if Align='' then Result:=Result+'Align not serialized: default/inherited/not-applicable behavior unknown.'
 else if Mode='none' then Result:=Result+'No alignment requested by this declaration. Explicit anchors can describe edge relationships.'
 else if MatchText(Mode,['top','bottom','left','right','mosttop','mostbottom','mostleft','mostright']) then Result:=Result+'Edge alignment '+Align+': places the control at the named edge of available parent space. The cross-axis can follow available space; thickness, sibling order, margins and constraints affect the result.'
 else if Mode='client' then Result:=Result+'Client alignment: requests remaining parent client space after framework layout allocation. It does not establish the full outer size or sibling ordering.'
 else if Mode='contents' then Result:=Result+'Contents alignment: requests parent contents coverage. It differs from remaining-client allocation; padding, clipping and framework behavior require review.'
 else if MatchText(Mode,['center','vertcenter','horzcenter']) then Result:=Result+'Center alignment '+Align+': centers on the named axis or axes. It does not imply fill or automatic wrapping.'
 else if MatchText(Mode,['horizontal','vertical']) then Result:=Result+'Axis-fill alignment '+Align+': follows available space on the named axis while the other axis follows framework rules.'
 else if MatchText(Mode,['scale','fit','fitleft','fitright']) then Result:=Result+'Proportional alignment '+Align+': scales or fits using framework reference bounds and available parent area. Scale and Fit differ; exact aspect, offsets and final bounds are not calculated here.'
 else if MatchText(Mode,['topleft','topcenter','topright','lefttop','leftcenter','leftbottom','righttop','rightcenter','rightbottom','bottomleft','bottomcenter','bottomright']) then Result:=Result+'Corner/edge placement '+Align+': combines a named edge with an axis position. It does not imply stretch across both axes.'
 else if Mode='custom' then Result:=Result+'Custom alignment requires application/framework layout code. Inspect alignment events; no numeric resize behavior is inferred.'
 else Result:=Result+'Unsupported Align value '+Align+': retained verbatim; no behavior inferred.';
 Result:=Result+sLineBreak+sLineBreak+'ANCHORS AND EDUCATIONAL RESIZE EXAMPLE'+sLineBreak+'Parent width change = '+IntToStr(AWidthDelta)+' units; height change = '+IntToStr(AHeightDelta)+' units. This changes only the explanation, never target source or form geometry.'+sLineBreak;
 Left:=False;Right:=False;Top:=False;Bottom:=False;Valid:=(Length(Anchors)>=2) and (Anchors[1]='[') and (Anchors[Length(Anchors)]=']');
 if Valid then begin
  Text:=Copy(Anchors,2,Length(Anchors)-2);if Text.Trim<>'' then begin Parts:=Text.Split([',']);for Token in Parts do begin
   Text:=LowerCase(Token.Trim);if Text='akleft' then Left:=True else if Text='akright' then Right:=True else if Text='aktop' then Top:=True else if Text='akbottom' then Bottom:=True else Valid:=False;
  end;end;
 end;
 if Anchors='' then Result:=Result+'Anchors not serialized: no default set is invented.'
 else if not Valid then Result:=Result+'Unsupported Anchors value '+Anchors+': no numeric example inferred.'
 else if ARow.GetValue<string>('declaration')<>'object' then Result:=Result+'Inherited/inline declaration: base rules are uncaptured; no numeric example inferred.'
 else if ARow.GetValue('parent_properties')=nil then Result:=Result+'No captured parent: a parent-resize example is not applicable or unknown.'
 else if Mode<>'none' then Result:=Result+'Anchors are captured, but alignment is active or unknown. Review alignment and framework precedence; no anchor-only numeric example inferred.'
 else Result:=Result+Axis(Left,Right,AWidthDelta,'Horizontal','width','left')+sLineBreak+Axis(Top,Bottom,AHeightDelta,'Vertical','height','top')+sLineBreak+'These are basic edge-constraint examples only, not predicted final bounds. Constraints, autosizing, spacing, DPI and custom layout can override or qualify them.';
 Result:=Result+sLineBreak+sLineBreak+'SPACING CONSTRAINTS AND RESPONSIVE BEHAVIOR'+sLineBreak+
 'Margins describe outside spacing; Padding describes inside spacing for children. VCL AlignWithMargins can govern margin participation; missing flags are unknown. Constraints limit permitted dimensions. AutoSize can derive size from content. WordWrap can change text flow without proving automatic control height. Scaled, PixelsPerInch and Scale properties affect coordinate interpretation; VCL/FMX units and DPI may differ. OnResize/OnCanResize/OnConstrainedResize and alignment events can replace simple design rules. No breakpoint, wrapping policy or runtime resize handler behavior is invented.'+sLineBreak;
 for Text in ['Width','Height'] do if TryStrToFloat(Prop('Constraints.Min'+Text),MinValue,TFormatSettings.Invariant) and TryStrToFloat(Prop('Constraints.Max'+Text),MaxValue,TFormatSettings.Invariant) and (MaxValue>0) and (MinValue>MaxValue) then Result:=Result+'Review candidate: Constraints.Min'+Text+' exceeds nonzero Max'+Text+'. This is captured evidence, not an observed defect.'+sLineBreak;
 Result:=Result+sLineBreak+'PARENT LAYOUT CONTEXT'+sLineBreak;
 if ARow.TryGetValue<TJSONArray>('parent_properties',Props) then begin for V in Props do if LayoutProperty(V.GetValue<string>('name')) then Result:=Result+'Parent '+V.GetValue<string>('name')+' = '+V.GetValue<string>('value')+' | line '+IntToStr(V.GetValue<Integer>('line'))+sLineBreak;end
 else Result:=Result+'No serialized parent captured.'+sLineBreak;
 Result:=Result+sLineBreak+'HOW TO CHECK THIS'+sLineBreak+'Compare these declarations with the Object Inspector. Resize the target at narrow, wide and high-DPI settings; observe text wrapping, clipping, minimum sizes and sibling allocation. Form designs is an approximate serialized reconstruction, not a responsive layout engine or screenshot. Missing properties can be defaults, inherited or not applicable, and remain unknown.';
end;
end.
