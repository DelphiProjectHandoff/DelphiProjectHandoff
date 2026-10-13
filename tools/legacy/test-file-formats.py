from pathlib import Path
r=Path.cwd()
s=r'''program DPH.Tests.FileFormats;
{$APPTYPE CONSOLE}
uses System.SysUtils,System.Classes,System.IOUtils,System.JSON,System.Hash,System.StrUtils,System.UITypes,
 FMX.Forms,FMX.Graphics,DPH.Project.Analysis,DPH.Analysis.Model,DPH.Analysis.Symbols,
 DPH.Workspace.Model,DPH.Workspace.Keyboard,DPH.UI.Main,DPH.Storage.Database,DPH.Storage.Types,DPH.Analysis.Persistence,DPH.Workspace.Catalog;
var Root,Work,Fixture,SourceHash,Catalog,CatalogHash,Before,Body,Title:string;I,Checks:Integer;
 Analyzer:TDPHAnalyzer;Semantic:TDPHSemanticAnalyzer;Scan:TDPHScan;Graph:TDPHSemanticGraph;
 View,Reopened:TDPHWorkspaceView;Document,Report,Other,Row,Log:TJSONObject;V:TJSONValue;
 Store:TDPHKnowledgeStore;Config,Generation,ID:Int64;Form:TDPHMainForm;Bitmap:TBitmap;Knowledge:TJSONArray;Denied:Boolean;
procedure Check(OK:Boolean;const MessageText:string);
begin if not OK then raise Exception.Create('FAIL '+MessageText);Inc(Checks);Writeln('PASS ',Checks,': ',MessageText);Flush(Output);end;
function Find(const Name,Direction:string):TJSONObject;
var Value:TJSONValue;
begin Result:=nil;for Value in Report.GetValue<TJSONArray>('rows') do if (Value.GetValue<string>('name')=Name) and (Value.GetValue<string>('direction')=Direction) then Exit(Value as TJSONObject);end;
procedure Render(const Name:string);
begin Application.ProcessMessages;Bitmap:=TBitmap.Create(Form.ClientWidth,Form.ClientHeight);
try if Bitmap.Canvas.BeginScene then try Form.PaintTo(Bitmap.Canvas);finally Bitmap.Canvas.EndScene;end;
 Bitmap.SaveToFile(TPath.Combine(Root,'docs\'+Name));finally Bitmap.Free;end;end;
begin
 Application.Initialize;
 try
 Root:=TPath.GetFullPath(ParamStr(1));Work:=TPath.Combine(Root,'bin\file-formats-validation');Fixture:=TPath.Combine(Work,'source');TDirectory.CreateDirectory(Fixture);
 TFile.WriteAllText(TPath.Combine(Fixture,'Formats.dpr'),'program Formats; uses Main; begin end.',TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(Fixture,'Main.pas'),String.Join(sLineBreak,[
 'unit Main; interface implementation procedure Transfer; var Data,Path:string; begin',
 'Data := TFile.ReadAllText(''settings.json'',TEncoding.UTF8);',
 'Data := TFile.ReadAllText(''settings.xml'');',
 'Data := TFile.ReadAllText(''settings.ini'');',
 'TFile.WriteAllText(''output.csv'',Data,TEncoding.Unicode);',
 'TFile.WriteAllBytes(''bytes.bin'',Data);',
 'Data := TFile.ReadAllBytes(''bytes.bin'');',
 'Lines.SaveToFile(Path); Lines.LoadFromFile(Path);',
 'Data := ''SECRET_FORMAT_CANARY TFile.WriteAllText(''''fake.bad'''')'';',
 '// TFile.ReadAllLines(''comment.bad'');',
 'end; end.']),TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(Fixture,'settings.json'),'{"customer":{"id":1,"name":"SECRET_FORMAT_VALUE"},"active":true,"extra":null,"items":[]}',TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(Fixture,'settings.xml'),'<settings><account id="SECRET_XML_VALUE">SECRET_XML_TEXT</account></settings>',TEncoding.UTF8);
 TFile.WriteAllText(TPath.Combine(Fixture,'settings.ini'),'[General]'+sLineBreak+'Secret=SECRET_INI_VALUE',TEncoding.UTF8);
 SourceHash:=THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'Main.pas'));
 Analyzer:=TDPHAnalyzer.Create;Semantic:=TDPHSemanticAnalyzer.Create;
 try Scan:=Analyzer.Scan(TPath.Combine(Fixture,'Formats.dpr'),'Debug','Win32',[],[],False);
 try Graph:=Semantic.Analyze(Scan);
 try Store:=TDPHKnowledgeStore.Create(TPath.Combine(Work,'formats.dphdb'),Fixture,TPath.Combine(Root,'migrations'));
 try Store.InitializeProject('Controlled format evidence','Delphi');Config:=Store.AddConfiguration('Win32','37.0','[]','[]','Debug');Store.SelectConfiguration(Config);
 Generation:=TDPHSemanticPersistence.Stage(Scan,Graph,Store,Config);
 Document:=TDPHWorkspaceView.Capture(Scan,Graph,Generation,'Formats.dpr','Debug','Win32',[],[]);
 Store.SaveWorkspaceView(Generation,Document.ToJSON);TDPHSemanticPersistence.Publish(Scan,Graph,Store,Generation);
 View:=TDPHWorkspaceView.Create(Document);Reopened:=TDPHWorkspaceView.Create(TJSONObject.ParseJSONValue(Store.LoadWorkspaceView) as TJSONObject);
 Check(Store.IntegrityCheck='ok','Persisted fixture integrity valid');
 try Before:=View.Document.ToJSON;Report:=View.FileFormats;
 try
 TFile.WriteAllText(TPath.Combine(Work,'inventory.json'),Report.Format,TEncoding.UTF8);
 Check(Find('ReadAllText','import')<>nil,'Actual parser exposes text import candidate');
 Check(Find('WriteAllText','export')<>nil,'Actual parser exposes text export candidate');
 Check(Find('ReadAllBytes','import')<>nil,'Binary import retained');Check(Find('WriteAllBytes','export')<>nil,'Binary export retained');
 Check(Find('SaveToFile','export')<>nil,'Receiver save retained as candidate');Check(Find('LoadFromFile','import')<>nil,'Receiver load retained as candidate');
 Row:=Find('ReadAllText','import');Check(Row.GetValue<string>('encoding').StartsWith('UTF8'),'Explicit UTF8 source argument visible');
 Check(Row.GetValue<string>('format').StartsWith('.json'),'Literal filename extension retained without full path');
 Check(Row.GetValue<string>('consumer').Contains('Transfer'),'Enclosing consumer routine available');Check(Row.GetValue<string>('target_key')<>'','Routine target retains exact identity');
 Check(Find('WriteAllText','export').GetValue<string>('encoding').StartsWith('Unicode'),'Explicit Unicode output argument retained');
 Check(Find('WriteAllText','export').GetValue<string>('producer').Contains('Transfer'),'Producer routine retained');
 Check(Find('SaveToFile','export').GetValue<string>('format').StartsWith('unknown'),'Dynamic path does not invent file format');
 Check(Find('ReadAllBytes','import').GetValue<string>('encoding').StartsWith('binary'),'Byte API not assigned text encoding');
 Check(Find('settings.json','captured resource')<>nil,'Referenced JSON resource discovered');
 Check(Find('settings.json','captured resource').GetValue<string>('encoding').Contains('Captured source decoding'),'Resource encoding labeled separately from transfer contract');
 Check(Find('settings.json','captured resource').GetValue<TJSONArray>('schema').ToJSON.Contains('JSON string'),'JSON scalar types visible without values');
 Check(Find('settings.json','captured resource').GetValue<TJSONArray>('schema').ToJSON.Contains('JSON boolean'),'JSON boolean shape retained');
 Check(Find('settings.json','captured resource').GetValue<TJSONArray>('schema').ToJSON.Contains('JSON null'),'JSON null shape retained');
 Check(Find('settings.xml','captured resource').GetValue<TJSONArray>('schema').ToJSON.Contains('xml_element'),'XML element structure retained');
 Check(Find('settings.ini','captured resource').GetValue<TJSONArray>('schema').ToJSON.Contains('ini_value'),'INI key structure retained');
 Check(not Report.ToJSON.Contains('SECRET_'),'Literal values and false API text remain absent');Check(not Report.ToJSON.Contains('fake.bad'),'API text inside a string is not captured');Check(not Report.ToJSON.Contains('comment.bad'),'Comment API not captured');
 Check(Row.GetValue<string>('source_hash')=SourceHash,'Transfer evidence retains source hash');Check(Row.GetValue<Int64>('generation_id')=Generation,'Transfer evidence retains generation');
 Check(TDPHWorkspaceView.DescribeFileFormat(Row).Contains('Consumer:'),'Newcomer details expose consumer explanation');
 Check(TDPHKeyboardInspector.ReadSource(View,TPath.Combine(Fixture,'Formats.dpr'),Row,Row.GetValue<TJSONObject>('range')).Contains('procedure Transfer'),'Guarded source opens unchanged attachment');
 Denied:=False;try TDPHKeyboardInspector.ReadSource(View,'',Row,Row.GetValue<TJSONObject>('range'));except on E:EInvalidOpException do Denied:=True;end;Check(Denied,'Detached source navigation refused');
 Title:=TDPHWorkspaceView.FileFormatContractTitle(Row);Other:=Row.Clone as TJSONObject;try Other.RemovePair('source_hash').Free;Other.AddPair('source_hash','changed');Check(TDPHWorkspaceView.FileFormatContractTitle(Other)<>Title,'Changed source cannot silently inherit an old contract');finally Other.Free;end;
 Body:='Format name and version: JSON profile v1'+sLineBreak+'Encoding and BOM policy: UTF-8'+sLineBreak+'Schema: id integer; name optional string'+sLineBreak+'Producer: maintainer export'+sLineBreak+'Consumer: Transfer'+sLineBreak+'Verification: validate schema; reject malformed input';
 ID:=Store.SaveKnowledge(0,0,Generation,Title,Body,'Format author','engineering_rule',Row.GetValue<string>('target_key'),'engineering','engineer');
 Knowledge:=Store.KnowledgeJSON;try Check(Knowledge.ToJSON.Contains('JSON profile v1'),'Explicit format contract persists');Check(Knowledge.ToJSON.Contains('Format author'),'Contract contributor attribution persists');Check(Knowledge.ToJSON.Contains('needs_review'),'Saved contract requires human review');finally Knowledge.Free;end;
 Check(View.Document.ToJSON=Before,'Inspector leaves captured workspace unchanged');Other:=Reopened.FileFormats;try Check(Other.ToJSON=Report.ToJSON,'Persisted reopening yields identical format evidence');finally Other.Free;end;
 Catalog:=TDPHWorkspaceCatalog.DefaultPath;CatalogHash:='';if TFile.Exists(Catalog) then CatalogHash:=THashSHA2.GetHashStringFromFile(Catalog);
 Form:=TDPHMainForm.Create(nil);
 try Form.PollTimer.Enabled:=False;Form.ChangeTimer.Enabled:=False;Form.LoadView(View.Document.Clone as TJSONObject);Form.LoadKnowledge(Store.KnowledgeJSON);
 Form.FileFormatsKind.ItemIndex:=1;Form.FileFormatsFilter.Text:='ReadAllText';Form.FileFormatsFilterChange(nil);
 Check(Form.FileFormatsList.Count>=1,'Native filters expose import candidates');Check(Form.FileFormatsMemo.Text.Contains('SAVED CONTRACT'),'Native inspector shows matching saved contract');
 Check(Form.FileFormatsExplain.Enabled,'Native routine navigation available');Form.FileFormatsExplainClick(nil);Check(Form.WorkspaceTabs.ActiveTab=Form.ExplainTab,'Explain opens enclosing captured routine');
 Form.FileFormatsSourceClick(nil);Check(Form.FileFormatsMemo.Text.Contains('detached'),'Native source refusal explains missing attachment');
 Form.FileFormatsContractClick(nil);Check(Form.WorkspaceTabs.ActiveTab=Form.KnowledgeTab,'Existing contract opens immutable Knowledge workflow');
 Form.FileFormatsKind.ItemIndex:=2;Form.FileFormatsFilter.Text:='WriteAllText';Form.FileFormatsFilterChange(nil);Form.FileFormatsContractClick(nil);
 Check(Form.KnowledgeBodyMemo.Text.Contains('Schema / required'),'New contract template includes schema fields');Check(Form.KnowledgeBodyMemo.Text.Contains('Encoding and BOM'),'New contract template includes encoding policy');Check(Form.KnowledgeBodyMemo.Text.Contains('Validation, malformed input'),'New contract template includes failure behavior');
 Form.DiscardKnowledgeClick(nil);Form.WorkspaceTabs.ActiveTab:=Form.FileFormatsTab;Form.Show;Render('phase1-file-formats-workspace.png');
 Form.WindowState:=TWindowState.wsNormal;Form.Width:=960;Form.Height:=600;Render('phase1-file-formats-compact.png');
 Check(Form.FileFormatsMemo.Height>=50,'Compact evidence area readable');Check(Form.FileFormatsMemo.ShowScrollBars,'Long details scroll');Check(Form.FileFormatsToolbar.ShowScrollBars,'Compact commands scroll horizontally');
 Form.FileFormatsFilter.Text:='nonexistent';Form.FileFormatsFilterChange(nil);Check(Form.FileFormatsMemo.Text.Contains('Empty results do not prove'),'Empty result explains unknown transfers');Form.Hide;
 finally Form.Free;end;
 Check((not TFile.Exists(Catalog) and (CatalogHash='')) or (TFile.Exists(Catalog) and (THashSHA2.GetHashStringFromFile(Catalog)=CatalogHash)),'Owner catalog unchanged');Check(THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'Main.pas'))=SourceHash,'Target source unchanged');
 Log:=TJSONObject.Create.AddPair('result','PASS').AddPair('checks',TJSONNumber.Create(Checks)).AddPair('qualification','Controlled captured format candidates, resource shape, attributed contracts and native FMX workflows. Runtime transfers unobserved.');try TFile.WriteAllText(TPath.Combine(Root,'docs\phase1-file-formats-validation.json'),Log.Format,TEncoding.UTF8);finally Log.Free;end;
 finally Report.Free;end;finally Reopened.Free;View.Free;end;
 finally Store.Free;end;finally Graph.Free;end;finally Scan.Free;end;finally Semantic.Free;Analyzer.Free;end;
 except on E:Exception do begin Writeln(E.ClassName,': ',E.Message);ExitCode:=1;end;end;
end.
'''
(r/'tests/DPH.Tests.FileFormats.dpr').write_text(s,encoding='utf-8')
s=(r/'tools/build-schema-history.cmd').read_text().replace('SchemaHistory','FileFormats');(r/'tools/build-file-formats.cmd').write_text(s,encoding='utf-8')
