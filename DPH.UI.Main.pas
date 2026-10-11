unit DPH.UI.Main;
interface
uses System.Classes, System.SysUtils, System.Types, System.UITypes, System.JSON, System.Generics.Collections,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Controls.Presentation, FMX.StdCtrls,
  FMX.Layouts, FMX.ListBox, FMX.Edit, FMX.Memo, FMX.Text, FMX.TabControl, FMX.Dialogs,
  FMX.Objects, FMX.Graphics, FMX.WebBrowser, DPH.Workspace.Model, DPH.Workspace.Worker,
  DPH.Publish.Model, DPH.Analysis.Explanations, DPH.Workspace.Catalog;
type
  TDPHMainForm = class(TForm)
    BaselineLabel,StatusLabel,BreadcrumbLabel,ScreenWarning,GraphLegend,InspectorTitle,InspectorPurpose: TLabel;
    CommandScroll: THorzScrollBox;
    HeaderLayout,CommandLayout,ExplorerLayout,InspectorLayout,FilterLayout,ScreenToolbar,GraphToolbar: TLayout;
    ExplorerSplitter,InspectorSplitter: TSplitter;
    OpenProjectButton,OpenCacheButton,FullScanButton,BackButton,BookmarkButton,BookmarksButton,NextPageButton,ParentButton,FullscreenButton: TButton;
    SearchEdit,DefinesEdit,ExternalRootsEdit,CodePageEdit: TEdit;
    CodePageLabel: TLabel;
    WholeProgramGraphButton,AllFormsGraphButton,ExplorerExpandButton: TButton;
    ConfigurationCombo,PlatformCombo,KindCombo,GraphCombo,ScreenModeCombo,FormCombo: TComboBox;
    ExplorerList,RelationsList: TListBox;
    DetailsList: TListBox;
    DetailsMemo: TMemo;
    DetailsTitle: TLabel;
    DetailsSourceButton: TButton;
    DetailsTab: TTabItem;
    WorkspaceTabs: TTabControl;
    OverviewTab,SourceTab,GraphTab,ScreenTab,RelationsTab: TTabItem;
    OverviewMemo,SourceMemo,InspectorMemo: TMemo;
    GraphScroll,ScreenScroll: TScrollBox;
    GraphPaint,ScreenPaint: TPaintBox;
    GraphNodeStyle,ScreenNodeStyle,HeaderStyle: TRectangle;
    OpenProjectDialog,OpenCacheDialog: TOpenDialog;
    DatabaseDialog: TSaveDialog;
    PollTimer,ChangeTimer: TTimer;
    KnowledgeTab: TTabItem;
    KnowledgeToolbar,KnowledgeEditorLayout: TLayout;
    KnowledgeList: TListBox;
    KnowledgeTitleEdit,KnowledgeAuthorEdit: TEdit;
    KnowledgeKindCombo: TComboBox;
    KnowledgeBodyMemo,KnowledgeHistoryMemo: TMemo;
    NewKnowledgeButton,SaveKnowledgeButton,RefreshKnowledgeButton,VerifyKnowledgeButton,RejectKnowledgeButton,RetireKnowledgeButton,DiscardKnowledgeButton: TButton;
    PendingKnowledgeCheck: TCheckBox;
    KnowledgeWarning: TLabel;
    PublishTab: TTabItem;
    PublishToolbar: TLayout;
    PublishScopeCombo: TComboBox;
    PublishExclusionsEdit: TEdit;
    PublishButton,PreviewButton: TButton;
    PublishMemo: TMemo;
    PublishBrowser: TWebBrowser;
    ExportDialog: TSaveDialog;
    RelocateButton: TButton;
    LearningTopics: TListBox;
    LearningBrowser,ExplainBrowser,FlowBrowser: TWebBrowser;
    ExplainTab: TTabItem;
    ExplainFallback: TMemo;
    ScreenshotTab: TTabItem;
    ScreenshotToolbar: TLayout;
    ScreenshotAuthor,ScreenshotCaption: TEdit;
    ImportScreenshotButton: TButton;
    ScreenshotList: TListBox;
    ScreenshotImage: TImage;
    ScreenshotEvidence: TMemo;
    ScreenshotDialog: TOpenDialog;
    HelpButton: TButton;
    HelpTab: TTabItem;
    HelpBrowser: TWebBrowser;
    HelpFallback: TMemo;
    ProjectsTab: TTabItem;
    ProjectsToolbar: TLayout;
    ProjectsList: TListBox;
    ProjectsPurpose: TLabel;
    OpenKnownProjectButton,ForgetProjectButton,RefreshProjectsButton: TButton;
    LifecycleTab: TTabItem;
    LifecycleToolbar: TLayout;
    LifecyclePurpose: TLabel;
    RetentionCountEdit,ReleaseLabelEdit,ReleaseReviewerEdit: TEdit;
    PreviewRetentionButton,ApplyRetentionButton,PinReleaseButton: TButton;
    LifecycleMemo: TMemo;
    BackupButton,RestoreBackupButton,IntegrityButton: TButton;
    BackupDialog,RestoreDestinationDialog: TSaveDialog;
    RestoreBackupDialog: TOpenDialog;
    ContinuityTab: TTabItem;
    ContinuityPurpose: TLabel;
    ContinuityToolbar: TLayout;
    ContinuityQueryEdit,ContinuityReviewerEdit: TEdit;
    FindContinuityButton,ApproveContinuityButton: TButton;
    ContinuityList: TListBox;
    ContinuityMemo: TMemo;
    ProjectSearchTab: TTabItem;
    ProjectSearchPurpose: TLabel;
    ProjectSearchToolbar: TLayout;
    ProjectSearchEdit: TEdit;
    ProjectSearchKind: TComboBox;
    RunProjectSearchButton,NextProjectSearchButton,OpenSearchResultButton: TButton;
    ProjectSearchList: TListBox;
    ProjectSearchMemo: TMemo;
    WorkspacePageCombo: TComboBox;
    procedure WorkspacePageChange(Sender: TObject);
    procedure WholeProgramGraphClick(Sender: TObject);
    procedure AllFormsGraphClick(Sender: TObject);
    procedure ProjectSearchClick(Sender: TObject);
    procedure ProjectSearchSelectionClick(Sender: TObject);
    procedure RetentionClick(Sender: TObject);
    procedure DatabaseToolsClick(Sender: TObject);
    procedure ContinuityClick(Sender: TObject);
    procedure ContinuitySelectionClick(Sender: TObject);
    procedure OpenKnownProjectClick(Sender: TObject);
    procedure ForgetProjectClick(Sender: TObject);
    procedure RefreshProjectsClick(Sender: TObject);
    procedure HelpClick(Sender: TObject);
    procedure ImportScreenshotClick(Sender: TObject);
    procedure ScreenshotClick(Sender: TObject);
    procedure LearningClick(Sender: TObject);
    procedure LearningShouldLoad(Sender: TObject; const AURL: string; var ACancel: Boolean);
    procedure RelocateClick(Sender: TObject);
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
    procedure ExplorerExpandClick(Sender: TObject);
    procedure DetailsClick(Sender: TObject);
    procedure DetailsSourceClick(Sender: TObject);
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
    procedure KnowledgeClick(Sender: TObject);
    procedure NewKnowledgeClick(Sender: TObject);
    procedure SaveKnowledgeClick(Sender: TObject);
    procedure RefreshKnowledgeClick(Sender: TObject);
    procedure ReviewKnowledgeClick(Sender: TObject);
    procedure KnowledgeFilterChange(Sender: TObject);
    procedure KnowledgeEdited(Sender: TObject);
    procedure DiscardKnowledgeClick(Sender: TObject);
    procedure PublishClick(Sender: TObject);
    procedure PreviewClick(Sender: TObject);
    procedure BrowserShouldLoad(Sender: TObject; const AURL: string; var ACancel: Boolean);
  private
    FWorker: TDPHWorkspaceWorker;
    FView: TDPHWorkspaceView;
    FGraph,FScreen: TJSONObject;
    FExplorerKeys,FRelationKeys,FHistory,FBookmarks,FExpandedKeys: TList<string>;
    FHierarchyVisible: Boolean;
    FDetails: TJSONArray;
    FEntry,FDatabase,FSelected,FScope,FBaseDirectory: string;
    FPendingEntry,FPendingDatabase: string;
    FPage: Integer;
    FBusy,FDetached,FClosing,FBinding: Boolean;
    FScreenScale: Single;
    FKnowledge: TJSONArray;
    FKnowledgeRows: TList<TJSONObject>;
    FKnowledgeID,FKnowledgeRevision: Int64;
    FReviewState: string;
    FKnowledgeEdited: Boolean;
    FPendingCommand,FSavedKnowledgeText,FKnowledgeLink: string;
    FExportDirectory: string;
    FLearningFacts: TDPHDocumentModel;
    FExplanations: TDPHExplanationModel;
    FLearningDirectory,FExplainDirectory,FFlowDirectory: string;
    FImages: TJSONArray;
    FCatalog: TDPHWorkspaceCatalog;
    FCatalogPaths: TList<string>;
    FContinuity: TJSONArray;
    FSearchResults: TJSONArray;
    FSearchOffset: Integer;
    FSearchQuery: string;
    FSearchKind: string;
    FWholeGraph: Boolean;
    procedure LoadScreenshots(ARows: TJSONArray);
    procedure RefreshLearning;
    procedure ShowExplanation;
    procedure Submit(const ACommand: string);
    procedure RefreshExplorer;
    procedure SelectSymbol(const AKey: string; AHistory: Boolean = True);
    procedure RefreshGraphics;
    procedure ClearWorkspace;
    function GraphRect(AIndex: Integer): TRectF;
  public
    procedure OpenSelection(const AEntry,ADatabase: string);
    procedure LoadView(ADocument: TJSONObject);
    procedure LoadKnowledge(ARows: TJSONArray);
    property WorkspaceView: TDPHWorkspaceView read FView;
  end;
var DPHMainForm: TDPHMainForm;
implementation
uses System.IOUtils, System.StrUtils, System.Math, System.Hash,
  Winapi.EdgeUtils, DPH.Workspace.Screen, DPH.Project.Source, DPH.Parse.Model, DPH.Publish.BrowserPolicy;
{$R *.fmx}
procedure TDPHMainForm.FormCreate(Sender: TObject);
var I: Integer; DatabaseDirectory: string;
begin
  FExplorerKeys:=TList<string>.Create; FRelationKeys:=TList<string>.Create; FExpandedKeys:=TList<string>.Create;
  FHistory:=TList<string>.Create; FBookmarks:=TList<string>.Create; FDetached:=True;
  FKnowledgeRows:=TList<TJSONObject>.Create;
  FCatalogPaths:=TList<string>.Create;
  try FCatalog:=TDPHWorkspaceCatalog.Create(TDPHWorkspaceCatalog.DefaultPath);
  except on E: Exception do StatusLabel.Text:='Workspace catalog unavailable: '+E.Message; end;
  RefreshProjectsClick(nil);
  FBaseDirectory:=ExtractFilePath(ParamStr(0));
  for I:=0 to 5 do begin if TDirectory.Exists(TPath.Combine(FBaseDirectory,'migrations')) then Break; FBaseDirectory:=ExtractFileDir(ExcludeTrailingPathDelimiter(FBaseDirectory)); end;
  DatabaseDirectory:=TPath.Combine(FBaseDirectory,DatabaseDialog.InitialDir);
  try
    TDirectory.CreateDirectory(DatabaseDirectory);
    DatabaseDialog.InitialDir:=DatabaseDirectory; OpenCacheDialog.InitialDir:=DatabaseDirectory;
    BackupDialog.InitialDir:=DatabaseDirectory; RestoreBackupDialog.InitialDir:=DatabaseDirectory;
    RestoreDestinationDialog.InitialDir:=DatabaseDirectory;
  except on E: Exception do StatusLabel.Text:='Cannot prepare Databases folder: '+E.Message; end;
  FWorker:=TDPHWorkspaceWorker.Create(FBaseDirectory);
  for I:=0 to 10 do LearningTopics.Items.Add(TDPHExplanationModel.TopicTitle(I));
  LearningTopics.ItemIndex:=0;
  OverviewMemo.Text:='Attach a Delphi project or open a cache to begin. Start here provides a guided route through the selected program; Explain describes any object you select.';
  HelpClick(nil);
  if SameText(ExtractFileExt(ParamStr(1)),'.dphdb') then OpenSelection('',ParamStr(1));
  if ParamCount=0 then
  begin
    if (FCatalog<>nil) and TFile.Exists(FCatalog.LastDatabase) then OpenSelection('',FCatalog.LastDatabase);
  end;
end;
procedure TDPHMainForm.FormDestroy(Sender: TObject);
var Directory: string;
begin
  PollTimer.Enabled:=False; ChangeTimer.Enabled:=False; FWorker.Free;
  FCatalog.Free; FCatalogPaths.Free;
  FContinuity.Free;
  FSearchResults.Free;
  FImages.Free; FExplanations.Free; FLearningFacts.Free;
  FView.Free; FGraph.Free; FScreen.Free; FExplorerKeys.Free; FRelationKeys.Free; FHistory.Free; FBookmarks.Free; FExpandedKeys.Free; FDetails.Free;
  FKnowledge.Free; FKnowledgeRows.Free;
  // Remove only this form's three generated preview files, never a recursive tree.
  if FLearningDirectory<>'' then
  try
    for Directory in [FExplainDirectory,FFlowDirectory,FLearningDirectory] do begin
      if TFile.Exists(TPath.Combine(Directory,'index.html')) then TFile.Delete(TPath.Combine(Directory,'index.html'));
      if TDirectory.Exists(Directory) then TDirectory.Delete(Directory,False);
    end;
  except end;
end;
procedure TDPHMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if FKnowledgeEdited then begin CanClose:=False; StatusLabel.Text:='Save or discard the authored text before closing'; Exit; end;
  CanClose:=not FBusy; if not CanClose then begin FClosing:=True; FWorker.Stop; StatusLabel.Text:='Cancelling at a safe analysis boundary...'; end;
end;
procedure TDPHMainForm.RefreshProjectsClick(Sender: TObject);
var Rows: TJSONArray; Value: TJSONValue; Path,LabelText: string;
begin
  ProjectsList.Items.Clear; FCatalogPaths.Clear;
  if FCatalog=nil then Exit;
  Rows:=FCatalog.Projects;
  try
    for Value in Rows do begin
      Path:=(Value as TJSONObject).GetValue<string>('database');
      LabelText:=TPath.GetFileNameWithoutExtension(Path)+' | '+Path;
      if not TFile.Exists(Path) then LabelText:='Missing database | '+LabelText;
      ProjectsList.Items.Add(LabelText); FCatalogPaths.Add(Path);
    end;
  finally Rows.Free; end;
end;
procedure TDPHMainForm.WorkspacePageChange(Sender: TObject);
var Index: Integer;
begin
  if FBinding then Exit;
  if Sender=WorkspacePageCombo then begin
    if WorkspacePageCombo.ItemIndex<0 then Exit;
    for Index:=0 to WorkspaceTabs.TabCount-1 do
      if WorkspaceTabs.Tabs[Index].Text=WorkspacePageCombo.Items[WorkspacePageCombo.ItemIndex] then begin
        WorkspaceTabs.ActiveTab:=WorkspaceTabs.Tabs[Index]; Break;
      end;
  end else if WorkspaceTabs.ActiveTab<>nil then begin
    FBinding:=True;
    try WorkspacePageCombo.ItemIndex:=WorkspacePageCombo.Items.IndexOf(WorkspaceTabs.ActiveTab.Text);
    finally FBinding:=False; end;
  end;
end;
procedure TDPHMainForm.ProjectSearchClick(Sender: TObject);
var Request: TDPHWorkspaceRequest; Row: TJSONObject; Index: Integer; Key: string;
begin
  if FBusy or (FView=nil) then Exit;
  if (Sender=OpenSearchResultButton) or (Sender=ProjectSearchList) then begin
    Index:=ProjectSearchList.ItemIndex;
    if (FSearchResults=nil) or (Index<0) then Exit;
    Row:=FSearchResults.Items[Index] as TJSONObject; Key:=Row.GetValue<string>('entity_key');
    if Key<>'' then begin SelectSymbol(Key); WorkspaceTabs.ActiveTab:=ExplainTab; Exit; end;
    if Row.GetValue<string>('kind')='knowledge' then begin
      if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current authored edit first'; Exit; end;
      PendingKnowledgeCheck.IsChecked:=False; KnowledgeFilterChange(nil);
      for Index:=0 to FKnowledgeRows.Count-1 do
        if FKnowledgeRows[Index].GetValue<string>('id')=Row.GetValue<string>('knowledge_id') then begin
          KnowledgeList.ItemIndex:=Index; KnowledgeClick(nil); WorkspaceTabs.ActiveTab:=KnowledgeTab; Exit;
        end;
    end;
    StatusLabel.Text:='This result is a diagnostic. Its message and source location are shown in the search details.'; Exit;
  end;
  Key:='';
  if ProjectSearchKind.ItemIndex>0 then Key:=ProjectSearchKind.Items[ProjectSearchKind.ItemIndex];
  if (Sender=NextProjectSearchButton) and (FSearchQuery=ProjectSearchEdit.Text) and (FSearchKind=Key) then
    Inc(FSearchOffset,50) else FSearchOffset:=0;
  FSearchQuery:=ProjectSearchEdit.Text; FSearchKind:=Key;
  Request:=Default(TDPHWorkspaceRequest); Request.Command:='search';
  Request.Database:=FDatabase; Request.Entry:=FEntry; Request.GenerationID:=FView.Document.GetValue<Int64>('generation_id');
  Request.Body:=ProjectSearchEdit.Text; Request.SearchOffset:=FSearchOffset;
  Request.SearchKind:=FSearchKind;
  FWorker.Submit(Request); FBusy:=True; StatusLabel.Text:='Searching the indexed project evidence and knowledge...';
end;
procedure TDPHMainForm.ProjectSearchSelectionClick(Sender: TObject);
var Row: TJSONObject;
begin
  if (FSearchResults=nil) or (ProjectSearchList.ItemIndex<0) then Exit;
  Row:=FSearchResults.Items[ProjectSearchList.ItemIndex] as TJSONObject;
  ProjectSearchMemo.Text:=Row.GetValue<string>('title')+sLineBreak+'Category: '+Row.GetValue<string>('kind')+
    ' | Status: '+Row.GetValue<string>('verification_state')+sLineBreak+'Source: '+Row.GetValue<string>('source_path')+
    sLineBreak+sLineBreak+Row.GetValue<string>('excerpt');
end;
procedure TDPHMainForm.RetentionClick(Sender: TObject);
var Request: TDPHWorkspaceRequest;
begin
  if FBusy or (FView=nil) then begin StatusLabel.Text:='Open a project and wait for its current operation to finish'; Exit; end;
  Request:=Default(TDPHWorkspaceRequest);
  Request.Command:='retention_preview';
  if Sender=ApplyRetentionButton then Request.Command:='retention_apply';
  if Sender=PinReleaseButton then Request.Command:='retention_pin';
  Request.Database:=FDatabase; Request.Entry:=FEntry;
  Request.GenerationID:=FView.Document.GetValue<Int64>('generation_id');
  Request.Body:=RetentionCountEdit.Text; Request.Title:=ReleaseLabelEdit.Text; Request.Editor:=ReleaseReviewerEdit.Text;
  FWorker.Submit(Request); FBusy:=True; StatusLabel.Text:='Preparing retention report...';
end;
procedure TDPHMainForm.DatabaseToolsClick(Sender: TObject);
var Request: TDPHWorkspaceRequest;
begin
  if FBusy then Exit;
  if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the authored edit before database operations'; Exit; end;
  Request:=Default(TDPHWorkspaceRequest); Request.Database:=FDatabase; Request.Entry:=FEntry;
  if Sender=RestoreBackupButton then begin
    if not RestoreBackupDialog.Execute then Exit;
    Request.Database:=RestoreBackupDialog.FileName;
    if not RestoreDestinationDialog.Execute then Exit;
    Request.ExportDirectory:=RestoreDestinationDialog.FileName; Request.Command:='restore_backup';
  end else begin
    if FView=nil then begin StatusLabel.Text:='Open a project database first'; Exit; end;
    Request.Command:='integrity';
    if Sender=BackupButton then begin
      BackupDialog.FileName:=TPath.GetFileNameWithoutExtension(FDatabase)+'-backup.dphdb';
      if not BackupDialog.Execute then Exit;
      Request.ExportDirectory:=BackupDialog.FileName; Request.Command:='save_backup';
    end;
  end;
  FWorker.Submit(Request); FBusy:=True; StatusLabel.Text:='Checking database files...';
end;
procedure TDPHMainForm.ContinuityClick(Sender: TObject);
var Request: TDPHWorkspaceRequest; Row: TJSONObject; Index: Integer;
begin
  if FBusy or (FView=nil) then Exit;
  if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the authored edit before continuity review'; Exit; end;
  Request:=Default(TDPHWorkspaceRequest); Request.Command:='continuity_preview';
  if not TryStrToInt(CodePageEdit.Text,Request.CodePage) or (Request.CodePage<0) or (Request.CodePage>65535) then begin StatusLabel.Text:='Enter code page 0 for Unicode or a Windows code page number from 1 to 65535'; Exit; end;
  Request.Database:=FDatabase; Request.Entry:=FEntry; Request.GenerationID:=FView.Document.GetValue<Int64>('generation_id');
  Request.Body:=ContinuityQueryEdit.Text; Request.Editor:=ContinuityReviewerEdit.Text;
  Request.Configuration:=ConfigurationCombo.Items[ConfigurationCombo.ItemIndex];
  Request.Platform:=PlatformCombo.Items[PlatformCombo.ItemIndex];
  Request.Defines:=DefinesEdit.Text.Split([';'],TStringSplitOptions.ExcludeEmpty);
  Request.ExternalRoots:=ExternalRootsEdit.Text.Split([';'],TStringSplitOptions.ExcludeEmpty);
  if Sender=ApproveContinuityButton then begin
    Index:=ContinuityList.ItemIndex;
    if (FContinuity=nil) or (Index<0) then begin StatusLabel.Text:='Select a proposed old-to-new identity match first'; Exit; end;
    Row:=FContinuity.Items[Index] as TJSONObject; Request.Command:='continuity_approve';
    Request.KnowledgeID:=StrToInt64(Row.GetValue<string>('knowledge_id'));
    Request.ExpectedRevision:=StrToInt64(Row.GetValue<string>('current_revision_id'));
    Request.OldEntityKey:=Row.GetValue<string>('old_key'); Request.EntityKey:=Row.GetValue<string>('new_key');
  end;
  FWorker.Submit(Request); FBusy:=True; StatusLabel.Text:='Checking identity continuity...';
end;
procedure TDPHMainForm.ContinuitySelectionClick(Sender: TObject);
var Row: TJSONObject;
begin
  if (FContinuity=nil) or (ContinuityList.ItemIndex<0) then Exit;
  Row:=FContinuity.Items[ContinuityList.ItemIndex] as TJSONObject;
  ContinuityMemo.Text:='Knowledge: '+Row.GetValue<string>('title')+sLineBreak+
    'Historical identity: '+Row.GetValue<string>('old_name')+' in '+Row.GetValue<string>('old_file')+sLineBreak+
    Row.GetValue<string>('old_signature')+sLineBreak+sLineBreak+
    'Proposed replacement: '+Row.GetValue<string>('new_name')+' in '+Row.GetValue<string>('new_file')+sLineBreak+
    Row.GetValue<string>('new_signature')+sLineBreak+sLineBreak+
    'This proposal uses declaration kind and signature shape; it is not proof of a rename. Inspect the replacement in Explain and Source. Approve only if you establish continuity. The authored content will remain pending review.';
  SelectSymbol(Row.GetValue<string>('new_key'));
end;
procedure TDPHMainForm.OpenKnownProjectClick(Sender: TObject);
var Index: Integer;
begin
  Index:=ProjectsList.ItemIndex;
  if (Index<0) or (Index>=FCatalogPaths.Count) then begin StatusLabel.Text:='Select a known project first'; Exit; end;
  if not TFile.Exists(FCatalogPaths[Index]) then begin StatusLabel.Text:='Database is missing. Use Open cache to locate its new location, or remove this entry.'; Exit; end;
  OpenSelection('',FCatalogPaths[Index]);
end;
procedure TDPHMainForm.ForgetProjectClick(Sender: TObject);
var Index: Integer;
begin
  Index:=ProjectsList.ItemIndex;
  if (FCatalog=nil) or (Index<0) or (Index>=FCatalogPaths.Count) then Exit;
  try FCatalog.Forget(FCatalogPaths[Index]); FCatalog.Save; RefreshProjectsClick(nil);
    StatusLabel.Text:='Removed from known projects. The database and source files were not deleted.';
  except on E: Exception do StatusLabel.Text:='Cannot remove catalog entry: '+E.Message; end;
end;
procedure TDPHMainForm.Submit(const ACommand: string);
var R: TDPHWorkspaceRequest;
begin
  if FBusy then Exit;
  R:=Default(TDPHWorkspaceRequest);
  if not TryStrToInt(CodePageEdit.Text,R.CodePage) or (R.CodePage<0) or (R.CodePage>65535) then begin StatusLabel.Text:='Enter code page 0 for Unicode or a Windows code page number from 1 to 65535'; Exit; end;
  R.Command:=ACommand; R.Database:=FDatabase; R.Entry:=FEntry;
  R.Configuration:=ConfigurationCombo.Items[ConfigurationCombo.ItemIndex]; R.Platform:=PlatformCombo.Items[PlatformCombo.ItemIndex];
  R.Defines:=DefinesEdit.Text.Split([';'],TStringSplitOptions.ExcludeEmpty); R.ExternalRoots:=ExternalRootsEdit.Text.Split([';'],TStringSplitOptions.ExcludeEmpty);
  if MatchText(ACommand,['knowledge','save_knowledge','review_knowledge']) then
  begin
    if FView=nil then begin StatusLabel.Text:='Open or analyze a project first'; Exit; end;
    R.KnowledgeID:=FKnowledgeID; R.ExpectedRevision:=FKnowledgeRevision; R.GenerationID:=FView.Document.GetValue<Int64>('generation_id');
    R.Title:=KnowledgeTitleEdit.Text; R.Body:=KnowledgeBodyMemo.Text; R.Editor:=KnowledgeAuthorEdit.Text;
    R.Kind:=KnowledgeKindCombo.Items[KnowledgeKindCombo.ItemIndex]; R.EntityKey:=FKnowledgeLink; R.ReviewState:=FReviewState;
  end;
  if ACommand='publish' then
  begin
    if FView=nil then begin StatusLabel.Text:='Open or analyze a project first'; Exit; end;
    R.GenerationID:=FView.Document.GetValue<Int64>('generation_id'); R.ExportDirectory:=FExportDirectory;
    R.Exclusions:=PublishExclusionsEdit.Text.Split([';'],TStringSplitOptions.ExcludeEmpty);
    if PublishScopeCombo.ItemIndex=1 then begin if FSelected='' then begin StatusLabel.Text:='Select an object for a task bundle'; Exit; end; R.Seeds:=[FSelected]; end else R.Seeds:=[];
  end;
  FWorker.Submit(R); FBusy:=True; StatusLabel.Text:='Working in background...';
  FPendingCommand:=ACommand; if ACommand='save_knowledge' then FSavedKnowledgeText:=KnowledgeTitleEdit.Text+#0+KnowledgeBodyMemo.Text;
end;
procedure TDPHMainForm.OpenProjectClick(Sender: TObject);
var SelectedDatabase: string;
begin
  if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the authored text before changing projects'; Exit; end;
  if FBusy or not OpenProjectDialog.Execute then Exit;
  SelectedDatabase:=FDatabase;
  if (FDatabase='') or ((FView<>nil) and not SameFileName(ExcludeTrailingPathDelimiter(FView.Document.GetValue<string>('root')),ExcludeTrailingPathDelimiter(ExtractFilePath(OpenProjectDialog.FileName)))) then
  begin
    DatabaseDialog.FileName:=TPath.GetFileNameWithoutExtension(OpenProjectDialog.FileName)+'.dphdb';
    if not DatabaseDialog.Execute then Exit; SelectedDatabase:=DatabaseDialog.FileName;
  end;
  OpenSelection(OpenProjectDialog.FileName,SelectedDatabase);
end;
procedure TDPHMainForm.OpenCacheClick(Sender: TObject);
begin
  if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the authored text before changing projects'; Exit; end;
  if FBusy or not OpenCacheDialog.Execute then Exit; OpenSelection('',OpenCacheDialog.FileName);
end;
procedure TDPHMainForm.OpenSelection(const AEntry,ADatabase: string);
var Request: TDPHWorkspaceRequest;
begin
  if FBusy then Exit;
  if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the authored text before changing projects'; Exit; end;
  Request:=Default(TDPHWorkspaceRequest); Request.Entry:=AEntry; Request.Database:=ADatabase;
  if not TryStrToInt(CodePageEdit.Text,Request.CodePage) or (Request.CodePage<0) or (Request.CodePage>65535) then begin StatusLabel.Text:='Enter code page 0 for Unicode or a Windows code page number from 1 to 65535'; Exit; end;
  if AEntry='' then Request.Command:='open' else Request.Command:='incremental';
  Request.Configuration:=ConfigurationCombo.Items[ConfigurationCombo.ItemIndex];
  Request.Platform:=PlatformCombo.Items[PlatformCombo.ItemIndex];
  if AEntry<>'' then begin Request.Configuration:=''; Request.Platform:=''; end;
  Request.Defines:=DefinesEdit.Text.Split([';'],TStringSplitOptions.ExcludeEmpty);
  Request.ExternalRoots:=ExternalRootsEdit.Text.Split([';'],TStringSplitOptions.ExcludeEmpty);
  FWorker.Submit(Request); FPendingEntry:=AEntry; FPendingDatabase:=ADatabase;
  FPendingCommand:=Request.Command; FBusy:=True; StatusLabel.Text:='Checking selected project; the current workspace is retained until accepted...';
end;
procedure TDPHMainForm.RelocateClick(Sender: TObject);
var Generation: Int64; Request: TDPHWorkspaceRequest;
begin
  if FBusy or (FView=nil) then Exit;
  if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the authored text before relocating'; Exit; end;
  if not OpenProjectDialog.Execute then Exit;
  Generation:=FView.Document.GetValue<Int64>('generation_id');
  Request:=Default(TDPHWorkspaceRequest); Request.CodePage:=FView.Document.GetValue<Integer>('code_page',0);
  Request.Command:='relocate'; Request.Database:=FDatabase; Request.Entry:=OpenProjectDialog.FileName; Request.GenerationID:=Generation;
  Request.Configuration:=FView.Document.GetValue<string>('configuration'); Request.Platform:=FView.Document.GetValue<string>('platform');
  Request.Defines:=DefinesEdit.Text.Split([';'],TStringSplitOptions.ExcludeEmpty); Request.ExternalRoots:=ExternalRootsEdit.Text.Split([';'],TStringSplitOptions.ExcludeEmpty);
  FPendingEntry:=Request.Entry; FPendingDatabase:=Request.Database; FBusy:=True;
  FWorker.Submit(Request); StatusLabel.Text:='Verifying relocated project hashes before reassessment...';
end;
procedure TDPHMainForm.ClearWorkspace;
begin
  FreeAndNil(FExplanations); FreeAndNil(FLearningFacts); LearningBrowser.Visible:=False; ExplainBrowser.Visible:=False; FlowBrowser.Visible:=False;
  FreeAndNil(FImages); ScreenshotList.Items.Clear; ScreenshotImage.Bitmap.Clear(TAlphaColors.Null); ScreenshotEvidence.Text:='No imported screenshot is selected.';
  FreeAndNil(FView); FreeAndNil(FGraph); FreeAndNil(FScreen); FreeAndNil(FKnowledge);
  FreeAndNil(FContinuity); ContinuityList.Items.Clear; ContinuityMemo.Text:='';
  FreeAndNil(FSearchResults); ProjectSearchList.Items.Clear; ProjectSearchMemo.Text:='';
  FSelected:=''; FScope:=''; FPage:=0; FHistory.Clear; FBookmarks.Clear;
  FExpandedKeys.Clear; FHierarchyVisible:=False;
  FreeAndNil(FDetails); DetailsList.Items.Clear; DetailsMemo.Text:='Select an object in Explorer to inspect its statements, serialized properties and evidence.';
  FExplorerKeys.Clear; FRelationKeys.Clear; FKnowledgeRows.Clear;
  ExplorerList.Items.Clear; RelationsList.Items.Clear; KnowledgeList.Items.Clear; FormCombo.Items.Clear;
  SourceMemo.Text:=''; InspectorMemo.Text:=''; OverviewMemo.Text:=''; BreadcrumbLabel.Text:='';
  NewKnowledgeClick(nil); FExportDirectory:=''; PreviewButton.Enabled:=False;
  PublishBrowser.Visible:=False; PublishMemo.Text:=''; GraphPaint.Repaint; ScreenPaint.Repaint;
end;
procedure TDPHMainForm.FullScanClick(Sender: TObject);
begin if FEntry='' then StatusLabel.Text:='Attach the source project first' else Submit('full'); end;
procedure TDPHMainForm.PollTimerTimer(Sender: TObject);
var R: TDPHWorkspaceResponse; Value: TJSONValue; Row: TJSONObject;
begin
  if FClosing and FWorker.Finished then begin FBusy:=False; Close; Exit; end;
  while FWorker.Poll(R) do
  try
    FBusy:=R.Busy;
    if not R.Busy and not R.Failed then FDetached:=R.Detached;
    if R.Document<>nil then begin
      if FPendingDatabase<>'' then begin
        ClearWorkspace; FEntry:=FPendingEntry; FDatabase:=FPendingDatabase;
        FPendingEntry:=''; FPendingDatabase:='';
      end;
      LoadView(R.Document); R.Document:=nil;
    end;
    if R.SourceEntry<>'' then FEntry:=R.SourceEntry;
    if R.Failed then begin
      FPendingEntry:=''; FPendingDatabase:='';
      if FView=nil then HelpClick(nil);
    end;
    if R.Knowledge<>nil then begin
      if (FPendingCommand='save_knowledge') and (FSavedKnowledgeText=KnowledgeTitleEdit.Text+#0+KnowledgeBodyMemo.Text) then FKnowledgeEdited:=False;
      LoadKnowledge(R.Knowledge); R.Knowledge:=nil; end;
    if R.Screenshots<>nil then begin LoadScreenshots(R.Screenshots); R.Screenshots:=nil; end;
    if (R.SearchResults<>nil) and (FView<>nil) and (R.SearchGeneration=FView.Document.GetValue<Int64>('generation_id')) then begin
      FSearchResults.Free; FSearchResults:=R.SearchResults; R.SearchResults:=nil; ProjectSearchList.Items.Clear;
      for Value in FSearchResults do begin Row:=Value as TJSONObject;
        ProjectSearchList.Items.Add(Row.GetValue<string>('kind')+' | '+Row.GetValue<string>('title')+' | '+Row.GetValue<string>('verification_state'));
      end;
      NextProjectSearchButton.Enabled:=FSearchResults.Count=50;
      ProjectSearchMemo.Text:='Results '+IntToStr(FSearchOffset+1)+' through '+IntToStr(FSearchOffset+FSearchResults.Count)+'. Select a row for its excerpt and status; Open result navigates to its object or authored record.';
      if FSearchResults.Count=0 then ProjectSearchMemo.Text:='No matching results on this page. Enter another search or click Search to start again from the first page.';
    end;
    if R.Continuity<>nil then begin
      FContinuity.Free; FContinuity:=R.Continuity; R.Continuity:=nil; ContinuityList.Items.Clear;
      for Value in FContinuity do begin Row:=Value as TJSONObject;
        ContinuityList.Items.Add(Row.GetValue<string>('title')+' | '+Row.GetValue<string>('old_name')+' -> '+Row.GetValue<string>('new_name'));
      end;
      ContinuityMemo.Text:='Select a proposal to inspect old and new declarations. Up to 500 proposals are shown; narrow the replacement name/file filter when needed.';
    end;
    if R.Lifecycle<>nil then begin
      LifecycleMemo.Lines.Clear;
      LifecycleMemo.Lines.Add('Saved policy: keep '+IntToStr(R.RetentionCount)+' recent generations. Preview below uses '+RetentionCountEdit.Text+'.');
      LifecycleMemo.Lines.Add('Generation | state | saved | cached views | retention reason | release label');
      for Value in R.Lifecycle do begin Row:=Value as TJSONObject;
        LifecycleMemo.Lines.Add(Row.GetValue<string>('generation_id')+' | '+Row.GetValue<string>('status')+' | '+
          Row.GetValue<string>('started_at')+' | '+Row.GetValue<string>('cached_views')+' | '+
          Row.GetValue<string>('retention_reason')+' | '+Row.GetValue<string>('release_label'));
      end;
    end;
    if R.RestoredDatabase<>'' then OpenSelection('',R.RestoredDatabase);
    if R.ExportDirectory<>'' then begin FExportDirectory:=R.ExportDirectory; PreviewButton.Enabled:=True;
      PublishMemo.Text:=R.MessageText+sLineBreak+FExportDirectory+sLineBreak+'Open index.html offline, or inspect canonical.json, indexes and validation. PDF conversion is available through the approved LibreOffice guide tool. Atlas is unconfigured; no external calls were made.'; end;
    StatusLabel.Text:=R.MessageText; if FView<>nil then StatusLabel.Text:=StatusLabel.Text+' | '+FView.FlagsText;
  finally R.Free; end;
end;
procedure TDPHMainForm.ChangeTimerTimer(Sender: TObject);
begin if not FBusy and not FDetached and (FEntry<>'') then Submit('check'); end;
procedure TDPHMainForm.LoadView(ADocument: TJSONObject);
var V: TJSONValue; Row: TJSONObject; Path: string; Options: TJSONArray;
begin
  FreeAndNil(FSearchResults); ProjectSearchList.Items.Clear; ProjectSearchMemo.Text:='Search the current analysis generation and authored knowledge.';
  FSearchOffset:=0; NextProjectSearchButton.Enabled:=False;
  FreeAndNil(FView); FView:=TDPHWorkspaceView.Create(ADocument); FSelected:=''; FScope:=''; FPage:=0; FHistory.Clear; FBookmarks.Clear;
  FreeAndNil(FDetails); DetailsList.Items.Clear; DetailsMemo.Text:='Select an object to inspect evidence from this generation.';
  if (FCatalog<>nil) and (FDatabase<>'') then
  try FCatalog.Remember(FDatabase); FCatalog.Save; RefreshProjectsClick(nil);
  except on E: Exception do StatusLabel.Text:='Project opened, but catalog could not be saved: '+E.Message; end;
  FBinding:=True;
  try
    if ADocument.TryGetValue<TJSONArray>('configurations',Options) then begin
      ConfigurationCombo.Items.Clear; for V in Options do ConfigurationCombo.Items.Add(V.Value);
    end;
    if ADocument.TryGetValue<TJSONArray>('platforms',Options) then begin
      PlatformCombo.Items.Clear; for V in Options do PlatformCombo.Items.Add(V.Value);
    end;
    if ConfigurationCombo.Items.IndexOf(ADocument.GetValue<string>('configuration'))<0 then ConfigurationCombo.Items.Add(ADocument.GetValue<string>('configuration'));
    if PlatformCombo.Items.IndexOf(ADocument.GetValue<string>('platform'))<0 then PlatformCombo.Items.Add(ADocument.GetValue<string>('platform'));
    ConfigurationCombo.ItemIndex:=ConfigurationCombo.Items.IndexOf(ADocument.GetValue<string>('configuration'));
    if ConfigurationCombo.ItemIndex<0 then ConfigurationCombo.ItemIndex:=0;
    PlatformCombo.ItemIndex:=PlatformCombo.Items.IndexOf(ADocument.GetValue<string>('platform'));
    if PlatformCombo.ItemIndex<0 then PlatformCombo.ItemIndex:=0;
    DefinesEdit.Text:=''; for V in ADocument.GetValue<TJSONArray>('defines') do begin if DefinesEdit.Text<>'' then DefinesEdit.Text:=DefinesEdit.Text+';'; DefinesEdit.Text:=DefinesEdit.Text+V.Value; end;
    CodePageEdit.Text:=IntToStr(ADocument.GetValue<Integer>('code_page',0));
    ExternalRootsEdit.Text:=''; for V in ADocument.GetValue<TJSONArray>('external_roots') do begin if ExternalRootsEdit.Text<>'' then ExternalRootsEdit.Text:=ExternalRootsEdit.Text+';'; ExternalRootsEdit.Text:=ExternalRootsEdit.Text+V.Value; end;
    FormCombo.Items.Clear;
    for V in ADocument.GetValue<TJSONArray>('syntax.files') do begin Row:=V as TJSONObject; Path:=Row.GetValue<string>('path');
      if MatchText(ExtractFileExt(Path),['.fmx','.dfm']) and (Row.GetValue('ir')<>nil) then FormCombo.Items.Add(Path);
    end;
    if FormCombo.Items.Count>0 then FormCombo.ItemIndex:=0;
    OverviewMemo.Text:=FView.FlagsText;
  finally FBinding:=False; end;
  RefreshExplorer; RefreshGraphics; RefreshLearning;
end;
procedure TDPHMainForm.RefreshLearning;
var ID: TGUID;
begin
  FreeAndNil(FExplanations); FreeAndNil(FLearningFacts); if FView=nil then Exit;
  FLearningFacts:=TDPHDocumentModel.Create(FView,FKnowledge,[],[],FDetached,not FView.Document.GetValue<Boolean>('analysis_complete'),nil,True);
  FExplanations:=TDPHExplanationModel.Create(FLearningFacts.Document);
  if FLearningDirectory='' then begin CreateGUID(ID);
    FLearningDirectory:=TPath.Combine(TPath.GetTempPath,'DPH-Learning-'+GUIDToString(ID));
    FExplainDirectory:=TPath.Combine(FLearningDirectory,'object');
    FFlowDirectory:=TPath.Combine(FLearningDirectory,'flow');
    TDirectory.CreateDirectory(FLearningDirectory); TDirectory.CreateDirectory(FExplainDirectory); TDirectory.CreateDirectory(FFlowDirectory);
  end;
  LearningClick(nil); ShowExplanation; RefreshGraphics;
end;
procedure TDPHMainForm.LearningClick(Sender: TObject);
begin
  if FExplanations=nil then Exit;
  OverviewMemo.Text:=FExplanations.TopicText(Max(0,LearningTopics.ItemIndex));
  TFile.WriteAllBytes(TPath.Combine(FLearningDirectory,'index.html'),TEncoding.UTF8.GetBytes(FExplanations.TopicHTML(Max(0,LearningTopics.ItemIndex))));
  try LearningBrowser.WindowsEngine:=TWindowsEngine.EdgeOnly; LearningBrowser.Visible:=True;
    LearningBrowser.Navigate('file://'+TPath.Combine(FLearningDirectory,'index.html'));
  except on E: Exception do begin LearningBrowser.Visible:=False; StatusLabel.Text:='Learning preview unavailable; text fallback is shown: '+E.Message; end; end;
end;
procedure TDPHMainForm.ShowExplanation;
begin
  if FExplanations=nil then Exit;
  ExplainFallback.Text:=FExplanations.ObjectText(FSelected);
  TFile.WriteAllBytes(TPath.Combine(FExplainDirectory,'index.html'),TEncoding.UTF8.GetBytes(FExplanations.ObjectHTML(FSelected)));
  try ExplainBrowser.WindowsEngine:=TWindowsEngine.EdgeOnly; ExplainBrowser.Visible:=True;
    ExplainBrowser.Navigate('file://'+TPath.Combine(FExplainDirectory,'index.html'));
  except on E: Exception do begin ExplainBrowser.Visible:=False; StatusLabel.Text:='Object preview unavailable; text fallback is shown: '+E.Message; end; end;
end;
procedure TDPHMainForm.LearningShouldLoad(Sender: TObject; const AURL: string; var ACancel: Boolean);
var Directory,Fragment: string; P: Integer; V: TJSONValue; S: TJSONObject;
begin
  Directory:=FLearningDirectory; if Sender=ExplainBrowser then Directory:=FExplainDirectory;
  if Sender=FlowBrowser then Directory:=FFlowDirectory;
  if Sender=HelpBrowser then Directory:=TPath.Combine(FBaseDirectory,'help');
  ACancel:=not TDPHBrowserPolicy.Allowed(AURL,Directory); if ACancel then Exit;
  P:=Pos('#s_',AURL); if (P=0) or (FView=nil) then Exit; ACancel:=True; Fragment:=Copy(AURL,P+3,MaxInt);
  for V in FView.Document.GetValue<TJSONArray>('semantics.symbols') do begin S:=V as TJSONObject;
    if SameText(THashSHA2.GetHashString(S.GetValue<string>('key')),Fragment) then begin SelectSymbol(S.GetValue<string>('key')); WorkspaceTabs.ActiveTab:=ExplainTab; Break; end;
  end;
end;
procedure TDPHMainForm.HelpClick(Sender: TObject);
begin
  WorkspaceTabs.ActiveTab:=HelpTab;
  if not TFile.Exists(TPath.Combine(FBaseDirectory,'help\index.html')) then begin StatusLabel.Text:='Getting started HTML is missing; use the displayed quick-start directions'; Exit; end;
  try HelpBrowser.WindowsEngine:=TWindowsEngine.EdgeOnly; HelpBrowser.Visible:=True;
    HelpBrowser.Navigate('file://'+TPath.Combine(FBaseDirectory,'help\index.html'));
  except on E: Exception do begin HelpBrowser.Visible:=False; StatusLabel.Text:='Getting started preview unavailable: '+E.Message; end; end;
end;
procedure TDPHMainForm.ImportScreenshotClick(Sender: TObject);
var Request: TDPHWorkspaceRequest;
begin
  if FBusy or (FView=nil) then Exit;
  if (Trim(ScreenshotAuthor.Text)='') or (Trim(ScreenshotCaption.Text)='') then begin StatusLabel.Text:='Enter contributor and capture/environment description before importing a PNG'; Exit; end;
  if not ScreenshotDialog.Execute then Exit;
  Request.Command:='import_screenshot'; Request.Database:=FDatabase; Request.Entry:=FEntry;
  Request.GenerationID:=FView.Document.GetValue<Int64>('generation_id'); Request.Body:=ScreenshotDialog.FileName;
  Request.Editor:=ScreenshotAuthor.Text; Request.Title:=ScreenshotCaption.Text; Request.EntityKey:=FSelected;
  FWorker.Submit(Request); FBusy:=True; StatusLabel.Text:='Importing the explicitly selected screenshot; no application will be executed...';
end;
procedure TDPHMainForm.LoadScreenshots(ARows: TJSONArray);
var V: TJSONValue; R: TJSONObject;
begin
  FImages.Free; FImages:=ARows; ScreenshotList.Items.Clear;
  for V in ARows do begin R:=V as TJSONObject; ScreenshotList.Items.Add(R.GetValue<string>('caption')+' | generation '+R.GetValue('generation_id').Value); end;
  ScreenshotEvidence.Text:='Imported images are contributor evidence, separate from the design-time reconstruction. Capture time and runtime origin require review.';
  ScreenshotImage.Bitmap.Clear(TAlphaColors.Null);
end;
procedure TDPHMainForm.ScreenshotClick(Sender: TObject);
var R: TJSONObject; Path: string;
begin
  if (FImages=nil) or (ScreenshotList.ItemIndex<0) then Exit;
  R:=FImages.Items[ScreenshotList.ItemIndex] as TJSONObject; Path:=R.GetValue<string>('managed_path');
  try
    if THashSHA2.GetHashStringFromFile(Path)<>R.GetValue<string>('image_sha256') then raise EReadError.Create('Screenshot changed after validation');
    ScreenshotImage.Bitmap.LoadFromFile(Path);
    ScreenshotEvidence.Text:=R.GetValue<string>('caption')+sLineBreak+'Contributor: '+R.GetValue<string>('author')+sLineBreak+
      'Imported: '+R.GetValue<string>('imported_utc')+' | generation '+R.GetValue('generation_id').Value+sLineBreak+
      R.GetValue<string>('provenance')+sLineBreak+'Status: '+R.GetValue<string>('verification_state')+sLineBreak+'SHA256 '+R.GetValue<string>('image_sha256');
  except on E: Exception do begin ScreenshotImage.Bitmap.Clear(TAlphaColors.Null); ScreenshotEvidence.Text:='Image unavailable: '+E.Message; end; end;
end;
procedure TDPHMainForm.RefreshExplorer;
var Rows: TJSONArray; V: TJSONValue; S: TJSONObject; Kind,LabelText,Prefix: string; Depth: Integer;
begin
  if FView=nil then Exit; Kind:=''; if KindCombo.ItemIndex>0 then Kind:=KindCombo.Items[KindCombo.ItemIndex];
  FHierarchyVisible:=(Trim(SearchEdit.Text)='') and (Kind='') and (FScope='');
  ExplorerExpandButton.Enabled:=FHierarchyVisible;
  if FHierarchyVisible then Rows:=FView.Hierarchy(FExpandedKeys.ToArray,FPage,250)
  else Rows:=FView.Search(SearchEdit.Text,Kind,FScope,FPage,250);
  try
    ExplorerList.Items.BeginUpdate;
    try ExplorerList.Items.Clear; FExplorerKeys.Clear;
      for V in Rows do begin S:=V as TJSONObject; LabelText:=S.GetValue<string>('name'); Prefix:='';
        if FHierarchyVisible then begin
          Depth:=S.GetValue<Integer>('depth'); Prefix:=StringOfChar(' ',Min(Depth,20)*2);
          if S.GetValue<Boolean>('has_children') then begin if S.GetValue<Boolean>('expanded') then Prefix:=Prefix+'[-] ' else Prefix:=Prefix+'[+] '; end
          else Prefix:=Prefix+'    ';
          if Depth>0 then LabelText:=Copy(LabelText,LastDelimiter('.',LabelText)+1,MaxInt);
        end;
        ExplorerList.Items.Add(Prefix+S.GetValue<string>('kind')+'  '+LabelText); FExplorerKeys.Add(S.GetValue<string>('key'));
      end;
    finally ExplorerList.Items.EndUpdate; end;
    BreadcrumbLabel.Text:='Project / '+FScope+' | page '+IntToStr(FPage div 250+1)+' | '+IntToStr(Rows.Count)+' objects';
  finally Rows.Free; end;
end;
procedure TDPHMainForm.SearchChange(Sender: TObject);
begin if FBinding then Exit; FScope:=''; FPage:=0; RefreshExplorer; end;
procedure TDPHMainForm.ExplorerClick(Sender: TObject);
begin if (ExplorerList.ItemIndex>=0) and (ExplorerList.ItemIndex<FExplorerKeys.Count) then begin SelectSymbol(FExplorerKeys[ExplorerList.ItemIndex]); WorkspaceTabs.ActiveTab:=ExplainTab; end; end;
procedure TDPHMainForm.ExplorerExpandClick(Sender: TObject);
var Key: string; Index: Integer;
begin
  if not FHierarchyVisible or (ExplorerList.ItemIndex<0) or (ExplorerList.ItemIndex>=FExplorerKeys.Count) then Exit;
  Key:=FExplorerKeys[ExplorerList.ItemIndex];
  if FExpandedKeys.Contains(Key) then FExpandedKeys.Remove(Key) else FExpandedKeys.Add(Key);
  FPage:=0; RefreshExplorer; Index:=FExplorerKeys.IndexOf(Key); if Index>=0 then ExplorerList.ItemIndex:=Index;
end;
procedure TDPHMainForm.DetailsClick(Sender: TObject);
var Row,Range: TJSONObject;
begin
  if (FDetails=nil) or (DetailsList.ItemIndex<0) or (DetailsList.ItemIndex>=FDetails.Count) then Exit;
  Row:=FDetails.Items[DetailsList.ItemIndex] as TJSONObject; Range:=Row.GetValue<TJSONObject>('range');
  DetailsMemo.Text:=Row.GetValue<string>('detail_kind')+': '+Row.GetValue<string>('title')+sLineBreak+sLineBreak+
    Row.GetValue<string>('text')+sLineBreak+sLineBreak+'Certainty: '+Row.GetValue<string>('resolution')+sLineBreak+
    'Rule: '+Row.GetValue<string>('rule')+sLineBreak+'Source: '+Range.GetValue<string>('source')+':'+Range.GetValue<Integer>('line').ToString+
    sLineBreak+'Byte range: '+Range.GetValue('start').Value+' through '+Range.GetValue('end').Value+
    sLineBreak+'SHA256: '+Row.GetValue<string>('source_hash','unavailable')+sLineBreak+
    'Generation: '+FView.Document.GetValue('generation_id').Value+sLineBreak+sLineBreak+
    'This is captured static evidence. Open matching source verifies the file hash before applying this range. Detached mode retains the evidence above.';
end;

procedure TDPHMainForm.DetailsSourceClick(Sender: TObject);
var Row,Range,FileRow: TJSONObject; Path: string; Source: TDPHSource; Diagnostics: TDPHDiagnostics;
begin
  if (FDetails=nil) or (DetailsList.ItemIndex<0) or (DetailsList.ItemIndex>=FDetails.Count) then Exit;
  DetailsClick(nil);
  if FDetached or (FEntry='') then begin DetailsMemo.Lines.Add('Original source is detached. The cached statement/value and source evidence remain available here.'); Exit; end;
  Row:=FDetails.Items[DetailsList.ItemIndex] as TJSONObject; Range:=Row.GetValue<TJSONObject>('range');
  FileRow:=FView.SourceFile(Range.GetValue<string>('source')); if FileRow=nil then Exit;
  Path:=TPath.GetFullPath(TPath.Combine(ExtractFilePath(FEntry),Range.GetValue<string>('source')));
  if not StartsText(IncludeTrailingPathDelimiter(ExtractFilePath(FEntry)),Path) then begin DetailsMemo.Lines.Add('Source location is outside the attached project.'); Exit; end;
  Diagnostics:=TDPHDiagnostics.Create;
  try
    try Source:=TDPHSource.Create(Path,Range.GetValue<string>('source'),Diagnostics,FView.Document.GetValue<Integer>('code_page',0));
      try
        if not Source.Decoded or not SameText(Source.SHA256,Row.GetValue<string>('source_hash','')) then begin DetailsMemo.Lines.Add('Source is changed or undecodable; the cached range was not applied.'); Exit; end;
        SourceMemo.Text:=Source.Text; SourceMemo.CaretPosition:=TCaretPosition.Create(Max(0,Range.GetValue<Integer>('line')-1),Max(0,Range.GetValue<Integer>('column')-1));
        WorkspaceTabs.ActiveTab:=SourceTab;
      finally Source.Free; end;
    except on E: Exception do DetailsMemo.Lines.Add('Source unavailable: '+E.Message); end;
  finally Diagnostics.Free; end;
end;

procedure TDPHMainForm.SelectSymbol(const AKey: string; AHistory: Boolean);
var S,Range,Row: TJSONObject; Rows,Props: TJSONArray; V: TJSONValue; Path,Direction,Target: string; Source: TDPHSource; Diagnostics: TDPHDiagnostics;
begin
  if FView=nil then Exit; S:=FView.Symbol(AKey); if S=nil then Exit;
  FWholeGraph:=False;
  if AHistory and (FSelected<>'') and (FSelected<>AKey) then FHistory.Add(FSelected); FSelected:=AKey;
  InspectorMemo.Text:=S.GetValue<string>('name')+sLineBreak+sLineBreak+'Kind: '+S.GetValue<string>('kind')+sLineBreak+
    'Signature: '+S.GetValue<string>('signature')+sLineBreak+'Declared type: '+S.GetValue<string>('type')+sLineBreak+sLineBreak+
    'Source: '+S.GetValue<string>('range.source')+':'+S.GetValue<Integer>('range.line').ToString+sLineBreak+
    'Generation: '+FView.Document.GetValue('generation_id').Value+sLineBreak+sLineBreak+
    'Read Explain for the role, callers, effects and execution trace. Open Source to inspect the attached code. References contains the direct forward and reverse links.'+sLineBreak+sLineBreak+
    'Evidence SHA256:'+sLineBreak+S.GetValue<string>('source_hash');
  RelationsList.Items.Clear; FRelationKeys.Clear;
  FreeAndNil(FDetails); FDetails:=FView.Details(AKey); DetailsList.Items.Clear;
  for V in FDetails do begin Row:=V as TJSONObject;
    DetailsList.Items.Add(Row.GetValue<string>('detail_kind')+' | '+Row.GetValue<string>('title')+' | line '+Row.GetValue<Integer>('range.line').ToString);
  end;
  DetailsMemo.Text:='Select a row to read its statement, serialized value or relationship and source evidence. Maximum 1,000 rows. Serialized properties are overrides; absent framework defaults are not inferred.';
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
        try Source:=TDPHSource.Create(Path,Range.GetValue<string>('source'),Diagnostics,FView.Document.GetValue<Integer>('code_page',0));
          try if Source.Decoded and SameText(Source.SHA256,Row.GetValue<string>('sha256')) then begin SourceMemo.Text:=Source.Text;
            SourceMemo.CaretPosition:=TCaretPosition.Create(Max(0,Range.GetValue<Integer>('line')-1),Max(0,Range.GetValue<Integer>('column')-1)); end
            else SourceMemo.Text:='STALE or undecodable source - cached range not applied.'; finally Source.Free; end;
        except on E: Exception do SourceMemo.Text:='Source unavailable: '+E.Message; end;
      finally Diagnostics.Free; end;
    end;
  end;
  if not FHierarchyVisible and MatchText(S.GetValue<string>('kind'),['unit','type','component','routine','anonymous']) then begin FScope:=S.GetValue<string>('name'); FPage:=0; RefreshExplorer; end;
  RefreshGraphics; ShowExplanation;
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
  FHierarchyVisible:=False; ExplorerExpandButton.Enabled:=False;
  ExplorerList.Items.Clear; FExplorerKeys.Clear; if FView=nil then Exit;
  for Key in FBookmarks do begin S:=FView.Symbol(Key); if S<>nil then begin ExplorerList.Items.Add(S.GetValue<string>('name')); FExplorerKeys.Add(Key); end; end;
  BreadcrumbLabel.Text:='Bookmarks for this captured generation';
end;
procedure TDPHMainForm.ViewChange(Sender: TObject);
begin if Sender=GraphCombo then FWholeGraph:=False; if not FBinding then RefreshGraphics; end;
procedure TDPHMainForm.WholeProgramGraphClick(Sender: TObject);
begin
  if FView=nil then Exit;
  GraphCombo.ItemIndex:=0; FWholeGraph:=True; RefreshGraphics;
  WorkspaceTabs.ActiveTab:=GraphTab;
  StatusLabel.Text:='Whole-program static startup graph; phase links show qualified reachability, not a runtime trace.';
end;
procedure TDPHMainForm.AllFormsGraphClick(Sender: TObject);
begin
  if FView=nil then Exit;
  GraphCombo.ItemIndex:=GraphCombo.Items.IndexOf('Form navigation'); FWholeGraph:=True; RefreshGraphics;
  WorkspaceTabs.ActiveTab:=GraphTab;
  StatusLabel.Text:='Form navigation from captured forms and declared instances. Show/Hide/Close actions are static possibilities; runtime screens and order are unobserved.';
end;
procedure TDPHMainForm.RefreshGraphics;
begin
  FreeAndNil(FGraph); FreeAndNil(FScreen); if FView=nil then Exit;
  FlowBrowser.Visible:=False;
  if (GraphCombo.ItemIndex=1) and (FExplanations<>nil) then begin
    TFile.WriteAllBytes(TPath.Combine(FFlowDirectory,'index.html'),TEncoding.UTF8.GetBytes(FExplanations.FlowHTML(FSelected)));
    try FlowBrowser.WindowsEngine:=TWindowsEngine.EdgeOnly; FlowBrowser.Visible:=True;
      FlowBrowser.Navigate('file://'+TPath.Combine(FFlowDirectory,'index.html'));
    except on E: Exception do begin FlowBrowser.Visible:=False; StatusLabel.Text:='HTML flow view unavailable; native graph retained: '+E.Message; end; end;
  end;
  if FWholeGraph and MatchText(GraphCombo.Items[GraphCombo.ItemIndex],['Execution','Form navigation']) then FGraph:=FView.Graph(GraphCombo.Items[GraphCombo.ItemIndex],'')
  else if GraphCombo.ItemIndex>=0 then FGraph:=FView.Graph(GraphCombo.Items[GraphCombo.ItemIndex],FSelected);
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
procedure TDPHMainForm.LoadKnowledge(ARows: TJSONArray);
begin FKnowledge.Free; FKnowledge:=ARows; if not FKnowledgeEdited then NewKnowledgeClick(nil); KnowledgeFilterChange(nil); RefreshLearning; end;
procedure TDPHMainForm.KnowledgeEdited(Sender: TObject);
begin if not FBinding then begin if not FKnowledgeEdited and (FKnowledgeID=0) then FKnowledgeLink:=FSelected; FKnowledgeEdited:=True; end; end;
procedure TDPHMainForm.DiscardKnowledgeClick(Sender: TObject);
begin FKnowledgeEdited:=False; NewKnowledgeClick(nil); end;
procedure TDPHMainForm.KnowledgeFilterChange(Sender: TObject);
var V: TJSONValue; Row: TJSONObject;
begin
  KnowledgeList.Items.Clear; FKnowledgeRows.Clear; if FKnowledge=nil then Exit;
  for V in FKnowledge do begin Row:=V as TJSONObject;
    if PendingKnowledgeCheck.IsChecked and (Row.GetValue<string>('pending')<>'1') and (Row.GetValue<string>('state')<>'needs_review') then Continue;
    KnowledgeList.Items.Add('['+Row.GetValue<string>('state')+'] '+Row.GetValue<string>('kind')+' / '+Row.GetValue<string>('title')); FKnowledgeRows.Add(Row);
  end;
end;
procedure TDPHMainForm.KnowledgeClick(Sender: TObject);
var Row: TJSONObject;
begin
  if FKnowledgeEdited then begin StatusLabel.Text:='Save the current authored text before selecting another record'; Exit; end;
  if (KnowledgeList.ItemIndex<0) or (KnowledgeList.ItemIndex>=FKnowledgeRows.Count) then Exit; Row:=FKnowledgeRows[KnowledgeList.ItemIndex];
  FBinding:=True;
  try
  FKnowledgeID:=StrToInt64(Row.GetValue<string>('id')); FKnowledgeRevision:=StrToInt64(Row.GetValue<string>('revision'));
  KnowledgeTitleEdit.Text:=Row.GetValue<string>('title'); KnowledgeKindCombo.ItemIndex:=KnowledgeKindCombo.Items.IndexOf(Row.GetValue<string>('kind'));
  if KnowledgeKindCombo.ItemIndex<0 then KnowledgeKindCombo.ItemIndex:=0;
  KnowledgeBodyMemo.Text:=Row.GetValue<string>('body');
  KnowledgeHistoryMemo.Text:='Author: '+Row.GetValue<string>('owner')+' | current state: '+Row.GetValue<string>('state')+sLineBreak+
    'Links: '+Row.GetValue<TJSONArray>('links').Format(2)+sLineBreak+'Immutable revision history: '+Row.GetValue<TJSONArray>('history').Format(2);
  finally FBinding:=False; end;
end;
procedure TDPHMainForm.NewKnowledgeClick(Sender: TObject);
begin
  if (Sender<>nil) and FKnowledgeEdited then begin StatusLabel.Text:='Save the current authored text before starting another record'; Exit; end;
  FBinding:=True; try FKnowledgeID:=0; FKnowledgeRevision:=0; KnowledgeTitleEdit.Text:=''; KnowledgeBodyMemo.Text:='';
    KnowledgeHistoryMemo.Text:='New content links to the selected canonical object, or the project when no object is selected. Titles and kinds remain stable after creation.';
    FKnowledgeEdited:=False; FKnowledgeLink:=FSelected; finally FBinding:=False; end;
end;
procedure TDPHMainForm.SaveKnowledgeClick(Sender: TObject);
begin Submit('save_knowledge'); end;
procedure TDPHMainForm.RefreshKnowledgeClick(Sender: TObject);
begin Submit('knowledge'); end;
procedure TDPHMainForm.ReviewKnowledgeClick(Sender: TObject);
begin
  if FKnowledgeEdited then begin StatusLabel.Text:='Save the authored edit before reviewing its revision'; Exit; end;
  if FKnowledgeID=0 then begin StatusLabel.Text:='Select a saved knowledge revision first'; Exit; end;
  FReviewState:='verified'; if Sender=RejectKnowledgeButton then FReviewState:='rejected'; if Sender=RetireKnowledgeButton then FReviewState:='retired'; Submit('review_knowledge');
end;
procedure TDPHMainForm.PublishClick(Sender: TObject);
begin
  if FBusy or (FView=nil) then Exit;
  if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the authored edit before publishing'; Exit; end;
  if not ExportDialog.Execute then Exit; FExportDirectory:=ExportDialog.FileName; Submit('publish');
end;
procedure TDPHMainForm.PreviewClick(Sender: TObject);
begin
  if FExportDirectory='' then Exit;
  try PublishBrowser.WindowsEngine:=TWindowsEngine.EdgeOnly; PublishBrowser.Visible:=True; PublishBrowser.Navigate('file://'+TPath.Combine(FExportDirectory,'index.html'));
  except on E: Exception do begin PublishBrowser.Visible:=False; PublishMemo.Text:='Embedded preview unavailable: '+E.Message+sLineBreak+'The offline index.html remains available in '+FExportDirectory; end; end;
end;
procedure TDPHMainForm.BrowserShouldLoad(Sender: TObject; const AURL: string; var ACancel: Boolean);
begin ACancel:=not TDPHBrowserPolicy.Allowed(AURL,FExportDirectory,True); end;
initialization
  SetWebView2Path(TPath.Combine(ExtractFilePath(ParamStr(0)),'WebView2Loader.dll'));
end.
