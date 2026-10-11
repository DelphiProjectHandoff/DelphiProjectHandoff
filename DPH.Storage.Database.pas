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
    function LoadWorkspaceView(AGenerationID: Int64 = 0): string;
    procedure BeginFacts(AGenerationID: Int64);
    procedure CommitFacts;
    procedure RollbackFacts;
    function SaveKnowledge(AKnowledgeID,AExpectedRevision,AGenerationID: Int64;
      const ATitle,ABody,AEditor,AKind,AEntityKey: string): Int64;
    procedure ReviewKnowledge(AKnowledgeID,AExpectedRevision,AGenerationID: Int64;
      const AReviewer,AState: string);
    function KnowledgeJSON: TJSONArray;
    procedure RecordExport(AGenerationID: Int64; const ADirectory,ACanonicalHash,AScope: string; AStale: Boolean);
    property DatabasePath: string read FDatabasePath;
  end;

implementation

uses
  System.IOUtils, System.Hash, System.StrUtils, System.DateUtils,
  System.Generics.Defaults, FireDAC.Stan.Def, FireDAC.Stan.Async, FireDAC.Stan.Param,
  FireDAC.DApt, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef,
  FireDAC.Phys.SQLiteWrapper.Stat;

const
  CurrentSchemaVersion = 2;

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
    else MigrationPath := MigrationPath + 'constraints.sql';
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
  const ATitle,ABody,AEditor,AKind,AEntityKey: string): Int64;
var Revision,Entity: Int64; Prior: string;
begin
  RequireWriter;
  if (ATitle.Trim='') or (ABody.Trim='') or (AEditor.Trim='') then raise EDPHStorage.Create('Title, text and named author are required');
  if Length(ABody)>1024*1024 then raise EDPHStorage.Create('Knowledge text exceeds 1 MiB');
  if not MatchText(AKind,['note','business_rule','engineering_rule','user_help','maintenance','build_deploy','troubleshooting','orientation','decision','unknown']) then raise EDPHStorage.Create('Unknown knowledge kind');
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
      if Scalar('SELECT count(*) FROM knowledge_records WHERE project_id=1 AND knowledge_id=:id AND current_revision_id=:revision AND title=:title AND kind=:kind',
        [Result,AExpectedRevision,ATitle,AKind])<>1 then raise EDPHStorage.Create('Knowledge changed since loading, or its stable title/kind was changed; reload first');
      Prior:=VarToStr(Scalar('SELECT body_md FROM knowledge_revisions WHERE knowledge_revision_id=:id',[AExpectedRevision]));
    end;
    FConnection.ExecSQL('INSERT INTO knowledge_revisions(knowledge_id,body_md,editor,created_at,verification_state) VALUES(:id,:body,:author,:stamp,''needs_review'')',[Result,ABody,AEditor,UTCNow]);
    Revision:=Scalar('SELECT last_insert_rowid()',[]);
    FConnection.ExecSQL('UPDATE knowledge_records SET current_revision_id=:revision,state=''needs_review'' WHERE knowledge_id=:id',[Revision,Result]);
    FConnection.ExecSQL('INSERT INTO review_tasks(project_id,knowledge_id,reason,state,opened_generation_id) SELECT 1,:id,''Human content changed'',''pending'',:generation '+
      'WHERE NOT EXISTS(SELECT 1 FROM review_tasks WHERE knowledge_id=:id2 AND state=''pending'')',[Result,AGenerationID,Result]);
    FConnection.ExecSQL('UPDATE project_state SET knowledge_review_needed=1 WHERE project_id=1');
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
    'AND NOT EXISTS(SELECT 1 FROM entity_versions v WHERE v.entity_id=l.entity_id AND v.generation_id=:generation)',[AKnowledgeID,AGenerationID])<>0) then
    raise EDPHStorage.Create('Linked entity is missing or renamed; continuity requires human investigation');
  FConnection.StartTransaction;
  try
    if Scalar('SELECT count(*) FROM knowledge_records WHERE project_id=1 AND knowledge_id=:id AND current_revision_id=:revision',[AKnowledgeID,AExpectedRevision])<>1 then
      raise EDPHStorage.Create('Knowledge revision changed; reload before reviewing');
    Body:=VarToStr(Scalar('SELECT body_md FROM knowledge_revisions WHERE knowledge_revision_id=:id',[AExpectedRevision]));
    FConnection.ExecSQL('INSERT INTO knowledge_revisions(knowledge_id,body_md,editor,created_at,verification_state,verified_by,verified_at) '+
      'VALUES(:id,:body,:editor,:stamp,:state,:reviewer,:reviewed)',[AKnowledgeID,Body,AReviewer,UTCNow,AState,AReviewer,UTCNow]);
    Revision:=Scalar('SELECT last_insert_rowid()',[]);
    FConnection.ExecSQL('UPDATE knowledge_records SET current_revision_id=:revision,state=:state WHERE knowledge_id=:id',[Revision,AState,AKnowledgeID]);
    if AState<>'needs_review' then begin
      FConnection.ExecSQL('UPDATE review_tasks SET state=''resolved'',resolved_generation_id=:generation,reviewer=:reviewer WHERE knowledge_id=:id AND state=''pending''',[AGenerationID,AReviewer,AKnowledgeID]);
      if AState='verified' then FConnection.ExecSQL('UPDATE knowledge_links SET last_verified_generation_id=:generation WHERE knowledge_id=:id',[AGenerationID,AKnowledgeID]);
    end else FConnection.ExecSQL('INSERT INTO review_tasks(project_id,knowledge_id,reason,state,opened_generation_id) SELECT 1,:id,''Human review requested'',''pending'',:generation '+
      'WHERE NOT EXISTS(SELECT 1 FROM review_tasks WHERE knowledge_id=:id2 AND state=''pending'')',[AKnowledgeID,AGenerationID,AKnowledgeID]);
    FConnection.ExecSQL('UPDATE project_state SET knowledge_review_needed=EXISTS(SELECT 1 FROM review_tasks WHERE state=''pending'') WHERE project_id=1');
    FConnection.ExecSQL('UPDATE artifacts SET build_state=''stale'' WHERE kind<>''workspace_view''');
    FConnection.ExecSQL('INSERT INTO audit_events(project_id,entity_type,entity_id,action,actor,recorded_at,after_hash) VALUES(1,''knowledge'',:id,:action,:actor,:stamp,:hash)',
      [AKnowledgeID,AState,AReviewer,UTCNow,THashSHA2.GetHashString(Body)]);
    FConnection.Commit;
  except FConnection.Rollback; raise; end;
end;

function TDPHKnowledgeStore.KnowledgeJSON: TJSONArray;
var Query,Detail: TFDQuery; Row,Item: TJSONObject; Links,History: TJSONArray; I: Integer;
begin
  RequireWriter; Result:=TJSONArray.Create;
  Query:=NewQuery('SELECT k.knowledge_id AS id,k.current_revision_id AS revision,k.kind,k.title,k.state,k.owner,r.body_md AS body,r.editor,r.created_at,r.verification_state AS revision_state,'+
    'coalesce(r.verified_by,'''') AS reviewer,coalesce(r.verified_at,'''') AS reviewed_at,'+
    'EXISTS(SELECT 1 FROM review_tasks t WHERE t.knowledge_id=k.knowledge_id AND t.state=''pending'') AS pending '+
    'FROM knowledge_records k JOIN knowledge_revisions r ON r.knowledge_revision_id=k.current_revision_id WHERE k.project_id=1 ORDER BY k.knowledge_id',[]);
  try
    while not Query.Eof do begin
      Row:=TJSONObject.Create; Result.AddElement(Row);
      for I:=0 to Query.FieldCount-1 do Row.AddPair(Query.Fields[I].FieldName,Query.Fields[I].AsString);
      Links:=TJSONArray.Create; Row.AddPair('links',Links);
      Detail:=NewQuery('SELECT e.canonical_key,e.entity_kind,coalesce(l.last_verified_generation_id,0) AS verified_generation '+
        'FROM knowledge_links l LEFT JOIN entities e ON e.entity_id=l.entity_id WHERE l.knowledge_id=:id ORDER BY l.link_id',[Query.FieldByName('id').AsLargeInt]);
      try while not Detail.Eof do begin Item:=TJSONObject.Create; Links.AddElement(Item); for I:=0 to Detail.FieldCount-1 do Item.AddPair(Detail.Fields[I].FieldName,Detail.Fields[I].AsString); Detail.Next; end; finally Detail.Free; end;
      History:=TJSONArray.Create; Row.AddPair('history',History);
      Detail:=NewQuery('SELECT knowledge_revision_id AS revision,body_md AS body,editor,created_at,verification_state,coalesce(verified_by,'''') AS reviewer,coalesce(verified_at,'''') AS reviewed_at '+
        'FROM knowledge_revisions WHERE knowledge_id=:id ORDER BY knowledge_revision_id',[Query.FieldByName('id').AsLargeInt]);
      try while not Detail.Eof do begin Item:=TJSONObject.Create; History.AddElement(Item); for I:=0 to Detail.FieldCount-1 do Item.AddPair(Detail.Fields[I].FieldName,Detail.Fields[I].AsString); Detail.Next; end; finally Detail.Free; end;
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
  BuildState:='validated'; if AStale then BuildState:='stale';
  FConnection.StartTransaction;
  try
    FConnection.ExecSQL('INSERT INTO artifacts(project_id,generation_id,kind,artifact_path,content_hash,locale,template_version,build_state) '+
      'VALUES(1,:generation,''handoff'',:path,:hash,''en'',''DPH-WP6-1'',:state)',[AGenerationID,ADirectory,ACanonicalHash,BuildState]);
    FConnection.ExecSQL('INSERT INTO export_jobs(project_id,generation_id,format,scope_json,started_at,finished_at,manifest_hash,status) '+
      'VALUES(1,:generation,''html_docx_jsonl'',:scope,:started,:finished,:hash,:state)',[AGenerationID,AScope,UTCNow,UTCNow,THashSHA2.GetHashStringFromFile(TPath.Combine(ADirectory,'manifest.json')),BuildState]);
    FConnection.Commit;
  except FConnection.Rollback; raise; end;
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
    Connection.Params.Values['Database']:=ADatabasePath; Connection.Params.Values['OpenMode']:='ReadOnly';
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

function TDPHKnowledgeStore.LoadWorkspaceView(AGenerationID: Int64): string;
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
    if not SameFileName(TPath.GetFullPath(Path),TPath.Combine(FDatabasePath+'.views',Hash+'.json')) then raise EDPHStorage.Create('Workspace artifact path is not managed');
    if not TFile.Exists(Path) then raise EDPHStorage.Create('Workspace artifact is missing');
    if (TFile.GetSize(Path)>128*1024*1024) or (THashSHA2.GetHashStringFromFile(Path)<>Hash) then raise EDPHStorage.Create('Workspace artifact is damaged');
    Result:=TEncoding.UTF8.GetString(TFile.ReadAllBytes(Path)); Parsed:=TJSONObject.ParseJSONValue(Result);
    try
      if not (Parsed is TJSONObject) or ((Parsed as TJSONObject).GetValue<Int64>('generation_id')<>AGenerationID) then raise EDPHStorage.Create('Workspace artifact generation mismatch');
    finally Parsed.Free; end;
  finally Query.Free; end;
end;

function TDPHKnowledgeStore.SQLiteVersion: string;
begin RequireWriter; Result := VarToStr(Scalar('SELECT sqlite_version()',[])); end;

function TDPHKnowledgeStore.SupportsFTS5: Boolean;
begin RequireWriter; Result := Scalar('SELECT sqlite_compileoption_used(''ENABLE_FTS5'')',[]) = 1; end;

end.
