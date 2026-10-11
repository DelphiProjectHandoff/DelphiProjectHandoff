unit DPH.Parse.Resources;
interface
uses DPH.Parse.Model, DPH.Project.Source;
type
  TDPHResourceParser = class
  public
    class function Parse(ASource: TDPHSource; ADiagnostics: TDPHDiagnostics): TDPHParseResult; static;
  end;
implementation
uses System.SysUtils, System.Classes, System.IOUtils, System.JSON, System.Variants,
  Xml.XMLDoc, Xml.XMLIntf;

class function TDPHResourceParser.Parse(ASource: TDPHSource; ADiagnostics: TDPHDiagnostics): TDPHParseResult;
var Parsed: TDPHParseResult; JSON: TJSONValue; XML: IXMLDocument;
    Position,LineEnd,Separator,Root,Section,Node,Offset,HeaderEnd,DataEnd: Integer;
    DataSize,HeaderSize: Cardinal; Line,Name,Value,Kind: string; JSONDepth: Integer; InString,Escaped: Boolean; C: Char;
  function Add(const AKind,AName,AValue: string; Parent,Start,Finish: Integer; Binary: Boolean = False): Integer;
  var N: TDPHIRNode;
  begin
    if Parsed.Nodes.Count>=DPHMaxNodes then raise EReadError.Create('Resource node limit');
    N:=Default(TDPHIRNode); N.Kind:=AKind; N.Name:=AName; N.Value:=AValue; N.Parent:=Parent;
    if Binary then begin N.Location.Source:=ASource.RelativePath; N.Location.StartByte:=Start; N.Location.EndByte:=Finish; end
    else N.Location:=ASource.Range(Start,Finish);
    Result:=Parsed.Nodes.Add(N);
  end;
  procedure JSONNodes(Item: TJSONValue; const Path: string; Parent,Depth: Integer);
  var Pair: TJSONPair; Child: TJSONValue; Index,ItemNode: Integer;
  begin
    if Depth>DPHMaxNesting then raise EReadError.Create('JSON resource nesting limit');
    if Item is TJSONObject then begin
      ItemNode:=Add('json_object',Path,'',Parent,0,Length(ASource.Text));
      for Pair in TJSONObject(Item) do JSONNodes(Pair.JsonValue,Path+'/'+Pair.JsonString.Value.Replace('~','~0').Replace('/','~1'),ItemNode,Depth+1);
    end else if Item is TJSONArray then begin
      ItemNode:=Add('json_array',Path,'',Parent,0,Length(ASource.Text)); Index:=0;
      for Child in TJSONArray(Item) do begin JSONNodes(Child,Path+'/'+IntToStr(Index),ItemNode,Depth+1); Inc(Index); end;
    end else Add('json_value',Path,Item.ToJSON,Parent,0,Length(ASource.Text));
  end;
  procedure XMLNodes(Item: IXMLNode; const Path: string; Parent,Depth: Integer);
  var Index,ItemNode: Integer; Attribute: IXMLNode; Text: string;
  begin
    if Depth>DPHMaxNesting then raise EReadError.Create('XML resource nesting limit');
    if Item.NodeType<>ntElement then Exit;
    Text:=''; if Item.IsTextElement then Text:=Item.Text;
    ItemNode:=Add('xml_element',Path+'/'+Item.NodeName,Text,Parent,0,Length(ASource.Text));
    for Index:=0 to Item.AttributeNodes.Count-1 do begin
      Attribute:=Item.AttributeNodes[Index]; Add('xml_attribute',Attribute.NodeName,VarToStr(Attribute.NodeValue),ItemNode,0,Length(ASource.Text));
    end;
    for Index:=0 to Item.ChildNodes.Count-1 do XMLNodes(Item.ChildNodes[Index],Path+'/'+Item.NodeName,ItemNode,Depth+1);
  end;
  function WordAt(Index: Integer): Word;
  begin
    if (Index<0) or (Index+2>Length(ASource.Bytes)) then raise EReadError.Create('Truncated resource directory');
    Result:=ASource.Bytes[Index] or (Word(ASource.Bytes[Index+1]) shl 8);
  end;
  function DWordAt(Index: Integer): Cardinal;
  begin Result:=WordAt(Index) or (Cardinal(WordAt(Index+2)) shl 16); end;
  function ResourceID(var Index: Integer): string;
  var W: Word;
  begin
    if Index+2>HeaderEnd then raise EReadError.Create('Resource identifier exceeds header');
    W:=WordAt(Index); Inc(Index,2);
    if W=$FFFF then begin
      if Index+2>HeaderEnd then raise EReadError.Create('Resource ordinal exceeds header');
      Result:='#'+IntToStr(WordAt(Index)); Inc(Index,2); Exit;
    end;
    Result:='';
    while W<>0 do begin
      if (Index+2>HeaderEnd) or (Length(Result)>=4096) then raise EReadError.Create('Resource identifier exceeds header');
      Result:=Result+Char(W); W:=WordAt(Index); Inc(Index,2);
    end;
  end;
begin
  Parsed:=TDPHParseResult.Create; JSON:=nil;
  try
    try
      Kind:=LowerCase(ExtractFileExt(ASource.Path));
      if Kind='.res' then Root:=Add('resource',ASource.RelativePath,Kind,-1,0,Length(ASource.Bytes),True)
      else Root:=Add('resource',ASource.RelativePath,Kind,-1,0,Length(ASource.Text));
      if Kind='.res' then begin
        Position:=0;
        while Position<Length(ASource.Bytes) do begin
          if Length(ASource.Bytes)-Position<8 then raise EReadError.Create('Truncated resource header');
          DataSize:=DWordAt(Position); HeaderSize:=DWordAt(Position+4);
          if (HeaderSize<32) or (Int64(Position)+HeaderSize+DataSize>Length(ASource.Bytes)) then raise EReadError.Create('Invalid resource header/data extent');
          HeaderEnd:=Position+Integer(HeaderSize); DataEnd:=HeaderEnd+Integer(DataSize); Offset:=Position+8;
          Name:=ResourceID(Offset); Value:=ResourceID(Offset); Offset:=(Offset+3) and not 3;
          if Offset+16>HeaderEnd then raise EReadError.Create('Resource metadata exceeds header');
          Node:=Add('compiled_resource',Value,'type='+Name+';language='+IntToStr(WordAt(Offset+6))+';bytes='+UIntToStr(DataSize),Root,Position,DataEnd,True);
          Add('resource_payload',Value,'Opaque bytes retained; resource payload is not instantiated or executed.',Node,HeaderEnd,DataEnd,True);
          if DataSize>0 then begin Parsed.Complete:=False; ADiagnostics.Report('OPAQUE_RESOURCE_PAYLOAD','Compiled resource directory parsed; payload decoding is not implemented',ASource.Range(0,0)); end;
          Position:=(DataEnd+3) and not 3;
          if Position>Length(ASource.Bytes) then Position:=Length(ASource.Bytes);
        end;
      end else begin
        if not ASource.Decoded then raise EReadError.Create('Resource text requires a valid selected encoding');
        if Kind='.json' then begin
          JSONDepth:=0; InString:=False; Escaped:=False;
          for C in ASource.Text do begin
            if InString then begin
              if Escaped then Escaped:=False else if C='\' then Escaped:=True else if C='"' then InString:=False;
            end else if C='"' then InString:=True
            else if CharInSet(C,['{','[']) then begin Inc(JSONDepth); if JSONDepth>DPHMaxNesting then raise EReadError.Create('JSON resource nesting limit'); end
            else if CharInSet(C,['}',']']) then Dec(JSONDepth);
          end;
          JSON:=TJSONObject.ParseJSONValue(ASource.Text,False,True); if JSON=nil then raise EReadError.Create('Invalid JSON resource'); JSONNodes(JSON,'',Root,0);
        end else if Kind='.sql' then begin
          Add('sql_text','statement',ASource.Text,Root,0,Length(ASource.Text));
        end else if Kind='.xml' then begin
          if ASource.Text.ToUpper.Contains('<!DOCTYPE') or ASource.Text.ToUpper.Contains('<!ENTITY') then raise EReadError.Create('Resource XML DTD/entity declarations are prohibited');
          XML:=LoadXMLData(ASource.Text); XMLNodes(XML.DocumentElement,'',Root,0);
        end else begin
          Position:=1; Section:=Root;
          while Position<=Length(ASource.Text) do begin
            LineEnd:=Position; while (LineEnd<=Length(ASource.Text)) and not CharInSet(ASource.Text[LineEnd],[#10,#13]) do Inc(LineEnd);
            Line:=Trim(Copy(ASource.Text,Position,LineEnd-Position));
            if (Line<>'') and not Line.StartsWith(';') and not Line.StartsWith('//') then begin
              if (Kind='.ini') and Line.StartsWith('[') and Line.EndsWith(']') then Section:=Add('ini_section',Copy(Line,2,Length(Line)-2),'',Root,Position-1,LineEnd-1)
              else if Kind='.ini' then begin
                Separator:=Pos('=',Line); if Separator>0 then Add('ini_value',Trim(Copy(Line,1,Separator-1)),Trim(Copy(Line,Separator+1,MaxInt)),Section,Position-1,LineEnd-1)
                else raise EReadError.Create('INI entry has no equals sign');
              end else Add('rc_statement','',Line,Root,Position-1,LineEnd-1);
            end;
            Position:=LineEnd+1; if (LineEnd<Length(ASource.Text)) and (ASource.Text[LineEnd]=#13) and (ASource.Text[LineEnd+1]=#10) then Inc(Position);
          end;
          if Kind='.rc' then begin Parsed.Complete:=False; ADiagnostics.Report('RC_LINE_ONLY','Resource script statements retained; macro evaluation and dialog compilation are not performed',ASource.Range(0,0)); end;
        end;
      end;
    except on E: Exception do begin Parsed.Complete:=False; ADiagnostics.Report('RESOURCE_PARSE_ERROR',E.Message,ASource.Range(0,0),'error'); end; end;
    Result:=Parsed; Parsed:=nil;
  finally JSON.Free; Parsed.Free; end;
end;
end.
