
CREATE OR REPLACE FUNCTION
kx_process_resource_parameters(r jsonb) returns jsonb language plpgsql AS $$ BEGIN
  -- Inflect table name
  SELECT jsonb_set(r, '{singular}', to_jsonb(inflection_singularize(r->>'table_name'))) 
    INTO r;

  -- Find which column contains value to generate slug against (name or title)
  SELECT jsonb_set(r, '{title_column}', value->'name')
    FROM jsonb_array_elements(r->'columns')
    WHERE value->>'name' = 'title'
       or value->>'name' = 'name'
    LIMIT 1
    INTO r;

  -- Expand composite columns, filter out unmatching stuff
  SELECT jsonb_set(r, '{columns}', kx_process_columns_parameters(r)) 
    INTO r;


  return r;
end
$$;



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
            create_resource_scopes_with_defaults(
              create_validation_function(
                create_table(
                  kx_process_resource_parameters(r)))));
end;
$$;



-- Update table columns and reinitialize triggers/functions
-- WILL NOT LOST DATA, it will soft migrate & archive removed columns
CREATE OR REPLACE FUNCTION
update_resource(r jsonb) returns jsonb language plpgsql AS $$
begin

  return  create_resource_actions(
            create_resource_scopes_with_defaults(
              create_validation_function(
                update_table(
                  kx_process_resource_parameters(r)))));
end;
$$;




SELECT create_resource($f${
    "table_name": "articles",
    "columns": [
      {"name":"thumbnail","type":"file"},
      {"name":"title","type":"varchar(255)", "validations": [
        "required"
      ]},
      {"name":"gorgella","type":"text"},
      {"name":"content","type":"xml"},
      {"name":"version","type":"integer"},
      {"name":"deleted_at","type":"timestamptz"}
    ]
}$f$::jsonb);
select kx_discover();

INSERT INTO articles(title, content, gorgella) VALUES('a', 'b', 'c');
INSERT INTO articles(title, content, gorgella) VALUES('d', 'e', 'f');
INSERT INTO articles(title, content, gorgella) VALUES('g', 'h', null);
--
SELECT version, root_id, title, content, gorgella, outdated from articles;
--

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
      {"name":"deleted_at","type":"timestamptz"}
    ]
}$f$::jsonb);
select kx_discover();

SELECT * from articles;


UPDATE articles set title = 'lolello', content = '<section>123</section>' where title ='a';
SELECT * from articles;

select kx_discover();

SELECT update_resource($f${
    "table_name": "articles",
    "columns": [
      {"name":"category_id","type":"integer"},
      {"name":"thumbnail","type":"file"},
      {"name":"title","type":"varchar(255)", "validations": [
        "required"
      ]},
      {"name":"gorgella","type":"text"},
      {"name":"context","type":"xml"},
      {"name":"version","type":"integer"},
      {"name":"deleted_at","type":"timestamptz"}
    ]
}$f$::jsonb);
SELECT * from articles_current;




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
--       {"name":"deleted_at","type":"timestamptz"}
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
--       {"name":"deleted_at","type":"timestamptz"}
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

--select kx_discover();






