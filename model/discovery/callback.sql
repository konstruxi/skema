
CREATE OR REPLACE FUNCTION
kx_discover()
returns text language plpgsql AS $ff$ declare
  q text := '';
begin
  -- heavy step, scan all tables in PG (N rows)
  REFRESH MATERIALIZED VIEW kx_resources;

  -- a bunch of lighter steps enriching resource data (N rows * nesting permutations)
  REFRESH MATERIALIZED VIEW kx_resources_and_services;

  -- Generate heavy query to scan all tables in search of slugs matching to arguments 
  -- and union the results. It's used by router to dispatch requests to proper resource.  
  SELECT string_agg('
    SELECT DISTINCT ON (root_id) ' || 
    'q.' || (CASE WHEN EXISTS(SELECT 1 
                                 FROM jsonb_array_elements(columns) c 
                                 WHERE c->>'name' = 'version') THEN
                            'root_id'
                        ELSE
                            'id'
                        END) || ' as root_id, ' 
    || 'q.updated_at, ' 
    || '''' || table_name || ''',' 
    || 'q.slug::varchar, 
      row_to_json(q)::jsonb as jsonb
      FROM (
        SELECT ' || columns_sql(table_name, s.columns, true) || '
        FROM ' || table_name || ' 
        WHERE ' || table_name || '.slug is not NULL AND (' || table_name || '.slug=nullif(first,  '''') 
           or ' || table_name || '.slug=nullif(second, '''')
           or ' || table_name || '.slug=nullif(third,  ''''))
           and ' || table_name || '.service_id = service
        ORDER BY id DESC
      ) q
  ', ' UNION ALL ')

    FROM kx_resources_and_services s
    WHERE second_resource = '' 
      AND table_name != 'services'
  INTO q;


  EXECUTE ('CREATE OR REPLACE FUNCTION
    kx_lookup(service integer, first varchar, second varchar default '''', third varchar default '''') returns TABLE (root_id integer, updated_at timestamptz, resource text, slug varchar, jsonb jsonb) language plpgsql as $$ begin
      RETURN QUERY
      ' || q || '
      ORDER BY updated_at desc;
    end $$');

  return '<Discovered>';
end $ff$;
