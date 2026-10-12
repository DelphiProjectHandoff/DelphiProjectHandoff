unit DPH.Knowledge.Glossary;
interface
uses System.SysUtils, System.JSON;
type
  TDPHGlossary = class
  public
    class function NameKey(const AName: string): string; static;
    class procedure Validate(ARecord: TJSONObject); static;
    class function Names(ARecord: TJSONObject): TArray<string>; static;
    class function Body(ARecord: TJSONObject): string; static;
  end;
implementation
uses System.RegularExpressions, System.Generics.Collections;
class function TDPHGlossary.NameKey(const AName: string): string;
begin Result:=TRegEx.Replace(AName.Trim,'\s+',' ').ToLowerInvariant; end;
class procedure TDPHGlossary.Validate(ARecord: TJSONObject);
var Pair: TJSONPair; Value: TJSONValue; Aliases: TJSONArray; Seen: TDictionary<string,Boolean>; Key,Field: string;
begin
  if (ARecord=nil) or (ARecord.GetValue<string>('record_type','')<>'business_glossary') then
    raise EArgumentException.Create('Expected a business glossary term');
  if Length(ARecord.ToJSON)>65536 then raise EArgumentException.Create('Glossary record exceeds 64 KiB');
  Seen:=TDictionary<string,Boolean>.Create;
  try
    for Pair in ARecord do begin
      Field:=Pair.JsonString.Value;
      if Seen.ContainsKey(Field) then raise EArgumentException.Create('Duplicate glossary field: '+Field);
      Seen.Add(Field,True);
      if not ((Field='record_type') or (Field='term') or (Field='aliases') or (Field='definition') or
        (Field='examples') or (Field='context')) then raise EArgumentException.Create('Unknown glossary field: '+Field);
      if (Field<>'aliases') and not (Pair.JsonValue is TJSONString) then raise EArgumentException.Create('Glossary fields must be text');
    end;
    for Field in ['term','definition','context'] do
      if ARecord.GetValue<string>(Field,'').Trim='' then raise EArgumentException.Create('Enter '+Field+' for this term');
    if Length(ARecord.GetValue<string>('term'))>128 then raise EArgumentException.Create('Term exceeds 128 characters');
    if TRegEx.IsMatch(ARecord.GetValue<string>('term'),'[\r\n\t]') then raise EArgumentException.Create('Term must occupy one line without tabs');
    if (Length(ARecord.GetValue<string>('definition'))>16384) or (Length(ARecord.GetValue<string>('examples',''))>16384) or
      (Length(ARecord.GetValue<string>('context'))>4096) then raise EArgumentException.Create('Definition/examples limit is 16384 characters; context limit is 4096');
    if not ARecord.TryGetValue<TJSONArray>('aliases',Aliases) then raise EArgumentException.Create('Aliases must be a list');
    if Aliases.Count>32 then raise EArgumentException.Create('Use at most 32 aliases');
    Seen.Clear; Seen.Add(NameKey(ARecord.GetValue<string>('term')),True);
    for Value in Aliases do begin
      if not (Value is TJSONString) then raise EArgumentException.Create('Each alias must be text');
      Key:=NameKey(Value.Value);
      if (Key='') or (Length(Value.Value)>128) or TRegEx.IsMatch(Value.Value,'[\r\n\t]') then
        raise EArgumentException.Create('Each alias must occupy one nonempty line of at most 128 characters');
      if Seen.ContainsKey(Key) then raise EArgumentException.Create('Duplicate term or alias: '+Value.Value);
      Seen.Add(Key,True);
    end;
  finally Seen.Free; end;
end;
class function TDPHGlossary.Names(ARecord: TJSONObject): TArray<string>;
var Value: TJSONValue; Index: Integer;
begin
  Validate(ARecord); SetLength(Result,ARecord.GetValue<TJSONArray>('aliases').Count+1);
  Result[0]:=NameKey(ARecord.GetValue<string>('term')); Index:=1;
  for Value in ARecord.GetValue<TJSONArray>('aliases') do begin Result[Index]:=NameKey(Value.Value); Inc(Index); end;
end;
class function TDPHGlossary.Body(ARecord: TJSONObject): string;
var Value: TJSONValue; AliasText: string;
begin
  Validate(ARecord); AliasText:='';
  for Value in ARecord.GetValue<TJSONArray>('aliases') do begin if AliasText<>'' then AliasText:=AliasText+', '; AliasText:=AliasText+Value.Value.Trim; end;
  if AliasText='' then AliasText:='None supplied';
  Result:='Business term: '+ARecord.GetValue<string>('term').Trim+sLineBreak+
    'Aliases: '+AliasText+sLineBreak+sLineBreak+'Definition:'+sLineBreak+ARecord.GetValue<string>('definition').Trim+
    sLineBreak+sLineBreak+'Examples:'+sLineBreak+ARecord.GetValue<string>('examples','').Trim+
    sLineBreak+sLineBreak+'Relevance and evidence context:'+sLineBreak+ARecord.GetValue<string>('context').Trim;
end;
end.
