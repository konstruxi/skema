CREATE OR REPLACE FUNCTION
create_resource_insert_action(r jsonb) returns jsonb language plpgsql AS $ff$ 
DECLARE
  assign_formatted_values text := '';
  inhert_values_from_parent_version text := '';
begin
  -- Generate code to inherit values from version specified by root_id value
  -- inherit data form last valid version unless previous_version is set
  IF EXISTS(SELECT 1 from jsonb_array_elements(r->'columns') WHERE value->>'name' = 'version') THEN
    SELECT 'IF (new.root_id is not NULL) and (new.version is NULL) THEN
              SELECT * FROM ' || (r->>'table_name') || '
              WHERE version = coalesce(new.previous_version, ' || (r->>'singular') || '_head(new.root_id, true))
                and root_id = new.root_id
              LIMIT 1 
              INTO old;
              ' || string_agg(
                -- xml + metadata + blobs
                CASE WHEN value->>'inherit' is not null AND value->>'inherit' != 'false'THEN
                  'new.' || (value->>'name') || ' = ' || (value->>'inherit')
                WHEN value->>'inherit' != 'false' THEN
                  'new.' || (value->>'name') || 
                         ' = coalesce(new.' || (value->>'name') ||
                                      ', old.' || (value->>'name') || ')' 
                END
              , ';
') || 
            '; END IF;'
    FROM jsonb_array_elements(r->'columns')
    INTO inhert_values_from_parent_version;
  END IF;

  -- Generate list of values prepared for insertion
  -- in their ordinal order
  SELECT string_agg('new.' || (value->>'name') || ' = ' || (value->>'insert') || ';', '
')
    FROM jsonb_array_elements(r->'columns')
    into assign_formatted_values;


  -- Inserts new version of a row
  EXECUTE  'CREATE OR REPLACE FUNCTION
            create_' || (r->>'singular') || '() returns trigger language plpgsql AS $$ begin
              ' || inhert_values_from_parent_version || '
              ' || assign_formatted_values || '
              return new; 
            end $$';

  EXECUTE kx_create_trigger(r, 'create_' || (r->>'singular'), 'BEFORE INSERT');

  RETURN r;
END $ff$;