program DPH.Tests.DepartmentalWorkflow;

{$APPTYPE CONSOLE}
uses System.Types,System.SysUtils,System.Classes,System.IOUtils,System.JSON,System.Hash,System.StrUtils,System.UITypes,
 FMX.Forms,FMX.Graphics,DPH.Project.Analysis,DPH.Analysis.Model,DPH.Analysis.Symbols,
 DPH.Workspace.Model,DPH.UI.Main,DPH.Storage.Database,DPH.Analysis.Persistence,DPH.Workspace.Catalog,DPH.Publish.Model,DPH.Publish.Export;

var Root,Work,Fixture,Body,Metadata,WorkflowTitle,SourceHash,Catalog,CatalogHash,Before,DatabaseName:string;

 I,Checks:Integer;
Config,Generation,WorkflowID,Revision,OldRevision,ProcedureID:Int64;

 Analyzer:TDPHAnalyzer;
Semantic:TDPHSemanticAnalyzer;
Scan:TDPHScan;
Graph:TDPHSemanticGraph;

 View:TDPHWorkspaceView;
Store:TDPHKnowledgeStore;
Form:TDPHMainForm;
Bitmap:TBitmap;
Model:TDPHDocumentModel;

 Rows,Links,Policies:TJSONArray;
Row,RecordValue,Log,Step:TJSONObject;
Value:TJSONValue;
Denied:Boolean;

procedure Check(OK:Boolean;
const MessageText:string);

begin if not OK then raise Exception.Create('FAIL '+MessageText);
Inc(Checks);
Writeln('PASS ',Checks,': ',MessageText);
Flush(Output);
end;

function LoadWorkflow:TJSONObject;

var A:TJSONArray;
V:TJSONValue;

begin Result:=nil;
A:=Store.KnowledgeJSON;
try for V in A do if V.GetValue<string>('id')=IntToStr(WorkflowID) then Exit(V.Clone as TJSONObject);
finally A.Free;
end;
end;

function SaveWorkflow(ID,Expected:Int64;
const Title,Text,Author,Kind,Document,Audience,LinkJSON,Structured:string):Boolean;

begin Result:=False;
try Store.SaveKnowledge(ID,Expected,Generation,Title,Text,Author,Kind,'',Document,Audience,LinkJSON,'',Structured);
except on E:Exception do Result:=True;
end;
end;

procedure Render(const Name:string);

begin Application.ProcessMessages;
Bitmap:=TBitmap.Create(Form.ClientWidth,Form.ClientHeight);
try
 if Bitmap.Canvas.BeginScene then try Form.PaintTo(Bitmap.Canvas);
finally Bitmap.Canvas.EndScene;
end;

 Bitmap.SaveToFile(TPath.Combine(Root,'docs\'+Name));
finally Bitmap.Free;
end;
end;

begin
 Application.Initialize;

 try
 Root:=TPath.GetFullPath(ParamStr(1));
Work:=TPath.Combine(Root,'bin\departmental-workflow-validation');
Fixture:=TPath.Combine(Work,'source');
TDirectory.CreateDirectory(Fixture);

 TFile.WriteAllText(TPath.Combine(Fixture,'Operations.dpr'),'program Operations; uses Main; begin end.',TEncoding.UTF8);

 TFile.WriteAllText(TPath.Combine(Fixture,'Main.pas'),'unit Main; interface implementation procedure FulfilOrders; begin end; end.',TEncoding.UTF8);

 SourceHash:=THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'Main.pas'));

 Analyzer:=TDPHAnalyzer.Create;
Semantic:=TDPHSemanticAnalyzer.Create;

 try Scan:=Analyzer.Scan(TPath.Combine(Fixture,'Operations.dpr'),'Debug','Win32',[],[],False);

 try Graph:=Semantic.Analyze(Scan);

 try Store:=TDPHKnowledgeStore.Create(TPath.Combine(Work,'workflow-'+TGUID.NewGuid.ToString+'.dphdb'),Fixture,TPath.Combine(Root,'migrations'));

 try Store.InitializeProject('Controlled target recovery requirements','Delphi');
Config:=Store.AddConfiguration('Win32','37.0','[]','[]','Debug');
Store.SelectConfiguration(Config);

 Generation:=TDPHSemanticPersistence.Stage(Scan,Graph,Store,Config);
View:=TDPHWorkspaceView.Create(TDPHWorkspaceView.Capture(Scan,Graph,Generation,'Operations.dpr','Debug','Win32',[],[]));

 try Store.SaveWorkspaceView(Generation,View.Document.ToJSON);
TDPHSemanticPersistence.Publish(Scan,Graph,Store,Generation);
Before:=View.Document.ToJSON;

 RecordValue:=TDPHWorkspaceView.NewDepartmentalWorkflow;

 try
  Row:=RecordValue.GetValue<TJSONObject>('fields');
Row.RemovePair('name').Free;
Row.AddPair('name','Order fulfilment workflow');
Row.RemovePair('owner').Free;
Row.AddPair('owner','Operations manager');

  Step:=TDPHWorkspaceView.NewWorkflowStep;
Step.RemovePair('action').Free;
Step.AddPair('action','Check approved order');
Step.RemovePair('department').Free;
Step.AddPair('department','Sales');
Step.RemovePair('role').Free;
Step.AddPair('role','Order clerk');
Step.RemovePair('inputs').Free;
Step.AddPair('inputs','Approved order from sales');
Step.RemovePair('outputs').Free;
Step.AddPair('outputs','Validated order');
Step.RemovePair('handoff').Free;
Step.AddPair('handoff','Sales sends validated order to Warehouse');
RecordValue.GetValue<TJSONArray>('steps').AddElement(Step);

  Step:=TDPHWorkspaceView.NewWorkflowStep;
Step.RemovePair('action').Free;
Step.AddPair('action','Dispatch order');
Step.RemovePair('department').Free;
Step.AddPair('department','Warehouse');
Step.RemovePair('role').Free;
Step.AddPair('role','Dispatch operator');
Step.RemovePair('exception_handling').Free;
Step.AddPair('exception_handling','Return missing approval to Sales for correction');
Step.RemovePair('exception_target').Free;
Step.AddPair('exception_target',RecordValue.GetValue<TJSONArray>('steps').Items[0].GetValue<string>('step_id'));
RecordValue.GetValue<TJSONArray>('steps').AddElement(Step);

  TDPHWorkspaceView.ValidateDepartmentalWorkflow(RecordValue);
Metadata:=RecordValue.ToJSON;
Body:=TDPHWorkspaceView.DepartmentalWorkflowBody(RecordValue);
WorkflowTitle:='Order fulfilment workflow';

  Check(Body.Contains('Approved order from sales'),'Step input rendered');
Check(Body.Contains('Sales sends validated order to Warehouse'),'Departmental handoff rendered');
Check(Body.Contains('Responsible role: Order clerk'),'Step role rendered');
Check(Body.Contains('Normal authored sequence: Step 2'),'Explicit ordered sequence rendered');
Check(Body.Contains('Exception destination: Step 1: Check approved order'),'Exception destination resolves stable step identity');
Check(Body.Contains('Unknown'),'Unresolved business fields remain explicit');

 finally RecordValue.Free;
end;

 Check(SaveWorkflow(0,0,WorkflowTitle,Body,'','business_rule','maintenance','maintainer','',Metadata),'Anonymous process author rejected');

 Check(SaveWorkflow(0,0,'Incorrect title',Body,'Author','business_rule','maintenance','maintainer','',Metadata),'Placeholder title rejected');

 Check(SaveWorkflow(0,0,WorkflowTitle,'Workflow heading removed','Author','business_rule','maintenance','maintainer','',Metadata),'Removed process heading rejected');

 Check(SaveWorkflow(0,0,WorkflowTitle,Body,'Author','engineering_rule','maintenance','maintainer','',Metadata),'Incorrect process kind rejected');

 Check(SaveWorkflow(0,0,WorkflowTitle,Body,'Author','business_rule','user','user','',Metadata),'Incorrect process audience rejected');

 RecordValue:=TJSONObject.ParseJSONValue(Metadata) as TJSONObject;
try RecordValue.RemovePair('workflow_id').Free;
RecordValue.AddPair('workflow_id','invalid');
Check(SaveWorkflow(0,0,WorkflowTitle,Body,'Author','business_rule','maintenance','maintainer','',RecordValue.ToJSON),'Invalid stable process identity rejected');
finally RecordValue.Free;
end;

 RecordValue:=TJSONObject.ParseJSONValue(Metadata) as TJSONObject;
try RecordValue.AddPair('unexpected','x');
Check(SaveWorkflow(0,0,WorkflowTitle,Body,'Author','business_rule','maintenance','maintainer','',RecordValue.ToJSON),'Unknown process metadata rejected');
finally RecordValue.Free;
end;

 RecordValue:=TJSONObject.ParseJSONValue(Metadata) as TJSONObject;
try Row:=RecordValue.GetValue<TJSONObject>('fields');
Row.RemovePair('scope').Free;
Row.AddPair('scope','');
Check(SaveWorkflow(0,0,WorkflowTitle,Body,'Author','business_rule','maintenance','maintainer','',RecordValue.ToJSON),'Empty structured scope rejected; Unknown must be explicit');
finally RecordValue.Free;
end;

 RecordValue:=TJSONObject.ParseJSONValue(Metadata) as TJSONObject;
try Row:=RecordValue.GetValue<TJSONObject>('fields');
Row.RemovePair('owner').Free;
Row.AddPair('owner',TJSONNumber.Create(1));
Check(SaveWorkflow(0,0,WorkflowTitle,Body,'Author','business_rule','maintenance','maintainer','',RecordValue.ToJSON),'Numeric owner rejected');
finally RecordValue.Free;
end;

 RecordValue:=TJSONObject.ParseJSONValue(Metadata) as TJSONObject;
try Row:=RecordValue.GetValue<TJSONObject>('fields');
Row.RemovePair('unknowns').Free;
Row.AddPair('unknowns',StringOfChar('x',4097));
Check(SaveWorkflow(0,0,WorkflowTitle,Body,'Author','business_rule','maintenance','maintainer','',RecordValue.ToJSON),'Oversized structured field rejected');
finally RecordValue.Free;
end;

 RecordValue:=TJSONObject.ParseJSONValue(Metadata) as TJSONObject;
try RecordValue.RemovePair('workflow_id').Free;
RecordValue.AddPair('workflow_id',StringToGUID('{ABCDEFAB-1234-1234-1234-ABCDEFABCDEF}').ToString.ToLower);
Check(SaveWorkflow(0,0,WorkflowTitle,Body,'Author','business_rule','maintenance','maintainer','',RecordValue.ToJSON),'Noncanonical GUID spelling rejected to prevent duplicate identities');
finally RecordValue.Free;
end;

 RecordValue:=TJSONObject.ParseJSONValue(Metadata) as TJSONObject;
try Row:=RecordValue.GetValue<TJSONArray>('steps').Items[0] as TJSONObject;
Row.RemovePair('exception_target').Free;
Row.AddPair('exception_target',TGUID.NewGuid.ToString);
Check(SaveWorkflow(0,0,WorkflowTitle,Body,'Author','business_rule','maintenance','maintainer','',RecordValue.ToJSON),'Dangling exception destination rejected');
finally RecordValue.Free;
end;

 RecordValue:=TJSONObject.ParseJSONValue(Metadata) as TJSONObject;
try Row:=RecordValue.GetValue<TJSONArray>('steps').Items[1] as TJSONObject;
Row.RemovePair('step_id').Free;
Row.AddPair('step_id',RecordValue.GetValue<TJSONArray>('steps').Items[0].GetValue<string>('step_id'));
Check(SaveWorkflow(0,0,WorkflowTitle,Body,'Author','business_rule','maintenance','maintainer','',RecordValue.ToJSON),'Duplicate step identity rejected');
finally RecordValue.Free;
end;

 RecordValue:=TJSONObject.ParseJSONValue(Metadata) as TJSONObject;
try Row:=RecordValue.GetValue<TJSONArray>('steps').Items[0] as TJSONObject;
Row.RemovePair('role').Free;
Row.AddPair('role',TJSONNumber.Create(1));
Check(SaveWorkflow(0,0,WorkflowTitle,Body,'Author','business_rule','maintenance','maintainer','',RecordValue.ToJSON),'Non-text step role rejected');
finally RecordValue.Free;
end;

 RecordValue:=TJSONObject.ParseJSONValue(Metadata) as TJSONObject;
try Row:=RecordValue.GetValue<TJSONArray>('steps').Items[0] as TJSONObject;
Row.RemovePair('action').Free;
Row.AddPair('action','Unknown');
Check(SaveWorkflow(0,0,WorkflowTitle,Body,'Author','business_rule','maintenance','maintainer','',RecordValue.ToJSON),'Unnamed step action rejected');
finally RecordValue.Free;
end;

 RecordValue:=TJSONObject.ParseJSONValue(Metadata) as TJSONObject;
try Row:=RecordValue.GetValue<TJSONArray>('steps').Items[0] as TJSONObject;
Row.RemovePair('inputs').Free;
Row.AddPair('inputs',StringOfChar('x',2049));
Check(SaveWorkflow(0,0,WorkflowTitle,Body,'Author','business_rule','maintenance','maintainer','',RecordValue.ToJSON),'Oversized step field rejected');
finally RecordValue.Free;
end;

 RecordValue:=TJSONObject.ParseJSONValue(Metadata) as TJSONObject;
try for I:=3 to 65 do begin Step:=TDPHWorkspaceView.NewWorkflowStep;
Step.RemovePair('action').Free;
Step.AddPair('action','Bounded extra step');
RecordValue.GetValue<TJSONArray>('steps').AddElement(Step);
end;
Check(SaveWorkflow(0,0,WorkflowTitle,Body,'Author','business_rule','maintenance','maintainer','',RecordValue.ToJSON),'More than 64 workflow steps rejected');
finally RecordValue.Free;
end;

 Links:=TJSONArray.Create;

 try Rows:=Store.LinkCandidates(Generation,'entity','FulfilOrders');
try
 Row:=nil;
for Value in Rows do if View.Symbol(Value.GetValue<string>('canonical_key'))<>nil then begin Row:=Value.Clone as TJSONObject;
Break;
end;

 Check(Row<>nil,'Actual captured semantic implementation routine available');
Row.AddPair('link_role','depends_on');
Links.AddElement(Row);
finally Rows.Free;
end;

 ProcedureID:=Store.SaveKnowledge(0,0,Generation,'Order fulfilment procedure','Controlled order fulfilment procedure; source evidence only. No execution.','Procedure author','maintenance','','maintenance','maintainer');

 Rows:=Store.LinkCandidates(Generation,'section','Order fulfilment procedure');
try Row:=Rows.Items[0].Clone as TJSONObject;
Row.AddPair('link_role','cites');
Links.AddElement(Row);
finally Rows.Free;
end;

 WorkflowID:=Store.SaveKnowledge(0,0,Generation,WorkflowTitle,Body,'Workflow author','business_rule','','maintenance','maintainer',Links.ToJSON,'',Metadata);

 finally Links.Free;
end;

 Row:=LoadWorkflow;
try Revision:=StrToInt64(Row.GetValue<string>('revision'));

 Check(TDPHWorkspaceView.IsDepartmentalWorkflow(Row),'Typed persisted process recognized');
Check(Row.GetValue<string>('owner')='Workflow author','Named contributor persists');
Check(Row.GetValue<string>('state')='needs_review','Saved process remains pending review');

 Check(Row.GetValue<TJSONArray>('rich_links').Count=2,'Routine and exact procedure-revision links persist');

 Check(Row.GetValue<string>('body').Contains('Sales sends validated order to Warehouse'),'Departmental handoff persists');
Check(Row.GetValue<string>('body').Contains('Unknown'),'Unresolved fields stay explicit');

 Check(TDPHWorkspaceView.DescribeDepartmentalWorkflow(Row).Contains('Explicit implementation/evidence links: 2'),'Inspector distinguishes resolved link count');

 finally Row.Free;
end;

 Check(SaveWorkflow(0,0,WorkflowTitle,Body,'Author','business_rule','maintenance','maintainer','',Metadata),'Duplicate process identity rejected');

 Check(SaveWorkflow(WorkflowID,Revision,WorkflowTitle,Body,'Author','business_rule','maintenance','maintainer','','{}'),'Typed metadata cannot be discarded');

 RecordValue:=TJSONObject.ParseJSONValue(Metadata) as TJSONObject;
RecordValue.RemovePair('workflow_id').Free;
RecordValue.AddPair('workflow_id',TGUID.NewGuid.ToString);
try Check(SaveWorkflow(WorkflowID,Revision,WorkflowTitle,Body,'Author','business_rule','maintenance','maintainer','',RecordValue.ToJSON),'Saved process identity cannot change');
finally RecordValue.Free;
end;

 Denied:=False;
try Store.ReviewKnowledge(WorkflowID,Revision,Generation,'','verified');
except Denied:=True;
end;
Check(Denied,'Anonymous process review rejected');

 OldRevision:=Revision;
Store.ReviewKnowledge(WorkflowID,Revision,Generation,'Workflow reviewer','verified');
Row:=LoadWorkflow;
try Revision:=StrToInt64(Row.GetValue<string>('revision'));
Check(Row.GetValue<string>('reviewer')='Workflow reviewer','Named reviewer persists');
Check(Row.GetValue<TJSONArray>('history').Count=2,'Review appends immutable history');
Check(Row.GetValue<TJSONArray>('rich_links').Count=2,'Review retains exact implementation links');
finally Row.Free;
end;

 Check(SaveWorkflow(WorkflowID,OldRevision,WorkflowTitle,Body,'Editor','business_rule','maintenance','maintainer','',Metadata),'Stale process edit rejected');

 RecordValue:=TJSONObject.ParseJSONValue(Metadata) as TJSONObject;

 try
  Row:=RecordValue.GetValue<TJSONArray>('steps').Items[0] as TJSONObject;
Row.RemovePair('outputs').Free;
Row.AddPair('outputs','Validated order and tracking number');

  Metadata:=RecordValue.ToJSON;
Body:=TDPHWorkspaceView.DepartmentalWorkflowBody(RecordValue);

 finally RecordValue.Free;
end;

 Store.SaveKnowledge(WorkflowID,Revision,Generation,WorkflowTitle,Body,'Second author','business_rule','','maintenance','maintainer','','',Metadata);

 Row:=LoadWorkflow;
try Check(Row.GetValue<string>('state')='needs_review','Workflow edits reopen review');
Check(Row.GetValue<TJSONArray>('history').Count=3,'Prior reviewed process retained');
Check(Row.GetValue<TJSONArray>('rich_links').Count=2,'Workflow revision preserves implementation links');
Check(Row.GetValue<string>('body').Contains('tracking number'),'Changed structured output persists');
finally Row.Free;
end;

 Row:=LoadWorkflow;
try Revision:=StrToInt64(Row.GetValue<string>('revision'));
finally Row.Free;
end;

 Check(SaveWorkflow(WorkflowID,Revision,WorkflowTitle,Body+sLineBreak+'invented prose','Editor','business_rule','maintenance','maintainer','',Metadata),'Structured process body cannot diverge from fields');

 Check(Store.IntegrityCheck='ok','Workflow database integrity valid');

 Rows:=Store.KnowledgeJSON;
try Model:=TDPHDocumentModel.Create(View,Rows,[],[],False,False,nil,False,'maintainer');

 try
 Check(Model.Document.ToJSON.Contains('Order fulfilment workflow'),'Maintainer publication includes authored process');

 Check(Model.Document.ToJSON.Contains('departmental_workflow'),'Canonical handoff preserves typed process identity');

 if TDirectory.Exists(TPath.Combine(Work,'handoff')) then begin
  RecordValue:=TJSONObject.ParseJSONValue(TFile.ReadAllText(TPath.Combine(Work,'handoff\manifest.json'),TEncoding.UTF8)) as TJSONObject;

  try if RecordValue.GetValue<string>('project','')<>'Operations.dpr' then raise Exception.Create('Refusing to replace an unrelated test export');
finally RecordValue.Free;
end;

  TDirectory.Delete(TPath.Combine(Work,'handoff'),True);

 end;

 TDPHPublisher.Export(Model,Store,TPath.Combine(Work,'handoff'));

 TDPHPublisher.Validate(TPath.Combine(Work,'handoff'),Model.Document.GetValue<string>('input_fingerprint'));

 Check(True,'Business process handoff passes full bundle validation');

 Check(TFile.ReadAllText(TPath.Combine(Work,'handoff\index.html'),TEncoding.UTF8).Contains('Approved order from sales'),'Published HTML includes structured inputs');

 finally Model.Free;
end;
finally Rows.Free;
end;

 DatabaseName:=Store.DatabasePath;
FreeAndNil(Store);
Store:=TDPHKnowledgeStore.Create(DatabaseName,Fixture,TPath.Combine(Root,'migrations'));
Store.SelectConfiguration(Config);

 Row:=LoadWorkflow;
try Check(Row<>nil,'Business process survives database close and reopen');
Check(Row.GetValue<string>('structured_json')=Metadata,'Exact structured fields survive reopening');
Check(Row.GetValue<TJSONArray>('history').Count=3,'Immutable review and edit history survives reopening');
Check(Row.GetValue<TJSONArray>('rich_links').Count=2,'Exact source and procedure links survive reopening');
finally Row.Free;
end;

 Catalog:=TDPHWorkspaceCatalog.DefaultPath;
CatalogHash:='';
if TFile.Exists(Catalog) then CatalogHash:=THashSHA2.GetHashStringFromFile(Catalog);

 Form:=TDPHMainForm.Create(nil);

 try Form.PollTimer.Enabled:=False;
Form.ChangeTimer.Enabled:=False;
Form.LoadView(View.Document.Clone as TJSONObject);
Form.LoadKnowledge(Store.KnowledgeJSON);

 Check(Form.DepartmentalWorkflowList.Count=1,'Native register includes process and excludes unrelated procedure');
Check(Form.DepartmentalWorkflowMemo.Text.Contains('Second author'),'Native inspector shows current contributor');

 Form.PendingKnowledgeCheck.IsChecked:=True;
Form.DepartmentalWorkflowOpenClick(nil);
Check(Form.WorkspaceTabs.ActiveTab=Form.KnowledgeTab,'Open plan enters saved Knowledge workflow');
Check(Form.KnowledgeBodyMemo.ReadOnly,'Saved structured body protected from free text edits');
Check(Form.KnowledgeTitleEdit.ReadOnly,'Saved stable title protected');
Check(not Form.KnowledgeKindCombo.Enabled,'Saved process kind protected');

 Form.DepartmentalWorkflowOpenClick(Form.DepartmentalWorkflowLinks);
Check(Form.WorkspaceTabs.ActiveTab=Form.KnowledgeLinksTab,'Implementation links opens exact link workflow');
Check(Form.KnowledgeLinksList.Count=2,'Native exact implementation links available');
Form.KnowledgeLinksList.ItemIndex:=0;
Form.OpenKnowledgeLinkClick(nil);
Check(Form.WorkspaceTabs.ActiveTab=Form.ExplainTab,'Saved implementation routine opens captured explanation');

 Form.DepartmentalWorkflowEditClick(nil);
Check(Form.WorkspaceTabs.ActiveTab=Form.WorkflowEditorTab,'Edit opens native workflow editor');
Check(Form.WorkflowSteps.Count=2,'Saved ordered steps restored');
Check(Form.Workflow_name.ReadOnly,'Saved workflow name protected');
Form.SaveKnowledgeClick(nil);
Check(Form.StatusLabel.Text.Contains('Apply the structured editor'),'Save refuses unapplied workflow editor');

 Form.WorkflowSteps.ItemIndex:=0;
Form.WorkflowStepClick(nil);
Check(Form.Step_role.Text='Order clerk','Native selected step restores role');
Check(Form.Step_handoff.Text.Contains('Warehouse'),'Native selected step restores handoff');

 Form.WorkflowStepAction(Form.WorkflowRemoveStep);
Check(Form.WorkflowSteps.Count=2,'Referring exception prevents removal of its target');

 Form.Step_outputs.Text:='Revised native output';
Form.WorkflowApplyClick(nil);
Check(Form.StatusLabel.Text.Contains('Apply step'),'Dirty step prevents workflow apply');
Form.WorkflowStepAction(Form.WorkflowNewStep);
Check(Form.StatusLabel.Text.Contains('Apply step'),'Dirty step prevents replacement');

 Form.WorkflowStepAction(Form.WorkflowSaveStep);
Check(Form.WorkflowSteps.Count=2,'Apply edited step preserves count');
Form.WorkflowStepAction(Form.WorkflowStepDown);
Check(Form.WorkflowSteps.ItemIndex=1,'Move down keeps selected step identity');
Check(Form.WorkflowSteps.Items[0].Contains('Warehouse'),'Move down changes authored order');
Form.WorkflowStepAction(Form.WorkflowStepUp);
Check(Form.WorkflowSteps.Items[0].Contains('Sales'),'Move up restores authored order');

 Form.WorkflowStepAction(Form.WorkflowNewStep);
Form.Step_action.Text:='Confirm fulfilment';
Form.Step_department.Text:='Customer service';
Form.Step_role.Text:='Support operator';
Form.WorkflowExceptionTarget.ItemIndex:=1;
Form.WorkflowStepAction(Form.WorkflowSaveStep);
Check(Form.WorkflowSteps.Count=3,'New structured step appended');

 Form.WorkflowAuthor.Text:='Native contributor';
Form.WorkflowApplyClick(nil);
Check(Form.WorkspaceTabs.ActiveTab=Form.KnowledgeTab,'Apply workflow prepares canonical Knowledge draft');
Check(Form.KnowledgeBodyMemo.Text.Contains('Revised native output'),'Edited step output enters canonical body');
Check(Form.KnowledgeBodyMemo.Text.Contains('Confirm fulfilment'),'Added step enters canonical body');

 Body:=Form.KnowledgeBodyMemo.Text;
Form.DepartmentalWorkflowOpenClick(nil);
Check(Form.KnowledgeBodyMemo.Text=Body,'Unsaved workflow draft protected from selection');
Form.DepartmentalWorkflowNewClick(nil);
Check(Form.StatusLabel.Text.Contains('Save or discard'),'Unsaved workflow draft protected from replacement');
Form.DiscardKnowledgeClick(nil);

 Form.DepartmentalWorkflowNewClick(nil);
Check(Form.WorkspaceTabs.ActiveTab=Form.WorkflowEditorTab,'New workflow opens editor');
Check(Form.WorkflowSteps.Count=0,'New workflow starts without invented steps');
Check(not Form.Workflow_name.ReadOnly,'New workflow name editable');
Form.Workflow_name.Text:='Native workflow';
Form.WorkflowAuthor.Text:='Native contributor';
Form.WorkflowApplyClick(nil);
Check(Form.StatusLabel.Text.Contains('1 through 64'),'Empty workflow cannot apply');

 Form.WorkflowStepAction(Form.WorkflowNewStep);
Form.Step_action.Text:='Handle sample order';
Form.WorkflowStepAction(Form.WorkflowSaveStep);
Check(Form.WorkflowSteps.Count=1,'New authored step applies to draft');
Form.WorkflowAuthor.Text:='';
Form.WorkflowApplyClick(nil);
Check(Form.StatusLabel.Text.Contains('named contributor'),'Anonymous workflow contributor rejected');
Form.WorkflowAuthor.Text:='Native contributor';
Form.WorkflowApplyClick(nil);
Check(Form.KnowledgeBodyMemo.Text.Contains('DEPARTMENTAL WORKFLOW'),'New workflow canonical body generated');
Check(Form.KnowledgeBodyMemo.ReadOnly,'Structured workflow body protected');
Form.DiscardKnowledgeClick(nil);

 Form.DepartmentalWorkflowState.ItemIndex:=2;
Form.DepartmentalWorkflowFilterChange(nil);
Check(Form.DepartmentalWorkflowList.Count=0,'Review-state filter respects pending edit');
Form.DepartmentalWorkflowState.ItemIndex:=0;
Form.DepartmentalWorkflowFilter.Text:='Approved order';
Form.DepartmentalWorkflowFilterChange(nil);
Check(Form.DepartmentalWorkflowList.Count=1,'Workflow text search finds authored input');

 Form.DepartmentalWorkflowFilter.Text:='absent';
Form.DepartmentalWorkflowFilterChange(nil);
Check(Form.DepartmentalWorkflowMemo.Text.Contains('Empty results do not establish'),'Empty register explains unresolved obligations');
Check(not Form.DepartmentalWorkflowOpen.Enabled,'Empty results disable opening');

 Form.DepartmentalWorkflowFilter.Text:='';
Form.DepartmentalWorkflowFilterChange(nil);
Form.DepartmentalWorkflowEditClick(nil);
Form.WorkflowSteps.ItemIndex:=1;
Form.WorkflowStepClick(nil);
Form.Show;
Render('phase1-departmental-workflow-editor.png');
Form.WindowState:=TWindowState.wsNormal;
Form.Width:=960;
Form.Height:=600;
Render('phase1-departmental-workflow-editor-compact.png');
Form.WorkflowEditorScroll.ViewportPosition:=PointF(0,780);
Render('phase1-departmental-workflow-step-editor.png');
Form.WorkflowEditorScroll.ViewportPosition:=PointF(0,1800);
Render('phase1-departmental-workflow-exception-editor.png');
Check(Form.WorkflowStepToolbar.ShowScrollBars and Form.WorkflowEditorToolbar.ShowScrollBars,'Compact workflow commands scroll');
Form.DiscardKnowledgeClick(nil);
Form.WorkspaceTabs.ActiveTab:=Form.DepartmentalWorkflowTab;
Form.Show;
Render('phase1-departmental-workflow-workspace.png');
Form.WindowState:=TWindowState.wsNormal;
Form.Width:=960;
Form.Height:=600;
Render('phase1-departmental-workflow-compact.png');
Check(Form.DepartmentalWorkflowMemo.Height>=50,'Compact workflow detail remains readable');
Check(Form.DepartmentalWorkflowToolbar.ShowScrollBars and Form.DepartmentalWorkflowMemo.ShowScrollBars,'Compact commands and long policies scroll');
Form.Hide;

 Policies:=TJSONArray.Create;
Row:=LoadWorkflow;
try for I:=1 to 270 do begin RecordValue:=Row.Clone as TJSONObject;
Policies.AddElement(RecordValue);
end;
finally Row.Free;
end;
Form.LoadKnowledge(Policies);
Check(Form.DepartmentalWorkflowList.Count=250,'Large register first page bounded');
Check(Form.DepartmentalWorkflowNext.Enabled,'Large register next page accessible');
Form.DepartmentalWorkflowFilterChange(Form.DepartmentalWorkflowNext);
Check(Form.DepartmentalWorkflowList.Count=20,'Remaining workflow rows accessible');

 Form.LoadKnowledge(nil);
Check(Form.DepartmentalWorkflowList.Count=0,'Clearing loaded knowledge removes prior workflow rows');

 finally Form.Free;
end;

 Form:=TDPHMainForm.Create(nil);
try Form.PollTimer.Enabled:=False;
Form.ChangeTimer.Enabled:=False;
Check(not Form.DepartmentalWorkflowNew.Enabled,'No capture disables new workflow');
finally Form.Free;
end;

 Check(View.Document.ToJSON=Before,'Workflow workflow leaves captured workspace unchanged');
Check(THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'Main.pas'))=SourceHash,'Target source unchanged');
Check((not TFile.Exists(Catalog) and (CatalogHash='')) or (TFile.Exists(Catalog) and (THashSHA2.GetHashStringFromFile(Catalog)=CatalogHash)),'Owner catalog unchanged');

 Log:=TJSONObject.Create.AddPair('result','PASS').AddPair('checks',TJSONNumber.Create(Checks)).AddPair('qualification','Structured attributed departmental workflows with ordered steps, departments, roles, handoffs and explicit exception destinations. Target execution and business outcomes remain unverified.');
try TFile.WriteAllText(TPath.Combine(Root,'docs\phase1-departmental-workflow-validation.json'),Log.Format,TEncoding.UTF8);
finally Log.Free;
end;

 finally View.Free;
end;
finally Store.Free;
end;
finally Graph.Free;
end;
finally Scan.Free;
end;
finally Semantic.Free;
Analyzer.Free;
end;

 except on E:Exception do begin Writeln(E.ClassName,': ',E.Message);
ExitCode:=1;
end;
end;

end.
