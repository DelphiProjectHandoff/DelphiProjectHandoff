unit DPH.Analysis.Symbols;

interface
uses System.SysUtils, System.Generics.Collections, DPH.Parse.Model, DPH.Project.Analysis,
  DPH.Analysis.Model;
type
  TDPHRoutineSummary = class
    ValidationHash: string;
    Relations: TArray<TDPHRelation>;
    FromKeys,ToKeys: TArray<string>;
    Nodes: TArray<TDPHFlowNode>;
    Edges: TArray<TDPHFlowEdge>;
    Diagnostics: TArray<TDPHDiagnostic>;
    Complete: Boolean;
    Weight: Integer;
  end;
  TDPHSemanticAnalyzer = class
  private
    FScan: TDPHScan;
    FGraph: TDPHSemanticGraph;
    FNodeSymbols: TDictionary<string,Integer>;
    FNames: TObjectDictionary<string,TList<Integer>>;
    FTokens: TDictionary<string,TDPHTokens>;
    FImports: TObjectDictionary<string,TList<string>>;
    FKeys: TDictionary<string,Integer>;
    FBaseTypes: TDictionary<Integer,Integer>;
    FRoutineCache: TObjectDictionary<string,TDPHRoutineSummary>;
    FCacheWeight: Integer;
    FReusedRoutines,FRecomputedRoutines: Integer;
    FCallExact: Boolean;
    function NodeKey(const AFile: string; ANode: Integer): string;
    function ParentSymbol(const AFile: string; IR: TDPHParseResult; ANode: Integer): Integer;
    function AddSymbol(S: TDPHSymbol): Integer;
    function FindType(const AName,AUnit: string): Integer;
    function FindDeclaredType(const AName,AUnit: string): Integer;
    function CanonicalType(const AName,AUnit: string): string;
    function FindVariable(const AName: string; ARoutine: Integer): Integer;
    function ResolveValue(const APath: string; ARoutine: Integer): Integer;
    function Candidates(const AName: string; ARoutine: Integer): TArray<Integer>;
    function SelectCall(const APath: string; ARoutine: Integer; const Arguments: TArray<string>): TArray<Integer>;
    function ExpressionType(const AText: string; ARoutine: Integer): string;
    procedure Header(S: TDPHSymbol; const Tokens: TDPHTokens; AStart,AEnd: Integer);
    procedure Collect(const AFile: string; IR: TDPHParseResult);
    procedure Variables(const AFile: string; IR: TDPHParseResult);
    procedure PropertyAccessors(const AFile: string; IR: TDPHParseResult);
    procedure ModulePhases;
    procedure TestCoverage;
    procedure Dependencies(const AFile: string; IR: TDPHParseResult);
    procedure BindForms(const AFile: string; IR: TDPHParseResult);
    procedure RoutineFacts(ARoutine: Integer; IR: TDPHParseResult; const Tokens: TDPHTokens);
    procedure CachedRoutineFacts(ARoutine: Integer; IR: TDPHParseResult; const Tokens: TDPHTokens; const ABindingHash: string);
  public
    constructor Create;
    destructor Destroy; override;
    function Analyze(AScan: TDPHScan; AIncremental: Boolean = True): TDPHSemanticGraph;
    property ReusedRoutines: Integer read FReusedRoutines;
    property RecomputedRoutines: Integer read FRecomputedRoutines;
  end;
implementation
uses System.Classes, System.StrUtils, System.Hash, DPH.Storage.Types,
  DPH.Storage.Database, DPH.Analysis.Flow, DPH.Analysis.Async, DPH.Analysis.SQL, DPH.Project.Inventory;

constructor TDPHSemanticAnalyzer.Create;
begin inherited; FRoutineCache:=TObjectDictionary<string,TDPHRoutineSummary>.Create([doOwnsValues]); end;
destructor TDPHSemanticAnalyzer.Destroy;
begin FRoutineCache.Free; inherited; end;

procedure TDPHSemanticAnalyzer.CachedRoutineFacts(ARoutine: Integer; IR: TDPHParseResult; const Tokens: TDPHTokens; const ABindingHash: string);
var Summary,Previous: TDPHRoutineSummary; Validation: string; Routine: TDPHSymbol;
    I,RelationStart,NodeStart,EdgeStart,DiagnosticStart,NodeOffset: Integer;
    R: TDPHRelation; N: TDPHFlowNode; E: TDPHFlowEdge; D: TDPHDiagnostic; CompleteBefore,RoutineComplete: Boolean;
begin
  Routine:=FGraph.Symbols[ARoutine];
  Validation:=THashSHA2.GetHashString(ABindingHash+#0+Routine.Key+#0+Routine.SourceHash);
  if FRoutineCache.TryGetValue(Routine.Key,Summary) and (Summary.ValidationHash=Validation) then begin
    if (FGraph.Relations.Count+Length(Summary.Relations)>200000) or
      (FGraph.FlowNodes.Count+Length(Summary.Nodes)>100000) or
      (FGraph.FlowEdges.Count+Length(Summary.Edges)>300000) then raise ERangeError.Create('Reused semantic graph exceeds analysis limits');
    NodeOffset:=FGraph.FlowNodes.Count;
    for I:=0 to High(Summary.Relations) do begin
      R:=Summary.Relations[I]; R.FromSymbol:=FKeys[Summary.FromKeys[I]];
      R.ToSymbol:=-1; if Summary.ToKeys[I]<>'' then R.ToSymbol:=FKeys[Summary.ToKeys[I]];
      FGraph.Relations.Add(R);
    end;
    for I:=0 to High(Summary.Nodes) do begin N:=Summary.Nodes[I]; N.Routine:=ARoutine; FGraph.FlowNodes.Add(N); end;
    for I:=0 to High(Summary.Edges) do begin E:=Summary.Edges[I]; Inc(E.FromNode,NodeOffset); Inc(E.ToNode,NodeOffset); FGraph.FlowEdges.Add(E); end;
    for D in Summary.Diagnostics do if FGraph.Diagnostics.Count<10000 then FGraph.Diagnostics.Add(D);
    FGraph.Complete:=FGraph.Complete and Summary.Complete;
    Inc(FReusedRoutines); Exit;
  end;
  Inc(FRecomputedRoutines); RelationStart:=FGraph.Relations.Count; NodeStart:=FGraph.FlowNodes.Count;
  EdgeStart:=FGraph.FlowEdges.Count; DiagnosticStart:=FGraph.Diagnostics.Count;
  CompleteBefore:=FGraph.Complete; FGraph.Complete:=True;
  RoutineComplete:=False;
  try RoutineFacts(ARoutine,IR,Tokens); RoutineComplete:=FGraph.Complete;
  finally FGraph.Complete:=FGraph.Complete and CompleteBefore; end;
  // Do not cache exceptionally large routines or exceed a bounded session cache.
  I:=(FGraph.Relations.Count-RelationStart)+(FGraph.FlowNodes.Count-NodeStart)+
    (FGraph.FlowEdges.Count-EdgeStart)+(FGraph.Diagnostics.Count-DiagnosticStart);
  if (I>512) or (FGraph.Diagnostics.Count>=10000) or
    ((FRoutineCache.Count>=512) and not FRoutineCache.ContainsKey(Routine.Key)) then Exit;
  Summary:=TDPHRoutineSummary.Create;
  try
    Summary.ValidationHash:=Validation; Summary.Weight:=I*512; Summary.Complete:=RoutineComplete;
    SetLength(Summary.Relations,FGraph.Relations.Count-RelationStart);
    SetLength(Summary.FromKeys,Length(Summary.Relations)); SetLength(Summary.ToKeys,Length(Summary.Relations));
    for I:=0 to High(Summary.Relations) do begin
      R:=FGraph.Relations[RelationStart+I]; Summary.Relations[I]:=R;
      Summary.FromKeys[I]:=FGraph.Symbols[R.FromSymbol].Key;
      if R.ToSymbol>=0 then Summary.ToKeys[I]:=FGraph.Symbols[R.ToSymbol].Key;
      Inc(Summary.Weight,2*(Length(Summary.FromKeys[I])+Length(Summary.ToKeys[I])+Length(R.LabelText)+Length(R.Rule)+Length(R.Condition)+Length(R.Location.Source)));
      if R.Resolution='unresolved' then Summary.Complete:=False;
    end;
    SetLength(Summary.Nodes,FGraph.FlowNodes.Count-NodeStart);
    for I:=0 to High(Summary.Nodes) do begin
      Summary.Nodes[I]:=FGraph.FlowNodes[NodeStart+I]; Inc(Summary.Weight,2*(Length(Summary.Nodes[I].ExpressionText)+Length(Summary.Nodes[I].Location.Source)));
    end;
    SetLength(Summary.Edges,FGraph.FlowEdges.Count-EdgeStart);
    for I:=0 to High(Summary.Edges) do begin
      E:=FGraph.FlowEdges[EdgeStart+I]; Dec(E.FromNode,NodeStart); Dec(E.ToNode,NodeStart); Summary.Edges[I]:=E;
    end;
    SetLength(Summary.Diagnostics,FGraph.Diagnostics.Count-DiagnosticStart);
    for I:=0 to High(Summary.Diagnostics) do begin
      Summary.Diagnostics[I]:=FGraph.Diagnostics[DiagnosticStart+I];
      Inc(Summary.Weight,2*(Length(Summary.Diagnostics[I].MessageText)+Length(Summary.Diagnostics[I].Location.Source)));
      if Summary.Diagnostics[I].Code='CFG_CONSERVATIVE_CONSTRUCT' then Summary.Complete:=False;
    end;
    if FCacheWeight+Summary.Weight>32*1024*1024 then Exit;
    if FRoutineCache.TryGetValue(Routine.Key,Previous) then Dec(FCacheWeight,Previous.Weight);
    Inc(FCacheWeight,Summary.Weight); FRoutineCache.AddOrSetValue(Routine.Key,Summary); Summary:=nil;
  finally Summary.Free; end;
end;

function TDPHSemanticAnalyzer.NodeKey(const AFile: string; ANode: Integer): string;
begin Result:=AFile+'#'+IntToStr(ANode); end;
function TDPHSemanticAnalyzer.ParentSymbol(const AFile: string; IR: TDPHParseResult; ANode: Integer): Integer;
begin
  Result:=-1;
  while ANode>=0 do
  begin if FNodeSymbols.TryGetValue(NodeKey(AFile,ANode),Result) then Exit; ANode:=IR.Nodes[ANode].Parent; end;
  Result:=-1;
end;
function TDPHSemanticAnalyzer.AddSymbol(S: TDPHSymbol): Integer;
var Names: TList<Integer>; Existing: TDPHSymbol;
begin
  if (Length(S.QualifiedName)>8192) or (Length(S.Signature)>8192) then
  begin S.Free; raise ERangeError.Create('Semantic identity size limit'); end;
  S.Key:=LowerCase(S.QualifiedName+'|'+S.Kind+'|'+S.Signature+'|'+S.Variant);
  if (S.Owner>=0) and MatchText(FGraph.Symbols[S.Owner].Kind,['routine','anonymous']) then
    S.Key:=S.Key+'|scope='+FGraph.Symbols[S.Owner].Key;
  if Length(S.Key)>16384 then begin S.Free; raise ERangeError.Create('Semantic scope key size limit'); end;
  if FKeys.TryGetValue(S.Key,Result) then
  begin
    Existing:=FGraph.Symbols[Result]; Existing.Occurrences.Add(S.Location);
    if S.HasBody and Existing.HasBody then
    begin FGraph.Complete:=False; FGraph.Diagnostics.Report('DUPLICATE_IMPLEMENTATION',S.QualifiedName,S.Location); end;
    if S.Dispatch='dynamic' then Existing.Dispatch:='dynamic';
    Existing.ClassMethod:=Existing.ClassMethod or S.ClassMethod;
    if S.HasBody then
    begin
      Existing.HasBody:=True; Existing.Location:=S.Location; Existing.BodyNode:=S.BodyNode;
      Existing.NodeIndex:=S.NodeIndex; Existing.Condition:=S.Condition;
      Existing.ParameterNames:=Copy(S.ParameterNames); Existing.ParameterTypes:=Copy(S.ParameterTypes);
    end;
    S.Free; Exit;
  end;
  if FGraph.Symbols.Count>=50000 then begin S.Free; raise ERangeError.Create('Semantic symbol limit'); end;
  S.Index:=FGraph.Symbols.Count; S.Occurrences.Add(S.Location); Result:=FGraph.Symbols.Add(S); FKeys.Add(S.Key,Result);
  if not FNames.TryGetValue(LowerCase(S.QualifiedName),Names) then
  begin Names:=TList<Integer>.Create; FNames.Add(LowerCase(S.QualifiedName),Names); end; Names.Add(Result);
  if S.Owner>=0 then FGraph.AddRelation(S.Owner,Result,'owns','confirmed_static','lexical_declaration',S.Name,S.Location,S.Condition);
end;

function TDPHSemanticAnalyzer.FindDeclaredType(const AName,AUnit: string): Integer;
var Items: TList<Integer>; I: Integer; S: TDPHSymbol; Found: Integer; Imports: TList<string>; U,Name: string;
begin
  Name:=AName; I:=Pos('<',Name); if I>0 then Name:=Copy(Name,1,I-1);
  Found:=-1;
  if FNames.TryGetValue(LowerCase(AUnit+'.'+Name),Items) or FNames.TryGetValue(LowerCase(Name),Items) then
    for I in Items do if FGraph.Symbols[I].Kind='type' then begin if Found>=0 then Exit(-1); Found:=I; end;
  if Found>=0 then Exit(Found);
  if FImports.TryGetValue(LowerCase(AUnit),Imports) then
    for U in Imports do if FNames.TryGetValue(LowerCase(U+'.'+Name),Items) then
      for I in Items do begin S:=FGraph.Symbols[I]; if (S.Kind='type') and S.Exported then begin if Found>=0 then Exit(-1); Found:=I; end; end;
  Result:=Found;
end;
function TDPHSemanticAnalyzer.FindType(const AName,AUnit: string): Integer;
var Pass,Next: Integer; Name,UnitName: string; Seen: TList<Integer>;
begin
  Seen:=TList<Integer>.Create;
  try
    Name:=AName; UnitName:=AUnit; Result:=-1;
    for Pass:=0 to 32 do begin
      Next:=FindDeclaredType(Name,UnitName); if Next<0 then Exit;
      if Seen.Contains(Next) then Exit(-1); Seen.Add(Next); Result:=Next;
      Name:=FGraph.Symbols[Next].TypeName; UnitName:=FGraph.Symbols[Next].UnitName;
      if (Name='') or MatchText(Name,['class','record','interface','dispinterface','object','type','array','set','procedure','function','reference','packed']) then Exit;
    end;
    Result:=-1;
  finally Seen.Free; end;
end;
function TDPHSemanticAnalyzer.CanonicalType(const AName,AUnit: string): string;
var Index,Pass,GenericAt: Integer; UnitName,GenericArguments: string; Seen: TList<Integer>;
begin
  Result:=LowerCase(AName); UnitName:=AUnit; Seen:=TList<Integer>.Create;
  try
    for Pass:=0 to 32 do begin
      Index:=FindDeclaredType(Result,UnitName); if Index<0 then Exit;
      if Seen.Contains(Index) then Exit(''); Seen.Add(Index);
      if MatchText(FGraph.Symbols[Index].TypeName,['class','record','interface','dispinterface','object','type','array','set','procedure','function','reference','packed','(','^']) then begin
        GenericArguments:=''; GenericAt:=Pos('<',Result); if GenericAt>0 then GenericArguments:=Copy(Result,GenericAt,MaxInt);
        Exit(LowerCase(FGraph.Symbols[Index].QualifiedName)+GenericArguments);
      end;
      Result:=LowerCase(FGraph.Symbols[Index].TypeName); UnitName:=FGraph.Symbols[Index].UnitName;
    end;
    Result:='';
  finally Seen.Free; end;
end;
function TDPHSemanticAnalyzer.FindVariable(const AName: string; ARoutine: Integer): Integer;
var Scope,I,OwnerType,Pass,Base: Integer; S: TDPHSymbol; R: TDPHRelation; Qualified: string; Items: TList<Integer>;
begin
  Result:=-1; Scope:=ARoutine;
  while Scope>=0 do
  begin
    Qualified:=FGraph.Symbols[Scope].QualifiedName+'.'+AName;
    if FNames.TryGetValue(LowerCase(Qualified),Items) then
      for I in Items do if (FGraph.Symbols[I].Owner=Scope) and MatchText(FGraph.Symbols[I].Kind,['local','parameter','field','property','variable']) then Exit(I);
    Scope:=FGraph.Symbols[Scope].Owner;
  end;
  S:=FGraph.Symbols[ARoutine]; OwnerType:=FindType(S.OwnerName,S.UnitName);
  for Pass:=0 to 32 do
  begin
    if OwnerType<0 then Break;
    if FNames.TryGetValue(LowerCase(FGraph.Symbols[OwnerType].QualifiedName+'.'+AName),Items) then
      for I in Items do if MatchText(FGraph.Symbols[I].Kind,['field','property']) then Exit(I);
    if not FBaseTypes.TryGetValue(OwnerType,Base) then Base:=-1;
    OwnerType:=Base;
  end;
end;
function TDPHSemanticAnalyzer.ResolveValue(const APath: string; ARoutine: Integer): Integer;
var Parts: TArray<string>; I,TypeIndex,Member,Pass,Base: Integer; Items: TList<Integer>; U: string;
begin
  Parts:=APath.Split(['.']); Result:=-1; if Length(Parts)=0 then Exit;
  U:=FGraph.Symbols[ARoutine].UnitName;
  if SameText(Parts[0],'Self') then Result:=FindType(FGraph.Symbols[ARoutine].OwnerName,U)
  else Result:=FindVariable(Parts[0],ARoutine);
  if Result<0 then Result:=FindType(Parts[0],U);
  for I:=1 to High(Parts) do
  begin
    if Result<0 then Exit;
    if FGraph.Symbols[Result].Kind='type' then TypeIndex:=Result else TypeIndex:=FindType(FGraph.Symbols[Result].TypeName,U);
    Result:=-1; if TypeIndex<0 then Exit;
    for Pass:=0 to 32 do begin
      if FNames.TryGetValue(LowerCase(FGraph.Symbols[TypeIndex].QualifiedName+'.'+Parts[I]),Items) then
        for Member in Items do if MatchText(FGraph.Symbols[Member].Kind,['field','property']) then begin Result:=Member; Break; end;
      if Result>=0 then Break;
      if not FBaseTypes.TryGetValue(TypeIndex,Base) or (Base<0) then Break; TypeIndex:=Base;
    end;
  end;
end;
function TDPHSemanticAnalyzer.Candidates(const AName: string; ARoutine: Integer): TArray<Integer>;
var Items,Found: TList<Integer>; Names: TList<string>; Name,Receiver,Member,U: string;
    Scope,I,Dot,TypeIndex,Base,Pass: Integer; R: TDPHRelation; S: TDPHSymbol;
  procedure Append(const Qualified: string);
  var Index,DeclOwner,Lexical: Integer; Accessible: Boolean;
  begin
    if FNames.TryGetValue(LowerCase(Qualified),Items) then
      for Index in Items do if MatchText(FGraph.Symbols[Index].Kind,['routine','anonymous']) and
        (SameText(FGraph.Symbols[Index].UnitName,S.UnitName) or FGraph.Symbols[Index].Exported) then
      begin
        DeclOwner:=FGraph.Symbols[Index].Owner; Accessible:=True;
        if (DeclOwner>=0) and MatchText(FGraph.Symbols[DeclOwner].Kind,['routine','anonymous']) then
        begin
          Accessible:=False; Lexical:=ARoutine;
          while Lexical>=0 do begin if Lexical=DeclOwner then begin Accessible:=True; Break; end; Lexical:=FGraph.Symbols[Lexical].Owner; end;
        end;
        if Accessible then Found.Add(Index);
      end;
  end;
begin
  Found:=TList<Integer>.Create;
  try
    S:=FGraph.Symbols[ARoutine]; Dot:=LastDelimiter('.',AName);
    if Dot>0 then
    begin
      Receiver:=Copy(AName,1,Dot-1); Member:=Copy(AName,Dot+1,MaxInt);
      TypeIndex:=ResolveValue(Receiver,ARoutine);
      if (TypeIndex>=0) and (FGraph.Symbols[TypeIndex].Kind<>'type') then TypeIndex:=FindType(FGraph.Symbols[TypeIndex].TypeName,S.UnitName);
      if SameText(Receiver,'inherited') then
      begin
        TypeIndex:=FindType(S.OwnerName,S.UnitName); Base:=-1;
        if not FBaseTypes.TryGetValue(TypeIndex,Base) then Base:=-1;
        TypeIndex:=Base;
      end;
      if TypeIndex>=0 then
      begin
        for Pass:=0 to 32 do
        begin
          Append(FGraph.Symbols[TypeIndex].QualifiedName+'.'+Member); if Found.Count>0 then Break;
          if not FBaseTypes.TryGetValue(TypeIndex,Base) then Base:=-1;
          if Base<0 then Break; TypeIndex:=Base;
        end;
      end
      else if SameText(Receiver,S.UnitName) then Append(Receiver+'.'+Member)
      else if FImports.TryGetValue(LowerCase(S.UnitName),Names) and Names.Contains(Receiver) then Append(Receiver+'.'+Member);
    end
    else
    begin
      Scope:=ARoutine;
      while Scope>=0 do
      begin Append(FGraph.Symbols[Scope].QualifiedName+'.'+AName); if Found.Count>0 then Break; Scope:=FGraph.Symbols[Scope].Owner; end;
      if (Found.Count=0) and (S.OwnerName<>'') then
      begin
        TypeIndex:=FindType(S.OwnerName,S.UnitName);
        for Pass:=0 to 32 do
        begin
          if TypeIndex<0 then Break;
          Append(FGraph.Symbols[TypeIndex].QualifiedName+'.'+AName); if Found.Count>0 then Break;
          if not FBaseTypes.TryGetValue(TypeIndex,Base) then Base:=-1;
          TypeIndex:=Base;
        end;
      end;
      if Found.Count=0 then Append(S.UnitName+'.'+AName);
      if (Found.Count=0) and FImports.TryGetValue(LowerCase(S.UnitName),Names) then
        for U in Names do Append(U+'.'+AName);
    end;
    Result:=Found.ToArray;
  finally Found.Free; end;
end;
function TDPHSemanticAnalyzer.ExpressionType(const AText: string; ARoutine: Integer): string;
var V,I: Integer; Number: Int64;
begin
  Result:=''; if AText='' then Exit;
  if AText[1]='''' then
  begin
    I:=2;
    while I<=Length(AText) do
    begin
      if AText[I]='''' then
      begin
        if I=Length(AText) then Exit('string');
        if AText[I+1]<>'''' then Exit(''); Inc(I);
      end;
      Inc(I);
    end;
    Exit('');
  end;
  if TryStrToInt64(AText,Number) then Exit('integer');
  if MatchText(AText,['True','False']) then Exit('boolean');
  V:=ResolveValue(AText,ARoutine); if V>=0 then Result:=CanonicalType(FGraph.Symbols[V].TypeName,FGraph.Symbols[V].UnitName);
end;
function TDPHSemanticAnalyzer.SelectCall(const APath: string; ARoutine: Integer; const Arguments: TArray<string>): TArray<Integer>;
var Items,Exact: TList<Integer>; Candidate,I: Integer; S: TDPHSymbol; Matches,Known: Boolean; TypeName: string;
begin
  FCallExact:=False;
  Items:=TList<Integer>.Create; Exact:=TList<Integer>.Create;
  try
    if (not APath.Contains('.')) and (FindVariable(APath,ARoutine)>=0) then Exit(nil);
    for Candidate in Candidates(APath,ARoutine) do
    begin
      S:=FGraph.Symbols[Candidate]; if (Length(Arguments)<S.MinArguments) or (Length(Arguments)>Length(S.ParameterTypes)) then Continue;
      Matches:=True; Known:=True;
      for I:=0 to High(Arguments) do
      begin
        TypeName:=ExpressionType(Arguments[I],ARoutine);
        if TypeName='' then Known:=False else if not SameText(TypeName,CanonicalType(S.ParameterTypes[I],S.UnitName)) then Matches:=False;
      end;
      if Matches then begin Items.Add(Candidate); if Known then Exact.Add(Candidate); end;
    end;
    if Exact.Count>0 then begin FCallExact:=True; Result:=Exact.ToArray; end else Result:=Items.ToArray;
  finally Exact.Free; Items.Free; end;
end;

procedure TDPHSemanticAnalyzer.Header(S: TDPHSymbol; const Tokens: TDPHTokens; AStart,AEnd: Integer);
var I,J,Colon,Count,OpenAt,CloseAt,Depth: Integer; Names,Types: TList<string>; Group: TList<string>; T,TypeName: string;
begin
  Names:=TList<string>.Create; Types:=TList<string>.Create; Group:=TList<string>.Create;
  try
    OpenAt:=-1; CloseAt:=-1; Depth:=0; I:=AStart;
    while I<=AEnd do
    begin
      T:=LowerCase(Tokens[I].Text);
      if (Depth=0) and MatchText(T,[';','begin','var','const','type']) then Break;
      if T='(' then begin if OpenAt<0 then OpenAt:=I; Inc(Depth); end;
      if T=')' then begin Dec(Depth); if Depth=0 then CloseAt:=I; end;
      Inc(I);
    end;
    S.ClassMethod:=SameText(Tokens[AStart].Text,'class');
    if (OpenAt>=0) and (CloseAt>OpenAt) then
    begin
      I:=OpenAt+1;
      while I<CloseAt do
      begin
        Group.Clear;
        while (I<CloseAt) and (Tokens[I].Text<>':') do
        begin
          T:=Tokens[I].Text;
          if (Tokens[I].Kind=tkIdentifier) and not MatchText(T,['const','var','out','constref']) then Group.Add(T);
          Inc(I);
        end;
        if I>=CloseAt then Break; Inc(I); TypeName:='';
        while (I<CloseAt) and not MatchText(Tokens[I].Text,[';','=']) do begin TypeName:=TypeName+LowerCase(Tokens[I].Text); Inc(I); end;
        for T in Group do begin Names.Add(T); Types.Add(TypeName); end;
        if (I<CloseAt) and (Tokens[I].Text='=') then
        begin while (I<CloseAt) and (Tokens[I].Text<>';') do Inc(I); end
        else Inc(S.MinArguments,Group.Count);
        if I<CloseAt then Inc(I);
      end;
    end;
    if CloseAt>=0 then I:=CloseAt+1 else
    begin I:=AStart; while (I<=AEnd) and not MatchText(Tokens[I].Text,[';',':','begin','var']) do Inc(I); end;
    if (I<=AEnd) and (Tokens[I].Text=':') then
    begin Inc(I); while (I<=AEnd) and not MatchText(Tokens[I].Text,[';','begin','var','const','type']) do begin S.TypeName:=S.TypeName+LowerCase(Tokens[I].Text); Inc(I); end; end;
    S.ParameterNames:=Names.ToArray; S.ParameterTypes:=Types.ToArray;
    S.Signature:='('+String.Join(';',S.ParameterTypes)+'):'+S.TypeName;
    S.Dispatch:='direct';
    // Dispatch directives are after the prototype's first semicolon.
    for J:=AStart to AEnd do
    begin
      if MatchText(Tokens[J].Text,['begin','var','const','type']) then Break;
      if MatchText(Tokens[J].Text,['virtual','dynamic','override']) then S.Dispatch:='dynamic';
    end;
  finally Group.Free; Types.Free; Names.Free; end;
end;

procedure TDPHSemanticAnalyzer.Collect(const AFile: string; IR: TDPHParseResult);
var N,Child: TDPHIRNode; S,Owner: TDPHSymbol; I,J,OwnerIndex,Index,Ordinal: Integer;
    UnitName,Kind,Name,Variant,Visibility: string; Tokens: TDPHTokens; Anon: TDictionary<Integer,Integer>; ImplementationAt,K: Integer;
begin
  if IR.Nodes.Count=0 then Exit; Kind:=IR.Nodes[0].Kind;
  if Kind='resource' then begin
    for I:=0 to IR.Nodes.Count-1 do begin
      N:=IR.Nodes[I]; S:=TDPHSymbol.Create; S.Location:=N.Location; S.NodeIndex:=I;
      S.SourceHash:=FGraph.SourceHashes[AFile]; S.Variant:=FGraph.Configuration;
      S.Name:=N.Name; S.Kind:='definition'; if I=0 then S.Kind:='resource';
      S.Signature:=N.Kind; S.UnitName:=AFile; S.QualifiedName:=AFile+'#'+N.Name;
      S.Owner:=ParentSymbol(AFile,IR,N.Parent);
      if S.Owner>=0 then S.QualifiedName:=FGraph.Symbols[S.Owner].QualifiedName+'/'+N.Name;
      Index:=AddSymbol(S); FNodeSymbols.Add(NodeKey(AFile,I),Index);
      if N.Parent>=0 then FGraph.AddRelation(FGraph.Symbols[Index].Owner,Index,'owns','confirmed_static','resource_document_structure',N.Kind,N.Location,'');
    end;
    Exit;
  end;
  if not MatchText(Kind,['unit','program','library','package']) then Exit;
  UnitName:=IR.Nodes[0].Name; Tokens:=FTokens[AFile];
  ImplementationAt:=MaxInt;
  for J:=0 to High(Tokens) do if SameText(Tokens[J].Text,'implementation') then begin ImplementationAt:=J; Break; end;
  Variant:=FGraph.Configuration+';'+String.Join(';',FScan.Inventory.SourceDefines[AFile]);
  if not FImports.ContainsKey(LowerCase(UnitName)) then FImports.Add(LowerCase(UnitName),TList<string>.Create);
  for N in IR.Nodes do if N.Kind='unit_reference' then FImports[LowerCase(UnitName)].Add(N.Name);
  Anon:=TDictionary<Integer,Integer>.Create;
  try
    for I:=0 to IR.Nodes.Count-1 do
    begin
      N:=IR.Nodes[I]; if not MatchText(N.Kind,['unit','program','library','package','type']) and not N.Kind.StartsWith('routine_') and not N.Kind.StartsWith('anonymous_') and
        not ((N.Parent=0) and MatchText(N.Kind,['block','initialization','finalization'])) then Continue;
      S:=TDPHSymbol.Create; S.Location:=N.Location; S.NodeIndex:=I; S.Condition:=N.Condition;
      S.Exported:=N.FirstToken<ImplementationAt;
      S.UnitName:=UnitName; S.SourceHash:=FGraph.SourceHashes[N.Location.Source]; S.Variant:=Variant;
      OwnerIndex:=ParentSymbol(AFile,IR,N.Parent); S.Owner:=OwnerIndex; S.Name:=N.Name;
      if I=0 then begin S.Kind:='unit'; S.TypeName:=N.Kind; S.QualifiedName:=UnitName; end
      else if (N.Parent=0) and MatchText(N.Kind,['block','initialization','finalization']) then begin
        S.Kind:='routine'; S.Name:='$'+N.Kind;
        if N.Kind='block' then begin S.Name:='$entry'; if IR.Nodes[0].Kind='unit' then S.Name:='$initialization'; end;
        S.QualifiedName:=UnitName+'.'+S.Name; S.Signature:='():'; S.Exported:=False;
        S.HasBody:=True; S.BodyNode:=I; S.Dispatch:='direct';
      end
      else if N.Kind='type' then
      begin
        S.Kind:='type'; S.QualifiedName:=UnitName+'.'+N.Name;
        if OwnerIndex>=0 then S.QualifiedName:=FGraph.Symbols[OwnerIndex].QualifiedName+'.'+N.Name;
        J:=N.FirstToken; while (J<=N.LastToken) and (Tokens[J].Text<>'=') do Inc(J);
        if J<N.LastToken then begin
          S.TypeName:=LowerCase(Tokens[J+1].Text);
          if (Tokens[J+1].Kind=tkIdentifier) and not MatchText(S.TypeName,['class','record','interface','dispinterface','object','type','array','set','procedure','function','reference','packed']) then begin
            S.TypeName:=''; K:=J+1;
            while (K<=N.LastToken) and (Tokens[K].Text<>';') do begin S.TypeName:=S.TypeName+LowerCase(Tokens[K].Text); Inc(K); end;
          end;
        end;
      end
      else
      begin
        S.Kind:='routine'; S.QualifiedName:=UnitName+'.'+N.Name;
        if OwnerIndex>=0 then
        begin
          Owner:=FGraph.Symbols[OwnerIndex];
          if Owner.Kind='type' then
          begin
            S.OwnerName:=Owner.Name;
            Visibility:='public';
            for K:=IR.Nodes[Owner.NodeIndex].FirstToken to N.FirstToken-1 do
              if MatchText(Tokens[K].Text,['private','protected','public','published','automated']) then Visibility:=LowerCase(Tokens[K].Text);
            S.Exported:=S.Exported and not MatchText(Visibility,['private','protected']);
            if not N.Name.Contains('.') then begin S.QualifiedName:=Owner.QualifiedName+'.'+N.Name; S.Name:=Owner.Name+'.'+N.Name; end;
          end
          else if Owner.Kind<>'unit' then S.QualifiedName:=Owner.QualifiedName+'.'+N.Name;
        end;
        if N.Name.Contains('.') then S.OwnerName:=Copy(N.Name,1,LastDelimiter('.',N.Name)-1);
        if N.Kind.StartsWith('anonymous_') then
        begin
          S.Kind:='anonymous'; if not Anon.TryGetValue(OwnerIndex,Ordinal) then Ordinal:=0;
          Anon.AddOrSetValue(OwnerIndex,Ordinal+1); S.Name:='$callback'+IntToStr(Ordinal);
          if OwnerIndex>=0 then S.QualifiedName:=FGraph.Symbols[OwnerIndex].QualifiedName+'.'+S.Name;
        end;
        Header(S,Tokens,N.FirstToken,N.LastToken);
        for J:=I+1 to IR.Nodes.Count-1 do
        begin Child:=IR.Nodes[J]; if (Child.Parent=I) and (Child.Kind='block') then begin S.HasBody:=True; S.BodyNode:=J; Break; end; end;
      end;
      Index:=AddSymbol(S); FNodeSymbols.AddOrSetValue(NodeKey(AFile,I),Index);
    end;
    for I:=0 to IR.Nodes.Count-1 do
    begin
      N:=IR.Nodes[I]; if not N.Kind.StartsWith('statement_') then Continue;
      OwnerIndex:=ParentSymbol(AFile,IR,N.Parent);
      if (OwnerIndex>=0) and (FGraph.Symbols[OwnerIndex].Kind='unit') then
      begin
        FGraph.Complete:=False;
        FGraph.Diagnostics.Report('MODULE_CODE_PARTIAL','Executable module entry/initialization/finalization is outside per-routine semantic coverage',N.Location);
        Break;
      end;
    end;
  finally Anon.Free; end;
end;

procedure TDPHSemanticAnalyzer.Variables(const AFile: string; IR: TDPHParseResult);
var N: TDPHIRNode; S,Routine: TDPHSymbol; Tokens: TDPHTokens; I,J,K,Colon,Owner,Index,TypeIndex,Depth: Integer;
    Name,TypeName: string; Names: TList<string>;
  procedure VariableSymbol(const VName,VType,VKind: string; VOwner: Integer; const Location: TDPHRange);
  var V: TDPHSymbol;
  begin
    if VOwner<0 then Exit;
    V:=TDPHSymbol.Create; V.Name:=VName; V.TypeName:=VType; V.Kind:=VKind; V.Owner:=VOwner;
    V.UnitName:=FGraph.Symbols[VOwner].UnitName; V.QualifiedName:=FGraph.Symbols[VOwner].QualifiedName+'.'+VName;
    V.Variant:=FGraph.Symbols[VOwner].Variant; V.Location:=Location; V.SourceHash:=FGraph.SourceHashes[Location.Source];
    AddSymbol(V);
  end;
begin
  Tokens:=FTokens[AFile]; Names:=TList<string>.Create;
  try
    for I:=0 to IR.Nodes.Count-1 do
    begin
      N:=IR.Nodes[I];
      if FNodeSymbols.TryGetValue(NodeKey(AFile,I),Index) and
        MatchText(FGraph.Symbols[Index].Kind,['routine','anonymous']) then
      begin
        Routine:=FGraph.Symbols[Index];
        for K:=0 to High(Routine.ParameterNames) do VariableSymbol(Routine.ParameterNames[K],Routine.ParameterTypes[K],'parameter',Index,N.Location);
        if Routine.TypeName<>'' then VariableSymbol('Result',Routine.TypeName,'local',Index,N.Location);
      end;
      if not MatchText(N.Kind,['field','property','declaration_var','declaration_threadvar']) then Continue;
      Owner:=ParentSymbol(AFile,IR,N.Parent); if Owner<0 then Continue; Names.Clear;
      Colon:=N.FirstToken; Depth:=0;
      while Colon<=N.LastToken do begin
        if MatchText(Tokens[Colon].Text,['[','(']) then Inc(Depth) else if MatchText(Tokens[Colon].Text,[']',')']) then Dec(Depth);
        if (Depth=0) and (Tokens[Colon].Text=':') then Break; Inc(Colon);
      end;
      if Colon>N.LastToken then Continue;
      if N.Kind='property' then Names.Add(N.Name)
      else for J:=N.FirstToken to Colon-1 do if (Tokens[J].Kind=tkIdentifier) and not SameText(Tokens[J].Text,'property') then Names.Add(Tokens[J].Text);
      TypeName:=''; J:=Colon+1;
      while (J<=N.LastToken) and not MatchText(Tokens[J].Text,[';','=','read','write','default','stored']) do
      begin TypeName:=TypeName+Tokens[J].Text; Inc(J); end;
      for Name in Names do
      begin
        if N.Kind='field' then VariableSymbol(Name,TypeName,'field',Owner,N.Location)
        else if N.Kind='property' then VariableSymbol(Name,TypeName,'property',Owner,N.Location)
        else if FGraph.Symbols[Owner].Kind='unit' then VariableSymbol(Name,TypeName,'variable',Owner,N.Location)
        else VariableSymbol(Name,TypeName,'local',Owner,N.Location);
      end;
    end;
  finally Names.Free; end;
end;

procedure TDPHSemanticAnalyzer.PropertyAccessors(const AFile: string; IR: TDPHParseResult);
var N: TDPHIRNode; Tokens: TDPHTokens; Owner,PropertyIndex,Target,J: Integer;
    Items: TList<Integer>; Found: TArray<Integer>; Kind,Name: string;
begin
  Tokens:=FTokens[AFile];
  for N in IR.Nodes do if N.Kind='property' then begin
    Owner:=ParentSymbol(AFile,IR,N.Parent); if Owner<0 then Continue;
    if not FNames.TryGetValue(LowerCase(FGraph.Symbols[Owner].QualifiedName+'.'+N.Name),Items) or (Items.Count<>1) then Continue;
    PropertyIndex:=Items[0];
    for J:=N.FirstToken to N.LastToken-1 do if MatchText(Tokens[J].Text,['read','write']) then begin
      Kind:='read_accessor'; if SameText(Tokens[J].Text,'write') then Kind:='write_accessor'; Name:=Tokens[J+1].Text;
      Found:=Candidates(Name,Owner); Target:=-1;
      if Length(Found)=1 then Target:=Found[0]
      else if Length(Found)=0 then Target:=FindVariable(Name,Owner);
      if Target>=0 then FGraph.AddRelation(PropertyIndex,Target,Kind,'confirmed_static','declared_property_accessor',Name,Tokens[J+1].Location,N.Condition)
      else begin
        FGraph.AddRelation(PropertyIndex,-1,Kind,'unresolved','property_accessor_ambiguous_or_missing',Name,Tokens[J+1].Location,N.Condition);
        FGraph.Diagnostics.Report('PROPERTY_ACCESSOR_UNRESOLVED',Name,Tokens[J+1].Location);
      end;
    end;
  end;
end;

procedure TDPHSemanticAnalyzer.ModulePhases;
var Root,Module,Entry,Phase,Index: Integer; RootSymbol,ModuleSymbol: TDPHSymbol;
    Queue: TQueue<Integer>; Seen: TDictionary<Integer,Boolean>; Items: TList<Integer>; Imports: TList<string>; Name: string;
begin
  Queue:=TQueue<Integer>.Create; Seen:=TDictionary<Integer,Boolean>.Create;
  try
    for Root:=0 to FGraph.Symbols.Count-1 do begin
      RootSymbol:=FGraph.Symbols[Root];
      if (RootSymbol.Kind<>'unit') or not MatchText(RootSymbol.TypeName,['program','library','package']) then Continue;
      Entry:=-1;
      if FNames.TryGetValue(LowerCase(RootSymbol.QualifiedName+'.$entry'),Items) and (Items.Count=1) then begin
        Entry:=Items[0]; FGraph.AddRelation(Root,Entry,'enters','confirmed_static','declared_module_entry','Program/library body',FGraph.Symbols[Entry].Location,'');
      end;
      Seen.Clear; Queue.Clear; Queue.Enqueue(Root);
      while Queue.Count>0 do begin
        Module:=Queue.Dequeue; if Seen.ContainsKey(Module) then Continue; Seen.Add(Module,True); ModuleSymbol:=FGraph.Symbols[Module];
        if FNames.TryGetValue(LowerCase(ModuleSymbol.QualifiedName+'.$initialization'),Items) and (Items.Count=1) then begin
          Phase:=Items[0]; FGraph.AddRelation(Root,Phase,'initializes','inferred','reachable_unit_initialization_not_total_runtime_order',ModuleSymbol.QualifiedName,FGraph.Symbols[Phase].Location,'');
        end;
        if FNames.TryGetValue(LowerCase(ModuleSymbol.QualifiedName+'.$finalization'),Items) and (Items.Count=1) then begin
          Phase:=Items[0]; Index:=Root; if Entry>=0 then Index:=Entry;
          FGraph.AddRelation(Index,Phase,'finalizes','inferred','reachable_unit_finalization_not_runtime_completion',ModuleSymbol.QualifiedName,FGraph.Symbols[Phase].Location,'');
        end;
        if FImports.TryGetValue(LowerCase(ModuleSymbol.UnitName),Imports) then
          for Name in Imports do if FNames.TryGetValue(LowerCase(Name),Items) then
            for Index in Items do if FGraph.Symbols[Index].Kind='unit' then Queue.Enqueue(Index);
      end;
    end;
  finally Seen.Free; Queue.Free; end;
end;

procedure TDPHSemanticAnalyzer.Dependencies(const AFile: string; IR: TDPHParseResult);
var N: TDPHIRNode; Tokens: TDPHTokens; I,J,FromIndex,Target,BaseOrdinal: Integer; Items: TList<Integer>; Name,Kind,Resolution: string;
begin
  Tokens:=FTokens[AFile];
  for I:=0 to IR.Nodes.Count-1 do
  begin
    N:=IR.Nodes[I];
    if N.Kind='unit_reference' then
    begin
      FromIndex:=ParentSymbol(AFile,IR,N.Parent); Target:=-1;
      if FNames.TryGetValue(LowerCase(N.Name),Items) then for J in Items do if FGraph.Symbols[J].Kind='unit' then Target:=J;
      Resolution:='confirmed_static'; if Target<0 then Resolution:='unresolved';
      if FromIndex>=0 then FGraph.AddRelation(FromIndex,Target,'imports',Resolution,'uses_dependency_only',N.Name,N.Location,N.Condition);
    end;
    if (N.Kind<>'type') or not FNodeSymbols.TryGetValue(NodeKey(AFile,I),FromIndex) then Continue;
    J:=N.FirstToken; while (J<=N.LastToken) and (Tokens[J].Text<>'=') do Inc(J); Inc(J);
    if (J>N.LastToken) or not MatchText(Tokens[J].Text,['class','interface','object']) then Continue;
    Inc(J); if (J>N.LastToken) or (Tokens[J].Text<>'(') then Continue; Inc(J); BaseOrdinal:=0;
    while (J<=N.LastToken) and (Tokens[J].Text<>')') do
    begin
      Name:=''; while (J<=N.LastToken) and ((Tokens[J].Kind=tkIdentifier) or (Tokens[J].Text='.')) do begin Name:=Name+Tokens[J].Text; Inc(J); end;
      if Name='' then Break; Target:=FindType(Name,FGraph.Symbols[FromIndex].UnitName);
      Kind:='inherits'; if (BaseOrdinal>0) or ((Target>=0) and (FGraph.Symbols[Target].TypeName='interface')) then Kind:='implements';
      Resolution:='confirmed_static'; if Target<0 then Resolution:='unresolved';
      FGraph.AddRelation(FromIndex,Target,Kind,Resolution,'declared_type_ancestor',Name,N.Location,N.Condition);
      if (Kind='inherits') and (Target>=0) then FBaseTypes.AddOrSetValue(FromIndex,Target);
      Inc(BaseOrdinal); if (J<=N.LastToken) and (Tokens[J].Text=',') then Inc(J) else Break;
    end;
  end;
end;

procedure TDPHSemanticAnalyzer.BindForms(const AFile: string; IR: TDPHParseResult);
var I,Root,Owner,Target,Index: Integer; N,RootNode,Component: TDPHIRNode; S: TDPHSymbol; List: TList<Integer>; CandidatesFound: TList<Integer>; Resolution,ClassName,Name: string;
begin
  CandidatesFound:=TList<Integer>.Create;
  try
    for I:=0 to IR.Nodes.Count-1 do
    begin
      N:=IR.Nodes[I]; if not MatchText(N.Kind,['object','inherited','inline','event_binding']) then Continue;
      Owner:=ParentSymbol(AFile,IR,N.Parent); S:=TDPHSymbol.Create;
      S.Kind:='component'; if N.Kind='event_binding' then S.Kind:='event';
      S.Name:=N.Name; S.QualifiedName:=AFile+'.'+N.Name;
      if Owner>=0 then S.QualifiedName:=FGraph.Symbols[Owner].QualifiedName+'.'+N.Name;
      S.TypeName:=N.Value; S.Location:=N.Location; S.SourceHash:=FGraph.SourceHashes[AFile]; S.Variant:=FGraph.Configuration; S.Owner:=Owner;
      Index:=AddSymbol(S); FNodeSymbols.AddOrSetValue(NodeKey(AFile,I),Index);
      if N.Kind<>'event_binding' then Continue;
      Root:=I; while IR.Nodes[Root].Parent>=0 do Root:=IR.Nodes[Root].Parent;
      RootNode:=IR.Nodes[Root]; ClassName:=RootNode.Value; CandidatesFound.Clear;
      for Target:=0 to FGraph.Symbols.Count-1 do
      begin
        S:=FGraph.Symbols[Target];
        if (S.Kind='routine') and SameText(S.Name,ClassName+'.'+N.Value) and
          SameText(ChangeFileExt(S.Location.Source,''),ChangeFileExt(AFile,'')) then CandidatesFound.Add(Target);
      end;
      Target:=-1; Resolution:='unresolved'; if CandidatesFound.Count=1 then begin Target:=CandidatesFound[0]; Resolution:='confirmed_static'; end;
      FGraph.AddRelation(Index,Target,'binds',Resolution,'serialized_event_own_form_method',ClassName+'.'+N.Value,N.Location,N.Condition);
      if Target<0 then FGraph.Diagnostics.Report('EVENT_TARGET_UNRESOLVED',N.Value,N.Location);
    end;
  finally CandidatesFound.Free; end;
end;

procedure TDPHSemanticAnalyzer.TestCoverage;
var S: TDPHSymbol; Imports: TList<string>; Tokens: TDPHTokens; L: TDPHRange;
    I,J,Count: Integer; DeclaredTest,UsesDUnitX: Boolean; R: TDPHRelation; ImportName: string;
begin
  Count:=FGraph.Relations.Count;
  for S in FGraph.Symbols do begin
    if not S.HasBody or not FImports.TryGetValue(LowerCase(S.UnitName),Imports) then Continue;
    UsesDUnitX:=False; for ImportName in Imports do if SameText(ImportName,'DUnitX.TestFramework') then UsesDUnitX:=True;
    DeclaredTest:=False;
    for L in S.Occurrences do begin
      if not FTokens.TryGetValue(L.Source,Tokens) then Continue;
      for I:=3 to High(Tokens) do if Tokens[I].Location.StartByte=L.StartByte then begin
        J:=I-1;
        if (Tokens[J].Text=']') and SameText(Tokens[J-1].Text,'Test') and (Tokens[J-2].Text='[') and
          UsesDUnitX then DeclaredTest:=True;
        Break;
      end;
    end;
    if not DeclaredTest then Continue;
    for I:=0 to Count-1 do begin R:=FGraph.Relations[I];
      if (R.FromSymbol=S.Index) and (R.Kind='calls') and (R.ToSymbol>=0) then
        FGraph.AddRelation(S.Index,R.ToSymbol,'test_covers','inferred','declared_dunitx_test_static_call_not_assertion_or_run_proof',R.LabelText,R.Location,R.Condition);
    end;
  end;
end;

procedure TDPHSemanticAnalyzer.RoutineFacts(ARoutine: Integer; IR: TDPHParseResult; const Tokens: TDPHTokens);
var Routine,S: TDPHSymbol; Body,N: TDPHIRNode; I,J,K,Stop,Depth,Next,Variable,Target,Child,CallEnd: Integer;
    Path,Resolution,Kind,Argument,TypeName: string; Args: TList<string>; Matches: TArray<Integer>; L: TDPHRange;
    IsCall,IsWrite,WithinWith,LiteralSQL: Boolean; Flow: TDPHFlowBuilder;
    InputIndex,ExpressionEnd,InputStop,InputSymbol: Integer; InputPath,SQLText: string;
    Nested: TDictionary<Integer,Integer>; Closures: TList<Integer>;
    WithScopes: TList<TDPHRange>; WithRange: TDPHRange;
begin
  Routine:=FGraph.Symbols[ARoutine]; if not Routine.HasBody then Exit; Body:=IR.Nodes[Routine.BodyNode];
  Flow:=TDPHFlowBuilder.Create;
  try Flow.Build(FGraph,ARoutine,IR,Tokens,Routine.BodyNode); finally Flow.Free; end;
  Args:=TList<string>.Create;
  Nested:=TDictionary<Integer,Integer>.Create; Closures:=TList<Integer>.Create;
  WithScopes:=TList<TDPHRange>.Create;
  try
    for J:=Routine.NodeIndex+1 to IR.Nodes.Count-1 do
    begin
      N:=IR.Nodes[J];
      if (N.Parent>=0) and (IR.Nodes[N.Parent].Kind='statement_with') and
        ((N.Kind='block') or N.Kind.StartsWith('statement_')) then WithScopes.Add(N.Location);
      if N.Kind.StartsWith('routine_') or N.Kind.StartsWith('anonymous_') then Nested.AddOrSetValue(N.FirstToken,N.LastToken+1);
      if N.Kind.StartsWith('anonymous_') and (ParentSymbol(Routine.Location.Source,IR,N.Parent)=ARoutine) then Closures.Add(J);
    end;
    I:=Body.FirstToken+1;
    while I<Body.LastToken do
    begin
      // Nested and anonymous bodies are analyzed under their own routine identity.
      Next:=I;
      Nested.TryGetValue(I,Next); if Next=0 then Next:=I;
      if Next<>I then begin I:=Next; Continue; end;
      if Tokens[I].Kind<>tkIdentifier then begin Inc(I); Continue; end;
      if SameText(Tokens[I].Text,'raise') or SameText(Tokens[I].Text,'on') then begin
        J:=I+1; Kind:='raises'; if SameText(Tokens[I].Text,'on') then begin
          Kind:='catches'; if (J+1<=Body.LastToken) and (Tokens[J+1].Text=':') then Inc(J,2);
        end;
        InputPath:='';
        if (J<=Body.LastToken) and (Tokens[J].Kind=tkIdentifier) and not MatchText(Tokens[J].Text,['end','else','do']) then begin
          InputPath:=Tokens[J].Text;
          while (J+2<=Body.LastToken) and (Tokens[J+1].Text='.') and (Tokens[J+2].Kind=tkIdentifier) do begin Inc(J,2); InputPath:=InputPath+'.'+Tokens[J].Text; end;
        end;
        if EndsText('.Create',InputPath) then Delete(InputPath,Length(InputPath)-6,7);
        InputSymbol:=FindType(InputPath,Routine.UnitName);
        if (InputSymbol<0) and (Kind='raises') then begin
          InputIndex:=ResolveValue(InputPath,ARoutine); if InputIndex>=0 then InputSymbol:=FindType(FGraph.Symbols[InputIndex].TypeName,Routine.UnitName);
        end;
        Resolution:='inferred'; if InputSymbol<0 then Resolution:='unresolved';
        L:=Tokens[I].Location;
        if (J<=Body.LastToken) and (Tokens[J].Location.Source=L.Source) then L.EndByte:=Tokens[J].Location.EndByte;
        FGraph.AddRelation(ARoutine,InputSymbol,Kind,Resolution,'exception_type_syntax_not_runtime_handler_match',InputPath,L,Tokens[I].Condition);
        if InputSymbol<0 then FGraph.Diagnostics.Report('EXCEPTION_TYPE_PARTIAL','Exception/rethrow type or handler match requires review',Tokens[I].Location);
      end;
      if MatchText(Tokens[I].Text,['begin','end','if','then','else','while','with','goto','do','for','to','downto','in','repeat','until','try','except','finally','on','raise','case','of','var','const','not','and','or','xor','div','mod','is','as','nil','true','false','exit','break','continue','inherited']) or
        ((I<Body.LastToken) and (Tokens[I+1].Text=':')) or ((I>Body.FirstToken) and SameText(Tokens[I-1].Text,'goto')) then begin Inc(I); Continue; end;
      WithinWith:=False;
      for WithRange in WithScopes do if (WithRange.Source=Tokens[I].Location.Source) and
        (WithRange.StartByte<=Tokens[I].Location.StartByte) and (WithRange.EndByte>=Tokens[I].Location.EndByte) then begin WithinWith:=True; Break; end;
      Path:=Tokens[I].Text; Stop:=I;
      while (Stop+2<=Body.LastToken) and (Tokens[Stop+1].Text='.') and (Tokens[Stop+2].Kind=tkIdentifier) do begin Inc(Stop,2); Path:=Path+'.'+Tokens[Stop].Text; end;
      if (I>Body.FirstToken) and SameText(Tokens[I-1].Text,'inherited') then Path:='inherited.'+Path;
      L:=Tokens[I].Location; if Tokens[Stop].Location.Source=L.Source then L.EndByte:=Tokens[Stop].Location.EndByte;
      IsCall:=(Stop+1<=Body.LastToken) and (Tokens[Stop+1].Text='('); CallEnd:=Stop;
      Args.Clear;
      if IsCall then
      begin
        J:=Stop+2; Depth:=0; Argument:='';
        while J<=Body.LastToken do
        begin
          if (Tokens[J].Text=')') and (Depth=0) then begin if Argument<>'' then Args.Add(Argument); Break; end;
          if (Tokens[J].Text=',') and (Depth=0) then begin Args.Add(Argument); Argument:=''; end
          else
          begin
            if MatchText(Tokens[J].Text,['(','[']) then Inc(Depth) else if MatchText(Tokens[J].Text,[')',']']) then Dec(Depth);
            Argument:=Argument+Tokens[J].Text;
          end;
          Inc(J);
        end;
        CallEnd:=J;
      end;
      if not IsCall and (Stop+1<=Body.LastToken) and MatchText(Tokens[Stop+1].Text,[';','end','else','until']) and
        ((I=Body.FirstToken+1) or MatchText(Tokens[I-1].Text,[';','begin','then','else','do',':','inherited'])) then IsCall:=True;
      if not IsCall and EndsText('.Create',Path) and (Stop+1<=Body.LastToken) and
        MatchText(Tokens[Stop+1].Text,[';','end','else','until']) and
        (FindType(Copy(Path,1,Length(Path)-7),Routine.UnitName)>=0) then IsCall:=True;
      if IsCall and EndsText('.Create',Path) then begin
        InputSymbol:=FindType(Copy(Path,1,Length(Path)-7),Routine.UnitName);
        if InputSymbol>=0 then FGraph.AddRelation(ARoutine,InputSymbol,'creates','inferred','declared_type_create_spelling_allocation_and_ownership_unverified',Path,L,Tokens[I].Condition);
      end;
      if IsCall and (EndsText('.Free',Path) or EndsText('.Destroy',Path) or SameText(Path,'FreeAndNil')) then begin
        InputSymbol:=-1;
        if SameText(Path,'FreeAndNil') then begin if Args.Count=1 then InputSymbol:=ResolveValue(Args[0],ARoutine); end
        else InputSymbol:=ResolveValue(Copy(Path,1,LastDelimiter('.',Path)-1),ARoutine);
        if InputSymbol>=0 then FGraph.AddRelation(ARoutine,InputSymbol,'destroys','possible_dynamic','lifetime_action_spelling_not_success_or_alias_proof',Path,L,Tokens[I].Condition);
      end;
      if IsCall and not MatchText(Path,['Assigned','Default','Length','SetLength','High','Low','Ord','Chr','Inc','Dec','SizeOf','New','Dispose','Include','Exclude']) and (FindType(Path,Routine.UnitName)<0) then
      begin
        Matches:=SelectCall(Path,ARoutine,Args.ToArray);
        Resolution:='confirmed_static'; if (Length(Matches)<>1) or not FCallExact then Resolution:='possible_dynamic';
        if Length(Matches)=0 then
        begin
          Variable:=ResolveValue(Path,ARoutine); Resolution:='unresolved';
          if Variable>=0 then Resolution:='possible_dynamic';
          FGraph.AddRelation(ARoutine,Variable,'calls',Resolution,'unresolved_or_procedural_receiver',Path,L,Tokens[I].Condition);
          FGraph.Diagnostics.Report('CALL_TARGET_UNRESOLVED',Path,L);
        end
        else for Target in Matches do
        begin
          S:=FGraph.Symbols[Target]; if S.Dispatch='dynamic' then Resolution:='possible_dynamic';
          if StartsText('inherited.',Path) then Resolution:='confirmed_static';
          if WithinWith and not Path.Contains('.') then Resolution:='possible_dynamic';
          if (S.Owner>=0) and SameText(FGraph.Symbols[S.Owner].TypeName,'interface') then Resolution:='possible_dynamic';
          FGraph.AddRelation(ARoutine,Target,'calls',Resolution,'lexical_scope_declared_receiver_and_signature',Path,L,Tokens[I].Condition);
          if MatchText(S.Name.Substring(LastDelimiter('.',S.Name)),['Render','RenderBody','Save']) and (Args.Count>0) then
          begin
            Variable:=ResolveValue(Args[0],ARoutine);
            if (Variable>=0) and (Length(S.ParameterTypes)>0) and SameText(FGraph.Symbols[Variable].TypeName,S.ParameterTypes[0]) and
              S.ClassMethod then FGraph.AddRelation(ARoutine,Variable,'renders','inferred','typed_model_passed_to_resolved_renderer',S.QualifiedName,L,Tokens[I].Condition);
          end;
        end;
        // Closure arguments are facts; scheduling is possible, never a synchronous call to the closure.
        for J in Closures do
        begin
          N:=IR.Nodes[J]; if not N.Kind.StartsWith('anonymous_') or (N.FirstToken<=Stop) or (N.LastToken>CallEnd) then Continue;
          if not FNodeSymbols.TryGetValue(NodeKey(Routine.Location.Source,J),Child) then Continue;
          FGraph.AddRelation(ARoutine,Child,'passes_callback','confirmed_static','anonymous_argument',Path,N.Location,N.Condition);
          if MatchText(Path,['TThread.CreateAnonymousThread','TThread.Queue','TThread.ForceQueue','TThread.Synchronize','TTask.Run']) then
            FGraph.AddRelation(ARoutine,Child,'schedules','possible_dynamic','recognized_async_api_spelling_not_runtime_observation',Path,L,Tokens[I].Condition);
        end;
        if MatchText(Path,['TThread.CreateAnonymousThread','TThread.Queue','TThread.ForceQueue','TThread.Synchronize','TTask.Run']) and (Args.Count>0) then begin
          Argument:=Args[Args.Count-1]; if Argument.StartsWith('@') then Delete(Argument,1,1);
          Matches:=Candidates(Argument,ARoutine);
          if (Length(Matches)=1) and (Length(FGraph.Symbols[Matches[0]].ParameterTypes)=0) then begin
            Child:=Matches[0]; FGraph.AddRelation(ARoutine,Child,'passes_callback','inferred','named_async_callback_candidate',Path,L,Tokens[I].Condition);
            FGraph.AddRelation(ARoutine,Child,'schedules','possible_dynamic','recognized_async_api_spelling_not_runtime_observation',Path,L,Tokens[I].Condition);
          end;
        end;
      end;
      Variable:=ResolveValue(Path,ARoutine);
      if (Variable>=0) and (FGraph.Symbols[Variable].Kind<>'type') then
      begin
        IsWrite:=(Stop+1<=Body.LastToken) and (Tokens[Stop+1].Text=':='); Kind:='reads'; if IsWrite then Kind:='writes';
        Resolution:='confirmed_static'; if FGraph.Symbols[Variable].Kind='property' then Resolution:='inferred';
        if WithinWith and not Path.Contains('.') then Resolution:='possible_dynamic';
        FGraph.AddRelation(ARoutine,Variable,Kind,Resolution,'lexical_def_use_not_runtime_value',Path,L,Tokens[I].Condition);
        if IsWrite then begin
          ExpressionEnd:=Stop+2; Depth:=0;
          while ExpressionEnd<=Body.LastToken do begin
            if (Depth=0) and MatchText(Tokens[ExpressionEnd].Text,[';','end','else','until']) then Break;
            if MatchText(Tokens[ExpressionEnd].Text,['(','[']) then Inc(Depth)
            else if MatchText(Tokens[ExpressionEnd].Text,[')',']']) then begin if Depth=0 then Break; Dec(Depth); end;
            Inc(ExpressionEnd);
          end;
          InputIndex:=Stop+2;
          while InputIndex<ExpressionEnd do begin
            if Nested.TryGetValue(InputIndex,Next) then begin InputIndex:=Next; Continue; end;
            if Tokens[InputIndex].Kind<>tkIdentifier then begin Inc(InputIndex); Continue; end;
            InputPath:=Tokens[InputIndex].Text; InputStop:=InputIndex;
            while (InputStop+2<ExpressionEnd) and (Tokens[InputStop+1].Text='.') and (Tokens[InputStop+2].Kind=tkIdentifier) do begin
              Inc(InputStop,2); InputPath:=InputPath+'.'+Tokens[InputStop].Text;
            end;
            InputSymbol:=ResolveValue(InputPath,ARoutine);
            if (InputSymbol>=0) and not (WithinWith and not InputPath.Contains('.')) and MatchText(FGraph.Symbols[InputSymbol].Kind,['local','parameter','variable','field','property']) then
              FGraph.AddRelation(Variable,InputSymbol,'derives_from','inferred','lexical_assignment_input_not_reaching_definition_or_runtime_value',Path+' := ... '+InputPath,Tokens[InputIndex].Location,Tokens[I].Condition);
            InputIndex:=InputStop+1;
          end;
        end;
        if IsWrite and (Stop+2<=Body.LastToken) then
        begin
          Argument:=Tokens[Stop+2].Text;
          if (Argument='@') and (Stop+3<=Body.LastToken) then Argument:=Tokens[Stop+3].Text;
          Matches:=Candidates(Argument,ARoutine);
          for Target in Matches do FGraph.AddRelation(Variable,Target,'assigns_callback','inferred','procedure_reference_assignment',Argument,L,Tokens[I].Condition);
        end;
      end
      else if not IsCall and (Stop+1<=Body.LastToken) and (Tokens[Stop+1].Text=':=') then
        FGraph.AddRelation(ARoutine,-1,'writes','unresolved','unresolved_assignment_target',Path,L,Tokens[I].Condition)
      else if not IsCall and (FindType(Path,Routine.UnitName)<0) and (Length(Candidates(Path,ARoutine))=0) then
      begin
        FGraph.AddRelation(ARoutine,-1,'reads','unresolved','unresolved_identifier_access',Path,L,Tokens[I].Condition);
        FGraph.Diagnostics.Report('READ_TARGET_UNRESOLVED',Path,L);
      end;
      if (Stop+1<=Body.LastToken) and (Tokens[Stop+1].Text=':=') and EndsText('.SQL.Text',Path) then begin
        SQLText:=''; LiteralSQL:=True; J:=Stop+2;
        while (J<=Body.LastToken) and (Tokens[J].Text<>';') do begin
          if Tokens[J].Kind=tkString then SQLText:=SQLText+Copy(Tokens[J].Text,2,Length(Tokens[J].Text)-2).Replace('''''','''')
          else if Tokens[J].Text<>'+' then LiteralSQL:=False;
          Inc(J);
        end;
        Kind:='dynamic_sql'; if LiteralSQL and (SQLText<>'') then Kind:='static_sql';
        InputSymbol:=ResolveValue(Copy(Path,1,Length(Path)-9),ARoutine);
        FGraph.AddRelation(ARoutine,InputSymbol,Kind,'inferred','sql_text_assignment_spelling_component_unverified',SQLText,L,Tokens[I].Condition);
        if Kind='dynamic_sql' then FGraph.Diagnostics.Report('SQL_DYNAMIC','SQL.Text contains nonliteral inputs; SQL schema usage is not inferred',L);
      end;
      if SameText(Path,'Inc') or SameText(Path,'Dec') then
        if Args.Count=1 then
        begin Variable:=ResolveValue(Args[0],ARoutine); FGraph.AddRelation(ARoutine,Variable,'writes','inferred','intrinsic_update',Args[0],L,Tokens[I].Condition); end;
      if EndsText('.ExecSQL',Path) and (Args.Count=1) and (Stop+3=CallEnd) and
        (Tokens[Stop+2].Kind=tkString) then begin
        InputSymbol:=ResolveValue(Copy(Path,1,Length(Path)-8),ARoutine);
        FGraph.AddRelation(ARoutine,InputSymbol,'static_sql','inferred','literal_argument_to_execsql_spelling_api_unverified',Args[0],L,Tokens[I].Condition);
      end;
      I:=Stop+1;
    end;
    if not IR.Complete then FGraph.Diagnostics.Report('ROUTINE_PARTIAL_PARSE','Routine facts derived from partial syntax; coverage is not complete',Routine.Location);
  finally WithScopes.Free; Closures.Free; Nested.Free; Args.Free; end;
end;

function TDPHSemanticAnalyzer.Analyze(AScan: TDPHScan; AIncremental: Boolean): TDPHSemanticGraph;
var Item: TDPHManifestFile; IR: TDPHParseResult; T: TDPHToken; Tokens: TList<TDPHToken>;
    S: TDPHSymbol; I,TypeIndex,Consumer,Resource: Integer; SymbolsBefore: Integer; Reference: TDPHDefinitionReference;
    BindingHash: THashSHA2; BindingIdentity: string; Import: TPair<string,TList<string>>; BindingRelation: TDPHRelation;
begin
  FReusedRoutines:=0; FRecomputedRoutines:=0;
  if not AIncremental then begin FRoutineCache.Clear; FCacheWeight:=0; end;
  FScan:=AScan; FGraph:=TDPHSemanticGraph.Create; FGraph.Complete:=AScan.Complete;
  FGraph.Diagnostics.AddRange(AScan.Inventory.Diagnostics);
  FGraph.Fingerprint:=TDPHKnowledgeStore.ManifestHash(AScan.Inventory.Manifest);
  FGraph.Configuration:=AScan.Inventory.ConfigurationIdentity;
  FGraph.ContextHash:=AScan.ContextHash;
  FNodeSymbols:=TDictionary<string,Integer>.Create; FKeys:=TDictionary<string,Integer>.Create;
  FBaseTypes:=TDictionary<Integer,Integer>.Create;
  FNames:=TObjectDictionary<string,TList<Integer>>.Create([doOwnsValues]); FTokens:=TDictionary<string,TDPHTokens>.Create;
  FImports:=TObjectDictionary<string,TList<string>>.Create([doOwnsValues]); Tokens:=TList<TDPHToken>.Create;
  try
    try
      for Item in AScan.Inventory.Manifest do if Item.Availability='available' then FGraph.SourceHashes.Add(Item.RelativePath,Item.SHA256);
      for Item in AScan.Inventory.Manifest do if AScan.Results.TryGetValue(Item.RelativePath,IR) then
      begin
        Tokens.Clear; for T in IR.Tokens do if not (T.Kind in [tkSpace,tkComment,tkDirective]) and (T.Active=daActive) then Tokens.Add(T);
        FTokens.Add(Item.RelativePath,Tokens.ToArray); Collect(Item.RelativePath,IR);
      end;
      for Item in AScan.Inventory.Manifest do if AScan.Results.TryGetValue(Item.RelativePath,IR) and (Length(FTokens[Item.RelativePath])>0) then Variables(Item.RelativePath,IR);
      for Item in AScan.Inventory.Manifest do if AScan.Results.TryGetValue(Item.RelativePath,IR) and (Length(FTokens[Item.RelativePath])>0) then PropertyAccessors(Item.RelativePath,IR);
      for Item in AScan.Inventory.Manifest do if AScan.Results.TryGetValue(Item.RelativePath,IR) and (Length(FTokens[Item.RelativePath])>0) then Dependencies(Item.RelativePath,IR);
      BindingHash:=THashSHA2.Create;
      BindingHash.Update(DPHSemanticVersion+#0+AScan.Inventory.Root+#0+FGraph.Configuration);
      for S in FGraph.Symbols do begin
        BindingHash.Update(S.Key+#0+S.TypeName+#0+S.Dispatch+#0+String.Join(';',S.ParameterTypes)+#0+IntToStr(S.MinArguments)+#0+
          BoolToStr(S.Exported,True)+#0+BoolToStr(S.ClassMethod,True)+#0+BoolToStr(S.HasBody,True)+#0+IntToStr(S.Owner));
      end;
      for Import in FImports do BindingHash.Update(Import.Key+#0+String.Join(';',Import.Value.ToArray));
      for BindingRelation in FGraph.Relations do begin
        BindingHash.Update(FGraph.Symbols[BindingRelation.FromSymbol].Key+#0+BindingRelation.Kind+#0+BindingRelation.Resolution+#0+BindingRelation.Condition);
        if BindingRelation.ToSymbol>=0 then BindingHash.Update(FGraph.Symbols[BindingRelation.ToSymbol].Key);
      end;
      for Item in AScan.Inventory.Manifest do if Item.Kind='.inc' then BindingHash.Update(Item.RelativePath+#0+Item.SHA256);
      BindingIdentity:=BindingHash.HashAsString;
      SymbolsBefore:=FGraph.Symbols.Count;
      for I:=0 to SymbolsBefore-1 do
      begin
        S:=FGraph.Symbols[I];
        if MatchText(S.Kind,['parameter','field','property','local','variable']) then
        begin TypeIndex:=FindType(S.TypeName,S.UnitName); if TypeIndex>=0 then FGraph.AddRelation(I,TypeIndex,'uses_type','confirmed_static','declared_type',S.TypeName,S.Location); end;
        if S.HasBody and AScan.Results.TryGetValue(S.Location.Source,IR) then CachedRoutineFacts(I,IR,FTokens[S.Location.Source],BindingIdentity);
      end;
      for Item in AScan.Inventory.Manifest do if MatchText(Item.Kind,['.fmx','.dfm']) and AScan.Results.TryGetValue(Item.RelativePath,IR) then BindForms(Item.RelativePath,IR);
      ModulePhases;
      TestCoverage;
      for Reference in AScan.Inventory.DefinitionReferences do begin
        Consumer:=-1; Resource:=-1;
        for I:=0 to FGraph.Symbols.Count-1 do begin S:=FGraph.Symbols[I];
          if (S.Kind='resource') and (S.Location.Source=Reference.Target) then Resource:=I;
          if S.HasBody and (S.Location.Source=Reference.Source) and (S.Location.StartByte<=Reference.Location.StartByte) and (S.Location.EndByte>=Reference.Location.EndByte) then
            if (Consumer<0) or (S.Location.EndByte-S.Location.StartByte<FGraph.Symbols[Consumer].Location.EndByte-FGraph.Symbols[Consumer].Location.StartByte) then Consumer:=I;
        end;
        if Consumer>=0 then begin
          if Resource>=0 then FGraph.AddRelation(Consumer,Resource,'reads','inferred','literal_file_loader_spelling_api_unverified',Reference.Loader+': '+Reference.Path,Reference.Location,'')
          else FGraph.AddRelation(Consumer,-1,'reads','unresolved','literal_definition_unavailable_or_opaque',Reference.Loader+': '+Reference.Path,Reference.Location,'');
          if Resource>=0 then FGraph.AddRelation(Resource,Consumer,'configures','inferred','loader_lexical_order_not_runtime_precedence',IntToStr(Reference.Order)+': '+Reference.Loader,Reference.Location,'');
        end;
      end;
      TDPHAsyncAnalysis.Enrich(AScan,FGraph);
      TDPHSQLAnalysis.Enrich(AScan,FGraph);
      Result:=FGraph; FGraph:=nil;
    except FGraph.Free; raise; end;
  finally Tokens.Free; FImports.Free; FTokens.Free; FNames.Free; FKeys.Free; FNodeSymbols.Free; FBaseTypes.Free; end;
end;
end.
