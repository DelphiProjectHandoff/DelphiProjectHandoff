# Delphi Project Handoff

Experimental Windows desktop software for understanding one selected Delphi application through captured source evidence and attributed knowledge. DPH reads the selected project without compiling or executing it. The converter reference is passive test input, never a build or runtime dependency.

The owner rejected the original WP7 experience as inadequate. The 11 October 2026 rework adds first-launch education, eleven project learning topics, readable object explanations, source comments, event/callback traces, labeled procedure diagrams, attributed screenshot imports and corresponding publication. The previous blanket completion statement is withdrawn. [The plan comparison](docs/Rework_Requirements_Audit.txt) identifies the remaining requirements; historical WP reports are not acceptance of the rework.

## Run

1. Run `bin\Win32\Debug\DelphiProjectHandoff.exe`, or extract the latest experimental binary ZIP from `export` to a writable folder and run its executable.
2. Read **Getting started**, which opens at launch. Keep the deployed `help`, `migrations` and `WebView2Loader.dll` files with the executable. Microsoft WebView2 Runtime enables embedded pages; native text remains available as a fallback.
3. Choose the intended configuration and platform; enter required compiler defines. Choose **Attach project**, select its project file and save its `.dphdb` database outside the selected source tree.
4. Start with **Learn the project → How the program starts**. Choose a control under **Screens and user actions**, follow its event, and read **Explain**. Compare its decisions and connections with **Source** and **Graphs**.
5. Preserve missing business explanations in **Knowledge** with a named author. Use **Publish** to create a scoped offline handoff after reviewing exclusions and private information.

DPH opens maximized. The right-hand **Selection details** pane identifies the object you double-click in the far-left list; its text wraps and scrolls vertically. Click the central **Explain** tab for behavior or **Source** for code. The **status line** is along the bottom edge of the window. For analysis gaps, click the central **Learn the project** tab, then **Coverage and troubleshooting** in that tab's topic list. In a smaller restored window, the horizontal scrollbar below the top command buttons reveals commands that do not fit.

**Form designs** are approximate serialized reconstructions. **Screenshots** displays actual PNG images explicitly imported by a contributor, retaining their generation and unverified attribution. DPH does not run the input application to obtain screenshots.

For the pinned converter example, select `samples\reference-vcl2fmx-v6.0.0\VCL2FMXConverter.dproj`, Debug / Win32, with extra defines `MSWINDOWS;WIN32`. The reference remains PARTIAL; missing dependencies and unsupported syntax are visible gaps.

Full directions and exercises: [User Guide DOCX](docs/guides/DPH_User_Guide.docx), [User Guide PDF](docs/pdf/DPH_User_Guide.pdf), and [local HTML help](help/index.html). Developers should also read the [Engineering Guide](docs/guides/DPH_Engineering_Guide.docx).

## Build and test

Open `DelphiProjectHandoff.dproj` in RAD Studio. Controls and properties are serialized in `DPH.UI.Main.fmx` and editable in the Object Inspector. From an elevated PowerShell prompt in this folder:

```powershell
cmd /c tools\build-wp0.cmd
powershell -NoProfile -ExecutionPolicy Bypass -File tools\validate-rework.ps1
```

The first command builds the Win32 Debug application and checks its FMX resource. The second runs the serial storage, discovery, semantics, workspace, knowledge, publishing, hardening and learning suites. It preserves historical phase reports, writes `docs/rework-*` evidence and verifies the pinned source and original instructions remain unchanged. It needs the pinned reference already present and may take several minutes. Test data stays under ignored `bin` directories.

For focused learning tests, use `cmd /c tools\build-learning.cmd`, optionally followed by a saved pinned-reference `.dphdb` path. To validate a bundle, run `DPH.ValidateHandoff.exe <bundle> <trusted fingerprint>`; `--allow-stale` permits integrity inspection of explicitly historical/partial bundles.

The installed RAD Studio toolchain is `C:\Program Files (x86)\Embarcadero\Studio\37.0\bin`; scripts load its `rsvars.bat`. Guide generation uses the owner's Python 3.13 and LibreOffice. Online translation, external AI and runtime instrumentation remain disabled pending their distinct decisions and authorization.
