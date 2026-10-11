unit DPH.Workspace.Worker;

interface
uses System.SysUtils, System.Classes, System.JSON, System.SyncObjs, System.Generics.Collections;
type
  TDPHWorkspaceRequest = record
    Command,Database,Entry,Configuration,Platform: string;
    Defines,ExternalRoots: TArray<string>;
    KnowledgeID,ExpectedRevision,GenerationID: Int64;
    Title,Body,Editor,Kind,EntityKey,ReviewState: string;
  end;
  TDPHWorkspaceResponse = class
  public
    Document: TJSONObject;
    Knowledge: TJSONArray;
    MessageText: string;
    Busy,Changed,Detached,Failed: Boolean;
    destructor Destroy; override;
  end;
  TDPHWorkspaceWorker = class(TThread)
  private
    FRequests: TThreadedQueue<TDPHWorkspaceRequest>;
    FResponses: TThreadedQueue<TDPHWorkspaceResponse>;
    FBaseDirectory: string;
    procedure Respond(ADocument: TJSONObject; const AMessage: string; ABusy,AChanged,ADetached,AFailed: Boolean; AKnowledge: TJSONArray = nil);
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
uses System.IOUtils, System.StrUtils, Winapi.ActiveX, DPH.Storage.Database, DPH.Storage.Types,
  DPH.Project.Analysis, DPH.Project.Inventory, DPH.Analysis.Model, DPH.Analysis.Symbols,
  DPH.Analysis.Persistence, DPH.Workspace.Model;

destructor TDPHWorkspaceResponse.Destroy;
begin Document.Free; Knowledge.Free; inherited; end;
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
procedure TDPHWorkspaceWorker.Respond(ADocument: TJSONObject; const AMessage: string; ABusy,AChanged,ADetached,AFailed: Boolean; AKnowledge: TJSONArray);
var Response: TDPHWorkspaceResponse;
begin
  Response:=TDPHWorkspaceResponse.Create; Response.Document:=ADocument; Response.MessageText:=AMessage;
  Response.Knowledge:=AKnowledge;
  Response.Busy:=ABusy; Response.Changed:=AChanged; Response.Detached:=ADetached; Response.Failed:=AFailed;
  if Terminated or (FResponses.PushItem(Response)<>wrSignaled) then Response.Free;
end;
procedure TDPHWorkspaceWorker.Execute;
var Request: TDPHWorkspaceRequest; Analyzer: TDPHAnalyzer; Semantic: TDPHSemanticAnalyzer;
    Scan: TDPHScan; Graph: TDPHSemanticGraph; Store: TDPHKnowledgeStore; Inventory: TDPHInventory;
    Root,Text,MessageText: string; Document,Cached: TJSONObject; Config,Generation: Int64;
    Defines: TJSONArray; Value: string; Status: TDPHProjectStatus; Changed,RunScan: Boolean;
begin
  CoInitializeEx(nil,COINIT_APARTMENTTHREADED); Analyzer:=TDPHAnalyzer.Create; Semantic:=TDPHSemanticAnalyzer.Create;
  try
    while not Terminated do
    begin
      if FRequests.PopItem(Request)<>wrSignaled then Continue;
      try
        Respond(nil,'Working in background…',True,False,False,False);
        if MatchText(Request.Command,['open','knowledge','save_knowledge','review_knowledge']) then Root:=TDPHKnowledgeStore.ProjectRoot(Request.Database)
        else Root:=ExtractFilePath(Request.Entry);
        Store:=TDPHKnowledgeStore.Create(Request.Database,Root,TPath.Combine(FBaseDirectory,'migrations'));
        try
          if MatchText(Request.Command,['knowledge','save_knowledge','review_knowledge']) then
          begin
            if Request.Command='save_knowledge' then Store.SaveKnowledge(Request.KnowledgeID,Request.ExpectedRevision,Request.GenerationID,
              Request.Title,Request.Body,Request.Editor,Request.Kind,Request.EntityKey);
            if Request.Command='review_knowledge' then
            begin
              if Request.Entry='' then raise EReadError.Create('Attach source before reviewing; cached evidence alone cannot establish current source');
              Cached:=TJSONObject.ParseJSONValue(Store.LoadWorkspaceView(Request.GenerationID)) as TJSONObject;
              try if (Cached=nil) or (Cached.GetValue<string>('selection_hash','')<>TDPHWorkspaceView.SelectionHash(Request.Configuration,Request.Platform,Request.Defines,Request.ExternalRoots)) then
                raise EReadError.Create('Selected configuration differs from the evidence being reviewed; reassess first'); finally Cached.Free; end;
              Inventory:=TDPHInventory.Create(Request.Entry,Request.Configuration,Request.Platform,Request.Defines,Request.ExternalRoots);
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
            Status:=Store.Status;
            MessageText:='Cached project — detached: source has not been attached';
            if Status.AnalysisStale then MessageText:=MessageText+' | analysis stale';
            if Status.ModificationDetected then MessageText:=MessageText+' | source modification detected';
            if Status.KnowledgeReviewNeeded then MessageText:=MessageText+' | human review pending';
            if Status.AnalysisFailed then MessageText:=MessageText+' | last analysis failed';
            Respond(Document,MessageText,False,False,True,False,Store.KnowledgeJSON); Continue;
          end;
          Store.InitializeProject(ExtractFileName(Request.Entry),'Delphi');
          RunScan:=True; Changed:=False;
          if Request.Command='check' then
          begin
            Cached:=nil; Text:=Store.LoadWorkspaceView;
            if Text<>'' then Cached:=TJSONObject.ParseJSONValue(Text) as TJSONObject;
            try
              Inventory:=TDPHInventory.Create(Request.Entry,Request.Configuration,Request.Platform,Request.Defines,Request.ExternalRoots);
              try
                Changed:=(Cached=nil) or (TDPHKnowledgeStore.ManifestHash(Inventory.Manifest)<>Cached.GetValue<TJSONObject>('semantics').GetValue<string>('input_fingerprint'))
                  or (Cached.GetValue<string>('selection_hash','')<>TDPHWorkspaceView.SelectionHash(Request.Configuration,Request.Platform,Request.Defines,Request.ExternalRoots));
                if Changed then Store.ObserveManifest(Inventory.Manifest);
              finally Inventory.Free; end;
              RunScan:=Changed;
              if Changed then Respond(nil,'Source modification detected; analysis stale; reassessing…',True,True,False,False)
              else Respond(nil,'Source fingerprints unchanged',False,False,False,False);
            finally Cached.Free; end;
          end;
          if not RunScan or Terminated then Continue;
          Defines:=TJSONArray.Create; try for Value in Request.Defines do Defines.Add(Value);
            Config:=Store.AddConfiguration(Request.Platform,'37.0',Defines.ToJSON,'[]',Request.Configuration);
          finally Defines.Free; end;
          Store.SelectConfiguration(Config);
          Scan:=Analyzer.Scan(Request.Entry,Request.Configuration,Request.Platform,Request.Defines,Request.ExternalRoots,Request.Command<>'full');
          try
            if Terminated then Continue;
            Graph:=Semantic.Analyze(Scan);
            try
              if Terminated then Continue;
              Respond(nil,'Saving revision-consistent analysis…',True,Changed,False,False);
              Generation:=TDPHSemanticPersistence.Stage(Scan,Graph,Store,Config);
              if Terminated then begin Store.FailGeneration(Generation,'Cancelled by user'); Continue; end;
              Document:=TDPHWorkspaceView.Capture(Scan,Graph,Generation,Request.Entry,Request.Configuration,Request.Platform,Request.Defines,Request.ExternalRoots);
              try
                Store.SaveWorkspaceView(Generation,Document.ToJSON);
                if TDPHSemanticPersistence.Publish(Scan,Graph,Store,Generation) then MessageText:='Analysis current'
                else if not Scan.Inventory.Revalidate then
                begin
                  MessageText:='Source changed during analysis — superseded; retry scheduled';
                  Document.Free; Document:=nil; Respond(nil,MessageText,False,True,False,False); Continue;
                end
                else MessageText:='PARTIAL captured analysis; previous complete head retained';
                if Store.Status.KnowledgeReviewNeeded then MessageText:=MessageText+' | human knowledge review pending';
                Respond(Document,MessageText,False,Changed,False,False,Store.KnowledgeJSON); Document:=nil;
              finally Document.Free; end;
            finally Graph.Free; end;
          finally Scan.Free; end;
        finally Store.Free; end;
      except on E: Exception do Respond(nil,E.ClassName+': '+E.Message,False,False,False,True); end;
    end;
  finally Semantic.Free; Analyzer.Free; CoUninitialize; end;
end;
end.
