-- Scope: last versions 
CREATE OR REPLACE 
VIEW {resources}_heads AS 
SELECT DISTINCT ON (root_id) * from {resources}_versions;

-- Find last version of an row, optionally may return invalid version too
CREATE OR REPLACE FUNCTION {resource}_head(integer, boolean DEFAULT true, integer DEFAULT 2147483646) RETURNS integer
    AS 'SELECT version from {resources}  WHERE root_id = $1 and version < $3 and 
       case when $2 then errors is null else true end 
       ORDER BY version DESC'
    LANGUAGE SQL IMMUTABLE RETURNS NULL ON NULL INPUT;

-- DELETE from {resources}_heads -- Roll back to version
CREATE OR REPLACE 
FUNCTION delete_{resource}_head() returns trigger language plpgsql AS $$ begin
  DELETE from {resources}_versions WHERE id=old.id;
  return null;
end; $$;

CREATE TRIGGER delete_{resource}_head
    INSTEAD OF DELETE ON {resource}s_heads
    FOR EACH ROW EXECUTE PROCEDURE delete_{resource}_head();


-- UPDATE {resources}_heads      -- Set any version
CREATE OR REPLACE 
FUNCTION update_{resource}_head() returns trigger language plpgsql AS $$ declare
  next integer := {resource}_head(new.root_id, true, coalesce(new.next_version, old.version) + 1);
begin
  UPDATE {resources} SET updated_at=now(), root_id=-1 WHERE version=next;
  return null;
end; $$;

CREATE TRIGGER update_{resource}_head
    INSTEAD OF UPDATE ON {resources}_heads
    FOR EACH ROW EXECUTE PROCEDURE update_{resource}_head();
