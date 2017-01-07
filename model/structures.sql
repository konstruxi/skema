

-- enumerate user defined tables
CREATE OR REPLACE VIEW structures AS

SELECT  
    columns.table_name,
    json_agg(json_strip_nulls(row_to_json(columns))) as columns

FROM (
  SELECT 
  tables.table_name                                as table_name,
  ''                                               as parent_name,
  ''                                               as grandparent_name,
  column_name                                      as name,
  CASE WHEN position('_ids' in column_name) > 0
  THEN replace(column_name, '_ids', '')
  WHEN position('_id' in column_name) > 0
  THEN pluralize(replace(column_name, '_id', ''))
  END                                              as relation_name,
  CASE WHEN position('character' in data_type) > 0
  THEN 'string'
  ELSE lower(data_type) END                               as type,
  character_maximum_length                         as maxlength,
  --(CASE WHEN position('_id' in column_name) > 0 and position('root_id' in column_name) = 0 THEN
  --   json_from(replace(column_name, '_id', ''), v.value::text::int)->'json_agg'
  -- END)                                            as options,
  (column_name != 'id' and column_name != 'root_id' and 
   position('version' in column_name) = 0) or NULL as is_editable,
  (position('_id' in column_name) > 0)
  and column_name != 'root_id' or NULL              as is_select,
  (SELECT c.column_name FROM INFORMATION_SCHEMA.COLUMNS c
    WHERE c.table_name = tables.table_name
    AND (position('character' in c.data_type) > 0 or c.data_type = 'text') LIMIT 1) = column_name or NULL  as is_title

FROM INFORMATION_SCHEMA.COLUMNS

LEFT JOIN INFORMATION_SCHEMA.TABLES tables
on tables.table_name = columns.table_name

WHERE position('pg_' in tables.table_name) = 0 
and tables.is_insertable_into != 'NO' 
AND position('sql_' in tables.table_name) != 1 
and tables.table_type != 'VIEW'

) columns

GROUP BY columns.table_name;

-- compute json array of tables that reference other table 
CREATE OR REPLACE VIEW structures_and_references AS
SELECT 
    q.*, 
    x.refs as references
FROM structures q

LEFT JOIN(
  SELECT structures.table_name, json_agg(y) as refs
  FROM structures
  INNER JOIN structures y
  ON (EXISTS(SELECT value FROM json_array_elements(y.columns) WHERE 
      value->>'name' =(singularize(structures.table_name) || '_id') OR
      value->>'name' = structures.table_name || '_ids'))
  GROUP BY structures.table_name
) x ON (x.table_name = q.table_name);



-- compute json array of related tables for each table 
CREATE OR REPLACE VIEW structures_and_children AS
SELECT 
    q.*, 
    s.relations as relations

FROM structures_and_references q

LEFT JOIN (
  SELECT 

    structs.table_name, 
    pluralize(replace(value->>'name', '_id', '')) as relation,
    row_to_json(x) as relations
    
    from structures structs, json_array_elements(structs.columns) as rls
    

  LEFT JOIN (
    SELECT z.table_name, json_agg(z.columns) as columns
    FROM (
      SELECT * FROM structures 
    ) z
    GROUP BY z.table_name
  ) x
  ON (x.table_name = pluralize(replace(value->>'name', '_id', '')) or 
      x.table_name = replace(value->>'name', '_ids', ''))

  WHERE position('_id' in rls.value->>'name') > 0 
    and rls.value->>'name' != 'root_id'

) s
ON (q.table_name = s.table_name);

-- produce configuration for nested resources
-- by duplicating tables for each relation
CREATE OR REPLACE VIEW structures_hierarchy AS
SELECT 
structures.*,
pluralize(replace(parent.column_name, '_id', ''))  as parent_name,
pluralize(replace(grandparent.column_name, '_id', ''))             as grandparent_name,

(SELECT columns 
  from structures q 
  where table_name = pluralize(replace(parent.column_name, '_id', ''))
  LIMIT 1) as parent_structure, 

(SELECT columns 
  from structures q 
  where table_name = pluralize(replace(grandparent.column_name, '_id', ''))
  LIMIT 1) as grandparent_structure

FROM structures_and_children structures

LEFT JOIN (
  SELECT column_name, columns.table_name
  from INFORMATION_SCHEMA.COLUMNS columns
  UNION SELECT '', ''
) parent
on ((structures.table_name = parent.table_name
  AND position('_id' in parent.column_name) > 0
  AND position('_ids' in parent.column_name) = 0
  AND parent.column_name != 'root_id')
  or parent.table_name = '' )


LEFT JOIN (
  SELECT column_name, columns.table_name
  from INFORMATION_SCHEMA.COLUMNS columns
  UNION SELECT '', ''
) grandparent
on ((pluralize(replace(parent.column_name, '_id', '')) = grandparent.table_name
  AND (position('_id' in grandparent.column_name) > 0 
    AND position('_ids' in grandparent.column_name) = 0) 
  AND grandparent.column_name != 'root_id')
  or grandparent.table_name = '');


DROP MATERIALIZED VIEW structures_and_queries;

CREATE MATERIALIZED VIEW structures_and_queries AS
  SELECT *, 
  CASE WHEN structures.parent_name != '' THEN
    replace(full_select_sql(table_name, structures.columns), 'WHERE 1=1', 'WHERE ' || singularize(parent_name) || '_id = $parent_id')
  ELSE
    full_select_sql(table_name, structures.columns) 
  END as select_sql,
  update_sql(table_name, structures.columns) AS update_sql,
  patch_sql(table_name, structures.columns)  AS patch_sql,
  insert_sql(table_name, structures.columns) AS insert_sql
  
  FROM structures_hierarchy structures;




CREATE OR REPLACE FUNCTION delete_and_return_new(relname text, id integer)
  RETURNS json AS
$BODY$DECLARE
  ret RECORD;
  root_id integer;
BEGIN
  
  EXECUTE 'SELECT root_id FROM ' || quote_ident(relname) || '_versions WHERE id=$1'
    INTO root_id USING id;
  
  EXECUTE 'DELETE FROM ' || quote_ident(relname) || '_versions  WHERE id=$1 RETURNING *'
    INTO ret USING id;
  
  EXECUTE 'SELECT * FROM ' || quote_ident(relname) || '_current  WHERE root_id=$1'
    INTO ret USING root_id;

  RETURN row_to_json(ret);
END;
$BODY$
LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION options_for(relname text, preset text, structure json) RETURNS json language plpgsql AS $$ declare
  options json := '{}';
BEGIN
    IF preset != 'edit' and preset != 'new'   THEN 
      return '{}'::json;
    END IF;

    WITH cols as (select
      value->>'name' as name,
      value
    from json_array_elements(structure))

    SELECT
      json_object_agg(cols.name,
      case when position('_ids' in cols.name) > 0 THEN
        json_from(replace(cols.name, '_ids', '') || '_current')
      when position('_id' in cols.name) > 0 THEN
        json_from(pluralize(replace(cols.name, '_id', '')) || '_current')
      end)
      FROM cols 
      WHERE cols.name != 'root_id'
      INTO options;

    return options;
END $$;



--SELECT *, o.json_agg as orders, p.json_agg as other
--  FROM orders 
--
--  LEFT JOIN (SELECT items.id, json_agg(orders) from items LEFT JOIN orders ON (items.order_id = orders.id) GROUP BY items.id) o 
--  ON o.id = orders.id
--
--  LEFT JOIN (SELECT items.id, json_agg(orders) from items LEFT JOIN orders ON (items.order_id = orders.id) GROUP BY items.id) p 
--  ON p.id = orders.id;


CREATE OR REPLACE FUNCTION convert_arrays(input json)
  RETURNS json language sql AS $ff$ 
    SELECT concat('{', string_agg(to_json("key") || ':' || 
           (CASE WHEN value::text ~ '^\[[^\]\{\}]+\]$' THEN
                -- convert arrays to psql array strings
                regexp_replace(
                  -- remove newlines
                  regexp_replace(
                    -- escape double quotes to adhere json syntax
                    regexp_replace(value::text,
                      '"', '\\"', 'g'),
                   '\n', ' ', 'g'),
                '^\[([^\]]+)\]$', '"{\1}"')
            ELSE
              value::text
            END)
      , ','), '}')::json
    FROM json_each(input)

$ff$;


CREATE OR REPLACE FUNCTION insert_nested_object(name text, input json)
RETURNS json language plpgsql as $ff$DECLARE
 ret json;
 columns text;
 BEGIN

  SELECT
    string_agg(key::text, ', ')
    FROM json_each(input)
    WHERE key::text != 'id'
    into columns;

  EXECUTE 'WITH r AS (INSERT INTO ' || name || '(' || columns || ') SELECT ' || columns || ' FROM json_populate_record(null::'||name||', $1) RETURNING *) SELECT row_to_json(r) FROM r' USING input  
  INTO ret;
  RETURN ret  ;
END;$ff$;

CREATE OR REPLACE FUNCTION insert_nested_objects(name text, input json)
RETURNS json language sql as $ff$
  SELECT json_agg(insert_nested_object(name, value)) FROM json_array_elements(input)
$ff$;

CREATE OR REPLACE FUNCTION process_nested_attributes(input json)
  RETURNS json language sql AS $ff$ 
    SELECT concat('{', string_agg(to_json("key") || ':' || 
      (CASE WHEN value::text ~ '^\[[\s\n]*\{.*\}[\s\n]*\]$' THEN
          insert_nested_objects(key::text, value)::text
        ELSE
          value::text
        END)
      , ','), '}')::json
    FROM json_each(input)

$ff$;


-- select possible parents
CREATE OR REPLACE FUNCTION json_from(relname text)
  RETURNS json AS
$BODY$DECLARE
 ret json;
 inputstring text;
BEGIN

  EXECUTE 'SELECT json_agg(r) FROM ( SELECT * FROM '|| quote_ident(relname) || ') r'
  INTO ret;
  RETURN ret  ;
END;
$BODY$
LANGUAGE plpgsql VOLATILE;


