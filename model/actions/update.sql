-- Validate on update
CREATE OR REPLACE FUNCTION
update_{resource}() returns trigger language plpgsql AS $$ begin
  new.errors = validate_{resource}(new);
  new.updated_at = now();
  return new;
end $$;

CREATE TRIGGER update_{resource}
    BEFORE UPDATE ON {resources}
    FOR EACH ROW EXECUTE PROCEDURE update_{resource}();

