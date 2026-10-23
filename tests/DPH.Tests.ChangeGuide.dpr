program DPH.Tests.ChangeGuide;
{$APPTYPE CONSOLE}
uses System.SysUtils, System.JSON, System.StrUtils, DPH.Analysis.Explanations in '..\DPH.Analysis.Explanations.pas';
var
  Facts,Symbol,Relation: TJSONObject;
  Symbols,Relations,Knowledge: TJSONArray;
  Model: TDPHExplanationModel;
  HTML: string;
begin
  Facts:=TJSONObject.Create;
  try
    Facts.AddPair('project','Example project');
    Facts.AddPair('stale',TJSONBool.Create(False));
    Facts.AddPair('analysis_complete',TJSONBool.Create(True));
    Facts.AddPair('files',TJSONArray.Create);
    Symbols:=TJSONArray.Create; Facts.AddPair('symbols',Symbols);
    Symbol:=TJSONObject.Create.AddPair('key','unit').AddPair('name','MainForm')
      .AddPair('kind','unit').AddPair('source_hash',StringOfChar('c',64))
      .AddPair('range',TJSONObject.Create.AddPair('source','MainForm.pas').AddPair('line',TJSONNumber.Create(1)));
    Symbols.AddElement(Symbol);
    Symbol:=TJSONObject.Create.AddPair('key','button').AddPair('name','Convert <script>')
      .AddPair('kind','component').AddPair('source_hash',StringOfChar('a',64))
      .AddPair('range',TJSONObject.Create.AddPair('source','MainForm.fmx').AddPair('line',TJSONNumber.Create(12)));
    Symbols.AddElement(Symbol);
    Symbol:=TJSONObject.Create.AddPair('key','handler').AddPair('name','ConvertClick')
      .AddPair('kind','routine').AddPair('source_hash',StringOfChar('b',64))
      .AddPair('range',TJSONObject.Create.AddPair('source','MainForm.pas').AddPair('line',TJSONNumber.Create(34)));
    Symbols.AddElement(Symbol);
    Relations:=TJSONArray.Create; Facts.AddPair('relationships',Relations);
    Relation:=TJSONObject.Create.AddPair('from','button').AddPair('to','handler')
      .AddPair('kind','binds').AddPair('resolution','confirmed_static')
      .AddPair('rule','serialized_event_binding').AddPair('source_hash',StringOfChar('a',64))
      .AddPair('range',TJSONObject.Create.AddPair('source','MainForm.fmx').AddPair('line',TJSONNumber.Create(15)));
    Relations.AddElement(Relation);
    Facts.AddPair('flow_nodes',TJSONArray.Create);
    Facts.AddPair('flow_edges',TJSONArray.Create);
    Knowledge:=TJSONArray.Create; Facts.AddPair('knowledge',Knowledge);
    Knowledge.AddElement(TJSONObject.Create.AddPair('entity_key','button')
      .AddPair('title','Reviewed usage').AddPair('state','verified')
      .AddPair('owner','Sample contributor').AddPair('body','Confirmed by sample test')
      .AddPair('links',TJSONArray.Create));
    Model:=TDPHExplanationModel.Create(Facts);
    try
      HTML:=Model.ChangeGuideHTML('button');
      if not ContainsText(HTML,'MainForm.fmx:12') or not ContainsText(HTML,'MainForm.pas') or
        not ContainsText(HTML,'confirmed_static') then
        raise Exception.Create('Change Guide lost a source citation or confirmed relationship');
      if ContainsText(HTML,'Convert <script>') or not ContainsText(HTML,'Convert &lt;script&gt;') then
        raise Exception.Create('Change Guide did not escape an untrusted source name');
      if not ContainsText(HTML,'not a measured execution sequence') or
        not ContainsText(HTML,'DPH has not run the target application') then
        raise Exception.Create('Change Guide failed to qualify static evidence');
      if not ContainsText(HTML,'Exercise the visible action') or
        ContainsText(HTML,'review affected queries') then
        raise Exception.Create('Change Guide suggested a check unsupported by the captured route');
      if not ContainsText(HTML,'Reviewed usage') or not ContainsText(HTML,'Open Knowledge records') then
        raise Exception.Create('Change Guide omitted linked contributor guidance');
      if not ContainsText(HTML,'AT A GLANCE') or
        not ContainsText(HTML,'<strong>1</strong> nearby objects') or
        not ContainsText(HTML,'<strong>2</strong> source files') or
        not ContainsText(HTML,'Event connects to') or
        not ContainsText(HTML,'Found in captured source') or
        not ContainsText(HTML,'<summary>General checks for any change</summary>') or
        not ContainsText(HTML,'Choose another object') then
        raise Exception.Create('Change Guide summary, plain labels, checks or navigation are missing');
      HTML:=Model.ChangeGuideHTML('handler');
      if not ContainsText(HTML,'Bound from') or
        not ContainsText(HTML,'<strong>1</strong> incoming connections') then
        raise Exception.Create('Change Guide incoming relationship is unclear');
      HTML:=Model.ChangeGuideHTML('button');
      if not ContainsText(HTML,'Use this guide to:') or
        not ContainsText(HTML,'Where this object is used') or
        not ContainsText(HTML,'DIRECT CONNECTION') or
        not ContainsText(HTML,'Change Guide - Convert &lt;script&gt;') or
        ContainsText(HTML,'â€”') then
        raise Exception.Create('Change Guide framing or title is incorrect');
      HTML:=Model.ChangeGuideHTML('absent');
      if not ContainsText(HTML,'Selection unavailable') then
        raise Exception.Create('Change Guide invented a route for an absent object');
      HTML:=Model.ChangeGuideHTML('');
      if not ContainsText(HTML,'Start with a specific project object') or
        not ContainsText(HTML,'Try this first:') or
        not ContainsText(HTML,'ConvertClick') then
        raise Exception.Create('Change Guide introduction is missing');
      HTML:=Model.ChangeGuideHTML('unit');
      if not ContainsText(HTML,'Broad selection:') or
        not ContainsText(HTML,'No supported connections were captured') then
        raise Exception.Create('Change Guide did not flag a broad unit selection');
      HTML:=Model.ProjectMapHTML;
      if not ContainsText(HTML,'Planning a code change?') or
        not ContainsText(HTML,'<strong>Change Guide</strong>') or
        not ContainsText(HTML,'ConvertClick') then
        raise Exception.Create('Project map did not introduce the Change Guide');
      Writeln('PASS: Change Guide introduction, evidence, escaping, limitations and missing-target behavior');
    finally Model.Free; end;
  finally Facts.Free; end;
end.
