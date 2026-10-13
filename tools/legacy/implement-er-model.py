from pathlib import Path
r=Path.cwd();p=r/'DPH.Workspace.DatabaseSchema.pas';s=p.read_text()
s=s.replace(' class function Describe(ARow:TJSONObject):string;static;', ' class function Describe(ARow:TJSONObject):string;static;\n class function Diagram(AInventory:TJSONObject;const AFilter,AFocusID:string;AOffset,ALimit,AMaxColumns:Integer):TJSONObject;static;')
model=r'''class function TDPHDatabaseSchema.Diagram(AInventory:TJSONObject;const AFilter,AFocusID:string;AOffset,ALimit,AMaxColumns:Integer):TJSONObject;
var Rows,Nodes,Edges,Columns,Links:TJSONArray;Value,LinkValue,ColumnValue,KeyValue:TJSONValue;Item,TableRow,Node,ColumnRow,KeyRow,Edge,Link:TJSONObject;
    Tables,ByID:TDictionary<string,TJSONObject>;Owned:TObjectDictionary<string,TList<TJSONObject>>;OwnedRows:TList<TJSONObject>;
    Wanted,Visible:TDictionary<string,Boolean>;Owner,Target,ID,StateText,Badges:string;TotalTables,TotalColumns,TotalForeign,SourceGaps,DuplicateTables,Unresolved,Matching,Related,Skipped,Order,Shown:Integer;
    Good,IsVisible,Partial:Boolean;
 function TargetID(AKey:TJSONObject):string;
 var V:TJSONValue;
 begin Result:='';for V in AKey.GetValue<TJSONArray>('links') do if V.GetValue<string>('role')='referenced table' then V.TryGetValue<string>('target_id',Result);end;
 procedure Note(ATable:TJSONObject;const Text:string);
 begin ATable.RemovePair('partial').Free;ATable.AddPair('partial',TJSONBool.Create(True));ATable.GetValue<TJSONArray>('notes').Add(Text);end;
begin
 if (AOffset<0) or (ALimit<1) or (ALimit>60) or (AMaxColumns<1) or (AMaxColumns>32) then raise EArgumentOutOfRangeException.Create('ER diagram bounds require offset >= 0, 1..60 tables and 1..32 column summaries');
 Result:=TJSONObject.Create;Nodes:=TJSONArray.Create;Edges:=TJSONArray.Create;Result.AddPair('nodes',Nodes).AddPair('edges',Edges);
 Result.AddPair('qualification','PARTIAL CAPTURED SCHEMA. Tables, column badges and foreign-key arrows are supported source declarations with exact captured ownership/links. Body grammar, referenced uniqueness, type compatibility, dialect validity, effective migration order, business cardinality and deployed enforcement remain unverified. No live database or target SQL is executed. Empty diagrams do not prove absence of a schema. Inferred SQL references and unsupported statements do not invent entities. Click a table or choose FK evidence to inspect original captured metadata.');
 Tables:=TDictionary<string,TJSONObject>.Create;ByID:=TDictionary<string,TJSONObject>.Create;Owned:=TObjectDictionary<string,TList<TJSONObject>>.Create([doOwnsValues]);Wanted:=TDictionary<string,Boolean>.Create;Visible:=TDictionary<string,Boolean>.Create;
 TotalTables:=0;TotalColumns:=0;TotalForeign:=0;SourceGaps:=0;DuplicateTables:=0;Unresolved:=0;Matching:=0;Related:=0;Skipped:=0;
 try
  try
   if AInventory=nil then Rows:=nil else Rows:=AInventory.GetValue<TJSONArray>('rows');
   if Rows<>nil then for Value in Rows do begin Item:=Value as TJSONObject;ID:=Item.GetValue<string>('id');ByID.Add(ID,Item);
    if (Item.GetValue<string>('kind')='table') and (Item.GetValue<string>('status')='declared header') then begin Tables.Add(ID,Item);Inc(TotalTables);if Item.GetValue<Integer>('definition_count')>1 then Inc(DuplicateTables);end;
    if Item.GetValue<string>('kind')='column' then Inc(TotalColumns);
    if Item.GetValue<string>('kind')='gap' then Inc(SourceGaps);
    if (Item.GetValue<string>('kind')='key') and (Item.GetValue<string>('key_kind')='foreign') then begin Inc(TotalForeign);if Item.GetValue<string>('relationship_status')<>'captured links complete' then Inc(Unresolved);end;
    if Item.TryGetValue<string>('declaration_id',Owner) then begin
     if not Owned.TryGetValue(Owner,OwnedRows) then begin OwnedRows:=TList<TJSONObject>.Create;Owned.Add(Owner,OwnedRows);end;OwnedRows.Add(Item);
    end;
   end;
   if (AFocusID<>'') and Tables.ContainsKey(AFocusID) then begin
    Wanted.Add(AFocusID,True);
    for Value in Rows do begin Item:=Value as TJSONObject;if (Item.GetValue<string>('kind')<>'key') or (Item.GetValue<string>('key_kind')<>'foreign') then Continue;
     Owner:=Item.GetValue<string>('declaration_id');Target:=TargetID(Item);
     if Owner=AFocusID then begin if Tables.ContainsKey(Target) then Wanted.AddOrSetValue(Target,True);end;
     if Target=AFocusID then begin if Tables.ContainsKey(Owner) then Wanted.AddOrSetValue(Owner,True);end;
    end;
   end;
   if Rows<>nil then for Value in Rows do begin TableRow:=Value as TJSONObject;ID:=TableRow.GetValue<string>('id');if not Tables.ContainsKey(ID) then Continue;
    if (AFocusID<>'') and not Wanted.ContainsKey(ID) then Continue;
    if (AFilter.Trim<>'') and not ContainsText(TableRow.GetValue<string>('name')+' '+TableRow.GetValue<string>('schema')+' '+TableRow.GetValue<string>('source'),AFilter.Trim) then Continue;
    Inc(Matching);if (Matching<=AOffset) or (Nodes.Count>=ALimit) then Continue;
    Node:=TJSONObject.Create.AddPair('id',ID).AddPair('name',TableRow.GetValue<string>('name')).AddPair('schema',TableRow.GetValue<string>('schema')).AddPair('source',TableRow.GetValue<string>('source')).AddPair('source_hash',TableRow.GetValue<string>('source_hash')).AddPair('generation_id',TableRow.GetValue('generation_id').Clone as TJSONValue).AddPair('range',TableRow.GetValue('range').Clone as TJSONValue).AddPair('partial',TJSONBool.Create(False)).AddPair('notes',TJSONArray.Create);
    Nodes.AddElement(Node);Visible.Add(ID,True);Columns:=TJSONArray.Create;Node.AddPair('columns',Columns);Shown:=0;Order:=0;
    if TableRow.GetValue<Integer>('definition_count')>1 then Note(Node,'Duplicate captured table name; effective migration unresolved.');
    if Owned.TryGetValue(ID,OwnedRows) then begin
     for Item in OwnedRows do begin
      if Item.GetValue<string>('kind')='gap' then Note(Node,Item.GetValue<string>('reason'));
      if (Item.GetValue<string>('kind')='key') and (Item.GetValue<string>('relationship_status')<>'captured links complete') then Note(Node,Item.GetValue<string>('constraint_name')+': relationship gaps; inspect key evidence.');
      if Item.GetValue<string>('kind')<>'column' then Continue;Inc(Order);if Columns.Count>=AMaxColumns then Continue;
      Badges:='';
      for KeyRow in OwnedRows do if KeyRow.GetValue<string>('kind')='key' then begin
       for LinkValue in KeyRow.GetValue<TJSONArray>('links') do begin Link:=LinkValue as TJSONObject;
        if (Link.GetValue<string>('role')='local column') and (Link.GetValue<string>('target_id','')=Item.GetValue<string>('id')) then begin
         StateText:=UpperCase(KeyRow.GetValue<string>('key_kind'));if StateText='PRIMARY' then StateText:='PK' else if StateText='FOREIGN' then StateText:='FK' else StateText:='UQ';
         if Badges<>'' then Badges:=Badges+' ';Badges:=Badges+StateText;Break;
        end;
       end;
      end;
      ColumnRow:=TJSONObject.Create.AddPair('id',Item.GetValue<string>('id')).AddPair('name',Item.GetValue<string>('column')).AddPair('declared_type',Item.GetValue<string>('declared_type')).AddPair('nullability',Item.GetValue<string>('nullability')).AddPair('badges',Badges);Columns.AddElement(ColumnRow);Inc(Shown);
     end;
    end;
    Node.AddPair('column_count',TJSONNumber.Create(Order)).AddPair('shown_columns',TJSONNumber.Create(Shown));
    if Order>Shown then Note(Node,'Column summary truncated; open table evidence for all captured columns.');
    if Order=0 then Note(Node,'No supported captured columns; not proof of an empty table.');
   end;
   if Rows<>nil then for Value in Rows do begin Item:=Value as TJSONObject;if (Item.GetValue<string>('kind')<>'key') or (Item.GetValue<string>('key_kind')<>'foreign') then Continue;
    Owner:=Item.GetValue<string>('declaration_id');Target:=TargetID(Item);if not Visible.ContainsKey(Owner) and not Visible.ContainsKey(Target) then Continue;Inc(Related);
    if Edges.Count>=120 then begin Inc(Skipped);Continue;end;
    Good:=(Item.GetValue<string>('relationship_status')='captured links complete') and Tables.ContainsKey(Owner) and Tables.ContainsKey(Target);
    if Good then StateText:='resolved captured links; semantics unverified' else StateText:='unresolved captured relationship';
    IsVisible:=Visible.ContainsKey(Owner) and Visible.ContainsKey(Target);if not IsVisible then StateText:=StateText+'; endpoint outside this page/filter or missing';
    Edge:=TJSONObject.Create.AddPair('key_id',Item.GetValue<string>('id')).AddPair('from',Owner).AddPair('to',Target).AddPair('name',Item.GetValue<string>('constraint_name')).AddPair('from_name',Item.GetValue<string>('table')).AddPair('to_name',Item.GetValue<string>('reference_table')).AddPair('members',Item.GetValue('members').Clone as TJSONValue).AddPair('reference_columns',Item.GetValue('reference_columns').Clone as TJSONValue).AddPair('resolved',TJSONBool.Create(Good)).AddPair('draw',TJSONBool.Create(IsVisible)).AddPair('state',StateText).AddPair('source',Item.GetValue<string>('source')).AddPair('source_hash',Item.GetValue<string>('source_hash')).AddPair('generation_id',Item.GetValue('generation_id').Clone as TJSONValue).AddPair('range',Item.GetValue('range').Clone as TJSONValue);Edges.AddElement(Edge);
   end;
   Result.AddPair('total_tables',TJSONNumber.Create(TotalTables)).AddPair('total_columns',TJSONNumber.Create(TotalColumns)).AddPair('total_foreign_keys',TJSONNumber.Create(TotalForeign)).AddPair('source_gaps',TJSONNumber.Create(SourceGaps)).AddPair('duplicate_table_declarations',TJSONNumber.Create(DuplicateTables)).AddPair('unresolved_foreign_keys',TJSONNumber.Create(Unresolved)).AddPair('matching_tables',TJSONNumber.Create(Matching)).AddPair('offset',TJSONNumber.Create(AOffset)).AddPair('shown_tables',TJSONNumber.Create(Nodes.Count)).AddPair('has_next',TJSONBool.Create(Matching>AOffset+Nodes.Count)).AddPair('related_foreign_keys',TJSONNumber.Create(Related)).AddPair('omitted_foreign_keys',TJSONNumber.Create(Skipped)).AddPair('focus_id',AFocusID).AddPair('filter',AFilter);
  except Result.Free;raise;end;
 finally Visible.Free;Wanted.Free;Owned.Free;ByID.Free;Tables.Free;end;
end;
'''
at=s.index('class function TDPHDatabaseSchema.Describe');s=s[:at]+model+s[at:];p.write_bytes(s.replace('\n','\r\n').encode())
print('Captured ER projection implemented')
