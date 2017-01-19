-- create a `validate_<table_name>` function from json definition of a table
CREATE OR REPLACE FUNCTION
create_validation_function(r jsonb) returns jsonb

language plpgsql AS $$ declare
  validations text;
begin
  
  -- Generate expression that invokes validation function
  -- and writes to errors object in case of failure
  SELECT
    string_agg('IF NOT validation_' || validation_name || '(new.' || column_name || ') THEN
        SELECT jsonb_set(errors, ''' || column_name || ''', ''' || validation_name || ''') into errors; 
      END IF;', '
')

  -- List each validation of each column as a flat list, if any
  FROM (SELECT value->>'name' as column_name, 
               jsonb_array_elements_text(value->'validations') as validation_name
    FROM jsonb_array_elements(r->'columns')
    WHERE value->>'validations' is not NULL) columns

  INTO validations;

  -- Define a function validate_<table> that checks if record is valid
  EXECUTE 'CREATE OR REPLACE FUNCTION
    validate_' || (r->>'singular') || '(new ' || (r->>'table_name') || ') 
    returns jsonb language plpgsql AS $ff$ declare
      errors jsonb := ''{}'';
    begin
' || coalesce(validations, '') || '
  if errors::text = ''{}'' THEN
    errors = null;
  END IF;

  return errors;
end $ff$;';

  return r;
end $$;

-- Check if text field is not empty
CREATE OR REPLACE FUNCTION
validation_required(value text) returns boolean language plpgsql AS $$ begin
  return value is not NULL and value != '';
end $$;

