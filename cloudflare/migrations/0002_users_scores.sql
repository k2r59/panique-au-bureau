DROP INDEX players_ranking;
ALTER TABLE players RENAME TO users;
CREATE TABLE scores (
  user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  best_score INTEGER NOT NULL DEFAULT 0 CHECK(best_score BETWEEN 0 AND 100000),
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO scores (user_id, best_score, updated_at) SELECT id, best_score, updated_at FROM users WHERE best_score > 0;
ALTER TABLE users DROP COLUMN best_score;
CREATE INDEX scores_ranking ON scores(best_score DESC, updated_at ASC, user_id);
