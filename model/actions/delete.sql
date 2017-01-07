-- Turns DELETEs into INSERTS with deleted_at timestamp
CREATE OR REPLACE FUNCTION
delete_{resource}() returns trigger language plpgsql AS $$
  begin
    -- set deleted_at timestamp
    EXECUTE 'UPDATE ' || TG_TABLE_NAME || ' SET deleted_at = now() WHERE id = $1' USING OLD.id;

    return null; -- dont delete original row
  end;
$$;

CREATE TRIGGER delete_{resource}
    BEFORE DELETE ON {resources}
    FOR EACH ROW EXECUTE PROCEDURE delete_{resource}();
