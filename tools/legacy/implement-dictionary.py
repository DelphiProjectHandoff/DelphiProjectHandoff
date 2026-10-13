from pathlib import Path
r=Path.cwd()
keys=['dictionary_id','schema_id','source','source_hash','generation','kind','name','table','source_line','definition','business_owner','sensitivity','evidence','usage']
labels=['Exact dictionary identity','Captured schema record','Captured source','Source SHA256','Original capture generation','Object kind','Object name','Owning table','Statement source line','Business definition','Business owner or steward','Sensitivity and handling','Evidence and remaining unknowns','Units values and business usage']
def write(p,s): (r/p).write_bytes(s.replace('\r\n','\n').replace('\n','\r\n').encode('utf-8'))
p=r/'DPH.Workspace.DatabaseSchema.pas';s=p.read_text(encoding='utf-8-sig')
s=s.replace('type TDPHDatabaseSchema=class',"const\n DPHDictionaryKeys:array[0..13] of string=("+','.join("'"+x+"'" for x in keys)+");\n DPHDictionaryLabels:array[0..13] of string=("+','.join("'"+x+"'" for x in labels)+");\ntype TDPHDatabaseSchema=class")
s=s.replace(' class function Inspect(',''' class function NewDictionary(ARow:TJSONObject):TJSONObject;static;
 class procedure ValidateDictionary(ARecord:TJSONObject);static;
 class function DictionaryBody(ARecord:TJSONObject):string;static;
 class function DictionaryTitle(ARecord:TJSONObject):string;static;
 class function FindDictionary(AKnowledge:TJSONArray;ARow:TJSONObject;AHistorical:Boolean=False):TJSONObject;static;
 class function DictionaryIdentity(const ASource,AHash,AID:string):string;static;
 class function Inspect(''',1)
s=s.replace('uses System.SysUtils,System.StrUtils,System.Classes,System.Generics.Collections;','uses System.SysUtils,System.StrUtils,System.Classes,System.Generics.Collections,System.Hash;')
at=s.index('type TSchemaToken=')
s=s[:at]+'''class function TDPHDatabaseSchema.DictionaryIdentity(const ASource,AHash,AID:string):string;
begin Result:='schema:'+THashSHA2.GetHashString(ASource+#0+AHash+#0+AID);end;
class function TDPHDatabaseSchema.NewDictionary(ARow:TJSONObject):TJSONObject;
var F:TJSONObject;K:string;
begin
 if (ARow=nil) or not MatchText(ARow.GetValue<string>('kind',''),['table','column']) or
 not MatchText(ARow.GetValue<string>('status',''),['declared table','declared column']) then raise EArgumentException.Create('Select a captured table or column declaration');
 Result:=TJSONObject.Create.AddPair('record_type','data_dictionary');F:=TJSONObject.Create;Result.AddPair('fields',F);
 for K in DPHDictionaryKeys do F.AddPair(K,'');
 for K in ['source','source_hash','kind','name','table'] do begin F.RemovePair(K).Free;F.AddPair(K,ARow.GetValue<string>(K,''));end;
 F.RemovePair('schema_id').Free;F.AddPair('schema_id',ARow.GetValue<string>('id'));
 F.RemovePair('generation').Free;F.AddPair('generation',ARow.GetValue('generation_id').Value);
 F.RemovePair('source_line').Free;F.AddPair('source_line',ARow.GetValue('range.line').Value);
 F.RemovePair('dictionary_id').Free;F.AddPair('dictionary_id',DictionaryIdentity(F.GetValue<string>('source'),F.GetValue<string>('source_hash'),F.GetValue<string>('schema_id')));
end;
class procedure TDPHDatabaseSchema.ValidateDictionary(ARecord:TJSONObject);
var F:TJSONObject;P:TJSONPair;K,H:string;Known:Boolean;N:Int64;
begin
 if (ARecord=nil) or (ARecord.GetValue<string>('record_type','')<>'data_dictionary') then raise EArgumentException.Create('Expected a data dictionary record');
 if Length(ARecord.ToJSON)>65536 then raise EArgumentException.Create('Dictionary exceeds 64 KiB');
 for P in ARecord do if not MatchText(P.JsonString.Value,['record_type','fields']) then raise EArgumentException.Create('Unknown dictionary metadata');
 if not ARecord.TryGetValue<TJSONObject>('fields',F) then raise EArgumentException.Create('Dictionary requires fields');
 if F.Count<>Length(DPHDictionaryKeys) then raise EArgumentException.Create('Dictionary requires all fields');
 for P in F do begin Known:=False;for K in DPHDictionaryKeys do if P.JsonString.Value=K then Known:=True;
  if not Known or not (P.JsonValue is TJSONString) then raise EArgumentException.Create('Unknown dictionary field or non-text value');
  if Length(P.JsonValue.Value)>4096 then raise EArgumentException.Create('Dictionary field exceeds 4096 characters');
 end;
 for K in ['dictionary_id','schema_id','source','source_hash','generation','kind','name','source_line','definition','business_owner','sensitivity','evidence'] do
  if F.GetValue<string>(K,'').Trim='' then raise EArgumentException.Create('Enter '+K+'; explicitly state unknowns when needed');
 if not MatchText(F.GetValue<string>('kind'),['table','column']) then raise EArgumentException.Create('Dictionary target must be a table or column');
 H:=F.GetValue<string>('source_hash');if Length(H)<>64 then raise EArgumentException.Create('Invalid source SHA256');
 for K in H do if not CharInSet(K[1],['0'..'9','a'..'f']) then raise EArgumentException.Create('Invalid source SHA256');
 if not TryStrToInt64(F.GetValue<string>('generation'),N) or (N<1) then raise EArgumentException.Create('Invalid captured generation');
 if not TryStrToInt64(F.GetValue<string>('source_line'),N) or (N<1) then raise EArgumentException.Create('Invalid statement line');
 if (F.GetValue<string>('kind')='column') and (F.GetValue<string>('table').Trim='') then raise EArgumentException.Create('Column requires its captured owning table');
 if F.GetValue<string>('dictionary_id')<>DictionaryIdentity(F.GetValue<string>('source'),H,F.GetValue<string>('schema_id')) then raise EArgumentException.Create('Dictionary identity must match its captured source and schema record');
end;
class function TDPHDatabaseSchema.DictionaryTitle(ARecord:TJSONObject):string;
begin ValidateDictionary(ARecord);Result:='Data dictionary: '+ARecord.GetValue<string>('fields.dictionary_id');end;
class function TDPHDatabaseSchema.DictionaryBody(ARecord:TJSONObject):string;
var I:Integer;T:string;
begin
 ValidateDictionary(ARecord);Result:='DATA DICTIONARY'+sLineBreak+'Human-authored business meanings and handling claims. Saving does not verify them. Captured schema links identify source evidence, not a live database. Read the named review state.'+sLineBreak;
 for I:=0 to High(DPHDictionaryKeys) do begin T:=ARecord.GetValue<string>('fields.'+DPHDictionaryKeys[I],'');if T.Trim='' then T:='Not supplied; remains unknown.';
 Result:=Result+sLineBreak+DPHDictionaryLabels[I]+':'+sLineBreak+T+sLineBreak;end;Result:=TrimRight(Result);
end;
class function TDPHDatabaseSchema.FindDictionary(AKnowledge:TJSONArray;ARow:TJSONObject;AHistorical:Boolean):TJSONObject;
var V:TJSONValue;R:TJSONObject;ID:string;
begin
 Result:=nil;if (AKnowledge=nil) or (ARow=nil) then Exit;
 ID:=DictionaryIdentity(ARow.GetValue<string>('source'),ARow.GetValue<string>('source_hash'),ARow.GetValue<string>('id'));
 for V in AKnowledge do begin R:=TJSONObject.ParseJSONValue(V.GetValue<string>('structured_json','{}')) as TJSONObject;
  try if (R=nil) or (R.GetValue<string>('record_type','')<>'data_dictionary') then Continue;
   if R.GetValue<string>('fields.dictionary_id','')=ID then Exit(V as TJSONObject);
   if AHistorical and (R.GetValue<string>('fields.source','')=ARow.GetValue<string>('source')) and
    (R.GetValue<string>('fields.schema_id','')=ARow.GetValue<string>('id')) and (R.GetValue<string>('fields.kind','')=ARow.GetValue<string>('kind')) and
    (R.GetValue<string>('fields.name','')=ARow.GetValue<string>('name')) then Result:=V as TJSONObject;
  finally R.Free;end;
 end;
end;

'''+s[at:];write(p.relative_to(r),s)
# Serialize the editor using the established native structured-knowledge form design.
s=(r/'DPH.UI.ActionPurpose.pas').read_text();s=s.replace('ActionPurpose','DatabaseDictionary').replace('DPHDatabaseDictionaryKeys','DPHDictionaryKeys').replace('DPH.Knowledge.DatabaseDictionary','DPH.Workspace.DatabaseSchema').replace('TDPHDatabaseDictionary.Validate','TDPHDatabaseSchema.ValidateDictionary')
start=s.index('    Profile_action_id_Row:');end=s.index('    procedure ApplyProfileClick',start)
s=s[:start]+''.join(f'    Profile_{k}_Row: TLayout;\n    Profile_{k}_Label: TLabel;\n    Profile_{k}: TMemo;\n' for k in keys)+s[end:];write('DPH.UI.DatabaseDictionary.pas',s)
s=(r/'DPH.UI.ComponentDependency.fmx').read_text();s=s[:s.index('    object Profile_class_name_Row:')]
s=s.replace('DPHComponentDependencyForm','DPHDatabaseDictionaryForm').replace('Component dependency record','Table or column business dictionary')
a=s.index("    Text = 'Document this component");b=s.index('\n',a)
s=s[:a]+"    Text = 'Define the selected table or column for readers learning this project. Enter its business definition, owner or steward, sensitivity and evidence. State unknowns explicitly. Identity fields are captured and read only. Apply creates a Knowledge draft; Save there, then review explicitly. Do not enter actual confidential values.'"+s[b:]
for i,(k,label) in enumerate(zip(keys,labels)):
 s+=f'''    object Profile_{k}_Row: TLayout
      Position.Y = {i*122}
      Width = 780
      Height = 122
      Anchors = [akLeft, akTop, akRight]
      object Profile_{k}_Label: TLabel
        Align = Top
        Height = 28
        Margins.Left = 12
        Text = '{label}'
      end
      object Profile_{k}: TMemo
        Align = Client
        Margins.Left = 12
        Margins.Right = 12
        Margins.Bottom = 10
        WordWrap = True
        ReadOnly = {'True' if i<9 else 'False'}
        ShowScrollBars = True
        StyledSettings = []
        TextSettings.Font.Size = 16
      end
    end
'''
s+='  end\nend\n';write('DPH.UI.DatabaseDictionary.fmx',s)
p=r/'DPH.UI.Main.pas';s=p.read_text();s=s.replace('DatabaseSchemaER:TButton;','DatabaseSchemaER,DatabaseDictionaryEdit,DatabaseDictionaryKnowledge:TButton;')
s=s.replace('    procedure DatabaseSchemaFilterChange','    procedure DatabaseDictionaryEditClick(Sender:TObject);\n    procedure DatabaseDictionaryKnowledgeClick(Sender:TObject);\n    procedure DatabaseSchemaFilterChange',1)
s=s.replace('DPH.UI.ActionPurpose','DPH.UI.DatabaseDictionary, DPH.UI.ActionPurpose',1)
s=s.replace(" DatabaseSchemaSource.Enabled:=False;DatabaseSchemaMemo.Text:=", " DatabaseDictionaryEdit.Enabled:=False;DatabaseDictionaryKnowledge.Enabled:=False;\n DatabaseSchemaSource.Enabled:=False;DatabaseSchemaMemo.Text:=",1)
anchor=' DatabaseSchemaSource.Enabled:=True;\n if MatchText(FDatabaseSchemaRows'
s=s.replace(anchor,""" DatabaseDictionaryEdit.Enabled:=MatchText(FDatabaseSchemaRows[DatabaseSchemaList.ItemIndex].GetValue<string>('status'),['declared table','declared column']);
 if DatabaseDictionaryEdit.Enabled then begin
  DatabaseSchemaMemo.Lines.Add(sLineBreak+'BUSINESS DICTIONARY');
  if TDPHDatabaseSchema.FindDictionary(FKnowledge,FDatabaseSchemaRows[DatabaseSchemaList.ItemIndex])<>nil then begin
   DatabaseSchemaMemo.Lines.Add(TDPHDatabaseSchema.FindDictionary(FKnowledge,FDatabaseSchemaRows[DatabaseSchemaList.ItemIndex]).GetValue<string>('body'));
   DatabaseSchemaMemo.Lines.Add('Review state: '+TDPHDatabaseSchema.FindDictionary(FKnowledge,FDatabaseSchemaRows[DatabaseSchemaList.ItemIndex]).GetValue<string>('state')+' | Open dictionary history for contributor, revisions and review.');
  end else DatabaseSchemaMemo.Lines.Add('Business meaning not recorded for these captured bytes. Click Edit dictionary. Do not infer purpose or sensitivity from SQL names.');
  DatabaseDictionaryKnowledge.Enabled:=TDPHDatabaseSchema.FindDictionary(FKnowledge,FDatabaseSchemaRows[DatabaseSchemaList.ItemIndex],True)<>nil;
  if DatabaseDictionaryKnowledge.Enabled and (TDPHDatabaseSchema.FindDictionary(FKnowledge,FDatabaseSchemaRows[DatabaseSchemaList.ItemIndex])=nil) then DatabaseSchemaMemo.Lines.Add('Historical dictionary exists for this source/record/name with different captured bytes. Open dictionary history; it is not transferred or verified against this capture.');
 end;
 DatabaseSchemaSource.Enabled:=True;
 if MatchText(FDatabaseSchemaRows""",1)
# Reuse the existing draft and immutable Knowledge flow.
a=s.index('procedure TDPHMainForm.DependencyEditClick');b=s.index('procedure TDPHMainForm.LayoutFilterChange',a);code=s[a:b]
code=code.replace('DependencyEditClick','DatabaseDictionaryEditClick').replace('DependencyList','DatabaseSchemaList').replace('FDependencyRows','FDatabaseSchemaRows').replace('TDPHComponentDependencies.FindRecord(FKnowledge,ComponentRow.GetValue<string>(\'class\'))','TDPHDatabaseSchema.FindDictionary(FKnowledge,ComponentRow)').replace('TDPHComponentDependencyForm','TDPHDatabaseDictionaryForm').replace("TJSONObject.Create.AddPair('record_type','component_dependency').AddPair('fields',TJSONObject.Create.AddPair('class_name',ComponentRow.GetValue<string>('class')))",'TDPHDatabaseSchema.NewDictionary(ComponentRow)').replace('TDPHComponentDependency.Title','TDPHDatabaseSchema.DictionaryTitle').replace('TDPHComponentDependency.Body','TDPHDatabaseSchema.DictionaryBody').replace("'engineering_rule'","'business_rule'").replace("'engineering'","'overview'").replace("'engineer'","'all'")
code=code.replace('Component dependency draft:','Data dictionary draft:').replace('Edit dependency fields on Component dependencies. Use Knowledge links for exact evidence. Saving does not resolve class source or verify vendor claims.','Edit fields using Database schema > Edit dictionary. Captured source, SHA256, statement line and schema identity stay read only. Use Knowledge links for additional evidence. Saving does not verify business meanings.').replace('Dependency draft prepared.','Dictionary draft prepared.')
code=code.replace(' ComponentRow:=FDatabaseSchemaRows[DatabaseSchemaList.ItemIndex];',' ComponentRow:=FDatabaseSchemaRows[DatabaseSchemaList.ItemIndex];if not DatabaseDictionaryEdit.Enabled then Exit;')
s=s[:b]+code+'''procedure TDPHMainForm.DatabaseDictionaryKnowledgeClick(Sender:TObject);
var Row:TJSONObject;I:Integer;
begin
 if FKnowledgeEdited then begin StatusLabel.Text:='Save or discard the current Knowledge draft first';Exit;end;
 if (DatabaseSchemaList.ItemIndex<0) or (DatabaseSchemaList.ItemIndex>=FDatabaseSchemaRows.Count) then Exit;
 Row:=TDPHDatabaseSchema.FindDictionary(FKnowledge,FDatabaseSchemaRows[DatabaseSchemaList.ItemIndex],True);if Row=nil then Exit;
 PendingKnowledgeCheck.IsChecked:=False;KnowledgeFilterChange(nil);
 for I:=0 to FKnowledgeRows.Count-1 do if FKnowledgeRows[I].GetValue<string>('id')=Row.GetValue<string>('id') then begin KnowledgeList.ItemIndex:=I;KnowledgeClick(nil);WorkspaceTabs.ActiveTab:=KnowledgeTab;Exit;end;
end;
'''+s[b:];write(p.relative_to(r),s)
p=r/'DPH.UI.Main.fmx';s=p.read_text();a=s.index('object DatabaseSchemaER:');b=s.index('\nend',a)+4
s=s[:b]+'''
object DatabaseDictionaryEdit: TButton
Position.X = 1557
Position.Y = 0
Width = 150
Height = 30
Text = 'Edit dictionary'
Enabled = False
OnClick = DatabaseDictionaryEditClick
end
object DatabaseDictionaryKnowledge: TButton
Position.X = 1717
Position.Y = 0
Width = 180
Height = 30
Text = 'Open dictionary history'
Enabled = False
OnClick = DatabaseDictionaryKnowledgeClick
end'''+s[b:];write(p.relative_to(r),s)
p=r/'DelphiProjectHandoff.dproj';s=p.read_text();s=s.replace('<DCCReference Include="DPH.Knowledge.ActionPurpose.pas" />','<DCCReference Include="DPH.Knowledge.ActionPurpose.pas" />\n      <DCCReference Include="DPH.UI.DatabaseDictionary.pas"><Form>DPHDatabaseDictionaryForm</Form><FormType>fmx</FormType></DCCReference>');write(p.relative_to(r),s)
p=r/'DPH.Storage.Database.pas';s=p.read_text();s=s.replace('DPH.Knowledge.ActionPurpose;','DPH.Knowledge.ActionPurpose,DPH.Workspace.DatabaseSchema;')
anchor="      end else if StructuredValue.GetValue<string>('record_type','')='component_dependency' then begin"
code='''      end else if StructuredValue.GetValue<string>('record_type','')='data_dictionary' then begin
        TDPHDatabaseSchema.ValidateDictionary(StructuredValue as TJSONObject);
        if (ATitle<>TDPHDatabaseSchema.DictionaryTitle(StructuredValue as TJSONObject)) or (AKind<>'business_rule') or (DocumentKind<>'overview') or (Audience<>'all') or (AEntityKey<>'') then raise EDPHStorage.Create('Dictionary identity and project business scope must be preserved');
        if ABody<>TDPHDatabaseSchema.DictionaryBody(StructuredValue as TJSONObject) then raise EDPHStorage.Create('Edit dictionary fields on Database schema');
        if (PriorStructured<>'') and (PriorStructured<>'{}') then begin
          PriorRecord:=TJSONObject.ParseJSONValue(PriorStructured);
          try for ActionIdentityField in ['dictionary_id','schema_id','source','source_hash','generation','kind','name','table','source_line'] do
            if PriorRecord.GetValue<string>('fields.'+ActionIdentityField,'')<>StructuredValue.GetValue<string>('fields.'+ActionIdentityField,'') then raise EDPHStorage.Create('Dictionary captured identity cannot change');finally PriorRecord.Free;end;
        end;
        if Scalar('SELECT count(*) FROM knowledge_records k JOIN knowledge_revisions r ON r.knowledge_revision_id=k.current_revision_id WHERE k.project_id=1 AND k.knowledge_id<>:id AND json_extract(r.structured_json,''$.record_type'')=''data_dictionary'' AND json_extract(r.structured_json,''$.fields.dictionary_id'')=:identity',[AKnowledgeID,StructuredValue.GetValue<string>('fields.dictionary_id')])<>0 then raise EDPHStorage.Create('A dictionary already exists for this captured target; refresh and edit it. Retired identities remain reserved.');
'''
assert anchor in s;s=s.replace(anchor,code+anchor,1);write(p.relative_to(r),s)
print('Dictionary model, IDE editor, schema integration and storage guards authored')
