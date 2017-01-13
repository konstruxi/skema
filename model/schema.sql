-- Example of a postgre-driven immutable versioned and validated models

DROP TABLE {resources} CASCADE;
CREATE TABLE {resources} (
  id serial PRIMARY KEY,             -- Serial ID
{if 'actions/patch'
  root_id integer,                      -- ID of a first version
  version integer,                      -- Version number
  previous_version integer,             -- ID of a previous version
  next_version integer,}
  errors jsonb,                         -- Results of validation

  created_at TIMESTAMP WITH TIME ZONE,  -- Initial creation time
  updated_at TIMESTAMP WITH TIME ZONE,  -- Last time of update
{if 'actions/delete'
  deleted_at TIMESTAMP WITH TIME ZONE,} -- Datestamp of deletion (inherited)

  
{schema   $1 $2,}                       -- GENERATED: column types 
);

CREATE OR REPLACE FUNCTION
validate_{resource}(new {resources}) returns jsonb language plpgsql AS $$ declare
  errors jsonb := '{}';
begin
  -- GENERATED: column validations
{schema   IF NOT (new.$1 $4) THEN
    SELECT jsonb_set(errors, '{$1}', '"$5"') into errors;
  END IF;}

  if errors::text = '{}' THEN
    errors = null;
  END IF;

  return errors;
end $$;

-- Scope: last versions
CREATE OR REPLACE 
VIEW {resources}_heads AS 
SELECT * from {resources};

-- Scope: undeleted things
CREATE OR REPLACE 
VIEW {resources}_current AS 
SELECT * from {resources}_heads;

-- Scope: undeleted things
CREATE OR REPLACE 
VIEW {resources}_json AS 
SELECT * from {resources}_current;

-- Scope: versions things
CREATE OR REPLACE 
VIEW {resources}_versions AS 

SELECT * from {resources};
