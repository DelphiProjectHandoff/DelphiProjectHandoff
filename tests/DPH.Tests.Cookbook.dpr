program DPH.Tests.Cookbook;
{$APPTYPE CONSOLE}
uses System.SysUtils, System.JSON, System.StrUtils, DPH.Analysis.Explanations in '..\DPH.Analysis.Explanations.pas';
var
  Facts,Symbol,Relation: TJSONObject;
  Symbols,Relations: TJSONArray;
  Model: TDPHExplanationModel;
  HTML: string;
begin
  Facts:=TJSONObject.Create;
  try
    Facts.AddPair('project','Example project');
    Facts.AddPair('stale',TJSONBool.Create(False));
    Facts.AddPair('analysis_complete',TJSONBool.Create(True));
    Symbols:=TJSONArray.Create; Facts.AddPair('symbols',Symbols);
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
    Model:=TDPHExplanationModel.Create(Facts);
    try
      HTML:=Model.CookbookHTML('button');
      if not ContainsText(HTML,'MainForm.fmx:12') or not ContainsText(HTML,'MainForm.pas') or
        not ContainsText(HTML,'confirmed_static') then
        raise Exception.Create('Cookbook lost a source citation or confirmed relationship');
      if ContainsText(HTML,'Convert <script>') or not ContainsText(HTML,'Convert &lt;script&gt;') then
        raise Exception.Create('Cookbook did not escape an untrusted source name');
      if not ContainsText(HTML,'not a measured execution sequence') or
        not ContainsText(HTML,'DPH has not run the target application') then
        raise Exception.Create('Cookbook failed to qualify static evidence');
      if not ContainsText(HTML,'Exercise the visible action') or
        ContainsText(HTML,'review affected queries') then
        raise Exception.Create('Cookbook suggested a check unsupported by the captured route');
      HTML:=Model.CookbookHTML('absent');
      if not ContainsText(HTML,'Selection unavailable') then
        raise Exception.Create('Cookbook invented a route for an absent object');
      Writeln('PASS: cookbook evidence, escaping, limitations and missing-target behavior');
    finally Model.Free; end;
  finally Facts.Free; end;
end.
