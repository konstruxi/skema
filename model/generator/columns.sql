
CREATE OR REPLACE FUNCTION
kx_process_columns_parameters(r jsonb) returns jsonb language plpgsql AS $$ declare
  columns jsonb;
BEGIN
  SELECT ('[' || 
    -- mandatory columns that every resource gets
    jsonb_build_object(
      'name', 'id',          
      'type', 'serial PRIMARY KEY',
      'patch', FALSE)::text || ',' ||

    -- slug string used in url built from title 
    jsonb_build_object(
      'name', 'slug',        
      'type', 'varchar',
      'insert', 'coalesce(nullif(new.slug, ''''), nullif(inflections_slugify(new.' || (r->>'title_column') || '), ''''), ''' || (r->>'singular') || '-'' || new.id::text)',
      'inherit', FALSE)::text || ',' ||

    -- timestamp of creation
    jsonb_build_object(
      'name', 'created_at',  
      'type', 'timestamptz',
      'insert', 'coalesce(new.created_at, now())',
      'inherit', 'old.created_at',
      'patch',  'old.created_at')::text || ',' ||

    -- last modified date
    jsonb_build_object(
      'name', 'updated_at',  
      'type', 'timestamptz',
      'insert', 'coalesce(new.updated_at, now())',
      'patch', 'now()')::text || ',' ||

    -- validation errors
    jsonb_build_object(
      'name', 'errors',      
      'type', 'jsonb',
      'insert', 'validate_' || (r->>'singular') || '(new)',
      'patch', FALSE)::text || ',' ||

    -- data archived from removed columns
    jsonb_build_object(
      'name', 'outdated',    
      'type', 'jsonb',
      'patch', FALSE)::text || ',' ||

    -- data archived from removed columns
    (CASE WHEN r->>'table_name' != 'services' THEN
      jsonb_build_object(
        'name', 'service_id',    
        'type', 'integer')::text || ','
    ELSE
      ''
    END)

  || string_agg(

    -- For file fields add a json column with meta data
   (CASE WHEN col->>'type' = 'file' or col->>'type' = 'files' THEN
      -- Initialize flat list of uploaded files
      kx_process_column(col, jsonb_build_object(
        'name', col->>'name', 
        'type', 'jsonb',
        'insert', 'assign_file_indecies(assign_file_list(new.' || (value->>'name') || '))',
        'inherit', 'assign_file_indecies(' || 
                      'assign_file_list(new.' || (value->>'name') || '::jsonb, ' ||
                          'old.' || (value->>'name') || '::jsonb))'))::text || ',' ||

      -- do not inherit blobs
      kx_process_column(col, jsonb_build_object(
        'name', (col->>'name') || '_blobs', 
        'type', 'bytea[]',
        'inherit', 'null',
        'view', FALSE))::text


     -- For each WYSIWYG field add file attachments columns
    WHEN col->>'type' = 'xml' THEN

      -- Process XML into wellformed roots
      kx_process_column(col, jsonb_build_object(
        'name', col->>'name', 
        'type', 'xml',
        'insert', 'xmlarticleroot(new.' || (col->>'name') || ', ''' || (r->>'table_name') || ''', new.slug, ''' || (col->>'name') || ''')'))::text || ',' ||

      -- Initialize flat list of uploaded files
      kx_process_column(col, jsonb_build_object(
        'name', col->>'name' || '_embeds', 
        'type', 'jsonb',
        'insert', 'assign_file_indecies(assign_file_list(new.' || (value->>'name') || '_embeds))',
        'inherit', 'assign_file_indecies(' || 
                      'assign_file_list(new.' || (value->>'name') || '_embeds::jsonb, ' ||
                         'old.' || (value->>'name') || '_embeds::jsonb))'))::text || ',' ||

      -- do not inherit blobs
      kx_process_column(col, jsonb_build_object(
        'name', (col->>'name') || '_embeds_blobs', 
        'type', 'bytea[]',
        'inherit', 'new.' || (col->>'name') || '_embeds_blobs',
        'view', FALSE))::text


    -- Add pointers to next, previous version number and first version id
    WHEN col->>'name' = 'version' THEN
      -- start with version 1 unless provided
      kx_process_column(col, jsonb_build_object(
        'name', col->>'name',
        'type', 'integer',
        'insert', 'coalesce(new.version, 1)',
        'inherit', (r->>'singular') || '_head(new.root_id, false) + 1',
        'patch', FALSE))::text || ',' ||

      -- inherit root_id or set to self
      kx_process_column(col, jsonb_build_object(
        'name', 'root_id',
        'type', 'integer',
        'insert',  'coalesce(new.root_id, new.id)',
        'inherit', 'coalesce(old.root_id, new.root_id)',
        'patch',   'old.root_id'))::text || ',' ||

      kx_process_column(col, jsonb_build_object(
        'name', 'previous_version', 
        'type', 'integer',
        'inherit', 'old.version',
        'patch',   'CASE WHEN new.root_id = -1 ' || 
                   'THEN old.previous_version ELSE old.version END'))::text || ',' ||

      kx_process_column(col, jsonb_build_object(
        'name', 'next_version',
        'type', 'integer',
        'inherit', 'old.next_version',
        'patch',   'CASE WHEN new.next_version = old.next_version and new.root_id != -1 ' || 
                   ' THEN null ELSE new.next_version END'))::text

    ELSE
      kx_process_column(col, jsonb_build_object('name', col->>'name', 'type', col->>'type'),
                            -- make title/name required
                             r->'title_column' = col->'name')::text
    END

    ), ',') || ']')::jsonb

    FROM jsonb_array_elements(r->'columns') col
    WHERE kx_is_custom_column(col->>'name')
      AND kx_is_allowed_type(col->>'type')

    INTO columns;

  return columns;
  end
$$;

-- track renamed columns
CREATE OR REPLACE FUNCTION
kx_process_column(col jsonb, def jsonb, required boolean default false) returns jsonb language plpgsql AS $$ 
BEGIN
  -- inject required validation
  IF (required) THEN
    SELECT jsonb_set(def, '{validations}',
      CASE WHEN def->>'validations' is not null THEN
        def->'validations' || '["required"]'::jsonb
      ELSE
        '["required"]'::jsonb
      END)
    INTO def;
  END IF;

  -- keep old name of a column when renaming
  IF (col->>'previously' is not NULL) THEN
    return jsonb_set(def, '{previously}', col->'previously');
  END IF;

  return def;
END
$$;

-- whitelist column names:
-- filter out all known composite names and mandatory columns
CREATE OR REPLACE FUNCTION
kx_is_custom_column(name text) returns boolean language plpgsql AS $$ begin
  return name != 'id' and
         name != 'created_at'  and
         name != 'updated_at'  and
         name != 'outdated'  and
         name != 'errors'  and
         name != 'slug'  and
         name != 'updated_at'  and
         name != 'root_id'  and
         name != 'next_version'  and
         name != 'previous_version'  and
         name !~ '_blobs|_embeds';
END $$;

-- whitelist column types
CREATE OR REPLACE FUNCTION
kx_is_allowed_type(type text) returns boolean language plpgsql AS $$ begin
  return type = 'integer' or
         type ~ 'varchar(?:\(\d+\))?' or
         type = 'text' or
         type = 'bigint' or
         type = 'file' or
         type = 'files' or
         type = 'timestamp' or
         type = 'timestamptz' or
         type = 'uuid' or
         type = 'xml';
END $$;




CREATE OR REPLACE FUNCTION
kx_update_column(r jsonb, new jsonb, old jsonb) returns jsonb language plpgsql AS $$ declare
  columns text;
begin
  IF new is NULL THEN
    return remove_column(r, old);
  END IF;

  IF old is NULL THEN
    SELECT add_column(r, new)
    INTO new;
  END IF;

  IF new->>'name' != old->>'name' THEN
    EXECUTE 'ALTER TABLE ' || (r->>'table_name') || ' RENAME COLUMN ' || (old->>'name') || ' TO ' || (new->>'name');
  END IF;
  
  EXECUTE 'COMMENT ON column ' || (r->>'table_name') || '.' || (new->>'name') || 
        ' is ' || '''{"index": ' || (new->>'index')::int || '}''';


  return new;
end $$;


CREATE OR REPLACE FUNCTION
add_column(r jsonb, col jsonb) returns jsonb language plpgsql AS $$ declare
  migration text;
begin
  EXECUTE 'ALTER TABLE ' || (r->>'table_name') || ' ' ||
          'ADD ' || (col->>'name') || ' ' || (col->>'type');

  -- Restore archived values for the column from "outdated" object
  IF (col->>'name') != 'outdated' and (col->>'name' NOT LIKE '%_blobs') THEN
  
  EXECUTE 'UPDATE ' || (r->>'table_name') ||
          ' SET outdated = outdated - '''  || (col->>'name') || ''', '  
          || (col->>'name') || ' = kx_best_effort_' || regexp_replace(
                                                        regexp_replace((col->>'type'), '\[.*\]', '_array')
                                                        , '\(.*\)', '')
          || '(outdated->>''' || (col->>'name') || ''''
          ') where outdated->>''' || (col->>'name') || ''' is not NULL' ||
          ' and ' || (col->>'name') || ' is NULL';
  END IF;

  return jsonb_set(col, '{new}', to_jsonb(1));
  --RETURN CASE WHEN r->>'migrations' is NULL THEN
  --  jsonb_set(r, '{migrations}', jsonb_build_array(migration))
  --ELSE
  --  jsonb_set(r, '{migrations}', (r->'migrations') || jsonb_build_array(migration))
  --END;
end $$;



CREATE OR REPLACE FUNCTION
remove_column(r jsonb, col jsonb) returns jsonb language plpgsql AS $$ declare
  columns text;
begin
  --EXECUTE 'ALTER TABLE ' || (r->>'table_name') || ' DISABLE TRIGGER USER';
  -- Store values from removed columns in json storage
  -- Side channel information to UPDATE trigger to avoid creation of a new version
  IF (col->>'name') != 'outdated' and (col->>'name' NOT LIKE '%_blobs') THEN
  EXECUTE 'UPDATE ' || (r->>'table_name') ||
          ' SET outdated = jsonb_set(
                            coalesce(outdated, ''{}''::jsonb), ''{' || (col->>'name') || '}'', 
                            to_jsonb(' || (col->>'name') || '))' ||
          ' where ' || (col->>'name') || ' is not NULL';
  END IF;
  --EXECUTE 'ALTER TABLE ' || (r->>'table_name') || ' ENABLE TRIGGER USER';

  EXECUTE 'ALTER TABLE ' || (r->>'table_name') || ' ' ||
          'DROP ' || (col->>'name') || ' cascade ';

  return col;


end $$;


