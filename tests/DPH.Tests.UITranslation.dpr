program DPH.Tests.UITranslation;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.JSON,
  System.Diagnostics,
  System.RegularExpressions,
  System.Generics.Collections,
  DAT.Runtime.LanguagePack,
  DAT.Runtime.Manager,
  DPH.Handoff.Dossier;

var
  Languages: TObjectList<TLanguagePackDescriptor>;
  Descriptor: TLanguagePackDescriptor;
  LayoutRule: TRuntimeLayoutRule;
  SourcePair: TPair<string,string>;
  MissingText: TStringList;
  Runtime: TTranslationRuntime;
  EnglishPack,EnglishStrings,AuditFacts,PopulatedFacts: TJSONObject;
  PackDirectory, PreferencePath, Caption, TitleText, TitleSource, Html, HelpText,
    PercentPattern, DossierSource, RawHtml: string;
  DossierMatch: TMatch;
  Count, SafePaneRuleCount, DossierPage, AuditVariant: Integer;
  PreferenceID: TGUID;
  HtmlTimer: TStopwatch;
begin
  try
    if ParamCount <> 1 then
      raise Exception.Create('Pass the Localization\Languages directory.');
    PackDirectory := TPath.GetFullPath(ParamStr(1));
    DossierSource := TFile.ReadAllText(TPath.Combine(
      TPath.GetDirectoryName(TPath.GetDirectoryName(PackDirectory)),
      'DPH.Handoff.Dossier.pas'), TEncoding.UTF8);
    EnglishPack := TJSONObject.ParseJSONValue(TFile.ReadAllText(
      TPath.Combine(PackDirectory,'en-US.json'),TEncoding.UTF8)) as TJSONObject;
    EnglishStrings := EnglishPack.GetValue<TJSONObject>('strings');
    AuditFacts := TJSONObject.Create;
    AuditFacts.AddPair('project','audit.dproj');
    PopulatedFacts := TJSONObject.ParseJSONValue(
      '{"project":"audit.dproj","files":[{"path":"XFile.pas"}],'+
      '"symbols":[{"key":"X1","name":"XObject","kind":"variable",'+
      '"type":"XType"}],"relationships":[{"kind":"binds",'+
      '"from":"X1","to":"X1"},{"kind":"output_candidate",'+
      '"from":"X1","to":"X1"},{"kind":"static_sql",'+
      '"from":"X1","to":"X1"},{"kind":"dynamic_sql",'+
      '"from":"X1","to":"X1"}],'+
      '"project_screens":[{"name":"XForm","source":"XForm.fmx",'+
      '"line":1}],"project_startup_forms":[{"instance":"XForm",'+
      '"class":"XClass","program":"XProgram","line":1}],'+
      '"author_questions":[{"title":"XQuestion","prompt":"XPrompt"}],'+
      '"diagnostics":[{"code":"XDiagnostic","message":"XMessage"}]}'
      ) as TJSONObject;
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
          for SourcePair in Runtime.ActivePack.SourceStrings do
            if SourcePair.Value.Contains('[[S') or
              SourcePair.Value.Contains(#$00AD) then
              raise Exception.Create('Leaked marker or soft hyphen in ' +
                Descriptor.LanguageCode + ': ' + SourcePair.Key);
          for SourcePair in Runtime.ActivePack.Strings do
            if SourcePair.Value.Contains('[[S') or
              SourcePair.Value.Contains(#$00AD) then
              raise Exception.Create('Leaked marker or soft hyphen in form text for ' +
                Descriptor.LanguageCode + ': ' + SourcePair.Key);
          for TitleSource in ['PromptLabel','DetailLabel','YesButton',
            'NoButton','CancelButton'] do
            if not Runtime.ActivePack.TryGetText(
              'DPHSavePromptForm.' + TitleSource + '.Text', HelpText) or
              (HelpText = '') then
              raise Exception.Create('Missing localized save confirmation in ' +
                Descriptor.LanguageCode + ': ' + TitleSource);
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
            for TitleSource in [
              'Project preparation stopped. Read the status message for details.',
              'Project saved to:',
              'Project was not saved.',
              'Save this unsaved project before closing?',
              'Save this unsaved project before opening another?',
              'Yes saves a project database. No discards this temporary capture. Cancel keeps it open.'] do
              if Runtime.TranslateDynamicText(TitleSource) = TitleSource then
                raise Exception.Create('Untranslated dialog text in ' +
                  Descriptor.LanguageCode + ': ' + TitleSource);
            for TitleSource in [
              'DPHMainForm.StatusLabel.Text',
              'DPHMainForm.InspectorPurpose.Text',
              'DPHMainForm.InspectorMemo.Lines.Strings.2',
              'DPHMainForm.SetupPurpose.Text',
              'DPHMainForm.HelpFallback.Lines.Strings.0',
              'DPHMainForm.HelpFallback.Lines.Strings.4',
              'DPHMainForm.PublishPurpose.Text',
              'DPHMainForm.PublishButton.Text',
              'DPHMainForm.PreviewButton.Text'] do
              if Runtime.Translate(TitleSource,
                EnglishStrings.Values[TitleSource].Value) =
                EnglishStrings.Values[TitleSource].Value then
                raise Exception.Create('Untranslated interface guidance in ' +
                  Descriptor.LanguageCode + ': ' + TitleSource);
            for TitleSource in [
              'DPHMainForm.HelpFallback.Lines.Strings.0',
              'DPHMainForm.HelpFallback.Lines.Strings.2',
              'DPHMainForm.HelpFallback.Lines.Strings.3',
              'DPHMainForm.HelpFallback.Lines.Strings.4',
              'DPHMainForm.HelpFallback.Lines.Strings.5',
              'DPHMainForm.HelpFallback.Lines.Strings.6',
              'DPHMainForm.HelpFallback.Lines.Strings.8',
              'DPHMainForm.HelpFallback.Lines.Strings.10'] do
              if Runtime.Translate(TitleSource,
                EnglishStrings.Values[TitleSource].Value) =
                EnglishStrings.Values[TitleSource].Value then
                raise Exception.Create('Getting-started text remains English in ' +
                  Descriptor.LanguageCode + ': ' + TitleSource);
            for TitleSource in [
              'Welcome to Delphi Project Handoff',
              'Open the application project',
              'Handoff dossier',
              'Coverage',
              'Some explanations need checking. Ask about unexplained behavior before relying on it.',
              'STALE evidence',
              'Captured analysis complete',
              'Coverage and gaps: separate static capture measures, human review and diagnostics. Select a diagnostic and click Inspect selected gap to read evidence and open matching source.',
              'Refresh the lessons after the source changes and check affected explanations.',
              'A true result follows one branch and a false result follows the other. Conditions found in this operation:',
              'Declared here:',
              'Inspect the saved form design',
              'Inspect the source walkthrough for branch order and other paths.',
              'Optional: read the code walkthrough and source details',
              'This source unit contains the declarations and operations listed in its connections below.',
              'Saved capture needs source refresh',
              'Project analysis is incomplete',
              'Source-derived, unreviewed',
              'captured',
              'Static inspection only; the selected application was not run.',
              'DPH saved what it found, but some results may be missing. Open Coverage, select a diagnostic, and choose Inspect selected gap to see the affected source. If a file, path, or project setting is missing, correct it and choose Rescan project.',
              'What this application is for',
              'What the captured source shows',
              'Visible commands and connected handlers',
              'Data and output evidence',
              'Questions to resolve',
              'Analysis gaps and risk candidates',
              'Dependencies and build paths',
              'Database connections and bindings',
              'Normal sequence / handoff',
              'Select for full step details; orange routes are exceptions'] do
            begin
              if Runtime.TranslateDynamicText(TitleSource) = TitleSource then
                raise Exception.Create('Interface prose lacks a complete translation in ' +
                  Descriptor.LanguageCode + ': ' + TitleSource);
              Html := Runtime.TranslateHtmlText('<p>' + TitleSource + '</p>');
              if Pos('>' + TitleSource + '<', Html) > 0 then
                raise Exception.Create('HTML retained English interface prose in ' +
                  Descriptor.LanguageCode + ': ' + TitleSource);
            end;
            for DossierMatch in TRegEx.Matches(DossierSource,
              '>([A-Za-z][^<>''\r\n]{5,})<') do
            begin
              TitleSource := Trim(DossierMatch.Groups[1].Value);
              if not TRegEx.IsMatch(TitleSource,
                '^[A-Za-z][A-Za-z0-9 ,.;:/?()\-]+$') then Continue;
              Html := Runtime.TranslateHtmlText('<p>' + TitleSource + '</p>');
              if Pos('>' + TitleSource + '<', Html) > 0 then
                raise Exception.Create('Dossier HTML retained English interface text in ' +
                  Descriptor.LanguageCode + ': ' + TitleSource);
            end;
            MissingText := TStringList.Create;
            try
            for AuditVariant := 0 to 1 do
            for DossierPage := 0 to 3 do
            begin
              if AuditVariant=0 then
                RawHtml := TDPHHandoffDossier.Render(AuditFacts,DossierPage)
              else
                RawHtml := TDPHHandoffDossier.Render(PopulatedFacts,DossierPage);
              RawHtml := TRegEx.Replace(RawHtml,'<pre[^>]*>.*?</pre>','',
                [roIgnoreCase,roSingleLine]);
              for DossierMatch in TRegEx.Matches(RawHtml,'>([^<>]+)<') do
              begin
                TitleSource := Trim(DossierMatch.Groups[1].Value);
                if (TitleSource = 'audit.dproj') or
                  TitleSource.Contains('&mdash;') or
                  (Pos('X',TitleSource) > 0) or
                  (Pos('{',TitleSource) > 0) or
                  not TRegEx.IsMatch(TitleSource,'[A-Za-z]{3}') then Continue;
                Html := Runtime.TranslateHtmlText('<p>' + TitleSource + '</p>');
                if Pos('>' + TitleSource + '<', Html) > 0 then
                  MissingText.Add(TitleSource);
              end;
            end;
            if MissingText.Count > 0 then
              raise Exception.Create('Rendered dossier retains English in ' +
                Descriptor.LanguageCode + ': ' + MissingText.Text);
            finally
              MissingText.Free;
            end;
            HelpText := Runtime.Translate('DPHMainForm.LearnerTabLabel1.Text',
              'Handoff dossier');
            if (HelpText = '') or (HelpText = 'Handoff dossier') then
              raise Exception.Create('Untranslated handoff navigation in ' +
                Descriptor.LanguageCode);
            for TitleSource in ['Handoff overview', 'Commands and workflows',
              'Data and operations', 'Risks and open questions'] do
            begin
              Html := Runtime.TranslateHtmlText('<p>' + TitleSource + '</p>');
              if Pos('>' + TitleSource + '<', Html) > 0 then
                raise Exception.Create('Untranslated handoff page title in ' +
                  Descriptor.LanguageCode + ': ' + TitleSource);
            end;
            Html := Runtime.TranslateHtmlText(
              '<p>Handoff dossier</p><p>reads</p><p>writes</p>');
            if (Pos('>Handoff dossier<', Html) > 0) or
              (Pos('>reads<', Html) > 0) or (Pos('>writes<', Html) > 0) then
              raise Exception.Create('Mixed handoff or relationship labels in ' +
                Descriptor.LanguageCode);
            Html := Runtime.TranslateHtmlText(
              '<html lang="en"><head></head><body><p>reads</p></body></html>');
            if Pos('lang="' + Descriptor.LanguageCode + '"', Html) = 0 then
              raise Exception.Create('Translated HTML retains English language metadata in ' +
                Descriptor.LanguageCode);
            HelpText := Runtime.TranslateDynamicText(
              'Formatted view unavailable; captured content is shown.');
            if HelpText = 'Formatted view unavailable; captured content is shown.' then
              raise Exception.Create('Untranslated formatted-document fallback in ' +
                Descriptor.LanguageCode);
            HelpText := Runtime.Translate('DPHMainForm.ScreenZoomLabel.Text',
              'Zoom 100%');
            PercentPattern := '[%' + #$066A + ']';
            if TRegEx.IsMatch(HelpText,PercentPattern+'\S+') then
              Html := TRegEx.Replace(HelpText,PercentPattern+'\S+','%90')
            else
              Html := TRegEx.Replace(HelpText,'\S+\s*'+PercentPattern,'90%');
            if (Html = HelpText) or
              ((Pos('90%',Html)=0) and (Pos('%90',Html)=0)) then
              raise Exception.Create('Translated screen zoom cannot update in ' +
                Descriptor.LanguageCode);
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
        Runtime.LoadLanguage('de-DE');
        if Runtime.TranslateDynamicText(
          'Save this unsaved project before closing?').StartsWith('Save this') or
          Runtime.TranslateDynamicText(
          'Yes saves a project database. No discards this temporary capture. Cancel keeps it open.').StartsWith('Yes saves') or
          Runtime.TranslateDynamicText(
          'Reading local guides, help, notes, logs and referenced public websites...').StartsWith('Reading local guides') then
          raise Exception.Create('German save dialog or progress message remained partly English.');
        Html := Runtime.TranslateHtmlText(
          '<html lang="en"><body><p>This overview reached its display limit. It shows 120 boxes and 260 connections; additional connections may exist. To explore a smaller area, select an item in Project map and return here, or choose Types or Units in the grouping menu above.</p>' +
          '<article class="project-prose"><p>Bundled Interface Language Packs</p><strong>Mapping Packs</strong></article></body></html>');
        if Pos('Diese ', Html) = 0 then
          raise Exception.Create('German diagram notice with live counts was not translated as a whole sentence.');
        if (Pos('120 ', Html) = 0) or
          (Pos('260 Verbindungen', Html) = 0) or
          (Pos('Bundled Interface Language Packs', Html) = 0) or
          (Pos('>Mapping Packs</strong>', Html) = 0) then
          raise Exception.Create('German count placement or original project document text changed.');
        Runtime.LoadLanguage('fr-FR');
        Runtime.LoadLanguage('pt-BR');
        HtmlTimer := TStopwatch.StartNew;
        Html := Runtime.TranslateHtmlText('<html lang="en"><body><p>' +
          StringOfChar('x',500000) + '</p><p>reads</p></body></html>');
        HtmlTimer.Stop;
        if (HtmlTimer.ElapsedMilliseconds > 15000) or
          (Pos('lang="pt-BR"',Html)=0) or
          (Pos('>reads<',Html)>0) then
          raise Exception.CreateFmt('Large Portuguese HTML translation failed or took %d ms.',
            [HtmlTimer.ElapsedMilliseconds]);
        Writeln('PASS: 500,000-character Portuguese HTML translation took ',
          HtmlTimer.ElapsedMilliseconds, ' ms.');
        if Pos(' &mdash; ',TDPHHandoffDossier.Render(PopulatedFacts,0))=0 then
          raise Exception.Create('Dossier em dash is not encoded safely.');
        Runtime.LoadLanguage('fr-FR');
        Writeln('PASS: ', Count,
          ' DPH language packs load; localized heading, French UI, and RTL mixed text verified.');
      finally
        Languages.Free;
      end;
    finally
      Runtime.Free;
      EnglishPack.Free;
      AuditFacts.Free;
      PopulatedFacts.Free;
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
