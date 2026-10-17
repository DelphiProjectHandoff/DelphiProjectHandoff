unit DPH.UI.Progress;

interface

uses FMX.Forms, FMX.StdCtrls;

type
  TDPHProgressForm = class(TForm)
    ProgressMessage: TLabel;
    ProgressHint: TLabel;
    ProgressPercent: TLabel;
    ProgressBar: TProgressBar;
  end;

implementation

{$R *.fmx}

end.
