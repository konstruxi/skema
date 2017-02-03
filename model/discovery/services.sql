
DROP materialized VIEW structures_and_services;

CREATE materialized VIEW structures_and_services AS
  SELECT 
    table_name,
    columns,
    "references",
    relations,
    parent_name,
    grandparent_name,
    parent_structure,
    grandparent_structure,
    select_sql,
    CASE WHEN table_name = 'services' THEN
      -- to join all portals into one, only select specific shared columns
        
      compose_sql('services', columns, (SELECT jsonb_agg(s)
                                        FROM structures_and_queries s
                                        WHERE parent_name = '' 
                                          AND table_name != 'services'
                                          AND NOT EXISTS( SELECT 1 
                                                          from structures_and_queries q 
                                                          WHERE q.table_name = s.table_name
                                                            AND q.parent_name != '')))
    ELSE
      compose_sql
    END as compose_sql,
    update_sql,
    insert_sql,
    file_sql,
    columns_sql,
    initialized

  FROM structures_and_queries;