program DPHPreviewTests;
{$APPTYPE CONSOLE}
uses System.SysUtils, System.Classes, System.IOUtils, System.Diagnostics, System.StrUtils,
  FMX.Forms, FMX.WebBrowser, DPH.UI.Main in '..\DPH.UI.Main.pas';
var Form: TDPHMainForm; Done: Boolean; ResultText: string; Timer,Attempt: TStopwatch;
begin
  Application.Initialize; Form:=TDPHMainForm.Create(nil);
  try
    Form.PollTimer.Enabled:=False; Form.ChangeTimer.Enabled:=False;
    Form.WorkspaceTabs.ActiveTab:=Form.PublishTab; Form.Show; Application.ProcessMessages;
    Form.PublishBrowser.OnShouldLoadURL:=nil;
    Form.PublishBrowser.WindowsEngine:=TWindowsEngine.EdgeOnly; Form.PublishBrowser.Visible:=True;
    Form.PublishBrowser.Navigate('file://'+TPath.Combine(ParamStr(1),'index.html'));
    Timer:=TStopwatch.StartNew;
    repeat
      Done:=False;
      Form.PublishBrowser.EvaluateJavaScript('document.getElementById("search") ? "READY" : "WAIT"',TJavaScriptResultCallback(procedure(const Value: string) begin ResultText:=Value; Done:=True; end));
      Attempt:=TStopwatch.StartNew;
      while not Done and (Attempt.ElapsedMilliseconds<250) do begin Application.ProcessMessages; TThread.Sleep(10); end;
      if ContainsText(ResultText,'READY') then Break;
      Application.ProcessMessages; TThread.Sleep(50);
    until Timer.ElapsedMilliseconds>20000;
    if not ContainsText(ResultText,'READY') then raise Exception.Create('Preview unavailable: '+ResultText);
    Writeln('PASS actual FMX WebView2 local page and JavaScript');
  finally Form.Free; end;
end.
