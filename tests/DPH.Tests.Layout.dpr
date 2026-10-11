program DPHLayoutTests;
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Types, System.IOUtils, System.UITypes,
  Winapi.Windows, Winapi.MultiMon, FMX.Types, FMX.Forms, FMX.Graphics, FMX.Platform.Win,
  DPH.UI.Main in '..\DPH.UI.Main.pas';
var
  Form: TDPHMainForm;
  WindowBounds: Winapi.Windows.TRect;
  MonitorInfo: TMonitorInfo;
  Width: Integer;
  Bitmap: TBitmap;
  OutputDirectory: string;
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
  OutputDirectory:=TPath.Combine(ParamStr(1),'docs');
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
    Check(Form.InspectorTitle.Text='Selection details','Right pane has a visible purpose heading');
    Check(Form.InspectorMemo.WordWrap,'Details text wraps inside the pane');
    Form.HelpBrowser.Visible:=False;
    Form.HelpFallback.Visible:=True;
    Form.InspectorMemo.Text:='Example selection for layout verification'+sLineBreak+sLineBreak+
      'Signature: procedure ExampleWithALongSignature(const SourcePath: string; const TargetPath: string; const ConfigurationName: string);'+sLineBreak+sLineBreak+
      'Source: very-long-folder-name\another-long-folder-name\UnitWithALongName.pas:123'+sLineBreak+sLineBreak+
      'Evidence SHA256: 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
    Form.WindowState:=TWindowState.wsNormal;
    for Width in [960,1200,1400] do
    begin
      Form.ClientWidth:=Width; Form.ClientHeight:=720; Settle;
      Check((Form.InspectorLayout.AbsoluteRect.Right<=Form.ClientWidth+1) and
        (Form.InspectorMemo.AbsoluteRect.Right<=Form.ClientWidth+1),
        'Right pane stays inside a '+Width.ToString+' pixel client width');
      Check(Form.WorkspaceTabs.Width>=300,'Central workspace retains usable width at '+Width.ToString);
      Check(Form.InspectorMemo.ContentBounds.Width<=Form.InspectorMemo.Width+1,
        'Long signature and source path stay wrapped at '+Width.ToString);
      Form.CommandScroll.ViewportPosition:=PointF(10000,0); Settle;
      Check(Form.ExternalRootsEdit.AbsoluteRect.Right<=Form.CommandScroll.AbsoluteRect.Right+2,
        'Rightmost command remains reachable by scrolling at '+Width.ToString);
      Bitmap:=TBitmap.Create(Round(Form.ClientWidth),Round(Form.ClientHeight));
      try
        if Bitmap.Canvas.BeginScene then
        try Form.PaintTo(Bitmap.Canvas); finally Bitmap.Canvas.EndScene; end;
        Bitmap.SaveToFile(TPath.Combine(OutputDirectory,'ui-layout-'+Width.ToString+'.png'));
      finally Bitmap.Free; end;
    end;
  finally Form.Free; end;
end.
