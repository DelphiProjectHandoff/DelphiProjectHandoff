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
    GlossaryTab: TTabItem;
    GlossaryPurpose: TLabel;
    GlossaryToolbar: THorzScrollBox;
    GlossaryFilterEdit: TEdit;
    NewGlossaryButton,EditGlossaryButton,OpenGlossaryKnowledgeButton: TButton;
    GlossaryList: TListBox;
    GlossaryMemo: TMemo;
    GlossarySplitter: TSplitter;
    KeyboardTab: TTabItem;
    KeyboardPurpose,KeyboardStatus: TLabel;
    KeyboardToolbar: THorzScrollBox;
    KeyboardFilterEdit: TEdit;
    KeyboardRefreshButton,KeyboardNextButton,KeyboardSourceButton,KeyboardActionButton: TButton;
    KeyboardList: TListBox;
    KeyboardMemo: TMemo;
    KeyboardSplitter: TSplitter;
    ActionPurposeTab:TTabItem;
    ActionPurposePurpose,ActionPurposeStatus:TLabel;
    ActionPurposeToolbar:THorzScrollBox;
    ActionPurposeFilterEdit:TEdit;
    ActionPurposeStateCombo:TComboBox;
    ActionPurposeFirstButton,ActionPurposeNextButton,ActionPurposeSourceButton,ActionPurposeEditButton,ActionPurposeNewButton,ActionPurposeKnowledgeButton,ActionPurposeExplainButton:TButton;
    ActionPurposeList:TListBox;
    ActionPurposeSplitter:TSplitter;
    ActionPurposeMemo:TMemo;
    InheritanceTab:TTabItem;
    InheritancePurpose,InheritanceStatus:TLabel;
    InheritanceToolbar:THorzScrollBox;
    InheritanceFilterEdit:TEdit;
    InheritanceFirstButton,InheritanceNextButton,InheritanceSourceButton:TButton;
    InheritanceOriginCombo:TComboBox;
    InheritanceList:TListBox;
    InheritanceSplitter:TSplitter;
    InheritanceMemo:TMemo;
    DependencyTab:TTabItem;
    DependencyPurpose,DependencyStatus:TLabel;
    DependencyToolbar:THorzScrollBox;
    DependencyFilterEdit:TEdit;
    DependencyFirstButton,DependencyNextButton,DependencySourceButton,DependencyEditButton,DependencyKnowledgeButton,DependencyClassButton:TButton;
    DependencyList:TListBox;
    DependencySplitter:TSplitter;
    DependencyMemo:TMemo;
    LayoutTab:TTabItem;
    LayoutPurpose,LayoutStatus,LayoutWidthLabel,LayoutHeightLabel:TLabel;
    LayoutToolbar:THorzScrollBox;
    LayoutFilterEdit,LayoutWidthEdit,LayoutHeightEdit:TEdit;
    LayoutFirstButton,LayoutNextButton,LayoutSourceButton,LayoutApplyButton:TButton;
    LayoutList:TListBox;
    LayoutSplitter:TSplitter;
    LayoutMemo:TMemo;
    DynamicTab:TTabItem;
    DynamicPurpose,DynamicStatus:TLabel;
    DynamicToolbar:THorzScrollBox;
    DynamicFilterEdit:TEdit;
    DynamicFirstButton,DynamicNextButton,DynamicExplainButton,DynamicReferenceButton:TButton;
    DynamicReferenceCombo:TComboBox;
    DynamicList:TListBox;
    DynamicSplitter:TSplitter;
    DynamicMemo:TMemo;
    CommandsTab: TTabItem;
    CommandsPurpose,CommandsStatus: TLabel;
    CommandsToolbar: THorzScrollBox;
    CommandsFilterEdit: TEdit;
    CommandsKindCombo,CommandsHandlerCombo: TComboBox;
    CommandsFirstButton,CommandsNextButton,CommandsSourceButton,CommandsActionButton,CommandsHandlerButton: TButton;
    CommandsList: TListBox;
    CommandsMemo: TMemo;
    CommandsSplitter: TSplitter;
    PublishTab: TTabItem;
    PublishToolbar: THorzScrollBox;
    PublishScopeCombo: TComboBox;
    PublishAudienceCombo: TComboBox;
    PublishAgentInstructions: TCheckBox;
    PublishSourceNavigation: TCheckBox;
    PublishLocaleLabel: TLabel;
    PublishLocaleEdit: TEdit;
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
    DatabaseERTab:TTabItem;
    DatabaseERPurpose,DatabaseERStatus,DatabaseEREvidenceLabel:TLabel;
    DatabaseERToolbar:THorzScrollBox;
    DatabaseERFilter:TEdit;
    DatabaseERPageSize,DatabaseERZoom,DatabaseERRelations:TComboBox;
    DatabaseERFirst,DatabaseERNext,DatabaseERAll,DatabaseERFocus,DatabaseEROpen,DatabaseSchemaER,DatabaseDictionaryEdit,DatabaseDictionaryKnowledge:TButton;
    DatabaseERScroll:TScrollBox;
    DatabaseERPaint:TPaintBox;
    DatabaseERMemo:TMemo;
    DatabaseERTableStyle,DatabaseERGapStyle,DatabaseERHeaderStyle:TRectangle;
    DatabaseERTextStyle,DatabaseERTitleStyle:TLabel;
    DataRetentionTab:TTabItem;
    DataRetentionPurpose,DataRetentionStatus,DataRetentionEvidenceLabel:TLabel;
    DataRetentionToolbar:THorzScrollBox;
    DataRetentionFilter:TEdit;
    DataRetentionState:TComboBox;
    DataRetentionFirst,DataRetentionNext,DataRetentionNew,DataRetentionOpen,DataRetentionLinks:TButton;
    DataRetentionList:TListBox;
    DataRetentionMemo:TMemo;
    TargetRecoveryTab:TTabItem;
    TargetRecoveryPurpose,TargetRecoveryStatus,TargetRecoveryEvidenceLabel:TLabel;
    TargetRecoveryToolbar:THorzScrollBox;
    TargetRecoveryFilter:TEdit;
    TargetRecoveryState:TComboBox;
    TargetRecoveryFirst,TargetRecoveryNext,TargetRecoveryNew,TargetRecoveryOpen,TargetRecoveryLinks:TButton;
    TargetRecoveryList:TListBox;
    TargetRecoveryMemo:TMemo;
    BusinessProcessTab:TTabItem;
    BusinessProcessPurpose,BusinessProcessStatus,BusinessProcessEvidenceLabel:TLabel;
    BusinessProcessToolbar:THorzScrollBox;
    BusinessProcessFilter:TEdit;
    BusinessProcessState:TComboBox;
    BusinessProcessFirst,BusinessProcessNext,BusinessProcessNew,BusinessProcessOpen,BusinessProcessLinks:TButton;
    BusinessProcessList:TListBox;
    BusinessProcessMemo:TMemo;
    BusinessRuleTab:TTabItem;
    BusinessRulePurpose,BusinessRuleStatus,BusinessRuleEvidenceLabel:TLabel;
    BusinessRuleToolbar:THorzScrollBox;
    BusinessRuleFilter:TEdit;
    BusinessRuleState:TComboBox;
    BusinessRuleFirst,BusinessRuleNext,BusinessRuleNew,BusinessRuleOpen,BusinessRuleLinks:TButton;
    BusinessRuleList:TListBox;
    BusinessRuleMemo:TMemo;
    BusinessRuleEdit:TButton;
    BusinessRuleEditorTab:TTabItem;
    BusinessRuleEditorPurpose,BusinessRuleAuthorLabel:TLabel;
    BusinessRuleEditorToolbar:THorzScrollBox;
    BusinessRuleAuthor:TEdit;
    BusinessRuleApply,BusinessRuleCancel:TButton;
    BusinessRuleEditorScroll:TVertScrollBox;
    Rule_rule_code_Row:TLayout;Rule_rule_code_Label:TLabel;Rule_rule_code:TMemo;
    Rule_name_Row:TLayout;Rule_name_Label:TLabel;Rule_name:TMemo;
    Rule_scope_Row:TLayout;Rule_scope_Label:TLabel;Rule_scope:TMemo;
    Rule_conditions_Row:TLayout;Rule_conditions_Label:TLabel;Rule_conditions:TMemo;
    Rule_outcomes_Row:TLayout;Rule_outcomes_Label:TLabel;Rule_outcomes:TMemo;
    Rule_exceptions_Row:TLayout;Rule_exceptions_Label:TLabel;Rule_exceptions:TMemo;
    Rule_owner_Row:TLayout;Rule_owner_Label:TLabel;Rule_owner:TMemo;
    Rule_approval_Row:TLayout;Rule_approval_Label:TLabel;Rule_approval:TMemo;
    Rule_unknowns_Row:TLayout;Rule_unknowns_Label:TLabel;Rule_unknowns:TMemo;
    DepartmentalWorkflowTab:TTabItem;
    DepartmentalWorkflowPurpose,DepartmentalWorkflowStatus,DepartmentalWorkflowEvidenceLabel:TLabel;
    DepartmentalWorkflowToolbar:THorzScrollBox;
    DepartmentalWorkflowFilter:TEdit;
    DepartmentalWorkflowState:TComboBox;
    DepartmentalWorkflowFirst,DepartmentalWorkflowNext,DepartmentalWorkflowNew,DepartmentalWorkflowOpen,DepartmentalWorkflowLinks:TButton;
    DepartmentalWorkflowList:TListBox;
    DepartmentalWorkflowMemo:TMemo;
    DepartmentalWorkflowEdit,DepartmentalWorkflowDiagram:TButton;
    WorkflowEditorTab:TTabItem;
    WorkflowEditorPurpose,WorkflowAuthorLabel,WorkflowStepsLabel,WorkflowExceptionLabel:TLabel;
    WorkflowEditorToolbar,WorkflowStepToolbar:THorzScrollBox;
    WorkflowAuthor:TEdit;
    WorkflowApply,WorkflowCancel,WorkflowNewStep,WorkflowSaveStep,WorkflowDiscardStep,WorkflowRemoveStep,WorkflowStepUp,WorkflowStepDown:TButton;
    WorkflowEditorScroll:TVertScrollBox;
    WorkflowSteps:TListBox;
    WorkflowExceptionTarget:TComboBox;
    Workflow_name_Row:TLayout;Workflow_name_Label:TLabel;Workflow_name:TMemo;
    Workflow_owner_Row:TLayout;Workflow_owner_Label:TLabel;Workflow_owner:TMemo;
    Workflow_scope_Row:TLayout;Workflow_scope_Label:TLabel;Workflow_scope:TMemo;
    Workflow_trigger_Row:TLayout;Workflow_trigger_Label:TLabel;Workflow_trigger:TMemo;
    Workflow_unknowns_Row:TLayout;Workflow_unknowns_Label:TLabel;Workflow_unknowns:TMemo;
    Step_step_id_Row:TLayout;Step_step_id_Label:TLabel;Step_step_id:TMemo;
    Step_department_Row:TLayout;Step_department_Label:TLabel;Step_department:TMemo;
    Step_role_Row:TLayout;Step_role_Label:TLabel;Step_role:TMemo;
    Step_action_Row:TLayout;Step_action_Label:TLabel;Step_action:TMemo;
    Step_inputs_Row:TLayout;Step_inputs_Label:TLabel;Step_inputs:TMemo;
    Step_outputs_Row:TLayout;Step_outputs_Label:TLabel;Step_outputs:TMemo;
    Step_handoff_Row:TLayout;Step_handoff_Label:TLabel;Step_handoff:TMemo;
    Step_exception_handling_Row:TLayout;Step_exception_handling_Label:TLabel;Step_exception_handling:TMemo;
    BusinessProcessEdit:TButton;
    BusinessProcessEditorTab:TTabItem;
    BusinessProcessEditorPurpose,BusinessProcessAuthorLabel:TLabel;
    BusinessProcessEditorToolbar:THorzScrollBox;
    BusinessProcessAuthor:TEdit;
    BusinessProcessApply,BusinessProcessCancel:TButton;
    BusinessProcessEditorScroll:TVertScrollBox;
    Process_name_Row:TLayout;
    Process_name_Label:TLabel;
    Process_name:TMemo;
    Process_owner_Row:TLayout;
    Process_owner_Label:TLabel;
    Process_owner:TMemo;
    Process_department_Row:TLayout;
    Process_department_Label:TLabel;
    Process_department:TMemo;
    Process_trigger_Row:TLayout;
    Process_trigger_Label:TLabel;
    Process_trigger:TMemo;
    Process_inputs_Row:TLayout;
    Process_inputs_Label:TLabel;
    Process_inputs:TMemo;
    Process_outputs_Row:TLayout;
    Process_outputs_Label:TLabel;
    Process_outputs:TMemo;
    Process_steps_Row:TLayout;
    Process_steps_Label:TLabel;
    Process_steps:TMemo;
    Process_unknowns_Row:TLayout;
    Process_unknowns_Label:TLabel;
    Process_unknowns:TMemo;
    DataQualityTab:TTabItem;
    DataQualityPurpose,DataQualityStatus,DataQualityEvidenceLabel:TLabel;
    DataQualityToolbar:THorzScrollBox;
    DataQualityFilter:TEdit;
    DataQualityState:TComboBox;
    DataQualityFirst,DataQualityNext,DataQualityNew,DataQualityOpen,DataQualityLinks:TButton;
    DataQualityList:TListBox;
    DataQualityMemo:TMemo;
    DataQualityImport:TButton;
    DataQualityImportToolbar:THorzScrollBox;
    DataQualityContributor,DataQualityContext:TEdit;
    FileFormatsTab:TTabItem;
    FileFormatsPurpose,FileFormatsStatus,FileFormatsEvidenceLabel:TLabel;
    FileFormatsToolbar:THorzScrollBox;
    FileFormatsKind:TComboBox;
    FileFormatsFilter:TEdit;
    FileFormatsFirst,FileFormatsNext,FileFormatsSource,FileFormatsExplain,FileFormatsContract:TButton;
    FileFormatsList:TListBox;
    FileFormatsMemo:TMemo;
    DatabaseSchemaTab:TTabItem;
    DatabaseSchemaPurpose,DatabaseSchemaStatus:TLabel;
    DatabaseSchemaToolbar:THorzScrollBox;
    DatabaseSchemaFilter:TEdit;
    DatabaseSchemaKind,DatabaseSchemaState:TComboBox;
    DatabaseSchemaLinks:TComboBox;
    DatabaseSchemaFollow:TButton;
    DatabaseSchemaFirst,DatabaseSchemaNext,DatabaseSchemaSource:TButton;
    DatabaseSchemaList:TListBox;
    DatabaseSchemaMemo:TMemo;
    DatabaseInventoryTab:TTabItem;
    DatabaseInventoryPurpose,DatabaseInventoryStatus:TLabel;
    DatabaseInventoryToolbar:THorzScrollBox;
    DatabaseInventoryFilter:TEdit;
    DatabaseInventoryKind,DatabaseInventoryLinks:TComboBox;
    DatabaseInventoryFirst,DatabaseInventoryNext,DatabaseInventoryFollow,DatabaseInventorySource,DatabaseInventoryTrace,DatabaseInventoryDiagram:TButton;
    DatabaseInventoryDirection:TComboBox;
    DatabaseInventoryList:TListBox;
    DatabaseInventoryMemo:TMemo;
    HistoryTab:TTabItem;
    HistoryPurpose,HistoryStatus,HistoryBeforeTitle,HistoryAfterTitle,HistoryDifferenceTitle:TLabel;
    HistoryToolbar:THorzScrollBox;
    HistoryBeforeCombo,HistoryAfterCombo,HistoryModeCombo:TComboBox;
    HistoryBeforePath,HistoryAfterPath,HistoryFilter:TEdit;
    HistoryCompareButton,HistorySwapButton,HistoryFirstButton,HistoryNextButton:TButton;
    HistoryBody:TVertScrollBox;
    HistoryContent,HistoryBeforePanel,HistoryAfterPanel,HistoryDifferencePanel:TLayout;
    HistoryGrid:TGridPanelLayout;
    HistoryBeforeImage,HistoryAfterImage,HistoryDifferenceImage:TImage;
    HistoryBeforeBackground,HistoryAfterBackground,HistoryDifferenceBackground,HistoryBeforeLegend,HistoryAfterLegend:TRectangle;
    HistoryBeforePaint,HistoryAfterPaint,HistoryDifferencePaint:TPaintBox;
    HistoryList:TListBox;
    HistoryMemo:TMemo;
    HelpButton: TButton;
    HelpTab: TTabItem;
    HelpBrowser: TWebBrowser;
    HelpFallback: TMemo;
    ProjectsTab: TTabItem;
    ProjectsToolbar: TLayout;
    ProjectsList: TListBox;
    ProjectMembersList: TListBox;
    ProjectMembersPurpose: TLabel;
    ProjectMemberMemo: TMemo;
    ProjectCatalogTabs: TTabControl;
    KnownProjectsTab,ProjectMembersTab: TTabItem;
    ProjectsPurpose: TLabel;
    OpenKnownProjectButton,ForgetProjectButton,RefreshProjectsButton: TButton;
    ProjectProfileButton: TButton;
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
    QualityTab: TTabItem;
    QualityPurpose: TLabel;
    QualityToolbar: THorzScrollBox;
    QualityKindCombo: TComboBox;
    QualityFilterEdit: TEdit;
    QualityRefreshButton,QualityNextButton,QualityOpenButton: TButton;
    QualityList: TListBox;
    QualityMemo: TMemo;
    ComparisonTab: TTabItem;
    ComparisonPurpose,ComparisonStatus,ComparisonBeforeLabel,ComparisonAfterLabel: TLabel;
    ComparisonToolbar: THorzScrollBox;
    ComparisonBaselineEdit,ComparisonFilterEdit: TEdit;
    ComparisonRunButton,ComparisonNextButton: TButton;
    ComparisonList: TListBox;
    ComparisonBeforePanel,ComparisonAfterPanel: TLayout;
    ComparisonBeforeMemo,ComparisonAfterMemo: TMemo;
    ComparisonSplitter: TSplitter;
    procedure KeyboardFilterChange(Sender: TObject);
    procedure ActionPurposeFilterChange(Sender:TObject);
    procedure ActionPurposeSelectionClick(Sender:TObject);
    procedure ActionPurposeSourceClick(Sender:TObject);
    procedure ActionPurposeExplainClick(Sender:TObject);
    procedure ActionPurposeKnowledgeClick(Sender:TObject);
    procedure ActionPurposeEditClick(Sender:TObject);
    procedure InheritanceFilterChange(Sender:TObject);
    procedure InheritanceSelectionClick(Sender:TObject);
    procedure InheritanceOriginChange(Sender:TObject);
    procedure InheritanceSourceClick(Sender:TObject);
    procedure DependencyFilterChange(Sender:TObject);
    procedure DependencySelectionClick(Sender:TObject);
    procedure DependencySourceClick(Sender:TObject);
    procedure DependencyClassClick(Sender:TObject);
    procedure DependencyEditClick(Sender:TObject);
    procedure DependencyKnowledgeClick(Sender:TObject);
    procedure LayoutFilterChange(Sender:TObject);
    procedure LayoutSelectionClick(Sender:TObject);
    procedure LayoutApplyClick(Sender:TObject);
    procedure LayoutSourceClick(Sender:TObject);
    procedure DynamicFilterChange(Sender:TObject);
    procedure DynamicSelectionClick(Sender:TObject);
    procedure DynamicReferenceChange(Sender:TObject);
    procedure DynamicExplainClick(Sender:TObject);
    procedure CommandsFilterChange(Sender: TObject);
    procedure CommandsSelectionClick(Sender: TObject);
    procedure CommandsSourceClick(Sender: TObject);
    procedure CommandsHandlerChange(Sender: TObject);
    procedure CommandsHandlerClick(Sender: TObject);
    procedure KeyboardSelectionClick(Sender: TObject);
    procedure KeyboardSourceClick(Sender: TObject);
    procedure ComparisonClick(Sender: TObject);
    procedure ProjectMemberSelectionClick(Sender: TObject);
    procedure ComparisonSelectionClick(Sender: TObject);
    procedure QualityClick(Sender: TObject);
    procedure QualitySelectionClick(Sender: TObject);
    procedure TranslationClick(Sender: TObject);
    procedure ProjectProfileClick(Sender: TObject);
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
    procedure DatabaseERFilterChange(Sender:TObject);
    procedure DatabaseERFocusClick(Sender:TObject);
    procedure DatabaseERSelectionChange(Sender:TObject);
    procedure DatabaseEROpenClick(Sender:TObject);
    procedure DatabaseERResize(Sender:TObject);
    procedure DatabaseERPaintPaint(Sender:TObject;Canvas:TCanvas);
    procedure DatabaseERMouseDown(Sender:TObject;Button:TMouseButton;Shift:TShiftState;X,Y:Single);
    procedure DatabaseDictionaryEditClick(Sender:TObject);
    procedure DatabaseDictionaryKnowledgeClick(Sender:TObject);
    procedure FileFormatsFilterChange(Sender:TObject);
    procedure FileFormatsSelectionChange(Sender:TObject);
    procedure FileFormatsSourceClick(Sender:TObject);
    procedure FileFormatsExplainClick(Sender:TObject);
    procedure DataRetentionFilterChange(Sender:TObject);
    procedure DataRetentionSelectionChange(Sender:TObject);
    procedure DataRetentionNewClick(Sender:TObject);
    procedure DataRetentionOpenClick(Sender:TObject);
    procedure DataQualityImportClick(Sender:TObject);
    procedure TargetRecoveryFilterChange(Sender:TObject);
    procedure TargetRecoverySelectionChange(Sender:TObject);
    procedure TargetRecoveryNewClick(Sender:TObject);
    procedure TargetRecoveryOpenClick(Sender:TObject);

    procedure BusinessProcessFilterChange(Sender:TObject);
    procedure BusinessProcessSelectionChange(Sender:TObject);
    procedure BusinessProcessNewClick(Sender:TObject);
    procedure BusinessProcessOpenClick(Sender:TObject);

    procedure BusinessRuleFilterChange(Sender:TObject);
    procedure BusinessRuleSelectionChange(Sender:TObject);
    procedure BusinessRuleNewClick(Sender:TObject);
    procedure BusinessRuleOpenClick(Sender:TObject);

    procedure BusinessRuleEditClick(Sender:TObject);
    procedure BusinessRuleApplyClick(Sender:TObject);
    procedure DepartmentalWorkflowFilterChange(Sender:TObject);
    procedure DepartmentalWorkflowSelectionChange(Sender:TObject);
    procedure DepartmentalWorkflowDiagramClick(Sender:TObject);
    procedure DepartmentalWorkflowNewClick(Sender:TObject);
    procedure DepartmentalWorkflowOpenClick(Sender:TObject);

    procedure DepartmentalWorkflowEditClick(Sender:TObject);
    procedure WorkflowApplyClick(Sender:TObject);
    procedure StructuredEditorChange(Sender:TObject);
    procedure WorkflowStepClick(Sender:TObject);
    procedure WorkflowStepChange(Sender:TObject);
    procedure WorkflowStepAction(Sender:TObject);
    procedure RefreshWorkflowSteps;
    procedure BusinessProcessEditClick(Sender:TObject);
    procedure BusinessProcessApplyClick(Sender:TObject);
    procedure DataQualityFilterChange(Sender:TObject);
    procedure DataQualitySelectionChange(Sender:TObject);
    procedure DataQualityNewClick(Sender:TObject);
    procedure DataQualityOpenClick(Sender:TObject);
    procedure FileFormatsContractClick(Sender:TObject);
    procedure DatabaseSchemaFilterChange(Sender:TObject);
    procedure DatabaseSchemaSelectionChange(Sender:TObject);
    procedure DatabaseSchemaSourceClick(Sender:TObject);
    procedure DatabaseSchemaFollowClick(Sender:TObject);
    procedure DatabaseInventoryFilterChange(Sender:TObject);
    procedure DatabaseInventorySelectionChange(Sender:TObject);
    procedure DatabaseInventoryFollowClick(Sender:TObject);
    procedure DatabaseInventoryTraceClick(Sender:TObject);
    procedure DatabaseInventorySourceClick(Sender:TObject);
    procedure HistorySelectionChange(Sender:TObject);
    procedure HistoryCompareClick(Sender:TObject);
    procedure HistoryModeChange(Sender:TObject);
    procedure HistoryFilterChange(Sender:TObject);
    procedure HistoryRowClick(Sender:TObject);
    procedure HistoryPaint(Sender:TObject;Canvas:TCanvas);
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
    procedure GlossaryFilterChange(Sender: TObject);
    procedure GlossaryClick(Sender: TObject);
    procedure EditGlossaryClick(Sender: TObject);
    procedure OpenGlossaryKnowledgeClick(Sender: TObject);
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
    FLineageSeed,FLineageDirection:string;
    FPreviewPages: TList<string>;
    FCoverage: TJSONObject;
    FLinkTargets,FEditableLinks: TJSONArray;
    FReviewTasks: TJSONArray;
    FQuestions: TJSONArray;
    FObservations: TJSONArray;
    FTranslations: TJSONArray;
    FTerminologyJSON: string;
    FKnowledgeQuestionJSON: string;
    FKnowledgeStructuredJSON: string;
    FGlossaryRows: TList<TJSONObject>;
    FQualityRows: TList<TJSONObject>;
    FQualityOffset: Integer;
    FComparison: TJSONObject;
    FDatabaseER:TJSONObject;
    FDatabaseEROffset:Integer;
    FDatabaseERFocusID,FDatabaseEREvidenceID:string;
    FDatabaseERScale:Single;
    FFileFormats:TJSONObject;
    FDataQualityRows:TList<TJSONObject>;
    FDataQualityOffset:Integer;
    FDepartmentalWorkflowRows:TList<TJSONObject>;
    FDepartmentalWorkflowOffset:Integer;
    FWorkflowDraft:TJSONObject;
    FWorkflowStepIndex:Integer;
    FWorkflowStepDirty:Boolean;
    FStructuredEditorPending:Boolean;
    FStructuredEditorID:string;
    FBusinessRuleRows:TList<TJSONObject>;FBusinessRuleOffset:Integer;
    FBusinessProcessRows:TList<TJSONObject>;
    FBusinessProcessOffset:Integer;
    FTargetRecoveryRows:TList<TJSONObject>;
    FTargetRecoveryOffset:Integer;
    FDataRetentionRows:TList<TJSONObject>;
    FDataRetentionOffset:Integer;
    FFileFormatRows:TList<TJSONObject>;
    FFileFormatOffset:Integer;
    FDatabaseSchema:TJSONObject;
    FDatabaseSchemaRows:TList<TJSONObject>;
    FDatabaseSchemaOffset:Integer;
    FDatabaseSchemaTargets:TList<string>;
    FDatabaseInventory:TJSONObject;
    FDatabaseInventoryRows:TList<TJSONObject>;
    FDatabaseInventoryTargets:TList<string>;
    FDatabaseInventoryOffset:Integer;
    FScreenHistory:TJSONObject;
    FScreenToken:Int64;
    FHistoryRows:TList<TJSONObject>;
    FHistoryOffset:Integer;
    FComparisonOffset: Integer;
    FProjectMembers: TJSONArray;
    FKeyboard: TJSONObject;
    FKeyboardRows: TList<TJSONObject>;
    FKeyboardOffset: Integer;
    FActionPurposes:TJSONObject;
    FActionPurposeRows:TList<TJSONObject>;
    FActionPurposeOffset:Integer;
    FInheritance:TJSONObject;
    FInheritanceRows,FInheritanceOrigins:TList<TJSONObject>;
    FInheritanceOffset:Integer;
    FDependencies:TJSONObject;
    FDependencyRows:TList<TJSONObject>;
    FDependencyOffset:Integer;
    FLayout:TJSONObject;
    FLayoutRows:TList<TJSONObject>;
    FLayoutOffset,FLayoutWidthDelta,FLayoutHeightDelta:Integer;
    FDynamic:TJSONObject;
    FDynamicRows:TList<TJSONObject>;
    FDynamicOffset:Integer;
    FCommands: TJSONObject;
    FCommandRows: TList<TJSONObject>;
    FCommandOffset: Integer;
    procedure RefreshQuestions;
    procedure RefreshKnowledgeLinks;
    procedure RefreshCoverage;
    procedure RefreshLearning;
    procedure ShowExplanation;
    procedure Submit(const ACommand: string);
    procedure RefreshExplorer;
    procedure SelectSymbol(const AKey: string; AHistory: Boolean = True);
    function DatabaseERRect(AIndex:Integer):TRectF;
    procedure DatabaseEREvidence(const AID:string);
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
    procedure LoadComparison(AReport: TJSONObject);
    procedure LoadScreenHistory(AReport:TJSONObject;const ABeforePNG,AAfterPNG,ADifferencePNG:TBytes);
    procedure LoadTranslations(ARows: TJSONArray);
    property WorkspaceView: TDPHWorkspaceView read FView;
  end;
var DPHMainForm: TDPHMainForm;
implementation
uses System.IOUtils, System.StrUtils, System.Math, System.Hash, System.Generics.Defaults,
  Winapi.EdgeUtils, DPH.Workspace.Screen, DPH.Workspace.Graphs, DPH.Project.Source, DPH.Parse.Model, DPH.Publish.BrowserPolicy,
  DPH.Knowledge.ProjectProfile, DPH.UI.ProjectProfile, DPH.Workspace.Comparison, DPH.Knowledge.Glossary, DPH.UI.Glossary, DPH.Workspace.Keyboard, DPH.Workspace.Commands, DPH.Workspace.DynamicControls, DPH.Workspace.LayoutRules, DPH.Workspace.ComponentDependencies, DPH.Knowledge.ComponentDependency, DPH.UI.ComponentDependency, DPH.Workspace.FormInheritance, DPH.Knowledge.ActionPurpose, DPH.Workspace.ActionPurposes, DPH.UI.DatabaseDictionary, DPH.UI.ActionPurpose,DPH.Workspace.ScreenHistory,DPH.Workspace.DatabaseConnections,DPH.Workspace.DatabaseSchema;
{$R *.fmx}
procedure TDPHMainForm.FormCreate(Sender: TObject);
var I: Integer; DatabaseDirectory: string;
begin
  FExplorerKeys:=TList<string>.Create; FRelationKeys:=TList<string>.Create; FExpandedKeys:=TList<string>.Create;
  FPreviewPages:=TList<string>.Create;
  FQualityRows:=TList<TJSONObject>.Create;
  FEditableLinks:=TJSONArray.Create;
  FHistory:=TList<string>.Create; FBookmarks:=TList<string>.Create; FDetached:=True;
  FKnowledgeRows:=TList<TJSONObject>.Create;
  FGlossaryRows:=TList<TJSONObject>.Create;
  FKeyboardRows:=TList<TJSONObject>.Create;
  FCommandRows:=TList<TJSONObject>.Create;
  FDynamicRows:=TList<TJSONObject>.Create;
  FActionPurposeRows:=TList<TJSONObject>.Create;
  FHistoryRows:=TList<TJSONObject>.Create;
  FFileFormatRows:=TList<TJSONObject>.Create;FDataRetentionRows:=TList<TJSONObject>.Create;FTargetRecoveryRows:=TList<TJSONObject>.Create;FBusinessProcessRows:=TList<TJSONObject>.Create;FBusinessRuleRows:=TList<TJSONObject>.Create;FDepartmentalWorkflowRows:=TList<TJSONObject>.Create;FDataQualityRows:=TList<TJSONObject>.Create;
  FDatabaseSchemaRows:=TList<TJSONObject>.Create;
  FDatabaseSchemaTargets:=TList<string>.Create;
  FDatabaseInventoryRows:=TList<TJSONObject>.Create;
  FDatabaseInventoryTargets:=TList<string>.Create;
  FInheritanceRows:=TList<TJSONObject>.Create;FInheritanceOrigins:=TList<TJSONObject>.Create;
  FDependencyRows:=TList<TJSONObject>.Create;
  FLayoutRows:=TList<TJSONObject>.Create;
  TryStrToInt(LayoutWidthEdit.Text,FLayoutWidthDelta);TryStrToInt(LayoutHeightEdit.Text,FLayoutHeightDelta);
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
  DataRetentionFilterChange(nil);TargetRecoveryFilterChange(nil);BusinessProcessFilterChange(nil);BusinessRuleFilterChange(nil);DepartmentalWorkflowFilterChange(nil);DataQualityFilterChange(nil);
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
  FKnowledge.Free; FKnowledgeRows.Free; FGlossaryRows.Free;
  FProjectMembers.Free; FComparison.Free; FQualityRows.Free;
  FKeyboardRows.Free; FKeyboard.Free;
  FCommandRows.Free; FCommands.Free;
  FDynamicRows.Free; FDynamic.Free;
  FActionPurposeRows.Free;FActionPurposes.Free;
  FHistoryRows.Free;FScreenHistory.Free;
  FDatabaseER.Free;
  FDataQualityRows.Free;FWorkflowDraft.Free;FDepartmentalWorkflowRows.Free;FBusinessRuleRows.Free;FBusinessProcessRows.Free;FTargetRecoveryRows.Free;FDataRetentionRows.Free;FFileFormatRows.Free;FFileFormats.Free;
  FDatabaseSchemaRows.Free;FDatabaseSchema.Free;
  FDatabaseSchemaTargets.Free;
  FDatabaseInventoryRows.Free;FDatabaseInventoryTargets.Free;FDatabaseInventory.Free;
  FInheritanceRows.Free;FInheritanceOrigins.Free;FInheritance.Free;
  FDependencyRows.Free; FDependencies.Free;
  FLayoutRows.Free; FLayout.Free;
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
procedure TDPHMainForm.ProjectMemberSelectionClick(Sender: TObject);
var Member,Node: TJSONObject; Value: TJSONValue;
begin
  if (FProjectMembers=nil) or (ProjectMembersList.ItemIndex<0) or
    (ProjectMembersList.ItemIndex>=FProjectMembers.Count) then Exit;
  Member:=FProjectMembers.Items[ProjectMembersList.ItemIndex] as TJSONObject;
  ProjectMemberMemo.Lines.BeginUpdate;
  try
    ProjectMemberMemo.Lines.Clear;
    ProjectMemberMemo.Lines.Add(Member.GetValue<string>('name')+' | '+Member.GetValue<string>('kind'));
    ProjectMemberMemo.Lines.Add('Captured path: '+Member.GetValue<string>('path'));
    ProjectMemberMemo.Lines.Add('Generation: '+Member.GetValue('generation_id').Value+' | '+Member.GetValue<string>('availability'));
    ProjectMemberMemo.Lines.Add('SHA256: '+Member.GetValue<string>('source_hash'));
    ProjectMemberMemo.Lines.Add(Member.GetValue<string>('qualification'));
    if Member.TryGetValue<TJSONObject>('declaration',Node) then
      ProjectMemberMemo.Lines.Add('Declaration: '+Node.GetValue<string>('source')+':'+IntToStr(Node.GetValue<Integer>('line')));
    for Value in Member.GetValue<TJSONArray>('settings_and_references') do begin
      Node:=Value as TJSONObject;
      ProjectMemberMemo.Lines.Add(Node.GetValue<string>('name')+' = '+Node.GetValue<string>('value'));
      ProjectMemberMemo.Lines.Add('  Evidence: '+Node.GetValue<string>('source')+':'+IntToStr(Node.GetValue<Integer>('line'))+
        ' | recorded child condition: '+Node.GetValue<string>('condition'));
    end;
  finally ProjectMemberMemo.Lines.EndUpdate; end;
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
      R.StructuredJSON:=FKnowledgeStructuredJSON;
  end;
  if ACommand='publish' then
  begin
    if FView=nil then begin StatusLabel.Text:='Open or analyze a project first'; Exit; end;
    R.GenerationID:=FView.Document.GetValue<Int64>('generation_id'); R.ExportDirectory:=FExportDirectory;
    R.Exclusions:=PublishExclusionsEdit.Text.Split([';'],TStringSplitOptions.ExcludeEmpty);
    R.Audience:='all'; if PublishAudienceCombo.ItemIndex>=0 then R.Audience:=PublishAudienceCombo.Items[PublishAudienceCombo.ItemIndex];
    R.IncludeAgentInstructions:=PublishAgentInstructions.IsChecked;
    R.IncludeSourceNavigation:=PublishSourceNavigation.IsChecked;
    R.PublicationLocale:=Trim(PublishLocaleEdit.Text);
    if PublishScopeCombo.ItemIndex=1 then begin if FSelected='' then begin StatusLabel.Text:='Select an object for a task bundle'; Exit; end; R.Seeds:=[FSelected]; end else R.Seeds:=[];
  end;
  FWorker.Submit(R); FBusy:=True; StatusLabel.Text:='Working in background...';
    FPendingCommand:=ACommand; if ACommand='save_knowledge' then FSavedKnowledgeText:=KnowledgeTitleEdit.Text+#0+KnowledgeBodyMemo.Text+#0+IntToStr(KnowledgeDocumentCombo.ItemIndex)+#0+IntToStr(KnowledgeAudienceCombo.ItemIndex)+#0+FEditableLinks.ToJSON+#0+FKnowledgeQuestionJSON+#0+FKnowledgeStructuredJSON;
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
  FFileFormatRows.Clear;FreeAndNil(FFileFormats);FileFormatsFilterChange(nil);
  FDatabaseSchemaRows.Clear;FreeAndNil(FDatabaseSchema);DatabaseSchemaFilterChange(nil);FDatabaseERFocusID:='';FDatabaseEREvidenceID:='';DatabaseERFilterChange(nil);
  FDatabaseInventoryRows.Clear;FreeAndNil(FDatabaseInventory);DatabaseInventoryFilterChange(nil);
 HistorySelectionChange(nil);HistoryBeforeCombo.Items.Clear;HistoryAfterCombo.Items.Clear;
 FActionPurposeRows.Clear;FreeAndNil(FActionPurposes);ActionPurposeList.Items.Clear;ActionPurposeMemo.Text:='Open a project to map user actions and business purposes.';ActionPurposeStatus.Text:='No capture loaded.';ActionPurposeNextButton.Enabled:=False;ActionPurposeSourceButton.Enabled:=False;ActionPurposeEditButton.Enabled:=False;ActionPurposeNewButton.Enabled:=False;ActionPurposeKnowledgeButton.Enabled:=False;ActionPurposeExplainButton.Enabled:=False;
 FInheritanceRows.Clear;FInheritanceOrigins.Clear;FreeAndNil(FInheritance);InheritanceList.Items.Clear;InheritanceOriginCombo.Items.Clear;InheritanceMemo.Text:='Open a project to inspect inherited forms and frames.';InheritanceStatus.Text:='No capture loaded.';InheritanceNextButton.Enabled:=False;InheritanceSourceButton.Enabled:=False;
 FDependencyRows.Clear;FreeAndNil(FDependencies);DependencyList.Items.Clear;DependencyMemo.Text:='Open a project to inspect component dependencies.';DependencyStatus.Text:='No capture loaded.';
 DependencyNextButton.Enabled:=False;DependencySourceButton.Enabled:=False;DependencyEditButton.Enabled:=False;DependencyKnowledgeButton.Enabled:=False;DependencyClassButton.Enabled:=False;
 FLayoutRows.Clear;FreeAndNil(FLayout);LayoutList.Items.Clear;LayoutMemo.Text:='Open a project to inspect layout declarations.';LayoutStatus.Text:='No capture loaded.';
 LayoutNextButton.Enabled:=False;LayoutSourceButton.Enabled:=False;
  FDynamicRows.Clear; FreeAndNil(FDynamic); DynamicList.Items.Clear; DynamicReferenceCombo.Items.Clear;
  DynamicMemo.Text:='Open a project to inspect creation sites.'; DynamicStatus.Text:='No capture loaded.';
  DynamicNextButton.Enabled:=False; DynamicExplainButton.Enabled:=False; DynamicReferenceButton.Enabled:=False;
  FCommandRows.Clear; FreeAndNil(FCommands); CommandsList.Items.Clear; CommandsHandlerCombo.Items.Clear;
  CommandsMemo.Text:='Open a captured project to inspect its commands.'; CommandsStatus.Text:='No capture loaded.';
  CommandsNextButton.Enabled:=False; CommandsSourceButton.Enabled:=False; CommandsActionButton.Enabled:=False; CommandsHandlerButton.Enabled:=False;
  FKeyboardRows.Clear; FreeAndNil(FKeyboard); KeyboardList.Items.Clear;
  KeyboardMemo.Text:='Open a project capture to inspect keyboard declarations.'; KeyboardNextButton.Enabled:=False;
  KeyboardStatus.Text:='No capture loaded.';
  FGlossaryRows.Clear; GlossaryList.Items.Clear; GlossaryMemo.Text:='Open a selected project, then add its business terms.';
  FreeAndNil(FProjectMembers); ProjectMembersList.Items.Clear; ProjectMemberMemo.Text:='Open a captured project to inspect its project and output declarations.';
  FreeAndNil(FComparison); ComparisonList.Items.Clear; ComparisonBeforeMemo.Text:=''; ComparisonAfterMemo.Text:='';
  ComparisonStatus.Text:='No comparison loaded.'; ComparisonNextButton.Enabled:=False;
  FQualityRows.Clear; QualityList.Items.Clear; QualityMemo.Text:='Open a captured project to inspect source quality candidates.';
  FreeAndNil(FExplanations); FreeAndNil(FLearningFacts); LearningBrowser.Visible:=False; ExplainBrowser.Visible:=False; FlowBrowser.Visible:=False;
  FreeAndNil(FImages); ScreenshotList.Items.Clear; ScreenshotImage.Bitmap.Clear(TAlphaColors.Null); ScreenshotEvidence.Text:='No imported screenshot is selected.';
  FreeAndNil(FView); FreeAndNil(FGraph); FreeAndNil(FScreen); FreeAndNil(FKnowledge);
  FreeAndNil(FCoverage); CoverageList.Items.Clear; CoverageMemo.Text:='Open a captured project to see coverage and gaps.';
  FreeAndNil(FContinuity); ContinuityList.Items.Clear; ContinuityMemo.Text:='';
  FreeAndNil(FReviewTasks); ReviewTasksList.Items.Clear; ReviewBeforeMemo.Text:=''; ReviewAfterMemo.Text:='';
  FreeAndNil(FQuestions); QuestionsList.Items.Clear; QuestionMemo.Text:=''; FKnowledgeQuestionJSON:='';
  FreeAndNil(FObservations); ObservationsList.Items.Clear; ObservationMemo.Text:='Open Runtime observations and click Refresh saved records.';
  FreeAndNil(FWorkflowDraft);FWorkflowStepDirty:=False;
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
  DataRetentionFilterChange(nil);TargetRecoveryFilterChange(nil);BusinessProcessFilterChange(nil);BusinessRuleFilterChange(nil);DepartmentalWorkflowFilterChange(nil);DataQualityFilterChange(nil);NewKnowledgeClick(nil); FExportDirectory:=''; PreviewButton.Enabled:=False;
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
    if R.Failed and (FPendingCommand='screen_history') then begin HistorySelectionChange(nil);HistoryStatus.Text:='Comparison failed; read details below.';HistoryMemo.Text:=R.MessageText;end;
    if R.Failed and (FPendingCommand='validate_bundle') then ValidationMemo.Text:='FAILED: '+R.MessageText+sLineBreak+'The bundle has not passed validation. Correct the reported mismatch before using it.';
    if R.Failed then begin
      FPendingEntry:=''; FPendingDatabase:='';
      if FView=nil then HelpClick(nil);
    end;
    if R.Knowledge<>nil then begin
      if (FPendingCommand='save_knowledge') and (FSavedKnowledgeText=KnowledgeTitleEdit.Text+#0+KnowledgeBodyMemo.Text+#0+IntToStr(KnowledgeDocumentCombo.ItemIndex)+#0+IntToStr(KnowledgeAudienceCombo.ItemIndex)+#0+FEditableLinks.ToJSON+#0+FKnowledgeQuestionJSON+#0+FKnowledgeStructuredJSON) then FKnowledgeEdited:=False;
      LoadKnowledge(R.Knowledge); R.Knowledge:=nil; end;
    if (R.Comparison<>nil) and (FView<>nil) and (R.SearchGeneration=FView.Document.GetValue<Int64>('generation_id')) then begin LoadComparison(R.Comparison); R.Comparison:=nil; end;
    if (R.ReviewTasks<>nil) and (FView<>nil) and (R.SearchGeneration=FView.Document.GetValue<Int64>('generation_id')) then begin LoadReviewTasks(R.ReviewTasks); R.ReviewTasks:=nil; end;
    if not R.Busy and not R.Failed and (FPendingCommand='review_knowledge') and (FReviewTasks<>nil) then ReviewTasksClick(RefreshReviewTasksButton);
    if R.Screenshots<>nil then begin LoadScreenshots(R.Screenshots); R.Screenshots:=nil; end;
    if (R.ScreenHistory<>nil) and (R.ScreenToken=FScreenToken) and SameText(R.ScreenDatabase,FDatabase) then begin LoadScreenHistory(R.ScreenHistory,R.BeforePNG,R.AfterPNG,R.DifferencePNG);R.ScreenHistory:=nil;end;
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
  FLineageSeed:=''; FLineageDirection:='both';
  HistorySelectionChange(nil);
  SameProject:=(FView<>nil) and SameText(FView.Document.GetValue<string>('root'),ADocument.GetValue<string>('root')) and
    SameText(FView.Document.GetValue<string>('entry'),ADocument.GetValue<string>('entry'));
  SavedKey:=''; SavedForm:=''; SavedTab:=WorkspaceTabs.ActiveTab;
  FreeAndNil(FComparison); ComparisonList.Items.Clear; ComparisonBeforeMemo.Text:=''; ComparisonAfterMemo.Text:='';
  ComparisonNextButton.Enabled:=False; ComparisonStatus.Text:='Compare two retained captures; the displayed project supplies the After generation.';
  FreeAndNil(FReviewTasks); ReviewTasksList.Items.Clear; ReviewBeforeMemo.Text:='Refresh tasks for this captured generation.'; ReviewAfterMemo.Text:='';
  FreeAndNil(FLinkTargets); LinkTargetsList.Items.Clear;
  if SameProject then begin SavedKey:=FSelected; if FormCombo.ItemIndex>=0 then SavedForm:=FormCombo.Items[FormCombo.ItemIndex]; end;
  FreeAndNil(FSearchResults); ProjectSearchList.Items.Clear; ProjectSearchMemo.Text:='Search the current analysis generation and authored knowledge.';
  FreeAndNil(FObservations); ObservationsList.Items.Clear; ObservationMemo.Text:='Click Refresh saved records to read attributed observations for this database.';
  FSearchOffset:=0; NextProjectSearchButton.Enabled:=False;
  FQualityRows.Clear; QualityList.Items.Clear;
  FreeAndNil(FView); FView:=TDPHWorkspaceView.Create(ADocument); FSelected:='';
  FDatabaseSchemaRows.Clear;FreeAndNil(FDatabaseSchema);FDatabaseSchema:=TDPHDatabaseSchema.Inspect(FView);
  FFileFormatRows.Clear;FreeAndNil(FFileFormats);FFileFormats:=FView.FileFormats;FileFormatsFilterChange(nil);DatabaseSchemaFilterChange(nil);FDatabaseERFocusID:='';FDatabaseEREvidenceID:='';DatabaseERFilterChange(nil);
  FDatabaseInventoryRows.Clear;FreeAndNil(FDatabaseInventory);FDatabaseInventory:=TDPHDatabaseConnections.Inspect(FView);DatabaseInventoryFilterChange(nil);
  FKeyboardRows.Clear; FreeAndNil(FKeyboard); FKeyboard:=TDPHKeyboardInspector.Inspect(FView); KeyboardFilterChange(nil);
  FCommandRows.Clear; FreeAndNil(FCommands); FCommands:=TDPHCommandInventory.Inspect(FView,FKeyboard); CommandsFilterChange(nil);
  FActionPurposeRows.Clear;FreeAndNil(FActionPurposes);FActionPurposes:=TDPHActionPurposes.Inspect(FView,FKeyboard,FKnowledge);ActionPurposeFilterChange(nil);
  FInheritanceRows.Clear;FInheritanceOrigins.Clear;FreeAndNil(FInheritance);FInheritance:=TDPHFormInheritance.Inspect(FView);InheritanceFilterChange(nil);
  FDependencyRows.Clear;FreeAndNil(FDependencies);FDependencies:=TDPHComponentDependencies.Inspect(FView,FKeyboard);DependencyFilterChange(nil);
  FLayoutRows.Clear;FreeAndNil(FLayout);FLayout:=TDPHLayoutRules.Inspect(FKeyboard);LayoutFilterChange(nil);
  FDynamicRows.Clear; FreeAndNil(FDynamic); FDynamic:=TDPHDynamicControls.Inspect(FView); DynamicFilterChange(nil);
  FreeAndNil(FProjectMembers); FProjectMembers:=FView.ProjectMembers; ProjectMembersList.Items.Clear;
  for V in FProjectMembers do ProjectMembersList.Items.Add(V.GetValue<string>('kind')+' | '+V.GetValue<string>('name')+' | '+V.GetValue<string>('path')+' | '+V.GetValue<string>('availability'));
  ProjectMemberMemo.Text:='Select a captured project or output declaration above to read its settings and evidence.';
  if ProjectMembersList.Count>0 then begin ProjectMembersList.ItemIndex:=0; ProjectMemberSelectionClick(nil); end;
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
  RefreshExplorer; RefreshLearning; RefreshCoverage; RefreshQuestions; QualityClick(nil);
  if SavedKey<>'' then begin SelectSymbol(SavedKey,False); ExplorerList.ItemIndex:=FExplorerKeys.IndexOf(SavedKey); end;
  if SameProject then WorkspaceTabs.ActiveTab:=SavedTab;
end;
procedure TDPHMainForm.KeyboardFilterChange(Sender: TObject);
var Value: TJSONValue; Row: TJSONObject; Count,Order: Integer; Text,Query: string;
begin
  if Sender=KeyboardNextButton then Inc(FKeyboardOffset,250) else FKeyboardOffset:=0;
  KeyboardList.Items.Clear; FKeyboardRows.Clear; KeyboardNextButton.Enabled:=False;
  KeyboardActionButton.Enabled:=False; KeyboardSourceButton.Enabled:=False;
  KeyboardMemo.Text:='Select a component to see its keyboard declarations, source evidence and diagnostics.';
  if FKeyboard=nil then Exit;
  Count:=0; Query:=KeyboardFilterEdit.Text.Trim;
  for Value in FKeyboard.GetValue<TJSONArray>('rows') do begin
    Row:=Value as TJSONObject;
    if (Query<>'') and not ContainsText(TDPHKeyboardInspector.Describe(Row),Query) then Continue;
    if (Count>=FKeyboardOffset) and (FKeyboardRows.Count<250) then begin
      FKeyboardRows.Add(Row); Order:=Row.GetValue<Integer>('tab_order'); Text:='?'; if Order<>MaxInt then Text:=IntToStr(Order);
      KeyboardList.Items.Add(Row.GetValue<string>('source')+' | '+Row.GetValue<string>('parent')+' | Tab '+Text+' | '+
        Row.GetValue<string>('name')+' | ShortCut '+Row.GetValue<string>('shortcut','')+' | Action '+Row.GetValue<string>('action',''));
    end;
    Inc(Count);
  end;
  KeyboardNextButton.Enabled:=Count>FKeyboardOffset+FKeyboardRows.Count;
  KeyboardStatus.Text:=IntToStr(Count)+' matching components; showing '+IntToStr(FKeyboardRows.Count)+' from offset '+IntToStr(FKeyboardOffset)+'. Grouped by file, form and parent; known TabOrder first.';
  if KeyboardList.Count>0 then begin KeyboardSourceButton.Enabled:=True; KeyboardList.ItemIndex:=0; KeyboardSelectionClick(nil); end
  else KeyboardMemo.Text:='No matching captured component. Clear the filter or inspect Coverage for missing form inputs.';
end;

procedure TDPHMainForm.KeyboardSelectionClick(Sender: TObject);
var Row: TJSONObject;
begin
  KeyboardActionButton.Enabled:=False;
  if (KeyboardList.ItemIndex<0) or (KeyboardList.ItemIndex>=FKeyboardRows.Count) then Exit;
  Row:=FKeyboardRows[KeyboardList.ItemIndex];
  KeyboardMemo.Text:=TDPHKeyboardInspector.Describe(Row)+sLineBreak+sLineBreak+FKeyboard.GetValue<string>('qualification');
  KeyboardActionButton.Enabled:=Row.GetValue('action_range')<>nil;
end;

procedure TDPHMainForm.KeyboardSourceClick(Sender: TObject);
var Row,Range: TJSONObject;
begin
  if (FView=nil) or (KeyboardList.ItemIndex<0) or (KeyboardList.ItemIndex>=FKeyboardRows.Count) then Exit;
  Row:=FKeyboardRows[KeyboardList.ItemIndex];
  if Sender=KeyboardActionButton then begin if not Row.TryGetValue<TJSONObject>('action_range',Range) then Exit; end
  else Range:=Row.GetValue<TJSONObject>('range');
  if FDetached then begin KeyboardMemo.Lines.Add('Source is detached. Captured locations and properties remain readable above. Attach the unchanged project to navigate.'); Exit; end;
  try
    SourceMemo.Text:=TDPHKeyboardInspector.ReadSource(FView,FEntry,Row,Range);
    SourceMemo.CaretPosition:=TCaretPosition.Create(Max(0,Range.GetValue<Integer>('line')-1),Max(0,Range.GetValue<Integer>('column')-1));
    WorkspaceTabs.ActiveTab:=SourceTab;
  except on E: Exception do KeyboardMemo.Lines.Add('Source unavailable: '+E.Message); end;
end;
procedure TDPHMainForm.ActionPurposeFilterChange(Sender:TObject);
var V:TJSONValue;Row:TJSONObject;Count:Integer;Query,StateFilter:string;
begin
 if FActionPurposeRows=nil then Exit;
 if Sender=ActionPurposeNextButton then Inc(FActionPurposeOffset,250) else FActionPurposeOffset:=0;
 ActionPurposeList.Items.Clear;FActionPurposeRows.Clear;ActionPurposeNextButton.Enabled:=False;ActionPurposeSourceButton.Enabled:=False;ActionPurposeEditButton.Enabled:=False;ActionPurposeKnowledgeButton.Enabled:=False;ActionPurposeExplainButton.Enabled:=False;ActionPurposeNewButton.Enabled:=FView<>nil;
 ActionPurposeMemo.Text:='Select a captured UI candidate or saved project task. Missing business purpose stays unknown.';if FActionPurposes=nil then Exit;
 Query:=ActionPurposeFilterEdit.Text.Trim;StateFilter:='';if ActionPurposeStateCombo.ItemIndex>0 then StateFilter:=ActionPurposeStateCombo.Selected.Text;Count:=0;
 for V in FActionPurposes.GetValue<TJSONArray>('rows') do begin Row:=V as TJSONObject;
  if (StateFilter<>'') and (StateFilter<>TDPHActionPurposes.State(Row,FKnowledge)) then Continue;
  if (Query<>'') and not ContainsText(TDPHActionPurposes.Describe(Row,FKnowledge),Query) then Continue;
  if (Count>=FActionPurposeOffset) and (FActionPurposeRows.Count<250) then begin FActionPurposeRows.Add(Row);ActionPurposeList.Items.Add(Row.GetValue<string>('target')+' | '+Row.GetValue<string>('name')+' | '+TDPHActionPurposes.State(Row,FKnowledge));end;Inc(Count);
 end;
 ActionPurposeNextButton.Enabled:=Count>FActionPurposeOffset+FActionPurposeRows.Count;
 ActionPurposeStatus.Text:=IntToStr(Count)+' matches; '+IntToStr(FActionPurposeRows.Count)+' shown from '+IntToStr(FActionPurposeOffset)+'. Select a row for evidence and review state.';
 if ActionPurposeList.Count>0 then begin ActionPurposeList.ItemIndex:=0;ActionPurposeSelectionClick(nil);end else ActionPurposeMemo.Text:='No matching actions or tasks. Clear filters or click New task for a project procedure.';
end;
procedure TDPHMainForm.ActionPurposeSelectionClick(Sender:TObject);
var Row:TJSONObject;
begin
 ActionPurposeSourceButton.Enabled:=False;ActionPurposeEditButton.Enabled:=False;ActionPurposeKnowledgeButton.Enabled:=False;ActionPurposeExplainButton.Enabled:=False;
 if (ActionPurposeList.ItemIndex<0) or (ActionPurposeList.ItemIndex>=FActionPurposeRows.Count) then Exit;
 Row:=FActionPurposeRows[ActionPurposeList.ItemIndex];ActionPurposeMemo.Text:=TDPHActionPurposes.Describe(Row,FKnowledge)+sLineBreak+sLineBreak+FActionPurposes.GetValue<string>('qualification');
 ActionPurposeEditButton.Enabled:=not Row.GetValue<Boolean>('ambiguous_target',False);ActionPurposeSourceButton.Enabled:=not Row.GetValue<Boolean>('record_only');
 ActionPurposeKnowledgeButton.Enabled:=TDPHActionPurposes.FindRecord(FKnowledge,Row.GetValue<string>('action_id'))<>nil;
 ActionPurposeExplainButton.Enabled:=not Row.GetValue<Boolean>('ambiguous_target',False) and not Row.GetValue<Boolean>('record_only') and (Row.GetValue<string>('target_key','')<>'');
end;
procedure TDPHMainForm.ActionPurposeSourceClick(Sender:TObject);
var Row,Range:TJSONObject;
begin
 if (FView=nil) or (ActionPurposeList.ItemIndex<0) or (ActionPurposeList.ItemIndex>=FActionPurposeRows.Count) then Exit;
 Row:=FActionPurposeRows[ActionPurposeList.ItemIndex];if Row.GetValue<Boolean>('record_only') then Exit;
 if FDetached then begin ActionPurposeMemo.Lines.Add('Source is detached. Attach unchanged source to navigate.');Exit;end;
 Range:=Row.GetValue<TJSONObject>('range');
 try SourceMemo.Text:=TDPHKeyboardInspector.ReadSource(FView,FEntry,Row,Range);SourceMemo.CaretPosition:=TCaretPosition.Create(Max(0,Range.GetValue<Integer>('line')-1),Max(0,Range.GetValue<Integer>('column')-1));WorkspaceTabs.ActiveTab:=SourceTab;
 except on E:Exception do ActionPurposeMemo.Lines.Add('Source unavailable: '+E.Message);end;
end;
procedure TDPHMainForm.ActionPurposeExplainClick(Sender:TObject);
var Row:TJSONObject;
begin
 if (FView=nil) or (ActionPurposeList.ItemIndex<0) or (ActionPurposeList.ItemIndex>=FActionPurposeRows.Count) then Exit;
 Row:=FActionPurposeRows[ActionPurposeList.ItemIndex];if Row.GetValue<Boolean>('ambiguous_target',False) or Row.GetValue<Boolean>('record_only') or (Row.GetValue<string>('target_key','')='') then Exit;
 SelectSymbol(Row.GetValue<string>('target_key'));WorkspaceTabs.ActiveTab:=ExplainTab;
end;
procedure TDPHMainForm.ActionPurposeKnowledgeClick(Sender:TObject);
var Row:TJSONObject;I:Integer;
begin
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft first';Exit;end;
 if (ActionPurposeList.ItemIndex<0) or (ActionPurposeList.ItemIndex>=FActionPurposeRows.Count) then Exit;
 Row:=TDPHActionPurposes.FindRecord(FKnowledge,FActionPurposeRows[ActionPurposeList.ItemIndex].GetValue<string>('action_id'));if Row=nil then Exit;
 PendingKnowledgeCheck.IsChecked:=False;KnowledgeFilterChange(nil);
 for I:=0 to FKnowledgeRows.Count-1 do if FKnowledgeRows[I].GetValue<string>('id')=Row.GetValue<string>('id') then begin KnowledgeList.ItemIndex:=I;KnowledgeClick(nil);WorkspaceTabs.ActiveTab:=KnowledgeTab;Exit;end;
end;
procedure TDPHMainForm.ActionPurposeEditClick(Sender:TObject);
var Editor:TDPHActionPurposeForm;Row,ComponentRow,RecordValue,Initial,Fields:TJSONObject;Links:TJSONArray;
begin
 if FBusy or (FView=nil) then Exit;
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft first';Exit;end;
 Row:=nil;
 if Sender=ActionPurposeNewButton then Initial:=TJSONObject.Create.AddPair('record_type','action_purpose').AddPair('fields',TJSONObject.Create.AddPair('action_id','task:'+TGUID.NewGuid.ToString).AddPair('target','Project task').AddPair('target_key',''))
 else begin
  if (ActionPurposeList.ItemIndex<0) or (ActionPurposeList.ItemIndex>=FActionPurposeRows.Count) then Exit;
  ComponentRow:=FActionPurposeRows[ActionPurposeList.ItemIndex];if ComponentRow.GetValue<Boolean>('ambiguous_target',False) then Exit;Row:=TDPHActionPurposes.FindRecord(FKnowledge,ComponentRow.GetValue<string>('action_id'));
  if Row<>nil then Row:=Row.Clone as TJSONObject;
  if Row<>nil then Initial:=TJSONObject.ParseJSONValue(Row.GetValue<string>('structured_json')) as TJSONObject
  else Initial:=TJSONObject.Create.AddPair('record_type','action_purpose').AddPair('fields',TJSONObject.Create.AddPair('action_id',ComponentRow.GetValue<string>('action_id')).AddPair('target',ComponentRow.GetValue<string>('target')).AddPair('target_key',ComponentRow.GetValue<string>('target_key','')).AddPair('screen',ComponentRow.GetValue<string>('form')));
 end;
 Editor:=TDPHActionPurposeForm.Create(nil);
 try
  Editor.LoadRecord(Initial,KnowledgeAuthorEdit.Text);if Editor.ShowModal<>mrOk then Exit;RecordValue:=Editor.RecordJSON;
  try
   Fields:=RecordValue.GetValue<TJSONObject>('fields');FBinding:=True;
   try
    FKnowledgeID:=0;FKnowledgeRevision:=0;if Row<>nil then begin FKnowledgeID:=StrToInt64(Row.GetValue<string>('id'));FKnowledgeRevision:=StrToInt64(Row.GetValue<string>('revision'));end;
    KnowledgeTitleEdit.Text:=TDPHActionPurpose.Title(RecordValue);KnowledgeAuthorEdit.Text:=Editor.ProfileAuthorEdit.Text;
    KnowledgeKindCombo.ItemIndex:=KnowledgeKindCombo.Items.IndexOf('user_help');KnowledgeDocumentCombo.ItemIndex:=KnowledgeDocumentCombo.Items.IndexOf('user');KnowledgeAudienceCombo.ItemIndex:=KnowledgeAudienceCombo.Items.IndexOf('user');
    KnowledgeBodyMemo.Text:=TDPHActionPurpose.Body(RecordValue);KnowledgeBodyMemo.ReadOnly:=True;KnowledgeTitleEdit.ReadOnly:=True;KnowledgeKindCombo.Enabled:=False;KnowledgeDocumentCombo.Enabled:=False;KnowledgeAudienceCombo.Enabled:=False;
    FKnowledgeStructuredJSON:=RecordValue.ToJSON;FKnowledgeQuestionJSON:='';FKnowledgeLink:=Fields.GetValue<string>('target_key','');FreeAndNil(FEditableLinks);
    if (Row<>nil) and Row.TryGetValue<TJSONArray>('rich_links',Links) then FEditableLinks:=Links.Clone as TJSONArray else FEditableLinks:=TJSONArray.Create;
    RefreshKnowledgeLinks;FKnowledgeEdited:=True;KnowledgeSectionLabel.Text:='Action purpose draft: click Save, then review explicitly';KnowledgeHistoryMemo.Text:='Edit structured fields on Action purposes. Add exact evidence on Knowledge links. Saving does not verify business claims or actual outcomes.';
   finally FBinding:=False;end;
   WorkspaceTabs.ActiveTab:=KnowledgeTab;StatusLabel.Text:='Action purpose draft prepared. Click Save to persist; review requires a named reviewer.';
  finally RecordValue.Free;end;
 finally Editor.Free;Initial.Free;Row.Free;end;
end;
procedure TDPHMainForm.InheritanceFilterChange(Sender:TObject);
var V:TJSONValue;Row:TJSONObject;Count:Integer;Query:string;
begin
 if FInheritanceRows=nil then Exit;
 if Sender=InheritanceNextButton then Inc(FInheritanceOffset,250) else FInheritanceOffset:=0;
 InheritanceList.Items.Clear;FInheritanceRows.Clear;FInheritanceOrigins.Clear;InheritanceOriginCombo.Items.Clear;
 InheritanceNextButton.Enabled:=False;InheritanceSourceButton.Enabled:=False;
 InheritanceMemo.Text:='Select a component to inspect base-to-derived property and event declarations.';
 if FInheritance=nil then Exit;Query:=InheritanceFilterEdit.Text.Trim;Count:=0;
 for V in FInheritance.GetValue<TJSONArray>('rows') do begin Row:=V as TJSONObject;
  if (Query<>'') and not ContainsText(TDPHFormInheritance.Describe(Row),Query) then Continue;
  if (Count>=FInheritanceOffset) and (FInheritanceRows.Count<250) then begin FInheritanceRows.Add(Row);InheritanceList.Items.Add(Row.GetValue<string>('form_source')+' | '+Row.GetValue<string>('component_path')+' : '+Row.GetValue<string>('class'));end;Inc(Count);
 end;
 InheritanceNextButton.Enabled:=Count>FInheritanceOffset+FInheritanceRows.Count;
 InheritanceStatus.Text:=IntToStr(Count)+' matching components; showing '+IntToStr(FInheritanceRows.Count)+' from offset '+IntToStr(FInheritanceOffset)+'. Select an origin to inspect its exact source.';
 if InheritanceList.Count>0 then begin InheritanceList.ItemIndex:=0;InheritanceSelectionClick(nil);end else InheritanceMemo.Text:='No matching components. Clear the filter or inspect Coverage for missing form source.';
end;
procedure TDPHMainForm.InheritanceSelectionClick(Sender:TObject);
var Row,P:TJSONObject;V,W:TJSONValue;
begin
 FInheritanceOrigins.Clear;InheritanceOriginCombo.Items.Clear;InheritanceSourceButton.Enabled:=False;
 if (InheritanceList.ItemIndex<0) or (InheritanceList.ItemIndex>=FInheritanceRows.Count) then Exit;
 Row:=FInheritanceRows[InheritanceList.ItemIndex];InheritanceMemo.Text:=TDPHFormInheritance.Describe(Row)+sLineBreak+sLineBreak+FInheritance.GetValue<string>('qualification');
 for V in Row.GetValue<TJSONArray>('declarations') do begin FInheritanceOrigins.Add(V as TJSONObject);InheritanceOriginCombo.Items.Add('Component declaration | '+V.GetValue<string>('source')+':'+IntToStr(V.GetValue<Integer>('range.line')));end;
 for V in Row.GetValue<TJSONArray>('properties') do begin P:=V as TJSONObject;
  for W in P.GetValue<TJSONArray>('history') do begin FInheritanceOrigins.Add(W as TJSONObject);InheritanceOriginCombo.Items.Add(P.GetValue<string>('name')+' = '+W.GetValue<string>('value')+' | '+W.GetValue<string>('source')+':'+IntToStr(W.GetValue<Integer>('range.line')));end;
 end;
 if InheritanceOriginCombo.Items.Count>0 then InheritanceOriginCombo.ItemIndex:=0;InheritanceOriginChange(nil);
end;
procedure TDPHMainForm.InheritanceOriginChange(Sender:TObject);
begin InheritanceSourceButton.Enabled:=(InheritanceOriginCombo.ItemIndex>=0) and (InheritanceOriginCombo.ItemIndex<FInheritanceOrigins.Count);end;
procedure TDPHMainForm.InheritanceSourceClick(Sender:TObject);
var Origin,Range:TJSONObject;
begin
 if (FView=nil) or (InheritanceOriginCombo.ItemIndex<0) or (InheritanceOriginCombo.ItemIndex>=FInheritanceOrigins.Count) then Exit;
 if FDetached then begin InheritanceMemo.Lines.Add('Source is detached. Attach unchanged source to navigate.');Exit;end;
 Origin:=FInheritanceOrigins[InheritanceOriginCombo.ItemIndex];Range:=Origin.GetValue<TJSONObject>('range');
 try SourceMemo.Text:=TDPHKeyboardInspector.ReadSource(FView,FEntry,Origin,Range);SourceMemo.CaretPosition:=TCaretPosition.Create(Max(0,Range.GetValue<Integer>('line')-1),Max(0,Range.GetValue<Integer>('column')-1));WorkspaceTabs.ActiveTab:=SourceTab;
 except on E:Exception do InheritanceMemo.Lines.Add('Source unavailable: '+E.Message);end;
end;
procedure TDPHMainForm.DependencyFilterChange(Sender:TObject);
var V:TJSONValue;Row:TJSONObject;Count:Integer;Query:string;
begin
 if FDependencyRows=nil then Exit;
 if Sender=DependencyNextButton then Inc(FDependencyOffset,250) else FDependencyOffset:=0;
 DependencyList.Items.Clear;FDependencyRows.Clear;DependencyNextButton.Enabled:=False;DependencySourceButton.Enabled:=False;DependencyEditButton.Enabled:=False;DependencyKnowledgeButton.Enabled:=False;DependencyClassButton.Enabled:=False;
 DependencyMemo.Text:='Select a component to inspect captured class evidence and authored dependency information.';if FDependencies=nil then Exit;
 Query:=DependencyFilterEdit.Text.Trim;Count:=0;
 for V in FDependencies.GetValue<TJSONArray>('rows') do begin Row:=V as TJSONObject;
  if (Query<>'') and not ContainsText(TDPHComponentDependencies.Describe(Row,FKnowledge),Query) then Continue;
  if (Count>=FDependencyOffset) and (FDependencyRows.Count<250) then begin FDependencyRows.Add(Row);DependencyList.Items.Add(Row.GetValue<string>('form')+' / '+Row.GetValue<string>('name')+' : '+Row.GetValue<string>('class')+' | '+Row.GetValue<string>('resolution'));end;Inc(Count);
 end;
 DependencyNextButton.Enabled:=Count>FDependencyOffset+FDependencyRows.Count;
 DependencyStatus.Text:=IntToStr(Count)+' matching components; showing '+IntToStr(FDependencyRows.Count)+' from offset '+IntToStr(FDependencyOffset)+'. Vendor and runtime support require attributed evidence.';
 if DependencyList.Count>0 then begin DependencyList.ItemIndex:=0;DependencySelectionClick(nil);end else DependencyMemo.Text:='No matching components. Clear the filter or inspect Coverage for uncaptured forms.';
end;
procedure TDPHMainForm.DependencySelectionClick(Sender:TObject);
var V:TJSONValue;Row:TJSONObject;
begin
 DependencySourceButton.Enabled:=False;DependencyEditButton.Enabled:=False;DependencyKnowledgeButton.Enabled:=False;DependencyClassButton.Enabled:=False;
 if (DependencyList.ItemIndex<0) or (DependencyList.ItemIndex>=FDependencyRows.Count) then Exit;
 Row:=FDependencyRows[DependencyList.ItemIndex];DependencyMemo.Text:=TDPHComponentDependencies.Describe(Row,FKnowledge)+sLineBreak+sLineBreak+FDependencies.GetValue<string>('qualification');
 DependencyMemo.Lines.Add('CAPTURED PACKAGE DECLARATIONS (not component membership)');
 for V in FDependencies.GetValue<TJSONArray>('packages') do DependencyMemo.Lines.Add(V.GetValue<string>('name')+' | '+V.GetValue<string>('source')+' | SHA-256 '+V.GetValue<string>('source_hash'));
 DependencyMemo.Lines.Add('UNAVAILABLE INPUTS (project-wide; not automatically attributed to this class)');
 for V in FDependencies.GetValue<TJSONArray>('unavailable_inputs') do DependencyMemo.Lines.Add(V.GetValue<string>('source')+' | '+V.GetValue<string>('availability'));
 DependencySourceButton.Enabled:=True;DependencyEditButton.Enabled:=True;DependencyKnowledgeButton.Enabled:=TDPHComponentDependencies.FindRecord(FKnowledge,Row.GetValue<string>('class'))<>nil;
 DependencyClassButton.Enabled:=Row.GetValue<TJSONArray>('class_candidates').Count=1;
end;
procedure TDPHMainForm.DependencyClassClick(Sender:TObject);
var Candidates:TJSONArray;
begin
 if (FView=nil) or (DependencyList.ItemIndex<0) or (DependencyList.ItemIndex>=FDependencyRows.Count) then Exit;
 Candidates:=FDependencyRows[DependencyList.ItemIndex].GetValue<TJSONArray>('class_candidates');if Candidates.Count<>1 then Exit;
 SelectSymbol(Candidates.Items[0].GetValue<string>('key'));WorkspaceTabs.ActiveTab:=ExplainTab;
end;
procedure TDPHMainForm.DependencySourceClick(Sender:TObject);
var Row,Range:TJSONObject;
begin
 if (FView=nil) or (DependencyList.ItemIndex<0) or (DependencyList.ItemIndex>=FDependencyRows.Count) then Exit;
 Row:=FDependencyRows[DependencyList.ItemIndex];Range:=Row.GetValue<TJSONObject>('range');
 if FDetached then begin DependencyMemo.Lines.Add('Source is detached. Attach unchanged source to navigate.');Exit;end;
 try SourceMemo.Text:=TDPHKeyboardInspector.ReadSource(FView,FEntry,Row,Range);SourceMemo.CaretPosition:=TCaretPosition.Create(Max(0,Range.GetValue<Integer>('line')-1),Max(0,Range.GetValue<Integer>('column')-1));WorkspaceTabs.ActiveTab:=SourceTab;
 except on E:Exception do DependencyMemo.Lines.Add('Source unavailable: '+E.Message);end;
end;
procedure TDPHMainForm.DependencyKnowledgeClick(Sender:TObject);
var Row:TJSONObject;I:Integer;
begin
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft first';Exit;end;
 if (DependencyList.ItemIndex<0) or (DependencyList.ItemIndex>=FDependencyRows.Count) then Exit;
 Row:=TDPHComponentDependencies.FindRecord(FKnowledge,FDependencyRows[DependencyList.ItemIndex].GetValue<string>('class'));if Row=nil then Exit;
 PendingKnowledgeCheck.IsChecked:=False;KnowledgeFilterChange(nil);
 for I:=0 to FKnowledgeRows.Count-1 do if FKnowledgeRows[I].GetValue<string>('id')=Row.GetValue<string>('id') then begin KnowledgeList.ItemIndex:=I;KnowledgeClick(nil);WorkspaceTabs.ActiveTab:=KnowledgeTab;Exit;end;
end;
procedure TDPHMainForm.DependencyEditClick(Sender:TObject);
var Editor:TDPHComponentDependencyForm;Row,ComponentRow,RecordValue,Initial:TJSONObject;Links:TJSONArray;
begin
 if FBusy or (FView=nil) then Exit;
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft first';Exit;end;
 if (DependencyList.ItemIndex<0) or (DependencyList.ItemIndex>=FDependencyRows.Count) then Exit;
 ComponentRow:=FDependencyRows[DependencyList.ItemIndex];Row:=TDPHComponentDependencies.FindRecord(FKnowledge,ComponentRow.GetValue<string>('class'));
 if Row<>nil then Initial:=TJSONObject.ParseJSONValue(Row.GetValue<string>('structured_json')) as TJSONObject
 else Initial:=TJSONObject.Create.AddPair('record_type','component_dependency').AddPair('fields',TJSONObject.Create.AddPair('class_name',ComponentRow.GetValue<string>('class')));
 Editor:=TDPHComponentDependencyForm.Create(nil);
 try
  Editor.LoadRecord(Initial,KnowledgeAuthorEdit.Text);if Editor.ShowModal<>mrOk then Exit;
  RecordValue:=Editor.RecordJSON;
  try
   FBinding:=True;
   try
    FKnowledgeID:=0;FKnowledgeRevision:=0;if Row<>nil then begin FKnowledgeID:=StrToInt64(Row.GetValue<string>('id'));FKnowledgeRevision:=StrToInt64(Row.GetValue<string>('revision'));end;
    KnowledgeTitleEdit.Text:=TDPHComponentDependency.Title(RecordValue);KnowledgeAuthorEdit.Text:=Editor.ProfileAuthorEdit.Text;
    KnowledgeKindCombo.ItemIndex:=KnowledgeKindCombo.Items.IndexOf('engineering_rule');KnowledgeDocumentCombo.ItemIndex:=KnowledgeDocumentCombo.Items.IndexOf('engineering');KnowledgeAudienceCombo.ItemIndex:=KnowledgeAudienceCombo.Items.IndexOf('engineer');
    KnowledgeBodyMemo.Text:=TDPHComponentDependency.Body(RecordValue);KnowledgeBodyMemo.ReadOnly:=True;KnowledgeTitleEdit.ReadOnly:=True;KnowledgeKindCombo.Enabled:=False;KnowledgeDocumentCombo.Enabled:=False;KnowledgeAudienceCombo.Enabled:=False;
    FKnowledgeStructuredJSON:=RecordValue.ToJSON;FKnowledgeQuestionJSON:='';FKnowledgeLink:='';FreeAndNil(FEditableLinks);
    if (Row<>nil) and Row.TryGetValue<TJSONArray>('rich_links',Links) then FEditableLinks:=Links.Clone as TJSONArray else FEditableLinks:=TJSONArray.Create;
    RefreshKnowledgeLinks;FKnowledgeEdited:=True;KnowledgeSectionLabel.Text:='Component dependency draft: click Save, then review explicitly';KnowledgeHistoryMemo.Text:='Edit structured fields on Component dependencies. Use Knowledge links for exact evidence. Saving does not resolve class source or verify vendor claims.';
   finally FBinding:=False;end;
   WorkspaceTabs.ActiveTab:=KnowledgeTab;StatusLabel.Text:='Dependency draft prepared. Click Save to persist; review requires a named reviewer.';
  finally RecordValue.Free;end;
 finally Editor.Free;Initial.Free;end;
end;

procedure TDPHMainForm.DatabaseDictionaryEditClick(Sender:TObject);
var Editor:TDPHDatabaseDictionaryForm;Row,ComponentRow,RecordValue,Initial:TJSONObject;Links:TJSONArray;
begin
 if FBusy or (FView=nil) then Exit;
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft first';Exit;end;
 if (DatabaseSchemaList.ItemIndex<0) or (DatabaseSchemaList.ItemIndex>=FDatabaseSchemaRows.Count) then Exit;
 ComponentRow:=FDatabaseSchemaRows[DatabaseSchemaList.ItemIndex];if not DatabaseDictionaryEdit.Enabled then Exit;Row:=TDPHDatabaseSchema.FindDictionary(FKnowledge,ComponentRow);
 if Row<>nil then Initial:=TJSONObject.ParseJSONValue(Row.GetValue<string>('structured_json')) as TJSONObject
 else Initial:=TDPHDatabaseSchema.NewDictionary(ComponentRow);
 Editor:=TDPHDatabaseDictionaryForm.Create(nil);
 try
  Editor.LoadRecord(Initial,KnowledgeAuthorEdit.Text);if Editor.ShowModal<>mrOk then Exit;
  RecordValue:=Editor.RecordJSON;
  try
   FBinding:=True;
   try
    FKnowledgeID:=0;FKnowledgeRevision:=0;if Row<>nil then begin FKnowledgeID:=StrToInt64(Row.GetValue<string>('id'));FKnowledgeRevision:=StrToInt64(Row.GetValue<string>('revision'));end;
    KnowledgeTitleEdit.Text:=TDPHDatabaseSchema.DictionaryTitle(RecordValue);KnowledgeAuthorEdit.Text:=Editor.ProfileAuthorEdit.Text;
    KnowledgeKindCombo.ItemIndex:=KnowledgeKindCombo.Items.IndexOf('business_rule');KnowledgeDocumentCombo.ItemIndex:=KnowledgeDocumentCombo.Items.IndexOf('overview');KnowledgeAudienceCombo.ItemIndex:=KnowledgeAudienceCombo.Items.IndexOf('all');
    KnowledgeBodyMemo.Text:=TDPHDatabaseSchema.DictionaryBody(RecordValue);KnowledgeBodyMemo.ReadOnly:=True;KnowledgeTitleEdit.ReadOnly:=True;KnowledgeKindCombo.Enabled:=False;KnowledgeDocumentCombo.Enabled:=False;KnowledgeAudienceCombo.Enabled:=False;
    FKnowledgeStructuredJSON:=RecordValue.ToJSON;FKnowledgeQuestionJSON:='';FKnowledgeLink:='';FreeAndNil(FEditableLinks);
    if (Row<>nil) and Row.TryGetValue<TJSONArray>('rich_links',Links) then FEditableLinks:=Links.Clone as TJSONArray else FEditableLinks:=TJSONArray.Create;
    RefreshKnowledgeLinks;FKnowledgeEdited:=True;KnowledgeSectionLabel.Text:='Data dictionary draft: click Save, then review explicitly';KnowledgeHistoryMemo.Text:='Edit fields using Database schema > Edit dictionary. Captured source, SHA256, statement line and schema identity stay read only. Use Knowledge links for additional evidence. Saving does not verify business meanings.';
   finally FBinding:=False;end;
   WorkspaceTabs.ActiveTab:=KnowledgeTab;StatusLabel.Text:='Dictionary draft prepared. Click Save to persist; review requires a named reviewer.';
  finally RecordValue.Free;end;
 finally Editor.Free;Initial.Free;end;
end;

procedure TDPHMainForm.DatabaseDictionaryKnowledgeClick(Sender:TObject);
var Row:TJSONObject;I:Integer;
begin
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft first';Exit;end;
 if (DatabaseSchemaList.ItemIndex<0) or (DatabaseSchemaList.ItemIndex>=FDatabaseSchemaRows.Count) then Exit;
 Row:=TDPHDatabaseSchema.FindDictionary(FKnowledge,FDatabaseSchemaRows[DatabaseSchemaList.ItemIndex],True);if Row=nil then Exit;
 PendingKnowledgeCheck.IsChecked:=False;KnowledgeFilterChange(nil);
 for I:=0 to FKnowledgeRows.Count-1 do if FKnowledgeRows[I].GetValue<string>('id')=Row.GetValue<string>('id') then begin KnowledgeList.ItemIndex:=I;KnowledgeClick(nil);WorkspaceTabs.ActiveTab:=KnowledgeTab;Exit;end;
end;
procedure TDPHMainForm.LayoutFilterChange(Sender:TObject);
var V:TJSONValue;Row:TJSONObject;Count:Integer;Query:string;
begin
 if Sender=LayoutNextButton then Inc(FLayoutOffset,250) else FLayoutOffset:=0;
 LayoutList.Items.Clear;FLayoutRows.Clear;LayoutNextButton.Enabled:=False;LayoutSourceButton.Enabled:=False;
 LayoutMemo.Text:='Select a component to read its layout declarations.';if FLayout=nil then Exit;
 Query:=LayoutFilterEdit.Text.Trim;Count:=0;
 for V in FLayout.GetValue<TJSONArray>('rows') do begin Row:=V as TJSONObject;
  if (Query<>'') and not ContainsText(TDPHLayoutRules.Describe(Row,FLayoutWidthDelta,FLayoutHeightDelta),Query) then Continue;
  if (Count>=FLayoutOffset) and (FLayoutRows.Count<250) then begin FLayoutRows.Add(Row);LayoutList.Items.Add(Row.GetValue<string>('form')+' / '+Row.GetValue<string>('parent')+' / '+Row.GetValue<string>('name')+' : '+Row.GetValue<string>('class'));end;Inc(Count);
 end;
 LayoutNextButton.Enabled:=Count>FLayoutOffset+FLayoutRows.Count;
 LayoutStatus.Text:=IntToStr(Count)+' matching components; showing '+IntToStr(FLayoutRows.Count)+' from offset '+IntToStr(FLayoutOffset)+'. Examples do not evaluate the target layout engine.';
 if LayoutList.Count>0 then begin LayoutList.ItemIndex:=0;LayoutSelectionClick(nil);end else LayoutMemo.Text:='No matching component. Clear the filter or inspect Coverage for uncaptured forms.';
end;
procedure TDPHMainForm.LayoutSelectionClick(Sender:TObject);
begin
 LayoutSourceButton.Enabled:=False;
 if (LayoutList.ItemIndex<0) or (LayoutList.ItemIndex>=FLayoutRows.Count) then Exit;
 LayoutMemo.Text:=TDPHLayoutRules.Describe(FLayoutRows[LayoutList.ItemIndex],FLayoutWidthDelta,FLayoutHeightDelta)+sLineBreak+sLineBreak+FLayout.GetValue<string>('qualification');LayoutSourceButton.Enabled:=True;
end;
procedure TDPHMainForm.LayoutApplyClick(Sender:TObject);
var W,H:Integer;
begin
 if not TryStrToInt(LayoutWidthEdit.Text.Trim,W) or not TryStrToInt(LayoutHeightEdit.Text.Trim,H) or (Abs(Int64(W))>10000) or (Abs(Int64(H))>10000) then begin LayoutStatus.Text:='Enter whole width and height changes from -10000 to 10000. The previous example remains active.';Exit;end;
 FLayoutWidthDelta:=W;FLayoutHeightDelta:=H;LayoutFilterChange(nil);
 LayoutStatus.Text:='Educational parent change applied: width '+IntToStr(W)+', height '+IntToStr(H)+' units. Target source and form geometry are unchanged.';
end;
procedure TDPHMainForm.LayoutSourceClick(Sender:TObject);
var Row,Range:TJSONObject;
begin
 if (FView=nil) or (LayoutList.ItemIndex<0) or (LayoutList.ItemIndex>=FLayoutRows.Count) then Exit;
 Row:=FLayoutRows[LayoutList.ItemIndex];Range:=Row.GetValue<TJSONObject>('range');
 if FDetached then begin LayoutMemo.Lines.Add('Source is detached. Attach unchanged source to navigate.');Exit;end;
 try SourceMemo.Text:=TDPHKeyboardInspector.ReadSource(FView,FEntry,Row,Range);SourceMemo.CaretPosition:=TCaretPosition.Create(Max(0,Range.GetValue<Integer>('line')-1),Max(0,Range.GetValue<Integer>('column')-1));WorkspaceTabs.ActiveTab:=SourceTab;
 except on E:Exception do LayoutMemo.Lines.Add('Source unavailable: '+E.Message);end;
end;

procedure TDPHMainForm.DynamicFilterChange(Sender:TObject);
var V:TJSONValue; Row:TJSONObject; Count:Integer; Query:string;
begin
 if Sender=DynamicNextButton then Inc(FDynamicOffset,250) else FDynamicOffset:=0;
 DynamicList.Items.Clear; FDynamicRows.Clear; DynamicReferenceCombo.Items.Clear;
 DynamicNextButton.Enabled:=False; DynamicExplainButton.Enabled:=False; DynamicReferenceButton.Enabled:=False;
 DynamicMemo.Text:='Select a creation site to read its evidence and limits.';
 if FDynamic=nil then Exit;
 Query:=DynamicFilterEdit.Text.Trim; Count:=0;
 for V in FDynamic.GetValue<TJSONArray>('rows') do begin Row:=V as TJSONObject;
  if (Query<>'') and not ContainsText(TDPHDynamicControls.Describe(Row),Query) then Continue;
  if (Count>=FDynamicOffset) and (FDynamicRows.Count<250) then begin FDynamicRows.Add(Row); DynamicList.Items.Add(Row.GetValue<string>('name')+' | '+Row.GetValue<string>('type')+' | instances unobserved'); end;
  Inc(Count);
 end;
 DynamicNextButton.Enabled:=Count>FDynamicOffset+FDynamicRows.Count;
 DynamicStatus.Text:=IntToStr(Count)+' matching creation sites; showing '+IntToStr(FDynamicRows.Count)+' from offset '+IntToStr(FDynamicOffset)+'. Reassess older captures for new links.';
 if DynamicList.Count>0 then begin DynamicList.ItemIndex:=0; DynamicSelectionClick(nil); end
 else DynamicMemo.Text:='No matching captured creation sites. Clear the filter or reassess. Unsupported factories and indirect creation remain gaps; this is not proof of no runtime controls.';
end;
procedure TDPHMainForm.DynamicSelectionClick(Sender:TObject);
var Row:TJSONObject; V:TJSONValue;
begin
 DynamicExplainButton.Enabled:=False; DynamicReferenceButton.Enabled:=False; DynamicReferenceCombo.Items.Clear;
 if (DynamicList.ItemIndex<0) or (DynamicList.ItemIndex>=FDynamicRows.Count) then Exit;
 Row:=FDynamicRows[DynamicList.ItemIndex]; DynamicMemo.Text:=TDPHDynamicControls.Describe(Row)+sLineBreak+sLineBreak+FDynamic.GetValue<string>('qualification');
 DynamicExplainButton.Enabled:=True;
 for V in Row.GetValue<TJSONArray>('links') do DynamicReferenceCombo.Items.Add(V.GetValue<string>('kind')+' | '+V.GetValue<string>('label')+' ['+V.GetValue<string>('resolution')+']');
 if DynamicReferenceCombo.Items.Count>0 then DynamicReferenceCombo.ItemIndex:=0;
 DynamicReferenceChange(nil);
end;
procedure TDPHMainForm.DynamicReferenceChange(Sender:TObject);
var Links:TJSONArray; Key:string;
begin
 DynamicReferenceButton.Enabled:=False;
 if (FView=nil) or (DynamicList.ItemIndex<0) or (DynamicList.ItemIndex>=FDynamicRows.Count) then Exit;
 Links:=FDynamicRows[DynamicList.ItemIndex].GetValue<TJSONArray>('links');
 if (DynamicReferenceCombo.ItemIndex<0) or (DynamicReferenceCombo.ItemIndex>=Links.Count) then Exit;
 Key:=Links.Items[DynamicReferenceCombo.ItemIndex].GetValue<string>('to','');
 DynamicReferenceButton.Enabled:=(Key<>'') and (FView.Symbol(Key)<>nil);
end;
procedure TDPHMainForm.DynamicExplainClick(Sender:TObject);
var Key:string;
begin
 if (FView=nil) or (DynamicList.ItemIndex<0) or (DynamicList.ItemIndex>=FDynamicRows.Count) then Exit;
 Key:=FDynamicRows[DynamicList.ItemIndex].GetValue<string>('key');
 if Sender=DynamicReferenceButton then begin
  DynamicReferenceChange(nil); if not DynamicReferenceButton.Enabled then Exit;
  Key:=FDynamicRows[DynamicList.ItemIndex].GetValue<TJSONArray>('links').Items[DynamicReferenceCombo.ItemIndex].GetValue<string>('to','');
 end;
 SelectSymbol(Key); WorkspaceTabs.ActiveTab:=ExplainTab;
end;

procedure TDPHMainForm.CommandsFilterChange(Sender: TObject);
var Value: TJSONValue; Row: TJSONObject; Count: Integer; Kind,Query: string;
begin
  if Sender=CommandsNextButton then Inc(FCommandOffset,250) else FCommandOffset:=0;
  CommandsList.Items.Clear; FCommandRows.Clear; CommandsHandlerCombo.Items.Clear;
  CommandsNextButton.Enabled:=False; CommandsSourceButton.Enabled:=False; CommandsActionButton.Enabled:=False; CommandsHandlerButton.Enabled:=False;
  CommandsMemo.Text:='Select a captured menu, toolbar command or action for explanations and source evidence.';
  if FCommands=nil then Exit;
  Query:=CommandsFilterEdit.Text.Trim; Kind:=''; if CommandsKindCombo.ItemIndex>0 then Kind:=CommandsKindCombo.Selected.Text; Count:=0;
  for Value in FCommands.GetValue<TJSONArray>('rows') do begin
    Row:=Value as TJSONObject;
    if (Kind<>'') and (Kind<>Row.GetValue<string>('kind')) then Continue;
    if (Query<>'') and not ContainsText(TDPHCommandInventory.Describe(Row),Query) then Continue;
    if (Count>=FCommandOffset) and (FCommandRows.Count<250) then begin
      FCommandRows.Add(Row); CommandsList.Items.Add(Row.GetValue<string>('kind')+' | '+Row.GetValue<string>('command_path')+' | '+Row.GetValue<string>('caption'));
    end;
    Inc(Count);
  end;
  CommandsNextButton.Enabled:=Count>FCommandOffset+FCommandRows.Count;
  CommandsStatus.Text:=IntToStr(Count)+' matching commands; showing '+IntToStr(FCommandRows.Count)+' from offset '+IntToStr(FCommandOffset)+'. Paths follow serialized parents.';
  if CommandsList.Count>0 then begin CommandsList.ItemIndex:=0; CommandsSelectionClick(nil); end
  else CommandsMemo.Text:='No matching captured command. Clear filters or inspect Coverage for missing form inputs.';
end;

procedure TDPHMainForm.CommandsSelectionClick(Sender: TObject);
var Row: TJSONObject; Value: TJSONValue;
begin
  CommandsSourceButton.Enabled:=False; CommandsActionButton.Enabled:=False; CommandsHandlerButton.Enabled:=False; CommandsHandlerCombo.Items.Clear;
  if (CommandsList.ItemIndex<0) or (CommandsList.ItemIndex>=FCommandRows.Count) then Exit;
  Row:=FCommandRows[CommandsList.ItemIndex]; CommandsMemo.Text:=TDPHCommandInventory.Describe(Row)+sLineBreak+sLineBreak+FCommands.GetValue<string>('qualification');
  CommandsSourceButton.Enabled:=True; CommandsActionButton.Enabled:=Row.GetValue('action_range')<>nil;
  for Value in Row.GetValue<TJSONArray>('handlers') do CommandsHandlerCombo.Items.Add(Value.GetValue<string>('origin')+'.'+Value.GetValue<string>('event')+' = '+Value.GetValue<string>('declared_handler')+' ['+Value.GetValue<string>('resolution')+']');
  if CommandsHandlerCombo.Items.Count>0 then CommandsHandlerCombo.ItemIndex:=0;
  CommandsHandlerChange(nil);
end;

procedure TDPHMainForm.CommandsHandlerChange(Sender: TObject);
var Handlers: TJSONArray; Key: string;
begin
  CommandsHandlerButton.Enabled:=False;
  if (FView=nil) or (CommandsList.ItemIndex<0) or (CommandsList.ItemIndex>=FCommandRows.Count) then Exit;
  Handlers:=FCommandRows[CommandsList.ItemIndex].GetValue<TJSONArray>('handlers');
  if (CommandsHandlerCombo.ItemIndex<0) or (CommandsHandlerCombo.ItemIndex>=Handlers.Count) then Exit;
  Key:=Handlers.Items[CommandsHandlerCombo.ItemIndex].GetValue<string>('target_key');
  CommandsHandlerButton.Enabled:=(Key<>'') and (FView.Symbol(Key)<>nil);
end;

procedure TDPHMainForm.CommandsHandlerClick(Sender: TObject);
var Handlers: TJSONArray; Key: string;
begin
  CommandsHandlerChange(nil); if not CommandsHandlerButton.Enabled then Exit;
  Handlers:=FCommandRows[CommandsList.ItemIndex].GetValue<TJSONArray>('handlers');
  Key:=Handlers.Items[CommandsHandlerCombo.ItemIndex].GetValue<string>('target_key');
  SelectSymbol(Key); WorkspaceTabs.ActiveTab:=ExplainTab;
end;

procedure TDPHMainForm.CommandsSourceClick(Sender: TObject);
var Row,Range: TJSONObject;
begin
  if (FView=nil) or (CommandsList.ItemIndex<0) or (CommandsList.ItemIndex>=FCommandRows.Count) then Exit;
  Row:=FCommandRows[CommandsList.ItemIndex];
  if Sender=CommandsActionButton then begin if not Row.TryGetValue<TJSONObject>('action_range',Range) then Exit; end
  else Range:=Row.GetValue<TJSONObject>('range');
  if FDetached then begin CommandsMemo.Lines.Add('Source is detached. Captured command evidence remains readable. Attach unchanged source to navigate.'); Exit; end;
  try
    SourceMemo.Text:=TDPHKeyboardInspector.ReadSource(FView,FEntry,Row,Range);
    SourceMemo.CaretPosition:=TCaretPosition.Create(Max(0,Range.GetValue<Integer>('line')-1),Max(0,Range.GetValue<Integer>('column')-1));
    WorkspaceTabs.ActiveTab:=SourceTab;
  except on E: Exception do CommandsMemo.Lines.Add('Source unavailable: '+E.Message); end;
end;

procedure TDPHMainForm.ComparisonClick(Sender: TObject);
var Request: TDPHWorkspaceRequest; Baseline: Int64;
begin
  if FBusy then begin StatusLabel.Text:='Wait for the current operation to finish.'; Exit; end;
  if (FView=nil) or (FDatabase='') then begin StatusLabel.Text:='Open a saved project database first.'; Exit; end;
  if not TryStrToInt64(ComparisonBaselineEdit.Text.Trim,Baseline) or (Baseline<=0) then begin
    StatusLabel.Text:='Enter a positive saved generation ID from Database tools > Preview retention.'; Exit;
  end;
  if Sender=ComparisonNextButton then Inc(FComparisonOffset,200) else FComparisonOffset:=0;
  Request:=Default(TDPHWorkspaceRequest); Request.Command:='compare'; Request.Database:=FDatabase; Request.Entry:=FEntry;
  Request.GenerationID:=FView.Document.GetValue<Int64>('generation_id'); Request.BaselineGeneration:=Baseline;
  Request.Body:=ComparisonFilterEdit.Text; Request.SearchOffset:=FComparisonOffset;
  FWorker.Submit(Request); FBusy:=True; FPendingCommand:='compare';
  StatusLabel.Text:='Comparing saved evidence in the background...';
end;
procedure TDPHMainForm.LoadComparison(AReport: TJSONObject);
var Value: TJSONValue;
begin
  ComparisonList.Items.Clear; FreeAndNil(FComparison); FComparison:=AReport;
  ComparisonBeforeMemo.Text:=''; ComparisonAfterMemo.Text:='';
  for Value in FComparison.GetValue<TJSONArray>('changes') do
    ComparisonList.Items.Add(StringReplace(Value.GetValue<string>('kind'),'_',' ',[rfReplaceAll])+' | '+Value.GetValue<string>('key'));
  ComparisonStatus.Text:='Before generation '+FComparison.GetValue('before_generation').Value+' > After generation '+
    FComparison.GetValue('after_generation').Value+' | '+FComparison.GetValue('total_matching').Value+' matching changes | page begins at '+
    IntToStr(FComparison.GetValue<Integer>('offset')+1)+sLineBreak+FComparison.GetValue<string>('definition');
  ComparisonNextButton.Enabled:=FComparison.GetValue<Boolean>('more');
  if ComparisonList.Count>0 then begin ComparisonList.ItemIndex:=0; ComparisonSelectionClick(nil); end
  else ComparisonBeforeMemo.Text:='No matching changes in the captured evidence. This does not prove complete semantic equivalence.';
end;
procedure TDPHMainForm.ComparisonSelectionClick(Sender: TObject);
var Row: TJSONObject; Value: TJSONValue;
begin
  if (FComparison=nil) or (ComparisonList.ItemIndex<0) then Exit;
  if ComparisonList.ItemIndex>=FComparison.GetValue<TJSONArray>('changes').Count then Exit;
  Row:=FComparison.GetValue<TJSONArray>('changes').Items[ComparisonList.ItemIndex] as TJSONObject;
  Value:=Row.GetValue('before'); if Value is TJSONObject then ComparisonBeforeMemo.Text:=TDPHRevisionComparison.EvidenceText(Value as TJSONObject)
  else ComparisonBeforeMemo.Text:='Absent from the Before capture.';
  Value:=Row.GetValue('after'); if Value is TJSONObject then ComparisonAfterMemo.Text:=TDPHRevisionComparison.EvidenceText(Value as TJSONObject)
  else ComparisonAfterMemo.Text:='Absent from the After capture.';
end;
procedure TDPHMainForm.QualityClick(Sender: TObject);
const Names: array[0..4] of string = ('routines','duplicate_bodies','unreferenced_candidates','unreachable_candidates','call_cycles');
var Quality,Row,Target: TJSONObject; Rows,Members: TJSONArray; Value: TJSONValue; Count: Integer; Title: string;
begin
  if FBinding or (FQualityRows=nil) then Exit;
  if Sender=QualityOpenButton then begin
    if (QualityList.ItemIndex<0) or (QualityList.ItemIndex>=FQualityRows.Count) then Exit;
    Target:=FQualityRows[QualityList.ItemIndex];
    if Target.TryGetValue<TJSONArray>('members',Members) and (Members.Count>0) then Target:=Members.Items[0] as TJSONObject;
    if Target.GetValue<string>('object_key','')<>'' then begin SelectSymbol(Target.GetValue<string>('object_key')); WorkspaceTabs.ActiveTab:=ExplainTab; end;
    Exit;
  end;
  if Sender=QualityNextButton then Inc(FQualityOffset,250) else FQualityOffset:=0;
  FQualityRows.Clear; QualityList.Items.Clear; QualityNextButton.Enabled:=False;
  QualityMemo.Text:='Open a captured project to inspect source quality candidates.';
  if FView=nil then Exit;
  if not FView.Document.TryGetValue<TJSONObject>('source_quality',Quality) then begin
    QualityMemo.Text:='This older capture has no source quality report. Attach source and reassess; detached caches retain their original evidence.'; Exit;
  end;
  if (QualityKindCombo.ItemIndex<0) or (QualityKindCombo.ItemIndex>4) then Exit;
  Rows:=Quality.GetValue<TJSONArray>(Names[QualityKindCombo.ItemIndex]); Count:=0;
  for Value in Rows do begin
    Row:=Value as TJSONObject;
    if (QualityFilterEdit.Text<>'') and not ContainsText(Row.ToJSON,QualityFilterEdit.Text) then Continue;
    Inc(Count); if Count<=FQualityOffset then Continue;
    if FQualityRows.Count>=250 then begin QualityNextButton.Enabled:=True; Break; end;
    Title:=Row.GetValue<string>('name','');
    if Row.TryGetValue<TJSONArray>('members',Members) and (Members.Count>0) then Title:=Members.Items[0].GetValue<string>('name')+' | '+IntToStr(Members.Count)+' members';
    if Row.GetValue('structural_decision_score')<>nil then Title:=Title+' | decisions '+Row.GetValue('structural_decision_score').Value;
    FQualityRows.Add(Row); QualityList.Items.Add(Title);
  end;
  QualityMemo.Text:=Quality.GetValue<string>('definition')+sLineBreak+Format('%d captured rows in this category. Displayed page begins at %d; use a filter or Next 250.',[Rows.Count,FQualityOffset+1]);
  if FQualityRows.Count>0 then begin QualityList.ItemIndex:=0; QualitySelectionClick(nil); end;
end;
procedure TDPHMainForm.QualitySelectionClick(Sender: TObject);
var Quality,Row,Member: TJSONObject; Members: TJSONArray; Text: TStringBuilder; I: Integer;
begin
  if (FView=nil) or (QualityList.ItemIndex<0) or (QualityList.ItemIndex>=FQualityRows.Count) then Exit;
  if not FView.Document.TryGetValue<TJSONObject>('source_quality',Quality) then Exit;
  Row:=FQualityRows[QualityList.ItemIndex]; Text:=TStringBuilder.Create;
  try
    Text.AppendLine(Row.GetValue<string>('name',QualityKindCombo.Items[QualityKindCombo.ItemIndex]));
    Text.AppendLine(Row.GetValue<string>('finding',Quality.GetValue<string>('definition')));
    if Row.GetValue('structural_decision_score')<>nil then begin
      Text.AppendLine('Structural decision score: '+Row.GetValue('structural_decision_score').Value);
      Text.AppendLine('Captured CFG nodes: '+Row.GetValue('captured_cfg_nodes').Value);
      Text.AppendLine('Significant body tokens: '+Row.GetValue('significant_body_tokens').Value);
      Text.AppendLine('Body line span (0 means unavailable): '+Row.GetValue('body_line_span').Value);
      Text.AppendLine('Maximum parsed statement nesting: '+Row.GetValue('maximum_parse_nesting').Value);
      Text.AppendLine('Captured incoming relationships: '+Row.GetValue('incoming_relationships').Value);
    end;
    if Row.GetValue('range')<>nil then Text.AppendLine('Evidence: '+Row.GetValue<string>('range.source')+':'+IntToStr(Row.GetValue<Integer>('range.line'))+' | SHA256 '+Row.GetValue<string>('source_hash'));
    if Row.TryGetValue<TJSONArray>('members',Members) then begin
      for I:=0 to Min(Members.Count,100)-1 do begin Member:=Members.Items[I] as TJSONObject;
        Text.AppendLine(Member.GetValue<string>('name')+' | '+Member.GetValue<string>('range.source')+':'+IntToStr(Member.GetValue<Integer>('range.line'))+' | SHA256 '+Member.GetValue<string>('source_hash'));
      end;
      if Members.Count>100 then Text.AppendLine(IntToStr(Members.Count-100)+' further members omitted from this display.');
    end;
    Text.AppendLine('Captured generation '+FView.Document.GetValue('generation_id').Value+' | '+Quality.GetValue<string>('version')+' | input fingerprint '+Quality.GetValue<string>('input_fingerprint'));
    Text.AppendLine('Open explanation inspects the routine, or the first group member. Use its Source and References pages to investigate. These findings never authorize source deletion.');
    QualityMemo.Text:=Text.ToString;
  finally Text.Free; end;
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
var Directory,Fragment,NodeKey: string; P,I: Integer; V: TJSONValue; S: TJSONObject;
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
  P:=Pos('#knowledge_revision_',AURL);
  if (Sender=FlowBrowser) and (P>0) and (FKnowledge<>nil) then begin
   ACancel:=True;Fragment:=Copy(AURL,P+20,MaxInt);
   for V in FKnowledge do begin
    for I:=0 to V.GetValue<TJSONArray>('history').Count-1 do begin S:=V.GetValue<TJSONArray>('history').Items[I] as TJSONObject;
     if S.GetValue<string>('revision')<>Fragment then Continue;
     FreeAndNil(FDetails);FDetails:=TJSONArray.Create;DetailsList.Items.Clear;DetailsMemo.Text:=V.GetValue<string>('title')+sLineBreak+'Exact linked revision '+Fragment+' | '+S.GetValue<string>('verification_state')+' | reviewer '+S.GetValue<string>('reviewer')+sLineBreak+S.GetValue<string>('body');WorkspaceTabs.ActiveTab:=DetailsTab;Exit;
    end;
   end;
   Exit;
  end;
  P:=Pos('#s_',AURL); if (P=0) or (FView=nil) then Exit; ACancel:=True; Fragment:=Copy(AURL,P+3,MaxInt);
  if (Sender=FlowBrowser) and (FGraph<>nil) and MatchText(FGraph.GetValue<string>('kind'),['Data lineage','Business process']) then begin
   for I:=0 to FGraph.GetValue<TJSONArray>('nodes').Count-1 do begin
    NodeKey:=FGraph.GetValue<TJSONArray>('nodes').Items[I].GetValue<string>('id');
    if FGraph.GetValue<string>('kind')='Business process' then NodeKey:=FGraph.GetValue<string>('workflow_id')+'|'+NodeKey;
    if SameText(THashSHA2.GetHashString(NodeKey),Fragment) then begin
     GraphMouseDown(GraphPaint,TMouseButton.mbLeft,[],GraphRect(I).CenterPoint.X,GraphRect(I).CenterPoint.Y);Break;
    end;
   end;Exit;
  end;
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
var V: TJSONValue; R: TJSONObject; Index: Integer; Thumbnail: TBitmap; Path,LabelText: string;BeforeID,AfterID:Int64;
begin
  BeforeID:=0;AfterID:=0;
  if (FImages<>nil) and (HistoryBeforeCombo.ItemIndex>=0) and (HistoryBeforeCombo.ItemIndex<FImages.Count) then BeforeID:=FImages.Items[HistoryBeforeCombo.ItemIndex].GetValue<Int64>('artifact_id');
  if (FImages<>nil) and (HistoryAfterCombo.ItemIndex>=0) and (HistoryAfterCombo.ItemIndex<FImages.Count) then AfterID:=FImages.Items[HistoryAfterCombo.ItemIndex].GetValue<Int64>('artifact_id');
  HistorySelectionChange(nil);HistoryBeforeCombo.Items.Clear;HistoryAfterCombo.Items.Clear;
  FImages.Free; FImages:=ARows; ScreenshotList.Items.Clear;
  for V in ARows do begin R:=V as TJSONObject;
    LabelText:='ID '+R.GetValue('artifact_id').Value+' | gen '+R.GetValue('generation_id').Value+' | '+R.GetValue<string>('caption');HistoryBeforeCombo.Items.Add(LabelText);HistoryAfterCombo.Items.Add(LabelText);
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
  if ARows.Count>0 then begin HistoryBeforeCombo.ItemIndex:=ARows.Count-1;HistoryAfterCombo.ItemIndex:=0;end;
  for Index:=0 to ARows.Count-1 do begin if ARows.Items[Index].GetValue<Int64>('artifact_id')=BeforeID then HistoryBeforeCombo.ItemIndex:=Index;if ARows.Items[Index].GetValue<Int64>('artifact_id')=AfterID then HistoryAfterCombo.ItemIndex:=Index;end;
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
procedure TDPHMainForm.DatabaseERFilterChange(Sender:TObject);
var V:TJSONValue;Edge:TJSONObject;Limit,MaxColumns:Integer;
begin
 if FDatabaseSchemaRows=nil then Exit;
 Limit:=StrToIntDef(DatabaseERPageSize.Selected.Text,30);
 if Sender=DatabaseERNext then Inc(FDatabaseEROffset,Limit) else FDatabaseEROffset:=0;
 if Sender=DatabaseERAll then begin FDatabaseERFocusID:='';DatabaseERFilter.Text:='';end;
 FDatabaseEREvidenceID:='';DatabaseEROpen.Enabled:=False;DatabaseERRelations.Items.Clear;FreeAndNil(FDatabaseER);
 MaxColumns:=Max(1,Min(32,Trunc((DatabaseERTableStyle.Height-DatabaseERHeaderStyle.Height-DatabaseERTextStyle.Height*2)/Max(1,DatabaseERTextStyle.Height))));
 FDatabaseER:=TDPHDatabaseSchema.Diagram(FDatabaseSchema,DatabaseERFilter.Text,FDatabaseERFocusID,FDatabaseEROffset,Limit,MaxColumns);
 FDatabaseERScale:=StrToIntDef(StringReplace(DatabaseERZoom.Selected.Text,'%','',[]),100)/100;
 for V in FDatabaseER.GetValue<TJSONArray>('edges') do begin Edge:=V as TJSONObject;
  DatabaseERRelations.Items.Add('FK '+IntToStr(DatabaseERRelations.Items.Count+1)+': '+Edge.GetValue<string>('from_name')+' -> '+Edge.GetValue<string>('to_name')+' | '+Edge.GetValue<string>('state'));
 end;
 DatabaseERNext.Enabled:=FDatabaseER.GetValue<Boolean>('has_next');
 DatabaseERStatus.Text:=Format('PARTIAL schema | %d of %d matching tables from %d | %d related FKs (%d omitted) | %d source gaps; %d unresolved FKs. Blue = captured links; orange = gaps. Cardinality/deployment unverified.',[FDatabaseER.GetValue<Integer>('shown_tables'),FDatabaseER.GetValue<Integer>('matching_tables'),FDatabaseEROffset,FDatabaseER.GetValue<Integer>('related_foreign_keys'),FDatabaseER.GetValue<Integer>('omitted_foreign_keys'),FDatabaseER.GetValue<Integer>('source_gaps'),FDatabaseER.GetValue<Integer>('unresolved_foreign_keys')]);
 DatabaseERMemo.Text:=FDatabaseER.GetValue<string>('qualification')+sLineBreak+sLineBreak+'PK = declared primary key; FK = declared foreign key; UQ = declared unique key. A badge describes captured membership, not deployed enforcement. Click a table for its full column/key evidence, or choose FK evidence in the command strip.';
 if FDatabaseER.GetValue<Integer>('shown_tables')=0 then DatabaseERMemo.Lines.Add('No matching captured tables. Clear the text filter, click All tables, or attach approved SQL resources and reassess.');
 if FDatabaseERFocusID<>'' then DatabaseERMemo.Lines.Add('Focus includes the selected captured table and its directly linked neighbors; the text filter still applies.');
 DatabaseERResize(nil);
end;
procedure TDPHMainForm.DatabaseERFocusClick(Sender:TObject);
var Row:TJSONObject;
begin
 FDatabaseERFocusID:='';
 if (DatabaseSchemaList.ItemIndex>=0) and (DatabaseSchemaList.ItemIndex<FDatabaseSchemaRows.Count) then begin
  Row:=FDatabaseSchemaRows[DatabaseSchemaList.ItemIndex];
  if (Row.GetValue<string>('kind')='table') and (Row.GetValue<string>('status')='declared header') then FDatabaseERFocusID:=Row.GetValue<string>('id')
  else Row.TryGetValue<string>('declaration_id',FDatabaseERFocusID);
 end;
 DatabaseERFilter.Text:='';DatabaseERFilterChange(nil);WorkspaceTabs.ActiveTab:=DatabaseERTab;
 if FDatabaseERFocusID='' then DatabaseERMemo.Lines.Add('No captured table/column/key selected in Database schema; showing all captured tables.');
end;
function TDPHMainForm.DatabaseERRect(AIndex:Integer):TRectF;
var W,H,Left,Top:Single;Columns:Integer;
begin
 W:=(DatabaseERTableStyle.Width+DatabaseERTableStyle.Margins.Right)*FDatabaseERScale;H:=(DatabaseERTableStyle.Height+DatabaseERTableStyle.Margins.Bottom)*FDatabaseERScale;
 Columns:=Max(1,Trunc((DatabaseERPaint.Width-DatabaseERTableStyle.Margins.Left*2*FDatabaseERScale)/Max(1,W)));
 Left:=DatabaseERTableStyle.Margins.Left*FDatabaseERScale+(AIndex mod Columns)*W;Top:=DatabaseERTableStyle.Margins.Top*FDatabaseERScale+(AIndex div Columns)*H;
 Result:=RectF(Left,Top,Left+DatabaseERTableStyle.Width*FDatabaseERScale,Top+DatabaseERTableStyle.Height*FDatabaseERScale);
end;
procedure TDPHMainForm.DatabaseERResize(Sender:TObject);
var Count:Integer;
begin
 if FDatabaseER=nil then Exit;
 DatabaseERPaint.Width:=Max(DatabaseERScroll.Width-24,(DatabaseERTableStyle.Width+DatabaseERTableStyle.Margins.Left*2+DatabaseERTableStyle.Margins.Right)*FDatabaseERScale);
 Count:=FDatabaseER.GetValue<TJSONArray>('nodes').Count;
 if Count=0 then DatabaseERPaint.Height:=Max(100,DatabaseERScroll.Height-24)
 else DatabaseERPaint.Height:=DatabaseERRect(Count-1).Bottom+DatabaseERTableStyle.Margins.Bottom*FDatabaseERScale;
 DatabaseERPaint.Repaint;
end;
procedure TDPHMainForm.DatabaseERPaintPaint(Sender:TObject;Canvas:TCanvas);
var Nodes,Edges:TJSONArray;V,Column:TJSONValue;Node,Edge:TJSONObject;I,J,A,B:Integer;R,Header,TextRect:TRectF;P1,P2,P3,P4,P5,P6:TPointF;Scale,Pad,RowHeight,Lane:Single;Style:TRectangle;Text:string;
begin
 Canvas.Fill.Color:=TAlphaColors.White;Canvas.FillRect(DatabaseERPaint.LocalRect,0,0,[],1);
 if FDatabaseER=nil then Exit;Nodes:=FDatabaseER.GetValue<TJSONArray>('nodes');Edges:=FDatabaseER.GetValue<TJSONArray>('edges');Scale:=FDatabaseERScale;Pad:=DatabaseERTextStyle.Margins.Left*Scale;RowHeight:=DatabaseERTextStyle.Height*Scale;
 Canvas.Font.Assign(DatabaseERTextStyle.TextSettings.Font);Canvas.Font.Size:=Canvas.Font.Size*Scale;
 if Nodes.Count=0 then begin Canvas.Fill.Color:=DatabaseERTextStyle.TextSettings.FontColor;Canvas.FillText(DatabaseERPaint.LocalRect,'No matching captured tables. Clear filters or attach SQL and reassess.',True,1,[],TTextAlign.Center,TTextAlign.Center);Exit;end;
 for I:=0 to Edges.Count-1 do begin Edge:=Edges.Items[I] as TJSONObject;if not Edge.GetValue<Boolean>('draw') then Continue;A:=-1;B:=-1;
  for J:=0 to Nodes.Count-1 do begin Node:=Nodes.Items[J] as TJSONObject;if Node.GetValue<string>('id')=Edge.GetValue<string>('from') then A:=J;if Node.GetValue<string>('id')=Edge.GetValue<string>('to') then B:=J;end;
  if (A<0) or (B<0) then Continue;
  Canvas.Stroke.Assign(DatabaseERTableStyle.Stroke);if not Edge.GetValue<Boolean>('resolved') then begin Canvas.Stroke.Assign(DatabaseERGapStyle.Stroke);Canvas.Stroke.Dash:=TStrokeDash.Dash;end;
  Lane:=(8+(I mod 3)*8)*Scale;R:=DatabaseERRect(A);Header:=DatabaseERRect(B);
  P1:=PointF(R.Right,R.CenterPoint.Y);P2:=PointF(R.Right+Lane,P1.Y);P3:=PointF(P2.X,Max(R.Bottom,Header.Bottom)+Lane);P4:=PointF(Header.Left-Lane,P3.Y);P5:=PointF(P4.X,Header.CenterPoint.Y);P6:=PointF(Header.Left,P5.Y);
  Canvas.DrawLine(P1,P2,1);Canvas.DrawLine(P2,P3,1);Canvas.DrawLine(P3,P4,1);Canvas.DrawLine(P4,P5,1);Canvas.DrawLine(P5,P6,1);
  Canvas.DrawLine(P6,PointF(P6.X-5*Scale,P6.Y-4*Scale),1);Canvas.DrawLine(P6,PointF(P6.X-5*Scale,P6.Y+4*Scale),1);
  Canvas.Fill.Color:=Canvas.Stroke.Color;Canvas.FillText(RectF(P2.X+2*Scale,P2.Y-RowHeight,P2.X+55*Scale,P2.Y),'FK '+IntToStr(I+1),False,1,[],TTextAlign.Leading,TTextAlign.Center);
 end;
 for I:=0 to Nodes.Count-1 do begin Node:=Nodes.Items[I] as TJSONObject;R:=DatabaseERRect(I);Style:=DatabaseERTableStyle;if Node.GetValue<Boolean>('partial') then Style:=DatabaseERGapStyle;
  Canvas.Fill.Assign(Style.Fill);Canvas.FillRect(R,4,4,AllCorners,1);Canvas.Stroke.Assign(Style.Stroke);Canvas.DrawRect(R,4,4,AllCorners,1);
  Header:=RectF(R.Left,R.Top,R.Right,R.Top+DatabaseERHeaderStyle.Height*Scale);Canvas.Fill.Assign(DatabaseERHeaderStyle.Fill);Canvas.FillRect(Header,0,0,[],1);
  Canvas.Font.Assign(DatabaseERTitleStyle.TextSettings.Font);Canvas.Font.Size:=Canvas.Font.Size*Scale;Canvas.Fill.Color:=DatabaseERTitleStyle.TextSettings.FontColor;
  TextRect:=Header;TextRect.Inflate(-Pad,-2*Scale);Canvas.FillText(TextRect,Node.GetValue<string>('name'),True,1,[],TTextAlign.Leading,TTextAlign.Center);
  Canvas.Font.Assign(DatabaseERTextStyle.TextSettings.Font);Canvas.Font.Size:=Canvas.Font.Size*Scale;Canvas.Fill.Color:=DatabaseERTextStyle.TextSettings.FontColor;J:=0;
  for Column in Node.GetValue<TJSONArray>('columns') do begin
   TextRect:=RectF(R.Left+Pad,Header.Bottom+J*RowHeight,R.Right-Pad,Header.Bottom+(J+1)*RowHeight);Text:=Column.GetValue<string>('badges');if Text<>'' then Text:='['+Text+'] ';Text:=Text+Column.GetValue<string>('name')+' : '+Column.GetValue<string>('declared_type');Canvas.FillText(TextRect,Text,False,1,[],TTextAlign.Leading,TTextAlign.Center);Inc(J);
  end;
  TextRect:=RectF(R.Left+Pad,R.Bottom-RowHeight*2,R.Right-Pad,R.Bottom-RowHeight);Canvas.FillText(TextRect,IntToStr(J)+'/'+Node.GetValue<Integer>('column_count').ToString+' columns | click table for evidence',False,1,[],TTextAlign.Leading,TTextAlign.Center);
  if Node.GetValue<Boolean>('partial') then Text:='GAPS / TRUNCATION - inspect evidence' else Text:='Captured declaration; live schema unverified';TextRect.Offset(0,RowHeight);Canvas.Fill.Color:=Style.Stroke.Color;Canvas.FillText(TextRect,Text,False,1,[],TTextAlign.Leading,TTextAlign.Center);
 end;
end;
procedure TDPHMainForm.DatabaseEREvidence(const AID:string);
var V,W:TJSONValue;Row:TJSONObject;Text:string;
begin
 if FDatabaseSchema=nil then Exit;
 FDatabaseEREvidenceID:='';DatabaseEROpen.Enabled:=False;
 for V in FDatabaseSchema.GetValue<TJSONArray>('rows') do begin Row:=V as TJSONObject;if Row.GetValue<string>('id')<>AID then Continue;
  FDatabaseEREvidenceID:=AID;Text:=TDPHDatabaseSchema.Describe(Row);
  if Row.GetValue<string>('kind')='table' then begin
   Text:=Text+sLineBreak+sLineBreak+'CAPTURED COLUMNS AND KEYS (full inventory, up to 10000 rows)'+sLineBreak;
   for W in FDatabaseSchema.GetValue<TJSONArray>('rows') do if W.GetValue<string>('declaration_id','')=AID then Text:=Text+W.GetValue<string>('kind')+' | '+W.GetValue<string>('name')+' | '+W.GetValue<string>('declared_type','')+' | '+W.GetValue<string>('key_kind','')+' | '+W.GetValue<string>('relationship_status','')+' | '+W.GetValue<string>('reason')+sLineBreak;
  end;
  DatabaseERMemo.Text:=Text+sLineBreak+sLineBreak+FDatabaseER.GetValue<string>('qualification');DatabaseEROpen.Enabled:=True;Exit;
 end;
end;
procedure TDPHMainForm.DatabaseERSelectionChange(Sender:TObject);
begin
 if (FDatabaseER=nil) or (DatabaseERRelations.ItemIndex<0) or (DatabaseERRelations.ItemIndex>=FDatabaseER.GetValue<TJSONArray>('edges').Count) then Exit;
 DatabaseEREvidence(FDatabaseER.GetValue<TJSONArray>('edges').Items[DatabaseERRelations.ItemIndex].GetValue<string>('key_id'));
end;
procedure TDPHMainForm.DatabaseERMouseDown(Sender:TObject;Button:TMouseButton;Shift:TShiftState;X,Y:Single);
var I:Integer;
begin
 if (FDatabaseER=nil) or (Button<>TMouseButton.mbLeft) then Exit;
 for I:=0 to FDatabaseER.GetValue<TJSONArray>('nodes').Count-1 do if DatabaseERRect(I).Contains(PointF(X,Y)) then begin DatabaseEREvidence(FDatabaseER.GetValue<TJSONArray>('nodes').Items[I].GetValue<string>('id'));Exit;end;
end;
procedure TDPHMainForm.DatabaseEROpenClick(Sender:TObject);
var I:Integer;V:TJSONValue;
begin
 if (FDatabaseSchema=nil) or (FDatabaseEREvidenceID='') then Exit;I:=0;
 for V in FDatabaseSchema.GetValue<TJSONArray>('rows') do begin
  if V.GetValue<string>('id')=FDatabaseEREvidenceID then begin
   DatabaseSchemaKind.ItemIndex:=0;DatabaseSchemaState.ItemIndex:=0;DatabaseSchemaFilter.Text:='';DatabaseSchemaFilterChange(nil);
   if I>=250 then begin FDatabaseSchemaOffset:=(I div 250)*250-250;DatabaseSchemaFilterChange(DatabaseSchemaNext);end;
   DatabaseSchemaList.ItemIndex:=I mod 250;DatabaseSchemaSelectionChange(nil);WorkspaceTabs.ActiveTab:=DatabaseSchemaTab;Exit;
  end;Inc(I);
 end;
 DatabaseERMemo.Lines.Add('Evidence target is no longer in this captured schema. Rebuild the diagram.');
end;

procedure TDPHMainForm.FileFormatsFilterChange(Sender:TObject);
var V:TJSONValue;Row:TJSONObject;Count:Integer;
begin
 if FFileFormatRows=nil then Exit;
 if Sender=FileFormatsNext then Inc(FFileFormatOffset,250) else FFileFormatOffset:=0;
 FFileFormatRows.Clear;FileFormatsList.Items.Clear;FileFormatsNext.Enabled:=False;FileFormatsSelectionChange(nil);
 if FFileFormats=nil then begin FileFormatsStatus.Text:='Open a captured project to inspect format evidence.';Exit;end;
 Count:=0;
 for V in FFileFormats.GetValue<TJSONArray>('rows') do begin Row:=V as TJSONObject;
  if (FileFormatsKind.ItemIndex>0) and (Row.GetValue<string>('direction')<>FileFormatsKind.Selected.Text) then Continue;
  if (FileFormatsFilter.Text.Trim<>'') and not ContainsText(TDPHWorkspaceView.DescribeFileFormat(Row),FileFormatsFilter.Text.Trim) then Continue;
  if (Count>=FFileFormatOffset) and (FFileFormatRows.Count<250) then begin FFileFormatRows.Add(Row);FileFormatsList.Items.Add(Row.GetValue<string>('direction')+' | '+Row.GetValue<string>('name')+' | '+Row.GetValue<string>('format'));end;Inc(Count);
 end;
 FileFormatsNext.Enabled:=Count>FFileFormatOffset+FFileFormatRows.Count;
 FileFormatsStatus.Text:=Format('%d matches; %d shown from %d. Captured candidates; runtime transfer unobserved. %s',[Count,FFileFormatRows.Count,FFileFormatOffset,FFileFormats.GetValue<string>('limit','')]);
 if FileFormatsList.Count>0 then FileFormatsList.ItemIndex:=0;FileFormatsSelectionChange(nil);
end;
procedure TDPHMainForm.FileFormatsSelectionChange(Sender:TObject);
var Row:TJSONObject;V:TJSONValue;Title:string;
begin
 FileFormatsSource.Enabled:=False;FileFormatsExplain.Enabled:=False;FileFormatsContract.Enabled:=False;
 FileFormatsMemo.Text:='Select a captured file or API candidate. Empty results do not prove there are no import/export formats; unsupported, dynamic and uncaptured transfers remain unknown.';
 if (FFileFormatRows=nil) or (FileFormatsList.ItemIndex<0) or (FileFormatsList.ItemIndex>=FFileFormatRows.Count) then Exit;
 Row:=FFileFormatRows[FileFormatsList.ItemIndex];FileFormatsMemo.Text:=TDPHWorkspaceView.DescribeFileFormat(Row)+sLineBreak+FFileFormats.GetValue<string>('qualification');
 FileFormatsSource.Enabled:=True;FileFormatsExplain.Enabled:=Row.GetValue<string>('target_key')<>'';FileFormatsContract.Enabled:=True;
 Title:=TDPHWorkspaceView.FileFormatContractTitle(Row);
 if FKnowledge<>nil then for V in FKnowledge do if V.GetValue<string>('title')=Title then FileFormatsMemo.Lines.Add(sLineBreak+'SAVED CONTRACT ['+V.GetValue<string>('state')+'] | '+V.GetValue<string>('owner')+sLineBreak+V.GetValue<string>('body'));
end;
procedure TDPHMainForm.FileFormatsSourceClick(Sender:TObject);
var Row,Range:TJSONObject;
begin
 if (FView=nil) or (FileFormatsList.ItemIndex<0) or (FileFormatsList.ItemIndex>=FFileFormatRows.Count) then Exit;
 Row:=FFileFormatRows[FileFormatsList.ItemIndex];Range:=Row.GetValue<TJSONObject>('range');
 if FDetached then begin FileFormatsMemo.Lines.Add('Source is detached. Attach unchanged source to navigate.');Exit;end;
 try SourceMemo.Text:=TDPHKeyboardInspector.ReadSource(FView,FEntry,Row,Range);SourceMemo.CaretPosition:=TCaretPosition.Create(Max(0,Range.GetValue<Integer>('line')-1),0);WorkspaceTabs.ActiveTab:=SourceTab;
 except on E:Exception do FileFormatsMemo.Lines.Add('Source unavailable: '+E.Message);end;
end;
procedure TDPHMainForm.FileFormatsExplainClick(Sender:TObject);
var Key:string;
begin
 if (FView=nil) or (FileFormatsList.ItemIndex<0) or (FileFormatsList.ItemIndex>=FFileFormatRows.Count) then Exit;
 Key:=FFileFormatRows[FileFormatsList.ItemIndex].GetValue<string>('target_key');if Key='' then Exit;
 SelectSymbol(Key);WorkspaceTabs.ActiveTab:=ExplainTab;
end;
procedure TDPHMainForm.DataRetentionFilterChange(Sender:TObject);
var V:TJSONValue;Row:TJSONObject;Count:Integer;Query,StateFilter:string;
begin
 if FDataRetentionRows=nil then Exit;
 if Sender=DataRetentionNext then Inc(FDataRetentionOffset,250) else FDataRetentionOffset:=0;
 FDataRetentionRows.Clear;DataRetentionList.Items.Clear;DataRetentionNext.Enabled:=False;DataRetentionNew.Enabled:=FView<>nil;
 DataRetentionSelectionChange(nil);
 if (FView=nil) or (FKnowledge=nil) then begin DataRetentionStatus.Text:='Open a captured project, then New policy to record its target-data requirements.';Exit;end;
 Query:=DataRetentionFilter.Text.Trim;StateFilter:='';if DataRetentionState.ItemIndex>0 then StateFilter:=DataRetentionState.Selected.Text;Count:=0;
 for V in FKnowledge do begin Row:=V as TJSONObject;
  if not TDPHWorkspaceView.IsDataRetentionPolicy(Row) then Continue;
  if (StateFilter<>'') and (Row.GetValue<string>('state')<>StateFilter) then Continue;
  if (Query<>'') and not ContainsText(TDPHWorkspaceView.DescribeDataRetentionPolicy(Row),Query) then Continue;
  if (Count>=FDataRetentionOffset) and (FDataRetentionRows.Count<250) then begin
   FDataRetentionRows.Add(Row);DataRetentionList.Items.Add('['+Row.GetValue<string>('state')+'] '+Row.GetValue<string>('title')+' | '+Row.GetValue<string>('owner'));
  end;Inc(Count);
 end;
 DataRetentionNext.Enabled:=Count>FDataRetentionOffset+FDataRetentionRows.Count;
 DataRetentionStatus.Text:=IntToStr(Count)+' saved policies match; '+IntToStr(FDataRetentionRows.Count)+' shown from '+IntToStr(FDataRetentionOffset)+'. Review state is a human assessment; unknown fields remain unresolved.';
 if DataRetentionList.Count>0 then DataRetentionList.ItemIndex:=0;
 DataRetentionSelectionChange(nil);
end;
procedure TDPHMainForm.DataRetentionSelectionChange(Sender:TObject);
var Row:TJSONObject;
begin
 Row:=nil;if (FDataRetentionRows<>nil) and (DataRetentionList.ItemIndex>=0) and (DataRetentionList.ItemIndex<FDataRetentionRows.Count) then Row:=FDataRetentionRows[DataRetentionList.ItemIndex];
 DataRetentionOpen.Enabled:=Row<>nil;DataRetentionLinks.Enabled:=Row<>nil;
 DataRetentionMemo.Text:=TDPHWorkspaceView.DescribeDataRetentionPolicy(Row);
end;
procedure TDPHMainForm.DataRetentionNewClick(Sender:TObject);
var Policy:TJSONObject;
begin
 if FBusy or (FView=nil) then Exit;
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft before starting a retention policy.';Exit;end;
 NewKnowledgeClick(nil);FBinding:=True;
 try
  FKnowledgeLink:='';KnowledgeTitleEdit.Text:='Retention policy: enter descriptive data scope';
  Policy:=TJSONObject.Create.AddPair('record_type','data_retention').AddPair('policy_id',TGUID.NewGuid.ToString);
  try FKnowledgeStructuredJSON:=Policy.ToJSON;finally Policy.Free;end;
  KnowledgeBodyMemo.Text:=TDPHWorkspaceView.NewDataRetentionPolicy;
  KnowledgeKindCombo.ItemIndex:=KnowledgeKindCombo.Items.IndexOf('business_rule');
  KnowledgeDocumentCombo.ItemIndex:=KnowledgeDocumentCombo.Items.IndexOf('maintenance');
  KnowledgeAudienceCombo.ItemIndex:=KnowledgeAudienceCombo.Items.IndexOf('maintainer');
  KnowledgeKindCombo.Enabled:=False;KnowledgeDocumentCombo.Enabled:=False;KnowledgeAudienceCombo.Enabled:=False;
 finally FBinding:=False;end;
 FKnowledgeEdited:=True;WorkspaceTabs.ActiveTab:=KnowledgeTab;
 StatusLabel.Text:='Enter a descriptive title and named author. Complete the policy fields, preserve the first heading, add implementation links, then Save. Review separately.';
end;
procedure TDPHMainForm.DataRetentionOpenClick(Sender:TObject);
var Row:TJSONObject;ID:string;I:Integer;
begin
 if FBusy or (FView=nil) then Exit;
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft before opening another policy.';Exit;end;
 if (DataRetentionList.ItemIndex<0) or (DataRetentionList.ItemIndex>=FDataRetentionRows.Count) then Exit;
 Row:=FDataRetentionRows[DataRetentionList.ItemIndex];ID:=Row.GetValue<string>('id');
 PendingKnowledgeCheck.IsChecked:=False;KnowledgeFilterChange(nil);
 for I:=0 to FKnowledgeRows.Count-1 do if FKnowledgeRows[I].GetValue<string>('id')=ID then begin
  KnowledgeList.ItemIndex:=I;KnowledgeClick(nil);WorkspaceTabs.ActiveTab:=KnowledgeTab;
  if Sender=DataRetentionLinks then begin WorkspaceTabs.ActiveTab:=KnowledgeLinksTab;StatusLabel.Text:='Select a saved link and Open target, or search a captured routine/procedure and Add link. Return to Knowledge and Save edits.';end;
  Exit;
 end;
end;

procedure TDPHMainForm.TargetRecoveryFilterChange(Sender:TObject);
var V:TJSONValue;Row:TJSONObject;Count:Integer;Query,StateFilter:string;
begin
 if FTargetRecoveryRows=nil then Exit;
 if Sender=TargetRecoveryNext then Inc(FTargetRecoveryOffset,250) else FTargetRecoveryOffset:=0;
 FTargetRecoveryRows.Clear;TargetRecoveryList.Items.Clear;TargetRecoveryNext.Enabled:=False;TargetRecoveryNew.Enabled:=FView<>nil;
 TargetRecoverySelectionChange(nil);
 if (FView=nil) or (FKnowledge=nil) then begin TargetRecoveryStatus.Text:='Open a captured project, then New plan to record its target-data requirements.';Exit;end;
 Query:=TargetRecoveryFilter.Text.Trim;StateFilter:='';if TargetRecoveryState.ItemIndex>0 then StateFilter:=TargetRecoveryState.Selected.Text;Count:=0;
 for V in FKnowledge do begin Row:=V as TJSONObject;
  if not TDPHWorkspaceView.IsTargetRecoveryPlan(Row) then Continue;
  if (StateFilter<>'') and (Row.GetValue<string>('state')<>StateFilter) then Continue;
  if (Query<>'') and not ContainsText(TDPHWorkspaceView.DescribeTargetRecoveryPlan(Row),Query) then Continue;
  if (Count>=FTargetRecoveryOffset) and (FTargetRecoveryRows.Count<250) then begin
   FTargetRecoveryRows.Add(Row);TargetRecoveryList.Items.Add('['+Row.GetValue<string>('state')+'] '+Row.GetValue<string>('title')+' | '+Row.GetValue<string>('owner'));
  end;Inc(Count);
 end;
 TargetRecoveryNext.Enabled:=Count>FTargetRecoveryOffset+FTargetRecoveryRows.Count;
 TargetRecoveryStatus.Text:=IntToStr(Count)+' saved plans match; '+IntToStr(FTargetRecoveryRows.Count)+' shown from '+IntToStr(FTargetRecoveryOffset)+'. Review state is a human assessment; unknown fields remain unresolved.';
 if TargetRecoveryList.Count>0 then TargetRecoveryList.ItemIndex:=0;
 TargetRecoverySelectionChange(nil);
end;
procedure TDPHMainForm.TargetRecoverySelectionChange(Sender:TObject);
var Row:TJSONObject;
begin
 Row:=nil;if (FTargetRecoveryRows<>nil) and (TargetRecoveryList.ItemIndex>=0) and (TargetRecoveryList.ItemIndex<FTargetRecoveryRows.Count) then Row:=FTargetRecoveryRows[TargetRecoveryList.ItemIndex];
 TargetRecoveryOpen.Enabled:=Row<>nil;TargetRecoveryLinks.Enabled:=Row<>nil;
 TargetRecoveryMemo.Text:=TDPHWorkspaceView.DescribeTargetRecoveryPlan(Row);
end;
procedure TDPHMainForm.TargetRecoveryNewClick(Sender:TObject);
var Policy:TJSONObject;
begin
 if FBusy or (FView=nil) then Exit;
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft before starting a recovery plan.';Exit;end;
 NewKnowledgeClick(nil);FBinding:=True;
 try
  FKnowledgeLink:='';KnowledgeTitleEdit.Text:='Recovery plan: enter descriptive data scope';
  Policy:=TJSONObject.Create.AddPair('record_type','target_recovery').AddPair('plan_id',TGUID.NewGuid.ToString);
  try FKnowledgeStructuredJSON:=Policy.ToJSON;finally Policy.Free;end;
  KnowledgeBodyMemo.Text:=TDPHWorkspaceView.NewTargetRecoveryPlan;
  KnowledgeKindCombo.ItemIndex:=KnowledgeKindCombo.Items.IndexOf('business_rule');
  KnowledgeDocumentCombo.ItemIndex:=KnowledgeDocumentCombo.Items.IndexOf('maintenance');
  KnowledgeAudienceCombo.ItemIndex:=KnowledgeAudienceCombo.Items.IndexOf('maintainer');
  KnowledgeKindCombo.Enabled:=False;KnowledgeDocumentCombo.Enabled:=False;KnowledgeAudienceCombo.Enabled:=False;
 finally FBinding:=False;end;
 FKnowledgeEdited:=True;WorkspaceTabs.ActiveTab:=KnowledgeTab;
 StatusLabel.Text:='Enter a descriptive title and named author. Complete the plan fields, preserve the first heading, add implementation links, then Save. Review separately.';
end;
procedure TDPHMainForm.TargetRecoveryOpenClick(Sender:TObject);
var Row:TJSONObject;ID:string;I:Integer;
begin
 if FBusy or (FView=nil) then Exit;
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft before opening another plan.';Exit;end;
 if (TargetRecoveryList.ItemIndex<0) or (TargetRecoveryList.ItemIndex>=FTargetRecoveryRows.Count) then Exit;
 Row:=FTargetRecoveryRows[TargetRecoveryList.ItemIndex];ID:=Row.GetValue<string>('id');
 PendingKnowledgeCheck.IsChecked:=False;KnowledgeFilterChange(nil);
 for I:=0 to FKnowledgeRows.Count-1 do if FKnowledgeRows[I].GetValue<string>('id')=ID then begin
  KnowledgeList.ItemIndex:=I;KnowledgeClick(nil);WorkspaceTabs.ActiveTab:=KnowledgeTab;
  if Sender=TargetRecoveryLinks then begin WorkspaceTabs.ActiveTab:=KnowledgeLinksTab;StatusLabel.Text:='Select a saved link and Open target, or search a captured routine/procedure and Add link. Return to Knowledge and Save edits.';end;
  Exit;
 end;
end;

procedure TDPHMainForm.BusinessProcessFilterChange(Sender:TObject);
var V:TJSONValue;Row:TJSONObject;Count:Integer;Query,StateFilter:string;
begin
 if FBusinessProcessRows=nil then Exit;
 if Sender=BusinessProcessNext then Inc(FBusinessProcessOffset,250) else FBusinessProcessOffset:=0;
 FBusinessProcessRows.Clear;BusinessProcessList.Items.Clear;BusinessProcessNext.Enabled:=False;BusinessProcessNew.Enabled:=FView<>nil;
 BusinessProcessSelectionChange(nil);
 if (FView=nil) or (FKnowledge=nil) then begin BusinessProcessStatus.Text:='Open a captured project, then New process to record its business process.';Exit;end;
 Query:=BusinessProcessFilter.Text.Trim;StateFilter:='';if BusinessProcessState.ItemIndex>0 then StateFilter:=BusinessProcessState.Selected.Text;Count:=0;
 for V in FKnowledge do begin Row:=V as TJSONObject;
  if not TDPHWorkspaceView.IsBusinessProcess(Row) then Continue;
  if (StateFilter<>'') and (Row.GetValue<string>('state')<>StateFilter) then Continue;
  if (Query<>'') and not ContainsText(TDPHWorkspaceView.DescribeBusinessProcess(Row),Query) then Continue;
  if (Count>=FBusinessProcessOffset) and (FBusinessProcessRows.Count<250) then begin
   FBusinessProcessRows.Add(Row);BusinessProcessList.Items.Add('['+Row.GetValue<string>('state')+'] '+Row.GetValue<string>('title')+' | '+Row.GetValue<string>('owner'));
  end;Inc(Count);
 end;
 BusinessProcessNext.Enabled:=Count>FBusinessProcessOffset+FBusinessProcessRows.Count;
 BusinessProcessStatus.Text:=IntToStr(Count)+' saved processes match; '+IntToStr(FBusinessProcessRows.Count)+' shown from '+IntToStr(FBusinessProcessOffset)+'. Review state is a human assessment; unknown fields remain unresolved.';
 if BusinessProcessList.Count>0 then BusinessProcessList.ItemIndex:=0;
 BusinessProcessSelectionChange(nil);
end;
procedure TDPHMainForm.BusinessProcessSelectionChange(Sender:TObject);
var Row:TJSONObject;
begin
 Row:=nil;if (FBusinessProcessRows<>nil) and (BusinessProcessList.ItemIndex>=0) and (BusinessProcessList.ItemIndex<FBusinessProcessRows.Count) then Row:=FBusinessProcessRows[BusinessProcessList.ItemIndex];
 BusinessProcessEdit.Enabled:=Row<>nil;BusinessProcessOpen.Enabled:=Row<>nil;BusinessProcessLinks.Enabled:=Row<>nil;
 BusinessProcessMemo.Text:=TDPHWorkspaceView.DescribeBusinessProcess(Row);
end;
procedure TDPHMainForm.BusinessProcessNewClick(Sender:TObject);
begin BusinessProcessEditClick(BusinessProcessNew);end;
procedure TDPHMainForm.BusinessProcessOpenClick(Sender:TObject);
var Row:TJSONObject;ID:string;I:Integer;
begin
 if FBusy or (FView=nil) then Exit;
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft before opening another process.';Exit;end;
 if (BusinessProcessList.ItemIndex<0) or (BusinessProcessList.ItemIndex>=FBusinessProcessRows.Count) then Exit;
 Row:=FBusinessProcessRows[BusinessProcessList.ItemIndex];ID:=Row.GetValue<string>('id');
 PendingKnowledgeCheck.IsChecked:=False;KnowledgeFilterChange(nil);
 for I:=0 to FKnowledgeRows.Count-1 do if FKnowledgeRows[I].GetValue<string>('id')=ID then begin
  KnowledgeList.ItemIndex:=I;KnowledgeClick(nil);WorkspaceTabs.ActiveTab:=KnowledgeTab;
  if Sender=BusinessProcessLinks then begin WorkspaceTabs.ActiveTab:=KnowledgeLinksTab;StatusLabel.Text:='Select a saved link and Open target, or search a captured routine/procedure and Add link. Return to Knowledge and Save edits.';end;
  Exit;
 end;
end;

procedure TDPHMainForm.BusinessRuleFilterChange(Sender:TObject);
var V:TJSONValue;Row,RecordValue:TJSONObject;Count:Integer;Query,StateFilter,Code:string;
begin
 if FBusinessRuleRows=nil then Exit;
 if Sender=BusinessRuleNext then Inc(FBusinessRuleOffset,250) else FBusinessRuleOffset:=0;
 FBusinessRuleRows.Clear;BusinessRuleList.Items.Clear;BusinessRuleNext.Enabled:=False;BusinessRuleNew.Enabled:=FView<>nil;
 BusinessRuleSelectionChange(nil);
 if (FView=nil) or (FKnowledge=nil) then begin BusinessRuleStatus.Text:='Open a captured project, then New rule to record its business rule.';Exit;end;
 Query:=BusinessRuleFilter.Text.Trim;StateFilter:='';if BusinessRuleState.ItemIndex>0 then StateFilter:=BusinessRuleState.Selected.Text;Count:=0;
 for V in FKnowledge do begin Row:=V as TJSONObject;
  if not TDPHWorkspaceView.IsBusinessRule(Row) then Continue;
  if (StateFilter<>'') and (Row.GetValue<string>('state')<>StateFilter) then Continue;
  if (Query<>'') and not ContainsText(TDPHWorkspaceView.DescribeBusinessRule(Row),Query) then Continue;
  if (Count>=FBusinessRuleOffset) and (FBusinessRuleRows.Count<250) then begin
   RecordValue:=TJSONObject.ParseJSONValue(Row.GetValue<string>('structured_json','{}')) as TJSONObject;
   try Code:=RecordValue.GetValue<string>('fields.rule_code','Unstructured');finally RecordValue.Free;end;
   FBusinessRuleRows.Add(Row);BusinessRuleList.Items.Add('['+Row.GetValue<string>('state')+'] '+Code+' | '+Row.GetValue<string>('title')+' | '+Row.GetValue<string>('owner'));
  end;Inc(Count);
 end;
 BusinessRuleNext.Enabled:=Count>FBusinessRuleOffset+FBusinessRuleRows.Count;
 BusinessRuleStatus.Text:=IntToStr(Count)+' saved rules match; '+IntToStr(FBusinessRuleRows.Count)+' shown from '+IntToStr(FBusinessRuleOffset)+'. Review state is a human assessment; unknown fields remain unresolved.';
 if BusinessRuleList.Count>0 then BusinessRuleList.ItemIndex:=0;
 BusinessRuleSelectionChange(nil);
end;
procedure TDPHMainForm.BusinessRuleSelectionChange(Sender:TObject);
var Row:TJSONObject;
begin
 Row:=nil;if (FBusinessRuleRows<>nil) and (BusinessRuleList.ItemIndex>=0) and (BusinessRuleList.ItemIndex<FBusinessRuleRows.Count) then Row:=FBusinessRuleRows[BusinessRuleList.ItemIndex];
 BusinessRuleEdit.Enabled:=(Row<>nil);if Row<>nil then BusinessRuleEdit.Enabled:=Row.GetValue<string>('structured_json','{}')<>'{}';BusinessRuleOpen.Enabled:=Row<>nil;BusinessRuleLinks.Enabled:=Row<>nil;
 BusinessRuleMemo.Text:=TDPHWorkspaceView.DescribeBusinessRule(Row);
end;
procedure TDPHMainForm.BusinessRuleNewClick(Sender:TObject);
begin BusinessRuleEditClick(BusinessRuleNew);end;
procedure TDPHMainForm.BusinessRuleOpenClick(Sender:TObject);
var Row:TJSONObject;ID:string;I:Integer;
begin
 if FBusy or (FView=nil) then Exit;
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft before opening another rule.';Exit;end;
 if (BusinessRuleList.ItemIndex<0) or (BusinessRuleList.ItemIndex>=FBusinessRuleRows.Count) then Exit;
 Row:=FBusinessRuleRows[BusinessRuleList.ItemIndex];ID:=Row.GetValue<string>('id');
 PendingKnowledgeCheck.IsChecked:=False;KnowledgeFilterChange(nil);
 for I:=0 to FKnowledgeRows.Count-1 do if FKnowledgeRows[I].GetValue<string>('id')=ID then begin
  KnowledgeList.ItemIndex:=I;KnowledgeClick(nil);WorkspaceTabs.ActiveTab:=KnowledgeTab;
  if Sender=BusinessRuleLinks then begin WorkspaceTabs.ActiveTab:=KnowledgeLinksTab;StatusLabel.Text:='Select a saved link and Open target, or search a captured routine/procedure and Add link. Return to Knowledge and Save edits.';end;
  Exit;
 end;
end;

procedure TDPHMainForm.DepartmentalWorkflowFilterChange(Sender:TObject);
var V:TJSONValue;Row:TJSONObject;Count:Integer;Query,StateFilter:string;
begin
 if FDepartmentalWorkflowRows=nil then Exit;
 if Sender=DepartmentalWorkflowNext then Inc(FDepartmentalWorkflowOffset,250) else FDepartmentalWorkflowOffset:=0;
 FDepartmentalWorkflowRows.Clear;DepartmentalWorkflowList.Items.Clear;DepartmentalWorkflowNext.Enabled:=False;DepartmentalWorkflowNew.Enabled:=FView<>nil;
 DepartmentalWorkflowSelectionChange(nil);
 if (FView=nil) or (FKnowledge=nil) then begin DepartmentalWorkflowStatus.Text:='Open a captured project, then New workflow to record its departmental workflow.';Exit;end;
 Query:=DepartmentalWorkflowFilter.Text.Trim;StateFilter:='';if DepartmentalWorkflowState.ItemIndex>0 then StateFilter:=DepartmentalWorkflowState.Selected.Text;Count:=0;
 for V in FKnowledge do begin Row:=V as TJSONObject;
  if not TDPHWorkspaceView.IsDepartmentalWorkflow(Row) then Continue;
  if (StateFilter<>'') and (Row.GetValue<string>('state')<>StateFilter) then Continue;
  if (Query<>'') and not ContainsText(TDPHWorkspaceView.DescribeDepartmentalWorkflow(Row),Query) then Continue;
  if (Count>=FDepartmentalWorkflowOffset) and (FDepartmentalWorkflowRows.Count<250) then begin
   FDepartmentalWorkflowRows.Add(Row);DepartmentalWorkflowList.Items.Add('['+Row.GetValue<string>('state')+'] '+Row.GetValue<string>('title')+' | '+Row.GetValue<string>('owner'));
  end;Inc(Count);
 end;
 DepartmentalWorkflowNext.Enabled:=Count>FDepartmentalWorkflowOffset+FDepartmentalWorkflowRows.Count;
 DepartmentalWorkflowStatus.Text:=IntToStr(Count)+' saved workflows match; '+IntToStr(FDepartmentalWorkflowRows.Count)+' shown from '+IntToStr(FDepartmentalWorkflowOffset)+'. Review state is a human assessment; unknown fields remain unresolved.';
 if DepartmentalWorkflowList.Count>0 then DepartmentalWorkflowList.ItemIndex:=0;
 DepartmentalWorkflowSelectionChange(nil);
end;
procedure TDPHMainForm.DepartmentalWorkflowSelectionChange(Sender:TObject);
var Row:TJSONObject;
begin
 Row:=nil;if (FDepartmentalWorkflowRows<>nil) and (DepartmentalWorkflowList.ItemIndex>=0) and (DepartmentalWorkflowList.ItemIndex<FDepartmentalWorkflowRows.Count) then Row:=FDepartmentalWorkflowRows[DepartmentalWorkflowList.ItemIndex];
 DepartmentalWorkflowDiagram.Enabled:=Row<>nil;DepartmentalWorkflowEdit.Enabled:=Row<>nil;DepartmentalWorkflowOpen.Enabled:=Row<>nil;DepartmentalWorkflowLinks.Enabled:=Row<>nil;
 DepartmentalWorkflowMemo.Text:=TDPHWorkspaceView.DescribeDepartmentalWorkflow(Row);
end;
procedure TDPHMainForm.DepartmentalWorkflowDiagramClick(Sender:TObject);
var Row:TJSONObject;HTML,GraphPath:string;
begin
 if FBusy or (FView=nil) then Exit;
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft before opening a saved workflow diagram.';Exit;end;
 if (DepartmentalWorkflowList.ItemIndex<0) or (DepartmentalWorkflowList.ItemIndex>=FDepartmentalWorkflowRows.Count) then Exit;
 Row:=FDepartmentalWorkflowRows[DepartmentalWorkflowList.ItemIndex];
 try
  GraphCombo.ItemIndex:=GraphCombo.Items.IndexOf('Business process');
  FreeAndNil(FGraph);FGraph:=TDPHGraphProjection.Workflow(Row,FKnowledge,FView.Document.GetValue<Int64>('generation_id'));
  GraphGroupingCombo.Enabled:=False;
  GraphLegend.Text:='Authored business workflow | blue: normal sequence | orange: exception routes | select steps for details | exact process links retain revision review; runtime unobserved';
  GraphPaint.Height:=Max(4500,FGraph.GetValue<TJSONArray>('nodes').Count*190+40);GraphPaint.Repaint;
  HTML:=FExplanations.GraphHTML(FGraph);GraphPath:=TPath.Combine(FFlowDirectory,THashSHA2.GetHashString(HTML)+'.html');
  if not FPreviewPages.Contains(GraphPath) then begin TFile.WriteAllBytes(GraphPath,TEncoding.UTF8.GetBytes(HTML));FPreviewPages.Add(GraphPath);end;
  WorkspaceTabs.ActiveTab:=GraphTab;FlowBrowser.Visible:=False;
  try FlowBrowser.WindowsEngine:=TWindowsEngine.EdgeOnly;FlowBrowser.Navigate('file://'+GraphPath);FlowBrowser.Visible:=True;
  except on E:Exception do StatusLabel.Text:='Browser diagram unavailable; the native diagram remains available: '+E.Message;end;
 except on E:Exception do begin FreeAndNil(FGraph);StatusLabel.Text:=E.Message;end;end;
end;
procedure TDPHMainForm.DepartmentalWorkflowNewClick(Sender:TObject);
begin DepartmentalWorkflowEditClick(DepartmentalWorkflowNew);end;
procedure TDPHMainForm.DepartmentalWorkflowOpenClick(Sender:TObject);
var Row:TJSONObject;ID:string;I:Integer;
begin
 if FBusy or (FView=nil) then Exit;
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft before opening another workflow.';Exit;end;
 if (DepartmentalWorkflowList.ItemIndex<0) or (DepartmentalWorkflowList.ItemIndex>=FDepartmentalWorkflowRows.Count) then Exit;
 Row:=FDepartmentalWorkflowRows[DepartmentalWorkflowList.ItemIndex];ID:=Row.GetValue<string>('id');
 PendingKnowledgeCheck.IsChecked:=False;KnowledgeFilterChange(nil);
 for I:=0 to FKnowledgeRows.Count-1 do if FKnowledgeRows[I].GetValue<string>('id')=ID then begin
  KnowledgeList.ItemIndex:=I;KnowledgeClick(nil);WorkspaceTabs.ActiveTab:=KnowledgeTab;
  if Sender=DepartmentalWorkflowLinks then begin WorkspaceTabs.ActiveTab:=KnowledgeLinksTab;StatusLabel.Text:='Select a saved link and Open target, or search a captured routine/procedure and Add link. Return to Knowledge and Save edits.';end;
  Exit;
 end;
end;

procedure TDPHMainForm.BusinessProcessEditClick(Sender:TObject);
var RecordValue,Fields:TJSONObject;Key:string;
begin
 if FBusy or (FView=nil) then Exit;
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft before editing a process.';Exit;end;
 if Sender=BusinessProcessNew then begin NewKnowledgeClick(nil);RecordValue:=TDPHWorkspaceView.NewBusinessProcess;end
 else begin
  if BusinessProcessList.ItemIndex<0 then Exit;
  BusinessProcessOpenClick(nil);
  RecordValue:=TJSONObject.ParseJSONValue(FKnowledgeStructuredJSON) as TJSONObject;
  if (RecordValue=nil) or (RecordValue.GetValue<string>('record_type','')<>'business_process') then begin RecordValue.Free;Exit;end;
 end;
 try
  FKnowledgeStructuredJSON:=RecordValue.ToJSON;FStructuredEditorID:=RecordValue.GetValue<string>('process_id');FStructuredEditorPending:=True;Fields:=RecordValue.GetValue<TJSONObject>('fields');
  for Key in DPHBusinessProcessKeys do (FindComponent('Process_'+Key) as TMemo).Text:=Fields.GetValue<string>(Key,'Unknown');
  Process_name.ReadOnly:=FKnowledgeID<>0;BusinessProcessAuthor.Text:=KnowledgeAuthorEdit.Text;
 finally RecordValue.Free;end;
 FKnowledgeEdited:=True;WorkspaceTabs.ActiveTab:=BusinessProcessEditorTab;
 StatusLabel.Text:='Complete the process fields, enter a named contributor and Apply to Knowledge draft. Then Save, add source links and review.';
end;
procedure TDPHMainForm.BusinessProcessApplyClick(Sender:TObject);
var RecordValue,Fields:TJSONObject;Key:string;
begin
 if FBusy or (FView=nil) or not FKnowledgeEdited then Exit;
 RecordValue:=TJSONObject.ParseJSONValue(FKnowledgeStructuredJSON) as TJSONObject;
 try
  try
   if (RecordValue=nil) or (RecordValue.GetValue<string>('record_type','')<>'business_process') or (RecordValue.GetValue<string>('process_id','')<>FStructuredEditorID) then raise EArgumentException.Create('Reopen this process with Edit fields before applying');
   Fields:=RecordValue.GetValue<TJSONObject>('fields');
   for Key in DPHBusinessProcessKeys do begin Fields.RemovePair(Key).Free;Fields.AddPair(Key,(FindComponent('Process_'+Key) as TMemo).Text.Trim);end;
   TDPHWorkspaceView.ValidateBusinessProcess(RecordValue);
   if BusinessProcessAuthor.Text.Trim='' then raise EArgumentException.Create('Enter a named contributor');
   FBinding:=True;
   try
    KnowledgeTitleEdit.Text:=Fields.GetValue<string>('name').Trim;KnowledgeAuthorEdit.Text:=BusinessProcessAuthor.Text.Trim;
    KnowledgeBodyMemo.Text:=TDPHWorkspaceView.BusinessProcessBody(RecordValue);KnowledgeBodyMemo.ReadOnly:=True;KnowledgeTitleEdit.ReadOnly:=True;
    KnowledgeKindCombo.ItemIndex:=KnowledgeKindCombo.Items.IndexOf('business_rule');KnowledgeDocumentCombo.ItemIndex:=KnowledgeDocumentCombo.Items.IndexOf('maintenance');KnowledgeAudienceCombo.ItemIndex:=KnowledgeAudienceCombo.Items.IndexOf('maintainer');
    KnowledgeKindCombo.Enabled:=False;KnowledgeDocumentCombo.Enabled:=False;KnowledgeAudienceCombo.Enabled:=False;
    FKnowledgeStructuredJSON:=RecordValue.ToJSON;FKnowledgeLink:='';FKnowledgeQuestionJSON:='';
   finally FBinding:=False;end;
   FStructuredEditorPending:=False;WorkspaceTabs.ActiveTab:=KnowledgeTab;StatusLabel.Text:='Process draft prepared. Click Save to persist. Add exact source links on Knowledge links, Save again and review separately.';
  except on E:Exception do StatusLabel.Text:=E.Message;end;
 finally RecordValue.Free;end;
end;

procedure TDPHMainForm.BusinessRuleEditClick(Sender:TObject);
var RecordValue,Fields:TJSONObject;Key:string;
begin
 if FBusy or (FView=nil) then Exit;
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft before editing a rule.';Exit;end;
 if Sender=BusinessRuleNew then begin NewKnowledgeClick(nil);RecordValue:=TDPHWorkspaceView.NewBusinessRule;end
 else begin
  if BusinessRuleList.ItemIndex<0 then Exit;
  BusinessRuleOpenClick(nil);
  RecordValue:=TJSONObject.ParseJSONValue(FKnowledgeStructuredJSON) as TJSONObject;
  if (RecordValue=nil) or (RecordValue.GetValue<string>('record_type','')<>'business_rule_definition') then begin RecordValue.Free;Exit;end;
 end;
 try
  FKnowledgeStructuredJSON:=RecordValue.ToJSON;FStructuredEditorID:=RecordValue.GetValue<string>('rule_id');FStructuredEditorPending:=True;Fields:=RecordValue.GetValue<TJSONObject>('fields');
  for Key in DPHBusinessRuleKeys do (FindComponent('Rule_'+Key) as TMemo).Text:=Fields.GetValue<string>(Key,'Unknown');
  Rule_name.ReadOnly:=FKnowledgeID<>0;Rule_rule_code.ReadOnly:=FKnowledgeID<>0;BusinessRuleAuthor.Text:=KnowledgeAuthorEdit.Text;
 finally RecordValue.Free;end;
 FKnowledgeEdited:=True;WorkspaceTabs.ActiveTab:=BusinessRuleEditorTab;
 StatusLabel.Text:='Complete the rule fields, enter a named contributor and Apply to Knowledge draft. Then Save, add source links and review.';
end;
procedure TDPHMainForm.BusinessRuleApplyClick(Sender:TObject);
var RecordValue,Fields:TJSONObject;Key:string;
begin
 if FBusy or (FView=nil) or not FKnowledgeEdited then Exit;
 RecordValue:=TJSONObject.ParseJSONValue(FKnowledgeStructuredJSON) as TJSONObject;
 try
  try
   if (RecordValue=nil) or (RecordValue.GetValue<string>('record_type','')<>'business_rule_definition') or (RecordValue.GetValue<string>('rule_id','')<>FStructuredEditorID) then raise EArgumentException.Create('Reopen this rule with Edit fields before applying');
   Fields:=RecordValue.GetValue<TJSONObject>('fields');
   for Key in DPHBusinessRuleKeys do begin Fields.RemovePair(Key).Free;Fields.AddPair(Key,(FindComponent('Rule_'+Key) as TMemo).Text.Trim);end;
   TDPHWorkspaceView.ValidateBusinessRule(RecordValue);
   if BusinessRuleAuthor.Text.Trim='' then raise EArgumentException.Create('Enter a named contributor');
   FBinding:=True;
   try
    KnowledgeTitleEdit.Text:=Fields.GetValue<string>('name').Trim;KnowledgeAuthorEdit.Text:=BusinessRuleAuthor.Text.Trim;
    KnowledgeBodyMemo.Text:=TDPHWorkspaceView.BusinessRuleBody(RecordValue);KnowledgeBodyMemo.ReadOnly:=True;KnowledgeTitleEdit.ReadOnly:=True;
    KnowledgeKindCombo.ItemIndex:=KnowledgeKindCombo.Items.IndexOf('business_rule');KnowledgeDocumentCombo.ItemIndex:=KnowledgeDocumentCombo.Items.IndexOf('maintenance');KnowledgeAudienceCombo.ItemIndex:=KnowledgeAudienceCombo.Items.IndexOf('maintainer');
    KnowledgeKindCombo.Enabled:=False;KnowledgeDocumentCombo.Enabled:=False;KnowledgeAudienceCombo.Enabled:=False;
    FKnowledgeStructuredJSON:=RecordValue.ToJSON;FKnowledgeLink:='';FKnowledgeQuestionJSON:='';
   finally FBinding:=False;end;
   FStructuredEditorPending:=False;WorkspaceTabs.ActiveTab:=KnowledgeTab;StatusLabel.Text:='Rule draft prepared. Click Save to persist. Add exact source links on Knowledge links, Save again and review separately.';
  except on E:Exception do StatusLabel.Text:=E.Message;end;
 finally RecordValue.Free;end;
end;

procedure TDPHMainForm.DepartmentalWorkflowEditClick(Sender:TObject);
var Fields:TJSONObject;Key:string;
begin
 if FBusy or (FView=nil) then Exit;
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft before editing a workflow.';Exit;end;
 if Sender=DepartmentalWorkflowNew then begin NewKnowledgeClick(nil);FWorkflowDraft:=TDPHWorkspaceView.NewDepartmentalWorkflow;end
 else begin
  if DepartmentalWorkflowList.ItemIndex<0 then Exit;
  DepartmentalWorkflowOpenClick(nil);FreeAndNil(FWorkflowDraft);
  FWorkflowDraft:=TJSONObject.ParseJSONValue(FKnowledgeStructuredJSON) as TJSONObject;
  if (FWorkflowDraft=nil) or (FWorkflowDraft.GetValue<string>('record_type','')<>'departmental_workflow') then begin FreeAndNil(FWorkflowDraft);Exit;end;
 end;
 FBinding:=True;
 try
  Fields:=FWorkflowDraft.GetValue<TJSONObject>('fields');
  for Key in DPHWorkflowKeys do (FindComponent('Workflow_'+Key) as TMemo).Text:=Fields.GetValue<string>(Key,'Unknown');
  Workflow_name.ReadOnly:=FKnowledgeID<>0;WorkflowAuthor.Text:=KnowledgeAuthorEdit.Text;
  FWorkflowStepIndex:=-1;FWorkflowStepDirty:=False;
 finally FBinding:=False;end;
 FKnowledgeStructuredJSON:=FWorkflowDraft.ToJSON;FStructuredEditorID:=FWorkflowDraft.GetValue<string>('workflow_id');FStructuredEditorPending:=True;FKnowledgeEdited:=True;RefreshWorkflowSteps;WorkspaceTabs.ActiveTab:=WorkflowEditorTab;
 StatusLabel.Text:='Complete workflow fields and add ordered steps. Apply step keeps it in this draft; Apply workflow prepares Knowledge. Save and review separately.';
end;
procedure TDPHMainForm.RefreshWorkflowSteps;
var Steps:TJSONArray;V:TJSONValue;I:Integer;
begin
 if FWorkflowDraft=nil then Exit;
 Steps:=FWorkflowDraft.GetValue<TJSONArray>('steps');FBinding:=True;
 try
  WorkflowSteps.Items.Clear;WorkflowExceptionTarget.Items.Clear;WorkflowExceptionTarget.Items.Add('Unknown');WorkflowExceptionTarget.Items.Add('End');
  I:=0;for V in Steps do begin Inc(I);WorkflowSteps.Items.Add(IntToStr(I)+'. '+V.GetValue<string>('department')+' | '+V.GetValue<string>('role')+' | '+V.GetValue<string>('action'));WorkflowExceptionTarget.Items.Add('Step '+IntToStr(I)+': '+V.GetValue<string>('action'));end;
  WorkflowSteps.ItemIndex:=FWorkflowStepIndex;
 finally FBinding:=False;end;
 WorkflowStepClick(nil);
end;
procedure TDPHMainForm.WorkflowStepClick(Sender:TObject);
var Steps:TJSONArray;Step:TJSONObject;Key,Target:string;I:Integer;
begin
 if FBinding or (FWorkflowDraft=nil) then Exit;
 if FWorkflowStepDirty then begin FBinding:=True;try WorkflowSteps.ItemIndex:=FWorkflowStepIndex;finally FBinding:=False;end;StatusLabel.Text:='Apply step or discard step changes before selecting another step.';Exit;end;
 Steps:=FWorkflowDraft.GetValue<TJSONArray>('steps');FWorkflowStepIndex:=WorkflowSteps.ItemIndex;Step:=nil;
 if (FWorkflowStepIndex>=0) and (FWorkflowStepIndex<Steps.Count) then Step:=Steps.Items[FWorkflowStepIndex] as TJSONObject;
 FBinding:=True;
 try
  for Key in DPHWorkflowStepKeys do if Key<>'exception_target' then begin
   (FindComponent('Step_'+Key) as TMemo).Text:='';if Step<>nil then (FindComponent('Step_'+Key) as TMemo).Text:=Step.GetValue<string>(Key);
  end;
  WorkflowExceptionTarget.ItemIndex:=0;
  if Step<>nil then begin Target:=Step.GetValue<string>('exception_target');if Target='End' then WorkflowExceptionTarget.ItemIndex:=1;
   for I:=0 to Steps.Count-1 do if Steps.Items[I].GetValue<string>('step_id')=Target then WorkflowExceptionTarget.ItemIndex:=I+2;
  end;
 finally FBinding:=False;end;
end;
procedure TDPHMainForm.StructuredEditorChange(Sender:TObject);
var RecordValue:TJSONValue;ID:string;
begin
 if FBinding or (FView=nil) or (FStructuredEditorID='') then Exit;
 RecordValue:=TJSONObject.ParseJSONValue(FKnowledgeStructuredJSON);
 try
  if not (RecordValue is TJSONObject) then Exit;
  ID:=RecordValue.GetValue<string>('process_id',RecordValue.GetValue<string>('workflow_id',RecordValue.GetValue<string>('rule_id','')));
  if ID<>FStructuredEditorID then begin StatusLabel.Text:='Reopen the record with Edit fields before changing these fields.';Exit;end;
  FStructuredEditorPending:=True;FKnowledgeEdited:=True;
 finally RecordValue.Free;end;
end;
procedure TDPHMainForm.WorkflowStepChange(Sender:TObject);
begin if not FBinding and (FWorkflowDraft<>nil) then begin StructuredEditorChange(Sender);if FStructuredEditorPending then FWorkflowStepDirty:=True;end;end;
procedure TDPHMainForm.WorkflowStepAction(Sender:TObject);
var Steps:TJSONArray;Step:TJSONObject;Key,Target:string;V:TJSONValue;Index,I:Integer;Elements:TList<TJSONValue>;
begin
 if FBusy or (FView=nil) or (FWorkflowDraft=nil) or not FKnowledgeEdited then Exit;
 FStructuredEditorPending:=True;
 Steps:=FWorkflowDraft.GetValue<TJSONArray>('steps');
 try
  if Sender=WorkflowDiscardStep then begin FWorkflowStepDirty:=False;WorkflowStepClick(nil);Exit;end;
  if (Sender<>WorkflowSaveStep) and FWorkflowStepDirty then raise EArgumentException.Create('Apply step or discard step changes first');
  if Sender=WorkflowNewStep then begin
   if Steps.Count>=64 then raise EArgumentException.Create('Workflow is limited to 64 steps');
   Step:=TDPHWorkspaceView.NewWorkflowStep;
   try FBinding:=True;try for Key in DPHWorkflowStepKeys do if Key<>'exception_target' then (FindComponent('Step_'+Key) as TMemo).Text:=Step.GetValue<string>(Key);WorkflowExceptionTarget.ItemIndex:=0;WorkflowSteps.ItemIndex:=-1;FWorkflowStepIndex:=-1;finally FBinding:=False;end;finally Step.Free;end;
   FWorkflowStepDirty:=True;StatusLabel.Text:='Complete the new step action, department, role, inputs, outputs, handoff and exception path; then Apply step.';Exit;
  end;
  if Sender=WorkflowSaveStep then begin
   if not FWorkflowStepDirty then Exit;
   Step:=TJSONObject.Create;
   try
    for Key in DPHWorkflowStepKeys do if Key<>'exception_target' then Step.AddPair(Key,(FindComponent('Step_'+Key) as TMemo).Text.Trim);
    Target:='Unknown';Index:=WorkflowExceptionTarget.ItemIndex;
    if Index=1 then Target:='End' else if (Index>=2) and (Index-2<Steps.Count) then Target:=Steps.Items[Index-2].GetValue<string>('step_id');
    Step.AddPair('exception_target',Target);TDPHWorkspaceView.ValidateWorkflowStep(Step);
    if FWorkflowStepIndex<0 then begin Steps.AddElement(Step.Clone as TJSONObject);FWorkflowStepIndex:=Steps.Count-1;end
    else begin
     Elements:=TList<TJSONValue>.Create;
     for I:=0 to Steps.Count-1 do if I=FWorkflowStepIndex then Elements.Add(Step.Clone as TJSONObject) else Elements.Add(Steps.Items[I]);
     V:=Steps.Items[FWorkflowStepIndex];Steps.SetElements(Elements);V.Free;
    end;
   finally Step.Free;end;
   FWorkflowStepDirty:=False;RefreshWorkflowSteps;StatusLabel.Text:='Step applied to workflow draft. Apply workflow and Save to persist.';Exit;
  end;
  if (FWorkflowStepIndex<0) or (FWorkflowStepIndex>=Steps.Count) then Exit;
  if Sender=WorkflowRemoveStep then begin
   Target:=Steps.Items[FWorkflowStepIndex].GetValue<string>('step_id');
   for V in Steps do if (V.GetValue<string>('step_id')<>Target) and (V.GetValue<string>('exception_target')=Target) then raise EArgumentException.Create('Change the referring exception destination before removing this step');
   Steps.Remove(FWorkflowStepIndex).Free;FWorkflowStepIndex:=-1;
  end else begin Index:=FWorkflowStepIndex;
   if Sender=WorkflowStepUp then Dec(Index) else if Sender=WorkflowStepDown then Inc(Index) else Exit;
   if (Index<0) or (Index>=Steps.Count) then Exit;
   Elements:=TList<TJSONValue>.Create;for I:=0 to Steps.Count-1 do Elements.Add(Steps.Items[I]);
   Elements.Exchange(FWorkflowStepIndex,Index);Steps.SetElements(Elements);FWorkflowStepIndex:=Index;
  end;
  RefreshWorkflowSteps;
 except on E:Exception do StatusLabel.Text:=E.Message;end;
end;
procedure TDPHMainForm.WorkflowApplyClick(Sender:TObject);
var Fields:TJSONObject;Key:string;Current:TJSONValue;
begin
 if FBusy or (FView=nil) or (FWorkflowDraft=nil) or not FKnowledgeEdited then Exit;
 try
  Current:=TJSONObject.ParseJSONValue(FKnowledgeStructuredJSON);
  try if not (Current is TJSONObject) or (Current.GetValue<string>('workflow_id','')<>FStructuredEditorID) then raise EArgumentException.Create('Reopen this workflow with Edit fields before applying');finally Current.Free;end;
  if FWorkflowDraft.GetValue<string>('workflow_id')<>FStructuredEditorID then raise EArgumentException.Create('Reopen this workflow with Edit fields before applying');
  if FWorkflowStepDirty then raise EArgumentException.Create('Apply step or discard step changes before applying the workflow');
  Fields:=FWorkflowDraft.GetValue<TJSONObject>('fields');
  for Key in DPHWorkflowKeys do begin Fields.RemovePair(Key).Free;Fields.AddPair(Key,(FindComponent('Workflow_'+Key) as TMemo).Text.Trim);end;
  TDPHWorkspaceView.ValidateDepartmentalWorkflow(FWorkflowDraft);
  if WorkflowAuthor.Text.Trim='' then raise EArgumentException.Create('Enter a named contributor');
  FBinding:=True;
  try
   KnowledgeTitleEdit.Text:=Fields.GetValue<string>('name').Trim;KnowledgeAuthorEdit.Text:=WorkflowAuthor.Text.Trim;KnowledgeBodyMemo.Text:=TDPHWorkspaceView.DepartmentalWorkflowBody(FWorkflowDraft);
   KnowledgeTitleEdit.ReadOnly:=True;KnowledgeBodyMemo.ReadOnly:=True;
   KnowledgeKindCombo.ItemIndex:=KnowledgeKindCombo.Items.IndexOf('business_rule');KnowledgeDocumentCombo.ItemIndex:=KnowledgeDocumentCombo.Items.IndexOf('maintenance');KnowledgeAudienceCombo.ItemIndex:=KnowledgeAudienceCombo.Items.IndexOf('maintainer');
   KnowledgeKindCombo.Enabled:=False;KnowledgeDocumentCombo.Enabled:=False;KnowledgeAudienceCombo.Enabled:=False;FKnowledgeStructuredJSON:=FWorkflowDraft.ToJSON;FKnowledgeLink:='';FKnowledgeQuestionJSON:='';
  finally FBinding:=False;end;
  FStructuredEditorPending:=False;WorkspaceTabs.ActiveTab:=KnowledgeTab;StatusLabel.Text:='Workflow draft prepared. Save, add exact business-process/source/procedure links, Save again and review separately.';
 except on E:Exception do StatusLabel.Text:=E.Message;end;
end;

procedure TDPHMainForm.DataQualityFilterChange(Sender:TObject);
var V:TJSONValue;Row:TJSONObject;Count:Integer;Query,StateFilter:string;
begin
 if FDataQualityRows=nil then Exit;
 if Sender=DataQualityNext then Inc(FDataQualityOffset,250) else FDataQualityOffset:=0;
 FDataQualityRows.Clear;DataQualityList.Items.Clear;DataQualityNext.Enabled:=False;DataQualityNew.Enabled:=FView<>nil;DataQualityImport.Enabled:=FView<>nil;
 DataQualitySelectionChange(nil);
 if (FView=nil) or (FKnowledge=nil) then begin DataQualityStatus.Text:='Open a captured project, then New check to record its target-data requirements.';Exit;end;
 Query:=DataQualityFilter.Text.Trim;StateFilter:='';if DataQualityState.ItemIndex>0 then StateFilter:=DataQualityState.Selected.Text;Count:=0;
 for V in FKnowledge do begin Row:=V as TJSONObject;
  if not TDPHWorkspaceView.IsDataQualityRule(Row) then Continue;
  if (StateFilter<>'') and (Row.GetValue<string>('state')<>StateFilter) then Continue;
  if (Query<>'') and not ContainsText(TDPHWorkspaceView.DescribeDataQualityRule(Row),Query) then Continue;
  if (Count>=FDataQualityOffset) and (FDataQualityRows.Count<250) then begin
   FDataQualityRows.Add(Row);DataQualityList.Items.Add('['+Row.GetValue<string>('state')+'] '+Row.GetValue<string>('title')+' | '+Row.GetValue<string>('owner'));
  end;Inc(Count);
 end;
 DataQualityNext.Enabled:=Count>FDataQualityOffset+FDataQualityRows.Count;
 DataQualityStatus.Text:=IntToStr(Count)+' saved checks match; '+IntToStr(FDataQualityRows.Count)+' shown from '+IntToStr(FDataQualityOffset)+'. Review state is a human assessment; unknown fields remain unresolved.';
 if DataQualityList.Count>0 then DataQualityList.ItemIndex:=0;
 DataQualitySelectionChange(nil);
end;
procedure TDPHMainForm.DataQualitySelectionChange(Sender:TObject);
var Row:TJSONObject;
begin
 Row:=nil;if (FDataQualityRows<>nil) and (DataQualityList.ItemIndex>=0) and (DataQualityList.ItemIndex<FDataQualityRows.Count) then Row:=FDataQualityRows[DataQualityList.ItemIndex];
 DataQualityOpen.Enabled:=Row<>nil;DataQualityLinks.Enabled:=Row<>nil;
 DataQualityMemo.Text:=TDPHWorkspaceView.DescribeDataQualityRule(Row);
end;
procedure TDPHMainForm.DataQualityNewClick(Sender:TObject);
var Policy:TJSONObject;
begin
 if FBusy or (FView=nil) then Exit;
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft before starting a data quality rule.';Exit;end;
 NewKnowledgeClick(nil);FBinding:=True;
 try
  FKnowledgeLink:='';KnowledgeTitleEdit.Text:='Quality check: enter descriptive data scope';
  Policy:=TJSONObject.Create.AddPair('record_type','data_quality').AddPair('rule_id',TGUID.NewGuid.ToString);
  try FKnowledgeStructuredJSON:=Policy.ToJSON;finally Policy.Free;end;
  KnowledgeBodyMemo.Text:=TDPHWorkspaceView.NewDataQualityRule;
  KnowledgeKindCombo.ItemIndex:=KnowledgeKindCombo.Items.IndexOf('business_rule');
  KnowledgeDocumentCombo.ItemIndex:=KnowledgeDocumentCombo.Items.IndexOf('maintenance');
  KnowledgeAudienceCombo.ItemIndex:=KnowledgeAudienceCombo.Items.IndexOf('maintainer');
  KnowledgeKindCombo.Enabled:=False;KnowledgeDocumentCombo.Enabled:=False;KnowledgeAudienceCombo.Enabled:=False;
 finally FBinding:=False;end;
 FKnowledgeEdited:=True;WorkspaceTabs.ActiveTab:=KnowledgeTab;
 StatusLabel.Text:='Enter a descriptive title and named author. Complete the check fields, preserve the first heading, add implementation links, then Save. Review separately.';
end;
procedure TDPHMainForm.DataQualityOpenClick(Sender:TObject);
var Row:TJSONObject;ID:string;I:Integer;
begin
 if FBusy or (FView=nil) then Exit;
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft before opening another check.';Exit;end;
 if (DataQualityList.ItemIndex<0) or (DataQualityList.ItemIndex>=FDataQualityRows.Count) then Exit;
 Row:=FDataQualityRows[DataQualityList.ItemIndex];ID:=Row.GetValue<string>('id');
 PendingKnowledgeCheck.IsChecked:=False;KnowledgeFilterChange(nil);
 for I:=0 to FKnowledgeRows.Count-1 do if FKnowledgeRows[I].GetValue<string>('id')=ID then begin
  KnowledgeList.ItemIndex:=I;KnowledgeClick(nil);WorkspaceTabs.ActiveTab:=KnowledgeTab;
  if Sender=DataQualityLinks then begin WorkspaceTabs.ActiveTab:=KnowledgeLinksTab;StatusLabel.Text:='Select a saved link and Open target, or search a captured routine/procedure and Add link. Return to Knowledge and Save edits.';end;
  Exit;
 end;
end;

procedure TDPHMainForm.DataQualityImportClick(Sender:TObject);
var Request:TDPHWorkspaceRequest;
begin
 if FBusy or (FView=nil) then Exit;
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft before importing a check report.';Exit;end;
 if (DataQualityContributor.Text.Trim='') or (DataQualityContext.Text.Trim='') then begin StatusLabel.Text:='Enter the named report contributor and check/environment context before selecting a report.';Exit;end;
 if not ObservationDialog.Execute then Exit;
 Request:=Default(TDPHWorkspaceRequest);Request.Command:='import_data_quality';Request.Database:=FDatabase;Request.Entry:=FEntry;
 Request.GenerationID:=FView.Document.GetValue<Int64>('generation_id');Request.Body:=ObservationDialog.FileName;
 Request.Editor:=DataQualityContributor.Text;Request.Title:=DataQualityContext.Text;
 FWorker.Submit(Request);FBusy:=True;StatusLabel.Text:='Importing saved check evidence; no check or target program executes.';
end;
procedure TDPHMainForm.FileFormatsContractClick(Sender:TObject);
var Row:TJSONObject;Title:string;I:Integer;
begin
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft before recording a format contract.';Exit;end;
 if (FView=nil) or (FileFormatsList.ItemIndex<0) or (FileFormatsList.ItemIndex>=FFileFormatRows.Count) then Exit;
 Row:=FFileFormatRows[FileFormatsList.ItemIndex];Title:=TDPHWorkspaceView.FileFormatContractTitle(Row);
 PendingKnowledgeCheck.IsChecked:=False;KnowledgeFilterChange(nil);
 for I:=0 to FKnowledgeRows.Count-1 do if FKnowledgeRows[I].GetValue<string>('title')=Title then begin KnowledgeList.ItemIndex:=I;KnowledgeClick(nil);WorkspaceTabs.ActiveTab:=KnowledgeTab;Exit;end;
 NewKnowledgeClick(nil);FBinding:=True;
 try FKnowledgeLink:=Row.GetValue<string>('target_key');KnowledgeTitleEdit.Text:=Title;KnowledgeKindCombo.ItemIndex:=KnowledgeKindCombo.Items.IndexOf('engineering_rule');
  KnowledgeBodyMemo.Text:='FILE FORMAT CONTRACT - replace Unknown with reviewed facts; do not enter credentials or real customer data.'+sLineBreak+
   'Format name and version: Unknown'+sLineBreak+'Direction and business purpose: '+Row.GetValue<string>('direction')+sLineBreak+
   'Encoding and BOM policy: Unknown'+sLineBreak+'Schema / required and optional fields / types: Unknown'+sLineBreak+
   'Delimiter, quoting, escaping and line endings: Unknown'+sLineBreak+'Producer routine and input mapping: '+Row.GetValue<string>('producer')+sLineBreak+
   'Consumer routine and destination mapping: '+Row.GetValue<string>('consumer')+sLineBreak+'Validation, malformed input and partial failure: Unknown'+sLineBreak+
   'Compatibility and version migration: Unknown'+sLineBreak+'Verification procedure and evidence: Unknown'+sLineBreak+'Remaining unknowns and responsible maintainer: Unknown'+sLineBreak+sLineBreak+TDPHWorkspaceView.DescribeFileFormat(Row);
 finally FBinding:=False;end;
 FKnowledgeEdited:=True;WorkspaceTabs.ActiveTab:=KnowledgeTab;StatusLabel.Text:='Complete the format contract, enter the named author, and click Save. Review separately against evidence.';
end;

procedure TDPHMainForm.DatabaseSchemaFilterChange(Sender:TObject);
var V:TJSONValue;Row,SavedDictionary:TJSONObject;Count:Integer;Parameters:TJSONArray;ParameterText:string;
begin
 if FDatabaseSchemaRows=nil then Exit;
 if Sender=DatabaseSchemaNext then Inc(FDatabaseSchemaOffset,250) else FDatabaseSchemaOffset:=0;
 FDatabaseSchemaRows.Clear;DatabaseSchemaList.Items.Clear;DatabaseSchemaNext.Enabled:=False;DatabaseSchemaSelectionChange(nil);
 if FDatabaseSchema=nil then begin DatabaseSchemaStatus.Text:='Open a captured project to inspect tables, views and schemas.';Exit;end;
 Count:=0;
 for V in FDatabaseSchema.GetValue<TJSONArray>('rows') do begin Row:=V as TJSONObject;
  if (DatabaseSchemaKind.ItemIndex>0) and (Row.GetValue<string>('kind')<>DatabaseSchemaKind.Selected.Text) then Continue;
  if (DatabaseSchemaState.ItemIndex>0) and (Row.GetValue<string>('status')<>DatabaseSchemaState.Selected.Text) then Continue;
  ParameterText:=Row.GetValue<string>('target_version','')+' '+Row.GetValue<string>('filename_order','')+' '+Row.GetValue<string>('verification','')+' '+Row.GetValue<string>('order_basis','');if Row.TryGetValue<TJSONArray>('parameters',Parameters) then ParameterText:=Parameters.ToJSON;SavedDictionary:=TDPHDatabaseSchema.FindDictionary(FKnowledge,Row);if SavedDictionary<>nil then ParameterText:=ParameterText+' '+SavedDictionary.GetValue<string>('body');
  if (DatabaseSchemaFilter.Text.Trim<>'') and not ContainsText(Row.GetValue<string>('name')+' '+Row.GetValue<string>('schema')+' '+Row.GetValue<string>('source')+' '+Row.GetValue<string>('declared_type','')+' '+Row.GetValue<string>('nullability','')+' '+Row.GetValue<string>('constraints','')+' '+Row.GetValue<string>('key_kind','')+' '+Row.GetValue<string>('reference_table','')+' '+Row.GetValue<string>('relationship_status','')+' '+Row.GetValue<string>('table','')+' '+Row.GetValue<string>('method','')+' '+Row.GetValue<string>('predicate','')+' '+Row.GetValue<string>('storage_kind','')+' '+Row.GetValue<string>('storage_options','')+' '+Row.GetValue<string>('language','')+' '+Row.GetValue<string>('returns','')+' '+Row.GetValue<string>('trigger_table','')+' '+Row.GetValue<string>('events','')+' '+Row.GetValue<string>('body','')+' '+Row.GetValue<string>('timing','')+' '+Row.GetValue<string>('when','')+' '+ParameterText,DatabaseSchemaFilter.Text.Trim) then Continue;
  if (Count>=FDatabaseSchemaOffset) and (FDatabaseSchemaRows.Count<250) then begin FDatabaseSchemaRows.Add(Row);DatabaseSchemaList.Items.Add(Row.GetValue<string>('kind')+' | '+Row.GetValue<string>('name')+' | '+Row.GetValue<string>('status')+' | '+Row.GetValue<string>('source')+':'+Row.GetValue<TJSONObject>('range').GetValue('line').Value);end;Inc(Count);
 end;
 DatabaseSchemaNext.Enabled:=Count>FDatabaseSchemaOffset+FDatabaseSchemaRows.Count;
 DatabaseSchemaStatus.Text:=Format('%d matches; %d shown from %d. Captured declarations and references; deployed schema unverified.',[Count,FDatabaseSchemaRows.Count,FDatabaseSchemaOffset]);
 if DatabaseSchemaList.Count>0 then begin DatabaseSchemaList.ItemIndex:=0;DatabaseSchemaSelectionChange(nil);end
 else DatabaseSchemaMemo.Text:=FDatabaseSchema.GetValue<string>('qualification')+sLineBreak+sLineBreak+'No matching captured evidence. Clear filters or attach approved SQL scripts referenced by the project and reassess. Empty results do not prove the application has no schema.';
end;
procedure TDPHMainForm.DatabaseSchemaSelectionChange(Sender:TObject);
var Link:TJSONValue;ID,SchemaText:string;SavedDictionary:TJSONObject;
begin
 if FDatabaseSchemaTargets=nil then Exit;FDatabaseSchemaTargets.Clear;DatabaseSchemaLinks.Items.Clear;DatabaseSchemaFollow.Enabled:=False;
 DatabaseDictionaryEdit.Enabled:=False;DatabaseDictionaryKnowledge.Enabled:=False;
 DatabaseSchemaSource.Enabled:=False;DatabaseSchemaMemo.Text:='Select a schema object or unsupported statement to read its captured evidence and next investigation.';
 if (FDatabaseSchemaRows=nil) or (DatabaseSchemaList.ItemIndex<0) or (DatabaseSchemaList.ItemIndex>=FDatabaseSchemaRows.Count) then Exit;
 DatabaseSchemaMemo.Text:=TDPHDatabaseSchema.Describe(FDatabaseSchemaRows[DatabaseSchemaList.ItemIndex])+sLineBreak+sLineBreak+FDatabaseSchema.GetValue<string>('qualification');
 DatabaseDictionaryEdit.Enabled:=MatchText(FDatabaseSchemaRows[DatabaseSchemaList.ItemIndex].GetValue<string>('kind'),['table','column']) and MatchText(FDatabaseSchemaRows[DatabaseSchemaList.ItemIndex].GetValue<string>('status'),['declared header','declared column']);
 if DatabaseDictionaryEdit.Enabled then begin
  SchemaText:=DatabaseSchemaMemo.Text;SavedDictionary:=TDPHDatabaseSchema.FindDictionary(FKnowledge,FDatabaseSchemaRows[DatabaseSchemaList.ItemIndex]);
  if SavedDictionary<>nil then DatabaseSchemaMemo.Text:=SavedDictionary.GetValue<string>('body')+sLineBreak+'Review state: '+SavedDictionary.GetValue<string>('state')+' | Open dictionary history for contributor, revisions and review.'
  else DatabaseSchemaMemo.Text:='BUSINESS DICTIONARY'+sLineBreak+'Business meaning not recorded for these captured bytes. Click Edit dictionary. Do not infer purpose or sensitivity from SQL names.';
  DatabaseDictionaryKnowledge.Enabled:=TDPHDatabaseSchema.FindDictionary(FKnowledge,FDatabaseSchemaRows[DatabaseSchemaList.ItemIndex],True)<>nil;
  if DatabaseDictionaryKnowledge.Enabled and (SavedDictionary=nil) then DatabaseSchemaMemo.Lines.Add('Historical dictionary exists for this source/record/name with different captured bytes. Open dictionary history; it is not transferred or verified against this capture.');
  DatabaseSchemaMemo.Lines.Add(sLineBreak+'CAPTURED SCHEMA EVIDENCE'+sLineBreak+SchemaText);
 end;
 DatabaseSchemaSource.Enabled:=True;
 if MatchText(FDatabaseSchemaRows[DatabaseSchemaList.ItemIndex].GetValue<string>('kind'),['key','index','procedure','function','trigger','migration']) then
  for Link in FDatabaseSchemaRows[DatabaseSchemaList.ItemIndex].GetValue<TJSONArray>('links') do
   if Link.TryGetValue<string>('target_id',ID) then begin FDatabaseSchemaTargets.Add(ID);DatabaseSchemaLinks.Items.Add(Link.GetValue<string>('role')+': '+Link.GetValue<string>('reference'));end;
 DatabaseSchemaFollow.Enabled:=FDatabaseSchemaTargets.Count>0;if DatabaseSchemaFollow.Enabled then DatabaseSchemaLinks.ItemIndex:=0;
end;
procedure TDPHMainForm.DatabaseSchemaFollowClick(Sender:TObject);
var ID:string;V:TJSONValue;Index:Integer;
begin
 if (FDatabaseSchema=nil) or (DatabaseSchemaLinks.ItemIndex<0) or (DatabaseSchemaLinks.ItemIndex>=FDatabaseSchemaTargets.Count) then Exit;
 ID:=FDatabaseSchemaTargets[DatabaseSchemaLinks.ItemIndex];Index:=0;
 for V in FDatabaseSchema.GetValue<TJSONArray>('rows') do begin
  if V.GetValue<string>('id')=ID then begin
   DatabaseSchemaKind.ItemIndex:=0;DatabaseSchemaState.ItemIndex:=0;DatabaseSchemaFilter.Text:='';DatabaseSchemaFilterChange(nil);
   if Index>=250 then begin FDatabaseSchemaOffset:=(Index div 250)*250-250;DatabaseSchemaFilterChange(DatabaseSchemaNext);end;
   DatabaseSchemaList.ItemIndex:=Index mod 250;DatabaseSchemaSelectionChange(nil);Exit;
  end;Inc(Index);
 end;
 DatabaseSchemaMemo.Lines.Add('Relationship target is no longer present in this captured projection.');
end;
procedure TDPHMainForm.DatabaseSchemaSourceClick(Sender:TObject);
var Row,Range:TJSONObject;
begin
 if (FView=nil) or (DatabaseSchemaList.ItemIndex<0) or (DatabaseSchemaList.ItemIndex>=FDatabaseSchemaRows.Count) then Exit;
 Row:=FDatabaseSchemaRows[DatabaseSchemaList.ItemIndex];Range:=Row.GetValue<TJSONObject>('range');
 try SourceMemo.Text:=TDPHKeyboardInspector.ReadSource(FView,FEntry,Row,Range);SourceMemo.CaretPosition:=TCaretPosition.Create(Max(0,Range.GetValue<Integer>('line')-1),0);WorkspaceTabs.ActiveTab:=SourceTab;
 except on E:Exception do DatabaseSchemaMemo.Lines.Add('Source unavailable: '+E.Message);end;
end;

procedure TDPHMainForm.DatabaseInventorySourceClick(Sender:TObject);
var Row,Range:TJSONObject;
begin
 if (FView=nil) or (DatabaseInventoryList.ItemIndex<0) or (DatabaseInventoryList.ItemIndex>=FDatabaseInventoryRows.Count) then Exit;
 Row:=FDatabaseInventoryRows[DatabaseInventoryList.ItemIndex];Range:=Row.GetValue<TJSONObject>('range');
 try SourceMemo.Text:=TDPHKeyboardInspector.ReadSource(FView,FEntry,Row,Range);SourceMemo.CaretPosition:=TCaretPosition.Create(Max(0,Range.GetValue<Integer>('line')-1),0);WorkspaceTabs.ActiveTab:=SourceTab;
 except on E:Exception do DatabaseInventoryMemo.Lines.Add('Source unavailable: '+E.Message);end;
end;

procedure TDPHMainForm.DatabaseInventoryFilterChange(Sender:TObject);
var V:TJSONValue;Row:TJSONObject;Count:Integer;Kind:string;
begin
 if FDatabaseInventoryRows=nil then Exit;
 if Sender=DatabaseInventoryNext then Inc(FDatabaseInventoryOffset,250) else FDatabaseInventoryOffset:=0;
 FDatabaseInventoryRows.Clear;DatabaseInventoryList.Items.Clear;DatabaseInventoryNext.Enabled:=False;DatabaseInventorySelectionChange(nil);
 if FDatabaseInventory=nil then begin DatabaseInventoryStatus.Text:='Open a captured project to inspect its database declarations.';Exit;end;
 Kind:='';if DatabaseInventoryKind.ItemIndex>0 then Kind:=DatabaseInventoryKind.Selected.Text;Count:=0;
 for V in FDatabaseInventory.GetValue<TJSONArray>('rows') do begin Row:=V as TJSONObject;
  if (Kind<>'') and (Row.GetValue<string>('role')<>Kind) then Continue;
  if (DatabaseInventoryFilter.Text.Trim<>'') and not ContainsText(Row.GetValue<string>('path')+' '+Row.GetValue<string>('class')+' '+Row.GetValue<string>('source')+' '+Row.GetValue<TJSONArray>('configuration').ToJSON+' '+Row.GetValue<TJSONArray>('links').ToJSON+' '+Row.GetValue<TJSONArray>('used_by').ToJSON+' '+Row.GetValue<string>('engine.family')+' '+Row.GetValue<string>('engine.server_version')+' '+Row.GetValue<string>('expression','')+' '+Row.GetValue<string>('constraint','')+' '+Row.GetValue<string>('input','')+' '+Row.GetValue<string>('output',''),DatabaseInventoryFilter.Text.Trim) then Continue;
  if (Count>=FDatabaseInventoryOffset) and (FDatabaseInventoryRows.Count<250) then begin FDatabaseInventoryRows.Add(Row);DatabaseInventoryList.Items.Add(Row.GetValue<string>('role')+' | '+Row.GetValue<string>('path')+' : '+Row.GetValue<string>('class')+' | Engine: '+Row.GetValue<string>('engine.family')+' | Declared version: '+Row.GetValue<string>('engine.server_version'));end;Inc(Count);
 end;
 DatabaseInventoryNext.Enabled:=Count>FDatabaseInventoryOffset+FDatabaseInventoryRows.Count;
 DatabaseInventoryStatus.Text:=Format('%d matches; %d shown from %d. Configuration is masked; no target database is opened.',[Count,FDatabaseInventoryRows.Count,FDatabaseInventoryOffset]);
 if FDatabaseInventory.GetValue<Boolean>('data_rules_truncated',False) then DatabaseInventoryStatus.Text:=DatabaseInventoryStatus.Text+' Rule inventory truncated at 10000 rows; narrow the captured project.';
 if DatabaseInventoryList.Count>0 then begin DatabaseInventoryList.ItemIndex:=0;DatabaseInventorySelectionChange(nil);end
 else DatabaseInventoryMemo.Text:=FDatabaseInventory.GetValue<string>('qualification')+sLineBreak+sLineBreak+'No matching captured database declarations. Clear the filters or reassess with approved missing source. Runtime-only factories and configuration are not established by an empty inventory.';
end;
procedure TDPHMainForm.DatabaseInventorySelectionChange(Sender:TObject);
var Row:TJSONObject;Value:TJSONValue;ID:string;
begin
 if FDatabaseInventoryTargets=nil then Exit;FDatabaseInventoryTargets.Clear;DatabaseInventoryLinks.Items.Clear;DatabaseInventoryFollow.Enabled:=False;DatabaseInventorySource.Enabled:=False;DatabaseInventoryTrace.Enabled:=False;DatabaseInventoryDiagram.Enabled:=False;
 DatabaseInventoryMemo.Text:='Select a connection, dataset, data source, transaction, session or definition. Missing configuration and runtime bindings remain unknown.';
 if (DatabaseInventoryList.ItemIndex<0) or (DatabaseInventoryList.ItemIndex>=FDatabaseInventoryRows.Count) then Exit;
 Row:=FDatabaseInventoryRows[DatabaseInventoryList.ItemIndex];DatabaseInventorySource.Enabled:=True;DatabaseInventoryTrace.Enabled:=True;DatabaseInventoryDiagram.Enabled:=True;DatabaseInventoryMemo.Text:=TDPHDatabaseConnections.Describe(Row)+sLineBreak+sLineBreak+FDatabaseInventory.GetValue<string>('qualification');
 for Value in Row.GetValue<TJSONArray>('links') do if Value.TryGetValue<string>('target_id',ID) then begin FDatabaseInventoryTargets.Add(ID);DatabaseInventoryLinks.Items.Add('Target via '+Value.GetValue<string>('property')+': '+Value.GetValue<string>('reference'));end;
 for Value in Row.GetValue<TJSONArray>('used_by') do begin FDatabaseInventoryTargets.Add(Value.GetValue<string>('id'));DatabaseInventoryLinks.Items.Add('Used by '+Value.GetValue<string>('name')+' via '+Value.GetValue<string>('property'));end;
 DatabaseInventoryFollow.Enabled:=FDatabaseInventoryTargets.Count>0;if DatabaseInventoryFollow.Enabled then DatabaseInventoryLinks.ItemIndex:=0;
end;
procedure TDPHMainForm.DatabaseInventoryFollowClick(Sender:TObject);
var ID:string;Value:TJSONValue;Index:Integer;
begin
 if (FDatabaseInventory=nil) or (DatabaseInventoryLinks.ItemIndex<0) or (DatabaseInventoryLinks.ItemIndex>=FDatabaseInventoryTargets.Count) then Exit;
 ID:=FDatabaseInventoryTargets[DatabaseInventoryLinks.ItemIndex];
 if ID.StartsWith('lineage-symbol:') then begin SelectSymbol(Copy(ID,16,MaxInt));WorkspaceTabs.ActiveTab:=ExplainTab;Exit;end;
 DatabaseInventoryFilter.Text:='';DatabaseInventoryKind.ItemIndex:=0;
 Index:=0;for Value in FDatabaseInventory.GetValue<TJSONArray>('rows') do begin if Value.GetValue<string>('id')=ID then Break;Inc(Index);end;
 FDatabaseInventoryOffset:=(Index div 250)*250;
 // Reuse pagination while keeping the exact target page.
 Dec(FDatabaseInventoryOffset,250);DatabaseInventoryFilterChange(DatabaseInventoryNext);
 DatabaseInventoryList.ItemIndex:=Index mod 250;DatabaseInventorySelectionChange(nil);
 if (DatabaseInventoryList.ItemIndex>=0) and (DatabaseInventoryList.ItemIndex<DatabaseInventoryList.Count) then DatabaseInventoryList.ScrollToItem(DatabaseInventoryList.ListItems[DatabaseInventoryList.ItemIndex]);
end;
procedure TDPHMainForm.DatabaseInventoryTraceClick(Sender:TObject);
var Trace:TJSONObject;V:TJSONValue;Direction,ID:string;
begin
 if (FView=nil) or (FDatabaseInventory=nil) or (DatabaseInventoryList.ItemIndex<0) or (DatabaseInventoryList.ItemIndex>=FDatabaseInventoryRows.Count) then Exit;
 Direction:='both';if DatabaseInventoryDirection.ItemIndex=1 then Direction:='inputs' else if DatabaseInventoryDirection.ItemIndex=2 then Direction:='destinations';
 FLineageSeed:=FDatabaseInventoryRows[DatabaseInventoryList.ItemIndex].GetValue<string>('id');FLineageDirection:=Direction;
 Trace:=TDPHDatabaseConnections.Lineage(FView,FDatabaseInventory,FDatabaseInventoryRows[DatabaseInventoryList.ItemIndex].GetValue<string>('id'),Direction);
 try
  DatabaseInventoryMemo.Text:=TDPHDatabaseConnections.DescribeLineage(Trace);FDatabaseInventoryTargets.Clear;DatabaseInventoryLinks.Items.Clear;
  for V in Trace.GetValue<TJSONArray>('nodes') do begin
   ID:=V.GetValue<string>('id');if not V.GetValue<Boolean>('inventory') then ID:='lineage-symbol:'+ID;
   FDatabaseInventoryTargets.Add(ID);DatabaseInventoryLinks.Items.Add('Lineage hop '+V.GetValue<TJSONValue>('depth').Value+': '+V.GetValue<string>('name'));
  end;
  DatabaseInventoryFollow.Enabled:=FDatabaseInventoryTargets.Count>0;if DatabaseInventoryFollow.Enabled then DatabaseInventoryLinks.ItemIndex:=0;
  if Sender=DatabaseInventoryDiagram then begin GraphCombo.ItemIndex:=GraphCombo.Items.IndexOf('Data lineage');RefreshGraphics;WorkspaceTabs.ActiveTab:=GraphTab;end;
 finally Trace.Free;end;
end;
procedure TDPHMainForm.HistorySelectionChange(Sender:TObject);
begin
 if FHistoryRows=nil then Exit;
 Inc(FScreenToken);FHistoryRows.Clear;FreeAndNil(FScreenHistory);HistoryList.Items.Clear;HistoryNextButton.Enabled:=False;
 HistoryBeforeTitle.Text:='BEFORE';HistoryAfterTitle.Text:='AFTER';
 HistoryBeforeImage.Bitmap.SetSize(0,0);HistoryAfterImage.Bitmap.SetSize(0,0);HistoryDifferenceImage.Bitmap.SetSize(0,0);
 HistoryStatus.Text:='Choose Before and After, then Compare. Newest 200 imported records are listed.';
 HistoryMemo.Text:='Import attributed PNG evidence on Screenshots first. Optional relative form paths enable layout comparison using each image generation. Retain those captures in Database tools. Scroll this page for images, layout changes and evidence.';
 HistoryBeforePaint.Repaint;HistoryAfterPaint.Repaint;HistoryDifferencePaint.Repaint;
end;
procedure TDPHMainForm.HistoryCompareClick(Sender:TObject);
var Request:TDPHWorkspaceRequest;Index:Integer;Path:string;
begin
 if Sender=HistorySwapButton then begin Index:=HistoryBeforeCombo.ItemIndex;HistoryBeforeCombo.ItemIndex:=HistoryAfterCombo.ItemIndex;HistoryAfterCombo.ItemIndex:=Index;Path:=HistoryBeforePath.Text;HistoryBeforePath.Text:=HistoryAfterPath.Text;HistoryAfterPath.Text:=Path;HistorySelectionChange(nil);Exit;end;
 if FBusy then begin StatusLabel.Text:='Wait for the current operation to finish';Exit;end;
 if (FView=nil) or (FDatabase='') then begin HistoryMemo.Text:='Open a saved project database first';Exit;end;
 if (FImages=nil) or (HistoryBeforeCombo.ItemIndex<0) or (HistoryAfterCombo.ItemIndex<0) or (HistoryBeforeCombo.ItemIndex>=FImages.Count) or (HistoryAfterCombo.ItemIndex>=FImages.Count) then begin HistoryMemo.Text:='Import screenshots and select both Before and After records';Exit;end;
 HistorySelectionChange(nil);Request:=Default(TDPHWorkspaceRequest);Request.Command:='screen_history';Request.Database:=FDatabase;Request.Entry:=FEntry;Request.GenerationID:=FView.Document.GetValue<Int64>('generation_id');Request.ScreenToken:=FScreenToken;
 Request.BeforeScreenshot:=FImages.Items[HistoryBeforeCombo.ItemIndex].GetValue<Int64>('artifact_id');Request.AfterScreenshot:=FImages.Items[HistoryAfterCombo.ItemIndex].GetValue<Int64>('artifact_id');Request.BeforeScreenSource:=HistoryBeforePath.Text.Trim;Request.AfterScreenSource:=HistoryAfterPath.Text.Trim;
 FWorker.Submit(Request);FBusy:=True;FPendingCommand:='screen_history';HistoryStatus.Text:='Comparing saved images in the background...';StatusLabel.Text:='Comparing screen history without executing the selected project...';
end;
procedure TDPHMainForm.LoadScreenHistory(AReport:TJSONObject;const ABeforePNG,AAfterPNG,ADifferencePNG:TBytes);
var Stream:TBytesStream;
begin
 HistorySelectionChange(nil);FScreenHistory:=AReport;
 try
  Stream:=TBytesStream.Create(ABeforePNG);try HistoryBeforeImage.Bitmap.LoadFromStream(Stream);finally Stream.Free;end;
  Stream:=TBytesStream.Create(AAfterPNG);try HistoryAfterImage.Bitmap.LoadFromStream(Stream);finally Stream.Free;end;
  Stream:=TBytesStream.Create(ADifferencePNG);try HistoryDifferenceImage.Bitmap.LoadFromStream(Stream);finally Stream.Free;end;
  HistoryBeforeTitle.Text:='BEFORE | gen '+AReport.GetValue<TJSONObject>('before').GetValue('generation_id').Value;HistoryAfterTitle.Text:='AFTER | gen '+AReport.GetValue<TJSONObject>('after').GetValue('generation_id').Value;
  HistoryStatus.Text:=AReport.GetValue('changed_pixels').Value+' changed pixels. Read attribution and limits below.';
  HistoryFilterChange(nil);HistoryModeChange(nil);
 except HistorySelectionChange(nil);raise;end;
end;
procedure TDPHMainForm.HistoryModeChange(Sender:TObject);
var LayoutMode:Boolean;
begin
 if FHistoryRows=nil then Exit;
 LayoutMode:=HistoryModeCombo.ItemIndex=1;HistoryBeforeImage.Visible:=not LayoutMode;HistoryAfterImage.Visible:=not LayoutMode;HistoryDifferenceImage.Visible:=not LayoutMode;
 HistoryBeforePaint.Visible:=LayoutMode;HistoryAfterPaint.Visible:=LayoutMode;HistoryDifferencePaint.Visible:=LayoutMode;
 if LayoutMode then HistoryDifferenceTitle.Text:='LAYOUT OVERLAY' else HistoryDifferenceTitle.Text:='PIXEL DIFFERENCE';
 HistoryBeforePaint.Repaint;HistoryAfterPaint.Repaint;HistoryDifferencePaint.Repaint;
end;
procedure TDPHMainForm.HistoryFilterChange(Sender:TObject);
var Layout,Row:TJSONObject;Value:TJSONValue;Count:Integer;
begin
 if FHistoryRows=nil then Exit;
 if Sender=HistoryNextButton then Inc(FHistoryOffset,250) else FHistoryOffset:=0;FHistoryRows.Clear;HistoryList.Items.Clear;HistoryNextButton.Enabled:=False;
 if FScreenHistory=nil then Exit;HistoryMemo.Text:=TDPHScreenHistory.Describe(FScreenHistory);
 if not FScreenHistory.TryGetValue<TJSONObject>('layout',Layout) then Exit;Count:=0;
 for Value in Layout.GetValue<TJSONArray>('changes') do begin Row:=Value as TJSONObject;if (HistoryFilter.Text.Trim<>'') and not ContainsText(Row.ToJSON,HistoryFilter.Text.Trim) then Continue;
  if (Count>=FHistoryOffset) and (FHistoryRows.Count<250) then begin FHistoryRows.Add(Row);HistoryList.Items.Add(Row.GetValue<string>('kind')+' | '+Row.GetValue<string>('path'));end;Inc(Count);
 end;
 HistoryNextButton.Enabled:=Count>FHistoryOffset+FHistoryRows.Count;HistoryMemo.Lines.Add(Format('Layout changes: %d matching; %d shown from %d',[Count,FHistoryRows.Count,FHistoryOffset]));
end;
procedure TDPHMainForm.HistoryRowClick(Sender:TObject);
var Row:TJSONObject;
begin
 if (FScreenHistory=nil) or (HistoryList.ItemIndex<0) or (HistoryList.ItemIndex>=FHistoryRows.Count) then Exit;
 Row:=FHistoryRows[HistoryList.ItemIndex];HistoryMemo.Text:=TDPHScreenHistory.Describe(FScreenHistory)+sLineBreak+sLineBreak+Row.GetValue<string>('kind')+' '+Row.GetValue<string>('path')+sLineBreak+'BEFORE serialized values (blank means absent component):'+sLineBreak+Row.GetValue<string>('before_values')+sLineBreak+'AFTER serialized values:'+sLineBreak+Row.GetValue<string>('after_values')+sLineBreak+'Exact captured component evidence:'+sLineBreak+Row.Format(2);
end;
procedure TDPHMainForm.HistoryPaint(Sender:TObject;Canvas:TCanvas);
var Paint:TPaintBox;Layout,Screen,Row:TJSONObject;Value:TJSONValue;Scale,MinX,MinY,MaxX,MaxY:Single;R:TRectF;I,J,Count:Integer;
begin
 Paint:=Sender as TPaintBox;Canvas.Fill.Kind:=TBrushKind.Solid;Canvas.Fill.Color:=TAlphaColors.White;Canvas.FillRect(Paint.LocalRect,0,0,[],1);Canvas.Stroke.Kind:=TBrushKind.Solid;Canvas.Stroke.Thickness:=1;
 if (FScreenHistory=nil) or not FScreenHistory.TryGetValue<TJSONObject>('layout',Layout) then begin Canvas.Fill.Color:=TAlphaColors.Gray;Canvas.FillText(Paint.LocalRect,'Layout unavailable; read evidence below.',True,1,[],TTextAlign.Center,TTextAlign.Center);Exit;end;
 MinX:=0;MinY:=0;MaxX:=1;MaxY:=1;
 for I:=0 to 1 do begin if I=0 then Screen:=Layout.GetValue<TJSONObject>('before') else Screen:=Layout.GetValue<TJSONObject>('after');for Value in Screen.GetValue<TJSONArray>('components') do begin Row:=Value as TJSONObject;MinX:=Min(MinX,Row.GetValue<Double>('x'));MinY:=Min(MinY,Row.GetValue<Double>('y'));MaxX:=Max(MaxX,Row.GetValue<Double>('x')+Row.GetValue<Double>('width'));MaxY:=Max(MaxY,Row.GetValue<Double>('y')+Row.GetValue<Double>('height'));end;end;
 Scale:=Min(Max(1,Paint.Width-16)/(MaxX-MinX),Max(1,Paint.Height-16)/(MaxY-MinY));
 for I:=0 to 1 do begin
  if (Paint=HistoryBeforePaint) and (I=1) then Continue;if (Paint=HistoryAfterPaint) and (I=0) then Continue;
  if I=0 then begin Screen:=Layout.GetValue<TJSONObject>('before');Canvas.Stroke.Color:=HistoryBeforeLegend.Fill.Color;end else begin Screen:=Layout.GetValue<TJSONObject>('after');Canvas.Stroke.Color:=HistoryAfterLegend.Fill.Color;end;
  Count:=Min(300,Screen.GetValue<TJSONArray>('components').Count);
  for J:=0 to Count-1 do begin Row:=Screen.GetValue<TJSONArray>('components').Items[J] as TJSONObject;R:=RectF(8+(Row.GetValue<Double>('x')-MinX)*Scale,8+(Row.GetValue<Double>('y')-MinY)*Scale,8+(Row.GetValue<Double>('x')-MinX+Row.GetValue<Double>('width'))*Scale,8+(Row.GetValue<Double>('y')-MinY+Row.GetValue<Double>('height'))*Scale);Canvas.DrawRect(R,0,0,[],1);end;
 end;
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
  if FSelected<>AKey then FLineageSeed:='';
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
var Grouped: TJSONObject; Limit: Integer; HTML,GraphPath,Seed,Direction: string;IsLineage:Boolean;
begin
  FreeAndNil(FGraph); FreeAndNil(FScreen); if FView=nil then Exit;
  FlowBrowser.Visible:=False;GraphPaint.Height:=4500;
  IsLineage:=(GraphCombo.ItemIndex>=0) and (GraphCombo.Selected.Text='Data lineage');
  GraphLegend.Text:='Static relationships | blue: confirmed | orange dash: uncertain | Objects, Types or Units changes grouping | select a group for members and evidence';
  Limit:=120; GraphGroupingCombo.Enabled:=(GraphCombo.ItemIndex<>1) and not IsLineage;
  if (GraphCombo.ItemIndex<>1) and (GraphGroupingCombo.ItemIndex>0) then Limit:=1000;
  if (GraphCombo.ItemIndex>=0) and (GraphCombo.Selected.Text='Business process') then begin
   GraphGroupingCombo.Enabled:=False;
   GraphLegend.Text:='Authored business workflow | blue: normal sequence | orange: exception routes | select steps for details | exact process links retain revision review; runtime unobserved';
   if FKnowledgeEdited then StatusLabel.Text:='Save or discard the current Knowledge draft before opening a saved workflow diagram.'
   else if (DepartmentalWorkflowList.ItemIndex>=0) and (DepartmentalWorkflowList.ItemIndex<FDepartmentalWorkflowRows.Count) then
    FGraph:=TDPHGraphProjection.Workflow(FDepartmentalWorkflowRows[DepartmentalWorkflowList.ItemIndex],FKnowledge,FView.Document.GetValue<Int64>('generation_id'));
   if FGraph<>nil then GraphPaint.Height:=Max(4500,FGraph.GetValue<TJSONArray>('nodes').Count*190+40);
  end
  else if IsLineage then begin
   Seed:=FLineageSeed;if Seed='' then Seed:=FSelected;Direction:=FLineageDirection;if Direction='' then Direction:='both';
   if FDatabaseInventory<>nil then FGraph:=TDPHDatabaseConnections.Lineage(FView,FDatabaseInventory,Seed,Direction);
   GraphLegend.Text:='Data lineage source candidates | arrows: lexical dependency or labeled context, not runtime order | select a node for details | unresolved breaks are listed below the HTML diagram and in Trace lineage';
  end
  else if FWholeGraph and MatchText(GraphCombo.Items[GraphCombo.ItemIndex],WholeKinds) then FGraph:=FView.Graph(GraphCombo.Items[GraphCombo.ItemIndex],'',Limit)
  else if GraphCombo.ItemIndex>=0 then FGraph:=FView.Graph(GraphCombo.Items[GraphCombo.ItemIndex],FSelected,Limit);
  if (FGraph<>nil) and (GraphCombo.ItemIndex<>1) and not IsLineage and (FGraph.GetValue<string>('kind')<>'Business process') and (GraphGroupingCombo.ItemIndex>0) then begin
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
  if (FGraph<>nil) and (FGraph.GetValue<string>('kind')='Business process') then Exit(TRectF.Create(170,40+AIndex*190,770,160+AIndex*190));
  W:=GraphNodeStyle.Width+GraphNodeStyle.Margins.Right; H:=GraphNodeStyle.Height+GraphNodeStyle.Margins.Bottom;
  Columns:=Max(1,Trunc(GraphPaint.Width/W)); Result:=TRectF.Create(10+(AIndex mod Columns)*W,10+(AIndex div Columns)*H,10+(AIndex mod Columns)*W+GraphNodeStyle.Width,10+(AIndex div Columns)*H+GraphNodeStyle.Height);
end;
procedure TDPHMainForm.GraphPaintPaint(Sender: TObject; Canvas: TCanvas);
var Nodes,Edges: TJSONArray; V: TJSONValue; E,N: TJSONObject; I,A,B: Integer; R,FromRect,ToRect: TRectF;RouteX:Single;
begin
  if FGraph=nil then Exit; Nodes:=FGraph.GetValue<TJSONArray>('nodes'); Edges:=FGraph.GetValue<TJSONArray>('edges');
  for V in Edges do begin E:=V as TJSONObject; A:=-1; B:=-1;
    for I:=0 to Nodes.Count-1 do begin N:=Nodes.Items[I] as TJSONObject;
      if N.GetValue('id').Value=E.GetValue('from').Value then A:=I; if N.GetValue('id').Value=E.GetValue('to').Value then B:=I;
    end;
  Canvas.Stroke.Assign(GraphNodeStyle.Stroke); if ((FGraph.GetValue<string>('kind')='Business process') and (E.GetValue<string>('kind')='exception')) or ((FGraph.GetValue<string>('kind')<>'Business process') and (E.GetValue<string>('resolution','')<>'confirmed_static')) then begin Canvas.Stroke.Color:=HeaderStyle.Fill.Color; Canvas.Stroke.Dash:=TStrokeDash.Dash; end;
    if (A>=0) and (B>=0) and (FGraph.GetValue<string>('kind')='Business process') then begin
     FromRect:=GraphRect(A);ToRect:=GraphRect(B);
     if E.GetValue<string>('kind')='normal' then begin
      Canvas.DrawLine(TPointF.Create(FromRect.CenterPoint.X,FromRect.Bottom),TPointF.Create(ToRect.CenterPoint.X,ToRect.Top),1);
      Canvas.DrawLine(TPointF.Create(ToRect.CenterPoint.X,ToRect.Top),TPointF.Create(ToRect.CenterPoint.X-6,ToRect.Top-8),1);
      Canvas.DrawLine(TPointF.Create(ToRect.CenterPoint.X,ToRect.Top),TPointF.Create(ToRect.CenterPoint.X+6,ToRect.Top-8),1);
     end else begin
      RouteX:=820+(A mod 8)*22;
      Canvas.DrawLine(TPointF.Create(FromRect.Right,FromRect.Top+70),TPointF.Create(RouteX,FromRect.Top+70),1);
      Canvas.DrawLine(TPointF.Create(RouteX,FromRect.Top+70),TPointF.Create(RouteX,ToRect.Top+30),1);
      Canvas.DrawLine(TPointF.Create(RouteX,ToRect.Top+30),TPointF.Create(ToRect.Right,ToRect.Top+30),1);
      Canvas.DrawLine(TPointF.Create(ToRect.Right,ToRect.Top+30),TPointF.Create(ToRect.Right+8,ToRect.Top+24),1);
      Canvas.DrawLine(TPointF.Create(ToRect.Right,ToRect.Top+30),TPointF.Create(ToRect.Right+8,ToRect.Top+36),1);
     end;
    end
    else if (A>=0) and (B>=0) then begin Canvas.DrawLine(GraphRect(A).CenterPoint,GraphRect(B).CenterPoint,1);
      Canvas.DrawLine(GraphRect(B).CenterPoint,TPointF.Create(GraphRect(B).CenterPoint.X-6,GraphRect(B).CenterPoint.Y-8),1);
      Canvas.DrawLine(GraphRect(B).CenterPoint,TPointF.Create(GraphRect(B).CenterPoint.X+6,GraphRect(B).CenterPoint.Y-8),1); end;
  end;
  for I:=0 to Nodes.Count-1 do begin N:=Nodes.Items[I] as TJSONObject; R:=GraphRect(I);
    Canvas.Fill.Assign(GraphNodeStyle.Fill); Canvas.FillRect(R,4,4,AllCorners,1); Canvas.Stroke.Assign(GraphNodeStyle.Stroke); Canvas.DrawRect(R,4,4,AllCorners,1);
    Canvas.Fill.Color:=GraphNodeStyle.Stroke.Color; if FGraph.GetValue<string>('kind')='Business process' then
     Canvas.FillText(R,Copy(N.GetValue<string>('label'),1,160)+sLineBreak+Copy(N.GetValue<string>('department','')+' | '+N.GetValue<string>('role',''),1,120),True,1,[],TTextAlign.Center,TTextAlign.Center)
    else Canvas.FillText(R,Copy(N.GetValue<string>('label'),1,160),True,1,[],TTextAlign.Center,TTextAlign.Center);
  end;
end;
procedure TDPHMainForm.GraphMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,Y: Single);
var I: Integer; N,Row: TJSONObject; Nodes: TJSONArray;
begin
  if FGraph=nil then Exit; Nodes:=FGraph.GetValue<TJSONArray>('nodes');
  for I:=0 to Nodes.Count-1 do if GraphRect(I).Contains(TPointF.Create(X,Y)) then begin N:=Nodes.Items[I] as TJSONObject;
    if FGraph.GetValue<string>('kind')='Business process' then begin
     FreeAndNil(FDetails);FDetails:=TJSONArray.Create;DetailsList.Items.Clear;DetailsMemo.Text:=N.GetValue<string>('label')+sLineBreak+N.GetValue<string>('detail')+sLineBreak+FGraph.GetValue<string>('qualification');WorkspaceTabs.ActiveTab:=DetailsTab;
    end
    else if FGraph.GetValue<string>('kind')='Data lineage' then begin
     if N.GetValue<Boolean>('inventory') then begin
      FDatabaseInventoryTargets.Clear;FDatabaseInventoryTargets.Add(N.GetValue<string>('id'));
      DatabaseInventoryLinks.Items.Clear;DatabaseInventoryLinks.Items.Add(N.GetValue<string>('label'));DatabaseInventoryLinks.ItemIndex:=0;
      DatabaseInventoryFollowClick(nil);WorkspaceTabs.ActiveTab:=DatabaseInventoryTab;
     end else begin SelectSymbol(N.GetValue<string>('id'));WorkspaceTabs.ActiveTab:=ExplainTab;end;
    end
    else if N.GetValue<string>('kind','')='group' then GraphGroupDetails(N.GetValue('id').Value)
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
begin FKnowledge.Free; FKnowledge:=ARows;DepartmentalWorkflowFilterChange(nil); if not FKnowledgeEdited then NewKnowledgeClick(nil); KnowledgeFilterChange(nil); GlossaryFilterChange(nil); RefreshLearning; RefreshCoverage; RefreshQuestions; DependencyFilterChange(nil); DatabaseSchemaSelectionChange(nil);FileFormatsSelectionChange(nil);DataRetentionFilterChange(nil);TargetRecoveryFilterChange(nil);BusinessProcessFilterChange(nil);BusinessRuleFilterChange(nil);DepartmentalWorkflowFilterChange(nil);DataQualityFilterChange(nil); if FView<>nil then begin FActionPurposeRows.Clear;FreeAndNil(FActionPurposes);FActionPurposes:=TDPHActionPurposes.Inspect(FView,FKeyboard,FKnowledge);ActionPurposeFilterChange(nil);end; end;
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
  FKnowledgeStructuredJSON:=Row.GetValue<string>('structured_json','{}');
  KnowledgeBodyMemo.ReadOnly:=(FKnowledgeStructuredJSON<>'{}') and not TDPHWorkspaceView.IsDataRetentionPolicy(Row) and not TDPHWorkspaceView.IsDataQualityRule(Row) and not TDPHWorkspaceView.IsTargetRecoveryPlan(Row);
  KnowledgeTitleEdit.ReadOnly:=FKnowledgeStructuredJSON<>'{}';
  KnowledgeKindCombo.Enabled:=FKnowledgeStructuredJSON='{}';
  KnowledgeDocumentCombo.Enabled:=FKnowledgeStructuredJSON='{}'; KnowledgeAudienceCombo.Enabled:=FKnowledgeStructuredJSON='{}';
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
  FreeAndNil(FWorkflowDraft);FWorkflowStepDirty:=False;FStructuredEditorPending:=False;FStructuredEditorID:='';
  FreeAndNil(FTranslations); TranslationList.Items.Clear; TranslationMemo.Text:='';
  FBinding:=True; try FKnowledgeID:=0; FKnowledgeRevision:=0; KnowledgeTitleEdit.Text:=''; KnowledgeBodyMemo.Text:='';
    FKnowledgeQuestionJSON:='';
    FKnowledgeStructuredJSON:='{}'; KnowledgeBodyMemo.ReadOnly:=False;
    KnowledgeTitleEdit.ReadOnly:=False; KnowledgeKindCombo.Enabled:=True; KnowledgeDocumentCombo.Enabled:=True; KnowledgeAudienceCombo.Enabled:=True;
    if (KnowledgeKindCombo.ItemIndex>=0) and (KnowledgeKindCombo.Items[KnowledgeKindCombo.ItemIndex]='glossary') then KnowledgeKindCombo.ItemIndex:=0;
    KnowledgeDocumentCombo.ItemIndex:=0; KnowledgeAudienceCombo.ItemIndex:=0; KnowledgeSectionLabel.Text:='New section: stable ID assigned on Save';
    FreeAndNil(FEditableLinks); FEditableLinks:=TJSONArray.Create; RefreshKnowledgeLinks;
    KnowledgeHistoryMemo.Text:='New content links to the selected canonical object, or the project when no object is selected. Titles and kinds remain stable after creation.';
    FKnowledgeEdited:=False; FKnowledgeLink:=FSelected; finally FBinding:=False; end;
end;
procedure TDPHMainForm.SaveKnowledgeClick(Sender: TObject);
begin
 if FStructuredEditorPending then begin StatusLabel.Text:='Apply the structured editor to Knowledge or discard its draft before Save.';Exit;end;
 Submit('save_knowledge');
end;
procedure TDPHMainForm.GlossaryFilterChange(Sender: TObject);
var Value: TJSONValue; Row: TJSONObject; Filter: string;
begin
  if FGlossaryRows=nil then Exit;
  GlossaryList.Items.Clear; FGlossaryRows.Clear;
  GlossaryMemo.Text:='No matching saved terms. Click New term to define business language for this selected application.';
  if FKnowledge=nil then Exit;
  Filter:=GlossaryFilterEdit.Text.Trim;
  for Value in FKnowledge do begin
    Row:=Value as TJSONObject;
    if Row.GetValue<string>('kind')<>'glossary' then Continue;
    if (Filter<>'') and not ContainsText(Row.GetValue<string>('title')+' '+Row.GetValue<string>('body'),Filter) then Continue;
    FGlossaryRows.Add(Row);
  end;
  FGlossaryRows.Sort(TComparer<TJSONObject>.Construct(function(const Left,Right: TJSONObject): Integer
    begin Result:=CompareText(Left.GetValue<string>('title'),Right.GetValue<string>('title')); end));
  for Row in FGlossaryRows do GlossaryList.Items.Add(Row.GetValue<string>('title')+' ['+Row.GetValue<string>('state')+']');
  if FGlossaryRows.Count>0 then begin GlossaryList.ItemIndex:=0; GlossaryClick(nil); end;
end;
procedure TDPHMainForm.GlossaryClick(Sender: TObject);
var Row: TJSONObject;
begin
  if (GlossaryList.ItemIndex<0) or (GlossaryList.ItemIndex>=FGlossaryRows.Count) then Exit;
  Row:=FGlossaryRows[GlossaryList.ItemIndex];
  GlossaryMemo.Text:=Row.GetValue<string>('body')+sLineBreak+sLineBreak+
    'State: '+Row.GetValue<string>('state')+' | revision '+Row.GetValue<string>('revision')+' | source generation '+Row.GetValue<string>('source_generation')+
    sLineBreak+'Contributor: '+Row.GetValue<string>('editor')+' | reviewer: '+Row.GetValue<string>('reviewer')+
    sLineBreak+sLineBreak+'Open in Knowledge to inspect immutable history, add exact source links, or explicitly review this revision.';
end;
procedure TDPHMainForm.OpenGlossaryKnowledgeClick(Sender: TObject);
var ID: string; Index: Integer;
begin
  if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft first'; Exit; end;
  if (GlossaryList.ItemIndex<0) or (GlossaryList.ItemIndex>=FGlossaryRows.Count) then begin StatusLabel.Text:='Select a saved glossary term first'; Exit; end;
  ID:=FGlossaryRows[GlossaryList.ItemIndex].GetValue<string>('id');
  PendingKnowledgeCheck.IsChecked:=False; KnowledgeFilterChange(nil);
  for Index:=0 to FKnowledgeRows.Count-1 do if FKnowledgeRows[Index].GetValue<string>('id')=ID then begin
    KnowledgeList.ItemIndex:=Index; KnowledgeClick(nil); WorkspaceTabs.ActiveTab:=KnowledgeTab; Exit;
  end;
end;
procedure TDPHMainForm.EditGlossaryClick(Sender: TObject);
var Editor: TDPHGlossaryForm; Row,RecordValue,Initial: TJSONObject; Links: TJSONArray;
begin
  if FBusy then Exit;
  if FView=nil then begin StatusLabel.Text:='Open the selected project before adding business terms'; Exit; end;
  if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft first'; Exit; end;
  Row:=nil; Initial:=nil;
  if Sender=EditGlossaryButton then begin
    if (GlossaryList.ItemIndex<0) or (GlossaryList.ItemIndex>=FGlossaryRows.Count) then begin StatusLabel.Text:='Select a saved glossary term first'; Exit; end;
    Row:=FGlossaryRows[GlossaryList.ItemIndex].Clone as TJSONObject; Initial:=TJSONObject.ParseJSONValue(Row.GetValue<string>('structured_json')) as TJSONObject;
  end;
  Editor:=TDPHGlossaryForm.Create(nil);
  try
    Editor.LoadRecord(Initial,KnowledgeAuthorEdit.Text);
    if Editor.ShowModal<>mrOk then Exit;
    RecordValue:=Editor.RecordJSON;
    try
      FBinding:=True;
      try
        FKnowledgeID:=0; FKnowledgeRevision:=0;
        if Row<>nil then begin FKnowledgeID:=StrToInt64(Row.GetValue<string>('id')); FKnowledgeRevision:=StrToInt64(Row.GetValue<string>('revision')); end;
        KnowledgeTitleEdit.Text:=RecordValue.GetValue<string>('term'); KnowledgeAuthorEdit.Text:=Editor.AuthorEdit.Text;
        KnowledgeKindCombo.ItemIndex:=KnowledgeKindCombo.Items.IndexOf('glossary');
        KnowledgeDocumentCombo.ItemIndex:=KnowledgeDocumentCombo.Items.IndexOf('user'); KnowledgeAudienceCombo.ItemIndex:=KnowledgeAudienceCombo.Items.IndexOf('all');
        KnowledgeBodyMemo.Text:=TDPHGlossary.Body(RecordValue); KnowledgeBodyMemo.ReadOnly:=True;
        KnowledgeTitleEdit.ReadOnly:=True; KnowledgeKindCombo.Enabled:=False; KnowledgeDocumentCombo.Enabled:=False; KnowledgeAudienceCombo.Enabled:=False;
        FKnowledgeStructuredJSON:=RecordValue.ToJSON; FKnowledgeQuestionJSON:=''; FKnowledgeLink:='';
        FreeAndNil(FEditableLinks);
        if (Row<>nil) and Row.TryGetValue<TJSONArray>('rich_links',Links) then FEditableLinks:=Links.Clone as TJSONArray else FEditableLinks:=TJSONArray.Create;
        RefreshKnowledgeLinks; FKnowledgeEdited:=True;
        KnowledgeSectionLabel.Text:='Business glossary draft: click Save, then explicitly review';
        KnowledgeHistoryMemo.Text:='Edit term fields in Business glossary. Knowledge links stores exact source evidence. Saving preserves prior revisions and requires a fresh named review.';
      finally FBinding:=False; end;
      WorkspaceTabs.ActiveTab:=KnowledgeTab; StatusLabel.Text:='Glossary draft prepared. Click Save to persist; use Knowledge links for source evidence.';
    finally RecordValue.Free; end;
  finally Editor.Free; Initial.Free; Row.Free; end;
end;
procedure TDPHMainForm.ProjectProfileClick(Sender: TObject);
var Editor: TDPHProjectProfileForm; Value: TJSONValue; Row,Profile,Initial: TJSONObject; Links: TJSONArray;
begin
  if FBusy then Exit;
  if FView=nil then begin StatusLabel.Text:='Open the selected project before editing its profile'; Exit; end;
  if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft before editing the profile'; Exit; end;
  Row:=nil; Initial:=nil;
  if FKnowledge<>nil then for Value in FKnowledge do begin
    Profile:=TJSONObject.ParseJSONValue(Value.GetValue<string>('structured_json','{}')) as TJSONObject;
    if (Profile<>nil) and (Profile.GetValue<string>('record_type','')='project_profile') then begin Row:=Value as TJSONObject; Initial:=Profile; Break; end;
    Profile.Free;
  end;
  Editor:=TDPHProjectProfileForm.Create(nil);
  try
    if Row=nil then Editor.LoadRecord(nil,KnowledgeAuthorEdit.Text) else Editor.LoadRecord(Initial,Row.GetValue<string>('editor',''));
    if Editor.ShowModal<>mrOk then Exit;
    Profile:=Editor.RecordJSON;
    try
      FBinding:=True;
      try
        FKnowledgeID:=0; FKnowledgeRevision:=0;
        if Row<>nil then begin FKnowledgeID:=StrToInt64(Row.GetValue<string>('id')); FKnowledgeRevision:=StrToInt64(Row.GetValue<string>('revision')); end;
        KnowledgeTitleEdit.Text:='Project profile'; KnowledgeAuthorEdit.Text:=Editor.ProfileAuthorEdit.Text;
        KnowledgeKindCombo.ItemIndex:=KnowledgeKindCombo.Items.IndexOf('orientation');
        KnowledgeDocumentCombo.ItemIndex:=KnowledgeDocumentCombo.Items.IndexOf('overview');
        KnowledgeAudienceCombo.ItemIndex:=KnowledgeAudienceCombo.Items.IndexOf('all');
        KnowledgeBodyMemo.Text:=TDPHProjectProfile.Body(Profile); KnowledgeBodyMemo.ReadOnly:=True;
        KnowledgeTitleEdit.ReadOnly:=True; KnowledgeKindCombo.Enabled:=False; KnowledgeDocumentCombo.Enabled:=False; KnowledgeAudienceCombo.Enabled:=False;
        FKnowledgeStructuredJSON:=Profile.ToJSON; FKnowledgeQuestionJSON:=''; FKnowledgeLink:='';
        FreeAndNil(FEditableLinks);
        if (Row<>nil) and Row.TryGetValue<TJSONArray>('rich_links',Links) then FEditableLinks:=Links.Clone as TJSONArray else FEditableLinks:=TJSONArray.Create;
        RefreshKnowledgeLinks; FKnowledgeEdited:=True;
        KnowledgeSectionLabel.Text:='Project profile draft; use Save, then review with a named reviewer';
        KnowledgeHistoryMemo.Text:='Structured profile fields are edited with Projects > Project profile. Saved revisions and review history remain available in Knowledge.';
      finally FBinding:=False; end;
      WorkspaceTabs.ActiveTab:=KnowledgeTab; StatusLabel.Text:='Project profile draft prepared. Click Save to persist it; review remains explicit.';
    finally Profile.Free; end;
  finally Editor.Free; Initial.Free; end;
end;
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
