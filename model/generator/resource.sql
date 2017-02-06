
CREATE OR REPLACE FUNCTION
kx_process_resource_parameters(r jsonb) returns jsonb language plpgsql AS $$ BEGIN
  -- Inflect table name
  SELECT jsonb_set(r, '{singular}', to_jsonb(inflection_singularize(r->>'table_name'))) 
    INTO r;

  -- Find which column contains value to generate slug against (name or title)
  -- falls back to id otherwise
  SELECT jsonb_set(r, '{title_column}', to_jsonb('id'::text))
    INTO r;
  SELECT jsonb_set(r, '{title_column}', value->'name')
    FROM jsonb_array_elements(r->'columns')
    WHERE value->>'name' = 'title'
       or value->>'name' = 'name'
    LIMIT 1
    INTO r;

  -- Expand composite columns, filter out unmatching stuff
  SELECT jsonb_set(r, '{columns}', kx_process_columns_parameters(r)) 
    INTO r;


  return r;
end
$$;



CREATE OR REPLACE FUNCTION
kx_create_trigger(r jsonb, name text, type text, scope text DEFAULT null) returns void language plpgsql AS $$ BEGIN
    
  EXECUTE  'DROP TRIGGER  IF EXISTS ' || (name) || ' on ' || concat_ws('_', r->>'table_name', scope) || ' cascade';
  EXECUTE  'CREATE TRIGGER ' || (name) || '
            ' || type || ' ON ' || concat_ws('_', r->>'table_name', scope) || '
            FOR EACH ROW EXECUTE PROCEDURE ' || (name) || '()';
end
$$;


-- Replace table, its triggers, views and functions
-- !!!WILL LOSE DATA!!!, as it replaces the table
CREATE OR REPLACE FUNCTION
create_resource(r jsonb) returns jsonb language plpgsql AS $$
begin

  return  create_resource_actions(
            create_resource_scopes_with_defaults(
              create_validation_function(
                create_table(
                  kx_process_resource_parameters(r)))));
end;
$$;



-- Update table columns and reinitialize triggers/functions
-- WILL NOT LOST DATA, it will soft migrate & archive removed columns
CREATE OR REPLACE FUNCTION
update_resource(r jsonb) returns jsonb language plpgsql AS $$
begin

  return  create_resource_actions(
            create_resource_scopes_with_defaults(
              create_validation_function(
                update_table(
                  kx_process_resource_parameters(r)))));
end;
$$;

--select kx_discover();






