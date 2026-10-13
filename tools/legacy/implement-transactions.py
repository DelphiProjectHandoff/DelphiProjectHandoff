from pathlib import Path
r=Path.cwd()
def edit(name,fn):
 p=r/name;s=p.read_text(encoding='utf-8-sig');p.write_text(fn(s),encoding='utf-8-sig')
edit('DPH.Analysis.Model.pas',lambda s:s.replace('DPH-WP3-13','DPH-WP3-14'))
def semantic(s):
 s=s.replace('function IsDatasetType(const AName,AUnit: string): Boolean;',"function IsDatabaseType(const AName,AUnit: string; const AOperation: string = ''): Boolean;")
 s=s.replace('function TDPHSemanticAnalyzer.IsDatasetType(const AName,AUnit: string): Boolean;', 'function TDPHSemanticAnalyzer.IsDatabaseType(const AName,AUnit,AOperation: string): Boolean;')
 s=s.replace("    if MatchText(ShortName,['TDataSet']) then RequiredUnit:='Data.DB'", """    if AOperation<>'' then begin
      if MatchText(ShortName,['TFDConnection','TFDCustomConnection','TFDTransaction','TFDCustomTransaction']) and MatchText(AOperation,['StartTransaction','Commit','Rollback','CommitRetaining','RollbackRetaining']) then RequiredUnit:='FireDAC.Comp.Client'
      else if SameText(ShortName,'TADOConnection') and MatchText(AOperation,['BeginTrans','CommitTrans','RollbackTrans']) then RequiredUnit:='Data.Win.ADODB'
      else if SameText(ShortName,'TSQLConnection') and MatchText(AOperation,['StartTransaction','BeginTransaction','Commit','Rollback','CommitFreeAndNil','RollbackFreeAndNil','RollbackIncompleteFreeAndNil']) then RequiredUnit:='Data.SqlExpr'
      else if SameText(ShortName,'TDatabase') and MatchText(AOperation,['StartTransaction','Commit','Rollback']) then RequiredUnit:='Bde.DBTables'
      else if SameText(ShortName,'TIBTransaction') and MatchText(AOperation,['StartTransaction','Commit','Rollback','CommitRetaining','RollbackRetaining','RollbackSavepoint']) then RequiredUnit:='IBX.IBDatabase';
    end
    else if MatchText(ShortName,['TDataSet']) then RequiredUnit:='Data.DB'""")
 s=s.replace('IsDatasetType(FGraph.Symbols[InputSymbol].TypeName,FGraph.Symbols[InputSymbol].UnitName)','IsDatabaseType(FGraph.Symbols[InputSymbol].TypeName,FGraph.Symbols[InputSymbol].UnitName)')
 s=s.replace("'IBX.IBQuery','IBX.IBTable','IBX.IBDataSet']) then Exit(True)","'IBX.IBQuery','IBX.IBTable','IBX.IBDataSet','IBX.IBDatabase']) then Exit(True)")
 s=s.replace('not a framework dataset.','not a framework database type.')
 needle="      if IsCall and (Args.Count>0) and\n        (EndsText('.WriteAllText',Path)"
 insert="""      if not WithinWith and (InputIndex>0) then begin
        InputPath:=Copy(Path,InputIndex+1,MaxInt);
        if MatchText(InputPath,['StartTransaction','BeginTransaction','BeginTrans','Commit','CommitTrans','CommitRetaining','CommitFreeAndNil','Rollback','RollbackTrans','RollbackRetaining','RollbackFreeAndNil','RollbackIncompleteFreeAndNil','RollbackSavepoint']) and
          (IsCall or (MatchText(InputPath,['BeginTrans','BeginTransaction']) and (Stop+1<=Body.LastToken) and MatchText(Tokens[Stop+1].Text,[';','end']))) then begin
          InputSymbol:=ResolveValue(Copy(Path,1,InputIndex-1),ARoutine);
          if (InputSymbol>=0) and IsDatabaseType(FGraph.Symbols[InputSymbol].TypeName,FGraph.Symbols[InputSymbol].UnitName,InputPath) then
            FGraph.AddRelation(ARoutine,InputSymbol,'database_transaction','possible_dynamic','declared_transaction_api_request_not_runtime_outcome',InputPath,L,Tokens[I].Condition);
        end;
      end;
"""
 assert needle in s;s=s.replace(needle,insert+needle);return s.rstrip()+'\n'
edit('DPH.Analysis.Symbols.pas',semantic)
def inventory(s):
 s=s.replace('    class procedure AppendOperations(', '    class procedure AttachTransactionPaths(AView:TDPHWorkspaceView;AInventory:TJSONObject); static;\n    class procedure AppendOperations(',1)
 s=s.replace('      AppendOperations(AView,Result);','      AppendOperations(AView,Result);\n      AttachTransactionPaths(AView,Result);')
 s=s.replace("['database_operation','static_sql','dynamic_sql']","['database_operation','database_transaction','static_sql','dynamic_sql']")
 s=s.replace("   if Basis='database_operation' then begin", """   if Basis='database_transaction' then begin
    if MatchText(Method,['StartTransaction','BeginTransaction','BeginTrans']) then begin Kind:='begin transaction';Effect:='Requests starting a transaction or nested savepoint. Provider settings, nesting depth and successful activation are unobserved.';end
    else if MatchText(Method,['Commit','CommitTrans','CommitFreeAndNil']) then begin Kind:='commit request';Effect:='Requests committing the current transaction. The call can raise; a later rollback path does not prove that committed changes were undone.';end
    else if SameText(Method,'CommitRetaining') then begin Kind:='commit retaining request';Effect:='Requests committing while retaining or restarting transaction context. Provider emulation and nested savepoint behavior require review.';end
    else if SameText(Method,'RollbackSavepoint') then begin Kind:='rollback savepoint request';Effect:='Requests rolling back a named savepoint, not necessarily the entire transaction. Savepoint identity and successful rollback remain unobserved.';end
    else if SameText(Method,'RollbackRetaining') then begin Kind:='rollback retaining request';Effect:='Requests undoing pending changes while retaining or restarting transaction context. Runtime success and provider behavior remain unobserved.';end
    else begin Kind:='rollback request';Effect:='Requests rolling back pending transaction changes. The request itself can raise. Previously committed changes, implicit commits and external side effects are not proved undone.';end;
    Basis:='Recognized API on a declared framework connection/transaction or captured descendant. Intraprocedural paths below are conservative source possibilities.';
   end else if Basis='database_operation' then begin""")
 s=s.replace("Row.AddPair('operation_kind',Kind)","if Relation.GetValue<string>('kind')='database_transaction' then begin Row.RemovePair('role').Free;Row.AddPair('role','transaction operation');end;\n   Row.AddPair('routine_key',Relation.GetValue<string>('from')).AddPair('receiver_key',Relation.GetValue<string>('to',''));\n   Row.AddPair('operation_kind',Kind)")
 s=s.replace("(Relation.GetValue<string>('kind')='database_operation') then begin","MatchText(Relation.GetValue<string>('kind'),['database_operation','database_transaction']) then begin")
 s=s.replace(".AddPair('role','dataset');\n     Target.AddPair", ".AddPair('role',IfThen(Relation.GetValue<string>('kind')='database_transaction','transaction','dataset'));\n     Target.AddPair")
 s=s.replace("'availability','captured descendant dataset declaration'","'availability','captured database receiver declaration'")
 s=s.replace("Receiver has a captured dataset ancestry.","Receiver has a captured database API ancestry.")
 s=s.replace("Link:=TJSONObject.Create.AddPair('property','DataSet')", "Link:=TJSONObject.Create.AddPair('property',IfThen(Relation.GetValue<string>('kind')='database_transaction','Transaction','DataSet'))")
 s=s.replace("['dataset','connection']) then begin","['dataset','connection','transaction']) then begin")
 s=s.replace("'database candidate','database operation'])","'database candidate','database operation','transaction operation'])")
 s=s.replace("'DefaultDatabase','DataSet']) then begin","'DefaultDatabase','DataSet','Transaction']) then begin")
 s=s.replace("if ARow.GetValue<string>('role')='database operation' then", "if MatchText(ARow.GetValue<string>('role'),['database operation','transaction operation']) then")
 return s
edit('DPH.Workspace.DatabaseConnections.pas',inventory)
edit('DPH.UI.Main.fmx',lambda s:s.replace("'database operation')","'database operation'\n 'transaction operation')"))
