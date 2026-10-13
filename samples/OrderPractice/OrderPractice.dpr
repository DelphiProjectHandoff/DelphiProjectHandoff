program OrderPractice;
uses FMX.Forms, OrderForm in 'OrderForm.pas' {PracticeOrderForm};
begin
  Application.Initialize;
  Application.CreateForm(TPracticeOrderForm, PracticeOrderForm);
  Application.Run;
end.
