unit Test;
interface
{$IF CompilerVersion > 23}
  {$DEFINE LATER}
  const A=1;
{$ELSE}
  const A=2;
{$IFEND}
{$IFDEF LATER}
  const B=3;
{$ENDIF}
implementation
end.
