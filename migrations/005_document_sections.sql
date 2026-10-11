-- Immutable documentation metadata follows each authored knowledge revision.
CREATE TABLE document_section_versions (
 revision_id INTEGER PRIMARY KEY REFERENCES knowledge_revisions(knowledge_revision_id),
 knowledge_id INTEGER NOT NULL REFERENCES knowledge_records(knowledge_id),
 section_id TEXT NOT NULL, document_kind TEXT NOT NULL, audience TEXT NOT NULL,
 source_generation INTEGER REFERENCES analysis_generations(generation_id),
 FOREIGN KEY(revision_id,knowledge_id) REFERENCES knowledge_revisions(knowledge_revision_id,knowledge_id)
);
-- DPH STATEMENT
INSERT INTO document_section_versions(revision_id,knowledge_id,section_id,document_kind,audience)
SELECT r.knowledge_revision_id,k.knowledge_id,'knowledge-'||k.knowledge_id,
 CASE WHEN k.kind='user_help' THEN 'user' WHEN k.kind IN ('maintenance','build_deploy','troubleshooting','orientation') THEN k.kind ELSE 'engineering' END,
 CASE WHEN k.kind='user_help' THEN 'user' WHEN k.kind='maintenance' THEN 'maintainer' WHEN k.kind='build_deploy' THEN 'builder' ELSE 'engineer' END
FROM knowledge_revisions r JOIN knowledge_records k ON k.knowledge_id=r.knowledge_id;
