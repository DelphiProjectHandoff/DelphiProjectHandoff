![Delphi Project Handoff](images%20and%20icons/DPH-Logo-Horizontal-720.png)

# Delphi Project Handoff

**Learn an unfamiliar Delphi application from the files it already has.**

Imagine joining a company after its programmer has left. Nobody can explain the application, and there are no prepared lessons or screenshots. Delphi Project Handoff (DPH) helps you find a starting point: it reads the project's structure, forms, Pascal code, and any useful documents it finds, then presents an application-specific route through the screens and actions. It does not compile, run, or change the application being studied.

DPH is experimental Delphi software, built on Delphi 13.1. **This repository is an editable Delphi source project.** To run a checkout, build it with RAD Studio as described below.

## Build and start from source

1. Clone this repository or download GitHub's **Code → Download ZIP** source archive, then extract it to a writable folder.
2. Open `DelphiProjectHandoff.dproj` in RAD Studio 37. Build **Win64** or **Win32**, in **Debug** or **Release**. The project uses FireMonkey and the bundled DelphiAppTranslation source in `dependencies/DelphiAppTranslation`.
3. Run `bin/Win64/Release/DelphiProjectHandoff.exe` for a Win64 Release build, or the executable under the platform and configuration you selected. Keep `WebView2Loader.dll` beside it, and keep `Localization`, `migrations`, `help`, and `images and icons` in the source folder. Embedded pages also require the Microsoft WebView2 Runtime.

The main form is editable in the RAD Studio designer. To edit its DelphiAppTranslation controls visually, install the supplied design package using [the DAT component-kit instructions](export/DAT-component-kit/DelphiProjectHandoff/README.txt). The [run and test directions](docs/guides/Run_And_Test.txt) give a fuller first-use check.

The current named source snapshot is the latest 0.6.10 archive in [source distributions](source%20distributions/). Older ZIPs there are historical experiments. `tools/package-source-distribution.ps1` is the source packager; `tools/package-dph.ps1` creates a separate, optional Windows binary package.

## Explore an application

Choose **Open application** and select its `.dproj`, `.dpr`, or `.groupproj` file. Save the resulting `.dphdb` outside the application source tree, together with its adjacent `.dphdb.views` folder. Later, **Open saved project** restores that analysis and its generated screen images.

While opening a project, DPH shows the current preparation step and a progress bar. It reads project startup information from `.dpr` and `.dproj`, identifies forms and controls from `.fmx` or `.dfm`, and traces their event handlers and related `.pas` code. It reads root-level documents and the selected project's top-level `docs`, `Help`, `Guides`, `Manual`, and `Notes` folders; nested release and upgrade packages are excluded. Supported document types include PDF, DOCX, Markdown, text, HTML, RTF, and ODT. DPH screens material before showing it. Existing saved projects are reassessed once under this narrower document rule.

The header's **Read public websites** checkbox controls DPH's optional Internet access. It starts off, and DPH remembers the choice for the current Windows user. When enabled, the next project analysis may read a small amount of text from up to three eligible public HTTPS pages referenced in project documents. When disabled, project discovery reads local material only. Changing the checkbox affects the next analysis; it does not change previously saved evidence. DPH does not offer a general web search engine. The **Close** button exits through the same unsaved-work and in-progress safeguards as the window close control.

DOCX and supported text formats are read directly. Extracting text from PDF, legacy Word, RTF, and several older formats requires LibreOffice at `C:\Program Files\LibreOffice\program\soffice.com`. A scanned image-only PDF may need OCR before it has usable text. The Learning library reports when a discovered file yielded no readable content.

The six learner views are:

| View | What you can do |
| --- | --- |
| **Getting started** | See how to open a project and move through DPH. |
| **Learn the project** | Read the inferred purpose, starting form, screens, and a route into the application's real tasks. |
| **Learning library** | Read grouped, formatted topics drawn from the project's available documents and screen information. |
| **Project map** | Select units, types, objects, controls, procedures, functions, variables, and their connections; follow links to the relevant detail or screen. |
| **Screenshots** | Inspect blank screen views generated inside DPH from `.fmx` and `.dfm` definitions, using Fit or Native pixels. These are form-derived designs, not captures of the running application. |
| **Application diagrams** | Explore source-derived screen routes, routine connections, data paths, and dependencies. Large diagrams retain readable node sizes inside a scrollable view; use grouping or select an object to narrow them. Arrows indicate possible relationships in the files, not measured runtime behavior. |

DPH shows the source behind its explanations where available and marks conclusions that need checking. A form file cannot reveal every runtime change, and a call site alone cannot prove when an action completes. The application under study is never executed as part of passive discovery.

## Languages and offline use

The header offers **35 offline language choices**, matching VCL2FMXConverter v7: English is the base language and 34 other interface packs are included. DPH changes its own controls and built-in explanations without an online translation service. Right-to-left interfaces keep navigation readable alongside source-code names and project material.

An experimental **English-to-German project-text translation** is included in Learn the project and the Learning library. When German is selected, DPH translates the project purpose, guide excerpts, and formatted guide paragraphs using a bundled WebAssembly engine and model. It runs on the user's computer through a loopback-only preview server; it does not contact a translation service or require Internet access. The original project files and saved analysis are unchanged. Source code, identifiers, citations, form captions, and other languages remain in their original form. If local translation fails for a passage, DPH shows its original text. The translated output is machine-generated and should be checked before relying on it.

The other 34 interface choices still work offline using the existing language packs. Optional referenced-site reading is the only part of normal project discovery that depends on Internet access; local preview and the German translation engine also work with the checkbox off.

## Guides, checks, and project layout

- [User Guide (PDF)](docs/pdf/DPH_User_Guide.pdf) and [Engineering Guide (PDF)](docs/pdf/DPH_Engineering_Guide.pdf); editable DOCX copies are in `docs/guides`.
- [Developer test directions](docs/guides/Developer_Test_Directions.txt) cover the available build and regression scripts. `tools/build-ui-translation.cmd` checks all 35 language packs, and `tools/build-learning-refocus.cmd` checks the learning route and source-linked explanations.
- [Project layout](docs/PROJECT_LAYOUT.txt) maps the source, guides, tests, graphics, and generated outputs.
- [Learning requirements reconciliation](docs/requirements/Learning_Requirements_Reconciliation.txt) records the scope decisions and remaining work. A scope decision does not imply an old requirement was implemented.

Independent testing with a first-time learner is separate from compilation and automated checks. DPH is designed to make an unknown project more understandable, while leaving uncertain behavior explicit.
