from pathlib import Path
r=Path.cwd();p=r/'DPH.Workspace.DatabaseConnections.pas';s=p.read_text(encoding='utf-8-sig').replace('for Flow in List do begin \n','for Flow in List do begin\n').replace('V,F,P,C,E,B,N,X:TJSONValue','V,F,P,C,E,B,N:TJSONValue').replace('Handler,Flow,Symbol,ReferenceRow','Handler,Flow,ReferenceRow')
s=s.replace("if BodyNodes=nil then Continue;", "if BodyNodes=nil then begin SetText(Rule,'constraint','Handler syntax unavailable; no body rules invented.');Continue;end;")
p.write_text(s,encoding='utf-8')
p=r/'DPH.Parse.Forms.pas';p.write_text(p.read_text(encoding='utf-8-sig'),encoding='utf-8')
p=r/'DPH.UI.Main.fmx';s=p.read_text(encoding='utf-8-sig');s=s.replace("Text = 'Select transaction operation for begin, commit, rollback and possible normal/error/cleanup paths. Follow reference opens a receiver or next boundary; Source opens captured code. Database operation shows CRUD requests. Scroll commands sideways. No target database is opened.'", "Text = 'Choose data rule for field constraints, validation conditions and input/output transformations. Follow reference opens the field, handler or lexical declaration; Source opens captured code. Transaction and database operation filters inspect other requests. Scroll commands sideways.'");p.write_text(s,encoding='utf-8-sig')
p=r/'DPH.UI.Main.pas';s=p.read_text(encoding='utf-8-sig');needle=" if DatabaseInventoryList.Count>0 then begin DatabaseInventoryList.ItemIndex:=0;DatabaseInventorySelectionChange(nil);end";assert needle in s
s=s.replace(needle," if FDatabaseInventory.GetValue<Boolean>('data_rules_truncated',False) then DatabaseInventoryStatus.Text:=DatabaseInventoryStatus.Text+' Rule inventory truncated at 10000 rows; narrow the captured project.';\n"+needle,1);p.write_text(s,encoding='utf-8-sig')
p=r/'tests/DPH.Tests.DataRules.dpr';s=p.read_text(encoding='utf-8-sig');s=s.replace('Document,Report,Row,Link,Log:TJSONObject;', 'Document,Report,Row,Link,Log,ChangedFile,AddedNode:TJSONObject;Limited:TDPHWorkspaceView;Nodes:TJSONArray;')
needle=" Catalog:=TDPHWorkspaceCatalog.DefaultPath;"
tests=""" Document:=View.Document.Clone as TJSONObject;
 for Value in Document.GetValue<TJSONArray>('syntax.files') do if Value.GetValue<string>('path')='main.pas' then begin ChangedFile:=Value.GetValue<TJSONObject>('ir');ChangedFile.RemovePair('nodes').Free;ChangedFile.AddPair('nodes',TJSONArray.Create);end;
 Limited:=TDPHWorkspaceView.Create(Document);
 try Row:=TDPHDatabaseConnections.Inspect(Limited);try
  Check(Row.GetValue<TJSONArray>('rows').Count<Report.GetValue<TJSONArray>('rows').Count,'Unavailable handler syntax does not recreate transformation rules');
 finally Row.Free;end;finally Limited.Free;end;
 Document:=View.Document.Clone as TJSONObject;
 for Value in Document.GetValue<TJSONArray>('syntax.files') do if Value.GetValue<string>('path')='main.dfm' then begin
  Nodes:=Value.GetValue<TJSONArray>('ir.nodes');
  for I:=1 to 10000-Report.GetValue<Integer>('component_and_declaration_rows')-2 do begin
   AddedNode:=TJSONObject.Create.AddPair('kind','object').AddPair('name','Limit'+IntToStr(I)).AddPair('value','TFDConnection').AddPair('parent',TJSONNumber.Create(0)).AddPair('source','main.dfm').AddPair('start',TJSONNumber.Create(1000000+I)).AddPair('end',TJSONNumber.Create(1000001+I)).AddPair('line',TJSONNumber.Create(1)).AddPair('column',TJSONNumber.Create(1)).AddPair('condition','');Nodes.AddElement(AddedNode);
  end;
 end;
 Limited:=TDPHWorkspaceView.Create(Document);
 try Row:=TDPHDatabaseConnections.Inspect(Limited);try
  Check(Row.GetValue<Boolean>('data_rules_truncated'),'Full inventory reports omitted data rules explicitly');
  Check(Row.GetValue<TJSONArray>('rows').Count<=10000,'Combined inventory never exceeds 10000 rows');
 finally Row.Free;end;finally Limited.Free;end;
"""
assert needle in s;s=s.replace(needle,tests+needle,1);p.write_text(s,encoding='utf-8')
print('Rule coverage and limits prepared for final validation')
