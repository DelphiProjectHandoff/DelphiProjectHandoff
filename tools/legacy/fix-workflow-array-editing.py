from pathlib import Path
p=Path('DPH.UI.Main.pas');s=p.read_text(encoding='utf-8-sig');s=s.replace('var Steps:TJSONArray;Step:TJSONObject;Key,Target:string;V:TJSONValue;Index:Integer;','var Steps:TJSONArray;Step:TJSONObject;Key,Target:string;V:TJSONValue;Index,I:Integer;Elements:TList<TJSONValue>;')
s=s.replace('else begin Steps.Remove(FWorkflowStepIndex).Free;Steps.Insert(FWorkflowStepIndex,Step.Clone as TJSONObject);end;', '''else begin
     Elements:=TList<TJSONValue>.Create;
     for I:=0 to Steps.Count-1 do if I=FWorkflowStepIndex then Elements.Add(Step.Clone as TJSONObject) else Elements.Add(Steps.Items[I]);
     V:=Steps.Items[FWorkflowStepIndex];Steps.SetElements(Elements);V.Free;
    end;''')
s=s.replace('V:=Steps.Remove(FWorkflowStepIndex);Steps.Insert(Index,V);FWorkflowStepIndex:=Index;', '''Elements:=TList<TJSONValue>.Create;for I:=0 to Steps.Count-1 do Elements.Add(Steps.Items[I]);
   Elements.Exchange(FWorkflowStepIndex,Index);Steps.SetElements(Elements);FWorkflowStepIndex:=Index;''')
p.write_text(s,encoding='utf-8')
