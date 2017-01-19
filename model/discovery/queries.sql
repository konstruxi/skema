
DROP MATERIALIZED VIEW structures_and_queries;

CREATE MATERIALIZED VIEW structures_and_queries AS
  SELECT *, 
  CASE WHEN structures.parent_name != '' THEN
    replace(full_select_sql(table_name, structures.columns), 'WHERE 1=1', 'WHERE ' || inflection_singularize(parent_name) || '_id = $parent_id')
  ELSE
    full_select_sql(table_name, structures.columns) 
  END as select_sql,
  update_sql(table_name, structures.columns) AS update_sql,
  patch_sql(table_name, structures.columns)  AS patch_sql,
  insert_sql(table_name, structures.columns) AS insert_sql,
  (table_name = 'services')                  AS initialized
  
  FROM structures_hierarchy structures;


