-- Scope VERSIONS: history of changes 
-- Deleting from the view will create a version with deletion flag set
CREATE OR REPLACE FUNCTION
create_resource_versions_scope(r jsonb, columns text DEFAULT '*') returns json language plpgsql AS $ff$ BEGIN

-- Create view containing all versions of all documents in reverse order
EXECUTE  'CREATE OR REPLACE 
          VIEW ' || (r->>'table_name') || '_versions AS 
          SELECT ' || columns || ' from ' || (r->>'table_name') || '
          WHERE errors is null 
          ORDER BY root_id, version DESC';

-- DELETE from {resources}_versions 
-- Roll back to version previous to deleted
EXECUTE  'CREATE OR REPLACE function
          delete_' || (r->>'singular') || '_version() returns trigger
          language plpgsql
          AS $$
            declare
              prev integer := ' || (r->>'singular') || '_head(old.root_id, true, old.previous_version + 1);
              next integer := (SELECT next_version from ' || (r->>'table_name') || ' WHERE version=prev and root_id = old.root_id);
            begin
              -- if there is no valid version to roll back to, mark as deleted if it isnt yet
              IF prev is null and old.deleted_at is null THEN
                DELETE FROM ' || (r->>'table_name') || '_current WHERE id=old.id;
              ELSE
                
                -- otherwise clone preceeding version without deletion flag and make it current
                UPDATE ' || (r->>'table_name') || '
                SET deleted_at=null, 
                    next_version=coalesce(next, old.version), 
                    root_id=-1
                WHERE root_id = old.root_id and version=coalesce(prev, old.version);
              END IF;
              return null;
            end;
          $$';

-- Wire in the trigger
EXECUTE kx_create_trigger(r, 'delete_' || (r->>'singular') || '_version', 'INSTEAD OF DELETE', 'versions');

return r;

END $ff$;