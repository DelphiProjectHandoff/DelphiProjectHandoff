unit DPH.Publish.Translation;
interface
uses System.SysUtils, System.Classes, System.JSON, System.Generics.Collections, DAT.Runtime.LanguagePack, DPH.Storage.Database;
type
  TDPHTranslationSegment = record
    Text: string;
    IsProtected: Boolean;
  end;
  IDPHTranslationProvider = interface
    ['{06755487-ED8A-47F9-A0D7-1344EAC53913}']
    function ID: string;
    function Version: string;
    function External: Boolean;
    function TranslateProse(const AText,ASourceLocale,ATargetLocale: string): string;
  end;
  IDPHTranslationLocale = interface
    ['{6B9F6C0B-D7C5-437E-B8C1-BC5E188A6D87}']
    function ResolvedTargetLocale: string;
  end;
  TDPHAtlasAdapter = class(TInterfacedObject,IDPHTranslationProvider,IDPHTranslationLocale)
  private
    FPack: TRuntimeLanguagePack;
    FHash: string;
  public
    constructor Create(const APackFile: string = '');
    destructor Destroy; override;
    function ID: string;
    function Version: string;
    function External: Boolean;
    function TranslateProse(const AText,ASourceLocale,ATargetLocale: string): string;
    function ResolvedTargetLocale: string;
  end;
  TDPHTranslationCache = class
  private
    FEntries: TObjectDictionary<string,TJSONObject>;
    FStore: TDPHKnowledgeStore;
  public
    constructor Create(AStore: TDPHKnowledgeStore = nil);
    destructor Destroy; override;
    class function SegmentsForText(const AText: string): TArray<TDPHTranslationSegment>; static;
    function Translate(ARevision: Int64; const ASourceLocale,ATargetLocale: string;
      const ASegments: TArray<TDPHTranslationSegment>; AProvider: IDPHTranslationProvider;
      AExternalConsent: Boolean = False; const ATerminologyJSON: string = '{}'): TJSONObject;
    procedure Review(const AKey,AReviewer: string);
  end;
implementation
uses System.Hash, System.IOUtils, System.RegularExpressions;
constructor TDPHAtlasAdapter.Create(const APackFile: string);
var Bytes,Decoded: TBytes; Hash: THashSHA2; Text: string;
begin
  inherited Create;
  if APackFile='' then Exit;
  if not TFile.Exists(APackFile) or (TFile.GetSize(APackFile)>4*1024*1024) then
    raise EArgumentException.Create('Select a local DAT language pack no larger than 4 MiB');
  Bytes:=TFile.ReadAllBytes(APackFile); Hash:=THashSHA2.Create; Hash.Update(Bytes); FHash:=Hash.HashAsString;
  Text:=TEncoding.UTF8.GetString(Bytes); Decoded:=TEncoding.UTF8.GetBytes(Text);
  if (Length(Bytes)<>Length(Decoded)) or ((Length(Bytes)>0) and not CompareMem(@Bytes[0],@Decoded[0],Length(Bytes))) then
    raise EReadError.Create('DAT language pack must contain valid UTF-8');
  if Text.StartsWith(#$FEFF) then Delete(Text,1,1);
  FPack:=TRuntimeLanguagePack.LoadFromJson(Text);
  if FPack.ApplicationId<>'DelphiProjectHandoff' then
    raise EArgumentException.Create('Language pack applicationId must be DelphiProjectHandoff');
end;
destructor TDPHAtlasAdapter.Destroy;
begin FPack.Free; inherited; end;
function TDPHAtlasAdapter.ID: string;
begin if FPack=nil then Result:='Atlas-unconfigured' else Result:='Atlas-DAT-offline'; end;
function TDPHAtlasAdapter.Version: string;
begin if FPack=nil then Result:='0' else Result:='DAT-pack-'+FHash; end;
function TDPHAtlasAdapter.External: Boolean;
begin Result:=False; end;
function TDPHAtlasAdapter.ResolvedTargetLocale: string;
begin if FPack=nil then Result:='' else Result:=FPack.LanguageCode; end;
function TDPHAtlasAdapter.TranslateProse(const AText,ASourceLocale,ATargetLocale: string): string;
var Prefix,Suffix: Integer; Translated: string;
begin
  if FPack=nil then raise EInvalidOperation.Create('Select a local Atlas DAT language pack first');
  if not SameText(ASourceLocale,FPack.SourceLanguage) and not SameText(ASourceLocale.Split(['-'])[0],FPack.SourceLanguage) then raise EArgumentException.Create('Source locale does not match the DAT language pack');
  if not SameText(ATargetLocale,FPack.LanguageCode) and not SameText(ATargetLocale.Split(['-'])[0],FPack.LanguageCode) then raise EArgumentException.Create('Target locale does not match the DAT language pack');
  if FPack.TryTranslateSource(AText,Result) then Exit;
  Result:=AText;
  if FPack.TryTranslateSource(AText.Trim,Translated) then begin
    Prefix:=Length(AText)-Length(AText.TrimLeft); Suffix:=Length(AText)-Length(AText.TrimRight);
    Result:=Copy(AText,1,Prefix)+Translated+Copy(AText,Length(AText)-Suffix+1,Suffix);
  end;
end;
constructor TDPHTranslationCache.Create(AStore: TDPHKnowledgeStore);
begin inherited Create; FStore:=AStore; FEntries:=TObjectDictionary<string,TJSONObject>.Create([doOwnsValues]); end;
destructor TDPHTranslationCache.Destroy;
begin FEntries.Free; inherited; end;
class function TDPHTranslationCache.SegmentsForText(const AText: string): TArray<TDPHTranslationSegment>;
var Parts: TList<TDPHTranslationSegment>; Seg: TDPHTranslationSegment; Line: string;
  Matches: TMatchCollection; Match: TMatch; Position,LineStart,LineEnd: Integer; Fenced,Whole: Boolean;
begin
  Parts:=TList<TDPHTranslationSegment>.Create;
  try
    Fenced:=False; LineStart:=1;
    while LineStart<=Length(AText) do begin
      LineEnd:=LineStart; while (LineEnd<=Length(AText)) and not CharInSet(AText[LineEnd],[#10,#13]) do Inc(LineEnd);
      Line:=Copy(AText,LineStart,LineEnd-LineStart);
      Whole:=Fenced or Line.Trim.StartsWith('```') or Line.Trim.StartsWith('~~~') or
        TRegEx.IsMatch(Line,'(?i)^\s*(select|insert|update|delete|create table|alter table|procedure|function|constructor|destructor|begin|end\b|var\b|const\b|uses\b|unit\b|program\b)') or Line.Contains(':=');
      if Line.Trim.StartsWith('```') or Line.Trim.StartsWith('~~~') then Fenced:=not Fenced;
      if Whole then begin Seg.Text:=Line; Seg.IsProtected:=True; Parts.Add(Seg); end
      else begin
        Matches:=TRegEx.Matches(Line,'`[^`]*`|[A-Za-z]:[\\/][^\s,;]*|https?://[^\s]+|(?:[\w.-]+[\\/])+[\w.-]+|"[^"]*"\s*:|\b[0-9a-fA-F]{32,64}\b|\b[A-Za-z_]\w*(?:\.\w+)+\b|\b[A-Za-z_]\w*_\w+\b|\b(?:T[A-Z]|[a-z]+[A-Z])[A-Za-z0-9_]*\b');
        Position:=1;
        for Match in Matches do begin
          if Match.Index>Position then begin Seg.Text:=Copy(Line,Position,Match.Index-Position); Seg.IsProtected:=False; Parts.Add(Seg); end;
          Seg.Text:=Match.Value; Seg.IsProtected:=True; Parts.Add(Seg); Position:=Match.Index+Match.Length;
        end;
        if Position<=Length(Line) then begin Seg.Text:=Copy(Line,Position,MaxInt); Seg.IsProtected:=False; Parts.Add(Seg); end;
      end;
      Position:=LineEnd; while (LineEnd<=Length(AText)) and CharInSet(AText[LineEnd],[#10,#13]) do Inc(LineEnd);
      if LineEnd>Position then begin Seg.Text:=Copy(AText,Position,LineEnd-Position); Seg.IsProtected:=True; Parts.Add(Seg); end;
      LineStart:=LineEnd;
    end;
    Result:=Parts.ToArray;
  finally Parts.Free; end;
end;
function TDPHTranslationCache.Translate(ARevision: Int64; const ASourceLocale,ATargetLocale: string;
  const ASegments: TArray<TDPHTranslationSegment>; AProvider: IDPHTranslationProvider;
  AExternalConsent: Boolean; const ATerminologyJSON: string): TJSONObject;
var Seg: TDPHTranslationSegment; Source,Rows: TJSONArray; Row,Cached,Terms: TJSONObject; Key,Text,SourceHash,Status: string; Missing: Integer; Term,TermsValue: TJSONValue; Pair: TJSONPair; LocaleProvider: IDPHTranslationLocale;
begin
  if AProvider=nil then raise EArgumentException.Create('Translation provider is required');
  if AProvider.External and not AExternalConsent then raise EInvalidOperation.Create('External translation is disabled without explicit consent');
  if (ASourceLocale.Trim='') or (ATargetLocale.Trim='') or (ARevision<1) then raise EArgumentException.Create('Revision and locale are required');
  TermsValue:=TJSONObject.ParseJSONValue(ATerminologyJSON);
  if not (TermsValue is TJSONObject) then begin TermsValue.Free; raise EArgumentException.Create('Terminology must be a JSON object of exact prose translations'); end;
  Terms:=TermsValue as TJSONObject;
  try
  for Pair in Terms do if not (Pair.JsonValue is TJSONString) or (Pair.JsonValue.Value.Trim='') then raise EArgumentException.Create('Terminology values must be nonempty prose strings');
  Source:=TJSONArray.Create;
  try
    for Seg in ASegments do begin Row:=TJSONObject.Create; Row.AddPair('text',Seg.Text); Row.AddPair('protected',TJSONBool.Create(Seg.IsProtected)); Source.AddElement(Row); end;
    SourceHash:=THashSHA2.GetHashString(Source.ToJSON);
    Key:=THashSHA2.GetHashString(IntToStr(ARevision)+#0+ASourceLocale+#0+ATargetLocale+#0+AProvider.ID+#0+AProvider.Version+#0+SourceHash+#0+Terms.ToJSON);
  finally Source.Free; end;
  if FStore<>nil then begin Cached:=FStore.LoadTranslation(Key); if Cached<>nil then begin FEntries.AddOrSetValue(Key,Cached); Exit(Cached.Clone as TJSONObject); end; end;
  if (FStore=nil) and FEntries.TryGetValue(Key,Cached) then Exit(Cached.Clone as TJSONObject);
  Cached:=TJSONObject.Create;
  try
    Cached.AddPair('cache_key',Key); Cached.AddPair('revision',TJSONNumber.Create(ARevision)); Cached.AddPair('locale',ATargetLocale);
    Cached.AddPair('provider',AProvider.ID); Cached.AddPair('provider_version',AProvider.Version); Cached.AddPair('state','needs_review'); Cached.AddPair('reviewer','');
    Cached.AddPair('source_locale',ASourceLocale); Cached.AddPair('source_hash',SourceHash);
    Cached.AddPair('terminology_hash',THashSHA2.GetHashString(Terms.ToJSON));
    if Supports(AProvider,IDPHTranslationLocale,LocaleProvider) then begin
      Cached.AddPair('resolved_locale',LocaleProvider.ResolvedTargetLocale);
      Cached.AddPair('locale_fallback',TJSONBool.Create(not SameText(ATargetLocale,LocaleProvider.ResolvedTargetLocale)));
    end else begin Cached.AddPair('resolved_locale',ATargetLocale); Cached.AddPair('locale_fallback',TJSONBool.Create(False)); end;
    Rows:=TJSONArray.Create; Cached.AddPair('segments',Rows);
    Missing:=0;
    for Seg in ASegments do begin Text:=Seg.Text; Status:='source_locale';
      if Seg.IsProtected then Status:='protected'
      else if not SameText(ASourceLocale,ATargetLocale) and (Text.Trim<>'') then begin
        Term:=Terms.GetValue(Text);
        if Term<>nil then begin
          if not (Term is TJSONString) or (Term.Value='') then raise EArgumentException.Create('Terminology values must be nonempty prose strings');
          Text:=Term.Value; Status:='terminology';
        end else begin Text:=AProvider.TranslateProse(Text,ASourceLocale,ATargetLocale); Status:='translated';
          if Text=Seg.Text then begin Status:='source_fallback'; Inc(Missing); end;
        end;
      end;
      Row:=TJSONObject.Create; Row.AddPair('text',Text); Row.AddPair('source_text',Seg.Text); Row.AddPair('status',Status);
      Row.AddPair('protected',TJSONBool.Create(Seg.IsProtected)); Rows.AddElement(Row);
    end;
    Cached.AddPair('source_fallback_count',TJSONNumber.Create(Missing));
    if FStore<>nil then FStore.SaveTranslation(Cached);
    FEntries.AddOrSetValue(Key,Cached); Result:=Cached.Clone as TJSONObject;
  except Cached.Free; raise; end;
  finally Terms.Free; end;
end;
procedure TDPHTranslationCache.Review(const AKey,AReviewer: string);
var Entry: TJSONObject;
begin
  if AReviewer.Trim='' then raise EArgumentException.Create('Translation review requires attribution');
  if not FEntries.TryGetValue(AKey,Entry) then raise EArgumentException.Create('Translation cache entry not found');
  if Entry.GetValue<Integer>('source_fallback_count',0)>0 then raise EInvalidOperation.Create('Translate missing prose before approving the localized revision');
  if FStore<>nil then FStore.ReviewTranslation(AKey,AReviewer);
  Entry.RemovePair('state').Free; Entry.AddPair('state','verified'); Entry.RemovePair('reviewer').Free; Entry.AddPair('reviewer',AReviewer);
end;
end.
