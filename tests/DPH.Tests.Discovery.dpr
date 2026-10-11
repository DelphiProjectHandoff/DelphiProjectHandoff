program DPHDiscoveryTests;
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes, System.IOUtils, System.JSON, System.Hash,
  System.Generics.Collections, Winapi.ActiveX,
  FireDAC.Comp.Client, FireDAC.Stan.Def, FireDAC.Stan.Async, FireDAC.DApt,
  DPH.Parse.Model in '..\DPH.Parse.Model.pas',
  DPH.Project.Source in '..\DPH.Project.Source.pas',
  DPH.Parse.Lexer in '..\DPH.Parse.Lexer.pas',
  DPH.Parse.Preprocessor in '..\DPH.Parse.Preprocessor.pas',
  DPH.Parse.Pascal in '..\DPH.Parse.Pascal.pas',
  DPH.Parse.Forms in '..\DPH.Parse.Forms.pas',
  DPH.Storage.Types in '..\DPH.Storage.Types.pas',
  DPH.Project.Inventory in '..\DPH.Project.Inventory.pas',
  DPH.Storage.Database in '..\DPH.Storage.Database.pas',
  DPH.Project.Analysis in '..\DPH.Project.Analysis.pas';
var Root,Work,Fixture,ReferenceRoot: string; Checks: Integer; TestRows: TJSONArray;

procedure Check(OK: Boolean; const ID,MessageText: string);
var Row: TJSONObject;
begin
  if not OK then raise Exception.Create('FAIL '+ID+': '+MessageText);
  Inc(Checks); Writeln('PASS '+ID+': '+MessageText);
  Row:=TJSONObject.Create; Row.AddPair('id',ID); Row.AddPair('result','pass');
  Row.AddPair('message',MessageText); TestRows.AddElement(Row);
end;

procedure WriteText(const Name,Text: string);
begin TFile.WriteAllText(TPath.Combine(Work,Name),Text,TEncoding.UTF8); end;

function NodeCount(Parsed: TDPHParseResult; const Kind,Name: string): Integer;
var N: TDPHIRNode;
begin
  Result:=0; for N in Parsed.Nodes do if ((Kind='') or (N.Kind=Kind)) and ((Name='') or SameText(N.Name,Name)) then Inc(Result);
end;

function HasDiagnostic(Diagnostics: TDPHDiagnostics; const Code: string): Boolean;
var D: TDPHDiagnostic;
begin Result:=False; for D in Diagnostics do if D.Code=Code then Exit(True); end;

function ParseText(const Text: string; out Diagnostics: TDPHDiagnostics): TDPHParseResult;
var Source: TDPHSource; P: TDPHPreprocessor; Parser: TDPHPascalParser;
begin
  WriteText('Temporary.pas',Text); Diagnostics:=TDPHDiagnostics.Create;
  Source:=TDPHSource.Create(TPath.Combine(Work,'Temporary.pas'),'temporary.pas',Diagnostics);
  try
    P:=TDPHPreprocessor.Create(['MSWINDOWS','WIN32'],Diagnostics,nil);
    Parser:=TDPHPascalParser.Create;
    try Result:=Parser.Parse(P.Run(Source),Diagnostics); finally Parser.Free; P.Free; end;
  finally Source.Free; end;
end;

procedure EncodingTests;
var D: TDPHDiagnostics; Source: TDPHSource; B: TBytes; R: TDPHRange;
  Tokens: TDPHTokens; T: TDPHToken; Enc: TEncoding;
begin
  D:=TDPHDiagnostics.Create;
  try
    WriteText('Encoding.pas','unit Cafe; // '+#$00E9+#13#10+'end.');
    Source:=TDPHSource.Create(TPath.Combine(Work,'Encoding.pas'),'encoding.pas',D);
    try
      R:=Source.Range(14,15); Tokens:=TDPHLexer.Tokenize(Source,D);
      Check(Source.Decoded and (Source.EncodingName='UTF-8 BOM') and (R.EndByte-R.StartByte=2),'ENC01','UTF-8 BOM and multibyte offsets');
      Check(Source.LineEndings='CRLF=1;LF=0;CR=0','ENC02','Line ending metadata retained');
      Check((Length(Tokens)>0) and (Tokens[0].Location.StartByte=3),'LEX01','Token starts after BOM');
      for T in Tokens do Check((T.Location.StartByte>=0) and (T.Location.EndByte<=Length(Source.Bytes)),'LEXRANGE'+IntToStr(T.Location.StartByte),'Token byte range inside captured source');
    finally Source.Free; end;
    TFile.WriteAllText(TPath.Combine(Work,'Encoding.pas'),'unit Wide; end.',TEncoding.Unicode);
    Source:=TDPHSource.Create(TPath.Combine(Work,'Encoding.pas'),'encoding.pas',D);
    try Check(Source.Decoded and (Source.Range(0,1).StartByte=2) and (Source.Range(0,1).EndByte=4),'ENC03','UTF-16 LE byte mapping'); finally Source.Free; end;
    TFile.WriteAllText(TPath.Combine(Work,'Encoding.pas'),'unit Wide; end.',TEncoding.BigEndianUnicode);
    Source:=TDPHSource.Create(TPath.Combine(Work,'Encoding.pas'),'encoding.pas',D);
    try Check(Source.Decoded and (Source.EncodingName='UTF-16 BE'),'ENC04','UTF-16 BE round trip'); finally Source.Free; end;
    B:=TBytes.Create($75,$6E,$69,$74,$20,$E9,$3B); TFile.WriteAllBytes(TPath.Combine(Work,'Encoding.pas'),B);
    Source:=TDPHSource.Create(TPath.Combine(Work,'Encoding.pas'),'encoding.pas',D);
    try Check(not Source.Decoded,'ENC05','Malformed UTF-8 never silently treated as ANSI'); finally Source.Free; end;
    Source:=TDPHSource.Create(TPath.Combine(Work,'Encoding.pas'),'encoding.pas',D,1252);
    try Check(Source.Decoded and (Source.EncodingName='CP1252'),'ENC06','Explicit legacy code page round trips'); finally Source.Free; end;
    Enc:=TEncoding.UTF8; B:=Enc.GetBytes('unit '+#$D83D+#$DE00+';'); TFile.WriteAllBytes(TPath.Combine(Work,'Encoding.pas'),B);
    Source:=TDPHSource.Create(TPath.Combine(Work,'Encoding.pas'),'encoding.pas',D);
    try Check(Source.Decoded and (Source.Range(5,7).EndByte-Source.Range(5,7).StartByte=4),'ENC07','Supplementary Unicode scalar byte range'); finally Source.Free; end;
  finally D.Free; end;
end;

procedure ParserTests;
var Parsed: TDPHParseResult; D: TDPHDiagnostics; Symbols: TDictionary<string,string>; S: string;
begin
  Symbols:=TDictionary<string,string>.Create;
  try
    Check(TDPHCondition.Evaluate('''Debug'' == ''Debug'' and (1 < 2)',Symbols)=daActive,'COND01','Supported project expression');
    Check(TDPHCondition.Evaluate('CompilerVersion > 23',Symbols)=daUnknown,'COND02','Compiler symbols require explicit known value');
    Check(TDPHCondition.Evaluate(StringOfChar('(',200)+'true'+StringOfChar(')',200),Symbols)=daUnknown,'COND03','Conditional recursion is bounded');
  finally Symbols.Free; end;
  Parsed:=ParseText('unit Test; interface procedure Foo; implementation procedure Foo; begin end; end.',D);
  try Check(Parsed.Complete and (NodeCount(Parsed,'routine_procedure','Foo')=2),'PAS01','Declaration and implementation stay separate'); finally Parsed.Free; D.Free; end;
  Parsed:=ParseText('unit Test; interface type TBox<T> = class procedure Run; end; implementation procedure TBox<T>.Run; begin end; end.',D);
  try Check(NodeCount(Parsed,'type','TBox')=1,'PAS02','Generic type structural discovery'); finally Parsed.Free; D.Free; end;
  Parsed:=ParseText('unit Test; interface implementation procedure Outer; procedure Inner; begin end; begin Run(procedure begin Inner; end); end; end.',D);
  try Check((NodeCount(Parsed,'anonymous_procedure','')=1) and (NodeCount(Parsed,'routine_procedure','Inner')=1),'PAS03','Nested routines and anonymous callback syntax'); finally Parsed.Free; D.Free; end;
  Parsed:=ParseText('unit Test; interface implementation procedure Foo; asm nop end; end.',D);
  try Check(not Parsed.Complete and HasDiagnostic(D,'OPAQUE_SYNTAX'),'PAS04','Assembler stays opaque and partial'); finally Parsed.Free; D.Free; end;
  Parsed:=ParseText(TFile.ReadAllText(TPath.Combine(Root,'tests\fixtures\Malformed.pas')),D);
  try Check(not Parsed.Complete and (D.Count>0),'PAS05','Malformed source yields diagnostics and partial IR'); finally Parsed.Free; D.Free; end;
  S:=TFile.ReadAllText(TPath.Combine(Root,'tests\fixtures\Conditional.pas'));
  Parsed:=ParseText(S,D);
  try Check(not Parsed.Complete and (Parsed.OpaqueTokens>0) and HasDiagnostic(D,'CONDITIONAL_DEFINE_UNKNOWN'),'COND04','Unknown branches and conditional definitions remain uncertain'); finally Parsed.Free; D.Free; end;
  Parsed:=ParseText('unit Test; interface // comment'+#10+'const S=''escaped''''quote''; implementation end.',D);
  try Check(Parsed.Complete and (Length(Parsed.Tokens)>Parsed.SignificantTokens),'LEX02','Comments, whitespace and escaped strings preserved'); finally Parsed.Free; D.Free; end;
  Parsed:=ParseText('unit Test; interface const Bad=%102; implementation end.',D);
  try Check(not Parsed.Complete and HasDiagnostic(D,'INVALID_NUMBER'),'LEX03','Malformed binary numeric literal is diagnosed'); finally Parsed.Free; D.Free; end;
  Parsed:=ParseText('package Test; requires Runtime; contains Local in ''Local.pas''; end.',D);
  try Check(Parsed.Complete and (NodeCount(Parsed,'package','Test')=1),'PAS06','Package terminator and dependency clauses'); finally Parsed.Free; D.Free; end;
  Parsed:=ParseText('unit Test; interface type TTest=class class var Value: Integer; end; implementation end.',D);
  try Check(not Parsed.Complete and HasDiagnostic(D,'OPAQUE_SYNTAX'),'PAS07','Unsupported class storage syntax cannot be mistaken for a routine'); finally Parsed.Free; D.Free; end;
end;

procedure FormTests;
var Input,Output: TMemoryStream; FormParser: TDPHFormParser; Source: TDPHSource;
    Parsed: TDPHParseResult; D: TDPHDiagnostics; Bytes: TBytes; Text: UTF8String;
begin
  D:=TDPHDiagnostics.Create; FormParser:=TDPHFormParser.Create;
  try
    Text:='object Form: TCustomThirdParty'+#10+' Caption = ''Hello'''+#10+' OnClick = Click'+#10+' object Child: TChild'+#10+'  Width = 10'+#10+' end'+#10+'end'+#10;
    Input:=TMemoryStream.Create; Output:=TMemoryStream.Create;
    try
      Input.WriteBuffer(PAnsiChar(Text)^,Length(Text)); Input.Position:=0;
      ObjectTextToBinary(Input,Output); SetLength(Bytes,Output.Size); Output.Position:=0; Output.ReadBuffer(Bytes,Length(Bytes));
      TFile.WriteAllBytes(TPath.Combine(Work,'Binary.dfm'),Bytes);
    finally Output.Free; Input.Free; end;
    Source:=TDPHSource.Create(TPath.Combine(Work,'Binary.dfm'),'binary.dfm',D);
    try
      Parsed:=FormParser.Parse(Source,D);
      try Check(Parsed.Complete and (NodeCount(Parsed,'object','')=2) and (NodeCount(Parsed,'event_binding','OnClick')=1),'FORM01','Direct binary form parser requires no component classes'); finally Parsed.Free; end;
    finally Source.Free; end;
    SetLength(Bytes,Length(Bytes)-2); TFile.WriteAllBytes(TPath.Combine(Work,'Broken.dfm'),Bytes);
    Source:=TDPHSource.Create(TPath.Combine(Work,'Broken.dfm'),'broken.dfm',D);
    try Parsed:=FormParser.Parse(Source,D); try Check(not Parsed.Complete,'FORM02','Truncated binary form is partial'); finally Parsed.Free; end; finally Source.Free; end;
    WriteText('Inherited.dfm','inherited Form: TCustomThirdParty'+#10+' object Child: TChild'+#10+'  Data = {'+#10+'   01020304}' +#10+' end'+#10+'end');
    Source:=TDPHSource.Create(TPath.Combine(Work,'Inherited.dfm'),'inherited.dfm',D);
    try Parsed:=FormParser.Parse(Source,D); try Check(Parsed.Complete and (NodeCount(Parsed,'inherited','Form')=1),'FORM03','Inherited text form and binary property range'); finally Parsed.Free; end; finally Source.Free; end;
  finally FormParser.Free; D.Free; end;
end;

procedure InventoryTests;
var Analyzer: TDPHAnalyzer; First,Again,Full,Changed: TDPHScan; J,Expected: TJSONObject;
    Before,After: string; Store: TDPHKnowledgeStore; Config,Generation,Head: Int64;
    FormIR,UnitIR: TDPHParseResult; D: TDPHDiagnostic; Golden: TJSONValue;
    ReleaseScan: TDPHScan; N: TDPHIRNode; Found: Boolean; Probe: TFDConnection; EntitiesBefore: Int64;
begin
  Analyzer:=TDPHAnalyzer.Create;
  try
    First:=Analyzer.Scan(TPath.Combine(Fixture,'Fixture.dproj'),'Debug','Win32',['MSWINDOWS','WIN32'],[],False);
    try
      J:=First.AsJSON; try TFile.WriteAllText(TPath.Combine(Work,'fixture-ir.json'),J.Format,TEncoding.UTF8); Before:=J.ToJSON; finally J.Free; end;
      for D in First.Inventory.Diagnostics do Writeln('FIXTURE ',D.Code,': ',D.MessageText);
      Expected:=TJSONObject.ParseJSONValue(TFile.ReadAllText(TPath.Combine(Fixture,'expected.json'))) as TJSONObject;
      try
        Check(Length(First.Inventory.Manifest)=Expected.GetValue<Integer>('files'),'INV01','Golden inventory file count');
        Check(First.Complete=Expected.GetValue<Boolean>('complete'),'INV02','Golden narrow project has complete syntax coverage');
      finally Expected.Free; end;
      FormIR:=First.Results['model.fmx']; UnitIR:=First.Results['model.pas'];
      Check((NodeCount(FormIR,'object','')=2) and (NodeCount(FormIR,'event_binding','OnClick')=1),'INV03','Golden hierarchy and event binding');
      Check(NodeCount(UnitIR,'routine_procedure','TExample.SetValue')=4,'INV04','Overload prototypes and implementations');
      Check(NodeCount(UnitIR,'property','Value')=1,'INV06','Published Pascal property name retained');
      Golden:=TJSONObject.ParseJSONValue(TFile.ReadAllText(TPath.Combine(Root,'tests\fixtures\syntax\expected-ir.json')));
      try Check(Golden.ToJSON=Before,'GOLD01','Exact versioned golden IR including ranges, manifests and diagnostics'); finally Golden.Free; end;
      ReleaseScan:=Analyzer.Scan(TPath.Combine(Fixture,'Fixture.dproj'),'Release','Win32',['MSWINDOWS','WIN32'],[]);
      try
        Found:=False; for N in ReleaseScan.Results['model.pas'].Nodes do if (N.Kind='declaration_const') and (N.Value='Selected = 2 ;') then Found:=True;
        Check(Found and ReleaseScan.Complete,'COND05','Release and Debug select distinct known branches');
      finally ReleaseScan.Free; end;
      Check(First.Inventory.Revalidate,'INV05','All captured source hashes remain unchanged');
      Again:=Analyzer.Scan(TPath.Combine(Fixture,'Fixture.dproj'),'Debug','Win32',['MSWINDOWS','WIN32'],[]);
      try
        J:=Again.AsJSON; try After:=J.ToJSON; finally J.Free; end;
        Check((Before=After) and (Again.ReusedFiles=3),'INC01','Incremental parse reuse equals clean full IR and diagnostics');
      finally Again.Free; end;
      Store:=TDPHKnowledgeStore.Create(TPath.Combine(Work,'Scan.dphdb'),Fixture,TPath.Combine(Root,'migrations'));
      try
        Store.InitializeProject('Syntax fixture','dproj'); Config:=Store.AddConfiguration('Win32','37.0','["FEATURE","MSWINDOWS","WIN32"]','[]','Debug');
        Store.SelectConfiguration(Config); Generation:=First.Stage(Store,Config);
        Check(First.Publish(Store,Generation),'STORE01','Complete syntax generation publishes atomically'); Head:=Store.Status.PublishedGeneration;
        Store.AddManualNote('Manual note','Keep this content','owner');
        Generation:=First.Stage(Store,Config);
        TFile.AppendAllText(TPath.Combine(Fixture,'Options.inc'),#10+'// changed test copy',TEncoding.UTF8);
        Check(not First.Publish(Store,Generation) and (Store.Status.PublishedGeneration=Head) and
          Store.Status.ModificationDetected and Store.Status.ReassessmentRequested,'STORE02','Mid-analysis source edit keeps the previous head and requests reassessment');
        Changed:=Analyzer.Scan(TPath.Combine(Fixture,'Fixture.dproj'),'Debug','Win32',['MSWINDOWS','WIN32'],[]);
        Full:=Analyzer.Scan(TPath.Combine(Fixture,'Fixture.dproj'),'Debug','Win32',['MSWINDOWS','WIN32'],[],False);
        try
          J:=Changed.AsJSON; try Before:=J.ToJSON; finally J.Free; end;
          J:=Full.AsJSON; try After:=J.ToJSON; finally J.Free; end;
          Check(Before=After,'INC02','Edited include incremental/full equivalence');
          Check(Store.IntegrityCheck='ok','STORE03','Syntax evidence and entity storage preserve integrity');
          Generation:=Changed.Stage(Store,Config); Check(Changed.Publish(Store,Generation),'STORE04','Changed include generation publishes after revalidation');
          Probe:=TFDConnection.Create(nil);
          try
            Probe.LoginPrompt:=False; Probe.Params.Values['DriverID']:='SQLite'; Probe.Params.Values['Database']:=Store.DatabasePath;
            Probe.Params.Values['LockingMode']:='Normal'; Probe.Connected:=True;
            EntitiesBefore:=Probe.ExecSQLScalar('SELECT count(*) FROM entities');
            TFile.WriteAllText(TPath.Combine(Fixture,'Model.pas'),'// harmless shift'+#10+TFile.ReadAllText(TPath.Combine(Fixture,'Model.pas')),TEncoding.UTF8);
            Again:=Analyzer.Scan(TPath.Combine(Fixture,'Fixture.dproj'),'Debug','Win32',['MSWINDOWS','WIN32'],[]);
            try
              Generation:=Again.Stage(Store,Config); Check(Again.Publish(Store,Generation),'STORE05','Shifted source publishes valid new ranges');
              Check(Probe.ExecSQLScalar('SELECT count(*) FROM entities')=EntitiesBefore,'STORE06','Syntax entity identities survive source offset shifts');
              Check(Probe.ExecSQLScalar('SELECT count(*) FROM knowledge_records')=1,'STORE07','Manual note retained across parser generations');
            finally Again.Free; end;
          finally Probe.Free; end;
        finally Full.Free; Changed.Free; end;
      finally Store.Free; end;
    finally First.Free; end;
    WriteText('Boundary.dpr','program Boundary; uses Escape in ''..\Outside.pas''; begin end.');
    First:=Analyzer.Scan(TPath.Combine(Work,'Boundary.dpr'),'Debug','Win32',[],[]);
    try Check(not First.Complete and HasDiagnostic(First.Inventory.Diagnostics,'BOUNDARY_EXCLUDED'),'SAFE01','Traversal outside selected root is excluded'); finally First.Free; end;
    WriteText('DTD.dproj','<!DOCTYPE Project [<!ENTITY x SYSTEM "file:///c:/secret.txt">]><Project>&x;</Project>');
    First:=Analyzer.Scan(TPath.Combine(Work,'DTD.dproj'),'Debug','Win32',[],[]);
    try Check(not First.Complete and HasDiagnostic(First.Inventory.Diagnostics,'XML_DTD_REJECTED'),'SAFE02','Project DTD rejected before XML parsing'); finally First.Free; end;
    WriteText('Cycle.dpr','program Cycle; {$I Cycle.inc} begin end.'); WriteText('Cycle.inc','{$I Cycle.inc}');
    First:=Analyzer.Scan(TPath.Combine(Work,'Cycle.dpr'),'Debug','Win32',[],[]);
    try Check(not First.Complete and HasDiagnostic(First.Inventory.Diagnostics,'INCLUDE_CYCLE_OR_DEPTH'),'SAFE03','Include cycles are bounded and diagnosed'); finally First.Free; end;
    WriteText('Passive.dproj','<Project><Target Name="Bad"><Exec Command="create-marker.exe"/></Target><ItemGroup><DCCReference Include="Missing.pas"/></ItemGroup></Project>');
    First:=Analyzer.Scan(TPath.Combine(Work,'Passive.dproj'),'Debug','Win32',[],[]);
    try Check(not First.Complete and HasDiagnostic(First.Inventory.Diagnostics,'FILE_UNAVAILABLE'),'SAFE04','Build targets remain passive and missing references visible'); finally First.Free; end;
    WriteText('External.pas','unit External; interface implementation end.');
    TDirectory.CreateDirectory(TPath.Combine(Work,'bounded'));
    TFile.WriteAllText(TPath.Combine(Work,'bounded\External.dpr'),'program ExternalProject; uses External in ''..\External.pas''; begin end.',TEncoding.UTF8);
    First:=Analyzer.Scan(TPath.Combine(Work,'bounded\External.dpr'),'Debug','Win32',[],[Work]);
    try Check(First.Complete and First.Results.ContainsKey('external/0/external.pas'),'SAFE05','Explicit external root uses traversal-free canonical manifest'); finally First.Free; end;
    WriteText('UnknownMacro.dproj','<Project><PropertyGroup><Root>.</Root></PropertyGroup><ItemGroup><DCCReference Include="$(Root)\$(Unprovided)\External.pas"/></ItemGroup></Project>');
    First:=Analyzer.Scan(TPath.Combine(Work,'UnknownMacro.dproj'),'Debug','Win32',[],[]);
    try Check(not First.Complete and HasDiagnostic(First.Inventory.Diagnostics,'PROJECT_PATH_MACRO') and (First.Inventory.Sources.Count=1),'SAFE06','Unprovided path macro cannot collapse into an unintended filename'); finally First.Free; end;
    WriteText('Group.groupproj','<Project><ItemGroup><Projects Include="fixture\Fixture.dproj"/></ItemGroup></Project>');
    First:=Analyzer.Scan(TPath.Combine(Work,'Group.groupproj'),'Debug','Win32',['MSWINDOWS','WIN32'],[]);
    try Check(First.Results.ContainsKey('fixture/model.fmx') and First.Complete,'INV07','Project-group member graph parsed without executing its targets'); finally First.Free; end;
    WriteText('GroupCycle.groupproj','<Project><ItemGroup><Projects Include="GroupCycle.groupproj"/></ItemGroup></Project>');
    First:=Analyzer.Scan(TPath.Combine(Work,'GroupCycle.groupproj'),'Debug','Win32',[],[]);
    try Check(First.Inventory.Sources.Count=1,'SAFE07','Project graph cycle terminates'); finally First.Free; end;
    TDirectory.CreateDirectory(TPath.Combine(Work,'search'));
    TFile.WriteAllText(TPath.Combine(Work,'search\Local.inc'),'const SearchValue=1;',TEncoding.UTF8);
    TFile.WriteAllText(TPath.Combine(Work,'search\Scope.Named.pas'),'unit Scope.Named; interface implementation end.',TEncoding.UTF8);
    WriteText('Search.dpr','program Search; uses Named; {$I Local.inc} begin end.');
    WriteText('Search.dproj','<Project><PropertyGroup><DCC_UnitSearchPath>search</DCC_UnitSearchPath><DCC_IncludePath>search</DCC_IncludePath><DCC_Namespace>Scope</DCC_Namespace></PropertyGroup><ItemGroup><DelphiCompile Include="Search.dpr"/></ItemGroup></Project>');
    First:=Analyzer.Scan(TPath.Combine(Work,'Search.dproj'),'Debug','Win32',[],[]);
    try Check(First.Complete and First.Results.ContainsKey('search/scope.named.pas'),'INV08','Explicit project search paths, include paths and unit scopes retained during parsing'); finally First.Free; end;
    WriteText('Limit.dpr','program Limit; '+StringOfChar(' ',1));
    TFile.WriteAllText(TPath.Combine(Work,'Limit.dpr'),'program Limit; '+StringOfChar('{',1)+StringOfChar('x',16*1024*1024),TEncoding.UTF8);
    First:=Analyzer.Scan(TPath.Combine(Work,'Limit.dpr'),'Debug','Win32',[],[]);
    try Check(not First.Complete and HasDiagnostic(First.Inventory.Diagnostics,'FILE_UNAVAILABLE'),'SAFE08','Oversized input rejected before token allocation'); finally First.Free; end;
  finally Analyzer.Free; end;
end;

procedure ReferenceTests;
var Analyzer: TDPHAnalyzer; Scan: TDPHScan; FormIR,UnitIR: TDPHParseResult; J,Report,Row: TJSONObject;
    N: TDPHIRNode; Found: Boolean; Files: TJSONArray; Item: TDPHManifestFile;
begin
  Analyzer:=TDPHAnalyzer.Create;
  try
    Scan:=Analyzer.Scan(TPath.Combine(ReferenceRoot,'VCL2FMXConverter.dproj'),'Debug','Win32',['MSWINDOWS','WIN32'],[],False);
    try
      Check(Scan.Results.TryGetValue('mainform.fmx',FormIR),'REF01','Pinned reference FMX acquired');
      Check((NodeCount(FormIR,'object','frmMain')=1) and (NodeCount(FormIR,'event_binding','OnClick')>0),'REF02','Pinned form hierarchy and event values extracted');
      Check(Scan.Results.TryGetValue('mainform.pas',UnitIR),'REF03','Pinned reference MainForm acquired');
      Check(NodeCount(UnitIR,'routine_procedure','TfrmMain.btnConvertClick')>=2,'REF04','btnConvertClick declaration and implementation ranges found');
      Found:=False;
      for N in FormIR.Nodes do if (N.Kind='event_binding') and (N.Value='btnConvertClick') then Found:=True;
      Check(Found,'REF05','btnConvert event names btnConvertClick; semantic resolution reserved for WP3');
      Check(not Scan.Complete and (Scan.Inventory.Diagnostics.Count>0),'REF06','Unavailable framework dependencies and unsupported syntax visibly partial');
      Check(Scan.Inventory.Revalidate,'REF07','Reference captured bytes unchanged after analysis');
      Report:=TJSONObject.Create;
      try
        Report.AddPair('reference_commit','e1fd10b2d3b06f2fc3f726b8eb7f234a54faf63d');
        Report.AddPair('complete',TJSONBool.Create(Scan.Complete)); Report.AddPair('diagnostic_count',TJSONNumber.Create(Scan.Inventory.Diagnostics.Count));
        Files:=TJSONArray.Create; Report.AddPair('files',Files);
        for Item in Scan.Inventory.Manifest do
        begin
          Row:=TJSONObject.Create; Files.AddElement(Row); Row.AddPair('path',Item.RelativePath);
          Row.AddPair('availability',Item.Availability); Row.AddPair('sha256',Item.SHA256);
          if Scan.Results.TryGetValue(Item.RelativePath,UnitIR) then
          begin Row.AddPair('nodes',TJSONNumber.Create(UnitIR.Nodes.Count)); Row.AddPair('significant_tokens',TJSONNumber.Create(UnitIR.SignificantTokens));
            Row.AddPair('opaque_tokens',TJSONNumber.Create(UnitIR.OpaqueTokens)); Row.AddPair('complete',TJSONBool.Create(UnitIR.Complete)); end;
        end;
        if ParamStr(2)<>'no-report' then TFile.WriteAllText(TPath.Combine(Root,'docs\wp2-reference-validation.json'),Report.Format,TEncoding.UTF8);
      finally Report.Free; end;
      J:=Scan.AsJSON; try TFile.WriteAllText(TPath.Combine(Work,'reference-ir.json'),J.Format,TEncoding.UTF8); finally J.Free; end;
    finally Scan.Free; end;
  finally Analyzer.Free; end;
end;

var Report: TJSONObject; Path,Destination: string;
begin
  CoInitializeEx(nil,COINIT_APARTMENTTHREADED); TestRows:=TJSONArray.Create;
  try
    try
      Root:=ParamStr(1); Work:=TPath.Combine(Root,'bin\wp2-tests-'+FormatDateTime('yyyymmdd-hhnnss-zzz',Now)); TDirectory.CreateDirectory(Work);
      Fixture:=TPath.Combine(Work,'fixture'); TDirectory.CreateDirectory(Fixture);
      for Path in TDirectory.GetFiles(TPath.Combine(Root,'tests\fixtures\syntax')) do
      begin Destination:=TPath.Combine(Fixture,ExtractFileName(Path)); TFile.Copy(Path,Destination); end;
      ReferenceRoot:=TPath.Combine(Root,'samples\reference-vcl2fmx-v6.0.0');
      EncodingTests; ParserTests; FormTests; InventoryTests; ReferenceTests;
      Report:=TJSONObject.Create;
      try
        Report.AddPair('analyzer',DPHAnalyzerVersion); Report.AddPair('ir_schema',TJSONNumber.Create(DPHIRVersion));
        Report.AddPair('checks_passed',TJSONNumber.Create(Checks)); Report.AddPair('checks',TestRows.Clone as TJSONArray);
        if ParamStr(2)<>'no-report' then TFile.WriteAllText(TPath.Combine(Root,'docs\wp2-validation.json'),Report.Format,TEncoding.UTF8);
      finally Report.Free; end;
      Writeln('PASS ALL: ',Checks,' checks');
    except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode:=1; end; end;
  finally TestRows.Free; CoUninitialize; end;
end.
