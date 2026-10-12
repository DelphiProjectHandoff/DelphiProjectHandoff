program DPH.Tests.Commands;
{$APPTYPE CONSOLE}
uses System.SysUtils, System.Classes, System.IOUtils, System.JSON, System.StrUtils, System.Hash, System.UITypes,
 FMX.Forms, FMX.Graphics, DPH.UI.Main, DPH.Project.Analysis, DPH.Analysis.Symbols,
 DPH.Analysis.Model, DPH.Workspace.Model, DPH.Workspace.Keyboard, DPH.Workspace.Commands, DPH.Workspace.Catalog;
var Root,Work,Fixture,BeforeHash,CatalogPath,CatalogHash,SourceText: string; Checks,I: Integer;
 Analyzer:TDPHAnalyzer; Semantic:TDPHSemanticAnalyzer; Scan:TDPHScan; Graph:TDPHSemanticGraph;
 View:TDPHWorkspaceView; Keyboard,Report,Row,CopyDocument:TJSONObject; V:TJSONValue;
 Form:TDPHMainForm; Bitmap:TBitmap; Input:TStringStream; Binary:TMemoryStream; Rejected:Boolean;
procedure Check(OK:Boolean; const S:string);
begin if not OK then raise Exception.Create('FAIL '+S); Inc(Checks); Writeln('PASS ',Checks,': ',S); Flush(Output); end;
function Find(const Name:string):TJSONObject;
var Item:TJSONValue;
begin Result:=nil; for Item in Report.GetValue<TJSONArray>('rows') do if Item.GetValue<string>('name')=Name then Exit(Item as TJSONObject); end;
function Has(const Name,Text:string):Boolean;
begin Result:=ContainsText(TDPHCommandInventory.Describe(Find(Name)),Text); end;
procedure Render(const Name:string);
begin Application.ProcessMessages; Bitmap:=TBitmap.Create(Form.ClientWidth,Form.ClientHeight);
 try if Bitmap.Canvas.BeginScene then try Form.PaintTo(Bitmap.Canvas); finally Bitmap.Canvas.EndScene; end;
 Bitmap.SaveToFile(TPath.Combine(Root,'docs\'+Name)); finally Bitmap.Free; end; end;
begin
 Application.Initialize;
 try
 Root:=TPath.GetFullPath(ParamStr(1)); Work:=TPath.Combine(Root,'bin\commands-validation'); Fixture:=TPath.Combine(Work,'source'); TDirectory.CreateDirectory(Fixture);
 TFile.WriteAllText(TPath.Combine(Fixture,'Commands.dpr'),'program Commands; uses MenuModel, Touch, BinaryMenu; begin end.',TEncoding.UTF8);
 SourceText:='unit MenuModel; interface type TMain = class'+sLineBreak;
 for Root in ['SaveExecute','SaveUpdate','DirectClick','PopupOpening'] do SourceText:=SourceText+' procedure '+Root+'(Sender: TObject);'+sLineBreak;
 SourceText:=SourceText+'end; implementation'+sLineBreak;
 for Root in ['SaveExecute','SaveUpdate','DirectClick','PopupOpening'] do SourceText:=SourceText+'procedure TMain.'+Root+'(Sender: TObject); begin end;'+sLineBreak;
 Root:=TPath.GetFullPath(ParamStr(1));
 TFile.WriteAllText(TPath.Combine(Fixture,'MenuModel.pas'),SourceText+'{$R *.dfm} end.',TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(Fixture,'Touch.pas'),'unit Touch; interface implementation {$R *.fmx} end.',TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(Fixture,'BinaryMenu.pas'),'unit BinaryMenu; interface implementation {$R *.dfm} end.',TEncoding.UTF8);
 Input:=TStringStream.Create('object BinaryForm: TForm'+sLineBreak+' object BinaryPopup: TPopupMenu'+sLineBreak+' end'+sLineBreak+'end'); Binary:=TMemoryStream.Create;
 try ObjectTextToBinary(Input,Binary); Binary.SaveToFile(TPath.Combine(Fixture,'BinaryMenu.dfm')); finally Binary.Free; Input.Free; end;
 SourceText:=String.Join(sLineBreak,[
 'object Main: TMain',' Menu = MainMenu',
 ' object MainMenu: TMainMenu','  object FileMenu: TMenuItem','   Caption = ''&File''',
 '   object SaveMenu: TMenuItem','    Caption = ''&Save''','    Action = SaveAction','    OnClick = DirectClick','    Checked = True','    AutoCheck = True','    GroupIndex = 2','    RadioItem = True','   end',
 '   object Separator: TMenuItem','    Caption = ''-''','   end','  end',' end',
 ' object ContextMenu: TPopupMenu','  OnPopup = PopupOpening','  object ContextOpen: TMenuItem','   OnClick = DirectClick','  end',' end',
 ' object Editor: TEdit','  PopupMenu = ContextMenu',' end',
 ' object Tools: TToolBar','  object SaveTool: TToolButton','   Action = SaveAction','   Style = tbsCheck','  end',
 '  object Layout: TPanel','   object NestedButton: TButton','    OnClick = DirectClick','   end','  end',' end',
 ' object Actions: TActionList','  object SaveAction: TAction','   Caption = ''Save document''','   ShortCut = 16467','   Category = ''File''','   OnExecute = SaveExecute','   OnUpdate = SaveUpdate','  end',
 '  object DuplicateAction: TAction','  end','  object DuplicateAction: TAction','  end',' end',
 ' object Remote: TButton','  Action = OtherModule.ExternalAction',' end',
 ' object Ambiguous: TButton','  Action = DuplicateAction',' end',
 ' object WrongMenu: TEdit','  PopupMenu = SaveAction',' end',
 ' object MissingHandler: TMenuItem','  OnClick = NotDeclared',' end',
 ' object PlainEdit: TEdit',' end',' inherited InheritedCommand: TMenuItem',' end','end']);
 TFile.WriteAllText(TPath.Combine(Fixture,'MenuModel.dfm'),SourceText,TEncoding.UTF8);
 SourceText:='object TouchForm: TForm'+sLineBreak+' object Bar: TMenuBar'+sLineBreak+'  object TouchMenu: TMenuItem'+sLineBreak+'   Text = ''Touch'''+sLineBreak+'  end'+sLineBreak+' end';
 for I:=1 to 270 do SourceText:=SourceText+sLineBreak+' object Extra'+IntToStr(I)+': TMenuItem'+sLineBreak+'  Text = ''Extra command '+IntToStr(I)+''''+sLineBreak+' end';
 TFile.WriteAllText(TPath.Combine(Fixture,'Touch.fmx'),SourceText+sLineBreak+'end',TEncoding.UTF8);
 BeforeHash:=THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'MenuModel.dfm'));
 Analyzer:=TDPHAnalyzer.Create; Semantic:=TDPHSemanticAnalyzer.Create;
 try Scan:=Analyzer.Scan(TPath.Combine(Fixture,'Commands.dpr'),'Debug','Win32',[],[],False);
 try Graph:=Semantic.Analyze(Scan); try View:=TDPHWorkspaceView.Create(TDPHWorkspaceView.Capture(Scan,Graph,1,'Commands.dpr','Debug','Win32',[],[])); finally Graph.Free; end; finally Scan.Free; end;
 finally Semantic.Free; Analyzer.Free; end;
 try Keyboard:=TDPHKeyboardInspector.Inspect(View); try Report:=TDPHCommandInventory.Inspect(View,Keyboard);
 try
 Check(Find('SaveMenu')<>nil,'Actual text DFM command parsed');
 Check(Find('TouchMenu')<>nil,'Actual FMX command parsed');
 Check(Find('BinaryPopup')<>nil,'Binary DFM command parsed');
 Check(Find('PlainEdit')=nil,'Unrelated component excluded');
 Check(Find('MainMenu').GetValue<string>('kind')='main menu','Main menu classified');
 Check(Find('Bar').GetValue<string>('kind')='main menu','FMX menu bar classified');
 Check(Find('ContextMenu').GetValue<string>('kind')='context menu','Context menu classified');
 Check(Find('Separator').GetValue<string>('kind')='menu separator','Separators distinguished from commands');
 Check(Find('SaveMenu').GetValue<string>('command_path')='Main / MainMenu / FileMenu / SaveMenu','Nested serialized menu path retained');
 Check(Find('SaveTool').GetValue<string>('kind')='toolbar command','Toolbar command classified');
 Check(Find('NestedButton').GetValue<string>('kind')='toolbar child','Nested toolbar child captured');
 Check(Find('SaveAction').GetValue<string>('kind')='action','Action classified');
 Check(Find('Actions').GetValue<string>('kind')='action container','Action list classified');
 Check(Find('Editor').GetValue<string>('kind')='menu attachment','Context attachment captured');
 Check(Has('Editor','PopupMenu = ContextMenu [confirmed_static]'),'Unique local context reference resolved');
 Check(Has('Main','Menu = MainMenu [confirmed_static]'),'Form menu attachment resolved');
 Check(Has('Remote','Action reference unresolved'),'External action stays unresolved');
 Check(Has('Ambiguous','Action reference unresolved'),'Duplicate local names stay unresolved');
 Check(Has('WrongMenu','PopupMenu reference unresolved'),'Incompatible menu class stays unresolved');
 Check(Has('MissingHandler','Handler unresolved'),'Absent routine stays unresolved');
 Check(Has('InheritedCommand','Inherited/inline command'),'Uncaptured inheritance qualified');
 Check(Has('TouchMenu','Caption/Text (serialized): ''Touch'''),'FMX Text preserved');
 Check(Has('SaveMenu','checked: True') and Has('SaveMenu','groupindex: 2'),'Check and radio state preserved');
 Check(Has('SaveMenu','enabled: unknown (not serialized)'),'Unserialized state remains unknown');
 Check(Has('SaveMenu','Action ShortCut code: 16467'),'Action shortcut shown separately');
 Check(Has('SaveMenu','Action caption (serialized): ''Save document'''),'Action caption preserved');
 Check(Find('SaveMenu').GetValue<TJSONArray>('handlers').Count=3,'Own click and action execute/update remain separate');
 Check(Has('SaveMenu','component.OnClick = DirectClick [confirmed_static]'),'Own handler linked to captured routine');
 Check(Has('SaveMenu','action SaveAction.OnExecute = SaveExecute [confirmed_static]'),'Action execute linked to captured routine');
 Check(Has('SaveMenu','action SaveAction.OnUpdate = SaveUpdate [confirmed_static]'),'Action update linked to captured routine');
 Check(Has('ContextMenu','OnPopup = PopupOpening [confirmed_static]'),'Popup handler linked');
 Check(Find('Separator').GetValue<TJSONArray>('handlers').Count=0,'Separator gets no invented executable binding');
 Check(Find('SaveMenu').GetValue<string>('source_hash')=BeforeHash,'Captured command source fingerprint retained');
 Check(Has('SaveMenu','SHA-256') and Has('SaveMenu','MenuModel.pas'),'Handler source and fingerprints exposed');
 Check(Report.GetValue<string>('qualification').Contains('not observed execution'),'Runtime limits explicit');
 Row:=Find('SaveMenu');
 Check(TDPHKeyboardInspector.ReadSource(View,TPath.Combine(Fixture,'Commands.dpr'),Row,Row.GetValue<TJSONObject>('range')).Contains('SaveMenu'),'Command navigation verifies current text source');
 Check(TDPHKeyboardInspector.ReadSource(View,TPath.Combine(Fixture,'Commands.dpr'),Row,Row.GetValue<TJSONObject>('action_range')).Contains('SaveAction'),'Action navigation verifies current text source');
 Row:=Find('BinaryPopup'); Rejected:=False;
 try TDPHKeyboardInspector.ReadSource(View,TPath.Combine(Fixture,'Commands.dpr'),Row,Row.GetValue<TJSONObject>('range')); except on E:EInvalidOpException do Rejected:=E.Message.Contains('Binary form'); end;
 Check(Rejected,'Binary offsets refused as text lines');
 CatalogPath:=TDPHWorkspaceCatalog.DefaultPath; CatalogHash:=''; if TFile.Exists(CatalogPath) then CatalogHash:=THashSHA2.GetHashStringFromFile(CatalogPath);
 Form:=TDPHMainForm.Create(nil); try Form.PollTimer.Enabled:=False; Form.ChangeTimer.Enabled:=False; Form.LoadView(View.Document.Clone as TJSONObject);
 Check(Form.CommandsList.Count=250,'Native page bounded to 250 rows'); Check(Form.CommandsNextButton.Enabled,'More rows enable pagination');
 Form.CommandsFilterChange(Form.CommandsNextButton); Check((Form.CommandsList.Count=Report.GetValue<Integer>('total')-250) and not Form.CommandsNextButton.Enabled,'Next page reaches remaining commands');
 Form.CommandsFilterChange(Form.CommandsFirstButton); Check(Form.CommandsList.Count=250,'First page resets pagination');
 Check(Form.WorkspacePageCombo.Items.IndexOf('Menus and commands')>=0,'Page available in workspace selector');
 Form.CommandsKindCombo.ItemIndex:=Form.CommandsKindCombo.Items.IndexOf('context menu'); Form.CommandsFilterChange(nil); Check(Form.CommandsList.Count=2,'Kind filter finds both text and binary context menus');
 Form.CommandsKindCombo.ItemIndex:=0; Form.CommandsFilterEdit.Text:='SaveMenu'; Form.CommandsFilterChange(nil); Check(Form.CommandsList.Count=1,'Native text filter finds command');
 Check(Form.CommandsActionButton.Enabled,'Resolved action enables source button'); Check(Form.CommandsHandlerCombo.Items.Count=3,'Native UI offers each handler independently');
 for I:=0 to 2 do begin Form.CommandsHandlerCombo.ItemIndex:=I; Form.CommandsHandlerChange(nil); Check(Form.CommandsHandlerButton.Enabled,'Each confirmed handler independently enables Explain'); end; Form.CommandsHandlerCombo.ItemIndex:=0;
 Check(Form.CommandsHandlerButton.Enabled,'Confirmed handler enables Explain'); Form.CommandsHandlerClick(nil); Check(Form.WorkspaceTabs.ActiveTab=Form.ExplainTab,'Explain opens captured handler');
 Form.CommandsSourceClick(Form.CommandsSourceButton); Check(Form.CommandsMemo.Text.Contains('Source is detached'),'Detached navigation refused explicitly');
 Form.CommandsFilterEdit.Text:='MissingHandler'; Form.CommandsFilterChange(nil); Check(not Form.CommandsHandlerButton.Enabled,'Unresolved handler disables Explain');
 Form.CommandsFilterEdit.Text:='Remote'; Form.CommandsFilterChange(nil); Check(not Form.CommandsActionButton.Enabled,'Unresolved action disables source button');
 Form.CommandsFilterEdit.Text:='absent 123xyz'; Form.CommandsFilterChange(nil); Check(Form.CommandsList.Count=0,'Empty filter clears rows'); Check(not Form.CommandsHandlerButton.Enabled and not Form.CommandsSourceButton.Enabled and not Form.CommandsActionButton.Enabled,'Empty results disable all navigation');
 Form.CommandsFilterEdit.Text:='SaveMenu'; Form.CommandsFilterChange(nil); Form.WorkspaceTabs.ActiveTab:=Form.CommandsTab; Form.Show; Render('phase1-commands-workspace.png');
 Form.WindowState:=TWindowState.wsNormal; Form.Width:=960; Form.Height:=600; Render('phase1-commands-compact.png');
 Check(Form.CommandsMemo.Height>=60,'Compact layout retains detail area'); Check(Form.CommandsToolbar.ShowScrollBars,'Compact toolbar scrolls'); Form.Hide;
 CopyDocument:=View.Document.Clone as TJSONObject; CopyDocument.GetValue<TJSONObject>('syntax').RemovePair('files').Free; CopyDocument.GetValue<TJSONObject>('syntax').AddPair('files',TJSONArray.Create); Form.LoadView(CopyDocument); Check(Form.CommandsList.Count=0,'New capture clears old commands');
 finally Form.Free; end;
 Check((not TFile.Exists(CatalogPath) and (CatalogHash='')) or (TFile.Exists(CatalogPath) and (THashSHA2.GetHashStringFromFile(CatalogPath)=CatalogHash)),'User project catalog unchanged');
 Check(THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'MenuModel.dfm'))=BeforeHash,'Inspection leaves selected source unchanged');
 TFile.WriteAllText(TPath.Combine(Root,'docs\phase1-commands-validation.json'),TJSONObject.Create.AddPair('result','PASS').AddPair('checks',TJSONNumber.Create(Checks)).AddPair('fixture',Work).AddPair('qualification','Real parser/model and instantiated FMX form. PaintTo renders show running DPH controls, not target-runtime screenshots.').ToJSON,TEncoding.UTF8);
 finally Report.Free; end; finally Keyboard.Free; end; finally View.Free; end;
 Writeln('Command validation passed: ',Checks,' checks.');
 except on E:Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode:=1; end; end;
end.
