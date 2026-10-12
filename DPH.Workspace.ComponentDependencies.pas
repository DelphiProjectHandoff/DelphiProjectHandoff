unit DPH.Workspace.ComponentDependencies;
interface
uses System.JSON,DPH.Workspace.Model;
type TDPHComponentDependencies=class
 class function Inspect(AView:TDPHWorkspaceView;AComponents:TJSONObject):TJSONObject;static;
 class function Describe(ARow:TJSONObject;AKnowledge:TJSONArray):string;static;
 class function FindRecord(AKnowledge:TJSONArray;const AClass:string):TJSONObject;static;
end;
implementation
uses System.SysUtils,System.StrUtils,System.Generics.Collections;
class function TDPHComponentDependencies.FindRecord(AKnowledge:TJSONArray;const AClass:string):TJSONObject;
var V:TJSONValue;RecordValue:TJSONObject;
begin
 Result:=nil;if AKnowledge=nil then Exit;
 for V in AKnowledge do begin
  RecordValue:=TJSONObject.ParseJSONValue(V.GetValue<string>('structured_json','{}')) as TJSONObject;
  try if (RecordValue<>nil) and (RecordValue.GetValue<string>('record_type','')='component_dependency') and SameText(RecordValue.GetValue<string>('fields.class_name',''),AClass) then Exit(V as TJSONObject);finally RecordValue.Free;end;
 end;
end;
class function TDPHComponentDependencies.Inspect(AView:TDPHWorkspaceView;AComponents:TJSONObject):TJSONObject;
var Rows,Matches,Unavailable,Packages,Nodes:TJSONArray;V,W:TJSONValue;Row,Symbol,FileRow,Node,Pack:TJSONObject;
 Classes:TObjectDictionary<string,TList<TJSONObject>>;Group:TList<TJSONObject>;Name,Key,UnitName:string;Count:Integer;
begin
 Result:=TJSONObject.Create;Rows:=TJSONArray.Create;Result.AddPair('rows',Rows);
 Result.AddPair('qualification','All captured form classes are listed; a name alone does not establish third-party origin. Class declarations are lexical candidates, not compiler binding proof. Package references are not installed packages or proof of containment. Missing source and conditional variants remain unresolved. Authored vendor/version/support records never change source-resolution status. No target classes, packages or DLLs are loaded.');
 Unavailable:=TJSONArray.Create;Result.AddPair('unavailable_inputs',Unavailable);Packages:=TJSONArray.Create;Result.AddPair('packages',Packages);
 Classes:=TObjectDictionary<string,TList<TJSONObject>>.Create([doOwnsValues]);
 try
  try
   for V in AView.Document.GetValue<TJSONArray>('semantics.symbols') do begin
    Symbol:=V as TJSONObject;if (Symbol.GetValue<string>('kind')<>'type') or (Symbol.GetValue<string>('type')<>'class') then Continue;
    Name:=Symbol.GetValue<string>('name');Key:=LowerCase(Name);
    if not Classes.TryGetValue(Key,Group) then begin Group:=TList<TJSONObject>.Create;Classes.Add(Key,Group);end;Group.Add(Symbol);
    Key:=LowerCase(Copy(Name,LastDelimiter('.',Name)+1,MaxInt));
    if not SameText(Name,Key) then begin if not Classes.TryGetValue(Key,Group) then begin Group:=TList<TJSONObject>.Create;Classes.Add(Key,Group);end;Group.Add(Symbol);end;
   end;
   for V in AView.Document.GetValue<TJSONArray>('syntax.files') do begin
    FileRow:=V as TJSONObject;
    if FileRow.GetValue<string>('availability')<>'available' then Unavailable.AddElement(TJSONObject.Create.AddPair('source',FileRow.GetValue<string>('path')).AddPair('availability',FileRow.GetValue<string>('availability')));
    if not FileRow.TryGetValue<TJSONArray>('ir.nodes',Nodes) then Continue;
    for W in Nodes do begin Node:=W as TJSONObject;if Node.GetValue<string>('kind')<>'package' then Continue;
     Pack:=TJSONObject.Create;Packages.AddElement(Pack);Pack.AddPair('name',Node.GetValue<string>('name'));Pack.AddPair('source',FileRow.GetValue<string>('path'));Pack.AddPair('source_hash',FileRow.GetValue<string>('sha256',''));Pack.AddPair('qualification','Captured package declaration only; membership, installation, vendor and version are not inferred.');
    end;
   end;
   for V in AComponents.GetValue<TJSONArray>('rows') do begin
    Row:=V.Clone as TJSONObject;Rows.AddElement(Row);Matches:=TJSONArray.Create;Row.AddPair('class_candidates',Matches);Count:=0;UnitName:='';
    if Classes.TryGetValue(LowerCase(Row.GetValue<string>('class')),Group) then for Symbol in Group do begin
     Matches.AddElement(Symbol.Clone as TJSONObject);Inc(Count);UnitName:='';
     FileRow:=AView.SourceFile(Symbol.GetValue<string>('range.source'));
     if (FileRow<>nil) and FileRow.TryGetValue<TJSONArray>('ir.nodes',Nodes) and (Nodes.Count>0) then UnitName:=Nodes.Items[0].GetValue<string>('name','');
    end;
    if Count=0 then Name:='unresolved class declaration'
    else if Count=1 then Name:='unique captured class candidate (inferred)'
    else Name:='ambiguous class declarations ('+IntToStr(Count)+')';
    Row.AddPair('resolution',Name);if Count=1 then Row.AddPair('candidate_unit',UnitName);
   end;
   Result.AddPair('total',TJSONNumber.Create(Rows.Count));
  except Result.Free;raise;end;
 finally Classes.Free;end;
end;
class function TDPHComponentDependencies.Describe(ARow:TJSONObject;AKnowledge:TJSONArray):string;
var V:TJSONValue;Saved:TJSONObject;
begin
 Result:='COMPONENT DEPENDENCY '+ARow.GetValue<string>('name')+' : '+ARow.GetValue<string>('class')+sLineBreak+
 'Form: '+ARow.GetValue<string>('form')+' | parent: '+ARow.GetValue<string>('parent')+sLineBreak+
 'Generation: '+ARow.GetValue('generation_id').Value+' | '+ARow.GetValue<string>('availability')+sLineBreak+
 'Form source: '+ARow.GetValue<string>('source')+':'+IntToStr(ARow.GetValue<Integer>('range.line'))+sLineBreak+
 'Form SHA-256: '+ARow.GetValue<string>('source_hash')+sLineBreak+sLineBreak+'CLASS SOURCE RESOLUTION'+sLineBreak+ARow.GetValue<string>('resolution')+sLineBreak;
 for V in ARow.GetValue<TJSONArray>('class_candidates') do Result:=Result+V.GetValue<string>('name')+' | '+V.GetValue<string>('range.source')+':'+IntToStr(V.GetValue<Integer>('range.line'))+' | condition: '+V.GetValue<string>('condition','')+' | SHA-256 '+V.GetValue<string>('source_hash')+sLineBreak;
 Result:=Result+'Missing declarations can be standard framework, external vendor, project-local, inherited or excluded source. DPH does not guess vendor, version, package or support from prefixes. A unique captured name is an inferred candidate; aliases, scope and compiler binding may differ.'+sLineBreak+sLineBreak+'AUTHORED PACKAGE VENDOR VERSION AND SUPPORT'+sLineBreak;
 Saved:=FindRecord(AKnowledge,ARow.GetValue<string>('class'));
 if Saved=nil then Result:=Result+'No attributed dependency record for this class. Choose Edit dependency to document it. Blank fields remain unknown.'
 else Result:=Result+Saved.GetValue<string>('body')+sLineBreak+'State: '+Saved.GetValue<string>('state')+' | revision: '+Saved.GetValue<string>('revision')+' | source generation: '+Saved.GetValue<string>('source_generation')+sLineBreak+'Contributor: '+Saved.GetValue<string>('editor','')+' | reviewer: '+Saved.GetValue<string>('reviewer','')+sLineBreak+'Open in Knowledge for immutable history, exact evidence links and named review. Authored metadata does not resolve the missing class.';
 Result:=Result+sLineBreak+sLineBreak+'HOW TO INVESTIGATE'+sLineBreak+'Compare the declaring unit and package with captured project references and unavailable inputs below. Ask the maintainer for the exact installed product/version, license, support contacts and replacement constraints. Attach approved source roots and reassess to capture missing declarations. Package declarations do not establish installed runtime/design-time binaries. Never execute a package to identify a component.';
end;
end.
