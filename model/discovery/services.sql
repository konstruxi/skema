
CREATE materialized VIEW kx_resources_and_services AS
  SELECT 
    table_name,
    columns,
    "references",
    relations,
    second_resource,
    third_resource,
    parent_structure,
    grandparent_structure,
    select_sql,
    CASE WHEN table_name = 'services' THEN
      -- to join all portals into one, only select specific shared columns
        
      compose_sql('services', columns, (SELECT jsonb_agg(s)
                                        FROM kx_resources_and_queries s
                                        WHERE second_resource = '' 
                                          AND table_name != 'services'
                                          AND NOT EXISTS( SELECT 1 
                                                          from kx_resources_and_queries q 
                                                          WHERE q.table_name = s.table_name
                                                            AND q.second_resource != '')))
    ELSE
      compose_sql
    END as compose_sql,
    update_sql,
    insert_sql,
    file_sql,
    columns_sql,
    initialized

  FROM kx_resources_and_queries;