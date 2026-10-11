-- Preserve typed authored fields with their exact immutable knowledge revision.
ALTER TABLE knowledge_revisions ADD COLUMN structured_json TEXT NOT NULL DEFAULT '{}' CHECK(json_valid(structured_json) AND json_type(structured_json)='object');
