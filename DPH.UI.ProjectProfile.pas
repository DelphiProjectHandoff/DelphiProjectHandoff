unit DPH.UI.ProjectProfile;
interface
uses System.Classes, System.SysUtils, System.JSON, System.UITypes, FMX.Types, FMX.Controls, FMX.Forms,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.Edit, FMX.Memo;
type
  TDPHProjectProfileForm = class(TForm)
    ProfilePurpose,ProfileAuthorLabel: TLabel;
    ProfileToolbar: TLayout;
    ProfileAuthorEdit: TEdit;
    ApplyProfileButton,CancelProfileButton: TButton;
    ProfileScroll: TVertScrollBox;
    Profile_purpose_Row: TLayout;
    Profile_purpose_Label: TLabel;
    Profile_purpose: TMemo;
    Profile_company_Row: TLayout;
    Profile_company_Label: TLabel;
    Profile_company: TMemo;
    Profile_department_Row: TLayout;
    Profile_department_Label: TLabel;
    Profile_department: TMemo;
    Profile_business_unit_Row: TLayout;
    Profile_business_unit_Label: TLabel;
    Profile_business_unit: TMemo;
    Profile_criticality_Row: TLayout;
    Profile_criticality_Label: TLabel;
    Profile_criticality: TMemo;
    Profile_owner_Row: TLayout;
    Profile_owner_Label: TLabel;
    Profile_owner: TMemo;
    Profile_support_Row: TLayout;
    Profile_support_Label: TLabel;
    Profile_support: TMemo;
    Profile_environments_Row: TLayout;
    Profile_environments_Label: TLabel;
    Profile_environments: TMemo;
    Profile_relationships_Row: TLayout;
    Profile_relationships_Label: TLabel;
    Profile_relationships: TMemo;
    Profile_lifecycle_Row: TLayout;
    Profile_lifecycle_Label: TLabel;
    Profile_lifecycle: TMemo;
    Profile_maturity_Row: TLayout;
    Profile_maturity_Label: TLabel;
    Profile_maturity: TMemo;
    Profile_vendor_Row: TLayout;
    Profile_vendor_Label: TLabel;
    Profile_vendor: TMemo;
    Profile_license_Row: TLayout;
    Profile_license_Label: TLabel;
    Profile_license: TMemo;
    Profile_architecture_Row: TLayout;
    Profile_architecture_Label: TLabel;
    Profile_architecture: TMemo;
    Profile_evidence_Row: TLayout;
    Profile_evidence_Label: TLabel;
    Profile_evidence: TMemo;
    procedure ApplyProfileClick(Sender: TObject);
  public
    procedure LoadRecord(ARecord: TJSONObject; const AAuthor: string);
    function RecordJSON: TJSONObject;
  end;
implementation
uses DPH.Knowledge.ProjectProfile;
{$R *.fmx}
procedure TDPHProjectProfileForm.LoadRecord(ARecord: TJSONObject; const AAuthor: string);
var I: Integer; Fields: TJSONObject;
begin
  ProfileAuthorEdit.Text:=AAuthor; Fields:=nil;
  if ARecord<>nil then ARecord.TryGetValue<TJSONObject>('fields',Fields);
  for I:=0 to DPHProjectProfileFieldCount-1 do begin
    (FindComponent('Profile_'+DPHProjectProfileKeys[I]) as TMemo).Text:='';
    if Fields<>nil then (FindComponent('Profile_'+DPHProjectProfileKeys[I]) as TMemo).Text:=Fields.GetValue<string>(DPHProjectProfileKeys[I],'');
  end;
end;
function TDPHProjectProfileForm.RecordJSON: TJSONObject;
var I: Integer; Fields: TJSONObject;
begin
  Result:=TJSONObject.Create; Result.AddPair('record_type','project_profile'); Fields:=TJSONObject.Create; Result.AddPair('fields',Fields);
  for I:=0 to DPHProjectProfileFieldCount-1 do Fields.AddPair(DPHProjectProfileKeys[I],(FindComponent('Profile_'+DPHProjectProfileKeys[I]) as TMemo).Text);
end;
procedure TDPHProjectProfileForm.ApplyProfileClick(Sender: TObject);
var RecordValue: TJSONObject;
begin
  RecordValue:=RecordJSON;
  try
    try
      TDPHProjectProfile.Validate(RecordValue);
      if ProfileAuthorEdit.Text.Trim='' then raise EArgumentException.Create('Enter a named contributor');
      ModalResult:=mrOk;
    except on E: Exception do ProfilePurpose.Text:=E.Message; end;
  finally RecordValue.Free; end;
end;
end.

