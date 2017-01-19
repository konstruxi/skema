-- Turns DELETEs into UPDATE of deleted_at timestamp
CREATE OR REPLACE FUNCTION
create_resource_delete_action(r jsonb) returns jsonb language plpgsql AS $ff$ BEGIN
  
  EXECUTE  'CREATE OR REPLACE FUNCTION
            delete_' || (r->>'singular') ||'() returns trigger language plpgsql AS $$
              begin
                -- set deleted_at timestamp
                EXECUTE ''UPDATE '' || TG_TABLE_NAME || '' SET deleted_at = now() WHERE id = $1'' USING OLD.id;
          
                return null; -- dont delete original row
              end;
            $$';

  EXECUTE  'CREATE TRIGGER delete_' || (r->>'singular') ||'
            BEFORE DELETE ON ' || (r->>'table_name') ||'
            FOR EACH ROW EXECUTE PROCEDURE delete_' || (r->>'singular') ||'()';

  return r;

END $ff$;