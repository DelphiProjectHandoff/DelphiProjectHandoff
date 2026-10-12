unit DPH.UI.Glossary;
interface
uses System.Classes, System.SysUtils, System.JSON, System.UITypes, FMX.Types, FMX.Controls, FMX.Forms,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.Edit, FMX.Memo;
type
  TDPHGlossaryForm = class(TForm)
    GlossaryPurpose,TermLabel,AliasesLabel,DefinitionLabel,ExamplesLabel,ContextLabel,AuthorLabel: TLabel;
    GlossaryFields: TVertScrollBox;
    TermRow,AliasesRow,DefinitionRow,ExamplesRow,ContextRow,AuthorRow,GlossaryActions: TLayout;
    TermEdit,AuthorEdit: TEdit;
    AliasesMemo,DefinitionMemo,ExamplesMemo,ContextMemo: TMemo;
    ApplyTermButton,CancelTermButton: TButton;
    procedure ApplyTermClick(Sender: TObject);
  public
    procedure LoadRecord(ARecord: TJSONObject; const AAuthor: string);
    function RecordJSON: TJSONObject;
  end;
implementation
uses DPH.Knowledge.Glossary;
{$R *.fmx}
procedure TDPHGlossaryForm.LoadRecord(ARecord: TJSONObject; const AAuthor: string);
var Value: TJSONValue;
begin
  TermEdit.Text:=''; AliasesMemo.Text:=''; DefinitionMemo.Text:=''; ExamplesMemo.Text:=''; ContextMemo.Text:=''; AuthorEdit.Text:=AAuthor;
  if ARecord=nil then Exit;
  TDPHGlossary.Validate(ARecord);
  TermEdit.Text:=ARecord.GetValue<string>('term'); DefinitionMemo.Text:=ARecord.GetValue<string>('definition');
  ExamplesMemo.Text:=ARecord.GetValue<string>('examples',''); ContextMemo.Text:=ARecord.GetValue<string>('context');
  for Value in ARecord.GetValue<TJSONArray>('aliases') do AliasesMemo.Lines.Add(Value.Value);
end;
function TDPHGlossaryForm.RecordJSON: TJSONObject;
var Aliases: TJSONArray; Line: string;
begin
  Result:=TJSONObject.Create; Result.AddPair('record_type','business_glossary'); Result.AddPair('term',TermEdit.Text.Trim);
  Aliases:=TJSONArray.Create; Result.AddPair('aliases',Aliases);
  for Line in AliasesMemo.Lines do if Line.Trim<>'' then Aliases.Add(Line.Trim);
  Result.AddPair('definition',DefinitionMemo.Text.Trim); Result.AddPair('examples',ExamplesMemo.Text.Trim); Result.AddPair('context',ContextMemo.Text.Trim);
end;
procedure TDPHGlossaryForm.ApplyTermClick(Sender: TObject);
var RecordValue: TJSONObject;
begin
  RecordValue:=RecordJSON;
  try
    try
      TDPHGlossary.Validate(RecordValue);
      if AuthorEdit.Text.Trim='' then raise EArgumentException.Create('Enter a named contributor');
      GlossaryPurpose.Text:='Term fields are complete. Apply returns a draft to Knowledge; Save there, then explicitly review the saved revision.';
      ModalResult:=mrOk;
    except on E: Exception do GlossaryPurpose.Text:=E.Message; end;
  finally RecordValue.Free; end;
end;
end.
