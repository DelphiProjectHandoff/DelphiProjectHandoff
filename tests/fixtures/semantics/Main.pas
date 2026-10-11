unit Main;
interface
uses Worker;
type
  TMain = class
    procedure Click(Sender: Integer);
  end;
implementation
{$R *.fmx}
procedure TMain.Click(Sender: Integer);
var Engine: TWorker; Face: IWorker; Callback: TProc; Count: Integer;
begin
  Engine.Convert(1);
  Engine.Convert('text');
  Engine.Run;
  Face.Run;
  PublicWork(Sender);
  HiddenWork();
  Callback := PublicWork;
  Callback();
  if Sender > 0 then Count := 1 else Count := 2;
  while Count < 4 do begin Inc(Count); if Count = 3 then Continue; end;
  repeat Dec(Count); until Count = 0;
  for Count := 1 to 3 do begin if Sender = 0 then Break; end;
  try
    if Sender = 1 then Exit;
    if Sender = 2 then raise;
    Count := 5;
  finally
    Count := 9;
  end;
  TThread.CreateAnonymousThread(procedure
    var Local: Integer;
    begin Local := 3; PublicWork(Local);
      TThread.Queue(nil, procedure begin PublicWork(4); end);
    end);
  Count := 12; // Engine.Convert('fake') is never a call
end;
procedure Shadow;
var PublicWork: TProc;
begin PublicWork(1); end;
procedure Conditional;
begin
{$IFDEF FEATURE}
  PublicWork(1);
{$ELSE}
  PublicWork(2);
{$ENDIF}
end;
procedure Uncertain;
var Engine: TWorker; Count: Integer;
begin
  Engine.Convert(UnknownValue());
  PublicWork('wrong argument type');
  HiddenBare;
  Count := MissingValue;
  try PublicWork(1); except on E: Exception do PublicWork(2); end;
  case UnknownValue() of 1: PublicWork(3); else PublicWork(4); end;
end;
procedure LoopFinally;
var Count: Integer;
begin
  while Count > 0 do
    try Break; finally Count := 8; end;
end;
end.
