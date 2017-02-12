

-- Replace
CREATE OR REPLACE FUNCTION
kx_create_service_resources(r jsonb) returns jsonb language plpgsql AS $$
begin
  return (SELECT jsonb_set(r, '{resources}', jsonb_agg(
            kx_create_nested_service_resources(q.value)))
          from (
            SELECT jsonb_set(value, '{index}', to_jsonb(row_number() OVER())) as value
            FROM jsonb_array_elements(r->'resources')
          ) q
  );
end;
$$;


CREATE OR REPLACE FUNCTION
kx_create_nested_service_resources(r jsonb, parent text default null) returns jsonb language plpgsql AS $$
begin
  return jsonb_strip_nulls((
    SELECT update_resource(jsonb_build_object(
      'table_name', r->>'table_name',
      'columns',  case when parent is not null then -- add parent fk
                    r->'columns' || jsonb_build_object(
                      'name', inflection_singularize(parent) || '_id',
                      'type', 'integer'
                    )
                  else
                    r->'columns'
                  end,
      'resources',  jsonb_agg(kx_create_nested_service_resources(q.value, r->>'table_name')),
      'index', r->'index'
    ))
    from (
      SELECT jsonb_set(value, '{index}', to_jsonb(row_number() OVER())) as value
      FROM jsonb_array_elements(r->'resources')
    ) q
  ));
end;
$$;

