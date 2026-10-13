from pathlib import Path
r=Path.cwd();p=r/'DPH.Workspace.Model.pas';s=p.read_text();a=s.index('class procedure TDPHWorkspaceView.ValidateDataQualityRecord');b=s.index('class function TDPHWorkspaceView.IsHandoffProject',a);t=s[a:b].replace('target-data data quality rule','target-data quality rule').replace('Retention metadata','Quality metadata').replace('No saved target-data policy selected','No saved target-data quality check selected');p.write_text(s[:a]+t+s[b:],encoding='utf-8')
p=r/'DPH.UI.Main.fmx';s=p.read_text().replace("Text = 'Record target-data quality rules, thresholds, owners and procedures. Import a saved check report below, then cite its section from a rule. Review claims separately. DPH does not run target checks.'","Text = 'Save target-data quality rules and source links. Import a saved report below, then cite its section. Results require human review; DPH never runs target checks.'");p.write_text(s,encoding='utf-8')
p=r/'tests/DPH.Tests.DataQuality.dpr';s=p.read_text(encoding='utf-8-sig').replace('CatalogHash,Before:string;','CatalogHash,Before,WorkspaceBefore:string;').replace('DPH.Publish.Model,DPH.Publish.Export;','DPH.Publish.Model,DPH.Publish.Export,DPH.Workspace.Worker;').replace('Denied:Boolean;','Denied:Boolean;Worker:TDPHWorkspaceWorker;Request:TDPHWorkspaceRequest;Response:TDPHWorkspaceResponse;Attempts:Integer;')
s=s.replace('Before:=View.Document.ToJSON;', 'WorkspaceBefore:=View.Document.ToJSON;',1).replace('Before:=View.Document.ToJSON;\nCheck(View.Document.ToJSON=Before,','\nCheck(View.Document.ToJSON=WorkspaceBefore,')
needle="Check(Model.Document.ToJSON.Contains('missing_ids=0'),'Publication includes imported check evidence');"
s=s.replace(needle,needle+'''TDPHPublisher.Export(Model,Store,TPath.Combine(Work,'result-handoff-'+TGUID.NewGuid.ToString));''') # replace below with fixed export directory and guarded owned prior deletion
s=s.replace("TDPHPublisher.Export(Model,Store,TPath.Combine(Work,'result-handoff-'+TGUID.NewGuid.ToString));",'''if TDirectory.Exists(TPath.Combine(Work,'result-handoff')) then begin
 RecordValue:=TJSONObject.ParseJSONValue(TFile.ReadAllText(TPath.Combine(Work,'result-handoff\\manifest.json'),TEncoding.UTF8)) as TJSONObject;
 try if RecordValue.GetValue<string>('project','')<>'Quality.dpr' then raise Exception.Create('Unrelated export directory');finally RecordValue.Free;end;
 TDirectory.Delete(TPath.Combine(Work,'result-handoff'),True);end;
 TDPHPublisher.Export(Model,Store,TPath.Combine(Work,'result-handoff'));
 TDPHPublisher.Validate(TPath.Combine(Work,'result-handoff'),Model.Document.GetValue<string>('input_fingerprint'));
 Check(True,'Imported report handoff passes full validation');
 Body:=TFile.ReadAllText(TPath.Combine(Work,'result-handoff\\index.html'),TEncoding.UTF8);
 Check(Body.Contains('missing_ids=0'),'Published HTML contains imported measurement');
 Check(Body.Contains('&lt;script&gt;do not execute&lt;/script&gt;'),'Imported markup remains escaped literal text');''')
s=s.replace(" Check(THashSHA2.GetHashStringFromFile(TPath.Combine(Work,'result.txt'))=Before",''' Worker:=TDPHWorkspaceWorker.Create(Root);try Request:=Default(TDPHWorkspaceRequest);Request.Command:='import_data_quality';Request.Database:=Store.DatabasePath;Request.GenerationID:=Generation;Request.Body:=TPath.Combine(Work,'result.txt');Request.Editor:='Worker reporter';Request.Title:='Worker controlled check';Worker.Submit(Request);Response:=nil;
 for Attempts:=1 to 1000 do begin if Worker.Poll(Response) then Break;Sleep(10);end;
 try Check((Response<>nil) and not Response.Failed,'Background check report import succeeds');Check((Response<>nil) and (Response.Knowledge<>nil),'Background import returns saved Knowledge');finally Response.Free;end;
 finally Worker.Free;end;
 Check(THashSHA2.GetHashStringFromFile(TPath.Combine(Work,'result.txt'))=Before''')
s=s.replace('legal compliance and runtime jobs remain unverified','source enforcement and imported outcomes remain unverified');p.write_text(s.rstrip()+'\n',encoding='utf-8-sig')
