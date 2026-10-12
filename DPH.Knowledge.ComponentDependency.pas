unit DPH.Knowledge.ComponentDependency;
interface
uses System.SysUtils,System.JSON;
const
 DPHComponentDependencyKeys:array[0..6] of string=('class_name','unit_name','package_name','vendor','version','support','evidence');
 DPHComponentDependencyLabels:array[0..6] of string=('Component class identity','Declaring unit','Package or product','Vendor or maintainer','Version and configuration','Support and replacement considerations','Evidence references and remaining unknowns');
type TDPHComponentDependency=class
 class procedure Validate(ARecord:TJSONObject);static;
 class function Body(ARecord:TJSONObject):string;static;
 class function Title(ARecord:TJSONObject):string;static;
end;
implementation
class procedure TDPHComponentDependency.Validate(ARecord:TJSONObject);
var Fields:TJSONObject;Pair:TJSONPair;Key:string;Known:Boolean;
begin
 if (ARecord=nil) or (ARecord.GetValue<string>('record_type','')<>'component_dependency') then raise EArgumentException.Create('Expected a component dependency record');
 if Length(ARecord.ToJSON)>65536 then raise EArgumentException.Create('Component dependency exceeds 64 KiB');
 for Pair in ARecord do if (Pair.JsonString.Value<>'record_type') and (Pair.JsonString.Value<>'fields') then raise EArgumentException.Create('Unknown component dependency metadata');
 if not ARecord.TryGetValue<TJSONObject>('fields',Fields) then raise EArgumentException.Create('Component dependency requires fields');
 for Pair in Fields do begin
  Known:=False;for Key in DPHComponentDependencyKeys do if Pair.JsonString.Value=Key then Known:=True;
  if not Known then raise EArgumentException.Create('Unknown component dependency field');
  if not (Pair.JsonValue is TJSONString) then raise EArgumentException.Create('Component dependency values must be text');
  if Length(Pair.JsonValue.Value)>4096 then raise EArgumentException.Create('Component dependency field exceeds 4096 characters');
 end;
 Key:=Fields.GetValue<string>('class_name','');
 if (Key.Trim='') or (Key<>Key.Trim) or Key.Contains(#10) or Key.Contains(#13) or (Length(Key)>255) then raise EArgumentException.Create('Enter one component class identity without surrounding whitespace');
 if Fields.GetValue<string>('evidence','').Trim='' then raise EArgumentException.Create('Enter evidence references and remaining unknowns');
end;
class function TDPHComponentDependency.Title(ARecord:TJSONObject):string;
begin Validate(ARecord);Result:='Component dependency: '+ARecord.GetValue<string>('fields.class_name');end;
class function TDPHComponentDependency.Body(ARecord:TJSONObject):string;
var I:Integer;Text:string;Fields:TJSONObject;
begin
 Validate(ARecord);Fields:=ARecord.GetValue<TJSONObject>('fields');
 Result:='Component dependency'+sLineBreak+'Human-authored package, vendor, version and support claims. Saving does not resolve source dependencies or verify these claims.'+sLineBreak;
 for I:=0 to High(DPHComponentDependencyKeys) do begin
  Text:=Fields.GetValue<string>(DPHComponentDependencyKeys[I],'').Trim;if Text='' then Text:='Not supplied; remains unknown.';
  Result:=Result+sLineBreak+DPHComponentDependencyLabels[I]+':'+sLineBreak+Text+sLineBreak;
 end;
 Result:=TrimRight(Result);
end;
end.
