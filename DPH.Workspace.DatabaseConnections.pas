unit DPH.Workspace.DatabaseConnections;
interface
uses System.JSON, DPH.Workspace.Model;
type
  TDPHDatabaseConnections = class
    class function Inspect(AView:TDPHWorkspaceView):TJSONObject; static;
    class function Describe(ARow:TJSONObject):string; static;
  end;
implementation
uses System.SysUtils,System.StrUtils,System.Classes,System.RegularExpressions,
  System.Generics.Collections;

class function TDPHDatabaseConnections.Inspect(AView:TDPHWorkspaceView):TJSONObject;
var Rows,Nodes,Properties,Links,Configuration:TJSONArray; FileValue,Value,Other:TJSONValue;
    FileRow,Node,PropertyNode,Row,RootNode,Target,Link,Setting,Symbol:TJSONObject;
    Groups:TObjectDictionary<Integer,TList<TJSONObject>>;
    Names:TObjectDictionary<string,TList<TJSONObject>>;
    Declarations:TDictionary<string,Boolean>; Definitions:TDictionary<string,TJSONObject>;
    Members:TList<TJSONObject>; Ordered:TList<TJSONObject>;
    Path,ComponentPath,Role,ClassName,Name,Reference,Key,Raw,Text,Field,TargetRole:string;
    I,Parent,Depth,Number,Count,OriginalCount:Integer; Match:TMatch; Found:Boolean;
  function Literal(const AText:string):string;
  begin
    Result:=Trim(AText);
    if (Length(Result)>=2) and (Result[1]='''') and (Result[Length(Result)]='''') then
      Result:=Copy(Result,2,Length(Result)-2).Replace('''''','''');
  end;
  function Identifier(const AText:string):Boolean;
  begin Result:=TRegEx.IsMatch(AText,'^[A-Za-z_][A-Za-z0-9_.-]{0,127}$');end;
  function ClassRole(const AClass:string):string;
  var ShortName:string;
  begin
    ShortName:=Copy(AClass,LastDelimiter('.',AClass)+1,MaxInt);Result:='';
    if MatchText(ShortName,['TFDConnection','TADOConnection','TSQLConnection','TDatabase','TIBDatabase','TSQLConnector','TZConnection','TUniConnection','TMyConnection','TPgConnection','TOraSession']) then Exit('connection');
    if MatchText(ShortName,['TFDQuery','TFDTable','TFDStoredProc','TFDCommand','TADOQuery','TADOTable','TADOStoredProc','TADODataSet','TSQLQuery','TSQLDataSet','TSQLTable','TSQLStoredProc','TQuery','TTable','TStoredProc','TIBQuery','TIBDataSet','TIBTable','TIBSQL','TZQuery','TZTable','TClientDataSet','TFDMemTable','TUniQuery','TMyQuery','TPgQuery']) then Exit('dataset');
    if SameText(ShortName,'TDataSource') then Exit('data source');
    if MatchText(ShortName,['TIBTransaction','TFDTransaction','TZTransaction','TSQLTransaction']) then Exit('transaction');
    if SameText(ShortName,'TSession') then Exit('session');
  end;
  procedure Index(const AKey:string; ARow:TJSONObject);
  var List:TList<TJSONObject>;
  begin
    if not Names.TryGetValue(LowerCase(AKey),List) then begin List:=TList<TJSONObject>.Create;Names.Add(LowerCase(AKey),List);end;
    List.Add(ARow);
  end;
  procedure Config(const AName,AValue:string;AProperty:TJSONObject);
  var SafeValue,Decoded,KnownName:string;N:Integer;
  begin
    KnownName:=AName;
    if not MatchText(KnownName,['DriverID','Protocol','Port','Connected','LoginPrompt','Server','Host','Database','DatabaseName','User_Name','UserName','User ID','UID','Password','PWD','Passwd','ConnectionString','Params','Params.Strings','Provider','ConnectionDefName','ConnectionName','SessionName','DatabaseName','SQLDialect','CharacterSet','CharSet','Authentication','Token','AccessToken','Secret','APIKey','Key','PrivateKey','SSLMode','OSAuthent','Trusted_Connection']) then KnownName:='[other configuration key]';
    Decoded:=Literal(AValue);SafeValue:='[REDACTED configuration value]';
    if MatchText(KnownName,['DriverID','Protocol','SQLDialect','CharacterSet','CharSet','SSLMode']) and Identifier(Decoded) then SafeValue:=Decoded;
    if SameText(KnownName,'Port') and TryStrToInt(Decoded,N) and (N>=1) and (N<=65535) then SafeValue:=IntToStr(N);
    if MatchText(KnownName,['Connected','LoginPrompt','OSAuthent','Trusted_Connection']) and MatchText(Decoded,['True','False','Yes','No']) then SafeValue:=Decoded;
    Setting:=TJSONObject.Create.AddPair('name',KnownName).AddPair('value',SafeValue);
    Setting.AddPair('line',AProperty.GetValue('line').Clone as TJSONValue).AddPair('start',AProperty.GetValue('start').Clone as TJSONValue).AddPair('end',AProperty.GetValue('end').Clone as TJSONValue);
    Configuration.AddElement(Setting);
  end;
begin
  Result:=TJSONObject.Create;Rows:=TJSONArray.Create;Result.AddPair('rows',Rows);
  Result.AddPair('qualification','Captured database declarations and references, not live connections. Known class names and property signals identify candidates; no driver, target class or production database is opened. Unique serialized references are lexical candidates, not runtime binding proof. Runtime assignments, inherited defaults, factories and external connection definitions remain unknown. Configuration values are masked except validated driver/protocol/dialect/charset/SSL identifiers, ports and booleans. Source hashes/locations identify the original evidence; original source/cache can contain secrets.');
  Groups:=TObjectDictionary<Integer,TList<TJSONObject>>.Create([doOwnsValues]);
  Names:=TObjectDictionary<string,TList<TJSONObject>>.Create([doOwnsValues]);
  Definitions:=TDictionary<string,TJSONObject>.Create;Declarations:=TDictionary<string,Boolean>.Create;Ordered:=TList<TJSONObject>.Create;
  try
    try
      for FileValue in AView.Document.GetValue<TJSONArray>('syntax.files') do begin
        FileRow:=FileValue as TJSONObject;Path:=FileRow.GetValue<string>('path');
        if not MatchText(ExtractFileExt(Path),['.dfm','.fmx']) or not FileRow.TryGetValue<TJSONArray>('ir.nodes',Nodes) then Continue;
        Groups.Clear;
        for Value in Nodes do begin
          PropertyNode:=Value as TJSONObject;if PropertyNode.GetValue<string>('kind')<>'property' then Continue;
          Parent:=PropertyNode.GetValue<Integer>('parent');
          if not Groups.TryGetValue(Parent,Members) then begin Members:=TList<TJSONObject>.Create;Groups.Add(Parent,Members);end;Members.Add(PropertyNode);
        end;
        for I:=0 to Nodes.Count-1 do begin
          Node:=Nodes.Items[I] as TJSONObject;if not MatchText(Node.GetValue<string>('kind'),['object','inherited','inline']) then Continue;
          ClassName:=Node.GetValue<string>('value');Role:=ClassRole(ClassName);
          if (Role='') and Groups.TryGetValue(I,Members) then for PropertyNode in Members do
            if MatchText(PropertyNode.GetValue<string>('name'),['Connection','SQLConnection','ADOConnection','Database','ConnectionDefName','ConnectionString','Params.Strings']) then begin Role:='database candidate';Break;end;
          if Role='' then Continue;
          if Rows.Count>=10000 then raise ERangeError.Create('Database inventory exceeds 10000 candidates; narrow the captured project');
          RootNode:=Node;ComponentPath:=Node.GetValue<string>('name');Parent:=Node.GetValue<Integer>('parent');
          for Depth:=0 to 127 do begin
            if Parent<0 then Break;RootNode:=Nodes.Items[Parent] as TJSONObject;ComponentPath:=RootNode.GetValue<string>('name')+'.'+ComponentPath;Parent:=RootNode.GetValue<Integer>('parent');
          end;
          if Parent>=0 then raise ERangeError.Create('Database component path exceeds supported nesting');
          Row:=TJSONObject.Create;Rows.AddElement(Row);Ordered.Add(Row);
          Row.AddPair('id',Path+'|'+ComponentPath+'|'+IntToStr(I)).AddPair('name',Node.GetValue<string>('name')).AddPair('path',ComponentPath).AddPair('class',ClassName).AddPair('role',Role);
          Row.AddPair('source',Path).AddPair('source_hash',FileRow.GetValue<string>('sha256','')).AddPair('availability',FileRow.GetValue<string>('availability','unknown'));
          Row.AddPair('generation_id',AView.Document.GetValue('generation_id').Clone as TJSONValue).AddPair('declaration',Node.GetValue<string>('kind'));
          Row.AddPair('range',TJSONObject.Create.AddPair('source',Path).AddPair('start',Node.GetValue('start').Clone as TJSONValue).AddPair('end',Node.GetValue('end').Clone as TJSONValue).AddPair('line',Node.GetValue('line').Clone as TJSONValue).AddPair('column',Node.GetValue('column').Clone as TJSONValue));
          Row.AddPair('root',RootNode.GetValue<string>('name'));Configuration:=TJSONArray.Create;Row.AddPair('configuration',Configuration);Links:=TJSONArray.Create;Row.AddPair('links',Links);Row.AddPair('used_by',TJSONArray.Create);
          Row.AddPair('unknowns','Missing properties, inherited values and runtime changes remain unknown. Named definitions are references only; no external definition file is read.');
          Index(Path+'|'+ComponentPath,Row);Index(ComponentPath,Row);
          if Groups.TryGetValue(I,Members) then for PropertyNode in Members do begin
            Name:=PropertyNode.GetValue<string>('name');Raw:=PropertyNode.GetValue<string>('value');
            if MatchText(Name,['Connection','SQLConnection','ADOConnection','Database','Transaction','UpdateTransaction','DefaultDatabase','DataSet','DataSource','Session','SessionName','DatabaseName','ConnectionDefName']) and not ((Role='connection') and (SameText(Name,'Database') or (SameText(Name,'DatabaseName') and not SameText(ClassName,'TDatabase')))) then begin
              Reference:=Literal(Raw);
              if not Identifier(Reference) or ((Trim(Raw)<>'') and (Trim(Raw)[1]='''') and not MatchText(Name,['ConnectionDefName','DatabaseName','SessionName'])) then Reference:='[unsupported reference expression]';
              Link:=TJSONObject.Create.AddPair('property',Name).AddPair('reference',Reference);Link.AddPair('line',PropertyNode.GetValue('line').Clone as TJSONValue);Links.AddElement(Link);
            end;
            if MatchText(Name,['Connection','SQLConnection','ADOConnection','Transaction','UpdateTransaction','DefaultDatabase','DataSet','DataSource','Session']) then Continue;
            if SameText(Name,'Params.Strings') then begin
              Config(Name,'',PropertyNode);
              for Match in TRegEx.Matches(Raw,'''((?:''''|[^''])*)''') do begin
                Text:=Match.Groups[1].Value.Replace('''''','''');Number:=Pos('=',Text);
                if Number>0 then Config(Trim(Copy(Text,1,Number-1)),Copy(Text,Number+1,MaxInt),PropertyNode);
              end;
            end else if MatchText(Name,['Params','ConnectionString','DriverID','Protocol','Port','Connected','LoginPrompt','Server','Host','Database','DatabaseName','User_Name','UserName','User ID','UID','Password','PWD','Passwd','Provider','ConnectionDefName','ConnectionName','SessionName','SQLDialect','CharacterSet','CharSet','Authentication','Token','AccessToken','Secret','APIKey','Key','PrivateKey','SSLMode','OSAuthent','Trusted_Connection']) then Config(Name,Raw,PropertyNode);
            if SameText(ClassName,'TDatabase') and SameText(Name,'DatabaseName') and Identifier(Literal(Raw)) then begin Index('alias:'+Literal(Raw),Row);Index(Path+'|'+Row.GetValue<string>('root')+'|alias:'+Literal(Raw),Row);end;
            if SameText(ClassName,'TSession') and SameText(Name,'SessionName') and Identifier(Literal(Raw)) then begin Index('session:'+Literal(Raw),Row);Index(Path+'|'+Row.GetValue<string>('root')+'|session:'+Literal(Raw),Row);end;
          end;
        end;
      end;
      // Existing semantic binding prevents duplicate field/component rows.
      for Value in AView.Document.GetValue<TJSONArray>('semantics.relationships') do
        if Value.GetValue<string>('kind')='component_field' then Declarations.AddOrSetValue(Value.GetValue<string>('to'),True);
      for Value in AView.Document.GetValue<TJSONArray>('semantics.symbols') do begin
        Symbol:=Value as TJSONObject;Role:=ClassRole(Symbol.GetValue<string>('type'));
        if (Role='') or not MatchText(Symbol.GetValue<string>('kind'),['field','variable','local']) or Declarations.ContainsKey(Symbol.GetValue<string>('key')) then Continue;
        if Rows.Count>=10000 then raise ERangeError.Create('Database inventory exceeds 10000 candidates');
        Row:=TJSONObject.Create;Rows.AddElement(Row);Row.AddPair('id',Symbol.GetValue<string>('key')).AddPair('name',Symbol.GetValue<string>('name')).AddPair('path',Symbol.GetValue<string>('name')).AddPair('class',Symbol.GetValue<string>('type')).AddPair('role',Role);
        Row.AddPair('source',Symbol.GetValue<string>('range.source')).AddPair('source_hash',Symbol.GetValue<string>('source_hash')).AddPair('generation_id',AView.Document.GetValue('generation_id').Clone as TJSONValue).AddPair('range',Symbol.GetValue('range').Clone as TJSONValue);
        Row.AddPair('availability','captured declaration').AddPair('declaration',Symbol.GetValue<string>('kind')).AddPair('configuration',TJSONArray.Create).AddPair('links',TJSONArray.Create).AddPair('used_by',TJSONArray.Create);
        Row.AddPair('unknowns','Pascal declaration only. Construction, configuration, reference assignments and actual connection state are unobserved.');
      end;
      OriginalCount:=Rows.Count;
      for Row in Ordered do for Value in Row.GetValue<TJSONArray>('links') do begin
        Link:=Value as TJSONObject;Name:=Link.GetValue<string>('property');Reference:=Link.GetValue<string>('reference');Members:=nil;Target:=nil;Count:=0;
        if SameText(Name,'ConnectionDefName') and Identifier(Reference) and not MatchText(Reference,['nil','null']) then begin
          Key:=LowerCase(Reference);
          if not Definitions.TryGetValue(Key,Target) then begin
            if Rows.Count>=10000 then raise ERangeError.Create('Database inventory exceeds 10000 rows including definitions');
            Target:=TJSONObject.Create;Rows.AddElement(Target);Definitions.Add(Key,Target);
            Target.AddPair('id','definition:'+Key).AddPair('name',Reference).AddPair('path',Reference).AddPair('role','connection definition').AddPair('class','named definition reference');
            Target.AddPair('source',Row.GetValue<string>('source')).AddPair('source_hash',Row.GetValue<string>('source_hash')).AddPair('generation_id',AView.Document.GetValue('generation_id').Clone as TJSONValue).AddPair('range',Row.GetValue('range').Clone as TJSONValue);
            Target.AddPair('declaration','external definition reference').AddPair('availability','definition contents unavailable').AddPair('configuration',TJSONArray.Create).AddPair('links',TJSONArray.Create).AddPair('used_by',TJSONArray.Create);
            Target.AddPair('unknowns','Name captured from ConnectionDefName. External definition contents, credentials, engine/version and environment overrides are unavailable. No INI, registry or production connection is accessed.');
          end;Count:=1;
        end else if Identifier(Reference) and not MatchText(Reference,['nil','null']) then begin
          if StartsText('Self.',Reference) then Delete(Reference,1,5);
          if SameText(Name,'DatabaseName') then begin
            if Row.GetValue<string>('role')<>'connection' then begin
              if not Names.TryGetValue(LowerCase(Row.GetValue<string>('source')+'|'+Row.GetValue<string>('root')+'|alias:'+Reference),Members) then Names.TryGetValue(LowerCase('alias:'+Reference),Members);
            end;
          end else if SameText(Name,'SessionName') then begin
            if Row.GetValue<string>('role')<>'session' then
              if not Names.TryGetValue(LowerCase(Row.GetValue<string>('source')+'|'+Row.GetValue<string>('root')+'|session:'+Reference),Members) then Names.TryGetValue(LowerCase('session:'+Reference),Members);
          end else begin
            Key:=Row.GetValue<string>('source')+'|'+Row.GetValue<string>('root')+'.'+Reference;
            if not Names.TryGetValue(LowerCase(Key),Members) and Reference.Contains('.') then Names.TryGetValue(LowerCase(Reference),Members);
          end;
          if Members<>nil then for Target in Members do begin
            TargetRole:=Target.GetValue<string>('role');Found:=False;
            if MatchText(Name,['Connection','SQLConnection','ADOConnection','Database','DefaultDatabase','DatabaseName']) then Found:=TargetRole='connection'
            else if MatchText(Name,['Transaction','UpdateTransaction']) then Found:=TargetRole='transaction'
            else if SameText(Name,'DataSet') then Found:=TargetRole='dataset'
            else if SameText(Name,'DataSource') then Found:=TargetRole='data source'
            else if MatchText(Name,['Session','SessionName']) then Found:=TargetRole='session';
            if Found then begin Inc(Count);Link.RemovePair('target_id').Free;Link.AddPair('target_id',Target.GetValue<string>('id'));end;
          end;
          Target:=nil;if Count=1 then for Target in Members do if Target.GetValue<string>('id')=Link.GetValue<string>('target_id') then Break;
        end;
        if Count=1 then begin
          Link.RemovePair('target_id').Free;
          Link.AddPair('resolution','unique captured lexical candidate').AddPair('target_id',Target.GetValue<string>('id'));
          Target.GetValue<TJSONArray>('used_by').AddElement(TJSONObject.Create.AddPair('id',Row.GetValue<string>('id')).AddPair('name',Row.GetValue<string>('path')).AddPair('property',Name));
        end else begin Link.RemovePair('target_id').Free;
          if MatchText(Link.GetValue<string>('reference'),['nil','null']) then Text:='explicit nil reference'
          else if Count>1 then Text:='ambiguous captured targets ('+IntToStr(Count)+')'
          else if (Name='DatabaseName') and (Row.GetValue<string>('role')='connection') then Text:='logical alias on connection; not a component reference'
          else if (Name='SessionName') and (Row.GetValue<string>('role')='session') then Text:='logical session alias; not a component reference'
          else Text:='unresolved or unsupported; external/inherited/runtime target unknown';
          Link.AddPair('resolution',Text);
        end;
      end;
      Result.AddPair('total',TJSONNumber.Create(Rows.Count)).AddPair('component_and_declaration_rows',TJSONNumber.Create(OriginalCount));
    except Result.Free;raise;end;
  finally Ordered.Free;Declarations.Free;Definitions.Free;Names.Free;Groups.Free;end;
end;
class function TDPHDatabaseConnections.Describe(ARow:TJSONObject):string;
var Value:TJSONValue;
begin
  Result:=UpperCase(ARow.GetValue<string>('role'))+' '+ARow.GetValue<string>('path')+' : '+ARow.GetValue<string>('class')+sLineBreak+
    'Generation '+ARow.GetValue('generation_id').Value+' | '+ARow.GetValue<string>('availability')+' | '+ARow.GetValue<string>('declaration')+sLineBreak+
    'Source '+ARow.GetValue<string>('source')+':'+ARow.GetValue<TJSONObject>('range').GetValue('line').Value+' | SHA256 '+ARow.GetValue<string>('source_hash')+sLineBreak+sLineBreak+'SAFE CONFIGURATION'+sLineBreak;
  for Value in ARow.GetValue<TJSONArray>('configuration') do Result:=Result+Value.GetValue<string>('name')+' = '+Value.GetValue<string>('value')+' | line '+Value.GetValue<TJSONValue>('line').Value+sLineBreak;
  Result:=Result+sLineBreak+'CAPTURED REFERENCES'+sLineBreak;
  for Value in ARow.GetValue<TJSONArray>('links') do Result:=Result+Value.GetValue<string>('property')+' -> '+Value.GetValue<string>('reference')+' | '+Value.GetValue<string>('resolution')+sLineBreak;
  Result:=Result+sLineBreak+'USED BY'+sLineBreak;
  for Value in ARow.GetValue<TJSONArray>('used_by') do Result:=Result+Value.GetValue<string>('name')+' via '+Value.GetValue<string>('property')+sLineBreak;
  Result:=Result+sLineBreak+'UNKNOWNS AND NEXT INVESTIGATION'+sLineBreak+ARow.GetValue<string>('unknowns')+sLineBreak+
    'Ask the maintainer which named definition and environment are intended; inspect approved configuration locally. Do not enter credentials into authored explanations. Serialized Connected=True is a declaration, not evidence of a successful connection. This inventory never opens a target database.';
end;
end.
