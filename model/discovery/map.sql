-- Create a three-level deep site map of resources,
-- with simplified column definitions 

-- The query is naive and inefficient, but its result 
-- is shared between all resources and via materialized view 
CREATE OR REPLACE FUNCTION
kx_discover_map()
returns jsonb language plpgsql AS $ff$ begin
  return (
    SELECT json_agg(
      jsonb_build_object(
        'table_name', top.table_name,
        'alias', top.alias,
        'columns', kx_simplify_columns(top.columns),
        'children', (SELECT json_agg(
                      jsonb_build_object(
                        'table_name', mid.table_name,
                        'alias', top.alias,
                        'columns', kx_simplify_columns(mid.columns),
                        'children', (SELECT json_agg(
                                      jsonb_build_object(
                                        'table_name', bot.table_name,
                                        'alias', top.alias,
                                        'columns', kx_simplify_columns(bot.columns)
                                     ) ORDER BY index)
                                     FROM kx_resources_hierarchy bot
                                     WHERE bot.third_resource  = top.table_name
                                       AND bot.second_resource = mid.table_name)

                     ) ORDER BY index)
                     FROM kx_resources_hierarchy mid
                     WHERE mid.second_resource = top.table_name)
      ) ORDER BY index
    )

    FROM kx_resources_hierarchy top

    WHERE top.second_resource = '' 
    AND top.table_name != 'services'
    AND NOT EXISTS( SELECT 1 
                      from kx_resources_hierarchy q 
                      WHERE q.table_name = top.table_name
                        AND q.second_resource != ''));

end;
$ff$ immutable;



CREATE OR REPLACE FUNCTION
kx_simplify_columns(columns jsonb)
returns jsonb language plpgsql AS $ff$ begin
  
  return (SELECT jsonb_agg(jsonb_build_object(
                          'name', value->>'name',
                          'type', value->>'type'
                          ))

                FILTER (WHERE kx_is_custom_column(value->>'name'))
          FROM jsonb_array_elements(columns));

end
$ff$ immutable;