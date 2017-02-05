CREATE OR REPLACE FUNCTION
kx_discover()
returns text language plpgsql AS $ff$ declare
  q text := '';
begin
  -- heavy step, scan all tables in PG (N rows)
  REFRESH MATERIALIZED VIEW kx_resources;

  -- a bunch of lighter steps enriching resource data (N rows + nest permutations)
  REFRESH MATERIALIZED VIEW kx_resources_and_services;

  -- Generate heavy query to scan all tables in search of slugs matching to arguments 
  -- and union the results. It's used by router to dispatch requests to proper resource.  
  SELECT string_agg('
    SELECT ' || table_name || '.updated_at, ''' || table_name || ''', ' || table_name || '.slug::varchar, row_to_json(' || table_name || ')::jsonb as jsonb
      FROM ' || table_name || '
      WHERE ' || table_name || '.slug is not NULL AND (' || table_name || '.slug=nullif(first,  '''') 
         or ' || table_name || '.slug=nullif(second, '''')
         or ' || table_name || '.slug=nullif(third,  ''''))
  ', ' UNION ALL ')

    FROM kx_resources_and_services s
    WHERE parent_name = '' 
      --AND table_name != 'services'
  INTO q;


  EXECUTE ('CREATE OR REPLACE FUNCTION
    kx_lookup(first varchar, second varchar default '''', third varchar default '''') returns TABLE (updated_at timestamptz, resource text, slug varchar, jsonb jsonb) language plpgsql as $$ begin
      RETURN QUERY
      ' || q || '
      ORDER BY updated_at desc;
    end $$');

  return '<Discovered>';
end $ff$;





















WITH matches as (
    -- Find records with matching slugs

    SELECT * FROM kx_lookup('', '', '4')
    UNION ALL
    SELECT null, '', '', null
  )

  -- generate all possible slug/resource combinations
  SELECT 
    coalesce(first_updated_at, second_updated_at, third_updated_at) as last_modified,
    coalesce(path, 'lol') as path



    from  (SELECT third.resource    as third_resource,
                  third.slug        as third_slug,
                  third.updated_at  as third_updated_at,
                  second.resource   as second_resource,
                  second.slug       as second_slug,
                  second.updated_at as second_updated_at,
                  first.resource    as first_resource,
                  first.slug        as first_slug,
                  first.updated_at  as first_updated_at,

                  kx_clean_jsonb(third.jsonb) as third,
                  kx_clean_jsonb(second.jsonb) as second,
                  kx_clean_jsonb(first.jsonb) as first,
 
    concat_ws('/', nullif(third.resource, ''), 
                   nullif(second.resource, ''), 
                   nullif(first.resource, '')) as path, 
               * FROM matches third, matches second, matches first) f

    RIGHT JOIN kx_resources_and_services q

    ON (1=1)

    where (
      table_name != ''
      and third_slug = ''
      and second_slug = ''
      and first_slug = '4'
      --and
--
      --(CASE WHEN '' != '' THEN
      --        concat_ws('/', nullif(q.grandparent_name, ''), nullif(q.parent_name, ''), q.table_name) 
      --      = concat_ws('/', nullif('', ''), nullif('', ''), '')
      --      WHEN concat_ws('/', nullif(q.grandparent_name, ''), nullif(q.parent_name, ''), q.table_name) = path THEN
      --        (third_resource != second_resource or third_resource = '')
      --        and (second_resource != first_resource)
      --        and (first_resource != second_resource)
      --      END)
            )
  ORDER BY length(path) DESC, last_modified DESC
  LIMIT 1;

