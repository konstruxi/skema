
-- create a table from json definition
CREATE OR REPLACE FUNCTION
create_table(r jsonb) returns jsonb language plpgsql AS $$ declare
  columns text;
begin
  -- Drop old table
  EXECUTE 'DROP TABLE IF EXISTS ' || (r->>'table_name') || ' CASCADE;';
  
  -- Enumerate columns in json object
  SELECT
    string_agg(
      (value->>'name') || ' ' || (value->>'type') ||

      -- Add extra columns if version column is present
      (CASE WHEN value->>'name' = 'version' THEN
        ',root_id integer,                -- ID of a first version
    previous_version integer,             -- ID of a previous version
    next_version integer'
      ELSE
        ''
      END), ',
    ')
    FROM jsonb_array_elements(r->'columns')
    WHERE value->>'name' != 'id'
    into columns;

  -- Create new table
  EXECUTE 'CREATE TABLE ' || (r->>'table_name') || '(
    id serial PRIMARY KEY,                -- Serial ID,
    created_at TIMESTAMP WITH TIME ZONE,  -- Initial creation time
    updated_at TIMESTAMP WITH TIME ZONE,  -- Last time of update
    errors jsonb,                         -- Results of validation
    ' || columns || ');';

  return r;
end $$;
