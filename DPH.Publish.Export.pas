unit DPH.Publish.Export;
interface
uses System.SysUtils, System.JSON, DPH.Publish.Model, DPH.Storage.Database;
type
  TDPHPublisher = class
  public
    class procedure Export(AModel: TDPHDocumentModel; AStore: TDPHKnowledgeStore; const ADirectory: string; AIncludeAgentInstructions: Boolean = False; AIncludeSourceNavigation: Boolean = False; const ALocale: string = ''); static;
    class procedure Validate(const ADirectory,AExpectedFingerprint: string; ARejectStale: Boolean = True); static;
    class procedure WriteGuide(AModel: TDPHDocumentModel; const APath,ATitle: string; AUser: Boolean); static;
  end;
implementation
uses System.IOUtils, System.Classes, System.StrUtils, System.Hash, System.Zip, System.RegularExpressions, System.NetEncoding, System.Generics.Collections, System.Generics.Defaults, Winapi.Windows, DPH.Analysis.Explanations, DPH.Project.Source, DPH.Parse.Model, DPH.Workspace.Graphs;
class procedure TDPHPublisher.WriteGuide(AModel: TDPHDocumentModel; const APath,ATitle: string; AUser: Boolean);
var Archive: TZipFile; Document,Body,Headings,Lesson: string; V,W,L: TJSONValue; R: TJSONObject; I,StartAt,EndAt: Integer; Linked: Boolean; Explanations: TDPHExplanationModel; Paragraph: string;
  procedure Part(const Name,Text: string);
  var Stream: TBytesStream;
  begin Stream:=TBytesStream.Create(TEncoding.UTF8.GetBytes(Text)); try Archive.Add(Stream,Name); finally Stream.Free; end; end;
  function P(const Text,Style: string): string;
  begin Result:='<w:p><w:pPr><w:pStyle w:val="'+Style+'"/></w:pPr><w:r><w:t xml:space="preserve">'+TDPHDocumentModel.HTML(Text)+'</w:t></w:r></w:p>'; end;
begin
  Body:=P(ATitle,'Title')+P('Delphi Project Handoff experimental reference','Normal')+
    P('Last changed '+AModel.Document.GetValue<string>('captured_utc','not recorded')+' | generation '+AModel.Document.GetValue('generation_id').Value,'Normal')+
    P('Static evidence and attributed knowledge for '+AModel.Document.GetValue<string>('project')+'. Review coverage, stale status and unknowns before use.','Normal')+
    '<w:p><w:r><w:br w:type="page"/></w:r></w:p>'+P('Contents','Title')+
    '<w:p><w:r><w:fldChar w:fldCharType="begin"/></w:r><w:r><w:instrText xml:space="preserve"> TOC \o "1-1" \h \z \u </w:instrText></w:r><w:r><w:fldChar w:fldCharType="separate"/></w:r></w:p>';
  Headings:='';
  if AUser then begin
    Body:=P(ATitle,'Title')+P('Learn '+AModel.Document.GetValue<string>('project'),'Normal')+
      P('Last changed '+AModel.Document.GetValue<string>('captured_utc','not recorded'),'Normal')+
      P('Start with the application purpose, follow a screen action and read the supplied task instructions. This guide presents source-derived explanations and named contributions. It does not run the application. Open learning.html in this edition to use the object links and supplied images mentioned in these lessons.','Normal')+
      '<w:p><w:r><w:br w:type="page"/></w:r></w:p>'+P('Contents','Title')+
      '<w:p><w:r><w:fldChar w:fldCharType="begin"/></w:r><w:r><w:instrText xml:space="preserve"> TOC \o "1-1" \h \z \u </w:instrText></w:r><w:r><w:fldChar w:fldCharType="separate"/></w:r></w:p>';
    Explanations:=TDPHExplanationModel.Create(AModel.Document);
    try
      for I:=0 to 11 do begin
        Body:=Body+P(TDPHExplanationModel.TopicTitle(I),'Normal');
        Headings:=Headings+P(TDPHExplanationModel.TopicTitle(I),'Heading1');
        Lesson:=Explanations.LessonHTML(I);StartAt:=Pos('<main>',Lesson);EndAt:=Pos('</main>',Lesson);
        Lesson:=Copy(Lesson,StartAt+6,EndAt-StartAt-6);
        Lesson:=TRegEx.Replace(Lesson,'(?s)<details class="card"><summary>About this lesson</summary>.*?</details>','');
        Lesson:=Lesson.Replace('<p><small>Some explanations need checking. Ask about unexplained behavior before relying on it.</small></p>','');
        Lesson:=TRegEx.Replace(Lesson,'(?is)<h[23]>(.*?)</h[23]>',sLineBreak+'[[HEADING]]$1'+sLineBreak);
        Lesson:=TRegEx.Replace(Lesson,'(?i)</(?:p|h[1-6]|li|section)>|<br\s*/?>',sLineBreak);
        Lesson:=TNetEncoding.HTML.Decode(TRegEx.Replace(Lesson,'<[^>]+>',''));
        Lesson:=Lesson.Replace('Open Learn a task to follow the prepared steps one at a time, with Previous, Next and Start again.','The saved task instructions follow below. The DPH application also provides a reader that presents one step at a time.');
        Lesson:=Lesson.Replace('Open Author questions to record a named reply.','Record replies in DPH through Prepare lessons, Author questions.');
        for Paragraph in Lesson.Split([sLineBreak]) do if Trim(Paragraph)<>'' then begin
          if StartsText('[[HEADING]]',Trim(Paragraph)) then Headings:=Headings+P(Copy(Trim(Paragraph),12,MaxInt),'Heading2')
          else Headings:=Headings+P(Trim(Paragraph),'Normal');
        end;
      end;
    finally Explanations.Free;end;
    Body:=Body+P('Continue learning','Normal')+'<w:p><w:r><w:fldChar w:fldCharType="end"/></w:r></w:p><w:p><w:r><w:br w:type="page"/></w:r></w:p>'+Headings;
    Body:=Body+P('Continue learning','Heading1')+P('Open learning.html in this edition for linked explanations, supplied screenshots and business terms. To add or change instructions, open the project in DPH and choose Prepare lessons.','Normal');
  end else begin
  for V in AModel.Document.GetValue<TJSONArray>('sections') do begin R:=V as TJSONObject;
    if AUser and not MatchText(R.GetValue<string>('id'),['overview','user','troubleshooting','orientation','help']) then Continue;
    Body:=Body+P(R.GetValue<string>('title'),'Normal');
    Headings:=Headings+P(R.GetValue<string>('title'),'Heading1');
    Headings:=Headings+P('Section '+R.GetValue<string>('section_id')+' | version '+R.GetValue<string>('section_version')+
      ' | source generation '+R.GetValue<string>('source_generation')+' | '+R.GetValue<string>('verification_state')+
      ' | last reviewed '+R.GetValue<string>('last_reviewed'),'Normal');
    for W in R.GetValue<TJSONArray>('paragraphs') do for Paragraph in W.Value.Split([sLineBreak]) do if Paragraph<>'' then Headings:=Headings+P(Paragraph,'Normal');
    for W in AModel.Document.GetValue<TJSONArray>('knowledge') do
    begin
      Linked:=False; for L in R.GetValue<TJSONArray>('knowledge_ids') do if L.Value=(W as TJSONObject).GetValue<string>('id') then Linked:=True;
      if Linked then
        Headings:=Headings+P((W as TJSONObject).GetValue<string>('title'),'Heading2')+
          P('Section '+W.GetValue<string>('section_id')+' | revision '+W.GetValue<string>('revision')+
          ' | source generation '+W.GetValue<string>('source_generation')+' | '+W.GetValue<string>('state')+
          ' | author '+W.GetValue<string>('owner')+' | reviewer '+IfThen(W.GetValue<string>('reviewer')='','unassigned',W.GetValue<string>('reviewer'))+
          ' | last reviewed '+IfThen(W.GetValue<string>('reviewed_at')='','never',W.GetValue<string>('reviewed_at')),'Normal')+
          P((W as TJSONObject).GetValue<string>('body'),'Normal');
    end;
  end;
  Body:=Body+P('Evidence reference','Normal')+P('Known unknowns','Normal')+'<w:p><w:r><w:fldChar w:fldCharType="end"/></w:r></w:p><w:p><w:r><w:br w:type="page"/></w:r></w:p>'+Headings;
  Body:=Body+P('Evidence reference','Heading1');
  I:=0; Explanations:=TDPHExplanationModel.Create(AModel.Document);
  try
  for V in AModel.Document.GetValue<TJSONArray>('symbols') do begin R:=V as TJSONObject;
    if AUser and not MatchText(R.GetValue<string>('kind'),['component','event']) then Continue;
    Body:=Body+P(R.GetValue<string>('name'),'Heading2')+P(R.GetValue<string>('kind')+' '+R.GetValue<string>('signature')+' | '+R.GetValue<string>('range.source')+
      ' line '+R.GetValue<Integer>('range.line').ToString+' | SHA256 '+R.GetValue<string>('source_hash'),'Normal');
    if MatchText(R.GetValue<string>('kind'),['routine','anonymous','component','event']) then
      for Paragraph in Explanations.ObjectText(R.GetValue<string>('key')).Split([sLineBreak]) do if Paragraph<>'' then Body:=Body+P(Paragraph,'Normal');
    Inc(I); if AUser and (I>=500) then begin Body:=Body+P('User guide evidence excerpt limited to 500 interface symbols. Complete indexes accompany this guide.','Normal'); Break; end;
  end;
  finally Explanations.Free; end;
  Body:=Body+P('Known unknowns','Heading1')+P(AModel.Document.GetValue<string>('known_unknowns'),'Normal');
  end;
  Document:='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>'+Body+
    '<w:sectPr><w:pgSz w:w="12240" w:h="15840"/><w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440"/></w:sectPr></w:body></w:document>';
  Archive:=TZipFile.Create;
  try
    Archive.Open(APath,zmWrite);
    Part('[Content_Types].xml','<?xml version="1.0"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/><Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/><Override PartName="/word/settings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"/></Types>');
    Part('_rels/.rels','<?xml version="1.0"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>');
    Part('word/_rels/document.xml.rels','<?xml version="1.0"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings" Target="settings.xml"/></Relationships>');
    Part('word/settings.xml','<?xml version="1.0"?><w:settings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:updateFields w:val="true"/></w:settings>');
    Part('word/styles.xml','<?xml version="1.0"?><w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:pPr><w:spacing w:after="160"/></w:pPr><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:sz w:val="23"/><w:color w:val="000000"/></w:rPr></w:style><w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:basedOn w:val="Normal"/><w:rPr><w:sz w:val="48"/></w:rPr></w:style><w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:basedOn w:val="Normal"/><w:pPr><w:keepNext/><w:spacing w:before="240" w:after="120"/><w:outlineLvl w:val="0"/></w:pPr><w:rPr><w:b/><w:sz w:val="30"/></w:rPr></w:style><w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/><w:basedOn w:val="Normal"/><w:pPr><w:keepNext/><w:outlineLvl w:val="1"/></w:pPr><w:rPr><w:b/><w:sz w:val="25"/></w:rPr></w:style></w:styles>');
    Part('word/document.xml',Document);
  finally Archive.Free; end;
end;
class procedure TDPHPublisher.Export(AModel: TDPHDocumentModel; AStore: TDPHKnowledgeStore; const ADirectory: string; AIncludeAgentInstructions,AIncludeSourceNavigation: Boolean; const ALocale: string);
var Directory,IndexText,Path,Relative,Anchor: string; V,W,LinkValue,RevisionValue: TJSONValue; R,J,Manifest,Hashes: TJSONObject; Lines,Page: TStringBuilder; Files: TArray<string>;
    ByFrom: TObjectDictionary<string,TList<TJSONObject>>; Neighbors: TList<TJSONObject>;
    Explanations: TDPHExplanationModel;
    Images: TJSONArray; ImageValue: TJSONValue; ImageRow: TJSONObject; ImagePath: string;
    SourcePages: TObjectDictionary<string,TJSONObject>; Navigation,SourceRecord: TJSONObject; SourceRows: TJSONArray;
    Source: TDPHSource; Diagnostics: TDPHDiagnostics; SourceLines: TArray<string>; SourceLine,ObjectPage,SourcePath: string; LineNumber,RenderedSources,OmittedSources: Integer;
    IncludedLines: TJSONArray; LineStarts: TArray<Integer>; LineMask: TArray<Boolean>; CharacterIndex,LineIndex,RenderedLines: Integer; SourceSymbol: TJSONValue; TaskSource,SkippingLines,LineAvailable: Boolean;
    LocalizedRows,CachedTranslations: TJSONArray; Localization,LocalizedRow: TJSONObject; TranslationValue,SegmentValue: TJSONValue;
    LocalizedBody,LocalizedSource,LocalePage,LessonPage: string; TranslatedCount,FallbackCount,LessonIndex,LessonStart,LessonEnd: Integer; LocalizedModel: TDPHDocumentModel; LocaleCharacter: Char;
  procedure Write(const Name,Text: string);
  var Target: string;
  begin Target:=TPath.Combine(Directory,Name.Replace('/',PathDelim)); TDirectory.CreateDirectory(ExtractFilePath(Target)); TFile.WriteAllBytes(Target,TEncoding.UTF8.GetBytes(Text)); end;
  procedure JSONL(const Name: string; Rows: TJSONArray);
  var Value: TJSONValue;
  begin Lines.Clear; for Value in Rows do Lines.Append(Value.ToJSON).Append(#10); Write(Name,Lines.ToString); end;
begin
  if AModel.LocalDisplay then raise EArgumentException.Create('Local display projection cannot be exported; create a redacted publication model');
  if Length(ALocale)>35 then raise EArgumentException.Create('Publication locale is limited to 35 characters');
  for LocaleCharacter in ALocale do if not CharInSet(LocaleCharacter,['a'..'z','A'..'Z','0'..'9','-']) then raise EArgumentException.Create('Use a language tag such as fr or fr-CA');
  Directory:=TPath.GetFullPath(ADirectory); AStore.CheckOutsideSource(Directory);
  if TDirectory.Exists(Directory) or TFile.Exists(Directory) then raise EArgumentException.Create('Export destination must be new; existing files will not be overwritten');
  TDirectory.CreateDirectory(Directory); Lines:=TStringBuilder.Create; Page:=TStringBuilder.Create;
  ByFrom:=TObjectDictionary<string,TList<TJSONObject>>.Create([doOwnsValues]); Explanations:=TDPHExplanationModel.Create(AModel.Document);
  SourcePages:=TObjectDictionary<string,TJSONObject>.Create([doOwnsValues]); Navigation:=TJSONObject.Create;
  Localization:=TJSONObject.Create;
  try
    LocalizedRows:=TJSONArray.Create; Localization.AddPair('sections',LocalizedRows); TranslatedCount:=0; FallbackCount:=0; LocalePage:='';
    Localization.AddPair('requested_locale',ALocale); Localization.AddPair('scope','authored bodies only; titles, generated guidance and technical indexes remain source language');
    if ALocale<>'' then begin
      for V in AModel.Document.GetValue<TJSONArray>('knowledge') do begin
        R:=V as TJSONObject; LocalizedRow:=TJSONObject.Create; LocalizedRows.AddElement(LocalizedRow);
        for SourcePath in ['id','section_id','revision','source_generation','title'] do LocalizedRow.AddPair(SourcePath,R.GetValue<string>(SourcePath));
        LocalizedRow.AddPair('author',R.GetValue<string>('owner')); LocalizedRow.AddPair('source_body',R.GetValue<string>('body'));
        LocalizedRow.AddPair('body',R.GetValue<string>('body')); LocalizedRow.AddPair('state','source_fallback_needs_translation');
        LocalizedRow.AddPair('actual_locale','source'); LocalizedRow.AddPair('reviewer','unassigned'); LocalizedRow.AddPair('reviewed_at','never');
        if (R.GetValue<string>('state')='verified') and (R.GetValue<string>('pending')='0') and not R.GetValue<string>('body').Contains('[REDACTED') then begin
          CachedTranslations:=AStore.TranslationEntries(R.GetValue<Int64>('revision'));
          try for TranslationValue in CachedTranslations do begin
            if not SameText(TranslationValue.GetValue<string>('locale'),ALocale) or (TranslationValue.GetValue<string>('state')<>'verified') or
              (TranslationValue.GetValue<Integer>('source_fallback_count')<>0) then Continue;
            LocalizedSource:=''; LocalizedBody:='';
            for SegmentValue in TranslationValue.GetValue<TJSONArray>('segments') do begin LocalizedSource:=LocalizedSource+SegmentValue.GetValue<string>('source_text'); LocalizedBody:=LocalizedBody+SegmentValue.GetValue<string>('text'); end;
            if LocalizedSource<>R.GetValue<string>('body') then Continue;
            LocalizedRow.RemovePair('body').Free; LocalizedRow.AddPair('body',TDPHDocumentModel.Redact(LocalizedBody));
            LocalizedRow.RemovePair('state').Free; LocalizedRow.AddPair('state','verified_translation');
            LocalizedRow.RemovePair('actual_locale').Free; LocalizedRow.AddPair('actual_locale',TranslationValue.GetValue<string>('resolved_locale',ALocale));
            LocalizedRow.RemovePair('reviewer').Free; LocalizedRow.AddPair('reviewer',TranslationValue.GetValue<string>('reviewer'));
            LocalizedRow.RemovePair('reviewed_at').Free; LocalizedRow.AddPair('reviewed_at',TranslationValue.GetValue<string>('reviewed_at','unknown'));
            LocalizedRow.AddPair('cache_key',TranslationValue.GetValue<string>('cache_key')); LocalizedRow.AddPair('provider',TranslationValue.GetValue<string>('provider'));
            LocalizedRow.AddPair('provider_version',TranslationValue.GetValue<string>('provider_version')); Break;
          end; finally CachedTranslations.Free; end;
        end;
        if LocalizedRow.GetValue<string>('state')='verified_translation' then Inc(TranslatedCount) else Inc(FallbackCount);
      end;
      LocalePage:='objects/'+THashSHA2.GetHashString('locale'+#0+ALocale+#0+LocalizedRows.ToJSON)+'.html';
      Lines.Clear; Lines.Append('<!doctype html><html lang="').Append(ALocale).Append('"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta http-equiv="Content-Security-Policy" content="default-src ''none''; style-src ''self''; connect-src ''none''; object-src ''none''; base-uri ''none''; form-action ''none''"><link rel="stylesheet" href="../assets/style.css"><title>Localized authored sections</title></head><body><a href="../index.html">Back to source-language handoff</a><h1>Localized authored sections: ')
        .Append(ALocale).Append('</h1><p>').Append(TranslatedCount).Append(' reviewed translations; ').Append(FallbackCount).Append(' source-language fallbacks. Titles, generated guidance and technical indexes remain source language. Translation review approves wording, not underlying facts.</p>');
      for V in LocalizedRows do Lines.Append('<section><h2>').Append(TDPHDocumentModel.HTML(V.GetValue<string>('title'))).Append('</h2><p>Section ')
        .Append(TDPHDocumentModel.HTML(V.GetValue<string>('section_id'))).Append(' revision ').Append(V.GetValue<string>('revision')).Append(' | ')
        .Append(V.GetValue<string>('state')).Append(' | actual locale ').Append(TDPHDocumentModel.HTML(V.GetValue<string>('actual_locale')))
        .Append(' | reviewer ').Append(TDPHDocumentModel.HTML(V.GetValue<string>('reviewer'))).Append('</p><pre>')
        .Append(TDPHDocumentModel.HTML(V.GetValue<string>('body'))).Append('</pre></section>');
      Lines.Append('</body></html>'); Write(LocalePage,Lines.ToString);
      LocalizedModel:=TDPHDocumentModel.CreateLocalizedSections(AModel,ALocale,LocalizedRows);
      try WriteGuide(LocalizedModel,TPath.Combine(Directory,'Localized_Sections.docx'),'Localized authored sections - '+ALocale,False); finally LocalizedModel.Free; end;
    end;
    Localization.AddPair('translated_sections',TJSONNumber.Create(TranslatedCount)); Localization.AddPair('source_fallback_sections',TJSONNumber.Create(FallbackCount));
    Localization.AddPair('html',LocalePage); Write('localization.json',Localization.Format(2));
    SourceRows:=TJSONArray.Create; Navigation.AddPair('files',SourceRows); RenderedSources:=0; OmittedSources:=0;
    Navigation.AddPair('included',TJSONBool.Create(AIncludeSourceNavigation)); Navigation.AddPair('raw_source_snapshots',TJSONBool.Create(False));
    Navigation.AddPair('disclosure','Optional redacted line-preserving browsing views. Original bytes are not included; inspect prose before sharing.');
    if AIncludeSourceNavigation then begin
      if AModel.Document.GetValue<Boolean>('detached') then raise EReadError.Create('Attach verified source before including source navigation');
      for V in AModel.Document.GetValue<TJSONArray>('files') do begin
        R:=V as TJSONObject; Relative:=R.GetValue<string>('path'); SourceRecord:=TJSONObject.Create; SourceRows.AddElement(SourceRecord);
        SourceRecord.AddPair('source',Relative); SourceRecord.AddPair('original_sha256',R.GetValue<string>('sha256')); SourceRecord.AddPair('artifact','');
        if R.GetValue<string>('availability')<>'available' then begin SourceRecord.AddPair('state','omitted_unavailable_at_capture'); Inc(OmittedSources); Continue; end;
        if Relative.Contains('..') or Relative.Contains(':') or StartsText('/',Relative) or StartsText('external/',Relative) then raise EReadError.Create('Source browsing path is outside the captured project');
        SourcePath:=TPath.GetFullPath(TPath.Combine(AStore.SourceRoot,Relative.Replace('/',PathDelim)));
        if not StartsText(IncludeTrailingPathDelimiter(AStore.SourceRoot),SourcePath) or not TFile.Exists(SourcePath) then raise EReadError.Create('Captured source is missing; reassess before exporting source navigation');
        if R.GetValue<Int64>('bytes')>4*1024*1024 then begin SourceRecord.AddPair('state','omitted_above_4_MiB_browsing_limit'); Inc(OmittedSources); Continue; end;
        if not MatchText(ExtractFileExt(Relative),['.pas','.dpr','.dproj','.groupproj','.inc','.dfm','.fmx','.rc','.json','.xml','.ini','.txt','.cfg']) then begin
          SourceRecord.AddPair('state','omitted_nontext_extension'); Inc(OmittedSources); Continue;
        end;
        Diagnostics:=TDPHDiagnostics.Create;
        try Source:=TDPHSource.Create(SourcePath,Relative,Diagnostics,AModel.Document.GetValue<Integer>('analysis_configuration.code_page'));
          try
            if Source.SHA256<>R.GetValue<string>('sha256') then raise EReadError.Create('Source changed since capture: '+Relative+'; reassess before exporting source navigation');
            if not Source.Decoded or ContainsText(Source.Text,'PRIVATE KEY-----') then begin SourceRecord.AddPair('state','omitted_binary_undecodable_or_private_key'); Inc(OmittedSources); Continue; end;
            SourceLines:=Source.Text.Replace(#13#10,#10).Replace(#13,#10).Split([#10]);
            if Length(SourceLines)>20000 then begin SourceRecord.AddPair('state','omitted_above_20000_line_browsing_limit'); Inc(OmittedSources); Continue; end;
            TaskSource:=AModel.Document.GetValue<string>('scope')='task';
            SetLength(LineStarts,Length(SourceLines)); SetLength(LineMask,Length(SourceLines));
            for LineIndex:=0 to High(LineMask) do LineMask[LineIndex]:=not TaskSource;
            if TaskSource then begin
              LineIndex:=0; LineStarts[0]:=Source.ByteOffsets[0];
              for CharacterIndex:=1 to Length(Source.Text) do if (Source.Text[CharacterIndex]=#10) or
                ((Source.Text[CharacterIndex]=#13) and ((CharacterIndex=Length(Source.Text)) or (Source.Text[CharacterIndex+1]<>#10))) then begin
                  Inc(LineIndex); if LineIndex<Length(LineStarts) then LineStarts[LineIndex]:=Source.ByteOffsets[CharacterIndex];
                end;
              for SourceSymbol in AModel.Document.GetValue<TJSONArray>('symbols') do
                if (SourceSymbol.GetValue<string>('range.source')=Relative) and not MatchText(SourceSymbol.GetValue<string>('kind'),['unit','type','form']) then begin
                  LineIndex:=SourceSymbol.GetValue<Integer>('range.line')-1;
                  while (LineIndex>=0) and (LineIndex<Length(LineMask)) and (LineStarts[LineIndex]<SourceSymbol.GetValue<Integer>('range.end')) do begin
                    LineMask[LineIndex]:=True; Inc(LineIndex);
                  end;
                end;
            end;
            RenderedLines:=0; for LineIndex:=0 to High(LineMask) do if LineMask[LineIndex] then Inc(RenderedLines);
            if RenderedLines=0 then begin SourceRecord.AddPair('state','omitted_no_cited_noncontainer_ranges'); Inc(OmittedSources); Continue; end;
            IncludedLines:=TJSONArray.Create; SourceRecord.AddPair('included_line_numbers',IncludedLines);
            Path:='objects/'+THashSHA2.GetHashString('source'+#0+Relative+#0+Source.SHA256+#0+DPHPublishVersion+#0+AModel.Document.GetValue<string>('scope')+#0+AModel.Document.GetValue<TJSONArray>('task_seeds').ToJSON)+'.html';
            Lines.Clear; Lines.Append('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta http-equiv="Content-Security-Policy" content="default-src ''none''; style-src ''self''; connect-src ''none''; object-src ''none''; base-uri ''none''; form-action ''none''"><link rel="stylesheet" href="../assets/style.css"><title>Captured source browsing view</title></head><body><a href="../index.html">Back to handoff</a><h1 class="notranslate" translate="no">')
              .Append(TDPHDocumentModel.HTML(Relative)).Append('</h1><p>Redacted browsing text; original source bytes are not included. Original SHA256: <code>')
              .Append(Source.SHA256).Append('</code>. Line anchors refer to the captured file. Task scope includes only cited non-container line excerpts; omitted lines are marked. Shared lines may contain surrounding code. Redaction does not guarantee removal of every sensitive value; review before sharing.</p><pre class="notranslate" translate="no">');
            LineNumber:=0; SkippingLines:=False;
            for SourceLine in SourceLines do begin Inc(LineNumber);
              if not LineMask[LineNumber-1] then begin
                if not SkippingLines then Lines.Append('... uncited lines omitted ...').Append(#10);
                SkippingLines:=True; Continue;
              end;
              SkippingLines:=False; IncludedLines.Add(LineNumber);
              Lines.Append('<span id="L').Append(LineNumber).Append('"><a href="#L').Append(LineNumber).Append('">')
                .Append(LineNumber).Append('</a> ').Append(TDPHDocumentModel.HTML(TDPHDocumentModel.Redact(SourceLine))).Append('</span>').Append(#10);
            end;
            Lines.Append('</pre></body></html>'); Write(Path,Lines.ToString);
            SourceRecord.RemovePair('artifact').Free; SourceRecord.AddPair('artifact',Path); SourceRecord.AddPair('state','redacted_captured_text');
            SourceRecord.AddPair('line_count',TJSONNumber.Create(LineNumber)); SourceRecord.AddPair('rendered_line_count',TJSONNumber.Create(RenderedLines));
            SourceRecord.AddPair('task_excerpts',TJSONBool.Create(TaskSource)); SourceRecord.AddPair('generation_id',AModel.Document.GetValue('generation_id').Clone as TJSONValue);
            SourcePages.Add(Relative,SourceRecord.Clone as TJSONObject); Inc(RenderedSources);
          finally Source.Free; end;
        finally Diagnostics.Free; end;
      end;
    end;
    Navigation.AddPair('rendered_files',TJSONNumber.Create(RenderedSources)); Navigation.AddPair('omitted_files',TJSONNumber.Create(OmittedSources));
    Write('source-navigation.json',Navigation.Format(2));
    for V in AModel.Document.GetValue<TJSONArray>('relationships') do begin J:=V as TJSONObject;
      if not ByFrom.TryGetValue(J.GetValue<string>('from'),Neighbors) then begin Neighbors:=TList<TJSONObject>.Create; ByFrom.Add(J.GetValue<string>('from'),Neighbors); end; Neighbors.Add(J);
    end;
    Images:=AStore.ScreenshotsJSON;
    try
      for V in AModel.Document.GetValue<TJSONArray>('screenshots') do begin R:=V as TJSONObject; ImagePath:='';
        for ImageValue in Images do begin ImageRow:=ImageValue as TJSONObject;
          if (ImageRow.GetValue<string>('image_sha256')=R.GetValue<string>('image_sha256')) and
             (ImageRow.GetValue<Int64>('generation_id')=R.GetValue<Int64>('generation_id')) then ImagePath:=ImageRow.GetValue<string>('managed_path');
        end;
        if ImagePath='' then raise EReadError.Create('Published screenshot has no validated managed artifact');
        TDirectory.CreateDirectory(TPath.Combine(Directory,'images'));
        if not TFile.Exists(TPath.Combine(Directory,'images\'+R.GetValue<string>('image'))) then
          TFile.Copy(ImagePath,TPath.Combine(Directory,'images\'+R.GetValue<string>('image')));
      end;
    finally Images.Free; end;
    Write('canonical.json',AModel.Document.Format(2));
    Write('assets/search.js','"use strict";document.getElementById("search").addEventListener("input",function(){const q=this.value.toLowerCase();document.querySelectorAll("article[data-search]").forEach(function(e){e.hidden=!e.dataset.search.includes(q);});});');
    Write('assets/translation-selector.js','"use strict";document.querySelectorAll("select[data-language-list]").forEach(function(s){Array.from(s.options).sort((a,b)=>a.text.localeCompare(b.text)).forEach(o=>s.add(o));});');
    Write('assets/style.css','body{font:17px/1.5 system-ui,sans-serif;color:#16293a;max-width:1100px;margin:auto;padding:24px}h1,h2{color:#146cb4}a{color:#146cb4}header{border-top:5px solid #f28c28}nav a{margin-right:18px}article{padding:12px 0;border-bottom:1px solid #ddd}pre,code{overflow-wrap:anywhere;white-space:pre-wrap}figure{margin:20px 0}figure img{max-width:100%;height:auto}.status{font-weight:bold}input{padding:10px;width:90%}@media print{nav,input{display:none}body{font:11pt/1.3 serif;max-width:none;padding:0}h2{break-after:avoid}}@media(max-width:600px){body{padding:12px}}');
    Lines.Clear;
    Lines.Append('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta http-equiv="Content-Security-Policy" content="default-src ''none''; style-src ''self''; img-src ''self'' data:; script-src ''none''; connect-src ''none''; object-src ''none''; base-uri ''none''; form-action ''none''"><link rel="stylesheet" href="assets/style.css"><title>Learn '+TDPHDocumentModel.HTML(AModel.Document.GetValue<string>('project'))+'</title></head><body><header><h1>Learn '+TDPHDocumentModel.HTML(AModel.Document.GetValue<string>('project'))+'</h1><p>Start with the application purpose. Follow a screen action, read its explanation, then try a supplied task.</p></header><nav aria-label="Learning topics">');
    for LessonIndex:=0 to 11 do Lines.Append('<a href="#lesson_'+IntToStr(LessonIndex)+'">'+TDPHExplanationModel.TopicTitle(LessonIndex)+'</a> ');
    Lines.Append('<a href="#screenshots">Supplied screenshots</a> <a href="#glossary">Business terms</a></nav><p>This is a saved, read-only learning edition. To add an explanation or answer a question, open the project in DPH and choose Prepare lessons. Source was read without running the application.</p>');
    for LessonIndex:=0 to 11 do begin
      LessonPage:=Explanations.LessonHTML(LessonIndex);LessonStart:=Pos('<main>',LessonPage);LessonEnd:=Pos('</main>',LessonPage);
      if (LessonStart=0) or (LessonEnd<=LessonStart) then raise EReadError.Create('Learning topic has no content');
      LessonPage:=Copy(LessonPage,LessonStart+6,LessonEnd-LessonStart-6);
      LessonPage:=TRegEx.Replace(LessonPage,'href="#s_([a-fA-F0-9]{64})"','href="objects/$1.html"');
      LessonPage:=LessonPage.Replace('href="#task_reader"','href="#lesson_11"').Replace('href="#ask_author"','href="#lesson_9"');
      if LessonIndex=11 then LessonPage:=LessonPage.Replace('Open Learn a task</a> to follow the prepared steps one at a time, with Previous, Next and Start again.','Read the task instructions below</a>. In DPH, Learn a task also lets you follow them one step at a time.');
      if LessonIndex=9 then LessonPage:=LessonPage.Replace('Open Author questions</a> to record a named reply.','Read the questions below</a>. Record replies in DPH through Prepare lessons, Author questions.');
      Lines.Append('<section id="lesson_'+IntToStr(LessonIndex)+'"><h2>'+TDPHExplanationModel.TopicTitle(LessonIndex)+'</h2>'+LessonPage+'</section>');
    end;
    Lines.Append('<section id="screenshots"><h2>Supplied screenshots</h2><p>These images were supplied by named contributors. They are separate from reconstructed form designs.</p>');
    for V in AModel.Document.GetValue<TJSONArray>('screenshots') do begin R:=V as TJSONObject;
      Lines.Append('<figure><img src="images/'+R.GetValue<string>('image')+'" alt="'+TDPHDocumentModel.HTML(R.GetValue<string>('caption'))+'"><figcaption>'+TDPHDocumentModel.HTML(R.GetValue<string>('caption'))+' &mdash; supplied by '+TDPHDocumentModel.HTML(R.GetValue<string>('author'))+'; user supplied, unverified.</figcaption></figure>');
    end;
    if AModel.Document.GetValue<TJSONArray>('screenshots').Count=0 then Lines.Append('<p>No screenshots have been supplied for this edition.</p>');
    Lines.Append('</section><section id="glossary"><h2>Business terms</h2>');LessonIndex:=0;
    for V in AModel.Document.GetValue<TJSONArray>('knowledge') do if (V.GetValue<string>('kind')='glossary') and not MatchText(V.GetValue<string>('state'),['retired','rejected']) then begin Inc(LessonIndex);
      Lines.Append('<h3>'+TDPHDocumentModel.HTML(V.GetValue<string>('title'))+'</h3><p>'+TDPHDocumentModel.HTML(V.GetValue<string>('body'))+'</p><p>Supplied by '+TDPHDocumentModel.HTML(V.GetValue<string>('owner'))+'; '+TDPHDocumentModel.HTML(V.GetValue<string>('state').Replace('_',' '))+'.</p>');
    end;
    if LessonIndex=0 then Lines.Append('<p>No business terms have been supplied for this edition.</p>');
    Lines.Append('</section><p><a href="#lesson_0">Return to Start here</a> &middot; <a href="index.html">Optional technical reference</a></p></body></html>');
    Write('learning.html',Lines.ToString);
    Page.Append('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta http-equiv="Content-Security-Policy" content="default-src ''none''; script-src ''self''; style-src ''self''; img-src ''self'' data:; connect-src ''none''; object-src ''none''; base-uri ''none''; form-action ''none''"><title>Delphi Project Handoff reference</title><link rel="stylesheet" href="assets/style.css"></head><body><header><h1 class="notranslate" translate="no">'+TDPHDocumentModel.HTML(AModel.Document.GetValue<string>('project'))+'</h1><p class="status">Generation '+AModel.Document.GetValue('generation_id').Value+' | '+
      IfThen(AModel.Document.GetValue<Boolean>('analysis_complete'),'Captured analysis complete','PARTIAL analysis')+' | '+IfThen(AModel.Document.GetValue<Boolean>('detached'),'Detached source','Connected capture')+' | '+IfThen(AModel.Document.GetValue<Boolean>('stale'),'STALE evidence','Captured fingerprint')+'</p><p>Static evidence; runtime behavior unobserved. Human verification is recorded separately.</p></header><nav>');
    for V in AModel.Document.GetValue<TJSONArray>('sections') do begin R:=V as TJSONObject; Page.Append('<a href="#'+R.GetValue<string>('id')+'">'+TDPHDocumentModel.HTML(R.GetValue<string>('title'))+'</a>'); end;
    Page.Append('</nav><p><a href="learning.html">Start learning this application</a></p><p><label>Search objects <input id="search" type="search" placeholder="Name, kind or signature"></label></p>');
    if LocalePage<>'' then Page.Append('<p><a href="'+LocalePage+'">Localized authored sections ('+ALocale+')</a>: '+TranslatedCount.ToString+' reviewed; '+FallbackCount.ToString+' source-language fallbacks. Generated guidance remains source language.</p>');
    Page.Append('<section><h2>Source navigation</h2><p>'+IfThen(AIncludeSourceNavigation,'Explicitly included redacted browsing views: ','Excluded by default. ')+
      RenderedSources.ToString+' rendered files; '+OmittedSources.ToString+' omitted files. Original source bytes are not included.</p>');
    if AIncludeSourceNavigation then begin Page.Append('<details><summary>Browse captured source files and omissions</summary><ul>');
      for V in SourceRows do begin Page.Append('<li>');
        if V.GetValue<string>('artifact')<>'' then Page.Append('<a class="notranslate" translate="no" href="'+V.GetValue<string>('artifact')+'">'+TDPHDocumentModel.HTML(V.GetValue<string>('source'))+'</a>')
        else Page.Append(TDPHDocumentModel.HTML(V.GetValue<string>('source'))+' - '+TDPHDocumentModel.HTML(V.GetValue<string>('state').Replace('_',' ')));
        Page.Append('</li>');
      end; Page.Append('</ul></details>');
    end; Page.Append('</section>');
    for V in AModel.Document.GetValue<TJSONArray>('screenshots') do begin R:=V as TJSONObject;
      Page.Append('<figure id="screenshot_'+R.GetValue<string>('artifact_hash','')+'"><img width="640" src="images/'+R.GetValue<string>('image')+'" alt="'+TDPHDocumentModel.HTML(R.GetValue<string>('caption'))+'"><figcaption>'+TDPHDocumentModel.HTML(R.GetValue<string>('caption'))+' | Contributor: '+TDPHDocumentModel.HTML(R.GetValue<string>('author'))+' | user supplied, unverified | generation '+R.GetValue('generation_id').Value+'</figcaption></figure>');
    end;
    Page.Append('<section id="business-glossary"><h2>Business glossary</h2><p>Definitions are attributed to contributors. Check each term revision, review state and source evidence before relying on it.</p>');
    for V in AModel.Document.GetValue<TJSONArray>('knowledge') do if V.GetValue<string>('kind')='glossary' then
      Page.Append('<p><a href="#knowledge_'+V.GetValue<string>('id')+'">'+TDPHDocumentModel.HTML(V.GetValue<string>('title'))+'</a> | '+
        TDPHDocumentModel.HTML(V.GetValue<string>('state'))+' | revision '+V.GetValue<string>('revision')+'</p>');
    Page.Append('</section>');
    for V in AModel.Document.GetValue<TJSONArray>('sections') do begin R:=V as TJSONObject; Page.Append('<section id="'+R.GetValue<string>('id')+'"><h2>'+TDPHDocumentModel.HTML(R.GetValue<string>('title'))+'</h2>');
      Page.Append('<p>Section '+TDPHDocumentModel.HTML(R.GetValue<string>('section_id'))+' | version <code class="notranslate" translate="no">'+
        TDPHDocumentModel.HTML(R.GetValue<string>('section_version'))+'</code> | source generation '+R.GetValue<string>('source_generation')+
        ' | '+TDPHDocumentModel.HTML(R.GetValue<string>('verification_state'))+' | last reviewed '+TDPHDocumentModel.HTML(R.GetValue<string>('last_reviewed'))+'</p>');
      for W in R.GetValue<TJSONArray>('paragraphs') do Page.Append('<p>'+TDPHDocumentModel.HTML(W.Value)+'</p>');
      for W in R.GetValue<TJSONArray>('knowledge_ids') do Page.Append('<p><a href="#knowledge_'+W.Value+'">Attributed knowledge '+W.Value+'</a></p>');
      Page.Append('</section>');
    end;
    for V in AModel.Document.GetValue<TJSONArray>('knowledge') do begin R:=V as TJSONObject;
      Page.Append('<article id="knowledge_'+R.GetValue<string>('id')+'" data-search="'+TDPHDocumentModel.HTML(LowerCase(R.GetValue<string>('title')+' '+R.GetValue<string>('body')))+'"><h2>'+TDPHDocumentModel.HTML(R.GetValue<string>('title'))+'</h2><p>Section '+
        TDPHDocumentModel.HTML(R.GetValue<string>('section_id'))+' | revision '+R.GetValue<string>('revision')+' | source generation '+R.GetValue<string>('source_generation')+
        ' | '+TDPHDocumentModel.HTML(R.GetValue<string>('state'))+' | author '+TDPHDocumentModel.HTML(R.GetValue<string>('owner'))+
        ' | reviewer '+TDPHDocumentModel.HTML(IfThen(R.GetValue<string>('reviewer')='','unassigned',R.GetValue<string>('reviewer')))+
        ' | last reviewed '+TDPHDocumentModel.HTML(IfThen(R.GetValue<string>('reviewed_at')='','never',R.GetValue<string>('reviewed_at')))+
        '</p><pre>'+TDPHDocumentModel.HTML(R.GetValue<string>('body'))+'</pre>');
      if R.GetValue('process_diagram')<>nil then Page.Append(TDPHGraphProjection.WorkflowSVG(R.GetValue<TJSONObject>('process_diagram')));
      for RevisionValue in R.GetValue<TJSONArray>('history') do begin
        Page.Append('<details id="knowledge_revision_'+RevisionValue.GetValue<string>('revision')+'"><summary>Revision '+RevisionValue.GetValue<string>('revision')+
          ' | '+TDPHDocumentModel.HTML(RevisionValue.GetValue<string>('verification_state'))+' | '+TDPHDocumentModel.HTML(RevisionValue.GetValue<string>('editor'))+'</summary><p>'+
          TDPHDocumentModel.HTML(RevisionValue.GetValue<string>('body'))+'</p></details>');
      end;
      if R.GetValue('rich_links')<>nil then for LinkValue in R.GetValue<TJSONArray>('rich_links') do begin
        Anchor:='';
        if LinkValue.GetValue<string>('target_kind')='entity' then Anchor:='#s_'+THashSHA2.GetHashString(LinkValue.GetValue<string>('canonical_key'));
        if LinkValue.GetValue<string>('target_kind')='section' then Anchor:='#knowledge_revision_'+LinkValue.GetValue<string>('target_id');
        if LinkValue.GetValue<string>('target_kind')='screenshot' then Anchor:='#screenshot_'+LinkValue.GetValue<string>('screenshot_hash');
        Page.Append('<details><summary>'+TDPHDocumentModel.HTML(LinkValue.GetValue<string>('link_role')+' | '+LinkValue.GetValue<string>('label'))+'</summary>');
        if Anchor<>'' then Page.Append('<p><a href="'+Anchor+'">Open linked target</a></p>');
        Page.Append('<p>Captured generation '+TDPHDocumentModel.HTML(LinkValue.GetValue<string>('source_generation'))+' | '+
          TDPHDocumentModel.HTML(LinkValue.GetValue<string>('resolution','inferred'))+'</p>');
        if MatchText(LinkValue.GetValue<string>('target_kind'),['relationship','evidence']) then
          Page.Append('<p>Source range: '+TDPHDocumentModel.HTML(LinkValue.GetValue<string>('source_range'))+'</p><pre>'+TDPHDocumentModel.HTML(LinkValue.GetValue<string>('evidence_payload'))+'</pre>');
        Page.Append('</details>');
      end;
      if R.GetValue<Integer>('omitted_rich_links',0)>0 then Page.Append('<p>Some links were omitted because their targets are outside this export scope.</p>');
      Page.Append('</article>');
    end;
    IndexText:='';
    for V in AModel.Document.GetValue<TJSONArray>('symbols') do begin R:=V as TJSONObject; Anchor:='s_'+THashSHA2.GetHashString(R.GetValue<string>('key'));
      Path:='objects/'+THashSHA2.GetHashString(R.GetValue<string>('key'))+'.html';
      try ObjectPage:=TRegEx.Replace(Explanations.ObjectLessonHTML(R.GetValue<string>('key')),'href="#s_([a-fA-F0-9]{64})"','href="$1.html"');
        ObjectPage:=ObjectPage.Replace('<body>','<body><p><a href="../learning.html">Return to learning topics</a></p>');
        LineAvailable:=False;
        if SourcePages.TryGetValue(R.GetValue<string>('range.source'),SourceRecord) then for SourceSymbol in SourceRecord.GetValue<TJSONArray>('included_line_numbers') do
          if SourceSymbol.Value=R.GetValue<Integer>('range.line').ToString then LineAvailable:=True;
        if LineAvailable then
          ObjectPage:=ObjectPage.Replace('<body>','<body><p><a href="'+ExtractFileName(SourceRecord.GetValue<string>('artifact'))+'#L'+R.GetValue<Integer>('range.line').ToString+'">Read captured redacted source at this line</a></p>');
        Write(Path,ObjectPage);
      except on E: Exception do raise EReadError.Create('Object explanation '+R.GetValue<string>('name')+': '+E.ClassName+': '+E.Message); end;
      Page.Append('<p><a href="'+Path+'">Explain '+TDPHDocumentModel.HTML(R.GetValue<string>('name'))+' - role, callers, effects, execution trace and control flow</a></p>');
      Page.Append('<article id="'+Anchor+'" data-search="'+TDPHDocumentModel.HTML(LowerCase(R.GetValue<string>('name')+' '+R.GetValue<string>('kind')+' '+R.GetValue<string>('signature')))+'"><h2 class="notranslate" translate="no">'+TDPHDocumentModel.HTML(R.GetValue<string>('name'))+'</h2><p>'+TDPHDocumentModel.HTML(R.GetValue<string>('kind'))+'</p><pre class="notranslate" translate="no">'+TDPHDocumentModel.HTML(R.GetValue<string>('signature'))+'</pre><p class="notranslate" translate="no">'+TDPHDocumentModel.HTML(R.GetValue<string>('range.source'))+' line '+R.GetValue<Integer>('range.line').ToString+' | SHA256 '+R.GetValue<string>('source_hash')+'</p>');
      if LineAvailable then Page.Append('<p><a href="'+SourceRecord.GetValue<string>('artifact')+'#L'+R.GetValue<Integer>('range.line').ToString+'">Read captured redacted source</a></p>');
      if ByFrom.TryGetValue(R.GetValue<string>('key'),Neighbors) then for J in Neighbors do begin
        Page.Append('<p>'+TDPHDocumentModel.HTML(J.GetValue<string>('kind'))+' ['+TDPHDocumentModel.HTML(J.GetValue<string>('resolution'))+'] ');
        if J.GetValue<string>('to','')<>'' then Page.Append('<a class="notranslate" translate="no" href="#s_'+THashSHA2.GetHashString(J.GetValue<string>('to'))+'">'+TDPHDocumentModel.HTML(J.GetValue<string>('label'))+'</a>')
        else Page.Append('<span class="notranslate" translate="no">'+TDPHDocumentModel.HTML(J.GetValue<string>('label'))+'</span>');
        Page.Append(' <a href="#'+J.GetValue<string>('evidence_id')+'">evidence</a></p>');
      end; Page.Append('</article>'); IndexText:=IndexText+R.ToJSON+#10;
    end;
    Page.Append('<section><h2>Evidence</h2>');
    for V in AModel.Document.GetValue<TJSONArray>('evidence') do begin R:=V as TJSONObject; Page.Append('<p id="'+R.GetValue<string>('id')+'" class="notranslate" translate="no">'+TDPHDocumentModel.HTML(R.ToJSON)+'</p>'); end;
    Page.Append('</section><section><h2>Known unknowns</h2><p>'+TDPHDocumentModel.HTML(AModel.Document.GetValue<string>('known_unknowns'))+'</p><p>Offline edition. Online GTranslate is disabled. Atlas DAT translation is available in the native Translations workspace for explicitly selected saved sections; this edition retains source-language prose.</p><div class="gtranslate_wrapper" data-online-translation="disabled"></div><select data-language-list disabled><option>English</option><option>Espa&#241;ol Spanish</option><option>Fran&#231;ais French</option><option>Deutsch German</option></select></section><script src="assets/search.js"></script><script src="assets/translation-selector.js"></script></body></html>');
    Write('index.html',Page.ToString); Write('indexes/symbols.jsonl',IndexText);
    JSONL('indexes/relationships.jsonl',AModel.Document.GetValue<TJSONArray>('relationships'));
    JSONL('evidence/references.jsonl',AModel.Document.GetValue<TJSONArray>('evidence'));
    JSONL('indexes/control-flow.jsonl',AModel.Document.GetValue<TJSONArray>('flow_nodes'));
    Write('indexes/configuration.jsonl',AModel.Document.GetValue<TJSONObject>('analysis_configuration').ToJSON+#10);
    JSONL('indexes/files.jsonl',AModel.Document.GetValue<TJSONArray>('files'));
    Lines.Clear; for V in AModel.Document.GetValue<TJSONArray>('symbols') do if MatchText((V as TJSONObject).GetValue<string>('kind'),['component','event']) then Lines.Append(V.ToJSON).Append(#10); Write('indexes/forms-events.jsonl',Lines.ToString);
    Lines.Clear; for V in AModel.Document.GetValue<TJSONArray>('relationships') do if MatchText((V as TJSONObject).GetValue<string>('kind'),['reads','writes','renders','static_sql']) then Lines.Append(V.ToJSON).Append(#10); Write('indexes/data-usage.jsonl',Lines.ToString);
    JSONL('indexes/knowledge.jsonl',AModel.Document.GetValue<TJSONArray>('knowledge'));
    Lines.Clear; for V in AModel.Document.GetValue<TJSONArray>('knowledge') do if V.GetValue<string>('kind')='glossary' then Lines.Append(V.ToJSON).Append(#10);
    Write('indexes/glossary.jsonl',Lines.ToString);
    Write('validation/coverage.json',AModel.Document.GetValue<TJSONObject>('coverage').Format(2));
    Write('README.md','# '+AModel.Document.GetValue<string>('project')+' handoff'+#10+#10+
      '1. Open learning.html offline. Start with the purpose, follow a screen action and read supplied task instructions.'+#10+
      '2. Compare manifest.json input_fingerprint with a separately trusted capture identity. Run DPH.ValidateHandoff with the bundle directory and that fingerprint; use --allow-stale only for explicit historical inspection.'+#10+
      '3. Read project-summary.md, architecture.md, build-and-test.md, known-risks.md and decisions-and-unknowns.md. Follow exact source ranges in evidence/references.jsonl.'+#10+
      '4. Inspect coverage and authored section review states. Hashes establish integrity relative to this manifest, not author authentication.'+#10+#10+
      'All routes and indexes are relative. Original source, external roots, secrets and owner AGENTS.md are excluded. Generated agent boundary instructions are included only when explicitly selected. No authority to modify or execute the analyzed project is granted by this bundle.'+#10);
    Write('known-risks.md',AModel.Document.GetValue<string>('known_unknowns')+#10);
    for V in AModel.Document.GetValue<TJSONArray>('sections') do begin R:=V as TJSONObject; Lines.Clear; Lines.Append('# ').Append(R.GetValue<string>('title')).Append(#10#10);
      for W in R.GetValue<TJSONArray>('paragraphs') do Lines.Append(W.Value).Append(#10#10); Write(R.GetValue<string>('id')+'.md',Lines.ToString);
    end;
    Lines.Clear; Lines.Append('# Project summary').Append(#10#10).Append('Project: ').Append(AModel.Document.GetValue<string>('project')).Append(#10)
      .Append('Generation: ').Append(AModel.Document.GetValue('generation_id').Value).Append(#10)
      .Append('Configuration/platform: ').Append(AModel.Document.GetValue<string>('configuration')).Append(' / ').Append(AModel.Document.GetValue<string>('platform')).Append(#10)
      .Append('Captured input: ').Append(AModel.Document.GetValue<string>('input_fingerprint')).Append(#10#10);
    for V in AModel.Document.GetValue<TJSONArray>('sections') do if V.GetValue<string>('id')='overview' then for W in V.GetValue<TJSONArray>('paragraphs') do Lines.Append(W.Value).Append(#10#10);
    Write('project-summary.md',Lines.ToString);
    Lines.Clear; Lines.Append('# Architecture').Append(#10#10).Append('Source-derived static architecture; runtime routing and ordering remain qualified.').Append(#10#10);
    for V in AModel.Document.GetValue<TJSONArray>('sections') do if MatchText(V.GetValue<string>('id'),['engineering','maintenance']) then
      for W in V.GetValue<TJSONArray>('paragraphs') do Lines.Append(W.Value).Append(#10#10);
    Lines.Append('## Evidence indexes').Append(#10).Append('indexes/symbols.jsonl, indexes/relationships.jsonl, indexes/forms-events.jsonl, indexes/data-usage.jsonl and evidence/references.jsonl carry exact identity, certainty and source ranges.').Append(#10);
    Write('architecture.md',Lines.ToString);
    Lines.Clear; Lines.Append('# Build and test').Append(#10#10).Append('Captured analysis selection:').Append(#10)
      .Append(AModel.Document.GetValue<TJSONObject>('analysis_configuration').Format(2)).Append(#10#10)
      .Append('Required toolchain and environment:').Append(#10).Append(AModel.Document.GetValue<TJSONObject>('required_toolchain').Format(2)).Append(#10#10)
      .Append('DPH did not compile or run the selected project. A parsed project file does not establish a working build command or deployed prerequisites. Use only attributed reviewed procedures and obtain execution authorization.').Append(#10#10);
    for V in AModel.Document.GetValue<TJSONArray>('sections') do if V.GetValue<string>('id')='build_deploy' then
      for W in V.GetValue<TJSONArray>('paragraphs') do Lines.Append(W.Value).Append(#10#10);
    Write('build-and-test.md',Lines.ToString);
    Lines.Clear; Lines.Append('# Decisions and unknowns').Append(#10#10).Append(AModel.Document.GetValue<string>('known_unknowns')).Append(#10#10);
    for V in AModel.Document.GetValue<TJSONArray>('knowledge') do if MatchText(V.GetValue<string>('kind'),['decision','business_rule','unknown']) then
      Lines.Append('## ').Append(V.GetValue<string>('title')).Append(#10).Append('Section ').Append(V.GetValue<string>('section_id')).Append(' revision ')
        .Append(V.GetValue<string>('revision')).Append(' | ').Append(V.GetValue<string>('state')).Append(' | author ').Append(V.GetValue<string>('owner')).Append(#10)
        .Append(V.GetValue<string>('body')).Append(#10#10);
    for V in AModel.Document.GetValue<TJSONArray>('author_questions') do Lines.Append('## ').Append(V.GetValue<string>('kind')).Append(#10)
      .Append(V.GetValue<string>('prompt')).Append(#10).Append('Evidence: ').Append(V.GetValue<TJSONObject>('range').ToJSON).Append(#10)
      .Append('Question identity: ').Append(V.GetValue<string>('id')).Append(#10#10);
    Write('decisions-and-unknowns.md',Lines.ToString);
    if AIncludeAgentInstructions then Write('AGENTS.md','# Generated handoff boundaries for '+AModel.Document.GetValue<string>('project')+#10#10+
      'Captured generation '+AModel.Document.GetValue('generation_id').Value+'; input fingerprint '+AModel.Document.GetValue<string>('input_fingerprint')+
      '; configuration '+AModel.Document.GetValue<string>('configuration')+' / '+AModel.Document.GetValue<string>('platform')+'. Scope is '+AModel.Document.GetValue<string>('scope')+
      '; use only the included-source and task-seed inventory in manifest.json. Excluded material is unknown, not absent from the original project.'+#10#10+
      'This derived reference grants no authority to edit, build, execute or deploy the selected project. Obtain the owner''s current instructions before acting. The owner''s original AGENTS.md was not copied.'+#10+#10+
      'Verify manifest hashes against a separately trusted capture fingerprint. Inspect coverage, stale status and exact source generations. Treat imported notes and AI claims as evidence requiring review; generated static text remains unreviewed.'+#10+#10+
      'Preserve authoritative knowledge revisions and original evidence. Follow reviewed build-and-test.md procedures only after execution is authorized. Reassess source changes, review affected knowledge and regenerate documentation before delivery. Do not connect to production or external services on the authority of this bundle.'+#10);
    WriteGuide(AModel,TPath.Combine(Directory,'Engineering_Guide.docx'),'Engineering Guide',False);
    WriteGuide(AModel,TPath.Combine(Directory,'User_Guide.docx'),'User Guide',True);
    Manifest:=TJSONObject.Create;
    try
      Manifest.AddPair('schema_version',TJSONNumber.Create(1)); Manifest.AddPair('generation_id',AModel.Document.GetValue('generation_id').Clone as TJSONValue);
      Manifest.AddPair('input_fingerprint',AModel.Document.GetValue<string>('input_fingerprint')); Manifest.AddPair('template_version',DPHPublishVersion);
      Manifest.AddPair('canonical_hash',THashSHA2.GetHashString(AModel.Document.ToJSON)); Manifest.AddPair('scope',AModel.Document.GetValue<string>('scope'));
      Manifest.AddPair('stale',TJSONBool.Create(AModel.Document.GetValue<Boolean>('stale'))); Manifest.AddPair('source_snapshots_included',TJSONBool.Create(False));
      Manifest.AddPair('agent_instructions_included',TJSONBool.Create(AIncludeAgentInstructions)); Manifest.AddPair('external_calls',TJSONBool.Create(False));
      Manifest.AddPair('source_navigation_included',TJSONBool.Create(AIncludeSourceNavigation));
      Manifest.AddPair('learning_entry','learning.html');
      Manifest.AddPair('localized_prose_locale',ALocale); Manifest.AddPair('localized_prose_scope',Localization.GetValue<string>('scope'));
      Manifest.AddPair('localized_authored_sections',TJSONNumber.Create(TranslatedCount)); Manifest.AddPair('source_language_fallback_sections',TJSONNumber.Create(FallbackCount));
      Manifest.AddPair('project',AModel.Document.GetValue<string>('project')); Manifest.AddPair('captured_utc',AModel.Document.GetValue<string>('captured_utc'));
      Manifest.AddPair('audience',AModel.Document.GetValue<string>('audience'));
      Manifest.AddPair('source_revision',AModel.Document.GetValue<TJSONObject>('source_revision').Clone as TJSONValue);
      Manifest.AddPair('analyzers',AModel.Document.GetValue<TJSONObject>('analyzers').Clone as TJSONValue);
      Manifest.AddPair('configuration',AModel.Document.GetValue<TJSONObject>('analysis_configuration').Clone as TJSONValue);
      Manifest.AddPair('required_toolchain',AModel.Document.GetValue<TJSONObject>('required_toolchain').Clone as TJSONValue);
      Manifest.AddPair('included_sources',AModel.Document.GetValue<TJSONArray>('files').Clone as TJSONValue);
      Manifest.AddPair('excluded_sources',AModel.Document.GetValue<TJSONArray>('exclusions').Clone as TJSONValue);
      Manifest.AddPair('task_seeds',AModel.Document.GetValue<TJSONArray>('task_seeds').Clone as TJSONValue);
      Manifest.AddPair('portability_scope','relative local routes, indexes, copied managed images and optional redacted source browsing pages; no original source bytes or absolute dependency roots');
      Manifest.AddPair('disclosure_limitations','Scoped redacted static evidence and attributed knowledge. Review explicit exclusions and remaining prose before sharing; redaction is not a confidentiality guarantee.');
      Manifest.AddPair('hash_index','validation/manifest-sha256.json'); Write('manifest.json',Manifest.Format(2));
    finally Manifest.Free; end;
    Hashes:=TJSONObject.Create;
    try Files:=TDirectory.GetFiles(Directory,'*',TSearchOption.soAllDirectories); TArray.Sort<string>(Files);
      for Path in Files do begin Relative:=ExtractRelativePath(IncludeTrailingPathDelimiter(Directory),Path).Replace('\','/'); Hashes.AddPair(Relative,THashSHA2.GetHashStringFromFile(Path)); end;
      Write('validation/manifest-sha256.json',Hashes.Format(2));
    finally Hashes.Free; end;
    Validate(Directory,AModel.Document.GetValue<string>('input_fingerprint'),False);
  finally Localization.Free; Navigation.Free; SourcePages.Free; Explanations.Free; ByFrom.Free; Page.Free; Lines.Free; end;
end;
class procedure TDPHPublisher.Validate(const ADirectory,AExpectedFingerprint: string; ARejectStale: Boolean);
var Hashes,Manifest,Canonical,Row,Referenced: TJSONObject; Pair: TJSONPair; Path,Root: string; Files: TArray<string>; V,W: TJSONValue; Generation: Int64;
    Sources,Symbols,Evidence,Flow: TDictionary<string,TJSONObject>; ArtifactCount,RenderedSources,OmittedSources,LastLine: Integer; BrowseInfo,BrowseSource: TJSONObject; BrowsedFiles: TDictionary<string,Boolean>;
  procedure CheckTree(const Directory: string);
  var Entry: string; Attributes: Cardinal;
  begin
    for Entry in TDirectory.GetFileSystemEntries(Directory) do begin
      Attributes:=GetFileAttributes(PChar(Entry));
      if (Attributes=INVALID_FILE_ATTRIBUTES) or ((Attributes and FILE_ATTRIBUTE_REPARSE_POINT)<>0) then raise EReadError.Create('Reparse or inaccessible artifact path');
      Inc(ArtifactCount); if ArtifactCount>100000 then raise EReadError.Create('Artifact count exceeds validation limit');
      if (Attributes and FILE_ATTRIBUTE_DIRECTORY)<>0 then CheckTree(Entry)
      else if TFile.GetSize(Entry)>128*1024*1024 then raise EReadError.Create('Artifact exceeds 128 MiB validation limit');
    end;
  end;
  procedure CheckJSONL(const Name,ArrayName: string; const Kinds: TArray<string>);
  var Lines: TArray<string>; Line: string; Index: Integer; Parsed: TJSONValue; Rows: TJSONArray;
  begin
    Rows:=Canonical.GetValue<TJSONArray>(ArrayName); Index:=0;
    Lines:=TFile.ReadAllLines(TPath.Combine(Root,Name.Replace('/',PathDelim)),TEncoding.UTF8);
    for Line in Lines do begin
      if Trim(Line)='' then Continue;
      while (Index<Rows.Count) and (Length(Kinds)>0) and not MatchText((Rows.Items[Index] as TJSONObject).GetValue<string>('kind'),Kinds) do Inc(Index);
      Parsed:=TJSONObject.ParseJSONValue(Line);
      try
        if (Parsed=nil) or (Index>=Rows.Count) or (Parsed.ToJSON<>Rows.Items[Index].ToJSON) then raise EReadError.Create('Technical index differs from canonical model: '+Name);
      finally Parsed.Free; end; Inc(Index);
    end;
    while (Index<Rows.Count) and (Length(Kinds)>0) and not MatchText((Rows.Items[Index] as TJSONObject).GetValue<string>('kind'),Kinds) do Inc(Index);
    if Index<>Rows.Count then raise EReadError.Create('Incomplete technical index: '+Name);
  end;
  procedure CheckRange(AValue: TJSONObject);
  var Source: TJSONObject; Range: TJSONObject;
  begin
    Range:=AValue.GetValue<TJSONObject>('range');
    if not Sources.TryGetValue(Range.GetValue<string>('source'),Source) then raise EReadError.Create('Evidence references a missing or excluded file');
    if (Source.GetValue<string>('sha256')<>AValue.GetValue<string>('source_hash')) or (Range.GetValue<Int64>('start')<0) or
      (Range.GetValue<Int64>('end')<Range.GetValue<Int64>('start')) or (Range.GetValue<Int64>('end')>Source.GetValue<Int64>('bytes')) then raise EReadError.Create('Evidence source hash or byte range mismatch');
    if AValue.GetValue<Int64>('generation_id')<>Generation then raise EReadError.Create('Cross-generation export record');
  end;
begin
  Root:=IncludeTrailingPathDelimiter(TPath.GetFullPath(ADirectory));
  Path:=ExcludeTrailingPathDelimiter(Root);
  repeat
    if (GetFileAttributes(PChar(Path)) and FILE_ATTRIBUTE_REPARSE_POINT)<>0 then raise EReadError.Create('Reparse artifact root');
    Path:=ExtractFileDir(Path);
  until (Path='') or (Length(Path)<=3);
  ArtifactCount:=0; CheckTree(Root);
  Hashes:=TJSONObject.ParseJSONValue(TFile.ReadAllText(TPath.Combine(Root,'validation/manifest-sha256.json'),TEncoding.UTF8)) as TJSONObject;
  Manifest:=nil; Canonical:=nil; Sources:=TDictionary<string,TJSONObject>.Create; Symbols:=TDictionary<string,TJSONObject>.Create;
  Evidence:=TDictionary<string,TJSONObject>.Create; Flow:=TDictionary<string,TJSONObject>.Create;
  try
    if Hashes=nil then raise EReadError.Create('Invalid checksum index');
    for Pair in Hashes do begin
      if Pair.JsonString.Value.Contains('..') or Pair.JsonString.Value.Contains(':') or StartsText('/',Pair.JsonString.Value) then raise EReadError.Create('Invalid artifact filename');
      Path:=TPath.GetFullPath(TPath.Combine(Root,Pair.JsonString.Value));
      if not StartsText(Root,Path) or not TFile.Exists(Path) or (THashSHA2.GetHashStringFromFile(Path)<>Pair.JsonValue.Value) then raise EReadError.Create('Artifact hash validation failed');
    end;
    Files:=TDirectory.GetFiles(Root,'*',TSearchOption.soAllDirectories); if Length(Files)<>Hashes.Count+1 then raise EReadError.Create('Unexpected or missing artifact file');
    Manifest:=TJSONObject.ParseJSONValue(TFile.ReadAllText(TPath.Combine(Root,'manifest.json'),TEncoding.UTF8)) as TJSONObject;
    if (Manifest=nil) or (Manifest.GetValue<Integer>('schema_version')<>1) then raise EReadError.Create('Unsupported handoff schema');
    if Manifest.GetValue<string>('input_fingerprint')<>AExpectedFingerprint then raise EReadError.Create('Handoff fingerprint is stale');
    if ARejectStale and Manifest.GetValue<Boolean>('stale') then raise EReadError.Create('Handoff is explicitly marked stale');
    Canonical:=TJSONObject.ParseJSONValue(TFile.ReadAllText(TPath.Combine(Root,'canonical.json'),TEncoding.UTF8)) as TJSONObject;
    if (Canonical=nil) or (Canonical.GetValue<Integer>('schema_version')<>1) or (THashSHA2.GetHashString(Canonical.ToJSON)<>Manifest.GetValue<string>('canonical_hash')) then raise EReadError.Create('Canonical documentation model does not match manifest');
    Generation:=Manifest.GetValue<Int64>('generation_id'); if (Canonical.GetValue<Int64>('generation_id')<>Generation) or (Canonical.GetValue<string>('input_fingerprint')<>AExpectedFingerprint) then raise EReadError.Create('Canonical generation/fingerprint mismatch');
    if (Canonical.GetValue<Boolean>('stale')<>Manifest.GetValue<Boolean>('stale')) or
      (Canonical.GetValue<string>('template_version')<>Manifest.GetValue<string>('template_version')) or
      (Canonical.GetValue<string>('scope')<>Manifest.GetValue<string>('scope')) then raise EReadError.Create('Canonical publication metadata mismatch');
    if Manifest.GetValue('analyzers')<>nil then begin
      for Path in ['project','captured_utc','audience','source_revision','analyzers','required_toolchain','task_seeds'] do
        if (Manifest.GetValue(Path)=nil) or (Canonical.GetValue(Path)=nil) or (Manifest.GetValue(Path).ToJSON<>Canonical.GetValue(Path).ToJSON) then
          raise EReadError.Create('Handoff provenance metadata mismatch: '+Path);
      if (Manifest.GetValue<TJSONObject>('configuration').ToJSON<>Canonical.GetValue<TJSONObject>('analysis_configuration').ToJSON) or
        (Manifest.GetValue<TJSONArray>('included_sources').ToJSON<>Canonical.GetValue<TJSONArray>('files').ToJSON) or
        (Manifest.GetValue<TJSONArray>('excluded_sources').ToJSON<>Canonical.GetValue<TJSONArray>('exclusions').ToJSON) then
        raise EReadError.Create('Handoff configuration or source scope mismatch');
      if Manifest.GetValue<Boolean>('agent_instructions_included')<>TFile.Exists(TPath.Combine(Root,'AGENTS.md')) then
        raise EReadError.Create('Generated agent instruction disclosure mismatch');
    end;
    for V in Canonical.GetValue<TJSONArray>('files') do begin Row:=V as TJSONObject; Sources.Add(Row.GetValue<string>('path'),Row); end;
    if Manifest.GetValue('source_navigation_included')<>nil then begin
      BrowseInfo:=TJSONObject.ParseJSONValue(TFile.ReadAllText(TPath.Combine(Root,'source-navigation.json'),TEncoding.UTF8)) as TJSONObject;
      BrowsedFiles:=TDictionary<string,Boolean>.Create;
      try
        if (BrowseInfo=nil) or (BrowseInfo.GetValue<Boolean>('included')<>Manifest.GetValue<Boolean>('source_navigation_included')) or BrowseInfo.GetValue<Boolean>('raw_source_snapshots') then
          raise EReadError.Create('Source navigation disclosure mismatch');
        RenderedSources:=0; OmittedSources:=0;
        if not BrowseInfo.GetValue<Boolean>('included') and (BrowseInfo.GetValue<TJSONArray>('files').Count<>0) then raise EReadError.Create('Unexpected source navigation records');
        if BrowseInfo.GetValue<Boolean>('included') and (BrowseInfo.GetValue<TJSONArray>('files').Count<>Sources.Count) then raise EReadError.Create('Source navigation scope differs from canonical inventory');
        for V in BrowseInfo.GetValue<TJSONArray>('files') do begin
          if BrowsedFiles.ContainsKey(V.GetValue<string>('source')) then raise EReadError.Create('Duplicate source browsing record');
          BrowsedFiles.Add(V.GetValue<string>('source'),True);
          if not Sources.TryGetValue(V.GetValue<string>('source'),BrowseSource) or (BrowseSource.GetValue<string>('sha256')<>V.GetValue<string>('original_sha256')) then raise EReadError.Create('Source browsing references a different captured file');
          Path:=V.GetValue<string>('artifact');
          if Path='' then begin Inc(OmittedSources); if not StartsText('omitted_',V.GetValue<string>('state')) then raise EReadError.Create('Unexplained source browsing omission'); Continue; end;
          if not StartsText('objects/',Path) or (Length(Path)<>77) or (V.GetValue<string>('state')<>'redacted_captured_text') or
            (V.GetValue<Integer>('line_count')<1) or (V.GetValue<Integer>('line_count')>20000) or (V.GetValue<Int64>('generation_id')<>Generation) or (Hashes.GetValue(Path)=nil) then
            raise EReadError.Create('Invalid redacted source browsing artifact');
          if (V.GetValue<Boolean>('task_excerpts')<>(Canonical.GetValue<string>('scope')='task')) or
            (V.GetValue<Integer>('rendered_line_count')<>V.GetValue<TJSONArray>('included_line_numbers').Count) or
            (V.GetValue<Integer>('rendered_line_count')<1) then raise EReadError.Create('Source browsing excerpt scope mismatch');
          LastLine:=0;
          for W in V.GetValue<TJSONArray>('included_line_numbers') do begin
            if (StrToInt(W.Value)<=LastLine) or (StrToInt(W.Value)>V.GetValue<Integer>('line_count')) then raise EReadError.Create('Invalid source line anchor identity');
            LastLine:=StrToInt(W.Value);
          end;
          if not V.GetValue<Boolean>('task_excerpts') and (V.GetValue<Integer>('rendered_line_count')<>V.GetValue<Integer>('line_count')) then raise EReadError.Create('Incomplete full-source browsing page');
          Inc(RenderedSources);
        end;
        if (RenderedSources<>BrowseInfo.GetValue<Integer>('rendered_files')) or (OmittedSources<>BrowseInfo.GetValue<Integer>('omitted_files')) then raise EReadError.Create('Source browsing coverage count mismatch');
      finally BrowsedFiles.Free; BrowseInfo.Free; end;
    end;
    if Manifest.GetValue('localized_prose_locale')<>nil then begin
      BrowseInfo:=TJSONObject.ParseJSONValue(TFile.ReadAllText(TPath.Combine(Root,'localization.json'),TEncoding.UTF8)) as TJSONObject;
      BrowsedFiles:=TDictionary<string,Boolean>.Create;
      try
        if (BrowseInfo=nil) or (BrowseInfo.GetValue<string>('requested_locale')<>Manifest.GetValue<string>('localized_prose_locale')) or
          (BrowseInfo.GetValue<string>('scope')<>Manifest.GetValue<string>('localized_prose_scope')) then raise EReadError.Create('Localization disclosure mismatch');
        RenderedSources:=0; OmittedSources:=0;
        if BrowseInfo.GetValue<string>('requested_locale')='' then begin
          if (BrowseInfo.GetValue<TJSONArray>('sections').Count<>0) or (BrowseInfo.GetValue<string>('html')<>'') or TFile.Exists(TPath.Combine(Root,'Localized_Sections.docx')) then
            raise EReadError.Create('Unexpected localized publication without a requested locale');
        end else begin
          if BrowseInfo.GetValue<TJSONArray>('sections').Count<>Canonical.GetValue<TJSONArray>('knowledge').Count then raise EReadError.Create('Localized section scope differs from canonical knowledge');
          Path:=BrowseInfo.GetValue<string>('html');
          if not StartsText('objects/',Path) or (Length(Path)<>77) or (Hashes.GetValue(Path)=nil) or not TFile.Exists(TPath.Combine(Root,'Localized_Sections.docx')) then
            raise EReadError.Create('Missing localized HTML or editable supplement');
        end;
        for V in BrowseInfo.GetValue<TJSONArray>('sections') do begin
          if BrowsedFiles.ContainsKey(V.GetValue<string>('id')) then raise EReadError.Create('Duplicate localized section');
          BrowsedFiles.Add(V.GetValue<string>('id'),True); BrowseSource:=nil;
          for W in Canonical.GetValue<TJSONArray>('knowledge') do if W.GetValue<string>('id')=V.GetValue<string>('id') then BrowseSource:=W as TJSONObject;
          if (BrowseSource=nil) or (BrowseSource.GetValue<string>('revision')<>V.GetValue<string>('revision')) or
            (BrowseSource.GetValue<string>('section_id')<>V.GetValue<string>('section_id')) or (BrowseSource.GetValue<string>('body')<>V.GetValue<string>('source_body')) then
            raise EReadError.Create('Localized prose refers to a different source revision');
          if V.GetValue<string>('state')='verified_translation' then begin
            if (BrowseSource.GetValue<string>('state')<>'verified') or (BrowseSource.GetValue<string>('pending')<>'0') or
              (V.GetValue<string>('reviewer').Trim='') or (V.GetValue<string>('reviewer')='unassigned') or (V.GetValue<string>('cache_key').Length<>64) then
              raise EReadError.Create('Localized review metadata is incomplete or source review is pending');
            Inc(RenderedSources);
          end else begin
            if (V.GetValue<string>('state')<>'source_fallback_needs_translation') or (V.GetValue<string>('body')<>V.GetValue<string>('source_body')) then
              raise EReadError.Create('Unreviewed localization must preserve source prose and its fallback state');
            Inc(OmittedSources);
          end;
        end;
        if (RenderedSources<>BrowseInfo.GetValue<Integer>('translated_sections')) or (RenderedSources<>Manifest.GetValue<Integer>('localized_authored_sections')) or
          (OmittedSources<>BrowseInfo.GetValue<Integer>('source_fallback_sections')) or (OmittedSources<>Manifest.GetValue<Integer>('source_language_fallback_sections')) then
          raise EReadError.Create('Localized publication coverage mismatch');
      finally BrowsedFiles.Free; BrowseInfo.Free; end;
    end;
    for V in Canonical.GetValue<TJSONArray>('symbols') do begin Row:=V as TJSONObject; CheckRange(Row); Symbols.Add(Row.GetValue<string>('key'),Row);
      if Row.GetValue('source_comments')<>nil then for W in Row.GetValue<TJSONArray>('source_comments') do CheckRange(W as TJSONObject);
    end;
    for V in Canonical.GetValue<TJSONArray>('evidence') do begin Row:=V as TJSONObject; CheckRange(Row); Evidence.Add(Row.GetValue<string>('id'),Row); end;
    for V in Canonical.GetValue<TJSONArray>('relationships') do begin Row:=V as TJSONObject; CheckRange(Row);
      if not Symbols.ContainsKey(Row.GetValue<string>('from')) or ((Row.GetValue<string>('to','')<>'') and not Symbols.ContainsKey(Row.GetValue<string>('to'))) then raise EReadError.Create('Broken relationship symbol reference');
      if not Evidence.TryGetValue(Row.GetValue<string>('evidence_id'),Referenced) or (Referenced.GetValue<TJSONObject>('range').ToJSON<>Row.GetValue<TJSONObject>('range').ToJSON) then raise EReadError.Create('Broken relationship evidence reference');
    end;
    for V in Canonical.GetValue<TJSONArray>('flow_nodes') do begin Row:=V as TJSONObject; CheckRange(Row);
      if not Symbols.ContainsKey(Row.GetValue<string>('routine')) then raise EReadError.Create('Missing control-flow routine'); Flow.Add(Row.GetValue('id').Value,Row);
    end;
    for V in Canonical.GetValue<TJSONArray>('flow_edges') do begin Row:=V as TJSONObject;
      if Row.GetValue<Int64>('generation_id')<>Generation then raise EReadError.Create('Cross-generation control-flow edge');
      if not Flow.ContainsKey(Row.GetValue('from').Value) or not Flow.ContainsKey(Row.GetValue('to').Value) then raise EReadError.Create('Broken control-flow reference');
    end;
    if Canonical.GetValue('startup')<>nil then for V in Canonical.GetValue<TJSONArray>('startup') do begin Row:=V as TJSONObject;
      CheckRange(Row); if Row.GetValue<Int64>('generation_id')<>Generation then raise EReadError.Create('Cross-generation startup explanation');
    end;
    if Canonical.GetValue('screenshots')<>nil then for V in Canonical.GetValue<TJSONArray>('screenshots') do begin Row:=V as TJSONObject;
      if (Row.GetValue<Int64>('generation_id')<>Generation) or (Row.GetValue<string>('verification_state')<>'user_supplied_unverified') or
        (Row.GetValue<string>('image')<>Row.GetValue<string>('image_sha256')+'.png') then raise EReadError.Create('Invalid screenshot provenance');
      Path:=Row.GetValue<string>('image');
      if (Length(Path)<>68) or Path.Contains('/') or Path.Contains('\') or Path.Contains(':') then raise EReadError.Create('Invalid screenshot filename');
      if THashSHA2.GetHashStringFromFile(TPath.Combine(Root,'images\'+Path))<>Row.GetValue<string>('image_sha256') then raise EReadError.Create('Screenshot image hash mismatch');
    end;
    CheckJSONL('indexes/symbols.jsonl','symbols',[]); CheckJSONL('indexes/relationships.jsonl','relationships',[]);
    CheckJSONL('evidence/references.jsonl','evidence',[]); CheckJSONL('indexes/control-flow.jsonl','flow_nodes',[]);
    if Canonical.GetValue('analysis_configuration')<>nil then begin
      if TFile.ReadAllText(TPath.Combine(Root,'indexes/configuration.jsonl'),TEncoding.UTF8)<>Canonical.GetValue<TJSONObject>('analysis_configuration').ToJSON+#10 then
        raise EReadError.Create('Configuration index differs from canonical model');
      CheckJSONL('indexes/files.jsonl','files',[]);
    end else CheckJSONL('indexes/configuration.jsonl','files',[]);
    for V in Canonical.GetValue<TJSONArray>('knowledge') do begin
     Row:=(V as TJSONObject).GetValue<TJSONObject>('structured_record',nil);
     if (Row<>nil) and (Row.GetValue<string>('record_type','')='departmental_workflow') and
       (Canonical.GetValue<string>('template_version')=DPHPublishVersion) and ((V as TJSONObject).GetValue('process_diagram')=nil) then
       raise EReadError.Create('Workflow process diagram is missing');
    end;
    for V in Canonical.GetValue<TJSONArray>('knowledge') do if (V as TJSONObject).GetValue('process_diagram')<>nil then begin
     Row:=TDPHGraphProjection.Workflow(V as TJSONObject,Canonical.GetValue<TJSONArray>('knowledge'),Generation);
     try if Row.ToJSON<>V.GetValue<TJSONObject>('process_diagram').ToJSON then raise EReadError.Create('Process diagram differs from authored canonical workflow');finally Row.Free;end;
    end;
    CheckJSONL('indexes/knowledge.jsonl','knowledge',[]);
    if (Canonical.GetValue<string>('template_version')=DPHPublishVersion) or TFile.Exists(TPath.Combine(Root,'indexes/glossary.jsonl')) then
      CheckJSONL('indexes/glossary.jsonl','knowledge',['glossary']);
    CheckJSONL('indexes/forms-events.jsonl','symbols',['component','event']);
    CheckJSONL('indexes/data-usage.jsonl','relationships',['reads','writes','renders','static_sql']);
  finally Flow.Free; Evidence.Free; Symbols.Free; Sources.Free; Canonical.Free; Manifest.Free; Hashes.Free; end;
end;
end.
