-- Inserts new version of a row
CREATE OR REPLACE FUNCTION
create_{resource}() returns trigger language plpgsql AS $$ begin

{if 'actions/patch'
  -- merge over latest versions if given root_id
  IF new.root_id is not NULL and new.version is NULL THEN
    SELECT * FROM {resources} WHERE id = new.root_id or root_id = new.root_id ORDER BY id DESC LIMIT 1 INTO old;
    new.created_at = old.created_at;
    new.version = old.version + 1;
    new.root_id = coalesce(old.root_id, new.root_id);
{schema     new.$1 = coalesce(new.$1, old.$1);}    -- GENERATED: column names
  END IF;
}
  new.errors = validate_{resource}(new);

  return (
    new.id,
{if 'actions/patch'
    coalesce(new.root_id, new.id),          -- inherit root_id or set to self
    coalesce(new.version, 0),               -- start with 0 version unless given
    new.previous_version,                   -- point to previous version
    new.next_version,                       -- point to next version
}
    new.errors,
    coalesce(new.created_at, now()),        -- inherit or set creation timestamp
    coalesce(new.updated_at, now()),        -- inherit or set modification timestamp
{if 'actions/delete'
    new.deleted_at,                         -- inherit deletion timestamp
} 
{schema     coalesce(new.$1, $3),});        -- GENERATED: column names & default values
end $$;

CREATE TRIGGER create_{resource}
    BEFORE INSERT ON {resources}
    FOR EACH ROW EXECUTE PROCEDURE create_{resource}();