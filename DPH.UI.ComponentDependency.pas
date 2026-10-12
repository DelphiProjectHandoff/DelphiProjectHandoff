unit DPH.UI.ComponentDependency;
interface
uses System.Classes, System.SysUtils, System.JSON, System.UITypes, FMX.Types, FMX.Controls, FMX.Forms,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.Edit, FMX.Memo;
type
  TDPHComponentDependencyForm = class(TForm)
    ProfilePurpose,ProfileAuthorLabel: TLabel;
    ProfileToolbar: TLayout;
    ProfileAuthorEdit: TEdit;
    ApplyProfileButton,CancelProfileButton: TButton;
    ProfileScroll: TVertScrollBox;
    Profile_class_name_Row: TLayout;
    Profile_class_name_Label: TLabel;
    Profile_class_name: TMemo;
    Profile_unit_name_Row: TLayout;
    Profile_unit_name_Label: TLabel;
    Profile_unit_name: TMemo;
    Profile_package_name_Row: TLayout;
    Profile_package_name_Label: TLabel;
    Profile_package_name: TMemo;
    Profile_vendor_Row: TLayout;
    Profile_vendor_Label: TLabel;
    Profile_vendor: TMemo;
    Profile_version_Row: TLayout;
    Profile_version_Label: TLabel;
    Profile_version: TMemo;
    Profile_support_Row: TLayout;
    Profile_support_Label: TLabel;
    Profile_support: TMemo;
    Profile_evidence_Row: TLayout;
    Profile_evidence_Label: TLabel;
    Profile_evidence: TMemo;
    procedure ApplyProfileClick(Sender: TObject);
  public
    procedure LoadRecord(ARecord: TJSONObject; const AAuthor: string);
    function RecordJSON: TJSONObject;
  end;
implementation
uses DPH.Knowledge.ComponentDependency;
{$R *.fmx}
procedure TDPHComponentDependencyForm.LoadRecord(ARecord: TJSONObject; const AAuthor: string);
var I: Integer; Fields: TJSONObject;
begin
  ProfileAuthorEdit.Text:=AAuthor; Fields:=nil;
  if ARecord<>nil then ARecord.TryGetValue<TJSONObject>('fields',Fields);
  for I:=0 to High(DPHComponentDependencyKeys) do begin
    (FindComponent('Profile_'+DPHComponentDependencyKeys[I]) as TMemo).Text:='';
    if Fields<>nil then (FindComponent('Profile_'+DPHComponentDependencyKeys[I]) as TMemo).Text:=Fields.GetValue<string>(DPHComponentDependencyKeys[I],'');
  end;
end;
function TDPHComponentDependencyForm.RecordJSON: TJSONObject;
var I: Integer; Fields: TJSONObject;
begin
  Result:=TJSONObject.Create; Result.AddPair('record_type','component_dependency'); Fields:=TJSONObject.Create; Result.AddPair('fields',Fields);
  for I:=0 to High(DPHComponentDependencyKeys) do Fields.AddPair(DPHComponentDependencyKeys[I],(FindComponent('Profile_'+DPHComponentDependencyKeys[I]) as TMemo).Text);
end;
procedure TDPHComponentDependencyForm.ApplyProfileClick(Sender: TObject);
var RecordValue: TJSONObject;
begin
  RecordValue:=RecordJSON;
  try
    try
      TDPHComponentDependency.Validate(RecordValue);
      if ProfileAuthorEdit.Text.Trim='' then raise EArgumentException.Create('Enter a named contributor');
      ModalResult:=mrOk;
    except on E: Exception do ProfilePurpose.Text:=E.Message; end;
  finally RecordValue.Free; end;
end;
end.
