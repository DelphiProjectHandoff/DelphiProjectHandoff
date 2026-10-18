![Delphi Project Handoff](images%20and%20icons/DPH-Logo-Horizontal-720.png)

# Delphi Project Handoff

**Prepare an evidence-based handoff for an unfamiliar Delphi application.**

Delphi Project Handoff (DPH) helps a new maintainer orient themselves when the original developer or documentation is unavailable. It captures project structure, forms, Pascal code, and eligible local documents, then assembles a handoff dossier with source links, uncertainties, and questions for a person who knows the application. It does not compile, run, or change the application being studied. A static trace is evidence to investigate, not proof of runtime behavior or business intent.

DPH is experimental Windows software built with Delphi 13.1. It is not a production 1.0 release.

**Release status (17 October 2026):** **0.8.0.10** is the current packaged experimental release. This repository's current source includes additional save and translation fixes that are awaiting the next package. **Rescan project** checks an attached project for changes without reopening it. An incomplete analysis notice points to Coverage, its diagnostics, and a clear correction and rescan path. The Handoff dossier shows captured project directories and build paths, points to component dependencies, and provides database connection starting templates and unit-level variables. In the current source, Getting started has complete German and Spanish prose, and the handoff dossier's own headings and guidance have Spanish translations. Other languages keep coherent English prose there pending reviewed translations. A centered progress window shows the current step and percentage while DPH prepares or rescans a project. Large projects can take over a minute to prepare; the duration depends on their files and the computer.

## Choose a download

- **Run the packaged 0.8.0.10 experiment:** Download the [Windows ZIP](export/DPH-0.8.0.10-experimental-Windows.zip), extract the whole ZIP, and run `Win64/DelphiProjectHandoff.exe` (or the Win32 edition). Keep the supplied folders together. Microsoft WebView2 Runtime is required for embedded pages.
- **Build editable source:** Download the source distribution matching 0.8.0.10 from its [release page](https://github.com/tmartindub/DelphiProjectHandoff/releases/tag/v0.8.0.10-experimental), or clone this repository for the newer source changes. Install the supplied translation design package in RAD Studio before opening the project's main form in the designer, then open `DelphiProjectHandoff.dproj`. GitHub's **Code → Download ZIP** contains no compiled executable.

The [0.8.0.10 release page](https://github.com/tmartindub/DelphiProjectHandoff/releases/tag/v0.8.0.10-experimental) lists both ZIPs and release notes. The Windows ZIP includes Win32 and Win64 executables; the source ZIP contains editable forms and build inputs. Both include the files needed for DPH's 35 offline interface languages. Earlier releases remain available as historical experiments.

## Build and start from source

1. Clone this repository or extract the release's **source ZIP** into a writable folder. Keep its `dependencies`, `Localization`, `migrations`, `help`, and `images and icons` folders beside the project files.
2. In RAD Studio 37, choose **Component → Install Packages → Add**. Select `export/DAT-component-kit/DelphiProjectHandoff/DesignPackages/Win32/Release/DATLanguageManagerFMXDesign.bpl`, enable the package, and restart RAD Studio if it asks. This registers the two translation controls already placed on the editable main form. [Detailed component-kit steps](export/DAT-component-kit/DelphiProjectHandoff/README.txt) explain the runtime packages and troubleshooting.
3. Open `DelphiProjectHandoff.dproj`. If RAD Studio asks for `TDATFMXLanguageManager` or `TDATFMXLanguageComboBox`, verify that the design package from step 2 is enabled. The project already includes `dependencies/DelphiAppTranslation/source` on its compiler search path; no separate preparation command is required.
4. Build **Win64** or **Win32** in **Debug** or **Release**. Run the matching `bin/<platform>/<configuration>/DelphiProjectHandoff.exe`. Keep `WebView2Loader.dll` beside that executable. Embedded pages also require the Microsoft WebView2 Runtime.

The main form remains editable in the RAD Studio designer. The [run and test directions](docs/guides/Run_And_Test.txt) give a first-use walkthrough.

`tools/package-source-distribution.ps1` creates the editable source ZIP; `tools/package-dph.ps1` creates the matching Windows package and verifies its files after extraction.

## Explore an application

Choose **Open application** and select its `.dproj`, `.dpr`, or `.groupproj` file. DPH keeps a new capture temporary while you explore. Click **Save project** whenever you want to keep it. The save dialog starts in DPH's `databases` folder and suggests a dated filename if that project's name is already taken. A confirmation displays the full saved path. If you close DPH or open another project before saving, choose **Yes** to open the same save dialog, **No** to discard the temporary capture, or **Cancel** to keep exploring. You may choose another location outside the application's source tree. Keep the `.dphdb` and its adjacent `.dphdb.views` folder together. If saving fails, DPH displays the error and retains the temporary capture; it never silently replaces a previous save. Later, **Open saved project** restores the saved analysis and generated screen images. An interrupted SQLite journal may be recovered during opening; keep the database and any adjacent journal together until recovery completes.

While opening a project, DPH shows a separate progress window with the current step and percentage. It reads project startup information from `.dpr` and `.dproj`, identifies forms and controls from `.fmx` or `.dfm`, and traces their event handlers and related `.pas` code. The Learning library reads documents at the selected project's root and in its own top-level `docs`, `Help`, `Guides`, `Manual`, and `Notes` folders. Unrelated parent directories and neighboring release folders are excluded. Supported document types include PDF, DOCX, Markdown, text, HTML, RTF, and ODT. Existing saved projects are reassessed once under this document rule, and excluded document entries are hidden while reassessment runs.

The header's **Read public websites** checkbox controls DPH's optional Internet access. It starts off, and DPH remembers the choice for the current Windows user. When enabled, the next project analysis may read text from up to three eligible public HTTPS pages referenced in project documents, with each response capped at 128 KiB. DPH rejects private IPv4 DNS results and pins each request to the validated public IPv4 address while preserving the original hostname for HTTPS verification. It uses no proxy and does not follow redirects; if Windows cannot apply address pinning, the request is skipped. This requires Windows 10 21H1 or later. When disabled, project discovery reads local material only. Changing the checkbox affects the next analysis; it does not change previously saved evidence. DPH does not offer a general web search engine. The **Close** button exits through the same unsaved-work and in-progress safeguards as the window close control.

DOCX and supported text formats are read directly. Extracting text from PDF, legacy Word, RTF, and several older formats requires LibreOffice at `C:\Program Files\LibreOffice\program\soffice.com`. A scanned image-only PDF may need OCR before it has usable text. The Learning library reports when a discovered file yielded no readable content.

The six primary views in the current source are:

| View | What you can do |
| --- | --- |
| **Getting started** | See how to open a project and move through DPH. |
| **Handoff dossier** | Read a four-part account of purpose evidence, startup and forms, visible command bindings, data and output candidates, and unresolved risks and questions. Each claim is tied to the selected capture or explicitly marked as a reading suggestion. |
| **Learning library** | Read grouped, formatted topics drawn from the project's available documents and screen information. |
| **Project map** | Select units, types, objects, controls, procedures, functions, variables, and their connections; follow links to the relevant detail or screen. Long object names are shortened in the list and available in full on hover and in the detail view. |
| **Screenshots** | Generate design previews on demand from `.fmx` and `.dfm` definitions, including the main form with its initial tab and a separate preview for each saved tab. Previews open at Native pixels for readable detail; scroll to inspect the rest or choose Fit for a whole-form overview. These are form-derived designs, not captures of the running application. Imported images retain their separate attribution. |
| **Application diagrams** | Explore source-derived screen routes, routine connections, data paths, and dependencies. The diagram page explains its symbols below the compact controls. Large diagrams retain readable node sizes inside a scrollable view; use grouping or select an object to narrow them. Arrows indicate possible relationships in the files, not measured runtime behavior. |

DPH shows the source behind its explanations where available and marks conclusions that need checking. A form file cannot reveal every runtime change, and a call site alone cannot prove when an action completes. The application under study is never executed as part of passive discovery.

### When the dossier says “STALE capture”

The capture timestamp reports when the project was read; it is not an expiration date. DPH starts on **Getting started** and waits for you to choose a project. To verify a saved capture, choose **Open saved project** while the original source is available. DPH checks the attached source in the background and automatically rescans when its saved analysis is stale, its fingerprint changed, or an analyzer version changed. You can also choose **Open application** and select the same project entry again. Wait for preparation to finish, then revisit **Handoff dossier**.

When analysis is incomplete, DPH says **Project analysis is incomplete** and keeps the results it found. Choose **Open Coverage** in the notice, select a diagnostic, then choose **Inspect selected gap** to see the affected source. Correct any missing file, path, or project setting and choose **Rescan project**. Unsupported constructs or unresolved connections may remain qualified after a fresh scan. A detached saved capture remains **STALE** until DPH can verify its source. **Static inspection only** is always accurate: DPH reads the files but never runs the selected application. A warning shown inside a guide screenshot describes that example capture; refreshing your project cannot change the printed screenshot.

**Export handoff** writes a new, read-only folder. Open `handoff-0.html` to start the four-part dossier, then follow included object pages and the technical index. The earlier teaching edition remains at `learning.html`. Review the full export before sharing; its checksum manifest detects changes relative to the capture but does not authenticate its author.

## Languages and offline use

The header offers **35 languages** for DPH's menus, buttons, instructions, and other built-in text: English and 34 additional languages. These choices work without an Internet connection. Languages written from right to left are supported in the interface.

The language choice changes DPH's own text; it does not alter the files of an application you open. Text taken from that application's guides or source may still appear in its original language. The German choice can additionally translate some selected passages locally as an experimental feature. If a passage cannot be translated, DPH shows the original. Names in code and links back to the source stay as written. Check any translated explanation against the original before relying on it.

DPH can be used offline. Reading public websites mentioned in a project's documents is optional and requires Internet access; the **Read public websites** checkbox is off by default.

## Guides, checks, and project layout

- [User Guide (PDF)](docs/pdf/DPH_User_Guide.pdf) and [Engineering Guide (PDF)](docs/pdf/DPH_Engineering_Guide.pdf); editable DOCX copies are in `docs/guides`.
- [Developer test directions](docs/guides/Developer_Test_Directions.txt) cover the available build and regression scripts. `tools/build-ui-translation.cmd` checks all 35 language packs, and `tools/build-learning-refocus.cmd` checks the learning route and source-linked explanations.
- [Project layout](docs/PROJECT_LAYOUT.txt) maps the source, guides, tests, graphics, and generated outputs.
- [Learning requirements reconciliation](docs/requirements/Learning_Requirements_Reconciliation.txt) records the scope decisions and remaining work. A scope decision does not imply an old requirement was implemented.

Independent testing with a first-time learner is separate from compilation and automated checks. DPH is designed to make an unknown project more understandable, while leaving uncertain behavior explicit.

## License and third-party material

DPH's original source code and documentation are licensed under [Apache License 2.0](LICENSE). Bundled components retain their own terms; see [third-party notices](THIRD_PARTY_NOTICES.md). The unmodified Bergamot German model is attributed there under CC BY-SA 4.0; its license text ships with both ZIPs.
