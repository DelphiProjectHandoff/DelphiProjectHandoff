program DPHLayoutTests;
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.UITypes,
  Winapi.Windows, Winapi.MultiMon, FMX.Types, FMX.Forms, FMX.Platform.Win,
  DPH.UI.Main in '..\DPH.UI.Main.pas';
var
  Form: TDPHMainForm;
  WindowBounds: Winapi.Windows.TRect;
  MonitorInfo: TMonitorInfo;
  Width: Integer;
procedure Check(Condition: Boolean; const MessageText: string);
begin
  if not Condition then raise Exception.Create(MessageText);
  Writeln('PASS: '+MessageText);
end;
procedure Settle;
var I: Integer;
begin
  for I:=1 to 20 do begin Application.ProcessMessages; Sleep(10); end;
end;
begin
  Application.Initialize;
  Form:=TDPHMainForm.Create(nil);
  try
    Form.PollTimer.Enabled:=False; Form.ChangeTimer.Enabled:=False;
    Form.Show; Settle;
    Check(IsZoomed(FormToHWND(Form)),'Application opens maximized');
    GetWindowRect(FormToHWND(Form),WindowBounds);
    MonitorInfo.cbSize:=SizeOf(MonitorInfo);
    if not GetMonitorInfo(MonitorFromWindow(FormToHWND(Form),MONITOR_DEFAULTTONEAREST),@MonitorInfo) then RaiseLastOSError;
    // Windows extends the invisible resize border beyond a maximized work area.
    Check((WindowBounds.Left>=MonitorInfo.rcWork.Left-16) and
      (WindowBounds.Right<=MonitorInfo.rcWork.Right+16),'Maximized window fits the monitor work area');
    Check(Trim(Form.InspectorTitle.Text)<>'','Right pane has a visible purpose heading');
    Check(Form.InspectorMemo.WordWrap,'Details text wraps inside the pane');
    Form.HelpBrowser.Visible:=False;
    Form.HelpFallback.Visible:=True;
    Form.InspectorMemo.Text:='Example selection for layout verification'+sLineBreak+sLineBreak+
      'Signature: procedure ExampleWithALongSignature(const SourcePath: string; const TargetPath: string; const ConfigurationName: string);'+sLineBreak+sLineBreak+
      'Source: very-long-folder-name\another-long-folder-name\UnitWithALongName.pas:123'+sLineBreak+sLineBreak+
      'Evidence SHA256: 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
    Form.WorkspaceTabs.ActiveTab:=Form.GraphTab;
    Form.WindowState:=TWindowState.wsNormal;
    for Width in [1400,1600] do
    begin
      Form.ClientWidth:=Width; Form.ClientHeight:=720; Settle;
      Check((Form.InspectorLayout.AbsoluteRect.Right<=Form.ClientWidth+1) and
        (Form.InspectorMemo.AbsoluteRect.Right<=Form.ClientWidth+1),
        'Right pane stays inside a '+Width.ToString+' pixel client width');
      Check(Form.WorkspaceTabs.Width>=300,'Central workspace retains usable width at '+Width.ToString);
      Check(Form.InspectorMemo.ContentBounds.Width<=Form.InspectorMemo.Width+1,
        'Long signature and source path stay wrapped at '+Width.ToString);
      Check(not Form.GraphPurpose.Visible and not Form.GraphLegend.Visible,
        'Diagram guidance stays in the rendered page at '+Width.ToString);
      Check(Form.GraphToolbar.AbsoluteRect.Bottom<=Form.GraphScroll.AbsoluteRect.Top+1,
        'Diagram controls do not overlap the diagram at '+Width.ToString);
    end;
  finally Form.Free; end;
end.
