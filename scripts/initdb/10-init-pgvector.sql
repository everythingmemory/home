-- Enable pgvector extension at database creation time.
-- Percona Distribution PostgreSQL 17 ships pgvector; this just activates it.
CREATE EXTENSION IF NOT EXISTS vector;
