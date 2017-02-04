CREATE OR REPLACE FUNCTION
create_resource_insert_action(r jsonb) returns jsonb language plpgsql AS $ff$ 
DECLARE
  columns text := '';
  file_columns text := '';
  title_column text := 'id';
  inhert_values_from_parent_version text := '';
  reject_malformed_values text := '';
begin
  -- Reject malformed values
  -- SELECT string_agg(CASE WHEN value->>'type' = 'xml' THEN
  --   -- xml has to have tags in it and has to have no text on top level
  --   'IF NOT xml_is_well_formed_document(new.' || (value->>'name') || '::text) THEN' ||
  --     ' new.' || (value->>'name') || ' = null; END IF;'
  -- END, '')
  -- FROM jsonb_array_elements(r->'columns')
  -- into reject_malformed_values;



  -- Generate code to inherit values from version specified by root_id value
  -- inherit data form last valid version unless previous_version is set
  IF EXISTS(SELECT 1 from jsonb_array_elements(r->'columns') WHERE value->>'name' = 'version') THEN
    SELECT 'IF (new.root_id is not NULL) and (new.version is NULL) THEN
              SELECT * FROM ' || (r->>'table_name') || '
              WHERE version = coalesce(new.previous_version, ' || (r->>'singular') || '_head(new.root_id, true))
                and root_id = new.root_id
              LIMIT 1 
              INTO old;
              
              new.created_at = old.created_at;
              new.root_id = coalesce(old.root_id, new.root_id);
              new.version = ' || (r->>'singular') || '_head(new.root_id, false) + 1;

              new.next_version = old.root_id;
              new.outdated     = coalesce(new.outdated, old.outdated);
              new.previous_version = old.version;
              ' || string_agg(
                -- xml + metadata + blobs
                CASE WHEN value->>'type' = 'xml' THEN
                  'new.' || (value->>'name') || 
                         ' = coalesce(new.' || (value->>'name') ||
                                      ', old.' || (value->>'name') || ');'
                -- inherit blobs
                WHEN value->>'type' LIKE 'file%' THEN
                  'new.' || (value->>'name') || 
                         ' =  assign_file_indecies(
                                assign_file_list(new.' || (value->>'name') ||
                                      '::jsonb, old.' || (value->>'name') || '::jsonb));'
                
                -- do NOT inherit blobs, only metadata
                WHEN value->>'type' LIKE 'bytea[]' THEN
                  '' 
                ELSE
                  'new.' || (value->>'name') || 
                         ' = coalesce(new.' || (value->>'name') ||
                                      ', old.' || (value->>'name') || ');' 
                END, '
              ') || '
            END IF;'
    FROM jsonb_array_elements(r->'columns')
    INTO inhert_values_from_parent_version;
  END IF;

  -- Find which column contains value to generate slug against (name or title)
  SELECT value->>'name' 
    FROM jsonb_array_elements(r->'columns')
    WHERE value->>'name' = 'title'
       or value->>'name' = 'name'
    INTO title_column LIMIT 1;


  -- Generate list of columns prefixed with new.
  SELECT string_agg(CASE
    WHEN value->>'name' = 'id' THEN
      'new.id'
     
    WHEN value->>'name' = 'slug' THEN
      'coalesce(new.slug, inflections_slugify(new.' || title_column || '))'
     
    WHEN value->>'name' = 'created_at' THEN
      'coalesce(new.created_at, now())'        -- inherit or set creation timestamp
                
    WHEN value->>'name' = 'updated_at' THEN
      'coalesce(new.updated_at, now())'        -- inherit or set modification timestamp
    
    WHEN value->>'name' = 'errors' THEN
      'validate_' || (r->>'singular') || '(new)'
       
    WHEN value->>'name' = 'id' THEN
      'coalesce(new.version, 1)'              -- start with version 1 unless given
     
    WHEN value->>'name' = 'version' THEN
      'coalesce(new.version, 1)'              -- start with version 1 unless given
     
    WHEN value->>'name' = 'root_id' THEN
      'coalesce(new.root_id, new.id)'          -- inherit root_id or set to self

    WHEN value->>'type' = 'xml' THEN
      'xmlarticle(new.' || (value->>'name') || ')'

    WHEN value->>'type' LIKE 'file%' THEN
      'assign_file_indecies(new.' || (value->>'name') || ')'
    ELSE
      'new.' || (value->>'name')
    END, ', ')
    FROM jsonb_array_elements(r->'columns')
    into columns;


  -- Inserts new version of a row
  EXECUTE  'CREATE OR REPLACE FUNCTION
            create_' || (r->>'singular') || '() returns trigger language plpgsql AS $$ begin
            ' || reject_malformed_values || '
            ' || inhert_values_from_parent_version || '
              return (' || columns || '); 
            end $$';

  EXECUTE kx_create_trigger(r, 'create_' || (r->>'singular'), 'BEFORE INSERT');

  RETURN r;
END $ff$;