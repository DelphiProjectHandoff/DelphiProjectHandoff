exec((__import__('pathlib').Path(__file__).parent/'implement-operations.py').read_text(encoding='utf-8').split("s=read('DPH.Analysis.Symbols.pas')")[0])
s=read('DPH.Workspace.DatabaseConnections.pas')
s=s.replace('    class procedure EvaluateEngines(', '    class procedure AppendOperations(AView:TDPHWorkspaceView;AInventory:TJSONObject); static;\n    class procedure EvaluateEngines(',1)
s=s.replace("['TFDQuery','TFDTable'","['TDataSet','TFDQuery','TFDTable'",1)
s=s.replace('      EvaluateEngines(Result);','      AppendOperations(AView,Result);\n      EvaluateEngines(Result);',1)
at=s.index('class procedure TDPHDatabaseConnections.ResolveFields(')
s=s[:at]+"""class procedure TDPHDatabaseConnections.AppendOperations(AView:TDPHWorkspaceView;AInventory:TJSONObject);
var Rows,Relations:TJSONArray;V,W:TJSONValue;Row,Target,Symbol,Relation,Link:TJSONObject;
    Symbols,Receivers,Locations:TDictionary<string,TJSONObject>;
    ID,Key,Kind,Method,Effect,Basis,SQL,Owner,Reference:string;Count,OriginalCount:Integer;Match:TMatch;
  function LocationKey(AValue:TJSONObject):string;
  begin Result:=AValue.GetValue<string>('range.source')+'|'+AValue.GetValue<TJSONValue>('range.start').Value;end;
  procedure Remember(AIndex:TDictionary<string,TJSONObject>;const AKey:string;AValue:TJSONObject);
  begin if AIndex.ContainsKey(AKey) then AIndex[AKey]:=nil else AIndex.Add(AKey,AValue);end;
begin
 Rows:=AInventory.GetValue<TJSONArray>('rows');Relations:=AView.Document.GetValue<TJSONArray>('semantics.relationships');
 Symbols:=TDictionary<string,TJSONObject>.Create;Receivers:=TDictionary<string,TJSONObject>.Create;Locations:=TDictionary<string,TJSONObject>.Create;
 try
  OriginalCount:=Rows.Count;
  for V in AView.Document.GetValue<TJSONArray>('semantics.symbols') do begin Symbol:=V as TJSONObject;Symbols.Add(Symbol.GetValue<string>('key'),Symbol);end;
  for V in Rows do begin Row:=V as TJSONObject;Remember(Receivers,Row.GetValue<string>('id'),Row);Remember(Locations,LocationKey(Row),Row);end;
  for V in Relations do if V.GetValue<string>('kind')='component_field' then
    if Symbols.TryGetValue(V.GetValue<string>('from'),Symbol) and Locations.TryGetValue(LocationKey(Symbol),Target) and (Target<>nil) then
      Remember(Receivers,V.GetValue<string>('to'),Target);
  Count:=0;
  for V in Relations do begin
   Relation:=V as TJSONObject;Basis:=Relation.GetValue<string>('kind');
   if not MatchText(Basis,['database_operation','static_sql','dynamic_sql']) then Continue;
   Kind:='unknown';Method:=Relation.GetValue<string>('label');Effect:='Operation type and affected objects require approved source review.';
   if Basis='database_operation' then begin
    if MatchText(Method,['Open','Refresh','First','Last','Next','Prior','MoveBy','Locate','Lookup','FindFirst','FindLast','FindNext','FindPrior']) then begin Kind:='read';Effect:='Requests opening, refreshing, navigating or searching dataset records. Opening or refreshing may run configured SQL. Returned records, implicit posts and side effects are unobserved.';end
    else if MatchText(Method,['Append','Insert']) then begin Kind:='insert preparation';Effect:='Starts a new record buffer. This is not proof of an inserted database row; follow Post or cancellation and cached-update handling.';end
    else if MatchText(Method,['AppendRecord','InsertRecord']) then begin Kind:='insert';Effect:='Requests insertion of supplied record values. Success, cached updates, validation, triggers and transaction outcome are unobserved.';end
    else if SameText(Method,'Edit') then begin Kind:='update preparation';Effect:='Starts editing the current record buffer. Follow Post or cancellation; changed live rows are unobserved.';end
    else if SameText(Method,'Post') then begin Kind:='insert or update';Effect:='Requests posting the pending record buffer. Insert versus update depends on dataset state. Cached updates may defer persistence. Post does not prove transaction commit.';end
    else if SameText(Method,'Delete') then begin Kind:='delete';Effect:='Requests deletion of the current record. Cached updates, cascade effects, affected rows and transaction outcome are unobserved.';end
    else if MatchText(Method,['Cancel','CancelUpdates']) then begin Kind:='cancel pending changes';Effect:='Requests cancellation of a record edit or cached changes. This does not establish rollback of a database transaction.';end
    else if SameText(Method,'ApplyUpdates') then begin Kind:='mixed pending writes';Effect:='Requests applying cached record changes, potentially inserts, updates and deletes. Errors and commit behavior depend on the provider and calling source.';end
    else begin Kind:='SQL execution request';Effect:='Requests execution through a declared dataset API. Inspect configured SQL and its parameters; read/write kind, execution success and commit are unobserved.';end;
    Basis:='Source call on a declared framework dataset or captured descendant; dispatch and runtime state unverified.';
   end else begin
    SQL:=Trim(Method);Method:='configured SQL';
    if ContainsText(Relation.GetValue<string>('rule'),'literal_argument_to_execsql') then Method:='ExecSQL literal argument';
    if Relation.GetValue<string>('kind')='static_sql' then begin
     if (Length(SQL)>=2) and (SQL[1]='''') and (SQL[Length(SQL)]='''') then SQL:=Copy(SQL,2,Length(SQL)-2).Replace('''''','''');
     // Mask quoted values before inspecting statement separators; never display SQL contents here.
     SQL:=TRegEx.Replace(SQL,'''(?:''''|[^''])*''','?');
     SQL:=TRegEx.Replace(SQL,'(?s)/\\*.*?\\*/',' ');SQL:=TRegEx.Replace(SQL,'--[^\\r\\n]*',' ');SQL:=Trim(SQL);
     if SQL.EndsWith(';') then SQL:=Trim(Copy(SQL,1,Length(SQL)-1));
     Match:=TRegEx.Match(SQL,'(?i)^\\s*(SELECT|INSERT|UPDATE|DELETE)\\b');
     if Match.Success and not SQL.Contains(';') then begin
      Key:=UpperCase(Match.Groups[1].Value);
      if Key='SELECT' then Kind:='read' else Kind:=LowerCase(Key);
     end;
     Effect:='Captured '+Kind+' SQL candidate. Configuring SQL does not execute it. Complex SQL may have unresolved tables, columns, nested operations, triggers or provider-specific effects. Use Database schema and Source for evidence.';
     Basis:='Literal SQL captured from source or a serialized resource; statement family is lexical, not server validation.';
    end else begin Method:='dynamic SQL';Basis:='SQL text depends on expressions or runtime values; operation kind remains unknown.';end;
   end;
   if Rows.Count>=10000 then raise ERangeError.Create('Database inventory exceeds 10000 rows including operations');
   Inc(Count);ID:='database-operation:'+IntToStr(Count);Owner:=Relation.GetValue<string>('from');
   if Symbols.TryGetValue(Owner,Symbol) then Owner:=Symbol.GetValue<string>('name');
   Row:=TJSONObject.Create;Rows.AddElement(Row);
   Row.AddPair('id',ID).AddPair('name',Method).AddPair('path',Owner+' / '+Method+' / '+Kind).AddPair('class',Method).AddPair('role','database operation');
   Row.AddPair('operation_kind',Kind).AddPair('effect',Effect).AddPair('basis',Basis).AddPair('condition',Relation.GetValue<string>('condition'));
   Row.AddPair('source',Relation.GetValue<string>('range.source')).AddPair('source_hash',Relation.GetValue<string>('source_hash')).AddPair('range',Relation.GetValue('range').Clone as TJSONValue).AddPair('generation_id',AView.Document.GetValue('generation_id').Clone as TJSONValue);
   Row.AddPair('availability','captured operation candidate').AddPair('declaration','source evidence, not execution evidence').AddPair('configuration',TJSONArray.Create).AddPair('links',TJSONArray.Create).AddPair('used_by',TJSONArray.Create);
   Row.AddPair('unknowns','No SQL or target application was executed. Values, current record, affected row counts, access permissions, triggers, commit and rollback are unobserved. Review the calling routine and provider configuration.');
   Target:=nil;Reference:='unresolved receiver';
   if Relation.TryGetValue<string>('to',Key) and Symbols.TryGetValue(Key,Symbol) then begin
    Reference:=Symbol.GetValue<string>('name');Receivers.TryGetValue(Key,Target);
   end;
   Link:=TJSONObject.Create.AddPair('property','DataSet').AddPair('reference',Reference);Row.GetValue<TJSONArray>('links').AddElement(Link);
   if (Target<>nil) and MatchText(Target.GetValue<string>('role'),['dataset','connection']) then begin
    Link.AddPair('target_id',Target.GetValue<string>('id')).AddPair('resolution','unique captured semantic receiver');
    Target.GetValue<TJSONArray>('used_by').AddElement(TJSONObject.Create.AddPair('id',ID).AddPair('name',Row.GetValue<string>('path')).AddPair('property','operation receiver'));
   end else Link.AddPair('resolution','receiver unavailable, ambiguous or outside recognized database inventory');
  end;
  AInventory.AddPair('operation_count',TJSONNumber.Create(Rows.Count-OriginalCount));
 finally Locations.Free;Receivers.Free;Symbols.Free;end;
end;

"""+s[at:]
s=s.replace("['dataset','data source','transaction','database candidate']","['dataset','data source','transaction','database candidate','database operation']",1)
s=s.replace("  Result:=Result+sLineBreak+'UNKNOWNS AND NEXT INVESTIGATION'", "  if ARow.GetValue<string>('role')='database operation' then Result:='DATABASE OPERATION: '+UpperCase(ARow.GetValue<string>('operation_kind'))+sLineBreak+ARow.GetValue<string>('path')+sLineBreak+ARow.GetValue<string>('effect')+sLineBreak+ARow.GetValue<string>('basis')+sLineBreak+'Conditional context: '+ARow.GetValue<string>('condition')+sLineBreak+'Follow reference opens the captured receiver. Source opens the hash-checked source location.'+sLineBreak+sLineBreak+Result;\n  Result:=Result+sLineBreak+'UNKNOWNS AND NEXT INVESTIGATION'",1)
write('DPH.Workspace.DatabaseConnections.pas',s)
s=read('DPH.UI.Main.pas').replace('DatabaseInventoryNext,DatabaseInventoryFollow:TButton;','DatabaseInventoryNext,DatabaseInventoryFollow,DatabaseInventorySource:TButton;')
s=s.replace('    procedure DatabaseInventoryFollowClick(Sender:TObject);','    procedure DatabaseInventoryFollowClick(Sender:TObject);\n    procedure DatabaseInventorySourceClick(Sender:TObject);',1)
at=s.index('procedure TDPHMainForm.DatabaseInventoryFilterChange(')
s=s[:at]+"""procedure TDPHMainForm.DatabaseInventorySourceClick(Sender:TObject);
var Row,Range:TJSONObject;
begin
 if (FView=nil) or (DatabaseInventoryList.ItemIndex<0) or (DatabaseInventoryList.ItemIndex>=FDatabaseInventoryRows.Count) then Exit;
 Row:=FDatabaseInventoryRows[DatabaseInventoryList.ItemIndex];Range:=Row.GetValue<TJSONObject>('range');
 try SourceMemo.Text:=TDPHKeyboardInspector.ReadSource(FView,FEntry,Row,Range);SourceMemo.CaretPosition:=TCaretPosition.Create(Max(0,Range.GetValue<Integer>('line')-1),0);WorkspaceTabs.ActiveTab:=SourceTab;
 except on E:Exception do DatabaseInventoryMemo.Lines.Add('Source unavailable: '+E.Message);end;
end;

"""+s[at:]
s=s.replace('FDatabaseInventoryTargets.Clear;DatabaseInventoryLinks.Items.Clear;DatabaseInventoryFollow.Enabled:=False;','FDatabaseInventoryTargets.Clear;DatabaseInventoryLinks.Items.Clear;DatabaseInventoryFollow.Enabled:=False;DatabaseInventorySource.Enabled:=False;',1)
s=s.replace("Row:=FDatabaseInventoryRows[DatabaseInventoryList.ItemIndex];DatabaseInventoryMemo.Text:=", "Row:=FDatabaseInventoryRows[DatabaseInventoryList.ItemIndex];DatabaseInventorySource.Enabled:=True;DatabaseInventoryMemo.Text:=",1)
write('DPH.UI.Main.pas',s)
s=read('DPH.UI.Main.fmx').replace("'binding control target')","'binding control target'\n'database operation')",1)
s=s.replace("Text = 'Select a dataset, data source, bound control or persistent field. Follow reference traces captured screen-data links in either direction. Filter by field or component name. Scroll commands sideways. No target database is opened.'", "Text = 'Select a database operation to learn its requested effect; follow its dataset or open Source. SQL configuration and source calls do not prove execution or commit. Other filters trace connections and screen-data bindings. Scroll commands sideways. No target database is opened.'",1)
needle='object DatabaseInventoryStatus: TLabel'
at=s.index(needle);start=s.rfind('end\nend\n',0,at)
assert start>0
s=s[:start+4]+'''object DatabaseInventorySource: TButton
Position.X = 1111
Position.Y = 0
Width = 90
Height = 28
Text = 'Source'
OnClick = DatabaseInventorySourceClick
Enabled = False
end
'''+s[start+4:]
write('DPH.UI.Main.fmx',s)
