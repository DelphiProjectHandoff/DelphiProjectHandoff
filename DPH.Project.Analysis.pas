unit DPH.Project.Analysis;

interface
uses System.SysUtils, System.JSON, System.Generics.Collections, DPH.Project.Inventory,
  DPH.Parse.Model, DPH.Storage.Database;
type
  TDPHScan = class
  public
    Inventory: TDPHInventory;
    Results: TObjectDictionary<string,TDPHParseResult>;
    Complete: Boolean;
    ReusedFiles: Integer;
    constructor Create(AInventory: TDPHInventory);
    destructor Destroy; override;
    function AsJSON(AIncludeComments: Boolean = False): TJSONObject;
    function ContextHash: string;
    function Stage(AStore: TDPHKnowledgeStore; AConfiguration: Int64; const AAnalyzerVersion: string = DPHAnalyzerVersion): Int64;
    function Publish(AStore: TDPHKnowledgeStore; AGeneration: Int64; AAdditionalComplete: Boolean = True): Boolean;
  end;
  TDPHAnalyzer = class
  private
    FCache: TObjectDictionary<string,TDPHParseResult>;
    FDiagnostics: TDictionary<string,TArray<TDPHDiagnostic>>;
  public
    constructor Create;
    destructor Destroy; override;
    function Scan(const AEntry,AConfig,APlatform: string;
      const ADefines,AExternalRoots: TArray<string>; AIncremental: Boolean = True; ACodePage: Integer = 0): TDPHScan;
  end;
implementation
uses System.IOUtils, System.Classes, System.Hash, System.StrUtils,
  DPH.Project.Source, DPH.Parse.Preprocessor, DPH.Parse.Pascal, DPH.Parse.Forms,
  DPH.Storage.Types, DPH.Parse.Resources;

constructor TDPHScan.Create(AInventory: TDPHInventory);
begin inherited Create; Inventory:=AInventory; Results:=TObjectDictionary<string,TDPHParseResult>.Create([doOwnsValues]); end;
destructor TDPHScan.Destroy;
begin Results.Free; Inventory.Free; inherited; end;

function RangeJSON(const ARange: TDPHRange): string;
var J: TJSONObject;
begin
  J:=TJSONObject.Create;
  try
    J.AddPair('source',ARange.Source); J.AddPair('start',TJSONNumber.Create(ARange.StartByte));
    J.AddPair('end',TJSONNumber.Create(ARange.EndByte)); J.AddPair('line',TJSONNumber.Create(ARange.Line));
    J.AddPair('column',TJSONNumber.Create(ARange.Column)); Result:=J.ToJSON;
  finally J.Free; end;
end;

function TDPHScan.AsJSON(AIncludeComments: Boolean): TJSONObject;
var Files,DiagnosticsArray,Comments: TJSONArray; Item: TDPHManifestFile; Row,IR,CommentRow: TJSONObject; Token: TDPHToken; CommentCount: Integer;
    Source: TDPHSource; Parsed: TDPHParseResult; D: TDPHDiagnostic;
begin
  Result:=TJSONObject.Create; Result.AddPair('analyzer',DPHAnalyzerVersion);
  Result.AddPair('schema_version',TJSONNumber.Create(DPHIRVersion));
  Result.AddPair('complete',TJSONBool.Create(Complete)); Files:=TJSONArray.Create; Result.AddPair('files',Files);
  for Item in Inventory.Manifest do
  begin
    Row:=TJSONObject.Create; Files.AddElement(Row); Row.AddPair('path',Item.RelativePath);
    Row.AddPair('sha256',Item.SHA256); Row.AddPair('bytes',TJSONNumber.Create(Item.SizeBytes));
    Row.AddPair('kind',Item.Kind); Row.AddPair('encoding',Item.Encoding); Row.AddPair('availability',Item.Availability);
    if Inventory.Sources.TryGetValue(Item.RelativePath,Source) then Row.AddPair('line_endings',Source.LineEndings);
    if Results.TryGetValue(Item.RelativePath,Parsed) then begin
      IR:=Parsed.AsJSON; Row.AddPair('ir',IR);
      if AIncludeComments then begin
      Comments:=TJSONArray.Create; Row.AddPair('comments',Comments); CommentCount:=0;
      for Token in Parsed.Tokens do if (Token.Kind=tkComment) and (Token.Location.Source=Item.RelativePath) then begin
        CommentRow:=TJSONObject.Create; CommentRow.AddPair('text',Copy(Token.Text,1,4000));
        CommentRow.AddPair('range',TJSONObject.ParseJSONValue(RangeJSON(Token.Location))); CommentRow.AddPair('source_hash',Item.SHA256); Comments.AddElement(CommentRow);
        Inc(CommentCount); if CommentCount>=200 then Break;
      end;
      end;
    end;
  end;
  DiagnosticsArray:=TJSONArray.Create; Result.AddPair('diagnostics',DiagnosticsArray);
  for D in Inventory.Diagnostics do
  begin
    Row:=TJSONObject.Create; DiagnosticsArray.AddElement(Row); Row.AddPair('code',D.Code);
    Row.AddPair('severity',D.Severity); Row.AddPair('message',D.MessageText);
    Row.AddPair('range',TJSONObject.ParseJSONValue(RangeJSON(D.Location)));
  end;
end;

function TDPHScan.ContextHash: string;
var Item: TDPHManifestFile; Value: string; Defines: TArray<string>;
begin
  Value:=DPHAnalyzerVersion+'|'+Inventory.Root+'|'+Inventory.ConfigurationIdentity+'|'+TDPHKnowledgeStore.ManifestHash(Inventory.Manifest);
  for Item in Inventory.Manifest do if Inventory.SourceDefines.TryGetValue(Item.RelativePath,Defines) then
    Value:=Value+'|'+Item.RelativePath+'='+String.Join(';',Defines);
  Result:=THashSHA2.GetHashString(Value);
end;

function TDPHScan.Stage(AStore: TDPHKnowledgeStore; AConfiguration: Int64; const AAnalyzerVersion: string): Int64;
var Item: TDPHManifestFile; Parsed: TDPHParseResult; J: TJSONObject; D: TDPHDiagnostic;
    Node,ParentNode: TDPHIRNode; Key,Structure,Scope: string;
    Occurrences: TDictionary<string,Integer>; Ordinal,ParentIndex: Integer; Source: TDPHSource;
begin
  AStore.ObserveManifest(Inventory.Manifest);
  Result:=AStore.BeginGeneration(AConfiguration,AAnalyzerVersion,Inventory.Manifest);
  AStore.BeginFacts(Result);
  Occurrences:=TDictionary<string,Integer>.Create;
  try
    try
      for Item in Inventory.Manifest do
      begin
        if Inventory.Sources.TryGetValue(Item.RelativePath,Source) then
        begin
          J:=TJSONObject.Create;
          try
            J.AddPair('sha256',Item.SHA256); J.AddPair('encoding',Item.Encoding);
            J.AddPair('line_endings',Source.LineEndings); J.AddPair('availability',Item.Availability); J.AddPair('kind',Item.Kind);
            AStore.AddEvidence(Result,Item.RelativePath,'{"start":0,"end":0}','source_metadata',J.ToJSON,'verified');
          finally J.Free; end;
        end;
        if Results.TryGetValue(Item.RelativePath,Parsed) then
        begin
          J:=Parsed.AsJSON;
          try Structure:=J.ToJSON; finally J.Free; end;
          AStore.AddEvidence(Result,Item.RelativePath,Format('{"start":0,"end":%d}',[Item.SizeBytes]),'syntax_ir',Structure,'inferred');
          for Node in Parsed.Nodes do
            if MatchText(Node.Kind,['unit','program','library','package','type','object','inherited','inline','property','event_binding']) or
              Node.Kind.StartsWith('routine_') or Node.Kind.StartsWith('anonymous_') then
            begin
              Scope:=''; ParentIndex:=Node.Parent;
              while ParentIndex>=0 do
              begin ParentNode:=Parsed.Nodes[ParentIndex]; Scope:=ParentNode.Kind+':'+ParentNode.Name+'/'+Scope; ParentIndex:=ParentNode.Parent; end;
              Key:=Node.Location.Source+':'+Scope+Node.Kind+':'+Node.Name;
              if Node.Kind.StartsWith('routine_') then Key:=Key+':'+THashSHA2.GetHashString(Node.Value);
              // Prototypes, overloads and repeated form property names stay separate syntax entities.
              if not Occurrences.TryGetValue(Key,Ordinal) then Ordinal:=0;
              Occurrences.AddOrSetValue(Key,Ordinal+1); Key:=Key+':'+IntToStr(Ordinal);
              AStore.AddSourceEntity(Result,Node.Location.Source,Key,Node.Kind,Node.Name,Node.Value,
                Node.Location.StartByte,Node.Location.EndByte,RangeJSON(Node.Location));
            end;
        end;
      end;
      for D in Inventory.Diagnostics do AStore.AddDiagnostic(Result,D.Severity,D.Code,D.MessageText,RangeJSON(D.Location));
      AStore.CommitFacts;
    except on E: Exception do begin AStore.RollbackFacts; AStore.FailGeneration(Result,E.Message); raise; end; end;
  finally Occurrences.Free; end;
end;

function TDPHScan.Publish(AStore: TDPHKnowledgeStore; AGeneration: Int64; AAdditionalComplete: Boolean): Boolean;
var Revalidated: TDPHManifest;
begin
  Revalidated:=Inventory.CurrentManifest;
  if TDPHKnowledgeStore.ManifestHash(Revalidated)<>TDPHKnowledgeStore.ManifestHash(Inventory.Manifest) then
  begin
    // A changed capture must never publish even when an older head is valid.
    AStore.ObserveManifest(Revalidated);
    AStore.PublishGeneration(AGeneration,Revalidated,'{"reason":"source_changed"}',False);
    AStore.RequestReassessment; Exit(False);
  end;
  Result:=AStore.PublishGeneration(AGeneration,Revalidated,
    Format('{"ir_version":%d,"parsed_files":%d,"diagnostics":%d}',[DPHIRVersion,Results.Count,Inventory.Diagnostics.Count]),Complete and AAdditionalComplete);
end;

constructor TDPHAnalyzer.Create;
begin
  inherited Create; FCache:=TObjectDictionary<string,TDPHParseResult>.Create([doOwnsValues]);
  FDiagnostics:=TDictionary<string,TArray<TDPHDiagnostic>>.Create;
end;
destructor TDPHAnalyzer.Destroy;
begin FDiagnostics.Free; FCache.Free; inherited; end;

function TDPHAnalyzer.Scan(const AEntry,AConfig,APlatform: string;
  const ADefines,AExternalRoots: TArray<string>; AIncremental: Boolean; ACodePage: Integer): TDPHScan;
var Inventory: TDPHInventory; Item: TDPHManifestFile; Source: TDPHSource;
    Parsed,Cached: TDPHParseResult; P: TDPHPreprocessor; PascalParser: TDPHPascalParser;
    FormParser: TDPHFormParser; Tokens: TDPHTokens; CacheKey,IncludeHashes,Symbols: string;
    NewDiagnostics: TArray<TDPHDiagnostic>; D: TDPHDiagnostic; Start,I,CacheWeight,IRWeight: Integer; UnitDefines: TArray<string>;
    UnitDiagnostics: TDPHDiagnostics;
begin
  Inventory:=TDPHInventory.Create(AEntry,AConfig,APlatform,ADefines,AExternalRoots,ACodePage);
  Result:=TDPHScan.Create(Inventory);
  try
    IncludeHashes:=''; Symbols:=String.Join(';',Inventory.Defines.ToArray); IRWeight:=0;
    for Item in Inventory.Manifest do if MatchText(Item.Kind,['.inc','.dproj','.groupproj']) then IncludeHashes:=IncludeHashes+Item.RelativePath+':'+Item.SHA256+';';
    for Item in Inventory.Manifest do
    begin
      if Inventory.ProjectIR.TryGetValue(Item.RelativePath,Parsed) then
      begin Result.Results.Add(Item.RelativePath,Parsed.Clone); Continue; end;
      if (Item.Availability='available') and MatchText(Item.Kind,['.res','.rc','.json','.xml','.ini','.sql']) then begin
        if IRWeight>=500000 then begin Inventory.Diagnostics.Report('PROJECT_IR_LIMIT','Resource retained without parsed IR',Inventory.Sources[Item.RelativePath].Range(0,0),'error'); Continue; end;
        Parsed:=TDPHResourceParser.Parse(Inventory.Sources[Item.RelativePath],Inventory.Diagnostics);
        Result.Results.Add(Item.RelativePath,Parsed); Inc(IRWeight,Parsed.Nodes.Count); Continue;
      end;
      if (Item.Availability='available') and not MatchText(Item.Kind,['.pas','.dpr','.dpk','.inc','.fmx','.dfm','.dproj','.groupproj']) then
      begin
        Inventory.Diagnostics.Report('OPAQUE_RESOURCE','Captured resource/configuration has no syntax adapter: '+Item.RelativePath,
          Inventory.Sources[Item.RelativePath].Range(0,0));
      end;
      if (Item.Availability<>'available') or not MatchText(Item.Kind,['.pas','.dpr','.dpk','.fmx','.dfm']) then Continue;
      Source:=Inventory.Sources[Item.RelativePath];
      if IRWeight>=500000 then
      begin Inventory.Diagnostics.Report('PROJECT_IR_LIMIT','Remaining inputs retained without parsed IR',Source.Range(0,0),'error'); Continue; end;
      UnitDefines:=Inventory.SourceDefines[Item.RelativePath]; Symbols:=String.Join(';',UnitDefines);
      CacheKey:=THashSHA2.GetHashString(DPHAnalyzerVersion+'|'+Inventory.Root+'|'+String.Join(';',AExternalRoots)+'|'+Item.RelativePath+'|'+Item.SHA256+'|'+Item.Encoding+'|'+IncludeHashes+'|'+Symbols+'|'+Inventory.ConfigurationIdentity);
      Start:=Inventory.Diagnostics.Count;
      if AIncremental and FCache.TryGetValue(CacheKey,Cached) then
      begin
        Parsed:=Cached.Clone; Inc(Result.ReusedFiles);
        for D in FDiagnostics[CacheKey] do Inventory.Diagnostics.Add(D);
      end
      else
      begin
        Parsed:=nil;
        UnitDiagnostics:=TDPHDiagnostics.Create;
        try
        try
        if MatchText(Item.Kind,['.fmx','.dfm']) then
        begin
          FormParser:=TDPHFormParser.Create;
          try Parsed:=FormParser.Parse(Source,UnitDiagnostics); finally FormParser.Free; end;
        end
        else
        begin
          P:=TDPHPreprocessor.Create(UnitDefines,UnitDiagnostics,
            function(const AFrom,AInclude: string): TDPHSource begin Result:=Inventory.Capture(AFrom,AInclude); end);
          try Tokens:=P.Run(Source); finally P.Free; end;
          PascalParser:=TDPHPascalParser.Create;
          try Parsed:=PascalParser.Parse(Tokens,UnitDiagnostics); finally PascalParser.Free; end;
        end;
        except on E: Exception do
          begin
            Parsed.Free; Parsed:=TDPHParseResult.Create; Parsed.Complete:=False;
            UnitDiagnostics.Report('PARSER_FAILED',E.Message,Source.Range(0,0),'error');
          end;
        end;
        Inventory.Diagnostics.AddRange(UnitDiagnostics);
        finally UnitDiagnostics.Free; end;
        SetLength(NewDiagnostics,Inventory.Diagnostics.Count-Start);
        for I:=Start to Inventory.Diagnostics.Count-1 do NewDiagnostics[I-Start]:=Inventory.Diagnostics[I];
        CacheWeight:=Parsed.Nodes.Count+Length(Parsed.Tokens);
        for Cached in FCache.Values do Inc(CacheWeight,Cached.Nodes.Count+Length(Cached.Tokens));
        if (CacheWeight>250000) or (FCache.Count>=64) then begin FCache.Clear; FDiagnostics.Clear; end;
        if Parsed.Nodes.Count+Length(Parsed.Tokens)<=250000 then
        begin FCache.AddOrSetValue(CacheKey,Parsed.Clone); FDiagnostics.AddOrSetValue(CacheKey,Copy(NewDiagnostics)); end;
      end;
      Result.Results.Add(Item.RelativePath,Parsed);
      Inc(IRWeight,Parsed.Nodes.Count+Length(Parsed.Tokens));
    end;
    Result.Complete:=Inventory.Complete;
    for Parsed in Result.Results.Values do if not Parsed.Complete then Result.Complete:=False;
    for D in Inventory.Diagnostics do if D.Severity<>'info' then Result.Complete:=False;
  except Result.Free; raise; end;
end;
end.
