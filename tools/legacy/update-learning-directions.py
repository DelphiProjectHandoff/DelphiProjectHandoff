from pathlib import Path
root=Path(__file__).resolve().parents[2]
text='''RUN AND TEST DELPHI PROJECT HANDOFF
Last changed 13 October 2026

START THE SUPPLIED APPLICATION
1. Extract the entire ZIP into a local folder where you can save files.
2. Open that extracted folder and double-click DelphiProjectHandoff.exe.
3. Keep its migrations, help, docs, samples and loader beside the executable.
   The window opens maximized. Getting started explains the first session.

BEGIN WITH THE SUPPLIED PRACTICE EXAMPLE
4. Click Try practice example in the command strip at the top.
5. Wait for Learn the project and read Start here. The example calculates a
   practice total; it saves no orders or payments. DPH does not launch it.
6. Choose Learn a task in the top-right selector. Enter New learner in User
   role and First day in Learning path. Scroll the task list if necessary.
7. Select Meet the practice application. Open Before you begin and task
   context. Read the purpose and prerequisites, then collapse that section
   to give the steps more space.
8. Read the action and expected result. Use Next step and Previous step.
   Scroll the instruction area or its text boxes if more text is below.
9. Continue with Predict a total without tax, Compare the tax alternatives,
   and Understand an input error safely, in that order.
   Worked answers for quantity 2 and price 10.00 are 20.00 without tax and
   22.00 with the example tax. Quantity 2.5 is invalid: only whole items
   from 1 to 1000 are accepted. These exercises can be completed by reading.

SAVE AND CHECK YOUR PLACE
10. Enter your name in Your name for saved progress.
11. After checking the current result, click I checked this result. The count
    increases by one and the next action appears.
12. Select another task, then return using the same name. The next unchecked
    step should appear. Start again returns to the first step without erasing
    checks. Clear my progress resets your own checks. Scroll the button strip
    horizontally if a button is outside the visible width.
    Checks are your record, not proof of mastery or a recorded application run.

READ A FIELD GUIDE AND FOLLOW ITS ACTUAL CONNECTION
13. Choose Learning library. Search for Quantity: and select Quantity: how
    many whole items. Read its meaning, example, limits, safe help and practice
    answer. Scroll within the reading area to see the complete explanation.
14. Click Explore related selection. Explain opens the captured control.
    Read its role and saved guidance. Keep optional source detail closed until
    it answers your question. Return through the top-right selector.
15. In Learning library search for Why did changing a field. Read why the
    Calculate total button must be used after changing an input.
16. Choose Screenshots. Select Sample output on the left. Read the actual
    native sample image and its numbered result explanation. Use Fit, Native
    pixels or Custom zoom to make the relevant detail readable.

PREPARE AN EXPLANATION AND A PICTURE CALLOUT
17. In Learning library click Prepare an explanation. Choose a teaching topic.
18. Enter your contributor name, topic name, user role or All learners,
    meaning, worked example, limits, safe help and practice with its answer.
    Enter Unknown where an answer has not yet been obtained.
19. Click Save explanation. Find and read it in the library. Edit explanation
    opens the existing fields; Cancel changes discards the current draft.
20. To explain a picture point, choose Screenshots, select a picture, click
    its relevant point, then Explain this point. Complete the teaching fields
    and Save explanation. Reselect the picture to read its numbered legend.
    The original picture remains unchanged.

PREPARE A TASK AND LEARNING PATH
21. Click Prepare lessons, then Prepare task instructions.
22. Enter your contributor name, task name, purpose, prerequisites, overall
    result, recovery guidance and practice exercise with an expected answer.
23. Optionally enter a User role and Learning path name. Set Lesson order
    to a whole number from 1 to 10000; lower numbers appear first in the path.
24. Scroll to the steps. Click New step, enter an action and expected result,
    then Keep step. Add another step in the same way.
25. Click Save task. Learn a task opens the saved instructions. Compare the
    actions and results with what you entered. Edited instruction revisions
    require fresh checks rather than inheriting old completion.

SHARE AND REOPEN THE LESSONS
26. Click Prepare lessons and choose Publish in its page selector.
27. Click Share lessons and choose a NEW folder outside the source folder.
28. Wait, then click Preview lessons. The edition starts at learning.html.
    Check tasks, explanations, pictures and links. Keep the whole edition
    folder together when sharing it.
29. Close and reopen DPH. If necessary, use Open saved lessons and select the
    same .dphdb in Databases. Keep its adjacent .dphdb.views folder with it.
    Check that your authored content and same-name progress are retained.

STUDY YOUR OWN APPLICATION
30. Click Choose application. Select the intended Delphi .dproj, .dpr or
    .groupproj file supplied by that application's owner.
31. Accept its proposed .dphdb in Databases, outside the selected source.
32. Read Learn the project and follow one screen action. Use Learning library,
    Learn a task, Business glossary and Search project for supplied material.
33. If purpose, field meanings, tasks or business answers are missing, have
    someone who knows that application prepare them. DPH discovers supported
    source connections; it cannot invent unwritten procedures or business facts.

EXPECTED LEARNING RESULT
Explain the application's purpose, name a task's inputs and expected result,
describe one choice, interpret an example output and explain one input error.
Use the supplied practice values to check your answers before studying another
application. Independent beginner acceptance is a separate human exercise;
automatic test success does not prove a person's understanding.

WHEN SOMETHING IS UNAVAILABLE
Some code could not be explained means the preparer should check missing files
or source settings. Leave advanced settings to that person. If embedded pages
fail, check Microsoft WebView2 Runtime and use available native text or the
shared learning.html. Do not delete your last readable lesson database.

The User Guide gives complete illustrated procedures. Source-build and automated
check directions are in the Engineering Guide and Developer_Test_Directions.txt.
'''
(root/'docs/guides/Run_And_Test.txt').write_text(text,encoding='utf-8')
(root/'docs/guides/Workspace_Operations.txt').write_text('''FIND YOUR WAY AROUND DELPHI PROJECT HANDOFF

Start with Try practice example. Its First day path, field guides, worked
totals, error explanations and native pictures demonstrate how to learn an app.
Choose application opens your own source. Open saved lessons reopens a .dphdb;
keep its adjacent .dphdb.views folder with it.

The top-right selector opens Learn the project, Learn a task, Learning library,
Explain, Form designs, Screenshots, Graphs, Business glossary, Search project
and Saved explanations. Getting started returns to introductory directions.

Learn a task provides roles, learning paths and ordered actions/results. Open
Before you begin and task context for prerequisites. Enter your name to save
checked-step progress. I checked this result records a check; Next step only
navigates. Clear my progress resets your own checks.

Learning library presents meanings, worked examples, limits, safe help and
practice answers for the selected application. Prepare an explanation and Edit
explanation open its native teaching editor. Save explanation persists it and
returns to the reader. Saving a contribution does not perform independent review.

Screenshots contains supplied screenshots, sample outputs and teaching pictures.
Click a point and Explain this point to prepare an anchored callout. The original
image stays unchanged. Form designs remain clearly labeled reconstructions.

Prepare lessons contains descriptions, tasks and other lesson material. Advanced
source settings begin collapsed. Profile, action-purpose and glossary dialogs
Apply to a draft; click Save in Saved explanations to keep those drafts. Save
task and Save explanation save directly to their readers.

Double-click an object on the left to open Explain. Selection details labels
the right pane. Drag dividers to resize panes. Scroll command strips horizontally
and text/list areas vertically when content is outside the visible view.

Follow Run_And_Test.txt for explicit first-session and repeatable checks.
''',encoding='utf-8')
p=root/'docs/guides/Developer_Test_Directions.txt';old=p.read_text(encoding='utf-8-sig')
old+='''
CURRENT BEGINNER FEATURES
From an elevated RAD Studio command prompt at the source root:
tools\\build-order-sample.cmd validates the designated sample and captures its
actual native screen. It runs only the supplied teaching example, never a
customer application. Rebuilding those pictures requires checking the hashes
in samples\\OrderPractice\\lessons.json before the practice import.

tools\\build-practice.cmd "<new disposable absolute folder>" validates the
practice button, actual source-linked explanations, ordered tasks, progress
and offline teaching edition. Run with a disposable workspace catalog and
restore any original preferences afterward; do not use owner lesson databases.

The revised learning scope is recorded in docs\\Learning_Requirements_Reconciliation.json
and its CSV and text companions. The original requirement ledger remains
unchanged. Scope decisions are distinct from implementation of old technical
requirements. Human learning acceptance remains separately reported.
'''
p.write_text(old,encoding='utf-8')
print('Updated current explicit learning and developer directions')
