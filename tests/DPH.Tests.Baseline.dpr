program DPHBaselineTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils, FMX.Forms,
  DPH.UI.Main in '..\DPH.UI.Main.pas';

var
  BaselineForm: TDPHMainForm;
begin
  Application.Initialize;
  BaselineForm := TDPHMainForm.Create(nil);
  try
    if not Assigned(BaselineForm.BaselineLabel) then
      raise Exception.Create('FMX resource did not bind the baseline label');
    if BaselineForm.BaselineLabel.Owner <> BaselineForm then
      raise Exception.Create('FMX resource ownership is invalid');
    Writeln('PASS WP0-TEST: FMX resource instantiation and component binding');
  finally
    BaselineForm.Free;
  end;
end.
