unit DPH.Publish.Translation;
interface
uses System.SysUtils, System.Classes, System.JSON, System.Generics.Collections;
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
  TDPHAtlasAdapter = class(TInterfacedObject,IDPHTranslationProvider)
    function ID: string;
    function Version: string;
    function External: Boolean;
    function TranslateProse(const AText,ASourceLocale,ATargetLocale: string): string;
  end;
  TDPHTranslationCache = class
  private
    FEntries: TObjectDictionary<string,TJSONObject>;
  public
    constructor Create;
    destructor Destroy; override;
    function Translate(ARevision: Int64; const ASourceLocale,ATargetLocale: string;
      const ASegments: TArray<TDPHTranslationSegment>; AProvider: IDPHTranslationProvider;
      AExternalConsent: Boolean = False): TJSONObject;
    procedure Review(const AKey,AReviewer: string);
  end;
implementation
uses System.Hash;
function TDPHAtlasAdapter.ID: string;
begin Result:='Atlas-unconfigured'; end;
function TDPHAtlasAdapter.Version: string;
begin Result:='0'; end;
function TDPHAtlasAdapter.External: Boolean;
begin Result:=True; end;
function TDPHAtlasAdapter.TranslateProse(const AText,ASourceLocale,ATargetLocale: string): string;
begin raise EInvalidOperation.Create('Atlas provider/API, transport, licensing and confidentiality must be selected and reviewed before connection'); end;
constructor TDPHTranslationCache.Create;
begin inherited; FEntries:=TObjectDictionary<string,TJSONObject>.Create([doOwnsValues]); end;
destructor TDPHTranslationCache.Destroy;
begin FEntries.Free; inherited; end;
function TDPHTranslationCache.Translate(ARevision: Int64; const ASourceLocale,ATargetLocale: string;
  const ASegments: TArray<TDPHTranslationSegment>; AProvider: IDPHTranslationProvider;
  AExternalConsent: Boolean): TJSONObject;
var Seg: TDPHTranslationSegment; Source,Rows: TJSONArray; Row,Cached: TJSONObject; Key,Text: string;
begin
  if AProvider=nil then raise EArgumentException.Create('Translation provider is required');
  if AProvider.External and not AExternalConsent then raise EInvalidOperation.Create('External translation is disabled without explicit consent');
  if (ASourceLocale.Trim='') or (ATargetLocale.Trim='') or (ARevision<1) then raise EArgumentException.Create('Revision and locale are required');
  Source:=TJSONArray.Create;
  try
    for Seg in ASegments do begin Row:=TJSONObject.Create; Row.AddPair('text',Seg.Text); Row.AddPair('protected',TJSONBool.Create(Seg.IsProtected)); Source.AddElement(Row); end;
    Key:=THashSHA2.GetHashString(IntToStr(ARevision)+#0+ASourceLocale+#0+ATargetLocale+#0+AProvider.ID+#0+AProvider.Version+#0+Source.ToJSON);
  finally Source.Free; end;
  if FEntries.TryGetValue(Key,Cached) then Exit(Cached.Clone as TJSONObject);
  Cached:=TJSONObject.Create;
  try
    Cached.AddPair('cache_key',Key); Cached.AddPair('revision',TJSONNumber.Create(ARevision)); Cached.AddPair('locale',ATargetLocale);
    Cached.AddPair('provider',AProvider.ID); Cached.AddPair('provider_version',AProvider.Version); Cached.AddPair('state','needs_review'); Cached.AddPair('reviewer','');
    Rows:=TJSONArray.Create; Cached.AddPair('segments',Rows);
    for Seg in ASegments do begin Text:=Seg.Text;
      if not Seg.IsProtected and (ASourceLocale<>ATargetLocale) and (Text<>'') then Text:=AProvider.TranslateProse(Text,ASourceLocale,ATargetLocale);
      Row:=TJSONObject.Create; Row.AddPair('text',Text); Row.AddPair('protected',TJSONBool.Create(Seg.IsProtected)); Rows.AddElement(Row);
    end;
    FEntries.Add(Key,Cached); Result:=Cached.Clone as TJSONObject;
  except Cached.Free; raise; end;
end;
procedure TDPHTranslationCache.Review(const AKey,AReviewer: string);
var Entry: TJSONObject;
begin
  if AReviewer.Trim='' then raise EArgumentException.Create('Translation review requires attribution');
  if not FEntries.TryGetValue(AKey,Entry) then raise EArgumentException.Create('Translation cache entry not found');
  Entry.RemovePair('state').Free; Entry.AddPair('state','verified'); Entry.RemovePair('reviewer').Free; Entry.AddPair('reviewer',AReviewer);
end;
end.
