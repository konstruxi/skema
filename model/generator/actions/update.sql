CREATE OR REPLACE FUNCTION
create_resource_update_action(r jsonb) returns jsonb language plpgsql AS $ff$ 
BEGIN
  -- Validate on update
  EXECUTE 'CREATE OR REPLACE FUNCTION
           update_' || (r->>'singular') || '() returns trigger language plpgsql AS $$ begin
             new.errors = validate_' || (r->>'singular') || '(new);
             new.updated_at = now();
             return new;
           end $$';

  EXECUTE kx_create_trigger(r, 'update_' || (r->>'singular'), 'BEFORE UPDATE');

  return r;
END $ff$;