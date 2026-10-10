program DelphiProjectHandoff;

uses
  System.StartUpCopy,
  FMX.Forms,
  DPH.UI.Main in 'DPH.UI.Main.pas' {DPHMainForm};

begin
  Application.Initialize;
  Application.CreateForm(TDPHMainForm, DPHMainForm);
  Application.Run;
end.
