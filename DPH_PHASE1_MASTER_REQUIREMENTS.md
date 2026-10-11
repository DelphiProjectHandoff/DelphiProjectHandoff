# Delphi Project Handoff (DPH)
## Phase 1 — Master Functional Requirements and Approved Expansions

**Status:** Phase 1 owner-approved; design reference for Codex, not implementation authorization.

**Scope:** DPH is an independent Delphi FMX application documenting **one explicitly selected Delphi project or project group**. Other programs/services are described only to the extent they directly affect that selected application. VCL2FMXConverter is an independent reference application; selected code may be copied and adapted, never made a shared dependency. Passive discovery is read-only.

This document reconstructs the Phase 1 inventory authored in the planning conversation, retaining its domain and feature identifiers. Original feature descriptions are followed by subsequent approved expansion items and operational decisions. The original planning discussion characterized the inventory as **387 proposed features across 23 domains**; the enumerated entries below are the authoritative list for traceability, rather than an assumed total. Some later expansions overlap original features and require consolidation during implementation planning.

### Acquisition codes
A = static automatic discovery; R = approved runtime observation; M = manual knowledge; I = AI-assisted interpretation; X = imported external evidence. A finding must preserve its method, source and verification state.

### Priorities
P0 = foundation; P1 = core; P2 = advanced; P3 = specialized. Priorities in the original inventory apply at domain level; finer priority decisions are part of subsequent implementation reviews.

# A. Original 23-domain feature inventory

## DPH-01 — Projects, Applications & Portfolios (P0)

- **01.01** Company, department, and business-unit records
- **01.02** Application and project catalogs
- **01.03** Multiple applications within one knowledge repository
- **01.04** Delphi project and project-group discovery
- **01.05** Executables, libraries, packages, and services
- **01.06** Application purpose, scope, and description
- **01.07** Business-criticality classification
- **01.08** Application ownership and support contacts
- **01.09** Production, test, staging, and development environments
- **01.10** Application relationships and dependencies
- **01.11** Active, legacy, retired, and planned systems
- **01.12** Project maturity, maintenance status, and lifecycle
- **01.13** Vendor, license, and support information
- **01.14** Application architecture overviews

## DPH-02 — Source Code Intelligence (P0)

- **02.01** Project-wide source-file inventory
- **02.02** Unit declarations and implementations
- **02.03** Classes, records, interfaces, and helper types
- **02.04** Methods, functions, and procedures
- **02.05** Parameters, return values, and overloads
- **02.06** Variables, constants, enumerations, and sets
- **02.07** Generic types, helpers, and anonymous methods
- **02.08** Inheritance and interface implementation
- **02.09** Properties, visibility, and accessors
- **02.10** Unit dependency and symbol-reference mapping
- **02.11** Compiler directives and conditional compilation
- **02.12** Exception handling and resource ownership
- **02.13** Memory management, object lifetimes, and ownership
- **02.14** Threading, asynchronous tasks, and synchronization
- **02.15** Source comments and embedded documentation
- **02.16** Unused or apparently unreachable code candidates
- **02.17** Duplicate and potentially redundant code
- **02.18** Source complexity and maintainability metrics
- **02.19** Precise source references and navigation
- **02.20** Source-code comparison across revisions

## DPH-03 — Logic, Control Flow & Execution (P0)

- **03.01** Application startup and initialization sequence
- **03.02** Application shutdown and cleanup sequence
- **03.03** Procedure and function call graphs
- **03.04** Reverse call graphs (who calls this?)
- **03.05** Conditional branches and decision paths
- **03.06** Loops and iteration logic
- **03.07** Event-driven execution tracing
- **03.08** Exception and recovery pathways
- **03.09** State transitions and state-machine descriptions
- **03.10** Data movement through procedures
- **03.11** Business-process execution sequences
- **03.12** Thread and task interaction diagrams
- **03.13** Recursive calls and potential cycles
- **03.14** Timers, callbacks, and scheduled procedures
- **03.15** Dynamic dispatch and uncertain call targets
- **03.16** Runtime trace correlation with static analysis
- **03.17** Logic-flow diagrams and readable explanations
- **03.18** Entry-point-to-result execution narratives

## DPH-04 — Forms, Screens & User Interfaces (P0)

- **04.01** DFM and FMX form discovery
- **04.02** Screen and form inventory
- **04.03** Form thumbnails and gallery views
- **04.04** Fit-to-window and full-size screen views
- **04.05** Full-screen and zoomable inspection
- **04.06** Visual component hierarchy
- **04.07** Component names, classes, and properties
- **04.08** Component-to-event-handler relationships
- **04.09** Form navigation and opening logic
- **04.10** Screen-to-screen navigation diagrams
- **04.11** Data bindings and dataset relationships
- **04.12** Validation rules and displayed error messages
- **04.13** Keyboard shortcuts and focus order
- **04.14** Menus, context menus, and toolbars
- **04.15** Dynamic and runtime-created controls
- **04.16** Responsive layouts, anchors, and alignments
- **04.17** Third-party UI components
- **04.18** Form inheritance and embedded frames
- **04.19** User-visible actions and business purposes
- **04.20** Screen history and visual change comparisons

## DPH-05 — Data, Databases & Transactions (P1)

- **05.01** Database connection inventory
- **05.02** Database engines and versions
- **05.03** Tables, views, and schemas
- **05.04** Columns, data types, and constraints
- **05.05** Primary, foreign, and unique keys
- **05.06** Indexes and performance-related structures
- **05.07** Stored procedures, functions, and triggers
- **05.08** Entity-relationship diagrams
- **05.09** Data dictionaries and business meanings
- **05.10** SQL statements linked to source locations
- **05.11** Dataset components and bindings
- **05.12** Read, insert, update, and delete operations
- **05.13** Transaction boundaries and rollback behavior
- **05.14** Data validation and transformation rules
- **05.15** Data lineage from input to final destination
- **05.16** Migration and schema-version history
- **05.17** Import/export file formats
- **05.18** Data retention and archival requirements
- **05.19** Data quality and integrity checks
- **05.20** Backup and restoration requirements

## DPH-06 — Business Operations & Rules (P1)

- **06.01** Business-process inventory
- **06.02** Departmental workflows
- **06.03** End-to-end process diagrams
- **06.04** Business-rule catalog
- **06.05** Business-rule-to-source-code links
- **06.06** Calculations and formulas
- **06.07** Approval and authorization workflows
- **06.08** Exception handling in business operations
- **06.09** Daily, weekly, monthly, and annual operations
- **06.10** Financial and regulatory deadlines
- **06.11** Critical operational dependencies
- **06.12** Business terminology and glossary
- **06.13** Policy and procedural requirements
- **06.14** Business continuity during system outages
- **06.15** Consequences of failures or incorrect processing
- **06.16** Business ownership of rules and decisions

## DPH-07 — Dependencies & Integration (P1)

- **07.01** Internal unit and package dependencies
- **07.02** Third-party Delphi component inventory
- **07.03** DLL and shared-library dependencies
- **07.04** COM, ActiveX, and external automation
- **07.05** REST, SOAP, and other API integrations
- **07.06** Network protocols, endpoints, and ports
- **07.07** File-based system interfaces
- **07.08** Messaging, queues, and event systems
- **07.09** Hardware, printers, scanners, and devices
- **07.10** External systems and their owners
- **07.11** Interface authentication requirements
- **07.12** Data formats, schemas, and contracts
- **07.13** Retry, timeout, and failure behavior
- **07.14** Compatibility and version requirements
- **07.15** Dependency diagrams and failure propagation

## DPH-08 — Configuration, Building & Deployment (P1)

- **08.01** Delphi compiler and IDE version
- **08.02** Build configurations and target platforms
- **08.03** Project compiler options
- **08.04** Conditional symbols and defines
- **08.05** Search paths and library paths
- **08.06** Required packages and dependencies
- **08.07** Resource files and application assets
- **08.08** Build instructions and scripts
- **08.09** Reproducible build verification
- **08.10** Environment-specific configuration
- **08.11** Installation and upgrade instructions
- **08.12** Runtime prerequisites
- **08.13** Deployment destinations and topologies
- **08.14** Rollback and recovery procedures
- **08.15** Versioning and release records
- **08.16** Secrets and credential-reference locations
- **08.17** Build troubleshooting
- **08.18** Production deployment verification

## DPH-09 — Runtime, Monitoring & Troubleshooting (P1)

- **09.01** Runtime architecture and processes
- **09.02** Services, daemons, and background tasks
- **09.03** Scheduled operations and timers
- **09.04** Logging locations and formats
- **09.05** Exception catalogs and error messages
- **09.06** Diagnostic procedures
- **09.07** System health and monitoring indicators
- **09.08** Common problems and solutions
- **09.09** Known defects and workarounds
- **09.10** Troubleshooting decision trees
- **09.11** Performance bottlenecks and constraints
- **09.12** Resource requirements
- **09.13** Incident records and lessons learned
- **09.14** Restart, shutdown, and recovery sequences
- **09.15** Outage-impact analysis
- **09.16** Disaster recovery and restoration testing
- **09.17** Scheduled-job dependency and failure chains
- **09.18** Escalation paths and emergency contacts

## DPH-10 — Security, Permissions & Compliance (P1)

- **10.01** Authentication mechanisms
- **10.02** Authorization and user roles
- **10.03** Permission checks linked to source code
- **10.04** Sensitive data classifications
- **10.05** Data encryption and key-management references
- **10.06** API credentials and secrets-handling procedures
- **10.07** User activity and audit logging
- **10.08** Security configuration requirements
- **10.09** Trust boundaries and data exposure
- **10.10** Vulnerability and risk documentation
- **10.11** Regulatory and contractual requirements
- **10.12** Security-related change history
- **10.13** Security incident procedures
- **10.14** DPH knowledge-access permissions
- **10.15** Redaction of sensitive information in exports
- **10.16** Approval controls for confidential handoffs

## DPH-11 — Engineering Knowledge & History (P1)

- **11.01** Architecture decisions and rationale
- **11.02** Design assumptions and constraints
- **11.03** Original requirements and specifications
- **11.04** Technical debt inventory
- **11.05** Known limitations
- **11.06** Alternative designs previously evaluated
- **11.07** Code ownership and expertise
- **11.08** Maintenance history
- **11.09** Git revision and commit references
- **11.10** Change requests and reasons
- **11.11** Design and implementation notes
- **11.12** Unfinished work and proposed improvements
- **11.13** Deprecations and compatibility issues
- **11.14** Engineering standards and conventions
- **11.15** Lessons learned from failures
- **11.16** Knowledge-capture interviews

## DPH-12 — User Manuals, Training & Help (P1)

- **12.01** Automatically generated screen catalog
- **12.02** Screen descriptions and purposes
- **12.03** Control and field explanations
- **12.04** Step-by-step user procedures
- **12.05** Common task walkthroughs
- **12.06** Error-message explanations
- **12.07** User role-specific instructions
- **12.08** Screenshots and annotated interface views
- **12.09** Business terminology and definitions
- **12.10** Frequently asked questions
- **12.11** Tutorials and training lessons
- **12.12** Troubleshooting for nontechnical users
- **12.13** Printable and searchable manuals
- **12.14** Context-sensitive help links
- **12.15** Version-specific documentation
- **12.16** Translation of user-facing documentation

## DPH-13 — Project Explorer & Visualization (P0)

- **13.01** Hierarchical project tree
- **13.02** Expandable and collapsible categories
- **13.03** Multiple simultaneous Explorer panes
- **13.04** Dockable and resizable panels
- **13.05** Tabbed documents and views
- **13.06** Thumbnail galleries
- **13.07** Fit-to-window and actual-size views
- **13.08** Zoom, pan, and full-screen viewing
- **13.09** Call, dependency, and data-flow diagrams
- **13.10** Visual database relationships
- **13.11** Source-code and documentation side by side
- **13.12** Bookmarks, favorites, and recent items
- **13.13** User-defined Explorer views
- **13.14** Breadcrumb navigation and history
- **13.15** Multiple monitor support
- **13.16** Graph node inspection and drill-down
- **13.17** Expandable technical detail levels
- **13.18** Exportable and printable diagrams

## DPH-14 — Search, Navigation & Impact Analysis (P0)

- **14.01** Global full-text search
- **14.02** Search by source-code symbol
- **14.03** Search by form, component, or event
- **14.04** Search by database object
- **14.05** Search by business process or rule
- **14.06** Search by error message
- **14.07** Search by file, path, or configuration
- **14.08** Relationship-aware search
- **14.09** Reverse dependency discovery
- **14.10** Change-impact analysis
- **14.11** Cross-application impact analysis
- **14.12** Natural-language question answering
- **14.13** Saved queries and filtered result sets
- **14.14** Navigation to original source locations
- **14.15** Search results with evidence references
- **14.16** Change-impact reports

## DPH-15 — Discovery, Evidence & Verification (P0)

- **15.01** Full initial project scan
- **15.02** Incremental rescanning
- **15.03** Change detection using file hashes and revisions
- **15.04** Delphi source-code parsing
- **15.05** DFM/FMX parsing
- **15.06** Project and package metadata parsing
- **15.07** Database metadata discovery
- **15.08** External-document ingestion
- **15.09** Runtime observation import
- **15.10** AI-generated explanation with evidence
- **15.11** Manual fact verification and approval
- **15.12** Evidence provenance and source locations
- **15.13** Confidence and verification classifications
- **15.14** Stale-documentation detection
- **15.15** Conflicting-information detection
- **15.16** Missing-information discovery
- **15.17** Parser failure and unsupported-syntax reporting
- **15.18** Source-to-documentation traceability
- **15.19** Analysis completeness measurements
- **15.20** Reproducible analysis and validation tests

## DPH-16 — Knowledge Database & Versioning (P0)

- **16.01** Central structured knowledge repository
- **16.02** Stable identifiers for every knowledge object
- **16.03** Relationships among all object types
- **16.04** Source-code reference storage
- **16.05** Technical explanations and annotations
- **16.06** Human-authored knowledge records
- **16.07** Document and image attachments
- **16.08** Analysis snapshots and revision history
- **16.09** Knowledge-record versioning
- **16.10** Conflict and change tracking
- **16.11** Cross-reference integrity checking
- **16.12** Custom object types and attributes
- **16.13** Tags, classifications, and metadata
- **16.14** Import/export and backup
- **16.15** Database schema migration
- **16.16** Multiuser review and approval support
- **16.17** Full-text and relationship indexes
- **16.18** Data-retention and archival controls

## DPH-17 — HTML, Translation & Publishing (P1)

- **17.01** Integrated HTML documentation viewer
- **17.02** Standalone offline HTML documentation
- **17.03** Interactive links and navigation
- **17.04** Searchable tables and indexes
- **17.05** Embedded screen images and diagrams
- **17.06** Expandable technical sections
- **17.07** Consistent documentation templates
- **17.08** Atlas translation integration
- **17.09** Source-language preservation
- **17.10** Protected source-code and identifier text
- **17.11** Multiple target languages
- **17.12** Translation caching and revision invalidation
- **17.13** Translation quality review
- **17.14** Technical manual generation
- **17.15** End-user manual generation
- **17.16** Operations manual generation
- **17.17** PDF and printable output
- **17.18** Documentation package validation

## DPH-18 — AI Agent Handoff & Integration (P1)

- **18.01** Machine-readable project manifest
- **18.02** Detailed source and symbol indexes
- **18.03** Structured dependency and call graphs
- **18.04** Technical architecture exports
- **18.05** Business-rule and data-flow mappings
- **18.06** Exact build and test instructions
- **18.07** AI agent operating constraints
- **18.08** AGENTS.md generation
- **18.09** Structured JSON knowledge exports
- **18.10** Source-revision and evidence references
- **18.11** Selective context retrieval
- **18.12** Token-efficient technical summaries
- **18.13** AI question-answering against project knowledge
- **18.14** Coding-task-specific handoff packages
- **18.15** Prohibited operations and protected files
- **18.16** Agent-generated-change verification
- **18.17** Stale-context detection
- **18.18** Post-change documentation refresh
- **18.19** External agent protocol adapters
- **18.20** Human review and approval of AI-derived facts

## DPH-19 — Organizational Handoff & Readiness (P1)

- **19.01** New-maintainer onboarding
- **19.02** Structured knowledge-transfer interviews
- **19.03** Departing-developer questionnaires
- **19.04** Knowledge gaps and unanswered questions
- **19.05** Ownership and responsibility mapping
- **19.06** Critical-person dependency analysis
- **19.07** Maintenance readiness assessments
- **19.08** Build and deployment readiness verification
- **19.09** Recovery readiness verification
- **19.10** Documentation coverage measurement
- **19.11** Training plans and learning paths
- **19.12** Required approvals and sign-offs
- **19.13** Handoff package generation
- **19.14** Acceptance-test checklists
- **19.15** Handoff status dashboards
- **19.16** Continuing knowledge-maintenance schedules

## DPH-20 — DPH Administration & Extensibility (P0)

- **20.01** DPH project creation and import
- **20.02** Analysis profiles and scan configuration
- **20.03** Customizable Explorer categories
- **20.04** Customizable documentation templates
- **20.05** User preferences and layouts
- **20.06** Extension and parser architecture
- **20.07** Pluggable translation providers
- **20.08** External tool integration
- **20.09** Analysis diagnostics and logs
- **20.10** Application backup and restore
- **20.11** Import/export configuration
- **20.12** Performance and resource controls
- **20.13** Large-project scalability
- **20.14** Restricted knowledge-access controls
- **20.15** Schema and application upgrades
- **20.16** Automated DPH regression tests
- **20.17** Documentation generation validation
- **20.18** Recovery from interrupted project scans

## DPH-21 — Testing, Quality Assurance & Regression (P1)

- **21.01** Test project and test framework discovery
- **21.02** Unit, integration, and system test inventories
- **21.03** Test-to-source-code traceability
- **21.04** Test-to-business-rule traceability
- **21.05** Test cases, inputs, and expected results
- **21.06** Manual testing procedures
- **21.07** Automated test execution integration
- **21.08** Regression-test selection for proposed changes
- **21.09** Test results and evidence history
- **21.10** Test coverage and missing-test identification
- **21.11** Performance and load testing records
- **21.12** Release acceptance criteria

## DPH-22 — Change Management & Maintenance Workflows (P1)

- **22.01** Maintenance request records
- **22.02** Defect investigation history
- **22.03** Enhancement specifications
- **22.04** Change-impact assessments
- **22.05** Required source and documentation updates
- **22.06** Change approval procedures
- **22.07** Implementation checklists
- **22.08** Prechange and postchange comparisons
- **22.09** Regression verification
- **22.10** Release and deployment approvals
- **22.11** Rollback plans
- **22.12** Maintenance audit trails

## DPH-23 — Reports, Outputs & Information Products (P1)

- **23.01** Application report inventory
- **23.02** Report templates and definitions
- **23.03** Report fields and data sources
- **23.04** Calculations, grouping, and sorting
- **23.05** Report generation and scheduling logic
- **23.06** Report access permissions
- **23.07** Printed forms, labels, and documents
- **23.08** Email, spreadsheet, and file exports
- **23.09** Output destinations and recipients
- **23.10** Report-to-business-process links
- **23.11** Sample output and layout previews
- **23.12** Report verification procedures

**Enumerated original domain feature count:** 387 (23 domains). The conversation referred to 387; that headline count is not identical to the number of explicitly numbered records above and should not be used as a machine-validated total.

# B. Approved Phase 1 expansion requirements

These EX records were added after the original 387-feature inventory while stress-testing it against VCL2FMXConverter v6.0. They deliberately overlap some original features where a deeper and independently testable behavior was specified.

## EX-001–EX-010 — Deeper source understanding

- **EX-001** Document every procedure's inputs, outputs, and side effects
- **EX-002** Identify which global variables a procedure reads or modifies
- **EX-003** Trace property getters, setters, and their side effects
- **EX-004** Analyze class constructors and destructors
- **EX-005** Document object ownership and lifetime relationships
- **EX-006** Distinguish static calls from virtual and dynamic dispatch
- **EX-007** Identify conditional code compiled for particular platforms
- **EX-008** Record initialization and finalization sections of every unit
- **EX-009** Trace exception creation, propagation, and handling
- **EX-010** Record unresolved symbols, unknown call targets, and parser limitations

## EX-011–EX-020 — Form and screen intelligence

- **EX-011** Show the actual component hierarchy within each form
- **EX-012** Display design-time properties and significant default values
- **EX-013** Identify controls created dynamically
- **EX-014** Locate all procedures that change a particular control
- **EX-015** Trace events through subsequent procedure calls
- **EX-016** Identify which database fields appear on each screen
- **EX-017** Show how and when a form is created and destroyed
- **EX-018** Document runtime changes to visibility, position, and enabled state
- **EX-019** Identify inherited forms, frames, styles, and custom components
- **EX-020** Distinguish real screen captures from reconstructed layouts

## EX-021–EX-030 — Execution and data-flow analysis

- **EX-021** Trace from an application entry point to a selected procedure
- **EX-022** Trace a user action through all identifiable downstream calls
- **EX-023** Identify all locations where a variable receives a value
- **EX-024** Identify every known location where a database field is changed
- **EX-025** Trace important data transformations
- **EX-026** Identify shared state across threads and callbacks
- **EX-027** Document timer-initiated execution
- **EX-028** Identify reentrant or potentially recursive execution
- **EX-029** Visualize transaction start, commit, and rollback paths
- **EX-030** Display uncertain paths separately from verified paths

## EX-031–EX-040 — Environment and dependencies

- **EX-031** Identify required Delphi and compiler versions
- **EX-032** Record component packages needed to compile
- **EX-033** Identify required DLLs and runtime files
- **EX-034** Document application-specific environment settings
- **EX-035** Identify external files read or written by the application
- **EX-036** Explain external services used by this application
- **EX-037** Document expected file and folder permissions
- **EX-038** Identify hardcoded paths, endpoints, and environment assumptions
- **EX-039** Record exact build and deployment prerequisites
- **EX-040** Identify dependencies that are unavailable or unverified

## EX-041–EX-050 — Maintenance and documentation

- **EX-041** Explain why important procedures exist
- **EX-042** Document unusual algorithms and design choices
- **EX-043** Associate a business rule with the exact implementing code
- **EX-044** Identify source-code comments that conflict with implementation
- **EX-045** Store programmer annotations linked to specific symbols
- **EX-046** Track changes to important procedures across revisions
- **EX-047** Explain known defects and their technical workarounds
- **EX-048** Generate user instructions from documented screens and workflows
- **EX-049** Generate detailed maintenance instructions for the selected application
- **EX-050** Flag manual documentation requiring reapproval after code changes

## EX-051–EX-060 — AI agent handoff

- **EX-051** Create an exact project-specific technical manifest
- **EX-052** Export symbol and relationship indexes with stable identifiers
- **EX-053** Provide source paths, signatures, and revision references
- **EX-054** Identify protected functionality and high-risk code
- **EX-055** List known limitations and unresolved analysis questions
- **EX-056** Supply build, test, and regression procedures
- **EX-057** Generate task-specific technical context packages
- **EX-058** Mark confirmed information separately from AI inference
- **EX-059** Detect technical-context changes after source modifications
- **EX-060** Generate a fresh handoff for the selected revision of the project

## EX-061–EX-070 — VCL2FMX v6 execution case

- **EX-061** Background execution: identify anonymous threads, entry points, completion mechanisms, and synchronization
- **EX-062** UI/thread relationships: explain how worker-thread results reach FMX controls
- **EX-063** Object lifecycle: creation, ownership, destruction, references held across threads
- **EX-064** Mode-dependent execution: compare normal and dry-run and other option-dependent paths
- **EX-065** Failure-path analysis: effect of errors on processing, status, and reports
- **EX-066** Shared analysis context: accesses and mutations of TConversionContext
- **EX-067** Configuration propagation: UI checkbox settings into engine behavior
- **EX-068** Output artifact lineage: source files to generated files and reports
- **EX-069** Nested/local procedures: analyze routines defined inside other routines
- **EX-070** Generated knowledge verification: documentation accurate for analyzed source revision

## EX-071–EX-082 — FMX and reporting case

- **EX-071** Associate visual control with serialized FMX/DFM definition
- **EX-072** Trace controls through events, callbacks, and downstream logic
- **EX-073** Locate procedures reading or changing a particular control
- **EX-074** Document user-visible validation and error messages
- **EX-075** Trace UI control values into settings and processing logic
- **EX-076** Connect background processing results to UI updates
- **EX-077** Identify generated output artifacts and their producers
- **EX-078** Trace report fields back to original calculations or source
- **EX-079** Identify report-format selection and fallback behavior
- **EX-080** Generate user and engineering documentation from shared knowledge
- **EX-081** Validate agreement among HTML, JSON, and other documentation formats
- **EX-082** Distinguish discovered screen details from verified runtime appearance

## EX-083–EX-094 — Configuration and revision case

- **EX-083** Trace each significant configuration option to its consumers
- **EX-084** Identify and explain mode-dependent application behavior
- **EX-085** Identify external definition files influencing program operation
- **EX-086** Link definition-file records to Delphi code interpreting them
- **EX-087** Document default settings and configuration precedence
- **EX-088** Identify caches and when configuration changes invalidate them
- **EX-089** Record project and relevant dependency revision fingerprints
- **EX-090** Detect changed source symbols and event bindings
- **EX-091** Identify documentation affected by code/configuration changes
- **EX-092** Preserve historical explanations and their original evidence
- **EX-093** Require revalidation of potentially obsolete explanations
- **EX-094** Detect stale AI handoff information before export

# C. Mandatory project-scope rules

**DPH-SCOPE-001:** All automatic discovery, knowledge, diagrams, reports, and AI handoffs are restricted to the selected Delphi project and verified relevant dependencies.

- **SC-01** One explicitly selected active Delphi project or project group
- **SC-02** Every discovered record carries a project identity
- **SC-03** External entities require an explicit relationship to that project
- **SC-04** No automatic scanning of unrelated applications or repositories
- **SC-05** No unrestricted traversal outside configured source/dependency boundaries
- **SC-06** No company-wide discovery unless directly required by selected application's dependencies
- **SC-07** Every knowledge item explains its relevance to the selected project
- **SC-08** Reports filtered to active project and relevant dependencies
- **SC-09** AI context restricted to active project and authorized references
- **SC-10** Dependency exploration never silently expands project scope
- **SC-11** Unrelated records excluded from generated manuals
- **SC-12** Switching projects is an explicit user action

# D. Storage, modification and reassessment requirements

- **DB-001** Maintain a persistent SQLite knowledge database for each selected project
- **DB-002** Open previously analyzed projects without requiring full rescanning
- **DB-003** Detect source and dependency changes through verified fingerprints
- **DB-004** Incrementally update affected symbols and relationships
- **DB-005** Preserve manual knowledge and historical records across scans
- **DB-006** Track stale facts, explanations, translations, and AI context
- **DB-007** Support explicit full reanalysis without losing curated knowledge
- **DB-008** Protect last verified database state during failed/interrupted analysis
- **DB-009** Maintain persistent modification and reassessment status for selected project, files, and knowledge records; user can manually request reassessment
- **DB-010** Separate source modification tracking from knowledge edits
- **DB-011** Store last successfully analyzed source fingerprint
- **DB-012** Store latest observed fingerprint independently
- **DB-013** Never clear modification flag for obsolete analysis revision
- **DB-014** Preserve curated knowledge during automatic rescanning
- **DB-015** Store source-to-knowledge dependency relationships
- **DB-016** Reevaluate dependent records when underlying facts change
- **DB-017** Record renamed, moved, deleted, and restored source objects
- **DB-018** Support manual reassessment requests
- **DB-019** Maintain history of successful analysis revisions
- **DB-020** Recover safely from interrupted database updates
- **DB-021** Keep reports associated with exact analyzed revision
- **DB-022** Track analyzer version for each result
- **DB-023** Detect changes in relevant external definition files
- **DB-024** Maintain unresolved documentation reviews independently of scan status
- **DB-025** Automatic incremental reassessment is default; load cached project immediately, check in background, update safely and preserve manual knowledge
- **DB-026** Store structured project facts persistently in SQLite
- **DB-027** Preserve exact source revision and fingerprint references
- **DB-028** Support configurable full-source snapshots
- **DB-029** Associate snapshots with correct analysis generation
- **DB-030** Support connected and detached project viewing
- **DB-031** Detect source changes occurring during analysis
- **DB-032** Prevent mixed-revision results from being published as current
- **DB-033** Deduplicate identical archived source content
- **DB-034** Support source-directory relocation
- **DB-035** Apply exclusions to confidential and unnecessary files
- **DB-036** Validate stored source hashes and snapshot integrity
- **DB-037** Support portable validated project handoff packages
- **DB-038** Enforce configurable snapshot retention and storage limits
- **DB-039** Preserve knowledge when source files become unavailable
- **DB-040** Keep previous successful analysis accessible during reassessment

## Reassessment state model

Keep **modification detected**, **analysis stale/reassessment needed**, **knowledge review needed**, **analysis failure**, and **manual reassessment requested** as distinguishable persistent states. A single project-level visible status may be derived from lower-level statuses. The original conversational proposal also sketched numeric statuses 0 Current, 1 Modified, 2 Reassessment Required, 3 Review Required, 4 Analysis Failed, but the later approved architecture favors separate dimensions rather than one mutually exclusive enum.

A new scan must operate on a consistent captured file generation, check fingerprints before publication, and never clear a modification indicator for a newer unanalysed revision. An interrupted scan cannot destroy the last valid generation. Manual knowledge remains independent and preserved.

## Stored data and portability

- One SQLite `.dphdb` per selected project via Delphi FireDAC; small separate workspace catalog may remember database locations. Store DPH databases outside the scanned project by default.
- Persist normalized objects, relationships, source references, evidence, hashes, analysis and knowledge revisions, flags, documents, translations, diagrams and export metadata.
- Hybrid approach: current extracted data plus selective excerpts/caches, optional permission-controlled compressed source snapshots. The analyzed source itself remains authoritative and read-only.
- Support both connected viewing (source available for incremental checks) and detached viewing (cached/historical data visibly identified as such).
- Initial full scan; later cached opening with background change checks and automatic incremental reassessment. Explicit manual full analysis remains available.
- SQLite writes must be atomic and revision-consistent; never present superseded results as current.

# E. Presentation and explanation rules approved in Phase 1

- HTML technical/user/maintenance documentation and AI machine-readable exports are different views of **the same knowledge**; no duplicate divergent manuals. Atlas translation is via an adapter; do not translate code tokens, paths, symbols, SQL or hashes.
- Four depths: Overview, Functional, Detailed Engineering, Forensic/Source-Level.
- Screen gallery thumbnails, fit-to-workspace, actual-size/full-screen, component inspection, and clear design-time vs runtime labels.
- Explain complete event and output chains in both forward and reverse directions, with source evidence. Mark inferred or unresolved edges.
- Scope always stays with the selected Delphi program; outside systems appear only as directly relevant interfaces.
- A new developer (Mr. A) must be able to learn, operate, debug, change, build and maintain the selected program using verified references and known gaps.

# F. Provenance, known uncertainties and implementation authorization

- Phases 1–7 were subsequently approved by the owner; the original master design file predates that approval and has stale 'pending approval' labels. The separate Codex handoff clarifies authorization state.
- This Phase 1 document is **a requirements reference**, not authorization to create a project or begin coding. Codex follows the owner's existing `AGENTS.md`, which must not be replaced or modified.
- VCL2FMXConverter `v6.0.0` is a pinned complexity/reference corpus, not a DPH runtime/build dependency. Copy only independently reviewed units with license and provenance handling.
- No claims of compiler-grade whole-program inference; confidence must be tied to evidence and explicit limits.
- Initial numeric benchmarks, actual Delphi toolchain, specific Atlas implementation, snapshot retention limits and runtime instrumentation permissions remain controlled design/implementation decisions.

**Companion documents:** `DPH_Master_Development_Specification_v1.md` and `DPH_CODEX_HANDOFF.md` (or the corresponding downloaded filenames).
