program DPH.Tests.DynamicControls;
{$APPTYPE CONSOLE}
uses System.SysUtils,System.Classes,System.IOUtils,System.JSON,System.StrUtils,System.Hash,System.UITypes,
 FMX.Forms,FMX.Graphics,DPH.UI.Main,DPH.Project.Analysis,DPH.Analysis.Symbols,DPH.Analysis.Model,
 DPH.Workspace.Model,DPH.Workspace.DynamicControls,DPH.Workspace.Catalog;
var Root,Work,Fixture,Code,SourceHash,Catalog,CatalogHash:string; Checks,I:Integer;
 Analyzer:TDPHAnalyzer; Semantic:TDPHSemanticAnalyzer; Scan:TDPHScan; Graph:TDPHSemanticGraph;
 View:TDPHWorkspaceView; Report,CopyDoc:TJSONObject; Form:TDPHMainForm; Bitmap:TBitmap;
procedure Check(OK:Boolean;const S:string);
begin if not OK then raise Exception.Create('FAIL '+S);Inc(Checks);Writeln('PASS ',Checks,': ',S);Flush(Output);end;
function Find(const Name:string):TJSONObject;
var V:TJSONValue;
begin Result:=nil;for V in Report.GetValue<TJSONArray>('rows') do if ContainsText(V.GetValue<string>('name'),Name+'.$control1') then Exit(V as TJSONObject);end;
function Has(const Name,Text:string):Boolean;
begin Result:=ContainsText(TDPHDynamicControls.Describe(Find(Name)),Text);end;
procedure Render(const Name:string);
begin Application.ProcessMessages;Bitmap:=TBitmap.Create(Form.ClientWidth,Form.ClientHeight);
 try if Bitmap.Canvas.BeginScene then try Form.PaintTo(Bitmap.Canvas);finally Bitmap.Canvas.EndScene;end;Bitmap.SaveToFile(TPath.Combine(Root,'docs\'+Name));finally Bitmap.Free;end;end;
begin
 Application.Initialize;
 try
 Root:=TPath.GetFullPath(ParamStr(1));Work:=TPath.Combine(Root,'bin\dynamic-validation');Fixture:=TPath.Combine(Work,'source');TDirectory.CreateDirectory(Fixture);
 TFile.WriteAllText(TPath.Combine(Fixture,'Dynamic.dpr'),'program Dynamic; uses Model; begin end.',TEncoding.UTF8);
 Code:=String.Join(sLineBreak,[
 'unit Model; interface uses Vcl.Controls, Vcl.StdCtrls;',
 'type TMain = class',' Panel: TPanel;',' procedure Click(Sender: TObject);',
 ' procedure Clobber;', ' procedure Build;',' procedure Reuse;',' procedure Before;',' procedure Empty;',' procedure Unknown;',' procedure Looping;', 'end;',
 'implementation','procedure TMain.Click(Sender: TObject); begin end;',
 'procedure TMain.Build; var B: TButton; begin',
 ' {$IFDEF DPH_TEST_DYNAMIC}', ' B := TButton.Create(Self);', ' {$ENDIF}', ' B.Parent := Panel;',' B.OnClick := Click;',' B.Caption := ''Run'';','end;',
 'procedure TMain.Clobber; var B: TButton; begin B := TButton.Create(Self); B := nil; B.Parent := Panel; end;',
 'procedure TMain.Reuse; var B: TButton; begin',' B := TButton.Create(nil);',' B.Parent := Panel;',' B := TButton.Create(Self);',' B.OnClick := Click;','end;',
 'procedure TMain.Before; var B: TButton; begin',' B.Parent := Panel;',' B := TButton.Create(Self);','end;',
 'procedure TMain.Empty; var B: TButton; begin',' B := TButton.Create(nil);',' B.Parent := nil;',' B.OnClick := nil;','end;',
 'procedure TMain.Unknown; var B: TButton; begin',' B := TButton.Create(GetOwner());',' B.Parent := GetPanel();',' B.OnClick := MissingHandler;','end;',
 'procedure TMain.Looping; var B: TButton; I: Integer; begin',' for I := 1 to 10 do begin B := TButton.Create(Self); B.Parent := Panel; end;','end;']);
 for I:=1 to 270 do Code:=Code+sLineBreak+'procedure Extra'+IntToStr(I)+'; var B: TButton; begin B := TButton.Create(nil); end;';
 TFile.WriteAllText(TPath.Combine(Fixture,'Model.pas'),Code+sLineBreak+'end.',TEncoding.UTF8);SourceHash:=THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'Model.pas'));
 Analyzer:=TDPHAnalyzer.Create;Semantic:=TDPHSemanticAnalyzer.Create;
 try Scan:=Analyzer.Scan(TPath.Combine(Fixture,'Dynamic.dpr'),'Debug','Win32',['DPH_TEST_DYNAMIC'],[],False);
 try Graph:=Semantic.Analyze(Scan);
 try View:=TDPHWorkspaceView.Create(TDPHWorkspaceView.Capture(Scan,Graph,1,'Dynamic.dpr','Debug','Win32',['DPH_TEST_DYNAMIC'],[]));finally Graph.Free;end;
 Graph:=Semantic.Analyze(Scan);try Check(Semantic.ReusedRoutines>0,'Incremental cache reuses new relationship candidates');
 CopyDoc:=Graph.AsJSON;try Check(CopyDoc.ToJSON=View.Document.GetValue<TJSONObject>('semantics').ToJSON,'Cached and fresh semantic relationships are identical');finally CopyDoc.Free;end;finally Graph.Free;end;
 finally Scan.Free;end;finally Semantic.Free;Analyzer.Free;end;
 try Report:=TDPHDynamicControls.Inspect(View);
 try
 Check(Report.GetValue<Integer>('total')=278,'Creation sites counted independently of loop execution');
 Check(Find('Build')<>nil,'Actual Pascal parser supplies creation site');
 Check(Has('Build','constructor_owner | Self [inferred]'),'Constructor owner expression retained');
 Check(Has('Build','Reference target: Model.TMain (type)'),'Self resolves to declaring type not invented runtime object');
 Check(Has('Build','dynamic_parent | B.Parent := Panel [inferred]'),'Parent assignment recorded separately');
 Check(Has('Build','Reference target: Model.TMain.Panel'),'Parent declaration linked');
 Check(Has('Build','dynamic_event | B.OnClick := Click [inferred]'),'Event assignment recorded');
 Check(Has('Build','Reference target: Model.TMain.Click (routine)'),'Unique event routine linked');
 Check(Has('Build','dynamic_property | B.Caption := ''Run'''),'Property expression retained without evaluation');
 Check(Has('Build','assigned_to'),'Lexical control handle retained');
 Check(Has('Reuse','dynamic_assignment_ambiguous'),'Reused handle is not attributed to one instance');
 Check(not Has('Reuse','dynamic_parent |'),'Ambiguous reused handle gets no false parent link');
 Check(Has('Clobber','dynamic_assignment_ambiguous'),'Overwritten handle is not attributed to the creation site');
 Check(not Has('Clobber','dynamic_parent |'),'Overwritten handle gets no false parent link');
 Check(Has('Before','dynamic_assignment_ambiguous'),'Assignment before construction is not attributed');
 Check(Has('Empty','constructor_owner | nil [inferred]'),'Explicit nil owner preserved');
 Check(Has('Empty','dynamic_parent | B.Parent := nil [inferred]'),'Explicit nil parent preserved');
 Check(Has('Empty','dynamic_event | B.OnClick := nil [inferred]'),'Explicit event clearing preserved');
 Check(Has('Unknown','GetOwner() [unresolved]'),'Factory owner expression stays unresolved');
 Check(Has('Unknown','GetPanel() [unresolved]'),'Factory parent expression stays unresolved');
 Check(Has('Unknown','MissingHandler [unresolved]'),'Missing event routine stays unresolved');
 Check(Has('Looping','Runtime instances: unknown / unobserved'),'Loop site never invents ten runtime instances');
 Check(Find('Build').GetValue<string>('condition').Contains('DPH_TEST_DYNAMIC'),'Creation site retains conditional compilation context');
 Check(Find('Build').GetValue<string>('source_hash')=SourceHash,'Source fingerprint retained');
 Check(Find('Build').GetValue<Integer>('range.line')>0,'Creation source line retained');
 Check(Report.GetValue<string>('qualification').Contains('zero, one or many'),'Instance uncertainty explained');
 Check(Has('Build','Owner means') or Report.GetValue<string>('qualification').Contains('Owner means lifetime'),'Owner versus parent explained');
 Catalog:=TDPHWorkspaceCatalog.DefaultPath;CatalogHash:='';if TFile.Exists(Catalog) then CatalogHash:=THashSHA2.GetHashStringFromFile(Catalog);
 Form:=TDPHMainForm.Create(nil);
 try Form.PollTimer.Enabled:=False;Form.ChangeTimer.Enabled:=False;Form.LoadView(View.Document.Clone as TJSONObject);
 Check(Form.DynamicList.Count=250,'Native page holds at most 250 sites');Check(Form.DynamicNextButton.Enabled,'Further sites enable next page');
 Form.DynamicFilterChange(Form.DynamicNextButton);Check(Form.DynamicList.Count=28,'Next page shows remaining sites');Check(not Form.DynamicNextButton.Enabled,'Last page disables Next');
 Form.DynamicFilterChange(Form.DynamicFirstButton);Check(Form.DynamicList.Count=250,'First page resets offset');
 Check(Form.WorkspacePageCombo.Items.IndexOf('Dynamic controls')>=0,'Page discoverable through selector');
 Form.DynamicFilterEdit.Text:='TMain.Build';Form.DynamicFilterChange(nil);Check(Form.DynamicList.Count=1,'Filter finds creation routine');
 Check(Form.DynamicMemo.Text.Contains('B.Parent := Panel'),'Native detail displays parent evidence');
 Check(Form.DynamicExplainButton.Enabled,'Selected site enables Explain');Form.DynamicExplainClick(nil);Check(Form.WorkspaceTabs.ActiveTab=Form.ExplainTab,'Creation Explain opens captured site');
 for I:=0 to Form.DynamicReferenceCombo.Items.Count-1 do begin Form.DynamicReferenceCombo.ItemIndex:=I;Form.DynamicReferenceChange(nil);
 if Form.DynamicReferenceCombo.Items[I].StartsWith('dynamic_event') then begin Check(Form.DynamicReferenceButton.Enabled,'Resolved event enables reference Explain');Form.DynamicExplainClick(Form.DynamicReferenceButton);Check(Form.WorkspaceTabs.ActiveTab=Form.ExplainTab,'Event reference opens Explain');end;end;
 Form.DynamicFilterEdit.Text:='TMain.Unknown';Form.DynamicFilterChange(nil);
 for I:=0 to Form.DynamicReferenceCombo.Items.Count-1 do begin Form.DynamicReferenceCombo.ItemIndex:=I;Form.DynamicReferenceChange(nil);
 if Form.DynamicReferenceCombo.Items[I].Contains('[unresolved]') then Check(not Form.DynamicReferenceButton.Enabled,'Unresolved reference disables Explain');end;
 Form.DynamicFilterEdit.Text:='no-match xyz';Form.DynamicFilterChange(nil);Check(Form.DynamicList.Count=0,'Empty filter clears sites');Check(not Form.DynamicExplainButton.Enabled and not Form.DynamicReferenceButton.Enabled,'Empty filter disables commands');
 Form.DynamicFilterEdit.Text:='TMain.Build';Form.DynamicFilterChange(nil);Form.WorkspaceTabs.ActiveTab:=Form.DynamicTab;Form.Show;Render('phase1-dynamic-workspace.png');
 Form.WindowState:=TWindowState.wsNormal;Form.Width:=960;Form.Height:=600;Render('phase1-dynamic-compact.png');Check(Form.DynamicMemo.Height>=60,'Compact layout retains detail area');Check(Form.DynamicToolbar.ShowScrollBars,'Compact command bar scrolls');Form.Hide;
 CopyDoc:=View.Document.Clone as TJSONObject;CopyDoc.GetValue<TJSONObject>('semantics').RemovePair('symbols').Free;CopyDoc.GetValue<TJSONObject>('semantics').AddPair('symbols',TJSONArray.Create);Form.LoadView(CopyDoc);Check(Form.DynamicList.Count=0,'New capture clears previous sites');
 finally Form.Free;end;
 Check((not TFile.Exists(Catalog) and (CatalogHash='')) or (TFile.Exists(Catalog) and (THashSHA2.GetHashStringFromFile(Catalog)=CatalogHash)),'User project catalog unchanged');
 Check(THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'Model.pas'))=SourceHash,'Selected fixture source unchanged');
 TFile.WriteAllText(TPath.Combine(Root,'docs\validation\reports\phase1-dynamic-validation.json'),TJSONObject.Create.AddPair('result','PASS').AddPair('checks',TJSONNumber.Create(Checks)).AddPair('fixture',Work).AddPair('qualification','Actual Pascal parser/semantic evidence and instantiated native FMX form. PaintTo renders are running DPH controls, not target-runtime screenshots.').ToJSON,TEncoding.UTF8);
 finally Report.Free;end;finally View.Free;end;
 Writeln('Dynamic controls validation passed: ',Checks,' checks.');
 except on E:Exception do begin Writeln(E.ClassName,': ',E.Message);ExitCode:=1;end;end;
end.
