"""Build DPH's own guides from implemented contracts and inspected source."""
from pathlib import Path
from datetime import datetime
import hashlib
import json
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

ROOT = Path(__file__).resolve().parent.parent
GUIDES = ROOT / 'docs' / 'guides'
GUIDES.mkdir(parents=True, exist_ok=True)

USER = [
('Purpose and evidence', [
'Delphi Project Handoff explains an explicitly selected Delphi project through source inventory, form information, symbols, relationships, control flow and attributed knowledge. It stores its work in one SQLite knowledge database per selected project. DPH is experimental Windows desktop software. Its static analysis is not a Delphi compiler and does not prove every runtime behavior.',
'Use the generation number, source hashes, certainty labels and diagnostics together. A complete captured analysis means the implemented analysis stages accepted their captured inputs. It does not mean a human approved the business explanation. PARTIAL means unavailable dependencies, unsupported syntax or bounded analysis prevented full coverage. DPH does not compile or execute the selected project, run its build scripts, load its component classes or connect to its production services.'
]),
('Start DPH', [
'Start DelphiProjectHandoff.exe from its deployed folder. Keep the migrations folder and Microsoft WebView2 loader with the deployment. WebView2 Runtime supports the optional embedded HTML preview. An unavailable preview must leave the exported HTML usable independently. The initial validated target is Windows Win32; another operating system has not been validated.',
'The Getting started page opens before a project is loaded. It explains the first ten minutes, each workspace tab, a small learning exercise, Delphi terms and repeatable checks. The header Getting started button returns to it at any time. Its native text fallback remains available without WebView2. Keep the help folder with the deployment.',
'The workspace has a left Explorer, central tabs and right Inspector. Drag either vertical splitter to resize the panes. The header contains project selection, cache opening, full reassessment, configuration, platform, extra defines and explicit dependency roots. The status area shows work in progress and the captured analysis status. The last successfully opened database identity is remembered in the local user profile and reopens detached.'
]),
('Attach a source project', [
'Choose Attach project and select the Delphi project file. The picker accepts dproj, dpr or groupproj. Choose a database filename ending in dphdb outside the analyzed source folder. DPH rejects database and export locations inside the source boundary and rejects reparse paths that could bypass that boundary. Keep each selected project in its own database.',
'Select Debug or Release and Win32 or Win64 as appropriate before analysis. Win64 is an analysis configuration choice; the current DPH executable is built for Win32. Extra defines use semicolons. Explicit dependency roots also use semicolons. Add only roots you intend to permit DPH to read. A missing dependency is a visible gap, not a reason to let discovery search neighboring projects without a boundary.',
'For the pinned VCL2FMXConverter Win32 reference, enter MSWINDOWS;WIN32 as extra defines to reproduce the recorded baseline. DPH does not synthesize every compiler built-in from the platform label. Supply the symbols required by the selected compiler environment; unknown conditional expressions remain uncertain.',
'Analysis runs in the background. Explorer data belongs to its displayed generation while the worker prepares another. Changed inputs during a scan supersede the capture and request reassessment. A partial or failed capture does not replace a previous complete published head. DPH retains the evidence needed to inspect partial results honestly.'
]),
('Open cached work', [
'Choose Open cache to inspect a saved dphdb database. DPH validates the cached workspace artifact against its SHA256 and generation before displaying it. Cached opening does not start a source scan. The cache opens detached until you explicitly attach its source project.',
'Detached mode allows historical inspection and authored notes. It does not follow cached filesystem paths to display source text or approve a current-source review. Attach the source when you want live hash checks, source navigation and human verification against current evidence. A missing or damaged cached artifact is reported rather than silently treated as a current view.'
,'A damaged supplemental screenshot does not block opening valid cached analysis. DPH reports Screenshot evidence unavailable and omits the rejected image from display. Repair or restore its managed evidence before publishing a bundle that uses it; do not replace its hash to disguise damaged content.'
,'Keep a copied database with its adjacent database.dphdb.views folder. DPH resolves cache files beside the opened database and verifies their hashes instead of following old absolute artifact paths. To move the source project, choose Relocate verified source and select the same project entry. Exact file identities, content hashes, availability and analysis selection must match the captured generation. A different copy is rejected. Accepted relocation preserves logical symbols and notes, requests human review and reassesses the new context.'
]),
('Learn the selected project', [
'Begin with Learn the project rather than trying to interpret the complete symbol index. Start here gives a six-step route: read actual startup statements, identify a familiar screen control, follow its event into code, inspect decisions and data, check gaps, then plan a controlled maintenance change. Each topic describes how to read the evidence and supplies project-specific starting points.',
'How the program starts quotes parsed program-body expressions with source locations and hashes. It does not substitute the first routine in a graph for the entry point. Screens and user actions links declared components. Follow an event explains binds, calls, callbacks and possible scheduling. Architecture, data and maintenance topics explain what their relationship kinds mean and where conclusions remain unsupported.',
'Double-click an Explorer object or follow a learning link to open Explain. It presents the declared contract, nearby source-author comments when captured, callers and consumers, outgoing interactions, decisions, attributed knowledge and a bounded execution trace. Source comments remain author documentation, not independently verified behavior. Expand a connection to see the precise evidence and derivation rule.',
'The learning and Explain pages run locally through WebView2. If the runtime is unavailable, a readable text fallback remains. Local learning projections avoid export-only redaction work; the publisher refuses to export them. A separately constructed publication model always applies redaction and exclusions.'
]),
('Explore and search', [
'Double-click an Explorer row to select its canonical object. The Inspector shows its identity, signature, condition, source range, source hash and serialized properties when available. Units, types, components and routines provide drill-down scopes. The breadcrumb reports the active scope and page. Parent moves upward; Back restores a prior selection.',
'Search matches object names, kinds and signatures across the project. A kind filter narrows the result. Pages contain at most 250 objects; Next page advances the result set. Clear the search or use Parent to broaden your route. Bookmark records the current canonical selection, and Bookmarks displays those selections. Bookmarks belong to the captured generation and reset when a new generation is loaded.',
'The References tab lists forward and reverse relationships with their certainty and derivation labels. Double-click a resolvable related object to inspect it. An unresolved target remains unresolved; the relationship is not proof that a named method actually ran.'
]),
('Read source and graph evidence', [
'The Source tab reads the attached source file and compares its bytes with the captured SHA256 before applying the source range. If the live file changed or cannot be decoded, DPH displays a stale or unavailable message instead of presenting the old range as a confirmed live location. External dependencies remain in the evidence model but are not followed by the local source viewer through an invented path.',
'The Graphs tab offers Execution, Procedure CFG, Caller / callee, Form navigation, Data flow and Change impact. Select a relevant routine or component before choosing a narrow graph. Graphs show at most 120 nodes and 960 edges. A narrower selection is preferable to interpreting a truncated large view as the complete program.',
'Confirmed static edges use blue. Uncertain edges use orange. Procedure CFG opens a labeled source-derived diagram when WebView2 is available, with a native graph fallback. Large routines collapse ordinary straight-line statements while retaining control nodes; arrows identify omitted statements. More than 70 retained control nodes produces an explicit limit instead of a misleading complete diagram. Other graph views retain their 120-node bound. Form navigation does not prove runtime window activation; Change impact is possible reachability. Click a native graph node to inspect its evidence.'
]),
('Inspect screens', [
'The Form designs tab reconstructs rectangles and text from serialized FMX or DFM data. It never creates untrusted component classes. The result is explicitly an approximate design-time view, not an actual runtime screenshot. Custom painting, runtime geometry, styles and unavailable inherited resources may differ from the running program.',
'Thumbnail displays a gallery of up to 60 forms. Fit scales the selected form to the viewport, Native uses its reconstructed size, Zoom displays 200 percent, and Full screen uses the larger window. The Full screen button toggles the DPH window size. Click a component rectangle to navigate to the corresponding canonical object when a source association is available.'
]),
('Import actual screenshot evidence', [
'Open Screenshots, enter the named contributor and a description including capture date and environment, then choose Import an existing PNG screenshot. Select an image you already captured and are authorized to preserve. DPH does not launch the selected application. PNG files are bounded to 20 MiB, 8192 pixels per dimension and 32 million pixels.',
'The managed image and its metadata are checksummed beside the knowledge database. Select a row to view the actual image and attribution. Runtime origin, capture time and environment are contributor claims and remain user supplied unverified. The associated generation is displayed, including when it is historical. Copy the adjacent views folder when moving the database.',
'Publishing includes only imported images matching the exported generation and included object scope. Excluding a linked source excludes its screenshot. The exported caption identifies the contributor and unverified state; private storage paths are omitted. Review screenshots for confidential material before sharing.'
]),
('Write attributed knowledge', [
'Use the Knowledge tab for notes, business rules, engineering rules, user help, maintenance, build and deployment details, troubleshooting, orientation, decisions and unknowns. Select the relevant Explorer object before starting New to link the record to that object. With no selected object, a new record applies to the project.',
'Enter a stable title, choose its kind, supply a named author and write the body. Save creates a new immutable revision pending human review. Titles and kinds remain stable after creation; update the body, or create and retire a replacement. Selecting a saved row displays its text, links, current state and complete authored and review history.',
'Unsaved text survives a background refresh. Save or explicitly Discard edit before switching projects, selecting another record, starting another record or closing. DPH will not silently approve an old saved revision while different unsaved text is visible.'
]),
('Review and retire knowledge', [
'Enter the named reviewer and select a saved revision. Verify review records your explicit approval of that text against the captured generation. Reject records a rejected explanation. Retire preserves an obsolete record and its history while resolving its pending task. The Pending reviews only filter shows records that still need attention.',
'Source or configuration changes invalidate human review separately from analysis. A successful rescan preserves authored text but cannot approve it. When a linked method disappears or is renamed, DPH keeps the old link as historical evidence and refuses to transfer verified knowledge automatically. Investigate continuity and create the appropriate reviewed replacement.',
'Attribution is a local named-author record, not an enterprise authentication system. A verified human explanation records the reviewer decision; it does not establish unwritten historical business intent automatically. Detached review requires source attachment first.'
]),
('Publish manuals and handoffs', [
'Open Publish. Choose Full project or Selected object and context. The task choice requires a selected canonical object and includes its incident technical context rather than a blind truncation of a full export. Enter explicit relative file or folder exclusions separated by semicolons. External source roots and sensitive filename categories are excluded by default.',
'Choose a new export folder name outside the source tree. DPH refuses an existing destination to avoid overwriting unrelated files. It creates offline index.html, local assets, canonical.json, editable engineering and user guides, technical JSONL indexes, evidence references, coverage and a checksum manifest. Generated AGENTS.md and source snapshots are excluded unless a separate explicit request is implemented and authorized.',
'Preview offline HTML opens the approved local index and generated hash-named object explanation pages through Edge. External addresses and arbitrary file navigation are blocked. Offline search and internal links work without a translation service. Atlas is unconfigured. The GTranslate region is disabled in the offline edition, and the language-label helper is local. No external translation or AI service receives source through this feature.',
'Run tools/export-pdf.ps1 with the BundleDirectory parameter for optional PDF companions. It uses LibreOffice and the approved Python 3.13 with pypdf, populates cached TOC page numbers while retaining changeable fields, and refreshes bundle checksums. Read coverage and known unknowns before treating an export as a final operating manual. Automatic documentation cannot invent missing end-user procedures.'
]),
('Validate and preserve exports', [
'Run DPH.ValidateHandoff.exe with the bundle directory and a separately retained trusted input fingerprint. It rejects stale exports by default. Add --allow-stale only to inspect the integrity of a historical or partial bundle; the flag does not establish current or complete source evidence.',
'Validate artifact filenames and SHA256 values against validation/manifest-sha256.json. The manifest records generation, input fingerprint, template version, scope, stale state and canonical hash. The validator also checks symbol, relationship, control-flow and evidence references and source ranges. A changed expected fingerprint rejects a stale bundle.',
'Hashes detect changed artifacts relative to their checksum index. They are not a digital signature proving the identity of an untrusted bundle author. Keep a trusted copy of the source fingerprint and export identity. Redaction recognizes common credential assignments, access keys, tokens and private keys; explicit exclusions and a disclosure review remain necessary for sensitive projects.',
'Keep the dphdb database together with its managed dphdb.views folder. The database is the authority for authored knowledge; generated manuals and diagrams are derived outputs. Project development backups are made before each authorized phase to D:, and validated changes are committed and pushed to both configured GitHub repositories.'
]),
('Troubleshoot common states', [
'PARTIAL analysis: read diagnostics and source availability. Unavailable framework units and unsupported syntax remain visible gaps. Do not clear the label by treating unresolved facts as verified. Source changed during analysis: allow reassessment or invoke Full reassessment after the source settles.',
'Cached artifact missing or damaged: retain the database and its previous backups, then attach the correct source to rebuild a derived workspace. Different source root: DPH rejects cross-project reuse; relocation must preserve and verify project identity rather than attach an unrelated project. Knowledge changed since loading: refresh and review the current immutable revision before saving.',
'Embedded preview unavailable: inspect index.html in the exported folder and check the deployed Microsoft loader and WebView2 Runtime. No named author or reviewer: enter an attributable name. Closing waits for background work: cancellation is checked at safe stage boundaries; a long parser stage does not execute the analyzed program.'
]),
('Practice a maintenance handoff', [
'Locate startup from the selected project inventory. Find the main form and a visible action, follow its serialized event to the handler, inspect callbacks and downstream calls, and distinguish certain edges from inferred ones. Locate a dry-run branch or another configuration-dependent path, then identify the model used to produce a report.',
'Record what the evidence establishes and what remains unknown. Add an attributed author answer for missing business rationale, reassess a controlled source change, and verify that the explanation remains pending review. Export a focused task bundle and validate its hashes. This scripted practice supports onboarding; it does not replace the required independent first-time programmer acceptance exercise.'
])]

ENGINEERING = [
('Architecture and boundaries', [
'DPH is an independent Delphi FMX application. It has no converter runtime or build dependency. The pinned VCL2FMXConverter v6.0.0 corpus is test input only, at commit e1fd10b2d3b06f2fc3f726b8eb7f234a54faf63d. No converter source was copied into the current analyzer. Preserve the original planning documents and global agents.md byte for byte.',
'The pipeline is selected project, bounded inventory, read-only byte acquisition, lexical and conditional processing, Pascal and form IR, semantic relationships and control flow, revision-consistent SQLite capture, cached workspace projection, curated knowledge and derived publication. Contract data remains separate from FMX. Every unsupported construct or unavailable dependency must remain diagnosable rather than being promoted into false completeness.',
'All application controls are serialized in DPH.UI.Main.fmx and editable in the IDE. List contents and paint-box geometry are data projections. No scanned component class is instantiated. Avoid adding runtime-only controls, Pascal class helpers or an alternative authoritative store without explicit authorization.'
]),
('Rework and acceptance status', [
'The owner rejected the earlier WP7 delivery as inadequate for learning and handoff. The statement that implementation through WP7 was complete has been withdrawn. docs/Rework_Requirements_Audit.txt compares the original plan with the implemented product and outstanding work. Historical WP reports remain historical evidence, not acceptance of the reworked experience.',
'The rework adds a first-launch Getting started course, deterministic explanation engine, guided learning workspace, source-comment context, event traces, labeled and collapsed procedure-flow views, attributed screenshot imports and richer project-specific publication. Run tools/build-learning.cmd with an optional pinned reference database path for dedicated learning and real-WebView2 tests. The source-based first-time-programmer exercise still needs a human participant.',
'Affected-only semantic recomputation, broader external-definition interpretation and retention/continuity controls remain incomplete. Source safety, privacy, attribution and exact generation links are retained. Do not turn an automated pass count into a claim that every requirement or the human onboarding goal is finished.'
]),
('Build and deployment', [
'The installed compiler is RAD Studio 37.0.59082.6021. Load C:\\Program Files (x86)\\Embarcadero\\Studio\\37.0\\bin\\rsvars.bat before compiling. tools/build-wp0.cmd builds DelphiProjectHandoff.dproj with elevated MSBuild and runs the FMX resource smoke test. Output is bin/Win32/Debug, with DCUs in dcu/Win32/Debug. The initial executable target is Windows Win32.',
'Deploy the executable, migrations 001_foundation.sql and 002_constraints.sql, and the architecture-matched WebView2Loader.dll. The reviewed Microsoft WebView2 SDK package is pinned to 1.0.4258.31; retain tools/WebView2/LICENSE.txt with binary redistribution. The browser loads the DLL by its absolute executable-folder path and activates Edge only when preview is requested. There is no intended IE fallback.',
'The repository standard folders include bin, dcu, docs/guides, docs/pdf, export, help, images and icons, samples, source distributions and tools. Deploy help/index.html for first-launch education. Reference source and generated test databases remain ignored. Use the explicitly approved Python 3.13 executable for project tooling and the installed LibreOffice, never Microsoft Word.'
]),
('Input acquisition and project scope', [
'DPH.Project.Inventory follows the selected project, explicit references, uses clauses, include paths and approved external roots. Project XML is passive: targets and imported build scripts are not executed. Canonical paths are project relative and normalized; traversal, ambiguous macros, reparse paths, cycles and oversized acquisition are rejected or diagnosed. A repository-wide count of Pascal files is not the build scope.',
'DPH.Project.Source opens input read only, checks the final opened Windows handle path, captures bytes, records SHA256 and verifies decoding by round trip. Unicode byte offsets, line endings and explicit legacy encodings remain in the evidence contract. The maximum acquired source is 16 MiB. Binary forms are parsed as data; unsupported resources remain gaps.',
'A source viewer must re-acquire the live file and match the captured hash before using a cached range. Externally referenced sources use their explicit canonical inventory identity. Never invent a neighboring source path from a cached filename or execute input to fill an analysis gap.'
]),
('Syntax contracts and limits', [
'DPH.Parse.Model defines IR schema 1, analyzer DPH-WP2-1, token and node limits, source ranges and diagnostics. Lexing preserves original tokens and conditional information. Preprocessing evaluates supported expressions, explicit defines and includes while retaining uncertainty for unknown branches. An unavailable compiler symbol is not automatically a false condition.',
'The Pascal parser extracts declarations, routines, anonymous methods and supported statements into IR. Declaration and implementation occurrences remain distinguishable before semantic unification. The form parser accepts supported text and binary DFM/FMX structures without loading component packages. The inventory reads relevant project configuration and resources through bounded adapters.',
'Current bounds include 250000 tokens, 100000 IR nodes, nesting 128 and 10000 diagnostics. Opaque assembler, malformed syntax and unsupported grammar are partial. Tests use exact golden IR, encoding edge cases, cyclic includes, passive malicious imports and changed source. Maintain source byte ranges and diagnostics when extending support.'
]),
('Symbols and typed relationships', [
'DPH.Analysis.Model defines semantic schema 1 and analyzer DPH-WP3-1. Stable symbol keys contain qualified identity, signature and conditional variant. DPH.Analysis.Symbols unifies supported routine prototypes and bodies, resolves cross-unit declarations, typed receivers and suitable overloads, associates form events and records anonymous callbacks.',
'Relationship certainty is confirmed_static, possible_dynamic, inferred, runtime_observed or unresolved. Passive scanning never claims runtime_observed. A uses dependency is not a call. Known lexical calls, serialized bindings and declared types carry derivation rules and source ranges. Recognized asynchronous API spelling can establish a possible scheduling relationship without proving execution order.',
'Method pointers, unresolved receivers, dynamic dispatch, generated types and framework behavior must retain uncertainty. Basic reads, writes, callback assignment, static SQL spelling and report-model rendering are conservative analyses. Renames are distinct identities until continuity is reviewed; offsets alone must not reassign knowledge.'
]),
('Control flow and impact', [
'DPH.Analysis.Flow builds per-routine control-flow nodes and typed edges for supported sequences, branches, loops, returns and exception/finally paths. Routine identity, source hash, range, node kind and expression remain available to inspectors and exports. Flow is bounded to 100000 nodes, 300000 edges and nesting 128.',
'Impact traversal is possible reachability through supported relationships. Do not label it proved runtime impact. The UI bounds a displayed graph to 120 nodes and 960 edges, while the stored semantic graph is the fuller evidence model. Uncertain edges remain visually distinct. Unsupported flow does not become a fabricated successful path.'
]),
('SQLite generations and durability', [
'TDPHKnowledgeStore owns one FireDAC SQLite connection on its creating thread and serializes writer access through a named mutex. Foreign keys and synchronous FULL are enabled. Default journal mode is DELETE; WAL is an explicit local-store option. Direct cross-thread writes are rejected. SQLite 3.42.0 with FTS5 was measured by the storage tests.',
'Schema 2 is created through two checksum-verified migrations. Existing migration text is immutable. A newer incompatible schema is rejected safely. Failed upgrade DDL and ledger changes roll back, and an upgrade from an existing schema makes a recoverable pre-migration database backup. Interrupted running generations recover as failed, preserving the previous published head.',
'ObserveManifest records current fingerprints independently of the capture. BeginGeneration freezes configuration and manifest identity. Syntax and semantic facts are staged in transactions. Before publication, inputs and configuration are revalidated. Only a coherent complete generation becomes the current head. Partial, failed or superseded captures cannot clear the exact-input stale state or overwrite a prior current head.'
]),
('Evidence and immutable history', [
'Normalized tables include projects, configurations, source files, file revisions, generations, generation files, entities, entity versions, evidence, relationships, component properties, control-flow nodes and edges, knowledge records and revisions, links, review tasks, translations, artifacts, export jobs and audit events. Foreign keys tie evidence and relationships to their producing generation.',
'Triggers prevent mutation of terminal generations, source revisions, captured facts, configurations and authored knowledge revisions. Evidence ranges must fit the captured source bytes and use the generation analyzer version. Historical file and entity identities cannot be changed casually. A missing source is retained as missing; its historical annotations survive.',
'Modification detected, analysis stale, knowledge review needed, analysis failed and reassessment requested are separate persistent flags. A UI summary is a projection of these states, not a replacement for them. Parser success must not clear human review.'
]),
('Background coordination and cached views', [
'DPH.Workspace.Worker is a persistent TThread with bounded request and response queues. It initializes COM for passive MSXML parsing, owns database operations in the worker, and retains analyzer instances across requests. FMX polls responses with a timer, avoiding queued closures that outlive the form.',
'A stopped Delphi queue can report success while returning an empty item. Poll checks both the wait result and a non-nil response; shutdown tests guard against a destructor loop. Cancellation is checked between stages and marks a staged running generation failed when appropriate. It is not a promise of interruption inside every parser loop.',
'Workspace projections are managed JSON files in database.dphdb.views named by SHA256 and registered in artifacts. Cached opening verifies the managed path, size, checksum and generation. The default is detached until explicit source attachment. Connected checks compare manifest fingerprints and selection identity every ten seconds. Syntax cache reuse is bounded; semantic recomputation is currently conservative rather than a claim of a minimal incremental semantic solver.'
]),
('FMX navigation and visualization', [
'DPH.UI.Main binds its published controls to the FMX resource. Explorer queries are paged at 250 rows; data filtering supports kind, text and qualified scope. History and bookmarks use canonical keys, with bookmarks reset on a new captured generation. Inspector output retains source metadata and serialized properties. Source memo navigation is permitted only after live hash validation.',
'Graph paint boxes draw bounded evidence data with palette and geometry values supplied by design-time style rectangles. Screen reconstruction draws approximate source-derived rectangles without creating components. Its gallery is bounded to 60 forms. Runtime styles, custom painting and inherited resources are not silently fabricated.',
'Keep lifecycle and ownership explicit: the view owns its JSON document, UI arrays own their records, responses transfer document or knowledge ownership to the main form, and the worker frees unconsumed responses during shutdown. Guard unsaved authored text before changing projects or replacing editor state.'
]),
('Curated knowledge and review', [
'SaveKnowledge requires title, body, a named author, a supported kind and a captured generation. Existing records require their expected revision and stable title/kind. Each edit appends a needs_review revision, preserves links and opens a pending task. Knowledge bodies are bounded to 1 MiB. Authored text is never regenerated from parser output.',
'ReviewKnowledge requires the expected current revision, a named reviewer and a matching captured source/configuration. The connected worker observes current source before accepting a review. A missing linked entity cannot be verified under a replacement name. Verification, rejection or retirement appends a revision and records attribution; history remains append only.',
'Manifest and configuration changes conservatively invalidate active knowledge, derived artifacts and translations. A partial static capture may support review of an attributable statement against available evidence, but its partial coverage remains visible. Local names are not authenticated enterprise identities. Human verification and automatic static derivation remain different evidence categories.'
]),
('Canonical publication and privacy', [
'DPH.Publish.Model constructs one versioned documentation model from a captured workspace and current curated knowledge. It carries generation, configuration, input/context fingerprints, detached/stale state, symbols, typed relationships, control flow, source references, human history, coverage and explicit unknowns. Full and task-scoped views share those facts.',
'Task scope selects the requested identities and complete direct incident context. It rejects missing or excluded seeds and rejects an oversized task rather than silently truncating a full export. External source roots and sensitive filename categories are excluded by default. Explicit relative prefix exclusions remove file-derived symbols and relationships. Source snapshots and generated AGENTS.md are absent by default.',
'Redaction recognizes common credential assignments, private keys, AWS access keys and JWT-shaped tokens throughout string data. It is defense in depth, not a guarantee that every project-specific secret format is recognizable. Require explicit exclusions and a disclosure review for sensitive content. No translation or AI provider is contacted by normal publishing.'
]),
('HTML guides and bundle validation', [
'DPH.Publish.Export writes a new destination outside source. The offline HTML uses encoded imported text, local search and styles, internal anchors, print CSS and a restrictive content security policy. The default WebView2 policy permits only the authorized local index and about:blank; publication explicitly enables hash-named object pages in its managed objects folder. Learning and help retain the index-only policy. There is no arbitrary native bridge. Data does not supply executable markup.',
'JSONL indexes contain symbols, relationships, forms/events, data usage, configuration, flow nodes, knowledge and evidence references. Manifest and checksum files accompany canonical.json. The validator checks filenames, hashes, expected input fingerprint, canonical identity, source hash/range, generation and cross-reference integrity. A stale manifest is rejected by default. Unsigned hashes establish integrity relative to the index, not author authenticity.',
'Editable engineering and user DOCX guides derive from the same sections and evidence model. They include title, last changed capture identity and a changeable TOC field. LibreOffice provides companion PDFs; the project rendering tool verifies cached page numbers and renders page images for layout inspection. Missing business procedures stay explicitly absent rather than being invented.'
]),
('Translation boundary', [
'IDPHTranslationProvider exposes provider identity, version, external status and prose translation. Protected segments retain identifiers, SQL, paths, hashes and protocol keys byte for byte. Cache keys include source content, revision, source/target locales and provider/version. Changed prose produces a fresh pending entry; named review applies to the exact cached translation.',
'TDPHAtlasAdapter is deliberately unconfigured because the exact Atlas product, transport, licensing and confidentiality have not been selected. External providers require explicit consent. The current adapter throws before transmission, and tests use an offline mock. The offline GTranslate region is disabled, with local bilingual labels and sorting; do not activate network translation merely because a generic widget name appears in documentation.'
]),
('Verification and release discipline', [
'Run the phase build/test scripts elevated with the installed toolchain. WP0 checks FMX resource ownership; WP1 checks storage, crash recovery and migrations; WP2 checks inventory, encoding, syntax and source safety; WP3 checks semantics and pinned reference traces; WP4 checks workspace/background behavior; WP5 checks immutable authored history and pending review; WP6 checks publication, exclusions, sanitization, hashes and translation protection.',
'Use exact input hashes before and after analysis, including failures. Preserve original reference and instruction files. Keep tests that demonstrate invariants rather than tests that merely mirror implementation. New source, validation failure or unresolved risk justifies another targeted test; a passing unchanged phase does not need endless repetition.',
'Before each authorized phase, create the full D: pre-change backup and verify SHA256. Review intended Git changes, commit validated work and push both public and private remotes without force or history rewriting. Remove a stale zero-byte index lock only after verifying no Git process runs. WP7 records measured performance, portability, security and explicit acceptance evidence. Independent first-time programmer acceptance and unknown historical business intent cannot be invented by automation.',
'On the recorded Core i7-1165G7 host with eight logical processors and about 16 GB RAM, the pinned reference pipeline measured 82.6 seconds for full capture, 2.87 seconds for cached opening and 75.9 seconds for incremental reassessment. The message-pump maximum gap was 64 ms. Peak test-process working set was about 1.21 GiB, including repeated captures, JSON cloning and FMX/WebView2 tests. These are baseline measurements, not agreed hardware-independent budgets. Large syntax-cache fallback and conservative semantic recomputation explain the modest reassessment speedup. Formal acceptance retains independent complex-flow review, missing business/user content, AC-25 and performance-budget agreement as outstanding.'
])]

def field(run, kind, text=None):
    element = OxmlElement('w:fldChar')
    element.set(qn('w:fldCharType'), kind)
    run._r.append(element)
    if text:
        instruction = OxmlElement('w:instrText')
        instruction.set(qn('xml:space'), 'preserve')
        instruction.text = text
        run._r.append(instruction)

def build(filename, title, audience, sections):
    doc = Document()
    section = doc.sections[0]
    section.top_margin = section.bottom_margin = Inches(.8)
    section.left_margin = section.right_margin = Inches(.85)
    section.page_width, section.page_height = Inches(8.5), Inches(11)
    for name in ['Normal', 'Title', 'Subtitle', 'Heading 1', 'Heading 2']:
        style = doc.styles[name]
        style.font.name = 'Calibri'
        style.font.color.rgb = RGBColor(0, 0, 0)
    for border in list(doc.styles.element.iter(qn('w:pBdr'))):
        border.getparent().remove(border)
    normal = doc.styles['Normal']
    normal.font.size = Pt(11)
    normal.paragraph_format.space_after = Pt(7)
    normal.paragraph_format.line_spacing = 1.1
    doc.styles['Heading 1'].font.size = Pt(16)
    doc.styles['Heading 1'].paragraph_format.space_before = Pt(15)
    doc.styles['Heading 1'].paragraph_format.keep_with_next = True
    doc.add_paragraph(title, 'Title')
    doc.add_paragraph('Delphi Project Handoff', 'Subtitle')
    doc.add_paragraph('Windows desktop experimental software')
    doc.add_paragraph('Last changed 11 October 2026')
    doc.add_paragraph(audience)
    doc.add_paragraph('This guide describes the implemented application and its evidence limits. Use the phase acceptance records for exact measured results and unresolved release gates.')
    doc.add_page_break()
    doc.add_paragraph('Contents', 'Title')
    field(doc.add_paragraph().add_run(), 'begin', ' TOC \\o "1-1" \\h \\z \\u ')
    field(doc.add_paragraph().add_run(), 'separate')
    for heading, _ in sections:
        doc.add_paragraph(heading)
    doc.add_paragraph('Source and revision evidence')
    field(doc.add_paragraph().add_run(), 'end')
    doc.add_page_break()
    for heading, paragraphs in sections:
        doc.add_heading(heading, 1)
        for paragraph in paragraphs:
            doc.add_paragraph(paragraph)
        if filename == 'DPH_User_Guide.docx' and heading == 'Learn the selected project':
            doc.add_page_break()
            doc.add_heading('The displayed learning pages', 2)
            doc.add_paragraph('These images are direct WebView2 captures from the running DPH test application, not proposed interface mockups. They show the visible portion of scrollable pages.')
            for image_name, caption in [
                ('rework-getting-started.png', 'Getting started: first-launch education before a project is loaded.'),
                ('rework-reference-trace.png', 'Explain: actual event/callback reachability in the pinned converter, retaining certainty and evidence.')
            ]:
                image_path = ROOT / 'docs' / image_name
                if not image_path.exists():
                    raise RuntimeError(f'Missing actual UI capture: {image_path}')
                doc.add_picture(str(image_path), width=Inches(5.0))
                doc.add_paragraph(caption)
            doc.add_page_break()
    doc.add_heading('Source and revision evidence', 1)
    doc.add_paragraph('The following source files and resources define this guide. SHA256 values identify the inspected implementation. Rebuild the guides after validated changes and retain the associated acceptance evidence.')
    evidence = []
    for source in sorted(ROOT.glob('DPH.*.pas')):
        evidence.append({'path': source.name, 'sha256': hashlib.sha256(source.read_bytes()).hexdigest()})
    for name in ['DPH.UI.Main.fmx', 'DelphiProjectHandoff.dpr', 'DelphiProjectHandoff.dproj']:
        source = ROOT / name
        evidence.append({'path': name, 'sha256': hashlib.sha256(source.read_bytes()).hexdigest()})
    for item in evidence:
        paragraph = doc.add_paragraph(item['path'])
        paragraph.paragraph_format.keep_with_next = True
        run = doc.add_paragraph(item['sha256']).runs[0]
        run.font.name = 'Consolas'
        run.font.size = Pt(8)
    footer = section.footer.paragraphs[0]
    footer.add_run('DPH experimental software    ')
    field(footer.add_run(), 'begin', ' PAGE ')
    field(footer.add_run(), 'separate')
    footer.add_run('1')
    field(footer.add_run(), 'end')
    settings = doc.settings.element
    update = OxmlElement('w:updateFields')
    update.set(qn('w:val'), 'true')
    settings.append(update)
    output = GUIDES / filename
    doc.save(output)
    return evidence

required = {
    'DPH.UI.Main.pas': ['PublishClick', 'KnowledgeClick', 'DiscardKnowledgeClick', 'BrowserShouldLoad'],
    'DPH.Storage.Database.pas': ['SaveKnowledge', 'ReviewKnowledge', 'RecordExport', 'PublishGeneration'],
    'DPH.Publish.Export.pas': ['WriteGuide', 'Validate'],
    'DPH.Publish.Translation.pas': ['TranslateProse', 'Review'],
}
for filename, names in required.items():
    source = (ROOT / filename).read_text(encoding='utf-8-sig')
    for name in names:
        if name not in source:
            raise RuntimeError(f'Guide refers to an absent implementation: {filename}:{name}')

evidence = build('DPH_User_Guide.docx', 'DPH User Guide', 'For the person inspecting a Delphi project and recording its handoff knowledge', USER)
build('DPH_Engineering_Guide.docx', 'DPH Engineering Guide', 'For a Delphi developer building maintaining and validating DPH', ENGINEERING)
(ROOT / 'docs' / 'guide-source-validation.json').write_text(json.dumps({'guide_version': 2, 'sources': evidence, 'last_changed': '2026-10-11'}, indent=2), encoding='utf-8')
print('Created editable DPH user and engineering guides with source evidence and TOC fields')
