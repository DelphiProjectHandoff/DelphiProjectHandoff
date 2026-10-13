from pathlib import Path
r=Path.cwd()
p=r/'DPH.Workspace.DatabaseConnections.pas';s=p.read_text()
s=s.replace('class procedure EvaluateEngines(AInventory:TJSONObject); static;','class procedure EvaluateEngines(AInventory:TJSONObject); static;\n    class procedure ResolveFields(AInventory:TJSONObject); static;')
s=s.replace("if SameText(ShortName,'TDataSource') then Exit('data source');", "if MatchText(ShortName,['TDataSource','TBindSourceDB']) then Exit('data source');\n    if MatchText(ShortName,['TField','TStringField','TWideStringField','TIntegerField','TLargeintField','TSmallintField','TWordField','TBooleanField','TFloatField','TCurrencyField','TBCDField','TFMTBCDField','TDateField','TTimeField','TDateTimeField','TSQLTimeStampField','TBlobField','TMemoField','TWideMemoField','TBytesField','TVarBytesField','TAutoIncField','TGuidField','TGraphicField']) then Exit('persistent field');")
s=s.replace("'Params.Strings']) then begin Role:='database candidate'", "'Params.Strings']) then begin Role:='database candidate'")
needle="          if Role='' then Continue;"
s=s.replace(needle,"          if (Role='') and Groups.TryGetValue(I,Members) then for PropertyNode in Members do\n            if MatchText(PropertyNode.GetValue<string>('name'),['DataSource','BindSource']) then begin Role:='bound control';Break;end;\n"+needle)
s=s.replace("'Key','PrivateKey','SSLMode'", "'Key','PrivateKey','FieldName','FieldKind','DataField','Required','ReadOnly','Size','Precision','SSLMode'")
s=s.replace("    Setting:=TJSONObject.Create", "    if MatchText(KnownName,['FieldName','DataField','FieldKind']) and Identifier(Decoded) then SafeValue:=Decoded;\n    if MatchText(KnownName,['Required','ReadOnly']) and MatchText(Decoded,['True','False']) then SafeValue:=Decoded;\n    if MatchText(KnownName,['Size','Precision']) and TryStrToInt(Decoded,N) and (N>=0) and (N<=1000000) then SafeValue:=IntToStr(N);\n    Setting:=TJSONObject.Create")
s=s.replace("          if Groups.TryGetValue(I,Members) then for PropertyNode in Members do begin", "          if (Role='persistent field') and (Node.GetValue<Integer>('parent')>=0) then begin\n            Parent:=LastDelimiter('.',ComponentPath);Reference:=Copy(ComponentPath,1,Parent-1);\n            Links.AddElement(TJSONObject.Create.AddPair('property','DataSet').AddPair('reference',Reference).AddPair('line',Node.GetValue('line').Clone as TJSONValue).AddPair('basis','serialized field parent'));\n          end;\n          if Groups.TryGetValue(I,Members) then for PropertyNode in Members do begin")
s=s.replace("'DataSet','DataSource','Session','SessionName'", "'DataSet','DataSource','BindSource','LookupDataSet','DataField','Session','SessionName'")
s=s.replace("Link:=TJSONObject.Create.AddPair('property',Name)", "Link:=TJSONObject.Create.AddPair('property',Name)")
s=s.replace("Link.AddPair('line',PropertyNode.GetValue('line').Clone as TJSONValue);Links.AddElement(Link);", "Link.AddPair('line',PropertyNode.GetValue('line').Clone as TJSONValue).AddPair('start',PropertyNode.GetValue('start').Clone as TJSONValue).AddPair('end',PropertyNode.GetValue('end').Clone as TJSONValue);Links.AddElement(Link);")
# Preserve quoted field names as captured identifiers, while component references must be symbols.
s=s.replace("['ConnectionDefName','DatabaseName','SessionName']))", "['ConnectionDefName','DatabaseName','SessionName','DataField']))")
s=s.replace("        Link:=Value as TJSONObject;Name:=Link.GetValue<string>('property');Reference:=Link.GetValue<string>('reference');Members:=nil;Target:=nil;Count:=0;", "        Link:=Value as TJSONObject;Name:=Link.GetValue<string>('property');Reference:=Link.GetValue<string>('reference');Members:=nil;Target:=nil;Count:=0;\n        if SameText(Name,'DataField') then Continue;")
s=s.replace("            Key:=Row.GetValue<string>('source')+'|'+Row.GetValue<string>('root')+'.'+Reference;", "            Key:=Row.GetValue<string>('source')+'|'+Row.GetValue<string>('root')+'.'+Reference;\n            if StartsText(Row.GetValue<string>('root')+'.',Reference) then Key:=Row.GetValue<string>('source')+'|'+Reference;")
s=s.replace("else if SameText(Name,'DataSet') then", "else if MatchText(Name,['DataSet','LookupDataSet']) then")
s=s.replace("else if SameText(Name,'DataSource') then", "else if MatchText(Name,['DataSource','BindSource']) then")
s=s.replace("      EvaluateEngines(Result);", "      ResolveFields(Result);\n      EvaluateEngines(Result);")
pos=s.index('class procedure TDPHDatabaseConnections.EvaluateEngines')
s=s[:pos]+'''class procedure TDPHDatabaseConnections.ResolveFields(AInventory:TJSONObject);
var Rows:TJSONArray;V,L,C:TJSONValue;Row,Link,Source,Dataset,Target:TJSONObject;
    ByID:TDictionary<string,TJSONObject>;Fields:TObjectDictionary<string,TList<TJSONObject>>;
    Candidates:TList<TJSONObject>;ID,FieldName,Key:string;Count:Integer;
begin
 Rows:=AInventory.GetValue<TJSONArray>('rows');ByID:=TDictionary<string,TJSONObject>.Create;
 Fields:=TObjectDictionary<string,TList<TJSONObject>>.Create([doOwnsValues]);
 try
  for V in Rows do ByID.Add(V.GetValue<string>('id'),V as TJSONObject);
  for V in Rows do begin Row:=V as TJSONObject;if Row.GetValue<string>('role')<>'persistent field' then Continue;
   FieldName:='';for C in Row.GetValue<TJSONArray>('configuration') do if SameText(C.GetValue<string>('name'),'FieldName') then FieldName:=C.GetValue<string>('value');
   if (FieldName='') or FieldName.StartsWith('[') then Continue;
   for L in Row.GetValue<TJSONArray>('links') do if (L.GetValue<string>('property')='DataSet') and L.TryGetValue<string>('target_id',ID) then begin
    Key:=ID+'|'+LowerCase(FieldName);if not Fields.TryGetValue(Key,Candidates) then begin Candidates:=TList<TJSONObject>.Create;Fields.Add(Key,Candidates);end;Candidates.Add(Row);
   end;
  end;
  for V in Rows do begin Row:=V as TJSONObject;
   for L in Row.GetValue<TJSONArray>('links') do begin Link:=L as TJSONObject;if Link.GetValue<string>('property')<>'DataField' then Continue;
    Dataset:=nil;Count:=0;
    for C in Row.GetValue<TJSONArray>('links') do if MatchText(C.GetValue<string>('property'),['DataSource','BindSource']) and C.TryGetValue<string>('target_id',ID) and ByID.TryGetValue(ID,Source) then
     for C in Source.GetValue<TJSONArray>('links') do if (C.GetValue<string>('property')='DataSet') and C.TryGetValue<string>('target_id',ID) and ByID.TryGetValue(ID,Target) then begin Inc(Count);Dataset:=Target;end;
    Candidates:=nil;if Count=1 then Fields.TryGetValue(Dataset.GetValue<string>('id')+'|'+LowerCase(Link.GetValue<string>('reference')),Candidates);
    if (Count=1) and (Candidates<>nil) and (Candidates.Count=1) then begin
     Target:=Candidates[0];Link.AddPair('resolution','unique captured persistent field candidate').AddPair('target_id',Target.GetValue<string>('id'));
     Target.GetValue<TJSONArray>('used_by').AddElement(TJSONObject.Create.AddPair('id',Row.GetValue<string>('id')).AddPair('name',Row.GetValue<string>('path')).AddPair('property','DataField'));
    end else if (Candidates<>nil) and (Candidates.Count>1) then Link.AddPair('resolution','ambiguous persistent field declarations')
    else Link.AddPair('resolution','unresolved field or dataset chain; dynamic fields and runtime bindings unobserved');
   end;
  end;
 finally Fields.Free;ByID.Free;end;
end;
''' +s[pos:]
# Avoid nested enumerator using same variable in Pascal.
s=s.replace('var Rows:TJSONArray;V,L,C:TJSONValue;', 'var Rows:TJSONArray;V,L,C,D:TJSONValue;')
s=s.replace("for C in Source.GetValue<TJSONArray>('links') do if (C.GetValue<string>('property')='DataSet') and C.TryGetValue<string>('target_id',ID)", "for D in Source.GetValue<TJSONArray>('links') do if (D.GetValue<string>('property')='DataSet') and D.TryGetValue<string>('target_id',ID)")
s=s.replace("  Engine:=ARow.GetValue<TJSONObject>('engine');", "  Engine:=ARow.GetValue<TJSONObject>('engine');")
# Put useful binding evidence before lengthy engine guidance.
s=s.replace("  Result:=Result+sLineBreak+'UNKNOWNS", "  if MatchText(ARow.GetValue<string>('role'),['bound control','persistent field','dataset','data source']) then begin\n    Result:='DATASET AND SCREEN BINDINGS'+sLineBreak+UpperCase(ARow.GetValue<string>('role'))+' '+ARow.GetValue<string>('path')+sLineBreak+\n      'Follow reference opens the exact captured target. Field names identify serialized persistent fields, not verified live columns. Missing/runtime/inherited bindings remain unknown.'+sLineBreak+sLineBreak+Result;\n  end;\n  Result:=Result+sLineBreak+'UNKNOWNS")
p.write_text(s)
p=r/'DPH.UI.Main.fmx';s=p.read_text().replace("'database candidate')", "'database candidate'\n'bound control'\n'persistent field')")
s=s.replace('Select a row for database engine, version declarations and masked evidence. Filter by engine name or component. Scroll commands sideways to follow references. No target database is opened.', 'Select a dataset, data source, bound control or persistent field. Follow reference traces captured screen-data links in either direction. Filter by field or component name. Scroll commands sideways. No target database is opened.')
p.write_text(s)
for p in [r/'DPH.Workspace.DatabaseConnections.pas',r/'DPH.UI.Main.fmx']:
 p.write_bytes(p.read_bytes().replace(b'\r\n',b'\n').replace(b'\n',b'\r\n'))
print('Dataset bindings implementation updated')
