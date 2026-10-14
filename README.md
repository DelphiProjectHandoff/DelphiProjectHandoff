# Delphi Project Handoff

Delphi Project Handoff (DPH) helps a beginner learn one unfamiliar Delphi application: what it does, how to use its screens, what inputs mean, how an action reaches its operation, and how to recognize a result. DPH reads selected source without changing, compiling or running that application.

## Run and learn

1. Extract the Windows distribution into a writable local folder. Run `Win64\DelphiProjectHandoff.exe` on 64-bit Windows, or use the `Win32` edition.
2. Click **Open application** and select the Delphi project or project group you need to learn. Keep its `.dphdb` outside the selected source tree, together with its adjacent `.dphdb.views` folder.
3. Use **Learn the project**, **Learning library**, and **Project map** to follow the selected application's documented purpose, screens, controls, and actions.
4. **Screenshots** contains blank screen images DPH generates internally from the project's `.fmx` and `.dfm` files. **Application diagrams** explains possible connections between screens, routines, and data.
5. Choose a language from the selector in the header. DPH includes the same 35 offline language choices as VCL2FMXConverter v7, with English as the source language. The selected application's own source and documents remain in the language in which they were written.

The [run and test directions](docs/guides/Run_And_Test.txt), [User Guide](docs/pdf/DPH_User_Guide.pdf), and [Engineering Guide](docs/pdf/DPH_Engineering_Guide.pdf) cover the current app-specific learning route. The guides also have editable DOCX editions in `docs/guides`.

## Learning views

- The project introduction draws on project structure, form captions, and usable explanations found in the selected project's documents.
- The Learning library formats material from project-local guides, help, notes, and useful log messages.
- The Project map lists source files, forms, controls, units, routines, and variables with their available connections.
- Screenshots shows DPH-generated empty form views at fitted or native size. Each image is derived from one `.fmx` or `.dfm` definition and contains no runtime data.
- Application diagrams explains possible screen navigation, routine calls, data flow, and change impact. These relationships come from file evidence, not a recorded run.

## Build and validate

Use the configured RAD Studio toolchain from an elevated developer prompt. `tools\build-wp0.cmd` builds DPH and verifies the serialized FMX controls. `tools\build-learning-refocus.cmd` checks the app-specific learning route and source-linked explanations. Detailed test directions are in [Developer test directions](docs/guides/Developer_Test_Directions.txt).

Forms and ordinary controls remain editable in the IDE. The selected application is a read-only input. Runtime observation, live service access and selected-project execution are not part of passive discovery.

The DAT FMX language manager and selector are editable on the main form. Their pinned source is in `dependencies/DelphiAppTranslation/source`; the matching IDE design package and instructions are in `export/DAT-component-kit/DelphiProjectHandoff`. Each build copies `Localization/Languages` beside its executable. The installed app uses these packs offline; translation-provider credentials are needed only to regenerate them.

## Current scope

[The learning reconciliation](docs/requirements/Learning_Requirements_Reconciliation.txt) records all 533 original requirement dispositions; its CSV and JSON retain each original status, limitation and remaining work. The revised learning contract supersedes dedicated enterprise administration, specialist analysis expansion and agent infrastructure. A scope decision does not claim that an original technical requirement was implemented. The historical ledger remains unchanged.

[Project layout](docs/PROJECT_LAYOUT.txt) explains where current guides, original plans, validation reports, images, logs, compiled units, and databases live. [The move manifest](docs/PROJECT_MOVE_MANIFEST.csv) maps every reorganized file to its former location and records its SHA-256 hash.

Independent first-time learner acceptance is reported separately from software validation. The converter reference is passive test input and is never a DPH build or runtime dependency.
