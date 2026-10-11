unit DPH.UI.Main;
interface
uses System.Classes, System.SysUtils, System.Types, System.UITypes, System.JSON, System.Generics.Collections,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Controls.Presentation, FMX.StdCtrls,
  FMX.Layouts, FMX.ListBox, FMX.Edit, FMX.Memo, FMX.Text, FMX.TabControl, FMX.Dialogs,
  FMX.Objects, FMX.Graphics, DPH.Workspace.Model, DPH.Workspace.Worker;
type
  TDPHMainForm = class(TForm)
    BaselineLabel,StatusLabel,BreadcrumbLabel,ScreenWarning,GraphLegend: TLabel;
    HeaderLayout,CommandLayout,ExplorerLayout,InspectorLayout,FilterLayout,ScreenToolbar,GraphToolbar: TLayout;
    ExplorerSplitter,InspectorSplitter: TSplitter;
    OpenProjectButton,OpenCacheButton,FullScanButton,BackButton,BookmarkButton,BookmarksButton,NextPageButton,ParentButton,FullscreenButton: TButton;
    SearchEdit,DefinesEdit,ExternalRootsEdit: TEdit;
    ConfigurationCombo,PlatformCombo,KindCombo,GraphCombo,ScreenModeCombo,FormCombo: TComboBox;
    ExplorerList,RelationsList: TListBox;
    WorkspaceTabs: TTabControl;
    OverviewTab,SourceTab,GraphTab,ScreenTab,RelationsTab: TTabItem;
    OverviewMemo,SourceMemo,InspectorMemo: TMemo;
    GraphScroll,ScreenScroll: TScrollBox;
    GraphPaint,ScreenPaint: TPaintBox;
    GraphNodeStyle,ScreenNodeStyle,HeaderStyle: TRectangle;
    OpenProjectDialog,OpenCacheDialog: TOpenDialog;
    DatabaseDialog: TSaveDialog;
    PollTimer,ChangeTimer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure OpenProjectClick(Sender: TObject);
    procedure OpenCacheClick(Sender: TObject);
    procedure FullScanClick(Sender: TObject);
    procedure PollTimerTimer(Sender: TObject);
    procedure ChangeTimerTimer(Sender: TObject);
    procedure SearchChange(Sender: TObject);
    procedure ExplorerClick(Sender: TObject);
    procedure RelationsClick(Sender: TObject);
    procedure BackClick(Sender: TObject);
    procedure ParentClick(Sender: TObject);
    procedure NextPageClick(Sender: TObject);
    procedure BookmarkClick(Sender: TObject);
    procedure BookmarksClick(Sender: TObject);
    procedure ViewChange(Sender: TObject);
    procedure GraphPaintPaint(Sender: TObject; Canvas: TCanvas);
    procedure GraphMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,Y: Single);
    procedure ScreenPaintPaint(Sender: TObject; Canvas: TCanvas);
    procedure ScreenMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,Y: Single);
    procedure FullscreenClick(Sender: TObject);
  private
    FWorker: TDPHWorkspaceWorker;
    FView: TDPHWorkspaceView;
    FGraph,FScreen: TJSONObject;
    FExplorerKeys,FRelationKeys,FHistory,FBookmarks: TList<string>;
    FEntry,FDatabase,FSelected,FScope,FBaseDirectory: string;
    FPage: Integer;
    FBusy,FDetached,FClosing,FBinding: Boolean;
    FScreenScale: Single;
    procedure Submit(const ACommand: string);
    procedure RefreshExplorer;
    procedure SelectSymbol(const AKey: string; AHistory: Boolean = True);
    procedure RefreshGraphics;
    function GraphRect(AIndex: Integer): TRectF;
  public
    procedure LoadView(ADocument: TJSONObject);
    property WorkspaceView: TDPHWorkspaceView read FView;
  end;
var DPHMainForm: TDPHMainForm;
implementation
uses System.IOUtils, System.StrUtils, System.Math,
  DPH.Workspace.Screen, DPH.Project.Source, DPH.Parse.Model;
{$R *.fmx}
procedure TDPHMainForm.FormCreate(Sender: TObject);
var I: Integer; Pref: TJSONObject; PrefPath: string;
begin
  FExplorerKeys:=TList<string>.Create; FRelationKeys:=TList<string>.Create;
  FHistory:=TList<string>.Create; FBookmarks:=TList<string>.Create; FDetached:=True;
  FBaseDirectory:=ExtractFilePath(ParamStr(0));
  for I:=0 to 5 do begin if TDirectory.Exists(TPath.Combine(FBaseDirectory,'migrations')) then Break; FBaseDirectory:=ExtractFileDir(ExcludeTrailingPathDelimiter(FBaseDirectory)); end;
  FWorker:=TDPHWorkspaceWorker.Create(FBaseDirectory);
  if SameText(ExtractFileExt(ParamStr(1)),'.dphdb') then begin FDatabase:=ParamStr(1); Submit('open'); end;
  if ParamCount=0 then
  begin
    PrefPath:=TPath.Combine(TPath.GetHomePath,'AppData\Local\DPH\workspace.json');
    if TFile.Exists(PrefPath) then
    try Pref:=TJSONObject.ParseJSONValue(TFile.ReadAllText(PrefPath,TEncoding.UTF8)) as TJSONObject;
      try if Pref<>nil then begin FDatabase:=Pref.GetValue<string>('database',''); if TFile.Exists(FDatabase) then Submit('open'); end; finally Pref.Free; end;
    except on E: Exception do StatusLabel.Text:='Workspace preferences unavailable: '+E.Message; end;
  end;
end;
procedure TDPHMainForm.FormDestroy(Sender: TObject);
var Pref: TJSONObject; PrefPath: string;
begin
  PollTimer.Enabled:=False; ChangeTimer.Enabled:=False; FWorker.Free;
  if (FDatabase<>'') and (FView<>nil) then
  try
    PrefPath:=TPath.Combine(TPath.GetHomePath,'AppData\Local\DPH'); TDirectory.CreateDirectory(PrefPath);
    Pref:=TJSONObject.Create; try Pref.AddPair('database',FDatabase); TFile.WriteAllText(TPath.Combine(PrefPath,'workspace.json'),Pref.ToJSON,TEncoding.UTF8); finally Pref.Free; end;
  except end;
  FView.Free; FGraph.Free; FScreen.Free; FExplorerKeys.Free; FRelationKeys.Free; FHistory.Free; FBookmarks.Free;
end;
procedure TDPHMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin CanClose:=not FBusy; if not CanClose then begin FClosing:=True; FWorker.Stop; StatusLabel.Text:='Cancelling at a safe analysis boundary…'; end; end;
procedure TDPHMainForm.Submit(const ACommand: string);
var R: TDPHWorkspaceRequest;
begin
  if FBusy then Exit;
  R.Command:=ACommand; R.Database:=FDatabase; R.Entry:=FEntry;
  R.Configuration:=ConfigurationCombo.Items[ConfigurationCombo.ItemIndex]; R.Platform:=PlatformCombo.Items[PlatformCombo.ItemIndex];
  R.Defines:=DefinesEdit.Text.Split([';'],TStringSplitOptions.ExcludeEmpty); R.ExternalRoots:=ExternalRootsEdit.Text.Split([';'],TStringSplitOptions.ExcludeEmpty);
  FWorker.Submit(R); FBusy:=True; StatusLabel.Text:='Working in background…';
end;
procedure TDPHMainForm.OpenProjectClick(Sender: TObject);
begin
  if FBusy or not OpenProjectDialog.Execute then Exit;
  if (FDatabase='') or ((FView<>nil) and not SameFileName(FView.Document.GetValue<string>('root'),ExtractFilePath(OpenProjectDialog.FileName))) then
  begin if not DatabaseDialog.Execute then Exit; FDatabase:=DatabaseDialog.FileName; end;
  FEntry:=OpenProjectDialog.FileName; FDetached:=False; Submit('incremental');
end;
procedure TDPHMainForm.OpenCacheClick(Sender: TObject);
begin if FBusy or not OpenCacheDialog.Execute then Exit; FDatabase:=OpenCacheDialog.FileName; FEntry:=''; FDetached:=True; Submit('open'); end;
procedure TDPHMainForm.FullScanClick(Sender: TObject);
begin if FEntry='' then StatusLabel.Text:='Attach the source project first' else Submit('full'); end;
procedure TDPHMainForm.PollTimerTimer(Sender: TObject);
var R: TDPHWorkspaceResponse;
begin
  if FClosing and FWorker.Finished then begin FBusy:=False; Close; Exit; end;
  while FWorker.Poll(R) do
  try
    FBusy:=R.Busy; FDetached:=R.Detached;
    if R.Document<>nil then begin LoadView(R.Document); R.Document:=nil; end;
    StatusLabel.Text:=R.MessageText; if FView<>nil then StatusLabel.Text:=StatusLabel.Text+' | '+FView.FlagsText;
  finally R.Free; end;
end;
procedure TDPHMainForm.ChangeTimerTimer(Sender: TObject);
begin if not FBusy and not FDetached and (FEntry<>'') then Submit('check'); end;
procedure TDPHMainForm.LoadView(ADocument: TJSONObject);
var V: TJSONValue; Row: TJSONObject; Path: string;
begin
  FreeAndNil(FView); FView:=TDPHWorkspaceView.Create(ADocument); FSelected:=''; FScope:=''; FPage:=0; FHistory.Clear; FBookmarks.Clear;
  FBinding:=True;
  try
    FormCombo.Items.Clear;
    for V in ADocument.GetValue<TJSONArray>('syntax.files') do begin Row:=V as TJSONObject; Path:=Row.GetValue<string>('path');
      if MatchText(ExtractFileExt(Path),['.fmx','.dfm']) and (Row.GetValue('ir')<>nil) then FormCombo.Items.Add(Path);
    end;
    if FormCombo.Items.Count>0 then FormCombo.ItemIndex:=0;
    OverviewMemo.Text:=FView.FlagsText+sLineBreak+'Selected project: '+ADocument.GetValue<string>('entry')+sLineBreak+
      'Configuration: '+ADocument.GetValue<string>('configuration')+' / '+ADocument.GetValue<string>('platform')+sLineBreak+
      'Technical evidence is static. Business rationale and user procedures require attributed human review.'+sLineBreak+
      ADocument.GetValue<TJSONObject>('semantics').GetValue<TJSONArray>('diagnostics').Format(2);
  finally FBinding:=False; end;
  RefreshExplorer; RefreshGraphics;
end;
procedure TDPHMainForm.RefreshExplorer;
var Rows: TJSONArray; V: TJSONValue; S: TJSONObject; Kind: string;
begin
  if FView=nil then Exit; Kind:=''; if KindCombo.ItemIndex>0 then Kind:=KindCombo.Items[KindCombo.ItemIndex];
  Rows:=FView.Search(SearchEdit.Text,Kind,FScope,FPage,250);
  try
    ExplorerList.Items.BeginUpdate;
    try ExplorerList.Items.Clear; FExplorerKeys.Clear;
      for V in Rows do begin S:=V as TJSONObject; ExplorerList.Items.Add(S.GetValue<string>('kind')+'  '+S.GetValue<string>('name')); FExplorerKeys.Add(S.GetValue<string>('key')); end;
    finally ExplorerList.Items.EndUpdate; end;
    BreadcrumbLabel.Text:='Project / '+FScope+' | page '+IntToStr(FPage div 250+1)+' | '+IntToStr(Rows.Count)+' objects';
  finally Rows.Free; end;
end;
procedure TDPHMainForm.SearchChange(Sender: TObject);
begin if FBinding then Exit; FScope:=''; FPage:=0; RefreshExplorer; end;
procedure TDPHMainForm.ExplorerClick(Sender: TObject);
begin if (ExplorerList.ItemIndex>=0) and (ExplorerList.ItemIndex<FExplorerKeys.Count) then SelectSymbol(FExplorerKeys[ExplorerList.ItemIndex]); end;
procedure TDPHMainForm.SelectSymbol(const AKey: string; AHistory: Boolean);
var S,Range,Row: TJSONObject; Rows,Props: TJSONArray; V: TJSONValue; Path,Direction,Target: string; Source: TDPHSource; Diagnostics: TDPHDiagnostics;
begin
  if FView=nil then Exit; S:=FView.Symbol(AKey); if S=nil then Exit;
  if AHistory and (FSelected<>'') and (FSelected<>AKey) then FHistory.Add(FSelected); FSelected:=AKey;
  Props:=FView.Properties(AKey); try InspectorMemo.Text:=S.Format(2)+sLineBreak+'Serialized properties:'+sLineBreak+Props.Format(2); finally Props.Free; end;
  RelationsList.Items.Clear; FRelationKeys.Clear;
  for Direction in ['forward','reverse'] do begin Rows:=FView.Neighbors(AKey,Direction); try for V in Rows do begin Row:=V as TJSONObject;
    Target:=Row.GetValue<string>('to',''); if Direction='reverse' then Target:=Row.GetValue<string>('from');
    RelationsList.Items.Add(Direction+' '+Row.GetValue<string>('kind')+' ['+Row.GetValue<string>('resolution')+'] '+Row.GetValue<string>('label')+' '+Target); FRelationKeys.Add(Target);
  end; finally Rows.Free; end; end;
  Range:=S.GetValue<TJSONObject>('range'); Path:=Range.GetValue<string>('source'); Row:=FView.SourceFile(Path);
  SourceMemo.Text:='Source unavailable in detached mode. Cached source range: '+Range.ToJSON;
  if not FDetached and (FEntry<>'') and (Row<>nil) then
  begin
    Path:=TPath.GetFullPath(TPath.Combine(ExtractFilePath(FEntry),Path));
    if StartsText(IncludeTrailingPathDelimiter(ExtractFilePath(FEntry)),Path) then
    begin
      Diagnostics:=TDPHDiagnostics.Create;
      try
        try Source:=TDPHSource.Create(Path,Range.GetValue<string>('source'),Diagnostics);
          try if Source.Decoded and SameText(Source.SHA256,Row.GetValue<string>('sha256')) then begin SourceMemo.Text:=Source.Text;
            SourceMemo.CaretPosition:=TCaretPosition.Create(Max(0,Range.GetValue<Integer>('line')-1),Max(0,Range.GetValue<Integer>('column')-1)); end
            else SourceMemo.Text:='STALE or undecodable source — cached range not applied.'; finally Source.Free; end;
        except on E: Exception do SourceMemo.Text:='Source unavailable: '+E.Message; end;
      finally Diagnostics.Free; end;
    end;
  end;
  if MatchText(S.GetValue<string>('kind'),['unit','type','component','routine','anonymous']) then begin FScope:=S.GetValue<string>('name'); FPage:=0; RefreshExplorer; end;
  RefreshGraphics;
end;
procedure TDPHMainForm.RelationsClick(Sender: TObject);
begin if (RelationsList.ItemIndex>=0) and (RelationsList.ItemIndex<FRelationKeys.Count) then SelectSymbol(FRelationKeys[RelationsList.ItemIndex]); end;
procedure TDPHMainForm.BackClick(Sender: TObject);
var Key: string;
begin if FHistory.Count=0 then Exit; Key:=FHistory.Last; FHistory.Delete(FHistory.Count-1); SelectSymbol(Key,False); end;
procedure TDPHMainForm.ParentClick(Sender: TObject);
var P: Integer;
begin P:=LastDelimiter('.',FScope); if P=0 then FScope:='' else FScope:=Copy(FScope,1,P-1); FPage:=0; RefreshExplorer; end;
procedure TDPHMainForm.NextPageClick(Sender: TObject);
begin Inc(FPage,250); RefreshExplorer; end;
procedure TDPHMainForm.BookmarkClick(Sender: TObject);
begin if (FSelected<>'') and not FBookmarks.Contains(FSelected) then FBookmarks.Add(FSelected); end;
procedure TDPHMainForm.BookmarksClick(Sender: TObject);
var Key: string; S: TJSONObject;
begin
  ExplorerList.Items.Clear; FExplorerKeys.Clear; if FView=nil then Exit;
  for Key in FBookmarks do begin S:=FView.Symbol(Key); if S<>nil then begin ExplorerList.Items.Add(S.GetValue<string>('name')); FExplorerKeys.Add(Key); end; end;
  BreadcrumbLabel.Text:='Bookmarks for this captured generation';
end;
procedure TDPHMainForm.ViewChange(Sender: TObject);
begin if not FBinding then RefreshGraphics; end;
procedure TDPHMainForm.RefreshGraphics;
begin
  FreeAndNil(FGraph); FreeAndNil(FScreen); if FView=nil then Exit;
  if GraphCombo.ItemIndex>=0 then FGraph:=FView.Graph(GraphCombo.Items[GraphCombo.ItemIndex],FSelected);
  if ScreenModeCombo.ItemIndex=0 then FScreen:=TDPHScreenLayout.Gallery(FView)
  else if FormCombo.ItemIndex>=0 then FScreen:=TDPHScreenLayout.Reconstruct(FView,FormCombo.Items[FormCombo.ItemIndex]);
  GraphPaint.Repaint; ScreenPaint.Repaint;
end;
function TDPHMainForm.GraphRect(AIndex: Integer): TRectF;
var Columns: Integer; W,H: Single;
begin
  W:=GraphNodeStyle.Width+GraphNodeStyle.Margins.Right; H:=GraphNodeStyle.Height+GraphNodeStyle.Margins.Bottom;
  Columns:=Max(1,Trunc(GraphPaint.Width/W)); Result:=TRectF.Create(10+(AIndex mod Columns)*W,10+(AIndex div Columns)*H,10+(AIndex mod Columns)*W+GraphNodeStyle.Width,10+(AIndex div Columns)*H+GraphNodeStyle.Height);
end;
procedure TDPHMainForm.GraphPaintPaint(Sender: TObject; Canvas: TCanvas);
var Nodes,Edges: TJSONArray; V: TJSONValue; E,N: TJSONObject; I,A,B: Integer; R: TRectF;
begin
  if FGraph=nil then Exit; Nodes:=FGraph.GetValue<TJSONArray>('nodes'); Edges:=FGraph.GetValue<TJSONArray>('edges');
  for V in Edges do begin E:=V as TJSONObject; A:=-1; B:=-1;
    for I:=0 to Nodes.Count-1 do begin N:=Nodes.Items[I] as TJSONObject;
      if N.GetValue('id').Value=E.GetValue('from').Value then A:=I; if N.GetValue('id').Value=E.GetValue('to').Value then B:=I;
    end;
  Canvas.Stroke.Assign(GraphNodeStyle.Stroke); if E.GetValue<string>('resolution','')<>'confirmed_static' then begin Canvas.Stroke.Color:=HeaderStyle.Fill.Color; Canvas.Stroke.Dash:=TStrokeDash.Dash; end;
    if (A>=0) and (B>=0) then begin Canvas.DrawLine(GraphRect(A).CenterPoint,GraphRect(B).CenterPoint,1);
      Canvas.DrawLine(GraphRect(B).CenterPoint,TPointF.Create(GraphRect(B).CenterPoint.X-6,GraphRect(B).CenterPoint.Y-8),1);
      Canvas.DrawLine(GraphRect(B).CenterPoint,TPointF.Create(GraphRect(B).CenterPoint.X+6,GraphRect(B).CenterPoint.Y-8),1); end;
  end;
  for I:=0 to Nodes.Count-1 do begin N:=Nodes.Items[I] as TJSONObject; R:=GraphRect(I);
    Canvas.Fill.Assign(GraphNodeStyle.Fill); Canvas.FillRect(R,4,4,AllCorners,1); Canvas.Stroke.Assign(GraphNodeStyle.Stroke); Canvas.DrawRect(R,4,4,AllCorners,1);
    Canvas.Fill.Color:=GraphNodeStyle.Stroke.Color; Canvas.FillText(R,Copy(N.GetValue<string>('label'),1,160),True,1,[],TTextAlign.Center,TTextAlign.Center);
  end;
end;
procedure TDPHMainForm.GraphMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,Y: Single);
var I: Integer; N: TJSONObject; Nodes: TJSONArray;
begin
  if FGraph=nil then Exit; Nodes:=FGraph.GetValue<TJSONArray>('nodes');
  for I:=0 to Nodes.Count-1 do if GraphRect(I).Contains(TPointF.Create(X,Y)) then begin N:=Nodes.Items[I] as TJSONObject;
    if FGraph.GetValue<string>('kind')='Procedure CFG' then InspectorMemo.Text:=N.Format(2) else SelectSymbol(N.GetValue<string>('id')); Break;
  end;
end;
procedure TDPHMainForm.ScreenPaintPaint(Sender: TObject; Canvas: TCanvas);
var Rows: TJSONArray; V: TJSONValue; R: TJSONObject; Bounds: TRectF; W,H: Single;
begin
  if FScreen=nil then Exit; Rows:=FScreen.GetValue<TJSONArray>('components'); W:=800; H:=600;
  if Rows.Count>0 then begin R:=Rows.Items[0] as TJSONObject; W:=R.GetValue<Double>('width'); H:=R.GetValue<Double>('height'); end;
  FScreenScale:=1; case ScreenModeCombo.ItemIndex of
    0: FScreenScale:=Min(0.35,Min(ScreenScroll.Width/W,ScreenScroll.Height/H));
    1,4: FScreenScale:=Min(ScreenScroll.Width/W,ScreenScroll.Height/H);
    3: FScreenScale:=2;
  end;
  FScreenScale:=Max(0.01,FScreenScale);
  for V in Rows do begin R:=V as TJSONObject;
    Bounds:=TRectF.Create(R.GetValue<Double>('x')*FScreenScale,R.GetValue<Double>('y')*FScreenScale,(R.GetValue<Double>('x')+R.GetValue<Double>('width'))*FScreenScale,(R.GetValue<Double>('y')+R.GetValue<Double>('height'))*FScreenScale);
    Canvas.Fill.Assign(ScreenNodeStyle.Fill); Canvas.FillRect(Bounds,0,0,AllCorners,1); Canvas.Stroke.Assign(ScreenNodeStyle.Stroke); Canvas.DrawRect(Bounds,0,0,AllCorners,1);
    Canvas.Fill.Color:=ScreenNodeStyle.Stroke.Color; Canvas.FillText(Bounds,Copy(R.GetValue<string>('caption'),1,100),True,1,[],TTextAlign.Leading,TTextAlign.Center);
  end;
end;
procedure TDPHMainForm.ScreenMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,Y: Single);
var Rows: TJSONArray; R: TJSONObject; I: Integer; Bounds: TRectF;
begin
  if (FScreen=nil) or (FScreenScale<=0) then Exit; Rows:=FScreen.GetValue<TJSONArray>('components');
  for I:=Rows.Count-1 downto 0 do begin R:=Rows.Items[I] as TJSONObject;
    Bounds:=TRectF.Create(R.GetValue<Double>('x'),R.GetValue<Double>('y'),R.GetValue<Double>('x')+R.GetValue<Double>('width'),R.GetValue<Double>('y')+R.GetValue<Double>('height'));
    if Bounds.Contains(TPointF.Create(X/FScreenScale,Y/FScreenScale)) then begin SelectSymbol(R.GetValue<string>('key','')); Break; end;
  end;
end;
procedure TDPHMainForm.FullscreenClick(Sender: TObject);
begin if WindowState=TWindowState.wsMaximized then WindowState:=TWindowState.wsNormal else WindowState:=TWindowState.wsMaximized; end;
end.
