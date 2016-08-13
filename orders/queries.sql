-- Returns SQL query that selects from specified table with related rows aggregated as json
CREATE OR REPLACE FUNCTION full_select_sql(relname text, structure json)
  RETURNS text AS
$BODY$DECLARE
 ret json;
 names text;
 joins text;
BEGIN

  WITH cols as (select
    value->>'name' as name,
    replace(value->>'name', '_id', '') as prefix,
    substr(value->>'name', 0, 2) as alias,
    value
  from json_array_elements(structure)
  WHERE position('_ids' in value->>'name') = 0)

  SELECT
    string_agg(alias || '.json_agg as ' || prefix || 's', ',')
    FROM cols
    WHERE cols.name != 'root_id' and prefix != name
    into names;


  WITH cols as (select
    value->>'name' as name,
    replace(value->>'name', '_id', '') as prefix,
    pluralize(replace(value->>'name', '_id', '')) as prefix_plural,
    substr(value->>'name', 0, 2) as alias,
    value
  from json_array_elements(structure)
  WHERE position('_ids' in value->>'name') = 0)

  SELECT
    string_agg(
      'LEFT JOIN (SELECT ' || relname || '.id, json_agg(' || prefix_plural || ')
       from ' || relname || ' 
       LEFT JOIN ' || prefix_plural || ' 
       ON (' || relname || '.' || name || ' = ' || prefix_plural || '.id) 
       GROUP BY ' || relname || '.id) ' || alias || ' 
       ON ' || alias || '.id = ' || relname || '.' || name, ',')
    FROM cols
    WHERE cols.name != 'root_id' and prefix != name
    into joins;


  RETURN 'SELECT ' || relname || '.* ' || (CASE WHEN names is not null THEN
      ', ' || names
    ELSE
      ''
    END) || ' from ' || relname || '_current as ' || relname || ' ' || coalesce(joins, '') || ' WHERE 1=1 ';
END;
$BODY$
LANGUAGE plpgsql VOLATILE;


-- select possible parents
CREATE OR REPLACE FUNCTION update_sql(relname text, structure json)
  RETURNS text AS
$BODY$DECLARE
 names text;
BEGIN

  SELECT
    string_agg((els->>'name') || ' = coalesce(new.' || (els->>'name') || ', ' || relname || '.' || (els->>'name') || ')', ', ')
    FROM json_array_elements(structure) els
    into names;


  RETURN 'UPDATE ' || relname || ' SET ' || names;
END;
$BODY$
LANGUAGE plpgsql VOLATILE;

-- UPDATE as INSERT
CREATE OR REPLACE FUNCTION patch_sql(relname text, structure json)
  RETURNS text AS
$BODY$DECLARE
 names text;
 values text;
BEGIN

  SELECT
    string_agg(els->>'name', ', ')
    FROM json_array_elements(structure) els
    WHERE els->>'name' != 'id'
    into names;

  SELECT
    string_agg(CASE WHEN els->>'name' = 'root_id' THEN
      ':i:id'
    ELSE
      'new.' || (els->>'name')
    END, ', ')
    FROM json_array_elements(structure) els
    WHERE els->>'name' != 'id'
    into values;

  RETURN 'INSERT INTO ' || relname || '(' || names || ') SELECT ' || values;
END;
$BODY$
LANGUAGE plpgsql VOLATILE;


-- INSERT
CREATE OR REPLACE FUNCTION insert_sql(relname text, structure json)
  RETURNS text AS
$BODY$DECLARE
 names text;
 values text;
BEGIN

  SELECT
    string_agg(els->>'name', ', ')
    FROM json_array_elements(structure) els
    WHERE els->>'name' != 'id'
    into names;

  SELECT
    string_agg('new.' || (els->>'name'), ', ')
    FROM json_array_elements(structure) els
    WHERE els->>'name' != 'id'
    into values;

  RETURN 'INSERT INTO ' || relname || '(' || names || ') SELECT ' || values;
END;
$BODY$
LANGUAGE plpgsql VOLATILE;





