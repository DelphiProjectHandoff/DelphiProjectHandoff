unit DPH.Knowledge.ProjectProfile;

interface
uses System.SysUtils, System.JSON;
const
  DPHProjectProfileFieldCount = 15;
  DPHProjectProfileKeys: array[0..14] of string = ('purpose','company','department','business_unit','criticality','owner','support','environments','relationships','lifecycle','maturity','vendor','license','architecture','evidence');
  DPHProjectProfileLabels: array[0..14] of string = ('Application purpose and scope','Company','Department','Business unit','Business criticality and consequences','Application owner','Support contacts and escalation','Development, test, staging and production environments','Relevant applications and dependencies','Active, legacy, retired or planned status','Maturity and maintenance status','Vendor and support arrangements','License and usage conditions','Architecture and constraints','Attribution, evidence references and remaining unknowns');
type
  TDPHProjectProfile = class
  public
    class procedure Validate(ARecord: TJSONObject); static;
    class function Body(ARecord: TJSONObject): string; static;
  end;
implementation
class procedure TDPHProjectProfile.Validate(ARecord: TJSONObject);
var Fields: TJSONObject; Pair: TJSONPair; I: Integer; Known: Boolean;
begin
  if (ARecord=nil) or (ARecord.GetValue<string>('record_type','')<>'project_profile') then
    raise EArgumentException.Create('Expected a project profile record');
  if Length(ARecord.ToJSON)>65536 then raise EArgumentException.Create('Project profile exceeds 64 KiB');
  for Pair in ARecord do if (Pair.JsonString.Value<>'record_type') and (Pair.JsonString.Value<>'fields') then
    raise EArgumentException.Create('Unknown project profile metadata');
  if not ARecord.TryGetValue<TJSONObject>('fields',Fields) then raise EArgumentException.Create('Project profile requires fields');
  for Pair in Fields do begin
    Known:=False; for I:=0 to DPHProjectProfileFieldCount-1 do if Pair.JsonString.Value=DPHProjectProfileKeys[I] then Known:=True;
    if not Known then raise EArgumentException.Create('Unknown project profile field: '+Pair.JsonString.Value);
    if not (Pair.JsonValue is TJSONString) then raise EArgumentException.Create('Project profile values must be text');
    if Length(Pair.JsonValue.Value)>4096 then raise EArgumentException.Create('Project profile field exceeds 4096 characters');
  end;
  if Fields.GetValue<string>('purpose','').Trim='' then raise EArgumentException.Create('Enter the selected application purpose and scope');
  if Fields.GetValue<string>('evidence','').Trim='' then raise EArgumentException.Create('Enter attribution, evidence references and remaining unknowns');
end;
class function TDPHProjectProfile.Body(ARecord: TJSONObject): string;
var Fields: TJSONObject; I: Integer; Value: string;
begin
  Validate(ARecord); Fields:=ARecord.GetValue<TJSONObject>('fields');
  Result:='Project profile'+sLineBreak+'Human-authored information about the selected application. Saving does not verify these claims.'+sLineBreak;
  for I:=0 to DPHProjectProfileFieldCount-1 do begin
    Value:=Trim(Fields.GetValue<string>(DPHProjectProfileKeys[I],''));
    if Value='' then Value:='Not supplied; requires attributed information.';
    Result:=Result+sLineBreak+DPHProjectProfileLabels[I]+':'+sLineBreak+Value+sLineBreak;
  end;
  Result:=TrimRight(Result);
end;
end.

