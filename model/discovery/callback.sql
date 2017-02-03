CREATE OR REPLACE FUNCTION
kx_discover()
returns text language plpgsql AS $ff$ declare
  q text := '';
begin
  -- heavy step, scan all tables in PG (N rows)
  REFRESH MATERIALIZED VIEW structures;

  -- a bunch of lighter steps enriching resource data (N rows + nest permutations)
  REFRESH MATERIALIZED VIEW structures_and_services;



  SELECT string_agg('
    SELECT ' || table_name || '.updated_at, ''' || table_name || ''', ' || table_name || '.slug
      FROM ' || table_name || '
      WHERE ' || table_name || '.slug=nullif(first,  '''') 
         or ' || table_name || '.slug=nullif(second, '''')
         or ' || table_name || '.slug=nullif(third,  '''')
  ', ' UNION ALL ')

    FROM structures_and_services s
    WHERE parent_name = '' 
      AND table_name != 'services'
  INTO q;


  EXECUTE ('CREATE OR REPLACE FUNCTION
    kx_lookup(first text, second text default '''', third text default '''') returns TABLE (updated_at timestamp with time zone, resource text, slug text) language plpgsql as $$ begin
      RETURN QUERY
      ' || q || '
      ORDER BY updated_at desc;
    end $$');

  return q;
end $ff$;


EXPLAIN WITH matches as (
    -- Find records with matching slugs

    SELECT * FROM kx_lookup('hello_world', '', '')
    UNION ALL
    SELECT null, '', ''
  )

  -- generate all possible slug/resource combinations
  SELECT *,
    table_name                             as resource_name,
    singularize(table_name)                as singular,
    '..' as back,

    coalesce(third_updated_at, second_updated_at, first_updated_at) as last_modified
 

    from  (SELECT first.resource    as first_resource,
                  first.slug        as first_slug,
                  first.updated_at  as first_updated_at,
                  second.resource   as second_resource,
                  second.slug       as second_slug,
                  second.updated_at as second_updated_at,
                  third.resource    as third_resource,
                  third.slug        as third_slug,
                  third.updated_at  as third_updated_at,
 
    concat_ws('/', nullif(first.resource, ''), 
                   nullif(second.resource, ''), 
                 nullif(third.resource, '')) as path, 
               * FROM matches first, matches second, matches third) f

    INNER JOIN structures_and_services q

    -- match urls against resource structure
    ON (concat_ws('/', nullif(q.grandparent_name, ''), nullif(q.parent_name, ''), q.table_name) = path)

    where first_slug = 'hello_world'
      and second_slug = ''
      and third_slug = ''
      and (first_resource != second_resource or first_resource = '')
      and (second_resource != third_resource or second_resource = '')
      and (third_resource != second_resource or third_resource = '')

  ORDER BY last_modified DESC;