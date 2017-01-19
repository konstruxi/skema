-- Scope CURRENT: last non-deleted versions 
-- Deleting from current scope deletes last version of the record
CREATE OR REPLACE FUNCTION
create_resource_current_scope(r jsonb) returns json language plpgsql AS $ff$ BEGIN
  
  -- Create {resource}_current view that filters out deleted rows
  EXECUTE 'CREATE OR REPLACE 
  VIEW ' || (r->>'table_name') || '_current AS 
  SELECT * FROM ' || (r->>'table_name') || '_heads  WHERE deleted_at is null';

  -- Set up a deletion trigger which redirects delete to main table 
  EXECUTE 'CREATE OR REPLACE function
  delete_current_' || (r->>'singular') || '() returns trigger
  language plpgsql
  AS $$
    begin
      DELETE from ' || (r->>'table_name') || ' WHERE id=old.id;
      return null;
    end;
  $$';

  -- Wire up the trigger
  EXECUTE 'CREATE TRIGGER delete_current_' || (r->>'singular') || '
      INSTEAD OF DELETE ON ' || (r->>'table_name') || '_current
      FOR EACH ROW EXECUTE PROCEDURE delete_current_' || (r->>'singular') || '();';

  return r;
END $ff$;

