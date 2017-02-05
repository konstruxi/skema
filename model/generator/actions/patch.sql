-- Turns update into insert with incremented version
CREATE OR REPLACE FUNCTION
create_resource_patch_action(r jsonb) returns jsonb language plpgsql AS $ff$ 
DECLARE
  columns text;
  values text;
begin
  -- Generate list of columns
  SELECT string_agg(value->>'name', ', ')
    FROM jsonb_array_elements(r->'columns')
    WHERE  value->>'patch' is null or value->>'patch' != 'false'
    into columns;
  
  -- Generate list of columns prefixed with new.
  SELECT string_agg(
          CASE WHEN value->>'patch' is null THEN
            'coalesce(new.' || (value->>'name') ||
                   ', old.' || (value->>'name') || ')' 
          WHEN value->>'patch' = 'false' THEN
            null
          ELSE 
            value->>'patch'
          END, ',
')
    FROM jsonb_array_elements(r->'columns')
    WHERE value->>'patch' is null or value->>'patch' != 'false'
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


