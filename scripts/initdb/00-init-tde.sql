-- Transparent data encryption, switched on at database creation.
--
-- Runs ONCE, on an empty data directory, before 10-init-pgvector.sql. It needs
-- `shared_preload_libraries=pg_tde`, which docker-compose.yml passes on the
-- postgres command line, and a writable /tde_keys (the key volume).
--
-- What it leaves behind:
--   * a FILE KEYRING at /tde_keys/keyring.per — the principal keys, generated
--     here. It protects a stolen disk or backup, not a stolen host. Back the
--     key volume up APART from the data: a backup holding both defeats it, and
--     a lost key volume loses the database (rebuilt from the archive). The step
--     up is Percona's Vault or KMIP provider in place of the file;
--   * a default principal key every database uses, and a server key for WAL;
--   * `tde_heap` as the default table access method, so every table the
--     migrations create is encrypted, with its indexes;
--   * WAL encryption on (takes effect when the init server restarts, which
--     the entrypoint does next).
--
-- The access method lives in the pg_tde extension, so it is created in every
-- database a table can be made in: template1 (every later CREATE DATABASE),
-- `postgres`, and the stack's own database, already made from template1 by the
-- time this runs. Prove it on a running stack with
--   SELECT pg_tde_is_encrypted('<table>');
\set ON_ERROR_STOP on

CREATE EXTENSION IF NOT EXISTS pg_tde;

-- KEY NAMES ARE UNIQUE PER DATABASE CREATION. A database rebuilt beside a
-- kept key volume (the archive restore: data lost, keys kept) finds the old
-- keys still in the keyring; reusing a name would fail this script, and the
-- restarted container would then skip initialisation and run UNENCRYPTED.
-- A new database gets new keys; the old ones stay in the file, unused.
\set created `date -u +%Y%m%dT%H%M%S`
\set principal_key 'ememory-principal-' :created
\set wal_key 'ememory-wal-' :created

SELECT pg_tde_add_global_key_provider_file('ememory-file-keyring', '/tde_keys/keyring.per');
SELECT pg_tde_create_key_using_global_key_provider(:'principal_key', 'ememory-file-keyring');
SELECT pg_tde_set_default_key_using_global_key_provider(:'principal_key', 'ememory-file-keyring');
SELECT pg_tde_create_key_using_global_key_provider(:'wal_key', 'ememory-file-keyring');
SELECT pg_tde_set_server_key_using_global_key_provider(:'wal_key', 'ememory-file-keyring');

ALTER SYSTEM SET default_table_access_method = 'tde_heap';
ALTER SYSTEM SET pg_tde.wal_encrypt = on;

\connect template1
CREATE EXTENSION IF NOT EXISTS pg_tde;

\connect postgres
CREATE EXTENSION IF NOT EXISTS pg_tde;
