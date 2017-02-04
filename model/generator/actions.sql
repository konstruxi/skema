-- Set up triggers for versioning, validations and soft-deletion
CREATE OR REPLACE FUNCTION
create_resource_actions(r jsonb) returns jsonb language plpgsql AS $$ BEGIN

  -- Soft deletion
  IF EXISTS(SELECT 1 from jsonb_array_elements(r->'columns') WHERE value->>'name' = 'deleted_at') THEN
    PERFORM create_resource_delete_action(r);
  END IF;

  -- Pick either patch or update trigger for validations
  IF EXISTS(SELECT 1 from jsonb_array_elements(r->'columns') WHERE value->>'name' = 'version') THEN
    PERFORM create_resource_patch_action(r);
  ELSE
    PERFORM create_resource_update_action(r); 
  END IF;

  
  -- Initialize file attachments functions
  return create_resource_params_functions(
          -- Set up insertion validation trigger
          create_resource_insert_action(r));
END $$;
