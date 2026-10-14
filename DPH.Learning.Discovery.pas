unit DPH.Learning.Discovery;

interface

uses System.JSON;

type
  TDPHLearningDiscovery = class
  public
    class procedure AddEvidence(AFacts, AWorkspace: TJSONObject);
  end;

implementation

uses Winapi.Windows, System.SysUtils, System.Classes, System.IOUtils, System.StrUtils, System.Math,
  System.Hash, System.NetEncoding, System.RegularExpressions, System.Zip,
  System.Net.HttpClient, System.Net.URLClient;

class procedure TDPHLearningDiscovery.AddEvidence(AFacts, AWorkspace: TJSONObject);
var
  Guides,Screens,Sections,Nodes,Files,Assets,Sites,StartupForms: TJSONArray;
  FileRow,Node,Child,Screen,Guide,Section,Site,StartupForm,UnitFile: TJSONObject;
  Root,Path,RelativePath,Ext,Body,Line,Heading,Value,Title,URL,Host: string;
  Converter,TempDir,OutputPath,CommandLine,ProfileURL,OutputFormat: string;
  Paths,PreferredPaths,SeenDocumentHashes: TStringList;
  Lines: TStringList;
  V: TJSONValue;
  I,K,DocumentCount,LogCount,EncodingOffset: Integer;
  FileHash: string;
  TotalBytes: Int64;
  Data: TBytes;
  Zip: TZipFile;
  Stream: TStream;
  Header: TZipHeader;
  FileStream: TFileStream;
  Matches: TMatchCollection;
  Match: TMatch;
  ProgramText,UnitText,FormClass,FormVariable,UnitPath,FormSource: string;
  ProgramMatch,UnitMatch: TMatch;
  ProgramBytes: TBytes;
  ByteIndex,SourceLine: Integer;
  PageMatches,Paragraphs: TMatchCollection;
  PageMatch,Paragraph: TMatch;
  PageNumber: Integer;
  HTTP: THTTPClient;
  Response: IHTTPResponse;
  URI: TURI;
  DetectedEncoding: TEncoding;
  ScanID: TGUID;
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  WaitResult: Cardinal;
  function SafeFolder(const AFolder: string): Boolean;
  var Attr: Cardinal;
  begin
    Attr:=GetFileAttributes(PChar(AFolder));
    Result:=(Attr<>INVALID_FILE_ATTRIBUTES) and ((Attr and FILE_ATTRIBUTE_REPARSE_POINT)=0);
  end;
  procedure Visit(const AFolder: string; ADepth: Integer);
  var Entry,Base,LowerName: string; FileEntries,FolderEntries: TArray<string>; Preferred: Boolean;
  begin
    if (ADepth>4) or (Assets.Count>=2000) or not SafeFolder(AFolder) then Exit;
    try FileEntries:=TDirectory.GetFiles(AFolder); FolderEntries:=TDirectory.GetDirectories(AFolder);
    except on E: Exception do Exit; end;
    for Entry in FileEntries do begin
      if Assets.Count>=2000 then Break;
      Ext:=LowerCase(TPath.GetExtension(Entry));
      LowerName:=LowerCase(TPath.GetFileName(Entry));
      if ContainsText(LowerName,'secret') or ContainsText(LowerName,'credential') or
        ContainsText(LowerName,'.env') or ContainsText(LowerName,'private') then Continue;
      if (GetFileAttributes(PChar(Entry)) and FILE_ATTRIBUTE_REPARSE_POINT)<>0 then Continue;
      if MatchText(Ext,['.pas','.dpr','.dproj','.groupproj','.fmx','.dfm',
        '.md','.markdown','.rst','.adoc','.asciidoc','.txt','.text','.nfo','.log',
        '.html','.htm','.docx','.docm','.doc','.dot','.dotx','.odt','.ott','.sxw',
        '.fodt','.pdf','.rtf','.wpd','.wpt','.wps','.wri','.tex','.csv','.json','.xml',
        '.ini','.config','.yml','.yaml','.sql','.contract','.schema',
        '.png','.jpg','.jpeg','.svg','.bmp','.rc','.res']) then begin
        Assets.AddElement(TJSONObject.Create.AddPair('source',
          Entry.Substring(Length(IncludeTrailingPathDelimiter(Root))).Replace('\','/'))
          .AddPair('format',Ext));
      end;
      if not MatchText(Ext,['.md','.markdown','.rst','.adoc','.asciidoc','.txt','.text',
        '.nfo','.log','.html','.htm','.docx','.docm','.doc','.dot','.dotx',
        '.odt','.ott','.sxw','.fodt','.pdf','.rtf','.wpd','.wpt','.wps','.wri','.tex']) or
        (Paths.Count+PreferredPaths.Count>=300) then Continue;
      Preferred:=(ContainsText(LowerName,'readme') or ContainsText(LowerName,'guide') or
        ContainsText(LowerName,'manual') or ContainsText(LowerName,'help') or
        ContainsText(LowerName,'notes') or ContainsText(LowerName,'getting start') or
        ContainsText(LowerName,'about') or ContainsText(LowerName,'overview') or
        ContainsText(LowerName,'instruction') or ContainsText(LowerName,'spec') or
        ContainsText(LowerName,'faq') or ContainsText(LowerName,'release') or
        ContainsText(LowerName,'requirement') or ContainsText(LowerName,'workflow') or
        ContainsText(LowerName,'architecture') or ContainsText(LowerName,'design') or
        ContainsText(LowerName,'contract') or ContainsText(LowerName,'training') or
        ContainsText(AFolder,'docs') or ContainsText(AFolder,'help') or
        (Ext='.log'));
      if ((Ext='.log') and (TFile.GetSize(Entry)<=16777216)) or
        (MatchText(Ext,['.pdf','.docx','.docm','.doc','.dot','.dotx','.odt',
          '.ott','.sxw','.fodt','.rtf','.wpd','.wpt','.wps','.wri']) and
          (TFile.GetSize(Entry)<=16777216)) or
        ((Ext<>'.log') and (TFile.GetSize(Entry)<=1048576)) then begin
        if Preferred then PreferredPaths.Add(Entry) else Paths.Add(Entry);
      end;
    end;
    for Entry in FolderEntries do begin
      Base:=LowerCase(TPath.GetFileName(Entry));
      if MatchText(Base,['.git','bin','dcu','database','databases','samples',
        'export','tests','tools','source distributions',
        'node_modules','vendor','dependencies']) then Continue;
      Visit(Entry,ADepth+1);
    end;
  end;
  function CleanText(const AText: string): string;
  begin
    Result:=TRegEx.Replace(AText,'(?is)<(script|style)\b[^>]*>.*?</\1>',' ');
    Result:=TRegEx.Replace(Result,'(?is)<w:instrText\b[^>]*>.*?</w:instrText>',' ');
    Result:=TRegEx.Replace(Result,'(?i)<br\s*/?>',sLineBreak);
    Result:=TRegEx.Replace(Result,'(?i)</(p|h[1-6]|li|div|w:p|text:p|text:h)>',sLineBreak+sLineBreak);
    Result:=TRegEx.Replace(Result,'<[^>]+>',' ');
    Result:=TNetEncoding.HTML.Decode(Result);
    Result:=TRegEx.Replace(Result,'[ \t]+',' ');
    Result:=TRegEx.Replace(Result,'(\r?\n){3,}',sLineBreak+sLineBreak);
  end;
begin
  Guides:=TJSONArray.Create; Screens:=TJSONArray.Create; Assets:=TJSONArray.Create; Sites:=TJSONArray.Create;
  StartupForms:=TJSONArray.Create;
  AFacts.AddPair('project_guides',Guides); AFacts.AddPair('project_screens',Screens);
  AFacts.AddPair('project_assets',Assets); AFacts.AddPair('project_sites',Sites);
  AFacts.AddPair('project_startup_forms',StartupForms);
  Root:=AWorkspace.GetValue<string>('root','');
  Files:=AWorkspace.GetValue<TJSONArray>('syntax.files',nil);
  if Files<>nil then for V in Files do begin
    FileRow:=V as TJSONObject; Path:=FileRow.GetValue<string>('path','');
    if not MatchText(LowerCase(TPath.GetExtension(Path)),['.fmx','.dfm']) or
      not FileRow.TryGetValue<TJSONArray>('ir.nodes',Nodes) then Continue;
    for I:=0 to Nodes.Count-1 do begin
      Node:=Nodes.Items[I] as TJSONObject;
      if (Node.GetValue<Integer>('parent',-2)<>-1) or
        not MatchText(Node.GetValue<string>('kind',''),['object','inherited','inline']) then Continue;
      Title:='';
      for K:=0 to Nodes.Count-1 do begin
        Child:=Nodes.Items[K] as TJSONObject;
        if (Child.GetValue<Integer>('parent',-2)=I) and
          MatchText(Child.GetValue<string>('name',''),['Caption','Text']) then begin
          Title:=Child.GetValue<string>('value','').Trim(['''',' ']); Break;
        end;
      end;
      Screen:=TJSONObject.Create;
      Screen.AddPair('source',Path); Screen.AddPair('source_hash',FileRow.GetValue<string>('sha256',''));
      Screen.AddPair('name',Node.GetValue<string>('name',''));
      Screen.AddPair('class',Node.GetValue<string>('value',''));
      Screen.AddPair('title',Title);
      Screen.AddPair('line',TJSONNumber.Create(Node.GetValue<Integer>('line',0)));
      Screens.AddElement(Screen);
    end;
  end;
  if (Root='') or not TDirectory.Exists(Root) then Exit;
  // Delphi syntax is ASCII even when a legacy-encoded comment prevents the
  // full parser from decoding a program file. Read that syntax without
  // interpreting non-ASCII bytes, and keep the result tied to captured files.
  if Files<>nil then for V in Files do begin
    FileRow:=V as TJSONObject; Path:=FileRow.GetValue<string>('path','');
    if not SameText(TPath.GetExtension(Path),'.dpr') or
      StartsText('external/',Path) or (StartupForms.Count>0) then Continue;
    RelativePath:=TPath.GetFullPath(TPath.Combine(Root,Path.Replace('/',PathDelim)));
    if not StartsText(IncludeTrailingPathDelimiter(TPath.GetFullPath(Root)),RelativePath) or
      not TFile.Exists(RelativePath) then Continue;
    try
      if TFile.GetSize(RelativePath)>1048576 then Continue;
      ProgramBytes:=TFile.ReadAllBytes(RelativePath);
      if (Length(ProgramBytes)>=2) and (ProgramBytes[0]=$FF) and (ProgramBytes[1]=$FE) then
        ProgramText:=TEncoding.Unicode.GetString(ProgramBytes,2,Length(ProgramBytes)-2)
      else if (Length(ProgramBytes)>=2) and (ProgramBytes[0]=$FE) and (ProgramBytes[1]=$FF) then
        ProgramText:=TEncoding.BigEndianUnicode.GetString(ProgramBytes,2,Length(ProgramBytes)-2)
      else begin
        SetLength(ProgramText,Length(ProgramBytes));
        for ByteIndex:=0 to High(ProgramBytes) do
          if ProgramBytes[ByteIndex]<128 then ProgramText[ByteIndex+1]:=Char(ProgramBytes[ByteIndex])
          else ProgramText[ByteIndex+1]:=' ';
      end;
      for ProgramMatch in TRegEx.Matches(ProgramText,
        '(?i)\bApplication\s*\.\s*CreateForm\s*\(\s*(T[A-Za-z_][A-Za-z_0-9]*)\s*,\s*([A-Za-z_][A-Za-z_0-9]*)\s*\)') do begin
        FormClass:=ProgramMatch.Groups[1].Value;
        FormVariable:=ProgramMatch.Groups[2].Value;
        UnitPath:=''; FormSource:='';
        UnitMatch:=TRegEx.Match(ProgramText,
          '(?i)\b[A-Za-z_][A-Za-z_0-9.]*\s+in\s+''([^'']+\.pas)''\s*\{\s*'+
          TRegEx.Escape(FormVariable)+'\s*\}');
        if UnitMatch.Success then UnitPath:=UnitMatch.Groups[1].Value.Replace('\','/');
        if UnitPath<>'' then begin
          UnitFile:=nil;
          for K:=0 to Files.Count-1 do
            if SameText((Files.Items[K] as TJSONObject).GetValue<string>('path',''),UnitPath) then begin
              UnitFile:=Files.Items[K] as TJSONObject; Break;
            end;
          if UnitFile<>nil then begin
            RelativePath:=TPath.GetFullPath(TPath.Combine(Root,UnitPath.Replace('/',PathDelim)));
            if StartsText(IncludeTrailingPathDelimiter(TPath.GetFullPath(Root)),RelativePath) and
              TFile.Exists(RelativePath) and (TFile.GetSize(RelativePath)<=4194304) then begin
              ProgramBytes:=TFile.ReadAllBytes(RelativePath);
              SetLength(UnitText,Length(ProgramBytes));
              for ByteIndex:=0 to High(ProgramBytes) do
                if ProgramBytes[ByteIndex]<128 then UnitText[ByteIndex+1]:=Char(ProgramBytes[ByteIndex])
                else UnitText[ByteIndex+1]:=' ';
              if not TRegEx.IsMatch(UnitText,'(?i)\b'+TRegEx.Escape(FormClass)+
                '\s*=\s*class\s*\(\s*T[A-Za-z_][A-Za-z_0-9]*') then UnitPath:='';
            end else UnitPath:='';
          end else UnitPath:='';
        end;
        for K:=0 to Screens.Count-1 do begin
          Screen:=Screens.Items[K] as TJSONObject;
          if SameText(Screen.GetValue<string>('class',''),FormClass) and
            ((UnitPath='') or SameText(TPath.ChangeExtension(Screen.GetValue<string>('source',''),'.pas'),UnitPath)) then begin
            FormSource:=Screen.GetValue<string>('source',''); Break;
          end;
        end;
        SourceLine:=1;
        for ByteIndex:=1 to ProgramMatch.Index do
          if ProgramText[ByteIndex]=#10 then Inc(SourceLine);
        StartupForm:=TJSONObject.Create.AddPair('class',FormClass)
          .AddPair('instance',FormVariable).AddPair('program',Path)
          .AddPair('line',TJSONNumber.Create(SourceLine))
          .AddPair('unit',UnitPath).AddPair('screen',FormSource);
        StartupForms.AddElement(StartupForm);
        if StartupForms.Count>=20 then Break;
      end;
    except on E: Exception do Continue; end;
  end;
  Paths:=TStringList.Create; PreferredPaths:=TStringList.Create;
  SeenDocumentHashes:=TStringList.Create; Lines:=TStringList.Create;
  try
    Visit(Root,0); Paths.Sort; PreferredPaths.Sort;
    for I:=PreferredPaths.Count-1 downto 0 do Paths.Insert(0,PreferredPaths[I]);
    TotalBytes:=0; DocumentCount:=0; LogCount:=0;
    for Path in Paths do begin
      Ext:=LowerCase(TPath.GetExtension(Path));
      if (Ext='.pdf') and TFile.Exists(TPath.ChangeExtension(Path,'.docx')) then Continue;
      if (Ext='.log') and (LogCount>=8) then Continue;
      if (Ext<>'.log') and (DocumentCount>=24) then Continue;
      if Ext='.log' then begin
        if TotalBytes+Min(TFile.GetSize(Path),7500)>4194304 then Continue;
      end else if MatchText(Ext,['.pdf','.docx','.docm','.doc','.dot','.dotx',
        '.odt','.ott','.sxw','.fodt','.rtf','.wpd','.wpt','.wps','.wri']) then begin
        if TotalBytes+65536>4194304 then Continue;
      end else if TotalBytes+TFile.GetSize(Path)>4194304 then Continue;
      try
        FileStream:=TFileStream.Create(Path,fmOpenRead or fmShareDenyNone);
        try FileHash:=THashSHA2.GetHashString(FileStream);
        finally FileStream.Free; end;
      except on E: Exception do Continue; end;
      if SeenDocumentHashes.IndexOf(FileHash)>=0 then Continue;
      SeenDocumentHashes.Add(FileHash);
      RelativePath:=Path.Substring(Length(IncludeTrailingPathDelimiter(Root))).Replace('\','/');
      Body:=''; Data:=nil;
      try
        if Ext='.log' then begin
          FileStream:=TFileStream.Create(Path,fmOpenRead or fmShareDenyNone);
          try
            SetLength(Data,Min(FileStream.Size,7500));
            FileStream.Position:=FileStream.Size-Length(Data);
            if Length(Data)>0 then FileStream.ReadBuffer(Data[0],Length(Data));
          finally FileStream.Free;end;
        end else if not MatchText(Ext,['.pdf','.docx','.docm','.doc','.dot',
          '.dotx','.odt','.ott','.sxw','.fodt','.rtf','.wpd','.wpt','.wps','.wri']) then
          Data:=TFile.ReadAllBytes(Path);
        if MatchText(Ext,['.docx','.docm','.dotx','.odt','.ott','.sxw']) then begin
          Zip:=TZipFile.Create;
          try
            Zip.Open(Path,zmRead);
            Stream:=nil;
            if MatchText(Ext,['.docx','.docm','.dotx']) then
              Zip.Read('word/document.xml',Stream,Header)
            else Zip.Read('content.xml',Stream,Header);
            try
              if (Stream<>nil) and (Stream.Size<=4194304) then begin
                SetLength(Data,Stream.Size); Stream.Position:=0;
                if Length(Data)>0 then Stream.ReadBuffer(Data[0],Length(Data));
                Body:=CleanText(TEncoding.UTF8.GetString(Data));
              end;
            finally Stream.Free; end;
          finally Zip.Free; end;
        end else if MatchText(Ext,['.pdf','.doc','.dot','.rtf','.wpd','.wpt',
          '.wps','.wri','.fodt']) then begin
          Converter:='C:\Program Files\LibreOffice\program\soffice.com';
          if TFile.Exists(Converter) then begin
            CreateGUID(ScanID);
            TempDir:=TPath.Combine(TPath.GetTempPath,'DPH-document-scan-'+GUIDToString(ScanID));
            TDirectory.CreateDirectory(TempDir);
            try
              ProfileURL:='file:///'+TempDir.Replace('\','/').Replace(' ','%20')+'/profile';
              if Ext='.pdf' then begin OutputFormat:='fodg'; OutputPath:=TPath.Combine(TempDir,TPath.GetFileNameWithoutExtension(Path)+'.fodg'); end
              else begin OutputFormat:='txt:Text'; OutputPath:=TPath.Combine(TempDir,TPath.GetFileNameWithoutExtension(Path)+'.txt'); end;
              CommandLine:='"'+Converter+'" "-env:UserInstallation='+ProfileURL+'" --headless --convert-to "'+
                OutputFormat+'" --outdir "'+TempDir+'" "'+Path+'"';
              UniqueString(CommandLine);
              FillChar(StartupInfo,SizeOf(StartupInfo),0);
              StartupInfo.cb:=SizeOf(StartupInfo);
              StartupInfo.dwFlags:=STARTF_USESHOWWINDOW;
              StartupInfo.wShowWindow:=SW_HIDE;
              if CreateProcess(nil,PChar(CommandLine),nil,nil,False,CREATE_NO_WINDOW,nil,nil,
                StartupInfo,ProcessInfo) then begin
                try
                  WaitResult:=WaitForSingleObject(ProcessInfo.hProcess,45000);
                  if WaitResult=WAIT_TIMEOUT then TerminateProcess(ProcessInfo.hProcess,1);
                finally
                  CloseHandle(ProcessInfo.hThread); CloseHandle(ProcessInfo.hProcess);
                end;
              end;
              if TFile.Exists(OutputPath) and (TFile.GetSize(OutputPath)<=33554432) then begin
                Value:=TFile.ReadAllText(OutputPath,TEncoding.UTF8);
                if Ext='.pdf' then begin
                  PageMatches:=TRegEx.Matches(Value,'(?is)<draw:page\b[^>]*>(.*?)</draw:page>');
                  PageNumber:=0;
                  for PageMatch in PageMatches do begin
                    Inc(PageNumber); Body:=Body+'# Page '+IntToStr(PageNumber)+sLineBreak;
                    Paragraphs:=TRegEx.Matches(PageMatch.Groups[1].Value,
                      '(?is)<text:p\b[^>]*>(.*?)</text:p>');
                    for Paragraph in Paragraphs do
                      Body:=Body+CleanText(Paragraph.Groups[1].Value).Trim+sLineBreak;
                    if (PageNumber>=60) or (Length(Body)>=300000) then Break;
                  end;
                end else Body:=Value;
              end;
            finally
              try TDirectory.Delete(TempDir,True); except on E: Exception do ; end;
            end;
          end;
        end else begin
          DetectedEncoding:=nil;
          EncodingOffset:=TEncoding.GetBufferEncoding(Data,DetectedEncoding,TEncoding.UTF8);
          Body:=DetectedEncoding.GetString(Data,EncodingOffset,Length(Data)-EncodingOffset);
          if (EncodingOffset=0) and ContainsText(Body,#$FFFD) then
            Body:=TEncoding.Default.GetString(Data);
          if MatchText(Ext,['.html','.htm']) then Body:=CleanText(Body);
        end;
      except on E: Exception do Continue; end;
      Inc(TotalBytes,Length(Body));
      if Ext='.log' then Inc(LogCount) else Inc(DocumentCount);
      Guide:=TJSONObject.Create; Guides.AddElement(Guide);
      Guide.AddPair('source',RelativePath);
      Guide.AddPair('sha256',FileHash);
      Guide.AddPair('format',Ext);
      Sections:=TJSONArray.Create; Guide.AddPair('sections',Sections);
      if (Length(Trim(Body))<18) or
        (Length(TRegEx.Replace(Body,'[A-Za-z]',''))>Length(Body)*0.85) or
        TRegEx.IsMatch(Body,'[\x00-\x08\x0E-\x1F]') then Continue;
      if Ext='.log' then begin
        Lines.Text:=Body; Body:='';
        for I:=0 to Lines.Count-1 do begin
          Line:=Trim(Lines[I]);
          if (Length(Line)<18) or (Length(Line)>260) or
            not (ContainsText(Line,'error') or ContainsText(Line,'warning') or
              ContainsText(Line,'failed') or ContainsText(Line,'complete') or
              ContainsText(Line,'success')) then Continue;
          if Body<>'' then Body:=Body+sLineBreak;
          Body:=Body+'- '+Line;
          if Length(Body)>2200 then Break;
        end;
        if Body='' then Continue;
      end;
      if (Ext<>'.log') and (Sites.Count<3) then begin
        Matches:=TRegEx.Matches(Body,'https://[A-Za-z0-9][A-Za-z0-9.-]+(?:/[A-Za-z0-9_./?=&%#-]*)?');
        for Match in Matches do begin
          URL:=Match.Value.TrimRight(['.',',',';',')']);
          URI:=TURI.Create(URL); Host:=LowerCase(URI.Host);
          if (Host='localhost') or Host.EndsWith('.local') or Host.EndsWith('.internal') or
            MatchText(Host,['example.com','www.example.com','example.org','www.example.org',
              'example.net','www.example.net']) or
            TRegEx.IsMatch(Host,'^[0-9.]+$') or (Pos('.',Host)=0) then Continue;
          Site:=TJSONObject.Create.AddPair('url',URL).AddPair('source',RelativePath).AddPair('text','');
          Sites.AddElement(Site);
          if Sites.Count>=3 then Break;
        end;
      end;
      Lines.Text:=Body; Heading:=TPath.GetFileNameWithoutExtension(Path); Value:='';
      for I:=0 to Lines.Count-1 do begin
        Line:=Trim(Lines[I]);
        if Line='' then begin
          if (Value<>'') and not Value.EndsWith(sLineBreak+sLineBreak) then Value:=Value+sLineBreak;
          Continue;
        end;
        if (Line.StartsWith('# ') or Line.StartsWith('## ') or Line.StartsWith('### ')) then begin
          if Value<>'' then begin
            Section:=TJSONObject.Create.AddPair('heading',Heading).AddPair('text',Copy(Value,1,8000));
            Sections.AddElement(Section);
          end;
          Heading:=Trim(Line.TrimLeft(['#',' '])); Value:='';
        end else if Length(Value)<8000 then begin
          if Value<>'' then Value:=Value+sLineBreak;
          Value:=Value+Line;
        end;
        if Sections.Count>=40 then Break;
      end;
      if Value<>'' then Sections.AddElement(TJSONObject.Create.AddPair('heading',Heading).AddPair('text',Copy(Value,1,8000)));
    end;
    HTTP:=THTTPClient.Create;
    try
      HTTP.ConnectionTimeout:=1000; HTTP.ResponseTimeout:=2000;
      HTTP.HandleRedirects:=False;
      for V in Sites do begin
        Site:=V as TJSONObject; URL:=Site.GetValue<string>('url');
        try
          Response:=HTTP.Get(URL);
          if (Response.StatusCode>=200) and (Response.StatusCode<300) and
            (Response.ContentLength>0) and (Response.ContentLength<=131072) and
            ContainsText(Response.MimeType,'text/html') then begin
            Body:=CleanText(Response.ContentAsString(TEncoding.UTF8));
            if Length(Body)>6000 then Body:=Copy(Body,1,6000);
            Site.RemovePair('text').Free; Site.AddPair('text',Body);
          end;
        except on E: Exception do Continue; end;
      end;
    finally HTTP.Free; end;
  finally Lines.Free; SeenDocumentHashes.Free; PreferredPaths.Free; Paths.Free; end;
end;

end.
