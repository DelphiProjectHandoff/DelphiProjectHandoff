program DelphiProjectHandoff;

uses
  System.StartUpCopy,
  FMX.Forms,
  DPH.UI.Main in 'DPH.UI.Main.pas' {DPHMainForm},
  DPH.Storage.Types in 'DPH.Storage.Types.pas',
  DPH.Storage.Database in 'DPH.Storage.Database.pas',
  DPH.Parse.Model in 'DPH.Parse.Model.pas',
  DPH.Project.Source in 'DPH.Project.Source.pas',
  DPH.Parse.Lexer in 'DPH.Parse.Lexer.pas',
  DPH.Parse.Preprocessor in 'DPH.Parse.Preprocessor.pas',
  DPH.Parse.Pascal in 'DPH.Parse.Pascal.pas',
  DPH.Parse.Forms in 'DPH.Parse.Forms.pas',
  DPH.Project.Inventory in 'DPH.Project.Inventory.pas',
  DPH.Project.Analysis in 'DPH.Project.Analysis.pas';

begin
  Application.Initialize;
  Application.CreateForm(TDPHMainForm, DPHMainForm);
  Application.Run;
end.
