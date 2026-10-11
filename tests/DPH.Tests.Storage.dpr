program DPHStorageTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Hash, System.Variants, Winapi.Windows,
  FireDAC.Comp.Client, FireDAC.Stan.Def, FireDAC.Stan.Async, FireDAC.DApt,
  FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteWrapper.Stat,
  DPH.Storage.Types in '..\DPH.Storage.Types.pas',
  DPH.Storage.Database in '..\DPH.Storage.Database.pas';

var
  Store, SecondWriter: TDPHKnowledgeStore;
  Probe, Reader: TFDConnection;
  RootPath, TestPath, SourceRoot, Migrations, DatabasePath, BackupPath,
    BadMigrations, MigrationDatabase, BadChecksumDirectory, ChildCommand, UpgradeBackup: string;
  Files, ChangedFiles, EmptyFiles: TDPHManifest;
  ConfigID, OtherConfig, FirstGeneration, NextGeneration, EntityID,
    EvidenceID, NoteID: Int64;
  Rejected: Boolean;
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  ChildExitCode: Cardinal;
  QueueThread: TThread;
  QueuedOnWriter, WrongThreadRejected, ValidVersionOneBackup: Boolean;
  SavedHead: Int64;
  StartedWaiting, ElapsedWaiting: UInt64;

procedure Check(ACondition: Boolean; const ATestID, AMessage: string);
begin
  if not ACondition then raise Exception.Create('FAIL ' + ATestID + ': ' + AMessage);
  Writeln('PASS ' + ATestID + ': ' + AMessage);
end;

procedure ExpectSQLFailure(const ASQL, ATestID: string);
var Failed: Boolean;
begin
  Failed := False;
  try Probe.ExecSQL(ASQL); except on E: Exception do Failed := True; end;
  Check(Failed,ATestID,'database rejects invalid mutation');
end;

begin
  Store := nil;
  Probe := nil;
  Reader := nil;
  try
    if ParamStr(1)='--crash-publication' then
    begin
      DatabasePath := ParamStr(2); SourceRoot := ParamStr(3); Migrations := ParamStr(4);
      Store := TDPHKnowledgeStore.Create(DatabasePath,SourceRoot,Migrations);
      ConfigID := Store.AddConfiguration('Win32','37.0','[]','[]','Debug');
      Store.SelectConfiguration(ConfigID);
      NextGeneration := Store.BeginGeneration(ConfigID,'crash-fixture',EmptyFiles);
      Probe := TFDConnection.Create(nil);
      Probe.LoginPrompt := False; Probe.Params.Values['DriverID'] := 'SQLite';
      Probe.Params.Values['Database'] := DatabasePath;
      Probe.Params.Values['LockingMode'] := 'Normal'; Probe.Connected := True;
      Probe.StartTransaction;
      Probe.ExecSQL('UPDATE analysis_generations SET status=''current'' WHERE generation_id='+IntToStr(NextGeneration));
      Probe.ExecSQL('UPDATE project_state SET published_generation_id='+IntToStr(NextGeneration));
      FlushFileBuffers(GetStdHandle(STD_OUTPUT_HANDLE));
      TerminateProcess(GetCurrentProcess,77);
      Halt(78);
    end;
    RootPath := TPath.GetFullPath(ParamStr(1));
    TestPath := TPath.Combine(RootPath,'bin\wp1-tests-' + TGUID.NewGuid.ToString);
    SourceRoot := TPath.Combine(TestPath,'selected-source');
    TDirectory.CreateDirectory(SourceRoot);
    Migrations := TPath.Combine(RootPath,'migrations');
    DatabasePath := TPath.Combine(TestPath,'project.dphdb');
    BackupPath := TPath.Combine(TestPath,'consistent-backup.dphdb');
    Writeln('Test database: ' + DatabasePath);
    TFile.WriteAllText(TPath.Combine(SourceRoot,'one.pas'),'unit One; interface implementation end.',TEncoding.UTF8);
    SetLength(Files,1);
    Files[0].RelativePath := 'one.pas';
    Files[0].SHA256 := THashSHA2.GetHashStringFromFile(TPath.Combine(SourceRoot,'one.pas'));
    Files[0].SizeBytes := TFile.GetSize(TPath.Combine(SourceRoot,'one.pas'));
    Files[0].Kind := 'pas'; Files[0].Encoding := 'UTF-8'; Files[0].Availability := 'available';
    Store := TDPHKnowledgeStore.Create(DatabasePath,SourceRoot,Migrations);
    Store.InitializeProject('Storage fixture','dpr');
    Writeln('SQLite version: ' + Store.SQLiteVersion + '; FTS5 compiled: ' + BoolToStr(Store.SupportsFTS5,True));
    Check(Store.IntegrityCheck='ok','WP1-01','fresh two-version migration and integrity');
    Probe := TFDConnection.Create(nil);
    Probe.LoginPrompt := False; Probe.Params.Values['DriverID'] := 'SQLite';
    Probe.Params.Values['Database'] := DatabasePath;
    Probe.Params.Values['LockingMode'] := 'Normal';
    Probe.Params.Values['ForeignKeys'] := 'On'; Probe.Connected := True;
    Probe.ExecSQL('PRAGMA foreign_keys=ON');
    Check(Probe.ExecSQLScalar('PRAGMA user_version')=5,'WP1-02','schema ledger version 5');
    Rejected := False;
    try SecondWriter := TDPHKnowledgeStore.Create(DatabasePath,SourceRoot,Migrations);
      SecondWriter.Free; except on E: EDPHStorage do Rejected := True; end;
    Check(Rejected,'WP1-03','second DPH writer is rejected');
    Rejected := False;
    try SecondWriter := TDPHKnowledgeStore.Create(TPath.Combine(SourceRoot,'forbidden.dphdb'),SourceRoot,Migrations);
      SecondWriter.Free; except on E: EDPHStorage do Rejected := True; end;
    Check(Rejected and not TFile.Exists(TPath.Combine(SourceRoot,'forbidden.dphdb')),
      'WP1-04','database cannot be created in selected source');
    ConfigID := Store.AddConfiguration('Win32','37.0','[]','[]','Debug');
    Store.SelectConfiguration(ConfigID);
    Store.ObserveManifest(Files);
    Check(Store.Status.ModificationDetected and Store.Status.AnalysisStale,
      'WP1-05','observation sets separate dirty/stale flags');
    FirstGeneration := Store.BeginGeneration(ConfigID,'fixture-1',Files);
    EntityID := Store.AddSourceEntity(FirstGeneration,'one.pas','one','unit','One','unit One',0,10);
    EvidenceID := Store.AddEvidence(FirstGeneration,'one.pas','{"start":0,"end":10}',
      'source','unit declaration fixture','inferred');
    Rejected := False;
    try Store.AddEvidence(FirstGeneration,'one.pas','{"start":0,"end":999999}',
      'source','invalid range','inferred'); except on E: Exception do Rejected := True; end;
    Check(Rejected,'WP1-26','evidence outside captured bytes is rejected');
    Store.AddRelationship(FirstGeneration,EntityID,0,EvidenceID,'calls','unresolved','');
    Probe.ExecSQL('CREATE TRIGGER test_publish_failure BEFORE UPDATE OF published_generation_id ON project_state '+
      'BEGIN SELECT RAISE(ABORT,''Deliberate publication fault''); END;');
    Rejected := False;
    try Store.PublishGeneration(FirstGeneration,Files,'{}',True); except on E: Exception do Rejected := True; end;
    Check(Rejected and (Store.Status.PublishedGeneration=0) and
      (Probe.ExecSQLScalar('SELECT status FROM analysis_generations WHERE generation_id='+IntToStr(FirstGeneration))='running'),
      'WP1-27','mid-publication SQL fault rolls back both generation and head');
    Probe.ExecSQL('DROP TRIGGER test_publish_failure');
    Check(Store.PublishGeneration(FirstGeneration,Files,'{"scope":"storage fixture only"}',True),
      'WP1-06','coherent generation published atomically');
    Check((Store.Status.PublishedGeneration=FirstGeneration) and not Store.Status.AnalysisStale,
      'WP1-07','head and exact-input flags updated');
    NoteID := Store.AddManualNote('Why this exists','Human knowledge stays intact','fixture author',EntityID);
    ChangedFiles := Copy(Files);
    ChangedFiles[0].SHA256 := THashSHA2.GetHashString('new content');
    ChangedFiles[0].SizeBytes := 11;
    NextGeneration := Store.BeginGeneration(ConfigID,'fixture-1',Files);
    Store.ObserveManifest(ChangedFiles);
    Check(not Store.PublishGeneration(NextGeneration,Files,'{}',True),'WP1-08','observed change rejects old captured generation');
    Check((Store.Status.PublishedGeneration=FirstGeneration) and Store.Status.KnowledgeReviewNeeded,
      'WP1-09','old head survives; manual review is pending');
    NextGeneration := Store.BeginGeneration(ConfigID,'fixture-1',ChangedFiles);
    Check(not Store.PublishGeneration(NextGeneration,Files,'{}',True),'WP1-10','revalidation mismatch rejects publish');
    NextGeneration := Store.BeginGeneration(ConfigID,'fixture-1',ChangedFiles);
    EntityID := Store.AddSourceEntity(NextGeneration,'one.pas','one','unit','One','unit One',0,10);
    Rejected := False;
    try Store.AddRelationship(NextGeneration,EntityID,0,EvidenceID,'calls','unresolved','');
      except on E: Exception do Rejected := True; end;
    Check(Rejected,'WP1-11','cross-generation evidence rejected by foreign key');
    Check(Store.PublishGeneration(NextGeneration,ChangedFiles,'{}',True),'WP1-12','fresh captured generation publishes');
    Check(Store.Status.KnowledgeReviewNeeded and
      (Probe.ExecSQLScalar('SELECT body_md FROM knowledge_revisions WHERE knowledge_id='+IntToStr(NoteID))='Human knowledge stays intact'),
      'WP1-13','reparse preserves note and pending human review');
    ExpectSQLFailure('UPDATE evidence SET payload_ref=''tampered'' WHERE evidence_id='+IntToStr(EvidenceID),'WP1-14');
    ExpectSQLFailure('UPDATE analysis_generations SET manifest_hash=''bad'' WHERE generation_id='+IntToStr(FirstGeneration),'WP1-15');
    ExpectSQLFailure('DELETE FROM knowledge_revisions WHERE knowledge_id='+IntToStr(NoteID),'WP1-16');
    Store.RequestReassessment;
    Check(Store.Status.ReassessmentRequested and Store.Status.AnalysisStale,'WP1-17','manual reassessment has its own flag');
    NextGeneration := Store.BeginGeneration(ConfigID,'fixture-1',ChangedFiles);
    Store.FailGeneration(NextGeneration,'deliberate fixture failure');
    Check(Store.Status.AnalysisFailed and (Store.Status.PublishedGeneration<>NextGeneration),
      'WP1-18','failure retains previous published head');
    NextGeneration := Store.BeginGeneration(ConfigID,'fixture-1',ChangedFiles);
    Store.Free; Store := nil;
    Probe.Close;
    Store := TDPHKnowledgeStore.Create(DatabasePath,SourceRoot,Migrations);
    Probe.Open;
    Check(Store.Status.AnalysisFailed and
      (Probe.ExecSQLScalar('SELECT status FROM analysis_generations WHERE generation_id='+IntToStr(NextGeneration))='failed'),
      'WP1-19','abandoned generation recovers with diagnostic');
    Check(Probe.ExecSQLScalar('SELECT count(*) FROM analysis_generations WHERE status=''running''')=0,
      'WP1-34','opening cached data does not start a new analysis');
    OtherConfig := Store.AddConfiguration('Win32','37.0','["OTHER"]','[]','Debug');
    NextGeneration := Store.BeginGeneration(ConfigID,'fixture-1',ChangedFiles);
    Store.SelectConfiguration(OtherConfig);
    Check(not Store.PublishGeneration(NextGeneration,ChangedFiles,'{}',True),'WP1-20','configuration change supersedes capture');
    Store.SelectConfiguration(ConfigID);
    Store.ObserveManifest(EmptyFiles);
    NextGeneration := Store.BeginGeneration(ConfigID,'fixture-1',EmptyFiles);
    Check(Store.PublishGeneration(NextGeneration,EmptyFiles,'{}',True) and
      (Probe.ExecSQLScalar('SELECT count(*) FROM knowledge_links')=1),
      'WP1-21','deleted source retains entity/knowledge history');
    Store.BackupTo(BackupPath);
    Check(TFile.Exists(BackupPath),'WP1-22','consistent SQLite backup produced');
    Store.Free; Store := nil; Probe.Close;
    Store := TDPHKnowledgeStore.Create(BackupPath,SourceRoot,Migrations);
    Check((Store.IntegrityCheck='ok') and (Store.Status.PublishedGeneration=NextGeneration),
      'WP1-23','backup restores with intact head');
    Store.Free; Store := nil;
    Probe.Open;
    Probe.ExecSQL('PRAGMA user_version=999');
    Probe.Close;
    Rejected := False;
    try Store := TDPHKnowledgeStore.Create(DatabasePath,SourceRoot,Migrations);
      except on E: EDPHStorage do Rejected := True; end;
    Check(Rejected,'WP1-24','newer incompatible database rejected');
    Probe.Open; Probe.ExecSQL('PRAGMA user_version=5'); Probe.Close;
    Store := TDPHKnowledgeStore.Create(DatabasePath,SourceRoot,Migrations);
    Store.ObserveManifest(Files);
    ChangedFiles := Copy(Files);
    ChangedFiles[0].Availability := 'unreadable'; ChangedFiles[0].SHA256 := '';
    Store.ObserveManifest(ChangedFiles);
    NextGeneration := Store.BeginGeneration(ConfigID,'fixture-1',ChangedFiles);
    Check(not Store.PublishGeneration(NextGeneration,ChangedFiles,'{}',True) and Store.Status.AnalysisStale,
      'WP1-28','incomplete captured input cannot replace completed head');
    Store.ObserveManifest(EmptyFiles);
    SavedHead := Store.Status.PublishedGeneration;
    Store.Free; Store := nil;
    FillChar(StartupInfo,SizeOf(StartupInfo),0); StartupInfo.cb := SizeOf(StartupInfo);
    ChildCommand := '"'+ParamStr(0)+'" --crash-publication "'+DatabasePath+'" "'+SourceRoot+'" "'+Migrations+'"';
    UniqueString(ChildCommand);
    if not CreateProcess(nil,PChar(ChildCommand),nil,nil,False,CREATE_NO_WINDOW,nil,nil,StartupInfo,ProcessInfo) then RaiseLastOSError;
    try
      if WaitForSingleObject(ProcessInfo.hProcess,15000)<>WAIT_OBJECT_0 then
        raise Exception.Create('Crash test child did not exit');
      GetExitCodeProcess(ProcessInfo.hProcess,ChildExitCode);
    finally CloseHandle(ProcessInfo.hThread); CloseHandle(ProcessInfo.hProcess); end;
    Store := TDPHKnowledgeStore.Create(DatabasePath,SourceRoot,Migrations);
    Check((ChildExitCode=77) and Store.Status.AnalysisFailed and
      (Store.Status.PublishedGeneration=SavedHead),
      'WP1-29','forced process termination recovers prior committed state');
    Store.Free; Store := nil;
    BadMigrations := TPath.Combine(TestPath,'bad-migrations'); TDirectory.CreateDirectory(BadMigrations);
    TFile.Copy(TPath.Combine(Migrations,'001_foundation.sql'),TPath.Combine(BadMigrations,'001_foundation.sql'));
    TFile.WriteAllText(TPath.Combine(BadMigrations,'002_constraints.sql'),
      'CREATE TABLE migration_probe(id INTEGER);'+sLineBreak+'-- DPH STATEMENT'+sLineBreak+'INVALID SQL;',TEncoding.UTF8);
    MigrationDatabase := TPath.Combine(TestPath,'upgrade.dphdb');
    Rejected := False;
    try Store := TDPHKnowledgeStore.Create(MigrationDatabase,SourceRoot,BadMigrations);
      except on E: Exception do Rejected := True; end;
    Probe.Params.Values['Database'] := MigrationDatabase; Probe.Open;
    Check(Rejected and (Probe.ExecSQLScalar('PRAGMA user_version')=1) and
      (Probe.ExecSQLScalar('SELECT count(*) FROM sqlite_master WHERE name=''migration_probe''')=0),
      'WP1-30','failed second migration rolls back DDL and ledger to version 1');
    Probe.ExecSQL('INSERT INTO projects(project_id,name,root_uri,project_kind,created_at,last_opened_at) '+
      'VALUES(1,''Upgrade fixture'',:root,''dpr'',''fixture'',''fixture'')',[IncludeTrailingPathDelimiter(SourceRoot)]);
    Probe.ExecSQL('INSERT INTO project_state(project_id) VALUES(1)');
    Probe.ExecSQL('INSERT INTO knowledge_records(knowledge_id,project_id,kind,title,source_language,state,owner) '+
      'VALUES(1,1,''note'',''Version one note'',''en'',''inferred'',''fixture author'')');
    Probe.ExecSQL('INSERT INTO knowledge_revisions(knowledge_id,body_md,editor,created_at,verification_state) '+
      'VALUES(1,''Preserved through upgrade'',''fixture author'',''fixture'',''inferred'')');
    Probe.Close;
    Store := TDPHKnowledgeStore.Create(MigrationDatabase,SourceRoot,Migrations);
    Store.InitializeProject('Upgrade fixture','dpr');
    Check(Store.IntegrityCheck='ok','WP1-31','version 1 database upgrades successfully after repair');
    Store.Free; Store := nil;
    Probe.Open;
    Check(Probe.ExecSQLScalar('SELECT body_md FROM knowledge_revisions WHERE knowledge_id=1')='Preserved through upgrade',
      'WP1-44','existing manual knowledge survives schema 1 to 2 upgrade');
    Probe.Close;
    ValidVersionOneBackup := False;
    for UpgradeBackup in TDirectory.GetFiles(TestPath,'upgrade.dphdb.pre-v2-*.dphdb') do
    begin
      Probe.Params.Values['Database'] := UpgradeBackup; Probe.Open;
      if (Probe.ExecSQLScalar('PRAGMA user_version')=1) and
        (Probe.ExecSQLScalar('SELECT count(*) FROM knowledge_revisions WHERE body_md=''Preserved through upgrade''')=1) then
        ValidVersionOneBackup := True;
      Probe.Close;
    end;
    Check(ValidVersionOneBackup,'WP1-45','pre-migration backup retains version 1 and existing notes');
    BadChecksumDirectory := TPath.Combine(TestPath,'changed-migrations'); TDirectory.CreateDirectory(BadChecksumDirectory);
    TFile.Copy(TPath.Combine(Migrations,'001_foundation.sql'),TPath.Combine(BadChecksumDirectory,'001_foundation.sql'));
    TFile.Copy(TPath.Combine(Migrations,'002_constraints.sql'),TPath.Combine(BadChecksumDirectory,'002_constraints.sql'));
    TFile.AppendAllText(TPath.Combine(BadChecksumDirectory,'001_foundation.sql'),sLineBreak+'-- changed checksum');
    Rejected := False;
    try Store := TDPHKnowledgeStore.Create(MigrationDatabase,SourceRoot,BadChecksumDirectory);
      except on E: EDPHStorage do Rejected := True; end;
    Check(Rejected,'WP1-32','modified applied migration checksum is rejected');
    ChangedFiles := Copy(Files); ChangedFiles[0].RelativePath := '../escape.pas';
    Rejected := False;
    try TDPHKnowledgeStore.ManifestHash(ChangedFiles); except on E: EDPHStorage do Rejected := True; end;
    Check(Rejected,'WP1-33','manifest path cannot traverse outside project');
    Store := TDPHKnowledgeStore.Create(TPath.Combine(TestPath,'wal.dphdb'),SourceRoot,Migrations,True);
    Store.InitializeProject('WAL fixture','dpr');
    ConfigID := Store.AddConfiguration('Win32','37.0','[]','[]','Debug'); Store.SelectConfiguration(ConfigID);
    Store.ObserveManifest(Files);
    FirstGeneration := Store.BeginGeneration(ConfigID,'fixture-1',Files);
    Check(Store.PublishGeneration(FirstGeneration,Files,'{}',True),'WP1-35','explicit local WAL configuration publishes');
    Reader := TFDConnection.Create(nil);
    Reader.LoginPrompt := False; Reader.Params.Values['DriverID'] := 'SQLite';
    Reader.Params.Values['Database'] := Store.DatabasePath; Reader.Params.Values['LockingMode'] := 'Normal';
    Reader.Params.Values['SharedCache'] := 'False'; Reader.Params.Values['JournalMode'] := 'WAL';
    Reader.Params.Values['OpenMode'] := 'ReadOnly'; Reader.Connected := True;
    Reader.StartTransaction;
    SavedHead := Reader.ExecSQLScalar('SELECT published_generation_id FROM project_state');
    NextGeneration := Store.BeginGeneration(ConfigID,'fixture-1',Files);
    Check(Store.PublishGeneration(NextGeneration,Files,'{}',True) and
      (Reader.ExecSQLScalar('SELECT published_generation_id FROM project_state')=SavedHead),
      'WP1-36','WAL reader retains consistent snapshot while writer publishes');
    Reader.Commit;
    Check(Reader.ExecSQLScalar('SELECT published_generation_id FROM project_state')=NextGeneration,
      'WP1-37','reader sees new generation after releasing snapshot');
    Check(Reader.ExecSQLScalar('SELECT count(*) FROM file_revisions')=1,
      'WP1-38','unchanged source revision reused across generations');
    Reader.Free; Reader := nil;
    QueuedOnWriter := False; WrongThreadRejected := False;
    QueueThread := TThread.CreateAnonymousThread(
      procedure
      begin
        try Store.RequestReassessment; except on E: EDPHStorage do WrongThreadRejected := True; end;
        Store.QueueWrite(
          procedure(AStore: TDPHKnowledgeStore)
          begin AStore.RequestReassessment; QueuedOnWriter := True; end);
      end);
    QueueThread.FreeOnTerminate := False;
    QueueThread.Start; QueueThread.WaitFor; QueueThread.Free;
    Store.ProcessQueuedWrites;
    Check(QueuedOnWriter and WrongThreadRejected and Store.Status.ReassessmentRequested,
      'WP1-39','worker commands queue to owner; direct cross-thread writes rejected');
    Probe.Params.Values['Database'] := Store.DatabasePath;
    Probe.Params.Values['SharedCache'] := 'False'; Probe.Params.Values['JournalMode'] := 'WAL';
    Probe.Open; Probe.StartTransaction;
    Probe.ExecSQL('UPDATE project_state SET reassessment_requested=0');
    Rejected := False; StartedWaiting := GetTickCount64;
    try Store.RequestReassessment; except on E: Exception do Rejected := True; end;
    ElapsedWaiting := GetTickCount64-StartedWaiting;
    Probe.Rollback;
    Store.RequestReassessment;
    Check(Rejected and (ElapsedWaiting>=2000) and (ElapsedWaiting<10000) and Store.Status.ReassessmentRequested,
      'WP1-40','busy writer times out safely and succeeds after lock release');
    Probe.Close;
    TFile.WriteAllText(TPath.Combine(SourceRoot,'two.pas'),'unit Two; interface implementation end.',TEncoding.UTF8);
    ChangedFiles := Copy(Files); SetLength(ChangedFiles,2);
    ChangedFiles[1] := Files[0]; ChangedFiles[1].RelativePath := 'two.pas';
    ChangedFiles[1].SHA256 := THashSHA2.GetHashStringFromFile(TPath.Combine(SourceRoot,'two.pas'));
    ChangedFiles[1].SizeBytes := TFile.GetSize(TPath.Combine(SourceRoot,'two.pas'));
    Store.ObserveManifest(ChangedFiles);
    NextGeneration := Store.BeginGeneration(ConfigID,'fixture-1',ChangedFiles);
    Check(Store.PublishGeneration(NextGeneration,ChangedFiles,'{}',True),'WP1-42','expanded file manifest publishes');
    SavedHead := Store.Status.PublishedGeneration;
    NextGeneration := Store.BeginGeneration(ConfigID,'partial-fixture',ChangedFiles);
    Check(not Store.PublishGeneration(NextGeneration,ChangedFiles,'{"coverage":"partial"}',False) and
      (Store.Status.PublishedGeneration=SavedHead) and Store.Status.AnalysisStale,
      'WP1-46','explicit partial analyzer coverage cannot clear stale state');
    ChangedFiles[1].SHA256 := THashSHA2.GetHashString('two changed');
    ChangedFiles[1].SizeBytes := 11; Store.ObserveManifest(ChangedFiles);
    Probe.Open;
    Check((Probe.ExecSQLScalar('SELECT reassessment_flag FROM source_files WHERE canonical_relpath=''one.pas''')=0) and
      (Probe.ExecSQLScalar('SELECT reassessment_flag FROM source_files WHERE canonical_relpath=''two.pas''')=1),
      'WP1-43','only changed files are flagged for incremental reassessment');
    Probe.Close;
    QueuedOnWriter := False;
    Store.QueueWrite(procedure(AStore: TDPHKnowledgeStore) begin AStore.RequestReassessment; QueuedOnWriter := True; end);
    Store.Free; Store := nil;
    Check(QueuedOnWriter,'WP1-41','graceful store shutdown drains accepted write commands');
    Check(THashSHA2.GetHashStringFromFile(TPath.Combine(SourceRoot,'one.pas'))=Files[0].SHA256,
      'WP1-25','selected fixture source bytes unchanged');
    Writeln('PASS WP1-SUITE');
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      Store.Free; Probe.Free; Reader.Free;
      Halt(1);
    end;
  end;
  Store.Free;
  Probe.Free;
end.
