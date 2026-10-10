-- DPH migration 1. Statements are separated by the explicit marker below.
CREATE TABLE projects (
 project_id INTEGER PRIMARY KEY CHECK(project_id=1), name TEXT NOT NULL,
 root_uri TEXT NOT NULL, project_kind TEXT NOT NULL, active_config INTEGER,
 created_at TEXT NOT NULL, last_opened_at TEXT NOT NULL,
 FOREIGN KEY(active_config,project_id) REFERENCES configurations(config_id,project_id)
);
-- DPH STATEMENT
CREATE TABLE configurations (
 config_id INTEGER PRIMARY KEY, project_id INTEGER NOT NULL REFERENCES projects(project_id),
 platform TEXT NOT NULL, compiler TEXT NOT NULL, defines_json TEXT NOT NULL,
 search_paths_json TEXT NOT NULL, environment_label TEXT NOT NULL,
 fingerprint TEXT NOT NULL CHECK(length(fingerprint)=64),
 UNIQUE(config_id,project_id), UNIQUE(project_id,fingerprint),
 CHECK(json_valid(defines_json) AND json_valid(search_paths_json))
);
-- DPH STATEMENT
CREATE TABLE analysis_generations (
 generation_id INTEGER PRIMARY KEY, project_id INTEGER NOT NULL REFERENCES projects(project_id),
 config_id INTEGER NOT NULL, started_at TEXT NOT NULL, completed_at TEXT,
 analyzer_version TEXT NOT NULL, config_fingerprint TEXT NOT NULL,
 manifest_hash TEXT NOT NULL CHECK(length(manifest_hash)=64),
 status TEXT NOT NULL CHECK(status IN ('running','current','partial','failed','superseded')),
 previous_generation_id INTEGER, completeness_summary_json TEXT NOT NULL DEFAULT '{}' CHECK(json_valid(completeness_summary_json)),
 UNIQUE(generation_id,project_id),
 FOREIGN KEY(config_id,project_id) REFERENCES configurations(config_id,project_id),
 FOREIGN KEY(previous_generation_id,project_id) REFERENCES analysis_generations(generation_id,project_id)
);
-- DPH STATEMENT
CREATE TABLE project_state (
 project_id INTEGER PRIMARY KEY REFERENCES projects(project_id), published_generation_id INTEGER,
 modification_detected INTEGER NOT NULL DEFAULT 0 CHECK(modification_detected IN (0,1)),
 analysis_stale INTEGER NOT NULL DEFAULT 1 CHECK(analysis_stale IN (0,1)),
 knowledge_review_needed INTEGER NOT NULL DEFAULT 0 CHECK(knowledge_review_needed IN (0,1)),
 analysis_failed INTEGER NOT NULL DEFAULT 0 CHECK(analysis_failed IN (0,1)),
 reassessment_requested INTEGER NOT NULL DEFAULT 0 CHECK(reassessment_requested IN (0,1)),
 FOREIGN KEY(published_generation_id,project_id) REFERENCES analysis_generations(generation_id,project_id)
);
-- DPH STATEMENT
CREATE TABLE source_files (
 file_id INTEGER PRIMARY KEY, project_id INTEGER NOT NULL REFERENCES projects(project_id),
 canonical_relpath TEXT NOT NULL, kind TEXT NOT NULL, current_observed_hash TEXT,
 last_analyzed_hash TEXT, availability_status TEXT NOT NULL
 CHECK(availability_status IN ('available','missing','excluded','unreadable')),
 reassessment_flag INTEGER NOT NULL CHECK(reassessment_flag IN (0,1)), encoding TEXT NOT NULL,
 observed_size INTEGER NOT NULL CHECK(observed_size>=0),
 in_manifest INTEGER NOT NULL DEFAULT 1 CHECK(in_manifest IN (0,1)),
 UNIQUE(file_id,project_id), UNIQUE(project_id,canonical_relpath)
);
-- DPH STATEMENT
CREATE TABLE artifact_blobs (
 blob_id TEXT PRIMARY KEY CHECK(length(blob_id)=64), storage_ref TEXT NOT NULL,
 size_bytes INTEGER NOT NULL CHECK(size_bytes>=0)
);
-- DPH STATEMENT
CREATE TABLE file_revisions (
 file_revision_id INTEGER PRIMARY KEY, project_id INTEGER NOT NULL, file_id INTEGER NOT NULL,
 sha256 TEXT NOT NULL CHECK(length(sha256)=64), size_bytes INTEGER NOT NULL CHECK(size_bytes>=0),
 revision_time TEXT NOT NULL, source_generation_id INTEGER NOT NULL,
 snapshot_blob_id TEXT REFERENCES artifact_blobs(blob_id),
 UNIQUE(file_id,sha256), UNIQUE(file_revision_id,file_id,project_id),
 FOREIGN KEY(file_id,project_id) REFERENCES source_files(file_id,project_id),
 FOREIGN KEY(source_generation_id,project_id) REFERENCES analysis_generations(generation_id,project_id)
);
-- DPH STATEMENT
CREATE TABLE generation_files (
 generation_id INTEGER NOT NULL, project_id INTEGER NOT NULL, file_id INTEGER NOT NULL,
 file_revision_id INTEGER, captured_hash TEXT NOT NULL,
 captured_size INTEGER NOT NULL CHECK(captured_size>=0), availability TEXT NOT NULL,
 kind TEXT NOT NULL, encoding TEXT NOT NULL,
 PRIMARY KEY(generation_id,file_id), UNIQUE(generation_id,file_revision_id),
 FOREIGN KEY(generation_id,project_id) REFERENCES analysis_generations(generation_id,project_id),
 FOREIGN KEY(file_id,project_id) REFERENCES source_files(file_id,project_id),
 FOREIGN KEY(file_revision_id,file_id,project_id) REFERENCES file_revisions(file_revision_id,file_id,project_id),
 CHECK((availability='available' AND file_revision_id IS NOT NULL AND length(captured_hash)=64)
 OR (availability IN ('missing','excluded','unreadable') AND file_revision_id IS NULL AND captured_hash=''))
);
-- DPH STATEMENT
CREATE TABLE entities (
 entity_id INTEGER PRIMARY KEY, project_id INTEGER NOT NULL REFERENCES projects(project_id),
 entity_kind TEXT NOT NULL, canonical_key TEXT NOT NULL, display_name TEXT NOT NULL,
 owner_file_id INTEGER, lifecycle_state TEXT NOT NULL DEFAULT 'active',
 UNIQUE(entity_id,project_id), UNIQUE(project_id,canonical_key,entity_kind),
 FOREIGN KEY(owner_file_id,project_id) REFERENCES source_files(file_id,project_id)
);
-- DPH STATEMENT
CREATE TABLE entity_versions (
 entity_version_id INTEGER PRIMARY KEY, entity_id INTEGER NOT NULL, project_id INTEGER NOT NULL,
 generation_id INTEGER NOT NULL, signature TEXT NOT NULL, structural_json TEXT NOT NULL,
 source_revision_id INTEGER, start_line INTEGER, end_line INTEGER, start_offset INTEGER, end_offset INTEGER,
 analysis_status TEXT NOT NULL, UNIQUE(entity_id,generation_id), UNIQUE(entity_version_id,generation_id),
 FOREIGN KEY(entity_id,project_id) REFERENCES entities(entity_id,project_id),
 FOREIGN KEY(generation_id,project_id) REFERENCES analysis_generations(generation_id,project_id),
 FOREIGN KEY(generation_id,source_revision_id) REFERENCES generation_files(generation_id,file_revision_id),
 CHECK(start_offset IS NULL OR (start_offset>=0 AND end_offset>=start_offset)),
 CHECK(start_line IS NULL OR (start_line>=1 AND end_line>=start_line)), CHECK(json_valid(structural_json))
);
-- DPH STATEMENT
CREATE TABLE evidence (
 evidence_id INTEGER PRIMARY KEY, project_id INTEGER NOT NULL, generation_id INTEGER NOT NULL,
 file_revision_id INTEGER NOT NULL, source_range_json TEXT NOT NULL CHECK(json_valid(source_range_json)),
 evidence_kind TEXT NOT NULL, payload_ref TEXT NOT NULL, analyzer_version TEXT NOT NULL,
 capture_time TEXT NOT NULL, verification_state TEXT NOT NULL
 CHECK(verification_state IN ('verified','inferred','needs_review','rejected')),
 UNIQUE(evidence_id,generation_id), UNIQUE(evidence_id,project_id),
 FOREIGN KEY(generation_id,project_id) REFERENCES analysis_generations(generation_id,project_id),
 FOREIGN KEY(generation_id,file_revision_id) REFERENCES generation_files(generation_id,file_revision_id)
);
-- DPH STATEMENT
CREATE TABLE relationships (
 relationship_id INTEGER PRIMARY KEY, project_id INTEGER NOT NULL, generation_id INTEGER NOT NULL,
 from_entity_id INTEGER NOT NULL, to_entity_id INTEGER, relation_kind TEXT NOT NULL,
 resolution_status TEXT NOT NULL CHECK(resolution_status IN
 ('confirmed_static','possible_dynamic','inferred','runtime_observed','unresolved')),
 evidence_id INTEGER NOT NULL, condition_variant TEXT,
 UNIQUE(relationship_id,project_id),
 FOREIGN KEY(generation_id,project_id) REFERENCES analysis_generations(generation_id,project_id),
 FOREIGN KEY(from_entity_id,generation_id) REFERENCES entity_versions(entity_id,generation_id),
 FOREIGN KEY(to_entity_id,generation_id) REFERENCES entity_versions(entity_id,generation_id),
 FOREIGN KEY(evidence_id,generation_id) REFERENCES evidence(evidence_id,generation_id)
);
-- DPH STATEMENT
CREATE TABLE diagnostics (
 diagnostic_id INTEGER PRIMARY KEY, project_id INTEGER NOT NULL, generation_id INTEGER NOT NULL,
 severity TEXT NOT NULL, code TEXT NOT NULL, message TEXT NOT NULL, source_range_json TEXT,
 affected_entity_id INTEGER, resolved_at TEXT,
 FOREIGN KEY(generation_id,project_id) REFERENCES analysis_generations(generation_id,project_id),
 FOREIGN KEY(affected_entity_id,project_id) REFERENCES entities(entity_id,project_id)
);
-- DPH STATEMENT
CREATE TABLE knowledge_records (
 knowledge_id INTEGER PRIMARY KEY, project_id INTEGER NOT NULL REFERENCES projects(project_id),
 kind TEXT NOT NULL, title TEXT NOT NULL, source_language TEXT NOT NULL, current_revision_id INTEGER,
 state TEXT NOT NULL CHECK(state IN ('verified','needs_review','inferred','rejected','retired')), owner TEXT NOT NULL,
 UNIQUE(knowledge_id,project_id),
 FOREIGN KEY(current_revision_id,knowledge_id) REFERENCES knowledge_revisions(knowledge_revision_id,knowledge_id)
);
-- DPH STATEMENT
CREATE TABLE knowledge_revisions (
 knowledge_revision_id INTEGER PRIMARY KEY, knowledge_id INTEGER NOT NULL REFERENCES knowledge_records(knowledge_id),
 body_md TEXT NOT NULL, editor TEXT NOT NULL, created_at TEXT NOT NULL,
 verification_state TEXT NOT NULL CHECK(verification_state IN ('verified','needs_review','inferred','rejected','retired')),
 verified_by TEXT, verified_at TEXT, UNIQUE(knowledge_revision_id,knowledge_id)
);
-- DPH STATEMENT
CREATE TABLE knowledge_links (
 link_id INTEGER PRIMARY KEY, project_id INTEGER NOT NULL, knowledge_id INTEGER NOT NULL,
 entity_id INTEGER, relationship_id INTEGER, evidence_id INTEGER, link_role TEXT NOT NULL,
 last_verified_generation_id INTEGER,
 FOREIGN KEY(knowledge_id,project_id) REFERENCES knowledge_records(knowledge_id,project_id),
 FOREIGN KEY(entity_id,project_id) REFERENCES entities(entity_id,project_id),
 FOREIGN KEY(relationship_id,project_id) REFERENCES relationships(relationship_id,project_id),
 FOREIGN KEY(evidence_id,project_id) REFERENCES evidence(evidence_id,project_id),
 FOREIGN KEY(last_verified_generation_id,project_id) REFERENCES analysis_generations(generation_id,project_id),
 CHECK(entity_id IS NOT NULL OR relationship_id IS NOT NULL OR evidence_id IS NOT NULL)
);
-- DPH STATEMENT
CREATE TABLE review_tasks (
 task_id INTEGER PRIMARY KEY, project_id INTEGER NOT NULL, knowledge_id INTEGER, entity_id INTEGER,
 reason TEXT NOT NULL, state TEXT NOT NULL CHECK(state IN ('pending','resolved')),
 opened_generation_id INTEGER, resolved_generation_id INTEGER, reviewer TEXT,
 FOREIGN KEY(project_id) REFERENCES projects(project_id),
 FOREIGN KEY(knowledge_id,project_id) REFERENCES knowledge_records(knowledge_id,project_id),
 FOREIGN KEY(entity_id,project_id) REFERENCES entities(entity_id,project_id),
 FOREIGN KEY(opened_generation_id,project_id) REFERENCES analysis_generations(generation_id,project_id),
 FOREIGN KEY(resolved_generation_id,project_id) REFERENCES analysis_generations(generation_id,project_id)
);
-- DPH STATEMENT
CREATE TABLE audit_events (
 event_id INTEGER PRIMARY KEY, project_id INTEGER NOT NULL REFERENCES projects(project_id),
 entity_type TEXT NOT NULL, entity_id INTEGER NOT NULL, action TEXT NOT NULL,
 actor TEXT NOT NULL, recorded_at TEXT NOT NULL, before_hash TEXT, after_hash TEXT
);
-- DPH STATEMENT
CREATE INDEX idx_relationship_from ON relationships(from_entity_id,relation_kind,generation_id);
-- DPH STATEMENT
CREATE INDEX idx_relationship_to ON relationships(to_entity_id,relation_kind,generation_id);
-- DPH STATEMENT
CREATE INDEX idx_evidence_revision ON evidence(file_revision_id,generation_id);
-- DPH STATEMENT
CREATE INDEX idx_entity_file ON entities(owner_file_id);
-- DPH STATEMENT
CREATE INDEX idx_review_state ON review_tasks(project_id,state);
-- DPH STATEMENT
CREATE INDEX idx_knowledge_entity ON knowledge_links(entity_id,knowledge_id);
-- DPH STATEMENT
CREATE INDEX idx_knowledge_record ON knowledge_links(knowledge_id);
