# DPH source tree cleanup review

15 October 2026. Read-only inventory: no project file was removed or moved.

The repository's active Delphi source files already sit at the root so RAD Studio can open the project and edit its forms. Most visible clutter is historical or generated material in established folders. The current source-distribution ZIP is narrower than the repository checkout; it does not include the historical logs, validation archive, old release ZIPs, or `tools/legacy`.

## Clear candidates after owner review

| Location | Inventory | Why it can leave the active checkout | Caution |
| --- | ---: | --- | --- |
| `tools/legacy/**` | 250 files | Its README describes one-time implementation, validation, and guide-generation scripts; current builds use the top-level `tools` scripts. | Archive for history; some scripts modify project files if run. |
| `export/DPH-*-experimental-*.zip`, excluding `DPH-0.6.15-experimental-Windows.zip` | 18 ZIPs | Superseded local Windows distributions. | Preserve their GitHub release assets and any promised historical links before removing repository copies. |
| `source distributions/*.zip`, excluding `DPH_v0_6_15_Source_Distribution_2026-10-15_145317.zip` | 29 ZIPs | Superseded local source distributions. | Same historical-release caveat. |
| `docs/history/**` | 54 files | Earlier completion, acceptance, and work-package records; not needed to compile or run DPH. | Useful audit trail; archive rather than discard. |
| `logs/**` | 346 files | Historical validation and development output, not runtime input. | A few may support old acceptance claims. |
| `docs/validation/reports/**` | 286 files before this review | Mostly phase and work-package JSON evidence, not app input. | Keep current guide/distribution reports and any reports read by maintained scripts; review this folder item by item before pruning. |
| `docs/validation/images/**` | 276 files | Historical test captures, not desktop runtime assets. | Keep any images referenced by retained reports or guides. Current User Guide figures use `docs/guides/assets/**`. |
| `tools/backup-phase.ps1` | 1 file | It makes direct folder copies to H:, contrary to the current ZIP-only backup directive. | Replace its callers, if any, with a compliant backup procedure before retiring it. |

## Rebuildable local output, with important exceptions

`bin` currently has 9,180 files (about 3.9 GiB), and `dcu` has 266 compiled files (about 87 MiB). Compiler output, temporary test databases, guide rendering, probe output, and distribution staging are generally rebuildable. The release executables under `bin/Win32/Release` and `bin/Win64/Release` are still inputs to the packaging script until a new build replaces them. Do not clear `bin` wholesale: its root also contains 45 `.dpr`, 16 `.cmd`, and 2 `.ps1` files that look like test or developer source but are currently Git-ignored. Those 63 files need a separate keep/relocate/archive decision before any cleanup.

## Keep in the working project

- Root `DelphiProjectHandoff.dpr`, `.dproj`, `.res`, and `DPH.*.pas`/`.fmx` files: active Delphi project and IDE-editable forms.
- `tests/**` (72 files), current top-level `tools/build-*.cmd`, packaging and guide scripts: regression/build machinery.
- `dependencies/**`, `Localization/**`, `migrations/**`, `help/**`, and `images and icons/**`: build/runtime or current documentation inputs.
- Current User and Engineering Guides, source prose, and PDF companions in `docs/guides` and `docs/pdf`.
- `export/DAT-component-kit/**`: RAD Studio design-time dependency for editing the translation controls.

This is a candidate list, not authorization to delete. Old releases and historical evidence can be moved out of the active checkout later without changing the current executable. The 63 ignored source-like files in `bin` are the main reason an automated blanket cleanup would be unsafe.
