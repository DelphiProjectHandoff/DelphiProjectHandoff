unit DPH.Workspace.Catalog;

interface

uses System.SysUtils, System.Classes, System.JSON;

type
  TDPHWorkspaceCatalog = class
  private
    FPath, FLastDatabase: string;
    FProjects, FLearningProgress: TJSONArray;
  public
    constructor Create(const APath: string);
    destructor Destroy; override;
    procedure Remember(const ADatabase: string);
    procedure Forget(const ADatabase: string);
    procedure Save;
    function Projects: TJSONArray;
    function LearningProgress(const ADatabase, ALearner, ALesson: string; ARevision: Int64): Integer;
    procedure SetLearningProgress(const ADatabase, ALearner, ALesson: string; ARevision: Int64; ACheckedSteps: Integer);
    class function DefaultPath: string; static;
    property LastDatabase: string read FLastDatabase;
  end;

implementation

uses System.IOUtils, System.Math, Winapi.Windows;

class function TDPHWorkspaceCatalog.DefaultPath: string;
begin
  // Keep the established preferences location and migrate its single entry.
  Result := TPath.Combine(TPath.GetHomePath, 'AppData\Local\DPH\workspace.json');
end;

constructor TDPHWorkspaceCatalog.Create(const APath: string);
var Document: TJSONObject; Value: TJSONValue; Database: string;
begin
  inherited Create;
  FPath := TPath.GetFullPath(APath);
  FProjects := TJSONArray.Create;
  FLearningProgress := TJSONArray.Create;
  if not TFile.Exists(FPath) then Exit;
  Document := TJSONObject.ParseJSONValue(TFile.ReadAllText(FPath, TEncoding.UTF8)) as TJSONObject;
  try
    if Document = nil then raise EReadError.Create('Workspace preferences are not a JSON object');
    if Document.GetValue('learning_progress') is TJSONArray then begin
      FLearningProgress.Free;
      FLearningProgress := Document.GetValue<TJSONArray>('learning_progress').Clone as TJSONArray;
    end;
    if Document.GetValue<Integer>('catalog_version', 1) <> 1 then
      raise EReadError.Create('Unsupported workspace catalog version');
    if Document.GetValue('projects') is TJSONArray then
      for Value in Document.GetValue<TJSONArray>('projects') do
        if Value is TJSONObject then
        begin
          Database := TJSONObject(Value).GetValue<string>('database', '');
          if Database <> '' then Remember(Database);
        end;
    FLastDatabase := '';
    Database := Document.GetValue<string>('database', '');
    if Database <> '' then Remember(Database);
  finally Document.Free; end;
end;

destructor TDPHWorkspaceCatalog.Destroy;
begin
  FProjects.Free;
  FLearningProgress.Free;
  inherited;
end;

procedure TDPHWorkspaceCatalog.Remember(const ADatabase: string);
var Value: TJSONValue; Database: string; Row: TJSONObject;
begin
  Database := TPath.GetFullPath(ADatabase);
  if not SameText(ExtractFileExt(Database), '.dphdb') then
    raise EArgumentException.Create('A project catalog entry must identify a .dphdb database');
  for Value in FProjects do
    if SameFileName(TJSONObject(Value).GetValue<string>('database'), Database) then
    begin FLastDatabase := Database; Exit; end;
  Row := TJSONObject.Create;
  Row.AddPair('database', Database);
  FProjects.AddElement(Row);
  FLastDatabase := Database;
end;

procedure TDPHWorkspaceCatalog.Forget(const ADatabase: string);
var Index: Integer; Database: string;
begin
  Database := TPath.GetFullPath(ADatabase);
  for Index := FProjects.Count - 1 downto 0 do
    if SameFileName(TJSONObject(FProjects.Items[Index]).GetValue<string>('database'), Database) then
      FProjects.Remove(Index).Free;
  if SameFileName(FLastDatabase, Database) then FLastDatabase := '';
end;

function TDPHWorkspaceCatalog.Projects: TJSONArray;
begin Result := FProjects.Clone as TJSONArray; end;

function TDPHWorkspaceCatalog.LearningProgress(const ADatabase, ALearner, ALesson: string; ARevision: Int64): Integer;
var V: TJSONValue; R: TJSONObject;
begin
  Result:=0;
  for V in FLearningProgress do begin
    if not (V is TJSONObject) then Continue;
    R:=V as TJSONObject;
    if SameFileName(R.GetValue<string>('database',''),TPath.GetFullPath(ADatabase)) and
      SameText(R.GetValue<string>('learner',''),ALearner.Trim) and
      (R.GetValue<string>('lesson','')=ALesson) and (R.GetValue<Int64>('revision',0)=ARevision) then
      Exit(EnsureRange(R.GetValue<Integer>('checked_steps',0),0,100));
  end;
end;

procedure TDPHWorkspaceCatalog.SetLearningProgress(const ADatabase, ALearner, ALesson: string; ARevision: Int64; ACheckedSteps: Integer);
var I: Integer; R: TJSONObject; Database: string;
begin
  if (ALearner.Trim='') or (Length(ALearner.Trim)>120) then raise EArgumentException.Create('Enter a learner name of at most 120 characters');
  if (ALesson='') or (ARevision<=0) or (ACheckedSteps<0) or (ACheckedSteps>100) then raise EArgumentException.Create('Invalid learning progress');
  Database:=TPath.GetFullPath(ADatabase);
  for I:=FLearningProgress.Count-1 downto 0 do begin
    if not (FLearningProgress.Items[I] is TJSONObject) then Continue;
    R:=FLearningProgress.Items[I] as TJSONObject;
    if SameFileName(R.GetValue<string>('database',''),Database) and SameText(R.GetValue<string>('learner',''),ALearner.Trim) and
      (R.GetValue<string>('lesson','')=ALesson) then FLearningProgress.Remove(I).Free;
  end;
  FLearningProgress.AddElement(TJSONObject.Create.AddPair('database',Database).AddPair('learner',ALearner.Trim).AddPair('lesson',ALesson).
    AddPair('revision',TJSONNumber.Create(ARevision)).AddPair('checked_steps',TJSONNumber.Create(ACheckedSteps)));
  Save;
end;

procedure TDPHWorkspaceCatalog.Save;
var Document: TJSONObject; TemporaryPath: string;
begin
  TDirectory.CreateDirectory(ExtractFileDir(FPath));
  Document := TJSONObject.Create;
  TemporaryPath := FPath + '.pending';
  try
    Document.AddPair('catalog_version', TJSONNumber.Create(1));
    Document.AddPair('database', FLastDatabase);
    Document.AddPair('projects', FProjects.Clone as TJSONArray);
    Document.AddPair('learning_progress', FLearningProgress.Clone as TJSONArray);
    TFile.WriteAllText(TemporaryPath, Document.Format(2), TEncoding.UTF8);
    if not MoveFileEx(PChar(TemporaryPath), PChar(FPath), MOVEFILE_REPLACE_EXISTING or MOVEFILE_WRITE_THROUGH) then
      RaiseLastOSError;
  finally
    Document.Free;
    if TFile.Exists(TemporaryPath) then TFile.Delete(TemporaryPath);
  end;
end;

end.
