
CREATE OR REPLACE FUNCTION
process_resource_parameters(r jsonb) returns jsonb language plpgsql AS $$ BEGIN
  -- Inflect table name
  SELECT jsonb_set(r, '{singular}', to_jsonb(inflection_singularize(r->>'table_name'))) 
    INTO r;

  -- Filter out private columns
  -- Expand composite columns



  SELECT jsonb_set(r, '{columns}', ('[' || 
    -- mandatory columns that every resource gets
    json_build_object('name', 'id',          'type', 'serial PRIMARY KEY')::text || ',' ||
    json_build_object('name', 'slug',        'type', 'varchar')::text || ',' ||
    json_build_object('name', 'created_at',  'type', 'TIMESTAMP WITH TIME ZONE')::text || ',' ||
    json_build_object('name', 'updated_at',  'type', 'TIMESTAMP WITH TIME ZONE')::text || ',' ||
    -- validation errors
    json_build_object('name', 'errors',      'type', 'jsonb')::text || ',' ||
    -- data archived from removed columns
    json_build_object('name', 'outdated',    'type', 'jsonb')::text || ','


  || string_agg(
    -- For file fields add a json column with meta data
    (CASE WHEN col->>'type' = 'file' or col->>'type' = 'files' THEN
       json_build_object('name', col->>'name', 'type', 'jsonb')::text || ',' ||
       json_build_object('name', col->>'name' || '_blobs', 'type', 'bytea[]')::text

     -- For each WYSIWYG field add file attachments columns
     WHEN col->>'type' = 'xml' THEN
       json_build_object('name', col->>'name', 'type', 'xml')::text || ',' ||
       json_build_object('name', col->>'name' || '_embeds', 'type', 'jsonb')::text || ',' ||
       json_build_object('name', col->>'name' || '_embeds_blobs', 'type', 'bytea[]')::text

     -- Add pointers to next, previous version number and first version id
     WHEN col->>'name' = 'version' THEN
       json_build_object('name', col->>'name',       'type', 'integer')::text || ',' ||
       json_build_object('name', 'root_id',          'type', 'integer')::text || ',' ||
       json_build_object('name', 'previous_version', 'type', 'integer')::text || ',' ||
       json_build_object('name', 'next_version',     'type', 'integer')::text
    ELSE
       json_build_object('name', col->>'name', 'type', col->>'type')::text
    END

    ), ',') || ']')::jsonb )
    FROM jsonb_array_elements(r->'columns') col
    WHERE kx_is_custom_column(col->>'name')
    INTO r;

  return r;
end
$$;


CREATE OR REPLACE FUNCTION
kx_is_custom_column(name text) returns boolean language plpgsql AS $$ begin
  return name !~ '_blobs|updated_at|outdated|errors|created_at|id|slug|_embeds|root_id|next_version|previous_version';
END $$;



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
            create_resource_scopes(
              create_resource_default_scopes(
                create_validation_function(
                  create_table(
                    process_resource_parameters(r))))));
end;
$$;



-- Update table columns and reinitialize triggers/functions
-- WILL NOT LOST DATA, it will soft migrate & archive removed columns
CREATE OR REPLACE FUNCTION
update_resource(r jsonb) returns jsonb language plpgsql AS $$
begin

  return  create_resource_actions(
              create_resource_scopes(
                create_resource_default_scopes(
                  create_validation_function(
                    update_table(
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
      {"name":"gorgella","type":"text"},
      {"name":"content","type":"xml"},
      {"name":"version","type":"integer"},
      {"name":"deleted_at","type":"TIMESTAMP WITH TIME ZONE"}
    ]
}$f$::jsonb);

INSERT INTO articles(title, content, gorgella) VALUES('a', 'b', 'c');
INSERT INTO articles(title, content, gorgella) VALUES('d', 'e', 'f');
INSERT INTO articles(title, content, gorgella) VALUES('g', 'h', null);

SELECT version, root_id, title, content, gorgella, outdated from articles;

select kx_discover();

SELECT update_resource($f${
    "table_name": "articles",
    "columns": [
      {"name":"category_id","type":"integer"},
      {"name":"thumbnail","type":"file"},
      {"name":"title","type":"varchar(255)", "validations": [
        "required"
      ]},
      {"name":"content","type":"xml"},
      {"name":"version","type":"integer"},
      {"name":"deleted_at","type":"TIMESTAMP WITH TIME ZONE"}
    ]
}$f$::jsonb);

SELECT version, root_id, title, content, outdated from articles;


UPDATE articles set title = 'lolello' where title ='a';
SELECT version, root_id, title, content, outdated from articles;


-- SELECT create_resource($f${
--     "table_name": "categories",
--     "columns": [
--       {"name":"name","type":"varchar(255)", "validations": [
--         "required"
--       ]},
--       {"name":"summary","type":"text"},
--       {"name":"content","type":"xml"},
--       {"name":"articles_content","type":"xml"},
--       {"name":"version","type":"integer"},
--       {"name":"deleted_at","type":"TIMESTAMP WITH TIME ZONE"}
--     ]
-- }$f$::jsonb);
-- 
-- SELECT create_resource($f${
--     "table_name": "things",
--     "columns": [
--       {"name":"name","type":"varchar(255)", "validations": [
--         "required"
--       ]},
--       {"name":"content","type":"text"},
--       {"name":"version","type":"integer"},
--       {"name":"deleted_at","type":"TIMESTAMP WITH TIME ZONE"}
--     ]
-- }$f$::jsonb);
-- 
-- SELECT create_resource($f${
--     "table_name": "services",
--     "columns": [
--       {"name":"name","type":"varchar(255)", "validations": [
--         "required"
--       ]},
--       {"name":"version","type":"integer"},
--       {"name":"uuid","type":"uuid"},
--       {"name":"type","type":"text"},
--       {"name":"url", "type":"text"},
--       {"name":"summary","type":"text"},
--       {"name":"content","type":"xml"},
--       {"name":"categories_content","type":"xml"},
--       {"name":"things_content","type":"xml"}
--     ]
-- }$f$::jsonb);

select kx_discover();






