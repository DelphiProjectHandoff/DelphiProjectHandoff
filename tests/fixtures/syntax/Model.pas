unit Model;
interface
{$I Options.inc}
type
  TExample = class
  private
    FValue: Integer;
  public
    procedure Click;
    procedure SetValue(AValue: Integer); overload;
    procedure SetValue(AValue: string); overload;
    property Value: Integer read FValue write FValue;
  end;
implementation
{$R *.fmx}
procedure TExample.Click;
var I: Integer;
begin
  if FValue = 0 then FValue := 1 else FValue := 2;
  for I := 1 to 3 do FValue := FValue + I;
  while FValue < 10 do FValue := FValue + 1;
  repeat FValue := FValue - 1 until FValue = 0;
  try
    SetValue(1);
  finally
    FValue := 0;
  end;
end;
procedure TExample.SetValue(AValue: Integer);
begin FValue := AValue end;
procedure TExample.SetValue(AValue: string);
begin FValue := 0 end;
end.
