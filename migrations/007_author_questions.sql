-- A response remains linked to the exact generated question and its evidence.
CREATE TABLE knowledge_questions (
 knowledge_id INTEGER PRIMARY KEY REFERENCES knowledge_records(knowledge_id),
 question_key TEXT NOT NULL CHECK(length(question_key)=64),
 question_json TEXT NOT NULL CHECK(json_valid(question_json)),
 opened_generation INTEGER NOT NULL REFERENCES analysis_generations(generation_id)
);
-- DPH STATEMENT
CREATE INDEX knowledge_questions_key ON knowledge_questions(question_key);
