# Delphi Project Handoff

Experimental Windows desktop software for understanding one selected Delphi application through captured source evidence and attributed knowledge. DPH reads the selected project without compiling or executing it. The converter reference is passive test input, never a build or runtime dependency.

The owner rejected the original WP7 experience as inadequate. The 11 October 2026 rework adds first-launch education, eleven project learning topics, readable object explanations, source comments, event/callback traces, labeled procedure diagrams, attributed screenshot imports and corresponding publication. The previous blanket completion statement is withdrawn. [The plan comparison](docs/Rework_Requirements_Audit.txt) identifies the remaining requirements; historical WP reports are not acceptance of the rework.

## Run

1. Run `bin\Win32\Debug\DelphiProjectHandoff.exe`, or extract the latest experimental binary ZIP from `export` to a writable folder and run its executable.
2. Read **Getting started**, which opens at launch. Keep the deployed `help`, `migrations` and `WebView2Loader.dll` files with the executable. Microsoft WebView2 Runtime enables embedded pages; native text remains available as a fallback.
3. Choose the intended configuration and platform; enter required compiler defines. Choose **Attach project**, select its project file and save its `.dphdb` database outside the selected source tree.
4. Start with **Learn the project → How the program starts**. Choose a control under **Screens and user actions**, follow its event, and read **Explain**. Compare its decisions and connections with **Source** and **Graphs**.
5. Preserve missing business explanations in **Knowledge** with a named author. Use **Publish** to create a scoped offline handoff after reviewing exclusions and private information.

DPH opens maximized. Click an object in the far-left Explorer to read the labeled **Selection details** pane; its text wraps and scrolls vertically. Choose **Explain**, **Source**, or **Learn the project** in the upper-right page selector. The **status line** is along the bottom edge. Choose **Coverage** for defined static measures, or **Learn the project → Coverage and troubleshooting** for guidance. In a smaller restored window, scroll the command toolbar horizontally to reach commands that do not fit.

**Databases** under the DPH application folder is now the default location for **Save knowledge database** and **Open cache**. For a source checkout this is the top-level `Databases` folder; for an extracted distribution it is beside the executable. Existing databases are not moved. You may browse to another location outside the selected source tree. Keep each database's adjacent `.dphdb.views` folder with it.

DPH rejects its own source project and self-analysis caches, including renamed or relocated copies retaining its project GUID or program declaration. A rejected selection leaves the current workspace intact. A rejected startup cache leaves **Getting started** visible. This is an application selection rule, not an identity/security guarantee for arbitrarily modified source.

**Form designs** are approximate serialized reconstructions. **Screenshots** displays actual PNG images explicitly imported by a contributor, retaining their generation and unverified attribution. DPH does not run the input application to obtain screenshots.

For the pinned converter example, select `samples\reference-vcl2fmx-v6.0.0\VCL2FMXConverter.dproj`, Debug / Win32, with extra defines `MSWINDOWS;WIN32`. The reference remains PARTIAL; missing dependencies and unsupported syntax are visible gaps.

Full directions and exercises: [User Guide DOCX](docs/guides/DPH_User_Guide.docx), [User Guide PDF](docs/pdf/DPH_User_Guide.pdf), and [local HTML help](help/index.html). Developers should also read the [Engineering Guide](docs/guides/DPH_Engineering_Guide.docx).

## Build and test

For the business glossary, choose **Business glossary** in the upper-right workspace selector after opening a project. **New term** opens its editable fields; **Apply to Knowledge draft** prepares a draft, and **Save** on Knowledge persists it. **Open in Knowledge** provides history, source links and named review. Full steps and repeatable checks are in [Business glossary directions](docs/guides/Business_Glossary_Run_and_Test.txt). From an elevated prompt run `cmd /c tools\build-glossary.cmd` for the focused acceptance suite.

Open `DelphiProjectHandoff.dproj` in RAD Studio. Controls and properties are serialized in `DPH.UI.Main.fmx` and editable in the Object Inspector. From an elevated PowerShell prompt in this folder:

```powershell
cmd /c tools\build-wp0.cmd
powershell -NoProfile -ExecutionPolicy Bypass -File tools\validate-rework.ps1
```

The first command builds the Win32 Debug application and checks its FMX resource. The second runs the serial storage, discovery, semantics, workspace, knowledge, publishing, hardening and learning suites. It preserves historical phase reports, writes `docs/rework-*` evidence and verifies the pinned source and original instructions remain unchanged. It needs the pinned reference already present and may take several minutes. Test data stays under ignored `bin` directories.

For focused learning tests, use `cmd /c tools\build-learning.cmd`, optionally followed by a saved pinned-reference `.dphdb` path. To validate a bundle, run `DPH.ValidateHandoff.exe <bundle> <trusted fingerprint>`; `--allow-stale` permits integrity inspection of explicitly historical/partial bundles.

For self-selection, cache/startup rejection, workspace preservation and the Databases defaults, run `cmd /c tools\build-selection.cmd` from this project folder in an elevated PowerShell prompt. It creates isolated fixtures under ignored `bin` directories and restores the remembered startup selection after testing.

The installed RAD Studio toolchain is `C:\Program Files (x86)\Embarcadero\Studio\37.0\bin`; scripts load its `rsvars.bat`. Guide generation uses the owner's Python 3.13 and LibreOffice. Online translation, external AI and runtime instrumentation remain disabled.

**Translations** reads explicitly selected DAT offline packs using independently vendored, licensed reader code from the owner's VCL2FMX reference. Compare saved source and localized prose, resolve source review, then attribute translation approval. In **Publish**, an optional locale includes reviewed exact-revision authored bodies in HTML and editable DOCX; missing or obsolete entries retain labeled source fallbacks. This does not translate all generated guidance or supply a complete language catalog. The French sample contains only three unreviewed phrases.

**Publish** also offers unchecked options for redacted captured-source browsing and generated agent boundaries. Review the output and exclusions before sharing. **Validate bundle** checks a selected root manifest against a separately trusted input fingerprint, without requiring an open database. Historical/partial inspection is an explicit qualification. Full steps are in [Workspace operations](docs/guides/Workspace_Operations.txt).

For keyboard inspection, open a project and choose **Keyboard and focus** in the upper-right selector. Select a component to inspect sibling focus order, readable shortcuts, action references, source evidence and possible conflicts. [Full run and test directions](docs/guides/Keyboard_and_Focus_Run_and_Test.txt) explain all commands and evidence limits. Run tools\build-keyboard.cmd elevated for focused acceptance checks.

For menu and toolbar inspection, choose **Menus and commands**. Select a command to read its menu path, action, shortcut and captured handlers. Scroll its command bar horizontally to choose a handler and click **Explain handler**. [Explicit run and test directions](docs/guides/Menus_and_Commands_Run_and_Test.txt) cover filtering, source navigation and evidence limits. Run `tools\build-commands.cmd` elevated for focused acceptance checks.

Choose **Dynamic controls** to inspect recognized constructor sites and their owner, parent, event and property references. Reassess older captures to obtain the new relationships. Runtime instance counts remain unobserved. [Explicit directions and tests](docs/guides/Dynamic_Controls_Run_and_Test.txt) explain every command. Run `tools\build-dynamic-controls.cmd` elevated for acceptance checks.
