unit DPH.Storage.Database;

interface

uses
  System.SysUtils, System.Classes, System.Variants, System.Generics.Collections,
  System.SyncObjs, System.JSON, Winapi.Windows,
  FireDAC.Comp.Client, DPH.Storage.Types;

type
  TDPHKnowledgeStore = class
  private
    FConnection: TFDConnection;
    FWriterMutex: THandle;
    FDatabasePath: string;
    FSourceRoot: string;
    FThreadID: Cardinal;
    FWriteQueue: TThreadedQueue<TProc<TDPHKnowledgeStore>>;
    FReady: Boolean;
    FClosing: Integer;
    procedure RequireWriter;
    procedure ApplyMigrations(const AMigrationDirectory: string);
    function NewQuery(const ASQL: string; const AValues: array of Variant): TFDQuery;
    function Scalar(const ASQL: string; const AValues: array of Variant): Variant;
    function UTCNow: string;
    procedure RequireRunning(AGenerationID: Int64);
    function ReadManifest(AGenerationID: Int64 = 0): TDPHManifest;
  public
    procedure CheckOutsideSource(const APath: string);
    constructor Create(const ADatabasePath, ASourceRoot, AMigrationDirectory: string;
      AUseWAL: Boolean = False);
    destructor Destroy; override;
    class function ManifestHash(const AFiles: TDPHManifest): string; static;
    procedure QueueWrite(const AWrite: TProc<TDPHKnowledgeStore>);
    procedure ProcessQueuedWrites;
    procedure InitializeProject(const AName, AProjectKind: string);
    function AddConfiguration(const APlatform, ACompiler, ADefinesJSON,
      ASearchPathsJSON, AEnvironment: string): Int64;
    procedure SelectConfiguration(AConfigurationID: Int64);
    procedure ObserveManifest(const AFiles: TDPHManifest);
    function BeginGeneration(AConfigurationID: Int64; const AAnalyzerVersion: string;
      const AFiles: TDPHManifest): Int64;
    function AddSourceEntity(AGenerationID: Int64; const APath, AKey,
      AKind, AName, ASignature: string; AStartOffset, AEndOffset: Int64;
      const AStructuralJSON: string = '{}'): Int64;
    procedure AddDiagnostic(AGenerationID: Int64; const ASeverity,ACode,AMessage,ARangeJSON: string);
    function AddEvidence(AGenerationID: Int64; const APath, ARangeJSON,
      AKind, APayload, AVerification: string): Int64;
    procedure AddRelationship(AGenerationID, AFromEntityID, AToEntityID,
      AEvidenceID: Int64; const AKind, AResolution, ACondition: string);
    function AddFlowNode(AGenerationID,ARoutineEntityID: Int64; const AKind,ARangeJSON,AExpression: string): Int64;
    procedure AddFlowEdge(AGenerationID,AFromNode,AToNode: Int64; const AKind,AResolution: string);
    function PublishGeneration(AGenerationID: Int64; const ARevalidatedFiles: TDPHManifest;
      const ACompletenessJSON: string; AAnalysisComplete: Boolean): Boolean;
    procedure FailGeneration(AGenerationID: Int64; const AReason: string);
    procedure RequestReassessment;
    function AddManualNote(const ATitle, ABody, AEditor: string; AEntityID: Int64 = 0): Int64;
    function Status: TDPHProjectStatus;
    procedure BackupTo(const ADestination: string);
    function IntegrityCheck: string;
    function SQLiteVersion: string;
    function SupportsFTS5: Boolean;
    class function ProjectRoot(const ADatabasePath: string): string; static;
    procedure SaveWorkspaceView(AGenerationID: Int64; const AJSON: string);
    function LoadWorkspaceView(AGenerationID: Int64 = 0; ASkipGenerationParse: Boolean = False): string;
    procedure RelocateSource(const ANewRoot: string; AGenerationID: Int64; const AVerifiedManifest: TDPHManifest);
    procedure BeginFacts(AGenerationID: Int64);
    procedure CommitFacts;
    procedure RollbackFacts;
    function SaveKnowledge(AKnowledgeID,AExpectedRevision,AGenerationID: Int64;
      const ATitle,ABody,AEditor,AKind,AEntityKey: string; const ADocumentKind: string = ''; const AAudience: string = ''; const ALinksJSON: string = ''; const AQuestionJSON: string = ''; const AStructuredJSON: string = ''): Int64;
    procedure ReviewKnowledge(AKnowledgeID,AExpectedRevision,AGenerationID: Int64;
      const AReviewer,AState: string);
    function KnowledgeJSON: TJSONArray;
    function LoadTranslation(const AKey: string): TJSONObject;
    function TranslationEntries(ARevision: Int64): TJSONArray;
    procedure SaveTranslation(AEntry: TJSONObject);
    procedure ReviewTranslation(const AKey,AReviewer: string);
    function LinkCandidates(AGeneration: Int64; const AKind: string; const AQuery: string = ''): TJSONArray;
    function ReviewTasks(AGeneration: Int64): TJSONArray;
    procedure RecordExport(AGenerationID: Int64; const ADirectory,ACanonicalHash,AScope: string; AStale: Boolean);
    function GenerationIsStale(AGenerationID: Int64): Boolean;
    procedure ImportScreenshot(AGenerationID: Int64; const AFile,AAuthor,ACaption,AEntityKey: string; const AImageKind:string='Screenshot');
    function ScreenshotsJSON: TJSONArray;
    function ImportDataQualityReport(AGenerationID:Int64;const AFile,AAuthor,AContext:string):Int64;
    procedure ImportObservation(AGenerationID: Int64; const AFile,AAuthor,AContext,AEntityKey: string);
    function ObservationsJSON: TJSONArray;
    function RetentionReport(ARecent: Integer): TJSONArray;
    function RecentRetentionCount: Integer;
    procedure ApplyRetention(ARecent: Integer);
    procedure RetainGeneration(AGeneration: Int64; const ALabel,AReviewer: string);
    function ContinuityCandidates(AGeneration: Int64; const AQuery: string): TJSONArray;
    procedure ApproveContinuity(AKnowledge,AExpectedRevision,AGeneration: Int64;
      const AOldKey,ANewKey,AReviewer: string);
    function ManagedArtifactPaths: TArray<string>;
    procedure BuildSearchIndex(AGeneration: Int64);
    function SearchProject(AGeneration: Int64; const AQuery,AKind: string; AOffset: Integer): TJSONArray;
    property DatabasePath: string read FDatabasePath;
    property SourceRoot: string read FSourceRoot;
  end;

implementation

uses
  System.IOUtils, System.Hash, System.StrUtils, System.DateUtils,
  System.Generics.Defaults, Data.DB, FireDAC.Stan.Def, FireDAC.Stan.Async, FireDAC.Stan.Param,
  FireDAC.DApt, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef,
  FireDAC.Phys.SQLiteWrapper.Stat, System.RegularExpressions, DPH.Knowledge.ProjectProfile, DPH.Knowledge.Glossary, DPH.Knowledge.ComponentDependency, DPH.Knowledge.ActionPurpose,DPH.Workspace.DatabaseSchema,DPH.Workspace.Model;

const
  CurrentSchemaVersion = 9;
  RichLinkProjectionSQL = 'SELECT l.target_kind,l.target_id,l.source_generation,l.link_role,l.label,'+
    'coalesce(e.canonical_key,a.canonical_key,'''') AS canonical_key,coalesce(b.canonical_key,'''') AS to_key,coalesce(ev.source_range_json,''{}'') AS source_range,'+
    'coalesce(ev.payload_ref,'''') AS evidence_payload,coalesce(rel.resolution_status,CASE WHEN ev.verification_state=''verified'' THEN ''confirmed_static'' ELSE ev.verification_state END,''inferred'') AS resolution,'+
    'coalesce(rel.relation_kind,ev.evidence_kind,l.target_kind) AS kind,coalesce(kr.knowledge_id,0) AS knowledge_id,'+
    'coalesce(art.content_hash,'''') AS screenshot_hash '+
    'FROM knowledge_revision_links l LEFT JOIN entities e ON l.target_kind=''entity'' AND e.entity_id=l.target_id '+
    'LEFT JOIN relationships rel ON l.target_kind=''relationship'' AND rel.relationship_id=l.target_id '+
    'LEFT JOIN entities a ON a.entity_id=rel.from_entity_id '+
    'LEFT JOIN entities b ON b.entity_id=rel.to_entity_id '+
    'LEFT JOIN evidence ev ON ev.evidence_id=CASE WHEN l.target_kind=''evidence'' THEN l.target_id ELSE rel.evidence_id END '+
    'LEFT JOIN knowledge_revisions kr ON l.target_kind=''section'' AND kr.knowledge_revision_id=l.target_id '+
    'LEFT JOIN artifacts art ON l.target_kind=''screenshot'' AND art.artifact_id=l.target_id WHERE l.revision_id=:revision ORDER BY l.ordinal';

constructor TDPHKnowledgeStore.Create(const ADatabasePath, ASourceRoot,
  AMigrationDirectory: string; AUseWAL: Boolean);
var
  MutexName: string;
begin
  inherited Create;
  FThreadID := GetCurrentThreadID;
  FWriteQueue := TThreadedQueue<TProc<TDPHKnowledgeStore>>.Create(256,0,0);
  FDatabasePath := TPath.GetFullPath(ADatabasePath);
  FSourceRoot := IncludeTrailingPathDelimiter(TPath.GetFullPath(ASourceRoot));
  CheckOutsideSource(FDatabasePath);
  if AUseWAL and FDatabasePath.StartsWith('\\') then
    raise EDPHStorage.Create('WAL requires an approved local database location');
  MutexName := 'Local\DPH.Writer.' + THashSHA2.GetHashString(LowerCase(FDatabasePath));
  FWriterMutex := CreateMutex(nil, True, PChar(MutexName));
  if FWriterMutex = 0 then RaiseLastOSError;
  if GetLastError = ERROR_ALREADY_EXISTS then
  begin
    CloseHandle(FWriterMutex);
    FWriterMutex := 0;
    raise EDPHStorage.Create('A DPH writer already owns this knowledge store');
  end;
  FConnection := TFDConnection.Create(nil);
  FConnection.LoginPrompt := False;
  FConnection.Params.Values['DriverID'] := 'SQLite';
  FConnection.Params.Values['Database'] := FDatabasePath;
  FConnection.Params.Values['LockingMode'] := 'Normal';
  FConnection.Params.Values['SharedCache'] := 'False';
  if AUseWAL then FConnection.Params.Values['JournalMode'] := 'WAL'
  else FConnection.Params.Values['JournalMode'] := 'Delete';
  FConnection.Params.Values['BusyTimeout'] := '3000';
  FConnection.UpdateOptions.LockWait := True;
  FConnection.Params.Values['ForeignKeys'] := 'On';
  FConnection.Connected := True;
  if Scalar('PRAGMA user_version', []) > CurrentSchemaVersion then
    raise EDPHStorage.Create('Database requires a newer DPH schema');
  if Scalar('SELECT count(*) FROM sqlite_master WHERE type=''table'' AND name=''projects''',[]) = 1 then
    if not SameText(VarToStr(Scalar('SELECT root_uri FROM projects WHERE project_id=1',[])),FSourceRoot) and
      (Scalar('SELECT count(*) FROM projects',[]) <> 0) then
      raise EDPHStorage.Create('Knowledge store belongs to a different source root; relocation requires review');
  FConnection.ExecSQL('PRAGMA foreign_keys=ON');
  if Scalar('PRAGMA foreign_keys', []) <> 1 then
    raise EDPHStorage.Create('SQLite foreign key enforcement is unavailable');
  if AUseWAL then
    FConnection.ExecSQL('PRAGMA journal_mode=WAL')
  else
    FConnection.ExecSQL('PRAGMA journal_mode=DELETE');
  FConnection.ExecSQL('PRAGMA synchronous=FULL');
  ApplyMigrations(AMigrationDirectory);
  if IntegrityCheck <> 'ok' then raise EDPHStorage.Create('Database integrity check failed');
  FConnection.StartTransaction;
  try
    FConnection.ExecSQL('UPDATE project_state SET analysis_failed=1,analysis_stale=1 '+
      'WHERE project_id IN (SELECT project_id FROM analysis_generations WHERE status=''running'')');
    FConnection.ExecSQL('INSERT INTO diagnostics(project_id,generation_id,severity,code,message) '+
      'SELECT project_id,generation_id,''error'',''INTERRUPTED'',''Previous writer stopped before publication'' '+
      'FROM analysis_generations WHERE status=''running''');
    FConnection.ExecSQL('UPDATE analysis_generations SET status=''failed'',completed_at=:stamp '+
      'WHERE status=''running''', [UTCNow]);
    FConnection.Commit;
  except
    FConnection.Rollback;
    raise;
  end;
  FReady := True;
end;

destructor TDPHKnowledgeStore.Destroy;
begin
  try
    if FReady then
    begin
      TInterlocked.Exchange(FClosing,1);
      FWriteQueue.DoShutDown;
      ProcessQueuedWrites;
    end;
  finally
    FWriteQueue.Free;
    FConnection.Free;
    if FWriterMutex <> 0 then
    begin
      ReleaseMutex(FWriterMutex);
      CloseHandle(FWriterMutex);
    end;
    inherited;
  end;
end;

procedure TDPHKnowledgeStore.QueueWrite(const AWrite: TProc<TDPHKnowledgeStore>);
begin
  if TInterlocked.CompareExchange(FClosing,0,0) <> 0 then
    raise EDPHStorage.Create('Knowledge store is closing');
  if not Assigned(AWrite) then raise EDPHStorage.Create('Write command is empty');
  if FWriteQueue.PushItem(AWrite) <> wrSignaled then
    raise EDPHStorage.Create('Write queue is full; command was not accepted');
end;

procedure TDPHKnowledgeStore.ProcessQueuedWrites;
var
  WriteCommand: TProc<TDPHKnowledgeStore>;
begin
  RequireWriter;
  while FWriteQueue.PopItem(WriteCommand) = wrSignaled do
  begin
    if not Assigned(WriteCommand) then Break;
    WriteCommand(Self);
    WriteCommand := nil;
  end;
end;

procedure TDPHKnowledgeStore.RequireWriter;
begin
  if GetCurrentThreadID <> FThreadID then
    raise EDPHStorage.Create('Queue work to the owning storage thread');
end;

procedure TDPHKnowledgeStore.CheckOutsideSource(const APath: string);
var
  FullPath, CheckedPath, ParentPath, NextParent: string;
  Attributes: Cardinal;
begin
  FullPath := TPath.GetFullPath(APath);
  if SameText(ExcludeTrailingPathDelimiter(FSourceRoot), FullPath) or
     StartsText(FSourceRoot, FullPath) then
    raise EDPHStorage.Create('Knowledge stores and backups must be outside selected source');
  for CheckedPath in TArray<string>.Create(FullPath,ExcludeTrailingPathDelimiter(FSourceRoot)) do
  begin
    ParentPath := CheckedPath;
    while ParentPath <> '' do
    begin
      Attributes := GetFileAttributes(PChar(ParentPath));
      if (Attributes <> INVALID_FILE_ATTRIBUTES) and
        ((Attributes and FILE_ATTRIBUTE_REPARSE_POINT) <> 0) then
        raise EDPHStorage.Create('Reparse-point paths require an explicitly resolved source boundary');
      NextParent := TPath.GetDirectoryName(ParentPath);
      if SameText(NextParent,ParentPath) then Break;
      ParentPath := NextParent;
    end;
  end;
end;

function TDPHKnowledgeStore.UTCNow: string;
begin
  Result := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz"Z"',
    TTimeZone.Local.ToUniversalTime(Now));
end;

function TDPHKnowledgeStore.NewQuery(const ASQL: string;
  const AValues: array of Variant): TFDQuery;
var
  I: Integer;
begin
  Result := TFDQuery.Create(nil);
  try
    Result.Connection := FConnection;
    Result.SQL.Text := ASQL;
    for I := 0 to High(AValues) do Result.Params[I].Value := AValues[I];
    Result.Open;
  except
    Result.Free;
    raise;
  end;
end;

function TDPHKnowledgeStore.Scalar(const ASQL: string;
  const AValues: array of Variant): Variant;
var
  Query: TFDQuery;
begin
  Query := NewQuery(ASQL, AValues);
  try
    if Query.Eof then Result := Null else Result := Query.Fields[0].Value;
  finally
    Query.Free;
  end;
end;

procedure TDPHKnowledgeStore.ApplyMigrations(const AMigrationDirectory: string);
var
  Version, AppliedVersion: Integer;
  MigrationPath, Checksum, SQLText, StatementText: string;
  ExistingSchema, NeedsUpgradeBackup: Boolean;
begin
  AppliedVersion := Scalar('PRAGMA user_version', []);
  NeedsUpgradeBackup := AppliedVersion > 0;
  if AppliedVersion > CurrentSchemaVersion then
    raise EDPHStorage.Create('Database requires a newer DPH schema');
  ExistingSchema := Scalar('SELECT count(*) FROM sqlite_master WHERE type=''table'' '+
    'AND name=''schema_migrations''', []) = 1;
  if (AppliedVersion > 0) and not ExistingSchema then
    raise EDPHStorage.Create('Migration ledger is missing');
  if ExistingSchema then
  begin
    if Scalar('SELECT count(*) FROM schema_migrations', []) <> AppliedVersion then
      raise EDPHStorage.Create('Migration ledger version mismatch');
  end
  else if Scalar('SELECT count(*) FROM sqlite_master WHERE type=''table'' '+
    'AND name NOT LIKE ''sqlite_%''', []) <> 0 then
    raise EDPHStorage.Create('Not an empty or recognized DPH database');
  for Version := 1 to CurrentSchemaVersion do
  begin
    MigrationPath := TPath.Combine(AMigrationDirectory,
      Format('%.3d_', [Version]));
    if Version = 1 then MigrationPath := MigrationPath + 'foundation.sql'
    else if Version = 2 then MigrationPath := MigrationPath + 'constraints.sql'
    else if Version = 3 then MigrationPath := MigrationPath + 'lifecycle.sql'
    else if Version = 4 then MigrationPath := MigrationPath + 'search.sql'
    else if Version = 5 then MigrationPath := MigrationPath + 'document_sections.sql'
    else if Version = 6 then MigrationPath := MigrationPath + 'revision_links.sql'
    else if Version = 7 then MigrationPath := MigrationPath + 'author_questions.sql'
      else if Version = 8 then MigrationPath := MigrationPath + 'translation_cache.sql'
      else MigrationPath := MigrationPath + 'structured_knowledge.sql';
    Checksum := THashSHA2.GetHashStringFromFile(MigrationPath);
    if Version <= AppliedVersion then
    begin
      if VarToStr(Scalar('SELECT checksum FROM schema_migrations WHERE version=:version',
        [Version])) <> Checksum then
        raise EDPHStorage.Create('Migration checksum mismatch');
      Continue;
    end;
    if NeedsUpgradeBackup then
    begin
      BackupTo(FDatabasePath + '.pre-v' + IntToStr(Version) + '-' +
        TGUID.NewGuid.ToString + '.dphdb');
      NeedsUpgradeBackup := False;
    end;
    SQLText := TFile.ReadAllText(MigrationPath, TEncoding.UTF8);
    FConnection.StartTransaction;
    try
      if not ExistingSchema then
        FConnection.ExecSQL('CREATE TABLE schema_migrations(version INTEGER PRIMARY KEY,'+
          'applied_at TEXT NOT NULL,checksum TEXT NOT NULL CHECK(length(checksum)=64))');
      for StatementText in SQLText.Split(['-- DPH STATEMENT']) do
        if Trim(StatementText) <> '' then FConnection.ExecSQL(StatementText);
      FConnection.ExecSQL('INSERT INTO schema_migrations(version,applied_at,checksum) '+
        'VALUES(:version,:stamp,:checksum)', [Version, UTCNow, Checksum]);
      FConnection.ExecSQL('PRAGMA user_version=' + IntToStr(Version));
      FConnection.Commit;
      ExistingSchema := True;
      AppliedVersion := Version;
    except
      FConnection.Rollback;
      raise;
    end;
  end;
end;

class function TDPHKnowledgeStore.ManifestHash(const AFiles: TDPHManifest): string;
var
  SortedFiles: TDPHManifest;
  FileEntry: TDPHManifestFile;
  CanonicalJSON: TJSONArray;
  Row: TJSONArray;
  PreviousPath: string;
  C: Char;
begin
  SortedFiles := Copy(AFiles);
  TArray.Sort<TDPHManifestFile>(SortedFiles,
    TComparer<TDPHManifestFile>.Construct(
      function(const Left, Right: TDPHManifestFile): Integer
      begin Result := CompareStr(Left.RelativePath, Right.RelativePath); end));
  CanonicalJSON := TJSONArray.Create;
  try
    PreviousPath := '';
    for FileEntry in SortedFiles do
    begin
      if (FileEntry.RelativePath = '') or (FileEntry.RelativePath = PreviousPath) or
        (FileEntry.RelativePath <> LowerCase(FileEntry.RelativePath)) or
        FileEntry.RelativePath.StartsWith('/') or FileEntry.RelativePath.EndsWith('/') or
        FileEntry.RelativePath.Contains('\') or FileEntry.RelativePath.Contains(':') or
        FileEntry.RelativePath.Contains('//') or
        ('/' + FileEntry.RelativePath + '/').Contains('/../') or
        ('/' + FileEntry.RelativePath + '/').Contains('/./') or
        (FileEntry.SizeBytes < 0) then
        raise EDPHStorage.Create('Invalid or duplicate canonical project-relative path');
      for C in FileEntry.RelativePath do
        if Ord(C) < 32 then raise EDPHStorage.Create('Control character in path');
      if FileEntry.Availability = 'available' then
      begin
        if Length(FileEntry.SHA256) <> 64 then raise EDPHStorage.Create('Invalid source hash');
        for C in FileEntry.SHA256 do
          if not CharInSet(C, ['0'..'9','a'..'f']) then raise EDPHStorage.Create('Invalid source hash');
      end
      else if not ((FileEntry.Availability = 'missing') or
        (FileEntry.Availability = 'excluded') or (FileEntry.Availability = 'unreadable')) or
        (FileEntry.SHA256 <> '') then raise EDPHStorage.Create('Invalid availability/hash combination');
      Row := TJSONArray.Create;
      Row.Add(FileEntry.RelativePath);
      Row.Add(FileEntry.SHA256);
      Row.Add(FileEntry.SizeBytes);
      Row.Add(FileEntry.Kind);
      Row.Add(FileEntry.Encoding);
      Row.Add(FileEntry.Availability);
      CanonicalJSON.AddElement(Row);
      PreviousPath := FileEntry.RelativePath;
    end;
    Result := THashSHA2.GetHashString(CanonicalJSON.ToJSON);
  finally CanonicalJSON.Free; end;
end;

procedure TDPHKnowledgeStore.InitializeProject(const AName, AProjectKind: string);
begin
  RequireWriter;
  FConnection.StartTransaction;
  try
    FConnection.ExecSQL('INSERT OR IGNORE INTO projects(project_id,name,root_uri,project_kind,created_at,last_opened_at) '+
      'VALUES(1,:name,:root,:kind,:created,:opened)', [AName,FSourceRoot,AProjectKind,UTCNow,UTCNow]);
    if not SameText(VarToStr(Scalar('SELECT root_uri FROM projects WHERE project_id=1', [])),FSourceRoot) then
      raise EDPHStorage.Create('Knowledge store belongs to a different source root; relocation requires review');
    FConnection.ExecSQL('INSERT OR IGNORE INTO project_state(project_id) VALUES(1)');
    FConnection.ExecSQL('UPDATE projects SET last_opened_at=:stamp WHERE project_id=1',[UTCNow]);
    FConnection.Commit;
  except FConnection.Rollback; raise; end;
end;

function TDPHKnowledgeStore.AddConfiguration(const APlatform, ACompiler,
  ADefinesJSON, ASearchPathsJSON, AEnvironment: string): Int64;
var
  ConfigurationJSON: TJSONArray;
  Fingerprint: string;
begin
  RequireWriter;
  ConfigurationJSON := TJSONArray.Create;
  try
    ConfigurationJSON.Add(APlatform); ConfigurationJSON.Add(ACompiler);
    ConfigurationJSON.Add(ADefinesJSON); ConfigurationJSON.Add(ASearchPathsJSON);
    ConfigurationJSON.Add(AEnvironment);
    Fingerprint := THashSHA2.GetHashString(ConfigurationJSON.ToJSON);
  finally ConfigurationJSON.Free; end;
  FConnection.ExecSQL('INSERT OR IGNORE INTO configurations(project_id,platform,compiler,defines_json,'+
    'search_paths_json,environment_label,fingerprint) VALUES(1,:platform,:compiler,:defines,:paths,:environment,:fingerprint)',
    [APlatform,ACompiler,ADefinesJSON,ASearchPathsJSON,AEnvironment,Fingerprint]);
  Result := Scalar('SELECT config_id FROM configurations WHERE project_id=1 AND fingerprint=:hash',[Fingerprint]);
end;

procedure TDPHKnowledgeStore.SelectConfiguration(AConfigurationID: Int64);
begin
  RequireWriter;
  FConnection.StartTransaction;
  try
    if Scalar('SELECT count(*) FROM configurations WHERE project_id=1 AND config_id=:config',[AConfigurationID]) <> 1 then
      raise EDPHStorage.Create('Unknown configuration');
    if VarToStr(Scalar('SELECT coalesce(active_config,0) FROM projects WHERE project_id=1',[]))<>IntToStr(AConfigurationID) then
    begin
      FConnection.ExecSQL('INSERT INTO review_tasks(project_id,knowledge_id,reason,state,opened_generation_id) '+
        'SELECT 1,knowledge_id,''Configuration changed'',''pending'',(SELECT published_generation_id FROM project_state WHERE project_id=1) FROM knowledge_records k '+
        'WHERE state NOT IN (''retired'',''rejected'') AND NOT EXISTS(SELECT 1 FROM review_tasks t WHERE t.knowledge_id=k.knowledge_id AND t.state=''pending'')');
      FConnection.ExecSQL('UPDATE knowledge_records SET state=''needs_review'' WHERE state IN (''verified'',''inferred'')');
      FConnection.ExecSQL('UPDATE project_state SET knowledge_review_needed=EXISTS(SELECT 1 FROM review_tasks WHERE state=''pending'') WHERE project_id=1');
      FConnection.ExecSQL('UPDATE artifacts SET build_state=''stale'' WHERE kind<>''workspace_view''');
      FConnection.ExecSQL('UPDATE translations SET translation_state=''needs_review''');
    end;
    FConnection.ExecSQL('UPDATE project_state SET analysis_stale=1 WHERE project_id=1 AND EXISTS '+
      '(SELECT 1 FROM projects WHERE project_id=1 AND (active_config IS NULL OR active_config<>:config))',[AConfigurationID]);
    FConnection.ExecSQL('UPDATE projects SET active_config=:config WHERE project_id=1',[AConfigurationID]);
    FConnection.Commit;
  except FConnection.Rollback; raise; end;
end;

function TDPHKnowledgeStore.ReadManifest(AGenerationID: Int64): TDPHManifest;
var
  Query: TFDQuery;
  Entry: TDPHManifestFile;
  Items: TList<TDPHManifestFile>;
begin
  if AGenerationID = 0 then
    Query := NewQuery('SELECT canonical_relpath,coalesce(current_observed_hash,'''') AS hash,'+
      'observed_size,kind,encoding,availability_status FROM source_files WHERE project_id=1 AND in_manifest=1', [])
  else
    Query := NewQuery('SELECT sf.canonical_relpath,gf.captured_hash,gf.captured_size,gf.kind,gf.encoding,gf.availability '+
      'FROM generation_files gf JOIN source_files sf ON sf.file_id=gf.file_id WHERE gf.generation_id=:id',[AGenerationID]);
  Items := TList<TDPHManifestFile>.Create;
  try
    while not Query.Eof do
    begin
      Entry.RelativePath := Query.Fields[0].AsString; Entry.SHA256 := Query.Fields[1].AsString;
      Entry.SizeBytes := Query.Fields[2].AsLargeInt; Entry.Kind := Query.Fields[3].AsString;
      Entry.Encoding := Query.Fields[4].AsString; Entry.Availability := Query.Fields[5].AsString;
      Items.Add(Entry); Query.Next;
    end;
    Result := Items.ToArray;
  finally Items.Free; Query.Free; end;
end;

procedure TDPHKnowledgeStore.ObserveManifest(const AFiles: TDPHManifest);
var
  Entry: TDPHManifestFile;
  OldHash, NewHash: string;
begin
  RequireWriter;
  NewHash := ManifestHash(AFiles);
  FConnection.StartTransaction;
  try
    OldHash := ManifestHash(ReadManifest);
    if OldHash <> NewHash then
    begin
      FConnection.ExecSQL('UPDATE source_files SET in_manifest=0 WHERE project_id=1');
      for Entry in AFiles do
        FConnection.ExecSQL('INSERT INTO source_files(project_id,canonical_relpath,kind,current_observed_hash,'+
          'availability_status,reassessment_flag,encoding,observed_size) VALUES(1,:path,:kind,:hash,:availability,1,:encoding,:size) '+
          'ON CONFLICT(project_id,canonical_relpath) DO UPDATE SET reassessment_flag=CASE WHEN '+
          'coalesce(source_files.current_observed_hash,'''')<>excluded.current_observed_hash '+
          'OR source_files.availability_status<>excluded.availability_status '+
          'OR source_files.observed_size<>excluded.observed_size OR source_files.kind<>excluded.kind '+
          'OR source_files.encoding<>excluded.encoding THEN 1 ELSE source_files.reassessment_flag END,kind=excluded.kind,'+
          'current_observed_hash=excluded.current_observed_hash,availability_status=excluded.availability_status,'+
          'encoding=excluded.encoding,observed_size=excluded.observed_size,in_manifest=1',
          [Entry.RelativePath,Entry.Kind,Entry.SHA256,Entry.Availability,Entry.Encoding,Entry.SizeBytes]);
      FConnection.ExecSQL('UPDATE source_files SET availability_status=''missing'',current_observed_hash='''','+
        'observed_size=0,reassessment_flag=1 WHERE project_id=1 AND in_manifest=0 AND availability_status<>''missing''');
      FConnection.ExecSQL('UPDATE project_state SET modification_detected=1,analysis_stale=1 WHERE project_id=1');
      FConnection.ExecSQL('INSERT INTO review_tasks(project_id,knowledge_id,reason,state,opened_generation_id) '+
        'SELECT project_id,knowledge_id,''Source manifest changed'',''pending'', '+
        '(SELECT published_generation_id FROM project_state WHERE project_id=1) FROM knowledge_records '+
        'WHERE state NOT IN (''retired'',''rejected'') AND NOT EXISTS '+
        '(SELECT 1 FROM review_tasks t WHERE t.knowledge_id=knowledge_records.knowledge_id AND t.state=''pending'')');
      FConnection.ExecSQL('UPDATE knowledge_records SET state=''needs_review'' WHERE state IN (''verified'',''inferred'')');
      FConnection.ExecSQL('UPDATE artifacts SET build_state=''stale'' WHERE kind<>''workspace_view''');
      FConnection.ExecSQL('UPDATE translations SET translation_state=''needs_review''');
      FConnection.ExecSQL('UPDATE project_state SET knowledge_review_needed=EXISTS '+
        '(SELECT 1 FROM review_tasks WHERE state=''pending'') WHERE project_id=1');
    end;
    FConnection.Commit;
  except FConnection.Rollback; raise; end;
end;

procedure TDPHKnowledgeStore.RequireRunning(AGenerationID: Int64);
begin
  RequireWriter;
  if VarToStr(Scalar('SELECT status FROM analysis_generations WHERE generation_id=:id AND project_id=1',
    [AGenerationID])) <> 'running' then raise EDPHStorage.Create('Generation is not running');
end;

function TDPHKnowledgeStore.BeginGeneration(AConfigurationID: Int64;
  const AAnalyzerVersion: string; const AFiles: TDPHManifest): Int64;
var
  Entry: TDPHManifestFile;
  Hash, ConfigHash: string;
  FileID: Int64;
  RevisionID: Variant;
begin
  RequireWriter;
  Hash := ManifestHash(AFiles);
  FConnection.StartTransaction;
  try
    if Scalar('SELECT count(*) FROM analysis_generations WHERE status=''running''',[]) <> 0 then
      raise EDPHStorage.Create('Finish the current generation before beginning another');
    if Hash <> ManifestHash(ReadManifest) then raise EDPHStorage.Create('Capture does not match observed manifest');
    if Scalar('SELECT active_config FROM projects WHERE project_id=1',[]) <> AConfigurationID then
      raise EDPHStorage.Create('Capture configuration is not selected');
    ConfigHash := VarToStr(Scalar('SELECT fingerprint FROM configurations WHERE config_id=:id',[AConfigurationID]));
    FConnection.ExecSQL('INSERT INTO analysis_generations(project_id,config_id,started_at,analyzer_version,'+
      'config_fingerprint,manifest_hash,status,previous_generation_id) '+
      'SELECT 1,:config,:stamp,:analyzer,:fingerprint,:manifest,''running'',published_generation_id FROM project_state WHERE project_id=1',
      [AConfigurationID,UTCNow,AAnalyzerVersion,ConfigHash,Hash]);
    Result := Scalar('SELECT last_insert_rowid()',[]);
    for Entry in AFiles do
    begin
      FileID := Scalar('SELECT file_id FROM source_files WHERE project_id=1 AND canonical_relpath=:path',[Entry.RelativePath]);
      RevisionID := Int64(0);
      if Entry.Availability = 'available' then
      begin
        FConnection.ExecSQL('INSERT OR IGNORE INTO file_revisions(project_id,file_id,sha256,size_bytes,revision_time,source_generation_id) '+
          'VALUES(1,:file,:hash,:size,:stamp,:generation)',[FileID,Entry.SHA256,Entry.SizeBytes,UTCNow,Result]);
        RevisionID := Scalar('SELECT file_revision_id FROM file_revisions WHERE file_id=:file AND sha256=:hash',[FileID,Entry.SHA256]);
      end;
      FConnection.ExecSQL('INSERT INTO generation_files(generation_id,project_id,file_id,file_revision_id,captured_hash,'+
        'captured_size,availability,kind,encoding) VALUES(:generation,1,:file,NULLIF(:revision,0),:hash,:size,:availability,:kind,:encoding)',
        [Result,FileID,RevisionID,Entry.SHA256,Entry.SizeBytes,Entry.Availability,Entry.Kind,Entry.Encoding]);
    end;
    FConnection.ExecSQL('UPDATE project_state SET analysis_stale=1 WHERE project_id=1');
    FConnection.Commit;
  except FConnection.Rollback; raise; end;
end;

function TDPHKnowledgeStore.AddSourceEntity(AGenerationID: Int64;
  const APath, AKey, AKind, AName, ASignature: string; AStartOffset, AEndOffset: Int64;
  const AStructuralJSON: string): Int64;
var
  Query: TFDQuery;
  FileID, RevisionID: Int64;
    OwnTransaction: Boolean;
begin
  RequireRunning(AGenerationID);
  if Scalar('SELECT json_valid(:value)',[AStructuralJSON])<>1 then raise EDPHStorage.Create('Invalid structural JSON');
  Query := NewQuery('SELECT gf.file_id,gf.file_revision_id,fr.size_bytes FROM generation_files gf '+
    'JOIN source_files sf ON sf.file_id=gf.file_id JOIN file_revisions fr ON fr.file_revision_id=gf.file_revision_id '+
    'WHERE gf.generation_id=:generation AND sf.canonical_relpath=:path',[AGenerationID,APath]);
  try
    if Query.Eof then raise EDPHStorage.Create('Entity source is not captured');
    if (AStartOffset < 0) or (AEndOffset < AStartOffset) or (AEndOffset > Query.Fields[2].AsLargeInt) then
      raise EDPHStorage.Create('Entity source range is outside captured bytes');
    FileID := Query.Fields[0].AsLargeInt; RevisionID := Query.Fields[1].AsLargeInt;
  finally Query.Free; end;
  OwnTransaction:=not FConnection.InTransaction;
  if OwnTransaction then FConnection.StartTransaction;
  try
    FConnection.ExecSQL('INSERT OR IGNORE INTO entities(project_id,entity_kind,canonical_key,display_name,owner_file_id) '+
      'VALUES(1,:kind,:key,:name,:file)',[AKind,AKey,AName,FileID]);
    Result := Scalar('SELECT entity_id FROM entities WHERE project_id=1 AND entity_kind=:kind AND canonical_key=:key',[AKind,AKey]);
    if Scalar('SELECT owner_file_id FROM entities WHERE entity_id=:id',[Result]) <> FileID then
      raise EDPHStorage.Create('Entity moved between files; continuity requires review');
    FConnection.ExecSQL('INSERT INTO entity_versions(entity_id,project_id,generation_id,signature,structural_json,'+
      'source_revision_id,start_offset,end_offset,analysis_status) VALUES(:entity,1,:generation,:signature,:structure,:revision,:start,:finish,''partial'')',
      [Result,AGenerationID,ASignature,AStructuralJSON,RevisionID,AStartOffset,AEndOffset]);
    if OwnTransaction then FConnection.Commit;
  except if OwnTransaction then FConnection.Rollback; raise; end;
end;

procedure TDPHKnowledgeStore.AddDiagnostic(AGenerationID: Int64;
  const ASeverity,ACode,AMessage,ARangeJSON: string);
begin
  RequireRunning(AGenerationID);
  if Scalar('SELECT json_valid(:value)',[ARangeJSON])<>1 then raise EDPHStorage.Create('Invalid diagnostic range JSON');
  FConnection.ExecSQL('INSERT INTO diagnostics(project_id,generation_id,severity,code,message,source_range_json) '+
    'VALUES(1,:generation,:severity,:code,:message,:range)',[AGenerationID,ASeverity,ACode,AMessage,ARangeJSON]);
end;

function TDPHKnowledgeStore.AddEvidence(AGenerationID: Int64;
  const APath, ARangeJSON, AKind, APayload, AVerification: string): Int64;
var
  RevisionID: Variant;
begin
  RequireRunning(AGenerationID);
  RevisionID := Scalar('SELECT gf.file_revision_id FROM generation_files gf JOIN source_files sf ON sf.file_id=gf.file_id '+
    'WHERE gf.generation_id=:generation AND sf.canonical_relpath=:path',[AGenerationID,APath]);
  if VarIsNull(RevisionID) then raise EDPHStorage.Create('Evidence source is not captured');
  FConnection.ExecSQL('INSERT INTO evidence(project_id,generation_id,file_revision_id,source_range_json,evidence_kind,'+
    'payload_ref,analyzer_version,capture_time,verification_state) '+
    'SELECT 1,:generation,:revision,:range,:kind,:payload,analyzer_version,:stamp,:state FROM analysis_generations WHERE generation_id=:id',
    [AGenerationID,RevisionID,ARangeJSON,AKind,APayload,UTCNow,AVerification,AGenerationID]);
  Result := Scalar('SELECT last_insert_rowid()',[]);
end;

procedure TDPHKnowledgeStore.AddRelationship(AGenerationID, AFromEntityID,
  AToEntityID, AEvidenceID: Int64; const AKind, AResolution, ACondition: string);
begin
  RequireRunning(AGenerationID);
  FConnection.ExecSQL('INSERT INTO relationships(project_id,generation_id,from_entity_id,to_entity_id,'+
    'relation_kind,resolution_status,evidence_id,condition_variant) VALUES(1,:generation,:fromid,NULLIF(:toid,0),:kind,:resolution,:evidence,:condition)',
    [AGenerationID,AFromEntityID,AToEntityID,AKind,AResolution,AEvidenceID,ACondition]);
end;

function TDPHKnowledgeStore.AddFlowNode(AGenerationID,ARoutineEntityID: Int64; const AKind,ARangeJSON,AExpression: string): Int64;
var VersionID: Variant;
begin
  RequireRunning(AGenerationID);
  if Scalar('SELECT json_valid(:range)',[ARangeJSON])<>1 then raise EDPHStorage.Create('Invalid CFG range JSON');
  if Scalar('SELECT count(*) FROM generation_files gf JOIN source_files sf ON sf.file_id=gf.file_id '+
    'JOIN file_revisions fr ON fr.file_revision_id=gf.file_revision_id WHERE gf.generation_id=:generation '+
    'AND sf.canonical_relpath=json_extract(:range,''$.source'') AND json_type(:range,''$.start'')=''integer'' '+
    'AND json_type(:range,''$.end'')=''integer'' AND json_extract(:range,''$.start'')>=0 '+
    'AND json_extract(:range,''$.end'')>=json_extract(:range,''$.start'') AND json_extract(:range,''$.end'')<=fr.size_bytes',
    [AGenerationID,ARangeJSON])<>1 then
    raise EDPHStorage.Create('CFG range is outside captured source bytes');
  VersionID:=Scalar('SELECT entity_version_id FROM entity_versions WHERE entity_id=:entity AND generation_id=:generation',[ARoutineEntityID,AGenerationID]);
  if VarIsNull(VersionID) then raise EDPHStorage.Create('CFG routine does not belong to generation');
  FConnection.ExecSQL('INSERT INTO control_flow_nodes(routine_version_id,generation_id,node_kind,source_range_json,expression_ref) '+
    'VALUES(:routine,:generation,:kind,:range,:expression)',[VersionID,AGenerationID,AKind,ARangeJSON,AExpression]);
  Result:=Scalar('SELECT last_insert_rowid()',[]);
end;

procedure TDPHKnowledgeStore.AddFlowEdge(AGenerationID,AFromNode,AToNode: Int64; const AKind,AResolution: string);
begin
  RequireRunning(AGenerationID);
  if Scalar('SELECT count(*) FROM control_flow_nodes f JOIN control_flow_nodes t ON t.cfg_node_id=:toid '+
    'WHERE f.cfg_node_id=:fromid AND f.generation_id=:generation AND t.generation_id=f.generation_id '+
    'AND t.routine_version_id=f.routine_version_id',[AToNode,AFromNode,AGenerationID])<>1 then
    raise EDPHStorage.Create('CFG edge must stay within its routine and generation');
  if not MatchText(AResolution,['confirmed_static','possible_dynamic','inferred','unresolved']) then raise EDPHStorage.Create('Invalid CFG resolution');
  FConnection.ExecSQL('INSERT INTO control_flow_edges(generation_id,from_cfg_node_id,to_cfg_node_id,edge_kind,condition_ref) '+
    'VALUES(:generation,:fromid,:toid,:kind,:resolution)',[AGenerationID,AFromNode,AToNode,AKind,AResolution]);
end;

function TDPHKnowledgeStore.PublishGeneration(AGenerationID: Int64;
  const ARevalidatedFiles: TDPHManifest; const ACompletenessJSON: string; AAnalysisComplete: Boolean): Boolean;
var
  RevalidatedHash: string;
begin
  RequireRunning(AGenerationID);
  RevalidatedHash := ManifestHash(ARevalidatedFiles);
  FConnection.StartTransaction;
  try
    Result := (VarToStr(Scalar('SELECT manifest_hash FROM analysis_generations WHERE generation_id=:id',[AGenerationID])) = RevalidatedHash) and
      (ManifestHash(ReadManifest) = RevalidatedHash) and
      (ManifestHash(ReadManifest(AGenerationID)) = RevalidatedHash) and
      (Scalar('SELECT config_id FROM analysis_generations WHERE generation_id=:id',[AGenerationID]) =
       Scalar('SELECT active_config FROM projects WHERE project_id=1',[]));
    if not Result then
    begin
      FConnection.ExecSQL('UPDATE analysis_generations SET status=''superseded'',completed_at=:stamp WHERE generation_id=:id',[UTCNow,AGenerationID]);
      FConnection.ExecSQL('UPDATE project_state SET analysis_stale=1,modification_detected=1 WHERE project_id=1');
    end
    else
    begin
      if not AAnalysisComplete or (Scalar('SELECT count(*) FROM generation_files WHERE generation_id=:id AND availability IN (''missing'',''unreadable'')',
        [AGenerationID]) <> 0) then
      begin
        FConnection.ExecSQL('INSERT INTO diagnostics(project_id,generation_id,severity,code,message) '+
          'VALUES(1,:id,''warning'',''INCOMPLETE_ANALYSIS'',''Input unavailable or analyzer reports partial coverage'')',[AGenerationID]);
        FConnection.ExecSQL('UPDATE analysis_generations SET status=''partial'',completed_at=:stamp,completeness_summary_json=:summary '+
          'WHERE generation_id=:id',[UTCNow,ACompletenessJSON,AGenerationID]);
        FConnection.Commit;
        Exit(False);
      end;
      FConnection.ExecSQL('UPDATE source_files SET last_analyzed_hash=(SELECT gf.captured_hash FROM generation_files gf '+
        'WHERE gf.generation_id=:id AND gf.file_id=source_files.file_id),reassessment_flag=0 WHERE project_id=1',[AGenerationID]);
      FConnection.ExecSQL('UPDATE analysis_generations SET status=''current'',completed_at=:stamp,completeness_summary_json=:summary '+
        'WHERE generation_id=:id',[UTCNow,ACompletenessJSON,AGenerationID]);
      FConnection.ExecSQL('UPDATE project_state SET published_generation_id=:id,modification_detected=0,'+
        'analysis_stale=0,analysis_failed=0,reassessment_requested=0 WHERE project_id=1',[AGenerationID]);
    end;
    FConnection.Commit;
  except FConnection.Rollback; raise; end;
end;

procedure TDPHKnowledgeStore.FailGeneration(AGenerationID: Int64; const AReason: string);
begin
  RequireRunning(AGenerationID);
  FConnection.StartTransaction;
  try
    FConnection.ExecSQL('INSERT INTO diagnostics(project_id,generation_id,severity,code,message) VALUES(1,:id,''error'',''FAILED'',:reason)',[AGenerationID,AReason]);
    FConnection.ExecSQL('UPDATE analysis_generations SET status=''failed'',completed_at=:stamp WHERE generation_id=:id',[UTCNow,AGenerationID]);
    FConnection.ExecSQL('UPDATE project_state SET analysis_failed=1,analysis_stale=1 WHERE project_id=1');
    FConnection.Commit;
  except FConnection.Rollback; raise; end;
end;

procedure TDPHKnowledgeStore.RequestReassessment;
begin
  RequireWriter;
  FConnection.ExecSQL('UPDATE project_state SET reassessment_requested=1,analysis_stale=1 WHERE project_id=1');
end;

function TDPHKnowledgeStore.AddManualNote(const ATitle, ABody, AEditor: string; AEntityID: Int64): Int64;
var
  RevisionID: Int64;
begin
  RequireWriter;
  if AEditor.Trim = '' then raise EDPHStorage.Create('Manual knowledge requires attribution');
  FConnection.StartTransaction;
  try
    FConnection.ExecSQL('INSERT INTO knowledge_records(project_id,kind,title,source_language,state,owner) '+
      'VALUES(1,''note'',:title,''en'',''inferred'',:editor)',[ATitle,AEditor]);
    Result := Scalar('SELECT last_insert_rowid()',[]);
    FConnection.ExecSQL('INSERT INTO knowledge_revisions(knowledge_id,body_md,editor,created_at,verification_state) '+
      'VALUES(:note,:body,:editor,:stamp,''inferred'')',[Result,ABody,AEditor,UTCNow]);
    RevisionID := Scalar('SELECT last_insert_rowid()',[]);
    FConnection.ExecSQL('UPDATE knowledge_records SET current_revision_id=:revision WHERE knowledge_id=:note',[RevisionID,Result]);
    if AEntityID <> 0 then
      FConnection.ExecSQL('INSERT INTO knowledge_links(project_id,knowledge_id,entity_id,link_role) '+
        'VALUES(1,:note,:entity,''annotates'')',[Result,AEntityID]);
    FConnection.ExecSQL('INSERT INTO audit_events(project_id,entity_type,entity_id,action,actor,recorded_at,after_hash) '+
      'VALUES(1,''knowledge'',:note,''created'',:editor,:stamp,:hash)',[Result,AEditor,UTCNow,THashSHA2.GetHashString(ABody)]);
    FConnection.Commit;
  except FConnection.Rollback; raise; end;
end;

function TDPHKnowledgeStore.SaveKnowledge(AKnowledgeID,AExpectedRevision,AGenerationID: Int64;
  const ATitle,ABody,AEditor,AKind,AEntityKey: string; const ADocumentKind,AAudience,ALinksJSON,AQuestionJSON,AStructuredJSON: string): Int64;
var Revision,Entity,TargetID: Int64; Prior,DocumentKind,Audience,TargetKind,Role,LabelText,SQL: string;
  LinkRows,PictureRows: TJSONArray; Value,ParsedLinks: TJSONValue; LinkRow,Question: TJSONObject; Ordinal: Integer; QuestionID,PriorQuestion,ExpectedID,StructuredText,PriorStructured: string;PictureFound:Boolean;
  DictionaryView:TDPHWorkspaceView;DictionaryInventory,DictionaryExpected:TJSONObject;DictionaryValue:TJSONValue;DictionaryMatched:Boolean;
  StructuredValue,PriorRecord: TJSONValue; GlossaryQuery: TFDQuery; ExistingGlossary: TJSONObject;
  TermNames,ExistingNames: TArray<string>; GlossaryName,ExistingName,ActionIdentityField: string;
begin
  RequireWriter;
  if (ATitle.Trim='') or (ABody.Trim='') or (AEditor.Trim='') then raise EDPHStorage.Create('Title, text and named author are required');
  if Length(ABody)>1024*1024 then raise EDPHStorage.Create('Knowledge text exceeds 1 MiB');
  if not MatchText(AKind,['note','business_rule','engineering_rule','user_help','maintenance','build_deploy','troubleshooting','orientation','decision','unknown','glossary']) then raise EDPHStorage.Create('Unknown knowledge kind');
  DocumentKind:=ADocumentKind; Audience:=AAudience;
  if DocumentKind='' then begin DocumentKind:='engineering'; if AKind='user_help' then DocumentKind:='user'
    else if MatchText(AKind,['maintenance','build_deploy','troubleshooting','orientation']) then DocumentKind:=AKind; end;
  if Audience='' then begin Audience:='engineer'; if DocumentKind='user' then Audience:='user'
    else if DocumentKind='maintenance' then Audience:='maintainer' else if DocumentKind='build_deploy' then Audience:='builder' else if DocumentKind='handoff' then Audience:='agent'; end;
  StructuredText:=AStructuredJSON; if StructuredText='' then StructuredText:='{}';
  if Length(StructuredText)>65536 then raise EDPHStorage.Create('Structured knowledge exceeds 64 KiB');
  StructuredValue:=TJSONObject.ParseJSONValue(StructuredText);
  try
    if not (StructuredValue is TJSONObject) then raise EDPHStorage.Create('Structured knowledge must be an object');
    PriorStructured:='';
    if AKnowledgeID<>0 then PriorStructured:=VarToStr(Scalar('SELECT structured_json FROM knowledge_revisions WHERE knowledge_revision_id=:revision AND knowledge_id=:id',[AExpectedRevision,AKnowledgeID]));
    if (StructuredValue as TJSONObject).Count>0 then begin
      if (PriorStructured<>'') and (PriorStructured<>'{}') then begin
        PriorRecord:=TJSONObject.ParseJSONValue(PriorStructured);
        try if PriorRecord.GetValue<string>('record_type','')<>StructuredValue.GetValue<string>('record_type','') then
          raise EDPHStorage.Create('A structured record cannot change its record type');
        finally PriorRecord.Free; end;
      end;
      if (AKnowledgeID<>0) and (PriorStructured='{}') then raise EDPHStorage.Create('An ordinary knowledge record cannot become a structured record');
      if StructuredValue.GetValue<string>('record_type','')='business_glossary' then begin
        TDPHGlossary.Validate(StructuredValue as TJSONObject);
        if (AKind<>'glossary') or (ATitle<>StructuredValue.GetValue<string>('term').Trim) or (DocumentKind<>'user') or (Audience<>'all') then
          raise EDPHStorage.Create('Glossary term identity, user document and all-reader audience must be preserved');
        if ABody<>TDPHGlossary.Body(StructuredValue as TJSONObject) then raise EDPHStorage.Create('Edit glossary fields with Business glossary > Edit term');
        TermNames:=TDPHGlossary.Names(StructuredValue as TJSONObject);
        GlossaryQuery:=NewQuery('SELECT r.structured_json FROM knowledge_records k JOIN knowledge_revisions r ON r.knowledge_revision_id=k.current_revision_id '+
          'WHERE k.project_id=1 AND k.kind=''glossary'' AND k.knowledge_id<>:id',[AKnowledgeID]);
        try
          while not GlossaryQuery.Eof do begin
            ExistingGlossary:=TJSONObject.ParseJSONValue(GlossaryQuery.Fields[0].AsString) as TJSONObject;
            try
              ExistingNames:=TDPHGlossary.Names(ExistingGlossary);
              for GlossaryName in TermNames do for ExistingName in ExistingNames do
                if GlossaryName=ExistingName then raise EDPHStorage.Create('Term or alias already belongs to another glossary record: '+GlossaryName+'. Edit that record instead; retired names remain reserved.');
            finally ExistingGlossary.Free; end;
            GlossaryQuery.Next;
          end;
        finally GlossaryQuery.Free; end;
      end else if StructuredValue.GetValue<string>('record_type','')='action_purpose' then begin
        TDPHActionPurpose.Validate(StructuredValue as TJSONObject);
        if (ATitle<>TDPHActionPurpose.Title(StructuredValue as TJSONObject)) or (AKind<>'user_help') or (DocumentKind<>'user') or (Audience<>'user') or (AEntityKey<>StructuredValue.GetValue<string>('fields.target_key','')) then raise EDPHStorage.Create('Action purpose identity, user scope and captured target must be preserved');
        if ABody<>TDPHActionPurpose.Body(StructuredValue as TJSONObject) then raise EDPHStorage.Create('Edit structured action fields on Action purposes');
        if (PriorStructured<>'') and (PriorStructured<>'{}') then begin
          PriorRecord:=TJSONObject.ParseJSONValue(PriorStructured);
          try for ActionIdentityField in ['action_id','target','target_key'] do if PriorRecord.GetValue<string>('fields.'+ActionIdentityField,'')<>StructuredValue.GetValue<string>('fields.'+ActionIdentityField,'') then raise EDPHStorage.Create('Action purpose target identity cannot change');finally PriorRecord.Free;end;
        end;
        if Scalar('SELECT count(*) FROM knowledge_records k JOIN knowledge_revisions r ON r.knowledge_revision_id=k.current_revision_id WHERE k.project_id=1 AND k.knowledge_id<>:id AND json_extract(r.structured_json,''$.record_type'')=''action_purpose'' AND lower(json_extract(r.structured_json,''$.fields.action_id''))=lower(:identity)',[AKnowledgeID,StructuredValue.GetValue<string>('fields.action_id')])<>0 then raise EDPHStorage.Create('A purpose record already exists for this target; refresh and edit it. Retired identities remain reserved.');
      end else if StructuredValue.GetValue<string>('record_type','')='learning_card' then begin
        TDPHWorkspaceView.ValidateLearningCard(StructuredValue as TJSONObject);
        if (AKind<>'user_help') or (DocumentKind<>'user') or (Audience<>'all') or (ATitle<>StructuredValue.GetValue<string>('fields.name').Trim) then raise EDPHStorage.Create('Teaching cards must preserve their learner scope and name');
        if (Trim(AEditor)='') or SameText(Trim(AEditor),'Unknown') then raise EDPHStorage.Create('Enter the person supplying this explanation');
        if ABody<>TDPHWorkspaceView.LearningCardBody(StructuredValue as TJSONObject) then raise EDPHStorage.Create('Edit teaching fields in the learning library');
        if StructuredValue.GetValue<TJSONObject>('picture',nil)<>nil then begin
          PictureFound:=False;PictureRows:=ScreenshotsJSON;
          try for Value in PictureRows do if Value.GetValue<string>('image_sha256')=StructuredValue.GetValue<string>('picture.image_sha256') then PictureFound:=True;finally PictureRows.Free;end;
          if not PictureFound then raise EDPHStorage.Create('Import this picture into the selected application before saving its callout');
        end;
        if (PriorStructured<>'') and (PriorStructured<>'{}') then begin
          PriorRecord:=TJSONObject.ParseJSONValue(PriorStructured);
          try if PriorRecord.GetValue<string>('card_id')<>StructuredValue.GetValue<string>('card_id') then raise EDPHStorage.Create('Teaching card identity cannot change');finally PriorRecord.Free;end;
        end;
        if Scalar('SELECT count(*) FROM knowledge_records k JOIN knowledge_revisions r ON r.knowledge_revision_id=k.current_revision_id WHERE k.project_id=1 AND k.knowledge_id<>:id AND json_extract(r.structured_json,''$.record_type'')=''learning_card'' AND json_extract(r.structured_json,''$.card_id'')=:identity',[AKnowledgeID,StructuredValue.GetValue<string>('card_id')])<>0 then raise EDPHStorage.Create('This teaching card already exists; edit its current version');
      end else if StructuredValue.GetValue<string>('record_type','')='learning_lesson' then begin
        TDPHWorkspaceView.ValidateLearningLesson(StructuredValue as TJSONObject);
        if (AKind<>'user_help') or (DocumentKind<>'user') or (Audience<>'all') or (AEntityKey<>'') then raise EDPHStorage.Create('Task instructions must preserve their selected-project learning scope');
        if ATitle<>StructuredValue.GetValue<string>('fields.name').Trim then raise EDPHStorage.Create('Task title must match its supplied name');
        if ABody<>TDPHWorkspaceView.LearningLessonBody(StructuredValue as TJSONObject) then raise EDPHStorage.Create('Edit task instructions through their preparation page');
        if SameText(AEditor.Trim,'Unknown') then raise EDPHStorage.Create('Enter the task contributor name');
        if (PriorStructured<>'') and (PriorStructured<>'{}') then begin
          PriorRecord:=TJSONObject.ParseJSONValue(PriorStructured);
          try if PriorRecord.GetValue<string>('lesson_id','')<>StructuredValue.GetValue<string>('lesson_id','') then raise EDPHStorage.Create('Saved task identity cannot change');finally PriorRecord.Free;end;
        end;
        if Scalar('SELECT count(*) FROM knowledge_records k JOIN knowledge_revisions r ON r.knowledge_revision_id=k.current_revision_id WHERE k.project_id=1 AND k.knowledge_id<>:id AND json_extract(r.structured_json,''$.record_type'')=''learning_lesson'' AND json_extract(r.structured_json,''$.lesson_id'')=:identity',[AKnowledgeID,StructuredValue.GetValue<string>('lesson_id')])<>0 then raise EDPHStorage.Create('This task already exists; edit its current version');
      end else if StructuredValue.GetValue<string>('record_type','')='data_retention' then begin
        TDPHWorkspaceView.ValidateDataRetentionRecord(StructuredValue as TJSONObject);
        if SameText(ATitle.Trim,'Retention policy: enter descriptive data scope') then raise EDPHStorage.Create('Enter a descriptive retention policy title before saving');
        if (AKind<>'business_rule') or (DocumentKind<>'maintenance') or (Audience<>'maintainer') or (AEntityKey<>'') then raise EDPHStorage.Create('Retention policy must preserve its project scope, business rule kind and maintenance audience');
        if not ABody.StartsWith('TARGET DATA RETENTION AND ARCHIVAL POLICY'+sLineBreak) then raise EDPHStorage.Create('Preserve the target-data retention policy heading; edit the requirements below it');
        if (PriorStructured<>'') and (PriorStructured<>'{}') then begin
          PriorRecord:=TJSONObject.ParseJSONValue(PriorStructured);
          try if PriorRecord.GetValue<string>('policy_id','')<>StructuredValue.GetValue<string>('policy_id','') then raise EDPHStorage.Create('Retention policy identity cannot change');finally PriorRecord.Free;end;
        end;
        if Scalar('SELECT count(*) FROM knowledge_records k JOIN knowledge_revisions r ON r.knowledge_revision_id=k.current_revision_id WHERE k.project_id=1 AND k.knowledge_id<>:id AND json_extract(r.structured_json,''$.record_type'')=''data_retention'' AND json_extract(r.structured_json,''$.policy_id'')=:identity',[AKnowledgeID,StructuredValue.GetValue<string>('policy_id')])<>0 then raise EDPHStorage.Create('This retention policy identity already exists; refresh and edit its current revision');
      end else if StructuredValue.GetValue<string>('record_type','')='target_recovery' then begin
        TDPHWorkspaceView.ValidateTargetRecoveryRecord(StructuredValue as TJSONObject);
        if SameText(ATitle.Trim,'Recovery plan: enter descriptive data scope') then raise EDPHStorage.Create('Enter a descriptive recovery plan title before saving');
        if (AKind<>'business_rule') or (DocumentKind<>'maintenance') or (Audience<>'maintainer') or (AEntityKey<>'') then raise EDPHStorage.Create('Recovery plan must preserve its project scope, business rule kind and maintenance audience');
        if not ABody.StartsWith('TARGET BACKUP AND RESTORATION REQUIREMENTS'+sLineBreak) then raise EDPHStorage.Create('Preserve the target backup and restoration policy heading; edit the requirements below it');
        if (PriorStructured<>'') and (PriorStructured<>'{}') then begin
          PriorRecord:=TJSONObject.ParseJSONValue(PriorStructured);
          try if PriorRecord.GetValue<string>('plan_id','')<>StructuredValue.GetValue<string>('plan_id','') then raise EDPHStorage.Create('Recovery plan identity cannot change');finally PriorRecord.Free;end;
        end;
        if Scalar('SELECT count(*) FROM knowledge_records k JOIN knowledge_revisions r ON r.knowledge_revision_id=k.current_revision_id WHERE k.project_id=1 AND k.knowledge_id<>:id AND json_extract(r.structured_json,''$.record_type'')=''target_recovery'' AND json_extract(r.structured_json,''$.plan_id'')=:identity',[AKnowledgeID,StructuredValue.GetValue<string>('plan_id')])<>0 then raise EDPHStorage.Create('This recovery plan identity already exists; refresh and edit its current revision');
      end else if StructuredValue.GetValue<string>('record_type','')='business_process' then begin
        TDPHWorkspaceView.ValidateBusinessProcess(StructuredValue as TJSONObject);
        if ATitle<>StructuredValue.GetValue<string>('fields.name').Trim then raise EDPHStorage.Create('Process title must match its structured name');
        if (AKind<>'business_rule') or (DocumentKind<>'maintenance') or (Audience<>'maintainer') or (AEntityKey<>'') then raise EDPHStorage.Create('Business process must preserve its project scope, business rule kind and maintenance audience');
        if ABody<>TDPHWorkspaceView.BusinessProcessBody(StructuredValue as TJSONObject) then raise EDPHStorage.Create('Edit the structured fields on Business processes');
        if (PriorStructured<>'') and (PriorStructured<>'{}') then begin
          PriorRecord:=TJSONObject.ParseJSONValue(PriorStructured);
          try if PriorRecord.GetValue<string>('process_id','')<>StructuredValue.GetValue<string>('process_id','') then raise EDPHStorage.Create('Business process identity cannot change');finally PriorRecord.Free;end;
        end;
        if Scalar('SELECT count(*) FROM knowledge_records k JOIN knowledge_revisions r ON r.knowledge_revision_id=k.current_revision_id WHERE k.project_id=1 AND k.knowledge_id<>:id AND json_extract(r.structured_json,''$.record_type'')=''business_process'' AND json_extract(r.structured_json,''$.process_id'')=:identity',[AKnowledgeID,StructuredValue.GetValue<string>('process_id')])<>0 then raise EDPHStorage.Create('This business process identity already exists; refresh and edit its current revision');
      end else if StructuredValue.GetValue<string>('record_type','')='calculation_definition' then begin
        TDPHWorkspaceView.ValidateCalculation(StructuredValue as TJSONObject);
        if ATitle<>StructuredValue.GetValue<string>('fields.name').Trim then raise EDPHStorage.Create('Calculation title must match its structured name');
        if (AKind<>'business_rule') or (DocumentKind<>'maintenance') or (Audience<>'maintainer') or (AEntityKey<>'') then raise EDPHStorage.Create('Calculation must preserve its project scope, business rule kind and maintenance audience');
        if ABody<>TDPHWorkspaceView.CalculationBody(StructuredValue as TJSONObject) then raise EDPHStorage.Create('Edit the structured fields on Calculations');
        if (PriorStructured<>'') and (PriorStructured<>'{}') then begin
          PriorRecord:=TJSONObject.ParseJSONValue(PriorStructured);
          try if PriorRecord.GetValue<string>('calculation_id','')<>StructuredValue.GetValue<string>('calculation_id','') then raise EDPHStorage.Create('Calculation identity cannot change');finally PriorRecord.Free;end;
        end;
        if Scalar('SELECT count(*) FROM knowledge_records k JOIN knowledge_revisions r ON r.knowledge_revision_id=k.current_revision_id WHERE k.project_id=1 AND k.knowledge_id<>:id AND json_extract(r.structured_json,''$.record_type'')=''calculation_definition'' AND json_extract(r.structured_json,''$.calculation_id'')=:identity',[AKnowledgeID,StructuredValue.GetValue<string>('calculation_id')])<>0 then raise EDPHStorage.Create('This calculation identity already exists; refresh and edit its current revision');
      end else if StructuredValue.GetValue<string>('record_type','')='business_rule_definition' then begin
        TDPHWorkspaceView.ValidateBusinessRule(StructuredValue as TJSONObject);
        if ATitle<>StructuredValue.GetValue<string>('fields.name').Trim then raise EDPHStorage.Create('Rule title must match its structured name');
        if (AKind<>'business_rule') or (DocumentKind<>'maintenance') or (Audience<>'maintainer') or (AEntityKey<>'') then raise EDPHStorage.Create('Business rule must preserve its project scope, business rule kind and maintenance audience');
        if ABody<>TDPHWorkspaceView.BusinessRuleBody(StructuredValue as TJSONObject) then raise EDPHStorage.Create('Edit the structured fields on Business rules');
        if (PriorStructured<>'') and (PriorStructured<>'{}') then begin
          PriorRecord:=TJSONObject.ParseJSONValue(PriorStructured);
          try if PriorRecord.GetValue<string>('fields.rule_code','')<>StructuredValue.GetValue<string>('fields.rule_code','') then raise EDPHStorage.Create('Saved rule identifier cannot change; retire and create a separately linked replacement');
          if PriorRecord.GetValue<string>('rule_id','')<>StructuredValue.GetValue<string>('rule_id','') then raise EDPHStorage.Create('Business rule identity cannot change');finally PriorRecord.Free;end;
        end;
        if Scalar('SELECT count(*) FROM knowledge_records k JOIN knowledge_revisions r ON r.knowledge_revision_id=k.current_revision_id WHERE k.project_id=1 AND k.knowledge_id<>:id AND json_extract(r.structured_json,''$.record_type'')=''business_rule_definition'' AND json_extract(r.structured_json,''$.rule_id'')=:identity',[AKnowledgeID,StructuredValue.GetValue<string>('rule_id')])<>0 then raise EDPHStorage.Create('This business rule identity already exists; refresh and edit its current revision');
        if Scalar('SELECT count(*) FROM knowledge_records k JOIN knowledge_revisions r ON r.knowledge_revision_id=k.current_revision_id WHERE k.project_id=1 AND k.knowledge_id<>:id AND json_extract(r.structured_json,''$.record_type'')=''business_rule_definition'' AND lower(json_extract(r.structured_json,''$.fields.rule_code''))=lower(:code)',[AKnowledgeID,StructuredValue.GetValue<string>('fields.rule_code')])<>0 then raise EDPHStorage.Create('This rule identifier already exists, including retired rules; refresh and edit its current revision');
      end else if StructuredValue.GetValue<string>('record_type','')='departmental_workflow' then begin
        TDPHWorkspaceView.ValidateDepartmentalWorkflow(StructuredValue as TJSONObject);
        if ATitle<>StructuredValue.GetValue<string>('fields.name').Trim then raise EDPHStorage.Create('Workflow title must match its structured name');
        if (AKind<>'business_rule') or (DocumentKind<>'maintenance') or (Audience<>'maintainer') or (AEntityKey<>'') then raise EDPHStorage.Create('Departmental workflow must preserve its project scope, business rule kind and maintenance audience');
        if ABody<>TDPHWorkspaceView.DepartmentalWorkflowBody(StructuredValue as TJSONObject) then raise EDPHStorage.Create('Edit the structured fields on Departmental workflows');
        if (PriorStructured<>'') and (PriorStructured<>'{}') then begin
          PriorRecord:=TJSONObject.ParseJSONValue(PriorStructured);
          try if PriorRecord.GetValue<string>('workflow_id','')<>StructuredValue.GetValue<string>('workflow_id','') then raise EDPHStorage.Create('Departmental workflow identity cannot change');finally PriorRecord.Free;end;
        end;
        if Scalar('SELECT count(*) FROM knowledge_records k JOIN knowledge_revisions r ON r.knowledge_revision_id=k.current_revision_id WHERE k.project_id=1 AND k.knowledge_id<>:id AND json_extract(r.structured_json,''$.record_type'')=''departmental_workflow'' AND json_extract(r.structured_json,''$.workflow_id'')=:identity',[AKnowledgeID,StructuredValue.GetValue<string>('workflow_id')])<>0 then raise EDPHStorage.Create('This departmental workflow identity already exists; refresh and edit its current revision');
      end else if StructuredValue.GetValue<string>('record_type','')='data_quality' then begin
        TDPHWorkspaceView.ValidateDataQualityRecord(StructuredValue as TJSONObject);
        if SameText(ATitle.Trim,'Quality check: enter descriptive data scope') then raise EDPHStorage.Create('Enter a descriptive data quality rule title before saving');
        if (AKind<>'business_rule') or (DocumentKind<>'maintenance') or (Audience<>'maintainer') or (AEntityKey<>'') then raise EDPHStorage.Create('Quality check must preserve its project scope, business rule kind and maintenance audience');
        if not ABody.StartsWith('TARGET DATA QUALITY AND INTEGRITY CHECK'+sLineBreak) then raise EDPHStorage.Create('Preserve the target-data quality rule heading; edit the requirements below it');
        if (PriorStructured<>'') and (PriorStructured<>'{}') then begin
          PriorRecord:=TJSONObject.ParseJSONValue(PriorStructured);
          try if PriorRecord.GetValue<string>('rule_id','')<>StructuredValue.GetValue<string>('rule_id','') then raise EDPHStorage.Create('Quality check identity cannot change');finally PriorRecord.Free;end;
        end;
        if Scalar('SELECT count(*) FROM knowledge_records k JOIN knowledge_revisions r ON r.knowledge_revision_id=k.current_revision_id WHERE k.project_id=1 AND k.knowledge_id<>:id AND json_extract(r.structured_json,''$.record_type'')=''data_quality'' AND json_extract(r.structured_json,''$.rule_id'')=:identity',[AKnowledgeID,StructuredValue.GetValue<string>('rule_id')])<>0 then raise EDPHStorage.Create('This data quality rule identity already exists; refresh and edit its current revision');
      end else if StructuredValue.GetValue<string>('record_type','')='data_dictionary' then begin
        TDPHDatabaseSchema.ValidateDictionary(StructuredValue as TJSONObject);
        if AKnowledgeID=0 then begin
          DictionaryView:=TDPHWorkspaceView.Create(TJSONObject.ParseJSONValue(LoadWorkspaceView(AGenerationID)) as TJSONObject);
          try DictionaryInventory:=TDPHDatabaseSchema.Inspect(DictionaryView);
            try DictionaryMatched:=False;
              for DictionaryValue in DictionaryInventory.GetValue<TJSONArray>('rows') do begin
                if not MatchText(DictionaryValue.GetValue<string>('kind'),['table','column']) or not MatchText(DictionaryValue.GetValue<string>('status'),['declared header','declared column']) then Continue;
                if DictionaryValue.GetValue<string>('id')<>StructuredValue.GetValue<string>('fields.schema_id') then Continue;
                DictionaryExpected:=TDPHDatabaseSchema.NewDictionary(DictionaryValue as TJSONObject);
                try DictionaryMatched:=True;for ActionIdentityField in ['dictionary_id','schema_id','source','source_hash','generation','kind','name','table','source_line'] do
                  if DictionaryExpected.GetValue<string>('fields.'+ActionIdentityField)<>StructuredValue.GetValue<string>('fields.'+ActionIdentityField) then DictionaryMatched:=False;
                finally DictionaryExpected.Free;end;
                if DictionaryMatched then Break;
              end;
              if not DictionaryMatched then raise EDPHStorage.Create('Dictionary target must exactly match a table or column in the selected captured generation');
            finally DictionaryInventory.Free;end;
          finally DictionaryView.Free;end;
        end;
        if (ATitle<>TDPHDatabaseSchema.DictionaryTitle(StructuredValue as TJSONObject)) or (AKind<>'business_rule') or (DocumentKind<>'overview') or (Audience<>'all') or (AEntityKey<>'') then raise EDPHStorage.Create('Dictionary identity and project business scope must be preserved');
        if ABody<>TDPHDatabaseSchema.DictionaryBody(StructuredValue as TJSONObject) then raise EDPHStorage.Create('Edit dictionary fields on Database schema');
        if (PriorStructured<>'') and (PriorStructured<>'{}') then begin
          PriorRecord:=TJSONObject.ParseJSONValue(PriorStructured);
          try for ActionIdentityField in ['dictionary_id','schema_id','source','source_hash','generation','kind','name','table','source_line'] do
            if PriorRecord.GetValue<string>('fields.'+ActionIdentityField,'')<>StructuredValue.GetValue<string>('fields.'+ActionIdentityField,'') then raise EDPHStorage.Create('Dictionary captured identity cannot change');finally PriorRecord.Free;end;
        end;
        if Scalar('SELECT count(*) FROM knowledge_records k JOIN knowledge_revisions r ON r.knowledge_revision_id=k.current_revision_id WHERE k.project_id=1 AND k.knowledge_id<>:id AND json_extract(r.structured_json,''$.record_type'')=''data_dictionary'' AND json_extract(r.structured_json,''$.fields.dictionary_id'')=:identity',[AKnowledgeID,StructuredValue.GetValue<string>('fields.dictionary_id')])<>0 then raise EDPHStorage.Create('A dictionary already exists for this captured target; refresh and edit it. Retired identities remain reserved.');
      end else if StructuredValue.GetValue<string>('record_type','')='component_dependency' then begin
        TDPHComponentDependency.Validate(StructuredValue as TJSONObject);
        if (ATitle<>TDPHComponentDependency.Title(StructuredValue as TJSONObject)) or (AKind<>'engineering_rule') or (DocumentKind<>'engineering') or (Audience<>'engineer') or (AEntityKey<>'') then raise EDPHStorage.Create('Component dependency identity and engineering scope must be preserved');
        if ABody<>TDPHComponentDependency.Body(StructuredValue as TJSONObject) then raise EDPHStorage.Create('Edit dependency fields on Component dependencies');
        if (PriorStructured<>'') and (PriorStructured<>'{}') then begin
          PriorRecord:=TJSONObject.ParseJSONValue(PriorStructured);
          try if PriorRecord.GetValue<string>('fields.class_name','')<>StructuredValue.GetValue<string>('fields.class_name','') then raise EDPHStorage.Create('Component class identity cannot change');finally PriorRecord.Free;end;
        end;
        if Scalar('SELECT count(*) FROM knowledge_records k JOIN knowledge_revisions r ON r.knowledge_revision_id=k.current_revision_id WHERE k.project_id=1 AND k.knowledge_id<>:id AND json_extract(r.structured_json,''$.record_type'')=''component_dependency'' AND lower(json_extract(r.structured_json,''$.fields.class_name''))=lower(:class)',[AKnowledgeID,StructuredValue.GetValue<string>('fields.class_name')])<>0 then raise EDPHStorage.Create('A dependency record already exists for this class; refresh and edit it. Retired identities remain reserved.');
      end else begin
      TDPHProjectProfile.Validate(StructuredValue as TJSONObject);
      if (ATitle<>'Project profile') or (AKind<>'orientation') or (DocumentKind<>'overview') or (Audience<>'all') or (AEntityKey<>'') then
        raise EDPHStorage.Create('Project profile identity, audience and project scope must be preserved');
      if ABody<>TDPHProjectProfile.Body(StructuredValue as TJSONObject) then raise EDPHStorage.Create('Edit project profile fields with the Project profile command');
      if (AKnowledgeID=0) and (Scalar('SELECT count(*) FROM knowledge_records k JOIN knowledge_revisions r ON r.knowledge_revision_id=k.current_revision_id WHERE k.project_id=1 AND json_extract(r.structured_json,''$.record_type'')=''project_profile''',[])<>0) then
        raise EDPHStorage.Create('A profile already exists; refresh and edit its current revision');
      if (AKnowledgeID<>0) and (PriorStructured='{}') then raise EDPHStorage.Create('An ordinary knowledge record cannot be reassigned as the project profile');
      end;
    end else if (PriorStructured<>'') and (PriorStructured<>'{}') then raise EDPHStorage.Create('Structured record fields cannot be discarded; use its editor');
    if (AKind='glossary') and (StructuredValue.GetValue<string>('record_type','')<>'business_glossary') then
      raise EDPHStorage.Create('Glossary terms require validated structured fields');
  finally StructuredValue.Free; end;
  if not MatchText(DocumentKind,['overview','engineering','user','maintenance','build_deploy','troubleshooting','orientation','handoff','help']) then raise EDPHStorage.Create('Unknown document kind');
  if not MatchText(Audience,['all','engineer','user','maintainer','builder','agent']) then raise EDPHStorage.Create('Unknown documentation audience');
  if Scalar('SELECT count(*) FROM analysis_generations WHERE generation_id=:id AND project_id=1 AND status IN (''current'',''partial'')',[AGenerationID])<>1 then raise EDPHStorage.Create('Select a captured generation first');
  Entity:=0;
  if AEntityKey<>'' then begin
    Entity:=VarAsType(Scalar('SELECT coalesce(max(e.entity_id),0) FROM entities e JOIN entity_versions v ON v.entity_id=e.entity_id '+
      'WHERE e.project_id=1 AND e.canonical_key=:key AND v.generation_id=:generation',[AEntityKey,AGenerationID]),varInt64);
    if Entity=0 then raise EDPHStorage.Create('Linked entity does not exist in this generation');
  end;
  FConnection.StartTransaction;
  try
    Result:=AKnowledgeID; Prior:='';
    if Result=0 then begin
      if AExpectedRevision<>0 then raise EDPHStorage.Create('New knowledge cannot have a prior revision');
      FConnection.ExecSQL('INSERT INTO knowledge_records(project_id,kind,title,source_language,state,owner) VALUES(1,:kind,:title,''en'',''needs_review'',:author)',[AKind,ATitle,AEditor]);
      Result:=Scalar('SELECT last_insert_rowid()',[]);
      if Entity<>0 then FConnection.ExecSQL('INSERT INTO knowledge_links(project_id,knowledge_id,entity_id,link_role) VALUES(1,:id,:entity,''annotates'')',[Result,Entity]);
    end else begin
      if Scalar('SELECT count(*) FROM knowledge_records WHERE project_id=1 AND knowledge_id=:id AND current_revision_id=:revision AND (title=:title OR kind=''glossary'') AND kind=:kind',
        [Result,AExpectedRevision,ATitle,AKind])<>1 then raise EDPHStorage.Create('Knowledge changed since loading, or its stable title/kind was changed; reload first');
      Prior:=VarToStr(Scalar('SELECT body_md FROM knowledge_revisions WHERE knowledge_revision_id=:id',[AExpectedRevision]));
      if AKind='glossary' then FConnection.ExecSQL('UPDATE knowledge_records SET title=:title WHERE knowledge_id=:id',[ATitle,Result]);
    end;
    FConnection.ExecSQL('INSERT INTO knowledge_revisions(knowledge_id,body_md,editor,created_at,verification_state,structured_json) VALUES(:id,:body,:author,:stamp,''needs_review'',:structured)',[Result,ABody,AEditor,UTCNow,StructuredText]);
    Revision:=Scalar('SELECT last_insert_rowid()',[]);
    FConnection.ExecSQL('INSERT INTO document_section_versions(revision_id,knowledge_id,section_id,document_kind,audience,source_generation) '+
      'VALUES(:revision,:id,:section,:document,:audience,:generation)',[Revision,Result,'knowledge-'+IntToStr(Result),DocumentKind,Audience,AGenerationID]);
    if ALinksJSON='' then FConnection.ExecSQL('INSERT INTO knowledge_revision_links SELECT :revision,ordinal,target_kind,target_id,source_generation,link_role,label '+
      'FROM knowledge_revision_links WHERE revision_id=:prior',[Revision,AExpectedRevision])
    else begin
      if Length(ALinksJSON)>65536 then raise EDPHStorage.Create('Links exceed 64 KiB');
      ParsedLinks:=TJSONObject.ParseJSONValue(ALinksJSON);
      if not (ParsedLinks is TJSONArray) then begin ParsedLinks.Free; raise EDPHStorage.Create('Links must be a JSON array'); end;
      LinkRows:=ParsedLinks as TJSONArray;
      try
        if LinkRows.Count>64 then raise EDPHStorage.Create('Maximum 64 links per section');
        FConnection.ExecSQL('DELETE FROM knowledge_links WHERE knowledge_id=:id AND link_role=''rich''',[Result]);
        Ordinal:=0;
        for Value in LinkRows do begin
          if not (Value is TJSONObject) then raise EDPHStorage.Create('Invalid link row'); LinkRow:=Value as TJSONObject;
          TargetKind:=LinkRow.GetValue<string>('target_kind'); TargetID:=LinkRow.GetValue<Int64>('target_id'); Role:=LinkRow.GetValue<string>('link_role');
          if not MatchText(Role,['explains','cites','depends_on','illustrates']) then raise EDPHStorage.Create('Unknown link role');
          if TargetKind='entity' then SQL:='SELECT e.display_name FROM entities e JOIN entity_versions v ON v.entity_id=e.entity_id WHERE e.entity_id=:id AND v.generation_id=:generation'
          else if TargetKind='relationship' then SQL:='SELECT relation_kind FROM relationships WHERE relationship_id=:id AND generation_id=:generation'
          else if TargetKind='evidence' then SQL:='SELECT evidence_kind FROM evidence WHERE evidence_id=:id AND generation_id=:generation'
          else if TargetKind='screenshot' then SQL:='SELECT ''Imported PNG #''||artifact_id FROM artifacts WHERE artifact_id=:id AND generation_id=:generation AND kind=''user_screenshot'''
          else if TargetKind='section' then SQL:='SELECT k.title FROM knowledge_records k JOIN knowledge_revisions r ON r.knowledge_id=k.knowledge_id '+
            'WHERE r.knowledge_revision_id=:id AND k.project_id=1 AND :generation>0'
          else raise EDPHStorage.Create('Unknown link target kind');
          LabelText:=VarToStr(Scalar(SQL,[TargetID,AGenerationID]));
          if LabelText='' then raise EDPHStorage.Create('Link target is unavailable in the selected generation');
          FConnection.ExecSQL('INSERT INTO knowledge_revision_links VALUES(:revision,:ordinal,:kind,:id,:generation,:role,:label)',
            [Revision,Ordinal,TargetKind,TargetID,AGenerationID,Role,LabelText]); Inc(Ordinal);
          if MatchText(TargetKind,['entity','relationship','evidence']) then begin
            SQL:='entity_id'; if TargetKind='relationship' then SQL:='relationship_id' else if TargetKind='evidence' then SQL:='evidence_id';
            FConnection.ExecSQL('INSERT INTO knowledge_links(project_id,knowledge_id,'+SQL+',link_role) VALUES(1,:id,:target,''rich'')',[Result,TargetID]);
          end;
        end;
      finally LinkRows.Free; end;
    end;
    FConnection.ExecSQL('UPDATE knowledge_records SET current_revision_id=:revision,state=''needs_review'' WHERE knowledge_id=:id',[Revision,Result]);
    if AQuestionJSON<>'' then begin
      if Length(AQuestionJSON)>65536 then raise EDPHStorage.Create('Question evidence exceeds 64 KiB');
      ParsedLinks:=TJSONObject.ParseJSONValue(AQuestionJSON);
      if not (ParsedLinks is TJSONObject) then begin ParsedLinks.Free; raise EDPHStorage.Create('Invalid question metadata'); end;
      Question:=ParsedLinks as TJSONObject;
      try
        QuestionID:=Question.GetValue<string>('id');
        ExpectedID:=THashSHA2.GetHashString(Question.GetValue<string>('kind')+#0+Question.GetValue<string>('entity_key')+#0+
          Question.GetValue<TJSONObject>('range').ToJSON+#0+Question.GetValue<string>('source_hash')+#0+
          Question.GetValue<string>('prompt')+#0+Question.GetValue<string>('rule')+#0+Question.GetValue<string>('context_fingerprint'));
        if QuestionID<>ExpectedID then raise EDPHStorage.Create('Question identity does not match its captured evidence');
        if (Pos('Answer:',ABody)=0) or (Trim(Copy(ABody,Pos('Answer:',ABody)+7,MaxInt))='') then raise EDPHStorage.Create('Enter an attributed answer after Answer: before saving');
        PriorQuestion:=VarToStr(Scalar('SELECT question_key FROM knowledge_questions WHERE knowledge_id=:id',[Result]));
        if (PriorQuestion<>'') and (PriorQuestion<>QuestionID) then raise EDPHStorage.Create('A response cannot be reassigned to another question');
        if PriorQuestion='' then begin
          if Question.GetValue<Int64>('generation_id')<>AGenerationID then raise EDPHStorage.Create('Refresh the question against the selected generation first');
          FConnection.ExecSQL('INSERT INTO knowledge_questions VALUES(:id,:key,:json,:generation)',[Result,QuestionID,AQuestionJSON,AGenerationID]);
        end;
      finally Question.Free; end;
    end;
    FConnection.ExecSQL('INSERT INTO review_tasks(project_id,knowledge_id,reason,state,opened_generation_id) SELECT 1,:id,''Human content changed'',''pending'',:generation '+
      'WHERE NOT EXISTS(SELECT 1 FROM review_tasks WHERE knowledge_id=:id2 AND state=''pending'')',[Result,AGenerationID,Result]);
    FConnection.ExecSQL('UPDATE project_state SET knowledge_review_needed=1 WHERE project_id=1');
    FConnection.ExecSQL('INSERT INTO review_tasks(project_id,knowledge_id,reason,state,opened_generation_id) '+
      'SELECT DISTINCT 1,k.knowledge_id,''Referenced section revision changed'',''pending'',:generation FROM knowledge_revision_links l '+
      'JOIN knowledge_records k ON k.current_revision_id=l.revision_id WHERE l.target_kind=''section'' AND l.target_id=:prior '+
      'AND NOT EXISTS(SELECT 1 FROM review_tasks t WHERE t.knowledge_id=k.knowledge_id AND t.state=''pending'')',[AGenerationID,AExpectedRevision]);
    FConnection.ExecSQL('UPDATE artifacts SET build_state=''stale'' WHERE kind<>''workspace_view''');
    FConnection.ExecSQL('UPDATE translations SET translation_state=''needs_review'' WHERE knowledge_revision_id IN (SELECT knowledge_revision_id FROM knowledge_revisions WHERE knowledge_id=:id)',[Result]);
    FConnection.ExecSQL('INSERT INTO audit_events(project_id,entity_type,entity_id,action,actor,recorded_at,before_hash,after_hash) '+
      'VALUES(1,''knowledge'',:id,''authored'',:actor,:stamp,:before,:after)',[Result,AEditor,UTCNow,THashSHA2.GetHashString(Prior),THashSHA2.GetHashString(ABody)]);
    FConnection.Commit;
  except FConnection.Rollback; raise; end;
end;

procedure TDPHKnowledgeStore.ReviewKnowledge(AKnowledgeID,AExpectedRevision,AGenerationID: Int64;
  const AReviewer,AState: string);
var Body,Manifest,GenerationState: string; Revision: Int64;
begin
  RequireWriter;
  if AReviewer.Trim='' then raise EDPHStorage.Create('Review requires a named reviewer');
  if not MatchText(AState,['verified','needs_review','rejected','retired']) then raise EDPHStorage.Create('Unknown review disposition');
  GenerationState:=VarToStr(Scalar('SELECT status FROM analysis_generations WHERE generation_id=:id AND project_id=1',[AGenerationID]));
  if not MatchText(GenerationState,['current','partial']) then raise EDPHStorage.Create('Review requires a captured generation');
  Manifest:=VarToStr(Scalar('SELECT manifest_hash FROM analysis_generations WHERE generation_id=:id',[AGenerationID]));
  if (Manifest<>ManifestHash(ReadManifest)) or (Scalar('SELECT config_id FROM analysis_generations WHERE generation_id=:id',[AGenerationID])<>
    Scalar('SELECT active_config FROM projects WHERE project_id=1',[])) then raise EDPHStorage.Create('Review source/configuration has changed; reassess first');
  if (AState='verified') and (Scalar('SELECT count(*) FROM knowledge_links l WHERE l.knowledge_id=:id AND l.entity_id IS NOT NULL '+
    'AND l.link_role<>''historical_annotation'' AND NOT EXISTS(SELECT 1 FROM entity_versions v WHERE v.entity_id=l.entity_id AND v.generation_id=:generation)',[AKnowledgeID,AGenerationID])<>0) then
    raise EDPHStorage.Create('Linked entity is missing or renamed; continuity requires human investigation');
  if (AState='verified') and (Scalar('SELECT count(*) FROM knowledge_revision_links l WHERE l.revision_id=:revision AND '+
    '(l.source_generation<>:generation OR (l.target_kind=''section'' AND NOT EXISTS(SELECT 1 FROM knowledge_records k WHERE k.current_revision_id=l.target_id)))',
    [AExpectedRevision,AGenerationID])<>0) then raise EDPHStorage.Create('Rich links refer to historical generations or section revisions. Review and save current targets first.');
  FConnection.StartTransaction;
  try
    if Scalar('SELECT count(*) FROM knowledge_records WHERE project_id=1 AND knowledge_id=:id AND current_revision_id=:revision',[AKnowledgeID,AExpectedRevision])<>1 then
      raise EDPHStorage.Create('Knowledge revision changed; reload before reviewing');
    Body:=VarToStr(Scalar('SELECT body_md FROM knowledge_revisions WHERE knowledge_revision_id=:id',[AExpectedRevision]));
    FConnection.ExecSQL('INSERT INTO knowledge_revisions(knowledge_id,body_md,editor,created_at,verification_state,verified_by,verified_at,structured_json) '+
      'VALUES(:id,:body,:editor,:stamp,:state,:reviewer,:reviewed,(SELECT structured_json FROM knowledge_revisions WHERE knowledge_revision_id=:prior))',[AKnowledgeID,Body,AReviewer,UTCNow,AState,AReviewer,UTCNow,AExpectedRevision]);
    Revision:=Scalar('SELECT last_insert_rowid()',[]);
    FConnection.ExecSQL('UPDATE knowledge_records SET current_revision_id=:revision,state=:state WHERE knowledge_id=:id',[Revision,AState,AKnowledgeID]);
    FConnection.ExecSQL('INSERT INTO knowledge_revision_links SELECT :revision,ordinal,target_kind,target_id,source_generation,link_role,label '+
      'FROM knowledge_revision_links WHERE revision_id=:prior',[Revision,AExpectedRevision]);
    FConnection.ExecSQL('INSERT INTO document_section_versions(revision_id,knowledge_id,section_id,document_kind,audience,source_generation) '+
      'SELECT :revision,knowledge_id,section_id,document_kind,audience,:generation FROM document_section_versions WHERE revision_id=:prior',
      [Revision,AGenerationID,AExpectedRevision]);
    if AState<>'needs_review' then begin
      FConnection.ExecSQL('UPDATE review_tasks SET state=''resolved'',resolved_generation_id=:generation,reviewer=:reviewer WHERE knowledge_id=:id AND state=''pending''',[AGenerationID,AReviewer,AKnowledgeID]);
      if AState='verified' then FConnection.ExecSQL('UPDATE knowledge_links SET last_verified_generation_id=:generation WHERE knowledge_id=:id',[AGenerationID,AKnowledgeID]);
    end else FConnection.ExecSQL('INSERT INTO review_tasks(project_id,knowledge_id,reason,state,opened_generation_id) SELECT 1,:id,''Human review requested'',''pending'',:generation '+
      'WHERE NOT EXISTS(SELECT 1 FROM review_tasks WHERE knowledge_id=:id2 AND state=''pending'')',[AKnowledgeID,AGenerationID,AKnowledgeID]);
    FConnection.ExecSQL('INSERT INTO review_tasks(project_id,knowledge_id,reason,state,opened_generation_id) '+
      'SELECT DISTINCT 1,k.knowledge_id,''Referenced section revision changed'',''pending'',:generation FROM knowledge_revision_links l '+
      'JOIN knowledge_records k ON k.current_revision_id=l.revision_id WHERE l.target_kind=''section'' AND l.target_id=:prior '+
      'AND NOT EXISTS(SELECT 1 FROM review_tasks t WHERE t.knowledge_id=k.knowledge_id AND t.state=''pending'')',[AGenerationID,AExpectedRevision]);
    FConnection.ExecSQL('UPDATE project_state SET knowledge_review_needed=EXISTS(SELECT 1 FROM review_tasks WHERE state=''pending'') WHERE project_id=1');
    FConnection.ExecSQL('UPDATE artifacts SET build_state=''stale'' WHERE kind<>''workspace_view''');
    FConnection.ExecSQL('INSERT INTO audit_events(project_id,entity_type,entity_id,action,actor,recorded_at,after_hash) VALUES(1,''knowledge'',:id,:action,:actor,:stamp,:hash)',
      [AKnowledgeID,AState,AReviewer,UTCNow,THashSHA2.GetHashString(Body)]);
    FConnection.Commit;
  except FConnection.Rollback; raise; end;
end;

function TDPHKnowledgeStore.ReviewTasks(AGeneration: Int64): TJSONArray;
var Query,Detail: TFDQuery; Row,Item: TJSONObject; Affected,Relations: TJSONArray;
  Baseline,Knowledge,Entity,Revision,PriorRevision,RelationGeneration: Int64; I,Pass: Integer; Name: string;
begin
  RequireWriter; Result:=TJSONArray.Create;
  Query:=NewQuery('SELECT t.task_id,coalesce(t.knowledge_id,0) AS knowledge_id,coalesce(t.entity_id,0) AS entity_id,'+
    'coalesce(k.title,''Source investigation'') AS title,t.reason,coalesce(t.opened_generation_id,0) AS opened_generation,'+
    'coalesce(k.current_revision_id,0) AS revision,coalesce(r.body_md,'''') AS body,coalesce(r.verification_state,''needs_review'') AS revision_state '+
    'FROM review_tasks t LEFT JOIN knowledge_records k ON k.knowledge_id=t.knowledge_id '+
    'LEFT JOIN knowledge_revisions r ON r.knowledge_revision_id=k.current_revision_id WHERE t.project_id=1 AND t.state=''pending'' ORDER BY t.task_id LIMIT 1000',[]);
  try
    try while not Query.Eof do begin
      Row:=TJSONObject.Create; Result.AddElement(Row); for I:=0 to Query.FieldCount-1 do Row.AddPair(Query.Fields[I].FieldName,Query.Fields[I].AsString);
      Knowledge:=Query.FieldByName('knowledge_id').AsLargeInt; Entity:=Query.FieldByName('entity_id').AsLargeInt; Revision:=Query.FieldByName('revision').AsLargeInt;
      Baseline:=Scalar('SELECT coalesce(max(last_verified_generation_id),0) FROM knowledge_links WHERE knowledge_id=:id',[Knowledge]);
      if Baseline=0 then Baseline:=Scalar('SELECT coalesce(previous_generation_id,0) FROM analysis_generations WHERE generation_id=:id',[AGeneration]);
      Row.AddPair('baseline_generation',TJSONNumber.Create(Baseline)); Row.AddPair('current_generation',TJSONNumber.Create(AGeneration));
      PriorRevision:=Scalar('SELECT coalesce(max(knowledge_revision_id),0) FROM knowledge_revisions WHERE knowledge_id=:id AND knowledge_revision_id<:revision',[Knowledge,Revision]);
      Row.AddPair('prior_revision',TJSONNumber.Create(PriorRevision));
      Row.AddPair('before_body',VarToStr(Scalar('SELECT body_md FROM knowledge_revisions WHERE knowledge_revision_id=:id',[PriorRevision])));
      for Pass:=0 to 1 do begin
        RelationGeneration:=Baseline; Name:='before'; if Pass=1 then begin RelationGeneration:=AGeneration; Name:='after'; end;
        Row.AddPair(Name+'_configuration',VarToStr(Scalar('SELECT c.platform||'' / ''||c.compiler||'' / ''||c.environment_label||'' | defines ''||c.defines_json '+
          'FROM analysis_generations g JOIN configurations c ON c.config_id=g.config_id WHERE g.generation_id=:id',[RelationGeneration])));
      end;
      Affected:=TJSONArray.Create; Row.AddPair('affected',Affected);
      Detail:=NewQuery('WITH p AS (SELECT :baseline AS old_gen,:generation AS new_gen,:knowledge AS kid,:entity AS eid),ids AS ('+
        'SELECT entity_id FROM knowledge_links,p WHERE knowledge_id=p.kid AND entity_id IS NOT NULL AND link_role<>''historical_annotation'' '+
        'UNION SELECT from_entity_id FROM relationships r JOIN knowledge_links l ON l.relationship_id=r.relationship_id,p WHERE l.knowledge_id=p.kid '+
        'UNION SELECT to_entity_id FROM relationships r JOIN knowledge_links l ON l.relationship_id=r.relationship_id,p WHERE l.knowledge_id=p.kid AND to_entity_id IS NOT NULL '+
        'UNION SELECT eid FROM p WHERE eid>0) '+
        'SELECT e.entity_id,e.canonical_key,e.display_name,coalesce(b.signature,'''') AS before_signature,coalesce(a.signature,'''') AS after_signature,'+
        'coalesce(json_extract(b.structural_json,''$.source_hash''),'''') AS before_hash,coalesce(json_extract(a.structural_json,''$.source_hash''),'''') AS after_hash,'+
        'coalesce(json_extract(b.structural_json,''$.type''),'''') AS before_type,coalesce(json_extract(a.structural_json,''$.type''),'''') AS after_type,'+
        'coalesce(json_extract(b.structural_json,''$.range.source''),'''') AS before_source,coalesce(json_extract(a.structural_json,''$.range.source''),'''') AS after_source,'+
        'CASE WHEN b.entity_version_id IS NULL THEN 0 ELSE 1 END AS before_present,CASE WHEN a.entity_version_id IS NULL THEN 0 ELSE 1 END AS after_present '+
        'FROM ids JOIN entities e ON e.entity_id=ids.entity_id,p LEFT JOIN entity_versions b ON b.entity_id=e.entity_id AND b.generation_id=p.old_gen '+
        'LEFT JOIN entity_versions a ON a.entity_id=e.entity_id AND a.generation_id=p.new_gen ORDER BY e.display_name LIMIT 200',[Baseline,AGeneration,Knowledge,Entity]);
      try while not Detail.Eof do begin Item:=TJSONObject.Create; Affected.AddElement(Item); for I:=0 to Detail.FieldCount-1 do Item.AddPair(Detail.Fields[I].FieldName,Detail.Fields[I].AsString); Detail.Next; end; finally Detail.Free; end;
      for Pass:=0 to 1 do begin
        RelationGeneration:=Baseline; Name:='before_relationships'; if Pass=1 then begin RelationGeneration:=AGeneration; Name:='after_relationships'; end;
        Relations:=TJSONArray.Create; Row.AddPair(Name,Relations);
        Detail:=NewQuery('SELECT a.canonical_key AS from_key,r.relation_kind,coalesce(b.canonical_key,''unresolved'') AS to_key,r.resolution_status '+
          'FROM relationships r JOIN entities a ON a.entity_id=r.from_entity_id LEFT JOIN entities b ON b.entity_id=r.to_entity_id '+
          'WHERE r.generation_id=:generation AND (r.from_entity_id IN (SELECT entity_id FROM knowledge_links WHERE knowledge_id=:knowledge AND entity_id IS NOT NULL) '+
          'OR r.to_entity_id=:entity) ORDER BY r.relationship_id LIMIT 200',[RelationGeneration,Knowledge,Entity]);
        try while not Detail.Eof do begin Item:=TJSONObject.Create; Relations.AddElement(Item); for I:=0 to Detail.FieldCount-1 do Item.AddPair(Detail.Fields[I].FieldName,Detail.Fields[I].AsString); Detail.Next; end; finally Detail.Free; end;
      end;
      Query.Next;
    end;
    except Result.Free; raise; end;
  finally Query.Free; end;
end;
function TDPHKnowledgeStore.LinkCandidates(AGeneration: Int64; const AKind,AQuery: string): TJSONArray;
var Query: TFDQuery; Row: TJSONObject; SQL,Search: string; I: Integer;
begin
  RequireWriter;
  if Scalar('SELECT count(*) FROM analysis_generations WHERE project_id=1 AND generation_id=:generation AND status IN (''current'',''partial'',''superseded'')',[AGeneration])<>1 then
    raise EDPHStorage.Create('Link candidates require a captured generation');
  Search:='%'+AQuery+'%';
  if AKind='entity' then SQL:='SELECT e.entity_id AS target_id,e.display_name||'' [''||e.entity_kind||'']'' AS label,e.canonical_key FROM entities e '+
    'JOIN entity_versions v ON v.entity_id=e.entity_id WHERE v.generation_id=:generation AND e.display_name LIKE :query ORDER BY e.display_name LIMIT 200'
  else if AKind='relationship' then SQL:='SELECT r.relationship_id AS target_id,a.display_name||'' -> ''||r.relation_kind||'' -> ''||coalesce(b.display_name,''unresolved'') AS label,a.canonical_key '+
    'FROM relationships r JOIN entities a ON a.entity_id=r.from_entity_id LEFT JOIN entities b ON b.entity_id=r.to_entity_id '+
    'WHERE r.generation_id=:generation AND (a.display_name||r.relation_kind||coalesce(b.display_name,'''')) LIKE :query ORDER BY r.relationship_id LIMIT 200'
  else if AKind='evidence' then SQL:='SELECT ev.evidence_id AS target_id,ev.evidence_kind||'' | ''||f.canonical_relpath||'':''||coalesce(json_extract(ev.source_range_json,''$.line''),0) AS label,'''' AS canonical_key '+
    'FROM evidence ev JOIN file_revisions fr ON fr.file_revision_id=ev.file_revision_id JOIN source_files f ON f.file_id=fr.file_id '+
    'WHERE ev.generation_id=:generation AND (ev.evidence_kind||f.canonical_relpath) LIKE :query ORDER BY ev.evidence_id LIMIT 200'
  else if AKind='screenshot' then SQL:='SELECT artifact_id AS target_id,''Imported PNG #''||artifact_id AS label,'''' AS canonical_key FROM artifacts '+
    'WHERE generation_id=:generation AND kind=''user_screenshot'' AND (''Imported PNG #''||artifact_id) LIKE :query ORDER BY artifact_id LIMIT 200'
  else if AKind='section' then SQL:='SELECT current_revision_id AS target_id,title||'' [revision ''||current_revision_id||'']'' AS label,'''' AS canonical_key FROM knowledge_records '+
    'WHERE project_id=1 AND current_revision_id IS NOT NULL AND :generation>0 AND title LIKE :query ORDER BY title LIMIT 200'
  else raise EDPHStorage.Create('Unknown link candidate kind');
  Result:=TJSONArray.Create; Query:=NewQuery(SQL,[AGeneration,Search]);
  try
    try while not Query.Eof do begin Row:=TJSONObject.Create; Result.AddElement(Row);
      for I:=0 to Query.FieldCount-1 do Row.AddPair(Query.Fields[I].FieldName,Query.Fields[I].AsString);
      Row.AddPair('target_kind',AKind); Row.AddPair('source_generation',TJSONNumber.Create(AGeneration)); Query.Next;
    end;
    except Result.Free; raise; end;
  finally Query.Free; end;
end;
function TDPHKnowledgeStore.TranslationEntries(ARevision: Int64): TJSONArray;
var Query: TFDQuery; Entry: TJSONObject;
begin
  RequireWriter; Result:=TJSONArray.Create;
  Query:=NewQuery('SELECT cache_key FROM translations WHERE knowledge_revision_id=:revision AND cache_key IS NOT NULL ORDER BY translation_id DESC LIMIT 50',[ARevision]);
  try
    try while not Query.Eof do begin Entry:=LoadTranslation(Query.FieldByName('cache_key').AsString); if Entry<>nil then Result.AddElement(Entry); Query.Next; end;
    except Result.Free; raise; end;
  finally Query.Free; end;
end;
function TDPHKnowledgeStore.LoadTranslation(const AKey: string): TJSONObject;
var Query: TFDQuery;
begin
  RequireWriter; Result:=nil;
  Query:=NewQuery('SELECT cache_json,translation_state,coalesce(reviewer,'''') AS reviewer FROM translations WHERE cache_key=:key',[AKey]);
  try
    if Query.Eof then Exit;
    Result:=TJSONObject.ParseJSONValue(Query.FieldByName('cache_json').AsString) as TJSONObject;
    if Result=nil then raise EDPHStorage.Create('Invalid saved translation cache');
    Result.RemovePair('state').Free; Result.AddPair('state',Query.FieldByName('translation_state').AsString);
    Result.RemovePair('reviewer').Free; Result.AddPair('reviewer',Query.FieldByName('reviewer').AsString);
  finally Query.Free; end;
end;
procedure TDPHKnowledgeStore.SaveTranslation(AEntry: TJSONObject);
var Revision: Int64; SourceText: string; Segment: TJSONValue; Query: TFDQuery;
begin
  RequireWriter; Revision:=AEntry.GetValue<Int64>('revision');
  if Scalar('SELECT count(*) FROM knowledge_records WHERE current_revision_id=:revision',[Revision])<>1 then
    raise EDPHStorage.Create('Translate the current saved authored revision');
  SourceText:=''; for Segment in AEntry.GetValue<TJSONArray>('segments') do SourceText:=SourceText+Segment.GetValue<string>('source_text');
  Query:=NewQuery('SELECT body_md FROM knowledge_revisions WHERE knowledge_revision_id=:revision',[Revision]);
  try if Query.Eof or (Query.FieldByName('body_md').AsString<>SourceText) then raise EDPHStorage.Create('Translation source does not match the saved revision'); finally Query.Free; end;
  if AEntry.GetValue<string>('cache_key').Length<>64 then raise EDPHStorage.Create('Invalid translation key');
  FConnection.ExecSQL('INSERT INTO translations(knowledge_revision_id,target_locale,provider_id,provider_version,translated_body,source_hash,translation_state,reviewer,cache_key,cache_json) '+
    'VALUES(:revision,:locale,:provider,:version,:body,:hash,''needs_review'','''',:key,:json) '+
    'ON CONFLICT(knowledge_revision_id,target_locale,provider_id,provider_version) DO UPDATE SET translated_body=excluded.translated_body,source_hash=excluded.source_hash,'+
    'translation_state=''needs_review'',reviewer='''',cache_key=excluded.cache_key,cache_json=excluded.cache_json',
    [Revision,AEntry.GetValue<string>('locale'),AEntry.GetValue<string>('provider'),AEntry.GetValue<string>('provider_version'),
    AEntry.GetValue<TJSONArray>('segments').ToJSON,AEntry.GetValue<string>('source_hash'),AEntry.GetValue<string>('cache_key'),AEntry.ToJSON]);
end;
procedure TDPHKnowledgeStore.ReviewTranslation(const AKey,AReviewer: string);
var Entry: TJSONObject; Revision: Int64;
begin
  RequireWriter;
  if Trim(AReviewer)='' then raise EDPHStorage.Create('Translation review requires a named reviewer');
  Entry:=LoadTranslation(AKey);
  try
    if Entry=nil then raise EDPHStorage.Create('Translation cache entry is no longer available');
    Revision:=Entry.GetValue<Int64>('revision');
    if Entry.GetValue<Integer>('source_fallback_count',0)>0 then raise EDPHStorage.Create('Missing translations cannot be approved');
    if Scalar('SELECT count(*) FROM knowledge_records k WHERE k.current_revision_id=:revision AND NOT EXISTS '+
      '(SELECT 1 FROM review_tasks t WHERE t.knowledge_id=k.knowledge_id AND t.state=''pending'')',[Revision])<>1 then
      raise EDPHStorage.Create('The source section changed or requires review; refresh and review its current revision first');
    FConnection.ExecSQL('UPDATE translations SET translation_state=''verified'',reviewer=:reviewer,cache_json=json_set(cache_json,''$.reviewed_at'',:stamp) WHERE cache_key=:key',[AReviewer,UTCNow,AKey]);
  finally Entry.Free; end;
end;
function TDPHKnowledgeStore.KnowledgeJSON: TJSONArray;
var Query,Detail,LinkDetail: TFDQuery; Row,Item,LinkItem: TJSONObject; Links,History: TJSONArray; I: Integer;
begin
  RequireWriter; Result:=TJSONArray.Create;
  Query:=NewQuery('SELECT k.knowledge_id AS id,k.current_revision_id AS revision,k.kind,k.title,k.state,k.owner,r.body_md AS body,r.editor,r.created_at,r.verification_state AS revision_state,'+
    'r.structured_json,coalesce(r.verified_by,'''') AS reviewer,coalesce(r.verified_at,'''') AS reviewed_at,'+
    'coalesce(s.section_id,''knowledge-''||k.knowledge_id) AS section_id,coalesce(s.document_kind,''engineering'') AS document_kind,'+
    'coalesce(s.audience,''engineer'') AS audience,coalesce(s.source_generation,0) AS source_generation,'+
    'coalesce(q.question_json,'''') AS question_json,'+
    'EXISTS(SELECT 1 FROM review_tasks t WHERE t.knowledge_id=k.knowledge_id AND t.state=''pending'') AS pending '+
    'FROM knowledge_records k JOIN knowledge_revisions r ON r.knowledge_revision_id=k.current_revision_id '+
    'LEFT JOIN document_section_versions s ON s.revision_id=r.knowledge_revision_id LEFT JOIN knowledge_questions q ON q.knowledge_id=k.knowledge_id '+
    'WHERE k.project_id=1 ORDER BY k.knowledge_id',[]);
  try
    while not Query.Eof do begin
      Row:=TJSONObject.Create; Result.AddElement(Row);
      for I:=0 to Query.FieldCount-1 do Row.AddPair(Query.Fields[I].FieldName,Query.Fields[I].AsString);
      Links:=TJSONArray.Create; Row.AddPair('rich_links',Links);
      Detail:=NewQuery(RichLinkProjectionSQL,[Query.FieldByName('revision').AsLargeInt]);
      try while not Detail.Eof do begin Item:=TJSONObject.Create; Links.AddElement(Item); for I:=0 to Detail.FieldCount-1 do Item.AddPair(Detail.Fields[I].FieldName,Detail.Fields[I].AsString); Detail.Next; end; finally Detail.Free; end;
      Links:=TJSONArray.Create; Row.AddPair('backlinks',Links);
      Detail:=NewQuery('SELECT k.knowledge_id,k.title,l.link_role FROM knowledge_revision_links l JOIN knowledge_records k ON k.current_revision_id=l.revision_id '+
        'WHERE l.target_kind=''section'' AND l.target_id=:revision ORDER BY k.knowledge_id',[Query.FieldByName('revision').AsLargeInt]);
      try while not Detail.Eof do begin Item:=TJSONObject.Create; Links.AddElement(Item); for I:=0 to Detail.FieldCount-1 do Item.AddPair(Detail.Fields[I].FieldName,Detail.Fields[I].AsString); Detail.Next; end; finally Detail.Free; end;
      Links:=TJSONArray.Create; Row.AddPair('links',Links);
      Detail:=NewQuery('SELECT coalesce(e.canonical_key,re.canonical_key,'''') AS canonical_key,coalesce(e.entity_kind,re.entity_kind,'''') AS entity_kind,'+
        'coalesce(sf.canonical_relpath,'''') AS source_path,coalesce(l.last_verified_generation_id,0) AS verified_generation '+
        'FROM knowledge_links l LEFT JOIN relationships rel ON rel.relationship_id=l.relationship_id '+
        'LEFT JOIN entities re ON re.entity_id=rel.from_entity_id LEFT JOIN entities e ON e.entity_id=l.entity_id '+
        'LEFT JOIN evidence ev ON ev.evidence_id=coalesce(l.evidence_id,rel.evidence_id) '+
        'LEFT JOIN file_revisions fr ON fr.file_revision_id=ev.file_revision_id LEFT JOIN source_files sf ON sf.file_id=fr.file_id '+
        'WHERE l.knowledge_id=:id AND l.link_role<>''historical_annotation'' ORDER BY l.link_id',[Query.FieldByName('id').AsLargeInt]);
      try while not Detail.Eof do begin Item:=TJSONObject.Create; Links.AddElement(Item); for I:=0 to Detail.FieldCount-1 do Item.AddPair(Detail.Fields[I].FieldName,Detail.Fields[I].AsString); Detail.Next; end; finally Detail.Free; end;
      History:=TJSONArray.Create; Row.AddPair('history',History);
      Detail:=NewQuery('SELECT r.knowledge_revision_id AS revision,r.body_md AS body,r.editor,r.created_at,r.verification_state,coalesce(r.verified_by,'''') AS reviewer,coalesce(r.verified_at,'''') AS reviewed_at,'+
        'r.structured_json,coalesce(s.document_kind,''engineering'') AS document_kind,coalesce(s.audience,''engineer'') AS audience,coalesce(s.source_generation,0) AS source_generation '+
        'FROM knowledge_revisions r LEFT JOIN document_section_versions s ON s.revision_id=r.knowledge_revision_id WHERE r.knowledge_id=:id ORDER BY r.knowledge_revision_id',[Query.FieldByName('id').AsLargeInt]);
      try while not Detail.Eof do begin Item:=TJSONObject.Create; History.AddElement(Item); for I:=0 to Detail.FieldCount-1 do Item.AddPair(Detail.Fields[I].FieldName,Detail.Fields[I].AsString);
        Links:=TJSONArray.Create; Item.AddPair('rich_links',Links);
        LinkDetail:=NewQuery(RichLinkProjectionSQL,[Detail.FieldByName('revision').AsLargeInt]);
        try while not LinkDetail.Eof do begin LinkItem:=TJSONObject.Create; Links.AddElement(LinkItem);
          for I:=0 to LinkDetail.FieldCount-1 do LinkItem.AddPair(LinkDetail.Fields[I].FieldName,LinkDetail.Fields[I].AsString); LinkDetail.Next;
        end; finally LinkDetail.Free; end;
        Detail.Next; end; finally Detail.Free; end;
      Query.Next;
    end;
  except Query.Free; Result.Free; raise; end;
  Query.Free;
end;

procedure TDPHKnowledgeStore.RecordExport(AGenerationID: Int64; const ADirectory,ACanonicalHash,AScope: string; AStale: Boolean);
var BuildState: string;
begin
  RequireWriter; CheckOutsideSource(ADirectory);
  if Scalar('SELECT count(*) FROM analysis_generations WHERE generation_id=:id AND status IN (''current'',''partial'')',[AGenerationID])<>1 then raise EDPHStorage.Create('Export generation is not captured');
  if not AStale and GenerationIsStale(AGenerationID) then raise EDPHStorage.Create('Historical or incomplete export must be explicitly marked stale');
  BuildState:='validated'; if AStale then BuildState:='stale';
  FConnection.StartTransaction;
  try
    FConnection.ExecSQL('INSERT INTO artifacts(project_id,generation_id,kind,artifact_path,content_hash,locale,template_version,build_state) '+
      'VALUES(1,:generation,''handoff'',:path,:hash,''en'',''DPH-WP7-1'',:state)',[AGenerationID,ADirectory,ACanonicalHash,BuildState]);
    FConnection.ExecSQL('INSERT INTO export_jobs(project_id,generation_id,format,scope_json,started_at,finished_at,manifest_hash,status) '+
      'VALUES(1,:generation,''html_docx_jsonl'',:scope,:started,:finished,:hash,:state)',[AGenerationID,AScope,UTCNow,UTCNow,THashSHA2.GetHashStringFromFile(TPath.Combine(ADirectory,'manifest.json')),BuildState]);
    FConnection.Commit;
  except FConnection.Rollback; raise; end;
end;

function TDPHKnowledgeStore.GenerationIsStale(AGenerationID: Int64): Boolean;
begin
  RequireWriter;
  Result:=Status.AnalysisStale or (Status.PublishedGeneration<>AGenerationID) or
    (Scalar('SELECT count(*) FROM analysis_generations g JOIN projects p ON p.project_id=g.project_id '+
      'WHERE g.generation_id=:id AND g.status=''current'' AND g.config_id=p.active_config AND g.manifest_hash=:hash',
      [AGenerationID,ManifestHash(ReadManifest)])<>1);
end;

function TDPHKnowledgeStore.Status: TDPHProjectStatus;
var Query: TFDQuery;
begin
  RequireWriter;
  Query := NewQuery('SELECT coalesce(published_generation_id,0),modification_detected,analysis_stale,'+
    'knowledge_review_needed,analysis_failed,reassessment_requested FROM project_state WHERE project_id=1',[]);
  try
    if Query.Eof then raise EDPHStorage.Create('Project is not initialized');
    Result.PublishedGeneration := Query.Fields[0].AsLargeInt;
    Result.ModificationDetected := (Query.Fields[1].AsInteger <> 0);
    Result.AnalysisStale := (Query.Fields[2].AsInteger <> 0);
    Result.KnowledgeReviewNeeded := (Query.Fields[3].AsInteger <> 0);
    Result.AnalysisFailed := (Query.Fields[4].AsInteger <> 0);
    Result.ReassessmentRequested := (Query.Fields[5].AsInteger <> 0);
  finally Query.Free; end;
end;

procedure TDPHKnowledgeStore.BackupTo(const ADestination: string);
begin
  RequireWriter;
  CheckOutsideSource(ADestination);
  if TFile.Exists(ADestination) then raise EDPHStorage.Create('Backup destination already exists');
  FConnection.ExecSQL('VACUUM main INTO :destination',[TPath.GetFullPath(ADestination)]);
end;

function TDPHKnowledgeStore.IntegrityCheck: string;
var Query: TFDQuery;
begin
  RequireWriter;
  Result := VarToStr(Scalar('PRAGMA integrity_check',[]));
  Query := NewQuery('PRAGMA foreign_key_check',[]);
  try if not Query.Eof then Result := 'foreign key violation'; finally Query.Free; end;
  if Scalar('SELECT count(*) FROM knowledge_revision_links l WHERE l.source_generation IS NULL OR '+
    '(l.target_kind=''entity'' AND NOT EXISTS(SELECT 1 FROM entities e WHERE e.entity_id=l.target_id)) OR '+
    '(l.target_kind=''relationship'' AND NOT EXISTS(SELECT 1 FROM relationships r WHERE r.relationship_id=l.target_id AND r.generation_id=l.source_generation)) OR '+
    '(l.target_kind=''evidence'' AND NOT EXISTS(SELECT 1 FROM evidence e WHERE e.evidence_id=l.target_id AND e.generation_id=l.source_generation)) OR '+
    '(l.target_kind=''screenshot'' AND NOT EXISTS(SELECT 1 FROM artifacts a WHERE a.artifact_id=l.target_id AND a.generation_id=l.source_generation AND a.kind=''user_screenshot'')) OR '+
    '(l.target_kind=''section'' AND NOT EXISTS(SELECT 1 FROM knowledge_revisions r WHERE r.knowledge_revision_id=l.target_id))',[])<>0 then Result:='invalid rich-link target';
end;

procedure TDPHKnowledgeStore.BeginFacts(AGenerationID: Int64);
begin RequireRunning(AGenerationID); if FConnection.InTransaction then raise EDPHStorage.Create('Fact batch already active'); FConnection.StartTransaction; end;
procedure TDPHKnowledgeStore.CommitFacts;
begin RequireWriter; FConnection.Commit; end;
procedure TDPHKnowledgeStore.RollbackFacts;
begin RequireWriter; if FConnection.InTransaction then FConnection.Rollback; end;

class function TDPHKnowledgeStore.ProjectRoot(const ADatabasePath: string): string;
var Connection: TFDConnection; Query: TFDQuery;
begin
  if not TFile.Exists(ADatabasePath) then raise EDPHStorage.Create('Knowledge database does not exist');
  Connection:=TFDConnection.Create(nil); Query:=TFDQuery.Create(nil);
  try
    Connection.LoginPrompt:=False; Connection.Params.Values['DriverID']:='SQLite';
    // A saved SQLite database may have a hot rollback journal after an interrupted
    // writer. SQLite must recover it before even this first SELECT can run.
    Connection.Params.Values['Database']:=ADatabasePath; Connection.Params.Values['OpenMode']:='ReadWrite';
    Connection.Connected:=True; Query.Connection:=Connection; Query.SQL.Text:='SELECT root_uri FROM projects WHERE project_id=1'; Query.Open;
    if Query.Eof then raise EDPHStorage.Create('Knowledge project is not initialized'); Result:=Query.Fields[0].AsString;
  finally Query.Free; Connection.Free; end;
end;

procedure TDPHKnowledgeStore.SaveWorkspaceView(AGenerationID: Int64; const AJSON: string);
var Bytes: TBytes; Hash,Directory,Path: string; Hasher: THashSHA2;
begin
  RequireRunning(AGenerationID);
  Bytes:=TEncoding.UTF8.GetBytes(AJSON);
  if Length(Bytes)>128*1024*1024 then raise EDPHStorage.Create('Workspace view exceeds 128 MiB');
  Hasher:=THashSHA2.Create; Hasher.Update(Bytes); Hash:=Hasher.HashAsString;
  Directory:=FDatabasePath+'.views'; CheckOutsideSource(Directory);
  TDirectory.CreateDirectory(Directory); Path:=TPath.Combine(Directory,Hash+'.json');
  if not TFile.Exists(Path) then TFile.WriteAllBytes(Path,Bytes);
  if THashSHA2.GetHashStringFromFile(Path)<>Hash then raise EDPHStorage.Create('Workspace artifact hash mismatch');
  FConnection.ExecSQL('INSERT INTO artifacts(project_id,generation_id,kind,artifact_path,content_hash,locale,template_version,build_state) '+
    'VALUES(1,:generation,''workspace_view'',:path,:hash,''en'',''DPH-WP4-1'',''captured'')',[AGenerationID,Path,Hash]);
end;

function TDPHKnowledgeStore.LoadWorkspaceView(AGenerationID: Int64; ASkipGenerationParse: Boolean): string;
var Query: TFDQuery; Path,Hash: string; Parsed: TJSONValue;
begin
  RequireWriter; Result:='';
  if AGenerationID=0 then
  begin
    AGenerationID:=Status.PublishedGeneration;
    if AGenerationID=0 then AGenerationID:=Scalar('SELECT coalesce(max(generation_id),0) FROM analysis_generations WHERE status=''partial''',[]);
  end;
  Query:=NewQuery('SELECT artifact_path,content_hash FROM artifacts WHERE generation_id=:generation AND kind=''workspace_view'' ORDER BY artifact_id DESC LIMIT 1',[AGenerationID]);
  try
    if Query.Eof then Exit; Path:=Query.Fields[0].AsString; Hash:=Query.Fields[1].AsString;
    if (Length(Hash)<>64) or not SameText(ExtractFileName(Path),Hash+'.json') then raise EDPHStorage.Create('Workspace artifact path is not managed');
    // Resolve a portable cache only beside this database, never at an old stored absolute path.
    Path:=TPath.Combine(FDatabasePath+'.views',Hash+'.json'); CheckOutsideSource(Path);
    if not TFile.Exists(Path) then raise EDPHStorage.Create('Workspace artifact is missing');
    if (TFile.GetSize(Path)>128*1024*1024) or (THashSHA2.GetHashStringFromFile(Path)<>Hash) then raise EDPHStorage.Create('Workspace artifact is damaged');
    Result:=TEncoding.UTF8.GetString(TFile.ReadAllBytes(Path));
    if not ASkipGenerationParse then begin
      Parsed:=TJSONObject.ParseJSONValue(Result);
      try
        if not (Parsed is TJSONObject) or ((Parsed as TJSONObject).GetValue<Int64>('generation_id')<>AGenerationID) then raise EDPHStorage.Create('Workspace artifact generation mismatch');
      finally Parsed.Free; end;
    end;
  finally Query.Free; end;
end;

procedure TDPHKnowledgeStore.RelocateSource(const ANewRoot: string; AGenerationID: Int64; const AVerifiedManifest: TDPHManifest);
var OldRoot,NewRoot: string;
begin
  RequireWriter;
  if Scalar('SELECT count(*) FROM analysis_generations WHERE generation_id=:id AND status IN (''current'',''partial'',''superseded'')',[AGenerationID])<>1 then
    raise EDPHStorage.Create('Relocation requires a captured terminal generation');
  if (Length(AVerifiedManifest)=0) or (ManifestHash(AVerifiedManifest)<>ManifestHash(ReadManifest(AGenerationID))) then
    raise EDPHStorage.Create('Relocation requires exact captured file identities, hashes and availability');
  OldRoot:=FSourceRoot; NewRoot:=IncludeTrailingPathDelimiter(TPath.GetFullPath(ANewRoot));
  if not TDirectory.Exists(NewRoot) then raise EDPHStorage.Create('Relocated source root is unavailable');
  FSourceRoot:=NewRoot;
  try CheckOutsideSource(FDatabasePath); CheckOutsideSource(FDatabasePath+'.views');
  except FSourceRoot:=OldRoot; raise; end;
  FConnection.StartTransaction;
  try
    FConnection.ExecSQL('UPDATE projects SET root_uri=:root WHERE project_id=1',[NewRoot]);
    FConnection.ExecSQL('INSERT INTO review_tasks(project_id,knowledge_id,reason,state,opened_generation_id) '+
      'SELECT 1,knowledge_id,''Source relocated; confirm evidence context'',''pending'',:generation FROM knowledge_records k '+
      'WHERE state NOT IN (''retired'',''rejected'') AND NOT EXISTS(SELECT 1 FROM review_tasks t WHERE t.knowledge_id=k.knowledge_id AND t.state=''pending'')',[AGenerationID]);
    FConnection.ExecSQL('UPDATE knowledge_records SET state=''needs_review'' WHERE state IN (''verified'',''inferred'')');
    FConnection.ExecSQL('UPDATE project_state SET analysis_stale=1,reassessment_requested=1,knowledge_review_needed=EXISTS(SELECT 1 FROM review_tasks WHERE state=''pending'') WHERE project_id=1');
    FConnection.ExecSQL('UPDATE artifacts SET build_state=''stale'' WHERE kind<>''workspace_view''');
    FConnection.ExecSQL('UPDATE translations SET translation_state=''needs_review''');
    FConnection.ExecSQL('INSERT INTO audit_events(project_id,entity_type,entity_id,action,actor,recorded_at,before_hash,after_hash) '+
      'VALUES(1,''project'',''1'',''source_relocated'',''explicit local relocation'',:stamp,:before,:after)',[UTCNow,THashSHA2.GetHashString(OldRoot),THashSHA2.GetHashString(NewRoot)]);
    FConnection.Commit;
  except FConnection.Rollback; FSourceRoot:=OldRoot; raise; end;
end;

procedure TDPHKnowledgeStore.ImportScreenshot(AGenerationID: Int64; const AFile,AAuthor,ACaption,AEntityKey: string; const AImageKind:string);
var Bytes: TBytes; Hash,Directory,Path,MetadataHash: string; Metadata: TJSONObject; Hasher: THashSHA2; Width,Height: Int64;
begin
  RequireWriter;
  if (Trim(AAuthor)='') or (Trim(ACaption)='') or (Length(AAuthor)>256) or (Length(ACaption)>4096) then raise EDPHStorage.Create('Screenshot requires a named contributor (up to 256 characters) and capture/environment description (up to 4096)');
  if Scalar('SELECT count(*) FROM analysis_generations WHERE generation_id=:id AND status IN (''current'',''partial'',''superseded'')',[AGenerationID])<>1 then raise EDPHStorage.Create('Screenshot requires a captured generation');
  if (AEntityKey<>'') and (Scalar('SELECT count(*) FROM entities e JOIN entity_versions v ON v.entity_id=e.entity_id '+
    'WHERE e.project_id=1 AND e.canonical_key=:key AND v.generation_id=:generation',[AEntityKey,AGenerationID])<>1) then
    raise EDPHStorage.Create('Screenshot link does not exist in the selected generation');
  if (TFile.GetSize(AFile)>20*1024*1024) then raise EDPHStorage.Create('Screenshot exceeds 20 MiB');
  Bytes:=TFile.ReadAllBytes(AFile);
  if Length(Bytes)>20*1024*1024 then raise EDPHStorage.Create('Screenshot changed beyond the supported size limit');
  if (Length(Bytes)<33) or (Bytes[0]<>137) or (Bytes[1]<>80) or (Bytes[2]<>78) or (Bytes[3]<>71) or (Bytes[4]<>13) or (Bytes[5]<>10) or (Bytes[6]<>26) or (Bytes[7]<>10) or
    (Bytes[12]<>73) or (Bytes[13]<>72) or (Bytes[14]<>68) or (Bytes[15]<>82) then raise EDPHStorage.Create('Select a PNG screenshot with a valid IHDR header');
  Width:=Int64(Bytes[16])*16777216+Int64(Bytes[17])*65536+Int64(Bytes[18])*256+Bytes[19];
  Height:=Int64(Bytes[20])*16777216+Int64(Bytes[21])*65536+Int64(Bytes[22])*256+Bytes[23];
  if (Width<1) or (Height<1) or (Width>8192) or (Height>8192) or (Width*Height>32000000) then raise EDPHStorage.Create('Screenshot dimensions exceed the supported bound');
  Hasher:=THashSHA2.Create; Hasher.Update(Bytes); Hash:=Hasher.HashAsString;
  Directory:=FDatabasePath+'.views'; CheckOutsideSource(Directory); TDirectory.CreateDirectory(Directory);
  Path:=TPath.Combine(Directory,Hash+'.png'); if not TFile.Exists(Path) then TFile.WriteAllBytes(Path,Bytes);
  if THashSHA2.GetHashStringFromFile(Path)<>Hash then raise EDPHStorage.Create('Screenshot content hash mismatch');
  if not MatchText(AImageKind,['Screenshot','Sample output','Other teaching image']) then raise EDPHStorage.Create('Choose screenshot, sample output or other teaching image');
  Metadata:=TJSONObject.Create;
  try
    Metadata.AddPair('image',Hash+'.png'); Metadata.AddPair('image_sha256',Hash); Metadata.AddPair('generation_id',TJSONNumber.Create(AGenerationID));
    Metadata.AddPair('author',AAuthor); Metadata.AddPair('caption',ACaption); Metadata.AddPair('entity_key',AEntityKey);
    Metadata.AddPair('image_kind',AImageKind);
    Metadata.AddPair('imported_utc',UTCNow); Metadata.AddPair('verification_state','user_supplied_unverified');
    Metadata.AddPair('provenance','User-selected image; capture time, environment and runtime origin are contributor claims, not observed by DPH');
    Bytes:=TEncoding.UTF8.GetBytes(Metadata.ToJSON); Hasher:=THashSHA2.Create; Hasher.Update(Bytes); MetadataHash:=Hasher.HashAsString;
    Path:=TPath.Combine(Directory,MetadataHash+'.json'); if not TFile.Exists(Path) then TFile.WriteAllBytes(Path,Bytes);
    if THashSHA2.GetHashStringFromFile(Path)<>MetadataHash then raise EDPHStorage.Create('Screenshot metadata hash mismatch');
    FConnection.ExecSQL('INSERT INTO artifacts(project_id,generation_id,kind,artifact_path,content_hash,locale,template_version,build_state) '+
      'VALUES(1,:generation,''user_screenshot'',:path,:hash,''en'',''DPH-LEARNING-1'',''needs_review'')',[AGenerationID,Path,MetadataHash]);
  finally Metadata.Free; end;
end;
function TDPHKnowledgeStore.ScreenshotsJSON: TJSONArray;
var Query: TFDQuery; Hash,Path,Image,ImageHash: string; Row: TJSONObject; C: Char;
begin
  RequireWriter; Result:=TJSONArray.Create;
  Query:=NewQuery('SELECT artifact_id,content_hash FROM artifacts WHERE kind=''user_screenshot'' ORDER BY artifact_id DESC LIMIT 200',[]);
  try
  try
    while not Query.Eof do begin
      Hash:=Query.FieldByName('content_hash').AsString;
      if Length(Hash)<>64 then raise EDPHStorage.Create('Screenshot metadata hash is invalid');
      for C in Hash do if not CharInSet(C,['0'..'9','a'..'f']) then raise EDPHStorage.Create('Screenshot metadata hash is invalid');
      Path:=TPath.Combine(FDatabasePath+'.views',Hash+'.json'); CheckOutsideSource(Path);
      if (Length(Hash)<>64) or not TFile.Exists(Path) or (TFile.GetSize(Path)>1024*1024) or (THashSHA2.GetHashStringFromFile(Path)<>Hash) then raise EDPHStorage.Create('Screenshot metadata is missing or damaged');
      Row:=TJSONObject.ParseJSONValue(TFile.ReadAllText(Path,TEncoding.UTF8)) as TJSONObject;
      try
        if Row=nil then raise EDPHStorage.Create('Screenshot metadata is invalid JSON');
        Image:=Row.GetValue<string>('image'); ImageHash:=Row.GetValue<string>('image_sha256');
        if (Length(ImageHash)<>64) or (Image<>ImageHash+'.png') then raise EDPHStorage.Create('Screenshot image path is not managed');
        for C in ImageHash do if not CharInSet(C,['0'..'9','a'..'f']) then raise EDPHStorage.Create('Screenshot image hash is invalid');
        Path:=TPath.Combine(FDatabasePath+'.views',Image); CheckOutsideSource(Path);
        if not TFile.Exists(Path) or (TFile.GetSize(Path)>20*1024*1024) or (THashSHA2.GetHashStringFromFile(Path)<>ImageHash) then raise EDPHStorage.Create('Screenshot image is missing or damaged');
        Row.AddPair('artifact_hash',Hash); Row.AddPair('artifact_id',TJSONNumber.Create(Query.FieldByName('artifact_id').AsLargeInt));
        Row.AddPair('managed_path',Path); Result.AddElement(Row); Row:=nil;
      finally Row.Free; end;
      Query.Next;
    end;
  except Result.Free; raise;
  end;
  finally Query.Free; end;
end;
function TDPHKnowledgeStore.ImportDataQualityReport(AGenerationID:Int64;const AFile,AAuthor,AContext:string):Int64;
var Bytes,RoundTrip:TBytes;Encoding:TUTF8Encoding;Content,Body,Hash:string;RecordValue:TJSONObject;Hasher:THashSHA2;
begin
 RequireWriter;
 if (AAuthor.Trim='') or (AContext.Trim='') or (Length(AAuthor)>256) or (Length(AContext)>4096) then raise EDPHStorage.Create('Enter a named report contributor and check/environment context (up to 256/4096 characters)');
 if not MatchText(ExtractFileExt(AFile),['.txt','.log','.json']) then raise EDPHStorage.Create('Select a saved UTF-8 .txt, .log or .json check extract');
 if TFile.GetSize(AFile)>32768 then raise EDPHStorage.Create('Check report exceeds 32 KiB; select a focused extract');
 Bytes:=TFile.ReadAllBytes(AFile);
 if (Length(Bytes)=0) or (Length(Bytes)>32768) then raise EDPHStorage.Create('Check report is empty or exceeds 32 KiB');
 Encoding:=TUTF8Encoding.Create(False);
 try Content:=Encoding.GetString(Bytes);RoundTrip:=Encoding.GetBytes(Content);finally Encoding.Free;end;
 if (Length(RoundTrip)<>Length(Bytes)) or not CompareMem(@RoundTrip[0],@Bytes[0],Length(Bytes)) then raise EDPHStorage.Create('Check report must be valid round-trip UTF-8');
 if Content.StartsWith(Char($FEFF)) then Delete(Content,1,1);
 if (Content.Trim='') or ContainsStr(Content,#0) then raise EDPHStorage.Create('Check report must contain text without NUL');
 Hasher:=THashSHA2.Create;Hasher.Update(Bytes);Hash:=Hasher.HashAsString;
 Body:=TDPHWorkspaceView.NewDataQualityRule+sLineBreak+sLineBreak+
  'IMPORTED CHECK REPORT - CONTRIBUTOR CLAIM UNVERIFIED'+sLineBreak+
  'Report context: '+AContext+sLineBreak+'Report contributor: '+AAuthor+sLineBreak+
  'Imported UTC: '+UTCNow+sLineBreak+'Captured generation: '+IntToStr(AGenerationID)+sLineBreak+
  'Original extract SHA256: '+Hash+sLineBreak+
  'Saved text below is literal evidence; no commands, SQL, scripts or markup are executed. Report origin, measurements, timestamps and environment are contributor claims. Named review remains separate.'+sLineBreak+sLineBreak+Content;
 RecordValue:=TJSONObject.Create.AddPair('record_type','data_quality').AddPair('rule_id',TGUID.NewGuid.ToString);
 try Result:=SaveKnowledge(0,0,AGenerationID,'Imported check report: '+AContext,Body,AAuthor,'business_rule','','maintenance','maintainer','','',RecordValue.ToJSON);finally RecordValue.Free;end;
end;
procedure TDPHKnowledgeStore.ImportObservation(AGenerationID: Int64; const AFile,AAuthor,AContext,AEntityKey: string);
var Bytes,RoundTrip: TBytes; Encoding: TUTF8Encoding; Metadata: TJSONObject; Hasher: THashSHA2;
    Content,Hash,Directory,Path,SourceHash: string;
begin
  RequireWriter;
  if (Trim(AAuthor)='') or (Trim(AContext)='') or (Length(AAuthor)>256) or (Length(AContext)>4096) then
    raise EDPHStorage.Create('Enter a named contributor and run/environment description (up to 256/4096 characters)');
  if Scalar('SELECT count(*) FROM analysis_generations WHERE generation_id=:id AND status IN (''current'',''partial'',''superseded'')',[AGenerationID])<>1 then
    raise EDPHStorage.Create('Observation requires a captured generation');
  SourceHash:='';
  if AEntityKey<>'' then begin
    if Scalar('SELECT count(*) FROM entities e JOIN entity_versions v ON v.entity_id=e.entity_id WHERE e.canonical_key=:key AND v.generation_id=:generation',
      [AEntityKey,AGenerationID])<>1 then raise EDPHStorage.Create('Observation target is absent from this generation');
    SourceHash:=VarToStr(Scalar('SELECT fr.sha256 FROM entities e JOIN entity_versions v ON v.entity_id=e.entity_id '+
      'JOIN file_revisions fr ON fr.file_revision_id=v.source_revision_id WHERE e.canonical_key=:key AND v.generation_id=:generation',[AEntityKey,AGenerationID]));
  end;
  if not MatchText(ExtractFileExt(AFile),['.txt','.log','.json']) then raise EDPHStorage.Create('Select an explicitly saved UTF-8 .txt, .log or .json observation');
  if TFile.GetSize(AFile)>256*1024 then raise EDPHStorage.Create('Observation exceeds 256 KiB; select a focused extract with its context');
  Bytes:=TFile.ReadAllBytes(AFile);
  if (Length(Bytes)=0) or (Length(Bytes)>256*1024) then raise EDPHStorage.Create('Observation is empty or changed beyond its size limit');
  Encoding:=TUTF8Encoding.Create(False);
  try Content:=Encoding.GetString(Bytes); RoundTrip:=Encoding.GetBytes(Content); finally Encoding.Free; end;
  if (Length(RoundTrip)<>Length(Bytes)) or not CompareMem(@RoundTrip[0],@Bytes[0],Length(Bytes)) then
    raise EDPHStorage.Create('Observation is not valid round-trip UTF-8 text');
  if Content.StartsWith(Char($FEFF)) then Delete(Content,1,1);
  if (Trim(Content)='') or ContainsStr(Content,#0) then raise EDPHStorage.Create('Observation must contain nonempty UTF-8 text without NUL characters');
  Hasher:=THashSHA2.Create; Hasher.Update(Bytes); Hash:=Hasher.HashAsString;
  Metadata:=TJSONObject.Create;
  try
    Metadata.AddPair('generation_id',TJSONNumber.Create(AGenerationID)); Metadata.AddPair('entity_key',AEntityKey);
    Metadata.AddPair('linked_source_hash',SourceHash); Metadata.AddPair('contributor',AAuthor); Metadata.AddPair('context',AContext);
    Metadata.AddPair('imported_utc',UTCNow); Metadata.AddPair('original_sha256',Hash); Metadata.AddPair('text',Content);
    Metadata.AddPair('verification_state','contributor_claim_unverified');
    Metadata.AddPair('provenance','Explicitly selected saved text; timestamps, runtime origin, environment and causal interpretation are contributor claims. DPH did not run the program or establish event order.');
    Bytes:=TEncoding.UTF8.GetBytes(Metadata.ToJSON); Hasher:=THashSHA2.Create; Hasher.Update(Bytes); Hash:=Hasher.HashAsString;
    Directory:=FDatabasePath+'.views'; CheckOutsideSource(Directory); TDirectory.CreateDirectory(Directory);
    Path:=TPath.Combine(Directory,Hash+'.json'); if not TFile.Exists(Path) then TFile.WriteAllBytes(Path,Bytes);
    if THashSHA2.GetHashStringFromFile(Path)<>Hash then raise EDPHStorage.Create('Observation managed content hash mismatch');
    FConnection.ExecSQL('INSERT INTO artifacts(project_id,generation_id,kind,artifact_path,content_hash,locale,template_version,build_state) '+
      'VALUES(1,:generation,''runtime_observation'',:path,:hash,''en'',''DPH-OBSERVATION-1'',''needs_review'')',[AGenerationID,Path,Hash]);
  finally Metadata.Free; end;
end;
function TDPHKnowledgeStore.ObservationsJSON: TJSONArray;
var Query: TFDQuery; Hash,Path: string; C: Char; Row: TJSONObject;
begin
  RequireWriter; Result:=TJSONArray.Create;
  Query:=NewQuery('SELECT artifact_id,generation_id,content_hash FROM artifacts WHERE kind=''runtime_observation'' ORDER BY artifact_id DESC LIMIT 50',[]);
  try
    try
      while not Query.Eof do begin
        Hash:=Query.FieldByName('content_hash').AsString;
        if Length(Hash)<>64 then raise EDPHStorage.Create('Observation hash is invalid');
        for C in Hash do if not CharInSet(C,['0'..'9','a'..'f']) then raise EDPHStorage.Create('Observation hash is invalid');
        Path:=TPath.Combine(FDatabasePath+'.views',Hash+'.json'); CheckOutsideSource(Path);
        if not TFile.Exists(Path) or (TFile.GetSize(Path)>2*1024*1024) or (THashSHA2.GetHashStringFromFile(Path)<>Hash) then
          raise EDPHStorage.Create('Observation content is missing or damaged');
        Row:=TJSONObject.ParseJSONValue(TFile.ReadAllText(Path,TEncoding.UTF8)) as TJSONObject;
        try
          if (Row=nil) or (Row.GetValue<Int64>('generation_id')<>Query.FieldByName('generation_id').AsLargeInt) then
            raise EDPHStorage.Create('Observation generation metadata is invalid');
          Row.AddPair('artifact_id',TJSONNumber.Create(Query.FieldByName('artifact_id').AsLargeInt)); Row.AddPair('artifact_hash',Hash);
          Result.AddElement(Row); Row:=nil;
        finally Row.Free; end;
        Query.Next;
      end;
    except Result.Free; raise; end;
  finally Query.Free; end;
end;
function TDPHKnowledgeStore.SQLiteVersion: string;
begin RequireWriter; Result := VarToStr(Scalar('SELECT sqlite_version()',[])); end;

procedure TDPHKnowledgeStore.BuildSearchIndex(AGeneration: Int64);
var Revision: Int64; Query: TFDQuery; Match: TMatch; FTS: Boolean;
    Workspace,Asset,Guide,Section: TJSONObject; Assets,Guides,Sections: TJSONArray;
    Value,GuideValue,SectionValue: TJSONValue;
    Root,RelativePath,Path,Ext,Body,Kind: string; FileCount: Integer; TotalBytes,FileBytes: Int64;
begin
  RequireWriter; FTS:=SupportsFTS5;
  if Scalar('SELECT count(*) FROM analysis_generations WHERE generation_id=:id AND status IN (''current'',''partial'')',[AGeneration])<>1 then
    raise EDPHStorage.Create('Search requires a captured generation');
  if FTS then FConnection.ExecSQL('CREATE VIRTUAL TABLE IF NOT EXISTS search_fts USING fts5(title,body)');
  Revision:=Scalar('SELECT coalesce(max(knowledge_revision_id),0) FROM knowledge_revisions',[]);
  if Scalar('SELECT count(*) FROM search_index_state WHERE generation_id=:generation AND knowledge_revision=:revision AND search_version=:version',
    [AGeneration,Revision,'DPH-SEARCH-2-'+BoolToStr(FTS,True)])=1 then Exit;
  FConnection.StartTransaction;
  try
    if FTS then FConnection.ExecSQL('DELETE FROM search_fts WHERE rowid IN (SELECT document_id FROM search_documents WHERE generation_id=:id)',[AGeneration]);
    FConnection.ExecSQL('DELETE FROM search_documents WHERE generation_id=:id',[AGeneration]);
    FConnection.ExecSQL('INSERT INTO search_documents(generation_id,kind,title,body,entity_key,source_path,verification_state) '+
      'SELECT :generation,''object'',e.display_name,v.signature||'' ''||v.structural_json,e.canonical_key,coalesce(f.canonical_relpath,''''),''source-derived'' '+
      'FROM entity_versions v JOIN entities e ON e.entity_id=v.entity_id LEFT JOIN source_files f ON f.file_id=e.owner_file_id '+
      'WHERE v.generation_id=:generation AND e.entity_kind LIKE ''semantic_%''',[AGeneration]);
    FConnection.ExecSQL('INSERT INTO search_documents(generation_id,kind,title,body,entity_key,source_path,verification_state) '+
      'SELECT :generation,''evidence'',e.display_name||'' / ''||c.node_kind,coalesce(c.expression_ref,''''),e.canonical_key,'+
      'coalesce(json_extract(c.source_range_json,''$.source''),''''),''static flow evidence'' '+
      'FROM control_flow_nodes c JOIN entity_versions v ON v.entity_version_id=c.routine_version_id JOIN entities e ON e.entity_id=v.entity_id '+
      'WHERE c.generation_id=:generation',[AGeneration]);
    FConnection.ExecSQL('INSERT INTO search_documents(generation_id,kind,title,body,source_path,verification_state) '+
      'SELECT :generation,''diagnostic'',code,message,coalesce(json_extract(source_range_json,''$.source''),''''),severity '+
      'FROM diagnostics WHERE generation_id=:generation',[AGeneration]);
    FConnection.ExecSQL('INSERT INTO search_documents(generation_id,kind,title,body,knowledge_id,verification_state) '+
      'SELECT :generation,''knowledge'',k.title,r.body_md,k.knowledge_id,k.state FROM knowledge_records k '+
      'JOIN knowledge_revisions r ON r.knowledge_revision_id=k.current_revision_id WHERE k.project_id=1',[AGeneration]);
    Workspace:=TJSONObject.ParseJSONValue(LoadWorkspaceView(AGeneration)) as TJSONObject;
    try
      if Workspace<>nil then begin
        Guides:=Workspace.GetValue<TJSONArray>('project_guides',nil);
        if Guides<>nil then for GuideValue in Guides do begin
          Guide:=GuideValue as TJSONObject;
          RelativePath:=Guide.GetValue<string>('source','');
          Sections:=Guide.GetValue<TJSONArray>('sections',nil);
          if Sections=nil then Continue;
          if Sections.Count=0 then
            FConnection.ExecSQL('INSERT INTO search_documents(generation_id,kind,title,body,source_path,verification_state) '+
              'VALUES(:generation,''guide'',:title,:body,:path,''document inventory only'')',
              [AGeneration,RelativePath,'Document found. Its text was not available to the reader.',RelativePath]);
          for SectionValue in Sections do begin
            Section:=SectionValue as TJSONObject;
            FConnection.ExecSQL('INSERT INTO search_documents(generation_id,kind,title,body,source_path,verification_state) '+
              'VALUES(:generation,''guide'',:title,:body,:path,''captured project document'')',
              [AGeneration,RelativePath+' / '+Section.GetValue<string>('heading',''),
               Section.GetValue<string>('text',''),RelativePath]);
          end;
        end;
        Root:=Workspace.GetValue<string>('root','');
        Assets:=Workspace.GetValue<TJSONArray>('project_assets',nil);
        FileCount:=0; TotalBytes:=0;
        if (Root<>'') and TDirectory.Exists(Root) and (Assets<>nil) then
          for Value in Assets do begin
            if (FileCount>=1000) or (TotalBytes>=64*1024*1024) then Break;
            Asset:=Value as TJSONObject;
            RelativePath:=Asset.GetValue<string>('source','');
            Ext:=LowerCase(Asset.GetValue<string>('format',''));
            if not MatchText(Ext,['.pas','.dpr','.dproj','.groupproj','.fmx','.dfm',
              '.md','.txt','.log','.html','.htm','.json','.xml','.ini','.config',
              '.yml','.yaml','.sql','.contract','.schema']) then Continue;
            try
              Path:=TPath.GetFullPath(TPath.Combine(Root,RelativePath));
              if not StartsText(IncludeTrailingPathDelimiter(TPath.GetFullPath(Root)),Path) or
                 not TFile.Exists(Path) or
                 ((GetFileAttributes(PChar(Path)) and FILE_ATTRIBUTE_REPARSE_POINT)<>0) then Continue;
              FileBytes:=TFile.GetSize(Path);
              if (FileBytes=0) or (FileBytes>1024*1024) or
                 (TotalBytes+FileBytes>64*1024*1024) then Continue;
              Body:=TFile.ReadAllText(Path);
              if MatchText(Ext,['.html','.htm']) then
                Body:=TRegEx.Replace(Body,'<[^>]+>',' ');
              if Length(Body)>262144 then SetLength(Body,262144);
              if Ext='.log' then Kind:='log'
              else if MatchText(Ext,['.md','.txt','.html','.htm']) then Kind:='guide'
              else Kind:='file';
              FConnection.ExecSQL('INSERT INTO search_documents(generation_id,kind,title,body,source_path,verification_state) '+
                'VALUES(:generation,:kind,:title,:body,:path,''current project file; compare with captured source'')',
                [AGeneration,Kind,RelativePath,Body,RelativePath]);
              Inc(FileCount); Inc(TotalBytes,FileBytes);
            except on E: Exception do Continue; end;
          end;
      end;
    finally Workspace.Free; end;
    if FTS then FConnection.ExecSQL('INSERT INTO search_fts(rowid,title,body) SELECT document_id,title,body FROM search_documents WHERE generation_id=:id',[AGeneration])
    else begin
      Query:=NewQuery('SELECT document_id,title,body FROM search_documents WHERE generation_id=:id',[AGeneration]);
      try
        while not Query.Eof do begin
          for Match in TRegEx.Matches(LowerCase(Query.Fields[1].AsString+' '+Query.Fields[2].AsString),'[\p{L}\p{N}_]+') do
            FConnection.ExecSQL('INSERT OR IGNORE INTO search_terms(term,document_id) VALUES(:term,:id)',[Match.Value,Query.Fields[0].AsLargeInt]);
          Query.Next;
        end;
      finally Query.Free; end;
    end;
    FConnection.ExecSQL('INSERT INTO search_index_state(generation_id,knowledge_revision,search_version) VALUES(:id,:revision,:version) '+
      'ON CONFLICT(generation_id) DO UPDATE SET knowledge_revision=excluded.knowledge_revision,search_version=excluded.search_version',
      [AGeneration,Revision,'DPH-SEARCH-2-'+BoolToStr(FTS,True)]);
    FConnection.Commit;
  except FConnection.Rollback; raise; end;
end;

function TDPHKnowledgeStore.SearchProject(AGeneration: Int64; const AQuery,AKind: string; AOffset: Integer): TJSONArray;
var Match: TMatch; ExpressionText,SQLText,Excerpt,FirstWord: string; Query: TFDQuery; Row: TJSONObject; I,TokenCount,ExcerptAt: Integer;
    Values: TArray<Variant>; FTS: Boolean;
begin
  RequireWriter;
  if (Length(AQuery)>1000) or (AOffset<0) or (AOffset>1000000) then raise EDPHStorage.Create('Invalid search query or page');
  if not MatchText(AKind,['','file','guide','log','object','evidence','knowledge','diagnostic']) then raise EDPHStorage.Create('Invalid search category');
  BuildSearchIndex(AGeneration); FTS:=SupportsFTS5; ExpressionText:=''; TokenCount:=0;
  Values:=[AGeneration,AKind];
  for Match in TRegEx.Matches(LowerCase(AQuery),'[\p{L}\p{N}_]+') do begin
    Inc(TokenCount); if TokenCount>12 then raise EDPHStorage.Create('Use at most twelve search words');
    if FTS then begin
      if ExpressionText<>'' then ExpressionText:=ExpressionText+' AND ';
      ExpressionText:=ExpressionText+'"'+Match.Value+'"*';
    end else begin
      ExpressionText:=ExpressionText+' AND d.document_id IN (SELECT document_id FROM search_terms WHERE term LIKE :word'+IntToStr(TokenCount)+')';
      Values:=Values+[Match.Value+'%'];
    end;
  end;
  if TokenCount=0 then raise EDPHStorage.Create('Enter at least one word to search');
  FirstWord:=TRegEx.Match(AQuery,'[\p{L}\p{N}_]+').Value;
  SQLText:='SELECT d.document_id,d.kind,d.title,d.body AS excerpt,d.entity_key,coalesce(d.knowledge_id,0) AS knowledge_id,'+
    'd.source_path,d.verification_state FROM search_documents d ';
  if FTS then SQLText:=SQLText+'JOIN search_fts ON search_fts.rowid=d.document_id ';
  SQLText:=SQLText+'WHERE d.generation_id=:generation AND (:kind='''' OR d.kind=:kind) ';
  if FTS then begin SQLText:=SQLText+'AND search_fts MATCH :query '; Values:=Values+[ExpressionText]; end
  else SQLText:=SQLText+ExpressionText;
  SQLText:=SQLText+' ORDER BY d.kind,d.title,d.document_id LIMIT 50 OFFSET :offset'; Values:=Values+[AOffset];
  Result:=TJSONArray.Create; Query:=NewQuery(SQLText,Values);
  try
    while not Query.Eof do begin
      Row:=TJSONObject.Create; Result.AddElement(Row);
      for I:=0 to Query.FieldCount-1 do begin
        if Query.Fields[I].FieldName='excerpt' then begin
          Excerpt:=Query.Fields[I].AsString;
          ExcerptAt:=Pos(LowerCase(FirstWord),LowerCase(Excerpt));
          if ExcerptAt>180 then Dec(ExcerptAt,180) else ExcerptAt:=1;
          Row.AddPair('excerpt',Copy(Excerpt,ExcerptAt,1200));
        end else Row.AddPair(Query.Fields[I].FieldName,Query.Fields[I].AsString);
      end;
      Query.Next;
    end;
  finally Query.Free; end;
end;

function TDPHKnowledgeStore.ManagedArtifactPaths: TArray<string>;
var Query: TFDQuery; Paths: TList<string>; Hash,Path,ImageHash: string; Metadata: TJSONObject; C: Char;
begin
  RequireWriter; Paths:=TList<string>.Create;
  Query:=NewQuery('SELECT content_hash,kind FROM artifacts WHERE kind IN (''workspace_view'',''user_screenshot'',''runtime_observation'') ORDER BY artifact_id',[]);
  try
    while not Query.Eof do begin
      Hash:=Query.Fields[0].AsString;
      if Length(Hash)<>64 then raise EDPHStorage.Create('Invalid managed artifact identity');
      for C in Hash do if not CharInSet(C,['0'..'9','a'..'f']) then raise EDPHStorage.Create('Invalid managed artifact identity');
      Path:=TPath.Combine(FDatabasePath+'.views',Hash+'.json'); CheckOutsideSource(Path);
      if THashSHA2.GetHashStringFromFile(Path)<>Hash then raise EDPHStorage.Create('Managed artifact is damaged');
      if not Paths.Contains(Path) then Paths.Add(Path);
      if Query.Fields[1].AsString='user_screenshot' then begin
        if TFile.GetSize(Path)>1024*1024 then raise EDPHStorage.Create('Screenshot metadata exceeds limit');
        Metadata:=TJSONObject.ParseJSONValue(TFile.ReadAllText(Path,TEncoding.UTF8)) as TJSONObject;
        try
          if Metadata=nil then raise EDPHStorage.Create('Invalid screenshot metadata');
          ImageHash:=Metadata.GetValue<string>('image_sha256');
          if (Length(ImageHash)<>64) or (Metadata.GetValue<string>('image')<>ImageHash+'.png') then raise EDPHStorage.Create('Invalid screenshot image identity');
          for C in ImageHash do if not CharInSet(C,['0'..'9','a'..'f']) then raise EDPHStorage.Create('Invalid screenshot image identity');
          Path:=TPath.Combine(FDatabasePath+'.views',ImageHash+'.png'); CheckOutsideSource(Path);
          if THashSHA2.GetHashStringFromFile(Path)<>ImageHash then raise EDPHStorage.Create('Screenshot image is damaged');
          if not Paths.Contains(Path) then Paths.Add(Path);
        finally Metadata.Free; end;
      end;
      Query.Next;
    end;
    Result:=Paths.ToArray;
  finally Query.Free; Paths.Free; end;
end;

function TDPHKnowledgeStore.ContinuityCandidates(AGeneration: Int64; const AQuery: string): TJSONArray;
var Query: TFDQuery; Row: TJSONObject; I: Integer;
begin
  RequireWriter; Result:=TJSONArray.Create;
  Query:=NewQuery('SELECT k.knowledge_id,k.current_revision_id,k.title,old.canonical_key AS old_key,old.display_name AS old_name,'+
    'ov.signature AS old_signature,new.canonical_key AS new_key,new.display_name AS new_name,nv.signature AS new_signature,'+
    'old.entity_kind,os.canonical_relpath AS old_file,ns.canonical_relpath AS new_file '+
    'FROM knowledge_records k JOIN knowledge_links l ON l.knowledge_id=k.knowledge_id '+
    'JOIN entities old ON old.entity_id=l.entity_id JOIN entity_versions ov ON ov.entity_id=old.entity_id '+
    'JOIN entities new ON new.entity_kind=old.entity_kind JOIN entity_versions nv ON nv.entity_id=new.entity_id AND nv.generation_id=:generation '+
    'LEFT JOIN source_files os ON os.file_id=old.owner_file_id LEFT JOIN source_files ns ON ns.file_id=new.owner_file_id '+
    'WHERE k.state NOT IN (''retired'',''rejected'') AND l.link_role<>''historical_annotation'' '+
    'AND ov.generation_id=(SELECT max(generation_id) FROM entity_versions WHERE entity_id=old.entity_id) '+
    'AND NOT EXISTS(SELECT 1 FROM entity_versions WHERE entity_id=old.entity_id AND generation_id=:generation) '+
    'AND (instr(ov.signature,''('')=0 OR substr(ov.signature,instr(ov.signature,''(''))=substr(nv.signature,instr(nv.signature,''(''))) '+
    'AND instr(lower(new.display_name||'' ''||coalesce(ns.canonical_relpath,'''')),lower(:query))>0 '+
    'ORDER BY k.knowledge_id,new.display_name LIMIT 500',[AGeneration,AQuery]);
  try
    while not Query.Eof do begin
      Row:=TJSONObject.Create; Result.AddElement(Row);
      for I:=0 to Query.FieldCount-1 do Row.AddPair(Query.Fields[I].FieldName,Query.Fields[I].AsString);
      Query.Next;
    end;
  finally Query.Free; end;
end;

procedure TDPHKnowledgeStore.ApproveContinuity(AKnowledge,AExpectedRevision,AGeneration: Int64;
  const AOldKey,ANewKey,AReviewer: string);
var OldEntity,NewEntity,Revision: Int64; Body,Manifest: string;
begin
  RequireWriter;
  if Trim(AReviewer)='' then raise EDPHStorage.Create('Continuity approval requires a named reviewer');
  Manifest:=VarToStr(Scalar('SELECT manifest_hash FROM analysis_generations WHERE generation_id=:id AND status IN (''current'',''partial'')',[AGeneration]));
  if (Manifest<>ManifestHash(ReadManifest)) or
    (Scalar('SELECT config_id FROM analysis_generations WHERE generation_id=:id',[AGeneration])<>
     Scalar('SELECT active_config FROM projects WHERE project_id=1',[])) then
    raise EDPHStorage.Create('Reassess the current source/configuration before continuity review');
  OldEntity:=VarAsType(Scalar('SELECT coalesce(max(e.entity_id),0) FROM entities e JOIN knowledge_links l ON l.entity_id=e.entity_id '+
    'WHERE l.knowledge_id=:note AND e.canonical_key=:key AND l.link_role<>''historical_annotation'' '+
    'AND NOT EXISTS(SELECT 1 FROM entity_versions WHERE entity_id=e.entity_id AND generation_id=:generation)',[AKnowledge,AOldKey,AGeneration]),varInt64);
  NewEntity:=VarAsType(Scalar('SELECT coalesce(max(e.entity_id),0) FROM entities e JOIN entity_versions v ON v.entity_id=e.entity_id '+
    'WHERE e.canonical_key=:key AND v.generation_id=:generation AND e.entity_kind=(SELECT entity_kind FROM entities WHERE entity_id=:old)',[ANewKey,AGeneration,OldEntity]),varInt64);
  if (OldEntity=0) or (NewEntity=0) then raise EDPHStorage.Create('Select a missing historical link and a current replacement of the same kind');
  FConnection.StartTransaction;
  try
    if Scalar('SELECT count(*) FROM knowledge_records WHERE knowledge_id=:id AND current_revision_id=:revision AND state NOT IN (''retired'',''rejected'')',[AKnowledge,AExpectedRevision])<>1 then
      raise EDPHStorage.Create('Knowledge changed; refresh candidates before approving');
    Body:=VarToStr(Scalar('SELECT body_md FROM knowledge_revisions WHERE knowledge_revision_id=:revision',[AExpectedRevision]));
    FConnection.ExecSQL('UPDATE knowledge_links SET link_role=''historical_annotation'' WHERE knowledge_id=:note AND entity_id=:old',[AKnowledge,OldEntity]);
    FConnection.ExecSQL('INSERT INTO knowledge_links(project_id,knowledge_id,entity_id,link_role) VALUES(1,:note,:new,''reviewed_continuity'')',[AKnowledge,NewEntity]);
    FConnection.ExecSQL('INSERT INTO knowledge_revisions(knowledge_id,body_md,editor,created_at,verification_state,structured_json) VALUES(:note,:body,:reviewer,:stamp,''needs_review'',(SELECT structured_json FROM knowledge_revisions WHERE knowledge_revision_id=:prior))',[AKnowledge,Body,AReviewer,UTCNow,AExpectedRevision]);
    Revision:=Scalar('SELECT last_insert_rowid()',[]);
    FConnection.ExecSQL('UPDATE knowledge_records SET current_revision_id=:revision,state=''needs_review'' WHERE knowledge_id=:note',[Revision,AKnowledge]);
    FConnection.ExecSQL('INSERT INTO knowledge_revision_links SELECT :revision,ordinal,target_kind,target_id,source_generation,link_role,label '+
      'FROM knowledge_revision_links WHERE revision_id=:prior',[Revision,AExpectedRevision]);
    FConnection.ExecSQL('INSERT INTO document_section_versions(revision_id,knowledge_id,section_id,document_kind,audience,source_generation) '+
      'SELECT :revision,knowledge_id,section_id,document_kind,audience,:generation FROM document_section_versions WHERE revision_id=:prior',
      [Revision,AGeneration,AExpectedRevision]);
    FConnection.ExecSQL('INSERT INTO review_tasks(project_id,knowledge_id,reason,state,opened_generation_id) VALUES(1,:note,''Reviewed identity continuity; content requires review'',''pending'',:generation)',[AKnowledge,AGeneration]);
    FConnection.ExecSQL('UPDATE project_state SET knowledge_review_needed=1 WHERE project_id=1');
    FConnection.ExecSQL('UPDATE artifacts SET build_state=''stale'' WHERE kind<>''workspace_view''');
    FConnection.ExecSQL('UPDATE translations SET translation_state=''needs_review'' WHERE knowledge_revision_id IN (SELECT knowledge_revision_id FROM knowledge_revisions WHERE knowledge_id=:note)',[AKnowledge]);
    FConnection.ExecSQL('INSERT INTO audit_events(project_id,entity_type,entity_id,action,actor,recorded_at,before_hash,after_hash) '+
      'VALUES(1,''knowledge'',:note,''Human approved identity continuity'',:reviewer,:stamp,:before,:after)',
      [AKnowledge,AReviewer,UTCNow,THashSHA2.GetHashString(AOldKey),THashSHA2.GetHashString(ANewKey)]);
    FConnection.Commit;
  except FConnection.Rollback; raise; end;
end;

function TDPHKnowledgeStore.RecentRetentionCount: Integer;
begin
  RequireWriter;
  Result:=Scalar('SELECT coalesce((SELECT recent_generations FROM retention_policy WHERE project_id=1),10)',[]);
end;

function TDPHKnowledgeStore.RetentionReport(ARecent: Integer): TJSONArray;
var Query: TFDQuery; Row: TJSONObject; I: Integer;
begin
  RequireWriter;
  if (ARecent<1) or (ARecent>10000) then raise EDPHStorage.Create('Keep between 1 and 10000 recent generations');
  Result:=TJSONArray.Create;
  Query:=NewQuery('SELECT g.generation_id,g.status,g.started_at,coalesce(p.label,'''') AS release_label,'+
    'CASE WHEN g.generation_id=(SELECT min(generation_id) FROM analysis_generations WHERE status IN (''current'',''partial'')) THEN ''baseline'' '+
    'WHEN g.generation_id=(SELECT published_generation_id FROM project_state WHERE project_id=1) THEN ''published head'' '+
    'WHEN g.generation_id=(SELECT max(generation_id) FROM analysis_generations WHERE status IN (''current'',''partial'')) THEN ''latest available'' '+
    'WHEN p.generation_id IS NOT NULL THEN ''retained release'' '+
    'WHEN g.generation_id IN (SELECT generation_id FROM analysis_generations ORDER BY generation_id DESC LIMIT :recent) THEN ''recent'' '+
    'WHEN EXISTS(SELECT 1 FROM knowledge_links WHERE last_verified_generation_id=g.generation_id) OR '+
    'EXISTS(SELECT 1 FROM review_tasks WHERE opened_generation_id=g.generation_id OR resolved_generation_id=g.generation_id) THEN ''knowledge evidence'' '+
    'WHEN EXISTS(SELECT 1 FROM artifacts WHERE generation_id=g.generation_id AND kind IN (''user_screenshot'',''runtime_observation'')) THEN ''contributed image or runtime evidence'' '+
    'ELSE ''eligible cached views'' END AS retention_reason,'+
    '(SELECT count(*) FROM artifacts a WHERE a.generation_id=g.generation_id AND a.kind=''workspace_view'') AS cached_views '+
    'FROM analysis_generations g LEFT JOIN retained_generations p ON p.generation_id=g.generation_id '+
    'WHERE g.status<>''running'' ORDER BY g.generation_id DESC',[ARecent]);
  try
    while not Query.Eof do begin
      Row:=TJSONObject.Create; Result.AddElement(Row);
      for I:=0 to Query.FieldCount-1 do Row.AddPair(Query.Fields[I].FieldName,Query.Fields[I].AsString);
      Query.Next;
    end;
  finally Query.Free; end;
end;

procedure TDPHKnowledgeStore.RetainGeneration(AGeneration: Int64; const ALabel,AReviewer: string);
begin
  RequireWriter;
  if (Trim(ALabel)='') or (Trim(AReviewer)='') then raise EDPHStorage.Create('Release label and named reviewer are required');
  if Scalar('SELECT count(*) FROM analysis_generations WHERE generation_id=:id AND status IN (''current'',''partial'')',[AGeneration])<>1 then
    raise EDPHStorage.Create('Select a completed captured generation');
  FConnection.ExecSQL('INSERT INTO retained_generations(project_id,generation_id,label,reviewer,recorded_at) '+
    'VALUES(1,:id,:label,:reviewer,:stamp) ON CONFLICT(project_id,generation_id) DO UPDATE SET label=excluded.label,reviewer=excluded.reviewer,recorded_at=excluded.recorded_at',
    [AGeneration,ALabel,AReviewer,UTCNow]);
end;

procedure TDPHKnowledgeStore.ApplyRetention(ARecent: Integer);
var Report: TJSONArray; Value: TJSONValue; Row: TJSONObject; Query: TFDQuery;
    Paths: TList<string>; Path,Hash: string; Generation: Int64; HashCharacter: Char;
begin
  RequireWriter; Report:=RetentionReport(ARecent); Paths:=TList<string>.Create;
  try
    // Validate every candidate before changing records or deleting exact files.
    for Value in Report do begin
      Row:=Value as TJSONObject;
      if Row.GetValue<string>('retention_reason')<>'eligible cached views' then Continue;
      Generation:=StrToInt64(Row.GetValue<string>('generation_id'));
      Query:=NewQuery('SELECT content_hash FROM artifacts WHERE generation_id=:id AND kind=''workspace_view''',[Generation]);
      try
        while not Query.Eof do begin
          Hash:=Query.Fields[0].AsString;
          if Length(Hash)<>64 then raise EDPHStorage.Create('Invalid managed artifact hash');
          for HashCharacter in Hash do if not CharInSet(HashCharacter,['0'..'9','a'..'f','A'..'F']) then
            raise EDPHStorage.Create('Invalid managed artifact hash');
          Path:=TPath.Combine(FDatabasePath+'.views',Hash+'.json'); CheckOutsideSource(Path);
          if Hash<>THashSHA2.GetHashStringFromFile(Path) then
            raise EDPHStorage.Create('Retention candidate is missing or damaged; nothing was removed');
          Paths.Add(Path); Query.Next;
        end;
      finally Query.Free; end;
    end;
    FConnection.StartTransaction;
    try
      FConnection.ExecSQL('INSERT INTO retention_policy(project_id,recent_generations) VALUES(1,:recent) '+
        'ON CONFLICT(project_id) DO UPDATE SET recent_generations=excluded.recent_generations',[ARecent]);
      for Value in Report do begin
        Row:=Value as TJSONObject;
        if Row.GetValue<string>('retention_reason')='eligible cached views' then
          FConnection.ExecSQL('DELETE FROM artifacts WHERE generation_id=:id AND kind=''workspace_view''',[StrToInt64(Row.GetValue<string>('generation_id'))]);
      end;
      FConnection.ExecSQL('INSERT INTO audit_events(project_id,entity_type,entity_id,action,actor,recorded_at) VALUES(1,''retention'',1,:action,''local operator'',:stamp)',
        ['Keep baseline, releases, linked evidence and '+IntToStr(ARecent)+' recent cached generations',UTCNow]);
      FConnection.Commit;
    except FConnection.Rollback; raise; end;
    for Path in Paths do
      if TFile.Exists(Path) and (Scalar('SELECT count(*) FROM artifacts WHERE content_hash=:hash',
        [TPath.GetFileNameWithoutExtension(Path)])=0) then TFile.Delete(Path);
    // Generation facts, manual revisions, screenshots and exported files remain immutable.
  finally Paths.Free; Report.Free; end;
end;

function TDPHKnowledgeStore.SupportsFTS5: Boolean;
begin RequireWriter; Result := Scalar('SELECT sqlite_compileoption_used(''ENABLE_FTS5'')',[]) = 1; end;

end.
