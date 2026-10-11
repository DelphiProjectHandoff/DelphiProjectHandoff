unit DPH.Project.Inventory;

interface
uses System.SysUtils, System.Generics.Collections, DPH.Project.Source,
  DPH.Parse.Model, DPH.Storage.Types;
type
  TDPHInventory = class
  private
    FRoot: string;
    FTotalBytes: Int64;
    FDuringDiscovery: Boolean;
    FInitialDefines: TArray<string>;
    FConfig,FPlatform: string;
    FExternalRoots, FSearchPaths: TList<string>;
    FSourcePaths,FSourceNamespaces: TDictionary<string,TArray<string>>;
    FNamespaces: TList<string>;
    FVisited: TDictionary<string,Boolean>;
    FProperties: TDictionary<string,string>;
    FUnavailable: TDictionary<string,TDPHManifestFile>;
    FUnavailablePaths: TDictionary<string,string>;
    function Resolve(const AFrom,AName: string): string;
    function Expand(const AValue: string): string;
    procedure ProjectXML(ASource: TDPHSource; ADepth: Integer);
    procedure Discover(ASource: TDPHSource; ADepth: Integer);
    function Allowed(const APath: string): Boolean;
    function GetConfigurationIdentity: string;
  public
    Sources: TObjectDictionary<string,TDPHSource>;
    ProjectIR: TObjectDictionary<string,TDPHParseResult>;
    SourceDefines: TDictionary<string,TArray<string>>;
    Diagnostics: TDPHDiagnostics;
    Defines: TList<string>;
    Complete: Boolean;
    constructor Create(const AEntry,AConfig,APlatform: string;
      const ADefines,AExternalRoots: TArray<string>);
    destructor Destroy; override;
    function Capture(const AFrom,AName: string): TDPHSource;
    function Manifest: TDPHManifest;
    function CurrentManifest: TDPHManifest;
    function Revalidate: Boolean;
    property Root: string read FRoot;
    property ConfigurationIdentity: string read GetConfigurationIdentity;
  end;
implementation
uses System.IOUtils, System.Classes, System.StrUtils, System.Variants,
  System.Generics.Defaults, Xml.XMLDoc, Xml.XMLIntf, Winapi.Windows,
  DPH.Parse.Lexer, DPH.Parse.Preprocessor;

function TDPHInventory.GetConfigurationIdentity: string;
begin Result:=FConfig+'/'+FPlatform; end;

function TDPHInventory.Allowed(const APath: string): Boolean;
var Boundary,Ancestor: string; Attributes: Cardinal;
begin
  Result:=False;
  for Boundary in FExternalRoots do
    if StartsText(IncludeTrailingPathDelimiter(Boundary),APath) then Result:=True;
  if StartsText(IncludeTrailingPathDelimiter(FRoot),APath) then Result:=True;
  if not Result then Exit;
  Ancestor:=APath;
  while Length(Ancestor)>3 do
  begin
    Attributes:=GetFileAttributes(PChar(Ancestor));
    if (Attributes<>INVALID_FILE_ATTRIBUTES) and ((Attributes and FILE_ATTRIBUTE_REPARSE_POINT)<>0) then Exit(False);
    Ancestor:=ExtractFileDir(Ancestor);
  end;
end;

constructor TDPHInventory.Create(const AEntry,AConfig,APlatform: string;
  const ADefines,AExternalRoots: TArray<string>);
var S: string; Entry: TDPHSource;
begin
  inherited Create;
  FRoot:=ExcludeTrailingPathDelimiter(ExtractFileDir(TPath.GetFullPath(AEntry)));
  FInitialDefines:=Copy(ADefines); FConfig:=AConfig; FPlatform:=APlatform;
  FExternalRoots:=TList<string>.Create; FSearchPaths:=TList<string>.Create;
  FSourcePaths:=TDictionary<string,TArray<string>>.Create;
  FSourceNamespaces:=TDictionary<string,TArray<string>>.Create; FNamespaces:=TList<string>.Create;
  Sources:=TObjectDictionary<string,TDPHSource>.Create([doOwnsValues]);
  ProjectIR:=TObjectDictionary<string,TDPHParseResult>.Create([doOwnsValues]);
  SourceDefines:=TDictionary<string,TArray<string>>.Create;
  FVisited:=TDictionary<string,Boolean>.Create; FUnavailable:=TDictionary<string,TDPHManifestFile>.Create;
  FUnavailablePaths:=TDictionary<string,string>.Create;
  FProperties:=TDictionary<string,string>.Create; Defines:=TList<string>.Create;
  Diagnostics:=TDPHDiagnostics.Create; Complete:=True;
  for S in AExternalRoots do FExternalRoots.Add(ExcludeTrailingPathDelimiter(TPath.GetFullPath(S)));
  for S in ADefines do if not Defines.Contains(S) then Defines.Add(S);
  FProperties.Add('CONFIG',AConfig); FProperties.Add('PLATFORM',APlatform);
  if not MatchText(ExtractFileExt(AEntry),['.dproj','.dpr','.dpk','.groupproj']) then
    raise EArgumentException.Create('Select one Delphi project, program, package or project group');
  Entry:=Capture('',ExtractFileName(AEntry));
  FDuringDiscovery:=True;
  try if Assigned(Entry) then Discover(Entry,0); finally FDuringDiscovery:=False; end;
end;
destructor TDPHInventory.Destroy;
begin
  Diagnostics.Free; Defines.Free; FProperties.Free; FUnavailable.Free; FUnavailablePaths.Free; FVisited.Free;
  FSourcePaths.Free; FSourceNamespaces.Free; FNamespaces.Free;
  SourceDefines.Free; ProjectIR.Free; Sources.Free; FSearchPaths.Free; FExternalRoots.Free; inherited;
end;

function TDPHInventory.Expand(const AValue: string): string;
var Start,Stop,Pass: Integer; Name,Value: string;
begin
  Result:=AValue;
  for Pass:=1 to 32 do
  begin
    Start:=Pos('$(',Result); if Start=0 then Exit;
    Stop:=PosEx(')',Result,Start+2); if Stop=0 then Exit;
    Name:=UpperCase(Copy(Result,Start+2,Stop-Start-2));
    if not FProperties.TryGetValue(Name,Value) then Value:='';
    Result:=Copy(Result,1,Start-1)+Value+Copy(Result,Stop+1,MaxInt);
    if Length(Result)>65536 then raise EReadError.Create('Expanded project property size limit');
  end;
  raise EReadError.Create('Project property expansion limit');
end;

function TDPHInventory.Resolve(const AFrom,AName: string): string;
var Candidate,Base,Search,Namespace: string; Source: TDPHSource;
    Paths,Namespaces: TArray<string>;
begin
  Base:=FRoot;
  if Sources.TryGetValue(AFrom,Source) then Base:=ExtractFileDir(Source.Path);
  Candidate:=StringReplace(AName,'/',PathDelim,[rfReplaceAll]);
  if TPath.IsPathRooted(Candidate) then Result:=TPath.GetFullPath(Candidate)
  else Result:=TPath.GetFullPath(TPath.Combine(Base,Candidate));
  if TFile.Exists(Result) or TPath.IsPathRooted(Candidate) then Exit;
  if not FSourcePaths.TryGetValue(AFrom,Paths) then Paths:=FSearchPaths.ToArray;
  for Search in Paths do
  begin
    Base:=TPath.GetFullPath(TPath.Combine(Search,Candidate));
    if TFile.Exists(Base) and Allowed(Base) then Exit(Base);
  end;
  if not FSourceNamespaces.TryGetValue(AFrom,Namespaces) then Namespaces:=FNamespaces.ToArray;
  if SameText(ExtractFileExt(Candidate),'.pas') and (ExtractFileDir(Candidate)='') then
    for Namespace in Namespaces do
    begin
      if Sources.TryGetValue(AFrom,Source) then Base:=ExtractFileDir(Source.Path) else Base:=FRoot;
      Base:=TPath.Combine(Base,Namespace+'.'+Candidate);
      if TFile.Exists(Base) and Allowed(Base) then Exit(Base);
      for Search in Paths do
      begin Base:=TPath.Combine(Search,Namespace+'.'+Candidate); if TFile.Exists(Base) and Allowed(Base) then Exit(Base); end;
    end;
end;

function TDPHInventory.Capture(const AFrom,AName: string): TDPHSource;
var Path,Key,Ext,Boundary: string; Index: Integer; Item: TDPHManifestFile; Location: TDPHRange;
begin
  Result:=nil; Location:=Default(TDPHRange); Location.Source:=AFrom;
  if (AName='') or AName.Contains('$(') or AName.Contains('%') or AName.Contains('*') or AName.Contains('?') then
  begin Complete:=False; Diagnostics.Report('UNRESOLVED_PATH',AName,Location); Exit; end;
  Path:=Resolve(AFrom,AName);
  if not Allowed(Path) then
  begin Complete:=False; Diagnostics.Report('BOUNDARY_EXCLUDED',Path,Location); Exit; end;
  Key:=LowerCase(StringReplace(ExtractRelativePath(IncludeTrailingPathDelimiter(FRoot),Path),'\','/',[rfReplaceAll]));
  // External files receive a stable, traversal-free namespace for the storage manifest.
  if Key.StartsWith('../') then
    for Index:=0 to FExternalRoots.Count-1 do
    begin
      Boundary:=FExternalRoots[Index];
      if StartsText(IncludeTrailingPathDelimiter(Boundary),Path) then
      begin Key:='external/'+IntToStr(Index)+'/'+LowerCase(StringReplace(ExtractRelativePath(IncludeTrailingPathDelimiter(Boundary),Path),'\','/',[rfReplaceAll])); Break; end;
    end;
  if Sources.TryGetValue(Key,Result) then
  begin
    if not SameFileName(Result.Path,Path) then
    begin Result:=nil; Complete:=False; Diagnostics.Report('PATH_COLLISION',Path,Location,'error'); end;
    if FDuringDiscovery and Assigned(Result) and MatchText(ExtractFileExt(Path),['.pas','.inc']) and
      (String.Join(';',SourceDefines[Key])<>String.Join(';',Defines.ToArray)) then
    begin Complete:=False; Diagnostics.Report('PROJECT_VARIANT_CONFLICT','Shared source requested under multiple define sets: '+Key,Location); end;
    Exit;
  end;
  if Sources.Count>=10000 then raise EReadError.Create('Project acquisition file limit');
  Item:=Default(TDPHManifestFile); Item.RelativePath:=Key; Ext:=LowerCase(ExtractFileExt(Path)); Item.Kind:=Ext;
  try
    if not TFile.Exists(Path) then raise EFileNotFoundException.Create(Path);
    Result:=TDPHSource.Create(Path,Key,Diagnostics,0,not MatchText(Ext,['.pas','.dpr','.dpk','.inc','.dproj','.groupproj','.fmx','.dfm','.rc','.xml','.json','.ini','.txt']));
    if FTotalBytes+Length(Result.Bytes)>128*1024*1024 then
    begin Result.Free; Result:=nil; raise EReadError.Create('Project byte acquisition limit'); end;
    Inc(FTotalBytes,Length(Result.Bytes));
    Sources.Add(Key,Result); FUnavailable.Remove(Key); FUnavailablePaths.Remove(Key);
    SourceDefines.Add(Key,Defines.ToArray);
    FSourcePaths.Add(Key,FSearchPaths.ToArray); FSourceNamespaces.Add(Key,FNamespaces.ToArray);
  except on E: Exception do
    begin
      Complete:=False; Result:=nil; Item.Availability:='unreadable';
      if not TFile.Exists(Path) then Item.Availability:='missing';
      FUnavailable.AddOrSetValue(Key,Item); Diagnostics.Report('FILE_UNAVAILABLE',E.Message,Location,'error');
      FUnavailablePaths.AddOrSetValue(Key,Path);
    end;
  end;
end;

procedure TDPHInventory.ProjectXML(ASource: TDPHSource; ADepth: Integer);
var Document: IXMLDocument; IR: TDPHParseResult; XMLPosition: Integer;
  procedure Fact(Node: IXMLNode; const Kind,Value: string; Parent: Integer);
  var N: TDPHIRNode; Start,Stop,CloseAt: Integer; Tag: string;
  begin
    if IR.Nodes.Count>=DPHMaxNodes then raise EReadError.Create('Project IR node limit');
    N:=Default(TDPHIRNode); N.Kind:=Kind; N.Name:=Node.LocalName; N.Value:=Value; N.Parent:=Parent;
    Tag:='<'+Node.NodeName; Start:=PosEx(Tag,ASource.Text,XMLPosition);
    Stop:=PosEx('>',ASource.Text,Start);
    if (Start>0) and (Stop>0) then
    begin
      XMLPosition:=Stop+1;
      if ASource.Text[Stop-1]<>'/' then
      begin CloseAt:=PosEx('</'+Node.NodeName+'>',ASource.Text,Stop+1); if CloseAt>0 then Stop:=CloseAt+Length(Node.NodeName)+2; end;
      N.Location:=ASource.Range(Start-1,Stop);
    end else
    begin N.Location:=ASource.Range(0,Length(ASource.Text)); IR.Complete:=False; end;
    if Node.HasAttribute('Condition') then N.Condition:=VarToStr(Node.Attributes['Condition']);
    IR.Nodes.Add(N);
  end;
  function ReferencePath(const Value: string): string;
  var Pending,Name: string; Start,Stop: Integer;
  begin
    Pending:=Value;
    while Pos('$(',Pending)>0 do
    begin
      Start:=Pos('$(',Pending); Stop:=PosEx(')',Pending,Start+2);
      if Stop=0 then Exit(Value);
      Name:=UpperCase(Copy(Pending,Start+2,Stop-Start-2));
      if not FProperties.ContainsKey(Name) then Exit(Value);
      Delete(Pending,Start,Stop-Start+1);
    end;
    Result:=Expand(Value);
  end;
  function Enabled(Node: IXMLNode): Boolean;
  var Condition: string; Decision: TDPHActive;
  begin
    Result:=True;
    if not Node.HasAttribute('Condition') then Exit;
    Condition:=Expand(VarToStr(Node.Attributes['Condition']));
    Decision:=TDPHCondition.Evaluate(Condition,FProperties);
    Result:=Decision=daActive;
    if Decision=daUnknown then
    begin Complete:=False; Diagnostics.Report('PROJECT_CONDITION_UNKNOWN',Condition,ASource.Range(0,0)); end;
  end;
  procedure Walk(Node: IXMLNode; Depth: Integer);
  var I: Integer; Child: IXMLNode; Name,Value,Path,Symbol,PropertyName: string; Input: TDPHSource;
  begin
    if Depth>DPHMaxNesting then raise EReadError.Create('Project XML nesting limit');
    if not Enabled(Node) then Exit;
    Name:=Node.LocalName;
    if MatchText(Name,['Project','PropertyGroup','ItemGroup','Import','Target']) then Fact(Node,LowerCase(Name),'',-1);
    if SameText(Name,'PropertyGroup') then
    begin
      for I:=0 to Node.ChildNodes.Count-1 do
      begin
        Child:=Node.ChildNodes[I]; if not Enabled(Child) then Continue;
        Value:=Expand(Child.Text); FProperties.AddOrSetValue(UpperCase(Child.LocalName),Value);
        Fact(Child,'project_property',Value,0);
        if SameText(Child.LocalName,'DCC_Define') then
        begin
          Defines.Clear; Defines.AddRange(FInitialDefines);
          for Symbol in Value.Split([';']) do if (Symbol<>'') and not Defines.Contains(Symbol) then Defines.Add(Symbol);
        end;
        if SameText(Child.LocalName,'DCC_Namespace') then
        begin FNamespaces.Clear; for Symbol in Value.Split([';']) do if Symbol<>'' then FNamespaces.Add(Symbol); end;
        if MatchText(Child.LocalName,['DCC_UnitSearchPath','DCC_IncludePath','DCC_ResourcePath']) then
        begin
          FSearchPaths.Clear;
          for PropertyName in ['DCC_UNITSEARCHPATH','DCC_INCLUDEPATH','DCC_RESOURCEPATH'] do
          begin
          if not FProperties.TryGetValue(PropertyName,Value) then Continue;
          for Path in Value.Split([';']) do if Path<>'' then
          begin
            Value:=TPath.GetFullPath(TPath.Combine(ExtractFileDir(ASource.Path),Path));
            if Allowed(TPath.Combine(Value,'boundary-probe')) then FSearchPaths.Add(Value)
            else begin Complete:=False; Diagnostics.Report('SEARCH_PATH_EXCLUDED',Value,ASource.Range(0,0)); end;
          end;
          end;
        end;
      end;
      Exit;
    end;
    if MatchText(Name,['DelphiCompile','DCCReference','Projects','ProjectReference','None','Content','RcCompile']) and Node.HasAttribute('Include') then
    begin
      Value:=VarToStr(Node.Attributes['Include']);
      Value:=ReferencePath(Value);
      Fact(Node,'project_reference',Value,0);
      if Value.Contains('$(') then
      begin Complete:=False; Diagnostics.Report('PROJECT_PATH_MACRO','Referenced path requires explicit resolved input: '+Value,ASource.Range(0,0)); end
      else
      begin Input:=Capture(ASource.RelativePath,Value); if Assigned(Input) then Discover(Input,ADepth+1); end;
    end;
    if SameText(Name,'Import') then
      Diagnostics.Report('IMPORT_NOT_EXECUTED','Build imports are not executed or acquired',ASource.Range(0,0),'info');
    for I:=0 to Node.ChildNodes.Count-1 do Walk(Node.ChildNodes[I],Depth+1);
  end;
begin
  if not ASource.Decoded then begin Complete:=False; Exit; end;
  if ContainsText(ASource.Text,'<!DOCTYPE') or ContainsText(ASource.Text,'<!ENTITY') then
  begin Complete:=False; Diagnostics.Report('XML_DTD_REJECTED','Project XML entities/DTDs are prohibited',ASource.Range(0,0),'error'); Exit; end;
  Document:=LoadXMLData(ASource.Text); IR:=TDPHParseResult.Create; XMLPosition:=1;
  ProjectIR.Add(ASource.RelativePath,IR); Walk(Document.DocumentElement,0);
end;

procedure TDPHInventory.Discover(ASource: TDPHSource; ADepth: Integer);
var Tokens: TDPHTokens; Token: TDPHToken; P: TDPHPreprocessor; I: Integer;
    Name,Directive,Ext,Previous,Prior: string; Input: TDPHSource;
    SavedProperties: TDictionary<string,string>; Pair: TPair<string,string>;
    SavedDefines,SavedPaths,SavedNamespaces: TArray<string>;
begin
  if ADepth>64 then begin Complete:=False; Diagnostics.Report('PROJECT_DEPTH_LIMIT','Project reference depth',ASource.Range(0,0),'error'); Exit; end;
  if FVisited.ContainsKey(ASource.RelativePath) then Exit;
  FVisited.Add(ASource.RelativePath,True); Ext:=LowerCase(ExtractFileExt(ASource.Path));
  try
    if MatchText(Ext,['.dproj','.groupproj']) then
    begin
      SavedProperties:=TDictionary<string,string>.Create;
      for Pair in FProperties do SavedProperties.Add(Pair.Key,Pair.Value);
      SavedDefines:=Defines.ToArray; SavedPaths:=FSearchPaths.ToArray; SavedNamespaces:=FNamespaces.ToArray;
      try
        FProperties.Clear; FProperties.Add('CONFIG',FConfig); FProperties.Add('PLATFORM',FPlatform);
        Defines.Clear; Defines.AddRange(FInitialDefines); FSearchPaths.Clear; FNamespaces.Clear;
        ProjectXML(ASource,ADepth);
      finally
        FProperties.Clear; for Pair in SavedProperties do FProperties.Add(Pair.Key,Pair.Value);
        SavedProperties.Free; Defines.Clear; Defines.AddRange(SavedDefines);
        FSearchPaths.Clear; FSearchPaths.AddRange(SavedPaths);
        FNamespaces.Clear; FNamespaces.AddRange(SavedNamespaces);
      end;
      Exit;
    end;
    if not MatchText(Ext,['.pas','.dpr','.dpk','.inc']) or not ASource.Decoded then Exit;
    SourceDefines.AddOrSetValue(ASource.RelativePath,Defines.ToArray);
    FSourcePaths.AddOrSetValue(ASource.RelativePath,FSearchPaths.ToArray);
    FSourceNamespaces.AddOrSetValue(ASource.RelativePath,FNamespaces.ToArray);
    P:=TDPHPreprocessor.Create(Defines.ToArray,Diagnostics,
      function(const AFrom,AInclude: string): TDPHSource
      begin Result:=Capture(AFrom,AInclude); end);
    try Tokens:=P.Run(ASource); finally P.Free; end;
    // Dependencies are extracted from active uses/contains/requires clauses, never from directory scans.
    I:=0; Previous:='';
    while I<Length(Tokens) do
    begin
      Token:=Tokens[I]; Inc(I);
      Prior:=Previous;
      if not (Token.Kind in [tkSpace,tkComment,tkDirective]) and (Token.Active=daActive) then Previous:=Token.Text;
      if (Token.Active<>daInactive) and (Token.Kind=tkDirective) then
      begin
        Directive:=Trim(Token.Text);
        if StartsText('{$R ',Directive) or StartsText('{$RESOURCE ',Directive) then
        begin
          Name:=Trim(Copy(Directive,Pos(' ',Directive)+1,Length(Directive)-Pos(' ',Directive)-1)).DeQuotedString('''');
          Name:=StringReplace(Name,'*',TPath.GetFileNameWithoutExtension(ASource.Path),[]);
          Input:=Capture(ASource.RelativePath,Name); if Assigned(Input) then Discover(Input,ADepth+1);
        end;
      end;
      if (Token.Active<>daActive) or (Token.Kind<>tkIdentifier) or
        not MatchText(Token.Text,['uses','contains','requires']) or
        not MatchText(Prior,[';','interface','implementation']) then Continue;
      while I<Length(Tokens) do
      begin
        while (I<Length(Tokens)) and (Tokens[I].Kind in [tkSpace,tkComment,tkDirective]) do Inc(I);
        if (I>=Length(Tokens)) or (Tokens[I].Text=';') then Break;
        if Tokens[I].Active<>daActive then begin Inc(I); Continue; end;
        Name:='';
        while (I<Length(Tokens)) and (((Tokens[I].Kind=tkIdentifier) and not SameText(Tokens[I].Text,'in')) or (Tokens[I].Text='.')) do
        begin Name:=Name+Tokens[I].Text; Inc(I); end;
        while (I<Length(Tokens)) and (Tokens[I].Kind in [tkSpace,tkComment,tkDirective]) do Inc(I);
        if (I<Length(Tokens)) and SameText(Tokens[I].Text,'in') then
        begin
          Inc(I); while (I<Length(Tokens)) and (Tokens[I].Kind in [tkSpace,tkComment]) do Inc(I);
          if (I<Length(Tokens)) and (Tokens[I].Kind=tkString) then begin Name:=Tokens[I].Text.DeQuotedString(''''); Inc(I); end;
        end else if Name<>'' then Name:=Name+'.pas';
        if Name<>'' then
        begin Input:=Capture(ASource.RelativePath,Name); if Assigned(Input) then Discover(Input,ADepth+1); end;
        while (I<Length(Tokens)) and not MatchText(Tokens[I].Text,[',',';']) do Inc(I);
        if (I<Length(Tokens)) and (Tokens[I].Text=',') then Inc(I) else Break;
      end;
    end;
  except on E: Exception do
    begin Complete:=False; Diagnostics.Report('DISCOVERY_ERROR',E.Message,ASource.Range(0,0),'error'); end;
  end;
end;

function TDPHInventory.Manifest: TDPHManifest;
var Items: TList<TDPHManifestFile>; Source: TDPHSource; Item: TDPHManifestFile;
begin
  Items:=TList<TDPHManifestFile>.Create;
  try
    for Source in Sources.Values do
    begin
      Item:=Default(TDPHManifestFile); Item.RelativePath:=Source.RelativePath; Item.SHA256:=LowerCase(Source.SHA256);
      Item.SizeBytes:=Length(Source.Bytes); Item.Encoding:=Source.EncodingName;
      Item.Kind:=LowerCase(ExtractFileExt(Source.Path)); Item.Availability:='available'; Items.Add(Item);
    end;
    for Item in FUnavailable.Values do Items.Add(Item);
    Items.Sort(TComparer<TDPHManifestFile>.Construct(
      function(const L,R: TDPHManifestFile): Integer begin Result:=CompareStr(L.RelativePath,R.RelativePath); end));
    Result:=Items.ToArray;
  finally Items.Free; end;
end;

function TDPHInventory.CurrentManifest: TDPHManifest;
var Source,Current: TDPHSource; Item: TDPHManifestFile; I: Integer; Path: string; RecheckDiagnostics: TDPHDiagnostics;
begin
  Result:=Manifest;
  RecheckDiagnostics:=TDPHDiagnostics.Create;
  try
  for I:=0 to High(Result) do
  begin
    Item:=Result[I]; Path:=TPath.Combine(FRoot,Item.RelativePath);
    if Sources.TryGetValue(Item.RelativePath,Source) then Path:=Source.Path;
    if FUnavailablePaths.ContainsKey(Item.RelativePath) then Path:=FUnavailablePaths[Item.RelativePath];
    try
      if not Allowed(Path) then raise EReadError.Create('Source boundary changed');
      Current:=TDPHSource.Create(Path,Item.RelativePath,RecheckDiagnostics,0,Item.Encoding='opaque-binary');
      try
        Item.SHA256:=LowerCase(Current.SHA256); Item.SizeBytes:=Length(Current.Bytes);
        Item.Encoding:=Current.EncodingName; Item.Availability:='available';
      finally Current.Free; end;
    except
      Item.SHA256:=''; Item.SizeBytes:=0; Item.Availability:='unreadable';
      if not TFile.Exists(Path) then Item.Availability:='missing';
    end;
    Result[I]:=Item;
  end;
  finally RecheckDiagnostics.Free; end;
end;

function TDPHInventory.Revalidate: Boolean;
var Before,After: TDPHManifest; I: Integer;
begin
  Before:=Manifest; After:=CurrentManifest; Result:=True;
  for I:=0 to High(Before) do
    if (Before[I].SHA256<>After[I].SHA256) or (Before[I].Availability<>After[I].Availability) or
      (Before[I].SizeBytes<>After[I].SizeBytes) or (Before[I].Encoding<>After[I].Encoding) then Exit(False);
end;
end.
