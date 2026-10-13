unit OrderForm;
interface
uses System.SysUtils, System.Classes, FMX.Forms, FMX.Types, FMX.Controls,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Edit, FMX.Dialogs;
type
  TPracticeOrderForm=class(TForm)
    Heading,QuantityLabel,PriceLabel,ResultLabel,InstructionLabel:TLabel;
    QuantityEdit,PriceEdit:TEdit;
    TaxCheck:TCheckBox;
    CalculateButton:TButton;
    procedure CalculateClick(Sender:TObject);
  end;
var PracticeOrderForm:TPracticeOrderForm;
implementation
{$R *.fmx}
procedure TPracticeOrderForm.CalculateClick(Sender:TObject);
var Quantity:Integer;UnitPrice,Subtotal,Tax,Total:Double;
begin
  // This deliberately small example teaches input, validation, a choice and a result.
  ResultLabel.Text:='Total: not calculated';
  if not TryStrToInt(QuantityEdit.Text,Quantity) or (Quantity<1) or (Quantity>1000) then begin
    ShowMessage('Enter a whole quantity from 1 to 1000.');Exit;
  end;
  if not TryStrToFloat(PriceEdit.Text,UnitPrice,TFormatSettings.Invariant) or (UnitPrice<0) or (UnitPrice>10000) then begin
    ShowMessage('Enter a price from 0 to 10000, using a decimal point.');Exit;
  end;
  Subtotal:=Quantity*UnitPrice;
  Tax:=0;
  if TaxCheck.IsChecked then Tax:=Subtotal*0.10;
  Total:=Subtotal+Tax;
  ResultLabel.Text:='Total: '+FormatFloat('0.00',Total,TFormatSettings.Invariant);
end;
end.
