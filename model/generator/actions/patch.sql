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
      (value->>'name') || ',' ||
      (value->>'name') || '_embeds,' ||
      (value->>'name') || '_embeds_blobs'
    WHEN value->>'type' LIKE 'file%' THEN
      (value->>'name') || ',' ||
      (value->>'name') || '_blobs'
    ELSE
      (value->>'name')
    END, ', ')
    FROM jsonb_array_elements(r->'columns')
    WHERE value->>'name' != 'version'
    into columns;
  
  -- Generate list of columns prefixed with new.
  SELECT string_agg(CASE 
    WHEN value->>'type' = 'xml' THEN
      'new.' || (value->>'name') || ',' ||
      'new.' || (value->>'name') || '_embeds,' ||
      'new.' || (value->>'name') || '_embeds_blobs'
    WHEN value->>'type' LIKE 'file%' THEN
      'new.' || (value->>'name') || ',' ||
      'new.' || (value->>'name') || '_blobs'
    ELSE
      'new.' || (value->>'name')
    END, ', ')
    FROM jsonb_array_elements(r->'columns')
    WHERE value->>'name' != 'version'
    into values;

  EXECUTE  'CREATE OR REPLACE FUNCTION
            update_' || (r->>'singular') || '() returns trigger language plpgsql AS $$ begin
              INSERT INTO ' || (r->>'table_name') || '(
                root_id, previous_version, next_version, 
                created_at, updated_at,' || columns || ')
              VALUES (
                old.root_id,                            -- inherit root_id
                CASE WHEN new.root_id = -1 THEN
                  old.previous_version
                ELSE
                  old.version
                END,
                CASE WHEN new.next_version = old.next_version and new.root_id != -1 THEN
                  null
                ELSE
                  new.next_version
                END,
                old.created_at,                         -- inherit creation timestamp 
                now(),                                  -- update modification timestamp
                ' || values || ');
              return null;                              -- keep row immutable
            end $$;';

  EXECUTE  'CREATE TRIGGER update_' || (r->>'singular') || '
            BEFORE UPDATE ON ' || (r->>'table_name') || '
            FOR EACH ROW EXECUTE PROCEDURE update_' || (r->>'singular') || '();';

  return r;
END $ff$;


