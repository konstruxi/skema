

-- Customize scopes based on table columns
CREATE OR REPLACE FUNCTION
create_resource_scopes_with_defaults(r jsonb, columns text DEFAULT '*') returns jsonb language plpgsql AS $$ BEGIN
  
  -- Generate reordered list of columns
  -- Exclude binary columns, apply accessors
  SELECT string_agg(
    CASE WHEN value->>'select' is not NULL THEN
      (value->>'select')
    ELSE
      (value->>'name')
    END, ', ') 
    FILTER (
      WHERE value->>'select' is null 
      or value->>'select' != 'false')
    FROM jsonb_array_elements(r->'columns')
    into columns;

  return  create_resource_view(
            create_resource_scopes(
              create_resource_default_scopes(r, columns)
            , columns)
          , columns); 

END $$;


-- Set up chain of views which can be later customized
CREATE OR REPLACE FUNCTION
create_resource_default_scopes(r jsonb, columns text DEFAULT '*') returns jsonb language plpgsql AS $$ BEGIN
  
  -- Scope: last versions
  EXECUTE 'DROP VIEW if exists ' || (r->>'table_name') || '_heads cascade';
  EXECUTE 'DROP VIEW if exists ' || (r->>'table_name') || '_current cascade';
  EXECUTE 'DROP VIEW if exists ' || (r->>'table_name') || '_json cascade';
  EXECUTE 'DROP VIEW if exists ' || (r->>'table_name') || '_versions cascade';

  -- Scope: last versions
  EXECUTE 'CREATE VIEW ' || (r->>'table_name') || '_heads AS 
  SELECT ' || columns || ' from ' || (r->>'table_name') ;

  -- Scope: undeleted things
  EXECUTE 'CREATE VIEW ' || (r->>'table_name') || '_current AS 
  SELECT ' || columns || ' from ' || (r->>'table_name') || '_heads';

  -- Scope: options for select
  EXECUTE 'CREATE VIEW ' || (r->>'table_name') || '_json AS 
  SELECT ' || columns || ' from ' || (r->>'table_name') || '_current';

  -- Scope: versions
  EXECUTE 'CREATE VIEW ' || (r->>'table_name') || '_versions AS 
  SELECT ' || columns || ' from ' || (r->>'table_name');

  return r;
END $$;


-- Customize scopes based on table columns
CREATE OR REPLACE FUNCTION
create_resource_scopes(r jsonb, columns text DEFAULT '*') returns jsonb language plpgsql AS $$ BEGIN

IF EXISTS(SELECT 1 from jsonb_array_elements(r->'columns') WHERE value->>'name' = 'deleted_at') THEN
  PERFORM create_resource_current_scope(r, columns);
END IF;

IF EXISTS(SELECT 1 from jsonb_array_elements(r->'columns') WHERE value->>'name' = 'version') THEN
  PERFORM create_resource_heads_scope(r, columns);
END IF;

IF EXISTS(SELECT 1 from jsonb_array_elements(r->'columns') WHERE value->>'name' = 'version') THEN
  PERFORM create_resource_versions_scope(r, columns);
END IF;


return r;
END $$;

-- Customize scopes based on table columns
CREATE OR REPLACE FUNCTION
create_resource_view(r jsonb, columns text DEFAULT '*') returns jsonb language plpgsql AS $$ BEGIN


  SELECT string_agg(
    CASE WHEN value->>'view' is not NULL THEN
      (value->>'view')
    ELSE
      (value->>'name')
    END, ', ') 
    FILTER (
      WHERE value->>'view' is null 
      or value->>'view' != 'false')
    FROM jsonb_array_elements(r->'columns')
    into columns;

  EXECUTE 'DROP VIEW if exists ' || (r->>'table_name') || '_view cascade';

  -- Scope: last versions
  EXECUTE 'CREATE VIEW ' || (r->>'table_name') || '_view AS 
  SELECT ' || columns || ' from ' || (r->>'table_name') || '_current';

  return jsonb_set(r, '{columns_sql}', to_jsonb(columns));
END $$;
