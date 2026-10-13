from pathlib import Path
r=Path.cwd();p=r/'DPH.Workspace.DatabaseConnections.pas';s=p.read_text(encoding='utf-8-sig')
s=s.replace('Owner,FileRow,PropertyNode,Rule,Handler,Flow,Symbol,ReferenceRow:TJSONObject;', 'Owner,FileRow,PropertyNode,Rule,Handler,Flow,Symbol,ReferenceRow,FlowIR:TJSONObject;')
s=s.replace('Original,I,J,Parent,Count,SplitAt:Integer;', 'Original,I,J,K,Parent,Count,SplitAt,FlowIndex,ExprCount,EvidenceStart,EvidenceEnd:Integer;FirstExpr,SecondExpr:TJSONObject;')
s=s.replace("Result:=Result+'[character code omitted]';Inc(J);while", "Result:=Result+'[character code omitted]';Inc(J);while (J<=Length(S)) and CharInSet(S[J],[#9,#10,#13,' ']) do Inc(J);while")
old="Kind:=Flow.GetValue<string>('kind');ExpressionText:=Flow.GetValue<string>('expression');SplitAt:=Pos('; ',ExpressionText);"
new="""Kind:=Flow.GetValue<string>('kind');ExpressionText:=Flow.GetValue<string>('expression');
      FlowIR:=nil;FlowIndex:=-1;FirstExpr:=nil;SecondExpr:=nil;ExprCount:=0;
      for K:=0 to Nodes.Count-1 do if (Nodes.Items[K].GetValue<Integer>('start')=Flow.GetValue<Integer>('range.start')) and (Nodes.Items[K].GetValue<string>('kind')='statement_'+Kind) then begin FlowIR:=Nodes.Items[K] as TJSONObject;FlowIndex:=K;Break;end;
      if FlowIR<>nil then for C in Nodes do if (C.GetValue<Integer>('parent')=FlowIndex) and (C.GetValue<string>('kind')='expression') then begin Inc(ExprCount);if ExprCount=1 then FirstExpr:=C as TJSONObject else if ExprCount=2 then SecondExpr:=C as TJSONObject;end;
      EvidenceStart:=Flow.GetValue<Integer>('range.start');EvidenceEnd:=Flow.GetValue<Integer>('range.end');
      if FirstExpr<>nil then begin EvidenceStart:=FirstExpr.GetValue<Integer>('start');EvidenceEnd:=FirstExpr.GetValue<Integer>('end');end;
      if SecondExpr<>nil then EvidenceEnd:=SecondExpr.GetValue<Integer>('end');"""
assert old in s;s=s.replace(old,new,1).replace("else if SplitAt>0 then Text:='transformation assignment candidate'", "else if (ExprCount=2) then Text:='transformation assignment candidate'")
s=s.replace("for C in Nodes do if (C.GetValue<Integer>('start')=Flow.GetValue<Integer>('range.start')) and C.GetValue<string>('kind').StartsWith('statement_') then begin SetText(Rule,'condition',C.GetValue<string>('condition',''));Break;end;", "if FlowIR<>nil then SetText(Rule,'condition',FlowIR.GetValue<string>('condition',''));")
s=s.replace("SetText(Rule,'output',Safe(Copy(ExpressionText,1,SplitAt-1)));SetText(Rule,'input',Safe(Copy(ExpressionText,SplitAt+2,MaxInt)));", "SetText(Rule,'output',Safe(FirstExpr.GetValue<string>('value')));SetText(Rule,'input',Safe(SecondExpr.GetValue<string>('value')));SetText(Rule,'expression',Safe(FirstExpr.GetValue<string>('value'))+' := '+Safe(SecondExpr.GetValue<string>('value')));")
s=s.replace("(B.GetValue<Integer>('range.start')>=Flow.GetValue<Integer>('range.start')) and (B.GetValue<Integer>('range.end')<=Flow.GetValue<Integer>('range.end'))", "(B.GetValue<Integer>('range.start')>=EvidenceStart) and (B.GetValue<Integer>('range.end')<=EvidenceEnd)")
s=s.replace('Count,SplitAt,FlowIndex','Count,FlowIndex')
p.write_text(s,encoding='utf-8')
p=r/'DPH.Parse.Forms.pas';s=p.read_text(encoding='utf-8-sig');s=s.replace("StartsText('On',PropertyName) and not MatchText(Value,['nil','null'])", "(StartsText('On',PropertyName) or MatchText(PropertyName,['BeforePost','BeforeInsert','BeforeEdit','BeforeDelete','BeforeCancel','BeforeOpen'])) and not MatchText(Value,['nil','null'])");p.write_text(s,encoding='utf-8-sig')
p=r/'DPH.Parse.Model.pas';s=p.read_text(encoding='utf-8-sig').replace("DPHAnalyzerVersion = 'DPH-WP2-5'","DPHAnalyzerVersion = 'DPH-WP2-6'");p.write_text(s,encoding='utf-8')
p=r/'DPH.Analysis.Model.pas';s=p.read_text(encoding='utf-8-sig').replace("DPHSemanticVersion = 'DPH-WP3-14'","DPHSemanticVersion = 'DPH-WP3-15'");p.write_text(s,encoding='utf-8')
p=r/'tests/DPH.Tests.DataRules.dpr';s=p.read_text(encoding='utf-8-sig').replace("Check(RuleRow('validation exit','Exit')=nil,'Bare Exit is represented as empty captured expression');", "Check(RuleRow('validation exit','Exit')<>nil,'Early return remains a visible source candidate');")
s=s.replace("' Normalized := Trim(Text);',", "' Normalized := Trim(Text);', ' Notify(''SENSITIVE_CALL; SEMICOLON_CANARY'');',")
s=s.replace("Check(RuleRow('transformation','Trim')<>nil,'Text transformation retained');", "Check(RuleRow('transformation','Trim')<>nil,'Text transformation retained');\n Check(RuleRow('transformation','Notify')=nil,'Semicolon inside call literal never invents assignment');\n Check(RuleRow('validation or conversion hook','BeforePost').GetValue<TJSONArray>('links').ToJSON.Contains('handler'),'Dataset BeforePost resolves captured handler');\n Check(RuleRow('validation condition','InputAmount = 0')<>nil,'Dataset BeforePost rule body captured');")
p.write_text(s,encoding='utf-8')
print('Assignment classification uses direct IR expressions; dataset hooks captured')
