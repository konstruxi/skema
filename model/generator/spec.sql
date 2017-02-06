
select kx_discover();


-- SELECT update_resource($f${
--     "table_name": "articles",
--     "columns": [
--       {"name":"thumbnail","type":"file"},
--       {"name":"title","type":"varchar(255)", "validations": [
--         "required"
--       ]},
--       {"name":"gorgella","type":"text", "previously": "summary"},
--       {"name":"content","type":"xml"},
--       {"name":"version","type":"integer"},
--       {"name":"deleted_at","type":"timestamptz"}
--     ]
-- }$f$::jsonb);
-- 
-- -- INSERT INTO articles(title, content, gorgella) VALUES('a', 'b', 'c');
-- -- INSERT INTO articles(title, content, gorgella) VALUES('d', 'e', 'f');
-- -- INSERT INTO articles(title, content, gorgella) VALUES('g', 'h', null);
-- --
-- --
-- 
-- SELECT update_resource($f${
--     "table_name": "articles",
--     "columns": [
--       {"name":"category_id","type":"integer"},
--       {"name":"thumbnail","type":"file"},
--       {"name":"title","type":"varchar(255)"},
--       {"name":"gorzella","type":"text", "previously": "gorgella"},
--       {"name":"version","type":"integer"},
--       {"name":"content","type":"xml"},
--       {"name":"deleted_at","type":"timestamptz"}
--     ]
-- }$f$::jsonb);
-- select kx_discover();


-- SELECT * from articles LIMIT 0;
-- SELECT * from articles_current LIMIT 0;

SELECT update_resource($f${
    "table_name": "articles",
    "columns": [
      {"name":"category_id","type":"integer"},
      {"name":"thumbnail","type":"file"},
      {"name":"title","type":"varchar(255)"},
      {"name":"content","type":"xml"},
      {"name":"summary","type":"text"},
      {"name":"version","type":"integer"},
      {"name":"deleted_at","type":"timestamptz"}
    ]
}$f$::jsonb);

SELECT update_resource($f${
    "table_name": "comments",
    "columns": [
      {"name":"article_id","type":"integer"},
      {"name":"title","type":"varchar(255)"},
      {"name":"content","type":"xml"},
      {"name":"deleted_at","type":"timestamptz"}
    ]
}$f$::jsonb);

SELECT update_resource($f${
    "table_name": "categories",
    "columns": [
      {"name":"name","type":"varchar(255)"},
      {"name":"summary","type":"text"},
      {"name":"content","type":"xml"},
      {"name":"articles_content","type":"xml"},
      {"name":"version","type":"integer"},
      {"name":"deleted_at","type":"timestamptz"}
    ]
}$f$::jsonb);

-- select kx_discover();
-- 
-- SELECT * from articles LIMIT 0;
-- SELECT * from articles_current LIMIT 0;


-- SELECT update_resource($f${
--     "table_name": "works",
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
-- SELECT update_resource($f${
--     "table_name": "inquiries",
--     "columns": [
--       {"name":"author","type":"integer"},
--       {"name":"name","type":"varchar(255)", "validations": [
--         "required"
--       ]},
--       {"name":"content","type":"xml"},
--       {"name":"version","type":"integer"},
--       {"name":"deleted_at","type":"timestamptz"}
--     ]
-- }$f$::jsonb);
-- 
-- SELECT update_resource($f${
--     "table_name": "answers",
--     "columns": [
--       {"name":"name","type":"varchar(255)", "validations": [
--         "required"
--       ]},
--       {"name":"author","type":"integer", "validations": [
--         "required"
--       ]},
--       {"name":"inquiry_id","type":"integer"},
--       {"name":"content","type":"xml"},
--       {"name":"version","type":"integer"},
--       {"name":"deleted_at","type":"timestamptz"}
--     ]
-- }$f$::jsonb);


select kx_discover();
-- 
-- 
-- SELECT * from articles;
-- 
-- 
-- UPDATE articles set title = 'lolello', content = '<section>123</section>' where title ='a';
-- SELECT * from articles;
-- 

-- SELECT update_resource($f${
--     "table_name": "articles",
--     "columns": [
--       {"name":"category_id","type":"integer"},
--       {"name":"thumbnail","type":"file"},
--       {"name":"title","type":"varchar(255)", "validations": [
--         "required"
--       ]},
--       {"name":"gorgella","type":"text"},
--       {"name":"memoire","type":"xml"},
--       {"name":"version","type":"integer"},
--       {"name":"context","type":"xml"},
--       {"name":"deleted_at","type":"timestamptz"}
--     ]
-- }$f$::jsonb);
-- ---- 
-- select kx_discover();
-- SELECT * from articles LIMIT 0;
-- SELECT * from articles_current LIMIT 0;

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
