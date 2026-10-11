unit DPH.Analysis.Symbols;

interface
uses System.SysUtils, System.Generics.Collections, DPH.Parse.Model, DPH.Project.Analysis,
  DPH.Analysis.Model;
type
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
    function NodeKey(const AFile: string; ANode: Integer): string;
    function ParentSymbol(const AFile: string; IR: TDPHParseResult; ANode: Integer): Integer;
    function AddSymbol(S: TDPHSymbol): Integer;
    function FindType(const AName,AUnit: string): Integer;
    function FindVariable(const AName: string; ARoutine: Integer): Integer;
    function ResolveValue(const APath: string; ARoutine: Integer): Integer;
    function Candidates(const AName: string; ARoutine: Integer): TArray<Integer>;
    function SelectCall(const APath: string; ARoutine: Integer; const Arguments: TArray<string>): TArray<Integer>;
    function ExpressionType(const AText: string; ARoutine: Integer): string;
    procedure Header(S: TDPHSymbol; const Tokens: TDPHTokens; AStart,AEnd: Integer);
    procedure Collect(const AFile: string; IR: TDPHParseResult);
    procedure Variables(const AFile: string; IR: TDPHParseResult);
    procedure Dependencies(const AFile: string; IR: TDPHParseResult);
    procedure BindForms(const AFile: string; IR: TDPHParseResult);
    procedure RoutineFacts(ARoutine: Integer; IR: TDPHParseResult; const Tokens: TDPHTokens);
  public
    function Analyze(AScan: TDPHScan): TDPHSemanticGraph;
  end;
implementation
uses System.Classes, System.StrUtils, System.Hash, DPH.Storage.Types,
  DPH.Storage.Database, DPH.Analysis.Flow;

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

function TDPHSemanticAnalyzer.FindType(const AName,AUnit: string): Integer;
var Items: TList<Integer>; I: Integer; S: TDPHSymbol; Found: Integer; Imports: TList<string>; U: string;
begin
  Found:=-1;
  if FNames.TryGetValue(LowerCase(AUnit+'.'+AName),Items) or FNames.TryGetValue(LowerCase(AName),Items) then
    for I in Items do if FGraph.Symbols[I].Kind='type' then begin if Found>=0 then Exit(-1); Found:=I; end;
  if Found>=0 then Exit(Found);
  if FImports.TryGetValue(LowerCase(AUnit),Imports) then
    for U in Imports do if FNames.TryGetValue(LowerCase(U+'.'+AName),Items) then
      for I in Items do begin S:=FGraph.Symbols[I]; if (S.Kind='type') and S.Exported then begin if Found>=0 then Exit(-1); Found:=I; end; end;
  Result:=Found;
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
var Parts: TArray<string>; I,TypeIndex,Member: Integer; Items: TList<Integer>; U: string;
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
    if FNames.TryGetValue(LowerCase(FGraph.Symbols[TypeIndex].QualifiedName+'.'+Parts[I]),Items) then
      for Member in Items do if MatchText(FGraph.Symbols[Member].Kind,['field','property']) then begin Result:=Member; Break; end;
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
  V:=ResolveValue(AText,ARoutine); if V>=0 then Result:=LowerCase(FGraph.Symbols[V].TypeName);
end;
function TDPHSemanticAnalyzer.SelectCall(const APath: string; ARoutine: Integer; const Arguments: TArray<string>): TArray<Integer>;
var Items,Exact: TList<Integer>; Candidate,I: Integer; S: TDPHSymbol; Matches,Known: Boolean; TypeName: string;
begin
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
        if TypeName='' then Known:=False else if not SameText(TypeName,S.ParameterTypes[I]) then Matches:=False;
      end;
      if Matches then begin Items.Add(Candidate); if Known then Exact.Add(Candidate); end;
    end;
    if Exact.Count>0 then Result:=Exact.ToArray else Result:=Items.ToArray;
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
      N:=IR.Nodes[I]; if not MatchText(N.Kind,['unit','program','library','package','type']) and not N.Kind.StartsWith('routine_') and not N.Kind.StartsWith('anonymous_') then Continue;
      S:=TDPHSymbol.Create; S.Location:=N.Location; S.NodeIndex:=I; S.Condition:=N.Condition;
      S.Exported:=N.FirstToken<ImplementationAt;
      S.UnitName:=UnitName; S.SourceHash:=FGraph.SourceHashes[N.Location.Source]; S.Variant:=Variant;
      OwnerIndex:=ParentSymbol(AFile,IR,N.Parent); S.Owner:=OwnerIndex; S.Name:=N.Name;
      if I=0 then begin S.Kind:='unit'; S.QualifiedName:=UnitName; end
      else if N.Kind='type' then
      begin
        S.Kind:='type'; S.QualifiedName:=UnitName+'.'+N.Name;
        if OwnerIndex>=0 then S.QualifiedName:=FGraph.Symbols[OwnerIndex].QualifiedName+'.'+N.Name;
        J:=N.FirstToken; while (J<=N.LastToken) and (Tokens[J].Text<>'=') do Inc(J);
        if J<N.LastToken then S.TypeName:=LowerCase(Tokens[J+1].Text);
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
var N: TDPHIRNode; S,Routine: TDPHSymbol; Tokens: TDPHTokens; I,J,K,Colon,Owner,Index,TypeIndex: Integer;
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
      Colon:=N.FirstToken;
      while (Colon<=N.LastToken) and (Tokens[Colon].Text<>':') do Inc(Colon);
      if Colon>N.LastToken then Continue;
      for J:=N.FirstToken to Colon-1 do if (Tokens[J].Kind=tkIdentifier) and not SameText(Tokens[J].Text,'property') then Names.Add(Tokens[J].Text);
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

procedure TDPHSemanticAnalyzer.RoutineFacts(ARoutine: Integer; IR: TDPHParseResult; const Tokens: TDPHTokens);
var Routine,S: TDPHSymbol; Body,N: TDPHIRNode; I,J,K,Stop,Depth,Next,Variable,Target,Child,CallEnd: Integer;
    Path,Resolution,Kind,Argument,TypeName: string; Args: TList<string>; Matches: TArray<Integer>; L: TDPHRange;
    IsCall,IsWrite: Boolean; Flow: TDPHFlowBuilder;
    Nested: TDictionary<Integer,Integer>; Closures: TList<Integer>;
begin
  Routine:=FGraph.Symbols[ARoutine]; if not Routine.HasBody then Exit; Body:=IR.Nodes[Routine.BodyNode];
  Flow:=TDPHFlowBuilder.Create;
  try Flow.Build(FGraph,ARoutine,IR,Tokens,Routine.BodyNode); finally Flow.Free; end;
  Args:=TList<string>.Create;
  Nested:=TDictionary<Integer,Integer>.Create; Closures:=TList<Integer>.Create;
  try
    for J:=Routine.NodeIndex+1 to IR.Nodes.Count-1 do
    begin
      N:=IR.Nodes[J];
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
      if MatchText(Tokens[I].Text,['begin','end','if','then','else','while','do','for','to','downto','in','repeat','until','try','except','finally','on','raise','case','of','var','const','not','and','or','xor','div','mod','is','as','nil','true','false','exit','break','continue','inherited']) then begin Inc(I); Continue; end;
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
      if IsCall and not MatchText(Path,['Assigned','Default','Length','SetLength','High','Low','Ord','Chr','Inc','Dec','SizeOf','New','Dispose','Include','Exclude']) and (FindType(Path,Routine.UnitName)<0) then
      begin
        Matches:=SelectCall(Path,ARoutine,Args.ToArray);
        Resolution:='confirmed_static'; if Length(Matches)<>1 then Resolution:='possible_dynamic';
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
      end;
      Variable:=ResolveValue(Path,ARoutine);
      if (Variable>=0) and (FGraph.Symbols[Variable].Kind<>'type') then
      begin
        IsWrite:=(Stop+1<=Body.LastToken) and (Tokens[Stop+1].Text=':='); Kind:='reads'; if IsWrite then Kind:='writes';
        Resolution:='confirmed_static'; if FGraph.Symbols[Variable].Kind='property' then Resolution:='inferred';
        FGraph.AddRelation(ARoutine,Variable,Kind,Resolution,'lexical_def_use_not_runtime_value',Path,L,Tokens[I].Condition);
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
      if SameText(Path,'Inc') or SameText(Path,'Dec') then
        if Args.Count=1 then
        begin Variable:=ResolveValue(Args[0],ARoutine); FGraph.AddRelation(ARoutine,Variable,'writes','inferred','intrinsic_update',Args[0],L,Tokens[I].Condition); end;
      if EndsText('.ExecSQL',Path) and (Args.Count=1) and (Stop+3=CallEnd) and
        (Tokens[Stop+2].Kind=tkString) then
        FGraph.AddRelation(ARoutine,-1,'static_sql','inferred','literal_argument_to_execsql_spelling_api_unverified',Args[0],L,Tokens[I].Condition);
      I:=Stop+1;
    end;
    if not IR.Complete then FGraph.Diagnostics.Report('ROUTINE_PARTIAL_PARSE','Routine facts derived from partial syntax; coverage is not complete',Routine.Location);
  finally Closures.Free; Nested.Free; Args.Free; end;
end;

function TDPHSemanticAnalyzer.Analyze(AScan: TDPHScan): TDPHSemanticGraph;
var Item: TDPHManifestFile; IR: TDPHParseResult; T: TDPHToken; Tokens: TList<TDPHToken>;
    S: TDPHSymbol; I,TypeIndex: Integer; SymbolsBefore: Integer;
begin
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
      for Item in AScan.Inventory.Manifest do if AScan.Results.TryGetValue(Item.RelativePath,IR) and (Length(FTokens[Item.RelativePath])>0) then Dependencies(Item.RelativePath,IR);
      SymbolsBefore:=FGraph.Symbols.Count;
      for I:=0 to SymbolsBefore-1 do
      begin
        S:=FGraph.Symbols[I];
        if MatchText(S.Kind,['parameter','field','property','local','variable']) then
        begin TypeIndex:=FindType(S.TypeName,S.UnitName); if TypeIndex>=0 then FGraph.AddRelation(I,TypeIndex,'uses_type','confirmed_static','declared_type',S.TypeName,S.Location); end;
        if S.HasBody and AScan.Results.TryGetValue(S.Location.Source,IR) then RoutineFacts(I,IR,FTokens[S.Location.Source]);
      end;
      for Item in AScan.Inventory.Manifest do if MatchText(Item.Kind,['.fmx','.dfm']) and AScan.Results.TryGetValue(Item.RelativePath,IR) then BindForms(Item.RelativePath,IR);
      Result:=FGraph; FGraph:=nil;
    except FGraph.Free; raise; end;
  finally Tokens.Free; FImports.Free; FTokens.Free; FNames.Free; FKeys.Free; FNodeSymbols.Free; FBaseTypes.Free; end;
end;
end.
