from pathlib import Path
r=Path.cwd();p=r/'DPH.Analysis.Symbols.pas';s=p.read_text(encoding='utf-8-sig').replace('R,P: TDPHRelation; S,Owner','R,P,W: TDPHRelation; Hazard:Boolean; S,Owner').replace("['control_owner_candidate','control_property_candidate']","['control_owner_candidate','control_property_candidate','writes']")
s=s.replace("if (Handles[HandleKey]<>1) or (P.Location.StartByte<R.Location.StartByte) then begin", """Hazard:=False;
        for W in Items do if (W.Kind='writes') and (W.ToSymbol=R.ToSymbol) and (W.Location.StartByte>R.Location.StartByte) and (W.Location.StartByte<P.Location.StartByte) then begin Hazard:=True; Break; end;
        if (Handles[HandleKey]<>1) or (P.Location.StartByte<R.Location.StartByte) or Hazard then begin""").replace('reused_handle_or_assignment_before_creation_not_attributed','reused_or_overwritten_handle_or_assignment_before_creation_not_attributed');p.write_text(s,encoding='utf-8')
p=r/'DPH.Workspace.DynamicControls.pas';s=p.read_text(encoding='utf-8-sig').replace('var V,L:TJSONValue;','var V:TJSONValue;').replace(' try\n  for V',' try\n  try\n  for V',1).replace(' end;\n Indexed.Free;',' end;\n finally Indexed.Free; end;');p.write_text(s,encoding='utf-8')
p=r/'tests/DPH.Tests.DynamicControls.dpr';s=p.read_text(encoding='utf-8-sig').replace('Report,Row,CopyDoc','Report,CopyDoc').replace("' procedure Build;'","' procedure Clobber;', ' procedure Build;'")
s=s.replace("'procedure TMain.Reuse;", "'procedure TMain.Clobber; var B: TButton; begin B := TButton.Create(Self); B := nil; B.Parent := Panel; end;',\n 'procedure TMain.Reuse;")
s=s.replace("Graph:=Semantic.Analyze(Scan);try Check(Semantic.ReusedRoutines>0,'Incremental cache reuses new relationship candidates');finally Graph.Free;end;", """Graph:=Semantic.Analyze(Scan);try Check(Semantic.ReusedRoutines>0,'Incremental cache reuses new relationship candidates');
 CopyDoc:=Graph.AsJSON;try Check(CopyDoc.ToJSON=View.Document.GetValue<TJSONObject>('semantics').ToJSON,'Cached and fresh semantic relationships are identical');finally CopyDoc.Free;end;finally Graph.Free;end;""")
s=s.replace("=277,'Creation", "=278,'Creation").replace("Count=27,'Next", "Count=28,'Next")
s=s.replace("Check(Has('Before','dynamic_assignment_ambiguous')", "Check(Has('Clobber','dynamic_assignment_ambiguous'),'Overwritten handle is not attributed to the creation site');\n Check(not Has('Clobber','dynamic_parent |'),'Overwritten handle gets no false parent link');\n Check(Has('Before','dynamic_assignment_ambiguous')")
p.write_text(s,encoding='utf-8')
