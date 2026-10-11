-- Rich links are immutable and belong to the exact authored revision.
CREATE TABLE knowledge_revision_links (
 revision_id INTEGER NOT NULL REFERENCES knowledge_revisions(knowledge_revision_id),
 ordinal INTEGER NOT NULL,
 target_kind TEXT NOT NULL CHECK(target_kind IN ('entity','relationship','evidence','screenshot','section')),
 target_id INTEGER NOT NULL, source_generation INTEGER REFERENCES analysis_generations(generation_id),
 link_role TEXT NOT NULL CHECK(link_role IN ('explains','cites','depends_on','illustrates')),
 label TEXT NOT NULL,
 PRIMARY KEY(revision_id,ordinal), UNIQUE(revision_id,target_kind,target_id,link_role)
);
-- DPH STATEMENT
CREATE INDEX knowledge_revision_links_target ON knowledge_revision_links(target_kind,target_id);
