program DPH.Tests.LayoutRules;
{$APPTYPE CONSOLE}
uses System.SysUtils,System.Classes,System.IOUtils,System.JSON,System.StrUtils,System.Hash,System.UITypes,
 FMX.Forms,FMX.Graphics,DPH.UI.Main,DPH.Project.Analysis,DPH.Analysis.Symbols,DPH.Analysis.Model,
 DPH.Workspace.Model,DPH.Workspace.Keyboard,DPH.Workspace.LayoutRules,DPH.Workspace.Catalog;
var Root,Work,Fixture,Text,Hash,Catalog,CatalogHash:string;Checks,I:Integer;Analyzer:TDPHAnalyzer;Semantic:TDPHSemanticAnalyzer;
 Scan:TDPHScan;Graph:TDPHSemanticGraph;View:TDPHWorkspaceView;Keyboard,Report,Row,CopyDoc:TJSONObject;
 Form:TDPHMainForm;Bitmap:TBitmap;Input:TStringStream;Binary:TMemoryStream;Rejected:Boolean;
procedure Check(OK:Boolean;const S:string);
begin if not OK then raise Exception.Create('FAIL '+S);Inc(Checks);Writeln('PASS ',Checks,': ',S);Flush(Output);end;
function Find(const Name:string):TJSONObject;
var V:TJSONValue;
begin Result:=nil;for V in Report.GetValue<TJSONArray>('rows') do if V.GetValue<string>('name')=Name then Exit(V as TJSONObject);end;
function Has(const Name,S:string):Boolean;
begin Result:=ContainsText(TDPHLayoutRules.Describe(Find(Name),120,80),S);end;
procedure Render(const Name:string);
begin Application.ProcessMessages;Bitmap:=TBitmap.Create(Form.ClientWidth,Form.ClientHeight);try if Bitmap.Canvas.BeginScene then try Form.PaintTo(Bitmap.Canvas);finally Bitmap.Canvas.EndScene;end;Bitmap.SaveToFile(TPath.Combine(Root,'docs\'+Name));finally Bitmap.Free;end;end;
begin
 Application.Initialize;
 try
 Root:=TPath.GetFullPath(ParamStr(1));Work:=TPath.Combine(Root,'bin\layout-validation');Fixture:=TPath.Combine(Work,'source');TDirectory.CreateDirectory(Fixture);
 TFile.WriteAllText(TPath.Combine(Fixture,'Layouts.dpr'),'program Layouts; uses Classic, Touch, BinaryLayout; begin end.',TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(Fixture,'Classic.pas'),'unit Classic; interface implementation {$R *.dfm} end.',TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(Fixture,'Touch.pas'),'unit Touch; interface implementation {$R *.fmx} end.',TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(Fixture,'BinaryLayout.pas'),'unit BinaryLayout; interface implementation {$R *.dfm} end.',TEncoding.UTF8);
 Text:=String.Join(sLineBreak,[
 'object Main: TForm',' ClientWidth = 800',' ClientHeight = 600',' Scaled = True',' PixelsPerInch = 96',
 ' object Container: TPanel','  Width = 600','  Height = 400','  Padding.Left = 8',
 '  object Stretch: TEdit','   Align = alNone','   Anchors = [akLeft, akTop, akRight, akBottom]','   Width = 200','   Height = 40','   Margins.Left = 4','   Constraints.MinWidth = 100','   Constraints.MaxWidth = 500','   OnResize = Resized','  end',
 '  object Trailing: TButton','   Align = alNone','   Anchors = [akRight, akBottom]','  end',
 '  object Leading: TButton','   Align = alNone','   Anchors = [akLeft, akTop]','  end',
 '  object Unanchored: TButton','   Align = alNone','   Anchors = []','  end',
 '  object Fill: TPanel','   Align = alClient','   Anchors = [akLeft, akTop, akRight, akBottom]','  end',
 '  object Dock: TPanel','   Align = alTop','   AlignWithMargins = True','  end',
 '  object Custom: TPanel','   Align = alCustom','   OnAlignPosition = CustomAlign','  end',
 '  object UnknownAlign: TPanel','   Align = WeirdAlign','   Anchors = [akLeft, akRight]','  end',
 '  object UnknownAnchor: TPanel','   Align = alNone','   Anchors = [akLeft, akRightExtra]','  end',
 '  object Limits: TLabel','   Constraints.MinWidth = 200','   Constraints.MaxWidth = 100','   AutoSize = True','   WordWrap = True','  end',
 '  inherited BaseEdit: TEdit','   Align = alNone','   Anchors = [akLeft, akRight]','  end',
 '  object Missing: TButton','  end',' end','end']);
 TFile.WriteAllText(TPath.Combine(Fixture,'Classic.dfm'),Text,TEncoding.UTF8);Hash:=THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'Classic.dfm'));
 Text:='object TouchForm: TForm'+sLineBreak;
 for Root in ['Contents','Center','HorzCenter','VertCenter','Scale','Fit','FitLeft','Horizontal','TopRight'] do Text:=Text+' object Mode'+Root+': TLayout'+sLineBreak+'  Align = '+Root+sLineBreak+'  Position.X = 12'+sLineBreak+'  Size.Width = 200'+sLineBreak+'  Scale.X = 1.5'+sLineBreak+' end'+sLineBreak;
 Root:=TPath.GetFullPath(ParamStr(1));
 for I:=1 to 270 do Text:=Text+' object Extra'+IntToStr(I)+': TButton'+sLineBreak+'  Align = None'+sLineBreak+'  Anchors = [akLeft, akTop]'+sLineBreak+' end'+sLineBreak;
 TFile.WriteAllText(TPath.Combine(Fixture,'Touch.fmx'),Text+'end',TEncoding.UTF8);
 Input:=TStringStream.Create('object BinaryForm: TForm'+sLineBreak+' object BinaryFill: TPanel'+sLineBreak+'  Align = alClient'+sLineBreak+' end'+sLineBreak+'end');Binary:=TMemoryStream.Create;
 try ObjectTextToBinary(Input,Binary);Binary.SaveToFile(TPath.Combine(Fixture,'BinaryLayout.dfm'));finally Binary.Free;Input.Free;end;
 Analyzer:=TDPHAnalyzer.Create;Semantic:=TDPHSemanticAnalyzer.Create;
 try Scan:=Analyzer.Scan(TPath.Combine(Fixture,'Layouts.dpr'),'Debug','Win32',[],[],False);try Graph:=Semantic.Analyze(Scan);try View:=TDPHWorkspaceView.Create(TDPHWorkspaceView.Capture(Scan,Graph,1,'Layouts.dpr','Debug','Win32',[],[]));finally Graph.Free;end;finally Scan.Free;end;finally Semantic.Free;Analyzer.Free;end;
 try Keyboard:=TDPHKeyboardInspector.Inspect(View);try Report:=TDPHLayoutRules.Inspect(Keyboard);
 try
 Check(Find('Stretch')<>nil,'Actual text DFM component captured');Check(Find('ModeContents')<>nil,'Actual FMX component captured');Check(Find('BinaryFill')<>nil,'Binary DFM layout captured');
 Check(Has('Stretch','Anchors = [akLeft, akTop, akRight, akBottom]'),'Original anchor set retained');
 Check(Has('Stretch','width change = 120 units') and Has('Stretch','height change = 80 units'),'Opposing anchor example explains size change');
 Check(Has('Trailing','left change = 120 units') and Has('Trailing','top change = 80 units'),'Trailing anchor example explains position change');
 Check(Has('Leading','leading edge anchored'),'Leading anchors explained');Check(Has('Unanchored','no numeric example inferred'),'No-anchor behavior remains framework dependent');
 Check(Has('Fill','requests remaining parent client space'),'Client allocation explained');Check(not Has('Fill','basic example width change = 120 units'),'Active alignment suppresses anchor-only arithmetic');
 Check(Has('Dock','Edge alignment alTop'),'Edge docking explained');Check(Has('Custom','Custom alignment requires'),'Custom layout requires code review');
 Check(Has('UnknownAlign','Unsupported Align value WeirdAlign'),'Unknown enum retained without invented semantics');
 Check(Has('UnknownAnchor','Unsupported Anchors value'),'Unknown anchor token rejected');Check(not Has('UnknownAnchor','basic example width change = 120 units'),'Substring anchor name never activates arithmetic');
 Check(Has('Missing','Align not serialized') and Has('Missing','Anchors not serialized'),'Missing defaults remain unknown');
 Check(Has('BaseEdit','base rules are uncaptured; no numeric example'),'Inherited layout never claims numeric behavior');
 Check(Has('Main','No serialized parent captured'),'Root gets no invented parent example');
 Check(Has('Stretch','Parent Padding.Left = 8'),'Serialized parent spacing context retained');
 Check(Has('Stretch','Margins.Left = 4') and Has('Stretch','Constraints.MaxWidth = 500'),'Spacing and constraints preserved');
 Check(Has('Stretch','OnResize = Resized'),'Resize event source evidence retained');
 Check(Has('Limits','AutoSize = True') and Has('Limits','WordWrap = True'),'Content layout declarations preserved');
 Check(Has('Limits','MinWidth exceeds nonzero MaxWidth'),'Conflicting dimension constraints flagged as review candidate');
 Check(Has('Main','PixelsPerInch = 96') and Has('Main','Scaled = True'),'VCL DPI declarations preserved');
 Check(Has('ModeContents','Contents alignment'),'FMX contents distinct from remaining client');
 Check(Has('ModeCenter','centers on the named axis'),'FMX center explained');Check(Has('ModeHorizontal','Axis-fill alignment'),'FMX horizontal fill explained');
 Check(Has('ModeScale','Proportional alignment Scale'),'FMX scale explained');Check(Has('ModeFit','Scale and Fit differ'),'FMX Fit distinguished from Scale');Check(Has('ModeTopRight','Corner/edge placement'),'FMX corner placement explained');
 Check(Has('ModeContents','Position.X = 12') and Has('ModeContents','Size.Width = 200') and Has('ModeContents','Scale.X = 1.5'),'FMX position, size and scale preserved');
 Check(TDPHLayoutRules.Describe(Find('Stretch'),-120,-80).Contains('width change = -120 units'),'Shrinking example supports negative changes');
 Check(Report.GetValue<string>('qualification').Contains('not evaluated VCL/FMX'),'Engine and runtime limits explicit');
 Row:=Find('Stretch');Check(Row.GetValue<string>('source_hash')=Hash,'Captured fingerprint retained');
 Check(TDPHKeyboardInspector.ReadSource(View,TPath.Combine(Fixture,'Layouts.dpr'),Row,Row.GetValue<TJSONObject>('range')).Contains('Stretch'),'Matching form source navigation verified');
 Row:=Find('BinaryFill');Rejected:=False;try TDPHKeyboardInspector.ReadSource(View,TPath.Combine(Fixture,'Layouts.dpr'),Row,Row.GetValue<TJSONObject>('range'));except on E:EInvalidOpException do Rejected:=E.Message.Contains('Binary form');end;Check(Rejected,'Binary byte locations never used as text lines');
 Catalog:=TDPHWorkspaceCatalog.DefaultPath;CatalogHash:='';if TFile.Exists(Catalog) then CatalogHash:=THashSHA2.GetHashStringFromFile(Catalog);
 Form:=TDPHMainForm.Create(nil);try Form.PollTimer.Enabled:=False;Form.ChangeTimer.Enabled:=False;Form.LoadView(View.Document.Clone as TJSONObject);
 Check(Form.LayoutList.Count=250,'Native pagination bounded to 250');Check(Form.LayoutNextButton.Enabled,'Further components enable Next');
 Form.LayoutFilterChange(Form.LayoutNextButton);Check(Form.LayoutList.Count=Report.GetValue<Integer>('total')-250,'Next page shows remaining components');Check(not Form.LayoutNextButton.Enabled,'Last page disables Next');
 Form.LayoutFilterChange(Form.LayoutFirstButton);Check(Form.LayoutList.Count=250,'First page resets offset');
 Check(Form.WorkspacePageCombo.Items.IndexOf('Layout rules')>=0,'Page discoverable in workspace selector');
 Form.LayoutFilterEdit.Text:='LAYOUT RULES Stretch :';Form.LayoutFilterChange(nil);Check(Form.LayoutList.Count=1,'Filter finds component');Check(Form.LayoutMemo.Text.Contains('width change = 120 units'),'Native selection explains default example');
 Form.LayoutWidthEdit.Text:='-50';Form.LayoutHeightEdit.Text:='30';Form.LayoutApplyClick(nil);Check(Form.LayoutMemo.Text.Contains('width change = -50 units') and Form.LayoutMemo.Text.Contains('height change = 30 units'),'Native example applies chosen changes');
 Form.LayoutWidthEdit.Text:='invalid';Form.LayoutApplyClick(nil);Check(Form.LayoutStatus.Text.Contains('whole width and height'),'Invalid example input explained');Check(Form.LayoutMemo.Text.Contains('width change = -50 units'),'Invalid input preserves previous valid example');
 Form.LayoutWidthEdit.Text:='2147483647';Form.LayoutApplyClick(nil);Check(Form.LayoutStatus.Text.Contains('-10000 to 10000'),'Large integer rejected without overflow');
 Form.LayoutSourceClick(nil);Check(Form.LayoutMemo.Text.Contains('Source is detached'),'Detached navigation refused explicitly');
 Form.LayoutFilterEdit.Text:='absent xyz';Form.LayoutFilterChange(nil);Check(Form.LayoutList.Count=0,'Empty filter clears previous components');Check(not Form.LayoutSourceButton.Enabled,'Empty filter disables source navigation');
 Form.LayoutFilterEdit.Text:='LAYOUT RULES Stretch :';Form.LayoutFilterChange(nil);Form.LayoutWidthEdit.Text:='120';Form.LayoutHeightEdit.Text:='80';Form.LayoutApplyClick(nil);Form.WorkspaceTabs.ActiveTab:=Form.LayoutTab;Form.Show;Render('phase1-layout-workspace.png');
 Form.WindowState:=TWindowState.wsNormal;Form.Width:=960;Form.Height:=600;Render('phase1-layout-compact.png');Check(Form.LayoutMemo.Height>=60,'Compact layout retains detail area');Check(Form.LayoutToolbar.ShowScrollBars,'Compact toolbar scrolls');Form.Hide;
 CopyDoc:=View.Document.Clone as TJSONObject;CopyDoc.GetValue<TJSONObject>('syntax').RemovePair('files').Free;CopyDoc.GetValue<TJSONObject>('syntax').AddPair('files',TJSONArray.Create);Form.LoadView(CopyDoc);Check(Form.LayoutList.Count=0,'Replacement capture clears stale layout rows');
 finally Form.Free;end;
 Check((not TFile.Exists(Catalog) and (CatalogHash='')) or (TFile.Exists(Catalog) and (THashSHA2.GetHashStringFromFile(Catalog)=CatalogHash)),'User catalog unchanged');Check(THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'Classic.dfm'))=Hash,'Selected fixture source unchanged');
 TFile.WriteAllText(TPath.Combine(Root,'docs\validation\reports\phase1-layout-validation.json'),TJSONObject.Create.AddPair('result','PASS').AddPair('checks',TJSONNumber.Create(Checks)).AddPair('fixture',Work).AddPair('qualification','Actual text/binary DFM and FMX parser evidence plus instantiated native DPH controls. Educational resize arithmetic is not target-engine evaluation. PaintTo renders are not target-runtime screenshots.').ToJSON,TEncoding.UTF8);
 finally Report.Free;end;finally Keyboard.Free;end;finally View.Free;end;
 Writeln('Layout rules validation passed: ',Checks,' checks.');
 except on E:Exception do begin Writeln(E.ClassName,': ',E.Message);ExitCode:=1;end;end;
end.
