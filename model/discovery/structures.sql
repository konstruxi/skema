

-- enumerate user defined tables
DROP MATERIALIZED VIEW structures CASCADE;
CREATE MATERIALIZED VIEW structures AS

SELECT  
    columns.table_name,
    jsonb_agg(jsonb_strip_nulls(
      row_to_json(columns)::jsonb - 'table_name' - 'parent_name' - 'grandparent_name'
    )) as columns

FROM (
  SELECT 
  tables.table_name                                as table_name,
  ''                                               as parent_name,
  ''                                               as grandparent_name,
  column_name                                      as name,
  CASE WHEN position('_ids' in column_name) > 0 THEN 
    replace(column_name, '_ids', '')
  WHEN position('_id' in column_name) > 0 AND column_name != 'root_id' THEN 
    inflection_pluralize(replace(column_name, '_id', ''))
  END                                              as relation_name,
  CASE WHEN position('character' in data_type) > 0 THEN 
    'string'
  ELSE 
    -- check if column represents binary file
    coalesce((SELECT CASE 
                -- not great
                WHEN inflection_singularize(cols.column_name) = cols.column_name THEN 
                  'file' 
                ELSE 
                  'files' 
                END 
              FROM INFORMATION_SCHEMA.COLUMNS c
                WHERE c.table_name = cols.table_name
                AND   c.column_name = cols.column_name || '_blobs')
    -- or use data_type as type
    , lower(data_type))

  END                                              as type, -- wrapping data type (e.g. array)
  trim(both '_' from udt_name)                     as udt,  -- underlying data type (e.g. bytea)
  character_maximum_length                         as maxlength,
  --(CASE WHEN position('_id' in column_name) > 0 and position('root_id' in column_name) = 0 THEN
  --   jsonb_from(replace(column_name, '_id', ''), v.value::text::int)->'jsonb_agg'
  -- END)                                            as options,
  (column_name != 'id' and column_name != 'root_id' and 
   position('version' in column_name) = 0) or NULL as is_editable,
  (SELECT c.column_name FROM INFORMATION_SCHEMA.COLUMNS c
    WHERE c.table_name = tables.table_name and c.column_name != 'slug'
    AND (position('character' in c.data_type) > 0 or c.data_type = 'text') LIMIT 1) = column_name or NULL  as is_title

FROM INFORMATION_SCHEMA.COLUMNS cols

LEFT JOIN INFORMATION_SCHEMA.TABLES tables
on tables.table_name = cols.table_name

WHERE position('pg_' in tables.table_name) = 0 
and tables.is_insertable_into != 'NO' 
AND position('sql_' in tables.table_name) != 1 
and tables.table_type != 'VIEW'

) columns

GROUP BY columns.table_name;
