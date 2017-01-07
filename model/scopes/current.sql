-- Scope: last non-deleted versions 
CREATE OR REPLACE 
VIEW {resources}_current AS 
SELECT * FROM {resources}_heads  WHERE deleted_at is null;

-- Mark HEAD of an {resource} as deleted (dont need to know version number)
CREATE OR REPLACE function
delete_current_{resource}() returns trigger
language plpgsql
AS $$
  begin
    DELETE from {resources} WHERE id=old.id;
    return null;
  end;
$$;

CREATE TRIGGER delete_current_{resource}
    INSTEAD OF DELETE ON {resources}_current
    FOR EACH ROW EXECUTE PROCEDURE delete_current_{resource}();

