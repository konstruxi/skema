-- create a table from json definition
CREATE OR REPLACE FUNCTION
update_table(r jsonb) returns jsonb language plpgsql AS $$ declare
  ret jsonb;
  old jsonb;
begin

  -- Lookup old definition for resource
  SELECT row_to_json(kx_resources)
    FROM kx_resources
    WHERE table_name = r->>'table_name'
    INTO old;

  -- create table initially in one go with legacy generator
  --IF old is NULL THEN
  --  return create_table(r);
  -- END IF;

  SELECT jsonb_object_agg(
           coalesce(n.value->>'name', o.value->>'name'), 
           kx_update_column(r, n.value, o.value)
         )
  FROM jsonb_array_elements(r->'columns') n 
  FULL OUTER JOIN jsonb_array_elements(old->'columns') o
  on (n.value->'name' = o.value->'name')
  where (n is null or kx_is_custom_column(n.value->>'name'))
  and (o is null or kx_is_custom_column(o.value->>'name'))
  into ret;

  -- modify table column by column


  return r;


end $$;

CREATE OR REPLACE FUNCTION
kx_update_column(r jsonb, new jsonb, old jsonb) returns jsonb language plpgsql AS $$ declare
  columns text;
begin
  IF old is NULL THEN
    return add_column(r, new);
  END IF;
  
  IF new is NULL THEN
    return remove_column(r, old);
  END IF;

  return new;
end $$;


CREATE OR REPLACE FUNCTION
add_column(r jsonb, col jsonb) returns jsonb language plpgsql AS $$ declare
  migration text;
begin
  EXECUTE 'ALTER TABLE ' || (r->>'table_name') || ' ' ||
          'ADD ' || (col->>'name') || ' ' || (col->>'type');

  -- Restore archived values for the column
  
  EXECUTE 'UPDATE ' || (r->>'table_name') ||
          ' SET ' || (col->>'name') || ' = outdated->>''' || (col->>'name') || ''''
          ' where outdated->>''' || (col->>'name') || ''' is not NULL' ||
          ' and ' || (col->>'name') || ' is NULL';

  return r;
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
  EXECUTE 'UPDATE ' || (r->>'table_name') ||
          ' SET outdated = jsonb_set(
                            coalesce(outdated, ''{}''::jsonb), ''{' || (col->>'name') || '}'', 
                            to_jsonb(' || (col->>'name') || '))' ||
          ' where ' || (col->>'name') || ' is not NULL';

  --EXECUTE 'ALTER TABLE ' || (r->>'table_name') || ' ENABLE TRIGGER USER';

  EXECUTE 'ALTER TABLE ' || (r->>'table_name') || ' ' ||
          'DROP ' || (col->>'name') || ' cascade ';

  return col;


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

