from pathlib import Path
r=Path.cwd();p=r/'tests/DPH.Tests.DataQuality.dpr';s=p.read_text(encoding='utf-8-sig');needle="Rows:=Store.LinkCandidates(Generation,'section','Imported check report');try Check(Rows.Count=1,'Imported result available as exact revision section link');finally Rows.Free;end;"
s=s.replace(needle,"""Rows:=Store.LinkCandidates(Generation,'section','Imported check report');try Check(Rows.Count=1,'Imported result available as exact revision section link');
 Row:=LoadPolicy;try Revision:=StrToInt64(Row.GetValue<string>('revision'));Body:=Row.GetValue<string>('body');Links:=Row.GetValue<TJSONArray>('rich_links').Clone as TJSONArray;finally Row.Free;end;
 try RecordValue:=Rows.Items[0].Clone as TJSONObject;RecordValue.AddPair('link_role','cites');Links.AddElement(RecordValue);
 Store.SaveKnowledge(PolicyID,Revision,Generation,PolicyTitle,Body,'Result linker','business_rule','','maintenance','maintainer',Links.ToJSON,'',Metadata);
 finally Links.Free;end;finally Rows.Free;end;
 Row:=LoadPolicy;try Check(Row.GetValue<TJSONArray>('rich_links').Count=3,'Quality rule retains source/procedure links and cites exact imported result revision');finally Row.Free;end;""")
s=s.replace("Check(not Form.DataQualityNew.Enabled,'No capture disables new policy');","Check(not Form.DataQualityNew.Enabled,'No capture disables new check');Check(not Form.DataQualityImport.Enabled,'No capture disables report import');")
s=s.replace("Form.DataQualityNewClick(nil);Check(Form.StatusLabel.Text.Contains('Save or discard'),'Unsaved draft protected from replacement');","Form.DataQualityNewClick(nil);Check(Form.StatusLabel.Text.Contains('Save or discard'),'Unsaved draft protected from replacement');Form.DataQualityImportClick(nil);Check(Form.StatusLabel.Text.Contains('Save or discard'),'Unsaved draft protected from report import');")
s=s.replace('Policy workflow','Quality workflow').replace('policy draft','quality draft').replace('Policy text search finds authored period','Quality text search finds authored threshold');p.write_text(s,encoding='utf-8-sig')
