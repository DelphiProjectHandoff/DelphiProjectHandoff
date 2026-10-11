program DPH.Tests.Semantics;
{$APPTYPE CONSOLE}
uses System.SysUtils, System.IOUtils, System.JSON, Winapi.ActiveX,
  DPH.Analysis.Model in '..\DPH.Analysis.Model.pas',
  DPH.Analysis.Symbols in '..\DPH.Analysis.Symbols.pas',
  DPH.Analysis.Flow in '..\DPH.Analysis.Flow.pas',
  DPH.Project.Analysis in '..\DPH.Project.Analysis.pas',
  DPH.Project.Inventory in '..\DPH.Project.Inventory.pas',
  DPH.Project.Source in '..\DPH.Project.Source.pas',
  DPH.Parse.Model in '..\DPH.Parse.Model.pas',
  DPH.Parse.Lexer in '..\DPH.Parse.Lexer.pas',
  DPH.Parse.Preprocessor in '..\DPH.Parse.Preprocessor.pas',
  DPH.Parse.Pascal in '..\DPH.Parse.Pascal.pas',
  DPH.Parse.Forms in '..\DPH.Parse.Forms.pas',
  DPH.Storage.Types in '..\DPH.Storage.Types.pas',
  DPH.Storage.Database in '..\DPH.Storage.Database.pas',
  DPH.Analysis.Persistence in '..\DPH.Analysis.Persistence.pas',
  DPH.Workspace.Model in '..\DPH.Workspace.Model.pas';
var Root,Work,Fixture: string; Checks: Integer; Rows: TJSONArray;

procedure Check(OK: Boolean; const ID,MessageText: string);
var J: TJSONObject;
begin
  if not OK then raise Exception.Create('FAIL '+ID+': '+MessageText);
  Inc(Checks); Writeln('PASS ',ID,': ',MessageText); J:=TJSONObject.Create; Rows.AddElement(J);
  J.AddPair('id',ID); J.AddPair('result','pass'); J.AddPair('message',MessageText);
end;
function Find(G: TDPHSemanticGraph; const Name,Signature: string): Integer;
var I: Integer;
begin
  Result:=-1; for I:=0 to G.Symbols.Count-1 do
    if SameText(G.Symbols[I].QualifiedName,Name) and ((Signature='*') or (G.Symbols[I].Signature=Signature)) then Exit(I);
end;
function Relation(G: TDPHSemanticGraph; AFrom,ATo: Integer; const Kind,Resolution: string): Boolean;
var R: TDPHRelation;
begin
  Result:=False; for R in G.Relations do if (R.FromSymbol=AFrom) and (R.ToSymbol=ATo) and
    (R.Kind=Kind) and (R.Resolution=Resolution) then Exit(True);
end;
function JSON(G: TDPHSemanticGraph): string;
var J: TJSONObject;
begin J:=G.AsJSON; try Result:=J.ToJSON; finally J.Free; end; end;

procedure AsyncDetailTests;
var A: TDPHAnalyzer; Analyzer: TDPHSemanticAnalyzer; Scan: TDPHScan; G,Cached: TDPHSemanticGraph;
    WorkIndex,NamedIndex,Operation,Queued,Sync,Callback,LocalValue: Integer;
begin
  TFile.WriteAllText(TPath.Combine(Fixture,'AsyncCases.pas'),
    'unit AsyncCases; interface procedure Work; implementation procedure Named; begin end; '+
    'procedure Work; var H:TThread; N:Integer; E:TEvent; begin N:=1; '+
    'H:=TThread.CreateAnonymousThread(procedure begin N:=N+1; end); H.Start; H.Terminate; H.WaitFor; '+
    'TThread.Queue(nil,Named); TThread.Synchronize(nil,Named); E.SetEvent; E.WaitFor; end; end.',TEncoding.UTF8);
  TFile.WriteAllText(TPath.Combine(Fixture,'AsyncCases.dpr'),'program AsyncCasesApp; uses AsyncCases in ''AsyncCases.pas''; begin end.',TEncoding.UTF8);
  A:=TDPHAnalyzer.Create; Analyzer:=TDPHSemanticAnalyzer.Create;
  try Scan:=A.Scan(TPath.Combine(Fixture,'AsyncCases.dpr'),'Debug','Win32',[],[]);
    try G:=Analyzer.Analyze(Scan);
      try
        WorkIndex:=Find(G,'AsyncCases.Work','*'); NamedIndex:=Find(G,'AsyncCases.Named','*');
        Operation:=Find(G,'AsyncCases.Work.$async1','*'); Queued:=Find(G,'AsyncCases.Work.$async2','*'); Sync:=Find(G,'AsyncCases.Work.$async3','*');
        Callback:=Find(G,'AsyncCases.Work.$callback0','*'); LocalValue:=Find(G,'AsyncCases.Work.N','*');
        Check((Operation>=0) and Relation(G,WorkIndex,Callback,'prepares_callback','possible_dynamic'),'ASYNC04','Thread creation retains a separate callback preparation fact');
        Check(Relation(G,WorkIndex,Operation,'starts','possible_dynamic'),'ASYNC05','Known local handle Start links to its lexical creation site');
        Check(Relation(G,WorkIndex,Operation,'requests_cancellation','possible_dynamic') and Relation(G,WorkIndex,Operation,'waits_for','possible_dynamic'),'ASYNC06','Cancellation request and blocking wait remain separate qualified actions');
        Check(Relation(G,Queued,NamedIndex,'dispatches','possible_dynamic') and Relation(G,Sync,NamedIndex,'dispatches','possible_dynamic'),'ASYNC07','Named callbacks retain distinct main-thread queue and synchronize sites');
        Check(Relation(G,WorkIndex,Sync,'waits_for','inferred'),'ASYNC08','Synchronize documents its normal-return completion contract with qualification');
        Check(Relation(G,Callback,LocalValue,'captures','inferred'),'ASYNC09','Closure capture is linked to the outer local without claiming lifetime safety');
        Check(Relation(G,WorkIndex,Find(G,'AsyncCases.Work.E','*'),'signals','inferred') and not G.Complete,'ASYNC10','Event signal and async lifetime review keep static coverage honest');
        Cached:=Analyzer.Analyze(Scan);
        try Check(JSON(G)=JSON(Cached),'ASYNC11','Postprocessed async facts are identical after routine cache reuse'); finally Cached.Free; end;
      finally G.Free; end;
    finally Scan.Free; end;
  finally Analyzer.Free; A.Free; end;
end;

procedure FlowDetailTests;
var A: TDPHAnalyzer; Analyzer: TDPHSemanticAnalyzer; Scan: TDPHScan; G: TDPHSemanticGraph;
    CaseRoutine,LabelRoutine,CrossRoutine,WithRoutine,CaseNode,GotoNode,LabelNode,Count,Matches,ElseEdges,Index: Integer;
    E: TDPHFlowEdge; N: TDPHFlowNode; R: TDPHRelation; D: TDPHDiagnostic; Found: Boolean;
begin
  TFile.WriteAllText(TPath.Combine(Fixture,'FlowCases.pas'),
    'unit FlowCases; interface type TObj=class Value:Integer; procedure Ping; end; var Value:Integer; '+
    'procedure Ping; procedure CaseWork(X:Integer); procedure LabelWork; procedure CrossWork; procedure WithWork(C:TObj); '+
    'implementation procedure Ping; begin end; procedure TObj.Ping; begin end; '+
    'procedure CaseWork(X:Integer); begin case X of 1,2: Ping; 3..5: begin Ping; Ping; end; else Ping; Ping; end; end; '+
    'procedure LabelWork; label Done; begin goto Done; Ping; Done: Ping; end; '+
    'procedure CrossWork; label Done; begin try goto Done; finally Ping; end; Done: Ping; end; '+
    'procedure WithWork(C:TObj); begin with C do begin Ping; Value:=1; end; end; end.',TEncoding.UTF8);
  TFile.WriteAllText(TPath.Combine(Fixture,'FlowCases.dpr'),'program FlowCasesApp; uses FlowCases in ''FlowCases.pas''; begin end.',TEncoding.UTF8);
  A:=TDPHAnalyzer.Create; Analyzer:=TDPHSemanticAnalyzer.Create;
  try
    Scan:=A.Scan(TPath.Combine(Fixture,'FlowCases.dpr'),'Debug','Win32',[],[]);
    try G:=Analyzer.Analyze(Scan);
      try
        CaseRoutine:=Find(G,'FlowCases.CaseWork','*'); LabelRoutine:=Find(G,'FlowCases.LabelWork','*');
        CrossRoutine:=Find(G,'FlowCases.CrossWork','*'); WithRoutine:=Find(G,'FlowCases.WithWork','*');
        CaseNode:=-1; GotoNode:=-1; LabelNode:=-1; Count:=0;
        for Index:=0 to G.FlowNodes.Count-1 do begin N:=G.FlowNodes[Index];
          if N.Routine=CaseRoutine then begin if N.Kind='case' then CaseNode:=Index; if N.Kind='ping' then Inc(Count); end;
          if N.Routine=LabelRoutine then begin if N.Kind='goto' then GotoNode:=Index; if N.Kind='label' then LabelNode:=Index; end;
        end;
        Check((CaseNode>=0) and (Count=5),'FLOW01','Case arms and all default statements survive as separate control-flow nodes');
        Matches:=0; ElseEdges:=0; Found:=False;
        for E in G.FlowEdges do if E.FromNode=CaseNode then begin
          if E.Kind='case_match' then Inc(Matches); if E.Kind='case_else' then Inc(ElseEdges); if E.Kind='case_no_match' then Found:=True;
        end;
        Check((Matches=2) and (ElseEdges=1) and not Found,'FLOW02','Case labels have separate alternatives and explicit else has no invented fallthrough');
        Count:=0; Found:=False; for E in G.FlowEdges do if E.FromNode=GotoNode then begin Inc(Count); if (E.ToNode=LabelNode) and (E.Kind='goto') and (E.Resolution='confirmed_static') then Found:=True; end;
        Check(Found and (Count=1),'FLOW03','Resolved goto targets its label without a false sequential edge');
        Found:=False; for E in G.FlowEdges do if (G.FlowNodes[E.FromNode].Routine=CrossRoutine) and (E.Kind='unresolved_jump') then Found:=True;
        Check(Found and not G.Complete,'FLOW04','Goto crossing a finally scope remains explicitly unresolved instead of bypassing cleanup');
        Found:=False; for E in G.FlowEdges do if (G.FlowNodes[E.FromNode].Routine=WithRoutine) and (E.Kind='with_body') then Found:=True;
        Check(Found,'FLOW05','With executes its body sequentially rather than as independent possible branches');
        Found:=False; for R in G.Relations do if (R.FromSymbol=WithRoutine) and (R.Kind='calls') and (R.Resolution='possible_dynamic') then Found:=True;
        Check(Found,'FLOW06','Unqualified call under with cannot falsely confirm the global candidate');
        Found:=False; for D in G.Diagnostics do if D.Code='WITH_SCOPE_PARTIAL' then Found:=True;
        Check(Found,'FLOW07','With member-binding coverage gap is visible in diagnostics');
      finally G.Free; end;
    finally Scan.Free; end;
  finally Analyzer.Free; A.Free; end;
end;

procedure StartupTests;
var A: TDPHAnalyzer; Analyzer: TDPHSemanticAnalyzer; Scan: TDPHScan; G: TDPHSemanticGraph;
    ProgramRoot,Entry,Init,Final,DepInit,Unused,WorkIndex: Integer; View: TDPHWorkspaceView; Projection: TJSONObject; V: TJSONValue; Found,HasFlow: Boolean; N: TDPHFlowNode;
begin
  TFile.WriteAllText(TPath.Combine(Fixture,'Startup.dpr'),'program StartupFixture; uses StartUnit in ''StartUnit.pas''; begin StartUnit.Work; end.',TEncoding.UTF8);
  TFile.WriteAllText(TPath.Combine(Fixture,'Startup.dproj'),'<Project><ItemGroup><DelphiCompile Include="Startup.dpr"/><DCCReference Include="UnusedInit.pas"/></ItemGroup></Project>',TEncoding.UTF8);
  TFile.WriteAllText(TPath.Combine(Fixture,'StartUnit.pas'),'unit StartUnit; interface uses DepUnit; procedure Work; implementation procedure Work; begin DepUnit.Work; end; initialization Work; finalization Work; end.',TEncoding.UTF8);
  TFile.WriteAllText(TPath.Combine(Fixture,'DepUnit.pas'),'unit DepUnit; interface procedure Work; implementation procedure Work; begin end; initialization Work; finalization Work; end.',TEncoding.UTF8);
  TFile.WriteAllText(TPath.Combine(Fixture,'UnusedInit.pas'),'unit UnusedInit; interface implementation initialization begin end; end.',TEncoding.UTF8);
  A:=TDPHAnalyzer.Create; Analyzer:=TDPHSemanticAnalyzer.Create;
  try
    Scan:=A.Scan(TPath.Combine(Fixture,'Startup.dproj'),'Debug','Win32',[],[]);
    try G:=Analyzer.Analyze(Scan);
      try
        ProgramRoot:=Find(G,'StartupFixture','*'); Entry:=Find(G,'StartupFixture.$entry','*');
        Init:=Find(G,'StartUnit.$initialization','*'); Final:=Find(G,'StartUnit.$finalization','*');
        DepInit:=Find(G,'DepUnit.$initialization','*'); Unused:=Find(G,'UnusedInit.$initialization','*'); WorkIndex:=Find(G,'StartUnit.Work','*');
        Check(G.Complete and (Entry>=0) and (Init>=0) and (Final>=0),'START01','Program entry and separate unit initialization/finalization have complete bounded routine semantics');
        Check(Relation(G,ProgramRoot,Entry,'enters','confirmed_static') and Relation(G,Entry,WorkIndex,'calls','confirmed_static'),'START02','Program declaration reaches its executable body and startup call');
        Check(Relation(G,ProgramRoot,Init,'initializes','inferred') and Relation(G,ProgramRoot,DepInit,'initializes','inferred'),'START03','Reachable direct and transitive unit initialization are included');
        Check((Unused>=0) and not Relation(G,ProgramRoot,Unused,'initializes','inferred'),'START04','An unused project-manager file does not become an executed initialization dependency');
        Check(Relation(G,Entry,Final,'finalizes','inferred') and Relation(G,Init,WorkIndex,'calls','confirmed_static'),'START05','Finalization phase and initialization body calls retain separate evidence');
        HasFlow:=False; for N in G.FlowNodes do if N.Routine=Init then HasFlow:=True;
        Check(HasFlow,'START06','Unit initialization has a navigable control-flow graph');
        View:=TDPHWorkspaceView.Create(TDPHWorkspaceView.Capture(Scan,G,1,TPath.Combine(Fixture,'Startup.dproj'),'Debug','Win32',[],[]));
        try Projection:=View.Graph('Execution','');
          try
            Found:=False; for V in Projection.GetValue<TJSONArray>('nodes') do if V.GetValue<string>('label')='StartupFixture' then Found:=True;
            Check(Found and not Projection.GetValue<Boolean>('runtime_trace'),'START07','Unselected Execution graph starts at the program and keeps static provenance');
          finally Projection.Free; end;
        finally View.Free; end;
      finally G.Free; end;
    finally Scan.Free; end;
  finally Analyzer.Free; A.Free; end;
end;

procedure ResolutionTests;
var A: TDPHAnalyzer; Analyzer: TDPHSemanticAnalyzer; Scan: TDPHScan; G: TDPHSemanticGraph;
    WorkIndex,PropertyIndex,Getter,Setter,TakeInteger,Solo,Index: Integer; R: TDPHRelation; Found: Boolean;
begin
  TFile.WriteAllText(TPath.Combine(Fixture,'Resolution.pas'),
    'unit Resolution; interface type TCount=Integer; TBase=class private FValue:TCount; '+
    'function GetValue:TCount; procedure SetValue(V:TCount); public function GetItem(A:Integer; B:Integer):TCount; '+
    'property Value:TCount read GetValue write SetValue; property Items[A:Integer; B:Integer]:TCount read GetItem; end; '+
    'TChild=class(TBase) end; TAlias=TChild; procedure Work; procedure Take(V:Integer); overload; procedure Take(V:string); overload; procedure Solo(V:Integer); '+
    'implementation function TBase.GetValue:TCount; begin Result:=FValue; end; procedure TBase.SetValue(V:TCount); begin FValue:=V; end; '+
    'function TBase.GetItem(A:Integer; B:Integer):TCount; begin Result:=FValue; end; '+
    'procedure Take(V:Integer); begin end; procedure Take(V:string); begin end; procedure Solo(V:Integer); begin end; '+
    'procedure Work; var C:TAlias; N:TCount; begin Take(N); N:=C.Value; C.Value:=N; N:=C.Items[1,2]; Solo(UnknownValue); end; end.',TEncoding.UTF8);
  A:=TDPHAnalyzer.Create; Analyzer:=TDPHSemanticAnalyzer.Create;
  try
    TFile.WriteAllText(TPath.Combine(Fixture,'Resolution.dpr'),'program ResolutionApp; uses Resolution in ''Resolution.pas''; begin end.',TEncoding.UTF8);
    Scan:=A.Scan(TPath.Combine(Fixture,'Resolution.dpr'),'Debug','Win32',[],[]);
    try
      G:=Analyzer.Analyze(Scan);
      try
        WorkIndex:=Find(G,'Resolution.Work','*'); PropertyIndex:=Find(G,'Resolution.TBase.Value','*');
        Getter:=Find(G,'Resolution.TBase.GetValue','*'); Setter:=Find(G,'Resolution.TBase.SetValue','*');
        TakeInteger:=Find(G,'Resolution.Take','(integer):'); Solo:=Find(G,'Resolution.Solo','*');
        Check(Relation(G,WorkIndex,TakeInteger,'calls','confirmed_static'),'RESOLVE01','Primitive type alias selects the correct overload');
        Check(Relation(G,PropertyIndex,Getter,'read_accessor','confirmed_static') and Relation(G,PropertyIndex,Setter,'write_accessor','confirmed_static'),'RESOLVE02','Property read/write declarations link to their actual accessor methods');
        Check(Relation(G,WorkIndex,PropertyIndex,'reads','inferred') and Relation(G,WorkIndex,PropertyIndex,'writes','inferred'),'RESOLVE03','Class aliases and inherited properties retain def-use links');
        Index:=Find(G,'Resolution.TBase.Items','*');
        Check((Index>=0) and (G.Symbols[Index].TypeName='TCount') and (Find(G,'Resolution.TBase.A','*')<0),'RESOLVE04','Indexed property parameters are not mistaken for property names or result types');
        Check(Relation(G,WorkIndex,Solo,'calls','possible_dynamic') and not Relation(G,WorkIndex,Solo,'calls','confirmed_static'),'RESOLVE05','A unique candidate with unknown argument type remains qualified');
        Found:=False; for R in G.Relations do if (R.FromSymbol=WorkIndex) and (R.ToSymbol=Index) and (R.Kind='reads') then Found:=True;
        Check(Found,'RESOLVE06','Indexed inherited property reads have a captured property target');
      finally G.Free; end;
    finally Scan.Free; end;
  finally Analyzer.Free; A.Free; end;
end;

procedure CacheBindingTests;
var A: TDPHAnalyzer; Analyzer: TDPHSemanticAnalyzer; Scan,Changed: TDPHScan;
    Graph,Incremental,Full: TDPHSemanticGraph; Source: string;
begin
  Source:='unit Derivation; interface type TA=class procedure Run; virtual; end; TB=class procedure Run; virtual; end; TC=class(TA) end; '+
    'implementation procedure TA.Run; begin end; procedure TB.Run; begin end; end.';
  TFile.WriteAllText(TPath.Combine(Fixture,'Derivation.pas'),Source,TEncoding.UTF8);
  TFile.WriteAllText(TPath.Combine(Fixture,'Client.pas'),'unit Client; interface uses Derivation; procedure Work; implementation procedure Work; var C: TC; begin C.Run; end; end.',TEncoding.UTF8);
  TFile.WriteAllText(TPath.Combine(Fixture,'Binding.dpr'),'program Binding; uses Client in ''Client.pas''; begin end.',TEncoding.UTF8);
  A:=TDPHAnalyzer.Create; Analyzer:=TDPHSemanticAnalyzer.Create;
  try
    Scan:=A.Scan(TPath.Combine(Fixture,'Binding.dpr'),'Debug','Win32',[],[]);
    try Graph:=Analyzer.Analyze(Scan); Graph.Free; finally Scan.Free; end;
    TFile.WriteAllText(TPath.Combine(Fixture,'Derivation.pas'),Source.Replace('TC=class(TA)','TC=class(TB)'),TEncoding.UTF8);
    Changed:=A.Scan(TPath.Combine(Fixture,'Binding.dpr'),'Debug','Win32',[],[]);
    try
      Incremental:=Analyzer.Analyze(Changed);
      try
        Check((Analyzer.ReusedRoutines=0) and (Analyzer.RecomputedRoutines>0),'INC_CACHE05','Ancestry change invalidates dependent routine bindings across unchanged files');
        Check(Relation(Incremental,Find(Incremental,'Client.Work','*'),Find(Incremental,'Derivation.TB.Run','*'),'calls','possible_dynamic'),'INC_CACHE06','Changed ancestry resolves the unchanged caller to its new inherited method');
        Full:=Analyzer.Analyze(Changed,False);
        try Check(JSON(Incremental)=JSON(Full),'INC_CACHE07','Binding-invalidated semantics match a clean full rebuild'); finally Full.Free; end;
      finally Incremental.Free; end;
    finally Changed.Free; end;
  finally Analyzer.Free; A.Free; end;
end;

procedure DefinitionTests;
var A: TDPHAnalyzer; Analyzer: TDPHSemanticAnalyzer; Scan: TDPHScan; Graph: TDPHSemanticGraph;
    Loader,Resource,Index: Integer; Source: string; Config: Int64; Generation: Int64; Store: TDPHKnowledgeStore;
begin
  Source:='unit Definitions; interface procedure Load; implementation procedure Load; begin TFile.ReadAllText(''Rules.json''); end; end.';
  TFile.WriteAllText(TPath.Combine(Fixture,'Definitions.pas'),Source,TEncoding.UTF8);
  TFile.WriteAllText(TPath.Combine(Fixture,'Rules.json'),'{"rules":{"button":"TButton"}}',TEncoding.UTF8);
  TFile.WriteAllText(TPath.Combine(Fixture,'Definitions.dpr'),'program DefinitionsApp; uses Definitions in ''Definitions.pas''; begin end.',TEncoding.UTF8);
  A:=TDPHAnalyzer.Create; Analyzer:=TDPHSemanticAnalyzer.Create;
  try
    Scan:=A.Scan(TPath.Combine(Fixture,'Definitions.dpr'),'Debug','Win32',[],[]);
    try
      Check(Scan.Inventory.DefinitionReferences.Count=1,'DEF01','Literal loader acquires only its bounded referenced definition file');
      Check(Scan.Results.ContainsKey('rules.json'),'DEF02','Referenced JSON definitions receive parsed resource IR');
      Graph:=Analyzer.Analyze(Scan);
      try
        Loader:=Find(Graph,'Definitions.Load','*'); Resource:=-1;
        for Index:=0 to Graph.Symbols.Count-1 do if (Graph.Symbols[Index].Kind='resource') and (Graph.Symbols[Index].Location.Source='rules.json') then Resource:=Index;
        Check((Loader>=0) and (Resource>=0) and Relation(Graph,Loader,Resource,'reads','inferred'),'DEF03','Definition source links to its consuming routine without claiming compiler resolution');
        Check(Relation(Graph,Resource,Loader,'configures','inferred'),'DEF04','Configuration dependency exposes lexical loader order with runtime precedence qualified');
        Store:=TDPHKnowledgeStore.Create(TPath.Combine(Work,'definitions.dphdb'),Fixture,TPath.Combine(Root,'migrations'));
        try
          Store.InitializeProject('Definition loader fixture','Delphi');
          Config:=Store.AddConfiguration('Win32','37.0','[]','[]','Debug'); Store.SelectConfiguration(Config);
          Generation:=TDPHSemanticPersistence.Stage(Scan,Graph,Store,Config);
          Check(Generation>0,'DEF05','Resource and loader relationships persist with valid captured source evidence');
          Store.FailGeneration(Generation,'Test only');
        finally Store.Free; end;
      finally Graph.Free; end;
    finally Scan.Free; end;
  finally Analyzer.Free; A.Free; end;
end;

procedure FixtureTests;
var A: TDPHAnalyzer; S: TDPHSemanticAnalyzer; Scan,Again,Full,Variant: TDPHScan;
    G,GAgain,GFull,GV: TDPHSemanticGraph; I,Click,Callback,Worker,Base,Face,IntConvert,StrConvert,PublicWork,Shadow,LocalProc: Integer;
    R: TDPHRelation; E: TDPHFlowEdge; N: TDPHFlowNode; J: TJSONObject; Refs: TJSONArray;
    Found,ReturnVia,RaiseVia,HasTrue,HasFalse,HasLoop,HasBreak,HasContinue,ValidScopes: Boolean;
    Store: TDPHKnowledgeStore; Config,Generation,Head,NodeID,OtherNode: Int64;
    EmptyScan: TDPHScan; EmptyGraph: TDPHSemanticGraph; BeforeKey: string;
    Entity,OtherEntity,OtherGeneration: Int64; Rejected: Boolean;
begin
  A:=TDPHAnalyzer.Create; S:=TDPHSemanticAnalyzer.Create;
  try
    Scan:=A.Scan(TPath.Combine(Fixture,'Semantic.dproj'),'Debug','Win32',['MSWINDOWS','WIN32'],[],False);
    try
      G:=S.Analyze(Scan);
      try
        Click:=Find(G,'Main.TMain.Click','(integer):'); PublicWork:=Find(G,'Worker.PublicWork','(integer):');
        Worker:=Find(G,'Worker.TWorker','*'); Base:=Find(G,'Worker.TBase','*'); Face:=Find(G,'Worker.IWorker','*');
        IntConvert:=Find(G,'Worker.TWorker.Convert','(integer):'); StrConvert:=Find(G,'Worker.TWorker.Convert','(string):');
        Check((Click>=0) and G.Symbols[Click].HasBody and (G.Symbols[Click].Occurrences.Count=2),'SYM01','Method prototype and implementation share one identity');
        Check((IntConvert>=0) and (StrConvert>=0) and (IntConvert<>StrConvert),'SYM02','Overload identities retain parameter types');
        Check(Relation(G,Worker,Base,'inherits','confirmed_static') and Relation(G,Worker,Face,'implements','confirmed_static'),'SYM03','Cross-unit class and interface ancestry');
        Check(Relation(G,Click,IntConvert,'calls','confirmed_static') and Relation(G,Click,StrConvert,'calls','confirmed_static'),'CALL01','Literal argument types select separate overloads');
        Check(Relation(G,Click,PublicWork,'calls','confirmed_static'),'CALL02','Public routine resolved through uses');
        Found:=False; for R in G.Relations do if (R.FromSymbol=Click) and (R.LabelText='HiddenWork') and (R.Resolution='unresolved') then Found:=True;
        Check(Found,'CALL03','Implementation-private cross-unit routine stays unresolved');
        Check(Relation(G,Click,Find(G,'Worker.TWorker.Run','():'),'calls','possible_dynamic'),'CALL04','Virtual receiver is a possible dynamic target');
        Check(Relation(G,Click,Find(G,'Worker.IWorker.Run','():'),'calls','possible_dynamic'),'CALL05','Interface dispatch is a possible dynamic target');
        Check(Relation(G,Find(G,'Worker.TWorker.Run','():'),Find(G,'Worker.TBase.Run','():'),'calls','confirmed_static'),'CALL07','Explicit inherited invocation resolves to the ancestor implementation');
        I:=Find(G,'Main.Uncertain','():');
        Check(Relation(G,I,IntConvert,'calls','possible_dynamic') and Relation(G,I,StrConvert,'calls','possible_dynamic'),'UNCERTAIN01','Unknown overload argument retains multiple possible targets');
        Found:=False; for R in G.Relations do if (R.FromSymbol=I) and (R.LabelText='PublicWork') and (R.Resolution='unresolved') then Found:=True;
        Check(Found,'UNCERTAIN02','Known incompatible argument does not become a confirmed call');
        Found:=False; for R in G.Relations do if (R.FromSymbol=I) and (R.LabelText='HiddenBare') and (R.Kind='calls') and (R.Resolution='unresolved') then Found:=True;
        Check(Found,'UNCERTAIN04','Unknown parameterless invocation remains an explicit unresolved call');
        Found:=False; for R in G.Relations do if (R.FromSymbol=I) and (R.LabelText='MissingValue') and (R.Kind='reads') and (R.Resolution='unresolved') then Found:=True;
        Check(Found,'UNCERTAIN05','Unknown read on an assignment right-hand side remains explicit');
        Shadow:=Find(G,'Main.Shadow','():'); LocalProc:=Find(G,'Main.Shadow.PublicWork','*');
        Check(Relation(G,Shadow,LocalProc,'calls','possible_dynamic') and not Relation(G,Shadow,PublicWork,'calls','confirmed_static'),'CALL06','Local procedural variable shadows a public routine');
        Callback:=Find(G,'Main.TMain.Click.$callback0','():');
        Check((Callback>=0) and Relation(G,Click,Callback,'passes_callback','confirmed_static') and Relation(G,Click,Callback,'prepares_callback','possible_dynamic'),'ASYNC01','Anonymous thread callback is prepared without an invented Start');
        Check(Relation(G,Callback,PublicWork,'calls','confirmed_static'),'ASYNC02','Callback body uses its own local lexical scope');
        Check(Relation(G,Callback,Find(G,'Main.TMain.Click.$callback0.$callback0','():'),'schedules','possible_dynamic'),'ASYNC03','Nested queue callback retains a second asynchronous boundary');
        Found:=False; for R in G.Relations do if (R.Kind='binds') and (R.ToSymbol=Click) and (R.Resolution='confirmed_static') then Found:=True;
        Check(Found,'EVENT01','Serialized event binds to its form method');
        I:=0; for R in G.Relations do if (R.FromSymbol=Click) and (R.LabelText='Engine.Convert') and (R.Kind='calls') then Inc(I);
        Check(I=2,'NEG01','Comment containing a fake call produces no semantic call');
        HasTrue:=False; HasFalse:=False; HasLoop:=False; HasBreak:=False; HasContinue:=False; ReturnVia:=False; RaiseVia:=False;
        ValidScopes:=True;
        for E in G.FlowEdges do
        begin
          ValidScopes:=ValidScopes and (G.FlowNodes[E.FromNode].Routine=G.FlowNodes[E.ToNode].Routine);
          if G.FlowNodes[E.FromNode].Routine<>Click then Continue;
          if E.Kind='true' then HasTrue:=True; if E.Kind='false' then HasFalse:=True;
          if E.Kind='iterate' then HasLoop:=True; if E.Kind='break' then HasBreak:=True; if E.Kind='continue' then HasContinue:=True;
          if (E.Kind='return') and (G.FlowNodes[E.ToNode].ExpressionText='Count; 9') then ReturnVia:=True;
          if (E.Kind='raise') and (G.FlowNodes[E.ToNode].ExpressionText='Count; 9') then RaiseVia:=True;
        end;
        Check(ValidScopes,'CFG_SCOPE','CFG edges never enter another routine or callback');
        Check(HasTrue and HasFalse and HasLoop and HasBreak and HasContinue,'CFG01','Branch, loop, break and continue transfers');
        Check(ReturnVia and RaiseVia,'CFG02','Return and raise traverse finally before their destinations');
        Found:=False; for E in G.FlowEdges do if (E.Kind='break') and (G.FlowNodes[E.ToNode].ExpressionText='Count; 8') then Found:=True;
        Check(Found,'CFG03','Loop break crosses its finally body before leaving the loop');
        Found:=False; for E in G.FlowEdges do if (E.Kind='possible_handler') and (E.Resolution='possible_dynamic') then Found:=True;
        Check(Found,'CFG04','Typed exception matching remains a possible handler edge');
        Found:=False; for N in G.FlowNodes do if N.Kind='case' then Found:=True;
        Check(Found and not G.Complete,'CFG05','Case dispatch is structured while unresolved source calls keep analysis partial');
        Refs:=G.ReverseReferences(G.Symbols[PublicWork].Key);
        try Check(Refs.Count>=4,'IMPACT01','Reverse references include direct calls and callbacks'); finally Refs.Free; end;
        J:=G.Impact([G.Symbols[PublicWork].Key],8,100);
        try
          Check(J.GetValue<TJSONArray>('possible_impact').Count>=4,'IMPACT02','Bounded reverse traversal reaches possible dependents');
          Check((J.GetValue<TJSONArray>('possible_impact').Items[1] as TJSONObject).GetValue('via_edge')<>nil,'IMPACT04','Each non-seed impact result links its derivation evidence');
        finally J.Free; end;
        J:=G.Impact([G.Symbols[PublicWork].Key,G.Symbols[Click].Key],8,1);
        try Check((J.GetValue<TJSONArray>('possible_impact').Count=1) and J.GetValue<Boolean>('truncated'),'IMPACT03','Impact budget also bounds multiple seeds'); finally J.Free; end;
        Found:=False; for R in G.Relations do if (R.Kind='writes') and (R.FromSymbol=Click) and (R.ToSymbol=Find(G,'Main.TMain.Click.Count','*')) then Found:=True;
        Check(Found and not G.Complete,'DEF01','Def-use facts coexist with explicit unresolved coverage');
        Found:=True; for R in G.Relations do Found:=Found and G.SourceHashes.ContainsKey(R.Location.Source) and (R.Location.EndByte>=R.Location.StartByte);
        Check(Found,'PROVENANCE','Every relation has a captured source range and hash');
        Again:=A.Scan(TPath.Combine(Fixture,'Semantic.dproj'),'Debug','Win32',['MSWINDOWS','WIN32'],[]);
        Full:=A.Scan(TPath.Combine(Fixture,'Semantic.dproj'),'Debug','Win32',['MSWINDOWS','WIN32'],[],False);
        try
          GAgain:=S.Analyze(Again);
          Check((S.ReusedRoutines>0) and (S.RecomputedRoutines=0),'INC_CACHE01','Unchanged binding context reuses routine semantics');
          GFull:=S.Analyze(Full,False);
          Check((S.ReusedRoutines=0) and (S.RecomputedRoutines>0),'INC_CACHE02','Explicit full analysis rebuilds semantics independently of its cache');
          try Check((Again.ReusedFiles>0) and (JSON(G)=JSON(GAgain)) and (JSON(GAgain)=JSON(GFull)),'INCR01','Full and cached syntax produce identical complete semantic graphs'); finally GFull.Free; GAgain.Free; end;
        finally Full.Free; Again.Free; end;
        Variant:=A.Scan(TPath.Combine(Fixture,'Semantic.dproj'),'Debug','Win32',['MSWINDOWS','WIN32','FEATURE'],[],False);
        try
          GV:=S.Analyze(Variant);
          try Check((GV.Fingerprint=G.Fingerprint) and (GV.Symbols[Find(GV,'Main.Conditional','():')].Key<>G.Symbols[Find(G,'Main.Conditional','():')].Key) and (JSON(GV)<>JSON(G)),'VAR01','Same source under changed defines has distinct conditional semantic identities'); finally GV.Free; end;
        finally Variant.Free; end;
        TFile.WriteAllText(TPath.Combine(Work,'fixture-graph.json'),JSON(G),TEncoding.UTF8);
        Store:=TDPHKnowledgeStore.Create(TPath.Combine(Work,'semantic.dphdb'),Fixture,TPath.Combine(Root,'migrations'));
        try
          Store.InitializeProject('WP3 semantic fixture','Delphi'); Config:=Store.AddConfiguration('Win32','37.0','[]','[]','test'); Store.SelectConfiguration(Config);
          Variant:=A.Scan(TPath.Combine(Fixture,'Semantic.dproj'),'Debug','Win32',['FEATURE'],[],False);
          try
            Rejected:=False;
            try TDPHSemanticPersistence.Stage(Variant,G,Store,Config); except on E: EArgumentException do Rejected:=True; end;
            Check(Rejected,'STORE_CONTEXT','Same byte manifest cannot mix semantic facts from different defines');
          finally Variant.Free; end;
          Generation:=TDPHSemanticPersistence.Stage(Scan,G,Store,Config);
          Check(not TDPHSemanticPersistence.Publish(Scan,G,Store,Generation) and (Store.Status.PublishedGeneration=0),'STORE01','Partial semantic generation cannot become published head');
          Check(Store.IntegrityCheck='ok','STORE02','Semantic entities, evidence, relations and normalized CFG satisfy SQLite constraints');
        finally Store.Free; end;
        Check(Scan.Inventory.Revalidate,'SAFE01','Captured semantic fixture bytes remain unchanged');
        BeforeKey:=G.Symbols[Click].Key;
        GAgain:=S.Analyze(Scan); GAgain.Free;
        TFile.WriteAllText(TPath.Combine(Fixture,'Main.pas'),'// shifted source'+#10+TFile.ReadAllText(TPath.Combine(Fixture,'Main.pas')),TEncoding.UTF8);
        Again:=A.Scan(TPath.Combine(Fixture,'Semantic.dproj'),'Debug','Win32',['MSWINDOWS','WIN32'],[]);
        try GAgain:=S.Analyze(Again); try
          Check((GAgain.Symbols[Find(GAgain,'Main.TMain.Click','(integer):')].Key=BeforeKey) and (GAgain.Fingerprint<>G.Fingerprint),'IDENTITY01','Whitespace shift preserves symbol identity while changing provenance');
          Check((S.ReusedRoutines>0) and (S.RecomputedRoutines>0),'INC_CACHE03','Source change rebuilds affected file routines and reuses unaffected routines');
          GFull:=S.Analyze(Again,False);
          try Check(JSON(GAgain)=JSON(GFull),'INC_CACHE04','Affected routine reuse exactly matches an independent clean semantic rebuild'); finally GFull.Free; end;
        finally GAgain.Free; end; finally Again.Free; end;
      finally G.Free; end;
    finally Scan.Free; end;
    TFile.WriteAllText(TPath.Combine(Work,'Empty.dpr'),'program Empty; begin end.',TEncoding.UTF8);
    EmptyScan:=A.Scan(TPath.Combine(Work,'Empty.dpr'),'Debug','Win32',[],[]);
    try
      EmptyGraph:=S.Analyze(EmptyScan);
      try
        Store:=TDPHKnowledgeStore.Create(Work+'-empty.dphdb',Work,TPath.Combine(Root,'migrations'));
        try
          Store.InitializeProject('WP3 complete fixture','Delphi'); Config:=Store.AddConfiguration('Win32','37.0','[]','[]','test'); Store.SelectConfiguration(Config);
          Generation:=TDPHSemanticPersistence.Stage(EmptyScan,EmptyGraph,Store,Config);
          Check(TDPHSemanticPersistence.Publish(EmptyScan,EmptyGraph,Store,Generation),'STORE03','Complete empty fixture publishes atomically');
          Head:=Store.Status.PublishedGeneration;
          Check(Head=Generation,'STORE04','Published head points to the matching semantic generation');
          EmptyGraph.Complete:=False; Generation:=TDPHSemanticPersistence.Stage(EmptyScan,EmptyGraph,Store,Config);
          Check(not TDPHSemanticPersistence.Publish(EmptyScan,EmptyGraph,Store,Generation) and (Store.Status.PublishedGeneration=Head),'STORE05','Partial reassessment retains the previous complete head');
          Generation:=Store.BeginGeneration(Config,DPHSemanticVersion,EmptyScan.Inventory.Manifest);
          Entity:=Store.AddSourceEntity(Generation,'empty.dpr','cfg-test','routine','Entry','',0,0);
          OtherEntity:=Store.AddSourceEntity(Generation,'empty.dpr','cfg-test-other','routine','Other','',0,0);
          NodeID:=Store.AddFlowNode(Generation,Entity,'entry','{"source":"empty.dpr","start":0,"end":0}','');
          OtherNode:=Store.AddFlowNode(Generation,OtherEntity,'entry','{"source":"empty.dpr","start":0,"end":0}','');
          Rejected:=False; try Store.AddFlowEdge(Generation,NodeID,OtherNode,'next','confirmed_static'); except on E: EDPHStorage do Rejected:=True; end;
          Check(Rejected,'STORE_CFG01','CFG API rejects an edge between different routines');
          Rejected:=False; try Store.AddFlowNode(Generation,Entity,'bad','{"source":"empty.dpr","start":0,"end":9999}',''); except on E: EDPHStorage do Rejected:=True; end;
          Check(Rejected,'STORE_CFG02','CFG API rejects an out-of-capture byte range');
          Store.FailGeneration(Generation,'intentional negative tests');
          OtherGeneration:=Store.BeginGeneration(Config,DPHSemanticVersion,EmptyScan.Inventory.Manifest);
          Rejected:=False; try Store.AddFlowNode(OtherGeneration,Entity,'entry','{"source":"empty.dpr","start":0,"end":0}',''); except on E: EDPHStorage do Rejected:=True; end;
          Check(Rejected,'STORE_CFG03','CFG API rejects a routine without a version in this generation');
          Store.FailGeneration(OtherGeneration,'intentional negative tests');
          EmptyGraph.Complete:=True; Generation:=TDPHSemanticPersistence.Stage(EmptyScan,EmptyGraph,Store,Config);
          TFile.WriteAllText(TPath.Combine(Work,'Empty.dpr'),'program Empty; begin end.'+#10,TEncoding.UTF8);
          Check(not TDPHSemanticPersistence.Publish(EmptyScan,EmptyGraph,Store,Generation) and (Store.Status.PublishedGeneration=Head) and Store.Status.ReassessmentRequested,'STORE06','Mid-analysis source change supersedes semantics and requests reassessment');
          Check(Store.IntegrityCheck='ok','STORE07','Negative generation and CFG checks preserve database integrity');
        finally Store.Free; end;
      finally EmptyGraph.Free; end;
    finally EmptyScan.Free; end;
    TFile.WriteAllText(TPath.Combine(Work,'Entry.dpr'),'program Entry; begin MissingCall(); end.',TEncoding.UTF8);
    EmptyScan:=A.Scan(TPath.Combine(Work,'Entry.dpr'),'Debug','Win32',[],[]);
    try
      EmptyGraph:=S.Analyze(EmptyScan);
      try
        Found:=False; for I:=0 to EmptyGraph.Diagnostics.Count-1 do if EmptyGraph.Diagnostics[I].Code='CALL_TARGET_UNRESOLVED' then Found:=True;
        Check(Found and not EmptyGraph.Complete and (Find(EmptyGraph,'Entry.$entry','*')>=0),'UNCERTAIN03','Module entry is analyzed while its unresolved call remains explicitly partial');
      finally EmptyGraph.Free; end;
    finally EmptyScan.Free; end;
  finally S.Free; A.Free; end;
end;

procedure ReferenceTests;
var A: TDPHAnalyzer; S: TDPHSemanticAnalyzer; Scan,Again: TDPHScan; G,GAgain: TDPHSemanticGraph;
    Click,Worker,Convert,Callback,Report: Integer; R: TDPHRelation; N: TDPHFlowNode;
    Bound,DryRun,Rendered: Boolean; J: TJSONObject; Trace: TJSONArray; Row: TJSONObject;
begin
  A:=TDPHAnalyzer.Create; S:=TDPHSemanticAnalyzer.Create;
  try
    Scan:=A.Scan(TPath.Combine(Root,'samples\reference-vcl2fmx-v6.0.0\VCL2FMXConverter.dproj'),'Debug','Win32',['MSWINDOWS','WIN32'],[],False);
    try
      G:=S.Analyze(Scan);
      try
        Click:=Find(G,'MainForm.TfrmMain.btnConvertClick','(tobject):');
        Worker:=Find(G,'MainForm.TfrmMain.ConversionThreadProc','*'); Convert:=Find(G,'Converter.Core.Engine.TConverterEngine.Convert','(tconversioncontext):boolean');
        Callback:=Find(G,'MainForm.TfrmMain.btnConvertClick.$callback0','():');
        Bound:=False; for R in G.Relations do if (R.Kind='binds') and (R.ToSymbol=Click) and (R.Resolution='confirmed_static') then Bound:=True;
        Check((Click>=0) and Bound,'REF01','Reference btnConvert.OnClick resolves to btnConvertClick');
        Check((Callback>=0) and Relation(G,Click,Callback,'prepares_callback','possible_dynamic'),'REF02','Reference anonymous worker creation is distinct from its later handle Start');
        Check(Relation(G,Callback,Worker,'calls','confirmed_static') and Relation(G,Worker,Convert,'calls','confirmed_static'),'REF03','Reference callback resolves through ConversionThreadProc to Engine.Convert');
        DryRun:=False; for N in G.FlowNodes do if (N.Routine=Convert) and (N.Kind='if') and (Pos('DryRunPreview',N.ExpressionText)>0) then DryRun:=True;
        Check(DryRun,'REF04','DryRunPreview condition is located in engine control flow');
        Report:=Find(G,'Converter.Core.Engine.TConverterEngine.GenerateReport','():'); Rendered:=False;
        for R in G.Relations do if (R.FromSymbol=Report) and (R.Kind='renders') and (R.Resolution='inferred') then Rendered:=True;
        Check(Rendered,'REF05','Report model-to-renderer relationship has typed static evidence');
        Check(not G.Complete and (G.Diagnostics.Count>0),'REF06','Missing framework and opaque constructs keep reference analysis partial');
        Again:=A.Scan(TPath.Combine(Root,'samples\reference-vcl2fmx-v6.0.0\VCL2FMXConverter.dproj'),'Debug','Win32',['MSWINDOWS','WIN32'],[]);
        try GAgain:=S.Analyze(Again); try
          TFile.WriteAllText(TPath.Combine(Work,'reference-full.json'),JSON(G),TEncoding.UTF8);
          TFile.WriteAllText(TPath.Combine(Work,'reference-cached.json'),JSON(GAgain),TEncoding.UTF8);
          Check(JSON(G)=JSON(GAgain),'REF07','Full and incremental reference graphs are exactly equivalent, including bounded cache fallback');
        finally GAgain.Free; end; finally Again.Free; end;
        Check(Scan.Inventory.Revalidate,'REF08','Reference capture rehashes unchanged after semantics');
        J:=TJSONObject.Create;
        try
          J.AddPair('reference_commit','e1fd10b2d3b06f2fc3f726b8eb7f234a54faf63d'); J.AddPair('input_fingerprint',G.Fingerprint);
          J.AddPair('complete',TJSONBool.Create(G.Complete)); J.AddPair('symbol_count',TJSONNumber.Create(G.Symbols.Count));
          J.AddPair('relationship_count',TJSONNumber.Create(G.Relations.Count)); J.AddPair('cfg_nodes',TJSONNumber.Create(G.FlowNodes.Count));
          J.AddPair('diagnostics',TJSONNumber.Create(G.Diagnostics.Count)); Trace:=TJSONArray.Create; J.AddPair('demonstration_trace',Trace);
          for R in G.Relations do if ((R.Kind='binds') and (R.ToSymbol=Click)) or
            ((R.FromSymbol=Click) and (R.ToSymbol=Callback)) or ((R.FromSymbol=Callback) and (R.ToSymbol=Worker)) or
            ((R.FromSymbol=Worker) and (R.ToSymbol=Convert)) or ((R.FromSymbol=Report) and (R.Kind='renders')) then
          begin
            Row:=TJSONObject.Create; Trace.AddElement(Row); Row.AddPair('from',G.Symbols[R.FromSymbol].Key);
            Row.AddPair('to',G.Symbols[R.ToSymbol].Key); Row.AddPair('kind',R.Kind); Row.AddPair('resolution',R.Resolution);
            Row.AddPair('rule',R.Rule); Row.AddPair('range',DPHRangeJSON(R.Location)); Row.AddPair('source_hash',G.SourceHashes[R.Location.Source]);
          end;
          TFile.WriteAllText(TPath.Combine(Root,'docs\wp3-reference-validation.json'),J.Format,TEncoding.UTF8);
        finally J.Free; end;
        TFile.WriteAllText(TPath.Combine(Work,'reference-graph.json'),JSON(G),TEncoding.UTF8);
      finally G.Free; end;
    finally Scan.Free; end;
  finally S.Free; A.Free; end;
end;

var Path,Destination: string; Report: TJSONObject; ID: TGUID;
begin
  CoInitialize(nil); Rows:=TJSONArray.Create;
  try
    try
      Root:=TPath.GetFullPath(ParamStr(1)); CreateGUID(ID); Work:=TPath.Combine(Root,'bin\wp3-tests-'+GUIDToString(ID)); TDirectory.CreateDirectory(Work);
      Fixture:=TPath.Combine(Work,'fixture'); TDirectory.CreateDirectory(Fixture);
      for Path in TDirectory.GetFiles(TPath.Combine(Root,'tests\fixtures\semantics')) do
      begin Destination:=TPath.Combine(Fixture,ExtractFileName(Path)); TFile.Copy(Path,Destination); end;
      FixtureTests; AsyncDetailTests; FlowDetailTests; StartupTests; ResolutionTests; CacheBindingTests; DefinitionTests; ReferenceTests;
      Report:=TJSONObject.Create;
      try Report.AddPair('analyzer',DPHSemanticVersion); Report.AddPair('checks_passed',TJSONNumber.Create(Checks)); Report.AddPair('checks',Rows); Rows:=nil;
        TFile.WriteAllText(TPath.Combine(Root,'docs\wp3-validation.json'),Report.Format,TEncoding.UTF8);
      finally Report.Free; end;
      Writeln('PASS WP3: ',Checks,' checks; evidence: ',Work);
    except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode:=1; end; end;
  finally Rows.Free; CoUninitialize; end;
end.
