program DPH.Tests.Publishing;
{$APPTYPE CONSOLE}
uses System.SysUtils, System.StrUtils, System.IOUtils, System.JSON, System.Hash, System.Zip, Winapi.ActiveX,
  DPH.Publish.Model in '..\DPH.Publish.Model.pas',
  DPH.Publish.Export in '..\DPH.Publish.Export.pas',
  DPH.Publish.Translation in '..\DPH.Publish.Translation.pas',
  DPH.Publish.BrowserPolicy in '..\DPH.Publish.BrowserPolicy.pas',
  DPH.Workspace.Model in '..\DPH.Workspace.Model.pas',
  DPH.Project.Analysis in '..\DPH.Project.Analysis.pas',
  DPH.Analysis.Model in '..\DPH.Analysis.Model.pas',
  DPH.Analysis.Symbols in '..\DPH.Analysis.Symbols.pas',
  DPH.Analysis.Persistence in '..\DPH.Analysis.Persistence.pas',
  DPH.Storage.Database in '..\DPH.Storage.Database.pas',
  DPH.Knowledge.ProjectProfile in '..\DPH.Knowledge.ProjectProfile.pas';
type TMockTranslator = class(TInterfacedObject,IDPHTranslationProvider)
  function ID: string; function Version: string; function External: Boolean;
  function TranslateProse(const AText,ASourceLocale,ATargetLocale: string): string;
end;
function TMockTranslator.ID: string; begin Result:='offline-test'; end;
function TMockTranslator.Version: string; begin Result:='1'; end;
function TMockTranslator.External: Boolean; begin Result:=False; end;
function TMockTranslator.TranslateProse(const AText,ASourceLocale,ATargetLocale: string): string;
begin Result:=ATargetLocale+': '+AText; end;
var Root,Work,Fixture,Path,Key,Text,CacheKey: string; IDValue: TGUID; Checks: Integer;
    Analyzer: TDPHAnalyzer; Semantic: TDPHSemanticAnalyzer; Scan: TDPHScan; Graph: TDPHSemanticGraph;
    Store: TDPHKnowledgeStore; Config,Generation,TranslationNote,TranslationRevision: Int64; View: TDPHWorkspaceView; Model,Task,Again: TDPHDocumentModel;
    Knowledge,Rows,RichLinks: TJSONArray; J: TJSONObject; V: TJSONValue; Failed: Boolean;
    Cache: TDPHTranslationCache; Provider: IDPHTranslationProvider; Segments: TArray<TDPHTranslationSegment>;
    Archive: TZipFile; Bytes,CapturedMainBytes: TBytes;
procedure Check(OK: Boolean; const MessageText: string);
begin if not OK then raise Exception.Create('FAIL '+MessageText); Inc(Checks); Writeln('PASS ',Checks,': ',MessageText); end;
begin
  CoInitialize(nil);
  try
    Root:=TPath.GetFullPath(ParamStr(1)); CreateGUID(IDValue); Work:=TPath.Combine(Root,'bin\wp6-tests-'+GUIDToString(IDValue)); Fixture:=TPath.Combine(Work,'fixture'); TDirectory.CreateDirectory(Fixture);
    Check(TDPHBrowserPolicy.Allowed('about:blank',Work),'Preview permits its blank startup page');
    Check(TDPHBrowserPolicy.Allowed('file://'+TPath.Combine(Work,StringOfChar('a',64)+'.html'),Work,False,True),
      'App preview permits content-hashed page in its owned preview directory');
    Check(not TDPHBrowserPolicy.Allowed('file://'+TPath.Combine(Work,'other.html'),Work,False,True),
      'Hashed preview policy rejects arbitrary local page names');
    Check(TDPHBrowserPolicy.Allowed('file:///'+Work.Replace('\','/')+'/index.html#overview',Work),'Preview permits only its local index and internal anchors');
    Check(not TDPHBrowserPolicy.Allowed('https://example.com',Work),'Preview rejects external navigation');
    Check(not TDPHBrowserPolicy.Allowed('file:///'+Fixture.Replace('\','/')+'/index.html',Work),'Preview rejects unrelated local files');
    Check(not TDPHBrowserPolicy.Allowed('file:///'+Work.Replace('\','/')+'/%2e%2e/index.html',Work),'Preview rejects encoded traversal');
    Check(not TDPHBrowserPolicy.Allowed('javascript:alert(1)',Work),'Preview rejects script navigation');
    Check(TDPHBrowserPolicy.Allowed('file:///'+Work.Replace('\','/')+'/learning.html#lesson_11',Work,True),'Publication preview permits its owned learning entry and lesson anchors');
    Check(not TDPHBrowserPolicy.Allowed('file:///'+Work.Replace('\','/')+'/arbitrary.html',Work,True),'Adding the learning entry does not permit arbitrary local HTML');
    Check(not ContainsText(TDPHDocumentModel.Redact('password := ''two word secret'';'),'two word'),'Pascal quoted credential assignments are fully redacted');
    Check(not ContainsText(TDPHDocumentModel.Redact('Authorization: Bearer abcdefghijklmnop'),'abcdefghijklmnop'),'Bearer authorization tokens are redacted');
    Check(not ContainsText(TDPHDocumentModel.Redact('{"password":"quoted secret words"}'),'quoted secret'),'JSON credential text is redacted');
    for Path in TDirectory.GetFiles(TPath.Combine(Root,'tests\fixtures\semantics')) do TFile.Copy(Path,TPath.Combine(Fixture,ExtractFileName(Path)));
    TFile.AppendAllText(TPath.Combine(Fixture,'Main.pas'),sLineBreak+'// password=SOURCE_SECRET_FOR_REDACTION'+sLineBreak,TEncoding.UTF8);
    Analyzer:=TDPHAnalyzer.Create; Semantic:=TDPHSemanticAnalyzer.Create;
    Store:=TDPHKnowledgeStore.Create(TPath.Combine(Work,'publish.dphdb'),Fixture,TPath.Combine(Root,'migrations'));
    try
      Store.InitializeProject('Publish fixture','Delphi'); Config:=Store.AddConfiguration('Win32','37.0','[]','[]','Debug'); Store.SelectConfiguration(Config);
      Scan:=Analyzer.Scan(TPath.Combine(Fixture,'Semantic.dproj'),'Debug','Win32',[],[],False);
      try Graph:=Semantic.Analyze(Scan);
        try Generation:=TDPHSemanticPersistence.Stage(Scan,Graph,Store,Config); TDPHSemanticPersistence.Publish(Scan,Graph,Store,Generation);
          View:=TDPHWorkspaceView.Create(TDPHWorkspaceView.Capture(Scan,Graph,Generation,'Semantic.dproj','Debug','Win32',[],[]));
          TFile.WriteAllText(TPath.Combine(Work,'workspace.json'),View.Document.Format(2),TEncoding.UTF8);
        finally Graph.Free; end;
      finally Scan.Free; end;
      try
        Rows:=View.Search('Click','routine',''); try Check(Rows.Count>0,'Captured fixture has its click routine'); Key:=(Rows.Items[0] as TJSONObject).GetValue<string>('key'); finally Rows.Free; end;
        RichLinks:=TJSONArray.Create;
        try
          Rows:=Store.LinkCandidates(Generation,'entity','Main.TMain.Click');
          try J:=Rows.Items[0].Clone as TJSONObject; J.AddPair('link_role','explains'); RichLinks.AddElement(J); finally Rows.Free; end;
          Rows:=Store.LinkCandidates(Generation,'relationship','Main.TMain.Click');
          try J:=nil; for V in Rows do if (V.GetValue<string>('canonical_key')=Key) and V.GetValue<string>('label').Contains('Worker.PublicWork') then begin J:=V.Clone as TJSONObject; Break; end;
            Check(J<>nil,'Publication fixture has a relationship to the excluded worker unit');
            J.AddPair('link_role','cites'); RichLinks.AddElement(J); finally Rows.Free; end;
          Store.SaveKnowledge(0,0,Generation,'Untrusted author text','<script>alert(1)</script> file://C:/private password=DO_NOT_EXPORT','Test Author','user_help',Key,'user','user',RichLinks.ToJSON);
        finally RichLinks.Free; end;
        Knowledge:=Store.KnowledgeJSON;
        try Model:=TDPHDocumentModel.Create(View,Knowledge,[],['worker.pas'],False,False);
          try
            Check(Pos('DO_NOT_EXPORT',Model.Document.ToJSON)=0,'Credential assignment is redacted throughout canonical model');
            Check(Model.Document.GetValue<TJSONArray>('exclusions').Count=1,'Explicit source exclusion is recorded');
            Check(Model.Document.GetValue<TJSONArray>('author_questions').Count>0,'Canonical handoff includes evidence-derived unanswered author questions');
            Failed:=False; for V in Model.Document.GetValue<TJSONArray>('author_questions') do if V.GetValue<string>('range.source')='worker.pas' then Failed:=True;
            Check(not Failed,'Scoped author questions omit evidence from excluded source files');
            Check((Model.Document.GetValue<TJSONArray>('knowledge').Items[0].GetValue<TJSONArray>('rich_links').Count=1) and
              (Model.Document.GetValue<TJSONArray>('knowledge').Items[0].GetValue<Integer>('omitted_rich_links')=1),
              'Publication removes rich relationship links whose target unit is excluded');
            Check((Model.Document.GetValue<TJSONArray>('sections').Count=9) and
              (Model.Document.GetValue<TJSONArray>('sections').Items[0].GetValue<string>('section_version').Length=64),
              'Generated document sections have stable IDs and deterministic content versions');
            Check(Model.Document.GetValue<TJSONArray>('knowledge').Items[0].GetValue<string>('source_generation')=IntToStr(Generation),
              'Publication preserves authored section source generation');
            Again:=TDPHDocumentModel.Create(View,Knowledge,[],[],False,False,nil,False,'engineer');
            try
              Check(Again.Document.GetValue<TJSONArray>('knowledge').Count=0,'Engineering audience excludes user-only authored sections');
              Check((Again.Document.GetValue<TJSONArray>('sections').Count=4) and
                (Again.Document.GetValue<string>('audience')='engineer'),'Audience filter includes overview and engineering-role guides');
            finally Again.Free; end;
            for V in Model.Document.GetValue<TJSONArray>('symbols') do Check((V as TJSONObject).GetValue<string>('range.source')<>'worker.pas','Excluded file cannot leak through symbol index');
            TDPHPublisher.Export(Model,Store,TPath.Combine(Work,'full'));
            TDPHPublisher.Validate(TPath.Combine(Work,'full'),Model.Document.GetValue<string>('input_fingerprint'));
            Check(True,'Full handoff passes filename and SHA256 validation');
            Text:=TFile.ReadAllText(TPath.Combine(Work,'full\learning.html'),TEncoding.UTF8);
            Check(Text.Contains('id="lesson_11"') and Text.Contains('Delphi terms in plain language') and Text.Contains('Start here'),'Offline learning edition includes the full beginner topic route');
            Check(not Text.Contains('href="#s_') and Text.Contains('href="objects/'),'Learning links point directly to exported object explanations');
            Check(not Text.Contains('DO_NOT_EXPORT') and not Text.Contains('<script>alert(1)</script>'),'Learning edition uses the redacted model and escapes authored markup');
            Text:=TFile.ReadAllText(TPath.Combine(Work,'full\objects\'+THashSHA2.GetHashString(Key)+'.html'),TEncoding.UTF8);
            Check(Text.Contains('Understand this selection') and Text.Contains('<details class="card"><summary>Optional: read the code walkthrough'),'Exported object starts with the beginner explanation and keeps deeper details optional');
            Check(not Text.Contains('href="../index.html#s_') and Text.Contains('Return to learning topics'),'Exported object navigation stays on the learning route');
            Check(not TFile.Exists(TPath.Combine(Work,'full\AGENTS.md')),'Owner guardrails and generated agent instructions are excluded by default');
            J:=TJSONObject.ParseJSONValue(TFile.ReadAllText(TPath.Combine(Work,'full\source-navigation.json'),TEncoding.UTF8)) as TJSONObject;
            try Check(not J.GetValue<Boolean>('included') and (J.GetValue<TJSONArray>('files').Count=0),'Source browsing is excluded by default'); finally J.Free; end;
            for Path in ['project-summary.md','architecture.md','build-and-test.md','known-risks.md','decisions-and-unknowns.md'] do
              Check(TFile.Exists(TPath.Combine(Work,'full\'+Path)),'Handoff includes planned narrative '+Path);
            J:=TJSONObject.ParseJSONValue(TFile.ReadAllText(TPath.Combine(Work,'full\manifest.json'),TEncoding.UTF8)) as TJSONObject;
            try Check((J.GetValue<string>('project')='Semantic.dproj') and (J.GetValue<string>('analyzers.syntax')<>'') and
              (J.GetValue<TJSONArray>('included_sources').Count=Model.Document.GetValue<TJSONArray>('files').Count) and
              (J.GetValue<string>('required_toolchain.selected_project_build')='not_run'),
              'Manifest carries project, analyzer, source scope and honest required-toolchain status'); finally J.Free; end;
            Check(TFile.ReadAllText(TPath.Combine(Work,'full\indexes\configuration.jsonl'),TEncoding.UTF8).Contains('additional_defines'),
              'Configuration index describes the captured selection rather than duplicating the file inventory');
            Text:=TFile.ReadAllText(TPath.Combine(Work,'full\index.html'),TEncoding.UTF8);
            Check(Pos('<script>alert(1)</script>',Text)=0,'Authored markup is encoded rather than executed');
            Check(Pos('&lt;script&gt;',Text)>0,'Escaped author text remains inspectable');
            Check(Text.Contains('reviewer unassigned') and Text.Contains('last reviewed never') and Text.Contains('Section knowledge-'),
              'Authored HTML exposes exact section identity and missing named review');
            Check(Text.Contains('source_derived_static_unreviewed') and Text.Contains('last reviewed unknown'),
              'Generated HTML sections disclose their unreviewed state separately');
            Check(Text.Contains('Open linked target') and Text.Contains('knowledge_revision_'),
              'Offline guide contains target navigation and exact revision anchors');
            Check(Pos('connect-src ''none''',Text)>0,'Offline HTML blocks external connections');
            Check(Pos('class="notranslate"',Text)>0,'Code identifiers are protected from translation');
            Check(TFile.Exists(TPath.Combine(Work,'full\assets\translation-selector.js')),'Local bilingual language selector helper is included');
            Again:=TDPHDocumentModel.Create(View,Knowledge,[],['worker.pas'],False,False);
            try Check(Again.Document.ToJSON=Model.Document.ToJSON,'Canonical output is deterministic for fixed capture, scope and knowledge'); finally Again.Free; end;
            Task:=TDPHDocumentModel.Create(View,Knowledge,[Key],[],False,False);
            try Check(Task.Document.GetValue<string>('scope')='task','Task bundle records its technical scope'); Check(Task.Document.GetValue<TJSONArray>('symbols').Count<View.Document.GetValue<TJSONArray>('semantics.symbols').Count,'Task bundle selects incident context rather than a blind full-export truncation');
              TDPHPublisher.Export(Task,Store,TPath.Combine(Work,'task'));
              TDPHPublisher.Export(Task,Store,TPath.Combine(Work,'task-source'),False,True);
              TDPHPublisher.Validate(TPath.Combine(Work,'task-source'),Task.Document.GetValue<string>('input_fingerprint'));
              J:=TJSONObject.ParseJSONValue(TFile.ReadAllText(TPath.Combine(Work,'task-source\source-navigation.json'),TEncoding.UTF8)) as TJSONObject;
              try Failed:=False; for V in J.GetValue<TJSONArray>('files') do if V.GetValue<string>('artifact')<>'' then begin
                if V.GetValue<Integer>('rendered_line_count')<V.GetValue<Integer>('line_count') then Failed:=True;
                Check(V.GetValue<Boolean>('task_excerpts'),'Task source browsing is explicitly limited to cited noncontainer line excerpts');
              end;
              Check(Failed,'Task source browsing omits uncited source instead of disclosing every line of an included file');
              finally J.Free; end;
            finally Task.Free; end;
            TDPHPublisher.Export(Model,Store,TPath.Combine(Work,'agent-opt-in'),True);
            TDPHPublisher.Validate(TPath.Combine(Work,'agent-opt-in'),Model.Document.GetValue<string>('input_fingerprint'));
            Check(TFile.ReadAllText(TPath.Combine(Work,'agent-opt-in\AGENTS.md'),TEncoding.UTF8).Contains('grants no authority'),
              'Explicit agent-instruction opt-in produces bounded generated instructions and a valid disclosed manifest');
            TDPHPublisher.Export(Model,Store,TPath.Combine(Work,'source-opt-in'),False,True);
            TDPHPublisher.Validate(TPath.Combine(Work,'source-opt-in'),Model.Document.GetValue<string>('input_fingerprint'));
            J:=TJSONObject.ParseJSONValue(TFile.ReadAllText(TPath.Combine(Work,'source-opt-in\source-navigation.json'),TEncoding.UTF8)) as TJSONObject;
            try
              Check(J.GetValue<Boolean>('included') and not J.GetValue<Boolean>('raw_source_snapshots') and (J.GetValue<Integer>('rendered_files')>0),
                'Explicit source browsing generates validated derived pages without copying original source bytes');
              Text:=''; for V in J.GetValue<TJSONArray>('files') do if V.GetValue<string>('source')='main.pas' then Text:=TFile.ReadAllText(TPath.Combine(Work,'source-opt-in\'+V.GetValue<string>('artifact')),TEncoding.UTF8);
              Check(Text.Contains('id="L1"') and Text.Contains('[REDACTED]') and not Text.Contains('SOURCE_SECRET_FOR_REDACTION'),
                'Source pages preserve line anchors and redact recognized credential assignments');
              Failed:=False; for V in J.GetValue<TJSONArray>('files') do if V.GetValue<string>('source')='worker.pas' then Failed:=True;
              Check(not Failed,'Excluded source cannot leak through browsing pages');
            finally J.Free; end;
            Text:=TFile.ReadAllText(TPath.Combine(Work,'source-opt-in\objects\'+THashSHA2.GetHashString(Key)+'.html'),TEncoding.UTF8);
            Check(Text.Contains('Read captured redacted source at this line') and Text.Contains('#L'),
              'Object explanation links to its exact captured source line using a relative allowlisted route');
            if not StartsText(IncludeTrailingPathDelimiter(TPath.Combine(Root,'bin')),TPath.Combine(Work,'source-opt-in')) or
              not StartsText(IncludeTrailingPathDelimiter(TPath.Combine(Root,'bin')),TPath.Combine(Work,'source-relocated')) then raise Exception.Create('Fixture relocation escaped test output');
            TDirectory.Move(TPath.Combine(Work,'source-opt-in'),TPath.Combine(Work,'source-relocated'));
            TDPHPublisher.Validate(TPath.Combine(Work,'source-relocated'),Model.Document.GetValue<string>('input_fingerprint'));
            Check(True,'Redacted source navigation bundle validates after folder relocation');
            CapturedMainBytes:=TFile.ReadAllBytes(TPath.Combine(Fixture,'Main.pas'));
            TFile.AppendAllText(TPath.Combine(Fixture,'Main.pas'),sLineBreak+'// changed after capture',TEncoding.UTF8);
            Failed:=False; try TDPHPublisher.Export(Model,Store,TPath.Combine(Work,'source-changed'),False,True); except Failed:=True; end;
            Check(Failed,'Changed source is rejected before it can masquerade as the captured browsing revision');
            TFile.WriteAllBytes(TPath.Combine(Fixture,'Main.pas'),CapturedMainBytes);
            Failed:=False; try TDPHPublisher.Validate(TPath.Combine(Work,'full'),StringOfChar('0',64)); except Failed:=True; end; Check(Failed,'Changed input fingerprint rejects a stale bundle');
            Failed:=False; try TDPHPublisher.Export(Model,Store,TPath.Combine(Fixture,'forbidden')); except Failed:=True; end; Check(Failed,'Publishing cannot write into the analyzed source');
            Failed:=False; try TDPHPublisher.Export(Model,Store,TPath.Combine(Work,'full')); except Failed:=True; end; Check(Failed,'Publishing cannot overwrite an existing folder');
            Archive:=TZipFile.Create; try Archive.Open(TPath.Combine(Work,'full\Engineering_Guide.docx'),zmRead); Archive.Read('word/document.xml',Bytes); Text:=TEncoding.UTF8.GetString(Bytes); Check(Pos(' TOC ',Text)>0,'Editable engineering guide has a changeable TOC field'); Check(Pos('Last changed',Text)>0,'Guide title page records last changed identity'); finally Archive.Free; end;
            TFile.AppendAllText(TPath.Combine(Work,'full\indexes\symbols.jsonl'),'tamper',TEncoding.UTF8);
            Failed:=False; try TDPHPublisher.Validate(TPath.Combine(Work,'full'),Model.Document.GetValue<string>('input_fingerprint')); except Failed:=True; end; Check(Failed,'Modified artifact fails hash validation');
            TFile.WriteAllText(TPath.Combine(Root,'docs\wp6-canonical-fixture.json'),Model.Document.Format(2),TEncoding.UTF8);
          finally Model.Free; end;
          TranslationNote:=Store.SaveKnowledge(0,0,Generation,'Translation fixture','Run conversion','Translation author','note','','engineering','engineer');
          Rows:=Store.KnowledgeJSON;
          try TranslationRevision:=0; for V in Rows do if V.GetValue<Int64>('id')=TranslationNote then TranslationRevision:=V.GetValue<Int64>('revision'); finally Rows.Free; end;
          Store.ReviewKnowledge(TranslationNote,TranslationRevision,Generation,'Source reviewer','verified');
          Rows:=Store.KnowledgeJSON;
          try for V in Rows do if V.GetValue<Int64>('id')=TranslationNote then TranslationRevision:=V.GetValue<Int64>('revision'); finally Rows.Free; end;
          Provider:=TDPHAtlasAdapter.Create(TPath.Combine(Root,'samples\translation\DPH.fr.sample.json'));
          Check(not Provider.External and (Provider.ID='Atlas-DAT-offline'),'Selected Atlas DAT pack translates offline without a network provider');
          Cache:=TDPHTranslationCache.Create(Store);
          try
            Segments:=TDPHTranslationCache.SegmentsForText('Run conversion');
            J:=Cache.Translate(TranslationRevision,'en','fr',Segments,Provider);
            try CacheKey:=J.GetValue<string>('cache_key'); Check(J.GetValue<TJSONArray>('segments').Items[0].GetValue<string>('text')='Exécuter la conversion','Pinned DAT reader resolves exact source prose from a real pack'); finally J.Free; end;
            Cache.Review(CacheKey,'French reviewer');
            Rows:=Store.KnowledgeJSON;
            try Again:=TDPHDocumentModel.Create(View,Rows,[],['worker.pas'],False,False);
              try
                TDPHPublisher.Export(Again,Store,TPath.Combine(Work,'localized-review'),False,False,'fr');
                TDPHPublisher.Validate(TPath.Combine(Work,'localized-review'),Again.Document.GetValue<string>('input_fingerprint'));
                J:=TJSONObject.ParseJSONValue(TFile.ReadAllText(TPath.Combine(Work,'localized-review\localization.json'),TEncoding.UTF8)) as TJSONObject;
                try
                  Check((J.GetValue<Integer>('translated_sections')=1) and (J.GetValue<Integer>('source_fallback_sections')>0),
                    'Localized publication uses the reviewed current translation and reports untranslated source fallbacks');
                  Text:=TFile.ReadAllText(TPath.Combine(Work,'localized-review\'+J.GetValue<string>('html')),TEncoding.UTF8);
                  Check(Text.Contains('Exécuter la conversion') and Text.Contains('source-language fallbacks') and not Text.Contains('DO_NOT_EXPORT'),
                    'Localized HTML contains actual reviewed prose, explicit fallback scope and redacted source content');
                finally J.Free; end;
                Archive:=TZipFile.Create;
                try Archive.Open(TPath.Combine(Work,'localized-review\Localized_Sections.docx'),zmRead); Archive.Read('word/document.xml',Bytes);
                  Text:=TEncoding.UTF8.GetString(Bytes); Check(Text.Contains('Exécuter la conversion') and Text.Contains(' TOC '),
                    'Editable localized supplement shares the same translated body and retains its TOC field');
                finally Archive.Free; end;
              finally Again.Free; end;
            finally Rows.Free; end;
          finally Cache.Free; end;
          Store.Free; Store:=nil;
          Store:=TDPHKnowledgeStore.Create(TPath.Combine(Work,'publish.dphdb'),Fixture,TPath.Combine(Root,'migrations'));
          Cache:=TDPHTranslationCache.Create(Store);
          try
            J:=Cache.Translate(TranslationRevision,'en','fr',Segments,Provider);
            try Check((J.GetValue<string>('state')='verified') and (J.GetValue<string>('reviewer')='French reviewer'),'Translation and named approval survive cache reconstruction in SQLite'); finally J.Free; end;
            J:=Cache.Translate(TranslationRevision,'en','fr-CA',Segments,Provider);
            try Check(J.GetValue<Boolean>('locale_fallback') and (J.GetValue<string>('resolved_locale')='fr'),'Regional locale fallback records the actual base-language pack'); finally J.Free; end;
            Failed:=False;
            try J:=Cache.Translate(TranslationRevision,'en','fr',TDPHTranslationCache.SegmentsForText('Wrong source'),Provider); J.Free; except Failed:=True; end;
            Check(Failed,'Persistent cache rejects source text that differs from the saved authored revision');
            Store.SaveKnowledge(TranslationNote,TranslationRevision,Generation,'Translation fixture','Run preview','Translation author','note','','engineering','engineer');
            J:=Store.LoadTranslation(CacheKey);
            try Check(J.GetValue<string>('state')='needs_review','Editing source invalidates the saved translation review state'); finally J.Free; end;
            Failed:=False; try Store.ReviewTranslation(CacheKey,'French reviewer'); except Failed:=True; end;
            Check(Failed,'Historical translation cannot be approved as the current authored revision');
            Rows:=Store.KnowledgeJSON;
            try Again:=TDPHDocumentModel.Create(View,Rows,[],['worker.pas'],False,False);
              try TDPHPublisher.Export(Again,Store,TPath.Combine(Work,'localized-after-edit'),False,False,'fr');
                J:=TJSONObject.ParseJSONValue(TFile.ReadAllText(TPath.Combine(Work,'localized-after-edit\localization.json'),TEncoding.UTF8)) as TJSONObject;
                try Check(J.GetValue<Integer>('translated_sections')=0,'Source edit prevents obsolete reviewed translation from leaking into a new localized export'); finally J.Free; end;
              finally Again.Free; end;
            finally Rows.Free; end;
          finally Cache.Free; end;
          Cache:=TDPHTranslationCache.Create;
          try
            Segments:=TDPHTranslationCache.SegmentsForText('Missing phrase');
            J:=Cache.Translate(TranslationRevision,'en','fr',Segments,Provider);
            try CacheKey:=J.GetValue<string>('cache_key'); Check(J.GetValue<Integer>('source_fallback_count')=1,'Missing DAT phrase retains source and counts its fallback'); finally J.Free; end;
            Failed:=False; try Cache.Review(CacheKey,'French reviewer'); except Failed:=True; end; Check(Failed,'Missing localized prose cannot receive translation approval');
            Segments:=TDPHTranslationCache.SegmentsForText('Inspect captured evidence');
            J:=Cache.Translate(TranslationRevision,'en','fr',Segments,Provider,False,'{"Inspect captured evidence":"Examiner les éléments enregistrés"}');
            try CacheKey:=J.GetValue<string>('cache_key'); Check(J.GetValue<TJSONArray>('segments').Items[0].GetValue<string>('status')='terminology','Exact prose terminology supplies a missing pack entry'); finally J.Free; end;
            J:=Cache.Translate(TranslationRevision,'en','fr',Segments,Provider,False,'{"Inspect captured evidence":"Examiner les preuves"}');
            try Check((J.GetValue<string>('cache_key')<>CacheKey) and (J.GetValue<string>('state')='needs_review'),'Changed terminology invalidates the derived translation and approval'); finally J.Free; end;
            Segments:=TDPHTranslationCache.SegmentsForText('Run conversion'+sLineBreak+'```pascal'+sLineBreak+'TMain.Click;'+sLineBreak+'```'+sLineBreak+'SELECT id FROM items'+sLineBreak+'C:\project\Main.pas');
            Text:=''; for var Segment in Segments do Text:=Text+Segment.Text;
            Check(Text='Run conversion'+sLineBreak+'```pascal'+sLineBreak+'TMain.Click;'+sLineBreak+'```'+sLineBreak+'SELECT id FROM items'+sLineBreak+'C:\project\Main.pas','Prose segmentation preserves every source character including line endings');
            J:=Cache.Translate(TranslationRevision,'en','fr',Segments,Provider);
            try Check(J.GetValue<Integer>('source_fallback_count')=0,'Fenced code, SQL and paths are protected without becoming missing prose'); finally J.Free; end;
          finally Cache.Free; Provider:=nil; end;
          J:=TJSONObject.ParseJSONValue('{"record_type":"project_profile","fields":{"purpose":"Profile publication fixture","owner":"Named fixture owner","evidence":"Synthetic acceptance evidence; not a live program observation"}}') as TJSONObject;
          try J.GetValue<TJSONObject>('fields').AddPair('architecture','secret="synthetic-profile-secret"; synthetic redaction test');
            Store.SaveKnowledge(0,0,Generation,'Project profile',TDPHProjectProfile.Body(J),'Profile fixture author','orientation','','overview','all','','',J.ToJSON);
          finally J.Free; end;
          Rows:=Store.KnowledgeJSON;
          try Again:=TDPHDocumentModel.Create(View,Rows,[],[],False,False);
            try
              Check(Again.Document.ToJSON.Contains('Profile publication fixture'),'Canonical publication includes attributed project profile text');
              Check(not Again.Document.ToJSON.Contains('synthetic-profile-secret'),'Structured profile values are decoded before export redaction');
              Failed:=False; for V in Again.Document.GetValue<TJSONArray>('knowledge') do
                if V.GetValue<string>('title')='Project profile' then Failed:=V.GetValue<string>('structured_record.fields.purpose')='Profile publication fixture';
              Check(Failed,'Canonical profile retains typed structured fields rather than an opaque encoded JSON string');
              TDPHPublisher.Export(Again,Store,TPath.Combine(Work,'project-profile'));
              TDPHPublisher.Validate(TPath.Combine(Work,'project-profile'),Again.Document.GetValue<string>('input_fingerprint'));
              Text:=TFile.ReadAllText(TPath.Combine(Work,'project-profile\index.html'),TEncoding.UTF8);
              Check(Text.Contains('Named fixture owner') and Text.Contains('Profile publication fixture'),'Offline handoff renders readable project purpose and owner');
              Archive:=TZipFile.Create;
              try Archive.Open(TPath.Combine(Work,'project-profile\Engineering_Guide.docx'),zmRead); Archive.Read('word/document.xml',Bytes);
                Check(TEncoding.UTF8.GetString(Bytes).Contains('Named fixture owner'),'Editable engineering guide includes the same attributed project profile');
              finally Archive.Free; end;
            finally Again.Free; end;
          finally Rows.Free; end;
        finally Knowledge.Free; end;
      finally View.Free; end;
    finally Store.Free; Semantic.Free; Analyzer.Free; end;
    Cache:=TDPHTranslationCache.Create;
    try
      Provider:=TMockTranslator.Create; SetLength(Segments,2); Segments[0].Text:='Run conversion'; Segments[0].IsProtected:=False;
      Segments[1].Text:='TMain.Click C:\project\Main.pas SELECT id FROM items abc123'; Segments[1].IsProtected:=True;
      J:=Cache.Translate(1,'en','fr',Segments,Provider);
      try Check((J.GetValue<TJSONArray>('segments').Items[1] as TJSONObject).GetValue<string>('text')=Segments[1].Text,'Translation preserves identifiers, paths and SQL byte for byte'); Check(J.GetValue<string>('state')='needs_review','Translated prose requires human review'); CacheKey:=J.GetValue<string>('cache_key'); finally J.Free; end;
      Cache.Review(CacheKey,'Translator Reviewer'); J:=Cache.Translate(1,'en','fr',Segments,Provider); try Check(J.GetValue<string>('state')='verified','Translation review is cached for exact content and revision'); finally J.Free; end;
      Segments[0].Text:='Run preview'; J:=Cache.Translate(1,'en','fr',Segments,Provider); try Check(J.GetValue<string>('cache_key')<>CacheKey,'Changed prose invalidates localized cache'); Check(J.GetValue<string>('state')='needs_review','Old translation approval cannot carry to new prose'); finally J.Free; end;
      Provider:=TDPHAtlasAdapter.Create; Failed:=False; try J:=Cache.Translate(1,'en','fr',Segments,Provider); J.Free; except Failed:=True; end; Check(Failed,'Unconfigured external Atlas translation cannot transmit content');
    finally Cache.Free; end;
    J:=TJSONObject.Create; try J.AddPair('checks_passed',TJSONNumber.Create(Checks)); J.AddPair('work',Work); TFile.WriteAllText(TPath.Combine(Root,'docs\wp6-validation.json'),J.Format,TEncoding.UTF8); finally J.Free; end;
    Writeln('PASS WP6: ',Checks,' checks');
  except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode:=1; end; end;
  CoUninitialize;
end.
