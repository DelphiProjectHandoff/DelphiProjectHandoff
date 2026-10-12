unit DPH.Knowledge.ActionPurpose;
interface
uses System.SysUtils,System.JSON;
const
 DPHActionPurposeKeys:array[0..11] of string=('action_id','target','target_key','action_name','screen','trigger','purpose','preconditions','steps','outcome','evidence','exceptions');
 DPHActionPurposeLabels:array[0..11] of string=('Stable action identity','Captured target or project task','Captured object key','Action or task name','Screen and user role','User trigger','Business purpose','Prerequisites and permissions','Numbered user steps','Expected business outcome','Evidence and remaining unknowns','Failures and recovery');
type TDPHActionPurpose=class
 class procedure Validate(ARecord:TJSONObject);static;
 class function Body(ARecord:TJSONObject):string;static;
 class function Title(ARecord:TJSONObject):string;static;
 class function Identity(const ATarget:string):string;static;
end;
implementation
uses System.Hash;
class function TDPHActionPurpose.Identity(const ATarget:string):string;
begin Result:='ui:'+THashSHA2.GetHashString(LowerCase(ATarget));end;
class procedure TDPHActionPurpose.Validate(ARecord:TJSONObject);
var Fields:TJSONObject;Pair:TJSONPair;Key,ID:string;Known:Boolean;TaskID:TGUID;
begin
 if (ARecord=nil) or (ARecord.GetValue<string>('record_type','')<>'action_purpose') then raise EArgumentException.Create('Expected an action purpose record');
 if Length(ARecord.ToJSON)>65536 then raise EArgumentException.Create('Action purpose exceeds 64 KiB');
 for Pair in ARecord do if (Pair.JsonString.Value<>'record_type') and (Pair.JsonString.Value<>'fields') then raise EArgumentException.Create('Unknown action purpose metadata');
 if not ARecord.TryGetValue<TJSONObject>('fields',Fields) then raise EArgumentException.Create('Action purpose requires fields');
 for Pair in Fields do begin
  Known:=False;for Key in DPHActionPurposeKeys do if Pair.JsonString.Value=Key then Known:=True;
  if not Known then raise EArgumentException.Create('Unknown action purpose field');
  if not (Pair.JsonValue is TJSONString) then raise EArgumentException.Create('Action purpose values must be text');
  if Length(Pair.JsonValue.Value)>4096 then raise EArgumentException.Create('Action purpose field exceeds 4096 characters');
 end;
 ID:=Fields.GetValue<string>('action_id','');
 if ID.StartsWith('ui:') then begin
  if (Fields.GetValue<string>('target','').Trim='') or (ID<>Identity(Fields.GetValue<string>('target'))) then raise EArgumentException.Create('UI action identity must match its captured target');
 end else if ID.StartsWith('task:') then begin
  try TaskID:=StringToGUID(Copy(ID,6,MaxInt));except raise EArgumentException.Create('Invalid project task identity');end;
  if (Fields.GetValue<string>('target','')<>'Project task') or (Fields.GetValue<string>('target_key','')<>'') then raise EArgumentException.Create('Invalid project task target or object scope');
 end else raise EArgumentException.Create('Expected a stable captured UI or project task identity');
 for Key in ['action_name','purpose','steps','outcome','evidence'] do if Fields.GetValue<string>(Key,'').Trim='' then raise EArgumentException.Create('Enter '+Key+'; explicitly describe any remaining unknowns');
end;
class function TDPHActionPurpose.Title(ARecord:TJSONObject):string;
begin Validate(ARecord);Result:='Action purpose: '+ARecord.GetValue<string>('fields.action_id');end;
class function TDPHActionPurpose.Body(ARecord:TJSONObject):string;
var I:Integer;Text:string;Fields:TJSONObject;
begin
 Validate(ARecord);Fields:=ARecord.GetValue<TJSONObject>('fields');
 Result:='Action and business purpose'+sLineBreak+'Human-authored guidance. Saving does not verify business intent, permissions, runtime execution or successful outcomes. Read the named review state.'+sLineBreak;
 for I:=0 to High(DPHActionPurposeKeys) do begin
  Text:=Fields.GetValue<string>(DPHActionPurposeKeys[I],'').Trim;if Text='' then Text:='Not supplied; remains unknown.';
  Result:=Result+sLineBreak+DPHActionPurposeLabels[I]+':'+sLineBreak+Text+sLineBreak;
 end;
 Result:=TrimRight(Result);
end;
end.
