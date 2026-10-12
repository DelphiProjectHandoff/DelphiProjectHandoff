unit DPH.Workspace.ScreenHistory;
interface
uses System.SysUtils,System.JSON,DPH.Workspace.Model;
type TDPHScreenHistory=class
 class function CompareImages(ABefore,AAfter:TJSONObject;out ABeforePNG,AAfterPNG,ADifferencePNG:TBytes):TJSONObject;static;
 class function CompareLayouts(ABefore,AAfter:TDPHWorkspaceView;const ABeforeFile,AAfterFile:string):TJSONObject;static;
 class function Describe(AReport:TJSONObject):string;static;
end;
implementation
uses System.Classes,System.IOUtils,System.Hash,System.Math,System.Types,System.StrUtils,
 System.Generics.Collections,Vcl.Graphics,Vcl.Imaging.pngimage,Winapi.Windows,
 DPH.Workspace.Keyboard,DPH.Workspace.Screen;
class function TDPHScreenHistory.CompareImages(ABefore,AAfter:TJSONObject;out ABeforePNG,AAfterPNG,ADifferencePNG:TBytes):TJSONObject;
var Images:array[0..1] of TPngImage;Bitmaps:array[0..1] of Vcl.Graphics.TBitmap;
 Mask:Vcl.Graphics.TBitmap;Encoded:TPngImage;Input:TBytesStream;Output:TMemoryStream;Rows:array[0..2] of PByte;
 Meta:TJSONObject;Bytes:TBytes;Hasher:THashSHA2;W,H,I,X,Y,C,Changed,BeforeOnly,AfterOnly,LeftEdge,TopEdge,RightEdge,BottomEdge:Integer;
 Width,Height:Int64;Different,InBefore,InAfter:Boolean;Side:TJSONObject;
begin
 ABeforePNG:=nil;AAfterPNG:=nil;ADifferencePNG:=nil;Result:=nil;
 if (ABefore=nil) or (AAfter=nil) then raise EArgumentException.Create('Select both screenshot records');
 Images[0]:=nil;Images[1]:=nil;Bitmaps[0]:=nil;Bitmaps[1]:=nil;Mask:=nil;Encoded:=nil;
 try
 try
  for I:=0 to 1 do begin
   if I=0 then Meta:=ABefore else Meta:=AAfter;
   if TFile.GetSize(Meta.GetValue<string>('managed_path'))>20*1024*1024 then raise EReadError.Create('Screenshot exceeds 20 MiB');
   Bytes:=TFile.ReadAllBytes(Meta.GetValue<string>('managed_path'));
   Hasher:=THashSHA2.Create;Hasher.Update(Bytes);if (Length(Bytes)>20*1024*1024) or (Hasher.HashAsString<>Meta.GetValue<string>('image_sha256')) then raise EReadError.Create('Screenshot bytes changed after validation');
   if (Length(Bytes)<33) or (Bytes[0]<>137) or (Bytes[1]<>80) or (Bytes[2]<>78) or (Bytes[3]<>71) or (Bytes[4]<>13) or (Bytes[5]<>10) or (Bytes[6]<>26) or (Bytes[7]<>10) or (Bytes[12]<>73) or (Bytes[13]<>72) or (Bytes[14]<>68) or (Bytes[15]<>82) then raise EReadError.Create('Invalid PNG header');
   Width:=Int64(Bytes[16])*16777216+Int64(Bytes[17])*65536+Int64(Bytes[18])*256+Bytes[19];Height:=Int64(Bytes[20])*16777216+Int64(Bytes[21])*65536+Int64(Bytes[22])*256+Bytes[23];
   if (Width<1) or (Height<1) or (Width>8192) or (Height>8192) or (Width*Height>16000000) then raise EReadError.Create('Comparison supports at most 16 million pixels per image and union canvas; dimensions at most 8192');
   Images[I]:=TPngImage.Create;Input:=TBytesStream.Create(Bytes);try Images[I].LoadFromStream(Input);finally Input.Free;end;
   if (Images[I].Width<>Width) or (Images[I].Height<>Height) then raise EReadError.Create('Decoded PNG dimensions disagree with header');
   Bitmaps[I]:=Vcl.Graphics.TBitmap.Create;Bitmaps[I].PixelFormat:=pf24bit;Bitmaps[I].SetSize(Width,Height);
   Bitmaps[I].Canvas.Brush.Color:=clWhite;Bitmaps[I].Canvas.FillRect(Rect(0,0,Width,Height));Bitmaps[I].Canvas.Draw(0,0,Images[I]);
   if I=0 then ABeforePNG:=Bytes else AAfterPNG:=Bytes;
  end;
  W:=Max(Bitmaps[0].Width,Bitmaps[1].Width);H:=Max(Bitmaps[0].Height,Bitmaps[1].Height);
  if Int64(W)*H>16000000 then raise EReadError.Create('Union canvas exceeds 16 million pixels; no automatic resampling is performed');
  Mask:=Vcl.Graphics.TBitmap.Create;Mask.PixelFormat:=pf24bit;Mask.SetSize(W,H);
  Changed:=0;BeforeOnly:=0;AfterOnly:=0;LeftEdge:=W;TopEdge:=H;RightEdge:=-1;BottomEdge:=-1;
  for Y:=0 to H-1 do begin
   for I:=0 to 1 do if Y<Bitmaps[I].Height then Rows[I]:=Bitmaps[I].ScanLine[Bitmaps[I].Height-1-Y] else Rows[I]:=nil;
   Rows[2]:=Mask.ScanLine[H-1-Y];
   for X:=0 to W-1 do begin
    InBefore:=(Y<Bitmaps[0].Height) and (X<Bitmaps[0].Width);InAfter:=(Y<Bitmaps[1].Height) and (X<Bitmaps[1].Width);
    Different:=InBefore<>InAfter;
    if InBefore and InAfter then for C:=0 to 2 do if PByteArray(Rows[0])^[X*3+C]<>PByteArray(Rows[1])^[X*3+C] then Different:=True;
    if not InBefore and not InAfter then Different:=False;
    for C:=0 to 2 do PByteArray(Rows[2])^[X*3+C]:=255;
    if Different then begin
     Inc(Changed);LeftEdge:=Min(LeftEdge,X);TopEdge:=Min(TopEdge,Y);RightEdge:=Max(RightEdge,X);BottomEdge:=Max(BottomEdge,Y);
     if not InAfter then Inc(BeforeOnly) else if not InBefore then Inc(AfterOnly);
     PByteArray(Rows[2])^[X*3+1]:=0;
     if InBefore and InAfter then PByteArray(Rows[2])^[X*3]:=0;
    end;
   end;
  end;
  Encoded:=TPngImage.Create;Encoded.Assign(Mask);Output:=TMemoryStream.Create;
  try Encoded.SaveToStream(Output);SetLength(ADifferencePNG,Output.Size);Output.Position:=0;Output.ReadBuffer(ADifferencePNG,Length(ADifferencePNG));finally Output.Free;end;
  Result:=TJSONObject.Create;Result.AddPair('definition','Exact decoded 8-bit RGB comparison after PNG transparency is composited on white. Top-left coordinates; no registration, scaling, tolerance or color-profile normalization. Red = changed overlapping pixel; magenta = Before-only/After-only extent; white = unchanged or outside both images. Pixel change is not proof of a software defect, source cause or business effect.');
  for I:=0 to 1 do begin if I=0 then Meta:=ABefore else Meta:=AAfter;Side:=Meta.Clone as TJSONObject;Side.RemovePair('managed_path').Free;Side.AddPair('width',TJSONNumber.Create(Bitmaps[I].Width)).AddPair('height',TJSONNumber.Create(Bitmaps[I].Height));if I=0 then Result.AddPair('before',Side) else Result.AddPair('after',Side);end;
  Result.AddPair('width',TJSONNumber.Create(W)).AddPair('height',TJSONNumber.Create(H)).AddPair('changed_pixels',TJSONNumber.Create(Changed)).AddPair('before_only_pixels',TJSONNumber.Create(BeforeOnly)).AddPair('after_only_pixels',TJSONNumber.Create(AfterOnly));
  if Changed=0 then Result.AddPair('changed_bounds',TJSONNull.Create) else Result.AddPair('changed_bounds',TJSONObject.Create.AddPair('left',TJSONNumber.Create(LeftEdge)).AddPair('top',TJSONNumber.Create(TopEdge)).AddPair('right_inclusive',TJSONNumber.Create(RightEdge)).AddPair('bottom_inclusive',TJSONNumber.Create(BottomEdge)));
 except Result.Free;Result:=nil;ABeforePNG:=nil;AAfterPNG:=nil;ADifferencePNG:=nil;raise;end;
 finally Encoded.Free;Mask.Free;for I:=0 to 1 do begin Bitmaps[I].Free;Images[I].Free;end;end;
end;
class function TDPHScreenHistory.CompareLayouts(ABefore,AAfter:TDPHWorkspaceView;const ABeforeFile,AAfterFile:string):TJSONObject;
var Captures:array[0..1] of TJSONObject;Maps:array[0..1] of TDictionary<string,TJSONObject>;
 Nodes:TDictionary<Integer,TJSONObject>;Keys:TStringList;Properties:TStringList;Changes:TJSONArray;
 V,P:TJSONValue;Row,Parent,Change,OldRow,NewRow,BeforeLayout,AfterLayout:TJSONObject;Path,Values,OldValues,NewValues:string;I,Depth:Integer;
begin
 Result:=nil;BeforeLayout:=nil;AfterLayout:=nil;Captures[0]:=nil;Captures[1]:=nil;Maps[0]:=nil;Maps[1]:=nil;
 if (ABefore=nil) or (AAfter=nil) then raise EArgumentException.Create('Both retained captures are required');
 if (ABefore.Document.GetValue<string>('syntax.analyzer')<>AAfter.Document.GetValue<string>('syntax.analyzer')) or (ABefore.Document.GetValue<Integer>('syntax.schema_version')<>AAfter.Document.GetValue<Integer>('syntax.schema_version')) then raise EArgumentException.Create('Layout comparison requires compatible captured parser contracts');
 if not SameText(ABefore.Document.GetValue<string>('entry'),AAfter.Document.GetValue<string>('entry')) or (ABefore.Document.GetValue<string>('selection_hash')<>AAfter.Document.GetValue<string>('selection_hash')) then raise EArgumentException.Create('Layout comparison requires the same project and analysis selection');
 if (ABeforeFile='') or (AAfterFile='') then raise EArgumentException.Create('Enter both relative DFM/FMX paths for captured layout comparison');
 if (ABefore.SourceFile(ABeforeFile)=nil) or (AAfter.SourceFile(AAfterFile)=nil) then raise EArgumentException.Create('A selected form file is absent from its captured generation');
 if not MatchText(ExtractFileExt(ABeforeFile),['.dfm','.fmx']) or not MatchText(ExtractFileExt(AAfterFile),['.dfm','.fmx']) then raise EArgumentException.Create('Select captured DFM or FMX form paths');
 Nodes:=TDictionary<Integer,TJSONObject>.Create;Keys:=TStringList.Create;Properties:=TStringList.Create;
 try
 try
  for I:=0 to 1 do begin
   Maps[I]:=TDictionary<string,TJSONObject>.Create;
   if I=0 then Captures[I]:=TDPHKeyboardInspector.Inspect(ABefore) else Captures[I]:=TDPHKeyboardInspector.Inspect(AAfter);
   Nodes.Clear;
   for V in Captures[I].GetValue<TJSONArray>('rows') do begin Row:=V as TJSONObject;if ((I=0) and SameText(Row.GetValue<string>('source'),ABeforeFile)) or ((I=1) and SameText(Row.GetValue<string>('source'),AAfterFile)) then Nodes.Add(Row.GetValue<Integer>('node'),Row);end;
   if Nodes.Count=0 then raise EArgumentException.Create('No parsed components in a selected form; layout remains unavailable');
   if Nodes.Count>5000 then raise EArgumentException.Create('Layout comparison supports at most 5000 components per form');
   for Row in Nodes.Values do begin
    Parent:=Row;Path:=Row.GetValue<string>('name');
    for Depth:=0 to 127 do begin if not Nodes.TryGetValue(Parent.GetValue<Integer>('parent_node'),Parent) then Break;Path:=Parent.GetValue<string>('name')+'/'+Path;end;
    Path:=LowerCase(Path);if Maps[I].ContainsKey(Path) then raise EArgumentException.Create('Ambiguous duplicate component path: '+Path);
    Maps[I].Add(Path,Row);if Keys.IndexOf(Path)<0 then Keys.Add(Path);
   end;
  end;
  Keys.Sort;Result:=TJSONObject.Create;Changes:=TJSONArray.Create;Result.AddPair('changes',Changes);
  for Path in Keys do begin
   Maps[0].TryGetValue(Path,OldRow);Maps[1].TryGetValue(Path,NewRow);OldValues:='';NewValues:='';
   for I:=0 to 1 do begin if I=0 then Row:=OldRow else Row:=NewRow;Values:='';
    if Row<>nil then begin Properties.Clear;for P in Row.GetValue<TJSONArray>('properties') do Properties.Add(P.GetValue<string>('name')+' = '+P.GetValue<string>('value'));Properties.Sort;Values:=Row.GetValue<string>('class')+sLineBreak+Properties.Text;end;
    if I=0 then OldValues:=Values else NewValues:=Values;
   end;
   if (OldRow<>nil) and (NewRow<>nil) and (OldValues=NewValues) then Continue;
   Change:=TJSONObject.Create;Changes.AddElement(Change);Change.AddPair('path',Path).AddPair('before_values',OldValues).AddPair('after_values',NewValues);
   if OldRow=nil then Change.AddPair('kind','added') else if NewRow=nil then Change.AddPair('kind','removed') else Change.AddPair('kind','changed');
   if OldRow=nil then Change.AddPair('before',TJSONNull.Create) else Change.AddPair('before',OldRow.Clone as TJSONValue);
   if NewRow=nil then Change.AddPair('after',TJSONNull.Create) else Change.AddPair('after',NewRow.Clone as TJSONValue);
  end;
  BeforeLayout:=TDPHScreenLayout.Reconstruct(ABefore,ABeforeFile);AfterLayout:=TDPHScreenLayout.Reconstruct(AAfter,AAfterFile);
  Result.AddPair('before',BeforeLayout);BeforeLayout:=nil;Result.AddPair('after',AfterLayout);AfterLayout:=nil;
  Result.AddPair('before_generation',ABefore.Document.GetValue('generation_id').Clone as TJSONValue).AddPair('after_generation',AAfter.Document.GetValue('generation_id').Clone as TJSONValue);
  Result.AddPair('definition','Captured component paths, classes and serialized inspector properties, not runtime geometry. Missing properties stay unknown/default/inherited. Renames appear added/removed. Source offsets alone do not change a component. Drawings are approximate reconstructions and show at most 300 rectangles per pane; all supported changes remain in the paged list. Blue = Before; orange = After. No target class is instantiated.');
 except Result.Free;Result:=nil;raise;end;
 finally BeforeLayout.Free;AfterLayout.Free;for I:=0 to 1 do begin Captures[I].Free;Maps[I].Free;end;Properties.Free;Keys.Free;Nodes.Free;end;
end;
class function TDPHScreenHistory.Describe(AReport:TJSONObject):string;
var Key:string;Side,Layout:TJSONObject;
begin
 Result:=AReport.GetValue<string>('definition')+sLineBreak+Format('Changed pixels: %d | Before-only: %d | After-only: %d | union %d x %d',[AReport.GetValue<Integer>('changed_pixels'),AReport.GetValue<Integer>('before_only_pixels'),AReport.GetValue<Integer>('after_only_pixels'),AReport.GetValue<Integer>('width'),AReport.GetValue<Integer>('height')])+sLineBreak+'Changed bounds: '+AReport.GetValue('changed_bounds').ToJSON+sLineBreak;
 for Key in ['before','after'] do begin Side:=AReport.GetValue<TJSONObject>(Key);Result:=Result+sLineBreak+UpperCase(Key)+': '+Side.GetValue<string>('caption')+sLineBreak+'Artifact '+Side.GetValue('artifact_id').Value+' | generation '+Side.GetValue('generation_id').Value+' | contributor '+Side.GetValue<string>('author')+sLineBreak+'Imported '+Side.GetValue<string>('imported_utc')+' | '+Side.GetValue<string>('verification_state')+sLineBreak+'Image SHA256 '+Side.GetValue<string>('image_sha256')+sLineBreak+'Metadata SHA256 '+Side.GetValue<string>('artifact_hash')+sLineBreak+'Object '+Side.GetValue<string>('entity_key','')+sLineBreak+Side.GetValue<string>('provenance')+sLineBreak;end;
 if AReport.TryGetValue<TJSONObject>('layout',Layout) then Result:=Result+sLineBreak+Layout.GetValue<string>('definition')+sLineBreak+'Before '+Layout.GetValue<string>('before.source')+' SHA256 '+Layout.GetValue<string>('before.source_hash','')+sLineBreak+'After '+Layout.GetValue<string>('after.source')+' SHA256 '+Layout.GetValue<string>('after.source_hash','')
 else Result:=Result+sLineBreak+'Layout unavailable: '+AReport.GetValue<string>('layout_gap','Not requested');
end;
end.
