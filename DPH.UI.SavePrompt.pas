unit DPH.UI.SavePrompt;

interface

uses FMX.Forms, FMX.StdCtrls;

type
  TDPHSavePromptForm = class(TForm)
    PromptLabel: TLabel;
    DetailLabel: TLabel;
    YesButton: TButton;
    NoButton: TButton;
    CancelButton: TButton;
  end;

implementation

{$R *.fmx}

end.
