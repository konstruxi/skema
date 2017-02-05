-- create a table from json definition
CREATE OR REPLACE FUNCTION
update_table(r jsonb) returns jsonb language plpgsql AS $$ declare
  old jsonb;
  added_columns jsonb;
  updated_columns jsonb;
begin

  -- Lookup old definition for resource
  SELECT row_to_json(kx_resources)
    FROM kx_resources
    WHERE table_name = r->>'table_name'
    limit 1
    INTO old;

  SELECT jsonb_set(r, '{columns}', jsonb_agg(v) FILTER (WHERE n is not NULL))
  FROM (

      SELECT 
        kx_update_column(r, n.value, o.value) as v, o, n
      FROM (
        SELECT jsonb_set(value, '{index}', to_jsonb(row_number() OVER())) as value
        FROM jsonb_array_elements(r->'columns')
      ) n
      FULL OUTER JOIN jsonb_array_elements(old->'columns') o
      on (coalesce(n.value->'previously', n.value->'name') = o.value->'name')
  ) q
  into old;

  return old;


end $$;






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
      (value->>'name') || ' ' || (value->>'type')
    , ',')
    FROM jsonb_array_elements(r->'columns')
    into columns;

  -- Create new table
  EXECUTE 'CREATE TABLE ' || (r->>'table_name') || '(' || columns || ');';

  return r;
end $$;

