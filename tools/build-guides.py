"""Build the current manuals and offline help from inspected application behavior."""
from pathlib import Path
from datetime import date
import hashlib,json,html,re
from docx import Document
from docx.shared import Inches,Pt,RGBColor
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
ROOT=Path(__file__).resolve().parents[1]
CHANGED=date.today().strftime('%d %B %Y')

USER=[
('Getting started',[
('h','What this guide helps you do'),
('p','Delphi Project Handoff (DPH) helps you learn an unfamiliar Delphi application. You choose that application, read its purpose, follow its screens and actions, and study instructions supplied by someone who knows it. You can then investigate how a particular action reaches the code that performs the work.'),
('p','This guide is for the learner and the person preparing lessons. Begin with one common task. You do not need to understand every source file or compiler setting before you start.'),
('h','Start DPH'),
('steps',['Extract the supplied DPH package into a local folder where you can save files. Open the extracted folder rather than running from inside the ZIP file.',
'Double-click DelphiProjectHandoff.exe. Keep the other supplied files and folders together. The window opens maximized and displays Getting started.',
'Read Your first ten minutes. Click Getting started in the header whenever you want to return to these directions.',
'If lessons have already been prepared, click Open saved lessons. Otherwise, continue with Choose an application in the next chapter.']),
('p','The top-right selector chooses a learning page. Prepare lessons is a separate button for adding introductions, tasks, answers and images. The bottom status line tells you what DPH is doing.'),
('h','Understand the lessons'),
('p','DPH reads supplied source and form files without changing or running the selected application. These files reveal many connections, but they do not contain every business reason or operating procedure. Named contributions supply that knowledge. When an explanation is unavailable, DPH leaves a question to answer.')]),
('Choose an application',[
('h','Open a project for the first time'),
('p','Obtain the application source from the person responsible for it. Ask for its Delphi project file and associated source and form files. An executable by itself does not provide the same lessons.'),
('steps',['Click Choose application at the top left.',
'Select the intended .dproj or .dpr project file, or its .groupproj project group. DPH prevents selecting its own project.',
'In the save dialog, give its lesson database a descriptive name ending in .dphdb. The proposed Databases folder is convenient. Keep the database outside the selected application source folder.',
'Wait while lessons are prepared. When ready, Learn the project opens. Read the introduction before browsing the object list.']),
('h','Open existing lessons'),
('steps',['Click Open saved lessons.',
'Select the supplied .dphdb file. Keep its adjacent folder with the same name plus .views beside it.',
'Read the application identity and lessons. Saved lessons can be read without the original source. Ask the preparer to reconnect and refresh the source when you need current explanations.']),
('p','One database belongs to one selected application or project group. Open a different database to learn another application. A rejected project selection leaves the current workspace available.'),
('h','When preparation needs help'),
('p','If some code could not be explained, ask the author whether all required files were supplied. Prepare lessons contains collapsed source reading settings for that person. Leave them alone unless the author tells you which settings the application requires.')]),
('Read the learning route',[
('h','Begin with purpose and a familiar screen'),
('steps',['Choose Learn the project in the top-right selector.',
'Select Start here in its topic list. Read the application purpose, contributor and review information.',
'Open Screens and actions. Find a control or action that matters to your first task and follow its link.',
'Read Understand this selection and Why it matters to the user. Identify the intended user result before following further connections.']),
('p','A missing purpose explanation means someone still needs to supply it. Ask the author for the intended user, the task, an example input and the expected result. A plausible control name does not establish its purpose.'),
('h','Choose the next question'),
('p','How it starts introduces initialization. Follow an action connects screen events to operations. Decisions and loops explains choices and repetition. Inputs and results follows information, while How the parts fit introduces units. Each topic includes an exercise to check your understanding.'),
('p','Questions and answers presents saved replies and questions still to ask. Delphi terms explains programming words in ordinary language. Business glossary, in the top-right selector, contains terms particular to the selected application.'),
('h','Keep the first lesson small'),
('p','Explain one action in your own words: what starts it, what information it uses, what decision changes its path, and what result the user should check. Return to Start here when you need another route through the material.')]),
('Follow an action',[
('h','From a control to the responding operation'),
('steps',['Open Learn the project and choose Screens and actions or Follow an action.',
'Follow a control or event link. In Explain, read the selection name and role. An event connects an action, such as a click, to a responding operation.',
'Follow the responding operation. Read its supplied purpose, then Follow what happens next.',
'Read Choices and stopping points when present. Compare its actual condition with the explanation of the alternatives.',
'Follow one next operation and describe why the application needs that work. Use Back to return.']),
('p','An object with no supported next connection may still do useful work. Ask the author or inspect the related source with someone who understands it.'),
('h','Open deeper detail when it answers your question'),
('p','Optional: read the code walkthrough and source details expands the supporting source explanation, trace and diagram. Keep it closed while learning the user task. An uncertain connection needs checking; a diagram describes possible paths rather than a recording of a successful run.'),
('p','The left object list finds names directly. Double-click an object to open its explanation. The labeled Selection details pane identifies the selection when visible. Drag the dividers to resize the panes. In a restored window, scroll the command strip if a button is outside the visible width.')]),
('Learn a task',[
('h','Follow the prepared steps'),
('steps',['Choose Learn a task in the top-right selector.',
'Select a saved task from the left list. Type part of its name to narrow the list. More tasks loads another page when available.',
'Read the purpose, contributor, review state and Before you begin. Check the prerequisites.',
'Read the action and its expected result. Scroll within the instructions to see the result and further material.',
'Click Next step to continue. Previous step returns to an earlier instruction; Start again returns to the first step.',
'At the last step, compare the overall expected result and read the recovery and practice instructions. Explain how you would recognize a correct outcome.']),
('image',('docs/lesson-preparation-task-reader-compact.png','The actual DPH task reader showing a two-step training example. Navigation stays available while the instructions scroll.')),
('h','Know where the task happens'),
('p','DPH displays instructions; it does not perform the task in the selected application. If practice requires running that application, use the environment and example data approved by its owner. Instructions should identify what is safe to try and what result to expect.'),
('p','If the list is empty, ask the preparer to add a common task. Older free-text instructions remain readable, but DPH does not invent steps for them. Instructions awaiting review remain visibly attributed to their contributor.')]),
('Explore screens and terms',[
('h','Recognize the two kinds of image'),
('p','Form designs reconstruct controls from the saved layout. They help identify names and connections, but styles, custom controls and runtime changes can make the running screen look different. Screenshots contains separately supplied images. Read the contributor and caption before treating an image as the current screen.'),
('steps',['Choose Form designs for a saved layout, or Screenshots for supplied images.',
'Select the form or image. Use the available fit, native-size or zoom controls to make the relevant area readable.',
'Open a control explanation. Read any saved label, typing guidance, input limit or availability information.',
'Relate that information to the task. Ask about behavior that changes while the application runs.']),
('h','Learn the vocabulary'),
('p','Choose Business glossary and search for a term used in the task. Read its definition, aliases and application context. A definition awaiting review still needs checking. Use Delphi terms in Learn the project for words such as form, event, procedure and unit.'),
('h','Supply a useful screenshot'),
('p','The preparer can choose Screenshots, enter a named contributor and a caption describing the context, and click Import PNG to select an existing PNG. Select the relevant object first if the image should be associated with it. DPH copies the image into managed storage; it does not automatically launch or capture the selected application.')]),
('Prepare useful lessons',[
('h','Describe the application'),
('image',('docs/learning-guides-prepare-lessons.png','Prepare lessons provides direct buttons for the application description and task instructions. Source reading settings start collapsed.')),
('steps',['Open the application lessons and click Prepare lessons.',
'Click Describe this application. Enter the contributor and a purpose explaining who uses the application and what it helps them accomplish.',
'Complete relevant ownership, support and architecture information. Leave genuinely unknown answers marked Unknown.',
'Click Apply to Knowledge draft. This returns to Saved explanations. Click Save there. Applying the dialog alone does not save it.']),
('h','Prepare a common task'),
('steps',['In Prepare lessons, click Prepare task instructions. Alternatively, choose Prepare a new task in Learn a task.',
'Enter the contributor, task name, what the learner will accomplish and the prerequisites.',
'Describe the whole task result, recovery guidance and a practice exercise. Enter Unknown for a result that needs confirmation.',
'Scroll to Steps in the order the learner follows. Click New step, enter the action and expected result, then Keep step.',
'Repeat for each step. Select a step to edit it. Keep step accepts the edit; Undo step edit discards the unsaved step edit. Move up and Move down reorder steps. Remove step removes the selected step from this draft.',
'Click Save task. DPH saves the instructions and returns to their first step in Learn a task. Cancel changes discards the task draft.']),
('p','Keep one action and one observable result in each step. Explain what to do when the result differs. A saved task retains its name; create a new task when you need a different identity.'),
('h','Explain a button or business term'),
('p','Choose Action purposes in the preparation selector, select an action and open its editor. Supply the user purpose and instructions, click Apply explanation draft, then Save in Saved explanations. For a term, choose Business glossary, New term, complete its definition and context, then Apply to Knowledge draft and Save.')]),
('Ask questions and review answers',[
('h','Record an author answer'),
('steps',['Click Prepare lessons and choose Author questions in its selector, or follow Open Author questions from Questions and answers.',
'Select a question and read its prompt. Inspect evidence opens supporting source detail when needed.',
'Click Record author answer. In Saved explanations, enter the contributor and write the reply after Answer:. Keep the question for context.',
'Click Save. Return to Learn the project, Questions and answers to read the reply.']),
('h','Save another explanation'),
('p','In Saved explanations, click New. Enter a descriptive title, named author and explanation. Choose a suitable kind, such as user_help or troubleshooting, then Save. Selecting a saved explanation displays its content for editing. Saving an edit creates a new revision and preserves the previous one.'),
('h','Review separately'),
('p','Saving does not mean someone checked the explanation. A knowledgeable reviewer should compare it with source or an approved example, select the saved record, enter their own name and choose Verify review. Current-source verification needs attached, current source. Rejected or retired records remain in history and are not presented as current task lessons.'),
('p','Source changes can make an explanation need review again. Refreshing source cannot confirm business knowledge. If DPH asks you to save or discard a draft before switching, finish that draft or discard it explicitly.')]),
('Share and preserve lessons',[
('h','Create a learning edition'),
('steps',['Save open lesson edits. Click Prepare lessons and choose Publish.',
'Click Share lessons. In the save dialog, choose a location outside the selected application source folder and enter a new folder name. Do not choose an existing destination.',
'Wait for the saved-edition message, then click Preview lessons.',
'Open learning.html in the resulting folder to read it in a browser. Start here begins the route; Task walkthroughs contains supplied ordered instructions.',
'Share the whole folder. Keep objects, assets and images together so its links and screenshots work.']),
('p','The edition is read-only. Change explanations in DPH, then create a new edition. Optional publication settings narrow the audience or scope. Read the resulting material before sharing it, particularly when the application contains sensitive information.'),
('h','Preserve the editable lessons'),
('p','The .dphdb file contains the lessons and authored knowledge. Keep its adjacent .dphdb.views folder because it can hold managed images and other material. Close DPH before copying these files to a safe location. An exported edition is useful for reading but does not replace the editable store.'),
('h','Use the printable guides'),
('p','The DPH package includes this User Guide as an editable document and a PDF. A learning edition also contains guides about the selected application. Its linked HTML provides the most direct route through objects and images. Build and optional PDF conversion instructions are in the Engineering Guide.')]),
('Solve problems and check learning',[
('h','When an explanation is missing'),
('p','No task supplied means someone has not prepared instructions. No purpose supplied means the introduction or action needs an answer. Some code could not be explained means DPH could not establish all relevant source connections. Ask the preparer to check missing files and source settings, and record the unresolved question.'),
('h','When a file or page will not open'),
('p','If Choose application rejects the selection, check that you chose the intended project rather than DPH itself. If saved lessons will not open, check the filename, access permissions and adjacent material. Preserve the last readable copy while the preparer investigates.'),
('p','If an embedded page is unavailable, use its native text explanation where provided. Open an exported edition independently through learning.html. The preparer can check Microsoft WebView2 Runtime and the supplied loader. If an export destination exists, choose a new folder name.'),
('h','A repeatable learning exercise'),
('steps',['Open a supplied application and read its purpose. State its intended user and the problem it solves.',
'Choose a common task and describe its prerequisites. Read the steps and identify the final result.',
'Follow a related screen action into Explain. Identify the responding operation and one actual decision or next operation.',
'Read a supplied screenshot or form design and explain which kind of image it is.',
'Find a business term or author answer that clarifies the task. Write down a remaining question.',
'Create an edition, open learning.html and follow the same object link. Confirm the task and expected results are present.']),
('p','You have learned this route when you can explain the task and its outcome without merely repeating control names. Take the remaining question to someone who knows the application, save the answer and revisit the lesson.')])]

ENGINEERING=[
('Purpose and architecture',[
('h','The learning contract'),
('p','Delphi Project Handoff (DPH) is an independent FireMonkey desktop application for learning one selected Delphi application or project group. Its primary interface presents purpose, screens, actions, guided tasks and attributed answers. Source analysis supports that learning route. Preparation detail should answer a question or help produce reliable lessons.'),
('h','Main responsibilities'),
('p','DPH.UI.Main.pas and its .fmx resource own navigation and native editors. DPH.Workspace.Worker.pas performs background capture, opening, saving and publication. DPH.Project.Analysis.pas orchestrates bounded read-only inventory and parsing. DPH.Analysis.Symbols.pas resolves supported relationships. DPH.Storage.Database.pas persists coherent source generations and immutable authored revisions.'),
('p','DPH.Workspace.Model.pas provides the captured view and typed task contract. DPH.Analysis.Explanations.pas generates beginner topics and object explanations from selected facts. DPH.Publish.Model.pas builds scoped, redacted publication data. DPH.Publish.Export.pas renders learning pages, technical indexes and editable guides. DPH.Publish.BrowserPolicy.pas restricts local navigation.'),
('h','Data route'),
('p','Selection leads to bounded input acquisition, syntax and relationship analysis, then coherent database publication. Captured facts and authored knowledge feed explanations. Native readers and exported pages use that material. Human instructions survive source reassessment.')]),
('Source and storage boundaries',[
('h','Read without executing the selected application'),
('p','Discovery follows the selected project and permitted dependencies. It reads source and form resources without compiling the target, loading its component classes, running scripts or contacting live services. Missing input and unsupported syntax produce diagnostics. Supported source relationships remain distinguishable from uncertain or inferred behavior.'),
('h','Persist reliable lessons'),
('p','Each selected project has a .dphdb SQLite store accessed through FireDAC, with numbered migrations under migrations. The workspace catalog remembers locations and preferences separately. Managed .dphdb.views material travels beside its database. Generation publication is atomic; failure or interruption preserves the last usable generation.'),
('p','SaveKnowledge uses expected revision values to prevent stale editors overwriting newer content. Edits and reviews create immutable history. learning_lesson records have a stable identity, six named fields and ordered action/expected_result steps. Storage validates their canonical body, contributor, scope and identity. Legacy free text retains its original instructions.'),
('h','Retain truthful explanations'),
('p','Hashes and source ranges identify evidence. They do not establish a successful run or a correct business rule. Rendering a lesson or hiding a page must not clear partial coverage. Preserve pending contributions and Unknown fields until someone supplies or verifies the missing knowledge.')]),
('Native interface and lesson generation',[
('h','Keep forms editable'),
('p','Open DPH.UI.Main.fmx and dedicated dialog forms in RAD Studio. Change layout, captions, margins, fonts and control properties in the Object Inspector. Ordinary forms must use serialized controls. HTML is a generated view hosted by serialized browser controls, with native text where supported.'),
('h','Separate learning and preparation'),
('p','LessonPageCombo contains learner destinations. SetupTab holds preparation, with source settings collapsed in AnalysisSettingsExpander. WorkspacePageChange builds optional reports on demand. Opening lessons should not build every report for hidden pages.'),
('p','TaskTab presents saved instructions one step at a time. TaskEditorTab holds fields and the ordered draft. Keep step accepts a step edit; Save task persists the whole record through the worker and returns to the reader. Protect drafts during opening and saving. A failed save must retain entered instructions.'),
('h','Generate from selected facts'),
('p','LessonHTML supplies twelve topics. ObjectLessonHTML introduces the selected object, linked human purpose, actual choices and bounded next connections. The source walkthrough remains optional. The native text fallback uses the same lesson. Unlinked global notes must not masquerade as the purpose of every object.')]),
('Build and run DPH',[
('h','Development requirements'),
('p','Use Windows, RAD Studio 37.0 with Delphi and FireMonkey, FireDAC SQLite support and Microsoft WebView2 Runtime for embedded pages. Build scripts initialize the compiler environment through rsvars.bat. Debug and Win32 is the validated desktop configuration; other builds need their own validation.'),
('h','Build from source'),
('steps',['Open an elevated Windows command prompt so RAD Studio can read its environment settings.',
'Change to the DPH source root containing DelphiProjectHandoff.dproj and tools.',
'Run tools\\build-wp0.cmd. It builds under bin\\Win32\\Debug and runs the serialized FMX resource and binding baseline.',
'Require a zero exit code and PASS WP0-TEST. Investigate the first error if compilation fails.',
'Start bin\\Win32\\Debug\\DelphiProjectHandoff.exe from the source tree. Keep WebView2Loader.dll beside it; its migration search locates the supplied migrations folder.']),
('h','Use the IDE'),
('p','Open DelphiProjectHandoff.dproj, select Debug and Win32 and inspect the main form before building. If a running DPH instance locks the output, check for unsaved edits, close that instance and rebuild. Do not close unrelated applications to solve a build failure.')]),
('Validate a change',[
('h','Run meaningful checks'),
('p','Native regressions instantiate serialized forms and use real WebView2 rendering. Persistence checks use disposable databases. Test fixtures are copies or designated samples; selected application sources must remain unchanged. Automated checks do not constitute independent beginner acceptance.'),
('steps',['Run tools\\build-wp0.cmd for the application and form baseline.',
'Run tools\\build-learning-refocus.cmd. Its optional argument is a prepared reference .dphdb; omit it for the small-fixture checks.',
'Run tools\\build-guided-tasks.cmd followed by a new disposable database path outside the source fixture folder. It checks ordering, saving, reopening and task export.',
'Run tools\\build-wp6.cmd for publication, redaction, navigation and integrity. Run tools\\build-phase1.cmd when changing the project profile.',
'Read final PASS lines and process exit codes. Resolve failures before committing. Add the appropriate analyzer or storage suite when those contracts change.']),
('h','Check the learning route'),
('p','Open a representative application. Read its purpose, follow a screen event, inspect a decision and read a prepared task. Save and reopen an answer. Export and follow the same object from learning.html. Check maximized and restored windows for readable labels, scrolling and expected results.'),
('h','Contain disposable output'),
('p','Keep validation output under bin in clearly designated folders. Retain failure evidence until diagnosed, then remove obsolete generated workspaces. Preserve one reusable reference cache where useful. Never delete source fixtures, owner databases or authored material while cleaning tests.')]),
('Package and deploy',[
('h','Create the desktop folder'),
('p','The package needs DelphiProjectHandoff.exe, WebView2Loader.dll, migrations, help, current guides and Databases instructions. DPH.ValidateHandoff.exe is an included technical validation tool. Microsoft WebView2 Runtime is a system prerequisite separate from its loader DLL.'),
('steps',['Build and validate the application and publication validator.',
'Run tools\\package-dph.ps1 through PowerShell with ExecutionPolicy Bypass. It creates a new versioned staging folder and refuses an existing one.',
'Verify the checksum report and extract the ZIP into a different local folder.',
'Start the extracted executable and confirm Getting started, native controls and migration discovery. Use only a disposable database for this deployment check.',
'Check the package contains current guides and help, with no owner databases, private documents, development history or personal path references.']),
('h','Give recipients plain directions'),
('p','Tell recipients to extract the package, open its folder and double-click DelphiProjectHandoff.exe. The User Guide describes deployed files and visible controls. Compiler configuration belongs in this Engineering Guide. Describe source locations with relative project paths.')]),
('Publication and privacy',[
('h','Publish learning first'),
('p','learning.html combines twelve topics, supplied tasks, answers, images and business terms. Hash-named object pages begin with beginner explanations and retain optional source detail. index.html and JSONL files support technical inspection. Native Preview lessons opens learning.html.'),
('p','Render from a scoped, redacted TDPHDocumentModel. Filter excluded files and unavailable links before rendering, and encode contributed prose as text. Screenshots remain contributor-supplied material. Source navigation and generated agent instructions require explicit options.'),
('h','Validate an edition'),
('p','Run DPH.ValidateHandoff.exe with the edition folder and a separately retained trusted input fingerprint. The default rejects stale or partial material. --allow-stale permits historical integrity inspection without changing that status. The checksum index detects modifications; it does not authenticate an unknown author.'),
('h','Create PDF companions'),
('p','tools\\export-pdf.ps1 accepts -BundleDirectory for an edition. It uses LibreOffice, populates changeable contents fields and refreshes checksums. tools\\build-guides.py rebuilds DPH\'s manuals and matching HTML help. Inspect every rendered page after a layout-sensitive edit.')]),
('Maintain the learning product',[
('h','Plan a focused change'),
('p','Begin with a learning problem: an unclear task, an unexplained control or an unanswered question. Locate the native form and responsible model. Reuse save and publication contracts rather than creating another administrative system. Keep the learner route concise and supporting detail optional.'),
('h','Protect the data'),
('p','Take the required verified backup before approved changes and synchronize the configured Git repositories after validated commits. Development backup locations belong to the environment, not the User Guide. For storage or migration changes, verify old databases open and authored revisions survive.'),
('h','Investigate failures'),
('p','For preparation failure, inspect the first diagnostic, missing files, scope and intended defines. For a save conflict, reopen the latest revision and reconcile the contribution. For a browser failure, check WebView2 Runtime and loader availability and use native text. For broken sharing links, regenerate from the scoped model and validate the edition.'),
('h','Maintain the manuals'),
('p','Update instructions from serialized controls, source and observed behavior. Use real screenshots with clear example captions. Remove obsolete names and personal paths. Refresh the contents and PDF, inspect every page and package only current guides. Keep requirement audits and test history separate from end-user instruction.')])]

def field(p,kind,text=None):
 run=p.add_run();node=OxmlElement('w:fldChar');node.set(qn('w:fldCharType'),kind);run._r.append(node)
 if text:
  node=OxmlElement('w:instrText');node.set(qn('xml:space'),'preserve');node.text=text;run._r.append(node)

def build(filename,title,subtitle,chapters):
 doc=Document();section=doc.sections[0]
 section.page_width=Inches(8.5);section.page_height=Inches(11)
 section.top_margin=section.bottom_margin=Inches(.75);section.left_margin=section.right_margin=Inches(.8)
 for name in ['Normal','Title','Subtitle','Heading 1','Heading 2','Caption']:
  style=doc.styles[name];style.font.name='Calibri';style.font.color.rgb=RGBColor(0,0,0)
 doc.styles['Normal'].font.size=Pt(11);doc.styles['Normal'].paragraph_format.space_after=Pt(7);doc.styles['Normal'].paragraph_format.line_spacing=1.08
 for name,size in [('Title',30),('Subtitle',14),('Heading 1',19),('Heading 2',13),('Caption',10)]:doc.styles[name].font.size=Pt(size)
 for name in ['Heading 1','Heading 2']:
  doc.styles[name].paragraph_format.keep_with_next=True;doc.styles[name].paragraph_format.space_before=Pt(12)
 for border in list(doc.styles.element.iter(qn('w:pBdr'))):border.getparent().remove(border)
 doc.core_properties.author='';doc.core_properties.last_modified_by='';doc.core_properties.title=title;doc.core_properties.subject=subtitle;doc.core_properties.keywords='';doc.core_properties.comments=''
 doc.add_paragraph(title,'Title');doc.add_paragraph(subtitle,'Subtitle');doc.add_paragraph('Experimental Windows desktop software');doc.add_paragraph('Last changed '+CHANGED)
 doc.add_paragraph('Read in order for your first session. Later, use the contents to find a particular procedure.')
 doc.add_page_break();doc.add_paragraph('Contents','Title');field(doc.add_paragraph(),'begin',' TOC \\o "1-1" \\h \\z \\u ');field(doc.add_paragraph(),'separate')
 for title,_ in chapters:
  p=doc.add_paragraph(title);p.paragraph_format.space_after=Pt(6)
 field(doc.add_paragraph(),'end')
 for title,blocks in chapters:
  heading=doc.add_heading(title,1);heading.paragraph_format.page_break_before=True
  for kind,value in blocks:
   if kind=='h':doc.add_heading(value,2)
   elif kind=='p':doc.add_paragraph(value)
   elif kind=='steps':
    for i,step in enumerate(value,1):
     p=doc.add_paragraph();p.paragraph_format.left_indent=Inches(.18);p.paragraph_format.first_line_indent=Inches(-.18);p.add_run(str(i)+'. ').bold=True;p.add_run(step)
   elif kind=='image':
    image,caption=value;p=doc.add_paragraph();p.paragraph_format.keep_with_next=True
    picture=p.add_run().add_picture(str(ROOT/image),width=Inches(6.4));picture._inline.docPr.set('descr',caption);doc.add_paragraph(caption,'Caption')
 footer=section.footer.paragraphs[0];footer.add_run('Delphi Project Handoff    ');field(footer,'begin',' PAGE ');field(footer,'separate');footer.add_run('1');field(footer,'end')
 setting=OxmlElement('w:updateFields');setting.set(qn('w:val'),'true');doc.settings.element.append(setting)
 doc.save(ROOT/'docs/guides'/filename)

def help_page():
 content=['<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Delphi Project Handoff User Help</title><style>body{font:18px/1.6 Segoe UI,Arial,sans-serif;max-width:1000px;margin:auto;padding:24px;color:#20364a;overflow-wrap:anywhere}h1,h2,h3,a{color:#146cb4}header{border-top:5px solid #f28c28}img{max-width:100%;height:auto}li{margin-bottom:12px}section{margin:32px 0}nav a{display:block}@media print{nav{display:none}}</style></head><body><header><h1><span class="notranslate" translate="no">Delphi Project Handoff</span> User Help</h1><p>Learn an unfamiliar application one task at a time.</p></header><nav>']
 for i,(title,_) in enumerate(USER):content.append(f'<a href="#chapter_{i}">{html.escape(title)}</a>')
 content.append('</nav>')
 for i,(title,blocks) in enumerate(USER):
  content.append(f'<section id="chapter_{i}"><h2>{html.escape(title)}</h2>')
  for kind,value in blocks:
   if kind in ['h','p']:
    tag='h3' if kind=='h' else 'p'
    prose=re.sub(r'DelphiProjectHandoff\.exe|\.dphdb(?:\.views)?|learning\.html|\bDPH\b|Choose application|Open saved lessons|Prepare lessons|Learn the project|Learn a task|Share lessons|Preview lessons',lambda m:'<span class="notranslate" translate="no">'+m[0]+'</span>',html.escape(value))
    content.append(f'<{tag}>{prose}</{tag}>')
   elif kind=='steps':
    content.append('<ol>')
    for step in value:
     prose=re.sub(r'DelphiProjectHandoff\.exe|\.dphdb(?:\.views)?|learning\.html|\bDPH\b|Choose application|Open saved lessons|Prepare lessons|Learn the project|Learn a task|Share lessons|Preview lessons',lambda m:'<span class="notranslate" translate="no">'+m[0]+'</span>',html.escape(step))
     content.append('<li>'+prose+'</li>')
    content.append('</ol>')
   elif kind=='image':
    image,caption=value;target=ROOT/'help/assets'/Path(image).name;target.parent.mkdir(exist_ok=True);target.write_bytes((ROOT/image).read_bytes());content.append('<figure><img src="assets/'+target.name+'" alt="'+html.escape(caption)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>')
  content.append('</section>')
 content.append('<p>Optional translation requires an internet connection. Product names and code names retain their original spelling.</p><div class="gtranslate_wrapper"></div><script>window.gtranslateSettings={default_language:"en",languages:["en","es","fr","de","it","pt","nl"],wrapper_selector:".gtranslate_wrapper",switcher_horizontal_position:"right",switcher_vertical_position:"top"};</script><script src="https://cdn.gtranslate.net/widgets/latest/float.js" defer></script><script src="assets/translation-selector.js" defer></script></body></html>')
 (ROOT/'help/index.html').write_text('\n'.join(content),encoding='utf-8')

if __name__=='__main__':
 build('DPH_User_Guide.docx','Delphi Project Handoff User Guide','Learn an application and prepare useful lessons',USER)
 build('DPH_Engineering_Guide.docx','Delphi Project Handoff Engineering Guide','Build maintain and validate the learning application',ENGINEERING)
 help_page()
 sources={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in list(ROOT.glob('DPH.*.pas'))+list(ROOT.glob('DPH.UI.*.fmx'))+[ROOT/'DelphiProjectHandoff.dproj']}
 (ROOT/'docs/guide-source-validation.json').write_text(json.dumps({'guide_version':40,'last_changed':date.today().isoformat(),'sources':sources,'basis':'Inspected native controls source and behavior'},indent=2)+'\n',encoding='utf-8')
 print('Created current manuals and matching HTML help')
