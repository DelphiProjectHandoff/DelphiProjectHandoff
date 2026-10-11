# Delphi Project Handoff (DPH)

Experimental software. WP0 through WP2 foundations are implemented: FMX shell, SQLite generations, and a headless read-only Delphi inventory/parser.

Independent Delphi FMX application for evidence-linked understanding and handoff of one selected Delphi project. VCL2FMXConverter is read-only reference material, never a runtime or build dependency.

Open DelphiProjectHandoff.dproj in RAD Studio. All initial controls and properties are serialized in DPH.UI.Main.fmx and editable in the Object Inspector.

From an elevated Windows command prompt, run tools\build-wp0.cmd. This builds the Windows 32-bit Debug application and runs the initial baseline test. Delphi's installed environment is loaded by rsvars.bat. The GUI is not automatically launched.

The owner's global AGENTS.md remains unchanged and independently authoritative. DPH_CODEX_HANDOFF.txt supersedes older approval labels in the master specification. Implementation authorization is granted separately for each work package.

WP0 was reviewed and approved by the owner, who separately authorized WP1. WP1 adds a headless FireDAC SQLite store, two checksum-validated migrations, manifests and revisions, generation/evidence constraints, separate status flags, queued writes, interruption recovery and consistent backups. Run tools\build-wp1.cmd from an elevated command prompt to build the application, rerun the FMX smoke test, and run the storage suite. Tests create disposable fixtures under ignored bin directories; they never scan or execute the converter.

WP1 was reviewed and approved by the owner, who separately authorized WP2. Run tools\validate-wp2.ps1 using PowerShell -ExecutionPolicy Bypass from an elevated prompt for the application build, WP0/WP1 regressions, WP2 fixtures and complete pinned-reference source hash verification. tools\build-wp2.cmd runs the discovery suite alone after the baseline output directories exist. The reference project is acquired as passive input and is never built or executed.

See docs\WP2_Acceptance.txt and docs\WP2_Parser_Contract.txt for measured coverage, API responsibilities and hard limits. The reference FMX hierarchy is parsed, while the overall reference analysis remains explicitly partial. The UI is still the original design-time shell. WP3 requires separate owner authorization and a new pre-change backup on D:\.
