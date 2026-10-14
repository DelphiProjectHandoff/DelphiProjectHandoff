program DPH.Tests.UITranslation;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.Generics.Collections,
  DAT.Runtime.LanguagePack,
  DAT.Runtime.Manager;

var
  Languages: TObjectList<TLanguagePackDescriptor>;
  Descriptor: TLanguagePackDescriptor;
  Runtime: TTranslationRuntime;
  PackDirectory, PreferencePath, Caption, Html: string;
  Count: Integer;
  PreferenceID: TGUID;
begin
  try
    if ParamCount <> 1 then
      raise Exception.Create('Pass the Localization\Languages directory.');
    PackDirectory := TPath.GetFullPath(ParamStr(1));
    CreateGUID(PreferenceID);
    PreferencePath := TPath.Combine(TPath.GetTempPath,
      'DPH-translation-smoke-' + GUIDToString(PreferenceID) + '.ini');
    Runtime := TTranslationRuntime.Create('DelphiProjectHandoff',
      PackDirectory, PreferencePath, 'en-US', 'FireMonkey');
    try
      Languages := Runtime.AvailableLanguages;
      try
        if Languages.Count <> 35 then
          raise Exception.CreateFmt('Expected 35 languages; found %d.',
            [Languages.Count]);
        Count := 0;
        for Descriptor in Languages do
        begin
          if not Runtime.LoadLanguage(Descriptor.LanguageCode) then
            raise Exception.Create('Could not load ' + Descriptor.LanguageCode);
          Caption := Runtime.Translate('DPHMainForm.OpenProjectButton.Text',
            'Open application');
          if Caption = '' then
            raise Exception.Create('Empty application caption in ' +
              Descriptor.LanguageCode);
          if SameText(Descriptor.LanguageCode, 'fr-FR') then
          begin
            if Caption <> 'Ouvrir l''application' then
              raise Exception.Create('French selector caption is incorrect.');
            Html := Runtime.TranslateHtmlText(
              '<html lang="en"><body><p>Open application</p></body></html>');
            Html := StringReplace(Html, #$00AD, '', [rfReplaceAll]);
            if Pos('Ouvrir l''application', Html) = 0 then
              raise Exception.Create('French learning-page text was not translated.');
          end;
          if SameText(Descriptor.LanguageCode, 'ar-SA') and
            not SameText(Runtime.ActivePack.TextDirection, 'rtl') then
            raise Exception.Create('Arabic reading direction is not RTL.');
          Inc(Count);
        end;
        Runtime.LoadLanguage('fr-FR');
        Writeln('PASS: ', Count,
          ' DPH language packs load; French UI/HTML and Arabic RTL verified.');
      finally
        Languages.Free;
      end;
    finally
      Runtime.Free;
    end;
    Runtime := TTranslationRuntime.Create('DelphiProjectHandoff',
      PackDirectory, PreferencePath, 'en-US', 'FireMonkey');
    try
      if not Runtime.LoadPreferredLanguage or
        not SameText(Runtime.ActivePack.LanguageCode, 'fr-FR') then
        raise Exception.Create('Selected language was not remembered.');
      Writeln('PASS: language preference survives a new runtime instance.');
    finally
      Runtime.Free;
      if TFile.Exists(PreferencePath) then TFile.Delete(PreferencePath);
    end;
  except
    on E: Exception do
    begin
      Writeln('FAIL: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
