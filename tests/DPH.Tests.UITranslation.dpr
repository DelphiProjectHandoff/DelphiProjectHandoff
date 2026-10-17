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
  LayoutRule: TRuntimeLayoutRule;
  Runtime: TTranslationRuntime;
  PackDirectory, PreferencePath, Caption, TitleText, TitleSource, Html, HelpText: string;
  Count, SafePaneRuleCount: Integer;
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
          TitleText := Runtime.Translate('DPHMainForm.BaselineLabel.Text',
            'Delphi Project Handoff');
          if not Runtime.ActivePack.TryGetSource(
            'DPHMainForm.BaselineLabel.Text', TitleSource) or
            (TitleSource <> 'Delphi Project Handoff') then
            raise Exception.Create('Incorrect main heading source in ' +
              Descriptor.LanguageCode);
          if not SameText(Descriptor.LanguageCode, 'en-US') and
            (TitleText = 'Delphi Project Handoff') then
            raise Exception.Create('Untranslated main heading in ' +
              Descriptor.LanguageCode);
          if not SameText(Descriptor.LanguageCode, 'en-US') then
          begin
            HelpText := Runtime.Translate('DPHMainForm.RescanProjectButton.Text',
              'Rescan project');
            if (HelpText = '') or (HelpText = 'Rescan project') then
              raise Exception.Create('Untranslated Rescan project action in ' +
                Descriptor.LanguageCode);
            Html := Runtime.TranslateHtmlText(
              '<html lang="en"><body><p>Select Open application and choose a .dproj file. DPH reads project files.</p></body></html>');
            if Pos('Select Open application and choose a .dproj file. DPH reads project files.', Html) = 0 then
              raise Exception.Create('HTML translation mixed languages inside a sentence in ' +
                Descriptor.LanguageCode);
            HelpText := Runtime.Translate('DPHMainForm.SaveProjectButton.Text',
              'Save project');
            if (HelpText = '') or (HelpText = 'Save project') then
              raise Exception.Create('Untranslated Save project action in ' +
                Descriptor.LanguageCode);
            HelpText := Runtime.Translate('DPHProgressForm.ProgressHint.Text',
              'This may take a few minutes...');
            if (HelpText = '') or (HelpText = 'This may take a few minutes...') then
              raise Exception.Create('Untranslated progress guidance in ' +
                Descriptor.LanguageCode);
            HelpText := Runtime.Translate('DPHMainForm.ScreenshotHelp.Text',
              'DPH generates these blank screen views from the application''s .fmx and .dfm files. Select a form, then use Fit or Native pixels. Custom painting and runtime data may differ.');
            if HelpText.StartsWith('DPH generates these blank screen views') then
              raise Exception.Create('Untranslated generated-screen note in ' +
                Descriptor.LanguageCode);
            HelpText := Runtime.TranslateDynamicText(
              'Read this application' + #$2019 + 's own documents');
            if HelpText.StartsWith('Read this application') then
              raise Exception.Create('Untranslated built-in guide heading in ' +
                Descriptor.LanguageCode);
            HelpText := Runtime.Translate(
              'DPH.UI.Main.Runtime.ProjectPreparationMessage_Text.Text.694ee195977a631e',
              'Checking the selected application and its Delphi files...');
            if HelpText.StartsWith('Checking the selected application') then
              raise Exception.Create('Untranslated project status in ' +
                Descriptor.LanguageCode);
            if Runtime.TranslateDynamicText('Project files') = 'Project files' then
              raise Exception.Create('Untranslated file-list heading in ' +
                Descriptor.LanguageCode);
          end;
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
          if SameText(Runtime.ActivePack.TextDirection, 'rtl') then
          begin
            SafePaneRuleCount := 0;
            for LayoutRule in Runtime.ActivePack.LayoutRules do
              if SameText(LayoutRule.FormName, 'DPHMainForm') and
                SameText(LayoutRule.PropertyName, 'Align') then
              begin
                if ((LayoutRule.ComponentName = 'ExplorerLayout') or
                    (LayoutRule.ComponentName = 'ExplorerSplitter') or
                    (LayoutRule.ComponentName = 'CardList') or
                    (LayoutRule.ComponentName = 'TaskPicker') or
                    (LayoutRule.ComponentName = 'LearningTopics') or
                    (LayoutRule.ComponentName = 'ScreenshotList') or
                    (LayoutRule.ComponentName = 'DetailsList') or
                    (LayoutRule.ComponentName = 'LinkTargetsList')) and
                    SameText(LayoutRule.TranslatedValue, 'Left') then
                  Inc(SafePaneRuleCount);
                if ((LayoutRule.ComponentName = 'InspectorLayout') or
                    (LayoutRule.ComponentName = 'InspectorSplitter')) and
                    SameText(LayoutRule.TranslatedValue, 'Right') then
                  Inc(SafePaneRuleCount);
              end;
            if SafePaneRuleCount <> 10 then
              raise Exception.Create('RTL reading panes are not docked safely in ' +
                Descriptor.LanguageCode);
          end;
          if SameText(Descriptor.LanguageCode, 'ar-SA') then
          begin
            Caption := Runtime.ActivePack.FormatTemplate(
              'DPH.UI.Main.Runtime.StatusLabel_Text.Text.27b34e6d78564198',
              'Project information for %s is ready. Choose Learn the project to continue.',
              ['Carillon.dproj']);
            if Pos('Project information for', Caption) <> 0 then
              raise Exception.Create('Arabic project-ready status was not translated.');
            Html := Runtime.TranslateHtmlText(
              '<html lang="en"><body><p dir="auto"><code>Carillon.dproj</code> is explored through its starting screen, visible controls, connected actions and available help topics.</p><pre dir="auto" class="project-prose">Original English project documentation.</pre></body></html>');
            if Pos('dir="rtl"', Html) = 0 then
              raise Exception.Create('Arabic HTML root is not RTL.');
            if Pos('dir="auto"', Html) = 0 then
              raise Exception.Create('Project-content auto direction was removed.');
            if Pos('Original English project documentation.', Html) = 0 then
              raise Exception.Create('Original project content changed.');
            if Pos('is explored through its starting screen', Html) <> 0 then
              raise Exception.Create('Arabic generated introduction was not translated.');
            Html := Runtime.TranslateHtmlText(
              '<html lang="en"><body><h2>Screens <bdi>(9)</bdi></h2><p><a>Screenshots</a></p><li dir="auto"><a><code class="project-name">Clock</code></a></li></body></html>');
            if (Pos('>Screens <bdi>', Html) <> 0) or
              (Pos('>Clock</code>', Html) = 0) then
              raise Exception.Create('Arabic screen summary or original form name is incorrect.');
          end;
          Inc(Count);
        end;
        Runtime.LoadLanguage('fr-FR');
        Writeln('PASS: ', Count,
          ' DPH language packs load; localized heading, French UI, and RTL mixed text verified.');
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
