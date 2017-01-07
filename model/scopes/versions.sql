-- Scope: history of changes
CREATE OR REPLACE 
VIEW {resources}_versions AS 
SELECT * from {resources} WHERE errors is null ORDER BY root_id, version DESC;

-- DELETE from {resources}_versions -- Roll back to version previous to deleted
CREATE OR REPLACE function
delete_{resource}_version() returns trigger
language plpgsql
AS $$
  declare
    prev integer := {resource}_head(old.root_id, true, old.previous_version + 1);
    next integer := (SELECT next_version from {resources} WHERE version=prev and root_id = old.root_id);
  begin
    -- if there is no valid version to roll back to, mark as deleted if it isnt yet
    IF prev is null and old.deleted_at is null THEN
      DELETE FROM {resources}_current WHERE id=old.id;
    ELSE
      
      -- otherwise clone preceeding version without deletion flag and make it current
      UPDATE {resources} SET deleted_at=null, next_version=coalesce(next, old.version), root_id=-1
      WHERE root_id = old.root_id and version=coalesce(prev, old.version);
    END IF;
    return null;
  end;
$$;

CREATE TRIGGER delete_{resource}_version
    INSTEAD OF DELETE ON {resources}_versions
    FOR EACH ROW EXECUTE PROCEDURE delete_{resource}_version();
