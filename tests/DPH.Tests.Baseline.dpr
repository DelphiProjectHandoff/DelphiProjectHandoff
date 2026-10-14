program DPHBaselineTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.Diagnostics, FMX.Forms,
  DPH.UI.Main in '..\DPH.UI.Main.pas';

var
  BaselineForm: TDPHMainForm;
  Timer: TStopwatch;
  LanguageCode, ExpectedTitle, OriginalLanguage: string;
begin
  Application.Initialize;
  BaselineForm := TDPHMainForm.Create(nil);
  try
    if not Assigned(BaselineForm.BaselineLabel) then
      raise Exception.Create('FMX resource did not bind the baseline label');
    if BaselineForm.BaselineLabel.Owner <> BaselineForm then
      raise Exception.Create('FMX resource ownership is invalid');
    if not Assigned(BaselineForm.HeaderLogo) then
      raise Exception.Create('FMX resource did not bind the header logo');
    if BaselineForm.HeaderLogo.Bitmap.IsEmpty then
      raise Exception.Create('Header logo image is empty');
    OriginalLanguage := BaselineForm.DATLanguageManager.ActiveLanguage;
    try
      for LanguageCode in ['en-US', 'de-DE', 'ar-SA', 'de-DE'] do
      begin
        Timer := TStopwatch.StartNew;
        if not BaselineForm.DATLanguageManager.SelectLanguage(LanguageCode) then
          raise Exception.Create('Could not select ' + LanguageCode);
        Timer.Stop;
        ExpectedTitle := BaselineForm.DATLanguageManager.Translate(
          'DPHMainForm.BaselineLabel.Text', 'Delphi Project Handoff');
        if BaselineForm.BaselineLabel.Text <> ExpectedTitle then
          raise Exception.Create('Main heading did not switch to ' + LanguageCode);
        Writeln('Language switch ', LanguageCode, ': ', Timer.ElapsedMilliseconds,
          ' ms');
      end;
    finally
      if (OriginalLanguage <> '') and
        (OriginalLanguage <> BaselineForm.DATLanguageManager.ActiveLanguage) then
        BaselineForm.DATLanguageManager.SelectLanguage(OriginalLanguage);
    end;
    Writeln('PASS WP0-TEST: FMX resource, header logo, and component binding');
  finally
    BaselineForm.Free;
  end;
end.
