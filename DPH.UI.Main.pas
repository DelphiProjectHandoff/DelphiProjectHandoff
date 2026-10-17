unit DPH.UI.Main;
interface
uses Winapi.Windows, System.Classes, System.SysUtils, System.Types, System.UITypes, System.JSON, System.Generics.Collections,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Controls.Presentation, FMX.StdCtrls,
  FMX.Layouts, FMX.ListBox, FMX.Edit, FMX.Memo, FMX.Text, FMX.TabControl, FMX.Dialogs,
  FMX.Objects, FMX.Graphics, FMX.TextLayout, FMX.WebBrowser, DAT.Components.FMX,
  DAT.Components.FMX.LanguageSelector, DPH.Workspace.Model, DPH.Workspace.Worker,
  DPH.Publish.Model, DPH.Publish.OfflinePreview, DPH.Analysis.Explanations,
  DPH.Handoff.Dossier, DPH.Workspace.Catalog, DPH.UI.Progress;
type
  TDPHMainForm = class(TForm)
    DATLanguageManager: TDATFMXLanguageManager;
    LanguageCombo: TDATFMXLanguageComboBox;
    LanguageLabel: TLabel;
    AllowInternetCheck: TCheckBox;
    BaselineLabel,StatusLabel,BreadcrumbLabel,ScreenWarning,GraphLegend,GraphPurpose,InspectorTitle,InspectorPurpose: TLabel;
    ProjectSearchProgress,ProjectPreparationLayout: TLayout;
    ProjectSearchSpinner: TAniIndicator;
    ProjectSearchProgressText: TLabel;
    ProjectPreparationMessage,ProjectPreparationHint,ProjectPreparationPercent: TLabel;
    ProjectPreparationProgress: TProgressBar;
    HeaderLayout,HeaderBrandRow,LearnerNavRow1,LearnerNavRow2,ExplorerLayout,InspectorLayout,FilterLayout: TLayout;
    HeaderLogo: TImage;
    ScreenToolbar: THorzScrollBox;
    GraphToolbar: THorzScrollBox;
    ExplorerSplitter,InspectorSplitter: TSplitter;
    OpenProjectButton,OpenCacheButton,SaveProjectButton,RescanProjectButton,CloseButton,BackButton,BookmarkButton,BookmarksButton,NextPageButton,ParentButton,FullscreenButton: TButton;
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
    GraphNodeStyle,ScreenNodeStyle,ScreenBackgroundStyle,HeaderStyle: TRectangle;
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
    PublishPurpose: TLabel;
    PublishSettingsExpander: TExpander;
    PublishOptionsLayout: TLayout;
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
    ScreenshotReturnButton: TButton;
    ScreenshotInspectButton: TButton;
    ScreenshotEvidence: TMemo;
    ScreenshotHelp:TLabel;
    ScreenshotKind:TComboBox;
    ScreenshotCallout:TButton;
    ScreenshotMarkers:TPaintBox;
    ScreenshotMarkerStyle:TRectangle;
    ScreenshotMarkerText:TText;
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
    CalculationEvidenceTab:TTabItem;
    CalculationEvidencePurpose,CalculationEvidenceStatus,CalculationSourceLabel:TLabel;
    CalculationEvidenceToolbar:THorzScrollBox;
    CalculationEvidenceFilter:TEdit;
    CalculationEvidenceFirst,CalculationEvidenceNext,CalculationEvidenceSource,CalculationEvidenceExplain,CalculationEvidenceDefine,CalculationEvidenceButton:TButton;
    CalculationEvidenceList:TListBox;
    CalculationEvidenceSplitter:TSplitter;
    CalculationEvidenceMemo:TMemo;
    CalculationTab:TTabItem;
    CalculationPurpose,CalculationStatus,CalculationEvidenceLabel:TLabel;
    CalculationToolbar:THorzScrollBox;
    CalculationFilter:TEdit;
    CalculationState:TComboBox;
    CalculationFirst,CalculationNext,CalculationNew,CalculationOpen,CalculationLinks:TButton;
    CalculationList:TListBox;
    CalculationMemo:TMemo;
    CalculationEdit:TButton;
    CalculationEditorTab:TTabItem;
    CalculationEditorPurpose,CalculationAuthorLabel:TLabel;
    CalculationEditorToolbar:THorzScrollBox;
    CalculationAuthor:TEdit;
    CalculationApply,CalculationCancel:TButton;
    CalculationEditorScroll:TVertScrollBox;
    Calc_name_Row:TLayout;Calc_name_Label:TLabel;Calc_name:TMemo;
    Calc_meaning_Row:TLayout;Calc_meaning_Label:TLabel;Calc_meaning:TMemo;
    Calc_formula_Row:TLayout;Calc_formula_Label:TLabel;Calc_formula:TMemo;
    Calc_inputs_Row:TLayout;Calc_inputs_Label:TLabel;Calc_inputs:TMemo;
    Calc_outputs_Row:TLayout;Calc_outputs_Label:TLabel;Calc_outputs:TMemo;
    Calc_units_Row:TLayout;Calc_units_Label:TLabel;Calc_units:TMemo;
    Calc_rounding_Row:TLayout;Calc_rounding_Label:TLabel;Calc_rounding:TMemo;
    Calc_assumptions_Row:TLayout;Calc_assumptions_Label:TLabel;Calc_assumptions:TMemo;
    Calc_exceptions_Row:TLayout;Calc_exceptions_Label:TLabel;Calc_exceptions:TMemo;
    Calc_examples_Row:TLayout;Calc_examples_Label:TLabel;Calc_examples:TMemo;
    Calc_owner_Row:TLayout;Calc_owner_Label:TLabel;Calc_owner:TMemo;
    Calc_unknowns_Row:TLayout;Calc_unknowns_Label:TLabel;Calc_unknowns:TMemo;
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
    TaskReaderTitle: TLabel;
    TaskContextMemo: TMemo;
    TaskStepLabel: TLabel;
    TaskPrevious: TButton;
    TaskNext: TButton;
    TaskRestart: TButton;
    TaskNavigation: THorzScrollBox;
    TaskResultMemo: TMemo;
    TaskActionMemo: TMemo;
    TaskReaderPanel: TLayout;
    TaskReaderScroll: TVertScrollBox;
    TaskPickerLabel: TLabel;
    TaskFilter: TEdit;
    TaskRoleFilter,TaskPathFilter,TaskLearner: TEdit;
    TaskProgressLabel: TLabel;
    TaskContextExpander:TExpander;
    TaskRoleLabel,TaskPathLabel,TaskLearnerLabel:TLabel;
    TaskCheckStep,TaskResetProgress: TButton;
    TutorRole,TutorPath,TutorOrder: TEdit;
    TutorLearningLayout: THorzScrollBox;
    TutorRoleLabel,TutorPathLabel,TutorOrderLabel: TLabel;
    TaskNextPage: TButton;
    TaskList: TListBox;
    TaskPicker: TLayout;
    TaskNew: TButton;
    TaskEdit: TButton;
    TaskNotes: TButton;
    TaskToolbar: THorzScrollBox;
    TaskPurposeLabel: TLabel;
    TaskTab: TTabItem;
    Tutor_name_label: TLabel;
    Tutor_name: TMemo;
    Tutor_purpose_label: TLabel;
    Tutor_purpose: TMemo;
    Tutor_prerequisites_label: TLabel;
    Tutor_prerequisites: TMemo;
    Tutor_expected_result_label: TLabel;
    Tutor_expected_result: TMemo;
    Tutor_troubleshooting_label: TLabel;
    Tutor_troubleshooting: TMemo;
    Tutor_practice_label: TLabel;
    Tutor_practice: TMemo;
    TutorStepsLabel: TLabel;
    TutorSteps: TListBox;
    TutorNewStep: TButton;
    TutorKeepStep: TButton;
    TutorDiscardStep: TButton;
    TutorRemoveStep: TButton;
    TutorStepUp: TButton;
    TutorStepDown: TButton;
    TutorStepToolbar: THorzScrollBox;
    TutorActionLabel: TLabel;
    TutorAction: TMemo;
    TutorExpectedLabel: TLabel;
    TutorExpected: TMemo;
    TutorAuthorLabel: TLabel;
    TutorAuthor: TEdit;
    TutorSave: TButton;
    TutorCancel: TButton;
    TaskEditorToolbar: THorzScrollBox;
    TaskEditorPurpose: TLabel;
    TaskEditorScroll: TVertScrollBox;
    TaskEditorTab: TTabItem;
    WorkspacePageCombo,LessonPageCombo: TComboBox;
    SetupTab: TTabItem;
    SetupScroll: TVertScrollBox;
    SetupPurpose,AnalysisSettingsTitle,SetupMaterialLabel: TLabel;
    SetupLessonToolbar: THorzScrollBox;
    SetupProfileButton,SetupTaskButton: TButton;
    AnalysisSettingsExpander: TExpander;
    AnalysisSettingsLayout: TLayout;
    SetupButton: TButton;
    CardLibraryTab,CardEditorTab:TTabItem;
    CardToolbar,CardEditToolbar:THorzScrollBox;
    CardFilter,CardRole,CardAuthor:TEdit;
    CardCategory,CardDocumentLocation:TComboBox;
    CardList:TListBox;
    CardReader:TMemo;
    CardBrowser:TWebBrowser;
    CardNew,CardEdit,CardRelated,CardSave,CardCancel:TButton;
    CardPurpose,CardEditorPurpose,CardDocumentLocationLabel:TLabel;
    CardEditorScroll:TVertScrollBox;
    Card_name,Card_role,Card_meaning,Card_example,Card_limits,Card_help,Card_practice:TMemo;
    Card_name_label,Card_role_label,Card_meaning_label,Card_example_label,Card_limits_label,Card_help_label,Card_practice_label:TLabel;
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
    procedure LearnerTabClick(Sender: TObject);
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
    procedure ScreenshotPoint(Sender:TObject;Button:TMouseButton;Shift:TShiftState;X,Y:Single);
    procedure ScreenshotMarkerPaint(Sender:TObject;Canvas:TCanvas);
    procedure ScreenshotCalloutClick(Sender:TObject);
    procedure ScreenshotViewChange(Sender: TObject);
    procedure ScreenshotInspectClick(Sender: TObject);
    procedure ScreenshotReturnClick(Sender: TObject);
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

    procedure CalculationEvidenceFilterChange(Sender:TObject);
    procedure CalculationEvidenceSelectionChange(Sender:TObject);
    procedure CalculationEvidenceSourceClick(Sender:TObject);
    procedure CalculationEvidenceExplainClick(Sender:TObject);
    procedure CalculationEvidenceDefineClick(Sender:TObject);
    procedure CalculationEvidenceOpenClick(Sender:TObject);
    procedure CalculationFilterChange(Sender:TObject);
    procedure CalculationSelectionChange(Sender:TObject);
    procedure CalculationNewClick(Sender:TObject);
    procedure CalculationOpenClick(Sender:TObject);

    procedure CalculationEditClick(Sender:TObject);
    procedure CalculationApplyClick(Sender:TObject);
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
    procedure LearningBrowserDidFinishLoad(Sender: TObject);
    procedure RelocateClick(Sender: TObject);
    procedure TaskFilterChange(Sender: TObject);
    procedure TaskProgressClick(Sender: TObject);
    procedure CardFilterChange(Sender:TObject);
    procedure CardSelectionChange(Sender:TObject);
    procedure CardEditClick(Sender:TObject);
    procedure CardSaveClick(Sender:TObject);
    procedure CardCancelClick(Sender:TObject);
    procedure CardChanged(Sender:TObject);
    procedure CardRelatedClick(Sender:TObject);
    procedure TaskSelectionChange(Sender: TObject);
    procedure TaskNavigate(Sender: TObject);
    procedure TaskEditClick(Sender: TObject);
    procedure TaskOpenNotes(Sender: TObject);
    procedure TaskEditorChanged(Sender: TObject);
    procedure TutorStepSelection(Sender: TObject);
    procedure TutorStepChanged(Sender: TObject);
    procedure TutorStepAction(Sender: TObject);
    procedure TaskSaveClick(Sender: TObject);
    procedure TaskCancelClick(Sender: TObject);
    procedure SetupClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure OpenProjectClick(Sender: TObject);
    procedure OpenCacheClick(Sender: TObject);
    procedure CloseButtonClick(Sender: TObject);
    procedure SaveProjectClick(Sender: TObject);
    procedure RescanProjectClick(Sender: TObject);
    procedure AllowInternetChange(Sender: TObject);
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
    procedure LanguageChanged(Sender: TObject; const AOldLanguage,
      ANewLanguage: string; const AGeneration: Cardinal);
  private
    FWorker: TDPHWorkspaceWorker;
    FProgressForm: TDPHProgressForm;
    FView: TDPHWorkspaceView;
    FGraph,FScreen: TJSONObject;
    FExplorerKeys,FRelationKeys,FHistory,FBookmarks,FExpandedKeys: TList<string>;
    FHierarchyVisible,FShowingBookmarks: Boolean;
    FDetails: TJSONArray;
    FEntry,FDatabase,FSelected,FScope,FBaseDirectory: string;
    FNetworkSettingsPath: string;
    FLoadingNetworkPreference: Boolean;
    FPendingEntry,FPendingDatabase: string;
    FUnsavedDatabase,FPendingUnsavedDatabase,FPendingDiscardDatabase: string;
    FPendingWorkspaceTab: TTabItem;
    FScreenshotOriginTab: TTabItem;
    FPage: Integer;
    FBusy,FDetached,FClosing,FBinding,FRenderingScreens,FPreparingProject: Boolean;
    FPreparationCompletionTicks: Integer;
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
    FExpectedDossierPage,FExpectedGraphPage: string;
    FOfflinePreview: TDPHOfflinePreview;
    FImages: TJSONArray;
    FPendingScreenshots: TJSONArray;
    FCatalog: TDPHWorkspaceCatalog;
    FCatalogPaths: TList<string>;
    FCardRows:TList<TJSONObject>;
    FLibraryEntries:TJSONArray;
    FCardDraft:TJSONObject;
    FCardSavingID:string;
    FPictureX,FPictureY:Integer;
    FPicturePointValid:Boolean;
    FContinuity: TJSONArray;
    FSearchResults: TJSONArray;
    FSearchOffset: Integer;
    FSearchQuery: string;
    FSearchKind: string;
    FWholeGraph: Boolean;
    FLineageSeed,FLineageDirection:string;
    FPreviewPages: TList<string>;
    FHelpLanguageGeneration: Cardinal;
    FOverviewLanguageGeneration: Cardinal;
    FLibraryLanguageGeneration: Cardinal;
    FMapLanguageGeneration: Cardinal;
    FGraphLanguageGeneration: Cardinal;
    FPendingLanguageRefresh: Boolean;
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
    FTaskRows:TList<TJSONObject>;
    FTaskDraft:TJSONObject;
    FTaskOffset,FTaskStep,FTutorStep:Integer;
    FTutorStepDirty:Boolean;
    FTaskSavingID:string;
    FCalculationEvidence:TJSONObject;FCalculationEvidenceRows:TList<TJSONObject>;FCalculationEvidenceOffset:Integer;
    FCalculationRows:TList<TJSONObject>;FCalculationOffset:Integer;
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
    function PrepareOfflineProjectTranslation(var AHTML: string): Boolean;
    procedure ShowExplanation;
    procedure Submit(const ACommand: string);
    procedure RefreshExplorer;
    procedure SelectSymbol(const AKey: string; AHistory: Boolean = True);
    function DatabaseERRect(AIndex:Integer):TRectF;
    procedure DatabaseEREvidence(const AID:string);
    procedure RefreshGraphics;
    procedure UpdateScreenBounds;
    procedure UpdateScreenshotBounds;
    procedure UpdateLearnerNavigation;
    procedure GraphGroupDetails(const AGroup: string);
    procedure ClearWorkspace;
    function ResolveUnsavedProject(AClosing: Boolean; ADirectSave: Boolean = False): Boolean;
    procedure DiscardUnsavedProject(const ADatabase: string);
    function GraphRect(AIndex: Integer): TRectF;
  public
    procedure OpenSelection(const AEntry,ADatabase: string; AUnsaved: Boolean = False);
    procedure LoadView(ADocument: TJSONObject; AScreenshots: TJSONArray = nil; ADeferLearning: Boolean = False);
    procedure LoadKnowledge(ARows: TJSONArray; ADeferInitialViews: Boolean = False);
    procedure LoadScreenshots(ARows: TJSONArray);
    procedure LoadReviewTasks(ARows: TJSONArray);
    procedure LoadComparison(AReport: TJSONObject);
    procedure LoadScreenHistory(AReport:TJSONObject;const ABeforePNG,AAfterPNG,ADifferencePNG:TBytes);
    procedure LoadTranslations(ARows: TJSONArray);
    property WorkspaceView: TDPHWorkspaceView read FView;
  end;
var DPHMainForm: TDPHMainForm;
implementation
uses System.IOUtils, System.IniFiles, System.StrUtils, System.Math, System.Hash, System.Generics.Defaults, System.RegularExpressions, System.NetEncoding, DAT.Components.Core, DPH.Storage.Database, DPH.Storage.Backup, FMX.DialogService.Sync,
  Winapi.EdgeUtils, DPH.Workspace.Screen, DPH.Workspace.Graphs, DPH.Project.Source, DPH.Parse.Model, DPH.Publish.BrowserPolicy,
  DPH.Knowledge.ProjectProfile, DPH.UI.ProjectProfile, DPH.Workspace.Comparison, DPH.Knowledge.Glossary, DPH.UI.Glossary, DPH.Workspace.Keyboard, DPH.Workspace.Commands, DPH.Workspace.DynamicControls, DPH.Workspace.LayoutRules, DPH.Workspace.ComponentDependencies, DPH.Knowledge.ComponentDependency, DPH.UI.ComponentDependency, DPH.Workspace.FormInheritance, DPH.Knowledge.ActionPurpose, DPH.Workspace.ActionPurposes, DPH.UI.DatabaseDictionary, DPH.UI.ActionPurpose,DPH.Workspace.ScreenHistory,DPH.Workspace.DatabaseConnections,DPH.Workspace.DatabaseSchema;
{$R *.fmx}
procedure TDPHMainForm.FormCreate(Sender: TObject);
var I: Integer; DatabaseDirectory, SettingsDirectory: string; Settings: TIniFile;
begin
  FExplorerKeys:=TList<string>.Create; FRelationKeys:=TList<string>.Create; FExpandedKeys:=TList<string>.Create;
  FPreviewPages:=TList<string>.Create;
  FTaskRows:=TList<TJSONObject>.Create;
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
  FFileFormatRows:=TList<TJSONObject>.Create;FDataRetentionRows:=TList<TJSONObject>.Create;FTargetRecoveryRows:=TList<TJSONObject>.Create;FBusinessProcessRows:=TList<TJSONObject>.Create;FCalculationEvidenceRows:=TList<TJSONObject>.Create;FCalculationRows:=TList<TJSONObject>.Create;FBusinessRuleRows:=TList<TJSONObject>.Create;FDepartmentalWorkflowRows:=TList<TJSONObject>.Create;FDataQualityRows:=TList<TJSONObject>.Create;
  FDatabaseSchemaRows:=TList<TJSONObject>.Create;
  FDatabaseSchemaTargets:=TList<string>.Create;
  FDatabaseInventoryRows:=TList<TJSONObject>.Create;
  FDatabaseInventoryTargets:=TList<string>.Create;
  FInheritanceRows:=TList<TJSONObject>.Create;FInheritanceOrigins:=TList<TJSONObject>.Create;
  FDependencyRows:=TList<TJSONObject>.Create;
  FLayoutRows:=TList<TJSONObject>.Create;
  TryStrToInt(LayoutWidthEdit.Text,FLayoutWidthDelta);TryStrToInt(LayoutHeightEdit.Text,FLayoutHeightDelta);
  FCatalogPaths:=TList<string>.Create;
  FCardRows:=TList<TJSONObject>.Create;
  try FCatalog:=TDPHWorkspaceCatalog.Create(TDPHWorkspaceCatalog.DefaultPath);
  except on E: Exception do StatusLabel.Text:='Workspace catalog unavailable: '+E.Message; end;
  RefreshProjectsClick(nil);
  FBaseDirectory:=ExtractFilePath(ParamStr(0));
  for I:=0 to 5 do begin if TDirectory.Exists(TPath.Combine(FBaseDirectory,'migrations')) then Break; FBaseDirectory:=ExtractFileDir(ExcludeTrailingPathDelimiter(FBaseDirectory)); end;
  SettingsDirectory:=GetEnvironmentVariable('LOCALAPPDATA');
  if SettingsDirectory='' then SettingsDirectory:=TPath.GetHomePath;
  FNetworkSettingsPath:=TPath.Combine(TPath.Combine(SettingsDirectory,'DelphiProjectHandoff'),'settings.ini');
  FLoadingNetworkPreference:=True;
  try
    if TFile.Exists(FNetworkSettingsPath) then begin
      Settings:=TIniFile.Create(FNetworkSettingsPath);
      try AllowInternetCheck.IsChecked:=Settings.ReadBool('Privacy','ReadPublicWebsites',False);
      finally Settings.Free; end;
    end;
  except on E: Exception do StatusLabel.Text:='Internet preference could not be read; public websites remain disabled.';
  end;
  FLoadingNetworkPreference:=False;
  DatabaseDirectory:=TPath.Combine(FBaseDirectory,DatabaseDialog.InitialDir);
  try
    TDirectory.CreateDirectory(DatabaseDirectory);
    DatabaseDialog.InitialDir:=DatabaseDirectory; OpenCacheDialog.InitialDir:=DatabaseDirectory;
    BackupDialog.InitialDir:=DatabaseDirectory; RestoreBackupDialog.InitialDir:=DatabaseDirectory;
    RestoreDestinationDialog.InitialDir:=DatabaseDirectory;
  except on E: Exception do StatusLabel.Text:='Cannot prepare Databases folder: '+E.Message; end;
  FWorker:=TDPHWorkspaceWorker.Create(FBaseDirectory);
  FProgressForm:=TDPHProgressForm.Create(Self);
  LearningTopics.ItemIndex:=0;
  OverviewMemo.Visible:=False;
  LanguageCombo.RefreshLanguages;
  TaskFilterChange(nil);
  DataRetentionFilterChange(nil);TargetRecoveryFilterChange(nil);BusinessProcessFilterChange(nil);CalculationFilterChange(nil);BusinessRuleFilterChange(nil);DepartmentalWorkflowFilterChange(nil);DataQualityFilterChange(nil);CalculationEvidenceFilterChange(nil);
  if SameText(ExtractFileExt(ParamStr(1)),'.dphdb') then OpenSelection('',ParamStr(1));
  if (not FBusy) and (FView=nil) then begin HelpClick(nil); LearningClick(nil); end;
end;
procedure TDPHMainForm.FormDestroy(Sender: TObject);
var Directory: string;
begin
  PollTimer.Enabled:=False; ChangeTimer.Enabled:=False; FWorker.Free;
  FProgressForm.Free;
  FCatalog.Free; FCatalogPaths.Free;
  FCardRows.Free;FLibraryEntries.Free;FCardDraft.Free;
  FContinuity.Free;
  FSearchResults.Free; FCoverage.Free; FLinkTargets.Free; FEditableLinks.Free; FReviewTasks.Free; FQuestions.Free; FObservations.Free; FTranslations.Free;
  FPendingScreenshots.Free; FImages.Free; FExplanations.Free; FLearningFacts.Free;
  FOfflinePreview.Free;
  FView.Free; FGraph.Free; FScreen.Free; FExplorerKeys.Free; FRelationKeys.Free; FHistory.Free; FBookmarks.Free; FExpandedKeys.Free; FDetails.Free;
  FKnowledge.Free; FKnowledgeRows.Free; FGlossaryRows.Free;
  FProjectMembers.Free; FComparison.Free; FQualityRows.Free;FTaskRows.Free;FTaskDraft.Free;
  FKeyboardRows.Free; FKeyboard.Free;
  FCommandRows.Free; FCommands.Free;
  FDynamicRows.Free; FDynamic.Free;
  FActionPurposeRows.Free;FActionPurposes.Free;
  FHistoryRows.Free;FScreenHistory.Free;
  FDatabaseER.Free;
  FDataQualityRows.Free;FWorkflowDraft.Free;FDepartmentalWorkflowRows.Free;FCalculationEvidenceRows.Free;FCalculationEvidence.Free;FCalculationRows.Free;FBusinessRuleRows.Free;FBusinessProcessRows.Free;FTargetRecoveryRows.Free;FDataRetentionRows.Free;FFileFormatRows.Free;FFileFormats.Free;
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
procedure TDPHMainForm.UpdateLearnerNavigation;
const VisibleTabNumbers: array[0..5] of Integer = (0,1,3,4,6,7);
var
  Tabs: array[0..5] of TRectangle;
  Labels: array[0..5] of TLabel;
  TextLayout: TTextLayout;
  Index: Integer;
  AvailableWidth, RowWidth, TabWidth: Single;
  SecondRow: Boolean;
begin
  if (LearnerNavRow1=nil) or (LearnerNavRow2=nil) or FScreenFullscreen then Exit;
  for Index:=0 to High(Tabs) do begin
    Tabs[Index]:=FindComponent('LearnerTab'+IntToStr(VisibleTabNumbers[Index])) as TRectangle;
    Labels[Index]:=FindComponent('LearnerTabLabel'+IntToStr(VisibleTabNumbers[Index])) as TLabel;
    if (Tabs[Index]=nil) or (Labels[Index]=nil) then Exit;
  end;
  TextLayout:=TTextLayoutManager.DefaultTextLayout.Create;
  try
    TextLayout.Font:=Labels[0].TextSettings.Font;
    TextLayout.WordWrap:=False;
    TextLayout.Text:=AllowInternetCheck.Text.Replace(#$00AD,'');
    AllowInternetCheck.Width:=Min(260,Max(192,Ceil(TextLayout.Width)+34));
    TextLayout.Text:=OpenProjectButton.Text.Replace(#$00AD,'');
    OpenProjectButton.Width:=Min(230,Max(132,Ceil(TextLayout.Width)+30));
    TextLayout.Text:=OpenCacheButton.Text.Replace(#$00AD,'');
    OpenCacheButton.Width:=Min(240,Max(142,Ceil(TextLayout.Width)+30));
    TextLayout.Text:=SaveProjectButton.Text.Replace(#$00AD,'');
    SaveProjectButton.Width:=Min(190,Max(112,Ceil(TextLayout.Width)+30));
    TextLayout.Text:=RescanProjectButton.Text.Replace(#$00AD,'');
    RescanProjectButton.Width:=Min(190,Max(112,Ceil(TextLayout.Width)+30));
    TextLayout.Text:=CloseButton.Text.Replace(#$00AD,'');
    CloseButton.Width:=Min(150,Max(88,Ceil(TextLayout.Width)+24));
    OpenProjectButton.Height:=36;
    OpenCacheButton.Height:=36;
    SaveProjectButton.Height:=36;
    RescanProjectButton.Height:=36;
    CloseButton.Height:=36;
    AvailableWidth:=Max(1,ClientWidth-LearnerNavRow1.Margins.Left-LearnerNavRow1.Margins.Right);
    RowWidth:=OpenProjectButton.Width+OpenProjectButton.Margins.Left+OpenProjectButton.Margins.Right+
      OpenCacheButton.Width+OpenCacheButton.Margins.Left+OpenCacheButton.Margins.Right+
      SaveProjectButton.Width+SaveProjectButton.Margins.Left+SaveProjectButton.Margins.Right+
      RescanProjectButton.Width+RescanProjectButton.Margins.Left+RescanProjectButton.Margins.Right+
      CloseButton.Width+CloseButton.Margins.Left+CloseButton.Margins.Right;
    SecondRow:=False;
    for Index:=0 to High(Tabs) do begin
      if not Tabs[Index].Visible then Continue;
      TextLayout.Font:=Labels[Index].TextSettings.Font;
      TextLayout.Text:=Labels[Index].Text.Replace(#$00AD,'');
      TabWidth:=Min(205,Max(100,Ceil(TextLayout.Width)+30));
      Tabs[Index].Width:=TabWidth;
      TabWidth:=TabWidth+Tabs[Index].Margins.Left+Tabs[Index].Margins.Right;
      if not SecondRow and (RowWidth+TabWidth>AvailableWidth) then begin
        SecondRow:=True;
        RowWidth:=0;
      end;
      if SecondRow then begin
        if Tabs[Index].Parent<>LearnerNavRow2 then Tabs[Index].Parent:=LearnerNavRow2;
      end else if Tabs[Index].Parent<>LearnerNavRow1 then Tabs[Index].Parent:=LearnerNavRow1;
      RowWidth:=RowWidth+TabWidth;
    end;
    LearnerNavRow2.Visible:=SecondRow;
    if SecondRow then begin
      LearnerNavRow2.Height:=42;
      HeaderLayout.Height:=148;
    end else begin
      LearnerNavRow2.Height:=0;
      HeaderLayout.Height:=106;
    end;
  finally TextLayout.Free; end;
end;
procedure TDPHMainForm.LanguageChanged(Sender: TObject;
  const AOldLanguage, ANewLanguage: string; const AGeneration: Cardinal);
var PreviousScreen: Integer; SavedScreens: TJSONArray; ScreenRow: TJSONValue;
begin
  if FClosing or (FLearningDirectory = '') then Exit;
  FHelpLanguageGeneration := 0;
  FOverviewLanguageGeneration := 0;
  FLibraryLanguageGeneration := 0;
  FMapLanguageGeneration := 0;
  FGraphLanguageGeneration := 0;
  if (FView <> nil) and not FBusy then begin
    StatusLabel.Text:=DATFormatText('DPH.UI.Main.Runtime.StatusLabel_Text.Text.27b34e6d78564198',
      'Project information for %s is ready.',
      [#$2066+FView.Document.GetValue<string>('entry')+#$2069]);
    if not FView.Document.GetValue<Boolean>('analysis_complete') then
      StatusLabel.Text:=StatusLabel.Text+' '+DATFormatText(
        'DPH.UI.Main.Runtime.StatusLabel_Text.Text.994988eeb78b8d77',
        '%s Some code could not be explained; check unanswered questions.', ['']);
  end;
  UpdateLearnerNavigation;
  if (FView<>nil) and not FBusy then begin
    if FPendingScreenshots=nil then begin
      SavedScreens:=TJSONArray.Create;
      if FImages<>nil then for ScreenRow in FImages do
        if ScreenRow.GetValue<Int64>('artifact_id',0)>0 then
          SavedScreens.AddElement(ScreenRow.Clone as TJSONValue);
      FPendingScreenshots:=SavedScreens;
    end;
    if WorkspaceTabs.ActiveTab=ScreenshotTab then begin
      PreviousScreen:=ScreenshotList.ItemIndex;
      SavedScreens:=FPendingScreenshots;
      FPendingScreenshots:=nil;
      LoadScreenshots(SavedScreens);
      if (PreviousScreen>=0) and (PreviousScreen<ScreenshotList.Count) then begin
        ScreenshotList.ItemIndex:=PreviousScreen;
        ScreenshotClick(nil);
      end;
    end;
  end;
  FPendingLanguageRefresh := True;
end;
procedure TDPHMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if FKnowledgeEdited then begin CanClose:=False; StatusLabel.Text:='Save or discard the authored text before closing'; Exit; end;
  if FRenderingScreens then begin CanClose:=False; Exit; end;
  CanClose:=not FBusy;
  if not CanClose then begin FClosing:=True; FWorker.Stop; StatusLabel.Text:='Cancelling at a safe analysis boundary...'; Exit; end;
  CanClose:=ResolveUnsavedProject(True);
  if CanClose and (FPendingUnsavedDatabase<>'') then
    try DiscardUnsavedProject(FPendingUnsavedDatabase);
    except on E: Exception do begin
      StatusLabel.Text:='Temporary project cleanup failed: '+E.Message;
      CanClose:=False;
    end; end;
  if not CanClose and FWorker.Finished then begin
    if (FPendingUnsavedDatabase<>'') and
      not SameFileName(FPendingUnsavedDatabase,FUnsavedDatabase) then
      try DiscardUnsavedProject(FPendingUnsavedDatabase);
      except on E: Exception do StatusLabel.Text:='Temporary project cleanup failed: '+E.Message; end;
    FPendingEntry:=''; FPendingDatabase:=''; FPendingUnsavedDatabase:='';
    FPendingDiscardDatabase:=''; FPendingCommand:='';
    FPreparingProject:=False; ProjectPreparationLayout.Visible:=False;
    WorkspaceTabs.Enabled:=True;
    FWorker.Free;
    FWorker:=TDPHWorkspaceWorker.Create(FBaseDirectory);
  end;
end;
procedure TDPHMainForm.CloseButtonClick(Sender: TObject);
begin
  Close;
end;
procedure TDPHMainForm.SaveProjectClick(Sender: TObject);
begin
  if FBusy or (FUnsavedDatabase='') then Exit;
  ResolveUnsavedProject(False,True);
  SaveProjectButton.Enabled:=FUnsavedDatabase<>'';
end;
procedure TDPHMainForm.RescanProjectClick(Sender: TObject);
begin
  if FBusy or FDetached or (FEntry='') or (FView=nil) then Exit;
  if FKnowledgeEdited then begin
    StatusLabel.Text:='Save or discard the authored text before rescanning the project';
    Exit;
  end;
  Submit('incremental');
end;
procedure TDPHMainForm.AllowInternetChange(Sender: TObject);
var Settings: TIniFile;
begin
  if FLoadingNetworkPreference or (FNetworkSettingsPath='') then Exit;
  try
    TDirectory.CreateDirectory(ExtractFileDir(FNetworkSettingsPath));
    Settings:=TIniFile.Create(FNetworkSettingsPath);
    try Settings.WriteBool('Privacy','ReadPublicWebsites',AllowInternetCheck.IsChecked);
    finally Settings.Free; end;
  except on E: Exception do begin
    StatusLabel.Text:='Internet preference could not be saved: '+E.Message;
    Exit;
  end; end;
  if AllowInternetCheck.IsChecked then
    StatusLabel.Text:='Public website reading enabled for the next project analysis.'
  else
    StatusLabel.Text:='Public website reading disabled; project analysis stays offline.';
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
procedure TDPHMainForm.CardFilterChange(Sender:TObject);
var V,W:TJSONValue;R,Section,Group:TJSONObject; Guides,Screens,Sites,GuideIndexes:TJSONArray;
  Title,Query,Source,GroupKey,DisplayTitle:string; I,J:Integer; MatchesQuery:Boolean;
begin
 if FCardRows=nil then Exit;
 FCardRows.Clear;CardList.Items.Clear;FreeAndNil(FLibraryEntries);FLibraryEntries:=TJSONArray.Create;
 CardDocumentLocation.TagString:='';CardDocumentLocation.Visible:=False;CardDocumentLocationLabel.Visible:=False;
 Query:=CardFilter.Text.Trim;
 if FLearningFacts<>nil then begin
  Guides:=FLearningFacts.Document.GetValue<TJSONArray>('project_guides',nil);
  if Guides<>nil then for I:=0 to Guides.Count-1 do begin
   R:=Guides.Items[I] as TJSONObject;
   Source:=R.GetValue<string>('source','');Title:=TPath.GetFileName(Source);
   MatchesQuery:=(Query='') or ContainsText(Source,Query);
   if not MatchesQuery then for W in R.GetValue<TJSONArray>('sections') do begin
    Section:=W as TJSONObject;
    if ContainsText(Section.GetValue<string>('heading','')+' '+Section.GetValue<string>('text',''),Query) then begin
     MatchesQuery:=True;Break;
    end;
   end;
   if not MatchesQuery then Continue;
   GroupKey:=LowerCase(TPath.GetFileNameWithoutExtension(Title));Group:=nil;
   for W in FLibraryEntries do
     if (W.GetValue<string>('library_kind','')='document_group') and
       SameText(W.GetValue<string>('group_key',''),GroupKey) then begin Group:=W as TJSONObject;Break;end;
   if Group=nil then begin
     DisplayTitle:=TRegEx.Replace(TPath.GetFileNameWithoutExtension(Title).Replace('_',' ').Replace('-',' '),'\s+',' ').Trim;
     Group:=TJSONObject.Create.AddPair('library_kind','document_group').AddPair('group_key',GroupKey)
       .AddPair('heading',DisplayTitle);
     GuideIndexes:=TJSONArray.Create;Group.AddPair('guide_indices',GuideIndexes);
     FLibraryEntries.AddElement(Group);FCardRows.Add(Group);
     CardList.Items.Add('Document: '+DisplayTitle);
   end else GuideIndexes:=Group.GetValue<TJSONArray>('guide_indices');
   GuideIndexes.AddElement(TJSONNumber.Create(I));
   if GuideIndexes.Count>1 then begin
     J:=FCardRows.IndexOf(Group);
     CardList.Items[J]:='Document: '+Group.GetValue<string>('heading')+' ('+GuideIndexes.Count.ToString+' locations)';
   end;
  end;
  Sites:=FLearningFacts.Document.GetValue<TJSONArray>('project_sites',nil);
  if Sites<>nil then for V in Sites do begin
   R:=V as TJSONObject;
   if R.GetValue<string>('text','').Trim='' then Continue;
   Title:=R.GetValue<string>('url','');
   if (Query<>'') and not ContainsText(Title+' '+R.GetValue<string>('text',''),Query) then Continue;
   FCardRows.Add(R);CardList.Items.Add('Public website: '+Title);
  end;
  Screens:=FLearningFacts.Document.GetValue<TJSONArray>('project_screens',nil);
  if Screens<>nil then for V in Screens do begin
   R:=V as TJSONObject;Title:=R.GetValue<string>('title','').Trim;
   if Title='' then Title:=R.GetValue<string>('name','Screen');
   if (Query<>'') and not ContainsText(Title+' '+R.GetValue<string>('source',''),Query) then Continue;
   FCardRows.Add(R);CardList.Items.Add('Screen: '+Title);
  end;
 end;
 for I:=0 to CardList.Count-1 do begin
   CardList.ListItems[I].StyledSettings:=CardList.ListItems[I].StyledSettings-[TStyledSetting.Other];
   CardList.ListItems[I].WordWrap:=True;
   CardList.ListItems[I].Trimming:=TTextTrimming.None;
   if Length(CardList.Items[I])>84 then CardList.ListItems[I].Height:=76
   else if Length(CardList.Items[I])>42 then CardList.ListItems[I].Height:=54
   else CardList.ListItems[I].Height:=30;
 end;
 if CardList.Count>0 then CardList.ItemIndex:=0;
 CardSelectionChange(nil);
end;
procedure TDPHMainForm.CardSelectionChange(Sender:TObject);
var R,Section,Symbol,Group:TJSONObject; V,W:TJSONValue; Guides,GuideIndexes:TJSONArray; Body,Title,HTML,Line,Path,ParagraphText,
  Source,CaptionText,NextLine,CellText:string; Lines:TStringList; Sections,Symbols:TJSONArray;
  Cells:TArray<string>; I,J,Count,GuideIndex:Integer; Offline,InTable,InList,InCode,IsTableHeader,
    IsOrderedItem,ListOrdered,IsStandaloneHeading,OldBinding:Boolean;
begin
 if FBinding and (Sender=CardDocumentLocation) then Exit;
 CardEdit.Enabled:=False;CardRelated.Enabled:=False;CardRelated.TagString:='';
 CardReader.Text:='Choose a topic to explore this application.';
 if (FCardRows=nil) or (CardList.ItemIndex<0) or (CardList.ItemIndex>=FCardRows.Count) then begin
   CardDocumentLocation.Visible:=False;CardDocumentLocationLabel.Visible:=False;
   CardBrowser.Visible:=False;CardReader.Visible:=True;Exit;
 end;
 R:=FCardRows[CardList.ItemIndex];
 if R.GetValue<string>('library_kind','')='document_group' then begin
   Group:=R;GuideIndexes:=Group.GetValue<TJSONArray>('guide_indices');
   Guides:=FLearningFacts.Document.GetValue<TJSONArray>('project_guides');
   if CardDocumentLocation.TagString<>Group.GetValue<string>('group_key') then begin
     OldBinding:=FBinding;FBinding:=True;
     try
       CardDocumentLocation.Items.Clear;
       for V in GuideIndexes do begin
         GuideIndex:=StrToInt(V.Value);
         CardDocumentLocation.Items.Add(Guides.Items[GuideIndex].GetValue<string>('source').Replace('/','  >  '));
       end;
       CardDocumentLocation.ItemIndex:=0;
       CardDocumentLocation.TagString:=Group.GetValue<string>('group_key');
     finally FBinding:=OldBinding;end;
   end;
   CardDocumentLocation.Visible:=GuideIndexes.Count>1;
   CardDocumentLocationLabel.Visible:=CardDocumentLocation.Visible;
   GuideIndex:=StrToInt(GuideIndexes.Items[Max(0,CardDocumentLocation.ItemIndex)].Value);
   R:=Guides.Items[GuideIndex] as TJSONObject;
 end else begin
   CardDocumentLocation.TagString:='';CardDocumentLocation.Visible:=False;CardDocumentLocationLabel.Visible:=False;
 end;
 if R.GetValue<string>('library_kind','')='route' then begin
   Title:=R.GetValue<string>('heading','Learning route');
   HTML:=TDPHHandoffDossier.Render(FLearningFacts.Document,
     R.GetValue<Integer>('route_index',0));
   Body:=TRegEx.Replace(HTML,'</(p|h[1-6]|li|section|ol|ul)>|<br\s*/?>',sLineBreak,[roIgnoreCase]);
   CardReader.Text:=TNetEncoding.HTML.Decode(TRegEx.Replace(Body,'<[^>]+>','')).Trim;
 end else if R.GetValue<string>('url','')<>'' then begin
   Title:=R.GetValue<string>('url','Public website');
   Body:='Captured from this public website during project analysis:'+sLineBreak+sLineBreak+
     R.GetValue<string>('text','');
   CardReader.Text:=Body;
 end else if R.GetValue<TJSONArray>('sections',nil)<>nil then begin
   Source:=R.GetValue<string>('source','');Title:=TPath.GetFileName(Source);
   Body:='';Sections:=R.GetValue<TJSONArray>('sections');
   if Sections.Count=0 then
     Body:=R.GetValue<string>('read_note','No readable content was found in this document.');
   for V in Sections do begin
     Section:=V as TJSONObject;Line:=Section.GetValue<string>('heading','').Trim;
     if (Line<>'') and not TRegEx.IsMatch(Line,'^Page\s+\d+$',[roIgnoreCase]) then
       Body:=Body+sLineBreak+sLineBreak+'## '+Line;
     ParagraphText:=Section.GetValue<string>('text','').Trim;
     if ParagraphText<>'' then Body:=Body+sLineBreak+sLineBreak+ParagraphText;
   end;
   Body:=TRegEx.Replace(Body,'(?i)\bPAGEREF\s+[_A-Za-z0-9.-]+(?:\s+\\[A-Za-z]+)*','').Trim;
   CardReader.Text:=Title+sLineBreak+sLineBreak+Body;
 end else begin
   Title:=R.GetValue<string>('title',R.GetValue<string>('name','Screen'));
   Source:=R.GetValue<string>('source','');
   Body:='This screen is defined in '+Source+'. DPH can show its saved controls in the Screenshots tab.';
   Symbols:=FLearningFacts.Document.GetValue<TJSONArray>('symbols',nil);Count:=0;
   if Symbols<>nil then for V in Symbols do begin
     Symbol:=V as TJSONObject;
     if (Symbol.GetValue<string>('kind','')<>'component') or
       not SameText(Symbol.GetValue<string>('range.source',''),Source) or
       (Symbol.GetValue<TJSONArray>('serialized_properties',nil)=nil) then Continue;
     CaptionText:='';
     for W in Symbol.GetValue<TJSONArray>('serialized_properties') do
       if MatchText(W.GetValue<string>('name',''),['Text','Caption']) then begin
         CaptionText:=W.GetValue<string>('value','').Trim(['''',' ']);Break;
       end;
     if (CaptionText='') or (Length(CaptionText)>120) then Continue;
     if Count=0 then Body:=Body+sLineBreak+sLineBreak+'## Controls visible in the saved design';
     Body:=Body+sLineBreak+'- '+CaptionText;Inc(Count);
     if Count>=24 then Break;
   end;
   if Count=0 then Body:=Body+sLineBreak+sLineBreak+'No labeled controls were captured for this screen.';
   CardReader.Text:=Title+sLineBreak+sLineBreak+Body;
 end;
 if R.GetValue<string>('library_kind','')<>'route' then begin
 HTML:='<!doctype html><html><head><meta charset="utf-8"><style>body{font:17px/1.65 Segoe UI,Arial,sans-serif;color:#19364e;max-width:950px;margin:36px auto;padding:0 28px;background:#fff}h1{color:#146cb4;font-size:30px;line-height:1.25;border-bottom:4px solid #f28a28;padding-bottom:14px}h2,h3{color:#146cb4;line-height:1.3;margin-top:32px}h2{font-size:23px}h3{font-size:19px}p{margin:16px 0}li{margin:8px 0}article{white-space:normal;overflow-wrap:anywhere}ul{padding-left:26px}'+
   'code{font:0.9em Consolas,monospace;background:#edf3f8;padding:2px 4px;border-radius:3px}pre{overflow:auto;background:#edf3f8;padding:16px;border-radius:6px}pre code{padding:0}blockquote{border-left:4px solid #f28a28;margin:20px 0;padding:4px 18px;background:#fff8f0}.table-scroll{overflow-x:auto;margin:20px 0;border:1px solid #d7e2ec;border-radius:6px}'+
   'table{border-collapse:collapse;width:100%;font-size:15px;line-height:1.5}th,td{text-align:left;vertical-align:top;padding:10px 12px;border-bottom:1px solid #d7e2ec}th{background:#e8f2fa;color:#145c99}tr:nth-child(even) td{background:#f8fbfd}</style></head><body><article><h1>'+
   TNetEncoding.HTML.Encode(Title)+'</h1>';
 if R.GetValue<TJSONArray>('sections',nil)<>nil then
   HTML:=HTML.Replace('<article>','<article class="project-prose">');
 Lines:=TStringList.Create;
 try
   Lines.Text:=Body;
   ParagraphText:='';InTable:=False;InList:=False;InCode:=False;ListOrdered:=False;
   for I:=0 to Lines.Count-1 do begin
     Line:=Trim(Lines[I]);
     NextLine:='';if I<Lines.Count-1 then NextLine:=Trim(Lines[I+1]);
     IsOrderedItem:=TRegEx.IsMatch(Line,'^\d+[.)]\s+');
     IsStandaloneHeading:=(Length(Line)<90) and Line.EndsWith(':') and
       (NextLine.StartsWith('|') or ((NextLine='') and (I<Lines.Count-2) and
         Trim(Lines[I+2]).StartsWith('|')));
     if Line.StartsWith('```') then begin
       if ParagraphText<>'' then begin HTML:=HTML+'<p>'+ParagraphText+'</p>';ParagraphText:='';end;
       if InList then begin if ListOrdered then HTML:=HTML+'</ol>' else HTML:=HTML+'</ul>';InList:=False;end;
       if InTable then begin HTML:=HTML+'</tbody></table></div>';InTable:=False;end;
       if InCode then HTML:=HTML+'</code></pre>' else HTML:=HTML+'<pre><code>';
       InCode:=not InCode;Continue;
     end;
     if InCode then begin HTML:=HTML+TNetEncoding.HTML.Encode(Lines[I])+sLineBreak;Continue;end;
     if InTable and not Line.StartsWith('|') then begin HTML:=HTML+'</tbody></table></div>';InTable:=False;end;
     if InList and not (Line.StartsWith('- ') or Line.StartsWith('* ') or IsOrderedItem) then begin
       if ListOrdered then HTML:=HTML+'</ol>' else HTML:=HTML+'</ul>';InList:=False;
     end;
     if (Line='') or Line.StartsWith('# ') or Line.StartsWith('## ') or
       Line.StartsWith('### ') or Line.StartsWith('- ') or Line.StartsWith('* ') or
       IsOrderedItem or IsStandaloneHeading or Line.StartsWith('|') or Line.StartsWith('> ') then
       if ParagraphText<>'' then begin HTML:=HTML+'<p>'+ParagraphText+'</p>';ParagraphText:='';end;
     if Line='' then Continue;
     if Line.StartsWith('|') and TRegEx.IsMatch(Line,'^[|:\-\s]+$') then Continue;
     if Line.StartsWith('|') and (InTable or TRegEx.IsMatch(NextLine,'^[|:\-\s]+$')) then begin
       IsTableHeader:=not InTable;
       if not InTable then begin HTML:=HTML+'<div class="table-scroll"><table><thead><tr>';InTable:=True;end
       else HTML:=HTML+'<tr>';
       Cells:=Line.Split(['|']);
       for J:=Low(Cells) to High(Cells) do begin
         if ((J=Low(Cells)) or (J=High(Cells))) and (Trim(Cells[J])='') then Continue;
         CellText:=TNetEncoding.HTML.Encode(Trim(Cells[J]));
         CellText:=TRegEx.Replace(CellText,'`([^`]+)`','<code>$1</code>');
         CellText:=TRegEx.Replace(CellText,'\*\*([^*]+)\*\*','<strong>$1</strong>');
         if IsTableHeader then HTML:=HTML+'<th>'+CellText+'</th>' else HTML:=HTML+'<td>'+CellText+'</td>';
       end;
       if IsTableHeader then HTML:=HTML+'</tr></thead><tbody>' else HTML:=HTML+'</tr>';
       Continue;
     end;
     Line:=TNetEncoding.HTML.Encode(Line);
     Line:=TRegEx.Replace(Line,'`([^`]+)`','<code>$1</code>');
     Line:=TRegEx.Replace(Line,'\*\*([^*]+)\*\*','<strong>$1</strong>');
     Line:=TRegEx.Replace(Line,'\[([^\]]+)\]\(https?://[^)]+\)','$1');
     if IsStandaloneHeading then HTML:=HTML+'<h2>'+Line+'</h2>'
     else if Line.StartsWith('# ') or Line.StartsWith('## ') or Line.StartsWith('### ') then begin
       if Line.StartsWith('### ') then HTML:=HTML+'<h3>'+Copy(Line,5,MaxInt)+'</h3>'
       else HTML:=HTML+'<h2>'+Line.TrimLeft(['#',' '])+'</h2>';
     end else if Line.StartsWith('- ') or Line.StartsWith('* ') then begin
       if InList and ListOrdered then begin HTML:=HTML+'</ol>';InList:=False;end;
       if not InList then begin HTML:=HTML+'<ul>';InList:=True;ListOrdered:=False;end;
       HTML:=HTML+'<li>'+Copy(Line,3,MaxInt)+'</li>';
     end else if IsOrderedItem then begin
       if InList and not ListOrdered then begin HTML:=HTML+'</ul>';InList:=False;end;
       if not InList then begin HTML:=HTML+'<ol>';InList:=True;ListOrdered:=True;end;
       HTML:=HTML+'<li>'+TRegEx.Replace(Line,'^\d+[.)]\s+','')+'</li>';
     end else if Line.StartsWith('&gt; ') then HTML:=HTML+'<blockquote>'+Copy(Line,6,MaxInt)+'</blockquote>'
     else begin
       if ParagraphText<>'' then ParagraphText:=ParagraphText+' ';
       ParagraphText:=ParagraphText+Line;
     end;
   end;
   if ParagraphText<>'' then HTML:=HTML+'<p>'+ParagraphText+'</p>';
   if InList then begin if ListOrdered then HTML:=HTML+'</ol>' else HTML:=HTML+'</ul>';end;
   if InTable then HTML:=HTML+'</tbody></table></div>';
   if InCode then HTML:=HTML+'</code></pre>';
 finally Lines.Free;end;
 if (R.GetValue<TJSONArray>('sections',nil)=nil) and (R.GetValue<string>('url','')='') then
   HTML:=HTML+'<p><a href="index.html#form_'+THashSHA2.GetHashString(R.GetValue<string>('source',''))+'">Open this screen</a></p>';
 HTML:=HTML+'</article></body></html>';
 end;
 if FLearningDirectory='' then Exit;
 HTML:=DATTranslateHtmlText(HTML);
 Offline:=PrepareOfflineProjectTranslation(HTML);
 Path:=TPath.Combine(FLearningDirectory,THashSHA2.GetHashString(HTML)+'.html');
 try
   TFile.WriteAllBytes(Path,TEncoding.UTF8.GetBytes(HTML));
   TFile.WriteAllBytes(TPath.Combine(FLearningDirectory,'index.html'),TEncoding.UTF8.GetBytes(HTML));
   CardBrowser.WindowsEngine:=TWindowsEngine.EdgeOnly;CardReader.Visible:=False;CardBrowser.Visible:=True;
   if Offline then CardBrowser.Navigate(FOfflinePreview.URLForPage(Path))
   else CardBrowser.Navigate('file://'+Path);
 except on E:Exception do begin CardBrowser.Visible:=False;CardReader.Visible:=True;end;end;
end;
procedure TDPHMainForm.CardRelatedClick(Sender:TObject);
begin
 if (CardList.ItemIndex<0) or (CardList.ItemIndex>=FCardRows.Count) then Exit;
 if (FView=nil) or (FView.Symbol(CardRelated.TagString)=nil) then Exit;
 SelectSymbol(CardRelated.TagString);WorkspaceTabs.ActiveTab:=ExplainTab;
end;
procedure TDPHMainForm.CardChanged(Sender:TObject);
begin if not FBinding and (FCardDraft<>nil) then begin FKnowledgeEdited:=True;FStructuredEditorPending:=True;end;end;
procedure TDPHMainForm.CardEditClick(Sender:TObject);
var Key,ID:string;I:Integer;
begin
 if FBusy or (FView=nil) then Exit;
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or cancel the current draft first';Exit;end;
 if Sender=CardNew then begin NewKnowledgeClick(nil);FCardDraft:=TDPHWorkspaceView.NewLearningCard;end
 else begin
  if (CardList.ItemIndex<0) or (CardList.ItemIndex>=FCardRows.Count) then Exit;
  ID:=FCardRows[CardList.ItemIndex].GetValue<string>('id');PendingKnowledgeCheck.IsChecked:=False;KnowledgeFilterChange(nil);
  for I:=0 to FKnowledgeRows.Count-1 do if FKnowledgeRows[I].GetValue<string>('id')=ID then begin KnowledgeList.ItemIndex:=I;KnowledgeClick(nil);Break;end;
  FreeAndNil(FCardDraft);FCardDraft:=TJSONObject.ParseJSONValue(FKnowledgeStructuredJSON) as TJSONObject;
 end;
 FBinding:=True;
 try
  for Key in ['name','role','meaning','example','limits','help','practice'] do (FindComponent('Card_'+Key) as TMemo).Text:=FCardDraft.GetValue<string>('fields.'+Key);
  CardCategory.ItemIndex:=CardCategory.Items.IndexOf(FCardDraft.GetValue<string>('category'));CardAuthor.Text:=KnowledgeAuthorEdit.Text;Card_name.ReadOnly:=FKnowledgeID<>0;
 finally FBinding:=False;end;
 FKnowledgeEdited:=True;FStructuredEditorPending:=True;WorkspaceTabs.ActiveTab:=CardEditorTab;
end;
procedure TDPHMainForm.CardCancelClick(Sender:TObject);
begin if FBusy then Exit;DiscardKnowledgeClick(nil);FreeAndNil(FCardDraft);WorkspaceTabs.ActiveTab:=CardLibraryTab;end;
procedure TDPHMainForm.CardSaveClick(Sender:TObject);
var Key:string;Fields:TJSONObject;
begin
 if FBusy or (FView=nil) or (FCardDraft=nil) then Exit;
 try
  Fields:=FCardDraft.GetValue<TJSONObject>('fields');
  for Key in ['name','role','meaning','example','limits','help','practice'] do begin Fields.RemovePair(Key).Free;Fields.AddPair(Key,(FindComponent('Card_'+Key) as TMemo).Text.Trim);end;
  if CardCategory.ItemIndex<0 then raise EArgumentException.Create('Choose a teaching topic');
  FCardDraft.RemovePair('category').Free;FCardDraft.AddPair('category',CardCategory.Selected.Text);TDPHWorkspaceView.ValidateLearningCard(FCardDraft);
  if (CardAuthor.Text.Trim='') or SameText(CardAuthor.Text.Trim,'Unknown') then raise EArgumentException.Create('Enter the person supplying this explanation');
  FBinding:=True;
  try
   KnowledgeTitleEdit.Text:=Fields.GetValue<string>('name').Trim;KnowledgeAuthorEdit.Text:=CardAuthor.Text.Trim;
   KnowledgeBodyMemo.Text:=TDPHWorkspaceView.LearningCardBody(FCardDraft);FKnowledgeStructuredJSON:=FCardDraft.ToJSON;FKnowledgeQuestionJSON:='';
   KnowledgeKindCombo.ItemIndex:=KnowledgeKindCombo.Items.IndexOf('user_help');KnowledgeDocumentCombo.ItemIndex:=KnowledgeDocumentCombo.Items.IndexOf('user');KnowledgeAudienceCombo.ItemIndex:=KnowledgeAudienceCombo.Items.IndexOf('all');
  finally FBinding:=False;end;
  FStructuredEditorPending:=False;FCardSavingID:=FCardDraft.GetValue<string>('card_id');Submit('save_knowledge');
  if FBusy then begin CardEditorScroll.Enabled:=False;CardEditToolbar.Enabled:=False;end else FCardSavingID:='';
 except on E:Exception do StatusLabel.Text:=E.Message;end;
end;
procedure TDPHMainForm.TaskFilterChange(Sender:TObject);
var V:TJSONValue;R,Lesson,Learning:TJSONObject;Count:Integer;Candidates:TList<TJSONObject>;
begin
 if FTaskRows=nil then Exit;
 if Sender=TaskNextPage then Inc(FTaskOffset,50) else FTaskOffset:=0;
 FTaskRows.Clear;TaskList.Items.Clear;TaskNextPage.Enabled:=False;Count:=0;
 Candidates:=TList<TJSONObject>.Create;
 try
 if FKnowledge<>nil then for V in FKnowledge do begin
  R:=V as TJSONObject;
  if MatchText(R.GetValue<string>('state'),['retired','rejected']) then Continue;
  if not MatchText(R.GetValue<string>('kind'),['user_help','troubleshooting']) then Continue;
  if (TaskFilter.Text.Trim<>'') and not ContainsText(R.GetValue<string>('title')+' '+R.GetValue<string>('body'),TaskFilter.Text.Trim) then Continue;
  Lesson:=TJSONObject.ParseJSONValue(R.GetValue<string>('structured_json','{}')) as TJSONObject;
  try
   Learning:=nil;if Lesson<>nil then Learning:=Lesson.GetValue<TJSONObject>('learning',nil);
   if (Lesson<>nil) and (Lesson.GetValue<string>('record_type','')<>'') and (Lesson.GetValue<string>('record_type','')<>'learning_lesson') then Continue;
   if (TaskRoleFilter.Text.Trim<>'') and (Learning<>nil) and (Learning.GetValue<string>('role','').Trim<>'') and
     not SameText(Learning.GetValue<string>('role'),TaskRoleFilter.Text.Trim) then Continue;
   if (TaskPathFilter.Text.Trim<>'') and ((Learning=nil) or not SameText(Learning.GetValue<string>('path'),TaskPathFilter.Text.Trim)) then Continue;
   Candidates.Add(R);
  finally Lesson.Free;end;
 end;
 Candidates.Sort(TComparer<TJSONObject>.Construct(function(const L,R:TJSONObject):Integer
 var LeftLesson,RightLesson:TJSONObject;
 begin
  LeftLesson:=TJSONObject.ParseJSONValue(L.GetValue<string>('structured_json','{}')) as TJSONObject;
  RightLesson:=TJSONObject.ParseJSONValue(R.GetValue<string>('structured_json','{}')) as TJSONObject;
  try
   Result:=CompareText(LeftLesson.GetValue<string>('learning.path',''),RightLesson.GetValue<string>('learning.path',''));
   if Result=0 then Result:=CompareValue(LeftLesson.GetValue<Integer>('learning.order',10000),RightLesson.GetValue<Integer>('learning.order',10000));
   if Result=0 then Result:=CompareText(L.GetValue<string>('title'),R.GetValue<string>('title'));
  finally LeftLesson.Free;RightLesson.Free;end;
 end));
 for R in Candidates do begin
  if (Count>=FTaskOffset) and (FTaskRows.Count<50) then begin FTaskRows.Add(R);TaskList.Items.Add(R.GetValue<string>('title'));end;Inc(Count);
 end;
 finally Candidates.Free;end;
 TaskNextPage.Enabled:=Count>FTaskOffset+FTaskRows.Count;
 if TaskList.Count>0 then TaskList.ItemIndex:=0;
 TaskSelectionChange(nil);
end;
procedure TDPHMainForm.TaskSelectionChange(Sender:TObject);
var R,Lesson:TJSONObject;
begin
 FTaskStep:=0;
 if (FCatalog<>nil) and (FDatabase<>'') and (FTaskRows<>nil) and (TaskList.ItemIndex>=0) and (TaskList.ItemIndex<FTaskRows.Count) then begin
  R:=FTaskRows[TaskList.ItemIndex];
  if TDPHWorkspaceView.IsLearningLesson(R) then begin
   Lesson:=TJSONObject.ParseJSONValue(R.GetValue<string>('structured_json')) as TJSONObject;
   try FTaskStep:=FCatalog.LearningProgress(FDatabase,TaskLearner.Text,Lesson.GetValue<string>('lesson_id'),R.GetValue<Int64>('revision'));
   finally Lesson.Free;end;
  end;
 end;
 TaskNavigate(nil);
end;
procedure TDPHMainForm.TaskProgressClick(Sender:TObject);
var R,Lesson:TJSONObject;Checked:Integer;
begin
 if (FCatalog=nil) or (FDatabase='') or (TaskList.ItemIndex<0) or (TaskList.ItemIndex>=FTaskRows.Count) then Exit;
 R:=FTaskRows[TaskList.ItemIndex];if not TDPHWorkspaceView.IsLearningLesson(R) then Exit;
 Lesson:=TJSONObject.ParseJSONValue(R.GetValue<string>('structured_json')) as TJSONObject;
 try
  Checked:=FCatalog.LearningProgress(FDatabase,TaskLearner.Text,Lesson.GetValue<string>('lesson_id'),R.GetValue<Int64>('revision'));
  if (Sender<>TaskResetProgress) and (Checked>=Lesson.GetValue<TJSONArray>('steps').Count) then Exit;
  if Sender=TaskResetProgress then begin Checked:=0;FTaskStep:=0;end
  else if FTaskStep=Checked then Inc(Checked) else raise EArgumentException.Create('Check each earlier step before marking this one');
  FCatalog.SetLearningProgress(FDatabase,TaskLearner.Text,Lesson.GetValue<string>('lesson_id'),R.GetValue<Int64>('revision'),Checked);
  FTaskStep:=Checked;TaskNavigate(nil);
 except on E:Exception do StatusLabel.Text:='Progress was not saved: '+E.Message;end;
 Lesson.Free;
end;
procedure TDPHMainForm.TaskNavigate(Sender:TObject);
var R,Lesson,Fields,Step,Learning:TJSONObject;Steps:TJSONArray;Checked:Integer;
begin
 TaskCheckStep.Enabled:=False;TaskResetProgress.Enabled:=False;TaskProgressLabel.Text:='Enter your name to save your place on this computer.';
 TaskPrevious.Enabled:=False;TaskNext.Enabled:=False;TaskRestart.Enabled:=False;TaskEdit.Enabled:=False;TaskNotes.Enabled:=False;
  TaskReaderTitle.Text:='Choose a task to learn';TaskContextMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.83a61c524bf7cbdb', 'Select saved instructions on the left. If none are supplied, read the Handoff dossier or ask the author to prepare one common task.');
 TaskStepLabel.Text:='Step instructions';TaskActionMemo.Text:='';TaskResultMemo.Text:='';
 if (FTaskRows=nil) or (TaskList.ItemIndex<0) or (TaskList.ItemIndex>=FTaskRows.Count) then Exit;
 R:=FTaskRows[TaskList.ItemIndex];TaskReaderTitle.Text:=R.GetValue<string>('title');TaskEdit.Enabled:=True;TaskNotes.Enabled:=True;
 TaskContextMemo.Text:='Instructions by '+R.GetValue<string>('owner')+'.';
 if R.GetValue<string>('state')='verified' then TaskContextMemo.Lines.Add(DATTranslateText('DPH.UI.Main.Memo.9de42bdd9e7f9c3e', 'These instructions have been reviewed.'))
 else TaskContextMemo.Lines.Add(DATTranslateText('DPH.UI.Main.Memo.41677e27d9c1df58', 'These instructions still need review by someone who knows the application.'));
 if not TDPHWorkspaceView.IsLearningLesson(R) then begin TaskActionMemo.Text:=R.GetValue<string>('body');TaskStepLabel.Text:='Read the supplied instructions';Exit;end;
 Lesson:=TJSONObject.ParseJSONValue(R.GetValue<string>('structured_json')) as TJSONObject;
 try
  TDPHWorkspaceView.ValidateLearningLesson(Lesson);Fields:=Lesson.GetValue<TJSONObject>('fields');Steps:=Lesson.GetValue<TJSONArray>('steps');
  Checked:=0;if (FCatalog<>nil) and (FDatabase<>'') then Checked:=FCatalog.LearningProgress(FDatabase,TaskLearner.Text,Lesson.GetValue<string>('lesson_id'),R.GetValue<Int64>('revision'));
  if Sender=TaskNext then Inc(FTaskStep) else if Sender=TaskPrevious then Dec(FTaskStep) else if Sender=TaskRestart then FTaskStep:=0;
  FTaskStep:=EnsureRange(FTaskStep,0,Steps.Count-1);Step:=Steps.Items[FTaskStep] as TJSONObject;
  TaskContextMemo.Lines.Add('Purpose: '+Fields.GetValue<string>('purpose'));TaskContextMemo.Lines.Add('Before you begin: '+Fields.GetValue<string>('prerequisites'));
  if Lesson.TryGetValue<TJSONObject>('learning',Learning) then begin
   if Learning.GetValue<string>('role')<>'' then TaskContextMemo.Lines.Add('For: '+Learning.GetValue<string>('role'));
   if Learning.GetValue<string>('path')<>'' then TaskContextMemo.Lines.Add('Learning path: '+Learning.GetValue<string>('path')+'; lesson '+Learning.GetValue('order').Value);
  end;
  if TaskLearner.Text.Trim<>'' then begin
   TaskProgressLabel.Text:=Format('%s: %d of %d steps checked. This records your checks, not proof of mastery.',[TaskLearner.Text.Trim,Checked,Steps.Count]);
   TaskCheckStep.Enabled:=(Checked<Steps.Count) and (FTaskStep=Checked);TaskResetProgress.Enabled:=Checked>0;
  end;
  TaskStepLabel.Text:=Format('Step %d of %d',[FTaskStep+1,Steps.Count]);TaskActionMemo.Text:=Step.GetValue<string>('action');
  TaskResultMemo.Text:='Expected after this step: '+Step.GetValue<string>('expected_result');
  if FTaskStep=Steps.Count-1 then TaskResultMemo.Lines.Add('Expected final result: '+Fields.GetValue<string>('expected_result')+sLineBreak+'If something goes wrong: '+Fields.GetValue<string>('troubleshooting')+sLineBreak+'Practice: '+Fields.GetValue<string>('practice'));
  TaskPrevious.Enabled:=FTaskStep>0;TaskNext.Enabled:=FTaskStep<Steps.Count-1;TaskRestart.Enabled:=True;
 finally Lesson.Free;end;
end;
procedure TDPHMainForm.TaskOpenNotes(Sender:TObject);
var ID:string;I:Integer;
begin
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or cancel the current instructions first';Exit;end;
 if (TaskList.ItemIndex<0) or (TaskList.ItemIndex>=FTaskRows.Count) then Exit;
 ID:=FTaskRows[TaskList.ItemIndex].GetValue<string>('id');PendingKnowledgeCheck.IsChecked:=False;KnowledgeFilterChange(nil);
 for I:=0 to FKnowledgeRows.Count-1 do if FKnowledgeRows[I].GetValue<string>('id')=ID then begin KnowledgeList.ItemIndex:=I;KnowledgeClick(nil);WorkspaceTabs.ActiveTab:=KnowledgeTab;Exit;end;
end;
procedure TDPHMainForm.TaskEditClick(Sender:TObject);
var Key:string;Steps:TJSONArray;I:Integer;
begin
 if FBusy or (FView=nil) then Exit;
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or cancel the current draft first';Exit;end;
 if (Sender=TaskNew) or (Sender=SetupTaskButton) then begin NewKnowledgeClick(nil);FTaskDraft:=TDPHWorkspaceView.NewLearningLesson;end
 else begin
  if (TaskList.ItemIndex<0) or (TaskList.ItemIndex>=FTaskRows.Count) then Exit;
  if not TDPHWorkspaceView.IsLearningLesson(FTaskRows[TaskList.ItemIndex]) then begin TaskOpenNotes(nil);Exit;end;
  TaskOpenNotes(nil);FTaskDraft:=TJSONObject.ParseJSONValue(FKnowledgeStructuredJSON) as TJSONObject;
 end;
 FBinding:=True;
 try
  for Key in DPHLessonKeys do (FindComponent('Tutor_'+Key) as TMemo).Text:=FTaskDraft.GetValue<string>('fields.'+Key);
  TutorAuthor.Text:=KnowledgeAuthorEdit.Text;TutorSteps.Items.Clear;Steps:=FTaskDraft.GetValue<TJSONArray>('steps');
  TutorRole.Text:=FTaskDraft.GetValue<string>('learning.role','');TutorPath.Text:=FTaskDraft.GetValue<string>('learning.path','');TutorOrder.Text:=IntToStr(FTaskDraft.GetValue<Integer>('learning.order',1));
  Tutor_name.ReadOnly:=FKnowledgeID<>0;
  for I:=0 to Steps.Count-1 do TutorSteps.Items.Add(IntToStr(I+1)+'. '+Steps.Items[I].GetValue<string>('action'));
  FTutorStep:= -1;TutorSteps.ItemIndex:= -1;TutorAction.Text:='';TutorExpected.Text:='Unknown';FTutorStepDirty:=False;
 finally FBinding:=False;end;
 FKnowledgeEdited:=True;FStructuredEditorPending:=True;WorkspaceTabs.ActiveTab:=TaskEditorTab;
end;
procedure TDPHMainForm.TaskEditorChanged(Sender:TObject);
begin if not FBinding and (FTaskDraft<>nil) then begin FKnowledgeEdited:=True;FStructuredEditorPending:=True;end;end;
procedure TDPHMainForm.TutorStepChanged(Sender:TObject);
begin if not FBinding and (FTaskDraft<>nil) then begin FTutorStepDirty:=True;FKnowledgeEdited:=True;FStructuredEditorPending:=True;end;end;
procedure TDPHMainForm.TutorStepSelection(Sender:TObject);
var Steps:TJSONArray;Step:TJSONObject;
begin
 if FBinding or (FTaskDraft=nil) then Exit;
 if FTutorStepDirty then begin FBinding:=True;try TutorSteps.ItemIndex:=FTutorStep;finally FBinding:=False;end;StatusLabel.Text:='Keep this step or undo its edit before selecting another';Exit;end;
 Steps:=FTaskDraft.GetValue<TJSONArray>('steps');FTutorStep:=TutorSteps.ItemIndex;FBinding:=True;
 try
  TutorAction.Text:='';TutorExpected.Text:='Unknown';
  if (FTutorStep>=0) and (FTutorStep<Steps.Count) then begin Step:=Steps.Items[FTutorStep] as TJSONObject;TutorAction.Text:=Step.GetValue<string>('action');TutorExpected.Text:=Step.GetValue<string>('expected_result');end;
 finally FBinding:=False;end;
end;
procedure TDPHMainForm.TutorStepAction(Sender:TObject);
var Steps:TJSONArray;Step:TJSONObject;Elements:TList<TJSONValue>;V:TJSONValue;I,Target:Integer;
begin
 if FBusy or (FTaskDraft=nil) then Exit;Steps:=FTaskDraft.GetValue<TJSONArray>('steps');
 try
  if Sender=TutorDiscardStep then begin FTutorStepDirty:=False;TutorStepSelection(nil);Exit;end;
  if (Sender<>TutorKeepStep) and FTutorStepDirty then raise EArgumentException.Create('Keep this step or undo its edit first');
  if Sender=TutorNewStep then begin
   if Steps.Count>=100 then raise EArgumentException.Create('A task may contain at most 100 steps');
   FBinding:=True;try FTutorStep:= -1;TutorSteps.ItemIndex:= -1;TutorAction.Text:='';TutorExpected.Text:='Unknown';finally FBinding:=False;end;
   FTutorStepDirty:=True;Exit;
  end;
  Elements:=TList<TJSONValue>.Create;
  try
   for V in Steps do Elements.Add(V);
   if Sender=TutorKeepStep then begin
    if TutorAction.Text.Trim='' then raise EArgumentException.Create('Enter the action for this step');
    if SameText(TutorAction.Text.Trim,'Unknown') then raise EArgumentException.Create('Explain what the learner does');
    if (TutorExpected.Text.Trim='') or (Length(TutorAction.Text)>4096) or (Length(TutorExpected.Text)>4096) then raise EArgumentException.Create('Enter the expected result or Unknown; each field is limited to 4096 characters');
    Step:=TJSONObject.Create.AddPair('action',TutorAction.Text.Trim).AddPair('expected_result',TutorExpected.Text.Trim);
    if FTutorStep<0 then begin
     if Steps.Count>=100 then begin Step.Free;raise EArgumentException.Create('A task may contain at most 100 steps');end;
     Elements.Add(Step);FTutorStep:=Elements.Count-1;
    end else begin V:=Elements[FTutorStep];Elements[FTutorStep]:=Step;V.Free;end;
    Steps.SetElements(Elements);Elements:=nil;FTutorStepDirty:=False;
   end else if (FTutorStep>=0) and (FTutorStep<Steps.Count) then begin
    if Sender=TutorRemoveStep then begin V:=Elements[FTutorStep];Elements.Delete(FTutorStep);Steps.SetElements(Elements);Elements:=nil;V.Free;FTutorStep:=Min(FTutorStep,Steps.Count-1);end
    else begin Target:=FTutorStep;if Sender=TutorStepUp then Dec(Target) else if Sender=TutorStepDown then Inc(Target);
     if (Target>=0) and (Target<Elements.Count) then begin Elements.Exchange(FTutorStep,Target);Steps.SetElements(Elements);Elements:=nil;FTutorStep:=Target;end;
    end;
   end;
  finally Elements.Free;end;
  FBinding:=True;
  try TutorSteps.Items.Clear;for I:=0 to Steps.Count-1 do TutorSteps.Items.Add(IntToStr(I+1)+'. '+Steps.Items[I].GetValue<string>('action'));TutorSteps.ItemIndex:=FTutorStep;finally FBinding:=False;end;
  FKnowledgeEdited:=True;TutorStepSelection(nil);
 except on E:Exception do StatusLabel.Text:=E.Message;end;
end;
procedure TDPHMainForm.TaskCancelClick(Sender:TObject);
begin
 if FBusy or (FTaskDraft=nil) then Exit;DiscardKnowledgeClick(nil);WorkspaceTabs.ActiveTab:=TaskTab;
end;
procedure TDPHMainForm.TaskSaveClick(Sender:TObject);
var Fields:TJSONObject;Key:string;LessonOrder:Integer;
begin
 if FBusy or (FView=nil) or (FTaskDraft=nil) then Exit;
 try
  if FTutorStepDirty then raise EArgumentException.Create('Keep the current step or undo its edit before saving');
  Fields:=FTaskDraft.GetValue<TJSONObject>('fields');
  for Key in DPHLessonKeys do begin Fields.RemovePair(Key).Free;Fields.AddPair(Key,(FindComponent('Tutor_'+Key) as TMemo).Text.Trim);end;
  if not TryStrToInt(TutorOrder.Text,LessonOrder) then raise EArgumentException.Create('Enter a whole number for lesson order');
  FTaskDraft.RemovePair('learning').Free;FTaskDraft.AddPair('learning',TJSONObject.Create.AddPair('role',TutorRole.Text.Trim).AddPair('path',TutorPath.Text.Trim).AddPair('order',TJSONNumber.Create(LessonOrder)));
  TDPHWorkspaceView.ValidateLearningLesson(FTaskDraft);
  if (TutorAuthor.Text.Trim='') or SameText(TutorAuthor.Text.Trim,'Unknown') then raise EArgumentException.Create('Enter the person supplying these instructions');
  FBinding:=True;
  try
   KnowledgeTitleEdit.Text:=Fields.GetValue<string>('name').Trim;KnowledgeAuthorEdit.Text:=TutorAuthor.Text.Trim;
   KnowledgeBodyMemo.ReadOnly:=True;KnowledgeTitleEdit.ReadOnly:=True;KnowledgeKindCombo.Enabled:=False;KnowledgeDocumentCombo.Enabled:=False;KnowledgeAudienceCombo.Enabled:=False;
   KnowledgeBodyMemo.Text:=TDPHWorkspaceView.LearningLessonBody(FTaskDraft);FKnowledgeStructuredJSON:=FTaskDraft.ToJSON;FKnowledgeLink:='';FKnowledgeQuestionJSON:='';
   KnowledgeKindCombo.ItemIndex:=KnowledgeKindCombo.Items.IndexOf('user_help');KnowledgeDocumentCombo.ItemIndex:=KnowledgeDocumentCombo.Items.IndexOf('user');KnowledgeAudienceCombo.ItemIndex:=KnowledgeAudienceCombo.Items.IndexOf('all');
  finally FBinding:=False;end;
  FStructuredEditorPending:=False;FTaskSavingID:=FTaskDraft.GetValue<string>('lesson_id');Submit('save_knowledge');
  if FBusy then begin TaskEditorScroll.Enabled:=False;TaskEditorToolbar.Enabled:=False;end else FTaskSavingID:='';
 except on E:Exception do StatusLabel.Text:=E.Message;end;
end;
procedure TDPHMainForm.SetupClick(Sender: TObject);
begin WorkspaceTabs.ActiveTab:=SetupTab; end;
procedure TDPHMainForm.LearnerTabClick(Sender: TObject);
var Index: Integer;
begin
  Index:=(Sender as TRectangle).Tag;
  if (Index>=0) and (Index<LessonPageCombo.Items.Count) then begin
    LessonPageCombo.ItemIndex:=Index;
    WorkspacePageChange(LessonPageCombo);
  end else if Index=11 then WorkspaceTabs.ActiveTab:=SetupTab;
end;
procedure TDPHMainForm.WorkspacePageChange(Sender: TObject);
var Index: Integer; Choice: TComboBox; TabShape: TRectangle;
begin
  if FBinding then Exit;
  if WorkspaceTabs.ActiveTab<>GraphTab then begin
    FExpectedGraphPage:='';
    FlowBrowser.Visible:=False;
  end;
  if WorkspaceTabs.ActiveTab<>ScreenshotTab then begin
    FScreenshotOriginTab:=nil;
    ScreenshotReturnButton.Enabled:=False;
  end;
  if (Sender=WorkspacePageCombo) or (Sender=LessonPageCombo) then begin
    Choice:=Sender as TComboBox;
    if Choice.ItemIndex<0 then Exit;
    for Index:=0 to WorkspaceTabs.TabCount-1 do
      if WorkspaceTabs.Tabs[Index].Text=Choice.Items[Choice.ItemIndex] then begin
        WorkspaceTabs.ActiveTab:=WorkspaceTabs.Tabs[Index]; Break;
      end;
    if (Sender=LessonPageCombo) and (WorkspaceTabs.ActiveTab=ExplainTab) and (FView<>nil) then begin
      FSelected:=''; FShowingBookmarks:=False; FScope:=''; FPage:=0;
      FBinding:=True;
      try SearchEdit.Text:=''; KindCombo.ItemIndex:=0; finally FBinding:=False; end;
      RefreshExplorer; ShowExplanation;
    end;
  end;
  if WorkspaceTabs.ActiveTab<>nil then begin
    FBinding:=True;
    try
      WorkspacePageCombo.ItemIndex:=WorkspacePageCombo.Items.IndexOf(WorkspaceTabs.ActiveTab.Text);
      LessonPageCombo.ItemIndex:=LessonPageCombo.Items.IndexOf(WorkspaceTabs.ActiveTab.Text);
    finally FBinding:=False; end;
    for Index:=0 to 11 do begin
      TabShape:=FindComponent('LearnerTab'+IntToStr(Index)) as TRectangle;
      if TabShape<>nil then begin
        if ((Index=11) and (WorkspaceTabs.ActiveTab=SetupTab)) or
           ((Index<11) and (LessonPageCombo.ItemIndex=Index)) then
        begin
          TabShape.Fill.Color:=$FFFFFFFF;
          TabShape.Stroke.Color:=$FFF28C28;
          TabShape.Stroke.Thickness:=2;
        end else begin
          TabShape.Fill.Color:=$FFE8F2FB;
          TabShape.Stroke.Color:=$FFB5CFE5;
          TabShape.Stroke.Thickness:=1;
        end;
      end;
    end;
    ExplorerLayout.Visible:=(WorkspaceTabs.ActiveTab=ExplainTab) or (WorkspaceTabs.ActiveTab=SourceTab) or
      (WorkspaceTabs.ActiveTab=GraphTab) or (WorkspaceTabs.ActiveTab=ScreenTab) or
      (WorkspaceTabs.ActiveTab=RelationsTab) or (WorkspaceTabs.ActiveTab=DetailsTab);
    ExplorerSplitter.Visible:=ExplorerLayout.Visible;
    if ExplorerLayout.Visible and (FView<>nil) and (FExplorerKeys.Count=0) then RefreshExplorer;
    InspectorLayout.Visible:=(WorkspaceTabs.ActiveTab=SourceTab) or
      (WorkspaceTabs.ActiveTab=RelationsTab) or (WorkspaceTabs.ActiveTab=DetailsTab);
    InspectorSplitter.Visible:=InspectorLayout.Visible;
  end;
  if (WorkspaceTabs.ActiveTab=ScreenshotTab) and (FPendingScreenshots<>nil) then begin
    var PendingScreenshots:=FPendingScreenshots;
    FPendingScreenshots:=nil;
    LoadScreenshots(PendingScreenshots);
  end;
  if FView<>nil then FPendingWorkspaceTab:=WorkspaceTabs.ActiveTab;
  if (FLearningDirectory = '') or (DATLanguageManager.Generation = 0) then Exit;
  if (WorkspaceTabs.ActiveTab = HelpTab) and
    (FHelpLanguageGeneration <> DATLanguageManager.Generation) then begin
    HelpClick(nil);
    FHelpLanguageGeneration := DATLanguageManager.Generation;
  end else if (WorkspaceTabs.ActiveTab = OverviewTab) and
    (FView = nil) then begin
    LearningClick(nil);
  end else if (WorkspaceTabs.ActiveTab = OverviewTab) and
    (FLearningFacts <> nil) and
    (FOverviewLanguageGeneration <> DATLanguageManager.Generation) then begin
    LearningClick(nil);
    FOverviewLanguageGeneration := DATLanguageManager.Generation;
  end else if (WorkspaceTabs.ActiveTab = CardLibraryTab) and
    (FCardRows <> nil) and
    (FLibraryLanguageGeneration <> DATLanguageManager.Generation) then begin
    CardSelectionChange(nil);
    FLibraryLanguageGeneration := DATLanguageManager.Generation;
  end else if (WorkspaceTabs.ActiveTab = ExplainTab) and
    (FView <> nil) and
    (FMapLanguageGeneration <> DATLanguageManager.Generation) then begin
    ShowExplanation;
    FMapLanguageGeneration := DATLanguageManager.Generation;
  end else if (WorkspaceTabs.ActiveTab = GraphTab) and
    (FView <> nil) and
    (FGraphLanguageGeneration <> DATLanguageManager.Generation) then begin
    RefreshGraphics;
    FGraphLanguageGeneration := DATLanguageManager.Generation;
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
    StatusLabel.Text:='The source location and matching text are shown in the search details.'; Exit;
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
  ProjectSearchProgress.Visible:=True;
  ProjectSearchMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.cd246329dfad9f68', 'Searching project files, discovered guides and logs, captured evidence, and saved explanations. Please wait...');
  FWorker.Submit(Request); FBusy:=True; FPendingCommand:='search';
  StatusLabel.Text:='Searching this application. Please wait...';
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
  R.AllowInternet:=AllowInternetCheck.IsChecked;
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
  FPendingCommand:=ACommand;
  FWorker.Submit(R); FBusy:=True;
  if not MatchText(ACommand,['full','incremental']) then StatusLabel.Text:='Processing the selected request...';
  if MatchText(ACommand,['full','incremental']) then begin
    ProjectPreparationMessage.Text:=DATTranslateDynamicText('Reading the selected application''s project files...');
    FPreparingProject:=True;FPreparationCompletionTicks:=0;
    ProjectPreparationProgress.Value:=5; ProjectPreparationPercent.Text:='5%';
    ProjectPreparationLayout.Visible:=True; ProjectPreparationLayout.BringToFront;
    FProgressForm.ProgressMessage.Text:=ProjectPreparationMessage.Text;
    FProgressForm.ProgressBar.Value:=5;
    FProgressForm.ProgressPercent.Text:='5%';
    FProgressForm.Show;
    Application.ProcessMessages;
  end;
    if ACommand='save_knowledge' then FSavedKnowledgeText:=KnowledgeTitleEdit.Text+#0+KnowledgeBodyMemo.Text+#0+IntToStr(KnowledgeDocumentCombo.ItemIndex)+#0+IntToStr(KnowledgeAudienceCombo.ItemIndex)+#0+FEditableLinks.ToJSON+#0+FKnowledgeQuestionJSON+#0+FKnowledgeStructuredJSON;
end;
procedure TDPHMainForm.OpenProjectClick(Sender: TObject);
var SelectedDatabase: string;
begin
  if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the authored text before changing projects'; Exit; end;
  if FBusy or not OpenProjectDialog.Execute then Exit;
  SelectedDatabase:=FDatabase;
  if (FDatabase='') or ((FView<>nil) and not SameFileName(ExcludeTrailingPathDelimiter(FView.Document.GetValue<string>('root')),ExcludeTrailingPathDelimiter(ExtractFilePath(OpenProjectDialog.FileName)))) then
    SelectedDatabase:=TPath.Combine(TPath.GetTempPath,'DPH-unsaved-'+TGUID.NewGuid.ToString+'.dphdb');
  OpenSelection(OpenProjectDialog.FileName,SelectedDatabase,
    not SameFileName(SelectedDatabase,FDatabase));
end;
procedure TDPHMainForm.OpenCacheClick(Sender: TObject);
begin
  if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the authored text before changing projects'; Exit; end;
  if FBusy or not OpenCacheDialog.Execute then Exit; OpenSelection('',OpenCacheDialog.FileName);
end;
procedure TDPHMainForm.DiscardUnsavedProject(const ADatabase: string);
var Database,Directory,Path,TempDirectory: string;
begin
  Database:=TPath.GetFullPath(ADatabase);
  TempDirectory:=IncludeTrailingPathDelimiter(TPath.GetFullPath(TPath.GetTempPath));
  if not Database.StartsWith(TempDirectory,True) or
    not ExtractFileName(Database).StartsWith('DPH-unsaved-',True) or
    not SameText(ExtractFileExt(Database),'.dphdb') then
    raise EArgumentException.Create('Refusing to discard a database outside DPH temporary projects');
  Directory:=Database+'.views';
  if TDirectory.Exists(Directory) then begin
    if (GetFileAttributes(PChar(Directory)) and FILE_ATTRIBUTE_REPARSE_POINT)<>0 then
      raise EReadError.Create('Linked temporary view folders cannot be discarded automatically');
    for Path in TDirectory.GetFiles(Directory) do TFile.Delete(Path);
    TDirectory.Delete(Directory,False);
  end;
  for Path in [Database+'-wal',Database+'-shm',Database+'-journal',Database] do
    if TFile.Exists(Path) then TFile.Delete(Path);
end;
function TDPHMainForm.ResolveUnsavedProject(AClosing,ADirectSave: Boolean): Boolean;
var Choice: Integer; Database,Destination,Prompt: string; Store: TDPHKnowledgeStore;
begin
  Result:=True;
  if FUnsavedDatabase='' then Exit;
  if ADirectSave then Choice:=mrYes
  else begin
    if AClosing then Prompt:='Save this unsaved project before closing?'
    else Prompt:='Save this unsaved project before opening another?';
    Choice:=TDialogServiceSync.MessageDialog(Prompt+sLineBreak+sLineBreak+
      'Yes saves a project database. No discards this temporary capture. Cancel keeps it open.',
      TMsgDlgType.mtConfirmation,[TMsgDlgBtn.mbYes,TMsgDlgBtn.mbNo,TMsgDlgBtn.mbCancel],
      TMsgDlgBtn.mbCancel,0);
  end;
  case Choice of
    mrYes: begin
      DatabaseDialog.FileName:=TPath.GetFileNameWithoutExtension(FEntry)+'.dphdb';
      if not DatabaseDialog.Execute then Exit(False);
      Destination:=DatabaseDialog.FileName;
      try
        Store:=TDPHKnowledgeStore.Create(FUnsavedDatabase,
          FView.Document.GetValue<string>('root'),TPath.Combine(FBaseDirectory,'migrations'));
        try TDPHProjectBackup.Save(Store,Destination); finally Store.Free; end;
      except on E: Exception do begin
        StatusLabel.Text:='Project was not saved: '+E.Message;
        Exit(False);
      end; end;
      Database:=FUnsavedDatabase;
      FDatabase:=TPath.GetFullPath(Destination);
      FUnsavedDatabase:='';
      FPendingDiscardDatabase:='';
      try DiscardUnsavedProject(Database);
      except on E: Exception do StatusLabel.Text:='Project saved, but its temporary files could not be removed: '+E.Message; end;
      if FCatalog<>nil then
        try FCatalog.Remember(Destination); FCatalog.Save; RefreshProjectsClick(nil);
        except on E: Exception do StatusLabel.Text:='Project saved, but the recent-project list could not be updated: '+E.Message; end;
    end;
    mrNo: begin
      if AClosing then begin
        try DiscardUnsavedProject(FUnsavedDatabase);
        except on E: Exception do begin StatusLabel.Text:='Temporary project could not be discarded: '+E.Message; Exit(False); end; end;
        FUnsavedDatabase:='';
        FDatabase:='';
      end else FPendingDiscardDatabase:=FUnsavedDatabase;
    end;
  else Exit(False);
  end;
end;
procedure TDPHMainForm.OpenSelection(const AEntry,ADatabase: string; AUnsaved: Boolean);
var Request: TDPHWorkspaceRequest;
begin
  if FBusy then Exit;
  if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the authored text before changing projects'; Exit; end;
  Request:=Default(TDPHWorkspaceRequest); Request.Entry:=AEntry; Request.Database:=ADatabase;
  Request.AllowInternet:=AllowInternetCheck.IsChecked;
  if not TryStrToInt(CodePageEdit.Text,Request.CodePage) or (Request.CodePage<0) or (Request.CodePage>65535) then begin StatusLabel.Text:='Enter code page 0 for Unicode or a Windows code page number from 1 to 65535'; Exit; end;
  if AEntry='' then Request.Command:='open' else Request.Command:='incremental';
  Request.Configuration:=ConfigurationCombo.Items[ConfigurationCombo.ItemIndex];
  Request.Platform:=PlatformCombo.Items[PlatformCombo.ItemIndex];
  if AEntry<>'' then begin Request.Configuration:=''; Request.Platform:=''; end;
  Request.Defines:=DefinesEdit.Text.Split([';'],TStringSplitOptions.ExcludeEmpty);
  Request.ExternalRoots:=ExternalRootsEdit.Text.Split([';'],TStringSplitOptions.ExcludeEmpty);
  if (FUnsavedDatabase<>'') and not SameFileName(FUnsavedDatabase,ADatabase) and
    not ResolveUnsavedProject(False) then Exit;
  FExpectedDossierPage:='';
  FWorker.Submit(Request); FPendingEntry:=AEntry; FPendingDatabase:=ADatabase;
  if AUnsaved or ((FUnsavedDatabase<>'') and SameFileName(FUnsavedDatabase,ADatabase)) then
    FPendingUnsavedDatabase:=ADatabase else FPendingUnsavedDatabase:='';
  FPendingCommand:=Request.Command; FBusy:=True;WorkspaceTabs.Enabled:=False;
  ProjectPreparationMessage.Text:=DATTranslateDynamicText('Checking the selected application and its Delphi files...');
  FPreparingProject:=True;FPreparationCompletionTicks:=0;
  ProjectPreparationProgress.Value:=5; ProjectPreparationPercent.Text:='5%';
  ProjectPreparationLayout.Visible:=True; ProjectPreparationLayout.BringToFront;
  FProgressForm.ProgressMessage.Text:=ProjectPreparationMessage.Text;
  FProgressForm.ProgressBar.Value:=5;
  FProgressForm.ProgressPercent.Text:='5%';
  FProgressForm.Show;
  Application.ProcessMessages;
end;
procedure TDPHMainForm.RelocateClick(Sender: TObject);
var Generation: Int64; Request: TDPHWorkspaceRequest;
begin
  if FBusy or (FView=nil) then Exit;
  if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the authored text before relocating'; Exit; end;
  if not OpenProjectDialog.Execute then Exit;
  Generation:=FView.Document.GetValue<Int64>('generation_id');
  Request:=Default(TDPHWorkspaceRequest); Request.CodePage:=FView.Document.GetValue<Integer>('code_page',0);
  Request.AllowInternet:=AllowInternetCheck.IsChecked;
  Request.Command:='relocate'; Request.Database:=FDatabase; Request.Entry:=OpenProjectDialog.FileName; Request.GenerationID:=Generation;
  Request.Configuration:=FView.Document.GetValue<string>('configuration'); Request.Platform:=FView.Document.GetValue<string>('platform');
  Request.Defines:=DefinesEdit.Text.Split([';'],TStringSplitOptions.ExcludeEmpty); Request.ExternalRoots:=ExternalRootsEdit.Text.Split([';'],TStringSplitOptions.ExcludeEmpty);
  FPendingEntry:=Request.Entry; FPendingDatabase:=Request.Database; FBusy:=True;
  FWorker.Submit(Request); StatusLabel.Text:='Verifying relocated project hashes before reassessment...';
end;
procedure TDPHMainForm.ClearWorkspace;
begin
  FCardRows.Clear;CardList.Items.Clear;CardSelectionChange(nil);FreeAndNil(FCardDraft);FCardSavingID:='';
  FTaskRows.Clear;TaskList.Items.Clear;FreeAndNil(FTaskDraft);TaskSelectionChange(nil);
  FCalculationEvidenceRows.Clear;FreeAndNil(FCalculationEvidence);CalculationEvidenceFilterChange(nil);
  FFileFormatRows.Clear;FreeAndNil(FFileFormats);FileFormatsFilterChange(nil);
  FDatabaseSchemaRows.Clear;FreeAndNil(FDatabaseSchema);DatabaseSchemaFilterChange(nil);FDatabaseERFocusID:='';FDatabaseEREvidenceID:='';DatabaseERFilterChange(nil);
  FDatabaseInventoryRows.Clear;FreeAndNil(FDatabaseInventory);DatabaseInventoryFilterChange(nil);
 HistorySelectionChange(nil);HistoryBeforeCombo.Items.Clear;HistoryAfterCombo.Items.Clear;
 FActionPurposeRows.Clear;FreeAndNil(FActionPurposes);ActionPurposeList.Items.Clear;ActionPurposeMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.40149f1d3eea74ed', 'Open a project to map user actions and business purposes.');ActionPurposeStatus.Text:='No capture loaded.';ActionPurposeNextButton.Enabled:=False;ActionPurposeSourceButton.Enabled:=False;ActionPurposeEditButton.Enabled:=False;ActionPurposeNewButton.Enabled:=False;ActionPurposeKnowledgeButton.Enabled:=False;ActionPurposeExplainButton.Enabled:=False;
 FInheritanceRows.Clear;FInheritanceOrigins.Clear;FreeAndNil(FInheritance);InheritanceList.Items.Clear;InheritanceOriginCombo.Items.Clear;InheritanceMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.0ac051f8fea1b4a0', 'Open a project to inspect inherited forms and frames.');InheritanceStatus.Text:='No capture loaded.';InheritanceNextButton.Enabled:=False;InheritanceSourceButton.Enabled:=False;
 FDependencyRows.Clear;FreeAndNil(FDependencies);DependencyList.Items.Clear;DependencyMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.c20d6d5f1d91513a', 'Open a project to inspect component dependencies.');DependencyStatus.Text:='No capture loaded.';
 DependencyNextButton.Enabled:=False;DependencySourceButton.Enabled:=False;DependencyEditButton.Enabled:=False;DependencyKnowledgeButton.Enabled:=False;DependencyClassButton.Enabled:=False;
 FLayoutRows.Clear;FreeAndNil(FLayout);LayoutList.Items.Clear;LayoutMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.26e013081e830571', 'Open a project to inspect layout declarations.');LayoutStatus.Text:='No capture loaded.';
 LayoutNextButton.Enabled:=False;LayoutSourceButton.Enabled:=False;
  FDynamicRows.Clear; FreeAndNil(FDynamic); DynamicList.Items.Clear; DynamicReferenceCombo.Items.Clear;
  DynamicMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.a158b168ff26530a', 'Open a project to inspect creation sites.'); DynamicStatus.Text:='No capture loaded.';
  DynamicNextButton.Enabled:=False; DynamicExplainButton.Enabled:=False; DynamicReferenceButton.Enabled:=False;
  FCommandRows.Clear; FreeAndNil(FCommands); CommandsList.Items.Clear; CommandsHandlerCombo.Items.Clear;
  CommandsMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.748063fad6a616a8', 'Open a captured project to inspect its commands.'); CommandsStatus.Text:='No capture loaded.';
  CommandsNextButton.Enabled:=False; CommandsSourceButton.Enabled:=False; CommandsActionButton.Enabled:=False; CommandsHandlerButton.Enabled:=False;
  FKeyboardRows.Clear; FreeAndNil(FKeyboard); KeyboardList.Items.Clear;
  KeyboardMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.3a1fefaf9ffa48f6', 'Open a project capture to inspect keyboard declarations.'); KeyboardNextButton.Enabled:=False;
  KeyboardStatus.Text:='No capture loaded.';
  FGlossaryRows.Clear; GlossaryList.Items.Clear; GlossaryMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.a9c771feebc98e7b', 'Open a selected project, then add its business terms.');
  FreeAndNil(FProjectMembers); ProjectMembersList.Items.Clear; ProjectMemberMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.fd94bd023c10d5b5', 'Open a captured project to inspect its project and output declarations.');
  FreeAndNil(FComparison); ComparisonList.Items.Clear; ComparisonBeforeMemo.Text:=''; ComparisonAfterMemo.Text:='';
  ComparisonStatus.Text:='No comparison loaded.'; ComparisonNextButton.Enabled:=False;
  FQualityRows.Clear; QualityList.Items.Clear; QualityMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.4e1b071080be460b', 'Open a captured project to inspect source quality candidates.');
  FreeAndNil(FExplanations); FreeAndNil(FLearningFacts); LearningBrowser.Visible:=False; ExplainBrowser.Visible:=False; FlowBrowser.Visible:=False;
  FreeAndNil(FPendingScreenshots); FreeAndNil(FImages); ScreenshotList.Items.Clear; ScreenshotImage.Bitmap.Clear(TAlphaColors.Null); ScreenshotEvidence.Text:='Open an application to generate its blank screen views.';
  FScreenshotOriginTab:=nil; ScreenshotReturnButton.Enabled:=False;
  FCardRows.Clear;CardList.Items.Clear;CardSelectionChange(nil);FreeAndNil(FCardDraft);FCardSavingID:='';
  FTaskRows.Clear;TaskList.Items.Clear;FreeAndNil(FTaskDraft);TaskSelectionChange(nil);
  FreeAndNil(FView); FreeAndNil(FGraph); FreeAndNil(FScreen); FreeAndNil(FKnowledge);
  FreeAndNil(FCoverage); CoverageList.Items.Clear; CoverageMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.30c4381dcdbbb81e', 'Open a captured project to see coverage and gaps.');
  FreeAndNil(FContinuity); ContinuityList.Items.Clear; ContinuityMemo.Text:='';
  FreeAndNil(FReviewTasks); ReviewTasksList.Items.Clear; ReviewBeforeMemo.Text:=''; ReviewAfterMemo.Text:='';
  FreeAndNil(FQuestions); QuestionsList.Items.Clear; QuestionMemo.Text:=''; FKnowledgeQuestionJSON:='';
  FreeAndNil(FObservations); ObservationsList.Items.Clear; ObservationMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.aa3847122e64f4b4', 'Open Runtime observations and click Refresh saved records.');
  FreeAndNil(FTaskDraft);FTutorStepDirty:=False;
  FreeAndNil(FWorkflowDraft);FWorkflowStepDirty:=False;
  FreeAndNil(FTranslations); TranslationList.Items.Clear; TranslationMemo.Text:=''; FTerminologyJSON:='';
  TranslationStatus.Text:='Select a saved Knowledge revision, then refresh or translate it here.';
  FreeAndNil(FLinkTargets); LinkTargetsList.Items.Clear;
  FreeAndNil(FSearchResults); ProjectSearchList.Items.Clear; ProjectSearchMemo.Text:='';
  FSelected:=''; FScope:=''; FPage:=0; FHistory.Clear; FBookmarks.Clear; FShowingBookmarks:=False;
  FExpandedKeys.Clear; FHierarchyVisible:=False;
  FreeAndNil(FDetails); DetailsList.Items.Clear; DetailsMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.5e010ae55e6432c9', 'Select an object in Explorer to inspect its statements, serialized properties and evidence.');
  FExplorerKeys.Clear; FRelationKeys.Clear; FKnowledgeRows.Clear;
  ExplorerList.Items.Clear; RelationsList.Items.Clear; KnowledgeList.Items.Clear; FormCombo.Items.Clear;
  SourceMemo.Text:=''; InspectorMemo.Text:=''; OverviewMemo.Text:=''; BreadcrumbLabel.Text:='';
  DataRetentionFilterChange(nil);TargetRecoveryFilterChange(nil);BusinessProcessFilterChange(nil);CalculationFilterChange(nil);BusinessRuleFilterChange(nil);DepartmentalWorkflowFilterChange(nil);DataQualityFilterChange(nil);NewKnowledgeClick(nil); FExportDirectory:=''; PreviewButton.Enabled:=False;
  PublishBrowser.Visible:=False; PublishMemo.Text:=''; GraphPaint.Repaint; ScreenPaint.Repaint;
end;
procedure TDPHMainForm.PollTimerTimer(Sender: TObject);
var R: TDPHWorkspaceResponse; Value: TJSONValue; Row: TJSONObject; TranslatedMessage: string;
begin
  if FClosing and FWorker.Finished then begin FBusy:=False; FClosing:=False; Close; Exit; end;
  if FPendingLanguageRefresh then begin
    FPendingLanguageRefresh:=False;
    LanguageCombo.RefreshLanguages;
    WorkspacePageChange(WorkspaceTabs);
    if (FView<>nil) and not FBusy then begin
      if WorkspaceTabs.ActiveTab=TaskTab then TaskNavigate(nil)
      else if WorkspaceTabs.ActiveTab=KeyboardTab then KeyboardFilterChange(nil)
      else if WorkspaceTabs.ActiveTab=ActionPurposeTab then ActionPurposeFilterChange(nil)
      else if WorkspaceTabs.ActiveTab=InheritanceTab then InheritanceFilterChange(nil)
      else if WorkspaceTabs.ActiveTab=DependencyTab then DependencyFilterChange(nil)
      else if WorkspaceTabs.ActiveTab=LayoutTab then LayoutFilterChange(nil)
      else if WorkspaceTabs.ActiveTab=DynamicTab then DynamicFilterChange(nil)
      else if WorkspaceTabs.ActiveTab=CommandsTab then CommandsFilterChange(nil)
      else if WorkspaceTabs.ActiveTab=FileFormatsTab then FileFormatsFilterChange(nil)
      else if WorkspaceTabs.ActiveTab=DatabaseSchemaTab then DatabaseSchemaFilterChange(nil)
      else if WorkspaceTabs.ActiveTab=DatabaseInventoryTab then DatabaseInventoryFilterChange(nil);
    end;
    if (FView<>nil) and ExplorerLayout.Visible then begin
      RefreshExplorer;
      ExplorerList.ItemIndex:=FExplorerKeys.IndexOf(FSelected);
    end;
  end;
  if FPreparationCompletionTicks>0 then begin
    Dec(FPreparationCompletionTicks);
    if FPreparationCompletionTicks=0 then ProjectPreparationLayout.Visible:=False;
  end;
  if FWorker.Poll(R) then
  try
    TranslatedMessage:=DATTranslateDynamicText(R.MessageText);
    if R.Busy and ContainsText(R.MessageText,'Saving project findings') and
      not SameText(DATActiveLanguageCode,'en-US') then
      TranslatedMessage:=DATTranslateDynamicText('Preparing the learning library and screen previews...')
    else if R.Busy and (R.MessageText<>'') and
      (TranslatedMessage=R.MessageText) and not SameText(DATActiveLanguageCode,'en-US') then begin
      TranslatedMessage:=DATTranslateText(
        'DPH.UI.Main.Runtime.ProjectPreparationMessage_Text.Text.694ee195977a631e',
        'Checking the selected application and its Delphi files...');
    end;
    FBusy:=R.Busy;if not R.Busy then WorkspaceTabs.Enabled:=True;
    if R.Busy and FPreparingProject then begin
      if R.ProgressPercent>=0 then
        ProjectPreparationProgress.Value:=Max(ProjectPreparationProgress.Value,R.ProgressPercent)
      else if ContainsText(R.MessageText,'Reading Delphi project files') then ProjectPreparationProgress.Value:=Max(ProjectPreparationProgress.Value,25)
      else if ContainsText(R.MessageText,'Tracing forms') then ProjectPreparationProgress.Value:=Max(ProjectPreparationProgress.Value,45)
      else if ContainsText(R.MessageText,'Saving project findings') then ProjectPreparationProgress.Value:=Max(ProjectPreparationProgress.Value,60)
      else if ContainsText(R.MessageText,'Searching project-local') or
        ContainsText(R.MessageText,'Refreshing project-local') then ProjectPreparationProgress.Value:=Max(ProjectPreparationProgress.Value,75)
      else ProjectPreparationProgress.Value:=Max(ProjectPreparationProgress.Value,10);
      if R.MessageText<>'' then ProjectPreparationMessage.Text:=TranslatedMessage;
      ProjectPreparationPercent.Text:=Format('%d%%',[Round(ProjectPreparationProgress.Value)]);
    end;
    if (FPendingCommand='search') and not R.Busy then ProjectSearchProgress.Visible:=False;
    if not R.Busy and not R.Failed then FDetached:=R.Detached;
    if R.Document<>nil then begin
      if FPendingDatabase<>'' then begin
        ClearWorkspace;
        if FPendingDiscardDatabase<>'' then begin
          try DiscardUnsavedProject(FPendingDiscardDatabase);
          except on E: Exception do StatusLabel.Text:='Previous temporary project could not be discarded: '+E.Message; end;
          FPendingDiscardDatabase:='';
        end;
        FUnsavedDatabase:=FPendingUnsavedDatabase;
        FPendingUnsavedDatabase:='';
        FEntry:=FPendingEntry; FDatabase:=FPendingDatabase;
        FPendingEntry:=''; FPendingDatabase:='';
      end;
      if FPreparingProject then begin
        if R.Busy then begin
          ProjectPreparationProgress.Value:=Max(ProjectPreparationProgress.Value,10);
          ProjectPreparationMessage.Text:=DATTranslateDynamicText('Loading saved project information and screen previews...');
        end else begin
          ProjectPreparationProgress.Value:=Max(ProjectPreparationProgress.Value,80);
          ProjectPreparationMessage.Text:=DATTranslateDynamicText('Preparing the learning library and screen previews...');
        end;
        ProjectPreparationPercent.Text:=Format('%d%%',[Round(ProjectPreparationProgress.Value)]);
      end;
      LoadView(R.Document,R.Screenshots,R.Knowledge<>nil); R.Document:=nil;
      FreeAndNil(R.Screenshots);
    end;
    if R.SourceEntry<>'' then FEntry:=R.SourceEntry;
    if R.ValidationReport<>'' then ValidationMemo.Text:=R.ValidationReport;
    if R.Failed and (FPendingCommand='screen_history') then begin HistorySelectionChange(nil);HistoryStatus.Text:='Comparison failed; read details below.';HistoryMemo.Text:=R.MessageText;end;
    if R.Failed and (FPendingCommand='validate_bundle') then ValidationMemo.Text:='FAILED: '+R.MessageText+sLineBreak+'The bundle has not passed validation. Correct the reported mismatch before using it.';
    if R.Failed then begin
      if FPendingUnsavedDatabase<>'' then begin
        try DiscardUnsavedProject(FPendingUnsavedDatabase);
        except on E: Exception do StatusLabel.Text:='Temporary project cleanup failed: '+E.Message; end;
      end;
      FPendingUnsavedDatabase:='';
      FPendingDiscardDatabase:='';
      FPendingEntry:=''; FPendingDatabase:='';
      if FView=nil then HelpClick(nil);
    end;
    if not R.Busy and (FTaskSavingID<>'') then begin
      TaskEditorScroll.Enabled:=True;TaskEditorToolbar.Enabled:=True;
      if R.Failed then FTaskSavingID:='';
    end;
    if not R.Busy and (FCardSavingID<>'') then begin
      CardEditorScroll.Enabled:=True;CardEditToolbar.Enabled:=True;
      if R.Failed then FCardSavingID:='';
    end;
    if R.Knowledge<>nil then begin
      if (FPendingCommand='save_knowledge') and (FSavedKnowledgeText=KnowledgeTitleEdit.Text+#0+KnowledgeBodyMemo.Text+#0+IntToStr(KnowledgeDocumentCombo.ItemIndex)+#0+IntToStr(KnowledgeAudienceCombo.ItemIndex)+#0+FEditableLinks.ToJSON+#0+FKnowledgeQuestionJSON+#0+FKnowledgeStructuredJSON) then FKnowledgeEdited:=False;
      LoadKnowledge(R.Knowledge,FPendingCommand='open'); R.Knowledge:=nil;
      if FCardSavingID<>'' then begin
        CardFilter.Text:='';CardRole.Text:='';CardFilterChange(nil);
        for var CardIndex:=0 to FCardRows.Count-1 do begin
          var SavedCard:=TJSONObject.ParseJSONValue(FCardRows[CardIndex].GetValue<string>('structured_json')) as TJSONObject;
          try if SavedCard.GetValue<string>('card_id')=FCardSavingID then begin CardList.ItemIndex:=CardIndex;CardSelectionChange(nil);Break;end;finally SavedCard.Free;end;
        end;
        FCardSavingID:='';WorkspaceTabs.ActiveTab:=CardLibraryTab;
      end;
      if FTaskSavingID<>'' then begin
        for var SavedTaskRow in FKnowledge do
          if TDPHWorkspaceView.IsLearningLesson(SavedTaskRow as TJSONObject) then begin
            var SavedTaskValue:=TJSONObject.ParseJSONValue(SavedTaskRow.GetValue<string>('structured_json')) as TJSONObject;
            try if SavedTaskValue.GetValue<string>('lesson_id')=FTaskSavingID then begin TaskFilter.Text:=SavedTaskRow.GetValue<string>('title');Break;end;finally SavedTaskValue.Free;end;
          end;
        TaskFilterChange(nil);
        for var TaskIndex:=0 to FTaskRows.Count-1 do
          if TDPHWorkspaceView.IsLearningLesson(FTaskRows[TaskIndex]) then begin
            var SavedLesson:=TJSONObject.ParseJSONValue(FTaskRows[TaskIndex].GetValue<string>('structured_json')) as TJSONObject;
            try if SavedLesson.GetValue<string>('lesson_id')=FTaskSavingID then begin TaskList.ItemIndex:=TaskIndex;TaskSelectionChange(nil);Break;end;finally SavedLesson.Free;end;
          end;
        FTaskSavingID:='';WorkspaceTabs.ActiveTab:=TaskTab;
      end;
    end;
    if (R.Comparison<>nil) and (FView<>nil) and (R.SearchGeneration=FView.Document.GetValue<Int64>('generation_id')) then begin LoadComparison(R.Comparison); R.Comparison:=nil; end;
    if (R.ReviewTasks<>nil) and (FView<>nil) and (R.SearchGeneration=FView.Document.GetValue<Int64>('generation_id')) then begin LoadReviewTasks(R.ReviewTasks); R.ReviewTasks:=nil; end;
    if not R.Busy and not R.Failed and (FPendingCommand='review_knowledge') and (FReviewTasks<>nil) then ReviewTasksClick(RefreshReviewTasksButton);
    if R.Screenshots<>nil then begin
      if WorkspaceTabs.ActiveTab=ScreenshotTab then LoadScreenshots(R.Screenshots)
      else begin FreeAndNil(FPendingScreenshots); FPendingScreenshots:=R.Screenshots; end;
      R.Screenshots:=nil;
    end;
    if (R.ScreenHistory<>nil) and (R.ScreenToken=FScreenToken) and SameText(R.ScreenDatabase,FDatabase) then begin LoadScreenHistory(R.ScreenHistory,R.BeforePNG,R.AfterPNG,R.DifferencePNG);R.ScreenHistory:=nil;end;
    if (R.Translations<>nil) and (FView<>nil) and (R.SearchGeneration=FView.Document.GetValue<Int64>('generation_id')) and (R.TranslationRevision=FKnowledgeRevision) then begin
      LoadTranslations(R.Translations); R.Translations:=nil;
    end;
    if (R.Observations<>nil) and (FView<>nil) and (R.SearchGeneration=FView.Document.GetValue<Int64>('generation_id')) then begin
      FObservations.Free; FObservations:=R.Observations; R.Observations:=nil; ObservationsList.Items.Clear;
      for Value in FObservations do ObservationsList.Items.Add(Value.GetValue<string>('context')+' | generation '+Value.GetValue<Int64>('generation_id').ToString);
      ObservationMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.404ee6ec0cce029d', 'Newest 50 records loaded. Select a record to read its attribution and saved text.');
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
      if FSearchResults.Count=0 then ProjectSearchMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.08b5c1d50406168c', 'No matching results on this page. Enter another search or click Search to start again from the first page.');
    end;
    if R.Continuity<>nil then begin
      FContinuity.Free; FContinuity:=R.Continuity; R.Continuity:=nil; ContinuityList.Items.Clear;
      for Value in FContinuity do begin Row:=Value as TJSONObject;
        ContinuityList.Items.Add(Row.GetValue<string>('title')+' | '+Row.GetValue<string>('old_name')+' -> '+Row.GetValue<string>('new_name'));
      end;
      ContinuityMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.1c3888d8baa9f573', 'Select a proposal to inspect old and new declarations. Up to 500 proposals are shown; narrow the replacement name/file filter when needed.');
    end;
    if R.Lifecycle<>nil then begin
      LifecycleMemo.Lines.Clear;
      LifecycleMemo.Lines.Add('Saved policy: keep '+IntToStr(R.RetentionCount)+' recent generations. Preview below uses '+RetentionCountEdit.Text+'.');
      LifecycleMemo.Lines.Add(DATTranslateText('DPH.UI.Main.Memo.1fa06333bdd4a2eb', 'Generation | state | saved | cached views | retention reason | release label'));
      for Value in R.Lifecycle do begin Row:=Value as TJSONObject;
        LifecycleMemo.Lines.Add(Row.GetValue<string>('generation_id')+' | '+Row.GetValue<string>('status')+' | '+
          Row.GetValue<string>('started_at')+' | '+Row.GetValue<string>('cached_views')+' | '+
          Row.GetValue<string>('retention_reason')+' | '+Row.GetValue<string>('release_label'));
      end;
    end;
    if R.RestoredDatabase<>'' then OpenSelection('',R.RestoredDatabase);
    if R.ExportDirectory<>'' then begin FExportDirectory:=R.ExportDirectory; PreviewButton.Enabled:=True;
      PublishMemo.Text:=DATFormatText('DPH.UI.Main.Runtime.PublishMemo_Text.Text.43df029f02f7e64f',
        'Handoff saved in %s'+sLineBreak+'Click Preview handoff, or open handoff-0.html in that folder. Share the whole folder so its evidence links and supplied images remain available. Review the edition before sharing it.',
        [FExportDirectory]); end;
    if not (R.Busy and ProjectPreparationLayout.Visible) then
      StatusLabel.Text:=TranslatedMessage;
    if (FView<>nil) and not R.Busy and not R.Failed then begin
      StatusLabel.Text:=DATFormatText('DPH.UI.Main.Runtime.StatusLabel_Text.Text.27b34e6d78564198',
        'Project information for %s is ready.',
        [#$2066+FView.Document.GetValue<string>('entry')+#$2069]);
      if not FView.Document.GetValue<Boolean>('analysis_complete') then
        StatusLabel.Text:=StatusLabel.Text+' '+DATFormatText(
          'DPH.UI.Main.Runtime.StatusLabel_Text.Text.994988eeb78b8d77',
          '%s Some code could not be explained; check unanswered questions.', ['']);
    end;
    if not R.Busy and FPreparingProject and ((FPendingCommand<>'open') or R.Failed) then begin
      FPreparingProject:=False;
      if R.Failed then ProjectPreparationMessage.Text:=DATTranslateDynamicText(
        'Project preparation stopped. Read the status message for details.')
      else begin
        ProjectPreparationProgress.Value:=100;
        ProjectPreparationPercent.Text:='100%';
        ProjectPreparationMessage.Text:=DATTranslateDynamicText('Project ready to explore.');
      end;
      FPreparationCompletionTicks:=5;
    end;
  finally R.Free; end;
  if FPreparingProject and (FPendingCommand='open') and (FView<>nil) and
    (WorkspaceTabs.ActiveTab=OverviewTab) and
    (FExpectedDossierPage='') and
    not LearningBrowser.Visible and not OverviewMemo.Visible then begin
    FPreparingProject:=True;
    ProjectPreparationLayout.Visible:=True; ProjectPreparationLayout.BringToFront;
    ProjectPreparationProgress.Value:=Max(ProjectPreparationProgress.Value,80);
    ProjectPreparationPercent.Text:=Format('%d%%',[Round(ProjectPreparationProgress.Value)]);
    RefreshLearning;
  end;
  if (FPendingWorkspaceTab<>nil) and (FPendingWorkspaceTab=WorkspaceTabs.ActiveTab) and (FView<>nil) then begin
    FPendingWorkspaceTab:=nil;
    if ((WorkspaceTabs.ActiveTab=ActionPurposeTab) or (WorkspaceTabs.ActiveTab=KeyboardTab) or
      (WorkspaceTabs.ActiveTab=CommandsTab) or (WorkspaceTabs.ActiveTab=DependencyTab) or
      (WorkspaceTabs.ActiveTab=LayoutTab)) and (FKeyboard=nil) then FKeyboard:=TDPHKeyboardInspector.Inspect(FView);
    if (WorkspaceTabs.ActiveTab=ActionPurposeTab) and (FActionPurposes=nil) then begin FActionPurposes:=TDPHActionPurposes.Inspect(FView,FKeyboard,FKnowledge);ActionPurposeFilterChange(nil);end;
    if WorkspaceTabs.ActiveTab=KeyboardTab then KeyboardFilterChange(nil);
    if (WorkspaceTabs.ActiveTab=CommandsTab) and (FCommands=nil) then begin FCommands:=TDPHCommandInventory.Inspect(FView,FKeyboard);CommandsFilterChange(nil);end;
    if (WorkspaceTabs.ActiveTab=DependencyTab) and (FDependencies=nil) then begin FDependencies:=TDPHComponentDependencies.Inspect(FView,FKeyboard);DependencyFilterChange(nil);end;
    if (WorkspaceTabs.ActiveTab=LayoutTab) and (FLayout=nil) then begin FLayout:=TDPHLayoutRules.Inspect(FKeyboard);LayoutFilterChange(nil);end;
    if (WorkspaceTabs.ActiveTab=InheritanceTab) and (FInheritance=nil) then begin FInheritance:=TDPHFormInheritance.Inspect(FView);InheritanceFilterChange(nil);end;
    if (WorkspaceTabs.ActiveTab=DynamicTab) and (FDynamic=nil) then begin FDynamic:=TDPHDynamicControls.Inspect(FView);DynamicFilterChange(nil);end;
    if ((WorkspaceTabs.ActiveTab=DatabaseSchemaTab) or (WorkspaceTabs.ActiveTab=DatabaseERTab)) and (FDatabaseSchema=nil) then begin FDatabaseSchema:=TDPHDatabaseSchema.Inspect(FView);DatabaseSchemaFilterChange(nil);end;
    if WorkspaceTabs.ActiveTab=DatabaseERTab then DatabaseERFilterChange(nil);
    if (WorkspaceTabs.ActiveTab=DatabaseInventoryTab) and (FDatabaseInventory=nil) then begin FDatabaseInventory:=TDPHDatabaseConnections.Inspect(FView);DatabaseInventoryFilterChange(nil);end;
    if (WorkspaceTabs.ActiveTab=CalculationEvidenceTab) and (FCalculationEvidence=nil) then begin FCalculationEvidence:=FView.Calculations;CalculationEvidenceFilterChange(nil);end;
    if (WorkspaceTabs.ActiveTab=FileFormatsTab) and (FFileFormats=nil) then begin FFileFormats:=FView.FileFormats;FileFormatsFilterChange(nil);end;
    if (WorkspaceTabs.ActiveTab=ProjectsTab) and (FProjectMembers=nil) then begin
      FProjectMembers:=FView.ProjectMembers;for Value in FProjectMembers do ProjectMembersList.Items.Add(Value.GetValue<string>('name'));end;
    if WorkspaceTabs.ActiveTab=QuestionsTab then RefreshQuestions;
    if WorkspaceTabs.ActiveTab=CoverageTab then RefreshCoverage;
    if WorkspaceTabs.ActiveTab=QualityTab then QualityClick(nil);
    if (WorkspaceTabs.ActiveTab=GraphTab) or (WorkspaceTabs.ActiveTab=ScreenTab) then RefreshGraphics;
  end;
  if FProgressForm.Visible then begin
    FProgressForm.ProgressMessage.Text:=ProjectPreparationMessage.Text;
    FProgressForm.ProgressBar.Value:=ProjectPreparationProgress.Value;
    FProgressForm.ProgressPercent.Text:=ProjectPreparationPercent.Text;
    if not ProjectPreparationLayout.Visible then FProgressForm.Hide;
  end;
  SaveProjectButton.Enabled:=(FUnsavedDatabase<>'') and not FBusy;
  RescanProjectButton.Enabled:=(FView<>nil) and (FEntry<>'') and not FDetached and not FBusy;
end;
procedure TDPHMainForm.ChangeTimerTimer(Sender: TObject);
begin if not FBusy and not FDetached and (FEntry<>'') then Submit('check'); end;
procedure TDPHMainForm.LoadView(ADocument: TJSONObject; AScreenshots: TJSONArray; ADeferLearning: Boolean);
var V: TJSONValue; Row: TJSONObject; Path,SavedKey,SavedForm: string; Options,Images: TJSONArray;
  SameProject: Boolean; Index: Integer; SavedTab: TTabItem;
begin
  FPendingWorkspaceTab:=nil;
  FExpectedDossierPage:='';
  if ADeferLearning and (FPendingCommand='open') then begin
    FPreparingProject:=True;
    FPreparationCompletionTicks:=0;
    ProjectPreparationLayout.Visible:=True; ProjectPreparationLayout.BringToFront;
  end;
  FLineageSeed:=''; FLineageDirection:='both';
  HistorySelectionChange(nil);
  SameProject:=(FView<>nil) and SameText(FView.Document.GetValue<string>('root'),ADocument.GetValue<string>('root')) and
    SameText(FView.Document.GetValue<string>('entry'),ADocument.GetValue<string>('entry'));
  SavedKey:=''; SavedForm:=''; SavedTab:=WorkspaceTabs.ActiveTab;
  FreeAndNil(FComparison); ComparisonList.Items.Clear; ComparisonBeforeMemo.Text:=''; ComparisonAfterMemo.Text:='';
  ComparisonNextButton.Enabled:=False; ComparisonStatus.Text:='Compare two retained captures; the displayed project supplies the After generation.';
  FreeAndNil(FReviewTasks); ReviewTasksList.Items.Clear; ReviewBeforeMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.577e1ef464106cc1', 'Refresh tasks for this captured generation.'); ReviewAfterMemo.Text:='';
  FreeAndNil(FLinkTargets); LinkTargetsList.Items.Clear;
  if SameProject then begin SavedKey:=FSelected; if FormCombo.ItemIndex>=0 then SavedForm:=FormCombo.Items[FormCombo.ItemIndex]; end;
  FreeAndNil(FSearchResults); ProjectSearchList.Items.Clear; ProjectSearchMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.d63c085f91a0da45', 'Search the current analysis generation and authored knowledge.');
  FreeAndNil(FObservations); ObservationsList.Items.Clear; ObservationMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.5239924b22587a2e', 'Click Refresh saved records to read attributed observations for this database.');
  FSearchOffset:=0; NextProjectSearchButton.Enabled:=False;
  FQualityRows.Clear; QualityList.Items.Clear;
  FreeAndNil(FView); FView:=TDPHWorkspaceView.Create(ADocument); FSelected:='';
  FDatabaseSchemaRows.Clear;FreeAndNil(FDatabaseSchema);DatabaseSchemaFilterChange(nil);FreeAndNil(FDatabaseER);
  FCalculationEvidenceRows.Clear;FreeAndNil(FCalculationEvidence);CalculationEvidenceFilterChange(nil);
  FFileFormatRows.Clear;FreeAndNil(FFileFormats);FileFormatsFilterChange(nil);
  FDatabaseInventoryRows.Clear;FreeAndNil(FDatabaseInventory);DatabaseInventoryFilterChange(nil);
  FKeyboardRows.Clear;FreeAndNil(FKeyboard);KeyboardFilterChange(nil);
  FCommandRows.Clear;FreeAndNil(FCommands);CommandsFilterChange(nil);
  FActionPurposeRows.Clear;FreeAndNil(FActionPurposes);ActionPurposeFilterChange(nil);
  FInheritanceRows.Clear;FInheritanceOrigins.Clear;FreeAndNil(FInheritance);InheritanceFilterChange(nil);
  FDependencyRows.Clear;FreeAndNil(FDependencies);DependencyFilterChange(nil);
  FLayoutRows.Clear;FreeAndNil(FLayout);LayoutFilterChange(nil);
  FDynamicRows.Clear;FreeAndNil(FDynamic);DynamicFilterChange(nil);
  FreeAndNil(FProjectMembers);ProjectMembersList.Items.Clear;ProjectMemberMemo.Text:='';
  InspectorMemo.Text:=''; SourceMemo.Text:='Select an object to inspect source from this generation.';
  if not SameProject then begin FScope:=''; FPage:=0; FHistory.Clear; FBookmarks.Clear; FExpandedKeys.Clear; FShowingBookmarks:=False; end
  else begin
    for Index:=FHistory.Count-1 downto 0 do if FView.Symbol(FHistory[Index])=nil then FHistory.Delete(Index);
    for Index:=FBookmarks.Count-1 downto 0 do if FView.Symbol(FBookmarks[Index])=nil then FBookmarks.Delete(Index);
    for Index:=FExpandedKeys.Count-1 downto 0 do if FView.Symbol(FExpandedKeys[Index])=nil then FExpandedKeys.Delete(Index);
    if (SavedKey<>'') and (FView.Symbol(SavedKey)=nil) then begin SavedKey:=''; FScope:=''; FPage:=0;
      StatusLabel.Text:='The previous selection is absent from the new generation. Explorer is reset; only surviving bookmarks and history were retained.';
    end;
  end;
  FreeAndNil(FDetails); DetailsList.Items.Clear; DetailsMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.7fa0622dccd4f994', 'Select an object to inspect evidence from this generation.');
  if (FCatalog<>nil) and (FDatabase<>'') and (FUnsavedDatabase='') then
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
    if ADeferLearning then begin
      LearningTopics.ItemIndex:=0;
      LearningBrowser.Visible:=False;
      OverviewMemo.Visible:=False;
    end;
  finally FBinding:=False; end;
  if ADeferLearning then begin FreeAndNil(FExplanations); FreeAndNil(FLearningFacts); end;
  if not ADeferLearning then RefreshExplorer;
  if not ADeferLearning then begin RefreshLearning; RefreshCoverage; RefreshQuestions; end;
  if AScreenshots<>nil then Images:=AScreenshots.Clone as TJSONArray
  else begin
    Images:=TJSONArray.Create;
    if FImages<>nil then for V in FImages do
      if V.GetValue<Int64>('artifact_id',0)>0 then Images.AddElement(V.Clone as TJSONValue);
  end;
  FreeAndNil(FPendingScreenshots);
  if (SavedTab=ScreenshotTab) and SameProject then LoadScreenshots(Images)
  else begin
    FPendingScreenshots:=Images;
    FreeAndNil(FImages);
    ScreenshotList.Items.Clear;
    ScreenshotImage.Bitmap.SetSize(0,0);
    ScreenshotEvidence.Text:='Open Screenshots to generate form previews from saved designs.';
  end;
  if SavedKey<>'' then SelectSymbol(SavedKey,False);
  if SameProject then WorkspaceTabs.ActiveTab:=SavedTab else WorkspaceTabs.ActiveTab:=OverviewTab;
  if ExplorerLayout.Visible and (FExplorerKeys.Count=0) then RefreshExplorer;
  if SavedKey<>'' then ExplorerList.ItemIndex:=FExplorerKeys.IndexOf(SavedKey);
end;
procedure TDPHMainForm.KeyboardFilterChange(Sender: TObject);
var Value: TJSONValue; Row: TJSONObject; Count,Order: Integer; Text,Query: string;
begin
  if Sender=KeyboardNextButton then Inc(FKeyboardOffset,250) else FKeyboardOffset:=0;
  KeyboardList.Items.Clear; FKeyboardRows.Clear; KeyboardNextButton.Enabled:=False;
  KeyboardActionButton.Enabled:=False; KeyboardSourceButton.Enabled:=False;
  KeyboardMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.d5eb2e873a6535f4', 'Select a component to see its keyboard declarations, source evidence and diagnostics.');
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
  else KeyboardMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.ed9041da72c5e144', 'No matching captured component. Clear the filter or inspect Coverage for missing form inputs.');
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
  if FDetached then begin KeyboardMemo.Lines.Add(DATTranslateText('DPH.UI.Main.Memo.3b5b409f9c089ca6', 'Source is detached. Captured locations and properties remain readable above. Attach the unchanged project to navigate.')); Exit; end;
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
 ActionPurposeMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.6170d236e36d06ed', 'Select a captured UI candidate or saved project task. Missing business purpose stays unknown.');if FActionPurposes=nil then Exit;
 Query:=ActionPurposeFilterEdit.Text.Trim;StateFilter:='';if ActionPurposeStateCombo.ItemIndex>0 then StateFilter:=ActionPurposeStateCombo.Selected.Text;Count:=0;
 for V in FActionPurposes.GetValue<TJSONArray>('rows') do begin Row:=V as TJSONObject;
  if (StateFilter<>'') and (StateFilter<>TDPHActionPurposes.State(Row,FKnowledge)) then Continue;
  if (Query<>'') and not ContainsText(TDPHActionPurposes.Describe(Row,FKnowledge),Query) then Continue;
  if (Count>=FActionPurposeOffset) and (FActionPurposeRows.Count<250) then begin FActionPurposeRows.Add(Row);ActionPurposeList.Items.Add(Row.GetValue<string>('target')+' | '+Row.GetValue<string>('name')+' | '+TDPHActionPurposes.State(Row,FKnowledge));end;Inc(Count);
 end;
 ActionPurposeNextButton.Enabled:=Count>FActionPurposeOffset+FActionPurposeRows.Count;
 ActionPurposeStatus.Text:=IntToStr(Count)+' matches; '+IntToStr(FActionPurposeRows.Count)+' shown from '+IntToStr(FActionPurposeOffset)+'. Select a row for evidence and review state.';
 if ActionPurposeList.Count>0 then begin ActionPurposeList.ItemIndex:=0;ActionPurposeSelectionClick(nil);end else ActionPurposeMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.a14d020f41ef0d1c', 'No matching actions or tasks. Clear filters or click New task for a project procedure.');
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
 if FDetached then begin ActionPurposeMemo.Lines.Add(DATTranslateText('DPH.UI.Main.Memo.08ca6e511f32b2d0', 'Source is detached. Attach unchanged source to navigate.'));Exit;end;
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
    RefreshKnowledgeLinks;FKnowledgeEdited:=True;KnowledgeSectionLabel.Text:='Action purpose draft: click Save, then review explicitly';KnowledgeHistoryMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.9c745121dac9d482', 'Edit structured fields on Action purposes. Add exact evidence on Knowledge links. Saving does not verify business claims or actual outcomes.');
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
 InheritanceMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.d5555980302dafaa', 'Select a component to inspect base-to-derived property and event declarations.');
 if FInheritance=nil then Exit;Query:=InheritanceFilterEdit.Text.Trim;Count:=0;
 for V in FInheritance.GetValue<TJSONArray>('rows') do begin Row:=V as TJSONObject;
  if (Query<>'') and not ContainsText(TDPHFormInheritance.Describe(Row),Query) then Continue;
  if (Count>=FInheritanceOffset) and (FInheritanceRows.Count<250) then begin FInheritanceRows.Add(Row);InheritanceList.Items.Add(Row.GetValue<string>('form_source')+' | '+Row.GetValue<string>('component_path')+' : '+Row.GetValue<string>('class'));end;Inc(Count);
 end;
 InheritanceNextButton.Enabled:=Count>FInheritanceOffset+FInheritanceRows.Count;
 InheritanceStatus.Text:=IntToStr(Count)+' matching components; showing '+IntToStr(FInheritanceRows.Count)+' from offset '+IntToStr(FInheritanceOffset)+'. Select an origin to inspect its exact source.';
 if InheritanceList.Count>0 then begin InheritanceList.ItemIndex:=0;InheritanceSelectionClick(nil);end else InheritanceMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.490ce37175fe7bdd', 'No matching components. Clear the filter or inspect Coverage for missing form source.');
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
 if FDetached then begin InheritanceMemo.Lines.Add(DATTranslateText('DPH.UI.Main.Memo.08ca6e511f32b2d0', 'Source is detached. Attach unchanged source to navigate.'));Exit;end;
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
 DependencyMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.57f18394d8bb348a', 'Select a component to inspect captured class evidence and authored dependency information.');if FDependencies=nil then Exit;
 Query:=DependencyFilterEdit.Text.Trim;Count:=0;
 for V in FDependencies.GetValue<TJSONArray>('rows') do begin Row:=V as TJSONObject;
  if (Query<>'') and not ContainsText(TDPHComponentDependencies.Describe(Row,FKnowledge),Query) then Continue;
  if (Count>=FDependencyOffset) and (FDependencyRows.Count<250) then begin FDependencyRows.Add(Row);DependencyList.Items.Add(Row.GetValue<string>('form')+' / '+Row.GetValue<string>('name')+' : '+Row.GetValue<string>('class')+' | '+Row.GetValue<string>('resolution'));end;Inc(Count);
 end;
 DependencyNextButton.Enabled:=Count>FDependencyOffset+FDependencyRows.Count;
 DependencyStatus.Text:=IntToStr(Count)+' matching components; showing '+IntToStr(FDependencyRows.Count)+' from offset '+IntToStr(FDependencyOffset)+'. Vendor and runtime support require attributed evidence.';
 if DependencyList.Count>0 then begin DependencyList.ItemIndex:=0;DependencySelectionClick(nil);end else DependencyMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.8d2d331b307fffea', 'No matching components. Clear the filter or inspect Coverage for uncaptured forms.');
end;
procedure TDPHMainForm.DependencySelectionClick(Sender:TObject);
var V:TJSONValue;Row:TJSONObject;
begin
 DependencySourceButton.Enabled:=False;DependencyEditButton.Enabled:=False;DependencyKnowledgeButton.Enabled:=False;DependencyClassButton.Enabled:=False;
 if (DependencyList.ItemIndex<0) or (DependencyList.ItemIndex>=FDependencyRows.Count) then Exit;
 Row:=FDependencyRows[DependencyList.ItemIndex];DependencyMemo.Text:=TDPHComponentDependencies.Describe(Row,FKnowledge)+sLineBreak+sLineBreak+FDependencies.GetValue<string>('qualification');
 DependencyMemo.Lines.Add(DATTranslateText('DPH.UI.Main.Memo.d4d288d87088c834', 'CAPTURED PACKAGE DECLARATIONS (not component membership)'));
 for V in FDependencies.GetValue<TJSONArray>('packages') do DependencyMemo.Lines.Add(V.GetValue<string>('name')+' | '+V.GetValue<string>('source')+' | SHA-256 '+V.GetValue<string>('source_hash'));
 DependencyMemo.Lines.Add(DATTranslateText('DPH.UI.Main.Memo.c9ada9524c8eda15', 'UNAVAILABLE INPUTS (project-wide; not automatically attributed to this class)'));
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
 if FDetached then begin DependencyMemo.Lines.Add(DATTranslateText('DPH.UI.Main.Memo.08ca6e511f32b2d0', 'Source is detached. Attach unchanged source to navigate.'));Exit;end;
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
    RefreshKnowledgeLinks;FKnowledgeEdited:=True;KnowledgeSectionLabel.Text:='Component dependency draft: click Save, then review explicitly';KnowledgeHistoryMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.a50484bc885fb662', 'Edit structured fields on Component dependencies. Use Knowledge links for exact evidence. Saving does not resolve class source or verify vendor claims.');
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
    RefreshKnowledgeLinks;FKnowledgeEdited:=True;KnowledgeSectionLabel.Text:='Data dictionary draft: click Save, then review explicitly';KnowledgeHistoryMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.a4dcc52c6279d25d', 'Edit fields using Database schema > Edit dictionary. Captured source, SHA256, statement line and schema identity stay read only. Use Knowledge links for additional evidence. Saving does not verify business meanings.');
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
 LayoutMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.57d2201611e9dae2', 'Select a component to read its layout declarations.');if FLayout=nil then Exit;
 Query:=LayoutFilterEdit.Text.Trim;Count:=0;
 for V in FLayout.GetValue<TJSONArray>('rows') do begin Row:=V as TJSONObject;
  if (Query<>'') and not ContainsText(TDPHLayoutRules.Describe(Row,FLayoutWidthDelta,FLayoutHeightDelta),Query) then Continue;
  if (Count>=FLayoutOffset) and (FLayoutRows.Count<250) then begin FLayoutRows.Add(Row);LayoutList.Items.Add(Row.GetValue<string>('form')+' / '+Row.GetValue<string>('parent')+' / '+Row.GetValue<string>('name')+' : '+Row.GetValue<string>('class'));end;Inc(Count);
 end;
 LayoutNextButton.Enabled:=Count>FLayoutOffset+FLayoutRows.Count;
 LayoutStatus.Text:=IntToStr(Count)+' matching components; showing '+IntToStr(FLayoutRows.Count)+' from offset '+IntToStr(FLayoutOffset)+'. Examples do not evaluate the target layout engine.';
 if LayoutList.Count>0 then begin LayoutList.ItemIndex:=0;LayoutSelectionClick(nil);end else LayoutMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.b32b8ca2b87a4e75', 'No matching component. Clear the filter or inspect Coverage for uncaptured forms.');
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
 if FDetached then begin LayoutMemo.Lines.Add(DATTranslateText('DPH.UI.Main.Memo.08ca6e511f32b2d0', 'Source is detached. Attach unchanged source to navigate.'));Exit;end;
 try SourceMemo.Text:=TDPHKeyboardInspector.ReadSource(FView,FEntry,Row,Range);SourceMemo.CaretPosition:=TCaretPosition.Create(Max(0,Range.GetValue<Integer>('line')-1),Max(0,Range.GetValue<Integer>('column')-1));WorkspaceTabs.ActiveTab:=SourceTab;
 except on E:Exception do LayoutMemo.Lines.Add('Source unavailable: '+E.Message);end;
end;

procedure TDPHMainForm.DynamicFilterChange(Sender:TObject);
var V:TJSONValue; Row:TJSONObject; Count:Integer; Query:string;
begin
 if Sender=DynamicNextButton then Inc(FDynamicOffset,250) else FDynamicOffset:=0;
 DynamicList.Items.Clear; FDynamicRows.Clear; DynamicReferenceCombo.Items.Clear;
 DynamicNextButton.Enabled:=False; DynamicExplainButton.Enabled:=False; DynamicReferenceButton.Enabled:=False;
 DynamicMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.bb0dc83ead2a9983', 'Select a creation site to read its evidence and limits.');
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
 else DynamicMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.f6e34b76c138e602', 'No matching captured creation sites. Clear the filter or reassess. Unsupported factories and indirect creation remain gaps; this is not proof of no runtime controls.');
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
  CommandsMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.464869b647cb362c', 'Select a captured menu, toolbar command or action for explanations and source evidence.');
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
  else CommandsMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.b483e7609df4e61c', 'No matching captured command. Clear filters or inspect Coverage for missing form inputs.');
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
  if FDetached then begin CommandsMemo.Lines.Add(DATTranslateText('DPH.UI.Main.Memo.9df3e10026af697a', 'Source is detached. Captured command evidence remains readable. Attach unchanged source to navigate.')); Exit; end;
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
  else ComparisonBeforeMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.6f09e914f216e8c0', 'No matching changes in the captured evidence. This does not prove complete semantic equivalence.');
end;
procedure TDPHMainForm.ComparisonSelectionClick(Sender: TObject);
var Row: TJSONObject; Value: TJSONValue;
begin
  if (FComparison=nil) or (ComparisonList.ItemIndex<0) then Exit;
  if ComparisonList.ItemIndex>=FComparison.GetValue<TJSONArray>('changes').Count then Exit;
  Row:=FComparison.GetValue<TJSONArray>('changes').Items[ComparisonList.ItemIndex] as TJSONObject;
  Value:=Row.GetValue('before'); if Value is TJSONObject then ComparisonBeforeMemo.Text:=TDPHRevisionComparison.EvidenceText(Value as TJSONObject)
  else ComparisonBeforeMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.a421865a12dec472', 'Absent from the Before capture.');
  Value:=Row.GetValue('after'); if Value is TJSONObject then ComparisonAfterMemo.Text:=TDPHRevisionComparison.EvidenceText(Value as TJSONObject)
  else ComparisonAfterMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.9c618a8eb1742cac', 'Absent from the After capture.');
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
  QualityMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.4e1b071080be460b', 'Open a captured project to inspect source quality candidates.');
  if FView=nil then Exit;
  if not FView.Document.TryGetValue<TJSONObject>('source_quality',Quality) then begin
    QualityMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.0015cbdd796f77f6', 'This older capture has no source quality report. Attach source and reassess; detached caches retain their original evidence.'); Exit;
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
  FreeAndNil(FCoverage); CoverageList.Items.Clear; CoverageMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.30c4381dcdbbb81e', 'Open a captured project to see coverage and gaps.');
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
  FreeAndNil(FQuestions); QuestionsList.Items.Clear; QuestionMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.2c1dfa814bf45e07', 'Open a captured project to derive focused author questions.');
  if FView=nil then Exit; FQuestions:=FView.Questions(FKnowledge);
  for V in FQuestions do QuestionsList.Items.Add(V.GetValue<string>('title')+' | '+V.GetValue<string>('range.source'));
  if FQuestions.Count>0 then begin QuestionsList.ItemIndex:=0; QuestionSelectionClick(nil); end
  else QuestionMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.e253ada72aef6856', 'No unanswered question was generated by the supported rules in this scope. This does not prove complete requirements or documentation.');
end;
procedure TDPHMainForm.QuestionSelectionClick(Sender: TObject);
var Row,Range: TJSONObject;
begin
  if (FQuestions=nil) or (QuestionsList.ItemIndex<0) then Exit;
  Row:=FQuestions.Items[QuestionsList.ItemIndex] as TJSONObject; Range:=Row.GetValue<TJSONObject>('range');
  QuestionMemo.Text:=Row.GetValue<string>('prompt')+sLineBreak+sLineBreak+
    'Choose Record author answer to preserve the explanation supplied by someone who knows this application.';
  if Range.GetValue<string>('source')<>'' then QuestionMemo.Lines.Add('Related source: '+Range.GetValue<string>('source')+':'+Range.GetValue<Int64>('line').ToString);
  QuestionMemo.Lines.Add(DATTranslateText('DPH.UI.Main.Memo.5b43045b545b3633', 'This is an unanswered question. It does not establish a problem in the running application. Inspect evidence opens the supporting detail.'));
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
  ReviewBeforeMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.dd98c8692fd502b9', 'No pending review tasks in this captured scope.'); ReviewAfterMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.74ca1e7fe27a873a', 'This is not proof that documentation is complete or approved.');
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
  FCardRows.Clear; CardList.Items.Clear;
  FreeAndNil(FExplanations); FreeAndNil(FLearningFacts); if FView=nil then Exit;
  FLearningFacts:=TDPHDocumentModel.Create(FView,FKnowledge,[],[],FDetached,FDetached,nil,True);
  if FLearningDirectory='' then begin CreateGUID(ID);
    FLearningDirectory:=TPath.Combine(TPath.GetTempPath,'DPH-Learning-'+GUIDToString(ID));
    FExplainDirectory:=TPath.Combine(FLearningDirectory,'object');
    FFlowDirectory:=TPath.Combine(FLearningDirectory,'flow');
    TDirectory.CreateDirectory(FLearningDirectory); TDirectory.CreateDirectory(FExplainDirectory); TDirectory.CreateDirectory(FFlowDirectory);
  end;
  FOverviewLanguageGeneration:=0;
  FMapLanguageGeneration:=0;
  FGraphLanguageGeneration:=0;
  CardFilterChange(nil);
  if LearningTopics.ItemIndex>=0 then LearningClick(nil);
end;
function TDPHMainForm.PrepareOfflineProjectTranslation(var AHTML: string): Boolean;
var
  AssetsDirectory: string;
begin
  Result := False;
  if not SameText(DATLanguageManager.CurrentLanguageCode, 'de-DE') or
     not AHTML.Contains('class="project-prose"') then Exit;
  try
    if FOfflinePreview = nil then begin
      AssetsDirectory := TPath.Combine(FBaseDirectory, 'Localization\OfflineTranslation');
      FOfflinePreview := TDPHOfflinePreview.Create(FLearningDirectory, AssetsDirectory);
    end;
  except
    on E: Exception do begin
      StatusLabel.Text := 'Offline project translation unavailable: ' + E.Message;
      Exit;
    end;
  end;
  if AHTML.Contains('Content-Security-Policy') then
    AHTML := AHTML.Replace('script-src ''none''; connect-src ''none'';',
      'script-src ''self'' ''wasm-unsafe-eval''; worker-src ''self''; connect-src ''self'';')
  else
    AHTML := AHTML.Replace('<head>', '<head><meta http-equiv="Content-Security-Policy" ' +
      'content="default-src ''none''; style-src ''unsafe-inline''; img-src ''self'' data:; ' +
      'script-src ''self'' ''wasm-unsafe-eval''; worker-src ''self''; connect-src ''self''; ' +
      'base-uri ''none''">');
  AHTML := TRegEx.Replace(AHTML, '<html\b',
    '<html class="offline-translation-pending"', [roIgnoreCase]);
  AHTML := AHTML.Replace('</head>',
    '<style>.offline-translation-pending pre.project-prose{opacity:0;animation:dph-show-original 0s 8s forwards}' +
    '@keyframes dph-show-original{to{opacity:1}}' +
    '#offline-translation-status{margin:0 0 16px}</style></head>');
  if AHTML.Contains('<main>') then
    AHTML := AHTML.Replace('<main>',
      '<main><p id="offline-translation-status" class="warning" lang="de">' +
      'Der Projekttext wird lokal ins Deutsche übersetzt…</p>')
  else
    AHTML := AHTML.Replace('<body>',
      '<body><p id="offline-translation-status" lang="de">' +
      'Der Projekttext wird lokal ins Deutsche übersetzt…</p>');
  AHTML := AHTML.Replace('</body>', '<script type="module" src="' +
    FOfflinePreview.ScriptURL + '"></script></body>');
  Result := True;
end;
procedure TDPHMainForm.LearningClick(Sender: TObject);
var HTML,PreviewPath: string; Offline: Boolean;
begin
  if FBinding then Exit;
  if FLearningFacts=nil then begin
    if FView<>nil then begin
      if LearningTopics.ItemIndex>=0 then RefreshLearning;
      Exit;
    end;
    if FLearningDirectory='' then Exit;
    try HTML:=TFile.ReadAllText(TPath.Combine(FBaseDirectory,
      'help\dossier-start.html'),TEncoding.UTF8);
    except on E: Exception do begin
      StatusLabel.Text:='Handoff page unavailable: '+E.Message;
      Exit;
    end; end;
  end else begin
    HTML:=TDPHHandoffDossier.Render(FLearningFacts.Document,
      Max(0,LearningTopics.ItemIndex));
  end;
  HTML:=HTML.Replace('href="#','href="index.html#');
  HTML:=DATTranslateHtmlText(HTML);
  Offline:=(FLearningFacts<>nil) and PrepareOfflineProjectTranslation(HTML);
  OverviewMemo.Text:='';
  PreviewPath:=TPath.Combine(FLearningDirectory,THashSHA2.GetHashString(HTML)+'.html');
  if not FPreviewPages.Contains(PreviewPath) then begin TFile.WriteAllBytes(PreviewPath,TEncoding.UTF8.GetBytes(HTML)); FPreviewPages.Add(PreviewPath); end;
  TFile.WriteAllBytes(TPath.Combine(FLearningDirectory,'index.html'),TEncoding.UTF8.GetBytes(HTML));
  FExpectedDossierPage:=TPath.GetFileName(PreviewPath);
  try LearningBrowser.WindowsEngine:=TWindowsEngine.EdgeOnly; OverviewMemo.Visible:=False; LearningBrowser.Visible:=True;
    if Offline then LearningBrowser.Navigate(FOfflinePreview.URLForPage(PreviewPath))
    else LearningBrowser.Navigate('file://'+PreviewPath);
  except on E: Exception do begin
    FExpectedDossierPage:='';
    LearningBrowser.Visible:=False; OverviewMemo.Visible:=False;
    StatusLabel.Text:='Handoff HTML page could not load: '+E.Message;
    if FPreparingProject and (FPendingCommand='open') then begin
      FPreparingProject:=False;
      WorkspaceTabs.Enabled:=True;
      ProjectPreparationLayout.Visible:=False;
    end;
  end; end;
end;
procedure TDPHMainForm.LearningBrowserDidFinishLoad(Sender: TObject);
begin
  if Sender=FlowBrowser then begin
    if (FExpectedGraphPage<>'') and
      ContainsText(FlowBrowser.URL,FExpectedGraphPage) and
      (WorkspaceTabs.ActiveTab=GraphTab) then FlowBrowser.Visible:=True;
    Exit;
  end;
  if FPreparingProject and (FPendingCommand='open') and
    (FExpectedDossierPage<>'') and
    ContainsText(LearningBrowser.URL,FExpectedDossierPage) then begin
    LearningBrowser.Visible:=True;
    FPreparingProject:=False;
    WorkspaceTabs.Enabled:=True;
    ProjectPreparationProgress.Value:=100;
    ProjectPreparationPercent.Text:='100%';
    ProjectPreparationMessage.Text:=DATTranslateDynamicText('Project ready to explore.');
    FPreparationCompletionTicks:=5;
  end;
end;
procedure TDPHMainForm.ShowExplanation;
var HTML,PreviewPath,Fallback: string; Offline: Boolean;
begin
  if (FLearningFacts=nil) and (FView<>nil) then RefreshLearning;
  if FLearningFacts=nil then Exit;
  if FExplanations=nil then FExplanations:=TDPHExplanationModel.Create(FLearningFacts.Document);
  if FSelected='' then HTML:=FExplanations.ProjectMapHTML
  else HTML:=FExplanations.ObjectLessonHTML(FSelected);
  HTML:=HTML.Replace('href="#','href="index.html#');
  HTML:=DATTranslateHtmlText(HTML);
  Offline:=PrepareOfflineProjectTranslation(HTML);
  ExplainFallback.Text:='';
  PreviewPath:=TPath.Combine(FExplainDirectory,THashSHA2.GetHashString(HTML)+'.html');
  if not FPreviewPages.Contains(PreviewPath) then begin TFile.WriteAllBytes(PreviewPath,TEncoding.UTF8.GetBytes(HTML)); FPreviewPages.Add(PreviewPath); end;
  TFile.WriteAllBytes(TPath.Combine(FExplainDirectory,'index.html'),TEncoding.UTF8.GetBytes(HTML));
  try ExplainBrowser.WindowsEngine:=TWindowsEngine.EdgeOnly; ExplainFallback.Visible:=False; ExplainBrowser.Visible:=True;
    if Offline then ExplainBrowser.Navigate(FOfflinePreview.URLForPage(PreviewPath))
    else ExplainBrowser.Navigate('file://'+PreviewPath);
  except on E: Exception do begin
    Fallback:=Copy(HTML,Pos('<main>',HTML)+6,MaxInt);Fallback:=Copy(Fallback,1,Pos('</main>',Fallback)-1);
    Fallback:=TRegEx.Replace(Fallback,'<details\b[^>]*>.*?</details>','',[roSingleLine,roIgnoreCase]);
    Fallback:=TRegEx.Replace(Fallback,'</(p|h[1-6]|li|section|ol|ul)>|<br\s*/?>',sLineBreak,[roIgnoreCase]);
    ExplainFallback.Text:=TNetEncoding.HTML.Decode(TRegEx.Replace(Fallback,'<[^>]+>','')).Trim;
    ExplainBrowser.Visible:=False; ExplainFallback.Visible:=True;
    StatusLabel.Text:='Object preview unavailable; text fallback is shown: '+E.Message;
  end; end;
end;
procedure TDPHMainForm.LearningShouldLoad(Sender: TObject; const AURL: string; var ACancel: Boolean);
var Directory,Fragment,NodeKey: string; P,I,J,ImageIndex: Integer; V: TJSONValue; S: TJSONObject; GuideIndexes,Guides: TJSONArray;
  FormSources: TJSONArray;
begin
  Directory:=FLearningDirectory; if Sender=ExplainBrowser then Directory:=FExplainDirectory;
  if Sender=FlowBrowser then Directory:=FFlowDirectory;
  if Sender=HelpBrowser then Directory:=FLearningDirectory;
  ACancel:=not (TDPHBrowserPolicy.Allowed(AURL,Directory,False,True) or
    ((FOfflinePreview<>nil) and FOfflinePreview.Allows(AURL,Directory)));
  if ACancel then Exit;
  if EndsText('#open_forms',AURL) then begin
    ACancel:=True;
    if WorkspaceTabs.ActiveTab<>ScreenshotTab then FScreenshotOriginTab:=WorkspaceTabs.ActiveTab;
    ScreenshotReturnButton.Enabled:=FScreenshotOriginTab<>nil;
    WorkspaceTabs.ActiveTab:=ScreenshotTab;
    Exit;
  end;
  P:=Pos('#form_',AURL);
  if P>0 then begin
    ACancel:=True; Fragment:=Copy(AURL,P+6,MaxInt);
    for I:=0 to FormCombo.Items.Count-1 do
      if SameText(THashSHA2.GetHashString(FormCombo.Items[I]),Fragment) then begin
        if WorkspaceTabs.ActiveTab<>ScreenshotTab then FScreenshotOriginTab:=WorkspaceTabs.ActiveTab;
        ScreenshotReturnButton.Enabled:=FScreenshotOriginTab<>nil;
        FormCombo.ItemIndex:=I; WorkspaceTabs.ActiveTab:=ScreenshotTab;
        if FImages<>nil then for ImageIndex:=0 to FImages.Count-1 do begin
          S:=FImages.Items[ImageIndex] as TJSONObject;
          FormSources:=S.GetValue<TJSONArray>('form_sources',nil);
          if FormSources=nil then Continue;
          for V in FormSources do
            if SameText(V.Value,FormCombo.Items[I]) then begin
              ScreenshotList.ItemIndex:=ImageIndex; ScreenshotClick(nil);
              StatusLabel.Text:='Showing '+FormCombo.Items[I]+'.'; Exit;
            end;
        end;
        ScreenshotList.ItemIndex:=-1; ScreenshotImage.Bitmap.SetSize(0,0);
        ScreenshotEvidence.Text:='A generated screen is unavailable for '+FormCombo.Items[I]+'.';
        StatusLabel.Text:=ScreenshotEvidence.Text; Exit;
      end;
    StatusLabel.Text:='This form is not available in the selected project.'; Exit;
  end;
  if EndsText('#open_screenshots',AURL) then begin
    ACancel:=True;
    if WorkspaceTabs.ActiveTab<>ScreenshotTab then FScreenshotOriginTab:=WorkspaceTabs.ActiveTab;
    ScreenshotReturnButton.Enabled:=FScreenshotOriginTab<>nil;
    WorkspaceTabs.ActiveTab:=ScreenshotTab; Exit;
  end;
  if EndsText('#open_commands',AURL) then begin
    ACancel:=True; WorkspaceTabs.ActiveTab:=CommandsTab; Exit;
  end;
  if EndsText('#open_data',AURL) then begin
    ACancel:=True; WorkspaceTabs.ActiveTab:=DatabaseInventoryTab; Exit;
  end;
  if EndsText('#open_schema',AURL) then begin
    ACancel:=True; WorkspaceTabs.ActiveTab:=DatabaseSchemaTab; Exit;
  end;
  if EndsText('#open_dependencies',AURL) then begin
    ACancel:=True; WorkspaceTabs.ActiveTab:=DependencyTab; Exit;
  end;
  if EndsText('#open_files',AURL) then begin
    ACancel:=True; WorkspaceTabs.ActiveTab:=FileFormatsTab; Exit;
  end;
  if EndsText('#open_quality',AURL) then begin
    ACancel:=True; WorkspaceTabs.ActiveTab:=QualityTab; Exit;
  end;
  if EndsText('#open_coverage',AURL) then begin
    ACancel:=True; WorkspaceTabs.ActiveTab:=CoverageTab; Exit;
  end;
  P:=Pos('#library_',AURL);
  if P>0 then begin
    ACancel:=True; Fragment:=Copy(AURL,P+9,MaxInt);
    CardFilter.Text:=''; CardFilterChange(nil);
    Guides:=FLearningFacts.Document.GetValue<TJSONArray>('project_guides');
    for I:=0 to FCardRows.Count-1 do begin
      S:=FCardRows[I];
      GuideIndexes:=S.GetValue<TJSONArray>('guide_indices',nil);
      if GuideIndexes=nil then Continue;
      for J:=0 to GuideIndexes.Count-1 do begin
        S:=Guides.Items[StrToInt(GuideIndexes.Items[J].Value)] as TJSONObject;
        if SameText(THashSHA2.GetHashString(S.GetValue<string>('source','')),Fragment) then begin
          CardList.ItemIndex:=I;CardSelectionChange(nil);
          CardDocumentLocation.ItemIndex:=J;CardSelectionChange(CardDocumentLocation);
          WorkspaceTabs.ActiveTab:=CardLibraryTab;
          StatusLabel.Text:='Showing '+TPath.GetFileName(S.GetValue<string>('source'))+' in the Learning library.';
          Exit;
        end;
      end;
    end;
    StatusLabel.Text:='This document is not available in the selected project.'; Exit;
  end;
  if EndsText('#all_objects',AURL) or EndsText('#objects',AURL) or (Pos('#kind_',AURL)>0) then begin
    ACancel:=True; FBinding:=True;
    try
      SearchEdit.Text:=''; KindCombo.ItemIndex:=0;
      if Pos('#kind_',AURL)>0 then KindCombo.ItemIndex:=KindCombo.Items.IndexOf(Copy(AURL,Pos('#kind_',AURL)+6,MaxInt));
    finally FBinding:=False; end;
    FSelected:=''; FScope:=''; FPage:=0; FShowingBookmarks:=False;
    RefreshExplorer; ShowExplanation; WorkspaceTabs.ActiveTab:=ExplainTab; Exit;
  end;
  if EndsText('#task_reader',AURL) then begin
    ACancel:=True;LearningTopics.ItemIndex:=1;LearningClick(nil);WorkspaceTabs.ActiveTab:=OverviewTab;Exit;
  end;
  if EndsText('#ask_author',AURL) then begin ACancel:=True;WorkspaceTabs.ActiveTab:=QuestionsTab;Exit;end;
  P:=Pos('#lesson_',AURL);
  if P>0 then begin
    ACancel:=True;
    if TryStrToInt(Copy(AURL,P+8,MaxInt),I) and (I>=0) and (I<LearningTopics.Count) then begin
      LearningTopics.ItemIndex:=I; LearningClick(nil); WorkspaceTabs.ActiveTab:=OverviewTab;
    end;
    Exit;
  end;
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
var ID:TGUID; HTML,PreviewPath,Logo,ImagePath:string;
begin
  WorkspaceTabs.ActiveTab:=HelpTab;
  if FLearningDirectory='' then begin
    CreateGUID(ID); FLearningDirectory:=TPath.Combine(TPath.GetTempPath,'DPH-Learning-'+GUIDToString(ID));
    FExplainDirectory:=TPath.Combine(FLearningDirectory,'object'); FFlowDirectory:=TPath.Combine(FLearningDirectory,'flow');
    TDirectory.CreateDirectory(FLearningDirectory); TDirectory.CreateDirectory(FExplainDirectory); TDirectory.CreateDirectory(FFlowDirectory);
  end;
  Logo:=''; ImagePath:=TPath.Combine(FBaseDirectory,'images and icons\DPH-Emblem-128.png');
  if TFile.Exists(ImagePath) then Logo:='<img src="data:image/png;base64,'+
    TNetEncoding.Base64.EncodeBytesToString(TFile.ReadAllBytes(ImagePath))+'" alt="Delphi Project Handoff logo">';
  HTML:='<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'+
    '<meta http-equiv="Content-Security-Policy" content="default-src ''none''; style-src ''unsafe-inline''; img-src data:; script-src ''none''; connect-src ''none''; base-uri ''none''">'+
    '<style>body{margin:0;background:#f1f5fa;color:#20364a;font:18px/1.6 Segoe UI,Arial,sans-serif;overflow-wrap:anywhere}'+
    'header{background:#146cb4;color:white;padding:28px;border-bottom:5px solid #f28c28;display:flex;align-items:center;gap:22px}header img{width:88px;height:88px;object-fit:contain}h1{margin:0;font-size:34px}main{padding:26px;max-width:1000px;margin:auto}'+
    'section{padding:24px;margin-bottom:20px;background:white;border:1px solid #dce5ef;border-radius:9px}h2{color:#146cb4;font-size:24px}li{margin-bottom:14px}'+
    '*{box-sizing:border-box}a{color:#146cb4}</style><title>Explore an application with DPH</title></head><body><header>'+Logo+'<div><h1>Welcome to Delphi Project Handoff</h1>'+
    '<p>Build a source-backed maintenance handoff for an unfamiliar Delphi application.</p></div></header><main><section><h2>Open the application project</h2><p>Select <strong>Open application</strong> and choose a .dproj, .dpr or .groupproj file. DPH reads project files, form designs, source, and eligible local documentation. For an existing capture, choose <strong>Open saved project</strong>.</p></section>'+
    '<section><h2>Read the handoff</h2><ol><li><strong>Handoff dossier</strong> presents purpose evidence, startup order, command bindings, data candidates and open questions.</li><li><strong>Learning library</strong> shows project-local guides and help.</li><li><strong>Project map</strong> links captured objects to source and relationships.</li><li><strong>Screenshots</strong> generates form previews on demand from .dfm or .fmx designs; an imported runtime image remains separate evidence.</li><li><strong>Application diagrams</strong> shows static connections that still need runtime confirmation.</li></ol></section>'+
    '<section><h2>Evidence limits</h2><p>Extracted facts, source-derived inferences and contributor claims have different certainty. Every conclusion should be checked against its source citation and capture configuration. DPH does not run or change the selected application. Optional public-website reading is controlled by the checkbox in the header.</p></section></main></body></html>';
  if SameText(DATActiveLanguageCode,'de-DE') then begin
    HTML:=HTML.Replace('<html lang="en">','<html lang="de">')
      .Replace('Explore an application with DPH','Eine Anwendung mit DPH erkunden')
      .Replace('Welcome to Delphi Project Handoff','Willkommen bei Delphi Project Handoff')
      .Replace('Build a source-backed maintenance handoff for an unfamiliar Delphi application.',
        'Erstellen Sie eine anhand des Quellcodes belegte Übergabe für eine unbekannte Delphi-Anwendung.')
      .Replace('<section><h2>Open the application project</h2><p>Select <strong>Open application</strong> and choose a .dproj, .dpr or .groupproj file. DPH reads project files, form designs, source, and eligible local documentation. For an existing capture, choose <strong>Open saved project</strong>.</p></section>',
        '<section><h2>Anwendungsprojekt öffnen</h2><p>Wählen Sie <strong>Anwendung öffnen</strong> und danach eine .dproj-, .dpr- oder .groupproj-Datei. DPH liest Projektdateien, Formularentwürfe, Quellcode und geeignete lokale Dokumentation. Um eine vorhandene Erfassung zu laden, wählen Sie <strong>Gespeichertes Projekt öffnen</strong>.</p></section>')
      .Replace('<section><h2>Read the handoff</h2><ol><li><strong>Handoff dossier</strong> presents purpose evidence, startup order, command bindings, data candidates and open questions.</li><li><strong>Learning library</strong> shows project-local guides and help.</li><li><strong>Project map</strong> links captured objects to source and relationships.</li><li><strong>Screenshots</strong> generates form previews on demand from .dfm or .fmx designs; an imported runtime image remains separate evidence.</li><li><strong>Application diagrams</strong> shows static connections that still need runtime confirmation.</li></ol></section>',
        '<section><h2>Die Übergabe lesen</h2><ol><li>Das <strong>Übergabedossier</strong> zeigt Belege zum Zweck, die Startreihenfolge, Befehlszuordnungen, Datenkandidaten und offene Fragen.</li><li>Die <strong>Lernbibliothek</strong> zeigt projektspezifische Anleitungen und Hilfen.</li><li>Die <strong>Projektkarte</strong> verbindet erfasste Objekte mit Quellcode und Beziehungen.</li><li>Unter <strong>Screenshots</strong> lassen sich Formularvorschauen bei Bedarf aus .dfm- oder .fmx-Dateien erzeugen; importierte Laufzeitbilder bleiben getrennte Belege.</li><li>Die <strong>Anwendungsdiagramme</strong> zeigen statische Verbindungen, die noch zur Laufzeit bestätigt werden müssen.</li></ol></section>')
      .Replace('<section><h2>Evidence limits</h2><p>Extracted facts, source-derived inferences and contributor claims have different certainty. Every conclusion should be checked against its source citation and capture configuration. DPH does not run or change the selected application. Optional public-website reading is controlled by the checkbox in the header.</p></section>',
        '<section><h2>Grenzen der Belege</h2><p>Extrahierte Fakten, aus dem Quellcode abgeleitete Schlussfolgerungen und Angaben von Mitwirkenden haben unterschiedliche Gewissheit. Prüfen Sie jede Schlussfolgerung anhand ihres Quellverweises und der Erfassungskonfiguration. DPH führt die ausgewählte Anwendung nicht aus und verändert sie nicht. Das Kontrollkästchen oben steuert das optionale Lesen öffentlicher Websites.</p></section>');
  end;
  PreviewPath:=TPath.Combine(FLearningDirectory,THashSHA2.GetHashString(HTML)+'.html');
  if not FPreviewPages.Contains(PreviewPath) then begin TFile.WriteAllBytes(PreviewPath,TEncoding.UTF8.GetBytes(HTML));FPreviewPages.Add(PreviewPath);end;
  try HelpBrowser.WindowsEngine:=TWindowsEngine.EdgeOnly; HelpBrowser.Visible:=True;
    HelpBrowser.Navigate('file://'+PreviewPath);
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
    if FView=nil then begin ValidationMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.6773836d227c3e4b', 'Open a trusted project capture first, or enter its separately retained expected fingerprint.'); Exit; end;
    ValidationFingerprintEdit.Text:=FView.Document.GetValue<string>('semantics.input_fingerprint');
    ValidationMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.8f8514ca017a36e4', 'Expected fingerprint copied from the opened capture. Select the bundle manifest to validate it against this identity.'); Exit;
  end;
  Fingerprint:=LowerCase(Trim(ValidationFingerprintEdit.Text));
  if Length(Fingerprint)<>64 then begin ValidationMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.b38c4c648e2d5d34', 'Enter the separately trusted 64-character capture fingerprint, or click Use opened capture fingerprint.'); Exit; end;
  for Character in Fingerprint do if not CharInSet(Character,['0'..'9','a'..'f']) then begin ValidationMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.9ab20045e883d4f5', 'The expected fingerprint must contain exactly 64 hexadecimal characters.'); Exit; end;
  if not ValidationDialog.Execute then Exit;
  if not SameText(ExtractFileName(ValidationDialog.FileName),'manifest.json') then begin ValidationMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.3bacdefdbb6f0754', 'Select manifest.json in the root of the intended handoff bundle.'); Exit; end;
  Request:=Default(TDPHWorkspaceRequest); Request.Command:='validate_bundle'; Request.ExportDirectory:=ExtractFileDir(ValidationDialog.FileName);
  Request.Title:=Fingerprint; Request.AllowStaleBundle:=ValidationAllowStale.IsChecked;
  FWorker.Submit(Request); FBusy:=True; FPendingCommand:=Request.Command;
  ValidationMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.c160f5ad636119a0', 'Checking bundle integrity and source identity in the background...');
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
  Request.Kind:=ScreenshotKind.Selected.Text;
  FWorker.Submit(Request); FBusy:=True; StatusLabel.Text:='Importing the explicitly selected screenshot; no application will be executed...';
end;
procedure TDPHMainForm.LoadScreenshots(ARows: TJSONArray);
var V,Part: TJSONValue; R,Screen,Node: TJSONObject; Index,Count,Done,W,H,TabIndex: Integer;
  Thumbnail,Picture,EmbeddedPicture: TBitmap; LayoutRows,Files,FormSources: TJSONArray;
  Path,Source,CaptionText,ClassName,ImageDirectory,ImageHash,ColorText,FormPath,FormText,
    CatalogPath,CatalogHash,RootName,CaptionKey,TabName,TabCaption,SourceHash,ActiveTabName: string;
  GermanCatalog,GermanStrings: TJSONObject;
  Bounds,NavigatorBounds: TRectF; Scale: Single; Seen,TabNames,TabCaptions: TStringList; ImageStream: TMemoryStream;
  ImageStart,ImageEnd,NextObject,CharacterIndex,ByteCount,HighNibble,Nibble: Integer;
  MenuX: Single; TextColor: TAlphaColor; NavigatorButtons: TArray<string>;
  NavigatorIndex: Integer; NavigatorLabel: string;
  ImageBytes: TBytes; ImageCharacter: Char;
  WasBusy,WasTabsEnabled,WasTimerEnabled: Boolean;
begin
  GermanCatalog:=nil; GermanStrings:=nil; CatalogHash:='original';
  if (FView<>nil) and SameText(DATLanguageManager.CurrentLanguageCode,'de-DE') then begin
    CatalogPath:=TPath.Combine(TPath.Combine(FView.Document.GetValue<string>('root',''),
      'Localization'),TPath.Combine('Languages','de-DE.json'));
    if TFile.Exists(CatalogPath) and (TFile.GetSize(CatalogPath)<8388608) then begin
      try
        GermanCatalog:=TJSONObject.ParseJSONValue(TFile.ReadAllText(CatalogPath,TEncoding.UTF8)) as TJSONObject;
        if GermanCatalog<>nil then begin
          GermanStrings:=GermanCatalog.GetValue<TJSONObject>('strings',nil);
          if GermanStrings<>nil then CatalogHash:=THashSHA2.GetHashStringFromFile(CatalogPath);
        end;
      except
        FreeAndNil(GermanCatalog);
        GermanStrings:=nil;
        CatalogHash:='original';
      end;
    end;
  end;
  WasBusy:=FBusy; WasTabsEnabled:=WorkspaceTabs.Enabled; WasTimerEnabled:=PollTimer.Enabled;
  FRenderingScreens:=True; FBusy:=True; WorkspaceTabs.Enabled:=False; PollTimer.Enabled:=False;
  try
  HistorySelectionChange(nil); HistoryBeforeCombo.Items.Clear; HistoryAfterCombo.Items.Clear;
  FreeAndNil(FImages); FImages:=TJSONArray.Create; ScreenshotList.Items.Clear;
  if FView<>nil then begin
    Files:=FView.Document.GetValue<TJSONArray>('syntax.files',nil);
    if Files<>nil then begin
      Seen:=TStringList.Create;
      try
        Seen.Sorted:=True; Seen.Duplicates:=dupIgnore; Seen.CaseSensitive:=False;
        Count:=0;
        for V in Files do begin
          R:=V as TJSONObject; Source:=R.GetValue<string>('path','');
          if MatchText(LowerCase(TPath.GetExtension(Source)),['.fmx','.dfm']) and (R.GetValue('ir')<>nil) and (Seen.IndexOf(Source)<0) then begin
            Seen.Add(Source); Inc(Count);
          end;
        end;
        Seen.Clear; Done:=0;
        if FDatabase<>'' then
          ImageDirectory:=TPath.Combine(TPath.Combine(ExtractFilePath(TPath.GetFullPath(FDatabase)),'Screen Previews'),
            THashSHA2.GetHashString(LowerCase(TPath.GetFullPath(FDatabase))))
        else ImageDirectory:=TPath.Combine(FLearningDirectory,'screens');
        try TDirectory.CreateDirectory(ImageDirectory);
        except on E: Exception do begin
          ImageDirectory:=TPath.Combine(FLearningDirectory,'screens');
          TDirectory.CreateDirectory(ImageDirectory);
        end; end;
        for V in Files do begin
          R:=V as TJSONObject; Source:=R.GetValue<string>('path','');
          if not MatchText(LowerCase(TPath.GetExtension(Source)),['.fmx','.dfm']) or (R.GetValue('ir')=nil) or (Seen.IndexOf(Source)>=0) then Continue;
          Seen.Add(Source); Inc(Done); SourceHash:=R.GetValue<string>('sha256','');
          Screen:=TDPHScreenLayout.Reconstruct(FView,Source,False);
          try
            LayoutRows:=Screen.GetValue<TJSONArray>('components',nil);
            if (LayoutRows=nil) or (LayoutRows.Count=0) then Continue;
            TabNames:=TStringList.Create; TabCaptions:=TStringList.Create;
            try
              for Part in LayoutRows do begin
                Node:=Part as TJSONObject;
                if SameText(Node.GetValue<string>('class',''),'TTabItem') and
                  Node.GetValue<Boolean>('visible',True) then begin
                  TabNames.Add(Node.GetValue<string>('name',''));
                  TabCaptions.Add(Node.GetValue<string>('caption',''));
                end;
              end;
              if TabNames.Count>0 then begin
                TabNames.Insert(0,'');
                TabCaptions.Insert(0,'Main screen');
              end else begin TabNames.Add(''); TabCaptions.Add('Main screen'); end;
            FormText:='';
            FormPath:=TPath.GetFullPath(TPath.Combine(FView.Document.GetValue<string>('root',''),Source.Replace('/',PathDelim)));
            if StartsText(IncludeTrailingPathDelimiter(TPath.GetFullPath(FView.Document.GetValue<string>('root',''))),FormPath) and
              TFile.Exists(FormPath) and (TFile.GetSize(FormPath)<=16777216) and
              SameText(THashSHA2.GetHashStringFromFile(FormPath),Screen.GetValue<string>('source_hash','')) then
              FormText:=TFile.ReadAllText(FormPath,TEncoding.Default);
            for TabIndex:=0 to TabNames.Count-1 do begin
            TabName:=TabNames[TabIndex]; TabCaption:=TabCaptions[TabIndex];
            ActiveTabName:=TabName;
            if (ActiveTabName='') and (TabNames.Count>1) then ActiveTabName:=TabNames[1];
            Path:=TPath.Combine(ImageDirectory,THashSHA2.GetHashString(
              Source+'|'+SourceHash+'|screen-v8|'+CatalogHash+'|'+TabName)+'.png');
            Picture:=TBitmap.Create;
            try
            if not TFile.Exists(Path) then begin
            Node:=LayoutRows.Items[0] as TJSONObject;
            RootName:=Node.GetValue<string>('name','');
            W:=Round(EnsureRange(Node.GetValue<Double>('width',800),320.0,1600.0));
            H:=Round(EnsureRange(Node.GetValue<Double>('height',600),240.0,1000.0));
            Picture.SetSize(W,H);
              Picture.Clear(ScreenBackgroundStyle.Fill.Color);
              Scale:=Min(W/Max(Node.GetValue<Double>('width',800),1),H/Max(Node.GetValue<Double>('height',600),1));
              MenuX:=14*Scale;
              if Picture.Canvas.BeginScene then try
                Picture.Canvas.Font.Family:='Segoe UI';
                Picture.Canvas.Stroke.Thickness:=1;
                for Part in LayoutRows do begin
                  Node:=Part as TJSONObject; ClassName:=LowerCase(Node.GetValue<string>('class',''));
                  if not Node.GetValue<Boolean>('visible',True) or
                    ((ActiveTabName<>'') and (Node.GetValue<string>('tab_owner','')<>'') and
                     not SameText(Node.GetValue<string>('tab_owner',''),ActiveTabName)) or
                    (ClassName='') or
                    (ClassName='ttabitem') or (ClassName='ttabcontrol') or
                    (ClassName='ttimer') or (ClassName='tdatasource') or
                    (ClassName='timagelist') or (ClassName='topendialog') or
                    StartsText('tfd',ClassName) or StartsText('tid',ClassName) or
                    EndsText('field',ClassName) or
                    ContainsText(ClassName,'binding') then Continue;
                  Bounds:=TRectF.Create((Node.GetValue<Double>('x')-Node.GetValue<Double>('tab_shift_x',0))*Scale,
                    (Node.GetValue<Double>('y')-Node.GetValue<Double>('tab_shift_y',0))*Scale,
                    (Node.GetValue<Double>('x')-Node.GetValue<Double>('tab_shift_x',0)+Node.GetValue<Double>('width'))*Scale,
                    (Node.GetValue<Double>('y')-Node.GetValue<Double>('tab_shift_y',0)+Node.GetValue<Double>('height'))*Scale);
                  if (Bounds.Width<3) or (Bounds.Height<3) then Continue;
                  if Part=LayoutRows.Items[0] then Continue;
                  if ClassName='tmenuitem' then begin
                    if SameText(Node.GetValue<string>('parent_class',''),'TMenuBar') then begin
                      CaptionText:=Node.GetValue<string>('caption','');
                      if GermanStrings<>nil then
                        CaptionText:=GermanStrings.GetValue<string>(RootName+'.'+
                          Node.GetValue<string>('name','')+'.Text',CaptionText);
                      Picture.Canvas.Font.Size:=14*Scale;
                      Picture.Canvas.Fill.Color:=$FF20364A;
                      Bounds:=RectF(MenuX,0,MenuX+Max(70*Scale,Length(CaptionText)*9*Scale),28*Scale);
                      Picture.Canvas.FillText(Bounds,CaptionText,True,1,[],TTextAlign.Center,TTextAlign.Center);
                      MenuX:=Bounds.Right+4*Scale;
                    end;
                    Continue;
                  end;
                  Picture.Canvas.Font.Size:=EnsureRange(Node.GetValue<Double>('font_size',14),8.0,72.0)*Scale;
                  Picture.Canvas.Fill.Color:=$FF20364A;
                  ColorText:=Node.GetValue<string>('font_color','');
                  if (Length(ColorText)=9) and (ColorText[1]='x') then
                    Picture.Canvas.Fill.Color:=TAlphaColor(StrToInt64Def('$'+Copy(ColorText,2,8),$FF20364A))
                  else if SameText(ColorText,'claMaroon') then Picture.Canvas.Fill.Color:=TAlphaColors.Maroon
                  else if SameText(ColorText,'claBlack') then Picture.Canvas.Fill.Color:=TAlphaColors.Black
                  // The blank design uses a light surface even when a runtime style
                  // supplies the dark background intended for white text.
                  else if SameText(ColorText,'claWhite') then Picture.Canvas.Fill.Color:=$FF20364A;
                  TextColor:=Picture.Canvas.Fill.Color;
                  if ContainsText(ClassName,'label') or (ClassName='ttext') then begin
                    // A label is text on the parent surface, not a button-shaped box.
                  end else if ContainsText(ClassName,'checkbox') or ContainsText(ClassName,'radiobutton') then begin
                    Picture.Canvas.Fill.Color:=TAlphaColors.White;
                    Picture.Canvas.FillRect(RectF(Bounds.Left+2,Bounds.CenterPoint.Y-8*Scale,
                      Bounds.Left+18*Scale,Bounds.CenterPoint.Y+8*Scale),2,2,AllCorners,1);
                    Picture.Canvas.Stroke.Color:=$FF687C8F;
                    Picture.Canvas.DrawRect(RectF(Bounds.Left+2,Bounds.CenterPoint.Y-8*Scale,
                      Bounds.Left+18*Scale,Bounds.CenterPoint.Y+8*Scale),2,2,AllCorners,1);
                    Bounds.Left:=Bounds.Left+24*Scale;
                  end else if ContainsText(ClassName,'navigator') then begin
                    NavigatorButtons:=Node.GetValue<string>('navigator_buttons','').Replace('[','').Replace(']','')
                      .Split([','],TStringSplitOptions.ExcludeEmpty);
                    if Length(NavigatorButtons)=0 then NavigatorButtons:=['Navigator'];
                    for NavigatorIndex:=0 to High(NavigatorButtons) do begin
                      NavigatorLabel:=Trim(NavigatorButtons[NavigatorIndex]);
                      if SameText(NavigatorLabel,'nbInsert') then NavigatorLabel:='Add'
                      else if SameText(NavigatorLabel,'nbDelete') then NavigatorLabel:='Delete'
                      else if SameText(NavigatorLabel,'nbPost') then NavigatorLabel:='Save'
                      else if SameText(NavigatorLabel,'nbCancel') then NavigatorLabel:='Cancel'
                      else if SameText(NavigatorLabel,'nbFirst') then NavigatorLabel:='First'
                      else if SameText(NavigatorLabel,'nbPrior') then NavigatorLabel:='Previous'
                      else if SameText(NavigatorLabel,'nbNext') then NavigatorLabel:='Next'
                      else if SameText(NavigatorLabel,'nbLast') then NavigatorLabel:='Last'
                      else if SameText(NavigatorLabel,'nbEdit') then NavigatorLabel:='Edit'
                      else if SameText(NavigatorLabel,'nbRefresh') then NavigatorLabel:='Refresh';
                      NavigatorBounds:=RectF(Bounds.Left+Bounds.Width*NavigatorIndex/Length(NavigatorButtons),
                        Bounds.Top,Bounds.Left+Bounds.Width*(NavigatorIndex+1)/Length(NavigatorButtons),Bounds.Bottom);
                      Picture.Canvas.Fill.Color:=$FFF1F5F8;
                      Picture.Canvas.FillRect(NavigatorBounds,4*Scale,4*Scale,AllCorners,1);
                      Picture.Canvas.Stroke.Color:=$FF92B3CC;
                      Picture.Canvas.DrawRect(NavigatorBounds,4*Scale,4*Scale,AllCorners,1);
                      Picture.Canvas.Font.Size:=Min(12*Scale,Max(8*Scale,
                        (NavigatorBounds.Width-8*Scale)/Max(Length(NavigatorLabel)*0.55,1)));
                      Picture.Canvas.Fill.Color:=$FF20364A;
                      Picture.Canvas.FillText(NavigatorBounds,NavigatorLabel,True,1,[],TTextAlign.Center,TTextAlign.Center);
                    end;
                    Continue;
                  end else if ContainsText(ClassName,'image') then begin
                    if FormText<>'' then begin
                      ImageStart:=Pos('object '+Node.GetValue<string>('name','')+':',FormText);
                      if ImageStart=0 then ImageStart:=Pos('inherited '+Node.GetValue<string>('name','')+':',FormText);
                      if ImageStart>0 then begin
                        NextObject:=PosEx(#10+'  object ',FormText,ImageStart+1);
                        ImageStart:=PosEx('PNG = {',FormText,ImageStart);
                        if (ImageStart>0) and ((NextObject=0) or (ImageStart<NextObject)) then begin
                          ImageStart:=ImageStart+Length('PNG = {');
                          ImageEnd:=PosEx('}',FormText,ImageStart);
                          if (ImageEnd>ImageStart) and (ImageEnd-ImageStart<=16000000) then begin
                            SetLength(ImageBytes,(ImageEnd-ImageStart) div 2);
                            ByteCount:=0; HighNibble:=-1;
                            for CharacterIndex:=ImageStart to ImageEnd-1 do begin
                              ImageCharacter:=UpCase(FormText[CharacterIndex]); Nibble:=-1;
                              if CharInSet(ImageCharacter,['0'..'9']) then Nibble:=Ord(ImageCharacter)-Ord('0')
                              else if CharInSet(ImageCharacter,['A'..'F']) then Nibble:=Ord(ImageCharacter)-Ord('A')+10;
                              if Nibble<0 then Continue;
                              if HighNibble<0 then HighNibble:=Nibble
                              else begin
                                if ByteCount>=Length(ImageBytes) then Break;
                                ImageBytes[ByteCount]:=Byte(HighNibble*16+Nibble);
                                Inc(ByteCount); HighNibble:=-1;
                              end;
                            end;
                            if (ByteCount>8) and (ImageBytes[0]=$89) and (ImageBytes[1]=$50) and
                              (ImageBytes[2]=$4E) and (ImageBytes[3]=$47) then begin
                              ImageStream:=TMemoryStream.Create; EmbeddedPicture:=TBitmap.Create;
                              try
                                ImageStream.WriteBuffer(ImageBytes[0],ByteCount);
                                ImageStream.Position:=0;
                                EmbeddedPicture.LoadFromStream(ImageStream);
                                Picture.Canvas.DrawBitmap(EmbeddedPicture,
                                  RectF(0,0,EmbeddedPicture.Width,EmbeddedPicture.Height),Bounds,1,True);
                              finally EmbeddedPicture.Free; ImageStream.Free; end;
                            end;
                          end;
                        end;
                      end;
                    end;
                    Continue;
                  end else if ContainsText(ClassName,'layout') then begin
                    Continue;
                  end else begin
                    Picture.Canvas.Fill.Color:=TAlphaColors.White;
                    if ContainsText(ClassName,'button') or ContainsText(ClassName,'navigator') then
                      Picture.Canvas.Fill.Color:=$FFF1F5F8;
                    if ContainsText(ClassName,'panel') or ContainsText(ClassName,'groupbox') or
                      ContainsText(ClassName,'rectangle') then Picture.Canvas.Fill.Color:=$FFF7F9FB;
                    ColorText:=Node.GetValue<string>('fill_color','');
                    if (Length(ColorText)=9) and (ColorText[1]='x') then
                      Picture.Canvas.Fill.Color:=TAlphaColor(StrToInt64Def('$'+Copy(ColorText,2,8),$FFFFFFFF))
                    else if SameText(ColorText,'claNavy') then Picture.Canvas.Fill.Color:=TAlphaColors.Navy
                    else if SameText(ColorText,'claSkyblue') then Picture.Canvas.Fill.Color:=TAlphaColors.Skyblue
                    else if SameText(ColorText,'claCornflowerblue') then Picture.Canvas.Fill.Color:=TAlphaColors.Cornflowerblue
                    else if SameText(ColorText,'claDarkorange') then Picture.Canvas.Fill.Color:=TAlphaColors.Darkorange
                    else if SameText(ColorText,'claGold') then Picture.Canvas.Fill.Color:=TAlphaColors.Gold
                    else if SameText(ColorText,'claGoldenrod') then Picture.Canvas.Fill.Color:=TAlphaColors.Goldenrod
                    else if SameText(ColorText,'claKhaki') then Picture.Canvas.Fill.Color:=TAlphaColors.Khaki
                    else if SameText(ColorText,'claSlateblue') then Picture.Canvas.Fill.Color:=TAlphaColors.Slateblue
                    else if SameText(ColorText,'claWhite') then Picture.Canvas.Fill.Color:=TAlphaColors.White;
                    if ClassName='tcircle' then Picture.Canvas.FillEllipse(Bounds,1)
                    else if ContainsText(ClassName,'button') then Picture.Canvas.FillRect(Bounds,6*Scale,6*Scale,AllCorners,1)
                    else Picture.Canvas.FillRect(Bounds,3,3,AllCorners,1);
                    Picture.Canvas.Stroke.Color:=$FF92B3CC;
                    if ClassName='tcircle' then Picture.Canvas.DrawEllipse(Bounds,1)
                    else if ContainsText(ClassName,'button') then Picture.Canvas.DrawRect(Bounds,6*Scale,6*Scale,AllCorners,1)
                    else Picture.Canvas.DrawRect(Bounds,3,3,AllCorners,1);
                  end;
                  Picture.Canvas.Fill.Color:=TextColor;
                  CaptionText:=Node.GetValue<string>('caption','').Trim(['''',' ']).Replace('''''','''');
                  if GermanStrings<>nil then begin
                    CaptionKey:=RootName+'.'+Node.GetValue<string>('name','');
                    CaptionText:=GermanStrings.GetValue<string>(CaptionKey+'.Text',
                      GermanStrings.GetValue<string>(CaptionKey+'.Caption',CaptionText));
                  end;
                  if ContainsText(ClassName,'edit') or ContainsText(ClassName,'memo') or
                    ContainsText(ClassName,'list') or ContainsText(ClassName,'grid') then CaptionText:='';
                  if CaptionText<>'' then begin
                    if ContainsText(ClassName,'label') or (ClassName='ttext') then
                      Bounds.Inflate(0,3*Scale)
                    else
                      Bounds.Inflate(-4*Scale,-1*Scale);
                    if SameText(Node.GetValue<string>('horizontal_alignment',''),'Trailing') then
                      Picture.Canvas.FillText(Bounds,Copy(CaptionText,1,120),True,1,[],TTextAlign.Trailing,TTextAlign.Center)
                    else if SameText(Node.GetValue<string>('horizontal_alignment',''),'Center') or
                      ContainsText(ClassName,'button') then
                      Picture.Canvas.FillText(Bounds,Copy(CaptionText,1,120),True,1,[],TTextAlign.Center,TTextAlign.Center)
                    else Picture.Canvas.FillText(Bounds,Copy(CaptionText,1,120),True,1,[],TTextAlign.Leading,TTextAlign.Center);
                  end;
                end;
              finally Picture.Canvas.EndScene; end;
              Picture.SaveToFile(Path);
            end else Picture.LoadFromFile(Path);
              ImageHash:=THashSHA2.GetHashStringFromFile(Path);
              if (TabName='') and (Seen.IndexOf('image:'+ImageHash)>=0) then begin
                for Index:=0 to FImages.Count-1 do begin
                  R:=FImages.Items[Index] as TJSONObject;
                  if SameText(R.GetValue<string>('image_sha256',''),ImageHash) then begin
                    R.GetValue<TJSONArray>('form_sources').Add(Source); Break;
                  end;
                end;
                Continue;
              end;
              Seen.Add('image:'+ImageHash);
              FormSources:=TJSONArray.Create; FormSources.Add(Source);
              if (TabName<>'') and (TabCaption='') then TabCaption:=TabName;
              R:=TJSONObject.Create.AddPair('artifact_id',TJSONNumber.Create(-(Done*1000+TabIndex+1)))
                .AddPair('generation_id',TJSONNumber.Create(FView.Document.GetValue<Int64>('generation_id')))
                .AddPair('caption',TPath.GetFileNameWithoutExtension(Source)+' - '+TabCaption)
                .AddPair('description','Reconstructed design preview from '+Source+', '+TabCaption+'. Saved controls and captions are shown; runtime styling and data may differ.')
                .AddPair('image_kind','Generated design preview').AddPair('managed_path',Path)
                .AddPair('form_sources',FormSources)
                .AddPair('image_sha256',ImageHash);
              FImages.AddElement(R);
              Index:=ScreenshotList.Items.Add(R.GetValue<string>('caption'));
              Thumbnail:=TBitmap.Create;
              try Thumbnail.Assign(Picture); Thumbnail.Resize(128,96); ScreenshotList.ListItems[Index].ItemData.Bitmap.Assign(Thumbnail);
              finally Thumbnail.Free; end;
          finally
            Picture.Free;
            if FPreparingProject then begin
              if WasBusy then
                ProjectPreparationProgress.Value:=Max(ProjectPreparationProgress.Value,10+Round(10*Done/Max(Count,1)))
              else
                ProjectPreparationProgress.Value:=Max(ProjectPreparationProgress.Value,80+Round(18*Done/Max(Count,1)));
              ProjectPreparationMessage.Text:=DATFormatText(
                'DPH.UI.Main.Runtime.ProjectPreparationMessage_Text.Text.b907fb4fd5f67390',
                'Preparing screen previews: %d of %d complete; %d remaining.',
                [Done,Count,Count-Done]);
              ProjectPreparationPercent.Text:=Format('%d%%',[Round(ProjectPreparationProgress.Value)]);
              ProjectPreparationMessage.Repaint; ProjectPreparationProgress.Repaint;
              ProjectPreparationPercent.Repaint;
              Application.ProcessMessages;
            end;
          end;
            end;
            finally TabCaptions.Free; TabNames.Free; end;
          finally Screen.Free; end;
        end;
      finally Seen.Free; end;
    end;
  end;
  if ARows<>nil then for V in ARows do begin
    R:=V as TJSONObject;
    if (R.GetValue<string>('managed_path','')='') or
      (R.GetValue<string>('image_sha256','')='') then Continue;
    FImages.AddElement(R.Clone as TJSONObject);
    Index:=ScreenshotList.Items.Add(R.GetValue<string>('caption','Imported screenshot'));
    Thumbnail:=TBitmap.Create;
    try
      Thumbnail.LoadFromFile(R.GetValue<string>('managed_path'));
      Thumbnail.Resize(128,96);
      ScreenshotList.ListItems[Index].ItemData.Bitmap.Assign(Thumbnail);
    finally Thumbnail.Free; end;
  end;
  ScreenshotEvidence.Text:='Select a generated form preview or an imported runtime screenshot.';
  ScreenshotImage.Bitmap.SetSize(0,0);
  if ScreenshotList.Count>0 then begin ScreenshotList.ItemIndex:=0; ScreenshotClick(nil); end;
  finally
    FBusy:=WasBusy; WorkspaceTabs.Enabled:=WasTabsEnabled; PollTimer.Enabled:=WasTimerEnabled;
    FRenderingScreens:=False;
    GermanCatalog.Free;
    ARows.Free;
  end;
end;
procedure TDPHMainForm.ScreenshotClick(Sender: TObject);
var R,Card,Picture:TJSONObject;V:TJSONValue;Path,Source:string;Sources:TJSONArray;Number:Integer;
begin
  FPicturePointValid:=False;ScreenshotCallout.Enabled:=False;
  if (FImages=nil) or (ScreenshotList.ItemIndex<0) then Exit;
  R:=FImages.Items[ScreenshotList.ItemIndex] as TJSONObject; Path:=R.GetValue<string>('managed_path');
  try
    if THashSHA2.GetHashStringFromFile(Path)<>R.GetValue<string>('image_sha256') then raise EReadError.Create('Screenshot changed after validation');
    ScreenshotImage.Bitmap.LoadFromFile(Path); UpdateScreenshotBounds;
    if R.GetValue<Int64>('artifact_id',0)<0 then begin
      Sources:=R.GetValue<TJSONArray>('form_sources',nil);
      Source:='';
      if (Sources<>nil) and (Sources.Count>0) then Source:=Sources.Items[0].Value;
      ScreenshotEvidence.Text:=R.GetValue<string>('caption')+' ('+Source+')';
    end
    else
      ScreenshotEvidence.Text:=R.GetValue<string>('caption')+sLineBreak+
        R.GetValue<string>('description','');
    Number:=0;
    if FKnowledge<>nil then for V in FKnowledge do begin
      if MatchText(V.GetValue<string>('state',''),['retired','rejected']) then Continue;
      Card:=TJSONObject.ParseJSONValue(V.GetValue<string>('structured_json','{}')) as TJSONObject;
      try
        if Card=nil then Continue;Picture:=Card.GetValue<TJSONObject>('picture',nil);
        if (Picture=nil) or (Picture.GetValue<string>('image_sha256')<>R.GetValue<string>('image_sha256')) then Continue;
        Inc(Number);ScreenshotEvidence.Lines.Add(IntToStr(Number)+'. '+
          V.GetValue<string>('title')+': '+Card.GetValue<string>('fields.meaning')+
          ' ('+V.GetValue<string>('owner')+')');
      finally Card.Free;end;
    end;
    ScreenshotMarkers.Repaint;
  except on E: Exception do begin ScreenshotImage.Bitmap.Clear(TAlphaColors.Null); ScreenshotEvidence.Text:='Image unavailable: '+E.Message; end; end;
end;
procedure TDPHMainForm.ScreenshotPoint(Sender:TObject;Button:TMouseButton;Shift:TShiftState;X,Y:Single);
begin
 if (Button<>TMouseButton.mbLeft) or ScreenshotImage.Bitmap.IsEmpty or (ScreenshotImage.Width<=0) or (ScreenshotImage.Height<=0) then Exit;
  if not ScreenshotCallout.Visible then Exit;
 FPictureX:=EnsureRange(Round(X/ScreenshotImage.Width*10000),0,10000);FPictureY:=EnsureRange(Round(Y/ScreenshotImage.Height*10000),0,10000);
 FPicturePointValid:=True;ScreenshotCallout.Enabled:=True;ScreenshotMarkers.Repaint;
 StatusLabel.Text:='Point selected. Choose Explain this point to add its meaning, example and practice question.';
end;
procedure TDPHMainForm.ScreenshotCalloutClick(Sender:TObject);
var Image:TJSONObject;
begin
 if not FPicturePointValid or (FImages=nil) or (ScreenshotList.ItemIndex<0) then Exit;
 Image:=FImages.Items[ScreenshotList.ItemIndex] as TJSONObject;
 CardEditClick(CardNew);if (FCardDraft=nil) or (WorkspaceTabs.ActiveTab<>CardEditorTab) then Exit;
 FCardDraft.AddPair('picture',TJSONObject.Create.AddPair('image_sha256',Image.GetValue<string>('image_sha256')).AddPair('x',TJSONNumber.Create(FPictureX)).AddPair('y',TJSONNumber.Create(FPictureY)));
 if Image.GetValue<string>('image_kind','Screenshot')='Sample output' then CardCategory.ItemIndex:=CardCategory.Items.IndexOf('Output or report');
 if FView.Symbol(Image.GetValue<string>('entity_key',''))<>nil then FKnowledgeLink:=Image.GetValue<string>('entity_key');
 Card_example.Text:='Unknown';
end;
procedure TDPHMainForm.ScreenshotMarkerPaint(Sender:TObject;Canvas:TCanvas);
var V:TJSONValue;Card,Picture,Image:TJSONObject;Number:Integer;X,Y,Radius:Single;Bounds:TRectF;
begin
 if (FImages=nil) or (ScreenshotList.ItemIndex<0) or (ScreenshotList.ItemIndex>=FImages.Count) or ScreenshotImage.Bitmap.IsEmpty then Exit;
 Image:=FImages.Items[ScreenshotList.ItemIndex] as TJSONObject;Number:=0;Radius:=ScreenshotMarkerStyle.Width/2;
 if (ScreenshotMarkers.Width<Radius*2) or (ScreenshotMarkers.Height<Radius*2) then Exit;
 Canvas.Font.Assign(ScreenshotMarkerText.TextSettings.Font);
 if FKnowledge<>nil then for V in FKnowledge do begin
  if MatchText(V.GetValue<string>('state',''),['retired','rejected']) then Continue;
  Card:=TJSONObject.ParseJSONValue(V.GetValue<string>('structured_json','{}')) as TJSONObject;
  try
   if Card=nil then Continue;Picture:=Card.GetValue<TJSONObject>('picture',nil);
   if (Picture=nil) or (Picture.GetValue<string>('image_sha256')<>Image.GetValue<string>('image_sha256')) then Continue;
   Inc(Number);X:=EnsureRange(Picture.GetValue<Integer>('x')/10000*ScreenshotMarkers.Width,Radius,ScreenshotMarkers.Width-Radius);Y:=EnsureRange(Picture.GetValue<Integer>('y')/10000*ScreenshotMarkers.Height,Radius,ScreenshotMarkers.Height-Radius);
   Bounds:=TRectF.Create(X-Radius,Y-Radius,X+Radius,Y+Radius);Canvas.Fill.Assign(ScreenshotMarkerStyle.Fill);Canvas.FillEllipse(Bounds,1);Canvas.Stroke.Assign(ScreenshotMarkerStyle.Stroke);Canvas.DrawEllipse(Bounds,1);
   Canvas.Fill.Color:=ScreenshotMarkerText.TextSettings.FontColor;Canvas.FillText(Bounds,IntToStr(Number),False,1,[],TTextAlign.Center,TTextAlign.Center);
  finally Card.Free;end;
 end;
 if FPicturePointValid then begin
  X:=EnsureRange(FPictureX/10000*ScreenshotMarkers.Width,Radius,ScreenshotMarkers.Width-Radius);Y:=EnsureRange(FPictureY/10000*ScreenshotMarkers.Height,Radius,ScreenshotMarkers.Height-Radius);
  Bounds:=TRectF.Create(X-Radius,Y-Radius,X+Radius,Y+Radius);Canvas.Stroke.Assign(ScreenshotMarkerStyle.Stroke);Canvas.DrawEllipse(Bounds,1);
 end;
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
 if FDatabaseER.GetValue<Integer>('shown_tables')=0 then DatabaseERMemo.Lines.Add(DATTranslateText('DPH.UI.Main.Memo.e5e257999e0ea550', 'No matching captured tables. Clear the text filter, click All tables, or attach approved SQL resources and reassess.'));
 if FDatabaseERFocusID<>'' then DatabaseERMemo.Lines.Add(DATTranslateText('DPH.UI.Main.Memo.bb4d7a293124e950', 'Focus includes the selected captured table and its directly linked neighbors; the text filter still applies.'));
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
 if FDatabaseERFocusID='' then DatabaseERMemo.Lines.Add(DATTranslateText('DPH.UI.Main.Memo.a54da8ef01305315', 'No captured table/column/key selected in Database schema; showing all captured tables.'));
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
 DatabaseERMemo.Lines.Add(DATTranslateText('DPH.UI.Main.Memo.ee6950f42e02622c', 'Evidence target is no longer in this captured schema. Rebuild the diagram.'));
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
 FileFormatsMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.ba076c5be07a6cfc', 'Select a captured file or API candidate. Empty results do not prove there are no import/export formats; unsupported, dynamic and uncaptured transfers remain unknown.');
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
 if FDetached then begin FileFormatsMemo.Lines.Add(DATTranslateText('DPH.UI.Main.Memo.08ca6e511f32b2d0', 'Source is detached. Attach unchanged source to navigate.'));Exit;end;
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

procedure TDPHMainForm.CalculationEvidenceOpenClick(Sender:TObject);
begin WorkspaceTabs.ActiveTab:=CalculationEvidenceTab;end;
procedure TDPHMainForm.CalculationEvidenceFilterChange(Sender:TObject);
var V:TJSONValue;Row:TJSONObject;Count:Integer;
begin
 if FCalculationEvidenceRows=nil then Exit;
 if Sender=CalculationEvidenceNext then Inc(FCalculationEvidenceOffset,250) else FCalculationEvidenceOffset:=0;
 FCalculationEvidenceRows.Clear;CalculationEvidenceList.Items.Clear;CalculationEvidenceNext.Enabled:=False;CalculationEvidenceSelectionChange(nil);
 if FCalculationEvidence=nil then begin CalculationEvidenceStatus.Text:='Open a captured project to inspect calculation candidates.';Exit;end;
 Count:=0;
 for V in FCalculationEvidence.GetValue<TJSONArray>('rows') do begin Row:=V as TJSONObject;
  if (CalculationEvidenceFilter.Text.Trim<>'') and not ContainsText(TDPHWorkspaceView.DescribeCalculationEvidence(Row),CalculationEvidenceFilter.Text.Trim) then Continue;
  if (Count>=FCalculationEvidenceOffset) and (FCalculationEvidenceRows.Count<250) then begin FCalculationEvidenceRows.Add(Row);CalculationEvidenceList.Items.Add(Row.GetValue<string>('source')+':'+Row.GetValue<Integer>('range.line').ToString+' | '+Row.GetValue<string>('expression'));end;Inc(Count);
 end;
 CalculationEvidenceNext.Enabled:=Count>FCalculationEvidenceOffset+FCalculationEvidenceRows.Count;
 CalculationEvidenceStatus.Text:=Format('%d matches; %d shown from %d. %d empty/long expressions unavailable. %s',[Count,FCalculationEvidenceRows.Count,FCalculationEvidenceOffset,FCalculationEvidence.GetValue<Integer>('unavailable_expressions'),FCalculationEvidence.GetValue<string>('limit','')]);
 if CalculationEvidenceList.Count>0 then CalculationEvidenceList.ItemIndex:=0;CalculationEvidenceSelectionChange(nil);
end;
procedure TDPHMainForm.CalculationEvidenceSelectionChange(Sender:TObject);
var Row:TJSONObject;
begin
 Row:=nil;if (FCalculationEvidenceRows<>nil) and (CalculationEvidenceList.ItemIndex>=0) and (CalculationEvidenceList.ItemIndex<FCalculationEvidenceRows.Count) then Row:=FCalculationEvidenceRows[CalculationEvidenceList.ItemIndex];
 CalculationEvidenceSource.Enabled:=Row<>nil;CalculationEvidenceDefine.Enabled:=Row<>nil;CalculationEvidenceExplain.Enabled:=False;
 if Row<>nil then CalculationEvidenceExplain.Enabled:=Row.GetValue<string>('target_key','')<>'';
 CalculationEvidenceMemo.Text:=TDPHWorkspaceView.DescribeCalculationEvidence(Row);
 if (Row<>nil) and (FCalculationEvidence<>nil) then CalculationEvidenceMemo.Lines.Add(FCalculationEvidence.GetValue<string>('qualification'));
end;
procedure TDPHMainForm.CalculationEvidenceSourceClick(Sender:TObject);
var Row,Range:TJSONObject;
begin
 if (FView=nil) or (CalculationEvidenceList.ItemIndex<0) or (CalculationEvidenceList.ItemIndex>=FCalculationEvidenceRows.Count) then Exit;
 Row:=FCalculationEvidenceRows[CalculationEvidenceList.ItemIndex];Range:=Row.GetValue<TJSONObject>('range');
 if FDetached then begin CalculationEvidenceMemo.Lines.Add(DATTranslateText('DPH.UI.Main.Memo.08ca6e511f32b2d0', 'Source is detached. Attach unchanged source to navigate.'));Exit;end;
 try SourceMemo.Text:=TDPHKeyboardInspector.ReadSource(FView,FEntry,Row,Range);SourceMemo.CaretPosition:=TCaretPosition.Create(Max(0,Range.GetValue<Integer>('line')-1),0);WorkspaceTabs.ActiveTab:=SourceTab;
 except on E:Exception do CalculationEvidenceMemo.Lines.Add('Source unavailable: '+E.Message);end;
end;
procedure TDPHMainForm.CalculationEvidenceExplainClick(Sender:TObject);
var Key:string;
begin
 if (FView=nil) or (CalculationEvidenceList.ItemIndex<0) or (CalculationEvidenceList.ItemIndex>=FCalculationEvidenceRows.Count) then Exit;
 Key:=FCalculationEvidenceRows[CalculationEvidenceList.ItemIndex].GetValue<string>('target_key');if Key='' then Exit;SelectSymbol(Key);WorkspaceTabs.ActiveTab:=ExplainTab;
end;
procedure TDPHMainForm.CalculationEvidenceDefineClick(Sender:TObject);
var Row:TJSONObject;
begin
 if FBusy or (FView=nil) then Exit;
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft before defining a calculation.';Exit;end;
 if (CalculationEvidenceList.ItemIndex<0) or (CalculationEvidenceList.ItemIndex>=FCalculationEvidenceRows.Count) then Exit;
 Row:=FCalculationEvidenceRows[CalculationEvidenceList.ItemIndex];CalculationNewClick(nil);
 if WorkspaceTabs.ActiveTab<>CalculationEditorTab then Exit;
 Calc_formula.Text:=Row.GetValue<string>('expression');Calc_assumptions.Text:='Captured expression candidate with original literals omitted: '+Row.GetValue<string>('source')+':'+Row.GetValue<Integer>('range.line').ToString+' | SHA256 '+Row.GetValue<string>('source_hash')+' | generation '+Row.GetValue('generation_id').Value+'. Verify against source and attach exact implementation links; business meaning, units and runtime values remain unknown.';
 StatusLabel.Text:='Name the calculation and contributor, define meaning, inputs, outputs and units. Apply then Save; add exact implementation links and review. Captured formula text is not evaluated.';
end;

procedure TDPHMainForm.CalculationFilterChange(Sender:TObject);
var V:TJSONValue;Row:TJSONObject;Count:Integer;Query,StateFilter:string;
begin
 if FCalculationRows=nil then Exit;
 if Sender=CalculationNext then Inc(FCalculationOffset,250) else FCalculationOffset:=0;
 FCalculationRows.Clear;CalculationList.Items.Clear;CalculationNext.Enabled:=False;CalculationNew.Enabled:=FView<>nil;
 CalculationSelectionChange(nil);
 if (FView=nil) or (FKnowledge=nil) then begin CalculationStatus.Text:='Open a captured project, then New calculation to record its business calculation.';Exit;end;
 Query:=CalculationFilter.Text.Trim;StateFilter:='';if CalculationState.ItemIndex>0 then StateFilter:=CalculationState.Selected.Text;Count:=0;
 for V in FKnowledge do begin Row:=V as TJSONObject;
  if not TDPHWorkspaceView.IsCalculation(Row) then Continue;
  if (StateFilter<>'') and (Row.GetValue<string>('state')<>StateFilter) then Continue;
  if (Query<>'') and not ContainsText(TDPHWorkspaceView.DescribeCalculation(Row),Query) then Continue;
  if (Count>=FCalculationOffset) and (FCalculationRows.Count<250) then begin
   FCalculationRows.Add(Row);CalculationList.Items.Add('['+Row.GetValue<string>('state')+'] '+Row.GetValue<string>('title')+' | '+Row.GetValue<string>('owner'));
  end;Inc(Count);
 end;
 CalculationNext.Enabled:=Count>FCalculationOffset+FCalculationRows.Count;
 CalculationStatus.Text:=IntToStr(Count)+' saved calculations match; '+IntToStr(FCalculationRows.Count)+' shown from '+IntToStr(FCalculationOffset)+'. Review state is a human assessment; unknown fields remain unresolved.';
 if CalculationList.Count>0 then CalculationList.ItemIndex:=0;
 CalculationSelectionChange(nil);
end;
procedure TDPHMainForm.CalculationSelectionChange(Sender:TObject);
var Row:TJSONObject;
begin
 Row:=nil;if (FCalculationRows<>nil) and (CalculationList.ItemIndex>=0) and (CalculationList.ItemIndex<FCalculationRows.Count) then Row:=FCalculationRows[CalculationList.ItemIndex];
 CalculationEdit.Enabled:=Row<>nil;CalculationOpen.Enabled:=Row<>nil;CalculationLinks.Enabled:=Row<>nil;
 CalculationMemo.Text:=TDPHWorkspaceView.DescribeCalculation(Row);
end;
procedure TDPHMainForm.CalculationNewClick(Sender:TObject);
begin CalculationEditClick(CalculationNew);end;
procedure TDPHMainForm.CalculationOpenClick(Sender:TObject);
var Row:TJSONObject;ID:string;I:Integer;
begin
 if FBusy or (FView=nil) then Exit;
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft before opening another calculation.';Exit;end;
 if (CalculationList.ItemIndex<0) or (CalculationList.ItemIndex>=FCalculationRows.Count) then Exit;
 Row:=FCalculationRows[CalculationList.ItemIndex];ID:=Row.GetValue<string>('id');
 PendingKnowledgeCheck.IsChecked:=False;KnowledgeFilterChange(nil);
 for I:=0 to FKnowledgeRows.Count-1 do if FKnowledgeRows[I].GetValue<string>('id')=ID then begin
  KnowledgeList.ItemIndex:=I;KnowledgeClick(nil);WorkspaceTabs.ActiveTab:=KnowledgeTab;
  if Sender=CalculationLinks then begin WorkspaceTabs.ActiveTab:=KnowledgeLinksTab;StatusLabel.Text:='Select a saved link and Open target, or search a captured routine/procedure and Add link. Return to Knowledge and Save edits.';end;
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
var Row:TJSONObject;HTML,GraphPath:string;GraphExplanation:TDPHExplanationModel;
begin
 if FBusy or (FView=nil) then Exit;
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft before opening a saved workflow diagram.';Exit;end;
 if (DepartmentalWorkflowList.ItemIndex<0) or (DepartmentalWorkflowList.ItemIndex>=FDepartmentalWorkflowRows.Count) then Exit;
 Row:=FDepartmentalWorkflowRows[DepartmentalWorkflowList.ItemIndex];
 try
  GraphCombo.ItemIndex:=7;
  FreeAndNil(FGraph);FGraph:=TDPHGraphProjection.Workflow(Row,FKnowledge,FView.Document.GetValue<Int64>('generation_id'));
  GraphGroupingCombo.Enabled:=False;
  GraphLegend.Text:='Authored business workflow | blue: normal sequence | orange: exception routes | select steps for details | exact process links retain revision review; runtime unobserved';
  GraphPaint.Height:=Max(4500,FGraph.GetValue<TJSONArray>('nodes').Count*190+40);
  GraphExplanation:=TDPHExplanationModel.Create(FLearningFacts.Document,False);
  try HTML:=DATTranslateHtmlText(GraphExplanation.GraphHTML(FGraph));finally GraphExplanation.Free;end;
  GraphPath:=TPath.Combine(FFlowDirectory,THashSHA2.GetHashString(HTML)+'.html');
  if not FPreviewPages.Contains(GraphPath) then begin TFile.WriteAllBytes(GraphPath,TEncoding.UTF8.GetBytes(HTML));FPreviewPages.Add(GraphPath);end;
  WorkspaceTabs.ActiveTab:=GraphTab;FlowBrowser.Visible:=False;GraphScroll.Visible:=False;
  try FExpectedGraphPage:=TPath.GetFileName(GraphPath);
    FlowBrowser.WindowsEngine:=TWindowsEngine.EdgeOnly;FlowBrowser.Navigate('file://'+GraphPath);
  except on E:Exception do begin GraphScroll.Visible:=True;GraphPaint.Repaint;
    StatusLabel.Text:='Browser diagram unavailable; the native diagram remains available: '+E.Message;end;end;
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

procedure TDPHMainForm.CalculationEditClick(Sender:TObject);
var RecordValue,Fields:TJSONObject;Key:string;
begin
 if FBusy or (FView=nil) then Exit;
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft before editing a calculation.';Exit;end;
 if Sender=CalculationNew then begin NewKnowledgeClick(nil);RecordValue:=TDPHWorkspaceView.NewCalculation;end
 else begin
  if CalculationList.ItemIndex<0 then Exit;
  CalculationOpenClick(nil);
  RecordValue:=TJSONObject.ParseJSONValue(FKnowledgeStructuredJSON) as TJSONObject;
  if (RecordValue=nil) or (RecordValue.GetValue<string>('record_type','')<>'calculation_definition') then begin RecordValue.Free;Exit;end;
 end;
 try
  FKnowledgeStructuredJSON:=RecordValue.ToJSON;FStructuredEditorID:=RecordValue.GetValue<string>('calculation_id');FStructuredEditorPending:=True;Fields:=RecordValue.GetValue<TJSONObject>('fields');
  for Key in DPHCalculationKeys do (FindComponent('Calc_'+Key) as TMemo).Text:=Fields.GetValue<string>(Key,'Unknown');
  Calc_name.ReadOnly:=FKnowledgeID<>0;CalculationAuthor.Text:=KnowledgeAuthorEdit.Text;
 finally RecordValue.Free;end;
 FKnowledgeEdited:=True;WorkspaceTabs.ActiveTab:=CalculationEditorTab;
 StatusLabel.Text:='Complete the calculation fields, enter a named contributor and Apply to Knowledge draft. Then Save, add source links and review.';
end;
procedure TDPHMainForm.CalculationApplyClick(Sender:TObject);
var RecordValue,Fields:TJSONObject;Key:string;
begin
 if FBusy or (FView=nil) or not FKnowledgeEdited then Exit;
 RecordValue:=TJSONObject.ParseJSONValue(FKnowledgeStructuredJSON) as TJSONObject;
 try
  try
   if (RecordValue=nil) or (RecordValue.GetValue<string>('record_type','')<>'calculation_definition') or (RecordValue.GetValue<string>('calculation_id','')<>FStructuredEditorID) then raise EArgumentException.Create('Reopen this calculation with Edit fields before applying');
   Fields:=RecordValue.GetValue<TJSONObject>('fields');
   for Key in DPHCalculationKeys do begin Fields.RemovePair(Key).Free;Fields.AddPair(Key,(FindComponent('Calc_'+Key) as TMemo).Text.Trim);end;
   TDPHWorkspaceView.ValidateCalculation(RecordValue);
   if CalculationAuthor.Text.Trim='' then raise EArgumentException.Create('Enter a named contributor');
   FBinding:=True;
   try
    KnowledgeTitleEdit.Text:=Fields.GetValue<string>('name').Trim;KnowledgeAuthorEdit.Text:=CalculationAuthor.Text.Trim;
    KnowledgeBodyMemo.Text:=TDPHWorkspaceView.CalculationBody(RecordValue);KnowledgeBodyMemo.ReadOnly:=True;KnowledgeTitleEdit.ReadOnly:=True;
    KnowledgeKindCombo.ItemIndex:=KnowledgeKindCombo.Items.IndexOf('business_rule');KnowledgeDocumentCombo.ItemIndex:=KnowledgeDocumentCombo.Items.IndexOf('maintenance');KnowledgeAudienceCombo.ItemIndex:=KnowledgeAudienceCombo.Items.IndexOf('maintainer');
    KnowledgeKindCombo.Enabled:=False;KnowledgeDocumentCombo.Enabled:=False;KnowledgeAudienceCombo.Enabled:=False;
    FKnowledgeStructuredJSON:=RecordValue.ToJSON;FKnowledgeLink:='';FKnowledgeQuestionJSON:='';
   finally FBinding:=False;end;
   FStructuredEditorPending:=False;WorkspaceTabs.ActiveTab:=KnowledgeTab;StatusLabel.Text:='Calculation draft prepared. Click Save to persist. Add exact source links on Knowledge links, Save again and review separately.';
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
   if (RecordValue=nil) or (RecordValue.GetValue<string>('record_type','')<>'business_rule_definition') or (RecordValue.GetValue<string>('rule_id',RecordValue.GetValue<string>('calculation_id',''))<>FStructuredEditorID) then raise EArgumentException.Create('Reopen this rule with Edit fields before applying');
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
  ID:=RecordValue.GetValue<string>('process_id',RecordValue.GetValue<string>('workflow_id',RecordValue.GetValue<string>('rule_id',RecordValue.GetValue<string>('calculation_id',''))));
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
 DatabaseSchemaSource.Enabled:=False;DatabaseSchemaMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.ee958ac608167d14', 'Select a schema object or unsupported statement to read its captured evidence and next investigation.');
 if (FDatabaseSchemaRows=nil) or (DatabaseSchemaList.ItemIndex<0) or (DatabaseSchemaList.ItemIndex>=FDatabaseSchemaRows.Count) then Exit;
 DatabaseSchemaMemo.Text:=TDPHDatabaseSchema.Describe(FDatabaseSchemaRows[DatabaseSchemaList.ItemIndex])+sLineBreak+sLineBreak+FDatabaseSchema.GetValue<string>('qualification');
 DatabaseDictionaryEdit.Enabled:=MatchText(FDatabaseSchemaRows[DatabaseSchemaList.ItemIndex].GetValue<string>('kind'),['table','column']) and MatchText(FDatabaseSchemaRows[DatabaseSchemaList.ItemIndex].GetValue<string>('status'),['declared header','declared column']);
 if DatabaseDictionaryEdit.Enabled then begin
  SchemaText:=DatabaseSchemaMemo.Text;SavedDictionary:=TDPHDatabaseSchema.FindDictionary(FKnowledge,FDatabaseSchemaRows[DatabaseSchemaList.ItemIndex]);
  if SavedDictionary<>nil then DatabaseSchemaMemo.Text:=SavedDictionary.GetValue<string>('body')+sLineBreak+'Review state: '+SavedDictionary.GetValue<string>('state')+' | Open dictionary history for contributor, revisions and review.'
  else DatabaseSchemaMemo.Text:='BUSINESS DICTIONARY'+sLineBreak+'Business meaning not recorded for these captured bytes. Click Edit dictionary. Do not infer purpose or sensitivity from SQL names.';
  DatabaseDictionaryKnowledge.Enabled:=TDPHDatabaseSchema.FindDictionary(FKnowledge,FDatabaseSchemaRows[DatabaseSchemaList.ItemIndex],True)<>nil;
  if DatabaseDictionaryKnowledge.Enabled and (SavedDictionary=nil) then DatabaseSchemaMemo.Lines.Add(DATTranslateText('DPH.UI.Main.Memo.caa444f662e3bb3c', 'Historical dictionary exists for this source/record/name with different captured bytes. Open dictionary history; it is not transferred or verified against this capture.'));
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
 DatabaseSchemaMemo.Lines.Add(DATTranslateText('DPH.UI.Main.Memo.037f4894e4662327', 'Relationship target is no longer present in this captured projection.'));
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
 DatabaseInventoryMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.ba96f0fbf8dd7d4a', 'Select a connection, dataset, data source, transaction, session or definition. Missing configuration and runtime bindings remain unknown.');
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
 HistoryMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.afd3a5ae31abc14c', 'Import attributed PNG evidence on Screenshots first. Optional relative form paths enable layout comparison using each image generation. Retain those captures in Database tools. Scroll this page for images, layout changes and evidence.');
 HistoryBeforePaint.Repaint;HistoryAfterPaint.Repaint;HistoryDifferencePaint.Repaint;
end;
procedure TDPHMainForm.HistoryCompareClick(Sender:TObject);
var Request:TDPHWorkspaceRequest;Index:Integer;Path:string;
begin
 if Sender=HistorySwapButton then begin Index:=HistoryBeforeCombo.ItemIndex;HistoryBeforeCombo.ItemIndex:=HistoryAfterCombo.ItemIndex;HistoryAfterCombo.ItemIndex:=Index;Path:=HistoryBeforePath.Text;HistoryBeforePath.Text:=HistoryAfterPath.Text;HistoryAfterPath.Text:=Path;HistorySelectionChange(nil);Exit;end;
 if FBusy then begin StatusLabel.Text:='Wait for the current operation to finish';Exit;end;
 if (FView=nil) or (FDatabase='') then begin HistoryMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.c29c15d3edfab3d9', 'Open a saved project database first');Exit;end;
 if (FImages=nil) or (HistoryBeforeCombo.ItemIndex<0) or (HistoryAfterCombo.ItemIndex<0) or (HistoryBeforeCombo.ItemIndex>=FImages.Count) or (HistoryAfterCombo.ItemIndex>=FImages.Count) then begin HistoryMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.3f779109d08873f2', 'Import screenshots and select both Before and After records');Exit;end;
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
procedure TDPHMainForm.ScreenshotReturnClick(Sender: TObject);
begin
  if FScreenshotOriginTab<>nil then WorkspaceTabs.ActiveTab:=FScreenshotOriginTab;
  FScreenshotOriginTab:=nil;
  ScreenshotReturnButton.Enabled:=False;
end;
procedure TDPHMainForm.RefreshExplorer;
const KindKeys: array[1..19] of string =
  ('unit','type','routine','anonymous','component','event','field','property',
   'local','variable','parameter','resource','definition','async_operation',
   'dynamic_control','output_artifact','sql_statement','sql_table','sql_column');
var Rows: TJSONArray; V: TJSONValue; S: TJSONObject; Kind,KindText,LabelText,Prefix,DisplayText,FullLabel: string;
  Depth,Index,LastDot,PreviousDot: Integer; IsRightToLeft: Boolean;
begin
  IsRightToLeft:=SameText(DATActiveTextDirection,'rtl');
  if FView=nil then Exit; Kind:='';
  if (KindCombo.ItemIndex>=Low(KindKeys)) and (KindCombo.ItemIndex<=High(KindKeys)) then
    Kind:=KindKeys[KindCombo.ItemIndex];
  if FShowingBookmarks then begin
    FHierarchyVisible:=False; ExplorerExpandButton.Enabled:=False; NextPageButton.Enabled:=False;
    ExplorerList.Items.Clear; FExplorerKeys.Clear;
    for LabelText in FBookmarks do begin
      S:=FView.Symbol(LabelText);
      if S<>nil then begin
        FullLabel:=S.GetValue<string>('name');
        LastDot:=LastDelimiter('.',FullLabel);
        PreviousDot:=LastDelimiter('.',Copy(FullLabel,1,LastDot-1));
        if PreviousDot>0 then DisplayText:='...'+Copy(FullLabel,PreviousDot+1,MaxInt)
        else DisplayText:=FullLabel;
        DisplayText:=DATTranslateDynamicText(S.GetValue<string>('kind'))+'  '+DisplayText;
        if IsRightToLeft then DisplayText:=#$2066+DisplayText+#$2069;
        ExplorerList.Items.Add(DisplayText);
        FExplorerKeys.Add(LabelText); end;
    end;
    for Index:=0 to ExplorerList.Count-1 do begin
      ExplorerList.ListItems[Index].StyledSettings:=ExplorerList.ListItems[Index].StyledSettings-[TStyledSetting.Other];
      ExplorerList.ListItems[Index].WordWrap:=False;
      ExplorerList.ListItems[Index].Trimming:=TTextTrimming.Character;
      ExplorerList.ListItems[Index].Height:=32;
      S:=FView.Symbol(FExplorerKeys[Index]);
      if S<>nil then ExplorerList.ListItems[Index].Hint:=S.GetValue<string>('name');
      ExplorerList.ListItems[Index].ShowHint:=True;
      if IsRightToLeft then ExplorerList.ListItems[Index].TextSettings.HorzAlign:=TTextAlign.Trailing
      else ExplorerList.ListItems[Index].TextSettings.HorzAlign:=TTextAlign.Leading;
    end;
    BreadcrumbLabel.Text:='Saved places for this application ('+IntToStr(FExplorerKeys.Count)+')';
    Exit;
  end;
  FHierarchyVisible:=(Trim(SearchEdit.Text)='') and (Kind='') and (FScope='');
  ExplorerExpandButton.Enabled:=FHierarchyVisible;
  if FHierarchyVisible then Rows:=FView.Hierarchy(FExpandedKeys.ToArray,FPage,251)
  else Rows:=FView.Search(SearchEdit.Text,Kind,FScope,FPage,251);
  if (Rows.Count=0) and (FPage>0) then begin Rows.Free; FPage:=0; RefreshExplorer; Exit; end;
  try
    ExplorerList.Items.BeginUpdate;
    try ExplorerList.Items.Clear; FExplorerKeys.Clear;
      for V in Rows do begin
        if FExplorerKeys.Count>=250 then Break;
        S:=V as TJSONObject; LabelText:=S.GetValue<string>('name'); Prefix:='';
        if S.GetValue<string>('kind','')='routine' then
          if S.GetValue<string>('type','')<>'' then LabelText:='function '+LabelText
          else LabelText:='procedure '+LabelText;
        if FHierarchyVisible then begin
          Depth:=S.GetValue<Integer>('depth'); Prefix:=StringOfChar(' ',Min(Depth,20)*2);
          if S.GetValue<Boolean>('has_children') then begin if S.GetValue<Boolean>('expanded') then Prefix:=Prefix+'[-] ' else Prefix:=Prefix+'[+] '; end
          else Prefix:=Prefix+'    ';
          if Depth>0 then LabelText:=Copy(LabelText,LastDelimiter('.',LabelText)+1,MaxInt);
        end;
        if not FHierarchyVisible then begin
          LastDot:=LastDelimiter('.',LabelText);
          PreviousDot:=LastDelimiter('.',Copy(LabelText,1,LastDot-1));
          if PreviousDot>0 then LabelText:='...'+Copy(LabelText,PreviousDot+1,MaxInt);
        end;
        if S.GetValue<string>('type','')<>'' then LabelText:=LabelText+' : '+S.GetValue<string>('type');
        KindText:=DATTranslateDynamicText(S.GetValue<string>('kind'));
        DisplayText:=Prefix+KindText+'  '+LabelText;
        if IsRightToLeft then DisplayText:=#$2066+DisplayText+#$2069;
        ExplorerList.Items.Add(DisplayText); FExplorerKeys.Add(S.GetValue<string>('key'));
      end;
      for Index:=0 to ExplorerList.Count-1 do begin
        ExplorerList.ListItems[Index].StyledSettings:=ExplorerList.ListItems[Index].StyledSettings-[TStyledSetting.Other];
        ExplorerList.ListItems[Index].WordWrap:=False;
        ExplorerList.ListItems[Index].Trimming:=TTextTrimming.Character;
        ExplorerList.ListItems[Index].Height:=32;
        ExplorerList.ListItems[Index].Hint:=(Rows.Items[Index] as TJSONObject).GetValue<string>('name');
        ExplorerList.ListItems[Index].ShowHint:=True;
        if IsRightToLeft then ExplorerList.ListItems[Index].TextSettings.HorzAlign:=TTextAlign.Trailing
        else ExplorerList.ListItems[Index].TextSettings.HorzAlign:=TTextAlign.Leading;
      end;
    finally ExplorerList.Items.EndUpdate; end;
    BreadcrumbLabel.Text:='Learning '+TPath.GetFileNameWithoutExtension(FView.Document.GetValue<string>('entry'));
    NextPageButton.Enabled:=Rows.Count>250;
  finally Rows.Free; end;
end;
procedure TDPHMainForm.SearchChange(Sender: TObject);
begin if FBinding then Exit; FShowingBookmarks:=False; FScope:=''; FPage:=0; RefreshExplorer; end;
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
  if FDetached or (FEntry='') then begin DetailsMemo.Lines.Add(DATTranslateText('DPH.UI.Main.Memo.23e7d84788728732', 'Original source is detached. The cached statement/value and source evidence remain available here.')); Exit; end;
  Row:=FDetails.Items[DetailsList.ItemIndex] as TJSONObject; Range:=Row.GetValue<TJSONObject>('range');
  if Row.GetValue<Int64>('generation_id',FView.Document.GetValue<Int64>('generation_id'))<>FView.Document.GetValue<Int64>('generation_id') then begin DetailsMemo.Lines.Add(DATTranslateText('DPH.UI.Main.Memo.92ee8e7ea7d6e4e0', 'Historical evidence: source navigation is disabled until this target is reviewed against the current generation.')); Exit; end;
  FileRow:=FView.SourceFile(Range.GetValue<string>('source')); if FileRow=nil then Exit;
  Path:=TPath.GetFullPath(TPath.Combine(ExtractFilePath(FEntry),Range.GetValue<string>('source')));
  if not StartsText(IncludeTrailingPathDelimiter(ExtractFilePath(FEntry)),Path) then begin DetailsMemo.Lines.Add(DATTranslateText('DPH.UI.Main.Memo.14a44b9f901d2d8b', 'Source location is outside the attached project.')); Exit; end;
  Diagnostics:=TDPHDiagnostics.Create;
  try
    try Source:=TDPHSource.Create(Path,Range.GetValue<string>('source'),Diagnostics,FView.Document.GetValue<Integer>('code_page',0));
      try
        if not Source.Decoded or not SameText(Source.SHA256,Row.GetValue<string>('source_hash','')) then begin DetailsMemo.Lines.Add(DATTranslateText('DPH.UI.Main.Memo.befd94a74f49f0a5', 'Source is changed or undecodable; the cached range was not applied.')); Exit; end;
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
  BackButton.Enabled:=FHistory.Count>0;
  InspectorMemo.Text:=S.GetValue<string>('name')+sLineBreak+sLineBreak+
    'This is a '+S.GetValue<string>('kind')+' in the selected application.'+sLineBreak+sLineBreak+
    IfThen(S.GetValue<string>('type','')<>'','Declared type: '+S.GetValue<string>('type')+sLineBreak+sLineBreak,'')+
    'Read Project map to understand its connections and the steps behind it. A routine is a named operation; an event connects an action to that operation.'+sLineBreak+sLineBreak+
    'Source location: '+S.GetValue<string>('range.source')+':'+S.GetValue<Integer>('range.line').ToString+sLineBreak+sLineBreak+
    'Use Handoff dossier for context. Source details remain available through Prepare lessons.';
  RelationsList.Items.Clear; FRelationKeys.Clear;
  FreeAndNil(FDetails); FDetails:=FView.Details(AKey); DetailsList.Items.Clear;
  for V in FDetails do begin Row:=V as TJSONObject;
    DetailsList.Items.Add(Row.GetValue<string>('detail_kind')+' | '+Row.GetValue<string>('title')+' | line '+Row.GetValue<Integer>('range.line').ToString);
  end;
  DetailsMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.e64fa9bbda52fee7', 'Select a row to read its statement, serialized value or relationship and source evidence. Maximum 1,000 rows. Serialized properties are overrides; absent framework defaults are not inferred.');
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
begin
  if FView=nil then begin StatusLabel.Text:='Choose an application before browsing its project map.'; Exit; end;
  if FHistory.Count=0 then begin StatusLabel.Text:='There is no earlier selection yet. Choose an object in Project map first.'; WorkspaceTabs.ActiveTab:=ExplainTab; Exit; end;
  Key:=FHistory.Last; FHistory.Delete(FHistory.Count-1); SelectSymbol(Key,False);
  WorkspaceTabs.ActiveTab:=ExplainTab; StatusLabel.Text:='Returned to the previous object.';
end;
procedure TDPHMainForm.ParentClick(Sender: TObject);
var Rows: TJSONArray; V: TJSONValue; R: TJSONObject; ParentKey: string;
begin
  if FView=nil then begin StatusLabel.Text:='Choose an application before browsing its project map.'; Exit; end;
  ParentKey:='';
  if FSelected<>'' then begin
    Rows:=FView.Neighbors(FSelected,'reverse');
    try for V in Rows do begin R:=V as TJSONObject;
      if R.GetValue<string>('kind','')='owns' then begin ParentKey:=R.GetValue<string>('from',''); Break; end;
    end; finally Rows.Free; end;
  end;
  FShowingBookmarks:=False; FScope:=''; FPage:=0;
  if ParentKey<>'' then begin SelectSymbol(ParentKey); StatusLabel.Text:='Opened the containing project object.'; end
  else begin FSelected:=''; ShowExplanation; StatusLabel.Text:='At the top of the project map.'; end;
  RefreshExplorer; WorkspaceTabs.ActiveTab:=ExplainTab;
end;
procedure TDPHMainForm.NextPageClick(Sender: TObject);
begin
  if FView=nil then begin StatusLabel.Text:='Choose an application before browsing its project map.'; Exit; end;
  if FShowingBookmarks or not NextPageButton.Enabled then begin
    StatusLabel.Text:='There are no further objects in this list.'; WorkspaceTabs.ActiveTab:=ExplainTab; Exit;
  end;
  Inc(FPage,250); RefreshExplorer; WorkspaceTabs.ActiveTab:=ExplainTab;
  StatusLabel.Text:='Showing the next page of project objects.';
end;
procedure TDPHMainForm.BookmarkClick(Sender: TObject);
begin
  if FView=nil then begin StatusLabel.Text:='Choose an application before saving a place.'; Exit; end;
  if FSelected='' then begin StatusLabel.Text:='Select an object in Project map, then choose Save place.';
    WorkspaceTabs.ActiveTab:=ExplainTab; Exit; end;
  if FBookmarks.Contains(FSelected) then StatusLabel.Text:='This object is already in Saved places.'
  else begin FBookmarks.Add(FSelected); StatusLabel.Text:='Saved this object in Saved places.'; end;
  WorkspaceTabs.ActiveTab:=ExplainTab;
  if FShowingBookmarks then RefreshExplorer;
end;
procedure TDPHMainForm.BookmarksClick(Sender: TObject);
begin
  if FView=nil then begin StatusLabel.Text:='Choose an application before opening Saved places.'; Exit; end;
  FShowingBookmarks:=True; FSelected:=''; RefreshExplorer; ShowExplanation;
  WorkspaceTabs.ActiveTab:=ExplainTab;
  if FBookmarks.Count=0 then StatusLabel.Text:='No saved places yet. Select an object and choose Save place.'
  else StatusLabel.Text:='Select a saved place from the list on the left.';
end;
procedure TDPHMainForm.ViewChange(Sender: TObject);
begin
  if FBinding then Exit;
  if Sender=GraphCombo then FWholeGraph:=GraphCombo.ItemIndex=0;
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
  GraphCombo.ItemIndex:=3; FWholeGraph:=True; RefreshGraphics;
  WorkspaceTabs.ActiveTab:=GraphTab;
  StatusLabel.Text:='Form navigation from captured forms and declared instances. Show/Hide/Close actions are static possibilities; runtime screens and order are unobserved.';
end;
procedure TDPHMainForm.AllDataGraphClick(Sender: TObject);
begin
  if FView=nil then Exit;
  GraphCombo.ItemIndex:=4; FWholeGraph:=True; RefreshGraphics;
  WorkspaceTabs.ActiveTab:=GraphTab;
  StatusLabel.Text:='Project data: source input/output dependencies, resources, SQL and artifacts. Arrow labels retain their rules; runtime values and context are unverified.';
end;
procedure TDPHMainForm.RefreshGraphics;
const GraphKinds: array[0..7] of string = ('Execution','Procedure CFG','Caller / callee','Form navigation','Data flow','Change impact','Data lineage','Business process');
var Grouped: TJSONObject; Limit: Integer; HTML,GraphPath,Seed,Direction: string;IsLineage:Boolean;
    GraphModel: TDPHExplanationModel;
begin
  FreeAndNil(FGraph); FreeAndNil(FScreen); if FView=nil then Exit;
  FExpectedGraphPage:=''; FlowBrowser.Visible:=False;
  if (WorkspaceTabs.ActiveTab<>GraphTab) and (WorkspaceTabs.ActiveTab<>ScreenTab) then Exit;
  if WorkspaceTabs.ActiveTab=ScreenTab then begin
    if ScreenModeCombo.ItemIndex=0 then FScreen:=TDPHScreenLayout.Gallery(FView)
    else if FormCombo.ItemIndex>=0 then FScreen:=TDPHScreenLayout.Reconstruct(FView,FormCombo.Items[FormCombo.ItemIndex]);
    UpdateScreenBounds;
    ScreenPaint.Repaint;
    Exit;
  end;
  GraphScroll.Visible:=False;
  if (WorkspaceTabs.ActiveTab=GraphTab) and (FLearningFacts=nil) then RefreshLearning;
  if (FSelected='') and (GraphCombo.ItemIndex in [0,3,4]) then FWholeGraph:=True;
  GraphPaint.Width:=Max(1050,GraphScroll.Width-24);
  GraphPaint.Height:=4500;
  IsLineage:=GraphCombo.ItemIndex=6;
  if GraphCombo.ItemIndex>=0 then case GraphCombo.ItemIndex of
    0: GraphPurpose.Text:='Execution shows which routines may call other routines. Follow a connection to understand how an action moves through the code.';
    1: GraphPurpose.Text:='A control-flow graph shows the paths through one procedure, including choices, loops and exits.';
    2: GraphPurpose.Text:='Caller / callee shows which routines use a selected routine and which routines it uses.';
    3: GraphPurpose.Text:='Form navigation shows connections between screens and controls. Use it to explore where a user action may lead.';
    4: GraphPurpose.Text:='Data flow shows where inputs, stored information and outputs are referenced in the application.';
    5: GraphPurpose.Text:='Change impact shows parts that depend on a selected part. It helps explain what might be affected by a change.';
    6: GraphPurpose.Text:='Data lineage follows possible paths from an input or database object to later uses and outputs.';
    7: GraphPurpose.Text:='Business process shows the sequence of a documented task, including alternate paths when available.';
  end;
  GraphLegend.Text:='Blue: direct connection in the project files. Orange dashed: possible connection that needs interpretation. Select a box for details.';
  Limit:=120; GraphGroupingCombo.Enabled:=(GraphCombo.ItemIndex<>1) and not IsLineage;
  if (GraphCombo.ItemIndex<>1) and (GraphGroupingCombo.ItemIndex>0) then Limit:=1000;
  if GraphCombo.ItemIndex=7 then begin
   GraphGroupingCombo.Enabled:=False;
   GraphLegend.Text:='Authored business workflow | blue: normal sequence | orange: exception routes | select steps for details | exact process links retain revision review; runtime unobserved';
   if FKnowledgeEdited then StatusLabel.Text:='Save or discard the current Knowledge draft before opening a saved workflow diagram.'
   else if (DepartmentalWorkflowList.ItemIndex>=0) and (DepartmentalWorkflowList.ItemIndex<FDepartmentalWorkflowRows.Count) then
    FGraph:=TDPHGraphProjection.Workflow(FDepartmentalWorkflowRows[DepartmentalWorkflowList.ItemIndex],FKnowledge,FView.Document.GetValue<Int64>('generation_id'));
   if FGraph<>nil then GraphPaint.Height:=Max(4500,FGraph.GetValue<TJSONArray>('nodes').Count*190+40);
  end
  else if IsLineage then begin
   if FDatabaseInventory=nil then FDatabaseInventory:=TDPHDatabaseConnections.Inspect(FView);
   Seed:=FLineageSeed;if Seed='' then Seed:=FSelected;Direction:=FLineageDirection;if Direction='' then Direction:='both';
   if FDatabaseInventory<>nil then FGraph:=TDPHDatabaseConnections.Lineage(FView,FDatabaseInventory,Seed,Direction);
   GraphLegend.Text:='Data lineage source candidates | arrows: lexical dependency or labeled context, not runtime order | select a node for details | unresolved breaks are listed below the HTML diagram and in Trace lineage';
  end
  else if FWholeGraph and (GraphCombo.ItemIndex in [0,3,4]) then FGraph:=FView.Graph(GraphKinds[GraphCombo.ItemIndex],'',Limit)
  else if GraphCombo.ItemIndex=1 then FGraph:=FView.Graph('Procedure CFG',FSelected,Limit)
  else if GraphCombo.ItemIndex>=0 then FGraph:=FView.Graph(GraphKinds[GraphCombo.ItemIndex],FSelected,Limit);
  if (GraphCombo.ItemIndex=0) and not FWholeGraph and (FSelected<>'') and
    (FGraph<>nil) and (FGraph.GetValue<TJSONArray>('nodes').Count=1) and
    (FGraph.GetValue<TJSONArray>('edges').Count=0) then begin
    FreeAndNil(FGraph);
    FGraph:=FView.Graph('Execution','',Limit);
    FWholeGraph:=True;
    GraphPurpose.Text:='No code connection was found from the selected object. Showing the application-wide code connections instead.';
  end;
  if (FGraph<>nil) and (GraphCombo.ItemIndex<>1) and not IsLineage and (FGraph.GetValue<string>('kind')<>'Business process') and (GraphGroupingCombo.ItemIndex>0) then begin
    Grouped:=TDPHGraphProjection.Group(FView,FGraph,GraphGroupingCombo.Items[GraphGroupingCombo.ItemIndex]); FGraph.Free; FGraph:=Grouped;
  end;
  if (FGraph<>nil) and (FLearningFacts<>nil) then begin
    GraphModel:=FExplanations;
    if GraphModel=nil then begin
      if GraphCombo.ItemIndex=1 then begin
        FExplanations:=TDPHExplanationModel.Create(FLearningFacts.Document);
        GraphModel:=FExplanations;
      end else GraphModel:=TDPHExplanationModel.Create(FLearningFacts.Document,False);
    end;
    try
      if GraphCombo.ItemIndex=1 then HTML:=GraphModel.FlowHTML(FSelected) else HTML:=GraphModel.GraphHTML(FGraph);
    finally if GraphModel<>FExplanations then GraphModel.Free; end;
    HTML:=HTML.Replace('href="#','href="index.html#');
    HTML:=DATTranslateHtmlText(HTML);
    GraphPath:=TPath.Combine(FFlowDirectory,THashSHA2.GetHashString(HTML)+'.html');
    if not FPreviewPages.Contains(GraphPath) then begin
      TFile.WriteAllBytes(GraphPath,TEncoding.UTF8.GetBytes(HTML)); FPreviewPages.Add(GraphPath);
    end;
    TFile.WriteAllBytes(TPath.Combine(FFlowDirectory,'index.html'),TEncoding.UTF8.GetBytes(HTML));
    try FExpectedGraphPage:=TPath.GetFileName(GraphPath);
      FlowBrowser.WindowsEngine:=TWindowsEngine.EdgeOnly;
      FlowBrowser.Navigate('file://'+GraphPath);
    except on E: Exception do begin FlowBrowser.Visible:=False; GraphScroll.Visible:=True;
      GraphPaint.Repaint; StatusLabel.Text:='HTML graph view unavailable; native graph retained: '+E.Message; end; end;
  end;
  if FGraph=nil then GraphScroll.Visible:=True;
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
  HeaderLayout.Visible:=not FScreenFullscreen;
  LearnerNavRow1.Visible:=not FScreenFullscreen; LearnerNavRow2.Visible:=not FScreenFullscreen;
  ExplorerLayout.Visible:=not FScreenFullscreen; ExplorerSplitter.Visible:=not FScreenFullscreen;
  InspectorLayout.Visible:=not FScreenFullscreen; InspectorSplitter.Visible:=not FScreenFullscreen;
  UpdateScreenBounds;
end;
procedure TDPHMainForm.FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin if (Key=vkEscape) and FScreenFullscreen then begin FullscreenClick(nil); Key:=0; end; end;
procedure TDPHMainForm.FormResize(Sender: TObject);
begin
  UpdateLearnerNavigation;
  UpdateScreenBounds;
  if ScreenshotImage<>nil then UpdateScreenshotBounds;
  if GraphPaint<>nil then begin
    GraphPaint.Width:=Max(1050,GraphScroll.Width-24);
    GraphPaint.Repaint;
  end;
end;
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
procedure TDPHMainForm.LoadKnowledge(ARows: TJSONArray; ADeferInitialViews: Boolean);
begin
  FCardRows.Clear;CardList.Items.Clear;FTaskRows.Clear;FKnowledge.Free; FKnowledge:=ARows;DepartmentalWorkflowFilterChange(nil); if not FKnowledgeEdited then NewKnowledgeClick(nil); KnowledgeFilterChange(nil); GlossaryFilterChange(nil);
  RefreshLearning;
  if not ADeferInitialViews then begin
    RefreshCoverage;
    RefreshQuestions;
  end;
  DependencyFilterChange(nil); DatabaseSchemaSelectionChange(nil);FileFormatsSelectionChange(nil);DataRetentionFilterChange(nil);TargetRecoveryFilterChange(nil);BusinessProcessFilterChange(nil);CalculationFilterChange(nil);BusinessRuleFilterChange(nil);DepartmentalWorkflowFilterChange(nil);DataQualityFilterChange(nil);TaskFilterChange(nil);CardFilterChange(nil); FActionPurposeRows.Clear;FreeAndNil(FActionPurposes);ActionPurposeFilterChange(nil);if (FView<>nil) and (WorkspaceTabs.ActiveTab=ActionPurposeTab) then WorkspacePageChange(nil);
end;
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
  FreeAndNil(FTaskDraft);FTutorStepDirty:=False;
  FreeAndNil(FCardDraft);
  FreeAndNil(FWorkflowDraft);FWorkflowStepDirty:=False;FStructuredEditorPending:=False;FStructuredEditorID:='';
  FreeAndNil(FTranslations); TranslationList.Items.Clear; TranslationMemo.Text:='';
  FBinding:=True; try FKnowledgeID:=0; FKnowledgeRevision:=0; KnowledgeTitleEdit.Text:=''; KnowledgeBodyMemo.Text:='';
    FKnowledgeQuestionJSON:='';
    FKnowledgeStructuredJSON:='{}'; KnowledgeBodyMemo.ReadOnly:=False;
    KnowledgeTitleEdit.ReadOnly:=False; KnowledgeKindCombo.Enabled:=True; KnowledgeDocumentCombo.Enabled:=True; KnowledgeAudienceCombo.Enabled:=True;
    if (KnowledgeKindCombo.ItemIndex>=0) and (KnowledgeKindCombo.Items[KnowledgeKindCombo.ItemIndex]='glossary') then KnowledgeKindCombo.ItemIndex:=0;
    KnowledgeDocumentCombo.ItemIndex:=0; KnowledgeAudienceCombo.ItemIndex:=0; KnowledgeSectionLabel.Text:='New section: stable ID assigned on Save';
    FreeAndNil(FEditableLinks); FEditableLinks:=TJSONArray.Create; RefreshKnowledgeLinks;
    KnowledgeHistoryMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.6ce13d44db1711fc', 'New content links to the selected canonical object, or the project when no object is selected. Titles and kinds remain stable after creation.');
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
  GlossaryMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.f94f97b767477e38', 'No matching saved terms. Click New term to define business language for this selected application.');
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
        KnowledgeHistoryMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.4ffaed4ba75333cf', 'Edit term fields in Business glossary. Knowledge links stores exact source evidence. Saving preserves prior revisions and requires a fresh named review.');
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
        KnowledgeHistoryMemo.Text:=DATTranslateText('DPH.UI.Main.Memo.09818941cd05999b', 'Structured profile fields are edited with Projects > Project profile. Saved revisions and review history remain available in Knowledge.');
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
  try PublishBrowser.WindowsEngine:=TWindowsEngine.EdgeOnly; PublishBrowser.Visible:=True; PublishBrowser.Navigate('file://'+TPath.Combine(FExportDirectory,'handoff-0.html'));
  except on E: Exception do begin PublishBrowser.Visible:=False; PublishMemo.Text:='Embedded preview unavailable: '+E.Message+sLineBreak+'Open handoff-0.html in '+FExportDirectory; end; end;
end;
procedure TDPHMainForm.BrowserShouldLoad(Sender: TObject; const AURL: string; var ACancel: Boolean);
begin ACancel:=not TDPHBrowserPolicy.Allowed(AURL,FExportDirectory,True); end;
initialization
  SetWebView2Path(TPath.Combine(ExtractFilePath(ParamStr(0)),'WebView2Loader.dll'));
end.
