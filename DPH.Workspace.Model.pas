unit DPH.Workspace.Model;

interface
uses System.SysUtils, System.JSON, System.Generics.Collections,
  DPH.Project.Analysis, DPH.Analysis.Model;
type
  TDPHWorkspaceView = class
  private
    FDocument: TJSONObject;
    FSymbols: TDictionary<string,TJSONObject>;
  public
    constructor Create(ADocument: TJSONObject);
    destructor Destroy; override;
    class function Capture(AScan: TDPHScan; AGraph: TDPHSemanticGraph; AGeneration: Int64;
      const AEntry,AConfig,APlatform: string; const ADefines,AExternalRoots: TArray<string>): TJSONObject; static;
    function Symbol(const AKey: string): TJSONObject;
    function Neighbors(const AKey,ADirection: string): TJSONArray;
    function Search(const AQuery,AKind,AScope: string; AOffset: Integer = 0; ALimit: Integer = 250): TJSONArray;
    function Hierarchy(const AExpanded: TArray<string>; AOffset: Integer = 0; ALimit: Integer = 250): TJSONArray;
    function SourceFile(const APath: string): TJSONObject;
    function Properties(const AKey: string): TJSONArray;
    function Details(const AKey: string): TJSONArray;
    function Graph(const AKind,AKey: string; ALimit: Integer = 120): TJSONObject;
    function FlagsText: string;
    function Coverage: TJSONObject;
    function Questions(AKnowledge: TJSONArray = nil): TJSONArray;
    function ProjectMembers: TJSONArray;
    class function NewDataRetentionPolicy:string;static;
    class procedure ValidateDataRetentionRecord(ARecord:TJSONObject);static;
    class function IsDataRetentionPolicy(ARow:TJSONObject):Boolean;static;
    class function DescribeDataRetentionPolicy(ARow:TJSONObject):string;static;
    function FileFormats: TJSONObject;
    class function DescribeFileFormat(ARow:TJSONObject):string; static;
    class function FileFormatContractTitle(ARow:TJSONObject):string; static;
    class function SelectionHash(const AConfig,APlatform: string; const ADefines,AExternalRoots: TArray<string>; ACodePage: Integer = 0): string; static;
    class function IsHandoffProject(ADocument: TJSONObject): Boolean; static;
    property Document: TJSONObject read FDocument;
  end;
implementation
uses System.RegularExpressions, System.StrUtils, System.IOUtils, System.Hash, System.DateUtils, System.Generics.Defaults, DPH.Project.Inventory, DPH.Analysis.Quality;

class function TDPHWorkspaceView.NewDataRetentionPolicy:string;
begin
 Result:='TARGET DATA RETENTION AND ARCHIVAL POLICY'+sLineBreak+
  'Human-authored requirements for the selected application. Replace Unknown with evidence or explain who must resolve it. Do not enter credentials or customer data.'+sLineBreak+sLineBreak+
  'Policy name and version: Unknown'+sLineBreak+
  'Data categories, tables/files and business scope: Unknown'+sLineBreak+
  'Business or regulatory basis and evidence: Unknown'+sLineBreak+
  'Retention period, units and clock-start event: Unknown'+sLineBreak+
  'Eligibility and expiry calculation, time zone: Unknown'+sLineBreak+
  'Archive trigger, frequency and implementing job/procedure: Unknown'+sLineBreak+
  'Archive destination, format and access permissions: Unknown'+sLineBreak+
  'Deletion/disposal method and implementing job/procedure: Unknown'+sLineBreak+
  'Legal holds, exceptions and override authority: Unknown'+sLineBreak+
  'Policy owner, operator and approval responsibility: Unknown'+sLineBreak+
  'Archive retrieval, restoration and disposal evidence: Unknown'+sLineBreak+
  'Failure handling, monitoring and audit trail: Unknown'+sLineBreak+
  'Verification procedure, test evidence and last review: Unknown'+sLineBreak+
  'Remaining unknowns and responsible maintainer: Unknown'+sLineBreak+sLineBreak+
  'Implementing links: use Knowledge links to attach captured routines, evidence or exact procedure-section revisions; Save the link edits. A written job name alone is not a resolved source link.'+sLineBreak+
  'Qualification: this records target-application policy. DPH snapshot retention is separate. DPH never runs an archive, deletion, SQL statement or target job. Saving or reviewing this record does not establish legal compliance or observed job success.';
end;
class function TDPHWorkspaceView.IsDataRetentionPolicy(ARow:TJSONObject):Boolean;
var RecordValue:TJSONValue;
begin
 Result:=False;if ARow=nil then Exit;
 RecordValue:=TJSONObject.ParseJSONValue(ARow.GetValue<string>('structured_json','{}'));
 try
  if not (RecordValue is TJSONObject) then Exit;
  Result:=(ARow.GetValue<string>('kind','')='business_rule') and (RecordValue.GetValue<string>('record_type','')='data_retention');
 finally RecordValue.Free;end;
end;
class procedure TDPHWorkspaceView.ValidateDataRetentionRecord(ARecord:TJSONObject);
var ID:TGUID;Pair:TJSONPair;
begin
 if (ARecord=nil) or (ARecord.GetValue<string>('record_type','')<>'data_retention') then raise EArgumentException.Create('Expected a target-data retention policy');
 if ARecord.Count<>2 then raise EArgumentException.Create('Retention policy requires only its record type and stable policy identity');
 for Pair in ARecord do if not (Pair.JsonValue is TJSONString) then raise EArgumentException.Create('Retention metadata must be text');
 if Length(ARecord.GetValue<string>('policy_id',''))<>38 then raise EArgumentException.Create('Invalid retention policy identity');
 try ID:=StringToGUID(ARecord.GetValue<string>('policy_id'));except raise EArgumentException.Create('Invalid retention policy identity');end;
end;
class function TDPHWorkspaceView.DescribeDataRetentionPolicy(ARow:TJSONObject):string;
var Links,History:TJSONArray;Value:TJSONValue;
begin
 Result:='No saved target-data policy selected. New policy prepares an unsaved Knowledge draft. Empty results do not prove that the application has no retention obligations.';
 if not IsDataRetentionPolicy(ARow) then Exit;
 Result:=ARow.GetValue<string>('title')+sLineBreak+'Original contributor: '+ARow.GetValue<string>('owner','unknown')+
  sLineBreak+'Review state: '+ARow.GetValue<string>('state','unknown')+' | revision '+ARow.GetValue<string>('revision','unknown')+
  sLineBreak+'Reviewer: '+IfThen(ARow.GetValue<string>('reviewer','')='','not supplied',ARow.GetValue<string>('reviewer',''))+sLineBreak;
 if ARow.TryGetValue<TJSONArray>('history',History) then for Value in History do
  if Value.GetValue<string>('revision','')=ARow.GetValue<string>('revision','') then
   Result:=Result+'Current revision author: '+Value.GetValue<string>('editor','unknown')+sLineBreak;
 if ARow.TryGetValue<TJSONArray>('rich_links',Links) then Result:=Result+'Explicit implementation/evidence links: '+IntToStr(Links.Count)+sLineBreak;
 Result:=Result+sLineBreak+ARow.GetValue<string>('body')+sLineBreak+sLineBreak+
  'Open policy to edit, save and review it. Implementation links opens the exact saved links and link editor. Unknown text remains unresolved even when a contributor has reviewed the record. Source links identify captured objects, not successful runtime jobs.';
end;

class function TDPHWorkspaceView.IsHandoffProject(ADocument: TJSONObject): Boolean;
var Files,Nodes: TJSONArray; FileValue,NodeValue: TJSONValue; Row,IR,Node: TJSONObject;
begin
  Result:=False;
  if (ADocument=nil) or not ADocument.TryGetValue<TJSONArray>('syntax.files',Files) then Exit;
  for FileValue in Files do
  begin
    Row:=FileValue as TJSONObject;
    if not Row.TryGetValue<TJSONObject>('ir',IR) or not IR.TryGetValue<TJSONArray>('nodes',Nodes) then Continue;
    for NodeValue in Nodes do
    begin
      Node:=NodeValue as TJSONObject;
      if (SameText(Node.GetValue<string>('kind',''),'project_property') and
        SameText(Node.GetValue<string>('name',''),'ProjectGuid') and
        SameText(Trim(Node.GetValue<string>('value','')),DPHHandoffProjectGUID)) or
        (SameText(Node.GetValue<string>('kind',''),'program') and
        SameText(Node.GetValue<string>('name',''),DPHHandoffProgramName)) then Exit(True);
    end;
  end;
end;

class function TDPHWorkspaceView.SelectionHash(const AConfig,APlatform: string; const ADefines,AExternalRoots: TArray<string>; ACodePage: Integer): string;
var Selection: string;
begin
  Selection:=AConfig+#0+APlatform+#0+String.Join(#0,ADefines)+#1+String.Join(#0,AExternalRoots);
  if ACodePage<>0 then Selection:=Selection+#0+'CP'+IntToStr(ACodePage);
  Result:=THashSHA2.GetHashString(Selection);
end;

class function TDPHWorkspaceView.Capture(AScan: TDPHScan; AGraph: TDPHSemanticGraph; AGeneration: Int64;
  const AEntry,AConfig,APlatform: string; const ADefines,AExternalRoots: TArray<string>): TJSONObject;
var A: TJSONArray; Value: string;
begin
  Result:=TJSONObject.Create; Result.AddPair('workspace_schema',TJSONNumber.Create(1));
  Result.AddPair('captured_utc',DateToISO8601(TTimeZone.Local.ToUniversalTime(Now),True));
  Result.AddPair('generation_id',TJSONNumber.Create(AGeneration)); Result.AddPair('entry',ExtractFileName(AEntry));
  Result.AddPair('root',AScan.Inventory.Root); Result.AddPair('configuration',AConfig); Result.AddPair('platform',APlatform);
  Result.AddPair('configuration_identity',AScan.Inventory.ConfigurationIdentity);
  Result.AddPair('selection_hash',SelectionHash(AConfig,APlatform,ADefines,AExternalRoots,AScan.Inventory.CodePage));
  Result.AddPair('code_page',TJSONNumber.Create(AScan.Inventory.CodePage));
  A:=TJSONArray.Create; Result.AddPair('defines',A); for Value in ADefines do A.Add(Value);
  A:=TJSONArray.Create; Result.AddPair('external_roots',A); for Value in AExternalRoots do A.Add(Value);
  A:=TJSONArray.Create; Result.AddPair('configurations',A); for Value in AScan.Inventory.Configurations do A.Add(Value);
  A:=TJSONArray.Create; Result.AddPair('platforms',A); for Value in AScan.Inventory.Platforms do A.Add(Value);
  Result.AddPair('syntax',AScan.AsJSON(True)); Result.AddPair('semantics',AGraph.AsJSON);
  Result.AddPair('source_quality',TDPHSourceQuality.Analyze(AScan,AGraph));
  Result.AddPair('analysis_complete',TJSONBool.Create(AScan.Complete and AGraph.Complete));
  Result.AddPair('runtime_observed',TJSONBool.Create(False));
end;
constructor TDPHWorkspaceView.Create(ADocument: TJSONObject);
var V: TJSONValue; S: TJSONObject; Semantic: TJSONObject;
begin
  inherited Create; FDocument:=ADocument;
  if (ADocument=nil) or (ADocument.GetValue<Integer>('workspace_schema',0)<>1) then raise EArgumentException.Create('Unsupported workspace document');
  FSymbols:=TDictionary<string,TJSONObject>.Create;
  Semantic:=ADocument.GetValue<TJSONObject>('semantics');
  for V in Semantic.GetValue<TJSONArray>('symbols') do
  begin S:=V as TJSONObject; FSymbols.Add(S.GetValue<string>('key'),S); end;
end;
destructor TDPHWorkspaceView.Destroy;
begin FSymbols.Free; FDocument.Free; inherited; end;
function TDPHWorkspaceView.Symbol(const AKey: string): TJSONObject;
begin if not FSymbols.TryGetValue(AKey,Result) then Result:=nil; end;

function TDPHWorkspaceView.FileFormats:TJSONObject;
var Rows,Files,Nodes,Shape:TJSONArray; F,N,V,W:TJSONValue; FileRow,Node,Row,Range,Owner:TJSONObject;
    Path,Kind,Text,API,Direction,Extension,Encoding,Key,Member,ValueType:string;
    Tokens:TMatchCollection; Seen:TDictionary<string,Boolean>; I,J,K,Depth,Parent,ShapeCount,BestSize:Integer;
  procedure Add(const AName,ADirection,AFormat,AEncoding:string; ANode:TJSONObject; ASite:Integer=0);
  var W:TJSONValue;
  begin
   if Rows.Count>=10000 then begin if Result.GetValue('limit')=nil then Result.AddPair('limit','File-format inventory truncated at 10000 candidates.');Exit;end;
   Range:=TJSONObject.Create.AddPair('source',Path).AddPair('line',TJSONNumber.Create(ANode.GetValue<Integer>('line',1))).AddPair('column',TJSONNumber.Create(ANode.GetValue<Integer>('column',1))).AddPair('start',TJSONNumber.Create(ANode.GetValue<Integer>('start',0))).AddPair('end',TJSONNumber.Create(ANode.GetValue<Integer>('end',0)));
   Row:=TJSONObject.Create;Rows.AddElement(Row);
   Key:=Path+'|'+Range.GetValue('start').Value+'|'+AName+'|'+ADirection+'|'+IntToStr(ASite);
   Row.AddPair('id',Key).AddPair('name',AName).AddPair('direction',ADirection).AddPair('format',AFormat).AddPair('encoding',AEncoding).AddPair('source',Path).AddPair('source_hash',FileRow.GetValue<string>('sha256','')).AddPair('generation_id',FDocument.GetValue('generation_id').Clone as TJSONValue).AddPair('range',Range).AddPair('schema',TJSONArray.Create).AddPair('producer','unknown').AddPair('consumer','unknown').AddPair('target_key','');
   Owner:=nil;BestSize:=MaxInt;
   for W in FDocument.GetValue<TJSONArray>('semantics.symbols') do
    if MatchText(W.GetValue<string>('kind'),['routine','anonymous']) and (W.GetValue<string>('range.source')=Path) and (W.GetValue<Integer>('range.start')<=ANode.GetValue<Integer>('start',0)) and (W.GetValue<Integer>('range.end')>=ANode.GetValue<Integer>('end',0)) and (W.GetValue<Integer>('range.end')-W.GetValue<Integer>('range.start')<BestSize) then begin Owner:=W as TJSONObject;BestSize:=W.GetValue<Integer>('range.end')-W.GetValue<Integer>('range.start');end;
   if Owner<>nil then begin
    Row.RemovePair('target_key').Free;Row.AddPair('target_key',Owner.GetValue<string>('key'));
    if ADirection='export' then Member:='producer' else Member:='consumer';
    Row.RemovePair(Member).Free;Row.AddPair(Member,Owner.GetValue<string>('name')+' (enclosing captured routine; API binding/execution unverified)');
   end;
  end;
begin
 Result:=TJSONObject.Create;Rows:=TJSONArray.Create;Result.AddPair('rows',Rows);
 Result.AddPair('qualification','Source format candidates and captured resource shape only. API spellings, extensions and enclosing routines do not prove runtime dispatch, an accepted schema, actual encoding or successful import/export. Scalar values and literal paths are omitted. Captured resource decoding is distinct from a file-transfer encoding contract. Dynamic paths, defaults, opaque resources, parser gaps and missing structure remain unknown. Record a named contract and review it against evidence. No target code or file-transfer API executes.');
 Seen:=TDictionary<string,Boolean>.Create;
 try
  Files:=FDocument.GetValue<TJSONArray>('syntax.files');
  for F in Files do begin
   if Rows.Count>=10000 then begin if Result.GetValue('limit')=nil then Result.AddPair('limit','File-format inventory truncated at 10000 candidates.');Break;end;
   FileRow:=F as TJSONObject;Path:=FileRow.GetValue<string>('path');Extension:=LowerCase(ExtractFileExt(Path));
   if not FileRow.TryGetValue<TJSONArray>('ir.nodes',Nodes) then Continue;
   if MatchText(Extension,['.json','.xml','.ini']) then begin
    Node:=TJSONObject.Create;try Add(Path,'captured resource',Extension,'Captured source decoding: '+FileRow.GetValue<string>('encoding','unknown')+'; transfer encoding unknown',Node);finally Node.Free;end;
    Shape:=Row.GetValue<TJSONArray>('schema');ShapeCount:=0;
    for N in Nodes do if MatchText(N.GetValue<string>('kind'),['json_object','json_array','json_value','xml_element','xml_attribute','ini_section','ini_value']) then begin
     Inc(ShapeCount);if ShapeCount>250 then Continue;Member:=N.GetValue<string>('name');
     if (Length(Member)>128) or not TRegEx.IsMatch(Member,'^[A-Za-z0-9_./~:-]*$') then Member:='<nonidentifier member omitted>';
     ValueType:=N.GetValue<string>('kind');Text:=N.GetValue<string>('value','');
     if ValueType='json_value' then begin
      if Text.StartsWith('"') then ValueType:='JSON string' else if Text='null' then ValueType:='JSON null' else if MatchText(Text,['true','false']) then ValueType:='JSON boolean' else ValueType:='JSON numeric candidate';
     end;
     Shape.AddElement(TJSONObject.Create.AddPair('member',Member).AddPair('shape',ValueType));
    end;
    Row.AddPair('shape_count',TJSONNumber.Create(ShapeCount));if ShapeCount>250 then Row.AddPair('shape_limit','Captured structure display truncated to first 250 members.');
    Row.AddPair('structure_basis','Observed resource shape, not a required/optional schema contract. Scalar values omitted; missing/opaque structure remains unknown.');
   end;
   for N in Nodes do begin
    Node:=N as TJSONObject;if Node.GetValue<string>('kind')<>'expression' then Continue;
    Parent:=Node.GetValue<Integer>('parent',-1);if (Parent>=0) and (Parent<Nodes.Count) and (Nodes[Parent].GetValue<string>('kind')='expression') then Continue;
    Text:=Node.GetValue<string>('value','');if (Text='') or (Length(Text)>16000) then Continue;
    // IR expression text is bounded by the parser. Quoted literals are single tokens.
    Tokens:=TRegEx.Matches(Text,'''(?:[^'']|'''')*''|[A-Za-z_][A-Za-z0-9_]*|[^\s]');
    for I:=0 to Tokens.Count-2 do begin
     API:=Tokens[I].Value;if not MatchText(API,['ReadAllText','ReadAllBytes','ReadAllLines','WriteAllText','WriteAllBytes','WriteAllLines','LoadFromFile','SaveToFile']) or (Tokens[I+1].Value<>'(') then Continue;
     if (I=0) or (Tokens[I-1].Value<>'.') then Continue;
     Direction:='import';if MatchText(API,['WriteAllText','WriteAllBytes','WriteAllLines','SaveToFile']) then Direction:='export';
     Key:=Path+'|'+Node.GetValue('start').Value+'|'+IntToStr(I)+'|'+API;if Seen.ContainsKey(Key) then Continue;Seen.Add(Key,True);
     Extension:='unknown; dynamic or unsupported path';J:=I+2;
     if (J+1<Tokens.Count) and Tokens[J].Value.StartsWith('''') and MatchText(Tokens[J+1].Value,[',',')']) then begin
      Extension:=LowerCase(ExtractFileExt(Tokens[J].Value.Trim([''''])));
      if (Length(Extension)>16) or not TRegEx.IsMatch(Extension,'^\.[a-z0-9]+$') then Extension:='unknown; no supported filename extension';
      Extension:=Extension+' (filename candidate; contents unverified)';
     end;
     Encoding:='unknown; default, custom receiver or unsupported encoding';Depth:=1;K:=J;
     while (K<Tokens.Count) and (Depth>0) do begin
      if Tokens[K].Value='(' then Inc(Depth) else if Tokens[K].Value=')' then Dec(Depth);
      if (K+2<Tokens.Count) and SameText(Tokens[K].Value,'TEncoding') and (Tokens[K+1].Value='.') and MatchText(Tokens[K+2].Value,['UTF8','Unicode','BigEndianUnicode','ASCII','Default']) then Encoding:=Tokens[K+2].Value+' (explicit source argument candidate; runtime binding unverified)';
      Inc(K);
     end;
     if MatchText(API,['ReadAllBytes','WriteAllBytes']) then Encoding:='binary byte API candidate; text encoding not established';
     if Rows.Count>=10000 then begin if Result.GetValue('limit')=nil then Result.AddPair('limit','File-format inventory truncated at 10000 candidates.');Break;end;
     Add(API,Direction,Extension,Encoding,Node,I);Row.AddPair('structure_basis','Transfer schema unknown; inspect the captured routine and record an explicit contract. Location is the enclosing IR expression.');
    end;
   end;
  end;
 except Seen.Free;Result.Free;raise;end;
 Seen.Free;
end;

class function TDPHWorkspaceView.FileFormatContractTitle(ARow:TJSONObject):string;
begin Result:='File format contract '+THashSHA2.GetHashString(ARow.GetValue<string>('id')+#0+ARow.GetValue<string>('source_hash'));end;
class function TDPHWorkspaceView.DescribeFileFormat(ARow:TJSONObject):string;
var V:TJSONValue;
begin
 Result:='FILE FORMAT EVIDENCE'+sLineBreak+ARow.GetValue<string>('name')+' | '+ARow.GetValue<string>('direction')+sLineBreak+
  'Format: '+ARow.GetValue<string>('format')+sLineBreak+'Encoding: '+ARow.GetValue<string>('encoding')+sLineBreak+'Producer: '+ARow.GetValue<string>('producer')+sLineBreak+'Consumer: '+ARow.GetValue<string>('consumer')+sLineBreak+ARow.GetValue<string>('structure_basis','')+sLineBreak;
 for V in ARow.GetValue<TJSONArray>('schema') do Result:=Result+V.GetValue<string>('member')+' : '+V.GetValue<string>('shape')+sLineBreak;
 Result:=Result+ARow.GetValue<string>('shape_limit','')+sLineBreak+'Source: '+ARow.GetValue<string>('source')+' | line '+ARow.GetValue<TJSONObject>('range').GetValue('line').Value+sLineBreak+'SHA256 '+ARow.GetValue<string>('source_hash')+' | generation '+ARow.GetValue('generation_id').Value+sLineBreak;
end;

function TDPHWorkspaceView.ProjectMembers: TJSONArray;
var Files,Nodes,Properties: TJSONArray; FileValue,NodeValue: TJSONValue;
    FileRow,Node,Member: TJSONObject; Path,Extension,Kind,Name: string;
begin
  Result:=TJSONArray.Create;
  try
    Files:=FDocument.GetValue<TJSONArray>('syntax.files');
    for FileValue in Files do begin
      FileRow:=FileValue as TJSONObject; Path:=FileRow.GetValue<string>('path');
      Extension:=LowerCase(ExtractFileExt(Path));
      if not MatchText(Extension,['.dproj','.groupproj','.dpr','.dpk']) then Continue;
      if Extension='.groupproj' then Kind:='project group'
      else if Extension='.dproj' then Kind:='project settings'
      else Kind:='unresolved output kind';
      Name:=TPath.GetFileNameWithoutExtension(Path);
      Member:=TJSONObject.Create; Result.AddElement(Member);
      Member.AddPair('path',Path); Member.AddPair('source_hash',FileRow.GetValue<string>('sha256'));
      Member.AddPair('availability',FileRow.GetValue<string>('availability'));
      Member.AddPair('generation_id',TJSONNumber.Create(FDocument.GetValue<Int64>('generation_id')));
      Properties:=TJSONArray.Create; Member.AddPair('settings_and_references',Properties);
      if FileRow.TryGetValue<TJSONArray>('ir.nodes',Nodes) then
        for NodeValue in Nodes do begin
          Node:=NodeValue as TJSONObject;
          if MatchText(Node.GetValue<string>('kind'),['program','library','package']) then begin
            Name:=Node.GetValue<string>('name');
            if Node.GetValue<string>('kind')='program' then Kind:='executable declaration'
            else if Node.GetValue<string>('kind')='library' then Kind:='library declaration'
            else Kind:='package declaration';
            Member.AddPair('declaration',Node.Clone as TJSONValue);
          end;
          if MatchText(Node.GetValue<string>('kind'),['project_property','project_reference']) then
            Properties.AddElement(Node.Clone as TJSONValue);
        end;
      Member.AddPair('name',Name); Member.AddPair('kind',Kind);
      Member.AddPair('qualification','Captured selected-project inputs only. Project settings and their main-source declarations are separate evidence rows, not separate applications. Output kind describes a declaration, not a built binary or verified service installation. Settings belong to the captured configuration; parent conditions may apply even when a child has no recorded condition. Read diagnostics for missing inputs and unsupported project conditions.');
    end;
  except Result.Free; raise; end;
end;
function TDPHWorkspaceView.Search(const AQuery,AKind,AScope: string; AOffset,ALimit: Integer): TJSONArray;
var V: TJSONValue; S: TJSONObject; Count: Integer; Name,Kind: string;
begin
  if (AOffset<0) or (ALimit<1) or (ALimit>1000) then raise EArgumentException.Create('Invalid Explorer page');
  Result:=TJSONArray.Create; Count:=0;
  for V in FDocument.GetValue<TJSONObject>('semantics').GetValue<TJSONArray>('symbols') do
  begin
    S:=V as TJSONObject; Name:=S.GetValue<string>('name'); Kind:=S.GetValue<string>('kind');
    if (AKind<>'') and (Kind<>AKind) then Continue;
    if (AScope<>'') and not StartsText(AScope+'.',Name) then Continue;
    if (AQuery<>'') and not ContainsText(Name+' '+S.GetValue<string>('signature')+' '+Kind,AQuery) then Continue;
    if Count>=AOffset then Result.AddElement(S.Clone as TJSONObject);
    Inc(Count); if Result.Count>=ALimit then Break;
  end;
end;
function TDPHWorkspaceView.Hierarchy(const AExpanded: TArray<string>; AOffset,ALimit: Integer): TJSONArray;
var Children: TObjectDictionary<string,TList<string>>; Parents: TDictionary<string,string>;
    Expanded,Seen: TDictionary<string,Boolean>; Roots: TList<string>; Items: TList<string>;
    V: TJSONValue; R: TJSONObject; Key,Owner,Child: string; VisibleCount: Integer;
  procedure Visit(const AKey: string; Depth: Integer);
  var Row,CopyRow: TJSONObject; Branch: TList<string>; ChildKey: string; HasChildren,IsExpanded: Boolean;
  begin
    if (Depth>128) or (Result.Count>=ALimit) or Seen.ContainsKey(AKey) then Exit;
    Row:=Symbol(AKey); if Row=nil then Exit; Seen.Add(AKey,True);
    HasChildren:=Children.TryGetValue(AKey,Branch); IsExpanded:=Expanded.ContainsKey(AKey);
    if VisibleCount>=AOffset then begin
      CopyRow:=Row.Clone as TJSONObject; Result.AddElement(CopyRow);
      CopyRow.AddPair('depth',TJSONNumber.Create(Depth)); CopyRow.AddPair('has_children',TJSONBool.Create(HasChildren));
      CopyRow.AddPair('expanded',TJSONBool.Create(IsExpanded));
    end;
    Inc(VisibleCount);
    if HasChildren and IsExpanded then for ChildKey in Branch do Visit(ChildKey,Depth+1);
  end;
begin
  if (AOffset<0) or (ALimit<1) or (ALimit>1000) then raise EArgumentException.Create('Invalid hierarchy page');
  Result:=TJSONArray.Create;
  Children:=TObjectDictionary<string,TList<string>>.Create([doOwnsValues]); Parents:=TDictionary<string,string>.Create;
  Expanded:=TDictionary<string,Boolean>.Create; Seen:=TDictionary<string,Boolean>.Create; Roots:=TList<string>.Create;
  try
    try
    for Key in AExpanded do Expanded.AddOrSetValue(Key,True);
    for V in FDocument.GetValue<TJSONArray>('semantics.relationships') do begin
      R:=V as TJSONObject; if R.GetValue<string>('kind')<>'owns' then Continue;
      Owner:=R.GetValue<string>('from'); Child:=R.GetValue<string>('to','');
      if (Owner=Child) or (Symbol(Owner)=nil) or (Symbol(Child)=nil) or Parents.ContainsKey(Child) then Continue;
      Parents.Add(Child,Owner);
      if not Children.TryGetValue(Owner,Items) then begin Items:=TList<string>.Create; Children.Add(Owner,Items); end;
      Items.Add(Child);
    end;
    for V in FDocument.GetValue<TJSONArray>('semantics.symbols') do begin
      Key:=(V as TJSONObject).GetValue<string>('key'); if not Parents.ContainsKey(Key) then Roots.Add(Key);
    end;
    VisibleCount:=0; for Key in Roots do Visit(Key,0);
    except Result.Free; raise; end;
  finally Roots.Free; Seen.Free; Expanded.Free; Parents.Free; Children.Free; end;
end;

function TDPHWorkspaceView.Neighbors(const AKey,ADirection: string): TJSONArray;
var V: TJSONValue; R: TJSONObject; Field: string;
begin
  Result:=TJSONArray.Create; Field:='from'; if ADirection='reverse' then Field:='to';
  for V in FDocument.GetValue<TJSONObject>('semantics').GetValue<TJSONArray>('relationships') do
  begin R:=V as TJSONObject; if R.GetValue<string>(Field,'')=AKey then Result.AddElement(R.Clone as TJSONObject); end;
end;
function TDPHWorkspaceView.SourceFile(const APath: string): TJSONObject;
var V: TJSONValue;
begin
  Result:=nil; for V in FDocument.GetValue<TJSONObject>('syntax').GetValue<TJSONArray>('files') do
    if SameText((V as TJSONObject).GetValue<string>('path'),APath) then Exit(V as TJSONObject);
end;
function TDPHWorkspaceView.Properties(const AKey: string): TJSONArray;
var S,FileRow,N,Range: TJSONObject; V: TJSONValue; Nodes: TJSONArray; NodeID,I: Integer;
begin
  Result:=TJSONArray.Create; S:=Symbol(AKey); if S=nil then Exit;
  Range:=S.GetValue<TJSONObject>('range'); FileRow:=SourceFile(Range.GetValue<string>('source')); if FileRow=nil then Exit;
  Nodes:=FileRow.GetValue<TJSONObject>('ir').GetValue<TJSONArray>('nodes'); NodeID:=-1;
  for I:=0 to Nodes.Count-1 do
  begin N:=Nodes.Items[I] as TJSONObject;
    if (N.GetValue<Int64>('start')=Range.GetValue<Int64>('start')) and MatchText(N.GetValue<string>('kind'),['object','inherited','inline']) then begin NodeID:=I; Break; end;
  end;
  if NodeID<0 then Exit;
  for V in Nodes do begin N:=V as TJSONObject; if (N.GetValue<Integer>('parent')=NodeID) and (N.GetValue<string>('kind')='property') then Result.AddElement(N.Clone as TJSONObject); end;
end;
function TDPHWorkspaceView.Details(const AKey: string): TJSONArray;
var V: TJSONValue; Row,CopyRow,FileRow: TJSONObject; PropertiesRows: TJSONArray; FlowRows: TList<TJSONObject>;
begin
  Result:=TJSONArray.Create; FlowRows:=TList<TJSONObject>.Create;
  try
    try
    for V in FDocument.GetValue<TJSONArray>('semantics.flow_nodes') do begin
      Row:=V as TJSONObject; if Row.GetValue<string>('routine')<>AKey then Continue;
      FlowRows.Add(Row);
    end;
    FlowRows.Sort(TComparer<TJSONObject>.Construct(
      function(const L,R: TJSONObject): Integer
      var LeftBoundary,RightBoundary: Boolean;
      begin
        LeftBoundary:=MatchText(L.GetValue<string>('kind'),['entry','normal_exit','exception_exit']);
        RightBoundary:=MatchText(R.GetValue<string>('kind'),['entry','normal_exit','exception_exit']);
        if LeftBoundary<>RightBoundary then begin if LeftBoundary then Exit(1) else Exit(-1); end;
        Result:=CompareStr(L.GetValue<string>('range.source'),R.GetValue<string>('range.source'));
        if Result=0 then begin
          if L.GetValue<Int64>('range.start')<R.GetValue<Int64>('range.start') then Result:=-1
          else if L.GetValue<Int64>('range.start')>R.GetValue<Int64>('range.start') then Result:=1;
        end;
      end));
    for Row in FlowRows do begin
      CopyRow:=Row.Clone as TJSONObject; Result.AddElement(CopyRow);
      if MatchText(Row.GetValue<string>('kind'),['entry','normal_exit','exception_exit']) then CopyRow.AddPair('detail_kind','flow boundary')
      else CopyRow.AddPair('detail_kind','statement'); CopyRow.AddPair('title',Row.GetValue<string>('kind'));
      CopyRow.AddPair('object_key',AKey);
      CopyRow.AddPair('text',Row.GetValue<string>('expression')); CopyRow.AddPair('resolution','inferred');
      CopyRow.AddPair('rule','captured_control_flow_not_runtime_trace'); if Result.Count>=1000 then Exit;
    end;
    PropertiesRows:=Properties(AKey);
    try for V in PropertiesRows do begin
      Row:=V as TJSONObject; CopyRow:=TJSONObject.Create; Result.AddElement(CopyRow);
      CopyRow.AddPair('detail_kind','property'); CopyRow.AddPair('title',Row.GetValue<string>('name'));
      CopyRow.AddPair('object_key',AKey);
      CopyRow.AddPair('text',Row.GetValue<string>('value')); CopyRow.AddPair('range',Row.Clone as TJSONObject);
      CopyRow.AddPair('resolution','confirmed_static'); CopyRow.AddPair('rule','serialized_override_not_framework_default');
      FileRow:=SourceFile(Row.GetValue<string>('source')); if FileRow<>nil then CopyRow.AddPair('source_hash',FileRow.GetValue<string>('sha256'));
      if Result.Count>=1000 then Exit;
    end; finally PropertiesRows.Free; end;
    for V in FDocument.GetValue<TJSONArray>('semantics.relationships') do begin
      Row:=V as TJSONObject; if Row.GetValue<string>('from')<>AKey then Continue;
      CopyRow:=Row.Clone as TJSONObject; Result.AddElement(CopyRow);
      CopyRow.AddPair('detail_kind','relationship'); CopyRow.AddPair('title',Row.GetValue<string>('kind'));
      CopyRow.AddPair('object_key',Row.GetValue<string>('to',AKey));
      CopyRow.AddPair('text',Row.GetValue<string>('label')); if Result.Count>=1000 then Exit;
    end;
    except Result.Free; raise; end;
  finally FlowRows.Free; end;
end;

function TDPHWorkspaceView.Graph(const AKind,AKey: string; ALimit: Integer): TJSONObject;
var Nodes,Edges,AllNodes,AllEdges: TJSONArray; V: TJSONValue; R,S,N: TJSONObject;
    Seen,EdgeKeys: TDictionary<string,Boolean>; Queue: TQueue<string>; Key,FromKey,ToKey,Kind,EdgeKey: string;
    I: Integer; Truncated: Boolean;
  procedure AddSymbolNode(const K: string);
  var Row,Sym: TJSONObject;
  begin
    if (K='') or Seen.ContainsKey(K) then Exit;
    if Seen.Count>=ALimit then begin Truncated:=True; Exit; end;
    Seen.Add(K,True); Sym:=Symbol(K); Row:=TJSONObject.Create; Row.AddPair('id',K);
    if Sym<>nil then begin Row.AddPair('label',Sym.GetValue<string>('name')); Row.AddPair('kind',Sym.GetValue<string>('kind')); Row.AddPair('type',Sym.GetValue<string>('type')); Row.AddPair('range',Sym.GetValue<TJSONObject>('range').Clone as TJSONObject); end
    else Row.AddPair('label',K); Nodes.AddElement(Row); Queue.Enqueue(K);
  end;
begin
  if (ALimit<1) or (ALimit>1000) then raise EArgumentException.Create('Invalid graph limit');
  Result:=TJSONObject.Create; Nodes:=TJSONArray.Create; Edges:=TJSONArray.Create;
  Result.AddPair('kind',AKind); Result.AddPair('nodes',Nodes); Result.AddPair('edges',Edges);
  Result.AddPair('generation_id',TJSONNumber.Create(FDocument.GetValue<Int64>('generation_id')));
  Result.AddPair('runtime_trace',TJSONBool.Create(False)); Truncated:=False;
  Seen:=TDictionary<string,Boolean>.Create; EdgeKeys:=TDictionary<string,Boolean>.Create; Queue:=TQueue<string>.Create;
  try
    S:=FDocument.GetValue<TJSONObject>('semantics');
    if AKind='Procedure CFG' then
    begin
      AllNodes:=S.GetValue<TJSONArray>('flow_nodes'); AllEdges:=S.GetValue<TJSONArray>('flow_edges');
      for V in AllNodes do
      begin N:=V as TJSONObject; if N.GetValue<string>('routine')<>AKey then Continue;
        if Nodes.Count>=ALimit then begin Truncated:=True; Break; end;
        R:=N.Clone as TJSONObject; Key:=N.GetValue<Integer>('id').ToString; R.AddPair('label',N.GetValue<string>('kind')+' '+N.GetValue<string>('expression'));
        Nodes.AddElement(R); Seen.Add(Key,True);
      end;
      for V in AllEdges do begin R:=V as TJSONObject;
        if Seen.ContainsKey(R.GetValue<Integer>('from').ToString) and Seen.ContainsKey(R.GetValue<Integer>('to').ToString) then Edges.AddElement(R.Clone as TJSONObject);
      end;
    end
    else
    begin
      AddSymbolNode(AKey);
      if (AKey='') and (AKind='Execution') then
        for V in S.GetValue<TJSONArray>('symbols') do begin N:=V as TJSONObject;
          if (N.GetValue<string>('kind')='unit') and MatchText(N.GetValue<string>('type'),['program','library','package']) then AddSymbolNode(N.GetValue<string>('key'));
        end;
      if (AKey='') and (AKind='Form navigation') then
        for V in S.GetValue<TJSONArray>('symbols') do begin N:=V as TJSONObject;
          if (N.GetValue<string>('kind')='component') and MatchText(ExtractFileExt(N.GetValue<string>('range.source')),['.fmx','.dfm']) then begin
            R:=SourceFile(N.GetValue<string>('range.source'));
            if (R<>nil) and (R.GetValue<TJSONArray>('ir.nodes').Count>0) and
              (R.GetValue<TJSONArray>('ir.nodes').Items[0].GetValue<Int64>('start')=N.GetValue<Int64>('range.start')) then AddSymbolNode(N.GetValue<string>('key'));
          end;
        end;
      if (AKey='') and (AKind='Data flow') then
        for V in S.GetValue<TJSONArray>('symbols') do begin N:=V as TJSONObject;
          if MatchText(N.GetValue<string>('kind'),['parameter','local','field','property','variable','resource','definition','sql_statement','sql_table','sql_column','output_artifact']) then AddSymbolNode(N.GetValue<string>('key'));
        end;
      if (AKey='') and (Nodes.Count=0) then for V in S.GetValue<TJSONArray>('symbols') do
      begin N:=V as TJSONObject; if N.GetValue<Boolean>('has_body') then begin AddSymbolNode(N.GetValue<string>('key')); Break; end; end;
      while Queue.Count>0 do
      begin
        Key:=Queue.Dequeue;
        for V in S.GetValue<TJSONArray>('relationships') do
        begin
          R:=V as TJSONObject; Kind:=R.GetValue<string>('kind'); FromKey:=R.GetValue<string>('from'); ToKey:=R.GetValue<string>('to','');
          if (AKind='Change impact') then begin if ToKey<>Key then Continue; end
          else if (AKind='Caller / callee') then begin if (FromKey<>Key) and (ToKey<>Key) then Continue; end
          else if (AKind='Data flow') then begin if (FromKey<>Key) and (ToKey<>Key) then Continue; end
          else if (AKind='Form navigation') and MatchText(Kind,['represents','form_instance','component_field','binds']) then begin if (FromKey<>Key) and (ToKey<>Key) then Continue; end
          else if FromKey<>Key then Continue;
          if (AKind='Execution') and not MatchText(Kind,['calls','schedules','passes_callback','prepares_callback','starts','dispatches','waits_for','requests_cancellation','signals','waits_for_signal','binds','enters','initializes','finalizes','creates']) then Continue;
          if (AKind='Form navigation') and not MatchText(Kind,['owns','binds','calls','schedules','creates','assigned_to','mutates_property','assigns_callback','uses_type','represents','form_instance','component_field','shows_form','shows_modal_form','hides_form','closes_form']) then Continue;
          if (AKind='Data flow') and not MatchText(Kind,['reads','writes','renders','captures','assigned_to','derives_from','configures','static_sql','dynamic_sql','mutates_property']) then Continue;
          AddSymbolNode(FromKey); AddSymbolNode(ToKey);
          if Seen.ContainsKey(FromKey) and Seen.ContainsKey(ToKey) then begin
            EdgeKey:=FromKey+#0+ToKey+#0+Kind+#0+R.GetValue<string>('range.source')+#0+R.GetValue<Int64>('range.start').ToString+#0+R.GetValue<string>('rule')+#0+R.GetValue<string>('condition');
            if not EdgeKeys.ContainsKey(EdgeKey) then begin EdgeKeys.Add(EdgeKey,True); Edges.AddElement(R.Clone as TJSONObject); end;
          end;
          if Edges.Count>=ALimit*8 then begin Truncated:=True; Queue.Clear; Break; end;
        end;
      end;
    end;
    Result.AddPair('truncated',TJSONBool.Create(Truncated));
  finally Queue.Free; EdgeKeys.Free; Seen.Free; end;
end;
function TDPHWorkspaceView.Questions(AKnowledge: TJSONArray): TJSONArray;
var V: TJSONValue; Row,Range,Answer: TJSONObject; Diagnostics: TJSONArray;
  Answered,Seen: TDictionary<string,Boolean>; Counts: TDictionary<string,Integer>;
  Kind,Title,Prompt,Key,Code,Context: string; HasUser,HasBuild: Boolean;
  procedure AddQuestion(const AKind,ATitle,APrompt,AKey,ARule: string; ARange: TJSONObject);
  var Item,Location,Source: TJSONObject; ID,Hash: string; Count: Integer;
  begin
    if Result.Count>=100 then Exit; Count:=0; Counts.TryGetValue(AKind,Count); if Count>=20 then Exit;
    if ARange<>nil then Location:=ARange.Clone as TJSONObject else begin Location:=TJSONObject.Create;
      Location.AddPair('source',''); Location.AddPair('start',TJSONNumber.Create(0)); Location.AddPair('end',TJSONNumber.Create(0));
      Location.AddPair('line',TJSONNumber.Create(0)); Location.AddPair('column',TJSONNumber.Create(0)); end;
    Hash:=''; Source:=SourceFile(Location.GetValue<string>('source','')); if Source<>nil then Hash:=Source.GetValue<string>('sha256','');
    ID:=THashSHA2.GetHashString(AKind+#0+AKey+#0+Location.ToJSON+#0+Hash+#0+APrompt+#0+ARule+#0+Context);
    if Seen.ContainsKey(ID) or Answered.ContainsKey(ID) then begin Location.Free; Exit; end;
    Seen.Add(ID,True); Counts.AddOrSetValue(AKind,Count+1); Item:=TJSONObject.Create; Result.AddElement(Item);
    Item.AddPair('id',ID); Item.AddPair('kind',AKind); Item.AddPair('title',ATitle); Item.AddPair('prompt',APrompt);
    Item.AddPair('entity_key',AKey); Item.AddPair('range',Location); Item.AddPair('source_hash',Hash); Item.AddPair('rule',ARule);
    Item.AddPair('context_fingerprint',Context); Item.AddPair('generation_id',FDocument.GetValue<Int64>('generation_id').ToString);
    Item.AddPair('verification_state','unanswered_question');
    Item.AddPair('answer_kind',IfThen(ATitle='Document the operating procedure','user_help',IfThen(ATitle='Document build and deployment','build_deploy','unknown')));
  end;
begin
  Result:=TJSONArray.Create; Answered:=TDictionary<string,Boolean>.Create; Seen:=TDictionary<string,Boolean>.Create; Counts:=TDictionary<string,Integer>.Create;
  try
    Context:=FDocument.GetValue<string>('semantics.context_fingerprint'); HasUser:=False; HasBuild:=False;
    if AKnowledge<>nil then for V in AKnowledge do begin Row:=V as TJSONObject;
      if (Row.GetValue<string>('state','')<>'verified') or (Row.GetValue<string>('pending','1')<>'0') then Continue;
      HasUser:=HasUser or (Row.GetValue<string>('kind')='user_help'); HasBuild:=HasBuild or (Row.GetValue<string>('kind')='build_deploy');
      Answer:=TJSONObject.ParseJSONValue(Row.GetValue<string>('question_json','')) as TJSONObject;
      try if Answer<>nil then Answered.AddOrSetValue(Answer.GetValue<string>('id'),True); finally Answer.Free; end;
    end;
    Prompt:='For '+FDocument.GetValue<string>('entry')+' ('+FDocument.GetValue<string>('configuration')+' / '+FDocument.GetValue<string>('platform')+'), ';
    if not HasUser then AddQuestion('missing_procedure','Document the operating procedure',Prompt+
      'which user actions, required inputs, permissions, success checks and recovery steps should a new operator follow? No verified user-help record is captured. Provide an attributed procedure and examples; control names alone cannot establish it.','','absence_of_verified_user_help_record',nil);
    if not HasBuild then AddQuestion('missing_procedure','Document build and deployment',Prompt+
      'what exact toolchain, dependencies, environment settings, build commands, installation and rollback steps are required? No verified build/deployment record is captured. Passive scanning did not run the project.','','absence_of_verified_build_record',nil);
    for V in FDocument.GetValue<TJSONArray>('semantics.relationships') do begin Row:=V as TJSONObject;
      if not MatchText(Row.GetValue<string>('resolution'),['unresolved','possible_dynamic']) then Continue;
      Kind:=Row.GetValue<string>('kind'); Key:=Row.GetValue<string>('from');
      if not MatchText(Kind,['calls','binds','schedules','passes_callback','dynamic_sql','renders','shows_form','shows_modal_form']) then Continue;
      Prompt:='At '+Row.GetValue<string>('range.source')+':'+Row.GetValue<Int64>('range.line').ToString+', the captured '+Kind+
        ' relationship '+Row.GetValue<string>('label','')+' is '+Row.GetValue<string>('resolution')+'. Which concrete target or behavior is intended in this configuration, what selects it, and which example or test verifies that choice?';
      AddQuestion('unresolved_relationship','Resolve '+Kind+' at '+Row.GetValue<string>('range.source'),Prompt,Key,Row.GetValue<string>('rule'),Row.GetValue<TJSONObject>('range'));
    end;
    Diagnostics:=TJSONArray.Create;
    try
      for V in FDocument.GetValue<TJSONArray>('syntax.diagnostics') do Diagnostics.AddElement(V.Clone as TJSONObject);
      for V in FDocument.GetValue<TJSONArray>('semantics.diagnostics') do Diagnostics.AddElement(V.Clone as TJSONObject);
      for V in Diagnostics do begin Row:=V as TJSONObject; Code:=Row.GetValue<string>('code'); Range:=Row.GetValue<TJSONObject>('range');
        if not (ContainsText(Code,'UNRESOLVED') or ContainsText(Code,'UNSUPPORTED') or ContainsText(Code,'DYNAMIC') or ContainsText(Code,'REVIEW') or ContainsText(Code,'OPAQUE')) then Continue;
        Prompt:='The captured diagnostic '+Code+' at '+Range.GetValue<string>('source')+':'+Range.GetValue<Int64>('line').ToString+
          ' reports: '+Row.GetValue<string>('message')+'. Please explain the intended behavior at this location, its required inputs and effects, and a regression example. This is an analysis gap; it does not establish a runtime defect.';
        AddQuestion('diagnostic_gap','Explain '+Code,Prompt,'',Code,Range);
      end;
    finally Diagnostics.Free; end;
    for V in FDocument.GetValue<TJSONArray>('semantics.symbols') do begin Row:=V as TJSONObject; Kind:=Row.GetValue<string>('kind');
      if not MatchText(Kind,['async_operation','sql_statement','output_artifact']) then Continue;
      Title:=''; Prompt:='';
      if Kind='async_operation' then begin Title:='Explain background-work ownership'; Prompt:='For captured operation '+Row.GetValue<string>('name')+', which thread or object owns the work, what signals completion, what cancels it, and what lifetime guarantees and tests are required? Captured scheduling does not establish runtime order.'; end;
      if Kind='sql_statement' then begin Title:='Explain SQL contract'; Prompt:='For captured SQL statement '+Row.GetValue<string>('name')+', which schema, parameter constraints, transaction boundaries and failure handling are intended? Provide a safe test example and the expected data effect. No database connection was made.'; end;
      if Kind='output_artifact' then begin Title:='Explain output acceptance'; Prompt:='For captured output '+Row.GetValue<string>('name')+', what destination and contents are required, which inputs determine them, how should a user verify success, and how should partial or failed writes be handled? Static writer evidence does not prove that a file was produced.'; end;
      AddQuestion(Kind,Title,Prompt,Row.GetValue<string>('key'),'captured_object_missing_operational_contract',Row.GetValue<TJSONObject>('range'));
    end;
  except Result.Free; Counts.Free; Seen.Free; Answered.Free; raise;
  end;
  Counts.Free; Seen.Free; Answered.Free;
end;
function TDPHWorkspaceView.Coverage: TJSONObject;
var Files,Relations,Diagnostics,Metrics,Nodes: TJSONArray; V,W,E: TJSONValue; R,IR,N,Edge: TJSONObject;
  Parsed,Available,Complete,Confirmed,Unresolved,Events,BoundEvents,Evidence: Integer; Recognized,Tokens: Int64; Matched: Boolean;
  procedure Metric(const Name,Definition: string; Numerator,Denominator: Int64);
  var Row: TJSONObject;
  begin Row:=TJSONObject.Create; Metrics.AddElement(Row); Row.AddPair('name',Name);
    Row.AddPair('definition',Definition); Row.AddPair('numerator',TJSONNumber.Create(Numerator));
    Row.AddPair('denominator',TJSONNumber.Create(Denominator)); end;
begin
  Result:=TJSONObject.Create; Metrics:=TJSONArray.Create; Result.AddPair('metrics',Metrics);
  Diagnostics:=TJSONArray.Create; Result.AddPair('diagnostics',Diagnostics);
  Files:=FDocument.GetValue<TJSONArray>('syntax.files'); Relations:=FDocument.GetValue<TJSONArray>('semantics.relationships');
  Parsed:=0; Available:=0; Complete:=0; Recognized:=0; Tokens:=0; Confirmed:=0; Unresolved:=0;
  Events:=0; BoundEvents:=0; Evidence:=0;
  for V in Files do begin R:=V as TJSONObject;
    if R.GetValue<string>('sha256','')<>'' then Inc(Available);
    if R.TryGetValue<TJSONObject>('ir',IR) then begin Inc(Parsed);
      if IR.GetValue<Boolean>('complete',False) then Inc(Complete);
      Inc(Recognized,IR.GetValue<Int64>('recognized_tokens',0)); Inc(Tokens,IR.GetValue<Int64>('significant_tokens',0));
      if MatchText(ExtractFileExt(R.GetValue<string>('path')),['.fmx','.dfm']) and IR.TryGetValue<TJSONArray>('nodes',Nodes) then
        for W in Nodes do begin N:=W as TJSONObject;
          if (N.GetValue<string>('kind')<>'property') or not StartsText('On',N.GetValue<string>('name')) or (Trim(N.GetValue<string>('value'))='') then Continue;
          Inc(Events); Matched:=False;
          for E in Relations do begin Edge:=E as TJSONObject;
            if (Edge.GetValue<string>('kind')='binds') and (Edge.GetValue<string>('resolution')='confirmed_static') and
              SameText(Edge.GetValue<string>('range.source'),R.GetValue<string>('path')) and
              (Edge.GetValue<Int64>('range.start')=N.GetValue<Int64>('start')) then begin Matched:=True; Break; end;
          end;
          if Matched then Inc(BoundEvents);
        end;
    end;
  end;
  for V in Relations do begin R:=V as TJSONObject;
    if R.GetValue<string>('resolution')='confirmed_static' then Inc(Confirmed);
    if R.GetValue<string>('resolution')='unresolved' then Inc(Unresolved);
    if (R.GetValue<string>('range.source','')<>'') and (R.GetValue<string>('rule','')<>'') then Inc(Evidence);
  end;
  Metric('Fingerprinted inventory files','Files with captured SHA256 / files in selected inventory. Not all files on disk.',Available,Files.Count);
  Metric('Files with parsed IR','Files with an intermediate representation / selected inventory files. Opaque resources may have no IR.',Parsed,Files.Count);
  Metric('Complete parsed files','IR complete flag / files with IR. This does not measure semantic correctness.',Complete,Parsed);
  Metric('Recognized syntax tokens','Sum of recognized tokens / significant tokens in parsed files. Not runtime coverage.',Recognized,Tokens);
  Metric('Confirmed static relationships','confirmed_static relationship records / all captured relationship records. Inferred edges remain separate.',Confirmed,Relations.Count);
  Metric('Unresolved relationships','unresolved relationship records / all captured relationship records. A zero count does not prove completeness.',Unresolved,Relations.Count);
  Metric('Serialized event bindings','Nonempty On-prefixed serialized properties with a confirmed static binds edge / nonempty On-prefixed properties in captured forms. Dynamic assignments excluded.',BoundEvents,Events);
  Metric('Source-located relationship evidence','Relationship records with a source location and derivation rule / all captured relationship records. Location is not human verification.',Evidence,Relations.Count);
  for V in FDocument.GetValue<TJSONArray>('syntax.diagnostics') do Diagnostics.AddElement(V.Clone as TJSONObject);
  for V in FDocument.GetValue<TJSONArray>('semantics.diagnostics') do Diagnostics.AddElement(V.Clone as TJSONObject);
end;
function TDPHWorkspaceView.FlagsText: string;
begin
  Result:='Generation '+FDocument.GetValue<Int64>('generation_id').ToString+' | ';
  if FDocument.GetValue<Boolean>('analysis_complete') then Result:=Result+'complete captured analysis' else Result:=Result+'PARTIAL analysis - inspect diagnostics';
  Result:=Result+' | static evidence; runtime behavior unobserved';
end;
end.
