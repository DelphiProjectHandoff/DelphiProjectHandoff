unit DPH.Handoff.Dossier;

interface

uses System.JSON;

type
  TDPHHandoffDossier = class
  public
    class function Render(AFacts: TJSONObject; APage: Integer;
      AExport: Boolean = False): string; static;
  end;

implementation

uses System.SysUtils, System.Classes, System.StrUtils, System.Hash,
  System.Generics.Collections;

class function TDPHHandoffDossier.Render(AFacts: TJSONObject; APage: Integer;
  AExport: Boolean): string;
const
  Titles: array[0..3] of string =
    ('Handoff overview', 'Commands and workflows', 'Data and operations',
     'Risks and open questions');
var
  Body, HTML: TStringBuilder;
  Files, Symbols, Relations, Screens, Startup, Guides, Questions, Diagnostics,
    Knowledge, Properties, Sections, BuildPaths: TJSONArray;
  ByKey: TDictionary<string,TJSONObject>;
  DirectoryCounts: TDictionary<string,Integer>;
  Value, Other: TJSONValue;
  Row, Target, Control, Guide, Section, Profile, Fields: TJSONObject;
  Name, Caption, EventName, Key, Source, Purpose, PurposeEvidence, Status,
    Title, Kind, DirectoryName, GuideSource, CandidatePurpose: string;
  Count, Total, Index, PurposeScore, CandidateScore, BindingCount,
    OutputCount, DataCount, ContractCount: Integer;
  IncompleteAnalysis: Boolean;
  function Esc(const AText: string): string;
  begin
    Result:=AText.Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;')
      .Replace('"','&quot;').Replace('''','&#39;');
  end;
  function Cite(ARow: TJSONObject): string;
  var Range: TJSONObject;
  begin
    Result:='';
    if ARow=nil then Exit;
    Range:=ARow.GetValue<TJSONObject>('range',nil);
    if Range=nil then Exit;
    Source:=Range.GetValue<string>('source','');
    if Source='' then Exit;
    Result:='<small class="cite"><code>'+Esc(Source)+':'+
      IntToStr(Range.GetValue<Integer>('line',0))+'</code>';
    Result:=Result+'</small>';
  end;
  function ObjectLink(ARow: TJSONObject): string;
  var Hash: string;
  begin
    if ARow=nil then Exit('<span class="unknown">unresolved target</span>');
    Hash:=THashSHA2.GetHashString(ARow.GetValue<string>('key'));
    if AExport then Result:='<a href="objects/'+Hash+'.html">'+
      Esc(ARow.GetValue<string>('name'))+'</a>'
    else Result:='<a href="#s_'+Hash+'">'+
      Esc(ARow.GetValue<string>('name'))+'</a>';
  end;
begin
  if AFacts=nil then Exit('');
  if not (APage in [0..3]) then APage:=0;
  Files:=AFacts.GetValue<TJSONArray>('files',nil);
  Symbols:=AFacts.GetValue<TJSONArray>('symbols',nil);
  Relations:=AFacts.GetValue<TJSONArray>('relationships',nil);
  Screens:=AFacts.GetValue<TJSONArray>('project_screens',nil);
  Startup:=AFacts.GetValue<TJSONArray>('project_startup_forms',nil);
  Guides:=AFacts.GetValue<TJSONArray>('project_guides',nil);
  Questions:=AFacts.GetValue<TJSONArray>('author_questions',nil);
  Diagnostics:=AFacts.GetValue<TJSONArray>('diagnostics',nil);
  Knowledge:=AFacts.GetValue<TJSONArray>('knowledge',nil);
  BuildPaths:=AFacts.GetValue<TJSONArray>('project_build_paths',nil);
  ByKey:=TDictionary<string,TJSONObject>.Create;
  DirectoryCounts:=TDictionary<string,Integer>.Create;
  Body:=TStringBuilder.Create;
  HTML:=TStringBuilder.Create;
  try
    if Symbols<>nil then for Value in Symbols do begin
      Row:=Value as TJSONObject;
      Key:=Row.GetValue<string>('key','');
      if Key<>'' then ByKey.AddOrSetValue(Key,Row);
    end;
    IncompleteAnalysis:=not AFacts.GetValue<Boolean>('stale',False) and
      not AFacts.GetValue<Boolean>('analysis_complete',False);
    Status:='Source-derived, unreviewed';
    if AFacts.GetValue<Boolean>('stale',False) then Status:='STALE capture - refresh before relying on it'
    else if IncompleteAnalysis then Status:='Project analysis is incomplete';
    if AExport and (APage=0) then begin
      Body.Append('<section class="scope"><p><strong>'+Esc(Status)+'</strong> | '+
        Esc(AFacts.GetValue<string>('configuration','unknown configuration'))+' / '+
        Esc(AFacts.GetValue<string>('platform','unknown platform'))+' | captured '+
        Esc(AFacts.GetValue<string>('captured_utc','unknown time'))+
        '. Static inspection only; the selected application was not run.</p>');
      if IncompleteAnalysis then
        Body.Append('<p>DPH saved what it found, but some results may be missing. '+
          'In DPH, open Coverage, select a diagnostic, and choose '+
          '<strong>Inspect selected gap</strong> to see the affected source. '+
          'If the gap is caused by a missing file, path, or project setting, '+
          'correct it and choose <strong>Rescan project</strong>.</p>');
      Body.Append('</section>');
    end;
    case APage of
      0: begin
        Purpose:=''; PurposeEvidence:='';
        if Knowledge<>nil then for Value in Knowledge do begin
          Row:=Value as TJSONObject;
          if Row.GetValue<string>('state','')<>'verified' then Continue;
          Profile:=Row.GetValue<TJSONObject>('structured_record',nil);
          if (Profile=nil) or (Profile.GetValue<string>('record_type','')<>'project_profile') then Continue;
          Fields:=Profile.GetValue<TJSONObject>('fields',nil);
          if Fields=nil then Continue;
          Purpose:=Trim(Fields.GetValue<string>('purpose',''));
          if Purpose<>'' then begin
            PurposeEvidence:='<span>Reviewed contributor record</span> | '+
              Esc(Row.GetValue<string>('owner','unknown author'))+' | <span>revision</span> '+
              Esc(Row.GetValue<string>('revision','unknown'));
            Break;
          end;
        end;
        PurposeScore:=-1;
        if (Purpose='') and (Guides<>nil) then for Value in Guides do begin
          Guide:=Value as TJSONObject;
          GuideSource:=LowerCase(Guide.GetValue<string>('source','').Replace('\','/'));
          if StartsText('contracts/',GuideSource) or StartsText('tests/',GuideSource) or
            ContainsText(GuideSource,'/archive/') or
            ContainsText(GuideSource,'engineering_guide') or
            ContainsText(GuideSource,'validation') then Continue;
          CandidateScore:=0;
          if MatchText(GuideSource,['readme.md','readme.txt']) then CandidateScore:=100
          else if StartsText('docs/guides/',GuideSource) and
            (ContainsText(GuideSource,'user_guide') or
             ContainsText(GuideSource,'getting_started')) then CandidateScore:=70
          else if StartsText('docs/',GuideSource) then CandidateScore:=20;
          Sections:=Guide.GetValue<TJSONArray>('sections',nil);
          if Sections=nil then Continue;
          for Other in Sections do begin
            Section:=Other as TJSONObject;
            Title:=Section.GetValue<string>('heading','');
            CandidatePurpose:=Trim(Section.GetValue<string>('text',''));
            if CandidatePurpose='' then Continue;
            if ContainsText(Title,'purpose') or ContainsText(Title,'overview') or
              ContainsText(Title,'introduction') or ContainsText(Title,'about') then
              Inc(CandidateScore,10)
            else if CandidateScore<100 then Continue;
            if CandidateScore>PurposeScore then begin
              Purpose:=CandidatePurpose;
              PurposeScore:=CandidateScore;
              PurposeEvidence:='<span>Project document</span> '+
                '<code>'+Esc(Guide.GetValue<string>('source',''))+'</code> | '+
                '<span>author statement, not runtime verification</span>';
            end;
            Break;
          end;
        end;
        Body.Append('<section class="card"><h2>What this application is for</h2>');
        if Purpose<>'' then Body.Append('<p class="source-note">Project description from the selected source (shown in its original language).</p>'+
          '<pre dir="auto" class="project-prose">'+
          Esc(Copy(Purpose,1,1800))+'</pre><p><small>'+PurposeEvidence+'</small></p>')
        else Body.Append('<p class="unknown">Purpose is not established by the captured evidence. '+
          'Use the screens, commands and local guides below as leads; do not treat a filename as a business description.</p>');
        Body.Append('</section><section class="card"><h2>What the captured source shows</h2>');
        if (Startup<>nil) and (Startup.Count>0) then begin
          Row:=Startup.Items[0] as TJSONObject;
          Body.Append('<p><span>The project entry registers</span> <strong>'+Esc(
            Row.GetValue<string>('instance','the first form'))+'</strong> '+
            '(<code>'+Esc(Row.GetValue<string>('class',''))+'</code>) &mdash; '+
            '<code>'+Esc(Row.GetValue<string>('program',''))+':'+
            IntToStr(Row.GetValue<Integer>('line',0))+'</code>.</p>');
        end else Body.Append('<p>The initial form registration was not resolved in this capture.</p>');
        BindingCount:=0; OutputCount:=0; DataCount:=0;
        if Relations<>nil then for Value in Relations do begin
          Row:=Value as TJSONObject;
          Kind:=Row.GetValue<string>('kind','');
          if Kind='binds' then Inc(BindingCount)
          else if Kind='output_candidate' then Inc(OutputCount)
          else if MatchText(Kind,['static_sql','dynamic_sql','reads','writes']) then
            Inc(DataCount);
        end;
        Body.Append('<p><span>The saved source and forms expose</span> <strong>'+IntToStr(BindingCount)+
          '</strong> <span>event bindings,</span> <strong>'+IntToStr(OutputCount)+
          '</strong> <span>candidate output sites and</span> <strong>'+IntToStr(DataCount)+
          '</strong> <span>data-access relationships.</span></p>'+
          '<p>Follow the connected handlers, files and reports to see each path in detail. '+
          'These are static findings; they do not establish that a conversion or other '+
          'operation completed at runtime.</p>');
        Body.Append('<div class="metrics">');
        if Files<>nil then Body.Append('<span><strong>'+IntToStr(Files.Count)+'</strong> <em>captured files</em></span>');
        if Symbols<>nil then Body.Append('<span><strong>'+IntToStr(Symbols.Count)+'</strong> <em>objects</em></span>');
        if Relations<>nil then Body.Append('<span><strong>'+IntToStr(Relations.Count)+'</strong> <em>relationships</em></span>');
        if Screens<>nil then Body.Append('<span><strong>'+IntToStr(Screens.Count)+'</strong> <em>form designs</em></span>');
        Body.Append('</div><p>Counts describe this selected capture, not all possible build variants or runtime paths.</p></section>');
        Body.Append('<section class="card"><h2>Dependencies and build paths</h2>'+
          '<h3>Project directories and build paths</h3>');
        if Files<>nil then for Value in Files do begin
          Row:=Value as TJSONObject;
          DirectoryName:=Row.GetValue<string>('path','').Replace('\','/');
          Index:=LastDelimiter('/',DirectoryName);
          if Index=0 then DirectoryName:='.'
          else DirectoryName:=Copy(DirectoryName,1,Index);
          if DirectoryCounts.TryGetValue(DirectoryName,Count) then
            DirectoryCounts[DirectoryName]:=Count+1
          else DirectoryCounts.Add(DirectoryName,1);
        end;
        Count:=0;
        for DirectoryName in DirectoryCounts.Keys do begin
          Body.Append('<p><code>'+Esc(DirectoryName)+'</code> &mdash; '+
            '<strong>'+IntToStr(DirectoryCounts[DirectoryName])+'</strong> '+
            '<span>captured files</span></p>');
          Inc(Count); if Count>=40 then Break;
        end;
        if DirectoryCounts.Count>Count then Body.Append('<p>Further directories are available in the Project map.</p>');
        if BuildPaths<>nil then for Value in BuildPaths do begin
          Row:=Value as TJSONObject;
          Body.Append('<p><strong>'+Esc(Row.GetValue<string>('name',''))+'</strong>: <code>'+
            Esc(Row.GetValue<string>('value',''))+'</code> <small><code>'+
            Esc(Row.GetValue<string>('source',''))+':'+
            IntToStr(Row.GetValue<Integer>('line',0))+'</code></small></p>');
        end;
        Body.Append('<p>These are captured project properties for the selected build variant. Delphi IDE global Library and Browsing paths are not stored in the project and require confirmation on the maintainer machine. Unresolved units can indicate a missing library path, package, source root or conditional variant.</p>');
        Body.Append('<p>Third-party component packs require the exact vendor, version, license and install location. A class prefix alone cannot confirm a package.</p>');
        if not AExport then Body.Append('<p><a href="#open_dependencies">Inspect component dependencies</a></p>');
        Body.Append('</section><section class="card"><h2>Contracts and validation</h2>');
        ContractCount:=0;
        if Files<>nil then for Value in Files do begin
          Row:=Value as TJSONObject;
          Name:=Row.GetValue<string>('path','').Replace('\','/');
          if not (ContainsText(Name,'contract') or StartsText('tests/',Name)) then Continue;
          Inc(ContractCount);
          if ContractCount<=6 then Body.Append('<p><code>'+Esc(Name)+'</code></p>');
        end;
        if ContractCount=0 then Body.Append('<p>No contract or test file was identified in this capture. Check the project documentation and build scripts before claiming validation coverage.</p>')
        else Body.Append('<p><strong>'+IntToStr(ContractCount)+'</strong> '+
          '<span>contract or test files were identified in the captured file set.</span> '+
          '<span>Their presence does not show that they passed; review the current test results and the applicable build variant.</span></p>');
        Body.Append('</section>');
        Body.Append('<section class="card"><h2>Startup reading order</h2>');
        Count:=0;
        if Startup<>nil then for Value in Startup do begin
          Row:=Value as TJSONObject;
          Body.Append('<p><span class="badge">EXTRACTED</span> <strong>'+
            Esc(Row.GetValue<string>('instance','form'))+'</strong> <code>'+Esc(
            Row.GetValue<string>('class',''))+'</code> | <code>'+Esc(
            Row.GetValue<string>('program',''))+':'+IntToStr(Row.GetValue<Integer>('line',0))+
            '</code></p>');
          Inc(Count); if Count>=16 then Break;
        end;
        if Count=0 then Body.Append('<p class="unknown">A startup form was not resolved in this capture.</p>');
        Body.Append('<p>Registration order is a source fact; construction side effects and first visible window still require inspection.</p></section>');
        Body.Append('<section class="card"><h2>Form designs</h2>');
        Count:=0;
        if Screens<>nil then for Value in Screens do begin
          Row:=Value as TJSONObject;
          if AExport then Body.Append('<p><strong>'+Esc(Row.GetValue<string>('title',
            Row.GetValue<string>('name','form')) )+'</strong>')
          else Body.Append('<p><a href="#form_'+THashSHA2.GetHashString(Row.GetValue<string>('source',''))+
            '">'+Esc(Row.GetValue<string>('title',Row.GetValue<string>('name','form')))+
            '</a>');
          Body.Append(' <small><code>'+Esc(Row.GetValue<string>('source',''))+':'+
            IntToStr(Row.GetValue<Integer>('line',0))+'</code></small></p>');
          Inc(Count); if Count>=30 then Break;
        end;
        if Count=0 then Body.Append('<p>No readable .dfm or .fmx root was captured.</p>');
        if AExport then Body.Append('<p><a href="index.html">Browse the technical index</a></p></section>')
        else Body.Append('<p><a href="#open_screenshots">Inspect generated form previews</a> | '+
          '<a href="#all_objects">Browse all captured objects</a></p></section>');
        Body.Append('<section class="card"><h2>Suggested reading tour</h2><ol>'+
          '<li>Read the project entry and its CreateForm sequence.</li>'+
          '<li>Inspect the first registered form and its command bindings.</li>'+
          '<li>Follow each handler to code, data and output candidates.</li>'+
          '<li>Review source gaps and ask the questions that files cannot answer.</li>'+
          '</ol><p><span class="badge inferred">GUIDE</span> This order is a reading aid, not an observed workflow.</p></section>');
      end;
      1: begin
        Body.Append('<section class="card"><h2>Visible commands and connected handlers</h2>'+
          '<p>Each row begins at a serialized form event. A confirmed binding identifies a declared handler; it does not prove the control is reachable or the handler runs.</p>');
        Count:=0; Total:=0;
        if Relations<>nil then for Value in Relations do begin
          Row:=Value as TJSONObject;
          if Row.GetValue<string>('kind','')<>'binds' then Continue;
          ByKey.TryGetValue(Row.GetValue<string>('from',''),Control);
          ByKey.TryGetValue(Row.GetValue<string>('to',''),Target);
          Name:=''; if Control<>nil then Name:=Control.GetValue<string>('name','');
          Index:=LastDelimiter('.',Name);
          if Index=0 then Continue;
          EventName:=Copy(Name,Index+1,MaxInt);
          if not MatchText(EventName,['OnClick','OnExecute','OnDblClick','OnTap']) then Continue;
          Inc(Total); if Count>=50 then Continue;
          Control:=nil;
          if Symbols<>nil then for Other in Symbols do begin
            Fields:=Other as TJSONObject;
            if not SameText(Fields.GetValue<string>('name',''),Copy(Name,1,Index-1)) then Continue;
            if not SameText(Fields.GetValue<string>('range.source',''),
              Row.GetValue<string>('range.source','')) then Continue;
            Control:=Fields;
            Break;
          end;
          Caption:='';
          if Control<>nil then begin
            Properties:=Control.GetValue<TJSONArray>('serialized_properties',nil);
            if Properties<>nil then for Other in Properties do
              if MatchText(Other.GetValue<string>('name',''),['Text','Caption']) then begin
                Caption:=Other.GetValue<string>('value',''); Break;
              end;
          end;
          if Caption='' then Caption:=Name;
          if Caption='' then Caption:='Unnamed control';
          Body.Append('<article class="item"><h3>'+Esc(Caption)+'</h3><p><span class="badge">'+
            Esc(Row.GetValue<string>('resolution','unresolved'))+'</span> '+Esc(EventName)+
            ' -> '+ObjectLink(Target)+'</p>'+Cite(Row)+'</article>');
          Inc(Count);
        end;
        if Total=0 then Body.Append('<p class="unknown">No form event binding was captured. This does not prove the application has no commands.</p>');
        if Total>Count then Body.Append('<p><strong>'+IntToStr(Total-Count)+'</strong> '+
          '<span>more bindings are available in the Project map.</span></p>');
        if AExport then Body.Append('<p><a href="index.html">Browse captured objects</a></p></section>')
        else Body.Append('<p><a href="#open_commands">Inspect full menus, actions and shortcuts</a> | '+
          '<a href="#all_objects">Open the Project map</a></p></section>');
      end;
      2: begin
        Body.Append('<section class="card"><h2>Data and output evidence</h2>'+
          '<p>These are source relationships, not a live database inventory or a record of files actually written.</p>');
        Count:=0; Total:=0;
        if Relations<>nil then for Value in Relations do begin
          Row:=Value as TJSONObject;
          Kind:=Row.GetValue<string>('kind','');
          if not MatchText(Kind,['static_sql','dynamic_sql','output_candidate','reads','writes']) then Continue;
          Inc(Total); if Count>=70 then Continue;
          ByKey.TryGetValue(Row.GetValue<string>('from',''),Control);
          ByKey.TryGetValue(Row.GetValue<string>('to',''),Target);
          Body.Append('<article class="item"><p><span class="badge inferred">'+Esc(Kind.Replace('_',' '))+
            '</span> '+ObjectLink(Control)+' -> '+ObjectLink(Target)+'</p>'+Cite(Row)+'</article>');
          Inc(Count);
        end;
        if Total=0 then Body.Append('<p class="unknown">No supported data or output relationship was captured. Dynamic code and missing inputs may hide additional behavior.</p>');
        if Total>Count then Body.Append('<p><strong>'+IntToStr(Total-Count)+'</strong> '+
          '<span>further relationships are available in the Project map.</span></p>');
        if AExport then Body.Append('<p><a href="index.html">Browse data relationships</a></p></section>')
        else Body.Append('<p><a href="#open_data">Inspect database evidence</a> | '+
          '<a href="#open_files">Inspect file-format candidates</a></p></section>');
        Body.Append('<section class="card"><h2>Database connections and bindings</h2><p>Database connections inventories captured FireDAC, InterBase/IBX, ADO and other recognized connection, dataset, data source and binding components. A declared driver family does not prove a successful connection. Review each source citation and missing definition before configuring an environment.</p>');
        if not AExport then Body.Append('<p><a href="#open_data">Inspect database connections</a> | <a href="#open_schema">Inspect captured database schema</a></p>');
        Body.Append('<p>Starting templates for a maintainer to complete outside source control:</p>'+
          '<pre>FireDAC / InterBase: DriverID=IB; Database=&lt;server:path&gt;; User_Name=&lt;user&gt;; Password=&lt;local secret&gt;'+#10+
          'FireDAC / SQL Server: DriverID=MSSQL; Server=&lt;host or instance&gt;; Database=&lt;name&gt;; OSAuthent=&lt;Yes/No&gt;'+#10+
          'FireDAC / SQLite: DriverID=SQLite; Database=&lt;absolute database path&gt;</pre>'+
          '<p>Confirm the required FireDAC driver unit and client library on the target machine, along with actual server, authentication, file path and deployment policy. Do not copy production credentials into the capture.</p></section>');
        Body.Append('<section class="card"><h2>Unit-level variables</h2>');
        Count:=0;
        if Symbols<>nil then for Value in Symbols do begin
          Row:=Value as TJSONObject;
          if Row.GetValue<string>('kind','')<>'variable' then Continue;
          Body.Append('<p>'+ObjectLink(Row)+' <code>'+Esc(Row.GetValue<string>('type',''))+
            '</code> '+Cite(Row)+'</p>');
          Inc(Count); if Count>=30 then Break;
        end;
        if Count=0 then Body.Append('<p>No unit-level variable declaration was captured in this selection.</p>');
        Body.Append('<p>Declaration does not establish initialization order, sharing, mutation or runtime value. Follow source and relationships for each relevant variable.</p></section>');
        Body.Append('<section class="card"><h2>Operational limits</h2><p>Build instructions, '+
          'live connection settings, permissions, scheduled jobs and deployment steps are unknown '+
          'unless a specific source or reviewed document establishes them. Do not open production '+
          'connections on the strength of this static capture.</p></section>');
      end;
      3: begin
        Body.Append('<section class="card"><h2>Questions to resolve</h2>');
        Count:=0;
        if Questions<>nil then for Value in Questions do begin
          Row:=Value as TJSONObject;
          Body.Append('<article class="item"><h3>'+Esc(Row.GetValue<string>('title','Question'))+
            '</h3><p>'+Esc(Row.GetValue<string>('prompt',''))+'</p>'+Cite(Row)+'</article>');
          Inc(Count); if Count>=30 then Break;
        end;
        if Count=0 then Body.Append('<p>No evidence-derived question was recorded in this selection. '+
          'This is not proof that the handoff is complete.</p>');
        if AExport then Body.Append('<p><a href="learning.html#lesson_3">Read saved author questions</a></p></section>')
        else Body.Append('<p><a href="#ask_author">Open the full question list</a></p></section>');
        Body.Append('<section class="card"><h2>Analysis gaps and risk candidates</h2>');
        Count:=0;
        if Diagnostics<>nil then for Value in Diagnostics do begin
          Row:=Value as TJSONObject;
          Body.Append('<article class="item"><strong>'+Esc(Row.GetValue<string>('code','Diagnostic'))+
            '</strong><p>'+Esc(Row.GetValue<string>('message',''))+'</p>'+Cite(Row)+'</article>');
          Inc(Count); if Count>=25 then Break;
        end;
        if Count=0 then Body.Append('<p>No diagnostic is listed in this export scope. '+
          'Unsupported dynamic behavior remains possible.</p>');
        if AExport then Body.Append('<p><a href="validation/coverage.json">Inspect capture coverage</a></p></section>')
        else Body.Append('<p><a href="#open_quality">Inspect source-quality candidates</a> | '+
          '<a href="#open_coverage">Check capture coverage</a></p></section>');
        Body.Append('<section class="card"><h2>Unknown without people or observation</h2>'+
          '<ul><li>Why a business rule exists and which workflow is still used.</li>'+
          '<li>Whether candidate dead code is actually unreachable.</li>'+
          '<li>Which external systems and data are authoritative today.</li>'+
          '<li>Known tolerated defects, customer exceptions and the roadmap.</li>'+
          '<li>Production access, legal obligations and safe deployment procedure.</li></ul>'+
          '<p>Record answers with a contributor, exact evidence and review state. '+
          'An inference must never be promoted to fact because it sounds plausible.</p></section>');
      end;
    end;
    HTML.Append('<!doctype html><html lang="en"><head><meta charset="utf-8">'+
      '<meta name="viewport" content="width=device-width,initial-scale=1">'+
      '<meta http-equiv="Content-Security-Policy" content="default-src ''none''; '+
      'style-src ''unsafe-inline''; img-src data:; script-src ''none''; connect-src ''none''">'+
      '<title>'+Esc(Titles[APage])+'</title>'+
      '<style>*{box-sizing:border-box}body{margin:0;background:#f1f5fa;color:#19364e;'+
      'font:16px/1.55 Segoe UI,Arial,sans-serif;overflow-wrap:break-word;word-break:normal;hyphens:none}'+
      'header{background:#146cb4;color:#fff;border-bottom:5px solid #f28c28;padding:22px 30px}'+
      'header h1{margin:0;font-size:27px}header p{margin:5px 0 0}'+
      'main{max-width:1120px;margin:auto;padding:16px 24px 40px}.scope,.card{background:#fff;'+
      'border:1px solid #dce5ef;border-radius:9px;padding:18px 22px;margin:14px 0}'+
      '.scope{border-left:5px solid #f28c28}.card h2{color:#146cb4;margin:0 0 12px;font-size:21px}'+
      '.card h3{font-size:17px;margin:0 0 6px}.item{padding:13px 0;border-top:1px solid #e4ebf1}'+
      '.item:first-of-type{border-top:0}.metrics{display:flex;gap:12px;flex-wrap:wrap}'+
      '.metrics span{background:#eaf3fc;border-radius:6px;padding:10px 16px}.metrics strong{font-size:22px}'+
      '.badge{font-size:11px;font-weight:700;color:#125a92;background:#e8f2fb;padding:3px 7px;'+
      'border-radius:4px;text-transform:uppercase}.inferred{color:#945000;background:#fff1df}'+
      '.cite{display:block;color:#597087}.card pre{white-space:pre-wrap;overflow-wrap:anywhere}pre.project-prose{font:inherit;white-space:pre-wrap;overflow-wrap:break-word;word-break:normal;hyphens:none}'+
      '.unknown{color:#865500}'+
      'a{color:#146cb4}code{direction:ltr;unicode-bidi:isolate;overflow-wrap:anywhere}'+
      'nav{display:flex;gap:12px;flex-wrap:wrap;margin-top:16px}nav a{color:#fff}'+
      '@media print{body{background:#fff}.card{break-inside:avoid}}</style></head><body>'+
      '<header><h1>'+Esc(Titles[APage])+'</h1><p><code>'+Esc(AFacts.GetValue<string>('project',''))+
      '</code></p><nav>');
    for Index:=0 to 3 do begin
      if AExport then HTML.Append('<a href="handoff-'+IntToStr(Index)+'.html">')
      else HTML.Append('<a href="#lesson_'+IntToStr(Index)+'">');
      HTML.Append(Esc(Titles[Index])+'</a>');
    end;
    HTML.Append('</nav></header><main>'+Body.ToString+'</main></body></html>');
    Result:=HTML.ToString;
  finally
    HTML.Free; Body.Free; ByKey.Free; DirectoryCounts.Free;
  end;
end;

end.
