-- Derived search projections; original evidence and knowledge remain authoritative.
CREATE TABLE search_documents (
 document_id INTEGER PRIMARY KEY,
 generation_id INTEGER NOT NULL REFERENCES analysis_generations(generation_id),
 kind TEXT NOT NULL, title TEXT NOT NULL, body TEXT NOT NULL,
 entity_key TEXT NOT NULL DEFAULT '', knowledge_id INTEGER,
 source_path TEXT NOT NULL DEFAULT '', verification_state TEXT NOT NULL,
 FOREIGN KEY(knowledge_id) REFERENCES knowledge_records(knowledge_id)
);
-- DPH STATEMENT
CREATE INDEX idx_search_generation ON search_documents(generation_id,kind,document_id);
-- DPH STATEMENT
CREATE TABLE search_terms (
 term TEXT COLLATE NOCASE NOT NULL,
 document_id INTEGER NOT NULL REFERENCES search_documents(document_id) ON DELETE CASCADE,
 PRIMARY KEY(term,document_id)
);
-- DPH STATEMENT
CREATE TABLE search_index_state (
 generation_id INTEGER PRIMARY KEY REFERENCES analysis_generations(generation_id),
 knowledge_revision INTEGER NOT NULL, search_version TEXT NOT NULL
);
