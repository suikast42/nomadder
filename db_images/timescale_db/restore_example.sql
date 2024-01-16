-- Drop current db and then restore ( optional

-- Close all connections at first
SELECT
    pg_terminate_backend(pid)
FROM
    pg_stat_activity
WHERE
  -- don't kill my own connection!
    pid <> pg_backend_pid()
  -- don't kill the connections to other databases
  AND datname = 'bi'
;

-- Drop the DB
Drop database bi;
-- Create user for the DB
CREATE USER BIMASTER WITH SUPERUSER PASSWORD 'bimaster';
 --Create DB
CREATE DATABASE BI OWNER BIMASTER;


-- Default restore workflow
-- Logon to the bi database
SELECT timescaledb_pre_restore();

-- execute the pg_restore

SELECT timescaledb_post_restore();
ANALYSE;

Alternatvive migration
https://docs.timescale.com/migrate/latest/pg-dump-and-restore/pg-dump-restore-from-timescaledb/