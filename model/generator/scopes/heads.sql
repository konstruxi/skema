-- Scope: last versions (including deleted)
CREATE OR REPLACE FUNCTION
create_resource_heads_scope(r jsonb, columns text DEFAULT '*') returns json language plpgsql AS $ff$ BEGIN

  EXECUTE 'CREATE OR REPLACE VIEW ' || (r->>'table_name') || '_heads AS 
            SELECT DISTINCT ON (root_id) ' || columns || ' from ' || (r->>'table_name') || '_versions';

  -- Find last version of an row, optionally may return invalid version too
  EXECUTE  'CREATE OR REPLACE FUNCTION ' || (r->>'singular') || '_head(integer, boolean DEFAULT true, integer DEFAULT 2147483646) RETURNS integer
            AS $$ SELECT version from ' || (r->>'table_name') || '  
                  WHERE root_id = $1 
                    and version < $3 
                    and case when $2 then errors is null else true end 
                  ORDER BY version DESC $$
            LANGUAGE SQL IMMUTABLE RETURNS NULL ON NULL INPUT';

  -- DELETE from {resource}_heads 
  -- Roll back to version
  EXECUTE  'CREATE OR REPLACE 
            FUNCTION delete_' || (r->>'singular') || '_head() returns trigger language plpgsql AS $$ begin
              DELETE from ' || (r->>'table_name') || '_versions WHERE id=old.id;
              return null;
            end; $$';

  -- Wire up deletion trigger
  EXECUTE kx_create_trigger(r, 'delete_' || (r->>'singular') || '_head', 'INSTEAD OF DELETE', 'heads');


  -- UPDATE {resources}_heads      
  -- Create new version based on one given in parameters
  EXECUTE  'CREATE OR REPLACE 
            FUNCTION update_' || (r->>'singular') || '_head() returns trigger language plpgsql AS $$ declare
              next integer := ' || (r->>'singular') || '_head(new.root_id, true, coalesce(new.next_version, old.version) + 1);
            begin
              UPDATE ' || (r->>'table_name') || ' SET updated_at=now(), root_id=-1 WHERE version=next;
              return null;
            end; $$';

  -- Wire up update trigger
  EXECUTE kx_create_trigger(r, 'update_' || (r->>'singular') || '_head', 'INSTEAD OF UPDATE', 'heads');

  return r;
END $ff$;