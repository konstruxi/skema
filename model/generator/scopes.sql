-- Set up chain of views which can be later customized
CREATE OR REPLACE FUNCTION
create_resource_default_scopes(r jsonb) returns jsonb language plpgsql AS $$ BEGIN
  
  -- Scope: last versions
  EXECUTE 'CREATE OR REPLACE 
  VIEW ' || (r->>'table_name') || '_heads AS 
  SELECT * from ' || (r->>'table_name') ;

  -- Scope: undeleted things
  EXECUTE 'CREATE OR REPLACE 
  VIEW ' || (r->>'table_name') || '_current AS 
  SELECT * from ' || (r->>'table_name') || '_heads';

  -- Scope: options for select
  EXECUTE 'CREATE OR REPLACE 
  VIEW ' || (r->>'table_name') || '_json AS 
  SELECT * from ' || (r->>'table_name') || '_current';

  -- Scope: versions
  EXECUTE 'CREATE OR REPLACE 
  VIEW ' || (r->>'table_name') || '_versions AS 
  SELECT * from ' || (r->>'table_name');

  return r;
END $$;


-- Customize scopes based on table columns
CREATE OR REPLACE FUNCTION
create_resource_scopes(r jsonb) returns jsonb language plpgsql AS $$ BEGIN

IF EXISTS(SELECT 1 from jsonb_array_elements(r->'columns') WHERE value->>'name' = 'deleted_at') THEN
  PERFORM create_resource_current_scope(r);
END IF;

IF EXISTS(SELECT 1 from jsonb_array_elements(r->'columns') WHERE value->>'name' = 'version') THEN
  PERFORM create_resource_heads_scope(r);
END IF;

IF EXISTS(SELECT 1 from jsonb_array_elements(r->'columns') WHERE value->>'name' = 'version') THEN
  PERFORM create_resource_versions_scope(r);
END IF;


return r;
END $$;
