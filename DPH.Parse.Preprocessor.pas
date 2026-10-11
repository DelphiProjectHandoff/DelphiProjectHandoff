unit DPH.Parse.Preprocessor;

interface

uses System.SysUtils, System.Generics.Collections, DPH.Project.Source, DPH.Parse.Model;

type
  TDPHCondition = class
  private
    FText: string;
    FPosition, FDepth: Integer;
    FQuoted: Boolean;
    FSymbols: TDictionary<string,string>;
    function Take(const AWord: string): Boolean;
    function Atom: string;
    function Factor: TDPHActive;
    function Term: TDPHActive;
    function Expression: TDPHActive;
  public
    class function Evaluate(const AExpression: string; ASymbols: TDictionary<string,string>): TDPHActive; static;
    class function Both(A,B: TDPHActive): TDPHActive; static;
    class function Either(A,B: TDPHActive): TDPHActive; static;
    class function Opposite(A: TDPHActive): TDPHActive; static;
  end;
  TDPHIncludeResolver = reference to function(const AFrom, AInclude: string): TDPHSource;
  TDPHPreprocessor = class
  private
    FSymbols: TDictionary<string,string>;
    FDiagnostics: TDPHDiagnostics;
    FResolver: TDPHIncludeResolver;
    FIncludeStack: TList<string>;
    FOutput: TList<TDPHToken>;
    procedure Process(ASource: TDPHSource; AParentActive: TDPHActive; const AParentCondition: string);
  public
    constructor Create(const ADefines: TArray<string>; ADiagnostics: TDPHDiagnostics; AResolver: TDPHIncludeResolver);
    destructor Destroy; override;
    function Run(ASource: TDPHSource): TDPHTokens;
  end;

implementation
uses System.StrUtils, System.Classes, DPH.Parse.Lexer;
type
  TConditionalFrame = record
    Parent, Taken: TDPHActive;
    OuterCondition, ExpressionText: string;
    ElseSeen: Boolean;
  end;

class function TDPHCondition.Both(A,B: TDPHActive): TDPHActive;
begin
  if (A=daInactive) or (B=daInactive) then Result:=daInactive
  else if (A=daUnknown) or (B=daUnknown) then Result:=daUnknown else Result:=daActive;
end;
class function TDPHCondition.Either(A,B: TDPHActive): TDPHActive;
begin
  if (A=daActive) or (B=daActive) then Result:=daActive
  else if (A=daUnknown) or (B=daUnknown) then Result:=daUnknown else Result:=daInactive;
end;
class function TDPHCondition.Opposite(A: TDPHActive): TDPHActive;
begin
  if A=daUnknown then Result:=daUnknown else if A=daActive then Result:=daInactive else Result:=daActive;
end;

function TDPHCondition.Take(const AWord: string): Boolean;
begin
  while (FPosition<=Length(FText)) and (FText[FPosition]<=' ') do Inc(FPosition);
  Result:=SameText(Copy(FText,FPosition,Length(AWord)),AWord);
  if Result and CharInSet(AWord[1],['A'..'Z','a'..'z']) and
    (FPosition+Length(AWord)<=Length(FText)) then
    Result:=not CharInSet(FText[FPosition+Length(AWord)],['A'..'Z','a'..'z','0'..'9','_']);
  if Result then Inc(FPosition,Length(AWord));
end;

function TDPHCondition.Atom: string;
var Start: Integer; Quote: Char;
begin
  FQuoted:=False;
  while (FPosition<=Length(FText)) and (FText[FPosition]<=' ') do Inc(FPosition);
  Start:=FPosition;
  if (FPosition<=Length(FText)) and CharInSet(FText[FPosition],['''','"']) then
  begin
    FQuoted:=True;
    Quote:=FText[FPosition]; Inc(FPosition); Start:=FPosition;
    while (FPosition<=Length(FText)) and (FText[FPosition]<>Quote) do Inc(FPosition);
    Result:=Copy(FText,Start,FPosition-Start);
    if FPosition<=Length(FText) then Inc(FPosition) else Result:=#0;
  end
  else
  begin
    while (FPosition<=Length(FText)) and CharInSet(FText[FPosition],['A'..'Z','a'..'z','0'..'9','_','.']) do Inc(FPosition);
    Result:=Copy(FText,Start,FPosition-Start);
    if FPosition=Start then begin Result:=#0; Inc(FPosition); end;
  end;
end;

function TDPHCondition.Factor: TDPHActive;
var Left,Right,Op: string; Comparison: Integer; LNumber,RNumber: Double; LQuoted,RQuoted: Boolean;
begin
  Inc(FDepth);
  try
  if FDepth>DPHMaxNesting then Exit(daUnknown);
  if Take('not') then Exit(Opposite(Factor));
  if Take('(') then begin Result:=Expression; if not Take(')') then Result:=daUnknown; Exit; end;
  if Take('defined') then
  begin
    if not Take('(') then Exit(daUnknown);
    Left:=Atom;
    if not Take(')') then Exit(daUnknown);
    if FSymbols.ContainsKey('UNKNOWN:'+UpperCase(Left)) then Exit(daUnknown);
    if FSymbols.ContainsKey('DEFINE:'+UpperCase(Left)) then Exit(daActive) else Exit(daInactive);
  end;
  Left:=Atom; LQuoted:=FQuoted; Op:='';
  if Take('==') then Op:='=' else if Take('!=') then Op:='<>'
  else if Take('<>') then Op:='<>' else if Take('<=') then Op:='<='
  else if Take('>=') then Op:='>=' else if Take('=') then Op:='='
  else if Take('<') then Op:='<' else if Take('>') then Op:='>';
  if Op='' then
  begin
    if SameText(Left,'true') then Exit(daActive);
    if SameText(Left,'false') then Exit(daInactive);
    Exit(daUnknown);
  end;
  Right:=Atom; RQuoted:=FQuoted; if (Left=#0) or (Right=#0) then Exit(daUnknown);
  if not LQuoted and not TryStrToFloat(Left,LNumber,TFormatSettings.Invariant) then Exit(daUnknown);
  if not RQuoted and not TryStrToFloat(Right,RNumber,TFormatSettings.Invariant) then Exit(daUnknown);
  if TryStrToFloat(Left,LNumber,TFormatSettings.Invariant) and TryStrToFloat(Right,RNumber,TFormatSettings.Invariant) then
  begin if LNumber<RNumber then Comparison:=-1 else if LNumber>RNumber then Comparison:=1 else Comparison:=0; end
  else Comparison:=CompareText(Left,Right);
  Result:=daInactive;
  if ((Op='=') and (Comparison=0)) or ((Op='<>') and (Comparison<>0)) or
    ((Op='<') and (Comparison<0)) or ((Op='>') and (Comparison>0)) or
    ((Op='<=') and (Comparison<=0)) or ((Op='>=') and (Comparison>=0)) then Result:=daActive;
  finally Dec(FDepth); end;
end;
function TDPHCondition.Term: TDPHActive;
var Next: TDPHActive;
begin Result:=Factor; while Take('and') do begin Next:=Factor; Result:=Both(Result,Next); end; end;
function TDPHCondition.Expression: TDPHActive;
var Next: TDPHActive;
begin Result:=Term; while Take('or') do begin Next:=Term; Result:=Either(Result,Next); end; end;
class function TDPHCondition.Evaluate(const AExpression: string; ASymbols: TDictionary<string,string>): TDPHActive;
var Parser: TDPHCondition;
begin
  if Length(AExpression)>65536 then Exit(daUnknown);
  Parser:=TDPHCondition.Create;
  try
    Parser.FText:=AExpression; Parser.FPosition:=1; Parser.FSymbols:=ASymbols;
    Result:=Parser.Expression;
    while (Parser.FPosition<=Length(AExpression)) and (AExpression[Parser.FPosition]<=' ') do Inc(Parser.FPosition);
    if Parser.FPosition<=Length(AExpression) then Result:=daUnknown;
  finally Parser.Free; end;
end;

constructor TDPHPreprocessor.Create(const ADefines: TArray<string>; ADiagnostics: TDPHDiagnostics; AResolver: TDPHIncludeResolver);
var S: string;
begin
  inherited Create; FDiagnostics:=ADiagnostics; FResolver:=AResolver;
  FSymbols:=TDictionary<string,string>.Create; FIncludeStack:=TList<string>.Create; FOutput:=TList<TDPHToken>.Create;
  for S in ADefines do if S.Trim<>'' then FSymbols.AddOrSetValue('DEFINE:'+UpperCase(S.Trim),'true');
end;
destructor TDPHPreprocessor.Destroy;
begin FOutput.Free; FIncludeStack.Free; FSymbols.Free; inherited; end;

procedure TDPHPreprocessor.Process(ASource: TDPHSource; AParentActive: TDPHActive; const AParentCondition: string);
var Frames: TList<TConditionalFrame>; Frame: TConditionalFrame; Tokens: TDPHTokens;
    Token, InputToken: TDPHToken; Directive,Command,Argument,Condition: string; SplitAt: Integer;
    Active,Decision: TDPHActive; Included: TDPHSource;
begin
  if (FIncludeStack.Count>=32) or FIncludeStack.Contains(ASource.RelativePath) then
  begin FDiagnostics.Report('INCLUDE_CYCLE_OR_DEPTH','Include cycle or depth limit',ASource.Range(0,0),'error'); Exit; end;
  if not ASource.Decoded then Exit;
  FIncludeStack.Add(ASource.RelativePath); Frames:=TList<TConditionalFrame>.Create;
  Active:=AParentActive; Condition:=AParentCondition;
  try
    Tokens:=TDPHLexer.Tokenize(ASource,FDiagnostics);
    for InputToken in Tokens do
    begin
      Token:=InputToken;
      Token.Active:=Active; Token.Condition:=Condition;
      if Token.Kind=tkEOF then Continue;
      if FOutput.Count>=DPHMaxTokens then raise EReadError.Create('Expanded token limit');
      FOutput.Add(Token);
      if Token.Kind<>tkDirective then Continue;
      Directive:=Token.Text;
      if Directive.StartsWith('{') then Directive:=Copy(Directive,3,Length(Directive)-3)
      else Directive:=Copy(Directive,4,Length(Directive)-5);
      Directive:=Directive.Trim; SplitAt:=1;
      while (SplitAt<=Length(Directive)) and (Directive[SplitAt]>' ') do Inc(SplitAt);
      Command:=UpperCase(Copy(Directive,1,SplitAt-1)); Argument:=Trim(Copy(Directive,SplitAt,MaxInt));
      if (Command='IFDEF') or (Command='IFNDEF') or (Command='IF') or (Command='IFOPT') then
      begin
        if Frames.Count>=DPHMaxNesting then raise EReadError.Create('Conditional nesting limit');
        if (Command='IFDEF') or (Command='IFNDEF') then
        begin
          if FSymbols.ContainsKey('UNKNOWN:'+UpperCase(Argument)) then Decision:=daUnknown
          else if FSymbols.ContainsKey('DEFINE:'+UpperCase(Argument)) then Decision:=daActive else Decision:=daInactive;
          if Command='IFNDEF' then Decision:=TDPHCondition.Opposite(Decision);
        end
        else if Command='IF' then Decision:=TDPHCondition.Evaluate(Argument,FSymbols) else Decision:=daUnknown;
        Frame.Parent:=Active; Frame.Taken:=Decision; Frame.OuterCondition:=Condition;
        Frame.ExpressionText:=Command+' '+Argument; Frame.ElseSeen:=False; Frames.Add(Frame);
        Active:=TDPHCondition.Both(Active,Decision); Condition:=Condition+'['+Frame.ExpressionText+']';
        if Decision=daUnknown then FDiagnostics.Report('UNKNOWN_CONDITIONAL','Conditional expression is unsupported; branches retained as unknown',Token.Location);
      end
      else if (Command='ELSE') or (Command='ELSEIF') then
      begin
        if Frames.Count=0 then begin FDiagnostics.Report('UNMATCHED_CONDITIONAL',Command,Token.Location,'error'); Continue; end;
        Frame:=Frames.Last;
        if Frame.ElseSeen then FDiagnostics.Report('DUPLICATE_ELSE',Command,Token.Location,'error');
        if Command='ELSE' then begin Decision:=daActive; Frame.ElseSeen:=True; end
        else Decision:=TDPHCondition.Evaluate(Argument,FSymbols);
        Active:=TDPHCondition.Both(Frame.Parent,TDPHCondition.Both(TDPHCondition.Opposite(Frame.Taken),Decision));
        Frame.Taken:=TDPHCondition.Either(Frame.Taken,Decision); Frames[Frames.Count-1]:=Frame;
        Condition:=Frame.OuterCondition+'['+Command+' '+Argument+' after '+Frame.ExpressionText+']';
      end
      else if (Command='ENDIF') or (Command='IFEND') then
      begin
        if Frames.Count=0 then FDiagnostics.Report('UNMATCHED_CONDITIONAL',Command,Token.Location,'error')
        else begin Frame:=Frames.Last; Frames.Delete(Frames.Count-1); Active:=Frame.Parent; Condition:=Frame.OuterCondition; end;
      end
      else if (Command='DEFINE') or (Command='UNDEF') then
      begin
        if Active=daActive then
        begin
          FSymbols.Remove('UNKNOWN:'+UpperCase(Argument));
          if Command='DEFINE' then FSymbols.AddOrSetValue('DEFINE:'+UpperCase(Argument),'true')
          else FSymbols.Remove('DEFINE:'+UpperCase(Argument));
        end
        else if Active=daUnknown then
        begin
          FSymbols.AddOrSetValue('UNKNOWN:'+UpperCase(Argument),'true');
          FDiagnostics.Report('CONDITIONAL_DEFINE_UNKNOWN','Definition depends on unsupported condition',Token.Location);
        end;
      end
      else if ((Command='I') or (Command='INCLUDE')) and (Active<>daInactive) then
      begin
        Argument:=Argument.DeQuotedString('''').DeQuotedString('"');
        Included:=nil;
        if Assigned(FResolver) then Included:=FResolver(ASource.RelativePath,Argument);
        if Assigned(Included) then Process(Included,Active,Condition)
        else FDiagnostics.Report('INCLUDE_UNAVAILABLE',Argument,Token.Location,'error');
      end
      else if (Command='MESSAGE') and (Active<>daInactive) then
        FDiagnostics.Report('COMPILER_MESSAGE',Argument,Token.Location);
    end;
    if Frames.Count<>0 then FDiagnostics.Report('UNCLOSED_CONDITIONAL','Conditional blocks cross end of source',ASource.Range(0,0),'error');
  finally Frames.Free; FIncludeStack.Delete(FIncludeStack.Count-1); end;
end;

function TDPHPreprocessor.Run(ASource: TDPHSource): TDPHTokens;
var Token: TDPHToken;
begin
  FOutput.Clear; Process(ASource,daActive,'');
  Token:=Default(TDPHToken); Token.Kind:=tkEOF; Token.Active:=daActive;
  Token.Location:=ASource.Range(Length(ASource.Text),Length(ASource.Text)); FOutput.Add(Token);
  Result:=FOutput.ToArray;
end;
end.
