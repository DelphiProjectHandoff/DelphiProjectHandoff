unit DPH.Learning.Discovery;

interface

uses System.JSON;

type
  TDPHLearningDiscovery = class
  public
    class procedure AddEvidence(AFacts, AWorkspace: TJSONObject);
  end;

implementation

uses Winapi.Windows, System.SysUtils, System.Classes, System.IOUtils, System.StrUtils,
  System.Hash, System.NetEncoding, System.RegularExpressions, System.Zip;

class procedure TDPHLearningDiscovery.AddEvidence(AFacts, AWorkspace: TJSONObject);
var
  Guides,Screens,Sections,Nodes,Files: TJSONArray;
  FileRow,Node,Child,Screen,Guide,Section: TJSONObject;
  Root,Path,RelativePath,Ext,Body,Line,Heading,Value,Title: string;
  Paths: TStringList;
  Lines: TStringList;
  V: TJSONValue;
  I,K: Integer;
  TotalBytes: Int64;
  Data: TBytes;
  Zip: TZipFile;
  Stream: TStream;
  Header: TZipHeader;
  FileStream: TFileStream;
  function SafeFolder(const AFolder: string): Boolean;
  var Attr: Cardinal;
  begin
    Attr:=GetFileAttributes(PChar(AFolder));
    Result:=(Attr<>INVALID_FILE_ATTRIBUTES) and ((Attr and FILE_ATTRIBUTE_REPARSE_POINT)=0);
  end;
  procedure Visit(const AFolder: string; ADepth: Integer);
  var Entry,Base,LowerName: string;
  begin
    if (ADepth>4) or (Paths.Count>=300) or not SafeFolder(AFolder) then Exit;
    for Entry in TDirectory.GetFiles(AFolder) do begin
      if Paths.Count>=300 then Break;
      Ext:=LowerCase(TPath.GetExtension(Entry));
      if not MatchText(Ext,['.md','.txt','.html','.htm','.docx','.pdf']) then Continue;
      LowerName:=LowerCase(TPath.GetFileName(Entry));
      if ContainsText(LowerName,'secret') or ContainsText(LowerName,'credential') or
        ContainsText(LowerName,'.env') or ContainsText(LowerName,'private') then Continue;
      if not (ContainsText(LowerName,'readme') or ContainsText(LowerName,'guide') or
        ContainsText(LowerName,'manual') or ContainsText(LowerName,'help') or
        ContainsText(LowerName,'notes') or ContainsText(LowerName,'getting start') or
        ContainsText(AFolder,'docs') or ContainsText(AFolder,'help')) then Continue;
      if (GetFileAttributes(PChar(Entry)) and FILE_ATTRIBUTE_REPARSE_POINT)<>0 then Continue;
      if TFile.GetSize(Entry)<=1048576 then Paths.Add(Entry);
    end;
    for Entry in TDirectory.GetDirectories(AFolder) do begin
      Base:=LowerCase(TPath.GetFileName(Entry));
      if MatchText(Base,['.git','bin','dcu','database','databases','samples',
        'export','logs','log','tests','tools','source distributions',
        'images and icons','node_modules','vendor']) then Continue;
      Visit(Entry,ADepth+1);
    end;
  end;
  function CleanText(const AText: string): string;
  begin
    Result:=TRegEx.Replace(AText,'(?is)<(script|style)\b[^>]*>.*?</\1>',' ');
    Result:=TRegEx.Replace(Result,'(?i)</(p|h[1-6]|li|div|w:p)>',sLineBreak);
    Result:=TRegEx.Replace(Result,'<[^>]+>',' ');
    Result:=TNetEncoding.HTML.Decode(Result);
    Result:=TRegEx.Replace(Result,'[ \t]+',' ');
  end;
begin
  Guides:=TJSONArray.Create; Screens:=TJSONArray.Create;
  AFacts.AddPair('project_guides',Guides); AFacts.AddPair('project_screens',Screens);
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
  Paths:=TStringList.Create; Lines:=TStringList.Create;
  try
    Visit(Root,0); Paths.Sort; TotalBytes:=0;
    for Path in Paths do begin
      if Guides.Count>=24 then Break;
      if TotalBytes+TFile.GetSize(Path)>2097152 then Break;
      RelativePath:=Path.Substring(Length(IncludeTrailingPathDelimiter(Root))).Replace('\','/');
      Ext:=LowerCase(TPath.GetExtension(Path)); Body:='';
      try
        Data:=TFile.ReadAllBytes(Path);
        if Ext='.docx' then begin
          Zip:=TZipFile.Create;
          try
            Zip.Open(Path,zmRead);
            Stream:=nil;
            Zip.Read('word/document.xml',Stream,Header);
            try
              if (Stream<>nil) and (Stream.Size<=2097152) then begin
                SetLength(Data,Stream.Size); Stream.Position:=0;
                if Length(Data)>0 then Stream.ReadBuffer(Data[0],Length(Data));
                Body:=CleanText(TEncoding.UTF8.GetString(Data));
              end;
            finally Stream.Free; end;
          finally Zip.Free; end;
        end else if Ext<>'.pdf' then begin
          Body:=TEncoding.UTF8.GetString(Data);
          if MatchText(Ext,['.html','.htm']) then Body:=CleanText(Body);
        end;
      except on E: Exception do Continue; end;
      Inc(TotalBytes,TFile.GetSize(Path));
      Guide:=TJSONObject.Create; Guides.AddElement(Guide);
      Guide.AddPair('source',RelativePath);
      FileStream:=TFileStream.Create(Path,fmOpenRead or fmShareDenyNone);
      try Guide.AddPair('sha256',THashSHA2.GetHashString(FileStream));
      finally FileStream.Free; end;
      Guide.AddPair('format',Ext);
      Sections:=TJSONArray.Create; Guide.AddPair('sections',Sections);
      if Ext='.pdf' then Continue;
      Lines.Text:=Body; Heading:=TPath.GetFileNameWithoutExtension(Path); Value:='';
      for I:=0 to Lines.Count-1 do begin
        Line:=Trim(Lines[I]);
        if Line='' then Continue;
        if (Line.StartsWith('# ') or Line.StartsWith('## ') or Line.StartsWith('### ')) then begin
          if Value<>'' then begin
            Section:=TJSONObject.Create.AddPair('heading',Heading).AddPair('text',Copy(Value,1,8000));
            Sections.AddElement(Section);
          end;
          Heading:=Trim(Line.TrimLeft(['#',' '])); Value:='';
        end else if Length(Value)<8000 then Value:=Value+Line+sLineBreak;
        if Sections.Count>=40 then Break;
      end;
      if Value<>'' then Sections.AddElement(TJSONObject.Create.AddPair('heading',Heading).AddPair('text',Copy(Value,1,8000)));
    end;
  finally Lines.Free; Paths.Free; end;
end;

end.
