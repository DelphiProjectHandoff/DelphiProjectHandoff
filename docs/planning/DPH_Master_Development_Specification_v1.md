# Delphi Project Handoff (DPH)
## Master Development Specification — Design Candidate 1.0
**Date:** 10 October 2026  
**Status:** Phases 1–2 approved by owner; Phases 3–7 completed as design proposals, pending owner approval. No implementation authorized.  
**Purpose:** Define an independent Delphi FMX application that makes a *selected Delphi application* understandable, maintainable, and transferable down to verified source and operational details.

---

# 0. Charter and immutable boundaries

1. DPH is an independent Delphi FMX product. VCL2FMXConverter remains a separate product and repository. Selected routines may be **copied** with provenance and license review, then adapted; no shared library, runtime dependency, or required build relationship.
2. DPH operates on **one explicitly selected Delphi project or project group** per knowledge store. Outside systems appear only as directly relevant dependencies, not as free-ranging enterprise inventories.
3. Analyze source **read-only**. No compilation, project execution, scripts, package loading, or connections to live services are performed by passive discovery. Runtime observations require explicit approval and separate instrumentation.
4. One SQLite knowledge database per project (FireDAC SQLite); stored results open immediately. Automatic, background, incremental reassessment is the default; explicit full reassessment is available.
5. Maintain separate source-modified, analysis-stale, knowledge-review, and error flags; never claim current results for mismatched fingerprints or incomplete scans.
6. Original source is the authority for code behavior. Human observations are attributed. AI summaries are hypotheses unless verified, never silently converted into facts.
7. The knowledge store is authoritative for DPH's **documentation records**; generated HTML, diagrams, printouts, translations, JSON and AI bundles are *derived views*, not competing sources of truth.
8. Provenance, qualified confidence, parser coverage, cross-reference integrity and reproducible version identity are mandatory.
9. DPH replaces *eligible project-specific* engineering guides and user manuals only after content is complete, approved, and validated. It cannot infer absent policies, unwritten procedures, or runtime behavior from code alone.
10. No implementation work begins without explicit authorization.

# 1. Phase 3 — Discovery and Knowledge Architecture

## 3.1 Pipeline

**Project selection and boundary definition** → **immutable input inventory** → **encoding-aware acquisition** → **lexing / preprocessing** → **parsing** → **symbol resolution** → **control-flow and reference analysis** → **form and resource association** → **cross-system evidence ingestion** → **knowledge derivation and explanations** → **verification / provenance** → **atomic database publish** → **projection into UI and documentation**.

Each stage uses an explicit contract with input fingerprint, implementation version, diagnostics, and output schema version. No stage directly edits the selected source tree.

### Stage A. Selection, input boundaries and manifests
- Support .dpr, .dproj, .groupproj, .dpk and linked relevant .pas, .inc, .dfm/.fmx, .res/.rc, configuration, map packs, SQL and defined resource files.
- Discover project references from project files first; expand through explicit include paths and resolvable references. Prevent arbitrary traversal into neighboring projects. External paths must be whitelisted for analysis.
- Record project-relative canonical paths, content hashes (SHA-256), file sizes, logical roles, encodings, line endings, source availability, and exclusion reasons.
- Record Delphi/target platform/configuration because conditional compilation changes the code being analyzed. Multiple configurations are distinct analysis variants, not silently conflated.
- For missing files, permissions, parsing limits, and unsupported binary resources, emit diagnostics rather than declaring completion.

### Stage B. Delphi lexical and syntactic analysis
- Implement a token stream preserving comments, exact line/column ranges, preprocessing conditions, lexical state, and original bytes/encoding boundaries.
- Parse Delphi/Object Pascal into a versioned intermediate representation (IR): units, uses, namespaces, types, generics, nested declarations, interfaces, classes, records, helpers, properties, routines, overloads, anonymous methods, expressions, statements, branches, loops, try/except/finally, labels, assembler/unsafe constructs as opaque blocks with diagnostics.
- Preserve separate declarations and implementations; handle conditional symbol variants and `{$INCLUDE}` directives with source mappings. Unrecognized syntax should yield partial AST with quantified coverage, not fabricated statements.
- **Source parser is not a compiler**; do not promise sound whole-program resolution for RTTI-based calls, generated types, custom frameworks, dynamic loading or external assemblies.

### Stage C. Symbol and relationship resolution
- Build stable *logical* symbol keys using project context, qualified name, signature and conditional variant, plus revision-scoped occurrence IDs. Renames/moves are proposed matches requiring review if ambiguous.
- Resolve unit imports, types, inherited members, interface implementation, overloads, method references, properties, events, generics and local nested scopes as far as supported.
- Encode references as `confirmed_static`, `possible_dynamic`, `inferred`, `runtime_observed`, or `unresolved`, with evidence and analysis rule. Never treat a uses clause as proof of a procedure call.
- Dependency graph edges include callers/callees, inherits, implements, owns, reads, writes, creates, destroys, raises, catches, binds, configures, renders, derives_from, documented_by, and test_covers.

### Stage D. Control/data flow analysis
- Create per-routine control-flow graphs (CFG) with entry/exit, branches, loop-back edges, exceptional paths, and return points. Provide statement ranges and condition expressions.
- Basic intra-procedural def-use: variable assignments, field/property reads and writes, parameter transformations and evident side effects. Interprocedural summaries may be conservative and mark unknown effects.
- Recognize threads, tasks, queued callbacks, anonymous methods and event handlers; represent asynchronous/happens-before *known* relations and flag uncertain ordering.
- Database access: extract static SQL and known component relationships, infer table/column usage only when unambiguous; dynamic SQL is partially known. Never connect to production automatically.
- Build change-impact reachability from typed graph edges; distinguish **possible impact** from proved runtime impact.

### Stage E. FMX/DFM and visual analysis
- Parse text/binary form resources safely without creating arbitrary third-party components; enumerate hierarchy, design-time properties, events, embedded frames, inheritance and resource references.
- Associate event values with resolved method symbols and source ranges. Scan code for programmatically created controls and relevant property mutations; mark incomplete when dynamic construction cannot be resolved.
- Form thumbnails: (1) screenshots acquired through consented running application when possible; (2) design-time reconstruction as approximate visualization, explicitly labeled. A source parser cannot promise pixel-perfect rendering of custom components and runtime styles.
- All component inspectors show direct evidence and distinguish default properties from serialized overrides.

### Stage F. External definitions and operation
- Inspect only directly-referenced JSON, XML, INI, SQL, scripts, mapping packs and assets; identify loaders, consumers, precedence, caching and conditional behavior where analysis supports it.
- Human records capture why rules exist, manual deployment steps, troubleshooting, user workflows, and operational knowledge, always attributed and associated with source/system evidence.
- Supplementary runtime observations and logs are imported explicitly, privacy filtered, timestamped and tied to the relevant project revision/environment.

## 3.2 Reuse review: VCL2FMXConverter v6.0

**Candidate code to copy and adapt** (subject to inspection, licensing, compatibility, tests): `Converter.Parser.Pascal.pas`, `Converter.Parser.DFM.pas`, `Converter.Core.FileManager.pas`, `Converter.Reporting.Model.pas`, `Converter.Reporting.Html.pas`, `Converter.Reporting.Json.pas`, relevant handling of encoding, source ranges, issue identities and component mappings.

**Do not import as DPH architecture**: conversion orchestration, FMX code generators, rewriting passes, auto-fixes, conversion mapping *behavior* or conversion-specific context/state. DPH's core contracts must be analysis-first and read-only. A copied parser is a starting point requiring expanded grammar, provenance, source positions, diagnostics and semantic resolution.

**Provenance ledger:** original source URI + release/tag/commit + exact file checksum + license notice + local adaptation reason + modified DPH module + corresponding tests. VCL2FMXConverter is not modified.

## 3.3 Analysis statuses and modification policy

- File status: `unchanged`, `added`, `modified`, `renamed_candidate`, `missing`, `excluded`, `unreadable`.
- Analysis status: `current`, `pending`, `running`, `partial`, `failed`, `superseded`.
- Knowledge status: `verified`, `needs_review`, `inferred`, `rejected`, `retired`.
- Project badge derived from the worst outstanding state, never used as sole persistent truth.
- At opening, present last committed scan at once. Compare manifests asynchronously; hash candidate-changed files. Recompute impacted symbol relationships, then invalidate associated explanations, diagrams and translations.
- Perform analysis against consistent captured inputs. Before committing the new published generation, check that every participating fingerprint still matches the captured set. If not, mark the generation superseded and queue a new pass. For a huge scan, stage partial work but publish only coherent generations.
- Persist last completed generation after a failure; leave flags and errors visible. Never destroy curated knowledge on rebuild.

## 3.4 Explicit analysis contract

Every factual result MUST store: `project_id`, `generation_id`, `entity_id`, `kind`, `value`, `source_uri`, `start/end offsets or range`, `source_hash`, `analyzer_version`, `evidence_type`, `resolution_status`, and `diagnostics` when applicable. A record may have multiple evidence items.

For a high-confidence claim, require an inspectable evidence chain, not an arbitrary AI confidence percentage. Explanations separate verified facts from interpretation and record a human reviewer where one approved them.

## 3.5 Phase 3 acceptance gates

1. Parse all top-level units and .fmx forms of a pinned v6.0 test baseline with exact input inventory and diagnostic accounting.
2. Resolve `MainForm.fmx` `btnConvert` to `TfrmMain.btnConvertClick`; link to the worker-thread initiation and `TConverterEngine.Convert`, classifying uncertain callback relationships correctly.
3. Represent `DryRunPreview` configuration and conditional branch differences accurately.
4. Identify report-generation relationships without confusing reported JSON fields with arbitrary string occurrences.
5. Handle deliberately malformed units, include cycles, conditional variants, overloads, anonymous callbacks and missing dependencies without false full-coverage claims.
6. Prove source trees unchanged before and after analysis, including failed scans.
7. Demonstrate incremental results matching clean full-rescan results on a fixed test corpus, modulo run metadata.

# 2. Phase 4 — Database and Knowledge Model

## 4.1 Persistence arrangement
- One project SQLite database with FireDAC (no server); a separate lightweight local workspace catalog stores only known project database locations/preferences.
- Enable referential integrity, managed migrations and explicit transactions. Configure WAL where deployment conditions make it suitable; do not assume a writable shared network drive is safe for concurrent SQLite writers.
- **One writer** coordinates analysis publication and knowledge editing; readers use appropriate snapshots/transactions. Include queued writes, busy handling and crash recovery.
- FTS5 or alternate indexed search if the linked SQLite build supports it; detect optional capabilities at startup.
- Store heavy binary snapshots/thumbnail artifacts by content hash in managed project storage, indexed by SQLite, if size warrants. A portable handoff package can collect them and verify its manifest.

## 4.2 Logical schema (first-pass implementation contract)

**Identity and versioning**
- `projects(project_id PK, name, root_uri, project_kind, active_config, created_at, last_opened_at)`
- `configurations(config_id PK, project_id FK, platform, compiler, defines_json, search_paths_json, environment_label)`
- `analysis_generations(generation_id PK, project_id FK, started_at, completed_at, analyzer_version, config_fingerprint, manifest_hash, status, previous_generation_id FK nullable, completeness_summary_json)`
- `source_files(file_id PK, project_id FK, canonical_relpath, kind, current_observed_hash, last_analyzed_hash, availability_status, reassessment_flag, encoding, UNIQUE(project_id,canonical_relpath))`
- `file_revisions(file_revision_id PK, file_id FK, sha256, size_bytes, revision_time, snapshot_blob_id nullable, source_generation_id FK, UNIQUE(file_id,sha256))`

**Facts and graph**
- `entities(entity_id PK, project_id FK, entity_kind, canonical_key, display_name, owner_file_id nullable, lifecycle_state, UNIQUE(project_id,canonical_key,entity_kind))`
- `entity_versions(entity_version_id PK, entity_id FK, generation_id FK, signature, structural_json, source_revision_id nullable, start_line, end_line, start_offset, end_offset, analysis_status, UNIQUE(entity_id,generation_id))`
- `relationships(relationship_id PK, project_id FK, from_entity_id FK, to_entity_id FK nullable, relation_kind, resolution_status, generation_id FK, evidence_id FK nullable, condition_variant nullable)`
- `evidence(evidence_id PK, project_id FK, generation_id FK nullable, file_revision_id FK nullable, source_range_json, evidence_kind, payload_ref, analyzer_version, capture_time, verification_state)`
- `diagnostics(diagnostic_id PK, project_id FK, generation_id FK, severity, code, message, source_range_json, affected_entity_id FK nullable, resolved_at nullable)`
- `component_properties(component_entity_id FK, generation_id FK, property_name, serialized_value, value_kind, evidence_id FK)`
- `control_flow_nodes(cfg_node_id PK, routine_version_id FK, node_kind, source_range_json, expression_ref nullable)`
- `control_flow_edges(cfg_edge_id PK, from_cfg_node_id FK, to_cfg_node_id FK, edge_kind, condition_ref nullable)`

**Manual knowledge and publication**
- `knowledge_records(knowledge_id PK, project_id FK, kind, title, source_language, current_revision_id FK nullable, state, owner)`
- `knowledge_revisions(knowledge_revision_id PK, knowledge_id FK, body_md, editor, created_at, verification_state, verified_by nullable, verified_at nullable)`
- `knowledge_links(link_id PK, knowledge_id FK, entity_id FK nullable, relationship_id FK nullable, evidence_id FK nullable, link_role, last_verified_generation_id nullable)`
- `review_tasks(task_id PK, project_id FK, knowledge_id FK nullable, entity_id FK nullable, reason, state, opened_generation_id FK, resolved_generation_id nullable, reviewer nullable)`
- `translations(translation_id PK, knowledge_revision_id FK, target_locale, provider_id, provider_version, translated_body, source_hash, translation_state, reviewer)`
- `artifacts(artifact_id PK, project_id FK, generation_id FK, kind, path_or_blob_id, content_hash, locale, template_version, build_state)`
- `export_jobs(export_id PK, project_id FK, generation_id FK, format, scope_json, started_at, finished_at, manifest_hash, status)`
- `audit_events(event_id PK, project_id FK, entity_type, entity_id, action, actor, recorded_at, before_hash nullable, after_hash nullable)`
- `schema_migrations(version PK, applied_at, checksum)`

This is a **logical schema**, not a finished executable migration. Codex must turn it into reviewed, normalized SQL migrations, indexes and constraints; no silent FK omissions. Use immutable `entity_version`/generation references for every exported source fact to avoid current/historical ambiguity.

## 4.3 Invariants
1. Published `analysis_generations` are immutable; never mix fingerprints from two generations under the same 'current' label.
2. A manually authored knowledge revision is never overwritten by automatic analysis.
3. A missing symbol is retired or unresolved, not silently deleted with its annotation history.
4. Every active relationship has a known producing generation and classification of certainty.
5. No derived documentation can claim a newer source generation than its dependencies.
6. No export includes excluded/private files merely because an archive exists.
7. Foreign keys, uniqueness constraints, migration checksums, and record-level validation enforce internal consistency.

## 4.4 Essential indexed queries
- Entity lookup by project+name/signature/type; file-to-symbol enumeration; direct/reverse graph neighbor queries; bounded traversal for impact analysis; source-range navigation; evidence per claim; stale documentation by generation; all uses of config property; manual-review queue; project-wide searchable text.
- Required indexes: project/filename, project/entity canonical key, relationship from+kind and to+kind+generation, evidence file+range, review state+project, artifacts generation+locale, knowledge links by entity and knowledge; explain-query-plan checks on representative large projects.

## 4.5 Storage lifecycle
- First open: full scan, migration, initial generation and (when permitted) snapshot baseline.
- Later open: immediate cached display, low-cost manifest check, background hash verification, affected-graph rebuild, atomic publish.
- Full reanalysis: regenerate derived records, retain manual knowledge and historical snapshots.
- Rename: use content/symbol continuity as candidate matching, preserve manual links only when verified; ambiguous matches go to review queue.
- Offline/detached: allow historical inspection and export with prominent 'source unavailable / last verified generation' markings.
- Backups: SQLite online backup API or consistent checkpoint strategy, integrity checks, recoverable archives; retention default to baseline, latest verified release and recent revisions, user adjustable.

## 4.6 Phase 4 acceptance gates
- Repeat open does not trigger full scan; file hash change sets modification flag; incremental publish clears flag only for exact captured fingerprint.
- Forced crash during publication leaves a valid previous completed generation and intact manual notes.
- Deleted and renamed units do not orphan or misassign knowledge links.
- Portable package passes independent hash validation and opens detached with correct status.
- Concurrent UI reads remain responsive during background analysis, with measurable performance targets after baseline benchmarks.
- Restore and migration tests work across at least two schema versions and reject incompatible newer versions safely.

# 3. Phase 5 — Documentation, Atlas and AI Handoff

## 5.1 Canonical document system
- Knowledge records are source-of-truth **documents** with stable IDs, versioned sections, role/audience tags, backlinks and evidence references; generated content is recomputable.
- Outputs: Overview, Engineering Reference, User Manual, Maintenance/Operations Guide, Build/Deployment Guide, Troubleshooting Guide, AI Agent Handoff, and context-sensitive help. Each filters the same project knowledge by audience and verified scope.
- Each statement or section carries `source_generation`, `verification_state`, `last_reviewed`, and evidence links as suitable. Explicitly label known gaps.
- Project-specific guide generation is sufficient only when its coverage and content are approved; do not claim a universal replacement for all policy or regulatory manuals.

## 5.2 HTML presentation and localization
- HTML static bundles with project-local routes, search index, figure metadata, responsive typography, collapsible detail, internal anchors, screenshots and source-navigation links. Support local offline use, print CSS and optional PDF export.
- Use FMX `TWebBrowser` for embedded HTML and separate native Explorer/Inspector. Test Windows runtime behavior; WebView2 navigation is allowlisted, arbitrary scripting/network is blocked by default and links do not gain arbitrary native file permissions.
- **Atlas provider decision remains conditional:** identify the exact Atlas translation system, executable/API, licensing and offline/cloud characteristics before implementation. Implement `ITranslationProvider` adapter with neutral interchange contract.
- Protect Pascal identifiers, SQL, file paths, hashes, snippets, code blocks and protocol keys from translation. Translate prose only, with revision-aware cache keys, locale fallbacks, terminology dictionary and reviewer approval.
- Imported text is untrusted: HTML-encode content; sanitize generated markup and external links; prevent malicious `file://` routes and script injection.

## 5.3 AI handoff contract

Package structure proposed:
```
DPH_Handoff_<project>_<revision>/
  manifest.json
  AGENTS.md
  README.md
  project-summary.md
  architecture.md
  build-and-test.md
  known-risks.md
  decisions-and-unknowns.md
  indexes/symbols.jsonl
  indexes/relationships.jsonl
  indexes/forms-events.jsonl
  indexes/configuration.jsonl
  indexes/data-usage.jsonl
  evidence/references.jsonl
  validation/coverage.json
  validation/manifest-sha256.json
```

- `manifest.json`: schema version, project identity, source revision/configuration, DPH analyzer/version, scan time, portability scope, inclusion/exclusion list, required toolchain, artifact hashes, disclosure limitations.
- `AGENTS.md`: repository-specific edit boundaries, build/test instructions, high-risk areas, mandatory verification, docs refresh requirements; never include credentials.
- JSONL indexes: stable IDs, fully qualified symbols, signatures, source refs, typed relationships, certainty, evidence IDs, revision identifiers, and explicit unknowns.
- Support **full project** and **task-scoped** bundles. Task-scoped bundles contain minimal related information and provenance, not a blind truncated full export.
- Exports should be deterministic for a fixed data generation/template version aside from explicitly variable metadata, and schema validated before delivery.
- AI agents must not silently override verified facts or modify production without authorization. Returned AI claims need human verification or source-derived checking before promotion.

## 5.4 Handoff completeness
- Coverage dashboard: source inventory, parser coverage, symbol resolution, UI binding coverage, evidence-bearing documentation, tested build, documentation review, known unknowns.
- Never collapse 'automatically analyzed' and 'human verified' into one misleading percentage. Each metric defines numerator, denominator, exclusions and revision.
- Provide focused questions to the original author for unresolved critical behavior. Recording an answer creates attributed knowledge; cannot automatically verify historical rationale.

## 5.5 Phase 5 acceptance gates
- HTML, print/PDF and JSON views agree on shared project facts and revisions.
- A single `btnConvert` selection provides user help, technical event trace, and precise AI symbol reference from one canonical model.
- HTML works offline, with navigation and searches but no unauthorized external network activity.
- Translation preserves every code token, path and hash; changing source prose invalidates affected localized entries.
- AI full/task-scoped handoffs validate schema, filenames, hashes, exclusions and evidence references; deliberately stale bundles are rejected or labeled.
- Nonexistent business knowledge is labeled absent, not invented.

# 4. Phase 6 — Verification, Testing and Acceptance Strategy

## 6.1 Testing pyramid
1. **Unit**: lexer, parser, configuration evaluator, event matching, graph edges, hash/manifests, transitions, SQL migrations, serializers, sanitizer.
2. **Contract**: fixture input and expected JSONL/IR/graph outputs for narrow Delphi patterns. Maintain versioned golden fixtures including malformed and conditional source.
3. **Integration**: `.dproj` inventory through SQLite publish through HTML output; source file changes and notes survival; export/restore; translation adapter mock.
4. **System**: FMX Explorer/Inspector interactions, full v6.0 trace scenarios, cross-project isolation, runtime-free scanning.
5. **Acceptance**: Mr. A walkthrough, supervised quality judgments, first-time onboarding, real program maintenance simulation.

## 6.2 Reference corpus and pinned baseline
- Pin VCL2FMXConverter **v6.0.0** source by Git commit and verify the exact code inputs; do not silently test moving `main`. Keep a separate synthetic fixture corpus for syntax coverage, security and deliberately invalid data.
- Include: MainForm component/event, background conversion chain, engine dry-run branch, mapper external definitions, report-model HTML/JSON rendering, and controlled edits that rename/replace methods.
- The repo-wide Pascal file count includes test materials; define precise project source boundary from DPR/DPROJ and analyzed include paths rather than count every `.pas` in the repository.

## 6.3 Mandatory baseline tests (from Phase 2)
- AT-01 cached open; AT-02 FMX form hierarchy; AT-03 `btnConvert` link; AT-04 procedure inspector; AT-05 asynchronous execution chain; AT-06 flowchart; AT-07 report origin; AT-08 four screen viewer modes; AT-09 search; AT-10 reverse links; AT-11 modification detection; AT-12 incremental recomputation; AT-13 notes retained; AT-14 incomplete analysis reported; AT-15 consistent HTML manuals; AT-16 source read-only.

## 6.4 Additional architectural gates
- AC-17 reproduce full versus incremental graph equivalence for same fingerprint set.
- AC-18 version-consistent evidence from each UI and exported claim; tampering with a stored source hash makes it stale.
- AC-19 compile condition variants yield separate branches; no false universal claims.
- AC-20 inaccessible dependency reports a gap with bounded scope.
- AC-21 failed SQLite migration/analysis resumes with valid prior state.
- AC-22 exported bundle contains no secrets or excluded files; sanitized HTML blocks injected links/scripts.
- AC-23 the project could be relocated without replacing the entire knowledge graph with incorrect new entities.
- AC-24 human review remains pending after parser success if its evidence was invalidated.
- AC-25 a first-time programmer can locate startup, explain convert, diagnose dry-run, locate mapper/report code, and identify unknowns using DPH.

## 6.5 Acceptance thresholds
- **Zero tolerance**: alteration to scanned sources; corrupted database; unjustified verified claim; wrong project scope; unredacted secrets in export; cross-generation mixing; wrong source link presented as confirmed.
- All 16 Phase 2 mandatory AT cases must pass for final product acceptance. AC-17–25 must pass for architecture acceptance. Blocked/partial are not Pass.
- Source parse coverage targets must be established from actual pinned baseline and feature-support matrix after prototype investigation; do not fabricate a percentage before measuring.
- Responsiveness and memory benchmarks must use defined hardware and corpus, with baseline measurements and explicit budgets agreed before release gate. Provisional aspiration: cached Explorer interactive within a few seconds, without making a contractual hardware-independent promise.
- Technical explanations require independent source-based review of sampled complex procedures, including negative controls where inference should be marked uncertain.

## 6.6 Audit artifact per test
`test_id`, corpus ID/hash, project config, analyzer/build/schema version, environment, expected, observed, result, log/artifact hashes, reviewer, timestamp, defect links and remediation. Publish machine-readable and human-readable acceptance reports.

# 5. Phase 7 — Codex Handoff and Implementation Plan

## 7.1 Handoff governance

This specification and approved Phase 1/2 decisions become immutable baseline requirements at project start. Codex must record newly discovered implementation issues as proposals, not silently replace decisions. Architectural changes affecting project boundaries, source safety, knowledge model, or verification require owner review.

No code shall be generated and no repository created until the owner gives explicit authorization.

## 7.2 Recommended Delphi implementation outline
- Target: modern Delphi FMX (owner to pin actual installed compiler/IDE version; do not assume Delphi 13/12 compatibility without test), with Windows desktop as initial validation target; portability is an optional future target.
- UI: `DPH.UI.*` (shell, Explorer, Tabs, Inspector, ScreenViewer, DiagramView, Search, Status).
- Project: `DPH.Project.*` (selection, manifests, boundaries, fingerprints, scan coordination).
- Parser: `DPH.Parse.*` (encoding, lexer, preprocessor, Pascal IR, FMX/DFM, resource/file adapters).
- Semantics: `DPH.Analysis.*` (symbols, references, CFG, event/callback analysis, def-use, dependencies, impact, provenance).
- Knowledge: `DPH.Knowledge.*` (entities, evidence, reviews, explanations, graph, snapshots).
- Database: `DPH.Storage.*` (FireDAC SQLite, migrations, repositories, atomic publication, search).
- Output: `DPH.Publish.*` (HTML, export manifest, JSONL, print/PDF adapter, Atlas translation adapter).
- Tests: `DPH.Tests.*` plus fixture-based golden contract runner and complete acceptance suite.
- Contract objects/DTOs separate the parser, storage and FMX presentation so the parsing engine can be tested headlessly.

## 7.3 Work packages with stop/go gates

**WP0 — Repository and governance (after approval):** establish independent DPH repository, compiler version, CI/test harness, fixture corpus, licensing/provenance policies, architecture decision log. Gate: reproducible no-op build/test and no VCL2FMX dependency.

**WP1 — Storage foundation:** schema migrations, project manifest, generation model, flags, safe backup; test interrupted scan and stale revision. Gate: AC-17/18/21 primitives.

**WP2 — Read-only project inventory and parser:** project graph, token/AST, DFM/FMX parser, diagnostics, deterministic fixtures. Gate: AT-02/03 foundations, zero source writes.

**WP3 — Symbol/flow and impact:** resolver, events/callbacks, CFG, reference graph, condition variants, provenance. Gate: AT-04/05/06/10/14 plus uncertainty tests.

**WP4 — FMX interface:** Explorer, Inspector, source/diagram viewers, screens, search, histories, status and responsive loading. Gate: AT-01/08/09/11/12.

**WP5 — Knowledge, notes, review:** annotations, approval, historical revisions, invalidation, user/engineering views. Gate: AT-13 and AC-24.

**WP6 — Publishing, translation and AI bundles:** common model, static HTML, report templates, translator adapter, task-scoped handoff, validation. Gate: AT-07/15, AC-22 and Phase 5 gates.

**WP7 — End-to-end hardening:** v6.0 scenario, full testing, performance, portability, threat modeling, packaging and user acceptance. Gate: all acceptance cases pass.

Each package must include code, unit and fixture tests, documentation, demonstration evidence, known gaps and a change log. No wave of parallel code generation that bypasses integration tests.

## 7.4 Codex first message (save for authorized implementation)

> Implement DPH only when explicitly authorized. Treat the approved DPH Master Development Specification as the controlling contract. Create an **independent Delphi FMX** application and repository. Do not modify or create runtime/build dependencies on VCL2FMXConverter. Copy and adapt vetted source components only with provenance and license review. Begin with WP0 and stop at its acceptance gate for review before proceeding. Scan selected Delphi source read-only, maintain one SQLite knowledge database per project, use immutable revision-aware analysis generations, and keep all manual documentation preserved. All uncertain code relationships must remain visibly uncertain. Require tested migrations, pinned fixtures, evidence-linked findings, incremental-versus-full scan equivalence, and a full acceptance record. No silent scope expansion into unrelated enterprise systems. List deviations and questions in an explicit decision log.

## 7.5 Required handoff bundle from planning to Codex
1. This master specification + Phase 1/2 approved decisions and 16 acceptance tests.
2. Schema migrations blueprint and contract definitions (to be authored by Codex in work packages).
3. Pinned reference project source locations and hashes, fixture manifests and expected examples.
4. UI/Explorer hierarchy and diagram behavior specification.
5. Provenance review list for copied VCL2FMXConverter units.
6. Security, scope and read-only policies.
7. Work-package order, objective pass/fail gates and review checkpoints.
8. Known decisions still awaiting explicit user confirmation below.

# 6. Owner review and outstanding decisions

The design is complete enough to seek approval, but **not** a claim of proven parser feasibility or finished executable schema. Explicit sign-off requested on these remaining choices:

| Decision | Proposed default | Reason for final confirmation |
|---|---|---|
| Initial Delphi version | User's actual Delphi toolchain pinned at WP0 | Compiler/RTL/FMX compatibility must be tested |
| Initial platform | Windows desktop | Simplifies source browsing and WebView2 validation |
| Snapshot policy | Optional baseline, recent changes and verified releases; no automatic secrets | Balance portability/privacy/size |
| Translations | Atlas through adapter, exact API TBD | Product/provider ambiguity and data handling |
| User permissions | Single local author initially; review roles architected for later | Avoid premature enterprise identity systems |
| AI explanation generation | Optional and opt-in, disabled for sensitive content without consent | Avoid leaking proprietary project source |
| Runtime instrumentation | Separate explicit opt-in stage, not passive scan | Safety and reproducibility |
| Large database storage | SQLite + managed artifact files as needed | Avoid excessively large BLOBs |

# 7. Requirements trace and completion checklist

| Phase | Output | Status |
|---|---|---|
| 1 | 23 functional domains, project scope, persistent analysis, modification flags | Owner approved |
| 2 | Three-panel Explorer, detailed object views, graphics/UI, 16 acceptance tests | Owner approved |
| 3 | Discovery pipeline, read-only parser/semantic contracts, provenance, reuse boundaries | Design completed; approval pending |
| 4 | Logical SQLite schema, generations, incremental updates, invariants, retention | Design completed; approval pending |
| 5 | Unified HTML/manual/translation/AI handoff contracts | Design completed; approval pending |
| 6 | Fixture, integration and Mr. A acceptance strategy and stop/go thresholds | Design completed; approval pending |
| 7 | Codex governance, work packages, first instruction and implementation gates | Design completed; approval pending |

**Implementation status:** Not started.  
**Source repository status:** Neither DPH nor VCL2FMXConverter modified.  
**Next required action:** Owner reads/reviews and approves or requests revisions to Phases 3–7, then separately authorizes WP0 when ready.
