from pathlib import Path
p=Path('DPH.Workspace.DatabaseConnections.pas');s=p.read_text(encoding='utf-8-sig')
needle="  Result:=Result+sLineBreak+'UNKNOWNS AND NEXT INVESTIGATION'"
insert="""  if ARow.GetValue<string>('role')='transaction operation' then begin
    BindingText:='TRANSACTION PATHS (SOURCE POSSIBILITIES)'+sLineBreak;
    for Value in ARow.GetValue<TJSONArray>('transaction_paths') do
      BindingText:=BindingText+Value.GetValue<string>('path_kind')+' -> '+Value.GetValue<string>('target')+sLineBreak+'  CFG edges: '+Value.GetValue<string>('edge_kinds')+sLineBreak;
    if ARow.GetValue<TJSONArray>('transaction_paths').Count=0 then BindingText:=BindingText+'No ordered route available. Review source; absence is not proof of safe commit/rollback handling.'+sLineBreak;
    BindingText:=BindingText+'CFG states examined: '+ARow.GetValue('flow_states_examined').Value+'; truncated: '+ARow.GetValue('flow_truncated').Value+'; ambiguous statement: '+ARow.GetValue('flow_ambiguous').Value+sLineBreak+ARow.GetValue<string>('flow_qualification')+sLineBreak+sLineBreak;
    Result:=BindingText+Result;
  end;
"""
assert needle in s;s=s.replace(needle,insert+needle);p.write_text(s,encoding='utf-8-sig')
