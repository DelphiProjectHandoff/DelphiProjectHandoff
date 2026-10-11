unit Worker;
interface
type
  IWorker = interface
    procedure Run;
  end;
  TBase = class
    procedure Run; virtual;
  end;
  TWorker = class(TBase, IWorker)
    Value: Integer;
    procedure Run; override;
    procedure Convert(AValue: Integer); overload;
    procedure Convert(AValue: string); overload;
  end;
procedure PublicWork(AValue: Integer);
implementation
procedure HiddenWork;
begin end;
procedure PublicWork(AValue: Integer);
begin HiddenWork; end;
procedure TBase.Run;
begin end;
procedure TWorker.Run;
begin inherited Run; Value := 1; end;
procedure TWorker.Convert(AValue: Integer);
begin Value := AValue; end;
procedure TWorker.Convert(AValue: string);
begin Value := 2; end;
end.
