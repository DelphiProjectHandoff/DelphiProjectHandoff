unit DPH.Workspace.FormInheritance;
interface
uses System.JSON, DPH.Workspace.Model;
type
  TDPHFormInheritance = class
    class function Inspect(AView: TDPHWorkspaceView): TJSONObject; static;
    class function Describe(ARow: TJSONObject): string; static;
  end;
implementation
uses System.SysUtils, System.StrUtils, System.IOUtils, System.Generics.Collections;

class function TDPHFormInheritance.Inspect(AView: TDPHWorkspaceView): TJSONObject;
var Forms: TList<TJSONObject>; Active: TList<string>; Rows,Issues: TJSONArray;
    FileValue: TJSONValue; FileRow,Tree: TJSONObject; Work: Integer; CapturedNodes:TJSONArray;
  procedure Warn(const S: string);
  begin if Issues.Count<10000 then Issues.Add(S); end;
  function Simple(const S: string): string;
  begin Result:=Copy(S,LastDelimiter('.',S)+1,MaxInt); end;
  function RootNode(F: TJSONObject): TJSONObject;
  var V: TJSONValue;
  begin Result:=nil; for V in F.GetValue<TJSONArray>('ir.nodes') do
    if MatchText(V.GetValue<string>('kind'),['object','inherited','inline']) and
      (V.GetValue<Integer>('parent')<0) then Exit(V as TJSONObject); end;
  function Origin(F,N: TJSONObject): TJSONObject;
  begin
    Result:=TJSONObject.Create.AddPair('source',F.GetValue<string>('path'))
      .AddPair('source_hash',F.GetValue<string>('sha256',''))
      .AddPair('generation_id',TJSONNumber.Create(AView.Document.GetValue<Int64>('generation_id')))
      .AddPair('condition',N.GetValue<string>('condition',''))
      .AddPair('range',TJSONObject.Create.AddPair('source',F.GetValue<string>('path'))
        .AddPair('start',TJSONNumber.Create(N.GetValue<Integer>('start')))
        .AddPair('end',TJSONNumber.Create(N.GetValue<Integer>('end')))
        .AddPair('line',TJSONNumber.Create(N.GetValue<Integer>('line')))
        .AddPair('column',TJSONNumber.Create(N.GetValue<Integer>('column'))));
  end;
  function FindForm(const ClassName: string): TJSONObject;
  var F,N,U: TJSONObject; V:TJSONValue; Count:Integer; UnitName,Qualified:string; UnitNodes:TJSONArray;
  begin
    Result:=nil;Count:=0;
    for F in Forms do begin
      N:=RootNode(F);if N=nil then Continue;UnitName:='';
      for V in AView.Document.GetValue<TJSONArray>('syntax.files') do begin
        U:=V as TJSONObject;
        if SameText(ExtractFileExt(U.GetValue<string>('path')),'.pas') and
          SameText(ChangeFileExt(U.GetValue<string>('path'),''),ChangeFileExt(F.GetValue<string>('path'),'')) and
          U.TryGetValue<TJSONArray>('ir.nodes',UnitNodes) then begin
          if U.GetValue<TJSONArray>('ir.nodes').Count>0 then UnitName:=U.GetValue<TJSONArray>('ir.nodes').Items[0].GetValue<string>('name','');
          Break;
        end;
      end;
      Qualified:=UnitName+'.'+N.GetValue<string>('value');
      if SameText(ClassName,N.GetValue<string>('value')) or SameText(ClassName,Qualified) then begin Result:=F;Inc(Count);end;
    end;
    if Count<>1 then begin
      if Count=0 then Warn('Missing captured form/frame for '+ClassName)
      else Warn('Ambiguous captured form/frame for '+ClassName+' ('+IntToStr(Count)+')');
      Result:=nil;
    end;
  end;
  function BaseForm(F,N: TJSONObject): TJSONObject;
  var V,W:TJSONValue;S,R,Selected:TJSONObject;Count,Edges:Integer;BaseName,UnitPath:string;
  begin
    Result:=nil;Selected:=nil;Count:=0;BaseName:='';UnitPath:=ChangeFileExt(F.GetValue<string>('path'),'.pas');
    for V in AView.Document.GetValue<TJSONArray>('semantics.symbols') do begin
      S:=V as TJSONObject;
      if (S.GetValue<string>('kind')='type') and (S.GetValue<string>('type')='class') and
        SameText(Simple(S.GetValue<string>('name')),Simple(N.GetValue<string>('value'))) and
        SameText(S.GetValue<string>('range.source'),UnitPath) then begin Selected:=S;Inc(Count);end;
    end;
    if Count<>1 then begin Warn('Missing or ambiguous declaring class for inherited root in '+F.GetValue<string>('path'));Exit;end;
    Edges:=0;
    for W in AView.Document.GetValue<TJSONArray>('semantics.relationships') do begin
      R:=W as TJSONObject;
      if (R.GetValue<string>('kind')='inherits') and (R.GetValue<string>('from')=Selected.GetValue<string>('key')) then begin
        Inc(Edges);BaseName:=R.GetValue<string>('label');
        if (R.GetValue<string>('condition','')<>'') or (Selected.GetValue<string>('condition','')<>'') then begin Warn('Conditional ancestor remains unresolved in '+UnitPath);Exit;end;
        S:=AView.Symbol(R.GetValue<string>('to',''));
        if S<>nil then BaseName:=S.GetValue<string>('name');
      end;
    end;
    if Edges<>1 then begin Warn('Missing or ambiguous ancestor edge in '+UnitPath);Exit;end;
    Result:=FindForm(BaseName);
  end;
  function BuildForm(F:TJSONObject;Depth:Integer):TJSONObject; forward;
  function BuildNode(F:TJSONObject;Index:Integer;Base:TJSONObject;Depth:Integer):TJSONObject;
  var Nodes:TJSONArray;N,P,Child,Target,Prop,History,Stamp,FrameFile:TJSONObject;
      V:TJSONValue;I,J,Matches,ChildIndex:Integer;Kind,Name:string;Children,Properties:TJSONArray;
  begin
    Inc(Work);if (Work>200000) or (Depth>64) then raise EInvalidOpException.Create('Form overlay work/depth limit reached');
    Nodes:=F.GetValue<TJSONArray>('ir.nodes');N:=Nodes.Items[Index] as TJSONObject;Kind:=N.GetValue<string>('kind');
    Result:=nil;
    if Kind='inline' then begin FrameFile:=FindForm(N.GetValue<string>('value'));if FrameFile<>nil then Result:=BuildForm(FrameFile,Depth+1);end
    else if Base<>nil then Result:=Base.Clone as TJSONObject;
    if Result=nil then Result:=TJSONObject.Create.AddPair('children',TJSONArray.Create).AddPair('properties',TJSONArray.Create).AddPair('declarations',TJSONArray.Create);
    try
      for Name in ['name','class','declaration','source','source_hash','generation_id','range','availability'] do Result.RemovePair(Name).Free;
      Result.AddPair('name',N.GetValue<string>('name')).AddPair('class',N.GetValue<string>('value')).AddPair('declaration',Kind);
      Stamp:=Origin(F,N);try
        for Name in ['source','source_hash','generation_id','range'] do Result.AddPair(Name,Stamp.GetValue(Name).Clone as TJSONValue);
        Result.GetValue<TJSONArray>('declarations').AddElement(Stamp.Clone as TJSONObject);
      finally Stamp.Free;end;
      Result.AddPair('availability',F.GetValue<string>('availability','unknown'));
      Children:=Result.GetValue<TJSONArray>('children');Properties:=Result.GetValue<TJSONArray>('properties');
      for I:=0 to Nodes.Count-1 do begin
        P:=Nodes.Items[I] as TJSONObject;if (P.GetValue<Integer>('parent')<>Index) or (P.GetValue<string>('kind')<>'property') then Continue;
        if StartsText('<',Trim(P.GetValue<string>('value'))) then Warn('Collection property '+P.GetValue<string>('name')+' in '+F.GetValue<string>('path')+': serialized history retained; collection-item merge is not resolved.');
        Prop:=nil;for V in Properties do if SameText(V.GetValue<string>('name'),P.GetValue<string>('name')) then begin Prop:=V as TJSONObject;Break;end;
        if Prop=nil then begin Prop:=TJSONObject.Create.AddPair('name',P.GetValue<string>('name')).AddPair('history',TJSONArray.Create);Properties.AddElement(Prop);end;
        History:=Origin(F,P);History.AddPair('value',P.GetValue<string>('value'));Prop.GetValue<TJSONArray>('history').AddElement(History);
        Prop.RemovePair('value').Free;Prop.AddPair('value',P.GetValue<string>('value'));
      end;
      for I:=0 to Nodes.Count-1 do begin
        P:=Nodes.Items[I] as TJSONObject;if (P.GetValue<Integer>('parent')<>Index) or not MatchText(P.GetValue<string>('kind'),['object','inherited','inline']) then Continue;
        Target:=nil;Matches:=0;ChildIndex:=-1;
        for J:=0 to Children.Count-1 do if SameText(Children.Items[J].GetValue<string>('name'),P.GetValue<string>('name')) then begin Target:=Children.Items[J] as TJSONObject;ChildIndex:=J;Inc(Matches);end;
        if (P.GetValue<string>('kind')='inherited') and (Matches=1) and SameText(Target.GetValue<string>('class'),P.GetValue<string>('value')) then begin
          Child:=BuildNode(F,I,Target,Depth+1);Children.Remove(ChildIndex).Free;Children.AddElement(Child);
        end else begin
          if (P.GetValue<string>('kind')='inherited') or (Matches>0) then Warn('Unresolved component overlay '+P.GetValue<string>('name')+' in '+F.GetValue<string>('path')+' (missing, duplicate or incompatible class).');
          Child:=BuildNode(F,I,nil,Depth+1);Children.AddElement(Child);
        end;
      end;
    except Result.Free;raise;end;
  end;
  function BuildForm(F:TJSONObject;Depth:Integer):TJSONObject;
  var N,B,ParentTree:TJSONObject;Path:string;Index:Integer;
  begin
    Result:=nil;Path:=F.GetValue<string>('path');
    if Active.Contains(LowerCase(Path)) then begin Warn('Cycle in form/frame inheritance: '+Path);Exit;end;
    if Depth>64 then begin Warn('Form/frame depth limit: '+Path);Exit;end;
    N:=RootNode(F);if N=nil then Exit;Active.Add(LowerCase(Path));ParentTree:=nil;
    try
      if not F.GetValue<Boolean>('ir.complete',False) then Warn('Partial parsed form: '+Path+'. Uncaptured declarations remain unknown.');
      if N.GetValue<string>('kind')='inherited' then begin B:=BaseForm(F,N);if B<>nil then ParentTree:=BuildForm(B,Depth+1);end;
      Index:=0;while F.GetValue<TJSONArray>('ir.nodes').Items[Index]<>N do Inc(Index);Result:=BuildNode(F,Index,ParentTree,Depth+1);
    finally ParentTree.Free;Active.Delete(Active.Count-1);end;
  end;
  procedure Flatten(N:TJSONObject;const FormPath,ParentPath:string);
  var Row:TJSONObject;V:TJSONValue;Path:string;
  begin
    if Rows.Count>=100000 then raise EInvalidOpException.Create('Form overlay output limit reached');
    Path:=ParentPath+'/'+N.GetValue<string>('name');Row:=N.Clone as TJSONObject;Row.RemovePair('children').Free;
    Row.AddPair('form_source',FormPath).AddPair('component_path',Path).AddPair('diagnostics',Issues.Clone as TJSONArray);
    Rows.AddElement(Row);for V in N.GetValue<TJSONArray>('children') do Flatten(V as TJSONObject,FormPath,Path);
  end;
begin
  Result:=TJSONObject.Create;Rows:=TJSONArray.Create;Result.AddPair('rows',Rows);
  Result.AddPair('qualification','Static serialized overlays only; framework defaults, collection-item merging, runtime changes and method dispatch are not inferred. Each property retains base-to-derived value history with exact source/hash/range. Event values are declarations, not observed calls. Missing/ambiguous bases, orphan overlays and cycles are reported. No target classes are instantiated.');
  Forms:=TList<TJSONObject>.Create;Active:=TList<string>.Create;Issues:=TJSONArray.Create;Work:=0;
  try
    try
      for FileValue in AView.Document.GetValue<TJSONArray>('syntax.files') do begin FileRow:=FileValue as TJSONObject;
        if MatchText(ExtractFileExt(FileRow.GetValue<string>('path')),['.dfm','.fmx']) and FileRow.TryGetValue<TJSONArray>('ir.nodes',CapturedNodes) then Forms.Add(FileRow);
      end;
      for FileRow in Forms do begin while Issues.Count>0 do Issues.Remove(0).Free;Tree:=BuildForm(FileRow,0);try if Tree<>nil then Flatten(Tree,FileRow.GetValue<string>('path'),'');finally Tree.Free;end;end;
    except Result.Free;raise;end;
  finally Issues.Free;Active.Free;Forms.Free;end;
end;

class function TDPHFormInheritance.Describe(ARow:TJSONObject):string;
var V,W:TJSONValue;P,O:TJSONObject;History:TJSONArray;
begin
  Result:='FORM INHERITANCE '+ARow.GetValue<string>('component_path')+' : '+ARow.GetValue<string>('class')+sLineBreak+
    'Selected form: '+ARow.GetValue<string>('form_source')+sLineBreak+'Latest declaration: '+ARow.GetValue<string>('source')+sLineBreak+
    'Generation: '+ARow.GetValue('generation_id').Value+sLineBreak+sLineBreak+'DECLARATION ORIGINS'+sLineBreak;
  for V in ARow.GetValue<TJSONArray>('declarations') do Result:=Result+V.GetValue<string>('source')+':'+IntToStr(V.GetValue<Integer>('range.line'))+' | SHA-256 '+V.GetValue<string>('source_hash')+sLineBreak;
  Result:=Result+sLineBreak+'SERIALIZED PROPERTY AND EVENT HISTORY (base to derived; latest serialized value shown)'+sLineBreak;
  for V in ARow.GetValue<TJSONArray>('properties') do begin P:=V as TJSONObject;History:=P.GetValue<TJSONArray>('history');
    Result:=Result+P.GetValue<string>('name')+' = '+P.GetValue<string>('value')+sLineBreak;
    for W in History do begin O:=W as TJSONObject;Result:=Result+'  '+O.GetValue<string>('value')+' | '+O.GetValue<string>('source')+':'+IntToStr(O.GetValue<Integer>('range.line'))+' | SHA-256 '+O.GetValue<string>('source_hash')+' | condition: '+O.GetValue<string>('condition','')+sLineBreak;end;
  end;
  Result:=Result+sLineBreak+'RESOLUTION GAPS'+sLineBreak;
  if ARow.GetValue<TJSONArray>('diagnostics').Count=0 then Result:=Result+'No unresolved serialized overlay in this form. Unserialized defaults and runtime behavior remain unknown.'+sLineBreak;
  for V in ARow.GetValue<TJSONArray>('diagnostics') do Result:=Result+V.Value+sLineBreak;
end;
end.
