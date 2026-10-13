# Delphi Project Handoff

Delphi Project Handoff (DPH) helps a beginner learn one unfamiliar Delphi application: what it does, how to use its screens, what inputs mean, how an action reaches its operation, and how to recognize a result. DPH reads selected source without changing, compiling or running that application.

## Run and learn

1. Extract the desktop package into a writable local folder and double-click `DelphiProjectHandoff.exe`.
2. Click **Choose application** and select the Delphi project or project group you need to learn. Keep its `.dphdb` outside the selected source tree, together with its adjacent `.dphdb.views` folder.
3. In **Learn the project**, follow **Meet this app**, **Learn a real task**, **Explore related tasks**, and **Resolve unknowns**. These pages use the selected application's own captured screens and actions plus its supplied explanations.
4. Use **Learn a task** for reviewed instructions and expected results, and **Learning library** for meanings and examples. If instructions are missing, ask someone who knows the app to prepare them; DPH does not invent business facts.

The [run and test directions](docs/guides/Run_And_Test.txt), [User Guide](docs/pdf/DPH_User_Guide.pdf), and [Engineering Guide](docs/pdf/DPH_Engineering_Guide.pdf) cover the current app-specific learning route. The guides also have editable DOCX editions in `docs/guides`.

## Teaching features

- Application purpose, a beginner learning route and plain Delphi terms.
- Screen and field meanings, worked examples, input limits, safe help and practice answers.
- Ordered task steps, role filters, learning paths and personal revision-specific checked-step progress.
- Source-linked action explanations with optional deeper detail.
- Attributed FAQs, error recovery, business rules, settings, dependencies and output explanations.
- Real supplied pictures and sample outputs with anchored numbered callouts. Source-based form reconstructions remain clearly labeled.
- Search, business glossary, saved knowledge and shared offline lessons from the same records.

Preparing a lesson cannot establish an unwritten business fact. A knowledgeable contributor supplies that information; DPH preserves attribution, unanswered points and review status. Checked steps record the learner's checks, not proof of mastery or a recorded application run.

## Build and validate

Use the configured RAD Studio toolchain from an elevated developer prompt. `tools\build-wp0.cmd` builds DPH and verifies the serialized FMX controls. `tools\build-learning-refocus.cmd` checks the app-specific learning route and source-linked explanations. Detailed test directions are in [Developer test directions](docs/guides/Developer_Test_Directions.txt).

Forms and ordinary controls remain editable in the IDE. The selected application is a read-only input. Runtime observation, live service access and selected-project execution are not part of passive discovery.

## Current scope

[The learning reconciliation](docs/requirements/Learning_Requirements_Reconciliation.txt) records all 533 original requirement dispositions; its CSV and JSON retain each original status, limitation and remaining work. The revised learning contract supersedes dedicated enterprise administration, specialist analysis expansion and agent infrastructure. A scope decision does not claim that an original technical requirement was implemented. The historical ledger remains unchanged.

[Project layout](docs/PROJECT_LAYOUT.txt) explains where current guides, original plans, validation reports, images, logs, compiled units, and databases live. [The move manifest](docs/PROJECT_MOVE_MANIFEST.csv) maps every reorganized file to its former location and records its SHA-256 hash.

Independent first-time learner acceptance is reported separately from software validation. The converter reference is passive test input and is never a DPH build or runtime dependency.
