program DPH.Tests.DatabaseDictionary;
{$APPTYPE CONSOLE}
uses System.SysUtils,System.Classes,System.IOUtils,System.JSON,System.Hash,System.Types,System.UITypes,
 FMX.Types,FMX.Forms,FMX.Graphics,FMX.Memo,DPH.Project.Analysis,DPH.Analysis.Model,DPH.Analysis.Symbols,
 DPH.Analysis.Persistence,DPH.Storage.Database,DPH.Storage.Types,DPH.Workspace.Model,
 DPH.Workspace.DatabaseSchema,DPH.UI.DatabaseDictionary,DPH.UI.Main,DPH.Publish.Model;
type TApplyTimer=class(TTimer)
 procedure Apply(Sender:TObject);
end;
var ApplyTimer:TApplyTimer;
var Root,Work,SourceRoot,Original,Before,Key,PurposeText:string;Checks,I:Integer;
 Store:TDPHKnowledgeStore;Analyzer:TDPHAnalyzer;Semantic:TDPHSemanticAnalyzer;Scan:TDPHScan;Graph:TDPHSemanticGraph;
 View:TDPHWorkspaceView;Inventory,TableRow,ColumnRow,RecordValue,Other,Saved,Fields,Report:TJSONObject;
 Knowledge:TJSONArray;V:TJSONValue;Config,Generation,ID,Revision,OldRevision:Int64;
 Failed:Boolean;Editor:TDPHDatabaseDictionaryForm;Form:TDPHMainForm;Bitmap:TBitmap;Model:TDPHDocumentModel;
procedure TApplyTimer.Apply(Sender:TObject);
var E:TDPHDatabaseDictionaryForm;J:Integer;
begin
 for J:=0 to Screen.FormCount-1 do if Screen.Forms[J] is TDPHDatabaseDictionaryForm then begin
 E:=Screen.Forms[J] as TDPHDatabaseDictionaryForm;Enabled:=False;E.ProfileAuthorEdit.Text:='Native draft editor';E.Profile_definition.Text:='Draft via native schema command';E.ApplyProfileClick(nil);Exit;end;
end;
procedure Check(OK:Boolean;const Text:string);
begin if not OK then raise Exception.Create('FAIL '+Text);Inc(Checks);Writeln('PASS ',Checks,': ',Text);Flush(Output);end;
procedure Put(R:TJSONObject;const K,Text:string);
begin R.GetValue<TJSONObject>('fields').RemovePair(K).Free;R.GetValue<TJSONObject>('fields').AddPair(K,Text);end;
function Save(R:TJSONObject;AID,ARevision:Int64;const Author:string='Dictionary contributor'):Int64;
begin Result:=Store.SaveKnowledge(AID,ARevision,Generation,TDPHDatabaseSchema.DictionaryTitle(R),TDPHDatabaseSchema.DictionaryBody(R),Author,'business_rule','','overview','all','','',R.ToJSON);end;
function Current:TJSONObject;
var A:TJSONArray;X:TJSONValue;
begin Result:=nil;A:=Store.KnowledgeJSON;try for X in A do if X.GetValue<string>('id')=IntToStr(ID) then Exit(X.Clone as TJSONObject);finally A.Free;end;end;
procedure RefuseRecord(R:TJSONObject;const Text:string);
begin Failed:=False;try TDPHDatabaseSchema.ValidateDictionary(R);except Failed:=True;end;Check(Failed,Text);end;
procedure Render(AForm:TForm;const Name:string);
begin Application.ProcessMessages;Bitmap:=TBitmap.Create(AForm.ClientWidth,AForm.ClientHeight);
 try if Bitmap.Canvas.BeginScene then try AForm.PaintTo(Bitmap.Canvas);finally Bitmap.Canvas.EndScene;end;
 Bitmap.SaveToFile(TPath.Combine(Root,'docs\'+Name));finally Bitmap.Free;end;end;
begin
 Application.Initialize;
 try
 Root:=TPath.GetFullPath(ParamStr(1));Work:=TPath.Combine(Root,'bin\database-dictionary-validation');SourceRoot:=TPath.Combine(Work,'source');TDirectory.CreateDirectory(SourceRoot);
 for Key in ['dictionary.dphdb','dictionary.dphdb-wal','dictionary.dphdb-shm'] do if TFile.Exists(TPath.Combine(Work,Key)) then TFile.Delete(TPath.Combine(Work,Key));
 TFile.WriteAllText(TPath.Combine(SourceRoot,'Dictionary.dpr'),'program Dictionary; uses Main; begin end.',TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(SourceRoot,'Main.pas'),'unit Main; interface implementation procedure Load; begin TFile.ReadAllText(''schema.sql''); end; end.',TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(SourceRoot,'schema.sql'),'CREATE TABLE Sales.Invoice (id INTEGER PRIMARY KEY, amount NUMERIC(12,2));'+sLineBreak+'CREATE TABLE Sales.Invoice (alternate INTEGER);'+sLineBreak+'SELECT id FROM Missing;',TEncoding.UTF8);
 Original:=THashSHA2.GetHashStringFromFile(TPath.Combine(SourceRoot,'schema.sql'));
 Store:=TDPHKnowledgeStore.Create(TPath.Combine(Work,'dictionary.dphdb'),SourceRoot,TPath.Combine(Root,'migrations'));
 Analyzer:=TDPHAnalyzer.Create;Semantic:=TDPHSemanticAnalyzer.Create;
 try
 Store.InitializeProject('Dictionary controlled practice','Delphi');Config:=Store.AddConfiguration('Win32','37.0','[]','[]','Debug');Store.SelectConfiguration(Config);
 Scan:=Analyzer.Scan(TPath.Combine(SourceRoot,'Dictionary.dpr'),'Debug','Win32',[],[],False);
 try Graph:=Semantic.Analyze(Scan);try Generation:=TDPHSemanticPersistence.Stage(Scan,Graph,Store,Config);
 View:=TDPHWorkspaceView.Create(TDPHWorkspaceView.Capture(Scan,Graph,Generation,'Dictionary.dpr','Debug','Win32',[],[]));
 Store.SaveWorkspaceView(Generation,View.Document.ToJSON);TDPHSemanticPersistence.Publish(Scan,Graph,Store,Generation);
 finally Graph.Free;end;finally Scan.Free;end;
 try Inventory:=TDPHDatabaseSchema.Inspect(View);try
 TableRow:=nil;ColumnRow:=nil;for V in Inventory.GetValue<TJSONArray>('rows') do begin
 if (V.GetValue<string>('kind')='table') and (TableRow=nil) then TableRow:=V as TJSONObject;
 if V.GetValue<string>('name')='Sales.Invoice.amount' then ColumnRow:=V as TJSONObject;end;
 Check((TableRow<>nil) and (ColumnRow<>nil),'Actual project SQL capture provides exact table and column targets');
 Before:=View.Document.ToJSON;RecordValue:=TDPHDatabaseSchema.NewDictionary(ColumnRow);
 try
 Fields:=RecordValue.GetValue<TJSONObject>('fields');
 Check((Fields.GetValue<string>('source_hash')=Original) and (Fields.GetValue<string>('schema_id')=ColumnRow.GetValue<string>('id')),'Dictionary pins the exact captured bytes and column declaration');
 Check((Fields.GetValue<string>('table')='Sales.Invoice') and (Fields.GetValue<string>('generation')=IntToStr(Generation)),'Dictionary retains owning table and original generation');
 RefuseRecord(RecordValue,'Blank business definition owner sensitivity and evidence require explicit unknowns');
 Put(RecordValue,'definition','Invoice amount before tax; <script>literal authored text</script>.');Put(RecordValue,'business_owner','Finance steward; synthetic practice claim');Put(RecordValue,'sensitivity','Internal financial information; synthetic practice claim');Put(RecordValue,'evidence','Controlled fixture. Production business rules remain unknown.');Put(RecordValue,'usage','Currency units are unknown; ask the finance steward.');
 TDPHDatabaseSchema.ValidateDictionary(RecordValue);Check(TDPHDatabaseSchema.DictionaryBody(RecordValue).Contains('Saving does not verify'),'Business claims retain explicit unverified qualification');
 Check(TDPHDatabaseSchema.DictionaryBody(RecordValue).Contains('Currency units are unknown'),'Optional units and usage are described');
 for Key in ['definition','business_owner','sensitivity','evidence'] do begin Other:=RecordValue.Clone as TJSONObject;try Put(Other,Key,' ');RefuseRecord(Other,'Required '+Key+' cannot be whitespace');finally Other.Free;end;end;
 Other:=RecordValue.Clone as TJSONObject;try Put(Other,'dictionary_id','schema:forged');RefuseRecord(Other,'Forged anchor digest rejected');finally Other.Free;end;
 Other:=RecordValue.Clone as TJSONObject;try Put(Other,'source_hash',StringOfChar('z',64));RefuseRecord(Other,'Invalid SHA256 alphabet rejected');finally Other.Free;end;
 for Key in ['generation','source_line'] do begin Other:=RecordValue.Clone as TJSONObject;try Put(Other,Key,'0');RefuseRecord(Other,'Nonpositive '+Key+' rejected');finally Other.Free;end;end;
 Other:=RecordValue.Clone as TJSONObject;try Put(Other,'kind','view');RefuseRecord(Other,'Inferred or unsupported object kind cannot become a dictionary target');finally Other.Free;end;
 Other:=RecordValue.Clone as TJSONObject;try Other.AddPair('unexpected','x');RefuseRecord(Other,'Unknown record metadata rejected');finally Other.Free;end;
 Other:=RecordValue.Clone as TJSONObject;try Other.GetValue<TJSONObject>('fields').AddPair('unexpected','x');RefuseRecord(Other,'Unknown field rejected');finally Other.Free;end;
 Other:=RecordValue.Clone as TJSONObject;try Other.GetValue<TJSONObject>('fields').RemovePair('usage').Free;RefuseRecord(Other,'Missing structured field rejected');finally Other.Free;end;
 Other:=RecordValue.Clone as TJSONObject;try Other.GetValue<TJSONObject>('fields').RemovePair('definition').Free;Other.GetValue<TJSONObject>('fields').AddPair('definition',TJSONNumber.Create(1));RefuseRecord(Other,'Nontext definition rejected');finally Other.Free;end;
 Other:=RecordValue.Clone as TJSONObject;try Put(Other,'usage',StringOfChar('x',4097));RefuseRecord(Other,'Oversized field rejected');finally Other.Free;end;
 Failed:=False;try Save(RecordValue,0,0,'');except Failed:=True;end;Check(Failed,'Anonymous contributor rejected');
 Other:=RecordValue.Clone as TJSONObject;try Put(Other,'name','Invented name');Failed:=False;try Save(Other,0,0);except Failed:=True;end;Check(Failed,'New target name must match the actual persisted capture');finally Other.Free;end;
 Other:=RecordValue.Clone as TJSONObject;try Put(Other,'source_line','999');Failed:=False;try Save(Other,0,0);except Failed:=True;end;Check(Failed,'New source line must match the actual persisted capture');finally Other.Free;end;
 ID:=Save(RecordValue,0,0);Saved:=Current;try Revision:=StrToInt64(Saved.GetValue<string>('revision'));Check(Saved.GetValue<string>('state')='needs_review','Saved business dictionary starts pending named review');Check(Saved.GetValue<string>('owner')='Dictionary contributor','Named business contributor persists');finally Saved.Free;end;
 Failed:=False;try Save(RecordValue,0,0);except Failed:=True;end;Check(Failed,'Duplicate dictionary anchor rejected');
 Failed:=False;try Store.SaveKnowledge(ID,Revision,Generation,TDPHDatabaseSchema.DictionaryTitle(RecordValue),'Conflicting body','Editor','business_rule','','overview','all','','',RecordValue.ToJSON);except Failed:=True;end;Check(Failed,'Conflicting plain body cannot bypass structured definition');
 Failed:=False;try Store.SaveKnowledge(ID,Revision,Generation,TDPHDatabaseSchema.DictionaryTitle(RecordValue),TDPHDatabaseSchema.DictionaryBody(RecordValue),'Editor','business_rule','','overview','all');except Failed:=True;end;Check(Failed,'Structured fields cannot be discarded');
 Store.ReviewKnowledge(ID,Revision,Generation,'Dictionary reviewer','verified');OldRevision:=Revision;Saved:=Current;try Revision:=StrToInt64(Saved.GetValue<string>('revision'));finally Saved.Free;end;Put(RecordValue,'definition','Revised amount before tax; includes approved adjustments.');Save(RecordValue,ID,Revision,'Revision editor');Saved:=Current;
 try Revision:=StrToInt64(Saved.GetValue<string>('revision'));Check(Saved.GetValue<string>('state')='needs_review','Definition edit reopens human review');Check((Saved.GetValue<string>('owner')='Dictionary contributor') and (Saved.GetValue<string>('editor')='Revision editor'),'Original contributor and revision editor remain distinct');Check(Saved.GetValue<TJSONArray>('history').Count>=3,'Authored and review history retained');finally Saved.Free;end;
 Failed:=False;try Store.ReviewKnowledge(ID,OldRevision,Generation,'Old reviewer','verified');except Failed:=True;end;Check(Failed,'Stale revision cannot be reviewed');
 Other:=RecordValue.Clone as TJSONObject;try Put(Other,'name','Changed name');Failed:=False;try Save(Other,ID,Revision);except Failed:=True;end;Check(Failed,'Existing captured name identity cannot change');finally Other.Free;end;
 Other:=RecordValue.Clone as TJSONObject;try Put(Other,'generation',IntToStr(Generation+1));Failed:=False;try Save(Other,ID,Revision);except Failed:=True;end;Check(Failed,'Original capture generation cannot change');finally Other.Free;end;
 Other:=TDPHDatabaseSchema.NewDictionary(TableRow);try Put(Other,'definition','Synthetic invoice table');Put(Other,'business_owner','Unknown; ask owner');Put(Other,'sensitivity','Unknown; requires review');Put(Other,'evidence','Practice fixture, not production facts');Check(Save(Other,0,0)>0,'Table dictionary is separate from its column dictionary');finally Other.Free;end;
 Knowledge:=Store.KnowledgeJSON;try
 Check(TDPHDatabaseSchema.FindDictionary(Knowledge,ColumnRow)<>nil,'Exact captured column retrieves its dictionary');
 Other:=ColumnRow.Clone as TJSONObject;try Other.RemovePair('source_hash').Free;Other.AddPair('source_hash',StringOfChar('a',64));Check(TDPHDatabaseSchema.FindDictionary(Knowledge,Other)=nil,'Changed source bytes do not inherit old definition');Check(TDPHDatabaseSchema.FindDictionary(Knowledge,Other,True)<>nil,'Old definition remains explicitly historical');finally Other.Free;end;
 Model:=TDPHDocumentModel.Create(View,Knowledge,[],[],False,False);try Check(Model.Document.GetValue<TJSONArray>('knowledge').Count=2,'Generic handoff publication includes attributed table and column definitions');finally Model.Free;end;
 Model:=TDPHDocumentModel.Create(View,Knowledge,[],['schema.sql'],False,False);try Check(Model.Document.GetValue<TJSONArray>('knowledge').Count=0,'Excluded SQL source excludes its dictionary definitions');finally Model.Free;end;
 Other:=TJSONObject.ParseJSONValue(Knowledge.Items[0].GetValue<string>('structured_json')) as TJSONObject;try Put(Other,'source_hash',StringOfChar('a',64));(Knowledge.Items[0] as TJSONObject).RemovePair('structured_json').Free;(Knowledge.Items[0] as TJSONObject).AddPair('structured_json',Other.ToJSON);finally Other.Free;end;
 Model:=TDPHDocumentModel.Create(View,Knowledge,[],[],False,False);try Check(Model.Document.GetValue<TJSONArray>('knowledge').Count=1,'Handoff omits a dictionary whose captured source bytes differ');finally Model.Free;end;
 finally Knowledge.Free;end;
 Editor:=TDPHDatabaseDictionaryForm.Create(nil);try Editor.LoadRecord(RecordValue,'Named editor');PurposeText:=Editor.ProfilePurpose.Text;
 for I:=0 to 8 do Check((Editor.FindComponent('Profile_'+DPHDictionaryKeys[I]) as TMemo).ReadOnly,'Captured '+DPHDictionaryKeys[I]+' is IDE-serialized read only');
 Check(not Editor.Profile_definition.ReadOnly and not Editor.Profile_sensitivity.ReadOnly,'Business fields are editable');
 Other:=Editor.RecordJSON;try for Key in DPHDictionaryKeys do Check(Other.GetValue<string>('fields.'+Key)=RecordValue.GetValue<string>('fields.'+Key),'Serialized editor round trips '+Key);finally Other.Free;end;
 Editor.ProfileAuthorEdit.Text:='';Editor.ApplyProfileClick(nil);Check(Editor.ModalResult<>mrOk,'Editor refuses anonymous Apply');Editor.ProfileAuthorEdit.Text:='Named editor';Editor.ApplyProfileClick(nil);Check(Editor.ModalResult=mrOk,'Editor accepts validated attributed dictionary');
 Editor.ProfilePurpose.Text:=PurposeText;Editor.ModalResult:=0;Editor.Show;Render(Editor,'phase1-database-dictionary-editor.png');Editor.ProfileScroll.ViewportPosition:=PointF(0,610);Application.ProcessMessages;Render(Editor,'phase1-database-dictionary-fields.png');Editor.Width:=640;Editor.Height:=500;Editor.ProfileScroll.ViewportPosition:=PointF(0,0);Render(Editor,'phase1-database-dictionary-editor-compact.png');Editor.Hide;
 finally Editor.Free;end;
 Form:=TDPHMainForm.Create(nil);try Form.PollTimer.Enabled:=False;Form.ChangeTimer.Enabled:=False;Form.LoadView(View.Document.Clone as TJSONObject);Form.LoadKnowledge(Store.KnowledgeJSON);Form.DatabaseSchemaFilter.Text:='Sales.Invoice.amount';Form.DatabaseSchemaFilterChange(nil);Form.WorkspaceTabs.ActiveTab:=Form.DatabaseSchemaTab;
 Check(Form.DatabaseDictionaryEdit.Enabled and Form.DatabaseDictionaryKnowledge.Enabled,'Captured column exposes edit and dictionary-history commands');Check(Form.DatabaseSchemaMemo.Text.Contains('Revised amount before tax'),'Schema details display attributed business meaning');Form.DatabaseSchemaFilter.Text:='approved adjustments';Form.DatabaseSchemaFilterChange(nil);Check(Form.DatabaseSchemaList.Count=1,'Schema search finds business definitions');
 ApplyTimer:=TApplyTimer.Create(nil);ApplyTimer.Interval:=100;ApplyTimer.OnTimer:=ApplyTimer.Apply;ApplyTimer.Enabled:=True;
 try Form.DatabaseDictionaryEditClick(nil);finally ApplyTimer.Free;end;Check((Form.WorkspaceTabs.ActiveTab=Form.KnowledgeTab) and Form.KnowledgeBodyMemo.Text.Contains('Draft via native schema command'),'Native edit and Apply create the attributed Knowledge draft');
 Check(Form.StatusLabel.Text.Contains('Click Save'),'Native draft explicitly requires Save before persistence');
 Saved:=Current;try Check(not Saved.GetValue<string>('body').Contains('Draft via native'),'Applying editor does not silently save or verify');finally Saved.Free;end;
 Form.DiscardKnowledgeClick(nil);Form.DatabaseDictionaryKnowledgeClick(nil);Check((Form.WorkspaceTabs.ActiveTab=Form.KnowledgeTab) and Form.KnowledgeBodyMemo.ReadOnly,'Open dictionary history uses protected structured Knowledge view');Check(Form.KnowledgeHistoryMemo.Text.Contains('Immutable revision history'),'Dictionary history and review are visible');
 Form.WorkspaceTabs.ActiveTab:=Form.DatabaseSchemaTab;Form.Show;Form.WindowState:=TWindowState.wsMaximized;Form.DatabaseSchemaToolbar.ViewportPosition:=PointF(1400,0);Render(Form,'phase1-database-dictionary-workspace.png');Form.WindowState:=TWindowState.wsNormal;Form.Width:=960;Form.Height:=600;Form.DatabaseSchemaToolbar.ViewportPosition:=PointF(1550,0);Render(Form,'phase1-database-dictionary-compact.png');Form.Hide;
 Form.DatabaseSchemaFilter.Text:='Missing';Form.DatabaseSchemaFilterChange(nil);Check(not Form.DatabaseDictionaryEdit.Enabled,'Inferred SQL reference does not enable dictionary creation');
 finally Form.Free;end;
 Check(View.Document.ToJSON=Before,'Dictionary editing leaves captured workspace immutable');Check(THashSHA2.GetHashStringFromFile(TPath.Combine(SourceRoot,'schema.sql'))=Original,'Dictionary editing leaves target SQL unchanged');
 Store.Free;Store:=TDPHKnowledgeStore.Create(TPath.Combine(Work,'dictionary.dphdb'),SourceRoot,TPath.Combine(Root,'migrations'));Saved:=Current;try Check(Saved.GetValue<string>('body').Contains('Revised amount before tax'),'Dictionary survives SQLite reopen');finally Saved.Free;end;
 Report:=TJSONObject.Create.AddPair('result','PASS').AddPair('checks',TJSONNumber.Create(Checks)).AddPair('requirement','05.09').AddPair('qualification','Business meanings, ownership and sensitivity are attributed human claims with independent review state; exact captured schema links do not establish a live schema or business truth. No target SQL executes.');
 try TFile.WriteAllText(TPath.Combine(Root,'docs\phase1-database-dictionary-validation.json'),Report.Format,TEncoding.UTF8);finally Report.Free;end;
 finally RecordValue.Free;end;
 finally Inventory.Free;end;finally View.Free;end;
 finally Store.Free;Semantic.Free;Analyzer.Free;end;
 Writeln('Database dictionary validation passed: ',Checks,' checks.');
 except on E:Exception do begin Writeln(E.ClassName,': ',E.Message);ExitCode:=1;end;end;
end.
