program DPH.Tests.Keyboard;
{$APPTYPE CONSOLE}
uses System.SysUtils, System.Classes, System.IOUtils, System.JSON, System.StrUtils, System.Hash, System.UITypes,
  FMX.Forms, FMX.Graphics, DPH.UI.Main, DPH.Project.Analysis, DPH.Analysis.Symbols,
  DPH.Analysis.Model, DPH.Workspace.Model, DPH.Workspace.Keyboard, DPH.Workspace.Catalog;
var Root,Work,Fixture,BeforeHash,CatalogPath,CatalogHash: string; Checks,I: Integer;
    Analyzer: TDPHAnalyzer; Semantic: TDPHSemanticAnalyzer; Scan: TDPHScan; Graph: TDPHSemanticGraph;
    View: TDPHWorkspaceView; Report,Row,Other,CopyDocument: TJSONObject; Value: TJSONValue;
    Form: TDPHMainForm; Bitmap: TBitmap; SourceText: string; Rejected: Boolean; Input: TStringStream; Binary: TMemoryStream;
procedure Check(OK: Boolean; const MessageText: string);
begin if not OK then raise Exception.Create('FAIL '+MessageText); Inc(Checks); Writeln('PASS ',Checks,': ',MessageText); Flush(Output); end;
function Find(const Name: string): TJSONObject;
var V: TJSONValue;
begin Result:=nil; for V in Report.GetValue<TJSONArray>('rows') do if V.GetValue<string>('name')=Name then Exit(V as TJSONObject); end;
function Has(const Name,Text: string): Boolean;
begin Result:=ContainsText(TDPHKeyboardInspector.Describe(Find(Name)),Text); end;
procedure Render(const Name: string);
begin
  Application.ProcessMessages; Bitmap:=TBitmap.Create(Form.ClientWidth,Form.ClientHeight);
  try if Bitmap.Canvas.BeginScene then try Form.PaintTo(Bitmap.Canvas); finally Bitmap.Canvas.EndScene; end;
    Bitmap.SaveToFile(TPath.Combine(Root,'docs\'+Name));
  finally Bitmap.Free; end;
end;
begin
  Application.Initialize;
  try
    Root:=TPath.GetFullPath(ParamStr(1)); Work:=TPath.Combine(Root,'bin\keyboard-validation');
    Fixture:=TPath.Combine(Work,'source'); TDirectory.CreateDirectory(Fixture);
    TFile.WriteAllText(TPath.Combine(Fixture,'Keyboard.dpr'),'program Keyboard; uses Keys, Touch, BinaryKeys; begin end.',TEncoding.UTF8);
    TFile.WriteAllText(TPath.Combine(Fixture,'Keys.pas'),'unit Keys; interface implementation {$R *.dfm} end.',TEncoding.UTF8);
    TFile.WriteAllText(TPath.Combine(Fixture,'Touch.pas'),'unit Touch; interface implementation {$R *.fmx} end.',TEncoding.UTF8);
    TFile.WriteAllText(TPath.Combine(Fixture,'BinaryKeys.pas'),'unit BinaryKeys; interface implementation {$R *.dfm} end.',TEncoding.UTF8);
    Input:=TStringStream.Create('object BinaryForm: TForm'+sLineBreak+' object BinaryEdit: TEdit'+sLineBreak+' TabOrder = 0'+sLineBreak+' end'+sLineBreak+'end');
    Binary:=TMemoryStream.Create;
    try ObjectTextToBinary(Input,Binary); Binary.SaveToFile(TPath.Combine(Fixture,'BinaryKeys.dfm'));
    finally Binary.Free; Input.Free; end;
    SourceText:=String.Join(sLineBreak,[
      'object MainKeys: TForm',
      '  object PanelOne: TPanel',
      '    object FirstEdit: TEdit', '      TabOrder = 0', '      TabStop = True', '      Enabled = True', '      OnKeyDown = EditKeyDown', '    end',
      '    object SecondEdit: TEdit', '      TabOrder = 0', '      TabStop = False', '      CanFocus = False', '    end',
      '    object ThirdEdit: TEdit', '      TabOrder = 2', '    end',
      '    object BadEdit: TEdit', '      TabOrder = -1', '      TabStop = Maybe', '    end', '  end',
      '  object PanelTwo: TPanel', '    object OtherEdit: TEdit', '      TabOrder = 0', '    end', '  end',
      '  object Actions: TActionList', '    object SaveAction: TAction', '      ShortCut = 16467', '    end',
      '    object DuplicateAction: TAction', '      ShortCut = $4053', '    end',
      '    object NoKeyAction: TAction', '    end', '  end',
      '  object SaveButton: TButton', '    Action = SaveAction', '    TabOrder = 1', '  end',
      '  object SaveMenu: TMenuItem', '    Action = SaveAction', '  end',
      '  object RemoteButton: TButton', '    Action = DataModule.RemoteAction', '  end',
      '  object NoKeyButton: TButton', '    Action = NoKeyAction', '  end',
      '  object BothButton: TButton', '    Action = SaveAction', '    ShortCut = 0', '  end',
      '  object InvalidShortcut: TMenuItem', '    ShortCut = 999999', '  end',
      '  object UnknownShortcut: TMenuItem', '    ShortCut = CtrlS', '  end',
      '  inherited BaseEdit: TEdit', '  end', 'end']);
    TFile.WriteAllText(TPath.Combine(Fixture,'Keys.dfm'),SourceText,TEncoding.UTF8);
    SourceText:=String.Join(sLineBreak,[
      'object TouchForm: TForm', '  object TouchEdit: TEdit', '    TabOrder = 0', '    CanFocus = True', '    Visible = False', '  end',
      '  object TouchAction: TAction', '    ShortCut = 16467', '  end']);
    for I:=1 to 270 do SourceText:=SourceText+sLineBreak+'  object Extra'+IntToStr(I)+': TEdit'+sLineBreak+'    TabOrder = '+IntToStr(I)+sLineBreak+'  end';
    TFile.WriteAllText(TPath.Combine(Fixture,'Touch.fmx'),SourceText+sLineBreak+'end',TEncoding.UTF8);
    BeforeHash:=THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'Keys.dfm'));
    Analyzer:=TDPHAnalyzer.Create; Semantic:=TDPHSemanticAnalyzer.Create;
    try
      Scan:=Analyzer.Scan(TPath.Combine(Fixture,'Keyboard.dpr'),'Debug','Win32',[],[],False);
      try Graph:=Semantic.Analyze(Scan);
        try View:=TDPHWorkspaceView.Create(TDPHWorkspaceView.Capture(Scan,Graph,1,'Keyboard.dpr','Debug','Win32',[],[]));
        finally Graph.Free; end;
      finally Scan.Free; end;
    finally Semantic.Free; Analyzer.Free; end;
    try
      Report:=TDPHKeyboardInspector.Inspect(View);
      try
        Check(Find('FirstEdit')<>nil,'DFM components are read from actual parser IR');
        Check(Find('TouchEdit')<>nil,'FMX components are read from actual parser IR');
        Check(Find('BinaryEdit')<>nil,'Binary DFM components are read from actual parser IR');
        Check(Has('FirstEdit','Duplicate TabOrder'),'Duplicate sibling focus position is diagnosed');
        Check(not Has('OtherEdit','Duplicate TabOrder'),'Equal positions in different parents are not conflicts');
        Check(not Has('TouchEdit','Duplicate TabOrder'),'Equal positions in different files are not conflicts');
        Check(Has('BadEdit','Invalid or unsupported TabOrder'),'Negative TabOrder is diagnosed');
        Check(Has('BadEdit','Unsupported TabStop'),'Unknown boolean is not silently accepted');
        Check(Has('BaseEdit','Inherited/inline declaration'),'Inherited behavior remains explicitly unknown');
        Check(Find('BaseEdit').GetValue<Integer>('tab_order')=MaxInt,'Missing TabOrder is not invented as zero');
        Check(Find('SaveAction').GetValue<string>('shortcut')='16467','Decimal shortcut code preserved');
        Check(Find('DuplicateAction').GetValue<string>('shortcut')='$4053','Hex shortcut code preserved');
        Check(Has('SaveAction','Possible duplicate shortcut') and Has('DuplicateAction','Possible duplicate shortcut'),'Equivalent decimal/hex shortcuts share a conflict group');
        Check(not Has('TouchAction','Possible duplicate shortcut'),'Shortcut conflicts are scoped to each form');
        Check(Find('SaveButton').GetValue<string>('action_target')='SaveAction','Local action reference resolved');
        Check(Find('SaveButton').GetValue<string>('action_shortcut')='16467','Action shortcut exposed separately');
        Check(Has('SaveButton','Ctrl+S'),'Common Windows shortcut codes have readable key names');
        Check(Find('SaveButton').GetValue('action_range')<>nil,'Action declaration source location retained');
        Check(not Has('SaveButton','Possible duplicate shortcut'),'Action consumers do not inflate duplicate count');
        Check(Has('RemoteButton','Action reference unresolved'),'External action references remain unresolved');
        Check(Has('NoKeyButton','effective shortcut is unknown'),'Absent action shortcut remains unknown');
        Check(Has('BothButton','Both component and action'),'Competing action/component declarations are qualified');
        Check(Has('InvalidShortcut','Unsupported shortcut encoding'),'Out-of-range shortcut rejected for conflict calculation');
        Check(Has('UnknownShortcut','Unsupported shortcut encoding'),'Unsupported symbolic shortcut remains captured');
        Check(Has('FirstEdit','OnKeyDown = EditKeyDown'),'Keyboard event binding visible with source location');
        Check(Has('SecondEdit','tabstop: False') and Has('SecondEdit','canfocus: False'),'Explicit focus exclusions shown');
        Check(Has('TouchEdit','visible: False'),'Explicit visibility shown');
        Check(Has('ThirdEdit','unknown (not serialized)'),'Absent state is explicit');
        Check(Find('FirstEdit').GetValue<Integer>('range.line')>0,'Text form line evidence retained');
        Check(Find('FirstEdit').GetValue<string>('source_hash')=BeforeHash,'Captured file fingerprint retained');
        Check(Report.GetValue<string>('qualification').Contains('not observed'),'Static and runtime evidence distinguished');
        Row:=Find('FirstEdit');
        Check(TDPHKeyboardInspector.ReadSource(View,TPath.Combine(Fixture,'Keyboard.dpr'),Row,Row.GetValue<TJSONObject>('range')).Contains('FirstEdit'),'Verified source navigation reads matching live form');
        Row:=Find('SaveButton');
        Check(TDPHKeyboardInspector.ReadSource(View,TPath.Combine(Fixture,'Keyboard.dpr'),Row,Row.GetValue<TJSONObject>('action_range')).Contains('SaveAction'),'Action navigation reads matching live evidence');
        Row:=Find('BinaryEdit'); Rejected:=False;
        try TDPHKeyboardInspector.ReadSource(View,TPath.Combine(Fixture,'Keyboard.dpr'),Row,Row.GetValue<TJSONObject>('range'));
        except on E: EInvalidOpException do Rejected:=E.Message.Contains('Binary form'); end;
        Check(Rejected,'Binary offsets are never treated as text lines');
        Row:=Find('FirstEdit');
        TFile.AppendAllText(TPath.Combine(Fixture,'Keys.dfm'),sLineBreak,TEncoding.UTF8); Rejected:=False;
        try TDPHKeyboardInspector.ReadSource(View,TPath.Combine(Fixture,'Keyboard.dpr'),Row,Row.GetValue<TJSONObject>('range'));
        except on E: EInvalidOpException do Rejected:=E.Message.Contains('Source changed'); end;
        Check(Rejected,'Changed live bytes refuse captured source offsets');
        // Restore only the controlled fixture bytes from this test, never user source.
        SourceText:=TFile.ReadAllText(TPath.Combine(Fixture,'Keys.dfm'),TEncoding.UTF8);
        TFile.WriteAllText(TPath.Combine(Fixture,'Keys.dfm'),Copy(SourceText,1,Length(SourceText)-Length(sLineBreak)),TEncoding.UTF8);
        Other:=Row.Clone as TJSONObject;
        try
          Other.RemovePair('generation_id').Free; Other.AddPair('generation_id',TJSONNumber.Create(999)); Rejected:=False;
          try TDPHKeyboardInspector.ReadSource(View,TPath.Combine(Fixture,'Keyboard.dpr'),Other,Other.GetValue<TJSONObject>('range'));
          except on E: EInvalidOpException do Rejected:=E.Message.Contains('Historical generation'); end;
          Check(Rejected,'Historical generations refuse navigation');
          Other.RemovePair('generation_id').Free; Other.AddPair('generation_id',TJSONNumber.Create(1));
          Other.GetValue<TJSONObject>('range').RemovePair('source').Free;
          Other.GetValue<TJSONObject>('range').AddPair('source','..\outside.dfm');
          Other.RemovePair('source').Free; Other.AddPair('source','..\outside.dfm'); Rejected:=False;
          try TDPHKeyboardInspector.ReadSource(View,TPath.Combine(Fixture,'Keyboard.dpr'),Other,Other.GetValue<TJSONObject>('range'));
          except on E: EInvalidOpException do Rejected:=E.Message.Contains('outside the attached project'); end;
          Check(Rejected,'Navigation refuses paths outside attached project');
        finally Other.Free; end;
        Row:=Find('FirstEdit'); Other:=Find('ThirdEdit'); I:=-1;
        for Value in Report.GetValue<TJSONArray>('rows') do begin
          if Value=Row then I:=0;
          if Value=Other then Check(I=0,'Sibling rows sorted by captured TabOrder');
        end;
        CatalogPath:=TDPHWorkspaceCatalog.DefaultPath; CatalogHash:='';
        if TFile.Exists(CatalogPath) then CatalogHash:=THashSHA2.GetHashStringFromFile(CatalogPath);
        Form:=TDPHMainForm.Create(nil);
        try
          Form.PollTimer.Enabled:=False; Form.ChangeTimer.Enabled:=False;
          Form.LoadView(View.Document.Clone as TJSONObject);
          Check(Form.KeyboardList.Count=250,'Native inspector bounds each page to 250 components');
          Check(Form.KeyboardNextButton.Enabled,'Large capture enables the next page');
          Form.KeyboardFilterChange(Form.KeyboardNextButton);
          Check((Form.KeyboardList.Count=Report.GetValue<Integer>('total')-250) and not Form.KeyboardNextButton.Enabled,'Next page displays remaining components and disables at end');
          Form.KeyboardFilterChange(Form.KeyboardRefreshButton);
          Check(Form.KeyboardList.Count=250,'First page resets pagination');
          Check(Form.WorkspacePageCombo.Items.IndexOf('Keyboard and focus')>=0,'Page is discoverable through workspace selector');
          Form.KeyboardFilterEdit.Text:='SaveButton'; Form.KeyboardFilterChange(nil);
          Check(Form.KeyboardList.Count=1,'Native filter finds component');
          Check(Form.KeyboardMemo.Text.Contains('SaveAction'),'Selection explains action and source evidence');
          Check(Form.KeyboardActionButton.Enabled,'Resolved action enables action navigation');
          Form.KeyboardSourceClick(Form.KeyboardSourceButton);
          Check(Form.KeyboardMemo.Text.Contains('Source is detached'),'Detached source navigation safely refuses cached text offsets');
          Form.KeyboardFilterEdit.Text:='RemoteButton'; Form.KeyboardFilterChange(nil);
          Check(not Form.KeyboardActionButton.Enabled,'Unresolved action disables action navigation');
          Form.KeyboardFilterEdit.Text:='no such component 987'; Form.KeyboardFilterChange(nil);
          Check(Form.KeyboardList.Count=0,'No matches clears previous rows');
          Check(not Form.KeyboardActionButton.Enabled and not Form.KeyboardSourceButton.Enabled,'Empty filter results disable both source commands');
          Form.KeyboardFilterEdit.Text:='FirstEdit'; Form.KeyboardFilterChange(nil);
          Form.WorkspaceTabs.ActiveTab:=Form.KeyboardTab; Form.Show; Render('phase1-keyboard-workspace.png');
          Form.WindowState:=TWindowState.wsNormal; Form.Width:=960; Form.Height:=600;
          Render('phase1-keyboard-compact.png');
          Check(Form.KeyboardMemo.Height>=60,'Minimum-size native layout retains readable detail area');
          Check(Form.KeyboardToolbar.ShowScrollBars,'Toolbar scrolls at compact widths');
          Form.Hide;
          CopyDocument:=View.Document.Clone as TJSONObject;
          CopyDocument.GetValue<TJSONObject>('syntax').RemovePair('files').Free; CopyDocument.GetValue<TJSONObject>('syntax').AddPair('files',TJSONArray.Create);
          Form.LoadView(CopyDocument);
          Check(Form.KeyboardList.Count=0,'New capture clears old keyboard rows');
        finally Form.Free; end;
        Check((not TFile.Exists(CatalogPath) and (CatalogHash='')) or (TFile.Exists(CatalogPath) and (THashSHA2.GetHashStringFromFile(CatalogPath)=CatalogHash)),'Validation leaves user project catalog unchanged');
        Check(THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'Keys.dfm'))=BeforeHash,'Inspection leaves selected source unchanged');
        TFile.WriteAllText(TPath.Combine(Root,'docs\phase1-keyboard-validation.json'),
          TJSONObject.Create.AddPair('result','PASS').AddPair('checks',TJSONNumber.Create(Checks)).AddPair('fixture',Work)
          .AddPair('qualification','Real parser/model and instantiated FMX form validation. PaintTo renders are DPH control renders, not target-runtime screenshots.').ToJSON,TEncoding.UTF8);
      finally Report.Free; end;
    finally View.Free; end;
    Writeln('Keyboard validation passed: ',Checks,' checks.');
  except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode:=1; end; end;
end.
