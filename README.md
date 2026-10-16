![Delphi Project Handoff](images%20and%20icons/DPH-Logo-Horizontal-720.png)

# Delphi Project Handoff

**Prepare an evidence-based handoff for an unfamiliar Delphi application.**

Delphi Project Handoff (DPH) helps a new maintainer orient themselves when the original developer or documentation is unavailable. It captures project structure, forms, Pascal code, and eligible local documents, then assembles a handoff dossier with source links, uncertainties, and questions for a person who knows the application. It does not compile, run, or change the application being studied. A static trace is evidence to investigate, not proof of runtime behavior or business intent.

DPH is experimental Delphi software, built on Delphi 13.1. You can download a ready-to-run Windows ZIP or build the editable Delphi source project.

The local development branch now has a refocused handoff dossier and loads generated form previews only when the Screenshots page is opened. The public 0.6.15 download below is the earlier experiment; this work has not been published to GitHub or packaged as a release.

## Download the current experiment

- **Run it on Windows:** Download [DPH 0.6.15 for Windows](export/DPH-0.6.15-experimental-Windows.zip), extract the whole ZIP, and run `Win64/DelphiProjectHandoff.exe` (or the Win32 edition). Keep the supplied folders together. Microsoft WebView2 Runtime is required for the embedded learning pages.
- **Edit it in Delphi:** Download the latest **0.6.15 Source Distribution** ZIP from [source distributions](source%20distributions/) or use GitHub's **Code → Download ZIP**. Open `DelphiProjectHandoff.dproj` in RAD Studio 37. The source ZIP contains no compiled executable.

The two packages are built from the same revision. Both include the 35 offline interface language packs and the experimental offline English-to-German project-text model. Earlier ZIPs are retained as historical experiments; use the version above for current testing. The [experimental release page](https://github.com/tmartindub/DelphiProjectHandoff/releases/tag/v0.6.15-experimental) provides both downloads together.

## Build and start from source

1. Clone this repository or download GitHub's **Code → Download ZIP** source archive, then extract it to a writable folder.
2. Open `DelphiProjectHandoff.dproj` in RAD Studio 37. Build **Win64** or **Win32**, in **Debug** or **Release**. The project uses FireMonkey and the bundled DelphiAppTranslation source in `dependencies/DelphiAppTranslation`.
3. Run `bin/Win64/Release/DelphiProjectHandoff.exe` for a Win64 Release build, or the executable under the platform and configuration you selected. Keep `WebView2Loader.dll` beside it, and keep `Localization`, `migrations`, `help`, and `images and icons` in the source folder. Embedded pages also require the Microsoft WebView2 Runtime.

The main form is editable in the RAD Studio designer. To edit its DelphiAppTranslation controls visually, install the supplied design package using [the DAT component-kit instructions](export/DAT-component-kit/DelphiProjectHandoff/README.txt). The [run and test directions](docs/guides/Run_And_Test.txt) give a fuller first-use check.

`tools/package-source-distribution.ps1` creates the editable source ZIP; `tools/package-dph.ps1` creates the matching Windows package and verifies its files after extraction.

## Explore an application

Choose **Open application** and select its `.dproj`, `.dpr`, or `.groupproj` file. DPH keeps a new capture temporary while you explore. When you close DPH or open another project, choose **Yes** to save it as a `.dphdb`, **No** to discard it, or **Cancel** to keep exploring. Save the `.dphdb` outside the application's source tree and keep its adjacent `.dphdb.views` folder. Later, **Open saved project** restores the saved analysis and generated screen images.

While opening a project, DPH shows the current preparation step and a progress bar. It reads project startup information from `.dpr` and `.dproj`, identifies forms and controls from `.fmx` or `.dfm`, and traces their event handlers and related `.pas` code. It reads root-level documents and the selected project's top-level `docs`, `Help`, `Guides`, `Manual`, and `Notes` folders; nested release and upgrade packages are excluded. Supported document types include PDF, DOCX, Markdown, text, HTML, RTF, and ODT. DPH screens material before showing it. Existing saved projects are reassessed once under this narrower document rule.

The header's **Read public websites** checkbox controls DPH's optional Internet access. It starts off, and DPH remembers the choice for the current Windows user. When enabled, the next project analysis may read text from up to three eligible public HTTPS pages referenced in project documents, with each response capped at 128 KiB. DPH rejects private IPv4 DNS results and pins each request to the validated public IPv4 address while preserving the original hostname for HTTPS verification. It uses no proxy and does not follow redirects; if Windows cannot apply address pinning, the request is skipped. This requires Windows 10 21H1 or later. When disabled, project discovery reads local material only. Changing the checkbox affects the next analysis; it does not change previously saved evidence. DPH does not offer a general web search engine. The **Close** button exits through the same unsaved-work and in-progress safeguards as the window close control.

DOCX and supported text formats are read directly. Extracting text from PDF, legacy Word, RTF, and several older formats requires LibreOffice at `C:\Program Files\LibreOffice\program\soffice.com`. A scanned image-only PDF may need OCR before it has usable text. The Learning library reports when a discovered file yielded no readable content.

The six primary views in the current local development build are:

| View | What you can do |
| --- | --- |
| **Getting started** | See how to open a project and move through DPH. |
| **Handoff dossier** | Read a four-part account of purpose evidence, startup and forms, visible command bindings, data and output candidates, and unresolved risks and questions. Each claim is tied to the selected capture or explicitly marked as a reading suggestion. |
| **Learning library** | Read grouped, formatted topics drawn from the project's available documents and screen information. |
| **Project map** | Select units, types, objects, controls, procedures, functions, variables, and their connections; follow links to the relevant detail or screen. |
| **Screenshots** | Generate blank screen views on demand from `.fmx` and `.dfm` definitions, using Fit or Native pixels. These are form-derived designs, not captures of the running application. Imported images retain their separate attribution. |
| **Application diagrams** | Explore source-derived screen routes, routine connections, data paths, and dependencies. Large diagrams retain readable node sizes inside a scrollable view; use grouping or select an object to narrow them. Arrows indicate possible relationships in the files, not measured runtime behavior. |

DPH shows the source behind its explanations where available and marks conclusions that need checking. A form file cannot reveal every runtime change, and a call site alone cannot prove when an action completes. The application under study is never executed as part of passive discovery.

**Export handoff** writes a new, read-only folder. Open `handoff-0.html` to start the four-part dossier, then follow included object pages and the technical index. The earlier teaching edition remains at `learning.html`. Review the full export before sharing; its checksum manifest detects changes relative to the capture but does not authenticate its author.

## Languages and offline use

The header offers **35 offline language choices**, matching VCL2FMXConverter v7: English is the base language and 34 other interface packs are included. DPH changes its own controls and built-in explanations without an online translation service. Right-to-left interfaces keep navigation readable alongside source-code names and project material.

An experimental **English-to-German project-text translation** is included for selected project prose in the Handoff dossier and Learning library. It uses a bundled WebAssembly engine and model through a loopback-only preview server; it does not contact a translation service or require Internet access. The original project files and saved analysis are unchanged. Source code, identifiers, citations, form captions, and other languages remain in their original form. If local translation fails for a passage, DPH shows its original text. The translated output is machine-generated and should be checked before relying on it. The new dossier's built-in narrative remains English while its interface language coverage is completed.

The other 34 interface choices still work offline using the existing language packs. Optional referenced-site reading is the only part of normal project discovery that depends on Internet access; local preview and the German translation engine also work with the checkbox off.

## Guides, checks, and project layout

- [User Guide (PDF)](docs/pdf/DPH_User_Guide.pdf) and [Engineering Guide (PDF)](docs/pdf/DPH_Engineering_Guide.pdf); editable DOCX copies are in `docs/guides`.
- [Developer test directions](docs/guides/Developer_Test_Directions.txt) cover the available build and regression scripts. `tools/build-ui-translation.cmd` checks all 35 language packs, and `tools/build-learning-refocus.cmd` checks the learning route and source-linked explanations.
- [Project layout](docs/PROJECT_LAYOUT.txt) maps the source, guides, tests, graphics, and generated outputs.
- [Learning requirements reconciliation](docs/requirements/Learning_Requirements_Reconciliation.txt) records the scope decisions and remaining work. A scope decision does not imply an old requirement was implemented.

Independent testing with a first-time learner is separate from compilation and automated checks. DPH is designed to make an unknown project more understandable, while leaving uncertain behavior explicit.

## License and third-party material

DPH's original source code and documentation are licensed under [Apache License 2.0](LICENSE). Bundled components retain their own terms; see [third-party notices](THIRD_PARTY_NOTICES.md). The unmodified Bergamot German model is attributed there under CC BY-SA 4.0; its license text ships with both ZIPs.
