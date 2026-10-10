-- DPH migration 2: generation and manual history protection.
CREATE TABLE component_properties (
 component_entity_id INTEGER NOT NULL, generation_id INTEGER NOT NULL,
 property_name TEXT NOT NULL, serialized_value TEXT NOT NULL, value_kind TEXT NOT NULL, evidence_id INTEGER NOT NULL,
 PRIMARY KEY(component_entity_id,generation_id,property_name),
 FOREIGN KEY(component_entity_id,generation_id) REFERENCES entity_versions(entity_id,generation_id),
 FOREIGN KEY(evidence_id,generation_id) REFERENCES evidence(evidence_id,generation_id)
);
-- DPH STATEMENT
CREATE TABLE control_flow_nodes (
 cfg_node_id INTEGER PRIMARY KEY, routine_version_id INTEGER NOT NULL, generation_id INTEGER NOT NULL,
 node_kind TEXT NOT NULL, source_range_json TEXT NOT NULL CHECK(json_valid(source_range_json)), expression_ref TEXT,
 UNIQUE(cfg_node_id,generation_id),
 FOREIGN KEY(routine_version_id,generation_id) REFERENCES entity_versions(entity_version_id,generation_id)
);
-- DPH STATEMENT
CREATE TABLE control_flow_edges (
 cfg_edge_id INTEGER PRIMARY KEY, generation_id INTEGER NOT NULL,
 from_cfg_node_id INTEGER NOT NULL, to_cfg_node_id INTEGER NOT NULL, edge_kind TEXT NOT NULL, condition_ref TEXT,
 FOREIGN KEY(from_cfg_node_id,generation_id) REFERENCES control_flow_nodes(cfg_node_id,generation_id),
 FOREIGN KEY(to_cfg_node_id,generation_id) REFERENCES control_flow_nodes(cfg_node_id,generation_id)
);
-- DPH STATEMENT
CREATE TABLE translations (
 translation_id INTEGER PRIMARY KEY, knowledge_revision_id INTEGER NOT NULL REFERENCES knowledge_revisions(knowledge_revision_id),
 target_locale TEXT NOT NULL, provider_id TEXT NOT NULL, provider_version TEXT NOT NULL, translated_body TEXT NOT NULL,
 source_hash TEXT NOT NULL CHECK(length(source_hash)=64), translation_state TEXT NOT NULL, reviewer TEXT,
 UNIQUE(knowledge_revision_id,target_locale,provider_id,provider_version)
);
-- DPH STATEMENT
CREATE TABLE artifacts (
 artifact_id INTEGER PRIMARY KEY, project_id INTEGER NOT NULL, generation_id INTEGER NOT NULL,
 kind TEXT NOT NULL, artifact_path TEXT, blob_id TEXT REFERENCES artifact_blobs(blob_id),
 content_hash TEXT NOT NULL CHECK(length(content_hash)=64), locale TEXT NOT NULL, template_version TEXT NOT NULL, build_state TEXT NOT NULL,
 FOREIGN KEY(generation_id,project_id) REFERENCES analysis_generations(generation_id,project_id),
 CHECK((artifact_path IS NOT NULL AND blob_id IS NULL) OR (artifact_path IS NULL AND blob_id IS NOT NULL))
);
-- DPH STATEMENT
CREATE TABLE export_jobs (
 export_id INTEGER PRIMARY KEY, project_id INTEGER NOT NULL, generation_id INTEGER NOT NULL,
 format TEXT NOT NULL, scope_json TEXT NOT NULL CHECK(json_valid(scope_json)), started_at TEXT NOT NULL,
 finished_at TEXT, manifest_hash TEXT, status TEXT NOT NULL,
 FOREIGN KEY(generation_id,project_id) REFERENCES analysis_generations(generation_id,project_id)
);
-- DPH STATEMENT
CREATE INDEX idx_entity_display ON entities(project_id,display_name);
-- DPH STATEMENT
CREATE INDEX idx_artifacts_generation ON artifacts(generation_id,locale);
-- DPH STATEMENT
CREATE TRIGGER immutable_file_identity BEFORE UPDATE OF file_id,project_id,canonical_relpath ON source_files
BEGIN SELECT RAISE(ABORT,'Historical file identity requires a reviewed continuity operation'); END;
-- DPH STATEMENT
CREATE TRIGGER immutable_entity_identity BEFORE UPDATE OF entity_id,project_id,canonical_key,entity_kind,owner_file_id ON entities
BEGIN SELECT RAISE(ABORT,'Historical entity identity requires a reviewed continuity operation'); END;
-- DPH STATEMENT
CREATE TRIGGER revision_requires_capture BEFORE INSERT ON file_revisions
WHEN COALESCE((SELECT status FROM analysis_generations WHERE generation_id=NEW.source_generation_id),'') <> 'running'
BEGIN SELECT RAISE(ABORT,'Source revisions must originate in a running capture'); END;
-- DPH STATEMENT
CREATE TRIGGER immutable_generation_update BEFORE UPDATE ON analysis_generations
WHEN OLD.status <> 'running'
BEGIN SELECT RAISE(ABORT,'Terminal generation is immutable'); END;
-- DPH STATEMENT
CREATE TRIGGER immutable_generation_delete BEFORE DELETE ON analysis_generations
BEGIN SELECT RAISE(ABORT,'Generation history cannot be deleted'); END;
-- DPH STATEMENT
CREATE TRIGGER valid_published_head BEFORE UPDATE OF published_generation_id ON project_state
WHEN NEW.published_generation_id IS NOT NULL AND NOT EXISTS
 (SELECT 1 FROM analysis_generations WHERE generation_id=NEW.published_generation_id
 AND project_id=NEW.project_id AND status='current')
BEGIN SELECT RAISE(ABORT,'Published head must refer to a completed generation'); END;
-- DPH STATEMENT
CREATE TRIGGER immutable_knowledge_update BEFORE UPDATE ON knowledge_revisions
BEGIN SELECT RAISE(ABORT,'Knowledge revisions are append-only'); END;
-- DPH STATEMENT
CREATE TRIGGER immutable_knowledge_delete BEFORE DELETE ON knowledge_revisions
BEGIN SELECT RAISE(ABORT,'Knowledge revisions are append-only'); END;
-- DPH STATEMENT
CREATE TRIGGER immutable_revision_update BEFORE UPDATE ON file_revisions
BEGIN SELECT RAISE(ABORT,'Source revisions are immutable'); END;
-- DPH STATEMENT
CREATE TRIGGER immutable_revision_delete BEFORE DELETE ON file_revisions
BEGIN SELECT RAISE(ABORT,'Source revisions are immutable'); END;
-- DPH STATEMENT
CREATE TRIGGER immutable_configuration_update BEFORE UPDATE ON configurations
BEGIN SELECT RAISE(ABORT,'Configurations are immutable'); END;
-- DPH STATEMENT
CREATE TRIGGER immutable_configuration_delete BEFORE DELETE ON configurations
BEGIN SELECT RAISE(ABORT,'Configurations are immutable'); END;
-- DPH STATEMENT
CREATE TRIGGER captured_revision_matches BEFORE INSERT ON generation_files
WHEN NEW.file_revision_id IS NOT NULL AND NOT EXISTS
 (SELECT 1 FROM file_revisions WHERE file_revision_id=NEW.file_revision_id
 AND file_id=NEW.file_id AND sha256=NEW.captured_hash AND size_bytes=NEW.captured_size)
BEGIN SELECT RAISE(ABORT,'Captured revision fingerprint mismatch'); END;
-- DPH STATEMENT
CREATE TRIGGER evidence_analyzer_matches BEFORE INSERT ON evidence
WHEN NEW.analyzer_version <> (SELECT analyzer_version FROM analysis_generations WHERE generation_id=NEW.generation_id)
BEGIN SELECT RAISE(ABORT,'Evidence analyzer version mismatch'); END;
-- DPH STATEMENT
CREATE TRIGGER evidence_range_valid BEFORE INSERT ON evidence
WHEN json_type(NEW.source_range_json,'$.start') IS NOT 'integer'
 OR json_type(NEW.source_range_json,'$.end') IS NOT 'integer'
 OR json_extract(NEW.source_range_json,'$.start') < 0
 OR json_extract(NEW.source_range_json,'$.end') < json_extract(NEW.source_range_json,'$.start')
 OR json_extract(NEW.source_range_json,'$.end') > (SELECT size_bytes FROM file_revisions WHERE file_revision_id=NEW.file_revision_id)
BEGIN SELECT RAISE(ABORT,'Evidence range outside captured source bytes'); END;
-- DPH STATEMENT
CREATE INDEX idx_evidence_source_range ON evidence(file_revision_id,json_extract(source_range_json,'$.start'),json_extract(source_range_json,'$.end'));
-- DPH STATEMENT
CREATE TRIGGER generation_files_staging_insert BEFORE INSERT ON generation_files WHEN COALESCE((SELECT status FROM analysis_generations WHERE generation_id=NEW.generation_id),'') <> 'running' BEGIN SELECT RAISE(ABORT,'Generation is not writable'); END;
-- DPH STATEMENT
CREATE TRIGGER generation_files_immutable_update BEFORE UPDATE ON generation_files BEGIN SELECT RAISE(ABORT,'Generation rows are append-only'); END;
-- DPH STATEMENT
CREATE TRIGGER generation_files_immutable_delete BEFORE DELETE ON generation_files BEGIN SELECT RAISE(ABORT,'Generation rows are append-only'); END;
-- DPH STATEMENT
CREATE TRIGGER entity_versions_staging_insert BEFORE INSERT ON entity_versions WHEN COALESCE((SELECT status FROM analysis_generations WHERE generation_id=NEW.generation_id),'') <> 'running' BEGIN SELECT RAISE(ABORT,'Generation is not writable'); END;
-- DPH STATEMENT
CREATE TRIGGER entity_versions_immutable_update BEFORE UPDATE ON entity_versions BEGIN SELECT RAISE(ABORT,'Generation rows are append-only'); END;
-- DPH STATEMENT
CREATE TRIGGER entity_versions_immutable_delete BEFORE DELETE ON entity_versions BEGIN SELECT RAISE(ABORT,'Generation rows are append-only'); END;
-- DPH STATEMENT
CREATE TRIGGER evidence_staging_insert BEFORE INSERT ON evidence WHEN COALESCE((SELECT status FROM analysis_generations WHERE generation_id=NEW.generation_id),'') <> 'running' BEGIN SELECT RAISE(ABORT,'Generation is not writable'); END;
-- DPH STATEMENT
CREATE TRIGGER evidence_immutable_update BEFORE UPDATE ON evidence BEGIN SELECT RAISE(ABORT,'Generation rows are append-only'); END;
-- DPH STATEMENT
CREATE TRIGGER evidence_immutable_delete BEFORE DELETE ON evidence BEGIN SELECT RAISE(ABORT,'Generation rows are append-only'); END;
-- DPH STATEMENT
CREATE TRIGGER relationships_staging_insert BEFORE INSERT ON relationships WHEN COALESCE((SELECT status FROM analysis_generations WHERE generation_id=NEW.generation_id),'') <> 'running' BEGIN SELECT RAISE(ABORT,'Generation is not writable'); END;
-- DPH STATEMENT
CREATE TRIGGER relationships_immutable_update BEFORE UPDATE ON relationships BEGIN SELECT RAISE(ABORT,'Generation rows are append-only'); END;
-- DPH STATEMENT
CREATE TRIGGER relationships_immutable_delete BEFORE DELETE ON relationships BEGIN SELECT RAISE(ABORT,'Generation rows are append-only'); END;
-- DPH STATEMENT
CREATE TRIGGER diagnostics_staging_insert BEFORE INSERT ON diagnostics WHEN COALESCE((SELECT status FROM analysis_generations WHERE generation_id=NEW.generation_id),'') <> 'running' BEGIN SELECT RAISE(ABORT,'Generation is not writable'); END;
-- DPH STATEMENT
CREATE TRIGGER diagnostics_immutable_update BEFORE UPDATE ON diagnostics BEGIN SELECT RAISE(ABORT,'Generation rows are append-only'); END;
-- DPH STATEMENT
CREATE TRIGGER diagnostics_immutable_delete BEFORE DELETE ON diagnostics BEGIN SELECT RAISE(ABORT,'Generation rows are append-only'); END;

-- DPH STATEMENT
CREATE TRIGGER component_properties_staging_insert BEFORE INSERT ON component_properties WHEN COALESCE((SELECT status FROM analysis_generations WHERE generation_id=NEW.generation_id),'') <> 'running' BEGIN SELECT RAISE(ABORT,'Generation is not writable'); END;
-- DPH STATEMENT
CREATE TRIGGER component_properties_immutable_update BEFORE UPDATE ON component_properties BEGIN SELECT RAISE(ABORT,'Generation rows are append-only'); END;
-- DPH STATEMENT
CREATE TRIGGER component_properties_immutable_delete BEFORE DELETE ON component_properties BEGIN SELECT RAISE(ABORT,'Generation rows are append-only'); END;
-- DPH STATEMENT
CREATE TRIGGER control_flow_nodes_staging_insert BEFORE INSERT ON control_flow_nodes WHEN COALESCE((SELECT status FROM analysis_generations WHERE generation_id=NEW.generation_id),'') <> 'running' BEGIN SELECT RAISE(ABORT,'Generation is not writable'); END;
-- DPH STATEMENT
CREATE TRIGGER control_flow_nodes_immutable_update BEFORE UPDATE ON control_flow_nodes BEGIN SELECT RAISE(ABORT,'Generation rows are append-only'); END;
-- DPH STATEMENT
CREATE TRIGGER control_flow_nodes_immutable_delete BEFORE DELETE ON control_flow_nodes BEGIN SELECT RAISE(ABORT,'Generation rows are append-only'); END;
-- DPH STATEMENT
CREATE TRIGGER control_flow_edges_staging_insert BEFORE INSERT ON control_flow_edges WHEN COALESCE((SELECT status FROM analysis_generations WHERE generation_id=NEW.generation_id),'') <> 'running' BEGIN SELECT RAISE(ABORT,'Generation is not writable'); END;
-- DPH STATEMENT
CREATE TRIGGER control_flow_edges_immutable_update BEFORE UPDATE ON control_flow_edges BEGIN SELECT RAISE(ABORT,'Generation rows are append-only'); END;
-- DPH STATEMENT
CREATE TRIGGER control_flow_edges_immutable_delete BEFORE DELETE ON control_flow_edges BEGIN SELECT RAISE(ABORT,'Generation rows are append-only'); END;
