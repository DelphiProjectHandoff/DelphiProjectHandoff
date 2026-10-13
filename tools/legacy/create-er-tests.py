from pathlib import Path
r=Path.cwd();s=(r/'tests/DPH.Tests.DatabaseStoredObjects.dpr').read_text()
s=s.replace('DatabaseStoredObjects','DatabaseER').replace('database-stored-objects','database-er')
s=s.replace('Form:TDPHMainForm;Bitmap:TBitmap;', 'Form:TDPHMainForm;Bitmap:TBitmap;Diagram,ERNode,EREdge:TJSONObject;Rejected:Boolean;')
s=s.replace("'TFile.ReadAllText(''stored-limits.sql'');", "'TFile.ReadAllText(''er.sql''); TFile.ReadAllText(''stored-limits.sql'');")
at=s.index(' SourceHash:=THashSHA2')
fixture=""" ColumnCase:=String.Join(sLineBreak,[
 'CREATE TABLE ER_Customers (id INTEGER PRIMARY KEY, name VARCHAR(80), active INTEGER DEFAULT 1);',
 'CREATE TABLE ER_Orders (id INTEGER PRIMARY KEY, customer_id INTEGER, total DECIMAL(12,2), CONSTRAINT ER_OrderCustomer FOREIGN KEY(customer_id) REFERENCES ER_Customers(id));',
 'CREATE TABLE ER_Lines (id INTEGER PRIMARY KEY, order_id INTEGER, description TEXT, quantity INTEGER, CONSTRAINT ER_LineOrder FOREIGN KEY(order_id) REFERENCES ER_Orders(id));',
 'CREATE TABLE ER_ManyLinks (id INTEGER,']);
 for I:=1 to 130 do begin ColumnCase:=ColumnCase+'CONSTRAINT Many'+IntToStr(I)+' FOREIGN KEY(id) REFERENCES ER_Customers(id)';if I<130 then ColumnCase:=ColumnCase+',';end;
 ColumnCase:=ColumnCase+');';TFile.WriteAllText(TPath.Combine(Fixture,'er.sql'),ColumnCase,TEncoding.UTF8);
"""
s=s[:at]+fixture+s[at:]
at=s.index(" Check(not Report.ToJSON.Contains('SECRET_SQL_CANARY')")
checks=r''' Diagram:=TDPHDatabaseSchema.Diagram(Report,'ER_','',0,60,8);
 try
 Check(Diagram.GetValue<TJSONArray>('nodes').Count=4,'ER entities come from actual captured table declarations');
 Check(Diagram.GetValue<Integer>('total_tables')>270,'ER global count retains all captured tables');
 Check(Diagram.GetValue<Integer>('source_gaps')>0,'ER labels incomplete schemas with source gap count');
 Check(Diagram.GetValue<Integer>('unresolved_foreign_keys')>0,'ER counts unresolved foreign keys separately');
 Check(Diagram.GetValue<string>('qualification').Contains('PARTIAL CAPTURED SCHEMA'),'ER never claims a complete deployed schema');
 Check(Diagram.GetValue<string>('qualification').Contains('business cardinality'),'ER does not invent business cardinality');
 Check(Diagram.GetValue<Integer>('related_foreign_keys')=132,'ER counts all related keys before evidence cap');
 Check(Diagram.GetValue<TJSONArray>('edges').Count=120,'ER relation evidence bounded to 120 entries');
 Check(Diagram.GetValue<Integer>('omitted_foreign_keys')=12,'ER omitted relationships explicitly counted');
 ERNode:=Diagram.GetValue<TJSONArray>('nodes').Items[0] as TJSONObject;
 Check(ERNode.GetValue<string>('name')='ER_Customers','ER stable ordering follows captured declarations');
 Check(ERNode.GetValue<string>('source_hash')=THashSHA2.GetHashStringFromFile(TPath.Combine(Fixture,'er.sql')),'ER node retains source hash');
 Check(ERNode.GetValue<Int64>('generation_id')=Generation,'ER node retains capture generation');
 Check(ERNode.GetValue<Integer>('range.line')=1,'ER node retains exact declaration start line');
 Check(ERNode.GetValue<TJSONArray>('columns').Items[0].GetValue<string>('badges').Contains('PK'),'ER column badges use captured primary-key membership');
 Check(ERNode.GetValue<TJSONArray>('columns').Items[0].GetValue<string>('id')=Find('ER_Customers.id','declared column').GetValue<string>('id'),'ER column evidence identity retained');
 Check(ERNode.GetValue<TJSONArray>('columns').Items[1].GetValue<string>('declared_type')='VARCHAR(80)','ER displays declared column type');
 EREdge:=Diagram.GetValue<TJSONArray>('edges').Items[0] as TJSONObject;
 Check(EREdge.GetValue<string>('key_id')=Find('ER_Orders | ER_OrderCustomer','declared key').GetValue<string>('id'),'ER edge retains exact key evidence identity');
 Check(EREdge.GetValue<string>('from')=Find('ER_Orders','declared header').GetValue<string>('id'),'ER FK starts from exact owning table declaration');
 Check(EREdge.GetValue<string>('to')=Find('ER_Customers','declared header').GetValue<string>('id'),'ER FK ends at exact resolved captured table');
 Check(EREdge.GetValue<Boolean>('resolved') and EREdge.GetValue<Boolean>('draw'),'ER draws structurally resolved visible foreign key');
 Check(EREdge.GetValue<TJSONArray>('members').ToJSON='["customer_id"]','ER local ordered membership retained');
 Check(EREdge.GetValue<TJSONArray>('reference_columns').ToJSON='["id"]','ER referenced ordered membership retained');
 Check(EREdge.GetValue<Integer>('range.line')=2,'ER edge retains source declaration line');
 Check(not Diagram.ToJSON.Contains('SECRET_'),'ER does not expose masked literal canaries');
 finally Diagram.Free;end;
 Diagram:=TDPHDatabaseSchema.Diagram(Report,'',Find('ER_Orders','declared header').GetValue<string>('id'),0,30,8);
 try Check(Diagram.GetValue<TJSONArray>('nodes').Count=3,'ER focus includes selected table and one-hop incoming/outgoing neighbors');
 Check(Diagram.GetValue<TJSONArray>('edges').Count=132 div 66,'ER focused evidence excludes unrelated foreign-key sources');
 finally Diagram.Free;end;
 Diagram:=TDPHDatabaseSchema.Diagram(Report,'ER_Orders','',0,30,8);
 try Check(Diagram.GetValue<TJSONArray>('nodes').Count=1,'ER text filter bounds visible entity scope');
 Check(not Diagram.GetValue<TJSONArray>('edges').Items[0].GetValue<Boolean>('draw'),'Off-page/filter endpoint is not drawn as a fabricated table');
 Check(Diagram.GetValue<TJSONArray>('edges').Items[0].GetValue<string>('state').Contains('outside'),'Off-page/filter relationship remains explicitly selectable evidence');
 Check(Diagram.GetValue<TJSONArray>('nodes').Items[0].GetValue<TJSONArray>('columns').Items[1].GetValue<string>('badges').Contains('FK'),'ER foreign column badge retained');
 finally Diagram.Free;end;
 Diagram:=TDPHDatabaseSchema.Diagram(Report,'ER_','',1,1,1);
 try Check(Diagram.GetValue<Integer>('matching_tables')=4,'ER pagination preserves total matching count');
 Check(Diagram.GetValue<TJSONArray>('nodes').Items[0].GetValue<string>('name')='ER_Orders','ER offset selects exact later table');
 Check(Diagram.GetValue<Boolean>('has_next'),'ER next page indicated');
 Check(Diagram.GetValue<TJSONArray>('nodes').Items[0].GetValue<Integer>('column_count')=3,'ER full column count survives truncation');
 Check(Diagram.GetValue<TJSONArray>('nodes').Items[0].GetValue<Integer>('shown_columns')=1,'ER column summaries respect display bound');
 Check(Diagram.GetValue<TJSONArray>('nodes').Items[0].GetValue<Boolean>('partial'),'ER truncated table marked incomplete');
 finally Diagram.Free;end;
 Diagram:=TDPHDatabaseSchema.Diagram(Report,'SelfRef','',0,30,8);
 try Check(Diagram.GetValue<TJSONArray>('edges').Items[0].GetValue<string>('from')=Diagram.GetValue<TJSONArray>('edges').Items[0].GetValue<string>('to'),'ER self-reference retained without inventing another entity');finally Diagram.Free;end;
 Diagram:=TDPHDatabaseSchema.Diagram(Report,'Absent','',0,30,8);
 try Check(not Diagram.GetValue<TJSONArray>('edges').Items[0].GetValue<Boolean>('resolved'),'ER absent target is unresolved');
 Check(Diagram.GetValue<TJSONArray>('edges').Items[0].GetValue<string>('to')='','ER absent target has no invented ID');
 Check(Diagram.GetValue<TJSONArray>('nodes').Items[0].GetValue<Boolean>('partial'),'ER unresolved owning table marked orange');finally Diagram.Free;end;
 Diagram:=TDPHDatabaseSchema.Diagram(Report,'Sales.Customers','',0,30,8);
 try Check(Diagram.GetValue<TJSONArray>('nodes').Count=2,'ER duplicate table declarations remain independent');
 Check(Diagram.GetValue<TJSONArray>('nodes').Items[0].GetValue<Boolean>('partial'),'ER duplicate-name table marked incomplete');
 Check(Diagram.GetValue<TJSONArray>('nodes').Items[0].GetValue<string>('id')<>Diagram.GetValue<TJSONArray>('nodes').Items[1].GetValue<string>('id'),'ER duplicate declaration identities do not merge');finally Diagram.Free;end;
 Diagram:=TDPHDatabaseSchema.Diagram(Report,'UnverifiedObject','',0,30,8);
 try Check(Diagram.GetValue<Integer>('shown_tables')=0,'Inferred SQL references do not invent ER entities');finally Diagram.Free;end;
 Diagram:=TDPHDatabaseSchema.Diagram(Report,'','missing-id',0,30,8);
 try Check(Diagram.GetValue<Integer>('shown_tables')=0,'ER missing focused identity cannot select an unrelated table');finally Diagram.Free;end;
 Diagram:=TDPHDatabaseSchema.Diagram(nil,'','',0,30,8);
 try Check(Diagram.GetValue<Integer>('total_tables')=0,'ER empty capture handled');finally Diagram.Free;end;
 Rejected:=False;try Diagram:=TDPHDatabaseSchema.Diagram(Report,'','',0,61,8);Diagram.Free;except on E:EArgumentOutOfRangeException do Rejected:=True;end;Check(Rejected,'ER page bounds enforced');
 Rejected:=False;try Diagram:=TDPHDatabaseSchema.Diagram(Report,'','',-1,30,8);Diagram.Free;except on E:EArgumentOutOfRangeException do Rejected:=True;end;Check(Rejected,'ER negative offset refused');
 Rejected:=False;try Diagram:=TDPHDatabaseSchema.Diagram(Report,'','',0,30,33);Diagram.Free;except on E:EArgumentOutOfRangeException do Rejected:=True;end;Check(Rejected,'ER column bounds enforced');
 Other:=nil;
'''
s=s[:at]+checks+s[at:]
at=s.index(' Form.WorkspaceTabs.ActiveTab:=Form.DatabaseSchemaTab;')
ui=r''' Form.DatabaseERFilter.Text:='ER_Orders';Form.DatabaseERFilterChange(nil);Form.WorkspaceTabs.ActiveTab:=Form.DatabaseERTab;
 Check(Form.DatabaseERStatus.Text.Contains('1 of 1 matching'),'Native ER filter shows captured table scope');
 Check(Form.DatabaseERRelations.Items.Count=2,'Native ER selector retains off-page FK evidence');
 Form.DatabaseERRelations.ItemIndex:=0;Form.DatabaseERSelectionChange(nil);
 Check(Form.DatabaseERMemo.Text.Contains('Ordered local columns'),'Native ER relationship selection explains full ordered key metadata');
 Form.DatabaseEROpenClick(nil);
 Check(Form.WorkspaceTabs.ActiveTab=Form.DatabaseSchemaTab,'ER Open evidence selects schema page');
 Check(Form.DatabaseSchemaMemo.Text.Contains('ER_OrderCustomer'),'ER Open evidence selects exact foreign key');
 Form.DatabaseERFocusClick(nil);
 Check(Form.DatabaseERStatus.Text.Contains('3 of 3 matching'),'Native focus includes incoming and outgoing neighbors');
 Check(Form.DatabaseERRelations.Items.Count=2,'Native focus removes unrelated FKs');
 Form.DatabaseERMouseDown(nil,TMouseButton.mbLeft,[],Form.DatabaseERTableStyle.Margins.Left+20,Form.DatabaseERTableStyle.Margins.Top+60);
 Check(Form.DatabaseERMemo.Text.Contains('TABLE ER_Customers'),'Native table hit selects exact captured table evidence');
 Check(Form.DatabaseERMemo.Text.Contains('CAPTURED COLUMNS AND KEYS'),'Native table evidence includes full inventory beyond card summary');
 Form.DatabaseEROpenClick(nil);Check(Form.DatabaseSchemaMemo.Text.Contains('TABLE ER_Customers'),'Native table evidence opens exact schema target');
 Form.DatabaseERFilterChange(Form.DatabaseERAll);Form.DatabaseERPageSize.ItemIndex:=0;Form.DatabaseERFilterChange(nil);
 Check(Form.DatabaseERStatus.Text.Contains('15 of'),'Native ER page size bounds diagrams');
 Check(Form.DatabaseERNext.Enabled,'Native ER next page enabled');
 Form.DatabaseERFilterChange(Form.DatabaseERNext);Check(Form.DatabaseERStatus.Text.Contains('from 15'),'Native ER next page advances exact offset');
 Form.DatabaseERFilter.Text:='missing-er-table';Form.DatabaseERFilterChange(nil);Check(Form.DatabaseERMemo.Text.Contains('No matching captured tables'),'Native ER empty results explain recovery');
 Form.DatabaseERFilter.Text:='Page270';Form.DatabaseERFilterChange(nil);Form.DatabaseERMouseDown(nil,TMouseButton.mbLeft,[],Form.DatabaseERTableStyle.Margins.Left+20,Form.DatabaseERTableStyle.Margins.Top+60);Form.DatabaseEROpenClick(nil);
 Check(Form.DatabaseSchemaMemo.Text.Contains('TABLE Page270'),'ER evidence navigation reaches later schema inventory page');
 Form.DatabaseERFilter.Text:='ER_';Form.DatabaseERFilterChange(nil);Form.WorkspaceTabs.ActiveTab:=Form.DatabaseERTab;Form.Show;
 Check(Form.WorkspacePageCombo.Items.IndexOf('Database ER diagram')>=0,'ER page available through serialized upper-right selector');
 Form.WorkspacePageCombo.ItemIndex:=Form.WorkspacePageCombo.Items.IndexOf('Database ER diagram');Form.WorkspacePageChange(Form.WorkspacePageCombo);
 Check(Form.WorkspaceTabs.ActiveTab=Form.DatabaseERTab,'Upper-right selector opens ER page');
 Bitmap:=Form.DatabaseERPaint.MakeScreenshot;try Bitmap.SaveToFile(TPath.Combine(Root,'docs\phase1-database-er-diagram.png'));finally Bitmap.Free;end;
 Render('phase1-database-er-workspace.png');
 Form.DatabaseERZoom.ItemIndex:=4;Form.DatabaseERFilterChange(nil);Check(Form.DatabaseERPaint.Width>Form.DatabaseERScroll.Width,'ER zoom enables horizontal scrolling');
 Form.DatabaseERZoom.ItemIndex:=1;Form.DatabaseERFilterChange(nil);
 Form.WindowState:=TWindowState.wsNormal;Form.Width:=960;Form.Height:=600;Application.ProcessMessages;Form.DatabaseERResize(nil);Render('phase1-database-er-compact.png');
 Check(Form.DatabaseERScroll.Height>=30,'Compact ER canvas retains reachable scroll area');
 Check(Form.DatabaseERMemo.ShowScrollBars,'ER evidence memo scrolls');
 Check(Form.DatabaseERScroll.ShowScrollBars,'ER diagram scrolls independently');
 Check(Form.DatabaseERPaint.Height>Form.DatabaseERScroll.Height,'ER canvas retains lower table rows outside viewport');
 Form.DatabaseERToolbar.ViewportPosition:=PointF(10000,0);Application.ProcessMessages;
 Check(Form.DatabaseEROpen.AbsoluteRect.Right<=Form.DatabaseERToolbar.AbsoluteRect.Right+2,'ER evidence command reachable at compact width');
 Render('phase1-database-er-commands.png');
 Form.LoadView(Reopened.Document.Clone as TJSONObject);Check(Form.DatabaseERStatus.Text.Contains('4 of 4 matching'),'Capture replacement rebuilds ER projection under current filter');
 Form.DatabaseSchemaKind.ItemIndex:=9;Form.DatabaseSchemaState.ItemIndex:=9;Form.DatabaseSchemaFilter.Text:='Data.Save';Form.DatabaseSchemaFilterChange(nil);
'''
s=s[:at]+ui+s[at:]
# Preserve the ER UI evidence rather than overwrite it with the retained schema render checks.
s=s.replace("Render('phase1-database-er-workspace.png');\n Form.WindowState", "Render('phase1-database-er-schema-workspace.png');\n Form.WindowState")
s=s.replace("Render('phase1-database-er-compact.png');\n Form.DatabaseSchemaToolbar", "Render('phase1-database-er-schema-compact.png');\n Form.DatabaseSchemaToolbar")
s=s.replace('Database stored objects validation passed:', 'Database ER validation passed:')
s=s.replace('Captured procedures/functions/triggers, ordered parameters/defaults/returns, sanitized bodies, supported table and explicit call evidence, ambiguity/gaps, persistence and native navigation. Body grammar and runtime binding unverified; no SQL executed.','ER diagrams from captured declarations and exact key links, qualified gaps, bounded table/column/relationship projections, focus/filter/paging/zoom and native evidence navigation. Cardinality, semantic validity and deployed schema unverified; no SQL executed.')
(r/'tests/DPH.Tests.DatabaseER.dpr').write_bytes(s.replace('\n','\r\n').encode())
s=(r/'tools/build-database-stored-objects.cmd').read_text().replace('DatabaseStoredObjects','DatabaseER');(r/'tools/build-database-er.cmd').write_bytes(s.replace('\n','\r\n').encode())
print('ER actual-capture and native interaction tests created')
