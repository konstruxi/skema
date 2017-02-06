

-- Walk through arrays and convert to postgresql syntax
CREATE OR REPLACE FUNCTION
kx_prepare_record(new anyelement, params jsonb, blobs bytea[] DEFAULT NULL)
returns anyelement language plpgsql AS $ff$ begin
  return jsonb_populate_record(new, params);
end $ff$;


-- For table like `articles`, return `params->'article'`
CREATE OR REPLACE FUNCTION
kx_prepare_params(new anyelement, table_name text, params jsonb)
returns jsonb language plpgsql AS $ff$ begin
  return params->(inflection_singularize(table_name));
end $ff$;

-- Keep only essential columns (e.g. to generate options for <select>)
CREATE OR REPLACE FUNCTION
kx_clean_jsonb(input jsonb)
returns jsonb language plpgsql AS $ff$ declare
ret jsonb;
begin
  IF jsonb_typeof(input) != 'object' THEN
    return NULL;
  END IF;
  SELECT jsonb_object_agg(key, value)
      FROM jsonb_each(input) cols
      WHERE key = 'id' or
            key = 'root_id' or
            key = 'slug' or
            key = 'title' or
            key = 'name' or
            key = 'summary'
  INTO ret;
  return ret;
end $ff$;


-- For table like `articles`, return `params->'article'`
CREATE OR REPLACE FUNCTION
kx_last_modified(updated_at TIMESTAMP WITH TIME ZONE)
returns text language plpgsql AS $ff$ begin
  return to_char(updated_at at time zone 'gmt' , 'Dy, dd Mon YYYY HH24:MI:ss GMT');
end $ff$;