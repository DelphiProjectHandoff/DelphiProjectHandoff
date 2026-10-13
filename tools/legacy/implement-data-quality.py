from pathlib import Path
r=Path.cwd()
def transform(s):
 return s.replace('DataRetentionPolicy','DataQualityRule').replace('DataRetentionRecord','DataQualityRecord').replace('DataRetention','DataQuality').replace('data_retention','data_quality').replace('policy_id','rule_id').replace('TARGET DATA RETENTION AND ARCHIVAL POLICY','TARGET DATA QUALITY AND INTEGRITY CHECK').replace('retention policy','data quality rule').replace('Retention policy','Quality check').replace('target-data retention','target-data quality').replace('retention obligations','data quality checks').replace('saved policies','saved checks').replace('New policy','New check').replace('Open policy','Open check').replace('policy fields','check fields').replace('policy body','check body').replace('another policy','another check').replace('starting a retention policy','starting a quality check').replace('policy selection','check selection').replace('policy identity','check identity').replace('retention requirements','quality requirements').replace('retention rules','quality rules')
p=r/'DPH.Workspace.Model.pas';s=p.read_text(encoding='utf-8-sig');start=s.index('class function TDPHWorkspaceView.NewDataRetentionPolicy');end=s.index('class function TDPHWorkspaceView.IsHandoffProject',start);block=transform(s[start:end]);a=block.index('class function TDPHWorkspaceView.NewDataQualityRule');b=block.index('class function TDPHWorkspaceView.IsDataQualityRule',a)
block=block[:a]+'''class function TDPHWorkspaceView.NewDataQualityRule:string;
begin
 Result:='TARGET DATA QUALITY AND INTEGRITY CHECK'+sLineBreak+
  'Selected-application data requirements and attributed results. Unknown means unresolved. Do not enter credentials or customer records.'+sLineBreak+sLineBreak+
  'Check name, version and purpose: Unknown'+sLineBreak+
  'Data scope, tables/fields/files and environment: Unknown'+sLineBreak+
  'Quality dimension (completeness, uniqueness, validity, consistency, freshness or referential integrity): Unknown'+sLineBreak+
  'Rule, threshold, units and expected outcome: Unknown'+sLineBreak+
  'Prerequisites, sampling, exclusions and limitations: Unknown'+sLineBreak+
  'Check procedure, implementing routine and schedule: Unknown'+sLineBreak+
  'Owner, operator and review responsibility: Unknown'+sLineBreak+
  'Failure severity, remediation and escalation: Unknown'+sLineBreak+
  'Observed result, counts, measurement time and environment: Unknown'+sLineBreak+
  'Result evidence, contributor and verification method: Unknown'+sLineBreak+
  'Remaining unknowns and responsible maintainer: Unknown'+sLineBreak+sLineBreak+
  'Use Knowledge links to cite captured routines, constraints and exact procedure or imported report revisions. Import check report saves an attributed UTF-8 text extract as another quality record; link it as a section. A written name alone is not a resolved link.'+sLineBreak+
  'Qualification: DPH never runs checks, SQL or the selected application. Source constraints are captured declarations, not proof of live data quality. Imported outcomes and timestamps remain contributor claims. DPH database integrity is separate.';
end;
'''+block[b:]
s=s[:end]+block+s[end:];decl=s[s.index('    class function NewDataRetentionPolicy'):s.index('    function FileFormats')];s=s.replace(decl,decl+transform(decl),1);p.write_text(s,encoding='utf-8')
p=r/'DPH.Storage.Database.pas';s=p.read_text(encoding='utf-8-sig');a=s.index("      end else if StructuredValue.GetValue<string>('record_type','')='data_retention'");b=s.index("      end else if StructuredValue.GetValue<string>('record_type','')='data_dictionary'",a);s=s[:b]+transform(s[a:b])+s[b:]
s=s.replace('    procedure ImportObservation(', '    function ImportDataQualityReport(AGenerationID:Int64;const AFile,AAuthor,AContext:string):Int64;\n    procedure ImportObservation(',1)
code='''function TDPHKnowledgeStore.ImportDataQualityReport(AGenerationID:Int64;const AFile,AAuthor,AContext:string):Int64;
var Bytes,RoundTrip:TBytes;Encoding:TUTF8Encoding;Content,Body,Hash:string;RecordValue:TJSONObject;
begin
 RequireWriter;
 if (AAuthor.Trim='') or (AContext.Trim='') or (Length(AAuthor)>256) or (Length(AContext)>4096) then raise EDPHStorage.Create('Enter a named report contributor and check/environment context (up to 256/4096 characters)');
 if not MatchText(ExtractFileExt(AFile),['.txt','.log','.json']) then raise EDPHStorage.Create('Select a saved UTF-8 .txt, .log or .json check extract');
 if TFile.GetSize(AFile)>32768 then raise EDPHStorage.Create('Check report exceeds 32 KiB; select a focused extract');
 Bytes:=TFile.ReadAllBytes(AFile);
 if (Length(Bytes)=0) or (Length(Bytes)>32768) then raise EDPHStorage.Create('Check report is empty or exceeds 32 KiB');
 Encoding:=TUTF8Encoding.Create(False);
 try Content:=Encoding.GetString(Bytes);RoundTrip:=Encoding.GetBytes(Content);finally Encoding.Free;end;
 if (Length(RoundTrip)<>Length(Bytes)) or not CompareMem(@RoundTrip[0],@Bytes[0],Length(Bytes)) then raise EDPHStorage.Create('Check report must be valid round-trip UTF-8');
 if Content.StartsWith(Char($FEFF)) then Delete(Content,1,1);
 if (Content.Trim='') or ContainsStr(Content,#0) then raise EDPHStorage.Create('Check report must contain text without NUL');
 Hash:=THashSHA2.GetHashString(Bytes);
 Body:=TDPHWorkspaceView.NewDataQualityRule+sLineBreak+sLineBreak+
  'IMPORTED CHECK REPORT - CONTRIBUTOR CLAIM UNVERIFIED'+sLineBreak+
  'Report context: '+AContext+sLineBreak+'Report contributor: '+AAuthor+sLineBreak+
  'Imported UTC: '+UTCNow+sLineBreak+'Captured generation: '+IntToStr(AGenerationID)+sLineBreak+
  'Original extract SHA256: '+Hash+sLineBreak+
  'Saved text below is literal evidence; no commands, SQL, scripts or markup are executed. Report origin, measurements, timestamps and environment are contributor claims. Named review remains separate.'+sLineBreak+sLineBreak+Content;
 RecordValue:=TJSONObject.Create.AddPair('record_type','data_quality').AddPair('rule_id',TGUID.NewGuid.ToString);
 try Result:=SaveKnowledge(0,0,AGenerationID,'Imported check report: '+AContext,Body,AAuthor,'business_rule','','maintenance','maintainer','','',RecordValue.ToJSON);finally RecordValue.Free;end;
end;
'''
s=s.replace('procedure TDPHKnowledgeStore.ImportObservation',code+'procedure TDPHKnowledgeStore.ImportObservation',1);p.write_text(s,encoding='utf-8')
p=r/'DPH.UI.Main.pas';s=p.read_text(encoding='utf-8-sig');a=s.index('    DataRetentionTab:');b=s.index('    FileFormatsTab:',a);s=s[:b]+transform(s[a:b])+'''    DataQualityImport:TButton;
    DataQualityImportToolbar:THorzScrollBox;
    DataQualityContributor,DataQualityContext:TEdit;
    procedure DataQualityImportClick(Sender:TObject);
'''+s[b:];a=s.index('    procedure DataRetentionFilterChange');b=s.index('    procedure FileFormatsContractClick',a);s=s[:b]+transform(s[a:b])+s[b:];s=s.replace('    FDataRetentionRows:TList<TJSONObject>;','    FDataQualityRows:TList<TJSONObject>;\n    FDataQualityOffset:Integer;\n    FDataRetentionRows:TList<TJSONObject>;',1)
s=s.replace('FDataRetentionRows:=TList<TJSONObject>.Create;', 'FDataRetentionRows:=TList<TJSONObject>.Create;FDataQualityRows:=TList<TJSONObject>.Create;',1).replace('FDataRetentionRows.Free;', 'FDataQualityRows.Free;FDataRetentionRows.Free;',1).replace('DataRetentionFilterChange(nil);','DataRetentionFilterChange(nil);DataQualityFilterChange(nil);')
a=s.index('procedure TDPHMainForm.DataRetentionFilterChange');b=s.index('procedure TDPHMainForm.FileFormatsContractClick',a);s=s[:b]+transform(s[a:b])+'''procedure TDPHMainForm.DataQualityImportClick(Sender:TObject);
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
'''+s[b:]
s=s.replace("and not TDPHWorkspaceView.IsDataRetentionPolicy(Row);","and not TDPHWorkspaceView.IsDataRetentionPolicy(Row) and not TDPHWorkspaceView.IsDataQualityRule(Row);",1);s=s.replace('DataQualityNew.Enabled:=FView<>nil;', 'DataQualityNew.Enabled:=FView<>nil;DataQualityImport.Enabled:=FView<>nil;',1)
p.write_text(s,encoding='utf-8')
p=r/'DPH.UI.Main.fmx';s=p.read_text(encoding='utf-8-sig');a=s.index('object DataRetentionTab:');b=s.index('object FileFormatsTab:',a);block=transform(s[a:b]);block=block.replace("Text = 'Target data retention'","Text = 'Target data quality'").replace("Text = 'Record the selected application''s retention and archival rules. New check prepares an attributed Knowledge draft. Link implementing routines or procedures; review the policy separately. No target job runs.'","Text = 'Record target-data quality rules, thresholds, owners and procedures. Import a saved check report below, then cite its section from a rule. Review claims separately. DPH does not run target checks.'").replace("TextPrompt = 'Find policy, scope, owner or job'","TextPrompt = 'Find check, scope, owner or result'").replace("Text = 'Saved policy, attribution and review state (scroll for details)'","Text = 'Saved check, imported results and review state (scroll for details)'")
insert='''object DataQualityImportToolbar: THorzScrollBox
Align = Top
Height = 44
ShowScrollBars = True
object DataQualityContributor: TEdit
Position.X = 12
Width = 190
Height = 28
TextPrompt = 'Report contributor name'
end
object DataQualityContext: TEdit
Position.X = 210
Width = 340
Height = 28
TextPrompt = 'Check name, environment and measurement context'
end
object DataQualityImport: TButton
Position.X = 558
Width = 150
Height = 28
Text = 'Import check report'
OnClick = DataQualityImportClick
end
end
'''
block=block.replace('object DataQualityStatus:',insert+'object DataQualityStatus:',1);s=s[:b]+block+s[b:];s=s.replace("'Target data retention'\n","'Target data retention'\n'Target data quality'\n",1);p.write_text(s,encoding='utf-8')
p=r/'DPH.Workspace.Worker.pas';s=p.read_text();s=s.replace("'import_observation','translate'","'import_observation','import_data_quality','translate'",1);s=s.replace("          if MatchText(Request.Command,['knowledge'",'''          if Request.Command='import_data_quality' then begin
            Store.ImportDataQualityReport(Request.GenerationID,Request.Body,Request.Editor,Request.Title);
            Respond(nil,'Saved target-data check report imported with attribution and original SHA256; human review pending.',False,False,Request.Entry='',False,Store.KnowledgeJSON);Continue;
          end;
          if MatchText(Request.Command,['knowledge' ''',1).replace("['knowledge' ,","['knowledge',");p.write_text(s,encoding='utf-8')
print('Authored quality register and saved-report import')
