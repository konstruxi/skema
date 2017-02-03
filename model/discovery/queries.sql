
CREATE VIEW structures_and_queries AS
  SELECT *, 
    CASE WHEN parent_name != '' THEN
      replace(full_select_sql(table_name, structures.columns), 'WHERE 1=1', 
        CASE WHEN EXISTS(SELECT 1 FROM jsonb_array_elements(structures.columns) 
                         WHERE value->>'name' = parent_name || '_ids') THEN

          'WHERE ' || parent_name || '_ids = :parent_id'
        ELSE
          'WHERE ' || inflection_singularize(parent_name) || '_id = (SELECT root_id FROM ' || parent_name || '_current WHERE slug = :parent_id)'

        END
      )
    ELSE
      full_select_sql(table_name, structures.columns)
    END 
 as select_sql,

  compose_sql(table_name, structures.columns, structures.references) as compose_sql,

  CASE WHEN EXISTS(SELECT 1 from jsonb_array_elements(structures.columns) WHERE value->>'name' = 'version') THEN
     patch_sql(table_name, structures.columns)  
  ELSE
    update_sql(table_name, structures.columns)
  END AS update_sql,
    insert_sql(table_name, structures.columns)  AS insert_sql,
      file_sql(table_name, structures.columns)    AS file_sql,
   columns_sql(table_name, structures.columns) AS columns_sql,
 
  (table_name = 'services')                   AS initialized

  
  FROM structures_hierarchy structures;


