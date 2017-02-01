-- Inflect table name
CREATE OR REPLACE FUNCTION
process_resource_parameters(r jsonb) returns jsonb language plpgsql AS $$ BEGIN
  SELECT jsonb_set(r, '{singular}', to_jsonb(inflection_singularize(r->>'table_name'))) into r;
  return r;
end
$$;


 -- Initialized table, its triggers, views and functions
CREATE OR REPLACE FUNCTION
create_resource(r jsonb) returns jsonb language plpgsql AS $$
begin

  return  create_resource_actions(
            create_resource_scopes(
              create_resource_default_scopes(
                create_validation_function(
                  create_table(
                    process_resource_parameters(r))))));
end;
$$;




SELECT create_resource($f${
    "table_name": "articles",
    "columns": [
      {"name":"category_id","type":"integer"},
      {"name":"thumbnail","type":"file"},
      {"name":"title","type":"varchar(255)", "validations": [
        "required"
      ]},
      {"name":"summary","type":"text"},
      {"name":"content","type":"xml"},
      {"name":"version","type":"integer"},
      {"name":"deleted_at","type":"TIMESTAMP WITH TIME ZONE"}
    ]
}$f$::jsonb);


SELECT create_resource($f${
    "table_name": "categories",
    "columns": [
      {"name":"name","type":"varchar(255)", "validations": [
        "required"
      ]},
      {"name":"summary","type":"text"},
      {"name":"content","type":"xml"},
      {"name":"articles_content","type":"xml"},
      {"name":"version","type":"integer"},
      {"name":"deleted_at","type":"TIMESTAMP WITH TIME ZONE"}
    ]
}$f$::jsonb);

SELECT create_resource($f${
    "table_name": "things",
    "columns": [
      {"name":"name","type":"varchar(255)", "validations": [
        "required"
      ]},
      {"name":"content","type":"text"},
      {"name":"version","type":"integer"},
      {"name":"deleted_at","type":"TIMESTAMP WITH TIME ZONE"}
    ]
}$f$::jsonb);

REFRESH MATERIALIZED VIEW structures_and_queries;