
CREATE VIEW kx_resources_and_queries AS
  SELECT *, 
    CASE WHEN second_resource != '' THEN
      replace(full_select_sql(table_name, kx_resources.columns), 'WHERE 1=1', 
        CASE WHEN EXISTS(SELECT 1 FROM jsonb_array_elements(kx_resources.columns) 
                         WHERE value->>'name' = second_resource || '_ids') THEN

          'WHERE ' || second_resource || '_ids = :slug2'
        ELSE
          'WHERE ' || inflection_singularize(second_resource) || '_id = (SELECT root_id FROM ' || second_resource || '_current WHERE slug = :slug2)'

        END
      )
    ELSE
      full_select_sql(table_name, kx_resources.columns)
    END 
 as select_sql,

  compose_sql(table_name, kx_resources.columns, kx_resources.references) as compose_sql,

  CASE WHEN EXISTS(SELECT 1 from jsonb_array_elements(kx_resources.columns) WHERE value->>'name' = 'version') THEN
     patch_sql(table_name, kx_resources.columns)  
  ELSE
    update_sql(table_name, kx_resources.columns)
  END AS update_sql,
    insert_sql(table_name, kx_resources.columns)  AS insert_sql,
      file_sql(table_name, kx_resources.columns)    AS file_sql,
   
   delete_sql(table_name, kx_resources.columns) AS delete_sql,
   
   columns_sql(table_name, kx_resources.columns) AS columns_sql,
 
  (table_name = 'services')                   AS initialized

  
  FROM kx_resources_hierarchy kx_resources;


