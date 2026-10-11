unit DPH.Storage.Backup;
interface
uses DPH.Storage.Database;
type
  TDPHProjectBackup = class
  public
    class procedure Save(AStore: TDPHKnowledgeStore; const ADestination: string); static;
    class procedure Restore(const ABackup,ADestination,AMigrations: string); static;
  end;
implementation
uses System.SysUtils, System.Classes, System.IOUtils, System.JSON, System.Hash,
  System.Generics.Collections, Winapi.Windows;

class procedure TDPHProjectBackup.Save(AStore: TDPHKnowledgeStore; const ADestination: string);
var Files: TArray<string>; Source,Destination,Target,Directory: string;
    Manifest,Hashes: TJSONObject; Created: TList<string>;
begin
  Destination:=TPath.GetFullPath(ADestination); Directory:=Destination+'.views';
  AStore.CheckOutsideSource(Destination); AStore.CheckOutsideSource(Directory);
  if not SameText(ExtractFileExt(Destination),'.dphdb') then raise EArgumentException.Create('Choose a .dphdb backup filename');
  if TFile.Exists(Destination) or TDirectory.Exists(Directory) then raise EInOutError.Create('Backup destination already exists; choose a new filename');
  if AStore.IntegrityCheck<>'ok' then raise EReadError.Create('Database must pass integrity checks before backup');
  Files:=AStore.ManagedArtifactPaths; Created:=TList<string>.Create;
  Manifest:=TJSONObject.Create; Hashes:=TJSONObject.Create; Manifest.AddPair('files',Hashes);
  try
    try
      Created.Add(Destination); AStore.BackupTo(Destination);
      TDirectory.CreateDirectory(Directory);
      for Source in Files do begin
        Target:=TPath.Combine(Directory,TPath.GetFileName(Source)); Created.Add(Target); TFile.Copy(Source,Target);
        Hashes.AddPair(TPath.GetFileName(Target),THashSHA2.GetHashStringFromFile(Target));
      end;
      Manifest.AddPair('backup_version',TJSONNumber.Create(1));
      Manifest.AddPair('database_sha256',THashSHA2.GetHashStringFromFile(Destination));
      Manifest.AddPair('purpose','Consistent SQLite backup plus verified managed views and images. Keep both together.');
      Target:=TPath.Combine(Directory,'backup-manifest.json'); Created.Add(Target);
      TFile.WriteAllText(Target,Manifest.Format(2),TEncoding.UTF8);
    except
      for Target in Created do if TFile.Exists(Target) then TFile.Delete(Target);
      if TDirectory.Exists(Directory) then TDirectory.Delete(Directory,False);
      raise;
    end;
  finally Manifest.Free; Created.Free; end;
end;

class procedure TDPHProjectBackup.Restore(const ABackup,ADestination,AMigrations: string);
var Backup,Destination,Directory,Path,Name,Root: string; Manifest,Hashes: TJSONObject;
    Pair: TJSONPair; C: Char; Store: TDPHKnowledgeStore; Created: TList<string>;
    Attributes: Cardinal;
begin
  Backup:=TPath.GetFullPath(ABackup); Destination:=TPath.GetFullPath(ADestination);
  Directory:=Backup+'.views';
  if not SameText(ExtractFileExt(Destination),'.dphdb') then raise EArgumentException.Create('Choose a .dphdb restore filename');
  if TFile.Exists(Destination) or TDirectory.Exists(Destination+'.views') then raise EInOutError.Create('Restore never overwrites an existing database; choose a new filename');
  // Check ancestors before reading any backup content or creating output.
  for Path in [Backup,Directory,Destination,Destination+'.views'] do begin
    Name:=Path;
    while Name<>'' do begin
      Attributes:=GetFileAttributes(PChar(Name));
      if (Attributes<>INVALID_FILE_ATTRIBUTES) and ((Attributes and FILE_ATTRIBUTE_REPARSE_POINT)<>0) then
        raise EReadError.Create('Linked backup/restore paths are not permitted');
      Root:=TPath.GetDirectoryName(Name); if SameText(Root,Name) then Break; Name:=Root;
    end;
  end;
  Path:=TPath.Combine(Directory,'backup-manifest.json');
  if not TFile.Exists(Path) or (TFile.GetSize(Path)>4*1024*1024) then raise EReadError.Create('Backup manifest is missing or exceeds the supported limit');
  if (GetFileAttributes(PChar(Path)) and FILE_ATTRIBUTE_REPARSE_POINT)<>0 then raise EReadError.Create('Linked backup manifest rejected');
  Manifest:=TJSONObject.ParseJSONValue(TFile.ReadAllText(Path,TEncoding.UTF8)) as TJSONObject;
  Created:=TList<string>.Create;
  try
    if (Manifest=nil) or (Manifest.GetValue<Integer>('backup_version',0)<>1) then raise EReadError.Create('Unsupported backup manifest');
    if THashSHA2.GetHashStringFromFile(Backup)<>Manifest.GetValue<string>('database_sha256') then raise EReadError.Create('Backup database checksum mismatch');
    Hashes:=Manifest.GetValue<TJSONObject>('files');
    if Hashes.Count>20000 then raise EReadError.Create('Backup contains too many managed artifacts');
    for Pair in Hashes do begin
      Name:=Pair.JsonString.Value;
      if (Length(TPath.GetFileNameWithoutExtension(Name))<>64) or
        not ((ExtractFileExt(Name)='.json') or (ExtractFileExt(Name)='.png')) then raise EReadError.Create('Invalid managed backup filename');
      for C in TPath.GetFileNameWithoutExtension(Name) do if not CharInSet(C,['0'..'9','a'..'f']) then raise EReadError.Create('Invalid managed backup filename');
      if TPath.GetFileName(Name)<>Name then raise EReadError.Create('Backup filename traversal rejected');
      Path:=TPath.Combine(Directory,Name);
      if (GetFileAttributes(PChar(Path)) and FILE_ATTRIBUTE_REPARSE_POINT)<>0 then raise EReadError.Create('Linked backup artifact rejected');
      if THashSHA2.GetHashStringFromFile(Path)<>Pair.JsonValue.Value then raise EReadError.Create('Backup artifact checksum mismatch');
    end;
    Root:=TDPHKnowledgeStore.ProjectRoot(Backup);
    if SameText(Destination,ExcludeTrailingPathDelimiter(Root)) or
      Destination.StartsWith(IncludeTrailingPathDelimiter(Root),True) then raise EArgumentException.Create('Restore must stay outside selected project source');
    try
      Created.Add(Destination); TFile.Copy(Backup,Destination);
      TDirectory.CreateDirectory(Destination+'.views');
      for Pair in Hashes do begin
        Name:=Pair.JsonString.Value; Path:=TPath.Combine(Destination+'.views',Name);
        Created.Add(Path); TFile.Copy(TPath.Combine(Directory,Name),Path);
      end;
      Store:=TDPHKnowledgeStore.Create(Destination,Root,AMigrations);
      try
        if Store.IntegrityCheck<>'ok' then raise EReadError.Create('Restored database failed integrity validation');
        Store.ManagedArtifactPaths;
      finally Store.Free; end;
    except
      for Path in Created do if TFile.Exists(Path) then TFile.Delete(Path);
      if TDirectory.Exists(Destination+'.views') then TDirectory.Delete(Destination+'.views',False);
      raise;
    end;
  finally Created.Free; Manifest.Free; end;
end;
end.
