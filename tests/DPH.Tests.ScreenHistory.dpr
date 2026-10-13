program DPH.Tests.ScreenHistory;

{$APPTYPE CONSOLE}
uses System.SysUtils,System.Classes,System.IOUtils,System.JSON,System.Hash,System.Diagnostics,System.StrUtils,System.Math,System.UITypes,Winapi.Windows,
 FMX.Forms,FMX.Graphics,Vcl.Imaging.pngimage,Vcl.Graphics,DPH.UI.Main,DPH.Project.Analysis,DPH.Analysis.Symbols,
 DPH.Analysis.Model,DPH.Analysis.Persistence,DPH.Workspace.Model,DPH.Workspace.ScreenHistory,DPH.Workspace.Worker,
 DPH.Workspace.Catalog,DPH.Storage.Database,DPH.Storage.Types;

var Root,Work,Fixture,Database,Text,Catalog,CatalogHash,SourceHash:string;
Checks,I:Integer;
Store:TDPHKnowledgeStore;
Config:Int64;

 Before,After,Report,Layout,Invalid,Row,MetaA,MetaB,Log:TJSONObject;
Images:TJSONArray;
V:TJSONValue;
BeforeView,AfterView:TDPHWorkspaceView;

 BeforePNG,AfterPNG,MaskPNG:TBytes;
Form:TDPHMainForm;
Bitmap:FMX.Graphics.TBitmap;
Worker:TDPHWorkspaceWorker;

 Request:TDPHWorkspaceRequest;
Response:TDPHWorkspaceResponse;
Watch:TStopwatch;
Rejected:Boolean;
PNG:TPngImage;

 Input:TStringStream;
Binary:TMemoryStream;
BeforeID,AfterID:Int64;
OldFile:string;
CatalogBytes:TBytes;
CatalogExisted:Boolean;
X,Y,Blue,Orange:Integer;Pixel:TColor;

procedure Check(OK:Boolean;
const S:string);

begin if not OK then raise Exception.Create('FAIL '+S);
Inc(Checks);
Writeln('PASS ',Checks,': ',S);
Flush(Output);
end;

procedure MakePNG(const Name:string;
Width,Height:Integer;
Change:Boolean=False;
Alpha:Boolean=False);

var Image:TPngImage;
X,Y:Integer;

begin Image:=TPngImage.CreateBlank(COLOR_RGB,8,Width,Height);
try for Y:=0 to Height-1 do for X:=0 to Width-1 do Image.Pixels[X,Y]:=clWhite;
if Change then Image.Pixels[2,1]:=clRed;
if Alpha then begin Image.CreateAlpha;
Image.Pixels[0,0]:=clBlack;
Image.AlphaScanline[0]^[0]:=0;
end;
Image.SaveToFile(TPath.Combine(Work,Name));
finally Image.Free;
end;
end;

function Metadata(const Name:string):TJSONObject;

begin Result:=TJSONObject.Create.AddPair('managed_path',TPath.Combine(Work,Name)).AddPair('image_sha256',THashSHA2.GetHashStringFromFile(TPath.Combine(Work,Name))).AddPair('artifact_id',TJSONNumber.Create(1)).AddPair('generation_id',TJSONNumber.Create(1)).AddPair('caption','Synthetic controlled PNG').AddPair('author','Fixture author').AddPair('imported_utc','2026-10-11').AddPair('verification_state','user_supplied_unverified').AddPair('artifact_hash','fixture metadata').AddPair('provenance','Synthetic image, not an observed target screenshot');
end;

function Capture:TJSONObject;

var Analyzer:TDPHAnalyzer;
Semantic:TDPHSemanticAnalyzer;
Scan:TDPHScan;
Graph:TDPHSemanticGraph;
Generation:Int64;

begin Analyzer:=TDPHAnalyzer.Create;
Semantic:=TDPHSemanticAnalyzer.Create;
try Scan:=Analyzer.Scan(TPath.Combine(Fixture,'History.dpr'),'Debug','Win32',[],[],False);
try Graph:=Semantic.Analyze(Scan);
try Generation:=TDPHSemanticPersistence.Stage(Scan,Graph,Store,Config);
Result:=TDPHWorkspaceView.Capture(Scan,Graph,Generation,'History.dpr','Debug','Win32',[],[]);
Store.SaveWorkspaceView(Generation,Result.ToJSON);
TDPHSemanticPersistence.Publish(Scan,Graph,Store,Generation);
finally Graph.Free;
end;
finally Scan.Free;
end;
finally Semantic.Free;
Analyzer.Free;
end;
end;

function WaitResponse:TDPHWorkspaceResponse;

begin Result:=nil;
Watch:=TStopwatch.StartNew;
repeat if Worker.Poll(Result) then begin if not Result.Busy then Exit;
Result.Free;
Result:=nil;
end;
if Watch.ElapsedMilliseconds>30000 then raise Exception.Create('Worker timeout');
TThread.Sleep(10);
until False;
end;

procedure Render(const Name:string);

begin Application.ProcessMessages;
Bitmap:=FMX.Graphics.TBitmap.Create(Form.ClientWidth,Form.ClientHeight);
try if Bitmap.Canvas.BeginScene then try Form.PaintTo(Bitmap.Canvas);
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
Work:=TPath.Combine(Root,'bin\screen-history-validation');
if TDirectory.Exists(Work) then TDirectory.Delete(Work,True);
Fixture:=TPath.Combine(Work,'source');
TDirectory.CreateDirectory(Fixture);

 MakePNG('before.png',4,3);
MakePNG('after.png',4,3,True);
MakePNG('wider.png',5,3,True);
MakePNG('alpha.png',4,3,False,True);
MakePNG('wide.png',8192,1);
MakePNG('tall.png',1,8192);

 MetaA:=Metadata('before.png');
MetaB:=Metadata('after.png');

 try Report:=TDPHScreenHistory.CompareImages(MetaA,MetaB,BeforePNG,AfterPNG,MaskPNG);
try
 Check(Report.GetValue<Integer>('changed_pixels')=1,'One changed pixel counted exactly');
Check(Report.GetValue<Integer>('changed_bounds.left')=2,'Changed bounds retain x');
Check(Report.GetValue<Integer>('changed_bounds.top')=1,'Changed bounds retain y');
Check(Report.GetValue<Integer>('before_only_pixels')=0,'Equal dimensions have no missing extent');

 Check(not Report.ToJSON.Contains('managed_path'),'Comparison metadata omits private managed path');
Check(TDPHScreenHistory.Describe(Report).Contains('Fixture author'),'Attribution displayed');
Check(TDPHScreenHistory.Describe(Report).Contains('not proof'),'Difference qualification explicit');

 PNG:=TPngImage.Create;
try Binary:=TBytesStream.Create(MaskPNG);
try PNG.LoadFromStream(Binary);
finally Binary.Free;
end;
Check(PNG.Pixels[2,1]=clRed,'Changed overlapping pixel marked red');
Check(PNG.Pixels[0,0]=clWhite,'Unchanged pixel white');
finally PNG.Free;
end;

 finally Report.Free;
end;

 Report:=TDPHScreenHistory.CompareImages(MetaA,MetaA,BeforePNG,AfterPNG,MaskPNG);
try Check(Report.GetValue<Integer>('changed_pixels')=0,'Identical images compare equal');
Check(Report.GetValue('changed_bounds') is TJSONNull,'Equal images have no changed bounds');
finally Report.Free;
end;

 MetaB.Free;
MetaB:=Metadata('wider.png');
Report:=TDPHScreenHistory.CompareImages(MetaA,MetaB,BeforePNG,AfterPNG,MaskPNG);
try Check(Report.GetValue<Integer>('changed_pixels')=4,'New extent and overlapping change counted');
Check(Report.GetValue<Integer>('after_only_pixels')=3,'After-only extent explicit');
Check(Report.GetValue<Integer>('width')=5,'Union preserves full dimensions');
finally Report.Free;
end;

 Report:=TDPHScreenHistory.CompareImages(MetaB,MetaA,BeforePNG,AfterPNG,MaskPNG);
try Check(Report.GetValue<Integer>('before_only_pixels')=3,'Swapping sides reverses extent attribution');
finally Report.Free;
end;

 MetaB.Free;
MetaB:=Metadata('alpha.png');
Report:=TDPHScreenHistory.CompareImages(MetaA,MetaB,BeforePNG,AfterPNG,MaskPNG);
try Check(Report.GetValue<Integer>('changed_pixels')=0,'Invisible transparent RGB is composited on white');
finally Report.Free;
end;

 MetaB.RemovePair('image_sha256').Free;
MetaB.AddPair('image_sha256',StringOfChar('0',64));
Rejected:=False;
try Report:=TDPHScreenHistory.CompareImages(MetaA,MetaB,BeforePNG,AfterPNG,MaskPNG);
Report.Free;
except Rejected:=True;
end;
Check(Rejected,'Changed image bytes rejected');
Check(Length(MaskPNG)=0,'Failure clears derived mask');

 MetaA.Free;
MetaA:=Metadata('wide.png');
MetaB.Free;
MetaB:=Metadata('tall.png');
Rejected:=False;
try Report:=TDPHScreenHistory.CompareImages(MetaA,MetaB,BeforePNG,AfterPNG,MaskPNG);
Report.Free;
except Rejected:=True;
end;
Check(Rejected,'Oversized union refused without resampling');

 finally MetaB.Free;
MetaA.Free;
end;

 TFile.WriteAllText(TPath.Combine(Fixture,'History.dpr'),'program History; uses Main, Touch, BinaryLayout; begin end.',TEncoding.UTF8);

 TFile.WriteAllText(TPath.Combine(Fixture,'Main.pas'),'unit Main; interface implementation {$R *.dfm} end.',TEncoding.UTF8);
TFile.WriteAllText(TPath.Combine(Fixture,'Touch.pas'),'unit Touch; interface implementation {$R *.fmx} end.',TEncoding.UTF8);
TFile.WriteAllText(TPath.Combine(Fixture,'BinaryLayout.pas'),'unit BinaryLayout; interface implementation {$R *.dfm} end.',TEncoding.UTF8);

 TFile.WriteAllText(TPath.Combine(Fixture,'Touch.fmx'),'object TouchForm: TForm'+sLineBreak+' object TouchButton: TButton'+sLineBreak+' Text = ''Before'''+sLineBreak+' end'+sLineBreak+'end',TEncoding.UTF8);

 Input:=TStringStream.Create('object BinaryForm: TForm'+sLineBreak+' object BinaryButton: TButton'+sLineBreak+' end'+sLineBreak+'end');
Binary:=TMemoryStream.Create;
try ObjectTextToBinary(Input,Binary);
Binary.SaveToFile(TPath.Combine(Fixture,'BinaryLayout.dfm'));
finally Binary.Free;
Input.Free;
end;

 Text:='object MainForm: TForm'+sLineBreak+' Width = 800'+sLineBreak+' Height = 600'+sLineBreak+' object Changed: TButton'+sLineBreak+' Left = 10'+sLineBreak+' Top = 20'+sLineBreak+' Width = 100'+sLineBreak+' Caption = ''Before'''+sLineBreak+' end'+sLineBreak+' object Removed: TButton'+sLineBreak+' end'+sLineBreak;

 for I:=1 to 270 do Text:=Text+' object Extra'+IntToStr(I)+': TButton'+sLineBreak+' Caption = ''Before'''+sLineBreak+' end'+sLineBreak;

 Text:=Text+'end';
TFile.WriteAllText(TPath.Combine(Fixture,'Main.dfm'),Text,TEncoding.UTF8);

 Database:=TPath.Combine(Work,'history.dphdb');
if TFile.Exists(Database) then TFile.Delete(Database);
Store:=TDPHKnowledgeStore.Create(Database,Fixture,TPath.Combine(Root,'migrations'));
Before:=nil;
After:=nil;

 try Store.InitializeProject('Screen history fixture','Delphi');
Config:=Store.AddConfiguration('Win32','37.0','[]','[]','Debug');
Store.SelectConfiguration(Config);
Before:=Capture;
Store.ImportScreenshot(Before.GetValue<Int64>('generation_id'),TPath.Combine(Work,'before.png'),'Before contributor','Synthetic BEFORE controlled fixture','');

 TFile.WriteAllText(TPath.Combine(Fixture,'Main.dfm'),StringReplace(StringReplace(StringReplace(Text,'Before','After',[rfReplaceAll]),'Left = 10','Left = 30',[]),'Removed','Added',[]),TEncoding.UTF8);

 TFile.WriteAllText(TPath.Combine(Fixture,'Touch.fmx'),'object TouchForm: TForm'+sLineBreak+' object TouchButton: TButton'+sLineBreak+' Text = ''After'''+sLineBreak+' end'+sLineBreak+'end',TEncoding.UTF8);
After:=Capture;
Store.ImportScreenshot(After.GetValue<Int64>('generation_id'),TPath.Combine(Work,'after.png'),'After contributor','Synthetic AFTER controlled fixture','');

 Images:=Store.ScreenshotsJSON;
try Check(Images.Count=2,'Both generations retain screenshot evidence');
BeforeID:=Images.Items[1].GetValue<Int64>('artifact_id');
AfterID:=Images.Items[0].GetValue<Int64>('artifact_id');
finally Images.Free;
end;
Check(Store.IntegrityCheck='ok','Imported history preserves SQLite integrity');

 finally Store.Free;
end;

 try BeforeView:=TDPHWorkspaceView.Create(Before.Clone as TJSONObject);
AfterView:=TDPHWorkspaceView.Create(After.Clone as TJSONObject);

 try Layout:=TDPHScreenHistory.CompareLayouts(BeforeView,AfterView,'main.dfm','main.dfm');
try
 Check(Layout.GetValue<TJSONArray>('changes').Count=273,'Changed, added and removed components counted');
Rejected:=False;
for V in Layout.GetValue<TJSONArray>('changes') do if V.GetValue<string>('path')='mainform/changed' then Rejected:=V.GetValue<string>('before_values').Contains('Left = 10') and V.GetValue<string>('after_values').Contains('Left = 30');
Check(Rejected,'Exact old and new geometry values retained');

 Check(Layout.GetValue<string>('before.source_hash')<>Layout.GetValue<string>('after.source_hash'),'Both source fingerprints retained');
Check(Layout.GetValue<Int64>('before_generation')<>Layout.GetValue<Int64>('after_generation'),'Both captured generations retained');
Check(Layout.GetValue<string>('definition').Contains('not runtime'),'Layout qualification explicit');

 finally Layout.Free;
end;

 Layout:=TDPHScreenHistory.CompareLayouts(BeforeView,AfterView,'touch.fmx','touch.fmx');
try Check(Layout.GetValue<TJSONArray>('changes').Count=1,'FMX visual text change compared');
finally Layout.Free;
end;

 Layout:=TDPHScreenHistory.CompareLayouts(BeforeView,AfterView,'binarylayout.dfm','binarylayout.dfm');
try Check(Layout.GetValue<TJSONArray>('changes').Count=0,'Binary DFM layout compared from captured IR');
finally Layout.Free;
end;

 Layout:=TDPHScreenHistory.CompareLayouts(BeforeView,BeforeView,'main.dfm','main.dfm');
try Check(Layout.GetValue<TJSONArray>('changes').Count=0,'Identical captured layout has no changes');
finally Layout.Free;
end;

 Invalid:=After.Clone as TJSONObject;
Invalid.GetValue<TJSONObject>('syntax').RemovePair('analyzer').Free;
Invalid.GetValue<TJSONObject>('syntax').AddPair('analyzer','different');
AfterView.Free;
AfterView:=TDPHWorkspaceView.Create(Invalid);
Rejected:=False;
try Layout:=TDPHScreenHistory.CompareLayouts(BeforeView,AfterView,'main.dfm','main.dfm');
Layout.Free;
except Rejected:=True;
end;
Check(Rejected,'Incompatible parser contracts refused');
AfterView.Free;
AfterView:=TDPHWorkspaceView.Create(After.Clone as TJSONObject);

 Rejected:=False;
try Layout:=TDPHScreenHistory.CompareLayouts(BeforeView,AfterView,'absent.dfm','main.dfm');
Layout.Free;
except Rejected:=True;
end;
Check(Rejected,'Missing form stays unavailable');

 Rejected:=False;
try Layout:=TDPHScreenHistory.CompareLayouts(BeforeView,AfterView,'main.pas','main.pas');
Layout.Free;
except Rejected:=True;
end;
Check(Rejected,'Nonform path refused');

 Invalid:=After.Clone as TJSONObject;
Invalid.RemovePair('selection_hash').Free;
Invalid.AddPair('selection_hash','different');

 Row:=Invalid;
AfterView.Free;
AfterView:=TDPHWorkspaceView.Create(Row);
Rejected:=False;
try Layout:=TDPHScreenHistory.CompareLayouts(BeforeView,AfterView,'main.dfm','main.dfm');
Layout.Free;
except Rejected:=True;
end;
Check(Rejected,'Different analysis selections refused');

 finally AfterView.Free;
BeforeView.Free;
end;

 Worker:=TDPHWorkspaceWorker.Create(Root);
try Request:=Default(TDPHWorkspaceRequest);
Request.Command:='screen_history';
Request.Database:=Database;
Request.GenerationID:=After.GetValue<Int64>('generation_id');
Request.BeforeScreenshot:=BeforeID;
Request.AfterScreenshot:=AfterID;
Request.ScreenToken:=42;
Request.BeforeScreenSource:='main.dfm';
Request.AfterScreenSource:='main.dfm';
Worker.Submit(Request);
Response:=WaitResponse;

 try Check(not Response.Failed,'Real background comparison succeeds');
Check(Response.ScreenHistory<>nil,'Worker returns screen report');
Check(Response.ScreenToken=42,'Request selection token preserved');
Check(Response.ScreenDatabase=Database,'Response bound to selected database');
Check(Response.ScreenHistory.GetValue<Integer>('changed_pixels')=1,'Worker returns exact pixel result');
Check(Response.ScreenHistory.GetValue<TJSONArray>('layout.changes').Count=273,'Worker reads both retained generations');

 Catalog:=TDPHWorkspaceCatalog.DefaultPath;
CatalogHash:='';
if TFile.Exists(Catalog) then CatalogHash:=THashSHA2.GetHashStringFromFile(Catalog);
SourceHash:=THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'Main.dfm'));

 Form:=TDPHMainForm.Create(nil);
try Form.PollTimer.Enabled:=False;
Form.ChangeTimer.Enabled:=False;
Form.LoadView(After.Clone as TJSONObject);
Store:=TDPHKnowledgeStore.Create(Database,Fixture,TPath.Combine(Root,'migrations'));
try Form.LoadScreenshots(Store.ScreenshotsJSON);
finally Store.Free;
end;

 Check(Form.HistoryBeforeCombo.Items.Count=2,'Native history selectors populated');
Check(Form.HistoryBeforeCombo.ItemIndex=1,'Before defaults oldest loaded record');
Check(Form.HistoryAfterCombo.ItemIndex=0,'After defaults newest loaded record');
Check(Form.WorkspacePageCombo.Items.IndexOf('Screen history')>=0,'Page discoverable');

 Form.LoadScreenHistory(Response.ScreenHistory.Clone as TJSONObject,Response.BeforePNG,Response.AfterPNG,Response.DifferencePNG);
Check(Form.HistoryList.Count=250,'Layout list paged at 250');
Check(Form.HistoryNextButton.Enabled,'More layout changes enable Next');
Form.HistoryFilterChange(Form.HistoryNextButton);
Check(Form.HistoryList.Count=23,'Next shows remaining changes');
Check(not Form.HistoryNextButton.Enabled,'Last page disables Next');
Form.HistoryFilter.Text:='mainform/changed';
Form.HistoryFilterChange(nil);
Check(Form.HistoryList.Count=1,'Layout filter selects component');
Form.HistoryList.ItemIndex:=0;
Form.HistoryRowClick(nil);
Check(Form.HistoryMemo.Text.Contains('Left = 30'),'Native details display before and after values');

 Check(Form.HistoryBeforeImage.Bitmap.Width=4,'Before image original dimensions retained');
Check(Form.HistoryAfterImage.Bitmap.Height=3,'After image original dimensions retained');
Check(Form.HistoryDifferenceImage.Bitmap.Width=4,'Native difference image loaded');
Form.WorkspaceTabs.ActiveTab:=Form.HistoryTab;
Form.Show;
Render('phase1-screen-history-images.png');
Check(Form.HistoryBeforePanel.Width>Form.HistoryGrid.Width/4,'Preview fills its grid cell');
Check(Form.HistoryBeforeImage.Height>150,'Image preview has usable height');
Form.HistoryModeCombo.ItemIndex:=1;
Form.HistoryModeChange(nil);
Render('phase1-screen-history-layouts.png');
Check(Form.HistoryDifferencePaint.Visible and not Form.HistoryDifferenceImage.Visible,'Layout mode uses serialized paint controls');
Form.WindowState:=TWindowState.wsNormal;
Form.Width:=960;
Form.Height:=600;
Render('phase1-screen-history-compact.png');
Check(Form.HistoryToolbar.ShowScrollBars and Form.HistoryBody.ShowScrollBars,'Compact page and command bar scroll');
Check((Form.HistoryBeforePanel.Width<Form.HistoryGrid.Width/2) and (Form.HistoryBeforePanel.Width>Form.HistoryGrid.Width/4),'Responsive grid maintains three usable panes');
Check(Form.HistoryDifferencePanel.Height>200,'Compact layout retains scrollable preview height');

 Form.HistoryCompareClick(Form.HistorySwapButton);
Check((Form.HistoryBeforeCombo.ItemIndex=0) and (Form.HistoryAfterCombo.ItemIndex=1),'Swap exchanges screenshot choices');
Check(Form.HistoryBeforeImage.Bitmap.IsEmpty and (Form.HistoryList.Count=0),'Changing pair clears stale images and layout rows');
Form.LoadScreenHistory(Response.ScreenHistory.Clone as TJSONObject,Response.BeforePNG,Response.AfterPNG,Response.DifferencePNG);
Form.HistoryBeforePath.Text:='absent.dfm';
Form.HistorySelectionChange(nil);
Check(Form.HistoryDifferenceImage.Bitmap.IsEmpty,'Changed form selection invalidates old result');
Form.Hide;

 finally Form.Free;
end;

 PNG:=TPngImage.Create;
try PNG.LoadFromFile(TPath.Combine(Root,'docs\validation\images\phase1-screen-history-layouts.png'));
Blue:=0;
Orange:=0;
for Y:=400 to PNG.Height-1 do for X:=270 to Min(1250,PNG.Width-1) do begin Pixel:=PNG.Pixels[X,Y];if (GetBValue(Pixel)>GetRValue(Pixel)+30) and (GetBValue(Pixel)>GetGValue(Pixel)+20) then Inc(Blue);
if (GetRValue(Pixel)>GetGValue(Pixel)+20) and (GetGValue(Pixel)>GetBValue(Pixel)+20) then Inc(Orange);
end;
Check(Blue>100,'Native layout render contains Before geometry');
Check(Orange>100,'Native layout render contains After geometry');
finally PNG.Free;
end;

 CatalogExisted:=TFile.Exists(Catalog);
if CatalogExisted then CatalogBytes:=TFile.ReadAllBytes(Catalog) else CatalogBytes:=nil;

 try Form:=TDPHMainForm.Create(nil);
try Form.PollTimer.Enabled:=False;
Form.ChangeTimer.Enabled:=False;
Form.OpenSelection('',Database);
Watch:=TStopwatch.StartNew;
repeat Form.PollTimerTimer(nil);
if Watch.ElapsedMilliseconds>30000 then raise Exception.Create('Native cached-open timeout');
TThread.Sleep(10);
until Form.StatusLabel.Text.Contains('Cached project verified');
Check(Form.HistoryBeforeCombo.Items.Count=2,'Actual cached-open command populates history choices');
Form.HistoryBeforePath.Text:='main.dfm';
Form.HistoryAfterPath.Text:='main.dfm';
Form.HistoryCompareClick(Form.HistoryCompareButton);
Watch:=TStopwatch.StartNew;
repeat Form.PollTimerTimer(nil);
if Watch.ElapsedMilliseconds>30000 then raise Exception.Create('Native comparison timeout');
TThread.Sleep(10);
until Form.HistoryStatus.Text.Contains('1 changed pixels');
Check(Form.HistoryList.Count=250,'Actual Compare command loads layout changes');
Check(not Form.HistoryDifferenceImage.Bitmap.IsEmpty,'Actual Compare command loads mask');
Form.HistoryCompareClick(Form.HistoryCompareButton);
Form.HistoryBeforePath.Text:='absent.dfm';
Watch:=TStopwatch.StartNew;
repeat Form.PollTimerTimer(nil);
if Watch.ElapsedMilliseconds>30000 then raise Exception.Create('Stale comparison timeout');
TThread.Sleep(10);
until Form.StatusLabel.Text.Contains('Screen history comparison ready');
Check(Form.HistoryDifferenceImage.Bitmap.IsEmpty,'Late response for changed selection is discarded');
finally Form.Free;
end;

 finally if CatalogExisted then TFile.WriteAllBytes(Catalog,CatalogBytes) else if TFile.Exists(Catalog) then TFile.Delete(Catalog);
end;

 Check((not TFile.Exists(Catalog) and (CatalogHash='')) or (TFile.Exists(Catalog) and (THashSHA2.GetHashStringFromFile(Catalog)=CatalogHash)),'Owner catalog unchanged');
Check(THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'Main.dfm'))=SourceHash,'Worker and native comparison leave source unchanged');

 finally Response.Free;
end;

 Request.BeforeScreenshot:=-1;
Worker.Submit(Request);
Response:=WaitResponse;
try Check(Response.Failed and (Response.ScreenHistory=nil),'Unknown screenshot ID refused without stale report');
finally Response.Free;
end;
Request.BeforeScreenshot:=BeforeID;

 Request.BeforeScreenSource:='absent.dfm';
Worker.Submit(Request);
Response:=WaitResponse;
try Check(not Response.Failed and Response.ScreenHistory.TryGetValue<string>('layout_gap',Text),'Unavailable layout preserves image comparison with explicit gap');
finally Response.Free;
end;
Request.BeforeScreenSource:='main.dfm';

 Store:=TDPHKnowledgeStore.Create(Database,Fixture,TPath.Combine(Root,'migrations'));
try OldFile:=Store.LoadWorkspaceView(Before.GetValue<Int64>('generation_id'));
finally Store.Free;
end;

 // Simulate a removed retained view by locating only its managed JSON file.
 for Text in TDirectory.GetFiles(Database+'.views','*.json') do if TFile.ReadAllText(Text,TEncoding.UTF8)=OldFile then begin TFile.Move(Text,Text+'.held');
OldFile:=Text;
Break;
end;

 try Worker.Submit(Request);
Response:=WaitResponse;
try Check(not Response.Failed and Response.ScreenHistory.TryGetValue<string>('layout_gap',Text),'Removed retained capture does not invent historical layout');
Check(Response.ScreenHistory.GetValue<Integer>('changed_pixels')=1,'Image comparison survives missing layout cache');
finally Response.Free;
end;

 finally if TFile.Exists(OldFile+'.held') then TFile.Move(OldFile+'.held',OldFile);
end;

 finally Worker.Free;
end;

 Log:=TJSONObject.Create;
try Log.AddPair('result','PASS').AddPair('checks',TJSONNumber.Create(Checks)).AddPair('qualification','Actual parser, two persisted generations, managed attributed PNGs, exact pixel comparisons, retained-cache worker and native FMX controls. Synthetic images are controlled test data, not observed target-runtime screenshots.');
TFile.WriteAllText(TPath.Combine(Root,'docs\validation\reports\phase1-screen-history-validation.json'),Log.Format,TEncoding.UTF8);
finally Log.Free;
end;

 finally Before.Free;
After.Free;
end;

 Writeln('Screen history validation passed: ',Checks,' checks.');

 except on E:Exception do begin Writeln(E.ClassName,': ',E.Message);
ExitCode:=1;
end;
end;

end.
