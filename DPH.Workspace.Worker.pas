unit DPH.Workspace.Worker;

interface
uses System.SysUtils, System.Classes, System.JSON, System.SyncObjs, System.Generics.Collections;
type
  TDPHWorkspaceRequest = record
    Command,Database,Entry,Configuration,Platform: string;
    Defines,ExternalRoots: TArray<string>;
    KnowledgeID,ExpectedRevision,GenerationID: Int64;
    Title,Body,Editor,Kind,EntityKey,ReviewState: string;
    DocumentKind,Audience: string;
    LinksJSON: string;
    QuestionJSON: string;
    OldEntityKey: string;
    SearchKind: string;
    SearchOffset: Integer;
    CodePage: Integer;
    ExportDirectory: string;
    Seeds,Exclusions: TArray<string>;
    IncludeAgentInstructions: Boolean;
    IncludeSourceNavigation: Boolean;
    AllowStaleBundle: Boolean;
  end;
  TDPHWorkspaceResponse = class
  public
    Document: TJSONObject;
    Knowledge,Screenshots: TJSONArray;
    ExportDirectory: string;
    SourceEntry: string;
    Lifecycle: TJSONArray;
    Continuity: TJSONArray;
    RetentionCount: Integer;
    RestoredDatabase: string;
    SearchResults: TJSONArray;
    SearchGeneration: Int64;
    LinkCandidates: TJSONArray;
    ReviewTasks: TJSONArray;
    Observations: TJSONArray;
    Translations: TJSONArray;
    TranslationRevision: Int64;
    ValidationReport: string;
    MessageText: string;
    Busy,Changed,Detached,Failed: Boolean;
    destructor Destroy; override;
  end;
  TDPHWorkspaceWorker = class(TThread)
  private
    FRequests: TThreadedQueue<TDPHWorkspaceRequest>;
    FResponses: TThreadedQueue<TDPHWorkspaceResponse>;
    FBaseDirectory: string;
    procedure Respond(ADocument: TJSONObject; const AMessage: string; ABusy,AChanged,ADetached,AFailed: Boolean; AKnowledge: TJSONArray = nil; const AExportDirectory: string = ''; AImages: TJSONArray = nil; const ASourceEntry: string = '');
  protected
    procedure Execute; override;
  public
    constructor Create(const ABaseDirectory: string);
    destructor Destroy; override;
    procedure Submit(const ARequest: TDPHWorkspaceRequest);
    function Poll(out AResponse: TDPHWorkspaceResponse): Boolean;
    procedure Stop;
  end;
implementation
uses System.IOUtils, System.StrUtils, System.Hash, Winapi.ActiveX, DPH.Storage.Database, DPH.Storage.Types,
  DPH.Project.Analysis, DPH.Project.Inventory, DPH.Analysis.Model, DPH.Analysis.Symbols,
  DPH.Analysis.Persistence, DPH.Workspace.Model, DPH.Publish.Model, DPH.Publish.Export, DPH.Storage.Backup, DPH.Parse.Model, DPH.Publish.Translation;

destructor TDPHWorkspaceResponse.Destroy;
begin Document.Free; Knowledge.Free; Screenshots.Free; Lifecycle.Free; Continuity.Free; SearchResults.Free; LinkCandidates.Free; ReviewTasks.Free; Observations.Free; Translations.Free; inherited; end;
constructor TDPHWorkspaceWorker.Create(const ABaseDirectory: string);
begin
  inherited Create(False); FreeOnTerminate:=False; FBaseDirectory:=ABaseDirectory;
  FRequests:=TThreadedQueue<TDPHWorkspaceRequest>.Create(8,0,100);
  FResponses:=TThreadedQueue<TDPHWorkspaceResponse>.Create(8,100,0);
end;
destructor TDPHWorkspaceWorker.Destroy;
var Response: TDPHWorkspaceResponse;
begin
  Stop; WaitFor; while Poll(Response) do Response.Free;
  FResponses.Free; FRequests.Free; inherited;
end;
procedure TDPHWorkspaceWorker.Stop;
begin Terminate; FRequests.DoShutDown; FResponses.DoShutDown; end;
procedure TDPHWorkspaceWorker.Submit(const ARequest: TDPHWorkspaceRequest);
begin if FRequests.PushItem(ARequest)<>wrSignaled then raise EInvalidOperation.Create('Workspace request queue is full'); end;
function TDPHWorkspaceWorker.Poll(out AResponse: TDPHWorkspaceResponse): Boolean;
begin Result:=(FResponses.PopItem(AResponse)=wrSignaled) and (AResponse<>nil); end;
procedure TDPHWorkspaceWorker.Respond(ADocument: TJSONObject; const AMessage: string; ABusy,AChanged,ADetached,AFailed: Boolean; AKnowledge: TJSONArray; const AExportDirectory: string; AImages: TJSONArray; const ASourceEntry: string);
var Response: TDPHWorkspaceResponse;
begin
  Response:=TDPHWorkspaceResponse.Create; Response.Document:=ADocument; Response.MessageText:=AMessage;
  Response.Knowledge:=AKnowledge;
  Response.Screenshots:=AImages;
  Response.ExportDirectory:=AExportDirectory;
  Response.SourceEntry:=ASourceEntry;
  Response.Busy:=ABusy; Response.Changed:=AChanged; Response.Detached:=ADetached; Response.Failed:=AFailed;
  if Terminated or (FResponses.PushItem(Response)<>wrSignaled) then Response.Free;
end;
procedure TDPHWorkspaceWorker.Execute;
var Request: TDPHWorkspaceRequest; Analyzer: TDPHAnalyzer; Semantic: TDPHSemanticAnalyzer;
    Scan: TDPHScan; Graph: TDPHSemanticGraph; Store: TDPHKnowledgeStore; Inventory: TDPHInventory;
    Root,Text,MessageText,SourceEntry: string; Document,Cached: TJSONObject; Config,Generation: Int64;
    Defines: TJSONArray; Value: string; JSONValue: TJSONValue; Status: TDPHProjectStatus; Changed,RunScan,OpeningCached: Boolean;
    View: TDPHWorkspaceView; Model: TDPHDocumentModel; Knowledge,Images: TJSONArray; LifecycleResponse: TDPHWorkspaceResponse;
    TranslationCache: TDPHTranslationCache; Provider: IDPHTranslationProvider; TranslationEntry: TJSONObject; RecordValue: TJSONValue;
begin
  CoInitializeEx(nil,COINIT_APARTMENTTHREADED); Analyzer:=TDPHAnalyzer.Create; Semantic:=TDPHSemanticAnalyzer.Create;
  try
    while not Terminated do
    begin
      if FRequests.PopItem(Request)<>wrSignaled then Continue;
      try
        OpeningCached:=Request.Command='open';
        Respond(nil,'Working in background...',True,False,False,False);
        if Request.Command='restore_backup' then begin
          TDPHProjectBackup.Restore(Request.Database,Request.ExportDirectory,TPath.Combine(FBaseDirectory,'migrations'));
          LifecycleResponse:=TDPHWorkspaceResponse.Create;
          LifecycleResponse.RestoredDatabase:=Request.ExportDirectory;
          LifecycleResponse.MessageText:='Backup restored to a new database; opening the verified copy';
          if FResponses.PushItem(LifecycleResponse)<>wrSignaled then LifecycleResponse.Free;
          Continue;
        end;
        if Request.Command='validate_bundle' then begin
          TDPHPublisher.Validate(Request.ExportDirectory,Request.Title,not Request.AllowStaleBundle);
          LifecycleResponse:=TDPHWorkspaceResponse.Create;
          LifecycleResponse.ValidationReport:='PASS: bundle filenames, SHA256 values, canonical provenance, technical indexes and evidence references agree with the supplied capture fingerprint.'+sLineBreak+
            'Expected fingerprint: '+Request.Title+sLineBreak+'Bundle: '+Request.ExportDirectory+sLineBreak;
          if Request.AllowStaleBundle then LifecycleResponse.ValidationReport:=LifecycleResponse.ValidationReport+
            'Historical/partial inspection enabled. This result does not establish current source, complete analysis or reviewed procedures.'+sLineBreak;
          LifecycleResponse.ValidationReport:=LifecycleResponse.ValidationReport+'Integrity is relative to the supplied trusted fingerprint and manifest; it is not author authentication or permission to execute the project.';
          LifecycleResponse.MessageText:='Bundle validation passed. Read the report and any historical/partial qualification.';
          if FResponses.PushItem(LifecycleResponse)<>wrSignaled then LifecycleResponse.Free;
          Continue;
        end;
        if (Request.Entry<>'') and MatchText(Request.Command,['incremental','full','relocate']) then
        begin
          Inventory:=TDPHInventory.Create(Request.Entry,Request.Configuration,Request.Platform,Request.Defines,Request.ExternalRoots,Request.CodePage);
          try if Inventory.IsHandoffProject then raise EReadError.Create(DPHSelfSelectionMessage);
            Request.Configuration:=Inventory.ConfigurationName; Request.Platform:=Inventory.PlatformName;
          finally Inventory.Free; end;
        end;
        if MatchText(Request.Command,['open','knowledge','save_knowledge','review_knowledge','publish','relocate','import_screenshot','retention_preview','retention_apply','retention_pin','continuity_preview','continuity_approve','save_backup','integrity','search','link_candidates','review_tasks','observations','import_observation','translate','translations','review_translation']) then Root:=TDPHKnowledgeStore.ProjectRoot(Request.Database)
        else Root:=ExtractFilePath(Request.Entry);
        Store:=TDPHKnowledgeStore.Create(Request.Database,Root,TPath.Combine(FBaseDirectory,'migrations'));
        try
          if MatchText(Request.Command,['translate','translations','review_translation']) then begin
            if Request.Command='translate' then begin
              Text:=''; Knowledge:=Store.KnowledgeJSON;
              try for RecordValue in Knowledge do if RecordValue.GetValue<Int64>('revision')=Request.ExpectedRevision then Text:=RecordValue.GetValue<string>('body'); finally Knowledge.Free; end;
              if Text='' then raise EReadError.Create('Select a current saved knowledge revision before translating');
              Provider:=TDPHAtlasAdapter.Create(Request.Body);
              TranslationCache:=TDPHTranslationCache.Create(Store);
              try TranslationEntry:=TranslationCache.Translate(Request.ExpectedRevision,Request.Kind,Request.Audience,
                TDPHTranslationCache.SegmentsForText(Text),Provider,False,Request.LinksJSON); TranslationEntry.Free;
              finally TranslationCache.Free; Provider:=nil; end;
            end;
            if Request.Command='review_translation' then begin
              if Request.Entry='' then raise EReadError.Create('Attach current source before approving a translation');
              Cached:=TJSONObject.ParseJSONValue(Store.LoadWorkspaceView(Request.GenerationID)) as TJSONObject;
              try if (Cached=nil) or (Cached.GetValue<string>('selection_hash','')<>TDPHWorkspaceView.SelectionHash(Request.Configuration,Request.Platform,Request.Defines,Request.ExternalRoots,Request.CodePage)) then
                raise EReadError.Create('Selected configuration differs from the source evidence; reassess first'); finally Cached.Free; end;
              Inventory:=TDPHInventory.Create(Request.Entry,Request.Configuration,Request.Platform,Request.Defines,Request.ExternalRoots,Request.CodePage);
              try Store.ObserveManifest(Inventory.Manifest); finally Inventory.Free; end;
              TranslationEntry:=Store.LoadTranslation(Request.Title);
              try if (TranslationEntry=nil) or (TranslationEntry.GetValue<Int64>('revision')<>Request.ExpectedRevision) then raise EReadError.Create('Refresh translations for the selected source revision');
              finally TranslationEntry.Free; end;
              Store.ReviewTranslation(Request.Title,Request.Editor);
            end;
            LifecycleResponse:=TDPHWorkspaceResponse.Create;
            try LifecycleResponse.Translations:=Store.TranslationEntries(Request.ExpectedRevision);
              LifecycleResponse.TranslationRevision:=Request.ExpectedRevision;
              LifecycleResponse.SearchGeneration:=Request.GenerationID; LifecycleResponse.Detached:=Request.Entry='';
              LifecycleResponse.MessageText:='Offline translations loaded for the exact saved revision. Source fallbacks remain explicit; approval is a separate named action.';
              if FResponses.PushItem(LifecycleResponse)=wrSignaled then LifecycleResponse:=nil;
            finally LifecycleResponse.Free; end;
            Continue;
          end;
          if Request.Command='search' then begin
            LifecycleResponse:=TDPHWorkspaceResponse.Create;
            try
              LifecycleResponse.SearchResults:=Store.SearchProject(Request.GenerationID,Request.Body,Request.SearchKind,Request.SearchOffset);
              LifecycleResponse.SearchGeneration:=Request.GenerationID;
              LifecycleResponse.Knowledge:=Store.KnowledgeJSON;
              LifecycleResponse.Detached:=Request.Entry='';
              LifecycleResponse.MessageText:='Indexed search returned '+IntToStr(LifecycleResponse.SearchResults.Count)+' results. Excerpts retain their evidence/review classification.';
              if FResponses.PushItem(LifecycleResponse)=wrSignaled then LifecycleResponse:=nil;
            finally LifecycleResponse.Free; end;
            Continue;
          end;
          if Request.Command='save_backup' then begin
            TDPHProjectBackup.Save(Store,Request.ExportDirectory);
            Respond(nil,'Backup saved: '+Request.ExportDirectory+'. Keep its adjacent .views folder with it.',False,False,Request.Entry='',False); Continue;
          end;
          if Request.Command='integrity' then begin
            Text:=Store.IntegrityCheck;
            if Text<>'ok' then raise EReadError.Create('Database integrity check failed: '+Text);
            Store.ManagedArtifactPaths;
            Respond(nil,'Database integrity: '+Text+'. All managed view/image checksums verified.',False,False,Request.Entry='',False); Continue;
          end;
          if StartsText('continuity_',Request.Command) then begin
            if Request.Command='continuity_approve' then begin
              if Request.Entry='' then raise EReadError.Create('Attach available source before approving identity continuity');
              Inventory:=TDPHInventory.Create(Request.Entry,Request.Configuration,Request.Platform,Request.Defines,Request.ExternalRoots,Request.CodePage);
              try Store.ObserveManifest(Inventory.Manifest); finally Inventory.Free; end;
              Store.ApproveContinuity(Request.KnowledgeID,Request.ExpectedRevision,Request.GenerationID,Request.OldEntityKey,Request.EntityKey,Request.Editor);
            end;
            LifecycleResponse:=TDPHWorkspaceResponse.Create;
            try
              LifecycleResponse.Continuity:=Store.ContinuityCandidates(Request.GenerationID,Request.Body);
              LifecycleResponse.Knowledge:=Store.KnowledgeJSON;
              LifecycleResponse.Detached:=Request.Entry='';
              LifecycleResponse.MessageText:='Identity candidates are proposals only. Approved links still require knowledge-content review.';
              if FResponses.PushItem(LifecycleResponse)=wrSignaled then LifecycleResponse:=nil;
            finally LifecycleResponse.Free; end;
            Continue;
          end;
          if StartsText('retention_',Request.Command) then begin
            if Request.Command='retention_apply' then Store.ApplyRetention(StrToInt(Request.Body));
            if Request.Command='retention_pin' then Store.RetainGeneration(Request.GenerationID,Request.Title,Request.Editor);
            LifecycleResponse:=TDPHWorkspaceResponse.Create;
            try
              LifecycleResponse.Lifecycle:=Store.RetentionReport(StrToInt(Request.Body));
              LifecycleResponse.RetentionCount:=Store.RecentRetentionCount;
              LifecycleResponse.Detached:=Request.Entry='';
              LifecycleResponse.MessageText:='Retention report ready. Immutable evidence and authored history are preserved.';
              if FResponses.PushItem(LifecycleResponse)=wrSignaled then LifecycleResponse:=nil;
            finally LifecycleResponse.Free; end;
            Continue;
          end;
          if MatchText(Request.Command,['observations','import_observation']) then begin
            if Request.Command='import_observation' then Store.ImportObservation(Request.GenerationID,Request.Body,Request.Editor,Request.Title,Request.EntityKey);
            LifecycleResponse:=TDPHWorkspaceResponse.Create;
            try LifecycleResponse.Observations:=Store.ObservationsJSON; LifecycleResponse.SearchGeneration:=Request.GenerationID;
              LifecycleResponse.Detached:=Request.Entry=''; LifecycleResponse.MessageText:='Saved runtime claims loaded (newest 50). No program executed; contributor evidence remains unverified.';
              if FResponses.PushItem(LifecycleResponse)=wrSignaled then LifecycleResponse:=nil;
            finally LifecycleResponse.Free; end;
            Continue;
          end;
          if Request.Command='import_screenshot' then begin
            Store.ImportScreenshot(Request.GenerationID,Request.Body,Request.Editor,Request.Title,Request.EntityKey);
            Respond(nil,'Screenshot imported as attributed, unverified image evidence',False,False,Request.Entry='',False,nil,'',Store.ScreenshotsJSON); Continue;
          end;
          if Request.Command='relocate' then
          begin
            Cached:=TJSONObject.ParseJSONValue(Store.LoadWorkspaceView(Request.GenerationID)) as TJSONObject;
            try
              if (Cached=nil) or not SameText(Cached.GetValue<string>('entry'),ExtractFileName(Request.Entry)) or
                (Cached.GetValue<string>('selection_hash','')<>TDPHWorkspaceView.SelectionHash(Request.Configuration,Request.Platform,Request.Defines,Request.ExternalRoots,Request.CodePage)) then
                raise EReadError.Create('Relocation requires the same project entry and analysis selection');
              Inventory:=TDPHInventory.Create(Request.Entry,Request.Configuration,Request.Platform,Request.Defines,Request.ExternalRoots,Request.CodePage);
              try
                if not Inventory.Revalidate then raise EReadError.Create('Relocation source changed during verification');
                Store.RelocateSource(Inventory.Root,Request.GenerationID,Inventory.Manifest);
              finally Inventory.Free; end;
            finally Cached.Free; end;
          end;
          if Request.Command='publish' then
          begin
            if Request.Entry<>'' then begin Inventory:=TDPHInventory.Create(Request.Entry,Request.Configuration,Request.Platform,Request.Defines,Request.ExternalRoots,Request.CodePage);
              try Store.ObserveManifest(Inventory.Manifest); finally Inventory.Free; end; end;
            Document:=TJSONObject.ParseJSONValue(Store.LoadWorkspaceView(Request.GenerationID)) as TJSONObject;
            View:=TDPHWorkspaceView.Create(Document); Knowledge:=nil; Images:=nil;
            try
              Knowledge:=Store.KnowledgeJSON; Images:=Store.ScreenshotsJSON;
              if Request.Audience='' then Request.Audience:='all';
              Model:=TDPHDocumentModel.Create(View,Knowledge,Request.Seeds,Request.Exclusions,Request.Entry='',Store.GenerationIsStale(Request.GenerationID),Images,False,Request.Audience);
              try TDPHPublisher.Export(Model,Store,Request.ExportDirectory,Request.IncludeAgentInstructions,Request.IncludeSourceNavigation);
                Store.RecordExport(Request.GenerationID,Request.ExportDirectory,THashSHA2.GetHashString(Model.Document.ToJSON),'{"scope":"'+Model.Document.GetValue<string>('scope')+'"}',Model.Document.GetValue<Boolean>('stale'));
              finally Model.Free; end;
            finally Images.Free; Knowledge.Free; View.Free; end;
            Respond(nil,'Offline HTML, editable guides and technical bundle exported. Review coverage and stale status before use.',False,False,Request.Entry='',False,nil,Request.ExportDirectory); Continue;
          end;
          if Request.Command='review_tasks' then begin
            LifecycleResponse:=TDPHWorkspaceResponse.Create;
            try LifecycleResponse.ReviewTasks:=Store.ReviewTasks(Request.GenerationID); LifecycleResponse.SearchGeneration:=Request.GenerationID;
              LifecycleResponse.Detached:=Request.Entry=''; LifecycleResponse.MessageText:='Pending review tasks with captured before/after evidence; first 1000 tasks, 200 affected objects/relationships per task.';
              if FResponses.PushItem(LifecycleResponse)=wrSignaled then LifecycleResponse:=nil;
            finally LifecycleResponse.Free; end;
            Continue;
          end;
          if Request.Command='link_candidates' then begin
            LifecycleResponse:=TDPHWorkspaceResponse.Create;
            try LifecycleResponse.LinkCandidates:=Store.LinkCandidates(Request.GenerationID,Request.Kind,Request.Body);
              LifecycleResponse.SearchGeneration:=Request.GenerationID; LifecycleResponse.Detached:=Request.Entry='';
              LifecycleResponse.MessageText:='First 200 matching link targets. Narrow the filter to find others.';
              if FResponses.PushItem(LifecycleResponse)=wrSignaled then LifecycleResponse:=nil;
            finally LifecycleResponse.Free; end;
            Continue;
          end;
          if MatchText(Request.Command,['knowledge','save_knowledge','review_knowledge']) then
          begin
            if Request.Command='save_knowledge' then Store.SaveKnowledge(Request.KnowledgeID,Request.ExpectedRevision,Request.GenerationID,
              Request.Title,Request.Body,Request.Editor,Request.Kind,Request.EntityKey,Request.DocumentKind,Request.Audience,Request.LinksJSON,Request.QuestionJSON);
            if Request.Command='review_knowledge' then
            begin
              if Request.Entry='' then raise EReadError.Create('Attach source before reviewing; cached evidence alone cannot establish current source');
              Cached:=TJSONObject.ParseJSONValue(Store.LoadWorkspaceView(Request.GenerationID)) as TJSONObject;
              try if (Cached=nil) or (Cached.GetValue<string>('selection_hash','')<>TDPHWorkspaceView.SelectionHash(Request.Configuration,Request.Platform,Request.Defines,Request.ExternalRoots,Request.CodePage)) then
                raise EReadError.Create('Selected configuration differs from the evidence being reviewed; reassess first'); finally Cached.Free; end;
              Inventory:=TDPHInventory.Create(Request.Entry,Request.Configuration,Request.Platform,Request.Defines,Request.ExternalRoots,Request.CodePage);
              try Store.ObserveManifest(Inventory.Manifest); finally Inventory.Free; end;
              Store.ReviewKnowledge(Request.KnowledgeID,Request.ExpectedRevision,Request.GenerationID,Request.Editor,Request.ReviewState);
            end;
            MessageText:='Knowledge saved; named review remains explicit';
            if Store.Status.KnowledgeReviewNeeded then MessageText:=MessageText+' | human review pending';
            Respond(nil,MessageText,False,False,Request.Entry='',False,Store.KnowledgeJSON); Continue;
          end;
          if Request.Command='open' then
          begin
            Text:=Store.LoadWorkspaceView;
            if Text='' then raise EReadError.Create('No cached workspace is available; attach the source project to analyze it');
            Document:=TJSONObject.ParseJSONValue(Text) as TJSONObject;
            if TDPHWorkspaceView.IsHandoffProject(Document) then
            begin Document.Free; raise EReadError.Create(DPHSelfSelectionMessage); end;
            Status:=Store.Status;
            MessageText:='Cached project - detached: source has not been attached';
            if Status.AnalysisStale then MessageText:=MessageText+' | analysis stale';
            if Status.ModificationDetected then MessageText:=MessageText+' | source modification detected';
            if Status.KnowledgeReviewNeeded then MessageText:=MessageText+' | human review pending';
            if Status.AnalysisFailed then MessageText:=MessageText+' | last analysis failed';
            Knowledge:=nil; Images:=nil;
            try
              Knowledge:=Store.KnowledgeJSON;
              try Images:=Store.ScreenshotsJSON;
              except on E: Exception do begin Images:=TJSONArray.Create; MessageText:=MessageText+' | Screenshot evidence unavailable: '+E.Message; end; end;
              SourceEntry:='';
              Text:=Document.GetValue<string>('entry');
              if (Text<>'') and (ExtractFileName(Text)=Text) and TFile.Exists(TPath.Combine(Root,Text)) then
                SourceEntry:=TPath.Combine(Root,Text);
              if SourceEntry<>'' then begin
                Request.Entry:=SourceEntry; Request.Command:='check';
                Request.CodePage:=Document.GetValue<Integer>('code_page',0);
                Request.Configuration:=Document.GetValue<string>('configuration');
                Request.Platform:=Document.GetValue<string>('platform');
                Request.Defines:=[]; Request.ExternalRoots:=[];
                for JSONValue in Document.GetValue<TJSONArray>('defines') do Request.Defines:=Request.Defines+[JSONValue.Value];
                for JSONValue in Document.GetValue<TJSONArray>('external_roots') do Request.ExternalRoots:=Request.ExternalRoots+[JSONValue.Value];
                MessageText:=MessageText.Replace('Cached project - detached: source has not been attached',
                  'Cached project loaded; verifying attached source in background');
              end;
              Respond(Document,MessageText,SourceEntry<>'',False,SourceEntry='',False,Knowledge,'',Images,SourceEntry);
              Document:=nil; Knowledge:=nil; Images:=nil;
            finally Document.Free; Knowledge.Free; Images.Free; end;
            if SourceEntry='' then Continue;
          end;
          Store.InitializeProject(ExtractFileName(Request.Entry),'Delphi');
          RunScan:=True; Changed:=False;
          if Request.Command='check' then
          begin
            Cached:=nil; Text:=Store.LoadWorkspaceView;
            if Text<>'' then Cached:=TJSONObject.ParseJSONValue(Text) as TJSONObject;
            try
              Inventory:=TDPHInventory.Create(Request.Entry,Request.Configuration,Request.Platform,Request.Defines,Request.ExternalRoots,Request.CodePage);
              try
                if Inventory.IsHandoffProject then raise EReadError.Create(DPHSelfSelectionMessage);
                Changed:=(Cached=nil) or (TDPHKnowledgeStore.ManifestHash(Inventory.Manifest)<>Cached.GetValue<TJSONObject>('semantics').GetValue<string>('input_fingerprint'))
                  or (Cached.GetValue<string>('syntax.analyzer','')<>DPHAnalyzerVersion)
                  or (Cached.GetValue<string>('semantics.analyzer','')<>DPHSemanticVersion)
                  or (Cached.GetValue<string>('selection_hash','')<>TDPHWorkspaceView.SelectionHash(Request.Configuration,Request.Platform,Request.Defines,Request.ExternalRoots,Request.CodePage));
                if Changed then Store.ObserveManifest(Inventory.Manifest);
              finally Inventory.Free; end;
              RunScan:=Changed;
              if Changed then Respond(nil,'Source modification detected; analysis stale; reassessing...',True,True,False,False)
              else if OpeningCached then Respond(Cached.Clone as TJSONObject,'Cached project verified; source fingerprints unchanged',False,False,False,False,nil,'',nil,Request.Entry)
              else Respond(nil,'Source fingerprints unchanged',False,False,False,False);
            finally Cached.Free; end;
          end;
          if not RunScan or Terminated then Continue;
          Defines:=TJSONArray.Create; try for Value in Request.Defines do Defines.Add(Value);
            Text:=Request.Configuration; if Request.CodePage<>0 then Text:=Text+';CP'+IntToStr(Request.CodePage);
            Config:=Store.AddConfiguration(Request.Platform,'37.0',Defines.ToJSON,'[]',Text);
          finally Defines.Free; end;
          Store.SelectConfiguration(Config);
          Scan:=Analyzer.Scan(Request.Entry,Request.Configuration,Request.Platform,Request.Defines,Request.ExternalRoots,Request.Command<>'full',Request.CodePage);
          try
            if Terminated then Continue;
            Graph:=Semantic.Analyze(Scan,Request.Command<>'full');
            try
              if Terminated then Continue;
              Respond(nil,'Saving revision-consistent analysis...',True,Changed,False,False);
              Generation:=TDPHSemanticPersistence.Stage(Scan,Graph,Store,Config);
              if Terminated then begin Store.FailGeneration(Generation,'Cancelled by user'); Continue; end;
              Document:=TDPHWorkspaceView.Capture(Scan,Graph,Generation,Request.Entry,Request.Configuration,Request.Platform,Request.Defines,Request.ExternalRoots);
              try
                Store.SaveWorkspaceView(Generation,Document.ToJSON);
                if TDPHSemanticPersistence.Publish(Scan,Graph,Store,Generation) then MessageText:='Analysis current'
                else if not Scan.Inventory.Revalidate then
                begin
                  MessageText:='Source changed during analysis - superseded; retry scheduled';
                  Document.Free; Document:=nil; Respond(nil,MessageText,False,True,False,False); Continue;
                end
                else MessageText:='PARTIAL captured analysis; previous complete head retained';
                MessageText:=MessageText+' | routines rebuilt '+IntToStr(Semantic.RecomputedRoutines)+', reused '+IntToStr(Semantic.ReusedRoutines);
                if Store.Status.KnowledgeReviewNeeded then MessageText:=MessageText+' | human knowledge review pending';
                Knowledge:=nil; Images:=nil;
                try
                  Knowledge:=Store.KnowledgeJSON;
                  try Images:=Store.ScreenshotsJSON;
                  except on E: Exception do begin Images:=TJSONArray.Create; MessageText:=MessageText+' | Screenshot evidence unavailable: '+E.Message; end; end;
                  Respond(Document,MessageText,False,Changed,False,False,Knowledge,'',Images);
                  Document:=nil; Knowledge:=nil; Images:=nil;
                finally Knowledge.Free; Images.Free; end;
              finally Document.Free; end;
            finally Graph.Free; end;
          finally Scan.Free; end;
        finally Store.Free; end;
      except on E: Exception do Respond(nil,E.ClassName+': '+E.Message,False,False,False,True); end;
    end;
  finally Semantic.Free; Analyzer.Free; CoUninitialize; end;
end;
end.
