unit DPH.Parse.Pascal;

interface
uses System.SysUtils, System.Generics.Collections, DPH.Parse.Model;
type
  TDPHPascalParser = class
  private
    FTokens: TDPHTokens;
    FPosition, FDepth: Integer;
    FScope: string;
    FResult: TDPHParseResult;
    FDiagnostics: TDPHDiagnostics;
    function Current: string;
    function IsToken(const S: string): Boolean;
    function Take(const S: string): Boolean;
    procedure Expect(const S: string);
    function AddNode(const AKind, AName: string; AParent, AStart: Integer): Integer;
    procedure Finish(ANode: Integer);
    procedure Opaque(AParent: Integer; const AReason: string; const AStops: TArray<string>);
    procedure UsesClause(AParent: Integer);
    procedure Declarations(AParent: Integer; APrototypes: Boolean);
    procedure TypeDeclaration(AParent: Integer);
    procedure Attributes(AParent: Integer);
    procedure VariantRecord(AParent: Integer);
    procedure Routine(AParent: Integer; APrototype: Boolean);
    procedure Block(AParent: Integer);
    procedure Statement(AParent: Integer);
    procedure Expression(AParent: Integer; APrecedence: Integer = 0);
    function Precedence(const S: string): Integer;
  public
    function Parse(const ATokens: TDPHTokens; ADiagnostics: TDPHDiagnostics): TDPHParseResult;
  end;
implementation
uses System.StrUtils, System.Classes;

function TDPHPascalParser.Current: string;
begin if FPosition<Length(FTokens) then Result:=LowerCase(FTokens[FPosition].Text) else Result:=''; end;
function TDPHPascalParser.IsToken(const S: string): Boolean;
begin Result:=Current=S; end;
function TDPHPascalParser.Take(const S: string): Boolean;
begin Result:=IsToken(S); if Result then Inc(FPosition); end;
procedure TDPHPascalParser.Expect(const S: string);
begin
  if not Take(S) then
  begin FDiagnostics.Report('EXPECTED_TOKEN','Expected '+S,FTokens[FPosition].Location,'error'); FResult.Complete:=False; end;
end;
function TDPHPascalParser.AddNode(const AKind,AName: string; AParent,AStart: Integer): Integer;
var N: TDPHIRNode;
begin
  if FResult.Nodes.Count>=DPHMaxNodes then raise EReadError.Create('IR node limit');
  N:=Default(TDPHIRNode); N.Kind:=AKind; N.Name:=AName; N.Parent:=AParent;
  N.Location:=FTokens[AStart].Location; N.Condition:=FTokens[AStart].Condition; N.FirstToken:=AStart; N.LastToken:=AStart;
  Result:=FResult.Nodes.Add(N);
end;
procedure TDPHPascalParser.Finish(ANode: Integer);
var N: TDPHIRNode; I: Integer;
begin
  N:=FResult.Nodes[ANode]; N.LastToken:=FPosition-1;
  if (FPosition>0) and (FTokens[FPosition-1].Location.Source=N.Location.Source) then
    N.Location.EndByte:=FTokens[FPosition-1].Location.EndByte
  else
  begin FResult.Complete:=False; FDiagnostics.Report('MULTIFILE_NODE','Node spans include files; inspect token source mappings',N.Location); end;
  if (N.Value='') and ((N.LastToken-N.FirstToken)<128) and
    not MatchText(N.Kind,['unit','program','library','package','type','block']) and not N.Kind.StartsWith('statement_') then
    for I:=N.FirstToken to N.LastToken do N.Value:=N.Value+FTokens[I].Text+' ';
  N.Value:=Trim(N.Value); FResult.Nodes[ANode]:=N;
end;

procedure TDPHPascalParser.Opaque(AParent: Integer; const AReason: string; const AStops: TArray<string>);
var Start,Node,Depth: Integer;
begin
  Start:=FPosition; Node:=AddNode('opaque',AReason,AParent,Start); Depth:=0;
  while (FTokens[FPosition].Kind<>tkEOF) and ((Depth>0) or not MatchText(Current,AStops)) do
  begin
    if MatchText(Current,['(','[']) then Inc(Depth) else if MatchText(Current,[')',']']) then Dec(Depth);
    Inc(FPosition);
  end;
  if (FPosition=Start) and (FTokens[FPosition].Kind<>tkEOF) then Inc(FPosition);
  Inc(FResult.OpaqueTokens,FPosition-Start); FResult.Complete:=False;
  FDiagnostics.Report('OPAQUE_SYNTAX',AReason,FTokens[Start].Location); Finish(Node);
end;

function TDPHPascalParser.Precedence(const S: string): Integer;
begin
  if MatchText(S,['=','<>','<','>','<=','>=','in','is','as']) then Exit(1);
  if MatchText(S,['+','-','or','xor']) then Exit(2);
  if MatchText(S,['*','/','div','mod','and','shl','shr']) then Exit(3);
  Result:=0;
end;

procedure TDPHPascalParser.Expression(AParent: Integer; APrecedence: Integer);
var Node,Start,P,Before,GenericEnd,GenericDepth: Integer; Op: string;
begin
  Inc(FDepth);
  try
    if FDepth>DPHMaxNesting then begin Opaque(AParent,'Expression nesting limit',[';',')',']','then','do']); Exit; end;
    Start:=FPosition; Node:=AddNode('expression','',AParent,Start);
    if Take('inherited') then begin
      if not MatchText(Current,[';', 'end', 'else', ')', ',']) then Expression(Node,4);
    end
    else if MatchText(Current,['not','-','+','@']) then begin Inc(FPosition); Expression(Node,4); end
    else if Take('(') then begin Expression(Node); while Take(',') do Expression(Node); Expect(')'); end
    else if Take('[') then
    begin
      if not IsToken(']') then
      begin Expression(Node); if Take('..') then Expression(Node);
        while Take(',') do begin Expression(Node); if Take('..') then Expression(Node); end; end;
      Expect(']');
    end
    else if MatchText(Current,['procedure','function']) then Routine(Node,False)
    else if FTokens[FPosition].Kind in [tkIdentifier,tkNumber,tkString] then
    begin
      Inc(FPosition);
      while (FTokens[FPosition].Kind=tkString) or IsToken('#') do
      begin if Take('#') then begin if FTokens[FPosition].Kind=tkNumber then Inc(FPosition) else Expect('number'); end else Inc(FPosition); end;
    end
    else if Take('#') then begin if FTokens[FPosition].Kind=tkNumber then Inc(FPosition) else Expect('number'); end
    else begin Opaque(Node,'Expression not recognized',[';',')',']',',','then','do','end']); Finish(Node); Exit; end;
    while True do
    begin
      // A generic suffix must close before a call/member selection. Otherwise
      // leave '<' to the comparison parser (for example A < B and C > D).
      if IsToken('<') then begin
        GenericEnd:=FPosition; GenericDepth:=0;
        while GenericEnd<High(FTokens) do begin
          Op:=LowerCase(FTokens[GenericEnd].Text);
          if Op='<' then Inc(GenericDepth) else if Op='>' then Dec(GenericDepth)
          else if not ((FTokens[GenericEnd].Kind=tkIdentifier) or MatchText(Op,[',','.','[',']'])) then Break;
          Inc(GenericEnd); if GenericDepth=0 then Break;
        end;
        if (GenericDepth=0) and (GenericEnd>FPosition) and
          MatchText(FTokens[GenericEnd].Text,['(','.']) then begin FPosition:=GenericEnd; Continue; end;
      end;
      if Take('.') then begin if FTokens[FPosition].Kind=tkIdentifier then Inc(FPosition) else Expect('identifier'); end
      else if Take('^') then Continue
      else if Take('(') then
      begin
        if not IsToken(')') then begin Expression(Node); while Take(',') do Expression(Node); end;
        Expect(')');
      end
      else if Take('[') then
      begin Expression(Node); while Take(',') do Expression(Node); Expect(']'); end
      else Break;
    end;
    while True do
    begin
      Op:=Current; P:=Precedence(Op); if (P=0) or (P<=APrecedence) then Break;
      Inc(FPosition); Before:=FPosition; Expression(Node,P); if FPosition=Before then Break;
    end;
    Finish(Node);
  finally Dec(FDepth); end;
end;

procedure TDPHPascalParser.UsesClause(AParent: Integer);
var Node,Item,Start: Integer; Name: string;
begin
  Node:=AddNode('uses','',AParent,FPosition); Inc(FPosition);
  repeat
    Start:=FPosition; Name:='';
    while ((FTokens[FPosition].Kind=tkIdentifier) and not IsToken('in')) or IsToken('.') do
    begin Name:=Name+FTokens[FPosition].Text; Inc(FPosition); end;
    if Name='' then begin Opaque(Node,'Malformed uses clause',[';']); Break; end;
    Item:=AddNode('unit_reference',Name,Node,Start);
    if Take('in') then begin if FTokens[FPosition].Kind=tkString then Inc(FPosition) else Expect('string'); end;
    Finish(Item);
  until not Take(',');
  Expect(';'); Finish(Node);
end;

procedure TDPHPascalParser.Attributes(AParent: Integer);
var Node,Depth: Integer;
begin
  while IsToken('[') do begin
    Node:=AddNode('attribute','',AParent,FPosition); Depth:=0;
    repeat
      if IsToken('[') then Inc(Depth) else if IsToken(']') then Dec(Depth);
      Inc(FPosition);
    until (FTokens[FPosition].Kind=tkEOF) or (Depth=0);
    if Depth<>0 then Expect(']'); Finish(Node);
  end;
end;

procedure TDPHPascalParser.VariantRecord(AParent: Integer);
var Node,Branch,Field,Start,Depth,Before: Integer;
begin
  Inc(FDepth);
  try
    if FDepth>DPHMaxNesting then begin Opaque(AParent,'Variant record nesting limit',['end']); Exit; end;
    Node:=AddNode('record_variant','',AParent,FPosition); Expect('case');
    while (FTokens[FPosition].Kind<>tkEOF) and not MatchText(Current,['of','end',')']) do Inc(FPosition);
    Expect('of');
    while (FTokens[FPosition].Kind<>tkEOF) and not MatchText(Current,['end',')']) do begin
      Before:=FPosition; Branch:=AddNode('record_variant_branch','',Node,FPosition);
      while (FTokens[FPosition].Kind<>tkEOF) and not MatchText(Current,[':','end',')']) do Inc(FPosition);
      Expect(':'); Expect('(');
      while (FTokens[FPosition].Kind<>tkEOF) and not MatchText(Current,[')', 'end']) do begin
        Start:=FPosition;
        if IsToken('case') then VariantRecord(Branch)
        else begin
          Field:=AddNode('field',FTokens[FPosition].Text,Branch,FPosition); Depth:=0;
          while (FTokens[FPosition].Kind<>tkEOF) and ((Depth>0) or not MatchText(Current,[';',')','end'])) do begin
            if MatchText(Current,['(','[','<']) then Inc(Depth)
            else if MatchText(Current,[')',']','>']) then Dec(Depth);
            Inc(FPosition);
          end;
          Finish(Field);
        end;
        Take(';'); if FPosition=Start then Inc(FPosition);
      end;
      Expect(')'); Take(';'); Finish(Branch);
      if FPosition=Before then Break;
    end;
    Finish(Node);
  finally Dec(FDepth); end;
end;

procedure TDPHPascalParser.TypeDeclaration(AParent: Integer);
var Start,Node,Depth,Before,MemberDepth: Integer; Name,OldScope,Kind: string;
begin
  Start:=FPosition; Name:=FTokens[FPosition].Text; Inc(FPosition);
  if Take('<') then
  begin Depth:=1; while (FTokens[FPosition].Kind<>tkEOF) and (Depth>0) do
    begin if IsToken('<') then Inc(Depth) else if IsToken('>') then Dec(Depth); Inc(FPosition); end; end;
  Expect('='); Node:=AddNode('type',Name,AParent,Start);
  Take('packed');
  if MatchText(Current,['class','record','interface','dispinterface','object']) and
    not ((FPosition+1<Length(FTokens)) and SameText(FTokens[FPosition+1].Text,'of')) then
  begin
    Kind:=Current; Inc(FPosition); while MatchText(Current,['sealed','abstract']) do Inc(FPosition);
    if Take(';') then begin Finish(Node); Exit; end;
    if Take('helper') then begin if Take('for') then while not MatchText(Current,['public','private','protected','published','end','procedure','function']) and
      (FTokens[FPosition].Kind<>tkEOF) do Inc(FPosition); end;
    if Take('(') then begin Depth:=1; while (FTokens[FPosition].Kind<>tkEOF) and (Depth>0) do
      begin if IsToken('(') then Inc(Depth) else if IsToken(')') then Dec(Depth); Inc(FPosition); end; end;
    if Take('[') then begin while (FTokens[FPosition].Kind<>tkEOF) and not Take(']') do Inc(FPosition); end;
    OldScope:=FScope; FScope:=Name;
    try
      while (FTokens[FPosition].Kind<>tkEOF) and not IsToken('end') do
      begin
        Before:=FPosition;
        if IsToken('[') then Attributes(Node)
        else if IsToken('case') and (Kind='record') then VariantRecord(Node)
        else if MatchText(Current,['private','protected','public','published','strict','automated','var']) then Inc(FPosition)
        else if IsToken('type') then
        begin Inc(FDepth); try if FDepth>DPHMaxNesting then Opaque(Node,'Type nesting limit',[';','end'])
          else Declarations(Node,True); finally Dec(FDepth); end; end
        else if IsToken('class') and (FPosition+1<Length(FTokens)) and
          MatchText(FTokens[FPosition+1].Text,['var','property']) then
        begin Inc(FPosition); Take('var'); end
        else if MatchText(Current,['procedure','function','constructor','destructor','operator','class']) then Routine(Node,True)
        else if (FTokens[FPosition].Kind=tkIdentifier) then
        begin
          Start:=FPosition;
          if IsToken('property') then begin Inc(FPosition); Depth:=AddNode('property',FTokens[FPosition].Text,Node,Start); end
          else Depth:=AddNode('field',FTokens[FPosition].Text,Node,Start);
          Inc(FPosition); MemberDepth:=0;
          while (FTokens[FPosition].Kind<>tkEOF) and ((MemberDepth>0) or not MatchText(Current,[';','end'])) do begin
            if MatchText(Current,['(','[']) then Inc(MemberDepth) else if MatchText(Current,[')',']']) then Dec(MemberDepth);
            Inc(FPosition);
          end;
          Take(';'); Finish(Depth);
        end else Opaque(Node,'Unrecognized type member',[';','end']);
        if FPosition=Before then Inc(FPosition);
      end;
    finally FScope:=OldScope; end;
    Expect('end');
    while MatchText(Current,['deprecated','platform','experimental']) do begin
      Inc(FPosition); if FTokens[FPosition].Kind=tkString then Inc(FPosition);
    end;
    Expect(';');
  end
  else
  begin
    Depth:=0;
    while (FTokens[FPosition].Kind<>tkEOF) and ((Depth>0) or not IsToken(';')) do
    begin
      if MatchText(Current,['(','[']) then Inc(Depth) else if MatchText(Current,[')',']']) then Dec(Depth);
      if MatchText(Current,['case','asm','begin']) then begin Opaque(Node,'Complex type expression',[';']); Break; end;
      Inc(FPosition);
    end;
    Expect(';');
  end;
  Finish(Node);
end;

procedure TDPHPascalParser.Routine(AParent: Integer; APrototype: Boolean);
var Start,Node,Depth,Before: Integer; Name,Kind: string; IsForward,Anonymous: Boolean;
begin
  Start:=FPosition; Take('class'); Kind:=Current; Inc(FPosition); Name:='';
  Anonymous:=MatchText(Current,['(','begin',':','var','const','type']);
  if not Anonymous then
    while (FTokens[FPosition].Kind=tkIdentifier) or MatchText(Current,['.','<','>',',']) do
    begin Name:=Name+FTokens[FPosition].Text; Inc(FPosition); end;
  if (FScope<>'') and not Name.Contains('.') and (Name<>'') then Name:=FScope+'.'+Name;
  if Anonymous then Kind:='anonymous_'+Kind else Kind:='routine_'+Kind;
  Node:=AddNode(Kind,Name,AParent,Start); Depth:=0;
  while (FTokens[FPosition].Kind<>tkEOF) and not ((Depth=0) and (IsToken(';') or (Anonymous and MatchText(Current,['begin','var','const','type'])))) do
  begin if IsToken('(') then Inc(Depth) else if IsToken(')') then Dec(Depth); Inc(FPosition); end;
  if not Anonymous then Expect(';') else Take(';');
  Finish(Node);
  IsForward:=False;
  while MatchText(Current,['overload','override','virtual','dynamic','abstract','reintroduce','static','inline',
    'cdecl','stdcall','safecall','register','pascal','assembler','forward','external','message','deprecated','platform','final']) do
  begin
    if MatchText(Current,['forward','external','abstract']) then IsForward:=True;
    Inc(FPosition); while (FTokens[FPosition].Kind<>tkEOF) and not Take(';') do Inc(FPosition);
  end;
  if not APrototype and not IsForward then
  begin
    Before:=FPosition; Inc(FDepth);
    try if FDepth>DPHMaxNesting then Opaque(Node,'Routine nesting limit',[';','end'])
      else Declarations(Node,False); finally Dec(FDepth); end;
    if IsToken('begin') then Block(Node)
    else if IsToken('asm') then
    begin Opaque(Node,'Assembler block',['end']); Expect('end'); end
    else if FPosition=Before then begin FResult.Complete:=False; FDiagnostics.Report('ROUTINE_BODY_MISSING','Routine body not recognized',FTokens[FPosition].Location); end;
    if not Anonymous then Expect(';');
  end;
  Finish(Node);
end;

procedure TDPHPascalParser.Declarations(AParent: Integer; APrototypes: Boolean);
var Section: string; Node,Start,Depth,Before: Integer;
begin
  Section:='';
  while FTokens[FPosition].Kind<>tkEOF do
  begin
    Before:=FPosition;
    if IsToken('[') then Attributes(AParent)
    else if MatchText(Current,['interface','implementation']) then
    begin Section:=''; APrototypes:=IsToken('interface'); Inc(FPosition); end
    else if MatchText(Current,['uses','contains','requires']) then UsesClause(AParent)
    else if MatchText(Current,['type','var','const','threadvar','resourcestring','label']) then
    begin Section:=Current; Inc(FPosition); end
    else if MatchText(Current,['procedure','function','constructor','destructor','operator','class']) then Routine(AParent,APrototypes)
    else if MatchText(Current,['begin','initialization','finalization','end']) then Exit
    else if (Section='type') and (FTokens[FPosition].Kind=tkIdentifier) then TypeDeclaration(AParent)
    else if (Section<>'') and (FTokens[FPosition].Kind in [tkIdentifier,tkNumber]) then
    begin
      Start:=FPosition; Node:=AddNode('declaration_'+Section,FTokens[FPosition].Text,AParent,Start); Depth:=0;
      while (FTokens[FPosition].Kind<>tkEOF) and not ((Depth=0) and IsToken(';')) do
      begin if MatchText(Current,['(','[']) then Inc(Depth) else if MatchText(Current,[')',']']) then Dec(Depth); Inc(FPosition); end;
      Expect(';'); Finish(Node);
    end
    else Opaque(AParent,'Declaration not recognized',[';','begin','implementation','procedure','function','type','var','const','initialization','finalization','end']);
    if FPosition=Before then Inc(FPosition);
  end;
end;

procedure TDPHPascalParser.Block(AParent: Integer);
var Node,Before: Integer;
begin
  Node:=AddNode('block','',AParent,FPosition); Expect('begin');
  while (FTokens[FPosition].Kind<>tkEOF) and not IsToken('end') do
  begin Before:=FPosition; Statement(Node); if not Take(';') and not IsToken('end') then
    FDiagnostics.Report('STATEMENT_SEPARATOR','Expected statement separator',FTokens[FPosition].Location,'error');
    if FPosition=Before then Inc(FPosition); end;
  Expect('end'); Finish(Node);
end;

procedure TDPHPascalParser.Statement(AParent: Integer);
var Node,Before: Integer; Kind: string;
begin
  Inc(FDepth);
  try
    if FDepth>DPHMaxNesting then begin Opaque(AParent,'Statement nesting limit',[';','end']); Exit; end;
    if IsToken('begin') then begin Block(AParent); Exit; end;
    Kind:=Current; Node:=AddNode('statement_'+Kind,'',AParent,FPosition);
    if Take('if') then
    begin Expression(Node); Expect('then'); Statement(Node); if Take('else') then Statement(Node); end
    else if Take('while') or Take('with') then
    begin Expression(Node); while Take(',') do Expression(Node); Expect('do'); Statement(Node); end
    else if Take('for') then
    begin
      Take('var'); Expression(Node);
      if Take(':=') then begin Expression(Node); if not (Take('to') or Take('downto')) then Expect('to'); Expression(Node); end;
      Expect('do'); Statement(Node);
    end
    else if Take('repeat') then
    begin
      while (FTokens[FPosition].Kind<>tkEOF) and not IsToken('until') do
      begin Before:=FPosition; Statement(Node); Take(';'); if FPosition=Before then Inc(FPosition); end;
      Expect('until'); Expression(Node);
    end
    else if Take('try') then
    begin
      while (FTokens[FPosition].Kind<>tkEOF) and not MatchText(Current,['except','finally','end']) do
      begin Before:=FPosition; Statement(Node); Take(';'); if FPosition=Before then Inc(FPosition); end;
      if Take('except') or Take('finally') then
        while (FTokens[FPosition].Kind<>tkEOF) and not IsToken('end') do
        begin
          Before:=FPosition;
          if Take('on') then begin while (FTokens[FPosition].Kind<>tkEOF) and not Take('do') do Inc(FPosition); Statement(Node); end
          else if Take('else') then Continue else Statement(Node);
          Take(';'); if FPosition=Before then Inc(FPosition);
        end;
      Expect('end');
    end
    else if Take('case') then
    begin
      Expression(Node); Expect('of');
      while (FTokens[FPosition].Kind<>tkEOF) and not IsToken('end') do
      begin
        Before:=FPosition;
        if not Take('else') then
        begin Expression(Node); if Take('..') then Expression(Node);
          while Take(',') do begin Expression(Node); if Take('..') then Expression(Node); end; Expect(':'); end;
        Statement(Node); Take(';'); if FPosition=Before then Inc(FPosition);
      end;
      Expect('end');
    end
    else if Take('raise') then begin if not MatchText(Current,[';','end']) then Expression(Node); end
    else if Take('asm') then begin Opaque(Node,'Assembler block',['end']); Expect('end'); end
    else if Take('goto') then begin if FTokens[FPosition].Kind in [tkNumber,tkIdentifier] then Inc(FPosition) else Expect('label'); end
    else if Take('var') or Take('const') then
    begin
      while (FTokens[FPosition].Kind<>tkEOF) and not MatchText(Current,[':=','=',';','end']) do Inc(FPosition);
      if Take(':=') or Take('=') then Expression(Node);
    end
    else if MatchText(Current,[';','end','else','until']) then begin FResult.Nodes.Delete(Node); Exit; end
    else
    begin Expression(Node); if Take(':=') then Expression(Node);
      if Take(':') then Statement(Node);
    end;
    Finish(Node);
  finally Dec(FDepth); end;
end;

function TDPHPascalParser.Parse(const ATokens: TDPHTokens; ADiagnostics: TDPHDiagnostics): TDPHParseResult;
var Filtered: TList<TDPHToken>; T: TDPHToken; Root,Start,Before: Integer; Name: string;
    RootNode: TDPHIRNode; D: TDPHDiagnostic; DiagnosticStart, DiagnosticIndex: Integer;
begin
  FResult:=TDPHParseResult.Create; FDiagnostics:=ADiagnostics; FPosition:=0; FDepth:=0; FScope:='';
  DiagnosticStart:=0;
  FResult.Tokens:=Copy(ATokens); Filtered:=TList<TDPHToken>.Create;
  try
    for T in ATokens do
      if not (T.Kind in [tkSpace,tkComment,tkDirective]) and (T.Active<>daInactive) then
      begin
        if T.Active=daUnknown then
        begin Inc(FResult.OpaqueTokens); FResult.Complete:=False; end else Filtered.Add(T);
      end;
    FTokens:=Filtered.ToArray;
    if (Length(FTokens)=0) or (FTokens[High(FTokens)].Kind<>tkEOF) then
      raise EArgumentException.Create('Token stream requires EOF');
    FResult.SignificantTokens:=Length(FTokens)-1+FResult.OpaqueTokens;
    Start:=FPosition;
    if not MatchText(Current,['unit','program','library','package']) then
    begin Opaque(-1,'Compilation unit header missing',[';']); Take(';'); Root:=-1; end
    else
    begin
      Name:=Current; Inc(FPosition); Root:=AddNode(Name,'',-1,Start); Name:='';
      while (FTokens[FPosition].Kind<>tkEOF) and not IsToken(';') do begin Name:=Name+FTokens[FPosition].Text; Inc(FPosition); end;
      FScope:='';
      Expect(';');
      // Names are assigned without pretending that declarations resolve across units.
      RootNode:=FResult.Nodes[Root]; RootNode.Name:=Name; FResult.Nodes[Root]:=RootNode;
    end;
    Declarations(Root,False);
    if IsToken('begin') then Block(Root)
    else if Take('initialization') then
      while (FTokens[FPosition].Kind<>tkEOF) and not MatchText(Current,['finalization','end']) do
      begin Before:=FPosition; Statement(Root); Take(';'); if FPosition=Before then Inc(FPosition); end;
    if Take('finalization') then
      while (FTokens[FPosition].Kind<>tkEOF) and not IsToken('end') do
      begin Before:=FPosition; Statement(Root); Take(';'); if FPosition=Before then Inc(FPosition); end;
    if (Root>=0) and MatchText(FResult.Nodes[Root].Kind,['unit','package']) then Expect('end');
    Expect('.'); if FTokens[FPosition].Kind<>tkEOF then Opaque(Root,'Trailing tokens',['']);
    if Root>=0 then Finish(Root);
    FResult.RecognizedTokens:=FResult.SignificantTokens-FResult.OpaqueTokens;
    for DiagnosticIndex:=DiagnosticStart to FDiagnostics.Count-1 do
    begin D:=FDiagnostics[DiagnosticIndex]; if D.Severity='error' then FResult.Complete:=False; end;
    Result:=FResult; FResult:=nil;
  except FResult.Free; Filtered.Free; raise;
  end;
  Filtered.Free;
end;
end.
