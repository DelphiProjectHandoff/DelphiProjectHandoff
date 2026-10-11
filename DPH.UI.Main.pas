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
    HeaderLayout,CommandLayout,ExplorerLayout,InspectorLayout,FilterLayout: TLayout;
    ScreenToolbar: THorzScrollBox;
    GraphToolbar: THorzScrollBox;
    ExplorerSplitter,InspectorSplitter: TSplitter;
    OpenProjectButton,OpenCacheButton,FullScanButton,BackButton,BookmarkButton,BookmarksButton,NextPageButton,ParentButton,FullscreenButton: TButton;
    SearchEdit,DefinesEdit,ExternalRootsEdit,CodePageEdit: TEdit;
    CodePageLabel: TLabel;
    WholeProgramGraphButton,AllFormsGraphButton,AllDataGraphButton,ExplorerExpandButton: TButton;
    ConfigurationCombo,PlatformCombo,KindCombo,GraphCombo,ScreenModeCombo,FormCombo: TComboBox;
    GraphGroupingCombo: TComboBox;
    ScreenZoom: TTrackBar;
    ScreenZoomLabel: TLabel;
    ExplorerList,RelationsList: TListBox;
    DetailsList: TListBox;
    DetailsMemo: TMemo;
    DetailsTitle: TLabel;
    DetailsSourceButton,DetailsObjectButton: TButton;
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
    KnowledgeDocumentCombo,KnowledgeAudienceCombo: TComboBox;
    KnowledgeSectionLabel: TLabel;
    KnowledgeLinksTab: TTabItem;
    KnowledgeLinksToolbar: TLayout;
    KnowledgeLinksPurpose: TLabel;
    LinkKindCombo,LinkRoleCombo: TComboBox;
    LinkFilterEdit: TEdit;
    RefreshLinkTargetsButton,AddKnowledgeLinkButton,RemoveKnowledgeLinkButton: TButton;
    OpenKnowledgeLinkButton: TButton;
    LinkTargetsList,KnowledgeLinksList: TListBox;
    KnowledgeBodyMemo,KnowledgeHistoryMemo: TMemo;
    NewKnowledgeButton,SaveKnowledgeButton,RefreshKnowledgeButton,VerifyKnowledgeButton,RejectKnowledgeButton,RetireKnowledgeButton,DiscardKnowledgeButton: TButton;
    PendingKnowledgeCheck: TCheckBox;
    KnowledgeWarning: TLabel;
    PublishTab: TTabItem;
    PublishToolbar: THorzScrollBox;
    PublishScopeCombo: TComboBox;
    PublishAudienceCombo: TComboBox;
    PublishAgentInstructions: TCheckBox;
    ValidationTab: TTabItem;
    ValidationPurpose,ValidationFingerprintLabel: TLabel;
    ValidationToolbar: THorzScrollBox;
    ValidationFingerprintEdit: TEdit;
    ValidationSelectButton,ValidationUseCaptureButton: TButton;
    ValidationAllowStale: TCheckBox;
    ValidationMemo: TMemo;
    ValidationDialog: TOpenDialog;
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
    ScreenshotScroll: TScrollBox;
    ScreenshotModeCombo: TComboBox;
    ScreenshotZoom: TTrackBar;
    ScreenshotInspectButton: TButton;
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
    CoverageTab: TTabItem;
    CoverageMemo: TMemo;
    CoverageList: TListBox;
    CoveragePurpose: TLabel;
    CoverageInspectButton: TButton;
    ReviewTasksTab: TTabItem;
    ReviewTasksPurpose: TLabel;
    ReviewTasksToolbar: THorzScrollBox;
    ReviewTasksList: TListBox;
    ReviewBeforeMemo,ReviewAfterMemo: TMemo;
    ReviewReviewerEdit: TEdit;
    ReviewAffectedCombo: TComboBox;
    RefreshReviewTasksButton,OpenReviewKnowledgeButton,ReviewImpactButton,VerifyTaskButton,RetireTaskButton: TButton;
    ReviewComparison: TLayout;
    ReviewSplitter: TSplitter;
    QuestionsTab: TTabItem;
    QuestionsPurpose: TLabel;
    QuestionsToolbar: TLayout;
    QuestionsList: TListBox;
    QuestionMemo: TMemo;
    RefreshQuestionsButton,QuestionEvidenceButton,AnswerQuestionButton: TButton;
    ObservationsTab: TTabItem;
    ObservationsPurpose: TLabel;
    ObservationContributorLabel,ObservationContextLabel: TLabel;
    ObservationsToolbar: THorzScrollBox;
    ObservationContributor,ObservationContext: TEdit;
    ImportObservationButton,RefreshObservationsButton,ObservationObjectButton: TButton;
    ObservationsList: TListBox;
    ObservationMemo: TMemo;
    ObservationDialog: TOpenDialog;
    TranslationTab: TTabItem;
    TranslationPurpose,TranslationStatus: TLabel;
    TranslationToolbar: THorzScrollBox;
    TranslationSourceLocale,TranslationTargetLocale,TranslationReviewer: TEdit;
    TranslationPackButton,TranslationRefreshButton,TranslationReviewButton,TranslationTermsButton,TranslationTermsResetButton: TButton;
    TranslationList: TListBox;
    TranslationMemo: TMemo;
    TranslationDialog,TerminologyDialog: TOpenDialog;
    procedure TranslationClick(Sender: TObject);
    procedure TranslationSelectionClick(Sender: TObject);
    procedure ValidateBundleClick(Sender: TObject);
    procedure QuestionsClick(Sender: TObject);
    procedure QuestionSelectionClick(Sender: TObject);
    procedure ObservationsClick(Sender: TObject);
    procedure ObservationSelectionClick(Sender: TObject);
    procedure ReviewTasksClick(Sender: TObject);
    procedure ReviewTaskSelectionClick(Sender: TObject);
    procedure KnowledgeLinksClick(Sender: TObject);
    procedure OpenKnowledgeLinkClick(Sender: TObject);
    procedure CoverageInspectClick(Sender: TObject);
    procedure WorkspacePageChange(Sender: TObject);
    procedure WholeProgramGraphClick(Sender: TObject);
    procedure AllFormsGraphClick(Sender: TObject);
    procedure AllDataGraphClick(Sender: TObject);
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
    procedure ScreenshotViewChange(Sender: TObject);
    procedure ScreenshotInspectClick(Sender: TObject);
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
    procedure DetailsObjectClick(Sender: TObject);
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
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure FormResize(Sender: TObject);
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
    FScreenFullscreen: Boolean;
    FSavedBorder: TFmxFormBorderStyle;
    FSavedWindowState: TWindowState;
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
    FPreviewPages: TList<string>;
    FCoverage: TJSONObject;
    FLinkTargets,FEditableLinks: TJSONArray;
    FReviewTasks: TJSONArray;
    FQuestions: TJSONArray;
    FObservations: TJSONArray;
    FTranslations: TJSONArray;
    FTerminologyJSON: string;
    FKnowledgeQuestionJSON: string;
    procedure RefreshQuestions;
    procedure RefreshKnowledgeLinks;
    procedure RefreshCoverage;
    procedure RefreshLearning;
    procedure ShowExplanation;
    procedure Submit(const ACommand: string);
    procedure RefreshExplorer;
    procedure SelectSymbol(const AKey: string; AHistory: Boolean = True);
    procedure RefreshGraphics;
    procedure UpdateScreenBounds;
    procedure UpdateScreenshotBounds;
    procedure GraphGroupDetails(const AGroup: string);
    procedure ClearWorkspace;
    function GraphRect(AIndex: Integer): TRectF;
  public
    procedure OpenSelection(const AEntry,ADatabase: string);
    procedure LoadView(ADocument: TJSONObject);
    procedure LoadKnowledge(ARows: TJSONArray);
    procedure LoadScreenshots(ARows: TJSONArray);
    procedure LoadReviewTasks(ARows: TJSONArray);
    procedure LoadTranslations(ARows: TJSONArray);
    property WorkspaceView: TDPHWorkspaceView read FView;
  end;
var DPHMainForm: TDPHMainForm;
implementation
uses System.IOUtils, System.StrUtils, System.Math, System.Hash,
  Winapi.EdgeUtils, DPH.Workspace.Screen, DPH.Workspace.Graphs, DPH.Project.Source, DPH.Parse.Model, DPH.Publish.BrowserPolicy;
{$R *.fmx}
procedure TDPHMainForm.FormCreate(Sender: TObject);
var I: Integer; DatabaseDirectory: string;
begin
  FExplorerKeys:=TList<string>.Create; FRelationKeys:=TList<string>.Create; FExpandedKeys:=TList<string>.Create;
  FPreviewPages:=TList<string>.Create;
  FEditableLinks:=TJSONArray.Create;
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
  FSearchResults.Free; FCoverage.Free; FLinkTargets.Free; FEditableLinks.Free; FReviewTasks.Free; FQuestions.Free; FObservations.Free; FTranslations.Free;
  FImages.Free; FExplanations.Free; FLearningFacts.Free;
  FView.Free; FGraph.Free; FScreen.Free; FExplorerKeys.Free; FRelationKeys.Free; FHistory.Free; FBookmarks.Free; FExpandedKeys.Free; FDetails.Free;
  FKnowledge.Free; FKnowledgeRows.Free;
  for Directory in FPreviewPages do try if TFile.Exists(Directory) then TFile.Delete(Directory); except end;
  FPreviewPages.Free;
  // Remove only this form's generated preview files, never a recursive tree.
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
    if KnowledgeDocumentCombo.ItemIndex>0 then R.DocumentKind:=KnowledgeDocumentCombo.Items[KnowledgeDocumentCombo.ItemIndex];
    if KnowledgeAudienceCombo.ItemIndex>0 then R.Audience:=KnowledgeAudienceCombo.Items[KnowledgeAudienceCombo.ItemIndex];
    R.LinksJSON:=FEditableLinks.ToJSON;
    R.QuestionJSON:=FKnowledgeQuestionJSON;
  end;
  if ACommand='publish' then
  begin
    if FView=nil then begin StatusLabel.Text:='Open or analyze a project first'; Exit; end;
    R.GenerationID:=FView.Document.GetValue<Int64>('generation_id'); R.ExportDirectory:=FExportDirectory;
    R.Exclusions:=PublishExclusionsEdit.Text.Split([';'],TStringSplitOptions.ExcludeEmpty);
    R.Audience:='all'; if PublishAudienceCombo.ItemIndex>=0 then R.Audience:=PublishAudienceCombo.Items[PublishAudienceCombo.ItemIndex];
    R.IncludeAgentInstructions:=PublishAgentInstructions.IsChecked;
    if PublishScopeCombo.ItemIndex=1 then begin if FSelected='' then begin StatusLabel.Text:='Select an object for a task bundle'; Exit; end; R.Seeds:=[FSelected]; end else R.Seeds:=[];
  end;
  FWorker.Submit(R); FBusy:=True; StatusLabel.Text:='Working in background...';
  FPendingCommand:=ACommand; if ACommand='save_knowledge' then FSavedKnowledgeText:=KnowledgeTitleEdit.Text+#0+KnowledgeBodyMemo.Text+#0+IntToStr(KnowledgeDocumentCombo.ItemIndex)+#0+IntToStr(KnowledgeAudienceCombo.ItemIndex)+#0+FEditableLinks.ToJSON+#0+FKnowledgeQuestionJSON;
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
  FreeAndNil(FCoverage); CoverageList.Items.Clear; CoverageMemo.Text:='Open a captured project to see coverage and gaps.';
  FreeAndNil(FContinuity); ContinuityList.Items.Clear; ContinuityMemo.Text:='';
  FreeAndNil(FReviewTasks); ReviewTasksList.Items.Clear; ReviewBeforeMemo.Text:=''; ReviewAfterMemo.Text:='';
  FreeAndNil(FQuestions); QuestionsList.Items.Clear; QuestionMemo.Text:=''; FKnowledgeQuestionJSON:='';
  FreeAndNil(FObservations); ObservationsList.Items.Clear; ObservationMemo.Text:='Open Runtime observations and click Refresh saved records.';
  FreeAndNil(FTranslations); TranslationList.Items.Clear; TranslationMemo.Text:=''; FTerminologyJSON:='';
  TranslationStatus.Text:='Select a saved Knowledge revision, then refresh or translate it here.';
  FreeAndNil(FLinkTargets); LinkTargetsList.Items.Clear;
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
    if R.ValidationReport<>'' then ValidationMemo.Text:=R.ValidationReport;
    if R.Failed and (FPendingCommand='validate_bundle') then ValidationMemo.Text:='FAILED: '+R.MessageText+sLineBreak+'The bundle has not passed validation. Correct the reported mismatch before using it.';
    if R.Failed then begin
      FPendingEntry:=''; FPendingDatabase:='';
      if FView=nil then HelpClick(nil);
    end;
    if R.Knowledge<>nil then begin
      if (FPendingCommand='save_knowledge') and (FSavedKnowledgeText=KnowledgeTitleEdit.Text+#0+KnowledgeBodyMemo.Text+#0+IntToStr(KnowledgeDocumentCombo.ItemIndex)+#0+IntToStr(KnowledgeAudienceCombo.ItemIndex)+#0+FEditableLinks.ToJSON+#0+FKnowledgeQuestionJSON) then FKnowledgeEdited:=False;
      LoadKnowledge(R.Knowledge); R.Knowledge:=nil; end;
    if (R.ReviewTasks<>nil) and (FView<>nil) and (R.SearchGeneration=FView.Document.GetValue<Int64>('generation_id')) then begin LoadReviewTasks(R.ReviewTasks); R.ReviewTasks:=nil; end;
    if not R.Busy and not R.Failed and (FPendingCommand='review_knowledge') and (FReviewTasks<>nil) then ReviewTasksClick(RefreshReviewTasksButton);
    if R.Screenshots<>nil then begin LoadScreenshots(R.Screenshots); R.Screenshots:=nil; end;
    if (R.Translations<>nil) and (FView<>nil) and (R.SearchGeneration=FView.Document.GetValue<Int64>('generation_id')) and (R.TranslationRevision=FKnowledgeRevision) then begin
      LoadTranslations(R.Translations); R.Translations:=nil;
    end;
    if (R.Observations<>nil) and (FView<>nil) and (R.SearchGeneration=FView.Document.GetValue<Int64>('generation_id')) then begin
      FObservations.Free; FObservations:=R.Observations; R.Observations:=nil; ObservationsList.Items.Clear;
      for Value in FObservations do ObservationsList.Items.Add(Value.GetValue<string>('context')+' | generation '+Value.GetValue<Int64>('generation_id').ToString);
      ObservationMemo.Text:='Newest 50 records loaded. Select a record to read its attribution and saved text.';
      if FObservations.Count>0 then begin ObservationsList.ItemIndex:=0; ObservationSelectionClick(nil); end;
    end;
    if (R.LinkCandidates<>nil) and (FView<>nil) and (R.SearchGeneration=FView.Document.GetValue<Int64>('generation_id')) then begin
      FLinkTargets.Free; FLinkTargets:=R.LinkCandidates; R.LinkCandidates:=nil; LinkTargetsList.Items.Clear;
      for Value in FLinkTargets do LinkTargetsList.Items.Add(Value.GetValue<string>('label'));
    end;
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
var V: TJSONValue; Row: TJSONObject; Path,SavedKey,SavedForm: string; Options: TJSONArray;
  SameProject: Boolean; Index: Integer; SavedTab: TTabItem;
begin
  SameProject:=(FView<>nil) and SameText(FView.Document.GetValue<string>('root'),ADocument.GetValue<string>('root')) and
    SameText(FView.Document.GetValue<string>('entry'),ADocument.GetValue<string>('entry'));
  SavedKey:=''; SavedForm:=''; SavedTab:=WorkspaceTabs.ActiveTab;
  FreeAndNil(FReviewTasks); ReviewTasksList.Items.Clear; ReviewBeforeMemo.Text:='Refresh tasks for this captured generation.'; ReviewAfterMemo.Text:='';
  FreeAndNil(FLinkTargets); LinkTargetsList.Items.Clear;
  if SameProject then begin SavedKey:=FSelected; if FormCombo.ItemIndex>=0 then SavedForm:=FormCombo.Items[FormCombo.ItemIndex]; end;
  FreeAndNil(FSearchResults); ProjectSearchList.Items.Clear; ProjectSearchMemo.Text:='Search the current analysis generation and authored knowledge.';
  FreeAndNil(FObservations); ObservationsList.Items.Clear; ObservationMemo.Text:='Click Refresh saved records to read attributed observations for this database.';
  FSearchOffset:=0; NextProjectSearchButton.Enabled:=False;
  FreeAndNil(FView); FView:=TDPHWorkspaceView.Create(ADocument); FSelected:='';
  InspectorMemo.Text:=''; SourceMemo.Text:='Select an object to inspect source from this generation.';
  if not SameProject then begin FScope:=''; FPage:=0; FHistory.Clear; FBookmarks.Clear; FExpandedKeys.Clear; end
  else begin
    for Index:=FHistory.Count-1 downto 0 do if FView.Symbol(FHistory[Index])=nil then FHistory.Delete(Index);
    for Index:=FBookmarks.Count-1 downto 0 do if FView.Symbol(FBookmarks[Index])=nil then FBookmarks.Delete(Index);
    for Index:=FExpandedKeys.Count-1 downto 0 do if FView.Symbol(FExpandedKeys[Index])=nil then FExpandedKeys.Delete(Index);
    if (SavedKey<>'') and (FView.Symbol(SavedKey)=nil) then begin SavedKey:=''; FScope:=''; FPage:=0;
      StatusLabel.Text:='The previous selection is absent from the new generation. Explorer is reset; only surviving bookmarks and history were retained.';
    end;
  end;
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
    if FormCombo.Items.Count>0 then begin FormCombo.ItemIndex:=FormCombo.Items.IndexOf(SavedForm); if FormCombo.ItemIndex<0 then FormCombo.ItemIndex:=0; end;
    OverviewMemo.Text:=FView.FlagsText;
  finally FBinding:=False; end;
  RefreshExplorer; RefreshLearning; RefreshCoverage; RefreshQuestions;
  if SavedKey<>'' then begin SelectSymbol(SavedKey,False); ExplorerList.ItemIndex:=FExplorerKeys.IndexOf(SavedKey); end;
  if SameProject then WorkspaceTabs.ActiveTab:=SavedTab;
end;
procedure TDPHMainForm.RefreshCoverage;
var V: TJSONValue; Row: TJSONObject; Text: TStringBuilder; Verified,Current,Total: Integer;
begin
  FreeAndNil(FCoverage); CoverageList.Items.Clear; CoverageMemo.Text:='Open a captured project to see coverage and gaps.';
  if FView=nil then Exit; FCoverage:=FView.Coverage; Text:=TStringBuilder.Create;
  try
    Text.AppendLine(FView.FlagsText); Text.AppendLine('Each measure has its own denominator. N/A means no eligible records.');
    for V in FCoverage.GetValue<TJSONArray>('metrics') do begin Row:=V as TJSONObject;
      Text.AppendLine(Row.GetValue<string>('name')+': '+Row.GetValue<Int64>('numerator').ToString+' / '+Row.GetValue<Int64>('denominator').ToString+
        IfThen(Row.GetValue<Int64>('denominator')=0,' (N/A)',''));
      Text.AppendLine('  '+Row.GetValue<string>('definition'));
    end;
    Verified:=0; Current:=0; Total:=0;
    if FKnowledge<>nil then for V in FKnowledge do begin Inc(Total); Row:=V as TJSONObject;
      if Row.GetValue<string>('revision_state','')='verified' then Inc(Verified);
      if Row.GetValue<string>('pending','1')='0' then Inc(Current);
    end;
    Text.AppendLine(Format('Human records: %d verified revisions / %d total; %d without pending review tasks / %d total.',[Verified,Total,Current,Total]));
    Text.AppendLine('No pending task is not proof of current or correct content. Human verification is independent of parser measures. Runtime behavior remains unobserved unless attributed evidence is imported.');
    Text.AppendLine('Selected-project tested build: unknown; passive analysis does not compile or run it. Documentation approval: unknown unless an attributed reviewed record establishes its scope.');
    Text.AppendLine('Diagnostics below identify captured gaps; they do not enumerate every possible unsupported behavior.');
    CoverageMemo.Text:=Text.ToString;
    for V in FCoverage.GetValue<TJSONArray>('diagnostics') do begin Row:=V as TJSONObject;
      CoverageList.Items.Add(Row.GetValue<string>('severity')+' | '+Row.GetValue<string>('code')+' | '+Row.GetValue<string>('message'));
    end;
  finally Text.Free; end;
end;
procedure TDPHMainForm.RefreshQuestions;
var V: TJSONValue;
begin
  FreeAndNil(FQuestions); QuestionsList.Items.Clear; QuestionMemo.Text:='Open a captured project to derive focused author questions.';
  if FView=nil then Exit; FQuestions:=FView.Questions(FKnowledge);
  for V in FQuestions do QuestionsList.Items.Add(V.GetValue<string>('title')+' | '+V.GetValue<string>('range.source'));
  if FQuestions.Count>0 then begin QuestionsList.ItemIndex:=0; QuestionSelectionClick(nil); end
  else QuestionMemo.Text:='No unanswered question was generated by the supported rules in this scope. This does not prove complete requirements or documentation.';
end;
procedure TDPHMainForm.QuestionSelectionClick(Sender: TObject);
var Row,Range: TJSONObject;
begin
  if (FQuestions=nil) or (QuestionsList.ItemIndex<0) then Exit;
  Row:=FQuestions.Items[QuestionsList.ItemIndex] as TJSONObject; Range:=Row.GetValue<TJSONObject>('range');
  QuestionMemo.Text:=Row.GetValue<string>('prompt')+sLineBreak+sLineBreak+
    'Why this question: '+Row.GetValue<string>('rule')+sLineBreak+'Source: '+Range.GetValue<string>('source')+':'+Range.GetValue<Int64>('line').ToString+
    sLineBreak+'Source SHA256: '+Row.GetValue<string>('source_hash')+sLineBreak+'Captured generation: '+Row.GetValue<string>('generation_id')+
    sLineBreak+'Question ID: '+Row.GetValue<string>('id')+sLineBreak+sLineBreak+
    'This is a question prompted by captured evidence or absent reviewed content. It is not an author answer or a finding of runtime failure. A source location is absent for project-level procedure questions.';
end;
procedure TDPHMainForm.QuestionsClick(Sender: TObject);
var Row,Detail: TJSONObject; Kind: string;
begin
  if Sender=RefreshQuestionsButton then begin RefreshQuestions; Exit; end;
  if (FQuestions=nil) or (QuestionsList.ItemIndex<0) then Exit; Row:=FQuestions.Items[QuestionsList.ItemIndex] as TJSONObject;
  if Sender=QuestionEvidenceButton then begin
    FreeAndNil(FDetails); FDetails:=TJSONArray.Create; Detail:=TJSONObject.Create; FDetails.AddElement(Detail);
    Detail.AddPair('range',Row.GetValue<TJSONObject>('range').Clone as TJSONObject); Detail.AddPair('detail_kind','author_question');
    Detail.AddPair('title',Row.GetValue<string>('title')); Detail.AddPair('text',Row.GetValue<string>('prompt'));
    Detail.AddPair('resolution','unanswered'); Detail.AddPair('rule',Row.GetValue<string>('rule')); Detail.AddPair('source_hash',Row.GetValue<string>('source_hash'));
    Detail.AddPair('object_key',Row.GetValue<string>('entity_key')); Detail.AddPair('generation_id',Row.GetValue<string>('generation_id'));
    DetailsList.Items.Clear; DetailsList.Items.Add(Detail.GetValue<string>('title')); DetailsList.ItemIndex:=0; DetailsClick(nil); WorkspaceTabs.ActiveTab:=DetailsTab; Exit;
  end;
  if Sender<>AnswerQuestionButton then Exit;
  if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current authored edit before drafting another answer.'; Exit; end;
  NewKnowledgeClick(nil); FBinding:=True;
  try
    FKnowledgeQuestionJSON:=Row.ToJSON; FKnowledgeLink:=Row.GetValue<string>('entity_key');
    KnowledgeTitleEdit.Text:='Answer: '+Row.GetValue<string>('title'); KnowledgeAuthorEdit.Text:='';
    KnowledgeBodyMemo.Text:='Question: '+Row.GetValue<string>('prompt')+sLineBreak+sLineBreak+'Answer:'+sLineBreak;
    Kind:=Row.GetValue<string>('answer_kind','unknown'); KnowledgeKindCombo.ItemIndex:=KnowledgeKindCombo.Items.IndexOf(Kind);
    KnowledgeDocumentCombo.ItemIndex:=0; KnowledgeAudienceCombo.ItemIndex:=0; FKnowledgeEdited:=True;
  finally FBinding:=False; end;
  WorkspaceTabs.ActiveTab:=KnowledgeTab; StatusLabel.Text:='Enter the named author and their answer after Answer:, then Save. Named review is a separate action.';
end;
procedure TDPHMainForm.LoadReviewTasks(ARows: TJSONArray);
var V: TJSONValue;
begin
  FReviewTasks.Free; FReviewTasks:=ARows; ReviewTasksList.Items.Clear;
  for V in ARows do ReviewTasksList.Items.Add(V.GetValue<string>('title')+' | '+V.GetValue<string>('reason'));
  ReviewBeforeMemo.Text:='No pending review tasks in this captured scope.'; ReviewAfterMemo.Text:='This is not proof that documentation is complete or approved.';
  if ARows.Count>0 then begin ReviewTasksList.ItemIndex:=0; ReviewTaskSelectionClick(nil); end;
end;
procedure TDPHMainForm.ReviewTaskSelectionClick(Sender: TObject);
var Row: TJSONObject; V: TJSONValue; BeforeText,AfterText: TStringBuilder;
begin
  if (FReviewTasks=nil) or (ReviewTasksList.ItemIndex<0) then Exit;
  Row:=FReviewTasks.Items[ReviewTasksList.ItemIndex] as TJSONObject; BeforeText:=TStringBuilder.Create; AfterText:=TStringBuilder.Create;
  ReviewAffectedCombo.Items.Clear;
  try
    BeforeText.AppendLine('BEFORE: baseline generation '+Row.GetValue<Int64>('baseline_generation').ToString);
    BeforeText.AppendLine('Configuration: '+Row.GetValue<string>('before_configuration'));
    BeforeText.AppendLine('Prior document revision '+Row.GetValue<Int64>('prior_revision').ToString+':'); BeforeText.AppendLine(Row.GetValue<string>('before_body'));
    AfterText.AppendLine('AFTER: captured generation '+Row.GetValue<Int64>('current_generation').ToString);
    AfterText.AppendLine('Original task trigger: '+Row.GetValue<string>('reason'));
    AfterText.AppendLine('Configuration: '+Row.GetValue<string>('after_configuration'));
    AfterText.AppendLine('Document revision '+Row.GetValue<string>('revision')+' | '+Row.GetValue<string>('revision_state')+':'); AfterText.AppendLine(Row.GetValue<string>('body'));
    BeforeText.AppendLine('Affected source objects (first 200):'); AfterText.AppendLine('Affected source objects (first 200):');
    for V in Row.GetValue<TJSONArray>('affected') do begin
      ReviewAffectedCombo.Items.Add(V.GetValue<string>('display_name'));
      BeforeText.AppendLine(V.GetValue<string>('display_name')+' | present '+V.GetValue<string>('before_present'));
      BeforeText.AppendLine('  Source: '+V.GetValue<string>('before_source')+' | type '+V.GetValue<string>('before_type'));
      BeforeText.AppendLine('  Signature: '+V.GetValue<string>('before_signature')); BeforeText.AppendLine('  SHA256: '+V.GetValue<string>('before_hash'));
      AfterText.AppendLine(V.GetValue<string>('display_name')+' | present '+V.GetValue<string>('after_present'));
      AfterText.AppendLine('  Source: '+V.GetValue<string>('after_source')+' | type '+V.GetValue<string>('after_type'));
      AfterText.AppendLine('  Signature: '+V.GetValue<string>('after_signature')); AfterText.AppendLine('  SHA256: '+V.GetValue<string>('after_hash'));
    end;
    BeforeText.AppendLine('Static relationships (first 200):'); AfterText.AppendLine('Static relationships (first 200):');
    for V in Row.GetValue<TJSONArray>('before_relationships') do BeforeText.AppendLine(V.GetValue<string>('from_key')+' -> '+V.GetValue<string>('relation_kind')+' -> '+V.GetValue<string>('to_key')+' | '+V.GetValue<string>('resolution_status'));
    for V in Row.GetValue<TJSONArray>('after_relationships') do AfterText.AppendLine(V.GetValue<string>('from_key')+' -> '+V.GetValue<string>('relation_kind')+' -> '+V.GetValue<string>('to_key')+' | '+V.GetValue<string>('resolution_status'));
    BeforeText.AppendLine('Empty baseline fields mean no captured comparison, not absence of behavior.');
    AfterText.AppendLine('Reachability and source changes do not establish runtime impact. Review the source and attributed content before approval.');
    ReviewBeforeMemo.Text:=BeforeText.ToString; ReviewAfterMemo.Text:=AfterText.ToString;
    if ReviewAffectedCombo.Items.Count>0 then ReviewAffectedCombo.ItemIndex:=0;
  finally AfterText.Free; BeforeText.Free; end;
end;
procedure TDPHMainForm.ReviewTasksClick(Sender: TObject);
var Request: TDPHWorkspaceRequest; Row: TJSONObject; V: TJSONValue; Index: Integer; Key: string;
begin
  if FBusy or (FView=nil) then Exit;
  if Sender=RefreshReviewTasksButton then begin
    Request:=Default(TDPHWorkspaceRequest); Request.Command:='review_tasks'; Request.Database:=FDatabase; Request.Entry:=FEntry;
    Request.GenerationID:=FView.Document.GetValue<Int64>('generation_id'); FWorker.Submit(Request); FBusy:=True; FPendingCommand:='review_tasks'; Exit;
  end;
  if (FReviewTasks=nil) or (ReviewTasksList.ItemIndex<0) then Exit;
  Row:=FReviewTasks.Items[ReviewTasksList.ItemIndex] as TJSONObject;
  if Row.GetValue<Int64>('current_generation')<>FView.Document.GetValue<Int64>('generation_id') then begin StatusLabel.Text:='Refresh tasks for the current generation first.'; Exit; end;
  if Sender=ReviewImpactButton then begin
    Key:=''; if ReviewAffectedCombo.ItemIndex>=0 then Key:=Row.GetValue<TJSONArray>('affected').Items[ReviewAffectedCombo.ItemIndex].GetValue<string>('canonical_key');
    if (Key='') or (FView.Symbol(Key)=nil) then begin Key:=''; for V in Row.GetValue<TJSONArray>('affected') do if FView.Symbol(V.GetValue<string>('canonical_key'))<>nil then begin Key:=V.GetValue<string>('canonical_key'); Break; end; end;
    if Key='' then begin StatusLabel.Text:='This task has no surviving captured source object. Inspect its documentation links and before/after evidence.'; Exit; end;
    SelectSymbol(Key); GraphCombo.ItemIndex:=GraphCombo.Items.IndexOf('Change impact'); FWholeGraph:=False; RefreshGraphics; WorkspaceTabs.ActiveTab:=GraphTab; Exit;
  end;
  if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the authored edit before opening another task.'; Exit; end;
  if Row.GetValue<Int64>('knowledge_id')=0 then begin StatusLabel.Text:='This source investigation has no authored record to approve. Inspect evidence and create attributed knowledge first.'; Exit; end;
  PendingKnowledgeCheck.IsChecked:=False; KnowledgeFilterChange(nil);
  for Index:=0 to FKnowledgeRows.Count-1 do if FKnowledgeRows[Index].GetValue<Int64>('id')=Row.GetValue<Int64>('knowledge_id') then begin KnowledgeList.ItemIndex:=Index; KnowledgeClick(nil); Break; end;
  if (FKnowledgeID<>Row.GetValue<Int64>('knowledge_id')) or (FKnowledgeRevision<>Row.GetValue<Int64>('revision')) then begin StatusLabel.Text:='The task revision changed. Refresh tasks and knowledge before reviewing.'; Exit; end;
  if Sender=OpenReviewKnowledgeButton then begin WorkspaceTabs.ActiveTab:=KnowledgeTab; Exit; end;
  if not ((Sender=VerifyTaskButton) or (Sender=RetireTaskButton)) then Exit;
  if Trim(ReviewReviewerEdit.Text)='' then begin StatusLabel.Text:='Enter the named reviewer before recording a disposition.'; Exit; end;
  KnowledgeAuthorEdit.Text:=ReviewReviewerEdit.Text; FReviewState:='verified'; if Sender=RetireTaskButton then FReviewState:='retired'; Submit('review_knowledge');
end;
procedure TDPHMainForm.CoverageInspectClick(Sender: TObject);
var Row: TJSONObject; Range: TJSONObject; FileRow: TJSONObject;
begin
  if (FCoverage=nil) or (CoverageList.ItemIndex<0) then Exit;
  Row:=FCoverage.GetValue<TJSONArray>('diagnostics').Items[CoverageList.ItemIndex].Clone as TJSONObject;
  FreeAndNil(FDetails); FDetails:=TJSONArray.Create; FDetails.AddElement(Row);
  Row.AddPair('detail_kind','diagnostic'); Row.AddPair('title',Row.GetValue<string>('code'));
  Row.AddPair('text',Row.GetValue<string>('message')); Row.AddPair('resolution','unresolved'); Row.AddPair('rule',Row.GetValue<string>('code'));
  Range:=Row.GetValue<TJSONObject>('range'); FileRow:=FView.SourceFile(Range.GetValue<string>('source'));
  if FileRow<>nil then Row.AddPair('source_hash',FileRow.GetValue<string>('sha256'));
  DetailsList.Items.Clear; DetailsList.Items.Add(Row.GetValue<string>('title')); DetailsList.ItemIndex:=0;
  DetailsClick(nil); WorkspaceTabs.ActiveTab:=DetailsTab;
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
var HTML,PreviewPath: string;
begin
  if FExplanations=nil then Exit;
  OverviewMemo.Text:=FExplanations.TopicText(Max(0,LearningTopics.ItemIndex));
  HTML:=FExplanations.TopicHTML(Max(0,LearningTopics.ItemIndex)); PreviewPath:=TPath.Combine(FLearningDirectory,THashSHA2.GetHashString(HTML)+'.html');
  if not FPreviewPages.Contains(PreviewPath) then begin TFile.WriteAllBytes(PreviewPath,TEncoding.UTF8.GetBytes(HTML)); FPreviewPages.Add(PreviewPath); end;
  try LearningBrowser.WindowsEngine:=TWindowsEngine.EdgeOnly; LearningBrowser.Visible:=True;
    LearningBrowser.Navigate('file://'+PreviewPath);
  except on E: Exception do begin LearningBrowser.Visible:=False; StatusLabel.Text:='Learning preview unavailable; text fallback is shown: '+E.Message; end; end;
end;
procedure TDPHMainForm.ShowExplanation;
var HTML,PreviewPath: string;
begin
  if FExplanations=nil then Exit;
  ExplainFallback.Text:=FExplanations.ObjectText(FSelected);
  HTML:=FExplanations.ObjectHTML(FSelected); PreviewPath:=TPath.Combine(FExplainDirectory,THashSHA2.GetHashString(HTML)+'.html');
  if not FPreviewPages.Contains(PreviewPath) then begin TFile.WriteAllBytes(PreviewPath,TEncoding.UTF8.GetBytes(HTML)); FPreviewPages.Add(PreviewPath); end;
  try ExplainBrowser.WindowsEngine:=TWindowsEngine.EdgeOnly; ExplainBrowser.Visible:=True;
    ExplainBrowser.Navigate('file://'+PreviewPath);
  except on E: Exception do begin ExplainBrowser.Visible:=False; StatusLabel.Text:='Object preview unavailable; text fallback is shown: '+E.Message; end; end;
end;
procedure TDPHMainForm.LearningShouldLoad(Sender: TObject; const AURL: string; var ACancel: Boolean);
var Directory,Fragment: string; P: Integer; V: TJSONValue; S: TJSONObject;
begin
  Directory:=FLearningDirectory; if Sender=ExplainBrowser then Directory:=FExplainDirectory;
  if Sender=FlowBrowser then Directory:=FFlowDirectory;
  if Sender=HelpBrowser then Directory:=TPath.Combine(FBaseDirectory,'help');
  ACancel:=not TDPHBrowserPolicy.Allowed(AURL,Directory,False,Sender<>HelpBrowser); if ACancel then Exit;
  P:=Pos('#g_',AURL);
  if (P>0) and (FGraph<>nil) then begin
    ACancel:=True; Fragment:=Copy(AURL,P+3,MaxInt);
    for V in FGraph.GetValue<TJSONArray>('nodes') do begin S:=V as TJSONObject;
      if SameText(THashSHA2.GetHashString(S.GetValue('id').Value),Fragment) then begin GraphGroupDetails(S.GetValue('id').Value); Break; end;
    end;
    Exit;
  end;
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
procedure TDPHMainForm.ObservationSelectionClick(Sender: TObject);
var Row: TJSONObject;
begin
  if (FObservations=nil) or (ObservationsList.ItemIndex<0) then Exit;
  Row:=FObservations.Items[ObservationsList.ItemIndex] as TJSONObject;
  ObservationMemo.Text:='CONTRIBUTOR CLAIM - UNVERIFIED'+sLineBreak+Row.GetValue<string>('context')+sLineBreak+
    'Contributor: '+Row.GetValue<string>('contributor')+sLineBreak+'Imported UTC: '+Row.GetValue<string>('imported_utc')+sLineBreak+
    'Captured generation: '+Row.GetValue('generation_id').Value+sLineBreak+'Linked object: '+Row.GetValue<string>('entity_key')+sLineBreak+
    'Linked source SHA256: '+Row.GetValue<string>('linked_source_hash')+sLineBreak+'Original extract SHA256: '+Row.GetValue<string>('original_sha256')+sLineBreak+
    Row.GetValue<string>('provenance')+sLineBreak+sLineBreak+'SAVED TEXT (file order; timestamps are unverified)'+sLineBreak+Row.GetValue<string>('text');
end;
procedure TDPHMainForm.LoadTranslations(ARows: TJSONArray);
var Value: TJSONValue;
begin
  FTranslations.Free; FTranslations:=ARows; TranslationList.Items.Clear; TranslationMemo.Text:='';
  for Value in FTranslations do TranslationList.Items.Add(Value.GetValue<string>('locale')+' | '+Value.GetValue<string>('state')+' | reviewer '+Value.GetValue<string>('reviewer'));
  TranslationStatus.Text:='Saved translations loaded. Select one to compare protected/source text and localized prose.';
  if FTranslations.Count>0 then begin TranslationList.ItemIndex:=0; TranslationSelectionClick(nil); end;
end;
procedure TDPHMainForm.TranslationSelectionClick(Sender: TObject);
var Row: TJSONObject; Segment: TJSONValue; SourceText,TranslatedText: string;
begin
  if (FTranslations=nil) or (TranslationList.ItemIndex<0) then Exit;
  Row:=FTranslations.Items[TranslationList.ItemIndex] as TJSONObject;
  SourceText:=''; TranslatedText:='';
  for Segment in Row.GetValue<TJSONArray>('segments') do begin
    SourceText:=SourceText+Segment.GetValue<string>('source_text'); TranslatedText:=TranslatedText+Segment.GetValue<string>('text');
  end;
  TranslationStatus.Text:='Revision '+Row.GetValue<string>('revision')+' | '+Row.GetValue<string>('source_locale')+' to '+Row.GetValue<string>('locale')+
    ' (pack locale '+Row.GetValue<string>('resolved_locale',Row.GetValue<string>('locale'))+')'+
    ' | '+Row.GetValue<string>('state')+' | source fallbacks '+Row.GetValue<Integer>('source_fallback_count',0).ToString+
    ' | reviewer '+Row.GetValue<string>('reviewer')+'. Code, paths and identifiers remain unchanged.';
  TranslationMemo.Text:='SOURCE'+sLineBreak+SourceText+sLineBreak+sLineBreak+'LOCALIZED PROSE'+sLineBreak+TranslatedText+
    sLineBreak+sLineBreak+'EXACT CACHE ID: '+Row.GetValue<string>('cache_key')+sLineBreak+'PROVIDER: '+Row.GetValue<string>('provider')+
    sLineBreak+'PACK VERSION: '+Row.GetValue<string>('provider_version')+sLineBreak+'TERMINOLOGY SHA256: '+Row.GetValue<string>('terminology_hash')+
    sLineBreak+'LAST REVIEWED UTC: '+Row.GetValue<string>('reviewed_at','never');
end;
procedure TDPHMainForm.TranslationClick(Sender: TObject);
var Request: TDPHWorkspaceRequest; Row: TJSONObject; Terms: TJSONValue;
begin
  if FBusy or (FView=nil) then Exit;
  if Sender=TranslationTermsResetButton then begin FTerminologyJSON:='{}'; TranslationStatus.Text:='Terminology dictionary cleared for the next translation. Existing exact cache records remain available.'; Exit; end;
  if Sender=TranslationTermsButton then begin
    if not TerminologyDialog.Execute then Exit;
    try
      if TFile.GetSize(TerminologyDialog.FileName)>256*1024 then raise EReadError.Create('Terminology dictionary is limited to 256 KiB');
      Terms:=TJSONObject.ParseJSONValue(TFile.ReadAllText(TerminologyDialog.FileName,TEncoding.UTF8));
      try if not (Terms is TJSONObject) then raise EReadError.Create('Terminology must be a JSON object mapping exact prose to localized prose');
        FTerminologyJSON:=Terms.ToJSON;
      finally Terms.Free; end;
      TranslationStatus.Text:='Selected terminology dictionary applies to the next translation. Its hash is part of the cache identity.';
    except on E: Exception do StatusLabel.Text:=E.Message; end;
    Exit;
  end;
  if (FKnowledgeRevision<1) or FKnowledgeEdited then begin StatusLabel.Text:='In Knowledge, select a saved revision and save any edits before translating.'; Exit; end;
  Request:=Default(TDPHWorkspaceRequest); Request.Command:='translations'; Request.Database:=FDatabase;
  Request.Entry:=FEntry; Request.Configuration:=ConfigurationCombo.Items[ConfigurationCombo.ItemIndex]; Request.Platform:=PlatformCombo.Items[PlatformCombo.ItemIndex];
  Request.Defines:=DefinesEdit.Text.Split([';'],TStringSplitOptions.ExcludeEmpty); Request.ExternalRoots:=ExternalRootsEdit.Text.Split([';'],TStringSplitOptions.ExcludeEmpty);
  if not TryStrToInt(CodePageEdit.Text,Request.CodePage) or (Request.CodePage<0) or (Request.CodePage>65535) then begin StatusLabel.Text:='Enter a valid source code page first'; Exit; end;
  Request.GenerationID:=FView.Document.GetValue<Int64>('generation_id'); Request.ExpectedRevision:=FKnowledgeRevision;
  if Sender=TranslationPackButton then begin
    if not TranslationDialog.Execute then Exit;
    Request.Command:='translate'; Request.Body:=TranslationDialog.FileName; Request.Kind:=Trim(TranslationSourceLocale.Text);
    Request.Audience:=Trim(TranslationTargetLocale.Text); Request.LinksJSON:=FTerminologyJSON; if Request.LinksJSON='' then Request.LinksJSON:='{}';
  end;
  if Sender=TranslationReviewButton then begin
    if (FTranslations=nil) or (TranslationList.ItemIndex<0) then begin StatusLabel.Text:='Select a saved translation first.'; Exit; end;
    Row:=FTranslations.Items[TranslationList.ItemIndex] as TJSONObject;
    if Row.GetValue<Int64>('revision')<>FKnowledgeRevision then begin StatusLabel.Text:='Refresh translations for the selected source revision first.'; Exit; end;
    Request.Command:='review_translation'; Request.Title:=Row.GetValue<string>('cache_key'); Request.Editor:=Trim(TranslationReviewer.Text);
    if Request.Editor='' then begin StatusLabel.Text:='Enter the named translation reviewer first.'; Exit; end;
  end;
  FWorker.Submit(Request); FBusy:=True;
end;
procedure TDPHMainForm.ValidateBundleClick(Sender: TObject);
var Request: TDPHWorkspaceRequest; Fingerprint: string; Character: Char;
begin
  if FBusy then Exit;
  if Sender=ValidationUseCaptureButton then begin
    if FView=nil then begin ValidationMemo.Text:='Open a trusted project capture first, or enter its separately retained expected fingerprint.'; Exit; end;
    ValidationFingerprintEdit.Text:=FView.Document.GetValue<string>('semantics.input_fingerprint');
    ValidationMemo.Text:='Expected fingerprint copied from the opened capture. Select the bundle manifest to validate it against this identity.'; Exit;
  end;
  Fingerprint:=LowerCase(Trim(ValidationFingerprintEdit.Text));
  if Length(Fingerprint)<>64 then begin ValidationMemo.Text:='Enter the separately trusted 64-character capture fingerprint, or click Use opened capture fingerprint.'; Exit; end;
  for Character in Fingerprint do if not CharInSet(Character,['0'..'9','a'..'f']) then begin ValidationMemo.Text:='The expected fingerprint must contain exactly 64 hexadecimal characters.'; Exit; end;
  if not ValidationDialog.Execute then Exit;
  if not SameText(ExtractFileName(ValidationDialog.FileName),'manifest.json') then begin ValidationMemo.Text:='Select manifest.json in the root of the intended handoff bundle.'; Exit; end;
  Request:=Default(TDPHWorkspaceRequest); Request.Command:='validate_bundle'; Request.ExportDirectory:=ExtractFileDir(ValidationDialog.FileName);
  Request.Title:=Fingerprint; Request.AllowStaleBundle:=ValidationAllowStale.IsChecked;
  FWorker.Submit(Request); FBusy:=True; FPendingCommand:=Request.Command;
  ValidationMemo.Text:='Checking bundle integrity and source identity in the background...';
end;
procedure TDPHMainForm.ObservationsClick(Sender: TObject);
var Request: TDPHWorkspaceRequest; Row: TJSONObject;
begin
  if FBusy or (FView=nil) then Exit;
  if Sender=ObservationObjectButton then begin
    if (FObservations=nil) or (ObservationsList.ItemIndex<0) then Exit;
    Row:=FObservations.Items[ObservationsList.ItemIndex] as TJSONObject;
    if (Row.GetValue<Int64>('generation_id')<>FView.Document.GetValue<Int64>('generation_id')) or (Row.GetValue<string>('entity_key')='') then begin
      StatusLabel.Text:='This record is historical or has no object link. Its attribution remains available; no current object identity is assumed.'; Exit;
    end;
    SelectSymbol(Row.GetValue<string>('entity_key')); Exit;
  end;
  Request:=Default(TDPHWorkspaceRequest); Request.Command:='observations'; Request.Database:=FDatabase; Request.Entry:=FEntry;
  Request.GenerationID:=FView.Document.GetValue<Int64>('generation_id');
  if Sender=ImportObservationButton then begin
    if (Trim(ObservationContributor.Text)='') or (Trim(ObservationContext.Text)='') then begin StatusLabel.Text:='Enter the contributor and run/environment description before selecting a saved log.'; Exit; end;
    if not ObservationDialog.Execute then Exit;
    Request.Command:='import_observation'; Request.Body:=ObservationDialog.FileName; Request.Editor:=ObservationContributor.Text;
    Request.Title:=ObservationContext.Text; Request.EntityKey:=FSelected;
  end;
  FWorker.Submit(Request); FBusy:=True; StatusLabel.Text:='Reading explicitly saved observation text; no target program is executed.';
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
var V: TJSONValue; R: TJSONObject; Index: Integer; Thumbnail: TBitmap; Path: string;
begin
  FImages.Free; FImages:=ARows; ScreenshotList.Items.Clear;
  for V in ARows do begin R:=V as TJSONObject;
    Index:=ScreenshotList.Items.Add(R.GetValue<string>('caption')+' | generation '+R.GetValue('generation_id').Value);
    Path:=R.GetValue<string>('managed_path'); Thumbnail:=TBitmap.Create;
    try
      try
        if THashSHA2.GetHashStringFromFile(Path)<>R.GetValue<string>('image_sha256') then raise EReadError.Create('Image changed');
        Thumbnail.LoadFromFile(Path); Thumbnail.Resize(128,96);
        ScreenshotList.ListItems[Index].ItemData.Bitmap.Assign(Thumbnail);
      except on E: Exception do ScreenshotList.ListItems[Index].Text:='[Unavailable] '+ScreenshotList.ListItems[Index].Text; end;
    finally Thumbnail.Free; end;
  end;
  ScreenshotEvidence.Text:='Imported images are contributor evidence, separate from the design-time reconstruction. Capture time and runtime origin require review.';
  ScreenshotImage.Bitmap.SetSize(0,0);
end;
procedure TDPHMainForm.ScreenshotClick(Sender: TObject);
var R: TJSONObject; Path: string;
begin
  if (FImages=nil) or (ScreenshotList.ItemIndex<0) then Exit;
  R:=FImages.Items[ScreenshotList.ItemIndex] as TJSONObject; Path:=R.GetValue<string>('managed_path');
  try
    if THashSHA2.GetHashStringFromFile(Path)<>R.GetValue<string>('image_sha256') then raise EReadError.Create('Screenshot changed after validation');
    ScreenshotImage.Bitmap.LoadFromFile(Path); UpdateScreenshotBounds;
    ScreenshotEvidence.Text:=R.GetValue<string>('caption')+sLineBreak+'Contributor: '+R.GetValue<string>('author')+sLineBreak+
      'Imported: '+R.GetValue<string>('imported_utc')+' | generation '+R.GetValue('generation_id').Value+sLineBreak+
      R.GetValue<string>('provenance')+sLineBreak+'Status: '+R.GetValue<string>('verification_state')+sLineBreak+
      Format('Image: %d x %d pixels',[ScreenshotImage.Bitmap.Width,ScreenshotImage.Bitmap.Height])+sLineBreak+
      'Linked object: '+R.GetValue<string>('entity_key','')+sLineBreak+'SHA256 '+R.GetValue<string>('image_sha256');
  except on E: Exception do begin ScreenshotImage.Bitmap.Clear(TAlphaColors.Null); ScreenshotEvidence.Text:='Image unavailable: '+E.Message; end; end;
end;
procedure TDPHMainForm.UpdateScreenshotBounds;
var Scale: Single;
begin
  if ScreenshotImage.Bitmap.IsEmpty then Exit;
  Scale:=1;
  case ScreenshotModeCombo.ItemIndex of
    0: Scale:=Min(Max(1,ScreenshotScroll.Width-24)/ScreenshotImage.Bitmap.Width,
      Max(1,ScreenshotScroll.Height-24)/ScreenshotImage.Bitmap.Height);
    2: Scale:=ScreenshotZoom.Value/100;
  end;
  ScreenshotImage.Width:=Max(1,ScreenshotImage.Bitmap.Width*Scale);
  ScreenshotImage.Height:=Max(1,ScreenshotImage.Bitmap.Height*Scale);
end;
procedure TDPHMainForm.ScreenshotViewChange(Sender: TObject);
begin
  if Sender=ScreenshotZoom then begin FBinding:=True; try ScreenshotModeCombo.ItemIndex:=2; finally FBinding:=False; end; end;
  if not FBinding then UpdateScreenshotBounds;
end;
procedure TDPHMainForm.ScreenshotInspectClick(Sender: TObject);
var Row: TJSONObject; Key: string;
begin
  if (FImages=nil) or (FView=nil) or (ScreenshotList.ItemIndex<0) then Exit;
  Row:=FImages.Items[ScreenshotList.ItemIndex] as TJSONObject; Key:=Row.GetValue<string>('entity_key','');
  if (Key<>'') and (FView.Symbol(Key)<>nil) then begin SelectSymbol(Key); WorkspaceTabs.ActiveTab:=ExplainTab; end
  else StatusLabel.Text:='This screenshot has no matching object in the current captured generation. Its image evidence remains available.';
end;
procedure TDPHMainForm.RefreshExplorer;
var Rows: TJSONArray; V: TJSONValue; S: TJSONObject; Kind,LabelText,Prefix: string; Depth: Integer;
begin
  if FView=nil then Exit; Kind:=''; if KindCombo.ItemIndex>0 then Kind:=KindCombo.Items[KindCombo.ItemIndex];
  FHierarchyVisible:=(Trim(SearchEdit.Text)='') and (Kind='') and (FScope='');
  ExplorerExpandButton.Enabled:=FHierarchyVisible;
  if FHierarchyVisible then Rows:=FView.Hierarchy(FExpandedKeys.ToArray,FPage,250)
  else Rows:=FView.Search(SearchEdit.Text,Kind,FScope,FPage,250);
  if (Rows.Count=0) and (FPage>0) then begin Rows.Free; FPage:=0; RefreshExplorer; Exit; end;
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
    'Generation: '+Row.GetValue<string>('generation_id',FView.Document.GetValue('generation_id').Value)+sLineBreak+sLineBreak+
    'This is captured static evidence. Open matching source verifies the file hash before applying this range. Detached mode retains the evidence above.';
end;

procedure TDPHMainForm.DetailsObjectClick(Sender: TObject);
var Row: TJSONObject; Key: string;
begin
  if (FDetails=nil) or (DetailsList.ItemIndex<0) or (DetailsList.ItemIndex>=FDetails.Count) then Exit;
  Row:=FDetails.Items[DetailsList.ItemIndex] as TJSONObject; Key:=Row.GetValue<string>('object_key',FSelected);
  if (Key='') or (FView.Symbol(Key)=nil) then Exit; SelectSymbol(Key); WorkspaceTabs.ActiveTab:=ExplainTab;
end;
procedure TDPHMainForm.DetailsSourceClick(Sender: TObject);
var Row,Range,FileRow: TJSONObject; Path: string; Source: TDPHSource; Diagnostics: TDPHDiagnostics;
begin
  if (FDetails=nil) or (DetailsList.ItemIndex<0) or (DetailsList.ItemIndex>=FDetails.Count) then Exit;
  DetailsClick(nil);
  if FDetached or (FEntry='') then begin DetailsMemo.Lines.Add('Original source is detached. The cached statement/value and source evidence remain available here.'); Exit; end;
  Row:=FDetails.Items[DetailsList.ItemIndex] as TJSONObject; Range:=Row.GetValue<TJSONObject>('range');
  if Row.GetValue<Int64>('generation_id',FView.Document.GetValue<Int64>('generation_id'))<>FView.Document.GetValue<Int64>('generation_id') then begin DetailsMemo.Lines.Add('Historical evidence: source navigation is disabled until this target is reviewed against the current generation.'); Exit; end;
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
begin
  if FBinding then Exit;
  if Sender=GraphCombo then FWholeGraph:=False;
  if Sender=ScreenZoom then begin FBinding:=True; try ScreenModeCombo.ItemIndex:=3; finally FBinding:=False; end; end;
  if (Sender=ScreenModeCombo) and (ScreenModeCombo.ItemIndex=4) and not FScreenFullscreen then FullscreenClick(nil);
  RefreshGraphics;
end;
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
procedure TDPHMainForm.AllDataGraphClick(Sender: TObject);
begin
  if FView=nil then Exit;
  GraphCombo.ItemIndex:=GraphCombo.Items.IndexOf('Data flow'); FWholeGraph:=True; RefreshGraphics;
  WorkspaceTabs.ActiveTab:=GraphTab;
  StatusLabel.Text:='Project data: source input/output dependencies, resources, SQL and artifacts. Arrow labels retain their rules; runtime values and context are unverified.';
end;
procedure TDPHMainForm.RefreshGraphics;
const WholeKinds: array[0..2] of string = ('Execution','Form navigation','Data flow');
var Grouped: TJSONObject; Limit: Integer; HTML,GraphPath: string;
begin
  FreeAndNil(FGraph); FreeAndNil(FScreen); if FView=nil then Exit;
  FlowBrowser.Visible:=False;
  Limit:=120; GraphGroupingCombo.Enabled:=GraphCombo.ItemIndex<>1;
  if (GraphCombo.ItemIndex<>1) and (GraphGroupingCombo.ItemIndex>0) then Limit:=1000;
  if FWholeGraph and MatchText(GraphCombo.Items[GraphCombo.ItemIndex],WholeKinds) then FGraph:=FView.Graph(GraphCombo.Items[GraphCombo.ItemIndex],'',Limit)
  else if GraphCombo.ItemIndex>=0 then FGraph:=FView.Graph(GraphCombo.Items[GraphCombo.ItemIndex],FSelected,Limit);
  if (FGraph<>nil) and (GraphCombo.ItemIndex<>1) and (GraphGroupingCombo.ItemIndex>0) then begin
    Grouped:=TDPHGraphProjection.Group(FView,FGraph,GraphGroupingCombo.Items[GraphGroupingCombo.ItemIndex]); FGraph.Free; FGraph:=Grouped;
  end;
  if (FGraph<>nil) and (FExplanations<>nil) then begin
    if GraphCombo.ItemIndex=1 then HTML:=FExplanations.FlowHTML(FSelected) else HTML:=FExplanations.GraphHTML(FGraph);
    GraphPath:=TPath.Combine(FFlowDirectory,THashSHA2.GetHashString(HTML)+'.html');
    if not FPreviewPages.Contains(GraphPath) then begin
      TFile.WriteAllBytes(GraphPath,TEncoding.UTF8.GetBytes(HTML)); FPreviewPages.Add(GraphPath);
    end;
    try FlowBrowser.WindowsEngine:=TWindowsEngine.EdgeOnly; FlowBrowser.Visible:=True;
      FlowBrowser.Navigate('file://'+GraphPath);
    except on E: Exception do begin FlowBrowser.Visible:=False; StatusLabel.Text:='HTML graph view unavailable; native graph retained: '+E.Message; end; end;
  end;
  if ScreenModeCombo.ItemIndex=0 then FScreen:=TDPHScreenLayout.Gallery(FView)
  else if FormCombo.ItemIndex>=0 then FScreen:=TDPHScreenLayout.Reconstruct(FView,FormCombo.Items[FormCombo.ItemIndex]);
  UpdateScreenBounds; GraphPaint.Repaint; ScreenPaint.Repaint;
end;
procedure TDPHMainForm.GraphGroupDetails(const AGroup: string);
var V,W,E: TJSONValue; GroupRow,Symbol,Row,Edge: TJSONObject; Key: string; EvidenceRows: TList<TJSONObject>;
begin
  if (FGraph=nil) or (FView=nil) then Exit;
  for V in FGraph.GetValue<TJSONArray>('nodes') do begin
    GroupRow:=V as TJSONObject; if (GroupRow.GetValue('id').Value<>AGroup) or (GroupRow.GetValue<string>('kind','')<>'group') then Continue;
    FreeAndNil(FDetails); FDetails:=TJSONArray.Create; DetailsList.Items.Clear;
    for W in GroupRow.GetValue<TJSONArray>('members') do begin
      Key:=W.Value; Symbol:=FView.Symbol(Key); if Symbol=nil then Continue;
      Row:=Symbol.Clone as TJSONObject; FDetails.AddElement(Row);
      Row.AddPair('detail_kind','group member'); Row.AddPair('title',Symbol.GetValue<string>('name'));
      Row.AddPair('text',Symbol.GetValue<string>('kind')+': '+Symbol.GetValue<string>('signature'));
      Row.AddPair('object_key',Key); Row.AddPair('resolution','inferred'); Row.AddPair('rule','lexical_graph_group_not_runtime_ownership');
      DetailsList.Items.Add('member | '+Symbol.GetValue<string>('name'));
    end;
    EvidenceRows:=TList<TJSONObject>.Create;
    try
    for E in GroupRow.GetValue<TJSONArray>('internal_evidence') do EvidenceRows.Add(E as TJSONObject);
    for W in FGraph.GetValue<TJSONArray>('edges') do begin
      Edge:=W as TJSONObject; if (Edge.GetValue('from').Value<>AGroup) and (Edge.GetValue('to').Value<>AGroup) then Continue;
      for E in Edge.GetValue<TJSONArray>('evidence') do EvidenceRows.Add(E as TJSONObject);
    end;
    for Edge in EvidenceRows do begin
        if FDetails.Count>=1000 then Break;
        Row:=Edge.Clone as TJSONObject; FDetails.AddElement(Row); Row.AddPair('detail_kind','group relationship');
        Row.AddPair('title',Row.GetValue<string>('kind')); Row.AddPair('text',Row.GetValue<string>('label'));
        Key:=Row.GetValue<string>('to',''); if Key='' then Key:=Row.GetValue<string>('from'); Row.AddPair('object_key',Key);
        DetailsList.Items.Add('evidence | '+Row.GetValue<string>('kind')+' | '+Row.GetValue<string>('label'));
    end;
    finally EvidenceRows.Free; end;
    DetailsMemo.Text:='Group: '+GroupRow.GetValue<string>('label')+sLineBreak+
      'Members in this captured projection: '+GroupRow.GetValue<Integer>('member_count').ToString+sLineBreak+
      'Internal source relationships: '+GroupRow.GetValue<Integer>('internal_relationships').ToString+sLineBreak+sLineBreak+
      'Select a member or evidence row. Open linked object reads its explanation; Open matching source verifies its file. Counts cover the bounded projection. Grouped connections retain up to 16 evidence examples each; at most 1,000 detail rows are shown.';
    WorkspaceTabs.ActiveTab:=DetailsTab; Exit;
  end;
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
var I: Integer; N,Row: TJSONObject; Nodes: TJSONArray;
begin
  if FGraph=nil then Exit; Nodes:=FGraph.GetValue<TJSONArray>('nodes');
  for I:=0 to Nodes.Count-1 do if GraphRect(I).Contains(TPointF.Create(X,Y)) then begin N:=Nodes.Items[I] as TJSONObject;
    if N.GetValue<string>('kind','')='group' then GraphGroupDetails(N.GetValue('id').Value)
    else if FGraph.GetValue<string>('kind')='Procedure CFG' then begin
      FreeAndNil(FDetails); FDetails:=TJSONArray.Create; Row:=N.Clone as TJSONObject; FDetails.AddElement(Row);
      Row.AddPair('detail_kind','statement'); Row.AddPair('title',N.GetValue<string>('kind')); Row.AddPair('text',N.GetValue<string>('expression'));
      Row.AddPair('resolution','inferred'); Row.AddPair('rule','captured_control_flow_not_runtime_trace'); Row.AddPair('object_key',FSelected);
      DetailsList.Items.Clear; DetailsList.Items.Add(N.GetValue<string>('label')); DetailsList.ItemIndex:=0; DetailsClick(nil); WorkspaceTabs.ActiveTab:=DetailsTab;
    end else SelectSymbol(N.GetValue<string>('id')); Break;
  end;
end;
procedure TDPHMainForm.ScreenPaintPaint(Sender: TObject; Canvas: TCanvas);
var Rows: TJSONArray; V: TJSONValue; R: TJSONObject; Bounds: TRectF;
begin
  if FScreen=nil then Exit; Rows:=FScreen.GetValue<TJSONArray>('components');
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
begin
  if not FScreenFullscreen then begin
    FSavedBorder:=BorderStyle; FSavedWindowState:=WindowState; FScreenFullscreen:=True;
    WorkspaceTabs.ActiveTab:=ScreenTab; BorderStyle:=TFmxFormBorderStyle.None;
    WindowState:=TWindowState.wsMaximized; FullscreenButton.Text:='Exit full screen';
  end else begin
    FScreenFullscreen:=False; BorderStyle:=FSavedBorder; WindowState:=FSavedWindowState;
    FullscreenButton.Text:='Full screen';
    if ScreenModeCombo.ItemIndex=4 then begin FBinding:=True; try ScreenModeCombo.ItemIndex:=1; finally FBinding:=False; end; end;
  end;
  HeaderLayout.Visible:=not FScreenFullscreen; CommandScroll.Visible:=not FScreenFullscreen;
  ExplorerLayout.Visible:=not FScreenFullscreen; ExplorerSplitter.Visible:=not FScreenFullscreen;
  InspectorLayout.Visible:=not FScreenFullscreen; InspectorSplitter.Visible:=not FScreenFullscreen;
  UpdateScreenBounds;
end;
procedure TDPHMainForm.FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin if (Key=vkEscape) and FScreenFullscreen then begin FullscreenClick(nil); Key:=0; end; end;
procedure TDPHMainForm.FormResize(Sender: TObject);
begin UpdateScreenBounds; if ScreenshotImage<>nil then UpdateScreenshotBounds; end;
procedure TDPHMainForm.UpdateScreenBounds;
var V: TJSONValue; R: TJSONObject; W,H: Single;
begin
  if FScreen=nil then Exit;
  W:=1; H:=1;
  for V in FScreen.GetValue<TJSONArray>('components') do begin R:=V as TJSONObject;
    W:=Max(W,R.GetValue<Double>('x')+R.GetValue<Double>('width'));
    H:=Max(H,R.GetValue<Double>('y')+R.GetValue<Double>('height'));
  end;
  FScreenScale:=1;
  case ScreenModeCombo.ItemIndex of
    0: FScreenScale:=0.25;
    1,4: FScreenScale:=Min(Max(1,ScreenScroll.Width-24)/W,Max(1,ScreenScroll.Height-24)/H);
    3: FScreenScale:=ScreenZoom.Value/100;
  end;
  FScreenScale:=EnsureRange(FScreenScale,0.001,4.0);
  ScreenZoomLabel.Text:=Format('Zoom %.0f%%',[FScreenScale*100]);
  ScreenPaint.Width:=Max(1,W*FScreenScale); ScreenPaint.Height:=Max(1,H*FScreenScale);
  ScreenPaint.Repaint;
end;
procedure TDPHMainForm.LoadKnowledge(ARows: TJSONArray);
begin FKnowledge.Free; FKnowledge:=ARows; if not FKnowledgeEdited then NewKnowledgeClick(nil); KnowledgeFilterChange(nil); RefreshLearning; RefreshCoverage; RefreshQuestions; end;
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
var Row: TJSONObject; Links: TJSONArray;
begin
  if FKnowledgeEdited then begin StatusLabel.Text:='Save the current authored text before selecting another record'; Exit; end;
  if (KnowledgeList.ItemIndex<0) or (KnowledgeList.ItemIndex>=FKnowledgeRows.Count) then Exit; Row:=FKnowledgeRows[KnowledgeList.ItemIndex];
  FreeAndNil(FTranslations); TranslationList.Items.Clear; TranslationMemo.Text:='';
  TranslationStatus.Text:='Choose Translations and refresh saved records, or select a local DAT pack for this revision.';
  FBinding:=True;
  try
  FKnowledgeID:=StrToInt64(Row.GetValue<string>('id')); FKnowledgeRevision:=StrToInt64(Row.GetValue<string>('revision'));
  KnowledgeTitleEdit.Text:=Row.GetValue<string>('title'); KnowledgeKindCombo.ItemIndex:=KnowledgeKindCombo.Items.IndexOf(Row.GetValue<string>('kind'));
  if KnowledgeKindCombo.ItemIndex<0 then KnowledgeKindCombo.ItemIndex:=0;
  KnowledgeBodyMemo.Text:=Row.GetValue<string>('body');
  FKnowledgeQuestionJSON:=Row.GetValue<string>('question_json','');
  FEditableLinks.Free; if Row.TryGetValue<TJSONArray>('rich_links',Links) then FEditableLinks:=Links.Clone as TJSONArray else FEditableLinks:=TJSONArray.Create;
  RefreshKnowledgeLinks;
  KnowledgeDocumentCombo.ItemIndex:=KnowledgeDocumentCombo.Items.IndexOf(Row.GetValue<string>('document_kind','engineering'));
  KnowledgeAudienceCombo.ItemIndex:=KnowledgeAudienceCombo.Items.IndexOf(Row.GetValue<string>('audience','engineer'));
  KnowledgeSectionLabel.Text:='Section '+Row.GetValue<string>('section_id','')+' | revision '+Row.GetValue<string>('revision');
  KnowledgeHistoryMemo.Text:='Author: '+Row.GetValue<string>('owner')+' | current state: '+Row.GetValue<string>('state')+sLineBreak+
    'Links: '+Row.GetValue<TJSONArray>('links').Format(2)+sLineBreak+'Immutable revision history: '+Row.GetValue<TJSONArray>('history').Format(2);
  if Row.TryGetValue<TJSONArray>('backlinks',Links) then KnowledgeHistoryMemo.Lines.Add('Sections linking to this exact revision: '+Links.Format(2));
  finally FBinding:=False; end;
end;
procedure TDPHMainForm.NewKnowledgeClick(Sender: TObject);
begin
  if (Sender<>nil) and FKnowledgeEdited then begin StatusLabel.Text:='Save the current authored text before starting another record'; Exit; end;
  FreeAndNil(FTranslations); TranslationList.Items.Clear; TranslationMemo.Text:='';
  FBinding:=True; try FKnowledgeID:=0; FKnowledgeRevision:=0; KnowledgeTitleEdit.Text:=''; KnowledgeBodyMemo.Text:='';
    FKnowledgeQuestionJSON:='';
    KnowledgeDocumentCombo.ItemIndex:=0; KnowledgeAudienceCombo.ItemIndex:=0; KnowledgeSectionLabel.Text:='New section: stable ID assigned on Save';
    FreeAndNil(FEditableLinks); FEditableLinks:=TJSONArray.Create; RefreshKnowledgeLinks;
    KnowledgeHistoryMemo.Text:='New content links to the selected canonical object, or the project when no object is selected. Titles and kinds remain stable after creation.';
    FKnowledgeEdited:=False; FKnowledgeLink:=FSelected; finally FBinding:=False; end;
end;
procedure TDPHMainForm.SaveKnowledgeClick(Sender: TObject);
begin Submit('save_knowledge'); end;
procedure TDPHMainForm.RefreshKnowledgeLinks;
var V: TJSONValue;
begin
  KnowledgeLinksList.Items.Clear;
  if FEditableLinks<>nil then for V in FEditableLinks do KnowledgeLinksList.Items.Add(
    V.GetValue<string>('link_role')+' | '+V.GetValue<string>('target_kind')+' | '+V.GetValue<string>('label'));
end;
procedure TDPHMainForm.OpenKnowledgeLinkClick(Sender: TObject);
var Link,Row,Payload,Range,RecordRow,RevisionRow: TJSONObject; V,W: TJSONValue; Kind,Key,Body: string; Index: Integer;
begin
  if (FView=nil) or (KnowledgeLinksList.ItemIndex<0) then Exit;
  Link:=FEditableLinks.Items[KnowledgeLinksList.ItemIndex] as TJSONObject; Kind:=Link.GetValue<string>('target_kind');
  Key:=Link.GetValue<string>('canonical_key','');
  if (Kind='entity') and (Key<>'') and (FView.Symbol(Key)<>nil) then begin SelectSymbol(Key); WorkspaceTabs.ActiveTab:=ExplainTab; Exit; end;
  if (Kind='screenshot') and (FImages<>nil) then begin
    for Index:=0 to FImages.Count-1 do if FImages.Items[Index].GetValue<string>('artifact_hash','')=Link.GetValue<string>('screenshot_hash','unavailable') then begin
      ScreenshotList.ItemIndex:=Index; ScreenshotClick(nil); WorkspaceTabs.ActiveTab:=ScreenshotTab; Exit;
    end;
  end;
  if Kind='section' then begin
    if FKnowledge<>nil then for V in FKnowledge do begin RecordRow:=V as TJSONObject;
      for W in RecordRow.GetValue<TJSONArray>('history') do begin RevisionRow:=W as TJSONObject;
        if RevisionRow.GetValue<Int64>('revision')<>Link.GetValue<Int64>('target_id') then Continue;
        Body:=RecordRow.GetValue<string>('title')+sLineBreak+'Exact revision '+RevisionRow.GetValue<string>('revision')+
          ' | '+RevisionRow.GetValue<string>('verification_state')+' | author '+RevisionRow.GetValue<string>('editor')+sLineBreak+RevisionRow.GetValue<string>('body');
        FreeAndNil(FDetails); FDetails:=TJSONArray.Create; DetailsList.Items.Clear; DetailsMemo.Text:=Body; WorkspaceTabs.ActiveTab:=DetailsTab; Exit;
      end;
    end;
  end;
  if MatchText(Kind,['relationship','evidence']) and (Link.GetValue<string>('source_range','')<>'') then begin
    Range:=TJSONObject.ParseJSONValue(Link.GetValue<string>('source_range')) as TJSONObject;
    if Range=nil then Range:=TJSONObject.Create;
    if Range.GetValue('source')=nil then Range.AddPair('source','');
    if Range.GetValue('start')=nil then Range.AddPair('start',TJSONNumber.Create(0));
    if Range.GetValue('end')=nil then Range.AddPair('end',TJSONNumber.Create(0));
    if Range.GetValue('line')=nil then Range.AddPair('line',TJSONNumber.Create(0));
    if Range.GetValue('column')=nil then Range.AddPair('column',TJSONNumber.Create(0));
    Payload:=TJSONObject.ParseJSONValue(Link.GetValue<string>('evidence_payload','')) as TJSONObject;
    try
      FreeAndNil(FDetails); FDetails:=TJSONArray.Create; Row:=TJSONObject.Create; FDetails.AddElement(Row);
      Row.AddPair('range',Range); Row.AddPair('detail_kind',Kind); Row.AddPair('title',Link.GetValue<string>('label'));
      Row.AddPair('text',Link.GetValue<string>('link_role')+' | '+Link.GetValue<string>('label')+sLineBreak+
        'Target record '+Link.GetValue<string>('target_id')+' | static evidence; not a runtime observation.');
      Row.AddPair('resolution',Link.GetValue<string>('resolution','inferred')); Row.AddPair('object_key',Key);
      Row.AddPair('generation_id',Link.GetValue<string>('source_generation'));
      if Payload<>nil then begin Row.AddPair('rule',Payload.GetValue<string>('rule','captured_evidence')); Row.AddPair('source_hash',Payload.GetValue<string>('source_hash','unavailable')); end
      else Row.AddPair('rule','captured_evidence');
      DetailsList.Items.Clear; DetailsList.Items.Add(Row.GetValue<string>('title')); DetailsList.ItemIndex:=0; DetailsClick(nil); WorkspaceTabs.ActiveTab:=DetailsTab;
    finally Payload.Free; end;
    Exit;
  end;
  StatusLabel.Text:='Save and reload this section to resolve its link evidence, or locate the target in its captured generation.';
end;
procedure TDPHMainForm.KnowledgeLinksClick(Sender: TObject);
var Request: TDPHWorkspaceRequest; Row: TJSONObject; V: TJSONValue; Role: string;
begin
  if Sender=RefreshLinkTargetsButton then begin
    if FBusy or (FView=nil) then Exit;
    Request:=Default(TDPHWorkspaceRequest); Request.Command:='link_candidates'; Request.Database:=FDatabase; Request.Entry:=FEntry;
    Request.GenerationID:=FView.Document.GetValue<Int64>('generation_id'); Request.Kind:=LinkKindCombo.Items[LinkKindCombo.ItemIndex]; Request.Body:=LinkFilterEdit.Text;
    FWorker.Submit(Request); FBusy:=True; StatusLabel.Text:='Finding link targets in the captured generation...'; Exit;
  end;
  if Sender=RemoveKnowledgeLinkButton then begin
    if KnowledgeLinksList.ItemIndex<0 then Exit; FEditableLinks.Remove(KnowledgeLinksList.ItemIndex).Free;
  end else if Sender=AddKnowledgeLinkButton then begin
    if (FLinkTargets=nil) or (LinkTargetsList.ItemIndex<0) then Exit;
    Row:=FLinkTargets.Items[LinkTargetsList.ItemIndex] as TJSONObject; Role:=LinkRoleCombo.Items[LinkRoleCombo.ItemIndex];
    for V in FEditableLinks do if (V.GetValue<string>('target_kind')=Row.GetValue<string>('target_kind')) and
      (V.GetValue<Int64>('target_id')=Row.GetValue<Int64>('target_id')) and (V.GetValue<string>('link_role')=Role) then begin StatusLabel.Text:='That link is already in this section.'; Exit; end;
    if FEditableLinks.Count>=64 then begin StatusLabel.Text:='A section supports up to 64 explicit links.'; Exit; end;
    Row:=Row.Clone as TJSONObject; Row.AddPair('link_role',Role); FEditableLinks.AddElement(Row);
  end else Exit;
  KnowledgeEdited(nil); RefreshKnowledgeLinks; StatusLabel.Text:='Link edit is unsaved. Return to Knowledge and click Save.';
end;
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
