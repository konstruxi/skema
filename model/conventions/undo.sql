
CREATE OR REPLACE FUNCTION delete_and_return_new(relname text, slug text)
  RETURNS json AS
$BODY$DECLARE
  ret RECORD;
  root_id integer;
  id integer;
BEGIN
  
  EXECUTE 'SELECT id, root_id FROM ' || quote_ident(relname) || '_versions WHERE slug=$1 limit 1'
    INTO id, root_id USING slug;

  EXECUTE 'DELETE FROM ' || quote_ident(relname) || '_versions  WHERE id=$1 RETURNING *'
    INTO ret USING id;
  
  EXECUTE 'SELECT * FROM ' || quote_ident(relname) || '_current  WHERE root_id=$1'
    INTO ret USING root_id;

  RETURN row_to_json(ret);
END;
$BODY$
LANGUAGE plpgsql VOLATILE;
