-- Turns update into insert and bumps version
CREATE OR REPLACE FUNCTION
update_{resource}() returns trigger language plpgsql AS $$ begin
  INSERT INTO {resources}(
    root_id, version, previous_version, next_version, 
    created_at, updated_at, {if 'actions/delete' deleted_at,} 
{schema     $1,})                           -- GENERATED: column names
  VALUES (
    old.root_id,                            -- inherit root_id
    {resource}_head(old.root_id, false) + 1,-- bump version to max + 1
    CASE WHEN new.root_id = -1 THEN
      old.previous_version
    ELSE
      old.version
    END,
    CASE WHEN new.next_version = old.next_version and new.root_id != -1 THEN
      null
    ELSE
      new.next_version
    END,
    old.created_at,                         -- inherit creation timestamp 
    now(),                                  -- update modification timestamp
  {if 'actions/delete'
      new.deleted_at,                         -- inherit deletion timestamp
  } 
{schema     new.$1,});                      -- GENERATED: column names

  return null;                              -- keep row immutable
end $$;

CREATE TRIGGER update_{resource}
    BEFORE UPDATE ON {resources}
    FOR EACH ROW EXECUTE PROCEDURE update_{resource}();





