unit DPH.Workspace.Model;

interface
uses System.SysUtils, System.JSON, System.Generics.Collections,
  DPH.Project.Analysis, DPH.Analysis.Model;
const DPHBusinessProcessKeys:array[0..7] of string = ('name','owner','department','trigger','inputs','outputs','steps','unknowns');
const DPHWorkflowKeys:array[0..4] of string = ('name','owner','scope','trigger','unknowns');
 DPHWorkflowStepKeys:array[0..8] of string = ('step_id','department','role','action','inputs','outputs','handoff','exception_handling','exception_target');

const DPHBusinessRuleKeys:array[0..8] of string = ('rule_code','name','scope','conditions','outcomes','exceptions','owner','approval','unknowns');
const DPHCalculationKeys:array[0..11] of string = ('name','meaning','formula','inputs','outputs','units','rounding','assumptions','exceptions','examples','owner','unknowns');
const DPHLessonKeys:array[0..5] of string = ('name','purpose','prerequisites','expected_result','troubleshooting','practice');
type
  TDPHWorkspaceView = class
  private
    FDocument: TJSONObject;
    FSymbols: TDictionary<string,TJSONObject>;
  public
    constructor Create(ADocument: TJSONObject);
    destructor Destroy; override;
    class function Capture(AScan: TDPHScan; AGraph: TDPHSemanticGraph; AGeneration: Int64;
      const AEntry,AConfig,APlatform: string; const ADefines,AExternalRoots: TArray<string>): TJSONObject; static;
    function Symbol(const AKey: string): TJSONObject;
    function Neighbors(const AKey,ADirection: string): TJSONArray;
    function Search(const AQuery,AKind,AScope: string; AOffset: Integer = 0; ALimit: Integer = 250): TJSONArray;
    function Hierarchy(const AExpanded: TArray<string>; AOffset: Integer = 0; ALimit: Integer = 250): TJSONArray;
    function SourceFile(const APath: string): TJSONObject;
    function Properties(const AKey: string): TJSONArray;
    function Details(const AKey: string): TJSONArray;
    function Graph(const AKind,AKey: string; ALimit: Integer = 120): TJSONObject;
    function FlagsText: string;
    function Coverage: TJSONObject;
    function Questions(AKnowledge: TJSONArray = nil): TJSONArray;
    function ProjectMembers: TJSONArray;
    class function NewDataRetentionPolicy:string;static;
    class procedure ValidateDataRetentionRecord(ARecord:TJSONObject);static;
    class function IsDataRetentionPolicy(ARow:TJSONObject):Boolean;static;
    class function DescribeDataRetentionPolicy(ARow:TJSONObject):string;static;
    class function NewDepartmentalWorkflow:TJSONObject;static;
    class function NewWorkflowStep:TJSONObject;static;
    class procedure ValidateWorkflowStep(AStep:TJSONObject);static;
    class procedure ValidateDepartmentalWorkflow(ARecord:TJSONObject);static;
    class function DepartmentalWorkflowBody(ARecord:TJSONObject):string;static;
    class function IsDepartmentalWorkflow(ARow:TJSONObject):Boolean;static;
    class function DescribeDepartmentalWorkflow(ARow:TJSONObject):string;static;
    class function NewBusinessProcess:TJSONObject;static;
    class procedure ValidateBusinessProcess(ARecord:TJSONObject);static;
    class function BusinessProcessBody(ARecord:TJSONObject):string;static;
    class function IsBusinessProcess(ARow:TJSONObject):Boolean;static;
    class function DescribeBusinessProcess(ARow:TJSONObject):string;static;
    class function NewCalculation:TJSONObject;static;
    class function NewLearningLesson:TJSONObject;static;
    class function NewLearningCard:TJSONObject;static;
    class procedure ValidateLearningCard(ARecord:TJSONObject);static;
    class function LearningCardBody(ARecord:TJSONObject):string;static;
    class procedure ValidateLearningLesson(ARecord:TJSONObject);static;
    class function LearningLessonBody(ARecord:TJSONObject):string;static;
    class function IsLearningLesson(ARow:TJSONObject):Boolean;static;
    class procedure ValidateCalculation(ARecord:TJSONObject);static;
    class function CalculationBody(ARecord:TJSONObject):string;static;
    class function IsCalculation(ARow:TJSONObject):Boolean;static;
    class function DescribeCalculation(ARow:TJSONObject):string;static;
    function Calculations:TJSONObject;
    class function DescribeCalculationEvidence(ARow:TJSONObject):string;static;
    class function NewBusinessRule:TJSONObject;static;
    class procedure ValidateBusinessRule(ARecord:TJSONObject);static;
    class function BusinessRuleBody(ARecord:TJSONObject):string;static;
    class function IsBusinessRule(ARow:TJSONObject):Boolean;static;
    class function DescribeBusinessRule(ARow:TJSONObject):string;static;
    class function NewTargetRecoveryPlan:string;static;
    class procedure ValidateTargetRecoveryRecord(ARecord:TJSONObject);static;
    class function IsTargetRecoveryPlan(ARow:TJSONObject):Boolean;static;
    class function DescribeTargetRecoveryPlan(ARow:TJSONObject):string;static;
    class function NewDataQualityRule:string;static;
    class procedure ValidateDataQualityRecord(ARecord:TJSONObject);static;
    class function IsDataQualityRule(ARow:TJSONObject):Boolean;static;
    class function DescribeDataQualityRule(ARow:TJSONObject):string;static;
    function FileFormats: TJSONObject;
    class function DescribeFileFormat(ARow:TJSONObject):string; static;
    class function FileFormatContractTitle(ARow:TJSONObject):string; static;
    class function SelectionHash(const AConfig,APlatform: string; const ADefines,AExternalRoots: TArray<string>; ACodePage: Integer = 0): string; static;
    class function IsHandoffProject(ADocument: TJSONObject): Boolean; static;
    property Document: TJSONObject read FDocument;
  end;
implementation
uses System.RegularExpressions, System.StrUtils, System.IOUtils, System.Hash, System.DateUtils, System.Generics.Defaults, DPH.Project.Inventory, DPH.Analysis.Quality;

class function TDPHWorkspaceView.NewDataRetentionPolicy:string;
begin
 Result:='TARGET DATA RETENTION AND ARCHIVAL POLICY'+sLineBreak+
  'Human-authored requirements for the selected application. Replace Unknown with evidence or explain who must resolve it. Do not enter credentials or customer data.'+sLineBreak+sLineBreak+
  'Policy name and version: Unknown'+sLineBreak+
  'Data categories, tables/files and business scope: Unknown'+sLineBreak+
  'Business or regulatory basis and evidence: Unknown'+sLineBreak+
  'Retention period, units and clock-start event: Unknown'+sLineBreak+
  'Eligibility and expiry calculation, time zone: Unknown'+sLineBreak+
  'Archive trigger, frequency and implementing job/procedure: Unknown'+sLineBreak+
  'Archive destination, format and access permissions: Unknown'+sLineBreak+
  'Deletion/disposal method and implementing job/procedure: Unknown'+sLineBreak+
  'Legal holds, exceptions and override authority: Unknown'+sLineBreak+
  'Policy owner, operator and approval responsibility: Unknown'+sLineBreak+
  'Archive retrieval, restoration and disposal evidence: Unknown'+sLineBreak+
  'Failure handling, monitoring and audit trail: Unknown'+sLineBreak+
  'Verification procedure, test evidence and last review: Unknown'+sLineBreak+
  'Remaining unknowns and responsible maintainer: Unknown'+sLineBreak+sLineBreak+
  'Implementing links: use Knowledge links to attach captured routines, evidence or exact procedure-section revisions; Save the link edits. A written job name alone is not a resolved source link.'+sLineBreak+
  'Qualification: this records target-application policy. DPH snapshot retention is separate. DPH never runs an archive, deletion, SQL statement or target job. Saving or reviewing this record does not establish legal compliance or observed job success.';
end;
class function TDPHWorkspaceView.IsDataRetentionPolicy(ARow:TJSONObject):Boolean;
var RecordValue:TJSONValue;
begin
 Result:=False;if ARow=nil then Exit;
 RecordValue:=TJSONObject.ParseJSONValue(ARow.GetValue<string>('structured_json','{}'));
 try
  if not (RecordValue is TJSONObject) then Exit;
  Result:=(ARow.GetValue<string>('kind','')='business_rule') and (RecordValue.GetValue<string>('record_type','')='data_retention');
 finally RecordValue.Free;end;
end;
class procedure TDPHWorkspaceView.ValidateDataRetentionRecord(ARecord:TJSONObject);
var ID:TGUID;Pair:TJSONPair;
begin
 if (ARecord=nil) or (ARecord.GetValue<string>('record_type','')<>'data_retention') then raise EArgumentException.Create('Expected a target-data retention policy');
 if ARecord.Count<>2 then raise EArgumentException.Create('Retention policy requires only its record type and stable policy identity');
 for Pair in ARecord do if not (Pair.JsonValue is TJSONString) then raise EArgumentException.Create('Retention metadata must be text');
 if Length(ARecord.GetValue<string>('policy_id',''))<>38 then raise EArgumentException.Create('Invalid retention policy identity');
 try ID:=StringToGUID(ARecord.GetValue<string>('policy_id'));except raise EArgumentException.Create('Invalid retention policy identity');end;
end;
class function TDPHWorkspaceView.DescribeDataRetentionPolicy(ARow:TJSONObject):string;
var Links,History:TJSONArray;Value:TJSONValue;
begin
 Result:='No saved target-data policy selected. New policy prepares an unsaved Knowledge draft. Empty results do not prove that the application has no retention obligations.';
 if not IsDataRetentionPolicy(ARow) then Exit;
 Result:=ARow.GetValue<string>('title')+sLineBreak+'Original contributor: '+ARow.GetValue<string>('owner','unknown')+
  sLineBreak+'Review state: '+ARow.GetValue<string>('state','unknown')+' | revision '+ARow.GetValue<string>('revision','unknown')+
  sLineBreak+'Reviewer: '+IfThen(ARow.GetValue<string>('reviewer','')='','not supplied',ARow.GetValue<string>('reviewer',''))+sLineBreak;
 if ARow.TryGetValue<TJSONArray>('history',History) then for Value in History do
  if Value.GetValue<string>('revision','')=ARow.GetValue<string>('revision','') then
   Result:=Result+'Current revision author: '+Value.GetValue<string>('editor','unknown')+sLineBreak;
 if ARow.TryGetValue<TJSONArray>('rich_links',Links) then Result:=Result+'Explicit implementation/evidence links: '+IntToStr(Links.Count)+sLineBreak;
 Result:=Result+sLineBreak+ARow.GetValue<string>('body')+sLineBreak+sLineBreak+
  'Open policy to edit, save and review it. Implementation links opens the exact saved links and link editor. Unknown text remains unresolved even when a contributor has reviewed the record. Source links identify captured objects, not successful runtime jobs.';
end;

class function TDPHWorkspaceView.NewDepartmentalWorkflow:TJSONObject;
var Fields:TJSONObject;Key:string;
begin
 Result:=TJSONObject.Create.AddPair('record_type','departmental_workflow').AddPair('workflow_id',TGUID.NewGuid.ToString);
 Fields:=TJSONObject.Create;Result.AddPair('fields',Fields);Result.AddPair('steps',TJSONArray.Create);
 for Key in DPHWorkflowKeys do Fields.AddPair(Key,'Unknown');
end;
class function TDPHWorkspaceView.NewWorkflowStep:TJSONObject;
var Key:string;
begin
 Result:=TJSONObject.Create;
 for Key in DPHWorkflowStepKeys do if Key='step_id' then Result.AddPair(Key,TGUID.NewGuid.ToString) else Result.AddPair(Key,'Unknown');
end;
class procedure TDPHWorkspaceView.ValidateWorkflowStep(AStep:TJSONObject);
var Key:string;Pair:TJSONPair;ID:TGUID;
begin
 if (AStep=nil) or (AStep.Count<>Length(DPHWorkflowStepKeys)) then raise EArgumentException.Create('Step requires its nine structured fields');
 for Pair in AStep do if not (Pair.JsonValue is TJSONString) then raise EArgumentException.Create('Step fields must be text');
 for Key in DPHWorkflowStepKeys do if (AStep.GetValue<string>(Key,'').Trim='') or (Length(AStep.GetValue<string>(Key))>2048) then raise EArgumentException.Create('Complete '+Key+' or enter Unknown; maximum 2048 characters');
 try ID:=StringToGUID(AStep.GetValue<string>('step_id'));except raise EArgumentException.Create('Invalid step identity');end;
 if ID.ToString<>AStep.GetValue<string>('step_id') then raise EArgumentException.Create('Use canonical step identity');
 if SameText(AStep.GetValue<string>('action').Trim,'Unknown') then raise EArgumentException.Create('Enter a descriptive step action');
end;
class procedure TDPHWorkspaceView.ValidateDepartmentalWorkflow(ARecord:TJSONObject);
var Fields:TJSONObject;Steps:TJSONArray;V:TJSONValue;Pair:TJSONPair;Key,Target:string;ID:TGUID;IDs:TList<string>;
begin
 if (ARecord=nil) or (ARecord.Count<>4) or (ARecord.GetValue<string>('record_type','')<>'departmental_workflow') then raise EArgumentException.Create('Expected a structured departmental workflow');
 if Length(ARecord.ToJSON)>65536 then raise EArgumentException.Create('Workflow exceeds 64 KiB; split it into explicitly linked workflows');
 try ID:=StringToGUID(ARecord.GetValue<string>('workflow_id',''));except raise EArgumentException.Create('Invalid workflow identity');end;
 if ID.ToString<>ARecord.GetValue<string>('workflow_id') then raise EArgumentException.Create('Use canonical workflow identity');
 if not ARecord.TryGetValue<TJSONObject>('fields',Fields) or (Fields.Count<>Length(DPHWorkflowKeys)) then raise EArgumentException.Create('Workflow requires its five fields');
 for Pair in Fields do if not (Pair.JsonValue is TJSONString) then raise EArgumentException.Create('Workflow fields must be text');
 for Key in DPHWorkflowKeys do if (Fields.GetValue<string>(Key,'').Trim='') or (Length(Fields.GetValue<string>(Key))>4096) then raise EArgumentException.Create('Complete '+Key+' or enter Unknown; maximum 4096 characters');
 if SameText(Fields.GetValue<string>('name').Trim,'Unknown') or (Length(Fields.GetValue<string>('name'))>200) then raise EArgumentException.Create('Enter a descriptive workflow name of at most 200 characters');
 if not ARecord.TryGetValue<TJSONArray>('steps',Steps) or (Steps.Count<1) or (Steps.Count>64) then raise EArgumentException.Create('Workflow requires 1 through 64 ordered steps');
 IDs:=TList<string>.Create;
 try
  for V in Steps do begin
   if not (V is TJSONObject) then raise EArgumentException.Create('Step must be an object');
   ValidateWorkflowStep(V as TJSONObject);Key:=V.GetValue<string>('step_id');
   if IDs.Contains(Key) then raise EArgumentException.Create('Duplicate workflow step identity');IDs.Add(Key);
  end;
  for V in Steps do begin Target:=V.GetValue<string>('exception_target');
   if (Target<>'Unknown') and (Target<>'End') and not IDs.Contains(Target) then raise EArgumentException.Create('Exception destination is absent from this workflow');
  end;
 finally IDs.Free;end;
end;
class function TDPHWorkspaceView.DepartmentalWorkflowBody(ARecord:TJSONObject):string;
const Labels:array[0..4] of string=('Workflow name','Accountable workflow owner','Departments and business scope','Trigger and prerequisites','Unknowns and responsible maintainer');
 StepLabels:array[0..8] of string=('Stable step identity','Department','Responsible role','Step action','Inputs and origin','Outputs and recipient','Handoff to next department or role','Exception handling and recovery','Exception destination');
var I,J:Integer;Fields,Step:TJSONObject;Steps:TJSONArray;Target,V:string;
begin
 ValidateDepartmentalWorkflow(ARecord);Fields:=ARecord.GetValue<TJSONObject>('fields');Steps:=ARecord.GetValue<TJSONArray>('steps');
 Result:='DEPARTMENTAL WORKFLOW'+sLineBreak;
 for I:=0 to High(DPHWorkflowKeys) do Result:=Result+sLineBreak+Labels[I]+': '+Fields.GetValue<string>(DPHWorkflowKeys[I])+sLineBreak;
 Result:=Result+sLineBreak+'ORDERED STEPS AND DEPARTMENT HANDOFFS'+sLineBreak;
 for I:=0 to Steps.Count-1 do begin Step:=Steps.Items[I] as TJSONObject;
  Result:=Result+sLineBreak+'Step '+IntToStr(I+1)+': '+Step.GetValue<string>('action')+sLineBreak;
  for J:=1 to High(DPHWorkflowStepKeys)-1 do Result:=Result+StepLabels[J]+': '+Step.GetValue<string>(DPHWorkflowStepKeys[J])+sLineBreak;
  if I+1<Steps.Count then V:='Step '+IntToStr(I+2) else V:='End';Result:=Result+'Normal authored sequence: '+V+sLineBreak;
  Target:=Step.GetValue<string>('exception_target');V:=Target;
  for J:=0 to Steps.Count-1 do if Steps.Items[J].GetValue<string>('step_id')=Target then V:='Step '+IntToStr(J+1)+': '+Steps.Items[J].GetValue<string>('action');
  Result:=Result+'Exception destination: '+V+sLineBreak;
 end;
 Result:=Result+sLineBreak+'Attributed workflow; Unknown remains unresolved. Ordered steps and exception destinations are supplied by a contributor. DPH never executes this workflow. Content review is separate from business authorization or observed success. Use exact Knowledge links for business-process, source and procedure evidence.';
end;
class function TDPHWorkspaceView.IsDepartmentalWorkflow(ARow:TJSONObject):Boolean;
var V:TJSONValue;
begin
 Result:=False;if ARow=nil then Exit;V:=TJSONObject.ParseJSONValue(ARow.GetValue<string>('structured_json','{}'));
 try if V is TJSONObject then Result:=(ARow.GetValue<string>('kind','')='business_rule') and (V.GetValue<string>('record_type','')='departmental_workflow');finally V.Free;end;
end;
class function TDPHWorkspaceView.DescribeDepartmentalWorkflow(ARow:TJSONObject):string;
var History:TJSONArray;V:TJSONValue;
begin
 Result:='No saved workflow selected. New workflow opens structured fields and ordered steps. Empty results do not establish absent workflows.';
 if not IsDepartmentalWorkflow(ARow) then Exit;
 Result:=ARow.GetValue<string>('title')+sLineBreak+'Original contributor: '+ARow.GetValue<string>('owner')+sLineBreak+'Review state: '+ARow.GetValue<string>('state')+' | revision '+ARow.GetValue<string>('revision')+sLineBreak+'Reviewer: '+IfThen(ARow.GetValue<string>('reviewer','')='','not supplied',ARow.GetValue<string>('reviewer',''))+sLineBreak+'Explicit implementation/evidence links: '+IntToStr(ARow.GetValue<TJSONArray>('rich_links').Count)+sLineBreak;
 if ARow.TryGetValue<TJSONArray>('history',History) then for V in History do if V.GetValue<string>('revision')=ARow.GetValue<string>('revision') then Result:=Result+'Current revision author: '+V.GetValue<string>('editor')+sLineBreak;
 Result:=Result+sLineBreak+ARow.GetValue<string>('body');
end;

class function TDPHWorkspaceView.NewBusinessRule:TJSONObject;
var Fields:TJSONObject;Key:string;
begin
 Result:=TJSONObject.Create.AddPair('record_type','business_rule_definition').AddPair('rule_id',TGUID.NewGuid.ToString);
 Fields:=TJSONObject.Create;Result.AddPair('fields',Fields);
 for Key in DPHBusinessRuleKeys do Fields.AddPair(Key,'Unknown');
end;
class procedure TDPHWorkspaceView.ValidateBusinessRule(ARecord:TJSONObject);
var Fields:TJSONObject;Pair:TJSONPair;Key:string;ID:TGUID;
begin
 if (ARecord=nil) or (ARecord.Count<>3) or (ARecord.GetValue<string>('record_type','')<>'business_rule_definition') then raise EArgumentException.Create('Expected a structured business rule');
 if not (ARecord.GetValue('rule_id') is TJSONString) or (Length(ARecord.GetValue<string>('rule_id',''))<>38) then raise EArgumentException.Create('Invalid rule identity');
 try ID:=StringToGUID(ARecord.GetValue<string>('rule_id'));except raise EArgumentException.Create('Invalid rule identity');end;
 if ID.ToString<>ARecord.GetValue<string>('rule_id') then raise EArgumentException.Create('Rule identity must use its canonical GUID representation');
 if not ARecord.TryGetValue<TJSONObject>('fields',Fields) or (Fields.Count<>Length(DPHBusinessRuleKeys)) then raise EArgumentException.Create('Rule requires its nine structured fields');
 for Pair in Fields do if not (Pair.JsonValue is TJSONString) then raise EArgumentException.Create('Rule fields must be text');
 for Key in DPHBusinessRuleKeys do begin
  if Fields.GetValue<string>(Key,'').Trim='' then raise EArgumentException.Create('Complete '+Key+' or explicitly enter Unknown');
  if Length(Fields.GetValue<string>(Key))>4096 then raise EArgumentException.Create('Rule field exceeds 4096 characters: '+Key);
 end;
 if SameText(Fields.GetValue<string>('name').Trim,'Unknown') or (Length(Fields.GetValue<string>('name'))>200) then raise EArgumentException.Create('Enter a descriptive rule name of at most 200 characters');
 if not TRegEx.IsMatch(Fields.GetValue<string>('rule_code'),'^[A-Za-z0-9][A-Za-z0-9._/-]{0,99}\z') or SameText(Fields.GetValue<string>('rule_code'),'Unknown') then raise EArgumentException.Create('Enter a rule identifier: 1 to 100 ASCII letters, digits, dot, underscore, slash or hyphen; Unknown is unresolved');
end;
class function TDPHWorkspaceView.BusinessRuleBody(ARecord:TJSONObject):string;
const Labels:array[0..8] of string = ('Rule identifier (unique and stable)','Rule name (stable after saving)','Applicability and affected operations','Conditions and prerequisites','Expected outcomes and consequences','Business exceptions and recovery','Accountable business owner','Approval authority and change responsibilities','Unresolved questions and responsible maintainer');
var I:Integer;Fields:TJSONObject;
begin
 ValidateBusinessRule(ARecord);Fields:=ARecord.GetValue<TJSONObject>('fields');
 Result:='BUSINESS RULE'+sLineBreak;
 for I:=0 to High(DPHBusinessRuleKeys) do Result:=Result+sLineBreak+Labels[I]+': '+Fields.GetValue<string>(DPHBusinessRuleKeys[I])+sLineBreak;
 Result:=Result+sLineBreak+'Attributed business description; Unknown remains unresolved. Source links identify captured code, not observed execution. Business owner and approval authority are distinct from the contributor and DPH content reviewer. Saving and named review do not grant business authorization or prove outcomes.';
end;
class function TDPHWorkspaceView.IsBusinessRule(ARow:TJSONObject):Boolean;
var V:TJSONValue;
begin
 Result:=False;if ARow=nil then Exit;
 V:=TJSONObject.ParseJSONValue(ARow.GetValue<string>('structured_json','{}'));
 try if V is TJSONObject then Result:=(ARow.GetValue<string>('kind','')='business_rule') and ((V.GetValue<string>('record_type','')='business_rule_definition') or ((V as TJSONObject).Count=0));finally V.Free;end;
end;
class function TDPHWorkspaceView.DescribeBusinessRule(ARow:TJSONObject):string;
var History:TJSONArray;Value:TJSONValue;
begin
 Result:='No saved rule selected. New rule opens structured fields. Empty results do not prove the application has no business rules.';
 if not IsBusinessRule(ARow) then Exit;
 if ARow.GetValue<string>('structured_json','{}')='{}' then begin Result:='Unstructured business-rule note. Rule identifier, applicability, conditions, outcomes and accountable owner have not been separately captured. Open record to inspect original text or New rule to create a separately attributed structured record. Preserve the original and link it as exact evidence.'+sLineBreak+ARow.GetValue<string>('title')+sLineBreak+'Contributor: '+ARow.GetValue<string>('owner')+' | review state: '+ARow.GetValue<string>('state')+sLineBreak+ARow.GetValue<string>('body');Exit;end;
 Result:=ARow.GetValue<string>('title')+sLineBreak+'Original contributor: '+ARow.GetValue<string>('owner','unknown')+sLineBreak+
 'Review state: '+ARow.GetValue<string>('state')+' | revision '+ARow.GetValue<string>('revision')+sLineBreak+
 'Reviewer: '+IfThen(ARow.GetValue<string>('reviewer','')='','not supplied',ARow.GetValue<string>('reviewer',''))+sLineBreak+
 'Explicit implementation/evidence links: '+IntToStr(ARow.GetValue<TJSONArray>('rich_links').Count)+sLineBreak+ARow.GetValue<string>('body');
 if ARow.TryGetValue<TJSONArray>('history',History) then for Value in History do if Value.GetValue<string>('revision','')=ARow.GetValue<string>('revision','') then Result:=Result+sLineBreak+'Current revision author: '+Value.GetValue<string>('editor','unknown');
end;

class function TDPHWorkspaceView.NewLearningCard:TJSONObject;
var Fields:TJSONObject;Key:string;
begin
 Result:=TJSONObject.Create.AddPair('record_type','learning_card').AddPair('card_id',TGUID.NewGuid.ToString).AddPair('category','Screen');
 Fields:=TJSONObject.Create;Result.AddPair('fields',Fields);
 for Key in ['name','role','meaning','example','limits','help','practice'] do Fields.AddPair(Key,'Unknown');
 Fields.RemovePair('role').Free;Fields.AddPair('role','All learners');
end;
class procedure TDPHWorkspaceView.ValidateLearningCard(ARecord:TJSONObject);
var Fields,Picture:TJSONObject;Key:string;Pair:TJSONPair;ID:TGUID;Coordinate:Integer;C:Char;
begin
 if (ARecord=nil) or not (ARecord.Count in [4,5]) or (ARecord.GetValue<string>('record_type','')<>'learning_card') then raise EArgumentException.Create('Expected a teaching card');
 if ARecord.Count=5 then begin
  if not ARecord.TryGetValue<TJSONObject>('picture',Picture) or (Picture.Count<>3) then raise EArgumentException.Create('Picture callout needs its image and two coordinates');
  Key:=Picture.GetValue<string>('image_sha256','');if Length(Key)<>64 then raise EArgumentException.Create('Invalid callout image identity');
  for C in Key do if not CharInSet(C,['0'..'9','a'..'f']) then raise EArgumentException.Create('Invalid callout image identity');
  for Key in ['x','y'] do begin
   if not (Picture.GetValue(Key) is TJSONNumber) then raise EArgumentException.Create('Callout coordinates must be whole numbers');
   Coordinate:=Picture.GetValue<Integer>(Key);if (Coordinate<0) or (Coordinate>10000) or (Picture.GetValue(Key).Value<>IntToStr(Coordinate)) then raise EArgumentException.Create('Callout coordinates must be within the picture');
  end;
 end;
 if not (ARecord.GetValue('card_id') is TJSONString) then raise EArgumentException.Create('Teaching card identity must be text');
 try ID:=StringToGUID(ARecord.GetValue<string>('card_id'));except raise EArgumentException.Create('Invalid teaching card identity');end;
 if ID.ToString<>ARecord.GetValue<string>('card_id') then raise EArgumentException.Create('Invalid canonical teaching card identity');
 if not MatchText(ARecord.GetValue<string>('category',''),['Screen','Field','Error or problem','Question and answer','Business rule','Output or report','Role or permission','Related system','Setting or option','Background work','History or design choice','Learning check']) then raise EArgumentException.Create('Choose a teaching card topic');
 if not ARecord.TryGetValue<TJSONObject>('fields',Fields) or (Fields.Count<>7) then raise EArgumentException.Create('Complete the seven teaching fields');
 for Pair in Fields do if not (Pair.JsonValue is TJSONString) then raise EArgumentException.Create('Teaching fields must be text');
 for Key in ['name','role','meaning','example','limits','help','practice'] do
  if (Fields.GetValue<string>(Key,'').Trim='') or (Length(Fields.GetValue<string>(Key))>4096) then raise EArgumentException.Create('Complete '+Key+' within 4096 characters, or explicitly enter Unknown');
 for Key in ['name','meaning'] do if SameText(Fields.GetValue<string>(Key).Trim,'Unknown') then raise EArgumentException.Create('Supply '+Key+' for the learner');
 if Length(Fields.GetValue<string>('name'))>200 then raise EArgumentException.Create('Teaching card name must fit within 200 characters');
 if Length(ARecord.ToJSON)>65536 then raise EArgumentException.Create('Teaching card exceeds 64 KiB');
end;
class function TDPHWorkspaceView.LearningCardBody(ARecord:TJSONObject):string;
const Keys:array[0..6] of string=('name','role','meaning','example','limits','help','practice');
 Labels:array[0..6] of string=('Topic','Who this helps','What this means and why it matters','Worked example or good input','Rules, limits and mistakes to avoid','If the result differs: safe next step and who can help','Practice and expected answer');
var I:Integer;Fields:TJSONObject;
begin
 ValidateLearningCard(ARecord);Fields:=ARecord.GetValue<TJSONObject>('fields');Result:='LEARNING CARD: '+ARecord.GetValue<string>('category')+sLineBreak;
 for I:=0 to High(Keys) do Result:=Result+sLineBreak+Labels[I]+sLineBreak+Fields.GetValue<string>(Keys[I])+sLineBreak;
 if ARecord.GetValue('picture')<>nil then Result:=Result+sLineBreak+'Picture callout: this explanation belongs to the marked point on a supplied image. The image and the explanation are separate contributions.';
end;
class function TDPHWorkspaceView.NewLearningLesson:TJSONObject;
var Fields:TJSONObject;Key:string;
begin
 Result:=TJSONObject.Create.AddPair('record_type','learning_lesson').AddPair('lesson_id',TGUID.NewGuid.ToString);
 Fields:=TJSONObject.Create;Result.AddPair('fields',Fields);Result.AddPair('steps',TJSONArray.Create);
 for Key in DPHLessonKeys do Fields.AddPair(Key,'Unknown');
end;
class procedure TDPHWorkspaceView.ValidateLearningLesson(ARecord:TJSONObject);
var Fields,Step,Learning:TJSONObject;Steps:TJSONArray;Pair:TJSONPair;V:TJSONValue;Key:string;ID:TGUID;
begin
 if (ARecord=nil) or not (ARecord.Count in [4,5]) or (ARecord.GetValue<string>('record_type','')<>'learning_lesson') then raise EArgumentException.Create('Expected task instructions');
 if ARecord.Count=5 then begin
  if not ARecord.TryGetValue<TJSONObject>('learning',Learning) or (Learning.Count<>3) then raise EArgumentException.Create('Expected role, learning path and lesson order');
  for Key in ['role','path'] do
   if not (Learning.GetValue(Key) is TJSONString) or (Length(Learning.GetValue<string>(Key))>200) then raise EArgumentException.Create('Enter role and path text within 200 characters');
  if not (Learning.GetValue('order') is TJSONNumber) or (Learning.GetValue<Integer>('order')<1) or
    (Learning.GetValue<Integer>('order')>10000) or (Learning.GetValue('order').Value<>IntToStr(Learning.GetValue<Integer>('order'))) then
    raise EArgumentException.Create('Lesson order must be a whole number from 1 to 10000');
 end;
 if not (ARecord.GetValue('lesson_id') is TJSONString) then raise EArgumentException.Create('Task identity must be text');
 try ID:=StringToGUID(ARecord.GetValue<string>('lesson_id'));except raise EArgumentException.Create('Invalid task identity');end;
 if ID.ToString<>ARecord.GetValue<string>('lesson_id') then raise EArgumentException.Create('Invalid canonical task identity');
 if not ARecord.TryGetValue<TJSONObject>('fields',Fields) or (Fields.Count<>Length(DPHLessonKeys)) then raise EArgumentException.Create('Complete the six task fields');
 for Pair in Fields do if not (Pair.JsonValue is TJSONString) then raise EArgumentException.Create('Task fields must be text');
 for Key in DPHLessonKeys do begin
  if Fields.GetValue<string>(Key,'').Trim='' then raise EArgumentException.Create('Complete '+Key+' or explicitly enter Unknown');
  if Length(Fields.GetValue<string>(Key))>4096 then raise EArgumentException.Create('Task field exceeds 4096 characters: '+Key);
 end;
 if SameText(Fields.GetValue<string>('name').Trim,'Unknown') or (Length(Fields.GetValue<string>('name'))>200) then raise EArgumentException.Create('Enter a descriptive task name of at most 200 characters');
 if SameText(Fields.GetValue<string>('purpose').Trim,'Unknown') then raise EArgumentException.Create('Explain what this task helps the learner accomplish');
 if not ARecord.TryGetValue<TJSONArray>('steps',Steps) or (Steps.Count=0) or (Steps.Count>100) then raise EArgumentException.Create('Supply between one and 100 task steps');
 for V in Steps do begin
  if not (V is TJSONObject) then raise EArgumentException.Create('Each step needs an action and expected result');
  Step:=V as TJSONObject;
  if (Step.Count<>2) or not (Step.GetValue('action') is TJSONString) or not (Step.GetValue('expected_result') is TJSONString) then raise EArgumentException.Create('Each step needs only action and expected result text');
  for Key in ['action','expected_result'] do if (Step.GetValue<string>(Key).Trim='') or (Length(Step.GetValue<string>(Key))>4096) then raise EArgumentException.Create('Complete the step '+Key+' within 4096 characters');
  if SameText(Step.GetValue<string>('action').Trim,'Unknown') then raise EArgumentException.Create('Explain the action for each step');
 end;
 if Length(ARecord.ToJSON)>65536 then raise EArgumentException.Create('Task instructions exceed 64 KiB');
end;
class function TDPHWorkspaceView.LearningLessonBody(ARecord:TJSONObject):string;
const Labels:array[0..5] of string = ('Task','Purpose','Before you begin','Expected final result','If something goes wrong','Practice and check your understanding');
var Fields,Learning:TJSONObject;I:Integer;V:TJSONValue;
begin
 ValidateLearningLesson(ARecord);Fields:=ARecord.GetValue<TJSONObject>('fields');Result:='TASK WALKTHROUGH'+sLineBreak;
 if ARecord.TryGetValue<TJSONObject>('learning',Learning) then Result:=Result+sLineBreak+'User role: '+Learning.GetValue<string>('role')+
  sLineBreak+'Learning path: '+Learning.GetValue<string>('path')+sLineBreak+'Lesson order: '+Learning.GetValue('order').Value+sLineBreak;
 for I:=0 to High(DPHLessonKeys) do Result:=Result+sLineBreak+Labels[I]+': '+Fields.GetValue<string>(DPHLessonKeys[I])+sLineBreak;
 I:=0;for V in ARecord.GetValue<TJSONArray>('steps') do begin Inc(I);
  Result:=Result+sLineBreak+IntToStr(I)+'. '+V.GetValue<string>('action')+sLineBreak+'Expected after this step: '+V.GetValue<string>('expected_result')+sLineBreak;
 end;
 Result:=Result+sLineBreak+'Instructions supplied by a contributor; review status is recorded separately. DPH presents these steps without executing the selected application. Unknown results need an answer from the author.';
end;
class function TDPHWorkspaceView.IsLearningLesson(ARow:TJSONObject):Boolean;
var V:TJSONValue;
begin
 Result:=False;if ARow=nil then Exit;
 V:=TJSONObject.ParseJSONValue(ARow.GetValue<string>('structured_json','{}'));
 try if V is TJSONObject then Result:=(ARow.GetValue<string>('kind','')='user_help') and (V.GetValue<string>('record_type','')='learning_lesson');finally V.Free;end;
end;
class function TDPHWorkspaceView.NewCalculation:TJSONObject;
var Fields:TJSONObject;Key:string;
begin
 Result:=TJSONObject.Create.AddPair('record_type','calculation_definition').AddPair('calculation_id',TGUID.NewGuid.ToString);
 Fields:=TJSONObject.Create;Result.AddPair('fields',Fields);
 for Key in DPHCalculationKeys do Fields.AddPair(Key,'Unknown');
end;
class procedure TDPHWorkspaceView.ValidateCalculation(ARecord:TJSONObject);
var Fields:TJSONObject;Pair:TJSONPair;Key:string;ID:TGUID;
begin
 if (ARecord=nil) or (ARecord.Count<>3) or (ARecord.GetValue<string>('record_type','')<>'calculation_definition') then raise EArgumentException.Create('Expected a structured business calculation');
 if not (ARecord.GetValue('calculation_id') is TJSONString) or (Length(ARecord.GetValue<string>('calculation_id',''))<>38) then raise EArgumentException.Create('Invalid calculation identity');
 try ID:=StringToGUID(ARecord.GetValue<string>('calculation_id'));except raise EArgumentException.Create('Invalid calculation identity');end;
 if ID.ToString<>ARecord.GetValue<string>('calculation_id') then raise EArgumentException.Create('Calculation identity must use its canonical GUID representation');
 if not ARecord.TryGetValue<TJSONObject>('fields',Fields) or (Fields.Count<>Length(DPHCalculationKeys)) then raise EArgumentException.Create('Calculation requires its twelve structured fields');
 for Pair in Fields do if not (Pair.JsonValue is TJSONString) then raise EArgumentException.Create('Calculation fields must be text');
 for Key in DPHCalculationKeys do begin
  if Fields.GetValue<string>(Key,'').Trim='' then raise EArgumentException.Create('Complete '+Key+' or explicitly enter Unknown');
  if Length(Fields.GetValue<string>(Key))>4096 then raise EArgumentException.Create('Calculation field exceeds 4096 characters: '+Key);
 end;
 if SameText(Fields.GetValue<string>('name').Trim,'Unknown') or (Length(Fields.GetValue<string>('name'))>200) then raise EArgumentException.Create('Enter a descriptive calculation name of at most 200 characters');
end;
class function TDPHWorkspaceView.CalculationBody(ARecord:TJSONObject):string;
const Labels:array[0..11] of string = ('Calculation name','Business meaning and applicability','Formula or algorithm (not evaluated)','Inputs definitions and origins','Outputs definitions and recipients','Units and conversions','Precision and rounding','Assumptions and valid ranges','Exceptions and boundary conditions','Worked examples and expected results (authored)','Accountable calculation owner','Unknowns and responsible maintainer');
var I:Integer;Fields:TJSONObject;
begin
 ValidateCalculation(ARecord);Fields:=ARecord.GetValue<TJSONObject>('fields');
 Result:='CALCULATION DEFINITION'+sLineBreak;
 for I:=0 to High(DPHCalculationKeys) do Result:=Result+sLineBreak+Labels[I]+': '+Fields.GetValue<string>(DPHCalculationKeys[I])+sLineBreak;
 Result:=Result+sLineBreak+'Attributed business description; Unknown remains unresolved. Source links identify captured code, not observed execution. Formula text and worked examples are authored evidence, never evaluated by DPH. Units, precision and business meanings require named review; no target execution or numerical correctness is proved.';
end;
class function TDPHWorkspaceView.IsCalculation(ARow:TJSONObject):Boolean;
var V:TJSONValue;
begin
 Result:=False;if ARow=nil then Exit;
 V:=TJSONObject.ParseJSONValue(ARow.GetValue<string>('structured_json','{}'));
 try if V is TJSONObject then Result:=(ARow.GetValue<string>('kind','')='business_rule') and (V.GetValue<string>('record_type','')='calculation_definition');finally V.Free;end;
end;
class function TDPHWorkspaceView.DescribeCalculation(ARow:TJSONObject):string;
var History:TJSONArray;Value:TJSONValue;
begin
 Result:='No saved calculation selected. New calculation opens structured fields. Empty results do not prove the application has no calculations.';
 if not IsCalculation(ARow) then Exit;
 Result:=ARow.GetValue<string>('title')+sLineBreak+'Original contributor: '+ARow.GetValue<string>('owner','unknown')+sLineBreak+
 'Review state: '+ARow.GetValue<string>('state')+' | revision '+ARow.GetValue<string>('revision')+sLineBreak+
 'Reviewer: '+IfThen(ARow.GetValue<string>('reviewer','')='','not supplied',ARow.GetValue<string>('reviewer',''))+sLineBreak+
 'Explicit implementation/evidence links: '+IntToStr(ARow.GetValue<TJSONArray>('rich_links').Count)+sLineBreak+ARow.GetValue<string>('body');
 if ARow.TryGetValue<TJSONArray>('history',History) then for Value in History do if Value.GetValue<string>('revision','')=ARow.GetValue<string>('revision','') then Result:=Result+sLineBreak+'Current revision author: '+Value.GetValue<string>('editor','unknown');
end;

class function TDPHWorkspaceView.NewBusinessProcess:TJSONObject;
var Fields:TJSONObject;Key:string;
begin
 Result:=TJSONObject.Create.AddPair('record_type','business_process').AddPair('process_id',TGUID.NewGuid.ToString);
 Fields:=TJSONObject.Create;Result.AddPair('fields',Fields);
 for Key in DPHBusinessProcessKeys do Fields.AddPair(Key,'Unknown');
end;
class procedure TDPHWorkspaceView.ValidateBusinessProcess(ARecord:TJSONObject);
var Fields:TJSONObject;Pair:TJSONPair;Key:string;ID:TGUID;
begin
 if (ARecord=nil) or (ARecord.Count<>3) or (ARecord.GetValue<string>('record_type','')<>'business_process') then raise EArgumentException.Create('Expected a structured business process');
 if not (ARecord.GetValue('process_id') is TJSONString) or (Length(ARecord.GetValue<string>('process_id',''))<>38) then raise EArgumentException.Create('Invalid process identity');
 try ID:=StringToGUID(ARecord.GetValue<string>('process_id'));except raise EArgumentException.Create('Invalid process identity');end;
 if ID.ToString<>ARecord.GetValue<string>('process_id') then raise EArgumentException.Create('Process identity must use its canonical GUID representation');
 if not ARecord.TryGetValue<TJSONObject>('fields',Fields) or (Fields.Count<>Length(DPHBusinessProcessKeys)) then raise EArgumentException.Create('Process requires its eight structured fields');
 for Pair in Fields do if not (Pair.JsonValue is TJSONString) then raise EArgumentException.Create('Process fields must be text');
 for Key in DPHBusinessProcessKeys do begin
  if Fields.GetValue<string>(Key,'').Trim='' then raise EArgumentException.Create('Complete '+Key+' or explicitly enter Unknown');
  if Length(Fields.GetValue<string>(Key))>4096 then raise EArgumentException.Create('Process field exceeds 4096 characters: '+Key);
 end;
 if SameText(Fields.GetValue<string>('name').Trim,'Unknown') or (Length(Fields.GetValue<string>('name'))>200) then raise EArgumentException.Create('Enter a descriptive process name of at most 200 characters');
end;
class function TDPHWorkspaceView.BusinessProcessBody(ARecord:TJSONObject):string;
const Labels:array[0..7] of string = ('Process name','Accountable business owner','Department and participating roles','Trigger and prerequisites','Inputs and their origin','Outputs and their recipients','Ordered steps and handoffs','Unknowns and responsible maintainer');
var I:Integer;Fields:TJSONObject;
begin
 ValidateBusinessProcess(ARecord);Fields:=ARecord.GetValue<TJSONObject>('fields');
 Result:='BUSINESS PROCESS'+sLineBreak;
 for I:=0 to High(DPHBusinessProcessKeys) do Result:=Result+sLineBreak+Labels[I]+': '+Fields.GetValue<string>(DPHBusinessProcessKeys[I])+sLineBreak;
 Result:=Result+sLineBreak+'Attributed business description; Unknown remains unresolved. Source links identify captured code, not observed execution. Saving and named review do not prove operational outcomes.';
end;
class function TDPHWorkspaceView.IsBusinessProcess(ARow:TJSONObject):Boolean;
var V:TJSONValue;
begin
 Result:=False;if ARow=nil then Exit;
 V:=TJSONObject.ParseJSONValue(ARow.GetValue<string>('structured_json','{}'));
 try if V is TJSONObject then Result:=(ARow.GetValue<string>('kind','')='business_rule') and (V.GetValue<string>('record_type','')='business_process');finally V.Free;end;
end;
class function TDPHWorkspaceView.DescribeBusinessProcess(ARow:TJSONObject):string;
var History:TJSONArray;Value:TJSONValue;
begin
 Result:='No saved process selected. New process opens structured fields. Empty results do not prove the application has no business processes.';
 if not IsBusinessProcess(ARow) then Exit;
 Result:=ARow.GetValue<string>('title')+sLineBreak+'Original contributor: '+ARow.GetValue<string>('owner','unknown')+sLineBreak+
 'Review state: '+ARow.GetValue<string>('state')+' | revision '+ARow.GetValue<string>('revision')+sLineBreak+
 'Reviewer: '+IfThen(ARow.GetValue<string>('reviewer','')='','not supplied',ARow.GetValue<string>('reviewer',''))+sLineBreak+
 'Explicit implementation/evidence links: '+IntToStr(ARow.GetValue<TJSONArray>('rich_links').Count)+sLineBreak+ARow.GetValue<string>('body');
 if ARow.TryGetValue<TJSONArray>('history',History) then for Value in History do if Value.GetValue<string>('revision','')=ARow.GetValue<string>('revision','') then Result:=Result+sLineBreak+'Current revision author: '+Value.GetValue<string>('editor','unknown');
end;

class function TDPHWorkspaceView.NewTargetRecoveryPlan:string;
begin
 Result:='TARGET BACKUP AND RESTORATION REQUIREMENTS'+sLineBreak+
  'Attributed requirements for the selected application. Unknown remains unresolved. Do not enter credentials or customer data.'+sLineBreak+sLineBreak+
  'Plan name and version: Unknown'+sLineBreak+
  'Data categories, tables/files and business scope: Unknown'+sLineBreak+
  'Recovery point objective (RPO), units and maximum acceptable data loss: Unknown'+sLineBreak+
  'Recovery time objective (RTO), units and restoration priority: Unknown'+sLineBreak+
  'Backup type, frequency, consistency and implementing job/procedure: Unknown'+sLineBreak+
  'Backup destination, format, retention and offsite copies: Unknown'+sLineBreak+
  'Encryption, access permissions and key recovery responsibility: Unknown'+sLineBreak+
  'Restore prerequisites, compatible versions and dependency order: Unknown'+sLineBreak+
  'Restoration steps, implementing routines and rollback/abort criteria: Unknown'+sLineBreak+
  'Plan owner, backup operator, restore operator and approval responsibility: Unknown'+sLineBreak+
  'Recovery test date, environment, operator and backup identity/hash: Unknown'+sLineBreak+
  'Observed recovery time, recovered point and acceptance checks: Unknown'+sLineBreak+
  'Test result, failures, corrective action, reviewer and evidence: Unknown'+sLineBreak+
  'Failure handling, monitoring and audit trail: Unknown'+sLineBreak+
  'Remaining unknowns and responsible maintainer: Unknown'+sLineBreak+
  sLineBreak+'Use Knowledge links to cite captured backup/restore routines and exact operating procedure or recovery-test evidence revisions. A written routine name alone is not a resolved link.'+sLineBreak+
  'Qualification: DPH portable database backup is separate. DPH never runs a target backup, restoration, SQL statement or job. Recovery test measurements are contributor claims; named review does not establish successful recovery.';
end;
class function TDPHWorkspaceView.IsTargetRecoveryPlan(ARow:TJSONObject):Boolean;
var RecordValue:TJSONValue;
begin
 Result:=False;if ARow=nil then Exit;
 RecordValue:=TJSONObject.ParseJSONValue(ARow.GetValue<string>('structured_json','{}'));
 try
  if not (RecordValue is TJSONObject) then Exit;
  Result:=(ARow.GetValue<string>('kind','')='business_rule') and (RecordValue.GetValue<string>('record_type','')='target_recovery');
 finally RecordValue.Free;end;
end;
class procedure TDPHWorkspaceView.ValidateTargetRecoveryRecord(ARecord:TJSONObject);
var ID:TGUID;Pair:TJSONPair;
begin
 if (ARecord=nil) or (ARecord.GetValue<string>('record_type','')<>'target_recovery') then raise EArgumentException.Create('Expected a target backup and restoration policy');
 if ARecord.Count<>2 then raise EArgumentException.Create('Recovery plan requires only its record type and stable plan identity');
 for Pair in ARecord do if not (Pair.JsonValue is TJSONString) then raise EArgumentException.Create('Recovery metadata must be text');
 if Length(ARecord.GetValue<string>('plan_id',''))<>38 then raise EArgumentException.Create('Invalid recovery plan identity');
 try ID:=StringToGUID(ARecord.GetValue<string>('plan_id'));except raise EArgumentException.Create('Invalid recovery plan identity');end;
end;
class function TDPHWorkspaceView.DescribeTargetRecoveryPlan(ARow:TJSONObject):string;
var Links,History:TJSONArray;Value:TJSONValue;
begin
 Result:='No saved target recovery plan selected. New plan prepares an unsaved Knowledge draft. Empty results do not prove that the application has no recovery requirements.';
 if not IsTargetRecoveryPlan(ARow) then Exit;
 Result:=ARow.GetValue<string>('title')+sLineBreak+'Original contributor: '+ARow.GetValue<string>('owner','unknown')+
  sLineBreak+'Review state: '+ARow.GetValue<string>('state','unknown')+' | revision '+ARow.GetValue<string>('revision','unknown')+
  sLineBreak+'Reviewer: '+IfThen(ARow.GetValue<string>('reviewer','')='','not supplied',ARow.GetValue<string>('reviewer',''))+sLineBreak;
 if ARow.TryGetValue<TJSONArray>('history',History) then for Value in History do
  if Value.GetValue<string>('revision','')=ARow.GetValue<string>('revision','') then
   Result:=Result+'Current revision author: '+Value.GetValue<string>('editor','unknown')+sLineBreak;
 if ARow.TryGetValue<TJSONArray>('rich_links',Links) then Result:=Result+'Explicit implementation/evidence links: '+IntToStr(Links.Count)+sLineBreak;
 Result:=Result+sLineBreak+ARow.GetValue<string>('body')+sLineBreak+sLineBreak+
  'Open plan to edit, save and review it. Implementation links opens the exact saved links and link editor. Unknown text remains unresolved even when a contributor has reviewed the record. Source links identify captured objects, not successful runtime jobs.';
end;

class function TDPHWorkspaceView.NewDataQualityRule:string;
begin
 Result:='TARGET DATA QUALITY AND INTEGRITY CHECK'+sLineBreak+
  'Selected-application data requirements and attributed results. Unknown means unresolved. Do not enter credentials or customer records.'+sLineBreak+sLineBreak+
  'Check name, version and purpose: Unknown'+sLineBreak+
  'Data scope, tables/fields/files and environment: Unknown'+sLineBreak+
  'Quality dimension (completeness, uniqueness, validity, consistency, freshness or referential integrity): Unknown'+sLineBreak+
  'Rule, threshold, units and expected outcome: Unknown'+sLineBreak+
  'Prerequisites, sampling, exclusions and limitations: Unknown'+sLineBreak+
  'Check procedure, implementing routine and schedule: Unknown'+sLineBreak+
  'Owner, operator and review responsibility: Unknown'+sLineBreak+
  'Failure severity, remediation and escalation: Unknown'+sLineBreak+
  'Observed result, counts, measurement time and environment: Unknown'+sLineBreak+
  'Result evidence, contributor and verification method: Unknown'+sLineBreak+
  'Remaining unknowns and responsible maintainer: Unknown'+sLineBreak+sLineBreak+
  'Use Knowledge links to cite captured routines, constraints and exact procedure or imported report revisions. Import check report saves an attributed UTF-8 text extract as another quality record; link it as a section. A written name alone is not a resolved link.'+sLineBreak+
  'Qualification: DPH never runs checks, SQL or the selected application. Source constraints are captured declarations, not proof of live data quality. Imported outcomes and timestamps remain contributor claims. DPH database integrity is separate.';
end;
class function TDPHWorkspaceView.IsDataQualityRule(ARow:TJSONObject):Boolean;
var RecordValue:TJSONValue;
begin
 Result:=False;if ARow=nil then Exit;
 RecordValue:=TJSONObject.ParseJSONValue(ARow.GetValue<string>('structured_json','{}'));
 try
  if not (RecordValue is TJSONObject) then Exit;
  Result:=(ARow.GetValue<string>('kind','')='business_rule') and (RecordValue.GetValue<string>('record_type','')='data_quality');
 finally RecordValue.Free;end;
end;
class procedure TDPHWorkspaceView.ValidateDataQualityRecord(ARecord:TJSONObject);
var ID:TGUID;Pair:TJSONPair;
begin
 if (ARecord=nil) or (ARecord.GetValue<string>('record_type','')<>'data_quality') then raise EArgumentException.Create('Expected a target-data quality rule');
 if ARecord.Count<>2 then raise EArgumentException.Create('Quality check requires only its record type and stable check identity');
 for Pair in ARecord do if not (Pair.JsonValue is TJSONString) then raise EArgumentException.Create('Quality metadata must be text');
 if Length(ARecord.GetValue<string>('rule_id',''))<>38 then raise EArgumentException.Create('Invalid data quality rule identity');
 try ID:=StringToGUID(ARecord.GetValue<string>('rule_id'));except raise EArgumentException.Create('Invalid data quality rule identity');end;
end;
class function TDPHWorkspaceView.DescribeDataQualityRule(ARow:TJSONObject):string;
var Links,History:TJSONArray;Value:TJSONValue;
begin
 Result:='No saved target-data quality check selected. New check prepares an unsaved Knowledge draft. Empty results do not prove that the application has no data quality checks.';
 if not IsDataQualityRule(ARow) then Exit;
 Result:=ARow.GetValue<string>('title')+sLineBreak+'Original contributor: '+ARow.GetValue<string>('owner','unknown')+
  sLineBreak+'Review state: '+ARow.GetValue<string>('state','unknown')+' | revision '+ARow.GetValue<string>('revision','unknown')+
  sLineBreak+'Reviewer: '+IfThen(ARow.GetValue<string>('reviewer','')='','not supplied',ARow.GetValue<string>('reviewer',''))+sLineBreak;
 if ARow.TryGetValue<TJSONArray>('history',History) then for Value in History do
  if Value.GetValue<string>('revision','')=ARow.GetValue<string>('revision','') then
   Result:=Result+'Current revision author: '+Value.GetValue<string>('editor','unknown')+sLineBreak;
 if ARow.TryGetValue<TJSONArray>('rich_links',Links) then Result:=Result+'Explicit implementation/evidence links: '+IntToStr(Links.Count)+sLineBreak;
 Result:=Result+sLineBreak+ARow.GetValue<string>('body')+sLineBreak+sLineBreak+
  'Open check to edit, save and review it. Implementation links opens the exact saved links and link editor. Unknown text remains unresolved even when a contributor has reviewed the record. Source links identify captured objects, not successful runtime jobs.';
end;

class function TDPHWorkspaceView.IsHandoffProject(ADocument: TJSONObject): Boolean;
var Files,Nodes: TJSONArray; FileValue,NodeValue: TJSONValue; Row,IR,Node: TJSONObject;
begin
  Result:=False;
  if (ADocument=nil) or not ADocument.TryGetValue<TJSONArray>('syntax.files',Files) then Exit;
  for FileValue in Files do
  begin
    Row:=FileValue as TJSONObject;
    if not Row.TryGetValue<TJSONObject>('ir',IR) or not IR.TryGetValue<TJSONArray>('nodes',Nodes) then Continue;
    for NodeValue in Nodes do
    begin
      Node:=NodeValue as TJSONObject;
      if (SameText(Node.GetValue<string>('kind',''),'project_property') and
        SameText(Node.GetValue<string>('name',''),'ProjectGuid') and
        SameText(Trim(Node.GetValue<string>('value','')),DPHHandoffProjectGUID)) or
        (SameText(Node.GetValue<string>('kind',''),'program') and
        SameText(Node.GetValue<string>('name',''),DPHHandoffProgramName)) then Exit(True);
    end;
  end;
end;

class function TDPHWorkspaceView.SelectionHash(const AConfig,APlatform: string; const ADefines,AExternalRoots: TArray<string>; ACodePage: Integer): string;
var Selection: string;
begin
  Selection:=AConfig+#0+APlatform+#0+String.Join(#0,ADefines)+#1+String.Join(#0,AExternalRoots);
  if ACodePage<>0 then Selection:=Selection+#0+'CP'+IntToStr(ACodePage);
  Result:=THashSHA2.GetHashString(Selection);
end;

class function TDPHWorkspaceView.Capture(AScan: TDPHScan; AGraph: TDPHSemanticGraph; AGeneration: Int64;
  const AEntry,AConfig,APlatform: string; const ADefines,AExternalRoots: TArray<string>): TJSONObject;
var A: TJSONArray; Value: string;
begin
  Result:=TJSONObject.Create; Result.AddPair('workspace_schema',TJSONNumber.Create(1));
  Result.AddPair('captured_utc',DateToISO8601(TTimeZone.Local.ToUniversalTime(Now),True));
  Result.AddPair('generation_id',TJSONNumber.Create(AGeneration)); Result.AddPair('entry',ExtractFileName(AEntry));
  Result.AddPair('root',AScan.Inventory.Root); Result.AddPair('configuration',AConfig); Result.AddPair('platform',APlatform);
  Result.AddPair('configuration_identity',AScan.Inventory.ConfigurationIdentity);
  Result.AddPair('selection_hash',SelectionHash(AConfig,APlatform,ADefines,AExternalRoots,AScan.Inventory.CodePage));
  Result.AddPair('code_page',TJSONNumber.Create(AScan.Inventory.CodePage));
  A:=TJSONArray.Create; Result.AddPair('defines',A); for Value in ADefines do A.Add(Value);
  A:=TJSONArray.Create; Result.AddPair('external_roots',A); for Value in AExternalRoots do A.Add(Value);
  A:=TJSONArray.Create; Result.AddPair('configurations',A); for Value in AScan.Inventory.Configurations do A.Add(Value);
  A:=TJSONArray.Create; Result.AddPair('platforms',A); for Value in AScan.Inventory.Platforms do A.Add(Value);
  Result.AddPair('syntax',AScan.AsJSON(True)); Result.AddPair('semantics',AGraph.AsJSON);
  Result.AddPair('source_quality',TDPHSourceQuality.Analyze(AScan,AGraph));
  Result.AddPair('analysis_complete',TJSONBool.Create(AScan.Complete and AGraph.Complete));
  Result.AddPair('runtime_observed',TJSONBool.Create(False));
end;
constructor TDPHWorkspaceView.Create(ADocument: TJSONObject);
var V: TJSONValue; S: TJSONObject; Semantic: TJSONObject;
begin
  inherited Create; FDocument:=ADocument;
  if (ADocument=nil) or (ADocument.GetValue<Integer>('workspace_schema',0)<>1) then raise EArgumentException.Create('Unsupported workspace document');
  FSymbols:=TDictionary<string,TJSONObject>.Create;
  Semantic:=ADocument.GetValue<TJSONObject>('semantics');
  for V in Semantic.GetValue<TJSONArray>('symbols') do
  begin S:=V as TJSONObject; FSymbols.Add(S.GetValue<string>('key'),S); end;
end;
destructor TDPHWorkspaceView.Destroy;
begin FSymbols.Free; FDocument.Free; inherited; end;
function TDPHWorkspaceView.Symbol(const AKey: string): TJSONObject;
begin if not FSymbols.TryGetValue(AKey,Result) then Result:=nil; end;


function TDPHWorkspaceView.Calculations:TJSONObject;
var Files,Nodes,Rows:TJSONArray;F,N,V:TJSONValue;FileRow,Node,Row,Owner,Range:TJSONObject;
    I,Parent,Depth,Ancestor:Integer;Text,Kind,Path:string;Owners:TDictionary<Integer,TJSONObject>;
begin
 Result:=TJSONObject.Create;Rows:=TJSONArray.Create;Result.AddPair('rows',Rows);
 Result.AddPair('qualification','Captured arithmetic, bitwise/boolean and recognized mathematical API-spelling candidates; operators may be overloaded. Literals are omitted, formulas are not evaluated, and lexical spelling does not prove numeric type, runtime dispatch, reaching inputs, output units or business meaning. Parser gaps, opaque/long expressions and dynamic calculations remain unknown. Record a definition and review it against exact source evidence. No target code executes.');
 Result.AddPair('unavailable_expressions',TJSONNumber.Create(0));Depth:=0;
 Files:=FDocument.GetValue<TJSONArray>('syntax.files');
 Owners:=TDictionary<Integer,TJSONObject>.Create;
 try
  for F in Files do begin
   FileRow:=F as TJSONObject;Path:=FileRow.GetValue<string>('path');
   if not FileRow.TryGetValue<TJSONArray>('ir.nodes',Nodes) then Continue;
   Owners.Clear;
   for V in FDocument.GetValue<TJSONArray>('semantics.symbols') do
    if MatchText(V.GetValue<string>('kind'),['routine','anonymous']) and (V.GetValue<string>('range.source')=Path) then Owners.AddOrSetValue(V.GetValue<Integer>('range.start'),V as TJSONObject);
   for I:=0 to Nodes.Count-1 do begin
    Node:=Nodes[I] as TJSONObject;Kind:=Node.GetValue<string>('kind');
    if not MatchText(Kind,['expression','declaration_const']) then Continue;
    Parent:=Node.GetValue<Integer>('parent',-1);
    if (Parent>=0) and (Parent<Nodes.Count) and (Nodes[Parent].GetValue<string>('kind')='expression') then Continue;
    Text:=Node.GetValue<string>('value','');
    if (Text='') or (Length(Text)>16000) then begin Inc(Depth);Continue;end;
    Text:=TRegEx.Replace(Text,'''(?:[^'']|'''')*''','<literal omitted>');
    if not TRegEx.IsMatch(Text,'(?:^|\s)(?:\+|-|\*|/|div|mod|shl|shr|and|or|xor)(?:\s|$)|\b(?:Round|Trunc|Abs|Sqr|Sqrt|Power|Exp|Ln|Sin|Cos|Inc|Dec)\s*\(',[roIgnoreCase]) then Continue;
    if Rows.Count>=10000 then begin if Result.GetValue('limit')=nil then Result.AddPair('limit','Calculation candidate inventory truncated at 10000 rows; empty or bounded results do not establish completeness.');Break;end;
    Range:=TJSONObject.Create.AddPair('source',Path).AddPair('start',Node.GetValue('start').Clone as TJSONValue).AddPair('end',Node.GetValue('end').Clone as TJSONValue).AddPair('line',Node.GetValue('line').Clone as TJSONValue).AddPair('column',Node.GetValue('column').Clone as TJSONValue);
    Row:=TJSONObject.Create.AddPair('id',Path+'|'+Node.GetValue('start').Value+'|'+Node.GetValue('end').Value+'|'+Kind).AddPair('kind',Kind).AddPair('expression',Text).AddPair('source',Path).AddPair('source_hash',FileRow.GetValue<string>('sha256','')).AddPair('generation_id',FDocument.GetValue('generation_id').Clone as TJSONValue).AddPair('range',Range).AddPair('condition',Node.GetValue<string>('condition','')).AddPair('target_key','').AddPair('routine','Unknown').AddPair('business_meaning','Unknown').AddPair('inputs','Unknown; follow source and captured dependency links').AddPair('outputs','Unknown; follow source and define recipients').AddPair('units','Unknown');Rows.AddElement(Row);
    Owner:=nil;Ancestor:=Parent;
    for var Hop:=0 to 127 do begin
     if (Ancestor<0) or (Ancestor>=Nodes.Count) then Break;
     if Owners.TryGetValue(Nodes[Ancestor].GetValue<Integer>('start'),Owner) then Break;
     Ancestor:=Nodes[Ancestor].GetValue<Integer>('parent',-1);
    end;
    if Owner<>nil then begin Row.RemovePair('target_key').Free;Row.AddPair('target_key',Owner.GetValue<string>('key'));Row.RemovePair('routine').Free;Row.AddPair('routine',Owner.GetValue<string>('name'));end;
   end;
   if Result.GetValue('limit')<>nil then Break;
  end;
  Result.RemovePair('unavailable_expressions').Free;Result.AddPair('unavailable_expressions',TJSONNumber.Create(Depth));
 finally Owners.Free;end;
end;
class function TDPHWorkspaceView.DescribeCalculationEvidence(ARow:TJSONObject):string;
begin
 Result:='Select a captured candidate. Empty results do not prove that no calculations exist. Long/opaque expressions and unsupported or dynamic code remain unknown.';
 if ARow=nil then Exit;
 Result:='Captured expression candidate (not evaluated)'+sLineBreak+ARow.GetValue<string>('expression')+sLineBreak+
 'Routine: '+ARow.GetValue<string>('routine')+sLineBreak+'Source: '+ARow.GetValue<string>('source')+':'+ARow.GetValue<Integer>('range.line').ToString+sLineBreak+
 'SHA256: '+ARow.GetValue<string>('source_hash')+sLineBreak+'Generation: '+ARow.GetValue('generation_id').Value+sLineBreak+'Conditional context: '+ARow.GetValue<string>('condition')+sLineBreak+
 'Business meaning: Unknown'+sLineBreak+'Inputs: '+ARow.GetValue<string>('inputs')+sLineBreak+'Outputs: '+ARow.GetValue<string>('outputs')+sLineBreak+'Units: Unknown'+sLineBreak+
 'Follow source/routine evidence, create an attributed definition, attach exact implementation links and review. API spellings and operators may be overloaded. Original literals are omitted; parser gaps and expression bounds prevent an exhaustive inventory. Numerical results, runtime execution and correctness are not established.';
end;

function TDPHWorkspaceView.FileFormats:TJSONObject;
var Rows,Files,Nodes,Shape:TJSONArray; F,N,V,W:TJSONValue; FileRow,Node,Row,Range,Owner:TJSONObject;
    Path,Kind,Text,API,Direction,Extension,Encoding,Key,Member,ValueType:string;
    Tokens:TMatchCollection; Seen:TDictionary<string,Boolean>; I,J,K,Depth,Parent,ShapeCount,BestSize:Integer;
  procedure Add(const AName,ADirection,AFormat,AEncoding:string; ANode:TJSONObject; ASite:Integer=0);
  var W:TJSONValue;
  begin
   if Rows.Count>=10000 then begin if Result.GetValue('limit')=nil then Result.AddPair('limit','File-format inventory truncated at 10000 candidates.');Exit;end;
   Range:=TJSONObject.Create.AddPair('source',Path).AddPair('line',TJSONNumber.Create(ANode.GetValue<Integer>('line',1))).AddPair('column',TJSONNumber.Create(ANode.GetValue<Integer>('column',1))).AddPair('start',TJSONNumber.Create(ANode.GetValue<Integer>('start',0))).AddPair('end',TJSONNumber.Create(ANode.GetValue<Integer>('end',0)));
   Row:=TJSONObject.Create;Rows.AddElement(Row);
   Key:=Path+'|'+Range.GetValue('start').Value+'|'+AName+'|'+ADirection+'|'+IntToStr(ASite);
   Row.AddPair('id',Key).AddPair('name',AName).AddPair('direction',ADirection).AddPair('format',AFormat).AddPair('encoding',AEncoding).AddPair('source',Path).AddPair('source_hash',FileRow.GetValue<string>('sha256','')).AddPair('generation_id',FDocument.GetValue('generation_id').Clone as TJSONValue).AddPair('range',Range).AddPair('schema',TJSONArray.Create).AddPair('producer','unknown').AddPair('consumer','unknown').AddPair('target_key','');
   Owner:=nil;BestSize:=MaxInt;
   for W in FDocument.GetValue<TJSONArray>('semantics.symbols') do
    if MatchText(W.GetValue<string>('kind'),['routine','anonymous']) and (W.GetValue<string>('range.source')=Path) and (W.GetValue<Integer>('range.start')<=ANode.GetValue<Integer>('start',0)) and (W.GetValue<Integer>('range.end')>=ANode.GetValue<Integer>('end',0)) and (W.GetValue<Integer>('range.end')-W.GetValue<Integer>('range.start')<BestSize) then begin Owner:=W as TJSONObject;BestSize:=W.GetValue<Integer>('range.end')-W.GetValue<Integer>('range.start');end;
   if Owner<>nil then begin
    Row.RemovePair('target_key').Free;Row.AddPair('target_key',Owner.GetValue<string>('key'));
    if ADirection='export' then Member:='producer' else Member:='consumer';
    Row.RemovePair(Member).Free;Row.AddPair(Member,Owner.GetValue<string>('name')+' (enclosing captured routine; API binding/execution unverified)');
   end;
  end;
begin
 Result:=TJSONObject.Create;Rows:=TJSONArray.Create;Result.AddPair('rows',Rows);
 Result.AddPair('qualification','Source format candidates and captured resource shape only. API spellings, extensions and enclosing routines do not prove runtime dispatch, an accepted schema, actual encoding or successful import/export. Scalar values and literal paths are omitted. Captured resource decoding is distinct from a file-transfer encoding contract. Dynamic paths, defaults, opaque resources, parser gaps and missing structure remain unknown. Record a named contract and review it against evidence. No target code or file-transfer API executes.');
 Seen:=TDictionary<string,Boolean>.Create;
 try
  Files:=FDocument.GetValue<TJSONArray>('syntax.files');
  for F in Files do begin
   if Rows.Count>=10000 then begin if Result.GetValue('limit')=nil then Result.AddPair('limit','File-format inventory truncated at 10000 candidates.');Break;end;
   FileRow:=F as TJSONObject;Path:=FileRow.GetValue<string>('path');Extension:=LowerCase(ExtractFileExt(Path));
   if not FileRow.TryGetValue<TJSONArray>('ir.nodes',Nodes) then Continue;
   if MatchText(Extension,['.json','.xml','.ini']) then begin
    Node:=TJSONObject.Create;try Add(Path,'captured resource',Extension,'Captured source decoding: '+FileRow.GetValue<string>('encoding','unknown')+'; transfer encoding unknown',Node);finally Node.Free;end;
    Shape:=Row.GetValue<TJSONArray>('schema');ShapeCount:=0;
    for N in Nodes do if MatchText(N.GetValue<string>('kind'),['json_object','json_array','json_value','xml_element','xml_attribute','ini_section','ini_value']) then begin
     Inc(ShapeCount);if ShapeCount>250 then Continue;Member:=N.GetValue<string>('name');
     if (Length(Member)>128) or not TRegEx.IsMatch(Member,'^[A-Za-z0-9_./~:-]*$') then Member:='<nonidentifier member omitted>';
     ValueType:=N.GetValue<string>('kind');Text:=N.GetValue<string>('value','');
     if ValueType='json_value' then begin
      if Text.StartsWith('"') then ValueType:='JSON string' else if Text='null' then ValueType:='JSON null' else if MatchText(Text,['true','false']) then ValueType:='JSON boolean' else ValueType:='JSON numeric candidate';
     end;
     Shape.AddElement(TJSONObject.Create.AddPair('member',Member).AddPair('shape',ValueType));
    end;
    Row.AddPair('shape_count',TJSONNumber.Create(ShapeCount));if ShapeCount>250 then Row.AddPair('shape_limit','Captured structure display truncated to first 250 members.');
    Row.AddPair('structure_basis','Observed resource shape, not a required/optional schema contract. Scalar values omitted; missing/opaque structure remains unknown.');
   end;
   for N in Nodes do begin
    Node:=N as TJSONObject;if Node.GetValue<string>('kind')<>'expression' then Continue;
    Parent:=Node.GetValue<Integer>('parent',-1);if (Parent>=0) and (Parent<Nodes.Count) and (Nodes[Parent].GetValue<string>('kind')='expression') then Continue;
    Text:=Node.GetValue<string>('value','');if (Text='') or (Length(Text)>16000) then Continue;
    // IR expression text is bounded by the parser. Quoted literals are single tokens.
    Tokens:=TRegEx.Matches(Text,'''(?:[^'']|'''')*''|[A-Za-z_][A-Za-z0-9_]*|[^\s]');
    for I:=0 to Tokens.Count-2 do begin
     API:=Tokens[I].Value;if not MatchText(API,['ReadAllText','ReadAllBytes','ReadAllLines','WriteAllText','WriteAllBytes','WriteAllLines','LoadFromFile','SaveToFile']) or (Tokens[I+1].Value<>'(') then Continue;
     if (I=0) or (Tokens[I-1].Value<>'.') then Continue;
     Direction:='import';if MatchText(API,['WriteAllText','WriteAllBytes','WriteAllLines','SaveToFile']) then Direction:='export';
     Key:=Path+'|'+Node.GetValue('start').Value+'|'+IntToStr(I)+'|'+API;if Seen.ContainsKey(Key) then Continue;Seen.Add(Key,True);
     Extension:='unknown; dynamic or unsupported path';J:=I+2;
     if (J+1<Tokens.Count) and Tokens[J].Value.StartsWith('''') and MatchText(Tokens[J+1].Value,[',',')']) then begin
      Extension:=LowerCase(ExtractFileExt(Tokens[J].Value.Trim([''''])));
      if (Length(Extension)>16) or not TRegEx.IsMatch(Extension,'^\.[a-z0-9]+$') then Extension:='unknown; no supported filename extension';
      Extension:=Extension+' (filename candidate; contents unverified)';
     end;
     Encoding:='unknown; default, custom receiver or unsupported encoding';Depth:=1;K:=J;
     while (K<Tokens.Count) and (Depth>0) do begin
      if Tokens[K].Value='(' then Inc(Depth) else if Tokens[K].Value=')' then Dec(Depth);
      if (K+2<Tokens.Count) and SameText(Tokens[K].Value,'TEncoding') and (Tokens[K+1].Value='.') and MatchText(Tokens[K+2].Value,['UTF8','Unicode','BigEndianUnicode','ASCII','Default']) then Encoding:=Tokens[K+2].Value+' (explicit source argument candidate; runtime binding unverified)';
      Inc(K);
     end;
     if MatchText(API,['ReadAllBytes','WriteAllBytes']) then Encoding:='binary byte API candidate; text encoding not established';
     if Rows.Count>=10000 then begin if Result.GetValue('limit')=nil then Result.AddPair('limit','File-format inventory truncated at 10000 candidates.');Break;end;
     Add(API,Direction,Extension,Encoding,Node,I);Row.AddPair('structure_basis','Transfer schema unknown; inspect the captured routine and record an explicit contract. Location is the enclosing IR expression.');
    end;
   end;
  end;
 except Seen.Free;Result.Free;raise;end;
 Seen.Free;
end;

class function TDPHWorkspaceView.FileFormatContractTitle(ARow:TJSONObject):string;
begin Result:='File format contract '+THashSHA2.GetHashString(ARow.GetValue<string>('id')+#0+ARow.GetValue<string>('source_hash'));end;
class function TDPHWorkspaceView.DescribeFileFormat(ARow:TJSONObject):string;
var V:TJSONValue;
begin
 Result:='FILE FORMAT EVIDENCE'+sLineBreak+ARow.GetValue<string>('name')+' | '+ARow.GetValue<string>('direction')+sLineBreak+
  'Format: '+ARow.GetValue<string>('format')+sLineBreak+'Encoding: '+ARow.GetValue<string>('encoding')+sLineBreak+'Producer: '+ARow.GetValue<string>('producer')+sLineBreak+'Consumer: '+ARow.GetValue<string>('consumer')+sLineBreak+ARow.GetValue<string>('structure_basis','')+sLineBreak;
 for V in ARow.GetValue<TJSONArray>('schema') do Result:=Result+V.GetValue<string>('member')+' : '+V.GetValue<string>('shape')+sLineBreak;
 Result:=Result+ARow.GetValue<string>('shape_limit','')+sLineBreak+'Source: '+ARow.GetValue<string>('source')+' | line '+ARow.GetValue<TJSONObject>('range').GetValue('line').Value+sLineBreak+'SHA256 '+ARow.GetValue<string>('source_hash')+' | generation '+ARow.GetValue('generation_id').Value+sLineBreak;
end;

function TDPHWorkspaceView.ProjectMembers: TJSONArray;
var Files,Nodes,Properties: TJSONArray; FileValue,NodeValue: TJSONValue;
    FileRow,Node,Member: TJSONObject; Path,Extension,Kind,Name: string;
begin
  Result:=TJSONArray.Create;
  try
    Files:=FDocument.GetValue<TJSONArray>('syntax.files');
    for FileValue in Files do begin
      FileRow:=FileValue as TJSONObject; Path:=FileRow.GetValue<string>('path');
      Extension:=LowerCase(ExtractFileExt(Path));
      if not MatchText(Extension,['.dproj','.groupproj','.dpr','.dpk']) then Continue;
      if Extension='.groupproj' then Kind:='project group'
      else if Extension='.dproj' then Kind:='project settings'
      else Kind:='unresolved output kind';
      Name:=TPath.GetFileNameWithoutExtension(Path);
      Member:=TJSONObject.Create; Result.AddElement(Member);
      Member.AddPair('path',Path); Member.AddPair('source_hash',FileRow.GetValue<string>('sha256'));
      Member.AddPair('availability',FileRow.GetValue<string>('availability'));
      Member.AddPair('generation_id',TJSONNumber.Create(FDocument.GetValue<Int64>('generation_id')));
      Properties:=TJSONArray.Create; Member.AddPair('settings_and_references',Properties);
      if FileRow.TryGetValue<TJSONArray>('ir.nodes',Nodes) then
        for NodeValue in Nodes do begin
          Node:=NodeValue as TJSONObject;
          if MatchText(Node.GetValue<string>('kind'),['program','library','package']) then begin
            Name:=Node.GetValue<string>('name');
            if Node.GetValue<string>('kind')='program' then Kind:='executable declaration'
            else if Node.GetValue<string>('kind')='library' then Kind:='library declaration'
            else Kind:='package declaration';
            Member.AddPair('declaration',Node.Clone as TJSONValue);
          end;
          if MatchText(Node.GetValue<string>('kind'),['project_property','project_reference']) then
            Properties.AddElement(Node.Clone as TJSONValue);
        end;
      Member.AddPair('name',Name); Member.AddPair('kind',Kind);
      Member.AddPair('qualification','Captured selected-project inputs only. Project settings and their main-source declarations are separate evidence rows, not separate applications. Output kind describes a declaration, not a built binary or verified service installation. Settings belong to the captured configuration; parent conditions may apply even when a child has no recorded condition. Read diagnostics for missing inputs and unsupported project conditions.');
    end;
  except Result.Free; raise; end;
end;
function TDPHWorkspaceView.Search(const AQuery,AKind,AScope: string; AOffset,ALimit: Integer): TJSONArray;
var V: TJSONValue; S: TJSONObject; Count: Integer; Name,Kind: string;
begin
  if (AOffset<0) or (ALimit<1) or (ALimit>1000) then raise EArgumentException.Create('Invalid Explorer page');
  Result:=TJSONArray.Create; Count:=0;
  for V in FDocument.GetValue<TJSONObject>('semantics').GetValue<TJSONArray>('symbols') do
  begin
    S:=V as TJSONObject; Name:=S.GetValue<string>('name'); Kind:=S.GetValue<string>('kind');
    if (AKind<>'') and (Kind<>AKind) then Continue;
    if (AScope<>'') and not StartsText(AScope+'.',Name) then Continue;
    if (AQuery<>'') and not ContainsText(Name+' '+S.GetValue<string>('signature')+' '+Kind,AQuery) then Continue;
    if Count>=AOffset then Result.AddElement(S.Clone as TJSONObject);
    Inc(Count); if Result.Count>=ALimit then Break;
  end;
end;
function TDPHWorkspaceView.Hierarchy(const AExpanded: TArray<string>; AOffset,ALimit: Integer): TJSONArray;
var Children: TObjectDictionary<string,TList<string>>; Parents: TDictionary<string,string>;
    Expanded,Seen: TDictionary<string,Boolean>; Roots: TList<string>; Items: TList<string>;
    V: TJSONValue; R: TJSONObject; Key,Owner,Child: string; VisibleCount: Integer;
  procedure Visit(const AKey: string; Depth: Integer);
  var Row,CopyRow: TJSONObject; Branch: TList<string>; ChildKey: string; HasChildren,IsExpanded: Boolean;
  begin
    if (Depth>128) or (Result.Count>=ALimit) or Seen.ContainsKey(AKey) then Exit;
    Row:=Symbol(AKey); if Row=nil then Exit; Seen.Add(AKey,True);
    HasChildren:=Children.TryGetValue(AKey,Branch); IsExpanded:=Expanded.ContainsKey(AKey);
    if VisibleCount>=AOffset then begin
      CopyRow:=Row.Clone as TJSONObject; Result.AddElement(CopyRow);
      CopyRow.AddPair('depth',TJSONNumber.Create(Depth)); CopyRow.AddPair('has_children',TJSONBool.Create(HasChildren));
      CopyRow.AddPair('expanded',TJSONBool.Create(IsExpanded));
    end;
    Inc(VisibleCount);
    if HasChildren and IsExpanded then for ChildKey in Branch do Visit(ChildKey,Depth+1);
  end;
begin
  if (AOffset<0) or (ALimit<1) or (ALimit>1000) then raise EArgumentException.Create('Invalid hierarchy page');
  Result:=TJSONArray.Create;
  Children:=TObjectDictionary<string,TList<string>>.Create([doOwnsValues]); Parents:=TDictionary<string,string>.Create;
  Expanded:=TDictionary<string,Boolean>.Create; Seen:=TDictionary<string,Boolean>.Create; Roots:=TList<string>.Create;
  try
    try
    for Key in AExpanded do Expanded.AddOrSetValue(Key,True);
    for V in FDocument.GetValue<TJSONArray>('semantics.relationships') do begin
      R:=V as TJSONObject; if R.GetValue<string>('kind')<>'owns' then Continue;
      Owner:=R.GetValue<string>('from'); Child:=R.GetValue<string>('to','');
      if (Owner=Child) or (Symbol(Owner)=nil) or (Symbol(Child)=nil) or Parents.ContainsKey(Child) then Continue;
      Parents.Add(Child,Owner);
      if not Children.TryGetValue(Owner,Items) then begin Items:=TList<string>.Create; Children.Add(Owner,Items); end;
      Items.Add(Child);
    end;
    for V in FDocument.GetValue<TJSONArray>('semantics.symbols') do begin
      Key:=(V as TJSONObject).GetValue<string>('key'); if not Parents.ContainsKey(Key) then Roots.Add(Key);
    end;
    VisibleCount:=0; for Key in Roots do Visit(Key,0);
    except Result.Free; raise; end;
  finally Roots.Free; Seen.Free; Expanded.Free; Parents.Free; Children.Free; end;
end;

function TDPHWorkspaceView.Neighbors(const AKey,ADirection: string): TJSONArray;
var V: TJSONValue; R: TJSONObject; Field: string;
begin
  Result:=TJSONArray.Create; Field:='from'; if ADirection='reverse' then Field:='to';
  for V in FDocument.GetValue<TJSONObject>('semantics').GetValue<TJSONArray>('relationships') do
  begin R:=V as TJSONObject; if R.GetValue<string>(Field,'')=AKey then Result.AddElement(R.Clone as TJSONObject); end;
end;
function TDPHWorkspaceView.SourceFile(const APath: string): TJSONObject;
var V: TJSONValue;
begin
  Result:=nil; for V in FDocument.GetValue<TJSONObject>('syntax').GetValue<TJSONArray>('files') do
    if SameText((V as TJSONObject).GetValue<string>('path'),APath) then Exit(V as TJSONObject);
end;
function TDPHWorkspaceView.Properties(const AKey: string): TJSONArray;
var S,FileRow,N,Range: TJSONObject; V: TJSONValue; Nodes: TJSONArray; NodeID,I: Integer;
begin
  Result:=TJSONArray.Create; S:=Symbol(AKey); if S=nil then Exit;
  Range:=S.GetValue<TJSONObject>('range'); FileRow:=SourceFile(Range.GetValue<string>('source')); if FileRow=nil then Exit;
  Nodes:=FileRow.GetValue<TJSONObject>('ir').GetValue<TJSONArray>('nodes'); NodeID:=-1;
  for I:=0 to Nodes.Count-1 do
  begin N:=Nodes.Items[I] as TJSONObject;
    if (N.GetValue<Int64>('start')=Range.GetValue<Int64>('start')) and MatchText(N.GetValue<string>('kind'),['object','inherited','inline']) then begin NodeID:=I; Break; end;
  end;
  if NodeID<0 then Exit;
  for V in Nodes do begin N:=V as TJSONObject; if (N.GetValue<Integer>('parent')=NodeID) and (N.GetValue<string>('kind')='property') then Result.AddElement(N.Clone as TJSONObject); end;
end;
function TDPHWorkspaceView.Details(const AKey: string): TJSONArray;
var V: TJSONValue; Row,CopyRow,FileRow: TJSONObject; PropertiesRows: TJSONArray; FlowRows: TList<TJSONObject>;
begin
  Result:=TJSONArray.Create; FlowRows:=TList<TJSONObject>.Create;
  try
    try
    for V in FDocument.GetValue<TJSONArray>('semantics.flow_nodes') do begin
      Row:=V as TJSONObject; if Row.GetValue<string>('routine')<>AKey then Continue;
      FlowRows.Add(Row);
    end;
    FlowRows.Sort(TComparer<TJSONObject>.Construct(
      function(const L,R: TJSONObject): Integer
      var LeftBoundary,RightBoundary: Boolean;
      begin
        LeftBoundary:=MatchText(L.GetValue<string>('kind'),['entry','normal_exit','exception_exit']);
        RightBoundary:=MatchText(R.GetValue<string>('kind'),['entry','normal_exit','exception_exit']);
        if LeftBoundary<>RightBoundary then begin if LeftBoundary then Exit(1) else Exit(-1); end;
        Result:=CompareStr(L.GetValue<string>('range.source'),R.GetValue<string>('range.source'));
        if Result=0 then begin
          if L.GetValue<Int64>('range.start')<R.GetValue<Int64>('range.start') then Result:=-1
          else if L.GetValue<Int64>('range.start')>R.GetValue<Int64>('range.start') then Result:=1;
        end;
      end));
    for Row in FlowRows do begin
      CopyRow:=Row.Clone as TJSONObject; Result.AddElement(CopyRow);
      if MatchText(Row.GetValue<string>('kind'),['entry','normal_exit','exception_exit']) then CopyRow.AddPair('detail_kind','flow boundary')
      else CopyRow.AddPair('detail_kind','statement'); CopyRow.AddPair('title',Row.GetValue<string>('kind'));
      CopyRow.AddPair('object_key',AKey);
      CopyRow.AddPair('text',Row.GetValue<string>('expression')); CopyRow.AddPair('resolution','inferred');
      CopyRow.AddPair('rule','captured_control_flow_not_runtime_trace'); if Result.Count>=1000 then Exit;
    end;
    PropertiesRows:=Properties(AKey);
    try for V in PropertiesRows do begin
      Row:=V as TJSONObject; CopyRow:=TJSONObject.Create; Result.AddElement(CopyRow);
      CopyRow.AddPair('detail_kind','property'); CopyRow.AddPair('title',Row.GetValue<string>('name'));
      CopyRow.AddPair('object_key',AKey);
      CopyRow.AddPair('text',Row.GetValue<string>('value')); CopyRow.AddPair('range',Row.Clone as TJSONObject);
      CopyRow.AddPair('resolution','confirmed_static'); CopyRow.AddPair('rule','serialized_override_not_framework_default');
      FileRow:=SourceFile(Row.GetValue<string>('source')); if FileRow<>nil then CopyRow.AddPair('source_hash',FileRow.GetValue<string>('sha256'));
      if Result.Count>=1000 then Exit;
    end; finally PropertiesRows.Free; end;
    for V in FDocument.GetValue<TJSONArray>('semantics.relationships') do begin
      Row:=V as TJSONObject; if Row.GetValue<string>('from')<>AKey then Continue;
      CopyRow:=Row.Clone as TJSONObject; Result.AddElement(CopyRow);
      CopyRow.AddPair('detail_kind','relationship'); CopyRow.AddPair('title',Row.GetValue<string>('kind'));
      CopyRow.AddPair('object_key',Row.GetValue<string>('to',AKey));
      CopyRow.AddPair('text',Row.GetValue<string>('label')); if Result.Count>=1000 then Exit;
    end;
    except Result.Free; raise; end;
  finally FlowRows.Free; end;
end;

function TDPHWorkspaceView.Graph(const AKind,AKey: string; ALimit: Integer): TJSONObject;
var Nodes,Edges,AllNodes,AllEdges: TJSONArray; V: TJSONValue; R,S,N: TJSONObject;
    Seen,EdgeKeys: TDictionary<string,Boolean>; Queue: TQueue<string>; Key,FromKey,ToKey,Kind,EdgeKey: string;
    I: Integer; Truncated: Boolean;
  procedure AddSymbolNode(const K: string);
  var Row,Sym: TJSONObject;
  begin
    if (K='') or Seen.ContainsKey(K) then Exit;
    if Seen.Count>=ALimit then begin Truncated:=True; Exit; end;
    Seen.Add(K,True); Sym:=Symbol(K); Row:=TJSONObject.Create; Row.AddPair('id',K);
    if Sym<>nil then begin Row.AddPair('label',Sym.GetValue<string>('name')); Row.AddPair('kind',Sym.GetValue<string>('kind')); Row.AddPair('type',Sym.GetValue<string>('type')); Row.AddPair('range',Sym.GetValue<TJSONObject>('range').Clone as TJSONObject); end
    else Row.AddPair('label',K); Nodes.AddElement(Row); Queue.Enqueue(K);
  end;
begin
  if (ALimit<1) or (ALimit>1000) then raise EArgumentException.Create('Invalid graph limit');
  Result:=TJSONObject.Create; Nodes:=TJSONArray.Create; Edges:=TJSONArray.Create;
  Result.AddPair('kind',AKind); Result.AddPair('nodes',Nodes); Result.AddPair('edges',Edges);
  Result.AddPair('generation_id',TJSONNumber.Create(FDocument.GetValue<Int64>('generation_id')));
  Result.AddPair('runtime_trace',TJSONBool.Create(False)); Truncated:=False;
  Seen:=TDictionary<string,Boolean>.Create; EdgeKeys:=TDictionary<string,Boolean>.Create; Queue:=TQueue<string>.Create;
  try
    S:=FDocument.GetValue<TJSONObject>('semantics');
    if AKind='Procedure CFG' then
    begin
      AllNodes:=S.GetValue<TJSONArray>('flow_nodes'); AllEdges:=S.GetValue<TJSONArray>('flow_edges');
      for V in AllNodes do
      begin N:=V as TJSONObject; if N.GetValue<string>('routine')<>AKey then Continue;
        if Nodes.Count>=ALimit then begin Truncated:=True; Break; end;
        R:=N.Clone as TJSONObject; Key:=N.GetValue<Integer>('id').ToString; R.AddPair('label',N.GetValue<string>('kind')+' '+N.GetValue<string>('expression'));
        Nodes.AddElement(R); Seen.Add(Key,True);
      end;
      for V in AllEdges do begin R:=V as TJSONObject;
        if Seen.ContainsKey(R.GetValue<Integer>('from').ToString) and Seen.ContainsKey(R.GetValue<Integer>('to').ToString) then Edges.AddElement(R.Clone as TJSONObject);
      end;
    end
    else
    begin
      AddSymbolNode(AKey);
      if (AKey='') and (AKind='Execution') then
        for V in S.GetValue<TJSONArray>('symbols') do begin N:=V as TJSONObject;
          if (N.GetValue<string>('kind')='unit') and MatchText(N.GetValue<string>('type'),['program','library','package']) then AddSymbolNode(N.GetValue<string>('key'));
        end;
      if (AKey='') and (AKind='Form navigation') then
        for V in S.GetValue<TJSONArray>('symbols') do begin N:=V as TJSONObject;
          if (N.GetValue<string>('kind')='component') and MatchText(ExtractFileExt(N.GetValue<string>('range.source')),['.fmx','.dfm']) then begin
            R:=SourceFile(N.GetValue<string>('range.source'));
            if (R<>nil) and (R.GetValue<TJSONArray>('ir.nodes').Count>0) and
              (R.GetValue<TJSONArray>('ir.nodes').Items[0].GetValue<Int64>('start')=N.GetValue<Int64>('range.start')) then AddSymbolNode(N.GetValue<string>('key'));
          end;
        end;
      if (AKey='') and (AKind='Data flow') then
        for V in S.GetValue<TJSONArray>('symbols') do begin N:=V as TJSONObject;
          if MatchText(N.GetValue<string>('kind'),['parameter','local','field','property','variable','resource','definition','sql_statement','sql_table','sql_column','output_artifact']) then AddSymbolNode(N.GetValue<string>('key'));
        end;
      if (AKey='') and (Nodes.Count=0) then for V in S.GetValue<TJSONArray>('symbols') do
      begin N:=V as TJSONObject; if N.GetValue<Boolean>('has_body') then begin AddSymbolNode(N.GetValue<string>('key')); Break; end; end;
      while Queue.Count>0 do
      begin
        Key:=Queue.Dequeue;
        for V in S.GetValue<TJSONArray>('relationships') do
        begin
          R:=V as TJSONObject; Kind:=R.GetValue<string>('kind'); FromKey:=R.GetValue<string>('from'); ToKey:=R.GetValue<string>('to','');
          if (AKind='Change impact') then begin if ToKey<>Key then Continue; end
          else if (AKind='Caller / callee') then begin if (FromKey<>Key) and (ToKey<>Key) then Continue; end
          else if (AKind='Data flow') then begin if (FromKey<>Key) and (ToKey<>Key) then Continue; end
          else if (AKind='Form navigation') and MatchText(Kind,['represents','form_instance','component_field','binds']) then begin if (FromKey<>Key) and (ToKey<>Key) then Continue; end
          else if FromKey<>Key then Continue;
          if (AKind='Execution') and not MatchText(Kind,['calls','schedules','passes_callback','prepares_callback','starts','dispatches','waits_for','requests_cancellation','signals','waits_for_signal','binds','enters','initializes','finalizes','creates']) then Continue;
          if (AKind='Form navigation') and not MatchText(Kind,['owns','binds','calls','schedules','creates','assigned_to','mutates_property','assigns_callback','uses_type','represents','form_instance','component_field','shows_form','shows_modal_form','hides_form','closes_form']) then Continue;
          if (AKind='Data flow') and not MatchText(Kind,['reads','writes','renders','captures','assigned_to','derives_from','configures','static_sql','dynamic_sql','mutates_property']) then Continue;
          AddSymbolNode(FromKey); AddSymbolNode(ToKey);
          if Seen.ContainsKey(FromKey) and Seen.ContainsKey(ToKey) then begin
            EdgeKey:=FromKey+#0+ToKey+#0+Kind+#0+R.GetValue<string>('range.source')+#0+R.GetValue<Int64>('range.start').ToString+#0+R.GetValue<string>('rule')+#0+R.GetValue<string>('condition');
            if not EdgeKeys.ContainsKey(EdgeKey) then begin EdgeKeys.Add(EdgeKey,True); Edges.AddElement(R.Clone as TJSONObject); end;
          end;
          if Edges.Count>=ALimit*8 then begin Truncated:=True; Queue.Clear; Break; end;
        end;
      end;
    end;
    Result.AddPair('truncated',TJSONBool.Create(Truncated));
  finally Queue.Free; EdgeKeys.Free; Seen.Free; end;
end;
function TDPHWorkspaceView.Questions(AKnowledge: TJSONArray): TJSONArray;
var V: TJSONValue; Row,Range,Answer: TJSONObject; Diagnostics: TJSONArray;
  Answered,Seen: TDictionary<string,Boolean>; Counts: TDictionary<string,Integer>;
  Kind,Title,Prompt,Key,Code,Context: string; HasUser,HasBuild: Boolean;
  procedure AddQuestion(const AKind,ATitle,APrompt,AKey,ARule: string; ARange: TJSONObject);
  var Item,Location,Source: TJSONObject; ID,Hash: string; Count: Integer;
  begin
    if Result.Count>=100 then Exit; Count:=0; Counts.TryGetValue(AKind,Count); if Count>=20 then Exit;
    if ARange<>nil then Location:=ARange.Clone as TJSONObject else begin Location:=TJSONObject.Create;
      Location.AddPair('source',''); Location.AddPair('start',TJSONNumber.Create(0)); Location.AddPair('end',TJSONNumber.Create(0));
      Location.AddPair('line',TJSONNumber.Create(0)); Location.AddPair('column',TJSONNumber.Create(0)); end;
    Hash:=''; Source:=SourceFile(Location.GetValue<string>('source','')); if Source<>nil then Hash:=Source.GetValue<string>('sha256','');
    ID:=THashSHA2.GetHashString(AKind+#0+AKey+#0+Location.ToJSON+#0+Hash+#0+APrompt+#0+ARule+#0+Context);
    if Seen.ContainsKey(ID) or Answered.ContainsKey(ID) then begin Location.Free; Exit; end;
    Seen.Add(ID,True); Counts.AddOrSetValue(AKind,Count+1); Item:=TJSONObject.Create; Result.AddElement(Item);
    Item.AddPair('id',ID); Item.AddPair('kind',AKind); Item.AddPair('title',ATitle); Item.AddPair('prompt',APrompt);
    Item.AddPair('entity_key',AKey); Item.AddPair('range',Location); Item.AddPair('source_hash',Hash); Item.AddPair('rule',ARule);
    Item.AddPair('context_fingerprint',Context); Item.AddPair('generation_id',FDocument.GetValue<Int64>('generation_id').ToString);
    Item.AddPair('verification_state','unanswered_question');
    Item.AddPair('answer_kind',IfThen(ATitle='Document the operating procedure','user_help',IfThen(ATitle='Document build and deployment','build_deploy','unknown')));
  end;
begin
  Result:=TJSONArray.Create; Answered:=TDictionary<string,Boolean>.Create; Seen:=TDictionary<string,Boolean>.Create; Counts:=TDictionary<string,Integer>.Create;
  try
    Context:=FDocument.GetValue<string>('semantics.context_fingerprint'); HasUser:=False; HasBuild:=False;
    if AKnowledge<>nil then for V in AKnowledge do begin Row:=V as TJSONObject;
      if (Row.GetValue<string>('state','')<>'verified') or (Row.GetValue<string>('pending','1')<>'0') then Continue;
      HasUser:=HasUser or (Row.GetValue<string>('kind')='user_help'); HasBuild:=HasBuild or (Row.GetValue<string>('kind')='build_deploy');
      Answer:=TJSONObject.ParseJSONValue(Row.GetValue<string>('question_json','')) as TJSONObject;
      try if Answer<>nil then Answered.AddOrSetValue(Answer.GetValue<string>('id'),True); finally Answer.Free; end;
    end;
    Prompt:='For '+FDocument.GetValue<string>('entry')+' ('+FDocument.GetValue<string>('configuration')+' / '+FDocument.GetValue<string>('platform')+'), ';
    if not HasUser then AddQuestion('missing_procedure','Document the operating procedure',Prompt+
      'which user actions, required inputs, permissions, success checks and recovery steps should a new operator follow? No verified user-help record is captured. Provide an attributed procedure and examples; control names alone cannot establish it.','','absence_of_verified_user_help_record',nil);
    if not HasBuild then AddQuestion('missing_procedure','Document build and deployment',Prompt+
      'what exact toolchain, dependencies, environment settings, build commands, installation and rollback steps are required? No verified build/deployment record is captured. Passive scanning did not run the project.','','absence_of_verified_build_record',nil);
    for V in FDocument.GetValue<TJSONArray>('semantics.relationships') do begin Row:=V as TJSONObject;
      if not MatchText(Row.GetValue<string>('resolution'),['unresolved','possible_dynamic']) then Continue;
      Kind:=Row.GetValue<string>('kind'); Key:=Row.GetValue<string>('from');
      if not MatchText(Kind,['calls','binds','schedules','passes_callback','dynamic_sql','renders','shows_form','shows_modal_form']) then Continue;
      Prompt:='At '+Row.GetValue<string>('range.source')+':'+Row.GetValue<Int64>('range.line').ToString+', the captured '+Kind+
        ' relationship '+Row.GetValue<string>('label','')+' is '+Row.GetValue<string>('resolution')+'. Which concrete target or behavior is intended in this configuration, what selects it, and which example or test verifies that choice?';
      AddQuestion('unresolved_relationship','Resolve '+Kind+' at '+Row.GetValue<string>('range.source'),Prompt,Key,Row.GetValue<string>('rule'),Row.GetValue<TJSONObject>('range'));
    end;
    Diagnostics:=TJSONArray.Create;
    try
      for V in FDocument.GetValue<TJSONArray>('syntax.diagnostics') do Diagnostics.AddElement(V.Clone as TJSONObject);
      for V in FDocument.GetValue<TJSONArray>('semantics.diagnostics') do Diagnostics.AddElement(V.Clone as TJSONObject);
      for V in Diagnostics do begin Row:=V as TJSONObject; Code:=Row.GetValue<string>('code'); Range:=Row.GetValue<TJSONObject>('range');
        if not (ContainsText(Code,'UNRESOLVED') or ContainsText(Code,'UNSUPPORTED') or ContainsText(Code,'DYNAMIC') or ContainsText(Code,'REVIEW') or ContainsText(Code,'OPAQUE')) then Continue;
        Prompt:='The captured diagnostic '+Code+' at '+Range.GetValue<string>('source')+':'+Range.GetValue<Int64>('line').ToString+
          ' reports: '+Row.GetValue<string>('message')+'. Please explain the intended behavior at this location, its required inputs and effects, and a regression example. This is an analysis gap; it does not establish a runtime defect.';
        AddQuestion('diagnostic_gap','Explain '+Code,Prompt,'',Code,Range);
      end;
    finally Diagnostics.Free; end;
    for V in FDocument.GetValue<TJSONArray>('semantics.symbols') do begin Row:=V as TJSONObject; Kind:=Row.GetValue<string>('kind');
      if not MatchText(Kind,['async_operation','sql_statement','output_artifact']) then Continue;
      Title:=''; Prompt:='';
      if Kind='async_operation' then begin Title:='Explain background-work ownership'; Prompt:='For captured operation '+Row.GetValue<string>('name')+', which thread or object owns the work, what signals completion, what cancels it, and what lifetime guarantees and tests are required? Captured scheduling does not establish runtime order.'; end;
      if Kind='sql_statement' then begin Title:='Explain SQL contract'; Prompt:='For captured SQL statement '+Row.GetValue<string>('name')+', which schema, parameter constraints, transaction boundaries and failure handling are intended? Provide a safe test example and the expected data effect. No database connection was made.'; end;
      if Kind='output_artifact' then begin Title:='Explain output acceptance'; Prompt:='For captured output '+Row.GetValue<string>('name')+', what destination and contents are required, which inputs determine them, how should a user verify success, and how should partial or failed writes be handled? Static writer evidence does not prove that a file was produced.'; end;
      AddQuestion(Kind,Title,Prompt,Row.GetValue<string>('key'),'captured_object_missing_operational_contract',Row.GetValue<TJSONObject>('range'));
    end;
  except Result.Free; Counts.Free; Seen.Free; Answered.Free; raise;
  end;
  Counts.Free; Seen.Free; Answered.Free;
end;
function TDPHWorkspaceView.Coverage: TJSONObject;
var Files,Relations,Diagnostics,Metrics,Nodes: TJSONArray; V,W,E: TJSONValue; R,IR,N,Edge: TJSONObject;
  Parsed,Available,Complete,Confirmed,Unresolved,Events,BoundEvents,Evidence: Integer; Recognized,Tokens: Int64; Matched: Boolean;
  procedure Metric(const Name,Definition: string; Numerator,Denominator: Int64);
  var Row: TJSONObject;
  begin Row:=TJSONObject.Create; Metrics.AddElement(Row); Row.AddPair('name',Name);
    Row.AddPair('definition',Definition); Row.AddPair('numerator',TJSONNumber.Create(Numerator));
    Row.AddPair('denominator',TJSONNumber.Create(Denominator)); end;
begin
  Result:=TJSONObject.Create; Metrics:=TJSONArray.Create; Result.AddPair('metrics',Metrics);
  Diagnostics:=TJSONArray.Create; Result.AddPair('diagnostics',Diagnostics);
  Files:=FDocument.GetValue<TJSONArray>('syntax.files'); Relations:=FDocument.GetValue<TJSONArray>('semantics.relationships');
  Parsed:=0; Available:=0; Complete:=0; Recognized:=0; Tokens:=0; Confirmed:=0; Unresolved:=0;
  Events:=0; BoundEvents:=0; Evidence:=0;
  for V in Files do begin R:=V as TJSONObject;
    if R.GetValue<string>('sha256','')<>'' then Inc(Available);
    if R.TryGetValue<TJSONObject>('ir',IR) then begin Inc(Parsed);
      if IR.GetValue<Boolean>('complete',False) then Inc(Complete);
      Inc(Recognized,IR.GetValue<Int64>('recognized_tokens',0)); Inc(Tokens,IR.GetValue<Int64>('significant_tokens',0));
      if MatchText(ExtractFileExt(R.GetValue<string>('path')),['.fmx','.dfm']) and IR.TryGetValue<TJSONArray>('nodes',Nodes) then
        for W in Nodes do begin N:=W as TJSONObject;
          if (N.GetValue<string>('kind')<>'property') or not StartsText('On',N.GetValue<string>('name')) or (Trim(N.GetValue<string>('value'))='') then Continue;
          Inc(Events); Matched:=False;
          for E in Relations do begin Edge:=E as TJSONObject;
            if (Edge.GetValue<string>('kind')='binds') and (Edge.GetValue<string>('resolution')='confirmed_static') and
              SameText(Edge.GetValue<string>('range.source'),R.GetValue<string>('path')) and
              (Edge.GetValue<Int64>('range.start')=N.GetValue<Int64>('start')) then begin Matched:=True; Break; end;
          end;
          if Matched then Inc(BoundEvents);
        end;
    end;
  end;
  for V in Relations do begin R:=V as TJSONObject;
    if R.GetValue<string>('resolution')='confirmed_static' then Inc(Confirmed);
    if R.GetValue<string>('resolution')='unresolved' then Inc(Unresolved);
    if (R.GetValue<string>('range.source','')<>'') and (R.GetValue<string>('rule','')<>'') then Inc(Evidence);
  end;
  Metric('Fingerprinted inventory files','Files with captured SHA256 / files in selected inventory. Not all files on disk.',Available,Files.Count);
  Metric('Files with parsed IR','Files with an intermediate representation / selected inventory files. Opaque resources may have no IR.',Parsed,Files.Count);
  Metric('Complete parsed files','IR complete flag / files with IR. This does not measure semantic correctness.',Complete,Parsed);
  Metric('Recognized syntax tokens','Sum of recognized tokens / significant tokens in parsed files. Not runtime coverage.',Recognized,Tokens);
  Metric('Confirmed static relationships','confirmed_static relationship records / all captured relationship records. Inferred edges remain separate.',Confirmed,Relations.Count);
  Metric('Unresolved relationships','unresolved relationship records / all captured relationship records. A zero count does not prove completeness.',Unresolved,Relations.Count);
  Metric('Serialized event bindings','Nonempty On-prefixed serialized properties with a confirmed static binds edge / nonempty On-prefixed properties in captured forms. Dynamic assignments excluded.',BoundEvents,Events);
  Metric('Source-located relationship evidence','Relationship records with a source location and derivation rule / all captured relationship records. Location is not human verification.',Evidence,Relations.Count);
  for V in FDocument.GetValue<TJSONArray>('syntax.diagnostics') do Diagnostics.AddElement(V.Clone as TJSONObject);
  for V in FDocument.GetValue<TJSONArray>('semantics.diagnostics') do Diagnostics.AddElement(V.Clone as TJSONObject);
end;
function TDPHWorkspaceView.FlagsText: string;
begin
  Result:='Generation '+FDocument.GetValue<Int64>('generation_id').ToString+' | ';
  if FDocument.GetValue<Boolean>('analysis_complete') then Result:=Result+'complete captured analysis' else Result:=Result+'PARTIAL analysis - inspect diagnostics';
  Result:=Result+' | static evidence; runtime behavior unobserved';
end;
end.
