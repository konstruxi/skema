CREATE OR REPLACE FUNCTION
create_resource_insert_action(r jsonb) returns jsonb language plpgsql AS $ff$ 
DECLARE
  columns text := '';
  rebase_version text := '';
begin
  -- Generate list of columns prefixed with new.
  SELECT string_agg(CASE WHEN value->>'name' = 'version' THEN
     'coalesce(new.version, 0),               -- start with 0 version unless given
      coalesce(new.root_id, new.id),          -- inherit root_id or set to self
      new.previous_version,                   -- point to previous version
      new.next_version                        -- point to next version
'
    ELSE
      'new.' || (value->>'name')
    END, ', ')
    FROM jsonb_array_elements(r->'columns')
    into columns;

  -- Generate code to inherit values from version specified by root_id value
  IF EXISTS(SELECT 1 from jsonb_array_elements(r->'columns') WHERE value->>'name' = 'version') THEN
    SELECT 'IF new.root_id is not NULL and new.version is NULL THEN
              SELECT * FROM ' || (r->>'table_name') || '
              WHERE id = new.root_id 
                 or root_id = new.root_id 
              ORDER BY id DESC LIMIT 1 
              INTO old;
              
              new.created_at = old.created_at;
              new.version = old.version + 1;
              new.root_id = coalesce(old.root_id, new.root_id);
              ' || string_agg('new.' || (value->>'name') || 
                       ' = coalesce(new.' || (value->>'name') ||
                                    ', old.' || (value->>'name') || ')', ';
              ') || ';
            END IF;'
    FROM jsonb_array_elements(r->'columns')
    INTO rebase_version;
  END IF;


  -- Inserts new version of a row
  EXECUTE  'CREATE OR REPLACE FUNCTION
            create_' || (r->>'singular') || '() returns trigger language plpgsql AS $$ begin
            ' || rebase_version || '
              return (
                new.id,
                coalesce(new.created_at, now()),        -- inherit or set creation timestamp
                coalesce(new.updated_at, now()),        -- inherit or set modification timestamp
                validate_' || (r->>'singular') || '(new),
            ' || columns || '); 
            end $$';

  EXECUTE  'CREATE TRIGGER create_' || (r->>'singular') || '
            BEFORE INSERT ON ' || (r->>'table_name') || '
            FOR EACH ROW EXECUTE PROCEDURE create_' || (r->>'singular') || '()';

  RETURN r;
END $ff$;