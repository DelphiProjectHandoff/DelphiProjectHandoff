unit DPH.Parse.Model;

interface

uses System.SysUtils, System.Generics.Collections, System.JSON;

const DPHAnalyzerVersion = 'DPH-WP2-3';
      DPHIRVersion = 1;
      DPHMaxSourceBytes = 16 * 1024 * 1024;
      DPHMaxNesting = 128;
      DPHMaxTokens = 250000;
      DPHMaxNodes = 100000;

type
  TDPHRange = record
    Source: string;
    StartByte, EndByte, Line, Column: Integer;
  end;
  TDPHDiagnostic = record
    Code, MessageText, Severity: string;
    Location: TDPHRange;
  end;
  TDPHDiagnostics = class(TList<TDPHDiagnostic>)
    procedure Report(const ACode, AMessage: string; const ARange: TDPHRange;
      const ASeverity: string = 'warning');
  end;
  TDPHActive = (daInactive, daActive, daUnknown);
  TDPHTokenKind = (tkSpace, tkComment, tkDirective, tkIdentifier, tkNumber, tkString, tkSymbol, tkEOF);
  TDPHToken = record
    Kind: TDPHTokenKind;
    Text: string;
    Location: TDPHRange;
    Active: TDPHActive;
    Condition: string;
  end;
  TDPHTokens = TArray<TDPHToken>;
  TDPHIRNode = record
    Kind, Name, Value, Condition: string;
    Parent: Integer;
    Location: TDPHRange;
    FirstToken, LastToken: Integer;
  end;
  TDPHParseResult = class
  public
    Nodes: TList<TDPHIRNode>;
    Tokens: TDPHTokens;
    SignificantTokens, RecognizedTokens, OpaqueTokens: Integer;
    Complete: Boolean;
    constructor Create;
    destructor Destroy; override;
    function AsJSON: TJSONObject;
    function Clone: TDPHParseResult;
  end;

implementation

procedure TDPHDiagnostics.Report(const ACode, AMessage: string;
  const ARange: TDPHRange; const ASeverity: string);
var D: TDPHDiagnostic;
begin
  if Count>=10000 then Exit;
  D.Code:=ACode; D.MessageText:=AMessage; D.Location:=ARange; D.Severity:=ASeverity;
  Add(D);
end;

constructor TDPHParseResult.Create;
begin inherited; Nodes:=TList<TDPHIRNode>.Create; Complete:=True; end;
destructor TDPHParseResult.Destroy;
begin Nodes.Free; inherited; end;

function TDPHParseResult.Clone: TDPHParseResult;
begin
  Result:=TDPHParseResult.Create; Result.Nodes.AddRange(Nodes);
  Result.Tokens:=Copy(Tokens); Result.Complete:=Complete;
  Result.SignificantTokens:=SignificantTokens; Result.RecognizedTokens:=RecognizedTokens;
  Result.OpaqueTokens:=OpaqueTokens;
end;

function TDPHParseResult.AsJSON: TJSONObject;
var Items: TJSONArray; N: TDPHIRNode; Row: TJSONObject;
begin
  Result:=TJSONObject.Create;
  Result.AddPair('schema_version',TJSONNumber.Create(DPHIRVersion));
  Result.AddPair('analyzer',DPHAnalyzerVersion);
  Result.AddPair('complete',TJSONBool.Create(Complete));
  Result.AddPair('significant_tokens',TJSONNumber.Create(SignificantTokens));
  Result.AddPair('recognized_tokens',TJSONNumber.Create(RecognizedTokens));
  Result.AddPair('opaque_tokens',TJSONNumber.Create(OpaqueTokens));
  Items:=TJSONArray.Create; Result.AddPair('nodes',Items);
  for N in Nodes do
  begin
    Row:=TJSONObject.Create; Items.AddElement(Row);
    Row.AddPair('kind',N.Kind); Row.AddPair('name',N.Name); Row.AddPair('value',N.Value);
    Row.AddPair('parent',TJSONNumber.Create(N.Parent)); Row.AddPair('source',N.Location.Source);
    Row.AddPair('start',TJSONNumber.Create(N.Location.StartByte));
    Row.AddPair('end',TJSONNumber.Create(N.Location.EndByte));
    Row.AddPair('line',TJSONNumber.Create(N.Location.Line));
    Row.AddPair('column',TJSONNumber.Create(N.Location.Column)); Row.AddPair('condition',N.Condition);
  end;
end;
end.
