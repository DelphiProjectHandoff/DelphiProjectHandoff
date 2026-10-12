unit DPH.UI.ActionPurpose;
interface
uses System.Classes, System.SysUtils, System.JSON, System.UITypes, FMX.Types, FMX.Controls, FMX.Forms,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.Edit, FMX.Memo;
type
  TDPHActionPurposeForm = class(TForm)
    ProfilePurpose,ProfileAuthorLabel: TLabel;
    ProfileToolbar: TLayout;
    ProfileAuthorEdit: TEdit;
    ApplyProfileButton,CancelProfileButton: TButton;
    ProfileScroll: TVertScrollBox;
    Profile_action_id_Row: TLayout;
    Profile_action_id_Label: TLabel;
    Profile_action_id: TMemo;
    Profile_target_Row: TLayout;
    Profile_target_Label: TLabel;
    Profile_target: TMemo;
    Profile_target_key_Row: TLayout;
    Profile_target_key_Label: TLabel;
    Profile_target_key: TMemo;
    Profile_action_name_Row: TLayout;
    Profile_action_name_Label: TLabel;
    Profile_action_name: TMemo;
    Profile_screen_Row: TLayout;
    Profile_screen_Label: TLabel;
    Profile_screen: TMemo;
    Profile_trigger_Row: TLayout;
    Profile_trigger_Label: TLabel;
    Profile_trigger: TMemo;
    Profile_purpose_Row: TLayout;
    Profile_purpose_Label: TLabel;
    Profile_purpose: TMemo;
    Profile_preconditions_Row: TLayout;
    Profile_preconditions_Label: TLabel;
    Profile_preconditions: TMemo;
    Profile_steps_Row: TLayout;
    Profile_steps_Label: TLabel;
    Profile_steps: TMemo;
    Profile_outcome_Row: TLayout;
    Profile_outcome_Label: TLabel;
    Profile_outcome: TMemo;
    Profile_evidence_Row: TLayout;
    Profile_evidence_Label: TLabel;
    Profile_evidence: TMemo;
    Profile_exceptions_Row: TLayout;
    Profile_exceptions_Label: TLabel;
    Profile_exceptions: TMemo;
    procedure ApplyProfileClick(Sender: TObject);
  public
    procedure LoadRecord(ARecord: TJSONObject; const AAuthor: string);
    function RecordJSON: TJSONObject;
  end;
implementation
uses DPH.Knowledge.ActionPurpose;
{$R *.fmx}
procedure TDPHActionPurposeForm.LoadRecord(ARecord: TJSONObject; const AAuthor: string);
var I: Integer; Fields: TJSONObject;
begin
  ProfileAuthorEdit.Text:=AAuthor; Fields:=nil;
  if ARecord<>nil then ARecord.TryGetValue<TJSONObject>('fields',Fields);
  for I:=0 to High(DPHActionPurposeKeys) do begin
    (FindComponent('Profile_'+DPHActionPurposeKeys[I]) as TMemo).Text:='';
    if Fields<>nil then (FindComponent('Profile_'+DPHActionPurposeKeys[I]) as TMemo).Text:=Fields.GetValue<string>(DPHActionPurposeKeys[I],'');
  end;
end;
function TDPHActionPurposeForm.RecordJSON: TJSONObject;
var I: Integer; Fields: TJSONObject;
begin
  Result:=TJSONObject.Create; Result.AddPair('record_type','action_purpose'); Fields:=TJSONObject.Create; Result.AddPair('fields',Fields);
  for I:=0 to High(DPHActionPurposeKeys) do Fields.AddPair(DPHActionPurposeKeys[I],(FindComponent('Profile_'+DPHActionPurposeKeys[I]) as TMemo).Text);
end;
procedure TDPHActionPurposeForm.ApplyProfileClick(Sender: TObject);
var RecordValue: TJSONObject;
begin
  RecordValue:=RecordJSON;
  try
    try
      TDPHActionPurpose.Validate(RecordValue);
      if ProfileAuthorEdit.Text.Trim='' then raise EArgumentException.Create('Enter a named contributor');
      ModalResult:=mrOk;
    except on E: Exception do ProfilePurpose.Text:=E.Message; end;
  finally RecordValue.Free; end;
end;
end.
