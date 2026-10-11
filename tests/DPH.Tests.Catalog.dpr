program DPHCatalogTests;
{$APPTYPE CONSOLE}
uses System.SysUtils, System.IOUtils, System.JSON,
  DPH.Workspace.Catalog in '..\DPH.Workspace.Catalog.pas';
var Root,Settings,First,Second: string; Catalog: TDPHWorkspaceCatalog; Rows: TJSONArray;
procedure Check(Condition: Boolean; const MessageText: string);
begin
  if not Condition then raise Exception.Create(MessageText);
  Writeln('PASS: ',MessageText);
end;
begin
  Root:=TPath.Combine(TPath.GetFullPath(ParamStr(1)),'bin\catalog-validation');
  TDirectory.CreateDirectory(Root);
  Settings:=TPath.Combine(Root,'workspace.json');
  First:=TPath.Combine(Root,'first.dphdb'); Second:=TPath.Combine(Root,'second.dphdb');
  try
    TFile.WriteAllText(Settings,'{"database":"'+First.Replace('\','\\')+'"}',TEncoding.UTF8);
    Catalog:=TDPHWorkspaceCatalog.Create(Settings);
    try
      Check(SameFileName(Catalog.LastDatabase,First),'Legacy last database migrates');
      Catalog.Remember(Second); Catalog.Remember(UpperCase(Second)); Catalog.Save;
    finally Catalog.Free; end;
    Catalog:=TDPHWorkspaceCatalog.Create(Settings);
    try
      Rows:=Catalog.Projects;
      try Check(Rows.Count=2,'Multiple entries persist without case duplicates'); finally Rows.Free; end;
      Check(SameFileName(Catalog.LastDatabase,Second),'Last successful project persists');
      TFile.WriteAllText(Second,'preserved'); Catalog.Forget(Second); Catalog.Save;
      Check(TFile.ReadAllText(Second)='preserved','Forget never deletes database contents');
    finally Catalog.Free; end;
    Catalog:=TDPHWorkspaceCatalog.Create(Settings);
    try
      Check(Catalog.LastDatabase='','Forgotten active entry is not reopened');
      Rows:=Catalog.Projects;
      try Check(Rows.Count=1,'Missing database entries remain discoverable'); finally Rows.Free; end;
    finally Catalog.Free; end;
    Check(not TFile.Exists(Settings+'.pending'),'Atomic save leaves no temporary preferences');
  finally
    // Only exact files created by this test; no recursive test-directory deletion.
    for First in [Settings,Settings+'.pending',Second] do if TFile.Exists(First) then TFile.Delete(First);
    TDirectory.Delete(Root,False);
  end;
end.
