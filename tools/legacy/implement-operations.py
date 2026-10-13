from pathlib import Path
root=Path(__file__).resolve().parents[2]
def read(name): return (root/name).read_text(encoding='utf-8-sig')
def write(name,text): (root/name).write_text(text,encoding='utf-8-sig',newline='\r\n')
s=read('DPH.Analysis.Symbols.pas')
s=s.replace('    function IsFormType(', '    function IsDatasetType(const AName,AUnit: string): Boolean;\n    function IsFormType(',1)
at=s.index('function TDPHSemanticAnalyzer.IsFormType(')
s=s[:at]+'''function TDPHSemanticAnalyzer.IsDatasetType(const AName,AUnit: string): Boolean;
var Index,Base,Depth:Integer;R:TDPHRelation;Name,UnitName,ImportName:string;Imports:TList<string>;
  function Known(const TypeName,Context:string):Boolean;
  var ShortName,RequiredUnit:string;P:Integer;
  begin
    P:=LastDelimiter('.',TypeName);ShortName:=Copy(TypeName,P+1,MaxInt);RequiredUnit:='';
    if MatchText(ShortName,['TDataSet']) then RequiredUnit:='Data.DB'
    else if MatchText(ShortName,['TFDQuery','TFDTable','TFDStoredProc','TFDMemTable','TFDDataSet','TFDAdaptedDataSet']) then RequiredUnit:='FireDAC.Comp.Client'
    else if MatchText(ShortName,['TADOQuery','TADOTable','TADOStoredProc','TADODataSet','TCustomADODataSet']) then RequiredUnit:='Data.Win.ADODB'
    else if MatchText(ShortName,['TSQLQuery','TSQLTable','TSQLStoredProc','TSQLDataSet','TCustomSQLDataSet']) then RequiredUnit:='Data.SqlExpr'
    else if SameText(ShortName,'TClientDataSet') then RequiredUnit:='Datasnap.DBClient'
    else if MatchText(ShortName,['TQuery','TTable','TStoredProc','TDBDataSet']) then RequiredUnit:='Bde.DBTables'
    else if MatchText(ShortName,['TIBQuery','TIBTable','TIBDataSet']) then RequiredUnit:='IBX.'+Copy(ShortName,2,MaxInt);
    Result:=False;if RequiredUnit='' then Exit;
    if (P>0) and not SameText(Copy(TypeName,1,P-1),RequiredUnit) then Exit;
    if SameText(Context,RequiredUnit) then Exit(True);
    if FImports.TryGetValue(LowerCase(Context),Imports) then for ImportName in Imports do
      if SameText(ImportName,RequiredUnit) or
        ((RequiredUnit='Data.DB') and SameText(ImportName,'DB')) or
        ((RequiredUnit='Data.Win.ADODB') and SameText(ImportName,'ADODB')) or
        ((RequiredUnit='Data.SqlExpr') and SameText(ImportName,'SqlExpr')) or
        ((RequiredUnit='Datasnap.DBClient') and SameText(ImportName,'DBClient')) or
        ((RequiredUnit='Bde.DBTables') and SameText(ImportName,'DBTables')) then Exit(True);
  end;
begin
  Result:=False;Index:=FindType(AName,AUnit);Name:=AName;UnitName:=AUnit;
  for Depth:=0 to 31 do begin
    if Index<0 then Exit(Known(Name,UnitName));
    Name:=FGraph.Symbols[Index].Name;UnitName:=FGraph.Symbols[Index].UnitName;
    // A local class sharing a framework name is not a framework dataset.
    if Known(Name,UnitName) and MatchText(UnitName,['Data.DB','FireDAC.Comp.Client','Data.Win.ADODB','Data.SqlExpr','Datasnap.DBClient','Bde.DBTables','IBX.IBQuery','IBX.IBTable','IBX.IBDataSet']) then Exit(True);
    if FBaseTypes.TryGetValue(Index,Base) then Index:=Base
    else begin
      for R in FGraph.Relations do if (R.FromSymbol=Index) and (R.Kind='inherits') and (R.ToSymbol<0) and Known(R.LabelText,UnitName) then Exit(True);
      Exit(False);
    end;
  end;
end;

'''+s[at:]
needle="      if IsCall and (Args.Count>0) and\n"
insert='''      InputIndex:=LastDelimiter('.',Path);
      if IsCall and not WithinWith and (InputIndex>0) then begin
        InputPath:=Copy(Path,InputIndex+1,MaxInt);
        if MatchText(InputPath,['Open','Refresh','First','Last','Next','Prior','MoveBy','Locate','Lookup','FindFirst','FindLast','FindNext','FindPrior','Append','AppendRecord','Insert','InsertRecord','Edit','Post','Delete','Cancel','ApplyUpdates','CancelUpdates','ExecSQL','Execute']) then begin
          InputSymbol:=ResolveValue(Copy(Path,1,InputIndex-1),ARoutine);
          if (InputSymbol>=0) and IsDatasetType(FGraph.Symbols[InputSymbol].TypeName,FGraph.Symbols[InputSymbol].UnitName) then
            FGraph.AddRelation(ARoutine,InputSymbol,'database_operation','possible_dynamic','declared_dataset_api_request_not_runtime_success',InputPath,L,Tokens[I].Condition);
        end;
      end;
'''
assert needle in s;s=s.replace(needle,insert+needle,1);write('DPH.Analysis.Symbols.pas',s)
s=read('DPH.Analysis.Model.pas').replace('DPH-WP3-12','DPH-WP3-13');write('DPH.Analysis.Model.pas',s)
