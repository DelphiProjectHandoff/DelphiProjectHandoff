exec((__import__('pathlib').Path(__file__).parent/'implement-operations.py').read_text(encoding='utf-8').split("s=read('DPH.Analysis.Symbols.pas')")[0])
s=read('tests/DPH.Tests.DatabaseOperations.dpr')
s=s.replace('uses Main, Remote, Touch, BinaryDB;', 'uses Main, Remote, Touch, BinaryDB, Shadow;')
needle=" for Text in ['Remote','Touch','BinaryDB']"
at=s.index(needle)
s=s[:at]+""" TFile.WriteAllText(TPath.Combine(Fixture,'Shadow.pas'),String.Join(sLineBreak,[
 'unit Shadow; interface uses FireDAC.Comp.Client; type TFDQuery = class procedure Delete; end; procedure Work; implementation',
 'procedure TFDQuery.Delete; begin end; procedure Work; var Fake: TFDQuery; begin Fake.Delete; end; end.']),TEncoding.UTF8);
"""+s[at:]
needle=" Check(Find('Post').GetValue<string>('effect')"
at=s.index(needle)
s=s[:at]+""" I:=0;for Value in Report.GetValue<TJSONArray>('rows') do if Value.GetValue<string>('role')='database operation' then begin
  Row:=Value as TJSONObject;Check(Row.GetValue<string>('source')<>'Shadow.pas','Local class shadowing framework name is excluded');
  if Row.GetValue<string>('name')='Delete' then begin Inc(I);
   if Row.GetValue<TJSONArray>('links').Items[0].GetValue<string>('reference')='Records' then
    Check(Row.GetValue<TJSONArray>('links').Items[0].GetValue<string>('target_id')=Find('Records').GetValue<string>('id'),'Custom dataset descendant follows exact declaration');
  end;
 end;
 Check(I=2,'Delete recognizes framework dataset and custom descendant only');
 I:=0;for Value in Report.GetValue<TJSONArray>('rows') do if Value.GetValue<string>('name')='configured SQL' then begin
  Inc(I);Text:=Value.GetValue<string>('operation_kind');
  case I of 1:Check(Text='read','Joined SELECT remains a lexical read candidate');2:Check(Text='insert','INSERT SQL family retained');3:Check(Text='update','UPDATE SQL family retained');4:Check(Text='delete','DELETE SQL family retained');5:Check(Text='unknown','Mixed SQL batch never collapsed to first statement');end;
 end;
"""+s[at:]
write('tests/DPH.Tests.DatabaseOperations.dpr',s)
s=read('DPH.Workspace.DatabaseConnections.pas').replace('Reference:string;Count,OriginalCount:Integer;Match:TMatch;', 'Reference:string;Count:Integer;Match:TMatch;').replace('  OriginalCount:=Rows.Count;\n  for V in AView.Document', '  for V in AView.Document')
write('DPH.Workspace.DatabaseConnections.pas',s)
s=read('DPH.Analysis.Symbols.pas').replace("['TFDQuery','TFDTable','TFDStoredProc','TFDMemTable','TFDDataSet','TFDAdaptedDataSet']", "['TFDQuery','TFDTable','TFDStoredProc','TFDMemTable']").replace("then RequiredUnit:='FireDAC.Comp.Client'", "then RequiredUnit:='FireDAC.Comp.Client'\n    else if MatchText(ShortName,['TFDDataSet','TFDAdaptedDataSet']) then RequiredUnit:='FireDAC.Comp.DataSet'",1).replace("['Data.DB','FireDAC.Comp.Client','Data.Win.ADODB'", "['Data.DB','FireDAC.Comp.Client','FireDAC.Comp.DataSet','Data.Win.ADODB'",1)
write('DPH.Analysis.Symbols.pas',s)
