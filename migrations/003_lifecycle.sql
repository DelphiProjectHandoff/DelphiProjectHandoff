-- User-managed retention keeps immutable facts and manual history intact.
CREATE TABLE retention_policy (
 project_id INTEGER PRIMARY KEY REFERENCES projects(project_id),
 recent_generations INTEGER NOT NULL DEFAULT 10 CHECK(recent_generations BETWEEN 1 AND 10000)
);
-- DPH STATEMENT
CREATE TABLE retained_generations (
 project_id INTEGER NOT NULL REFERENCES projects(project_id),
 generation_id INTEGER NOT NULL,
 label TEXT NOT NULL, reviewer TEXT NOT NULL, recorded_at TEXT NOT NULL,
 PRIMARY KEY(project_id,generation_id),
 FOREIGN KEY(generation_id,project_id) REFERENCES analysis_generations(generation_id,project_id)
);
