program DPHValidateHandoff;
{$APPTYPE CONSOLE}
uses System.SysUtils, DPH.Publish.Export in '..\DPH.Publish.Export.pas';
begin
  try
    if (ParamCount<2) or (ParamCount>3) or ((ParamCount=3) and (ParamStr(3)<>'--allow-stale')) then
      raise EArgumentException.Create('Usage: DPH.ValidateHandoff bundle-directory trusted-input-fingerprint [--allow-stale]');
    TDPHPublisher.Validate(ParamStr(1),ParamStr(2),ParamCount=2);
    Writeln('PASS: checksums, source ranges, generation and technical indexes agree with the trusted fingerprint');
    if ParamCount=3 then Writeln('Historical/partial inspection explicitly allowed; this does not establish current complete source evidence.');
  except on E: Exception do begin Writeln(E.ClassName,': ',E.Message); ExitCode:=1; end; end;
end.
