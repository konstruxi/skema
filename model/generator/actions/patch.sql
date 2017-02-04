-- Turns update into insert with incremented version
CREATE OR REPLACE FUNCTION
create_resource_patch_action(r jsonb) returns jsonb language plpgsql AS $ff$ 
DECLARE
  columns text;
  values text;
begin
  -- Generate list of columns
  SELECT string_agg(CASE 
    WHEN value->>'type' = 'xml' THEN
      (value->>'name')
    WHEN value->>'type' LIKE 'file%' THEN
      (value->>'name')
    WHEN value->>'name' = 'id' THEN
      null
    ELSE
      (value->>'name')
    END, ', ')
    FROM jsonb_array_elements(r->'columns')
    WHERE value->>'name' != 'version'
    into columns;
  
  -- Generate list of columns prefixed with new.
  SELECT string_agg(CASE 
    WHEN value->>'name' = 'root_id' THEN
      'old.root_id'
    WHEN value->>'name' = 'previous_version' THEN
      'CASE WHEN new.root_id = -1 THEN
        old.previous_version
      ELSE
        old.version
      END'
    WHEN value->>'name' = 'next_version' THEN
      'CASE WHEN new.next_version = old.next_version and new.root_id != -1 THEN
        null
      ELSE
        new.next_version
      END'
    WHEN value->>'name' = 'root_id' THEN
      'old.root_id'
    WHEN value->>'name' = 'created_at' THEN
      'old.created_at'
    WHEN value->>'name' = 'updated_at' THEN
      'now()'
    WHEN value->>'name' = 'id' THEN
      null
    ELSE
      'new.' || (value->>'name')
    END, ', ') FROM jsonb_array_elements(r->'columns')
    WHERE value->>'name' != 'version'
    into values;

  EXECUTE  'CREATE OR REPLACE FUNCTION
            update_' || (r->>'singular') || '() returns trigger language plpgsql AS $$ begin
              IF old.outdated is DISTINCT FROM new.outdated THEN      -- when altering table structure
                return new;                             -- dont create new version 
              END IF;
              INSERT INTO ' || (r->>'table_name') || '(' || columns || ')
              VALUES (' || values || ');
              return null;                              -- keep row immutable
            end $$;';

  EXECUTE kx_create_trigger(r, 'update_' || (r->>'singular'), 'BEFORE UPDATE');

  return r;
END $ff$;


