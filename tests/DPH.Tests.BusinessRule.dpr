program DPH.Tests.BusinessRule;
{$APPTYPE CONSOLE}
uses System.Types,System.SysUtils,System.Classes,System.IOUtils,System.JSON,System.Hash,System.StrUtils,System.UITypes,
 FMX.Forms,FMX.Graphics,DPH.Project.Analysis,DPH.Analysis.Model,DPH.Analysis.Symbols,
 DPH.Workspace.Model,DPH.UI.Main,DPH.Storage.Database,DPH.Analysis.Persistence,DPH.Workspace.Catalog,DPH.Publish.Model,DPH.Publish.Export;
var Root,Work,Fixture,Body,Metadata,RuleTitle,SourceHash,Catalog,CatalogHash,Before,DatabaseName:string;
 I,Checks:Integer;Config,Generation,RuleID,Revision,OldRevision,ProcedureID:Int64;
 Analyzer:TDPHAnalyzer;Semantic:TDPHSemanticAnalyzer;Scan:TDPHScan;Graph:TDPHSemanticGraph;
 View:TDPHWorkspaceView;Store:TDPHKnowledgeStore;Form:TDPHMainForm;Bitmap:TBitmap;Model:TDPHDocumentModel;
 Rows,Links,Policies:TJSONArray;
ExtraID,ExtraRevision:Int64;ErrorText:string;Row,RecordValue,Log:TJSONObject;Value:TJSONValue;Denied:Boolean;
procedure Check(OK:Boolean;const MessageText:string);
begin if not OK then raise Exception.Create('FAIL '+MessageText);Inc(Checks);Writeln('PASS ',Checks,': ',MessageText);Flush(Output);end;
function LoadRule:TJSONObject;
var A:TJSONArray;V:TJSONValue;
begin Result:=nil;A:=Store.KnowledgeJSON;try for V in A do if V.GetValue<string>('id')=IntToStr(RuleID) then Exit(V.Clone as TJSONObject);finally A.Free;end;end;
function SaveRule(ID,Expected:Int64;const Title,Text,Author,Kind,Document,Audience,LinkJSON,Structured:string):Boolean;
begin Result:=False;try Store.SaveKnowledge(ID,Expected,Generation,Title,Text,Author,Kind,'',Document,Audience,LinkJSON,'',Structured);except on E:Exception do Result:=True;end;end;
procedure Render(const Name:string);
begin Application.ProcessMessages;Bitmap:=TBitmap.Create(Form.ClientWidth,Form.ClientHeight);try
 if Bitmap.Canvas.BeginScene then try Form.PaintTo(Bitmap.Canvas);finally Bitmap.Canvas.EndScene;end;
 Bitmap.SaveToFile(TPath.Combine(Root,'docs\'+Name));finally Bitmap.Free;end;end;
begin
 Application.Initialize;
 try
 Root:=TPath.GetFullPath(ParamStr(1));Work:=TPath.Combine(Root,'bin\business-rule-validation');Fixture:=TPath.Combine(Work,'source');TDirectory.CreateDirectory(Fixture);
 TFile.WriteAllText(TPath.Combine(Fixture,'Operations.dpr'),'program Operations; uses Main; begin end.',TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(Fixture,'Main.pas'),'unit Main; interface implementation procedure FulfilOrders; begin end; end.',TEncoding.UTF8);
 SourceHash:=THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'Main.pas'));
 Analyzer:=TDPHAnalyzer.Create;Semantic:=TDPHSemanticAnalyzer.Create;
 try Scan:=Analyzer.Scan(TPath.Combine(Fixture,'Operations.dpr'),'Debug','Win32',[],[],False);
 try Graph:=Semantic.Analyze(Scan);
 try Store:=TDPHKnowledgeStore.Create(TPath.Combine(Work,'rule-'+TGUID.NewGuid.ToString+'.dphdb'),Fixture,TPath.Combine(Root,'migrations'));
 try Store.InitializeProject('Controlled target recovery requirements','Delphi');Config:=Store.AddConfiguration('Win32','37.0','[]','[]','Debug');Store.SelectConfiguration(Config);
 Generation:=TDPHSemanticPersistence.Stage(Scan,Graph,Store,Config);View:=TDPHWorkspaceView.Create(TDPHWorkspaceView.Capture(Scan,Graph,Generation,'Operations.dpr','Debug','Win32',[],[]));
 try Store.SaveWorkspaceView(Generation,View.Document.ToJSON);TDPHSemanticPersistence.Publish(Scan,Graph,Store,Generation);Before:=View.Document.ToJSON;
 RecordValue:=TDPHWorkspaceView.NewBusinessRule;
 try
  Row:=RecordValue.GetValue<TJSONObject>('fields');
  Row.RemovePair('rule_code').Free;Row.AddPair('rule_code','BR-001');
  Row.RemovePair('name').Free;Row.AddPair('name','Credit approval rule');
  Row.RemovePair('owner').Free;Row.AddPair('owner','Operations manager');
  Row.RemovePair('scope').Free;Row.AddPair('scope','Orders requiring credit approval');
  Row.RemovePair('outcomes').Free;Row.AddPair('outcomes','Hold order and request approval');
  Row.RemovePair('conditions').Free;Row.AddPair('conditions','Order total exceeds the approved credit limit');
  TDPHWorkspaceView.ValidateBusinessRule(RecordValue);Metadata:=RecordValue.ToJSON;
  Body:=TDPHWorkspaceView.BusinessRuleBody(RecordValue);RuleTitle:='Credit approval rule';
  Check(Body.Contains('Orders requiring credit approval'),'Structured rule inputs rendered');
  Check(Body.Contains('Hold order and request approval'),'Structured rule outputs rendered');
  Check(Body.Contains('Operations manager'),'Accountable owner rendered separately from contributor');
  Check(Body.Contains('Conditions and prerequisites'),'Structured ordered steps rendered');
  Check(Body.Contains('Business exceptions and recovery: Unknown'),'Missing department remains explicitly unknown');
  Check(Body.Contains('not observed execution'),'Business rule qualification retained');
 finally RecordValue.Free;end;
 Check(SaveRule(0,0,RuleTitle,Body,'','business_rule','maintenance','maintainer','',Metadata),'Anonymous rule author rejected');
 Check(SaveRule(0,0,'Incorrect title',Body,'Author','business_rule','maintenance','maintainer','',Metadata),'Placeholder title rejected');
 Check(SaveRule(0,0,RuleTitle,'Rule heading removed','Author','business_rule','maintenance','maintainer','',Metadata),'Removed rule heading rejected');
 Check(SaveRule(0,0,RuleTitle,Body,'Author','engineering_rule','maintenance','maintainer','',Metadata),'Incorrect rule kind rejected');
 Check(SaveRule(0,0,RuleTitle,Body,'Author','business_rule','user','user','',Metadata),'Incorrect rule audience rejected');
 RecordValue:=TJSONObject.ParseJSONValue(Metadata) as TJSONObject;try RecordValue.RemovePair('rule_id').Free;RecordValue.AddPair('rule_id','invalid');Check(SaveRule(0,0,RuleTitle,Body,'Author','business_rule','maintenance','maintainer','',RecordValue.ToJSON),'Invalid stable rule identity rejected');finally RecordValue.Free;end;
 RecordValue:=TJSONObject.ParseJSONValue(Metadata) as TJSONObject;try RecordValue.AddPair('unexpected','x');Check(SaveRule(0,0,RuleTitle,Body,'Author','business_rule','maintenance','maintainer','',RecordValue.ToJSON),'Unknown rule metadata rejected');finally RecordValue.Free;end;
 RecordValue:=TJSONObject.ParseJSONValue(Metadata) as TJSONObject;try Row:=RecordValue.GetValue<TJSONObject>('fields');Row.RemovePair('scope').Free;Row.AddPair('scope','');Check(SaveRule(0,0,RuleTitle,Body,'Author','business_rule','maintenance','maintainer','',RecordValue.ToJSON),'Empty structured inputs rejected; Unknown must be explicit');finally RecordValue.Free;end;
 RecordValue:=TJSONObject.ParseJSONValue(Metadata) as TJSONObject;try Row:=RecordValue.GetValue<TJSONObject>('fields');Row.RemovePair('owner').Free;Row.AddPair('owner',TJSONNumber.Create(1));Check(SaveRule(0,0,RuleTitle,Body,'Author','business_rule','maintenance','maintainer','',RecordValue.ToJSON),'Numeric owner rejected');finally RecordValue.Free;end;
 RecordValue:=TJSONObject.ParseJSONValue(Metadata) as TJSONObject;try Row:=RecordValue.GetValue<TJSONObject>('fields');Row.RemovePair('conditions').Free;Row.AddPair('conditions',StringOfChar('x',4097));Check(SaveRule(0,0,RuleTitle,Body,'Author','business_rule','maintenance','maintainer','',RecordValue.ToJSON),'Oversized structured field rejected');finally RecordValue.Free;end;
 RecordValue:=TJSONObject.ParseJSONValue(Metadata) as TJSONObject;try RecordValue.RemovePair('rule_id').Free;RecordValue.AddPair('rule_id',StringToGUID('{ABCDEFAB-1234-1234-1234-ABCDEFABCDEF}').ToString.ToLower);Check(SaveRule(0,0,RuleTitle,Body,'Author','business_rule','maintenance','maintainer','',RecordValue.ToJSON),'Noncanonical GUID spelling rejected to prevent duplicate identities');finally RecordValue.Free;end;
 Links:=TJSONArray.Create;
 try Rows:=Store.LinkCandidates(Generation,'entity','FulfilOrders');try
 Row:=nil;for Value in Rows do if View.Symbol(Value.GetValue<string>('canonical_key'))<>nil then begin Row:=Value.Clone as TJSONObject;Break;end;
 Check(Row<>nil,'Actual captured semantic implementation routine available');Row.AddPair('link_role','depends_on');Links.AddElement(Row);finally Rows.Free;end;
 ProcedureID:=Store.SaveKnowledge(0,0,Generation,'Order fulfilment procedure','Controlled order fulfilment procedure; source evidence only. No execution.','Procedure author','maintenance','','maintenance','maintainer');
 Rows:=Store.LinkCandidates(Generation,'section','Order fulfilment procedure');try Row:=Rows.Items[0].Clone as TJSONObject;Row.AddPair('link_role','cites');Links.AddElement(Row);finally Rows.Free;end;
 RuleID:=Store.SaveKnowledge(0,0,Generation,RuleTitle,Body,'Rule author','business_rule','','maintenance','maintainer',Links.ToJSON,'',Metadata);
 finally Links.Free;end;
 Row:=LoadRule;try Revision:=StrToInt64(Row.GetValue<string>('revision'));
 Check(TDPHWorkspaceView.IsBusinessRule(Row),'Typed persisted rule recognized');Check(Row.GetValue<string>('owner')='Rule author','Named contributor persists');Check(Row.GetValue<string>('state')='needs_review','Saved rule remains pending review');
 Check(Row.GetValue<TJSONArray>('rich_links').Count=2,'Routine and exact procedure-revision links persist');
 Check(Row.GetValue<string>('body').Contains('Orders requiring credit approval'),'Structured rule inputs persist');Check(Row.GetValue<string>('body').Contains('Unknown'),'Unresolved fields stay explicit');
 Check(TDPHWorkspaceView.DescribeBusinessRule(Row).Contains('Explicit implementation/evidence links: 2'),'Inspector distinguishes resolved link count');
 finally Row.Free;end;
 Check(SaveRule(0,0,RuleTitle,Body,'Author','business_rule','maintenance','maintainer','',Metadata),'Duplicate rule identity rejected');
 Check(SaveRule(RuleID,Revision,RuleTitle,Body,'Author','business_rule','maintenance','maintainer','','{}'),'Typed metadata cannot be discarded');
 RecordValue:=TJSONObject.ParseJSONValue(Metadata) as TJSONObject;RecordValue.RemovePair('rule_id').Free;RecordValue.AddPair('rule_id',TGUID.NewGuid.ToString);try Check(SaveRule(RuleID,Revision,RuleTitle,Body,'Author','business_rule','maintenance','maintainer','',RecordValue.ToJSON),'Saved rule identity cannot change');finally RecordValue.Free;end;
 Denied:=False;try Store.ReviewKnowledge(RuleID,Revision,Generation,'','verified');except Denied:=True;end;Check(Denied,'Anonymous rule review rejected');
 OldRevision:=Revision;Store.ReviewKnowledge(RuleID,Revision,Generation,'Rule reviewer','verified');Row:=LoadRule;try Revision:=StrToInt64(Row.GetValue<string>('revision'));Check(Row.GetValue<string>('reviewer')='Rule reviewer','Named reviewer persists');Check(Row.GetValue<TJSONArray>('history').Count=2,'Review appends immutable history');Check(Row.GetValue<TJSONArray>('rich_links').Count=2,'Review retains exact implementation links');finally Row.Free;end;
 Check(SaveRule(RuleID,OldRevision,RuleTitle,Body,'Editor','business_rule','maintenance','maintainer','',Metadata),'Stale rule edit rejected');
 RecordValue:=TJSONObject.ParseJSONValue(Metadata) as TJSONObject;
 try
  Row:=RecordValue.GetValue<TJSONObject>('fields');Row.RemovePair('outcomes').Free;Row.AddPair('outcomes','Dispatch confirmation and tracking number');
  Metadata:=RecordValue.ToJSON;Body:=TDPHWorkspaceView.BusinessRuleBody(RecordValue);
 finally RecordValue.Free;end;
 Store.SaveKnowledge(RuleID,Revision,Generation,RuleTitle,Body,'Second author','business_rule','','maintenance','maintainer','','',Metadata);
 Row:=LoadRule;try Check(Row.GetValue<string>('state')='needs_review','Rule edits reopen review');Check(Row.GetValue<TJSONArray>('history').Count=3,'Prior reviewed rule retained');Check(Row.GetValue<TJSONArray>('rich_links').Count=2,'Rule revision preserves implementation links');Check(Row.GetValue<string>('body').Contains('tracking number'),'Changed structured output persists');finally Row.Free;end;
 Row:=LoadRule;try Revision:=StrToInt64(Row.GetValue<string>('revision'));finally Row.Free;end;
 Check(SaveRule(RuleID,Revision,RuleTitle,Body+sLineBreak+'invented prose','Editor','business_rule','maintenance','maintainer','',Metadata),'Structured rule body cannot diverge from fields');
 Check(Store.IntegrityCheck='ok','Rule database integrity valid');
 RecordValue:=TJSONObject.ParseJSONValue(Metadata) as TJSONObject;
 try
  RecordValue.RemovePair('rule_id').Free;RecordValue.AddPair('rule_id',TGUID.NewGuid.ToString);
  Row:=RecordValue.GetValue<TJSONObject>('fields');Row.RemovePair('rule_code').Free;Row.AddPair('rule_code','br-001');
  ErrorText:='';
  try Store.SaveKnowledge(0,0,Generation,RuleTitle,TDPHWorkspaceView.BusinessRuleBody(RecordValue),'Independent author','business_rule','','maintenance','maintainer','','',RecordValue.ToJSON);except on E:Exception do ErrorText:=E.Message;end;
  Check(ErrorText.Contains('identifier already exists'),'Rule codes unique ignoring ASCII case across distinct GUIDs');
 finally RecordValue.Free;end;
 RecordValue:=TJSONObject.ParseJSONValue(Metadata) as TJSONObject;
 try
  Row:=RecordValue.GetValue<TJSONObject>('fields');Row.RemovePair('rule_code').Free;Row.AddPair('rule_code','BR-CHANGED');
  ErrorText:='';
  try Store.SaveKnowledge(RuleID,Revision,Generation,RuleTitle,TDPHWorkspaceView.BusinessRuleBody(RecordValue),'Editor','business_rule','','maintenance','maintainer','','',RecordValue.ToJSON);except on E:Exception do ErrorText:=E.Message;end;
  Check(ErrorText.Contains('identifier cannot change'),'Saved human rule identifier immutable across revisions');
 finally RecordValue.Free;end;
 for ErrorText in ['Unknown','contains spaces','<script>','',StringOfChar('X',101),'BR-001'+#10] do begin
  RecordValue:=TJSONObject.ParseJSONValue(Metadata) as TJSONObject;
  try Row:=RecordValue.GetValue<TJSONObject>('fields');Row.RemovePair('rule_code').Free;Row.AddPair('rule_code',ErrorText);Denied:=False;
   try TDPHWorkspaceView.ValidateBusinessRule(RecordValue);except Denied:=True;end;
   Check(Denied,'Invalid or unresolved human rule code rejected');
  finally RecordValue.Free;end;
 end;

 Rows:=Store.KnowledgeJSON;try Model:=TDPHDocumentModel.Create(View,Rows,[],[],False,False,nil,False,'maintainer');
 try
 Check(Model.Document.ToJSON.Contains('Credit approval rule'),'Maintainer publication includes authored rule');
 Check(Model.Document.ToJSON.Contains('business_rule_definition'),'Canonical handoff preserves typed rule identity');
 if TDirectory.Exists(TPath.Combine(Work,'handoff')) then begin
  RecordValue:=TJSONObject.ParseJSONValue(TFile.ReadAllText(TPath.Combine(Work,'handoff\manifest.json'),TEncoding.UTF8)) as TJSONObject;
  try if RecordValue.GetValue<string>('project','')<>'Operations.dpr' then raise Exception.Create('Refusing to replace an unrelated test export');finally RecordValue.Free;end;
  TDirectory.Delete(TPath.Combine(Work,'handoff'),True);
 end;
 TDPHPublisher.Export(Model,Store,TPath.Combine(Work,'handoff'));
 TDPHPublisher.Validate(TPath.Combine(Work,'handoff'),Model.Document.GetValue<string>('input_fingerprint'));
 Check(True,'Business rule handoff passes full bundle validation');
 Check(TFile.ReadAllText(TPath.Combine(Work,'handoff\index.html'),TEncoding.UTF8).Contains('Orders requiring credit approval'),'Published HTML includes structured inputs');
 finally Model.Free;end;finally Rows.Free;end;
 DatabaseName:=Store.DatabasePath;FreeAndNil(Store);Store:=TDPHKnowledgeStore.Create(DatabaseName,Fixture,TPath.Combine(Root,'migrations'));Store.SelectConfiguration(Config);
 Row:=LoadRule;try Check(Row<>nil,'Business rule survives database close and reopen');Check(Row.GetValue<string>('structured_json')=Metadata,'Exact structured fields survive reopening');Check(Row.GetValue<TJSONArray>('history').Count=3,'Immutable review and edit history survives reopening');Check(Row.GetValue<TJSONArray>('rich_links').Count=2,'Exact source and procedure links survive reopening');finally Row.Free;end;
 Catalog:=TDPHWorkspaceCatalog.DefaultPath;CatalogHash:='';if TFile.Exists(Catalog) then CatalogHash:=THashSHA2.GetHashStringFromFile(Catalog);
 Form:=TDPHMainForm.Create(nil);
 try Form.PollTimer.Enabled:=False;Form.ChangeTimer.Enabled:=False;Form.LoadView(View.Document.Clone as TJSONObject);Form.LoadKnowledge(Store.KnowledgeJSON);
 Check(Form.BusinessRuleList.Count=1,'Native register includes rule and excludes unrelated procedure');Check(Form.BusinessRuleMemo.Text.Contains('Second author'),'Native inspector shows current contributor');
 Form.PendingKnowledgeCheck.IsChecked:=True;Form.BusinessRuleOpenClick(nil);Check(Form.WorkspaceTabs.ActiveTab=Form.KnowledgeTab,'Open plan enters saved Knowledge workflow');Check(Form.KnowledgeBodyMemo.ReadOnly,'Saved structured body protected from free text edits');Check(Form.KnowledgeTitleEdit.ReadOnly,'Saved stable title protected');Check(not Form.KnowledgeKindCombo.Enabled,'Saved rule kind protected');
 Form.BusinessRuleOpenClick(Form.BusinessRuleLinks);Check(Form.WorkspaceTabs.ActiveTab=Form.KnowledgeLinksTab,'Implementation links opens exact link workflow');Check(Form.KnowledgeLinksList.Count=2,'Native exact implementation links available');Form.KnowledgeLinksList.ItemIndex:=0;Form.OpenKnowledgeLinkClick(nil);Check(Form.WorkspaceTabs.ActiveTab=Form.ExplainTab,'Saved implementation routine opens captured explanation');
 Form.BusinessRuleEditClick(nil);Check(Form.WorkspaceTabs.ActiveTab=Form.BusinessRuleEditorTab,'Edit opens native structured fields');Check(Form.Rule_scope.Text='Orders requiring credit approval','Native editor restores persisted input');Check(Form.Rule_name.ReadOnly,'Saved rule name remains stable');
 Form.Show;Render('phase1-business-rule-editor.png');Form.WindowState:=TWindowState.wsNormal;Form.Width:=960;Form.Height:=600;Render('phase1-business-rule-editor-compact.png');Check(Form.BusinessRuleEditorToolbar.ShowScrollBars,'Compact editor commands scroll horizontally');Form.BusinessRuleEditorScroll.ViewportPosition:=PointF(0,700);Render('phase1-business-rule-editor-bottom.png');Check(Form.Rule_unknowns.Height>50,'Unknowns field retains editable height');Form.Hide;
 Form.Rule_outcomes.Text:='Revised native output';Form.Rule_rule_code.Text:='BR-NATIVE-002';Form.BusinessRuleAuthor.Text:='Native contributor';Form.BusinessRuleApplyClick(nil);Check(Form.WorkspaceTabs.ActiveTab=Form.KnowledgeTab,'Apply prepares Knowledge draft');Check(Form.KnowledgeBodyMemo.Text.Contains('Revised native output'),'Native structured edit generates canonical body');
 Body:=Form.KnowledgeBodyMemo.Text;Form.BusinessRuleOpenClick(nil);Check(Form.KnowledgeBodyMemo.Text=Body,'Unsaved structured draft protected from selection');Form.BusinessRuleNewClick(nil);Check(Form.StatusLabel.Text.Contains('Save or discard'),'Unsaved structured draft protected from replacement');Form.DiscardKnowledgeClick(nil);
 Form.BusinessRuleNewClick(nil);Check(Form.WorkspaceTabs.ActiveTab=Form.BusinessRuleEditorTab,'New rule opens structured editor');Check(not Form.Rule_name.ReadOnly,'New rule name editable');
 Form.Rule_name.Text:='Anonymous fixture';Form.Rule_rule_code.Text:='BR-ANON-002';Form.BusinessRuleAuthor.Text:='';Form.BusinessRuleApplyClick(nil);Check(Form.WorkspaceTabs.ActiveTab=Form.BusinessRuleEditorTab,'Anonymous contributor keeps rule in editor');
 Form.Rule_name.Text:='Native rule';Form.Rule_rule_code.Text:='BR-NATIVE-002';Form.BusinessRuleAuthor.Text:='Native contributor';Form.BusinessRuleApplyClick(nil);Check(Form.KnowledgeBodyMemo.Text.Contains('BUSINESS RULE'),'New native rule canonical body prepared');Check(Form.KnowledgeBodyMemo.ReadOnly,'Canonical draft body protected');Form.DiscardKnowledgeClick(nil);
 Form.BusinessRuleState.ItemIndex:=2;Form.BusinessRuleFilterChange(nil);Check(Form.BusinessRuleList.Count=0,'Review-state filter respects pending edit');Form.BusinessRuleState.ItemIndex:=0;Form.BusinessRuleFilter.Text:='credit approval';Form.BusinessRuleFilterChange(nil);Check(Form.BusinessRuleList.Count=1,'Rule text search finds authored input');
 Form.BusinessRuleFilter.Text:='absent';Form.BusinessRuleFilterChange(nil);Check(Form.BusinessRuleMemo.Text.Contains('Empty results do not prove'),'Empty register explains unresolved obligations');Check(not Form.BusinessRuleOpen.Enabled,'Empty results disable opening');
 Form.BusinessRuleFilter.Text:='';Form.BusinessRuleFilterChange(nil);Form.WorkspaceTabs.ActiveTab:=Form.BusinessRuleTab;Form.Show;Render('phase1-business-rule-workspace.png');Form.WindowState:=TWindowState.wsNormal;Form.Width:=960;Form.Height:=600;Render('phase1-business-rule-compact.png');Check(Form.BusinessRuleMemo.Height>=50,'Compact rule detail remains readable');Check(Form.BusinessRuleToolbar.ShowScrollBars and Form.BusinessRuleMemo.ShowScrollBars,'Compact commands and long policies scroll');Form.Hide;
 Policies:=TJSONArray.Create;Row:=LoadRule;try for I:=1 to 270 do begin RecordValue:=Row.Clone as TJSONObject;Policies.AddElement(RecordValue);end;finally Row.Free;end;Form.LoadKnowledge(Policies);Check(Form.BusinessRuleList.Count=250,'Large register first page bounded');Check(Form.BusinessRuleNext.Enabled,'Large register next page accessible');Form.BusinessRuleFilterChange(Form.BusinessRuleNext);Check(Form.BusinessRuleList.Count=20,'Remaining rule rows accessible');

 ExtraID:=Store.SaveKnowledge(0,0,Generation,'Legacy dispatch rule','Original unstructured rule body; preserve its attribution.','Legacy author','business_rule','','maintenance','maintainer');
 Form.LoadKnowledge(Store.KnowledgeJSON);Form.BusinessRuleFilter.Text:='Legacy dispatch';Form.BusinessRuleFilterChange(nil);
 Check(Form.BusinessRuleList.Count=1,'Unstructured original business-rule notes remain in catalog');
 Check(Form.BusinessRuleList.Items[0].Contains('Unstructured'),'Legacy notes clearly distinguish missing structured identifiers');
 Check(not Form.BusinessRuleEdit.Enabled,'Legacy note cannot silently become a typed rule');
 Form.BusinessRuleOpenClick(nil);Check(Form.KnowledgeBodyMemo.Text.Contains('Original unstructured'),'Open record preserves original legacy text');
 Form.BusinessRuleFilter.Text:='BR-001';Form.BusinessRuleFilterChange(nil);
 Check(Form.BusinessRuleList.Count=1,'Native catalog searches stable rule identifier');
 Form.BusinessRuleFilter.Text:='';Form.BusinessRuleFilterChange(nil);
 Form.LoadKnowledge(nil);Check(Form.BusinessRuleList.Count=0,'Clearing loaded knowledge removes prior rule rows');
 finally Form.Free;end;
 Form:=TDPHMainForm.Create(nil);try Form.PollTimer.Enabled:=False;Form.ChangeTimer.Enabled:=False;Check(not Form.BusinessRuleNew.Enabled,'No capture disables new rule');finally Form.Free;end;
 Check(View.Document.ToJSON=Before,'Rule workflow leaves captured workspace unchanged');Check(THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'Main.pas'))=SourceHash,'Target source unchanged');Check((not TFile.Exists(Catalog) and (CatalogHash='')) or (TFile.Exists(Catalog) and (THashSHA2.GetHashStringFromFile(Catalog)=CatalogHash)),'Owner catalog unchanged');
 Log:=TJSONObject.Create.AddPair('result','PASS').AddPair('checks',TJSONNumber.Create(Checks)).AddPair('qualification','Structured attributed business-rule catalog with unique immutable identifiers, applicability, conditions, outcomes, exceptions, accountable owners, approval responsibilities and exact source/procedure links. Original unstructured notes remain distinguishable. Target execution and business outcomes remain unverified.');try TFile.WriteAllText(TPath.Combine(Root,'docs\validation\reports\phase1-business-rule-validation.json'),Log.Format,TEncoding.UTF8);finally Log.Free;end;
 finally View.Free;end;finally Store.Free;end;finally Graph.Free;end;finally Scan.Free;end;finally Semantic.Free;Analyzer.Free;end;
 except on E:Exception do begin Writeln(E.ClassName,': ',E.Message);ExitCode:=1;end;end;
end.
