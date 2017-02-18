
-- list of public columns to select
-- skip binary stuff and passwords
CREATE OR REPLACE FUNCTION columns_sql(relname text, structure jsonb, prefix boolean DEFAULT false)
  RETURNS text AS $ff$
  SELECT string_agg(
    (CASE WHEN prefix THEN
      relname || '.'
    ELSE
      ''
    END) || (value->>'name'), ', ')
    FROM jsonb_array_elements(structure)
    WHERE value->>'type' NOT LIKE 'bytea'
      AND value->>'name' NOT LIKE '%password%'
$ff$ LANGUAGE sql VOLATILE;





-- Returns SQL query that selects from specified table with related rows aggregated as jsonb
CREATE OR REPLACE FUNCTION full_select_sql(relname text, structure jsonb)
  RETURNS text AS
$BODY$DECLARE
 ret jsonb;
 names text;
 joins text;
BEGIN

  WITH cols as (select
    value->>'name' as name,
    replace(value->>'name', '_id', '') as prefix,
    inflection_pluralize(replace(value->>'name', '_id', '')) as plural,
    inflection_pluralize(replace(value->>'name', '_id', '')) || '_parent' as alias,
    value
  from jsonb_array_elements(structure)
  WHERE position('_ids' in value->>'name') = 0)

  SELECT
    string_agg(alias || '.jsonb_agg as ' || plural, ',')
    FROM cols
    WHERE cols.name != 'root_id' and prefix != name
    into names;


  WITH cols as (select
    value->>'name' as name,
    replace(value->>'name', '_id', '') as prefix,
    inflection_pluralize(replace(value->>'name', '_id', '')) as plural,
    inflection_pluralize(replace(value->>'name', '_id', '')) || '_parent' as alias,
    value
  from jsonb_array_elements(structure)
  WHERE position('_ids' in value->>'name') = 0)

  SELECT
    string_agg(
      'LEFT JOIN (SELECT ' || relname || '.id, jsonb_agg(' || plural || '_current)
       from ' || relname || ' 
       LEFT JOIN ' || plural || '_current
       ON (' || relname || '.' || name || ' = ' || plural || '_current.root_id) 
       GROUP BY ' || relname || '.id) ' || alias || ' 
       ON ' || alias || '.id = ' || relname || '.id', '
')
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





-- select possible parents
CREATE OR REPLACE FUNCTION update_sql(relname text, structure jsonb)
  RETURNS text AS
$BODY$DECLARE
 names text;
BEGIN

  SELECT
    string_agg((els->>'name') || ' = coalesce(new.' || (els->>'name') || ', ' || relname || '.' || (els->>'name') || ')', ', ')
    FROM jsonb_array_elements(structure) els
    into names;


  RETURN 'UPDATE ' || relname || ' SET ' || names;
END;
$BODY$
LANGUAGE plpgsql VOLATILE;

-- UPDATE as INSERT
CREATE OR REPLACE FUNCTION patch_sql(relname text, structure jsonb)
  RETURNS text AS
$BODY$DECLARE
 names text;
 values text;
BEGIN

  SELECT
    string_agg(els->>'name', ', ')
    FROM jsonb_array_elements(structure) els
    WHERE els->>'name' != 'id'
    into names;

  SELECT
    string_agg('new.' || (els->>'name'), ', ')
    FROM jsonb_array_elements(structure) els
    WHERE els->>'name' != 'id'
    into values;

  RETURN 'INSERT INTO ' || relname || '(' || names || ') SELECT ' || values;
END;
$BODY$
LANGUAGE plpgsql VOLATILE;


-- INSERT
CREATE OR REPLACE FUNCTION insert_sql(relname text, structure jsonb)
  RETURNS text AS
$BODY$DECLARE
 names text;
 values text;
BEGIN

  SELECT
    string_agg(els->>'name', ', ')
    FROM jsonb_array_elements(structure) els
    WHERE els->>'name' != 'id'
    into names;

  SELECT
    string_agg('new.' || (els->>'name'), ', ')
    FROM jsonb_array_elements(structure) els
    WHERE els->>'name' != 'id'
    into values;

  RETURN 'INSERT INTO ' || relname || '(' || names || ') SELECT ' || values;
END;
$BODY$
LANGUAGE plpgsql VOLATILE;



-- Returns SQL query that selects from specified table with related rows aggregated as jsonb
CREATE OR REPLACE FUNCTION file_sql(relname text, structure jsonb)
  RETURNS text AS
$BODY$DECLARE
  all_files_in_row text;
BEGIN
  SELECT string_agg(
    (CASE WHEN value->>'type' = 'files' THEN
      'SELECT root_id, value->>''name'' as name, 
        ' || (value->>'name') || '_blobs[(value->>''index'')::int] as blob
        from ' || relname || ', jsonb_array_elements(' || (value->>'name') || ')
        WHERE value->>''index'' is not null'
    WHEN value->>'type' = 'file' THEN
      'SELECT root_id, ' || (value->>'name') || '->>''name'' as name, 
           ' || (value->>'name') || '_blobs[1] as blob
           from ' || relname
    END), '
UNION
')
    FROM jsonb_array_elements(structure)
    INTO all_files_in_row;

  RETURN 'SELECT blob FROM (' || all_files_in_row || ') q WHERE 1=1 ';
END;
$BODY$
LANGUAGE plpgsql VOLATILE;


