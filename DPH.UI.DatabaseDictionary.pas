unit DPH.UI.DatabaseDictionary;
interface
uses System.Classes, System.SysUtils, System.JSON, System.UITypes, FMX.Types, FMX.Controls, FMX.Forms,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.Edit, FMX.Memo;
type
  TDPHDatabaseDictionaryForm = class(TForm)
    ProfilePurpose,ProfileAuthorLabel: TLabel;
    ProfileToolbar: TLayout;
    ProfileAuthorEdit: TEdit;
    ApplyProfileButton,CancelProfileButton: TButton;
    ProfileScroll: TVertScrollBox;
    Profile_dictionary_id_Row: TLayout;
    Profile_dictionary_id_Label: TLabel;
    Profile_dictionary_id: TMemo;
    Profile_schema_id_Row: TLayout;
    Profile_schema_id_Label: TLabel;
    Profile_schema_id: TMemo;
    Profile_source_Row: TLayout;
    Profile_source_Label: TLabel;
    Profile_source: TMemo;
    Profile_source_hash_Row: TLayout;
    Profile_source_hash_Label: TLabel;
    Profile_source_hash: TMemo;
    Profile_generation_Row: TLayout;
    Profile_generation_Label: TLabel;
    Profile_generation: TMemo;
    Profile_kind_Row: TLayout;
    Profile_kind_Label: TLabel;
    Profile_kind: TMemo;
    Profile_name_Row: TLayout;
    Profile_name_Label: TLabel;
    Profile_name: TMemo;
    Profile_table_Row: TLayout;
    Profile_table_Label: TLabel;
    Profile_table: TMemo;
    Profile_source_line_Row: TLayout;
    Profile_source_line_Label: TLabel;
    Profile_source_line: TMemo;
    Profile_definition_Row: TLayout;
    Profile_definition_Label: TLabel;
    Profile_definition: TMemo;
    Profile_business_owner_Row: TLayout;
    Profile_business_owner_Label: TLabel;
    Profile_business_owner: TMemo;
    Profile_sensitivity_Row: TLayout;
    Profile_sensitivity_Label: TLabel;
    Profile_sensitivity: TMemo;
    Profile_evidence_Row: TLayout;
    Profile_evidence_Label: TLabel;
    Profile_evidence: TMemo;
    Profile_usage_Row: TLayout;
    Profile_usage_Label: TLabel;
    Profile_usage: TMemo;
    procedure ApplyProfileClick(Sender: TObject);
  public
    procedure LoadRecord(ARecord: TJSONObject; const AAuthor: string);
    function RecordJSON: TJSONObject;
  end;
implementation
uses DPH.Workspace.DatabaseSchema;
{$R *.fmx}
procedure TDPHDatabaseDictionaryForm.LoadRecord(ARecord: TJSONObject; const AAuthor: string);
var I: Integer; Fields: TJSONObject;
begin
  ProfileAuthorEdit.Text:=AAuthor; Fields:=nil;
  if ARecord<>nil then ARecord.TryGetValue<TJSONObject>('fields',Fields);
  for I:=0 to High(DPHDictionaryKeys) do begin
    (FindComponent('Profile_'+DPHDictionaryKeys[I]) as TMemo).Text:='';
    if Fields<>nil then (FindComponent('Profile_'+DPHDictionaryKeys[I]) as TMemo).Text:=Fields.GetValue<string>(DPHDictionaryKeys[I],'');
  end;
end;
function TDPHDatabaseDictionaryForm.RecordJSON: TJSONObject;
var I: Integer; Fields: TJSONObject;
begin
  Result:=TJSONObject.Create; Result.AddPair('record_type','data_dictionary'); Fields:=TJSONObject.Create; Result.AddPair('fields',Fields);
  for I:=0 to High(DPHDictionaryKeys) do Fields.AddPair(DPHDictionaryKeys[I],(FindComponent('Profile_'+DPHDictionaryKeys[I]) as TMemo).Text);
end;
procedure TDPHDatabaseDictionaryForm.ApplyProfileClick(Sender: TObject);
var RecordValue: TJSONObject;
begin
  RecordValue:=RecordJSON;
  try
    try
      TDPHDatabaseSchema.ValidateDictionary(RecordValue);
      if ProfileAuthorEdit.Text.Trim='' then raise EArgumentException.Create('Enter a named contributor');
      ModalResult:=mrOk;
    except on E: Exception do ProfilePurpose.Text:=E.Message; end;
  finally RecordValue.Free; end;
end;
end.
