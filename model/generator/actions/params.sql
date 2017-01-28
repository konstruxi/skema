CREATE OR REPLACE FUNCTION
create_resource_params_functions(r jsonb)
returns jsonb language plpgsql AS $ff$ 
DECLARE
  file_columns text := '';
begin
  -- Generate code to invoke function that assigns blobs 
  -- from flat bytea[] to the record based on json metadata
  -- Example:
  --   new.file_blobs = assign_uploaded_blobs(new.file_blobs, new.file, blobs)
  SELECT string_agg(
    CASE WHEN value->>'type' LIKE 'file%' THEN
      'new.' || (value->>'name') || '_blobs = 
        assign_uploaded_blobs(
          new.' || (value->>'name') || '_blobs, 
          new.' || (value->>'name') || ', 
          blobs);' 
    WHEN value->>'type' = 'xml' THEN
      'new.' || (value->>'name') || '_embeds_blobs = 
        assign_uploaded_blobs(
          new.' || (value->>'name') || '_embeds_blobs, 
          new.' || (value->>'name') || '_embeds, 
          blobs);'
    END, '
')

    FROM jsonb_array_elements(r->'columns')
    into file_columns;


  -- Build record out of blobs and assign parameters
  EXECUTE  'CREATE OR REPLACE FUNCTION
            kx_prepare_record(new ' || quote_ident(r->>'table_name') || ', params jsonb, blobs bytea[]) 
            returns ' || quote_ident(r->>'table_name') || ' language plpgsql AS $$ 
            begin
              SELECT * FROM kx_prepare_record(new, params) into new;
              ' || coalesce(file_columns, '') || '
              return new; 
            end $$';

  -- Prepare json parameters for 
  -- PG barfs on unquoted strings in json columns 
    SELECT string_agg(
        'IF jsonb_typeof(attributes->''' || (value->>'name') || ''') = ''string'' THEN
          select jsonb_set(attributes, ''{' || (value->>'name') || '}'', 
                           to_json(to_json(attributes->>''' || (value->>'name') || ''')::text)::jsonb)
          into attributes;
        END IF;','
')
      FROM jsonb_array_elements(r->'columns')
      WHERE value->>'type' = 'file' 
         or value->>'type' LIKE 'json%'
      into file_columns;

    EXECUTE  'CREATE OR REPLACE FUNCTION
              kx_prepare_params(new ' || (r->>'table_name') || ', table_name text, params jsonb) 
              returns jsonb language plpgsql AS $$ declare
                attributes jsonb := params->''' || inflection_singularize(r->>'table_name') || ''';
              begin
                ' || coalesce(file_columns, '') || '
                return attributes; 
              end $$';
  RETURN r;
END $ff$;
