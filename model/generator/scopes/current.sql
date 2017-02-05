-- Scope CURRENT: last non-deleted versions 
-- Deleting from current scope deletes last version of the record
CREATE OR REPLACE FUNCTION
create_resource_current_scope(r jsonb, columns text DEFAULT '*') returns json language plpgsql AS $ff$ BEGIN
  
  -- Create {resource}_current view that filters out deleted rows
  EXECUTE 'DROP VIEW ' || (r->>'table_name') || '_current cascade';
  EXECUTE 'CREATE VIEW ' || (r->>'table_name') || '_current AS 
  SELECT ' || columns || ' FROM ' || (r->>'table_name') || '_heads  WHERE deleted_at is null';

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

  EXECUTE kx_create_trigger(r, 'delete_current_' || (r->>'singular'), 'INSTEAD OF DELETE', 'current');
 
  return r;
END $ff$;

