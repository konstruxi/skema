

-- enumerate user defined tables
DROP MATERIALIZED VIEW kx_resources CASCADE;
CREATE MATERIALIZED VIEW kx_resources AS

SELECT  
    columns.table_name,
    inflection_singularize(columns.table_name) as singular,
    (kx_best_effort_jsonb( -- read alias & index from json in table comments
      obj_description(class.oid)
    )->>'index') as index,
    coalesce((kx_best_effort_jsonb(
      obj_description(class.oid)
    )->>'alias'), columns.table_name) as alias,
    jsonb_agg(jsonb_strip_nulls(
      row_to_json(columns)::jsonb - 'table_name'
    ) ORDER BY index ASC, pos ASC) as columns

FROM (
  SELECT 
  tables.table_name                                as table_name,
  (kx_best_effort_jsonb(
    col_description(class.oid, cols.ordinal_position)
  )->>'index')::int                                as index,
  column_name                                      as name,
  cols.ordinal_position                            as pos,
  CASE WHEN position('_ids' in column_name) > 0 THEN 
    replace(column_name, '_ids', '')
  WHEN position('_id' in column_name) > 0 AND column_name != 'root_id' THEN 
    inflection_pluralize(replace(column_name, '_id', ''))
  END                                              as relation_name,
  CASE WHEN position('character' in data_type) > 0 THEN 
    'string'
  WHEN data_type = 'timestamp with time zone' THEN 
    'timestamptz'
  WHEN data_type = 'timestamp' THEN 
    'timestamp'
  WHEN udt_name = 'bytea' THEN 
    'bytea'
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

LEFT JOIN pg_catalog.pg_class class
ON (class.relname = cols.table_name)

LEFT JOIN INFORMATION_SCHEMA.TABLES tables
on tables.table_name = cols.table_name

WHERE position('pg_' in tables.table_name) = 0 
and tables.is_insertable_into != 'NO' 
AND position('sql_' in tables.table_name) != 1 
and tables.table_type != 'VIEW'

) columns


LEFT JOIN pg_catalog.pg_class class
ON (class.relname = columns.table_name)

GROUP BY columns.table_name, class.oid
ORDER BY index ASC;

