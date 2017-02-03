

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




-- For table like `articles`, return `params->'article'`
CREATE OR REPLACE FUNCTION
kx_last_modified(updated_at TIMESTAMP WITH TIME ZONE)
returns text language plpgsql AS $ff$ begin
  return to_char(updated_at at time zone 'gmt' , 'Dy, dd Mon YYYY HH24:II:ss GMT');
end $ff$;