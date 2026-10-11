-- Exact localized derived views; revisions remain authoritative.
ALTER TABLE translations ADD COLUMN cache_key TEXT;
-- DPH STATEMENT
CREATE UNIQUE INDEX translations_cache_key ON translations(cache_key);
-- DPH STATEMENT
ALTER TABLE translations ADD COLUMN cache_json TEXT NOT NULL DEFAULT '{}' CHECK(json_valid(cache_json));
