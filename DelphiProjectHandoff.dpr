program DelphiProjectHandoff;

uses
  System.StartUpCopy,
  FMX.Forms,
  DPH.UI.Main in 'DPH.UI.Main.pas' {DPHMainForm},
  DPH.Storage.Types in 'DPH.Storage.Types.pas',
  DPH.Storage.Database in 'DPH.Storage.Database.pas';

begin
  Application.Initialize;
  Application.CreateForm(TDPHMainForm, DPHMainForm);
  Application.Run;
end.
