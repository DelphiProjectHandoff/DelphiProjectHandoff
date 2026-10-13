program DPH.Tests.OrderSample;
{$APPTYPE CONSOLE}
uses System.SysUtils,System.IOUtils,FMX.Forms,FMX.Graphics,Winapi.ActiveX,
 OrderForm in '..\samples\OrderPractice\OrderForm.pas';
var Form:TPracticeOrderForm;Bitmap:TBitmap;Root:string;
begin
 CoInitialize(nil);Application.Initialize;
 try
  try
   Root:=TPath.GetFullPath(ParamStr(1));Form:=TPracticeOrderForm.Create(nil);
   try
    Form.Show;Application.ProcessMessages;
    Form.CalculateClick(nil);
    if Form.ResultLabel.Text<>'Total: 20.00' then raise Exception.Create('Incorrect untaxed worked example');
    Writeln('PASS quantity 2 at price 10.00 gives 20.00 without tax');
    Bitmap:=TBitmap.Create(Form.ClientWidth,Form.ClientHeight);
    try if Bitmap.Canvas.BeginScene then try Form.PaintTo(Bitmap.Canvas);finally Bitmap.Canvas.EndScene;end;Bitmap.SaveToFile(TPath.Combine(Root,'samples\OrderPractice\practice-screen.png'));finally Bitmap.Free;end;
    Form.TaxCheck.IsChecked:=True;Form.CalculateClick(nil);
    if Form.ResultLabel.Text<>'Total: 22.00' then raise Exception.Create('Incorrect taxed worked example');
    Writeln('PASS tax option adds 2.00 for total 22.00');
    Bitmap:=TBitmap.Create(Form.ClientWidth,Form.ClientHeight);
    try if Bitmap.Canvas.BeginScene then try Form.PaintTo(Bitmap.Canvas);finally Bitmap.Canvas.EndScene;end;Bitmap.SaveToFile(TPath.Combine(Root,'samples\OrderPractice\practice-result.png'));finally Bitmap.Free;end;
    Form.QuantityEdit.Text:='3';Form.PriceEdit.Text:='5.00';Form.CalculateClick(nil);
    if Form.ResultLabel.Text<>'Total: 16.50' then raise Exception.Create('Incorrect practice answer');Writeln('PASS practice answer 3 at 5.00 with tax is 16.50');
    Form.QuantityEdit.Text:='4';Form.PriceEdit.Text:='2.50';Form.CalculateClick(nil);
    if Form.ResultLabel.Text<>'Total: 11.00' then raise Exception.Create('Incorrect final learning check');Writeln('PASS final learning check 4 at 2.50 with tax is 11.00');
    Form.Hide;
   finally Form.Free;end;
  except on E:Exception do begin Writeln(E.ClassName,': ',E.Message);ExitCode:=1;end;end;
 finally CoUninitialize;end;
end.
