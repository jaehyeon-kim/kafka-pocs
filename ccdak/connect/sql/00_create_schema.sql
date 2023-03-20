CREATE SCHEMA ods;

-- change search_path on a connection-level
SET search_path TO ods;

-- change search_path on a database-level
ALTER database "main" SET search_path TO ods;