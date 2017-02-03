
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
    inflection_pluralize(replace(value->>'name', '_id', '')) as plural,
    inflection_pluralize(replace(value->>'name', '_id', '')) || '_parent' as alias,
    value
  from json_array_elements(structure)
  WHERE position('_ids' in value->>'name') = 0)

  SELECT
    string_agg(alias || '.json_agg as ' || plural, ',')
    FROM cols
    WHERE cols.name != 'root_id' and prefix != name
    into names;


  WITH cols as (select
    value->>'name' as name,
    replace(value->>'name', '_id', '') as prefix,
    inflection_pluralize(replace(value->>'name', '_id', '')) as plural,
    inflection_pluralize(replace(value->>'name', '_id', '')) || '_parent' as alias,
    value
  from json_array_elements(structure)
  WHERE position('_ids' in value->>'name') = 0)

  SELECT
    string_agg(
      'LEFT JOIN (SELECT ' || relname || '.id, json_agg(' || plural || ')
       from ' || relname || ' 
       LEFT JOIN ' || plural || ' 
       ON (' || relname || '.' || name || ' = ' || plural || '.id) 
       GROUP BY ' || relname || '.id) ' || alias || ' 
       ON ' || alias || '.id = ' || relname || '.' || name, ',')
    FROM cols
    WHERE cols.name != 'root_id' and prefix != name
    into joins;


  RETURN 'SELECT ' || columns_sql(relname, structure, true) || (CASE WHEN names is not null THEN
      ', ' || names
    ELSE
      ''
    END) || ' from ' || relname || '_current as ' || relname || ' ' || coalesce(joins, '') || ' WHERE 1=1 ';
END;
$BODY$
LANGUAGE plpgsql VOLATILE;