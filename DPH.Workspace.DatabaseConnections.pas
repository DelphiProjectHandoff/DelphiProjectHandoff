unit DPH.Workspace.DatabaseConnections;
interface
uses System.JSON, DPH.Workspace.Model;
type
  TDPHDatabaseConnections = class
  private
    class procedure AppendDataRules(AView:TDPHWorkspaceView;AInventory:TJSONObject); static;
    class procedure AttachTransactionPaths(AView:TDPHWorkspaceView;AInventory:TJSONObject); static;
    class procedure AppendOperations(AView:TDPHWorkspaceView;AInventory:TJSONObject); static;
    class procedure EvaluateEngines(AInventory:TJSONObject); static;
    class procedure ResolveFields(AInventory:TJSONObject); static;
  public
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
    Declarations,VisualReferences:TDictionary<string,Boolean>; Definitions:TDictionary<string,TJSONObject>;
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
    if MatchText(ShortName,['TDataSet','TFDQuery','TFDTable','TFDStoredProc','TFDCommand','TADOQuery','TADOTable','TADOStoredProc','TADODataSet','TSQLQuery','TSQLDataSet','TSQLTable','TSQLStoredProc','TQuery','TTable','TStoredProc','TIBQuery','TIBDataSet','TIBTable','TIBSQL','TZQuery','TZTable','TClientDataSet','TFDMemTable','TUniQuery','TMyQuery','TPgQuery']) then Exit('dataset');
    if MatchText(ShortName,['TDataSource','TBindSourceDB']) then Exit('data source');
    if MatchText(ShortName,['TField','TStringField','TWideStringField','TIntegerField','TLargeintField','TSmallintField','TWordField','TBooleanField','TFloatField','TCurrencyField','TBCDField','TFMTBCDField','TDateField','TTimeField','TDateTimeField','TSQLTimeStampField','TBlobField','TMemoField','TWideMemoField','TBytesField','TVarBytesField','TAutoIncField','TGuidField','TGraphicField']) then Exit('persistent field');
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
    if not MatchText(KnownName,['ServerVersion','DatabaseVersion','ClientVersion','DriverVersion','DriverID','Protocol','Port','Connected','LoginPrompt','Server','Host','Database','DatabaseName','User_Name','UserName','User ID','UID','Password','PWD','Passwd','ConnectionString','Params','Params.Strings','Provider','ConnectionDefName','ConnectionName','SessionName','DatabaseName','SQLDialect','CharacterSet','CharSet','Authentication','Token','AccessToken','Secret','APIKey','Key','PrivateKey','FieldName','FieldKind','DataField','Required','ReadOnly','Size','Precision','SSLMode','OSAuthent','Trusted_Connection']) then KnownName:='[other configuration key]';
    Decoded:=Literal(AValue);SafeValue:='[REDACTED configuration value]';
    if MatchText(KnownName,['DriverID','Protocol','SQLDialect','CharacterSet','CharSet','SSLMode']) and Identifier(Decoded) then SafeValue:=Decoded;
    if SameText(KnownName,'Port') and TryStrToInt(Decoded,N) and (N>=1) and (N<=65535) then SafeValue:=IntToStr(N);
    if MatchText(KnownName,['Connected','LoginPrompt','OSAuthent','Trusted_Connection']) and MatchText(Decoded,['True','False','Yes','No']) then SafeValue:=Decoded;
    if MatchText(KnownName,['ServerVersion','DatabaseVersion','ClientVersion','DriverVersion']) and TRegEx.IsMatch(Decoded,'^[0-9]{1,5}(\.[0-9]{1,5}){0,4}$') then SafeValue:=Decoded;
    if MatchText(KnownName,['FieldName','DataField','FieldKind']) and Identifier(Decoded) then SafeValue:=Decoded;
    if MatchText(KnownName,['Required','ReadOnly']) and MatchText(Decoded,['True','False']) then SafeValue:=Decoded;
    if MatchText(KnownName,['Size','Precision']) and TryStrToInt(Decoded,N) and (N>=0) and (N<=1000000) then SafeValue:=IntToStr(N);
    Setting:=TJSONObject.Create.AddPair('name',KnownName).AddPair('value',SafeValue);
    Setting.AddPair('line',AProperty.GetValue('line').Clone as TJSONValue).AddPair('start',AProperty.GetValue('start').Clone as TJSONValue).AddPair('end',AProperty.GetValue('end').Clone as TJSONValue);
    Configuration.AddElement(Setting);
  end;
begin
  Result:=TJSONObject.Create;Rows:=TJSONArray.Create;Result.AddPair('rows',Rows);
  Result.AddPair('qualification','Captured database declarations and references, not live connections. Known class names and property signals identify candidates; no driver, target class or production database is opened. Unique serialized references are lexical candidates, not runtime binding proof. Runtime assignments, inherited defaults, factories and external connection definitions remain unknown. Configuration values are masked except validated driver/protocol/dialect/charset/SSL identifiers, ports and booleans. Source hashes/locations identify the original evidence; original source/cache can contain secrets.');
  Groups:=TObjectDictionary<Integer,TList<TJSONObject>>.Create([doOwnsValues]);
  Names:=TObjectDictionary<string,TList<TJSONObject>>.Create([doOwnsValues]);
  Definitions:=TDictionary<string,TJSONObject>.Create;Declarations:=TDictionary<string,Boolean>.Create;VisualReferences:=TDictionary<string,Boolean>.Create;Ordered:=TList<TJSONObject>.Create;
  try
    try
      for FileValue in AView.Document.GetValue<TJSONArray>('syntax.files') do begin
        FileRow:=FileValue as TJSONObject;Path:=FileRow.GetValue<string>('path');
        if not MatchText(ExtractFileExt(Path),['.dfm','.fmx']) or not FileRow.TryGetValue<TJSONArray>('ir.nodes',Nodes) then Continue;
        Groups.Clear;VisualReferences.Clear;
        for Value in Nodes do begin
          PropertyNode:=Value as TJSONObject;if PropertyNode.GetValue<string>('kind')<>'property' then Continue;
          if SameText(PropertyNode.GetValue<string>('name'),'Control') then begin Reference:=PropertyNode.GetValue<string>('value');if Identifier(Reference) then VisualReferences.AddOrSetValue(LowerCase(Copy(Reference,LastDelimiter('.',Reference)+1,MaxInt)),True);end;
          Parent:=PropertyNode.GetValue<Integer>('parent');
          if not Groups.TryGetValue(Parent,Members) then begin Members:=TList<TJSONObject>.Create;Groups.Add(Parent,Members);end;Members.Add(PropertyNode);
        end;
        for I:=0 to Nodes.Count-1 do begin
          Node:=Nodes.Items[I] as TJSONObject;if not MatchText(Node.GetValue<string>('kind'),['object','inherited','inline']) then Continue;
          ClassName:=Node.GetValue<string>('value');Role:=ClassRole(ClassName);
          if (Role='') and Groups.TryGetValue(I,Members) then for PropertyNode in Members do
            if MatchText(PropertyNode.GetValue<string>('name'),['Connection','SQLConnection','ADOConnection','Database','ConnectionDefName','ConnectionString','Params.Strings']) then begin Role:='database candidate';Break;end;
          if (Role='') and Groups.TryGetValue(I,Members) then for PropertyNode in Members do
            if MatchText(PropertyNode.GetValue<string>('name'),['DataSource','BindSource']) then begin Role:='bound control';Break;end;
          if (Role='') and VisualReferences.ContainsKey(LowerCase(Node.GetValue<string>('name'))) then Role:='binding control target';
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
          if (Role='persistent field') and (Node.GetValue<Integer>('parent')>=0) then begin
            Parent:=LastDelimiter('.',ComponentPath);Reference:=Copy(ComponentPath,1,Parent-1);
            Links.AddElement(TJSONObject.Create.AddPair('property','DataSet').AddPair('reference',Reference).AddPair('line',Node.GetValue('line').Clone as TJSONValue).AddPair('basis','serialized field parent'));
          end;
          if Groups.TryGetValue(I,Members) then for PropertyNode in Members do begin
            Name:=PropertyNode.GetValue<string>('name');Raw:=PropertyNode.GetValue<string>('value');
            if MatchText(Name,['Connection','SQLConnection','ADOConnection','Database','Transaction','UpdateTransaction','DefaultDatabase','DataSet','DataSource','BindSource','LookupDataSet','DataField','Control','Session','SessionName','DatabaseName','ConnectionDefName']) and not ((Role='connection') and (SameText(Name,'Database') or (SameText(Name,'DatabaseName') and not SameText(ClassName,'TDatabase')))) or ((Role='bound control') and SameText(Name,'FieldName')) then begin
              Reference:=Literal(Raw);
              if not Identifier(Reference) or ((Trim(Raw)<>'') and (Trim(Raw)[1]='''') and not MatchText(Name,['ConnectionDefName','DatabaseName','SessionName','DataField','FieldName'])) then Reference:='[unsupported reference expression]';
              Link:=TJSONObject.Create.AddPair('property',Name).AddPair('reference',Reference);Link.AddPair('line',PropertyNode.GetValue('line').Clone as TJSONValue).AddPair('start',PropertyNode.GetValue('start').Clone as TJSONValue).AddPair('end',PropertyNode.GetValue('end').Clone as TJSONValue);Links.AddElement(Link);
            end;
            if MatchText(Name,['Connection','SQLConnection','ADOConnection','Transaction','UpdateTransaction','DefaultDatabase','DataSet','DataSource','Session']) then Continue;
            if SameText(Name,'Params.Strings') then begin
              Config(Name,'',PropertyNode);
              for Match in TRegEx.Matches(Raw,'''((?:''''|[^''])*)''') do begin
                Text:=Match.Groups[1].Value.Replace('''''','''');Number:=Pos('=',Text);
                if Number>0 then Config(Trim(Copy(Text,1,Number-1)),Copy(Text,Number+1,MaxInt),PropertyNode);
              end;
            end else if MatchText(Name,['ServerVersion','DatabaseVersion','ClientVersion','DriverVersion','Params','ConnectionString','DriverID','Protocol','Port','Connected','LoginPrompt','Server','Host','Database','DatabaseName','User_Name','UserName','User ID','UID','Password','PWD','Passwd','Provider','ConnectionDefName','ConnectionName','SessionName','SQLDialect','CharacterSet','CharSet','Authentication','Token','AccessToken','Secret','APIKey','Key','PrivateKey','FieldName','FieldKind','DataField','Required','ReadOnly','Size','Precision','SSLMode','OSAuthent','Trusted_Connection']) then Config(Name,Raw,PropertyNode);
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
        if MatchText(Name,['DataField','FieldName']) then Continue;
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
            if StartsText(Row.GetValue<string>('root')+'.',Reference) then Key:=Row.GetValue<string>('source')+'|'+Reference;
            if not Names.TryGetValue(LowerCase(Key),Members) and Reference.Contains('.') then Names.TryGetValue(LowerCase(Reference),Members);
          end;
          if Members<>nil then for Target in Members do begin
            TargetRole:=Target.GetValue<string>('role');Found:=False;
            if MatchText(Name,['Connection','SQLConnection','ADOConnection','Database','DefaultDatabase','DatabaseName']) then Found:=TargetRole='connection'
            else if MatchText(Name,['Transaction','UpdateTransaction']) then Found:=TargetRole='transaction'
            else if MatchText(Name,['DataSet','LookupDataSet']) then Found:=TargetRole='dataset'
            else if MatchText(Name,['DataSource','BindSource']) then Found:=TargetRole='data source'
            else if SameText(Name,'Control') then Found:=MatchText(TargetRole,['binding control target','bound control'])
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
      ResolveFields(Result);
      AppendOperations(AView,Result);
      AttachTransactionPaths(AView,Result);
      AppendDataRules(AView,Result);
      EvaluateEngines(Result);
      Result.AddPair('total',TJSONNumber.Create(Rows.Count)).AddPair('component_and_declaration_rows',TJSONNumber.Create(OriginalCount));
    except Result.Free;raise;end;
  finally VisualReferences.Free;Ordered.Free;Declarations.Free;Definitions.Free;Names.Free;Groups.Free;end;
end;
class procedure TDPHDatabaseConnections.AppendOperations(AView:TDPHWorkspaceView;AInventory:TJSONObject);
var Rows,Relations:TJSONArray;V,W:TJSONValue;Row,Target,Symbol,Relation,Link:TJSONObject;
    Symbols,Receivers,Locations:TDictionary<string,TJSONObject>;
    ID,Key,Kind,Method,Effect,Basis,SQL,Owner,Reference:string;Count:Integer;Match:TMatch;
  function LocationKey(AValue:TJSONObject):string;
  begin Result:=AValue.GetValue<string>('range.source')+'|'+AValue.GetValue<TJSONValue>('range.start').Value;end;
  procedure Remember(AIndex:TDictionary<string,TJSONObject>;const AKey:string;AValue:TJSONObject);
  begin if AIndex.ContainsKey(AKey) then AIndex[AKey]:=nil else AIndex.Add(AKey,AValue);end;
begin
 Rows:=AInventory.GetValue<TJSONArray>('rows');Relations:=AView.Document.GetValue<TJSONArray>('semantics.relationships');
 Symbols:=TDictionary<string,TJSONObject>.Create;Receivers:=TDictionary<string,TJSONObject>.Create;Locations:=TDictionary<string,TJSONObject>.Create;
 try
  for V in AView.Document.GetValue<TJSONArray>('semantics.symbols') do begin Symbol:=V as TJSONObject;Symbols.Add(Symbol.GetValue<string>('key'),Symbol);end;
  for V in Rows do begin Row:=V as TJSONObject;Remember(Receivers,Row.GetValue<string>('id'),Row);Remember(Locations,LocationKey(Row),Row);end;
  for V in Relations do if V.GetValue<string>('kind')='component_field' then
    if Symbols.TryGetValue(V.GetValue<string>('from'),Symbol) and Locations.TryGetValue(LocationKey(Symbol),Target) and (Target<>nil) then
      Remember(Receivers,V.GetValue<string>('to'),Target);
  Count:=0;
  for V in Relations do begin
   Relation:=V as TJSONObject;Basis:=Relation.GetValue<string>('kind');
   if not MatchText(Basis,['database_operation','database_transaction','static_sql','dynamic_sql']) then Continue;
   Kind:='unknown';Method:=Relation.GetValue<string>('label');Effect:='Operation type and affected objects require approved source review.';
   if Basis='database_transaction' then begin
    if MatchText(Method,['StartTransaction','BeginTransaction','BeginTrans']) then begin Kind:='begin transaction';Effect:='Requests starting a transaction or nested savepoint. Provider settings, nesting depth and successful activation are unobserved.';end
    else if MatchText(Method,['Commit','CommitTrans','CommitFreeAndNil']) then begin Kind:='commit request';Effect:='Requests committing the current transaction. The call can raise; a later rollback path does not prove that committed changes were undone.';end
    else if SameText(Method,'CommitRetaining') then begin Kind:='commit retaining request';Effect:='Requests committing while retaining or restarting transaction context. Provider emulation and nested savepoint behavior require review.';end
    else if SameText(Method,'RollbackSavepoint') then begin Kind:='rollback savepoint request';Effect:='Requests rolling back a named savepoint, not necessarily the entire transaction. Savepoint identity and successful rollback remain unobserved.';end
    else if SameText(Method,'RollbackRetaining') then begin Kind:='rollback retaining request';Effect:='Requests undoing pending changes while retaining or restarting transaction context. Runtime success and provider behavior remain unobserved.';end
    else begin Kind:='rollback request';Effect:='Requests rolling back pending transaction changes. The request itself can raise. Previously committed changes, implicit commits and external side effects are not proved undone.';end;
    Basis:='Recognized API on a declared framework connection/transaction or captured descendant. Intraprocedural paths below are conservative source possibilities.';
   end else if Basis='database_operation' then begin
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
     SQL:=TRegEx.Replace(SQL,'(?s)/\*.*?\*/',' ');SQL:=TRegEx.Replace(SQL,'--[^\r\n]*',' ');SQL:=Trim(SQL);
     if SQL.EndsWith(';') then SQL:=Trim(Copy(SQL,1,Length(SQL)-1));
     Match:=TRegEx.Match(SQL,'(?i)^\s*(SELECT|INSERT|UPDATE|DELETE)\b');
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
   if Relation.GetValue<string>('kind')='database_transaction' then begin Row.RemovePair('role').Free;Row.AddPair('role','transaction operation');end;
   Row.AddPair('routine_key',Relation.GetValue<string>('from')).AddPair('receiver_key',Relation.GetValue<string>('to',''));
   Row.AddPair('operation_kind',Kind).AddPair('effect',Effect).AddPair('basis',Basis).AddPair('condition',Relation.GetValue<string>('condition'));
   Row.AddPair('source',Relation.GetValue<string>('range.source')).AddPair('source_hash',Relation.GetValue<string>('source_hash')).AddPair('range',Relation.GetValue('range').Clone as TJSONValue).AddPair('generation_id',AView.Document.GetValue('generation_id').Clone as TJSONValue);
   Row.AddPair('availability','captured operation candidate').AddPair('declaration','source evidence, not execution evidence').AddPair('configuration',TJSONArray.Create).AddPair('links',TJSONArray.Create).AddPair('used_by',TJSONArray.Create);
   Row.AddPair('unknowns','No SQL or target application was executed. Values, current record, affected row counts, access permissions, triggers, commit and rollback are unobserved. Review the calling routine and provider configuration.');
   Target:=nil;Reference:='unresolved receiver';
   if Relation.TryGetValue<string>('to',Key) and Symbols.TryGetValue(Key,Symbol) then begin
    Reference:=Symbol.GetValue<string>('name');
    if not Receivers.TryGetValue(Key,Target) and MatchText(Relation.GetValue<string>('kind'),['database_operation','database_transaction']) then begin
     if Rows.Count>=10000 then raise ERangeError.Create('Database inventory exceeds 10000 rows including operation receivers');
     Target:=TJSONObject.Create;Rows.AddElement(Target);Receivers.Add(Key,Target);
     Target.AddPair('id',Key).AddPair('name',Reference).AddPair('path',Reference).AddPair('class',Symbol.GetValue<string>('type')).AddPair('role',IfThen(Relation.GetValue<string>('kind')='database_transaction','transaction','dataset'));
     Target.AddPair('source',Symbol.GetValue<string>('range.source')).AddPair('source_hash',Symbol.GetValue<string>('source_hash')).AddPair('range',Symbol.GetValue('range').Clone as TJSONValue).AddPair('generation_id',AView.Document.GetValue('generation_id').Clone as TJSONValue);
     Target.AddPair('availability','captured database receiver declaration').AddPair('declaration',Symbol.GetValue<string>('kind')).AddPair('configuration',TJSONArray.Create).AddPair('links',TJSONArray.Create).AddPair('used_by',TJSONArray.Create);
     Target.AddPair('unknowns','Receiver has a captured database API ancestry. Runtime instance, inherited/custom API overrides, connection and configuration are unobserved.');
    end;
   end;
   Link:=TJSONObject.Create.AddPair('property',IfThen(Relation.GetValue<string>('kind')='database_transaction','Transaction','DataSet')).AddPair('reference',Reference);Row.GetValue<TJSONArray>('links').AddElement(Link);
   if (Target<>nil) and MatchText(Target.GetValue<string>('role'),['dataset','connection','transaction']) then begin
    Link.AddPair('target_id',Target.GetValue<string>('id')).AddPair('resolution','unique captured semantic receiver');
    Target.GetValue<TJSONArray>('used_by').AddElement(TJSONObject.Create.AddPair('id',ID).AddPair('name',Row.GetValue<string>('path')).AddPair('property','operation receiver'));
   end else Link.AddPair('resolution','receiver unavailable, ambiguous or outside recognized database inventory');
  end;
  AInventory.AddPair('operation_count',TJSONNumber.Create(Count));
 finally Locations.Free;Receivers.Free;Symbols.Free;end;
end;

class procedure TDPHDatabaseConnections.AttachTransactionPaths(AView:TDPHWorkspaceView;AInventory:TJSONObject);
var Nodes,Edges,Rows,Paths,Origins:TJSONArray;V,X:TJSONValue;Row,Node,Edge,Target,Route:TJSONObject;
    ByRoutine:TObjectDictionary<string,TList<TJSONObject>>;
    Outgoing:TObjectDictionary<Integer,TList<TJSONObject>>;
    AtNode:TObjectDictionary<Integer,TList<TJSONObject>>;
    NodeIndex:TDictionary<Integer,TJSONObject>;Starts:TObjectDictionary<string,TList<Integer>>;
    Seen,Published:TDictionary<string,Boolean>;Trace:TDictionary<string,string>;
    Candidates:TList<TJSONObject>;IDs:TList<Integer>;Targets:TList<TJSONObject>;
    Queue:TQueue<TPair<Integer,Integer>>;State:TPair<Integer,Integer>;
    I,N,Width,Best,Flags,NextFlags,Steps,TotalSteps,Count:Integer;
    Key,NextKey,LabelText,RouteKey,EdgeKind,TraceText:string;
    Truncated,Stopped,Ambiguous:Boolean;
  function SameReceiver(A,B:TJSONObject):Boolean;
  begin Result:=(A.GetValue<string>('receiver_key')<>'') and (A.GetValue<string>('receiver_key')=B.GetValue<string>('receiver_key'));end;
  function StateKey(ANode,AFlags:Integer):string;
  begin Result:=IntToStr(ANode)+'|'+IntToStr(AFlags);end;
begin
 Rows:=AInventory.GetValue<TJSONArray>('rows');Nodes:=AView.Document.GetValue<TJSONArray>('semantics.flow_nodes');Edges:=AView.Document.GetValue<TJSONArray>('semantics.flow_edges');
 ByRoutine:=TObjectDictionary<string,TList<TJSONObject>>.Create([doOwnsValues]);Outgoing:=TObjectDictionary<Integer,TList<TJSONObject>>.Create([doOwnsValues]);
 AtNode:=TObjectDictionary<Integer,TList<TJSONObject>>.Create([doOwnsValues]);NodeIndex:=TDictionary<Integer,TJSONObject>.Create;
 Starts:=TObjectDictionary<string,TList<Integer>>.Create([doOwnsValues]);Seen:=TDictionary<string,Boolean>.Create;Published:=TDictionary<string,Boolean>.Create;Trace:=TDictionary<string,string>.Create;Queue:=TQueue<TPair<Integer,Integer>>.Create;
 try
  for V in Nodes do begin
   Node:=V as TJSONObject;NodeIndex.Add(Node.GetValue<Integer>('id'),Node);Key:=Node.GetValue<string>('routine');
   if not ByRoutine.TryGetValue(Key,Candidates) then begin Candidates:=TList<TJSONObject>.Create;ByRoutine.Add(Key,Candidates);end;Candidates.Add(Node);
  end;
  for V in Edges do begin
   Edge:=V as TJSONObject;I:=Edge.GetValue<Integer>('from');
   if not Outgoing.TryGetValue(I,Candidates) then begin Candidates:=TList<TJSONObject>.Create;Outgoing.Add(I,Candidates);end;Candidates.Add(Edge);
  end;
  Count:=0;
  for V in Rows do begin
   Row:=V as TJSONObject;if Row.GetValue<string>('role')<>'transaction operation' then Continue;Inc(Count);
   IDs:=TList<Integer>.Create;Starts.Add(Row.GetValue<string>('id'),IDs);Best:=MaxInt;
   Row.AddPair('transaction_paths',TJSONArray.Create);
   Truncated:=ByRoutine.TryGetValue(Row.GetValue<string>('routine_key'),Candidates) and (Candidates.Count>10000);
   Row.AddPair('flow_mapping_truncated',TJSONBool.Create(Truncated));
   if ByRoutine.TryGetValue(Row.GetValue<string>('routine_key'),Candidates) and (Candidates.Count<=10000) then begin
    for Node in Candidates do begin
     if MatchText(Node.GetValue<string>('kind'),['entry','normal_exit','exception_exit','exception_dispatch','try']) then Continue;
     if (Node.GetValue<string>('range.source')<>Row.GetValue<string>('source')) or
       (Node.GetValue<Integer>('range.start')>Row.GetValue<Integer>('range.start')) or
       (Node.GetValue<Integer>('range.end')<Row.GetValue<Integer>('range.end')) then Continue;
     Width:=Node.GetValue<Integer>('range.end')-Node.GetValue<Integer>('range.start');
     if Width<Best then begin IDs.Clear;Best:=Width;end;
     if Width=Best then IDs.Add(Node.GetValue<Integer>('id'));
    end;
   end;
   for I in IDs do begin
    if not AtNode.TryGetValue(I,Targets) then begin Targets:=TList<TJSONObject>.Create;AtNode.Add(I,Targets);end;Targets.Add(Row);
   end;
   Row.AddPair('flow_node_count',TJSONNumber.Create(IDs.Count));Origins:=TJSONArray.Create;Row.AddPair('flow_origin_nodes',Origins);
   for I in IDs do Origins.AddElement(TJSONNumber.Create(I));
  end;
  TotalSteps:=0;
  for V in Rows do begin
   Row:=V as TJSONObject;if Row.GetValue<string>('role')<>'transaction operation' then Continue;
   Paths:=Row.GetValue<TJSONArray>('transaction_paths');IDs:=Starts[Row.GetValue<string>('id')];
   Seen.Clear;Published.Clear;Trace.Clear;Queue.Clear;Steps:=0;Truncated:=Row.GetValue<Boolean>('flow_mapping_truncated');Ambiguous:=False;
   for I in IDs do if AtNode[I].Count>1 then Ambiguous:=True;
   if not Ambiguous then for I in IDs do begin
    Flags:=0;if IDs.Count>1 then Flags:=4;
    Key:=StateKey(I,Flags);Seen.AddOrSetValue(Key,True);Trace.AddOrSetValue(Key,'');Queue.Enqueue(TPair<Integer,Integer>.Create(I,Flags));
   end;
   while Queue.Count>0 do begin
    if (Steps>=5000) or (TotalSteps>=1000000) or (Paths.Count>=64) then begin Truncated:=True;Break;end;
    State:=Queue.Dequeue;Inc(Steps);Inc(TotalSteps);Key:=StateKey(State.Key,State.Value);
    if not Outgoing.TryGetValue(State.Key,Candidates) then Continue;
    for Edge in Candidates do begin
     N:=Edge.GetValue<Integer>('to');if not NodeIndex.TryGetValue(N,Node) or (Node.GetValue<string>('routine')<>Row.GetValue<string>('routine_key')) then Continue;
     EdgeKind:=Edge.GetValue<string>('kind');NextFlags:=State.Value;
     if ContainsText(EdgeKind,'raise') or MatchText(EdgeKind,['possible_handler','possibly_unhandled']) then NextFlags:=NextFlags or 1;
     if MatchText(EdgeKind,['true','false','iterate','loop_exit','case_match','case_else','case_no_match','possible_branch','possible_fallthrough']) then NextFlags:=NextFlags or 2;
     Stopped:=False;Target:=nil;
     if AtNode.TryGetValue(N,Targets) then for X in Targets do begin
      if not SameReceiver(Row,X as TJSONObject) then Continue;
      if Targets.Count>1 then begin Ambiguous:=True;Stopped:=True;Break;end;
      Target:=X as TJSONObject;Stopped:=True;if Starts[Target.GetValue<string>('id')].Count>1 then NextFlags:=NextFlags or 4;Break;
     end;
       if (Target<>nil) or MatchText(Node.GetValue<string>('kind'),['normal_exit','exception_exit']) then begin
      if (NextFlags and 1)<>0 then LabelText:='possible exception path' else LabelText:='possible normal path';
      if (NextFlags and 2)<>0 then LabelText:=LabelText+' (conditional/loop)';
      if (NextFlags and 4)<>0 then LabelText:=LabelText+' through cleanup copies';
      RouteKey:=IntToStr(N)+'|'+IntToStr(NextFlags);if Target<>nil then RouteKey:=Target.GetValue<string>('id')+'|'+IntToStr(NextFlags);
      if not Published.ContainsKey(RouteKey) and (Paths.Count>=64) then Truncated:=True;
      if not Published.ContainsKey(RouteKey) and (Paths.Count<64) then begin
       Published.Add(RouteKey,True);Route:=TJSONObject.Create;Paths.AddElement(Route);
       Route.AddPair('path_kind',LabelText).AddPair('flow_from',TJSONNumber.Create(State.Key)).AddPair('flow_to',TJSONNumber.Create(N));
       TraceText:=Trace[Key];if not ContainsText('|'+TraceText+'|','|'+EdgeKind+'|') then begin if TraceText<>'' then TraceText:=TraceText+'|';TraceText:=TraceText+EdgeKind;end;
       Route.AddPair('edge_kinds',TraceText).AddPair('resolution','conservative intraprocedural possibility, not execution');
       if Target<>nil then begin
        Route.AddPair('target_id',Target.GetValue<string>('id')).AddPair('target',Target.GetValue<string>('path'));
        Row.GetValue<TJSONArray>('links').AddElement(TJSONObject.Create.AddPair('property',LabelText).AddPair('reference',Target.GetValue<string>('path')).AddPair('target_id',Target.GetValue<string>('id')).AddPair('resolution','possible control-flow route; same declared receiver'));
        Target.GetValue<TJSONArray>('used_by').AddElement(TJSONObject.Create.AddPair('id',Row.GetValue<string>('id')).AddPair('name',Row.GetValue<string>('path')).AddPair('property',LabelText));
       end else Route.AddPair('target',Node.GetValue<string>('kind')+' without another explicit boundary on this receiver');
      end;
      Stopped:=True;
     end;
     if Stopped then Continue;
     NextKey:=StateKey(N,NextFlags);if Seen.ContainsKey(NextKey) then Continue;
     Seen.Add(NextKey,True);TraceText:=Trace[Key];if not ContainsText('|'+TraceText+'|','|'+EdgeKind+'|') then begin if TraceText<>'' then TraceText:=TraceText+'|';TraceText:=TraceText+EdgeKind;end;
     Trace.Add(NextKey,TraceText);Queue.Enqueue(TPair<Integer,Integer>.Create(N,NextFlags));
    end;
   end;
   Row.AddPair('flow_truncated',TJSONBool.Create(Truncated)).AddPair('flow_ambiguous',TJSONBool.Create(Ambiguous)).AddPair('flow_states_examined',TJSONNumber.Create(Steps));
   Row.AddPair('flow_qualification','Paths follow captured routine CFG edges to the next explicit API boundary on the same declared receiver or routine exit. Exception edges are possibilities; typed handlers, branch feasibility, aliases, interprocedural calls, implicit/automatic commits, savepoint names, server behavior and transaction activation remain unverified. Duplicated finalizer nodes retain separate pending transfers. Multiple calls in one statement are not ordered. Missing/truncated CFG is not proof of a safe exit.');
  end;
  AInventory.AddPair('transaction_operation_count',TJSONNumber.Create(Count));
 finally Queue.Free;Trace.Free;Published.Free;Seen.Free;Starts.Free;NodeIndex.Free;AtNode.Free;Outgoing.Free;ByRoutine.Free;end;
end;

class procedure TDPHDatabaseConnections.AppendDataRules(AView:TDPHWorkspaceView;AInventory:TJSONObject);
var Rows,Symbols,Relations,Flows,Nodes,BodyNodes:TJSONArray;V,F,P,C,E,B,N:TJSONValue;
    Owner,FileRow,PropertyNode,Rule,Handler,Flow,ReferenceRow,FlowIR:TJSONObject;
    BySymbol:TDictionary<string,TJSONObject>;Hooks:TObjectDictionary<string,TList<TJSONObject>>;
    RoutineFlows:TObjectDictionary<string,TList<TJSONObject>>;List:TList<TJSONObject>;
    Original,I,J,K,Parent,Count,FlowIndex,ExprCount,EvidenceStart,EvidenceEnd:Integer;FirstExpr,SecondExpr:TJSONObject;Key,Name,Text,Kind,ID,HandlerKey,ExpressionText:string;
    Seen:TDictionary<string,Boolean>;Truncated:Boolean;
  function Safe(const S:string):string;
  var J:Integer;Comment:Boolean;Closer:string;
  begin
   Result:='';J:=1;Comment:=False;Closer:='';
   while J<=Length(S) do begin
    if Comment then begin
     if Copy(S,J,Length(Closer))=Closer then begin Inc(J,Length(Closer));Comment:=False;end else Inc(J);Continue;
    end;
    if S[J]='''' then begin
     Result:=Result+'[literal omitted]';Inc(J);
     while J<=Length(S) do begin
      if S[J]='''' then begin Inc(J);if (J<=Length(S)) and (S[J]='''') then Inc(J) else begin Break;end;end else Inc(J);
     end;
     Continue;
    end;
    if S[J]='{' then begin Comment:=True;Closer:='}';Inc(J);Continue;end;
    if Copy(S,J,2)='(*' then begin Comment:=True;Closer:='*)';Inc(J,2);Continue;end;
    if Copy(S,J,2)='//' then begin while (J<=Length(S)) and not CharInSet(S[J],[#10,#13]) do Inc(J);Continue;end;
    if S[J]='#' then begin
     Result:=Result+'[character code omitted]';Inc(J);while (J<=Length(S)) and CharInSet(S[J],[#9,#10,#13,' ']) do Inc(J);while (J<=Length(S)) and CharInSet(S[J],['0'..'9','A'..'F','a'..'f','$']) do Inc(J);Continue;
    end;
    Result:=Result+S[J];Inc(J);
   end;
   Result:=Trim(Result);if Length(Result)>2048 then Result:=Copy(Result,1,2048)+' [expression truncated]';
  end;
  function NewRule(const AKind,AName,ASource,AHash:string;ARange:TJSONObject;AOwner:TJSONObject):TJSONObject;
  begin
   Result:=nil;if Rows.Count>=10000 then begin Truncated:=True;Exit;end;
   ID:='rule:'+IntToStr(Rows.Count);Result:=TJSONObject.Create;Rows.AddElement(Result);Inc(Count);
   Result.AddPair('id',ID).AddPair('name',AName).AddPair('path',AOwner.GetValue<string>('path')+' / '+AName).AddPair('class',AKind).AddPair('role','data rule');
   Result.AddPair('rule_kind',AKind).AddPair('source',ASource).AddPair('source_hash',AHash).AddPair('range',ARange.Clone as TJSONValue).AddPair('generation_id',AView.Document.GetValue('generation_id').Clone as TJSONValue);
   Result.AddPair('declaration','captured rule evidence').AddPair('availability','source candidate, not enforced behavior').AddPair('configuration',TJSONArray.Create).AddPair('links',TJSONArray.Create).AddPair('used_by',TJSONArray.Create);
   Result.AddPair('input','unknown').AddPair('output','unknown').AddPair('constraint','unknown').AddPair('expression','').AddPair('condition','');
   Result.AddPair('unknowns','This is captured configuration or source evidence. Actual values, event dispatch, inherited defaults, validation outcome, database constraints, aliases and external effects remain unobserved. Handler context is not proof that every statement validates its associated field.');
   Result.GetValue<TJSONArray>('links').AddElement(TJSONObject.Create.AddPair('property','rule context').AddPair('reference',AOwner.GetValue<string>('path')).AddPair('target_id',AOwner.GetValue<string>('id')).AddPair('resolution','exact captured context, not proven field effect'));
   AOwner.GetValue<TJSONArray>('used_by').AddElement(TJSONObject.Create.AddPair('id',ID).AddPair('name',Result.GetValue<string>('path')).AddPair('property','rule evidence'));
  end;
  procedure SetText(ARow:TJSONObject;const AName,AValue:string);
  begin ARow.RemovePair(AName).Free;ARow.AddPair(AName,AValue);end;
  function SymbolRow(const AKey:string):TJSONObject;
  var S:TJSONObject;Item:TJSONValue;
  begin
   Result:=nil;if not BySymbol.TryGetValue(AKey,S) then Exit;
   for Item in Rows do if Item.GetValue<string>('id')=AKey then Exit(Item as TJSONObject);
   if Rows.Count>=10000 then begin Truncated:=True;Exit;end;
   Result:=TJSONObject.Create;Rows.AddElement(Result);
   Result.AddPair('id',AKey).AddPair('name',S.GetValue<string>('name')).AddPair('path',S.GetValue<string>('name')).AddPair('class',S.GetValue<string>('type')).AddPair('role','rule declaration');
   Result.AddPair('source',S.GetValue<string>('range.source')).AddPair('source_hash',S.GetValue<string>('source_hash')).AddPair('range',S.GetValue('range').Clone as TJSONValue).AddPair('generation_id',AView.Document.GetValue('generation_id').Clone as TJSONValue);
   Result.AddPair('declaration',S.GetValue<string>('kind')).AddPair('availability','captured declaration').AddPair('configuration',TJSONArray.Create).AddPair('links',TJSONArray.Create).AddPair('used_by',TJSONArray.Create).AddPair('unknowns','Lexical declaration only; reaching definitions, runtime values and dispatch are unobserved.');
  end;
  procedure LinkSymbol(ARow:TJSONObject;const AKey,AProperty:string);
  var Target:TJSONObject;
  begin
   Target:=SymbolRow(AKey);if Target=nil then Exit;
   ARow.GetValue<TJSONArray>('links').AddElement(TJSONObject.Create.AddPair('property',AProperty).AddPair('reference',Target.GetValue<string>('path')).AddPair('target_id',Target.GetValue<string>('id')).AddPair('resolution','captured lexical relation; not reaching-value proof'));
   Target.GetValue<TJSONArray>('used_by').AddElement(TJSONObject.Create.AddPair('id',ARow.GetValue<string>('id')).AddPair('name',ARow.GetValue<string>('path')).AddPair('property',AProperty));
  end;
begin
 Rows:=AInventory.GetValue<TJSONArray>('rows');Original:=Rows.Count;Count:=0;Truncated:=False;
 Symbols:=AView.Document.GetValue<TJSONArray>('semantics.symbols');Relations:=AView.Document.GetValue<TJSONArray>('semantics.relationships');Flows:=AView.Document.GetValue<TJSONArray>('semantics.flow_nodes');
 BySymbol:=TDictionary<string,TJSONObject>.Create;Hooks:=TObjectDictionary<string,TList<TJSONObject>>.Create([doOwnsValues]);RoutineFlows:=TObjectDictionary<string,TList<TJSONObject>>.Create([doOwnsValues]);Seen:=TDictionary<string,Boolean>.Create;
 try
  for V in Symbols do BySymbol.Add(V.GetValue<string>('key'),V as TJSONObject);
  for V in Relations do if V.GetValue<string>('kind')='binds' then begin
   Key:=V.GetValue<string>('from');if not Hooks.TryGetValue(Key,List) then begin List:=TList<TJSONObject>.Create;Hooks.Add(Key,List);end;List.Add(V as TJSONObject);
  end;
  for V in Flows do begin Key:=V.GetValue<string>('routine');if not RoutineFlows.TryGetValue(Key,List) then begin List:=TList<TJSONObject>.Create;RoutineFlows.Add(Key,List);end;List.Add(V as TJSONObject);end;
  for I:=0 to Original-1 do begin
   Owner:=Rows.Items[I] as TJSONObject;if not MatchText(Owner.GetValue<string>('role'),['persistent field','dataset','bound control']) then Continue;
   for F in AView.Document.GetValue<TJSONArray>('syntax.files') do begin
    FileRow:=F as TJSONObject;if FileRow.GetValue<string>('path')<>Owner.GetValue<string>('source') then Continue;
    if not FileRow.TryGetValue<TJSONArray>('ir.nodes',Nodes) then Continue;Parent:=-1;
    for J:=0 to Nodes.Count-1 do begin P:=Nodes.Items[J];if MatchText(P.GetValue<string>('kind'),['object','inherited','inline']) and (P.GetValue<Integer>('start')=Owner.GetValue<Integer>('range.start')) then begin Parent:=J;Break;end;end;
    if Parent<0 then Continue;
    for P in Nodes do begin
     PropertyNode:=P as TJSONObject;if PropertyNode.GetValue<Integer>('parent')<>Parent then Continue;
     Name:=PropertyNode.GetValue<string>('name');
     if (PropertyNode.GetValue<string>('kind')='property') and (Owner.GetValue<string>('role')='persistent field') and MatchText(Name,['Required','ReadOnly','Size','Precision','MinValue','MaxValue','DefaultExpression','CustomConstraint','ConstraintErrorMessage','EditMask']) then begin
      ReferenceRow:=TJSONObject.Create.AddPair('source',Owner.GetValue<string>('source')).AddPair('start',PropertyNode.GetValue('start').Clone as TJSONValue).AddPair('end',PropertyNode.GetValue('end').Clone as TJSONValue).AddPair('line',PropertyNode.GetValue('line').Clone as TJSONValue).AddPair('column',PropertyNode.GetValue('column').Clone as TJSONValue);
      try Rule:=NewRule('declared field constraint',Name,Owner.GetValue<string>('source'),Owner.GetValue<string>('source_hash'),ReferenceRow,Owner);finally ReferenceRow.Free;end;
      if Rule=nil then Continue;Text:=PropertyNode.GetValue<string>('value');
      if MatchText(Name,['CustomConstraint','DefaultExpression']) and (Length(Text)>=2) and (Text[1]='''') and (Text[Length(Text)]='''') then Text:=Copy(Text,2,Length(Text)-2).Replace('''''','''');
      Text:=Safe(Text);SetText(Rule,'constraint',Name+' = '+Text);SetText(Rule,'output',Owner.GetValue<string>('path'));SetText(Rule,'condition',PropertyNode.GetValue<string>('condition',''));Continue;
     end;
     if (PropertyNode.GetValue<string>('kind')<>'property') or not MatchText(Name,['OnValidate','OnSetText','OnGetText','BeforePost','BeforeInsert','BeforeEdit','OnCalcFields','OnNewRecord','OnChange','OnExit','OnValidating']) then Continue;
     Key:='';for E in Symbols do if (E.GetValue<string>('kind')='event') and (E.GetValue<string>('range.source')=Owner.GetValue<string>('source')) and (E.GetValue<Integer>('range.start')=PropertyNode.GetValue<Integer>('start')) then begin Key:=E.GetValue<string>('key');Break;end;
     Rule:=NewRule('validation or conversion hook',Name,Owner.GetValue<string>('source'),Owner.GetValue<string>('source_hash'),Owner.GetValue<TJSONObject>('range'),Owner);if Rule=nil then Continue;
     Rule.RemovePair('range').Free;Rule.AddPair('range',TJSONObject.Create.AddPair('source',Owner.GetValue<string>('source')).AddPair('start',PropertyNode.GetValue('start').Clone as TJSONValue).AddPair('end',PropertyNode.GetValue('end').Clone as TJSONValue).AddPair('line',PropertyNode.GetValue('line').Clone as TJSONValue).AddPair('column',PropertyNode.GetValue('column').Clone as TJSONValue));
     SetText(Rule,'expression',Name+' = '+Safe(PropertyNode.GetValue<string>('value')));SetText(Rule,'condition',PropertyNode.GetValue<string>('condition',''));HandlerKey:='';
     if Hooks.TryGetValue(Key,List) and (List.Count=1) then HandlerKey:=List[0].GetValue<string>('to','');
     if (HandlerKey='') or not BySymbol.TryGetValue(HandlerKey,Handler) then begin SetText(Rule,'constraint','Handler unresolved or ambiguous; no body invented.');Continue;end;
     LinkSymbol(Rule,HandlerKey,'handler');SetText(Rule,'constraint','Serialized event binding; runtime dispatch and successful validation remain unverified.');
     if not RoutineFlows.TryGetValue(HandlerKey,List) then Continue;BodyNodes:=nil;for N in AView.Document.GetValue<TJSONArray>('syntax.files') do if N.GetValue<string>('path')=Handler.GetValue<string>('range.source') then N.TryGetValue<TJSONArray>('ir.nodes',BodyNodes);if BodyNodes=nil then begin SetText(Rule,'constraint','Handler syntax unavailable; no body rules invented.');Continue;end;
     for Flow in List do begin
      Kind:=Flow.GetValue<string>('kind');ExpressionText:=Flow.GetValue<string>('expression');
      FlowIR:=nil;FlowIndex:=-1;FirstExpr:=nil;SecondExpr:=nil;ExprCount:=0;
      for K:=0 to BodyNodes.Count-1 do if (BodyNodes.Items[K].GetValue<Integer>('start')=Flow.GetValue<Integer>('range.start')) and (BodyNodes.Items[K].GetValue<string>('kind')='statement_'+Kind) then begin FlowIR:=BodyNodes.Items[K] as TJSONObject;FlowIndex:=K;Break;end;
      if FlowIR<>nil then for C in BodyNodes do if (C.GetValue<Integer>('parent')=FlowIndex) and (C.GetValue<string>('kind')='expression') then begin Inc(ExprCount);if ExprCount=1 then FirstExpr:=C as TJSONObject else if ExprCount=2 then SecondExpr:=C as TJSONObject;end;
      EvidenceStart:=Flow.GetValue<Integer>('range.start');EvidenceEnd:=Flow.GetValue<Integer>('range.end');
      if FirstExpr<>nil then begin EvidenceStart:=FirstExpr.GetValue<Integer>('start');EvidenceEnd:=FirstExpr.GetValue<Integer>('end');end;
      if SecondExpr<>nil then EvidenceEnd:=SecondExpr.GetValue<Integer>('end');
      if MatchText(Kind,['entry','normal_exit','exception_exit','exception_dispatch','try','for','with','case_arm','case_default']) then Continue;
      if MatchText(Kind,['if','while','repeat','case']) then Text:='validation condition candidate'
      else if MatchText(Kind,['raise','exit']) then Text:='validation exit or error candidate'
      else if (ExprCount=2) then Text:='transformation assignment candidate' else Continue;
      Key:=Owner.GetValue<string>('id')+'|'+HandlerKey+'|'+Flow.GetValue<TJSONValue>('range.start').Value+'|'+Text;
      if Seen.ContainsKey(Key) then Continue;Seen.Add(Key,True);
      Rule:=NewRule(Text,Name+' / line '+Flow.GetValue<TJSONValue>('range.line').Value,Flow.GetValue<string>('range.source'),Flow.GetValue<string>('source_hash'),Flow.GetValue<TJSONObject>('range'),Owner);if Rule=nil then Continue;
      LinkSymbol(Rule,HandlerKey,'handler');SetText(Rule,'expression',Safe(ExpressionText));SetText(Rule,'condition',PropertyNode.GetValue<string>('condition',''));
      if FlowIR<>nil then SetText(Rule,'condition',FlowIR.GetValue<string>('condition',''));
      if Text='transformation assignment candidate' then begin SetText(Rule,'output',Safe(FirstExpr.GetValue<string>('value')));SetText(Rule,'input',Safe(SecondExpr.GetValue<string>('value')));SetText(Rule,'expression',Safe(FirstExpr.GetValue<string>('value'))+' := '+Safe(SecondExpr.GetValue<string>('value')));end
      else SetText(Rule,'constraint',Safe(ExpressionText));
      for B in Relations do if (B.GetValue<string>('from')=HandlerKey) and MatchText(B.GetValue<string>('kind'),['reads','writes']) and
       (B.GetValue<string>('range.source')=Flow.GetValue<string>('range.source')) and (B.GetValue<Integer>('range.start')>=EvidenceStart) and (B.GetValue<Integer>('range.end')<=EvidenceEnd) then begin
       Key:=B.GetValue<string>('to','');if Key<>'' then LinkSymbol(Rule,Key,IfThen(B.GetValue<string>('kind')='writes','lexical output','lexical input'));
      end;
     end;
    end;
   end;
  end;
  AInventory.AddPair('data_rule_count',TJSONNumber.Create(Count)).AddPair('data_rules_truncated',TJSONBool.Create(Truncated));
 finally Seen.Free;RoutineFlows.Free;Hooks.Free;BySymbol.Free;end;
end;

class procedure TDPHDatabaseConnections.ResolveFields(AInventory:TJSONObject);
var Rows:TJSONArray;V,L,C,D:TJSONValue;Row,Link,Source,Dataset,Target:TJSONObject;
    ByID:TDictionary<string,TJSONObject>;Fields:TObjectDictionary<string,TList<TJSONObject>>;
    Candidates:TList<TJSONObject>;ID,FieldName,Key:string;Count:Integer;Incomplete:Boolean;
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
   for L in Row.GetValue<TJSONArray>('links') do begin Link:=L as TJSONObject;if not MatchText(Link.GetValue<string>('property'),['DataField','FieldName']) then Continue;
    Dataset:=nil;Count:=0;Incomplete:=False;
    for C in Row.GetValue<TJSONArray>('links') do if MatchText(C.GetValue<string>('property'),['DataSource','BindSource']) then begin
     if not C.TryGetValue<string>('target_id',ID) or not ByID.TryGetValue(ID,Source) then Incomplete:=True
     else for D in Source.GetValue<TJSONArray>('links') do if (D.GetValue<string>('property')='DataSet') and not D.TryGetValue<string>('target_id',ID) then Incomplete:=True;
    end;
    for C in Row.GetValue<TJSONArray>('links') do if MatchText(C.GetValue<string>('property'),['DataSource','BindSource']) and C.TryGetValue<string>('target_id',ID) and ByID.TryGetValue(ID,Source) then
     for D in Source.GetValue<TJSONArray>('links') do if (D.GetValue<string>('property')='DataSet') and D.TryGetValue<string>('target_id',ID) and ByID.TryGetValue(ID,Target) then begin Inc(Count);Dataset:=Target;end;
    Candidates:=nil;if (Count=1) and not Incomplete then Fields.TryGetValue(Dataset.GetValue<string>('id')+'|'+LowerCase(Link.GetValue<string>('reference')),Candidates);
    if (Count=1) and (Candidates<>nil) and (Candidates.Count=1) then begin
     Target:=Candidates[0];Link.AddPair('resolution','unique captured persistent field candidate').AddPair('target_id',Target.GetValue<string>('id'));
     Target.GetValue<TJSONArray>('used_by').AddElement(TJSONObject.Create.AddPair('id',Row.GetValue<string>('id')).AddPair('name',Row.GetValue<string>('path')).AddPair('property',Link.GetValue<string>('property')));
    end else if (Candidates<>nil) and (Candidates.Count>1) then Link.AddPair('resolution','ambiguous persistent field declarations')
    else Link.AddPair('resolution','unresolved field or dataset chain; dynamic fields and runtime bindings unobserved');
   end;
  end;
 finally Fields.Free;ByID.Free;end;
end;
class procedure TDPHDatabaseConnections.EvaluateEngines(AInventory:TJSONObject);
const DriverIDs:array[0..13] of string=('ADS','ASA','DB2','FB','IB','IBLite','Infx','MSAcc','MSSQL','MySQL','Ora','PG','SQLite','Mongo');
      Families:array[0..13] of string=('Advantage Database Server','SQL Anywhere','IBM DB2','Firebird','InterBase','InterBase','Informix','Microsoft Access','Microsoft SQL Server','MySQL-compatible','Oracle','PostgreSQL','SQLite','MongoDB');
var Rows:TJSONArray;Value,SettingValue,LinkValue:TJSONValue;Row,Engine,Fact,Target,Selected:TJSONObject;
    Index:TDictionary<string,TJSONObject>;Targets:TDictionary<string,Boolean>;
    Name,Text,Family,Version,State,VersionState,ClassName,ID:string;
    I,Pass:Integer;Unrecognized,InvalidVersion,UnresolvedLink:Boolean;
begin
 Rows:=AInventory.GetValue<TJSONArray>('rows');Index:=TDictionary<string,TJSONObject>.Create;Targets:=TDictionary<string,Boolean>.Create;
 try
  for Value in Rows do begin
   Row:=Value as TJSONObject;Index.Add(Row.GetValue<string>('id'),Row);
   Engine:=TJSONObject.Create;Row.AddPair('engine',Engine);Engine.AddPair('evidence',TJSONArray.Create);
   Family:='unknown';Version:='unknown';State:='unknown';VersionState:='unknown';Unrecognized:=False;InvalidVersion:=False;
   ClassName:=Row.GetValue<string>('class');ClassName:=Copy(ClassName,LastDelimiter('.',ClassName)+1,MaxInt);
   for SettingValue in Row.GetValue<TJSONArray>('configuration') do begin
    Name:=SettingValue.GetValue<string>('name');Text:=SettingValue.GetValue<string>('value');
    if (Row.GetValue<string>('role')='connection') and (SameText(Name,'DriverID') or MatchText(Name,['ServerVersion','DatabaseVersion','ClientVersion','DriverVersion'])) then begin
     Fact:=SettingValue.Clone as TJSONObject;
     Fact.AddPair('source',Row.GetValue<string>('source')).AddPair('source_hash',Row.GetValue<string>('source_hash')).AddPair('generation_id',Row.GetValue('generation_id').Clone as TJSONValue);
     Engine.GetValue<TJSONArray>('evidence').AddElement(Fact);
     if SameText(Name,'DriverID') then begin
      // Only the FireDAC connection contract gives DriverID this meaning.
      I:=-1;if SameText(ClassName,'TFDConnection') then I:=IndexText(Text,DriverIDs);
      if I<0 then Unrecognized:=True
      else if State='unknown' then begin Family:=Families[I];State:='identified';end
      else if Family<>Families[I] then begin Family:='conflicting';State:='conflicting';end;
     end else if MatchText(Name,['ServerVersion','DatabaseVersion']) then begin
      if not TRegEx.IsMatch(Text,'^[0-9]{1,5}(\.[0-9]{1,5}){0,4}$') then InvalidVersion:=True
      else if VersionState='unknown' then begin Version:=Text;VersionState:='declared';end
      else if Version<>Text then begin Version:='conflicting';VersionState:='conflicting';end;
     end;
    end;
   end;
   if Unrecognized and (State='identified') then begin Family:='conflicting';State:='conflicting';end;
   if InvalidVersion and (VersionState='declared') then begin Version:='conflicting';VersionState:='conflicting';end;
   Engine.AddPair('family',Family).AddPair('state',State).AddPair('server_version',Version).AddPair('version_state',VersionState).AddPair('hops',TJSONNumber.Create(0));
   Engine.AddPair('qualification','Engine family is inferred only from a recognized captured FireDAC DriverID. MySQL-compatible does not distinguish MySQL from compatible servers. ODBC, virtual/unknown drivers, generic classes, filenames, ports, SQL dialect and DPH internal SQLite do not establish the selected project engine. Numeric ServerVersion/DatabaseVersion are captured declarations only, not measured server versions. ClientVersion/DriverVersion never become server versions. External definitions, runtime overrides and compatibility remain unknown; no connection is made.');
  end;
  // At most three resolved hops cover ordinary data-source/dataset/connection paths.
  // Conflicting references are never collapsed to whichever target was visited last.
  for Pass:=1 to 3 do for Value in Rows do begin
   Row:=Value as TJSONObject;if not MatchText(Row.GetValue<string>('role'),['dataset','data source','transaction','database candidate','database operation','transaction operation']) then Continue;
   Targets.Clear;Selected:=nil;UnresolvedLink:=False;
   for LinkValue in Row.GetValue<TJSONArray>('links') do
    if MatchText(LinkValue.GetValue<string>('property'),['Connection','SQLConnection','ADOConnection','Database','DefaultDatabase','DataSet','Transaction']) then begin
     if LinkValue.TryGetValue<string>('target_id',ID) and Index.TryGetValue(ID,Target) then begin
      if MatchText(Target.GetValue<string>('role'),['connection','dataset']) then begin Targets.AddOrSetValue(ID,True);Selected:=Target;end;
     end else UnresolvedLink:=True;
    end;
   if (Targets.Count=1) and not UnresolvedLink and (Selected.GetValue<Integer>('engine.hops')<3) then begin
    Engine:=Selected.GetValue<TJSONObject>('engine').Clone as TJSONObject;
    Engine.RemovePair('via').Free;Engine.AddPair('via',Selected.GetValue<string>('path')+' | '+Selected.GetValue<string>('id'));
    Engine.RemovePair('hops').Free;Engine.AddPair('hops',TJSONNumber.Create(Selected.GetValue<Integer>('engine.hops')+1));
    Row.RemovePair('engine').Free;Row.AddPair('engine',Engine);
   end else if Targets.Count>1 then begin
    Engine:=Row.GetValue<TJSONObject>('engine');Engine.RemovePair('family').Free;Engine.AddPair('family','conflicting');Engine.RemovePair('state').Free;Engine.AddPair('state','conflicting');
    Engine.RemovePair('server_version').Free;Engine.AddPair('server_version','unknown');Engine.RemovePair('version_state').Free;Engine.AddPair('version_state','unknown');
   end;
  end;
 finally Targets.Free;Index.Free;end;
end;
class function TDPHDatabaseConnections.Describe(ARow:TJSONObject):string;
var Value:TJSONValue;Engine:TJSONObject;BindingText:string;
begin
  Engine:=ARow.GetValue<TJSONObject>('engine');
  Result:='DATABASE ENGINE AND VERSION EVIDENCE'+sLineBreak+'Engine: '+Engine.GetValue<string>('family')+' | '+Engine.GetValue<string>('state')+sLineBreak+'Server version declaration: '+Engine.GetValue<string>('server_version')+' | '+Engine.GetValue<string>('version_state')+sLineBreak+sLineBreak+
    UpperCase(ARow.GetValue<string>('role'))+' '+ARow.GetValue<string>('path')+' : '+ARow.GetValue<string>('class')+sLineBreak+
    'Generation '+ARow.GetValue('generation_id').Value+' | '+ARow.GetValue<string>('availability')+' | '+ARow.GetValue<string>('declaration')+sLineBreak+
    'Source '+ARow.GetValue<string>('source')+':'+ARow.GetValue<TJSONObject>('range').GetValue('line').Value+' | SHA256 '+ARow.GetValue<string>('source_hash')+sLineBreak;
  if Engine.GetValue<string>('via','')<>'' then Result:=Result+'Via resolved captured reference: '+Engine.GetValue<string>('via')+sLineBreak;
  for Value in Engine.GetValue<TJSONArray>('evidence') do Result:=Result+Value.GetValue<string>('name')+' = '+Value.GetValue<string>('value')+' | '+Value.GetValue<string>('source')+':'+Value.GetValue<TJSONValue>('line').Value+' | SHA256 '+Value.GetValue<string>('source_hash')+sLineBreak;
  Result:=Result+Engine.GetValue<string>('qualification')+sLineBreak+sLineBreak+'SAFE CONFIGURATION'+sLineBreak;
  for Value in ARow.GetValue<TJSONArray>('configuration') do Result:=Result+Value.GetValue<string>('name')+' = '+Value.GetValue<string>('value')+' | line '+Value.GetValue<TJSONValue>('line').Value+sLineBreak;
  Result:=Result+sLineBreak+'CAPTURED REFERENCES'+sLineBreak;
  for Value in ARow.GetValue<TJSONArray>('links') do Result:=Result+Value.GetValue<string>('property')+' -> '+Value.GetValue<string>('reference')+' | '+Value.GetValue<string>('resolution')+sLineBreak;
  Result:=Result+sLineBreak+'USED BY'+sLineBreak;
  for Value in ARow.GetValue<TJSONArray>('used_by') do Result:=Result+Value.GetValue<string>('name')+' via '+Value.GetValue<string>('property')+sLineBreak;
  if MatchText(ARow.GetValue<string>('role'),['bound control','persistent field','dataset','data source']) then begin
    BindingText:='DATASET AND SCREEN BINDINGS'+sLineBreak+UpperCase(ARow.GetValue<string>('role'))+' '+ARow.GetValue<string>('path')+sLineBreak;
    for Value in ARow.GetValue<TJSONArray>('links') do BindingText:=BindingText+Value.GetValue<string>('property')+' -> '+Value.GetValue<string>('reference')+' | '+Value.GetValue<string>('resolution')+sLineBreak;
    for Value in ARow.GetValue<TJSONArray>('configuration') do if MatchText(Value.GetValue<string>('name'),['FieldName','FieldKind','Required','ReadOnly','Size','Precision']) then BindingText:=BindingText+Value.GetValue<string>('name')+' = '+Value.GetValue<string>('value')+sLineBreak;
    Result:=BindingText+'Follow reference opens the exact captured target. Field names identify serialized persistent fields, not verified live columns. Missing/runtime/inherited bindings remain unknown.'+sLineBreak+sLineBreak+Result;
  end;
  if MatchText(ARow.GetValue<string>('role'),['database operation','transaction operation']) then Result:='DATABASE OPERATION: '+UpperCase(ARow.GetValue<string>('operation_kind'))+sLineBreak+ARow.GetValue<string>('path')+sLineBreak+ARow.GetValue<string>('effect')+sLineBreak+ARow.GetValue<string>('basis')+sLineBreak+'Conditional context: '+ARow.GetValue<string>('condition')+sLineBreak+'Follow reference opens the captured receiver. Source opens the hash-checked source location.'+sLineBreak+sLineBreak+Result;
  if ARow.GetValue<string>('role')='transaction operation' then begin
    BindingText:='TRANSACTION PATHS (SOURCE POSSIBILITIES)'+sLineBreak;
    for Value in ARow.GetValue<TJSONArray>('transaction_paths') do
      BindingText:=BindingText+Value.GetValue<string>('path_kind')+' -> '+Value.GetValue<string>('target')+sLineBreak+'  CFG edges: '+Value.GetValue<string>('edge_kinds')+sLineBreak;
    if ARow.GetValue<TJSONArray>('transaction_paths').Count=0 then BindingText:=BindingText+'No ordered route available. Review source; absence is not proof of safe commit/rollback handling.'+sLineBreak;
    BindingText:=BindingText+'CFG states examined: '+ARow.GetValue('flow_states_examined').Value+'; truncated: '+ARow.GetValue('flow_truncated').Value+'; ambiguous statement: '+ARow.GetValue('flow_ambiguous').Value+sLineBreak+ARow.GetValue<string>('flow_qualification')+sLineBreak+sLineBreak;
    Result:=BindingText+Result;
  end;
  if ARow.GetValue<string>('role')='data rule' then Result:='DATA VALIDATION AND TRANSFORMATION EVIDENCE'+sLineBreak+ARow.GetValue<string>('rule_kind')+sLineBreak+'Input expression: '+ARow.GetValue<string>('input')+sLineBreak+'Output expression: '+ARow.GetValue<string>('output')+sLineBreak+'Constraint: '+ARow.GetValue<string>('constraint')+sLineBreak+'Captured expression: '+ARow.GetValue<string>('expression')+sLineBreak+'Conditional compilation: '+ARow.GetValue<string>('condition')+sLineBreak+'Candidate evidence only. Follow reference opens context, handler or lexical declaration; Source opens the hash-checked location.'+sLineBreak+sLineBreak+Result;
  Result:=Result+sLineBreak+'UNKNOWNS AND NEXT INVESTIGATION'+sLineBreak+ARow.GetValue<string>('unknowns')+sLineBreak+
    'Ask the maintainer which named definition and environment are intended; inspect approved configuration locally. Do not enter credentials into authored explanations. Serialized Connected=True is a declaration, not evidence of a successful connection. This inventory never opens a target database.';
end;
end.
