from pathlib import Path
import subprocess
root=Path(__file__).resolve().parents[2];out=root/'bin/learning-guides';out.mkdir(exist_ok=True)
program=r'''program DPH.CaptureGuide;
{$APPTYPE CONSOLE}
uses System.SysUtils,System.Classes,System.Types,System.IOUtils,System.Diagnostics,System.UITypes,System.Math.Vectors,
 Winapi.ActiveX,FMX.Forms,FMX.Graphics,FMX.WebBrowser,DPH.UI.Main in '..\..\DPH.UI.Main.pas';
var Form:TDPHMainForm;Bitmap,Browser:TBitmap;Watch:TStopwatch;Done:Boolean;JS:string;
begin
 CoInitialize(nil);Application.Initialize;
 try Form:=TDPHMainForm.Create(nil);
 try Form.PollTimer.Enabled:=False;Form.ChangeTimer.Enabled:=False;Form.Show;
  Form.WindowState:=TWindowState.wsNormal;Form.ClientWidth:=960;Form.ClientHeight:=650;Application.ProcessMessages;Form.HelpClick(nil);
  Watch:=TStopwatch.StartNew;JS:='';
  repeat Done:=False;Form.HelpBrowser.EvaluateJavaScript('document.body.innerText',TJavaScriptResultCallback(procedure(const Value:string) begin JS:=Value;Done:=True;end));
   while not Done and (Watch.ElapsedMilliseconds<10000) do begin Application.ProcessMessages;TThread.Sleep(10);end;
   Application.ProcessMessages;TThread.Sleep(30);
  until JS.Contains('Your first ten minutes') or (Watch.ElapsedMilliseconds>10000);
  if not JS.Contains('Your first ten minutes') then raise Exception.Create('Getting started did not render');
  Browser:=Form.HelpBrowser.CaptureBitmap;Bitmap:=TBitmap.Create(Form.ClientWidth,Form.ClientHeight);
  try if Bitmap.Canvas.BeginScene then try Form.PaintTo(Bitmap.Canvas);Bitmap.Canvas.DrawBitmap(Browser,TRectF.Create(0,0,Browser.Width,Browser.Height),Form.HelpBrowser.AbsoluteRect,1);finally Bitmap.Canvas.EndScene;end;
   Browser.SaveToFile(TPath.Combine(ParamStr(1),'docs\learning-guides-getting-started.png'));
  finally Bitmap.Free;Browser.Free;end;
  Form.SetupClick(nil);Application.ProcessMessages;
  Bitmap:=TBitmap.Create(Form.ClientWidth,Form.ClientHeight);try if Bitmap.Canvas.BeginScene then try Form.PaintTo(Bitmap.Canvas);finally Bitmap.Canvas.EndScene;end;Bitmap.SaveToFile(TPath.Combine(ParamStr(1),'docs\learning-guides-prepare-lessons.png'));finally Bitmap.Free;end;
  Form.Hide;
 finally Form.Free;end;
 finally CoUninitialize;end;
end.'''
(out/'DPH.CaptureGuide.dpr').write_text(program,encoding='utf-8-sig')
script='\n'.join(['@echo off','call "C:\\Program Files (x86)\\Embarcadero\\Studio\\37.0\\bin\\rsvars.bat"','dcc32 -B -Q -U"%BDS%\\lib\\Win32\\release;.;dependencies\\DelphiAppTranslation" -NSSystem;FMX;Data;Xml;Winapi -N0dcu\\Win32\\Debug -Ebin\\Win32\\Debug bin\\learning-guides\\DPH.CaptureGuide.dpr','if errorlevel 1 exit /b 1','bin\\Win32\\Debug\\DPH.CaptureGuide.exe "%CD%"','exit /b %errorlevel%'])
(out/'capture.cmd').write_text(script,encoding='ascii')
prefs=Path.home()/'AppData/Local/DPH/workspace.json';old=prefs.read_bytes() if prefs.exists() else None
try:
 prefs.parent.mkdir(parents=True,exist_ok=True);prefs.write_text('{"catalog_version":1,"database":"","projects":[]}',encoding='utf-8')
 result=subprocess.run(['cmd','/d','/c','bin\\learning-guides\\capture.cmd'],cwd=root,capture_output=True,text=True,errors='replace')
 (out/'capture.log').write_text(result.stdout+result.stderr,encoding='utf-8');print(result.returncode,(result.stdout+result.stderr)[-1000:])
 if result.returncode:raise SystemExit(result.returncode)
finally:
 if old is None:prefs.unlink(missing_ok=True)
 else:prefs.write_bytes(old)
 print('Owner workspace preferences restored')
