

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