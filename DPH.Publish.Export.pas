unit DPH.Publish.Export;
interface
uses System.SysUtils, System.JSON, DPH.Publish.Model, DPH.Storage.Database;
type
  TDPHPublisher = class
  public
    class procedure Export(AModel: TDPHDocumentModel; AStore: TDPHKnowledgeStore; const ADirectory: string; AIncludeAgentInstructions: Boolean = False); static;
    class procedure Validate(const ADirectory,AExpectedFingerprint: string; ARejectStale: Boolean = True); static;
    class procedure WriteGuide(AModel: TDPHDocumentModel; const APath,ATitle: string; AUser: Boolean); static;
  end;
implementation
uses System.IOUtils, System.Classes, System.StrUtils, System.Hash, System.Zip, System.Generics.Collections, System.Generics.Defaults, Winapi.Windows, DPH.Analysis.Explanations;
class procedure TDPHPublisher.WriteGuide(AModel: TDPHDocumentModel; const APath,ATitle: string; AUser: Boolean);
var Archive: TZipFile; Document,Body,Headings: string; V,W,L: TJSONValue; R: TJSONObject; I: Integer; Linked: Boolean; Explanations: TDPHExplanationModel; Paragraph: string;
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
class procedure TDPHPublisher.Export(AModel: TDPHDocumentModel; AStore: TDPHKnowledgeStore; const ADirectory: string; AIncludeAgentInstructions: Boolean);
var Directory,IndexText,Path,Relative,Anchor: string; V,W,LinkValue,RevisionValue: TJSONValue; R,J,Manifest,Hashes: TJSONObject; Lines,Page: TStringBuilder; Files: TArray<string>;
    ByFrom: TObjectDictionary<string,TList<TJSONObject>>; Neighbors: TList<TJSONObject>;
    Explanations: TDPHExplanationModel;
    Images: TJSONArray; ImageValue: TJSONValue; ImageRow: TJSONObject; ImagePath: string;
  procedure Write(const Name,Text: string);
  var Target: string;
  begin Target:=TPath.Combine(Directory,Name.Replace('/',PathDelim)); TDirectory.CreateDirectory(ExtractFilePath(Target)); TFile.WriteAllBytes(Target,TEncoding.UTF8.GetBytes(Text)); end;
  procedure JSONL(const Name: string; Rows: TJSONArray);
  var Value: TJSONValue;
  begin Lines.Clear; for Value in Rows do Lines.Append(Value.ToJSON).Append(#10); Write(Name,Lines.ToString); end;
begin
  if AModel.LocalDisplay then raise EArgumentException.Create('Local display projection cannot be exported; create a redacted publication model');
  Directory:=TPath.GetFullPath(ADirectory); AStore.CheckOutsideSource(Directory);
  if TDirectory.Exists(Directory) or TFile.Exists(Directory) then raise EArgumentException.Create('Export destination must be new; existing files will not be overwritten');
  TDirectory.CreateDirectory(Directory); Lines:=TStringBuilder.Create; Page:=TStringBuilder.Create;
  ByFrom:=TObjectDictionary<string,TList<TJSONObject>>.Create([doOwnsValues]); Explanations:=TDPHExplanationModel.Create(AModel.Document);
  try
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
    Page.Append('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta http-equiv="Content-Security-Policy" content="default-src ''none''; script-src ''self''; style-src ''self''; img-src ''self'' data:; connect-src ''none''; object-src ''none''; base-uri ''none''; form-action ''none''"><title>Delphi Project Handoff reference</title><link rel="stylesheet" href="assets/style.css"></head><body><header><h1 class="notranslate" translate="no">'+TDPHDocumentModel.HTML(AModel.Document.GetValue<string>('project'))+'</h1><p class="status">Generation '+AModel.Document.GetValue('generation_id').Value+' | '+
      IfThen(AModel.Document.GetValue<Boolean>('analysis_complete'),'Captured analysis complete','PARTIAL analysis')+' | '+IfThen(AModel.Document.GetValue<Boolean>('detached'),'Detached source','Connected capture')+' | '+IfThen(AModel.Document.GetValue<Boolean>('stale'),'STALE evidence','Captured fingerprint')+'</p><p>Static evidence; runtime behavior unobserved. Human verification is recorded separately.</p></header><nav>');
    for V in AModel.Document.GetValue<TJSONArray>('sections') do begin R:=V as TJSONObject; Page.Append('<a href="#'+R.GetValue<string>('id')+'">'+TDPHDocumentModel.HTML(R.GetValue<string>('title'))+'</a>'); end;
    Page.Append('</nav><p><label>Search objects <input id="search" type="search" placeholder="Name, kind or signature"></label></p>');
    for V in AModel.Document.GetValue<TJSONArray>('screenshots') do begin R:=V as TJSONObject;
      Page.Append('<figure id="screenshot_'+R.GetValue<string>('artifact_hash','')+'"><img width="640" src="images/'+R.GetValue<string>('image')+'" alt="'+TDPHDocumentModel.HTML(R.GetValue<string>('caption'))+'"><figcaption>'+TDPHDocumentModel.HTML(R.GetValue<string>('caption'))+' | Contributor: '+TDPHDocumentModel.HTML(R.GetValue<string>('author'))+' | user supplied, unverified | generation '+R.GetValue('generation_id').Value+'</figcaption></figure>');
    end;
    for V in AModel.Document.GetValue<TJSONArray>('sections') do begin R:=V as TJSONObject; Page.Append('<section id="'+R.GetValue<string>('id')+'"><h2>'+TDPHDocumentModel.HTML(R.GetValue<string>('title'))+'</h2>');
      Page.Append('<p>Section '+TDPHDocumentModel.HTML(R.GetValue<string>('section_id'))+' | version <code class="notranslate" translate="no">'+
        TDPHDocumentModel.HTML(R.GetValue<string>('section_version'))+'</code> | source generation '+R.GetValue<string>('source_generation')+
        ' | '+TDPHDocumentModel.HTML(R.GetValue<string>('verification_state'))+' | last reviewed '+TDPHDocumentModel.HTML(R.GetValue<string>('last_reviewed'))+'</p>');
      for W in R.GetValue<TJSONArray>('paragraphs') do Page.Append('<p>'+TDPHDocumentModel.HTML(W.Value)+'</p>');
      for W in R.GetValue<TJSONArray>('knowledge_ids') do Page.Append('<p><a href="#knowledge_'+W.Value+'">Attributed knowledge '+W.Value+'</a></p>');
      Page.Append('</section>');
    end;
    for V in AModel.Document.GetValue<TJSONArray>('knowledge') do begin R:=V as TJSONObject;
      Page.Append('<section id="knowledge_'+R.GetValue<string>('id')+'"><h2>'+TDPHDocumentModel.HTML(R.GetValue<string>('title'))+'</h2><p>Section '+
        TDPHDocumentModel.HTML(R.GetValue<string>('section_id'))+' | revision '+R.GetValue<string>('revision')+' | source generation '+R.GetValue<string>('source_generation')+
        ' | '+TDPHDocumentModel.HTML(R.GetValue<string>('state'))+' | author '+TDPHDocumentModel.HTML(R.GetValue<string>('owner'))+
        ' | reviewer '+TDPHDocumentModel.HTML(IfThen(R.GetValue<string>('reviewer')='','unassigned',R.GetValue<string>('reviewer')))+
        ' | last reviewed '+TDPHDocumentModel.HTML(IfThen(R.GetValue<string>('reviewed_at')='','never',R.GetValue<string>('reviewed_at')))+
        '</p><p>'+TDPHDocumentModel.HTML(R.GetValue<string>('body'))+'</p>');
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
      Page.Append('</section>');
    end;
    IndexText:='';
    for V in AModel.Document.GetValue<TJSONArray>('symbols') do begin R:=V as TJSONObject; Anchor:='s_'+THashSHA2.GetHashString(R.GetValue<string>('key'));
      Path:='objects/'+THashSHA2.GetHashString(R.GetValue<string>('key'))+'.html';
      try Write(Path,Explanations.ObjectHTML(R.GetValue<string>('key')).Replace('href="#s_','href="../index.html#s_'));
      except on E: Exception do raise EReadError.Create('Object explanation '+R.GetValue<string>('name')+': '+E.ClassName+': '+E.Message); end;
      Page.Append('<p><a href="'+Path+'">Explain '+TDPHDocumentModel.HTML(R.GetValue<string>('name'))+' - role, callers, effects, execution trace and control flow</a></p>');
      Page.Append('<article id="'+Anchor+'" data-search="'+TDPHDocumentModel.HTML(LowerCase(R.GetValue<string>('name')+' '+R.GetValue<string>('kind')+' '+R.GetValue<string>('signature')))+'"><h2 class="notranslate" translate="no">'+TDPHDocumentModel.HTML(R.GetValue<string>('name'))+'</h2><p>'+TDPHDocumentModel.HTML(R.GetValue<string>('kind'))+'</p><pre class="notranslate" translate="no">'+TDPHDocumentModel.HTML(R.GetValue<string>('signature'))+'</pre><p class="notranslate" translate="no">'+TDPHDocumentModel.HTML(R.GetValue<string>('range.source'))+' line '+R.GetValue<Integer>('range.line').ToString+' | SHA256 '+R.GetValue<string>('source_hash')+'</p>');
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
    Write('validation/coverage.json',AModel.Document.GetValue<TJSONObject>('coverage').Format(2));
    Write('README.md','# '+AModel.Document.GetValue<string>('project')+' handoff'+#10+#10+
      '1. Open index.html offline and read Overview and Known unknowns.'+#10+
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
      Manifest.AddPair('project',AModel.Document.GetValue<string>('project')); Manifest.AddPair('captured_utc',AModel.Document.GetValue<string>('captured_utc'));
      Manifest.AddPair('audience',AModel.Document.GetValue<string>('audience'));
      Manifest.AddPair('source_revision',AModel.Document.GetValue<TJSONObject>('source_revision').Clone as TJSONValue);
      Manifest.AddPair('analyzers',AModel.Document.GetValue<TJSONObject>('analyzers').Clone as TJSONValue);
      Manifest.AddPair('configuration',AModel.Document.GetValue<TJSONObject>('analysis_configuration').Clone as TJSONValue);
      Manifest.AddPair('required_toolchain',AModel.Document.GetValue<TJSONObject>('required_toolchain').Clone as TJSONValue);
      Manifest.AddPair('included_sources',AModel.Document.GetValue<TJSONArray>('files').Clone as TJSONValue);
      Manifest.AddPair('excluded_sources',AModel.Document.GetValue<TJSONArray>('exclusions').Clone as TJSONValue);
      Manifest.AddPair('task_seeds',AModel.Document.GetValue<TJSONArray>('task_seeds').Clone as TJSONValue);
      Manifest.AddPair('portability_scope','relative local routes, indexes and copied managed images; no original source or absolute dependency roots');
      Manifest.AddPair('disclosure_limitations','Scoped redacted static evidence and attributed knowledge. Review explicit exclusions and remaining prose before sharing; redaction is not a confidentiality guarantee.');
      Manifest.AddPair('hash_index','validation/manifest-sha256.json'); Write('manifest.json',Manifest.Format(2));
    finally Manifest.Free; end;
    Hashes:=TJSONObject.Create;
    try Files:=TDirectory.GetFiles(Directory,'*',TSearchOption.soAllDirectories); TArray.Sort<string>(Files);
      for Path in Files do begin Relative:=ExtractRelativePath(IncludeTrailingPathDelimiter(Directory),Path).Replace('\','/'); Hashes.AddPair(Relative,THashSHA2.GetHashStringFromFile(Path)); end;
      Write('validation/manifest-sha256.json',Hashes.Format(2));
    finally Hashes.Free; end;
    Validate(Directory,AModel.Document.GetValue<string>('input_fingerprint'),False);
  finally Explanations.Free; ByFrom.Free; Page.Free; Lines.Free; end;
end;
class procedure TDPHPublisher.Validate(const ADirectory,AExpectedFingerprint: string; ARejectStale: Boolean);
var Hashes,Manifest,Canonical,Row,Referenced: TJSONObject; Pair: TJSONPair; Path,Root: string; Files: TArray<string>; V,W: TJSONValue; Generation: Int64;
    Sources,Symbols,Evidence,Flow: TDictionary<string,TJSONObject>; ArtifactCount: Integer;
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
    if Manifest.GetValue<string>('template_version')=DPHPublishVersion then begin
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
    if Canonical.GetValue<string>('template_version')=DPHPublishVersion then begin
      if TFile.ReadAllText(TPath.Combine(Root,'indexes/configuration.jsonl'),TEncoding.UTF8)<>Canonical.GetValue<TJSONObject>('analysis_configuration').ToJSON+#10 then
        raise EReadError.Create('Configuration index differs from canonical model');
      CheckJSONL('indexes/files.jsonl','files',[]);
    end else CheckJSONL('indexes/configuration.jsonl','files',[]);
    CheckJSONL('indexes/knowledge.jsonl','knowledge',[]);
    CheckJSONL('indexes/forms-events.jsonl','symbols',['component','event']);
    CheckJSONL('indexes/data-usage.jsonl','relationships',['reads','writes','renders','static_sql']);
  finally Flow.Free; Evidence.Free; Symbols.Free; Sources.Free; Canonical.Free; Manifest.Free; Hashes.Free; end;
end;
end.
